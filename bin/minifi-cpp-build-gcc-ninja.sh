#!/usr/bin/env bash
set -ex
set -o pipefail
shopt -sq extglob

COMPILER=gcc
GENERATOR=Ninja
BUILD_TYPE=Debug  # Debug|RelWithDebInfo|Release
HARDENED=0

BUILD_DIR="build-${COMPILER,,}-${GENERATOR,,}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "${SCRIPT_DIR}/functions.sh" ] && source "${SCRIPT_DIR}/functions.sh"
include_build_env
remove_build_dir

#CFLAGS=""
#CXXFLAGS=""

setup_compiler_env "${COMPILER}"

GENERAL_FLAGS="-DAWS_ENABLE_UNITY_BUILD=OFF -DASAN_BUILD=OFF -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DFAIL_ON_WARNINGS=OFF"
EXTENSIONS="-DENABLE_ALL=ON"

run_build
