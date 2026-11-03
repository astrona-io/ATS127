# Normalize Provider Payloads With CEL

The Pipeline `ci-build` takes `repo-url`, `revision` and `branch`, where `branch` is a short name. A GitHub push puts the full ref `refs/heads/main` in `body.ref`, and GitLab does the same. If the Pipeline expects `main`, someone must shorten it. Do it once, in the Trigger, with a CEL interceptor that comes after the provider interceptor.

## The chain

Interceptors in a Trigger run in order. The `gitlab` interceptor runs first and stops forged or unwanted events. The `cel` interceptor then filters, and writes new values into `extensions`. The binding reads `$(extensions.<name>)`.

## Filter on the branch and add the short name

Save this as `eventlistener-starfleet-gitlab.yaml`. It replaces the EventListener of the last part:

<!-- astrona:playground:renew -->

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: starfleet-gitlab
  namespace: starfleet
spec:
  serviceAccountName: starfleet-triggers
  triggers:
    - name: gitlab-push
      interceptors:
        - ref:
            name: gitlab
          params:
            - name: secretRef
              value:
                secretName: gitlab-webhook-secret
                secretKey: secretToken
            - name: eventTypes
              value:
                - Push Hook
        - ref:
            name: cel
          params:
            - name: filter
              value: body.ref == 'refs/heads/main'
            - name: overlays
              value:
                - key: branch
                  expression: body.ref.split('/')[2]
      bindings:
        - ref: gitlab-push
      template:
        ref: ci-build-run
```

Change the binding so that `branch` reads the overlay. Save it as `triggerbinding-gitlab-push.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: gitlab-push
  namespace: starfleet
spec:
  params:
    - name: repo-url
      value: $(body.project.git_http_url)
    - name: revision
      value: $(body.checkout_sha)
    - name: branch
      value: $(extensions.branch)
```

```sh
kubectl apply -f triggerbinding-gitlab-push.yaml
kubectl apply -f eventlistener-starfleet-gitlab.yaml
kubectl rollout status deployment/el-starfleet-gitlab -n starfleet
```

Send the sample push with the right token and read the run:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-Gitlab-Event: Push Hook' -H 'X-Gitlab-Token: lab-only-gitlab-token' --data-binary @/payloads/gitlab-push-main.json http://el-starfleet-gitlab.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-gitlab -o jsonpath='{.items[*].spec.params}'
```

The run has `branch` with the value `main`. `body.ref.split('/')[2]` splits `refs/heads/main` at each slash and takes the third item. A branch with a slash in its name, such as `feature/shields`, would give only `feature`, so a real setup cuts off the prefix `refs/heads/` instead.

## Order matters

The `cel` interceptor reads `body` and `header` as they came in, plus the `extensions` that earlier interceptors added. If the CEL interceptor came first, a forged event would be evaluated before the origin check. Put the origin check first.

You can now chain a provider interceptor and a CEL interceptor. The fields of the provider stay in the binding; the Pipeline sees the same three parameters whatever the provider.

## Your mission: Accept Signed GitLab Pushes

You can now check the token of a GitLab webhook, filter on the event type and the branch, and shorten the ref. The graded lab gives you an EventListener that accepts everything from GitLab, with a binding that already expects a short branch name. You secure it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-020-02
astrona start ats-127-playground-020-02
```

## Common pitfalls

> [!WARNING]
> - **The CEL interceptor before the provider interceptor.** Unchecked events then reach your expressions.
> - **A binding that reads `$(extensions.branch)` without an overlay.** The path finds nothing and the event creates no run.
> - **`split('/')[2]` on every branch name.** Names with slashes lose their tail.
