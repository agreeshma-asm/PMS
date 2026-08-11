import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _userRole = 'Operator';

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get userRole => _userRole;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('user_role');
    if (token != null) {
      _apiService.setToken(token);
      _isAuthenticated = true;
      _userRole = role ?? 'Operator';
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
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        await prefs.setString('user_role', _userRole);
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      await GoogleSignIn.instance.initialize(
        clientId: 'YOUR_GOOGLE_CLIENT_ID',
      );
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        // User canceled login
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken != null) {
        final response = await _apiService.post('/auth/google', body: {
          'idToken': idToken,
        });
        
        if (response['token'] != null) {
          _apiService.setToken(response['token']);
          _isAuthenticated = true;
          _userRole = response['user']?['role'] ?? 'Operator';
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', response['token']);
          await prefs.setString('user_role', _userRole);
        }
      }
    } catch (e) {
      debugPrint('Google login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userRole = 'Operator';
    _apiService.clearToken();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    notifyListeners();
  }
}
