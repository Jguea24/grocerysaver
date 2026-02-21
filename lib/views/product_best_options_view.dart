import 'package:flutter/material.dart';

import '../viewmodels/catalog_viewmodel.dart';

class ProductBestOptionsView extends StatelessWidget {
  const ProductBestOptionsView({super.key, required this.catalogViewModel});

  final CatalogViewModel catalogViewModel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: catalogViewModel,
      builder: (context, _) {
        final products = catalogViewModel.products;

        return Scaffold(
          appBar: AppBar(title: const Text('Mejores opciones')),
          body: RefreshIndicator(
            onRefresh: catalogViewModel.refresh,
            child: _buildContent(context, products),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) {
    if (catalogViewModel.isLoading && products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'No hay productos para mostrar.',
            style: TextStyle(color: Color(0xFF7A8A97), fontSize: 15),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        return _BestOptionCard(
          name: catalogViewModel.productName(product),
          storesAvailable: catalogViewModel.productStoresAvailable(product),
          bestStore: catalogViewModel.productBestOptionStore(product),
          bestPrice: catalogViewModel.productBestOptionPrice(product),
          onView: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductBestOptionDetailView(
                  product: product,
                  catalogViewModel: catalogViewModel,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ProductBestOptionDetailView extends StatelessWidget {
  const ProductBestOptionDetailView({
    super.key,
    required this.product,
    required this.catalogViewModel,
  });

  final Map<String, dynamic> product;
  final CatalogViewModel catalogViewModel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = catalogViewModel.productImageUrl(product);
    final rows = catalogViewModel.productPriceRows(product);

    return Scaffold(
      appBar: AppBar(title: Text(catalogViewModel.productName(product))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            const SizedBox(height: 12),
          Text(
            'Categoria: ${catalogViewModel.productCategoryName(product)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            catalogViewModel.productDescription(product),
            style: const TextStyle(color: Color(0xFF5E6B76), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Mejor opcion: ${catalogViewModel.productBestOptionStore(product)} (${catalogViewModel.productBestOptionPrice(product)})',
            style: const TextStyle(
              color: Color(0xFF1F6A47),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Precios por tienda (${catalogViewModel.productStoresAvailable(product)})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text(
              'Sin precios disponibles',
              style: TextStyle(color: Color(0xFF7A8A97)),
            )
          else
            ...rows.map(
              (row) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(catalogViewModel.priceRowStoreName(row)),
                  trailing: Text(
                    catalogViewModel.priceRowPrice(row),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BestOptionCard extends StatelessWidget {
  const _BestOptionCard({
    required this.name,
    required this.storesAvailable,
    required this.bestStore,
    required this.bestPrice,
    required this.onView,
  });

  final String name;
  final int storesAvailable;
  final String bestStore;
  final String bestPrice;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF7ED842),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6DA),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFF20573A),
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
                  style: const TextStyle(
                    color: Color(0xFF173A29),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tiendas disponibles: $storesAvailable',
                  style: const TextStyle(
                    color: Color(0xFF173A29),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mejor opcion: $bestStore ($bestPrice)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              minimumSize: const Size(76, 38),
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}
