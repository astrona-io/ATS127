# Path-Filtered And Multi-Pipeline Triggers — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-127-playground-030-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment with Tekton Pipelines v1.17.1, Tekton Triggers v0.37.2 with the core interceptors, the tkn CLI 0.46.2, and in the namespace `starfleet` the Pipelines `ci-build`, `pr-check` and `docs-check`, the EventListener `starfleet-ci` that selects Triggers by the label `team: starfleet`, the Trigger `github-push`, the binding `github-push`, the templates `ci-build-run` and `docs-check-run`, the ServiceAccount and RBAC, and the webhook client pod with payloads that list changed files. The Trigger for documentation changes is not installed: the reader creates it. Nothing to submit.

Not yet run: this playground was written from the Tekton documentation and
the v1.17.1 and v0.37.2 release manifests and has not been started on a cluster yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-127-playground-030-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-playground-030-03`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Environment preparation run once at startup; applies the EventListener last |
| `manifests/lab-start.yaml` | The namespace `starfleet` |
| `manifests/webhook-client.yaml` | The webhook client Deployment and the ConfigMap `webhook-payloads` |
| `manifests/pipeline-ci-build.yaml`, `pipeline-pr-check.yaml`, `pipeline-docs-check.yaml` | The three Pipelines |
| `manifests/rbac-starfleet-triggers.yaml` | The ServiceAccount `starfleet-triggers`, its RoleBinding and ClusterRoleBinding |
| `manifests/secret-github-webhook-secret.yaml` | The lab-only webhook secret |
| `manifests/triggerbinding-github-push.yaml`, `triggertemplate-ci-build-run.yaml`, `triggertemplate-docs-check-run.yaml`, `trigger-github-push.yaml` | The push path and the template for documentation checks |
| `manifests/eventlistener-starfleet-ci.yaml` | The EventListener with a label selector |
| `docs/overview.md` | What the environment contains and ideas to try |
