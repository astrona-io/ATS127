# GitHub Push And Pull Request Payloads

A push and a pull request both describe a commit in a repository, but GitHub puts the commit ID, the branch and the reason for the event in different places. A binding written for a push reads empty or wrong values from a pull request, and a filter written for one event type fails on the other. Before you add a second Trigger, you need to know both payloads well enough to map each field to the right parameter. This part compares them and writes the binding and the template for pull requests.

## Two payloads side by side

The `webhook-client` pod has `jq`, a command-line JSON processor, so you can pick fields out of the sample payloads without reading the whole file. Start with the push to `main`:

<!-- astrona:playground:renew -->

```sh
kubectl exec -n starfleet deploy/webhook-client -- jq '{ref, after, head_commit: .head_commit.id, clone_url: .repository.clone_url}' /payloads/push-main.json
```

A push names the branch in `ref` as a full ref, `refs/heads/main`, and the new commit in `after` and in `head_commit.id`. Now the pull request that was just opened:

```sh
kubectl exec -n starfleet deploy/webhook-client -- jq '{action, number, head: .pull_request.head, base: .pull_request.base.ref, clone_url: .repository.clone_url}' /payloads/pull-request-opened.json
```

A pull request event has no `ref` and no `head_commit` at the top level. It has an `action`, here `opened`, the pull request `number`, and two branches: `pull_request.head` is the branch with the proposed change (`feature-shields` and its commit `sha`), and `pull_request.base` is the branch it wants to merge into (`main`).

| What the Pipeline needs | Push event | Pull request event |
| --- | --- | --- |
| Clone URL | `repository.clone_url` | `repository.clone_url` |
| Commit to check out | `head_commit.id` or `after` | `pull_request.head.sha` |
| Branch | `ref` (full ref, `refs/heads/main`) | `pull_request.head.ref` (short name); target in `pull_request.base.ref` |
| Number | none | `number` |
| Why it was sent | always a push | `action` |
| Header `X-GitHub-Event` | `push` | `pull_request` |

The check for a pull request runs on `pull_request.head.sha`, the latest commit of the proposed change. The base branch matters for filtering: a team usually checks only pull requests that target its main branch.

## Events that should not start anything

Not every delivery of an event type should create a run. For pull requests, the `action` field says what happened, and only some actions change the code:

| `action` | What happened | Run a check? |
| --- | --- | --- |
| `opened` | The pull request was created | Yes |
| `synchronize` | New commits were pushed to the head branch | Yes |
| `reopened` | A closed pull request was opened again | Yes |
| `closed` | It was closed or merged (`pull_request.merged` says which) | No |
| `edited`, `labeled`, `assigned` | The title, labels or people changed | No |

Pushes have their own cases. A pushed tag has a `ref` such as `refs/tags/v1.0.0`. A deleted branch has `"deleted": true`, its `after` is forty zeros, and its `head_commit` is `null`, so a binding that reads `head_commit.id` fails. GitHub also sends a `ping` event with `X-GitHub-Event: ping` when you first add the webhook. A filter on `ref` and a list of `eventTypes` keep all of these out of the build.

## A binding and a template for pull requests

The Pipeline `pr-check` in `starfleet` takes the parameters `repo-url`, `revision` and `pr-number`, and writes `checked pull request <n> at <revision>` to its result `summary`. The binding reads the matching fields of a pull request event.

Save this as `triggerbinding-github-pull-request.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: github-pull-request
  namespace: starfleet
spec:
  params:
    - name: repo-url
      value: $(body.repository.clone_url)
    - name: revision
      value: $(body.pull_request.head.sha)
    - name: pr-number
      value: $(body.number)
```

Apply it:

```sh
kubectl apply -f triggerbinding-github-pull-request.yaml
```

`number` is a JSON number, not a string. A binding turns it into the text `7`, which is what a Tekton string parameter needs. The template creates a `PipelineRun` of `pr-check` with its own `generateName`, so pull request runs are easy to tell apart from push runs.

Save this as `triggertemplate-pr-check-run.yaml`:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: pr-check-run
  namespace: starfleet
spec:
  params:
    - name: repo-url
      description: The clone URL of the repository
    - name: revision
      description: The head commit ID of the pull request
    - name: pr-number
      description: The number of the pull request
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: PipelineRun
      metadata:
        generateName: pr-check-run-
      spec:
        pipelineRef:
          name: pr-check
        params:
          - name: repo-url
            value: $(tt.params.repo-url)
          - name: revision
            value: $(tt.params.revision)
          - name: pr-number
            value: $(tt.params.pr-number)
```

Apply it:

```sh
kubectl apply -f triggertemplate-pr-check-run.yaml
```

Then check the result with `tkn`, which lists Triggers objects like Pipelines objects:

```sh
tkn triggerbinding list -n starfleet
tkn triggertemplate describe pr-check-run -n starfleet
```

Two bindings exist now, `github-push` and `github-pull-request`, and the template `pr-check-run` lists its three parameters and one `PipelineRun` resource template.

You can now read the fields of both event types, tell which events should start a build or a check, and map a pull request to the parameters of `pr-check`. Nothing receives events yet, and nothing decides which of the two templates an event should use. That is the job of the Triggers and their interceptors.

## Common pitfalls

> [!WARNING]
> - **Reading push fields from a pull request.** `$(body.head_commit.id)` and `$(body.ref)` do not exist in a `pull_request` event. Use `pull_request.head.sha` and `pull_request.head.ref`.
> - **Checking the base commit.** `pull_request.base.sha` is the target branch, not the proposed change. The check runs on `pull_request.head.sha`.
> - **Building every action.** `closed`, `edited` and `labeled` arrive as `pull_request` events too. Filter on `action`.
> - **Forgetting deletes and tags.** A deleted branch has no `head_commit`; a tag push has `refs/tags/...` in `ref`.
> - **Comparing `number` as a string in CEL.** In a binding it becomes text, but in a CEL expression it is a number (`double`).
