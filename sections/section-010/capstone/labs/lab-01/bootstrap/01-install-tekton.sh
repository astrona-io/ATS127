#!/usr/bin/env bash
# Installs the environment for ats-127-capstone-010.
#
# Graded lab bootstrap: this prepares the environment ONLY. It never creates the objects the task asks for and never fixes the seeded fault.
# This script:
#   1. puts the tkn command-line tool (pinned) on the PATH,
#   2. applies the namespace starfleet,
#   3. installs Tekton Pipelines v1.17.1, then Tekton Triggers v0.37.2 and its core interceptors, and waits for their webhooks,
#   4. starts the webhook client (nicolaka/netshoot:v0.13) in starfleet.
LOG="[lab]"
set -euo pipefail

TKN_VERSION="0.46.2"
PIPELINES_VERSION="v1.17.1"
TRIGGERS_VERSION="v0.37.2"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Pin the version rather than accepting whatever tkn happens to be on the
# machine: the course is written against tkn ${TKN_VERSION}.
have_version=""
if command -v tkn >/dev/null 2>&1; then
  have_version="$(tkn version --component client 2>/dev/null || true)"
  have_version="${have_version#v}"
fi
if [ "$have_version" != "$TKN_VERSION" ]; then
  case "$(uname -s)" in
    Darwin) TKN_OS="Darwin"; TKN_ARCH="all" ;;
    Linux)
      TKN_OS="Linux"
      case "$(uname -m)" in
        x86_64|amd64) TKN_ARCH="x86_64" ;;
        aarch64|arm64) TKN_ARCH="aarch64" ;;
        *) echo "ERROR: no tkn release for $(uname -m)." >&2; exit 1 ;;
      esac ;;
    *) echo "ERROR: no tkn release for $(uname -s)." >&2; exit 1 ;;
  esac
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  echo "$LOG Downloading tkn ${TKN_VERSION} (${TKN_OS}/${TKN_ARCH})..."
  curl -fsSL -o "$WORK/tkn.tar.gz" \
    "https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_${TKN_OS}_${TKN_ARCH}.tar.gz"
  tar -xzf "$WORK/tkn.tar.gz" -C "$WORK" tkn
  install -m 0755 "$WORK/tkn" "$BIN_DIR/tkn"
fi
echo "$LOG tkn client version: $(tkn version --component client)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done
[ -n "$MANIFEST_DIR" ] || { echo "ERROR: manifests folder not found." >&2; exit 1; }

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"

apply_with_retry() {
  # apply_with_retry ARGS...: kubectl apply, retried while the API server or
  # a Tekton webhook is still starting.
  local attempt
  for attempt in $(seq 1 30); do
    if kubectl apply "$@"; then
      return 0
    fi
    echo "$LOG kubectl apply failed (attempt $attempt), retrying in 5s..."
    sleep 5
  done
  echo "ERROR: kubectl apply $* kept failing." >&2
  return 1
}

wait_for_dry_run() {
  # wait_for_dry_run WHAT FILE: retry a server-side dry run of FILE until the
  # admission webhook that validates it answers. A Deployment can be
  # Available a moment before its Service answers.
  local what="$1" file="$2" attempt
  for attempt in $(seq 1 60); do
    if kubectl apply --dry-run=server -f "$file" >/dev/null 2>&1; then
      echo "$LOG The $what webhook answers."
      return 0
    fi
    sleep 5
  done
  echo "ERROR: the $what webhook did not answer within 5 minutes." >&2
  return 1
}

PROBE_DIR="$(mktemp -d)"
cat > "$PROBE_DIR/task.yaml" <<'YAML'
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: webhook-probe
  namespace: starfleet
spec:
  steps:
    - name: probe
      image: busybox:1.37.0
      script: |
        echo probe
YAML
cat > "$PROBE_DIR/triggerbinding.yaml" <<'YAML'
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: webhook-probe
  namespace: starfleet
spec:
  params:
    - name: probe
      value: $(body.probe)
YAML

echo "$LOG Installing Tekton Pipelines ${PIPELINES_VERSION}..."
apply_with_retry -f "https://infra.tekton.dev/tekton-releases/pipeline/previous/${PIPELINES_VERSION}/release.yaml"
for deployment in tekton-pipelines-controller tekton-pipelines-webhook tekton-events-controller; do
  kubectl -n tekton-pipelines rollout status "deployment/$deployment" --timeout=300s
done
kubectl -n tekton-pipelines-resolvers rollout status deployment/tekton-pipelines-remote-resolvers --timeout=300s
wait_for_dry_run "Tekton Pipelines" "$PROBE_DIR/task.yaml"

# Triggers installs into tekton-pipelines, which the Pipelines release creates.
echo "$LOG Installing Tekton Triggers ${TRIGGERS_VERSION}..."
apply_with_retry -f "https://infra.tekton.dev/tekton-releases/triggers/previous/${TRIGGERS_VERSION}/release.yaml"
for deployment in tekton-triggers-controller tekton-triggers-webhook; do
  kubectl -n tekton-pipelines rollout status "deployment/$deployment" --timeout=300s
done
wait_for_dry_run "Tekton Triggers" "$PROBE_DIR/triggerbinding.yaml"

# interceptors.yaml holds ClusterInterceptor objects, which the Triggers
# webhook validates, so it comes after the webhook answers.
echo "$LOG Installing the Triggers core interceptors ${TRIGGERS_VERSION}..."
apply_with_retry -f "https://infra.tekton.dev/tekton-releases/triggers/previous/${TRIGGERS_VERSION}/interceptors.yaml"
kubectl -n tekton-pipelines rollout status deployment/tekton-triggers-core-interceptors --timeout=300s

# The core interceptors write their CA certificate into each
# ClusterInterceptor. An EventListener waits for it before it serves.
for interceptor in github cel; do
  ca=""
  for _ in $(seq 1 60); do
    ca="$(kubectl get clusterinterceptor "$interceptor" -o jsonpath='{.spec.clientConfig.caBundle}' 2>/dev/null || true)"
    [ -n "$ca" ] && break
    sleep 5
  done
  if [ -z "$ca" ]; then
    echo "ERROR: ClusterInterceptor $interceptor has no caBundle after 5 minutes." >&2
    exit 1
  fi
done
echo "$LOG The core interceptors are ready."
rm -rf "$PROBE_DIR"

echo "$LOG Starting the webhook client..."
apply_with_retry -f "$MANIFEST_DIR/webhook-client.yaml"
kubectl -n starfleet rollout status deployment/webhook-client --timeout=300s

echo "$LOG Environment ready."
kubectl get pods -n tekton-pipelines 2>/dev/null || true
