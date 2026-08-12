import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CardsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _workOrders = [];
  List<dynamic> _routeCards = [];
  List<dynamic> _alerts = [];
  Map<String, dynamic> _riskSummary = {};
  List<String> _koNumbers = [];

  bool _isLoading = false;

  List<dynamic> get workOrders => _workOrders;
  List<dynamic> get routeCards => _routeCards;
  List<dynamic> get alerts => _alerts;
  Map<String, dynamic> get riskSummary => _riskSummary;
  List<String> get koNumbers => _koNumbers;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _apiService.get('/pms/risk-summary'),
        _apiService.get('/pms/alerts?limit=20'),
        _apiService.get('/route-cards'),
        _apiService.get('/pms/ko-numbers'),
        _apiService.get('/pms/work-orders'),
      ]);

      if (results[0] != null) _riskSummary = results[0];
      if (results[1] != null) _alerts = results[1];
      if (results[2] != null) _routeCards = results[2];
      if (results[3] != null) _koNumbers = List<String>.from(results[3]);
      if (results[4] != null) _workOrders = results[4];
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchCardDetails(String cardId) async {
    try {
      final result = await _apiService.get('/route-cards/$cardId');
      return result;
    } catch (e) {
      print('Error fetching card details: $e');
      return null;
    }
  }

  Future<void> createRouteCard(Map<String, dynamic> data) async {
    try {
      await _apiService.post('/route-cards', body: data);
      await fetchDashboardData();
    } catch (e) {
      print('Error creating route card: $e');
      rethrow;
    }
  }

  Future<void> signOffStep(String cardId, String stepId, String operatorName, String role, {String? remarks, int? qty}) async {
    try {
      await _apiService.put('/route-cards/$cardId/steps/$stepId/sign-off', body: {
        'operatorName': operatorName,
        'operatorRole': role,
        'remarks': remarks ?? '',
        if (qty != null) 'completionQty': qty,
      });
      await fetchDashboardData();
    } catch (e) {
      print('Error signing off step: $e');
    }
  }

  Future<void> resolveDeviation(String id, String stepId, Map<String, dynamic> data) async {
    await _apiService.put('/route-cards/$id/steps/$stepId/resolve', body: data);
    await fetchDashboardData();
  }

  Future<Map<String, dynamic>> uploadBom(List<int> bytes, String filename) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.uploadMultipartFile('/bom/parse', bytes, filename);
      return response as Map<String, dynamic>;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> bulkCreateRouteCards(String koNumber, String bomNumber, List<dynamic> items) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('/bom/bulk-create', body: {
        'koNumber': koNumber,
        'bomNumber': bomNumber,
        'items': items,
      });
      await fetchDashboardData();
      return response['createdCount'] ?? 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> progressStep(String cardId, String stepId) async {
    try {
      await _apiService.put('/route-cards/$cardId/steps/$stepId/progress');
      await fetchDashboardData();
    } catch (e) {
      print('Error progressing step: $e');
    }
  }

  Future<void> flagDeviation(String cardId, String stepId, String reason, {String? remarks}) async {
    try {
      await _apiService.put('/route-cards/$cardId/steps/$stepId/flag', body: {
        'reason': reason,
        'remarks': remarks ?? '',
      });
      await fetchDashboardData();
    } catch (e) {
      print('Error flagging deviation: $e');
    }
  }

  Future<void> iqcFail(String cardId, String stepId, String reason, String remarks, String operatorName) async {
    try {
      await _apiService.put('/route-cards/$cardId/steps/$stepId/iqc-fail', body: {
        'reason': reason,
        'remarks': remarks,
        'operatorName': operatorName,
      });
      await fetchDashboardData();
    } catch (e) {
      print('Error on IQC Fail: $e');
    }
  }

  Future<void> iqcReinspect(String cardId, String stepId, String remarks, String operatorName) async {
    try {
      await _apiService.put('/route-cards/$cardId/steps/$stepId/iqc-reinspect', body: {
        'remarks': remarks,
        'operatorName': operatorName,
      });
      await fetchDashboardData();
    } catch (e) {
      print('Error on IQC Reinspect: $e');
    }
  }
}
