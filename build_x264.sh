#!/bin/bash
set -e

NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
X264_SRC=/home/puffy/sang/ffmpeg_sources/x264
INSTALL_BASE=/home/puffy/sang/ffmpeg_sources/other_libs

API=21
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64

for ABI in "${ABIS[@]}"; do
    echo "============================="
    echo "🔧 正在构建 ABI: $ABI"
    echo "============================="

    case $ABI in
        armeabi-v7a)
            TARGET=armv7a-linux-androideabi
            ARCH=arm
            CROSS_PREFIX=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-
            CC=$TOOLCHAIN/bin/armv7a-linux-androideabi${API}-clang
            ;;
        arm64-v8a)
            TARGET=aarch64-linux-android
            ARCH=arm64
            CROSS_PREFIX=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-
            CC=$TOOLCHAIN/bin/aarch64-linux-android${API}-clang
            ;;
        x86)
            TARGET=i686-linux-android
            ARCH=x86
            CROSS_PREFIX=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-
            CC=$TOOLCHAIN/bin/i686-linux-android${API}-clang
            ;;
        x86_64)
            TARGET=x86_64-linux-android
            ARCH=x86_64
            CROSS_PREFIX=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-
            CC=$TOOLCHAIN/bin/x86_64-linux-android${API}-clang
            ;;
        *)
            echo "❌ Unsupported ABI: $ABI"
            exit 1
            ;;
    esac

    BUILD_DIR=$X264_SRC/build/$ABI
    INSTALL_DIR=$INSTALL_BASE/$ABI/x264
    mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

    rm -rf "$BUILD_DIR"/*
    cd "$BUILD_DIR"

    echo "🔨 配置 x264 for $ABI"

    # 设置 sysroot 为 llvm 自带的 sysroot，兼容新 NDK
    SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot

    # 设置环境变量，指定交叉编译器和 sysroot
    export CC=$CC
    export CFLAGS="--sysroot=$SYSROOT"
    export LDFLAGS="--sysroot=$SYSROOT"

    $X264_SRC/configure \
        --prefix="$INSTALL_DIR" \
        --host=$TARGET \
        --enable-shared \
        --disable-cli \
        --enable-pic \
        --disable-asm \
        --sysroot="$SYSROOT"

    echo "🏗️ 编译 x264 动态库"
    make -j$(nproc)
    make install

    echo "✅ 静态库完成: $INSTALL_DIR/lib/libx264.a"
    echo
done

echo "🎉 所有 ABI 构建完成，输出在: $INSTALL_BASE/<abi>/x264"

