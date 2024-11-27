cd $1

pgyer_api_key=$(cat pubspec.yaml | grep "pgyer_api_key: " | awk '{print $2}')

oss_access_key_id=$(cat pubspec.yaml | grep "oss_access_key_id: " | awk '{print $2}')
oss_access_key_secret=$(cat pubspec.yaml | grep "oss_access_key_secret: " | awk '{print $2}')
oss_endpoint=$(cat pubspec.yaml | grep "oss_endpoint: " | awk '{print $2}')

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)
version=$(cat pubspec.yaml | grep "version: " | awk '{print $2}' | head -n 1)

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

  echo "---------------------------------"
  oss_upload_path_array=$(cat pubspec.yaml | grep "oss_upload_path: " | awk '{print $2}')
  if [[ -n $oss_upload_path_array ]]; then
    echo "🗂 ️ $oss_upload_path_array"
    # 将字符串转换为数组
    IFS=',' read -r -a oss_upload_path_array <<< "$oss_upload_path_array"
  fi
  oss_file_path_array=$(cat pubspec.yaml | grep "oss_file_path: " | awk '{print $2}')
  if [[ -n $oss_file_path_array ]]; then
    echo "🗂️  $oss_file_path_array"
    # 将字符串转换为数组
    IFS=',' read -r -a oss_file_path_array <<< "$oss_file_path_array"
  fi

  # 获取长度
  oss_upload_path_length=${#oss_upload_path_array[@]}
  echo "数组长度是：$oss_upload_path_length"
  # 判断是否大于 1
  if [ $oss_upload_path_length -gt 1 ]; then
    tmpIndex=0
    printf "%-4s %-20s\n" 编号 上传地址
    for entry in "${oss_file_path_array[@]}"
    do
      tmp=${entry%/*}
      _tmp_array+=($tmp)
      tempTitle=${tmp##*/}
      printf "%-4s %-20s\n" $tmpIndex $tempTitle
      let "tmpIndex++"
      done
      echo "---------------------------------"
      echo
      echo "输入编号 0 - `expr ${#_tmp_array[@]} - 1`"
      read answer
      oss_upload_path=${oss_upload_path_array[answer]}
      oss_file_path=${oss_file_path_array[answer]}
      echo "上传地址为：$oss_upload_path 下载地址为：$oss_file_path"
  else
    oss_upload_path=${oss_upload_path_array[0]}
    oss_file_path=${oss_file_path_array[0]}
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

ios_finished=false
build_ios_name="build/ios/ipa/$name"
build_ios_file="$build_ios_name.ipa"

android_finished=false
build_android_name="build/app/outputs/apk/release/$name"
build_android_file="$build_android_name.apk"

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
  if [ -f "$build_ios_file" ]; then
    ios_finished=true
  fi
  echo "---------------------------------"
  echo
fi

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
  tmp="build/app/outputs/apk/release/app-release.apk"
   if [ -f "$tmp" ]; then
      android_finished=true
      mv $tmp $build_android_file
  fi
fi

# open build/app/outputs/apk/release

# ----- upload -----

if [ $iosFlag == true ]; then
  if [ -f "$build_ios_file" ]; then
    if [[ -n "${pgyer_api_key}" ]]
    then
      #上传到pgyer
      echo "正在上传ipa到蒲公英..."
      echo
      curl -F "file=@${build_ios_file}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.pgyer.com/apiv2/app/upload
#      curl -F "file=@${build_ios_file}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.xcxwo.com/apiv2/app/upload
      echo
      say "iOS上传蒲公英成功"
      echo
    fi

    if [ $ossUtilInstall -eq 1 ]; then
      echo "正在上传ipa到OSS..."
      echo
      ossutil -e $oss_endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $build_ios_file $oss_upload_path -f

      ipa_version="${build_ios_name}_ipa".version
      echo "{\"version\": \"$version\"}" > $ipa_version

      ossutil -e $oss_endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $ipa_version $oss_upload_path -f

      # plist文件创建
      distribution_summary_plist=build/ios/ipa/DistributionSummary.plist
      ipa_version="1.0.0"
      ipa_build="0"
      ipa_package=""
      if [ -e $distribution_summary_plist ]; then
          echo "$distribution_summary_plist 文件存在"
          ipa_version=$(/usr/libexec/PlistBuddy -c "Print :$name.ipa:0:versionNumber" $distribution_summary_plist)
          ipa_build=$(/usr/libexec/PlistBuddy -c "Print :$name.ipa:0:buildNumber" $distribution_summary_plist)
          ipa_package=$(/usr/libexec/PlistBuddy -c "Print :$name.ipa:0:entitlements:application-identifier" $distribution_summary_plist)
          ipa_package="${ipa_package#*.}"
          echo $ipa_version
          echo $ipa_build
          echo $ipa_package
      else
          echo "$distribution_summary_plist 文件不存在"
      fi

      info_plist=$build_ios_name.plist
      if [ -e $info_plist ]; then
          echo "$info_plist 文件存在"
          rm -f $info_plist
      else
          echo "$info_plist 文件不存在"
      fi

      /usr/libexec/PlistBuddy -c "Add :items array" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0 dict" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:assets array" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:assets:0 dict" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:assets:0:url string '$oss_file_path$name.ipa'" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:assets:0:kind string 'software-package'" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:metadata dict" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:metadata:title string '$name'" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:metadata:kind string 'software'" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:metadata:bundle-version string '$ipa_version'" $info_plist
      /usr/libexec/PlistBuddy -c "Add :items:0:metadata:bundle-identifier string '$ipa_package'" $info_plist

      ossutil -e $oss_endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $info_plist $oss_upload_path -f
    fi
  fi
fi

if [ $androidFlag == true ]; then
  if [ -f "$build_android_file" ]; then
    if [[ -n "${pgyer_api_key}" ]]
    then
      #上传到pgyer
      echo "正在上传apk到蒲公英..."
      echo
    curl -F "file=@${build_android_file}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.pgyer.com/apiv2/app/upload
#      curl -F "file=@${build_android_file}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=脚本自动上传" https://www.xcxwo.com/apiv2/app/upload
      echo
      say "android上传蒲公英成功"
      echo
    fi

    if [ $ossUtilInstall -eq 1 ]; then
      echo "正在上传apk到OSS..."
      echo
      ossutil -e $oss_endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $build_android_file $oss_upload_path -f

      apk_version="${build_android_name}_apk".version
      echo "{\"version\": \"$version\"}" > $apk_version

      ossutil -e $oss_endpoint -i $oss_access_key_id -k $oss_access_key_secret cp $apk_version $oss_upload_path -f
    fi
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
if [ $ios_finished == true ]; then
  echo "iOS扫码下载: "
  qrencode -m 2 -t UTF8 "itms-services://?action=download-manifest&url=$oss_file_path$name.plist"
  echo
fi

if [ $android_finished == true ]; then
  echo "Android扫码下载: "
  qrencode -m 4 -l M -t UTF8 "$oss_file_path$name.apk"
  echo
fi
echo
echo

if [ $iosFlag == true ]; then
  if [ $ios_finished == true ]; then
      say "$name ios版打包成功"
    else
      say "$name ios版打包失败"
  fi
fi

if [ $androidFlag == true ]; then
  if [ $android_finished == true ]; then
    say "$name android版打包成功"
  else
    say "$name android版打包失败"
  fi
fi