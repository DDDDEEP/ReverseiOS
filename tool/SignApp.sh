##!/bin/sh
# ================== 环境变量 ==================
# HOME_PATH="/Users/DEEP"
# TARGET_NAME="reverseiOS"
# SRCROOT="${HOME_PATH}/Documents/Coding/playground/reverseiOS"
# BUILT_PRODUCTS_DIR="${HOME_PATH}/Library/Developer/Xcode/DerivedData/reverseiOS-folekbkzldtxwkgmicdsfrwrbhiy/Build/Products/Debug-iphoneos"
# PRODUCT_BUNDLE_IDENTIFIE="com.DEEP.reverseiOS"
# EXPANDED_CODE_SIGN_IDENTITY="00000000000000000000000"
# EXPANDED_CODE_SIGN_IDENTITY_NAME="Apple Development: xxxx@qq.com (xxxx)"

#目标文件路径
BUILD_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
#定义临时目录变量，存放解.ipa后产生的临时文件
TEMP_PATH="${SRCROOT}/temp"
#tool路径
TOOL_PATH="${SRCROOT}/tool"
#定义APP资源目录变量，存放要重签名的APP
APP_PATH="${SRCROOT}/app"
#定义ipa包路径
IPA_PATH="${APP_PATH}/*.ipa"




# ================== 1、解压 ipa 到 TEMP_PATH 目录下 ==================
#移除临时文件，并重新创建文件夹
rm -rf "${TEMP_PATH}"
mkdir -p "${TEMP_PATH}"

unzip -o "$IPA_PATH" -d "$TEMP_PATH"
#获取临时app路径
TEMP_APP_PATH=$(set -- "$TEMP_PATH/Payload/"*.app;echo "$1")
#Info文件路径
TARGET_INFO_PLIST=$TEMP_APP_PATH/Info.plist
echo ".app文件路径：$TEMP_APP_PATH"


# ================== 2、拷贝 provision 到 TEMP_APP_PATH 下 ==================
echo "目标代码路径:$BUILD_APP_PATH"
cp -rf "$BUILD_APP_PATH/embedded.mobileprovision" "$TEMP_APP_PATH/"


# ================== 3、修改 info.plist 中的 BundleId、displayName ==================
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TEMP_APP_PATH/Info.plist"
TARGET_DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" "$TARGET_INFO_PLIST")
TARGET_DISPLAY_NAME="${TARGET_DISPLAY_NAME}_hook"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $TARGET_DISPLAY_NAME" "$TEMP_APP_PATH/Info.plist"

echo "plist路径：$TARGET_INFO_PLIST"
echo "显示名称：$TARGET_DISPLAY_NAME"

if [[ "$TARGET_DISPLAY_NAME" != "" ]]; then
    for file in `ls "$TEMP_APP_PATH"`;
    do
        extension="${file#*.}"
        if [[ -d "$TEMP_APP_PATH/$file" ]]; then
            if [[ "$extension" == "lproj" ]]; then
                if [[ -f "$TEMP_APP_PATH/$file/InfoPlist.strings" ]];then
                    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $TARGET_DISPLAY_NAME" "$TEMP_APP_PATH/$file/InfoPlist.strings"
                fi
            fi
        fi
    done
fi


# ================== 4、删除扩展应用及插件 ==================
echo "Removing PlugIns and Watch"
rm -rf "$TEMP_APP_PATH/PlugIns"
rm -rf "$TEMP_APP_PATH/Watch"
#rm -rf "$TEMP_APP_PATH/com.apple.WatchPlaceholder"


# ================== 5、给可执行文件执行权限 ==================
APP_BINARY=`plutil -convert xml1 -o - $TEMP_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
chmod +x "$TEMP_APP_PATH/$APP_BINARY"


# ================== 6、重签 Frameworks 下的所有动态库 ==================
APP_FRAMEWORKS_PATH="$TEMP_APP_PATH/Frameworks"
if [ ! -d "$APP_FRAMEWORKS_PATH" ]
then
mkdir -p "${APP_FRAMEWORKS_PATH}"
fi

#注入到可执行文件中
if [ -d "$BUILT_PRODUCTS_DIR/MyHook.framework" ]
then
MyHook_FRAMEWORKS_PATH="$BUILT_PRODUCTS_DIR/MyHook.framework"
cp -rf "$MyHook_FRAMEWORKS_PATH" "$APP_FRAMEWORKS_PATH/"
${SRCROOT}/tool/insert_dylib --all-yes --inplace "@rpath/MyHook.framework/MyHook" "$TEMP_APP_PATH/$APP_BINARY"
else
echo "没有该文件"
fi

#遍历所有动态库
for FRAMEWORK in "$APP_FRAMEWORKS_PATH/"*
do
echo "framework: $FRAMEWORK"
#对动态库签名 $EXPANDED_CODE_SIGN_IDENTITY xcode上的证书
/usr/bin/codesign -fs "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
echo "EXPANDED_CODE_SIGN_IDENTITY:$EXPANDED_CODE_SIGN_IDENTITY  FRAMEWORK:$FRAMEWORK"
done


# ================== 7、将修改后的 .app 移动到 Xcode 对应的 Products 下 ==================
rm -rf "$BUILD_APP_PATH"
mkdir -p "$BUILD_APP_PATH"
cp -rf "$TEMP_APP_PATH/" "$BUILD_APP_PATH/"

