#!/bin/bash
# Sensei Build Script
# Copyright (c) 2015 Haikal Izzuddin
## ----------------------------------
# Step #1: Define variables
# ----------------------------------
EDITOR=vim
PASSWD=/etc/passwd
RED='\033[0;41;30m'
STD='\033[0;0;39m'

KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/arch/arm64/boot/Image
DTBTOOL=$KERNEL_DIR/tools/dtbToolCM
BUILD_START=$(date +"%s")
green='\033[01;32m'
red='\033[01;31m'
cyan='\033[01;36m'
blue='\033[01;34m'
blink_red='\033[05;31m'
restore='\033[0m'
nocol='\033[0m'

# Device varibles (Modify this)
device='Xiaomi Mi4i (Ferrari)' # Device Id
sensei_base_version='Sensei' # Kernel Id
version='2.3-dev' # Kernel Version
TC=''

# Modify the following variable if you want to build
export USE_CCACHE=1
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="Haikal Izzuddin"
export KBUILD_BUILD_HOST="haikalizz"
STRIP="~/Development/SenseiKernel/toolchains/uber/bin/aarch64-linux-android-strip"
MODULES_DIR="~/Development/SenseiKernel/SenseiOutput"
export CROSS_COMPILE="/home/haikalizz/Development/SenseiKernel/toolchains/uber/bin/aarch64-linux-android-"
make ferrari_debug_defconfig
make -j5 CONFIG_NO_ERROR_ON_MISMATCH=y

if ! [ -s $KERN_IMG ];
	then
		echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
		exit 1
fi
$DTBTOOL -2 -o $KERNEL_DIR/arch/arm64/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/

rm $MODULES_DIR/Mi4i/tools/Image
rm $MODULES_DIR/Mi4i/tools/dt.img
cp $KERNEL_DIR/arch/arm64/boot/Image  $MODULES_DIR/Mi4i/tools
cp $KERNEL_DIR/arch/arm64/boot/dt.img  $MODULES_DIR/Mi4i/tools
cd $MODULES_DIR/Mi4i/
zipfile="Sensei-$version+$TC-$(date +"%Y-%m-%d(%I.%M%p)").zip"
echo $zipfile
zip -r $zipfile tools META-INF system -x *kernel/.gitignore*
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
