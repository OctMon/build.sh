cd $1

flutter clean

flutter packages get

mkdir channel

sh build_channel.sh xiaomi
sh build_channel.sh huawei
sh build_channel.sh yingyongbao
sh build_channel.sh vivo
sh build_channel.sh oppo
sh build_channel.sh meizu
sh build_channel.sh m360

open channel

say "渠道包打包成功"
