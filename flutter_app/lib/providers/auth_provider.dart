import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _userRole = 'Operator';
  String _userName = '';
  String _userEmail = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get userRole => _userRole;
  String get userName => _userName;
  String get userEmail => _userEmail;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('user_role');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    if (token != null) {
      _apiService.setToken(token);
      _isAuthenticated = true;
      _userRole = role ?? 'Operator';
      _userName = name ?? '';
      _userEmail = email ?? '';
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      if (response['token'] != null) {
        _apiService.setToken(response['token']);
        _isAuthenticated = true;
        _userRole = response['user']?['role'] ?? 'Operator';
        _userName = response['user']?['name'] ?? '';
        _userEmail = response['user']?['email'] ?? email;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        await prefs.setString('user_role', _userRole);
        await prefs.setString('user_name', _userName);
        await prefs.setString('user_email', _userEmail);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String name, String email, String password, {String role = 'Operator'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('/auth/signup', body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      if (response != null && response['success'] == true) {
        if (response['token'] != null) {
          _apiService.setToken(response['token']);
          _isAuthenticated = true;
          _userRole = response['user']?['role'] ?? role;
          _userName = response['user']?['name'] ?? name;
          _userEmail = response['user']?['email'] ?? email;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', response['token']);
          await prefs.setString('user_role', _userRole);
          await prefs.setString('user_name', _userName);
          await prefs.setString('user_email', _userEmail);
        }
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Organization login: validates @asmltd.com domain, registers with role, and logs in.
  Future<void> loginWithOrgEmail(String name, String email, String role) async {
    // Enforce org domain
    if (!email.trim().toLowerCase().endsWith('@asmltd.com')) {
      throw Exception('Only @asmltd.com email addresses are allowed.');
    }
    
    _isLoading = true;
    notifyListeners();
    try {
      // Try signup first (will fail gracefully if user exists)
      try {
        await _apiService.post('/auth/signup', body: {
          'name': name,
          'email': email,
          'password': 'org-sso-${email.hashCode}',
          'role': role,
        });
      } catch (_) {
        // User may already exist — proceed to login
      }
      
      // Now login
      final response = await _apiService.post('/auth/login', body: {
        'email': email,
        'password': 'org-sso-${email.hashCode}',
      });
      
      if (response['token'] != null) {
        _apiService.setToken(response['token']);
        _isAuthenticated = true;
        _userRole = response['user']?['role'] ?? role;
        _userName = response['user']?['name'] ?? name;
        _userEmail = response['user']?['email'] ?? email;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        await prefs.setString('user_role', _userRole);
        await prefs.setString('user_name', _userName);
        await prefs.setString('user_email', _userEmail);
      }
    } catch (e) {
      debugPrint('Org login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/auth/forgot-password', body: {
        'email': email,
      });
    } catch (e) {
      debugPrint('Forgot password error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userRole = 'Operator';
    _userName = '';
    _userEmail = '';
    _apiService.clearToken();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    
    notifyListeners();
  }
}
