# One EventListener, Several Triggers

A Git server sends all events of a repository to one webhook address. So one EventListener must handle pushes and pull requests, and start a different Pipeline for each. You could list both Triggers inline in the EventListener, but then every change to a Trigger is a change to the EventListener, and teams cannot add Triggers of their own. This part keeps each Trigger as its own object, lets the EventListener select them by label, and adds a pull request Trigger next to the push Trigger.

## Standalone Triggers

A `Trigger` can be its own object with the same fields as an inline Trigger: `interceptors`, `bindings`, `template`, and optionally `serviceAccountName`. The playground already has one, `github-push`. Look at its labels:

<!-- astrona:playground:renew -->

```sh
kubectl get triggers -n starfleet --show-labels
```

The Trigger `github-push` has the label `team: starfleet`. Its spec is the push chain: the `github` interceptor with the webhook Secret and the event type `push`, then a `cel` interceptor that lets through only `refs/heads/main` and stores `branch_name`, then the binding `github-push` and the template `ci-build-run`.

An EventListener can pick up standalone Triggers in three ways. `spec.triggers` can name one with `triggerRef: github-push`. `spec.labelSelector` selects every Trigger in the EventListener's namespace whose labels match. `spec.namespaceSelector` with `matchNames` looks in other namespaces as well; that needs an extra ClusterRoleBinding to `tekton-triggers-eventlistener-roles`, because the EventListener then reads Triggers outside its own namespace.

## Select Triggers by label

Create the EventListener with a label selector and no inline Triggers.

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

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
```

Then check the result. If `kubectl wait` reports that it found nothing, the Triggers controller has not created the Deployment yet; run it again:

```sh
kubectl wait --for=condition=Ready eventlistener/starfleet-ci -n starfleet --timeout=180s
tkn eventlistener describe starfleet-ci -n starfleet
```

The EventListener is ready, and `tkn eventlistener describe` shows its ServiceAccount and its address, `http://el-starfleet-ci.starfleet.svc.cluster.local:8080`. It lists no Triggers, because the selector is evaluated for every event, not when the EventListener is created. A Trigger you add later with the label `team: starfleet` takes part from the next event on, without any change to the EventListener.

## Add the pull request Trigger

The new Trigger uses the `github` interceptor with the event type `pull_request`, and a CEL filter for the actions that change code and the base branch `main`. It uses the binding `github-pull-request` and the template `pr-check-run`.

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

## Send three events

Every event now runs through both Triggers. Open a shell in the client pod and define a helper that signs a file and sends it with an event type:

```sh
kubectl exec -it -n starfleet deploy/webhook-client -- bash
```

Inside the shell, send a push to `main`, an opened pull request and a closed pull request, then leave the shell:

```sh
send_event() {
  local signature
  signature="$(openssl dgst -sha256 -hmac 'lab-only-webhook-secret' "$2" | awk '{print $NF}')"
  curl -sS -X POST -H 'Content-Type: application/json' -H "X-GitHub-Event: $1" \
    -H "X-Hub-Signature-256: sha256=$signature" --data-binary "@$2" \
    http://el-starfleet-ci.starfleet.svc.cluster.local:8080
  echo
}
send_event push /payloads/push-main.json
send_event pull_request /payloads/pull-request-opened.json
send_event pull_request /payloads/pull-request-closed.json
exit
```

Back on your machine, list the runs with the label that names their Trigger as an extra column:

```sh
kubectl get pipelineruns -n starfleet -L triggers.tekton.dev/trigger --sort-by=.metadata.creationTimestamp
```

There are two new runs. A `ci-build-run-` run came from the Trigger `github-push`, and a `pr-check-run-` run came from `github-pull-request`. When the second one has finished, `tkn pipelinerun describe` shows its result `summary` as `checked pull request 7 at 7a3d9e1b5c8f2a6d0e4b7c1f9a2d5e8b3c6f0a14`. The closed pull request created nothing.

Each event went through both chains. For the push, the `github` interceptor of `github-pull-request` stopped it with `event type push is not allowed`, and the push Trigger continued. For the opened pull request it was the other way round. For the closed pull request, the `github` interceptor of `github-pull-request` let it through and its CEL filter stopped it. The core interceptors' log has one answer for each of these steps.

## A ServiceAccount per Trigger

By default, the EventListener creates every run with its own ServiceAccount. A Trigger can set `serviceAccountName` to use another ServiceAccount in the same namespace, for example one that may create PipelineRuns but nothing else, or one per team. The EventListener then impersonates that ServiceAccount when it creates the Trigger's objects; its own role `tekton-triggers-eventlistener-roles` includes the `impersonate` verb for ServiceAccounts. The Trigger's ServiceAccount itself needs `create` on `pipelineruns`. Without it, the interceptors pass, the EventListener logs a `forbidden` error when it creates the run, and nothing appears.

You can now split event handling into standalone Triggers, select them by label, and let the interceptors of each Trigger pick its events. The EventListener stays the same when a team adds a Trigger. The open question is how to follow one event through this setup when it does not start what you expect, and how to keep the namespace clean when every event leaves a run behind.

## Common pitfalls

> [!WARNING]
> - **A label selector that matches nothing.** The EventListener is ready and answers `202`, but no Trigger runs. Compare `spec.labelSelector` with `kubectl get triggers --show-labels`.
> - **A Trigger without the label.** It exists, but the EventListener never selects it.
> - **Two Triggers that both accept an event.** Both create a run. Make the interceptors of each Trigger exclusive, for example with `eventTypes`.
> - **`pull-request` instead of `pull_request`.** GitHub sends `X-GitHub-Event: pull_request` with an underscore; any other spelling never matches.
> - **A Trigger ServiceAccount without permission.** The EventListener impersonates it to create the run; it needs `create` on `pipelineruns`.

## Your mission: Add A Pull Request Trigger

You can now write a binding and a template for pull requests and add a standalone Trigger that an EventListener selects by label. The graded lab gives you a working push setup and asks you to add the pull request path next to it, without breaking pushes and without letting closed pull requests or unsigned events through.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-030-01
astrona start ats-127-playground-030-01
```
