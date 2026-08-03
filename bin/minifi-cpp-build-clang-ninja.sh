#!/bin/bash
set -ex
set -o pipefail

shopt -sq extglob

COMPILER=clang-20
GENERATOR=Ninja
BUILD_TYPE=RelWithDebInfo  # Debug|RelWithDebInfo|Release
HARDENED=0


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "${SCRIPT_DIR}/functions.sh" ] && source "${SCRIPT_DIR}/functions.sh"

BUILD_DIR="build-$(get_compiler_type "${COMPILER}")-${GENERATOR,,}"

include_build_env
remove_build_dir

#CFLAGS=""
CXXFLAGS+=" -stdlib=libc++"

setup_compiler_env "${COMPILER}"

GENERAL_FLAGS="-DAWS_ENABLE_UNITY_BUILD=OFF -DASAN_BUILD=OFF -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DFAIL_ON_WARNINGS=OFF"
EXTENSIONS="$(grep -Po '(?!add_minifi_option\()(ENABLE_(?!ALL)[A-Z]+)' cmake/MiNiFiOptions.cmake | sed -e "s/^/-D/g" -e "s/$/=ON/g")"

run_build
