import 'package:flutter/material.dart';

import 'app/grocery_saver_app.dart';
import 'core/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.initialize();
  runApp(const GrocerySaverApp());
}

