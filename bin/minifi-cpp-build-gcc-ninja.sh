#!/usr/bin/env bash
set -ex
set -o pipefail
shopt -sq extglob
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
exec "${SCRIPT_DIR}/minifi-cpp-build.sh" "--compiler=gcc" --generator=ninja --build-type=RelWithDebInfo
