import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zorssh/core/theme/app_theme.dart';
import 'package:zorssh/features/files/data/remote_file.dart';

/// Next-gen floating file/folder card item widget
class RemoteFileItem extends StatelessWidget {
  final RemoteFile file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isInMultiSelectMode;
  final bool isNavigationDisabled;
  final VoidCallback? onToggleSelect;
  final ViewMode viewMode;

  const RemoteFileItem({
    super.key,
    required this.file,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isInMultiSelectMode = false,
    this.isNavigationDisabled = false,
    this.onToggleSelect,
    this.viewMode = ViewMode.list,
  });

  @override
  Widget build(BuildContext context) {
    if (viewMode == ViewMode.grid) {
      return _buildGridItem();
    }
    return _buildListItem();
  }

  Widget _buildListItem() {
    return IgnorePointer(
      ignoring: isNavigationDisabled,
      child: AnimatedOpacity(
        opacity: isNavigationDisabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF132034)
                : const Color(0xFF10131B),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : Colors.white.withValues(alpha: 0.06),
              width: isSelected ? 1.4 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.4 : 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: isInMultiSelectMode ? onToggleSelect : onTap,
              onLongPress: isNavigationDisabled ? null : onLongPress,
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Selection checkbox in multi-select mode
                    if (isInMultiSelectMode) ...[
                      Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggleSelect?.call(),
                          activeColor: const Color(0xFF00E676),
                          checkColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Squircle Icon Badge
                    _buildIconBadge(size: 42),
                    const SizedBox(width: 14),

                    // File Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File / Folder Name Row
                          Row(
                            children: [
                              if (file.isHidden) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.eyeOff,
                                        size: 10,
                                        color: Colors.white60,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (file.isLink) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    LucideIcons.link,
                                    size: 10,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  file.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: file.isDirectory
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: Colors.white,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          // Metadata Row (Size, Permissions, Date)
                          Row(
                            children: [
                              // Size Tag
                              Text(
                                file.formattedSize,
                                style: GoogleFonts.firaCode(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: file.isDirectory
                                      ? const Color(0xFF00E676).withValues(alpha: 0.85)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),

                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Modified time
                              Text(
                                file.formattedModified,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),

                              // Permissions chip
                              if (file.permissions.isNotEmpty && !file.isDirectory) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF181F2C),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    file.permissions,
                                    style: GoogleFonts.firaCode(
                                      fontSize: 9.5,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Directory Chevron
                    if (file.isDirectory && !isInMultiSelectMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem() {
    return IgnorePointer(
      ignoring: isNavigationDisabled,
      child: AnimatedOpacity(
        opacity: isNavigationDisabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF132034)
                : const Color(0xFF10131B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : Colors.white.withValues(alpha: 0.07),
              width: isSelected ? 1.4 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: isInMultiSelectMode ? onToggleSelect : onTap,
              onLongPress: isNavigationDisabled ? null : onLongPress,
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildIconBadge(size: 48),
                        const SizedBox(height: 10),
                        Text(
                          file.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: file.isDirectory
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file.formattedSize,
                          style: GoogleFonts.firaCode(
                            fontSize: 10.5,
                            color: file.isDirectory
                                ? const Color(0xFF00E676)
                                : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Selection checkbox for grid
                  if (isInMultiSelectMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E676)
                                : Colors.white30,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                LucideIcons.check,
                                size: 14,
                                color: Colors.black,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Squircle dual-tone badge with vibrant glowing color according to file type
  Widget _buildIconBadge({required double size}) {
    IconData icon;
    Color primaryColor;
    Color bgTint;

    if (file.isDirectory) {
      icon = LucideIcons.folder;
      primaryColor = const Color(0xFF00E676); // Emerald
      bgTint = const Color(0xFF00E676).withValues(alpha: 0.12);
    } else {
      switch (file.fileType) {
        case 'image':
          icon = LucideIcons.image;
          primaryColor = const Color(0xFFE040FB); // Magenta
          bgTint = const Color(0xFFE040FB).withValues(alpha: 0.12);
          break;
        case 'video':
          icon = LucideIcons.video;
          primaryColor = const Color(0xFFFF5252); // Red/Coral
          bgTint = const Color(0xFFFF5252).withValues(alpha: 0.12);
          break;
        case 'audio':
          icon = LucideIcons.music;
          primaryColor = const Color(0xFFFF4081); // Pink
          bgTint = const Color(0xFFFF4081).withValues(alpha: 0.12);
          break;
        case 'code':
          icon = LucideIcons.code2;
          primaryColor = const Color(0xFF00B0FF); // Electric Cyan
          bgTint = const Color(0xFF00B0FF).withValues(alpha: 0.12);
          break;
        case 'archive':
          icon = LucideIcons.archive;
          primaryColor = const Color(0xFFFF9100); // Amber
          bgTint = const Color(0xFFFF9100).withValues(alpha: 0.12);
          break;
        case 'config':
          icon = LucideIcons.settings2;
          primaryColor = const Color(0xFF7C4DFF); // Deep Purple
          bgTint = const Color(0xFF7C4DFF).withValues(alpha: 0.12);
          break;
        case 'document':
          icon = LucideIcons.fileText;
          primaryColor = const Color(0xFF40C4FF); // Sky Blue
          bgTint = const Color(0xFF40C4FF).withValues(alpha: 0.12);
          break;
        default:
          icon = LucideIcons.file;
          primaryColor = const Color(0xFF94A3B8); // Slate
          bgTint = Colors.white.withValues(alpha: 0.05);
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.48,
          color: primaryColor,
        ),
      ),
    );
  }
}

/// View mode enum
enum ViewMode { list, grid }
