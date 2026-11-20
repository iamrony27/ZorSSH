import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:aetherssh/core/theme/app_theme.dart';
import 'package:aetherssh/core/theme/app_sizes.dart';
import 'package:aetherssh/core/widgets/glow_border.dart';
import 'package:aetherssh/features/dashboard/models/gpu_stats.dart';

class GpuMetricCard extends StatelessWidget {
  final GpuStats gpuStats;

  const GpuMetricCard({super.key, required this.gpuStats});

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
            child: gpuStats.hasGpu
                ? _buildActiveGpuView(context)
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
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
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
                'Discrete GPU metrics appear when NVIDIA SMI or DRM is active.',
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

  Widget _buildActiveGpuView(BuildContext context) {
    final util = gpuStats.utilizationPct ?? 0.0;
    final temp = gpuStats.temperatureC;
    final vramUsedGb = (gpuStats.vramUsedMb ?? 0) / 1024.0;
    final vramTotalGb = (gpuStats.vramTotalMb ?? 0) / 1024.0;
    final hasVram = (gpuStats.vramTotalMb ?? 0) > 0;

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
        // GPU Header & Temperature
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF76B900).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.circuitBoard,
                      color: Color(0xFF76B900),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      gpuStats.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (temp != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tempColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tempColor.withValues(alpha: 0.3)),
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

        // Utilization Bar
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
                color: const Color(0xFF76B900),
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
            color: const Color(0xFF76B900),
            minHeight: 6,
          ),
        ),

        // VRAM Bar (if available)
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
}
