---
estimated_duration: 25m
---

# Accept Signed GitLab Pushes

- **ID:** LAB
- **Slug:** ats-127-lab-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. The EventListener accepts every request and its binding expects a short branch name from an extension. The task is to check the GitLab token and the event type, accept only pushes to main, and add the short branch name. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-020-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-020-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the Pipeline, the Secret, the RBAC, the template, the binding and the open EventListener |
| `manifests/` | The namespace, the webhook client, the Pipeline, RBAC, binding, template and EventListener |
| `solution/` | Reference solution used by `astrona test`: the secured EventListener |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; each sends its own events |
