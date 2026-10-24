# Solution: Repair Signature Checks And A CEL Filter

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the EventListener is ready; a signed push to `main` creates a `PipelineRun` of `ci-build` with `branch` = `main` that succeeds; unsigned and wrongly signed pushes create nothing; and signed events that are not pushes to `main` create nothing.

## Step 1: Send a signed push

Open a shell in the client pod; the next commands run inside it:

```sh
kubectl exec -it -n starfleet deploy/webhook-client -- bash
```

Sign the payload and send it, then leave the shell:

```sh
SIGNATURE="$(openssl dgst -sha256 -hmac 'lab-only-webhook-secret' /payloads/push-main.json | awk '{print $NF}')"
curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' -H "X-Hub-Signature-256: sha256=$SIGNATURE" --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
exit
```

The response is `202`, but no `PipelineRun` appears:

```sh
kubectl get pipelineruns -n starfleet
```

## Step 2: Read why the interceptor stopped it

The EventListener answered before the interceptors ran, so the reason is in the core interceptors' log:

```sh
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=5
```

The newest answer has `Continue:false` and a message that starts with `error getting secret`. The `github` interceptor could not read the key it was given. Compare the reference with the Secret:

```sh
kubectl get eventlistener starfleet-ci -n starfleet -o jsonpath='{.spec.triggers[0].interceptors[0].params[0].value}{"\n"}'
kubectl get secret github-webhook-secret -n starfleet -o jsonpath='{.data}{"\n"}'
```

The interceptor asks for the key `token`; the Secret stores the webhook secret under `secretToken`. The value is right, so fix the reference, not the Secret.

## Step 3: Read the CEL filter

The CEL interceptor runs after the `github` interceptor, so its fault is hidden until the first one is fixed. Read it now anyway:

```sh
kubectl get eventlistener starfleet-ci -n starfleet -o jsonpath='{.spec.triggers[0].interceptors[1].params[0].value}{"\n"}'
```

The filter is `body.ref == 'refs/heads/master'`. The team's branch is `main`, so every push to `main` would be stopped with `expression body.ref == 'refs/heads/master' did not return true`.

## Step 4: Fix both faults

Save this as `eventlistener-starfleet-ci.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: starfleet-ci
  namespace: starfleet
spec:
  serviceAccountName: starfleet-triggers
  triggers:
    - name: github-push
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
        - name: only-main
          ref:
            name: cel
          params:
            - name: filter
              value: "body.ref == 'refs/heads/main'"
            - name: overlays
              value:
                - key: branch_name
                  expression: "body.ref.split('/')[2]"
      bindings:
        - ref: github-push
      template:
        ref: ci-build-run
```

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
```

## Step 5: Prove the fix and the checks

Open the client pod's shell again and send four events: the signed push to `main`, the same push unsigned, the signed push to `feature-shields`, and the signed push to `main` labelled as a `pull_request` event:

```sh
kubectl exec -it -n starfleet deploy/webhook-client -- bash
```

Inside the shell, compute the two signatures and send the four events, then leave the shell:

```sh
EL_URL='http://el-starfleet-ci.starfleet.svc.cluster.local:8080'
MAIN_SIGNATURE="$(openssl dgst -sha256 -hmac 'lab-only-webhook-secret' /payloads/push-main.json | awk '{print $NF}')"
FEATURE_SIGNATURE="$(openssl dgst -sha256 -hmac 'lab-only-webhook-secret' /payloads/push-feature.json | awk '{print $NF}')"
curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' -H "X-Hub-Signature-256: sha256=$MAIN_SIGNATURE" --data-binary @/payloads/push-main.json "$EL_URL"
curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json "$EL_URL"
curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' -H "X-Hub-Signature-256: sha256=$FEATURE_SIGNATURE" --data-binary @/payloads/push-feature.json "$EL_URL"
curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: pull_request' -H "X-Hub-Signature-256: sha256=$MAIN_SIGNATURE" --data-binary @/payloads/push-main.json "$EL_URL"
exit
```

Then check the result:

```sh
kubectl get pipelineruns -n starfleet
tkn pipelinerun describe --last -n starfleet
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=8
```

Exactly one new run exists. It has `revision` = `4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39` and `branch` = `main`, and it succeeds with the result `summary` = `built main at 4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39`. The log shows `no X-Hub-Signature-256 header set` for the unsigned push, the CEL message for the feature branch, and `event type pull_request is not allowed` for the last event.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove the `github` interceptor or its `secretRef` | Signed pushes work, but so do unsigned and forged ones. The grader sends both and rejects the fix |
| Remove the CEL filter, or set it to `true` | Pushes to every branch start the release build. The grader's push to another branch fails the check |
| Remove `eventTypes` | A body that looks like a push to `main` but comes as a `pull_request` event starts a build |
| Change the Secret value to match something else | The Git server signs with `lab-only-webhook-secret`; every real delivery would fail |

## Common mistakes

- Looking for the reason in the EventListener's log. The interceptors log their answers in `tekton-triggers-core-interceptors`.
- Fixing only the first fault. The CEL filter stops the event as soon as the signature check passes.
- Signing `push-main.json` and sending `push-feature.json` with that signature. Each body needs its own signature.

## Practice on your own

- Change the filter to `body.ref in ['refs/heads/main', 'refs/heads/release']` and test it with a payload of your own.
- Add a second overlay `short_sha` with `body.head_commit.id.truncate(7)` and read it with a binding.
- Delete the Secret and send a signed push. Read the message in the core interceptors' log.
