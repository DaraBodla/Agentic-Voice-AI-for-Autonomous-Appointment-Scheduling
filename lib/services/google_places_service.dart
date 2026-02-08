import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';
import '../models/models.dart';

class GooglePlacesService {
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Search for service providers by type and location
  static Future<List<Provider>> searchProviders({
    required String serviceType,
    required String location,
    double? latitude,
    double? longitude,
    double radiusMeters = 10000,
    double minRating = 0,
  }) async {
    if (!EnvConfig.hasGooglePlaces) {
      return []; // Caller should fall back to demo data
    }

    // Map service types to Google Places types
    final placeType = _mapServiceType(serviceType);

    String url;
    if (latitude != null && longitude != null) {
      url = '$_baseUrl/nearbysearch/json'
          '?location=$latitude,$longitude'
          '&radius=$radiusMeters'
          '&type=$placeType'
          '&key=${EnvConfig.googlePlacesApiKey}';
    } else {
      url = '$_baseUrl/textsearch/json'
          '?query=$serviceType+near+$location'
          '&type=$placeType'
          '&key=${EnvConfig.googlePlacesApiKey}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') {
        return [];
      }

      final results = data['results'] as List;
      return results
          .map((place) => _parsePlace(place, serviceType))
          .where((p) => p.rating >= minRating)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
    }
    throw Exception('Google Places API error: ${response.statusCode}');
  }

  /// Get place details including phone number and hours
  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    if (!EnvConfig.hasGooglePlaces) return {};

    final url = '$_baseUrl/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_phone_number,international_phone_number,'
        'opening_hours,rating,formatted_address,geometry'
        '&key=${EnvConfig.googlePlacesApiKey}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? {};
    }
    return {};
  }

  /// Calculate distance and travel time between two points
  static Future<Map<String, dynamic>> getDistanceMatrix({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'driving',
  }) async {
    if (!EnvConfig.hasGooglePlaces) {
      return {'distance_km': 0, 'duration_minutes': 0};
    }

    final url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$originLat,$originLng'
        '&destinations=$destLat,$destLng'
        '&mode=$mode'
        '&key=${EnvConfig.googlePlacesApiKey}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final element = data['rows'][0]['elements'][0];
        if (element['status'] == 'OK') {
          return {
            'distance_km': (element['distance']['value'] / 1000).round(),
            'duration_minutes': (element['duration']['value'] / 60).round(),
            'distance_text': element['distance']['text'],
            'duration_text': element['duration']['text'],
          };
        }
      }
    }
    return {'distance_km': 0, 'duration_minutes': 15};
  }

  /// Map our service types to Google Places types
  static String _mapServiceType(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'dentist':
        return 'dentist';
      case 'mechanic':
        return 'car_repair';
      case 'salon':
        return 'hair_care';
      default:
        return serviceType;
    }
  }

  /// Parse a Google Places result into our Provider model
  static Provider _parsePlace(Map<String, dynamic> place, String serviceType) {
    final geometry = place['geometry']?['location'];
    return Provider(
      providerId: place['place_id'] ?? '',
      name: place['name'] ?? '',
      serviceType: serviceType,
      phone: place['formatted_phone_number'] ?? '',
      rating: (place['rating'] ?? 0).toDouble(),
      address: place['formatted_address'] ?? place['vicinity'] ?? '',
      latitude: geometry?['lat']?.toDouble(),
      longitude: geometry?['lng']?.toDouble(),
      hours: _formatHours(place['opening_hours']),
      acceptsNewPatients: place['business_status'] == 'OPERATIONAL',
    );
  }

  static String _formatHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return '';
    final periods = openingHours['weekday_text'] as List?;
    if (periods == null || periods.isEmpty) return '';
    return periods.take(3).join(', ');
  }
}
