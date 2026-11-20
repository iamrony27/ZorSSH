import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:aetherssh/core/utils/app_logger.dart';

enum OsType { linux, windows, macos, unknown }

class OsInfo {
  final OsType type;
  final String distroName;
  final String version;
  final String kernel;
  final String shell;
  final String distroKey; // 'ubuntu', 'debian', 'mint', 'fedora', 'arch', 'windows', 'linux', 'mac'

  const OsInfo({
    required this.type,
    required this.distroName,
    this.version = '',
    this.kernel = '',
    this.shell = 'sh',
    required this.distroKey,
  });

  bool get isWindows => type == OsType.windows;
  bool get isLinux => type == OsType.linux;
  bool get isMac => type == OsType.macos;

  static const OsInfo unknown = OsInfo(
    type: OsType.unknown,
    distroName: 'Unknown',
    distroKey: 'linux',
  );

  /// Helper to classify a pre-existing osDistro string from Server model
  static OsInfo fromDistroString(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return OsInfo.unknown;

    if (lower.contains('windows')) {
      return OsInfo(
        type: OsType.windows,
        distroName: raw,
        shell: 'powershell',
        distroKey: 'windows',
      );
    }
    if (lower.contains('ubuntu')) {
      return OsInfo(
        type: OsType.linux,
        distroName: raw,
        shell: 'bash',
        distroKey: 'ubuntu',
      );
    }
    if (lower.contains('debian')) {
      return OsInfo(
        type: OsType.linux,
        distroName: raw,
        shell: 'bash',
        distroKey: 'debian',
      );
    }
    if (lower.contains('mint')) {
      return OsInfo(
        type: OsType.linux,
        distroName: raw,
        shell: 'bash',
        distroKey: 'mint',
      );
    }
    if (lower.contains('fedora')) {
      return OsInfo(
        type: OsType.linux,
        distroName: raw,
        shell: 'bash',
        distroKey: 'fedora',
      );
    }
    if (lower.contains('arch')) {
      return OsInfo(
        type: OsType.linux,
        distroName: raw,
        shell: 'bash',
        distroKey: 'arch',
      );
    }
    if (lower.contains('centos') || lower.contains('rhel') || lower.contains('red hat')) {
      return OsInfo(
        type: OsType.linux,
        distroName: raw,
        shell: 'bash',
        distroKey: 'redhat',
      );
    }
    if (lower.contains('suse')) {
      return OsInfo(
        type: OsType.linux,
        distroName: raw,
        shell: 'bash',
        distroKey: 'suse',
      );
    }
    if (lower.contains('darwin') || lower.contains('macos') || lower.contains('os x')) {
      return OsInfo(
        type: OsType.macos,
        distroName: raw,
        shell: 'zsh',
        distroKey: 'mac',
      );
    }

    return OsInfo(
      type: OsType.linux,
      distroName: raw.isNotEmpty ? raw : 'Linux',
      shell: 'sh',
      distroKey: 'linux',
    );
  }
}

class OsDetector {
  /// Probes the remote server over SSH to accurately identify operating system and shell.
  static Future<OsInfo> detect(SSHClient client) async {
    try {
      // 1. Try Linux probe first
      const linuxProbeCmd =
          'uname -s; echo "|||"; cat /etc/os-release 2>/dev/null; echo "|||"; echo "\$SHELL"; echo "|||"; uname -r';
      
      final linuxResult = await client
          .run(linuxProbeCmd)
          .timeout(const Duration(seconds: 5));
      final linuxOutput = utf8.decode(linuxResult, allowMalformed: true).trim();

      if (linuxOutput.contains('Linux') || linuxOutput.contains('Darwin')) {
        return _parseLinuxProbe(linuxOutput);
      }
    } catch (e) {
      AppLogger.debug('Linux probe failed or skipped: $e');
    }

    // 2. Try Windows probe
    try {
      const winProbeCmd =
          'powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption; echo \'|||\'; \$PSVersionTable.PSVersion.ToString(); echo \'|||\'; cmd.exe /c ver"';
      final winResult = await client
          .run(winProbeCmd)
          .timeout(const Duration(seconds: 5));
      final winOutput = utf8.decode(winResult, allowMalformed: true).trim();

      if (winOutput.toLowerCase().contains('windows') ||
          winOutput.toLowerCase().contains('microsoft')) {
        return _parseWindowsProbe(winOutput);
      }
    } catch (e) {
      AppLogger.debug('Windows PowerShell probe failed: $e');
    }

    // 3. Fallback to basic cmd.exe `ver`
    try {
      final cmdResult = await client
          .run('cmd.exe /c ver')
          .timeout(const Duration(seconds: 4));
      final cmdOutput = utf8.decode(cmdResult, allowMalformed: true).trim();
      if (cmdOutput.toLowerCase().contains('windows')) {
        return OsInfo(
          type: OsType.windows,
          distroName: cmdOutput.replaceAll('\r', '').replaceAll('\n', ' ').trim(),
          shell: 'cmd',
          distroKey: 'windows',
        );
      }
    } catch (_) {}

    return OsInfo.unknown;
  }

  static OsInfo _parseLinuxProbe(String output) {
    final parts = output.split('|||');
    final uname = parts.isNotEmpty ? parts[0].trim() : '';
    final osRelease = parts.length > 1 ? parts[1].trim() : '';
    final shell = parts.length > 2 ? parts[2].trim() : '/bin/bash';
    final kernel = parts.length > 3 ? parts[3].trim() : '';

    if (uname.contains('Darwin')) {
      return OsInfo(
        type: OsType.macos,
        distroName: 'macOS',
        kernel: kernel,
        shell: shell.isNotEmpty ? shell.split('/').last : 'zsh',
        distroKey: 'mac',
      );
    }

    String prettyName = '';
    String id = '';
    String versionId = '';

    for (final line in osRelease.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('PRETTY_NAME=')) {
        prettyName = trimmed.substring('PRETTY_NAME='.length).replaceAll('"', '').trim();
      } else if (trimmed.startsWith('ID=')) {
        id = trimmed.substring('ID='.length).replaceAll('"', '').toLowerCase().trim();
      } else if (trimmed.startsWith('VERSION_ID=')) {
        versionId = trimmed.substring('VERSION_ID='.length).replaceAll('"', '').trim();
      }
    }

    final displayName = prettyName.isNotEmpty ? prettyName : (id.isNotEmpty ? id : 'Linux');
    final distroKey = _mapDistroKey(id, displayName);

    return OsInfo(
      type: OsType.linux,
      distroName: displayName,
      version: versionId,
      kernel: kernel,
      shell: shell.isNotEmpty ? shell.split('/').last : 'bash',
      distroKey: distroKey,
    );
  }

  static OsInfo _parseWindowsProbe(String output) {
    final parts = output.split('|||');
    final caption = parts.isNotEmpty ? parts[0].trim() : 'Microsoft Windows';
    final psVer = parts.length > 1 ? parts[1].trim() : '';

    return OsInfo(
      type: OsType.windows,
      distroName: caption.isNotEmpty ? caption : 'Windows Server / PC',
      version: psVer,
      shell: 'powershell',
      distroKey: 'windows',
    );
  }

  static String _mapDistroKey(String id, String displayName) {
    final lower = '$id $displayName'.toLowerCase();
    if (lower.contains('ubuntu')) return 'ubuntu';
    if (lower.contains('debian')) return 'debian';
    if (lower.contains('mint')) return 'mint';
    if (lower.contains('fedora')) return 'fedora';
    if (lower.contains('arch')) return 'arch';
    if (lower.contains('centos') || lower.contains('rhel') || lower.contains('red hat')) return 'redhat';
    if (lower.contains('suse')) return 'suse';
    return 'linux';
  }
}
