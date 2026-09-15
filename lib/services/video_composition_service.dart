/// Video composition service for combining animation frames with audio

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../models/video_composition.dart';
import '../utils/audio_mixing_utils.dart';
import '../utils/ffmpeg_command_builder.dart';

/// Exception thrown during video composition
class VideoCompositionException implements Exception {
  final String message;
  final String? code;

  VideoCompositionException(this.message, {this.code});

  @override
  String toString() => 'VideoCompositionException: $message';
}

/// Service for composing videos from frames and audio
class VideoCompositionService {
  static final VideoCompositionService _instance = VideoCompositionService._internal();

  /// Stream for composition progress updates
  final StreamController<CompositionProgress> _progressController =
      StreamController<CompositionProgress>.broadcast();

  /// Stream for composition status updates
  final StreamController<CompositionStatus> _statusController =
      StreamController<CompositionStatus>.broadcast();

  /// Current composition task process
  Process? _currentProcess;

  /// Cancel token for stopping composition
  bool _isCancelled = false;

  VideoCompositionService._internal();

  /// Get singleton instance
  factory VideoCompositionService() {
    return _instance;
  }

  /// Progress stream
  Stream<CompositionProgress> get progressStream => _progressController.stream;

  /// Status stream
  Stream<CompositionStatus> get statusStream => _statusController.stream;

  /// Check if composition is in progress
  bool get isComposing => _currentProcess != null;

  /// Compose video from frames and audio
  /// [framePattern]: Pattern for frame files (e.g., '/path/frames/frame_%04d.png')
  /// [audioPath]: Path to audio file
  /// [outputPath]: Path where output video will be saved
  /// [settings]: Composition settings
  /// Returns the completed VideoComposition
  Future<VideoComposition> composeVideo({
    required String framePattern,
    required String audioPath,
    required String outputPath,
    required CompositionSettings settings,
    required String projectId,
    int? totalFrames,
  }) async {
    if (isComposing) {
      throw VideoCompositionException('Composition already in progress');
    }

    _isCancelled = false;
    _statusController.add(CompositionStatus.processing);

    try {
      // Validate inputs
      _validateInputs(framePattern, audioPath, settings);

      // Build FFmpeg command
      final command = _buildFFmpegCommand(
        framePattern: framePattern,
        audioPath: audioPath,
        outputPath: outputPath,
        settings: settings,
      );

      // Run FFmpeg
      await _runFFmpeg(command, totalFrames ?? 0);

      // Verify output file
      final outputFile = File(outputPath);
      if (!outputFile.existsSync()) {
        throw VideoCompositionException('Output file was not created');
      }

      // Get file size
      final fileSizeMB = outputFile.lengthSync() / (1024 * 1024);

      // Create composition result
      final composition = VideoComposition(
        id: _generateId(),
        projectId: projectId,
        outputPath: outputPath,
        format: settings.format,
        resolution: settings.resolution,
        fps: settings.fps,
        fileSizeMB: fileSizeMB,
        createdAt: DateTime.now(),
        status: CompositionStatus.completed,
      );

      _statusController.add(CompositionStatus.completed);
      return composition;
    } catch (e) {
      _statusController.add(CompositionStatus.failed);
      rethrow;
    } finally {
      _currentProcess = null;
    }
  }

  /// Compose video with multiple audio tracks
  /// [framePattern]: Pattern for frame files
  /// [audioPaths]: List of audio file paths to mix
  /// [outputPath]: Path where output video will be saved
  /// [settings]: Composition settings
  Future<VideoComposition> composeVideoWithAudio({
    required String framePattern,
    required List<String> audioPaths,
    required String outputPath,
    required CompositionSettings settings,
    required String projectId,
    int? totalFrames,
    List<double>? trackVolumes,
  }) async {
    if (isComposing) {
      throw VideoCompositionException('Composition already in progress');
    }

    if (audioPaths.isEmpty) {
      throw VideoCompositionException('At least one audio track is required');
    }

    _isCancelled = false;
    _statusController.add(CompositionStatus.processing);

    try {
      // Validate inputs
      _validateInputs(framePattern, audioPaths.first, settings);

      // Build FFmpeg command for multi-track composition
      final command = _buildMultiTrackFFmpegCommand(
        framePattern: framePattern,
        audioPaths: audioPaths,
        outputPath: outputPath,
        settings: settings,
        trackVolumes: trackVolumes,
      );

      // Run FFmpeg
      await _runFFmpeg(command, totalFrames ?? 0);

      // Verify output file
      final outputFile = File(outputPath);
      if (!outputFile.existsSync()) {
        throw VideoCompositionException('Output file was not created');
      }

      // Get file size
      final fileSizeMB = outputFile.lengthSync() / (1024 * 1024);

      // Create composition result
      final composition = VideoComposition(
        id: _generateId(),
        projectId: projectId,
        outputPath: outputPath,
        format: settings.format,
        resolution: settings.resolution,
        fps: settings.fps,
        fileSizeMB: fileSizeMB,
        createdAt: DateTime.now(),
        status: CompositionStatus.completed,
      );

      _statusController.add(CompositionStatus.completed);
      return composition;
    } catch (e) {
      _statusController.add(CompositionStatus.failed);
      rethrow;
    } finally {
      _currentProcess = null;
    }
  }

  /// Cancel ongoing composition
  Future<void> cancel() async {
    _isCancelled = true;
    if (_currentProcess != null && !_currentProcess!.kill()) {
      throw VideoCompositionException('Failed to cancel composition');
    }
    _currentProcess = null;
  }

  /// Validate composition inputs
  void _validateInputs(
    String framePattern,
    String audioPath,
    CompositionSettings settings,
  ) {
    if (framePattern.isEmpty) {
      throw VideoCompositionException('Frame pattern cannot be empty');
    }

    final audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      throw VideoCompositionException('Audio file does not exist: $audioPath');
    }

    if (!settings.isValid) {
      throw VideoCompositionException('Invalid composition settings');
    }
  }

  /// Build FFmpeg command for single audio track
  String _buildFFmpegCommand({
    required String framePattern,
    required String audioPath,
    required String outputPath,
    required CompositionSettings settings,
  }) {
    final builder = FFmpegCommandBuilder();

    builder.addImageSequenceInput(framePattern, fps: settings.fps);
    builder.addAudioInput(audioPath);

    // Parse resolution to enum
    final resolution = _parseResolution(settings.resolution);

    builder.setVideoEncoding(
      resolution,
      _parseFormat(settings.format),
      bitrate: settings.videoBitrate,
    );

    builder.setAudioEncoding(
      _parseFormat(settings.format),
      bitrate: settings.audioBitrate,
    );

    builder.mapStreams(hasAudio: true, audioInputCount: 1);

    if (settings.videoTitle != null) {
      builder.addMetadata(title: settings.videoTitle);
    }

    builder.setOutput(outputPath, _parseFormat(settings.format));

    return builder.buildAsString();
  }

  /// Build FFmpeg command for multiple audio tracks
  String _buildMultiTrackFFmpegCommand({
    required String framePattern,
    required List<String> audioPaths,
    required String outputPath,
    required CompositionSettings settings,
    List<double>? trackVolumes,
  }) {
    final builder = FFmpegCommandBuilder();

    builder.addImageSequenceInput(framePattern, fps: settings.fps);
    builder.addMultipleAudioInputs(audioPaths);

    // Configure audio mixing
    builder.configureAudioMixing(audioPaths.length);

    // Parse resolution to enum
    final resolution = _parseResolution(settings.resolution);

    builder.setVideoEncoding(
      resolution,
      _parseFormat(settings.format),
      bitrate: settings.videoBitrate,
    );

    builder.setAudioEncoding(
      _parseFormat(settings.format),
      bitrate: settings.audioBitrate,
    );

    builder.mapStreams(hasAudio: true, audioInputCount: audioPaths.length);

    if (settings.videoTitle != null) {
      builder.addMetadata(title: settings.videoTitle);
    }

    builder.setOutput(outputPath, _parseFormat(settings.format));

    return builder.buildAsString();
  }

  /// Run FFmpeg process
  Future<void> _runFFmpeg(String command, int totalFrames) async {
    try {
      final parts = command.split(' ');
      final executable = parts.first;
      final args = parts.sublist(1);

      _currentProcess = await Process.start(executable, args);

      // Monitor process output
      int processedFrames = 0;
      int startTime = DateTime.now().millisecondsSinceEpoch;

      // Read stdout
      _currentProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (_isCancelled) return;

        // Parse frame number from FFmpeg output
        // FFmpeg outputs: "frame=  123"
        if (line.contains('frame=')) {
          final match = RegExp(r'frame=\s*(\d+)').firstMatch(line);
          if (match != null) {
            processedFrames = int.parse(match.group(1)!);
            final now = DateTime.now().millisecondsSinceEpoch;

            final progress = CompositionProgress.fromFrames(
              processedFrames,
              totalFrames,
              startTime ~/ 1000,
              now ~/ 1000,
            );

            _progressController.add(progress);
          }
        }
      });

      // Wait for process to complete
      final exitCode = await _currentProcess!.exitCode;

      if (_isCancelled) {
        throw VideoCompositionException('Composition cancelled by user');
      }

      if (exitCode != 0) {
        throw VideoCompositionException(
          'FFmpeg process failed with exit code: $exitCode',
        );
      }
    } catch (e) {
      throw VideoCompositionException(
        'Failed to run FFmpeg: $e',
      );
    }
  }

  /// Parse resolution string to enum
  VideoResolution _parseResolution(String resolution) {
    return switch (resolution.toLowerCase()) {
      '720p' => VideoResolution.hd720,
      '1080p' => VideoResolution.fullHd1080,
      '4k' => VideoResolution.uhd4k,
      _ => VideoResolution.fullHd1080,
    };
  }

  /// Parse format string to enum
  VideoFormat _parseFormat(String format) {
    return switch (format.toLowerCase()) {
      'mp4' => VideoFormat.mp4,
      'webm' => VideoFormat.webm,
      'mov' => VideoFormat.mov,
      _ => VideoFormat.mp4,
    };
  }

  /// Generate unique ID
  String _generateId() {
    return 'comp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _progressController.close();
    await _statusController.close();
    await cancel();
  }
}

