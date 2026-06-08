~/.zshrc

```
function build() {
    tmp=$(pwd)
    cd ~/Developer/build.sh
    sh build.sh $tmp
}

export PGYER_API_KEY="你的蒲公英密钥"
