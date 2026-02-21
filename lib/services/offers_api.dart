import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OffersPage {
  const OffersPage({
    required this.offers,
    required this.hasNext,
    required this.nextPage,
    required this.totalCount,
  });

  final List<Map<String, dynamic>> offers;
  final bool hasNext;
  final int? nextPage;
  final int? totalCount;
}

class OffersApi {
  const OffersApi._();

  // Web/iOS/desktop local: 127.0.0.1
  // Android emulator: 10.0.2.2
  static String get baseUrl =>
      kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';

  static Future<List<Map<String, dynamic>>> getOffers({
    bool active = true,
    int? storeId,
    int? categoryId,
    String? search,
  }) async {
    final page = await getOffersPage(
      active: active,
      storeId: storeId,
      categoryId: categoryId,
      search: search,
    );
    return page.offers;
  }

  static Future<OffersPage> getOffersPage({
    bool active = true,
    int? storeId,
    int? categoryId,
    String? search,
    int page = 1,
    int? pageSize,
  }) async {
    final query = <String, String>{
      'active': active ? 'true' : 'false',
      if (storeId != null) 'store_id': '$storeId',
      if (categoryId != null) 'category_id': '$categoryId',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'page': '$page',
      if (pageSize != null) 'page_size': '$pageSize',
    };

    final uri = Uri.parse('$baseUrl/offers/').replace(queryParameters: query);
    final res = await http.get(uri, headers: const {'Accept': 'application/json'});

    final dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      throw Exception('Respuesta invalida del servidor de ofertas.');
    }

    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception((body['detail'] ?? 'Error cargando ofertas').toString());
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta invalida del servidor de ofertas');
    }

    final offers = _extractOfferMaps(body);
    final totalCount = _asInt(body['count']);
    final nextPageFromUrl = _parseNextPage(body['next']);

    bool hasNext;
    int? nextPage;

    if (nextPageFromUrl != null) {
      hasNext = true;
      nextPage = nextPageFromUrl;
    } else if (body['next'] != null && body['next'].toString().trim().isNotEmpty) {
      hasNext = true;
      nextPage = page + 1;
    } else if (body['has_next'] is bool) {
      hasNext = body['has_next'] as bool;
      nextPage = hasNext ? page + 1 : null;
    } else if (_asInt(body['total_pages']) != null) {
      final totalPages = _asInt(body['total_pages'])!;
      hasNext = page < totalPages;
      nextPage = hasNext ? page + 1 : null;
    } else if (totalCount != null && pageSize != null && pageSize > 0) {
      hasNext = page * pageSize < totalCount;
      nextPage = hasNext ? page + 1 : null;
    } else if (pageSize != null && pageSize > 0) {
      hasNext = offers.length >= pageSize;
      nextPage = hasNext ? page + 1 : null;
    } else {
      hasNext = false;
      nextPage = null;
    }

    return OffersPage(
      offers: offers,
      hasNext: hasNext,
      nextPage: nextPage,
      totalCount: totalCount,
    );
  }

  static List<Map<String, dynamic>> _extractOfferMaps(Map<String, dynamic> body) {
    final raw = body['offers'] ?? body['results'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (raw is Map<String, dynamic>) {
      final nested = raw['results'] ?? raw['offers'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    return const <Map<String, dynamic>>[];
  }

  static int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  static int? _parseNextPage(dynamic raw) {
    final next = (raw ?? '').toString().trim();
    if (next.isEmpty || next.toLowerCase() == 'null') return null;

    final uri = Uri.tryParse(next);
    if (uri == null) return null;

    final fromPage = uri.queryParameters['page'];
    if (fromPage != null) {
      final parsed = int.tryParse(fromPage);
      if (parsed != null && parsed > 0) return parsed;
    }

    final segment = uri.pathSegments.cast<String?>().firstWhere(
      (s) => (s ?? '').toLowerCase().startsWith('page='),
      orElse: () => null,
    );
    if (segment != null) {
      return int.tryParse(segment.split('=').last);
    }

    return null;
  }
}
