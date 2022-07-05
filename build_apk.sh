cd $1

flutter clean

flutter packages get

mkdir channel

build_apk(){
    flutter build apk --dart-define=app-channel=$1 --obfuscate --split-debug-info=symbols
    mv build/app/outputs/apk/release/app-release.apk channel/$1.apk
}

build_apk xiaomi
build_apk huawei
build_apk yingyongbao
build_apk vivo
build_apk oppo
build_apk meizu
build_apk m360

open channel

say "渠道包打包成功"
