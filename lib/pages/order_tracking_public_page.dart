import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/customer_orders_db.dart';
import '../models/customer_order_model.dart';

class OrderTrackingPublicPage extends StatefulWidget {
  final String? orderNumber;

  const OrderTrackingPublicPage({super.key, this.orderNumber});

  @override
  State<OrderTrackingPublicPage> createState() =>
      _OrderTrackingPublicPageState();
}

class _OrderTrackingPublicPageState extends State<OrderTrackingPublicPage> {
  final TextEditingController _orderNumberController = TextEditingController();
  late Future<CustomerOrderModel?> _orderFuture;
  String? _currentOrderNumber;

  @override
  void initState() {
    super.initState();
    if (widget.orderNumber != null) {
      _currentOrderNumber = widget.orderNumber;
      _orderFuture = _searchOrder(widget.orderNumber!);
    } else {
      _orderFuture = Future.value(null);
    }
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    super.dispose();
  }

  Future<CustomerOrderModel?> _searchOrder(String orderNumber) async {
    try {
      final order =
          await CustomerOrdersDatabase.instance.getOrderByNumber(orderNumber);
      return order;
    } catch (e) {
      debugPrint('Error searching order: $e');
      return null;
    }
  }

  void _handleSearch() {
    final searchValue = _orderNumberController.text.trim();
    if (searchValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم الطلب')),
      );
      return;
    }

    setState(() {
      _currentOrderNumber = searchValue;
      _orderFuture = _searchOrder(searchValue);
    });
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

  List<_TrackingStep> _getTrackingSteps(String status) {
    final steps = [
      _TrackingStep(
        title: 'قيد الانتظار',
        status: 'pending',
        description: 'تم استقبال طلبك وقيد المراجعة',
        isCompleted: _isStatusCompleted(status, 'pending'),
      ),
      _TrackingStep(
        title: 'مؤكد',
        status: 'confirmed',
        description: 'تم تأكيد الطلب من قبلنا',
        isCompleted: _isStatusCompleted(status, 'confirmed'),
      ),
      _TrackingStep(
        title: 'قيد الشحن',
        status: 'shipped',
        description: 'الطلب في الطريق إليك',
        isCompleted: _isStatusCompleted(status, 'shipped'),
      ),
      _TrackingStep(
        title: 'تم التسليم',
        status: 'delivered',
        description: 'تم استلام الطلب بنجاح',
        isCompleted: _isStatusCompleted(status, 'delivered'),
      ),
    ];
    return steps;
  }

  bool _isStatusCompleted(String currentStatus, String checkStatus) {
    const statusOrder = [
      'pending',
      'confirmed',
      'shipped',
      'delivered',
      'cancelled'
    ];
    return statusOrder.indexOf(currentStatus) >=
            statusOrder.indexOf(checkStatus) &&
        currentStatus != 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة الطلب'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search section
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'أدخل رقم الطلب',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _orderNumberController,
                      decoration: InputDecoration(
                        hintText: 'مثال: ORD-20250530-143025',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _handleSearch(),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('بحث عن الطلب'),
                      onPressed: _handleSearch,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Order tracking result
            FutureBuilder<CustomerOrderModel?>(
              future: _orderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ: ${snapshot.error}'),
                  );
                }

                final order = snapshot.data;
                if (order == null) {
                  if (_currentOrderNumber != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'لم يتم العثور على الطلب: $_currentOrderNumber',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'يرجى التأكد من رقم الطلب والمحاولة مرة أخرى',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                // Order found - display tracking info
                final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'ar');
                final statusColor = _getStatusColor(order.status);
                final trackingSteps = _getTrackingSteps(order.status);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Order header
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'رقم الطلب',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.orderNumber,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
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
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'تاريخ الطلب: ${dateFmt.format(order.createdAt)}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tracking timeline
                    const Text(
                      'مراحل الطلب',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildTrackingTimeline(trackingSteps, order.status),
                    if (order.status == 'cancelled') ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.cancel_outlined,
                                  color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'تم إلغاء هذا الطلب. تواصل مع المتجر لمعرفة التفاصيل.',
                                  style: TextStyle(color: Colors.red.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Customer info
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معلومات التسليم',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('الاسم', order.customerName),
                            _buildInfoRow('الهاتف', order.customerPhone),
                            _buildInfoRow('العنوان', order.customerAddress),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Order total
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'إجمالي الطلب',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${order.totalAmount.toStringAsFixed(0)} د.ع',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ملاحظات',
                                style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.notes!,
                                style: TextStyle(color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(
      List<_TrackingStep> steps, String currentStatus) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        final isCurrentStep = step.status == currentStatus;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot and line
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isCompleted
                            ? Colors.green
                            : Colors.grey.shade300,
                        border: isCurrentStep
                            ? Border.all(color: Colors.green, width: 3)
                            : null,
                      ),
                      child: step.isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : Text(
                              '${index + 1}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: step.isCompleted
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Step content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCurrentStep ? Colors.green : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!isLast) const SizedBox(height: 8),
          ],
        );
      }),
    );
  }
}

class _TrackingStep {
  final String title;
  final String status;
  final String description;
  final bool isCompleted;

  _TrackingStep({
    required this.title,
    required this.status,
    required this.description,
    required this.isCompleted,
  });
}
