import 'dart:typed_data';
import 'dart:html' as html;

Future<void> shareImageBytesImpl(Uint8List bytes, {String? filename, String? text}) async {
  // Fallback for web: create an object URL and open in new tab so user can save/download.
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // revoke URL later
  Future.delayed(const Duration(seconds: 5), () => html.Url.revokeObjectUrl(url));
}
