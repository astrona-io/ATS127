# PipelineRun Options, Defaults And uid

A `PipelineRun` created by a template is a normal `PipelineRun`. It can have a timeout, a ServiceAccount, labels and annotations, and every one of them can take a value from the event. Two details need care: Kubernetes limits what a label value may contain, and an event may not carry the field that a parameter reads. This part sets run options from event values, gives parameters defaults, and uses `$(uid)` to link the objects that one event created.

## Set options in the run template

A resource template is the full object. Anything that a `PipelineRun` accepts goes in it. Save this as `triggertemplate-ci-build-options.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: ci-build-options
  namespace: starfleet
spec:
  params:
    - name: repo-url
    - name: revision
    - name: branch
    - name: pusher
      default: unknown
    - name: build-timeout
      default: 30m
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: PipelineRun
      metadata:
        generateName: ci-build-run-
        labels:
          team: starfleet
          build-id: $(uid)
        annotations:
          starfleet/pusher: $(tt.params.pusher)
          starfleet/branch: $(tt.params.branch)
      spec:
        pipelineRef:
          name: ci-build
        timeouts:
          pipeline: $(tt.params.build-timeout)
        taskRunTemplate:
          serviceAccountName: default
        params:
          - name: repo-url
            value: $(tt.params.repo-url)
          - name: revision
            value: $(tt.params.revision)
          - name: branch
            value: $(tt.params.branch)
```

Apply it:

```sh
kubectl apply -f triggertemplate-ci-build-options.yaml
```

The template uses four things:

- `spec.timeouts.pipeline` limits the whole run. A value from the event or from a default must be a valid duration such as `30m`.
- `spec.taskRunTemplate.serviceAccountName` sets the ServiceAccount of the `TaskRuns`. It is not the ServiceAccount of the EventListener.
- `labels` select and group runs. A label value may contain only letters, digits, `-`, `_` and `.`, at most 63 characters.
- `annotations` hold any text, so use them for values such as a branch name with slashes.

## Defaults

A parameter with a `default` takes that value when no binding provides it. In the template above, `pusher` defaults to `unknown` and `build-timeout` defaults to `30m`. The binding in this part provides neither of them, so a default is the only source of `build-timeout`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: github-push-options
  namespace: starfleet
spec:
  params:
    - name: repo-url
      value: $(body.repository.clone_url)
    - name: revision
      value: $(body.head_commit.id)
    - name: branch
      value: $(body.ref)
    - name: pusher
      value: $(body.pusher.name)
```

Save it as `triggerbinding-github-push-options.yaml` and apply it:

```sh
kubectl apply -f triggerbinding-github-push-options.yaml
```

A default covers a parameter that no binding names. It does not cover a binding whose path finds nothing in the payload. For a path that finds nothing, the value is not the default, so test the payload fields you rely on.

## Link the objects of one event with uid

The EventListener already puts the label `triggers.tekton.dev/triggers-eventid` on every object it creates, so you can find all objects of one event with it. The placeholder `$(uid)` is a second, separate value. It is replaced with a unique string each time the template is evaluated, and every `$(uid)` in that one evaluation gets the same string. Use it for a name or label that you own, for example `build-id` above.

Point the EventListener `starfleet-ci` at the new binding and template. Save this as `eventlistener-starfleet-ci.yaml`:

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
      bindings:
        - ref: github-push-options
      template:
        ref: ci-build-options
```

Apply it, send a push, and read the run's label, annotations and timeout:

```sh
kubectl apply -f eventlistener-starfleet-ci.yaml
kubectl rollout status deployment/el-starfleet-ci -n starfleet
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl get pipelineruns -n starfleet -l team=starfleet -o yaml
```

The run has the label `build-id` with the generated string, the annotation `starfleet/pusher: scout`, the annotation `starfleet/branch: refs/heads/main` and `spec.timeouts.pipeline: 30m`. Send the same body again: the second run has a different `build-id`.

## Fix a label value that is not valid

Change `build-id: $(uid)` to `branch: $(tt.params.branch)` in the labels and apply the template. A push to `refs/heads/main` now produces the value `refs/heads/main`, and that contains `/`. The API server rejects the `PipelineRun`, the EventListener log has the error, and the response was still `202`. Move the branch back to an annotation, or cut the value in an interceptor before the binding.

You can now shape the run that a template creates. Options come from the template, values come from the event, defaults cover parameters that no binding provides, and `$(uid)` gives each evaluation one unique string. The values of a label are limited by Kubernetes; the values of an annotation are not.

## Common pitfalls

> [!WARNING]
> - **Putting a branch or a path in a label.** The slash is not allowed. Use an annotation.
> - **Expecting a default to replace a missing field.** A default only fills a parameter that no binding names.
> - **A duration that is not valid.** A `timeouts` value such as `30` without a unit makes the run invalid.
> - **Confusing the two ServiceAccounts.** The EventListener's creates the run; `taskRunTemplate.serviceAccountName` is the one that the run's pods use.
