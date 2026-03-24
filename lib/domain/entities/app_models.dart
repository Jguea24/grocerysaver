class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final int id;
  final String email;
  final String fullName;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] ?? '').toString(),
      fullName: ((json['full_name'] ?? json['name'] ?? json['email']) ?? '')
          .toString(),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;
}

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.estimatedPrice,
    required this.category,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String brand;
  final String barcode;
  final double estimatedPrice;
  final String category;
  final String? imageUrl;

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: _readText(json['name'] ?? json['title'], fallback: 'Producto'),
      brand: _readText(json['brand_name'] ?? json['brand']),
      barcode: (json['barcode'] ?? '').toString(),
      estimatedPrice: _toDouble(
        json['estimated_price'] ??
            json['best_price'] ??
            json['best_option']?['price'] ??
            json['price'],
      ),
      category: _readCategoryName(
        json['category_name'] ?? json['category'] ?? json['category_detail'],
      ),
      imageUrl: _readImageUrl(json),
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.expiresAt,
    this.daysUntilExpiry,
  });

  final int id;
  final ProductSummary product;
  final int quantity;
  final String expiresAt;
  final int? daysUntilExpiry;

  String get expiryBadge {
    if (daysUntilExpiry == null) return '';
    if (daysUntilExpiry! < 0) return 'Vencido';
    if (daysUntilExpiry == 0) return 'Hoy';
    if (daysUntilExpiry == 1) return '1 d';
    return '$daysUntilExpiry d';
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      product: ProductSummary.fromJson(
        (json['product'] as Map<String, dynamic>?) ??
            {
              'id': json['product_id'],
              'name': json['product_name'],
              'estimated_price': json['estimated_price'],
              'category_image': json['category_image'],
              'image': json['image'],
            },
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      expiresAt: (json['expires_at'] ?? '').toString(),
      daysUntilExpiry: (json['days_until_expiry'] as num?)?.toInt(),
    );
  }
}

class CartItem {
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.checked,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int id;
  final ProductSummary product;
  final int quantity;
  final bool checked;
  final double unitPrice;
  final double lineTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = ProductSummary.fromJson(
      (json['product'] as Map<String, dynamic>?) ??
          {
            'id': json['product_id'],
            'name': json['product_name'],
            'brand': json['brand'],
            'category_name': json['category_name'],
            'category_image': json['category_image'],
            'image': json['image'],
            'estimated_price': json['unit_price'] ?? json['estimated_price'],
          },
    );
    final quantity = (json['quantity'] as num?)?.toInt() ?? 0;
    final unitPrice = _toDouble(
      json['unit_price'] ?? json['estimated_price'] ?? product.estimatedPrice,
    );
    final rawLineTotal = _toDouble(json['line_total']);

    return CartItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      product: product,
      quantity: quantity,
      checked: json['checked'] == true || json['status'] == 'done',
      unitPrice: unitPrice,
      lineTotal: rawLineTotal > 0 ? rawLineTotal : unitPrice * quantity,
    );
  }
}

class AlertItem {
  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.expiresAt,
    required this.daysRemaining,
    this.imageUrl,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final String status;
  final String expiresAt;
  final int? daysRemaining;
  final String? imageUrl;

  String get urgencyLabel {
    if (daysRemaining == null) return expiresAt;
    if (daysRemaining! <= 0) return 'Hoy';
    if (daysRemaining == 1) return '1 d';
    return '$daysRemaining d';
  }

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final daysRemaining = (json['days_remaining'] as num?)?.toInt();
    final productName = (json['product_name'] ?? product?['name'] ?? '').toString().trim();
    final fallbackTitle = productName.isEmpty ? 'Alerta' : productName;
    final fallbackExpiresAt = (json['expires_at'] ?? json['created_at'] ?? '').toString().trim();
    final daysLabel = daysRemaining == null
        ? ''
        : daysRemaining <= 0
            ? 'Hoy'
            : daysRemaining == 1
                ? '1 dia restante'
                : '$daysRemaining dias restantes';

    return AlertItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'expiry').toString(),
      title: (json['title'] ?? fallbackTitle).toString(),
      message: (json['message'] ?? json['detail'] ?? 'Producto por caducar').toString(),
      status: (json['status'] ?? 'active').toString(),
      expiresAt: fallbackExpiresAt.isNotEmpty ? fallbackExpiresAt : daysLabel,
      daysRemaining: daysRemaining,
      imageUrl: product == null ? null : _readImageUrl(product),
    );
  }
}

class PriceComparisonItem {
  const PriceComparisonItem({
    required this.storeName,
    required this.unitPrice,
    required this.isOffer,
  });

  final String storeName;
  final double unitPrice;
  final bool isOffer;

  factory PriceComparisonItem.fromJson(Map<String, dynamic> json) {
    return PriceComparisonItem(
      storeName: _readText(json['store_name'] ?? json['store'], fallback: 'Tienda'),
      unitPrice: _toDouble(json['unit_price'] ?? json['price']),
      isOffer: json['is_offer'] == true || json['offer'] == true,
    );
  }
}

class PriceHistoryEntry {
  const PriceHistoryEntry({
    required this.date,
    required this.storeName,
    required this.unitPrice,
  });

  final String date;
  final String storeName;
  final double unitPrice;

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PriceHistoryEntry(
      date: (json['date'] ?? json['created_at'] ?? '').toString(),
      storeName: _readText(json['store_name'] ?? json['store'], fallback: 'Tienda'),
      unitPrice: _toDouble(json['unit_price'] ?? json['price']),
    );
  }
}

class ProductDetail {
  const ProductDetail({
    required this.product,
    required this.description,
    required this.alternatives,
    required this.comparisons,
    required this.history,
  });

  final ProductSummary product;
  final String description;
  final List<ProductSummary> alternatives;
  final List<PriceComparisonItem> comparisons;
  final List<PriceHistoryEntry> history;
}

class ScanResult {
  const ScanResult({
    required this.code,
    required this.product,
    required this.message,
  });

  final String code;
  final ProductSummary? product;
  final String message;
}

class CategorySummary {
  const CategorySummary({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String? imageUrl;

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: _readText(json['name'] ?? json['title'], fallback: 'Categoria'),
      imageUrl: _readCategoryImageUrl(json),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.categories,
    required this.products,
    required this.offers,
    required this.alerts,
  });

  final List<CategorySummary> categories;
  final List<ProductSummary> products;
  final List<ProductSummary> offers;
  final List<AlertItem> alerts;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}

String _readText(dynamic value, {String fallback = ''}) {
  if (value is Map<String, dynamic>) {
    final text = (value['name'] ?? value['title'] ?? value['label'] ?? '')
        .toString()
        .trim();
    return text.isEmpty ? fallback : text;
  }

  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return fallback;

  final pseudoMapName = RegExp(r'name\s*:\s*([^,}]+)').firstMatch(text);
  if (pseudoMapName != null) {
    final parsed = pseudoMapName.group(1)?.trim() ?? '';
    if (parsed.isNotEmpty) return parsed;
  }

  if (text.startsWith('{') && text.endsWith('}')) {
    return fallback;
  }

  return text;
}

String _readCategoryName(dynamic value) {
  return _readText(value, fallback: 'General');
}

String? _readCategoryImageUrl(Map<String, dynamic> json) {
  final direct = json['category_image'] ?? json['image_url'] ?? json['image'] ?? json['photo'];
  final text = (direct ?? '').toString().trim();
  if (text.isNotEmpty && !text.startsWith('{')) return text;
  return null;
}

String? _readImageUrl(Map<String, dynamic> json) {
  final direct =
      json['image_url'] ?? json['image'] ?? json['photo'] ?? json['category_image'];
  final text = (direct ?? '').toString().trim();
  if (text.isNotEmpty && !text.startsWith('{')) return text;

  final category = json['category'];
  if (category is Map<String, dynamic>) {
    final nested = (category['image'] ?? category['image_url'] ?? '').toString().trim();
    return nested.isEmpty ? null : nested;
  }

  return null;
}


