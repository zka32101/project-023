import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/video_service.dart';
import 'camera_provider.dart';

/// Returns ordered list of on-disk frame PNG paths for the given project.
/// Rebuilds whenever frameCount changes (e.g. after shooting another frame).
final framePathsProvider =
    FutureProvider.family<List<String>, String>((ref, projectId) async {
  final frameCount = ref.watch(cameraStateProvider).frameCount;
  if (frameCount == 0) return [];

  final framesDir = await VideoService().getFramesDir(projectId);
  final paths = <String>[];
  for (int i = 0; i < frameCount; i++) {
    final path = '$framesDir/frame_$i.png';
    if (File(path).existsSync()) {
      paths.add(path);
    }
  }
  return paths;
});
