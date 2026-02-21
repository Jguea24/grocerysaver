import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../viewmodels/catalog_viewmodel.dart';

class ProductBestOptionsView extends StatefulWidget {
  const ProductBestOptionsView({super.key, required this.catalogViewModel});

  final CatalogViewModel catalogViewModel;

  @override
  State<ProductBestOptionsView> createState() => _ProductBestOptionsViewState();
}

class _ProductBestOptionsViewState extends State<ProductBestOptionsView> {
  int? _selectedProductId;
  Map<String, dynamic>? _compareData;
  bool _isComparing = false;
  String? _compareError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSelectionAndCompare();
    });
  }

  Future<void> _refresh() async {
    await widget.catalogViewModel.refresh();
    await _ensureSelectionAndCompare(force: true);
  }

  Future<void> _ensureSelectionAndCompare({bool force = false}) async {
    final products = _productsForCompare();
    if (products.isEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedProductId = null;
        _compareData = null;
        _compareError = null;
      });
      return;
    }

    final hasCurrent = _selectedProductId != null &&
        products.any((item) => item.id == _selectedProductId);
    final selectedId = hasCurrent ? _selectedProductId! : products.first.id;

    if (_selectedProductId != selectedId) {
      setState(() {
        _selectedProductId = selectedId;
      });
    }

    if (_compareData == null || force) {
      await _compareByProductId(selectedId);
    }
  }

  Future<void> _compareByProductId(int productId) async {
    setState(() {
      _isComparing = true;
      _compareError = null;
    });

    try {
      final data = await ApiService.comparePricesByProductId(productId);
      if (!mounted) return;
      setState(() {
        _compareData = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _compareError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isComparing = false;
        });
      }
    }
  }

  List<_CompareProductItem> _productsForCompare() {
    final source = widget.catalogViewModel.featuredProducts.isNotEmpty
        ? widget.catalogViewModel.featuredProducts
        : widget.catalogViewModel.products;

    final seen = <int>{};
    final items = <_CompareProductItem>[];
    for (final product in source) {
      final id = _productId(product);
      if (id == null || !seen.add(id)) {
        continue;
      }
      items.add(
        _CompareProductItem(
          id: id,
          name: widget.catalogViewModel.productName(product),
          product: product,
        ),
      );
    }
    return items;
  }

  int? _productId(Map<String, dynamic> product) {
    final raw = product['id'] ?? product['product_id'] ?? product['productId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  String _bestStore(Map<String, dynamic>? best) {
    if (best == null) return 'Sin datos';

    final nestedStore = best['store'];
    if (nestedStore is Map<String, dynamic>) {
      final nestedName = nestedStore['name'] ??
          nestedStore['store_name'] ??
          nestedStore['title'];
      final nestedText = (nestedName ?? '').toString().trim();
      if (nestedText.isNotEmpty) return nestedText;
    }

    final raw = best['store'] ?? best['store_name'] ?? best['name'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Sin datos' : text;
  }

  dynamic _bestPriceRaw(Map<String, dynamic>? best) {
    if (best == null) return null;
    return best['price'] ?? best['best_price'] ?? best['amount'];
  }

  String _formatCurrencyRaw(dynamic raw) {
    if (raw == null) return 'N/A';
    final number = _asNum(raw);
    if (number == null) {
      final text = raw.toString().trim();
      if (text.isEmpty) return 'N/A';
      return text.startsWith('\$') ? text : '\$$text';
    }
    if (number == number.roundToDouble()) {
      return '\$${number.toStringAsFixed(0)}';
    }
    return '\$${number.toStringAsFixed(2)}';
  }

  num? _asNum(dynamic raw) {
    if (raw is num) return raw;
    return num.tryParse((raw ?? '').toString().trim());
  }

  List<Map<String, dynamic>> _priceRows(Map<String, dynamic>? data) {
    final rows = data?['prices'];
    if (rows is! List) return const [];
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.catalogViewModel,
      builder: (context, _) {
        final products = _productsForCompare();
        final selectedId = _selectedProductId != null &&
                products.any((item) => item.id == _selectedProductId)
            ? _selectedProductId
            : (products.isEmpty ? null : products.first.id);

        if (_selectedProductId != selectedId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedProductId = selectedId;
            });
          });
        }

        final best = _compareData?['best_option'] is Map<String, dynamic>
            ? _compareData!['best_option'] as Map<String, dynamic>
            : null;
        final savings = _compareData?['savings_vs_most_expensive'];
        final prices = _priceRows(_compareData)
          ..sort((a, b) {
            final aValue = _asNum(a['price'] ?? a['amount'] ?? a['value']);
            final bValue = _asNum(b['price'] ?? b['amount'] ?? b['value']);
            if (aValue == null && bValue == null) return 0;
            if (aValue == null) return 1;
            if (bValue == null) return -1;
            return aValue.compareTo(bValue);
          });

        return Scaffold(
          appBar: AppBar(title: const Text('Comparador de precios')),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E6846),
                        Color(0xFF2F7D57),
                        Color(0xFF5AAE74),
                      ],
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.compare_arrows_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Compara precios por producto y encuentra el mejor supermercado.',
                          style: TextStyle(
                            color: Color(0xFFE8F8EE),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  const _InfoBox(
                    message: 'No hay productos disponibles para comparar.',
                    color: Color(0xFFF6F8FA),
                    textColor: Color(0xFF5A6772),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDDE3E8)),
                    ),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: selectedId,
                          items: products
                              .map(
                                (item) => DropdownMenuItem<int>(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProductId = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isComparing || selectedId == null
                                ? null
                                : () => _compareByProductId(selectedId),
                            icon: const Icon(Icons.price_check_rounded),
                            label: const Text('Comparar ahora'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_compareError != null) ...[
                  const SizedBox(height: 12),
                  _InfoBox(
                    message: _compareError!,
                    color: const Color(0xFFFCEAEA),
                    textColor: const Color(0xFFAC2E2E),
                  ),
                ],
                if (_isComparing) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (!_isComparing && _compareData != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDDE3E8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resultado de comparacion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A242D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                icon: Icons.storefront_rounded,
                                title: 'Mejor tienda',
                                value: _bestStore(best),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricTile(
                                icon: Icons.attach_money_rounded,
                                title: 'Mejor precio',
                                value: _formatCurrencyRaw(_bestPriceRaw(best)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _MetricTile(
                          icon: Icons.savings_rounded,
                          title: 'Ahorro vs mas caro',
                          value: _formatCurrencyRaw(savings),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Precios por supermercado (${prices.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF27333D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (prices.isEmpty)
                          const Text(
                            'Sin precios disponibles.',
                            style: TextStyle(color: Color(0xFF7A8A97)),
                          )
                        else
                          ...prices.map(
                            (row) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAF8),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE2E8ED)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.catalogViewModel
                                          .priceRowStoreName(row),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2A33),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    widget.catalogViewModel.priceRowPrice(row),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2F7D57),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Detalle por producto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E252B),
                  ),
                ),
                const SizedBox(height: 8),
                if (products.isEmpty)
                  const Text(
                    'Sin productos para mostrar.',
                    style: TextStyle(color: Color(0xFF7A8A97)),
                  )
                else
                  ...products.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BestOptionCard(
                        name: widget.catalogViewModel.productName(item.product),
                        storesAvailable: widget.catalogViewModel
                            .productStoresAvailable(item.product),
                        bestStore: widget.catalogViewModel
                            .productBestOptionStore(item.product),
                        bestPrice: widget.catalogViewModel
                            .productBestOptionPrice(item.product),
                        onView: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductBestOptionDetailView(
                                product: item.product,
                                catalogViewModel: widget.catalogViewModel,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductBestOptionDetailView extends StatelessWidget {
  const ProductBestOptionDetailView({
    super.key,
    required this.product,
    required this.catalogViewModel,
  });

  final Map<String, dynamic> product;
  final CatalogViewModel catalogViewModel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = catalogViewModel.productImageUrl(product);
    final rows = catalogViewModel.productPriceRows(product);

    return Scaffold(
      appBar: AppBar(title: Text(catalogViewModel.productName(product))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            const SizedBox(height: 12),
          Text(
            'Categoria: ${catalogViewModel.productCategoryName(product)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            catalogViewModel.productDescription(product),
            style: const TextStyle(color: Color(0xFF5E6B76), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Mejor opcion: ${catalogViewModel.productBestOptionStore(product)} (${catalogViewModel.productBestOptionPrice(product)})',
            style: const TextStyle(
              color: Color(0xFF1F6A47),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Precios por tienda (${catalogViewModel.productStoresAvailable(product)})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text(
              'Sin precios disponibles',
              style: TextStyle(color: Color(0xFF7A8A97)),
            )
          else
            ...rows.map(
              (row) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(catalogViewModel.priceRowStoreName(row)),
                  trailing: Text(
                    catalogViewModel.priceRowPrice(row),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BestOptionCard extends StatelessWidget {
  const _BestOptionCard({
    required this.name,
    required this.storesAvailable,
    required this.bestStore,
    required this.bestPrice,
    required this.onView,
  });

  final String name;
  final int storesAvailable;
  final String bestStore;
  final String bestPrice;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6DA),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF20573A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF173A29),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tiendas disponibles: $storesAvailable',
                  style: const TextStyle(
                    color: Color(0xFF3C4B57),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mejor opcion: $bestStore ($bestPrice)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF24513A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onView,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2F7D57),
              foregroundColor: Colors.white,
              minimumSize: const Size(76, 38),
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8ED)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF2F7D57)),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6A7884),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2A33),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.message,
    required this.color,
    required this.textColor,
  });

  final String message;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompareProductItem {
  const _CompareProductItem({
    required this.id,
    required this.name,
    required this.product,
  });

  final int id;
  final String name;
  final Map<String, dynamic> product;
}
