import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_order_model.dart';
import '../services/customer_orders_supabase_service.dart';

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
  String _filterStatus =
      'all'; // all, pending, confirmed, shipped, delivered, cancelled

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = _ordersService.getMyOrders(
      filterStatus: _filterStatus == 'all' ? null : _filterStatus,
    );
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _requireLogin() async {
    if (_supabase.auth.currentUser != null) return;
    final loginPageBuilder = widget.loginPageBuilder;
    if (loginPageBuilder == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: loginPageBuilder),
    );
    if (mounted) setState(_loadOrders);
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _ordersService.updateOrderStatus(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الطلب: ${order.orderNumber}',
                        softWrap: true,
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
                      if (order.updatedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'تم التعديل ${dateFmt.format(order.updatedAt!)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: order.id == null ? null : order.status,
                      hint: const Text('الحالة'),
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      icon: Icon(Icons.arrow_drop_down, color: statusColor),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      items: orderStatuses
                          .map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(_getStatusArabic(status)),
                            ),
                          )
                          .toList(),
                      onChanged: order.id == null
                          ? null
                          : (newStatus) {
                              if (newStatus != null &&
                                  newStatus != order.status) {
                                _updateOrderStatus(order.id!, newStatus);
                              }
                            },
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
                  if (order.customerLandmark.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'أقرب نقطة دالة: ${order.customerLandmark}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
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
                (item) => Text(
                  '- ${item['name'] ?? ''} x${item['quantity'] ?? 1} '
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
            if (order.id != null)
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
    var deliveryResult = 'pending';
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
                      decoration: const InputDecoration(labelText: 'اسم الزبون'),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'أدخل اسم الزبون'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'رقم التلفون'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'أدخل رقم التلفون'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'عنوان الزبون'),
                      maxLines: 2,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'أدخل العنوان'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'أقرب نقطة دالة',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
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
                                        itemNameControllers[index].dispose();
                                        itemQuantityControllers[index].dispose();
                                        itemPriceControllers[index].dispose();
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
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: deliveryResult,
                      decoration: const InputDecoration(labelText: 'حالة الطلب'),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('غير محدد'),
                        ),
                        DropdownMenuItem(value: 'received', child: Text('واصل')),
                        DropdownMenuItem(value: 'returned', child: Text('راجع')),
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
        final orderNumber =
            'MAN-${DateTime.now().millisecondsSinceEpoch}';
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
            deliveryResult: deliveryResult,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر حفظ الطلب: $error')),
          );
        }
      }
    }

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    landmarkController.dispose();
    receiptController.dispose();
    notesController.dispose();
    for (final controller in itemNameControllers) {
      controller.dispose();
    }
    for (final controller in itemQuantityControllers) {
      controller.dispose();
    }
    for (final controller in itemPriceControllers) {
      controller.dispose();
    }
  }

  Future<void> _showEditOrderDialog(CustomerOrderModel order) async {
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
    var orderStatus = order.status;
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
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: orderStatus,
                      decoration: const InputDecoration(
                        labelText: 'حالة الطلب',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('قيد الانتظار'),
                        ),
                        DropdownMenuItem(
                          value: 'confirmed',
                          child: Text('مؤكد'),
                        ),
                        DropdownMenuItem(
                          value: 'shipped',
                          child: Text('قيد الشحن'),
                        ),
                        DropdownMenuItem(
                          value: 'delivered',
                          child: Text('تم التسليم'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('ملغى'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => orderStatus = value);
                        }
                      },
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
      landmarkController.dispose();
      notesController.dispose();
      receiptController.dispose();
      itemsController.dispose();
      priceController.dispose();
      return;
    }

    try {
      await _ordersService.updateOrderDetails(
        id: order.id!,
        status: orderStatus,
        address: addressController.text.trim(),
        landmark: landmarkController.text.trim(),
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
      landmarkController.dispose();
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
