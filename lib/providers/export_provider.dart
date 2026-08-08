import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/video_service.dart';

final exportStateProvider = StateNotifierProvider<ExportStateNotifier, ExportState>((ref) {
  return ExportStateNotifier();
});

final exportResolutionProvider =
    StateProvider<VideoResolution>((ref) => VideoResolution.resolution720p);

enum ExportStatus { idle, processing, completed, failed }

class ExportState {
  final ExportStatus status;
  final int progressPercentage;
  final String? errorMessage;
  final String? outputFilePath;

  ExportState({
    this.status = ExportStatus.idle,
    this.progressPercentage = 0,
    this.errorMessage,
    this.outputFilePath,
  });

  ExportState copyWith({
    ExportStatus? status,
    int? progressPercentage,
    String? errorMessage,
    String? outputFilePath,
  }) {
    return ExportState(
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      errorMessage: errorMessage ?? this.errorMessage,
      outputFilePath: outputFilePath ?? this.outputFilePath,
    );
  }
}

class ExportStateNotifier extends StateNotifier<ExportState> {
  ExportStateNotifier() : super(ExportState());

  void startExport() {
    state = state.copyWith(
      status: ExportStatus.processing,
      progressPercentage: 0,
      errorMessage: null,
      outputFilePath: null,
    );
  }

  void updateProgress(int percentage) {
    if (percentage >= 0 && percentage <= 100) {
      state = state.copyWith(progressPercentage: percentage);
    }
  }

  void completeExport(String outputPath) {
    state = state.copyWith(
      status: ExportStatus.completed,
      progressPercentage: 100,
      outputFilePath: outputPath,
    );
  }

  void failExport(String errorMessage) {
    state = state.copyWith(
      status: ExportStatus.failed,
      errorMessage: errorMessage,
      progressPercentage: 0,
    );
  }

  void reset() {
    state = ExportState();
  }
}
