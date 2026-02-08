import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';

class TwilioService {
  static String get _baseUrl =>
      'https://api.twilio.com/2010-04-01/Accounts/${EnvConfig.twilioAccountSid}';

  static String get _authHeader {
    final credentials =
        base64Encode(utf8.encode('${EnvConfig.twilioAccountSid}:${EnvConfig.twilioAuthToken}'));
    return 'Basic $credentials';
  }

  /// Initiate an outbound call to a provider
  /// In a full implementation, the TwiML would connect to ElevenLabs
  /// for real-time voice conversation with the receptionist
  static Future<Map<String, dynamic>> makeCall({
    required String toNumber,
    required String providerName,
    required String serviceType,
    String? callbackUrl,
  }) async {
    if (!EnvConfig.hasTwilio) {
      return {
        'sid': 'demo_call_sid',
        'status': 'demo',
        'message': 'Twilio not configured — using demo mode',
      };
    }

    // TwiML instructions for the call
    // In production: connect to ElevenLabs websocket for AI conversation
    final twiml = '''
<Response>
  <Say voice="alice">Hello, I'm calling from CallPilot to schedule a $serviceType appointment. Could you help me find available times this week?</Say>
  <Pause length="2"/>
  <Record maxLength="120" transcribe="true" 
    transcribeCallback="$callbackUrl/transcribe"/>
  <Say>Thank you for your time. Goodbye.</Say>
</Response>
''';

    final response = await http.post(
      Uri.parse('$_baseUrl/Calls.json'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'To': toNumber,
        'From': EnvConfig.twilioPhoneNumber,
        'Twiml': twiml,
        if (callbackUrl != null) 'StatusCallback': '$callbackUrl/status',
        'StatusCallbackEvent': 'initiated ringing answered completed',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Twilio API error: ${response.statusCode} ${response.body}');
  }

  /// Get call status
  static Future<Map<String, dynamic>> getCallStatus(String callSid) async {
    if (!EnvConfig.hasTwilio) {
      return {'status': 'completed', 'duration': '45'};
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/Calls/$callSid.json'),
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Twilio API error: ${response.statusCode}');
  }

  /// End a call in progress
  static Future<void> endCall(String callSid) async {
    if (!EnvConfig.hasTwilio) return;

    await http.post(
      Uri.parse('$_baseUrl/Calls/$callSid.json'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'Status': 'completed'},
    );
  }

  /// Get call recording/transcript
  static Future<Map<String, dynamic>> getCallTranscript(
      String callSid) async {
    if (!EnvConfig.hasTwilio) {
      return {'transcript': '', 'status': 'demo'};
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/Calls/$callSid/Recordings.json'),
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'transcript': ''};
  }

  /// Check Twilio account balance / status
  static Future<Map<String, dynamic>> getAccountStatus() async {
    if (!EnvConfig.hasTwilio) {
      return {'status': 'demo', 'balance': 'N/A'};
    }

    final response = await http.get(
      Uri.parse('$_baseUrl.json'),
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'status': data['status'],
        'friendly_name': data['friendly_name'],
      };
    }
    return {'status': 'error'};
  }
}
