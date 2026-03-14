// Resolucion de la URL base de la API segun plataforma o variables de entorno.
import 'package:flutter/foundation.dart';

/// Centraliza la configuracion de conectividad para todos los servicios HTTP.
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

  /// Devuelve la URL activa priorizando `API_BASE_URL` cuando esta definida.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
      return '${Uri.base.scheme}://$host:8000/api';
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

  /// Devuelve el origen publico del backend sin el sufijo `/api`.
  static Uri get backendOrigin {
    final uri = Uri.parse(baseUrl);
    final path = uri.path.endsWith('/api')
        ? uri.path.substring(0, uri.path.length - 4)
        : uri.path;
    return uri.replace(path: path, query: null, fragment: null);
  }

  /// Reescribe URLs del backend para que sean accesibles desde la plataforma actual.
  static String resolveBackendUrl(String rawUrl) {
    final text = rawUrl.trim();
    if (text.isEmpty) return text;

    final uri = Uri.tryParse(text);
    if (uri == null) return text;
    if (!uri.hasScheme) {
      return backendOrigin.resolveUri(uri).toString();
    }

    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      final origin = backendOrigin;
      return uri.replace(
        scheme: origin.scheme,
        host: origin.host,
        port: origin.hasPort ? origin.port : null,
      ).toString();
    }

    return uri.toString();
  }
}
