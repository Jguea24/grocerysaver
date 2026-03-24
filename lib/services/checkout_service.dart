import '../models/checkout_model.dart';
import 'api_client.dart';

class CheckoutService {
  CheckoutService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CheckoutModel> createCheckout({String? notes}) async {
    final response = await _apiClient.post(
      '/checkout/',
      auth: true,
      body: {
        if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
      },
    );

    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final checkoutMap = map['checkout'];
    if (checkoutMap is! Map<String, dynamic>) {
      throw ApiException('La respuesta de checkout no contiene checkout.');
    }

    return CheckoutModel.fromJson(checkoutMap);
  }

  Future<CheckoutModel> updateCheckout({
    required int checkoutId,
    int? addressId,
    String? notes,
  }) async {
    final response = await _apiClient.patch(
      '/checkout/$checkoutId/',
      auth: true,
      body: {
        if (addressId != null) 'address_id': addressId,
        if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
      },
    );

    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final checkoutMap = map['checkout'] ?? map;
    if (checkoutMap is! Map<String, dynamic>) {
      throw ApiException('La respuesta de actualizar checkout no es valida.');
    }

    return CheckoutModel.fromJson(checkoutMap);
  }
}

