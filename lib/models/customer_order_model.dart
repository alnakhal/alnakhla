class CustomerOrderModel {
  final int? id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double totalAmount;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final String? notes;
  final List<Map<String, dynamic>>? items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomerOrderModel({
    this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.totalAmount,
    this.status = 'pending',
    this.notes,
    this.items,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'order_number': orderNumber,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'total_amount': totalAmount,
        'status': status,
        'notes': notes,
        'items_json': items != null ? items.toString() : null,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory CustomerOrderModel.fromMap(Map<String, dynamic> map) {
    return CustomerOrderModel(
      id: map['id'] as int?,
      orderNumber: map['order_number']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? '',
      customerPhone: map['customer_phone']?.toString() ?? '',
      customerAddress: map['customer_address']?.toString() ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'pending',
      notes: map['notes']?.toString(),
      items: map['items'] is List
          ? List<Map<String, dynamic>>.from(map['items'] as List)
          : null,
      createdAt: map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at']?.toString() ??
              DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] is DateTime
              ? map['updated_at'] as DateTime
              : DateTime.parse(map['updated_at'].toString()))
          : null,
    );
  }

  String get statusArabic {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'shipped':
        return 'قيد الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }
}

const orderStatuses = [
  'pending',
  'confirmed',
  'shipped',
  'delivered',
  'cancelled',
];
