cd $1

fvm flutter clean

fvm flutter packages get

apk_path="build/app/outputs/apk/release/"
apk_file="${apk_path}app-release.apk"

if [[ -n $3 ]]; then
  echo "🗂️  $3"
  fvm flutter build apk --target-platform android-arm64 --dart-define=app-channel=$3 --obfuscate --split-debug-info=symbols
  if [ -f "$apk_file" ]; then
    echo "$apk_file exists."
    mv $apk_file $apk_path$3.apk
    open $apk_path
    say "$3打包成功"
  else
    echo "$apk_file does not exist."
    say "$3打包失败"
  fi
else
  if [[ $2 == "channel" ]]; then
    echo "🎁 $2"
    rm -rf channel
    rm -rf channel.zip
    mkdir channel
    build_apk(){
      echo "build $1 ..."
      fvm flutter build apk --target-platform android-arm64 --dart-define=app-channel=$1 --obfuscate --split-debug-info=symbols
    }

    channel_packages=$(cat pubspec.yaml | grep "channel_packages: " | awk '{print $2}')
    if [[ -n $channel_packages ]]; then
      echo "🗂️  -> $channel_packages"
      # 将字符串转换为数组
      IFS=',' read -r -a array <<< "$channel_packages"
      for item in "${array[@]}"; do
        build_apk $item
        if [ -f "$apk_file" ]; then
            mv $apk_file channel/$item.apk
          else
            break  # 中途退出循环
        fi
      done

      if [ "$(ls -A channel)" ]; then
        zip -r -m -P octmon channel.zip channel
        open .
        say "渠道包打包成功"
      else
        say "渠道包打包失败"
      fi
    else
      say "未配置渠道"
    fi

  else
    echo "📦 $2"
    # fvm flutter build appbundle --obfuscate --split-debug-info=symbols
    fvm flutter build appbundle --target-platform android-arm64 --obfuscate --split-debug-info=symbols
    open build/app/outputs/bundle/release
    say "aab打包成功"
  fi
fi
