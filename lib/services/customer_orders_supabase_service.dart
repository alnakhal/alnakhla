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
            (row) =>
                CustomerOrder.fromJson(Map<String, dynamic>.from(row as Map)),
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
    var query = _client.from('customer_orders').select().eq('user_id', user.id);
    if (filterStatus != null) {
      query = query.eq('status', filterStatus);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map(
          (row) =>
              CustomerOrderModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> insertOrder(CustomerOrderModel order) async {
    final data = order.toMap()..remove('id');
    final user = _client.auth.currentUser;
    if (user != null) data['user_id'] = user.id;
    if (user == null) data.remove('user_id');
    await _client.from('customer_orders').insert(data);
  }

  Future<void> updateOrderStatus(String orderNumber, String newStatus) async {
    if (!orderStatuses.contains(newStatus)) {
      throw ArgumentError('حالة طلب غير صالحة: $newStatus');
    }
    final user = _requireUser();
    await _client.rpc(
      'update_customer_order_status_with_inventory',
      params: {'p_order_number': orderNumber, 'p_new_status': newStatus},
    );
    await _client.from('order_audit_log').insert({
      'order_number': orderNumber,
      'user_id': user.id,
      'action': 'status_changed',
      'details': {'status': newStatus},
    });
  }

  Future<void> updateOrderDetails({
    required String orderNumber,
    required String customerName,
    required String customerPhone,
    required String address,
    required String landmark,
    required String notes,
    required String receiptNumber,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryResult,
  }) async {
    if (!['pending', 'received', 'returned'].contains(deliveryResult)) {
      throw ArgumentError('نتيجة تسليم غير صالحة: $deliveryResult');
    }
    final user = _requireUser();
    final updatedRows = await _client
        .from('customer_orders')
        .update({
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_address': address,
          'customer_landmark': landmark,
          'notes': notes.isEmpty ? null : notes,
          'receipt_number': receiptNumber.isEmpty ? null : receiptNumber,
          'items': items,
          'total_amount': totalAmount,
          'delivery_result': deliveryResult,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('order_number', orderNumber)
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

  Future<Map<String, dynamic>?> getPublicOrderTracking(
    String orderNumber,
  ) async {
    final response = await _client.rpc(
      'get_public_order_tracking',
      params: {'p_order_number': orderNumber},
    );
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map<String, dynamic>) return response;
    return null;
  }

  RealtimeChannel subscribeToPublicOrderTracking(
    String orderNumber,
    void Function(Map<String, dynamic> order) onUpdate,
  ) {
    final channel = _client.channel('public-order-tracking:$orderNumber');
    channel
        .onBroadcast(
          event: 'status_changed',
          callback: (payload) {
            final record = payload['record'];
            if (record is Map) {
              onUpdate(Map<String, dynamic>.from(record));
            }
          },
        )
        .subscribe();
    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
