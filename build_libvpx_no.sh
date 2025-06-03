#!/bin/bash

set -e

# === 配置路径 ===
NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
LIBVPX_SRC=/home/puffy/sang/ffmpeg_sources/libvpx
INSTALL_BASE=/home/puffy/sang/ffmpeg_sources/other_libs
BUILD_BASE=/home/puffy/sang/ffmpeg_sources/build_libvpx

API=21
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

# === 开始循环编译 ===
for ABI in "${ABIS[@]}"; do
    echo "============================="
    echo "🔧 编译 libvpx for $ABI"
    echo "============================="

    TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
    SYSROOT=$TOOLCHAIN/sysroot

    case $ABI in
        armeabi-v7a)
            TARGET="armv7-android-gcc"
            TRIPLE="armv7a-linux-androideabi"
            ;;
        arm64-v8a)
            TARGET="arm64-linux-gcc"
            TRIPLE="aarch64-linux-android"
            ;;
        x86)
            TARGET="x86-linux-gcc"
            TRIPLE="i686-linux-android"
            ;;
        x86_64)
            TARGET="x86_64-linux-gcc"
            TRIPLE="x86_64-linux-android"
            ;;
        *)
            echo "❌ Unsupported ABI: $ABI"
            exit 1
            ;;
    esac

    CC=$TOOLCHAIN/bin/${TRIPLE}${API}-clang
    CXX=$TOOLCHAIN/bin/${TRIPLE}${API}-clang++

    BUILD_DIR=$BUILD_BASE/$ABI
    INSTALL_DIR=$INSTALL_BASE/$ABI/libvpx

    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    echo "🧩 配置 libvpx"

    export CC=$CC
    export CXX=$CXX
    export CFLAGS="--sysroot=$SYSROOT -fPIC"
    export LDFLAGS="--sysroot=$SYSROOT"

    $LIBVPX_SRC/configure \
        --prefix=$INSTALL_DIR \
        --target=$TARGET \
        --disable-examples \
        --disable-tools \
        --disable-docs \
        --disable-unit-tests \
        --enable-pic \
        --disable-webm-io \
        --disable-runtime-cpu-detect \
        --enable-vp8 \
        --enable-vp9 \
        --libdir=$INSTALL_DIR/lib

    echo "🏗️  编译并安装 libvpx ($ABI)"
    make clean || true
    make -j$(nproc)
    make install

    echo "✅ 编译完成: $INSTALL_DIR/lib/libvpx.a"
done

