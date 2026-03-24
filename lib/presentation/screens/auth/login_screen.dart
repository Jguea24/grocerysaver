import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/google_auth_service.dart';
import '../../providers/app_providers.dart';
import 'auth_ui.dart';
import 'google_web_sign_in_button_stub.dart'
    if (dart.library.html) 'google_web_sign_in_button_web.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<String>? _googleIdTokenSubscription;
  bool _googleListenerAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_googleListenerAttached || !kIsWeb) return;
    _googleListenerAttached = true;
    final googleAuthService = context.read<GoogleAuthService>();
    _googleIdTokenSubscription = googleAuthService.idTokenChanges.listen((idToken) async {
      if (!mounted) return;
      final provider = context.read<AuthProvider>();
      final navigator = Navigator.of(context);
      final success = await provider.loginWithGoogleIdToken(idToken);
      if (!mounted || !success) return;
      navigator.pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
    });
  }

  @override
  void dispose() {
    _googleIdTokenSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.loginWithGoogle();
    if (!mounted || !success) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final success = await provider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted || !success) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AuthGradientScaffold(
          child: ListView(
            children: [
              const SizedBox(height: 20),
              AuthCard(
                logo: Image.asset(
                  'assets/images/logo_grocesy.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.lock_person_rounded,
                      color: Colors.white,
                      size: 42,
                    );
                  },
                ),
                title: 'Iniciar sesion',
                subtitle: '',
                footer: AuthSecondaryLink(
                  label: 'No tienes cuenta?',
                  actionText: 'Crear cuenta',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (auth.errorMessage != null) ...[
                        _AuthErrorBox(message: auth.errorMessage!),
                        const SizedBox(height: 18),
                      ],
                      AuthField(
                        label: 'Correo electronico',
                        hintText: 'Ingresa tu correo',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            (value ?? '').contains('@') ? null : 'Ingresa un correo valido',
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Contrasena',
                        hintText: 'Ingresa tu contrasena',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) =>
                            (value ?? '').length >= 6 ? null : 'Minimo 6 caracteres',
                      ),
                      const SizedBox(height: 22),
                      AuthPrimaryButton(
                        label: auth.isSubmitting ? 'Ingresando...' : 'Entrar',
                        onPressed: auth.isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: 22),
                      const AuthDividerLabel(label: 'O continua con'),
                      const SizedBox(height: 18),
                      if (kIsWeb) ...[
                        const GoogleWebSignInButton(),
                        const SizedBox(height: 18),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AuthSocialButton(
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Inicio con Facebook aun no implementado')),
                              ),
                              child: const Icon(
                                Icons.facebook_rounded,
                                color: Color(0xFF1877F2),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 18),
                            AuthSocialButton(
                              onTap: auth.isSubmitting ? () {} : _loginWithGoogle,
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFFDB4437),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            AuthSocialButton(
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Inicio con Apple aun no implementado')),
                              ),
                              child: const Icon(
                                Icons.apple_rounded,
                                color: Color(0xFF111111),
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthErrorBox extends StatelessWidget {
  const _AuthErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3BDD0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB1305D),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
