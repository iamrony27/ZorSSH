import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zorssh/core/utils/storage_helper.dart';
import 'package:zorssh/features/files/data/download_task.dart';

void main() {
  group('DownloadTask Tests', () {
    test('calculates progress accurately', () {
      final task = DownloadTask(
        id: '1',
        remotePath: '/var/log/syslog',
        fileName: 'syslog',
        totalBytes: 1000,
        downloadedBytes: 450,
      );
      expect(task.progress, closeTo(0.45, 0.001));
    });

    test('handles zero totalBytes without crashing', () {
      final task = DownloadTask(
        id: '2',
        remotePath: '/empty',
        fileName: 'empty',
        totalBytes: 0,
        downloadedBytes: 0,
      );
      expect(task.progress, 0.0);
    });

    test('formats speed into human readable units', () {
      final taskB = DownloadTask(
        id: '3',
        remotePath: '/f1',
        fileName: 'f1',
        totalBytes: 100,
        speedBytesPerSecond: 512,
      );
      expect(taskB.formattedSpeed, '512 B/s');

      final taskKB = DownloadTask(
        id: '4',
        remotePath: '/f2',
        fileName: 'f2',
        totalBytes: 100000,
        speedBytesPerSecond: 204800, // 200 KB/s
      );
      expect(taskKB.formattedSpeed, '200.0 KB/s');

      final taskMB = DownloadTask(
        id: '5',
        remotePath: '/f3',
        fileName: 'f3',
        totalBytes: 100000000,
        speedBytesPerSecond: 5242880, // 5 MB/s
      );
      expect(taskMB.formattedSpeed, '5.00 MB/s');
    });
  });

  group('StorageHelper Tests', () {
    test('getNonCollidingPath returns original path when file does not exist', () {
      final tempDir = Directory.systemTemp.createTempSync('storage_test_');
      try {
        final path = StorageHelper.getNonCollidingPath(tempDir.path, 'unique.txt');
        expect(path, '${tempDir.path}/unique.txt');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getNonCollidingPath appends counter when file already exists', () {
      final tempDir = Directory.systemTemp.createTempSync('storage_test_');
      try {
        final f1 = File('${tempDir.path}/report.pdf');
        f1.writeAsStringSync('existing file');

        final nextPath = StorageHelper.getNonCollidingPath(tempDir.path, 'report.pdf');
        expect(nextPath, '${tempDir.path}/report (1).pdf');

        final f2 = File(nextPath);
        f2.writeAsStringSync('existing file 2');

        final thirdPath = StorageHelper.getNonCollidingPath(tempDir.path, 'report.pdf');
        expect(thirdPath, '${tempDir.path}/report (2).pdf');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
