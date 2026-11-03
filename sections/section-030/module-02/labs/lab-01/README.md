---
estimated_duration: 30m
---

# Clean Up Old Runs — Lab

- **ID:** LAB
- **Slug:** ats-127-lab-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. The namespace holds three old build runs and one release run, and no cleanup job. The task is to delete the old builds, create a ServiceAccount that may only delete PipelineRuns, and schedule the cleanup with a CronJob. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-030-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-030-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the push path from the earlier modules and four seeded PipelineRuns |
| `manifests/` | The namespace, the webhook client, the Pipeline, RBAC, binding, template and EventListener |
| `solution/` | Reference solution used by `astrona test`: the deletion of the old runs, the ServiceAccount with its Role and the CronJob |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; each sends its own events |
