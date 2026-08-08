import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/timeline_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/frame_provider.dart';
import '../services/video_service.dart';
import '../widgets/page_transition.dart';
import 'export_screen.dart';

class TimelineScreen extends ConsumerWidget {
  final String projectId;

  const TimelineScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineStateProvider);
    final cameraState = ref.watch(cameraStateProvider);
    final framePathsAsync = ref.watch(framePathsProvider(projectId));
    final frameCount = cameraState.frameCount;
    final fps = cameraState.fpsPreset;
    final duration = frameCount > 0 ? frameCount / fps : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$frameCount フレーム · ${duration.toStringAsFixed(2)}秒',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: TextButton(
              onPressed: frameCount > 0
                  ? () => _goToExport(context, ref)
                  : null,
              child: Text(
                '書き出し →',
                style: TextStyle(
                  color: frameCount > 0 ? AppColors.accent : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact preview area
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
            child: Row(
              children: [
                // Mini preview box
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                  child: Container(
                    width: 80,
                    height: 56,
                    color: Colors.grey[850],
                    child: framePathsAsync.when(
                      data: (paths) => paths.isNotEmpty
                          ? Image.file(
                              File(paths.first),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.movie,
                                      color: Colors.white38),
                            )
                          : const Icon(Icons.movie,
                              color: Colors.white38, size: 28),
                      loading: () => const SizedBox(),
                      error: (_, __) => const Icon(Icons.error,
                          color: Colors.red, size: 20),
                    ),
                  ),
                ),

                const SizedBox(width: AppSizes.md),

                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$frameCount 枚 · $fps fps',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '合計 ${duration.toStringAsFixed(2)} 秒',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Play button
                IconButton(
                  icon: Icon(
                    timelineState.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: AppColors.accent,
                    size: 36,
                  ),
                  onPressed: () {
                    if (timelineState.isPlaying) {
                      ref
                          .read(timelineStateProvider.notifier)
                          .stopPlaying();
                    } else {
                      ref
                          .read(timelineStateProvider.notifier)
                          .startPlaying();
                    }
                  },
                ),
              ],
            ),
          ),

          // FPS Slider (enlarged touch target + quick presets)
          Container(
            color: const Color(0xFF1A1D27),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg, vertical: AppSizes.sm),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('FPS',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 22),
                        ),
                        child: Slider(
                          value: fps.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          activeColor: AppColors.accent,
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
                            ref
                                .read(cameraStateProvider.notifier)
                                .setFpsPreset(value.toInt());
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$fps',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [8, 12, 24, 30].map((preset) {
                    final isActive = fps == preset;
                    return GestureDetector(
                      onTap: () => ref
                          .read(cameraStateProvider.notifier)
                          .setFpsPreset(preset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$preset',
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Frame thumbnail grid
          Expanded(
            child: frameCount == 0
                ? _buildEmptyState(context)
                : framePathsAsync.when(
                    data: (paths) =>
                        _buildFrameGrid(context, ref, paths, timelineState),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent),
                    ),
                    error: (_, __) => _buildFrameGrid(
                        context, ref, [], timelineState),
                  ),
          ),

          // Bottom bar: camera back
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg, vertical: AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('撮影に戻る'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: frameCount > 0
                        ? () => _goToExport(context, ref)
                        : null,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text('書き出す',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined,
              size: 64, color: Colors.white24),
          const SizedBox(height: AppSizes.md),
          Text(
            'フレームがありません',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white38),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'カメラ画面で写真を撮りましょう',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameGrid(
    BuildContext context,
    WidgetRef ref,
    List<String> paths,
    TimelineState timelineState,
  ) {
    final frameCount =
        ref.read(cameraStateProvider).frameCount;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: frameCount,
      itemBuilder: (context, index) {
        final isSelected = timelineState.selectedFrameIndex == index;
        final hasFile = index < paths.length;

        final cell = AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail
                hasFile
                    ? Image.file(
                        File(paths[index]),
                        fit: BoxFit.cover,
                        cacheWidth: 120,
                        errorBuilder: (_, __, ___) =>
                            _framePlaceholder(index),
                      )
                    : _framePlaceholder(index),

                // Frame number badge
                Positioned(
                  left: 3,
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),

                // Drag handle hint
                const Positioned(
                  top: 2,
                  left: 2,
                  child: Icon(Icons.drag_indicator,
                      color: Colors.white38, size: 14),
                ),

                // Delete button (only when selected)
                if (isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () =>
                          _confirmDeleteFrame(context, ref, index, frameCount),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) =>
              _reorderFrame(ref, details.data, index, frameCount),
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;
            return LongPressDraggable<int>(
              data: index,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Opacity(opacity: 0.85, child: cell),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: cell),
              child: GestureDetector(
                onTap: () {
                  if (isSelected) {
                    ref.read(timelineStateProvider.notifier).deselectFrame();
                  } else {
                    ref.read(timelineStateProvider.notifier).selectFrame(index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: isDropTarget
                        ? Border.all(color: AppColors.accent, width: 3)
                        : null,
                  ),
                  child: cell,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reorderFrame(
    WidgetRef ref,
    int oldIndex,
    int newIndex,
    int frameCount,
  ) async {
    await VideoService().reorderFrame(projectId, oldIndex, newIndex, frameCount);
    ref.read(timelineStateProvider.notifier).deselectFrame();
    ref.invalidate(framePathsProvider(projectId));
  }

  Future<void> _confirmDeleteFrame(
    BuildContext context,
    WidgetRef ref,
    int index,
    int frameCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D27),
        title: const Text('フレームを削除',
            style: TextStyle(color: Colors.white)),
        content: Text('${index + 1} 枚目のフレームを削除しますか？',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル',
                style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await VideoService().deleteFrame(projectId, index, frameCount);
    ref.read(cameraStateProvider.notifier).decrementFrameCount();
    ref.read(timelineStateProvider.notifier).deselectFrame();
    ref.invalidate(framePathsProvider(projectId));
  }

  Widget _framePlaceholder(int index) {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white38, fontSize: 16),
        ),
      ),
    );
  }

  void _goToExport(BuildContext context, WidgetRef ref) {
    final cState = ref.read(cameraStateProvider);
    Navigator.push(
      context,
      FadePageRoute(
        page: ExportScreen(
          projectId: projectId,
          frameCount: cState.frameCount,
          fps: cState.fpsPreset,
        ),
      ),
    );
  }
}
