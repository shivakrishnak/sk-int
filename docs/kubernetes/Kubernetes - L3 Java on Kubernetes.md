---
layout: default
title: "Kubernetes - L3 Java on Kubernetes"
parent: "Kubernetes"
grand_parent: "SK Interview"
nav_order: 6
permalink: /kubernetes/l3-java-kubernetes/
---

# JVM Memory Configuration in Kubernetes

🎯 Interview Weight: very high - JVM memory in containers is a
production gotcha that causes OOMKilled at scale. Every Java
backend candidate should know this cold.

---

### 🎯 Model Answer

**30 seconds:**
> JVM inside a container must be told container memory limits,
> not host memory. Without configuration, JVM defaults to 25%
> of total host RAM (e.g., 4GB on a 16GB host) - ignoring the
> 512MB container limit. Result: OOMKilled. Fix: use
> `-XX:MaxRAMPercentage=75` (JDK 11+) so JVM sets its heap
> relative to container memory, or set `-Xmx` explicitly.

**3 minutes (Senior):**
> JVM container memory model:
>
> Pre-JDK 10 problem: JVM reads /proc/meminfo (host total RAM),
> not cgroup memory limits. A container limited to 512Mi on a
> 32GB host causes JVM to set heap at 8GB (25% of 32GB).
> The JVM exceeds the cgroup limit. Linux OOM killer terminates
> the container process. Kubernetes restarts it. Loop.
>
> JDK 10+ container awareness:
> `-XX:+UseContainerSupport` (default since JDK 10).
> JVM reads cgroup memory limits via /sys/fs/cgroup/memory.
> JVM now knows it has 512Mi, not 32GB.
>
> Heap sizing options:
> `-XX:MaxRAMPercentage=75.0`: set max heap to 75% of container
> memory. For 512Mi container: heap = 384Mi. Off-heap (Metaspace,
> thread stacks, code cache, direct buffers) needs the remaining 25%.
>
> `-Xmx400m -Xms400m`: explicit sizing. Set Xms=Xmx to avoid
> heap resizing overhead. Deterministic.
>
> Off-heap memory budget (non-heap):
> Metaspace: 100-200MB (class metadata). Default: unbounded.
> Set `-XX:MaxMetaspaceSize=128m`.
> Thread stacks: 1MB per thread (default). 200 threads = 200MB.
> Set `-Xss512k` to reduce per-thread stack.
> Direct buffers: NIO, Netty. Set
> `-XX:MaxDirectMemorySize=128m`.
> Code cache (JIT): 240MB default. Set
> `-XX:ReservedCodeCacheSize=64m` for small services.
>
> Total memory formula for K8s resource limit:
> container_limit = Xmx + Metaspace + threads * stackSize
>                 + directMemory + codeCache + 100MB buffer
> For a 512Mi container: Xmx=256m, Metaspace=64m,
> threads=100*512k=50m, direct=32m, codeCache=32m = ~434Mi.
> 512Mi limit is tight. Use 768Mi for safe operation.
>
> Kubernetes resource settings:
> requests = memory the scheduler uses for bin-packing.
> limits = memory cgroup enforces (OOMKill threshold).
> Best practice: set requests = limits (Guaranteed QoS class).
> If requests < limits (Burstable class): pod may be evicted
> under node memory pressure before hitting its limit.

**Blank Mind Recovery:**

**(1) Restate:** "JVM must know the container memory limit.
Use MaxRAMPercentage and budget off-heap memory."

**(2) First principles:** "JVM does not know it is in a container
unless told. It will allocate memory based on host stats and
get killed by the kernel."

**(3) Bridge:** "Like building a house within a lot - you must
know the lot size (container limit) before designing the rooms
(heap, metaspace, threads)."

---

### 📘 Concept Explanation

**Memory zones in a Java container:**

```
Container Limit (e.g. 1Gi = 1024 MiB)
├── JVM Heap (MaxRAMPercentage=75%)  = 768 MiB
│   ├── Young Generation
│   └── Old Generation
└── Non-Heap (must fit in remaining ~256 MiB)
    ├── Metaspace (class metadata)
    ├── Thread stacks (N threads * Xss)
    ├── Direct ByteBuffers (NIO, Netty)
    ├── Code Cache (JIT compiled code)
    └── GC overhead structures
```

---

### 💻 Code Example

```yaml
# BAD: no memory configuration - JVM uses host memory
containers:
  - name: my-service
    image: my-service:1.0
    resources:
      requests:
        memory: "512Mi"
      limits:
        memory: "512Mi"
    # No JVM flags - JVM reads host 32GB RAM
    # Sets heap to ~8GB -> OOMKilled immediately

---
# GOOD: explicit JVM memory configuration
containers:
  - name: my-service
    image: my-service:1.0
    resources:
      requests:
        memory: "768Mi"   # match limits for Guaranteed QoS
        cpu: "500m"
      limits:
        memory: "768Mi"
        cpu: "2000m"
    env:
      - name: JAVA_OPTS
        value: >-
          -XX:+UseContainerSupport
          -XX:MaxRAMPercentage=75.0
          -XX:InitialRAMPercentage=75.0
          -XX:MaxMetaspaceSize=128m
          -Xss512k
          -XX:ReservedCodeCacheSize=64m
          -XX:MaxDirectMemorySize=64m
          -XX:+ExitOnOutOfMemoryError
```

> **Code walkthrough:** The bad config omits JVM flags entirely.
> Without `-XX:MaxRAMPercentage`, the JVM reads the host's 32GB
> and sets an 8GB heap inside a 512Mi container - instant OOMKill.
> The good config sets MaxRAMPercentage=75 (576Mi heap for 768Mi
> container), caps Metaspace, reduces thread stack size to 512k
> (saves 50% vs default 1MB), and caps DirectMemory and CodeCache.
> `ExitOnOutOfMemoryError` ensures clean pod restart instead of
> hanging in OOM state. `requests=limits` gives Guaranteed QoS
> (no eviction under node pressure).

---

### ⚖️ Comparison Table

| Sizing Approach | Pros | Cons | When to Use |
|----------------|------|------|-------------|
| `-XX:MaxRAMPercentage` | Dynamic, portable | Off-heap budget manual | General purpose |
| Explicit `-Xmx` | Deterministic | Must recalculate on resize | Stable workloads |
| `-Xmx -Xms` equal | No resizing overhead | Slower startup | Production (low latency) |
| No config (pre-JDK10) | None | OOMKilled | Never |

---

### ⚠️ Common Misconceptions

**Misconception 1:** "Setting memory limit = Xmx is correct."
**Reality:** Xmx is just the heap. Non-heap can add 200-400MB.
Container limit must be Xmx + non-heap + buffer.

**Misconception 2:** "UseContainerSupport is not needed in JDK 11+."
**Reality:** It is on by default but explicitly setting it
documents intent and is safe.

**Misconception 3:** "Requests and limits can differ freely."
**Reality:** Burstable QoS (requests < limits) pods are evicted
first under node pressure. Match them for critical services.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - OOMKilled loop:**
Symptom: pod restarts every few minutes, status OOMKilled.
`kubectl describe pod <pod>` shows `OOMKilled: true`.
Cause: JVM heap exceeded container limit.
Fix: increase container limit OR reduce MaxRAMPercentage OR
add explicit caps on Metaspace and DirectMemory.

**Failure 2 - Metaspace OOM:**
Symptom: `java.lang.OutOfMemoryError: Metaspace`.
Cause: class loading leak (frameworks generating classes, e.g.,
Reflection, Hibernate proxies). MaxMetaspaceSize not set.
Fix: set `-XX:MaxMetaspaceSize=128m`, enable `-Xlog:class+load`
to identify loading source.

**Failure 3 - Slow startup then OOMKilled:**
Cause: JIT code cache too small for large Spring Boot app.
ReservedCodeCacheSize hit -> deoptimization cycles -> slow ->
OOMKill.
Fix: increase `-XX:ReservedCodeCacheSize=128m`.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | MaxRAMPercentage + requests=limits |
| Senior | 7 min | Full memory budget + QoS classes + diagnosis |
| Staff | 10 min | OOMKill loop root cause + GC tuning in containers |

**[DEBUGGING] A Java pod is OOMKilled every 2 hours in production.
Memory limit is 1Gi. How do you diagnose it?**
`[SENIOR]`

*Why they ask:* Tests real container debugging experience, not
just theoretical knowledge.

*Likely follow-up:* "The heap usage looks normal in the metrics.
What else could it be?"

Step 1: `kubectl describe pod` - confirm OOMKilled, note RSS
(Resident Set Size). If RSS exceeds limit, cgroup kills the pod.
Step 2: Check heap vs container memory. Add JMX metrics or
`/actuator/metrics/jvm.memory.used`. If heap < 600Mi (75% of 1Gi),
heap is not the culprit.
Step 3: Check off-heap. Use `/proc/<pid>/smaps` or
`-XX:NativeMemoryTracking=summary` + `jcmd <pid> VM.native_memory`.
This shows heap, metaspace, thread stacks, code cache, direct
buffers broken down.
Step 4: Common non-heap culprits: (a) Thread stacks growing
(thread pool leak - each thread = 1MB stack). Check thread count
via JMX. (b) Direct buffer leak (Netty buffers not released).
`-XX:MaxDirectMemorySize=128m` + `DirectMemory` metrics.
(c) Metaspace leak (dynamic class generation). Monitor
`jvm.memory.used{area=nonheap}`.
Step 5: Add `-XX:+ExitOnOutOfMemoryError -XX:HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/dumps` - capture heap dump on OOM for analysis.

*What separates good from great:* Knowing that heap OOM and
container OOMKill are different - the container can be killed
even if the JVM heap is fine (off-heap growth).

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | MaxRAMPercentage formula + non-heap budget |
| K8s/Platform | QoS classes + eviction behavior |
| Bar Raiser | OOMKill diagnosis methodology |

---

---

# Graceful Shutdown for Java Services

🎯 Interview Weight: very high - Graceful shutdown prevents
request drops and data corruption during deployments. Expected
at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Graceful shutdown ensures a Java service: stops accepting new
> requests, finishes in-flight requests, closes DB connections,
> commits or rolls back pending transactions, and exits cleanly.
> Without it, a rolling update kills pods mid-request causing
> 500 errors for users. Kubernetes sends SIGTERM first (grace
> period: default 30s), then SIGKILL. Java catches SIGTERM via
> a shutdown hook or Spring's context refresh.

**3 minutes (Senior):**
> Graceful shutdown sequence in Kubernetes:
>
> 1. Kubernetes marks pod as Terminating (removes from service
>    endpoints - new requests no longer route to this pod).
>    PROBLEM: there is a propagation delay (kube-proxy, Envoy
>    take 1-5 seconds to update iptables). Requests still arrive
>    during this window.
>
> 2. Kubernetes sends SIGTERM to PID 1 in the container.
>
> 3. Java application receives SIGTERM (via JVM shutdown hook
>    or Spring lifecycle). Spring Boot: graceful shutdown enabled
>    with `server.shutdown=graceful`. The Tomcat/Netty thread
>    pool drains active requests before accepting new ones.
>
> 4. Application completes in-flight requests (up to
>    `spring.lifecycle.timeout-per-shutdown-phase=30s`).
>
> 5. Spring closes ApplicationContext: triggers @PreDestroy,
>    closes DB connection pools (HikariCP), shuts down
>    message consumers (Kafka consumers commit offsets),
>    closes caches.
>
> 6. JVM exits (exit code 0).
>
> 7. If not complete within terminationGracePeriodSeconds
>    (default: 30), Kubernetes sends SIGKILL.
>
> The propagation delay problem:
> Solution: add a preStop sleep hook in the pod spec.
> `preStop: exec: command: ["sleep", "10"]`
> This delays the SIGTERM, giving kube-proxy time to remove
> the pod from service endpoints before the app starts shutting
> down. Typical value: 5-15 seconds.

**Blank Mind Recovery:**

**(1) Restate:** "Graceful shutdown: stop accepting traffic,
finish current requests, clean up resources, exit."

**(2) First principles:** "A hard kill mid-request = data corruption
and 500 errors. Graceful shutdown = finish what you started."

---

### 💻 Code Example

```yaml
# Kubernetes pod spec with graceful shutdown
spec:
  terminationGracePeriodSeconds: 60
  containers:
    - name: java-service
      image: my-service:1.0
      lifecycle:
        preStop:
          exec:
            # Delay SIGTERM to allow kube-proxy to drain
            command: ["sleep", "15"]
```

```yaml
# application.yaml - Spring Boot graceful shutdown
server:
  shutdown: graceful   # drain active requests before shutdown

spring:
  lifecycle:
    # Max time to wait for active requests to complete
    timeout-per-shutdown-phase: 30s

# Kafka consumer - commit offsets on shutdown
spring:
  kafka:
    consumer:
      enable-auto-commit: false   # manual commit = safe
    listener:
      ack-mode: MANUAL_IMMEDIATE  # commit explicitly
```

```java
// Custom shutdown hook for non-Spring resources
@Component
public class GracefulShutdownHook {

    private final KafkaConsumer kafkaConsumer;
    private final ScheduledExecutorService scheduler;

    @PreDestroy
    public void shutdown() {
        log.info("Shutting down: stopping scheduler");
        scheduler.shutdown();
        try {
            // Wait up to 10 seconds for running tasks
            if (!scheduler.awaitTermination(10, SECONDS)) {
                scheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            scheduler.shutdownNow();
            Thread.currentThread().interrupt();
        }

        log.info("Shutting down: closing Kafka consumer");
        kafkaConsumer.close(Duration.ofSeconds(5));
        log.info("Shutdown complete");
    }
}
```

> **Code walkthrough:** The `preStop: sleep 15` buys 15 seconds
> for kube-proxy to remove this pod from service endpoints
> before the app receives SIGTERM. `server.shutdown=graceful`
> tells Spring Boot to drain Tomcat threads before stopping.
> The `terminationGracePeriodSeconds=60` gives 60 seconds total
> (15 preStop + 45 for draining). The `@PreDestroy` hook handles
> resources Spring does not know about - the scheduler and
> Kafka consumer get a clean shutdown with offset commit.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The preStop sleep is a band-aid for a fundamental race condition
> in Kubernetes networking. The clean solution: readiness probe
> returns false immediately on shutdown signal. This removes
> the pod from load balancer rotation immediately (before
> kube-proxy update). Implementation: add a `volatile boolean
> shuttingDown = false;` flag, set it in a shutdown hook, return
> HTTP 503 in the readiness probe when true. Spring Boot 2.3+
> does this automatically with graceful shutdown enabled.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | SIGTERM flow + Spring shutdown config |
| Senior | 7 min | preStop hook + propagation delay + Kafka offset commit |
| Staff | 10 min | Readiness-based draining + zero-request-drop guarantees |

---

---

# Init Containers and Sidecar Pattern

🎯 Interview Weight: medium-high - Init containers and sidecars
model infrastructure concerns. Tested at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Init containers run to completion before the main container
> starts. Used for: waiting for DB readiness, loading secrets,
> running DB migrations, setting up config. Sidecar containers
> run alongside the main container throughout its lifetime.
> Used for: log shipping, metrics collection, service mesh
> proxy (Envoy), secrets refresh. Both patterns separate
> infrastructure concerns from application logic.

**3 minutes (Senior):**
> Init container use cases:
>
> DB readiness check: "Wait until PostgreSQL accepts connections
> before starting the app." Without init container: Spring Boot
> fails to start if DB is not ready (pod CrashLoopBackOff).
> With init container: a small `busybox` container polls the DB
> every 5 seconds; main container starts only when DB is ready.
>
> DB schema migration: run `flyway migrate` in an init container
> before the service starts. All replicas use the same init
> container image; only one migration runs because of Flyway's
> distributed lock. Safe even with multiple pod replicas starting
> simultaneously.
>
> Secret injection: fetch secrets from Vault into a shared
> `emptyDir` volume. Main container reads secrets from the
> volume. Vault agent runs as an init container (or sidecar
> for dynamic secrets).
>
> Sidecar container use cases:
>
> Log shipping (Filebeat sidecar): reads app's log files from
> a shared volume, ships to Elasticsearch. App does not need
> Elasticsearch knowledge.
>
> Service mesh (Envoy/Istio): transparently intercepts all
> network traffic. mTLS, circuit breaking, retry logic handled
> at mesh layer without application code changes.
>
> Secrets refresh (Vault Agent sidecar): watches for secret
> expiry, fetches fresh secrets, writes to shared volume. App
> re-reads the file. No restart required for secret rotation.
>
> Kubernetes 1.29+: native sidecar containers (restartPolicy:
> Always in initContainers). Sidecars start before main container,
> stay running throughout pod lifetime, stop after main exits.
> Previously, sidecars were implemented as regular containers
> with init container workarounds.

**Blank Mind Recovery:**

**(1) Restate:** "Init containers: prerequisites before app starts.
Sidecars: infrastructure helpers running alongside the app."

---

### 💻 Code Example

```yaml
spec:
  initContainers:
    # Wait for database to be ready
    - name: wait-for-db
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          until nc -z postgres-svc 5432; do
            echo "Waiting for DB..."
            sleep 3
          done
          echo "DB is ready"

    # Run DB migration before app starts
    - name: run-migration
      image: my-service:1.0
      command: ["java", "-jar", "app.jar",
                "--spring.profiles.active=migrate"]
      env:
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url

  containers:
    # Main application
    - name: my-service
      image: my-service:1.0
      ports:
        - containerPort: 8080

    # Sidecar: structured log shipping
    - name: log-shipper
      image: elastic/filebeat:8.12.0
      volumeMounts:
        - name: log-volume
          mountPath: /var/log/app
      env:
        - name: ELASTICSEARCH_HOST
          value: "elasticsearch:9200"

  volumes:
    - name: log-volume
      emptyDir: {}
```

> **Code walkthrough:** The `wait-for-db` init container uses
> `nc` (netcat) to poll the PostgreSQL port until it accepts
> connections. Kubernetes retries the init container if it
> exits non-zero. The `run-migration` init container runs Flyway
> using the same image as the app (same classpath). After both
> init containers succeed, the main container starts. The
> Filebeat sidecar shares the `log-volume` emptyDir with the
> main container, shipping logs without any application code
> changes.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The anti-pattern: using init containers for long-running setup
> that adds 60+ seconds to pod startup. Example: downloading a
> large model file (500MB) in an init container on every pod
> restart. Fix: bake the model into the Docker image (layer
> cache), use a PersistentVolumeClaim to pre-populate once, or
> use a daemonset to pre-stage data on nodes. Init container
> startup delay = deployment delay = slower rollouts = worse SLA.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Init container use cases + DB readiness |
| Senior | 6 min | Migration in init containers + sidecar patterns |
| Staff | 8 min | Vault agent sidecar + native K8s 1.29+ sidecars |

---

---

# Spring Boot on Kubernetes Best Practices

🎯 Interview Weight: very high - Spring Boot + K8s integration is
the most common Java deployment pattern. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Boot on Kubernetes: set `server.shutdown=graceful`,
> configure `/actuator/health/liveness` and
> `/actuator/health/readiness` probes, use
> `-XX:MaxRAMPercentage=75` for JVM memory, set equal requests
> and limits (Guaranteed QoS), externalize config via
> environment variables or ConfigMaps, and use init containers
> for DB migration. The Spring Boot actuator + Kubernetes health
> probes integration is the critical piece.

**3 minutes (Senior):**
> Spring Boot + Kubernetes integration checklist:
>
> Health probes (Spring Boot 2.3+):
> `/actuator/health/liveness`: application is alive (not deadlocked).
> Spring only returns DOWN if the app is fatally broken
> (OOM, deadlock, internal error). Kubernetes restarts on DOWN.
> `/actuator/health/readiness`: application is ready to serve traffic.
> Returns DOWN during startup (DB connection not established,
> caches not loaded), returns UP when fully ready. Kubernetes
> removes from service endpoints on DOWN (traffic stops).
> Setting: `management.health.probes.enabled=true`
> (auto-detected in Kubernetes environment).
>
> Configuration externalization:
> 12-factor app: config comes from the environment, not baked in.
> Spring property hierarchy: default values in application.yaml ->
> overridden by ConfigMap (mounted as env vars or volume file) ->
> overridden by Secrets (sensitive data as env vars).
> Profile activation: `SPRING_PROFILES_ACTIVE=prod` env var.
>
> Startup probe (Spring Boot slow startup):
> JVM + Spring context initialization takes 10-60 seconds.
> Liveness probe failing during startup -> pod killed before
> it is ready (thrash).
> Solution: `startupProbe` with generous `failureThreshold`
> (30 * 10s = 300s startup window). Only after startup probe
> succeeds do liveness and readiness probes activate.
>
> Spring Cloud Kubernetes (optional):
> Reads ConfigMaps and Secrets as Spring property sources.
> Config refreshable without pod restart (Spring Cloud Bus
> or actuator `/actuator/refresh`). Requires RBAC to read
> ConfigMaps/Secrets in the pod's namespace.

**Blank Mind Recovery:**

**(1) Restate:** "Spring Boot Kubernetes integration: health probes,
graceful shutdown, env-based config, JVM memory settings."

---

### 💻 Code Example

```yaml
# application.yaml - Spring Boot K8s configuration
server:
  shutdown: graceful
  port: 8080

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
  datasource:
    url: ${DB_URL}       # from K8s Secret env var
    username: ${DB_USER}
    password: ${DB_PASSWORD}

management:
  health:
    probes:
      enabled: true    # /liveness and /readiness endpoints
    livenessState:
      enabled: true
    readinessState:
      enabled: true
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
```

```yaml
# Kubernetes deployment with Spring Boot probes
containers:
  - name: spring-service
    image: my-spring-service:1.0
    env:
      - name: DB_URL
        valueFrom:
          secretKeyRef:
            name: db-credentials
            key: url
      - name: JAVA_OPTS
        value: "-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
    startupProbe:
      httpGet:
        path: /actuator/health/liveness
        port: 8080
      initialDelaySeconds: 30
      failureThreshold: 20     # 20 * 10s = 200s for slow JVM
      periodSeconds: 10
    livenessProbe:
      httpGet:
        path: /actuator/health/liveness
        port: 8080
      periodSeconds: 10
      failureThreshold: 3      # restart if dead 30s
    readinessProbe:
      httpGet:
        path: /actuator/health/readiness
        port: 8080
      periodSeconds: 5
      failureThreshold: 3      # remove from load balancer 15s
```

> **Code walkthrough:** The startup probe gives 200 seconds
> (20 * 10s) for JVM startup - critical for large Spring contexts.
> After the startup probe passes, liveness and readiness activate.
> Liveness checks app health every 10s, restarts on 3 failures.
> Readiness checks every 5s, removes from service on 3 failures
> (15 second window). DB credentials come from Secrets as env
> vars - never baked into the image or ConfigMap.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The two-probe problem most teams get wrong: using the same
> endpoint for liveness and readiness. If the liveness endpoint
> returns DOWN because a downstream dependency (Redis, Kafka)
> is unavailable, Kubernetes restarts the pod - but the dependency
> is still down, so the new pod immediately restarts too. The
> restart loop amplifies the outage. Fix: liveness checks only
> the JVM's internal health (no external dependencies).
> Readiness checks external dependencies. During a Redis outage:
> readiness returns DOWN (traffic stops), liveness returns UP
> (pod stays alive). When Redis recovers: readiness returns UP
> (traffic resumes). No restart loop.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Probe types + Spring Boot actuator config |
| Senior | 8 min | Liveness vs readiness separation + startup probe |
| Staff | 12 min | Config externalization + Spring Cloud Kubernetes |

---

---

# Native Image in Kubernetes Deployments

🎯 Interview Weight: medium-high - GraalVM Native Image changes
the Java Kubernetes deployment model. Tested at senior+ level.

---

### 🎯 Model Answer

**30 seconds:**
> GraalVM Native Image compiles Java to a native binary with
> no JVM startup overhead. Benefits in Kubernetes: sub-second
> startup (10-100ms vs 10-30s for JVM), ~5x lower memory
> (no JVM overhead), smaller container images (10-50MB vs
> 200-500MB). Trade-offs: longer build time (2-10 minutes),
> reflection requires configuration, dynamic class loading is
> restricted. Ideal for: serverless, short-lived batch jobs,
> lambda functions, and scale-to-zero scenarios.

**3 minutes (Senior):**
> Native image Kubernetes deployment differences:
>
> Container image size:
> JVM: `FROM eclipse-temurin:21-jre` base image = 250MB +
> Spring Boot fat JAR = 350-500MB total.
> Native: `FROM scratch` (no JVM needed) or `FROM gcr.io/distroless/base`
> = 10-50MB total. Smaller image = faster pull = faster pod startup.
>
> Startup time:
> JVM Spring Boot: 8-30 seconds (depends on context size).
> Native Spring Boot: 50-200ms. This makes native ideal for:
> (1) Scale-to-zero (Knative/KEDA scales to 0 when idle, starts
> instantly on first request).
> (2) CronJob pods (start, run, exit quickly).
> (3) Lambda/FaaS deployments.
>
> Memory usage:
> JVM: 200-500MB RSS for a Spring Boot service.
> Native: 40-100MB RSS for the same service (no JVM heap
> overhead, no JIT compiler memory).
>
> Resource configuration differences:
> No JVM flags (`-Xmx`, `-XX:MaxRAMPercentage` etc.) - native
> binary uses native OS memory management.
> Memory limit can be much lower: 128Mi-256Mi instead of 512Mi-1Gi.
>
> Build pipeline changes:
> `./mvnw -Pnative native:compile` (Spring Boot 3 native)
> Requires GraalVM JDK at build time. Not at runtime.
> Build takes 2-10 minutes vs 30-60 seconds for JVM build.
> CI/CD: native build in a dedicated build stage.
> Cache Graal reachability metadata between builds.
>
> Reflection limitation:
> Native image does all class analysis at build time (closed
> world assumption). Dynamic reflection, JDK proxies, serialization
> require `reflect-config.json`. Spring Boot 3 generates this
> automatically via AOT processing. Third-party libraries may
> need manual configuration.

**Blank Mind Recovery:**

**(1) Restate:** "Native Image: no JVM, instant start, small memory,
tiny container. Trade-off: longer build, reflection constraints."

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> Native image is not universally better. For long-running
> services with JIT optimization: JVM peaks at higher throughput
> than native (JIT optimizes hot paths; native uses AOT-compiled
> code without runtime profile feedback). For sub-100ms startup
> and low memory services (FaaS, batch): native is compelling.
> The decision framework: startup time < 1s required? Use native.
> Peak throughput > steady throughput matters? Use JVM. Memory
> cost is the binding constraint? Use native. GraalVM 24+ with
> Profile-Guided Optimization (PGO) narrows the throughput gap.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 3 min | Native vs JVM differences in K8s |
| Senior | 6 min | Scale-to-zero + build pipeline + reflection limitations |
| Staff | 8 min | JVM vs native throughput trade-off + PGO |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | JVM memory config + graceful shutdown |
| K8s/Platform | Native image + resource sizing |
| Bar Raiser | OOMKill debugging + liveness/readiness separation |
