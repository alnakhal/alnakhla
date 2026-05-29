import 'dart:typed_data';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

Future<void> shareImageBytesImpl(Uint8List bytes, {String? filename, String? text}) async {
  final tmp = Directory.systemTemp;
  final file = File('${tmp.path}/${filename ?? 'share_image_${DateTime.now().millisecondsSinceEpoch}.png'}');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: text ?? '');
}
