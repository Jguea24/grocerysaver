import '../models/payment_result_model.dart';
import 'api_client.dart';

class PaymentService {
  PaymentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PaymentResultModel> createPayment({
    required int checkoutId,
    required String method,
    String provider = 'sandbox',
    bool simulateFailure = false,
  }) async {
    final response = await _apiClient.post(
      '/payments/',
      auth: true,
      body: {
        'checkout_id': checkoutId,
        'method': method,
        'provider': provider,
        if (simulateFailure) 'simulate_failure': true,
      },
    );

    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    if (map['payment'] is! Map<String, dynamic> ||
        map['order'] is! Map<String, dynamic> ||
        map['shipment'] is! Map<String, dynamic>) {
      throw ApiException('La respuesta del pago no contiene payment, order y shipment.');
    }

    return PaymentResultModel.fromJson(map);
  }
}
