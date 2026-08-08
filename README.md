# つくアニ（Tsukuani）— AR 動画クリエーター

親子が一緒にコマ撮り動画を作ることで、子どもの創造力と表現力が自然に育つアプリ。

## 概要

- **対象:** 小学生（6～12歳）＋ 保護者
- **プラットフォーム:** iOS 12+、Android 8+
- **価格:** ¥600 買い切り（1時間無料体験）
- **リリース:** 2026年8月

## セットアップ

### 前提条件

- Flutter 3.16+
- Dart 3.x
- iOS: Xcode 14+
- Android: Android Studio Flamingo+

### インストール

\`\`\`bash
flutter pub get
cd ios && pod repo update && pod install && cd ..
\`\`\`

### Firebase・RevenueCat セットアップ

1. Firebase Console でプロジェクト作成
2. GoogleService-Info.plist / google-services.json をダウンロード
3. RevenueCat API Key を設定

## 実行

\`\`\`bash
flutter run
flutter test                 # Unit/Widget テスト
flutter build apk --release  # Android ビルド
flutter build ios --release  # iOS ビルド
\`\`\`

## プロジェクト構成

```
lib/
├── config/              # Constants, Theme
├── models/              # Data models
├── services/            # Firebase, AR, Video, Analytics
├── providers/           # Riverpod state (7 providers)
├── screens/             # UI screens (7 screens)
├── widgets/             # Lottie, Haptic feedback
└── utils/               # Logger, Error handling

assets/
├── animations/          # Lottie JSON
├── ar_models/           # 3D models
├── images/              # UI images
└── data/                # characters.json

.github/workflows/       # CI/CD (GitHub Actions)
test/                    # Unit/Widget/Integration tests
```

## 実装進捗

| Week | Phase | Status |
|------|-------|--------|
| 1-2 | プロジェクト初期化 | ✅ |
| 2-3 | Service 層 | ✅ |
| 3-4 | Riverpod Providers | ✅ |
| 4-5 | Aha Moment フロー（5画面） | ✅ |
| 5-6 | ペイウォール・図鑑・Lottie | ✅ |
| 6-7 | テスト・ブラッシング | ✅ |
| 7-8 | CI/CD・リリース準備 | ✅ |

## CI/CD パイプライン

- **flutter_analyze.yml** — Code quality
- **flutter_test.yml** — Unit/Widget tests
- **build_android.yml** — APK/AAB build
- **build_ios.yml** — iOS build & TestFlight

## KPI

- KR1: Day7 リテンション 30%+
- KR2: 動画書き出し完了率 60%+ ⭐ 最重要
- KR3: コンバージョン率 8%+
- KR4: 図鑑閲覧率 50%+

## サポート

- GitHub Issues: https://github.com/petit-works/tsukuani/issues
- Email: support@petit-works.com

Made with ❤️ by Petit Works
