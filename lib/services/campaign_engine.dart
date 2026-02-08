import 'dart:math';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/env_config.dart';
import 'demo_data.dart';
import 'openai_service.dart';
import 'elevenlabs_service.dart';
import 'twilio_service.dart';
import 'google_places_service.dart';
import 'google_calendar_service.dart';

String _formatSlotTime(DateTime dt) {
  return DateFormat('MMM d h:mm a').format(dt);
}

class CampaignEngine {
  static Future<List<Provider>> lookupProviders({
    required String serviceType,
    required String location,
    double? latitude,
    double? longitude,
    int maxResults = 5,
    List<Provider> customProviders = const [],
  }) async {
    // Start with user's personal contacts — they are always first priority
    final List<Provider> result = [...customProviders];
    final remaining = maxResults - result.length;

    if (remaining <= 0) return result.take(maxResults).toList();

    // Fill remaining slots from Google Places or demo data
    List<Provider> discovered = [];
    if (EnvConfig.hasGooglePlaces) {
      try {
        discovered = await GooglePlacesService.searchProviders(
          serviceType: serviceType,
          location: location,
          latitude: latitude,
          longitude: longitude,
        );
      } catch (_) {}
    }
    if (discovered.isEmpty) {
      discovered = DemoData.getProvidersByType(serviceType);
      if (discovered.isEmpty) {
        discovered = DemoData.providers.take(remaining).toList();
      }
    }

    // Avoid duplicates by phone number
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

  static Future<Map<String, dynamic>> checkCalendar({
    required DateTime start,
    required DateTime end,
  }) async {
    if (GoogleCalendarService.isAuthenticated) {
      try {
        return await GoogleCalendarService.getFreeBusy(timeMin: start, timeMax: end);
      } catch (_) {}
    }
    final busySlots = DemoData.busySlots;
    final freeRanges = <Map<String, String>>[];
    var current = start;
    for (var busy in busySlots) {
      final bs = DateTime.parse(busy['start']!);
      final be = DateTime.parse(busy['end']!);
      if (bs.isAfter(end)) break;
      if (bs.isAfter(current)) {
        freeRanges.add({'start': current.toIso8601String(), 'end': bs.toIso8601String()});
      }
      if (be.isAfter(current)) current = be;
    }
    if (current.isBefore(end)) {
      freeRanges.add({'start': current.toIso8601String(), 'end': end.toIso8601String()});
    }
    return {'busy': busySlots, 'free': freeRanges};
  }

  static Future<Map<String, dynamic>> validateSlot({
    required DateTime slotTime,
    required DateTime windowStart,
    required DateTime windowEnd,
    int durationMinutes = 30,
  }) async {
    if (GoogleCalendarService.isAuthenticated) {
      try {
        return await GoogleCalendarService.validateSlot(
          slotStart: slotTime, durationMinutes: durationMinutes,
        );
      } catch (_) {}
    }
    final slotEnd = slotTime.add(Duration(minutes: durationMinutes));
    for (var busy in DemoData.busySlots) {
      final bs = DateTime.parse(busy['start']!);
      final be = DateTime.parse(busy['end']!);
      if (slotTime.isBefore(be) && slotEnd.isAfter(bs)) {
        return {'valid': false, 'reason': 'Conflicts with: ${busy['title']} (${busy['start']} - ${busy['end']})'};
      }
    }
    return {'valid': true, 'reason': 'No calendar conflicts'};
  }

  static Map<String, dynamic> computeDistance(String userLocation, String providerAddress) {
    final rng = Random(userLocation.hashCode ^ providerAddress.hashCode);
    final minutes = rng.nextInt(30) + 5;
    return {'minutes': minutes, 'km': (minutes * 0.8).round(), 'mode': 'driving'};
  }

  static Future<CallResult> simulateCall({
    required Provider provider,
    required DateTime windowStart,
    required DateTime windowEnd,
    required int callIndex,
    required int seed,
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
    toolLog.add(ToolCallLog(tool: 'calendar_check', input: {'start': windowStart.toIso8601String(), 'end': windowEnd.toIso8601String()}, output: calResult));

    final offeredSlots = <SlotOffer>[];
    if (scenario['outcome'] == 'available') {
      final numSlots = rng.nextInt(3) + 1;
      for (var i = 0; i < numSlots; i++) {
        final slotDt = windowStart.add(Duration(hours: rng.nextInt(48) + 1, minutes: [0, 15, 30, 45][rng.nextInt(4)]));
        final validation = await validateSlot(slotTime: slotDt, windowStart: windowStart, windowEnd: windowEnd);
        toolLog.add(ToolCallLog(tool: 'slot_validate', input: {'datetime': slotDt.toIso8601String()}, output: validation));
        offeredSlots.add(SlotOffer(
          dateTime: slotDt,
          durationMinutes: [30, 45, 60][rng.nextInt(3)],
          valid: validation['valid'] == true,
          validationReason: validation['reason'] ?? '',
          notes: scenario['notes'] ?? '',
        ));
      }
    }

    final transcriptLines = scenario['transcript'] as List;
    final transcript = transcriptLines
        .map((line) => (line as String)
            .replaceAll('{provider}', provider.name)
            .replaceAll('{service}', provider.serviceType))
        .join('\n');

    double confidence;
    if (scenario['outcome'] == 'available') {
      final validSlots = offeredSlots.where((s) => s.valid).toList();
      confidence = validSlots.isNotEmpty ? 0.85 + rng.nextDouble() * 0.15 : 0.3;
    } else if (scenario['outcome'] == 'callback') {
      confidence = 0.4;
    } else {
      confidence = 0.1;
    }

    return CallResult(
      providerId: provider.providerId,
      providerName: provider.name,
      status: scenario['outcome'] != 'unavailable' ? CallStatus.done : CallStatus.failed,
      offeredSlots: offeredSlots,
      notes: scenario['notes'] ?? '',
      transcriptSummary: transcript,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      durationSeconds: double.parse(duration.toStringAsFixed(1)),
      toolCallsLog: toolLog,
    );
  }

  static Future<CallResult> makeLiveCall({
    required Provider provider,
    required DateTime windowStart,
    required DateTime windowEnd,
    required int callIndex,
  }) async {
    final toolLog = <ToolCallLog>[];
    try {
      final session = await ElevenLabsService.createConversationSession(
        providerName: provider.name,
        serviceType: provider.serviceType,
        timeWindow: '${windowStart.toIso8601String()} to ${windowEnd.toIso8601String()}',
      );
      toolLog.add(ToolCallLog(tool: 'elevenlabs_create_session', input: {'provider': provider.name}, output: session));

      final callResult = await TwilioService.makeCall(
        toNumber: provider.phone,
        providerName: provider.name,
        serviceType: provider.serviceType,
      );
      toolLog.add(ToolCallLog(tool: 'twilio_make_call', input: {'to': provider.phone}, output: callResult));

      final callSid = callResult['sid'] ?? '';
      String status = 'in-progress';
      int attempts = 0;
      while (status == 'in-progress' || status == 'ringing' || status == 'queued') {
        await Future.delayed(const Duration(seconds: 3));
        final statusResult = await TwilioService.getCallStatus(callSid);
        status = statusResult['status'] ?? 'completed';
        attempts++;
        if (attempts > 40) break;
      }

      final sessionId = session['session_id'] ?? '';
      final convResults = await ElevenLabsService.getConversationResults(sessionId);
      final transcript = convResults['transcript'] ?? '';
      final extracted = await OpenAIService.extractSlotsFromTranscript(transcript);

      final slots = (extracted['slots'] as List?)?.map((s) => SlotOffer(
            dateTime: DateTime.parse(s['datetime']),
            durationMinutes: s['duration_minutes'] ?? 30,
            notes: s['notes'] ?? '',
            valid: true,
          )).toList() ?? [];

      for (var i = 0; i < slots.length; i++) {
        final validation = await validateSlot(slotTime: slots[i].dateTime, windowStart: windowStart, windowEnd: windowEnd);
        slots[i] = SlotOffer(
          dateTime: slots[i].dateTime,
          durationMinutes: slots[i].durationMinutes,
          valid: validation['valid'] == true,
          validationReason: validation['reason'] ?? '',
          notes: slots[i].notes,
        );
      }

      return CallResult(
        providerId: provider.providerId,
        providerName: provider.name,
        status: CallStatus.done,
        offeredSlots: slots,
        notes: extracted['notes'] ?? '',
        transcriptSummary: transcript,
        confidence: (extracted['confidence'] ?? 0.5).toDouble(),
        durationSeconds: attempts * 3.0,
        toolCallsLog: toolLog,
      );
    } catch (e) {
      return CallResult(
        providerId: provider.providerId,
        providerName: provider.name,
        status: CallStatus.failed,
        notes: 'Live call error: $e',
        toolCallsLog: toolLog,
      );
    }
  }

  static List<RankedOption> rankResults({
    required List<CallResult> callResults,
    required List<Provider> providers,
    required Preferences preferences,
    required String userLocation,
    required DateTime windowStart,
  }) {
    final providerMap = {for (var p in providers) p.providerId: p};
    final candidates = <Map<String, dynamic>>[];

    for (var cr in callResults) {
      if (cr.status != CallStatus.done) continue;
      final provider = providerMap[cr.providerId];
      if (provider == null) continue;

      for (var slot in cr.offeredSlots) {
        if (!slot.valid) continue;
        final hoursFromStart = slot.dateTime.difference(windowStart).inMinutes / 60.0;
        final earliestScore = (1.0 - hoursFromStart / 72).clamp(0.0, 1.0);
        final ratingScore = ((provider.rating - 1.0) / 4.0).clamp(0.0, 1.0);
        final dist = computeDistance(userLocation, provider.address);
        final distScore = (1.0 - (dist['minutes'] as int) / 40).clamp(0.0, 1.0);

        final totalScore = preferences.earliestWeight * earliestScore +
            preferences.ratingWeight * ratingScore +
            preferences.distanceWeight * distScore;

        final reasons = <String>[];
        if (earliestScore > 0.7) {
          reasons.add('Very early availability (${_formatSlotTime(slot.dateTime)})');
        } else if (earliestScore > 0.4) {
          reasons.add('Reasonable timing (${_formatSlotTime(slot.dateTime)})');
        }
        if (provider.rating >= 4.5) {
          reasons.add('Excellent rating (${provider.rating}★)');
        } else if (provider.rating >= 4.0) {
          reasons.add('Good rating (${provider.rating}★)');
        }
        if ((dist['minutes'] as int) <= 15) {
          reasons.add('Very close (${dist['minutes']} min drive)');
        } else if ((dist['minutes'] as int) <= 25) {
          reasons.add('Reasonable distance (${dist['minutes']} min)');
        }
        if (reasons.isEmpty) reasons.add('Balanced option across criteria');

        candidates.add({
          'provider_id': cr.providerId,
          'provider_name': cr.providerName,
          'slot': slot,
          'score': double.parse(totalScore.toStringAsFixed(3)),
          'rating': provider.rating,
          'distance_minutes': (dist['minutes'] as int).toDouble(),
          'confidence': cr.confidence,
          'why': '${reasons.take(3).join('. ')}.',
        });
      }
    }

    candidates.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return candidates.take(10).toList().asMap().entries.map((entry) {
      final c = entry.value;
      return RankedOption(
        rank: entry.key + 1,
        providerId: c['provider_id'],
        providerName: c['provider_name'],
        slot: c['slot'],
        score: c['score'],
        rating: c['rating'],
        distanceMinutes: c['distance_minutes'],
        confidence: c['confidence'],
        why: c['why'],
      );
    }).toList();
  }

  static Future<BookingConfirmation> confirmBooking({
    required String providerId,
    required String providerName,
    required DateTime slotTime,
    int durationMinutes = 30,
    String? providerAddress,
    String? serviceType,
  }) async {
    if (GoogleCalendarService.isAuthenticated) {
      try {
        await GoogleCalendarService.createEvent(
          summary: '${serviceType ?? 'Appointment'} at $providerName',
          description: 'Booked via CallPilot',
          startTime: slotTime,
          durationMinutes: durationMinutes,
          location: providerAddress,
        );
      } catch (_) {}
    }

    final code = 'CP-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    return BookingConfirmation(
      confirmed: true,
      providerId: providerId,
      providerName: providerName,
      slot: slotTime.toIso8601String(),
      confirmationCode: code,
      message: 'Appointment confirmed successfully.',
    );
  }
}