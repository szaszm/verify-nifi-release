#!/usr/bin/env bash
#
# Assumptions:
#  remote origin refers to own fork
#  remote upstream refers to upstream to which PR is to be submitted

set -e

usage() {
	echo "Usage: $0 <jira> <title>" 1>&2
}

die() {
    echo "$*" 1>&2
    exit 1
}

[ $# -lt 1 -o $# -gt 2 -o -z "$1" -o -z "$2" ] && usage && exit 1

jira="$1"
title="$2"

github_user="$(git remote -v | grep origin | cut -d : -f 2 | cut -d / -f 1 | head -1)"
echo "GitHub user: $github_user"

starting_branch="$(git rev-parse --abbrev-ref HEAD)"
echo "Starting branch: $starting_branch"

set -x

git checkout upstream/main
git checkout -b "$jira"
git commit -m "$jira $title" --signoff --gpg-sign || die "Failed to commit, bailing"
git push --set-upstream origin "$jira"
xdg-open "https://github.com/apache/nifi-minifi-cpp/compare/main...${github_user}:nifi-minifi-cpp:${jira}?expand=1"
git checkout "$starting_branch"
