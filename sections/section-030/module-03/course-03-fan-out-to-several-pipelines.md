# Fan Out To Several Pipelines

One event can start more than one Pipeline. The EventListener evaluates every Trigger it selects, and each Trigger runs its own interceptors, binding and template. This part adds a documentation check next to the build.

## One event, two Triggers

The playground has the Trigger `github-push`, which builds on a push to `main`, and the Pipeline `docs-check` with the TriggerTemplate `docs-check-run`. The template takes the same three parameters as `ci-build-run`, so the existing binding `github-push` feeds it too. What is missing is the Trigger. Save this as `trigger-docs-check.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: Trigger
metadata:
  name: docs-check
  namespace: starfleet
  labels:
    team: starfleet
spec:
  interceptors:
    - name: verify-github-push
      ref:
        name: github
      params:
        - name: secretRef
          value:
            secretName: github-webhook-secret
            secretKey: secretToken
        - name: eventTypes
          value: ["push"]
    - name: only-docs-on-main
      ref:
        name: cel
      params:
        - name: filter
          value: "body.ref == 'refs/heads/main' && body.commits.exists(c, c.modified.exists(f, f.startsWith('docs/')))"
        - name: overlays
          value:
            - key: branch_name
              expression: "body.ref.split('/')[2]"
  bindings:
    - ref: github-push
  template:
    ref: docs-check-run
```

The label `team: starfleet` is what the EventListener selects on. Without it the Trigger exists but never runs.

```sh
kubectl apply -f trigger-docs-check.yaml
```

## Send both pushes

<!-- astrona:playground:renew -->

Use the helper from the overview of the playground, or sign and send in the client pod. Send the documentation push first:

```sh
kubectl exec -n starfleet deploy/webhook-client -- bash -c 'SIGNATURE="$(openssl dgst -sha256 -hmac lab-only-webhook-secret /payloads/push-main-docs.json | awk "{print \$NF}")"; curl -sS -X POST -H "Content-Type: application/json" -H "X-GitHub-Event: push" -H "X-Hub-Signature-256: sha256=$SIGNATURE" --data-binary @/payloads/push-main-docs.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080'
```

Copy the `eventID` and list the runs of that event:

```sh
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/triggers-eventid=<EVENT_ID> -L triggers.tekton.dev/trigger
```

Two runs carry the same event ID, one for each Trigger: `ci-build-run-` from `github-push` and `docs-check-run-` from `docs-check`. Now send `push-main-src.json` the same way. Only the build run appears, because the path filter of `docs-check` is false.

## What the event ID tells you

Both runs share the event ID, because it belongs to the request. They differ in the label `triggers.tekton.dev/trigger`. To follow an event across all its runs, select on the event ID. To follow one Trigger, select on the Trigger label.

## Failure in one Trigger

The Triggers are independent. When the interceptor of `docs-check` stops the event, `github-push` still runs, and the other way around. A broken template in one Trigger does not stop the other. The cost is that the client still sees `202` in every case, so check each Trigger on its own when a run is missing.

## Your mission: Repair The Docs Trigger

You can now fan one event out to two Pipelines. The graded lab gives you a documentation Trigger that never starts a run.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-030-03
astrona start ats-127-playground-030-03
```

## Common pitfalls

> [!WARNING]
> - **Forgetting the selector label on a new Trigger.** The EventListener does not select it.
> - **A template whose parameters do not match the binding.** The template needs every value it uses.
> - **Expecting the client to see the second run.** The response is `202` whatever happens.
