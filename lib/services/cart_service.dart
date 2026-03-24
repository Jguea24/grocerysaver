import 'package:grocerysaver/models/cart_item_model.dart';
import 'package:grocerysaver/models/cart_snapshot_model.dart';
import 'package:grocerysaver/services/api_client.dart';

class CartService {
  CartService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CartSnapshotModel> fetchCartSnapshot() async {
    final results = await Future.wait<dynamic>([
      _apiClient.get('/cart/items/', auth: true),
      _apiClient.get('/cart/', auth: true),
    ]);

    final items = _readItems(results[0]);
    final cartMap = _readCartMap(results[1]);
    final subtotalFromApi = _toDouble(cartMap['subtotal']);

    return CartSnapshotModel(
      items: items,
      subtotal: subtotalFromApi > 0 ? subtotalFromApi : items.fold<double>(0.0, (sum, item) => sum + item.lineTotal),
      totalItems: (cartMap['total_items'] as num?)?.toInt() ?? items.fold<int>(0, (sum, item) => sum + item.quantity),
      distinctProducts: (cartMap['distinct_products'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<List<CartItemModel>> fetchCartItems() async {
    final response = await _apiClient.get('/cart/items/', auth: true);
    return _readItems(response);
  }

  Future<CartItemModel> addToCart({required int productId, int quantity = 1, int? storeId}) async {
    final response = await _apiClient.post(
      '/cart/items/',
      auth: true,
      body: {
        'product_id': productId,
        'quantity': quantity,
        if (storeId != null) 'store_id': storeId,
      },
    );

    return _readSingleItem(response, fallbackMessage: 'La respuesta de agregar al carrito no contiene un item valido.');
  }

  Future<CartItemModel> updateCartItem({required int itemId, int? quantity, int? storeId}) async {
    final response = await _apiClient.patch(
      '/cart/items/$itemId/',
      auth: true,
      body: {
        if (quantity != null) 'quantity': quantity,
        if (storeId != null) 'store_id': storeId,
      },
    );

    return _readSingleItem(response, fallbackMessage: 'La respuesta de actualizar carrito no contiene un item valido.');
  }

  Future<void> deleteCartItem(int itemId) async {
    await _apiClient.delete('/cart/items/$itemId/', auth: true);
  }

  List<CartItemModel> _readItems(dynamic response) {
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawItems = map['items'];
    if (rawItems is! List) {
      return const [];
    }
    return rawItems.whereType<Map<String, dynamic>>().map(CartItemModel.fromJson).toList();
  }

  Map<String, dynamic> _readCartMap(dynamic response) {
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawCart = map['cart'];
    return rawCart is Map<String, dynamic> ? rawCart : <String, dynamic>{};
  }

  CartItemModel _readSingleItem(dynamic response, {required String fallbackMessage}) {
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawItem = map['item'] ?? map['cart_item'] ?? map;
    if (rawItem is! Map<String, dynamic>) {
      throw ApiException(fallbackMessage);
    }
    return CartItemModel.fromJson(rawItem);
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}
