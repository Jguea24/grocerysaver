// Cliente HTTP para jobs asincronos de exportacion.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'cache_status_reader.dart';

/// Error especifico del modulo de jobs.
class JobsApiException implements Exception {
  JobsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

/// Gestiona el encolado y seguimiento de jobs protegidos por token.
class JobsApi {
  JobsApi(String baseUrl)
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _storage = const FlutterSecureStorage();

  final String baseUrl;
  final FlutterSecureStorage _storage;
  String? _lastCacheStatus;

  String? get lastCacheStatus => _lastCacheStatus;

  /// Solicita al backend la exportacion asincrona del catalogo.
  Future<Map<String, dynamic>> createExportJob({
    required String format,
    String? search,
    int? categoryId,
  }) async {
    const endpoint = '/jobs/export-products/';
    final cleanFormat = format.trim().toLowerCase();
    if (cleanFormat.isEmpty) {
      throw JobsApiException('El formato de exportacion es obligatorio.');
    }

    final payload = <String, dynamic>{'format': cleanFormat};
    final query = search?.trim() ?? '';
    if (query.isNotEmpty) {
      payload['search'] = query;
    }
    if (categoryId != null) {
      payload['category_id'] = categoryId;
    }

    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(includeJson: true),
      body: jsonEncode(payload),
    );
    final data = _decode(res, endpoint: endpoint);
    if (res.statusCode != 202) {
      throw JobsApiException(
        'Estado inesperado al crear job de exportacion.',
        statusCode: res.statusCode,
      );
    }
    return data;
  }

  /// Consulta el estado actual de un job previamente encolado.
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      throw JobsApiException('El job_id es obligatorio.');
    }

    final endpoint = '/jobs/$cleanJobId/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    return _decode(res, endpoint: endpoint);
  }

  /// Construye headers autenticados y opcionalmente JSON.
  Future<Map<String, String>> _authHeaders({bool includeJson = false}) async {
    final token = await _storage.read(key: 'access');
    if (token == null || token.isEmpty) {
      throw JobsApiException('No hay token de acceso.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (includeJson) 'Content-Type': 'application/json',
    };
  }

  /// Traduce la respuesta HTTP del backend a un mapa validado.
  Map<String, dynamic> _decode(http.Response res, {required String endpoint}) {
    _lastCacheStatus = CacheStatusReader.fromHeaders(res.headers);

    final contentType = (res.headers['content-type'] ?? '').toLowerCase();
    final body = res.body.trim();
    if (!contentType.contains('application/json')) {
      throw JobsApiException(
        'Respuesta no JSON (${res.statusCode}) en $endpoint: ${_preview(body)}',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw JobsApiException(
        'Formato de respuesta no valido en $endpoint.',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    throw JobsApiException(
      _extractMessage(decoded).isEmpty
          ? 'Error consumiendo jobs.'
          : _extractMessage(decoded),
      statusCode: res.statusCode,
    );
  }

  /// Extrae el mensaje mas representativo de una respuesta de error.
  String _extractMessage(Map<String, dynamic> data) {
    if (data['detail'] != null) {
      return _toHumanMessage(data['detail'].toString());
    }
    if (data['message'] != null) {
      return _toHumanMessage(data['message'].toString());
    }
    if (data['error'] != null) {
      return _toHumanMessage(data['error'].toString());
    }
    if (data.isNotEmpty) {
      return _toHumanMessage(data.toString());
    }
    return '';
  }

  /// Traduce errores tecnicos frecuentes del backend a mensajes para usuario.
  String _toHumanMessage(String raw) {
    final text = raw.trim();
    final normalized = text.toLowerCase();

    if (normalized.contains('token not valid') ||
        normalized.contains('given token not valid') ||
        normalized.contains('token is invalid') ||
        normalized.contains('invalid token')) {
      return 'Tu sesion expiro o el token ya no es valido. Inicia sesion otra vez.';
    }

    if (normalized.contains('token') && normalized.contains('expired')) {
      return 'Tu sesion expiro. Inicia sesion otra vez.';
    }

    return text;
  }

  /// Acorta bodies extensos para errores mas legibles.
  String _preview(String body) {
    if (body.isEmpty) return '(sin contenido)';
    const limit = 180;
    if (body.length <= limit) return body;
    return '${body.substring(0, limit)}...';
  }
}
