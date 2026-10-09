import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Translate known sample values from profiles saved before the English UI update.
// Unrecognized user-entered values are preserved.
String englishProfileValue(String value) => const {
  'किसान': 'Farmer', 'यवतमाळ': 'Yavatmal', 'अमरावती': 'Amravati',
  'अकोला': 'Akola', 'वर्धा': 'Wardha', 'नागपुर': 'Nagpur',
  'महाराष्ट्र': 'Maharashtra', 'कपास': 'Cotton', 'सोयाबीन': 'Soybean',
  'मक्का': 'Maize', 'गेहूं': 'Wheat', 'चावल': 'Rice', 'तुअर': 'Pigeon pea',
}[value] ?? value;

class User {
  final String id;
  final String name;
  final String phone;
  final String district;
  final String state;
  final List<String> crops;
  final String language;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.district,
    required this.state,
    required this.crops,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'district': district,
    'state': state,
    'crops': crops,
    'language': language,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: englishProfileValue(json['name']),
    phone: json['phone'],
    district: englishProfileValue(json['district']),
    state: englishProfileValue(json['state']),
    crops: List<String>.from(json['crops']).map(englishProfileValue).toList(),
    language: json['language'],
  );
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  static const _userKey = 'kisaan_user';
  static const _onboardingKey = 'kisaan_onboarding_done';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> checkOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_onboardingKey, true);
    _user = user;
    notifyListeners();
  }

  Future<void> login(String phone, String otp) async {
    // In production, verify OTP with backend
    // For demo, create a mock user
    final user = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Farmer',
      phone: phone,
      district: 'Yavatmal',
      state: 'Maharashtra',
      crops: ['Cotton', 'Soybean'],
      language: 'en',
    );
    await completeOnboarding(user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? district, String? state, List<String>? crops, String? language}) async {
    if (_user == null) return;
    _user = User(
      id: _user!.id,
      name: name ?? _user!.name,
      phone: _user!.phone,
      district: district ?? _user!.district,
      state: state ?? _user!.state,
      crops: crops ?? _user!.crops,
      language: language ?? _user!.language,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }
}

