class ShipmentModel {
  const ShipmentModel({
    required this.id,
    required this.status,
    required this.orderId,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.carrier,
    this.trackingNumber,
  });

  final int id;
  final String status;
  final int orderId;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String? carrier;
  final String? trackingNumber;

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      carrier: _readOptionalText(json['carrier']),
      trackingNumber: _readOptionalText(json['tracking_number']),
    );
  }

  String get displayCarrier => carrier?.isNotEmpty == true ? carrier! : 'Pendiente';
  String get displayTracking => trackingNumber?.isNotEmpty == true ? trackingNumber! : 'Sin asignar';
}

String? _readOptionalText(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}
