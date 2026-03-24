import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../presentation/providers/app_providers.dart';
import '../services/api_config.dart';

class ShoppingListPage extends StatelessWidget {
  const ShoppingListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFFF7F6F2),
        child: Consumer<ShoppingListProvider>(
          builder: (context, provider, _) {
            final totalEstimated = provider.items.fold<double>(0, (sum, item) => sum + item.lineTotal);

            final content = RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(18, embedded ? 10 : 18, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF16423C), Color(0xFF2D5A4E), Color(0xFF4E7A65)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                embedded ? 'Compras' : 'Lista de compras',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.items.isEmpty
                                    ? 'Tu carrito esta vacio por ahora'
                                    : '${provider.items.length} producto(s) agregado(s)',
                                style: const TextStyle(color: Color(0xFFE6F2EC)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Total estimado: \$${totalEstimated.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (provider.items.isNotEmpty)
                          FilledButton.tonalIcon(
                            onPressed: provider.isSaving ? null : () => Navigator.of(context).pushNamed(AppRoutes.cart),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF16423C),
                            ),
                            icon: const Icon(Icons.shopping_cart_checkout_rounded),
                            label: const Text('Ver carrito'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (provider.isLoading)
                    const _ShoppingLoadingState()
                  else if (provider.errorMessage != null)
                    _ShoppingErrorState(message: provider.errorMessage!, onRetry: provider.load)
                  else if (provider.items.isEmpty)
                    const _ShoppingEmptyState()
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Productos agregados',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF17142A)),
                          ),
                          const SizedBox(height: 14),
                          ...provider.items.map(
                            (item) => _ShoppingItemCard(
                              item: item,
                              isSaving: provider.isSaving,
                              onIncrease: () => provider.updateItem(itemId: item.id, quantity: item.quantity + 1),
                              onDecrease: () {
                                final next = item.quantity - 1;
                                if (next <= 0) {
                                  provider.removeItem(item.id);
                                } else {
                                  provider.updateItem(itemId: item.id, quantity: next);
                                }
                              },
                              onDelete: () => provider.removeItem(item.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: provider.isSaving ? null : () => Navigator.of(context).pushNamed(AppRoutes.cart),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE90059),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout_rounded),
                      label: const Text('Continuar al pago'),
                    ),
                  ],
                ],
              ),
            );

            if (embedded) return content;

            return Scaffold(
              backgroundColor: const Color(0xFFF7F6F2),
              appBar: AppBar(title: const Text('Lista de compras'), centerTitle: true),
              body: content,
            );
          },
        ),
      ),
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  const _ShoppingItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
    required this.isSaving,
  });

  final dynamic item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item.product.imageUrl ?? '').toString().trim();
    final subtitle = [item.product.brand, item.product.category]
        .where((value) => value.toString().trim().isNotEmpty)
        .join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: imageUrl.isEmpty
                ? Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFF1EEE8),
                    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6C7B74)),
                  )
                : Image.network(
                    ApiConfig.resolveBackendUrl(imageUrl),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: const Color(0xFFF1EEE8),
                      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6C7B74)),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isEmpty ? 'Sin detalle' : subtitle,
                  style: const TextStyle(color: Color(0xFF6E6B77)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ShoppingChip(label: 'Cantidad: ${item.quantity}'),
                    _ShoppingChip(label: 'Unitario: \$${item.unitPrice.toStringAsFixed(2)}'),
                    _ShoppingChip(label: 'Total: \$${item.lineTotal.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              IconButton(
                onPressed: isSaving ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Eliminar',
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: isSaving ? null : onDecrease,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: isSaving ? null : onIncrease,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShoppingChip extends StatelessWidget {
  const _ShoppingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3E3A4B))),
    );
  }
}

class _ShoppingLoadingState extends StatelessWidget {
  const _ShoppingLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ShoppingErrorState extends StatelessWidget {
  const _ShoppingErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEA),
        borderRadius: BorderRadius.circular(20),
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

class _ShoppingEmptyState extends StatelessWidget {
  const _ShoppingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.shopping_cart_outlined, size: 42, color: Color(0xFF6C7B74)),
          SizedBox(height: 12),
          Text(
            'No hay productos agregados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega productos desde el catalogo para verlos aqui y continuar con tu compra.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6E6B77), height: 1.35),
          ),
        ],
      ),
    );
  }
}
