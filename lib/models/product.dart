class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.cost,
    required this.wholesalePrice,
    required this.minWholesaleQuantity,
    required this.singlePrice,
    required this.hasWholesale,
    required this.remainingQty,
    this.imageUrl,
    this.storeId,
    this.deliveryPrice,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] is int ? (map['id'] as int) : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0,
      minWholesaleQuantity: (map['min_wholesale_quantity'] as num?)?.toInt() ?? 0,
      singlePrice: (map['single_price'] as num?)?.toDouble() ?? 0,
      hasWholesale: map['has_wholesale'] as bool? ?? false,
      remainingQty: (map['remaining_qty'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url'] as String?,
      storeId: map['store_id']?.toString(),
      deliveryPrice: (map['delivery_price'] as num?)?.toDouble() ?? 0,
    );
  }

  final int id;
  final String name;
  final String description;
  final double price;
  final double cost;
  final double wholesalePrice;
  final int minWholesaleQuantity;
  final double singlePrice;
  final bool hasWholesale;
  final int remainingQty;
  final String? imageUrl;
  final String? storeId;
  final double? deliveryPrice;
}
