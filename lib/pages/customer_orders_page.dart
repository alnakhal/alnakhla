import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../services/product_service.dart';

const String whatsappTargetNumber = '07867360219';

class CustomerOrdersPage extends StatefulWidget {
  final String? storeSlug;
  final String? storeUserId;

  const CustomerOrdersPage({super.key, this.storeSlug, this.storeUserId});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _orderNoteController = TextEditingController();
  late final Future<List<Product>> _productsFuture;
  final Map<int, int> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _orderNoteController.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() async {
    if (widget.storeSlug != null && widget.storeSlug!.trim().isNotEmpty) {
      return fetchProductsBySlug(widget.storeSlug!.trim());
    }
    if (widget.storeUserId != null && widget.storeUserId!.trim().isNotEmpty) {
      return fetchProductsByUserId(widget.storeUserId!.trim());
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final storeId = await getOrCreateStoreForUser(user.id);
      if (storeId != null) {
        return fetchProductsByStoreId(storeId);
      }
    }

    return fetchAllProducts();
  }

  int get _selectedCount => _selectedQuantities.values.fold(0, (sum, qty) => sum + qty);

  double get _selectedTotal => _selectedQuantities.entries.fold(0.0, (sum, entry) {
    final productId = entry.key;
    final quantity = entry.value;
    return sum + quantity * _productPrice(productId);
  });

  double _productPrice(int productId) {
    return _lastProducts.firstWhere((p) => p.id == productId, orElse: () => Product(
          id: 0,
          name: '',
          description: '',
          price: 0,
          cost: 0,
          wholesalePrice: 0,
          minWholesaleQuantity: 0,
          singlePrice: 0,
          hasWholesale: false,
          remainingQty: 0,
        )).price;
  }

  List<Product> _lastProducts = [];

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) {
      return digits.substring(1);
    }
    return digits;
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (product.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(product.imageUrl!, height: 180, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, size: 80),
                        )),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(product.description.isEmpty ? 'لا توجد تفاصيل إضافية.' : product.description),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('السعر:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(product.price.toStringAsFixed(0)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('المخزون المتوفر: ${product.remainingQty} قطعة'),
                if (product.hasWholesale) ...[
                  const SizedBox(height: 8),
                  Text('سعر الجملة: ${product.wholesalePrice.toStringAsFixed(0)} من ${product.minWholesaleQuantity} قطع'),
                ],
                if (product.singlePrice > 0) ...[
                  const SizedBox(height: 8),
                  Text('سعر المفرد: ${product.singlePrice.toStringAsFixed(0)}'),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendOrderWhatsApp({
    required String customerName,
    required String customerPhone,
    required String orderNote,
  }) async {
    final selectedProducts = _lastProducts.where((product) => (_selectedQuantities[product.id] ?? 0) > 0).toList();
    if (selectedProducts.isEmpty) {
      await _showMessage('يرجى اختيار منتج واحد على الأقل قبل إرسال الطلب');
      return;
    }

    final whatsappNumber = _normalizePhone(whatsappTargetNumber);
    final total = selectedProducts.fold<double>(0, (sum, product) {
      final qty = _selectedQuantities[product.id] ?? 0;
      return sum + qty * product.price;
    });

    final text = StringBuffer();
    text.writeln('طلب جديد من صفحة طلبات الزبائن');
    if (customerName.isNotEmpty) {
      text.writeln('اسم العميل: $customerName');
    }
    if (customerPhone.isNotEmpty) {
      text.writeln('جوال العميل: $customerPhone');
    }
    text.writeln('---');
    for (final product in selectedProducts) {
      final qty = _selectedQuantities[product.id] ?? 0;
      text.writeln('${product.name} x$qty = ${(product.price * qty).toStringAsFixed(0)}');
    }
    text.writeln('---');
    text.writeln('المجموع: ${total.toStringAsFixed(0)}');
    if (orderNote.isNotEmpty) {
      text.writeln('ملاحظات: $orderNote');
    }

    final url = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(text.toString())}');
    final canOpen = await canLaunchUrl(url);
    if (!canOpen) {
      await _showMessage('لا يمكن فتح واتساب على هذا الجهاز');
      return;
    }

    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      await _showMessage('فشل فتح واتساب. حاول مرة أخرى.');
    }
  }

  void _showOrderSummaryDialog() {
    final selectedProducts = _lastProducts.where((product) => (_selectedQuantities[product.id] ?? 0) > 0).toList();
    if (selectedProducts.isEmpty) {
      _showMessage('يرجى اختيار منتجات قبل إتمام الطلب');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تفاصيل الطلب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...selectedProducts.map((product) {
                  final qty = _selectedQuantities[product.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${product.name} x$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Text((product.price * qty).toStringAsFixed(0)),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_selectedTotal.toStringAsFixed(0), style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'سيتم تحويل الطلب إلى واتساب رقم 07867360219 بطريقة منظمة.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الجوال'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _orderNoteController,
                  decoration: const InputDecoration(labelText: 'ملاحظات الطلب (اختياري)'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('إرسال الطلب عبر واتساب'),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await _sendOrderWhatsApp(
                      customerName: _customerNameController.text.trim(),
                      customerPhone: _customerPhoneController.text.trim(),
                      orderNote: _orderNoteController.text.trim(),
                    );
                    if (mounted) navigator.pop();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متجر الطلبات'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _selectedCount > 0 ? _showOrderSummaryDialog : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_cart),
                  if (_selectedCount > 0)
                    Positioned(
                      right: 0,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _selectedCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل المنتجات: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          _lastProducts = products;
          if (products.isEmpty) {
            final authUser = Supabase.instance.client.auth.currentUser;
            final noStoreLink = widget.storeSlug == null && widget.storeUserId == null && authUser == null;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  noStoreLink
                      ? 'استخدم رابط المتجر المخصص لعرض المنتجات، أو سجّل دخول صاحب المتجر.'
                      : authUser == null
                          ? 'لا يوجد منتجات في المتجر حالياً أو لم يتم العثور على المتجر.'
                          : 'لا يوجد منتجات في المتجر حالياً.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final query = _searchController.text.trim().toLowerCase();
          final filtered = products.where((product) {
            return query.isEmpty ||
                product.name.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).colorScheme.primary.withAlpha(24),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        Text('واجهة متجر احترافية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('اختر المنتجات واضغط إتمام الطلب لمراجعة ملخص الطلب ثم إرساله عبر واتساب مباشرة.', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'ابحث في المنتجات',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).colorScheme.secondary.withAlpha(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('السلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('$_selectedCount منتج'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_selectedTotal.toStringAsFixed(0)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: const Text('عرض السلة وإتمام الطلب'),
                          onPressed: _selectedCount > 0 ? _showOrderSummaryDialog : null,
                        ),
                        if (_selectedCount == 0) ...[
                          const SizedBox(height: 12),
                          const Text('أضف منتجات إلى السلة ليظهر ملخص الطلب هنا.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد منتجات تطابق البحث.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            final quantity = _selectedQuantities[product.id] ?? 0;
                            final available = product.remainingQty;
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: InkWell(
                                onTap: () => _showProductDetails(product),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: product.imageUrl != null
                                            ? Image.network(product.imageUrl!, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(
                                                  width: 90,
                                                  height: 90,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.image_not_supported),
                                                ))
                                            : Container(
                                                width: 90,
                                                height: 90,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image_not_supported),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                ),
                                                Text('${product.price.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              product.description.isEmpty ? 'بدون وصف' : product.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                Chip(label: Text('المخزون: $available')),
                                                if (product.hasWholesale)
                                                  Chip(label: Text('جملة ${product.wholesalePrice.toStringAsFixed(0)}')),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline),
                                            onPressed: available > quantity
                                                ? () {
                                                    setState(() {
                                                      _selectedQuantities[product.id] = quantity + 1;
                                                    });
                                                  }
                                                : null,
                                          ),
                                          Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline),
                                            onPressed: quantity > 0
                                                ? () {
                                                    setState(() {
                                                      final next = quantity - 1;
                                                      if (next <= 0) {
                                                        _selectedQuantities.remove(product.id);
                                                      } else {
                                                        _selectedQuantities[product.id] = next;
                                                      }
                                                    });
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
