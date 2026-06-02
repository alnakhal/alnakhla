import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../services/product_service.dart';

const String whatsappTargetNumber = '+9647746582364';

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
  final TextEditingController _customerAddressController = TextEditingController();
  final TextEditingController _orderNoteController = TextEditingController();
  late final Future<List<Product>> _productsFuture;
  final Map<int, int> _selectedQuantities = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  bool _isSendingOrder = false;
  String _sortOption = 'الأحدث';
  final List<String> _sortOptions = ['الأحدث', 'السعر الأقل', 'السعر الأعلى'];
  bool _showWelcomeBanner = false;
  bool _showWelcomeDescription = true;
  Timer? _welcomeTimer;


  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadWelcomeState();
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    _welcomeTimer?.cancel();
    _searchController.dispose();
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerPhoneController.dispose();
    _orderNoteController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
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

  List<Product> _sortProducts(List<Product> products) {
    final sorted = List<Product>.from(products);
    if (_sortOption == 'السعر الأقل') {
      sorted.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOption == 'السعر الأعلى') {
      sorted.sort((a, b) => b.price.compareTo(a.price));
    }
    return sorted;
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) {
      return digits.substring(1);
    }
    return digits;
  }

  void _updateCartQuantity(int productId, int delta) {
    setState(() {
      final current = _selectedQuantities[productId] ?? 0;
      final updated = current + delta;
      if (updated <= 0) {
        _selectedQuantities.remove(productId);
      } else {
        _selectedQuantities[productId] = updated;
      }
    });
  }

  void _removeFromCart(int productId) {
    setState(() {
      _selectedQuantities.remove(productId);
    });
  }

  void _clearCart() {
    setState(() {
      _selectedQuantities.clear();
    });
  }

  Future<bool> _confirmClearCart(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('تأكيد مسح السلة'),
              content: const Text('هل تريد مسح جميع المنتجات من السلة؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('نعم، مسح'),
                ),
              ],
            );
          },
        ) ==
        true;
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadWelcomeState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('orders_page_welcome_seen') ?? false;
    if (!seen && mounted) {
      setState(() {
        _showWelcomeBanner = true;
        _showWelcomeDescription = true;
      });
      _welcomeTimer = Timer(const Duration(seconds: 5), () {
        _dismissWelcomeBanner(persist: true);
      });
    }
  }

  Future<void> _dismissWelcomeBanner({bool persist = true}) async {
    _welcomeTimer?.cancel();
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('orders_page_welcome_seen', true);
    }
    if (!mounted) return;
    setState(() {
      _showWelcomeBanner = false;
      _showWelcomeDescription = false;
    });
  }

  void _openSearchAndSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('بحث وفرز المنتجات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _sortOption,
                items: _sortOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortOption = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'ترتيب النتائج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('تطبيق البحث'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmSendOrder(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('تأكيد إرسال الطلب'),
              content: const Text('هل أنت متأكد من إرسال الطلب عبر واتساب الآن؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('نعم، إرسال'),
                ),
              ],
            );
          },
        ) ==
        true;
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
    required String customerAddress,
    required String orderNote,
  }) async {
    if (_isSendingOrder) return;
    setState(() {
      _isSendingOrder = true;
    });
    try {
      final selectedProducts = _lastProducts.where((product) => (_selectedQuantities[product.id] ?? 0) > 0).toList();
      if (selectedProducts.isEmpty) {
        await _showMessage('يرجى اختيار منتج واحد على الأقل قبل إرسال الطلب');
        return;
      }

      if (customerPhone.isEmpty) {
        await _showMessage('يرجى إدخال رقم الجوال لإتمام الطلب');
        return;
      }
      if (customerAddress.isEmpty) {
        await _showMessage('يرجى إدخال العنوان لإتمام الطلب');
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
      } else {
        text.writeln('نوع العميل: زائر');
      }
      if (customerPhone.isNotEmpty) {
        text.writeln('جوال العميل: $customerPhone');
      }
      if (customerAddress.isNotEmpty) {
        text.writeln('عنوان العميل: $customerAddress');
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
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOrder = false;
        });
      }
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
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final currentProducts = _lastProducts.where((product) => (_selectedQuantities[product.id] ?? 0) > 0).toList();
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سلة الطلب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text('${currentProducts.length} صنف', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('مسح الكل'),
                              onPressed: currentProducts.isNotEmpty
                                  ? () async {
                                      final confirmed = await _confirmClearCart(context);
                                      if (confirmed) {
                                        _clearCart();
                                        setStateSheet(() {});
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...currentProducts.map((product) {
                      final qty = _selectedQuantities[product.id] ?? 0;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      _removeFromCart(product.id);
                                      setStateSheet(() {});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('سعر الوحدة: ${product.price.toStringAsFixed(0)} د.ع'),
                                  Text('المجموع: ${(product.price * qty).toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: qty > 1
                                            ? () {
                                                _updateCartQuantity(product.id, -1);
                                                setStateSheet(() {});
                                              }
                                            : null,
                                      ),
                                      Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: product.remainingQty > qty
                                            ? () {
                                                _updateCartQuantity(product.id, 1);
                                                setStateSheet(() {});
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                  if (product.remainingQty <= qty)
                                    const Text('غير متوفر', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي السلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_selectedTotal.toStringAsFixed(0), style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'سيتم تحويل الطلب إلى واتساب رقم $whatsappTargetNumber بطريقة منظمة.',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                      decoration: const InputDecoration(labelText: 'رقم الجوال (مطلوب)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customerAddressController,
                      decoration: const InputDecoration(labelText: 'العنوان (مطلوب)'),
                      minLines: 1,
                      maxLines: 3,
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
                      icon: _isSendingOrder ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                      label: Text(_isSendingOrder ? 'جاري إرسال الطلب...' : 'إرسال الطلب عبر واتساب'),
                      onPressed: _isSendingOrder
                          ? null
                          : () async {
                              final sheetContext = context;
                                      // validate required fields
                                      final phoneVal = _customerPhoneController.text.trim();
                                      final addressVal = _customerAddressController.text.trim();
                                      if (phoneVal.isEmpty) {
                                        await _showMessage('الرجاء إدخال رقم الجوال');
                                        return;
                                      }
                                      if (addressVal.isEmpty) {
                                        await _showMessage('الرجاء إدخال العنوان');
                                        return;
                                      }

                                      final confirmed = await _confirmSendOrder(sheetContext);
                                      if (!confirmed || !sheetContext.mounted) return;

                                      await _sendOrderWhatsApp(
                                        customerName: _customerNameController.text.trim(),
                                        customerPhone: phoneVal,
                                        customerAddress: addressVal,
                                        orderNote: _orderNoteController.text.trim(),
                                      );
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                            },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
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
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: _openSearchAndSortSheet,
          ),
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
                      right: -2,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
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
          final authUser = Supabase.instance.client.auth.currentUser;
          if (products.isEmpty) {
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
                if (_showWelcomeBanner)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).colorScheme.primary.withAlpha(24),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('واجهة متجر احترافية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (_showWelcomeDescription)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'اضغط زر البحث في الأعلى لكتابة اسم المنتج وفرز النتائج داخل شاشة البحث. يمكنك إزالة هذا الشرح بالضغط على علامة الإغلاق.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    tooltip: 'إزالة الشرح',
                                    onPressed: () {
                                      setState(() {
                                        _showWelcomeDescription = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (_showWelcomeBanner) const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'المستورد الرئيسي لكاسات النخلة ومنتجات الحجامة'
                              : 'نتائج البحث عن: ${_searchController.text}',
                          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedCount == 0)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'سلتك فارغة الآن. أضف أول منتج للبدء في الطلب بسهولة.',
                              style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'السلة تحتوي على $_selectedCount منتج. اضغط أيقونة العربة لمراجعة الطلب وإتمامه.',
                              style: TextStyle(color: Colors.green.shade900, fontSize: 14),
                            ),
                          ),
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
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final sortedProducts = _sortProducts(filtered);
                            final crossAxisCount = constraints.maxWidth > 1000
                                ? 3
                                : constraints.maxWidth > 650
                                    ? 2
                                    : 1;
                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: sortedProducts.length,
                              itemBuilder: (context, index) {
                                final product = sortedProducts[index];
                                final quantity = _selectedQuantities[product.id] ?? 0;
                                final available = product.remainingQty;
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  elevation: 2,
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => _showProductDetails(product),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Stack(
                                          children: [
                                            SizedBox(
                                              height: 180,
                                              child: product.imageUrl != null
                                                  ? Image.network(
                                                      product.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey.shade200,
                                                        child: const Center(child: Icon(Icons.image_not_supported, size: 60)),
                                                      ),
                                                    )
                                                  : Container(
                                                      color: Colors.grey.shade200,
                                                      child: const Center(child: Icon(Icons.image_not_supported, size: 60)),
                                                    ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              left: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: available > 0
                                                      ? available <= 5
                                                          ? Colors.orange.withOpacity(0.95)
                                                          : Colors.green.withOpacity(0.95)
                                                      : Colors.red.withOpacity(0.95),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  available > 0
                                                      ? available <= 5
                                                          ? 'كمية محدودة'
                                                          : 'متوفر'
                                                      : 'منفد',
                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            if (quantity > 0)
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.7),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    'في السلة x$quantity',
                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                product.name,
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                product.description.isEmpty ? 'لا يوجد وصف.' : product.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                                              ),
                                              const SizedBox(height: 14),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '${product.price.toStringAsFixed(0)} د.ع',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '/قطعة',
                                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                  if (available > 0)
                                                    Text(
                                                      '${available} قطعة متاحة',
                                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 14),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline),
                                                    tooltip: 'نقص كمية',
                                                    onPressed: quantity > 0
                                                        ? () {
                                                            setState(() {
                                                              final next = quantity - 1;
                                                              if (next <= 0) {
                                                                _selectedQuantities.remove(product.id);
                                                              } else {
                                                                _selectedQuantities[product.id] = next;
                                                              }
                                                              _quantityControllers[product.id]?.text = next > 0 ? next.toString() : '';
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  SizedBox(
                                                    width: 72,
                                                    child: TextField(
                                                      controller: _quantityControllers.putIfAbsent(
                                                        product.id,
                                                        () => TextEditingController(text: quantity > 0 ? quantity.toString() : ''),
                                                      )..text = quantity > 0 ? quantity.toString() : '',
                                                      keyboardType: TextInputType.number,
                                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                      textAlign: TextAlign.center,
                                                      decoration: InputDecoration(
                                                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                        hintText: '0',
                                                      ),
                                                      onChanged: (value) {
                                                        final parsed = int.tryParse(value) ?? 0;
                                                        final newValue = parsed.clamp(0, available);
                                                        setState(() {
                                                          if (newValue <= 0) {
                                                            _selectedQuantities.remove(product.id);
                                                          } else {
                                                            _selectedQuantities[product.id] = newValue;
                                                          }
                                                          _quantityControllers[product.id]?.text = newValue > 0 ? newValue.toString() : '';
                                                          _quantityControllers[product.id]?.selection = TextSelection.collapsed(offset: _quantityControllers[product.id]?.text.length ?? 0);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle_outline),
                                                    tooltip: 'زيادة كمية',
                                                    onPressed: available > quantity
                                                        ? () {
                                                            setState(() {
                                                              final next = quantity + 1;
                                                              _selectedQuantities[product.id] = next;
                                                              _quantityControllers[product.id]?.text = next.toString();
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
