/// オーディオトラックモデル
class AudioTrack {
  final String id;
  final String name;
  final String audioPath;
  final int startFrame;        // アニメーションのどのフレームから再生
  final double volume;
  final bool isMuted;
  final DateTime createdAt;
  final int duration;          // ミリ秒

  AudioTrack({
    required this.id,
    required this.name,
    required this.audioPath,
    required this.startFrame,
    required this.volume,
    required this.isMuted,
    required this.createdAt,
    required this.duration,
  });

  /// copyWithメソッド - 一部フィールドを上書きしたコピーを作成
  AudioTrack copyWith({
    String? id,
    String? name,
    String? audioPath,
    int? startFrame,
    double? volume,
    bool? isMuted,
    DateTime? createdAt,
    int? duration,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      audioPath: audioPath ?? this.audioPath,
      startFrame: startFrame ?? this.startFrame,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
    );
  }

  /// JSON形式で保存するためのマップ変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'audioPath': audioPath,
      'startFrame': startFrame,
      'volume': volume,
      'isMuted': isMuted,
      'createdAt': createdAt.toIso8601String(),
      'duration': duration,
    };
  }

  /// JSONから生成するファクトリーコンストラクタ
  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'] as String,
      name: json['name'] as String,
      audioPath: json['audioPath'] as String,
      startFrame: json['startFrame'] as int,
      volume: (json['volume'] as num).toDouble(),
      isMuted: json['isMuted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      duration: json['duration'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AudioTrack &&
        other.id == id &&
        other.name == name &&
        other.audioPath == audioPath &&
        other.startFrame == startFrame &&
        other.volume == volume &&
        other.isMuted == isMuted &&
        other.createdAt == createdAt &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        audioPath.hashCode ^
        startFrame.hashCode ^
        volume.hashCode ^
        isMuted.hashCode ^
        createdAt.hashCode ^
        duration.hashCode;
  }

  @override
  String toString() {
    return 'AudioTrack(id: $id, name: $name, startFrame: $startFrame, volume: $volume, isMuted: $isMuted, duration: $duration)';
  }
}
