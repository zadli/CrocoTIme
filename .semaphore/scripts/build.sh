#!/bin/bash

set +e
sudo apt-get update > /dev/null
sudo apt-get install -y jq > /dev/null

edit_ci_message() {
	MESSAGE_TEXT="$MESSAGE_TEXT
$1"
	curl -s -X POST https://api.telegram.org/bot${ZadliCI_Token}/editMessageText -d chat_id="$TG_CROCO_CHAT_ID" -d message_id="$MESSAGE_ID" -d text="$MESSAGE_TEXT" -d silent=true | jq .
}

LAST_COMMIT=$(git rev-parse --short HEAD)

MESSAGE_TEXT="CrocoTime CI
New event on commit ($LAST_COMMIT)"

MESSAGE="$(curl -s -X POST https://api.telegram.org/bot${ZadliCI_Token}/sendMessage -d chat_id="$TG_CROCO_CHAT_ID" -d text="$MESSAGE_TEXT" -d silent=true | jq .)"
echo "$MESSAGE"

MESSAGE_ID="$(echo "$MESSAGE" | jq .result.message_id)"
echo "Message ID: $MESSAGE_ID"

status_code=$(curl --write-out %{http_code} --silent --output /dev/null -X POST http://${ZadliCI_Server_IP}/croco_build)
if [[ "$status_code" -ne 200 ]] ; then
	echo "Server status changed to $status_code"
	SEMAPHORE_JOB_RESULT="failed"
	export SEMAPHORE_JOB_RESULT=failed
	exit
elif [[ "$status_code" == "805" ]] ; then
    edit_ci_message "Just commit, skipping build task"
fi