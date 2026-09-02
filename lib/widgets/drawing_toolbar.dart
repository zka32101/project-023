import 'package:flutter/material.dart';
import '../config/constants.dart';

/// 描画モード
enum DrawingMode {
  polygon,
  freehand,
}

/// 描画ツールバーコールバック
typedef DrawingModeChanged = void Function(DrawingMode mode);
typedef DrawingActionTriggered = void Function(String action);

/// 描画ツールバー
class DrawingToolbar extends StatefulWidget {
  /// 現在の描画モード
  final DrawingMode currentMode;

  /// モード変更コールバック
  final DrawingModeChanged onModeChanged;

  /// アクション実行コールバック（undo, redo, clear）
  final DrawingActionTriggered onAction;

  /// アンドゥ可能かどうか
  final bool canUndo;

  /// リドゥ可能かどうか
  final bool canRedo;

  const DrawingToolbar({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
    required this.onAction,
    this.canUndo = false,
    this.canRedo = false,
  }) : super(key: key);

  @override
  State<DrawingToolbar> createState() => _DrawingToolbarState();
}

class _DrawingToolbarState extends State<DrawingToolbar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 描画モード選択
          Row(
            children: [
              Expanded(
                child: Text(
                  '描画モード',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.mediumGrey),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    _ModeButton(
                      icon: Icons.crop_din,
                      label: '多角形',
                      isSelected: widget.currentMode == DrawingMode.polygon,
                      onPressed: () =>
                          widget.onModeChanged(DrawingMode.polygon),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.mediumGrey,
                    ),
                    _ModeButton(
                      icon: Icons.gesture,
                      label: 'フリーハンド',
                      isSelected: widget.currentMode == DrawingMode.freehand,
                      onPressed: () =>
                          widget.onModeChanged(DrawingMode.freehand),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // 操作ボタン
          Row(
            children: [
              // アンドゥボタン
              _ActionButton(
                icon: Icons.undo,
                label: 'アンドゥ',
                enabled: widget.canUndo,
                onPressed: () => widget.onAction('undo'),
              ),
              const SizedBox(width: AppSizes.sm),

              // リドゥボタン
              _ActionButton(
                icon: Icons.redo,
                label: 'リドゥ',
                enabled: widget.canRedo,
                onPressed: () => widget.onAction('redo'),
              ),
              const SizedBox(width: AppSizes.sm),

              // クリアボタン
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'クリア',
                enabled: true,
                onPressed: () => widget.onAction('clear'),
              ),
              const Spacer(),

              // リセットボタン
              _ActionButton(
                icon: Icons.fit_screen,
                label: 'リセット',
                enabled: true,
                onPressed: () => widget.onAction('reset_canvas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// モード選択ボタン
class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor:
            isSelected ? AppColors.primaryStart : AppColors.darkGrey,
        backgroundColor:
            isSelected ? AppColors.primaryStart.withAlpha(20) : null,
      ),
    );
  }
}

/// アクションボタン
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(icon),
        onPressed: enabled ? onPressed : null,
        tooltip: label,
      ),
    );
  }
}
