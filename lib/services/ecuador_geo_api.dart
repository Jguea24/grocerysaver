import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class EcuadorGeoApi {
  EcuadorGeoApi({String? baseUrl})
    : _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/$'), '');

  final String _baseUrl;

  Future<List<Map<String, dynamic>>> getProvinces() async {
    final res = await http.get(Uri.parse('$_baseUrl/geo/ecuador/provinces/'));
    final body = _decodeBody(
      res,
      errorMessage: 'Error cargando provincias',
      key: 'provinces',
    );
    return body;
  }

  Future<List<Map<String, dynamic>>> getCantonsByProvinceId(
    int provinceId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/geo/ecuador/cantons/?province_id=$provinceId'),
    );
    final body = _decodeBody(
      res,
      errorMessage: 'Error cargando cantones',
      key: 'cantons',
    );
    return body;
  }

  List<Map<String, dynamic>> _decodeBody(
    http.Response res, {
    required String errorMessage,
    required String key,
  }) {
    if (res.statusCode != 200) {
      throw Exception('$errorMessage (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('$errorMessage: respuesta invalida');
    }

    final rawList = decoded[key];
    if (rawList is! List) {
      throw Exception('$errorMessage: campo "$key" invalido');
    }

    return rawList.whereType<Map<String, dynamic>>().toList();
  }
}
