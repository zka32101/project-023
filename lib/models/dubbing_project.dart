import 'audio_track.dart';

/// ダビングプロジェクトモデル
class DubbingProject {
  final String id;
  final String characterId;    // CustomCharacter への参照
  final String projectName;
  final List<AudioTrack> tracks;
  final int fps;               // アニメーション FPS
  final int totalFrames;
  final DateTime createdAt;

  DubbingProject({
    required this.id,
    required this.characterId,
    required this.projectName,
    required this.tracks,
    required this.fps,
    required this.totalFrames,
    required this.createdAt,
  });

  /// copyWithメソッド - 一部フィールドを上書きしたコピーを作成
  DubbingProject copyWith({
    String? id,
    String? characterId,
    String? projectName,
    List<AudioTrack>? tracks,
    int? fps,
    int? totalFrames,
    DateTime? createdAt,
  }) {
    return DubbingProject(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      projectName: projectName ?? this.projectName,
      tracks: tracks ?? this.tracks,
      fps: fps ?? this.fps,
      totalFrames: totalFrames ?? this.totalFrames,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// プロジェクトの総再生時間（ミリ秒）
  int getTotalDuration() {
    if (tracks.isEmpty) return 0;
    return tracks.fold<int>(0, (max, track) => max > track.duration ? max : track.duration);
  }

  /// フレーム数から時間を計算（ミリ秒）
  int framesToMilliseconds(int frames) {
    return (frames / fps * 1000).toInt();
  }

  /// 時間からフレーム数を計算
  int millisecondsToFrames(int milliseconds) {
    return (milliseconds / 1000 * fps).toInt();
  }

  /// JSON形式で保存するためのマップ変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'projectName': projectName,
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'fps': fps,
      'totalFrames': totalFrames,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSONから生成するファクトリーコンストラクタ
  factory DubbingProject.fromJson(Map<String, dynamic> json) {
    return DubbingProject(
      id: json['id'] as String,
      characterId: json['characterId'] as String,
      projectName: json['projectName'] as String,
      tracks: (json['tracks'] as List<dynamic>)
          .map((track) => AudioTrack.fromJson(track as Map<String, dynamic>))
          .toList(),
      fps: json['fps'] as int,
      totalFrames: json['totalFrames'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DubbingProject &&
        other.id == id &&
        other.characterId == characterId &&
        other.projectName == projectName &&
        _listEquals(other.tracks, tracks) &&
        other.fps == fps &&
        other.totalFrames == totalFrames &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        characterId.hashCode ^
        projectName.hashCode ^
        tracks.hashCode ^
        fps.hashCode ^
        totalFrames.hashCode ^
        createdAt.hashCode;
  }

  /// リストの等価性チェック
  static bool _listEquals(List<AudioTrack> a, List<AudioTrack> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'DubbingProject(id: $id, projectName: $projectName, characterId: $characterId, trackCount: ${tracks.length}, fps: $fps, totalFrames: $totalFrames)';
  }
}
