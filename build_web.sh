cd $1

name=$(cat pubspec.yaml | grep "name: " | awk '{print $2}' | head -n 1)
web_base_href=$(cat pubspec.yaml | grep "web_base_href: " | awk '{print $2}')

echo "web_base_href: $web_base_href"

fvm flutter clean

fvm flutter packages get

if [[ -n "$web_base_href" ]]
then
  fvm flutter build web --base-href=$web_base_href
else
  fvm flutter build web
fi

if [ -e build ]; then
  cd build
  # 定义目录路径
  DIR_PATH="web"          # 需要压缩的目录
  OUTPUT_FILE="$name.zip"   # 压缩后的文件名

  # 检查目录是否存在
  if [ ! -d "$DIR_PATH" ]; then
    echo "错误：目录 $DIR_PATH 不存在！"
    exit 1
  fi

  ln -s $DIR_PATH $name

  # 压缩目录
  zip -r $OUTPUT_FILE $name

  rm $name

  # 提示压缩完成
  echo "压缩完成：$OUTPUT_FILE"

  open web

  say "web打包成功"
else
  say "web打包失败"
fi
