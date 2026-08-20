import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/customer_orders_db.dart';
import '../models/customer_order_model.dart';

class CustomerOrdersTrackingPage extends StatefulWidget {
  const CustomerOrdersTrackingPage({super.key});

  @override
  State<CustomerOrdersTrackingPage> createState() =>
      _CustomerOrdersTrackingPageState();
}

class _CustomerOrdersTrackingPageState
    extends State<CustomerOrdersTrackingPage> {
  late Future<List<CustomerOrderModel>> _ordersFuture;
  String _filterStatus =
      'all'; // all, pending, confirmed, shipped, delivered, cancelled

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = CustomerOrdersDatabase.instance.getAllOrders(
      filterStatus: _filterStatus == 'all' ? null : _filterStatus,
    );
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await CustomerOrdersDatabase.instance.updateOrderStatus(
        orderId,
        newStatus,
      );
      setState(() => _loadOrders());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث حالة الطلب إلى ${_getStatusArabic(newStatus)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  String _getStatusArabic(String status) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة الطلبات'), elevation: 0),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFilterChip('all', 'الكل'),
                _buildFilterChip('pending', 'قيد الانتظار'),
                _buildFilterChip('confirmed', 'مؤكد'),
                _buildFilterChip('shipped', 'قيد الشحن'),
                _buildFilterChip('delivered', 'تم التسليم'),
                _buildFilterChip('cancelled', 'ملغى'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Orders list
          Expanded(
            child: FutureBuilder<List<CustomerOrderModel>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      _filterStatus == 'all'
                          ? 'لا توجد طلبات بعد'
                          : 'لا توجد طلبات بهذه الحالة',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _filterStatus = status;
            _loadOrders();
          });
        },
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrderModel order) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'ar');
    final statusColor = _getStatusColor(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم الطلب: ${order.orderNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFmt.format(order.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        _getStatusArabic(order.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'إضافة أو تعديل تفاصيل الطلب',
                      onPressed: order.id == null
                          ? null
                          : () => _showEditOrderDialog(order),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                  Text(
                    'العميل: ${order.customerName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الهاتف: ${order.customerPhone}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'العنوان: ${order.customerAddress}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'التوصيل: ${order.deliveryAreaArabic}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أجور التوصيل: ${order.deliveryFee.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الدفع: ${order.paymentMethodArabic}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'حالة التسليم: ${order.deliveryResultArabic}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (order.receiptNumber != null &&
                      order.receiptNumber!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'رقم الوصل: ${order.receiptNumber}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إجمالي الطلب:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
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
                child: Text(
                  'ملاحظات: ${order.notes}',
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Status update buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (order.status != 'pending')
                  _buildStatusButton('pending', 'قيد الانتظار', order.id!),
                if (order.status != 'confirmed')
                  _buildStatusButton('confirmed', 'مؤكد', order.id!),
                if (order.status != 'shipped')
                  _buildStatusButton('shipped', 'قيد الشحن', order.id!),
                if (order.status != 'delivered')
                  _buildStatusButton('delivered', 'تم التسليم', order.id!),
                if (order.status != 'cancelled')
                  _buildStatusButton('cancelled', 'ملغى', order.id!),
              ],
            ),
          ],
        ),
      ),
    );
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

  Future<void> _showEditOrderDialog(CustomerOrderModel order) async {
    final addressController = TextEditingController(
      text: order.customerAddress,
    );
    final notesController = TextEditingController(text: order.notes ?? '');
    final receiptController = TextEditingController(
      text: order.receiptNumber ?? '',
    );
    final itemsController = TextEditingController(text: _itemsToText(order));
    final priceController = TextEditingController(
      text: order.totalAmount.toStringAsFixed(0),
    );
    var deliveryResult = order.deliveryResult;
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
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: deliveryResult,
                      decoration: const InputDecoration(
                        labelText: 'حالة التسليم',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('غير محدد'),
                        ),
                        DropdownMenuItem(
                          value: 'received',
                          child: Text('واصل'),
                        ),
                        DropdownMenuItem(
                          value: 'returned',
                          child: Text('راجع'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => deliveryResult = value);
                        }
                      },
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

    if (saved != true || order.id == null) {
      addressController.dispose();
      notesController.dispose();
      receiptController.dispose();
      itemsController.dispose();
      priceController.dispose();
      return;
    }

    try {
      await CustomerOrdersDatabase.instance.updateOrderDetails(
        id: order.id!,
        address: addressController.text.trim(),
        notes: notesController.text.trim(),
        receiptNumber: receiptController.text.trim(),
        items: _itemsFromText(itemsController.text),
        totalAmount: double.parse(priceController.text.trim()),
        deliveryResult: deliveryResult,
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
    } finally {
      addressController.dispose();
      notesController.dispose();
      receiptController.dispose();
      itemsController.dispose();
      priceController.dispose();
    }
  }

  Widget _buildStatusButton(String status, String label, int orderId) {
    final color = _getStatusColor(status);
    return OutlinedButton(
      onPressed: () => _updateOrderStatus(orderId, status),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
