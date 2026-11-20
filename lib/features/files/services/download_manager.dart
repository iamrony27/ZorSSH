import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:aetherssh/core/services/sftp_service.dart';
import 'package:aetherssh/core/utils/app_logger.dart';
import 'package:aetherssh/core/utils/storage_helper.dart';
import 'package:aetherssh/features/files/data/download_task.dart';
import 'package:aetherssh/features/files/data/remote_file.dart';

class DownloadManagerState {
  final List<DownloadTask> tasks;

  const DownloadManagerState({this.tasks = const []});

  int get activeCount =>
      tasks.where((t) => t.status == DownloadStatus.downloading).length;

  int get completedCount =>
      tasks.where((t) => t.status == DownloadStatus.completed).length;

  DownloadManagerState copyWith({List<DownloadTask>? tasks}) {
    return DownloadManagerState(tasks: tasks ?? this.tasks);
  }
}

class DownloadManager extends StateNotifier<DownloadManagerState> {
  final _uuid = const Uuid();
  final Map<String, bool> _cancellationFlags = {};

  DownloadManager() : super(const DownloadManagerState());

  /// Enqueue and start downloading a single file
  Future<DownloadTask> enqueueDownload({
    required SftpService sftp,
    required RemoteFile file,
    String? customDirectory,
  }) async {
    final taskId = _uuid.v4();
    final task = DownloadTask(
      id: taskId,
      remotePath: file.path,
      fileName: file.name,
      totalBytes: file.size,
      status: DownloadStatus.pending,
    );

    state = state.copyWith(tasks: [task, ...state.tasks]);
    _runDownload(taskId, sftp, file, customDirectory);
    return task;
  }

  /// Enqueue multiple files
  Future<void> enqueueMultiple({
    required SftpService sftp,
    required List<RemoteFile> files,
    String? customDirectory,
  }) async {
    for (final file in files) {
      if (!file.isDirectory) {
        await enqueueDownload(
          sftp: sftp,
          file: file,
          customDirectory: customDirectory,
        );
      }
    }
  }

  void cancelDownload(String taskId) {
    _cancellationFlags[taskId] = true;
    _updateTask(
      taskId,
      (t) => t.copyWith(
        status: DownloadStatus.cancelled,
        errorMessage: 'Cancelled by user',
      ),
    );
  }

  Future<void> retryDownload(String taskId, SftpService sftp) async {
    final task = state.tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found'),
    );

    _cancellationFlags.remove(taskId);
    _updateTask(
      taskId,
      (t) => t.copyWith(
        status: DownloadStatus.pending,
        downloadedBytes: 0,
        speedBytesPerSecond: 0,
        errorMessage: null,
      ),
    );

    final remoteFile = RemoteFile(
      name: task.fileName,
      path: task.remotePath,
      isDirectory: false,
      size: task.totalBytes,
      modified: DateTime.now(),
      permissions: '',
      owner: '',
      group: '',
    );

    _runDownload(taskId, sftp, remoteFile, null);
  }

  void clearCompleted() {
    state = state.copyWith(
      tasks: state.tasks
          .where(
            (t) =>
                t.status != DownloadStatus.completed &&
                t.status != DownloadStatus.cancelled,
          )
          .toList(),
    );
  }

  void removeTask(String taskId) {
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != taskId).toList(),
    );
  }

  Future<void> _runDownload(
    String taskId,
    SftpService sftp,
    RemoteFile file,
    String? customDirectory,
  ) async {
    _updateTask(
      taskId,
      (t) => t.copyWith(status: DownloadStatus.downloading),
    );

    try {
      final destDir = customDirectory ??
          (await StorageHelper.getDownloadsDirectoryPath()).path;

      final targetPath = StorageHelper.getNonCollidingPath(destDir, file.name);

      _updateTask(taskId, (t) => t.copyWith(localPath: targetPath));

      await sftp.downloadFile(
        file.path,
        destinationPath: targetPath,
        isCancelled: () => _cancellationFlags[taskId] == true,
        onProgressExtended: (received, total, speed) {
          if (_cancellationFlags[taskId] == true) return;
          _updateTask(
            taskId,
            (t) => t.copyWith(
              downloadedBytes: received,
              totalBytes: total > 0 ? total : t.totalBytes,
              speedBytesPerSecond: speed,
            ),
          );
        },
      );

      if (_cancellationFlags[taskId] == true) {
        _updateTask(
          taskId,
          (t) => t.copyWith(
            status: DownloadStatus.cancelled,
            errorMessage: 'Cancelled by user',
          ),
        );
        return;
      }

      _updateTask(
        taskId,
        (t) => t.copyWith(
          status: DownloadStatus.completed,
          completedTime: DateTime.now(),
          downloadedBytes: t.totalBytes > 0 ? t.totalBytes : t.downloadedBytes,
          speedBytesPerSecond: 0,
        ),
      );
      AppLogger.info('DownloadManager: Completed download of ${file.name}');
    } catch (e) {
      if (_cancellationFlags[taskId] == true) {
        _updateTask(
          taskId,
          (t) => t.copyWith(
            status: DownloadStatus.cancelled,
            errorMessage: 'Cancelled by user',
          ),
        );
      } else {
        AppLogger.error('DownloadManager: Failed download of ${file.name}: $e');
        _updateTask(
          taskId,
          (t) => t.copyWith(
            status: DownloadStatus.failed,
            errorMessage: e.toString().replaceFirst('Exception: ', ''),
            speedBytesPerSecond: 0,
          ),
        );
      }
    } finally {
      _cancellationFlags.remove(taskId);
    }
  }

  void _updateTask(String taskId, DownloadTask Function(DownloadTask) updater) {
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.id == taskId ? updater(t) : t).toList(),
    );
  }
}

final downloadManagerProvider =
    StateNotifierProvider<DownloadManager, DownloadManagerState>((ref) {
      return DownloadManager();
    });
