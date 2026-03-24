import 'package:grocerysaver/models/cart_item_model.dart';

class CartSnapshotModel {
  const CartSnapshotModel({
    required this.items,
    required this.subtotal,
    required this.totalItems,
    required this.distinctProducts,
  });

  final List<CartItemModel> items;
  final double subtotal;
  final int totalItems;
  final int distinctProducts;

  double get previousSubtotal => subtotal <= 0 ? 0 : subtotal / 0.9;
  bool get isEmpty => items.isEmpty;
}
