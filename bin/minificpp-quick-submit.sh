#!/usr/bin/env bash
#
# Assumptions:
#  remote origin refers to own fork
#  remote upstream refers to upstream to which PR is to be submitted
#  The to-be-submitted changes are in the staging area. Unstaged working directory changes are restored.

set -e

usage() {
	echo "Usage: $0 <title> [improvement|bug|task|feature]" 1>&2
}

die() {
    echo "$*" 1>&2
    exit 1
}


[ $# -lt 1 -o $# -gt 2 -o -z "$1" ] && usage && exit 1

if git diff --cached --quiet; then
	die "No staged files. Add the submitted changes to the staging area first! (git add)"
fi

if [ -n "$2" ]; then
	case "$2" in
		improvement) : ;;
		bug) : ;;
		task) : ;;
		feature) : ;;
		*) usage; exit 1 ;;
	esac
fi

title="$1"
issuetype="$2"

create_result_json="$(minificpp-create-issue.sh "$title" "" "$issuetype" | tail -1)"
echo "Create result JSON: $create_result_json"

jira="$(echo $create_result_json | jq -r .key)"
echo "Jira: $jira"
[ -z "$jira" ] && exit 1

minificpp-branch-and-pr.sh "$jira" "$title"
