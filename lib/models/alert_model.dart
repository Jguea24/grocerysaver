import 'package:grocerysaver/models/product_model.dart';

class AlertModel {
  const AlertModel({
    required this.id,
    required this.type,
    required this.status,
    required this.daysRemaining,
    required this.message,
    required this.product,
    required this.inventoryItemId,
  });

  final int id;
  final String type;
  final String status;
  final int? daysRemaining;
  final String message;
  final ProductModel product;
  final int? inventoryItemId;

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final productMap = (json['product'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return AlertModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      message: (json['message'] ?? '').toString(),
      product: ProductModel.fromJson(productMap),
      inventoryItemId: (json['inventory_item_id'] as num?)?.toInt(),
    );
  }

  String get imageUrl => product.categoryImage ?? '';

  String get badgeLabel {
    final days = daysRemaining;
    if (days == null) return 'Pronto';
    if (days <= 0) return 'Caduca hoy';
    if (days == 1) return '1 dia';
    return '$days dias';
  }
}
