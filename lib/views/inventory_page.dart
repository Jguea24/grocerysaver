import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/entities/app_models.dart';
import '../models/alert_model.dart';
import '../models/product_model.dart';
import '../presentation/providers/app_providers.dart';
import '../services/api_config.dart';
import '../services/inventory_service.dart';
import '../services/product_service.dart';
import 'widgets/expiry_alerts_section.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    this.embedded = false,
    this.inventoryService,
    this.productService,
  });

  final bool embedded;
  final InventoryService? inventoryService;
  final ProductService? productService;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final InventoryService _inventoryService;
  late final ProductService _productService;

  bool _isAlertsLoading = true;
  bool _isSaving = false;
  String? _alertsErrorMessage;
  List<AlertModel> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _inventoryService = widget.inventoryService ?? InventoryService();
    _productService = widget.productService ?? ProductService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAll();
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<InventoryProvider>().load(),
      _loadAlerts(),
    ]);
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isAlertsLoading = true;
      _alertsErrorMessage = null;
    });
    try {
      final alerts = await _inventoryService.fetchActiveAlerts();
      if (!mounted) return;
      setState(() => _alerts = alerts);
    } catch (error) {
      if (!mounted) return;
      setState(() => _alertsErrorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isAlertsLoading = false);
      }
    }
  }

  Future<void> _deleteItem(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('Se eliminara ${item.product.name} del inventario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await context.read<InventoryProvider>().removeItem(item.id);
      await _loadAlerts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.product.name} eliminado del inventario.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openItemSheet({InventoryItem? item}) async {
    final result = await showModalBottomSheet<_InventoryFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _InventoryItemSheet(
        productService: _productService,
        initialItem: item,
      ),
    );

    if (result == null) return;

    setState(() => _isSaving = true);
    final provider = context.read<InventoryProvider>();
    bool success = false;
    try {
      if (item == null) {
        success = await provider.addItem(
          productId: result.product.id,
          quantity: result.quantity,
          expiresAt: result.expiresAt,
        );
      } else {
        success = await provider.updateItem(
          itemId: item.id,
          quantity: result.quantity,
          expiresAt: result.expiresAt,
        );
      }
      await _loadAlerts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? item == null
                    ? 'Producto agregado al inventario.'
                    : 'Inventario actualizado.'
                : provider.errorMessage ?? 'No se pudo guardar el inventario.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFFF7F6F2),
        child: Consumer<InventoryProvider>(
          builder: (context, provider, _) {
            final content = RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(18, widget.embedded ? 10 : 18, 18, 24),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.embedded ? 'Inventario' : 'Mi inventario',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.items.isEmpty
                                    ? 'Agrega tu primer producto para controlar caducidad y stock.'
                                    : '${provider.items.length} producto(s) guardado(s) en casa',
                                style: const TextStyle(color: Color(0xFFE6F2EC)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.tonalIcon(
                          onPressed: _isSaving || provider.isSaving ? null : () => _openItemSheet(),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF16423C),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ExpiryAlertsSection(
                    alerts: _alerts,
                    isLoading: _isAlertsLoading,
                    errorMessage: _alertsErrorMessage,
                    onRetry: _loadAlerts,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Productos del inventario',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF17142A),
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _isSaving || provider.isSaving ? null : () => _openItemSheet(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Agregar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (provider.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 34),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (provider.errorMessage != null)
                          _InventoryErrorState(
                            message: provider.errorMessage!,
                            onRetry: provider.load,
                          )
                        else if (provider.items.isEmpty)
                          const _InventoryEmptyState()
                        else
                          Column(
                            children: provider.items
                                .map(
                                  (item) => _InventoryItemCard(
                                    item: item,
                                    isSaving: _isSaving || provider.isSaving,
                                    onEdit: () => _openItemSheet(item: item),
                                    onDelete: () => _deleteItem(item),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (widget.embedded) {
              return content;
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF7F6F2),
              appBar: AppBar(title: const Text('Mi inventario'), centerTitle: true),
              body: content,
            );
          },
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.isSaving,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSaving;

  String get _imageUrl => item.product.imageUrl?.trim() ?? '';

  String get _expiryText {
    final raw = item.expiresAt.trim();
    if (raw.isEmpty) return 'Sin fecha';
    return raw.split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _InventoryImage(imageUrl: _imageUrl),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  item.product.category.trim().isEmpty ? 'Sin categoria' : item.product.category,
                  style: const TextStyle(color: Color(0xFF6E6B77)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(label: 'Cantidad', value: '${item.quantity}'),
                    _MetaChip(label: 'Caduca', value: _expiryText),
                    _ExpiryChip(
                      label: item.expiryBadge.isEmpty ? 'Sin alerta' : item.expiryBadge,
                      urgent: item.daysUntilExpiry != null && item.daysUntilExpiry! <= 1,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              IconButton(
                onPressed: isSaving ? null : onEdit,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: isSaving ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryImage extends StatelessWidget {
  const _InventoryImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 70,
        height: 70,
        color: const Color(0xFFF1EEE8),
        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF6C7B74)),
      );
    }
    return Image.network(
      ApiConfig.resolveBackendUrl(imageUrl),
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 70,
        height: 70,
        color: const Color(0xFFF1EEE8),
        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF6C7B74)),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3E3A4B)),
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  const _ExpiryChip({required this.label, required this.urgent});

  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFFE26B) : const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: urgent ? const Color(0xFF5C4300) : const Color(0xFF166534),
        ),
      ),
    );
  }
}

class _InventoryErrorState extends StatelessWidget {
  const _InventoryErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1B7AC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  const _InventoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF6C7B74)),
          SizedBox(height: 12),
          Text(
            'No tienes productos en inventario',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega productos con su fecha de caducidad para recibir alertas automaticas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6E6B77), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemSheet extends StatefulWidget {
  const _InventoryItemSheet({
    required this.productService,
    this.initialItem,
  });

  final ProductService productService;
  final InventoryItem? initialItem;

  @override
  State<_InventoryItemSheet> createState() => _InventoryItemSheetState();
}

class _InventoryItemSheetState extends State<_InventoryItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiresController = TextEditingController();

  bool _isLoadingProducts = false;
  String? _errorMessage;
  List<ProductModel> _products = const [];
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _searchController.text = item?.product.name ?? '';
    _quantityController.text = '${item?.quantity ?? 1}';
    _expiresController.text = _initialExpiryText(item);
    _loadProducts();
  }

  String _initialExpiryText(InventoryItem? item) {
    final raw = item?.expiresAt.trim() ?? '';
    if (raw.isEmpty) {
      return _formatDate(DateTime.now().add(const Duration(days: 7)));
    }
    return raw.split('T').first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _expiresController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _errorMessage = null;
    });
    try {
      final products = await widget.productService.fetchProducts(search: _searchController.text.trim());
      if (!mounted) return;
      setState(() {
        _products = products;
        if (_selectedProduct == null && products.isNotEmpty) {
          _selectedProduct = products.firstWhere(
            (product) => product.name == widget.initialItem?.product.name,
            orElse: () => products.first,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_expiresController.text) ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    _expiresController.text = _formatDate(picked);
    setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final product = _selectedProduct;
    if (product == null) {
      setState(() => _errorMessage = 'Selecciona un producto.');
      return;
    }
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    Navigator.of(context).pop(
      _InventoryFormResult(
        product: product,
        quantity: quantity,
        expiresAt: _expiresController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialItem == null ? 'Agregar producto' : 'Editar inventario',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Color(0xFFD94841))),
                const SizedBox(height: 10),
              ],
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar producto',
                  suffixIcon: IconButton(
                    onPressed: _loadProducts,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView(
                    shrinkWrap: true,
                    children: _products
                        .map(
                          (product) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => setState(() => _selectedProduct = product),
                            leading: Icon(
                              _selectedProduct?.id == product.id
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                            ),
                            title: Text(product.name),
                            subtitle: Text(
                              [product.displayBrand, product.displayCategory].join(' · '),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (value) {
                  final quantity = int.tryParse((value ?? '').trim());
                  if (quantity == null || quantity <= 0) {
                    return 'Ingresa una cantidad valida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiresController,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'Fecha de caducidad',
                  suffixIcon: IconButton(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_rounded),
                  ),
                ),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Selecciona una fecha.' : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    widget.initialItem == null ? 'Agregar al inventario' : 'Guardar cambios',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryFormResult {
  const _InventoryFormResult({
    required this.product,
    required this.quantity,
    required this.expiresAt,
  });

  final ProductModel product;
  final int quantity;
  final String expiresAt;
}

String _formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
