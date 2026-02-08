import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get mode => dotenv.env['CALLPILOT_MODE'] ?? 'demo';
  static bool get isDemoMode => mode == 'demo';
  static bool get isLiveMode => mode == 'live';

  // OpenAI
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get openaiModel => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o';
  static bool get hasOpenAI => openaiApiKey.isNotEmpty && openaiApiKey != 'sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  // ElevenLabs
  static String get elevenlabsApiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  static String get elevenlabsAgentId => dotenv.env['ELEVENLABS_AGENT_ID'] ?? '';
  static String get elevenlabsVoiceId => dotenv.env['ELEVENLABS_VOICE_ID'] ?? '21m00Tcm4TlvDq8ikWAM';
  static bool get hasElevenLabs => elevenlabsApiKey.isNotEmpty && !elevenlabsApiKey.startsWith('xi_xxx');

  // Twilio
  static String get twilioAccountSid => dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
  static String get twilioAuthToken => dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
  static String get twilioPhoneNumber => dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';
  static bool get hasTwilio => twilioAccountSid.isNotEmpty && !twilioAccountSid.startsWith('ACxxx');

  // Google Places
  static String get googlePlacesApiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  static bool get hasGooglePlaces => googlePlacesApiKey.isNotEmpty && !googlePlacesApiKey.startsWith('AIzaSyXXX');

  // Google Calendar
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get googleClientSecret => dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
  static bool get hasGoogleCalendar => googleClientId.isNotEmpty && !googleClientId.startsWith('xxxx');

  // Backend
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';

  /// Summary of which services are available
  static Map<String, bool> get serviceStatus => {
        'openai': hasOpenAI,
        'elevenlabs': hasElevenLabs,
        'twilio': hasTwilio,
        'google_places': hasGooglePlaces,
        'google_calendar': hasGoogleCalendar,
      };

  static bool get allLiveServicesReady =>
      hasOpenAI && hasElevenLabs && hasTwilio && hasGooglePlaces && hasGoogleCalendar;
}
