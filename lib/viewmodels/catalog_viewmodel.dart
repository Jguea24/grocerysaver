import 'package:flutter/foundation.dart';

import '../services/catalog_api.dart';

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel({required CatalogApi api}) : _api = api;

  final CatalogApi _api;

  bool _isLoading = false;
  bool _isLoadingCompare = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _stores = const [];
  List<Map<String, dynamic>> _categories = const [];
  List<Map<String, dynamic>> _featuredProducts = const [];
  List<Map<String, dynamic>> _products = const [];
  Map<String, dynamic>? _compareResult;
  int? _selectedCategoryId;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  bool get isLoadingCompare => _isLoadingCompare;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get stores => _stores;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get featuredProducts => _featuredProducts;
  List<Map<String, dynamic>> get products => _products;
  Map<String, dynamic>? get compareResult => _compareResult;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getStores(),
        _api.getCategories(),
        _api.getProducts(),
      ]);

      _stores = _toMapList(results[0]);
      _categories = _toMapList(results[1]);
      _featuredProducts = _toMapList(results[2]);
      _products = _featuredProducts;

      await compareCurrent();
    } catch (e) {
      _errorMessage = _errorToText(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadInitialData();
  }

  Future<void> selectCategoryById(int? categoryId) async {
    _selectedCategoryId = categoryId;
    await _loadProducts();
  }

  Future<void> updateSearch(String value) async {
    _searchQuery = value.trim();
    await _loadProducts();
  }

  Future<void> compareCurrent() async {
    _isLoadingCompare = true;
    notifyListeners();
    try {
      final firstProduct = _products.isEmpty
          ? null
          : _productName(_products.first);
      final queryProduct = _searchQuery.isNotEmpty
          ? _searchQuery
          : firstProduct;

      if (queryProduct == null || queryProduct.isEmpty) {
        _compareResult = null;
        return;
      }

      _compareResult = await _api.comparePrices(product: queryProduct);
    } catch (e) {
      _errorMessage = _errorToText(e);
    } finally {
      _isLoadingCompare = false;
      notifyListeners();
    }
  }

  Future<void> _loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _api.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );
      _products = _toMapList(data);
      await compareCurrent();
    } catch (e) {
      _errorMessage = _errorToText(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  int? categoryId(Map<String, dynamic> category) {
    return int.tryParse((category['id'] ?? '').toString());
  }

  String categoryName(Map<String, dynamic> category) {
    final raw = category['name'] ?? category['category'] ?? category['title'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Categoria' : text;
  }

  String? categoryImageUrl(Map<String, dynamic> category) {
    final raw = category['image'] ?? category['image_url'] ?? category['icon'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  String storeName(Map<String, dynamic> store) {
    final raw = store['name'] ?? store['store'] ?? store['store_name'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Tienda' : text;
  }

  String productName(Map<String, dynamic> product) {
    return _productName(product) ?? 'Producto';
  }

  String? productImageUrl(Map<String, dynamic> product) {
    final raw = product['image'] ?? product['image_url'] ?? product['photo'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  String productCategoryName(Map<String, dynamic> product) {
    final category = product['category'];
    if (category is Map<String, dynamic>) {
      final raw = category['name'] ?? category['title'];
      final text = (raw ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    final raw = product['category_name'] ?? category;
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Sin categoria' : text;
  }

  String productDescription(Map<String, dynamic> product) {
    final raw =
        product['description'] ??
        product['descripcion'] ??
        product['brand'] ??
        product['marca'] ??
        product['maker'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Sin marca' : text;
  }

  // Mantiene compatibilidad con la UI existente sin cambiar su flujo.
  String productBrand(Map<String, dynamic> product) {
    return productDescription(product);
  }

  String productPrice(Map<String, dynamic> product) {
    final raw =
        product['best_price'] ??
        product['price'] ??
        product['current_price'] ??
        product['min_price'] ??
        _bestPriceFromPrices(product);
    if (raw == null) return '-';
    return '\$$raw';
  }

  String productStore(Map<String, dynamic> product) {
    final raw = product['store'] ?? product['store_name'] ?? product['market'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim();
    }
    final rows = productPriceRows(product);
    if (rows.isNotEmpty) {
      final firstStore = rows.first['store'];
      if (firstStore is Map<String, dynamic>) {
        final nestedName = firstStore['name'] ?? firstStore['store_name'];
        final text = (nestedName ?? '').toString().trim();
        if (text.isNotEmpty) return text;
      }
      final directName = rows.first['store_name'] ?? rows.first['store'];
      final text = (directName ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Sin tienda' : text;
  }

  List<Map<String, dynamic>> productPriceRows(Map<String, dynamic> product) {
    final prices = product['prices'];
    if (prices is! List) return const [];
    return prices.whereType<Map<String, dynamic>>().toList();
  }

  String priceRowStoreName(Map<String, dynamic> row) {
    final store = row['store'];
    if (store is Map<String, dynamic>) {
      final raw = store['name'] ?? store['store_name'] ?? store['title'];
      final text = (raw ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    final raw = row['store_name'] ?? row['store'] ?? row['market'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Tienda' : text;
  }

  String priceRowPrice(Map<String, dynamic> row) {
    final raw = row['price'] ?? row['amount'] ?? row['value'];
    if (raw == null) return 'N/A';
    return '\$$raw';
  }

  int productStoresAvailable(Map<String, dynamic> product) {
    final raw = product['stores_available'];
    if (raw is int) return raw;
    final parsed = int.tryParse((raw ?? '').toString().trim());
    if (parsed != null) return parsed;
    return productPriceRows(product).length;
  }

  String productBestOptionStore(Map<String, dynamic> product) {
    final best = product['best_option'];
    if (best is Map<String, dynamic>) {
      final nestedStore = best['store'];
      if (nestedStore is Map<String, dynamic>) {
        final nestedName =
            nestedStore['name'] ??
            nestedStore['store_name'] ??
            nestedStore['title'];
        final nestedText = (nestedName ?? '').toString().trim();
        if (nestedText.isNotEmpty) return nestedText;
      }
      final directName = best['store'] ?? best['store_name'] ?? best['name'];
      final directText = (directName ?? '').toString().trim();
      if (directText.isNotEmpty) return directText;
    }
    return productStore(product);
  }

  String productBestOptionPrice(Map<String, dynamic> product) {
    final best = product['best_option'];
    if (best is Map<String, dynamic>) {
      final raw = best['price'] ?? best['best_price'] ?? best['amount'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        return '\$$raw';
      }
    }
    return productPrice(product);
  }

  String? productDiscountBadge(Map<String, dynamic> product) {
    final rows = productPriceRows(product);
    if (rows.length < 2) return null;

    num? min;
    num? max;
    for (final row in rows) {
      final raw = row['price'] ?? row['amount'] ?? row['value'];
      final value = raw is num ? raw : num.tryParse(raw.toString());
      if (value == null) continue;
      min = min == null || value < min ? value : min;
      max = max == null || value > max ? value : max;
    }

    if (min == null || max == null || max <= 0 || min >= max) {
      return null;
    }

    final percent = (((max - min) / max) * 100).round();
    if (percent <= 0) return null;
    return '+$percent%';
  }

  String? bestStoreName() {
    final best = compareResult?['best_option'];
    if (best is Map<String, dynamic>) {
      final raw = best['store'] ?? best['store_name'] ?? best['name'];
      final text = (raw ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  String? bestPrice() {
    final best = compareResult?['best_option'];
    if (best is Map<String, dynamic>) {
      final raw = best['price'] ?? best['best_price'] ?? best['amount'];
      if (raw != null) return '\$$raw';
    }
    return null;
  }

  String? _productName(Map<String, dynamic> product) {
    final raw = product['name'] ?? product['product'] ?? product['title'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  dynamic _bestPriceFromPrices(Map<String, dynamic> product) {
    final rows = productPriceRows(product);
    if (rows.isEmpty) return null;

    num? best;
    for (final row in rows) {
      final raw = row['price'] ?? row['amount'] ?? row['value'];
      final value = raw is num ? raw : num.tryParse(raw.toString());
      if (value == null) continue;
      if (best == null || value < best) {
        best = value;
      }
    }
    return best;
  }

  String _errorToText(Object error) {
    if (error is CatalogApiException) {
      return error.message;
    }
    return 'No se pudo cargar catalogo.';
  }
}
