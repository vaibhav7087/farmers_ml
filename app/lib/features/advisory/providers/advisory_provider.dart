import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';

class AdvisoryData {
  final String district;
  final String crop;
  final String mandi;
  final double predictedYield;
  final double predictedPrice;
  final double confidence;
  final double grossRevenue;
  final double netProfit;
  final List<String> recommendations;
  final DateTime generatedAt;

  AdvisoryData({
    required this.district,
    required this.crop,
    required this.mandi,
    required this.predictedYield,
    required this.predictedPrice,
    required this.confidence,
    required this.grossRevenue,
    required this.netProfit,
    required this.recommendations,
    required this.generatedAt,
  });

  factory AdvisoryData.fromJson(Map<String, dynamic> json) => AdvisoryData(
    district: json['district'],
    crop: json['crop'],
    mandi: json['mandi'],
    predictedYield: (json['predictions']['yield']['value'] as num).toDouble(),
    predictedPrice: (json['predictions']['price']['value'] as num).toDouble(),
    confidence: (json['predictions']['yield']['confidence'] as num).toDouble(),
    grossRevenue: (json['economics']['gross_revenue_inr_per_ha'] as num).toDouble(),
    netProfit: (json['economics']['estimated_net_profit_inr_per_ha'] as num).toDouble(),
    recommendations: List<String>.from(json['recommendations']),
    generatedAt: DateTime.parse(json['generated_at']),
  );
}

class AdvisoryProvider extends ChangeNotifier {
  AdvisoryData? _currentAdvisory;
  bool _isLoading = false;
  String? _error;

  AdvisoryData? get currentAdvisory => _currentAdvisory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kisaan-ml-api.bylancetechnologies.workers.dev/api/v1',
  );

  Future<void> fetchAdvisory({
    required String district,
    required String crop,
    required String mandi,
    String? variety,
    int? sowingWeek,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse('$baseUrl/advisory');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'district': district,
          'crop': crop,
          'mandi': mandi,
          if (variety != null) 'variety': variety,
          if (sowingWeek != null) 'sowing_week': sowingWeek,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _currentAdvisory = AdvisoryData.fromJson(jsonDecode(response.body));
      } else {
        _error = 'सलाह प्राप्त करने में विफल: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'नेटवर्क त्रुटि: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchYieldPrediction({
    required String district,
    required String crop,
    String? season,
    int? sowingWeek,
    bool useSatellite = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse('$baseUrl/predict/yield').replace(queryParameters: {
        'district': district,
        'crop': crop,
        if (season != null) 'season': season,
        if (sowingWeek != null) 'sowing_week': sowingWeek.toString(),
        'use_satellite': useSatellite.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Handle yield prediction response
        print('Yield prediction: ${response.body}');
      }
    } catch (e) {
      print('Yield prediction error: $e');
    }
  }

  Future<void> fetchPricePrediction({
    required String mandi,
    required String crop,
    String? variety,
    int horizonDays = 14,
    bool includePolicy = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse('$baseUrl/predict/price').replace(queryParameters: {
        'mandi': mandi,
        'crop': crop,
        if (variety != null) 'variety': variety,
        'horizon_days': horizonDays.toString(),
        'include_policy': includePolicy.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('Price prediction: ${response.body}');
      }
    } catch (e) {
      print('Price prediction error: $e');
    }
  }

  void clear() {
    _currentAdvisory = null;
    _error = null;
    notifyListeners();
  }
}