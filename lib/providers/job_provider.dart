import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/campaign_engine.dart';
import '../utils/env_config.dart';

class JobProvider extends ChangeNotifier {
  Job? _currentJob;
  bool _isStopped = false;

  Job? get currentJob => _currentJob;
  JobStatus get status => _currentJob?.status ?? JobStatus.created;
  List<CallResult> get calls => _currentJob?.calls ?? [];
  List<RankedOption> get rankedResults => _currentJob?.rankedResults ?? [];
  List<EventLog> get logs => _currentJob?.logs ?? [];
  BookingConfirmation? get confirmation => _currentJob?.confirmation;
  bool get isRunning => _currentJob?.status == JobStatus.inProgress;

  int get totalCalls => calls.length;
  int get activeCalls => calls.where((c) => c.status == CallStatus.calling).length;
  int get doneCalls => calls.where((c) => c.status == CallStatus.done).length;
  int get failedCalls => calls.where((c) => c.status == CallStatus.failed).length;

  /// Create and start a new campaign
  Future<void> startCampaign(UserRequest request) async {
    _isStopped = false;

    _currentJob = Job(request: request);
    _addLog('job_created', {'service': request.serviceType, 'mode': request.mode.name});
    notifyListeners();

    // Look up providers
    final providers = await CampaignEngine.lookupProviders(
      serviceType: request.serviceType,
      location: request.location,
      latitude: request.latitude,
      longitude: request.longitude,
      maxResults: request.maxProviders,
    );

    _currentJob!.providers = providers;
    _addLog('providers_found', {'count': providers.length});

    // Initialize call entries as queued
    _currentJob!.calls = providers.map((p) => CallResult(
      providerId: p.providerId,
      providerName: p.name,
      status: CallStatus.queued,
    )).toList();

    _currentJob!.status = JobStatus.inProgress;
    _currentJob!.startedAt = DateTime.now();
    _addLog('campaign_started', {'providers': providers.length, 'mode': request.mode.name});
    notifyListeners();

    // Run calls
    if (request.mode == CampaignMode.swarm) {
      await _runSwarm(providers, request);
    } else {
      await _runSingle(providers, request);
    }

    if (_isStopped) return;

    // Rank results
    final ranked = CampaignEngine.rankResults(
      callResults: _currentJob!.calls,
      providers: providers,
      preferences: request.preferences,
      userLocation: request.location,
      windowStart: request.timeWindowStart,
    );

    _currentJob!.rankedResults = ranked;
    _currentJob!.status = JobStatus.completed;
    _currentJob!.completedAt = DateTime.now();
    _addLog('campaign_completed', {
      'total_calls': _currentJob!.calls.length,
      'successful': doneCalls,
      'ranked_options': ranked.length,
    });
    notifyListeners();
  }

  /// Swarm mode — parallel calls
  Future<void> _runSwarm(List<Provider> providers, UserRequest request) async {
    final seed = DateTime.now().millisecondsSinceEpoch;
    final futures = <Future<CallResult>>[];

    for (var i = 0; i < providers.length; i++) {
      // Mark as calling
      _currentJob!.calls[i].status = CallStatus.calling;
      notifyListeners();

      final future = _makeCall(providers[i], request, i, seed);
      futures.add(future);
    }

    final results = await Future.wait(futures);

    for (var i = 0; i < results.length; i++) {
      if (_isStopped) break;
      _currentJob!.calls[i] = results[i];
      _addLog('call_completed', {
        'provider': results[i].providerName,
        'status': results[i].status.name,
        'slots': results[i].offeredSlots.length,
        'confidence': results[i].confidence,
      });
      notifyListeners();
    }
  }

  /// Single mode — sequential calls, stop at first success
  Future<void> _runSingle(List<Provider> providers, UserRequest request) async {
    final seed = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < providers.length; i++) {
      if (_isStopped) break;

      _currentJob!.calls[i].status = CallStatus.calling;
      notifyListeners();

      final result = await _makeCall(providers[i], request, i, seed);
      _currentJob!.calls[i] = result;
      _addLog('call_completed', {
        'provider': result.providerName,
        'status': result.status.name,
        'slots': result.offeredSlots.length,
      });
      notifyListeners();

      // Stop at first success in single mode
      if (result.status == CallStatus.done && result.offeredSlots.any((s) => s.valid)) {
        break;
      }
    }
  }

  /// Make a single call (demo or live)
  Future<CallResult> _makeCall(Provider provider, UserRequest request, int index, int seed) async {
    if (EnvConfig.isDemoMode || !EnvConfig.hasTwilio) {
      return CampaignEngine.simulateCall(
        provider: provider,
        windowStart: request.timeWindowStart,
        windowEnd: request.timeWindowEnd,
        callIndex: index,
        seed: seed,
      );
    } else {
      return CampaignEngine.makeLiveCall(
        provider: provider,
        windowStart: request.timeWindowStart,
        windowEnd: request.timeWindowEnd,
        callIndex: index,
      );
    }
  }

  /// Confirm a booking
  Future<void> confirmBooking(RankedOption option) async {
    if (_currentJob == null) return;

    final provider = _currentJob!.providers.firstWhere(
      (p) => p.providerId == option.providerId,
      orElse: () => Provider(
        providerId: option.providerId,
        name: option.providerName,
        serviceType: _currentJob!.request.serviceType,
        phone: '',
        rating: option.rating,
        address: '',
      ),
    );

    final confirmation = await CampaignEngine.confirmBooking(
      providerId: option.providerId,
      providerName: option.providerName,
      slotTime: option.slot.dateTime,
      durationMinutes: option.slot.durationMinutes,
      providerAddress: provider.address,
      serviceType: _currentJob!.request.serviceType,
    );

    _currentJob!.confirmation = confirmation;
    _currentJob!.status = JobStatus.booked;
    _addLog('booking_confirmed', {
      'provider': option.providerName,
      'slot': option.slot.dateTime.toIso8601String(),
      'code': confirmation.confirmationCode,
    });
    notifyListeners();
  }

  /// Kill switch — stop all calls
  void stopCampaign() {
    _isStopped = true;
    if (_currentJob != null) {
      _currentJob!.status = JobStatus.stopped;
      for (var call in _currentJob!.calls) {
        if (call.status == CallStatus.queued || call.status == CallStatus.calling) {
          call.status = CallStatus.stopped;
        }
      }
      _addLog('campaign_stopped', {});
      notifyListeners();
    }
  }

  /// Reset for new job
  void reset() {
    _currentJob = null;
    _isStopped = false;
    notifyListeners();
  }

  void _addLog(String event, Map<String, dynamic> data) {
    _currentJob?.logs.add(EventLog(event: event, data: data));
  }
}
