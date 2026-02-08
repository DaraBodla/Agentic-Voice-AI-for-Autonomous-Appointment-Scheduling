import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/env_config.dart';
import 'demo_data.dart';
import 'openai_service.dart';
import 'web_call_service.dart';
import 'google_places_service.dart';
import 'google_calendar_service.dart';

String _formatSlotTime(DateTime dt) => DateFormat('MMM d h:mm a').format(dt);

class CampaignEngine {
  /// Find providers — uses backend /api/nearby (location-aware), then Google Places, then demo fallback.
  static Future<List<Provider>> lookupProviders({
    required String serviceType,
    required String location,
    double? latitude,
    double? longitude,
    int maxResults = 5,
    List<Provider> customProviders = const [],
  }) async {
    final List<Provider> result = [...customProviders];
    final remaining = maxResults - result.length;
    if (remaining <= 0) return result.take(maxResults).toList();

    List<Provider> discovered = [];

    // 1. Try backend /api/nearby (uses user's real location, returns Google Places or demo data)
    if (latitude != null && longitude != null) {
      try {
        final resp = await http.get(Uri.parse(
          '${EnvConfig.backendUrl}/api/nearby?service=$serviceType&lat=$latitude&lng=$longitude&radius=5000',
        )).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final providers = data['providers'] as List? ?? [];
          discovered = providers.map((p) => Provider(
            providerId: p['place_id'] ?? 'nearby-${p['name'].hashCode}',
            name: p['name'] ?? '',
            serviceType: serviceType,
            phone: p['phone'] ?? '',
            rating: (p['rating'] ?? 0).toDouble(),
            address: p['address'] ?? '',
            latitude: p['lat']?.toDouble(),
            longitude: p['lng']?.toDouble(),
            hours: p['hours'] ?? '',
          )).toList();
        }
      } catch (_) {}
    }

    // 2. Fallback: Google Places directly from Flutter
    if (discovered.isEmpty && EnvConfig.hasGooglePlaces) {
      try {
        discovered = await GooglePlacesService.searchProviders(
          serviceType: serviceType,
          location: location,
          latitude: latitude,
          longitude: longitude,
        );
      } catch (_) {}
    }

    // 3. Last resort: demo data
    if (discovered.isEmpty) {
      discovered = DemoData.getProvidersByType(serviceType);
      if (discovered.isEmpty) {
        discovered = DemoData.providers.take(remaining).toList();
      }
    }

    final existingPhones = result.map((p) => p.phone).toSet();
    for (var p in discovered) {
      if (result.length >= maxResults) break;
      if (!existingPhones.contains(p.phone)) {
        result.add(p);
        existingPhones.add(p.phone);
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> checkCalendar({required DateTime start, required DateTime end}) async {
    if (GoogleCalendarService.isAuthenticated) {
      try { return await GoogleCalendarService.getFreeBusy(timeMin: start, timeMax: end); } catch (_) {}
    }
    final busySlots = DemoData.busySlots;
    final freeRanges = <Map<String, String>>[];
    var current = start;
    for (var busy in busySlots) {
      final bs = DateTime.parse(busy['start']!); final be = DateTime.parse(busy['end']!);
      if (bs.isAfter(end)) break;
      if (bs.isAfter(current)) freeRanges.add({'start': current.toIso8601String(), 'end': bs.toIso8601String()});
      if (be.isAfter(current)) current = be;
    }
    if (current.isBefore(end)) freeRanges.add({'start': current.toIso8601String(), 'end': end.toIso8601String()});
    return {'busy': busySlots, 'free': freeRanges};
  }

  static Future<Map<String, dynamic>> validateSlot({
    required DateTime slotTime, required DateTime windowStart, required DateTime windowEnd, int durationMinutes = 30,
  }) async {
    if (GoogleCalendarService.isAuthenticated) {
      try { return await GoogleCalendarService.validateSlot(slotStart: slotTime, durationMinutes: durationMinutes); } catch (_) {}
    }
    final slotEnd = slotTime.add(Duration(minutes: durationMinutes));
    for (var busy in DemoData.busySlots) {
      final bs = DateTime.parse(busy['start']!); final be = DateTime.parse(busy['end']!);
      if (slotTime.isBefore(be) && slotEnd.isAfter(bs)) return {'valid': false, 'reason': 'Conflicts: ${busy['title']}'};
    }
    return {'valid': true, 'reason': 'No conflicts'};
  }

  static Map<String, dynamic> computeDistance(String userLocation, String providerAddress) {
    final rng = Random(userLocation.hashCode ^ providerAddress.hashCode);
    final minutes = rng.nextInt(30) + 5;
    return {'minutes': minutes, 'km': (minutes * 0.8).round(), 'mode': 'driving'};
  }

  static Future<CallResult> simulateCall({
    required Provider provider, required DateTime windowStart, required DateTime windowEnd, required int callIndex, required int seed,
  }) async {
    final rng = Random(seed + callIndex + provider.providerId.hashCode);
    final toolLog = <ToolCallLog>[];
    final duration = 1.0 + rng.nextDouble() * 3.0;
    await Future.delayed(Duration(milliseconds: (duration * 1000).round()));

    final scenarios = DemoData.scenarios;
    final availScenarios = scenarios.where((s) => s['outcome'] != 'unavailable').toList();
    final failScenarios = scenarios.where((s) => s['outcome'] == 'unavailable').toList();
    Map<String, dynamic> scenario;
    if (rng.nextDouble() < 0.2 && failScenarios.isNotEmpty) {
      scenario = failScenarios[rng.nextInt(failScenarios.length)];
    } else {
      scenario = availScenarios[rng.nextInt(availScenarios.length)];
    }

    final calResult = await checkCalendar(start: windowStart, end: windowEnd);
    toolLog.add(ToolCallLog(tool: 'calendar_check', input: {'start': windowStart.toIso8601String()}, output: calResult));

    final offeredSlots = <SlotOffer>[];
    if (scenario['outcome'] == 'available') {
      final numSlots = rng.nextInt(3) + 1;
      for (var i = 0; i < numSlots; i++) {
        final slotDt = windowStart.add(Duration(hours: rng.nextInt(48) + 1, minutes: [0, 15, 30, 45][rng.nextInt(4)]));
        final validation = await validateSlot(slotTime: slotDt, windowStart: windowStart, windowEnd: windowEnd);
        toolLog.add(ToolCallLog(tool: 'slot_validate', input: {'datetime': slotDt.toIso8601String()}, output: validation));
        offeredSlots.add(SlotOffer(dateTime: slotDt, durationMinutes: [30, 45, 60][rng.nextInt(3)], valid: validation['valid'] == true, validationReason: validation['reason'] ?? '', notes: scenario['notes'] ?? ''));
      }
    }

    final transcriptLines = scenario['transcript'] as List;
    final transcript = transcriptLines.map((l) => (l as String).replaceAll('{provider}', provider.name).replaceAll('{service}', provider.serviceType)).join('\n');

    double confidence;
    if (scenario['outcome'] == 'available') {
      confidence = offeredSlots.any((s) => s.valid) ? 0.85 + rng.nextDouble() * 0.15 : 0.3;
    } else if (scenario['outcome'] == 'callback') {
      confidence = 0.4;
    } else {
      confidence = 0.1;
    }

    return CallResult(
      providerId: provider.providerId, providerName: provider.name,
      status: scenario['outcome'] != 'unavailable' ? CallStatus.done : CallStatus.failed,
      offeredSlots: offeredSlots, notes: scenario['notes'] ?? '', transcriptSummary: transcript,
      confidence: double.parse(confidence.toStringAsFixed(2)), durationSeconds: double.parse(duration.toStringAsFixed(1)), toolCallsLog: toolLog,
    );
  }

  static Future<CallResult> makeLiveCall({
    required Provider provider, required DateTime windowStart, required DateTime windowEnd, required int callIndex,
  }) async {
    final toolLog = <ToolCallLog>[];
    try {
      final webCall = WebCallService();
      final completer = Completer<void>();
      final transcriptLines = <String>[];

      webCall.onTranscript.listen((line) {
        transcriptLines.add('${line.role == TranscriptRole.ai ? "AI" : "User"}: ${line.text}');
      });
      webCall.onStatus.listen((s) {
        if (s == WebCallStatus.completed || s == WebCallStatus.ended || s == WebCallStatus.error) {
          if (!completer.isCompleted) completer.complete();
        }
      });
      webCall.onError.listen((err) {
        toolLog.add(ToolCallLog(tool: 'web_call_error', input: {'provider': provider.name}, output: {'error': err}));
        if (!completer.isCompleted) completer.complete();
      });

      toolLog.add(ToolCallLog(tool: 'web_call_start', input: {'provider': provider.name, 'phone': provider.phone}, output: {'status': 'connecting'}));
      final started = await webCall.startCall(providerName: provider.name, serviceType: provider.serviceType, phone: provider.phone);
      if (!started) {
        return CallResult(providerId: provider.providerId, providerName: provider.name, status: CallStatus.failed, notes: 'Failed to start web call', toolCallsLog: toolLog);
      }

      await completer.future.timeout(const Duration(minutes: 2), onTimeout: () => webCall.endCall());
      final fullTranscript = webCall.fullTranscript;
      toolLog.add(ToolCallLog(tool: 'web_call_complete', input: {'provider': provider.name}, output: {'lines': transcriptLines.length}));

      final extracted = await OpenAIService.extractSlotsFromTranscript(fullTranscript);
      final slots = (extracted['slots'] as List?)?.map((s) => SlotOffer(dateTime: DateTime.parse(s['datetime']), durationMinutes: s['duration_minutes'] ?? 30, notes: s['notes'] ?? '', valid: true)).toList() ?? [];
      for (var i = 0; i < slots.length; i++) {
        final v = await validateSlot(slotTime: slots[i].dateTime, windowStart: windowStart, windowEnd: windowEnd);
        slots[i] = SlotOffer(dateTime: slots[i].dateTime, durationMinutes: slots[i].durationMinutes, valid: v['valid'] == true, validationReason: v['reason'] ?? '', notes: slots[i].notes);
      }
      webCall.dispose();
      return CallResult(providerId: provider.providerId, providerName: provider.name, status: CallStatus.done, offeredSlots: slots, notes: extracted['notes'] ?? '', transcriptSummary: fullTranscript, confidence: (extracted['confidence'] ?? 0.5).toDouble(), durationSeconds: transcriptLines.length * 3.0, toolCallsLog: toolLog);
    } catch (e) {
      return CallResult(providerId: provider.providerId, providerName: provider.name, status: CallStatus.failed, notes: 'Web call error: $e', toolCallsLog: toolLog);
    }
  }

  static List<RankedOption> rankResults({
    required List<CallResult> callResults, required List<Provider> providers, required Preferences preferences, required String userLocation, required DateTime windowStart,
  }) {
    final providerMap = {for (var p in providers) p.providerId: p};
    final candidates = <Map<String, dynamic>>[];
    for (var cr in callResults) {
      if (cr.status != CallStatus.done) continue;
      final provider = providerMap[cr.providerId]; if (provider == null) continue;
      for (var slot in cr.offeredSlots) {
        if (!slot.valid) continue;
        final hoursFromStart = slot.dateTime.difference(windowStart).inMinutes / 60.0;
        final earliestScore = (1.0 - hoursFromStart / 72).clamp(0.0, 1.0);
        final ratingScore = ((provider.rating - 1.0) / 4.0).clamp(0.0, 1.0);
        final dist = computeDistance(userLocation, provider.address);
        final distScore = (1.0 - (dist['minutes'] as int) / 40).clamp(0.0, 1.0);
        final totalScore = preferences.earliestWeight * earliestScore + preferences.ratingWeight * ratingScore + preferences.distanceWeight * distScore;
        final reasons = <String>[];
        if (earliestScore > 0.7) reasons.add('Early slot (${_formatSlotTime(slot.dateTime)})');
        if (provider.rating >= 4.5) reasons.add('${provider.rating}★ rating');
        if ((dist['minutes'] as int) <= 15) reasons.add('${dist["minutes"]} min away');
        if (reasons.isEmpty) reasons.add('Balanced option');
        candidates.add({'provider_id': cr.providerId, 'provider_name': cr.providerName, 'slot': slot, 'score': double.parse(totalScore.toStringAsFixed(3)), 'rating': provider.rating, 'distance_minutes': (dist['minutes'] as int).toDouble(), 'confidence': cr.confidence, 'why': reasons.take(3).join(' · ')});
      }
    }
    candidates.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return candidates.take(10).toList().asMap().entries.map((e) {
      final c = e.value;
      return RankedOption(rank: e.key + 1, providerId: c['provider_id'], providerName: c['provider_name'], slot: c['slot'], score: c['score'], rating: c['rating'], distanceMinutes: c['distance_minutes'], confidence: c['confidence'], why: c['why']);
    }).toList();
  }

  static Future<BookingConfirmation> confirmBooking({
    required String providerId, required String providerName, required DateTime slotTime, int durationMinutes = 30, String? providerAddress, String? serviceType,
  }) async {
    if (GoogleCalendarService.isAuthenticated) {
      try { await GoogleCalendarService.createEvent(summary: '${serviceType ?? "Appointment"} at $providerName', description: 'Booked via CallPilot', startTime: slotTime, durationMinutes: durationMinutes, location: providerAddress); } catch (_) {}
    }
    return BookingConfirmation(confirmed: true, providerId: providerId, providerName: providerName, slot: slotTime.toIso8601String(), confirmationCode: 'CP-${const Uuid().v4().substring(0, 8).toUpperCase()}', message: 'Appointment confirmed.');
  }
}