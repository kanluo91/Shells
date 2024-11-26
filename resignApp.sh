#1.资源目录，存放ipa包
ASSET_PATH="${SRCROOT}/APP"
#2.临时目录,存放解压文件
TMP_PATH="${SRCROOT}/Temp"
#3.ipa包的路径
TARGET_IPA_PATH="${ASSET_PATH}/*.ipa"
#4.清空Temp 文件夹
rm -rf "${TMP_PATH}"
mkdir -p "${TMP_PATH}"
#5. 创建APP 目录
if [ -d "$ASSET_PATH"]; then
    echo "[脚本日志]APP 目录存在"
else
    echo "[脚本日志]App 目录不存在"
    mkdir -p "$ASSET_PATH"
fi

#6. 解压APP/*.ipa 到Temp 目录里
unzip -oqq "$TARGET_IPA_PATH" -d "$TMP_PATH"

#7. 解压后临时App路径
TEMP_APP_PATH=$(set -- "${TMP_PATH}/Payload/"*.app;echo $1)

echo "[脚本日志]临时App路径： $TEMP_APP_PATH"

#8. 拷贝APP文件 替换掉xcode 生成的app，让app去帮忙签名
TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
echo "[脚本日志]编译出来的文件路径=$TARGET_APP_PATH"
#9. 拷贝，覆盖掉 .app
cp -rf "$TEMP_APP_PATH/" "$TARGET_APP_PATH"

#10. 移除不能签名的文件
rm -rf "$TARGET_APP_PATH/PlugIns"
rm -rf "$TARGET_APP_PATH/Watch"


#11. 修改infoplist -> Bundle Id  (通过PlistBuddy 工具)
# PlistBuddy 工具 在电脑 /usr/libexec 目录下
# 格式: -c "Set :KEY Value" "xxxx.plist"


/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${PRODUCT_BUNDLE_IDENTIFIER}" "$TARGET_APP_PATH/Info.plist"


#12.重签 三方的frameworks
# 使用codesign 工具  在目录 /usr/bin/codesign
# -fs == --force --sign
# 开发者证书的宏    $EXPANDED_CODE_SIGN_IDENTITY
TARGET_FRAMEWORKS_PATH="$TARGET_APP_PATH/Frameworks"
if [ -d "$TARGET_FRAMEWORKS_PATH"]; then


for FRAMEWORK in "$TARGET_FRAMEWORKS_PATH/"*
do
 if [ -d "$FRAMEWORK"]; then
 echo "[脚本日志]签名库的路径=$FRAMEWORK"
 /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
 fi

 #   if [ -d "$FRAMEWORK"]; then
  #      /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK" 
done
fi

