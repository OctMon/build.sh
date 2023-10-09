cd $1


echo $2

flutter clean

flutter packages get

flutter build ipa --obfuscate --split-debug-info=symbols

#  apikey 为密钥ID, apiIssure 为 Issuer Id
# ·验证成功后会提示 No errors validating ……
# ·上传成功会提示 No errors uploading ……

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)
apiKey=$(cat pubspec.yaml | grep "apiKey: " | awk '{print $2}')
apiIssure=$(cat pubspec.yaml | grep "apiIssure: " | awk '{print $2}')
ipa="build/ios/ipa/$name.ipa"

if [[ $2 == "validate" ]]; then
  echo "🌞$2"
    # 验证
    xcrun altool --validate-app -f $ipa -t ios --apiKey $apiKey --apiIssuer $apiIssure --verbose
else
    echo "🚀$2"
    # 上传
    xcrun altool --upload-app -f $ipa -t ios --apiKey $apiKey --apiIssuer $apiIssure --verbose
fi

say "上传Appstore成功"