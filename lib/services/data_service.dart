import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  Future<UploadResult> uploadSliderImageFromBytes(Uint8List imageBytes, String title, {String? fileName}) async {
    if (kIsWeb) {
      debugPrint('Web platform detected: uploading slider image using bytes only.');
    }

    return _uploadSliderImageInternal(
      imageBytes: imageBytes,
      title: title,
      fileName: fileName,
    );
  }

  Future<UploadResult> _uploadSliderImageInternal({
    required Uint8List imageBytes,
    required String title,
    String? fileName,
  }) async {
    try {
      final sanitizedFileName = _sanitizeFileName(fileName ?? DateTime.now().millisecondsSinceEpoch.toString());
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      final path = 'slider/$uniqueFileName';

      await _supabase.storage.from('uploads').uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(upsert: true),
      );
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

  Future<UploadResult> uploadCategoryImageFromBytes(Uint8List imageBytes, String categoryName, List<String> productKeywords, {String? fileName}) async {
    if (kIsWeb) {
      debugPrint('Web platform detected: uploading category image using bytes only.');
    }

    return _uploadCategoryImageInternal(
      imageBytes: imageBytes,
      categoryName: categoryName,
      productKeywords: productKeywords,
      fileName: fileName,
    );
  }

  Future<UploadResult> _uploadCategoryImageInternal({
    required Uint8List imageBytes,
    required String categoryName,
    required List<String> productKeywords,
    String? fileName,
  }) async {
    try {
      final sanitizedFileName = _sanitizeFileName(fileName ?? DateTime.now().millisecondsSinceEpoch.toString());
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      final path = 'categories/$uniqueFileName';

      await _supabase.storage.from('uploads').uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(upsert: true),
      );
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

  Future<UploadResult> updateSliderImageFromBytes(int id, Uint8List imageBytes, String title, {String? fileName}) async {
    try {
      final sanitizedFileName = _sanitizeFileName(fileName ?? DateTime.now().millisecondsSinceEpoch.toString());
      final path = 'slider/$sanitizedFileName';

      await _supabase.storage.from('uploads').uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      final publicUrl = await _getPublicUrl(path);

      await _supabase.from('slider_items').update({
        'image_url': publicUrl,
        'title': title,
      }).eq('id', id);

      return UploadResult.success(publicUrl);
    } catch (e, st) {
      debugPrint('خطأ في تحديث صورة السلايدر: $e');
      debugPrint(st.toString());
      return UploadResult.failure(e.toString());
    }
  }

  Future<UploadResult> updateCategoryImageFromBytes(int id, Uint8List imageBytes, String categoryName, List<String> productKeywords, {String? fileName}) async {
    try {
      final sanitizedFileName = _sanitizeFileName(fileName ?? DateTime.now().millisecondsSinceEpoch.toString());
      final path = 'categories/$sanitizedFileName';

      await _supabase.storage.from('uploads').uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      final publicUrl = await _getPublicUrl(path);

      await _supabase.from('category_items').update({
        'image_url': publicUrl,
        'category_name': categoryName,
        'product_keywords': productKeywords.join(','),
      }).eq('id', id);

      return UploadResult.success(publicUrl);
    } catch (e, st) {
      debugPrint('خطأ في تحديث صورة القسم: $e');
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
      final fileName = pickedFile.name;
      final bytes = await pickedFile.readAsBytes();
      if (isSlider) {
        return await uploadSliderImageFromBytes(bytes, title, fileName: fileName);
      } else {
        return await uploadCategoryImageFromBytes(
          bytes,
          categoryName ?? 'بدون عنوان',
          productKeywords ?? [],
          fileName: fileName,
        );
      }
    } catch (e, st) {
      debugPrint('خطأ في رفع الصورة من الكاميرا: $e');
      debugPrint(st.toString());
      return UploadResult.failure(e.toString());
    }
  }

  String _sanitizeFileName(String fileName) {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    if (safeName.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
    return safeName;
  }

  Future<List<Map<String, dynamic>>> loadSliderImages() async {
    try {
      final response = await _supabase
          .from('slider_items')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطأ في جلب صور السلايدر: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadCategoryImages() async {
    try {
      final response = await _supabase
          .from('category_items')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطأ في جلب صور الأقسام: $e');
      return [];
    }
  }

  Uint8List decodeBase64Image(String base64String) {
    return base64Decode(base64String);
  }

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
      return _buildImageFromBase64(imageData, fit: fit);
    }
  }

  Widget _buildImageFromBase64(String base64String, {BoxFit fit = BoxFit.cover}) {
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
