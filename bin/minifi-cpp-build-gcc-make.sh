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
export CFLAGS="${CFLAGS} -O3 -pipe -march=native -Wall -Wextra -Wno-error -Wno-stringop-overflow"
export CXXFLAGS="${CXXFLAGS} -O3 -pipe -march=native -Wall -Wextra -Wno-error -Wno-stringop-overflow"
CMAKE_COMPILER="-DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX}"
GENERAL_FLAGS=" -DFORCE_COLORED_OUTPUT=ON -DAWS_ENABLE_UNITY_BUILD=OFF -DASAN_BUILD=OFF -DCMAKE_BUILD_TYPE=Debug -DFAIL_ON_WARNINGS=OFF"
EXTENSIONS=""
cmake ${CMAKE_COMPILER} ${GENERAL_FLAGS} ${EXTENSIONS} ..
nice -n 19 make -j$(nproc)
make -j$(nproc) linter
ctest -j8 --output-on-failure
popd # "${BUILD_DIR}"
