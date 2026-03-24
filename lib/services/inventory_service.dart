import 'package:grocerysaver/models/alert_model.dart';
import 'package:grocerysaver/models/inventory_item_model.dart';
import 'package:grocerysaver/services/api_client.dart';

class InventoryService {
  InventoryService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<InventoryItemModel>> fetchItems() async {
    final response = await _apiClient.get('/inventory/items/', auth: true);
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawItems = map['items'];
    if (rawItems is! List) return const [];
    return rawItems.whereType<Map<String, dynamic>>().map(InventoryItemModel.fromJson).toList();
  }

  Future<InventoryItemModel> createItem({
    required int productId,
    required int quantity,
    String? expiresAt,
  }) async {
    final response = await _apiClient.post(
      '/inventory/items/',
      auth: true,
      body: {
        'product_id': productId,
        'quantity': quantity,
        if ((expiresAt ?? '').trim().isNotEmpty) 'expires_at': expiresAt!.trim(),
      },
    );

    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final itemMap = (map['item'] ?? map) as Map<String, dynamic>;
    return InventoryItemModel.fromJson(itemMap);
  }

  Future<InventoryItemModel> updateItem({
    required int itemId,
    int? quantity,
    String? expiresAt,
  }) async {
    final response = await _apiClient.patch(
      '/inventory/items/$itemId/',
      auth: true,
      body: {
        if (quantity != null) 'quantity': quantity,
        if (expiresAt != null) 'expires_at': expiresAt,
      },
    );

    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final itemMap = (map['item'] ?? map) as Map<String, dynamic>;
    return InventoryItemModel.fromJson(itemMap);
  }

  Future<void> deleteItem(int itemId) async {
    await _apiClient.delete('/inventory/items/$itemId/', auth: true);
  }

  Future<List<AlertModel>> fetchActiveAlerts() async {
    final response = await _apiClient.get(
      '/alerts/',
      auth: true,
      queryParameters: const {'status': 'active'},
    );
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawAlerts = map['alerts'];
    if (rawAlerts is! List) return const [];
    return rawAlerts.whereType<Map<String, dynamic>>().map(AlertModel.fromJson).toList();
  }
}
