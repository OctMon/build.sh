cd $1


echo $2

flutter clean

flutter packages get

flutter build ipa --dart-define=app-channel=appstore --obfuscate --split-debug-info=symbols

#  appstore_api_key 为密钥ID, appstore_api_issure 为 Issuer Id
# ·验证成功后会提示 No errors validating ……
# ·上传成功会提示 No errors uploading ……

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)
appstore_api_key=$(cat pubspec.yaml | grep "appstore_api_key: " | awk '{print $2}')
appstore_api_issure=$(cat pubspec.yaml | grep "appstore_api_issure: " | awk '{print $2}')
ipa="build/ios/ipa/$name.ipa"

if [[ $2 == "validate" ]]; then
    echo "🌞$2"
    # 验证
    xcrun altool --validate-app -f $ipa -t ios --apiKey $appstore_api_key --apiIssuer $appstore_api_issure --verbose
else
    echo "🚀$2"
    # 上传
    xcrun altool --upload-app -f $ipa -t ios --apiKey $appstore_api_key --apiIssuer $appstore_api_issure --verbose
fi

say "上传Appstore成功"