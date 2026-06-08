cd $1

get_pubspec_value() {
    local key="$1"
    awk -F ': ' -v search_key="$key" '$1 == search_key {print $2; exit}' pubspec.yaml
}

decode_base64_to_file() {
    local base64_content="$1"
    local output_path="$2"
    if ! printf '%s' "$base64_content" | base64 --decode >"$output_path" 2>/dev/null; then
        printf '%s' "$base64_content" | base64 -D >"$output_path"
    fi
}

echo $2

fvm flutter clean

fvm flutter packages get

fvm flutter build macos --dart-define=git-branch=$(git rev-parse --abbrev-ref HEAD) --dart-define=git-commit=$(git rev-parse --short HEAD) --dart-define=app-channel=appstore --obfuscate --split-debug-info=symbols

# appstore_api_key 为密钥ID, appstore_api_issuer 为 Issuer Id
# 验证成功后会提示 No errors validating ......
# 上传成功会提示 No errors uploading ......

name=$(get_pubspec_value "name")
appstore_api_key=$(get_pubspec_value "appstore_api_key")
appstore_api_issuer=$(get_pubspec_value "appstore_api_issuer")
appstore_base64_content=$(get_pubspec_value "appstore_base64_content")

export_options_plist="build/macos/ExportOptions.plist"
archive_path="build/macos/Runner.xcarchive"
export_path="build/macos"
temp_p8_file="$(mktemp "${TMPDIR:-/tmp}/AuthKey_${appstore_api_key}.XXXXXX.p8")"

cleanup() {
    rm -f "$temp_p8_file"
}

trap cleanup EXIT INT TERM

if [[ -z "$appstore_api_key" ]]; then
    echo "缺少 appstore_api_key 配置" >&2
    exit 1
fi

if [[ -z "$appstore_api_issuer" ]]; then
    echo "缺少 appstore_api_issuer 配置" >&2
    exit 1
fi

if [[ -z "$appstore_base64_content" ]]; then
    echo "缺少 appstore_base64_content 配置" >&2
    exit 1
fi

if ! decode_base64_to_file "$appstore_base64_content" "$temp_p8_file"; then
    echo "appstore_base64_content base64 解码失败" >&2
    exit 1
fi

if [[ ! -s "$temp_p8_file" ]]; then
    echo "appstore_base64_content 解码后为空文件" >&2
    exit 1
fi

if ! grep -q "BEGIN PRIVATE KEY" "$temp_p8_file" || ! grep -q "END PRIVATE KEY" "$temp_p8_file"; then
    echo "appstore_base64_content 解码结果不是有效的 p8 私钥" >&2
    exit 1
fi

if [ ! -f "$export_options_plist" ]; then
    echo "缺少 $export_options_plist, 自动生成基础模板"
    mkdir -p "$(dirname "$export_options_plist")"
    cat > "$export_options_plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
EOF
fi

echo "生成 macOS App Store 包..."
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Release -archivePath "$archive_path" archive
mkdir -p "$export_path"
xcodebuild -exportArchive -archivePath "$archive_path" -exportPath "$export_path" -exportOptionsPlist "$export_options_plist"
export_status=$?
if [ $export_status -ne 0 ]; then
    echo "xcodebuild -exportArchive 失败，请检查输出日志"
    exit $export_status
fi

pkg=$(find "$export_path" -maxdepth 1 -name "*.pkg" | head -n 1)
if [ -z "$pkg" ]; then
    echo "未找到导出的 .pkg 文件，导出目录内容如下："
    ls -la "$export_path"
    exit 1
fi

if [[ $2 == "validate" ]]; then
    echo "🌞$2"
    # 验证
    xcrun altool --validate-app -f "$pkg" -t osx --apiKey "$appstore_api_key" --apiIssuer "$appstore_api_issuer" --p8-file-path "$temp_p8_file" --verbose
else
    echo "🚀$2"
    # 上传
    xcrun altool --upload-app -f "$pkg" -t osx --apiKey "$appstore_api_key" --apiIssuer "$appstore_api_issuer" --p8-file-path "$temp_p8_file" --verbose
fi

say "上传Appstore成功"
