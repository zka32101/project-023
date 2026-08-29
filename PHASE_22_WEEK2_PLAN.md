# Phase 22 Week 2 実装計画
## マニュアル切り抜き機能（多角形 + フリーハンド）

**開始日**: 2026-08-29  
**期間**: 1 週間  
**目標**: L2 マニュアル切り抜き機能の完全実装

---

## 📋 実装内容

### 1. マニュアル切り抜きツール

#### 1.1 UI コンポーネント
**新規ファイル**: `lib/screens/manual_cutout_screen.dart`

**機能**:
- 画像プレビュー表示
- 2 つの描画モード切り替え
- キャンバス操作（ズーム、パン）

#### 1.2 多角形選択モード
**CustomPaint ベース**:
- タップで頂点を追加
- ドラッグで頂点を移動
- 既存頂点をタップで削除
- 完了ボタンで確定

**コンポーネント**: `PolygonDrawingMode`

#### 1.3 フリーハンド描画モード
**CustomPaint ベース**:
- ドラッグで自由に描画
- ストロークを蓄積
- マスク生成

**コンポーネント**: `FreehandDrawingMode`

---

### 2. アンドゥ/リドゥ機能

#### 2.1 ストローク履歴管理
```dart
class DrawingHistory {
  final List<_Stroke> strokes;
  int currentIndex;
  
  void undo() => currentIndex--;
  void redo() => currentIndex++;
}
```

#### 2.2 UI ボタン
- **アンドゥ**: 前のストロークに戻る
- **リドゥ**: 次のストロークに進む
- **クリア**: すべて削除

---

### 3. マスク生成 & 透明化

#### 3.1 マスク画像生成
**BackgroundRemovalService に追加**:
```dart
Future<ui.Image> generateMaskFromPath(
  List<Offset> points,  // 多角形頂点
  Size canvasSize,
)

Future<ui.Image> generateMaskFromStrokes(
  List<_Stroke> strokes,  // フリーハンド
  Size canvasSize,
)
```

#### 3.2 透明化処理
既存の `applyManualMask()` を活用

---

## 🏗️ アーキテクチャ

```
BackgroundRemovalScreen
  ├─ 処理方法選択
  │  ├─ 自動（白背景） → L1 実装済み
  │  └─ マニュアル → ManualCutoutScreen へ
  │
  └─ ManualCutoutScreen
      ├─ 描画モード選択
      │  ├─ 多角形 (PolygonDrawingMode)
      │  └─ フリーハンド (FreehandDrawingMode)
      │
      ├─ 履歴管理
      │  ├─ Undo ボタン
      │  ├─ Redo ボタン
      │  └─ Clear ボタン
      │
      └─ マスク生成
          └─ 透明化 → CustomCharacter 登録
```

---

## 📁 新規ファイル

```
lib/
├── screens/
│   └── manual_cutout_screen.dart (400+ 行)
│
├── widgets/
│   ├── polygon_drawing_mode.dart (300+ 行)
│   ├── freehand_drawing_mode.dart (200+ 行)
│   ├── drawing_toolbar.dart (150+ 行)
│   └── canvas_controls.dart (100+ 行)
│
└── models/
    └── drawing_stroke.dart (50 行)
```

---

## ✅ 実装順序

### Day 1-2: UI & キャンバス基盤
- [ ] ManualCutoutScreen スケルトン
- [ ] Canvas 制御（ズーム、パン）
- [ ] 描画モード UI

### Day 3: 多角形選択
- [ ] PolygonDrawingMode 実装
- [ ] タップ/ドラッグ検出
- [ ] 頂点描画
- [ ] 多角形レンダリング

### Day 4: フリーハンド描画
- [ ] FreehandDrawingMode 実装
- [ ] ストローク描画
- [ ] ストローク蓄積

### Day 5: アンドゥ/リドゥ & マスク生成
- [ ] 履歴管理実装
- [ ] マスク生成ロジック
- [ ] 透明化処理
- [ ] テスト & 統合

---

## 🧪 テスト計画

### ユニットテスト
- [ ] DrawingHistory (undo/redo)
- [ ] Mask 生成ロジック
- [ ] 頂点判定ロジック

### ウィジェットテスト
- [ ] Canvas 描画
- [ ] タップ/ドラッグ検出
- [ ] UI ボタン動作

### 統合テスト
- [ ] 全フロー（多角形 → マスク → 保存）
- [ ] 全フロー（フリーハンド → マスク → 保存）

---

## 📊 完成度チェックリスト

| 項目 | 状態 |
|------|------|
| **UI 構築** | ⏳ |
| **多角形選択** | ⏳ |
| **フリーハンド** | ⏳ |
| **Undo/Redo** | ⏳ |
| **マスク生成** | ⏳ |
| **テスト** | ⏳ |
| **統合** | ⏳ |

---

## 🎯 成功基準

| 項目 | 基準 |
|------|------|
| **機能** | L2 完全実装 |
| **テスト** | 全テスト合格 |
| **Lint** | 0 問題 |
| **UX** | 直感的操作 |

---

## 💾 ブランチ & コミット

**ブランチ**: `claude/tsukuani-dev-fldmz8` (既存)

**コミット戦略**:
1. UI & Canvas: `feat(phase-22-w2): Manual cutout UI and canvas`
2. Polygon: `feat(phase-22-w2): Implement polygon selection mode`
3. Freehand: `feat(phase-22-w2): Implement freehand drawing mode`
4. History: `feat(phase-22-w2): Add undo/redo functionality`
5. Mask: `feat(phase-22-w2): Complete mask generation and integration`
6. Tests: `test(phase-22-w2): Add comprehensive test coverage`

---

## 🚀 次フェーズ（Phase 23）

本フェーズ完了後:
- **アフレコスタジオ** — 音声録音 + 合成
- **音声入力** — マイクからの録音
- **タイミング調整** — フレームとのシンク

---

**準備完了！実装を開始します。**

