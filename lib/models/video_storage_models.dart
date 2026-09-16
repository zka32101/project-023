/// Models for video storage management

/// Metadata for a stored video
class VideoMetadata {
  /// Creation timestamp
  final DateTime createdAt;

  /// Video width in pixels
  final int width;

  /// Video height in pixels
  final int height;

  /// File size in bytes
  final int fileSizeBytes;

  /// Video duration in seconds
  final double durationSeconds;

  /// Video frame rate (fps)
  final int fps;

  /// Video format (mp4, webm, mov)
  final String format;

  VideoMetadata({
    required this.createdAt,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.durationSeconds,
    required this.fps,
    required this.format,
  });

  /// Get human-readable file size
  String getFileSizeString() {
    if (fileSizeBytes < 1024) {
      return '${fileSizeBytes} B';
    } else if (fileSizeBytes < 1024 * 1024) {
      final kb = fileSizeBytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      final mb = fileSizeBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = fileSizeBytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  /// Get resolution string (e.g., "1920x1080")
  String getResolutionString() => '${width}x$height';

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'width': width,
    'height': height,
    'fileSizeBytes': fileSizeBytes,
    'durationSeconds': durationSeconds,
    'fps': fps,
    'format': format,
  };

  /// Create from JSON
  factory VideoMetadata.fromJson(Map<String, dynamic> json) => VideoMetadata(
    createdAt: DateTime.parse(json['createdAt'] as String),
    width: json['width'] as int,
    height: json['height'] as int,
    fileSizeBytes: json['fileSizeBytes'] as int,
    durationSeconds: (json['durationSeconds'] as num).toDouble(),
    fps: json['fps'] as int,
    format: json['format'] as String,
  );

  @override
  String toString() =>
      'VideoMetadata($width×$height, ${getFileSizeString()}, ${durationSeconds.toStringAsFixed(1)}s)';
}

/// Information about a saved video
class SavedVideo {
  /// Unique identifier for this video
  final String id;

  /// Reference to the project that created this video
  final String projectId;

  /// File path to the saved video
  final String filePath;

  /// Video metadata
  final VideoMetadata metadata;

  /// Thumbnail path (if available)
  final String? thumbnailPath;

  /// Custom display name
  final String? displayName;

  SavedVideo({
    required this.id,
    required this.projectId,
    required this.filePath,
    required this.metadata,
    this.thumbnailPath,
    this.displayName,
  });

  /// Get the display name, falling back to ID if not set
  String getDisplayName() => displayName ?? 'Video ${id.substring(0, 8)}';

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'filePath': filePath,
    'metadata': metadata.toJson(),
    'thumbnailPath': thumbnailPath,
    'displayName': displayName,
  };

  /// Create from JSON
  factory SavedVideo.fromJson(Map<String, dynamic> json) => SavedVideo(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    filePath: json['filePath'] as String,
    metadata: VideoMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    thumbnailPath: json['thumbnailPath'] as String?,
    displayName: json['displayName'] as String?,
  );

  @override
  String toString() =>
      'SavedVideo(${getDisplayName()}, ${metadata.getFileSizeString()})';
}

/// Storage space information
class StorageInfo {
  /// Total available storage in bytes
  final int totalBytes;

  /// Used storage in bytes
  final int usedBytes;

  /// Free storage in bytes
  final int freeBytes;

  StorageInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
  });

  /// Percentage of storage used (0.0 to 1.0)
  double get percentageUsed => totalBytes > 0 ? usedBytes / totalBytes : 0.0;

  /// Whether storage is critically low (less than 100MB free)
  bool get isCriticallyLow => freeBytes < 100 * 1024 * 1024;

  /// Whether storage is low (less than 500MB free)
  bool get isLow => freeBytes < 500 * 1024 * 1024;

  /// Get human-readable used space string
  String getUsedString() {
    if (usedBytes < 1024 * 1024) {
      final kb = usedBytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (usedBytes < 1024 * 1024 * 1024) {
      final mb = usedBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = usedBytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  /// Get human-readable free space string
  String getFreeString() {
    if (freeBytes < 1024 * 1024) {
      final kb = freeBytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (freeBytes < 1024 * 1024 * 1024) {
      final mb = freeBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = freeBytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  /// Get human-readable total space string
  String getTotalString() {
    if (totalBytes < 1024 * 1024) {
      final kb = totalBytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      final mb = totalBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = totalBytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  @override
  String toString() =>
      'StorageInfo(${getUsedString()} / ${getTotalString()}, ${getFreeString()} free)';
}
