// Cliente HTTP para datos de perfil, direcciones y preferencias.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Error especifico del modulo de perfil.
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

/// Encapsula llamadas protegidas relacionadas con perfil y preferencias.
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

  /// Lee el token JWT guardado para consumir endpoints privados.
  Future<String> _accessToken() async {
    final token = await _storage.read(key: 'access');
    if (token == null || token.isEmpty) {
      throw ProfileApiException('No access token');
    }
    return token;
  }

  /// Recupera headers autenticados para endpoints privados.
  Future<Map<String, String>> _authHeaders() async {
    final token = await _accessToken();
    return {..._jsonHeaders, 'Authorization': 'Bearer $token'};
  }

  /// Obtiene los datos principales del usuario autenticado.
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

  /// Obtiene las direcciones asociadas al perfil.
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

  /// Crea una nueva direccion usando el payload recibido desde la UI.
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

  /// Actualiza una direccion existente por identificador.
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

  /// Elimina una direccion guardada.
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

  /// Consulta las preferencias de notificacion actuales.
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

  /// Actualiza el mapa completo de preferencias de notificacion.
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

  /// Consulta las rifas activas visibles para el usuario.
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

  /// Obtiene el historial de solicitudes de cambio de rol.
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

  /// Crea una nueva solicitud de cambio de rol.
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

  /// Sube el avatar actual usando multipart/form-data.
  Future<String?> uploadAvatar(XFile file) async {
    try {
      const endpoint = '/auth/me/avatar/';
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl$endpoint'),
      );
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer ${await _accessToken()}';
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            bytes,
            filename: file.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', file.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = _decode(response, endpoint: endpoint);
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        return user['avatar']?.toString();
      }
      return data['avatar']?.toString();
    } on ProfileApiException {
      rethrow;
    } catch (e) {
      throw ProfileApiException(
        'No se pudo subir la foto. ${_friendlyError(e)}',
      );
    }
  }

  /// Elimina el avatar del usuario autenticado.
  Future<void> deleteAvatar() async {
    try {
      const endpoint = '/auth/me/avatar/';
      final res = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return;
      }
      _decode(res, endpoint: endpoint);
      throw ProfileApiException('Error eliminando avatar', statusCode: 500);
    } on ProfileApiException {
      rethrow;
    } catch (e) {
      throw ProfileApiException(
        'No se pudo eliminar la foto. ${_friendlyError(e)}',
      );
    }
  }

  /// Valida el cuerpo JSON y estandariza errores del backend.
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

  /// Extrae un mensaje claro desde respuestas de error heterogeneas.
  String _extractMessage(Map<String, dynamic> data) {
    if (data['detail'] != null) return data['detail'].toString();
    if (data['message'] != null) return data['message'].toString();
    if (data['error'] != null) return data['error'].toString();
    if (data.isNotEmpty) return data.toString();
    return '';
  }

  /// Recorta el body para evitar mensajes de error demasiado largos.
  String _preview(String body) {
    if (body.isEmpty) return '(sin contenido)';
    const limit = 180;
    if (body.length <= limit) return body;
    return '${body.substring(0, limit)}...';
  }

  /// Limpia mensajes tecnicos antes de mostrarlos en la UI.
  String _friendlyError(Object error) {
    final text = error.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }
}
