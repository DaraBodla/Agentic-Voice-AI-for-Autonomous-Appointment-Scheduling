import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';

class OpenAIService {
  static const _baseUrl = 'https://api.openai.com/v1';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${EnvConfig.openaiApiKey}',
      };

  /// Extract structured slot data from a receptionist transcript
  static Future<Map<String, dynamic>> extractSlotsFromTranscript(
      String transcript) async {
    if (!EnvConfig.hasOpenAI) {
      return {'slots': [], 'notes': 'OpenAI not configured'};
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode({
        'model': EnvConfig.openaiModel,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': '''You are a data extraction assistant. Extract appointment slot information from receptionist call transcripts.

Return ONLY valid JSON in this exact format:
{
  "slots": [
    {
      "datetime": "2026-02-10T09:00:00",
      "duration_minutes": 30,
      "notes": "Standard appointment"
    }
  ],
  "outcome": "available|unavailable|callback",
  "confidence": 0.85,
  "notes": "Brief summary of the call outcome"
}

If no specific times are mentioned, infer reasonable times based on context. If unavailable, return empty slots array.'''
          },
          {
            'role': 'user',
            'content': 'Extract slots from this transcript:\n\n$transcript',
          },
        ],
        'temperature': 0.1,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return jsonDecode(content);
    }
    throw Exception('OpenAI API error: ${response.statusCode}');
  }

  /// Generate ranking explanations using OpenAI
  static Future<List<Map<String, dynamic>>> generateRankingExplanations(
    List<Map<String, dynamic>> candidates,
    Map<String, dynamic> preferences,
  ) async {
    if (!EnvConfig.hasOpenAI) {
      return candidates; // Return as-is without LLM explanations
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode({
        'model': EnvConfig.openaiModel,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': '''You are a ranking explanation assistant. Given ranked appointment options and user preferences, generate clear 1-2 sentence explanations for why each option was ranked that way.

Return JSON in this format:
{
  "explanations": [
    {
      "provider_id": "...",
      "rank": 1,
      "why": "Clear, concise explanation of why this option ranked here."
    }
  ]
}

Focus on: timing (earliest/latest), rating quality, distance/convenience, and how well it matches user priorities.'''
          },
          {
            'role': 'user',
            'content':
                'Preferences: ${jsonEncode(preferences)}\n\nCandidates:\n${jsonEncode(candidates)}',
          },
        ],
        'temperature': 0.3,
        'max_tokens': 800,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      final parsed = jsonDecode(content);
      final explanations = parsed['explanations'] as List;

      for (var candidate in candidates) {
        final match = explanations.firstWhere(
          (e) => e['provider_id'] == candidate['provider_id'],
          orElse: () => null,
        );
        if (match != null) {
          candidate['why'] = match['why'];
        }
      }
    }
    return candidates;
  }

  /// Check if user needs clarification
  static Future<Map<String, dynamic>> checkClarificationNeeded(
      String userQuery) async {
    if (!EnvConfig.hasOpenAI) {
      return {'needs_clarification': false};
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode({
        'model': EnvConfig.openaiModel,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': '''Analyze the user's appointment request. Determine if any critical information is missing or ambiguous.

Return JSON:
{
  "needs_clarification": true/false,
  "missing_fields": ["service_type", "timeframe", etc.],
  "suggestion": "Could you specify..."
}'''
          },
          {'role': 'user', 'content': userQuery},
        ],
        'temperature': 0.1,
        'max_tokens': 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return jsonDecode(data['choices'][0]['message']['content']);
    }
    return {'needs_clarification': false};
  }
}
