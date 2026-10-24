# Solution: Harden An Open EventListener

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks five things: the EventListener is ready; the Secret and the order of the interceptors are right; a signed push to `main` creates a `PipelineRun` with `branch` = `main` that succeeds; unsigned and wrongly signed pushes create nothing; and signed events that are not pushes to `main` create nothing.

## Step 1: See the problem

Send an unsigned push to a feature branch:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-feature.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
tkn pipelinerun describe --last -n starfleet
```

A new run starts with `branch` = `refs/heads/feature-shields`, although nobody signed the request and the branch is not `main`.

## Step 2: Store the webhook secret

Save this as `secret-github-webhook-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-webhook-secret
  namespace: starfleet
type: Opaque
stringData:
  secretToken: lab-only-webhook-secret
```

Apply it:

```sh
kubectl apply -f secret-github-webhook-secret.yaml
```

## Step 3: Read the branch from the overlay

Save this as `triggerbinding-github-push.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: github-push
  namespace: starfleet
spec:
  params:
    - name: repo-url
      value: $(body.repository.clone_url)
    - name: revision
      value: $(body.head_commit.id)
    - name: branch
      value: $(extensions.branch_name)
```

Apply it:

```sh
kubectl apply -f triggerbinding-github-push.yaml
```

Until the CEL overlay exists, this path does not resolve, so the EventListener creates nothing for a moment. That is fine, because the next step adds the overlay.

## Step 4: Add the interceptors

The `github` interceptor goes first, so unsigned requests never reach the CEL code.

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

## Step 5: Test with signed and unsigned events

Open a shell in the client pod:

```sh
kubectl exec -it -n starfleet deploy/webhook-client -- bash
```

Inside the shell, define a helper that signs a file with a given secret and sends it with a given event type, send four events, and leave the shell:

```sh
send_event() {
  local signature
  signature="$(openssl dgst -sha256 -hmac "$2" "$3" | awk '{print $NF}')"
  curl -sS -X POST -H 'Content-Type: application/json' -H "X-GitHub-Event: $1" \
    -H "X-Hub-Signature-256: sha256=$signature" --data-binary "@$3" \
    http://el-starfleet-ci.starfleet.svc.cluster.local:8080
  echo
}
send_event push lab-only-webhook-secret /payloads/push-main.json
send_event push not-the-secret /payloads/push-main.json
send_event push lab-only-webhook-secret /payloads/push-feature.json
send_event pull_request lab-only-webhook-secret /payloads/push-main.json
exit
```

Then check the result:

```sh
kubectl get pipelineruns -n starfleet --sort-by=.metadata.creationTimestamp
tkn pipelinerun describe --last -n starfleet
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=8
```

Only the first event created a run. It has `revision` = `4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39` and `branch` = `main`, and it succeeds with `summary` = `built main at 4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39`. The log has `payload signature check failed` for the second event, the CEL message `expression body.ref == 'refs/heads/main' did not return true` for the third, and `event type pull_request is not allowed` for the fourth.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Only `eventTypes`, no `secretRef` | The interceptor checks a header that anyone can set; unsigned pushes still build |
| The CEL interceptor first, the `github` interceptor second | Every request, signed or not, runs through the CEL code first. The grader checks the order |
| Filter on `header.match('X-GitHub-Event', 'push')` only | Pushes to every branch build |
| Keep `branch` = `$(body.ref)` | The run gets `refs/heads/main`, not `main` |
| Put the overlay result into `body` | Overlays always go to `extensions`; the binding must read `$(extensions.branch_name)` |

## Common mistakes

- Sending the payload with `-d` instead of `--data-binary`. `curl -d` strips the line breaks, so the signature no longer matches.
- Writing the CEL string in double quotes inside a double-quoted YAML value. Use single quotes inside: `"body.ref == 'refs/heads/main'"`.
- Expecting an error response for a rejected event. The EventListener answers `202` for all four events.

## Practice on your own

- Add an overlay `short_sha` and a second inline binding that reads it, then add a matching parameter to a copy of the template.
- Allow pushes to branches that start with `release-` as well, with `body.ref.startsWith('refs/heads/release-')`.
- Replace `eventTypes` with a CEL condition `header.match('X-GitHub-Event', 'push')` and compare the log messages.
