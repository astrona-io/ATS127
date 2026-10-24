# TriggerBindings, TriggerTemplates And tt.params

A push event carries everything a build needs: the repository, the branch and the commit ID. The Pipeline `ci-build` needs exactly those values as the parameters `repo-url`, `branch` and `revision`. Something has to read the values out of the JSON body and put them into a new `PipelineRun`. In Tekton Triggers, a `TriggerBinding` does the reading and a `TriggerTemplate` does the writing. This part creates both and sends the first push event that starts a run.

## What a push event looks like

The `webhook-client` pod has sample payloads in `/payloads`. Look at the push to `main`:

<!-- astrona:playground:renew -->

```sh
kubectl exec -n starfleet deploy/webhook-client -- cat /payloads/push-main.json
```

The body has the fields that GitHub sends for a push, cut down to the ones this course uses: `ref` is the full name of the pushed branch (`refs/heads/main`), `head_commit.id` and `after` are the new commit ID, and `repository.clone_url` is the address to clone. GitHub also sends the header `X-GitHub-Event: push`, which says what kind of event the body describes.

## Read values with a TriggerBinding

A `TriggerBinding` is a list of parameters. Each value is a JSONPath expression in `$()` that the EventListener evaluates against the event: `$(body.<path>)` reads the JSON body, and `$(header.<name>)` reads a header.

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
      value: $(body.ref)
```

Apply it:

```sh
kubectl apply -f triggerbinding-github-push.yaml
```

The names on the left matter. The EventListener matches binding parameters to template parameters **by name**, so `revision` here fills the template parameter `revision` and nothing else. The paths on the right follow the JSON: `$(body.head_commit.id)` is the field `id` inside `head_commit`. Header names are not case sensitive, so `$(header.X-GitHub-Event)` and `$(header.x-github-event)` read the same header.

## Write a run with a TriggerTemplate

A `TriggerTemplate` declares parameters under `spec.params` and lists the objects to create under `spec.resourcetemplates`. Inside a resource template, `$(tt.params.<name>)` is replaced by the value of the parameter. The `tt.` prefix keeps these apart from the `$(params.<name>)` of the Pipeline itself.

Save this as `triggertemplate-ci-build-run.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: ci-build-run
  namespace: starfleet
spec:
  params:
    - name: repo-url
      description: The clone URL of the repository
    - name: revision
      description: The commit ID to build
    - name: branch
      description: The branch that was pushed
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: PipelineRun
      metadata:
        generateName: ci-build-run-
      spec:
        pipelineRef:
          name: ci-build
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
kubectl apply -f triggertemplate-ci-build-run.yaml
```

The `PipelineRun` uses `generateName`, not `name`. Every event creates a new object, and the API server adds a random suffix to `ci-build-run-` each time. With a fixed `name`, the first event would create the run and every later event would fail, because the name is taken. The Triggers webhook also checks the template when you apply it: a `$(tt.params.<name>)` that is not declared under `spec.params` is refused at once.

## Send a push event

The EventListener `starfleet-ci` already refers to `github-push` and `ci-build-run` by name, so it picks up both objects with the next event. Send the push payload from the client pod. `--data-binary @file` sends the file exactly as it is, and `Content-Type: application/json` says that the body is JSON:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary @/payloads/push-main.json http://el-starfleet-ci.starfleet.svc.cluster.local:8080
```

The response is the same `202` JSON as before, with a new `eventID`. This time the EventListener pod found the binding and the template and created a `PipelineRun`. Find it by the label that Triggers puts on everything it creates:

```sh
kubectl get pipelineruns -n starfleet -l triggers.tekton.dev/eventlistener=starfleet-ci
```

The run is named `ci-build-run-` plus a random suffix. Triggers adds three labels to every object it creates: `triggers.tekton.dev/eventlistener` with the EventListener's name, `triggers.tekton.dev/trigger` with the Trigger's name (`github-push`), and `triggers.tekton.dev/triggers-eventid` with the `eventID` from the response. Read the parameters and the result of the newest run:

```sh
tkn pipelinerun describe --last -n starfleet
```

The parameters are `repo-url` = `https://git.example.com/starfleet/bridge.git`, `revision` = `4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39` and `branch` = `refs/heads/main`. When the run has succeeded, its result `summary` reads `built refs/heads/main at 4f1c2a9e8b7d6c5f4e3d2c1b0a9f8e7d6c5b4a39`. The `branch` value is the full ref; a binding can only copy a field, not cut it. An interceptor can compute a shorter value before the binding runs.

## When a value is missing

Events do not always have the fields a binding expects. The EventListener handles a missing value in one of three ways, and each one leaves a different trace:

| Situation | What the EventListener does |
| --- | --- |
| The binding's path does not exist, and the template parameter has a `default` | It uses the default |
| The binding's path does not exist, and there is no default | It logs `failed to replace JSONPath value for param ...` and creates nothing |
| No binding sets the parameter, and there is no default | It creates the run with the literal text `$(tt.params.<name>)` and logs a warning |

Try the second case. The empty JSON object `{}` has no `head_commit`, and the template has no defaults:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' --data-binary '{}' http://el-starfleet-ci.starfleet.svc.cluster.local:8080
kubectl logs -n starfleet -l eventlistener=starfleet-ci --tail=5
```

The response is `202` again, no new run appears, and the log has an error with `failed to replace JSONPath value for param`. The log line also carries the event ID, so you can match it to the response.

## Share a binding with ClusterTriggerBinding

A `ClusterTriggerBinding` has the same `spec.params` as a `TriggerBinding`, but it is cluster-scoped, so a platform team can define the GitHub push fields once and every namespace can use them. A Trigger refers to it with `kind: ClusterTriggerBinding` in its bindings entry:

```yaml
bindings:
  - ref: github-push
    kind: ClusterTriggerBinding
```

Without `kind`, the EventListener looks for a namespaced `TriggerBinding` of that name, and if there is none, it logs that it cannot find it and creates nothing. Reading ClusterTriggerBindings is also why the EventListener's ServiceAccount needs the ClusterRoleBinding to `tekton-triggers-eventlistener-clusterroles`. A Trigger can list several bindings, and also inline bindings with a fixed value, such as `- name: branch` and `value: main`.

You can now take a field from an event, pass it by name from a binding to a template, and create a new `PipelineRun` for every event. You also know where to look when no run appears: the EventListener's log, matched by event ID. The open question is trust: right now, any pod that can reach the Service can start a build with any values it likes.

## Common pitfalls

> [!WARNING]
> - **Names that do not match.** A binding parameter fills only the template parameter with the same name. A typo leaves the template parameter empty, and the run gets the literal `$(tt.params.<name>)`.
> - **A path the payload does not have.** For example `$(body.head_commit.sha)` instead of `$(body.head_commit.id)`. Without a default, nothing is created; read the EventListener's log.
> - **A fixed `name` in the resource template.** Only the first event creates a run. Use `generateName`.
> - **`curl -d` without a content type.** `curl -d` sends the body as a form (`application/x-www-form-urlencoded`). Set `Content-Type: application/json` and use `--data-binary` so the body is sent unchanged.
> - **A ClusterTriggerBinding without `kind`.** The reference then looks for a namespaced `TriggerBinding`. Add `kind: ClusterTriggerBinding`.

## Your mission: Create An EventListener For Push Events

You can now give an EventListener a ServiceAccount with the right bindings and turn a push event into a `PipelineRun` with a binding and a template. The graded lab gives you an empty `starfleet` namespace with the Pipeline `ci-build` and the template `ci-build-run`, and asks you to build the ServiceAccount, its RBAC, the binding and the EventListener so that a push starts a run with the right values.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-127-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-127-lab-010-01
astrona start ats-127-playground-010-01
```
