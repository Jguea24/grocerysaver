class OrderLineModel {
  const OrderLineModel({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory OrderLineModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final quantity = (json['quantity'] as num?)?.toInt() ?? 0;
    final unitPrice = _toDouble(json['unit_price'] ?? json['price']);
    final lineTotal = _toDouble(json['line_total'] ?? json['total']);

    return OrderLineModel(
      productName: (json['product_name'] ?? product?['name'] ?? 'Producto').toString(),
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: lineTotal > 0 ? lineTotal : unitPrice * quantity,
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.checkoutId,
    required this.shipmentId,
    required this.createdAt,
    required this.total,
    required this.items,
    required this.addressSnapshot,
  });

  final int id;
  final String status;
  final int checkoutId;
  final int? shipmentId;
  final String createdAt;
  final double total;
  final List<OrderLineModel> items;
  final String addressSnapshot;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map<String, dynamic>>().map(OrderLineModel.fromJson).toList()
        : const <OrderLineModel>[];

    return OrderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'created').toString(),
      checkoutId: (json['checkout_id'] as num?)?.toInt() ?? 0,
      shipmentId: (json['shipment_id'] as num?)?.toInt(),
      createdAt: (json['created_at'] ?? '').toString(),
      total: _toDouble(json['total'] ?? json['subtotal'] ?? json['amount_total']),
      items: items,
      addressSnapshot: _readAddress(json['address_snapshot']),
    );
  }

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);
}

String _readAddress(dynamic value) {
  if (value is Map<String, dynamic>) {
    final parts = [
      value['label'],
      value['line1'],
      value['city'],
    ].where((item) => item != null && item.toString().trim().isNotEmpty).map((e) => e.toString().trim()).toList();
    return parts.join(' · ');
  }
  return (value ?? '').toString();
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}
