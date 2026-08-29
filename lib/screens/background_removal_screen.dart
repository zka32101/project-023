import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../config/constants.dart';
import '../models/custom_character.dart';
import '../services/background_removal_service.dart';
import '../utils/logger.dart';

class BackgroundRemovalScreen extends ConsumerStatefulWidget {
  const BackgroundRemovalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BackgroundRemovalScreen> createState() =>
      _BackgroundRemovalScreenState();
}

class _BackgroundRemovalScreenState
    extends ConsumerState<BackgroundRemovalScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _isProcessing = false;
  String _selectedMethod = 'white';
  String? _errorMessage;

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _processedImage = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('画像選択に失敗しました: $e');
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) {
      _showError('画像を選択してください');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      Uint8List? result;
      if (_selectedMethod == 'white') {
        result = await BackgroundRemovalService.removeWhiteBackground(
          imageBytes,
          threshold: 200,
          tolerance: 30,
        );
      }

      if (result == null) {
        _showError('背景切り抜きに失敗しました');
        return;
      }

      setState(() {
        _processedImage = result;
        _errorMessage = null;
      });
    } catch (e) {
      _showError('処理中にエラーが発生しました: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveCharacter() async {
    if (_processedImage == null) {
      _showError('先に背景を切り抜いてください');
      return;
    }

    try {
      setState(() => _isProcessing = true);

      final docsDir = await getApplicationDocumentsDirectory();
      final customDir = Directory('${docsDir.path}/custom_characters');
      if (!customDir.existsSync()) {
        customDir.createSync(recursive: true);
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '${customDir.path}/character_$id.png';
      await File(path).writeAsBytes(_processedImage!);

      final character = CustomCharacter(
        id: id,
        name: '写真キャラ',
        imagePath: path,
        sourceType: 'photo',
        removalMethod: _selectedMethod,
        hasTransparency: true,
        originalFileSize: _selectedImage!.lengthSync(),
      );

      if (mounted) {
        Navigator.pop(context, character);
      }
    } catch (e) {
      _showError('保存に失敗しました: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    AppLogger.error('Background Removal', message);
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('背景を切り抜こう'),
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 画像プレビュー エリア
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: _buildPreviewArea(),
            ),

            // 処理方法選択
            if (_selectedImage != null && _processedImage == null)
              _buildMethodSelector(),

            // エラーメッセージ
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            // アクションボタン
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_selectedImage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              '画像を選択してください',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('ギャラリーから選択'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.md),
            Text(
              '処理中...',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    if (_processedImage != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(_processedImage!),
            fit: BoxFit.contain,
          ),
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '✓ 完了',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return Image.file(
      _selectedImage!,
      fit: BoxFit.contain,
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '切り抜き方法を選択',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          RadioListTile<String>(
            title: const Text(
              '自動（白背景のみ対応）',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              '白い背景が素早く削除されます',
              style: TextStyle(color: Colors.grey),
            ),
            value: 'white',
            groupValue: _selectedMethod,
            onChanged: (val) => setState(() => _selectedMethod = val ?? 'white'),
            activeColor: AppColors.accent,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'マニュアル切り抜きは Phase 22.2 で実装予定',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_selectedImage != null && _processedImage == null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processImage,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(
                _isProcessing ? '処理中...' : '背景を削除する',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _selectedImage = null;
                _processedImage = null;
              }),
              icon: const Icon(Icons.clear),
              label: const Text('キャンセル'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
            ),
          ),
        ],
        if (_processedImage != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _saveCharacter,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _isProcessing ? '保存中...' : 'キャラクターにする',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _processedImage = null),
              icon: const Icon(Icons.refresh),
              label: const Text('別の方法で試す'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
