import 'dart:typed_data';

import 'package:saver_gallery/saver_gallery.dart';

Future<void> saveImageBytesImpl(
  Uint8List bytes, {
  required String filename,
}) async {
  final result = await SaverGallery.saveImage(
    bytes,
    fileName: filename,
    albumPath: 'مستلزمات النخلة',
    skipIfExists: false,
  );
  if (!result.isSuccess) {
    throw StateError(result.errorMessage ?? 'تعذر حفظ الصورة في المعرض');
  }
}