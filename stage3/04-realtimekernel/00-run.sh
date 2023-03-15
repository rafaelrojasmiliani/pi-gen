#!/bin/bash

main() {
    # taken from https://lemariva.com/blog/2019/09/raspberry-pi-4b-preempt-rt-kernel-419y-performance-test
    # and frmom here https://www.raspberrypi.com/documentation/computers/linux_kernel.html for arm64
    echo "--------------------------------------------------------------------"
    echo "------------- cross compilation started ----------------------------"
    echo "--------------------------------------------------------------------"
    set -x

    local build_folder=${ROOTFS_DIR}/kernel_cross
    export LINUX_KERNEL_VERSION=5.15

    if [ ! -d $build_folder/rpi-kernel/linux ]; then
        git clone --depth=1 https://github.com/raspberrypi/linux.git \
            -b rpi-5.15.y $build_folder/rpi-kernel/linux

        cd $build_folder/rpi-kernel/linux/ # change directory for the patch command

        export PATCH=$(curl -s https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/${LINUX_KERNEL_VERSION}/ | sed -n 's:.*<a href="\(.*\).patch.gz">.*:\1:p' | sort -V | tail -1) &&
            echo "Downloading patch ${PATCH}" &&
            curl https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/${LINUX_KERNEL_VERSION}/${PATCH}.patch.gz --output $build_folder/rpi-kernel/linux/${PATCH}.patch.gz &&
            gzip -cd $build_folder/rpi-kernel/linux//${PATCH}.patch.gz | patch -p1 --verbose
    fi

    export KERNEL=kernel8
    export ARCH=arm64
    export CROSS_COMPILE=aarch64-linux-gnu-
    export INSTALL_MOD_PATH=${ROOTFS_DIR}
    export INSTALL_DTBS_PATH=$build_folder/rpi-kernel/rt-kernel

    cd $build_folder/rpi-kernel/linux/

    make clean
    make bcm2711_defconfig
    ./scripts/config --disable CONFIG_VIRTUALIZATION
    ./scripts/config --enable CONFIG_PREEMPT_RT
    ./scripts/config --disable CONFIG_RCU_EXPERT
    ./scripts/config --enable CONFIG_RCU_BOOST
    ./scripts/config --set-val CONFIG_RCU_BOOST_DELAY 500
    cat >patch.txt <<'EOF'
629c629
< YYLTYPE yylloc;
---
> extern YYLTYPE yylloc;
EOF
    make -j20 Image
    patch scripts/dtc/dtc-lexer.lex.c <./patch.txt
    make -j20 Image
    make -j20 modules
    make -j20 dtbs
    make -j20 modules_install
    make -j20 dtbs_install

    [ -d $INSTALL_MOD_PATH/boot ] || mkdir $INSTALL_MOD_PATH/boot
    cp ./arch/arm64/boot/Image $INSTALL_MOD_PATH/boot/$KERNEL.img
    cp $build_folder/rpi-kernel/rt-kernel/broadcom/* ${ROOTFS_DIR}/boot/
    cp $build_folder/rpi-kernel/rt-kernel/overlays/* \
        ${ROOTFS_DIR}/boot/overlays/

}

main
