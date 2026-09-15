/// FFmpeg command builder for video composition
/// Generates FFmpeg commands for combining animation frames with audio

import 'dart:io';

/// Represents a video resolution with pixel dimensions
enum VideoResolution {
  hd720('1280x720', 720),
  fullHd1080('1920x1080', 1080),
  uhd4k('3840x2160', 2160);

  final String dimensions;
  final int height;

  const VideoResolution(this.dimensions, this.height);

  /// Get width from resolution
  int get width => switch (this) {
    VideoResolution.hd720 => 1280,
    VideoResolution.fullHd1080 => 1920,
    VideoResolution.uhd4k => 3840,
  };
}

/// Video output format
enum VideoFormat {
  mp4('mp4', 'H264', 'aac'),
  webm('webm', 'VP9', 'libopus'),
  mov('mov', 'prores', 'aac');

  final String fileExtension;
  final String videoCodec;
  final String audioCodec;

  const VideoFormat(this.fileExtension, this.videoCodec, this.audioCodec);
}

/// FFmpeg command builder for video composition
class FFmpegCommandBuilder {
  final List<String> _command = ['ffmpeg', '-y']; // -y: overwrite output file

  /// Add input image sequence (frames)
  /// [framePattern]: e.g., '/path/frames/frame_%04d.png'
  /// [fps]: frames per second
  void addImageSequenceInput(String framePattern, {int fps = 30}) {
    _command.addAll([
      '-framerate',
      fps.toString(),
      '-i',
      framePattern,
    ]);
  }

  /// Add audio input file
  /// [audioPath]: path to audio file
  void addAudioInput(String audioPath) {
    _command.addAll(['-i', audioPath]);
  }

  /// Add multiple audio inputs (for mixing)
  /// [audioPaths]: list of audio file paths
  void addMultipleAudioInputs(List<String> audioPaths) {
    for (final path in audioPaths) {
      _command.addAll(['-i', path]);
    }
  }

  /// Configure audio filter for mixing multiple tracks
  /// [audioInputCount]: number of audio input streams (excluding video)
  void configureAudioMixing(int audioInputCount) {
    if (audioInputCount <= 1) return; // No mixing needed

    // Build filter string: [0:a][1:a][2:a]... amix=inputs=N:duration=longest[a]
    final inputLabels = List.generate(audioInputCount, (i) => '[${i}:a]').join();
    final filterComplex = '${inputLabels}amix=inputs=$audioInputCount:duration=longest[a]';

    _command.addAll([
      '-filter_complex',
      filterComplex,
    ]);
  }

  /// Set video codec and encoding parameters
  /// [resolution]: output video resolution
  /// [format]: output video format
  /// [bitrate]: video bitrate (e.g., '2000k')
  void setVideoEncoding(
    VideoResolution resolution,
    VideoFormat format, {
    String bitrate = '3000k',
  }) {
    _command.addAll([
      '-c:v',
      format.videoCodec,
      '-b:v',
      bitrate,
      '-s',
      resolution.dimensions,
    ]);
  }

  /// Set audio codec and encoding parameters
  /// [format]: output video format
  /// [bitrate]: audio bitrate (e.g., '128k')
  void setAudioEncoding(
    VideoFormat format, {
    String bitrate = '128k',
  }) {
    _command.addAll([
      '-c:a',
      format.audioCodec,
      '-b:a',
      bitrate,
    ]);
  }

  /// Map video and audio streams
  /// [hasAudio]: whether to include audio
  /// [audioInputCount]: number of audio input streams
  void mapStreams({bool hasAudio = true, int audioInputCount = 1}) {
    _command.addAll(['-map', '0:v:0']); // Map video from first input

    if (hasAudio) {
      if (audioInputCount > 1) {
        _command.addAll(['-map', '[a]']); // Map mixed audio
      } else {
        _command.addAll(['-map', '1:a:0']); // Map audio from second input
      }
    }
  }

  /// Add metadata to output file
  /// [title]: video title
  /// [author]: video author
  void addMetadata({String? title, String? author}) {
    if (title != null) {
      _command.addAll(['-metadata', 'title=$title']);
    }
    if (author != null) {
      _command.addAll(['-metadata', 'artist=$author']);
    }
  }

  /// Set output format and file path
  /// [outputPath]: path to output video file
  /// [format]: video format
  void setOutput(String outputPath, VideoFormat format) {
    _command.addAll([
      '-f',
      format.fileExtension,
      outputPath,
    ]);
  }

  /// Get the complete FFmpeg command as a list
  List<String> build() => List.from(_command);

  /// Get the complete FFmpeg command as a string
  String buildAsString() => _command.join(' ');

  /// Reset the command builder
  void reset() {
    _command.clear();
    _command.addAll(['ffmpeg', '-y']);
  }
}

/// FFmpeg preset configurations for common use cases
class FFmpegPresets {
  /// High-quality MP4 preset
  static FFmpegCommandBuilder highQualityMP4(
    String framePattern,
    String audioPath,
    String outputPath, {
    int fps = 30,
  }) {
    final builder = FFmpegCommandBuilder();
    builder.addImageSequenceInput(framePattern, fps: fps);
    builder.addAudioInput(audioPath);
    builder.setVideoEncoding(VideoResolution.fullHd1080, VideoFormat.mp4, bitrate: '5000k');
    builder.setAudioEncoding(VideoFormat.mp4, bitrate: '192k');
    builder.mapStreams(hasAudio: true, audioInputCount: 1);
    builder.setOutput(outputPath, VideoFormat.mp4);
    return builder;
  }

  /// Standard MP4 preset
  static FFmpegCommandBuilder standardMP4(
    String framePattern,
    String audioPath,
    String outputPath, {
    int fps = 30,
  }) {
    final builder = FFmpegCommandBuilder();
    builder.addImageSequenceInput(framePattern, fps: fps);
    builder.addAudioInput(audioPath);
    builder.setVideoEncoding(VideoResolution.hd720, VideoFormat.mp4, bitrate: '2000k');
    builder.setAudioEncoding(VideoFormat.mp4, bitrate: '128k');
    builder.mapStreams(hasAudio: true, audioInputCount: 1);
    builder.setOutput(outputPath, VideoFormat.mp4);
    return builder;
  }

  /// WebM preset for web delivery
  static FFmpegCommandBuilder webM(
    String framePattern,
    String audioPath,
    String outputPath, {
    int fps = 30,
  }) {
    final builder = FFmpegCommandBuilder();
    builder.addImageSequenceInput(framePattern, fps: fps);
    builder.addAudioInput(audioPath);
    builder.setVideoEncoding(VideoResolution.hd720, VideoFormat.webm, bitrate: '2000k');
    builder.setAudioEncoding(VideoFormat.webm, bitrate: '128k');
    builder.mapStreams(hasAudio: true, audioInputCount: 1);
    builder.setOutput(outputPath, VideoFormat.webm);
    return builder;
  }

  /// Multi-track audio mixing preset
  static FFmpegCommandBuilder multiTrackMP4(
    String framePattern,
    List<String> audioPaths,
    String outputPath, {
    int fps = 30,
  }) {
    final builder = FFmpegCommandBuilder();
    builder.addImageSequenceInput(framePattern, fps: fps);
    builder.addMultipleAudioInputs(audioPaths);
    builder.configureAudioMixing(audioPaths.length);
    builder.setVideoEncoding(VideoResolution.fullHd1080, VideoFormat.mp4, bitrate: '5000k');
    builder.setAudioEncoding(VideoFormat.mp4, bitrate: '192k');
    builder.mapStreams(hasAudio: true, audioInputCount: audioPaths.length);
    builder.setOutput(outputPath, VideoFormat.mp4);
    return builder;
  }
}
