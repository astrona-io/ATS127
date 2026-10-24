# Summary

Event-driven CI sends each kind of Git event to the Pipeline meant for it, with the values of that event, and leaves a trail that ties every run to the request that caused it.

## What you learned

GitHub push and pull request events describe a commit in different places. A push names the branch in `ref` as a full ref and the commit in `head_commit.id` and `after`. A pull request event has an `action`, a `number`, the proposed change in `pull_request.head` and the target branch in `pull_request.base`; its check runs on `pull_request.head.sha`. Only the actions `opened`, `synchronize` and `reopened` change the code. Tag pushes, deleted branches and the `ping` event need filters too.

A `Trigger` can be its own object with interceptors, bindings, a template and an optional ServiceAccount. An EventListener with a `labelSelector` selects every Trigger in its namespace whose labels match, at the time each event arrives, so teams add Triggers without touching the EventListener. Every event runs through every selected Trigger, and the interceptors of each Trigger decide whether it acts: `eventTypes` separates pushes from pull requests, and CEL filters pick branches and actions. When a Trigger sets `serviceAccountName`, the EventListener impersonates that ServiceAccount to create the run, and that ServiceAccount needs `create` on PipelineRuns.

The EventListener returns an `eventID` with every `202` response, writes it into its log lines and sets it as the label `triggers.tekton.dev/triggers-eventid` on what it creates. Together with the labels `triggers.tekton.dev/eventlistener` and `triggers.tekton.dev/trigger`, that is how you find the run of an event, and how you clean up: `tkn pipelinerun delete` with `--label` and `--keep` removes old runs of one Trigger and leaves the rest. The key facts to remember are these:

- One event, every selected Trigger, each with its own interceptor chain.
- A label selector that matches no Trigger gives a ready EventListener that never creates anything.
- Interceptor answers are in the core interceptors' log; binding errors and permission errors are in the EventListener's log.
- Match runs to events by the event ID label, never by time.

<!-- astrona:playground:destroy -->
