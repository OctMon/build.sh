flutter build apk --dart-define=app-channel=$1 --obfuscate --split-debug-info=symbols
mv build/app/outputs/apk/release/app-release.apk channel/$1.apk
