import 'dart:typed_data';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

Future<void> shareImageBytesImpl(
  Uint8List bytes, {
  String? filename,
  String? text,
}) async {
  final tmp = Directory.systemTemp;
  final safeFilename =
      filename ?? 'share_image_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${tmp.path}/$safeFilename');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      fileNameOverrides: [safeFilename],
      text: text,
      title: 'مشاركة الفاتورة',
    ),
  );
}
