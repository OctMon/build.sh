cd $1

pgyer_api_key=$(cat pubspec.yaml | grep "pgyer_api_key: " | awk '{print $2}')

iosFlag=false
androidFlag=false

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
    flutter build ipa --export-method ad-hoc --obfuscate --split-debug-info=symbols
  else
    echo "build iOS beta test"
    flutter build ipa --export-method ad-hoc --dart-define=app-debug-flag=true --obfuscate --split-debug-info=symbols
  fi
  echo "---------------------------------"
  echo
fi

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)

build_ios_name="build/ios/ipa/$name"
build_android_name="build/app/outputs/apk/release/$name"
oss_path="oss://octmon/release/$name/"

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

ossUtilInstall=0
if command -v ~/ossutil/ossutil64 >/dev/null 2>&1;then
   ossUtilInstall=1
fi

echo $ossUtilInstall

version=$(cat pubspec.yaml | grep "version:" | awk '{print $2}')

if [ $iosFlag == true ]; then

  if [[ -n "${pgyer_api_key}" ]]
      then
          #上传到pgyer
          echo "正在上传ipa到蒲公英..."
          echo
          file_ipa="$build_ios_name.ipa"
#          curl -F "file=@${file_ipa}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.pgyer.com/apiv2/app/upload
          curl -F "file=@${file_ipa}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.xcxwo.com/apiv2/app/upload
          echo
          say "iOS上传蒲公英成功"
          echo
  fi

  if [ $ossUtilInstall -eq 1 ]; then
      echo "正在上传ipa到OSS..."
      echo
      ~/ossutil/ossutil64 cp $build_ios_name.ipa $oss_path -f

      ipa_version="${build_ios_name}_ipa".version
      echo "{\"version\": \"$version\"}" > $ipa_version

      ~/ossutil/ossutil64 cp $ipa_version $oss_path -f
  fi

fi

if [ $androidFlag == true ]; then

if [[ -n "${pgyer_api_key}" ]]
      then
          #上传到pgyer
          echo "正在上传apk到蒲公英..."
          echo
          file_apk="$build_android_name.apk"
#          curl -F "file=@${file_apk}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.pgyer.com/apiv2/app/upload
          curl -F "file=@${file_apk}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.xcxwo.com/apiv2/app/upload
          echo
          say "android上传蒲公英成功"
          echo
  fi

  if [ $ossUtilInstall -eq 1 ]; then
      echo "正在上传apk到OSS..."
      echo
      ~/ossutil/ossutil64 cp $build_android_name.apk $oss_path -f

      apk_version="${build_android_name}_apk".version
      echo "{\"version\": \"$version\"}" > $apk_version

      ~/ossutil/ossutil64 cp $apk_version $oss_path -f
  fi

fi

say "Beta版上传成功"