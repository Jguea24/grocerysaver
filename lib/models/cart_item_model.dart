import 'package:grocerysaver/models/product_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.hasPrice,
    this.storeId,
    this.storeName,
  });

  final int id;
  final ProductModel product;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final bool hasPrice;
  final int? storeId;
  final String? storeName;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productMap = (json['product'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final storeMap = json['store'] as Map<String, dynamic>?;
    final quantity = (json['quantity'] as num?)?.toInt() ?? 0;
    final unitPrice = _toDouble(json['unit_price']);
    final lineTotal = _toDouble(json['line_total']);

    return CartItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      product: ProductModel.fromJson(productMap),
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: lineTotal > 0 ? lineTotal : unitPrice * quantity,
      hasPrice: json['has_price'] == true,
      storeId: (storeMap?['id'] as num?)?.toInt(),
      storeName: _readText(storeMap?['name']),
    );
  }

  String get brandLabel => product.displayBrand;
  String get categoryLabel => product.displayCategory;
  String get imageUrl => product.categoryImage ?? '';
  double get currentDisplayPrice => lineTotal > 0 ? lineTotal : unitPrice * quantity;
  double get previousDisplayPrice => currentDisplayPrice <= 0 ? 0 : currentDisplayPrice / 0.9;
  String get discountLabel => '10% OFF';

  String get metaLine {
    final values = <String>[brandLabel, categoryLabel];
    if ((storeName ?? '').trim().isNotEmpty) {
      values.add(storeName!.trim());
    }
    return values.join(' · ');
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}

String? _readText(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}
