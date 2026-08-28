import 'dart:typed_data';
import 'dart:html' as html;

Future<void> shareImageBytesImpl(
  Uint8List bytes, {
  String? filename,
  String? text,
}) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final safeFilename = filename ?? 'invoice.png';

  final anchor = html.AnchorElement(href: url)
    ..download = safeFilename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(
    const Duration(seconds: 1),
    () => html.Url.revokeObjectUrl(url),
  );
}
