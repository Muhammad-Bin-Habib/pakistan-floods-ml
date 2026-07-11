import 'dart:html' as html;

Future<String?> saveFileWeb(List<int> bytes, String filename) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    return 'Browser Downloads Directory';
  } catch (e) {
    return 'Web download failed: $e';
  }
}
