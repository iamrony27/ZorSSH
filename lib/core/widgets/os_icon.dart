import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:aetherssh/core/services/os_detector.dart';

class OsIconWidget extends StatelessWidget {
  final String osDistro;
  final OsInfo? osInfo;
  final double size;

  const OsIconWidget({
    super.key,
    this.osDistro = '',
    this.osInfo,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final info = osInfo ?? OsInfo.fromDistroString(osDistro);
    final d = (info.distroName.isNotEmpty ? info.distroName : osDistro).toLowerCase();

    if (info.isWindows || d.contains('windows')) return _buildWindowsLogo(size);
    if (d.contains('ubuntu')) return _buildUbuntuLogo(size);
    if (d.contains('debian')) return _buildDebianLogo(size);
    if (d.contains('mint')) return _buildMintLogo(size);
    if (d.contains('fedora')) return _buildFedoraLogo(size);
    if (d.contains('arch')) return _buildArchLogo(size);
    if (d.contains('centos') || d.contains('rhel') || d.contains('red hat') || d.contains('rocky') || d.contains('alma')) {
      return _buildRhelLogo(size);
    }
    if (d.contains('mac') || d.contains('darwin')) return _buildMacLogo(size);
    if (d.contains('android')) return _buildAndroidLogo(size);
    if (info.isLinux || d.contains('linux')) return _buildLinuxLogo(size);
    return _buildGenericLogo(size);
  }

  Widget _buildRhelLogo(double size) {
    return Tooltip(
      message: 'Red Hat / RHEL',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xFFEE0000), shape: BoxShape.circle),
        child: Center(
          child: Text('RH', style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildAndroidLogo(double size) {
    return Tooltip(
      message: 'Android',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xFF3DDC84), shape: BoxShape.circle),
        child: Center(child: Icon(LucideIcons.bot, size: size * 0.58, color: Colors.white)),
      ),
    );
  }

  Widget _buildGenericLogo(double size) {
    return Tooltip(
      message: 'OS',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(LucideIcons.monitor, size: size * 0.55, color: Colors.white70)),
      ),
    );
  }

  Widget _buildWindowsLogo(double size) {
    final tileSize = (size - 3) / 2;
    return Tooltip(
      message: 'Windows',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A4EF),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 2.5),
                Container(
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A4EF),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2.5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A4EF),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 2.5),
                Container(
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A4EF),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUbuntuLogo(double size) {
    return Tooltip(
      message: 'Ubuntu',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE95420), // Canonical Ubuntu Orange
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: size * 0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebianLogo(double size) {
    return Tooltip(
      message: 'Debian',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFA80030), // Debian Red
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            LucideIcons.disc,
            size: size * 0.65,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMintLogo(double size) {
    return Tooltip(
      message: 'Linux Mint',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF87CF3E), // Linux Mint Green
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'LM',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1B3B10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFedoraLogo(double size) {
    return Tooltip(
      message: 'Fedora',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF294172), // Fedora Blue
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            LucideIcons.infinity,
            size: size * 0.65,
            color: const Color(0xFF3C6EB4),
          ),
        ),
      ),
    );
  }

  Widget _buildArchLogo(double size) {
    return Tooltip(
      message: 'Arch Linux',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF1793D1), // Arch Cyan
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            LucideIcons.triangle,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMacLogo(double size) {
    return Tooltip(
      message: 'macOS',
      child: Icon(
        LucideIcons.apple,
        size: size,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildLinuxLogo(double size) {
    return Tooltip(
      message: 'Linux',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            LucideIcons.terminal,
            size: size * 0.55,
            color: const Color(0xFF00E676),
          ),
        ),
      ),
    );
  }
}
