cd $1

get_pubspec_value() {
  local key="$1"
  awk -F ': ' -v search_key="$key" '$1 == search_key {print $2; exit}' pubspec.yaml
}

require_env() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" ]]; then
    echo "缺少环境变量 $key" >&2
    exit 1
  fi
}

fvm flutter clean

fvm flutter packages get

name=$(get_pubspec_value "name")
version=$(get_pubspec_value "version")
require_env "PGYER_API_KEY"
pgyer_api_key="${PGYER_API_KEY}"

apk_path="build/app/outputs/apk/release/"
apk_file="${apk_path}app-release.apk"

if [[ "$2" == "official" ]]; then
  echo "📦 official"
  fvm flutter build apk --target-platform android-arm64 --dart-define=git-branch=$(git rev-parse --abbrev-ref HEAD) --dart-define=git-commit=$(git rev-parse --short HEAD) --dart-define=app-channel=official --obfuscate --split-debug-info=symbols

  if [[ ! -f "$apk_file" ]]; then
    echo "$apk_file does not exist." >&2
    say "official打包失败"
    exit 1
  fi

  official_apk="${apk_path}${name}_official_${version}.apk"
  mv "$apk_file" "$official_apk"
  open "$apk_path"

  echo "正在上传apk到蒲公英..."
  if ! curl -F "file=@${official_apk}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.pgyer.com/apiv2/app/upload; then
    echo "上传apk到蒲公英失败" >&2
    exit 1
  fi

  say "official上传蒲公英成功"
elif [[ -n $3 ]]; then
  echo "🗂️ $name $version  $3"
  fvm flutter build apk --target-platform android-arm64 --dart-define=git-branch=$(git rev-parse --abbrev-ref HEAD) --dart-define=git-commit=$(git rev-parse --short HEAD) --dart-define=app-channel=$3 --obfuscate --split-debug-info=symbols
  if [ -f "$apk_file" ]; then
    echo "$apk_file exists."
    mv $apk_file ${apk_path}${name}_$3_${version}.apk
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
      fvm flutter build apk --target-platform android-arm64 --dart-define=git-branch=$(git rev-parse --abbrev-ref HEAD) --dart-define=git-commit=$(git rev-parse --short HEAD) --dart-define=app-channel=$1 --obfuscate --split-debug-info=symbols
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
    fvm flutter build appbundle --target-platform android-arm64 --dart-define=git-branch=$(git rev-parse --abbrev-ref HEAD) --dart-define=git-commit=$(git rev-parse --short HEAD) --obfuscate --split-debug-info=symbols
    open build/app/outputs/bundle/release
    say "aab打包成功"
  fi
fi
