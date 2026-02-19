import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/app_backdrop.dart';
import '../viewmodels/auth_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final session = viewModel.session;

        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('No hay sesion activa.')),
          );
        }

        return Scaffold(
          body: AppBackdrop(
            maxWidth: 860,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hola, ${session.username ?? (session.email.isEmpty ? 'usuario' : session.email)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E5338),
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar sesion',
                      onPressed: () async {
                        final confirmed = await _confirmLogout(context);
                        if (!confirmed || !context.mounted) {
                          return;
                        }
                        await viewModel.logout();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if ((session.role ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Rol actual: ${session.role}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF2F7D57),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                _highlightCard(context),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: viewModel.isLoadingProtected
                          ? null
                          : () => viewModel.loadMe(),
                      icon: const Icon(Icons.person_search_outlined),
                      label: const Text('Probar /auth/me'),
                    ),
                    OutlinedButton.icon(
                      onPressed: viewModel.isLoadingProtected
                          ? null
                          : () => viewModel.loadAdminOnly(),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Probar /admin-only'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (viewModel.profileData != null)
                  _dataCard(
                    context: context,
                    title: 'Respuesta /auth/me',
                    data: viewModel.profileData!,
                    isProfile: true,
                  ),
                if (viewModel.adminOnlyData != null) ...[
                  const SizedBox(height: 10),
                  _dataCard(
                    context: context,
                    title: 'Respuesta /protected/admin-only',
                    data: viewModel.adminOnlyData!,
                    isProfile: false,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Acciones principales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _FeatureTile(
                      icon: Icons.storefront_outlined,
                      title: 'Comparar precios',
                      description:
                          'Consulta alimentos en supermercados y tiendas cercanas.',
                    ),
                    _FeatureTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Promociones activas',
                      description:
                          'Recibe alertas de tus articulos preferidos.',
                    ),
                    _FeatureTile(
                      icon: Icons.checklist_rounded,
                      title: 'Lista inteligente',
                      description:
                          'Arma tu lista y calcula automaticamente el total.',
                    ),
                    _FeatureTile(
                      icon: Icons.insights_outlined,
                      title: 'Historial de gasto',
                      description: 'Monitorea el gasto mensual por categoria.',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ExpansionTile(
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFDFECE4)),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFDFECE4)),
                  ),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  title: const Text(
                    'Detalle tecnico de sesion',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  children: [
                    SelectableText(
                      session.accessToken,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Cerrar sesion'),
          content: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('¿Estas seguro de que deseas cerrar sesion?'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesion'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _highlightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F7D57), Color(0xFF4E9F76)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x262F7D57),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ahorro estimado esta semana',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$24.50',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu proxima mejora viene de comparar arroz, leche y huevos.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _dataCard({
    required BuildContext context,
    required String title,
    required Map<String, dynamic> data,
    required bool isProfile,
  }) {
    final hasMissingProfileFields =
        isProfile &&
        (data['role'] == null ||
            data['address'] == null ||
            data['birth_date'] == null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFECE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (isProfile) ...[
            _rowData('id', data['id']),
            _rowData('username', data['username']),
            _rowData('email', data['email']),
            _rowData('first_name', data['first_name']),
            _rowData('last_name', data['last_name']),
            _rowData('role', data['role']),
            _rowData('address', data['address']),
            _rowData('birth_date', data['birth_date']),
            _rowData('is_staff', data['is_staff']),
          ] else
            SelectableText(
              data.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          if (hasMissingProfileFields) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF0D98B)),
              ),
              child: const Text(
                'Tu API /auth/me esta devolviendo campos nulos (role/address/birth_date). '
                'Debes revisarlo en serializer/backend.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A5A00)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rowData(String label, Object? value) {
    final text = (value == null || value.toString().trim().isEmpty)
        ? 'No disponible'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('$label: $text', style: const TextStyle(fontSize: 12)),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 410,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDFECE4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF8EF),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF2F7D57)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF567563)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
