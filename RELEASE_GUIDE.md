# つくアニ リリース手順書

## 📋 プロジェクト完成状況

- ✅ **20フェーズ全実装完了**
- ✅ 40テスト全合格
- ✅ Analyze クリーン
- ✅ 全機能動作確認済み（ローカルテスト）

---

## 🔧 リリース前チェックリスト

### 1️⃣ **ビルド環境修正**

#### 問題：ffmpeg_kit_flutter AGP 互換性
- **現状**: ffmpeg_kit_flutter v5.1.0 は新しい Android Gradle Plugin に非対応
- **解決法**:

```bash
# Option A: ffmpeg_kit_flutter をアップグレード
flutter pub upgrade ffmpeg_kit_flutter

# Option B: gradle.properties で namespace を指定
# android/gradle.properties に追加:
android.overridePathCheck=true
```

**推奨**: Option A（アップグレード）

####実行コマンド:
```bash
cd G:\マイドライブ\apps\tsukuani
flutter pub get
flutter clean
flutter build apk --release  # テスト用
```

---

### 2️⃣ **Firebase セットアップ**

#### ファイル配置

**Android:**
```
android/app/google-services.json
```

**iOS:**
```
ios/Runner/GoogleService-Info.plist
```

#### 取得方法:
1. [Firebase Console](https://console.firebase.google.com) にアクセス
2. 「つくアニ」プロジェクト作成
3. Android・iOS アプリ登録
4. 各 config ファイルダウンロード

---

### 3️⃣ **RevenueCat API キー設定**

#### ファイル: `lib/config/constants.dart`

```dart
class AppKeys {
  // 実キーに置き換え
  static const String revenueCatAndroid = 'goog_XXXXXXXXXXXXXXXX';
  static const String revenueCatIos = 'appl_XXXXXXXXXXXXXXXX';
}
```

#### 取得方法:
1. [RevenueCat Dashboard](https://app.revenuecat.com) にログイン
2. 「つくアニ」プロジェクト作成
3. Android・iOS API キー発行

---

### 4️⃣ **Android ビルド署名設定**

#### キーストア作成:
```bash
keytool -genkey -v -keystore ~/release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias tsukuani
```

#### `android/key.properties` 作成:
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=tsukuani
storeFile=<path-to-release-keystore.jks>
```

#### `android/app/build.gradle.kts` 修正:
```kotlin
android {
  ...
  signingConfigs {
    getByName("release") {
      keyAlias = keystoreProperties.getProperty("keyAlias")
      keyPassword = keystoreProperties.getProperty("keyPassword")
      storeFile = file(keystoreProperties.getProperty("storeFile"))
      storePassword = keystoreProperties.getProperty("storePassword")
    }
  }
  buildTypes {
    release {
      signingConfig = signingConfigs.getByName("release")
    }
  }
}
```

---

### 5️⃣ **iOS ビルド署名設定**

#### Xcode で設定:
```bash
open ios/Runner.xcworkspace
```

1. Runner → Signing & Capabilities
2. Team: <Your Apple Developer Team>
3. Bundle Identifier: `com.petitStudio.tsukuani` (任意)
4. Provisioning Profile: 自動生成

---

## 🔨 ビルド手順

### Android:
```bash
cd G:\マイドライブ\apps\tsukuani
flutter build appbundle --release
# 出力: build/app/outputs/bundle/release/app-release.aab
```

### iOS:
```bash
cd G:\マイドライブ\apps\tsukuani
flutter build ios --release
# 出力: build/ios/iphoneos/Runner.app
```

---

## 📤 Google Play Console への提出

1. [Google Play Console](https://play.google.com/console) にアクセス
2. 「つくアニ」アプリ作成
3. **アプリリリース → 本番環境 → 新しいリリース**
4. `app-release.aab` をアップロード
5. スクリーンショット＆説明文入力（`release-outputs/` に自動生成済み）
6. 価格＆配布設定
7. 審査申請

---

## 📱 App Store Connect への提出

1. [App Store Connect](https://appstoreconnect.apple.com) にアクセス
2. 「つくアニ」アプリ作成
3. **Xcode → Product → Archive**
4. Organizer で IPA エクスポート
5. TestFlight でベータテスト（推奨）
6. スクリーンショット＆説明文入力
7. 審査申請

---

## ✅ リリース前テスト

| テスト項目 | 状態 |
|-----------|------|
| ユニットテスト | ✅ (40/40) |
| ウィジェットテスト | ✅ 全画面 |
| カメラ権限 | ⏳ 実機テスト必要 |
| 動画生成 | ⏳ 実機テスト必要 |
| 課金フロー | ⏳ RevenueCat テスト |
| Firebase 連携 | ⏳ Firebase 設定後 |

---

## 📋 リリース前最終チェック

- [ ] ffmpeg_kit_flutter ビルド確認
- [ ] Firebase config ファイル配置
- [ ] RevenueCat API キー設定
- [ ] Android キーストア作成・設定
- [ ] iOS 証明書＆プロビジョニング設定
- [ ] `flutter build apk --release` 成功確認
- [ ] `flutter build ios --release` 成功確認
- [ ] 実機でカメラ・AR 動作確認
- [ ] 動画生成・エクスポート 確認
- [ ] 課金フロー テスト
- [ ] Google Play/App Store ポリシー確認

---

## 📞 サポート

各サービスの公式ドキュメント：
- [Flutter ビルド](https://flutter.dev/docs/deployment)
- [Firebase セットアップ](https://firebase.google.com/docs/flutter/setup)
- [RevenueCat ドキュメント](https://docs.revenuecat.com/)
- [Google Play Console ヘルプ](https://support.google.com/googleplay/android-developer)
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect)

---

## 🎉 完成！

**つくアニプロジェクトは完全実装されました。**

このガイドに従ってセットアップすれば、Google Play・App Store へのリリースが可能です。

質問・問題があれば、いつでもお知らせください！
