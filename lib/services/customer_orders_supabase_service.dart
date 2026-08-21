import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/customer_order.dart';
import '../models/customer_order_model.dart';

class CustomerOrdersSupabaseService {
  CustomerOrdersSupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<CustomerOrder>> fetchOrders() async {
    try {
      final response = await _client
          .from('customer_orders')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (row) => CustomerOrder.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('يرجى تسجيل الدخول أولاً');
    }
    return user;
  }

  Future<List<CustomerOrderModel>> getMyOrders({String? filterStatus}) async {
    final user = _requireUser();
    var query = _client
        .from('customer_orders')
        .select()
        .eq('user_id', user.id);
    if (filterStatus != null) {
      query = query.eq('status', filterStatus);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((row) => CustomerOrderModel.fromMap(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  }

  Future<void> insertOrder(CustomerOrderModel order) async {
    final user = _requireUser();
    final data = order.toMap()
      ..remove('id')
      ..['user_id'] = user.id;
    await _client.from('customer_orders').insert(data);
  }

  Future<void> updateOrderStatus(int id, String newStatus) async {
    if (!orderStatuses.contains(newStatus)) {
      throw ArgumentError('حالة طلب غير صالحة: $newStatus');
    }
    final user = _requireUser();
    final updatedRows = await _client
        .from('customer_orders')
        .update({
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', user.id)
        .select('id');
    if (updatedRows.isEmpty) {
      throw StateError('لم يتم العثور على الطلب أو لا تملك صلاحية تعديله');
    }
  }

  Future<void> updateOrderDetails({
    required int id,
    required String status,
    required String address,
    required String landmark,
    required String notes,
    required String receiptNumber,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryResult,
  }) async {
    if (!orderStatuses.contains(status)) {
      throw ArgumentError('حالة طلب غير صالحة: $status');
    }
    if (!['pending', 'received', 'returned'].contains(deliveryResult)) {
      throw ArgumentError('نتيجة تسليم غير صالحة: $deliveryResult');
    }
    final user = _requireUser();
    final updatedRows = await _client
        .from('customer_orders')
        .update({
          'status': status,
          'customer_address': address,
          'customer_landmark': landmark,
          'notes': notes.isEmpty ? null : notes,
          'receipt_number': receiptNumber.isEmpty ? null : receiptNumber,
          'items': items,
          'total_amount': totalAmount,
          'delivery_result': deliveryResult,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', user.id)
        .select('id');
    if (updatedRows.isEmpty) {
      throw StateError('لم يتم العثور على الطلب أو لا تملك صلاحية تعديله');
    }
  }

  Future<CustomerOrderModel?> getMyOrderByNumber(String orderNumber) async {
    final user = _requireUser();
    final row = await _client
        .from('customer_orders')
        .select()
        .eq('user_id', user.id)
        .eq('order_number', orderNumber)
        .maybeSingle();
    if (row == null) return null;
    return CustomerOrderModel.fromMap(Map<String, dynamic>.from(row));
  }
}
