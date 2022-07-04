flutter clean

flutter packages get

flutter build ipa --export-method ad-hoc --dart-define=app-debug-flag=true --obfuscate --split-debug-info=symbols

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)

build_name="build/ios/ipa/$name"
oss_path="oss://octmon/release/$name/"

# open build/ios/ipa

flutter build apk --dart-define=app-channel=beta --dart-define=app-debug-flag=true --obfuscate --split-debug-info=symbols

mv build/app/outputs/apk/release/app-release.apk $build_name.apk

# open build/app/outputs/apk/release

# ----- upload -----

~/ossutil/ossutil64 cp $build_name.ipa $oss_path -f

~/ossutil/ossutil64 cp $build_name.apk $oss_path -f

version=$(cat pubspec.yaml | grep "version:" | awk '{print $2}')
echo "{\"version\": \"$version\"}" > $build_name.version

~/ossutil/ossutil64 cp $build_name.version $oss_path -f
