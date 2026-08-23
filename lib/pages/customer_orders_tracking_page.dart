import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_order_model.dart';
import '../services/customer_orders_supabase_service.dart';

const _publicTrackingBaseUrl = 'https://alnakhal.github.io/alnakhla';

class CustomerOrdersTrackingPage extends StatefulWidget {
  const CustomerOrdersTrackingPage({super.key, this.loginPageBuilder});

  final WidgetBuilder? loginPageBuilder;

  @override
  State<CustomerOrdersTrackingPage> createState() =>
      _CustomerOrdersTrackingPageState();
}

class _CustomerOrdersTrackingPageState
    extends State<CustomerOrdersTrackingPage> {
  late Future<List<CustomerOrderModel>> _ordersFuture;
  final _ordersService = CustomerOrdersSupabaseService();
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = _ordersService.getMyOrders();
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _requireLogin() async {
    if (_supabase.auth.currentUser != null) return;
    final loginPageBuilder = widget.loginPageBuilder;
    if (loginPageBuilder == null) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: loginPageBuilder));
    if (mounted) setState(_loadOrders);
  }

  Future<void> _updateOrderStatus(
    CustomerOrderModel order,
    String newStatus,
  ) async {
    if (newStatus == order.status) return;
    if (!canTransitionOrderStatus(order.status, newStatus)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن نقل الطلب من ${orderStatusArabic(order.status)} إلى ${orderStatusArabic(newStatus)}',
          ),
        ),
      );
      return;
    }
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد تغيير الحالة'),
        content: Text(
          'هل تريد نقل الطلب إلى ${orderStatusArabic(newStatus)}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (shouldContinue != true) return;
    try {
      await _ordersService.updateOrderStatus(order.orderNumber, newStatus);
      if (!mounted) return;
      setState(_loadOrders);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة الطلب إلى ${_statusArabic(newStatus)}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث حالة الطلب: $error')),
      );
    }
  }

  String _statusArabic(String status) {
    return orderStatusArabic(status);
  }

  String _orderAgeLabel(CustomerOrderModel order) {
    final reference = order.updatedAt ?? order.createdAt;
    final elapsed = DateTime.now().difference(reference.toLocal());
    if (elapsed.inDays > 0) return 'منذ ${elapsed.inDays} يوم';
    if (elapsed.inHours > 0) return 'منذ ${elapsed.inHours} ساعة';
    if (elapsed.inMinutes > 0) return 'منذ ${elapsed.inMinutes} دقيقة';
    return 'منذ لحظات';
  }

  String _trackingUrl(String orderNumber, String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneLast4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits;
    return '$_publicTrackingBaseUrl/#/track-order?order=${Uri.encodeQueryComponent(orderNumber)}&phone=${Uri.encodeQueryComponent(phoneLast4)}';
  }

  Future<void> _copyTrackingLink(CustomerOrderModel order) async {
    await Clipboard.setData(
      ClipboardData(text: _trackingUrl(order.orderNumber, order.customerPhone)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رابط تتبع الطلب')),
    );
  }

  Future<void> _shareOrderAsImage(CustomerOrderModel order) async {
    final boundaryKey = GlobalKey();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: 0,
        child: RepaintBoundary(
          key: boundaryKey,
          child: _buildShareImage(order),
        ),
      ),
    );

    try {
      Overlay.of(context).insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('تعذر إنشاء صورة الطلب');
      final bytes = byteData.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: 'order-${order.orderNumber}.png',
            ),
          ],
          subject: 'تفاصيل الطلب ${order.orderNumber}',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر مشاركة صورة الطلب: $error')));
    } finally {
      entry.remove();
    }
  }

  Widget _buildShareImage(CustomerOrderModel order) {
    final itemRows = order.items ?? const <Map<String, dynamic>>[];
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Material(
        color: Colors.white,
        child: SizedBox(
          width: 900,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تفاصيل الطلب',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'مستلزمات النخلة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '077821215446',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                _shareInfoRow('رقم الطلب', order.orderNumber),
                _shareInfoRow('اسم الزبون', order.customerName),
                _shareInfoRow('رقم الهاتف', order.customerPhone),
                _shareInfoRow('العنوان', order.customerAddress),
                if (order.customerLandmark.isNotEmpty)
                  _shareInfoRow('أقرب نقطة دالة', order.customerLandmark),
                const SizedBox(height: 24),
                const Text(
                  'المنتجات',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  color: Colors.blueGrey.shade50,
                  child: const Row(
                    children: [
                      Expanded(flex: 5, child: Text('المنتج')),
                      Expanded(child: Text('العدد')),
                      Expanded(child: Text('السعر')),
                      Expanded(child: Text('المجموع')),
                    ],
                  ),
                ),
                ...itemRows.map((item) {
                  final name = item['name']?.toString() ?? '';
                  final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
                  final price = (item['price'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: Text(name)),
                        Expanded(child: Text(_formatNumber(quantity))),
                        Expanded(
                          child: Text('${price.toStringAsFixed(0)} د.ع'),
                        ),
                        Expanded(
                          child: Text(
                            '${(price * quantity).toStringAsFixed(0)} د.ع',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 28),
                _shareTotalRow('الإجمالي الكلي', order.totalAmount, bold: true),
                const SizedBox(height: 32),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green.shade700,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'تم التجهيز',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مستلزمات النخلة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shareInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text('$label: $value', style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _shareTotalRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 24 : 20,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value.toStringAsFixed(0)} د.ع', style: style),
        ],
      ),
    );
  }

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة الطلبات'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'إضافة طلب',
            icon: const Icon(Icons.add),
            onPressed: () async {
              if (_supabase.auth.currentUser == null) {
                await _requireLogin();
                return;
              }
              await _showAddOrderDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                labelText: 'بحث في الطلبات',
                hintText: 'رقم الطلب أو اسم العميل أو رقم الهاتف',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح البحث',
                        onPressed: () => setState(() => _searchQuery = ''),
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          // Orders list
          Expanded(
            child: FutureBuilder<List<CustomerOrderModel>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (_supabase.auth.currentUser == null) {
                  return Center(
                    child: FilledButton.icon(
                      onPressed: _requireLogin,
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل الدخول لمتابعة الطلبات'),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                final orders = snapshot.data ?? [];
                final filteredOrders = orders.where((order) {
                  if (_searchQuery.isEmpty) return true;
                  return order.orderNumber.toLowerCase().contains(
                        _searchQuery,
                      ) ||
                      order.customerName.toLowerCase().contains(_searchQuery) ||
                      order.customerPhone.toLowerCase().contains(_searchQuery);
                }).where((order) {
                  return _selectedStatusFilter == 'all' ||
                      order.status == _selectedStatusFilter;
                }).toList()
                  ..sort(
                    (a, b) => _sortNewestFirst
                        ? b.createdAt.compareTo(a.createdAt)
                        : a.createdAt.compareTo(b.createdAt),
                  );
                final ordersByStatus = <String, List<CustomerOrderModel>>{
                  for (final status in orderStatuses)
                    status: filteredOrders
                        .where((order) => order.status == status)
                        .toList(),
                };
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatusFilter,
                              decoration: const InputDecoration(
                                labelText: 'فلتر الحالة',
                                prefixIcon: Icon(Icons.filter_alt_outlined),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('كل الحالات'),
                                ),
                                ...orderStatuses.map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(_statusArabic(status)),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedStatusFilter = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: _sortNewestFirst
                                ? 'ترتيب من الأقدم'
                                : 'ترتيب من الأحدث',
                            onPressed: () =>
                                setState(() => _sortNewestFirst = !_sortNewestFirst),
                            icon: Icon(
                              _sortNewestFirst
                                  ? Icons.south_outlined
                                  : Icons.north_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'لا توجد نتائج مطابقة للبحث'
                                    : 'لا توجد طلبات بعد',
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final status in orderStatuses)
                                    _buildStatusColumn(
                                      status,
                                      ordersByStatus[status]!,
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusColumn(String status, List<CustomerOrderModel> orders) {
    final color = _statusColor(status);
    return Container(
      width: 350,
      margin: const EdgeInsetsDirectional.only(end: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _statusArabic(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${orders.length} طلب',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('لا توجد طلبات'))
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: orders.map(_buildOrderCard).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
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

  Widget _buildOrderCard(CustomerOrderModel order) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'ar');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCopyableText(
                          'رقم الطلب: ${order.orderNumber}',
                          order.orderNumber,
                          softWrap: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildCopyableText(
                          dateFmt.format(order.createdAt),
                          dateFmt.format(order.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        if (order.updatedAt != null) ...[
                          const SizedBox(height: 4),
                          _buildCopyableText(
                            'تم التعديل ${dateFmt.format(order.updatedAt!)}',
                            dateFmt.format(order.updatedAt!),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'مدة الحالة الحالية: ${_orderAgeLabel(order)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'مشاركة الطلب كصورة',
                    onPressed: () => _shareOrderAsImage(order),
                    icon: const Icon(Icons.share_outlined),
                  ),
                  IconButton(
                    tooltip: 'نسخ رابط التتبع',
                    onPressed: () => _copyTrackingLink(order),
                    icon: const Icon(Icons.link_outlined),
                  ),
                  IconButton(
                    tooltip: 'تعديل الطلب',
                    onPressed: () => _showEditOrderDialog(order),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: orderStatuses.contains(order.status)
                    ? order.status
                    : null,
                decoration: const InputDecoration(
                  labelText: 'حالة الطلب',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                  isDense: true,
                ),
                items: orderStatuses
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(_statusArabic(status)),
                      ),
                    )
                    .toList(),
                onChanged: (newStatus) {
                  if (newStatus != null) {
                    _updateOrderStatus(order, newStatus);
                  }
                },
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 4),
              // Customer info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCopyableText(
                      'العميل: ${order.customerName}',
                      order.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    _buildCopyableText(
                      'الهاتف: ${order.customerPhone}',
                      order.customerPhone,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    _buildCopyableText(
                      'العنوان: ${order.customerAddress}',
                      order.customerAddress,
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (order.customerLandmark.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildCopyableText(
                        'أقرب نقطة دالة: ${order.customerLandmark}',
                        order.customerLandmark,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (order.receiptNumber != null &&
                        order.receiptNumber!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildCopyableText(
                        'رقم الوصل: ${order.receiptNumber}',
                        order.receiptNumber!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (order.items != null && order.items!.isNotEmpty) ...[
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'المواد المطلوبة:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 4),
                ...order.items!.map(
                  (item) => _buildCopyableText(
                    '- ${item['name'] ?? ''} x${item['quantity'] ?? 1} '
                        '(${((item['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} د.ع)',
                    '${item['name'] ?? ''} x${item['quantity'] ?? 1} '
                        '(${((item['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} د.ع)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إجمالي الطلب:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  _buildCopyableText(
                    '${order.totalAmount.toStringAsFixed(0)} د.ع',
                    '${order.totalAmount.toStringAsFixed(0)} د.ع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildCopyableText(
                    'ملاحظات: ${order.notes}',
                    order.notes!,
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyableText(
    String displayText,
    String copyText, {
    TextStyle? style,
    bool softWrap = true,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(displayText, softWrap: softWrap, style: style),
        ),
        IconButton(
          tooltip: 'نسخ',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: const Icon(Icons.copy_outlined, size: 16),
          onPressed: () => _copyOrderText(copyText),
        ),
      ],
    );
  }

  Future<void> _copyOrderText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ المعلومات')));
  }

  String _itemsToText(CustomerOrderModel order) {
    return (order.items ?? const <Map<String, dynamic>>[])
        .map((item) {
          final name = item['name']?.toString() ?? '';
          final quantity = item['quantity']?.toString() ?? '1';
          return '$name x$quantity';
        })
        .join('\n');
  }

  List<Map<String, dynamic>> _itemsFromText(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(
          (line) => <String, dynamic>{'name': line, 'quantity': 1, 'price': 0},
        )
        .toList();
  }

  Future<void> _showAddOrderDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final landmarkController = TextEditingController();
    final receiptController = TextEditingController();
    final notesController = TextEditingController();
    final itemNameControllers = [TextEditingController()];
    final itemQuantityControllers = [TextEditingController(text: '1')];
    final itemPriceControllers = [TextEditingController()];
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة طلب جديد'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الزبون',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل اسم الزبون'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم التلفون',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل رقم التلفون'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الزبون',
                      ),
                      maxLines: 2,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل العنوان'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'أقرب نقطة دالة',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل أقرب نقطة دالة'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: receiptController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الوصل',
                        hintText: 'أدخل رقم الوصل يدويًا',
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'المواد المطلوبة والأسعار',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(itemNameControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: itemNameControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'المادة',
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'أدخل المادة'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: itemQuantityControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'العدد',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    int.tryParse(value?.trim() ?? '') == null
                                    ? 'العدد'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: itemPriceControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'السعر',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) =>
                                    double.tryParse(value?.trim() ?? '') == null
                                    ? 'السعر'
                                    : null,
                              ),
                            ),
                            IconButton(
                              tooltip: 'حذف المادة',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: itemNameControllers.length == 1
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        itemNameControllers.removeAt(index);
                                        itemQuantityControllers.removeAt(index);
                                        itemPriceControllers.removeAt(index);
                                      });
                                    },
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            itemNameControllers.add(TextEditingController());
                            itemQuantityControllers.add(
                              TextEditingController(text: '1'),
                            );
                            itemPriceControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة مادة'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'ملاحظات'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('حفظ الطلب'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final items = List.generate(
        itemNameControllers.length,
        (index) => <String, dynamic>{
          'name': itemNameControllers[index].text.trim(),
          'quantity': int.parse(itemQuantityControllers[index].text.trim()),
          'price': double.parse(itemPriceControllers[index].text.trim()),
        },
      );
      final totalAmount = items.fold<double>(
        0,
        (sum, item) =>
            sum + (item['quantity'] as int) * (item['price'] as double),
      );
      try {
        final orderNumber = 'MAN-${DateTime.now().millisecondsSinceEpoch}';
        await _ordersService.insertOrder(
          CustomerOrderModel(
            orderNumber: orderNumber,
            customerName: nameController.text.trim(),
            customerPhone: phoneController.text.trim(),
            customerAddress: addressController.text.trim(),
            customerLandmark: landmarkController.text.trim(),
            receiptNumber: receiptController.text.trim().isEmpty
                ? null
                : receiptController.text.trim(),
            totalAmount: totalAmount,
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
            items: items,
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) {
          setState(_loadOrders);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة الطلب بنجاح')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('تعذر حفظ الطلب: $error')));
        }
      }
    }
  }

  Future<void> _showEditOrderDialog(CustomerOrderModel order) async {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'ar');
    final nameController = TextEditingController(text: order.customerName);
    final phoneController = TextEditingController(text: order.customerPhone);
    final addressController = TextEditingController(
      text: order.customerAddress,
    );
    final landmarkController = TextEditingController(
      text: order.customerLandmark,
    );
    final notesController = TextEditingController(text: order.notes ?? '');
    final receiptController = TextEditingController(
      text: order.receiptNumber ?? '',
    );
    final itemsController = TextEditingController(text: _itemsToText(order));
    final priceController = TextEditingController(
      text: order.totalAmount.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تفاصيل الطلب'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOrderDetail('رقم الطلب', order.orderNumber),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الزبون',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل اسم الزبون'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم التلفون',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل رقم التلفون'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _buildOrderDetail(
                      'تاريخ الإنشاء',
                      dateFmt.format(order.createdAt),
                    ),
                    if (order.updatedAt != null)
                      _buildOrderDetail(
                        'آخر تعديل',
                        dateFmt.format(order.updatedAt!),
                      ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'العنوان'),
                      maxLines: 2,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'أدخل العنوان'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'أقرب نقطة دالة',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'الملاحظات'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: receiptController,
                      decoration: const InputDecoration(labelText: 'رقم الوصل'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: itemsController,
                      decoration: const InputDecoration(
                        labelText: 'محتويات الطلب',
                        hintText: 'اكتب كل منتج في سطر مستقل',
                      ),
                      minLines: 2,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'السعر الكلي',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          double.tryParse(value?.trim() ?? '') == null
                          ? 'أدخل سعرًا صحيحًا'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      return;
    }
    if (order.orderNumber.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تعديل الطلب: رقم الطلب غير موجود'),
          ),
        );
      }
      return;
    }

    try {
      await _ordersService.updateOrderDetails(
        orderNumber: order.orderNumber,
        customerName: nameController.text.trim(),
        customerPhone: phoneController.text.trim(),
        address: addressController.text.trim(),
        landmark: landmarkController.text.trim(),
        notes: notesController.text.trim(),
        receiptNumber: receiptController.text.trim(),
        items: _itemsFromText(itemsController.text),
        totalAmount: double.parse(priceController.text.trim()),
        deliveryResult: order.deliveryResult,
      );
      if (!mounted) return;
      setState(_loadOrders);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ تفاصيل الطلب')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ تفاصيل الطلب: $error')),
        );
      }
    }
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
