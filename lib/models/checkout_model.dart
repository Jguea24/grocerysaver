class CheckoutModel {
  const CheckoutModel({
    required this.id,
    required this.status,
    required this.notes,
    this.addressId,
    this.totalItems = 0,
    this.distinctProducts = 0,
    this.subtotal = 0,
  });

  final int id;
  final String status;
  final String notes;
  final int? addressId;
  final int totalItems;
  final int distinctProducts;
  final double subtotal;

  factory CheckoutModel.fromJson(Map<String, dynamic> json) {
    return CheckoutModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      notes: (json['notes'] ?? '').toString(),
      addressId: (json['address_id'] as num?)?.toInt(),
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      distinctProducts: (json['distinct_products'] as num?)?.toInt() ?? 0,
      subtotal: _toDouble(json['subtotal'] ?? json['total'] ?? json['amount_total']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}
