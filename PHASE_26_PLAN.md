# Phase 26 実装計画
## クラウド配信・SNS連携 (Cloud Distribution & Community Features)

**フェーズ**: Phase 26  
**開発期間**: 1-2週間  
**目標**: ビデオのクラウド保存、SNS統合、コミュニティ機能の実装

---

## 📋 実装内容

### Day 1-2: クラウドストレージ統合

#### 1.1 クラウドストレージサービス
**ファイル**: `lib/services/cloud_storage_service.dart`

**機能**:
- Google Drive 連携（oauth2 パッケージ）
- iCloud 連携（CloudKit）
- ビデオのアップロード機能
- ビデオのダウンロード機能
- ストレージ容量管理
- 同期状態管理

```dart
class CloudStorageService {
  // Google Drive 操作
  Future<void> uploadToGoogleDrive(SavedVideo video)
  Future<void> downloadFromGoogleDrive(String driveFileId)
  
  // iCloud 操作
  Future<void> uploadToICloud(SavedVideo video)
  Future<void> downloadFromICloud(String iCloudFileId)
  
  // 容量管理
  Future<CloudStorageQuota> getStorageQuota()
  Future<List<CloudVideo>> listCloudVideos()
  
  // 同期
  Future<void> syncVideos()
}
```

#### 1.2 クラウドビデオモデル
**ファイル**: `lib/models/cloud_video.dart`

**クラス**:
- `CloudVideo` - クラウド上のビデオ情報
- `CloudStorageQuota` - ストレージ容量情報
- `SyncStatus` - 同期ステータス

---

### Day 3-4: ビデオランキング & コミュニティ機能

#### 2.1 ビデオランキングシステム
**新規ファイル**: `lib/services/video_ranking_service.dart`

**機能**:
- ビデオの視聴回数追跡
- いいね機能
- シェア数カウント
- 日間・週間・月間ランキング
- トレンド分析

```dart
class VideoRankingService {
  // ランキング取得
  Future<List<RankedVideo>> getDailyRanking()
  Future<List<RankedVideo>> getWeeklyRanking()
  Future<List<RankedVideo>> getMonthlyRanking()
  
  // 統計更新
  Future<void> incrementViewCount(String videoId)
  Future<void> addLike(String videoId)
  Future<void> addShare(String videoId)
  
  // ユーザーランキング
  Future<List<UserRanking>> getCreatorRanking()
}
```

#### 2.2 ビデオコメント & レビュー
**新規ファイル**: `lib/services/video_comments_service.dart`

**機能**:
- コメント投稿・削除
- いいね機能
- ユーザーレビュー
- コメント通知

#### 2.3 ビデオシェアリング統計
**新規ファイル**: `lib/services/share_analytics_service.dart`

**機能**:
- シェア数追跡
- シェアプラットフォーム分析
- ユーザーエンゲージメント計測
- バイラル指数計算

---

### Day 3-4: ユーザープロフィール & フォロー機能

#### 3.1 ユーザープロフィールサービス
**新規ファイル**: `lib/services/user_profile_service.dart`

**機能**:
- プロフィール情報管理
- 作品一覧表示
- フォロワー管理
- バッジシステム

```dart
class UserProfileService {
  Future<UserProfile> getUserProfile(String userId)
  Future<void> updateProfile(UserProfile profile)
  Future<void> followUser(String userId)
  Future<void> unfollowUser(String userId)
  Future<List<UserProfile>> getFollowers(String userId)
}
```

#### 3.2 ユーザープロフィール画面
**新規ファイル**: `lib/screens/user_profile_screen.dart`

**機能**:
- プロフィール表示
- 作品グリッド
- フォロー・フォロワー表示
- 統計情報（総再生数、総いいね数）

---

### Day 5: テスト & 統合

#### 4.1 ユニットテスト
**ファイル**: 
- `test/unit/services/cloud_storage_service_test.dart`
- `test/unit/services/video_ranking_service_test.dart`
- `test/unit/services/video_comments_service_test.dart`
- `test/unit/services/share_analytics_service_test.dart`
- `test/unit/services/user_profile_service_test.dart`

#### 4.2 ウィジェットテスト
**ファイル**:
- `test/widget/user_profile_screen_test.dart`
- `test/widget/ranking_list_test.dart`
- `test/widget/comments_section_test.dart`

#### 4.3 統合テスト
**ファイル**:
- `test/integration/community_features_workflow_test.dart`
- `test/integration/cloud_sync_workflow_test.dart`

---

## 📁 新規ファイル一覧

```
lib/
├── services/
│   ├── cloud_storage_service.dart       # クラウドストレージ統合
│   ├── video_ranking_service.dart       # ランキング機能
│   ├── video_comments_service.dart      # コメント機能
│   ├── share_analytics_service.dart     # シェア分析
│   └── user_profile_service.dart        # プロフィール管理
│
├── models/
│   ├── cloud_video.dart                 # クラウドビデオモデル
│   ├── user_profile.dart                # ユーザープロフィール
│   ├── video_ranking.dart               # ランキングモデル
│   ├── video_comment.dart               # コメントモデル
│   └── share_analytics.dart             # シェア分析モデル
│
├── screens/
│   ├── ranking_screen.dart              # ランキング表示
│   ├── user_profile_screen.dart         # ユーザープロフィール
│   └── community_feed_screen.dart       # コミュニティフィード
│
└── widgets/
    ├── ranking_list.dart                # ランキングリスト
    ├── comments_section.dart            # コメントセクション
    ├── user_card.dart                   # ユーザーカード
    └── engagement_stats.dart            # エンゲージメント統計

test/
├── unit/services/
│   ├── cloud_storage_service_test.dart
│   ├── video_ranking_service_test.dart
│   ├── video_comments_service_test.dart
│   ├── share_analytics_service_test.dart
│   └── user_profile_service_test.dart
├── widget/
│   ├── user_profile_screen_test.dart
│   ├── ranking_list_test.dart
│   └── comments_section_test.dart
└── integration/
    ├── community_features_workflow_test.dart
    └── cloud_sync_workflow_test.dart
```

---

## 🧪 テスト計画

### ユニットテスト (50+ tests)
- クラウドストレージ操作
- ランキング計算
- コメント管理
- 分析データ処理
- プロフィール操作

### ウィジェットテスト (30+ tests)
- プロフィール表示
- ランキング表示
- コメント表示
- UI レスポンシブ性

### 統合テスト (40+ tests)
- クラウド同期ワークフロー
- コミュニティ機能統合
- ユーザーインタラクション
- エンドツーエンド

---

## 📦 依存パッケージ

| パッケージ | 版 | 用途 |
|-----------|-----|------|
| `google_sign_in` | ^6.0.0 | Google 認証 |
| `googleapis` | ^11.0.0 | Google Drive API |
| `cloud_firestore` | ^4.0.0 | ランキング・コメント保存 |
| `firebase_auth` | ^4.0.0 | ユーザー認証 |
| `connectivity_plus` | ^4.0.0 | ネットワーク状態監視 |

---

## 🎯 成功基準

| 項目 | 基準 |
|------|------|
| **クラウドアップロード** | 安定した Google Drive/iCloud 連携 |
| **ランキング機能** | リアルタイム更新、正確な計算 |
| **コメント機能** | 投稿・削除・表示が動作 |
| **プロフィール** | ユーザー情報表示と編集が可能 |
| **テスト** | 120+ テスト全合格 |
| **パフォーマンス** | クラウド同期 <5秒、ランキング読み込み <2秒 |

---

## 🔧 実装の流れ

```
Day 1-2: クラウド統合
  ├─ CloudStorageService (Google Drive, iCloud)
  └─ CloudVideo モデル

Day 3-4: コミュニティ機能
  ├─ VideoRankingService (ランキング)
  ├─ VideoCommentsService (コメント)
  ├─ UserProfileService (プロフィール)
  └─ UI コンポーネント

Day 5: テスト & 統合
  ├─ ユニットテスト (50+ テスト)
  ├─ ウィジェットテスト (30+ テスト)
  └─ 統合テスト (40+ テスト)
```

---

## 📊 期待される効果

- ユーザーが作品をクラウドで安全に保存できる
- ランキング機能がユーザーの競争心を刺激
- コミュニティ機能でユーザー間の交流が増加
- プロフィール機能でクリエイターのブランド構築が可能
- アプリのエンゲージメントが向上

---

## 🚀 Next Phase 27 予定

- AI キャラクター生成（画像 → AR キャラ）
- リアルタイム協調編集（複数ユーザー同時作成）
- オフラインモード拡張

---

## 🔗 関連フェーズ

- **Phase 25**: 🔙 ビデオ管理・共有（完了 ✅）
- **Phase 26**: 🔄 クラウド配信・コミュニティ（本フェーズ）
- **Phase 27**: 🔜 AI・協調編集機能

---

**準備完了！Phase 26 実装を開始します。**
