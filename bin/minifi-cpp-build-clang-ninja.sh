#!/usr/bin/env bash
set -ex
set -o pipefail
shopt -sq extglob
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "${SCRIPT_DIR}/functions.sh" ] && source "${SCRIPT_DIR}/functions.sh"

exec "${SCRIPT_DIR}/minifi-cpp-build.sh" --compiler=clang --generator=ninja --build-type=RelWithDebInfo
exit 0

COMPILER=$(try_commands clang clang-20)
GENERATOR=Ninja
BUILD_TYPE=RelWithDebInfo  # Debug|RelWithDebInfo|Release
HARDENED=0
BUILD_DIR="build-$(get_compiler_type "${COMPILER}")-${GENERATOR,,}"


include_build_env
remove_build_dir

CXXFLAGS+=" -stdlib=libc++"

setup_compiler_env "${COMPILER}"

GENERAL_FLAGS=""
GENERAL_FLAGS+=" -DAWS_ENABLE_UNITY_BUILD=OFF"  # unity build breaks rebuilds
GENERAL_FLAGS+=" -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DFAIL_ON_WARNINGS=OFF"
GENERAL_FLAGS+=" -DMINIFI_ADVANCED_LINK_TIME_OPTIMIZATION=ON"
#GENERAL_FLAGS+=" -DMINIFI_ADVANCED_ASAN_BUILD=ON -DENABLE_SANDBOX=OFF"  # liblzma requires disabling its sandbox with asan. Doesn't affect the library, only the xz/lzma binaries, that we don't use

#EXTENSIONS="-DENABLE_ALL=ON"  # the easy way to enable all, but won't let you override individual options

# enable all extensions, separately to make it possible to disable individual ones
EXTENSIONS="$(enable_all_extensions_cmake_flags)"
EXTENSIONS+=" -DENABLE_LUA_SCRIPTING=OFF"  # lua 5.5 is unsupported by our sol2 version, comment out the line when using Lua <5.5

run_build
