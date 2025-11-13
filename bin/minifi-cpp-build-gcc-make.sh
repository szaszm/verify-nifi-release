#!/bin/sh
set -ex
set -o pipefail

BUILD_DIR="build-gcc-make"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/build.env" ] && source "$SCRIPT_DIR/build.env"

rm -rf "${BUILD_DIR}"
mkdir "${BUILD_DIR}"
pushd "${BUILD_DIR}"
export CC=gcc
export CXX=g++
export CFLAGS="${CFLAGS} -O3 -pipe -march=native -Wall -Wextra -Wno-error -Wno-stringop-overflow -fhardened"
export CXXFLAGS="${CXXFLAGS} -O3 -pipe -march=native -Wall -Wextra -Wno-error -Wno-stringop-overflow -fhardened"
GENERAL_FLAGS=" -DFORCE_COLORED_OUTPUT=ON -DAWS_ENABLE_UNITY_BUILD=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DFAIL_ON_WARNINGS=OFF -DMINIFI_ADVANCED_ASAN_BUILD=ON -DMINIFI_ADVANCED_LINK_TIME_OPTIMIZATION=ON"
GENERAL_FLAGS="${GENERAL_FLAGS} -DENABLE_SANDBOX=OFF"  # liblzma requires this with asan enabled. Doesn't affect the library, only the binaries
EXTENSIONS="-DENABLE_AWS=OFF -DENABLE_COUCHBASE=OFF"
cmake "-DCMAKE_C_COMPILER=${CC}" "-DCMAKE_CXX_COMPILER=${CXX}" "-DCMAKE_C_FLAGS=${CFLAGS}" "-DCMAKE_CXX_FLAGS=${CXXFLAGS}" ${GENERAL_FLAGS} ${EXTENSIONS} ..
nice -n 19 make -j$(nproc)
make -j$(nproc) linter
ctest -j8 --output-on-failure
popd # "${BUILD_DIR}"
