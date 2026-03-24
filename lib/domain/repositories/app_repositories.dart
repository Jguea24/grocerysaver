import '../entities/app_models.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String address,
    required String birthDate,
  });

  Future<AuthSession?> loginWithGoogle();
  Future<AuthSession> loginWithGoogleIdToken(String idToken);
  Future<AppUser?> restoreUser();
  Future<void> logout();
}

abstract class HouseholdRepository {
  Future<DashboardData> fetchDashboard();
  Future<List<CategorySummary>> fetchCategories();
  Future<List<ProductSummary>> fetchProducts({String search = '', String? barcode, int? categoryId});
  Future<ProductDetail> fetchProductDetail(int productId);
  Future<List<PriceComparisonItem>> fetchPriceComparison(int productId);
  Future<List<PriceHistoryEntry>> fetchPriceHistory(int productId);
  Future<ScanResult> scanCode(String code);

  Future<List<InventoryItem>> fetchInventory();
  Future<InventoryItem> addInventoryItem({
    required int productId,
    required int quantity,
    required String expiresAt,
  });
  Future<InventoryItem> updateInventoryItem({
    required int itemId,
    required int quantity,
    required String expiresAt,
  });
  Future<void> removeInventoryItem(int itemId);

  Future<List<CartItem>> fetchCart();
  Future<CartItem> addCartItem({
    required int productId,
    required int quantity,
  });
  Future<CartItem> updateCartItem({
    required int itemId,
    required int quantity,
  });
  Future<void> removeCartItem(int itemId);

  Future<List<AlertItem>> fetchAlerts();
  Future<void> dismissAlert(int alertId);
}
