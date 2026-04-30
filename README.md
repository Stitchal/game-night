# Examen Technique M2  – 3h  
## Développement, Monitoring et Déploiement d’une Application Microservices avec Spring Boot, Eureka, Prometheus, Grafana et Kubernetes

---

# Contexte

Vous devez concevoir une plateforme backend nommée **GameNight**, destinée à organiser des soirées de jeux entre amis.

Les utilisateurs peuvent :

- créer des soirées de jeux,
- inscrire des participants,
- consulter les statistiques d’une soirée.

L’objectif de cet examen est de mettre en place une architecture **microservices résiliente**, **monitorée**, et **déployable sur Kubernetes**.

---

# Objectifs

Vous devez démontrer votre maîtrise des concepts suivants :

- architecture microservices avec **Spring Boot**
- **service discovery** avec **Eureka**
- **résilience applicative** avec **Resilience4j**
- **monitoring** avec **Prometheus + Grafana**
- **déploiement Kubernetes**
- organisation Git propre avec **commits réguliers**

---

# Durée

**3 heures**

---

# Livrable attendu

Un dépôt **GitHub** contenant :

- les microservices développés,
- les fichiers de configuration,
- les manifests Kubernetes,
- un `README.md` expliquant :
  - comment lancer les services,
  - comment accéder aux métriques,
  - comment déployer sur Kubernetes.

Le dépôt doit contenir des **commits réguliers**, reflétant les étapes de développement.

Exemple :

```bash
git commit -m "Init project structure"
git commit -m "Add Eureka server"
git commit -m "Implement party service"
git commit -m "Add monitoring with Prometheus"
git commit -m "Deploy services on Kubernetes"
```

---

# Sujet : Plateforme **GameNight**

Vous devez développer **3 microservices** :

---

# 1. Architecture attendue

## 1.1 Eureka Server

Un serveur Eureka permettant l’enregistrement des microservices.

Port conseillé :

```yaml
8761
```

---

## 1.2 Party Service

Gestion des soirées :

- créer une soirée
- consulter les soirées

Une soirée contient :

- `id`
- `name`
- `gameType`
- `date`

Exemple :

```json
{
  "id": 1,
  "name": "Poker Night Friday",
  "gameType": "POKER",
  "date": "2026-06-15"
}
```

Endpoints :

```http
POST /parties
GET /parties
GET /parties/{id}
```

---

## 1.3 Player Service

Gestion des participants :

- inscrire un joueur à une soirée
- lister les joueurs d’une soirée

Un participant contient :

- `id`
- `partyId`
- `playerName`

Exemple :

```json
{
  "id": 1,
  "partyId": 2,
  "playerName": "Alice"
}
```

Endpoints :

```http
POST /players
GET /players/party/{partyId}
```

---

## 1.4 Stats Service

Ce service interroge :

- `Party Service`
- `Player Service`

et retourne les statistiques d’une soirée :

- informations de la soirée
- nombre de participants

Exemple :

```json
{
  "partyName": "Poker Night Friday",
  "gameType": "POKER",
  "playersCount": 5
}
```

Endpoint :

```http
GET /stats/{partyId}
```

---

# 2. Résilience applicative

Le **Stats Service** doit être résilient lorsqu’il appelle les autres services.

Utilisez **Resilience4j** :

- `CircuitBreaker`
- `Retry`

Si `Player Service` est indisponible, retourner une réponse fallback :

```json
{
  "partyName": "Poker Night Friday",
  "gameType": "POKER",
  "playersCount": -1
}
```

Exemple attendu :

```java
@CircuitBreaker(name = "playerService", fallbackMethod = "fallbackStats")
@Retry(name = "playerService")
public PartyStats getStats(Long partyId) {
    ...
}
```

---

# 3. Monitoring

Chaque microservice doit exposer ses métriques via :

```http
/actuator/prometheus
```

Ajoutez :

- Spring Boot Actuator
- Micrometer Prometheus

Dépendances attendues :

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

Configuration :

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,prometheus
```

---

# 4. Prometheus

Configurer Prometheus pour scraper les métriques des 3 microservices.

Exemple :

```yaml
scrape_configs:
  - job_name: 'party-service'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['party-service:8081']
```

Jobs attendus :

- `party-service`
- `player-service`
- `stats-service`

---

# 5. Grafana

Créer un dashboard affichant au minimum :

- nombre de requêtes HTTP
- temps de réponse
- état de santé des services

Exemple de métrique :

```promql
http_server_requests_seconds_count
```

---

# 6. Déploiement Kubernetes

Déployer :

- Eureka Server
- Party Service
- Player Service
- Stats Service
- Prometheus
- Grafana

Chaque microservice doit avoir :

- un `Deployment`
- un `Service`

Exemple :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: party-service
spec:
  replicas: 1
```

---

# 7. Structure minimale attendue

```bash
gamenight/
│
├── eureka-server/
├── party-service/
├── player-service/
├── stats-service/
├── k8s/
│   ├── party-service.yaml
│   ├── player-service.yaml
│   ├── stats-service.yaml
│   ├── eureka.yaml
│   ├── prometheus.yaml
│   └── grafana.yaml
│
├── prometheus/
│   └── prometheus.yml
│
└── README.md
```

---

# 8. Squelettes de configuration fournis

## 8.1 Eureka Client

```yaml
eureka:
  client:
    service-url:
      defaultZone: http://eureka-server:8761/eureka
```

## 8.2 Nom du service

```yaml
spring:
  application:
    name: party-service
```

## 8.3 Dépendance Eureka Client

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

---

# 9. Critères d’évaluation

## 9.1 Fonctionnalités (8 points)

- Party Service opérationnel
- Player Service opérationnel
- Stats Service opérationnel

## 9.2 Résilience (4 points)

- Circuit breaker
- Retry
- fallback fonctionnel

## 9.3 Monitoring (4 points)

- endpoints Prometheus
- configuration Prometheus
- dashboard Grafana

## 9.4 Kubernetes (3 points)

- manifests corrects
- services accessibles

## 9.5 Qualité Git et organisation (1 point)

- structure claire
- commits réguliers

---

# Bonus (+2 points)

Ajouter :

- un **API Gateway**
- ou un **HorizontalPodAutoscaler**
- ou des métriques personnalisées

---

# Conseils

Travaillez par étapes :

1. créer Eureka  
2. créer les microservices  
3. ajouter la résilience  
4. ajouter Prometheus  
5. déployer sur Kubernetes  

Commitez régulièrement :

```bash
git add .
git commit -m "Step X completed"
```

---

# Résultat attendu

À la fin :

- les microservices sont enregistrés dans Eureka,
- `Stats Service` appelle les autres services,
- les métriques sont visibles dans Prometheus,
- les dashboards sont visibles dans Grafana,
- l’ensemble est déployé sur Kubernetes.

---


# Architechture: Modélisation de l’architecture logicielle

Avant de finaliser l’implémentation, vous "devez" produire un **schéma d’architecture logicielle** représentant les composants de la solution et leurs interactions.

Ce schéma peut être réalisé avec l’outil de votre choix :

- **draw.io**
- **Lucidchart**
- **Excalidraw**
- ou tout autre outil équivalent

Le diagramme devra être exporté et ajouté au dépôt GitHub :

- soit en image (`architecture.png`)
- soit en PDF (`architecture.pdf`)

Le fichier devra être placé dans un dossier :

```bash
docs/architecture.png
```

---

## Objectif du schéma

Le diagramme doit permettre de visualiser :

- les microservices développés,
- les communications entre services,
- les composants de monitoring,
- l’infrastructure Kubernetes.

---

## Éléments obligatoires à représenter

Votre schéma doit inclure au minimum :

### Services applicatifs

- `party-service`
- `player-service`
- `stats-service`

### Infrastructure

- `eureka-server`
- `prometheus`
- `grafana`

### Orchestration

- `kubernetes`

---

## Relations attendues

Le schéma doit montrer :

- que les microservices s’enregistrent dans **Eureka**
- que **Stats Service** appelle **Party Service** et **Player Service**
- que **Prometheus** collecte les métriques des microservices
- que **Grafana** exploite les données de **Prometheus**
- que tous les composants sont déployés sur **Kubernetes**

---

## Exemple simplifié attendu

```text
                    +-------------------+
                    |      Grafana      |
                    +---------+---------+
                              |
                              v
                    +-------------------+
                    |    Prometheus     |
                    +----+----+----+----+
                         |    |    |
                         v    v    v
                  +------+ +------+ +------+
                  |Party | |Player| |Stats |
                  |Service| |Service| |Service|
                  +---+---+ +---+---+ +---+---+
                      |         |         |
                      +---------+---------+
                                |
                                v
                         +-------------+
                         |   Eureka    |
                         +-------------+

             Tous les composants sont déployés sur Kubernetes
```

---
