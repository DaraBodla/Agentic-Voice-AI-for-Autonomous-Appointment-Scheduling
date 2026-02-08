import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/env_config.dart';

const _locationKey = 'callpilot_location_v2';

/// Manages user location globally.
/// GPS detection, manual entry, reverse geocode, persistence, search radius.
class LocationProvider extends ChangeNotifier {
  double? _lat;
  double? _lng;
  String _address = '';
  String _city = '';
  int _radiusMeters = 5000;
  LocationState _state = LocationState.idle;
  String? _error;
  bool _loaded = false;

  double? get lat => _lat;
  double? get lng => _lng;
  String get address => _address;
  String get city => _city;
  int get radiusMeters => _radiusMeters;
  LocationState get state => _state;
  String? get error => _error;
  bool get hasLocation => _lat != null && _lng != null;
  bool get loaded => _loaded;

  String get displayAddress {
    if (_address.isNotEmpty) return _address;
    if (hasLocation) return '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}';
    return 'Not set';
  }

  String get coordsText => hasLocation
      ? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
      : '';

  /// Load persisted location from disk
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_locationKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw);
        _lat = j['lat']?.toDouble();
        _lng = j['lng']?.toDouble();
        _address = j['address'] ?? '';
        _city = j['city'] ?? '';
        _radiusMeters = j['radius'] ?? 5000;
        _state = hasLocation ? LocationState.set : LocationState.idle;
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationKey, jsonEncode({
      'lat': _lat,
      'lng': _lng,
      'address': _address,
      'city': _city,
      'radius': _radiusMeters,
    }));
  }

  /// Set location manually (from text input or map pick)
  Future<void> setManual({
    required double lat,
    required double lng,
    String address = '',
    String city = '',
  }) async {
    _lat = lat;
    _lng = lng;
    _address = address;
    _city = city;
    _state = LocationState.set;
    _error = null;
    notifyListeners();

    // Try reverse geocode via backend if no address provided
    if (_address.isEmpty) {
      await _reverseGeocode();
    }

    await _save();
  }

  /// Set from address string (will store without coords unless geocoded)
  Future<void> setFromAddress(String address) async {
    _address = address;
    _state = LocationState.set;
    _error = null;
    notifyListeners();
    await _save();
  }

  /// Update search radius
  Future<void> setRadius(int meters) async {
    _radiusMeters = meters;
    notifyListeners();
    await _save();
  }

  /// Detect location via browser/device geolocation
  /// On Flutter Web, uses the JS API. On mobile, we'd use geolocator package.
  /// For now this sends a request to the backend which can geocode.
  Future<void> detectViaGPS() async {
    _state = LocationState.detecting;
    _error = null;
    notifyListeners();

    // Flutter Web: use html.window.navigator.geolocation
    // For cross-platform, we rely on the backend or manually entered coords.
    // This placeholder simulates detection — in production use geolocator package.
    try {
      // Try the backend for a default location based on IP
      // In a real app you'd use: import 'dart:html' as html; html.window.navigator.geolocation.getCurrentPosition()
      // For now, mark as needing manual entry
      _state = LocationState.needsManual;
      _error = 'GPS not available on this platform. Please enter your location manually.';
      notifyListeners();
    } catch (e) {
      _state = LocationState.error;
      _error = 'Location detection failed: $e';
      notifyListeners();
    }
  }

  /// Reverse geocode lat/lng via backend
  Future<void> _reverseGeocode() async {
    if (!hasLocation) return;
    try {
      final resp = await http.get(Uri.parse(
        '${EnvConfig.backendUrl}/api/geocode?lat=$_lat&lng=$_lng',
      ));
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        _address = d['address'] ?? _address;
        _city = d['city'] ?? d['area'] ?? _city;
        notifyListeners();
        await _save();
      }
    } catch (_) {}
  }

  /// Find nearby providers via the backend
  Future<List<Map<String, dynamic>>> findNearbyProviders(String serviceType) async {
    if (!hasLocation) return [];
    try {
      final resp = await http.get(Uri.parse(
        '${EnvConfig.backendUrl}/api/nearby?service=$serviceType&lat=$_lat&lng=$_lng&radius=$_radiusMeters',
      ));
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        return List<Map<String, dynamic>>.from(d['providers'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Clear location
  Future<void> clear() async {
    _lat = null;
    _lng = null;
    _address = '';
    _city = '';
    _state = LocationState.idle;
    _error = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationKey);
  }
}

enum LocationState {
  idle,        // No location set yet
  detecting,   // GPS detection in progress
  needsManual, // GPS failed, need manual entry
  set,         // Location is set and ready
  error,       // Something went wrong
}