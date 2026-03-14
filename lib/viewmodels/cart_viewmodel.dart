// Estado del carrito autenticado consumido por vistas de compra.
import 'package:flutter/foundation.dart';

import '../services/cart_api.dart';

/// ViewModel del carrito alineado con el resto de modulos de la app.
class CartViewModel extends ChangeNotifier {
  CartViewModel({required CartApi api}) : _api = api;

  final CartApi _api;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _infoMessage;
  Map<String, dynamic>? _cartResponse;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  Map<String, dynamic>? get cartResponse => _cartResponse;

  /// Devuelve el nodo `cart` tolerando respuestas ya desenvueltas.
  Map<String, dynamic> get cart {
    final raw = _cartResponse?['cart'];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    return _cartResponse ?? const {};
  }

  /// Devuelve los items del carrito como lista segura.
  List<Map<String, dynamic>> get items {
    final raw = cart['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  /// Expone la cantidad total de items.
  int get totalItems => _asInt(cart['total_items']) ?? items.length;

  /// Expone la cantidad de productos distintos.
  int get distinctProducts =>
      _asInt(cart['distinct_products']) ?? items.length;

  /// Expone el subtotal del carrito.
  num get subtotal => _asNum(cart['subtotal']) ?? 0;

  /// Consulta el carrito actual desde el backend.
  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cartResponse = await _api.getCart();
    } catch (e) {
      _errorMessage = _errorToText(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alias semantico para la recarga manual desde UI.
  Future<void> refresh() async {
    await loadCart();
  }

  /// Agrega un producto y sincroniza el estado visible del carrito.
  Future<bool> addItem({
    required int productId,
    int quantity = 1,
    int? storeId,
  }) async {
    _startMutation();
    try {
      await _api.addCartItem(
        productId: productId,
        quantity: quantity,
        storeId: storeId,
      );
      _infoMessage = 'Producto agregado al carrito.';
      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      notifyListeners();
      return false;
    } finally {
      _finishMutation();
    }
  }

  /// Actualiza un item existente y luego recarga el carrito.
  Future<bool> updateItem({
    required int itemId,
    int? quantity,
    int? storeId,
  }) async {
    _startMutation();
    try {
      await _api.updateCartItem(
        itemId: itemId,
        quantity: quantity,
        storeId: storeId,
      );
      _infoMessage = 'Carrito actualizado.';
      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      notifyListeners();
      return false;
    } finally {
      _finishMutation();
    }
  }

  /// Elimina un item del carrito y sincroniza el resumen.
  Future<bool> removeItem(int itemId) async {
    _startMutation();
    try {
      await _api.deleteCartItem(itemId);
      _infoMessage = 'Item eliminado del carrito.';
      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      notifyListeners();
      return false;
    } finally {
      _finishMutation();
    }
  }

  /// Vacia el carrito por completo.
  Future<bool> clear() async {
    _startMutation();
    try {
      await _api.clearCart();
      _cartResponse = const {
        'cart': {
          'items': [],
          'total_items': 0,
          'distinct_products': 0,
          'subtotal': 0,
        },
      };
      _infoMessage = 'Carrito vaciado.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      notifyListeners();
      return false;
    } finally {
      _finishMutation();
    }
  }

  /// Borra mensajes temporales mostrados por la UI.
  void clearMessages() {
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  /// Inicia una mutacion del carrito.
  void _startMutation() {
    _isSaving = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  /// Finaliza una mutacion del carrito.
  void _finishMutation() {
    _isSaving = false;
    notifyListeners();
  }

  /// Convierte errores del servicio a texto apto para UI.
  String _errorToText(Object error) {
    if (error is CartApiException) {
      return error.message;
    }
    return 'No se pudo actualizar el carrito.';
  }

  /// Interpreta enteros incluso si llegan serializados como texto.
  int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  /// Interpreta numeros desde contratos JSON heterogeneos.
  num? _asNum(dynamic raw) {
    if (raw is num) return raw;
    return num.tryParse((raw ?? '').toString().trim());
  }
}
