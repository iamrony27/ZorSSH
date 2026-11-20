import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:aetherssh/core/services/os_detector.dart';
import 'package:aetherssh/core/utils/app_logger.dart';

class ClipboardSyncResult {
  final bool isSuccess;
  final String message;
  final String? troubleshooting;

  const ClipboardSyncResult({
    required this.isSuccess,
    required this.message,
    this.troubleshooting,
  });

  static const emptyText = ClipboardSyncResult(
    isSuccess: false,
    message: 'Clipboard is empty. Copy some text first.',
  );
}

class ClipboardSyncService {
  /// Sends text from the Android device to the remote desktop clipboard over SSH.
  /// Zero software or agents need to be installed on the remote machine.
  static Future<ClipboardSyncResult> syncToRemote({
    required SSHClient client,
    required OsInfo osInfo,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return ClipboardSyncResult.emptyText;
    }

    final b64 = base64Encode(utf8.encode(text));

    if (osInfo.isWindows) {
      return _syncToWindows(client, b64, text.length);
    } else {
      return _syncToLinux(client, b64, text.length);
    }
  }

  /// Sends text to Windows clipboard using built-in PowerShell Set-Clipboard
  static Future<ClipboardSyncResult> _syncToWindows(
    SSHClient client,
    String base64Content,
    int characterCount,
  ) async {
    final winCmd =
        'powershell -NoProfile -Command "\$bytes = [System.Convert]::FromBase64String(\'$base64Content\'); \$text = [System.Text.Encoding]::UTF8.GetString(\$bytes); Set-Clipboard -Value \$text"';

    try {
      final session = await client.execute(winCmd);
      final stderrFuture = session.stderr.toList();
      await session.done;

      final stderrBytes = (await stderrFuture).expand((x) => x).toList();
      final stderrText = utf8.decode(stderrBytes, allowMalformed: true).trim();
      final exitCode = session.exitCode ?? 0;

      if (exitCode == 0 && stderrText.isEmpty) {
        return ClipboardSyncResult(
          isSuccess: true,
          message: 'Synced $characterCount characters to Windows clipboard!',
        );
      }

      return ClipboardSyncResult(
        isSuccess: false,
        message: 'Failed to set Windows clipboard.',
        troubleshooting: stderrText.isNotEmpty
            ? stderrText
            : 'PowerShell Set-Clipboard exited with status $exitCode',
      );
    } catch (e) {
      AppLogger.error('Windows clipboard sync failed: $e');
      return ClipboardSyncResult(
        isSuccess: false,
        message: 'Clipboard sync failed: $e',
      );
    }
  }

  /// Sends text to Linux clipboard using native wl-copy, xclip, or xsel
  static Future<ClipboardSyncResult> _syncToLinux(
    SSHClient client,
    String base64Content,
    int characterCount,
  ) async {
    // Multi-tier Linux clipboard command:
    // 1. Wayland (wl-copy)
    // 2. X11 (xclip)
    // 3. X11 (xsel)
    final linuxCmd = '''
sh -c '
B64="$base64Content"
DATA=\$(printf "%s" "\$B64" | base64 -d 2>/dev/null)

if command -v wl-copy >/dev/null 2>&1; then
  export WAYLAND_DISPLAY="\${WAYLAND_DISPLAY:-wayland-0}"
  if printf "%s" "\$DATA" | wl-copy 2>/dev/null; then
    echo "SUCCESS:wl-copy"
    exit 0
  fi
fi

if command -v xclip >/dev/null 2>&1; then
  export DISPLAY="\${DISPLAY:-:0}"
  if printf "%s" "\$DATA" | xclip -selection clipboard 2>/dev/null; then
    echo "SUCCESS:xclip"
    exit 0
  fi
fi

if command -v xsel >/dev/null 2>&1; then
  export DISPLAY="\${DISPLAY:-:0}"
  if printf "%s" "\$DATA" | xsel --clipboard --input 2>/dev/null; then
    echo "SUCCESS:xsel"
    exit 0
  fi
fi

if ! command -v wl-copy >/dev/null 2>&1 && ! command -v xclip >/dev/null 2>&1 && ! command -v xsel >/dev/null 2>&1; then
  echo "ERR_NO_TOOL"
  exit 127
else
  echo "ERR_NO_DISPLAY"
  exit 1
fi
'
''';

    try {
      final bytes = await client.run(linuxCmd).timeout(const Duration(seconds: 8));
      final output = utf8.decode(bytes, allowMalformed: true).trim();

      if (output.contains('SUCCESS:')) {
        final tool = output.split(':').last;
        return ClipboardSyncResult(
          isSuccess: true,
          message: 'Synced $characterCount characters to Linux clipboard (via $tool)!',
        );
      }

      if (output.contains('ERR_NO_TOOL')) {
        return const ClipboardSyncResult(
          isSuccess: false,
          message: 'No clipboard utility found on the remote Linux desktop.',
          troubleshooting:
              'Install a clipboard tool on your remote Linux desktop:\n\n'
              '• For Wayland: sudo apt install wl-clipboard\n'
              '• For X11: sudo apt install xclip\n'
              '• Or: sudo apt install xsel',
        );
      }

      if (output.contains('ERR_NO_DISPLAY')) {
        return const ClipboardSyncResult(
          isSuccess: false,
          message: 'Remote desktop display is not reachable.',
          troubleshooting:
              'Clipboard sharing requires an active desktop session (DISPLAY or WAYLAND_DISPLAY) on the remote computer.\n\n'
              'If this is a headless cloud server without a graphical desktop, clipboard sharing cannot synchronize to a graphical display.',
        );
      }

      return ClipboardSyncResult(
        isSuccess: false,
        message: 'Remote clipboard synchronization returned an error.',
        troubleshooting: output.isNotEmpty ? output : 'Process exited with an error.',
      );
    } catch (e) {
      AppLogger.error('Linux clipboard sync failed: $e');
      return ClipboardSyncResult(
        isSuccess: false,
        message: 'Clipboard sync failed: $e',
      );
    }
  }
}
