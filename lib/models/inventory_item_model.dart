import 'package:grocerysaver/models/product_model.dart';

class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.expiresAt,
    required this.daysUntilExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final ProductModel product;
  final int quantity;
  final String? expiresAt;
  final int? daysUntilExpiry;
  final String createdAt;
  final String updatedAt;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final productMap = (json['product'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return InventoryItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      product: ProductModel.fromJson(productMap),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      expiresAt: _readOptionalText(json['expires_at']),
      daysUntilExpiry: (json['days_until_expiry'] as num?)?.toInt(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  String get imageUrl => product.categoryImage ?? '';

  String get displayExpiryDate {
    final raw = expiresAt?.trim() ?? '';
    if (raw.isEmpty) return 'Sin fecha';
    return raw.split('T').first;
  }

  String get expiryBadgeLabel {
    final days = daysUntilExpiry;
    if (days == null) return 'Sin fecha';
    if (days <= 0) return 'Caduca hoy';
    if (days == 1) return '1 dia';
    return '$days dias';
  }

  bool get isUrgent {
    final days = daysUntilExpiry;
    return days != null && days <= 2;
  }
}

String? _readOptionalText(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}
