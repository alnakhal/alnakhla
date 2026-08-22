import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/customer_orders_supabase_service.dart';

class PublicOrderTrackingPage extends StatefulWidget {
  const PublicOrderTrackingPage({super.key, this.initialOrderNumber});

  final String? initialOrderNumber;

  @override
  State<PublicOrderTrackingPage> createState() =>
      _PublicOrderTrackingPageState();
}

class _PublicOrderTrackingPageState extends State<PublicOrderTrackingPage> {
  final _orderNumberController = TextEditingController();
  final _ordersService = CustomerOrdersSupabaseService();
  Map<String, dynamic>? _order;
  RealtimeChannel? _trackingChannel;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final orderNumber = widget.initialOrderNumber?.trim() ?? '';
    _orderNumberController.text = orderNumber;
    if (orderNumber.isNotEmpty) {
      _loadOrder(orderNumber);
    }
  }

  @override
  void dispose() {
    final channel = _trackingChannel;
    if (channel != null) {
      _ordersService.removeChannel(channel);
    }
    _orderNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder(String value) async {
    final orderNumber = value.trim().toUpperCase();
    if (orderNumber.isEmpty) {
      _clearTrackingChannel();
      setState(() {
        _order = null;
        _errorMessage = 'أدخل رقم الطلب';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final order = await _ordersService.getPublicOrderTracking(orderNumber);
      if (!mounted) return;
      setState(() {
        _order = order;
        _errorMessage = order == null ? 'لم يتم العثور على هذا الطلب' : null;
      });
      _subscribeToOrder(orderNumber);
    } catch (error) {
      if (!mounted) return;
      _clearTrackingChannel();
      setState(() {
        _order = null;
        _errorMessage = 'تعذر تحميل حالة الطلب: $error';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearTrackingChannel() {
    final channel = _trackingChannel;
    if (channel != null) {
      _ordersService.removeChannel(channel);
      _trackingChannel = null;
    }
  }

  void _subscribeToOrder(String orderNumber) {
    _clearTrackingChannel();
    if (_order == null) {
      return;
    }
    _trackingChannel = _ordersService.subscribeToPublicOrderTracking(
      orderNumber,
      (updatedOrder) {
        if (!mounted) return;
        setState(() => _order = {...?_order, ...updatedOrder});
      },
    );
  }

  String _statusArabic(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد التجهيز';
      case 'confirmed':
        return 'مؤكد';
      case 'shipped':
        return 'قيد الشحن';
      case 'delivered':
        return 'تم الاستلام';
      case 'cancelled':
      case 'cancelled_company':
        return 'ملغي';
      case 'returned':
        return 'راجع إلى المخزن';
      default:
        return status ?? 'غير محدد';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'confirmed':
        return Colors.blue.shade700;
      case 'shipped':
        return Colors.deepOrange.shade700;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
      case 'cancelled_company':
      case 'returned':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?['status']?.toString();
    final color = _statusColor(status);
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الطلب')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.local_shipping_outlined, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'أدخل رقم طلبك لمعرفة آخر حالة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _orderNumberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'رقم الطلب',
                    hintText: 'MAN-1787315674467',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _loadOrder,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _loadOrder(_orderNumberController.text),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('عرض حالة الطلب'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (_order != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'طلب رقم ${_order!['order_number']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              border: Border.all(color: color),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _statusArabic(status),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_formatDate(
                                  _order!['updated_at'],
                                ).isNotEmpty)
                                  Text(
                                    'آخر تحديث: ${_formatDate(_order!['updated_at'])}',
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'تاريخ الطلب: ${_formatDate(_order!['created_at'])}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
