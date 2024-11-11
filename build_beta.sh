cd $1

pgyer_api_key=$(cat pubspec.yaml | grep "pgyer_api_key: " | awk '{print $2}')

oss_access_key_id=$(cat pubspec.yaml | grep "oss_access_key_id: " | awk '{print $2}')
oss_access_key_secret=$(cat pubspec.yaml | grep "oss_access_key_secret: " | awk '{print $2}')
endpoint=$(cat pubspec.yaml | grep "endpoint: " | awk '{print $2}')
oss_upload_path=$(cat pubspec.yaml | grep "oss_upload_path: " | awk '{print $2}')
oss_file_path=$(cat pubspec.yaml | grep "oss_file_path: " | awk '{print $2}')

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)
version=$(cat pubspec.yaml | grep "version: " | awk '{print $2}')

iosFlag=false
androidFlag=false


if [[ -n "${pgyer_api_key}" ]]
then
  echo "pgyer_api_key存在"
else
  echo "pgyer_api_key不存在"
fi

ossUtilInstall=0
if [[ -n "${oss_access_key_secret}" ]]
then
  echo "oss_access_key_secret存在"
  if command -v ossutil >/dev/null 2>&1; then
    ossUtilInstall=1
    echo "ossutil已安装"
    else
    echo "请输入密码，安装ossutil"
  #   默认安装到/usr/local/bin目录下。
    sudo -v ; curl https://gosspublic.alicdn.com/ossutil/install.sh | sudo bash
    echo "ossutil安装成功"
    ossUtilInstall=1
  fi
else
  echo "oss_access_key_secret不存在"
fi

if [[ $2 == "release" || $2 = "ios" || $3 = "ios" ]]
then
  iosFlag=true
  echo "☑︎ iOS"
else
  echo "☒︎ iOS"
fi

if [[ $2 == "release" || $2 = "android" || $3 = "android" ]]
then
  androidFlag=true
  echo "☑︎ android"
else
  echo "☒︎ android"
fi

flutter clean

flutter packages get

if [ $iosFlag == true ]; then
  echo
  echo "---------------------------------"
  if [[ $2 == "release" ]]; then
    echo "build iOS beta release"
    flutter build ipa --dart-define=app-channel=official --export-method ad-hoc --obfuscate --split-debug-info=symbols
  else
    echo "build iOS beta test"
    flutter build ipa --dart-define=app-channel=official --dart-define=app-debug-flag=true --export-method ad-hoc --obfuscate --split-debug-info=symbols
  fi
  echo "---------------------------------"
  echo
fi

build_ios_name="build/ios/ipa/$name"
build_android_name="build/app/outputs/apk/release/$name"
# open build/ios/ipa

if [ $androidFlag == true ]; then
  echo
  echo "---------------------------------"
  if [[ $2 == "release" ]]; then
    echo "build android beta release"
    flutter build apk --dart-define=app-channel=beta --obfuscate --split-debug-info=symbols
  else
    echo "build android beta test"
    flutter build apk --dart-define=app-channel=beta --dart-define=app-debug-flag=true --obfuscate --split-debug-info=symbols
  fi
  echo "---------------------------------"
  echo
  mv build/app/outputs/apk/release/app-release.apk $build_android_name.apk
fi

# open build/app/outputs/apk/release

# ----- upload -----

if [ $iosFlag == true ]; then

  if [[ -n "${pgyer_api_key}" ]]
  then
    #上传到pgyer
    echo "正在上传ipa到蒲公英..."
    echo
    file_ipa="$build_ios_name.ipa"
    curl -F "file=@${file_ipa}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.pgyer.com/apiv2/app/upload
#    curl -F "file=@${file_ipa}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.xcxwo.com/apiv2/app/upload
    echo
    say "iOS上传蒲公英成功"
    echo
  fi

  if [ $ossUtilInstall -eq 1 ]; then
    echo "正在上传ipa到OSS..."
    echo
    ossutil -e $endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $build_ios_name.ipa $oss_upload_path -f

    ipa_version="${build_ios_name}_ipa".version
    echo "{\"version\": \"$version\"}" > $ipa_version

    ossutil -e $endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $ipa_version $oss_upload_path -f
  fi

fi

if [ $androidFlag == true ]; then

  if [[ -n "${pgyer_api_key}" ]]
  then
    #上传到pgyer
    echo "正在上传apk到蒲公英..."
    echo
    file_apk="$build_android_name.apk"
  curl -F "file=@${file_apk}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.pgyer.com/apiv2/app/upload
#    curl -F "file=@${file_apk}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.xcxwo.com/apiv2/app/upload
    echo
    say "android上传蒲公英成功"
    echo
  fi

  if [ $ossUtilInstall -eq 1 ]; then
    echo "正在上传apk到OSS..."
    echo
    ossutil -e $endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $build_android_name.apk $oss_upload_path -f

    apk_version="${build_android_name}_apk".version
    echo "{\"version\": \"$version\"}" > $apk_version

    ossutil -e $endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $apk_version $oss_upload_path -f
  fi

fi

# 展示下载二维码
qrencodeInstall=0
if [[ -n "${oss_access_key_secret}" ]]
then
  if command -v qrencode >/dev/null 2>&1; then
    qrencodeInstall=1
    echo "qrencode已安装"
    else
    echo "未安装qrencode"
    brew install qrencode
    echo "qrencode安装成功"
    qrencodeInstall=1
  fi
fi

echo
echo
echo "$name $version"
echo
echo "iOS扫码下载: "
qrencode -m 2 -t UTF8 "itms-services://?action=download-manifest&url=$oss_file_path$name.plist"
echo
echo "Android扫码下载: "
qrencode -m 2 -t UTF8 "$oss_file_path$name.apk"
echo
echo
echo

say "Beta版上传成功"