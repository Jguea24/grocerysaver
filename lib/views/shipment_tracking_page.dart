import 'package:flutter/material.dart';

import '../models/shipment_model.dart';
import '../services/shipment_service.dart';

class ShipmentTrackingPage extends StatefulWidget {
  const ShipmentTrackingPage({
    super.key,
    required this.shipmentId,
    this.shipmentService,
  });

  final int shipmentId;
  final ShipmentService? shipmentService;

  @override
  State<ShipmentTrackingPage> createState() => _ShipmentTrackingPageState();
}

class _ShipmentTrackingPageState extends State<ShipmentTrackingPage> {
  late final ShipmentService _shipmentService;

  bool _isLoading = true;
  String? _errorMessage;
  ShipmentModel? _shipment;

  @override
  void initState() {
    super.initState();
    _shipmentService = widget.shipmentService ?? ShipmentService();
    _loadShipment();
  }

  Future<void> _loadShipment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shipment = await _shipmentService.fetchShipmentDetail(widget.shipmentId);
      if (!mounted) return;
      setState(() {
        _shipment = shipment;
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

  @override
  Widget build(BuildContext context) {
    final shipment = _shipment;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento de envio')),
      body: RefreshIndicator(
        onRefresh: _loadShipment,
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
              _ShipmentErrorView(message: _errorMessage!, onRetry: _loadShipment)
            else if (shipment == null)
              const _ShipmentEmptyView()
            else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF143E64), Color(0xFF3F5BCE), Color(0xFF8652E5)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shipment #${shipment.id}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Estado actual: ${shipment.status}',
                            style: const TextStyle(color: Color(0xFFDCE7FF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Informacion del envio',
                rows: [
                  _TrackingRow(label: 'Shipment ID', value: '${shipment.id}'),
                  _TrackingRow(label: 'Order ID', value: '${shipment.orderId}'),
                  _TrackingRow(label: 'Estado', value: shipment.status),
                  _TrackingRow(label: 'Carrier', value: shipment.displayCarrier),
                  _TrackingRow(label: 'Tracking', value: shipment.displayTracking),
                  _TrackingRow(label: 'Creado', value: shipment.createdAt.isEmpty ? 'Sin fecha' : shipment.createdAt),
                  _TrackingRow(label: 'Actualizado', value: shipment.updatedAt.isEmpty ? 'Sin fecha' : shipment.updatedAt),
                ],
              ),
              if (shipment.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Notas',
                  rows: [
                    _TrackingRow(label: 'Detalle', value: shipment.notes),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6DDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }
}

class _TrackingRow extends StatelessWidget {
  const _TrackingRow({required this.label, required this.value});

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

class _ShipmentErrorView extends StatelessWidget {
  const _ShipmentErrorView({required this.message, required this.onRetry});

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

class _ShipmentEmptyView extends StatelessWidget {
  const _ShipmentEmptyView();

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
          Icon(Icons.local_shipping_outlined, size: 42, color: Color(0xFF6C7B74)),
          SizedBox(height: 12),
          Text('Sin envio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
            'No se encontro informacion del envio solicitado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF66756F), height: 1.4),
          ),
        ],
      ),
    );
  }
}


