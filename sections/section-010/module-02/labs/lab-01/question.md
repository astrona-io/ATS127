# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Triggers architecture

## Scenario

The `starfleet` team runs its push builds through the EventListener `starfleet-ci`. Last night a node restarted, the single EventListener pod was gone for a minute, and pushes in that minute started no builds. The platform team also wants the pod to have memory limits, a `team` label for its cost report, and a Service that the node network can reach.

## Your task

1. Change the EventListener `starfleet-ci` so that it runs two pods.
2. Give the pods of the EventListener the label `team` with the value `starfleet`.
3. Give the container requests of `cpu` `50m` and `memory` `64Mi`, and limits of `cpu` `200m` and `memory` `128Mi`.
4. Change the Service `el-starfleet-ci` to the type `NodePort`. It must keep port `8080`.

## Constraints

- Make every change in the EventListener object. The controller reverts changes made in the Deployment or the Service.
- Keep the Trigger `github-push` with its binding and template as they are.
- Do not change the Pipeline `ci-build`, the TriggerTemplate or the TriggerBinding.

## Done when

- The EventListener `starfleet-ci` is `Ready` and its Deployment has two ready replicas.
- Both pods carry the labels `eventlistener=starfleet-ci` and `team=starfleet`, and the container of each pod has the requested limits.
- The Service `el-starfleet-ci` has the type `NodePort` and still serves port `8080`.
- A push event sent to `http://el-starfleet-ci.starfleet.svc.cluster.local:8080` still creates a `PipelineRun` of `ci-build` with the commit ID of the event, and that run succeeds.
