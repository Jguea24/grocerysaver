import 'package:flutter/material.dart';

import '../viewmodels/catalog_viewmodel.dart';
import 'category_products_view.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key, required this.catalogViewModel});

  final CatalogViewModel catalogViewModel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: catalogViewModel,
      builder: (context, _) {
        final categories = catalogViewModel.categories;

        return Scaffold(
          appBar: AppBar(title: const Text('Categorias disponibles')),
          body: RefreshIndicator(
            onRefresh: catalogViewModel.refresh,
            child: _buildContent(context, categories),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Map<String, dynamic>> categories,
  ) {
    if (catalogViewModel.isLoading && categories.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (categories.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'No hay categorias disponibles.',
            style: TextStyle(color: Color(0xFF7A8A97), fontSize: 15),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryId = catalogViewModel.categoryId(category);
        final label = catalogViewModel.categoryName(category);
        return _CategoryCard(
          label: label,
          imageUrl: catalogViewModel.categoryImageUrl(category),
          onTap: categoryId == null
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryProductsView(
                        categoryId: categoryId,
                        categoryName: label,
                      ),
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
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE3E8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CategoryImage(imageUrl: imageUrl),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2D3D49),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3ED),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.grid_view_rounded, color: Color(0xFF2F7D57)),
    );
  }
}
