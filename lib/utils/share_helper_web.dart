import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<void> shareImageBytesImpl(
  Uint8List bytes, {
  String? filename,
  String? text,
}) async {
  final safeFilename = filename ?? 'invoice.png';
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: safeFilename,
        ),
      ],
      fileNameOverrides: [safeFilename],
      text: text,
      title: 'مشاركة الفاتورة',
      downloadFallbackEnabled: true,
    ),
  );
}
