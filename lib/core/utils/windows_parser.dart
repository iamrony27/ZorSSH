import 'dart:convert';
import 'package:aetherssh/features/dashboard/models/gpu_stats.dart';
import 'package:aetherssh/features/dashboard/models/process_info.dart';
import 'package:aetherssh/features/dashboard/models/server_stats.dart';

class WindowsParser {
  static const String windowsMetricsCommand =
      'powershell -NoProfile -Command "\$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average; \$os = Get-CimInstance Win32_OperatingSystem; \$ramTotal = [int64]\$os.TotalVisibleMemorySize * 1024; \$ramFree = [int64]\$os.FreePhysicalMemory * 1024; \$ramUsed = \$ramTotal - \$ramFree; \$disk = Get-CimInstance Win32_LogicalDisk -Filter \\"DeviceID=\'C:\'\\"; \$diskTotal = [int64]\$disk.Size; \$diskUsed = [int64](\$disk.Size - \$disk.FreeSpace); \$uptime = (Get-Date) - \$os.LastBootUpTime; \$uptimeStr = \\"\$(\$uptime.Days)d \$(\$uptime.Hours)h \$(\$uptime.Minutes)m\\"; \$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias \'Ethernet*\',\'Wi-Fi*\' -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress; \$procs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 6 Id, ProcessName, @{Name=\'Cpu\';Expression={[math]::Round(\$_.CPU, 1)}}, @{Name=\'Mem\';Expression={[math]::Round(\$_.WorkingSet64 / 1MB, 1)}}; \$gpu = (nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>\$null); if (-not \$gpu) { \$gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1 -ExpandProperty Name) }; @{ cpuPct = [double]\$cpu; ramTotal = \$ramTotal; ramUsed = \$ramUsed; ramPct = if (\$ramTotal -gt 0) { [math]::Round((\$ramUsed / \$ramTotal) * 100, 1) } else { 0.0 }; diskTotal = \$diskTotal; diskUsed = \$diskUsed; diskPct = if (\$diskTotal -gt 0) { [math]::Round((\$diskUsed / \$diskTotal) * 100, 1) } else { 0.0 }; uptime = \$uptimeStr; hostname = \$env:COMPUTERNAME; ipAddress = if (\$ip) { \$ip } else { \'\' }; osDistro = \$os.Caption; kernelVersion = \$os.Version; cpuModel = (Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name); cpuCores = [int](Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty NumberOfCores); gpuRaw = if (\$gpu) { [string]\$gpu } else { \'NO_GPU\' }; processes = \$procs; } | ConvertTo-Json -Compress -Depth 3"';

  /// Parses JSON output from the Windows PowerShell telemetry command
  static ServerStats parseMetrics(String jsonStr, {int latencyMs = 0}) {
    try {
      final decoded = jsonDecode(jsonStr.trim());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object for Windows metrics');
      }

      final cpuPct = (decoded['cpuPct'] as num?)?.toDouble() ?? 0.0;
      final ramPct = (decoded['ramPct'] as num?)?.toDouble() ?? 0.0;
      final ramUsed = (decoded['ramUsed'] as num?)?.toInt() ?? 0;
      final ramTotal = (decoded['ramTotal'] as num?)?.toInt() ?? 0;
      final diskPct = (decoded['diskPct'] as num?)?.toDouble() ?? 0.0;
      final diskUsed = (decoded['diskUsed'] as num?)?.toInt() ?? 0;
      final diskTotal = (decoded['diskTotal'] as num?)?.toInt() ?? 0;
      final uptime = decoded['uptime']?.toString() ?? 'N/A';
      final hostname = decoded['hostname']?.toString() ?? '';
      final ipAddress = decoded['ipAddress']?.toString() ?? '';
      final osDistro = decoded['osDistro']?.toString() ?? 'Windows';
      final kernelVersion = decoded['kernelVersion']?.toString() ?? '';
      final cpuModel = decoded['cpuModel']?.toString() ?? '';
      final cpuCores = (decoded['cpuCores'] as num?)?.toInt() ?? 0;

      // GPU Parsing
      final gpuRaw = decoded['gpuRaw']?.toString() ?? 'NO_GPU';
      final gpuStats = GpuStats.parseNvidiaSmi(gpuRaw);

      // Top Processes Parsing
      final List<ProcessItem> processes = [];
      final rawProcs = decoded['processes'];
      if (rawProcs is List) {
        for (final item in rawProcs) {
          if (item is Map) {
            final p = ProcessItem.fromWindowsMap(Map<String, dynamic>.from(item));
            if (p != null) processes.add(p);
          }
        }
      }

      return ServerStats(
        cpuPct: cpuPct,
        ramPct: ramPct,
        ramUsed: ramUsed,
        ramTotal: ramTotal,
        diskPct: diskPct,
        diskUsed: diskUsed,
        diskTotal: diskTotal,
        uptime: uptime,
        latencyMs: latencyMs,
        timestamp: DateTime.now(),
        hostname: hostname,
        ipAddress: ipAddress,
        osDistro: osDistro,
        kernelVersion: kernelVersion,
        cpuModel: cpuModel,
        cpuCores: cpuCores,
        gpuStats: gpuStats,
        topProcesses: processes,
      );
    } catch (e) {
      return ServerStats(
        cpuPct: 0.0,
        ramPct: 0.0,
        diskPct: 0.0,
        uptime: 'Error',
        latencyMs: latencyMs,
        timestamp: DateTime.now(),
      );
    }
  }
}
