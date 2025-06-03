#!/bin/bash
set -e

NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
SYSROOT=$TOOLCHAIN/sysroot

FFMPEG_SRC=/home/puffy/sang/ffmpeg_sources/ffmpeg-4.3.1
INSTALL_BASE=/home/puffy/sang/ffmpeg_build
BUILD_BASE=/home/puffy/sang/ffmpeg_sources/build_ffmpeg_shared

API=21
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

for ABI in "${ABIS[@]}"; do
    echo "Building FFmpeg for $ABI"

    case $ABI in
        armeabi-v7a)
            TARGET=armv7a-linux-androideabi
            ARCH=arm
            CPU=armv7-a
            EXTRA_CFLAGS="-mfloat-abi=softfp -mfpu=neon"
            ;;
        arm64-v8a)
            TARGET=aarch64-linux-android
            ARCH=aarch64
            CPU=armv8-a
            EXTRA_CFLAGS=""
            ;;
        x86)
            TARGET=i686-linux-android
            ARCH=x86
            CPU=i686
            EXTRA_CFLAGS=""
            ;;
        x86_64)
            TARGET=x86_64-linux-android
            ARCH=x86_64
            CPU=x86_64
            EXTRA_CFLAGS=""
            ;;
    esac

    CROSS_PREFIX=$TOOLCHAIN/bin/${TARGET}-
    CC=$TOOLCHAIN/bin/${TARGET}${API}-clang
    CXX=$TOOLCHAIN/bin/${TARGET}${API}-clang++
    NM=$TOOLCHAIN/bin/llvm-nm
    STRIP=$TOOLCHAIN/bin/llvm-strip

    PREFIX=$INSTALL_BASE/$ABI/ffmpeg_shared
    mkdir -p $BUILD_BASE/$ABI && cd $BUILD_BASE/$ABI

    # 设置 pkg-config 路径，包含所有库
    export PKG_CONFIG_PATH="
$INSTALL_BASE/fdk-aac/lib/pkgconfig:
$INSTALL_BASE/lame/lib/pkgconfig:
$INSTALL_BASE/opus/lib/pkgconfig:
$INSTALL_BASE/x264/lib/pkgconfig:
$INSTALL_BASE/x265/lib/pkgconfig
"

    # 设置编译和链接参数
    EXTRA_CFLAGS_FULL="-I$INSTALL_BASE/fdk-aac/include -I$INSTALL_BASE/lame/include -I$INSTALL_BASE/opus/include -I$INSTALL_BASE/x264/include -I$INSTALL_BASE/x265/include $EXTRA_CFLAGS"
    EXTRA_LDFLAGS_FULL="-L$INSTALL_BASE/fdk-aac/lib -L$INSTALL_BASE/lame/lib -L$INSTALL_BASE/opus/lib -L$INSTALL_BASE/x264/lib -L$INSTALL_BASE/x265/lib"

    $FFMPEG_SRC/configure \
        --prefix=$PREFIX \
        --target-os=android \
        --arch=$ARCH \
        --cpu=$CPU \
        --cross-prefix=$CROSS_PREFIX \
        --cc=$CC \
        --cxx=$CXX \
        --nm=$NM \
        --enable-cross-compile \
        --enable-static \
        --enable-shared \
        --enable-gpl \
        --enable-nonfree \
        --enable-libx264 \
        --enable-libx265 \
        --enable-libfdk-aac \
        --enable-libmp3lame \
        --enable-libopus \
        --disable-doc \
        --disable-programs \
        --disable-avdevice \
        --disable-postproc \
        --disable-avfilter \
        --enable-small \
        --enable-pic \
        --extra-cflags="$EXTRA_CFLAGS_FULL" \
        --extra-ldflags="$EXTRA_LDFLAGS_FULL" \
        --pkg-config-flags="--static"

    make -j$(nproc)
    make install

    echo "FFmpeg for $ABI build complete, libs in $PREFIX/lib"
done

