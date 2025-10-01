#!/usr/bin/env bash

#set -x

usage() {
	echo "Usage: $0 <MINIFICPP-1337>"
}

[ $# -lt 1 -o $# -gt 1 ] && usage && exit 1

access_token="$(cat ~/.apache-jira-access-token)"
[ -z "$access_token" ] && usage && echo "missing access token ~/.apache-jira-access-token" 1>&2 && exit 1

jira=$1

transitions="$(curl -s -S -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" https://issues.apache.org/jira/rest/api/2/issue/$jira/transitions)"
transition_id="$(echo $transitions | jq '(.transitions | map(select(.to.name == "Resolved")))[0].id | tonumber')"
[ -z "$transition_id" ] && echo "missing \"Resolved\" transition" 1>&2 && echo $transitions | jq 1>&2 && exit 1

issuejson="$(curl -s -S -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" https://issues.apache.org/jira/rest/api/2/issue/$jira)"
issuetype="$(echo $issuejson | jq -r '.fields.issuetype.name | ascii_downcase')"
case "$issuetype" in
	improvement) resolution="Done" ;;
	bug) resolution="Fixed" ;;
	task) resolution="Done" ;;
	feature) resolution="Done" ;;
	*) resolution="Done" ;;
esac

data="{\"update\":{},\"transition\":{\"id\":\"$transition_id\"},\"fields\":{\"resolution\":{\"name\": \"$resolution\"}}}"

echo "Transitioning to \"Resolved\""
# curl produces no output
curl -s -S -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" -X POST --data "${data}" "https://issues.apache.org/jira/rest/api/2/issue/$jira/transitions"
echo "  exit code: $?"

fix_version="1.0.0"
echo "Setting fix version to $fix_version"
fix_version_data="{\"update\":{\"fixVersions\":[{\"set\":[{\"name\":\"$fix_version\"}]}]}}"
curl -s -S -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" -X PUT --data "${fix_version_data}" "https://issues.apache.org/jira/rest/api/2/issue/$jira"
echo "  exit code: $?"
