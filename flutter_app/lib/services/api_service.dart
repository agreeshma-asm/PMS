import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  void setToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _headers.remove('Authorization');
  }

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final Map<String, String> getHeaders = Map.from(_headers);
    getHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    getHeaders['Pragma'] = 'no-cache';
    getHeaders['Expires'] = '0';
    
    // Also append timestamp to URL to bust aggressive browser caching
    final separator = uri.query.isEmpty ? '?' : '&';
    final bustedUrl = '${uri.toString()}${separator}_t=${DateTime.now().millisecondsSinceEpoch}';
    
    final response = await http.get(Uri.parse(bustedUrl), headers: getHeaders);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> uploadMultipartFile(String endpoint, List<int> bytes, String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$endpoint'));
    
    // Add auth headers explicitly
    request.headers.addAll(_headers);
    // MultipartRequest already sets Content-Type to multipart/form-data with boundary
    request.headers.remove('Content-Type'); 
    
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
