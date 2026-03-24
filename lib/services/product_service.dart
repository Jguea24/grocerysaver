import '../models/product_model.dart';
import 'api_client.dart';

class ProductService {
  ProductService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ProductModel>> fetchProducts({String? search}) async {
    final response = await _apiClient.get(
      '/products/',
      queryParameters: (search ?? '').trim().isEmpty ? null : {'search': search!.trim()},
    );
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawProducts = map['products'];

    if (rawProducts is! List) {
      return const [];
    }

    return rawProducts
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }
}

