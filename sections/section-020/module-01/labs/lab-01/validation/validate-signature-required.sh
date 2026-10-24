#!/usr/bin/env bash
# PASS when the EventListener refuses pushes to main that are not signed with
# the lab webhook secret: one without X-Hub-Signature-256 and one signed with
# another secret. Each must create no PipelineRun within 30 seconds. An
# EventListener without the GitHub signature check fails here.
set -uo pipefail

NS="starfleet"
EL_NAME="starfleet-ci"
EL_URL="http://el-starfleet-ci.starfleet.svc.cluster.local:8080"
WEBHOOK_SECRET="lab-only-webhook-secret"
EVENT_LABEL="triggers.tekton.dev/triggers-eventid"

# The script that runs inside the webhook client pod. It signs the body with
# HMAC-SHA256 when a secret is given, sends it like GitHub does, and prints
# "<HTTP status> <response body>".
SEND_SCRIPT='
event="$1"; secret="$2"; body="$3"; url="$4"
args=(-sS -m 10 -o /tmp/el-response.json -w "%{http_code}" -X POST -H "Content-Type: application/json" -H "X-GitHub-Event: $event")
if [ -n "$secret" ]; then
  sig="$(printf "%s" "$body" | openssl dgst -sha256 -hmac "$secret" | awk "{print \$NF}")"
  args+=(-H "X-Hub-Signature-256: sha256=$sig")
fi
rm -f /tmp/el-response.json
code="$(curl "${args[@]}" --data-binary "$body" "$url" 2>/dev/null || true)"
printf "%s " "$code"
cat /tmp/el-response.json 2>/dev/null || true
'

random_sha() {
  # random_sha: a random 40-digit hex commit ID, so every grader event is unique.
  head -c 20 /dev/urandom | od -An -tx1 | tr -d ' \n'
}

push_payload() {
  # push_payload REF SHA: a GitHub-style push event body.
  printf '{"ref":"%s","before":"0000000000000000000000000000000000000000","after":"%s","repository":{"full_name":"starfleet/bridge","clone_url":"https://git.example.com/starfleet/bridge.git"},"pusher":{"name":"grader"},"head_commit":{"id":"%s","message":"Grader push"}}' "$1" "$2" "$2"
}

pull_request_payload() {
  # pull_request_payload ACTION NUMBER SHA BASE_BRANCH: a GitHub-style pull_request event body.
  printf '{"action":"%s","number":%s,"pull_request":{"number":%s,"title":"Grader pull request","head":{"ref":"grader-branch","sha":"%s"},"base":{"ref":"%s","sha":"0000000000000000000000000000000000000000"}},"repository":{"full_name":"starfleet/bridge","clone_url":"https://git.example.com/starfleet/bridge.git"},"sender":{"login":"grader"}}' "$1" "$2" "$2" "$3" "$4"
}

wait_for_eventlistener() {
  # wait_for_eventlistener: waits up to 3 minutes for the EventListener's Ready condition.
  local ready=""
  for _ in $(seq 1 60); do
    ready="$(kubectl -n "$NS" get eventlistener "$EL_NAME" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
    [ "$ready" = "True" ] && return 0
    sleep 3
  done
  echo "FAIL: the EventListener $EL_NAME in $NS is not Ready (Ready=${ready:-none}). Check its pod with kubectl get pods -n $NS -l eventlistener=$EL_NAME."
  exit 1
}

send_event() {
  # send_event EVENT_TYPE SIGNING_SECRET BODY: sends one webhook from the
  # client pod and sets SEND_CODE and EVENT_ID. An empty SIGNING_SECRET sends
  # no signature. Retries while the Service does not answer with 202.
  local out=""
  SEND_CODE=""
  EVENT_ID=""
  for _ in $(seq 1 20); do
    out="$(kubectl -n "$NS" exec deploy/webhook-client -- bash -c "$SEND_SCRIPT" _ "$1" "$2" "$3" "$EL_URL" 2>/dev/null || true)"
    SEND_CODE="${out%% *}"
    EVENT_ID="$(printf '%s' "$out" | sed -n 's/.*"eventID": *"\([^"]*\)".*/\1/p')"
    if [ "$SEND_CODE" = "202" ] && [ -n "$EVENT_ID" ]; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: the EventListener at $EL_URL did not accept a webhook (HTTP status '${SEND_CODE:-none}')."
  exit 1
}

count_runs() {
  # count_runs: the number of PipelineRuns in the namespace.
  local names
  names="$(kubectl -n "$NS" get pipelineruns -o name 2>/dev/null)"
  if [ -z "$names" ]; then
    echo 0
  else
    printf '%s\n' "$names" | wc -l | tr -d ' '
  fi
}

wait_for_run() {
  # wait_for_run EVENT_ID: waits up to 60 seconds for a PipelineRun created by
  # the event and sets RUN_NAME (empty when none appeared).
  RUN_NAME=""
  for _ in $(seq 1 20); do
    RUN_NAME="$(kubectl -n "$NS" get pipelineruns -l "$EVENT_LABEL=$1" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
    [ -n "$RUN_NAME" ] && return 0
    sleep 3
  done
  return 0
}

wait_for_run_end() {
  # wait_for_run_end NAME: waits up to 5 minutes for the Succeeded condition
  # to be True or False and sets RUN_STATUS.
  RUN_STATUS=""
  for _ in $(seq 1 100); do
    RUN_STATUS="$(kubectl -n "$NS" get pipelinerun "$1" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
    [ "$RUN_STATUS" = "True" ] || [ "$RUN_STATUS" = "False" ] && return 0
    sleep 3
  done
  return 0
}

run_param() {
  # run_param NAME PARAM: a parameter value of a PipelineRun.
  kubectl -n "$NS" get pipelinerun "$1" -o jsonpath="{.spec.params[?(@.name==\"$2\")].value}" 2>/dev/null
}

expect_no_run() {
  # expect_no_run EVENT_ID BEFORE_COUNT WHAT: watches for 30 seconds; fails as
  # soon as the event creates a PipelineRun or the number of PipelineRuns grows.
  local name now
  for _ in $(seq 1 10); do
    name="$(kubectl -n "$NS" get pipelineruns -l "$EVENT_LABEL=$1" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
    now="$(count_runs)"
    if [ -n "$name" ] || [ "$now" -gt "$2" ]; then
      cleanup_event "$1"
      echo "FAIL: $3 created a PipelineRun (${name:-a new run}). It must create nothing."
      exit 1
    fi
    sleep 3
  done
}

cleanup_event() {
  # cleanup_event EVENT_ID: deletes the PipelineRuns the grader's event created.
  kubectl -n "$NS" delete pipelineruns -l "$EVENT_LABEL=$1" --wait=false >/dev/null 2>&1 || true
}

wait_for_eventlistener

before="$(count_runs)"
send_event push "" "$(push_payload refs/heads/main "$(random_sha)")"
expect_no_run "$EVENT_ID" "$before" "a push to main without a signature"

before="$(count_runs)"
send_event push "not-the-webhook-secret" "$(push_payload refs/heads/main "$(random_sha)")"
expect_no_run "$EVENT_ID" "$before" "a push to main signed with the wrong secret"

echo "PASS: unsigned pushes and pushes signed with the wrong secret create no PipelineRun."
exit 0
