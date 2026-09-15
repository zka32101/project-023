# Phase 24 実装計画
## 動画合成 (Video Composition) - アニメーション + 音声統合

**フェーズ**: Phase 24  
**開発期間**: 1-2週間  
**目標**: アニメーションフレーム + ダビングオーディオ統合による動画生成

---

## 📋 実装内容

### 1. 動画合成サービス

#### 1.1 FFmpeg ラッパー強化
**ファイル**: `lib/services/video_composition_service.dart`

**機能**:
- アニメーションフレーム + オーディオの合成
- フレームレート管理（24/30fps）
- オーディオトラックの複数マージ
- 出力フォーマット制御

#### 1.2 FFmpeg コマンド生成
**ファイル**: `lib/utils/ffmpeg_command_builder.dart`

**機能**:
- フレームシーケンス入力（PNG/JPG）
- 複数オーディオトラックのミックス
- 動画エンコード設定
- メタデータ埋め込み

---

### 2. UI コンポーネント

#### 2.1 合成プレビュー画面
**新規ファイル**: `lib/screens/video_composition_screen.dart`

**機能**:
- 合成対象フレーム表示
- オーディオトラック確認
- フレームレート/コーデック選択
- 進行状況表示

#### 2.2 出力フォーマット選択
**新規ファイル**: `lib/widgets/output_format_selector.dart`

**機能**:
- MP4/WebM/MOV 選択
- 解像度選択（720p/1080p/4K）
- ビットレート調整
- プリセット保存

#### 2.3 合成進行状況ウィジェット
**新規ファイル**: `lib/widgets/composition_progress.dart`

**機能**:
- リアルタイム進行度表示
- フレーム処理状況
- 推定残り時間
- キャンセル機能

---

### 3. データモデル拡張

#### 3.1 VideoComposition モデル
```dart
class VideoComposition {
  final String id;
  final String projectId;      // DubbingProject への参照
  final String outputPath;
  final VideoFormat format;    // MP4, WebM, MOV
  final VideoResolution resolution;
  final int fps;
  final double videoFileSize;  // MB
  final DateTime createdAt;
  final CompositionStatus status; // pending, processing, completed, failed
  final String? errorMessage;
}
```

#### 3.2 VideoFormat & VideoResolution
```dart
enum VideoFormat { mp4, webm, mov }
enum VideoResolution { hd720, fullHd1080, uhd4k }

extension VideoResolutionExt on VideoResolution {
  String get dimensions {
    switch (this) {
      case VideoResolution.hd720 => '1280x720';
      case VideoResolution.fullHd1080 => '1920x1080';
      case VideoResolution.uhd4k => '3840x2160';
    }
  }
}
```

#### 3.3 CompositionStatus & CompositionProgress
```dart
enum CompositionStatus { pending, processing, completed, failed }

class CompositionProgress {
  final int processedFrames;
  final int totalFrames;
  final double percentComplete;
  final Duration estimatedTimeRemaining;
}
```

---

### 4. 機能フロー

```
DubbingProject 完成
  ↓
「動画生成」ボタン
  ↓
VideoCompositionScreen
  ├─ フレーム確認
  ├─ オーディオトラック確認
  └─ 出力フォーマット選択
  ↓
合成開始
  ├─ FFmpeg フレーム読み込み
  ├─ オーディオミックス
  └─ ビデオエンコード
  ↓
進行状況表示 (CompositionProgress)
  ↓
合成完了 → VideoComposition 保存
  ↓
成功 → ダウンロード/シェア
```

---

## 📁 新規ファイル一覧

```
lib/
├── screens/
│   └── video_composition_screen.dart      # 動画合成メイン画面
│
├── widgets/
│   ├── output_format_selector.dart        # フォーマット選択
│   ├── composition_progress.dart          # 進行状況表示
│   ├── audio_track_mixer.dart             # オーディオトラックミキシング
│   └── frame_preview_grid.dart            # フレームプレビュー
│
├── services/
│   └── video_composition_service.dart     # 動画合成サービス
│
├── utils/
│   ├── ffmpeg_command_builder.dart        # FFmpeg コマンド生成
│   ├── audio_mixing_utils.dart            # オーディオミックスユーティリティ
│   └── video_encoding_presets.dart        # エンコーディング プリセット
│
├── models/
│   ├── video_composition.dart             # 動画合成モデル
│   └── composition_settings.dart          # 合成設定
│
└── providers/
    └── video_composition_provider.dart    # 状態管理 (Riverpod)

test/
├── services/
│   └── video_composition_service_test.dart
├── widgets/
│   └── composition_progress_test.dart
└── integration/
    └── video_composition_workflow_test.dart
```

---

## ✅ 実装順序

### Day 1-2: FFmpeg 統合 & サービス実装
- [ ] FFmpeg コマンドビルダー実装
- [ ] オーディオミックス機能
- [ ] VideoCompositionService 基本実装
- [ ] エラーハンドリング

### Day 3-4: UI コンポーネント
- [ ] VideoCompositionScreen 実装
- [ ] OutputFormatSelector ウィジェット
- [ ] CompositionProgress ウィジェット
- [ ] フレームプレビュー表示

### Day 5: 統合 & テスト
- [ ] 完全なワークフロー統合
- [ ] ユニット & ウィジェットテスト (30+ tests)
- [ ] 統合テスト
- [ ] パフォーマンス最適化

---

## 🧪 テスト計画

### ユニットテスト
- [ ] FFmpeg コマンド生成の正確性
- [ ] オーディオミックスロジック
- [ ] フォーマット変換ユーティリティ
- [ ] 解像度計算

### ウィジェットテスト
- [ ] フォーマット選択UI
- [ ] 進行状況表示アニメーション
- [ ] フレームグリッド表示
- [ ] 入力フィールド検証

### 統合テスト
- [ ] 完全な合成フロー（フレーム + オーディオ）
- [ ] エラーリカバリー
- [ ] キャンセル機能
- [ ] ファイル保存検証

---

## 📊 成功基準

| 項目 | 基準 |
|------|------|
| **フレーム読み込み** | 全フレーム正確に読み込み、スキップなし |
| **オーディオミックス** | 複数トラック正確にミックス、音ズレなし |
| **動画生成** | MP4/WebM/MOV 形式で正常にエンコード |
| **出力品質** | 720p/1080p/4K 選択可能、ビットレート正確 |
| **パフォーマンス** | 1080p 1分間: <5分で完成 |
| **UI/UX** | 直感的操作、リアルタイムフィードバック |
| **テスト** | 全テスト合格、Lint 0問題 |

---

## 💾 依存パッケージ

| パッケージ | 版 | 用途 |
|-----------|-----|------|
| `ffmpeg_kit_flutter` | ^5.1.0 | FFmpeg 統合 |
| `path_provider` | ^2.0.0 | ファイルパス管理 |
| `video_player` | ^2.8.0 | プレビュー再生 |
| `permission_handler` | ^11.0.0 | ストレージ権限 |

---

## 🎯 次のフェーズ（Phase 25）

本フェーズ完了後:
- **クラウド配信** — Google Drive/iCloud への自動アップロード
- **SNS シェア** — TikTok/YouTube 連携
- **分析機能** — 視聴数/エンゲージメント追跡

---

## 🔗 関連フェーズ

- **Phase 23**: 🔙 ダビングオーディオ録音・管理（完了 ✅）
- **Phase 24**: 🔄 動画合成（本フェーズ）
- **Phase 25**: 🔜 クラウド配信・SNS 連携

---

**準備完了！Phase 24 実装を開始します。**
