import 'package:grocerysaver/models/order_model.dart';
import 'package:grocerysaver/services/api_client.dart';

class OrderService {
  OrderService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<OrderModel>> fetchOrders() async {
    final response = await _apiClient.get('/orders/', auth: true);
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawOrders = map['orders'];

    if (rawOrders is! List) {
      return const [];
    }

    return rawOrders.whereType<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }

  Future<OrderModel> fetchOrderDetail(int orderId) async {
    final response = await _apiClient.get('/orders/$orderId/', auth: true);
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final orderMap = map['order'] ?? map;
    if (orderMap is! Map<String, dynamic>) {
      throw ApiException('La respuesta del detalle de orden no es valida.');
    }

    return OrderModel.fromJson(orderMap);
  }
}
