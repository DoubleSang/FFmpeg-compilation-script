#!/bin/bash

set -e

NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
LIBVPX_SRC=/home/puffy/sang/ffmpeg_sources/libvpx
INSTALL_BASE=/home/puffy/sang/ffmpeg_sources/other_libs
BUILD_BASE=/home/puffy/sang/ffmpeg_sources/build_libvpx

API=21
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

for ABI in "${ABIS[@]}"; do
    echo "============================="
    echo "🔧 编译 libvpx for $ABI"
    echo "============================="

    TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
    SYSROOT=$TOOLCHAIN/sysroot

    case $ABI in
        armeabi-v7a)
            TRIPLE="armv7a-linux-androideabi"
            TARGET="armv7-android-gcc"
            ;;
        arm64-v8a)
            TRIPLE="aarch64-linux-android"
            TARGET="arm64-android-gcc"
            ;;
        x86)
            TRIPLE="i686-linux-android"
            TARGET="x86-android-gcc"
            ;;
        x86_64)
            TRIPLE="x86_64-linux-android"
            TARGET="x86_64-android-gcc"
            ;;
        *)
            echo "❌ Unsupported ABI: $ABI"
            exit 1
            ;;
    esac

    export CC=$TOOLCHAIN/bin/${TRIPLE}${API}-clang
    export CXX=$TOOLCHAIN/bin/${TRIPLE}${API}-clang++
    export AR=$TOOLCHAIN/bin/llvm-ar
    export AS=$CC
    export LD=$TOOLCHAIN/bin/ld
    export STRIP=$TOOLCHAIN/bin/llvm-strip
    export NM=$TOOLCHAIN/bin/llvm-nm
    export RANLIB=$TOOLCHAIN/bin/llvm-ranlib

    export CFLAGS="--sysroot=$SYSROOT -fPIC"
    export LDFLAGS="--sysroot=$SYSROOT"

    BUILD_DIR=$BUILD_BASE/$ABI
    INSTALL_DIR=$INSTALL_BASE/$ABI/libvpx

    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    echo "🧩 配置 libvpx"

    $LIBVPX_SRC/configure \
        --prefix=$INSTALL_DIR \
        --target=$TARGET \
        --disable-examples \
        --disable-tools \
        --disable-docs \
        --disable-unit-tests \
        --disable-webm-io \
        --disable-runtime-cpu-detect \
        --enable-pic \
        --enable-vp8 \
        --enable-vp9 \
        --enable-realtime-only \
        --libdir=$INSTALL_DIR/lib

    echo "🏗️  编译并安装 libvpx ($ABI)"
    make clean || true
    make -j$(nproc)
    make install

    echo "✅ 编译完成: $INSTALL_DIR/lib/libvpx.a"
done

