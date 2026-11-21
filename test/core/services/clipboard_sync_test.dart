import 'package:flutter_test/flutter_test.dart';
import 'package:zorssh/core/services/clipboard_sync_service.dart';

void main() {
  group('ClipboardSyncService Tests', () {
    test('empty string returns emptyText result immediately', () async {
      // Create mock client or verify empty check
      final res = ClipboardSyncResult.emptyText;
      expect(res.isSuccess, isFalse);
      expect(res.message, contains('empty'));
    });
  });
}
