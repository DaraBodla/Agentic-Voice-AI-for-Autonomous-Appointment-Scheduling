import 'package:uuid/uuid.dart';

// ─── Enums ──────────────────────────────────────────────────────────────────

enum JobStatus { created, inProgress, completed, booked, stopped, failed }

enum CallStatus { queued, calling, done, failed, stopped }

enum ServiceType { dentist, mechanic, salon }

enum CampaignMode { single, swarm }

// ─── UserRequest ────────────────────────────────────────────────────────────

class UserRequest {
  final String serviceType;
  final DateTime timeWindowStart;
  final DateTime timeWindowEnd;
  final String location;
  final double? latitude;
  final double? longitude;
  final Preferences preferences;
  final int maxProviders;
  final CampaignMode mode;
  final List<Provider> customProviders;

  UserRequest({
    required this.serviceType,
    required this.timeWindowStart,
    required this.timeWindowEnd,
    this.location = 'Downtown',
    this.latitude,
    this.longitude,
    Preferences? preferences,
    this.maxProviders = 5,
    this.mode = CampaignMode.swarm,
    List<Provider>? customProviders,
  })  : preferences = preferences ?? Preferences(),
        customProviders = customProviders ?? [];

  Map<String, dynamic> toJson() => {
        'service_type': serviceType,
        'time_window_start': timeWindowStart.toIso8601String(),
        'time_window_end': timeWindowEnd.toIso8601String(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'preferences': preferences.toJson(),
        'max_providers': maxProviders,
        'mode': mode == CampaignMode.swarm ? 'swarm' : 'single',
        'custom_providers': customProviders.length,
      };
}

// ─── Preferences ────────────────────────────────────────────────────────────

class Preferences {
  double earliestWeight;
  double ratingWeight;
  double distanceWeight;

  Preferences({
    this.earliestWeight = 0.4,
    this.ratingWeight = 0.3,
    this.distanceWeight = 0.3,
  });

  Map<String, dynamic> toJson() => {
        'earliest_weight': earliestWeight,
        'rating_weight': ratingWeight,
        'distance_weight': distanceWeight,
      };
}

// ─── Provider ───────────────────────────────────────────────────────────────

class Provider {
  final String providerId;
  final String name;
  final String serviceType;
  final String phone;
  final double rating;
  final String address;
  final double? latitude;
  final double? longitude;
  final String hours;
  final bool acceptsNewPatients;

  Provider({
    required this.providerId,
    required this.name,
    required this.serviceType,
    required this.phone,
    required this.rating,
    required this.address,
    this.latitude,
    this.longitude,
    this.hours = '',
    this.acceptsNewPatients = true,
  });

  factory Provider.fromJson(Map<String, dynamic> json) => Provider(
        providerId: json['provider_id'] ?? '',
        name: json['name'] ?? '',
        serviceType: json['service_type'] ?? '',
        phone: json['phone'] ?? '',
        rating: (json['rating'] ?? 0).toDouble(),
        address: json['address'] ?? '',
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        hours: json['hours'] ?? '',
        acceptsNewPatients: json['accepts_new_patients'] ?? true,
      );
}

// ─── SlotOffer ──────────────────────────────────────────────────────────────

class SlotOffer {
  final DateTime dateTime;
  final int durationMinutes;
  final bool valid;
  final String validationReason;
  final String notes;

  SlotOffer({
    required this.dateTime,
    this.durationMinutes = 30,
    this.valid = true,
    this.validationReason = '',
    this.notes = '',
  });

  factory SlotOffer.fromJson(Map<String, dynamic> json) => SlotOffer(
        dateTime: DateTime.parse(json['datetime'] ?? DateTime.now().toIso8601String()),
        durationMinutes: json['duration_minutes'] ?? 30,
        valid: json['valid'] ?? false,
        validationReason: json['validation_reason'] ?? '',
        notes: json['notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'datetime': dateTime.toIso8601String(),
        'duration_minutes': durationMinutes,
        'valid': valid,
        'validation_reason': validationReason,
        'notes': notes,
      };
}

// ─── ToolCallLog ────────────────────────────────────────────────────────────

class ToolCallLog {
  final String tool;
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;
  final DateTime timestamp;

  ToolCallLog({
    required this.tool,
    required this.input,
    required this.output,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ToolCallLog.fromJson(Map<String, dynamic> json) => ToolCallLog(
        tool: json['tool'] ?? '',
        input: Map<String, dynamic>.from(json['input'] ?? {}),
        output: Map<String, dynamic>.from(json['output'] ?? {}),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'tool': tool,
        'input': input,
        'output': output,
        'timestamp': timestamp.toIso8601String(),
      };
}

// ─── CallResult ─────────────────────────────────────────────────────────────

class CallResult {
  final String providerId;
  final String providerName;
  CallStatus status;
  List<SlotOffer> offeredSlots;
  String notes;
  String transcriptSummary;
  double confidence;
  double durationSeconds;
  List<ToolCallLog> toolCallsLog;

  CallResult({
    required this.providerId,
    required this.providerName,
    this.status = CallStatus.queued,
    List<SlotOffer>? offeredSlots,
    this.notes = '',
    this.transcriptSummary = '',
    this.confidence = 0.0,
    this.durationSeconds = 0.0,
    List<ToolCallLog>? toolCallsLog,
  })  : offeredSlots = offeredSlots ?? [],
        toolCallsLog = toolCallsLog ?? [];

  int get validSlotCount => offeredSlots.where((s) => s.valid).length;

  factory CallResult.fromJson(Map<String, dynamic> json) => CallResult(
        providerId: json['provider_id'] ?? '',
        providerName: json['provider_name'] ?? '',
        status: _parseCallStatus(json['status']),
        offeredSlots: (json['offered_slots'] as List<dynamic>?)
                ?.map((s) => SlotOffer.fromJson(s))
                .toList() ??
            [],
        notes: json['notes'] ?? '',
        transcriptSummary: json['transcript_summary'] ?? '',
        confidence: (json['confidence'] ?? 0).toDouble(),
        durationSeconds: (json['duration_seconds'] ?? 0).toDouble(),
        toolCallsLog: (json['tool_calls_log'] as List<dynamic>?)
                ?.map((t) => ToolCallLog.fromJson(t))
                .toList() ??
            [],
      );

  static CallStatus _parseCallStatus(dynamic s) {
    if (s == null) return CallStatus.queued;
    final str = s.toString().toLowerCase();
    switch (str) {
      case 'queued':
        return CallStatus.queued;
      case 'calling':
        return CallStatus.calling;
      case 'done':
        return CallStatus.done;
      case 'failed':
        return CallStatus.failed;
      case 'stopped':
        return CallStatus.stopped;
      default:
        return CallStatus.queued;
    }
  }
}

// ─── RankedOption ───────────────────────────────────────────────────────────

class RankedOption {
  final int rank;
  final String providerId;
  final String providerName;
  final SlotOffer slot;
  final double score;
  final double rating;
  final double distanceMinutes;
  final double confidence;
  final String why;

  RankedOption({
    required this.rank,
    required this.providerId,
    required this.providerName,
    required this.slot,
    required this.score,
    required this.rating,
    this.distanceMinutes = 0,
    this.confidence = 0,
    this.why = '',
  });

  factory RankedOption.fromJson(Map<String, dynamic> json) => RankedOption(
        rank: json['rank'] ?? 0,
        providerId: json['provider_id'] ?? '',
        providerName: json['provider_name'] ?? '',
        slot: SlotOffer.fromJson(json['slot'] ?? {}),
        score: (json['score'] ?? 0).toDouble(),
        rating: (json['rating'] ?? 0).toDouble(),
        distanceMinutes: (json['distance_minutes'] ?? 0).toDouble(),
        confidence: (json['confidence'] ?? 0).toDouble(),
        why: json['why'] ?? '',
      );
}

// ─── BookingConfirmation ────────────────────────────────────────────────────

class BookingConfirmation {
  final bool confirmed;
  final String providerId;
  final String providerName;
  final String slot;
  final String confirmationCode;
  final String message;

  BookingConfirmation({
    required this.confirmed,
    required this.providerId,
    this.providerName = '',
    required this.slot,
    required this.confirmationCode,
    this.message = '',
  });

  factory BookingConfirmation.fromJson(Map<String, dynamic> json) =>
      BookingConfirmation(
        confirmed: json['confirmed'] ?? false,
        providerId: json['provider_id'] ?? '',
        providerName: json['provider_name'] ?? '',
        slot: json['slot'] ?? '',
        confirmationCode: json['confirmation_code'] ?? '',
        message: json['message'] ?? '',
      );
}

// ─── EventLog ───────────────────────────────────────────────────────────────

class EventLog {
  final String event;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  EventLog({
    required this.event,
    DateTime? timestamp,
    Map<String, dynamic>? data,
  })  : timestamp = timestamp ?? DateTime.now(),
        data = data ?? {};

  factory EventLog.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy.remove('event');
    copy.remove('timestamp');
    return EventLog(
      event: json['event'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      data: copy,
    );
  }
}

// ─── Job ────────────────────────────────────────────────────────────────────

class Job {
  final String jobId;
  JobStatus status;
  final UserRequest request;
  List<Provider> providers;
  List<CallResult> calls;
  List<RankedOption> rankedResults;
  BookingConfirmation? confirmation;
  List<EventLog> logs;
  DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;

  Job({
    String? jobId,
    this.status = JobStatus.created,
    required this.request,
    List<Provider>? providers,
    List<CallResult>? calls,
    List<RankedOption>? rankedResults,
    this.confirmation,
    List<EventLog>? logs,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
  })  : jobId = jobId ?? const Uuid().v4().substring(0, 8),
        providers = providers ?? [],
        calls = calls ?? [],
        rankedResults = rankedResults ?? [],
        logs = logs ?? [],
        createdAt = createdAt ?? DateTime.now();
}