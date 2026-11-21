import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:aetherssh/core/theme/app_theme.dart';
import 'package:aetherssh/core/theme/app_sizes.dart';
import 'package:aetherssh/core/widgets/glow_border.dart';
import 'package:aetherssh/features/dashboard/models/gpu_stats.dart';
import 'package:aetherssh/features/dashboard/models/server_stats.dart';
import 'package:aetherssh/features/dashboard/widgets/cpu_line_chart.dart';

class GpuMetricCard extends StatelessWidget {
  final List<GpuStats> gpus;
  final List<ServerStats> history;

  GpuMetricCard({
    super.key,
    List<GpuStats>? gpus,
    GpuStats? gpuStats,
    this.history = const [],
  }) : gpus = gpus ?? (gpuStats != null && gpuStats.hasGpu ? [gpuStats] : (gpuStats != null ? [gpuStats] : const []));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'GPU TELEMETRY',
            style: AppTheme.sectionHeaderStyle.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.8),
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        GlowBorder(
          borderRadius: AppSizes.radiusMedium,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.p20),
            child: gpus.isNotEmpty
                ? _buildGpuList(context)
                : _buildNoGpuView(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNoGpuView(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.circuitBoard,
            color: Colors.white38,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No Dedicated GPU Detected',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'GPU metrics appear when NVIDIA SMI or AMD DRM telemetry is available.',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGpuList(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < gpus.length; i++) ...[
          _buildActiveGpuView(context, gpus[i], i),
          if (i != gpus.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            ),
        ],
      ],
    );
  }

  Widget _buildActiveGpuView(BuildContext context, GpuStats gpuStats, int index) {
    final util = (gpuStats.utilizationPct ?? 0.0).clamp(0.0, 100.0);
    final temp = gpuStats.temperatureC;
    final vramUsedGb = (gpuStats.vramUsedMb ?? 0) / 1024.0;
    final vramTotalGb = (gpuStats.vramTotalMb ?? 0) / 1024.0;
    final hasVram = (gpuStats.vramTotalMb ?? 0) > 0;
    final accent = _vendorAccent(gpuStats.vendor);

    Color tempColor = AppTheme.terminalMint;
    if (temp != null) {
      if (temp > 80) {
        tempColor = Colors.redAccent;
      } else if (temp > 70) {
        tempColor = Colors.amber;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  _VendorBadge(vendor: gpuStats.vendor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gpuStats.model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _vendorName(gpuStats.vendor),
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (temp != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tempColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.thermometer, size: 12, color: tempColor),
                    const SizedBox(width: 4),
                    Text(
                      '${temp.toStringAsFixed(0)}°C',
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tempColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GPU Load',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              '${util.toStringAsFixed(1)}%',
              style: GoogleFonts.firaCode(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (util / 100.0).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            color: accent,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: CpuLineChart(
            history: history,
            primaryColor: accent,
            isDynamicScale: false,
            getValue: (s) {
              final list = s.gpus.isNotEmpty ? s.gpus : [s.gpuStats];
              final g = index < list.length ? list[index] : list.last;
              return (g.utilizationPct ?? 0.0).clamp(0.0, 100.0);
            },
            valueFormatter: (v) => '${v.toStringAsFixed(1)}%',
            emptyMessage: 'Collecting GPU telemetry…',
          ),
        ),
        if (hasVram) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VRAM Usage',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                '${vramUsedGb.toStringAsFixed(1)} GB / ${vramTotalGb.toStringAsFixed(1)} GB (${gpuStats.vramPct.toStringAsFixed(0)}%)',
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (gpuStats.vramPct / 100.0).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: AppTheme.terminalMint,
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  static String _vendorName(GpuVendor vendor) {
    switch (vendor) {
      case GpuVendor.nvidia:
        return 'NVIDIA';
      case GpuVendor.amd:
        return 'AMD';
      case GpuVendor.intel:
        return 'Intel';
      case GpuVendor.unknown:
        return 'GPU';
    }
  }

  static Color _vendorAccent(GpuVendor vendor) {
    switch (vendor) {
      case GpuVendor.nvidia:
        return const Color(0xFF76B900);
      case GpuVendor.amd:
        return const Color(0xFFED1C24);
      case GpuVendor.intel:
        return const Color(0xFF0071C5);
      case GpuVendor.unknown:
        return AppTheme.terminalMint;
    }
  }
}

class _VendorBadge extends StatelessWidget {
  final GpuVendor vendor;
  const _VendorBadge({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final accent = GpuMetricCard._vendorAccent(vendor);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.5),
      ),
      alignment: Alignment.center,
      child: _VendorLogo(vendor: vendor, size: 20, color: accent),
    );
  }
}

class _VendorLogo extends StatelessWidget {
  final GpuVendor vendor;
  final double size;
  final Color color;
  const _VendorLogo({required this.vendor, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: switch (vendor) {
        GpuVendor.nvidia => _NvidiaLogoPainter(color),
        GpuVendor.amd => _AmdLogoPainter(color),
        GpuVendor.intel => _IntelLogoPainter(color),
        GpuVendor.unknown => _GenericGpuLogoPainter(color),
      },
    );
  }
}

class _NvidiaLogoPainter extends CustomPainter {
  final Color color;
  _NvidiaLogoPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = size.width * 0.12..strokeCap = StrokeCap.round;
    final eye = Paint()..color = color..style = PaintingStyle.fill;
    final w = size.width; final h = size.height;
    // stylized eye/spiral mark
    final rect = Rect.fromLTWH(w*0.15, h*0.28, w*0.55, h*0.55);
    canvas.drawArc(rect, -1.1, 4.2, false, p);
    canvas.drawCircle(Offset(w*0.72, h*0.42), w*0.08, eye);
    // "eye" surround
    final p2 = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = size.width * 0.09;
    canvas.drawArc(Rect.fromLTWH(w*0.28, h*0.38, w*0.5, h*0.35), -0.8, 2.2, false, p2);
  }
  @override
  bool shouldRepaint(covariant _NvidiaLogoPainter old) => old.color != color;
}

class _AmdLogoPainter extends CustomPainter {
  final Color color;
  _AmdLogoPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.fill;
    final w = size.width; final h = size.height;
    // AMD arrow logo simplified: corner block + arrow
    final path = Path()
      ..moveTo(w*0.1, h*0.1)
      ..lineTo(w*0.9, h*0.1)
      ..lineTo(w*0.9, h*0.9)
      ..lineTo(w*0.65, h*0.65)
      ..lineTo(w*0.65, h*0.35)
      ..lineTo(w*0.35, h*0.35)
      ..lineTo(w*0.1, h*0.1)
      ..close();
    canvas.drawPath(path, p);
    final p2 = Paint()..color = color..style = PaintingStyle.fill;
    final arrow = Path()
      ..moveTo(w*0.1, h*0.45)
      ..lineTo(w*0.45, h*0.45)
      ..lineTo(w*0.25, h*0.65)
      ..lineTo(w*0.55, h*0.65)
      ..lineTo(w*0.55, h*0.9)
      ..lineTo(w*0.1, h*0.9)
      ..close();
    canvas.drawPath(arrow, p2);
  }
  @override
  bool shouldRepaint(covariant _AmdLogoPainter old) => old.color != color;
}

class _IntelLogoPainter extends CustomPainter {
  final Color color;
  _IntelLogoPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = size.width * 0.1;
    final w = size.width; final h = size.height;
    // rounded square with "intel" swirl hint
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(w*0.08, h*0.2, w*0.84, h*0.6), Radius.circular(w*0.2));
    canvas.drawRRect(rrect, p);
    final tp = TextPainter(
      text: TextSpan(text: 'intel', style: TextStyle(color: color, fontSize: w*0.28, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w-tp.width)/2, (h-tp.height)/2));
  }
  @override
  bool shouldRepaint(covariant _IntelLogoPainter old) => old.color != color;
}

class _GenericGpuLogoPainter extends CustomPainter {
  final Color color;
  _GenericGpuLogoPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = size.width * 0.1;
    final w = size.width; final h = size.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*0.15,h*0.25,w*0.7,h*0.5), Radius.circular(w*0.08)), p);
    canvas.drawLine(Offset(w*0.35,h*0.75), Offset(w*0.35,h*0.85), p);
    canvas.drawLine(Offset(w*0.65,h*0.75), Offset(w*0.65,h*0.85), p);
  }
  @override
  bool shouldRepaint(covariant _GenericGpuLogoPainter old) => old.color != color;
}
