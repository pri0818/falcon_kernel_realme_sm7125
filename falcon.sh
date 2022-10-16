#!/bin/bash

#set -e

 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##

# Basic Information
KERNEL_DEFCONFIG=falcon_defconfig

DEVICE=reatoll

VERSION=srb5-v2.0

DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")

TANGGAL=$(date +"%F%S")

ANYKERNEL3_DIR=$PWD/AnyKernel3/

FINAL_KERNEL_ZIP=Falcon-X-${VERSION}-${DEVICE}-${TANGGAL}.zip

# Verbose Build
VERBOSE=0
##----------------------------------------------------------##

# Exports

export PATH="$HOME/proton/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING="$($HOME/proton/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

if ! [ -d "$HOME/proton" ]; then
echo "Proton clang not found! Cloning..."
if ! git clone -q https://github.com/kdrag0n/proton-clang --depth=1 --single-branch ~/proton; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

# Speed up build process
MAKE="./makeparallel"

##----------------------------------------------------------##

# Start build
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Clean build always lol
echo -e "$red***********************************************"
echo "          STARTING THE ENGINE         "
echo -e "***********************************************$nocol"
echo -e "$yellow***********************************************"
echo "         CLEANING, PLEASE WAIT A BIT         "
echo -e "***********************************************$nocol"
mkdir -p out
make O=out clean

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING Falcon-X KERNEL          "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG O=out
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip \
			          V=$VERBOSE 2>&1 | tee error.log                      

##----------------------------------------------------------##

# Verify Files

echo "**** Verify Image.gz & dtbo.img ****"
ls $PWD/out/arch/arm64/boot/Image.gz
ls $PWD/out/arch/arm64/boot/dtbo.img
ls $PWD/out/arch/arm64/boot/dtb.img

       if ! [ -a "$PWD/out/arch/arm64/boot/Image.gz" ];
          then
              echo -e "$blue***********************************************"
              echo "          BUILD THROWS ERRORS         "
              echo -e "***********************************************$nocol"
              rm -rf out/
              for i in *.log
              do
              curl -F "document=@$i" --form-string "caption=" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}&parse_mode=HTML"
              done
              rm -rf error.log
              exit 1
          else
             echo -e "$blue***********************************************"
             echo "    KERNEL COMPILATION FINISHED, STARTING ZIPPING         "
             echo -e "***********************************************$nocol"
             rm -rf error.log 
       fi

##----------------------------------------------------------##

# Anykernel 3 time!!
echo "**** Verifying AnyKernel3 Directory ****"
ls $ANYKERNEL3_DIR
echo "**** Removing leftovers ****"
rm -rf $ANYKERNEL3_DIR/Image.gz
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/dtb.img
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP

echo "**** Copying Image.gz & dtbo.img ****"
cp $PWD/out/arch/arm64/boot/Image.gz $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtb.img $ANYKERNEL3_DIR/

echo -e "$cyan***********************************************"
echo "          Time to zip up!          "
echo -e "***********************************************$nocol"
cd $ANYKERNEL3_DIR/
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP

echo -e "$yellow***********************************************"
echo "         Done, here is your sha1         "
echo -e "***********************************************$nocol"
cd ..
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANYKERNEL3_DIR/Image.gz
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/dtb.img
rm -rf out/

sha1sum $FINAL_KERNEL_ZIP

##----------------------------------------------------------##
##----------------------------------------------------------##
##----------------------------------------------------------##

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"

##----------------------------------------------------------##
##----------------------------------------------------------##
##----------------------------------------------------------##

echo -e "$red***********************************************"
echo "         Uploading to telegram         "
echo -e "***********************************************$nocol"

# Upload Time!!
for i in *.zip
do
curl -F "document=@$i" --form-string "caption=" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}&parse_mode=HTML"
done

echo -e "$cyan***********************************************"
echo "          All done !!!         "
echo -e "***********************************************$nocol"
##----------------------------------------------------------##
##----------------------------------------------------------##
##----------------------------------------------------------##
