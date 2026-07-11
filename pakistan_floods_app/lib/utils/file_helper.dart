import 'dart:io';
import 'package:flutter/foundation.dart';
import 'file_helper_stub.dart' if (dart.library.html) 'file_helper_web.dart';

class FileHelper {
  /// Writes [bytes] to the local Downloads folder.
  /// If running on Web, triggers an actual html-driven browser download.
  /// Returns the path string where it was written. Returns null on failure.
  static Future<String?> saveFile(List<int> bytes, String filename) async {
    if (kIsWeb) {
      return await saveFileWeb(bytes, filename);
    }
    
    try {
      final homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final downloadsPath = '$homeDir/Downloads';
      final dir = Directory(downloadsPath);
      
      String finalPath = '$downloadsPath/$filename';
      if (!await dir.exists()) {
        // Fallback to relative project path
        finalPath = filename;
      }
      
      final file = File(finalPath);
      await file.writeAsBytes(bytes);
      return file.absolute.path;
    } catch (e) {
      try {
        // Direct local write fallback
        final file = File(filename);
        await file.writeAsBytes(bytes);
        return file.absolute.path;
      } catch (_) {
        return null;
      }
    }
  }
}
