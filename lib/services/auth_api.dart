import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode != null ? ' (HTTP $statusCode)' : '';
    return '$message$code';
  }
}

class AuthApi {
  AuthApi(String baseUrl)
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _storage = const FlutterSecureStorage();

  final String baseUrl;
  final FlutterSecureStorage _storage;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<String>> getRoles() async {
    const endpoint = '/auth/roles/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: const {'Accept': 'application/json'},
    );
    final data = _decode(res, endpoint: endpoint);
    final roles = data['roles'];
    if (roles is! List) {
      throw ApiException(
        'Respuesta invalida en $endpoint: no contiene lista de roles.',
        statusCode: res.statusCode,
      );
    }
    final parsed = roles
        .map((role) {
          if (role is Map<String, dynamic> && role['name'] != null) {
            return role['name'].toString();
          }
          return role.toString();
        })
        .where((role) => role.trim().isNotEmpty)
        .toList();

    if (parsed.isEmpty) {
      throw ApiException(
        'Respuesta invalida en $endpoint: lista de roles vacia.',
        statusCode: res.statusCode,
      );
    }

    return parsed;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    required String firstName,
    required String lastName,
    required String address,
    required String birthDate,
  }) async {
    const endpoint = '/auth/register/';
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        'address': address,
        'birth_date': birthDate,
      }),
    );
    return _decode(res, endpoint: endpoint);
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    const endpoint = '/auth/verify-email/';
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _jsonHeaders,
      body: jsonEncode({'token': token}),
    );
    final data = _decode(res, endpoint: endpoint);
    await _saveTokensFrom(data);
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    const endpoint = '/auth/login/';
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res, endpoint: endpoint);
    await _saveTokensFrom(data);
    return data;
  }

  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    String? idToken,
    String? providerUserId,
    String? email,
    String firstName = '',
    String lastName = '',
  }) async {
    const endpoint = '/auth/social-login/';
    final payload = <String, dynamic>{
      'provider': provider,
      'first_name': firstName,
      'last_name': lastName,
    };
    if (idToken != null && idToken.isNotEmpty) {
      payload['id_token'] = idToken;
    }
    if (providerUserId != null && providerUserId.isNotEmpty) {
      payload['provider_user_id'] = providerUserId;
    }
    if (email != null && email.isNotEmpty) {
      payload['email'] = email;
    }

    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );
    final data = _decode(res, endpoint: endpoint);
    await _saveTokensFrom(data);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    const endpoint = '/auth/me/';
    final access = await _storage.read(key: 'access');
    if (access == null || access.isEmpty) {
      throw ApiException('No hay token de acceso para consultar perfil.');
    }
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $access',
        'Accept': 'application/json',
      },
    );
    return _decode(res, endpoint: endpoint);
  }

  Future<Map<String, dynamic>> adminOnly() async {
    const endpoint = '/protected/admin-only/';
    final access = await _storage.read(key: 'access');
    if (access == null || access.isEmpty) {
      throw ApiException('No hay token de acceso para consultar ruta admin.');
    }
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $access',
        'Accept': 'application/json',
      },
    );
    return _decode(res, endpoint: endpoint);
  }

  Future<Map<String, dynamic>> logout() async {
    const endpoint = '/auth/logout/';
    final access = await _storage.read(key: 'access');
    final refresh = await _storage.read(key: 'refresh');
    if (refresh == null || refresh.isEmpty) {
      await clearTokens();
      return {'detail': 'No habia refresh token para cerrar sesion.'};
    }

    final headers = <String, String>{..._jsonHeaders};
    if (access != null && access.isNotEmpty) {
      headers['Authorization'] = 'Bearer $access';
    }

    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode({'refresh': refresh}),
    );
    final data = _decode(res, endpoint: endpoint);
    await clearTokens();
    return data;
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
  }

  Map<String, dynamic> _decode(http.Response res, {required String endpoint}) {
    final contentType = (res.headers['content-type'] ?? '').toLowerCase();
    final body = res.body.trim();
    if (!contentType.contains('application/json')) {
      throw ApiException(
        'Respuesta no JSON (${res.statusCode}) en $endpoint: ${_preview(body)}',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Formato de respuesta no valido en $endpoint.',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      _extractMessage(decoded).isEmpty
          ? 'Error de autenticacion.'
          : _extractMessage(decoded),
      statusCode: res.statusCode,
    );
  }

  Future<void> _saveTokensFrom(Map<String, dynamic> data) async {
    final tokens = data['tokens'];
    if (tokens is! Map<String, dynamic>) {
      return;
    }
    final access = tokens['access']?.toString();
    final refresh = tokens['refresh']?.toString();
    if (access != null && access.isNotEmpty) {
      await _storage.write(key: 'access', value: access);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: 'refresh', value: refresh);
    }
  }

  String _extractMessage(Map<String, dynamic> data) {
    if (data['detail'] != null) return data['detail'].toString();
    if (data['message'] != null) return data['message'].toString();
    if (data['error'] != null) return data['error'].toString();
    if (data.isNotEmpty) return data.toString();
    return '';
  }

  String _preview(String body) {
    if (body.isEmpty) return '(sin contenido)';
    const limit = 180;
    if (body.length <= limit) return body;
    return '${body.substring(0, limit)}...';
  }
}
