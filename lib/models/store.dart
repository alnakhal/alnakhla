class Store {
  Store({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    required this.createdAt,
  });

  factory Store.fromMap(Map<String, dynamic> m) => Store(
        id: m['id']?.toString() ?? '',
        userId: m['user_id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        slug: m['slug']?.toString() ?? '',
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  final String id;
  final String userId;
  final String name;
  final String slug;
  final DateTime createdAt;
}
