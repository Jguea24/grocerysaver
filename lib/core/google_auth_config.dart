import 'package:flutter/foundation.dart';

class GoogleAuthConfig {
  const GoogleAuthConfig._();

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String? get clientIdOrNull {
    final value = kIsWeb ? webClientId : '';
    return value.trim().isEmpty ? null : value.trim();
  }

  static String? get serverClientIdOrNull {
    final value = serverClientId.trim();
    return value.isEmpty ? null : value;
  }

  static void validate() {
    if (kIsWeb && webClientId.trim().isEmpty) {
      throw StateError(
        'Falta GOOGLE_WEB_CLIENT_ID. Ejecuta Flutter con --dart-define=GOOGLE_WEB_CLIENT_ID=tu_client_id.apps.googleusercontent.com',
      );
    }
  }
}
