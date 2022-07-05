pwd

echo "---------------------------------"
myArray=()

index=0
for entry in /Users/limeng/Developer/*
do
  myArray+=($entry)

  echo "$index: $entry"
  let "index++"
done
echo "---------------------------------"
pwd

echo
echo "输入项目编号 0 - `expr ${#myArray[@]} - 1`"
read answer

project=${myArray[answer]}

echo $project
echo

echo '输入 1 到 5 之间的数字:'
echo '1: Beta-iOS'
echo '2: Beta-android'
echo '3: Beta-all'
echo '4: Appstore'
echo '5: Android'

echo '你输入的数字为:'
read aNum
case $aNum in
1)
  echo '你选择了 1'
  sh build_beta.sh $project "ios"
  ;;
2)
  echo '你选择了 2'
  sh build_beta.sh $project "android"
  ;;
3)
  echo '你选择了 3'
  sh build_beta.sh $project "ios" "android"
  ;;
4)
  echo '你选择了 4'
  sh build_ipa.sh $project
  ;;
5)
  echo '你选择了 5'
  sh build_apk.sh $project
  ;;
*)
  echo '你没有输入 1 到 5 之间的数字'
  ;;
esac
