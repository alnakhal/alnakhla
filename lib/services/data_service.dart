import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabaseClient = Supabase.instance.client;
final DataService dataService = DataService();

class UploadResult {
  final bool success;
  final String? error;
  final String? imageUrl;

  const UploadResult({required this.success, this.error, this.imageUrl});

  bool get failed => !success;

  factory UploadResult.success([String? imageUrl]) => UploadResult(success: true, imageUrl: imageUrl);
  factory UploadResult.failure(String message) => UploadResult(success: false, error: message);
}

class DataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _getPublicUrl(String path) async {
    return _supabase.storage.from('uploads').getPublicUrl(path);
  }

  Future<UploadResult> uploadSliderImage(File imageFile, String title) async {
    return _uploadSliderImageInternal(
      imageFile: imageFile,
      title: title,
    );
  }

  Future<UploadResult> uploadSliderImageFromBytes(Uint8List imageBytes, String title) async {
    return _uploadSliderImageInternal(
      imageBytes: imageBytes,
      title: title,
    );
  }

  Future<UploadResult> _uploadSliderImageInternal({
    File? imageFile,
    Uint8List? imageBytes,
    required String title,
  }) async {
    try {
      if (imageFile == null && imageBytes == null) {
        return UploadResult.failure('No image provided for slider upload');
      }

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'slider/$fileName.jpg';
      final bytes = imageBytes ?? await imageFile!.readAsBytes();

      await _supabase.storage.from('uploads').upload(path, bytes);
      final publicUrl = await _getPublicUrl(path);

      await _supabase.from('slider_items').insert({
        'image_url': publicUrl,
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
      });

      return UploadResult.success(publicUrl);
    } catch (e, st) {
      debugPrint('خطأ في رفع صورة السلايدر: $e');
      debugPrint(st.toString());
      return UploadResult.failure(e.toString());
    }
  }

  Future<UploadResult> uploadCategoryImage(File imageFile, String categoryName, List<String> productKeywords) async {
    return _uploadCategoryImageInternal(
      imageFile: imageFile,
      categoryName: categoryName,
      productKeywords: productKeywords,
    );
  }

  Future<UploadResult> uploadCategoryImageFromBytes(Uint8List imageBytes, String categoryName, List<String> productKeywords) async {
    return _uploadCategoryImageInternal(
      imageBytes: imageBytes,
      categoryName: categoryName,
      productKeywords: productKeywords,
    );
  }

  Future<UploadResult> _uploadCategoryImageInternal({
    File? imageFile,
    Uint8List? imageBytes,
    required String categoryName,
    required List<String> productKeywords,
  }) async {
    try {
      if (imageFile == null && imageBytes == null) {
        return UploadResult.failure('No image provided for category upload');
      }

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'categories/$fileName.jpg';
      final bytes = imageBytes ?? await imageFile!.readAsBytes();

      await _supabase.storage.from('uploads').upload(path, bytes);
      final publicUrl = await _getPublicUrl(path);

      await _supabase.from('category_items').insert({
        'category_name': categoryName,
        'image_url': publicUrl,
        'product_keywords': productKeywords.join(','),
        'created_at': DateTime.now().toIso8601String(),
      });

      return UploadResult.success(publicUrl);
    } catch (e, st) {
      debugPrint('خطأ في رفع صورة القسم: $e');
      debugPrint(st.toString());
      return UploadResult.failure(e.toString());
    }
  }

  Future<UploadResult> saveSliderImageUrl(String imageUrl, String title) async {
    try {
      await _supabase.from('slider_items').insert({
        'image_url': imageUrl,
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
      });
      return UploadResult.success(imageUrl);
    } catch (e, st) {
      debugPrint('خطأ في حفظ رابط صورة السلايدر: $e');
      debugPrint(st.toString());
      return UploadResult.failure(e.toString());
    }
  }

  Future<UploadResult> saveCategoryImageUrl(String imageUrl, String categoryName, List<String> productKeywords) async {
    try {
      await _supabase.from('category_items').insert({
        'category_name': categoryName,
        'image_url': imageUrl,
        'product_keywords': productKeywords.join(','),
        'created_at': DateTime.now().toIso8601String(),
      });
      return UploadResult.success(imageUrl);
    } catch (e, st) {
      debugPrint('خطأ في حفظ رابط صورة القسم: $e');
      debugPrint(st.toString());
      return UploadResult.failure(e.toString());
    }
  }

  Future<UploadResult> uploadImageFromPicker({
    required XFile pickedFile,
    required String title,
    required bool isSlider,
    String? categoryName,
    List<String>? productKeywords,
  }) async {
    try {
      final imageFile = File(pickedFile.path);
      if (isSlider) {
        return await uploadSliderImage(imageFile, title);
      } else {
        return await uploadCategoryImage(
          imageFile,
          categoryName ?? 'بدون عنوان',
          productKeywords ?? [],
        );
      }
    } catch (e, st) {
      debugPrint('خطأ في رفع الصورة من الكاميرا: $e');
      debugPrint(st.toString());
      return UploadResult.failure(e.toString());
    }
  }
}

/// جلب جميع صور السلايدر
Future<List<Map<String, dynamic>>> fetchSliderImages() async {
  try {
    final response = await _supabaseClient
        .from('slider_items')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('خطأ في جلب صور السلايدر: $e');
    return [];
  }
}

/// جلب جميع صور الأقسام
Future<List<Map<String, dynamic>>> fetchCategoryImages() async {
  try {
    final response = await _supabaseClient
        .from('category_items')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('خطأ في جلب صور الأقسام: $e');
    return [];
  }
}

/// حذف صورة سلايدر من Supabase
Future<bool> deleteSliderImage(int id) async {
  try {
    await _supabaseClient
        .from('slider_items')
        .delete()
        .eq('id', id);
    return true;
  } catch (e) {
    debugPrint('خطأ في حذف صورة السلايدر: $e');
    return false;
  }
}

/// حذف صورة قسم من Supabase
Future<bool> deleteCategoryImage(int id) async {
  try {
    await _supabaseClient
        .from('category_items')
        .delete()
        .eq('id', id);
    return true;
  } catch (e) {
    debugPrint('خطأ في حذف صورة القسم: $e');
    return false;
  }
}

/// تحويل صورة من base64 إلى Uint8List
Uint8List decodeBase64Image(String base64String) {
  return base64Decode(base64String);
}

/// بناء صورة من رابط أو base64
Widget buildImageWidget(String imageData, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
  if (imageData.startsWith('http')) {
    return Image.network(
      imageData,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      ),
    );
  } else {
    return buildImageFromBase64(imageData, fit: fit);
  }
}

/// تحويل صورة من Uint8List إلى Image Widget
Widget buildImageFromBase64(String base64String, {BoxFit fit = BoxFit.cover}) {
  try {
    final imageBytes = decodeBase64Image(base64String);
    return Image.memory(
      imageBytes,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      ),
    );
  } catch (e) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
      ),
    );
  }
}

/// رفع صورة من ImagePicker وحفظها مباشرة
Future<UploadResult> uploadImageFromPicker({
  required XFile pickedFile,
  required String title,
  required bool isSlider,
  String? categoryName,
  List<String>? productKeywords,
}) async {
  try {
    return await dataService.uploadImageFromPicker(
      pickedFile: pickedFile,
      title: title,
      isSlider: isSlider,
      categoryName: categoryName,
      productKeywords: productKeywords,
    );
  } catch (e, st) {
    debugPrint('خطأ في رفع الصورة من الكاميرا: $e');
    debugPrint(st.toString());
    return UploadResult.failure(e.toString());
  }
}
