pwd

echo "输入项目名称"
read answer

project="/Users/limeng/Developer/$answer"

echo $project

echo '输入 1 到 3 之间的数字:'
echo '1: Beta'
echo '2: Appstore'
echo '3: Android'

echo '你输入的数字为:'
read aNum
case $aNum in
1)
  echo '你选择了 1'
  sh build_beta.sh $project
  ;;
2)
  echo '你选择了 2'
  sh build_ipa.sh $project
  ;;
3)
  echo '你选择了 3'
  sh build_apk.sh $project
  ;;
*)
  echo '你没有输入 1 到 3 之间的数字'
  ;;
esac
