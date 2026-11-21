import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageHelper {
  /// Resolves a writable Downloads directory.
  /// On Android, prefer app-specific external Downloads to avoid scoped-storage
  /// permission failures on modern Android versions.
  static Future<Directory> getDownloadsDirectoryPath() async {
    if (Platform.isAndroid) {
      final candidates = <Directory>[];

      try {
        final externalDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (externalDirs != null) {
          candidates.addAll(externalDirs);
        }
      } catch (_) {}

      try {
        final external = await getExternalStorageDirectory();
        if (external != null) {
          candidates.add(Directory('${external.path}/Download'));
        }
      } catch (_) {}

      try {
        final docs = await getApplicationDocumentsDirectory();
        candidates.add(Directory('${docs.path}/Downloads'));
      } catch (_) {}

      for (final dir in candidates) {
        try {
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          final probe = File('${dir.path}/.zorssh_write_probe');
          await probe.writeAsString('ok', flush: true);
          if (await probe.exists()) {
            await probe.delete();
          }
          return dir;
        } catch (_) {
          // Try next candidate.
        }
      }

      final fallback = await getApplicationDocumentsDirectory();
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return fallback;
    }

    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) return downloadsDir;

    return await getApplicationDocumentsDirectory();
  }

  /// Generates a non-colliding file path if the destination already exists.
  /// Example: 'test.zip' -> 'test (1).zip'
  static String getNonCollidingPath(String directoryPath, String filename) {
    final safeName = filename.isEmpty ? 'download' : filename;
    var targetFile = File('$directoryPath/$safeName');
    if (!targetFile.existsSync()) {
      return targetFile.path;
    }

    final dotIndex = safeName.lastIndexOf('.');
    final name = dotIndex > 0 ? safeName.substring(0, dotIndex) : safeName;
    final ext = dotIndex > 0 ? safeName.substring(dotIndex) : '';

    int counter = 1;
    while (targetFile.existsSync()) {
      targetFile = File('$directoryPath/$name ($counter)$ext');
      counter++;
    }
    return targetFile.path;
  }
}
