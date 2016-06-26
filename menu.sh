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
device='Xiaomi Mi4i (FERRARI)' # Device Id
sensei_base_version='Sensei' # Kernel Id
version='2.2-dev' # Kernel Version
TC=''

# Modify the following variable if you want to build
export USE_CCACHE=1
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="Haikal Izzuddin"
export KBUILD_BUILD_HOST="haikalizz"
STRIP="~/Development/SenseiKernel/toolchains/uber/bin/aarch64-linux-android-strip"
BUILD_DIR=$KERNEL_DIR/../SenseiOutput
MODULES_DIR="${KERNEL_DIR}/../SenseiOutput/Mi4i/modules"
 
# ----------------------------------
# Step #2: User defined function
# ----------------------------------
pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}
 
# Build
one(){
	echo "${green}"
	echo "-----------------"
	echo "Initialising Build Sequence"
	echo "-----------------"
	echo "${restore}"

	echo "${cyan}"
	while read -p " Desired toolchain: UBERTC 4.9(1) | SABERMOD4.9(2) | UBERTC6.0(3)?" echoice
	do
	case "$echoice" in
	1 )
		export CROSS_COMPILE="/home/haikalizz/Development/SenseiKernel/toolchains/uber/bin/aarch64-linux-android-"
		TC="UBER"
		echo "${blue}"
		echo "Compiling using UBERTC4.9"
		echo "${restore}"
		break
		;;
	2 )
		export CROSS_COMPILE="~/Development/SenseiKernel/toolchains/sabermod/bin/aarch64-"
		TC="SM"
		echo "${blue}"
		echo "Compiling using SM4.9"
		echo "${restore}"
		break
		;;
	3 )
		export CROSS_COMPILE="~/Development/SenseiKernel/toolchains/uber6/bin/aarch64-linux-android-"
		TC="UBER6"
		echo "${blue}"
		echo "Compiling using UBER6"
		echo "${restore}"
		break
		;;
	* )
		echo "${blink_red}"
		echo "Invalid try again!"
		echo "${restore}"
		;;
	esac
	done
	echo "${restore}"

	make ferrari_debug_defconfig
	read -p "Enter number of cpu's : " choice
	make -j$choice CONFIG_NO_ERROR_ON_MISMATCH=y

	if ! [ -s $KERN_IMG ];
		then
			echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
			exit 1
	fi
	$DTBTOOL -2 -o $KERNEL_DIR/arch/arm64/boot/dtb -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/

	rm `echo $MODULES_DIR"/*"`
	find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;

	rm $BUILD_DIR/Mi4i/zImage
	rm $BUILD_DIR/Mi4i/dtb
	cp -vr $KERNEL_DIR/arch/arm64/boot/Image  $BUILD_DIR/Mi4i/zImage
	cp $KERNEL_DIR/arch/arm64/boot/dtb  $BUILD_DIR/Mi4i/dtb
	cd $BUILD_DIR/Mi4i/
	zipfile="SenseiMi4i-$version+$TC-$(date +"%Y-%m-%d(%I.%M%p)").zip"
	echo $zipfile
	zip -r9 $zipfile * -x README
	mv $BUILD_DIR/Mi4i/$zipfile $BUILD_DIR/
	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))

 	echo "${green}"
 	echo "------------------------------------------"
 	echo "Build $version Completed :"
 	echo "------------------------------------------"
 	echo "${restore}"
	echo ${yellow}"Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."${restore}
	echo "Enjoy Sensei for "$device

        exit 0
}
 
# Clean Repo
two(){
	echo "Initialising Cleaning Sequence..."
	read -p "Enter number of cpu's : " choice
	make ARCH=arm64 -j$choice clean mrproper
	echo "Cleaning Completed"
        pause
}

# Kernel Info
three(){
	echo "Sensei Kernel"
	echo "Device : "$device
	echo "Version : "$sensei_base_version-$version
	echo "";
	echo "Build Dir : "$KERNEL_DIR
	echo "Out Dir : "$MODULES_DIR
	pause
}
 
# Kconfig
menuconfig(){
	echo "Opening Menuconfig"
	make ferrari_debug_defconfig;
	make menuconfig;
	pause
}

# Changelog Generator
changelog_gen(){
	echo "Generating Changelog"
	sh changelog.sh
	pause
}

show_menus() {
	clear
	echo "${restore}~~~~~~~~~~~~~~~~~~~~~"	
	echo " Welcome! Sensei Builder"
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Build Sensei"
	echo "		? - Build kernel from source"
	echo "2. Clean Repo"
	echo "		? - Clear the previous build"
	echo "3. Kernel Info"
	echo "		? - Returns kernel info"
	echo "4. Generate Changelog"
	echo "		? - Generates changelog"
	echo "5. Edit Defconfig"
	echo "		? - Edits the defconfig"
	echo "6. Exit"
}

read_options(){
	local choice
	read -p "Enter choice [ 1 - 6] " choice
	case $choice in
		1) one ;;
		2) two ;;
		3) three;;
		4) changelog_gen;;
		5) menuconfig;;
		6) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}
 
# ----------------------------------------------
# Step #3: Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP
 
# -----------------------------------
# Step #4: Main logic - infinite loop
# ------------------------------------
while true
do
 
	show_menus
	read_options
done
