#!/usr/bin/env bash
set -ex
set -o pipefail
shopt -sq extglob
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "${SCRIPT_DIR}/functions.sh" ] && source "${SCRIPT_DIR}/functions.sh"

COMPILER=$(try_commands clang clang-20)
CXXFLAGS="-stdlib=libc++"
exec "${SCRIPT_DIR}/minifi-cpp-build.sh" "--compiler=${COMPILER}" --generator=ninja --build-type=RelWithDebInfo
