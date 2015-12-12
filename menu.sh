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
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Device varibles (Modify this)
device='Xiaomi Mi4i (FERRARI)' # Device Id
sensei_base_version='Sensei' # Kernel Id
version='2.0.4-dev' # Kernel Version

# Modify the following variable if you want to build
#export CROSS_COMPILE="~/Development/Toolchains/ubertc6.0/bin/aarch64-"
export USE_CCACHE=1
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="Haikal Izzuddin"
export KBUILD_BUILD_HOST="haikalizz"
STRIP="~/Development/Toolchains/ubertc6.0/bin/aarch64-strip"
MODULES_DIR=$KERNEL_DIR/../SenseiOutput
 
# ----------------------------------
# Step #2: User defined function
# ----------------------------------
pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}
 
# Build
one(){
	echo " Initialising Build Sequence...  "

	echo -e "${green}"
	echo "-----------------"
	echo "Making Sensei Kernel:"
	echo "-----------------"
	echo -e "${restore}"

	while read -p "Do you want to use UBERTC 4.9(1) or SABERMOD4.9(2)? " echoice
	do
	case "$echoice" in
	1 )
		export CROSS_COMPILE="/home/haikalizz/Development/Toolchains/ubertc4.9/bin/aarch64-linux-android-"
		TC="UBER4.9"
		echo
		echo "Using UBERTC4.9"
		break
		;;
	2 )
		export CROSS_COMPILE="/home/haikalizz/Development/Toolchains/sabermod4.9/bin/aarch64-"
		TC="SaberMod4.9"
		echo
		echo "Using SM4.9"
		break
		;;
	3 )
		export CROSS_COMPILE="/home/haikalizz/Development/Toolchains/ubertc6.0/bin/aarch64-linux-android-"
		TC="UBER6.0"
		echo
		echo "Using UBER6"
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
	esac
	done

	make ferrari_debug_defconfig
	read -p "Enter number of cpu's : " choice
	make -j$choice CONFIG_NO_ERROR_ON_MISMATCH=y

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
	zipfile="Sensei-$version-$(date +"%Y-%m-%d(%I.%M%p)").zip"
	echo $zipfile
	zip -r $zipfile tools META-INF system -x *kernel/.gitignore*
	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
	echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
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
	echo "Modules Dir : "$MODULES_DIR
	pause
}
 
# Kconfig
four(){
	make ferrari_debug_defconfig;
	make menuconfig;
	pause
}

show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~"	
	echo " Sensei Build Script"
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Build Sensei"
	echo "		? - Build kernel from source"
	echo "2. Clean Repo"
	echo "		? - Clear the previous build"
	echo "3. Kernel Info"
	echo "		? - Returns kernel info"
	echo "4. Defconfig"
	echo "5. Exit"
}

read_options(){
	local choice
	read -p "Enter choice [ 1 - 5] " choice
	case $choice in
		1) one ;;
		2) two ;;
		3) three;;
		4)four;;
		5) exit 0;;
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
