import 'package:flutter/material.dart';

/// 描画ストロークデータモデル
class DrawingStroke {
  /// ストロークを構成するポイントのリスト
  final List<Offset> points;

  /// ストローク幅（ピクセル）
  final double width;

  /// ストロークの色
  final Color color;

  /// ストローク作成時刻
  final DateTime createdAt;

  DrawingStroke({
    required this.points,
    this.width = 2.0,
    this.color = Colors.black,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// ストロークのコピー（フィールド上書き用）
  DrawingStroke copyWith({
    List<Offset>? points,
    double? width,
    Color? color,
    DateTime? createdAt,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      width: width ?? this.width,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// ストロークが有効かどうかを判定（ポイント数 >= 2）
  bool get isValid => points.length >= 2;
}

/// 描画操作の履歴管理
class DrawingHistory {
  /// ストロークのリスト
  final List<DrawingStroke> _strokes = [];

  /// 現在の履歴インデックス
  int _currentIndex = -1;

  /// 現在のストローク一覧を取得
  List<DrawingStroke> get strokes => _strokes.sublist(0, _currentIndex + 1);

  /// 複数のストローク値を取得（フリーハンド用）
  List<DrawingStroke> get allStrokes => List.unmodifiable(_strokes);

  /// アンドゥできるかどうか
  bool get canUndo => _currentIndex > -1;

  /// リドゥできるかどうか
  bool get canRedo => _currentIndex < _strokes.length - 1;

  /// ストロークを追加
  void addStroke(DrawingStroke stroke) {
    // 現在位置より後ろのストロークを削除（アンドゥ後に新規操作した場合）
    if (_currentIndex < _strokes.length - 1) {
      _strokes.removeRange(_currentIndex + 1, _strokes.length);
    }

    _strokes.add(stroke);
    _currentIndex++;
  }

  /// 最後のストロークを削除
  void removeLastStroke() {
    if (_strokes.isNotEmpty && _currentIndex >= 0) {
      _strokes.removeAt(_currentIndex);
      _currentIndex--;
    }
  }

  /// アンドゥ実行
  void undo() {
    if (canUndo) {
      _currentIndex--;
    }
  }

  /// リドゥ実行
  void redo() {
    if (canRedo) {
      _currentIndex++;
    }
  }

  /// すべてをクリア
  void clear() {
    _strokes.clear();
    _currentIndex = -1;
  }

  /// 現在のストロークをリセット（アンドゥで隠れたストロークは保持）
  void resetToCurrentIndex() {
    if (_currentIndex < _strokes.length - 1) {
      _strokes.removeRange(_currentIndex + 1, _strokes.length);
    }
  }
}
