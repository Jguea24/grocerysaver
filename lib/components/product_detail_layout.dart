// Layout reutilizable para pantallas de detalle de producto tipo delivery.
import 'package:flutter/material.dart';

/// Pantalla de detalle con hero de imagen, cantidad y CTA fijo al carrito.
class ProductDetailLayout extends StatefulWidget {
  const ProductDetailLayout({
    super.key,
    required this.title,
    required this.description,
    required this.vendorName,
    required this.unitPrice,
    required this.priceLabel,
    required this.onAddToCart,
    this.imageUrl,
    this.oldPriceLabel,
    this.ratingLabel,
    this.reviewsLabel,
    this.categoryLabel,
    this.badgeLabel,
    this.isSaving = false,
    this.onCartTap,
    this.extraSections = const [],
    this.topTitle = 'Details',
  });

  final String title;
  final String description;
  final String vendorName;
  final num unitPrice;
  final String priceLabel;
  final Future<void> Function(int quantity) onAddToCart;
  final String? imageUrl;
  final String? oldPriceLabel;
  final String? ratingLabel;
  final String? reviewsLabel;
  final String? categoryLabel;
  final String? badgeLabel;
  final bool isSaving;
  final VoidCallback? onCartTap;
  final List<Widget> extraSections;
  final String topTitle;

  @override
  State<ProductDetailLayout> createState() => _ProductDetailLayoutState();
}

class _ProductDetailLayoutState extends State<ProductDetailLayout> {
  int _quantity = 1;

  String _formatCurrency(num value) {
    if (value == value.roundToDouble()) {
      return '\$${value.toStringAsFixed(0)}';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.unitPrice * _quantity;
    final heroHeight = MediaQuery.of(context).size.width * 0.78;
    final imageUrl = widget.imageUrl?.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: heroHeight + 24,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: const Color(0xFFF0F1F3),
                        ),
                        Center(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(42, 78, 42, 26),
                            padding: const EdgeInsets.all(8),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) =>
                                          _heroFallback(),
                                    )
                                  : _heroFallback(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -26),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 132),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 24,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF21C997),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.categoryLabel ?? 'Producto',
                            style: const TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _VendorRow(vendorName: widget.vendorName),
                              ),
                              const SizedBox(width: 14),
                              _CompactQty(
                                quantity: _quantity,
                                onSubtract: _quantity > 1
                                    ? () {
                                        setState(() {
                                          _quantity--;
                                        });
                                      }
                                    : null,
                                onAdd: _quantity < 99
                                    ? () {
                                        setState(() {
                                          _quantity++;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if ((widget.ratingLabel ?? '').isNotEmpty ||
                              (widget.reviewsLabel ?? '').isNotEmpty)
                            _InlineRating(
                              ratingLabel: widget.ratingLabel ?? '',
                              reviewsLabel: widget.reviewsLabel ?? '',
                            ),
                          if ((widget.ratingLabel ?? '').isNotEmpty ||
                              (widget.reviewsLabel ?? '').isNotEmpty)
                            const SizedBox(height: 18),
                          if ((widget.oldPriceLabel ?? '').isNotEmpty)
                            Text(
                              widget.oldPriceLabel!,
                              style: const TextStyle(
                                color: Color(0xFF98A2B3),
                                fontSize: 17,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            widget.priceLabel,
                            style: const TextStyle(
                              color: Color(0xFFE25353),
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              if ((widget.categoryLabel ?? '').isNotEmpty)
                                Expanded(
                                  child: _InfoPill(
                                    icon: Icons.category_outlined,
                                    text: widget.categoryLabel!,
                                  ),
                                ),
                              if ((widget.categoryLabel ?? '').isNotEmpty &&
                                  (widget.badgeLabel ?? '').isNotEmpty)
                                const SizedBox(width: 10),
                              if ((widget.badgeLabel ?? '').isNotEmpty)
                                Expanded(
                                  child: _InfoPill(
                                    icon: Icons.storefront_outlined,
                                    text: widget.badgeLabel!,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 22),
                          Text(
                            widget.topTitle == 'Details'
                                ? 'Product Details'
                                : 'Descripcion',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF23272F),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.description,
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 15,
                              height: 1.55,
                            ),
                          ),
                          if (widget.extraSections.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            ...widget.extraSections,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            child: _RoundOverlayButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  widget.topTitle,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 14,
            child: _RoundOverlayButton(
              icon: widget.onCartTap == null
                  ? Icons.favorite_border_rounded
                  : Icons.shopping_cart_outlined,
              onTap: widget.onCartTap,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EC))),
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Color(0xFF8A8F98),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCurrency(total),
                    style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: widget.isSaving
                        ? null
                        : () => widget.onAddToCart(_quantity),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1FB86A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: widget.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      widget.isSaving ? 'Adding...' : 'Add to Cart',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF2),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 70,
        color: Color(0xFF8FA0B2),
      ),
    );
  }
}

class _RoundOverlayButton extends StatelessWidget {
  const _RoundOverlayButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: const Color(0xFF667085), size: 18),
        ),
      ),
    );
  }
}

class _VendorRow extends StatelessWidget {
  const _VendorRow({required this.vendorName});

  final String vendorName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            vendorName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineRating extends StatelessWidget {
  const _InlineRating({
    required this.ratingLabel,
    required this.reviewsLabel,
  });

  final String ratingLabel;
  final String reviewsLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF5B301), size: 18),
        const Icon(Icons.star_rounded, color: Color(0xFFF5B301), size: 18),
        const Icon(Icons.star_rounded, color: Color(0xFFF5B301), size: 18),
        const Icon(Icons.star_rounded, color: Color(0xFFF5B301), size: 18),
        const Icon(Icons.star_half_rounded, color: Color(0xFFF5B301), size: 18),
        const SizedBox(width: 8),
        Text(
          [ratingLabel, reviewsLabel]
              .where((item) => item.trim().isNotEmpty)
              .join(' '),
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E4E8)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5D6A76)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF2F4F7) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE0E5EB)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF2C475E)),
      ),
    );
  }
}

class _CompactQty extends StatelessWidget {
  const _CompactQty({
    required this.quantity,
    required this.onSubtract,
    required this.onAdd,
  });

  final int quantity;
  final VoidCallback? onSubtract;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(icon: Icons.remove, onTap: onSubtract),
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _QtyButton(icon: Icons.add, onTap: onAdd),
      ],
    );
  }
}
