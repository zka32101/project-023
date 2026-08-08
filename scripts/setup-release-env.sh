#!/bin/bash

# つくアニ リリース環境セットアップスクリプト
# 用途: Firebase, RevenueCat キー, ビルド設定を確認・準備

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔧 つくアニ リリース環境セットアップ"
echo "=================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Flutter 環境確認
echo "📱 Flutter 環境確認..."
flutter --version > /dev/null 2>&1 && echo -e "${GREEN}✓${NC} Flutter インストール済み" || {
    echo -e "${RED}✗${NC} Flutter がインストールされていません"
    exit 1
}

# 2. Java/Gradle 確認
echo "☕ Java/Gradle 環境確認..."
which keytool > /dev/null 2>&1 && echo -e "${GREEN}✓${NC} keytool インストール済み" || {
    echo -e "${YELLOW}⚠${NC} keytool (Java JDK) がインストールされていません"
    echo "   ダウンロード: https://www.oracle.com/java/technologies/downloads/"
}

# 3. Firebase config ファイル確認
echo ""
echo "🔥 Firebase config ファイル確認..."
if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✓${NC} android/app/google-services.json 存在"
else
    echo -e "${YELLOW}⚠${NC} android/app/google-services.json がありません"
    echo "   テンプレート: android/app/google-services.json.template"
    echo "   Firebase Console から実ファイルをダウンロードしてください"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✓${NC} ios/Runner/GoogleService-Info.plist 存在"
else
    echo -e "${YELLOW}⚠${NC} ios/Runner/GoogleService-Info.plist がありません"
    echo "   テンプレート: ios/Runner/GoogleService-Info.plist.template"
fi

# 4. RevenueCat キー確認
echo ""
echo "💰 RevenueCat API キー確認..."
REVENUE_CAT_KEY=$(grep "revenueCat" lib/config/constants.dart | grep -o "'[^']*'" | head -1 | tr -d "'")
if [ "$REVENUE_CAT_KEY" = "REVENUECAT_ANDROID_API_KEY" ] || [ "$REVENUE_CAT_KEY" = "REVENUECAT_IOS_API_KEY" ]; then
    echo -e "${YELLOW}⚠${NC} RevenueCat API キーがプレースホルダーのままです"
    echo "   ファイル: lib/config/constants.dart"
    echo "   実キーに置き換えてください"
else
    echo -e "${GREEN}✓${NC} RevenueCat キー設定済み"
fi

# 5. Android キーストア確認
echo ""
echo "🔐 Android キーストア確認..."
if [ -f "android/key.properties" ]; then
    echo -e "${GREEN}✓${NC} android/key.properties 存在"
else
    echo -e "${YELLOW}⚠${NC} android/key.properties がありません"
    echo "   テンプレート: android/key.properties.template"
    echo "   キーストア作成コマンド:"
    echo "   ${YELLOW}pwsh scripts/create-keystore.ps1 -password 'your-password'${NC}"
fi

# 6. ビルド構成確認
echo ""
echo "🏗️  ビルド構成確認..."
if grep -q "isMinifyEnabled = true" android/app/build.gradle.kts; then
    echo -e "${GREEN}✓${NC} Minification 有効"
else
    echo -e "${YELLOW}⚠${NC} Minification が無効です"
fi

# 7. リリース資料確認
echo ""
echo "📄 リリース資料確認..."
RELEASE_FILES=(
    "release-outputs/SECURITY_POLICY.md"
    "release-outputs/PRIVACY_POLICY.md"
    "release-outputs/RELEASE_CHECKLIST.md"
    "RELEASE_GUIDE.md"
    "PROJECT_SUMMARY.md"
)

for file in "${RELEASE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (見つかりません)"
    fi
done

# 8. テスト実行オプション
echo ""
echo "✅ セットアップ確認完了！"
echo ""
echo "次のステップ:"
echo ""
echo "1️⃣  Firebase 設定:"
echo "   - Firebase Console から config ファイルダウンロード"
echo "   - android/app/google-services.json 配置"
echo "   - ios/Runner/GoogleService-Info.plist 配置"
echo ""
echo "2️⃣  RevenueCat 設定:"
echo "   - RevenueCat Dashboard からキー取得"
echo "   - lib/config/constants.dart の値を置き換え"
echo ""
echo "3️⃣  Android キーストア作成:"
echo "   pwsh scripts/create-keystore.ps1 -password 'your-password'"
echo ""
echo "4️⃣  ビルドテスト:"
echo "   flutter clean"
echo "   flutter pub get"
echo "   flutter build appbundle --release  # Android"
echo "   flutter build ios --release        # iOS"
echo ""
echo "5️⃣  リリース:"
echo "   - Google Play Console に提出"
echo "   - App Store Connect に提出"
echo ""
echo "詳細は ${YELLOW}RELEASE_GUIDE.md${NC} を参照してください！"
