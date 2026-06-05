import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/data_service.dart';

class _CategorySection {
  final String name;
  final String imageUrl;
  final List<String> products;

  const _CategorySection({
    required this.name,
    required this.imageUrl,
    required this.products,
  });
}

class SliderImagesSettingsPage extends StatefulWidget {
  const SliderImagesSettingsPage({super.key});

  @override
  State<SliderImagesSettingsPage> createState() => _SliderImagesSettingsPageState();
}

class _SliderImagesSettingsPageState extends State<SliderImagesSettingsPage> {
  final DataService _dataService = DataService();
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<bool> _isUploading = List.generate(5, (_) => false);
  bool _isSaving = false;
  List<Map<String, dynamic>> _sliderImages = [];

  final List<_CategorySection> _categorySections = const [
    _CategorySection(
      name: 'قسم العناية',
      imageUrl: 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=400&q=80',
      products: ['زيت عطري', 'كريم ترطيب', 'مجموعة عناية'],
    ),
    _CategorySection(
      name: 'قسم التجميل',
      imageUrl: 'https://images.unsplash.com/photo-1491553895911-0055eca6402d?auto=format&fit=crop&w=400&q=80',
      products: ['ماسك طبيعي', 'صبغة شعر', 'مستحضرات تجميل'],
    ),
    _CategorySection(
      name: 'قسم الصحة',
      imageUrl: 'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=400&q=80',
      products: ['مكملات غذائية', 'فيتامينات', 'زيوت طبيعية'],
    ),
    _CategorySection(
      name: 'قسم الهدايا',
      imageUrl: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=400&q=80',
      products: ['سلة هدايا', 'عبوة عطور', 'مجموعة ضيافة'],
    ),
  ];

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
    try {
      final images = await _dataService.loadSliderImages();
      if (mounted) {
        setState(() {
          _sliderImages = images;
          // تحميل أول 5 صور إلى المحررات
          for (var i = 0; i < _controllers.length && i < images.length; i++) {
            _controllers[i].text = images[i]['image_url'] ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الصور: $e');
    }
  }

  Future<void> _saveSliderImages() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      // حفظ جميع الصور المعبأة
      for (var i = 0; i < _controllers.length; i++) {
        final imageUrl = _controllers[i].text.trim();
        if (imageUrl.isNotEmpty && i >= _sliderImages.length) {
          if (imageUrl.startsWith('http')) {
            final result = await _dataService.saveSliderImageUrl(
              imageUrl,
              'صورة السلايدر ${i + 1}',
            );
            if (result.failed) {
              throw Exception(result.error ?? 'فشل حفظ رابط صورة السلايدر');
            }
          } else {
            final imageBytes = _dataService.decodeBase64Image(imageUrl);
            final result = await _dataService.uploadSliderImageFromBytes(
              imageBytes,
              'صورة السلايدر ${i + 1}',
            );
            if (result.failed) {
              throw Exception(result.error ?? 'فشل حفظ صورة السلايدر');
            }
          }
        }
      }
      
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ صور السلايدر بنجاح في Supabase')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('خطأ في حفظ الصور: $e');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
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

  int get _firstEmptyImageSlot {
    return _controllers.indexWhere((controller) => controller.text.trim().isEmpty);
  }

  Future<void> _pickAndUploadImage(int index) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result == null) return;

    setState(() {
      _isUploading[index] = true;
    });

    try {
      final imageBytes = await result.readAsBytes();
      final uploadResult = await _dataService.uploadSliderImageFromBytes(
        imageBytes,
        'صورة السلايدر ${index + 1}',
      );

      if (uploadResult.failed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: ${uploadResult.error ?? 'حدث خطأ'}')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _controllers[index].text = uploadResult.imageUrl ?? _controllers[index].text;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع الصورة بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('خطأ في رفع صورة السلايدر: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء رفع الصورة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading[index] = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadNewImage() async {
    final index = _firstEmptyImageSlot >= 0 ? _firstEmptyImageSlot : 0;
    await _pickAndUploadImage(index);
  }

  void _showCategoryProducts(_CategorySection section) {
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
                  Text(section.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (section.products.isEmpty)
                const Text('لا توجد منتجات محددة لهذا القسم بعد.', style: TextStyle(fontSize: 16))
              else
                ...section.products.map((product) => ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: Text(product),
                    )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openEditCategoriesSheet() {
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تعديل الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _categorySections.map((section) {
                    final itemWidth = (MediaQuery.of(context).size.width - 64) / 2;
                    return SizedBox(
                      width: itemWidth,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          _showCategoryProducts(section);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            ClipOval(
                              child: Image.network(
                                section.imageUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error_outline, color: Colors.redAccent),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              section.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderPreview() {
    final imageData = _controllers
        .map((controller) => controller.text.trim())
        .where((data) => data.isNotEmpty)
        .toList();
    
    if (imageData.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'لم يتم إضافة صور السلايدر بعد',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: imageData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _dataService.buildImageWidget(
                imageData[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _categorySections.map((section) {
            final itemWidth = (MediaQuery.of(context).size.width - 64) / 2;
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () => _showCategoryProducts(section),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.network(
                        section.imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.error_outline, color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      section.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
              'اختر صوراً حقيقية من الجوال لعرضها في صفحة الطلبات. سيتم رفع الصورة مباشرة إلى Supabase وتخزين الرابط. يمكنك تعديل الترتيب وحفظ التغييرات.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _pickAndUploadNewImage,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('رفع صورة من الجوال'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openEditCategoriesSheet,
              icon: const Icon(Icons.grid_view),
              label: const Text('تعديل الأقسام'),
            ),
            const SizedBox(height: 16),
            _buildSliderPreview(),
            const SizedBox(height: 16),
            _buildCategorySection(),
            const SizedBox(height: 16),
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
                        suffixIcon: _isUploading[index]
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.cloud_upload_outlined),
                                tooltip: 'رفع صورة من الجوال لهذا الحقل',
                                onPressed: () => _pickAndUploadImage(index),
                              ),
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
                          child: _dataService.buildImageWidget(
                            _controllers[index].text.trim(),
                            fit: BoxFit.cover,
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
