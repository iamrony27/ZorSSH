import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zorssh/core/localization/app_localization.dart';
import 'package:zorssh/core/theme/app_theme.dart';
import 'package:zorssh/core/theme/app_sizes.dart';
import 'package:zorssh/features/settings/presentation/widgets/language_tile.dart';
import 'package:zorssh/features/settings/presentation/widgets/poll_interval_tile.dart';
import 'package:zorssh/features/settings/presentation/widgets/biometrics_tile.dart';
import 'package:zorssh/features/settings/presentation/widgets/upi_donation_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zorssh/features/settings/providers/settings_provider.dart';
import 'package:zorssh/core/providers.dart';
import 'package:zorssh/core/widgets/clipboard_sync_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(
          ref.tr('settings'),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSizes.p16,
          AppSizes.p16,
          AppSizes.p16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        children: [
          // ── Group 1: Intelligence & Server Management ─────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'INTELLIGENCE & SERVERS',
              style: AppTheme.sectionTitleStyle,
            ),
          ),
          _buildSettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p6,
                ),
                leading: _buildIconContainer(
                  icon: LucideIcons.server,
                  color: const Color(0xFF00B0FF),
                  bgColor: const Color(0xFF00B0FF).withValues(alpha: 0.12),
                ),
                title: Text(
                  ref.tr('manage_servers'),
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  ref.tr('manage_servers_subtitle'),
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onTap: () => context.push('/manage-servers'),
              ),
              _divider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p6,
                ),
                leading: _buildIconContainer(
                  icon: LucideIcons.sparkles,
                  color: const Color(0xFF00E676),
                  bgColor: const Color(0xFF00E676).withValues(alpha: 0.12),
                ),
                title: Text(
                  'Zor AI Assistant',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Neural terminal intelligence & custom models',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onTap: () => context.push('/ai-settings'),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.p24),

          // ── Group 2: Security & Authentication ────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SECURITY & ACCESS',
              style: AppTheme.sectionTitleStyle,
            ),
          ),
          _buildSettingsCard(
            children: [
              const BiometricsTile(),
              _divider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p4,
                ),
                leading: _buildIconContainer(
                  icon: LucideIcons.shieldCheck,
                  color: const Color(0xFFFF9100),
                  bgColor: const Color(0xFFFF9100).withValues(alpha: 0.12),
                ),
                title: Text(
                  'Change Master PIN',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Update the PIN used to secure the app',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onTap: () => context.push('/change-pin'),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.p24),

          // ── Group 3: Preferences & Environment ────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'PREFERENCES',
              style: AppTheme.sectionTitleStyle,
            ),
          ),
          _buildSettingsCard(
            children: [
              const PollIntervalTile(),
              _divider(),
              Consumer(
                builder: (context, ref, _) {
                  final settingsAsync = ref.watch(settingsProvider);
                  final isGeoEnabled = settingsAsync.maybeWhen(
                    data: (s) => s.isGeolocationEnabled,
                    orElse: () => false,
                  );
                  return SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p16,
                      vertical: AppSizes.p4,
                    ),
                    secondary: _buildIconContainer(
                      icon: LucideIcons.mapPin,
                      color: const Color(0xFF29B6F6),
                      bgColor: const Color(0xFF29B6F6).withValues(alpha: 0.12),
                    ),
                    title: Text(
                      'Server Geolocation',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Look up server country & city via ipwho.is (HTTPS)',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: isGeoEnabled,
                    activeThumbColor: const Color(0xFF00E676),
                    activeTrackColor: const Color(0xFF00E676).withValues(
                      alpha: 0.3,
                    ),
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setGeolocationEnabled(val);
                    },
                  );
                },
              ),
              _divider(),
              Consumer(
                builder: (context, ref, _) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p16,
                      vertical: AppSizes.p4,
                    ),
                    leading: _buildIconContainer(
                      icon: LucideIcons.clipboardCopy,
                      color: const Color(0xFF00E5FF),
                      bgColor: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    ),
                    title: Text(
                      'Shared Clipboard',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Bi-directional sync between device & remote host',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      LucideIcons.chevronRight,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                    onTap: () {
                      final servers =
                          ref.read(serverListStreamProvider).asData?.value ??
                          [];
                      if (servers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No servers configured yet. Add a server first.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (servers.length == 1) {
                        ClipboardSyncSheet.show(context, server: servers.first);
                      } else {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          backgroundColor: AppTheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Select Server for Clipboard Sync',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                ...servers.map(
                                  (s) => ListTile(
                                    leading: const Icon(
                                      LucideIcons.server,
                                      color: Color(0xFF00E676),
                                    ),
                                    title: Text(
                                      s.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${s.username}@${s.hostname}:${s.port}',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      ClipboardSyncSheet.show(
                                        context,
                                        server: s,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              _divider(),
              const LanguageTile(),
            ],
          ),

          const SizedBox(height: AppSizes.p24),

          // ── Group 4: Support & System ─────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SUPPORT & SYSTEM',
              style: AppTheme.sectionTitleStyle,
            ),
          ),
          _buildSettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p4,
                ),
                leading: _buildIconContainer(
                  icon: LucideIcons.heartHandshake,
                  color: const Color(0xFF00E676),
                  bgColor: const Color(0xFF00E676).withValues(alpha: 0.15),
                ),
                title: Text(
                  'Help Developer',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Support Zor SSH development via UPI donation',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00E676),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onTap: () => UpiDonationSheet.show(context),
              ),
              _divider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p4,
                ),
                leading: _buildIconContainer(
                  icon: LucideIcons.info,
                  color: Colors.white70,
                  bgColor: Colors.white.withValues(alpha: 0.08),
                ),
                title: Text(
                  'About Zor SSH',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'App details, licenses, privacy & terms',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onTap: () => context.push('/about'),
              ),
              _divider(),
              const _UpdateTile(),
            ],
          ),

          const SizedBox(height: AppSizes.p32),

          // App version footer
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.2.0';
              final buildNumber = snapshot.data?.buildNumber;
              final versionText =
                  (buildNumber != null && buildNumber.isNotEmpty)
                      ? 'Zor SSH v$version+$buildNumber'
                      : 'Zor SSH v$version';
              return Center(
                child: Text(
                  versionText,
                  style: GoogleFonts.firaCode(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Modern elevated card container with cyber-glass styling
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10131B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// Dual-tone rounded badge for settings list tile leading icons
  Widget _buildIconContainer({
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.white.withValues(alpha: 0.05),
      indent: AppSizes.p16,
      endIndent: AppSizes.p16,
    );
  }
}

class _UpdateTile extends StatefulWidget {
  const _UpdateTile();

  @override
  State<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<_UpdateTile> {
  bool _isChecking = false;

  static const String _githubRepo = 'iamrony27/ZorSSH';

  bool _isNewer(String remote, String local) {
    try {
      final rParts = remote.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final lParts = local.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _checkForUpdate() async {
    setState(() => _isChecking = true);
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      // 1. Query GitHub Releases for iamrony27/ZorSSH
      final uri = Uri.parse('https://api.github.com/repos/$_githubRepo/releases/latest');
      final response = await http
          .get(uri, headers: {'Accept': 'application/vnd.github.v3+json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '').trim();
        final releaseUrl = data['html_url'] as String? ?? 'https://github.com/$_githubRepo/releases';
        final releaseName = data['name'] as String? ?? 'v$tagName';
        final releaseNotes = data['body'] as String? ?? '';

        String? apkDownloadUrl;
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('.apk')) {
              apkDownloadUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }

        if (_isNewer(tagName, currentVersion)) {
          if (mounted) {
            _showUpdateDialog(
              latestVersion: tagName,
              currentVersion: currentVersion,
              releaseName: releaseName,
              releaseNotes: releaseNotes,
              downloadUrl: apkDownloadUrl ?? releaseUrl,
            );
          }
          return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Zor SSH is up to date (v$currentVersion)!'),
                backgroundColor: const Color(0xFF00E676),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      } else {
        // Fallback: check InAppUpdate if available on Play Store
        try {
          final updateInfo = await InAppUpdate.checkForUpdate();
          if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
            if (mounted) {
              _showPlayStoreDialog();
            }
            return;
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zor SSH is up to date (v$currentVersion). GitHub repository verified.'),
              backgroundColor: const Color(0xFF00E676),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to reach GitHub. Please check internet connection.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _showPlayStoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131822),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Available',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'A new version of Zor SSH is available on the Play Store.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              InAppUpdate.performImmediateUpdate();
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog({
    required String latestVersion,
    required String currentVersion,
    required String releaseName,
    required String releaseNotes,
    required String downloadUrl,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131822),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: Color(0xFF00E676), size: 22),
            const SizedBox(width: 10),
            Text(
              'Update Available',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new release of Zor SSH is available on GitHub:',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    releaseName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Installed: v$currentVersion → Latest: v$latestVersion',
                    style: GoogleFonts.firaCode(
                      fontSize: 11.5,
                      color: const Color(0xFF00E676),
                    ),
                  ),
                  if (releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      releaseNotes.length > 150
                          ? '${releaseNotes.substring(0, 150)}...'
                          : releaseNotes,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(downloadUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(LucideIcons.download, size: 16),
            label: const Text('Download APK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p4,
      ),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        child: const Center(
          child: Icon(
            LucideIcons.refreshCw,
            color: Colors.white70,
            size: 18,
          ),
        ),
      ),
      title: Text(
        'Check for Updates',
        style: GoogleFonts.inter(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Verify latest release build',
        style: GoogleFonts.inter(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: _isChecking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00E676),
              ),
            )
          : const Icon(
              LucideIcons.chevronRight,
              color: AppTheme.textSecondary,
              size: 18,
            ),
      onTap: _isChecking ? null : _checkForUpdate,
    );
  }
}
