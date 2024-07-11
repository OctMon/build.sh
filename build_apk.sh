cd $1

flutter clean

flutter packages get

if [[ -n $3 ]]; then

    echo "🗂️  $3"

    flutter build apk --target-platform android-arm64 --dart-define=app-channel=$3 --obfuscate --split-debug-info=symbols
    mv build/app/outputs/apk/release/app-release.apk build/app/outputs/apk/release/$3.apk
    open build/app/outputs/apk/release

    say "$3打包成功"

else

  if [[ $2 == "channel" ]]; then

      echo "🎁  $2"
      mkdir channel

      build_apk(){
          flutter build apk --target-platform android-arm64 --dart-define=app-channel=$1 --obfuscate --split-debug-info=symbols
      }

      build_apk xiaomi
      build_apk huawei
      build_apk yingyongbao
      build_apk vivo
      build_apk oppo
      build_apk meizu
      build_apk m360
      build_apk samsung

      zip -r -m -P octmon channel.zip channel

      open .

      say "渠道包打包成功"

  else

      echo "📦  $2"
      # flutter build appbundle --obfuscate --split-debug-info=symbols
      flutter build appbundle --target-platform android-arm64 --obfuscate --split-debug-info=symbols
      open build/app/outputs/bundle/release

      say "aab打包成功"
  fi

fi
