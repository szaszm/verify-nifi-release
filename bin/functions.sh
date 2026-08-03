# no shebang, this script provides functions and is not supposed to be directly calle

include_build_env() {
	local name="${SCRIPT_DIR}/build.env"
	if [ -f "${name}" ]; then
		source "${name}"
	fi
}

remove_build_dir() {
	if [ -z "${BUILD_DIR}" ]; then
		echo "can't delete empty build dir" 1>&2
		exit 1
	fi
	rm -rf "${BUILD_DIR}"
	mkdir "${BUILD_DIR}"
}

get_compiler_type() {
	local compiler="${1}"
	if [ -z "${compiler}" ]; then
		echo "get_compiler_type: missing argument" 1>&2
		exit 1
	fi
	local compiler_type="${compiler%-[0-9]*}"
	echo $compiler_type
}

get_compiler_major_ver() {
	local compiler="${1}"
	if [ -z "${compiler}" ]; then
		echo "get_compiler_type: missing argument" 1>&2
		exit 1
	fi
	declare -i compiler_major_ver="${compiler/#+([[:alpha:]])[-]/}"
	echo "${compiler_major_ver}"
}


setup_compiler_env() {
	local compiler="${1:-gcc}"
	local compiler_type="$(get_compiler_type "${compiler}")"
	declare -i compiler_major_ver="$(get_compiler_major_ver "${compiler}")"
	local compiler_suffix=-"${compiler_major_ver}"
	if [ -z "${compiler_major_ver}" -o "${compiler_major_ver}" -eq 0 ]; then
		compiler_suffix=""
	fi
	case "${compiler_type}" in
		gcc)
			export CC=gcc${compiler_suffix}
			export CXX=g++${compiler_suffix}
			;;
		clang)
			export CC=clang${compiler_suffix}
			export CXX=clang${compiler_suffix}
			;;
		*)
			echo "unknown compiler type, skipping CC/CXX setup" 1>&2
			;;
	esac
	# only GCC supports -fhardened
	if [ "${compiler_type}" = "gcc" -a "${HARDENED}" -eq 1 ]; then
		CFLAGS+=" -fhardened"
		CXXFLAGS+=" -fhardened"
	fi

	# common flags
	CFLAGS+=" -pipe -march=native -Wall -Wextra -pedantic -Wno-error -Wno-stringop-overflow"
	CXXFLAGS+=" -pipe -march=native -Wall -Wextra -pedantic -Wno-error -Wno-stringop-overflow"
	CMAKE_COMPILER="-DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX}"
}

generator_flags() {
	local generator="${1}"
	if [ "${generator}" = "Ninja" ]; then
		echo "-DFORCE_COLORED_OUTPUT=ON"
	fi
}

run_build() {
	pushd "${BUILD_DIR}"
	cmake -G "${GENERATOR}" $(generator_flags "${GENERATOR}") ${CMAKE_COMPILER} ${GENERAL_FLAGS} ${EXTENSIONS} ..
	nice -n 19 cmake --build . --parallel $(nproc)
	cmake --build . --target linter
	ctest -j8 --output-on-failure
	popd # "${BUILD_DIR}"
}
