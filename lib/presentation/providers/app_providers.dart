import 'package:flutter/foundation.dart';

import '../../core/local_notification_service.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/repositories/app_repositories.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;
  AppUser? _user;
  bool _isBootstrapping = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get isBootstrapping => _isBootstrapping;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    _isBootstrapping = true;
    notifyListeners();
    _user = await _repository.restoreUser();
    _isBootstrapping = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _setSubmitting(true);
    try {
      final session = await _repository.login(email: email, password: password);
      _user = session.user;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String address,
    required String birthDate,
  }) async {
    _setSubmitting(true);
    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        address: address,
        birthDate: birthDate,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    _setSubmitting(true);
    try {
      final session = await _repository.loginWithGoogle();
      if (session == null) {
        _errorMessage = null;
        notifyListeners();
        return false;
      }
      _user = session.user;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> loginWithGoogleIdToken(String idToken) async {
    _setSubmitting(true);
    try {
      final session = await _repository.loginWithGoogleIdToken(idToken);
      _user = session.user;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }
}

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository);

  final HouseholdRepository _repository;
  DashboardData _data = const DashboardData(categories: [], products: [], offers: [], alerts: []);
  bool _isLoading = false;
  String? _errorMessage;

  DashboardData get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _data = await _repository.fetchDashboard();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> dismissAlert(int alertId) async {
    await _repository.dismissAlert(alertId);
    _data = DashboardData(
      categories: _data.categories,
      products: _data.products,
      offers: _data.offers,
      alerts: _data.alerts.where((item) => item.id != alertId).toList(),
    );
    notifyListeners();
  }
}

class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._repository);

  final HouseholdRepository _repository;
  List<InventoryItem> _items = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.fetchInventory();
      await LocalNotificationService.instance.notifyExpiringInventory(_items);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem({
    required int productId,
    required int quantity,
    required String expiresAt,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final item = await _repository.addInventoryItem(
        productId: productId,
        quantity: quantity,
        expiresAt: expiresAt,
      );
      _items = [item, ..._items];
      await LocalNotificationService.instance.notifyExpiringInventory(_items);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem({
    required int itemId,
    required int quantity,
    required String expiresAt,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final updated = await _repository.updateInventoryItem(
        itemId: itemId,
        quantity: quantity,
        expiresAt: expiresAt,
      );
      _items = _items.map((item) => item.id == itemId ? updated : item).toList();
      await LocalNotificationService.instance.notifyExpiringInventory(_items);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(int itemId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.removeInventoryItem(itemId);
      await load();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

class ShoppingListProvider extends ChangeNotifier {
  ShoppingListProvider(this._repository);

  final HouseholdRepository _repository;
  List<CartItem> _items = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.fetchCart();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem({required int productId, required int quantity}) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.addCartItem(
        productId: productId,
        quantity: quantity,
      );
      _errorMessage = null;
      await load();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem({required int itemId, required int quantity}) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );
      _errorMessage = null;
      await load();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(int itemId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.removeCartItem(itemId);
      await load();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

class ProductDetailProvider extends ChangeNotifier {
  ProductDetailProvider(this._repository);

  final HouseholdRepository _repository;
  ProductDetail? _detail;
  bool _isLoading = false;
  String? _errorMessage;

  ProductDetail? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(int productId) async {
    _isLoading = true;
    _detail = null;
    _errorMessage = null;
    notifyListeners();
    try {
      _detail = await _repository.fetchProductDetail(productId);
    } catch (error) {
      _detail = null;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class ScannerProvider extends ChangeNotifier {
  ScannerProvider(this._repository);

  final HouseholdRepository _repository;
  ScanResult? _lastResult;
  bool _isSubmitting = false;
  String? _errorMessage;

  ScanResult? get lastResult => _lastResult;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<ScanResult?> submitCode(String code) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _lastResult = await _repository.scanCode(code);
      notifyListeners();
      return _lastResult;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}








