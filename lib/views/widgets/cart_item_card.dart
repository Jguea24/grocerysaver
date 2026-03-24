import 'package:flutter/material.dart';
import 'package:grocerysaver/models/cart_item_model.dart';
import 'package:grocerysaver/services/api_config.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({super.key, required this.item, required this.isSaving, required this.onEdit, required this.onIncrease, required this.onDecrease});

  final CartItemModel item;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl.trim().isEmpty ? '' : ApiConfig.resolveBackendUrl(item.imageUrl);
    final currentPrice = item.currentDisplayPrice;
    final previousPrice = item.previousDisplayPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(color: const Color(0xFFF4F4F4), borderRadius: BorderRadius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isEmpty
                ? const Icon(Icons.shopping_bag_outlined, size: 34, color: Color(0xFF8A8A8A))
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, size: 34, color: Color(0xFF8A8A8A)),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.15, color: Color(0xFF17142A))),
                const SizedBox(height: 6),
                Text(item.metaLine, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Color(0xFF7B7A86))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('\$${currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF151223))),
                    const SizedBox(width: 8),
                    Text('\$${previousPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Color(0xFF8C8C96), decoration: TextDecoration.lineThrough, decorationThickness: 2)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xFFFFE93B), borderRadius: BorderRadius.circular(16)),
                  child: Text(item.discountLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E1E1E))),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: isSaving ? null : onEdit,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, foregroundColor: const Color(0xFF201A3A)),
                  child: const Text('Editar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _QuantityPill(quantity: item.quantity, enabled: !isSaving, showDeleteIcon: item.quantity <= 1, onDecrease: onDecrease, onIncrease: onIncrease),
        ],
      ),
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({required this.quantity, required this.enabled, required this.showDeleteIcon, required this.onDecrease, required this.onIncrease});

  final int quantity;
  final bool enabled;
  final bool showDeleteIcon;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF4F3F8), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: enabled ? onDecrease : null, splashRadius: 18, visualDensity: VisualDensity.compact, icon: Icon(showDeleteIcon ? Icons.delete_outline_rounded : Icons.remove_rounded), color: const Color(0xFF1F1B32)),
          SizedBox(width: 24, child: Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF17142A)))),
          IconButton(onPressed: enabled ? onIncrease : null, splashRadius: 18, visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_rounded), color: const Color(0xFF1F1B32)),
        ],
      ),
    );
  }
}
