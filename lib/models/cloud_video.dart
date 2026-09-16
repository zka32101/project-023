/// Cloud storage models for video management in the cloud

/// Supported cloud storage providers
enum CloudProvider {
  googleDrive,
  iCloud,
}

/// Cloud storage quota information
class CloudStorageQuota {
  /// Total storage capacity in bytes
  final int totalBytes;

  /// Used storage in bytes
  final int usedBytes;

  /// Free storage in bytes
  final int freeBytes;

  /// Storage provider
  final CloudProvider provider;

  /// Last updated timestamp
  final DateTime lastUpdated;

  CloudStorageQuota({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.provider,
    required this.lastUpdated,
  });

  /// Percentage of storage used (0.0 to 1.0)
  double get percentageUsed =>
      totalBytes > 0 ? usedBytes / totalBytes : 0.0;

  /// Whether storage is critically low (less than 100MB free)
  bool get isCriticallyLow => freeBytes < 100 * 1024 * 1024;

  /// Whether storage is low (less than 500MB free)
  bool get isLow => freeBytes < 500 * 1024 * 1024;

  /// Get human-readable used space
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

  /// Get human-readable free space
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

  /// Get human-readable total space
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
      'CloudStorageQuota(${getUsedString()} / ${getTotalString()})';
}

/// Sync status for cloud operations
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
  paused,
}

/// Video stored in cloud
class CloudVideo {
  /// Unique identifier for this cloud video
  final String id;

  /// Cloud file ID (Google Drive or iCloud)
  final String cloudFileId;

  /// Reference to local SavedVideo
  final String localVideoId;

  /// Project ID
  final String projectId;

  /// Cloud provider
  final CloudProvider provider;

  /// File size in bytes
  final int fileSizeBytes;

  /// Sync status
  final SyncStatus status;

  /// Upload/sync timestamp
  final DateTime uploadedAt;

  /// Last sync timestamp
  final DateTime? lastSyncedAt;

  /// Error message if sync failed
  final String? errorMessage;

  /// Whether this video is available offline
  final bool isAvailableOffline;

  /// Video URL for sharing
  final String? publicUrl;

  CloudVideo({
    required this.id,
    required this.cloudFileId,
    required this.localVideoId,
    required this.projectId,
    required this.provider,
    required this.fileSizeBytes,
    this.status = SyncStatus.pending,
    required this.uploadedAt,
    this.lastSyncedAt,
    this.errorMessage,
    this.isAvailableOffline = false,
    this.publicUrl,
  });

  /// Check if sync is in progress
  bool get isSyncing => status == SyncStatus.syncing;

  /// Check if sync is complete
  bool get isSynced => status == SyncStatus.synced;

  /// Check if sync failed
  bool get hasFailed => status == SyncStatus.failed;

  /// Get provider name
  String getProviderName() {
    return switch (provider) {
      CloudProvider.googleDrive => 'Google Drive',
      CloudProvider.iCloud => 'iCloud',
    };
  }

  /// Get status label
  String getStatusLabel() {
    return switch (status) {
      SyncStatus.pending => '待機中',
      SyncStatus.syncing => '同期中',
      SyncStatus.synced => '同期済み',
      SyncStatus.failed => '失敗',
      SyncStatus.paused => '一時停止',
    };
  }

  /// Get human-readable file size
  String getFileSizeString() {
    if (fileSizeBytes < 1024 * 1024) {
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

  /// Create copy with modified fields
  CloudVideo copyWith({
    String? id,
    String? cloudFileId,
    String? localVideoId,
    String? projectId,
    CloudProvider? provider,
    int? fileSizeBytes,
    SyncStatus? status,
    DateTime? uploadedAt,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool? isAvailableOffline,
    String? publicUrl,
  }) {
    return CloudVideo(
      id: id ?? this.id,
      cloudFileId: cloudFileId ?? this.cloudFileId,
      localVideoId: localVideoId ?? this.localVideoId,
      projectId: projectId ?? this.projectId,
      provider: provider ?? this.provider,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
      publicUrl: publicUrl ?? this.publicUrl,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'cloudFileId': cloudFileId,
    'localVideoId': localVideoId,
    'projectId': projectId,
    'provider': provider.name,
    'fileSizeBytes': fileSizeBytes,
    'status': status.name,
    'uploadedAt': uploadedAt.toIso8601String(),
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'errorMessage': errorMessage,
    'isAvailableOffline': isAvailableOffline,
    'publicUrl': publicUrl,
  };

  /// Create from JSON
  factory CloudVideo.fromJson(Map<String, dynamic> json) => CloudVideo(
    id: json['id'] as String,
    cloudFileId: json['cloudFileId'] as String,
    localVideoId: json['localVideoId'] as String,
    projectId: json['projectId'] as String,
    provider: CloudProvider.values.byName(json['provider'] as String),
    fileSizeBytes: json['fileSizeBytes'] as int,
    status: SyncStatus.values.byName(json['status'] as String),
    uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    lastSyncedAt: json['lastSyncedAt'] != null
        ? DateTime.parse(json['lastSyncedAt'] as String)
        : null,
    errorMessage: json['errorMessage'] as String?,
    isAvailableOffline: json['isAvailableOffline'] as bool? ?? false,
    publicUrl: json['publicUrl'] as String?,
  );

  @override
  String toString() =>
      'CloudVideo($localVideoId, ${getProviderName()}, ${getStatusLabel()})';
}

/// Cloud sync configuration
class CloudSyncConfig {
  /// Whether to auto-sync new videos
  final bool autoSync;

  /// Maximum file size for auto-sync (in bytes)
  final int maxAutoSyncSizeBytes;

  /// Whether to sync only on WiFi
  final bool wifiOnly;

  /// Whether to create public links
  final bool createPublicLinks;

  /// Retention days for synced files (0 = unlimited)
  final int retentionDays;

  /// Preferred cloud provider
  final CloudProvider? preferredProvider;

  CloudSyncConfig({
    this.autoSync = true,
    this.maxAutoSyncSizeBytes = 500 * 1024 * 1024,
    this.wifiOnly = false,
    this.createPublicLinks = false,
    this.retentionDays = 0,
    this.preferredProvider,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'autoSync': autoSync,
    'maxAutoSyncSizeBytes': maxAutoSyncSizeBytes,
    'wifiOnly': wifiOnly,
    'createPublicLinks': createPublicLinks,
    'retentionDays': retentionDays,
    'preferredProvider': preferredProvider?.name,
  };

  /// Create from JSON
  factory CloudSyncConfig.fromJson(Map<String, dynamic> json) =>
      CloudSyncConfig(
        autoSync: json['autoSync'] as bool? ?? true,
        maxAutoSyncSizeBytes:
            json['maxAutoSyncSizeBytes'] as int? ?? (500 * 1024 * 1024),
        wifiOnly: json['wifiOnly'] as bool? ?? false,
        createPublicLinks: json['createPublicLinks'] as bool? ?? false,
        retentionDays: json['retentionDays'] as int? ?? 0,
        preferredProvider: json['preferredProvider'] != null
            ? CloudProvider.values.byName(json['preferredProvider'] as String)
            : null,
      );
}
