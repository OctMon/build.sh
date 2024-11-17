~/.zshrc

```
function build() {
    tmp=$(pwd)
    cd ~/Developer/build.sh
    sh build.sh $tmp
}
