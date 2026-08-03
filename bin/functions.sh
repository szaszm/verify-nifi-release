# no shebang, this script provides functions and is not supposed to be directly calle

print_usage() {
	echo "Usage: ${0} --compiler=COMPILER --generator=<make|ninja> --build-type=<Debug|Release|RelWithDebInfo|MinSizeRel> [--hardened] [--build-dir=DIR] [--help]"
}

parse_opts() {
	options="$(getopt -l "help,compiler:,generator:,build-type:,hardened,build-dir:" -o "hc:g:t:rd:" -- "$@")"
	eval set -- "$options"
	while true; do
		case "${1}" in
			-h|--help) print_usage; exit 0 ;;
			-c|--compiler)
				shift
				COMPILER="${1}"
				;;
			-g|--generator)
				shift
				GENERATOR="${1}"
				;;
			-t|--build-type)
				shift
				BUILD_TYPE="${1}"
				;;
			-r|--hardened) HARDENED=1 ;;
			-d|--build-dir)
				shift
				BUILD_DIR="${1}"
				;;
			--) shift; break ;;
			
		esac
		shift
	done
}

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

try_commands() {
	while [ "$#" -gt 0 ]; do
		local compiler="${1}"
		if command -v "${compiler}" > /dev/null; then
			# command exists
			echo "${compiler}"
			break
		fi
		shift
	done
}

enable_all_extensions_cmake_flags() {
	grep -Po '(?!add_minifi_option\()(ENABLE_(?!ALL)[A-Z]+)' cmake/MiNiFiOptions.cmake | sed -e "s/^/-D/g" -e "s/$/=ON/g"
}


setup_compiler_env() {
	local compiler="${1:-gcc}"
	local compiler_type="$(get_compiler_type "${compiler}")"
	declare -i compiler_major_ver="$(get_compiler_major_ver "${compiler}")"
	local compiler_suffix=-"${compiler_major_ver}"
	if [ -z "${compiler_major_ver}" -o "${compiler_major_ver}" -eq 0 ]; then
		compiler_suffix=""
	fi
	# common flags
	CFLAGS+=" -pipe -march=native -Wall -Wextra -pedantic -Wno-error"
	CXXFLAGS+=" -pipe -march=native -Wall -Wextra -pedantic -Wno-error"
	case "${compiler_type}" in
		gcc)
			export CC=gcc${compiler_suffix}
			export CXX=g++${compiler_suffix}
			CFLAGS+=" -Wno-stringop-overflow"
			CXXFLAGS+=" -Wno-stringop-overflow"
			;;
		clang)
			export CC=clang${compiler_suffix}
			export CXX=clang++${compiler_suffix}
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

	CMAKE_COMPILER=("-DCMAKE_C_COMPILER=${CC}" "-DCMAKE_CXX_COMPILER=${CXX}" "-DCMAKE_C_FLAGS=${CFLAGS}" "-DCMAKE_CXX_FLAGS=${CXXFLAGS}")
}

generator_flags() {
	local generator="${1}"
	if [ "${generator}" = "Ninja" ]; then
		echo "-DFORCE_COLORED_OUTPUT=ON"
	fi
}

run_build() {
	local generator_full=""
	case "${GENERATOR,,}" in
		gmake|make|"unix makefiles")
			generator_full="Unix Makefiles"
			;;
		ninja)
			generator_full="Ninja"
			;;
	esac
	pushd "${BUILD_DIR}"
	cmake -G "${generator_full}" $(generator_flags "${GENERATOR}") "${CMAKE_COMPILER[@]}" ${GENERAL_FLAGS} ${EXTENSIONS} ..
	nice -n 19 cmake --build . --parallel $(nproc)
	cmake --build . --target linter
	nice -n 19 cmake --build . --parallel $(nproc) --target package
	ctest -j8 --output-on-failure
	popd # "${BUILD_DIR}"
}
