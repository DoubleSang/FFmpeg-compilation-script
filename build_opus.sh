#!/bin/bash

set -e

NDK=/home/puffy/sang/ffmpeg_sources/ndk/21.2.6472646/android-ndk-r21e
OPUS_SRC=/home/puffy/sang/ffmpeg_sources/opus
INSTALL_BASE=/home/puffy/sang/ffmpeg_sources/other_libs

API=21
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

for ABI in "${ABIS[@]}"; do
    echo "============================="
    echo "🔧 编译 opus for $ABI"
    echo "============================="

    case $ABI in
        armeabi-v7a)
            TARGET_HOST=armv7a-linux-androideabi
            CC_PREFIX=armv7a-linux-androideabi
            ;;
        arm64-v8a)
            TARGET_HOST=aarch64-linux-android
            CC_PREFIX=aarch64-linux-android
            ;;
        x86)
            TARGET_HOST=i686-linux-android
            CC_PREFIX=i686-linux-android
            ;;
        x86_64)
            TARGET_HOST=x86_64-linux-android
            CC_PREFIX=x86_64-linux-android
            ;;
        *)
            echo "Unsupported ABI: $ABI"
            exit 1
            ;;
    esac

    TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
    export AR=$TOOLCHAIN/bin/llvm-ar
    export AS=$TOOLCHAIN/bin/llvm-as
    export CC=$TOOLCHAIN/bin/${CC_PREFIX}${API}-clang
    export CXX=$TOOLCHAIN/bin/${CC_PREFIX}${API}-clang++
    export LD=$TOOLCHAIN/bin/ld
    export NM=$TOOLCHAIN/bin/llvm-nm
    export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
    export STRIP=$TOOLCHAIN/bin/llvm-strip
    export CFLAGS="--sysroot=$TOOLCHAIN/sysroot"

    BUILD_DIR=$OPUS_SRC/build/$ABI
    INSTALL_DIR=$INSTALL_BASE/$ABI/opus

    echo "清理并创建编译目录"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    echo "配置环境变量并运行 configure"
    "$OPUS_SRC/configure" \
        --prefix=$INSTALL_DIR \
        --host=$TARGET_HOST \
        --disable-shared \
        --enable-static \
        --with-pic

    echo "开始编译并安装 opus ($ABI)"
    make -j$(nproc)
    make install

    echo "✅ 编译完成: $INSTALL_DIR/lib/libopus.a"

    echo "-----------------------------"
    echo "创建共享库 (.so) for $ABI"
    echo "-----------------------------"

    $CC -shared -o $INSTALL_DIR/lib/libopus.so \
        -Wl,--no-undefined \
        -Wl,--whole-archive $INSTALL_DIR/lib/libopus.a -Wl,--no-whole-archive \
        -lm

    echo "✅ 共享库完成: $INSTALL_DIR/lib/libopus.so"
done

