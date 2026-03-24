class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryName,
    this.categoryImage,
    required this.bestPrice,
  });

  final int id;
  final String name;
  final String brand;
  final String categoryName;
  final String? categoryImage;
  final double bestPrice;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString().trim().isEmpty
          ? 'Producto'
          : (json['name'] ?? '').toString().trim(),
      brand: (json['brand'] ?? '').toString().trim(),
      categoryName: (json['category_name'] ?? '').toString().trim(),
      categoryImage: _readImage(json),
      bestPrice: _toDouble(json['best_price']),
    );
  }

  String get displayBrand => brand.isEmpty ? 'Sin marca' : brand;
  String get displayCategory => categoryName.isEmpty ? 'Sin categoria' : categoryName;

  static String? _readImage(Map<String, dynamic> json) {
    final value = (json['image'] ?? json['category_image'] ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}
