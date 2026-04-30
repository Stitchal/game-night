# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**GameNight** is a microservices platform for organizing game nights. See `README.md` for the full exam specification.

**Stack:** Java 17, Spring Boot 4.0.6, Spring Cloud 2025.1.1, Maven.

**Services and ports:**

| Service            | Port | Role                                         |
|--------------------|------|----------------------------------------------|
| `discovery-service`| 8761 | Eureka Server — service registry             |
| `party-service`    | 8081 | CRUD for game night parties                  |
| `player-service`   | 8082 | Players registered to a party                |
| `stats-service`    | 8083 | Aggregates party + player data, Resilience4j |

Start order: **discovery-service first**, then the others.

---

## Commands

Each service is an independent Maven module. Run all commands from inside the service directory (e.g. `cd party-service`).

```bash
# Build and run
./mvnw spring-boot:run

# Compile only
./mvnw compile

# Run tests
./mvnw test

# Run a single test class
./mvnw test -Dtest=PartyServiceApplicationTests

# Package (skip tests)
./mvnw package -DskipTests

# Build Docker image (when Dockerfile exists)
docker build -t party-service .
```

---

## Microservice Architecture

Every business microservice (`party-service`, `player-service`, `stats-service`) follows the same 4-layer package structure under `unica.ds4h.rosset.<servicename>`:

```
model/        — JPA @Entity, plain getters/setters, no business logic
repository/   — JpaRepository<Entity, Long>, no custom queries unless needed
service/      — @Service, holds all business logic, injected via constructor
controller/   — @RestController, delegates entirely to service, no logic here
```

**Dependency injection:** always constructor injection (no `@Autowired` on fields).

**Persistence:** H2 in-memory (`jdbc:h2:mem:<dbname>`, `ddl-auto=create-drop`) for all services. The H2 console is enabled at `/h2-console`.

**Service discovery:** all business services register with Eureka via:
```properties
eureka.client.service-url.defaultZone=http://localhost:8761/eureka
```
The discovery-service itself sets `register-with-eureka=false` and `fetch-registry=false`.

**Monitoring:** every service exposes `/actuator/health` and `/actuator/prometheus`. Add these to any new service:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```
```properties
management.endpoints.web.exposure.include=health,prometheus
management.endpoint.prometheus.access=unrestricted
```

---

## Resilience4j (stats-service only)

`stats-service` calls `party-service` and `player-service` via `RestTemplate` or `WebClient` resolved through Eureka. Wrap those calls with:

```java
@CircuitBreaker(name = "playerService", fallbackMethod = "fallbackStats")
@Retry(name = "playerService")
public PartyStats getStats(Long partyId) { ... }
```

Fallback must return `playersCount: -1` when `player-service` is unavailable.

---

## Spring Boot 4.x Notes

- Use `jakarta.*` imports (not `javax.*`) for JPA, validation, servlet APIs.
- `management.endpoint.prometheus.access=unrestricted` replaces the deprecated `enabled=true` flag from Boot 3.x.

---

## Kubernetes

Manifests go in `k8s/`, one file per service (`party-service.yaml`, etc.), each containing a `Deployment` + `Service`. Prometheus config goes in `prometheus/prometheus.yml`. Architecture diagram goes in `docs/architecture.png`.