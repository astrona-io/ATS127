# Retention Labels In The Template

The cleanup rule needs a label to select on. Runs created by hand carry whatever label you give them, but runs created by an EventListener come from a TriggerTemplate, so the template is where retention is decided.

## Add labels to the PipelineRun in the template

The template creates its `PipelineRun` from the `resourcetemplates` list. Put the label in the `metadata` of that resource, like in any manifest:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: ci-build-run
  namespace: starfleet
spec:
  params:
    - name: repo-url
    - name: revision
    - name: branch
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: PipelineRun
      metadata:
        generateName: ci-build-run-
        labels:
          purpose: ci-build
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

The EventListener adds its own labels next to yours. Your label does not replace them.

## Labels from event values

A template parameter can fill a label value, because `$(tt.params.<name>)` is replaced anywhere in the resource. A label value must follow the Kubernetes rules: at most 63 characters, only letters, digits, `-`, `_` and `.`, starting and ending with a letter or a digit. A branch name such as `feature/warp` contains a slash and is not a valid label value. Use a value you control, such as a fixed word per template, or a value that a CEL overlay has cleaned.

## One template, two purposes

Two different retention rules need two different labels. The simplest way is two templates, one for builds and one for releases, each with its own `purpose`, and a Trigger for each. Another is a parameter: a binding sets `purpose` from the event, for example from a CEL expression that returns `release` for tag pushes and `ci-build` for branch pushes, and the template uses `$(tt.params.purpose)` in the label.

The rule of the CronJob from the last part, `purpose!=release`, then keeps releases and removes everything else. Choose the label values so that the rule you write is a short selector you can read at a glance.

## Check it

After you change a template, send an event and look at the run it creates:

```sh
kubectl get pipelineruns -n starfleet -L purpose,triggers.tekton.dev/trigger --sort-by=.metadata.creationTimestamp
```

A run created before the change keeps its old labels, because labels are set when the object is created. Only new runs carry the new label, so a cleanup rule needs to handle the unlabelled runs of the past as well. That is another reason to prefer a negative selector such as `purpose!=release`.

You can now decide at creation time which runs are safe to remove and write a selector that says so.

## Common pitfalls

> [!WARNING]
> - **Putting a branch name in a label value.** Slashes are not allowed, and the run is not created.
> - **Changing the label of an existing template and expecting old runs to follow.** Labels apply to new runs only.
> - **Using a positive selector on a new label.** Old runs have no such label and are never cleaned. Prefer a negative selector for the keep rule.
