import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/constants.dart';
import '../models/ar_character.dart';
import '../models/custom_character.dart';
import '../providers/camera_provider.dart';
import '../providers/ar_character_provider.dart';
import '../providers/custom_character_provider.dart';
import '../providers/frame_provider.dart';
import '../services/video_service.dart';
import '../utils/haptic_feedback.dart';
import '../utils/logger.dart';
import '../widgets/page_transition.dart';
import '../widgets/live_preview_widget.dart';
import 'character_drawing_screen.dart';
import 'timeline_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final String projectId;

  const CameraScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  String? _cameraError;
  Uint8List? _onionSkinImage; // 前フレームの画像

  final GlobalKey _captureKey = GlobalKey();
  Offset _characterPosition = const Offset(0.5, 0.5); // 相対座標 (0-1)
  ARCharacter? _placedCharacter;
  CustomCharacter? _placedCustomCharacter;

  bool get _hasPlacedCharacter =>
      _placedCharacter != null || _placedCustomCharacter != null;

  // Character controls
  double _characterSize = 1.0; // 0.5 - 2.0
  double _characterRotation = 0.0; // -180 to 180
  double _characterOpacity = 1.0; // 0.0 - 1.0
  bool _showCharacterControls = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() => _cameraError = 'カメラの権限が必要です。設定から許可してください。');
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraError = 'カメラが見つかりません');
        return;
      }

      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      AppLogger.error('Camera initialization error', e);
      if (mounted) {
        setState(() => _cameraError = 'カメラの初期化に失敗しました: $e');
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraStateProvider);
    final charactersAsync = ref.watch(freeCharactersProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _confirmExit(context),
        ),
        title: Text(
          'フレーム ${cameraState.frameCount}/100',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.grid_3x3,
              color: cameraState.gridGuideEnabled
                  ? AppColors.accent
                  : Colors.white,
            ),
            onPressed: () =>
                ref.read(cameraStateProvider.notifier).toggleGridGuide(),
            tooltip: 'グリッドガイド',
          ),
          IconButton(
            icon: Icon(
              Icons.layers,
              color: cameraState.onionSkinEnabled
                  ? AppColors.accent
                  : Colors.white,
            ),
            onPressed: () =>
                ref.read(cameraStateProvider.notifier).toggleOnionSkin(),
            tooltip: 'オニオンスキン',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera view
          Expanded(
            flex: 3,
            child: _buildCameraView(cameraState),
          ),

          // Character selector
          _buildCharacterSelector(charactersAsync),

          // Character control panel (expandable)
          if (_placedCharacter != null)
            _buildCharacterControlPanel(),

          // Live loop preview (3+ frames)
          if (cameraState.frameCount >= 3)
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  const Text(
                    'ライブプレビュー',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  LivePreviewWidget(
                    framePaths: ref.watch(framePathsProvider(widget.projectId)).maybeWhen(
                      data: (paths) => paths,
                      orElse: () => [],
                    ),
                    fps: cameraState.fpsPreset,
                  ),
                ],
              ),
            ),

          // Bottom controls
          _buildBottomControls(context, cameraState),

          // Timeline button (Aha Moment達成後)
          if (cameraState.isAhaMoment)
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, 0, AppSizes.md, AppSizes.md),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _goToTimeline(context),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'タイムラインへ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraView(CameraState cameraState) {
    return RepaintBoundary(
      key: _captureKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview or error
          if (_cameraError != null)
            _buildCameraError()
          else if (!_isCameraInitialized)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            _buildCameraPreview(),

          // Onion skin overlay
          if (cameraState.onionSkinEnabled && _onionSkinImage != null)
            Opacity(
              opacity: 0.35,
              child: Image.memory(
                _onionSkinImage!,
                fit: BoxFit.cover,
              ),
            ),

          // Grid guide overlay
          if (cameraState.gridGuideEnabled) _buildGridGuide(),

          // Placed character overlay (draggable)
          if (_hasPlacedCharacter) _buildCharacterOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return GestureDetector(
      onTapDown: (details) {
        if (_hasPlacedCharacter) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final local = box.globalToLocal(details.globalPosition);
            final size = box.size;
            setState(() {
              _characterPosition = Offset(
                (local.dx / size.width).clamp(0.0, 1.0),
                (local.dy / size.height).clamp(0.0, 1.0),
              );
            });
          }
        }
      },
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildCameraError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: AppSizes.md),
            Text(
              _cameraError ?? 'カメラエラー',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
              onPressed: _initCamera,
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridGuide() {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }

  Widget _buildCharacterOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final charSize = 80.0 * _characterSize;
        final left =
            (_characterPosition.dx * constraints.maxWidth - charSize / 2)
                .clamp(0.0, constraints.maxWidth - charSize);
        final top =
            (_characterPosition.dy * constraints.maxHeight - charSize / 2)
                .clamp(0.0, constraints.maxHeight - charSize);

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _characterPosition = Offset(
                      (_characterPosition.dx +
                              details.delta.dx / constraints.maxWidth)
                          .clamp(0.0, 1.0),
                      (_characterPosition.dy +
                              details.delta.dy / constraints.maxHeight)
                          .clamp(0.0, 1.0),
                    );
                  });
                },
                child: Transform.rotate(
                  angle: _characterRotation * 3.14159 / 180,
                  child: Opacity(
                    opacity: _characterOpacity,
                    child: _placedCustomCharacter != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(charSize / 2),
                            child: Container(
                              width: charSize,
                              height: charSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(charSize / 2),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: Image.file(
                                File(_placedCustomCharacter!.imagePath),
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : Container(
                            width: charSize,
                            height: charSize,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(200),
                              borderRadius: BorderRadius.circular(charSize / 2),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                _placedCharacter!.name.characters.first,
                                style:
                                    TextStyle(fontSize: 36 * _characterSize),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharacterSelector(AsyncValue<List<ARCharacter>> charactersAsync) {
    final customCharacters = ref.watch(customCharacterProvider);

    return Container(
      height: 80,
      color: Colors.grey[900],
      child: charactersAsync.when(
        data: (characters) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.sm),
          itemCount: characters.length + customCharacters.length + 2,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppSizes.sm),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildClearCharacterButton();
            }
            if (index == 1) {
              return _buildDrawCharacterButton();
            }
            final customIndex = index - 2;
            if (customIndex < customCharacters.length) {
              return _buildCustomCharacterChip(customCharacters[customIndex]);
            }
            final char = characters[customIndex - customCharacters.length];
            return _buildCharacterChip(char);
          },
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (_, __) =>
            const Center(child: Icon(Icons.error, color: Colors.red)),
      ),
    );
  }

  Widget _buildClearCharacterButton() {
    return GestureDetector(
      onTap: () => setState(() {
        _placedCharacter = null;
        _placedCustomCharacter = null;
      }),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: !_hasPlacedCharacter ? Colors.grey[600] : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !_hasPlacedCharacter ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: const Icon(Icons.close, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawCharacterButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<CustomCharacter>(
          context,
          MaterialPageRoute(builder: (_) => const CharacterDrawingScreen()),
        );
        if (result != null && mounted) {
          setState(() {
            _placedCharacter = null;
            _placedCustomCharacter = result;
            _characterPosition = const Offset(0.5, 0.5);
          });
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: const Icon(Icons.brush, color: AppColors.accent),
      ),
    );
  }

  Widget _buildCustomCharacterChip(CustomCharacter character) {
    final isSelected = _placedCustomCharacter?.id == character.id;
    return GestureDetector(
      onTap: () => setState(() {
        _placedCustomCharacter = isSelected ? null : character;
        _placedCharacter = null;
        _characterPosition = const Offset(0.5, 0.5);
      }),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(character.imagePath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, color: Colors.white38),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterChip(ARCharacter char) {
    final isSelected = _placedCharacter?.characterId == char.characterId;
    return GestureDetector(
      onTap: () => setState(() {
        _placedCharacter = isSelected ? null : char;
        _placedCustomCharacter = null;
        _characterPosition = const Offset(0.5, 0.5);
      }),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withAlpha(200)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            char.name.characters.first,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, CameraState cameraState) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg, vertical: AppSizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FPS Slider
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white54, size: 18),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Slider(
                  value: cameraState.fpsPreset.toDouble(),
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
              Text(
                '${cameraState.fpsPreset}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Shoot button (centered) + Frame count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Frame count (left)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cameraState.frameCount}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '枚撮影',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),

              // Shoot button (center) - Large with gradient + pulse
              GestureDetector(
                onTap: () => _captureFrame(context),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade700,
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withAlpha(150),
                        blurRadius: 20,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: Colors.red.withAlpha(80),
                        blurRadius: 40,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera, color: Colors.white, size: 44),
                ),
              ),

              // Progress indicator (right)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${((cameraState.frameCount / 100) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (cameraState.frameCount / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _captureFrame(BuildContext context) async {
    if (_cameraController == null || !_isCameraInitialized) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Capture the composited view (camera + character overlay) as PNG
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 1.5);
      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return;

      final bytes = pngData.buffer.asUint8List();

      // Save frame as PNG (ffmpeg reads frame_%d.png)
      final frameIndex = ref.read(cameraStateProvider).frameCount;
      await VideoService().saveFrameImage(widget.projectId, frameIndex, bytes);

      // Reuse same PNG bytes for onion skin
      if (mounted) {
        setState(() => _onionSkinImage = bytes);
      }

      // Update state
      ref.read(cameraStateProvider.notifier).recordFrame();
      HapticService().trigger(HapticFeedbackType.shootSuccess);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'フレーム ${ref.read(cameraStateProvider).frameCount} 撮影!'),
            duration: const Duration(milliseconds: 400),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Frame capture error', e);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('撮影に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCharacterControlPanel() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with toggle
          Row(
            children: [
              const Expanded(
                child: Text(
                  'キャラ設定',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showCharacterControls ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => setState(() => _showCharacterControls = !_showCharacterControls),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),

          // Controls (expandable)
          if (_showCharacterControls) ...[
            const SizedBox(height: AppSizes.sm),

            // Size slider
            Row(
              children: [
                const Icon(Icons.zoom_in, color: Colors.white54, size: 16),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Slider(
                    value: _characterSize,
                    min: 0.5,
                    max: 2.0,
                    activeColor: AppColors.accent,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => setState(() => _characterSize = v),
                  ),
                ),
                Text(
                  '${(_characterSize * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),

            // Rotation dial
            Row(
              children: [
                const Icon(Icons.rotate_right, color: Colors.white54, size: 16),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Slider(
                    value: _characterRotation,
                    min: -180,
                    max: 180,
                    activeColor: AppColors.accent,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => setState(() => _characterRotation = v),
                  ),
                ),
                Text(
                  '${_characterRotation.toStringAsFixed(0)}°',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),

            // Opacity slider
            Row(
              children: [
                const Icon(Icons.opacity, color: Colors.white54, size: 16),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Slider(
                    value: _characterOpacity,
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppColors.accent,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => setState(() => _characterOpacity = v),
                  ),
                ),
                Text(
                  '${(_characterOpacity * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('撮影を中止'),
        content: const Text('撮影済みのフレームが失われます。本当に中止しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cameraStateProvider.notifier).reset();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('中止', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _goToTimeline(BuildContext context) {
    Navigator.push(
      context,
      ScaleFadePageRoute(
        page: TimelineScreen(projectId: widget.projectId),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..strokeWidth = 0.8;

    // 3x3 grid
    canvas.drawLine(
        Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
