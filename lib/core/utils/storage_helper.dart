import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageHelper {
  /// Resolves the primary public Downloads folder on Android or default downloads directory.
  static Future<Directory> getDownloadsDirectoryPath() async {
    if (Platform.isAndroid) {
      // Direct access to standard Android public Download directory
      final primaryDownload = Directory('/storage/emulated/0/Download');
      if (await primaryDownload.exists()) {
        return primaryDownload;
      }
      try {
        final externalDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (externalDirs != null && externalDirs.isNotEmpty) {
          return externalDirs.first;
        }
      } catch (_) {}
      try {
        final sysDownloads = await getDownloadsDirectory();
        if (sysDownloads != null) {
          return sysDownloads;
        }
      } catch (_) {}
    }

    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) return downloadsDir;

    return await getApplicationDocumentsDirectory();
  }

  /// Generates a non-colliding file path if the destination already exists.
  /// Example: 'test.zip' -> 'test (1).zip'
  static String getNonCollidingPath(String directoryPath, String filename) {
    var targetFile = File('$directoryPath/$filename');
    if (!targetFile.existsSync()) {
      return targetFile.path;
    }

    final dotIndex = filename.lastIndexOf('.');
    final name = dotIndex != -1 ? filename.substring(0, dotIndex) : filename;
    final ext = dotIndex != -1 ? filename.substring(dotIndex) : '';

    int counter = 1;
    while (targetFile.existsSync()) {
      targetFile = File('$directoryPath/$name ($counter)$ext');
      counter++;
    }
    return targetFile.path;
  }
}
