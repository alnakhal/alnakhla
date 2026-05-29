import 'dart:typed_data';
import 'share_helper_io.dart'
    if (dart.library.html) 'share_helper_web.dart';

Future<void> shareImageBytes(Uint8List bytes, {String? filename, String? text}) =>
    shareImageBytesImpl(bytes, filename: filename, text: text);
