// Cliente HTTP para enviar lecturas de sensores del dispositivo.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Error tipado para el envio de datos de sensores.
class DeviceSensorsApiException implements Exception {
  DeviceSensorsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

/// Servicio ligero para registrar acelerometro y giroscopio en el backend.
class DeviceSensorsApi {
  const DeviceSensorsApi._();

  static String get baseUrl =>
      ApiConfig.baseUrl.replaceFirst(RegExp(r'/$'), '');
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Reutiliza el token persistido por el flujo de login actual.
  static Future<String> _resolveAccessToken(String? authToken) async {
    final explicitToken = authToken?.trim() ?? '';
    if (explicitToken.isNotEmpty) {
      return explicitToken;
    }

    final storedToken = (await _storage.read(key: 'access'))?.trim() ?? '';
    if (storedToken.isNotEmpty) {
      return storedToken;
    }

    throw DeviceSensorsApiException(
      'No hay access token. Debes iniciar sesion antes de enviar sensores.',
    );
  }

  /// Publica una lectura de sensores contra `/device-sensors/`.
  static Future<void> submitReading({
    required double accelerometerX,
    required double accelerometerY,
    required double accelerometerZ,
    required double gyroscopeX,
    required double gyroscopeY,
    required double gyroscopeZ,
    required bool isShaking,
    String? authToken,
  }) async {
    final accessToken = await _resolveAccessToken(authToken);
    final uri = Uri.parse('$baseUrl/device-sensors/');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'accelerometer': {
          'x': accelerometerX,
          'y': accelerometerY,
          'z': accelerometerZ,
        },
        'gyroscope': {'x': gyroscopeX, 'y': gyroscopeY, 'z': gyroscopeZ},
        'is_shaking': isShaking,
        'captured_at': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'No se pudieron enviar los datos.';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        message = (decoded['detail'] ?? decoded['message'] ?? message)
            .toString();
      } else if (response.body.trim().isNotEmpty) {
        message = response.body;
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        message = response.body;
      }
    }

    throw DeviceSensorsApiException(message, statusCode: response.statusCode);
  }
}
