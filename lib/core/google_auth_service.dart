import 'package:google_sign_in/google_sign_in.dart';

import 'google_auth_config.dart';

class GoogleAuthPayload {
  const GoogleAuthPayload({required this.idToken});

  final String idToken;
}

class GoogleAuthService {
  GoogleAuthService()
    : _googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile', 'openid'],
        clientId: GoogleAuthConfig.clientIdOrNull,
        serverClientId: GoogleAuthConfig.serverClientIdOrNull,
      );

  final GoogleSignIn _googleSignIn;

  Stream<String> get idTokenChanges async* {
    await for (final account in _googleSignIn.onCurrentUserChanged) {
      if (account == null) continue;
      final auth = await account.authentication;
      final idToken = auth.idToken?.trim() ?? '';
      if (idToken.isNotEmpty) {
        yield idToken;
      }
    }
  }

  Future<GoogleAuthPayload?> signIn() async {
    GoogleAuthConfig.validate();
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken?.trim() ?? '';
    if (idToken.isEmpty) {
      throw StateError('Google no devolvio id_token. En web usa el boton oficial de Google.');
    }

    return GoogleAuthPayload(idToken: idToken);
  }

  Future<void> signOut() {
    return _googleSignIn.signOut();
  }
}
