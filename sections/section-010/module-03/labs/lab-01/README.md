---
estimated_duration: 25m
---

# Repair A Multi-Resource Template

- **ID:** LAB
- **Slug:** ats-127-lab-010-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. The template creates a PipelineRun and a ConfigMap, but no run appears: the binding reads a path that a push event does not have, and the ServiceAccount may not create ConfigMaps. The task is to repair both without widening the rights. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-010-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-010-03`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the Pipeline, RBAC, template, binding and the EventListener with the two faults |
| `manifests/` | The namespace, the webhook client, the Pipeline, RBAC, binding, template and EventListener |
| `solution/` | Reference solution used by `astrona test`: the repaired binding and a Role that allows creating ConfigMaps |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; each sends its own events |
