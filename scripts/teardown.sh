#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[teardown]${NC} $*"; }

# ── Port forwards ─────────────────────────────────────────────────────────────

log "Stopping port forwards..."
pkill -f 'kubectl port-forward' 2>/dev/null && log "  → port forwards stopped" || log "  → no port forwards running"

# ── Kubernetes resources ──────────────────────────────────────────────────────

ROOT="$(cd "$(dirname "$(realpath "$BASH_SOURCE")")/.." && pwd)"

log "Deleting Kubernetes resources..."
kubectl delete --ignore-not-found \
  -f "$ROOT/k8s/grafana.yaml" \
  -f "$ROOT/k8s/prometheus.yaml" \
  -f "$ROOT/k8s/stats-service.yaml" \
  -f "$ROOT/k8s/player-service.yaml" \
  -f "$ROOT/k8s/party-service.yaml" \
  -f "$ROOT/k8s/eureka.yaml"

log "Done."