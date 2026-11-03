# Read Values With JSONPath

A binding is only as good as its paths. A path that is one letter wrong gives no error in the response, and the build simply does not start. Before you write bindings for real payloads, you need to know what a path can reach: nested fields, items of a list, headers and whole objects. And you need a way to look at the values a Trigger produced, without guessing. This part builds that way first, then uses it to read each kind of path.

## A debug template that prints its parameters

The fastest way to see what a binding produces is a template that creates a `TaskRun` whose steps print the parameters. A `TaskRun` is one execution of a Task, and its log shows what it received. The values go into environment variables, because a value with quotes or braces would break a shell command line.

<!-- astrona:playground:renew -->

Save this as `triggertemplate-show-values.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: show-values
  namespace: starfleet
spec:
  params:
    - name: repo
    - name: first-commit
    - name: second-commit
    - name: commits
    - name: event
    - name: missing
      default: not-in-the-payload
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: TaskRun
      metadata:
        generateName: show-values-
      spec:
        taskSpec:
          steps:
            - name: print
              image: busybox:1.37.0
              env:
                - name: REPO
                  value: $(tt.params.repo)
                - name: FIRST_COMMIT
                  value: $(tt.params.first-commit)
                - name: SECOND_COMMIT
                  value: $(tt.params.second-commit)
                - name: COMMITS
                  value: $(tt.params.commits)
                - name: EVENT
                  value: $(tt.params.event)
                - name: MISSING
                  value: $(tt.params.missing)
              script: |
                #!/bin/sh
                echo "repo=$REPO"
                echo "first-commit=$FIRST_COMMIT"
                echo "second-commit=$SECOND_COMMIT"
                echo "commits=$COMMITS"
                echo "event=$EVENT"
                echo "missing=$MISSING"
```

Apply it:

```sh
kubectl apply -f triggertemplate-show-values.yaml
```

## Paths for nested fields, items, headers and objects

Save this as `triggerbinding-github-push-detail.yaml`. Each path shows one kind of access:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: github-push-detail
  namespace: starfleet
spec:
  params:
    - name: repo
      value: $(body.repository.full_name)
    - name: first-commit
      value: $(body.commits[0].id)
    - name: second-commit
      value: $(body.commits[1].id)
    - name: commits
      value: $(body.commits)
    - name: event
      value: $(header.X-GitHub-Event)
    - name: missing
      value: $(body.nothing.here)
```

Apply it:

```sh
kubectl apply -f triggerbinding-github-push-detail.yaml
```

A dot goes into an object (`repository.full_name`). Square brackets with a number pick an item of a list, counted from zero (`commits[0]`). A path that ends on an object or a list, such as `$(body.commits)`, gives the JSON text of that value. A header is read by name, in any letter case. The last parameter, `missing`, points at a field that no payload has, and the template gives that parameter a `default`.

## Use a second EventListener for debugging

Leave the EventListener `starfleet-ci` as it is, and add one for experiments. Save this as `eventlistener-starfleet-debug.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: starfleet-debug
  namespace: starfleet
spec:
  serviceAccountName: starfleet-triggers
  triggers:
    - name: show-values
      bindings:
        - ref: github-push-detail
      template:
        ref: show-values
```

Apply it and wait for it:

```sh
kubectl apply -f eventlistener-starfleet-debug.yaml
kubectl rollout status deployment/el-starfleet-debug -n starfleet
```

## Send an event with a list and read the result

The sample payload files have no `commits` list, so send a small body of your own from the client pod:

```sh
kubectl exec -n starfleet deploy/webhook-client -- curl -sS -X POST -H 'Content-Type: application/json' -H 'X-GitHub-Event: push' --data-binary '{"ref":"refs/heads/main","repository":{"full_name":"starfleet/bridge"},"commits":[{"id":"a1b2c3","modified":["src/main.go"]},{"id":"d4e5f6","modified":["docs/index.md"]}]}' http://el-starfleet-debug.starfleet.svc.cluster.local:8080
tkn taskrun logs --last -n starfleet
```

The log has one line for each parameter. `first-commit` is `a1b2c3` and `second-commit` is `d4e5f6`. `event` is `push`. `commits` holds the JSON text of the whole list. `missing` shows `not-in-the-payload`: the path did not resolve, so the template used the default.

You can now read every kind of path and see what a Trigger produced. The binding in this part is one big list. A real team has some parameters that every Trigger needs and some that belong to one event type, and the next part splits them.

## Common pitfalls

> [!WARNING]
> - **A path that does not exist and a template parameter without a default.** The EventListener logs `failed to replace JSONPath value for param ...` and creates nothing. The response is still `202`.
> - **Counting list items from one.** The first item is `[0]`.
> - **Putting a JSON value into a shell command.** Quotes inside the value break the command. Pass it through an environment variable.
> - **Using the wrong letter case in a body path.** Body paths are case sensitive; only header names are not.
