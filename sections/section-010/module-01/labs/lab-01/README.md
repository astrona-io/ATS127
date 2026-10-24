---
estimated_duration: 25m
---

# Create An EventListener For Push Events

- **ID:** LAB
- **Slug:** ats-127-lab-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-010-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the Pipeline and the TriggerTemplate |
| `manifests/` | The namespace `starfleet`, the webhook client, the Pipeline `ci-build`, the TriggerTemplate `ci-build-run` |
| `solution/` | Reference solution used by `astrona test`: ServiceAccount, two bindings, TriggerBinding, EventListener |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; the last one sends its own push event |
