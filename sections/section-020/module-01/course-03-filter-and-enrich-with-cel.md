# Filter And Enrich Events With CEL

A signed push is a real push, but it is not always one you want to build. The release Pipeline should run for `main`, not for every feature branch, and it would be nicer to pass `main` than `refs/heads/main`. A `TriggerBinding` cannot do either: it copies fields as they are. The `cel` interceptor can, with short expressions that decide whether an event continues and compute new values for the binding. This part adds it behind the signature check.

## CEL in a Trigger

CEL (Common Expression Language) is a small expression language with no loops and no side effects; Kubernetes uses it too, for example in validation rules. The `cel` interceptor takes two parameters:

| Parameter | What it does |
| --- | --- |
| `filter` | One expression that must return `true`. Otherwise the interceptor stops the event with the message `expression <filter> did not return true` |
| `overlays` | A list of `key` and `expression` pairs. The interceptor evaluates each expression and stores the result under `extensions.<key>` |

Inside an expression, `body` is the parsed JSON body, `header` is the map of request headers, `requestURL` is the address of the request, and `extensions` holds what earlier interceptors added. Triggers adds helper functions, such as `header.match('X-GitHub-Event', 'push')`, which compares a header without caring about the case of its name, and `.truncate(7)`, which cuts a string. The usual string functions of CEL work too: `.startsWith()`, `.split('/')`, and the `in` operator for lists, as in `body.action in ['opened', 'reopened']`. JSON numbers arrive as decimal numbers (CEL `double`), so compare them with `7.0` or convert them with `int()`.

## Add a CEL interceptor after the signature check

The new chain has two interceptors. The `github` interceptor runs first, so an unsigned request never reaches the CEL code. The `cel` interceptor then lets through only pushes to `main` and stores the short branch name and the short commit ID.

<!-- astrona:playground:renew -->

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
                - key: short_sha
                  expression: "body.head_commit.id.truncate(7)"
      bindings:
        - ref: github-push
      template:
        ref: ci-build-run
```

Apply it:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
```

The overlay `branch_name` splits `refs/heads/main` at each `/` and takes the third part, `main`. That is enough for branch names without a `/`; a branch like `feature/x` would need a different expression. The overlay `short_sha` is not used by the template yet; it shows that one interceptor can add several values.

## Read the overlay in the binding

The binding still reads `$(body.ref)`. Point `branch` at the new value under `extensions` instead.

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

The overlay did not change `body.ref`; the body that the binding reads is still the body GitHub sent. `extensions` is a separate field next to `body` and `header`, filled by the interceptors of this Trigger.

## Send a push to main and a push to a feature branch

Open a shell in the `webhook-client` pod again; the next commands run inside it:

```sh
kubectl exec -it -n starfleet deploy/webhook-client -- bash
```

Define a small function that signs a payload file and sends it as a push event, then send the push to `main` and the push to `feature-shields`, and leave the shell:

```sh
send_signed_push() {
  local signature
  signature="$(openssl dgst -sha256 -hmac 'lab-only-webhook-secret' "$1" | awk '{print $NF}')"
  curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' \
    -H "X-Hub-Signature-256: sha256=$signature" --data-binary "@$1" \
    http://el-starfleet-ci.starfleet.svc.cluster.local:8080
  echo
}
send_signed_push /payloads/push-main.json
send_signed_push /payloads/push-feature.json
exit
```

Both requests are signed correctly and both got `202`. Back on your machine, look at the newest run and the log:

```sh
tkn pipelinerun describe --last -n starfleet
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=4
```

The newest run comes from the push to `main`: its parameter `branch` is now `main`, and when it has finished its result `summary` is `built main at 4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39`. The push to `feature-shields` created nothing. In the log, the `github` interceptor continued for both requests, and the `cel` interceptor stopped the second one with `expression body.ref == 'refs/heads/main' did not return true`.

## Choosing what to filter on

A filter can use the header as well as the body. `header.match('X-GitHub-Event', 'push')` does the same job as `eventTypes`, and conditions combine with `&&` and `||`: `body.ref == 'refs/heads/main' && body.pusher.name != 'release-bot'` skips pushes from an automation account. Keep the signature check in the `github` interceptor, though. A CEL filter reads values that the sender wrote, and only the HMAC check proves who the sender was.

You can now build a chain of interceptors that verifies the sender first, then selects events by their content, and finally hands the binding values that the payload does not contain in that form. Together with the event types of the `github` interceptor, that controls exactly which events start which build.

## Common pitfalls

> [!WARNING]
> - **A filter before the signature check.** The CEL code then runs on every request, signed or not. Put the `github` interceptor first.
> - **Quoting in YAML.** Wrap the whole expression in double quotes and use single quotes for CEL strings: `"body.ref == 'refs/heads/main'"`.
> - **Reading an overlay from `body`.** Overlays go to `extensions`. The binding reads `$(extensions.branch_name)`, not `$(body.branch_name)`.
> - **A field that is missing from some events.** `body.head_commit.id` does not exist in a pull request event, and the expression fails. Filter on the event type first, or check with `has(body.head_commit)`.
> - **Comparing numbers as integers.** JSON numbers are CEL `double` values: write `body.number == 7.0` or `int(body.number) == 7`.

## Your mission: Repair Signature Checks And A CEL Filter

You can now verify GitHub signatures with a Secret, restrict event types, and filter and enrich events with CEL. The graded lab gives you an EventListener that rejects every signed push and, once that is fixed, builds the wrong branch, and asks you to repair both without weakening the checks.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-020-01
astrona start ats-127-playground-020-01
```
