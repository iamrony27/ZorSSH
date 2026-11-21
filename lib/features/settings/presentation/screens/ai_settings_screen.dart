import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zorssh/core/theme/app_sizes.dart';
import 'package:zorssh/core/theme/app_theme.dart';
import 'package:zorssh/core/widgets/pulsing_status_dot.dart';
import 'package:zorssh/core/widgets/system_card.dart';
import 'package:zorssh/features/terminal/services/ai_service.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  Future<void> _testAiEngine() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final result = await AiService.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = result.isSuccess;
        _testResult = result.isSuccess
            ? 'Zor Neural Engine is responsive and ready for instant terminal synthesis.'
            : 'Engine check failed: ${result.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Zor AI Assistant',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AI Engine Banner Card ──────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'NEURAL CLOUD ENGINE',
                style: AppTheme.sectionTitleStyle,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Zor Neural Engine',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const PulsingStatusDot(
                                  isOnline: true,
                                  size: 10,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Active • Built-in Zero-Config Intelligence',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF00E676),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Built-in AI provides instant natural language commands, server diagnostics, and script explanations directly inside your terminal with zero configuration required.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.shieldCheck,
                              size: 13,
                              color: Color(0xFF00E676),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Zero-Key Config',
                              style: GoogleFonts.firaCode(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.zap,
                              size: 13,
                              color: Color(0xFF00B0FF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ultra Low Latency',
                              style: GoogleFonts.firaCode(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00E676),
                        side: BorderSide(
                          color: const Color(0xFF00E676).withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isTesting ? null : _testAiEngine,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00E676),
                              ),
                            )
                          : const Icon(LucideIcons.radio, size: 15),
                      label: Text(
                        _isTesting
                            ? 'Testing Neural Connection...'
                            : 'Test AI Engine Connection',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 14),
              _buildTestResultBadge(),
            ],

            const SizedBox(height: 28),

            // ── Capabilities & Guardrails ────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'FEATURES & SAFETY GUARDRAILS',
                style: AppTheme.sectionTitleStyle,
              ),
            ),
            SystemCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFeatureRow(
                    icon: LucideIcons.terminal,
                    color: const Color(0xFF00E676),
                    title: 'One-Tap Command Generation',
                    description:
                        'Speak or type requests like "Check RAM usage" or "Find large files over 100MB" to produce instant executable commands.',
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildFeatureRow(
                    icon: LucideIcons.cpu,
                    color: const Color(0xFF00B0FF),
                    title: 'Adaptive OS Compliance',
                    description:
                        'Automatically identifies whether target host runs Linux or Windows and formats syntax (Bash vs PowerShell) accurately.',
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildFeatureRow(
                    icon: LucideIcons.shieldAlert,
                    color: const Color(0xFFFFB74D),
                    title: 'Destructive Command Guard',
                    description:
                        'Warns and prompts for explicit confirmation before generating or executing critical system reboot or deletion operations.',
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildFeatureRow(
                    icon: LucideIcons.lock,
                    color: const Color(0xFFE040FB),
                    title: 'Hardware Keystore Security',
                    description:
                        'All communication is secured end-to-end via TLS 1.3 with hardware-backed Keystore isolation.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestResultBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _testSuccess == true
            ? const Color(0xFF00E676).withValues(alpha: 0.1)
            : AppTheme.critical.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _testSuccess == true
              ? const Color(0xFF00E676).withValues(alpha: 0.3)
              : AppTheme.critical.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _testSuccess == true
                ? LucideIcons.checkCircle
                : LucideIcons.alertCircle,
            size: 18,
            color: _testSuccess == true
                ? const Color(0xFF00E676)
                : AppTheme.critical,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _testResult!,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _testSuccess == true
                    ? const Color(0xFF00E676)
                    : AppTheme.critical,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
