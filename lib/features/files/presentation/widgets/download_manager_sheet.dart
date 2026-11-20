import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:aetherssh/core/theme/app_theme.dart';
import 'package:aetherssh/core/utils/formatters.dart';
import 'package:aetherssh/features/files/data/download_task.dart';
import 'package:aetherssh/features/files/providers/file_browser_provider.dart';
import 'package:aetherssh/features/files/services/download_manager.dart';

class DownloadManagerSheet extends ConsumerWidget {
  const DownloadManagerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121316),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const DownloadManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadManagerProvider);
    final sftpService = ref.watch(sftpServiceProvider);
    final tasks = downloadState.tasks;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.downloadCloud,
                        color: AppTheme.terminalMint,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Download Manager',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (downloadState.activeCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.terminalMint.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${downloadState.activeCount}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.terminalMint,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tasks.any((t) => t.status == DownloadStatus.completed))
                    TextButton.icon(
                      onPressed: () => ref
                          .read(downloadManagerProvider.notifier)
                          .clearCompleted(),
                      icon: const Icon(LucideIcons.trash2, size: 14),
                      label: const Text('Clear Finished'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        textStyle: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              // Task List
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.inbox,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No recent downloads',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: tasks.length,
                        separatorBuilder: (context, _) =>
                            const Divider(color: Colors.white10, height: 16),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _buildTaskTile(context, ref, task, sftpService);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    WidgetRef ref,
    DownloadTask task,
    dynamic sftpService,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(task.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.fileName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _buildSubtitleText(task),
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: task.status == DownloadStatus.failed
                            ? AppTheme.critical
                            : AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildActionButtons(ref, task, sftpService),
            ],
          ),
          if (task.status == DownloadStatus.downloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress > 0 ? task.progress : null,
                backgroundColor: Colors.white10,
                valueColor:
                    const AlwaysStoppedAnimation(AppTheme.terminalMint),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
      case DownloadStatus.downloading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppTheme.terminalMint),
          ),
        );
      case DownloadStatus.completed:
        return const Icon(
          LucideIcons.checkCircle2,
          color: AppTheme.terminalMint,
          size: 20,
        );
      case DownloadStatus.failed:
        return const Icon(
          LucideIcons.alertTriangle,
          color: AppTheme.critical,
          size: 20,
        );
      case DownloadStatus.cancelled:
        return const Icon(
          LucideIcons.xCircle,
          color: AppTheme.textSecondary,
          size: 20,
        );
    }
  }

  String _buildSubtitleText(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.pending:
        return 'Preparing download...';
      case DownloadStatus.downloading:
        final downloaded = formatBytes(task.downloadedBytes);
        final total = task.totalBytes > 0
            ? formatBytes(task.totalBytes)
            : 'Unknown';
        return '$downloaded / $total • ${task.formattedSpeed}';
      case DownloadStatus.completed:
        final size = formatBytes(task.downloadedBytes);
        return 'Completed ($size) • Saved to Downloads';
      case DownloadStatus.failed:
        return task.errorMessage ?? 'Download failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  Widget _buildActionButtons(
    WidgetRef ref,
    DownloadTask task,
    dynamic sftpService,
  ) {
    if (task.status == DownloadStatus.downloading) {
      return IconButton(
        icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.critical),
        tooltip: 'Cancel',
        onPressed: () =>
            ref.read(downloadManagerProvider.notifier).cancelDownload(task.id),
      );
    }

    if (task.status == DownloadStatus.completed && task.localPath != null) {
      return IconButton(
        icon: const Icon(LucideIcons.share2, size: 18, color: Colors.white70),
        tooltip: 'Share',
        onPressed: () {
          SharePlus.instance.share(ShareParams(files: [XFile(task.localPath!)]));
        },
      );
    }

    if (task.status == DownloadStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              LucideIcons.refreshCw,
              size: 16,
              color: AppTheme.terminalMint,
            ),
            tooltip: 'Retry',
            onPressed: () => ref
                .read(downloadManagerProvider.notifier)
                .retryDownload(task.id, sftpService),
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.trash2,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            tooltip: 'Dismiss',
            onPressed: () =>
                ref.read(downloadManagerProvider.notifier).removeTask(task.id),
          ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(
        LucideIcons.trash2,
        size: 16,
        color: AppTheme.textSecondary,
      ),
      tooltip: 'Remove',
      onPressed: () =>
          ref.read(downloadManagerProvider.notifier).removeTask(task.id),
    );
  }
}
