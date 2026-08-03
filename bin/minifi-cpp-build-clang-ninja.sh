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
# SQL: needs sqlite odbc driver for testing
# SFTP: slow and broken tests
# PCAP: fails to build, some dependency issue
# OpenCV: incompatible with libc++ and C++20
EXTENSIONS="-DENABLE_AZURE=ON -DENABLE_PYTHON=ON -DENABLE_OPS=ON -DENABLE_JNI=ON -DENABLE_OPC=ON -DENABLE_COAP=ON -DENABLE_GPS=ON -DENABLE_MQTT=ON -DENABLE_LIBRDKAFKA=ON -DENABLE_SENSORS=ON -DENABLE_USB_CAMERA=ON -DENABLE_AWS=ON -DENABLE_SFTP=OFF -DENABLE_OPENWSMAN=ON -DENABLE_BUSTACHE=ON -DENABLE_OPENCV=OFF -DENABLE_TENSORFLOW=OFF -DENABLE_SQL=ON -DENABLE_PCAP=OFF -DENABLE_NANOFI=ON -DENABLE_SYSTEMD=ON -DENABLE_SCRIPTING=ON -DDISABLE_PYTHON_SCRIPTING=OFF -DENABLE_LUA_SCRIPTING=ON -DENABLE_SPLUNK=ON"

run_build
