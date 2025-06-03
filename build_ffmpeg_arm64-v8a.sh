#!/bin/bash

set -e

NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
API=21
ARCH=arm64-v8a
CPU=armv8-a
PLATFORM=aarch64-linux-android
PREFIX=/home/puffy/sang/ffmpeg_build/out/$ARCH
X264_PATH=/home/puffy/sang/ffmpeg_sources/other_libs/$ARCH/x264

export CC=$TOOLCHAIN/bin/${PLATFORM}${API}-clang
export CXX=$TOOLCHAIN/bin/${PLATFORM}${API}-clang++
export AR=$TOOLCHAIN/bin/aarch64-linux-android-ar
export LD=$TOOLCHAIN/bin/aarch64-linux-android-ld
export NM=$TOOLCHAIN/bin/aarch64-linux-android-nm
export STRIP=$TOOLCHAIN/bin/aarch64-linux-android-strip

export PKG_CONFIG_PATH=$X264_PATH/lib/pkgconfig

./configure \
    --prefix=$PREFIX \
    --target-os=android \
    --arch=aarch64 \
    --cpu=$CPU \
    --enable-cross-compile \
    --cross-prefix=$TOOLCHAIN/bin/aarch64-linux-android- \
    --cc=$CC \
    --cxx=$CXX \
    --sysroot=$TOOLCHAIN/sysroot \
    --enable-gpl \
    --enable-libx264 \
    --enable-shared \
    --disable-static \
    --disable-doc \
    --disable-programs \
    --disable-symver \
    --extra-cflags="-I$X264_PATH/include -march=$CPU" \
    --extra-ldflags="-L$X264_PATH/lib"

make -j$(nproc)
make install

# ✅ 拷贝 libx264.so
X264_SO=$X264_PATH/lib/libx264.so
DEST_SO_DIR=$PREFIX/lib

if [ -f "$X264_SO" ]; then
    echo "📦 拷贝 libx264.so 到 FFmpeg 输出目录：$DEST_SO_DIR"
    cp -v "$X264_SO" "$DEST_SO_DIR/"
else
    echo "❌ 未找到 libx264.so，请确认 x264 已正确编译：$X264_SO"
    exit 1
fi

# ✅ 拷贝 include 头文件
X264_INCLUDE_DIR=$X264_PATH/include
DEST_INCLUDE_DIR=$PREFIX/include/x264

if [ -d "$X264_INCLUDE_DIR" ]; then
    echo "📦 拷贝 x264 include 头文件到：$DEST_INCLUDE_DIR"
    mkdir -p "$DEST_INCLUDE_DIR"
    cp -v "$X264_INCLUDE_DIR"/*.h "$DEST_INCLUDE_DIR/"
else
    echo "❌ 未找到 x264 include 目录，请确认路径：$X264_INCLUDE_DIR"
    exit 1
fi


echo "✅ 编译完成，所有文件已就绪"

