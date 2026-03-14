// Estado de perfil, direcciones, notificaciones y rifas.
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_api.dart';

/// ViewModel que prepara datos del perfil para la pantalla `ProfileView`.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required ProfileApi api}) : _api = api;

  final ProfileApi _api;

  bool _isLoading = false;
  bool _isSavingNotifications = false;
  bool _isUpdatingAvatar = false;
  int _avatarRevision = 0;
  String? _errorMessage;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _addresses = const [];
  Map<String, dynamic> _notificationPrefs = const {};
  List<Map<String, dynamic>> _raffles = const [];
  List<Map<String, dynamic>> _roleRequests = const [];

  bool get isLoading => _isLoading;
  bool get isSavingNotifications => _isSavingNotifications;
  bool get isUpdatingAvatar => _isUpdatingAvatar;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  List<Map<String, dynamic>> get addresses => _addresses;
  Map<String, dynamic> get notificationPrefs => _notificationPrefs;
  List<Map<String, dynamic>> get raffles => _raffles;
  List<Map<String, dynamic>> get roleRequests => _roleRequests;

  /// Carga todas las secciones del perfil en paralelo.
  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getMe(),
        _api.getAddresses(),
        _api.getNotificationPrefs(),
        _api.getActiveRaffles(),
        _api.getRoleChangeRequests(),
      ]);
      _user = results[0] as Map<String, dynamic>;
      _addresses = _toMapList(results[1]);
      _notificationPrefs = _toMap(results[2]);
      _raffles = _toMapList(results[3]);
      _roleRequests = _toMapList(results[4]);
      _touchAvatarRevision();
    } catch (e) {
      _errorMessage = _errorToText(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fuerza una recarga completa del perfil.
  Future<void> refresh() async {
    await loadAll();
  }

  /// Actualiza una preferencia localmente y revierte si el backend falla.
  Future<void> setNotificationPref(String key, bool value) async {
    if (key.trim().isEmpty) return;
    final previous = Map<String, dynamic>.from(_notificationPrefs);
    _notificationPrefs = {..._notificationPrefs, key: value};
    _isSavingNotifications = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _notificationPrefs = await _api.updateNotificationPrefs(
        _notificationPrefs,
      );
    } catch (e) {
      _notificationPrefs = previous;
      _errorMessage = _errorToText(e);
    } finally {
      _isSavingNotifications = false;
      notifyListeners();
    }
  }

  /// Envia una solicitud de cambio de rol y la agrega al estado visible.
  Future<bool> requestRoleChange({
    required String role,
    String reason = '',
  }) async {
    try {
      final request = await _api.createRoleChangeRequest(role, reason: reason);
      _roleRequests = [request, ..._roleRequests];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      notifyListeners();
      return false;
    }
  }

  /// Devuelve un nombre de usuario presentable.
  String displayName() {
    final raw =
        _user?['username'] ??
        _user?['full_name'] ??
        '${_user?['first_name'] ?? ''} ${_user?['last_name'] ?? ''}';
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Usuario' : text;
  }

  /// Devuelve el correo principal o un fallback util.
  String email() {
    final text = (_user?['email'] ?? '').toString().trim();
    return text.isEmpty ? 'Sin correo' : text;
  }

  /// Devuelve la puntuacion media del usuario.
  double rating() {
    final raw = _user?['rating'] ?? _user?['average_rating'];
    if (raw is num) return raw.toDouble();
    return double.tryParse((raw ?? '').toString()) ?? 5.0;
  }

  /// Devuelve el numero de resenas del usuario.
  int reviewsCount() {
    final raw = _user?['reviews_count'] ?? _user?['reviews'];
    if (raw is int) return raw;
    return int.tryParse((raw ?? '').toString()) ?? 0;
  }

  /// Devuelve la URL del avatar en formato absoluto cuando existe.
  String? avatarUrl() {
    final raw = (_user?['avatar'] ?? '').toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }

    final uri = Uri.tryParse(raw);
    final resolved = uri != null && uri.hasScheme
        ? uri
        : Uri.parse(_api.baseUrl).resolve(raw);
    return resolved.replace(
      queryParameters: {
        ...resolved.queryParameters,
        'v': _avatarRevision.toString(),
      },
    ).toString();
  }

  /// Sube un nuevo avatar y actualiza el usuario visible.
  Future<bool> uploadAvatar(XFile file) async {
    _isUpdatingAvatar = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final avatar = await _api.uploadAvatar(file);
      _user = {...?_user, 'avatar': avatar};
      _touchAvatarRevision();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      return false;
    } finally {
      _isUpdatingAvatar = false;
      notifyListeners();
    }
  }

  /// Elimina el avatar actual y limpia el estado local.
  Future<bool> deleteAvatar() async {
    _isUpdatingAvatar = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.deleteAvatar();
      _user = {...?_user, 'avatar': null};
      _touchAvatarRevision();
      return true;
    } catch (e) {
      _errorMessage = _errorToText(e);
      return false;
    } finally {
      _isUpdatingAvatar = false;
      notifyListeners();
    }
  }

  /// Entrega las claves de preferencias ya ordenadas para la UI.
  List<String> notificationKeys() {
    final keys = _notificationPrefs.keys.map((key) => key.toString()).toList();
    keys.sort();
    return keys;
  }

  /// Interpreta flags de notificacion aunque lleguen como texto.
  bool notificationValue(String key) {
    final value = _notificationPrefs[key];
    if (value is bool) return value;
    final text = (value ?? '').toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  /// Convierte listas dinamicas del backend a listas de mapas seguras.
  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  /// Convierte mapas dinamicos a una estructura segura.
  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return const {};
  }

  /// Cambia la revision local para invalidar cache de imagen.
  void _touchAvatarRevision() {
    _avatarRevision = DateTime.now().millisecondsSinceEpoch;
  }

  /// Traduce fallos del servicio a texto para la interfaz.
  String _errorToText(Object error) {
    if (error is ProfileApiException) return error.message;
    if (error is FormatException) return error.message;
    final text = error.toString().trim();
    if (text.isNotEmpty) {
      return text.startsWith('Exception: ')
          ? text.substring('Exception: '.length)
          : text;
    }
    return 'No se pudo cargar el perfil.';
  }
}
