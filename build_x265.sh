#!/bin/bash

set -e

NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
X265_SRC=/home/puffy/sang/ffmpeg_sources/x265
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
            COMPILER=$TOOLCHAIN/bin/${TARGET}${API}-clang++
            ;;
        arm64-v8a)
            TARGET=aarch64-linux-android
            COMPILER=$TOOLCHAIN/bin/${TARGET}${API}-clang++
            ;;
        x86)
            TARGET=i686-linux-android
            COMPILER=$TOOLCHAIN/bin/${TARGET}${API}-clang++
            ;;
        x86_64)
            TARGET=x86_64-linux-android
            COMPILER=$TOOLCHAIN/bin/${TARGET}${API}-clang++
            ;;
        *)
            echo "❌ Unsupported ABI: $ABI"
            exit 1
            ;;
    esac

    # 路径准备
    BUILD_DIR=$X265_SRC/build/$ABI
    INSTALL_DIR=$INSTALL_BASE/$ABI/x265
    LIB_OUTPUT=$INSTALL_DIR/lib
    mkdir -p "$BUILD_DIR" "$LIB_OUTPUT"

    # 清理旧内容
    rm -rf "$BUILD_DIR"/*
    cd "$BUILD_DIR"

    echo "🔨 配置 CMake for $ABI"
	cmake -G "Unix Makefiles" \
	    -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
	    -DANDROID_ABI=$ABI \
	    -DANDROID_PLATFORM=android-$API \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DENABLE_SHARED=OFF \
	    -DENABLE_CLI=OFF \
	    -DENABLE_ASSEMBLY=OFF \
	    -DHIGH_BIT_DEPTH=OFF \
	    -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
	    $X265_SRC/source



    echo "🏗️  编译 x265 静态库"
    make -j$(nproc)
    make install

    echo "✅ 静态库完成: $LIB_OUTPUT/libx265.a"

    echo "🔗 手动生成 libx265.so"
    $COMPILER -shared -o $LIB_OUTPUT/libx265.so \
        -Wl,--no-undefined \
        -Wl,--whole-archive $LIB_OUTPUT/libx265.a -Wl,--no-whole-archive \
        -lm -ldl -llog

    echo "✅ 动态库完成: $LIB_OUTPUT/libx265.so"
    echo
done

echo "🎉 所有 ABI 构建完成，输出在: $INSTALL_BASE/<abi>/x265"

