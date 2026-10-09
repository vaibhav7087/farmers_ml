import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  String _preferredLanguage = 'en';
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  List<String> _watchedMandis = [];
  List<String> _watchedCrops = [];

  String get preferredLanguage => _preferredLanguage;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  List<String> get watchedMandis => _watchedMandis;
  List<String> get watchedCrops => _watchedCrops;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredLanguage = prefs.getString('language') ?? 'en';
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _watchedMandis = prefs.getStringList('watched_mandis') ?? [];
    _watchedCrops = prefs.getStringList('watched_crops') ?? [];
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    _preferredLanguage = language;
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', enabled);
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
    _darkMode = enabled;
    notifyListeners();
  }

  Future<void> addWatchedMandi(String mandi) async {
    if (!_watchedMandis.contains(mandi)) {
      _watchedMandis.add(mandi);
      await _saveMandis();
      notifyListeners();
    }
  }

  Future<void> removeWatchedMandi(String mandi) async {
    _watchedMandis.remove(mandi);
    await _saveMandis();
    notifyListeners();
  }

  Future<void> addWatchedCrop(String crop) async {
    if (!_watchedCrops.contains(crop)) {
      _watchedCrops.add(crop);
      await _saveCrops();
      notifyListeners();
    }
  }

  Future<void> removeWatchedCrop(String crop) async {
    _watchedCrops.remove(crop);
    await _saveCrops();
    notifyListeners();
  }

  Future<void> _saveMandis() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('watched_mandis', _watchedMandis);
  }

  Future<void> _saveCrops() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('watched_crops', _watchedCrops);
  }
}

