import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/expense.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  // 10.0.2.2 is the special alias to reach the host machine's localhost
  // from the Android emulator.
  static const String baseUrl = 'http://172.20.10.5:8000';

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // ---------- Token management ----------

  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------- Auth ----------

  Future<void> register(String name, String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw ApiException(body['detail']?.toString() ?? 'Registration failed');
    }
  }

  Future<void> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'username': email,
            'password': password,
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(body['detail']?.toString() ?? 'Login failed');
    }

    final data = jsonDecode(response.body);
    await _saveToken(data['access_token']);
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<void> deleteAccount() async {
  final response = await http
      .delete(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _authHeaders(),
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 204) {
    throw ApiException('Failed to delete account');
  }

  await clearToken();
}

  // ---------- Expenses ----------

  Future<List<Expense>> getExpenses() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/expenses/'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException('Failed to load expenses');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Expense.fromJson(json)).toList();
  }

  Future<Expense> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/expenses/'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'title': title,
            'amount': amount,
            'category': category,
            'date': date.toIso8601String(),
            'note': note,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw ApiException('Failed to add expense');
    }

    return Expense.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteExpense(String id) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/expenses/$id'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 204) {
      throw ApiException('Failed to delete expense');
    }
  }
}