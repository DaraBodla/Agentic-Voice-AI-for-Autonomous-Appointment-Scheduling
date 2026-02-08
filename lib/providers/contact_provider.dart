import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

const _storageKey = 'callpilot_contacts';
const _locationKey = 'callpilot_user_location';

/// A personal contact the user wants CallPilot to call
class UserContact {
  final String id;
  String name;
  String phone;
  String serviceType; // dentist, mechanic, salon, or custom
  double rating;
  String address;
  String notes;
  DateTime createdAt;

  UserContact({
    String? id,
    required this.name,
    required this.phone,
    required this.serviceType,
    this.rating = 4.0,
    this.address = '',
    this.notes = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4().substring(0, 8),
        createdAt = createdAt ?? DateTime.now();

  /// Convert to Provider model for the campaign engine
  Provider toProvider() => Provider(
        providerId: 'user-$id',
        name: name,
        serviceType: serviceType,
        phone: phone,
        rating: rating,
        address: address,
        hours: notes,
        acceptsNewPatients: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'service_type': serviceType,
        'rating': rating,
        'address': address,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserContact.fromJson(Map<String, dynamic> json) => UserContact(
        id: json['id'],
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        serviceType: json['service_type'] ?? 'other',
        rating: (json['rating'] ?? 4.0).toDouble(),
        address: json['address'] ?? '',
        notes: json['notes'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Stores user's own location
class UserLocation {
  String address;
  double? latitude;
  double? longitude;

  UserLocation({
    this.address = '',
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get isEmpty => address.isEmpty && !hasCoordinates;

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
        address: json['address'] ?? '',
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
      );
}

class ContactProvider extends ChangeNotifier {
  List<UserContact> _contacts = [];
  UserLocation _userLocation = UserLocation();
  bool _loaded = false;

  List<UserContact> get contacts => _contacts;
  UserLocation get userLocation => _userLocation;
  bool get loaded => _loaded;

  /// Get contacts filtered by service type
  List<UserContact> getByType(String serviceType) =>
      _contacts.where((c) => c.serviceType.toLowerCase() == serviceType.toLowerCase()).toList();

  /// Get contacts as Provider models for the campaign engine
  List<Provider> getProvidersForType(String serviceType) =>
      getByType(serviceType).map((c) => c.toProvider()).toList();

  /// Load from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Load contacts
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _contacts = list.map((j) => UserContact.fromJson(j)).toList();
      } catch (_) {
        _contacts = [];
      }
    }

    // Load location
    final locRaw = prefs.getString(_locationKey);
    if (locRaw != null) {
      try {
        _userLocation = UserLocation.fromJson(jsonDecode(locRaw));
      } catch (_) {
        _userLocation = UserLocation();
      }
    }

    _loaded = true;
    notifyListeners();
  }

  /// Save to SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_contacts.map((c) => c.toJson()).toList()));
    await prefs.setString(_locationKey, jsonEncode(_userLocation.toJson()));
  }

  /// Add a contact
  Future<void> addContact(UserContact contact) async {
    _contacts.add(contact);
    notifyListeners();
    await _save();
  }

  /// Update a contact
  Future<void> updateContact(UserContact contact) async {
    final idx = _contacts.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) {
      _contacts[idx] = contact;
      notifyListeners();
      await _save();
    }
  }

  /// Delete a contact
  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
    await _save();
  }

  /// Update user location
  Future<void> setUserLocation(UserLocation location) async {
    _userLocation = location;
    notifyListeners();
    await _save();
  }
}