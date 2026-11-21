import 'package:flutter_test/flutter_test.dart';
import 'package:zorssh/core/utils/windows_parser.dart';

void main() {
  group('WindowsParser - Metrics Telemetry', () {
    test('parses Windows PowerShell JSON telemetry payload accurately', () {
      const sampleJson = '''
{
  "cpuPct": 18.5,
  "ramTotal": 17179869184,
  "ramUsed": 8589934592,
  "ramPct": 50.0,
  "diskTotal": 512000000000,
  "diskUsed": 256000000000,
  "diskPct": 50.0,
  "uptime": "5d 14h 22m",
  "hostname": "WIN-SRV-2022",
  "ipAddress": "192.168.1.150",
  "osDistro": "Microsoft Windows 11 Pro",
  "kernelVersion": "10.0.22631",
  "cpuModel": "AMD Ryzen 9 5950X 16-Core Processor",
  "cpuCores": 16,
  "gpuRaw": "NVIDIA GeForce RTX 4080, 28, 4120, 16384, 54",
  "processes": [
    {"Id": 4120, "ProcessName": "chrome", "Cpu": 12.4, "Mem": 450.2},
    {"Id": 1892, "ProcessName": "code", "Cpu": 5.1, "Mem": 320.0}
  ]
}
''';

      final stats = WindowsParser.parseMetrics(sampleJson, latencyMs: 25);

      expect(stats.cpuPct, 18.5);
      expect(stats.ramPct, 50.0);
      expect(stats.diskPct, 50.0);
      expect(stats.uptime, '5d 14h 22m');
      expect(stats.hostname, 'WIN-SRV-2022');
      expect(stats.ipAddress, '192.168.1.150');
      expect(stats.osDistro, 'Microsoft Windows 11 Pro');
      expect(stats.kernelVersion, '10.0.22631');
      expect(stats.cpuModel, 'AMD Ryzen 9 5950X 16-Core Processor');
      expect(stats.cpuCores, 16);
      expect(stats.latencyMs, 25);

      // GPU verification
      expect(stats.gpuStats.hasGpu, isTrue);
      expect(stats.gpuStats.model, 'NVIDIA GeForce RTX 4080');
      expect(stats.gpuStats.utilizationPct, 28.0);
      expect(stats.gpuStats.vramUsedMb, 4120);
      expect(stats.gpuStats.vramTotalMb, 16384);
      expect(stats.gpuStats.temperatureC, 54.0);

      // Process verification
      expect(stats.topProcesses.length, 2);
      expect(stats.topProcesses[0].pid, 4120);
      expect(stats.topProcesses[0].name, 'chrome');
      expect(stats.topProcesses[0].cpuPct, 12.4);
      expect(stats.topProcesses[0].memPct, 450.2);
    });

    test('handles Windows system with no discrete GPU', () {
      const jsonNoGpu = '''
{
  "cpuPct": 5.0,
  "ramTotal": 8589934592,
  "ramUsed": 4294967296,
  "ramPct": 50.0,
  "diskTotal": 100000000000,
  "diskUsed": 50000000000,
  "diskPct": 50.0,
  "uptime": "1d 2h 3m",
  "hostname": "OFFICE-PC",
  "ipAddress": "10.0.0.45",
  "osDistro": "Microsoft Windows 10 Home",
  "kernelVersion": "10.0.19045",
  "cpuModel": "Intel Core i5-10400",
  "cpuCores": 6,
  "gpuRaw": "NO_GPU",
  "processes": []
}
''';
      final stats = WindowsParser.parseMetrics(jsonNoGpu);
      expect(stats.gpuStats.hasGpu, isFalse);
      expect(stats.topProcesses, isEmpty);
    });

    test('recovers safely from invalid JSON', () {
      final stats = WindowsParser.parseMetrics('{corrupted json');
      expect(stats.uptime, 'Error');
      expect(stats.cpuPct, 0.0);
    });
  });
}
