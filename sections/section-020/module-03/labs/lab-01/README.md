---
estimated_duration: 25m
---

# Repair A Custom Interceptor

- **ID:** LAB
- **Slug:** ats-127-lab-020-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. The Trigger calls a custom interceptor service, but the ClusterInterceptor names a Service that does not exist and the binding reads an extension the service does not return. The task is to repair both. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton Triggers v0.37.2 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-127-lab-020-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-lab-020-03`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines, Tekton Triggers and the webhook client, then the Pipeline, the RBAC, the interceptor service, the faulty ClusterInterceptor and binding, and the EventListener |
| `manifests/` | The namespace, the webhook client, the Pipeline, RBAC, the interceptor service, the ClusterInterceptor, binding, template and EventListener |
| `solution/` | Reference solution used by `astrona test`: the repaired ClusterInterceptor and binding |
| `testing/` | Waits for the Tekton Deployments and the webhook client |
| `validation/` | Grading scripts, one per check; each sends its own events |
