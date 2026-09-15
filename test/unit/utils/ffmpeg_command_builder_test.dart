import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuani/utils/ffmpeg_command_builder.dart';

void main() {
  group('VideoResolution', () {
    test('hd720 has correct dimensions', () {
      expect(VideoResolution.hd720.dimensions, equals('1280x720'));
      expect(VideoResolution.hd720.height, equals(720));
      expect(VideoResolution.hd720.width, equals(1280));
    });

    test('fullHd1080 has correct dimensions', () {
      expect(VideoResolution.fullHd1080.dimensions, equals('1920x1080'));
      expect(VideoResolution.fullHd1080.height, equals(1080));
      expect(VideoResolution.fullHd1080.width, equals(1920));
    });

    test('uhd4k has correct dimensions', () {
      expect(VideoResolution.uhd4k.dimensions, equals('3840x2160'));
      expect(VideoResolution.uhd4k.height, equals(2160));
      expect(VideoResolution.uhd4k.width, equals(3840));
    });
  });

  group('VideoFormat', () {
    test('mp4 has correct codecs', () {
      expect(VideoFormat.mp4.fileExtension, equals('mp4'));
      expect(VideoFormat.mp4.videoCodec, equals('H264'));
      expect(VideoFormat.mp4.audioCodec, equals('aac'));
    });

    test('webm has correct codecs', () {
      expect(VideoFormat.webm.fileExtension, equals('webm'));
      expect(VideoFormat.webm.videoCodec, equals('VP9'));
      expect(VideoFormat.webm.audioCodec, equals('libopus'));
    });

    test('mov has correct codecs', () {
      expect(VideoFormat.mov.fileExtension, equals('mov'));
      expect(VideoFormat.mov.videoCodec, equals('prores'));
      expect(VideoFormat.mov.audioCodec, equals('aac'));
    });
  });

  group('FFmpegCommandBuilder', () {
    late FFmpegCommandBuilder builder;

    setUp(() {
      builder = FFmpegCommandBuilder();
    });

    test('initial command contains ffmpeg and -y flag', () {
      final command = builder.build();
      expect(command, contains('ffmpeg'));
      expect(command, contains('-y'));
    });

    test('addImageSequenceInput adds framerate and input', () {
      builder.addImageSequenceInput('/path/frames/frame_%04d.png', fps: 30);
      final command = builder.build();

      expect(command, contains('-framerate'));
      expect(command, contains('30'));
      expect(command, contains('-i'));
      expect(command, contains('/path/frames/frame_%04d.png'));
    });

    test('addImageSequenceInput uses default fps of 30', () {
      builder.addImageSequenceInput('/path/frames/frame_%04d.png');
      final command = builder.build();

      expect(command, contains('30'));
    });

    test('addAudioInput adds audio file', () {
      builder.addAudioInput('/path/audio.mp3');
      final command = builder.build();

      expect(command, contains('-i'));
      expect(command, contains('/path/audio.mp3'));
    });

    test('addMultipleAudioInputs adds multiple audio files', () {
      builder.addMultipleAudioInputs(
          ['/path/audio1.mp3', '/path/audio2.mp3', '/path/audio3.mp3']);
      final command = builder.build();

      expect(command, contains('/path/audio1.mp3'));
      expect(command, contains('/path/audio2.mp3'));
      expect(command, contains('/path/audio3.mp3'));
    });

    test('configureAudioMixing adds filter_complex for multiple tracks', () {
      builder.addMultipleAudioInputs(['/path/audio1.mp3', '/path/audio2.mp3']);
      builder.configureAudioMixing(2);
      final command = builder.build();

      expect(command, contains('-filter_complex'));
      expect(command, contains('amix'));
      expect(command, contains('inputs=2'));
    });

    test('configureAudioMixing does nothing for single track', () {
      builder.configureAudioMixing(1);
      final command = builder.build();

      expect(command, isNotEmpty);
      expect(command, contains('ffmpeg'));
    });

    test('setVideoEncoding adds codec and bitrate', () {
      builder.setVideoEncoding(
        VideoResolution.fullHd1080,
        VideoFormat.mp4,
        bitrate: '3000k',
      );
      final command = builder.build();

      expect(command, contains('-c:v'));
      expect(command, contains('H264'));
      expect(command, contains('-b:v'));
      expect(command, contains('3000k'));
      expect(command, contains('-s'));
      expect(command, contains('1920x1080'));
    });

    test('setAudioEncoding adds codec and bitrate', () {
      builder.setAudioEncoding(VideoFormat.mp4, bitrate: '128k');
      final command = builder.build();

      expect(command, contains('-c:a'));
      expect(command, contains('aac'));
      expect(command, contains('-b:a'));
      expect(command, contains('128k'));
    });

    test('mapStreams maps video stream', () {
      builder.mapStreams(hasAudio: false);
      final command = builder.build();

      expect(command, contains('-map'));
      expect(command, contains('0:v:0'));
    });

    test('mapStreams maps video and single audio stream', () {
      builder.mapStreams(hasAudio: true, audioInputCount: 1);
      final command = builder.build();

      expect(command, contains('-map'));
      expect(command, contains('0:v:0'));
      expect(command, contains('1:a:0'));
    });

    test('mapStreams maps mixed audio when multiple inputs', () {
      builder.mapStreams(hasAudio: true, audioInputCount: 2);
      final command = builder.build();

      expect(command, contains('-map'));
      expect(command, contains('0:v:0'));
      expect(command, contains('[a]'));
    });

    test('addMetadata adds title metadata', () {
      builder.addMetadata(title: 'Test Video');
      final command = builder.build();

      expect(command, contains('-metadata'));
      expect(command, contains('title=Test Video'));
    });

    test('addMetadata adds author metadata', () {
      builder.addMetadata(author: 'Test Author');
      final command = builder.build();

      expect(command, contains('-metadata'));
      expect(command, contains('artist=Test Author'));
    });

    test('addMetadata adds both title and author', () {
      builder.addMetadata(title: 'Test Video', author: 'Test Author');
      final command = builder.build();

      expect(command, contains('title=Test Video'));
      expect(command, contains('artist=Test Author'));
    });

    test('setOutput adds format and output path', () {
      builder.setOutput('/output/video.mp4', VideoFormat.mp4);
      final command = builder.build();

      expect(command, contains('-f'));
      expect(command, contains('mp4'));
      expect(command, contains('/output/video.mp4'));
    });

    test('buildAsString returns space-separated command', () {
      builder.addImageSequenceInput('/path/frames/frame_%04d.png', fps: 30);
      builder.addAudioInput('/path/audio.mp3');
      builder.setOutput('/output/video.mp4', VideoFormat.mp4);

      final commandString = builder.buildAsString();

      expect(commandString, isA<String>());
      expect(commandString, contains('ffmpeg'));
      expect(commandString, contains('/path/frames/frame_%04d.png'));
      expect(commandString, contains('/path/audio.mp3'));
      expect(commandString, contains('/output/video.mp4'));
    });

    test('reset clears all commands', () {
      builder.addImageSequenceInput('/path/frames/frame_%04d.png');
      builder.reset();

      final command = builder.build();
      expect(command, equals(['ffmpeg', '-y']));
    });

    test('complete mp4 command builds correctly', () {
      builder.addImageSequenceInput('/path/frames/frame_%04d.png', fps: 30);
      builder.addAudioInput('/path/audio.mp3');
      builder.setVideoEncoding(VideoResolution.fullHd1080, VideoFormat.mp4);
      builder.setAudioEncoding(VideoFormat.mp4);
      builder.mapStreams(hasAudio: true, audioInputCount: 1);
      builder.setOutput('/output/video.mp4', VideoFormat.mp4);

      final command = builder.build();

      expect(command.length, greaterThan(0);
      expect(command.first, equals('ffmpeg'));
      expect(command, contains('-framerate'));
      expect(command, contains('-i'));
      expect(command, contains('-c:v'));
      expect(command, contains('-c:a'));
      expect(command, contains('-map'));
      expect(command, contains('-f'));
      expect(command, contains('/output/video.mp4'));
    });
  });

  group('FFmpegPresets', () {
    test('highQualityMP4 creates correct builder', () {
      final builder = FFmpegPresets.highQualityMP4(
        '/path/frames/frame_%04d.png',
        '/path/audio.mp3',
        '/output/video.mp4',
        fps: 30,
      );

      final command = builder.build();
      expect(command, contains('5000k')); // High quality bitrate
      expect(command, contains('192k')); // High quality audio
      expect(command, contains('1920x1080')); // Full HD
    });

    test('standardMP4 creates correct builder', () {
      final builder = FFmpegPresets.standardMP4(
        '/path/frames/frame_%04d.png',
        '/path/audio.mp3',
        '/output/video.mp4',
        fps: 30,
      );

      final command = builder.build();
      expect(command, contains('2000k')); // Standard bitrate
      expect(command, contains('128k')); // Standard audio
      expect(command, contains('1280x720')); // HD
    });

    test('webM creates correct builder', () {
      final builder = FFmpegPresets.webM(
        '/path/frames/frame_%04d.png',
        '/path/audio.mp3',
        '/output/video.webm',
        fps: 30,
      );

      final command = builder.build();
      expect(command, contains('VP9'));
      expect(command, contains('libopus'));
      expect(command, contains('webm'));
    });

    test('multiTrackMP4 creates correct builder', () {
      final builder = FFmpegPresets.multiTrackMP4(
        '/path/frames/frame_%04d.png',
        ['/path/audio1.mp3', '/path/audio2.mp3'],
        '/output/video.mp4',
        fps: 30,
      );

      final command = builder.build();
      expect(command, contains('amix'));
      expect(command, contains('inputs=2'));
      expect(command, contains('5000k')); // High quality
    });
  });
}
