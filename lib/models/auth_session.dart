// Modelo simple para conservar el estado autenticado del usuario actual.
class AuthSession {
  const AuthSession({
    required this.email,
    required this.accessToken,
    this.refreshToken,
    this.username,
    this.role,
  });

  final String email;
  final String accessToken;
  final String? refreshToken;
  final String? username;
  final String? role;

  /// Construye la sesion a partir de la respuesta estandar del login.
  factory AuthSession.fromLoginResponse(
    Map<String, dynamic> data, {
    String fallbackEmail = '',
  }) {
    final tokens = _tokensFrom(data);
    if (tokens == null) {
      throw const FormatException('La respuesta no contiene "tokens".');
    }

    final accessToken = (tokens['access'] ?? '').toString();
    if (accessToken.isEmpty) {
      throw const FormatException('La respuesta no contiene access token.');
    }

    final refreshToken = tokens['refresh']?.toString();

    String email = fallbackEmail;
    String? username;
    String? role;
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      if (user['email'] != null) {
        email = user['email'].toString();
      }
      if (user['username'] != null) {
        username = user['username'].toString();
      }
      if (user['role'] != null) {
        role = user['role'].toString();
      }
    } else if (data['email'] != null) {
      email = data['email'].toString();
    }

    return AuthSession(
      email: email,
      accessToken: accessToken,
      refreshToken: refreshToken,
      username: username,
      role: role,
    );
  }

  static Map<String, dynamic>? _tokensFrom(Map<String, dynamic> data) {
    final nested = data['tokens'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }

    final access = data['access'];
    final refresh = data['refresh'];
    if (access != null || refresh != null) {
      return {
        'access': access,
        'refresh': refresh,
      };
    }
    return null;
  }
}
