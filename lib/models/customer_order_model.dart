class CustomerOrderModel {
  final int? id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double totalAmount;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final String paymentMethod;
  final String deliveryArea;
  final double deliveryFee;
  final String? receiptNumber;
  final String deliveryResult;
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
    this.paymentMethod = 'cash_on_delivery',
    this.deliveryArea = 'baghdad',
    this.deliveryFee = 0,
    this.receiptNumber,
    this.deliveryResult = 'pending',
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
    'payment_method': paymentMethod,
    'delivery_area': deliveryArea,
    'delivery_fee': deliveryFee,
    'receipt_number': receiptNumber,
    'delivery_result': deliveryResult,
    'notes': notes,
    'items': items,
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
      paymentMethod: map['payment_method']?.toString() ?? 'cash_on_delivery',
      deliveryArea: map['delivery_area']?.toString() ?? 'baghdad',
      deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
      receiptNumber: map['receipt_number']?.toString(),
      deliveryResult: map['delivery_result']?.toString() ?? 'pending',
      notes: map['notes']?.toString(),
      items: _readItems(map),
      createdAt: map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(
              map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
            ),
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] is DateTime
                ? map['updated_at'] as DateTime
                : DateTime.parse(map['updated_at'].toString()))
          : null,
    );
  }

  static List<Map<String, dynamic>>? _readItems(Map<String, dynamic> map) {
    final rawItems = map['items'];
    if (rawItems is! List) return null;
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  String get paymentMethodArabic => paymentMethod == 'cash_on_delivery'
      ? 'الدفع عند الاستلام'
      : 'دفع إلكتروني';

  String get deliveryAreaArabic {
    switch (deliveryArea) {
      case 'pickup':
        return 'استلام من المتجر';
      case 'other_governorates':
        return 'باقي المحافظات';
      case 'baghdad':
        return 'بغداد';
      default:
        return deliveryArea;
    }
  }

  String get deliveryResultArabic {
    switch (deliveryResult) {
      case 'received':
        return 'واصل';
      case 'returned':
        return 'راجع';
      default:
        return 'غير محدد';
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
