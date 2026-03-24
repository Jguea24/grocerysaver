import 'package:flutter/material.dart';

import '../models/cart_item_model.dart';
import '../models/cart_snapshot_model.dart';
import '../services/cart_service.dart';
import 'checkout_page.dart';
import 'widgets/cart_item_card.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, this.cartService});

  final CartService? cartService;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartService _cartService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  CartSnapshotModel _snapshot = const CartSnapshotModel(
    items: <CartItemModel>[],
    subtotal: 0,
    totalItems: 0,
    distinctProducts: 0,
  );

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? CartService();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _cartService.fetchCartSnapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editQuantity(CartItemModel item) async {
    final controller = TextEditingController(text: '${item.quantity}');
    final quantity = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar cantidad',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(item.product.name),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(int.tryParse(controller.text.trim())),
                  child: const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (quantity == null) {
      return;
    }

    if (quantity <= 0) {
      await _deleteItem(item.id);
      return;
    }

    await _runMutation(() => _cartService.updateCartItem(itemId: item.id, quantity: quantity));
  }

  Future<void> _increase(CartItemModel item) async {
    await _runMutation(() => _cartService.updateCartItem(itemId: item.id, quantity: item.quantity + 1));
  }

  Future<void> _decrease(CartItemModel item) async {
    final nextQuantity = item.quantity - 1;
    if (nextQuantity <= 0) {
      await _deleteItem(item.id);
      return;
    }
    await _runMutation(() => _cartService.updateCartItem(itemId: item.id, quantity: nextQuantity));
  }

  Future<void> _deleteItem(int itemId) async {
    await _runMutation(() => _cartService.deleteCartItem(itemId));
  }

  Future<void> _runMutation(Future<dynamic> Function() action) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await action();
      await _loadCart();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = !_snapshot.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tu carrito',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF19162A)),
        ),
      ),
      bottomNavigationBar: hasItems ? _CartBottomBar(snapshot: _snapshot, isSaving: _isSaving) : null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadCart,
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_errorMessage != null) {
                return _CartErrorState(message: _errorMessage!, onRetry: _loadCart);
              }

              if (_snapshot.isEmpty) {
                return const _CartEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _snapshot.items.length,
                itemBuilder: (context, index) {
                  final item = _snapshot.items[index];
                  return CartItemCard(
                    item: item,
                    isSaving: _isSaving,
                    onEdit: () => _editQuantity(item),
                    onIncrease: () => _increase(item),
                    onDecrease: () => _decrease(item),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({required this.snapshot, required this.isSaving});

  final CartSnapshotModel snapshot;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF17142A),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${snapshot.previousSubtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF8B8896),
                        decoration: TextDecoration.lineThrough,
                        decorationThickness: 2,
                      ),
                    ),
                    Text(
                      '\$${snapshot.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF17142A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutPage()),
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE90059),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                child: const Text('Ir a pagar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartErrorState extends StatelessWidget {
  const _CartErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFD94841)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartEmptyState extends StatelessWidget {
  const _CartEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF8B8896)),
              SizedBox(height: 12),
              Text(
                'Tu carrito esta vacio',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Agrega productos desde el catalogo para verlos aqui y continuar con tu compra.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6E6B77), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
