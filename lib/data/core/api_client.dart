import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final suffix = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$suffix';
  }
}

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  }) : _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/$'), ''),
       _httpClient = httpClient ?? http.Client(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final String _baseUrl;
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  String? _accessToken;

  Future<void> restoreSession() async {
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
  }

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessToken = accessToken;
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clearSession() async {
    _accessToken = null;
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<dynamic> get(
    String path, {
    bool auth = false,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'GET',
      path,
      auth: auth,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return _request('POST', path, body: body, auth: auth);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return _request('PATCH', path, body: body, auth: auth);
  }

  Future<dynamic> delete(String path, {bool auth = false}) {
    return _request('DELETE', path, auth: auth);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters?.isEmpty == true ? null : queryParameters,
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (auth && (_accessToken ?? '').isNotEmpty)
        'Authorization': 'Bearer $_accessToken',
    };

    late final http.Response response;
    switch (method) {
      case 'POST':
        response = await _httpClient.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
        break;
      case 'PATCH':
        response = await _httpClient.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
        break;
      case 'DELETE':
        response = await _httpClient.delete(uri, headers: headers);
        break;
      case 'GET':
      default:
        response = await _httpClient.get(uri, headers: headers);
        break;
    }

    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    final body = response.body.trim();
    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = _extractErrorMessage(
      decoded,
      response.statusCode,
      rawBody: body,
    );
    throw ApiException(message, statusCode: response.statusCode);
  }

  String _extractErrorMessage(
    dynamic decoded,
    int statusCode, {
    required String rawBody,
  }) {
    if (decoded is Map<String, dynamic>) {
      final direct = [
        decoded['detail'],
        decoded['message'],
        decoded['error'],
        decoded['non_field_errors'],
      ].where((value) => value != null).toList();
      if (direct.isNotEmpty) {
        return _normalizeErrorValue(direct.first);
      }

      final fieldErrors = <String>[];
      for (final entry in decoded.entries) {
        final key = entry.key;
        if (key == 'detail' || key == 'message' || key == 'error' || key == 'non_field_errors') {
          continue;
        }
        final value = _normalizeErrorValue(entry.value);
        if (value.isNotEmpty) {
          fieldErrors.add('$key: $value');
        }
      }
      if (fieldErrors.isNotEmpty) {
        return fieldErrors.join('\n');
      }
    }

    if (decoded is List && decoded.isNotEmpty) {
      return decoded
          .map(_normalizeErrorValue)
          .where((item) => item.isNotEmpty)
          .join('\n');
    }

    if (rawBody.isNotEmpty) {
      return rawBody.length > 300 ? '${rawBody.substring(0, 300)}...' : rawBody;
    }

    return 'API error $statusCode';
  }

  String _normalizeErrorValue(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .join(', ');
    }
    return value.toString().trim();
  }
}
