# つくアニ Phase 22 実装計画書
## おえかきキャラクター拡張（背景切り抜き + AI学習）

**フェーズ**: Phase 22  
**開発期間**: 1-2週間  
**目標**: 手描き・写真キャラクターの背景切り抜き機能を完成させる

---

## 📋 実装内容

### 1. 背景切り抜き機能（Background Removal）
背景を自動で削除し、透明PNG として保存する機能

#### 1.1 画像選択画面
- **機能**: ギャラリーから画像を選択 → プレビュー表示
- **ファイル**: `lib/screens/background_removal_screen.dart`（新規）
- **UI構成**:
  - 選択ボタン (image_picker)
  - 画像プレビュー
  - 複数切り抜き方法の選択肢

#### 1.2 背景切り抜き処理
**3つの実装レベル（優先度順）**:

1. **L1: 簡易版（白背景検出）** ⭐ Week 1
   - 白系背景を自動削除（最も簡単）
   - 実装: `image` パッケージ + ピクセル判定
   - 処理時間: 1-2秒

2. **L2: マニュアル切り抜き** 🎨 Week 1-2
   - ユーザーが指で背景をタッチして削除
   - 実装: CustomPaint + 多角形選択ツール
   - 処理時間: ユーザー依存

3. **L3: ML背景削除（ExpandedNets/U-Net）** 🤖 Week 2+
   - TensorFlow Lite + 背景セグメンテーション
   - 実装: `tflite_flutter` パッケージ
   - 処理時間: 3-5秒（GPU 有効時）
   - **別PR**: 検討フェーズ

#### 1.3 UI コンポーネント
- `BackgroundRemovalMethodSelector` — 処理方法選択
- `RemovalProgressIndicator` — 進捗表示
- `PreviewWithMask` — マスク付きプレビュー

---

### 2. キャラクター管理UI拡張

#### 2.1 カスタムキャラクター一覧画面
- **ファイル**: `lib/screens/custom_character_gallery_screen.dart`（新規）
- **機能**:
  - グリッド表示（手描き + 写真両方）
  - 長押し: リネーム / 削除
  - 詳細情報: 作成日時、サイズ、背景削除状況

#### 2.2 キャラクター詳細画面
- **ファイル**: `lib/widgets/custom_character_detail_view.dart`（新規）
- **表示内容**:
  - プレビュー（透明背景表示）
  - メタデータ（名前、作成日、背景処理）
  - アクション: 再編集、複製、削除、エクスポート

---

### 3. データモデル拡張

#### 3.1 CustomCharacter の拡張
```dart
class CustomCharacter {
  final String id;
  final String name;
  final String imagePath;
  
  // 新規フィールド
  final String sourceType;      // 'drawn' | 'photo'
  final String removalMethod;   // 'none' | 'white' | 'manual' | 'ml'
  final bool hasTransparency;   // 背景透明化済みフラグ
  final DateTime createdAt;
  final int? originalFileSize;  // 元画像のサイズ
}
```

#### 3.2 Provider 拡張
- `customCharacterProvider` に背景削除履歴を追加
- `selectedCharacterProvider` — 詳細画面用

---

### 4. 機能フロー

```
ホーム画面
  ↓
「マイキャラを作る」タップ
  ↓
[ 手書き ] or [ 写真から ]
  ├→ 手書き → CharacterDrawingScreen
  │   ↓
  │ キャラ保存
  │   ↓
  │ カスタムキャラクター一覧へ
  │
  └→ 写真から → 背景切り抜き
      ↓
    ギャラリー選択
      ↓
    背景切り抜き方法選択
      ├→ 自動（白背景）→ 即座に完了
      ├→ マニュアル → 手作業
      └→ AI → 処理中...
      ↓
    透明PNG保存
      ↓
    キャラ名入力
      ↓
    カスタムキャラクター一覧へ
```

---

## 🔧 技術仕様

### 4.1 使用パッケージ

| パッケージ | 版 | 用途 |
|-----------|-----|------|
| `image` | ^4.0.0 | ピクセル操作 / 白背景検出 |
| `image_picker` | ✅ 既有 | ギャラリー選択 |
| `path_provider` | ✅ 既有 | ファイル保存 |
| `permission_handler` | ✅ 既有 | ストレージアクセス |
| `tflite_flutter` | ^0.10.0 | ML背景削除 (後追 L3) |

### 4.2 ファイルサイズ最適化
- 透明PNG保存時、ImageMagick 互換の最小化
- 目標: 500KB 以下 / キャラクター

---

## 📁 新規ファイル一覧

```
lib/
├── screens/
│   ├── background_removal_screen.dart      # 背景切り抜きメイン画面
│   └── custom_character_gallery_screen.dart  # カスタムキャラ一覧
│
├── widgets/
│   ├── background_removal_method_selector.dart  # 処理方法選択UI
│   ├── removal_progress_indicator.dart          # 進捗表示
│   ├── preview_with_mask.dart                   # マスク付きプレビュー
│   └── custom_character_detail_view.dart        # 詳細表示

├── services/
│   └── background_removal_service.dart     # L1/L2/L3 背景処理エンジン

└── models/
    └── background_removal_method.dart      # 列挙型

assets/
└── images/
    └── background_removal_guide.png        # 使い方ガイド
```

---

## ✅ 実装タイムライン

### Week 1
- [ ] Day 1: CustomCharacter モデル拡張 + CustomCharacterProvider 更新
- [ ] Day 2: BackgroundRemovalScreen UI 構築
- [ ] Day 3: L1（白背景検出）実装 + テスト
- [ ] Day 4: L2（マニュアル切り抜き）UI 実装
- [ ] Day 5: UI統合 + カメラ画面での動作確認

### Week 2
- [ ] Day 1: CustomCharacterGalleryScreen 実装
- [ ] Day 2: キャラ詳細表示 + メタデータ表示
- [ ] Day 3: エッジケース対応 + バグ修正
- [ ] Day 4: テスト追加（ウィジェットテスト）
- [ ] Day 5: ドキュメント & PR 準備

---

## 🧪 テスト計画

### ユニットテスト
- `BackgroundRemovalService` のL1/L2処理テスト
- `CustomCharacter` の JSON シリアライズテスト
- ファイルI/O のエラーハンドリング

### ウィジェットテスト
- `BackgroundRemovalScreen` の画像選択 / プレビュー
- `CustomCharacterGalleryScreen` のグリッド表示
- タッチジェスチャー（長押し、選択）

### 統合テスト
- 手書き → 背景切り抜き → カメラ配置 全フロー

---

## 📊 成功基準

| 項目 | 基準 |
|------|------|
| **背景切り抜き精度** | 90%+ の画像で正確に背景削除 |
| **処理速度** | L1: <2秒, L2: <10秒 |
| **ストレージ** | 平均 300-500KB/キャラクター |
| **テスト合格** | 全テスト合格 + Lint 0 問題 |
| **UI/UX** | 3クリック以内で完成 |

---

## 🚀 次のフェーズ（Phase 23）

本フェーズ完了後、以下を実装:
- **アフレコスタジオ** — 音声録音 + 動画合成
- 音声入力、タイミング調整、BGM統合

---

**開発日**: 2026-08-29  
**ステータス**: 🚀 準備完了 → 実装開始  
**責任者**: Claude Code

---

