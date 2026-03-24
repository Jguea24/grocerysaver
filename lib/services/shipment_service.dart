import '../models/shipment_model.dart';
import 'api_client.dart';

class ShipmentService {
  ShipmentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ShipmentModel>> fetchShipments() async {
    final response = await _apiClient.get('/shipments/', auth: true);
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawShipments = map['shipments'];

    if (rawShipments is! List) {
      return const [];
    }

    return rawShipments
        .whereType<Map<String, dynamic>>()
        .map(ShipmentModel.fromJson)
        .toList();
  }

  Future<ShipmentModel> fetchShipmentDetail(int shipmentId) async {
    final response = await _apiClient.get('/shipments/$shipmentId/', auth: true);
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final shipmentMap = map['shipment'] ?? map;
    if (shipmentMap is! Map<String, dynamic>) {
      throw ApiException('La respuesta del envio no es valida.');
    }

    return ShipmentModel.fromJson(shipmentMap);
  }
}

