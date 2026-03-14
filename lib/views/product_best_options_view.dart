// Comparador de precios y detalle de mejores opciones por producto.
import 'package:flutter/material.dart';

import '../components/product_detail_layout.dart';
import '../services/api_service.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/catalog_viewmodel.dart';

/// Pantalla de comparacion de precios reutilizando el catalogo ya cargado.
class ProductBestOptionsView extends StatefulWidget {
  const ProductBestOptionsView({
    super.key,
    required this.catalogViewModel,
    required this.cartViewModel,
  });

  final CatalogViewModel catalogViewModel;
  final CartViewModel cartViewModel;

  @override
  State<ProductBestOptionsView> createState() => _ProductBestOptionsViewState();
}

class _ProductBestOptionsViewState extends State<ProductBestOptionsView> {
  int? _selectedProductId;
  int _selectedQuantity = 1;
  Map<String, dynamic>? _compareData;
  bool _isComparing = false;
  String? _compareError;
  String? _compareCacheStatus;

  @override
  void initState() {
    super.initState();
    widget.cartViewModel.loadCart();
    // La seleccion depende del primer frame porque el catalogo puede llegar despues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSelectionAndCompare();
    });
  }

  /// Recarga el catalogo y fuerza una nueva comparacion del producto activo.
  Future<void> _refresh() async {
    await Future.wait([
      widget.catalogViewModel.refresh(),
      widget.cartViewModel.refresh(),
    ]);
    await _ensureSelectionAndCompare(force: true);
  }

  /// Garantiza una seleccion valida antes de disparar el comparador.
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

  /// Consulta al backend la mejor opcion para el producto indicado.
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
        _compareCacheStatus = ApiService.lastCacheStatus;
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

  /// Construye la lista de productos comparables evitando duplicados por id.
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

  /// Intenta resolver el identificador canonico del producto.
  int? _productId(Map<String, dynamic> product) {
    final raw = product['id'] ?? product['product_id'] ?? product['productId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  /// Devuelve el nombre de la mejor tienda desde respuestas anidadas o planas.
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

  /// Extrae el valor de precio desde las claves mas comunes del backend.
  dynamic _bestPriceRaw(Map<String, dynamic>? best) {
    if (best == null) return null;
    return best['price'] ?? best['best_price'] ?? best['amount'];
  }

  /// Formatea precios tolerando numeros y strings provenientes de la API.
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

  /// Convierte valores numericos heterogeneos a `num`.
  num? _asNum(dynamic raw) {
    if (raw is num) return raw;
    return num.tryParse((raw ?? '').toString().trim());
  }

  /// Extrae la tabla de precios lista para ordenarse y mostrarse.
  List<Map<String, dynamic>> _priceRows(Map<String, dynamic>? data) {
    final rows = data?['prices'];
    if (rows is! List) return const [];
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  /// Busca el producto actualmente seleccionado.
  _CompareProductItem? _selectedProduct(List<_CompareProductItem> products) {
    final selectedId = _selectedProductId;
    if (selectedId == null) return null;
    for (final item in products) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  /// Obtiene `store_id` desde contratos planos o anidados.
  int? _storeIdFromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final nestedStore = data['store'];
    final raw =
        data['store_id'] ??
        data['storeId'] ??
        (nestedStore is Map<String, dynamic>
            ? (nestedStore['id'] ?? nestedStore['store_id'])
            : null);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  /// Intenta conservar la tienda mas conveniente al agregar al carrito.
  int? _preferredStoreId(Map<String, dynamic> product) {
    final best = product['best_option'];
    if (best is Map<String, dynamic>) {
      final bestStoreId = _storeIdFromMap(best);
      if (bestStoreId != null) return bestStoreId;
    }

    Map<String, dynamic>? cheapestRow;
    num? cheapestPrice;
    for (final row in widget.catalogViewModel.productPriceRows(product)) {
      final price = _asNum(row['price'] ?? row['amount'] ?? row['value']);
      if (price == null) continue;
      if (cheapestPrice == null || price < cheapestPrice) {
        cheapestPrice = price;
        cheapestRow = row;
      }
    }
    return _storeIdFromMap(cheapestRow);
  }

  /// Agrega el producto seleccionado al carrito autenticado.
  Future<void> _addSelectedToCart() async {
    final selected = _selectedProduct(_productsForCompare());
    if (selected == null) return;

    final ok = await widget.cartViewModel.addItem(
      productId: selected.id,
      quantity: _selectedQuantity,
      storeId: _preferredStoreId(selected.product),
    );
    if (!mounted) return;

    final message = ok
        ? (widget.cartViewModel.infoMessage ?? 'Producto agregado al carrito.')
        : (widget.cartViewModel.errorMessage ??
              'No se pudo agregar el producto al carrito.');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.catalogViewModel,
        widget.cartViewModel,
      ]),
      builder: (context, _) {
        final products = _productsForCompare();
        final selectedId = _selectedProductId != null &&
                products.any((item) => item.id == _selectedProductId)
            ? _selectedProductId
            : (products.isEmpty ? null : products.first.id);

        // Si el producto seleccionado desaparece tras un refresh, se corrige al siguiente frame.
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
            // Se ordena por precio ascendente para resaltar la mejor opcion arriba.
            final aValue = _asNum(a['price'] ?? a['amount'] ?? a['value']);
            final bValue = _asNum(b['price'] ?? b['amount'] ?? b['value']);
            if (aValue == null && bValue == null) return 0;
            if (aValue == null) return 1;
            if (bValue == null) return -1;
            return aValue.compareTo(bValue);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Comparador de precios'),
            actions: [
              IconButton(
                tooltip: 'Recargar carrito',
                onPressed: widget.cartViewModel.isLoading
                    ? null
                    : widget.cartViewModel.refresh,
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
            ],
          ),
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
                        Row(
                          children: [
                            const Text(
                              'Cantidad',
                              style: TextStyle(
                                color: Color(0xFF42505B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _selectedQuantity > 1
                                  ? () {
                                      setState(() {
                                        _selectedQuantity--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$_selectedQuantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              onPressed: _selectedQuantity < 99
                                  ? () {
                                      setState(() {
                                        _selectedQuantity++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isComparing || selectedId == null
                                    ? null
                                    : () => _compareByProductId(selectedId),
                                icon: const Icon(Icons.price_check_rounded),
                                label: const Text('Comparar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed:
                                    widget.cartViewModel.isSaving ||
                                        selectedId == null
                                    ? null
                                    : _addSelectedToCart,
                                icon: widget.cartViewModel.isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.add_shopping_cart_rounded,
                                      ),
                                label: const Text('Agregar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _CartSummaryCard(
                  totalItems: widget.cartViewModel.totalItems,
                  distinctProducts: widget.cartViewModel.distinctProducts,
                  subtotal: _formatCurrencyRaw(widget.cartViewModel.subtotal),
                  isLoading: widget.cartViewModel.isLoading,
                  isSaving: widget.cartViewModel.isSaving,
                  onRefresh: widget.cartViewModel.refresh,
                  onClear:
                      widget.cartViewModel.totalItems == 0 ||
                          widget.cartViewModel.isSaving
                      ? null
                      : () async {
                          final ok = await widget.cartViewModel.clear();
                          if (!context.mounted) return;
                          final message = ok
                              ? (widget.cartViewModel.infoMessage ??
                                    'Carrito vaciado.')
                              : (widget.cartViewModel.errorMessage ??
                                    'No se pudo vaciar el carrito.');
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                ),
                if (widget.cartViewModel.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _InfoBox(
                    message: widget.cartViewModel.errorMessage!,
                    color: const Color(0xFFFCEAEA),
                    textColor: const Color(0xFFAC2E2E),
                  ),
                ],
                if (widget.cartViewModel.infoMessage != null &&
                    widget.cartViewModel.errorMessage == null) ...[
                  const SizedBox(height: 12),
                  _InfoBox(
                    message: widget.cartViewModel.infoMessage!,
                    color: const Color(0xFFE9F5ED),
                    textColor: const Color(0xFF20573A),
                  ),
                ],
                if (_compareError != null) ...[
                  const SizedBox(height: 12),
                  _InfoBox(
                    message: _compareError!,
                    color: const Color(0xFFFCEAEA),
                    textColor: const Color(0xFFAC2E2E),
                  ),
                ],
                if (_compareCacheStatus != null) ...[
                  const SizedBox(height: 12),
                  _InfoBox(
                    message: 'Cache backend: $_compareCacheStatus',
                    color: const Color(0xFFE9F5ED),
                    textColor: const Color(0xFF20573A),
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
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: selectedId == null ||
                                    widget.cartViewModel.isSaving
                                ? null
                                : _addSelectedToCart,
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: Text(
                              widget.cartViewModel.isSaving
                                  ? 'Agregando...'
                                  : 'Agregar mejor opcion al carrito',
                            ),
                          ),
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
                                cartViewModel: widget.cartViewModel,
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

/// Vista de detalle para revisar todas las tiendas de un producto.
class ProductBestOptionDetailView extends StatelessWidget {
  const ProductBestOptionDetailView({
    super.key,
    required this.product,
    required this.catalogViewModel,
    required this.cartViewModel,
  });

  final Map<String, dynamic> product;
  final CatalogViewModel catalogViewModel;
  final CartViewModel cartViewModel;

  int? _productId() {
    final raw = product['id'] ?? product['product_id'] ?? product['productId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  int? _storeIdFromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final nestedStore = data['store'];
    final raw =
        data['store_id'] ??
        data['storeId'] ??
        (nestedStore is Map<String, dynamic>
            ? (nestedStore['id'] ?? nestedStore['store_id'])
            : null);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  int? _preferredStoreId() {
    final best = product['best_option'];
    if (best is Map<String, dynamic>) {
      final bestStoreId = _storeIdFromMap(best);
      if (bestStoreId != null) return bestStoreId;
    }

    num? cheapestValue;
    Map<String, dynamic>? cheapestRow;
    for (final row in catalogViewModel.productPriceRows(product)) {
      final raw = row['price'] ?? row['amount'] ?? row['value'];
      final value = raw is num ? raw : num.tryParse((raw ?? '').toString());
      if (value == null) continue;
      if (cheapestValue == null || value < cheapestValue) {
        cheapestValue = value;
        cheapestRow = row;
      }
    }
    return _storeIdFromMap(cheapestRow);
  }

  String _formatCurrency(num raw) {
    if (raw == raw.roundToDouble()) {
      return '\$${raw.toStringAsFixed(0)}';
    }
    return '\$${raw.toStringAsFixed(2)}';
  }

  num _unitPrice() {
    final raw =
        product['best_price'] ?? product['price'] ?? product['min_price'];
    if (raw is num) return raw;
    return num.tryParse((raw ?? '').toString().trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = catalogViewModel.productImageUrl(product);
    final rows = catalogViewModel.productPriceRows(product);
    final productId = _productId();

    return AnimatedBuilder(
      animation: cartViewModel,
      builder: (context, _) {
        return ProductDetailLayout(
          title: catalogViewModel.productName(product),
          description: catalogViewModel.productDescription(product),
          imageUrl: imageUrl,
          vendorName: catalogViewModel.productBestOptionStore(product),
          unitPrice: _unitPrice(),
          priceLabel: catalogViewModel.productBestOptionPrice(product),
          ratingLabel: '',
          reviewsLabel: '',
          categoryLabel: catalogViewModel.productCategoryName(product),
          badgeLabel:
              'Mejor opcion: ${catalogViewModel.productBestOptionStore(product)}',
          isSaving: cartViewModel.isSaving,
          onCartTap: null,
          onAddToCart: (quantity) async {
            if (productId == null) return;
            final ok = await cartViewModel.addItem(
              productId: productId,
              quantity: quantity,
              storeId: _preferredStoreId(),
            );
            if (!context.mounted) return;
            final message = ok
                ? (cartViewModel.infoMessage ?? 'Producto agregado al carrito.')
                : (cartViewModel.errorMessage ??
                      'No se pudo agregar el producto.');
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
          extraSections: [
            _CartSummaryCard(
              totalItems: cartViewModel.totalItems,
              distinctProducts: cartViewModel.distinctProducts,
              subtotal: _formatCurrency(cartViewModel.subtotal),
              isLoading: cartViewModel.isLoading,
              isSaving: cartViewModel.isSaving,
              onRefresh: cartViewModel.refresh,
              onClear:
                  cartViewModel.totalItems == 0 || cartViewModel.isSaving
                  ? null
                  : () async {
                      final ok = await cartViewModel.clear();
                      if (!context.mounted) return;
                      final message = ok
                          ? (cartViewModel.infoMessage ?? 'Carrito vaciado.')
                          : (cartViewModel.errorMessage ??
                                'No se pudo vaciar el carrito.');
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(message)));
                    },
            ),
            const SizedBox(height: 18),
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
                (row) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE3E8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          catalogViewModel.priceRowStoreName(row),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        catalogViewModel.priceRowPrice(row),
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
        );
      },
    );
  }
}

/// Tarjeta resumen de un producto dentro del listado de mejores opciones.
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

/// Tarjeta compacta para mostrar una metrica clave del comparador.
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

/// Resumen compacto del carrito autenticado con acciones basicas.
class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({
    required this.totalItems,
    required this.distinctProducts,
    required this.subtotal,
    required this.isLoading,
    required this.isSaving,
    required this.onRefresh,
    required this.onClear,
  });

  final int totalItems;
  final int distinctProducts;
  final String subtotal;
  final bool isLoading;
  final bool isSaving;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0D8A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_cart_checkout_rounded,
                color: Color(0xFF915F0A),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Carrito autenticado',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5F450D),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Recargar carrito',
                onPressed: isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 4),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.shopping_basket_rounded,
                  title: 'Items',
                  value: '$totalItems',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  icon: Icons.category_rounded,
                  title: 'Productos',
                  value: '$distinctProducts',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  icon: Icons.attach_money_rounded,
                  title: 'Subtotal',
                  value: subtotal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(isSaving ? 'Procesando...' : 'Vaciar carrito'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caja simple de mensajes informativos o de error.
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

/// Modelo privado que une id, nombre y payload original del producto.
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
