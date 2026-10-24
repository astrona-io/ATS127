# Turn A Webhook Into A PipelineRun — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-127-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment with Tekton Pipelines v1.17.1, Tekton Triggers v0.37.2 with the core interceptors, the tkn CLI 0.46.2, the Pipeline `ci-build` and the webhook client pod in the namespace `starfleet`. No EventListener exists yet: the reader builds it. Nothing to submit.

Not yet run: this playground was written from the Tekton documentation and
the v1.17.1 and v0.37.2 release manifests and has not been started on a cluster yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-127-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-127-playground-010-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Environment preparation run once at startup |
| `manifests/lab-start.yaml` | The namespace `starfleet` |
| `manifests/webhook-client.yaml` | The webhook client Deployment and the ConfigMap `webhook-payloads` |
| `manifests/pipeline-ci-build.yaml` | The Pipeline `ci-build` |
| `docs/overview.md` | What the environment contains and ideas to try |
