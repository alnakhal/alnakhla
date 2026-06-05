import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabaseClient = Supabase.instance.client;

Future<String?> uploadImageToSupabase({
  required Uint8List bytes,
  required String bucket,
  required String folder,
  required String fileName,
  bool upsert = true,
}) async {
  try {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final storagePath = '$folder/$sanitizedName';
    await _supabaseClient.storage.from(bucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(upsert: upsert),
    );
    final publicUrl = _supabaseClient.storage.from(bucket).getPublicUrl(storagePath);
    if (publicUrl.isEmpty) return null;
    return publicUrl;
  } catch (error, stackTrace) {
    print('uploadImageToSupabase error: $error');
    print(stackTrace);
    return null;
  }
}

Future<String?> uploadToSupabase(Uint8List bytes, String fileName, {required String bucket, required String folder}) async {
  try {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final storagePath = '$folder/$sanitizedName';
    await _supabaseClient.storage.from(bucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    final publicUrl = _supabaseClient.storage.from(bucket).getPublicUrl(storagePath);
    if (publicUrl.isEmpty) return null;
    return publicUrl;
  } catch (error, stackTrace) {
    print('uploadToSupabase error: $error');
    print(stackTrace);
    return null;
  }
}
