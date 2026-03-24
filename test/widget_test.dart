import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:grocerysaver/domain/entities/app_models.dart';
import 'package:grocerysaver/domain/repositories/app_repositories.dart';
import 'package:grocerysaver/presentation/providers/app_providers.dart';
import 'package:grocerysaver/presentation/screens/auth/login_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession?> loginWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> loginWithGoogleIdToken(String idToken) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> register({required String firstName, required String lastName, required String email, required String password, required String confirmPassword, required String address, required String birthDate}) async {}

  @override
  Future<AppUser?> restoreUser() async => null;
}

void main() {
  testWidgets('renderiza login base', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(_FakeAuthRepository()),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
