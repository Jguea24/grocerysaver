import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../services/auth_api.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthApi api}) : _api = api;

  final AuthApi _api;

  bool _isLoading = false;
  bool _isLoadingRoles = false;
  bool _isLoadingProtected = false;
  String? _errorMessage;
  String? _infoMessage;
  AuthSession? _session;
  List<String> _roles = const ['cliente', 'admin'];
  String _selectedRole = 'cliente';
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _adminOnlyData;

  bool get isLoading => _isLoading;
  bool get isLoadingRoles => _isLoadingRoles;
  bool get isLoadingProtected => _isLoadingProtected;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null;
  List<String> get roles => List.unmodifiable(_roles);
  String get selectedRole => _selectedRole;
  Map<String, dynamic>? get profileData => _profileData;
  Map<String, dynamic>? get adminOnlyData => _adminOnlyData;

  Future<void> loadRoles() async {
    _isLoadingRoles = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final fetched = await _api.getRoles();
      if (fetched.isNotEmpty) {
        _roles = fetched;
      }
      if (!_roles.contains(_selectedRole)) {
        _selectedRole = _roles.first;
      }
    } catch (e) {
      _errorMessage = _errorToText(e);
    } finally {
      _isLoadingRoles = false;
      notifyListeners();
    }
  }

  void selectRole(String? role) {
    if (role == null || role == _selectedRole) {
      return;
    }
    _selectedRole = role;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _startRequest();
    try {
      final data = await _api.login(email: email, password: password);
      _session = AuthSession.fromLoginResponse(data, fallbackEmail: email);
      if (data['user'] is Map<String, dynamic>) {
        _profileData = data['user'] as Map<String, dynamic>;
      }
      _infoMessage = 'Sesion iniciada correctamente.';
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      return false;
    } finally {
      _finishRequest();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    required String firstName,
    required String lastName,
    required String address,
    required String birthDate,
  }) async {
    _startRequest();
    try {
      final data = await _api.register(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        role: role,
        firstName: firstName,
        lastName: lastName,
        address: address,
        birthDate: birthDate,
      );

      final debugToken = data['verification_token_debug']?.toString();
      if (debugToken != null && debugToken.isNotEmpty) {
        await _api.verifyEmail(debugToken);
        _infoMessage = 'Registro exitoso y correo verificado en modo debug.';
      } else {
        _infoMessage =
            'Registro exitoso. Revisa tu correo para verificar tu cuenta.';
      }
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      return false;
    } finally {
      _finishRequest();
    }
  }

  Future<bool> loadMe() async {
    _isLoadingProtected = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _profileData = await _api.me();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      return false;
    } finally {
      _isLoadingProtected = false;
      notifyListeners();
    }
  }

  Future<bool> loadAdminOnly() async {
    _isLoadingProtected = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _adminOnlyData = await _api.adminOnly();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      return false;
    } finally {
      _isLoadingProtected = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      await _api.clearTokens();
    }
    _session = null;
    _profileData = null;
    _adminOnlyData = null;
    _errorMessage = null;
    _infoMessage = 'Sesion cerrada.';
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  void _startRequest() {
    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  void _finishRequest() {
    _isLoading = false;
    notifyListeners();
  }

  String _errorToText(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Ocurrio un error inesperado.';
  }
}
