import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import 'shipment_tracking_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, this.orderService});

  final OrderService? orderService;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrderService _orderService;

  bool _isLoading = true;
  String? _errorMessage;
  List<OrderModel> _orders = const [];

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? OrderService();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openOrderDetail(OrderModel order) async {
    try {
      final detail = await _orderService.fetchOrderDetail(order.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden #${detail.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _OrderInfoRow(label: 'Estado', value: detail.status),
                  _OrderInfoRow(label: 'Checkout ID', value: '${detail.checkoutId}'),
                  _OrderInfoRow(label: 'Total', value: '\$${detail.total.toStringAsFixed(2)}'),
                  if (detail.addressSnapshot.trim().isNotEmpty)
                    _OrderInfoRow(label: 'Direccion', value: detail.addressSnapshot),
                  const SizedBox(height: 12),
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (detail.items.isEmpty)
                    const Text('La orden no devolvio items.')
                  else
                    ...detail.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3EC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text('Cantidad: ${item.quantity}'),
                                ],
                              ),
                            ),
                            Text('\$${item.lineTotal.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ),
                  if (detail.shipmentId != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ShipmentTrackingPage(shipmentId: detail.shipmentId!),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_shipping_rounded),
                        label: const Text('Ver envio'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis ordenes')),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _OrdersErrorView(message: _errorMessage!, onRetry: _loadOrders)
            else if (_orders.isEmpty)
              const _OrdersEmptyView()
            else
              ..._orders.map(
                (order) => _OrderCard(
                  order: order,
                  onTap: () => _openOrderDetail(order),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6DDD0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEF9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6B54E4)),
        ),
        title: Text('Orden #${order.id}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('Estado: ${order.status} · Total: \$${order.total.toStringAsFixed(2)}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF66756F)))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersErrorView extends StatelessWidget {
  const _OrdersErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1B7AC)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFD94841)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _OrdersEmptyView extends StatelessWidget {
  const _OrdersEmptyView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 42, color: Color(0xFF6C7B74)),
          SizedBox(height: 12),
          Text('Sin ordenes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
            'Todavia no existen ordenes para esta cuenta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF66756F), height: 1.4),
          ),
        ],
      ),
    );
  }
}

