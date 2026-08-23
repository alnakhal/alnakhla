import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart'
    show
        LoginPage,
        OwnerDashboardPage,
        ProductManagementPage,
        storeShareBaseUrl;
import '../models/product.dart';
import '../models/customer_order_model.dart';
import '../services/product_service.dart';
import '../services/data_service.dart';
import '../services/customer_orders_supabase_service.dart';
import 'photo_viewer_page.dart';
import 'slider_images_settings_page.dart';
import 'customer_orders_tracking_page.dart' as customer_orders_tracking;

const String whatsappTargetNumber = '+9647746582364';
const String orderTrackingUrl = 'متابعة-الطلب';

class CustomerOrdersPage extends StatefulWidget {
  final String? storeSlug;
  final String? storeUserId;

  const CustomerOrdersPage({super.key, this.storeSlug, this.storeUserId});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  final TextEditingController _orderNoteController = TextEditingController();
  final PageController _sliderPageController = PageController();
  String _sortOption = 'الأحدث';
  String _selectedCategory = 'الكل';
  Set<int> _favoriteProductIds = <int>{};
  bool _showFavoritesOnly = false;
  static const List<String> _defaultSliderImages = [
    'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1491553895911-0055eca6402d?auto=format&fit=crop&w=1200&q=80',
  ];
  List<String> _sliderImageUrls = [];
  int _currentSliderIndex = 0;
  late Future<List<Product>> _productsFuture;
  final Map<int, int> _selectedQuantities = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  bool _isSendingOrder = false;
  Timer? _sliderTimer;
  bool _showWelcomeBanner = false;

  bool _showWelcomeDescription = true;
  Timer? _welcomeTimer;
  late final AnimationController _addButtonAnimationController;

  bool get _canEditSlider {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return false;
    return widget.storeUserId == null || widget.storeUserId == authUser.id;
  }

  @override
  void initState() {
    super.initState();
    _addButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _productsFuture = _loadProducts();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadWelcomeState();
    _loadCustomerPreferences();
    _loadSliderImages();
    _startSliderTimer();
  }

  @override
  void dispose() {
    _addButtonAnimationController.dispose();
    _welcomeTimer?.cancel();
    _sliderTimer?.cancel();
    _sliderPageController.dispose();
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

  Future<void> _loadSliderImages() async {
    try {
      final images = await fetchSliderImages();
      if (!mounted) return;
      if (images.isNotEmpty) {
        setState(() {
          _sliderImageUrls = images
              .map((img) => img['image_url'] as String)
              .toList();
        });
      } else {
        setState(() {
          _sliderImageUrls = _defaultSliderImages;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل صور السلايدر: $e');
      if (!mounted) return;
      setState(() {
        _sliderImageUrls = _defaultSliderImages;
      });
    }
  }

  String get _preferencesKey {
    final storeKey = widget.storeSlug ?? widget.storeUserId ?? 'default';
    return storeKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Future<void> _loadCustomerPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites =
        prefs.getStringList('favorite_products_$_preferencesKey') ?? <String>[];
    if (!mounted) return;
    setState(() {
      _favoriteProductIds = favorites
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
      _customerNameController.text =
          prefs.getString('customer_name_$_preferencesKey') ?? '';
      _customerPhoneController.text =
          prefs.getString('customer_phone_$_preferencesKey') ?? '';
      _customerAddressController.text =
          prefs.getString('customer_address_$_preferencesKey') ?? '';
    });
  }

  Future<void> _saveCustomerPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_products_$_preferencesKey',
      _favoriteProductIds.map((id) => id.toString()).toList(),
    );
    await prefs.setString(
      'customer_name_$_preferencesKey',
      _customerNameController.text.trim(),
    );
    await prefs.setString(
      'customer_phone_$_preferencesKey',
      _customerPhoneController.text.trim(),
    );
    await prefs.setString(
      'customer_address_$_preferencesKey',
      _customerAddressController.text.trim(),
    );
  }

  Future<void> _toggleFavorite(Product product) async {
    setState(() {
      if (_favoriteProductIds.contains(product.id)) {
        _favoriteProductIds.remove(product.id);
      } else {
        _favoriteProductIds.add(product.id);
      }
    });
    await _saveCustomerPreferences();
  }

  void _startSliderTimer() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted ||
          _sliderImageUrls.isEmpty ||
          !_sliderPageController.hasClients) {
        return;
      }
      _currentSliderIndex = (_currentSliderIndex + 1) % _sliderImageUrls.length;
      _sliderPageController.animateToPage(
        _currentSliderIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildImageSlider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _sliderPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentSliderIndex = index;
                  });
                },
                itemCount: _sliderImageUrls.length,
                itemBuilder: (context, index) {
                  final imageData = _sliderImageUrls[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      buildImageWidget(imageData, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _sliderImageUrls.length,
              (index) => Container(
                width: _currentSliderIndex == index ? 12 : 8,
                height: _currentSliderIndex == index ? 12 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentSliderIndex == index
                      ? Colors.brown.shade700
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildTrustChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.brown.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTrustChip(Icons.local_shipping_outlined, 'توصيل موثوق'),
          const SizedBox(width: 8),
          _buildTrustChip(Icons.payments_outlined, 'الدفع عند الاستلام'),
          const SizedBox(width: 8),
          _buildTrustChip(Icons.support_agent_outlined, 'دعم سريع'),
        ],
      ),
    );
  }

  Future<List<Product>> _loadProducts() async {
    if (widget.storeSlug != null && widget.storeSlug!.trim().isNotEmpty) {
      final products = await fetchProductsBySlug(widget.storeSlug!.trim());
      return products.where((product) => !product.isHidden).toList();
    }
    if (widget.storeUserId != null && widget.storeUserId!.trim().isNotEmpty) {
      final products = await fetchProductsByUserId(widget.storeUserId!.trim());
      return products.where((product) => !product.isHidden).toList();
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final storeId = await getOrCreateStoreForUser(user.id);
      if (storeId != null) {
        final products = await fetchProductsByStoreId(storeId);
        return products.where((product) => !product.isHidden).toList();
      }
    }

    final products = await fetchAllProducts();
    return products.where((product) => !product.isHidden).toList();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = _loadProducts();
    });
    await _productsFuture;
  }

  Future<void> _showStoreLinkOptions() async {
    const storeUrl = 'https://alnakhal.github.io/alnakhla/';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('هل تريد فتح الرابط؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(storeUrl),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final launched = await launchUrl(
                  Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication,
                );
                if (!launched && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تعذر فتح رابط المتجر')),
                  );
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح الرابط'),
            ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: storeUrl));
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الرابط')),
                  );
                }
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('نسخ الرابط'),
            ),
          ],
        ),
      ),
    );
  }

  int get _selectedCount =>
      _selectedQuantities.values.fold(0, (sum, qty) => sum + qty);

  double get _selectedTotal =>
      _selectedQuantities.entries.fold(0.0, (sum, entry) {
        final productId = entry.key;
        final quantity = entry.value;
        return sum + quantity * _productPrice(productId);
      });

  double get _selectedGrandTotal => _selectedTotal;

  double _productPrice(int productId) {
    return _lastProducts
        .firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
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
          ),
        )
        .price;
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

  bool _isValidPhone(String raw) {
    final phone = _normalizePhone(raw);
    return RegExp(r'^(07\d{9}|9647\d{9})$').hasMatch(phone);
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    return 'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<bool> _confirmSendOrder(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('تأكيد إرسال الطلب'),
              content: const Text(
                'هل أنت متأكد من إرسال الطلب عبر واتساب الآن؟',
              ),
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
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (product.imageUrl != null) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoViewerPage(
                            imageUrl: product.imageUrl!,
                            productName: product.name,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          product.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على الصورة لعرضها بالكامل مع إمكانية التدوير',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  product.description.isEmpty
                      ? 'لا توجد تفاصيل إضافية.'
                      : product.description,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'السعر:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(product.price.toStringAsFixed(0)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('المخزون المتوفر: ${product.remainingQty} قطعة'),
                if (product.hasWholesale) ...[
                  const SizedBox(height: 8),
                  Text(
                    'سعر الجملة: ${product.wholesalePrice.toStringAsFixed(0)} من ${product.minWholesaleQuantity} قطع',
                  ),
                ],
                if (product.singlePrice > 0) ...[
                  const SizedBox(height: 8),
                  Text('سعر المفرد: ${product.singlePrice.toStringAsFixed(0)}'),
                ],
                if (product.deliveryPrice != null &&
                    product.deliveryPrice! > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'سعر التوصيل: ${product.deliveryPrice!.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      await _showMessage('يرجى تسجيل الدخول أولاً لحفظ ومتابعة الطلب');
      return;
    }
    setState(() {
      _isSendingOrder = true;
    });
    try {
      final selectedProducts = _lastProducts
          .where((product) => (_selectedQuantities[product.id] ?? 0) > 0)
          .toList();
      if (selectedProducts.isEmpty) {
        await _showMessage('يرجى اختيار منتج واحد على الأقل قبل إرسال الطلب');
        return;
      }

      if (customerName.trim().isEmpty) {
        await _showMessage('يرجى إدخال اسم العميل لإتمام الطلب');
        return;
      }

      if (!_isValidPhone(customerPhone)) {
        await _showMessage('يرجى إدخال رقم جوال عراقي صحيح مثل 077xxxxxxxx');
        return;
      }
      if (customerAddress.isEmpty) {
        await _showMessage('يرجى إدخال العنوان لإتمام الطلب');
        return;
      }
      await _saveCustomerPreferences();

      final outOfStockProduct = selectedProducts.cast<Product?>().firstWhere(
        (product) =>
            (_selectedQuantities[product!.id] ?? 0) > product.remainingQty,
        orElse: () => null,
      );
      if (outOfStockProduct != null) {
        await _showMessage(
          'الكمية المطلوبة من ${outOfStockProduct.name} أكبر من المتوفر حاليًا',
        );
        return;
      }

      final whatsappNumber = _normalizePhone(whatsappTargetNumber);
      final total = selectedProducts.fold<double>(0, (sum, product) {
        final qty = _selectedQuantities[product.id] ?? 0;
        return sum + qty * product.price;
      });
      final grandTotal = total;

      final orderNumber = _generateOrderNumber();
      final text = StringBuffer();
      text.writeln('طلب جديد من صفحة طلبات الزبائن');
      text.writeln('رقم الطلب: $orderNumber');
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
      for (var i = 0; i < selectedProducts.length; i++) {
        final product = selectedProducts[i];
        final qty = _selectedQuantities[product.id] ?? 0;
        text.writeln(
          '${i + 1}. ${product.name} x$qty = ${(product.price * qty).toStringAsFixed(0)}',
        );
      }
      text.writeln('---');
      text.writeln('مجموع المنتجات: ${total.toStringAsFixed(0)} د.ع');
      text.writeln('الإجمالي النهائي: ${grandTotal.toStringAsFixed(0)} د.ع');
      if (orderNote.isNotEmpty) {
        text.writeln('ملاحظات: $orderNote');
      }
      text.writeln('');
      final trackingUrl =
          '$storeShareBaseUrl/#/track-order?order=${Uri.encodeQueryComponent(orderNumber)}';
      text.writeln('يمكنك متابعة حالة طلبك عبر الرابط:');
      text.writeln(trackingUrl);

      final url = Uri.parse(
        'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(text.toString())}',
      );
      final canOpen = await canLaunchUrl(url);
      if (!canOpen) {
        await _showMessage('لا يمكن فتح واتساب على هذا الجهاز');
        return;
      }

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await _showMessage('فشل فتح واتساب. حاول مرة أخرى.');
        return;
      }

      // حفظ الطلب في قاعدة البيانات بعد الإرسال الناجح
      try {
        final order = CustomerOrderModel(
          orderNumber: orderNumber,
          customerName: customerName.isNotEmpty ? customerName : 'زائر',
          userId: authUser.id,
          storeUserId: widget.storeUserId,
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          totalAmount: grandTotal,
          status: 'pending',
          paymentMethod: 'cash_on_delivery',
          deliveryPlatform: 'website',
          deliveryArea: 'baghdad',
          deliveryFee: 0,
          notes: orderNote.isNotEmpty ? orderNote : null,
          items: selectedProducts
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.name,
                  'quantity': _selectedQuantities[p.id] ?? 0,
                  'price': p.price,
                },
              )
              .toList(),
          createdAt: DateTime.now(),
        );
        await CustomerOrdersSupabaseService().insertOrder(order);
        if (mounted) {
          setState(() => _selectedQuantities.clear());
          await _showMessage('✓ تم إرسال الطلب بنجاح! رقم الطلب: $orderNumber');
        }
      } catch (e) {
        debugPrint('Error saving order: $e');
        if (mounted) {
          await _showMessage('تحذير: تم إرسال الطلب لكن تعذر حفظه في الحساب');
        }
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
    final selectedProducts = _lastProducts
        .where((product) => (_selectedQuantities[product.id] ?? 0) > 0)
        .toList();
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
            final currentProducts = _lastProducts
                .where((product) => (_selectedQuantities[product.id] ?? 0) > 0)
                .toList();
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
                        const Text(
                          'سلة الطلب',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${currentProducts.length} صنف',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('مسح الكل'),
                              onPressed: currentProducts.isNotEmpty
                                  ? () async {
                                      final confirmed = await _confirmClearCart(
                                        context,
                                      );
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'سعر الوحدة: ${product.price.toStringAsFixed(0)} د.ع',
                                  ),
                                  Text(
                                    'المجموع: ${(product.price * qty).toStringAsFixed(0)} د.ع',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (product.deliveryPrice != null &&
                                  product.deliveryPrice! > 0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'التوصيل: ${product.deliveryPrice!.toStringAsFixed(0)} د.ع',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: qty > 1
                                            ? () {
                                                _updateCartQuantity(
                                                  product.id,
                                                  -1,
                                                );
                                                setStateSheet(() {});
                                              }
                                            : null,
                                      ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed: product.remainingQty > qty
                                            ? () {
                                                _updateCartQuantity(
                                                  product.id,
                                                  1,
                                                );
                                                setStateSheet(() {});
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                  if (product.remainingQty <= qty)
                                    const Text(
                                      'غير متوفر',
                                      style: TextStyle(color: Colors.red),
                                    ),
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
                        const Text(
                          'إجمالي السلة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${_selectedTotal.toStringAsFixed(0)} د.ع',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي النهائي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${_selectedGrandTotal.toStringAsFixed(0)} د.ع',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
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
                      decoration: const InputDecoration(
                        labelText: 'الاسم (مطلوب)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الجوال (مطلوب)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customerAddressController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان (مطلوب)',
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _orderNoteController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات الطلب (اختياري)',
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: _isSendingOrder
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSendingOrder
                            ? 'جاري إرسال الطلب...'
                            : 'إرسال الطلب عبر واتساب',
                      ),
                      onPressed: _isSendingOrder
                          ? null
                          : () async {
                              final sheetContext = context;
                              // validate required fields
                              final phoneVal = _customerPhoneController.text
                                  .trim();
                              final nameVal = _customerNameController.text
                                  .trim();
                              final addressVal = _customerAddressController.text
                                  .trim();
                              if (nameVal.isEmpty) {
                                await _showMessage('الرجاء إدخال اسم العميل');
                                return;
                              }
                              if (!_isValidPhone(phoneVal)) {
                                await _showMessage(
                                  'الرجاء إدخال رقم جوال عراقي صحيح مثل 077xxxxxxxx',
                                );
                                return;
                              }
                              if (addressVal.isEmpty) {
                                await _showMessage('الرجاء إدخال العنوان');
                                return;
                              }

                              final confirmed = await _confirmSendOrder(
                                sheetContext,
                              );
                              if (!confirmed || !sheetContext.mounted) return;

                              await _sendOrderWhatsApp(
                                customerName: _customerNameController.text
                                    .trim(),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final width = MediaQuery.of(context).size.width;
    final pagePadding = width > 900
        ? 28.0
        : width > 650
        ? 22.0
        : 16.0;
    final cardSpacing = width > 900 ? 18.0 : 12.0;
    final appBarHeight = width > 600 ? 82.0 : 70.0;
    final productCardAspectRatio = width >= 1100
        ? 1.1
        : width >= 720
        ? 0.95
        : 0.85;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'متجرنا صمم خصيصا لك',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(appBarHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.brown.shade700),
                hintText: 'ابحث عن المنتجات أو الأقسام',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: width > 700 ? 18 : 14,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.brown.shade700,
                    width: 1.6,
                  ),
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'الإعدادات',
            offset: const Offset(0, 48),
            onSelected: (value) async {
              if (value == 'login') {
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                if (mounted) setState(() {});
                return;
              }

              if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
                );
                return;
              }

              if (value == 'manage_products') {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OwnerDashboardPage()),
                );
                if (mounted) await _refreshProducts();
              }
            },
            itemBuilder: (context) {
              final isLoggedIn =
                  Supabase.instance.client.auth.currentUser != null;
              if (isLoggedIn) {
                return const [
                  PopupMenuItem<String>(
                    value: 'manage_products',
                    child: Text('إدارة المنشورات'),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('تسجيل الخروج'),
                  ),
                ];
              }
              return const [
                PopupMenuItem<String>(
                  value: 'login',
                  child: Text('تسجيل الدخول'),
                ),
              ];
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _selectedCount > 0
                      ? _showOrderSummaryDialog
                      : null,
                  tooltip: 'سلة الطلبات',
                ),
                if (_selectedCount > 0)
                  Positioned(
                    right: 6,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        _selectedCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('خطأ في تحميل المنتجات: ${snapshot.error}'),
              );
            }
            final products = snapshot.data ?? [];
            _lastProducts = products;
            final authUser = Supabase.instance.client.auth.currentUser;
            if (products.isEmpty) {
              final noStoreLink =
                  widget.storeSlug == null &&
                  widget.storeUserId == null &&
                  authUser == null;
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
              final matchesQuery =
                  query.isEmpty ||
                  product.name.toLowerCase().contains(query) ||
                  product.description.toLowerCase().contains(query);
              final matchesCategory =
                  _selectedCategory == 'الكل' ||
                  (product.category ?? 'غير مصنف') == _selectedCategory;
              final matchesFavorites =
                  !_showFavoritesOnly ||
                  _favoriteProductIds.contains(product.id);
              return matchesQuery && matchesCategory && matchesFavorites;
            }).toList();

            return Padding(
              padding: EdgeInsets.all(pagePadding),
              child: RefreshIndicator(
                onRefresh: _refreshProducts,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_sliderImageUrls.isNotEmpty) ...[
                        if (_canEditSlider) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton.icon(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SliderImagesSettingsPage(),
                                    ),
                                  );
                                  _loadSliderImages();
                                },
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('تعديل صور السلايدر'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          color: Colors.brown.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'شارك رابط المتجر',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _showStoreLinkOptions,
                                        child: Text(
                                          'https://alnakhal.github.io/alnakhla/',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: () async {
                                        await Share.share(
                                          'تسوق معنا الآن: https://alnakhal.github.io/alnakhla/\nمنتجات عالية الجودة وتوصيل سريع!',
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.share_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('شارك'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.brown.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                customer_orders_tracking.CustomerOrdersTrackingPage(
                                                  loginPageBuilder: (_) =>
                                                      const LoginPage(),
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.receipt_long_outlined,
                                      ),
                                      label: const Text('الطلبات'),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ProductManagementPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.inventory_2_outlined,
                                      ),
                                      label: const Text('المخزن'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildImageSlider(),
                        const SizedBox(height: 12),
                        _buildTrustStrip(),
                        const SizedBox(height: 20),
                      ],
                      if (_showWelcomeBanner)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          color: Colors.brown.shade50,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: EdgeInsets.all(pagePadding),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.brown.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تجربة طلب واضحة وسهلة',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_showWelcomeDescription)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            'اضغط على المنتج لمشاهدة التفاصيل، ثم استخدم زر إضافة إلى السلة لإتمام الطلب بسرعة.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_showWelcomeDescription)
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
                        ),
                      if (_showWelcomeBanner) const SizedBox(height: 16),
                      if (_selectedCount > 0) ...[
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.16,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: pagePadding,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'السلة تحتوي على $_selectedCount منتج. اضغط أيقونة العربة لمراجعة الطلب وإتمامه.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'منتجات المتجر',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DropdownButton<String>(
                            value: _sortOption,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.swap_vert, size: 18),
                            items: const [
                              DropdownMenuItem(
                                value: 'الأحدث',
                                child: Text('الأحدث'),
                              ),
                              DropdownMenuItem(
                                value: 'السعر الأقل',
                                child: Text('الأقل سعراً'),
                              ),
                              DropdownMenuItem(
                                value: 'السعر الأعلى',
                                child: Text('الأعلى سعراً'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sortOption = value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${filtered.length} منتج متاح',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'التصنيفات',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['غير مصنف', ...productCategories]
                              .map(
                                (category) => Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 8,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(category),
                                    selected: _selectedCategory == category,
                                    onSelected: (_) => setState(
                                      () => _selectedCategory = category,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilterChip(
                        avatar: const Icon(Icons.favorite_border, size: 18),
                        label: const Text('المفضلة فقط'),
                        selected: _showFavoritesOnly,
                        onSelected: (selected) {
                          setState(() => _showFavoritesOnly = selected);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: Text(
                              'لا توجد منتجات تطابق البحث.',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final sortedProducts = _sortProducts(filtered);
                            final crossAxisCount = constraints.maxWidth > 500
                                ? 2
                                : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: cardSpacing,
                                    mainAxisSpacing: cardSpacing,
                                    childAspectRatio: productCardAspectRatio,
                                  ),
                              itemCount: sortedProducts.length,
                              itemBuilder: (context, index) {
                                final product = sortedProducts[index];
                                final quantity =
                                    _selectedQuantities[product.id] ?? 0;
                                final available = product.remainingQty;
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 2,
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => _showProductDetails(product),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: product.imageUrl != null
                                              ? Image.network(
                                                  product.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return Container(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 60,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      size: 60,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(
                                                    alpha: 0.4,
                                                  ),
                                                ],
                                                stops: const [0.45, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: available > 0
                                                  ? available <= 5
                                                        ? colorScheme
                                                              .errorContainer
                                                              .withValues(
                                                                alpha: 0.9,
                                                              )
                                                        : colorScheme
                                                              .primaryContainer
                                                              .withValues(
                                                                alpha: 0.9,
                                                              )
                                                  : colorScheme.error
                                                        .withValues(
                                                          alpha: 0.85,
                                                        ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              available > 0
                                                  ? available <= 5
                                                        ? 'كمية محدودة'
                                                        : 'متوفر'
                                                  : 'منفد',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.onPrimary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Material(
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                            shape: const CircleBorder(),
                                            child: IconButton(
                                              tooltip:
                                                  _favoriteProductIds.contains(
                                                    product.id,
                                                  )
                                                  ? 'إزالة من المفضلة'
                                                  : 'إضافة إلى المفضلة',
                                              icon: Icon(
                                                _favoriteProductIds.contains(
                                                      product.id,
                                                    )
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color:
                                                    _favoriteProductIds
                                                        .contains(product.id)
                                                    ? Colors.redAccent
                                                    : Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _toggleFavorite(product),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(
                                                    alpha: 0.85,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${product.price.toStringAsFixed(0)} د.ع',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          '/قطعة',
                                                          style: textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color: colorScheme
                                                                    .onSurfaceVariant,
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    AnimatedBuilder(
                                                      animation:
                                                          _addButtonAnimationController,
                                                      builder: (context, child) {
                                                        return DecoratedBox(
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                available > 0
                                                                ? LinearGradient(
                                                                    begin: Alignment
                                                                        .topLeft,
                                                                    end: Alignment
                                                                        .bottomRight,
                                                                    transform: GradientRotation(
                                                                      _addButtonAnimationController
                                                                              .value *
                                                                          math.pi *
                                                                          2,
                                                                    ),
                                                                    colors: const [
                                                                      Color(
                                                                        0xFFFFB300,
                                                                      ),
                                                                      Color(
                                                                        0xFFFF7043,
                                                                      ),
                                                                      Color(
                                                                        0xFFEF5350,
                                                                      ),
                                                                      Color(
                                                                        0xFFFFB300,
                                                                      ),
                                                                    ],
                                                                  )
                                                                : null,
                                                            color: available > 0
                                                                ? null
                                                                : Colors.grey,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  14,
                                                                ),
                                                            boxShadow:
                                                                available > 0
                                                                ? [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .deepOrange
                                                                          .withValues(
                                                                            alpha:
                                                                                0.42,
                                                                          ),
                                                                      blurRadius:
                                                                          10,
                                                                      spreadRadius:
                                                                          1,
                                                                    ),
                                                                  ]
                                                                : null,
                                                          ),
                                                          child: FilledButton.icon(
                                                            onPressed:
                                                                available > 0
                                                                ? () {
                                                                    setState(() {
                                                                      final next =
                                                                          quantity +
                                                                          1;
                                                                      _selectedQuantities[product
                                                                              .id] =
                                                                          next;
                                                                    });
                                                                  }
                                                                : null,
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              disabledBackgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              foregroundColor:
                                                                  Colors.white,
                                                              minimumSize: Size(
                                                                width > 700
                                                                    ? 132
                                                                    : 116,
                                                                50,
                                                              ),
                                                              elevation: 0,
                                                              shadowColor: Colors
                                                                  .transparent,
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        width >
                                                                            700
                                                                        ? 20
                                                                        : 16,
                                                                    vertical:
                                                                        11,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      14,
                                                                    ),
                                                              ),
                                                            ),
                                                            icon: Icon(
                                                              Icons
                                                                  .add_shopping_cart,
                                                              size: width > 700
                                                                  ? 22
                                                                  : 20,
                                                            ),
                                                            label: Text(
                                                              'أضف',
                                                              style: textTheme
                                                                  .labelLarge
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        width >
                                                                            700
                                                                        ? 16
                                                                        : 15,
                                                                  ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                if (quantity > 0) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'في السلة x$quantity',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.zoom_in,
                                              color: Colors.white,
                                              size: 18,
                                            ),
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
