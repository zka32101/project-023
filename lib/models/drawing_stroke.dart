import 'package:flutter/material.dart';

/// 単一のストロークを表現
class DrawingStroke {
  final List<Offset> points;
  final StrokeType type;
  final Color color;
  final double width;
  final DateTime createdAt;

  DrawingStroke({
    required this.points,
    required this.type,
    this.color = Colors.black,
    this.width = 2.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// ストロークをコピー
  DrawingStroke copyWith({
    List<Offset>? points,
    StrokeType? type,
    Color? color,
    double? width,
    DateTime? createdAt,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      type: type ?? this.type,
      color: color ?? this.color,
      width: width ?? this.width,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// ストロークのタイプ
enum StrokeType {
  polygon,      // 多角形選択
  freehand,     // フリーハンド描画
  mask,         // マスク（内部用）
}

/// 描画履歴を管理
class DrawingHistory {
  final List<DrawingStroke> strokes;
  int _currentIndex = -1;

  DrawingHistory() : strokes = [];

  /// 現在の状態までのストロークを取得
  List<DrawingStroke> get currentStrokes {
    if (_currentIndex < 0) return [];
    return strokes.sublist(0, _currentIndex + 1);
  }

  /// ストロークを追加
  void addStroke(DrawingStroke stroke) {
    // 現在のインデックス以降を削除（新規分岐の場合）
    if (_currentIndex < strokes.length - 1) {
      strokes.removeRange(_currentIndex + 1, strokes.length);
    }
    strokes.add(stroke);
    _currentIndex = strokes.length - 1;
  }

  /// アンドゥ
  bool undo() {
    if (_currentIndex > 0) {
      _currentIndex--;
      return true;
    }
    return false;
  }

  /// リドゥ
  bool redo() {
    if (_currentIndex < strokes.length - 1) {
      _currentIndex++;
      return true;
    }
    return false;
  }

  /// 最後のストロークを削除
  bool removeLast() {
    if (strokes.isNotEmpty && _currentIndex >= 0) {
      strokes.removeAt(_currentIndex);
      _currentIndex--;
      return true;
    }
    return false;
  }

  /// クリア
  void clear() {
    strokes.clear();
    _currentIndex = -1;
  }

  /// 何もない状態か
  bool get isEmpty => strokes.isEmpty;

  /// アンドゥ可能か
  bool get canUndo => _currentIndex > 0;

  /// リドゥ可能か
  bool get canRedo => _currentIndex < strokes.length - 1;
}
