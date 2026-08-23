import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/customer_orders_supabase_service.dart';
import '../models/customer_order_model.dart';

const _publicTrackingBaseUrl = 'https://alnakhal.github.io/alnakhla';
const _storePhoneNumber = '+9647746582364';

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
  bool _isRealtimeActive = false;
  DateTime? _lastSyncedAt;
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
    if (orderNumber.length < 4) {
      _clearTrackingChannel();
      setState(() {
        _order = null;
        _errorMessage = 'تحقق من رقم الطلب وأعد المحاولة';
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
        _lastSyncedAt = order == null ? null : DateTime.now();
        _isRealtimeActive = false;
        _errorMessage = order == null ? 'لم يتم العثور على هذا الطلب' : null;
      });
      _subscribeToOrder(orderNumber);
    } catch (error) {
      if (!mounted) return;
      _clearTrackingChannel();
      setState(() {
        _order = null;
        _errorMessage = 'تعذر تحميل حالة الطلب. تحقق من الاتصال وأعد المحاولة';
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
        final history = [
          ...((_order?['status_history'] as List?) ?? const []),
          {
            'status': updatedOrder['status'],
            'changed_at': updatedOrder['updated_at'],
          },
        ];
        setState(
          () =>
              _order = {...?_order, ...updatedOrder, 'status_history': history},
        );
        setState(() {
          _isRealtimeActive = true;
          _lastSyncedAt = DateTime.now();
        });
      },
    );
    if (mounted) {
      setState(() => _isRealtimeActive = true);
    }
  }

  String _statusArabic(String? status) {
    return status == null ? 'غير محدد' : orderStatusArabic(status);
  }

  String? _exceptionMessage(String? status) {
    switch (status) {
      case 'cancelled':
      case 'cancelled_company':
        return 'تم إلغاء هذا الطلب. تواصل معنا لمعرفة التفاصيل أو إنشاء طلب جديد.';
      case 'returned':
        return 'تمت إعادة هذا الطلب إلى المخزن. تواصل معنا لمعرفة سبب الإرجاع.';
      default:
        return null;
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

  List<String> _statusSteps(String? status) {
    if (status == 'cancelled' || status == 'cancelled_company') {
      return ['pending', 'confirmed', 'cancelled_company'];
    }
    if (status == 'returned') {
      return ['pending', 'confirmed', 'shipped', 'returned'];
    }
    return ['pending', 'confirmed', 'shipped', 'delivered'];
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.inventory_2_outlined;
      case 'confirmed':
        return Icons.fact_check_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.home_outlined;
      case 'cancelled_company':
        return Icons.cancel_outlined;
      case 'returned':
        return Icons.assignment_return_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildStatusTimeline(String? currentStatus, List<dynamic> history) {
    final steps = _statusSteps(currentStatus);
    final currentIndex = currentStatus == null
        ? -1
        : steps.indexOf(currentStatus);
    final activeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= activeIndex
                          ? _statusColor(steps[index])
                          : Colors.grey.shade200,
                    ),
                    child: Icon(
                      _statusIcon(steps[index]),
                      size: 18,
                      color: index <= activeIndex
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 34,
                      color: index < activeIndex
                          ? _statusColor(steps[index])
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusArabic(steps[index]),
                      style: TextStyle(
                        fontWeight: index == activeIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: index <= activeIndex
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (index <= activeIndex)
                      for (final entry in history)
                        if (entry is Map &&
                            entry['status']?.toString() == steps[index] &&
                            _formatDate(entry['changed_at']).isNotEmpty)
                          Text(
                            _formatDate(entry['changed_at']),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatAmount(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return '${amount.toStringAsFixed(0)} د.ع';
  }

  String _paymentMethodArabic(String? method) {
    switch (method) {
      case 'cash_on_delivery':
        return 'الدفع عند الاستلام';
      case 'online':
      case 'online_payment':
        return 'دفع إلكتروني';
      default:
        return method ?? 'غير محدد';
    }
  }

  String _deliveryAreaArabic(String? area) {
    switch (area) {
      case 'baghdad':
        return 'بغداد';
      case 'pickup':
        return 'استلام من المتجر';
      case 'other_governorates':
        return 'باقي المحافظات';
      default:
        return area ?? 'غير محدد';
    }
  }

  Widget _buildOrderSummary(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _summaryRow('عدد المنتجات', '${order['items_count'] ?? 0}'),
          _summaryRow(
            'طريقة الدفع',
            _paymentMethodArabic(order['payment_method']?.toString()),
          ),
          _summaryRow(
            'منطقة التوصيل',
            _deliveryAreaArabic(order['delivery_area']?.toString()),
          ),
          _summaryRow('رسوم التوصيل', _formatAmount(order['delivery_fee'])),
          _summaryRow(
            'الإجمالي الكلي',
            _formatAmount(order['total_amount']),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }

  String _trackingUrl(String orderNumber) {
    return '$_publicTrackingBaseUrl/#/track-order?order=${Uri.encodeQueryComponent(orderNumber)}';
  }

  Future<void> _copyOrderNumber(String orderNumber) async {
    await Clipboard.setData(ClipboardData(text: orderNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ رقم الطلب')));
  }

  Future<void> _shareTrackingLink(String orderNumber) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'يمكنك متابعة الطلب $orderNumber عبر الرابط:\n${_trackingUrl(orderNumber)}',
        subject: 'رابط تتبع الطلب $orderNumber',
      ),
    );
  }

  Future<void> _openStoreContact({required bool whatsapp}) async {
    final uri = whatsapp
        ? Uri.parse('https://wa.me/${_storePhoneNumber.substring(1)}')
        : Uri.parse('tel:$_storePhoneNumber');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح وسيلة التواصل')));
    }
  }

  Widget _buildOrderActions(String orderNumber) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _copyOrderNumber(orderNumber),
          icon: const Icon(Icons.copy_outlined),
          label: const Text('نسخ الرقم'),
        ),
        OutlinedButton.icon(
          onPressed: () => _shareTrackingLink(orderNumber),
          icon: const Icon(Icons.share_outlined),
          label: const Text('مشاركة الرابط'),
        ),
        OutlinedButton.icon(
          onPressed: () => _openStoreContact(whatsapp: true),
          icon: const Icon(Icons.chat_outlined),
          label: const Text('واتساب'),
        ),
        OutlinedButton.icon(
          onPressed: () => _openStoreContact(whatsapp: false),
          icon: const Icon(Icons.phone_outlined),
          label: const Text('اتصال'),
        ),
        TextButton.icon(
          onPressed: _isLoading ? null : () => _loadOrder(orderNumber),
          icon: const Icon(Icons.refresh),
          label: const Text('تحديث'),
        ),
      ],
    );
  }

  String _syncLabel() {
    if (_lastSyncedAt == null) return 'بانتظار التحديث';
    final time = _formatDate(_lastSyncedAt);
    return _isRealtimeActive ? 'تحديث تلقائي • $time' : 'آخر مزامنة • $time';
  }

  Future<void> _refreshOrder() async {
    final orderNumber = _orderNumberController.text.trim();
    if (orderNumber.isEmpty) {
      return;
    }
    await _loadOrder(orderNumber);
  }

  Widget _buildLoadingPlaceholder() {
    Widget placeholder({double height = 18}) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            placeholder(),
            const SizedBox(height: 18),
            placeholder(height: 100),
            const SizedBox(height: 18),
            placeholder(height: 150),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?['status']?.toString();
    final color = _statusColor(status);
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الطلب')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: RefreshIndicator(
            onRefresh: _refreshOrder,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
                    if (_isLoading && _order == null) ...[
                      const SizedBox(height: 24),
                      _buildLoadingPlaceholder(),
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
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    _isRealtimeActive
                                        ? Icons.cloud_done_outlined
                                        : Icons.cloud_off_outlined,
                                    size: 16,
                                    color: _isRealtimeActive
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _syncLabel(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                              if (_exceptionMessage(status) != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.red.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_exceptionMessage(status)!),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _buildStatusTimeline(
                                status,
                                (_order!['status_history'] as List?) ??
                                    const [],
                              ),
                              const SizedBox(height: 16),
                              _buildOrderSummary(_order!),
                              const SizedBox(height: 16),
                              _buildOrderActions(
                                _order!['order_number'].toString(),
                              ),
                              const SizedBox(height: 16),
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
        ),
      ),
    );
  }
}
