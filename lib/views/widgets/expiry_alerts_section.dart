import 'package:flutter/material.dart';
import 'package:grocerysaver/models/alert_model.dart';
import 'package:grocerysaver/services/api_config.dart';

class ExpiryAlertsSection extends StatelessWidget {
  const ExpiryAlertsSection({
    super.key,
    required this.alerts,
    required this.isLoading,
    required this.onRetry,
    this.errorMessage,
  });

  final List<AlertModel> alerts;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Alertas por caducar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF17142A)),
                ),
              ),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            _InlineInventoryError(message: errorMessage!, onRetry: onRetry)
          else if (alerts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'No hay alertas activas por ahora.',
                style: TextStyle(color: Color(0xFF6E6B77)),
              ),
            )
          else
            Column(
              children: alerts
                  .map(
                    (alert) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8ED),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF5D8A7)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _AlertImage(imageUrl: alert.imageUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.product.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.message,
                                  style: const TextStyle(color: Color(0xFF6E6B77), height: 1.35),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _AlertBadge(label: alert.badgeLabel),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AlertImage extends StatelessWidget {
  const _AlertImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 58,
        height: 58,
        color: const Color(0xFFF1EEE8),
        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFC26B12)),
      );
    }

    return Image.network(
      ApiConfig.resolveBackendUrl(imageUrl),
      width: 58,
      height: 58,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 58,
        height: 58,
        color: const Color(0xFFF1EEE8),
        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFC26B12)),
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE26B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5C4300)),
      ),
    );
  }
}

class _InlineInventoryError extends StatelessWidget {
  const _InlineInventoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1B7AC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
