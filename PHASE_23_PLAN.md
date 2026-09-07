# Phase 23 実装計画
## アフレコスタジオ（Dubbing Studio）- 音声録音 + 合成

**フェーズ**: Phase 23  
**開発期間**: 1-2週間  
**目標**: 音声録音・管理・タイミング調整機能の実装

---

## 📋 実装内容

### 1. 音声録音機能（Voice Recording）

#### 1.1 録音サービス
**ファイル**: `lib/services/audio_recording_service.dart`

**機能**:
- マイクからの音声入力キャプチャ
- WAV/MP3 形式での保存
- 録音の一時停止/再開
- 音量レベル検出

#### 1.2 音声再生機能
**ファイル**: `lib/services/audio_playback_service.dart`

**機能**:
- MP3/WAV 再生
- 再生位置の制御
- 音量調整
- ループ再生

---

### 2. アフレコスタジオUI

#### 2.1 録音画面
**新規ファイル**: `lib/screens/dubbing_studio_screen.dart`

**機能**:
- 波形表示（Visual feedback）
- 録音ボタン（開始/停止/一時停止）
- 音量メーター表示
- 再生プレビュー
- タイムライン表示

#### 2.2 トラック管理
**新規ファイル**: `lib/widgets/audio_track_list.dart`

**機能**:
- 複数トラック管理
- トラック削除/編集
- ボリュームコントロール
- ミュート/ソロ機能

#### 2.3 タイミング調整
**新規ファイル**: `lib/widgets/timing_adjustment_widget.dart`

**機能**:
- フレーム単位でのタイミング調整
- キーフレーム設定
- 同期点マーカー

---

### 3. データモデル拡張

#### 3.1 AudioTrack モデル
```dart
class AudioTrack {
  final String id;
  final String name;
  final String audioPath;
  final int startFrame;        // アニメーションのどのフレームから再生
  final double volume;
  final bool isMuted;
  final DateTime createdAt;
  final int duration;          // ミリ秒
}
```

#### 3.2 DubbingProject モデル
```dart
class DubbingProject {
  final String id;
  final String characterId;    // CustomCharacter への参照
  final String projectName;
  final List<AudioTrack> tracks;
  final int fps;               // アニメーション FPS
  final int totalFrames;
  final DateTime createdAt;
}
```

---

### 4. 機能フロー

```
カスタムキャラ選択
  ↓
「アフレコを追加」
  ↓
DubbingStudioScreen
  ├─ 波形表示
  ├─ 録音コントロール
  ├─ 音量メーター
  └─ 再生プレビュー
  ↓
オーディオトラック保存
  ↓
タイミング調整
  ↓
完成 → DubbingProject 保存
```

---

## 📁 新規ファイル一覧

```
lib/
├── screens/
│   └── dubbing_studio_screen.dart        # アフレコスタジオメイン画面
│
├── widgets/
│   ├── audio_track_list.dart             # トラック管理
│   ├── timing_adjustment_widget.dart     # タイミング調整
│   ├── waveform_painter.dart             # 波形描画
│   └── volume_meter.dart                 # 音量メーター
│
├── services/
│   ├── audio_recording_service.dart      # 録音機能
│   └── audio_playback_service.dart       # 再生機能
│
├── models/
│   ├── audio_track.dart                  # オーディオトラックモデル
│   └── dubbing_project.dart              # ダビングプロジェクトモデル
│
└── providers/
    └── dubbing_project_provider.dart     # 状態管理
```

---

## ✅ 実装順序

### Day 1-2: 音声録音 & 再生基盤
- [ ] AudioRecordingService 実装
- [ ] AudioPlaybackService 実装
- [ ] 音声ファイル I/O

### Day 3-4: UI コンポーネント
- [ ] DubbingStudioScreen 実装
- [ ] 波形表示（WaveformPainter）
- [ ] 音量メーター表示

### Day 5: タイミング調整 & 統合
- [ ] タイミング調整ウィジェット
- [ ] フレーム同期ロジック
- [ ] 完全なフロー統合 & テスト

---

## 🧪 テスト計画

### ユニットテスト
- [ ] AudioRecordingService (録音/保存)
- [ ] AudioPlaybackService (再生制御)
- [ ] タイミング計算ロジック

### ウィジェットテスト
- [ ] 波形描画の正確性
- [ ] 再生コントロール
- [ ] UI レスポンス

### 統合テスト
- [ ] 完全な録音→再生フロー
- [ ] タイミング同期の精度

---

## 📊 成功基準

| 項目 | 基準 |
|------|------|
| **録音機能** | マイク入力正常、ファイル保存成功 |
| **再生機能** | スムーズ再生、音量制御正常 |
| **UI/UX** | 直感的操作、リアルタイムフィードバック |
| **タイミング** | ±1フレーム精度での同期 |
| **テスト** | 全テスト合格、Lint 0問題 |

---

## 💾 依存パッケージ

| パッケージ | 版 | 用途 |
|-----------|-----|------|
| `record` | ^5.0.0 | 音声録音 |
| `audioplayers` | ^6.0.0+ | 音声再生 |
| `audio_waveforms` | ^0.6.0+ | 波形表示（オプション） |

---

## 🎯 次のフェーズ（Phase 24）

本フェーズ完了後:
- **動画合成** — アニメーション + オーディオの統合
- 出力フォーマット (MP4, WebM など)
- クラウド配信対応

---

**準備完了！Phase 23 実装を開始します。**
