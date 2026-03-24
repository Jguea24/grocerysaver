import 'package:grocerysaver/models/address_model.dart';
import 'package:grocerysaver/services/api_client.dart';

class AddressService {
  AddressService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AddressModel>> fetchAddresses() async {
    final response = await _apiClient.get('/profile/addresses/', auth: true);
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final raw = map['addresses'];
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map<String, dynamic>>().map(AddressModel.fromJson).toList();
  }

  Future<AddressModel> createAddress({
    required String label,
    required String contactName,
    required String phone,
    required String line1,
    required String city,
    bool isDefault = false,
  }) async {
    final response = await _apiClient.post(
      '/profile/addresses/',
      auth: true,
      body: {
        'label': label.trim(),
        'contact_name': contactName.trim(),
        'phone': phone.trim(),
        'line1': line1.trim(),
        'city': city.trim(),
        'is_default': isDefault,
      },
    );

    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final raw = map['address'] ?? map;
    if (raw is! Map<String, dynamic>) {
      throw ApiException('La respuesta de direccion no contiene un objeto valido.');
    }

    return AddressModel.fromJson(raw);
  }
}
