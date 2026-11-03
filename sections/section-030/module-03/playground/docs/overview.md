# Overview: Path-Filtered And Multi-Pipeline Triggers (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Tekton Pipelines, Tekton Triggers, a working build path and the pieces for a documentation check. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** with the core interceptors in `tekton-pipelines`.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | EventListener `starfleet-ci` | Selects every Trigger with the label `team: starfleet`. Service `el-starfleet-ci`, port 8080 |
  | Trigger `github-push` | Verifies the signature and the event type, lets through only pushes to `main`, starts `ci-build` |
  | TriggerBinding `github-push` | `repo-url`, `revision` and `branch` (from the CEL overlay `branch_name`) |
  | TriggerTemplates `ci-build-run`, `docs-check-run` | Create a PipelineRun of `ci-build` or `docs-check` |
  | Pipelines `ci-build`, `docs-check`, `pr-check` | Each reports what it received in its result `summary` |
  | Deployment `webhook-client` | `curl`, `openssl` and `jq`, with payloads in `/payloads` |

- Payloads in `/payloads`: `push-main.json` (no file lists), `push-main-docs.json` (changes `docs/status.md`), `push-main-src.json` (changes `src/bridge.go`), `push-feature.json`, `pull-request-opened.json` and `pull-request-closed.json`.
- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.

## Helpers

Paste these once in each new terminal. `send_signed` signs a payload file in the client pod with the lab secret and sends it with an event type. `runs_of` lists the PipelineRuns of one event ID with their Trigger.

```sh
send_signed() {
  # send_signed EVENT_TYPE PAYLOAD_FILE
  kubectl exec -n starfleet deploy/webhook-client -- bash -c '
    signature="$(openssl dgst -sha256 -hmac lab-only-webhook-secret "$2" | awk "{print \$NF}")"
    curl -sS -X POST -H "Content-Type: application/json" -H "X-GitHub-Event: $1" \
      -H "X-Hub-Signature-256: sha256=$signature" --data-binary "@$2" \
      http://el-starfleet-ci.starfleet.svc.cluster.local:8080
    echo' _ "$1" "$2"
}
runs_of() {
  kubectl get pipelineruns -n starfleet -l "triggers.tekton.dev/triggers-eventid=$1" -L triggers.tekton.dev/trigger
}
```

Use them like this: `send_signed push /payloads/push-main-docs.json`, then `runs_of <EVENT_ID>`.

## Practice tasks

- Create the Trigger `docs-check` from the module, label it `team: starfleet`, and send `push-main-docs.json` and `push-main-src.json`. Compare the runs.
- Remove the label from the Trigger and send the documentation push again. What changes, and what does the response look like?
- Send `push-main.json`, which has no `commits`. Where does the event stop, and what does the log of the core interceptors say?
- Change the filter to also match `added` and `removed` paths, and write a payload that only removes a file under `docs/`.
- Replace `docs/` with `docs` in the filter and add a payload that changes `docs-old.txt`. Does the Trigger now start?
- Change the build Trigger so it skips pushes that only change `docs/`, and check that a documentation push starts only `docs-check`.
