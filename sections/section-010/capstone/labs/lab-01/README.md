---
estimated_duration: 30m
---

# Repair An EventListener That Starts No Runs

- **ID:** CAPSTONE
- **Slug:** ats-127-capstone-010
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Section 010 capstone for the namespace `starfleet`. Three faults stand between a push event and a `PipelineRun`: a missing RoleBinding for the EventListener's ServiceAccount, a binding reference without `kind: ClusterTriggerBinding`, and a ClusterTriggerBinding that reads `head_commit.sha`. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this capstone was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-capstone-010
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-capstone-010`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the broken EventListener |
| `manifests/` | The namespace, the webhook client, the Pipeline, the TriggerTemplate, the ServiceAccount, the ClusterTriggerBinding and the EventListener |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; the last one sends its own push event |
