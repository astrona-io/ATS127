# Solution: Repair An Event-Driven CI System

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks six things: the EventListener is ready and selects the two standalone Triggers by label; `starfleet-pr-runner` may create PipelineRuns and nothing broader; a push to `main` creates one `ci-build` run; an opened pull request creates one `pr-check` run; and closed, wrong-base and unsigned pull requests create nothing.

## Step 1: Send both events

Define a helper on your machine that signs a file in the client pod and sends it with an event type:

```sh
send_signed() {
  kubectl exec -n starfleet deploy/webhook-client -- bash -c '
    signature="$(openssl dgst -sha256 -hmac lab-only-webhook-secret "$2" | awk "{print \$NF}")"
    curl -sS -X POST -H "Content-Type: application/json" -H "X-GitHub-Event: $1" \
      -H "X-Hub-Signature-256: sha256=$signature" --data-binary "@$2" \
      http://el-starfleet-ci.starfleet.svc.cluster.local:8080
    echo' _ "$1" "$2"
}
send_signed push /payloads/push-main.json
send_signed pull_request /payloads/pull-request-opened.json
```

Both answer `202` with an `eventID`. Look for runs and for interceptor answers:

```sh
kubectl get pipelineruns -n starfleet
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=5
```

There are no runs, and the core interceptors did not answer anything for these two events: no interceptor was called at all. So no Trigger was selected.

## Step 2: Fix the label selector

Compare the EventListener's selector with the Triggers' labels:

```sh
kubectl get eventlistener starfleet-ci -n starfleet -o jsonpath='{.spec.labelSelector}{"\n"}'
kubectl get triggers -n starfleet --show-labels
```

The EventListener selects `team: starfleet-ci`; both Triggers carry `team: starfleet`. The Triggers' labels stay, so fix the selector.

Save this as `eventlistener-starfleet-ci.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: starfleet-ci
  namespace: starfleet
spec:
  serviceAccountName: starfleet-triggers
  labelSelector:
    matchLabels:
      team: starfleet
```

Apply it, and send both events again:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
send_signed push /payloads/push-main.json
send_signed pull_request /payloads/pull-request-opened.json
```

Then check the result:

```sh
kubectl get pipelineruns -n starfleet -L triggers.tekton.dev/trigger
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=8
```

The push now creates a `ci-build-run-` run with `branch` = `main`. The pull request still creates nothing. In the log, the `github` interceptor of `github-pull-request` answered the pull request with `event type pull_request is not allowed`.

## Step 3: Fix the event type

```sh
kubectl get trigger github-pull-request -n starfleet -o jsonpath='{.spec.interceptors[0].params[?(@.name=="eventTypes")].value}{"\n"}'
```

The Trigger allows `pull-request`, with a hyphen. GitHub sends `pull_request`, with an underscore.

Save this as `trigger-github-pull-request.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: Trigger
metadata:
  name: github-pull-request
  namespace: starfleet
  labels:
    team: starfleet
spec:
  serviceAccountName: starfleet-pr-runner
  interceptors:
    - name: verify-github-pull-request
      ref:
        name: github
      params:
        - name: secretRef
          value:
            secretName: github-webhook-secret
            secretKey: secretToken
        - name: eventTypes
          value: ["pull_request"]
    - name: only-open-pull-requests-to-main
      ref:
        name: cel
      params:
        - name: filter
          value: "body.action in ['opened', 'synchronize', 'reopened'] && body.pull_request.base.ref == 'main'"
  bindings:
    - ref: github-pull-request
  template:
    ref: pr-check-run
```

Apply it, and send the pull request again. The response's `eventID` is the one to look for:

```sh
kubectl apply -f trigger-github-pull-request.yaml
send_signed pull_request /payloads/pull-request-opened.json
```

Still no `pr-check` run. Both interceptors continue now, so read the EventListener's log for the event ID:

```sh
tkn eventlistener logs starfleet-ci -n starfleet -t 30 | grep <EVENT_ID>
```

The EventListener resolved the parameters, then failed to create the `PipelineRun`: the error says that `system:serviceaccount:starfleet:starfleet-pr-runner` is forbidden to create `pipelineruns`. The Trigger sets `serviceAccountName: starfleet-pr-runner`, so the EventListener impersonates that ServiceAccount, and it has no permissions.

## Step 4: Let starfleet-pr-runner create PipelineRuns

Give it exactly one permission with a Role and a RoleBinding.

Save this as `rbac-starfleet-pr-runner.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pipelinerun-creator
  namespace: starfleet
rules:
  - apiGroups: ["tekton.dev"]
    resources: ["pipelineruns"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: starfleet-pr-runner-pipelinerun-creator
  namespace: starfleet
subjects:
  - kind: ServiceAccount
    name: starfleet-pr-runner
    namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pipelinerun-creator
```

Apply it:

```sh
kubectl apply -f rbac-starfleet-pr-runner.yaml
```

## Step 5: Prove both paths and the filters

```sh
send_signed pull_request /payloads/pull-request-opened.json
send_signed pull_request /payloads/pull-request-closed.json
send_signed push /payloads/push-main.json
kubectl get pipelineruns -n starfleet -L triggers.tekton.dev/trigger --sort-by=.metadata.creationTimestamp
```

The opened pull request creates a `pr-check-run-` run from `github-pull-request` with `revision` = `7a3d9e1b5c8f2a6d0e4b7c1f9a2d5e8b3c6f0a14` and `pr-number` = `7`, which succeeds with `summary` = `checked pull request 7 at 7a3d9e1b5c8f2a6d0e4b7c1f9a2d5e8b3c6f0a14`. The closed pull request creates nothing, and the push creates one more `ci-build-run-` run.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Relabel both Triggers to `team: starfleet-ci` | Events work, but teams that label their Triggers `team: starfleet` are left out. The constraints keep the labels |
| Move the Triggers inline into the EventListener | The selector problem disappears, and so does the standalone setup. The grader rejects inline Triggers |
| Remove `serviceAccountName` from the pull request Trigger | Runs are then created by `starfleet-triggers`, not by the restricted ServiceAccount. The grader checks it |
| Bind `starfleet-pr-runner` to `edit` or `cluster-admin` | It can create runs, but also delete pods and read Secrets. The grader rejects it |
| Remove `eventTypes` from the pull request Trigger | Pushes reach its CEL filter, which fails on fields a push does not have; the event type check is the clear way to separate them |

## Common mistakes

- Looking for interceptor answers when no Trigger was selected. No answer at all points at the label selector.
- Stopping after the push works. Each fault hides the next one on the pull request path.
- Reading the core interceptors' log for the permission error. Creating the run is the EventListener's job, so the `forbidden` error is in its log.

## Practice on your own

- Add a third Trigger for pushes to `release-` branches with its own label value, and select both label values with `matchExpressions`.
- Give `starfleet-triggers` its own `serviceAccountName` in `github-push` and check which permissions it still needs.
- Use `tkn pipelinerun delete --label triggers.tekton.dev/trigger=github-pull-request --keep 1 -n starfleet -f` and count the runs that are left.
