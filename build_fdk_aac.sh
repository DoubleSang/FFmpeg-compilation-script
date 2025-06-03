#!/bin/bash
set -e

NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
FDK_AAC_SRC=/home/puffy/sang/ffmpeg_sources/fdk-aac
INSTALL_BASE=/home/puffy/sang/ffmpeg_sources/other_libs
API=21
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

for ABI in "${ABIS[@]}"; do
    echo "============================="
    echo "🔧 编译 fdk-aac for $ABI"
    echo "============================="

    case $ABI in
        armeabi-v7a)
            TARGET_HOST=arm-linux-androideabi
            TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
            CC=$TOOLCHAIN/bin/armv7a-linux-androideabi$API-clang
            CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi$API-clang++
            ;;
        arm64-v8a)
            TARGET_HOST=aarch64-linux-android
            TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
            CC=$TOOLCHAIN/bin/aarch64-linux-android$API-clang
            CXX=$TOOLCHAIN/bin/aarch64-linux-android$API-clang++
            ;;
        x86)
            TARGET_HOST=i686-linux-android
            TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
            CC=$TOOLCHAIN/bin/i686-linux-android$API-clang
            CXX=$TOOLCHAIN/bin/i686-linux-android$API-clang++
            ;;
        x86_64)
            TARGET_HOST=x86_64-linux-android
            TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
            CC=$TOOLCHAIN/bin/x86_64-linux-android$API-clang
            CXX=$TOOLCHAIN/bin/x86_64-linux-android$API-clang++
            ;;
    esac

    BUILD_DIR=$FDK_AAC_SRC/build/$ABI
    INSTALL_DIR=$INSTALL_BASE/$ABI/fdk-aac

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    rm -rf ./*

    echo "配置环境变量"
    export CC=$CC
    export CXX=$CXX
    export AR=$TOOLCHAIN/bin/llvm-ar
    export AS=$CC
    export LD=$TOOLCHAIN/bin/ld
    export STRIP=$TOOLCHAIN/bin/llvm-strip
    export NM=$TOOLCHAIN/bin/llvm-nm
    export RANLIB=$TOOLCHAIN/bin/llvm-ranlib

    echo "运行 configure"
    $FDK_AAC_SRC/configure \
        --prefix=$INSTALL_DIR \
        --host=$TARGET_HOST \
        --enable-static \
        --disable-shared \
        --with-pic

    echo "开始 make"
    make -j$(nproc)
    make install

    echo "✅ 编译完成，安装目录：$INSTALL_DIR"
done

