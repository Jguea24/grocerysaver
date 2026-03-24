import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_config.dart';
import '../services/profile_api.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _seeded = false;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(api: ProfileApi(ApiConfig.baseUrl));
    _viewModel.loadAll();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _seedControllers() {
    if (_seeded || _viewModel.user == null) return;
    final user = _viewModel.user!;
    _firstNameController.text = (user['first_name'] ?? '').toString();
    _lastNameController.text = (user['last_name'] ?? '').toString();
    _birthDateController.text = _readBirthDate(user);
    _emailController.text = _viewModel.email();
    _phoneController.text = _readPhone(user);
    _seeded = true;
  }

  String _readBirthDate(Map<String, dynamic> user) {
    final raw = (user['birth_date'] ?? user['date_of_birth'] ?? '').toString().trim();
    if (raw.isEmpty) return '01/01/2000';
    if (raw.contains('-')) {
      final parts = raw.split('T').first.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }
    return raw;
  }

  String _readPhone(Map<String, dynamic> user) {
    final raw = (user['phone'] ?? user['phone_number'] ?? user['whatsapp'] ?? '').toString().trim();
    return raw.isEmpty ? '989894312' : raw;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked == null) return;
    _birthDateController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    setState(() {});
  }

  Future<void> _pickAndUploadAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final ok = await _viewModel.uploadAvatar(file);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Foto de perfil actualizada.'
              : (_viewModel.errorMessage ?? 'No se pudo actualizar la foto.'),
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSavingDraft = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _isSavingDraft = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados en esta sesion.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        _seedControllers();
        final user = _viewModel.user ?? const <String, dynamic>{};
        final email = _viewModel.email();
        _emailController.text = email;
        final avatarUrl = _viewModel.avatarUrl();

        if (_viewModel.isLoading && _viewModel.user == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F4F8),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F8),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF4F4F8),
            surfaceTintColor: const Color(0xFFF4F4F8),
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            centerTitle: true,
            title: const Text(
              'Editar Perfil',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              TextButton(
                onPressed: _isSavingDraft ? null : _saveDraft,
                child: Text(
                  _isSavingDraft ? 'Guardando...' : 'Guardar',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _viewModel.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  if (_viewModel.errorMessage != null)
                    _ProfileErrorBanner(message: _viewModel.errorMessage!),
                  const SizedBox(height: 4),
                  Center(
                    child: Column(
                      children: [
                        _AvatarCircle(
                          name: _viewModel.displayName(),
                          avatarUrl: avatarUrl,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _viewModel.isUpdatingAvatar ? null : _pickAndUploadAvatar,
                          child: Text(
                            _viewModel.isUpdatingAvatar ? 'Subiendo foto...' : 'Cambiar foto de perfil',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionLabel(title: 'DATOS PERSONALES'),
                  const SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _ProfileField(
                          label: 'Nombre',
                          controller: _firstNameController,
                          validator: (value) =>
                              (value ?? '').trim().isEmpty ? 'Ingresa tu nombre.' : null,
                        ),
                        const SizedBox(height: 14),
                        _ProfileField(
                          label: 'Apellido',
                          controller: _lastNameController,
                          validator: (value) =>
                              (value ?? '').trim().isEmpty ? 'Ingresa tu apellido.' : null,
                        ),
                        const SizedBox(height: 14),
                        _ProfileField(
                          label: 'Fecha de Nacimiento',
                          controller: _birthDateController,
                          readOnly: true,
                          onTap: _pickBirthDate,
                          suffixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1D9BF0)),
                          validator: (value) =>
                              (value ?? '').trim().isEmpty ? 'Selecciona una fecha.' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionLabel(title: 'INFORMACION DE CONTACTO'),
                  const SizedBox(height: 10),
                  _ProfileField(
                    label: 'Correo Electronico',
                    controller: _emailController,
                    enabled: false,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'El correo no puede ser modificado por seguridad.',
                    style: TextStyle(
                      color: Color(0xFF9C9CA6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PhoneField(controller: _phoneController),
                  const SizedBox(height: 20),
                  _ProfileInfoCard(
                    title: 'Cuenta actual',
                    value: (_viewModel.displayName()).trim().isEmpty
                        ? 'Usuario'
                        : _viewModel.displayName(),
                    subtitle: 'Correo: $email',
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    title: 'Direcciones guardadas',
                    value: '${_viewModel.addresses.length}',
                    subtitle: _viewModel.addresses.isEmpty
                        ? 'No tienes direcciones registradas'
                        : 'Tienes direcciones disponibles para checkout',
                  ),
                  if (user.isNotEmpty) const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE7F5), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl == null
          ? Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF68738A),
                ),
              ),
            )
          : Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF68738A),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF8E8E93),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF0F0F4),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF1D9BF0)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Telefono / WhatsApp',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E0E6)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text(
                  '🇪🇨  +593',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '987654321',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF676D7A)),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorBanner extends StatelessWidget {
  const _ProfileErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFAC2E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
