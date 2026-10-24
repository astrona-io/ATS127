# Solution: Add A Pull Request Trigger

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks five things: the EventListener is ready and selects standalone Triggers by label; an opened pull request against `main` creates one `pr-check` run with the event's values; closed, wrong-base and unsigned pull requests create nothing; and a push to `main` still creates exactly one `ci-build` run.

## Step 1: Look at the push path

```sh
kubectl get eventlistener starfleet-ci -n starfleet -o jsonpath='{.spec.labelSelector}{"\n"}'
kubectl get triggers -n starfleet --show-labels
```

The EventListener selects Triggers with the label `team: starfleet`, and the Trigger `github-push` has it. A new Trigger with the same label takes part from the next event on.

## Step 2: Create the binding and the template

Save this as `triggerbinding-github-pull-request.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: github-pull-request
  namespace: starfleet
spec:
  params:
    - name: repo-url
      value: $(body.repository.clone_url)
    - name: revision
      value: $(body.pull_request.head.sha)
    - name: pr-number
      value: $(body.number)
```

Save this as `triggertemplate-pr-check-run.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: pr-check-run
  namespace: starfleet
spec:
  params:
    - name: repo-url
      description: The clone URL of the repository
    - name: revision
      description: The head commit ID of the pull request
    - name: pr-number
      description: The number of the pull request
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: PipelineRun
      metadata:
        generateName: pr-check-run-
      spec:
        pipelineRef:
          name: pr-check
        params:
          - name: repo-url
            value: $(tt.params.repo-url)
          - name: revision
            value: $(tt.params.revision)
          - name: pr-number
            value: $(tt.params.pr-number)
```

Apply both:

```sh
kubectl apply -f triggerbinding-github-pull-request.yaml -f triggertemplate-pr-check-run.yaml
```

## Step 3: Create the Trigger

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

Apply it:

```sh
kubectl apply -f trigger-github-pull-request.yaml
```

## Step 4: Send pull request events

Open a shell in the client pod:

```sh
kubectl exec -it -n starfleet deploy/webhook-client -- bash
```

Inside the shell, define a signing helper, send the opened and the closed pull request and a push to `main`, then leave the shell:

```sh
send_event() {
  local signature
  signature="$(openssl dgst -sha256 -hmac 'lab-only-webhook-secret' "$2" | awk '{print $NF}')"
  curl -sS -X POST -H 'Content-Type: application/json' -H "X-GitHub-Event: $1" \
    -H "X-Hub-Signature-256: sha256=$signature" --data-binary "@$2" \
    http://el-starfleet-ci.starfleet.svc.cluster.local:8080
  echo
}
send_event pull_request /payloads/pull-request-opened.json
send_event pull_request /payloads/pull-request-closed.json
send_event push /payloads/push-main.json
exit
```

Then check the result:

```sh
kubectl get pipelineruns -n starfleet -L triggers.tekton.dev/trigger --sort-by=.metadata.creationTimestamp
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=10
```

Two new runs exist: a `pr-check-run-` run from `github-pull-request` and a `ci-build-run-` run from `github-push`. The `pr-check` run has `revision` = `7a3d9e1b5c8f2a6d0e4b7c1f9a2d5e8b3c6f0a14` and `pr-number` = `7`, and when it succeeds its result `summary` is `checked pull request 7 at 7a3d9e1b5c8f2a6d0e4b7c1f9a2d5e8b3c6f0a14`. The closed pull request created nothing: the log shows the CEL filter of `github-pull-request` stopping it. For the push, the log shows `event type push is not allowed` from the pull request Trigger, and the push Trigger went on.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add the pull request Trigger inline to the EventListener | It works for events, but the grader requires standalone Triggers selected by label |
| Forget the label `team: starfleet` | The Trigger exists, but the EventListener never selects it |
| Filter only on `action` | Pull requests against other branches start checks too |
| Use `pull_request.base.sha` as `revision` | The check runs on the target branch, not on the proposed change |
| Leave out `secretRef` | Unsigned pull requests start checks |

## Common mistakes

- Writing the event type as `pull-request`. GitHub sends `pull_request`.
- Reading `$(body.head_commit.id)` in the pull request binding. A pull request event has no `head_commit`.
- Comparing `body.number` with a string in CEL. It is a number.

## Practice on your own

- Send `/payloads/pull-request-opened.json` with `"action": "synchronize"` from a payload of your own and check that a second `pr-check` run starts.
- Add an inline binding parameter to the Trigger and see which value wins over the binding `github-pull-request`.
- Remove the label from `github-push` and send a push. Read both logs to see that no Trigger answered.
