import 'package:flutter/material.dart';
import 'package:grocerysaver/app/app_routes.dart';
import 'package:grocerysaver/models/payment_result_model.dart';
import 'package:grocerysaver/views/orders_page.dart';
import 'package:grocerysaver/views/shipment_tracking_page.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key, required this.result});

  final PaymentResultModel result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                    ),
                    const SizedBox(height: 24),
                    const Text('Pago exitoso', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF17142A))),
                    const SizedBox(height: 10),
                    Text(result.message.isEmpty ? 'Tu pago fue procesado correctamente.' : result.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF6E6B77), height: 1.45)),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 8))]),
                      child: Column(
                        children: [
                          _SuccessRow(label: 'Monto', value: '\$${result.payment.amount.toStringAsFixed(2)} ${result.payment.currency}'),
                          _SuccessRow(label: 'Metodo', value: result.payment.methodLabel),
                          _SuccessRow(label: 'Orden', value: '#${result.order.id}'),
                          _SuccessRow(label: 'Envio', value: '#${result.shipment.id}'),
                          _SuccessRow(label: 'Estado', value: result.shipment.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShipmentTrackingPage(shipmentId: result.shipment.id))),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE90059), minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                  child: const Text('Ver seguimiento'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersPage())),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                  child: const Text('Ver mis ordenes'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.shell,
                    (route) => false,
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF6E6B77), fontWeight: FontWeight.w600))), Text(value, style: const TextStyle(color: Color(0xFF17142A), fontWeight: FontWeight.w800))]),
    );
  }
}
