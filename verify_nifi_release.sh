#!/usr/bin/env bash

set -e

GIT_TAG=$1
GIT_COMMIT_ID=$2
SHA512=$3

[ $# -ne 3 ] && echo "Usage: $0 GIT_TAG GIT_COMMIT_ID SHA512" && exit 1

WORKING_DIR=work
DIST_URL="https://dist.apache.org/repos/dist"
GIT_REPO="https://github.com/apache/nifi.git"
RELEASE_DIFF_CHECKER="$(readlink -m "$(dirname "$0")/nifi-release-tools/release-diff-checker.sh")"

TERM_RESET="\x1b[0m"
TERM_BGRED="\x1b[41m"
TERM_BGGREEN="\x1b[42m"

[ -d "$WORKING_DIR" ] && rm -rf --preserve-root "$WORKING_DIR" && echo "Removed old working directory"
mkdir -p "$WORKING_DIR" && echo "Created working directory: $WORKING_DIR"
pushd "$WORKING_DIR"

echo -n Importing release KEYS...
wget -q -O KEYS-release "$DIST_URL/release/nifi/KEYS" && gpg --import KEYS-release &>/dev/null && echo -e  ${TERM_BGGREEN}done${TERM_RESET} || (echo -e ${TERM_BGRED}failed${TERM_RESET} && exit 1)
rm KEYS-release
echo -n Importing dev KEYS...
wget -q -O KEYS-dev "$DIST_URL/dev/nifi/KEYS" && gpg --import KEYS-dev &>/dev/null && echo -e ${TERM_BGGREEN}done${TERM_RESET} || (echo -e ${TERM_BGRED}failed${TERM_RESET} && exit 1)
rm KEYS-dev

RC_PARENT_DIR_URL="$DIST_URL/dev/nifi"
RC_DIR="$(svn ls "$RC_PARENT_DIR_URL" | grep -E '[0-9]+\.[0-9]+\.[0-9]+' | tail -1 | sed -r -e 's%/$%%')"
[ -z "$RC_DIR" ] && echo -e "${TERM_BGRED}Missing RC directory${TERM_RESET}, check $RC_PARENT_DIR_URL" 1>&2 && exit 1
RC_VERSION="$(echo "${RC_DIR}" | sed -r 's/^nifi-//g')"

TARBALL_NAME="nifi-$RC_VERSION-source-release.zip"
SOURCE_URL="$RC_PARENT_DIR_URL/$RC_DIR/$TARBALL_NAME"
echo Downloading release candidate
set -x
wget -q "$SOURCE_URL"
wget -q "$SOURCE_URL.asc"
wget -q "$SOURCE_URL.sha256"
wget -q "$SOURCE_URL.sha512"
set +x

echo Checking checksums
SOURCE_SHA256="$(sha256sum "$TARBALL_NAME" | cut -d \  -f 1)"
SOURCE_SHA512="$(sha512sum "$TARBALL_NAME" | cut -d \  -f 1)"
DOWNLOADED_SHA256="$(cat "$TARBALL_NAME.sha256")"
DOWNLOADED_SHA512="$(cat "$TARBALL_NAME.sha512")"

echo -n " SHA256: (expected) $DOWNLOADED_SHA256 <=> $SOURCE_SHA256 (actual)  = "
[ -n "$SOURCE_SHA256" -a "$SOURCE_SHA256" = "$DOWNLOADED_SHA256" ] && echo -e ${TERM_BGGREEN}matching${TERM_RESET} || (echo -e ${TERM_BGRED}DIFFERENT${TERM_RESET} && exit 1)
echo -n " SHA512: (expected) $DOWNLOADED_SHA512 <=> $SOURCE_SHA512 (actual)  = "
[ -n "$SOURCE_SHA512" -a "$SOURCE_SHA512" = "$DOWNLOADED_SHA512" ] && echo -e ${TERM_BGGREEN}matching${TERM_RESET} || (echo -e ${TERM_BGRED}DIFFERENT${TERM_RESET} && exit 1)
echo -n " SHA512: (expected) $SHA512 <=> $SOURCE_SHA512 (actual)  = "
[ -n "$SOURCE_SHA512" -a "$SOURCE_SHA512" = "$SHA512" ] && echo -e ${TERM_BGGREEN}matching${TERM_RESET} || (echo -e ${TERM_BGRED}DIFFERENT${TERM_RESET} && exit 1)

echo " gpg --verify $TARBALL_NAME.asc"
gpg --verify "$TARBALL_NAME.asc"
echo " GPG returned exit code: $?"

echo -n "Extracting tarball... "
7z x "$TARBALL_NAME"
pushd "nifi-$RC_VERSION"
README_SIZE="$(wc -c README.md | cut -d \  -f 1)"
NOTICE_SIZE="$(wc -c NOTICE | cut -d \  -f 1)"
LICENSE_SIZE="$(wc -c LICENSE | cut -d \  -f 1)"
[ "$README_SIZE" -gt 16000 -a "$README_SIZE" -lt 20000 ] && echo -e "${TERM_BGGREEN}README looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}README size looks off${TERM_RESET}" && exit 1)
[ "$NOTICE_SIZE" -gt 8000 -a "$NOTICE_SIZE" -lt 10000 ] && echo -e "${TERM_BGGREEN}NOTICE looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}NOTICE size looks off${TERM_RESET}" && exit 1)
[ "$LICENSE_SIZE" -gt 21000 -a "$LICENSE_SIZE" -lt 25000 ] && echo -e "${TERM_BGGREEN}LICENSE looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}LICENSE size looks off${TERM_RESET}" && exit 1)
popd # nifi-$RC_VERSION
echo done

echo "Running release-diff-checker..."
"$RELEASE_DIFF_CHECKER" "$TARBALL_NAME" "$GIT_REPO" "$GIT_TAG"

echo "Checking git commit id..."
git clone --filter=blob:none --no-checkout --single-branch --branch $GIT_TAG https://github.com/apache/nifi.git temp-git-repo &>/dev/null
pushd temp-git-repo &>/dev/null
GIT_COMMIT_ID_ACTUAL="$(git log | head -1 | cut -d \  -f 2)"
popd &>/dev/null
rm -rf temp-git-repo
echo -n " Git commit ID: (expected) $GIT_COMMIT_ID <=> $GIT_COMMIT_ID_ACTUAL (actual)  - "
[ -n "$GIT_COMMIT_ID" -a "$GIT_COMMIT_ID" = "$GIT_COMMIT_ID_ACTUAL" ] && echo -e ${TERM_BGGREEN}matching${TERM_RESET} || (echo -e ${TERM_BGRED}DIFFERENT${TERM_RESET} && exit 1)

echo Press enter to continue building
read

echo "Build and test"
set -x
pushd "nifi-$RC_VERSION"
mvn -T 1C clean package -Pcontrib-check #-DskipTests
unzip nifi-assembly/target/nifi-$RC_VERSION-bin.zip
pushd nifi-$RC_VERSION
set +x
README_SIZE="$(wc -c README | cut -d \  -f 1)"
NOTICE_SIZE="$(wc -c NOTICE | cut -d \  -f 1)"
LICENSE_SIZE="$(wc -c LICENSE | cut -d \  -f 1)"
[ "$README_SIZE" -gt 4000 -a "$README_SIZE" -lt 6000 ] && echo -e "${TERM_BGGREEN}README looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}README size looks off${TERM_RESET}" && exit 1)
[ "$NOTICE_SIZE" -gt 95000 -a "$NOTICE_SIZE" -lt 120000 ] && echo -e "${TERM_BGGREEN}NOTICE looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}NOTICE size looks off${TERM_RESET}" && exit 1)
[ "$LICENSE_SIZE" -gt 165000 -a "$LICENSE_SIZE" -lt 185000 ] && echo -e "${TERM_BGGREEN}LICENSE looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}LICENSE size looks off${TERM_RESET}" && exit 1)
popd # nifi-$RC_VERSION (bin)
mv nifi-assembly/target/nifi-$RC_VERSION-bin.zip ../
popd # nifi-$RC_VERSION (src)

popd # WORKING_DIR
