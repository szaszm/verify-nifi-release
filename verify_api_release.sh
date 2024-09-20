#!/usr/bin/env bash

set -e

GIT_TAG=$1
GIT_COMMIT_ID=$2
SHA512=$3

[ $# -ne 3 ] && echo "Usage: $0 GIT_TAG GIT_COMMIT_ID SHA512" && exit 1

WORKING_DIR=work
DIST_URL="https://dist.apache.org/repos/dist"
GIT_REPO="https://github.com/apache/nifi-api.git"
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

VERSION="$(echo "${GIT_TAG}" | sed -r -e 's/^nifi-api-//g' -e 's/-RC[0-9]+$//g')"
echo version: ${VERSION}

RC_PARENT_DIR_URL="$DIST_URL/dev/nifi"
RC_DIR="$(svn ls "$RC_PARENT_DIR_URL" | grep "nifi-api-${VERSION}" | tail -1 | sed -r -e 's%/$%%')"
[ -z "$RC_DIR" ] && echo -e "${TERM_BGRED}Missing RC directory${TERM_RESET}, check $RC_PARENT_DIR_URL" 1>&2 && exit 1
RC_VERSION="$(echo "${RC_DIR}" | sed -r 's/^nifi-api-//g')"

TARBALL_NAME="nifi-api-$RC_VERSION-source-release.zip"
SOURCE_URL="$RC_PARENT_DIR_URL/$RC_DIR/$TARBALL_NAME"
echo Downloading release candidate
set -x
wget -q "$SOURCE_URL"
wget -q "$SOURCE_URL.asc"
wget -q "$SOURCE_URL.sha512"
set +x

echo Checking checksums
SOURCE_SHA512="$(sha512sum "$TARBALL_NAME" | cut -d \  -f 1)"
DOWNLOADED_SHA512="$(cat "$TARBALL_NAME.sha512")"

echo -n " SHA512: (expected) $DOWNLOADED_SHA512 <=> $SOURCE_SHA512 (actual)  = "
[ -n "$SOURCE_SHA512" -a "$SOURCE_SHA512" = "$DOWNLOADED_SHA512" ] && echo -e ${TERM_BGGREEN}matching${TERM_RESET} || (echo -e ${TERM_BGRED}DIFFERENT${TERM_RESET} && exit 1)
echo -n " SHA512: (expected) $SHA512 <=> $SOURCE_SHA512 (actual)  = "
[ -n "$SOURCE_SHA512" -a "$SOURCE_SHA512" = "$SHA512" ] && echo -e ${TERM_BGGREEN}matching${TERM_RESET} || (echo -e ${TERM_BGRED}DIFFERENT${TERM_RESET} && exit 1)

echo " gpg --verify $TARBALL_NAME.asc"
gpg --verify "$TARBALL_NAME.asc"
echo " GPG returned exit code: $?"

echo -n "Extracting tarball... "
7z x "$TARBALL_NAME"
pushd "nifi-api-$RC_VERSION"
README_SIZE="$(wc -c README.md | cut -d \  -f 1)"
NOTICE_SIZE="$(wc -c NOTICE | cut -d \  -f 1)"
LICENSE_SIZE="$(wc -c LICENSE | cut -d \  -f 1)"
[ "$README_SIZE" -gt 1800 -a "$README_SIZE" -lt 2100 ] && echo -e "${TERM_BGGREEN}README looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}README size looks off${TERM_RESET}" && exit 1)
[ "$NOTICE_SIZE" -gt 130 -a "$NOTICE_SIZE" -lt 190 ] && echo -e "${TERM_BGGREEN}NOTICE looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}NOTICE size looks off${TERM_RESET}" && exit 1)
[ "$LICENSE_SIZE" -gt 10000 -a "$LICENSE_SIZE" -lt 12500 ] && echo -e "${TERM_BGGREEN}LICENSE looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}LICENSE size looks off${TERM_RESET}" && exit 1)
popd # nifi-api-$RC_VERSION
echo done

echo "Running release-diff-checker to diff the source tarball and the git tag..."
"$RELEASE_DIFF_CHECKER" "$TARBALL_NAME" "$GIT_REPO" "$GIT_TAG"

echo "Checking git commit id..."
git clone --filter=blob:none --no-checkout --single-branch --branch "$GIT_TAG" "$GIT_REPO" temp-git-repo &>/dev/null
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
pushd "nifi-api-$RC_VERSION"
./mvnw clean verify
unzip target/nifi-api-$RC_VERSION.jar
set +x
NOTICE_SIZE="$(wc -c META-INF/NOTICE | cut -d \  -f 1)"
LICENSE_SIZE="$(wc -c META-INF/LICENSE | cut -d \  -f 1)"
[ "$NOTICE_SIZE" -gt 130 -a "$NOTICE_SIZE" -lt 190 ] && echo -e "${TERM_BGGREEN}NOTICE looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}NOTICE size looks off${TERM_RESET}" && exit 1)
[ "$LICENSE_SIZE" -gt 10000 -a "$LICENSE_SIZE" -lt 12500 ] && echo -e "${TERM_BGGREEN}LICENSE looks reasonable${TERM_RESET}" || (echo -e "${TERM_BGRED}LICENSE size looks off${TERM_RESET}" && exit 1)
popd # nifi-api-$RC_VERSION (src)

popd # WORKING_DIR
