# ATS127 — Triggers, Interceptors & Event-Driven CI (Tekton)

Course material for the **Triggers, Interceptors & Event-Driven CI** domain of
the Astrona Tekton training path ([ATP024](https://github.com/astrona-io/ATP024)),
which is **15% of the path**. Written for **Tekton Triggers v0.37.2** on
**Tekton Pipelines v1.17.1**, with the **tkn CLI v0.46.2**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Tekton documentation, the v1.17.1 and v0.37.2 release manifests and
> the Triggers source at v0.37.2. None has been started on a cluster, and no
> lab has passed `astrona test` yet. See `CLAUDE.md`.

Tekton is an incubating project of the Cloud Native Computing Foundation
(CNCF) since March 2026; before that it was a graduated project of the
Continuous Delivery Foundation. There is no official Tekton certification
exam; the path's domains and weights are Astrona's own.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Tekton Triggers Architecture And RBAC | 1 | 1 + capstone | Triggers architecture |
| [020](sections/section-020) | Verify And Filter Events With Interceptors | 1 | 1 + capstone | Interceptors |
| [030](sections/section-030) | Event-Driven CI End To End | 1 | 1 + capstone | Event-driven CI |

The order follows one event. Section 010 builds the path from an HTTP request
to a `PipelineRun`: the EventListener, its ServiceAccount and RBAC, a binding
and a template. Section 020 decides which requests may use that path, with the
GitHub signature check and CEL filters. Section 030 handles pushes and pull
requests side by side with standalone Triggers, and traces events when they
start nothing.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Turn A Webhook Into A PipelineRun](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Verify And Filter Webhooks With Interceptors](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Run CI On Push And Pull Request Events](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |

| Lab | Title | Kind | Faults or work |
| --- | --- | --- | --- |
| 010-01 | Create An EventListener For Push Events | build | ServiceAccount, RoleBinding and ClusterRoleBinding to the Triggers ClusterRoles, TriggerBinding, EventListener |
| 020-01 | Repair Signature Checks And A CEL Filter | troubleshooting | `secretKey: token` instead of `secretToken`; a CEL filter for `master` instead of `main` |
| 030-01 | Add A Pull Request Trigger | build | TriggerBinding, TriggerTemplate and standalone Trigger for pull requests next to a working push Trigger |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair An EventListener That Starts No Runs | missing RoleBinding (pod never ready), a binding reference without `kind: ClusterTriggerBinding`, `$(body.head_commit.sha)` instead of `head_commit.id` |
| [020](sections/section-020/capstone/labs/lab-01) | Harden An Open EventListener | build: webhook Secret, `github` interceptor with `secretRef` and `eventTypes`, CEL filter for `main`, overlay `branch_name` read by the binding |
| [030](sections/section-030/capstone/labs/lab-01) | Repair An Event-Driven CI System | a label selector that matches no Trigger, event type `pull-request`, a Trigger ServiceAccount without permission to create PipelineRuns |

---

## The lab environment

Every playground and lab is a single-node **kind** cluster (Kubernetes 1.28
or later) with the `tkn` CLI 0.46.2 installed on the machine and the
namespace `starfleet`. Tekton Pipelines v1.17.1 is installed from its release
manifest, then Tekton Triggers v0.37.2 from `release.yaml` and
`interceptors.yaml`. The Pipelines `ci-build` and `pr-check` use
`busybox:1.37.0` and clone nothing; they report the parameters they received.

There is no Git hosting account and no public address. The Deployment
`webhook-client` (`nicolaka/netshoot:v0.13`) in `starfleet` plays the Git
server: it signs GitHub-style payloads with `openssl` (HMAC-SHA256, header
`X-Hub-Signature-256`) and sends them with `curl` to the EventListener
Service `el-starfleet-ci` on port 8080. Both images are preloaded on the
node. Tekton's own images come from `ghcr.io` (and the `place-scripts` shell
image from `cgr.dev`) by digest, so every start needs outbound internet.

Graders send their own events from the client pod, with random commit IDs,
read the `eventID` from the response, and find the PipelineRuns by the label
`triggers.tekton.dev/triggers-eventid`. Negative checks (unsigned, wrongly
signed, filtered events) watch for 30 seconds and pass only when no
PipelineRun appears. Graders delete the runs they caused. No script uses a
fixed host port.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final cluster state** with independent checks, and
several of them deliberately reject the plausible-but-wrong fix (binding the
EventListener's ServiceAccount to `cluster-admin` or `edit`, copying a
ClusterTriggerBinding into a namespace, removing the signature check or the
CEL filter, moving standalone Triggers inline, dropping a Trigger's own
ServiceAccount).
