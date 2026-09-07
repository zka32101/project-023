import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dubbing_project.dart';
import '../models/audio_track.dart';
import '../utils/logger.dart';

/// ダビングプロジェクト管理プロバイダー
final dubbingProjectProvider =
    StateNotifierProvider<DubbingProjectNotifier, List<DubbingProject>>((ref) {
  return DubbingProjectNotifier();
});

/// ダビングプロジェクト状態管理クラス
class DubbingProjectNotifier extends StateNotifier<List<DubbingProject>> {
  static const String _storageDirName = 'dubbing_projects';
  static const String _projectsFileName = 'projects.json';

  DubbingProjectNotifier() : super([]) {
    _loadProjects();
  }

  /// プロジェクト一覧を読み込む
  Future<void> _loadProjects() async {
    try {
      final projectsFile = await _getProjectsFile();
      if (!projectsFile.existsSync()) {
        state = [];
        return;
      }

      final jsonString = await projectsFile.readAsString();
      final jsonList = json.decode(jsonString) as List<dynamic>;
      final projects = jsonList
          .map((item) => DubbingProject.fromJson(item as Map<String, dynamic>))
          .toList();

      state = projects;
    } catch (e) {
      AppLogger.error('Failed to load dubbing projects', e);
      state = [];
    }
  }

  /// プロジェクトを保存
  Future<void> persistState() async {
    try {
      final projectsFile = await _getProjectsFile();
      final jsonString = json.encode(state.map((p) => p.toJson()).toList());
      await projectsFile.writeAsString(jsonString);
    } catch (e) {
      AppLogger.error('Failed to save dubbing projects', e);
      rethrow;
    }
  }

  /// 新規プロジェクトを作成
  Future<DubbingProject> createProject({
    required String characterId,
    required String projectName,
    required int fps,
    required int totalFrames,
  }) async {
    final project = DubbingProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      characterId: characterId,
      projectName: projectName,
      tracks: [],
      fps: fps,
      totalFrames: totalFrames,
      createdAt: DateTime.now(),
    );

    state = [...state, project];
    await persistState();
    return project;
  }

  /// プロジェクトを削除
  Future<void> deleteProject(String projectId) async {
    state = state.where((p) => p.id != projectId).toList();
    await persistState();
  }

  /// プロジェクトを更新
  Future<void> updateProject(DubbingProject project) async {
    final index = state.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      final newList = List<DubbingProject>.from(state);
      newList[index] = project;
      state = newList;
      await persistState();
    }
  }

  /// トラックを追加
  Future<void> addTrackToProject(
    String projectId,
    AudioTrack track,
  ) async {
    final index = state.indexWhere((p) => p.id == projectId);
    if (index >= 0) {
      final project = state[index];
      final updatedProject = project.copyWith(
        tracks: [...project.tracks, track],
      );
      await updateProject(updatedProject);
    }
  }

  /// トラックを削除
  Future<void> removeTrackFromProject(
    String projectId,
    String trackId,
  ) async {
    final index = state.indexWhere((p) => p.id == projectId);
    if (index >= 0) {
      final project = state[index];
      final updatedProject = project.copyWith(
        tracks: project.tracks.where((t) => t.id != trackId).toList(),
      );
      await updateProject(updatedProject);
    }
  }

  /// トラックを更新
  Future<void> updateTrackInProject(
    String projectId,
    AudioTrack track,
  ) async {
    final index = state.indexWhere((p) => p.id == projectId);
    if (index >= 0) {
      final project = state[index];
      final trackIndex = project.tracks.indexWhere((t) => t.id == track.id);
      if (trackIndex >= 0) {
        final updatedTracks = List<AudioTrack>.from(project.tracks);
        updatedTracks[trackIndex] = track;
        final updatedProject = project.copyWith(tracks: updatedTracks);
        await updateProject(updatedProject);
      }
    }
  }

  /// キャラクターIDに基づくプロジェクト一覧を取得
  List<DubbingProject> getProjectsByCharacterId(String characterId) {
    return state.where((p) => p.characterId == characterId).toList();
  }

  /// プロジェクトファイルを取得
  Future<File> _getProjectsFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${docsDir.path}/$_storageDirName');
    if (!projectDir.existsSync()) {
      projectDir.createSync(recursive: true);
    }
    return File('${projectDir.path}/$_projectsFileName');
  }
}
