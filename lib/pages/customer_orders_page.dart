import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../models/customer_order_model.dart';
import '../services/product_service.dart';
import '../services/data_service.dart';
import '../db/customer_orders_db.dart';
import 'photo_viewer_page.dart';
import 'slider_images_settings_page.dart';

class _ProductCategory {
  final String title;
  final String imageUrl;
  final List<String> keywords;

  const _ProductCategory({
    required this.title,
    required this.imageUrl,
    required this.keywords,
  });

  bool matches(Product product) {
    final text = '${product.name} ${product.description}'.toLowerCase();
    return keywords.any((keyword) => text.contains(keyword));
  }

  String get header => title;
}

const String whatsappTargetNumber = '+9647746582364';
const String orderTrackingUrl = 'متابعة-الطلب';

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
  final PageController _sliderPageController = PageController();
  final String _sortOption = 'الأحدث';
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

  static const String _categoryImagesPrefKey = 'orders_page_category_images';
  List<String> _categoryImageUrls = [];
  final List<bool> _isCategoryUploading = List.generate(4, (_) => false);

  final List<_ProductCategory> _productCategories = const [
    _ProductCategory(
      title: 'مستلزمات حجامة جملة',
      imageUrl: 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=500&q=80',
      keywords: ['حجامة', 'مستلزمات', 'كاسات', 'زيوت', 'أنابيب', 'جملة'],
    ),
    _ProductCategory(
      title: 'حجامة مفرد',
      imageUrl: 'https://images.unsplash.com/photo-1491553895911-0055eca6402d?auto=format&fit=crop&w=500&q=80',
      keywords: ['حجامة', 'مفرد', 'جلسة', 'شفط', 'تنظيف'],
    ),
    _ProductCategory(
      title: 'العروض الحالية',
      imageUrl: 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=500&q=80',
      keywords: ['عرض', 'تخفيض', 'خصم', 'عرض خاص', 'عرضية'],
    ),
    _ProductCategory(
      title: 'كل المنتجات',
      imageUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?auto=format&fit=crop&w=500&q=80',
      keywords: [''],
    ),
  ];
  bool _showWelcomeDescription = true;
  Timer? _welcomeTimer;

  bool get _canEditSlider {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return false;
    return widget.storeUserId == null || widget.storeUserId == authUser.id;
  }

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadWelcomeState();
    _loadSliderImages();
    _loadCategoryImages();
    _startSliderTimer();
  }

  @override
  void dispose() {
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
          _sliderImageUrls = images.map((img) => img['image_data'] as String).toList();
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

  Future<void> _loadCategoryImages() async {
    try {
      final categories = await fetchCategoryImages();
      if (!mounted) return;
      if (categories.isNotEmpty) {
        setState(() {
          _categoryImageUrls = categories.map((cat) => cat['image_data'] as String).toList();
        });
      } else {
        // استخدام الصور الافتراضية إذا لم تكن هناك صور في Supabase
        final defaults = _productCategories.map((c) => c.imageUrl).toList();
        setState(() {
          _categoryImageUrls = defaults;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل صور الأقسام: $e');
      if (!mounted) return;
      final defaults = _productCategories.map((c) => c.imageUrl).toList();
      setState(() {
        _categoryImageUrls = defaults;
      });
    }
  }

  Future<void> _saveCategoryImages() async {
    // لا مزيد من الحاجة لحفظ في SharedPreferences - البيانات محفوظة في Supabase بالفعل
  }

  Future<void> _pickAndUploadCategoryImage(int index) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result == null) return;

    if (!mounted) return;
    setState(() {
      _isCategoryUploading[index] = true;
    });

    try {
      final categoryName = _productCategories[index].title;
      final keywords = _productCategories[index].keywords;
      
      final success = await uploadImageFromPicker(
        pickedFile: result,
        title: categoryName,
        isSlider: false,
        categoryName: categoryName,
        productKeywords: keywords,
      );
      
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع صورة القسم، حاول مرة أخرى.')),
        );
        return;
      }
      
      // قراءة الصورة كـ base64 وتحديثها في الحالة
      final imageBytes = await result.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      if (!mounted) return;
      setState(() {
        _categoryImageUrls[index] = base64Image;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ صورة القسم بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('خطأ في رفع صورة القسم: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء رفع صورة القسم: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCategoryUploading[index] = false;
        });
      }
    }
  }

  void _startSliderTimer() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _sliderImageUrls.isEmpty || !_sliderPageController.hasClients) return;
      _currentSliderIndex = (_currentSliderIndex + 1) % _sliderImageUrls.length;
      _sliderPageController.animateToPage(
        _currentSliderIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildImageSlider() {
    return Column(
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
                          colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.0)],
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
                color: _currentSliderIndex == index ? Colors.white : Colors.white54,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _showCategoryProducts(_ProductCategory category) {
    final products = _lastProducts.where((product) => category.matches(product)).toList();

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
                  Text(category.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('لا توجد منتجات محددة لهذا القسم حالياً.', style: TextStyle(fontSize: 16)),
                )
              else
                Column(
                  children: products.map((product) {
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(product.description.isEmpty ? 'بدون وصف' : product.description),
                      trailing: Text('${product.price.toStringAsFixed(0)} د.ع'),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(_productCategories.length, (index) {
            final category = _productCategories[index];
            final imageUrl = index < _categoryImageUrls.length && _categoryImageUrls[index].isNotEmpty
                ? _categoryImageUrls[index]
                : category.imageUrl;
            final itemWidth = (MediaQuery.of(context).size.width - 64) / 2;
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () => _showCategoryProducts(category),
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipOval(
                          child: buildImageWidget(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                        ),
                        if (_canEditSlider)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: () {
                                _pickAndUploadCategoryImage(index);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: _isCategoryUploading[index]
                                    ? const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.edit, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      category.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
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

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = _loadProducts();
    });
    await _productsFuture;
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
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported, size: 80),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على الصورة لعرضها بالكامل مع إمكانية التدوير',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
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
                if (product.deliveryPrice != null && product.deliveryPrice! > 0) ...[
                  const SizedBox(height: 8),
                  Text('سعر التوصيل: ${product.deliveryPrice!.toStringAsFixed(0)} د.ع', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
        text.writeln('${i + 1}. ${product.name} x$qty = ${(product.price * qty).toStringAsFixed(0)}');
      }
      text.writeln('---');
      text.writeln('المجموع: ${total.toStringAsFixed(0)}');
      if (orderNote.isNotEmpty) {
        text.writeln('ملاحظات: $orderNote');
      }
      text.writeln('');
      text.writeln('📱 يمكنك متابعة حالة طلبك من التطبيق:');
      text.writeln('- اضغط على أيقونة "متابعة" في الصفحة الرئيسية');
      text.writeln('- أدخل رقم الطلب: $orderNumber');
      text.writeln('- ستشاهد جميع مراحل معالجة طلبك');

      final url = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(text.toString())}');
      final canOpen = await canLaunchUrl(url);
      if (!canOpen) {
        await _showMessage('لا يمكن فتح واتساب على هذا الجهاز');
        return;
      }

      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await _showMessage('فشل فتح واتساب. حاول مرة أخرى.');
        return;
      }

      // حفظ الطلب في قاعدة البيانات بعد الإرسال الناجح
      try {
        final order = CustomerOrderModel(
          orderNumber: orderNumber,
          customerName: customerName.isNotEmpty ? customerName : 'زائر',
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          totalAmount: total,
          status: 'pending',
          notes: orderNote.isNotEmpty ? orderNote : null,
          items: selectedProducts
              .map((p) => {
                    'id': p.id,
                    'name': p.name,
                    'quantity': _selectedQuantities[p.id] ?? 0,
                    'price': p.price,
                  })
              .toList(),
          createdAt: DateTime.now(),
        );
        await CustomerOrdersDatabase.instance.insertOrder(order);
        if (mounted) {
          await _showMessage('✓ تم إرسال الطلب بنجاح! رقم الطلب: $orderNumber');
        }
      } catch (e) {
        debugPrint('Error saving order: $e');
        if (mounted) {
          await _showMessage('تحذير: لم يتم حفظ الطلب محليا، لكن تم إرساله');
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
                              if (product.deliveryPrice != null && product.deliveryPrice! > 0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(color: Colors.green.shade300),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'التوصيل: ${product.deliveryPrice!.toStringAsFixed(0)} د.ع',
                                    style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
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
        title: const Text('متجرنا صمم خصيصا لك'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ابحث عن المنتجات',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
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
                                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SliderImagesSettingsPage()));
                                _loadSliderImages();
                              },
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('تعديل صور السلايدر'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      _buildImageSlider(),
                      const SizedBox(height: 16),
                      _buildCategoriesRow(),
                      const SizedBox(height: 20),
                    ],
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
                                          'اضغط على المنتج لمشاهدة التفاصيل واضغط على أيقونة العربة لإضافة المنتج إلى الطلب.',
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
                    if (_selectedCount > 0) ...[
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
                    ],
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
                          final crossAxisCount = constraints.maxWidth > 1000
                              ? 3
                              : constraints.maxWidth > 650
                                  ? 2
                                  : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                                            child: GestureDetector(
                                              onTap: () {
                                                if (product.imageUrl != null) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => PhotoViewerPage(
                                                        imageUrl: product.imageUrl!,
                                                        productName: product.name,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
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
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
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
                                                        ? Colors.orange.withValues(alpha: 0.95)
                                                        : Colors.green.withValues(alpha: 0.95)
                                                    : Colors.red.withValues(alpha: 0.95),
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
                                                  color: Colors.black.withValues(alpha: 0.7),
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
                                                    '$available قطعة متاحة',
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                  ),
                                              ],
                                            ),
                                            if (product.deliveryPrice != null && product.deliveryPrice! > 0) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  border: Border.all(color: Colors.green.shade300),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'التوصيل: ${product.deliveryPrice!.toStringAsFixed(0)} د.ع',
                                                  style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
