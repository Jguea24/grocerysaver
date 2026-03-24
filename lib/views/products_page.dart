import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/api_config.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import 'cart_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, this.productService, this.cartService});

  final ProductService? productService;
  final CartService? cartService;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final ProductService _productService;
  late final CartService _cartService;

  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;
  List<ProductModel> _products = const [];
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _cartService = widget.cartService ?? CartService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _productService.fetchProducts(),
        _cartService.fetchCartItems(),
      ]);

      if (!mounted) return;
      setState(() {
        _products = results[0] as List<ProductModel>;
        _cartCount = (results[1] as List).length;
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

  Future<void> _openCart() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartPage(cartService: _cartService),
      ),
    );
    if (!mounted) return;
    await _refreshCartCount();
  }

  Future<void> _refreshCartCount() async {
    try {
      final items = await _cartService.fetchCartItems();
      if (!mounted) return;
      setState(() {
        _cartCount = items.length;
      });
    } catch (_) {}
  }

  Future<void> _addToCart(ProductModel product) async {
    setState(() {
      _isAdding = true;
    });

    try {
      await _cartService.addToCart(productId: product.id, quantity: 1);
      final items = await _cartService.fetchCartItems();
      if (!mounted) return;
      setState(() {
        _cartCount = items.length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} agregado al carrito.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogo'),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Abrir carrito',
                onPressed: _openCart,
                icon: const Icon(Icons.shopping_cart_rounded),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD94841),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _cartCount > 9 ? '9+' : '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
              _ProductsErrorView(message: _errorMessage!, onRetry: _loadData)
            else if (_products.isEmpty)
              const _ProductsEmptyView()
            else
              ..._products.map(
                (product) => _ProductTile(
                  product: product,
                  isAdding: _isAdding,
                  onAddToCart: () => _addToCart(product),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCart,
        icon: const Icon(Icons.shopping_cart_checkout_rounded),
        label: const Text('Ver carrito'),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.isAdding,
    required this.onAddToCart,
  });

  final ProductModel product;
  final bool isAdding;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final rawImage = product.categoryImage?.trim() ?? '';
    final imageUrl = rawImage.isEmpty ? '' : ApiConfig.resolveBackendUrl(rawImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6DDD0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEF9),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isEmpty
                ? const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6B54E4))
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6B54E4));
                    },
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '${product.displayBrand} · ${product.displayCategory}',
                  style: const TextStyle(color: Color(0xFF66756F)),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${product.bestPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16423C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: isAdding ? null : onAddToCart,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}

class _ProductsErrorView extends StatelessWidget {
  const _ProductsErrorView({required this.message, required this.onRetry});

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

class _ProductsEmptyView extends StatelessWidget {
  const _ProductsEmptyView();

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
          Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF6C7B74)),
          SizedBox(height: 12),
          Text(
            'Sin productos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'El backend no devolvio productos en response["products"].',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF66756F), height: 1.4),
          ),
        ],
      ),
    );
  }
}

