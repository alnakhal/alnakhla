class CustomerOrder {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? orderNumber;
  final String? receiptNumber;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerLandmark;
  final String? deliveryArea;
  final double totalAmount;
  final double deliveryFee;
  final String status;
  final String? paymentMethod;
  final String? notes;
  final dynamic items;
  final String? userId;

  CustomerOrder({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.orderNumber,
    this.receiptNumber,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerLandmark,
    this.deliveryArea,
    required this.totalAmount,
    required this.deliveryFee,
    required this.status,
    this.paymentMethod,
    this.notes,
    this.items,
    this.userId,
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      orderNumber: json['order_number']?.toString(),
      receiptNumber: json['receipt_number']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      customerAddress: json['customer_address']?.toString(),
      customerLandmark: json['customer_landmark']?.toString(),
      deliveryArea: json['delivery_area']?.toString(),
      totalAmount: _readDouble(json['total_amount']),
      deliveryFee: _readDouble(json['delivery_fee']),
      status: json['status']?.toString() ?? 'قيد الانتظار',
      paymentMethod: json['payment_method']?.toString(),
      notes: json['notes']?.toString(),
      items: json['items'],
      userId: json['user_id']?.toString(),
    );
  }

  static double _readDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (orderNumber != null) 'order_number': orderNumber,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (customerLandmark != null) 'customer_landmark': customerLandmark,
      if (deliveryArea != null) 'delivery_area': deliveryArea,
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'status': status,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
      if (items != null) 'items': items,
      if (userId != null) 'user_id': userId,
    };
  }
}
