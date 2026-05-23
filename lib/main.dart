import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://bhyqgohtwtvblmlbwcbb.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJoeXFnb2h0d3R2YmxtbGJ3Y2JiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNTkyMjMsImV4cCI6MjA5NDgzNTIyM30.qeGH6AkRgxnSKJIU3r5LEH94HAJ743-SvZ6g0wWkZxg';
const storeShareBaseUrl = 'https://your-merchant-store.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'متجر التجار',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class DebugHome extends StatelessWidget {
  const DebugHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('Debug home: app renders OK', style: TextStyle(fontSize: 18))),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SettingsAction { logout, register, login }

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  bool get _isLoggedIn => supabase.auth.currentUser != null;

  Future<void> _handleSettingsAction(SettingsAction action) async {
    switch (action) {
      case SettingsAction.logout:
        await supabase.auth.signOut();
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
        );
        break;
      case SettingsAction.register:
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
        if (!mounted) return;
        setState(() {});
        break;
      case SettingsAction.login:
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
        if (!mounted) return;
        setState(() {});
        break;
    }
  }

  Future<void> _showStoreLinkDialog() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }

    String? slug;
    try {
      final res = await supabase.from('stores').select('slug,user_id').eq('user_id', user.id).maybeSingle();
      Map<String, dynamic>? map;
      try {
        map = res as Map<String, dynamic>?;
      } catch (_) {
        try {
          map = (res as dynamic).data as Map<String, dynamic>?;
        } catch (_) {
          map = null;
        }
      }
      if (map != null) slug = map['slug']?.toString();
    } catch (e) {
      debugPrint('fetch store link failed: $e');
    }

    final displayLink = slug != null ? 'store.html?slug=$slug' : 'store.html?user_id=${user.id}';

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رابط متجرك'),
        content: SelectableText(displayLink),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: displayLink));
              Navigator.of(ctx).pop();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رابط المتجر')));
            },
            child: const Text('نسخ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StorePage()));
            },
            child: const Text('عرض داخل التطبيق'),
          ),
        ],
      ),
    );
  }

  static const List<Widget> _pages = <Widget>[
    HomeTab(),
    ProductsTab(),
    OrdersTab(),
    MoreTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متجر التجار'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'رابط متجرك',
            onPressed: _showStoreLinkDialog,
          ),
          PopupMenuButton<SettingsAction>(
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
            onSelected: _handleSettingsAction,
            itemBuilder: (context) {
              if (_isLoggedIn) {
                return [
                  const PopupMenuItem(
                    value: SettingsAction.logout,
                    child: Text('تسجيل الخروج'),
                  ),
                ];
              }
              return const [
                PopupMenuItem(
                  value: SettingsAction.register,
                  child: Text('سجل حساب جديد'),
                ),
                PopupMenuItem(
                  value: SettingsAction.login,
                  child: Text('تسجيل دخول'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'المنتجات'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'الطلبات'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.session == null) {
        throw AuthException('فشل تسجيل الدخول، تأكد من البريد الإلكتروني وكلمة المرور');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور وتأكيدها غير متطابقين')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user == null) {
        throw AuthException('فشل إنشاء الحساب، حاول مرة أخرى');
      }

      // محاولة إنشاء سجل متجر للمستخدم الجديد (إن وجد جدول stores)
      String? createdSlug;
      try {
        final newUser = response.user!;
        final storeSlug = newUser.id.toString().split('-').first;
        createdSlug = storeSlug;
        await Supabase.instance.client.from('stores').insert({
          'user_id': newUser.id,
          'slug': storeSlug,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // تجاهل أي خطأ إن كان جدول stores غير موجود أو فشل الإدخال
        debugPrint('Create store record skipped or failed: $e');
      }

      // ملاحظة: Supabase يقوم عادةً بإرسال رسالة تأكيد البريد الإلكتروني
      // تلقائيًا عند التسجيل، لذلك لا نحتاج إلى استدعاء دالة غير موجودة هنا.

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب، تحقق من بريدك الإلكتروني لتأكيد الحساب')),
      );

      // عرض رابط المتجر الذي تم إنشاؤه (slug) إن وُجد
      if (createdSlug != null) {
        final storeLinkSlug = 'store.html?slug=$createdSlug';
        final storeLinkUser = 'store.html?user_id=${response.user!.id}';
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('رابط المتجر'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('رابط بالـ slug:'),
                SelectableText(storeLinkSlug),
                const SizedBox(height: 8),
                Text('رابط بالـ user_id:'),
                SelectableText(storeLinkUser),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: storeLinkSlug));
                  Navigator.of(ctx).pop();
                },
                child: const Text('نسخ رابط الـ slug'),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: storeLinkUser));
                  Navigator.of(ctx).pop();
                },
                child: const Text('نسخ رابط الـ user_id'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }

      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء الحساب: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل حساب جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى تأكيد كلمة المرور';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('تسجيل حساب جديد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? _slug;
  String? _storeUserId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreLink();
  }

  Future<void> _loadStoreLink() async {
    setState(() => _loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final res = await supabase.from('stores').select('slug,user_id').eq('user_id', user.id).maybeSingle();
      if (res != null) {
        // res may be a Map or have .data depending on client response
        Map<String, dynamic>? map;
        try {
          map = res as Map<String, dynamic>;
        } catch (_) {
          try {
            map = (res as dynamic).data as Map<String, dynamic>?;
          } catch (_) {
            map = null;
          }
        }
        if (map != null) {
          // capture values outside the closure so the analyzer knows they
          // are non-null when used inside setState
          final slugVal = map['slug']?.toString();
          final storeUserIdVal = map['user_id']?.toString() ?? user.id;
          setState(() {
            _slug = slugVal;
            _storeUserId = storeUserIdVal;
          });
        } else {
          setState(() {
            _storeUserId = user.id;
          });
        }
      } else {
        setState(() {
          _storeUserId = user.id;
        });
      }
    } catch (e) {
      debugPrint('load store link error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLink = _slug != null
        ? 'store.html?slug=$_slug'
        : _storeUserId != null
            ? 'store.html?user_id=$_storeUserId'
            : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'رابط متجرك',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('هذا هو الرابط الذي يشاركه الزبائن:'),
                  const SizedBox(height: 8),
                  if (_loading) const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  if (displayLink != null) ...[
                    SelectableText(
                      displayLink,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('عرض المتجر'),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StorePage()));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text('نسخ الرابط'),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: displayLink));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ رابط المتجر إلى الحافظة')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else if (!_loading) ...[
                    const Text('لا يوجد رابط متجر حالي. سجّل الدخول أو تأكد من وجود سجل متجر في قاعدة البيانات.'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'إضافة منتج جديد',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('يمكنك إضافة المنتج ورفعه إلى المتجر مباشرةً.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة منتج'),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductPage()));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'معرض المنتجات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const ProductPreviewList(),
        ],
      ),
    );
  }
}

enum ProductFilter { all, lowStock, wholesale }

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  static const int _pageSize = 12;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Product> _products = [];
  ProductFilter _selectedFilter = ProductFilter.all;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 120 && !_isLoading && _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      _products.clear();
      _hasMore = true;
      _errorMessage = null;
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final start = _products.length;
      final end = start + _pageSize - 1;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول لعرض المنتجات';
          _isLoading = false;
        });
        return;
      }
      final dynamic res = await supabase.from('products').select().eq('user_id', user.id).order('created_at', ascending: false).range(start, end);
      List<dynamic> list;
      try {
        list = res as List<dynamic>;
      } catch (_) {
        try {
          list = (res as dynamic).data as List<dynamic>;
        } catch (_) {
          list = [];
        }
      }
      final pageProducts = list.map((item) => Product.fromMap(item as Map<String, dynamic>)).toList();
      setState(() {
        _products.addAll(pageProducts);
        _hasMore = pageProducts.length == _pageSize;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_products.isEmpty) {
          _errorMessage = e.toString();
        }
      });
      if (_products.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث المنتجات، عرض البيانات المحفوظة محليًا')));
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProducts() async {
    await _loadNextPage(reset: true);
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا المنتج نهائيًا؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await supabase.from('products').delete().eq('id', product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنتج')));
      _refreshProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل حذف المنتج: $e')));
    }
  }

  Future<void> _setProductQuantity(Product product) async {
    final controller = TextEditingController(text: product.remainingQty.toString());
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الكمية'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: const InputDecoration(labelText: 'الكمية الجديدة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result == null) return;

    try {
      await supabase.from('products').update({'remaining_qty': result}).eq('id', product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الكمية')));
      _refreshProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تحديث الكمية: $e')));
    }
  }

  List<Product> _applyFilters(List<Product> products) {
    var filtered = products;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((product) => product.name.toLowerCase().contains(query) || product.description.toLowerCase().contains(query)).toList();
    }

    switch (_selectedFilter) {
      case ProductFilter.lowStock:
        return filtered.where((product) => product.remainingQty <= 5).toList();
      case ProductFilter.wholesale:
        return filtered.where((product) => product.hasWholesale).toList();
      case ProductFilter.all:
      default:
        return filtered;
    }
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: ProductFilter.values.map((filter) {
        final label = switch (filter) {
          ProductFilter.all => 'الكل',
          ProductFilter.lowStock => 'مخزون منخفض',
          ProductFilter.wholesale => 'الجملة فقط',
        };
        return ChoiceChip(
          label: Text(label),
          selected: _selectedFilter == filter,
          onSelected: (_) {
            setState(() {
              _selectedFilter = filter;
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _applyFilters(_products);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج جديد'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductPage())).then((_) => _refreshProducts());
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'بحث في المنتجات',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 20),
          const Text('جميع المنتجات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              child: _errorMessage != null && _products.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                                const SizedBox(height: 12),
                                Text('خطأ في تحميل المنتجات: $_errorMessage', textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(onPressed: _refreshProducts, child: const Text('إعادة المحاولة')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : filteredProducts.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  _products.isEmpty
                                      ? 'لا يوجد منتجات بعد.'
                                      : 'لا توجد منتجات تطابق البحث أو الفلتر.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredProducts.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= filteredProducts.length) {
                              if (_isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: FilledButton(
                                    onPressed: _loadNextPage,
                                    child: const Text('تحميل المزيد'),
                                  ),
                                ),
                              );
                            }
                            final product = filteredProducts[index];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: product.imageUrl != null
                                      ? Image.network(product.imageUrl!, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 72, height: 72, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)))
                                      : Container(width: 72, height: 72, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                                ),
                                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text('السعر: ${product.price.toStringAsFixed(0)}'),
                                    Text('المخزون: ${product.remainingQty} قطعة'),
                                    if (product.hasWholesale) Text('جملة: ${product.wholesalePrice.toStringAsFixed(0)} من ${product.minWholesaleQuantity} قطع'),
                                    if (product.singlePrice > 0) Text('سعر المفرد: ${product.singlePrice.toStringAsFixed(0)}'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(builder: (_) => EditProductPage(product: product)))
                                            .then((_) => _refreshProducts());
                                        break;
                                      case 'delete':
                                        _deleteProduct(product);
                                        break;
                                      case 'stock':
                                        _setProductQuantity(product);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                    const PopupMenuItem(value: 'stock', child: Text('تعديل الكمية')),
                                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))).then((_) => _refreshProducts());
                                },
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductPreviewList extends StatefulWidget {
  const ProductPreviewList({super.key});

  @override
  State<ProductPreviewList> createState() => _ProductPreviewListState();
}

class _ProductPreviewListState extends State<ProductPreviewList> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  Future<List<Product>> _loadProducts() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];
      final dynamic res = await supabase.from('products').select().eq('user_id', user.id).order('created_at', ascending: false);
      List<dynamic> list;
      try {
        list = res as List<dynamic>;
      } catch (_) {
        try {
          list = (res as dynamic).data as List<dynamic>;
        } catch (_) {
          return [];
        }
      }
      return list.map((item) => Product.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل المنتجات: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('لا يوجد منتجات بعد.')));
          }
          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: products.take(4).map((product) {
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.imageUrl != null
                        ? Image.network(product.imageUrl!, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)))
                        : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                  title: Text(product.name),
                  subtitle: Text('السعر: ${product.price.toStringAsFixed(0)}\nالمخزون: ${product.remainingQty} قطعة'),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _minWholesaleController = TextEditingController();
  final _singlePriceController = TextEditingController();
  final _remainingQtyController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _hasWholesale = false;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (result != null) {
      final bytes = await result.readAsBytes();
      setState(() {
        _pickedImage = result;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadImage(XFile file) async {
    try {
      final bytes = _pickedImageBytes ?? await file.readAsBytes();
      final sanitizedName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
      final storagePath = 'products/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      
      final uploadResponse = await supabase.storage.from('product-images').uploadBinary(storagePath, bytes);
      debugPrint('Upload response: $uploadResponse');
      
      final bucketUrl = supabase.storage.from('product-images').getPublicUrl(storagePath);
      debugPrint('Bucket URL: $bucketUrl');
      
      if (bucketUrl.isEmpty) {
        debugPrint('Error: Public URL is empty');
        return null;
      }
      
      debugPrint('Image uploaded successfully: $bucketUrl');
      return bucketUrl;
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع الصورة: $e')),
      );
      return null;
    }
  }

  String _normalizeNumberString(String value) {
    var text = value.trim();
    text = text.replaceAll(RegExp(r'[٬،٫]'), '.');
    text = text.replaceAll(RegExp(r'[ -]'), '');
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const westernDigits = '0123456789';
    for (var i = 0; i < arabicDigits.length; i++) {
      text = text.replaceAll(arabicDigits[i], westernDigits[i]);
    }
    return text;
  }

  double? _parseDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(_normalizeNumberString(value));
  }

  int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(_normalizeNumberString(value));
  }

  Future<void> _saveProduct() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً قبل إضافة منتج')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final price = _parseDouble(_priceController.text) ?? 0;
    final cost = _parseDouble(_costController.text) ?? 0;
    final wholesalePrice = _parseDouble(_wholesalePriceController.text) ?? 0;
    final minWholesale = _parseInt(_minWholesaleController.text) ?? 0;
    final singlePrice = _parseDouble(_singlePriceController.text) ?? 0;
    final remainingQty = _parseInt(_remainingQtyController.text) ?? 0;
    final description = _descriptionController.text.trim();

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadImage(_pickedImage!);
    }

    final insertData = {
      'name': _nameController.text.trim(),
      'description': description,
      'price': price.toInt(),
      'cost': cost.toInt(),
      'wholesale_price': wholesalePrice.toInt(),
      'min_wholesale_quantity': minWholesale,
      'single_price': singlePrice.toInt(),
      'has_wholesale': _hasWholesale,
      'remaining_qty': remainingQty,
      if (imageUrl != null) 'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
      'user_id': user.id,
    };

    try {
      await supabase.from('products').insert(insertData);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء حفظ المنتج: $e')));
      return;
    }
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المنتج بنجاح')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى كتابة اسم المنتج' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'سعر البيع'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى كتابة سعر البيع';
                  }
                  final parsed = _parseDouble(value);
                  if (parsed == null || parsed <= 0) {
                    return 'يرجى كتابة سعر صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'تكلفة المنتج'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('بيع بالجملة'),
                value: _hasWholesale,
                onChanged: (value) => setState(() => _hasWholesale = value),
              ),
              if (_hasWholesale) ...[
                TextFormField(
                  controller: _wholesalePriceController,
                  decoration: const InputDecoration(labelText: 'سعر الجملة'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minWholesaleController,
                  decoration: const InputDecoration(labelText: 'أقل عدد للجملة'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _singlePriceController,
                decoration: const InputDecoration(labelText: 'سعر المفرد (اختياري)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remainingQtyController,
                decoration: const InputDecoration(labelText: 'الكمية المتبقية'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text('اختر صورة'),
                onPressed: _pickImage,
              ),
              if (_pickedImageBytes != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_pickedImageBytes!, height: 180, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _saveProduct,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('حفظ المنتج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({required this.product, super.key});

  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isProcessing = false;

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا المنتج نهائيًا؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await supabase.from('products').delete().eq('id', widget.product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنتج')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل حذف المنتج: $e')));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateQuantity() async {
    final controller = TextEditingController(text: widget.product.remainingQty.toString());
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الكمية'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: const InputDecoration(labelText: 'الكمية الجديدة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      await supabase.from('products').update({'remaining_qty': result}).eq('id', widget.product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الكمية')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تحديث الكمية: $e')));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  product.imageUrl!,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        height: 300,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 100),
                      ),
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.image_not_supported, size: 100),
              ),
            const SizedBox(height: 24),
            Text(
              product.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    const Text('معلومات الأسعار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          const Text('سعر البيع:'),
                        Text('${product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (product.cost > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          const Text('تكلفة المنتج:'),
                          Text('${product.cost.toStringAsFixed(0)}'),
                        ],
                      ),
                    if (product.singlePrice > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          const Text('سعر المفرد:'),
                          Text('${product.singlePrice.toStringAsFixed(0)}'),
                        ],
                      ),
                    ],
                    if (product.hasWholesale) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('معلومات الجملة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('سعر الجملة:'),
                          Text('${product.wholesalePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الحد الأدنى للجملة:'),
                          Text('${product.minWholesaleQuantity} قطعة'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المخزون', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الكمية المتبقية:'),
                        Text(
                          '${product.remainingQty} قطعة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: product.remainingQty > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الوصف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(product.description),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('تعديل المعلومات'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProductPage(product: product))).then((result) {
                  if (result == true) {
                    Navigator.of(context).pop(true);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.inventory),
              label: const Text('تعديل الكمية'),
              onPressed: _isProcessing ? null : _updateQuantity,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('حذف المنتج'),
              onPressed: _isProcessing ? null : _deleteProduct,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class EditProductPage extends StatefulWidget {
  const EditProductPage({required this.product, super.key});

  final Product product;

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _minWholesaleController;
  late TextEditingController _singlePriceController;
  late TextEditingController _remainingQtyController;
  late TextEditingController _descriptionController;
  late bool _hasWholesale;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _costController = TextEditingController(text: widget.product.cost.toString());
    _wholesalePriceController = TextEditingController(text: widget.product.wholesalePrice.toString());
    _minWholesaleController = TextEditingController(text: widget.product.minWholesaleQuantity.toString());
    _singlePriceController = TextEditingController(text: widget.product.singlePrice.toString());
    _remainingQtyController = TextEditingController(text: widget.product.remainingQty.toString());
    _descriptionController = TextEditingController(text: widget.product.description);
    _hasWholesale = widget.product.hasWholesale;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _wholesalePriceController.dispose();
    _minWholesaleController.dispose();
    _singlePriceController.dispose();
    _remainingQtyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (result != null) {
      final bytes = await result.readAsBytes();
      setState(() {
        _pickedImage = result;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadImage(XFile file) async {
    try {
      final bytes = _pickedImageBytes ?? await file.readAsBytes();
      final sanitizedName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
      final storagePath = 'products/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      
      final uploadResponse = await supabase.storage.from('product-images').uploadBinary(storagePath, bytes);
      debugPrint('Upload response: $uploadResponse');
      
      final bucketUrl = supabase.storage.from('product-images').getPublicUrl(storagePath);
      debugPrint('Bucket URL: $bucketUrl');
      
      if (bucketUrl.isEmpty) {
        debugPrint('Error: Public URL is empty');
        return null;
      }
      
      debugPrint('Image uploaded successfully: $bucketUrl');
      return bucketUrl;
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع الصورة: $e')),
      );
      return null;
    }
  }

  String _normalizeNumberString(String value) {
    var text = value.trim();
    text = text.replaceAll(RegExp(r'[\u066c\u060c\u066b]'), '.');
    text = text.replaceAll(RegExp(r'[\u0000-\u001f]'), '');
    const arabicDigits = '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669';
    const westernDigits = '0123456789';
    for (var i = 0; i < arabicDigits.length; i++) {
      text = text.replaceAll(arabicDigits[i], westernDigits[i]);
    }
    return text;
  }

  double? _parseDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(_normalizeNumberString(value));
  }

  int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(_normalizeNumberString(value));
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final price = _parseDouble(_priceController.text) ?? 0;
    final cost = _parseDouble(_costController.text) ?? 0;
    final wholesalePrice = _parseDouble(_wholesalePriceController.text) ?? 0;
    final minWholesale = _parseInt(_minWholesaleController.text) ?? 0;
    final singlePrice = _parseDouble(_singlePriceController.text) ?? 0;
    final remainingQty = _parseInt(_remainingQtyController.text) ?? 0;
    final description = _descriptionController.text.trim();

    String? imageUrl = widget.product.imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadImage(_pickedImage!);
    }

    final updateData = {
      'name': _nameController.text.trim(),
      'description': description,
      'price': price.toInt(),
      'cost': cost.toInt(),
      'wholesale_price': wholesalePrice.toInt(),
      'min_wholesale_quantity': minWholesale,
      'single_price': singlePrice.toInt(),
      'has_wholesale': _hasWholesale,
      'remaining_qty': remainingQty,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    try {
      await supabase.from('products').update(updateData).eq('id', widget.product.id);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء تحديث المنتج: $e')));
      return;
    }
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث المنتج بنجاح')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل المنتج')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'يرجى كتابة اسم المنتج' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'سعر البيع'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى كتابة سعر البيع';
                  }
                  final parsed = _parseDouble(value);
                  if (parsed == null || parsed <= 0) {
                    return 'يرجى كتابة سعر صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'تكلفة المنتج'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('بيع بالجملة'),
                value: _hasWholesale,
                onChanged: (value) => setState(() => _hasWholesale = value),
              ),
              if (_hasWholesale) ...[
                TextFormField(
                  controller: _wholesalePriceController,
                  decoration: const InputDecoration(labelText: 'سعر الجملة'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minWholesaleController,
                  decoration: const InputDecoration(labelText: 'أقل عدد للجملة'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _singlePriceController,
                decoration: const InputDecoration(labelText: 'سعر المفرد (اختياري)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remainingQtyController,
                decoration: const InputDecoration(labelText: 'الكمية المتبقية'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (widget.product.imageUrl != null) ...[
                const Text('الصورة الحالية:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(widget.product.imageUrl!, height: 150, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text('تغيير الصورة'),
                onPressed: _pickImage,
              ),
              if (_pickedImageBytes != null) ...[
                const SizedBox(height: 16),
                const Text('الصورة الجديدة:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_pickedImageBytes!, height: 180, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _updateProduct,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('تحديث المنتج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  static const int _pageSize = 10;
  final List<Product> _products = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 120 && !_isLoading && _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      _products.clear();
      _hasMore = true;
      _errorMessage = null;
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final start = _products.length;
      final end = start + _pageSize - 1;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول لعرض المنتجات';
          _isLoading = false;
        });
        return;
      }
      final dynamic res = await supabase.from('products').select().eq('user_id', user.id).order('created_at', ascending: false).range(start, end);
      List<dynamic> list;
      try {
        list = res as List<dynamic>;
      } catch (_) {
        try {
          list = (res as dynamic).data as List<dynamic>;
        } catch (_) {
          list = [];
        }
      }
      final pageProducts = list.map((item) => Product.fromMap(item as Map<String, dynamic>)).toList();
      setState(() {
        _products.addAll(pageProducts);
        _hasMore = pageProducts.length == _pageSize;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_products.isEmpty) {
          _errorMessage = e.toString();
        }
      });
      if (_products.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث المنتجات، عرض البيانات المحفوظة محليًا')));
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProducts() async {
    await _loadNextPage(reset: true);
  }

  void _showQuickView(Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (product.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(product.imageUrl!, height: 180, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(product.description.isNotEmpty ? product.description : 'لا يوجد وصف لهذا المنتج بعد.'),
            const SizedBox(height: 12),
            Text('السعر: ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (product.hasWholesale) Text('الجملة: ${product.wholesalePrice.toStringAsFixed(0)} من ${product.minWholesaleQuantity} قطعة'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))).then((_) => _refreshProducts());
              },
              child: const Text('عرض التفاصيل'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('واجهة المتجر')),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: _errorMessage != null && _products.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text('حدث خطأ: $_errorMessage', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _refreshProducts, child: const Text('إعادة المحاولة')),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: _products.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _products.length) {
                    if (_isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Center(
                      child: FilledButton(onPressed: _loadNextPage, child: const Text('تحميل المزيد')),
                    );
                  }
                  final product = _products[index];
                  return GestureDetector(
                    onTap: () => _showQuickView(product),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              child: product.imageUrl != null
                                  ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 40)))
                                  : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 40)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('السعر: ${product.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('الكمية: ${product.remainingQty}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))).then((_) => _refreshProducts()),
                                  child: const Text('عرض المنتج'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

enum OrderStatusFilter { all, pending, inDelivery, completed, cancelled }

class _OrdersTabState extends State<OrdersTab> {
  static const int _pageSize = 12;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<Order> _orders = [];
  OrderStatusFilter _selectedStatus = OrderStatusFilter.all;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadNextPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 120 && !_isLoading && _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      _orders.clear();
      _hasMore = true;
      _errorMessage = null;
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // تأكد من وجود مستخدم مسجل للحصول على الطلبات الخاصة به
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول لعرض الطلبات';
          _isLoading = false;
        });
        return;
      }

      // بدلاً من استخدام range، سنأخذ جميع الطلبات الخاصة بالمستخدم
      final dynamic res = await supabase
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      List<dynamic> list;
      try {
        list = res as List<dynamic>;
      } catch (_) {
        try {
          list = (res as dynamic).data as List<dynamic>;
        } catch (_) {
          list = [];
        }
      }

      // بعض قواعد البيانات تخزن الطلب كاملًا في صف واحد (بـ 'items' كمصفوفة)،
      // وبعضها يخزن كل عنصر كصف منفصل مرتبط بـ 'order_id'. ندعم الحالتين.
      debugPrint('Orders response count: ${list.length}');
      if (list.isNotEmpty) debugPrint('First order raw: ${list.first}');

      final Map<String, List<Map<String, dynamic>>> groupedOrders = {};
      final List<Order> allOrders = [];

      for (final raw in list) {
        final map = raw as Map<String, dynamic>;
        // إذا الصف يحتوي على 'items' فهذا صف يمثل طلبًا كاملاً
        final itemsField = map['items'];
        if (itemsField is List && itemsField.isNotEmpty) {
          final firstRow = Map<String, dynamic>.from(map);
          firstRow['items'] = itemsField;
          try {
            allOrders.add(Order.fromMap(firstRow));
          } catch (e, st) {
            debugPrint('Error parsing full-order row (skipping): $e\n$st');
          }
          continue;
        }

        // خلاف ذلك، نجمع الصفوف حسب order_id أو id
        final orderId = (map['order_id'] ?? map['id'] ?? '').toString();
        groupedOrders.putIfAbsent(orderId, () => []).add(Map<String, dynamic>.from(map));
      }

      // الآن نحول المجموعات إلى أوامر
      for (final entry in groupedOrders.entries) {
        final firstRow = Map<String, dynamic>.from(entry.value.first);
        firstRow['items'] = entry.value;
        try {
          allOrders.add(Order.fromMap(firstRow));
        } catch (e, st) {
          debugPrint('Error creating Order from grouped rows (skipping): $e\n$st');
        }
      }

      // فرز تنازلي حسب التاريخ
      allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // تطبيق pagination
      final startIdx = _orders.length;
      final endIdx = (startIdx + _pageSize).clamp(0, allOrders.length);
      final paginatedOrders = allOrders.sublist(startIdx, endIdx);

      setState(() {
        _orders.addAll(paginatedOrders);
        _hasMore = paginatedOrders.length == _pageSize && endIdx < allOrders.length;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (!mounted) return;
      setState(() {
        if (_orders.isEmpty) {
          _errorMessage = e.toString();
        }
      });
      if (_orders.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحميل المزيد من الطلبات، عرض البيانات المحفوظة محليًا')));
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Order> _applyFilters(List<Order> orders) {
    final query = _searchController.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesSearch = query.isEmpty ||
          order.id.toString().contains(query) ||
          (order.customerName?.toLowerCase().contains(query) ?? false) ||
          order.items.any((item) => item.name.toLowerCase().contains(query));
      final matchesStatus = switch (_selectedStatus) {
        OrderStatusFilter.all => true,
        OrderStatusFilter.pending => order.status.toLowerCase() == 'pending',
        OrderStatusFilter.inDelivery => order.status.toLowerCase() == 'in_delivery',
        OrderStatusFilter.completed => order.status.toLowerCase() == 'completed',
        OrderStatusFilter.cancelled => order.status.toLowerCase() == 'cancelled',
      };
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _refreshOrders() async {
    await _loadNextPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todaysOrders = _orders.where((o) {
      final d = o.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final dailyCount = todaysOrders.length;
    final dailySales = todaysOrders.fold<double>(0, (sum, o) => sum + o.total);
    final pendingCount = _orders.where((o) => o.status.toLowerCase() == 'pending').length;
    final filteredOrders = _applyFilters(_orders);

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('إنشاء طلب جديد'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateOrderPage())).then((_) => _refreshOrders());
              },
            ),
            const SizedBox(height: 20),
            const Text('قائمة الطلبات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'بحث في الطلبات',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OrderStatusFilter.values.map((filter) {
                final label = switch (filter) {
                  OrderStatusFilter.all => 'الكل',
                  OrderStatusFilter.pending => 'قيد الانتظار',
                  OrderStatusFilter.inDelivery => 'قيد التوصيل',
                  OrderStatusFilter.completed => 'مكتمل',
                  OrderStatusFilter.cancelled => 'ملغى',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: _selectedStatus == filter,
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = filter;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _errorMessage != null && _orders.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                                const SizedBox(height: 12),
                                Text('خطأ في تحميل الطلبات: $_errorMessage', textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(onPressed: _refreshOrders, child: const Text('إعادة المحاولة')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : _orders.isEmpty && _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredOrders.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'لا توجد طلبات تطابق البحث أو الفلتر.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: 1 + filteredOrders.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Card(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('الطلبات اليوم', style: TextStyle(color: Colors.black54)),
                                              const SizedBox(height: 8),
                                              Text('$dailyCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Card(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('إجمالي المبيعات اليوم', style: TextStyle(color: Colors.black54)),
                                              const SizedBox(height: 8),
                                              Text('${dailySales.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Card(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('طلبات قيد الانتظار', style: TextStyle(color: Colors.black54)),
                                              const SizedBox(height: 8),
                                              Text('$pendingCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (index == 1 + filteredOrders.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final order = filteredOrders[index - 1];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text('طلب رقم ${order.id}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (order.customerName != null && order.customerName!.isNotEmpty)
                                      Text('العميل: ${order.customerName}'),
                                    Text('العدد: ${order.items.length} • المجموع: ${order.total.toStringAsFixed(0)}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => OrderDetailsPage(order: order)))
                                      .then((_) => _refreshOrders());
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Order _currentOrder;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  String get _formattedDate {
    final date = _currentOrder.createdAt.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get _statusLabel {
    switch (_currentOrder.status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_delivery':
        return 'قيد التوصيل';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return _currentOrder.status;
    }
  }

  Color get _statusColor {
    switch (_currentOrder.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_delivery':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      // تحديث جميع صفوف الطلب بالحالة الجديدة
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('order_id', _currentOrder.id.toString());

      if (!mounted) return;
      setState(() {
        _currentOrder = Order(
          id: _currentOrder.id,
          items: _currentOrder.items,
          total: _currentOrder.total,
          status: newStatus,
          createdAt: _currentOrder.createdAt,
          customerName: _currentOrder.customerName,
          customerPhone: _currentOrder.customerPhone,
          notes: _currentOrder.notes,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة الطلب بنجاح')),
      );
      // أغلق الصفحة وارجع لصفحة القائمة لتحديثها
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث حالة الطلب: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل الطلب #${_currentOrder.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تاريخ الطلب', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(_formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('حالة الطلب', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.2),
                        border: Border.all(color: _statusColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_currentOrder.customerName != null && _currentOrder.customerName!.isNotEmpty) ...[
                      const Text('اسم العميل', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(_currentOrder.customerName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ],
                    if (_currentOrder.customerPhone != null && _currentOrder.customerPhone!.isNotEmpty) ...[
                      const Text('رقم الهاتف', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(_currentOrder.customerPhone!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ],
                    const Text('عدد العناصر', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text('${_currentOrder.items.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('إجمالي الطلب', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text('${_currentOrder.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('تحديث حالة الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _isUpdating ? null : () => _updateOrderStatus('pending'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _currentOrder.status.toLowerCase() == 'pending' ? Colors.orange : Colors.orange.withOpacity(0.6),
                  ),
                  child: const Text('قيد الانتظار'),
                ),
                FilledButton(
                  onPressed: _isUpdating ? null : () => _updateOrderStatus('in_delivery'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _currentOrder.status.toLowerCase() == 'in_delivery' ? Colors.blue : Colors.blue.withOpacity(0.6),
                  ),
                  child: const Text('قيد التوصيل'),
                ),
                FilledButton(
                  onPressed: _isUpdating ? null : () => _updateOrderStatus('completed'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _currentOrder.status.toLowerCase() == 'completed' ? Colors.green : Colors.green.withOpacity(0.6),
                  ),
                  child: const Text('مكتمل'),
                ),
                FilledButton(
                  onPressed: _isUpdating ? null : () => _updateOrderStatus('cancelled'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _currentOrder.status.toLowerCase() == 'cancelled' ? Colors.red : Colors.red.withOpacity(0.6),
                  ),
                  child: const Text('ملغي'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('تفاصيل العناصر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _currentOrder.items.isEmpty
                  ? const Center(child: Text('لا توجد عناصر في هذا الطلب'))
                  : SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                        },
                        border: TableBorder.all(color: Colors.grey[300]!),
                        children: [
                          // Header Row
                          TableRow(
                            decoration: BoxDecoration(color: Colors.deepPurple[100]),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          ),
                          // Data Rows
                          ..._currentOrder.items.map((item) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(item.name, style: const TextStyle(fontSize: 13)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text('${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text('${item.quantity}', style: const TextStyle(fontSize: 13)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text('${item.total.toStringAsFixed(0)}', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple)),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.storefront, size: 80, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('مرحبًا بك في لوحة التحكم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('في هذا القسم يمكنك الإطلاع على حالة المتجر، إدارة المنتجات، والطلبات بسهولة.'),
          ],
        ),
      ),
    );
  }
}

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final Map<int, int> _orderQuantities = {};
  final List<OrderItem> _manualItems = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _orderNotesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _orderNotesController.dispose();
    super.dispose();
  }

  Future<List<Product>> _fetchProducts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final response = await supabase.from('products').select().eq('user_id', user.id).order('created_at', ascending: false) as List<dynamic>;
    return response.map((item) => Product.fromMap(item as Map<String, dynamic>)).toList();
  }

  double get _manualTotal => _manualItems.fold<double>(0, (sum, item) => sum + item.total);

  Future<void> _saveOrder(List<Product> products) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً قبل إنشاء الطلب')),
      );
      return;
    }

    final selectedItems = <Map<String, dynamic>>[];
    for (final product in products) {
      final quantity = _orderQuantities[product.id] ?? 0;
      if (quantity > 0) {
        selectedItems.add({
          'name': product.name,
          'price': product.price.toInt(),
          'quantity': quantity,
          'total': (product.price * quantity).toInt(),
        });
      }
    }
    for (final item in _manualItems) {
      selectedItems.add(item.toJson());
    }
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار منتج واحد على الأقل')));
      return;
    }

    // بناء خريطة الكميات المطلوبة من المنتجات المحددة
    final Map<int, int> qtyMap = {};
    for (final product in products) {
      final q = _orderQuantities[product.id] ?? 0;
      if (q > 0) qtyMap[product.id] = q;
    }

    // تحقق من توافر الكميات المطلوبة
    for (final product in products) {
      final requested = qtyMap[product.id] ?? 0;
      if (requested > 0 && requested > product.remainingQty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الكمية المطلوبة من "${product.name}" (${requested}) تتجاوز المتوفر (${product.remainingQty})')));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final createdAt = DateTime.now().toIso8601String();
      
      final rows = selectedItems.map((item) => {
        'user_id': user.id,
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'total': item['total'],
        'status': 'pending',
        'customer_name': _customerNameController.text.trim(),
        'customer_phone': _customerPhoneController.text.trim(),
        'notes': _orderNotesController.text.trim(),
        'created_at': createdAt,
          }).toList();

      debugPrint('Order insert rows: $rows');
      await supabase.from('orders').insert(rows);

      // ثم نخفض الكميات في جدول المنتجات
      for (final product in products) {
        final q = qtyMap[product.id] ?? 0;
        if (q <= 0) continue;
        final newQty = (product.remainingQty - q).clamp(0, 1 << 31);
        try {
          await supabase.from('products').update({'remaining_qty': newQty}).eq('id', product.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء الطلب ولكن فشل تحديث مخزون "${product.name}": $e')));
          }
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      debugPrint('Order insert error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء إنشاء الطلب: $e')));
      return;
    }
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الطلب بنجاح')));
    Navigator.of(context).pop();
  }

  void _showAddManualItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منتج جديد للطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المنتج')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'العدد'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0;
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (name.isEmpty || price <= 0 || quantity <= 0) {
                return;
              }
              setState(() {
                _manualItems.add(OrderItem(name: name, price: price, quantity: quantity));
              });
              Navigator.of(context).pop();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء طلب جديد')),
      body: FutureBuilder<List<Product>>(
        future: _fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل المنتجات: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          final filteredProducts = products.where((product) {
            final query = _searchController.text.trim().toLowerCase();
            return query.isEmpty ||
                product.name.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query);
          }).toList();
          final productsTotal = products.fold<double>(0, (sum, product) {
            final quantity = _orderQuantities[product.id] ?? 0;
            return sum + quantity * product.price;
          });
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const Text('اختر منتجات من المتجر أو أضف منتجًا جديدًا يدوياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('بيانات العميل', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _customerNameController,
                                decoration: const InputDecoration(labelText: 'اسم العميل'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _customerPhoneController,
                                decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _orderNotesController,
                                decoration: const InputDecoration(labelText: 'ملاحظات الطلب (اختياري)'),
                                minLines: 2,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'بحث في المنتجات',
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
                      if (filteredProducts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              products.isEmpty ? 'لا يوجد منتجات في المتجر.' : 'لا توجد منتجات تطابق البحث.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ...filteredProducts.map((product) {
                        final quantity = _orderQuantities[product.id] ?? 0;
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: product.imageUrl != null
                                  ? Image.network(product.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                                  : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                            ),
                            title: Text(product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('السعر: ${product.price.toStringAsFixed(0)}'),
                                Text('المخزون: ${product.remainingQty} قطعة'),
                                if (quantity > 0)
                                  Text('محددة: $quantity', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 130,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: quantity > 0
                                        ? () {
                                            setState(() {
                                              final next = quantity - 1;
                                              if (next <= 0) {
                                                _orderQuantities.remove(product.id);
                                              } else {
                                                _orderQuantities[product.id] = next;
                                              }
                                            });
                                          }
                                        : null,
                                  ),
                                  Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: product.remainingQty > quantity
                                        ? () {
                                            setState(() {
                                              _orderQuantities[product.id] = quantity + 1;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة منتج يدوياً'),
                        onPressed: _showAddManualItemDialog,
                      ),
                      if (_manualItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('منتجات يدوية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._manualItems.map((item) => Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text('سعر الوحدة: ${item.price.toStringAsFixed(0)} • الكمية: ${item.quantity}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() => _manualItems.remove(item));
                                  },
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('ملخص الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('عدد السلع المحددة'),
                            Text(_orderQuantities.values.fold<int>(0, (sum, qty) => sum + qty).toString()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('مجموع منتجات المتجر'),
                            Text('${productsTotal.toStringAsFixed(0)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('مجموع المنتجات اليدوية'),
                            Text('${_manualTotal.toStringAsFixed(0)}'),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الإجمالي الكلي', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${(productsTotal + _manualTotal).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _isSaving ? null : () => _saveOrder(products),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('إنشاء الطلب'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.cost,
    required this.wholesalePrice,
    required this.minWholesaleQuantity,
    required this.singlePrice,
    required this.hasWholesale,
    required this.remainingQty,
    this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0,
      minWholesaleQuantity: (map['min_wholesale_quantity'] as num?)?.toInt() ?? 0,
      singlePrice: (map['single_price'] as num?)?.toDouble() ?? 0,
      hasWholesale: map['has_wholesale'] as bool? ?? false,
      remainingQty: (map['remaining_qty'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url'] as String?,
    );
  }

  final int id;
  final String name;
  final String description;
  final double price;
  final double cost;
  final double wholesalePrice;
  final int minWholesaleQuantity;
  final double singlePrice;
  final bool hasWholesale;
  final int remainingQty;
  final String? imageUrl;
}

class Order {
  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.notes,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    // محاولة الحصول على العناصر من قائمة 'items'
    List<OrderItem> items = [];
    
    try {
      final itemsList = map['items'];
      if (itemsList is List && itemsList.isNotEmpty) {
        items = itemsList
            .where((item) => item != null)
            .map((item) {
              if (item is Map<String, dynamic>) {
                return OrderItem.fromMap(item);
              }
              return null;
            })
            .whereType<OrderItem>()
            .toList();
      }

      // إذا لم يوجد عناصر، إنشاء عنصر من بيانات الصف الحالي
      if (items.isEmpty && map['name'] != null && (map['name'] as String).isNotEmpty) {
        final priceValue = map['price'];
        final quantityValue = map['quantity'];
        final item = OrderItem(
          name: map['name'] as String,
          price: (priceValue is num) ? priceValue.toDouble() : double.tryParse(priceValue.toString()) ?? 0,
          quantity: (quantityValue is num) ? quantityValue.toInt() : int.tryParse(quantityValue.toString()) ?? 0,
        );
        if (item.name.isNotEmpty) {
          items.add(item);
        }
      }
    } catch (e) {
      debugPrint('Error parsing items: $e');
    }

    // حساب المجموع من العناصر
    final calculatedTotal = items.fold<double>(0, (sum, item) => sum + item.total);

    // قراءة الحقول بشكل آمن: support num or String
    double parseDoubleField(dynamic v, double fallback) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    int parseIntField(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final mapTotal = map['total'];
    final total = parseDoubleField(mapTotal, calculatedTotal);

    final rawOrderId = map['order_id'] ?? map['id'];
    final parsedId = parseIntField(rawOrderId, 0);

    return Order(
      id: parsedId,
      items: items,
      total: total,
      status: ((map['status'] as String?) ?? 'pending').toLowerCase(),
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : (map['created_at'] is DateTime ? map['created_at'] as DateTime : DateTime.now()),
      customerName: (map['customer_name'] as String?)?.isEmpty == false ? map['customer_name'] as String? : null,
      customerPhone: (map['customer_phone'] as String?)?.isEmpty == false ? map['customer_phone'] as String? : null,
      notes: (map['notes'] as String?)?.isEmpty == false ? map['notes'] as String? : null,
    );
  }

  final int id;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
}

class OrderItem {
  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    try {
      return OrderItem(
        name: (map['name'] as String?) ?? '',
        price: ((map['price'] as num?) ?? 0).toDouble(),
        quantity: ((map['quantity'] as num?) ?? 0).toInt(),
      );
    } catch (e) {
      debugPrint('Error creating OrderItem: $e, map: $map');
      return OrderItem(name: '', price: 0, quantity: 0);
    }
  }

  final String name;
  final double price;
  final int quantity;

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price.toInt(),
        'quantity': quantity,
        'total': total.toInt(),
      };
}
