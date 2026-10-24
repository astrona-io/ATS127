---
estimated_duration: 30m
---

# Harden An Open EventListener

- **ID:** CAPSTONE
- **Slug:** ats-127-capstone-020
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Section 020 capstone for the namespace `starfleet`. The EventListener `starfleet-ci` has no interceptors and builds every request. The learner adds the webhook Secret, a GitHub interceptor with `secretRef` and `eventTypes`, a CEL interceptor with a filter for `main` and the overlay `branch_name`, and points the binding's `branch` at the overlay. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this capstone was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-capstone-020
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-capstone-020`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the open EventListener |
| `manifests/` | The namespace, the webhook client, the Pipeline, RBAC, binding, template and the open EventListener |
| `solution/` | Reference solution used by `astrona test`: Secret, binding and hardened EventListener |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; four of them send their own events |
