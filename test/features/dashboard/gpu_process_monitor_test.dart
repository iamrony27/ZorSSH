import 'package:flutter_test/flutter_test.dart';
import 'package:aetherssh/core/utils/linux_parser.dart';
import 'package:aetherssh/features/dashboard/models/gpu_stats.dart';
import 'package:aetherssh/features/dashboard/models/process_info.dart';

void main() {
  group('GpuStats Model', () {
    test('parses nvidia-smi comma-separated output', () {
      const csv = 'NVIDIA GeForce RTX 3080 Ti, 45, 4200, 12288, 62';
      final gpu = GpuStats.parseNvidiaSmi(csv);

      expect(gpu.hasGpu, isTrue);
      expect(gpu.model, 'NVIDIA GeForce RTX 3080 Ti');
      expect(gpu.utilizationPct, 45.0);
      expect(gpu.vramUsedMb, 4200);
      expect(gpu.vramTotalMb, 12288);
      expect(gpu.temperatureC, 62.0);
      expect(gpu.vramPct, closeTo(34.18, 0.1));
    });

    test('returns none for NO_GPU or empty strings', () {
      expect(GpuStats.parseNvidiaSmi('NO_GPU').hasGpu, isFalse);
      expect(GpuStats.parseNvidiaSmi('').hasGpu, isFalse);
      expect(GpuStats.parseNvidiaSmi('nvidia-smi: command not found').hasGpu, isFalse);
    });
  });

  group('ProcessItem Model', () {
    test('parses Linux ps command line', () {
      const psLine = ' 15423  dockerd  18.4  6.2 ';
      final proc = ProcessItem.parsePsLine(psLine);

      expect(proc, isNotNull);
      expect(proc!.pid, 15423);
      expect(proc.name, 'dockerd');
      expect(proc.cpuPct, 18.4);
      expect(proc.memPct, 6.2);
    });

    test('ignores invalid or header ps lines', () {
      expect(ProcessItem.parsePsLine('PID COMMAND %CPU %MEM'), isNull);
      expect(ProcessItem.parsePsLine(''), isNull);
    });
  });

  group('LinuxParser Extended Tests', () {
    test('parses 11-part payload including GPU and Top Processes', () {
      const sample11Part = '''
cpu  1000 200 300 5000 100 50 20 10
|||
total        used        free      shared  buff/cache   available
Mem:    16000000000  8000000000  4000000000   100000000  4000000000  7500000000
|||
Filesystem     1K-blocks      Used Available Use% Mounted on
/dev/sda1      100000000  40000000  60000000  40% /
|||
12345.67 45678.90
|||
linux-prod-node
|||
192.168.1.100
|||
Ubuntu 24.04 LTS
|||
6.8.0-45-generic
|||
Model name: Intel(R) Xeon(R) CPU E5-2680 v4 @ 2.40GHz
CPU(s): 14
CPU max MHz: 3300.0000
|||
NVIDIA A100-SXM4-40GB, 65, 15400, 40960, 48
|||
1024 python3 54.2 12.0
2048 node 10.1 4.5
''';

      final result = LinuxParser.parseAll(sample11Part);

      expect(result['hostname'], 'linux-prod-node');
      expect(result['osDistro'], 'Ubuntu 24.04 LTS');

      // GPU check
      final GpuStats gpu = result['gpuStats'];
      expect(gpu.hasGpu, isTrue);
      expect(gpu.model, 'NVIDIA A100-SXM4-40GB');
      expect(gpu.utilizationPct, 65.0);
      expect(gpu.temperatureC, 48.0);

      // Processes check
      final List<ProcessItem> procs = result['topProcesses'];
      expect(procs.length, 2);
      expect(procs[0].pid, 1024);
      expect(procs[0].name, 'python3');
      expect(procs[0].cpuPct, 54.2);
    });
  });
}
