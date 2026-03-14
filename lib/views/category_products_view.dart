// Pantalla de productos filtrados por una categoria concreta.
import 'package:flutter/material.dart';

import '../components/product_detail_layout.dart';
import '../services/api_config.dart';
import '../services/catalog_api.dart';
import '../services/cart_api.dart';
import '../viewmodels/cart_viewmodel.dart';

/// Muestra productos pertenecientes a una categoria especifica.
class CategoryProductsView extends StatefulWidget {
  const CategoryProductsView({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  @override
  State<CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends State<CategoryProductsView> {
  late final CatalogApi _api;
  late final CartViewModel _cartViewModel;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _products = const [];

  @override
  void initState() {
    super.initState();
    _api = CatalogApi(ApiConfig.baseUrl);
    _cartViewModel = CartViewModel(api: CartApi(ApiConfig.baseUrl));
    _cartViewModel.loadCart();
    _loadProducts();
  }

  @override
  void dispose() {
    _cartViewModel.dispose();
    super.dispose();
  }

  /// Consulta los productos de la categoria seleccionada.
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _api.getProducts(categoryId: widget.categoryId);
      _products = list.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      _errorMessage = _errorToText(e);
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: RefreshIndicator(onRefresh: _loadProducts, child: _buildContent()),
    );
  }

  /// Escoge entre loading, error, vacio o grilla de productos.
  Widget _buildContent() {
    if (_isLoading && _products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null && _products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Color(0xFFAC2E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (_products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'No hay productos en esta categoria.',
            style: TextStyle(color: Color(0xFF7A8A97), fontSize: 15),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final product = _products[index];
        return _ProductTile(
          name: _name(product),
          description: _description(product),
          imageUrl: _imageUrl(product),
          price: _price(product),
          stores: _storesAvailable(product),
          bestOption: _bestOption(product),
          onTap: () => _openProductDetail(product),
        );
      },
    );
  }

  /// Abre el detalle de un producto manteniendo datos ya cargados.
  void _openProductDetail(Map<String, dynamic> product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CategoryProductDetailView(
          product: product,
          name: _name(product),
          description: _description(product),
          imageUrl: _imageUrl(product),
          price: _price(product),
          stores: _storesAvailable(product),
          bestOption: _bestOption(product),
          categoryName: _categoryName(product),
          prices: _priceRows(product),
          cartViewModel: _cartViewModel,
        ),
      ),
    );
  }

  /// Devuelve el nombre visible del producto.
  String _name(Map<String, dynamic> product) {
    final raw = product['name'] ?? product['title'] ?? product['product'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Producto' : text;
  }

  /// Devuelve una descripcion breve o fallback legible.
  String _description(Map<String, dynamic> product) {
    final raw = product['description'] ?? product['brand'] ?? product['marca'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Sin descripcion' : text;
  }

  /// Devuelve la URL de imagen si existe.
  String? _imageUrl(Map<String, dynamic> product) {
    final raw = product['image'] ?? product['image_url'] ?? product['photo'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Devuelve el precio visible de referencia.
  String _price(Map<String, dynamic> product) {
    final raw =
        product['best_price'] ?? product['price'] ?? product['min_price'];
    return raw == null ? '-' : '\$$raw';
  }

  /// Calcula cuantas tiendas reportan el producto.
  String _storesAvailable(Map<String, dynamic> product) {
    final raw = product['stores_available'];
    if (raw != null && raw.toString().trim().isNotEmpty) return '$raw';
    final prices = product['prices'];
    if (prices is List) return '${prices.length}';
    return '0';
  }

  /// Resume la mejor opcion de compra dentro de una sola cadena.
  String _bestOption(Map<String, dynamic> product) {
    final best = product['best_option'];
    if (best is Map<String, dynamic>) {
      final storeRaw = best['store'];
      String store = '-';
      if (storeRaw is Map<String, dynamic>) {
        store =
            (storeRaw['name'] ??
                    storeRaw['store_name'] ??
                    storeRaw['title'] ??
                    '-')
                .toString();
      } else {
        store = (best['store'] ?? best['store_name'] ?? best['name'] ?? '-')
            .toString();
      }
      final price = best['price'] ?? best['best_price'] ?? '-';
      return '$store ($price)';
    }
    return '-';
  }

  /// Resuelve el nombre de categoria asociado al producto.
  String _categoryName(Map<String, dynamic> product) {
    final category = product['category'];
    if (category is Map<String, dynamic>) {
      final raw = category['name'] ?? category['title'];
      final text = (raw ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    final raw = product['category_name'] ?? category;
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? widget.categoryName : text;
  }

  /// Convierte la lista cruda de precios a un modelo simple para detalle.
  List<_StorePrice> _priceRows(Map<String, dynamic> product) {
    final prices = product['prices'];
    if (prices is! List) return const [];
    final rows = <_StorePrice>[];
    for (final item in prices) {
      if (item is! Map<String, dynamic>) continue;
      final storeRaw = item['store'];
      String store = 'Tienda';
      if (storeRaw is Map<String, dynamic>) {
        final name =
            storeRaw['name'] ?? storeRaw['store_name'] ?? storeRaw['title'];
        final text = (name ?? '').toString().trim();
        if (text.isNotEmpty) store = text;
      } else {
        final name = item['store_name'] ?? item['store'] ?? item['market'];
        final text = (name ?? '').toString().trim();
        if (text.isNotEmpty) store = text;
      }
      final rawPrice = item['price'] ?? item['amount'] ?? item['value'];
      final priceText = rawPrice == null ? 'N/A' : '\$$rawPrice';
      rows.add(_StorePrice(store: store, price: priceText));
    }
    return rows;
  }

  /// Traduce errores del servicio a texto apto para UI.
  String _errorToText(Object error) {
    if (error is CatalogApiException) return error.message;
    return 'No se pudieron cargar los productos.';
  }
}

/// Tarjeta compacta usada en la grilla de productos de la categoria.
class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.stores,
    required this.bestOption,
    required this.onTap,
  });

  final String name;
  final String description;
  final String? imageUrl;
  final String price;
  final String stores;
  final String bestOption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE3E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProductImage(imageUrl: imageUrl),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111316),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8A959F), fontSize: 12),
            ),
            const Spacer(),
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFF1F6A47),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tiendas: $stores',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF5E6B76), fontSize: 12),
            ),
            Text(
              'Mejor: $bestOption',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF5E6B76), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de detalle para un producto dentro de la categoria.
class _CategoryProductDetailView extends StatelessWidget {
  const _CategoryProductDetailView({
    required this.product,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.stores,
    required this.bestOption,
    required this.categoryName,
    required this.prices,
    required this.cartViewModel,
  });

  final Map<String, dynamic> product;
  final String name;
  final String description;
  final String? imageUrl;
  final String price;
  final String stores;
  final String bestOption;
  final String categoryName;
  final List<_StorePrice> prices;
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
    for (final row in product['prices'] is List ? product['prices'] as List : const []) {
      if (row is Map<String, dynamic>) {
        final candidate = _storeIdFromMap(row);
        if (candidate != null) return candidate;
      }
    }
    return null;
  }

  num _unitPrice() {
    final raw = product['best_price'] ?? product['price'] ?? product['min_price'];
    if (raw is num) return raw;
    return num.tryParse((raw ?? '').toString().trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cartViewModel,
      builder: (context, _) {
        return ProductDetailLayout(
          title: name,
          description: description,
          imageUrl: imageUrl,
          vendorName: bestOption == '-' ? 'Tienda disponible' : bestOption,
          unitPrice: _unitPrice(),
          priceLabel: price,
          oldPriceLabel: null,
          ratingLabel: '',
          reviewsLabel: '',
          categoryLabel: categoryName,
          badgeLabel: bestOption == '-' ? null : bestOption,
          isSaving: cartViewModel.isSaving,
          onCartTap: null,
          onAddToCart: (quantity) async {
            final productId = _productId();
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
            const Text(
              'Precios por tienda',
              style: TextStyle(
                color: Color(0xFF1A242D),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            if (prices.isEmpty)
              const Text(
                'Sin precios disponibles',
                style: TextStyle(color: Color(0xFF7A8A97)),
              )
            else
              ...prices.map(
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
                          row.store,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        row.price,
                        style: const TextStyle(
                          color: Color(0xFF1F6A47),
                          fontWeight: FontWeight.w800,
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

/// Modelo ligero de precio por tienda para la pantalla de detalle.
class _StorePrice {
  const _StorePrice({required this.store, required this.price});

  final String store;
  final String price;
}

/// Imagen del producto con fallback neutro si falla la carga remota.
class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_basket_outlined,
        size: 20,
        color: Color(0xFF7B8791),
      ),
    );
  }
}
