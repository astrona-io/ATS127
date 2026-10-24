# Section 030: Event-Driven CI End To End

A real CI system reacts to more than one kind of event. A push to `main` builds and publishes; a pull request runs checks on the proposed change and reports back before anyone merges it. Both arrive at the same EventListener, signed with the same secret, but they carry different fields and must start different Pipelines. When something goes wrong, you need to follow one event from the HTTP request to the run it created, or find out why it created none.

This section puts the pieces together. You first compare the payloads of GitHub push and pull request events and map their fields to the parameters of two Pipelines. Then you split the work into standalone `Trigger` objects that one EventListener selects by label, and add a Trigger for pull requests next to the one for pushes. Last, you trace events by their event ID through the EventListener's response, the run's labels and the logs, and clean up the runs that events leave behind.

**Topic covered:** Event-driven CI

## What you will learn

- Which fields of a GitHub `push` and `pull_request` event a CI system needs, and which pull request actions should start a check.
- How to write standalone `Trigger` objects and select them with the `labelSelector` of an EventListener.
- How one event runs through every selected Trigger, and how the interceptors of each Trigger decide which one creates a run.
- How a Trigger can create its runs with its own ServiceAccount, and what the EventListener needs for that.
- How to follow an event by its event ID, read the EventListener with `tkn`, and clean up event-driven runs by label.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Run CI On Push And Pull Request Events

The module starts at its landing page, which also launches the playground. The playground runs Tekton Pipelines v1.17.1, Tekton Triggers v0.37.2 with the core interceptors, and in `starfleet` the Pipelines `ci-build` and `pr-check`, the webhook Secret, the ServiceAccount with its RBAC, the push binding, template and Trigger, and the webhook client pod.

1. GitHub Push And Pull Request Payloads
2. One EventListener, Several Triggers, followed by the lab **Add A Pull Request Trigger**
3. Trace And Clean Up Event-Driven Runs
4. Summary

## Section capstone: Repair An Event-Driven CI System

The capstone is one graded scenario that combines the whole module. The `starfleet` team runs pushes and pull requests through one EventListener with two standalone Triggers. Nothing starts any more: the EventListener selects no Triggers, the pull request Trigger allows an event type GitHub never sends, and its own ServiceAccount may not create runs. Find each fault by tracing signed events, fix it, and prove that pushes and pull requests start the right Pipelines again. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS127.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-127-capstone-030
```
