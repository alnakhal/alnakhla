import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabaseClient = Supabase.instance.client;

/// رفع صورة السلايدر وحفظها مباشرة في Supabase
Future<bool> uploadSliderImage({
  required Uint8List imageBytes,
  required String title,
}) async {
  try {
    // تحويل الصورة إلى base64
    final base64Image = base64Encode(imageBytes);
    
    // حفظ البيانات في جدول slider_images
    await _supabaseClient.from('slider_images').insert({
      'title': title,
      'image_data': base64Image,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    return true;
  } catch (e) {
    debugPrint('خطأ في رفع صورة السلايدر: $e');
    return false;
  }
}

/// رفع صورة القسم وحفظها مباشرة في Supabase
Future<bool> uploadCategoryImage({
  required Uint8List imageBytes,
  required String categoryName,
  required List<String> productKeywords,
}) async {
  try {
    // تحويل الصورة إلى base64
    final base64Image = base64Encode(imageBytes);
    
    // حفظ البيانات في جدول category_images
    await _supabaseClient.from('category_images').insert({
      'category_name': categoryName,
      'image_data': base64Image,
      'product_keywords': productKeywords.join(','),
      'created_at': DateTime.now().toIso8601String(),
    });
    
    return true;
  } catch (e) {
    debugPrint('خطأ في رفع صورة القسم: $e');
    return false;
  }
}

/// جلب جميع صور السلايدر
Future<List<Map<String, dynamic>>> fetchSliderImages() async {
  try {
    final response = await _supabaseClient
        .from('slider_images')
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
        .from('category_images')
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
        .from('slider_images')
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
        .from('category_images')
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
  // التحقق مما إذا كانت الصورة base64 أو رابط URL
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
    // base64 image
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
Future<bool> uploadImageFromPicker({
  required XFile pickedFile,
  required String title,
  required bool isSlider,
  String? categoryName,
  List<String>? productKeywords,
}) async {
  try {
    final imageBytes = await pickedFile.readAsBytes();
    
    if (isSlider) {
      return await uploadSliderImage(
        imageBytes: imageBytes,
        title: title,
      );
    } else {
      return await uploadCategoryImage(
        imageBytes: imageBytes,
        categoryName: categoryName ?? 'بدون عنوان',
        productKeywords: productKeywords ?? [],
      );
    }
  } catch (e) {
    debugPrint('خطأ في رفع الصورة من الكاميرا: $e');
    return false;
  }
}
