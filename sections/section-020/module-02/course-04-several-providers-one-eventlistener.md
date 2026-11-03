# Several Providers On One EventListener

A company may use GitHub for some projects and GitLab for others. Running two EventListeners doubles the pods and the Services. One EventListener can serve both, with one Trigger per provider. Each event is offered to every Trigger, and each Trigger's interceptors decide whether it applies.

## One Trigger per provider

Save this as `eventlistener-starfleet-ci.yaml` and apply it. The GitHub Trigger checks the signature, the GitLab Trigger checks the token:

<!-- astrona:playground:renew -->

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
        - ref:
            name: github
          params:
            - name: secretRef
              value:
                secretName: github-webhook-secret
                secretKey: secretToken
            - name: eventTypes
              value:
                - push
      bindings:
        - ref: github-push
      template:
        ref: ci-build-run
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

The Secret `github-webhook-secret` does not exist in this playground. Create it before you apply the EventListener:

```sh
kubectl create secret generic github-webhook-secret -n starfleet --from-literal=secretToken=lab-only-webhook-secret
```

Both Triggers use the same template `ci-build-run`, so a push from either provider creates the same kind of run.

## What each event does

A GitHub push passes the first Trigger's checks. The second Trigger's `gitlab` interceptor stops it, because it has no `X-Gitlab-Token`. A GitLab push does the opposite. Neither stops the other: a Trigger that fails its interceptors only skips itself. Send a GitLab push and list the runs:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-Gitlab-Event: Push Hook' -H 'X-Gitlab-Token: lab-only-gitlab-token' --data-binary @/payloads/gitlab-push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-ci
```

One run exists. Look at the log of the core interceptors to see the GitHub interceptor stopping the same event.

## Keep the load in mind

Every Trigger evaluates every event. Ten providers and repositories on one EventListener mean ten sets of interceptor calls for each event, most of them stopping at once. That is cheap per event, but the log gets noisy. Split EventListeners by team or by trust level when the number of Triggers grows, and give the exposed one the strictest checks.

You can now serve several providers with one EventListener. Each provider has its own Trigger, its own origin check and the same template.

## Common pitfalls

> [!WARNING]
> - **A Trigger without an origin check next to checked ones.** An event can use the unchecked Trigger. Check every Trigger.
> - **Different parameter names between the bindings.** The shared template needs the same names from each.
> - **One Secret shared by every provider.** A leak of one token then breaks all of them. Use one Secret per provider.
