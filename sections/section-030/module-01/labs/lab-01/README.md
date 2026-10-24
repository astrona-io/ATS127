---
estimated_duration: 30m
---

# Add A Pull Request Trigger

- **ID:** LAB
- **Slug:** ats-127-lab-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. The push path works through a standalone Trigger that the EventListener selects by label; the learner adds the TriggerBinding, TriggerTemplate and standalone Trigger for pull requests. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-030-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the push path |
| `manifests/` | The namespace, the webhook client, both Pipelines, RBAC, Secret, the push binding, template and Trigger, and the EventListener |
| `solution/` | Reference solution used by `astrona test`: the pull request binding, template and Trigger |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; three of them send their own events |
