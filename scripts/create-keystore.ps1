# つくアニ Android Release Keystore 作成スクリプト
# Requires: keytool (included with Java JDK)

param(
    [string]$password = "",
    [string]$outputPath = "$env:USERPROFILE\.android\tsukuani-release-keystore.jks"
)

if ([string]::IsNullOrEmpty($password)) {
    Write-Host "エラー: パスワードを指定してください" -ForegroundColor Red
    Write-Host "使用法: .\create-keystore.ps1 -password 'your-secure-password'"
    exit 1
}

Write-Host "キーストアを作成しています..." -ForegroundColor Green
Write-Host "出力先: $outputPath"

# keytool コマンド実行
& keytool -genkey -v -keystore "$outputPath" `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias tsukuani `
    -storepass "$password" `
    -keypass "$password" `
    -dname "CN=Petit Studio, OU=Development, O=Petit Studio, L=Tokyo, ST=Tokyo, C=JP"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ キーストア作成完了！" -ForegroundColor Green
    Write-Host ""
    Write-Host "次のステップ：" -ForegroundColor Yellow
    Write-Host "1. android/key.properties ファイルを作成："
    Write-Host "   storeFile=$outputPath"
    Write-Host "   storePassword=$password"
    Write-Host "   keyAlias=tsukuani"
    Write-Host "   keyPassword=$password"
} else {
    Write-Host "❌ キーストア作成失敗" -ForegroundColor Red
    exit 1
}
