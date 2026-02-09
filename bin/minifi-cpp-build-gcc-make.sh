#!/bin/sh
set -ex
set -o pipefail

BUILD_DIR="build-gcc-make"
HARDENED=0

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/build.env" ] && source "$SCRIPT_DIR/build.env"

if [ "${HARDENED}" -ne 0 ]; then
	OPT_HARDENED_FLAG="-fhardened"
else
	OPT_HARDENED_FLAG=""
fi

rm -rf "${BUILD_DIR}"
mkdir "${BUILD_DIR}"
pushd "${BUILD_DIR}"
export CC=gcc
export CXX=g++
export CFLAGS="${CFLAGS} -O3 -pipe -march=native -Wall -Wextra -pedantic -Wno-error -Wno-stringop-overflow ${OPT_HARDENED_FLAG}"
export CXXFLAGS="${CXXFLAGS} -O3 -pipe -march=native -Wall -Wextra -pedantic -Wno-error -Wno-stringop-overflow ${OPT_HARDENED_FLAG}"
GENERAL_FLAGS=" -DFORCE_COLORED_OUTPUT=ON -DAWS_ENABLE_UNITY_BUILD=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo -DFAIL_ON_WARNINGS=OFF -DMINIFI_ADVANCED_ASAN_BUILD=OFF -DMINIFI_ADVANCED_LINK_TIME_OPTIMIZATION=ON"
GENERAL_FLAGS="${GENERAL_FLAGS} -DENABLE_SANDBOX=OFF"  # liblzma requires this with asan enabled. Doesn't affect the library, only the binaries
EXTENSIONS="-DENABLE_AWS=OFF -DENABLE_COUCHBASE=OFF -DENABLE_GRPC_FOR_LOKI=OFF"
cmake "-DCMAKE_C_COMPILER=${CC}" "-DCMAKE_CXX_COMPILER=${CXX}" "-DCMAKE_C_FLAGS=${CFLAGS}" "-DCMAKE_CXX_FLAGS=${CXXFLAGS}" ${GENERAL_FLAGS} ${EXTENSIONS} ..
nice -n 10 make -j$(nproc)
make -j$(nproc) linter
ctest -j8 --output-on-failure
popd # "${BUILD_DIR}"
