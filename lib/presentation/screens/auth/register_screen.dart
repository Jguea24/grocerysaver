import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../providers/app_providers.dart';
import 'auth_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _addressController = TextEditingController(text: '');
  final _birthDateController = TextEditingController(text: '');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios del registro')),
      );
      return;
    }
    final provider = context.read<AuthProvider>();
    final success = await provider.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
      address: _addressController.text.trim(),
      birthDate: _birthDateController.text.trim(),
    );
    if (!mounted) return;
    if (!success) {
      final message = provider.errorMessage;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada. Revisa tu correo y verificalo antes de iniciar sesion.'),
      ),
    );
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AuthGradientScaffold(
          showBack: true,
          child: ListView(
            children: [
              Text(
                'Crea tu cuenta',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Registrate para guardar tu inventario, recibir alertas y organizar tu lista de compras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF4EFFF),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              AuthCard(
                logo: Image.asset(
                  'assets/images/logo_grocesy.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 42,
                    );
                  },
                ),
                title: 'Registro',
                subtitle: 'Completa tus datos basicos para conectar tu cuenta.',
                footer: AuthSecondaryLink(
                  label: 'Ya tienes cuenta?',
                  actionText: 'Iniciar sesion',
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
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
                        label: 'Nombre',
                        hintText: 'Ingresa tu nombre',
                        icon: Icons.person_outline_rounded,
                        controller: _firstNameController,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Ingresa tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Apellido',
                        hintText: 'Ingresa tu apellido',
                        icon: Icons.badge_outlined,
                        controller: _lastNameController,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Ingresa tu apellido'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Correo electronico',
                        hintText: 'Ingresa tu correo',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value ?? '').contains('@')
                            ? null
                            : 'Ingresa un correo valido',
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Contrasena',
                        hintText: 'Crea una contrasena',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) => (value ?? '').length >= 8
                            ? null
                            : 'Minimo 8 caracteres',
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Confirmar contrasena',
                        hintText: 'Repite tu contrasena',
                        icon: Icons.verified_user_outlined,
                        controller: _confirmController,
                        obscureText: true,
                        validator: (value) => value == _passwordController.text
                            ? null
                            : 'Las contrasenas no coinciden',
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Direccion',
                        hintText: 'Ingresa tu direccion',
                        icon: Icons.location_on_outlined,
                        controller: _addressController,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Ingresa una direccion'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Fecha de nacimiento',
                        hintText: '1995-01-01',
                        icon: Icons.calendar_month_outlined,
                        controller: _birthDateController,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Ingresa una fecha'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: auth.isSubmitting ? 'Registrando...' : 'Crear cuenta',
                        onPressed: auth.isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: 22),
                      const AuthDividerLabel(label: 'Beneficios al registrarte'),
                      const SizedBox(height: 18),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          AuthGhostChip(
                            icon: Icons.notifications_active_outlined,
                            label: 'Alertas',
                          ),
                          AuthGhostChip(
                            icon: Icons.shopping_cart_checkout_rounded,
                            label: 'Compras',
                          ),
                        ],
                      ),
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
