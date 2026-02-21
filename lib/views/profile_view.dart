import 'package:flutter/material.dart';

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
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(api: ProfileApi(ApiConfig.baseUrl));
    _viewModel.loadAll();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F1F5),
          appBar: AppBar(
            title: const Text(
              'Mi Perfil',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: _viewModel.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (_viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ErrorBanner(message: _viewModel.errorMessage!),
                  ),
                _UserCard(
                  name: _viewModel.displayName(),
                  email: _viewModel.email(),
                ),
                const SizedBox(height: 12),
                _RatingCard(
                  rating: _viewModel.rating(),
                  reviewsCount: _viewModel.reviewsCount(),
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'CUENTA'),
                const SizedBox(height: 8),
                _GroupCard(
                  children: [
                    _MenuRow(
                      color: const Color(0xFF5AC1F6),
                      icon: Icons.person_rounded,
                      title: 'Informacion del perfil',
                      onTap: _showUserData,
                    ),
                    _MenuRow(
                      color: const Color(0xFF34C759),
                      icon: Icons.location_on_rounded,
                      title: 'Mis direcciones',
                      subtitle:
                          '${_viewModel.addresses.length} direcciones guardadas',
                      onTap: _showAddresses,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'PREFERENCIAS'),
                const SizedBox(height: 8),
                _GroupCard(
                  children: [
                    _MenuRow(
                      color: const Color(0xFFFF3B30),
                      icon: Icons.notifications_rounded,
                      title: 'Notificaciones',
                      subtitle: _viewModel.notificationKeys().isEmpty
                          ? 'Sin preferencias cargadas'
                          : '${_viewModel.notificationKeys().length} ajustes',
                      onTap: _showNotificationPrefs,
                    ),
                    const _MenuRow(
                      color: Color(0xFF007AFF),
                      icon: Icons.language_rounded,
                      title: 'Idioma',
                      subtitle: 'Espanol',
                    ),
                    _SwitchRow(
                      color: const Color(0xFFFFCC00),
                      icon: Icons.light_mode_rounded,
                      title: 'Modo oscuro',
                      value: _darkMode,
                      onChanged: (value) => setState(() => _darkMode = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'RIFAS Y PROMOCIONES'),
                const SizedBox(height: 8),
                _GroupCard(
                  children: [
                    _MenuRow(
                      color: const Color(0xFFFFA500),
                      icon: Icons.confirmation_number_rounded,
                      title: 'Rifas activas',
                      subtitle: '${_viewModel.raffles.length} activas',
                      onTap: _showRaffles,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'SOLICITUDES'),
                const SizedBox(height: 8),
                _GroupCard(
                  children: [
                    _MenuRow(
                      color: const Color(0xFFAF52DE),
                      icon: Icons.swap_horiz_rounded,
                      title: 'Solicitar cambio de rol',
                      subtitle: 'Solicita ser proveedor o repartidor',
                      onTap: _showRoleRequestDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'SEGURIDAD'),
                const SizedBox(height: 8),
                const _GroupCard(
                  children: [
                    _MenuRow(
                      color: Color(0xFF5AC8FA),
                      icon: Icons.lock_rounded,
                      title: 'Cambiar contrasena',
                      subtitle: 'Actualiza tu clave de acceso',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'SOPORTE'),
                const SizedBox(height: 8),
                const _GroupCard(
                  children: [
                    _MenuRow(
                      color: Color(0xFF5856D6),
                      icon: Icons.help_rounded,
                      title: 'Ayuda y soporte',
                    ),
                    _MenuRow(
                      color: Color(0xFF8E8E93),
                      icon: Icons.article_rounded,
                      title: 'Terminos y condiciones',
                    ),
                    _MenuRow(
                      color: Color(0xFF0A84FF),
                      icon: Icons.privacy_tip_rounded,
                      title: 'Politica de privacidad',
                    ),
                  ],
                ),
                if (_viewModel.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUserData() {
    final user = _viewModel.user ?? const {};
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _SimpleListSheet(
        title: 'Informacion del perfil',
        lines: user.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .toList(growable: false),
      ),
    );
  }

  void _showAddresses() {
    final addresses = _viewModel.addresses;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _SimpleListSheet(
        title: 'Mis direcciones',
        lines: addresses.isEmpty
            ? const ['Sin direcciones registradas']
            : addresses
                  .map(
                    (item) =>
                        item['address']?.toString() ??
                        item['label']?.toString() ??
                        item.toString(),
                  )
                  .toList(growable: false),
      ),
    );
  }

  void _showRaffles() {
    final raffles = _viewModel.raffles;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _SimpleListSheet(
        title: 'Rifas activas',
        lines: raffles.isEmpty
            ? const ['No hay rifas activas']
            : raffles
                  .map(
                    (item) =>
                        item['title']?.toString() ??
                        item['name']?.toString() ??
                        item.toString(),
                  )
                  .toList(growable: false),
      ),
    );
  }

  Future<void> _showNotificationPrefs() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final keys = _viewModel.notificationKeys();
        if (keys.isEmpty) {
          return const _SimpleListSheet(
            title: 'Notificaciones',
            lines: ['No hay preferencias disponibles'],
          );
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  const Text(
                    'Notificaciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...keys.map(
                    (key) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_formatPrefLabel(key)),
                      value: _viewModel.notificationValue(key),
                      onChanged: _viewModel.isSavingNotifications
                          ? null
                          : (value) async {
                              await _viewModel.setNotificationPref(key, value);
                              if (context.mounted) {
                                setModalState(() {});
                              }
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRoleRequestDialog() async {
    final roleController = TextEditingController(text: 'proveedor');
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Solicitar cambio de rol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Rol solicitado'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Motivo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    final sent = await _viewModel.requestRoleChange(
      role: roleController.text.trim(),
      reason: reasonController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent ? 'Solicitud enviada.' : (_viewModel.errorMessage ?? 'Error'),
        ),
      ),
    );
  }

  String _formatPrefLabel(String raw) {
    final text = raw.replaceAll('_', ' ').trim();
    if (text.isEmpty) return raw;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF35B6EA), width: 2.5),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              size: 46,
              color: Color(0xFF9BA7B4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111316),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8D9197),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating, required this.reviewsCount});

  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF7B500),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$reviewsCount reseñas',
            style: const TextStyle(
              color: Color(0xFF8D9197),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF8E8E93),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF13171D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final Color color;
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Modo oscuro',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF13171D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SimpleListSheet extends StatelessWidget {
  const _SimpleListSheet({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: const TextStyle(color: Color(0xFF2D3D49), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
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
    );
  }
}
