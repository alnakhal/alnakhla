/// نموذج صورة السلايدر
class SliderImage {
  final int? id;
  final String imageData; // base64 encoded image
  final String title;
  final String createdAt;

  SliderImage({
    this.id,
    required this.imageData,
    required this.title,
    required this.createdAt,
  });

  factory SliderImage.fromMap(Map<String, dynamic> map) {
    return SliderImage(
      id: map['id'],
      imageData: map['image_data'] ?? '',
      title: map['title'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_data': imageData,
      'title': title,
      'created_at': createdAt,
    };
  }
}

/// نموذج صورة القسم
class CategoryImage {
  final int? id;
  final String imageData; // base64 encoded image
  final String categoryName;
  final String productKeywords;
  final String createdAt;

  CategoryImage({
    this.id,
    required this.imageData,
    required this.categoryName,
    required this.productKeywords,
    required this.createdAt,
  });

  List<String> get keywordsList => productKeywords.split(',');

  factory CategoryImage.fromMap(Map<String, dynamic> map) {
    return CategoryImage(
      id: map['id'],
      imageData: map['image_data'] ?? '',
      categoryName: map['category_name'] ?? '',
      productKeywords: map['product_keywords'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_data': imageData,
      'category_name': categoryName,
      'product_keywords': productKeywords,
      'created_at': createdAt,
    };
  }
}
