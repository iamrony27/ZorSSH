import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:aetherssh/core/services/os_detector.dart';
import 'package:aetherssh/core/utils/app_logger.dart';

enum ServiceStatus {
  running,
  stopped,
  failed,
  unknown,
}

enum ServiceAction {
  start,
  stop,
  restart,
}

class ManagedServiceItem {
  final String name;
  final String displayName;
  final ServiceStatus status;
  final String rawStatus;
  final String? loadState;
  final String? subState;
  final bool isWindows;

  const ManagedServiceItem({
    required this.name,
    required this.displayName,
    required this.status,
    required this.rawStatus,
    this.loadState,
    this.subState,
    required this.isWindows,
  });

  bool get isRunning => status == ServiceStatus.running;
  bool get isStopped => status == ServiceStatus.stopped;
  bool get isFailed => status == ServiceStatus.failed;
}

class ServiceActionResult {
  final bool isSuccess;
  final String message;
  final bool isPermissionDenied;

  const ServiceActionResult({
    required this.isSuccess,
    required this.message,
    this.isPermissionDenied = false,
  });
}

class ServiceManagementService {
  /// Queries the remote system and returns a structured list of services.
  static Future<List<ManagedServiceItem>> listServices({
    required SSHClient client,
    required OsInfo osInfo,
  }) async {
    if (osInfo.isWindows) {
      return _listWindowsServices(client);
    } else {
      return _listLinuxServices(client);
    }
  }

  /// Lists services on Linux via systemctl
  static Future<List<ManagedServiceItem>> _listLinuxServices(
    SSHClient client,
  ) async {
    const cmd =
        'systemctl list-units --type=service --all --no-pager --no-legend --plain 2>/dev/null';
    try {
      final bytes = await client.run(cmd).timeout(const Duration(seconds: 10));
      final output = utf8.decode(bytes, allowMalformed: true);
      return parseLinuxServices(output);
    } catch (e) {
      AppLogger.error('Failed to list Linux services: $e');
      // Fallback: try `service --status-all` if systemctl fails
      return _fallbackLinuxServices(client);
    }
  }

  /// Fallback parser for non-systemd Linux systems
  static Future<List<ManagedServiceItem>> _fallbackLinuxServices(
    SSHClient client,
  ) async {
    try {
      final bytes = await client
          .run('service --status-all 2>&1')
          .timeout(const Duration(seconds: 8));
      final output = utf8.decode(bytes, allowMalformed: true);
      final List<ManagedServiceItem> items = [];

      final lines = output.split('\n');
      final regex = RegExp(r'\[\s*([+\-?])\s*\]\s+(.*)');
      for (final line in lines) {
        final match = regex.firstMatch(line.trim());
        if (match != null) {
          final sym = match.group(1);
          final name = match.group(2)?.trim() ?? '';
          if (name.isNotEmpty) {
            final status = sym == '+'
                ? ServiceStatus.running
                : sym == '-'
                    ? ServiceStatus.stopped
                    : ServiceStatus.unknown;
            items.add(
              ManagedServiceItem(
                name: name,
                displayName: name,
                status: status,
                rawStatus: sym == '+' ? 'running' : 'stopped',
                isWindows: false,
              ),
            );
          }
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Parses systemctl list-units output
  static List<ManagedServiceItem> parseLinuxServices(String output) {
    final List<ManagedServiceItem> items = [];
    final lines = output.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('●')) continue;

      // Format: UNIT LOAD ACTIVE SUB DESCRIPTION...
      // Example: docker.service loaded active running Docker Application Container Engine
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 4) continue;

      final unit = parts[0];
      if (!unit.endsWith('.service')) continue;

      final load = parts[1];
      final active = parts[2];
      final sub = parts[3];
      final description = parts.length > 4 ? parts.sublist(4).join(' ') : unit;

      ServiceStatus status;
      if (active == 'active' && sub == 'running') {
        status = ServiceStatus.running;
      } else if (active == 'failed' || sub == 'failed') {
        status = ServiceStatus.failed;
      } else if (active == 'inactive' || sub == 'dead' || sub == 'exited') {
        status = ServiceStatus.stopped;
      } else {
        status = ServiceStatus.unknown;
      }

      items.add(
        ManagedServiceItem(
          name: unit,
          displayName: description.isNotEmpty ? description : unit,
          status: status,
          rawStatus: '$active ($sub)',
          loadState: load,
          subState: sub,
          isWindows: false,
        ),
      );
    }

    return items;
  }

  /// Lists services on Windows via PowerShell Get-Service
  static Future<List<ManagedServiceItem>> _listWindowsServices(
    SSHClient client,
  ) async {
    const cmd =
        'powershell -NoProfile -Command "Get-Service | Select-Object Name, @{Name=\'Status\';Expression={\$_.Status.ToString()}}, DisplayName | ConvertTo-Json -Compress"';
    try {
      final bytes = await client.run(cmd).timeout(const Duration(seconds: 15));
      final output = utf8.decode(bytes, allowMalformed: true).trim();
      return parseWindowsServices(output);
    } catch (e) {
      AppLogger.error('Failed to list Windows services: $e');
      return [];
    }
  }

  /// Parses Windows PowerShell Get-Service JSON output
  static List<ManagedServiceItem> parseWindowsServices(String jsonOutput) {
    final List<ManagedServiceItem> items = [];
    if (jsonOutput.isEmpty) return items;

    try {
      final decoded = jsonDecode(jsonOutput);
      final List list = decoded is List ? decoded : [decoded];

      for (final rawItem in list) {
        if (rawItem is Map) {
          final name = rawItem['Name']?.toString() ?? '';
          final displayName = rawItem['DisplayName']?.toString() ?? name;
          final statusStr = rawItem['Status']?.toString() ?? '';

          if (name.isEmpty) continue;

          ServiceStatus status;
          final lower = statusStr.toLowerCase();
          if (lower == 'running') {
            status = ServiceStatus.running;
          } else if (lower == 'stopped') {
            status = ServiceStatus.stopped;
          } else {
            status = ServiceStatus.unknown;
          }

          items.add(
            ManagedServiceItem(
              name: name,
              displayName: displayName.isNotEmpty ? displayName : name,
              status: status,
              rawStatus: statusStr,
              isWindows: true,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to parse Windows service JSON: $e');
    }

    return items;
  }

  /// Executes Start, Stop, or Restart on the given remote service
  static Future<ServiceActionResult> executeAction({
    required SSHClient client,
    required OsInfo osInfo,
    required String serviceName,
    required ServiceAction action,
    bool useSudo = false,
  }) async {
    final actionWord = action == ServiceAction.start
        ? 'start'
        : action == ServiceAction.stop
            ? 'stop'
            : 'restart';

    if (osInfo.isWindows) {
      final winVerb = action == ServiceAction.start
          ? 'Start'
          : action == ServiceAction.stop
              ? 'Stop'
              : 'Restart';
      final forceFlag = action == ServiceAction.start ? '' : '-Force';
      final winCmd =
          'powershell -NoProfile -Command "$winVerb-Service -Name \'$serviceName\' $forceFlag"';

      try {
        final session = await client.execute(winCmd);
        final stdoutFuture = session.stdout.toList();
        final stderrFuture = session.stderr.toList();
        await session.done;

        final stdoutBytes = (await stdoutFuture).expand((x) => x).toList();
        final stderrBytes = (await stderrFuture).expand((x) => x).toList();
        final stdoutText = utf8.decode(stdoutBytes, allowMalformed: true).trim();
        final stderrText = utf8.decode(stderrBytes, allowMalformed: true).trim();
        final exitCode = session.exitCode ?? 0;

        if (exitCode == 0 && stderrText.isEmpty) {
          return ServiceActionResult(
            isSuccess: true,
            message: 'Service "$serviceName" successfully ${actionWord}ed.',
          );
        }

        final combined = '$stderrText $stdoutText'.toLowerCase();
        final isPerm = combined.contains('access is denied') ||
            combined.contains('unauthorized') ||
            combined.contains('privilege');

        return ServiceActionResult(
          isSuccess: false,
          isPermissionDenied: isPerm,
          message: isPerm
              ? 'Permission denied: Administrator privileges required to $actionWord "$serviceName".'
              : (stderrText.isNotEmpty ? stderrText : 'Failed to $actionWord service (exit $exitCode)'),
        );
      } catch (e) {
        return ServiceActionResult(
          isSuccess: false,
          message: 'Execution error: $e',
        );
      }
    } else {
      // Linux
      final prefix = useSudo ? 'sudo -n ' : '';
      final cmd = '$prefix systemctl $actionWord $serviceName 2>&1';

      try {
        final bytes = await client.run(cmd).timeout(const Duration(seconds: 15));
        final output = utf8.decode(bytes, allowMalformed: true).trim();

        if (output.isEmpty) {
          return ServiceActionResult(
            isSuccess: true,
            message: 'Service "$serviceName" successfully ${actionWord}ed.',
          );
        }

        final lower = output.toLowerCase();
        final isPerm = lower.contains('interactive authentication required') ||
            lower.contains('access denied') ||
            lower.contains('polkit') ||
            lower.contains('permission denied') ||
            lower.contains('password is required');

        if (isPerm) {
          return ServiceActionResult(
            isSuccess: false,
            isPermissionDenied: true,
            message: 'Permission denied: Root or sudo privileges required to $actionWord "$serviceName".',
          );
        }

        if (lower.contains('failed') || lower.contains('error')) {
          return ServiceActionResult(
            isSuccess: false,
            message: output,
          );
        }

        return ServiceActionResult(
          isSuccess: true,
          message: output.isEmpty ? 'Service ${actionWord}ed.' : output,
        );
      } catch (e) {
        return ServiceActionResult(
          isSuccess: false,
          message: 'Error executing service action: $e',
        );
      }
    }
  }
}
