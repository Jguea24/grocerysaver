// Pantalla de registro con datos extendidos del usuario.
import 'package:flutter/material.dart';

import '../components/app_backdrop.dart';
import '../components/auth_logo.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Formulario de alta de usuario conectado al `AuthViewModel`.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Abre el selector nativo de fechas y guarda el resultado en texto.
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selected == null) {
      return;
    }

    _birthDateController.text = _formatDate(selected);
  }

  /// Formatea la fecha al contrato esperado por el backend.
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Valida y envia el formulario de registro.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await widget.viewModel.register(
      username: _buildUsername(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
      role: widget.viewModel.selectedRole,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      address: _addressController.text.trim(),
      birthDate: _birthDateController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      Navigator.pop(context);
    }
  }

  /// Genera un username estable para backends que aun lo requieren.
  String _buildUsername() {
    final first = _firstNameController.text.trim().toLowerCase();
    final last = _lastNameController.text.trim().toLowerCase();
    final email = _emailController.text.trim().toLowerCase();

    final seed = [first, last].where((part) => part.isNotEmpty).join('.');
    final fallback = email.split('@').first.trim();
    final raw = seed.isNotEmpty ? seed : fallback;
    final normalized = raw.replaceAll(RegExp(r'[^a-z0-9._]'), '');

    if (normalized.isNotEmpty) {
      return normalized;
    }
    return 'usuario${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        maxWidth: 460,
        child: AnimatedBuilder(
          animation: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: vm.isLoading
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const AuthLogo(size: 80, showSubtitle: false),
                      const SizedBox(height: 14),
                      Text(
                        'Crear cuenta',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E5338),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Configura tu perfil para comenzar a comparar precios.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF557865),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Ingresa tu nombre.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Ingresa tu apellido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Direccion',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Ingresa tu direccion.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _birthDateController,
                        readOnly: true,
                        onTap: _pickBirthDate,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento (YYYY-MM-DD)',
                          suffixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return 'Selecciona tu fecha de nacimiento.';
                          }
                          final isValid = RegExp(
                            r'^\d{4}-\d{2}-\d{2}$',
                          ).hasMatch(text);
                          if (!isValid) {
                            return 'Formato invalido. Usa YYYY-MM-DD.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Ingresa tu correo.';
                          if (!text.contains('@')) return 'Correo invalido.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Contrasena',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final text = value ?? '';
                          if (text.length < 8) {
                            return 'Minimo 8 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contrasena',
                          prefixIcon: const Icon(Icons.shield_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '') != _passwordController.text) {
                            return 'Las contrasenas no coinciden.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: vm.infoMessage == null
                            ? const SizedBox.shrink()
                            : Container(
                                key: ValueKey(vm.infoMessage),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F7EF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  vm.infoMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF1E7B4D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                      if (vm.infoMessage != null) const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: vm.errorMessage == null
                            ? const SizedBox.shrink()
                            : Container(
                                key: ValueKey(vm.errorMessage),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCEAEA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  vm.errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFAC2E2E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: vm.isLoading ? null : _submit,
                        child: vm.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Registrarme'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
