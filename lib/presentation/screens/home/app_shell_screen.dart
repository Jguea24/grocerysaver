import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../domain/entities/app_models.dart';
import '../../../domain/repositories/app_repositories.dart';
import '../../../services/api_config.dart';
import '../../../views/inventory_page.dart';
import '../../../views/profile_view.dart';
import '../../../views/shopping_list_page.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class ProductRouteArgs {
  const ProductRouteArgs({required this.productId});

  final int productId;
}

class PriceCompareRouteArgs {
  const PriceCompareRouteArgs({required this.productId, required this.productName});

  final int productId;
  final String productName;
}

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  void _openAlerts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
    );
  }

  void _openCart(BuildContext context) {
    context.read<ShoppingListProvider>().load();
    Navigator.of(context).pushNamed(AppRoutes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final pages = [
      const _HomeTab(),
      const _InventoryTab(),
      const ShoppingListPage(embedded: true),
      _index == 3 ? const _ScannerTab() : const SizedBox.shrink(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ['Home', 'Inventario', 'Lista de compras', 'Escaner'][_index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Consumer<ShoppingListProvider>(
            builder: (context, provider, _) {
              final count = provider.items.length;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Carrito',
                      onPressed: () => _openCart(context),
                      icon: const Icon(Icons.shopping_cart_rounded),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16423C),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Consumer<DashboardProvider>(
            builder: (context, provider, _) {
              final count = provider.data.alerts.length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Alertas',
                      onPressed: () => _openAlerts(context),
                      icon: const Icon(Icons.notifications_rounded),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD94841),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16423C),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Usuario',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(user?.email ?? ''),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F1EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: Color(0xFF16423C)),
                  ),
                  title: const Text(
                    'Mi perfil',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Ver y editar mis datos'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileView()),
                    );
                  },
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await context.read<AuthProvider>().logout();
                    if (!mounted) return;
                    navigator.pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesion'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Inventario'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_rounded), label: 'Compras'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Escaner'),
        ],
        onDestinationSelected: (value) {
          setState(() => _index = value);
          if (value == 0) {
            context.read<DashboardProvider>().load();
          } else if (value == 1) {
            context.read<InventoryProvider>().load();
          } else if (value == 2) {
            context.read<ShoppingListProvider>().load();
          }
        },
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().load(),
      child: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              const _HeaderBanner(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ValueBadge(label: 'Productos', value: '${provider.data.products.length}')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ValueBadge(
                      label: 'Ofertas',
                      value: '${provider.data.offers.length}',
                      background: const Color(0xFFFFEDDB),
                      foreground: const Color(0xFF8C4717),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ValueBadge(
                      label: 'Alertas',
                      value: '${provider.data.alerts.length}',
                      background: const Color(0xFFFFECE8),
                      foreground: const Color(0xFF9A3C28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.isLoading) const LoadingBlock(),
              if (provider.errorMessage != null)
                InlineErrorView(message: provider.errorMessage!, onRetry: provider.load),
              if (!provider.isLoading && provider.errorMessage == null) ...[
                SectionCard(
                  title: 'Categorias',
                  child: provider.data.categories.isEmpty
                      ? const EmptyStateView(
                          title: 'Sin categorias',
                          message: 'Cuando /categories/ devuelva datos apareceran aqui.',
                          icon: Icons.category_outlined,
                        )
                      : _CategoryGrid(categories: provider.data.categories.take(6).toList()),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Catalogo recomendado',
                  action: provider.data.products.isEmpty
                      ? null
                      : TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.productsCatalog),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Ver todo'),
                        ),
                  child: provider.data.products.isEmpty
                      ? const EmptyStateView(
                          title: 'Sin productos',
                          message: 'Tu backend aun no devolvio productos para el home.',
                        )
                      : Column(
                          children: provider.data.products.take(6).map((product) {
                            return _ProductTile(product: product);
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Mejores precios del dia',
                  child: provider.data.offers.isEmpty
                      ? const EmptyStateView(
                          title: 'Sin ofertas',
                          message: 'Las ofertas activas apareceran en esta seccion.',
                          icon: Icons.local_offer_outlined,
                        )
                      : Column(
                          children: provider.data.offers.take(5).map((product) {
                            return _ProductTile(product: product, offerStyle: true);
                          }).toList(),
                        ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFFF7F6F2),
        child: Consumer<InventoryProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF16423C), Color(0xFF2D5A4E), Color(0xFF4E7A65)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi inventario',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.items.isEmpty
                              ? 'Agrega tus productos para controlar cantidad y caducidad.'
                              : '${provider.items.length} producto(s) guardado(s)',
                          style: const TextStyle(color: Color(0xFFE6F2EC)),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const InventoryPage()),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF16423C),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Administrar inventario'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.isLoading)
                    const LoadingBlock()
                  else if (provider.errorMessage != null)
                    InlineErrorView(message: provider.errorMessage!, onRetry: provider.load)
                  else if (provider.items.isEmpty)
                    const EmptyStateView(
                      title: 'Inventario vacio',
                      message: 'Todavia no tienes productos guardados en el inventario.',
                      icon: Icons.inventory_2_outlined,
                    )
                  else
                    SectionCard(
                      title: 'Productos',
                      child: Column(
                        children: provider.items
                            .map(
                              (item) => _InventoryTile(
                                item: item,
                                onEdit: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const InventoryPage()),
                                  );
                                },
                                onDelete: () => provider.removeItem(item.id),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: const ShoppingListPage(),
    );
  }
}

class _ShoppingListTab extends StatelessWidget {
  const _ShoppingListTab();

  @override
  Widget build(BuildContext context) {
    return const ShoppingListPage(embedded: true);
  }
}

class _ScannerTab extends StatefulWidget {
  const _ScannerTab();

  @override
  State<_ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<_ScannerTab> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isHandlingScan = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String code) async {
    if (_isHandlingScan || code.trim().isEmpty) return;
    _isHandlingScan = true;
    final result = await context.read<ScannerProvider>().submitCode(code.trim());
    _isHandlingScan = false;
    if (!mounted || result?.product == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: ProductRouteArgs(productId: result!.product!.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        SectionCard(
          title: 'Escaner de codigo de barras o QR',
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 260,
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;
                      final code = barcodes.first.rawValue;
                      if (code != null) _handleCode(code);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _manualCodeController,
                decoration: const InputDecoration(
                  labelText: 'Codigo manual',
                  hintText: '1234567890123',
                ),
              ),
              const SizedBox(height: 12),
              Consumer<ScannerProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      FilledButton.icon(
                        onPressed: provider.isSubmitting ? null : () => _handleCode(_manualCodeController.text),
                        icon: const Icon(Icons.search_rounded),
                        label: Text(provider.isSubmitting ? 'Consultando...' : 'Buscar producto'),
                      ),
                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        InlineErrorView(message: provider.errorMessage!),
                      ],
                      if (provider.lastResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8F5),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            provider.lastResult!.product == null
                                ? provider.lastResult!.message
                                : '${provider.lastResult!.message}: ${provider.lastResult!.product!.name}',
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductDetailProvider>().load(widget.productId);
    });
  }

  Future<void> _addToCart(ProductSummary product) async {
    final provider = context.read<ShoppingListProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await provider.addItem(productId: product.id, quantity: 1);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${product.name} agregado al carrito.'
              : provider.errorMessage ?? 'No se pudo agregar al carrito.',
        ),
      ),
    );
    if (success) {
      navigator.pushNamed(AppRoutes.cart);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: Consumer<ProductDetailProvider>(
        builder: (context, provider, _) {
          final detail = provider.detail;
          if (provider.isLoading && detail == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && detail == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: InlineErrorView(
                message: provider.errorMessage!,
                onRetry: () => provider.load(widget.productId),
              ),
            );
          }
          if (detail == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EmptyStateView(
                    title: 'Detalle no disponible',
                    message: 'No se pudo cargar la informacion del producto.',
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => provider.load(widget.productId),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final product = detail.product;
          final imageUrl = (product.imageUrl?.trim().isNotEmpty ?? false)
              ? ApiConfig.resolveBackendUrl(product.imageUrl!.trim())
              : null;
          final priceLabel = product.estimatedPrice > 0
              ? '\$${product.estimatedPrice.toStringAsFixed(2)}'
              : 'Sin precio';
          final hasBrand = product.brand.trim().isNotEmpty;
          final hasCategory = product.category.trim().isNotEmpty && product.category.trim().toLowerCase() != 'general';
          final hasBarcode = product.barcode.trim().isNotEmpty;
          final hasPrice = product.estimatedPrice > 0;
          final description = detail.description.trim();
          final hasMeaningfulDescription = description.isNotEmpty &&
              description != 'Producto listo para seguimiento de stock, precio e historial.';
          final hasStructuredData = hasBrand || hasCategory || hasBarcode || hasPrice;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _ProductHeroCard(
                productName: product.name,
                brand: product.brand,
                category: product.category,
                priceLabel: priceLabel,
                imageUrl: imageUrl,
                onCompare: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.priceCompare,
                    arguments: PriceCompareRouteArgs(
                      productId: product.id,
                      productName: product.name,
                    ),
                  );
                },
                onAddToCart: () => _addToCart(product),
              ),
              const SizedBox(height: 16),
              if (!hasStructuredData && !hasMeaningfulDescription)
                const _DetailNoticeCard(
                  title: 'Faltan datos del producto',
                  message: 'Este producto ya abre su detalle, pero tu backend todavia no devolvio marca, precio, descripcion o categoria especifica.',
                ),
              if (!hasStructuredData && !hasMeaningfulDescription) const SizedBox(height: 16),
              SectionCard(
                title: 'Resumen del producto',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (hasPrice)
                          SizedBox(
                            width: 230,
                            child: _InfoStatCard(
                              label: 'Precio estimado',
                              value: priceLabel,
                              icon: Icons.sell_rounded,
                              background: const Color(0xFFFFEDDB),
                              foreground: const Color(0xFF8C4717),
                            ),
                          ),
                        if (hasCategory)
                          SizedBox(
                            width: 230,
                            child: _InfoStatCard(
                              label: 'Categoria',
                              value: product.category,
                              icon: Icons.category_rounded,
                            ),
                          ),
                        if (hasBrand)
                          SizedBox(
                            width: 230,
                            child: _InfoStatCard(
                              label: 'Marca',
                              value: product.brand,
                              icon: Icons.verified_rounded,
                            ),
                          ),
                        if (hasBarcode)
                          SizedBox(
                            width: 230,
                            child: _InfoStatCard(
                              label: 'Codigo',
                              value: product.barcode,
                              icon: Icons.qr_code_2_rounded,
                              background: const Color(0xFFF1F6EA),
                              foreground: const Color(0xFF426B1F),
                            ),
                          ),
                      ],
                    ),
                    if (!hasStructuredData) ...[
                      const _DetailInlineHint(
                        message: 'Todavia no hay datos comerciales suficientes para este producto.',
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      hasMeaningfulDescription
                          ? description
                          : 'Este producto ya puede usarse para comparacion, inventario y seguimiento. Cuando el backend envie mas informacion, aqui se mostrara una descripcion mas completa.',
                      style: const TextStyle(height: 1.5, color: Color(0xFF4E5A56)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Mejores precios',
                child: detail.comparisons.isEmpty
                    ? const EmptyStateView(
                        title: 'Sin comparaciones',
                        message: 'El endpoint /compare-prices/ aun no devolvio resultados.',
                        icon: Icons.store_mall_directory_outlined,
                      )
                    : Column(
                        children: detail.comparisons
                            .map((item) => _PriceRowCard(item: item))
                            .toList(),
                      ),
              ),
              if (detail.alternatives.isNotEmpty) ...[
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Alternativas',
                  child: Column(
                    children: detail.alternatives
                        .map((product) => _ProductTile(product: product))
                        .toList(),
                  ),
                ),
              ],
              if (detail.history.isNotEmpty) ...[
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Historial de precios',
                  child: Column(
                    children: detail.history
                        .map((entry) => _HistoryRowCard(entry: entry))
                        .toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}


class _ProductHeroCard extends StatelessWidget {
  const _ProductHeroCard({
    required this.productName,
    required this.brand,
    required this.category,
    required this.priceLabel,
    required this.imageUrl,
    required this.onCompare,
    required this.onAddToCart,
  });

  final String productName;
  final String brand;
  final String category;
  final String priceLabel;
  final String? imageUrl;
  final VoidCallback onCompare;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final subtitle = [brand.trim(), category.trim()]
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'general')
        .join(' · ');
    final heroCategory = category.trim().isEmpty || category.trim().toLowerCase() == 'general'
        ? 'Producto'
        : category;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143E64), Color(0xFF3F5BCE), Color(0xFF8652E5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        heroCategory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      productName.trim().isEmpty ? 'Producto sin nombre' : productName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFFE6EEFF), height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      priceLabel == 'Sin precio' ? 'Precio pendiente' : 'Mejor referencia actual',
                      style: const TextStyle(
                        color: Color(0xFFD8E4FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(26),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl == null || imageUrl!.isEmpty
                    ? const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 50,
                      )
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 50,
                          );
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCompare,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF203E9A),
                  ),
                  icon: const Icon(Icons.compare_arrows_rounded),
                  label: const Text('Comparar precios'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddToCart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16423C),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Anadir al carrito'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _DetailNoticeCard extends StatelessWidget {
  const _DetailNoticeCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0E7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAD9C4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF8C4717).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.info_outline_rounded, color: Color(0xFF8C4717)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5E3615),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(height: 1.4, color: Color(0xFF6A584B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInlineHint extends StatelessWidget {
  const _DetailInlineHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F2FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF5E5A74),
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _InfoStatCard extends StatelessWidget {
  const _InfoStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.background = const Color(0xFFF3F0FA),
    this.foreground = const Color(0xFF352A62),
  });

  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: foreground.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
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

class _PriceRowCard extends StatelessWidget {
  const _PriceRowCard({required this.item});

  final PriceComparisonItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isOffer ? const Color(0xFFFFF2E7) : const Color(0xFFF5F6FB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.storeName, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(item.isOffer ? 'Oferta activa' : 'Precio regular'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '\$${item.unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRowCard extends StatelessWidget {
  const _HistoryRowCard({required this.entry});

  final PriceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.query_stats_rounded, color: Color(0xFF6B54E4)),
      ),
      title: Text(entry.storeName),
      subtitle: Text(entry.date),
      trailing: Text(
        '\$${entry.unitPrice.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class PriceCompareScreen extends StatefulWidget {
  const PriceCompareScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  final int productId;
  final String productName;

  @override
  State<PriceCompareScreen> createState() => _PriceCompareScreenState();
}

class _PriceCompareScreenState extends State<PriceCompareScreen> {
  String? _selectedStoreName;

  Future<void> _addToCart() async {
    final provider = context.read<ShoppingListProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await provider.addItem(productId: widget.productId, quantity: 1);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${widget.productName} agregado al carrito desde ${_selectedStoreName ?? 'la tienda seleccionada'}.'
              : provider.errorMessage ?? 'No se pudo agregar al carrito.',
        ),
      ),
    );
    if (success) {
      navigator.pushNamed(AppRoutes.cart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<HouseholdRepository>();
    return Scaffold(
      appBar: AppBar(title: Text('Comparador: ${widget.productName}')),
      body: FutureBuilder<List<PriceComparisonItem>>(
        future: repository.fetchPriceComparison(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: InlineErrorView(message: snapshot.error.toString()),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyStateView(
                title: 'Sin resultados',
                message: 'No llegaron comparaciones para este producto.',
                icon: Icons.storefront_outlined,
              ),
            );
          }

          items.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
          _selectedStoreName ??= items.first.storeName;
          final selectedItem = items.firstWhere(
            (item) => item.storeName == _selectedStoreName,
            orElse: () => items.first,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6EF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDAEAD9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF205B33)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tienda seleccionada',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B5B42),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${selectedItem.storeName} ? \$${selectedItem.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isBest = index == 0;
                    final isSelected = item.storeName == _selectedStoreName;
                    return InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => setState(() => _selectedStoreName = item.storeName),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2F6FED) : const Color(0xFFE7E1D6),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.storeName,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF2F6FED)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(isBest ? 'Mejor precio actual' : item.isOffer ? 'Oferta activa' : 'Precio disponible'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isBest ? const Color(0xFFE7F2E8) : const Color(0xFFF5F1E8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '\$${item.unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton.icon(
          onPressed: _selectedStoreName == null ? null : _addToCart,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Agregar al carrito'),
        ),
      ),
    );
  }
}


class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD94841), Color(0xFFF08A5D)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alertas activas',
                              style: TextStyle(
                                color: Color(0xFFFFE7E4),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.data.alerts.length} por revisar',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading)
                  const LoadingBlock(message: 'Cargando alertas...')
                else if (provider.errorMessage != null)
                  InlineErrorView(message: provider.errorMessage!, onRetry: provider.load)
                else if (provider.data.alerts.isEmpty)
                  _EmptyAlertsState(
                    onReload: provider.load,
                    detailed: true,
                  )
                else
                  ...provider.data.alerts.map(
                    (alert) => _AlertCard(
                      alert: alert,
                      onDismiss: () => provider.dismissAlert(alert.id),
                      compact: false,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}



class _EmptyAlertsState extends StatelessWidget {
  const _EmptyAlertsState({
    required this.onReload,
    this.detailed = false,
  });

  final Future<void> Function() onReload;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? 'sin sesion';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EA),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF6C7B74),
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            'Sin alertas activas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detailed
                ? 'No llegaron alertas activas para la sesion actual.'
                : 'Cuando existan productos proximos a caducar apareceran aqui.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6E7773), height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Sesion: $email',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A615D),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recargar alertas'),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onDismiss,
    this.compact = true,
  });

  final AlertItem alert;
  final VoidCallback onDismiss;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFD94841);
    final secondary = const Color(0xFFF08A5D);
    final dateText = alert.expiresAt.trim();
    final rawImageUrl = alert.imageUrl?.trim() ?? '';
    final imageUrl = rawImageUrl.isEmpty ? '' : ApiConfig.resolveBackendUrl(rawImageUrl);

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 12 : 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF6C9C3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: imageUrl.isEmpty ? LinearGradient(colors: [accent, secondary]) : null,
              color: imageUrl.isEmpty ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isEmpty
                ? const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                      );
                    },
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6C211B),
                        ),
                      ),
                    ),
                    if (alert.urgencyLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          alert.urgencyLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9A3C28),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.message,
                  style: const TextStyle(height: 1.35),
                ),
                if (dateText.isNotEmpty && dateText != alert.urgencyLabel) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Caduca: $dateText',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A3C28),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Marcar como revisada',
            onPressed: onDismiss,
            icon: const Icon(Icons.check_circle_rounded),
            color: accent,
          ),
        ],
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16423C), Color(0xFF2D5A4E), Color(0xFF4E7A65)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu centro de control para compras y stock',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta inventario, expira productos, compara supermercados y registra compras desde una sola experiencia.',
            style: TextStyle(color: Color(0xFFE5F1EA), height: 1.4),
          ),
        ],
      ),
    );
  }
}


class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<CategorySummary> categories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final rawImageUrl = category.imageUrl?.trim() ?? '';
        final imageUrl = rawImageUrl.isEmpty ? '' : ApiConfig.resolveBackendUrl(rawImageUrl);
        return _CategoryCard(
          category: category,
          imageUrl: imageUrl,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CategoryProductsScreen(category: category),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.imageUrl,
    required this.onTap,
  });

  final CategorySummary category;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F1A4D),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.shopping_basket_rounded,
                          color: Color(0xFF6B54E4),
                          size: 34,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.shopping_basket_rounded,
                                color: Color(0xFF6B54E4),
                                size: 34,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF352A62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ProductsCatalogScreen extends StatefulWidget {
  const ProductsCatalogScreen({super.key});

  @override
  State<ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    setState(() {
      _search = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<HouseholdRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Todos los productos')),
      body: FutureBuilder<List<ProductSummary>>(
        future: repository.fetchProducts(search: _search),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: InlineErrorView(message: snapshot.error.toString()),
            );
          }

          final products = snapshot.data ?? const [];
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF16423C), Color(0xFF2D5A4E), Color(0xFF4E7A65)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catalogo completo',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${products.length} productos disponibles desde tu backend',
                        style: const TextStyle(color: Color(0xFFE5F1EA)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _submitSearch(),
                              decoration: const InputDecoration(
                                hintText: 'Buscar por nombre o marca',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(18)),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: _submitSearch,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF16423C),
                              minimumSize: const Size(54, 54),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.search_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (products.isEmpty)
                  const EmptyStateView(
                    title: 'Sin productos',
                    message: 'No se encontraron productos para esta busqueda.',
                    icon: Icons.inventory_2_outlined,
                  )
                else
                  SectionCard(
                    title: 'Productos',
                    child: Column(
                      children: products
                          .map((product) => _ProductTile(product: product))
                          .toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final CategorySummary category;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<HouseholdRepository>();
    final imageUrl = (category.imageUrl?.trim().isNotEmpty ?? false)
        ? ApiConfig.resolveBackendUrl(category.imageUrl!.trim())
        : '';

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: FutureBuilder<List<ProductSummary>>(
        future: repository.fetchProducts(categoryId: category.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: InlineErrorView(message: snapshot.error.toString()),
            );
          }

          final products = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF143E64), Color(0xFF3F5BCE), Color(0xFF8652E5)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrl.isEmpty
                          ? const Icon(
                              Icons.category_rounded,
                              color: Colors.white,
                              size: 34,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.category_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Productos por categoria',
                            style: TextStyle(
                              color: Color(0xFFDCE7FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${products.length} productos encontrados',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (products.isEmpty)
                const EmptyStateView(
                  title: 'Sin productos',
                  message: 'Tu backend aun no devolvio productos para esta categoria.',
                  icon: Icons.inventory_2_outlined,
                )
              else
                SectionCard(
                  title: 'Catalogo',
                  child: Column(
                    children: products
                        .map((product) => _ProductTile(product: product))
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, this.offerStyle = false});

  final ProductSummary product;
  final bool offerStyle;

  @override
  Widget build(BuildContext context) {
    final meta = [product.brand.trim(), product.category.trim()]
        .where((value) => value.isNotEmpty)
        .join(' · ');
    final rawImageUrl = product.imageUrl?.trim() ?? '';
    final imageUrl = rawImageUrl.isEmpty ? '' : ApiConfig.resolveBackendUrl(rawImageUrl);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 68,
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEF9),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl.isEmpty
            ? const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF6B54E4),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF6B54E4),
                  );
                },
              ),
      ),
      title: Text(product.name),
      subtitle: meta.isEmpty ? null : Text(meta),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${product.estimatedPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: offerStyle ? const Color(0xFF8C4717) : null,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.productDetail,
                arguments: ProductRouteArgs(productId: product.id),
              );
            },
            child: const Text(
              'Ver detalle',
              style: TextStyle(color: Color(0xFF16423C), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rawImageUrl = item.product.imageUrl?.trim() ?? '';
    final imageUrl = rawImageUrl.isEmpty ? '' : ApiConfig.resolveBackendUrl(rawImageUrl);
    final expiryText = item.expiresAt.trim().isEmpty ? 'Sin fecha' : item.expiresAt.split('T').first;
    final badge = item.expiryBadge;
    final badgeColor = item.daysUntilExpiry != null && item.daysUntilExpiry! <= 1
        ? const Color(0xFFD94841)
        : const Color(0xFF8C4717);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE6DA),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isEmpty
                ? const Icon(Icons.inventory_2_outlined, color: Color(0xFF8C4717))
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.inventory_2_outlined, color: Color(0xFF8C4717));
                    },
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (badge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Cantidad: ${item.quantity}'),
                const SizedBox(height: 2),
                Text('Caduca: $expiryText'),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}


class _CartTile extends StatelessWidget {
  const _CartTile({required this.item, required this.onEdit, required this.onDelete});

  final CartItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rawImageUrl = item.product.imageUrl?.trim() ?? '';
    final imageUrl = rawImageUrl.isEmpty ? '' : ApiConfig.resolveBackendUrl(rawImageUrl);
    final lineTotal = item.lineTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6DDD0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEF9),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isEmpty
                ? const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6B54E4))
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6B54E4));
                    },
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                if (item.product.category.trim().isNotEmpty)
                  Text(
                    item.product.category,
                    style: const TextStyle(color: Color(0xFF66756F)),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CartChip(label: 'Cantidad: ${item.quantity}'),
                    _CartChip(label: 'Unitario: \$${item.unitPrice.toStringAsFixed(2)}'),
                    _CartChip(label: 'Total: \$${lineTotal.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartChip extends StatelessWidget {
  const _CartChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EC),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF3F4A46),
        ),
      ),
    );
  }
}


































