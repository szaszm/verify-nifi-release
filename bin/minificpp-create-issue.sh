#!/usr/bin/env bash

usage() {
	echo "Usage: $0 <title> [description] [improvement|bug|task|feature] [-q]" 1>&2
}

[ $# -lt 1 -o $# -gt 4 ] && usage && exit 1

if [ $# -eq 4 ]; then
	if [ "$4" = "-q" ]; then
		quiet=true
	else
		quiet=false
	fi
else
	quiet=false
fi

access_token="$(cat ~/.apache-jira-access-token)"
#username="$(cat ~/.apache-jira-username)"

[ -z "$access_token" ] && usage && echo "missing access token ~/.apache-jira-access-token" 1>&2 && exit 1

if [ $# -eq 3 ]; then
	case "$3" in
		improvement) issuetype="Improvement" ;;
		bug) issuetype="Bug" ;;
		task) issuetype="Task" ;;
		feature) issuetype="New Feature" ;;
		*) usage; exit 1 ;;
	esac
else
	if [[ $title == "Fix"* || $title == "fix"* ]]; then
		issuetype="Bug"
	else
		issuetype="Improvement"
	fi
fi

title=$1
description=$2

if ! $quiet; then
	echo title: $title 1>&2
	echo description: $description 1>&2
	echo issuetype: $issuetype 1>&2
fi

PROJECT=MINIFICPP

data="{\"fields\":{\"project\":{\"key\":\"${PROJECT}\"},\"summary\":\"${title}\",\"description\":\"${description}\",\"issuetype\":{\"name\":\"$issuetype\"}}}"

if ! $quiet; then
	echo data: $data 1>&2

	set -x
fi

curl -s -S -D- -X POST --data "${data}" -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" https://issues.apache.org/jira/rest/api/2/issue

exit 0

# example output:
Note: Unnecessary use of -X or --request, POST is already inferred.
*   Trying 168.119.33.54:443...
* Connected to issues.apache.org (168.119.33.54) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.0 (OUT), TLS header, Certificate Status (22):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS header, Certificate Status (22):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS header, Finished (20):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.2 (OUT), TLS header, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: CN=*.apache.org
*  start date: Jun 29 00:00:00 2022 GMT
*  expire date: Jul 30 23:59:59 2023 GMT
*  subjectAltName: host "issues.apache.org" matched cert's "*.apache.org"
*  issuer: C=GB; ST=Greater Manchester; L=Salford; O=Sectigo Limited; CN=Sectigo RSA Domain Validation Secure Server CA
*  SSL certificate verify ok.
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
> POST /jira/rest/api/2/issue HTTP/1.1
> Host: issues.apache.org
> User-Agent: curl/7.81.0
> Accept: */*
> Content-Type: application/json
> Authorization: Bearer n0p3
> Content-Length: 201
> 
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* Mark bundle as not supporting multiuse
< HTTP/1.1 201 Created
HTTP/1.1 201 Created
< Date: Wed, 05 Apr 2023 13:55:37 GMT
Date: Wed, 05 Apr 2023 13:55:37 GMT
< Server: JIRA (via Aardvark)
Server: JIRA (via Aardvark)
< X-AREQUESTID: 835x133936783x10
X-AREQUESTID: 835x133936783x10
< X-ASESSIONID: u2cih9
X-ASESSIONID: u2cih9
< Referrer-Policy: strict-origin-when-cross-origin
Referrer-Policy: strict-origin-when-cross-origin
< X-XSS-Protection: 1; mode=block
X-XSS-Protection: 1; mode=block
< X-Content-Type-Options: nosniff
X-Content-Type-Options: nosniff
< X-Frame-Options: SAMEORIGIN
X-Frame-Options: SAMEORIGIN
< Content-Security-Policy: sandbox
Content-Security-Policy: sandbox
< Strict-Transport-Security: max-age=31536000
Strict-Transport-Security: max-age=31536000
< X-Seraph-LoginReason: OK
X-Seraph-LoginReason: OK
< X-AUSERNAME: szaszm
X-AUSERNAME: szaszm
< Cache-Control: no-cache, no-store, no-transform
Cache-Control: no-cache, no-store, no-transform
< Content-Type: application/json;charset=UTF-8
Content-Type: application/json;charset=UTF-8
< Set-Cookie: atlassian.xsrf.token=asdas; Path=/jira; Secure; SameSite=None
Set-Cookie: atlassian.xsrf.token=askldals; Path=/jira; Secure; SameSite=None
< Via: 1.1 jira2-he-de.apache.org
Via: 1.1 jira2-he-de.apache.org
< Transfer-Encoding: chunked
Transfer-Encoding: chunked

< 
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* Connection #0 to host issues.apache.org left intact
{"id":"13531590","key":"MINIFICPP-2093","self":"https://issues.apache.org/jira/rest/api/2/issue/13531590"}

