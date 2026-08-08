import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus { draft, completed, exported }

class Project {
  final String projectId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final int fpsPreset;
  final int frameCount;
  final double videoDuration; // seconds
  final String? videoFileUrl;
  final String? thumbnailUrl;
  final ProjectStatus status;
  final String deviceOrientation; // 'portrait' | 'landscape'

  Project({
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.fpsPreset,
    required this.frameCount,
    required this.videoDuration,
    this.videoFileUrl,
    this.thumbnailUrl,
    required this.status,
    required this.deviceOrientation,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['projectId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title: json['title'] ?? '作品①',
      fpsPreset: json['fpsPreset'] ?? 10,
      frameCount: json['frameCount'] ?? 0,
      videoDuration: (json['videoDuration'] ?? 0.0).toDouble(),
      videoFileUrl: json['videoFileUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      status: _parseStatus(json['status']),
      deviceOrientation: json['deviceOrientation'] ?? 'portrait',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'title': title,
      'fpsPreset': fpsPreset,
      'frameCount': frameCount,
      'videoDuration': videoDuration,
      'videoFileUrl': videoFileUrl,
      'thumbnailUrl': thumbnailUrl,
      'status': status.toString().split('.').last,
      'deviceOrientation': deviceOrientation,
    };
  }

  static ProjectStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return ProjectStatus.draft;
    switch (statusStr) {
      case 'completed':
        return ProjectStatus.completed;
      case 'exported':
        return ProjectStatus.exported;
      default:
        return ProjectStatus.draft;
    }
  }
}
