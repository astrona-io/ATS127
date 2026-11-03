#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# `astrona test` bootstraps and applies in one go. Wait until every Tekton
# Deployment (Pipelines, Triggers and the core interceptors) and the webhook
# client are Available, so the reference solution never races a component
# that is still starting.
set -euo pipefail

for namespace in tekton-pipelines tekton-pipelines-resolvers; do
  deployments="$(kubectl -n "$namespace" get deployment -o name 2>/dev/null || true)"
  for deployment in $deployments; do
    replicas="$(kubectl -n "$namespace" get "$deployment" -o jsonpath='{.spec.replicas}')"
    [ "$replicas" = "0" ] && continue
    kubectl -n "$namespace" rollout status "$deployment" --timeout=300s
  done
done
kubectl -n starfleet rollout status deployment/webhook-client --timeout=300s
echo "[test] Tekton Deployments and the webhook client are ready."
