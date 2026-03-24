class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.checkoutId,
    required this.orderId,
    required this.method,
    required this.provider,
    required this.status,
    required this.amount,
    required this.currency,
    required this.providerReference,
    required this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  final int id;
  final String paymentNumber;
  final int checkoutId;
  final int? orderId;
  final String method;
  final String provider;
  final String status;
  final double amount;
  final String currency;
  final String providerReference;
  final String failureReason;
  final String createdAt;
  final String updatedAt;
  final String? paidAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      paymentNumber: (json['payment_number'] ?? '').toString(),
      checkoutId: (json['checkout_id'] as num?)?.toInt() ?? 0,
      orderId: (json['order_id'] as num?)?.toInt(),
      method: (json['method'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      amount: _toDouble(json['amount']),
      currency: ((json['currency'] ?? 'USD').toString()).toUpperCase(),
      providerReference: (json['provider_reference'] ?? '').toString(),
      failureReason: (json['failure_reason'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      paidAt: _optionalText(json['paid_at']),
    );
  }

  String get methodLabel {
    switch (method) {
      case 'card':
        return 'Tarjeta';
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      default:
        return method;
    }
  }

  bool get isSucceeded => status.toLowerCase() == 'succeeded';
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}

String? _optionalText(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}
