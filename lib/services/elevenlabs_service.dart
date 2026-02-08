import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';

class ElevenLabsService {
  static const _baseUrl = 'https://api.elevenlabs.io/v1';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'xi-api-key': EnvConfig.elevenlabsApiKey,
      };

  /// Create a conversational AI session for a phone call
  /// This sets up the ElevenLabs agent with tools for appointment scheduling
  static Future<Map<String, dynamic>> createConversationSession({
    required String providerName,
    required String serviceType,
    required String timeWindow,
  }) async {
    if (!EnvConfig.hasElevenLabs) {
      return {'session_id': 'demo_session', 'status': 'demo'};
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/convai/conversations'),
      headers: _headers,
      body: jsonEncode({
        'agent_id': EnvConfig.elevenlabsAgentId,
        'agent_overrides': {
          'prompt': {
            'prompt': '''You are a friendly AI assistant calling $providerName to schedule a $serviceType appointment.

Your goal:
1. Greet the receptionist politely
2. Ask about available appointment slots within: $timeWindow
3. Get specific dates and times for any openings
4. Note any special requirements (new patient forms, arrive early, etc.)
5. Thank them and end the call

IMPORTANT:
- Be conversational and natural
- If they put you on hold, wait patiently
- If no availability, ask about the next available opening
- Always confirm the exact date and time before ending
- Use the calendar_check tool to verify slots don't conflict with existing appointments
''',
          },
          'first_message':
              'Hi, I\'m calling to schedule a $serviceType appointment. Do you have any availability this week?',
        },
        // Agentic Functions — tools the AI can call during conversation
        'tools': [
          {
            'type': 'function',
            'function': {
              'name': 'calendar_check',
              'description':
                  'Check the user\'s calendar for a specific time slot to see if it\'s free',
              'parameters': {
                'type': 'object',
                'properties': {
                  'datetime': {
                    'type': 'string',
                    'description': 'ISO datetime to check',
                  },
                  'duration_minutes': {
                    'type': 'integer',
                    'description': 'Appointment duration in minutes',
                  },
                },
                'required': ['datetime'],
              },
            },
          },
          {
            'type': 'function',
            'function': {
              'name': 'slot_validate',
              'description':
                  'Validate that a proposed appointment slot works with the user\'s schedule',
              'parameters': {
                'type': 'object',
                'properties': {
                  'datetime': {
                    'type': 'string',
                    'description': 'Proposed appointment datetime',
                  },
                },
                'required': ['datetime'],
              },
            },
          },
          {
            'type': 'function',
            'function': {
              'name': 'record_offered_slot',
              'description':
                  'Record an appointment slot offered by the receptionist',
              'parameters': {
                'type': 'object',
                'properties': {
                  'datetime': {
                    'type': 'string',
                    'description': 'Offered appointment datetime',
                  },
                  'duration_minutes': {
                    'type': 'integer',
                    'description': 'Duration in minutes',
                  },
                  'notes': {
                    'type': 'string',
                    'description': 'Any notes about this slot',
                  },
                },
                'required': ['datetime'],
              },
            },
          },
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('ElevenLabs API error: ${response.statusCode} ${response.body}');
  }

  /// Get conversation transcript and tool call results
  static Future<Map<String, dynamic>> getConversationResults(
      String conversationId) async {
    if (!EnvConfig.hasElevenLabs) {
      return {'transcript': '', 'tool_calls': []};
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/convai/conversations/$conversationId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('ElevenLabs API error: ${response.statusCode}');
  }

  /// List available voices
  static Future<List<Map<String, dynamic>>> listVoices() async {
    if (!EnvConfig.hasElevenLabs) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl/voices'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['voices']);
    }
    return [];
  }

  /// Simple text-to-speech for notification sounds
  static Future<List<int>> textToSpeech(String text) async {
    if (!EnvConfig.hasElevenLabs) return [];

    final response = await http.post(
      Uri.parse('$_baseUrl/text-to-speech/${EnvConfig.elevenlabsVoiceId}'),
      headers: {
        ..._headers,
        'Accept': 'audio/mpeg',
      },
      body: jsonEncode({
        'text': text,
        'model_id': 'eleven_turbo_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75,
        },
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes.toList();
    }
    return [];
  }
}
