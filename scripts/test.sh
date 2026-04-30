#!/usr/bin/env bash

ROOT="$(cd "$(dirname "$(realpath "$BASH_SOURCE")")/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

log()     { echo -e "${BLUE}[test]${NC}    $*"; }
ok()      { echo -e "${GREEN}[PASS]${NC}    $*"; PASS=$((PASS + 1)); }
fail()    { echo -e "${RED}[FAIL]${NC}    $*"; FAIL=$((FAIL + 1)); }
warn()    { echo -e "${YELLOW}[warn]${NC}    $*"; }
section() { echo ""; echo -e "${BLUE}━━━ $* ━━━${NC}"; }

http_get() {
    curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$1" 2>/dev/null
}

http_body() {
    curl -s --connect-timeout 5 "$1" 2>/dev/null
}

# Wait until a local port responds with any HTTP code (not 000), up to $2s
wait_http() {
    local url=$1
    local timeout=${2:-60}
    local i=0
    while [ "$i" -lt "$timeout" ]; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$url" 2>/dev/null)
        if [ "$code" != "000" ]; then
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    return 1
}

# ── Step 1: Setup if needed ───────────────────────────────────────────────────

section "Setup"

PODS_RUNNING=$(kubectl get pods 2>/dev/null | grep -c "Running" || true)
if [ "$PODS_RUNNING" -lt 6 ]; then
    log "Cluster not ready ($PODS_RUNNING/6 pods running) — running setup..."
    bash "$ROOT/scripts/setup.sh"
else
    log "Cluster already up ($PODS_RUNNING pods running) — skipping setup."
fi

# ── Step 2: Kubernetes — all pods Running ─────────────────────────────────────

section "Kubernetes — pods"

for svc in eureka-server party-service player-service stats-service prometheus grafana; do
    STATUS=$(kubectl get pods -l "app=$svc" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    if [ "$STATUS" = "Running" ]; then
        ok "$svc pod is Running"
    else
        fail "$svc pod is not Running (status: ${STATUS:-not found})"
    fi
done

# ── Step 3: Port-forwards ─────────────────────────────────────────────────────

section "Port forwards"

SVC_LIST="eureka-server:8761 party-service:8081 player-service:8082 stats-service:8083 prometheus:9090 grafana:3000"

for entry in $SVC_LIST; do
    svc="${entry%%:*}"
    port="${entry##*:}"
    if ! lsof -i ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        warn "port-forward $svc:$port not active — starting it..."
        nohup kubectl port-forward "svc/$svc" "$port:$port" >"/tmp/pf-${svc}.log" 2>&1 &
    fi
done

# Wait for each service to respond sequentially
HEALTH_LIST="eureka-server:8761:/actuator/health party-service:8081:/actuator/health player-service:8082:/actuator/health stats-service:8083:/actuator/health prometheus:9090:/-/ready grafana:3000:/api/health"

log "Waiting for services to be ready on their ports..."
for entry in $HEALTH_LIST; do
    svc=$(echo "$entry" | cut -d: -f1)
    port=$(echo "$entry" | cut -d: -f2)
    path=$(echo "$entry" | cut -d: -f3)
    url="http://localhost:${port}${path}"
    if wait_http "$url" 120; then
        ok "port reachable ($svc)"
    else
        fail "port not reachable after 120s ($svc)"
    fi
done

# ── Step 4: Eureka — services registered ─────────────────────────────────────

section "Eureka — service registration"

EUREKA_APPS=$(http_body "http://localhost:8761/eureka/apps")

for svc in PARTY-SERVICE PLAYER-SERVICE STATS-SERVICE; do
    if echo "$EUREKA_APPS" | grep -qi "$svc"; then
        ok "$svc registered in Eureka"
    else
        fail "$svc NOT registered in Eureka"
    fi
done

# ── Step 5: Party Service endpoints ──────────────────────────────────────────

section "Party Service — endpoints"

PARTY_RESPONSE=$(curl -s -X POST http://localhost:8081/parties \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Night","gameType":"POKER","date":"2026-06-15"}')
PARTY_ID=$(echo "$PARTY_RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)

if [ -n "$PARTY_ID" ]; then
    ok "POST /parties → created party id=$PARTY_ID"
else
    fail "POST /parties → no id returned (response: $PARTY_RESPONSE)"
fi

CODE=$(http_get "http://localhost:8081/parties")
if [ "$CODE" = "200" ]; then
    ok "GET /parties → 200"
else
    fail "GET /parties → $CODE"
fi

if [ -n "$PARTY_ID" ]; then
    CODE=$(http_get "http://localhost:8081/parties/$PARTY_ID")
    if [ "$CODE" = "200" ]; then
        ok "GET /parties/$PARTY_ID → 200"
    else
        fail "GET /parties/$PARTY_ID → $CODE"
    fi
fi

# ── Step 6: Player Service endpoints ─────────────────────────────────────────

section "Player Service — endpoints"

if [ -n "$PARTY_ID" ]; then
    for name in Alice Bob Charlie; do
        CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8082/players \
            -H "Content-Type: application/json" \
            -d "{\"partyId\":$PARTY_ID,\"playerName\":\"$name\"}")
        if [ "$CODE" = "200" ]; then
            ok "POST /players ($name) → 200"
        else
            fail "POST /players ($name) → $CODE"
        fi
    done

    PLAYERS=$(http_body "http://localhost:8082/players/party/$PARTY_ID")
    COUNT=$(echo "$PLAYERS" | grep -o '"id"' | wc -l | tr -d ' ')
    if [ "$COUNT" -eq 3 ]; then
        ok "GET /players/party/$PARTY_ID → $COUNT players"
    else
        fail "GET /players/party/$PARTY_ID → expected 3, got $COUNT"
    fi
fi

# ── Step 7: Stats Service — nominal ──────────────────────────────────────────

section "Stats Service — nominal call"

if [ -n "$PARTY_ID" ]; then
    STATS=$(http_body "http://localhost:8083/stats/$PARTY_ID")
    PLAYERS_COUNT=$(echo "$STATS" | grep -o '"playersCount":[0-9]*' | grep -o '[0-9]*')
    PARTY_NAME=$(echo "$STATS" | grep -o '"partyName":"[^"]*"' | cut -d'"' -f4)

    if [ "$PLAYERS_COUNT" = "3" ]; then
        ok "GET /stats/$PARTY_ID → playersCount=$PLAYERS_COUNT"
    else
        fail "GET /stats/$PARTY_ID → expected playersCount=3, got '${PLAYERS_COUNT}' (body: $STATS)"
    fi

    if [ "$PARTY_NAME" = "Test Night" ]; then
        ok "GET /stats/$PARTY_ID → partyName=$PARTY_NAME"
    else
        fail "GET /stats/$PARTY_ID → expected partyName='Test Night', got '$PARTY_NAME'"
    fi
fi

# ── Step 8: Stats Service — Resilience4j fallback ────────────────────────────

section "Stats Service — Resilience4j fallback"

log "Scaling down player-service to 0..."
kubectl scale deployment player-service --replicas=0 >/dev/null
pkill -f 'port-forward svc/player-service' 2>/dev/null || true
log "Waiting for Eureka to deregister player-service (~40s)..."
sleep 40

# Ensure stats port-forward is alive before the fallback call
pkill -f 'port-forward svc/stats-service' 2>/dev/null || true
nohup kubectl port-forward svc/stats-service 8083:8083 >/tmp/pf-stats-service.log 2>&1 &
sleep 3

if [ -n "$PARTY_ID" ]; then
    STATS=$(http_body "http://localhost:8083/stats/$PARTY_ID")
    PLAYERS_COUNT=$(echo "$STATS" | grep -o '"playersCount":-\?[0-9]*' | grep -o -- '-\?[0-9]*')
    if [ "$PLAYERS_COUNT" = "-1" ]; then
        ok "Fallback → playersCount=-1 when player-service is down"
    else
        fail "Fallback → expected playersCount=-1, got '$PLAYERS_COUNT' (body: $STATS)"
    fi
fi

log "Restoring player-service..."
kubectl scale deployment player-service --replicas=1 >/dev/null
kubectl rollout status deployment/player-service --timeout=120s >/dev/null
nohup kubectl port-forward svc/player-service 8082:8082 >/tmp/pf-player-service.log 2>&1 &
# Wait long enough for player-service to register in Eureka before prometheus test
log "Waiting for player-service to register in Eureka (~30s)..."
sleep 30

# ── Step 9: Prometheus ────────────────────────────────────────────────────────

section "Prometheus — metrics"

for entry in "party-service:8081" "player-service:8082" "stats-service:8083"; do
    svc="${entry%%:*}"
    port="${entry##*:}"
    CODE=$(http_get "http://localhost:$port/actuator/prometheus")
    if [ "$CODE" = "200" ]; then
        ok "$svc /actuator/prometheus → 200"
    else
        fail "$svc /actuator/prometheus → $CODE"
    fi
done

sleep 5
PROM_TARGETS=$(http_body "http://localhost:9090/api/v1/targets")
for svc in party-service player-service stats-service; do
    if echo "$PROM_TARGETS" | grep -q "\"$svc\""; then
        ok "Prometheus target '$svc' found"
    else
        fail "Prometheus target '$svc' not found"
    fi
done

# ── Step 10: Grafana ──────────────────────────────────────────────────────────

section "Grafana — dashboard"

GRAFANA_HEALTH=$(http_body "http://localhost:3000/api/health")
if echo "$GRAFANA_HEALTH" | grep -q "ok\|database"; then
    ok "Grafana API healthy"
else
    fail "Grafana API not healthy (response: $GRAFANA_HEALTH)"
fi

DASHBOARDS=$(curl -s -u admin:admin "http://localhost:3000/api/search?type=dash-db" 2>/dev/null)
if echo "$DASHBOARDS" | grep -qi "GameNight\|gamenight"; then
    ok "Grafana dashboard 'GameNight Overview' provisioned"
else
    fail "Grafana dashboard 'GameNight Overview' not found"
fi

DATASOURCES=$(curl -s -u admin:admin "http://localhost:3000/api/datasources" 2>/dev/null)
if echo "$DATASOURCES" | grep -qi "prometheus"; then
    ok "Grafana datasource Prometheus configured"
else
    fail "Grafana datasource Prometheus not found"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Results: ${GREEN}$PASS passed${NC}  ${RED}$FAIL failed${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Eureka     →  ${BLUE}http://localhost:8761${NC}"
echo -e "  Party      →  ${BLUE}http://localhost:8081${NC}"
echo -e "  Player     →  ${BLUE}http://localhost:8082${NC}"
echo -e "  Stats      →  ${BLUE}http://localhost:8083${NC}"
echo -e "  Prometheus →  ${BLUE}http://localhost:9090${NC}"
echo -e "  Grafana    →  ${BLUE}http://localhost:3000${NC}  (admin/admin)"
echo ""
echo -e "  Pour arrêter le projet : ${YELLOW}./scripts/teardown.sh${NC}"
echo ""

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
