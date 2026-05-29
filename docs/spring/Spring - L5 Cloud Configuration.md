---
layout: default
title: "Spring - L5 Cloud Configuration"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 15
permalink: /spring/l5-cloud-configuration/
---

# Spring - L5 Cloud Configuration

---

# Spring Cloud Config and Service Discovery

---
id: SPR-027
title: Spring Cloud Config and Service Discovery
category: Spring
difficulty: ★★★
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #spring-cloud, #config-server, #eureka, #service-discovery, #kubernetes
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — configuration management and service discovery
are fundamental microservices infrastructure concerns. Senior interviews
distinguish between classical approaches (Eureka, Config Server) and Kubernetes-native
approaches.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Cloud Config Server centralizes application configuration across
> all microservices, reading from Git/Vault and serving to services at startup.
> Service discovery (Eureka) allows services to find each other by name instead
> of IP. In Kubernetes, both are replaced: ConfigMaps replace Config Server,
> Kubernetes Service DNS replaces Eureka. Spring Cloud Kubernetes DiscoveryClient
> bridges the two worlds.

**3 minutes (Senior):**
> Spring Cloud Config Server solves configuration sprawl: instead of 50
> services each having their own application.properties, all configuration lives
> in a Git repo. The Config Server is a Spring Boot app that reads from Git
> and exposes configuration via REST. Clients fetch their configuration at
> startup via spring.config.import=configserver:. Properties from Config Server
> override local application.properties. @RefreshScope beans can be refreshed
> live.
>
> Eureka service discovery works through registration: each service registers
> itself at startup with its IP/port. Clients query Eureka for instances of
> a service. Spring Cloud LoadBalancer caches the instance list and does
> load-balanced HTTP calls by service name. Heartbeats maintain registration
> freshness.
>
> In Kubernetes, the native equivalents: Kubernetes Service (ClusterIP) +
> CoreDNS replace Eureka. ConfigMaps + Secrets replace Config Server for
> static config. Spring Cloud Kubernetes provides DiscoveryClient over the
> Kubernetes API and @RefreshScope triggered by ConfigMap changes. The
> recommendation: use Kubernetes-native for infrastructure, Spring Cloud for
> application-level resilience.

**Framework:** WHAT -> WHY -> HOW -> KUBERNETES COMPARISON -> PRODUCTION

*Adapting up:* Staff - GitOps with Config Server (ArgoCD watching config repo),
multi-environment Config Server with profile branching strategy, Vault dynamic
secrets integration, Spring Cloud Kubernetes reconciliation vs polling.

*Adapting down:* Mid - "Config Server is like a central settings file server.
All services ask it for their settings at startup instead of having settings
files bundled with each service."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring Cloud Config Server for configuration
management and service discovery for routing between services."

**(2) First principles:** "With 50 microservices each having their own config files:
50 places to update a database URL, 50 places to change a feature flag. Centralized
config solves this by having one source of truth. Service discovery solves the
problem of finding services when their IP addresses change."

**(3) Bridge:** "Config Server is the company HR policy manual. Each department
(service) doesn't maintain its own copy - they all reference the central manual.
When policy changes, everyone gets the update. Service discovery is the company
phone directory: you look up 'accounting department' not the person's direct
phone number, so it still works when people move."

---

### 📘 Concept Explanation

**What it is:**
Spring Cloud Config Server provides a centralized configuration service for
distributed systems. Eureka provides a service registry for service discovery.
Together they solve two fundamental microservices challenges: where is the
configuration and where are the services?

**The problem it solves:**
Managing configuration across 50+ microservices is operationally complex. Each
service has environment-specific configuration. Updating a single shared setting
requires touching all services. Service IPs change with deployments, auto-scaling,
and failures. Hard-coded IPs break at the first deployment. Dynamic discovery
enables location transparency.

**How it works:**

```
Spring Cloud Config Server architecture:

       Git Repository
         /application.yml           (all services)
         /application-prod.yml      (all, prod profile)
         /order-service.yml         (order service only)
         /order-service-prod.yml    (order, prod)
               |
               | (git clone/pull)
               v
       Config Server (Spring Boot)
         Port: 8888
         GET /order-service/prod/{label}
             -> merges files in order:
                1. application.yml
                2. application-prod.yml
                3. order-service.yml
                4. order-service-prod.yml
             -> returns merged properties
               |
               | (HTTP, on startup)
               v
       Microservice (Config Client)
         Fetches config before context refresh
         (bootstrap context or spring.config.import)
         Config Server properties override local

Config Server setup:
  @SpringBootApplication
  @EnableConfigServer  // turns it into a Config Server
  public class ConfigServerApp { }

  spring.cloud.config.server.git.uri=
    https://github.com/org/config-repo

Config Client setup:
  spring.config.import=configserver:http://config:8888
  spring.application.name=order-service
  spring.profiles.active=prod

Eureka service discovery architecture:

       Eureka Server
         (service registry)
         Stores: {serviceName -> [ip1:port1, ip2:port2]}
               |
  register     |     register
  (on startup) |     (on startup)
               v
  order-service          inventory-service
  ip: 10.0.1.5:8080      ip: 10.0.1.6:8080
               |
               | wants to call inventory-service
               | 1. Query Eureka: "inventory-service"?
               | 2. Gets back: [10.0.1.6:8080]
               | 3. Load balance, make HTTP call
               v
  Spring Cloud LoadBalancer
    Caches instance list (30s refresh)
    Round-robin among live instances

Eureka registration lifecycle:
  On startup:
    POST /eureka/apps/{APP_NAME}
    Registers: IP, port, health URL, instance ID
  Heartbeat:
    PUT /eureka/apps/{APP_NAME}/{instanceId}
    Every 30 seconds (default)
  On deregistration:
    DELETE /eureka/apps/{APP_NAME}/{instanceId}
    (on graceful shutdown)
  Eviction:
    Eureka evicts instances that miss 3 heartbeats
    (90 second TTL by default)

Kubernetes comparison:
  Config Server -> ConfigMaps + Secrets
    kubectl apply -f configmap.yaml
    Spring Cloud Kubernetes Config DiscoveryClient:
      reads ConfigMaps/Secrets as property sources
      @RefreshScope + ConfigMap watch for live updates

  Eureka -> Kubernetes Service + CoreDNS
    Service: inventory-service.default.svc.cluster.local
    Spring Cloud Kubernetes DiscoveryClient:
      uses Kubernetes API to list pods for service
    Spring Cloud LoadBalancer: client-side LB
      or let Kubernetes kube-proxy do it
```

**The key insight:**
The choice between Eureka/Config Server vs Kubernetes-native is an infrastructure
philosophy choice, not a technical limitation. Eureka and Config Server are
self-contained Spring applications that work anywhere. Kubernetes-native approaches
leverage existing infrastructure (you're already in K8s). Hybrid: deploy on K8s
but use Config Server for shared config that changes at runtime (vs ConfigMaps
which require pod restarts).

**When to use Spring Cloud Config Server:**
- Non-Kubernetes environments (bare metal, VMs)
- Need live config refresh without pod restarts
- Config that changes frequently (feature flags)
- Config shared across different environments/cloud providers

**When to use Kubernetes ConfigMaps:**
- All services in Kubernetes
- Static config that changes with deployments
- Simpler operations (no extra service to maintain)

---

### 💻 Code Example

```java
// Config Server application
@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(
            ConfigServerApplication.class, args);
    }
}
```

```yaml
# Config Server application.yml
server:
  port: 8888

spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/myorg/config-repo
          default-label: main
          search-paths: '{application}'
          # Refresh interval (pull from Git)
          refresh-rate: 30
          # Clone on start (fail fast if Git unreachable)
          clone-on-start: true
        # Encryption support
        encrypt:
          enabled: true  # encrypts values with {cipher}

# Secure Config Server access
spring:
  security:
    user:
      name: configserver
      password: ${CONFIG_SERVER_PASSWORD}
```

> **Code walkthrough:** @EnableConfigServer is all that's needed to turn a Spring
> Boot application into a Config Server. The git.uri points to the config repository.
> search-paths: '{application}' means Config Server looks in a subfolder named
> after the application (order-service folder for order-service app).
> clone-on-start: true fails fast at Config Server startup if Git is unreachable,
> rather than failing at the first client request. Encryption support allows
> storing sensitive values as {cipher}xxx in Git (encrypted).

```java
// Config Client: consuming Config Server
// bootstrap.properties (legacy, Spring Boot < 2.4)
// OR spring.config.import= (Spring Boot 2.4+)

// application.properties
spring.application.name=order-service
spring.profiles.active=prod
spring.config.import=\
  configserver:http://config-server:8888

// Credentials for secured Config Server
spring.cloud.config.username=configserver
spring.cloud.config.password=${CONFIG_SERVER_PASSWORD}
```

```java
// @RefreshScope bean with live config update
@RestController
@RefreshScope  // bean recreated on /actuator/refresh
public class FeatureFlagController {

    // Value injected from Config Server
    @Value("${features.new-checkout.enabled:false}")
    private boolean newCheckoutEnabled;

    @GetMapping("/api/checkout")
    public ResponseEntity<?> checkout(
            @RequestBody CheckoutRequest req) {
        if (newCheckoutEnabled) {
            return newCheckoutService.process(req);
        }
        return legacyCheckoutService.process(req);
    }
}

// Trigger refresh (update config in Git, then):
// POST /actuator/refresh
// -> ContextRefreshEvent published
// -> @RefreshScope beans recreated
// -> newCheckoutEnabled re-read from Config Server

// Spring Cloud Bus: broadcast to all instances
// POST /actuator/busrefresh
// -> All instances receive and refresh
```

> **Code walkthrough:** @RefreshScope creates a CGLIB proxy for the bean.
> The proxy delegates to the real bean. When /actuator/refresh is called,
> the real bean is destroyed and recreated with fresh @Value injections.
> The proxy continues pointing to the new bean. This is transparent to callers.
> Important caveat: the new bean's @PostConstruct runs on the new instance.
> If @PostConstruct does I/O (DB queries, file reads), it runs again on each
> refresh. @RefreshScope is a custom scope (not singleton/prototype) - Spring's
> scope SPI in action.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Cloud Config Server is a separate Spring Boot application that serves
> configuration to all your microservices. You put config in a Git repo, point
> the Config Server at it, and all your services get their config from the Config
> Server at startup. This means you only have to change config in one place.
> Eureka is a service registry - services register themselves and can find other
> services by name instead of using hard-coded IPs.

*Push deeper:* What happens if the Config Server is unavailable when a service
starts? (Service fails to start unless spring.cloud.config.fail-fast=false)

---

**Senior / Staff (5+ years):**
> Config Server and Eureka are the classical Spring Cloud approach. Key production
> concerns: Config Server HA (multiple instances, same Git backend), Eureka replication
> (peer-to-peer cluster for availability), and bootstrap context timing (Config
> Server must be reachable before the service's ApplicationContext starts).
>
> In Kubernetes: both are usually replaced. ConfigMaps serve static config
> (reloaded on pod restart). For live updates without restarts, Spring Cloud
> Kubernetes Config Watcher watches ConfigMap changes and triggers @RefreshScope.
> Kubernetes Service + CoreDNS replaces Eureka entirely - no registration needed,
> pod readiness probes handle health. Recommendation: use Config Server only when
> Kubernetes ConfigMaps are insufficient (frequent config changes, multi-cloud,
> Vault-backed secrets).

*Push deeper:* Spring Cloud Kubernetes with fabric8io or kubernetes-client
reads ConfigMaps as property sources using the Kubernetes API. The watch mechanism
uses K8s informers (event-based, not polling). When a ConfigMap changes,
the informer callback triggers in milliseconds, not minutes - faster than
Config Server polling.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Config Server is required for microservices."**
Config Server is optional. Kubernetes ConfigMaps, HashiCorp Vault, AWS Parameter
Store, and Azure App Configuration all serve the same purpose. Config Server
is the Spring-native option. Teams already using Kubernetes don't gain much
from Config Server unless they need runtime refresh or Vault-backed secrets.

**Misconception 2: "Eureka is required for service discovery in Spring Cloud."**
Spring Cloud LoadBalancer works with any ServiceInstanceListSupplier backend:
Eureka, Consul, Zookeeper, Kubernetes API, or a static list. @LoadBalancerClient
is the extension point. In Kubernetes, spring-cloud-starter-kubernetes-client-loadbalancer
provides Kubernetes-native discovery. You can remove Eureka without removing
client-side load balancing.

**Misconception 3: "/actuator/refresh updates all running instances."**
/actuator/refresh updates only the instance that received the request.
To refresh all instances: use Spring Cloud Bus (broadcast via Kafka/RabbitMQ),
or call /actuator/refresh on every instance separately (ops burden).
Spring Cloud Bus /actuator/busrefresh broadcasts the refresh to all subscribers.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Config Server unavailable at service startup**
Symptom: Service fails to start with "Could not locate PropertySource: Config
Server URL could not be reached" (if fail-fast=true).
Cause: Config Server down, wrong URL, network issue.
Options:
- spring.cloud.config.fail-fast=false: service starts with local defaults
  (risk: running with wrong config)
- spring.cloud.config.retry.*: retry with backoff (adds startup delay)
- Kubernetes: use readinessProbe to prevent traffic until Config Server available

**Failure 2: Stale service discovery (calling dead instances)**
Symptom: Intermittent failures with connection refused on a service that is up.
Cause: Eureka cache on client side has stale entries (recently dead instance
still in cache, recently started instance not yet in cache).
Default cache TTL: 30 seconds. During this window, stale routing can occur.
Fix: Add retry to Feign client for connection-level failures. The circuit breaker
handles sustained failures; retry handles transient stale-cache issues.

---

### 🎯 Interview Deep-Dive

**Timing:** Hard ★★★ - 12 questions.

---

#### Q1 - How does Spring Cloud Config Server serve properties to clients?

Config Server exposes a REST API:
```
GET /{application}/{profiles}/{label}
GET /{application}-{profiles}.yml
GET /{application}-{profiles}.properties
```

For order-service with prod profile on main branch:
```
GET /order-service/prod/main
```

Config Server reads (in order, lowest to highest priority):
1. application.yml (shared, all services)
2. application-prod.yml (shared, prod profile)
3. order-service.yml (service-specific)
4. order-service-prod.yml (service-specific, prod)

Returns merged JSON:
```json
{
  "name": "order-service",
  "profiles": ["prod"],
  "label": "main",
  "propertySources": [
    {"name": ".../order-service-prod.yml", "source": {...}},
    {"name": ".../order-service.yml", "source": {...}},
    {"name": ".../application-prod.yml", "source": {...}},
    {"name": ".../application.yml", "source": {...}}
  ]
}
```

Client merges these (first wins): order-service-prod.yml overrides order-service.yml
overrides application-prod.yml overrides application.yml.

*What separates good from great:* The merge order puts the most specific file
at highest priority. This allows shared defaults in application.yml (all services)
with service-specific and profile-specific overrides. The label (Git branch/tag)
allows per-environment branches. Some teams use: feature/my-feature branch for
testing new config without affecting main. Others use tags for release config.
Branch-per-environment is simpler to understand but harder to merge.

---

#### Q2 - How does Eureka's self-preservation mode work?

Eureka's self-preservation mode prevents mass evictions during network partitions:

Normal operation:
- Instances send heartbeats every 30 seconds
- If 3 heartbeats missed (90 seconds TTL): evict instance

Self-preservation trigger:
- Eureka server tracks expected heartbeat rate (based on registrations)
- If actual heartbeat rate < 85% of expected (15% drop): self-preservation activates
- In self-preservation: Eureka STOPS evicting instances
- Rationale: a 15% heartbeat drop is likely a network issue, not mass service failure

Self-preservation risks:
- Dead instances remain in the registry
- Clients route to dead instances
- The 30-second cache on clients means brief unavailability anyway

Self-preservation can be disabled:
```properties
# Eureka Server:
eureka.server.enable-self-preservation=false

# Eureka Client (reduce TTL from 90s to 30s):
eureka.instance.lease-expiration-duration-in-seconds=30
eureka.client.registry-fetch-interval-seconds=5
```

*What separates good from great:* Self-preservation is a trade-off: it protects
against mass false evictions during network blips, at the cost of keeping dead
instances in the registry. In Kubernetes, this is moot because Kubernetes health
checks (readiness probes) handle instance removal. For bare-metal Eureka deployments,
evaluate whether your network is reliable enough to prefer fast eviction (disable
self-preservation) over protection against false evictions.

---

#### Q3 - How does Spring Cloud Config handle encryption of sensitive properties?

Config Server supports symmetric and asymmetric encryption:

Symmetric (ENCRYPT_KEY env var):
```bash
# Generate encrypted value
POST /encrypt
Body: mysecretpassword
Response: dGhpcyBpcyBlbmNyeXB0ZWQ=...

# Store in Git config file
database.password={cipher}dGhpcyBpcyBlbmNyeXB0ZWQ=...

# Config Server decrypts before sending to client
# Client sees plain text: mysecretpassword
```

Asymmetric (RSA key pair):
```properties
# Config Server
encrypt.key-store.location=classpath:keystore.jks
encrypt.key-store.alias=configserver
encrypt.key-store.password=${KEYSTORE_PASSWORD}
encrypt.key-store.secret=${KEY_PASSWORD}
```

Client-side decryption:
```properties
# Config Server sends encrypted (not decrypt)
spring.cloud.config.server.encrypt.enabled=false
# Client decrypts with:
encrypt.key=${ENCRYPT_KEY}
```

Vault integration (better than symmetric):
```yaml
spring.cloud.config.server.vault:
  host: vault-server
  port: 8200
  kvVersion: 2
  backend: secret
```
Config Server reads from Vault. No encryption in Git - secrets never enter
the config repository at all.

*What separates good from great:* {cipher} encryption in Git is better than
plain text but has limitations: the encryption key must be distributed securely
to all Config Server instances. Compromised encryption key = all secrets compromised.
Vault integration is architecturally superior: secrets never in Git, Vault
provides audit trail of who accessed what secret and when, Vault supports dynamic
secrets (short-lived database credentials). For production, Vault-backed Config
Server or Kubernetes Secrets (sealed secrets + Sealed Secrets controller) are
preferred over {cipher} encryption.

---

#### Q4 - What is the bootstrap context in Spring Cloud Config clients?

The bootstrap context loads BEFORE the regular ApplicationContext:

Bootstrap context purpose:
- Load configuration needed to connect to Config Server
  (Config Server URL, credentials, application name)
- This config cannot come FROM Config Server (chicken and egg)
- Source: bootstrap.properties / bootstrap.yml

Bootstrap context properties:
- spring.cloud.config.uri (Config Server URL)
- spring.application.name (determines config files to fetch)
- spring.cloud.config.username/password
- spring.profiles.active

Bootstrap context is DEPRECATED in Spring Boot 2.4+:
The new approach uses spring.config.import:
```properties
# application.properties (no bootstrap needed)
spring.application.name=order-service
spring.config.import=configserver:http://config-server:8888
```

The import is processed during the early config loading phase
(before ApplicationContext but using application.properties, not bootstrap.yml).

*What separates good from great:* The migration from bootstrap to spring.config.import
was one of Spring Boot 2.4's breaking changes for Config Server users. If upgrading
from Spring Boot 2.3 to 2.4+: either add spring.config.import, or add
spring-cloud-starter-bootstrap dependency which re-enables the bootstrap context.
The new spring.config.import approach is cleaner: one properties file instead of two,
and it fits into Spring Boot's config loading hierarchy consistently.

---

#### Q5 - How does Spring Cloud Kubernetes replace Eureka and Config Server?

Spring Cloud Kubernetes provides native Kubernetes integration:

**Service Discovery (replaces Eureka):**
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-client-discoveryclient</artifactId>
</dependency>
```

```java
// Works exactly like Eureka discovery
@FeignClient("inventory-service")
interface InventoryClient {
    @GetMapping("/inventory/{id}")
    Inventory get(@PathVariable Long id);
}
```

Behind the scenes: Spring Cloud Kubernetes DiscoveryClient queries the
Kubernetes API for Service endpoints. Load balancing: client-side (Spring Cloud
LoadBalancer) or Kubernetes kube-proxy (server-side via ClusterIP Service).

**Configuration (replaces Config Server):**
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-client-config</artifactId>
</dependency>
```

```yaml
spring:
  cloud:
    kubernetes:
      config:
        enabled: true
        # Which ConfigMaps to read
        sources:
          - name: order-service  # ConfigMap name
            namespace: default
      secrets:
        enabled: true
        sources:
          - name: order-service-secrets
```

Spring Cloud Kubernetes Config Watcher:
```yaml
# Separate container that watches ConfigMaps
# and calls /actuator/refresh on change
spring.cloud.kubernetes.config.reload.enabled=true
spring.cloud.kubernetes.config.reload.strategy=refresh
```

*What separates good from great:* Spring Cloud Kubernetes needs specific RBAC
permissions to call the Kubernetes API (list pods, get ConfigMaps). The required
ClusterRole/RoleBinding is a security consideration: giving read access to the
K8s API from application pods. Scope it to only the namespaces and resources
needed (ConfigMaps, Secrets, Services in the application's namespace).

---

#### Q6 - How do you achieve high availability for Eureka?

Eureka HA is achieved with a peer-to-peer cluster where each node replicates
to others:

```yaml
# Eureka Server 1 (server1)
server:
  port: 8761
eureka:
  client:
    service-url:
      defaultZone: http://server2:8762/eureka/

# Eureka Server 2 (server2)
server:
  port: 8762
eureka:
  client:
    service-url:
      defaultZone: http://server1:8761/eureka/
```

Client configuration (points to both):
```properties
eureka.client.service-url.defaultZone=\
  http://server1:8761/eureka/,\
  http://server2:8762/eureka/
```

Behavior:
- Each server registers with the others
- Registrations replicated peer-to-peer
- If one server goes down, others continue serving
- Client fetches registry from first available

In Kubernetes: Eureka Deployment with 2+ replicas + Headless Service.
Pods discover each other via DNS.

*What separates good from great:* Eureka peer replication is eventually consistent.
During a split-brain scenario (network partition between two Eureka nodes),
each node keeps its own registry. Clients may see different sets of services
depending on which Eureka they consult. Self-preservation activates. After
partition heals, registries converge. For most scenarios, this is acceptable.
For strict consistency requirements (financial services, healthcare), Consul with
Raft consensus is more appropriate than Eureka.

---

#### Q7 - How does the Config Server handle different environments?

Two strategies for environment separation:

**Strategy 1: Profile-based files (one branch):**
```
config-repo/
  application.yml               (all envs)
  application-dev.yml           (dev override)
  application-prod.yml          (prod override)
  order-service.yml             (service, all envs)
  order-service-dev.yml         (service, dev)
  order-service-prod.yml        (service, prod)
```
Client activates profile: spring.profiles.active=prod
Config Server serves profile-specific files.

**Strategy 2: Branch-based (one branch per environment):**
```
config-repo branches:
  main  -> prod config
  staging -> staging config
  dev -> dev config
```
Client specifies label (branch):
```properties
spring.cloud.config.label=main  # prod
spring.cloud.config.label=dev   # dev
```

Trade-offs:
- Profile-based: simple, all config in one branch, easy to see differences
- Branch-based: complete isolation, but merging between branches is complex

Recommended: profile-based for non-secrets, Vault for secrets.

*What separates good from great:* The profile-based approach works well for
structural differences (different DB hosts per env). For secrets (passwords, API keys),
neither approach is ideal (no secrets in Git). The production pattern: Config Server
for structure, Vault for secrets, with Config Server's Vault backend pulling secrets
from Vault at request time. The client gets config WITH secrets already resolved,
never seeing the Vault path.

---

#### Q8 - How do you implement a Config Server fallback strategy?

Client fallback when Config Server is unavailable:

**Option 1: fail-fast=false (local defaults):**
```properties
spring.cloud.config.fail-fast=false
```
Service starts with local application.properties.
Risk: service uses default config, may connect to wrong environment.

**Option 2: Retry with backoff:**
```properties
spring.cloud.config.fail-fast=true
spring.cloud.config.retry.max-attempts=6
spring.cloud.config.retry.initial-interval=1000
spring.cloud.config.retry.max-interval=2000
spring.cloud.config.retry.multiplier=1.1
```
Service retries for ~10 seconds before failing.
Works with Kubernetes restartPolicy: Always.

**Option 3: Config Server in same pod (sidecar):**
Spring Cloud Config Client can use local filesystem:
```yaml
spring.cloud.config.server.native.search-locations=\
  file:///etc/config
```
Kubernetes mounts ConfigMap as filesystem at /etc/config.
Config "Server" is just a Spring Boot app reading files.
No network call needed - no availability issue.

**Option 4: Kubernetes ConfigMap as fallback:**
Even with Config Server, mount ConfigMap with default values.
If Config Server unavailable, local file-based config provides defaults.

*What separates good from great:* The correct strategy depends on the risk profile.
fail-fast=true + retry: appropriate for mandatory config (wrong config = malfunction).
fail-fast=false: appropriate when local defaults are safe to run with.
In a K8s deployment: combine ConfigMap (always available, structural config)
+ Config Server (dynamic config, runtime updates). ConfigMap provides the
"floor" - service always has baseline config even if Config Server is down.

---

#### Q9 - How does service registration work in Eureka?

Registration lifecycle:

**Startup registration:**
```
POST /eureka/apps/{APP_NAME}
Body: {
  "instance": {
    "hostName": "10.0.1.5",
    "appName": "ORDER-SERVICE",
    "ipAddr": "10.0.1.5",
    "port": {"$": 8080, "@enabled": "true"},
    "securePort": {"$": 443, "@enabled": "false"},
    "healthCheckUrl": "http://10.0.1.5:8080/actuator/health",
    "statusPageUrl": "http://10.0.1.5:8080/actuator/info",
    "homePageUrl": "http://10.0.1.5:8080/",
    "status": "UP"
  }
}
```

**Heartbeat (renew registration):**
```
PUT /eureka/apps/{APP_NAME}/{instanceId}
Every 30 seconds (eureka.instance.lease-renewal-interval-in-seconds)
```

**Graceful deregistration:**
```
DELETE /eureka/apps/{APP_NAME}/{instanceId}
On JVM shutdown hook (Spring ApplicationContext.close)
```

**Status change (for graceful degradation):**
```
PUT /eureka/apps/{APP_NAME}/{instanceId}/status?value=OUT_OF_SERVICE
```
Removes from load balancing without deregistering.
Used in rolling deployments: mark OUT_OF_SERVICE before shutdown.

*What separates good from great:* The timing gap between deregistration and
client cache eviction: when a service shuts down and calls DELETE, the Eureka
server removes it. But clients cache the instance list for 30 seconds by default.
For 30 seconds after deregistration, clients may try to route to the dead instance.
In a rolling deployment: always wait for Kubernetes graceful shutdown to drain
existing connections before the process exits. The combination of:
(1) pre-stop hook sleep, (2) graceful shutdown drain, (3) Eureka deregistration
ensures no traffic reaches a shutting-down instance.

---

#### Q10 - How does Spring Cloud Config handle high-volume environments?

Config Server bottlenecks:
- Git clone: cloning a large repo is slow
- Per-request Git pull: checking for updates on every request is slow
- Concurrent requests: many services starting simultaneously

Optimization strategies:

**1. Git clone caching:**
```yaml
spring.cloud.config.server.git:
  uri: https://github.com/org/config-repo
  # Cache clone for 30 seconds
  refresh-rate: 30
  # Clone at startup, not per-request
  clone-on-start: true
  # Use shallow clone
  force-pull: false
```

**2. Local filesystem backend for Config Server (Kubernetes):**
```yaml
spring:
  profiles:
    active: native
  cloud:
    config:
      server:
        native:
          search-locations:
            - file:///etc/config/
```
ConfigMap mounted at /etc/config. No Git IO. Instant config reads.

**3. Config Server HA (multiple instances):**
Multiple Config Server instances read from same Git.
Client load balanced across Config Servers.

**4. Config Server composite backend:**
```yaml
spring.cloud.config.server.composite:
  - type: git
    uri: https://github.com/org/config-repo
  - type: vault
    host: vault-server
```
Git provides structure, Vault provides secrets. Best of both.

*What separates good from great:* At very high scale (1000+ services starting
simultaneously), even a cached Config Server becomes a bottleneck. Kubernetes-native
approach (ConfigMaps served via K8s API server) scales better because the K8s
API server is designed for high concurrent access. Config Server is a single
(or few) application instances with Git as backend - not designed for thousands
of concurrent requests. For very large deployments, move critical config to
ConfigMaps and reserve Config Server for dynamic configuration that needs
runtime refresh.

---

#### Q11 - How do you test microservices that depend on Config Server?

Testing challenges: Config Server may not be available in test environments.

**Option 1: Mock Config Server with WireMock:**
```java
@SpringBootTest
@AutoConfigureWireMock(port = 8888)
class OrderServiceIntegrationTest {

    @BeforeEach
    void setup() {
        // Mock Config Server response
        stubFor(get(urlPathEqualTo(
                "/order-service/test"))
            .willReturn(aResponse()
                .withHeader("Content-Type",
                    "application/json")
                .withBody("{\"propertySources\":"
                    + "[{\"name\":\"test\","
                    + "\"source\":"
                    + "{\"feature.enabled\":true}"
                    + "}]}")));
    }
}
```

**Option 2: Local config override (simplest):**
```properties
# src/test/resources/application-test.properties
spring.config.import=  # remove Config Server import
# Provide test values directly
feature.enabled=true
database.url=jdbc:h2:mem:testdb
```

**Option 3: Native profile Config Server:**
```yaml
# Config Server test profile
spring:
  profiles:
    active: native
  cloud:
    config:
      server:
        native:
          search-locations: classpath:/test-config/
```
Test Config Server reads from test classpath resources.
Fast, no Git, no network.

*What separates good from great:* The cleanest test approach: remove Config Server
from test scope entirely. Tests should not depend on external services (including
Config Server). Use application-test.properties to provide all needed values
directly. Only integration tests that specifically test Config Server integration
should have Config Server in scope. This follows the test pyramid principle:
unit/integration tests (no external services) vs full-stack tests (everything).

---

#### Q12 - How do you implement a GitOps workflow with Spring Cloud Config?

GitOps: Git is the single source of truth. Infrastructure and config changes
are made via Git PRs. No direct changes to running systems.

Config Server + GitOps:
```
Developer changes order-service-prod.yml
  -> Pull Request review
  -> Merge to main branch
  -> Git webhook fires
     POST /config-server/monitor
     (GitHub/GitLab webhook)
  -> Config Server receives webhook
  -> Config Server publishes RefreshRemoteApplicationEvent
     via Spring Cloud Bus (Kafka/RabbitMQ)
  -> All order-service instances receive event
  -> Instances call /actuator/refresh
  -> @RefreshScope beans recreated with new config
```

Config Server monitor endpoint:
```yaml
# Config Server application.yml
spring:
  cloud:
    config:
      monitor:
        enabled: true
    bus:
      enabled: true  # Spring Cloud Bus

spring:
  rabbitmq:
    host: rabbitmq-server
```

GitHub webhook setup:
- URL: http://config-server:8888/monitor
- Content-Type: application/json
- Events: Push

*What separates good from great:* The GitOps Config Server pattern has an audit
trail by design: every config change is a Git commit with author, timestamp, and
message. Rolling back config is a git revert commit. The webhook-to-bus-to-refresh
chain is event-driven: config changes propagate in seconds rather than on the
next poll. Combine with PR review process for production config changes: changes
to application-prod.yml require approval before merge, and production services
only update from the main branch. This enforces change management without
requiring manual intervention in running services.
