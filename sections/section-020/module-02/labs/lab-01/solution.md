# Solution: Accept Signed GitLab Pushes

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: a push with the right token starts a run with `branch` set to `main`, and a wrong or missing token starts nothing; an event of another type starts nothing; and a push to another branch starts nothing.

## Step 1: Look at the starting state

```sh
kubectl get eventlistener starfleet-ci -n starfleet -o yaml
kubectl get triggerbinding gitlab-push -n starfleet -o yaml
kubectl get secret gitlab-webhook-secret -n starfleet -o jsonpath='{.data}'
```

The Trigger has no interceptors. The binding reads `$(extensions.branch)`, and the Secret has the key `secretToken`.

## Step 2: Add the two interceptors

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

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
kubectl rollout status deployment/el-starfleet-ci -n starfleet
```

## Step 3: Check with events

Send a push with the right token, then one with a wrong token, and list the runs:

```sh
URL=http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-Gitlab-Event: Push Hook' -H 'X-Gitlab-Token: lab-only-gitlab-token' --data-binary @/payloads/gitlab-push-main.json $URL
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-Gitlab-Event: Push Hook' -H 'X-Gitlab-Token: wrong' --data-binary @/payloads/gitlab-push-main.json $URL
kubectl get pipelineruns -n starfleet
```

One run exists and its `branch` is `main`. The reason for the other event is in the log of the core interceptors:

```sh
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=20
```

## Step 4: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change the binding to read `$(body.ref)` | The binding must not change, and the branch would be `refs/heads/main` |
| Put the `cel` interceptor first | Events with a wrong token reach the expressions before the origin check |
| Skip `eventTypes` | A `Merge Request Hook` with the right token starts a run |

## Common mistakes

- Writing `push` instead of `Push Hook`. GitLab's name has a space and capitals.
- Using the key name `token` instead of `secretToken` in `secretKey`.
- Forgetting `kubectl rollout status` and testing against the old pod.

## Practice on your own

- Let `refs/heads/release` through as well with `||` in the filter.
- Remove the `secretRef` and send a wrong token to see the difference.
