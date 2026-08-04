~/.zshrc

```
function build() {
    tmp=$(pwd)
    cd ~/Developer/build.sh
    sh build.sh $tmp
}

# 可选；未配置则跳过蒲公英上传
export PGYER_API_KEY="你的蒲公英密钥"
