cd $1


echo $2

fvm flutter clean

fvm flutter packages get

fvm flutter build ipa --dart-define=git-branch=$(git rev-parse --abbrev-ref HEAD) --dart-define=git-commit=$(git rev-parse --short HEAD) --dart-define=app-channel=appstore --obfuscate --split-debug-info=symbols

#  appstore_api_key 为密钥ID, appstore_api_issuer 为 Issuer Id
# ·验证成功后会提示 No errors validating ……
# ·上传成功会提示 No errors uploading ……

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)
appstore_api_key=$(cat pubspec.yaml | grep "appstore_api_key: " | awk '{print $2}')
appstore_api_issuer=$(cat pubspec.yaml | grep "appstore_api_issuer: " | awk '{print $2}')
ipa="build/ios/ipa/$name.ipa"

if [[ $2 == "validate" ]]; then
    echo "🌞$2"
    # 验证
    xcrun altool --validate-app -f $ipa -t ios --apiKey $appstore_api_key --apiIssuer $appstore_api_issuer --verbose
else
    echo "🚀$2"
    # 上传
    xcrun altool --upload-app -f $ipa -t ios --apiKey $appstore_api_key --apiIssuer $appstore_api_issuer --verbose
fi

say "上传Appstore成功"