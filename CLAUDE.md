# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS127 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Triggers, Interceptors & Event-Driven CI** domain
  of the **Tekton** training path (`ATP024`). It is 15% of the path. There is
  no official Tekton certification exam; the path's domains and weights are
  Astrona's own, set in `ATP024/path.yaml` (10/20/25/15/15/15 for ATS124 to
  ATS129).
- **Where Tekton sits:** Tekton is an **incubating project of the Cloud Native
  Computing Foundation (CNCF)**. The CNCF accepted it on 13 March 2026. Before
  that it was a founding and graduated project of the Continuous Delivery
  Foundation (CD Foundation). It is **not** a CNCF graduated project, and it is
  no longer a CD Foundation project. Both foundations belong to the Linux
  Foundation. Say this correctly wherever the course mentions it.
- **What the domain really tests:** wiring events to runs, not remembering
  words. The student must *do* things (install Tekton Triggers, give an
  EventListener a ServiceAccount with the right RBAC, map payload fields to
  PipelineRun parameters, verify a GitHub HMAC signature, filter events with
  CEL, trace an event to the PipelineRun it created). Every explanation should
  lead to a command they can run, and every fix should be proved with a signed
  event that creates a PipelineRun with the expected parameters, and with
  events that must create nothing.
- **The three topics:** the Triggers architecture (EventListener, Trigger,
  TriggerBinding, ClusterTriggerBinding, TriggerTemplate, ServiceAccount and
  RBAC), interceptors (ClusterInterceptors, the GitHub interceptor with HMAC
  verification, CEL filters and overlays, chaining), and event-driven CI end
  to end (push and pull request payloads, several Triggers on one
  EventListener, tracing and cleaning up runs). The README table maps each
  section to its topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Tekton Triggers Architecture And RBAC | Triggers architecture |
  | 020 | Verify And Filter Events With Interceptors | Interceptors |
  | 030 | Event-Driven CI End To End | Event-driven CI |

- **The versions:** everything is written for **Tekton Triggers v0.37.2** on
  **Tekton Pipelines v1.17.1**, with the **tkn CLI v0.46.2**, on a single-node
  `kind` cluster. Triggers v0.37.2 was released on 22 October 2026. The
  Triggers project publishes no compatibility table with Pipelines; v0.37.2 is
  built against the Pipelines Go module v1.15.0 (the current long-term support
  release) and creates runs through the Kubernetes API, so it works with any
  Pipelines release that serves `tekton.dev/v1` PipelineRuns, such as v1.17.1.
  Triggers needs Kubernetes 1.28 or later, like Pipelines 1.17. v1.17 is a
  monthly Pipelines release (end of life 31 October 2026). Do not teach
  fields, flags or output from other versions without saying so.
- **The main sources:** the Tekton documentation, <https://tekton.dev/docs/>
  (Triggers pages), and the `docs/` folder and source of `tektoncd/triggers`
  at tag `v0.37.2` (`pkg/interceptors/github`, `pkg/interceptors/cel`,
  `pkg/sink`, `pkg/template`), plus `tektoncd/pipeline` at `v1.17.1` and
  `tektoncd/cli` at `v0.46.2`. Check every page against them.

### Status: every environment passes `astrona test`

All nine environments (three playgrounds, three labs, three capstones) passed
`astrona test` on 2026-10-25 on a laptop `kind` cluster with Podman. Pages
still describe results in words: add a `text` output block only when it is
pasted exactly from a real run. Run `astrona test` again on every environment
you change.

### Terms, not metaphors

Explanations use Tekton's and Kubernetes' own words. Define each one in plain
technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| Tekton Triggers | The Tekton project that creates Tekton objects, such as PipelineRuns, from HTTP events |
| Webhook | An HTTP POST request that a Git server sends to a URL when something happens in a repository |
| `EventListener` | A Triggers object that runs an HTTP server (a Deployment and a Service named `el-<name>`) and processes each event with its Triggers |
| `Trigger` | One rule of an EventListener: interceptors, bindings and a template; inline in the EventListener or a standalone object |
| `TriggerBinding` / `ClusterTriggerBinding` | A namespaced / cluster-wide list of parameters whose values come from the event (`$(body...)`, `$(header...)`, `$(extensions...)`) |
| `TriggerTemplate` | A list of resource templates, such as a PipelineRun, with parameters used as `$(tt.params.<name>)` |
| Interceptor | A step that runs before the bindings and can reject, check or add data to an event |
| `ClusterInterceptor` | A cluster-scoped object (`triggers.tekton.dev/v1alpha1`) that names the Service of an interceptor; the release ships `github`, `gitlab`, `bitbucket`, `cel` and `slack` |
| Core interceptors | The Deployment `tekton-triggers-core-interceptors` that serves the shipped ClusterInterceptors over HTTPS |
| HMAC | Hash-based message authentication code: a hash of the body computed with a shared secret; GitHub sends it as `X-Hub-Signature-256: sha256=<hex>` |
| CEL | Common Expression Language: a small expression language the `cel` interceptor uses for `filter` and `overlays` |
| `extensions` | The top-level field where interceptors add data; bindings read it as `$(extensions.<key>)` |
| Event ID | The ID the EventListener gives each request; returned as `eventID` and set as the label `triggers.tekton.dev/triggers-eventid` on created objects |

An EventListener and its Service are the most confused pair. On first use in
a file, say that the EventListener is the Triggers object and that the
controller creates a Deployment and a Service named `el-<name>` for it.

### The example workloads

| Name | Image | What it is |
| --- | --- | --- |
| Namespace `starfleet` | | Where every Triggers object, Pipeline and PipelineRun of the course lives |
| EventListener `starfleet-ci` | Tekton's `eventlistenersink` | The EventListener of every environment; Service `el-starfleet-ci`, port `8080` |
| ServiceAccount `starfleet-triggers` | | The EventListener's ServiceAccount |
| Pipeline `ci-build` | `busybox:1.37.0` | Parameters `repo-url`, `revision`, `branch` (no defaults); result `summary` = `built <branch> at <revision>` |
| Pipeline `pr-check` | `busybox:1.37.0` | Parameters `repo-url`, `revision`, `pr-number`; result `summary` = `checked pull request <n> at <revision>` (section 030) |
| TriggerTemplate `ci-build-run` / `pr-check-run` | | Create PipelineRuns with `generateName` `ci-build-run-` / `pr-check-run-` |
| TriggerBinding or ClusterTriggerBinding `github-push`, TriggerBinding `github-pull-request` | | Map payload fields to parameters |
| Secret `github-webhook-secret` | | Key `secretToken`, value `lab-only-webhook-secret` (lab only) |
| Deployment `webhook-client` | `nicolaka/netshoot:v0.13` | The client that sends signed GitHub-style webhooks with `openssl` and `curl`; payloads in `/payloads` |
| Repository `starfleet/bridge` | | The repository named in the payloads, `https://git.example.com/starfleet/bridge.git` (nothing clones it) |

Every step uses a `script`, never a bare image without `command`. No step
clones a repository: the Pipelines report the values they received, so the
labs need no Git server.

### Environment facts the text must respect

- **Install from the release manifests, Pipelines first.** Triggers has no
  namespace of its own: its `release.yaml` installs into `tekton-pipelines`,
  which the Pipelines release creates.
  `kubectl apply -f https://infra.tekton.dev/tekton-releases/triggers/previous/v0.37.2/release.yaml`
  then, after the Triggers webhook answers,
  `kubectl apply -f https://infra.tekton.dev/tekton-releases/triggers/previous/v0.37.2/interceptors.yaml`
  (the ClusterInterceptor objects in it are validated by the Triggers
  webhook).
- **What the Triggers release creates (checked in the v0.37.2 manifests):**
  Deployments `tekton-triggers-controller`, `tekton-triggers-webhook`
  (`release.yaml`) and `tekton-triggers-core-interceptors`
  (`interceptors.yaml`), all in `tekton-pipelines`; CRDs `eventlisteners`,
  `triggers`, `triggerbindings`, `triggertemplates`, `clustertriggerbindings`
  (`triggers.tekton.dev/v1beta1`, also served as `v1alpha1`),
  `clusterinterceptors` and `interceptors` (`v1alpha1` only); short names
  `el`, `tri`, `tb`, `tt`, `ctb`, `ci`, `ni`; ClusterInterceptors `github`,
  `gitlab`, `bitbucket`, `cel`, `slack` (Service
  `tekton-triggers-core-interceptors`, port 8443, path = name); ConfigMaps
  `feature-flags-triggers`, `config-defaults-triggers`,
  `config-logging-triggers`, `triggers-info`; ClusterRoles
  `tekton-triggers-eventlistener-roles` and
  `tekton-triggers-eventlistener-clusterroles`.
- **EventListener RBAC:** bind the EventListener's ServiceAccount to
  `tekton-triggers-eventlistener-roles` with a RoleBinding (get/list/watch on
  EventListeners, Triggers, TriggerBindings, TriggerTemplates, Interceptors
  and ConfigMaps; `create` on `pipelineruns`, `taskruns`; `impersonate` on
  ServiceAccounts; create Events) and to
  `tekton-triggers-eventlistener-clusterroles` with a ClusterRoleBinding
  (get/list/watch on ClusterTriggerBindings, ClusterInterceptors and Secrets).
  Without them, the EventListener pod cannot fill its informer caches, its
  HTTP server never starts, and the pod never becomes Ready. A Trigger can
  set its own `serviceAccountName`; the EventListener then impersonates it,
  and that ServiceAccount needs `create` on the run kind.
- **The EventListener (checked in the v0.37.2 source):** the controller
  creates a Deployment and a Service named `el-<name>` with the label
  `eventlistener=<name>`; Service type `ClusterIP`, port `8080` (name
  `http-listener`) plus `9000` for metrics; probes on `/live`. The
  EventListener's `Ready` condition follows the Deployment's `Available`
  condition. It answers every accepted request with **HTTP 202** and a JSON
  body with `eventListener`, `namespace`, `eventListenerUID` and `eventID`,
  **even when an interceptor rejects the event**: Triggers run after the
  response. A body that is not JSON gets HTTP 400. Kubernetes Events for
  EventListeners are off by default (`-el-events disable`).
- **Labels on created objects:** `triggers.tekton.dev/eventlistener`,
  `triggers.tekton.dev/trigger` and `triggers.tekton.dev/triggers-eventid`.
  Graders find their runs by the event ID label.
- **Bindings and templates:** binding values are JSONPath in `$()`:
  `$(body.head_commit.id)`, `$(header.X-GitHub-Event)`,
  `$(extensions.branch_name)`, `$(context.eventID)`. A path that does not
  resolve falls back to the template parameter's `default`; without a
  default the EventListener logs `failed to replace JSONPath value for param
  ...` and creates nothing. A template parameter with no value and no default
  stays as a literal `$(tt.params.<name>)` (the EventListener logs a warning).
  The Triggers webhook rejects a TriggerTemplate that uses an undeclared
  `$(tt.params.<name>)`. `$(uid)` is a random value per Trigger. Use
  `generateName` in resource templates; a fixed name works only once.
- **GitHub interceptor (checked in `pkg/interceptors/github` at v0.37.2):**
  reads `X-GitHub-Event` and checks it against `eventTypes` first; without
  `secretRef` it continues without any check; with `secretRef` it requires
  `X-Hub-Signature-256` (only the SHA-256 header) and reads the Secret from
  the Trigger's namespace with its own ServiceAccount. Messages: `event type
  <x> is not allowed`, `no X-Hub-Signature-256 header set`, `error getting
  secret: ...`, `payload signature check failed`. It refuses
  `application/x-www-form-urlencoded` bodies, so senders must set
  `Content-Type: application/json` (`curl -d` alone sends form encoding).
  GitLab: `X-Gitlab-Event`, plain token in `X-Gitlab-Token`. Bitbucket Server:
  `X-Event-Key`, signature in `X-Hub-Signature`.
- **CEL interceptor:** params `filter` (must return `true`, otherwise
  `expression <x> did not return true`) and `overlays` (`key`, `expression`;
  results go to `extensions.<key>`). Variables `body`, `header`,
  `requestURL`, `extensions`; functions such as `header.match()`,
  `.truncate()`, `.split()`, `.startsWith()`. The core interceptors log every
  response at info level (`Interceptor response is: ...`), which is where a
  rejected event shows up.
- **Sending a webhook:** the client pod computes the signature with
  `openssl dgst -sha256 -hmac "$SECRET"` over the exact bytes it sends with
  `curl --data-binary`. Graders build their own payload with a random 40-digit
  hex commit ID, read `eventID` from the response, and look for PipelineRuns
  with that event ID label. A negative check watches for 30 seconds and
  passes only if no PipelineRun appeared.
- **Many environments start broken on purpose.** A lab seeds a fault (a
  missing RoleBinding, a binding with the wrong kind or path, a wrong
  `secretKey`, a CEL filter for the wrong branch, a label selector that
  matches nothing, a Trigger ServiceAccount without permissions). The fault is
  the material. Never "fix" it in the bootstrap.
- **The proof is a PipelineRun.** A fix is proven with a signed event that
  creates a PipelineRun with the expected parameters whose `Succeeded`
  condition is `True`, and with events that must create nothing (a wrong
  signature, a filtered event type or branch). Graders delete the
  PipelineRuns they caused.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-install-tekton.sh`, `02-seed-state.sh` | The tkn CLI, Tekton Pipelines, Tekton Triggers with the core interceptors, the webhook client; then the starting state |
| `manifests/` | `lab-start.yaml` (namespace `starfleet`), `webhook-client.yaml`, and the seeded objects |
| `solution/apply.sh` | Reference end state, applied only by `astrona test` |
| `testing/wait-for-tekton.sh` | Waits until the Tekton Deployments and the webhook client answer before the reference solution runs |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS127`, domain
`Triggers, Interceptors & Event-Driven CI`, weight `15`) and one entry per
section under `modules:` (`module-010`, `module-020`, `module-030`). Each
section's `content` lists, in order: the section `README.md`, then for each
module its landing page, its parts, and right after the part a lab tests, a
`Question` reading (`labs/lab-01/question.md`) followed by the `type: lab`
entry; the module's closing page comes last. The section capstone closes the
section. Playgrounds are not listed.

Every `type: lab` entry carries the same fields, in the same order, as in
ATS016: `title`, `path`, `difficulty`, `estimated_duration`, `topic`,
`task_kind`, `tags`, `learning_goals`, `resources`.

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`.
- `topic`: exactly one of `triggers-architecture`, `interceptors`,
  `event-driven-ci`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `tekton.dev`, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Architecture: `eventlistener`, `trigger`, `triggerbinding`,
  `clustertriggerbinding`, `triggertemplate`, `tt-params`,
  `eventlistener-rbac`, `serviceaccount`, `triggers-install`
- Interceptors: `clusterinterceptor`, `github-interceptor`,
  `hmac-signature`, `webhook-secret`, `event-types`, `cel-filter`,
  `cel-overlays`, `interceptor-chain`
- Event-driven CI: `push-event`, `pull-request-event`, `pipelinerun`,
  `generatename`, `label-selector`, `event-id`, `trigger-serviceaccount`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-010/module-01/playground
astrona destroy ats-127-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-127-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-127-playground-<section>-<module>`, a module lab
is `ats-127-lab-<section>-<module>` and a capstone is
`ats-127-capstone-<section>`; keep those names. Lab bootstrap scripts do not
pin a kube context: astrona sets `KUBECONFIG` for the lab. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: a signed push
to `main` that creates a PipelineRun with the right parameters and
`Succeeded` `True`, and events that must create nothing (a wrong signature,
no signature, a filtered event type, a filtered branch, a closed pull
request). Graders also reject the plausible but wrong fix (binding the
EventListener's ServiceAccount to `cluster-admin` or `edit`, removing the
GitHub interceptor, removing the CEL filter, changing the shared secret,
turning standalone Triggers into inline ones). A lab's `question.md` and
`solution.md` must match what its `validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. Each environment
runs the four Tekton Pipelines Deployments, the three Triggers Deployments,
the EventListener and the webhook client. No script uses a fixed host port:
graders reach the EventListener from inside the cluster through
`kubectl exec deploy/webhook-client`.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Triggers concepts:** [overview](https://tekton.dev/docs/triggers/),
  [install](https://tekton.dev/docs/installation/triggers/)
- **APIs:** [EventListeners](https://tekton.dev/docs/triggers/eventlisteners/),
  [Triggers](https://tekton.dev/docs/triggers/triggers/),
  [TriggerBindings](https://tekton.dev/docs/triggers/triggerbindings/),
  [TriggerTemplates](https://tekton.dev/docs/triggers/triggertemplates/),
  [Interceptors](https://tekton.dev/docs/triggers/interceptors/),
  [ClusterInterceptors](https://tekton.dev/docs/triggers/clusterinterceptors/),
  [CEL expressions](https://tekton.dev/docs/triggers/cel_expressions/)
- **Source at v0.37.2:** `pkg/sink/sink.go` (202 response, trigger
  processing), `pkg/template/event.go` (binding resolution),
  `pkg/interceptors/github/github.go`, `pkg/interceptors/cel/cel.go`,
  `pkg/reconciler/eventlistener/resources/` (Deployment, Service, probes),
  `examples/rbac.yaml`
- **CLI:** [tkn](https://tekton.dev/docs/cli/) and `docs/cmd/` in
  `tektoncd/cli` at `v0.46.2` (`tkn eventlistener`, `tkn triggerbinding`,
  `tkn triggertemplate`, `tkn clustertriggerbinding`)
- **The landscape:** Tekton's page on the CNCF site,
  <https://www.cncf.io/projects/tekton/> (incubating, accepted 13 March 2026),
  and the CD Foundation announcement "Tekton moves to the CNCF" (24 March 2026).

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
