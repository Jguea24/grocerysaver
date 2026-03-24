import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/entities/app_models.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Set<int> _shownIds = <int>{};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  Future<void> notifyExpiringInventory(List<InventoryItem> items) async {
    if (!_initialized || kIsWeb) return;

    final now = DateTime.now();
    for (final item in items) {
      final expiresAt = DateTime.tryParse(item.expiresAt);
      if (expiresAt == null) continue;
      final daysLeft = expiresAt.difference(now).inDays;
      if (daysLeft < 0 || daysLeft > 3) continue;
      if (_shownIds.contains(item.id)) continue;

      await _plugin.show(
        _safeId(item.id),
        'Producto por caducar',
        '${item.product.name} vence en ${max(daysLeft, 0)} dia(s).',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'inventory_expiry',
            'Caducidad de inventario',
            channelDescription: 'Alertas para productos del hogar proximos a caducar.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
      _shownIds.add(item.id);
    }
  }

  int _safeId(int value) => value.abs() % 2147483647;
}
