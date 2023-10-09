#!/bin/bash

pwd

echo "---------------------------------"
myArray=()

index=0

printf "%-4s %-20s\n" 编号 项目名称

for entry in $(find ~/Developer -maxdepth 2 -name pubspec.yaml)
do
  tmp=${entry%/*}
  myArray+=($tmp)
  name=${tmp##*/}
  printf "%-4s %-20s\n" $index $name
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

echo "🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀"
echo
echo '********** 请输入指令 **********'
echo
echo '1: 📱 Beta-iOS'
echo '2: 📱 Beta-android'
echo '3: 📱 Beta-all'
echo '4: 🎈 Release-all'
echo '5a:🧑🏻‍💻 Appstore (验证)'
echo '5b:🧑🏻‍💻 Appstore (上传)'
echo '6: 📦 Android (aab)'
echo '7: 📦 Android (channel)'
echo
echo "🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀"

echo
echo '你输入的:'
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
  echo '你选择了 4 Release-all'
  sh build_beta.sh $project "release"
  ;;
5a)
  echo '你选择了 5a Appstore (验证)'
  sh build_ipa.sh $project "validate"
  ;;
5b)
  echo '你选择了 5b Appstore (上传)'
  sh build_ipa.sh $project "upload"
  ;;
6)
  echo '你选择了 6 Android (aab)'
  sh build_apk.sh $project "aab"
  ;;
7)
  echo '你选择了 7 Android (channel)'
  sh build_apk.sh $project "channel"
  ;;
*)
  echo '你没有正确输入, 联系我 -> https://github.com/OctMon/build.sh'
  ;;
esac

cd ~/
