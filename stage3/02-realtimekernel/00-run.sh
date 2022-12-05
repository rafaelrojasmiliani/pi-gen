

main(){
# taken from https://lemariva.com/blog/2019/09/raspberry-pi-4b-preempt-rt-kernel-419y-performance-test
    echo "-------------------------------------------------------------------"
    echo "------------------------------- cross compilation started -------------------------"
    echo "-------------------------------------------------------------------"
    set -x

    local build_folder=${ROOTFS_DIR}/kernel_cross

    [ -d $build_folder/rpi-kernel/linux ] || git clone https://github.com/raspberrypi/linux.git -b rpi-4.19.y-rt $build_folder/rpi-kernel/linux
    [ -d $build_folder/rpi-kernel/tools ] || git clone https://github.com/raspberrypi/tools.git $build_folder/rpi-kernel/tools
	export ARCH=arm
	export CROSS_COMPILE=$build_folder/rpi-kernel/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-
	export INSTALL_MOD_PATH=$build_folder/rpi-kernel/rt-kernel
	export INSTALL_DTBS_PATH=$build_folder/rpi-kernel/rt-kernel

	export KERNEL=kernel7l
	cd $build_folder/rpi-kernel/linux/


    echo "-------------------------------"
    echo "------------------------------- run make"
    make bcm2711_defconfig
    cat > patch.txt << 'EOF'
629c629
< YYLTYPE yylloc;
---
> extern YYLTYPE yylloc;
EOF
	make -j20 zImage
	patch scripts/dtc/dtc-lexer.lex.c < ./patch.txt
	make -j20 zImage
	make -j20 modules
	make -j20 dtbs
	make -j20 modules_install
	make -j20 dtbs_install

	[ ! -d $INSTALL_MOD_PATH ] && mkdir $INSTALL_MOD_PATH/boot
	./scripts/mkknlimg ./arch/arm/boot/zImage $INSTALL_MOD_PATH/boot/$KERNEL.img
	cd $INSTALL_MOD_PATH/boot
	mv $KERNEL.img kernel7_rt.img
    cd $INSTALL_MOD_PATH
}


main
