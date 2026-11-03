# GitLab Token And Event Types

GitHub signs the body of a webhook. GitLab does it more simply: when you give a webhook a secret token, GitLab sends that token unchanged in the header `X-Gitlab-Token`, and it names the kind of event in the header `X-Gitlab-Event`. The `gitlab` interceptor uses both. This part builds a Trigger that accepts only GitLab push events that carry the right token.

## What GitLab sends

A GitLab push webhook is a POST with a JSON body and these headers:

- `X-Gitlab-Event: Push Hook` names the event. Other values include `Merge Request Hook` and `Tag Push Hook`.
- `X-Gitlab-Token: <the secret token>` is present only when a token was configured on the webhook.

The body has the branch in `ref`, the new commit in `checkout_sha`, the repository URL in `project.git_http_url` and the user in `user_username`. The playground has one in `/payloads/gitlab-push-main.json`.

A token is weaker than a signature. Anyone who sees one request sees the token, and the token proves nothing about the body. Use HTTPS between GitLab and the EventListener, and treat the token like a password.

## Check the token and the event type

The Secret `gitlab-webhook-secret` already exists in the playground. The interceptor reads it with `secretRef`. Save this as `triggerbinding-gitlab-push.yaml`:

<!-- astrona:playground:renew -->

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
      value: $(body.ref)
```

Apply it. Then save the EventListener as `eventlistener-starfleet-gitlab.yaml`:

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
      bindings:
        - ref: gitlab-push
      template:
        ref: ci-build-run
```

```sh
kubectl apply -f triggerbinding-gitlab-push.yaml
kubectl apply -f eventlistener-starfleet-gitlab.yaml
kubectl rollout status deployment/el-starfleet-gitlab -n starfleet
```

## Send three events

Send a push with the right token, one with a wrong token and one with another event type. Each is a `curl` from the client pod:

```sh
URL=http://el-starfleet-gitlab.starfleet.svc.cluster.local:8080
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-Gitlab-Event: Push Hook' -H 'X-Gitlab-Token: lab-only-gitlab-token' --data-binary @/payloads/gitlab-push-main.json $URL
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-Gitlab-Event: Push Hook' -H 'X-Gitlab-Token: wrong' --data-binary @/payloads/gitlab-push-main.json $URL
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-Gitlab-Event: Merge Request Hook' -H 'X-Gitlab-Token: lab-only-gitlab-token' --data-binary @/payloads/gitlab-push-main.json $URL
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-gitlab
```

All three answer `202`, and exactly one `PipelineRun` exists, from the first event. The reasons for the other two are in the log of the core interceptors:

```sh
kubectl logs -n tekton-pipelines deploy/tekton-triggers-core-interceptors --tail=20
```

You can now check a GitLab webhook by token and by event type. The `branch` parameter still holds the full ref, `refs/heads/main`. The next parts deal with the Bitbucket variants and then shorten it.

## Common pitfalls

> [!WARNING]
> - **A `secretKey` that is not in the Secret.** The interceptor stops every event. Compare the key name with `kubectl get secret gitlab-webhook-secret -n starfleet -o jsonpath='{.data}'`.
> - **A webhook without a token.** GitLab then sends no `X-Gitlab-Token`. If the interceptor has a `secretRef`, it stops the event.
> - **Event names copied from the GitHub setup.** GitLab names are words such as `Push Hook`, with a space and capital letters.
> - **Judging the check by the HTTP status.** It is `202` in every case.
