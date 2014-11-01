#!/bin/bash

echo ""
echo ""

# Find any simulator SDK
cd "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/"
pattern="iPhoneSimulator"
for _dir in *"${pattern}"*; do
    [ -d "${_dir}" ] && dir="${_dir}" && break
done
PLATSDK="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/${dir}/"
echo "PLATSDK: $PLATSDK"

# Go into current location:
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CD=$DIR
cd $CD
echo "CD: $CD"

# Load SDK configuration:
ADT="$(<configure.adt)"
echo "ADT: $ADT"
ACOMPC="$(<configure.acompc)"
echo "ACOMPC: $ACOMPC"

# Clean & Copy files:
rm -rf temp
mkdir temp
mkdir temp/ios
mkdir temp/mac

# Patch xml files:
SEARCH="_THIS_"
REPLACE="$(<anename.txt)"
ANENAME=$REPLACE

cat extension.xml | sed -e "s/$SEARCH/$REPLACE/g" >> ./temp/extension.xml
cp platformoptions.xml ./temp/

# Copy binaries:
mv -f ../projects/xcode/JSSpiderANE/Build/Products/Release-iphonesimulator/libJSSpideriOS.a ./temp/ios/JSSpiderANE386.a
mv -f ../projects/xcode/JSSpiderANE/Build/Products/Release-iphoneos/libJSSpideriOS.a ./temp/ios/JSSpiderANE.a
mv -f ../projects/xcode/JSSpiderANE/Build/Products/Release/JSSpiderANE.framework ./temp/mac/JSSpiderANE.framework

# android:
mkdir -p temp/android/libs/armeabi-v7a
mkdir -p temp/android/libs/x86

cp "../projects/android/so_arm/libs/armeabi-v7a/libjs_staticARM7.so" temp/android/libs/armeabi-v7a/libalegorium.ane.$REPLACE.so
cp "../projects/android/so_x86/libs/x86/libjs_static.so" temp/android/libs/x86/libalegorium.ane.$REPLACE.so

[[ -f "../ane/$ANENAME.ane" ]] && rm -f "../ane/$ANENAME.ane"

SWFVERSION=26

INCLUDE_CLASSES="alegorium.$ANENAME"
echo "INCLUDE_CLASSES: $INCLUDE_CLASSES"

SRCPATH="../as3/"

# Build:
echo "GENERATING SWC"
if test "../as3/alegorium/$ANENAME.as" -nt "../as3/alegorium/$ANENAME.swc"; then
# file1 -nt file2;
# file1 is newer than file2
$ACOMPC -source-path $SRCPATH -include-classes $INCLUDE_CLASSES -swf-version=$SWFVERSION -define+=CONFIG::mock,false -output ../as3/alegorium/$ANENAME.swc
fi

cp -rf "../as3/alegorium/$ANENAME.swc" "temp/$ANENAME.swc"
sleep 0

cd temp
echo "GENERATING LIBRARY from SWC"

unzip $ANENAME.swc
sleep 0
[[ -f "catalog.xml" ]] && rm -f "catalog.xml"

cp -rf "library.swf" "mac/library.swf"
cp -rf "library.swf" "ios/library.swf"
cp -rf "library.swf" "android/libs/armeabi-v7a/library.swf"
cp -rf "library.swf" "android/libs/x86/library.swf"

echo "GENERATING ANE"



sleep 0

mv $ANENAME.ane ../../ane/

# Clean:
[[ -f "library.swf" ]] && rm -f "library.swf"
[[ -f "$ANENAME.swc" ]] && rm -f "$ANENAME.swc"
cd ..

mv -f ./temp/mac/JSSpiderANE.framework ../projects/xcode/JSSpiderANE/Build/Products/Release/JSSpiderANE.framework
mv -f ./temp/ios/JSSpiderANE386.a ../projects/xcode/JSSpiderANE/Build/Products/Release-iphonesimulator/libJSSpideriOS.a
mv -f ./temp/ios/JSSpiderANE.a ../projects/xcode/JSSpiderANE/Build/Products/Release-iphoneos/libJSSpideriOS.a
rm -rf temp

echo "DONE!"