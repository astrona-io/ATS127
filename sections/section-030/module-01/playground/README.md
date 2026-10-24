# Run CI On Push And Pull Request Events — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-127-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment with Tekton Pipelines v1.17.1, Tekton Triggers v0.37.2 with the core interceptors, the tkn CLI 0.46.2, and in the namespace `starfleet` the Pipelines `ci-build` and `pr-check`, the ServiceAccount `starfleet-triggers` with its RBAC, the Secret `github-webhook-secret`, the TriggerBinding `github-push`, the TriggerTemplate `ci-build-run`, the standalone Trigger `github-push` (label `team: starfleet`) and the webhook client pod. No EventListener: the reader creates it with a label selector. Nothing to submit.

Not yet run: this playground was written from the Tekton documentation and
the v1.17.1 and v0.37.2 release manifests and has not been started on a cluster yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-127-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-playground-030-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Environment preparation run once at startup |
| `manifests/lab-start.yaml` | The namespace `starfleet` |
| `manifests/webhook-client.yaml` | The webhook client Deployment and the ConfigMap `webhook-payloads` |
| `manifests/pipeline-ci-build.yaml`, `pipeline-pr-check.yaml` | The two Pipelines |
| `manifests/rbac-starfleet-triggers.yaml` | The ServiceAccount `starfleet-triggers`, its RoleBinding and ClusterRoleBinding |
| `manifests/secret-github-webhook-secret.yaml` | The lab-only webhook secret |
| `manifests/triggerbinding-github-push.yaml`, `triggertemplate-ci-build-run.yaml`, `trigger-github-push.yaml` | The push path |
| `docs/overview.md` | What the environment contains and ideas to try |
