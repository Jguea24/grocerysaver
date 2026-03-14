// Pantalla de perfil con secciones de cuenta, preferencias y solicitudes.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_config.dart';
import '../services/profile_api.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'export_jobs_view.dart';

/// Muestra la informacion agregada del perfil autenticado.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;
  final ImagePicker _picker = ImagePicker();
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
                  avatarUrl: _viewModel.avatarUrl(),
                  isUpdatingAvatar: _viewModel.isUpdatingAvatar,
                  onAvatarTap: _showAvatarActions,
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
                    _MenuRow(
                      color: const Color(0xFF2F7D57),
                      icon: Icons.file_download_rounded,
                      title: 'Exportar productos',
                      subtitle: 'Encola el CSV y consulta el estado',
                      onTap: _openExportJobs,
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

  /// Muestra el mapa crudo del usuario para depuracion ligera.
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

  /// Muestra las direcciones registradas en una hoja inferior.
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

  /// Muestra las rifas activas disponibles para el usuario.
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

  /// Abre un modal editable para cambiar preferencias de notificacion.
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

  /// Solicita al usuario el rol y motivo para crear una peticion.
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

  /// Abre la vista dedicada al flujo de exportacion por jobs.
  void _openExportJobs() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExportJobsView()));
  }

  /// Permite elegir una foto desde la galeria y la envia al backend.
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

  /// Elimina la foto actual del perfil.
  Future<void> _deleteAvatar() async {
    final ok = await _viewModel.deleteAvatar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Foto de perfil eliminada.'
              : (_viewModel.errorMessage ?? 'No se pudo eliminar la foto.'),
        ),
      ),
    );
  }

  /// Muestra acciones rapidas para actualizar o eliminar el avatar.
  Future<void> _showAvatarActions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Cambiar foto'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndUploadAvatar();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Convierte claves snake_case a etiquetas mas legibles.
  String _formatPrefLabel(String raw) {
    final text = raw.replaceAll('_', ' ').trim();
    if (text.isEmpty) return raw;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}

/// Tarjeta superior con avatar, nombre y correo.
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isUpdatingAvatar,
    required this.onAvatarTap,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final bool isUpdatingAvatar;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                _AvatarAction(
                  isUpdatingAvatar: isUpdatingAvatar,
                  onTap: onAvatarTap,
                  child: _AvatarVisual(name: name, avatarUrl: avatarUrl),
                ),
                Positioned(
                  right: 6,
                  bottom: 10,
                  child: _AvatarBadge(
                    isUpdatingAvatar: isUpdatingAvatar,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF8D9197),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isUpdatingAvatar ? 'Subiendo foto...' : 'Toca el avatar para cambiar la foto',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C6E80),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarAction extends StatelessWidget {
  const _AvatarAction({
    required this.child,
    required this.isUpdatingAvatar,
    required this.onTap,
  });

  final Widget child;
  final bool isUpdatingAvatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUpdatingAvatar ? null : onTap,
        customBorder: const CircleBorder(),
        child: child,
      ),
    );
  }
}

class _AvatarVisual extends StatelessWidget {
  const _AvatarVisual({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB7DBFB), Color(0xFFEAF5FF)],
        ),
        border: Border.all(color: const Color(0xFF8FCBFF), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14344055),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _AvatarPlaceholder(name: name),
            )
          : _AvatarPlaceholder(name: name),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.isUpdatingAvatar});

  final bool isUpdatingAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF344055),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: isUpdatingAvatar
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.photo_camera_rounded,
              size: 16,
              color: Colors.white,
            ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD9ECFF), Color(0xFFF7FBFF)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Color(0xFF5C6E80),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta compacta con rating y numero de resenas.
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

/// Titulo de seccion estilo iOS para grupos del perfil.
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

/// Contenedor comun para agrupar opciones del perfil.
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

/// Fila de menu navegable con icono, titulo y subtitulo opcional.
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

/// Variante con switch para preferencias locales.
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

/// Hoja inferior simple usada para listas de texto.
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

/// Banner de error reutilizable para la pantalla de perfil.
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
