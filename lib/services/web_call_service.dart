import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/env_config.dart';

/// Voice call over WebSocket — replaces Twilio entirely.
///
/// Pipeline:
///   Flutter → WebSocket → Python backend → ElevenLabs Conversational AI
///   ElevenLabs AI audio → Python backend → WebSocket → Flutter speaker
class WebCallService {
  WebSocketChannel? _channel;
  bool _active = false;
  String? callId;

  final _statusCtrl = StreamController<WebCallStatus>.broadcast();
  final _transcriptCtrl = StreamController<TranscriptLine>.broadcast();
  final _audioCtrl = StreamController<Uint8List>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();

  Stream<WebCallStatus> get onStatus => _statusCtrl.stream;
  Stream<TranscriptLine> get onTranscript => _transcriptCtrl.stream;
  Stream<Uint8List> get onAudio => _audioCtrl.stream;
  Stream<String> get onError => _errorCtrl.stream;
  bool get isActive => _active;

  // Collected transcript for post-call summary
  final List<TranscriptLine> transcript = [];

  /// Check if a call is already running on the backend
  static Future<bool> isServerBusy() async {
    try {
      final resp = await http.get(Uri.parse('${EnvConfig.backendUrl}/api/status'));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body)['active'] == true;
      }
    } catch (_) {}
    return false;
  }

  /// Get backend config (demo mode, available keys, etc.)
  static Future<Map<String, dynamic>> getServerConfig() async {
    try {
      final resp = await http.get(Uri.parse('${EnvConfig.backendUrl}/api/config'));
      if (resp.statusCode == 200) return jsonDecode(resp.body);
    } catch (_) {}
    return {'demo_mode': true, 'error': 'Backend unreachable'};
  }

  /// Start a voice call
  Future<bool> startCall({
    required String providerName,
    required String serviceType,
    String phone = '',
    String notes = '',
  }) async {
    if (_active) {
      _errorCtrl.add('A call is already in progress');
      return false;
    }

    final busy = await isServerBusy();
    if (busy) {
      _errorCtrl.add('Another call is already in progress on the server');
      return false;
    }

    _active = true;
    transcript.clear();
    _statusCtrl.add(WebCallStatus.connecting);

    final wsUrl = EnvConfig.backendWsUrl;
    debugPrint('[WebCall] Connecting to $wsUrl/ws/call');

    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws/call'));

      // Send init config
      _channel!.sink.add(jsonEncode({
        'provider_name': providerName,
        'service_type': serviceType,
        'phone': phone,
        'notes': notes,
      }));

      _channel!.stream.listen(
        _handleMessage,
        onError: (err) {
          _errorCtrl.add('WebSocket error: $err');
          _active = false;
          _statusCtrl.add(WebCallStatus.ended);
        },
        onDone: () {
          if (_active) {
            _active = false;
            _statusCtrl.add(WebCallStatus.ended);
          }
        },
      );

      return true;
    } catch (e) {
      _errorCtrl.add('Connection failed: $e');
      _active = false;
      _statusCtrl.add(WebCallStatus.error);
      return false;
    }
  }

  /// Send mic audio (PCM16 bytes, base64-encoded) to backend
  void sendAudioChunk(Uint8List pcm16Bytes) {
    if (!_active || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'audio',
        'data': base64Encode(pcm16Bytes),
      }));
    } catch (_) {}
  }

  /// End the call gracefully
  void endCall() {
    if (!_active && _channel == null) return;
    _active = false;
    try {
      _channel?.sink.add(jsonEncode({'type': 'stop'}));
    } catch (_) {}
    _channel?.sink.close();
    _channel = null;
    _statusCtrl.add(WebCallStatus.ended);
  }

  void _handleMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (msg['type'] as String? ?? '') {
        case 'status':
          callId = msg['call_id'] as String?;
          final s = msg['message'] as String? ?? '';
          if (s == 'connected' || s == 'session_ready') {
            _statusCtrl.add(WebCallStatus.connected);
          } else if (s == 'connecting') {
            _statusCtrl.add(WebCallStatus.connecting);
          }

        case 'transcript':
          final role = (msg['role'] as String? ?? '') == 'user'
              ? TranscriptRole.user
              : TranscriptRole.ai;
          final text = msg['text'] as String? ?? '';
          if (text.isNotEmpty) {
            final line = TranscriptLine(role: role, text: text, timestamp: DateTime.now());
            transcript.add(line);
            _transcriptCtrl.add(line);
          }

        case 'audio':
          final b64 = msg['data'] as String? ?? '';
          if (b64.isNotEmpty) {
            _audioCtrl.add(base64Decode(b64));
          }

        case 'call_ended':
          _active = false;
          _statusCtrl.add(WebCallStatus.completed);

        case 'error':
          _errorCtrl.add(msg['message'] as String? ?? 'Unknown error');
          _active = false;
          _statusCtrl.add(WebCallStatus.error);
      }
    } catch (e) {
      debugPrint('[WebCall] Parse error: $e');
    }
  }

  /// Produce a full transcript string for post-call processing
  String get fullTranscript =>
      transcript.map((l) => '${l.role == TranscriptRole.ai ? "AI" : "User"}: ${l.text}').join('\n');

  void dispose() {
    endCall();
    _statusCtrl.close();
    _transcriptCtrl.close();
    _audioCtrl.close();
    _errorCtrl.close();
  }
}

// ── Enums & Models ──────────────────────────────────────────────────────────

enum WebCallStatus { connecting, connected, completed, ended, error }

enum TranscriptRole { ai, user }

class TranscriptLine {
  final TranscriptRole role;
  final String text;
  final DateTime timestamp;
  TranscriptLine({required this.role, required this.text, required this.timestamp});
}