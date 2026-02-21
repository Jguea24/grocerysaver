import 'package:flutter/foundation.dart';

import '../services/profile_api.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required ProfileApi api}) : _api = api;

  final ProfileApi _api;

  bool _isLoading = false;
  bool _isSavingNotifications = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _addresses = const [];
  Map<String, dynamic> _notificationPrefs = const {};
  List<Map<String, dynamic>> _raffles = const [];
  List<Map<String, dynamic>> _roleRequests = const [];

  bool get isLoading => _isLoading;
  bool get isSavingNotifications => _isSavingNotifications;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  List<Map<String, dynamic>> get addresses => _addresses;
  Map<String, dynamic> get notificationPrefs => _notificationPrefs;
  List<Map<String, dynamic>> get raffles => _raffles;
  List<Map<String, dynamic>> get roleRequests => _roleRequests;

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
    } catch (e) {
      _errorMessage = _errorToText(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadAll();
  }

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

  String displayName() {
    final raw =
        _user?['username'] ??
        _user?['full_name'] ??
        '${_user?['first_name'] ?? ''} ${_user?['last_name'] ?? ''}';
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Usuario' : text;
  }

  String email() {
    final text = (_user?['email'] ?? '').toString().trim();
    return text.isEmpty ? 'Sin correo' : text;
  }

  double rating() {
    final raw = _user?['rating'] ?? _user?['average_rating'];
    if (raw is num) return raw.toDouble();
    return double.tryParse((raw ?? '').toString()) ?? 5.0;
  }

  int reviewsCount() {
    final raw = _user?['reviews_count'] ?? _user?['reviews'];
    if (raw is int) return raw;
    return int.tryParse((raw ?? '').toString()) ?? 0;
  }

  List<String> notificationKeys() {
    final keys = _notificationPrefs.keys.map((key) => key.toString()).toList();
    keys.sort();
    return keys;
  }

  bool notificationValue(String key) {
    final value = _notificationPrefs[key];
    if (value is bool) return value;
    final text = (value ?? '').toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return const {};
  }

  String _errorToText(Object error) {
    if (error is ProfileApiException) return error.message;
    return 'No se pudo cargar el perfil.';
  }
}
