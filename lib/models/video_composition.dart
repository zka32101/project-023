/// Video composition model for managing generated videos

import 'package:flutter/foundation.dart';

/// Status of video composition process
enum CompositionStatus {
  pending,     // Waiting to start
  processing,  // Currently composing
  completed,   // Successfully completed
  failed,      // Failed with error
}

/// Progress information during composition
class CompositionProgress {
  /// Number of frames processed so far
  final int processedFrames;

  /// Total number of frames to process
  final int totalFrames;

  /// Percentage complete (0.0 to 1.0)
  final double percentComplete;

  /// Estimated time remaining in seconds
  final int estimatedSecondsRemaining;

  CompositionProgress({
    required this.processedFrames,
    required this.totalFrames,
    required this.percentComplete,
    required this.estimatedSecondsRemaining,
  });

  /// Check if composition is complete
  bool get isComplete => percentComplete >= 1.0;

  /// Get human-readable progress string
  String getProgressString() {
    final percent = (percentComplete * 100).toStringAsFixed(1);
    return '$processedFrames / $totalFrames frames ($percent%)';
  }

  /// Create from frame count
  factory CompositionProgress.fromFrames(
    int processedFrames,
    int totalFrames,
    int startTimeSeconds,
    int currentTimeSeconds,
  ) {
    final percent = totalFrames > 0 ? processedFrames / totalFrames : 0.0;
    final elapsedSeconds = currentTimeSeconds - startTimeSeconds;
    final estimatedTotal = elapsedSeconds > 0 && percent > 0
        ? (elapsedSeconds / percent).toInt()
        : 0;
    final remaining = estimatedTotal - elapsedSeconds;

    return CompositionProgress(
      processedFrames: processedFrames,
      totalFrames: totalFrames,
      percentComplete: percent.clamp(0.0, 1.0),
      estimatedSecondsRemaining: remaining > 0 ? remaining : 0,
    );
  }

  @override
  String toString() =>
      'CompositionProgress($processedFrames/$totalFrames, ${(percentComplete * 100).toStringAsFixed(1)}%, ~${estimatedSecondsRemaining}s remaining)';
}

/// Video composition result
class VideoComposition {
  /// Unique identifier for this composition
  final String id;

  /// Reference to the DubbingProject
  final String projectId;

  /// Output file path
  final String outputPath;

  /// Video format (MP4, WebM, MOV)
  final String format;

  /// Video resolution (720p, 1080p, 4K)
  final String resolution;

  /// Frames per second
  final int fps;

  /// File size in megabytes
  final double fileSizeMB;

  /// Creation timestamp
  final DateTime createdAt;

  /// Current composition status
  final CompositionStatus status;

  /// Error message if composition failed
  final String? errorMessage;

  VideoComposition({
    required this.id,
    required this.projectId,
    required this.outputPath,
    required this.format,
    required this.resolution,
    required this.fps,
    required this.fileSizeMB,
    required this.createdAt,
    this.status = CompositionStatus.pending,
    this.errorMessage,
  });

  /// Whether composition is successful
  bool get isSuccess => status == CompositionStatus.completed;

  /// Whether composition is in progress
  bool get isProcessing => status == CompositionStatus.processing;

  /// Whether composition has failed
  bool get hasFailed => status == CompositionStatus.failed;

  /// Get human-readable file size
  String getFileSizeString() {
    if (fileSizeMB < 1) {
      return '${(fileSizeMB * 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeMB < 1024) {
      return '${fileSizeMB.toStringAsFixed(2)} MB';
    } else {
      final gb = fileSizeMB / 1024;
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  /// Get status label in Japanese
  String getStatusLabel() {
    return switch (status) {
      CompositionStatus.pending => '待機中',
      CompositionStatus.processing => '処理中',
      CompositionStatus.completed => '完了',
      CompositionStatus.failed => 'エラー',
    };
  }

  /// Create copy with modified fields
  VideoComposition copyWith({
    String? id,
    String? projectId,
    String? outputPath,
    String? format,
    String? resolution,
    int? fps,
    double? fileSizeMB,
    DateTime? createdAt,
    CompositionStatus? status,
    String? errorMessage,
  }) {
    return VideoComposition(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      outputPath: outputPath ?? this.outputPath,
      format: format ?? this.format,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      fileSizeMB: fileSizeMB ?? this.fileSizeMB,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'outputPath': outputPath,
      'format': format,
      'resolution': resolution,
      'fps': fps,
      'fileSizeMB': fileSizeMB,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory VideoComposition.fromJson(Map<String, dynamic> json) {
    return VideoComposition(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      outputPath: json['outputPath'] as String,
      format: json['format'] as String,
      resolution: json['resolution'] as String,
      fps: json['fps'] as int,
      fileSizeMB: (json['fileSizeMB'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: CompositionStatus.values.byName(json['status'] as String),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VideoComposition &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            projectId == other.projectId &&
            outputPath == other.outputPath &&
            format == other.format &&
            resolution == other.resolution &&
            fps == other.fps &&
            fileSizeMB == other.fileSizeMB &&
            createdAt == other.createdAt &&
            status == other.status &&
            errorMessage == other.errorMessage;
  }

  @override
  int get hashCode {
    return hashValues(
      id,
      projectId,
      outputPath,
      format,
      resolution,
      fps,
      fileSizeMB,
      createdAt,
      status,
      errorMessage,
    );
  }

  @override
  String toString() =>
      'VideoComposition($id, $format, $resolution, ${getStatusLabel()})';
}

/// Video composition settings
class CompositionSettings {
  /// Video format to output
  final String format;

  /// Video resolution
  final String resolution;

  /// Frames per second
  final int fps;

  /// Video bitrate
  final String videoBitrate;

  /// Audio bitrate
  final String audioBitrate;

  /// Whether to normalize audio
  final bool normalizeAudio;

  /// Video title metadata
  final String? videoTitle;

  /// Video author metadata
  final String? videoAuthor;

  CompositionSettings({
    required this.format,
    required this.resolution,
    required this.fps,
    this.videoBitrate = '3000k',
    this.audioBitrate = '128k',
    this.normalizeAudio = true,
    this.videoTitle,
    this.videoAuthor,
  });

  /// Validate settings
  bool get isValid {
    return ['mp4', 'webm', 'mov'].contains(format.toLowerCase()) &&
        ['720p', '1080p', '4k'].contains(resolution) &&
        fps > 0 &&
        fps <= 60;
  }

  /// Get human-readable resolution label
  String getResolutionLabel() {
    return switch (resolution) {
      '720p' => '1280x720',
      '1080p' => '1920x1080',
      '4k' => '3840x2160',
      _ => resolution,
    };
  }

  /// Create copy with modified fields
  CompositionSettings copyWith({
    String? format,
    String? resolution,
    int? fps,
    String? videoBitrate,
    String? audioBitrate,
    bool? normalizeAudio,
    String? videoTitle,
    String? videoAuthor,
  }) {
    return CompositionSettings(
      format: format ?? this.format,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      normalizeAudio: normalizeAudio ?? this.normalizeAudio,
      videoTitle: videoTitle ?? this.videoTitle,
      videoAuthor: videoAuthor ?? this.videoAuthor,
    );
  }

  @override
  String toString() =>
      'CompositionSettings($format, $resolution, ${fps}fps)';
}
