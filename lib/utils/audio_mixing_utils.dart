/// Audio mixing utilities for combining multiple audio tracks

/// Represents audio mixing parameters
class AudioMixingConfig {
  /// Individual track volumes (0.0 to 1.0)
  final List<double> trackVolumes;

  /// Overall output volume (0.0 to 1.0)
  final double outputVolume;

  /// Whether to normalize output to prevent clipping
  final bool normalize;

  /// Sample rate for output (44100 or 48000 Hz)
  final int sampleRate;

  AudioMixingConfig({
    List<double>? trackVolumes,
    this.outputVolume = 1.0,
    this.normalize = true,
    this.sampleRate = 48000,
  }) : trackVolumes = trackVolumes ?? [];

  /// Validate mixing configuration
  bool get isValid {
    // All track volumes must be between 0 and 1
    return trackVolumes.every((v) => v >= 0.0 && v <= 1.0) &&
        outputVolume >= 0.0 &&
        outputVolume <= 1.0 &&
        (sampleRate == 44100 || sampleRate == 48000);
  }

  /// Get FFmpeg audio filter string for mixing
  /// [trackCount]: number of audio tracks to mix
  String getFilterString(int trackCount) {
    if (trackCount == 0) {
      return '';
    }

    if (trackCount == 1) {
      // Single track: just apply volume
      final volume = trackVolumes.isNotEmpty ? trackVolumes[0] : 1.0;
      return '[0:a]volume=$volume[a]';
    }

    // Multiple tracks: build amix filter
    final inputLabels = List.generate(trackCount, (i) => '[${i}:a]').join();
    var filterString = '${inputLabels}amix=inputs=$trackCount:duration=longest[mixed]';

    // Add individual track volumes if specified
    if (trackVolumes.isNotEmpty && trackVolumes.length == trackCount) {
      final volumeFilters = List.generate(
        trackCount,
        (i) => '[${i}:a]volume=${trackVolumes[i]}[vol$i]',
      ).join(';');

      final volLabels = List.generate(trackCount, (i) => '[vol$i]').join();
      filterString = '$volumeFilters;${volLabels}amix=inputs=$trackCount:duration=longest[mixed]';
    }

    // Apply output volume if not at 1.0
    if (outputVolume != 1.0) {
      filterString += ';[mixed]volume=${outputVolume}[a]';
    } else {
      // Rename mixed output to standard audio label
      filterString = filterString.replaceAll('[mixed]', '[a]');
    }

    return filterString;
  }

  /// Calculate peak amplitude for normalization
  /// Returns scaling factor to prevent clipping
  double calculateNormalizationFactor() {
    double peakVolume = 0.0;
    for (final volume in trackVolumes) {
      peakVolume += volume;
    }
    peakVolume *= outputVolume;

    // If peak is above 1.0, return scale factor
    return peakVolume > 1.0 ? 1.0 / peakVolume : 1.0;
  }

  @override
  String toString() =>
      'AudioMixingConfig(tracks: ${trackVolumes.length}, output: $outputVolume, sampleRate: $sampleRate)';
}

/// Audio track information for mixing
class AudioTrackInfo {
  /// Unique identifier for the track
  final String id;

  /// Track name/label
  final String name;

  /// File path to audio file
  final String filePath;

  /// Volume level (0.0 to 1.0)
  final double volume;

  /// Whether track is muted
  final bool isMuted;

  /// Start time offset in milliseconds
  final int startMs;

  /// Duration in milliseconds
  final int durationMs;

  AudioTrackInfo({
    required this.id,
    required this.name,
    required this.filePath,
    this.volume = 1.0,
    this.isMuted = false,
    this.startMs = 0,
    this.durationMs = 0,
  });

  /// Get effective volume (considering mute state)
  double get effectiveVolume => isMuted ? 0.0 : volume;

  /// Check if track is valid
  bool get isValid => id.isNotEmpty && filePath.isNotEmpty;

  @override
  String toString() => 'AudioTrackInfo($id, $name, volume: $volume, muted: $isMuted)';
}

/// Audio mixing utilities
class AudioMixingUtils {
  /// Generate FFmpeg audio filter chain for multiple tracks
  static String generateAudioFilterChain(
    List<AudioTrackInfo> tracks, {
    double outputVolume = 1.0,
    bool normalize = true,
  }) {
    if (tracks.isEmpty) {
      return '';
    }

    if (tracks.length == 1) {
      final track = tracks.first;
      final effectiveVolume = track.effectiveVolume;
      return '[0:a]volume=$effectiveVolume[a]';
    }

    // Build volume adjustments for each track
    var filterParts = <String>[];
    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      final volume = track.effectiveVolume;
      if (volume != 1.0) {
        filterParts.add('[${i}:a]volume=$volume[vol$i]');
      }
    }

    // Build input labels for mix (use volume-adjusted or original)
    final inputLabels = <String>[];
    for (int i = 0; i < tracks.length; i++) {
      if (tracks[i].effectiveVolume != 1.0) {
        inputLabels.add('[vol$i]');
      } else {
        inputLabels.add('[${i}:a]');
      }
    }

    // Add mix filter
    filterParts.add(
      '${inputLabels.join()}amix=inputs=${tracks.length}:duration=longest[mixed]',
    );

    // Apply output volume if needed
    if (outputVolume != 1.0) {
      filterParts.add('[mixed]volume=$outputVolume[a]');
    } else {
      filterParts.add('[mixed]aformat=sample_rates=48000[a]');
    }

    return filterParts.join(';');
  }

  /// Calculate total duration from multiple audio tracks
  static int calculateTotalDuration(List<AudioTrackInfo> tracks) {
    int maxEndTime = 0;
    for (final track in tracks) {
      final endTime = track.startMs + track.durationMs;
      if (endTime > maxEndTime) {
        maxEndTime = endTime;
      }
    }
    return maxEndTime;
  }

  /// Check if audio tracks overlap
  static bool hasOverlappingTracks(List<AudioTrackInfo> tracks) {
    for (int i = 0; i < tracks.length; i++) {
      for (int j = i + 1; j < tracks.length; j++) {
        final track1 = tracks[i];
        final track2 = tracks[j];

        final end1 = track1.startMs + track1.durationMs;
        final end2 = track2.startMs + track2.durationMs;

        // Check for overlap
        if (track1.startMs < end2 && track2.startMs < end1) {
          return true;
        }
      }
    }
    return false;
  }

  /// Validate audio mixing configuration
  static String? validateTracks(List<AudioTrackInfo> tracks) {
    if (tracks.isEmpty) {
      return 'At least one audio track is required';
    }

    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      if (!track.isValid) {
        return 'Track $i is invalid: missing id or file path';
      }
      if (track.volume < 0.0 || track.volume > 1.0) {
        return 'Track $i: volume must be between 0.0 and 1.0';
      }
    }

    return null; // No errors
  }

  /// Calculate preview volume for mixing
  /// Returns a reasonable level that won't cause clipping
  static double calculateSafeVolume(List<AudioTrackInfo> tracks) {
    double combinedVolume = 0.0;
    for (final track in tracks) {
      if (!track.isMuted) {
        combinedVolume += track.volume;
      }
    }

    // If combined volume exceeds 1.0, scale down to prevent clipping
    if (combinedVolume > 1.0) {
      return 1.0 / combinedVolume;
    }

    return 1.0;
  }

  /// Get recommended bitrate for mixed audio based on track count
  static String getRecommendedBitrate(int trackCount) {
    return switch (trackCount) {
      0 => '0k',
      1 => '128k',
      2 => '160k',
      3 => '192k',
      _ => '256k',
    };
  }
}
