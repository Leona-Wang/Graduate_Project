import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  String? _token;

  ApiClient();

  // 初始化，從 SharedPreferences 讀取 Token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('accessToken');
  }

  // 設定 Token 並存到 SharedPreferences
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }

  // 清除 Token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
  }

  // POST
  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return http.post(
      Uri.parse('$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
  }

  // GET
  Future<http.Response> get(String path) async {
    return http.get(Uri.parse('$path'), headers: _headers());
  }

  // Header
  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }
}
