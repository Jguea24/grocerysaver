// Pantalla principal con accesos rapidos al resto de modulos.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/catalog_api.dart';
import '../services/cart_api.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/catalog_viewmodel.dart';
import 'categories_view.dart';
import 'offers_view.dart';
import 'product_best_options_view.dart';
import 'profile_view.dart';
import 'scan_view.dart';
import 'sensor_view.dart';
import 'weather_view.dart';

/// Home principal mostrado despues del login.
class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedTab = 0;
  late final CatalogViewModel _catalogViewModel;
  late final CartViewModel _cartViewModel;

  @override
  void initState() {
    super.initState();
    // El catalogo se comparte con vistas hijas para evitar recargas duplicadas.
    _catalogViewModel = CatalogViewModel(api: CatalogApi(ApiConfig.baseUrl));
    _cartViewModel = CartViewModel(api: CartApi(ApiConfig.baseUrl));
    _catalogViewModel.loadInitialData();
    _cartViewModel.loadCart();
  }

  @override
  void dispose() {
    _cartViewModel.dispose();
    _catalogViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.viewModel,
        _catalogViewModel,
        _cartViewModel,
      ]),
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

        final categories = _catalogViewModel.categories;
        final products = _catalogViewModel.products;
        final featuredProduct = products.isEmpty ? null : products.first;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F5F7),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) {
              // Algunas pestanas abren vistas dedicadas en lugar de cambiar el body.
              if (index == 1) {
                _openCategories(context);
                return;
              }
              if (index == 2) {
                _openBestOptions(context);
                return;
              }
              if (index == 3) {
                _openOffers(context);
                return;
              }
              if (index == 4) {
                _openWeather(context, location);
                return;
              }
              if (index == 5) {
                _openProfile(context);
                return;
              }
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
                icon: Icon(Icons.cloud_outlined),
                selectedIcon: Icon(Icons.cloud_rounded),
                label: 'Clima',
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
                  onRefresh: () async {
                    await Future.wait([
                      _catalogViewModel.refresh(),
                      _cartViewModel.refresh(),
                    ]);
                  },
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
                          cartItems: _cartViewModel.totalItems,
                          isCartLoading: _cartViewModel.isLoading,
                          onCart: () => _openBestOptions(context),
                          onScan: () => _openScan(context),
                          onSensors: () => _openSensors(context),
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
                        const SizedBox(height: 12),
                        _OrderShortcutCard(
                          totalItems: _cartViewModel.totalItems,
                          subtotal: _cartViewModel.subtotal,
                          isLoading: _cartViewModel.isLoading,
                          onTap: () => _openBestOptions(context),
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
                              final imageUrl = _catalogViewModel
                                  .categoryImageUrl(category);

                              return _CategoryTile(
                                label: label,
                                imageUrl: imageUrl,
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
                          GridView.builder(
                            itemCount: products.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.35,
                                ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return _FeaturedProductCard(
                                name: _catalogViewModel.productName(product),
                                brand: _catalogViewModel.productDescription(
                                  product,
                                ),
                                imageUrl: _catalogViewModel.productImageUrl(
                                  product,
                                ),
                                price: _catalogViewModel.productPrice(product),
                                discountBadge: _catalogViewModel
                                    .productDiscountBadge(product),
                                onTap: () =>
                                    _openProductDetail(context, product),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        _TrackCard(
                          storesCount: featuredProduct == null
                              ? 0
                              : _catalogViewModel.productStoresAvailable(
                                  featuredProduct,
                                ),
                          bestStore: featuredProduct == null
                              ? 'Sin datos'
                              : _catalogViewModel.productBestOptionStore(
                                  featuredProduct,
                                ),
                          bestPrice: featuredProduct == null
                              ? '-'
                              : _catalogViewModel.productBestOptionPrice(
                                  featuredProduct,
                                ),
                          onView: () => _openBestOptions(context),
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

  /// Asigna iconos locales a categorias cuando el backend no provee imagen.
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

  /// Confirma el cierre de sesion antes de limpiar la navegacion.
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

  /// Navega al comparador compartiendo el mismo `CatalogViewModel`.
  void _openBestOptions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductBestOptionsView(
          catalogViewModel: _catalogViewModel,
          cartViewModel: _cartViewModel,
        ),
      ),
    );
  }

  /// Reutiliza la vista de detalle del comparador desde home.
  void _openProductDetail(BuildContext context, Map<String, dynamic> product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductBestOptionDetailView(
          product: product,
          catalogViewModel: _catalogViewModel,
          cartViewModel: _cartViewModel,
        ),
      ),
    );
  }

  /// Abre el listado completo de categorias.
  void _openCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoriesView(catalogViewModel: _catalogViewModel),
      ),
    );
  }

  /// Abre clima usando la direccion del usuario como pista inicial.
  void _openWeather(BuildContext context, String locationHint) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WeatherView(initialCity: locationHint)),
    );
  }

  /// Abre el modulo de ofertas.
  void _openOffers(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OffersView()));
  }

  /// Abre el modulo de escaneo.
  void _openScan(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScanView()));
  }

  /// Abre la pantalla de sensores del dispositivo.
  void _openSensors(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SensorView()));
  }

  /// Abre la pantalla de perfil.
  void _openProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileView()));
  }

  /// Muestra una confirmacion nativa antes de cerrar sesion.
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

/// Encabezado con saludo, ubicacion y accesos rapidos.
class _Header extends StatelessWidget {
  const _Header({
    required this.username,
    required this.location,
    required this.role,
    required this.cartItems,
    required this.isCartLoading,
    required this.onCart,
    required this.onScan,
    required this.onSensors,
    required this.onLogout,
  });

  final String username;
  final String location;
  final String? role;
  final int cartItems;
  final bool isCartLoading;
  final VoidCallback onCart;
  final VoidCallback onScan;
  final VoidCallback onSensors;
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Mi pedido',
              onPressed: onCart,
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
            if (isCartLoading)
              const Positioned(
                right: 6,
                top: 6,
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (cartItems > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5FA8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cartItems > 99 ? '99+' : '$cartItems',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          tooltip: 'Escanear producto',
          onPressed: onScan,
          icon: const Icon(Icons.qr_code_scanner_rounded),
        ),
        IconButton(
          tooltip: 'Sensores',
          onPressed: onSensors,
          icon: const Icon(Icons.sensors_rounded),
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

/// Barra de busqueda con debounce para no saturar el backend.
class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onSearch, required this.onClear});

  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  /// Agrupa cambios rapidos de texto en una sola consulta.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  /// Fuerza una busqueda inmediata al enviar desde teclado.
  void _submitNow(String value) {
    _debounce?.cancel();
    widget.onSearch(value);
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
              onChanged: _onChanged,
              onSubmitted: _submitNow,
            ),
          ),
          IconButton(
            onPressed: () {
              _debounce?.cancel();
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

/// Tarjeta resumen del ahorro semanal sugerido.
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

/// Acceso directo al pedido actual usando el resumen del carrito.
class _OrderShortcutCard extends StatelessWidget {
  const _OrderShortcutCard({
    required this.totalItems,
    required this.subtotal,
    required this.isLoading,
    required this.onTap,
  });

  final int totalItems;
  final num subtotal;
  final bool isLoading;
  final VoidCallback onTap;

  String _formatCurrency() {
    if (subtotal == subtotal.roundToDouble()) {
      return '\$${subtotal.toStringAsFixed(0)}';
    }
    return '\$${subtotal.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD6E2EA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5FF),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF2B6CB0),
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi Pedido',
                    style: TextStyle(
                      color: Color(0xFF1A242D),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLoading
                        ? 'Actualizando carrito...'
                        : totalItems == 0
                        ? 'Tu carrito esta vacio'
                        : '$totalItems items · ${_formatCurrency()}',
                    style: const TextStyle(
                      color: Color(0xFF637381),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F5FA8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ver',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador decorativo de paginas o bloques destacados.
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

/// Punto individual del indicador.
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

/// Titulo de seccion con accion secundaria a la derecha.
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

/// Tarjeta compacta para una categoria dentro de la grilla de home.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.imageUrl,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
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
            child: _CategoryVisual(
              imageUrl: imageUrl,
              icon: icon,
              isSelected: isSelected,
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

/// Renderiza la imagen remota o un icono fallback para categorias.
class _CategoryVisual extends StatelessWidget {
  const _CategoryVisual({
    required this.imageUrl,
    required this.icon,
    required this.isSelected,
  });

  final String? imageUrl;
  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Icon(
      icon,
      color: isSelected ? Colors.white : const Color(0xFF2F7D57),
      size: 30,
    );
  }
}

/// Tarjeta compacta de producto destacada en home.
class _FeaturedProductCard extends StatelessWidget {
  const _FeaturedProductCard({
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.price,
    required this.discountBadge,
    required this.onTap,
  });

  final String name;
  final String brand;
  final String? imageUrl;
  final String price;
  final String? discountBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE3E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (discountBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F6D9),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      discountBadge!,
                      style: const TextStyle(
                        color: Color(0xFF2C8B45),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 20, height: 14),
                const Icon(Icons.favorite, size: 12, color: Color(0xFF27A05A)),
              ],
            ),
            const SizedBox(height: 3),
            Center(child: _FeaturedProductVisual(imageUrl: imageUrl)),
            const SizedBox(height: 5),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8A959F), fontSize: 9.5),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
          ],
        ),
      ),
    );
  }
}

/// Imagen reducida del producto con fallback local.
class _FeaturedProductVisual extends StatelessWidget {
  const _FeaturedProductVisual({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_basket_outlined,
        size: 20,
        color: Color(0xFF7B8791),
      ),
    );
  }
}

/// Resumen rapido de la mejor opcion para un producto visible.
class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.storesCount,
    required this.bestStore,
    required this.bestPrice,
    required this.onView,
  });

  final int storesCount;
  final String bestStore;
  final String bestPrice;
  final VoidCallback onView;

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
            onPressed: onView,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF24513A),
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
