import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ScanApiException implements Exception {
  ScanApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

class ScanApi {
  const ScanApi._();

  static String get baseUrl =>
      kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';

  static Future<Map<String, dynamic>> scanCode({
    required String code,
    String? codeType, // 'barcode' | 'qr'
    int? categoryId,
    String? name,
    String? brand,
    String? description,
    int? storeId,
    String? price,
  }) async {
    final codeText = code.trim();
    final codeTypeText = codeType?.trim();
    final nameText = name?.trim();
    final brandText = brand?.trim();
    final descriptionText = description?.trim();
    final priceText = price?.trim();

    final payload = <String, dynamic>{
      'code': codeText,
      if (codeTypeText?.isNotEmpty ?? false) 'code_type': codeTypeText,
      ...?categoryId == null ? null : {'category_id': categoryId},
      if (nameText?.isNotEmpty ?? false) 'name': nameText,
      if (brandText?.isNotEmpty ?? false) 'brand': brandText,
      if (descriptionText?.isNotEmpty ?? false) 'description': descriptionText,
      ...?storeId == null ? null : {'store_id': storeId},
      if (priceText?.isNotEmpty ?? false) 'price': priceText,
    };

    final uri = Uri.parse('$baseUrl/products/scan/');
    final res = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      throw ScanApiException(
        'Respuesta invalida del servidor',
        statusCode: res.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ScanApiException(
        'Respuesta invalida del servidor',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      return decoded;
    }

    throw ScanApiException(
      (decoded['detail'] ?? 'Error al escanear producto').toString(),
      statusCode: res.statusCode,
    );
  }
}
