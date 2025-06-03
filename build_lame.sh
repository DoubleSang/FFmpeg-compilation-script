#!/bin/bash

set -e

NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
LAME_SRC=/home/puffy/sang/ffmpeg_sources/lame
INSTALL_BASE=/home/puffy/sang/ffmpeg_sources/other_libs
BUILD_ROOT=/home/puffy/sang/ffmpeg_sources/build_lame

API=21
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

for ABI in "${ABIS[@]}"; do
    echo "============================="
    echo "🔧 编译 lame for $ABI"
    echo "============================="

    case $ABI in
        armeabi-v7a)
            TARGET_HOST=arm-linux-androideabi
            TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
            CC=$TOOLCHAIN/bin/armv7a-linux-androideabi$API-clang
            ;;
        arm64-v8a)
            TARGET_HOST=aarch64-linux-android
            TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
            CC=$TOOLCHAIN/bin/aarch64-linux-android$API-clang
            ;;
        x86)
            TARGET_HOST=i686-linux-android
            TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
            CC=$TOOLCHAIN/bin/i686-linux-android$API-clang
            ;;
        x86_64)
            TARGET_HOST=x86_64-linux-android
            TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
            CC=$TOOLCHAIN/bin/x86_64-linux-android$API-clang
            ;;
    esac

    export CC=$CC
    export AR=$TOOLCHAIN/bin/llvm-ar
    export AS=$CC
    export LD=$TOOLCHAIN/bin/ld
    export NM=$TOOLCHAIN/bin/llvm-nm
    export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
    export STRIP=$TOOLCHAIN/bin/llvm-strip
    export CFLAGS="--sysroot=$TOOLCHAIN/sysroot"

    BUILD_DIR=$BUILD_ROOT/$ABI
    INSTALL_DIR=$INSTALL_BASE/$ABI/lame

    echo "准备构建目录 $BUILD_DIR"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cp -r $LAME_SRC/* $BUILD_DIR

    cd $BUILD_DIR

    echo "运行 configure"
    ./configure \
        --prefix=$INSTALL_DIR \
        --host=$TARGET_HOST \
        --disable-shared \
        --enable-static \
        --with-pic \
        --disable-frontend

    echo "🏗️  编译并安装 lame ($ABI)"
    make -j$(nproc)
    make install

    echo "✅ 编译完成: $INSTALL_DIR/lib/libmp3lame.a"

    echo "-----------------------------"
    echo "创建共享库 (.so) for $ABI"
    echo "-----------------------------"

    $CC -shared -o $INSTALL_DIR/lib/libmp3lame.so \
        -Wl,--no-undefined \
        -Wl,--whole-archive $INSTALL_DIR/lib/libmp3lame.a -Wl,--no-whole-archive \
        -lm -ldl -llog

    echo "✅ 共享库完成: $INSTALL_DIR/lib/libmp3lame.so"
done

