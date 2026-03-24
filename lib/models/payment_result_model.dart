import 'package:grocerysaver/models/order_model.dart';
import 'package:grocerysaver/models/payment_model.dart';
import 'package:grocerysaver/models/shipment_model.dart';

class PaymentResultModel {
  const PaymentResultModel({
    required this.message,
    required this.payment,
    required this.order,
    required this.shipment,
  });

  final String message;
  final PaymentModel payment;
  final OrderModel order;
  final ShipmentModel shipment;

  factory PaymentResultModel.fromJson(Map<String, dynamic> json) {
    final paymentMap = (json['payment'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final orderMap = (json['order'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final shipmentMap = (json['shipment'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return PaymentResultModel(
      message: (json['message'] ?? '').toString(),
      payment: PaymentModel.fromJson(paymentMap),
      order: OrderModel.fromJson(orderMap),
      shipment: ShipmentModel.fromJson(shipmentMap),
    );
  }
}
