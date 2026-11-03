# Overview: GitLab And Bitbucket Interceptors (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Tekton Pipelines, Tekton Triggers and an EventListener that accepts every request. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1** and **Tekton Triggers v0.37.2** in `tekton-pipelines`. The Deployment `tekton-triggers-core-interceptors` serves the ClusterInterceptors `github`, `gitlab`, `bitbucket`, `cel` and `slack`; its log holds the reason each time an interceptor stops an event.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | EventListener `starfleet-ci` | One Trigger `github-push`, no interceptors. Service `el-starfleet-ci`, port 8080 |
  | ServiceAccount `starfleet-triggers` | Bound to `tekton-triggers-eventlistener-roles` and `tekton-triggers-eventlistener-clusterroles` |
  | TriggerBinding `github-push` | `repo-url`, `revision` and `branch` (the full ref) from a push |
  | TriggerTemplate `ci-build-run` | Creates a `PipelineRun` of `ci-build` with `generateName: ci-build-run-` |
  | Pipeline `ci-build` | Reports the values it received in its result `summary` |
  | Deployment `webhook-client` | `curl` and `openssl`, with payloads in `/payloads` |

- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.

## Helpers

Paste these once in each new terminal. `send_gitlab` sends the sample GitLab push to an EventListener; pass its name, the event name and the token.

```sh
send_gitlab() {
  # send_gitlab EVENTLISTENER_NAME EVENT TOKEN
  kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H "X-Gitlab-Event: $2" -H "X-Gitlab-Token: $3" --data-binary @/payloads/gitlab-push-main.json "http://el-$1.starfleet.svc.cluster.local:8080"
  echo
}
```

## Practice tasks

- Build the EventListener `starfleet-gitlab` from the reading. Send the push with a right token, a wrong token and the event name `Merge Request Hook`, and compare the runs.
- Read the log of `tekton-triggers-core-interceptors` after each event.
- Delete the key `secretToken` from the Secret and read what the interceptor says.
- Add the CEL interceptor and change the filter to accept `refs/heads/release` too.
- Add a second Trigger for GitHub and send one event of each provider to the same EventListener.
