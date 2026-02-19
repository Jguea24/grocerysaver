import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  // Puedes sobreescribir con:
  // Navegador:
  // flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
  // Android emulador:
  // flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8000/api';
    }
  }
}
