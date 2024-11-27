#!/usr/bin/env bash

set -e

usage() {
	echo "Usage: $0 <pull-request-id>"
}

cleanup_and_die() {
	if [ -n "${1}" ]; then
		echo Merge or rebase failed, cleaning up merge branch of \#${0} before exiting
		git rebase --abort
		git checkout main
		git branch -D "merge-${1}"
	fi
	exit 1
}

[ $# -ne 1 ] && usage 1>&2 && exit 1

pull_id=$1

pull_json="$(curl -s -S -H "Accept: application/vnd.github+json" https://api.github.com/repos/apache/nifi-minifi-cpp/pulls/$pull_id)"
author="$(echo $pull_json | jq -r '.head.user.login')"
branch="$(echo $pull_json | jq -r '.head.ref')"
title="$(echo $pull_json | jq -r '.title')"
# modified sed expression to remove trailing blank lines from https://stackoverflow.com/questions/7359527/removing-trailing-starting-newlines-with-sed-awk-tr-and-friends
body="$(echo $pull_json | jq -r '.body' | sed -e '/^Thank you for submitting a contribution/,$d' -e '/^\s*https:\/\/issues.apache.org\/jira/d' -e '/Depends on https:\/\/github.com/d' | sed -e :a -e '/[^[:blank:]]/,$!d; /^[[:space:]_\-]*$/{ $d; N; ba' -e '}' | sed -e 's/\r//g')"
base_branch="$(echo $pull_json | jq -r '.base.ref')"

echo base branch: $(echo $pull_json | jq -r '.base.ref')
echo title: $title
echo author: $author
echo branch: $branch
echo ----------------------------------------------------
echo "${body}"
echo ----------------------------------------------------

message_args=(-m "$title")
if [ -n "${body}" ]; then
	message_args=("${message_args[@]}" "-m" "${body}")
fi
message_args=("${message_args[@]}" "-m" "Closes #${pull_id}")

# assuming remote == author
set -x
git checkout main
echo Delete leftover merge branches if any. Failure is normal and ignored.
git branch -D merge-${pull_id} || :
git pull
git fetch $author
git checkout $author/$branch
git checkout -b merge-${pull_id} --track $author/$branch
git pull --rebase
git rebase --onto main upstream/$base_branch merge-${pull_id} || (echo 'Rebase failed. Starting subshell to resolve conflicts. Run "exit 0" if you successfully finished the rebase, or "exit 1" if you want to abort'; bash) || cleanup_and_die ${pull_id}
git checkout main
git merge --squash --no-commit merge-${pull_id} || cleanup_and_die ${pull_id}
git branch -D merge-${pull_id}
author_name_email="$(git log --format='%an <%ae>' "${base_branch}...${author}/${branch}" | tail -1)"
git commit --signoff --gpg-sign --author="$author_name_email" "${message_args[@]}"
