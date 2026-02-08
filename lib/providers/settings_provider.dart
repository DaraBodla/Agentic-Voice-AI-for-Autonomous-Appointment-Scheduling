import 'package:flutter/material.dart';
import '../utils/env_config.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDemoMode = true;

  bool get isDemoMode => _isDemoMode;
  Map<String, bool> get serviceStatus => EnvConfig.serviceStatus;

  SettingsProvider() {
    _isDemoMode = EnvConfig.isDemoMode;
  }

  void toggleMode() {
    _isDemoMode = !_isDemoMode;
    notifyListeners();
  }
}