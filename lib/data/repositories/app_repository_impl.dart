import '../../core/google_auth_service.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/repositories/app_repositories.dart';
import '../core/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client, this._googleAuthService);

  final ApiClient _client;
  final GoogleAuthService _googleAuthService;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/login/',
      body: {'email': email, 'password': password},
    );
    return _buildSession(data as Map<String, dynamic>);
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String address,
    required String birthDate,
  }) async {
    await _client.post(
      '/auth/register/',
      body: {
        'username': _buildUsername(firstName: firstName, lastName: lastName, email: email),
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'role': 'cliente',
        'address': address,
        'birth_date': birthDate,
      },
    );
  }

  @override
  Future<AuthSession?> loginWithGoogle() async {
    final googleUser = await _googleAuthService.signIn();
    if (googleUser == null) return null;
    return loginWithGoogleIdToken(googleUser.idToken);
  }

  @override
  Future<AuthSession> loginWithGoogleIdToken(String idToken) async {
    final data = await _client.post(
      '/auth/social-login/',
      body: {
        'provider': 'google',
        'id_token': idToken,
      },
    );
    return _buildSession(data as Map<String, dynamic>);
  }

  @override
  Future<AppUser?> restoreUser() async {
    await _client.restoreSession();
    try {
      final me = await _client.get('/auth/me/', auth: true);
      return AppUser.fromJson(me as Map<String, dynamic>);
    } catch (_) {
      await _client.clearSession();
      return null;
    }
  }

  @override
  Future<void> logout() {
    return _client.clearSession();
  }


  String _buildUsername({
    required String firstName,
    required String lastName,
    required String email,
  }) {
    final base = '${firstName.trim()}.${lastName.trim()}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.]'), '');
    if (base.isNotEmpty) {
      return base;
    }

    final fromEmail = email.trim().split('@').first.toLowerCase();
    final cleaned = fromEmail.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    return cleaned.isEmpty ? 'cliente' : cleaned;
  }

  Future<AuthSession> _buildSession(Map<String, dynamic> data) async {
    final tokens = (data['tokens'] as Map<String, dynamic>?) ?? data;
    final access = (tokens['access'] ?? '').toString();
    final refresh = (tokens['refresh'] ?? '').toString();
    await _client.saveSession(accessToken: access, refreshToken: refresh);
    final me = await _client.get('/auth/me/', auth: true);
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      user: AppUser.fromJson(me as Map<String, dynamic>),
    );
  }
}

class HouseholdRepositoryImpl implements HouseholdRepository {
  HouseholdRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<DashboardData> fetchDashboard() async {
    final results = await Future.wait<dynamic>([
      _client.get('/categories/'),
      _client.get('/products/'),
      _client.get('/offers/'),
      _client.get('/alerts/', auth: true, queryParameters: {'status': 'active'}),
    ]);

    return DashboardData(
      categories: _readCategories(results[0]),
      products: _readProducts(results[1]),
      offers: _readProducts(results[2]),
      alerts: _readAlerts(results[3]),
    );
  }

  @override
  Future<List<CategorySummary>> fetchCategories() async {
    final data = await _client.get('/categories/');
    return _readCategories(data);
  }

  @override
  Future<List<ProductSummary>> fetchProducts({
    String search = '',
    String? barcode,
    int? categoryId,
  }) async {
    final params = <String, String>{};
    if (search.trim().isNotEmpty) params['search'] = search.trim();
    if ((barcode ?? '').trim().isNotEmpty) params['barcode'] = barcode!.trim();
    if (categoryId != null && categoryId > 0) params['category_id'] = '$categoryId';
    final data = await _client.get('/products/', queryParameters: params);
    return _readProducts(data);
  }

  @override
  Future<ProductDetail> fetchProductDetail(int productId) async {
    final results = await Future.wait<dynamic>([
      _client.get('/products/$productId/'),
      _safeGet(
        '/compare-prices/',
        queryParameters: {'product_id': '$productId'},
      ),
      _safeGet(
        '/prices/history/',
        queryParameters: {'product_id': '$productId', 'limit': '20'},
      ),
      _safeGet(
        '/products/',
        queryParameters: {'related_to': '$productId'},
      ),
    ]);

    final detailMap = results[0] as Map<String, dynamic>;
    final productMap = _readDetailProduct(detailMap, productId);
    final product = ProductSummary.fromJson(productMap);
    final alternativesSource = detailMap['cheaper_alternatives'] ?? detailMap['alternatives'] ?? results[3];
    final historySource = detailMap['purchase_history'] ?? detailMap['price_history'] ?? results[2];
    final comparisonSource = detailMap['compare_prices'] ?? detailMap['comparisons'] ?? results[1];

    return ProductDetail(
      product: product,
      description: (detailMap['description'] ?? productMap['description'] ??
              'Producto listo para seguimiento de stock, precio e historial.')
          .toString(),
      alternatives: _readProducts(alternativesSource)
          .where((item) => item.id != productId)
          .take(4)
          .toList(),
      comparisons: _readComparisons(comparisonSource),
      history: _readHistory(historySource),
    );
  }

  @override
  Future<List<PriceComparisonItem>> fetchPriceComparison(int productId) async {
    final data = await _safeGet(
      '/compare-prices/',
      queryParameters: {'product_id': '$productId'},
    );
    return _readComparisons(data);
  }

  @override
  Future<List<PriceHistoryEntry>> fetchPriceHistory(int productId) async {
    final data = await _safeGet(
      '/prices/history/',
      queryParameters: {'product_id': '$productId', 'limit': '20'},
    );
    return _readHistory(data);
  }

  @override
  Future<ScanResult> scanCode(String code) async {
    final data = await _client.post('/products/scan/', body: {'code': code});
    final map = data as Map<String, dynamic>;
    final rawProduct = map['product'] ?? map['data'] ?? map;
    final product = rawProduct is Map<String, dynamic> && rawProduct['id'] != null
        ? ProductSummary.fromJson(rawProduct)
        : null;
    return ScanResult(
      code: code,
      product: product,
      message: (map['message'] ?? 'Escaneo completado').toString(),
    );
  }

  @override
  Future<List<InventoryItem>> fetchInventory() async {
    final data = await _client.get('/inventory/items/', auth: true);
    return _readList(data).map(InventoryItem.fromJson).toList();
  }

  @override
  Future<InventoryItem> addInventoryItem({
    required int productId,
    required int quantity,
    required String expiresAt,
  }) async {
    final data = await _client.post(
      '/inventory/items/',
      auth: true,
      body: {
        'product_id': productId,
        'quantity': quantity,
        'expires_at': expiresAt,
      },
    );
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final item = (map['item'] ?? map) as Map<String, dynamic>;
    return InventoryItem.fromJson(item);
  }

  @override
  Future<InventoryItem> updateInventoryItem({
    required int itemId,
    required int quantity,
    required String expiresAt,
  }) async {
    final data = await _client.patch(
      '/inventory/items/$itemId/',
      auth: true,
      body: {'quantity': quantity, 'expires_at': expiresAt},
    );
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final item = (map['item'] ?? map) as Map<String, dynamic>;
    return InventoryItem.fromJson(item);
  }

  @override
  Future<void> removeInventoryItem(int itemId) async {
    await _client.delete('/inventory/items/$itemId/', auth: true);
  }

  @override
  Future<List<CartItem>> fetchCart() async {
    final data = await _client.get('/cart/items/', auth: true);
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final source = map['cart'] ?? map['results'] ?? map['items'] ?? data;
    final items = source is Map<String, dynamic> ? source['items'] ?? source : source;
    return _readList(items).map(CartItem.fromJson).toList();
  }

  @override
  Future<CartItem> addCartItem({
    required int productId,
    required int quantity,
  }) async {
    final data = await _client.post(
      '/cart/items/',
      auth: true,
      body: {'product_id': productId, 'quantity': quantity},
    );
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final item = map['item'] ?? map['cart_item'] ?? map['data'] ?? map;
    return CartItem.fromJson(item as Map<String, dynamic>);
  }

  @override
  Future<CartItem> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    final data = await _client.patch(
      '/cart/items/$itemId/',
      auth: true,
      body: {'quantity': quantity},
    );
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final item = map['item'] ?? map['cart_item'] ?? map['data'] ?? map;
    return CartItem.fromJson(item as Map<String, dynamic>);
  }

  @override
  Future<void> removeCartItem(int itemId) async {
    await _client.delete('/cart/items/$itemId/', auth: true);
  }

  @override
  Future<List<AlertItem>> fetchAlerts() async {
    final data = await _client.get(
      '/alerts/',
      auth: true,
      queryParameters: {'status': 'active'},
    );
    return _readAlerts(data);
  }

  @override
  Future<void> dismissAlert(int alertId) async {
    await _client.patch(
      '/alerts/$alertId/',
      auth: true,
      body: {'status': 'dismissed'},
    );
  }

  List<CategorySummary> _readCategories(dynamic data) {
    return _readList(data).map(CategorySummary.fromJson).toList();
  }

  List<ProductSummary> _readProducts(dynamic data) {
    return _readList(data).map(ProductSummary.fromJson).toList();
  }

  Map<String, dynamic> _readDetailProduct(
    Map<String, dynamic> data,
    int productId,
  ) {
    final nested = data['product'] as Map<String, dynamic>?;
    return {
      'id': nested?['id'] ?? data['id'] ?? productId,
      'name': nested?['name'] ?? data['name'] ?? data['product_name'],
      'brand': nested?['brand'] ?? data['brand'],
      'brand_name': nested?['brand_name'] ?? data['brand_name'],
      'barcode': nested?['barcode'] ?? data['barcode'],
      'category': nested?['category'] ?? data['category'],
      'category_name': nested?['category_name'] ?? data['category_name'],
      'category_detail': nested?['category_detail'] ?? data['category_detail'],
      'image': nested?['image'] ?? data['image'],
      'image_url': nested?['image_url'] ?? data['image_url'],
      'category_image': nested?['category_image'] ?? data['category_image'],
      'estimated_price': data['estimated_price'] ?? nested?['estimated_price'],
      'best_price': data['best_price'] ?? nested?['best_price'],
      'best_option': data['best_option'] ?? nested?['best_option'],
      'price': data['price'] ?? nested?['price'],
      'description': data['description'] ?? nested?['description'],
    };
  }

  List<AlertItem> _readAlerts(dynamic data) {
    final source = data is Map<String, dynamic>
        ? data['alerts'] ?? data['results'] ?? data['items'] ?? data
        : data;
    return _readList(source).map(AlertItem.fromJson).toList();
  }

  List<PriceComparisonItem> _readComparisons(dynamic data) {
    final source = data is Map<String, dynamic>
        ? data['results'] ?? data['comparisons'] ?? data['prices'] ?? data
        : data;
    return _readList(source).map(PriceComparisonItem.fromJson).toList();
  }

  List<PriceHistoryEntry> _readHistory(dynamic data) {
    final source = data is Map<String, dynamic>
        ? data['results'] ?? data['history'] ?? data['prices'] ?? data
        : data;
    return _readList(source).map(PriceHistoryEntry.fromJson).toList();
  }

  List<Map<String, dynamic>> _readList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final nested = data['results'] ?? data['items'] ?? data['data'] ?? data['products'] ?? data['categories'] ?? data['alerts'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
      if (data['id'] != null) {
        return [data];
      }
    }
    return const [];
  }

  Future<dynamic> _safeGet(
    String path, {
    bool auth = false,
    Map<String, String>? queryParameters,
  }) async {
    try {
      return await _client.get(
        path,
        auth: auth,
        queryParameters: queryParameters,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return const <Map<String, dynamic>>[];
      }
      rethrow;
    }
  }
}





