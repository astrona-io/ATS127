---
estimated_duration: 35m
---

# Repair An Event-Driven CI System

- **ID:** CAPSTONE
- **Slug:** ats-127-capstone-030
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Section 030 capstone for the namespace `starfleet`. One EventListener selects two standalone Triggers by label. Three faults stop every event: the label selector matches no Trigger, the pull request Trigger allows the event type `pull-request`, and its own ServiceAccount `starfleet-pr-runner` may not create PipelineRuns. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this capstone was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-capstone-030
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-capstone-030`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the broken CI setup |
| `manifests/` | The namespace, the webhook client, both Pipelines, RBAC, Secret, bindings, templates, Triggers, the ServiceAccount `starfleet-pr-runner` and the EventListener |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; three of them send their own events |
