cd $1

iosFlag=false
androidFlag=false

if [[ $2 = "ios" || $3 = "ios" ]]
then
  iosFlag=true
  echo "☑︎ iOS"
else
  echo "☒︎ iOS"
fi

if [[ $2 = "android" || $3 = "android" ]]
then
  androidFlag=true
  echo "☑︎ android"
else
  echo "☒︎ android"
fi

flutter clean

flutter packages get

if [ $iosFlag == true ]; then
  flutter build ipa --export-method ad-hoc --dart-define=app-debug-flag=true --obfuscate --split-debug-info=symbols
fi

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)

build_ios_name="build/ios/ipa/$name"
build_android_name="build/app/outputs/apk/release/$name"
oss_path="oss://octmon/release/$name/"

# open build/ios/ipa

if [ $androidFlag == true ]; then
  flutter build apk --dart-define=app-channel=beta --dart-define=app-debug-flag=true --obfuscate --split-debug-info=symbols
  
  mv build/app/outputs/apk/release/app-release.apk $build_android_name.apk
fi

# open build/app/outputs/apk/release

# ----- upload -----

version=$(cat pubspec.yaml | grep "version:" | awk '{print $2}')

if [ $iosFlag == true ]; then
  ~/ossutil/ossutil64 cp $build_ios_name.ipa $oss_path -f

  ipa_version="${build_ios_name}_ipa".version
  echo "{\"version\": \"$version\"}" > $ipa_version

  ~/ossutil/ossutil64 cp $ipa_version $oss_path -f
fi

if [ $androidFlag == true ]; then
  ~/ossutil/ossutil64 cp $build_android_name.apk $oss_path -f

  apk_version="${build_android_name}_apk".version
  echo "{\"version\": \"$version\"}" > $apk_version

  ~/ossutil/ossutil64 cp $apk_version $oss_path -f
fi
