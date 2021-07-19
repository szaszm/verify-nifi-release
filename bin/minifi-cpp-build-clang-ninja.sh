#!/bin/bash
set -ex
set -o pipefail

BUILD_DIR="build-clang-ninja"

rm -rf "${BUILD_DIR}"
mkdir "${BUILD_DIR}"
pushd "${BUILD_DIR}"
export CC=clang
export CXX=clang++
export CFLAGS="-O3 -pipe -march=native -Wall -Wextra"
export CXXFLAGS="-O3 -pipe -march=native -Wall -Wextra"
CMAKE_COMPILER="-DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX}"
GENERAL_FLAGS=" -DFORCE_COLORED_OUTPUT=ON -DAWS_ENABLE_UNITY_BUILD=OFF -DASAN_BUILD=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DFAIL_ON_WARNINGS=ON"
# JNI, SENSORS: incompatible with FAIL_ON_WARNINGS atm
# AWS: produces warnings and no way to override Werror
# SQL: needs sqlite odbc driver for testing
EXTENSIONS="-DENABLE_PYTHON=ON -DENABLE_OPS=ON -DENABLE_JNI=ON -DENABLE_OPC=ON -DENABLE_COAP=ON -DENABLE_GPS=ON -DENABLE_MQTT=ON -DENABLE_LIBRDKAFKA=ON -DENABLE_SENSORS=ON -DENABLE_USB_CAMERA=ON -DENABLE_AWS=OFF -DENABLE_SFTP=ON -DENABLE_OPENWSMAN=ON -DENABLE_BUSTACHE=ON -DENABLE_OPENCV=ON -DENABLE_TENSORFLOW=OFF -DENABLE_SQL=OFF -DENABLE_PCAP=OFF -DENABLE_NANOFI=ON -DENABLE_SYSTEMD=ON"
cmake -G Ninja ${CMAKE_COMPILER} ${GENERAL_FLAGS} ${EXTENSIONS} ..
nice -n 19 ninja -v -j$(nproc)
ninja linter
ctest -j8 --output-on-failure
popd # "${BUILD_DIR}"
