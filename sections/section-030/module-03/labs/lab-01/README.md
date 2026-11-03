---
estimated_duration: 25m
---

# Repair The Docs Trigger — Lab

- **ID:** LAB
- **Slug:** ats-127-lab-030-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. The build Trigger works, and a second Trigger, docs-check, should start a documentation check when a push changes a file under docs/. It never starts a run. The task is to find the two faults and repair the Trigger. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-030-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-030-03`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the build path, the docs-check Pipeline and template, and the broken Trigger |
| `manifests/` | The namespace, the webhook client, the Pipeline, RBAC, binding, template and EventListener |
| `solution/` | Reference solution used by `astrona test`: the repaired Trigger |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; each sends its own events |
