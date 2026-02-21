import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProfileApiException implements Exception {
  ProfileApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

class ProfileApi {
  ProfileApi(String baseUrl)
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _storage = const FlutterSecureStorage();

  final String baseUrl;
  final FlutterSecureStorage _storage;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access');
    if (token == null || token.isEmpty) {
      throw ProfileApiException('No access token');
    }
    return {..._jsonHeaders, 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> getMe() async {
    const endpoint = '/auth/me/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    final data = _decode(res, endpoint: endpoint);
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    return data;
  }

  Future<List<dynamic>> getAddresses() async {
    const endpoint = '/profile/addresses/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    final data = _decode(res, endpoint: endpoint);
    final addresses = data['addresses'];
    if (addresses is List<dynamic>) {
      return addresses;
    }
    return const [];
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) async {
    const endpoint = '/profile/addresses/';
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    final data = _decode(res, endpoint: endpoint);
    final address = data['address'];
    if (address is Map<String, dynamic>) {
      return address;
    }
    return data;
  }

  Future<Map<String, dynamic>> updateAddress(
    int id,
    Map<String, dynamic> body,
  ) async {
    final endpoint = '/profile/addresses/$id/';
    final res = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    final data = _decode(res, endpoint: endpoint);
    final address = data['address'];
    if (address is Map<String, dynamic>) {
      return address;
    }
    return data;
  }

  Future<void> deleteAddress(int id) async {
    final endpoint = '/profile/addresses/$id/';
    final res = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 204) {
      return;
    }
    _decode(res, endpoint: endpoint);
    throw ProfileApiException('Error eliminando direccion', statusCode: 500);
  }

  Future<Map<String, dynamic>> getNotificationPrefs() async {
    const endpoint = '/profile/notifications/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    final data = _decode(res, endpoint: endpoint);
    final prefs = data['notification_preferences'];
    if (prefs is Map<String, dynamic>) {
      return prefs;
    }
    return data;
  }

  Future<Map<String, dynamic>> updateNotificationPrefs(
    Map<String, dynamic> body,
  ) async {
    const endpoint = '/profile/notifications/';
    final res = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    final data = _decode(res, endpoint: endpoint);
    final prefs = data['notification_preferences'];
    if (prefs is Map<String, dynamic>) {
      return prefs;
    }
    return data;
  }

  Future<List<dynamic>> getActiveRaffles() async {
    const endpoint = '/raffles/active/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    final data = _decode(res, endpoint: endpoint);
    final raffles = data['raffles'];
    if (raffles is List<dynamic>) {
      return raffles;
    }
    return const [];
  }

  Future<List<dynamic>> getRoleChangeRequests() async {
    const endpoint = '/profile/role-change-requests/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    final data = _decode(res, endpoint: endpoint);
    final requests = data['requests'];
    if (requests is List<dynamic>) {
      return requests;
    }
    return const [];
  }

  Future<Map<String, dynamic>> createRoleChangeRequest(
    String role, {
    String reason = '',
  }) async {
    const endpoint = '/profile/role-change-requests/';
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode({'requested_role': role, 'reason': reason}),
    );
    final data = _decode(res, endpoint: endpoint);
    final request = data['request'];
    if (request is Map<String, dynamic>) {
      return request;
    }
    return data;
  }

  Map<String, dynamic> _decode(http.Response res, {required String endpoint}) {
    final contentType = (res.headers['content-type'] ?? '').toLowerCase();
    final body = res.body.trim();
    if (!contentType.contains('application/json')) {
      throw ProfileApiException(
        'Respuesta no JSON (${res.statusCode}) en $endpoint: ${_preview(body)}',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw ProfileApiException(
        'Formato de respuesta no valido en $endpoint.',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    throw ProfileApiException(
      _extractMessage(decoded).isEmpty
          ? 'Error consumiendo perfil.'
          : _extractMessage(decoded),
      statusCode: res.statusCode,
    );
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
