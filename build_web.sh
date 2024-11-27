cd $1

flutter clean

flutter packages get

flutter build web

cd build
# 定义目录路径
DIR_PATH="web"          # 需要压缩的目录
OUTPUT_FILE="web.zip"   # 压缩后的文件名

# 检查目录是否存在
if [ ! -d "$DIR_PATH" ]; then
  echo "错误：目录 $DIR_PATH 不存在！"
  exit 1
fi

# 压缩目录
zip -r $OUTPUT_FILE $DIR_PATH

# 提示压缩完成
echo "压缩完成：$OUTPUT_FILE"

open web

say "web打包成功"