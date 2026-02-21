import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiService {
  ApiService._();

  static String get baseUrl => ApiConfig.baseUrl.replaceFirst(RegExp(r'/$'), '');

  static Future<Map<String, dynamic>> comparePricesByProductId(
    int productId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/compare-prices/',
    ).replace(queryParameters: {'product_id': '$productId'});

    final res = await http.get(uri, headers: const {'Accept': 'application/json'});

    final dynamic decoded = jsonDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception(
      (data['detail'] ?? data['message'] ?? 'Error al comparar precios')
          .toString(),
    );
  }
}
