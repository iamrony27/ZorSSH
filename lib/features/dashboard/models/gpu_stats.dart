enum GpuVendor { nvidia, amd, intel, unknown }

class GpuStats {
  final bool hasGpu;
  final String model;
  final double? utilizationPct;
  final int? vramUsedMb;
  final int? vramTotalMb;
  final double? temperatureC;
  final GpuVendor vendor;

  const GpuStats({
    this.hasGpu = false,
    this.model = '',
    this.utilizationPct,
    this.vramUsedMb,
    this.vramTotalMb,
    this.temperatureC,
    this.vendor = GpuVendor.unknown,
  });

  static const none = GpuStats(hasGpu: false);

  double get vramPct {
    if (vramTotalMb == null || vramTotalMb == 0 || vramUsedMb == null) {
      return 0.0;
    }
    return ((vramUsedMb! / vramTotalMb!) * 100.0).clamp(0.0, 100.0);
  }

  /// Parses GPU telemetry from the Linux collector.
  /// Supported formats:
  /// - NVIDIA: `NVIDIA GeForce RTX 3080, 24, 2145, 10240, 58`
  /// - Tagged: `AMD|Radeon RX 7900 XTX|12|8192|24576|65`
  /// - Tagged: `NVIDIA|GeForce RTX ...|...`
  static GpuStats parse(String raw) {
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
      if (line.contains('|')) {
        final parts = line.split('|').map((s) => s.trim()).toList();
        if (parts.length < 2) return GpuStats.none;
        final vendor = _vendorFromTag(parts[0]);
        final model = parts.length > 1 ? parts[1] : '';
        if (model.isEmpty) return GpuStats.none;
        final util = parts.length > 2 ? double.tryParse(parts[2]) : null;
        final vramUsed = parts.length > 3 ? int.tryParse(parts[3]) : null;
        final vramTotal = parts.length > 4 ? int.tryParse(parts[4]) : null;
        final temp = parts.length > 5 ? double.tryParse(parts[5]) : null;
        return GpuStats(
          hasGpu: true,
          model: model,
          utilizationPct: util,
          vramUsedMb: vramUsed,
          vramTotalMb: vramTotal,
          temperatureC: temp,
          vendor: vendor,
        );
      }

      // Legacy nvidia-smi CSV: name, util, vramUsed, vramTotal, temp
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
        vendor: _inferVendor(model),
      );
    } catch (_) {
      return GpuStats.none;
    }
  }

  /// Backward-compatible alias.
  static GpuStats parseNvidiaSmi(String raw) => parse(raw);

  static GpuVendor _vendorFromTag(String tag) {
    switch (tag.toUpperCase()) {
      case 'NVIDIA':
        return GpuVendor.nvidia;
      case 'AMD':
        return GpuVendor.amd;
      case 'INTEL':
        return GpuVendor.intel;
      default:
        return _inferVendor(tag);
    }
  }

  static GpuVendor _inferVendor(String model) {
    final m = model.toLowerCase();
    if (m.contains('nvidia') || m.contains('geforce') || m.contains('rtx') || m.contains('gtx') || m.contains('quadro') || m.contains('tesla')) {
      return GpuVendor.nvidia;
    }
    if (m.contains('amd') || m.contains('radeon') || m.contains('rx ')) {
      return GpuVendor.amd;
    }
    if (m.contains('intel') || m.contains('arc') || m.contains('uhd') || m.contains('iris')) {
      return GpuVendor.intel;
    }
    return GpuVendor.unknown;
  }
}
