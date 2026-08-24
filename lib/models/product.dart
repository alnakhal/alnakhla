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
    this.isHidden = false,
    this.imageUrl,
    this.storeId,
    this.deliveryPrice,
    this.baghdadDeliveryPrice,
    this.otherGovernoratesDeliveryPrice,
    this.pickupAvailable = false,
    this.category,
    this.sku,
    this.barcode,
    this.unit = 'قطعة',
    this.minimumStock = 0,
    this.discountPrice,
    this.brand,
    this.weight,
    this.dimensions,
    this.variants,
    this.internalNotes,
    this.imageUrls = const [],
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] is int
          ? (map['id'] as int)
          : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0,
      minWholesaleQuantity:
          (map['min_wholesale_quantity'] as num?)?.toInt() ?? 0,
      singlePrice: (map['single_price'] as num?)?.toDouble() ?? 0,
      hasWholesale: map['has_wholesale'] as bool? ?? false,
      remainingQty: (map['remaining_qty'] as num?)?.toInt() ?? 0,
      isHidden: map['is_hidden'] as bool? ?? false,
      imageUrl: map['image_url'] as String?,
      storeId: map['store_id']?.toString(),
      deliveryPrice: (map['delivery_price'] as num?)?.toDouble() ?? 0,
      baghdadDeliveryPrice: (map['baghdad_delivery_price'] as num?)?.toDouble(),
      otherGovernoratesDeliveryPrice:
          (map['other_governorates_delivery_price'] as num?)?.toDouble(),
      pickupAvailable: map['pickup_available'] as bool? ?? false,
      category: map['category'] as String?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      unit: map['unit'] as String? ?? 'قطعة',
      minimumStock: (map['minimum_stock'] as num?)?.toInt() ?? 0,
      discountPrice: (map['discount_price'] as num?)?.toDouble(),
      brand: map['brand'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      dimensions: map['dimensions'] as String?,
      variants: map['variants'] as String?,
      internalNotes: map['internal_notes'] as String?,
      imageUrls:
          (map['image_urls'] as List?)?.whereType<String>().toList() ??
          const [],
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
  final bool isHidden;
  final String? imageUrl;
  final String? storeId;
  final double? deliveryPrice;
  final double? baghdadDeliveryPrice;
  final double? otherGovernoratesDeliveryPrice;
  final bool pickupAvailable;
  final String? category;
  final String? sku;
  final String? barcode;
  final String unit;
  final int minimumStock;
  final double? discountPrice;
  final String? brand;
  final double? weight;
  final String? dimensions;
  final String? variants;
  final String? internalNotes;
  final List<String> imageUrls;
}

const productCategories = <String>[
  'أدوات مساج',
  'بوسترات جدارية',
  'أدوات حجامة',
  'أعشاب',
  'أخرى',
];

