class ProcessItem {
  final int pid;
  final String name;
  final double cpuPct;
  final double memPct;

  const ProcessItem({
    required this.pid,
    required this.name,
    required this.cpuPct,
    required this.memPct,
  });

  /// Parses Linux ps line: "1234 python3 12.5 3.4"
  static ProcessItem? parsePsLine(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) return null;

    final pid = int.tryParse(parts[0]);
    if (pid == null) return null;

    final name = parts[1];
    final cpu = double.tryParse(parts[2]) ?? 0.0;
    final mem = double.tryParse(parts[3]) ?? 0.0;

    return ProcessItem(
      pid: pid,
      name: name,
      cpuPct: cpu,
      memPct: mem,
    );
  }

  /// Parses JSON item from Windows PowerShell Get-Process
  static ProcessItem? fromWindowsMap(Map<String, dynamic> map) {
    try {
      final pid = int.tryParse(map['Id']?.toString() ?? '') ?? 0;
      final name = map['ProcessName']?.toString() ?? 'unknown';
      final cpu = double.tryParse(map['Cpu']?.toString() ?? '0') ?? 0.0;
      final mem = double.tryParse(map['Mem']?.toString() ?? '0') ?? 0.0;

      return ProcessItem(
        pid: pid,
        name: name,
        cpuPct: cpu,
        memPct: mem,
      );
    } catch (_) {
      return null;
    }
  }
}
