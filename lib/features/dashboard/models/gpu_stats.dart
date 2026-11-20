class GpuStats {
  final bool hasGpu;
  final String model;
  final double? utilizationPct;
  final int? vramUsedMb;
  final int? vramTotalMb;
  final double? temperatureC;

  const GpuStats({
    this.hasGpu = false,
    this.model = '',
    this.utilizationPct,
    this.vramUsedMb,
    this.vramTotalMb,
    this.temperatureC,
  });

  static const none = GpuStats(hasGpu: false);

  double get vramPct {
    if (vramTotalMb == null || vramTotalMb == 0 || vramUsedMb == null) {
      return 0.0;
    }
    return ((vramUsedMb! / vramTotalMb!) * 100.0).clamp(0.0, 100.0);
  }

  /// Parses nvidia-smi CSV line:
  /// NVIDIA GeForce RTX 3080, 24, 2145, 10240, 58
  static GpuStats parseNvidiaSmi(String raw) {
    final line = raw.trim();
    final lower = line.toLowerCase();
    if (line.isEmpty ||
        line == 'NO_GPU' ||
        lower.contains('failed') ||
        lower.contains('not found') ||
        lower.contains('no such') ||
        lower.contains('cannot') ||
        lower.contains('error')) {
      return GpuStats.none;
    }

    try {
      final parts = line.split(',').map((s) => s.trim()).toList();
      if (parts.isEmpty || parts[0].isEmpty) return GpuStats.none;

      final model = parts[0];
      final util = parts.length > 1 ? double.tryParse(parts[1]) : null;
      final vramUsed = parts.length > 2 ? int.tryParse(parts[2]) : null;
      final vramTotal = parts.length > 3 ? int.tryParse(parts[3]) : null;
      final temp = parts.length > 4 ? double.tryParse(parts[4]) : null;

      return GpuStats(
        hasGpu: true,
        model: model,
        utilizationPct: util,
        vramUsedMb: vramUsed,
        vramTotalMb: vramTotal,
        temperatureC: temp,
      );
    } catch (_) {
      return GpuStats.none;
    }
  }
}
