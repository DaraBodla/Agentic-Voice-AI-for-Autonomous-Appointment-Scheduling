import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';

class GoogleCalendarService {
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  /// Check if we have a valid access token
  static bool get isAuthenticated =>
      _accessToken != null &&
      _tokenExpiry != null &&
      DateTime.now().isBefore(_tokenExpiry!);

  /// Set access token (from Google Sign-In flow)
  static void setAccessToken(String token, {Duration? expiresIn}) {
    _accessToken = token;
    _tokenExpiry = DateTime.now().add(expiresIn ?? const Duration(hours: 1));
  }

  /// Get free/busy information for a time range
  static Future<Map<String, dynamic>> getFreeBusy({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    if (!EnvConfig.hasGoogleCalendar || !isAuthenticated) {
      return {'busy': [], 'free': []};
    }

    final response = await http.post(
      Uri.parse('https://www.googleapis.com/calendar/v3/freeBusy'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'timeMin': timeMin.toUtc().toIso8601String(),
        'timeMax': timeMax.toUtc().toIso8601String(),
        'items': [
          {'id': 'primary'},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final calendar = data['calendars']?['primary'];
      final busy = (calendar?['busy'] as List?)
              ?.map((b) => {
                    'start': b['start'],
                    'end': b['end'],
                  })
              .toList() ??
          [];

      return {
        'busy': busy,
        'free': _computeFreeSlots(busy, timeMin, timeMax),
      };
    }
    throw Exception('Google Calendar API error: ${response.statusCode}');
  }

  /// Get upcoming events
  static Future<List<Map<String, dynamic>>> getUpcomingEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    int maxResults = 20,
  }) async {
    if (!EnvConfig.hasGoogleCalendar || !isAuthenticated) {
      return [];
    }

    final url = 'https://www.googleapis.com/calendar/v3/calendars/primary/events'
        '?timeMin=${timeMin.toUtc().toIso8601String()}'
        '&timeMax=${timeMax.toUtc().toIso8601String()}'
        '&maxResults=$maxResults'
        '&singleEvents=true'
        '&orderBy=startTime';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['items'] ?? []);
    }
    return [];
  }

  /// Create a calendar event for the booked appointment
  static Future<Map<String, dynamic>> createEvent({
    required String summary,
    required String description,
    required DateTime startTime,
    required int durationMinutes,
    String? location,
  }) async {
    if (!EnvConfig.hasGoogleCalendar || !isAuthenticated) {
      return {'status': 'demo', 'message': 'Calendar not connected'};
    }

    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final response = await http.post(
      Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/primary/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'summary': summary,
        'description': description,
        'start': {
          'dateTime': startTime.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        },
        'end': {
          'dateTime': endTime.toUtc().toIso8601String(),
          'timeZone': 'UTC',
        },
        if (location != null) 'location': location,
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 30},
            {'method': 'email', 'minutes': 60},
          ],
        },
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Calendar event creation failed: ${response.statusCode}');
  }

  /// Validate a specific slot against the calendar
  static Future<Map<String, dynamic>> validateSlot({
    required DateTime slotStart,
    int durationMinutes = 30,
  }) async {
    final slotEnd = slotStart.add(Duration(minutes: durationMinutes));

    if (!EnvConfig.hasGoogleCalendar || !isAuthenticated) {
      return {'valid': true, 'reason': 'Calendar not connected (demo mode)'};
    }

    final freeBusy = await getFreeBusy(
      timeMin: slotStart.subtract(const Duration(minutes: 15)),
      timeMax: slotEnd.add(const Duration(minutes: 15)),
    );

    final busy = freeBusy['busy'] as List;
    for (var block in busy) {
      final busyStart = DateTime.parse(block['start']);
      final busyEnd = DateTime.parse(block['end']);

      if (slotStart.isBefore(busyEnd) && slotEnd.isAfter(busyStart)) {
        return {
          'valid': false,
          'reason':
              'Conflicts with event from ${_formatTime(busyStart)} to ${_formatTime(busyEnd)}',
        };
      }
    }

    return {'valid': true, 'reason': 'No calendar conflicts'};
  }

  /// Compute free time slots from busy blocks
  static List<Map<String, String>> _computeFreeSlots(
    List<dynamic> busy,
    DateTime start,
    DateTime end,
  ) {
    final freeSlots = <Map<String, String>>[];
    var current = start;

    final sortedBusy = List<Map<String, dynamic>>.from(busy)
      ..sort((a, b) => a['start'].compareTo(b['start']));

    for (var block in sortedBusy) {
      final busyStart = DateTime.parse(block['start']);
      final busyEnd = DateTime.parse(block['end']);

      if (busyStart.isAfter(current)) {
        freeSlots.add({
          'start': current.toIso8601String(),
          'end': busyStart.toIso8601String(),
        });
      }
      if (busyEnd.isAfter(current)) {
        current = busyEnd;
      }
    }

    if (current.isBefore(end)) {
      freeSlots.add({
        'start': current.toIso8601String(),
        'end': end.toIso8601String(),
      });
    }

    return freeSlots;
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
