import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'utils/share_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/customer_orders_page.dart';
import 'pages/invoices_page.dart';
import 'pages/photo_viewer_page.dart';
import 'pages/slider_images_settings_page.dart';
import 'models/product.dart';
import 'services/product_service.dart';
import 'services/storage_service.dart';

const supabaseUrl = 'https://bhyqgohtwtvblmlbwcbb.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJoeXFnb2h0d3R2YmxtbGJ3Y2JiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNTkyMjMsImV4cCI6MjA5NDgzNTIyM30.qeGH6AkRgxnSKJIU3r5LEH94HAJ743-SvZ6g0wWkZxg';
const storeShareBaseUrl = 'https://alnwm162-jpg.github.io/al_mustalazimat_al_iraqiya-main';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
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
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF4B39EF),
          onPrimary: Colors.white,
          secondary: Color(0xFF00BFA6),
          onSecondary: Colors.white,
          tertiary: Color(0xFF7C4DFF),
          onTertiary: Colors.white,
          surface: Color(0xFFF4F6FF),
          onSurface: Color(0xFF1E293B),
          error: Color(0xFFB00020),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4B39EF),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4B39EF),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFEDE7FF),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF4B39EF)
                  : Colors.grey.shade600,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4B39EF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4B39EF),
            side: const BorderSide(color: Color(0x4D4B39EF)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4B39EF),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey.shade900,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF4B39EF)),
      ),
      home: const CustomerOrdersPage(),
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  final name = settings.name ?? '/';
  final uri = Uri.parse(name);
  final path = uri.path;
  final slug = uri.queryParameters['slug'];
  final userId = uri.queryParameters['user_id'];

  if (path == '/' || path.isEmpty) {
    if (slug != null || userId != null) {
      return MaterialPageRoute(
        builder: (_) => CustomerOrdersPage(storeSlug: slug, storeUserId: userId),
      );
    }
    return MaterialPageRoute(builder: (_) => const HomeScreen());
  }

  if (path == '/customer-orders' || path == '/store') {
    return MaterialPageRoute(
      builder: (_) => CustomerOrdersPage(storeSlug: slug, storeUserId: userId),
    );
  }

  if (path.startsWith('/store/')) {
    final storeSlug = path.substring('/store/'.length);
    return MaterialPageRoute(builder: (_) => CustomerOrdersPage(storeSlug: storeSlug));
  }

  if (path.startsWith('/customer-orders/')) {
    final storeSlug = path.substring('/customer-orders/'.length);
    return MaterialPageRoute(builder: (_) => CustomerOrdersPage(storeSlug: storeSlug));
  }

  return MaterialPageRoute(builder: (_) => const HomeScreen());
}

String get _initialRoute {
  final uri = Uri.base;
  final path = (uri.path == '/' || uri.path.isEmpty) ? uri.fragment : uri.path;
  if (path.isEmpty || path == '/') {
    return '/customer-orders';
  }
  return path.startsWith('/') ? path : '/$path';
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

enum SettingsAction { logout, register, login, storeSettings }

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
      case SettingsAction.storeSettings:
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreSettingsPage()));
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

    // ensure store and slug exist, create if necessary
    String? slug;
    try {
      final store = await ensureStoreForUser(user.id);
      if (store != null) slug = store.slug;
    } catch (e) {
      debugPrint('ensure store failed: $e');
    }

    // Use a clean path-style URL that points to the storefront catalog for the
    // given store slug. Fall back to a query by user_id when slug is missing.
    final displayLink = slug != null
      ? '$storeShareBaseUrl/store/$slug'
      : '$storeShareBaseUrl/store?user_id=${user.id}';

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
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
            },
            child: const Text('نسخ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StorePage()));
            },
            child: const Text('فتح صفحة المتجر'),
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
                return const [
                  PopupMenuItem(
                    value: SettingsAction.storeSettings,
                    child: Text('إعدادات المتجر'),
                  ),
                  PopupMenuItem(
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

class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  final _storePhoneController = TextEditingController();
  Uint8List? _invoiceLogoBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storePhone = prefs.getString('store_phone');
    final logoBase64 = prefs.getString('invoice_logo_base64');
    setState(() {
      _storePhoneController.text = storePhone ?? '';
      _invoiceLogoBytes = logoBase64 != null ? base64Decode(logoBase64) : null;
    });
  }

  Future<void> _pickInvoiceLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _invoiceLogoBytes = bytes);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_phone', _storePhoneController.text.trim());
    if (_invoiceLogoBytes != null) {
      await prefs.setString('invoice_logo_base64', base64Encode(_invoiceLogoBytes!));
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات المتجر')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المتجر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('إعدادات فاتورة المتجر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _storePhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'رقم المتجر'),
                    ),
                    const SizedBox(height: 16),
                    if (_invoiceLogoBytes != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_invoiceLogoBytes!, height: 120, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text('اختر شعار الفاتورة'),
                      onPressed: _pickInvoiceLogo,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('حفظ إعدادات المتجر'),
                    ),
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
        final storeLinkSlug = '$storeShareBaseUrl/store/$createdSlug';
        final storeLinkUser = '$storeShareBaseUrl/store?user_id=${response.user!.id}';
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
      // ensure store exists and has a slug (creates if necessary)
      try {
        final store = await ensureStoreForUser(user.id);
        if (store != null) {
          setState(() {
            _slug = store.slug;
            _storeUserId = store.userId;
          });
        } else {
          setState(() {
            _storeUserId = user.id;
          });
        }
      } catch (e) {
        // fallback: try to read existing record
        final res = await supabase.from('stores').select('slug,user_id').eq('user_id', user.id).maybeSingle();
        if (res != null) {
          Map<String, dynamic>? map;
          map = res;
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
      ? '$storeShareBaseUrl/store/$_slug'
      : _storeUserId != null
        ? '$storeShareBaseUrl/store?user_id=$_storeUserId'
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
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('إنشاء فاتورة'),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateInvoicePage()));
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.menu_book),
                    label: const Text('جميع الفواتير'),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllInvoicesPage()));
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('تعديل صور العرض'),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SliderImagesSettingsPage()));
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
      _hasMore = true;
      _errorMessage = null;
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final start = reset ? 0 : _products.length;
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
        if (reset) {
          _products.clear();
        }
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
        _showMessage('تعذر تحديث المنتجات، عرض البيانات المحفوظة محليًا');
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      _showMessage('تم حذف المنتج');
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
      _showMessage('تم تحديث الكمية');
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
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductPage())).then((_) {
                if (mounted) {
                  _refreshProducts();
                }
              });
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'بحث في المنتجات',
              hintText: 'اكتب اسم المنتج أو الوصف',
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
          const SizedBox(height: 14),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('عدد المنتجات: ${filteredProducts.length} من ${_products.length}'),
                  Text('الفلتر: ${_selectedFilter == ProductFilter.all ? 'الكل' : _selectedFilter == ProductFilter.lowStock ? 'مخزون منخفض' : 'جملة'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('جميع المنتجات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_isLoading && _products.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _products.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
                                      size: 64,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      _products.isEmpty
                                          ? 'لم تضف أي منتج بعد. اضغط على زر إضافة منتج لبدء البيع.'
                                          : 'لم يتم العثور على منتجات تطابق البحث أو الفلتر. جرّب تعديل الكلمات أو تغيير الفلتر.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 18),
                                    if (_products.isNotEmpty)
                                      FilledButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                        child: const Text('إبطال البحث'),
                                      ),
                                  ],
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
                                            .then((_) {
                                              if (mounted) {
                                                _refreshProducts();
                                              }
                                            });
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
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))).then((_) {
                                    if (mounted) {
                                      _refreshProducts();
                                    }
                                  });
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
      // prefer loading by the user's store id so products carry `store_id`
      final storeId = await getOrCreateStoreForUser(user.id);
      if (storeId == null) return [];
      final products = await fetchProductsByStoreId(storeId);
      return products;
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
  final _deliveryPriceController = TextEditingController(text: '0');
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
      final imageUrl = await uploadImageToSupabase(
        bytes: bytes,
        bucket: 'product-images',
        folder: 'products',
        fileName: file.name,
      );
      if (imageUrl == null) {
        throw 'فشل في الحصول على رابط الصورة بعد الرفع';
      }
      return imageUrl;
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
    text = text.replaceAll(RegExp(r'[?،?]'), '.');
    text = text.replaceAll(RegExp(r'[ -]'), '');
    const arabicDigits = '0123456789';
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
    final deliveryPrice = _parseDouble(_deliveryPriceController.text) ?? 0;
    final description = _descriptionController.text.trim();

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadImage(_pickedImage!);
    }

    final storeId = await getOrCreateStoreForUser(user.id);

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
      'delivery_price': deliveryPrice,
      'image_url': imageUrl,
      if (storeId != null) 'store_id': storeId,
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
                controller: _deliveryPriceController,
                decoration: const InputDecoration(labelText: 'سعر التوصيل (اختياري)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productQuantityController = TextEditingController(text: '1');
  final _productNoteController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _invoiceNotesController = TextEditingController();
  final List<OrderItem> _invoiceItems = [];
  Uint8List? _invoiceLogoBytes;
  String? _storePhone;
  bool _isSavingInvoice = false;
  Timer? _autosaveTimer;
  static const String _draftPrefsKey = 'invoice_draft_v1';

  @override
  void initState() {
    super.initState();
    _loadInvoiceSettings();
    _loadDraft();
    // controllers that affect draft
    _customerNameController.addListener(_onDraftChanged);
    _customerPhoneController.addListener(_onDraftChanged);
    _customerAddressController.addListener(_onDraftChanged);
    _discountController.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 1), () => _saveDraft(showSnack: false));
  }

  String _buildInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, "0")}${now.day.toString().padLeft(2, "0")}-${now.millisecondsSinceEpoch}';
  }

  Future<void> _saveDraft({bool showSnack = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'customerName': _customerNameController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim(),
        'customerAddress': _customerAddressController.text.trim(),
        'invoiceNotes': _invoiceNotesController.text.trim(),
        'discount': _discountController.text.trim(),
        'items': _invoiceItems.map((it) => {'name': it.name, 'price': it.price, 'quantity': it.quantity, 'note': it.note}).toList(),
        'invoiceLogoBase64': _invoiceLogoBytes != null ? base64Encode(_invoiceLogoBytes!) : null,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_draftPrefsKey, jsonEncode(draft));
      debugPrint('Draft saved');
      if (showSnack && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المسودة')));
    } catch (e) {
      debugPrint('save draft failed: $e');
    }
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_draftPrefsKey);
      if (s == null) return;
      final map = jsonDecode(s) as Map<String, dynamic>;
      final items = (map['items'] as List<dynamic>?) ?? [];
      setState(() {
        _customerNameController.text = map['customerName'] ?? '';
        _customerPhoneController.text = map['customerPhone'] ?? '';
        _customerAddressController.text = map['customerAddress'] ?? '';
        _invoiceNotesController.text = map['invoiceNotes'] ?? '';
        _discountController.text = map['discount']?.toString() ?? '0';
        _invoiceItems.clear();
        for (var it in items) {
          try {
            final m = it as Map<String, dynamic>;
            final price = (m['price'] is num) ? (m['price'] as num).toDouble() : double.tryParse(m['price']?.toString() ?? '') ?? 0;
            final qty = (m['quantity'] is num) ? (m['quantity'] as num).toInt() : int.tryParse(m['quantity']?.toString() ?? '') ?? 0;
            _invoiceItems.add(OrderItem(name: m['name'] ?? '', price: price, quantity: qty, note: m['note']?.toString() ?? ''));
          } catch (_) {}
        }
        final logoB64 = map['invoiceLogoBase64'] as String?;
        if (logoB64 != null) _invoiceLogoBytes = base64Decode(logoB64);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحميل المسودة')));
    } catch (e) {
      debugPrint('load draft failed: $e');
    }
  }

  Future<void> _clearDraft({bool showSnack = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftPrefsKey);
      debugPrint('Draft cleared');
      if (showSnack && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المسودة')));
    } catch (e) {
      debugPrint('clear draft failed: $e');
    }
  }

  Future<void> _loadInvoiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPhone = prefs.getString('store_phone');
    final logoBase64 = prefs.getString('invoice_logo_base64');
    setState(() {
      _storePhone = storedPhone;
      _invoiceLogoBytes = logoBase64 != null ? base64Decode(logoBase64) : null;
    });
  }

  String get _invoiceDate {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  double get _itemsTotal => _invoiceItems.fold<double>(0, (sum, item) => sum + item.total);
  double get _discount => _parseDouble(_discountController.text) ?? 0;
  double get _invoiceTotal => (_itemsTotal - _discount).clamp(0, double.infinity);

  String _normalizeNumberString(String value) {
    var text = value.trim();
    text = text.replaceAll(RegExp(r'[?،?]'), '.');
    const arabicDigits = '0123456789';
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

  void _addInvoiceItem() {
    final name = _productNameController.text.trim();
    final price = _parseDouble(_productPriceController.text) ?? 0;
    final quantity = _parseInt(_productQuantityController.text) ?? 0;

    if (name.isEmpty || price <= 0 || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة اسم المنتج والسعر والكمية بشكل صحيح')),
      );
      return;
    }

    setState(() {
      _invoiceItems.add(OrderItem(name: name, price: price, quantity: quantity, note: _productNoteController.text.trim()));
      _productNameController.clear();
      _productPriceController.clear();
      _productQuantityController.text = '1';
      _onDraftChanged();
    });
  }

  Future<void> _showEditInvoiceItemDialog(int index) async {
    final item = _invoiceItems[index];
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(0));
    final qtyController = TextEditingController(text: item.quantity.toString());
    final noteController = TextEditingController(text: item.note ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل عنصر الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم المنتج'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'السعر'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'ملاحظات البند'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newPrice = _parseDouble(priceController.text) ?? item.price;
              final newQuantity = _parseInt(qtyController.text) ?? item.quantity;
              if (newName.isEmpty || newPrice <= 0 || newQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال بيانات صحيحة')),
                );
                return;
              }
              setState(() {
                _invoiceItems[index] = OrderItem(name: newName, price: newPrice, quantity: newQuantity, note: noteController.text.trim());
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _removeInvoiceItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
      _onDraftChanged();
    });
  }

  void _clearInvoice() {
    setState(() {
      _invoiceItems.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerAddressController.clear();
      _invoiceNotesController.clear();
      _productNameController.clear();
      _productPriceController.clear();
      _productNoteController.clear();
      _productQuantityController.text = '1';
      _discountController.text = '0';
    });
    _clearDraft();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productQuantityController.dispose();
    _discountController.dispose();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveInvoice() async {
    if (_invoiceItems.isEmpty) return;

    final invoiceNumber = _buildInvoiceNumber();
    final invoice = Invoice(
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      customerAddress: _customerAddressController.text.trim(),
      storePhone: _storePhone ?? '',
      createdAt: DateTime.now(),
      items: List<OrderItem>.from(_invoiceItems),
      discount: _discount,
      notes: _invoiceNotesController.text.trim().isNotEmpty ? _invoiceNotesController.text.trim() : null,
      logoBytes: _invoiceLogoBytes,
      invoiceNumber: invoiceNumber,
    );

    setState(() => _isSavingInvoice = true);
    try {
      final user = supabase.auth.currentUser;
      final insertData = {
        'customer_name': invoice.customerName,
        'customer_phone': invoice.customerPhone,
        'customer_address': invoice.customerAddress,
        'store_phone': invoice.storePhone,
        'created_at': invoice.createdAt.toIso8601String(),
        'discount': invoice.discount,
        'total': (invoice.total - invoice.discount).clamp(0, double.infinity).toInt(),
        'items': invoice.items.map((item) => item.toJson()).toList(),
        'notes': invoice.notes,
        'invoice_number': invoiceNumber,
        if (user != null) 'user_id': user.id,
      };

      final dynamic response = await supabase.from('invoices').insert(insertData).select().maybeSingle();
      int? savedId;
      if (response is Map<String, dynamic>) {
        final idValue = response['id'];
        if (idValue is int) {
          savedId = idValue;
        } else if (idValue is String) {
          savedId = int.tryParse(idValue);
        }
      } else if (response is List && response.isNotEmpty && response[0] is Map<String, dynamic>) {
        final idValue = (response[0] as Map<String, dynamic>)['id'];
        if (idValue is int) {
          savedId = idValue;
        } else if (idValue is String) {
          savedId = int.tryParse(idValue);
        }
      }
      final savedInvoice = Invoice(
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        customerAddress: invoice.customerAddress,
        storePhone: invoice.storePhone,
        createdAt: invoice.createdAt,
        items: invoice.items,
        discount: invoice.discount,
        notes: invoice.notes,
        logoBytes: invoice.logoBytes,
        id: savedId,
        invoiceNumber: invoice.invoiceNumber,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة في سوبيس بنجاح')));
      savedInvoices.add(savedInvoice);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoice: savedInvoice)),
      );
      _clearInvoice();
      await _clearDraft(showSnack: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل حفظ الفاتورة: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _isSavingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فاتورة محاسبية جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('تفاصيل الفاتورة المحاسبية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('أكمل بيانات العميل والمتجر لإنشاء فاتورة احترافية جاهزة للمحاسبة.', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(labelText: 'اسم الزبون'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerPhoneController,
                      decoration: const InputDecoration(labelText: 'رقم الزبون'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerAddressController,
                      decoration: const InputDecoration(labelText: 'عنوان الزبون'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _invoiceNotesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات الفاتورة',
                        hintText: 'اكتب ملاحظات تظهر في الفاتورة بالحمراء',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text('تاريخ الفاتورة: $_invoiceDate', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            // بطاقة إدخال عنصر فاتورة جديد (خلايا شبيهة بإكسل)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('إضافة عنصر للفاتورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              controller: _productNameController,
                              decoration: const InputDecoration(
                                hintText: 'اسم المنتج',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey, width: 1)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey, width: 1)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.blue, width: 1.5)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          height: 36,
                          child: TextField(
                            controller: _productQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'الكمية',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey, width: 1)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey, width: 1)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.blue, width: 1.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          height: 36,
                          child: TextField(
                            controller: _productPriceController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: 'السعر',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey, width: 1)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey, width: 1)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.blue, width: 1.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _productNoteController,
                      decoration: const InputDecoration(
                        hintText: 'ملاحظات للبند',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey, width: 1)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('أضف'),
                            onPressed: _addInvoiceItem,
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_invoiceItems.isNotEmpty) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('المنتجات المضافة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _invoiceItems.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _invoiceItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: TextFormField(
                                        initialValue: item.name,
                                        decoration: InputDecoration(
                                          hintText: 'اسم المنتج ${index + 1}',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                        onChanged: (v) {
                                          setState(() {
                                            _invoiceItems[index] = OrderItem(name: v, price: item.price, quantity: item.quantity, note: item.note);
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        initialValue: item.price.toStringAsFixed(0),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                        onChanged: (v) {
                                          final p = _parseDouble(v) ?? item.price;
                                          setState(() {
                                            _invoiceItems[index] = OrderItem(name: item.name, price: p, quantity: item.quantity, note: item.note);
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue: item.quantity.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                        onChanged: (v) {
                                          final q = _parseInt(v) ?? item.quantity;
                                          setState(() {
                                            _invoiceItems[index] = OrderItem(name: item.name, price: item.price, quantity: q, note: item.note);
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(width: 60, child: Text(item.total.toStringAsFixed(0), textAlign: TextAlign.center)),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeInvoiceItem(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('حساب الفاتورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('مجموع المنتجات'),
                        Text(_itemsTotal.toStringAsFixed(0)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الخصم'),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _discountController,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey, width: 1)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_invoiceLogoBytes != null) ...[
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_invoiceLogoBytes!, height: 120, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      const Text('لا يوجد شعار فاتورة حالياً. يمكنك إضافته من الإعدادات.', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي الكلي', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_invoiceTotal.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _invoiceItems.isEmpty || _isSavingInvoice ? null : _saveInvoice,
                      child: _isSavingInvoice
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('حفظ الفاتورة'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _clearInvoice,
                      child: const Text('مسح الفاتورة'),
                    ),
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

  Future<void> _copyProductLink() async {
    String productLink;
    try {
      final storeId = widget.product.storeId;
      if (storeId != null && storeId.isNotEmpty) {
        final dynamic storeRes = await supabase.from('stores').select('slug').eq('id', storeId).maybeSingle();
        final slug = (storeRes is Map<String, dynamic>) ? storeRes['slug']?.toString() : null;
        if (slug != null && slug.isNotEmpty) {
          productLink = '$storeShareBaseUrl/store/$slug/product/${widget.product.id}';
        } else {
          productLink = '$storeShareBaseUrl/store/product/${widget.product.id}';
        }
      } else {
        productLink = '$storeShareBaseUrl/store/product/${widget.product.id}';
      }
    } catch (e) {
      productLink = '$storeShareBaseUrl/store/product/${widget.product.id}';
    }

    await Clipboard.setData(ClipboardData(text: productLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رابط المنتج')));
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
              GestureDetector(
                onTap: () {
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
                child: Hero(
                  tag: 'product-image-${product.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.network(
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
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_in, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  label: Text('رمز المنتج: ${product.id}'),
                ),
                Chip(
                  label: Text(product.remainingQty > 0 ? 'متوفر' : 'غير متوفر'),
                  backgroundColor: product.remainingQty > 0 ? Colors.green.shade100 : Colors.red.shade100,
                ),
                Chip(
                  label: Text(product.hasWholesale ? 'متاح بالجملة' : 'متاح للبيع المفرد'),
                ),
              ],
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
                        Text(product.price.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (product.cost > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          const Text('تكلفة المنتج:'),
                          Text(product.cost.toStringAsFixed(0)),
                        ],
                      ),
                    if (product.singlePrice > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          const Text('سعر المفرد:'),
                          Text(product.singlePrice.toStringAsFixed(0)),
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
                          Text(product.wholesalePrice.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    if (product.deliveryPrice != null && product.deliveryPrice! > 0) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('سعر التوصيل:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('${product.deliveryPrice!.toStringAsFixed(0)} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
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
                  if (!mounted) return;
                  if (result == true) {
                    Navigator.of(context).pop(true);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('عرض المنتج في المتجر'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StorePage()));
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('نسخ رابط المنتج'),
              onPressed: _copyProductLink,
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
  late TextEditingController _deliveryPriceController;
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
    _deliveryPriceController = TextEditingController(text: (widget.product.deliveryPrice ?? 0).toString());
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
    _deliveryPriceController.dispose();
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
      final imageUrl = await uploadImageToSupabase(
        bytes: bytes,
        bucket: 'product-images',
        folder: 'products',
        fileName: file.name,
      );
      if (imageUrl == null) {
        throw 'فشل في الحصول على رابط الصورة بعد الرفع';
      }
      return imageUrl;
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
    final deliveryPrice = _parseDouble(_deliveryPriceController.text) ?? 0;
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
      'delivery_price': deliveryPrice,
      'image_url': imageUrl,
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
                controller: _deliveryPriceController,
                decoration: const InputDecoration(labelText: 'سعر التوصيل (اختياري)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))).then((_) {
                  if (mounted) {
                    _refreshProducts();
                  }
                });
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
                              child: Hero(
                                tag: 'product-image-${product.id}',
                                child: product.imageUrl != null
                                    ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 40)))
                                    : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 40)),
                              ),
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
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))).then((_) {
                                      if (mounted) {
                                        _refreshProducts();
                                      }
                                    });
                                  },
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
      final startIdx = reset ? 0 : _orders.length;
      final endIdx = (startIdx + _pageSize).clamp(0, allOrders.length);
      final paginatedOrders = allOrders.sublist(startIdx, endIdx);

      setState(() {
        if (reset) {
          _orders.clear();
        }
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
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateOrderPage())).then((_) {
                  if (mounted) {
                    _refreshOrders();
                  }
                });
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
            if (_isLoading && _orders.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
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
                                              Text(dailySales.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
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
                                      .then((_) {
                                        if (mounted) {
                                          _refreshOrders();
                                        }
                                      });
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

  void _updateCurrentOrderItems(List<OrderItem> updatedItems) {
    final newTotal = updatedItems.fold<double>(0, (sum, item) => sum + item.total);
    setState(() {
      _currentOrder = Order(
        id: _currentOrder.id,
        items: updatedItems,
        total: newTotal,
        status: _currentOrder.status,
        createdAt: _currentOrder.createdAt,
        customerName: _currentOrder.customerName,
        customerPhone: _currentOrder.customerPhone,
        notes: _currentOrder.notes,
      );
    });
  }

  Future<void> _showEditItemDialog(int index) async {
    final item = _currentOrder.items[index];
    final priceController = TextEditingController(text: item.price.toStringAsFixed(0));
    final quantityController = TextEditingController(text: item.quantity.toString());

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'السعر'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text) ?? item.price;
              final newQuantity = int.tryParse(quantityController.text) ?? item.quantity;
              final updatedItem = OrderItem(
                name: item.name,
                price: newPrice,
                quantity: newQuantity,
              );
              final updatedItems = List<OrderItem>.from(_currentOrder.items);
              updatedItems[index] = updatedItem;
              _updateCurrentOrderItems(updatedItems);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث بيانات المنتج داخل الفاتورة')),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderItemsDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تفاصيل فاتورة الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _currentOrder.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _currentOrder.items[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text('السعر: ${item.price.toStringAsFixed(0)} • الكمية: ${item.quantity} • المجموع: ${item.total.toStringAsFixed(0)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.deepPurple),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _showEditItemDialog(index);
                              },
                            ),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await _showEditItemDialog(index);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الاجمالي الجديد: ${_currentOrder.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حفظ التغييرات محليًا في تفاصيل الطلب')),
                            );
                          },
                          child: const Text('حفظ الفاتورة'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    Text(_currentOrder.total.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تفاصيل العناصر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                FilledButton.icon(
                  onPressed: _showOrderItemsDialog,
                  icon: const Icon(Icons.list),
                  label: const Text('عرض الفاتورة'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _currentOrder.items.isEmpty
                  ? const Center(child: Text('لا توجد عناصر في هذا الطلب'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(1.2),
                              2: FlexColumnWidth(1),
                              3: FlexColumnWidth(1),
                            },
                            border: TableBorder.all(color: Colors.grey[300]!),
                            children: [
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
                              ..._currentOrder.items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return TableRow(
                                  decoration: BoxDecoration(color: index.isOdd ? Colors.grey[50] : Colors.white),
                                  children: [
                                    TableCell(
                                      verticalAlignment: TableCellVerticalAlignment.middle,
                                      child: InkWell(
                                        onTap: _showOrderItemsDialog,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(item.name, style: const TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      verticalAlignment: TableCellVerticalAlignment.middle,
                                      child: InkWell(
                                        onTap: _showOrderItemsDialog,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(item.price.toStringAsFixed(0), style: const TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      verticalAlignment: TableCellVerticalAlignment.middle,
                                      child: InkWell(
                                        onTap: _showOrderItemsDialog,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text('${item.quantity}', style: const TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      verticalAlignment: TableCellVerticalAlignment.middle,
                                      child: InkWell(
                                        onTap: _showOrderItemsDialog,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(item.total.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple)),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _showOrderItemsDialog,
                            icon: const Icon(Icons.edit_note),
                            label: const Text('تحرير الفاتورة كاملة'),
                          ),
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
          children: [
            const Icon(Icons.storefront, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text('مرحبًا بك في لوحة التحكم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('في هذا القسم يمكنك الإطلاع على حالة المتجر، إدارة المنتجات، والطلبات بسهولة.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.shopping_bag),
              label: const Text('طلبات الزبائن'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerOrdersPage()));
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('الفواتير'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoicesPage()));
              },
            ),
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
  final TextEditingController _orderDiscountController = TextEditingController(text: '0');
  final GlobalKey _orderShareKey = GlobalKey();
  bool _isSharingOrder = false;
  late final Future<List<Product>> _productsFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  double _parseAmount(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[?،?]'), '.');
    return double.tryParse(normalized) ?? 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _orderNotesController.dispose();
    _orderDiscountController.dispose();
    super.dispose();
  }

  Future<void> _shareOrderAsImage() async {
    if (_isSharingOrder) return;
    setState(() => _isSharingOrder = true);
    try {
      final currentContext = _orderShareKey.currentContext;
      if (currentContext == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ: لم يتم تحميل تفاصيل الطلب')));
        return;
      }
      final renderObject = currentContext.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ: فشل إنشاء الصورة')));
        return;
      }
      final ui.Image image = await (renderObject).toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ: فشل تحويل الصورة')));
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();
      await shareImageBytes(pngBytes, filename: 'طلب_${DateTime.now().millisecondsSinceEpoch}.png', text: 'طلب جديد - العميل: ${_customerNameController.text.trim()}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مشاركة الطلب كصورة')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في المشاركة: $e')));
    } finally {
      if (mounted) setState(() => _isSharingOrder = false);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الكمية المطلوبة من "${product.name}" ($requested) تتجاوز المتوفر (${product.remainingQty})')));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final createdAt = DateTime.now().toIso8601String();
      final discount = _parseAmount(_orderDiscountController.text).clamp(0, selectedItems.fold<double>(0, (sum, item) => sum + (item['total'] as num).toDouble()));

      final rows = selectedItems.map((item) => {
        'user_id': user.id,
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'total': item['total'],
        'discount': discount,
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
        future: _productsFuture,
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
          final discount = _parseAmount(_orderDiscountController.text).clamp(0, double.infinity);
          final netTotal = (productsTotal + _manualTotal - discount).clamp(0, double.infinity);
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
                              const SizedBox(height: 12),
                              TextField(
                                controller: _orderDiscountController,
                                decoration: const InputDecoration(labelText: 'خصم الطلب'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                RepaintBoundary(
                  key: _orderShareKey,
                  child: Card(
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
                              Text(productsTotal.toStringAsFixed(0)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('مجموع المنتجات اليدوية'),
                              Text(_manualTotal.toStringAsFixed(0)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الخصم', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(discount.toStringAsFixed(0)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الإجمالي بعد الخصم', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(netTotal.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: _isSharingOrder
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.share),
                        label: Text(_isSharingOrder ? 'جاري إنشاء الصورة...' : 'مشاركة الطلب كصورة'),
                        onPressed: _isSharingOrder ? null : _shareOrderAsImage,
                      ),
                    ),
                  ],
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

// `Product` model moved to lib/models/product.dart

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

class Invoice {
  Invoice({
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.storePhone,
    required this.createdAt,
    required this.items,
    this.notes,
    this.logoBytes,
    this.discount = 0,
    this.id,
    this.invoiceNumber,
  });

  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String storePhone;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String? notes;
  final Uint8List? logoBytes;
  final double discount;
  final int? id;
  final String? invoiceNumber;

  double get total => items.fold<double>(0, (sum, item) => sum + item.total);
}

final List<Invoice> savedInvoices = [];

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final GlobalKey<State> _invoiceKey = GlobalKey<State>();
  bool _isSharing = false;

  Future<void> _shareInvoiceAsImage() async {
    if (_isSharing) return;
    
    setState(() => _isSharing = true);
    
    try {
      final currentContext = _invoiceKey.currentContext;
      if (currentContext == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: لم يتم تحميل الفاتورة بشكل صحيح')),
        );
        return;
      }
      
      final RenderObject? renderObject = currentContext.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: لم يتم إنشاء الصورة')),
        );
        return;
      }
      
      final RenderRepaintBoundary boundary = renderObject;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: فشل في تحويل الصورة')),
        );
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await shareImageBytes(pngBytes, filename: 'فاتورة_${widget.invoice.createdAt.millisecondsSinceEpoch}.png', text: 'فاتورة محاسبية - العميل: ${widget.invoice.customerName}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مشاركة الفاتورة بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في مشاركة الفاتورة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _printInvoice() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال الفاتورة إلى الطابعة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الفاتورة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _invoiceKey,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.invoice.logoBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(widget.invoice.logoBytes!, height: 100, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('فاتورة محاسبية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('رقم المتجر: ${widget.invoice.storePhone}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('بيانات الزبون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('الاسم: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(widget.invoice.customerName)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text('الجوال: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(widget.invoice.customerPhone)),
                              ],
                            ),
                            if (widget.invoice.customerAddress.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('العنوان: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(widget.invoice.customerAddress)),
                                ],
                              ),
                            ],
                            if (widget.invoice.notes != null && widget.invoice.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text('ملاحظات الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              Text(widget.invoice.notes!, style: const TextStyle(color: Colors.red)),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text('التاريخ: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    '${widget.invoice.createdAt.day.toString().padLeft(2, '0')}/${widget.invoice.createdAt.month.toString().padLeft(2, '0')}/${widget.invoice.createdAt.year}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('المنتجات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade200),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          ...List<TableRow>.generate(
                            widget.invoice.items.length,
                            (index) {
                              final item = widget.invoice.items[index];
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text((index + 1).toString()),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name),
                                if (item.note != null && item.note!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(item.note!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ],
                            ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item.price.toStringAsFixed(0)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item.quantity.toString()),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item.total.toStringAsFixed(0)),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي قبل الخصم', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(widget.invoice.total.toStringAsFixed(0)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (widget.invoice.discount > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الخصم', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  Text('- ${widget.invoice.discount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي بعد الخصم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  (widget.invoice.total - widget.invoice.discount).clamp(0, double.infinity).toStringAsFixed(0),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: _isSharing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.share),
                    label: Text(_isSharing ? 'جاري المشاركة...' : 'مشاركة كصورة'),
                    onPressed: _isSharing ? null : _shareInvoiceAsImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('طباعة'),
                    onPressed: _printInvoice,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(backgroundColor: Colors.grey.shade600),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}

class AllInvoicesPage extends StatefulWidget {
  const AllInvoicesPage({super.key});

  @override
  State<AllInvoicesPage> createState() => _AllInvoicesPageState();
}

class _AllInvoicesPageState extends State<AllInvoicesPage> {
  late Future<List<Invoice>> _invoicesFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _invoicesFuture = _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Invoice>> _loadInvoices() async {
    try {
      final dynamic res = await supabase.from('invoices').select().order('created_at', ascending: false);
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

      final invoices = <Invoice>[];
      for (var item in list) {
        try {
          final map = item as Map<String, dynamic>;
          final itemsRaw = map['items'] as List<dynamic>? ?? [];
          final items = itemsRaw.map((it) {
            try {
              return OrderItem.fromMap(it as Map<String, dynamic>);
            } catch (_) {
              return OrderItem(name: '', price: 0, quantity: 0);
            }
          }).toList();

          final createdAt = DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now();
          final discount = (map['discount'] is num) ? (map['discount'] as num).toDouble() : double.tryParse(map['discount']?.toString() ?? '') ?? 0;

          invoices.add(Invoice(
            customerName: map['customer_name']?.toString() ?? '',
            customerPhone: map['customer_phone']?.toString() ?? '',
            customerAddress: map['customer_address']?.toString() ?? '',
            storePhone: map['store_phone']?.toString() ?? '',
            createdAt: createdAt,
            items: items,
            discount: discount,
            id: map['id'],
            invoiceNumber: map['invoice_number']?.toString(),
          ));
        } catch (e) {
          debugPrint('parse invoice failed: $e');
        }
      }

      if (invoices.isEmpty) {
        return List<Invoice>.from(savedInvoices);
      }
      return invoices;
    } catch (e) {
      debugPrint('load invoices from supabase failed: $e');
      return List<Invoice>.from(savedInvoices);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جميع الفواتير')),
      body: FutureBuilder<List<Invoice>>(
        future: _invoicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في جلب الفواتير: ${snapshot.error}'));
          }
          final invoices = snapshot.data ?? [];
          final query = _searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? invoices
              : invoices.where((inv) {
                  final invoiceNum = (inv.invoiceNumber ?? '').toLowerCase();
                  return inv.customerName.toLowerCase().contains(query) ||
                      inv.customerPhone.toLowerCase().contains(query) ||
                      invoiceNum.contains(query);
                }).toList();
          if (invoices.isEmpty) {
            return const Center(child: Text('لا توجد فواتير محفوظة بعد'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث باسم الزبون، الجوال أو رقم الفاتورة',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final invoice = filtered[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('فاتورة ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${invoice.createdAt.day.toString().padLeft(2, '0')}/${invoice.createdAt.month.toString().padLeft(2, '0')}/${invoice.createdAt.year}', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('الزبون: ${invoice.customerName} | الجوال: ${invoice.customerPhone}'),
                            const SizedBox(height: 6),
                            if (invoice.customerAddress.isNotEmpty)
                              Text('العنوان: ${invoice.customerAddress}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            if (invoice.customerAddress.isNotEmpty) const SizedBox(height: 6),
                            Text('رقم المتجر: ${invoice.storePhone}'),
                            const SizedBox(height: 12),
                            Text('عدد المنتجات: ${invoice.items.length} • إجمالي: ${invoice.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل الفاتورة',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditDialog(invoice),
                                ),
                                IconButton(
                                  tooltip: 'مشاركة / عرض',
                                  icon: const Icon(Icons.share),
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoice: invoice)));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: filtered.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(Invoice invoice) async {
    final nameCtrl = TextEditingController(text: invoice.customerName);
    final phoneCtrl = TextEditingController(text: invoice.customerPhone);
    final addrCtrl = TextEditingController(text: invoice.customerAddress);
    final discountCtrl = TextEditingController(text: invoice.discount.toStringAsFixed(0));

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الفاتورة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الزبون')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'جوال الزبون')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'عنوان الزبون')),
              TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'الخصم')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _updateInvoiceOnServer(invoice, nameCtrl.text.trim(), phoneCtrl.text.trim(), addrCtrl.text.trim(), double.tryParse(discountCtrl.text) ?? 0);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateInvoiceOnServer(Invoice invoice, String name, String phone, String address, double discount) async {
    final query = supabase.from('invoices').update({
      'customer_name': name,
      'customer_phone': phone,
      'customer_address': address,
      'discount': discount,
    });

    if (invoice.id != null) {
      final invoiceId = invoice.id!;
      query.eq('id', invoiceId);
    } else if (invoice.invoiceNumber != null) {
      final invoiceNumber = invoice.invoiceNumber!;
      query.eq('invoice_number', invoiceNumber);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن تحديث الفاتورة (معرف غير متاح)')));
      return;
    }

    try {
      await query;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الفاتورة')));
      setState(() {
        _invoicesFuture = _loadInvoices();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تحديث الفاتورة: $e')));
    }
  }
}

class OrderItem {
  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.note,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    try {
      return OrderItem(
        name: (map['name'] as String?) ?? '',
        price: ((map['price'] as num?) ?? 0).toDouble(),
        quantity: ((map['quantity'] as num?) ?? 0).toInt(),
        note: (map['note'] as String?) ?? '',
      );
    } catch (e) {
      debugPrint('Error creating OrderItem: $e, map: $map');
      return OrderItem(name: '', price: 0, quantity: 0);
    }
  }

  final String name;
  final double price;
  final int quantity;
  final String? note;

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price.toInt(),
        'quantity': quantity,
        'total': total.toInt(),
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}







