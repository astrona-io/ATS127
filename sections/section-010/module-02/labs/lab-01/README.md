---
estimated_duration: 25m
---

# Scale And Place An EventListener

- **ID:** LAB
- **Slug:** ats-127-lab-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. The EventListener starts with the defaults: one pod, no limits and a ClusterIP Service. The task is to scale it, label its pods, limit its memory and expose its Service. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-010-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-010-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the plain EventListener |
| `manifests/` | The namespace, the webhook client, the Pipeline, RBAC, binding, template and EventListener |
| `solution/` | Reference solution used by `astrona test`: the configured EventListener |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; each sends its own events |
