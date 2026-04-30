#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[setup]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}  $*"; }
die()  { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ── Prerequisites ────────────────────────────────────────────────────────────

command -v docker  >/dev/null 2>&1 || die "docker is required but not installed"
command -v kubectl >/dev/null 2>&1 || die "kubectl is required but not installed"

# ── Step 1: Maven build ───────────────────────────────────────────────────────

SERVICES=(discovery-service party-service player-service stats-service)

log "Building Maven packages..."
for svc in "${SERVICES[@]}"; do
    log "  → $svc"
    (cd "$ROOT/$svc" && ./mvnw package -DskipTests -q)
done

# ── Step 2: Docker images ─────────────────────────────────────────────────────

log "Building Docker images..."
for svc in "${SERVICES[@]}"; do
    log "  → $svc:latest"
    docker build -t "$svc:latest" "$ROOT/$svc" --quiet
done

# ── Step 3: Load images into cluster ─────────────────────────────────────────
# Supports minikube and kind; skips if neither is detected.

if command -v minikube >/dev/null 2>&1 && minikube status --format='{{.Host}}' 2>/dev/null | grep -q Running; then
    log "Minikube detected — loading images..."
    for svc in "${SERVICES[@]}"; do
        minikube image load "$svc:latest"
    done
elif command -v kind >/dev/null 2>&1; then
    CLUSTER=$(kind get clusters 2>/dev/null | head -1)
    if [ -n "$CLUSTER" ]; then
        log "kind cluster '$CLUSTER' detected — loading images..."
        for svc in "${SERVICES[@]}"; do
            kind load docker-image "$svc:latest" --name "$CLUSTER"
        done
    else
        warn "kind found but no cluster running — skipping image load"
    fi
else
    warn "No minikube/kind detected — assuming images are already accessible (e.g. Docker Desktop)"
fi

# ── Step 4: Kubernetes deploy ─────────────────────────────────────────────────

log "Applying Kubernetes manifests..."

kubectl apply --validate=false -f "$ROOT/k8s/eureka.yaml"

log "Waiting for eureka-server to be ready..."
kubectl rollout status deployment/eureka-server --timeout=120s

kubectl apply --validate=false -f "$ROOT/k8s/party-service.yaml"
kubectl apply --validate=false -f "$ROOT/k8s/player-service.yaml"
kubectl apply --validate=false -f "$ROOT/k8s/stats-service.yaml"
kubectl apply --validate=false -f "$ROOT/k8s/prometheus.yaml"
kubectl apply --validate=false -f "$ROOT/k8s/grafana.yaml"

log "Waiting for all deployments to be ready..."
for deploy in party-service player-service stats-service prometheus grafana; do
    kubectl rollout status deployment/"$deploy" --timeout=120s
done

# ── Step 5: Summary ───────────────────────────────────────────────────────────

echo ""
log "All services deployed successfully."
echo ""
echo "  Eureka      →  kubectl port-forward svc/eureka-server 8761:8761"
echo "  Party       →  kubectl port-forward svc/party-service 8081:8081"
echo "  Player      →  kubectl port-forward svc/player-service 8082:8082"
echo "  Stats       →  kubectl port-forward svc/stats-service 8083:8083"
echo "  Prometheus  →  kubectl port-forward svc/prometheus 9090:9090"
echo "  Grafana     →  kubectl port-forward svc/grafana 3000:3000  (admin/admin)"
echo ""