import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import '../utils/logger.dart';

enum VideoResolution { resolution720p, resolution1080p }

class VideoService {
  static final VideoService _instance = VideoService._internal();

  factory VideoService() {
    return _instance;
  }

  VideoService._internal();

  Future<String> get _projectsDir async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${appDocDir.path}/projects');
    if (!projectsDir.existsSync()) {
      projectsDir.createSync(recursive: true);
    }
    return projectsDir.path;
  }

  Future<String> getProjectDir(String projectId) async {
    final baseDir = await _projectsDir;
    final projectDir = Directory('$baseDir/$projectId');
    if (!projectDir.existsSync()) {
      projectDir.createSync(recursive: true);
    }
    return projectDir.path;
  }

  Future<String> getFramesDir(String projectId) async {
    final projectDir = await getProjectDir(projectId);
    final framesDir = Directory('$projectDir/frames');
    if (!framesDir.existsSync()) {
      framesDir.createSync(recursive: true);
    }
    return framesDir.path;
  }

  // Path for the user-recorded voiceover narration track.
  Future<String> getVoiceoverPath(String projectId) async {
    final projectDir = await getProjectDir(projectId);
    return '$projectDir/voiceover.m4a';
  }

  // Saves PNG bytes as a frame file.
  Future<String> saveFrameImage(
    String projectId,
    int frameIndex,
    List<int> imageBytes,
  ) async {
    try {
      final framesDir = await getFramesDir(projectId);
      final framePath = '$framesDir/frame_$frameIndex.png';
      final file = File(framePath);
      await file.writeAsBytes(imageBytes);
      return framePath;
    } catch (e) {
      AppLogger.error('Error saving frame image', e);
      rethrow;
    }
  }

  Future<File?> createVideoFromFrames({
    required String projectId,
    required int fps,
    required VideoResolution resolution,
    required Function(int percentage) onProgress,
    String? audioPath,
    String outputFileName = 'video.mp4',
  }) async {
    try {
      final framesDir = await getFramesDir(projectId);
      final projectDir = await getProjectDir(projectId);

      // Get resolution dimensions
      final (width, height) = _getResolutionDimensions(resolution);

      final hasAudio = audioPath != null && File(audioPath).existsSync();
      // Render the silent video to a temp path when audio needs muxing
      // afterward, otherwise write straight to the final output path.
      final outputPath = '$projectDir/$outputFileName';
      final silentPath =
          hasAudio ? '$projectDir/${outputFileName}_silent.mp4' : outputPath;

      // FFmpeg command to create video from image sequence
      // Input: frame_0.jpg, frame_1.jpg, etc.
      // Output: video.mp4
      final command = [
        '-framerate',
        fps.toString(),
        '-i',
        '$framesDir/frame_%d.png',
        '-c:v',
        'libx264',
        '-pix_fmt',
        'yuv420p',
        '-vf',
        'scale=$width:$height',
        silentPath,
      ];

      // Execute FFmpeg
      final session = await FFmpegKit.executeWithArguments(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final failStackTrace = await session.getFailStackTrace();
        AppLogger.error('FFmpeg error', failStackTrace);
        onProgress(0);
        return null;
      }

      if (!hasAudio) {
        onProgress(100);
        return File(outputPath);
      }

      onProgress(70);
      final muxed = await _muxAudioIntoVideo(silentPath, audioPath, outputPath);
      onProgress(muxed ? 100 : 0);
      return muxed ? File(outputPath) : null;
    } catch (e) {
      AppLogger.error('Error creating video', e);
      onProgress(0);
      rethrow;
    }
  }

  // Renders the same frames at half the original speed so the frame-by-frame
  // creation process reads clearly, as a shareable "behind the scenes" cut.
  Future<File?> createMakingOfVideo({
    required String projectId,
    required int originalFps,
    required Function(int percentage) onProgress,
  }) async {
    final makingOfFps = (originalFps / 2).round().clamp(2, 30);
    return createVideoFromFrames(
      projectId: projectId,
      fps: makingOfFps,
      resolution: VideoResolution.resolution720p,
      onProgress: onProgress,
      outputFileName: 'making_of.mp4',
    );
  }

  // Merges [audioPath] into [silentVideoPath] and writes the result to
  // [outputPath]. Video is copied without re-encoding; audio track is
  // trimmed/padded to the video length via -shortest.
  Future<bool> _muxAudioIntoVideo(
    String silentVideoPath,
    String audioPath,
    String outputPath,
  ) async {
    final command = [
      '-i',
      silentVideoPath,
      '-i',
      audioPath,
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      '-shortest',
      '-y',
      outputPath,
    ];

    final session = await FFmpegKit.executeWithArguments(command);
    final returnCode = await session.getReturnCode();

    final silentFile = File(silentVideoPath);
    if (silentFile.existsSync()) {
      await silentFile.delete();
    }

    if (ReturnCode.isSuccess(returnCode)) {
      return true;
    }

    final failStackTrace = await session.getFailStackTrace();
    AppLogger.error('FFmpeg audio mux error', failStackTrace);
    return false;
  }

  (int, int) _getResolutionDimensions(VideoResolution resolution) {
    switch (resolution) {
      case VideoResolution.resolution720p:
        return (1280, 720);
      case VideoResolution.resolution1080p:
        return (1920, 1080);
    }
  }

  // Deletes frame at [index] and shifts subsequent frames down to keep
  // the frame_N.png naming contiguous with no gaps.
  Future<void> deleteFrame(String projectId, int index, int totalCount) async {
    final framesDir = await getFramesDir(projectId);

    final target = File('$framesDir/frame_$index.png');
    if (target.existsSync()) {
      await target.delete();
    }

    for (int i = index + 1; i < totalCount; i++) {
      final src = File('$framesDir/frame_$i.png');
      if (src.existsSync()) {
        await src.rename('$framesDir/frame_${i - 1}.png');
      }
    }
  }

  // Moves the frame at [oldIndex] to [newIndex], shifting the frames
  // in between. Uses temp filenames to avoid overwrite collisions.
  Future<void> reorderFrame(
    String projectId,
    int oldIndex,
    int newIndex,
    int totalCount,
  ) async {
    if (oldIndex == newIndex) return;
    final framesDir = await getFramesDir(projectId);

    final tempPaths = <String>[];
    for (int i = 0; i < totalCount; i++) {
      final original = File('$framesDir/frame_$i.png');
      final tempPath = '$framesDir/temp_frame_$i.png';
      if (original.existsSync()) {
        await original.rename(tempPath);
      }
      tempPaths.add(tempPath);
    }

    final reordered = [...tempPaths];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    for (int i = 0; i < reordered.length; i++) {
      final tempFile = File(reordered[i]);
      if (tempFile.existsSync()) {
        await tempFile.rename('$framesDir/frame_$i.png');
      }
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final projectDir = await getProjectDir(projectId);
      final dir = Directory(projectDir);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      AppLogger.error('Error deleting project', e);
    }
  }

  Future<int> getProjectStorageSize(String projectId) async {
    try {
      final projectDir = await getProjectDir(projectId);
      final dir = Directory(projectDir);

      if (!dir.existsSync()) return 0;

      int size = 0;
      final files = dir.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          size += await file.length();
        }
      }
      return size;
    } catch (e) {
      AppLogger.error('Error calculating storage size', e);
      return 0;
    }
  }

  Future<String> getProjectVideoPath(String projectId) async {
    final projectDir = await getProjectDir(projectId);
    return '$projectDir/video.mp4';
  }
}
