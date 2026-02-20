import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/catalog_api.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/catalog_viewmodel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedTab = 0;
  late final CatalogViewModel _catalogViewModel;

  @override
  void initState() {
    super.initState();
    _catalogViewModel = CatalogViewModel(api: CatalogApi(ApiConfig.baseUrl));
    _catalogViewModel.loadInitialData();
  }

  @override
  void dispose() {
    _catalogViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.viewModel, _catalogViewModel]),
      builder: (context, _) {
        final session = widget.viewModel.session;
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('No hay sesion activa.')),
          );
        }

        final address =
            widget.viewModel.profileData?['address']?.toString().trim() ?? '';
        final location = address.isEmpty ? 'Tu ciudad' : address;
        final username =
            session.username ??
            (session.email.isEmpty ? 'usuario' : session.email);

        final categories = _catalogViewModel.categories.take(8).toList();
        final products = _catalogViewModel.products.take(6).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF3F5F7),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Categorias',
              ),
              NavigationDestination(
                icon: Icon(Icons.compare_arrows_rounded),
                selectedIcon: Icon(Icons.compare_arrows_rounded),
                label: 'Comparar',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_offer_outlined),
                selectedIcon: Icon(Icons.local_offer_rounded),
                label: 'Ofertas',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: RefreshIndicator(
                  onRefresh: _catalogViewModel.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          username: username,
                          location: location,
                          role: session.role,
                          onLogout: () => _logout(context),
                        ),
                        const SizedBox(height: 14),
                        _SearchBar(
                          onSearch: _catalogViewModel.updateSearch,
                          onClear: () => _catalogViewModel.updateSearch(''),
                        ),
                        const SizedBox(height: 14),
                        _WeeklyHeroCard(
                          storesCount: _catalogViewModel.stores.length,
                          bestStore: _catalogViewModel.bestStoreName(),
                          bestPrice: _catalogViewModel.bestPrice(),
                          isLoadingCompare: _catalogViewModel.isLoadingCompare,
                          onCompare: _catalogViewModel.compareCurrent,
                        ),
                        const SizedBox(height: 10),
                        const _DotsIndicator(),
                        if (_catalogViewModel.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCEAEA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _catalogViewModel.errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFAC2E2E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _SectionTitle(
                          title: 'Compra por categoria',
                          actionText: 'Todas',
                          onTap: () =>
                              _catalogViewModel.selectCategoryById(null),
                        ),
                        const SizedBox(height: 10),
                        if (_catalogViewModel.isLoading && categories.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (categories.isEmpty)
                          const Text(
                            'No hay categorias disponibles.',
                            style: TextStyle(color: Color(0xFF7A8A97)),
                          )
                        else
                          GridView.builder(
                            itemCount: categories.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.85,
                                ),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final categoryId = _catalogViewModel.categoryId(
                                category,
                              );
                              final label = _catalogViewModel.categoryName(
                                category,
                              );

                              return _CategoryTile(
                                label: label,
                                icon: _iconForCategory(index),
                                isSelected:
                                    categoryId != null &&
                                    categoryId ==
                                        _catalogViewModel.selectedCategoryId,
                                onTap: () => _catalogViewModel
                                    .selectCategoryById(categoryId),
                              );
                            },
                          ),
                        const SizedBox(height: 18),
                        _SectionTitle(
                          title: 'Productos encontrados',
                          actionText:
                              '${_catalogViewModel.products.length} items',
                          onTap: () {},
                        ),
                        const SizedBox(height: 10),
                        if (_catalogViewModel.isLoading && products.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (products.isEmpty)
                          const Text(
                            'No hay productos para mostrar.',
                            style: TextStyle(color: Color(0xFF7A8A97)),
                          )
                        else
                          ...products.map(
                            (product) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ProductCard(
                                name: _catalogViewModel.productName(product),
                                price: _catalogViewModel.productPrice(product),
                                store: _catalogViewModel.productStore(product),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        _TrackCard(
                          storesCount: _catalogViewModel.stores.length,
                          bestStore:
                              _catalogViewModel.bestStoreName() ?? 'Sin datos',
                          bestPrice: _catalogViewModel.bestPrice() ?? '-',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconForCategory(int index) {
    const icons = [
      Icons.local_grocery_store_rounded,
      Icons.eco_rounded,
      Icons.set_meal_rounded,
      Icons.lunch_dining_rounded,
      Icons.bakery_dining_rounded,
      Icons.rice_bowl_rounded,
      Icons.local_drink_rounded,
      Icons.icecream_rounded,
    ];
    return icons[index % icons.length];
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await _confirmLogout(context);
    if (!confirmed || !context.mounted) {
      return;
    }
    await widget.viewModel.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Cerrar sesion'),
          content: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('Estas seguro de que deseas cerrar sesion?'),
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
}

class _Header extends StatelessWidget {
  const _Header({
    required this.username,
    required this.location,
    required this.role,
    required this.onLogout,
  });

  final String username;
  final String location;
  final String? role;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF172026),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5E6B76),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if ((role ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F5ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Rol: $role',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2F7D57),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        IconButton(
          tooltip: 'Cerrar sesion',
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onSearch, required this.onClear});

  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF8A98A4)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration.collapsed(
                hintText: 'Buscar productos o tiendas',
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSearch,
            ),
          ),
          IconButton(
            onPressed: () {
              _controller.clear();
              widget.onClear();
            },
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _WeeklyHeroCard extends StatelessWidget {
  const _WeeklyHeroCard({
    required this.storesCount,
    required this.bestStore,
    required this.bestPrice,
    required this.isLoadingCompare,
    required this.onCompare,
  });

  final int storesCount;
  final String? bestStore;
  final String? bestPrice;
  final bool isLoadingCompare;
  final Future<void> Function() onCompare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF245E44), Color(0xFF2F7D57), Color(0xFF4DA670)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40245E44),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahorro inteligente de la semana',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tiendas conectadas: $storesCount',
                  style: const TextStyle(color: Color(0xFFE2F6EA)),
                ),
                const SizedBox(height: 2),
                Text(
                  bestStore == null
                      ? 'Compara para ver la mejor opcion.'
                      : 'Mejor opcion: $bestStore ${bestPrice ?? ''}',
                  style: const TextStyle(color: Color(0xFFE2F6EA)),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: isLoadingCompare ? null : onCompare,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C5A3D),
                    minimumSize: const Size(124, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: isLoadingCompare
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Comparar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            children: [
              Icon(Icons.local_offer_rounded, color: Colors.white, size: 32),
              Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 32),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_Dot(active: true), _Dot(active: false), _Dot(active: false)],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 17 : 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2F7D57) : const Color(0xFFC5D1DA),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  final String title;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E252B),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: Color(0xFF7A8A97),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2F7D57)
                  : const Color(0xFFEAF3ED),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF2F7D57),
              size: 30,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF42505B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.price,
    required this.store,
  });

  final String name;
  final String price;
  final String store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3ED),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: Color(0xFF2F7D57),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  store,
                  style: const TextStyle(
                    color: Color(0xFF647380),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF1F6A47),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.storesCount,
    required this.bestStore,
    required this.bestPrice,
  });

  final int storesCount;
  final String bestStore;
  final String bestPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7FDC42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFF246549),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiendas disponibles: $storesCount',
                  style: const TextStyle(
                    color: Color(0xFF183E2B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mejor opcion: $bestStore ($bestPrice)',
                  style: const TextStyle(
                    color: Color(0xFF24513A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              disabledBackgroundColor: Colors.white,
              foregroundColor: const Color(0xFF24513A),
              disabledForegroundColor: const Color(0xFF24513A),
              minimumSize: const Size(82, 36),
            ),
            child: const Text(
              'Ver',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
