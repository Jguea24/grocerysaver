import 'dart:async';

import 'package:flutter/material.dart';

import '../services/offers_api.dart';

class OffersView extends StatefulWidget {
  const OffersView({super.key});

  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  bool _activeOnly = true;
  int? _selectedStoreId;
  int? _selectedCategoryId;

  List<_FilterItem> _storeOptions = const [];
  List<_FilterItem> _categoryOptions = const [];
  List<Map<String, dynamic>> _offers = const [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  int _currentPage = 1;
  int _queryToken = 0;

  String? _initialError;
  String? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadNextPage();
    }
  }

  Future<void> _refresh() async {
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    final token = ++_queryToken;
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _initialError = null;
      _loadMoreError = null;
      _offers = const [];
      _hasMore = true;
      _currentPage = 1;
    });

    await _loadPage(page: 1, append: false, token: token);
  }

  Future<void> _loadNextPage() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;
    final token = _queryToken;
    await _loadPage(page: _currentPage + 1, append: true, token: token);
  }

  Future<void> _loadPage({
    required int page,
    required bool append,
    required int token,
  }) async {
    if (append) {
      setState(() {
        _isLoadingMore = true;
        _loadMoreError = null;
      });
    }

    try {
      final response = await OffersApi.getOffersPage(
        active: _activeOnly,
        storeId: _selectedStoreId,
        categoryId: _selectedCategoryId,
        search: _searchController.text.trim(),
        page: page,
        pageSize: _pageSize,
      );

      if (!mounted || token != _queryToken) return;

      final incoming = response.offers;
      final merged = append ? _mergeUniqueOffers(_offers, incoming) : incoming;
      final appendedAny = !append || merged.length > _offers.length;

      final filterData = _buildFilterData(merged);
      final validStoreId =
          filterData.stores.any((item) => item.id == _selectedStoreId)
          ? _selectedStoreId
          : null;
      final validCategoryId =
          filterData.categories.any((item) => item.id == _selectedCategoryId)
          ? _selectedCategoryId
          : null;

      setState(() {
        _offers = merged;
        _storeOptions = filterData.stores;
        _categoryOptions = filterData.categories;
        _selectedStoreId = validStoreId;
        _selectedCategoryId = validCategoryId;
        _currentPage = page;
        _hasMore = response.hasNext && appendedAny;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _initialError = null;
        _loadMoreError = null;
      });
    } catch (e) {
      if (!mounted || token != _queryToken) return;

      setState(() {
        if (append) {
          _loadMoreError = e.toString();
          _isLoadingMore = false;
        } else {
          _initialError = e.toString();
          _isInitialLoading = false;
          _isLoadingMore = false;
        }
      });
    }
  }

  List<Map<String, dynamic>> _mergeUniqueOffers(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> incoming,
  ) {
    final merged = <Map<String, dynamic>>[...current];
    final seen = <String>{...current.map(_offerIdentity)};

    for (final item in incoming) {
      final key = _offerIdentity(item);
      if (seen.add(key)) {
        merged.add(item);
      }
    }

    return merged;
  }

  String _offerIdentity(Map<String, dynamic> offer) {
    final offerId = offer['id'];
    if (offerId != null) {
      return 'id:${offerId.toString().trim()}';
    }

    final product = offer['product'] is Map<String, dynamic>
        ? offer['product'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final store = offer['store'] is Map<String, dynamic>
        ? offer['store'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final productId = (product['id'] ?? '').toString().trim();
    final storeId = (store['id'] ?? '').toString().trim();
    final offerPrice = (offer['offer_price'] ?? '').toString().trim();
    final normalPrice = (offer['normal_price'] ?? '').toString().trim();
    final until = (offer['valid_until'] ?? offer['expires_at'] ?? '')
        .toString()
        .trim();

    return 'pk:$productId-$storeId-$normalPrice-$offerPrice-$until';
  }

  _FilterData _buildFilterData(List<Map<String, dynamic>> offers) {
    final stores = <int, String>{};
    final categories = <int, String>{};

    for (final offer in offers) {
      final store = offer['store'];
      if (store is Map<String, dynamic>) {
        final id = _asInt(store['id']);
        final name = _asText(store['name']);
        if (id != null && name.isNotEmpty) {
          stores[id] = name;
        }
      }

      final product = offer['product'];
      if (product is Map<String, dynamic>) {
        final category = product['category'];
        if (category is Map<String, dynamic>) {
          final id = _asInt(category['id']);
          final name = _asText(category['name']);
          if (id != null && name.isNotEmpty) {
            categories[id] = name;
          }
        } else {
          final id = _asInt(product['category_id']);
          final name = _asText(product['category_name']);
          if (id != null && name.isNotEmpty) {
            categories[id] = name;
          }
        }
      }
    }

    final storeItems = stores.entries
        .map((e) => _FilterItem(id: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final categoryItems = categories.entries
        .map((e) => _FilterItem(id: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return _FilterData(stores: storeItems, categories: categoryItems);
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadFirstPage);
  }

  void _onStoreChanged(int? id) {
    setState(() {
      _selectedStoreId = id;
    });
    _loadFirstPage();
  }

  void _onCategoryChanged(int? id) {
    setState(() {
      _selectedCategoryId = id;
    });
    _loadFirstPage();
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _activeOnly = true;
      _selectedStoreId = null;
      _selectedCategoryId = null;
    });
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 12),
            _buildFiltersCard(),
            const SizedBox(height: 12),
            if (_isInitialLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_initialError != null && _offers.isEmpty)
              _StateMessage(
                icon: Icons.error_outline_rounded,
                message: 'Error: $_initialError',
                actionLabel: 'Reintentar',
                onAction: _loadFirstPage,
              )
            else if (_offers.isEmpty)
              _StateMessage(
                icon: Icons.local_offer_outlined,
                message: 'Sin ofertas para los filtros seleccionados.',
                actionLabel: 'Actualizar',
                onAction: _loadFirstPage,
              )
            else
              ..._offers.map(
                (offer) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OfferCard(offer: offer),
                ),
              ),
            if (!_isInitialLoading && _offers.isNotEmpty && _isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_isInitialLoading &&
                _offers.isNotEmpty &&
                _loadMoreError != null &&
                !_isLoadingMore)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _StateMessage(
                  icon: Icons.wifi_tethering_error_rounded,
                  message: _loadMoreError!,
                  actionLabel: 'Reintentar carga',
                  onAction: _loadNextPage,
                ),
              ),
            if (!_isInitialLoading &&
                _offers.isNotEmpty &&
                !_hasMore &&
                !_isLoadingMore)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Center(
                  child: Text(
                    'Fin de resultados',
                    style: TextStyle(
                      color: Color(0xFF6D7B87),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB85824), Color(0xFFD36E2F), Color(0xFFE88F43)],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer_rounded, color: Colors.white, size: 30),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Encuentra descuentos activos y compara el precio antes y ahora.',
              style: TextStyle(
                color: Color(0xFFFFF1E7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar oferta o producto',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _debounce?.cancel();
                        _searchController.clear();
                        setState(() {});
                        _loadFirstPage();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _activeOnly,
            contentPadding: EdgeInsets.zero,
            title: const Text('Solo ofertas activas'),
            dense: true,
            onChanged: (value) {
              setState(() {
                _activeOnly = value;
              });
              _loadFirstPage();
            },
          ),
          if (_storeOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: ValueKey(
                'store-${_selectedStoreId ?? 0}-${_storeOptions.length}',
              ),
              initialValue: _selectedStoreId,
              hint: const Text('Filtrar por tienda'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Todas las tiendas'),
                ),
                ..._storeOptions.map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                ),
              ],
              onChanged: _onStoreChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
          if (_categoryOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: ValueKey(
                'category-${_selectedCategoryId ?? 0}-${_categoryOptions.length}',
              ),
              initialValue: _selectedCategoryId,
              hint: const Text('Filtrar por categoria'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Todas las categorias'),
                ),
                ..._categoryOptions.map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                ),
              ],
              onChanged: _onCategoryChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }

  int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString().trim());
  }

  String _asText(dynamic raw) => (raw ?? '').toString().trim();
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final Map<String, dynamic> offer;

  @override
  Widget build(BuildContext context) {
    final product = offer['product'] is Map<String, dynamic>
        ? offer['product'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final store = offer['store'] is Map<String, dynamic>
        ? offer['store'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final productName = _text(product['name'], fallback: 'Producto');
    final storeName = _text(store['name'], fallback: 'Tienda');
    final normalPrice = _currency(offer['normal_price']);
    final offerPrice = _currency(offer['offer_price']);
    final discount = _discount(offer['discount_percent']);
    final imageUrl = _text(
      product['image'] ?? product['image_url'] ?? product['photo'],
      fallback: '',
    );
    final date = _text(offer['valid_until'] ?? offer['expires_at'], fallback: '');
    final savings = _savings(offer['normal_price'], offer['offer_price']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isEmpty
                ? Container(
                    width: 66,
                    height: 66,
                    color: const Color(0xFFF4F6F8),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF83919E),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    width: 66,
                    height: 66,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 66,
                      height: 66,
                      color: const Color(0xFFF4F6F8),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF83919E),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2A33),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  storeName,
                  style: const TextStyle(
                    color: Color(0xFF5F6E79),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PriceTag(
                      label: 'Antes',
                      value: normalPrice,
                      background: const Color(0xFFF8EAEA),
                      color: const Color(0xFF8A3A3A),
                    ),
                    _PriceTag(
                      label: 'Ahora',
                      value: offerPrice,
                      background: const Color(0xFFE9F6ED),
                      color: const Color(0xFF1E6A47),
                    ),
                    if (savings.isNotEmpty)
                      _PriceTag(
                        label: 'Ahorras',
                        value: savings,
                        background: const Color(0xFFEAF1F9),
                        color: const Color(0xFF27517D),
                      ),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Vence: $date',
                    style: const TextStyle(
                      color: Color(0xFF6A7884),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4C9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              discount,
              style: const TextStyle(
                color: Color(0xFF8C3F00),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _text(dynamic raw, {required String fallback}) {
    final value = (raw ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  num? _asNum(dynamic raw) {
    if (raw is num) return raw;
    return num.tryParse((raw ?? '').toString().trim());
  }

  String _currency(dynamic raw) {
    final value = _asNum(raw);
    if (value == null) return 'N/A';
    if (value == value.roundToDouble()) return '\$${value.toStringAsFixed(0)}';
    return '\$${value.toStringAsFixed(2)}';
  }

  String _discount(dynamic raw) {
    final value = _asNum(raw);
    if (value == null) return 'Oferta';
    if (value == value.roundToDouble()) return '-${value.toStringAsFixed(0)}%';
    return '-${value.toStringAsFixed(1)}%';
  }

  String _savings(dynamic normalRaw, dynamic offerRaw) {
    final normal = _asNum(normalRaw);
    final offer = _asNum(offerRaw);
    if (normal == null || offer == null || normal <= offer) return '';
    final delta = normal - offer;
    if (delta == delta.roundToDouble()) return '\$${delta.toStringAsFixed(0)}';
    return '\$${delta.toStringAsFixed(2)}';
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({
    required this.label,
    required this.value,
    required this.background,
    required this.color,
  });

  final String label;
  final String value;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: color, fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6E7E8A), size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4F5E69),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem({required this.id, required this.name});

  final int id;
  final String name;
}

class _FilterData {
  const _FilterData({required this.stores, required this.categories});

  final List<_FilterItem> stores;
  final List<_FilterItem> categories;
}
