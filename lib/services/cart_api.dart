// Cliente HTTP autenticado para consultar y modificar el carrito.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Error especifico del modulo de carrito.
class CartApiException implements Exception {
  CartApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

/// Encapsula operaciones protegidas del carrito usando Bearer token.
class CartApi {
  CartApi(String baseUrl)
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _storage = const FlutterSecureStorage();

  final String baseUrl;
  final FlutterSecureStorage _storage;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Recupera el carrito actual del usuario autenticado.
  Future<Map<String, dynamic>> getCart() async {
    const endpoint = '/cart/';
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    return _decode(res, endpoint: endpoint);
  }

  /// Agrega un producto al carrito con cantidad y tienda opcional.
  Future<Map<String, dynamic>> addCartItem({
    required int productId,
    int quantity = 1,
    int? storeId,
  }) async {
    const endpoint = '/cart/items/';
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
        'store_id': ?storeId,
      }),
    );
    return _decode(res, endpoint: endpoint);
  }

  /// Actualiza cantidad o tienda de un item ya agregado.
  Future<Map<String, dynamic>> updateCartItem({
    required int itemId,
    int? quantity,
    int? storeId,
  }) async {
    final endpoint = '/cart/items/$itemId/';
    final res = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'quantity': ?quantity,
        'store_id': ?storeId,
      }),
    );
    return _decode(res, endpoint: endpoint);
  }

  /// Elimina un item individual del carrito.
  Future<void> deleteCartItem(int itemId) async {
    final endpoint = '/cart/items/$itemId/';
    final res = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 204) {
      return;
    }
    _decode(res, endpoint: endpoint);
    throw CartApiException(
      'Estado inesperado al eliminar item del carrito.',
      statusCode: res.statusCode,
    );
  }

  /// Vacia completamente el carrito del usuario autenticado.
  Future<void> clearCart() async {
    const endpoint = '/cart/';
    final res = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 204) {
      return;
    }
    _decode(res, endpoint: endpoint);
    throw CartApiException(
      'Estado inesperado al vaciar carrito.',
      statusCode: res.statusCode,
    );
  }

  /// Construye headers autenticados en JSON.
  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access');
    if (token == null || token.isEmpty) {
      throw CartApiException('No hay token de acceso.');
    }
    return {..._jsonHeaders, 'Authorization': 'Bearer $token'};
  }

  /// Valida JSON de respuesta y normaliza errores del backend.
  Map<String, dynamic> _decode(http.Response res, {required String endpoint}) {
    final contentType = (res.headers['content-type'] ?? '').toLowerCase();
    final body = res.body.trim();
    if (!contentType.contains('application/json')) {
      throw CartApiException(
        'Respuesta no JSON (${res.statusCode}) en $endpoint: ${_preview(body)}',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw CartApiException(
        'Formato de respuesta no valido en $endpoint.',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    throw CartApiException(
      _extractMessage(decoded).isEmpty
          ? 'Error consumiendo carrito.'
          : _extractMessage(decoded),
      statusCode: res.statusCode,
    );
  }

  /// Busca el mensaje de error mas util en respuestas heterogeneas.
  String _extractMessage(Map<String, dynamic> data) {
    if (data['detail'] != null) return data['detail'].toString();
    if (data['message'] != null) return data['message'].toString();
    if (data['error'] != null) return data['error'].toString();
    if (data.isNotEmpty) return data.toString();
    return '';
  }

  /// Recorta bodies extensos antes de incluirlos en el error.
  String _preview(String body) {
    if (body.isEmpty) return '(sin contenido)';
    const limit = 180;
    if (body.length <= limit) return body;
    return '${body.substring(0, limit)}...';
  }
}
