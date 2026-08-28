import 'dart:typed_data';
import 'save_image_io.dart'
    if (dart.library.html) 'save_image_web.dart';

Future<void> saveImageBytes(Uint8List bytes, {required String filename}) =>
    saveImageBytesImpl(bytes, filename: filename);