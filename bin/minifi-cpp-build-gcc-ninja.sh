#!/bin/bash
set -ex
set -o pipefail

BUILD_DIR="build-gcc-ninja"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/build.env" ] && source "$SCRIPT_DIR/build.env"

rm -rf "${BUILD_DIR}"
mkdir "${BUILD_DIR}"
pushd "${BUILD_DIR}"
export CC=gcc
export CXX=g++
export CFLAGS="-O3 -pipe -march=native -Wall -Wextra -Wno-error"
export CXXFLAGS="-O3 -pipe -march=native -Wall -Wextra -Wno-error"
CMAKE_COMPILER="-DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX}"
GENERAL_FLAGS=" -DFORCE_COLORED_OUTPUT=ON -DAWS_ENABLE_UNITY_BUILD=OFF -DASAN_BUILD=OFF -DCMAKE_BUILD_TYPE=Debug -DFAIL_ON_WARNINGS=OFF"
# tensorflow: not installed
# pcap: fails
# jni: unusable binary on my system
# aws: incompatible with Werror
# sftp: slow tests
EXTENSIONS="-DENABLE_AZURE=ON -DENABLE_PYTHON=ON -DENABLE_OPS=ON -DENABLE_JNI=OFF -DENABLE_OPC=ON -DENABLE_COAP=ON -DENABLE_GPS=ON -DENABLE_MQTT=ON -DENABLE_LIBRDKAFKA=ON -DENABLE_SENSORS=ON -DENABLE_USB_CAMERA=ON -DENABLE_AWS=OFF -DENABLE_SFTP=OFF -DENABLE_OPENWSMAN=ON -DENABLE_BUSTACHE=ON -DENABLE_OPENCV=ON -DENABLE_TENSORFLOW=OFF -DENABLE_SQL=OFF -DENABLE_PCAP=OFF -DENABLE_NANOFI=ON -DENABLE_SYSTEMD=ON"
cmake -G Ninja ${CMAKE_COMPILER} ${GENERAL_FLAGS} ${EXTENSIONS} ..
nice -n 19 ninja -v -j$(nproc)
ninja linter
ctest -j8 --output-on-failure
popd # "${BUILD_DIR}"
