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
  List<Map<String, dynamic>> _products = const [];
  Map<String, dynamic>? _compareResult;
  int? _selectedCategoryId;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  bool get isLoadingCompare => _isLoadingCompare;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get stores => _stores;
  List<Map<String, dynamic>> get categories => _categories;
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
      _products = _toMapList(results[2]);

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

  String storeName(Map<String, dynamic> store) {
    final raw = store['name'] ?? store['store'] ?? store['store_name'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Tienda' : text;
  }

  String productName(Map<String, dynamic> product) {
    return _productName(product) ?? 'Producto';
  }

  String productPrice(Map<String, dynamic> product) {
    final raw =
        product['price'] ??
        product['current_price'] ??
        product['min_price'] ??
        product['best_price'];
    if (raw == null) return '-';
    return '\$$raw';
  }

  String productStore(Map<String, dynamic> product) {
    final raw = product['store'] ?? product['store_name'] ?? product['market'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Sin tienda' : text;
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

  String _errorToText(Object error) {
    if (error is CatalogApiException) {
      return error.message;
    }
    return 'No se pudo cargar catalogo.';
  }
}
