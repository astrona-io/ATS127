---
estimated_duration: 25m
---

# Repair Signature Checks And A CEL Filter

- **ID:** LAB
- **Slug:** ats-127-lab-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. The EventListener's GitHub interceptor names a key that the Secret does not have, and its CEL filter lets through pushes to `master` instead of `main`. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-020-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the EventListener with two faults |
| `manifests/` | The namespace, the webhook client, the Pipeline, RBAC, binding, template, Secret and EventListener |
| `solution/` | Reference solution used by `astrona test`: the fixed EventListener |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; each sends its own signed or unsigned events |
