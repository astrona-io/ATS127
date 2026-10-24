# Welcome To The Course

This course trains you for the **Triggers, Interceptors & Event-Driven CI** part of the Astrona **Tekton** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, pods, Services, Secrets, ServiceAccounts, Roles and RoleBindings, `kubectl apply`, `kubectl logs` and `kubectl exec`. You know the basics of Tekton Pipelines: a `Pipeline` is an ordered set of Tasks, and a `PipelineRun` is one execution of it with its own parameter values. You do not need to know Tekton Triggers yet. Each new idea is explained the first time it appears.

## What you can do at the end

A continuous integration (CI) system has to start builds by itself, when code changes. Tekton Triggers is the Tekton project that does that: it receives webhooks from a Git server and creates PipelineRuns from them. This course does not ask you to remember words. It asks you to wire events to runs, prove that only the right events get through, and find out why when a push starts nothing. The course has three topics, and each one turns into a set of skills you will practise.

The first topic is **the architecture of Tekton Triggers**. You will learn to:

- Install Tekton Triggers on top of Tekton Pipelines and name the objects it adds.
- Create an `EventListener` and give its ServiceAccount the permissions it needs.
- Map fields of an event to the parameters of a `PipelineRun` with a `TriggerBinding` and a `TriggerTemplate`.

An EventListener that accepts every request is not safe, so the second topic is **interceptors**. You will learn to:

- Explain how interceptors run before the bindings, and find out why one stopped an event.
- Verify GitHub webhooks with a shared secret and an HMAC signature.
- Filter events and compute new values with CEL expressions.

The third topic is **event-driven CI end to end**. You will learn to:

- Handle push and pull request events with separate Triggers behind one EventListener.
- Give a Trigger its own ServiceAccount.
- Follow an event by its ID to the run it created, and clean up old runs.

Everything is written for **Tekton Triggers v0.37.2** on **Tekton Pipelines v1.17.1**, with **tkn v0.46.2**.

## The words this course uses

The pages use Tekton's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **webhook** is an HTTP POST request that a Git server sends when something happens in a repository, such as a push. Tekton Triggers adds new resource kinds to Kubernetes to handle it:

| Object | What it is |
| --- | --- |
| `EventListener` | Receives webhooks. Tekton runs it as a pod behind a Service named `el-<name>` |
| `Trigger` | One rule: which interceptors, binding and template to use for an event |
| `TriggerBinding` | Reads values from the event, such as the commit ID |
| `TriggerTemplate` | Creates objects, such as a `PipelineRun`, with those values |
| Interceptor | A check that runs before the binding and can stop an event |

An **HMAC signature** is a hash of the request body computed with a shared secret; GitHub sends it so that the receiver can tell the request is genuine. **CEL** (Common Expression Language) is the small expression language the `cel` interceptor uses to filter events.

## The example setup in your playground

Every playground and lab runs on a small `kind` cluster with Tekton Pipelines and Tekton Triggers installed. Your objects live in the namespace `starfleet`. The EventListener is called `starfleet-ci`, and pushes start a Pipeline called `ci-build`, while pull requests start one called `pr-check`. The Pipelines do not clone anything; they report the values they received, so every run shows exactly what the event delivered.

There is no real GitHub account and no public address. A pod called `webhook-client` inside the cluster plays the Git server: it signs sample GitHub payloads about the repository `starfleet/bridge` with `openssl` and sends them with `curl`. The webhook secret is `lab-only-webhook-secret`, a value that is only for these labs.

Many labs start with something broken on purpose: an EventListener whose pod never becomes ready, a signature check that refuses every event, a Trigger nobody selects. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. It starts with the objects that turn a request into a run, then secures and filters the events, and ends with a complete CI setup for pushes and pull requests.

| Section | What it covers |
| --- | --- |
| 010 | Tekton Triggers Architecture And RBAC |
| 020 | Verify And Filter Events With Interceptors |
| 030 | Event-Driven CI End To End |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
