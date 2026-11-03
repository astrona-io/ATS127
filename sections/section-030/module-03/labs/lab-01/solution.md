# Solution: Repair The Docs Trigger

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the definition of the Trigger (label, interceptors, filter on `docs/`); a documentation push starts both runs; and a code-only push starts only the build.

## Step 1: Check the EventListener and the Trigger

```sh
kubectl get eventlistener starfleet-ci -n starfleet -o yaml
kubectl get triggers -n starfleet --show-labels
```

The EventListener selects Triggers with `team: starfleet`. The Trigger `github-push` has that label. `docs-check` has no labels, so the EventListener never evaluates it.

## Step 2: Read the filter

```sh
kubectl get trigger docs-check -n starfleet -o yaml
```

The CEL filter tests `f.startsWith('doc/')`. The directory is `docs`. After the label is fixed, this filter still matches nothing, and a documentation push still creates no `docs-check` run.

## Step 3: Repair the Trigger

Save the Trigger with both fixes as `trigger-docs-check.yaml`. The changes against the broken version are the label under `metadata` and the prefix in the filter:

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

```sh
kubectl apply -f trigger-docs-check.yaml
```

## Step 4: Test both pushes

Send `push-main-docs.json` and `push-main-src.json` as in the module, with a signed request, and list the runs of each event:

```sh
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/triggers-eventid=<EVENT_ID> -L triggers.tekton.dev/trigger
```

The documentation push creates a `ci-build-run-` run and a `docs-check-run-` run with the same event ID. The code push creates only the build run.

## Step 5: Check

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

All three checks pass.

## Common mistakes

| Mistake | Effect |
| --- | --- |
| Fixing only the label | The Trigger is evaluated, the filter matches nothing, and no run appears |
| Fixing only the prefix | The EventListener never selects the Trigger |
| Removing the filter | A code-only push starts `docs-check` and the third check fails |
| Writing `startsWith('docs')` without the slash | Works for the grader, but also matches `docs-old.txt` in real use |
