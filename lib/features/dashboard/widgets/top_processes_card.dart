import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zorssh/core/theme/app_theme.dart';
import 'package:zorssh/core/theme/app_sizes.dart';
import 'package:zorssh/core/widgets/glow_border.dart';
import 'package:zorssh/features/dashboard/models/process_info.dart';

class TopProcessesCard extends StatelessWidget {
  final List<ProcessItem> processes;

  const TopProcessesCard({super.key, required this.processes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'RUNNING PROCESSES',
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
            padding: const EdgeInsets.all(AppSizes.p16),
            child: processes.isEmpty
                ? _buildEmptyState()
                : _buildProcessTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.listOrdered, color: Colors.white38, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'Collecting process telemetry...',
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  'PID',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'NAME',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              SizedBox(
                width: 54,
                child: Text(
                  'CPU%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 54,
                child: Text(
                  'MEM%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.06), height: 12),

        // Process rows
        ...processes.take(6).map((proc) {
          final isHighCpu = proc.cpuPct > 20.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    proc.pid.toString(),
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    proc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${proc.cpuPct.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      fontWeight: isHighCpu ? FontWeight.bold : FontWeight.normal,
                      color: isHighCpu ? AppTheme.critical : AppTheme.terminalMint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${proc.memPct.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
