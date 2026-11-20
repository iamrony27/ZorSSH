enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String remotePath;
  final String fileName;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final double speedBytesPerSecond;
  final String? localPath;
  final String? errorMessage;
  final DateTime startTime;
  final DateTime? completedTime;

  DownloadTask({
    required this.id,
    required this.remotePath,
    required this.fileName,
    required this.totalBytes,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.speedBytesPerSecond = 0.0,
    this.localPath,
    this.errorMessage,
    DateTime? startTime,
    this.completedTime,
  }) : startTime = startTime ?? DateTime.now();

  double get progress =>
      totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  String get formattedSpeed {
    if (speedBytesPerSecond < 1024) {
      return '${speedBytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (speedBytesPerSecond < 1024 * 1024) {
      return '${(speedBytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speedBytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
  }

  DownloadTask copyWith({
    String? id,
    String? remotePath,
    String? fileName,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    double? speedBytesPerSecond,
    String? localPath,
    String? errorMessage,
    DateTime? startTime,
    DateTime? completedTime,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      remotePath: remotePath ?? this.remotePath,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      localPath: localPath ?? this.localPath,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
      completedTime: completedTime ?? this.completedTime,
    );
  }
}
