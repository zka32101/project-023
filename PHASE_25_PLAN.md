# Phase 25 実装計画
## ビデオ合成結果の管理・共有 (Video Management & Sharing)

**フェーズ**: Phase 25  
**開発期間**: 1-2週間  
**目標**: Phase 24で生成したビデオの保存、管理、プレビュー、SNS共有機能の実装

---

## 📋 実装内容

### Day 1-2: ビデオ保存・メタデータ管理

#### 1.1 ビデオ保存サービス
**ファイル**: `lib/services/video_storage_service.dart`

**機能**:
- FFmpegで生成したビデオをアプリフォルダに保存
- メタデータ（作成日時、解像度、ファイルサイズ）の管理
- ファイルシステムのパス管理
- ストレージスペース監視

```dart
class VideoStorageService {
  // ビデオ保存
  Future<SavedVideo> saveVideo(String tempPath, String projectName)
  
  // メタデータ取得
  Future<VideoMetadata> getVideoMetadata(String videoPath)
  
  // ストレージ使用量
  Future<StorageInfo> getStorageInfo()
  
  // ビデオ削除
  Future<void> deleteVideo(String videoId)
}
```

#### 1.2 ビデオライブラリ管理
**ファイル**: `lib/services/video_library_service.dart`

**機能**:
- 生成されたビデオの一覧管理
- プロジェクト別のビデオ分類
- 検索・フィルタリング機能
- サムネイル生成と管理

---

### Day 3-4: ビデオプレビュー & UI コンポーネント

#### 2.1 ビデオプレビュー画面
**ファイル**: `lib/screens/video_preview_screen.dart`

**機能**:
- フルスクリーン再生
- 再生コントロール（再生・一時停止・シーク）
- メタデータ表示（解像度、ファイルサイズ、作成日時）
- 削除・共有ボタン
- 品質情報表示

#### 2.2 ビデオライブラリウィジェット
**ファイル**: `lib/widgets/video_library_grid.dart`

**機能**:
- ビデオのグリッド表示
- サムネイル表示
- 再生ボタン
- 長押しメニュー（削除・共有・詳細情報）

#### 2.3 SNS共有ウィジェット
**ファイル**: `lib/widgets/social_share_dialog.dart`

**機能**:
- プラットフォーム選択（Twitter/Instagram/Facebook/TikTok）
- ビデオをギャラリーに保存
- share_plus による共有
- 共有テキスト編集

---

### Day 5: テスト & 統合

#### 3.1 ユニットテスト
**ファイル**: `test/unit/services/video_storage_service_test.dart`

**テスト内容**:
- ビデオ保存機能
- メタデータ管理
- ストレージ操作
- ファイルシステム管理

#### 3.2 ウィジェットテスト
**ファイル**: `test/widget/video_preview_screen_test.dart`

**テスト内容**:
- 再生コントロール機能
- メタデータ表示
- 共有ダイアログ
- UI レスポンシブ性

#### 3.3 統合テスト
**テスト内容**:
- 動画作成→保存→表示→共有のフルパイプライン
- 複数ビデオの管理
- エラーハンドリング

---

## 📦 依存パッケージ

既存で使用可能:
- `video_player: ^2.8.0` (ビデオ再生)
- `share_plus: ^10.0.0` (SNS共有)
- `path_provider: ^2.1.0` (ファイルパス管理)
- `image_gallery_saver: ^2.0.3` (ギャラリー保存)

---

## 🎯 成功基準

✅ ビデオ保存機能が正常に動作  
✅ ビデオライブラリが最大100個のビデオを管理  
✅ プレビュー画面が安定して再生  
✅ SNS共有が全プラットフォームで動作  
✅ 90%以上のテストカバレッジ  
✅ ストレージ使用量が正確に計測  

---

## 🔧 実装の流れ

```
Day 1-2: サービス層
  ├─ VideoStorageService (保存・管理)
  └─ VideoLibraryService (ライブラリ管理)

Day 3-4: UI層
  ├─ VideoPreviewScreen (プレビュー)
  ├─ VideoLibraryGrid (グリッド表示)
  └─ SocialShareDialog (共有)

Day 5: テスト & 統合
  ├─ ユニットテスト (40+ テスト)
  ├─ ウィジェットテスト (20+ テスト)
  └─ 統合テスト
```

---

## 📊 期待される効果

- ユーザーが生成したビデオを簡単に管理できる
- SNS上での共有が容易になり、バイラル性が向上
- アプリの保有時間が延長
- ユーザーの再利用率が増加

---

## 🚀 Next Phase 26 予定

- クラウドストレージ連携（Google Drive/iCloud）
- ビデオアップロード機能
- ビデオランキング・コミュニティ機能
