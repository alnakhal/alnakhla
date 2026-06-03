import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SliderImagesSettingsPage extends StatefulWidget {
  const SliderImagesSettingsPage({super.key});

  @override
  State<SliderImagesSettingsPage> createState() => _SliderImagesSettingsPageState();
}

class _SliderImagesSettingsPageState extends State<SliderImagesSettingsPage> {
  static const String _sliderPrefKey = 'orders_page_slider_images';
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSliderImages();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSliderImages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_sliderPrefKey) ?? [];
    if (mounted) {
      setState(() {
        for (var i = 0; i < _controllers.length; i++) {
          _controllers[i].text = i < stored.length ? stored[i] : '';
        }
      });
    }
  }

  Future<void> _saveSliderImages() async {
    setState(() {
      _isSaving = true;
    });
    final urls = _controllers.map((c) => c.text.trim()).where((url) => url.isNotEmpty).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sliderPrefKey, urls);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ صور السلايدر بنجاح')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _confirmSave() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('تنبيه قبل النشر'),
              content: const Text(
                'تأكد من أن الصور واضحة ومقاسها مناسب قبل حفظ السلايدر. المقاس الموصى به: 1200×600 أو نسبة عرض إلى ارتفاع 2:1.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('حفظ وتحديث'),
                ),
              ],
            );
          },
        ) ==
        true;
    if (confirmed) {
      await _saveSliderImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل صور السلايدر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'قم بإدخال روابط الصور التي تريد عرضها في أعلى صفحة الطلبات. يمكنك تحديث الصور وتغيير ترتيبها كما تشاء.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Text('النصيحة: اختر صوراً أفقية بعرض أكبر من الارتفاع، أفضل مقاس: 1200×600.', style: TextStyle(fontSize: 14)),
                    SizedBox(height: 8),
                    Text('تنبيه قبل النشر: تأكد من جودة الصورة وأن الرابط يؤدي إلى صورة صحيحة.', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_controllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('رابط الصورة ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers[index],
                      decoration: InputDecoration(
                        labelText: 'https://...',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    if (_controllers[index].text.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _controllers[index].text.trim(),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            FilledButton(
              onPressed: _isSaving ? null : _confirmSave,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ الصور'),
            ),
          ],
        ),
      ),
    );
  }
}
