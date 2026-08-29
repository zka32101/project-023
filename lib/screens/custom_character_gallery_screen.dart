import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/custom_character.dart';
import '../providers/custom_character_provider.dart';
import '../screens/background_removal_screen.dart';
import '../screens/character_drawing_screen.dart';
import '../utils/logger.dart';

class CustomCharacterGalleryScreen extends ConsumerWidget {
  const CustomCharacterGalleryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customCharacters = ref.watch(customCharacterProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('マイキャラクター'),
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: customCharacters.isEmpty
          ? _buildEmptyState(context)
          : _buildCharacterGrid(context, ref, customCharacters),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreationOptions(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        label: const Text('新規作成'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_outlined,
            size: 80,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'まだキャラクターがありません',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            '手書きまたは写真から\nオリジナルキャラクターを作ろう！',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton.icon(
            onPressed: () => _showCreationOptions(context),
            icon: const Icon(Icons.add),
            label: const Text('キャラクター作成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterGrid(
    BuildContext context,
    WidgetRef ref,
    List<CustomCharacter> characters,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Text(
            '${characters.length} 件',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSizes.md,
              crossAxisSpacing: AppSizes.md,
              childAspectRatio: 1.0,
            ),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return _buildCharacterCard(context, ref, character);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(
    BuildContext context,
    WidgetRef ref,
    CustomCharacter character,
  ) {
    return GestureDetector(
      onLongPress: () => _showCharacterMenu(context, ref, character),
      child: Card(
        color: Colors.grey.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // キャラクター画像
            if (File(character.imagePath).existsSync())
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(character.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade900,
                ),
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            // グラデーションオーバーレイ
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // メタデータ
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _buildBadge(
                        character.sourceType == 'drawn' ? '手書き' : '写真',
                        Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      if (character.hasTransparency)
                        _buildBadge('透過', Colors.green.shade700),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCharacterMenu(
    BuildContext context,
    WidgetRef ref,
    CustomCharacter character,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade800,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                '名前を変更',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, character);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text(
                '詳細を表示',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDetailDialog(context, character);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                '削除',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, character);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    CustomCharacter character,
  ) {
    final controller = TextEditingController(text: character.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('キャラクター名を変更'),
        content: TextField(
          controller: controller,
          maxLength: 20,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'キャラクター名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _renameCharacter(context, ref, character, newName);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameCharacter(
    BuildContext context,
    WidgetRef ref,
    CustomCharacter character,
    String newName,
  ) async {
    try {
      final updated = character.copyWith(name: newName);
      final characters = ref.read(customCharacterProvider);
      final index = characters.indexWhere((c) => c.id == character.id);

      if (index >= 0) {
        final newList = List<CustomCharacter>.from(characters);
        newList[index] = updated;
        ref.read(customCharacterProvider.notifier).state = newList;
        await ref.read(customCharacterProvider.notifier).persistState();
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('キャラクター名を変更しました')),
        );
      }
    } catch (e) {
      AppLogger.error('Rename character', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  void _showDetailDialog(BuildContext context, CustomCharacter character) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('キャラクター情報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('名前', character.name),
            _buildDetailRow('タイプ', character.sourceType == 'drawn' ? '手書き' : '写真'),
            _buildDetailRow(
              '背景処理',
              character.removalMethod == 'none' ? 'なし' : character.removalMethod,
            ),
            _buildDetailRow(
              '透明度',
              character.hasTransparency ? '透過済み' : '背景あり',
            ),
            _buildDetailRow(
              '作成日',
              '${character.createdAt.year}-${character.createdAt.month.toString().padLeft(2, '0')}-${character.createdAt.day.toString().padLeft(2, '0')}',
            ),
            if (character.originalFileSize != null)
              _buildDetailRow(
                'ファイルサイズ',
                '${(character.originalFileSize! / 1024).toStringAsFixed(1)} KB',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(value, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    CustomCharacter character,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('キャラクターを削除しますか？'),
        content: Text('「${character.name}」を削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(customCharacterProvider.notifier)
                  .removeCharacter(character.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('キャラクターを削除しました')),
              );
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade800,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Text(
                'キャラクターを作成',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.brush, color: AppColors.accent),
              title: const Text(
                '手書きで作成',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '指で自由に描いてキャラクターを作ります',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<CustomCharacter>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CharacterDrawingScreen(),
                  ),
                );
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('キャラクターを作成しました')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.image, color: AppColors.accent),
              title: const Text(
                '写真から背景を削除',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '写真の背景を透明にしてキャラクターに',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<CustomCharacter>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackgroundRemovalScreen(),
                  ),
                );
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('キャラクターを保存しました')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
