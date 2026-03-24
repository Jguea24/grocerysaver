import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

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
  static const _legacyAccessTokenKey = 'access';

  final String _baseUrl;
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  Future<dynamic> get(String path, {bool auth = false, Map<String, String>? queryParameters}) {
    return _request('GET', path, auth: auth, queryParameters: queryParameters);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = false}) {
    return _request('POST', path, auth: auth, body: body);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool auth = false}) {
    return _request('PATCH', path, auth: auth, body: body);
  }

  Future<dynamic> delete(String path, {bool auth = false}) {
    return _request('DELETE', path, auth: auth);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    bool auth = false,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty ? null : queryParameters,
    );

    final headers = await _buildHeaders(auth: auth);

    late final http.Response response;
    switch (method) {
      case 'POST':
        response = await _httpClient.post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}));
        break;
      case 'PATCH':
        response = await _httpClient.patch(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}));
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

  Future<Map<String, String>> _buildHeaders({required bool auth}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (!auth) return headers;

    final token = await _secureStorage.read(key: _accessTokenKey) ??
        await _secureStorage.read(key: _legacyAccessTokenKey);

    if (token == null || token.isEmpty) {
      throw ApiException('No hay token JWT disponible para esta ruta privada.');
    }

    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic _handle(http.Response response) {
    final body = response.body.trim();
    dynamic decoded;

    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(_extractError(decoded, response.statusCode), statusCode: response.statusCode);
  }

  String _extractError(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final direct = [decoded['detail'], decoded['message'], decoded['error']]
          .where((value) => value != null)
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (direct.isNotEmpty) {
        return direct.first;
      }

      final fieldErrors = <String>[];
      for (final entry in decoded.entries) {
        if (entry.value is List) {
          final text = (entry.value as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .join(', ');
          if (text.isNotEmpty) {
            fieldErrors.add('${entry.key}: $text');
          }
        }
      }
      if (fieldErrors.isNotEmpty) {
        return fieldErrors.join('\n');
      }
    }

    if (decoded is String && decoded.isNotEmpty) {
      return decoded;
    }

    return 'API error $statusCode';
  }
}

