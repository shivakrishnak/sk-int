---
layout: default
title: "Kubernetes - L2 Workloads"
parent: "Kubernetes"
nav_order: 3
permalink: /kubernetes/l2-workloads/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Health Probes Liveness Readiness Startup](#health-probes-liveness-readiness-startup) | high |
| 2 | [Resource Requests and Limits](#resource-requests-and-limits) | high |
| 3 | [Horizontal Pod Autoscaler](#horizontal-pod-autoscaler) | high |
| 4 | [Rolling Updates and Rollback Strategies](#rolling-updates-and-rollback-strategies) | high |
| 5 | [Jobs CronJobs and Batch Processing](#jobs-cronjobs-and-batch-processing) | medium |

---

# Health Probes Liveness Readiness Startup

**Interview Weight:** high - Probes are the operational contract between
your application and Kubernetes. Misconfigured probes cause production
incidents. Every Java Kubernetes interview covers this.

---

### 🎯 Model Answer

**30 seconds:**

> Kubernetes has three probe types: startupProbe (is the app still starting?),
> readinessProbe (is the app ready to receive traffic?), and livenessProbe
> (is the app alive and functional?). startupProbe runs first and disables
> liveness during startup - critical for slow JVM startup. readinessProbe
> gates Service traffic routing. livenessProbe triggers pod restart on failure.
> All three should point to Spring Boot Actuator health endpoints.

**3 minutes (Senior):**

> The three probes serve distinct purposes at different lifecycle phases,
> and they interact with each other.
>
> startupProbe: active only during initial startup. While startupProbe is
> running, liveness and readiness probes are disabled. This prevents premature
> liveness failures during the Spring Boot context initialization (which can
> take 20-60 seconds). Configuration: failureThreshold * periodSeconds = maximum
> startup budget. For Spring Boot: 30 * 10 = 300 seconds.
>
> readinessProbe: indicates whether the pod should receive traffic. A failing
> readiness probe removes the pod from the Service Endpoints within 1-5 seconds.
> Traffic stops flowing to the pod. When readiness recovers, the pod is re-added.
> This is the primary mechanism for: keeping traffic away from not-yet-ready
> pods during startup, removing pods from routing during temporary overload or
> maintenance, and preventing traffic during rolling updates.
>
> livenessProbe: indicates whether the pod should be restarted. A liveness
> failure triggers container restart (not pod replacement - the pod stays on
> the same node). Configure conservatively: use high failureThreshold (3-4)
> to avoid restarting pods under temporary load. A liveness probe restart
> resolves thread deadlocks and OOM zombie states that readiness cannot.
>
> Spring Boot Actuator: /actuator/health/readiness and /actuator/health/liveness
> provide Spring-managed health endpoints. Spring marks readiness DOWN when the
> application is not ready for traffic (during startup or when manually set).
> Spring marks liveness DOWN only when the application is in an unrecoverable
> state (developers can trigger this via ApplicationAvailability API).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the three Kubernetes health probe types
and how they apply to Java services."

**(2) First principles:** "A health system needs to know: did it start? is it
ready? is it alive? These three questions map exactly to startup, readiness, and
liveness probes."

**(3) Bridge:** "Like a new employee on day 1: startupProbe is the onboarding
period (not yet ready for full duties). readinessProbe is being on duty (ready
to take calls). livenessProbe is still being alive (not having a breakdown that
requires a reset)."

---

### 📘 Concept Explanation

**What it is:**
Kubernetes health probes are periodic checks that determine pod health states,
controlling traffic routing (readiness), restart policy (liveness), and startup
gate (startup), using HTTP, TCP, or exec probe types.

**The problem it solves:**
Kubernetes cannot distinguish between a pod that is starting (normal, do not
route traffic), temporarily degraded (unhealthy, stop routing traffic), or
permanently stuck (restart required). The three probes provide this distinction.

**How it works:**

```
Probe Lifecycle (time->):

  t=0:  Pod starts
  startupProbe active: liveness + readiness DISABLED
    |
    | Spring Boot context loading (30s typical)
    |
  t=30: startupProbe passes -> startup DONE
  readinessProbe active: traffic DISABLED until passes
    |
    | DB connection pool initialized, config loaded
    |
  t=32: readinessProbe passes -> ADD to Service Endpoints
        Traffic starts flowing
  livenessProbe active: restart if fails
    |
    | Normal operation: both pass each check
    |
  t=X:  Thread deadlock - app stops responding
        readinessProbe fails -> REMOVE from Endpoints
        livenessProbe fails (failureThreshold=4 reached)
        -> Container RESTARTED

Probe Types:
  httpGet:  GET request, 200-399 = healthy
  tcpSocket: TCP connect success = healthy
  exec:     exit code 0 = healthy
  grpc:     gRPC health check protocol

Spring Actuator Endpoints:
  /actuator/health/liveness   -> {status: UP}
  /actuator/health/readiness  -> {status: UP}
  Require: management.endpoint.health.probes.enabled=true
```

**The key insight:**
liveness and readiness probes serve DIFFERENT Kubernetes actions.
readiness failure = remove from Endpoints (stop traffic).
liveness failure = restart container.
A temporarily overloaded pod should fail readiness (stop traffic) but NOT
liveness (do not restart). Configure differently: readiness with tight
failureThreshold (3 failures * 5s = 15s to deregister), liveness with loose
failureThreshold (4 failures * 15s = 60s before restart).

**When to use exec probes:**
For non-HTTP services (gRPC before gRPC probe support, Java CLI apps,
batch services). Exec probes are heavier (spawn a new process) - use
HTTP or gRPC probes for web services.

**First-principles derivation:**
Traffic routing requires knowing if a pod is ready. Restart decisions
require knowing if a pod is alive. Initial startup requires a separate
gate to prevent premature liveness from restarting a healthy-but-slow-starting
pod. These three distinct decisions require three distinct probe states.

---

### 💻 Code Example

**Example 1: BAD vs GOOD probe configuration for Spring Boot**

```yaml
# BAD: Single liveness probe, no startup probe
# Problem: liveness fires immediately at startup.
# Spring Boot 60s startup -> liveness fails 4x ->
# pod restarts -> infinite crash loop
spec:
  containers:
  - name: app
    image: myapp:v1.0
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30   # Hope 30s is enough
      periodSeconds: 10
      failureThreshold: 3

---
# GOOD: All three probes, correctly configured
spec:
  containers:
  - name: app
    image: myapp:v2.0
    # startupProbe: protect slow JVM startup
    # 30 * 10s = 300s startup budget
    # liveness + readiness DISABLED until this passes
    startupProbe:
      httpGet:
        path: /actuator/health/liveness
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
    # readinessProbe: gate Service traffic
    # Fail 3 * 5s = 15s to remove from endpoints
    readinessProbe:
      httpGet:
        path: /actuator/health/readiness
        port: 8080
      periodSeconds: 5
      failureThreshold: 3
      successThreshold: 1
    # livenessProbe: restart stuck pods ONLY
    # Conservative: 4 * 15s = 60s before restart
    # Prevents restart during temporary load spikes
    livenessProbe:
      httpGet:
        path: /actuator/health/liveness
        port: 8080
      periodSeconds: 15
      failureThreshold: 4
```

> **Code walkthrough:** The BAD configuration uses only liveness with
> initialDelaySeconds as a crude startup gate. If Spring Boot takes longer
> than 30 seconds (common in cold-start scenarios), liveness fires before
> readiness and crashes the pod into a restart loop. The GOOD configuration
> uses startupProbe to protect the entire startup phase: Kubernetes disables
> liveness checks until startupProbe passes, allowing up to 300 seconds for
> initialization. The readiness probe is tight (15 seconds to deregister)
> so traffic stops flowing to degraded pods quickly. The liveness probe is
> conservative (60 seconds) to avoid restarting pods under transient load.

```yaml
# Spring Boot application.properties
# Required for /readiness and /liveness actuator endpoints
management.endpoint.health.probes.enabled=true
management.health.livenessState.enabled=true
management.health.readinessState.enabled=true

# Graceful shutdown: complete in-flight requests before exit
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
```

> **Code walkthrough:** The Spring Boot configuration enables the dedicated
> /readiness and /liveness endpoints that map to Spring's lifecycle state
> machine. Without `probes.enabled=true`, the actuator uses the generic
> /health endpoint which aggregates all health indicators - a DB hiccup would
> fail liveness (causing unnecessary restarts). The dedicated endpoints give
> Spring fine-grained control: readiness DOWN during startup, liveness DOWN
> only for unrecoverable application failures.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Kubernetes has three probe types: startupProbe (is the app starting?),
> readinessProbe (is it ready for traffic?), and livenessProbe (is it alive?).
> startupProbe runs during startup and disables liveness/readiness. readinessProbe
> removes the pod from Service Endpoints when it fails. livenessProbe restarts
> the container. For Spring Boot: configure startupProbe with failureThreshold:
> 30 and periodSeconds: 10 to allow 5 minutes for startup.

*Push deeper:* "The interaction between probes: while startupProbe is active,
liveness and readiness probes do not run. This is the key behavior that prevents
crash loops for slow-starting apps. Only when startupProbe passes do liveness
and readiness begin. This means startupProbe must be configured more generously
than liveness - it is the final gate protecting against premature restarts."

---

**Senior / Staff (5+ years):**

> The most impactful probe configuration for Java production services:
> (1) startupProbe with generous timeout (30 * 10s for Spring Boot)
> (2) readinessProbe checking /actuator/health/readiness (not /health)
>     - Avoid checking DB health in readiness probe: a DB hiccup removes
>       ALL pods from endpoints simultaneously -> service unavailable
>     - readiness should reflect app state (am I ready?), not dependency health
> (3) livenessProbe with conservative threshold (4 * 15s)
>
> Production incident I have seen: readiness probe checking DB health.
> During a DB maintenance window, all pods failed readiness simultaneously.
> The service had zero available endpoints. Users saw 503 errors. The correct
> design: readiness only checks local state (startup complete, thread pool
> healthy). Dependencies are handled by circuit breakers in the app code.

*Push deeper:* "The successThreshold parameter: after readiness fails and the
pod is removed from endpoints, how many consecutive successes are required
to re-add it? Default is 1. For flapping services (repeatedly failing and
passing readiness), increase to 2 or 3 to prevent repeated endpoint churn."

---

### ⚖️ Comparison Table

| Probe | Action on Failure | Timing | What to Check |
|---|---|---|---|
| **startupProbe** | No restart (continues retrying) | Initial startup only | Can the app start at all? |
| **readinessProbe** | Remove from Service Endpoints | Every N seconds forever | Ready to serve traffic? |
| **livenessProbe** | Restart container | Every N seconds (after startup) | Alive and functional? |

**The deciding factor:** startupProbe protects startup. readinessProbe
controls traffic. livenessProbe triggers restart. A readiness failure
is traffic management. A liveness failure is a restart decision.
They solve different problems.

---

### ⚠️ Common Misconceptions

**"readinessProbe and livenessProbe check the same thing."**

They trigger different Kubernetes actions. Readiness: remove from Service
Endpoints (stop traffic). Liveness: restart the container. A temporarily
overloaded pod should fail readiness (stop traffic until recovered) but NOT
liveness (restart is unnecessary and disruptive for transient conditions).

**"initialDelaySeconds replaces startupProbe."**

initialDelaySeconds is a fixed delay before the first probe attempt. It
cannot adapt to variable startup times. If Spring Boot sometimes takes 30
seconds and sometimes 90 seconds (cold cache vs warm), a fixed delay either
waits too long (fast path) or fails (slow path). startupProbe retries until
success, adapting to actual startup time.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Missing startupProbe | Pod crash loop | Liveness failures before startup complete | Add startupProbe with adequate failureThreshold |
| readinessProbe checks DB | All pods removed from endpoints during DB issue | `/actuator/health/readiness` returns DOWN | Remove DB from readiness; use circuit breaker |
| livenessProbe too aggressive | Pods restart under load | Liveness failures at CPU spike | Increase failureThreshold * periodSeconds |
| Wrong probe path | Pod never becomes ready | `kubectl describe pod` shows probe failures | Verify actuator path with `kubectl exec curl` |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Three probe types, what each does |
| Mid | 6 min | Spring Actuator integration, interaction |
| Senior | 9 min | DB in readiness anti-pattern, liveness threshold |
| Staff | 9 min | Probe design philosophy, successThreshold |

---

**[SENIOR] Q1 - TRADE-OFF: Should your readiness probe
check downstream dependency (database) health?**

*Why they ask:* Design philosophy and production experience.

*Likely follow-up:* "What happens if all pods fail readiness simultaneously?"

Short answer: No. Readiness should reflect the pod's local health.

Argument FOR checking dependencies:
If the database is down and the app cannot serve requests, readiness
failure removes the pod from endpoints. Users see a clean 503 (service
unavailable) from the Ingress/load balancer instead of connection errors
from the pod.

Why this is WRONG for production:
The problem is at scale. If you have 20 pods and the database has a 10-second
connectivity blip: all 20 pods fail readiness simultaneously -> all 20 are
removed from Service Endpoints -> the Service has zero endpoints -> clients
get 503 from the load balancer during the DB issue.

If readiness only checks local state: during the DB blip, the pods stay
in the Endpoints. Requests arrive, hit the connection error, and return 503
from the application (with proper error handling). When the DB recovers
(10 seconds), everything works. No Kubernetes-level intervention needed.

The correct architecture:
- readiness probe checks: local state only (startup complete, thread pool
  accessible, no OOM condition)
- Database connection issues: handled by Resilience4j circuit breaker
  (open circuit after N failures, return 503 with fallback)
- Healthcheck endpoint: /actuator/health/readiness reflects Spring Availability
  state only

Exception: use dependency checks in readiness only during initial startup
(the first readiness check after startupProbe passes) to ensure connections
are established before traffic flows. Not on an ongoing basis.

*What separates good from great:* The "all pods fail simultaneously" scenario
- this is the key production risk that makes DB health in readiness dangerous.

---

**[SENIOR] Q2 - DEBUGGING: A Spring Boot pod is in
running state but never passes readiness. How do you
diagnose?**

*Why they ask:* Production probe debugging.

*Likely follow-up:* "What if the pod restarts before you can investigate?"

Systematic diagnosis approach:

Step 1: Check pod status and events
`kubectl describe pod <pod-name> -n <namespace>`
Look for:
- "Readiness probe failed: HTTP probe failed with statuscode: 404"
  -> Wrong probe path. The endpoint does not exist.
- "Readiness probe failed: Get http://...: dial tcp: connect refused"
  -> App not listening on the configured port.
- "Readiness probe failed: HTTP probe failed with statuscode: 503"
  -> App is returning 503 from the health endpoint.
- No probe failures shown -> probe may not have started (check startupProbe)

Step 2: Check readiness endpoint directly
`kubectl exec <pod-name> -- curl -v localhost:8080/actuator/health/readiness`
This tells you exactly what the endpoint returns. If it returns:
- 404: Spring Boot actuator not configured properly
  (missing management.endpoint.health.probes.enabled=true)
- 503: Spring Boot application is DOWN in ApplicationAvailability
  Check application logs for startup errors
- 200: Probe path is correct; check Kubernetes probe config port

Step 3: Check application logs
`kubectl logs <pod-name> --previous` (if pod restarted)
`kubectl logs <pod-name>` (current logs)
Look for: connection refused errors, bean initialization failures,
database connection failures.

Step 4: Verify Spring Boot configuration
`kubectl exec <pod-name> -- env | grep MANAGEMENT`
Ensure management.endpoint.health.probes.enabled=true is set.

*What separates good from great:* Using `kubectl exec curl` to test
the probe endpoint directly - isolating whether the issue is the
application endpoint or the Kubernetes probe configuration.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Java engineer | Spring | Actuator endpoints, probes.enabled config |
| SRE | Operations | Probe thresholds, failure scenarios |
| Platform engineer | Design | DB in readiness anti-pattern |
| Staff engineer | Architecture | Probe philosophy, successThreshold |

---
---

# Resource Requests and Limits

**Interview Weight:** high - Resource misconfiguration is one of the
top causes of production Kubernetes issues: OOMKilled pods, throttled
CPU, noisy neighbors, and failed scheduling. Every production Kubernetes
interview covers this.

---

### 🎯 Model Answer

**30 seconds:**

> Resource requests are what Kubernetes uses for scheduling (reserves
> capacity on a node). Resource limits are the hard ceiling (the pod is
> killed if memory exceeds the limit; CPU is throttled). For Java services:
> always set memory requests equal to limits (avoid OOMKilled from JVM heap
> growth), set CPU requests to typical usage, and set CPU limits conservatively
> or avoid them entirely (CPU limits cause throttling, not OOM).

**3 minutes (Senior):**

> The distinction between requests and limits is fundamental for Kubernetes
> scheduling and node health.
>
> Requests: used by the scheduler to find a node with sufficient available
> capacity. If you request 500m CPU and 512Mi memory, the scheduler only
> places the pod on a node that has 500m unallocated CPU and 512Mi unallocated
> memory. Requests do NOT limit the pod's actual consumption - they are
> reservations.
>
> Limits: enforced at the cgroup level by the kernel. Memory limit exceeded:
> the process receives SIGKILL (OOMKilled). CPU limit exceeded: the process
> is CPU-throttled (paused by the kernel scheduler). CPU throttling is
> insidious: the pod keeps running, appears healthy to probes, but latency
> increases dramatically.
>
> QoS classes: Guaranteed (requests == limits for all containers), Burstable
> (requests < limits or only one set), BestEffort (no requests or limits).
> The kubelet evicts pods under node memory pressure in this order: BestEffort
> first, then Burstable, then Guaranteed. For production: always use Guaranteed
> or Burstable with appropriate values.
>
> Java-specific: JVM heap grows to its -Xmx limit. Set container memory limit
> >= -Xmx + overhead (off-heap, metaspace, thread stacks, native memory).
> Rule of thumb: memory limit = -Xmx * 1.25-1.5. Or use MaxRAMPercentage=75.0
> and set requests == limits so the JVM self-configures within the container limit.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kubernetes resource requests and limits -
how to configure CPU and memory for pods."

**(2) First principles:** "Scheduling needs to know what to reserve (requests).
Isolation needs a hard ceiling (limits). They serve different purposes."

**(3) Bridge:** "Requests are your seat reservation at a restaurant (guarantees
a place). Limits are the maximum table size (hard ceiling)."

---

### 📘 Concept Explanation

**What it is:**
Resource requests specify the guaranteed allocation reserved during scheduling.
Resource limits enforce the maximum consumption allowed. Together they define
the pod's resource profile for both scheduling and runtime enforcement.

**The problem it solves:**
Without requests: the scheduler cannot place pods efficiently, leading to
overcommitted nodes (OOM node-level) or underutilized nodes. Without limits:
one pod can consume all node resources, starving other pods.

**How it works:**

```
Requests vs Limits:

  requests:       # Scheduling guarantee
    memory: "512Mi"  # Reserve 512Mi on node
    cpu: "250m"      # Reserve 0.25 core on node

  limits:         # Runtime ceiling
    memory: "1Gi"    # Kill if > 1Gi (SIGKILL)
    cpu: "500m"      # Throttle if > 0.5 core

QoS Classes (node eviction priority):
  Guaranteed: requests == limits (evicted last)
    requests.memory == limits.memory
    requests.cpu == limits.cpu

  Burstable: requests < limits (middle priority)
    Common for apps with variable usage

  BestEffort: no requests, no limits (evicted first)
    Never use for production workloads

CPU Throttling Mechanism:
  Linux cfs_quota_us limits CPU time per period
  Pod uses 500m limit = 50% of 1 core per 100ms period
  If pod uses 55ms CPU in first 55ms of period:
    -> Pod throttled for remaining 45ms of period
    -> High latency even though CPU is "available"
  Effect: p99 latency increases under CPU limits
```

**The key insight:**
CPU throttling from CPU limits causes latency but NOT crash or restart.
This makes it hard to diagnose. The pod is "running", probes pass, but
p99 latency is elevated. `kubectl top pod` shows CPU usage below the
limit (because throttled time is not counted as usage). The real indicator
is `container_cpu_cfs_throttled_seconds_total` in Prometheus.

**When to set CPU limits:**
In development/testing environments (prevent runaway processes). In production:
set generous limits (3-4x requests) or omit CPU limits entirely and rely on
node-level resource management.

**First-principles derivation:**
The Linux kernel uses cgroups for resource enforcement. Memory: tracked per
page allocation; OOM killer fires when cgroup memory limit exceeded. CPU:
CFS (Completely Fair Scheduler) uses quota (time allowed per period). These
kernel mechanisms are what Kubernetes limits map to. Understanding the
kernel mechanism explains why CPU limits cause throttling (quota exhausted)
while memory limits cause OOM kill (no page allocations permitted).

---

### 💻 Code Example

**Example 1: BAD vs GOOD resource configuration for Java**

```yaml
# BAD: No resource limits (BestEffort)
# Problem: JVM grows heap without limit
# -> Node runs out of memory -> Node OOM
# -> All pods on node killed (including others)
containers:
- name: app
  image: payment-service:v1.0
  # No resources section

---
# BAD: Memory limit too low for JVM
# Problem: JVM heap + off-heap > limit
# -> OOMKilled every few hours
containers:
- name: app
  image: payment-service:v1.0
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"  # Too small: Xmx=512Mi + overhead
      cpu: "200m"      # Too small: causes throttling

---
# GOOD: Properly sized Java resources
# MaxRAMPercentage=75.0 -> JVM uses 75% of limit
# 1Gi limit -> heap=~768Mi, leaving 256Mi for overhead
containers:
- name: app
  image: payment-service:v2.0
  resources:
    # Guaranteed QoS: requests == limits
    # Prevents eviction under node memory pressure
    requests:
      memory: "1Gi"
      cpu: "250m"     # typical usage in steady state
    limits:
      memory: "1Gi"   # = requests -> Guaranteed QoS
      cpu: "1000m"    # generous limit (4x requests)
                      # reduces throttling under spike
  env:
  - name: JAVA_OPTS
    value: >-
      -XX:MaxRAMPercentage=75.0
      -XX:InitialRAMPercentage=50.0
      -XX:+UseContainerSupport
```

> **Code walkthrough:** The BestEffort (no resources) configuration lets
> the JVM grow its heap to the JVM default (typically 25% of total system
> RAM). On a 32GB node, that is 8GB per pod. Three pods can exhaust the
> node, triggering Linux OOM killer. The too-small configuration uses
> 512Mi memory limit but JVM overhead (metaspace, thread stacks, JIT
> compilation, NIO buffers) typically adds 256-512Mi on top of heap. The
> result is OOMKilled containers. The GOOD configuration uses Guaranteed
> QoS (requests == limits), sets the limit to accommodate heap + overhead,
> and uses MaxRAMPercentage=75.0 so the JVM self-configures heap as 75%
> of the container memory limit (768Mi heap in a 1Gi limit container).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Requests reserve capacity on a node for scheduling. Limits are hard ceilings.
> Memory: exceeding the limit causes OOMKilled. CPU: exceeding the limit causes
> throttling (latency, not kill). For Java: set memory limit high enough for
> JVM heap + overhead, or use MaxRAMPercentage=75.0 with requests == limits.

*Push deeper:* "Guaranteed QoS class (requests == limits) is important for
production Java services. When the node is under memory pressure, Kubernetes
evicts BestEffort pods first, then Burstable. Guaranteed pods are evicted last.
A production Java service with variable heap usage that bursts past the
request value (Burstable) is vulnerable to eviction during node memory pressure."

---

**Senior / Staff (5+ years):**

> The practical approach I use for Java microservices:
> (1) Memory: set requests == limits (Guaranteed QoS). Use MaxRAMPercentage=75.0.
>     Memory limit = target heap / 0.75. For 512Mi heap: limit = 682Mi, round up
>     to 768Mi. This leaves 25% for off-heap.
> (2) CPU: set requests to typical steady-state usage (measured from Prometheus
>     `container_cpu_usage_seconds_total`). Set limits to 3-4x requests.
>     Never set CPU limits to requests - this causes throttling on any spike.
> (3) Vertical Pod Autoscaler in recommendation mode: run for 2-4 weeks to
>     get actual usage data, then set requests based on VPA recommendations.

*Push deeper:* "CPU throttling is the silent killer. `container_cpu_cfs_throttled_seconds_total`
metric divided by `container_cpu_cfs_periods_total` gives the throttle ratio. If
> 25% of CPU periods are throttled, latency is significantly affected. Many
engineers only look at CPU utilization and miss throttling. Throttling and
utilization are orthogonal: a pod can be at 30% CPU utilization but 80%
of periods throttled (because the limit was set to match the average, not
the burst)."

---

### ⚖️ Comparison Table

| QoS Class | Config | Eviction Priority | Use Case |
|---|---|---|---|
| **Guaranteed** | requests == limits | Last | Production services, stateful |
| **Burstable** | requests < limits | Middle | Dev workloads, batch jobs |
| **BestEffort** | No requests/limits | First | Lowest priority jobs |

**The deciding factor:** Guaranteed for all production services. The predictable
behavior (not evicted under node pressure, no CPU throttle from request mismatch)
outweighs the slightly reduced resource efficiency.

---

### ⚠️ Common Misconceptions

**"CPU requests limit CPU usage."**

CPU requests are scheduling reservations, not runtime limits. The kubelet
does not throttle CPU usage at the request level. Only CPU limits (cfs_quota)
throttle actual CPU consumption. A pod with request: 100m and no limit can
use all available CPU on the node.

**"Setting memory limits prevents all OOM situations."**

Container memory limits enforce the container's memory. If the JVM uses
memory outside the heap (metaspace, code cache, thread stacks, native memory),
this also counts against the container limit. A container can OOMKilled even
if the JVM heap is within Xmx if total process memory (heap + off-heap) exceeds
the container limit.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| OOMKilled | Pod restarts; `kubectl describe pod` shows OOMKilled | `kubectl get pod -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'` | Increase memory limit; check MaxRAMPercentage |
| CPU throttling | High p99 latency; CPU looks fine in dashboard | `container_cpu_cfs_throttled_seconds_total > 25%` | Increase CPU limit or remove limit |
| Overcommit OOM | Pods evicted from node | `kubectl get events --field-selector reason=Evicted` | Add resource requests to Burstable/BestEffort pods |
| BestEffort eviction | Production pod evicted under load | No resource requests configured | Add requests/limits; use Guaranteed QoS |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Requests vs limits, OOMKilled |
| Mid | 6 min | QoS classes, Java sizing |
| Senior | 9 min | CPU throttling, MaxRAMPercentage formula |
| Staff | 9 min | VPA, throttle ratio metrics, production tuning |

---

**[SENIOR] Q1 - How do you size memory resources
for a Spring Boot Java service in Kubernetes?**

*Why they ask:* Java-specific resource management.

*Likely follow-up:* "What is the formula for heap vs container limit?"

JVM memory in a container has multiple regions:

Container memory = Heap + Off-heap

Heap: controlled by -Xmx (or -XX:MaxRAMPercentage)
Off-heap: Metaspace, Code Cache, Thread stacks, NIO buffers, JNI

Sizing formula:
1. Use MaxRAMPercentage=75.0 (sets heap = 75% of container limit)
2. Container memory limit = desired heap / 0.75

Example: target heap 512Mi
  limit = 512Mi / 0.75 = 682Mi, round to 768Mi
  Heap: ~576Mi (75% of 768Mi)
  Off-heap reserve: ~192Mi (25%)

Verification:
`kubectl exec <pod> -- java -XX:MaxRAMPercentage=75.0
  -XX:+PrintFlagsFinal -version 2>&1 | grep HeapSize`
Shows actual MaxHeapSize.

Monitoring heap usage:
`kubectl exec <pod> -- curl localhost:8080/actuator/metrics/jvm.memory.max`
If heap usage approaches Xmx: pod is at risk of OOM -> increase limit

For services with variable heap (batch jobs, large request processing):
Set limits = 1.5x * typical peak
Monitor GC frequency (jvm.gc.pause via Micrometer)
If full GC happening frequently: heap is undersized

*What separates good from great:* The formula limit = target_heap / 0.75
and knowing how to verify the actual heap size at runtime.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Java engineer | JVM sizing | MaxRAMPercentage formula, heap vs off-heap |
| SRE | Operations | QoS classes, OOMKilled diagnosis |
| Platform engineer | Cluster health | CPU throttling, noisy neighbors |
| Staff engineer | Optimization | VPA, throttle metrics |

---
---

# Horizontal Pod Autoscaler

**Interview Weight:** high - HPA is the primary auto-scaling mechanism
for Kubernetes workloads. Interviewers test understanding of the scaling
algorithm, metric types, and common pitfalls for Java services.

---

### 🎯 Model Answer

**30 seconds:**

> HPA (Horizontal Pod Autoscaler) automatically scales pod count based on
> observed metrics. It computes: desired replicas = ceil(currentReplicas *
> currentMetricValue / targetMetricValue). Default metric: CPU utilization
> (relative to requests). The HPA checks metrics every 15 seconds and scales
> up fast, scales down slowly (default: 5-minute stabilization window). For
> Java services: CPU is a reasonable signal, but queue depth or request rate
> is more accurate for bursty workloads.

**3 minutes (Senior):**

> HPA v2 (autoscaling/v2) supports multiple metric types: Resource (CPU/memory),
> Pods (custom per-pod metric), Object (metric from a Kubernetes object like
> an Ingress), and External (metrics from outside the cluster, like SQS queue
> depth).
>
> The scaling algorithm: desired = ceil(current * currentValue / target). For
> CPU: if target is 70% utilization and current is 3 pods at 90% average, then
> desired = ceil(3 * 90 / 70) = 4 pods.
>
> Scale-up behavior: no stabilization window by default. HPA scales up
> immediately when the metric exceeds the target. This is intentional - scale
> up quickly to handle load.
>
> Scale-down behavior: default 5-minute stabilization window. HPA waits 5
> minutes of sustained low metrics before scaling down. This prevents scale
> oscillation (scale up, then immediately scale down as the new pods absorb load).
>
> Java-specific considerations: CPU-based HPA is sensitive to JVM warm-up.
> Cold JVM pods show low CPU until the JIT compiler kicks in. During scale-up,
> new pods may show artificially low CPU, causing the HPA to scale up fewer
> pods than needed. JVM warm-up delay (initialDelaySeconds for HPA metric
> collection) can help.
>
> Better metrics for Java: HTTP request rate per pod (via Prometheus adapter)
> scales better than CPU because CPU usage is not linear with load for
> JVM-heavy services (GC pauses, JIT compilation skew the signal).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about HPA - how Kubernetes automatically
scales pod count based on metrics."

**(2) First principles:** "Scaling is a feedback loop. Current load exceeds
capacity -> add pods. Load is low -> remove pods. The HPA is this feedback
loop with configurable targets and stabilization."

**(3) Bridge:** "HPA is like a call center manager: if the average hold time
exceeds the target, hire more agents. If hold times are consistently low,
reduce staff. But wait 5 minutes before firing anyone to avoid reacting to
a brief slow period."

---

### 📘 Concept Explanation

**What it is:**
The Horizontal Pod Autoscaler is a Kubernetes controller that automatically
adjusts the number of pod replicas based on observed metrics (CPU, memory,
custom metrics) to match desired resource utilization.

**The problem it solves:**
Static pod counts waste resources at low load and fail under high load.
HPA provides automatic, metrics-driven scaling that maintains target
utilization while respecting min/max replica boundaries.

**How it works:**

```
HPA Algorithm:

desiredReplicas = ceil(
  currentReplicas *
  (currentMetricValue / desiredMetricValue)
)

Example (CPU-based):
  Current: 3 pods, 90% CPU avg, target: 70%
  Desired = ceil(3 * (90/70)) = ceil(3.86) = 4 pods

HPA Scaling Policies:
  Scale-Up:   Immediate (no stabilization default)
              Default: add max(4, 100%) pods per minute
  Scale-Down: 5-minute stabilization window
              Waits for 5 min of sustained low metrics

Metric Types (v2):
  Resource:  CPU/memory relative to requests
  Pods:      custom metric averaged per pod
  Object:    metric from K8s object (Ingress)
  External:  metric outside cluster (SQS depth)

Architecture:
  HPA Controller
    -> metrics-server (Resource metrics)
    -> custom-metrics-api (Pods/Object metrics)
    -> external-metrics-api (External metrics)
```

**The key insight:**
The HPA algorithm uses the ratio of current/desired metric, not the absolute
value. This means the scale factor is proportional to how far the metric
deviates from the target. A 200% CPU (when target is 100%) doubles the
pod count. The ceil() ensures we round up (prefer over-provisioning to
under-provisioning).

**When custom metrics are better than CPU:**
Queue depth (message queue consumers): scale based on queue depth / target
depth per pod. Request rate (HTTP services): scale based on RPS per pod.
Both correlate more directly with required capacity than CPU (which includes
GC time, JIT compilation, and other JVM overhead unrelated to request load).

**First-principles derivation:**
Auto-scaling requires: (1) a desired state (target metric), (2) current
state measurement (metrics API), (3) an action to close the gap (replica
adjustment), (4) stability to prevent oscillation (stabilization window).
HPA implements all four components.

---

### 💻 Code Example

**Example 1: CPU-based and custom metric HPA for Spring Boot**

```yaml
# Basic CPU-based HPA (autoscaling/v2)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: payment-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payment-service
  minReplicas: 3   # Never scale below 3
  maxReplicas: 20  # Hard cap
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Target: 70% avg CPU

---
# Advanced: Multi-metric HPA + custom scaling policy
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: payment-service-hpa-advanced
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: payment-service
  minReplicas: 3
  maxReplicas: 20
  metrics:
  # Primary: HTTP request rate per pod
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "100"   # 100 RPS per pod target
  # Secondary: CPU as fallback
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30  # Fast scale-up
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60    # Double pods per minute max
    scaleDown:
      stabilizationWindowSeconds: 300 # 5 min stabilization
      policies:
      - type: Pods
        value: 2
        periodSeconds: 60   # Remove max 2 pods per minute
```

> **Code walkthrough:** The basic CPU HPA scales between 3 and 20 replicas
> targeting 70% CPU utilization. When CPU averages 90% across all pods,
> the algorithm computes ceil(3 * 90/70) = 4 replicas and schedules an
> additional pod. The advanced HPA uses HTTP request rate as the primary
> metric (100 requests per second per pod target) - more directly correlated
> with load than CPU. The behavior section configures asymmetric scaling:
> fast scale-up (30-second window, can double pods per minute) to handle
> traffic spikes, and slow scale-down (5-minute window, max 2 pods/minute)
> to prevent oscillation.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> HPA automatically scales pod count based on metrics. The most common metric
> is CPU utilization: set a target (70%), and HPA adds pods when average CPU
> exceeds that target, removes pods when CPU drops below it. minReplicas and
> maxReplicas bound the scaling range. HPA uses metrics-server for CPU metrics.

*Push deeper:* "HPA requires resource requests to be set on pods for CPU
utilization metrics. The 70% target means: when average CPU across pods
hits 70% of their requested CPU, scale up. Without resource requests defined,
the CPU utilization percentage cannot be computed - HPA reports unknown
metrics and does not scale."

---

**Senior / Staff (5+ years):**

> For Java services, the HPA metric choice matters significantly. CPU-based
> HPA has a cold-start problem: new pods have cold JVM (JIT not warmed up).
> They show low CPU initially, so the HPA may not add enough pods to handle
> the load until the new pods warm up. This can cause a brief under-provisioned
> state during fast traffic growth.
>
> Preferred approach for Java: HTTP request rate via Prometheus adapter with
> KEDA (Kubernetes Event Driven Autoscaler). KEDA supports external metrics
> natively (Kafka lag, SQS depth, HTTP RPS from Prometheus). HTTP request rate
> scales proportionally to actual work being done, independent of JVM state.
>
> Scale-to-zero: KEDA supports scaling to zero replicas (HPA minimum is 1).
> For batch Java services or event-driven services that have zero traffic at
> night: scale-to-zero saves significant cost. Deploy a lightweight "wake up"
> handler (KEDA HTTP add-on) that starts pods when a request arrives.

*Push deeper:* "The VPA (Vertical Pod Autoscaler) and HPA should not both
manage the same resource. If VPA adjusts memory requests upward and HPA
targets memory utilization: they fight each other (VPA increases request,
utilization drops, HPA removes pods, utilization rises, VPA stays, HPA
re-adds pods). Use HPA for horizontal scaling, VPA for right-sizing requests
in off-peak analysis mode."

---

### ⚖️ Comparison Table

| Metric Type | Pros | Cons | Best For |
|---|---|---|---|
| **CPU (Resource)** | No extra tools needed | JVM warm-up skew, GC interference | General purpose |
| **HTTP RPS (Pods)** | Direct correlation to load | Requires Prometheus adapter | HTTP services |
| **Queue depth (External)** | Perfect for consumers | Requires KEDA or custom adapter | Kafka, SQS consumers |
| **Custom (Pods)** | Any per-pod metric | Setup complexity | Domain-specific scaling |

**The deciding factor:** CPU for services with CPU-linear workloads. HTTP RPS
or queue depth for services where CPU does not linearly correlate with request
load (JVM-heavy, I/O-bound, or batch workloads).

---

### ⚠️ Common Misconceptions

**"HPA scales immediately to the calculated replica count."**

HPA applies scaling policies that may limit the rate of change. Scale-up
default: add max(4, 100%) pods per minute. Scale-down has a 5-minute
stabilization window. The transition to the computed replica count is
gradual, not instant.

**"Setting maxReplicas high is always safe."**

High maxReplicas can overload downstream dependencies. If payment-service
scales to 50 replicas and the database connection pool supports 100 connections,
50 * (pool size per pod) connections can exhaust the database. Always consider
downstream capacity when setting maxReplicas.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| HPA not scaling | High CPU, pod count static | `kubectl describe hpa` shows unknown metrics | Install metrics-server; check resource requests |
| Rapid scale oscillation | Pod count fluctuates frequently | HPA events show frequent scale up/down | Increase stabilizationWindowSeconds for scale-down |
| Under-scaling on Java | Slow scale-up during traffic spike | HPA adds pods but CPU stays high (JVM cold) | Add preemptive scaling; use KEDA with RPS metric |
| Downstream overload | DB errors after HPA scale-up | DB connection errors after scale | Reduce maxReplicas; use DB connection pooling (PgBouncer) |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | How HPA works, CPU metric |
| Mid | 6 min | Metric types, scale-up vs scale-down |
| Senior | 9 min | Java cold-start problem, KEDA |
| Staff | 9 min | VPA conflict, downstream capacity |

---

**[MID] Q1 - What happens to HPA if resource requests
are not set on pods?**

*Why they ask:* Common production misconfiguration.

*Likely follow-up:* "What error will you see in kubectl describe hpa?"

HPA with CPU utilization metric requires resource requests:

Why requests are required:
CPU utilization is a percentage of the requested CPU. The formula:
utilization = actualCPU / requestedCPU * 100%
If requests.cpu is not set, the denominator is undefined.
HPA cannot compute the utilization percentage.

Observed behavior:
`kubectl describe hpa payment-service-hpa`
Shows:
  Metrics:    ( unknown / 70% )
  Warning: unable to get metrics for resource cpu:
  unable to fetch metrics from resource metrics API

The HPA will not scale based on unknown metrics. Pod count stays at
the current replica count regardless of actual CPU load.

Fix: Set resource requests on all containers managed by the HPA.
```yaml
resources:
  requests:
    cpu: "250m"   # Required for CPU utilization HPA
```

Related issue: if some pods in the deployment have requests and some
do not (mixed configuration from partial rollout), the average is computed
only for pods with requests. This gives an inaccurate average and
unpredictable HPA behavior.

Best practice: always set resource requests before enabling HPA.
Use LimitRange to enforce requests as a namespace default:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-resource-requirements
spec:
  limits:
  - type: Container
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
```

*What separates good from great:* Knowing the exact error message and
the LimitRange solution to enforce requests namespace-wide.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Java engineer | Practical | CPU metric, cold-start issue |
| SRE | Operations | Metric types, scale behavior |
| Platform engineer | Architecture | KEDA, VPA conflict |
| Staff engineer | Strategy | Cost optimization, scale-to-zero |

---
---

# Rolling Updates and Rollback Strategies

**Interview Weight:** high - Zero-downtime deployments are a core
operational requirement. Understanding the mechanics, pitfalls, and
advanced strategies (blue-green, canary) demonstrates production maturity.

---

### 🎯 Model Answer

**30 seconds:**

> Kubernetes rolling updates gradually replace old pods with new pods
> while maintaining the configured minimum availability. maxUnavailable: 0
> ensures zero downtime (all old pods stay running until new pods pass
> readiness). maxSurge: 1 allows one extra pod during the transition. If
> a rollout fails, kubectl rollout undo reverts to the previous ReplicaSet
> in seconds. For high-risk changes: blue-green or canary deployment
> (via Argo Rollouts) provides more controlled rollout.

**3 minutes (Senior):**

> Rolling updates are the default Kubernetes deployment strategy. The rollout
> controller implements the strategy parameters: maxUnavailable and maxSurge.
>
> The rollout gate is the readiness probe. For each new pod, Kubernetes waits
> until it passes readiness (and minReadySeconds additional time) before
> proceeding with the next old pod termination. This ensures traffic is
> never disrupted: old pods are terminated only after new pods are confirmed
> ready.
>
> A rollout fails if new pods do not pass readiness within progressDeadlineSeconds
> (default: 600 seconds). The Deployment reports a "progress deadline exceeded"
> condition. In production: kubectl rollout undo immediately reverts.
>
> Blue-green deployment: maintain two complete environments (blue and green).
> Route all traffic to blue. Deploy new version to green. Verify green. Switch
> traffic (Ingress rule change) atomically to green. Rollback is instant (switch
> traffic back to blue, which still runs). Downside: double resource cost during
> transition.
>
> Canary deployment (Argo Rollouts): route small percentage of traffic (5%)
> to new version. Monitor error rate and latency. Gradually increase percentage
> (5% -> 20% -> 50% -> 100%). Automatic rollback if error rate exceeds threshold.
> This is the safest strategy for user-facing services with changing behavior.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about rolling updates and how to roll back
when a deployment fails."

**(2) First principles:** "Safe deployment requires never having zero serving
capacity. Rolling updates maintain a minimum number of serving pods. Rollback
requires keeping the previous version available."

**(3) Bridge:** "Rolling update is like renovating an office one floor at a
time: never close all floors simultaneously. Keep the old floors serving
while the new floors are being finished."

---

### 📘 Concept Explanation

**What it is:**
Rolling updates gradually replace old pod instances with new ones while
maintaining service availability, using readiness probes as the health gate
and the previous ReplicaSet for instant rollback.

**The problem it solves:**
Deploying new code requires replacing running pods. Doing this all at once
causes downtime. Rolling updates replace pods incrementally, maintaining
availability throughout.

**How it works:**

```
Rolling Update Sequence:
  Initial: 3 pods running v1.0
  Strategy: maxUnavailable: 0, maxSurge: 1

  Step 1: Create 1 new pod (v2.0)
    [v1.0] [v1.0] [v1.0] [v2.0-pending]
    Total: 4 pods (3+1 surge)

  Step 2: Wait for v2.0 to pass readiness
    [v1.0] [v1.0] [v1.0] [v2.0-ready]

  Step 3: Terminate 1 old pod (v1.0)
    [v1.0] [v1.0] [GONE] [v2.0-ready]
    Total: 3 pods again

  Step 4: Create next new pod, repeat...
    Until all 3 pods are v2.0

  Rollback: kubectl rollout undo
    Old ReplicaSet (v1.0) still exists (0 replicas)
    Scale old ReplicaSet to 3
    Scale new ReplicaSet to 0
    -> Instant revert (same image, no rebuild)

Advanced Strategies:
  Blue-Green:
    Route: Traffic -> Blue (v1.0)
    Deploy: Green (v2.0) [full new deployment]
    Verify: Green passes health checks
    Switch: Traffic -> Green (Ingress change)
    Keep: Blue available for instant rollback

  Canary (Argo Rollouts):
    Step 1: Route 5% traffic to v2.0
    Step 2: Monitor metrics (error rate < 1%)
    Step 3: Route 20%, 50%, 100% progressively
    Auto-rollback: if error rate > threshold
```

**The key insight:**
Kubernetes rolling updates rely on the readiness probe as the safety gate.
Without readiness probes, Kubernetes considers a pod "ready" as soon as the
container is running (regardless of whether Spring Boot has finished
initializing). This causes traffic to be routed to pods that cannot serve
requests. Readiness probe is not optional for rolling updates.

**When to use blue-green:**
When you need instant rollback capability (payment services, auth services
where even 1% error is unacceptable). When the new version has a schema
migration that makes simultaneous old+new version operation impossible.

**When to use canary:**
User-facing features, A/B testing, gradual traffic migration, when
you need real-user validation before full rollout.

**First-principles derivation:**
Zero-downtime deployment requires capacity to always exceed demand. During
a rolling update with maxUnavailable: 0, total capacity never decreases:
you add a new pod before removing an old pod. Capacity temporarily increases
(surge), then returns to normal after the transition.

---

### 💻 Code Example

**Example 1: Rolling update with proper health gate configuration**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0   # Never lose availability
      maxSurge: 1         # One extra pod during rollout
  # Require pods stable for 10s before proceeding
  minReadySeconds: 10
  # Fail deployment if not complete in 10 min
  progressDeadlineSeconds: 600
  # Keep 5 previous ReplicaSets for rollback
  revisionHistoryLimit: 5
  template:
    spec:
      containers:
      - name: app
        image: payment-service:v2.1.0
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          periodSeconds: 5
          failureThreshold: 3
```

```bash
# Monitor rollout progress
kubectl rollout status deployment/payment-service \
  --timeout=300s

# Pause rollout if issues detected
kubectl rollout pause deployment/payment-service

# Resume after investigation
kubectl rollout resume deployment/payment-service

# Rollback to previous version
kubectl rollout undo deployment/payment-service

# Rollback to specific revision
kubectl rollout undo deployment/payment-service \
  --to-revision=3

# View rollout history
kubectl rollout history deployment/payment-service
# REVISION  CHANGE-CAUSE
# 1         Initial: v2.0.0
# 2         feat: retry logic v2.1.0
# 3         fix: payment timeout v2.1.1
```

> **Code walkthrough:** maxUnavailable: 0 ensures zero downtime by
> requiring all original pods to remain serving throughout the rollout.
> minReadySeconds: 10 adds a stabilization gate: after a pod passes
> readiness, Kubernetes waits an additional 10 seconds before considering
> it stable. This prevents flapping readiness (passes for 1 second, then
> fails) from being treated as stable. progressDeadlineSeconds: 600 fails
> the deployment if rollout does not complete in 10 minutes - triggering
> alerts rather than silently stalling. The kubectl rollout commands
> provide operational control: pause, resume, undo, and history.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Rolling updates gradually replace pods: create a new pod, wait for it to
> pass readiness, then terminate an old pod, repeat. maxUnavailable: 0 means
> no downtime. kubectl rollout undo reverts to the previous version using the
> saved ReplicaSet.

*Push deeper:* "The change-cause annotation in kubectl annotate deployment
is important for audit trails. kubectl rollout history shows revision history,
and the CHANGE-CAUSE column comes from the kubernetes.io/change-cause
annotation. Without it, revision history shows no context about what changed."

---

**Senior / Staff (5+ years):**

> For high-risk changes (API contract changes, DB schema changes), rolling
> update with readiness gate is not sufficient. The issue: during the rollout,
> you have both v1.0 and v2.0 pods serving traffic simultaneously. If the
> API contract changes are not backward compatible, some requests go to v1.0
> (old behavior) and some to v2.0 (new behavior).
>
> Solutions: (1) Backward-compatible changes only during rolling updates.
> (2) Blue-green for breaking changes (atomic traffic switch). (3) Argo
> Rollouts with traffic management (all traffic stays on v1.0, 5% canary
> on v2.0, analyze, then fully switch).
>
> The most important operational habit: set kubectl annotate deployment
> with a change-cause before each update. Three months later, when you
> need to rollback to a specific revision, the history is readable.

*Push deeper:* "Deployment pause mid-rollout is underutilized. During a
large rollout (200 pods, 20 minutes), if you see elevated error rates after
the first 20 pods, kubectl rollout pause stops the rollout immediately.
You then have time to analyze: are the first 20 new pods causing errors?
Is it just one pod? Can you fix forward? Then resume or undo."

---

### ⚖️ Comparison Table

| Strategy | Downtime | Resource Overhead | Rollback Speed | Risk |
|---|---|---|---|---|
| **Rolling (default)** | None | +1 pod (maxSurge) | Seconds | Mixed old+new traffic |
| **Recreate** | Yes | None | Seconds | Full downtime |
| **Blue-Green** | None | 2x full deployment | Instant (traffic switch) | Double cost |
| **Canary (Argo)** | None | Small canary set | Per-step rollback | Complexity |

**The deciding factor:** Rolling for standard changes. Blue-green for
breaking API/schema changes requiring atomic switch. Canary for user-facing
changes needing gradual validation.

---

### ⚠️ Common Misconceptions

**"kubectl rollout undo rebuilds the old image."**

kubectl rollout undo reactivates the previous ReplicaSet (still present with
0 replicas). The pod template from the previous deployment is already stored
in the ReplicaSet. Rollback is instant because no build or pull is needed.

**"maxUnavailable: 0 guarantees zero errors during rolling update."**

maxUnavailable: 0 prevents availability gaps in the Kubernetes resource model.
But traffic to the new version can still fail if the new version has bugs.
readiness gates errors at pod health level. Application-level correctness
requires additional strategies (canary analysis, smoke tests).

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Rollout stalled | New pods stuck in Pending | `kubectl describe pod` shows resource or scheduling issue | Fix resource issue; pause/resume; undo |
| Rollout fails readiness | New pods Running but not Ready | `kubectl describe pod` shows readiness failures; `kubectl logs` | Fix app bug; kubectl rollout undo |
| Progress deadline exceeded | Deployment condition: DeadlineExceeded | `kubectl describe deployment` | Investigate pod failures; rollback |
| Mixed version errors | Intermittent errors during rollout | Traffic going to both versions; API incompatibility | Use blue-green for incompatible changes |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Rolling update mechanics, kubectl undo |
| Mid | 6 min | Strategy parameters, rollout history |
| Senior | 9 min | Mixed version issues, pause/resume |
| Staff | 9 min | Blue-green vs canary, Argo Rollouts |

---

**[MID] Q1 - TRADE-OFF: What are the risks of rolling
updates and when should you use blue-green instead?**

*Why they ask:* Strategy selection judgment.

*Likely follow-up:* "How do you make DB schema changes with rolling updates?"

Rolling update risks:

Mixed-version traffic:
During the rollout, both v1.0 and v2.0 pods serve traffic simultaneously.
If the API contract changed (new response field, changed error codes),
clients may receive inconsistent responses depending on which pod handles
the request. This is a hidden risk that many teams discover in production.

Stateful concern:
Sessions, caches, and in-flight transactions may behave differently when
requests are split between versions. If v2.0 changes session serialization
format, sessions created by v1.0 may not be readable by v2.0.

When to use blue-green:
(1) Breaking API changes that affect external clients
(2) DB schema migrations that make old + new incompatible
(3) When you need sub-second rollback (blue-green is an Ingress routing change)
(4) Regulatory requirements for zero-error transitions

DB schema change pattern with rolling updates (expand-contract):
Phase 1 (v1.0 with migration): add new nullable column to DB.
  v1.0 writes to old column only. DB has both old + new.
Phase 2 (v2.0 rolling update): app uses new column.
  Both v1.0 (being removed) and v2.0 work with the schema.
Phase 3 (v3.0 cleanup): remove old column once v1.0 is gone.

This expand-contract pattern makes rolling updates safe for schema changes.
Blue-green bypasses the need for this but requires double resources.

*What separates good from great:* The expand-contract pattern for DB
schema changes - this is the production-validated approach to database
migrations during rolling updates.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Backend engineer | Practical | kubectl commands, history, undo |
| SRE | Operations | Stalled rollout diagnosis, pause/resume |
| Platform engineer | Strategy | Argo Rollouts, blue-green setup |
| Staff engineer | Architecture | Mixed-version risk, DB schema patterns |

---
---

# Jobs CronJobs and Batch Processing

**Interview Weight:** medium - Batch and scheduled workloads are common
in Java backends. Interviewers test understanding of Job completion semantics,
retry behavior, and when to use Jobs vs CronJobs vs persistent services.

---

### 🎯 Model Answer

**30 seconds:**

> A Kubernetes Job runs a pod to completion (success or failure). It handles
> retries (backoffLimit), parallelism (parallel batch processing), and
> completion tracking. A CronJob creates Jobs on a schedule (cron expression).
> For Java batch jobs: the Job's backoffLimit and activeDeadlineSeconds prevent
> infinite retry loops. The completion mode (indexed) enables parallel batch
> processing where each pod handles a portion of the dataset.

**3 minutes (Senior):**

> Jobs differ from Deployments in a fundamental way: Deployments run pods
> indefinitely (restartPolicy: Always). Jobs run pods to completion (restartPolicy:
> OnFailure or Never). When all pods complete successfully, the Job is done.
>
> Parallelism: Job has two settings: completions (how many successful pod
> completions required) and parallelism (how many pods run simultaneously).
> For batch processing: set completions to the number of items to process
> and parallelism to the desired concurrency level.
>
> Indexed completion mode: each pod receives a unique index (0 to completions-1)
> via the JOB_COMPLETION_INDEX env var. Each pod processes a specific shard
> of the dataset. This is the recommended pattern for parallel batch processing:
> pod 0 processes items 0-1000, pod 1 processes items 1001-2000, etc.
>
> CronJob management: the CronJob creates a new Job on each schedule. Old
> Jobs are retained (default: 3 successful, 1 failed) for debugging. CronJobs
> have concurrencyPolicy: Allow (run even if previous is still running), Forbid
> (skip if previous is running), Replace (kill previous, start new).
>
> For Java Spring Batch: Kubernetes Jobs integrate naturally. The Spring Batch
> Job is triggered at container startup (main method runs the batch job). The
> pod exits 0 on success, non-0 on failure. Kubernetes handles the retry logic
> via backoffLimit, replacing the need for a separate retry mechanism.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kubernetes Jobs and CronJobs - how
to run batch workloads to completion."

**(2) First principles:** "Batch work has a start and an end. Services run
indefinitely. Jobs represent finite work. CronJobs represent recurring finite work."

**(3) Bridge:** "Job is like an invoice processing task: it runs once, processes
the invoices, and exits. CronJob is like a monthly invoice run: triggered on
schedule, runs to completion, exits until the next schedule."

---

### 📘 Concept Explanation

**What it is:**
A Kubernetes Job ensures that a specified number of pod completions succeed.
A CronJob creates Jobs on a schedule. Together, they provide reliable execution
of batch and scheduled workloads with retry, parallelism, and completion tracking.

**The problem it solves:**
Batch workloads need one-time execution with retry on failure, completion
tracking, and scheduled triggering. Pods alone lack completion semantics.
Deployments run indefinitely. Jobs fill the gap.

**How it works:**

```
Job Lifecycle:

  Job spec:
    completions: 5    # Need 5 successful pods
    parallelism: 2    # Run 2 pods at a time
    backoffLimit: 3   # Retry up to 3 times per pod
    activeDeadlineSeconds: 3600 # 1-hour timeout

  Execution:
    t=0: Start pod-0, pod-1 (parallelism=2)
    t=10: pod-0 succeeds (1/5 complete)
          Start pod-2
    t=20: pod-1 fails (retry 1)
    t=30: pod-1 retry succeeds (2/5)
    t=40: pod-2 succeeds (3/5)...
    ...eventually: 5 successes -> Job COMPLETE

  Indexed Mode:
    Each pod gets: JOB_COMPLETION_INDEX=0,1,2,...
    Pod 0: process items 0-1000
    Pod 1: process items 1001-2000
    Pod N: process items N*1000 to (N+1)*1000

  CronJob schedule examples:
    "0 2 * * *"       # 02:00 daily
    "*/30 * * * *"    # Every 30 minutes
    "0 0 * * 0"       # Sunday midnight
    "0 8-18 * * 1-5"  # 8am-6pm weekdays

  CronJob retention:
    successfulJobsHistoryLimit: 3  # Keep 3 completed Jobs
    failedJobsHistoryLimit: 1      # Keep 1 failed Job
```

**The key insight:**
Jobs with backoffLimit represent finite retry attempts, not infinite retry.
Without activeDeadlineSeconds, a stuck pod (not failing, not succeeding)
runs indefinitely, consuming resources. Always set activeDeadlineSeconds
for production Jobs to enforce a maximum run time.

**When to use CronJob vs event-driven approach:**
CronJob: regular scheduled batch work (daily reports, weekly cleanup).
Event-driven (Kafka consumer Job): when batch work is triggered by data
arrival rather than time. Event-driven provides better resource efficiency
(no idle time between scheduled runs).

**First-principles derivation:**
Batch processing has these requirements: execute once, retry on transient
failure, fail permanently on repeated failure, track completion, run in
parallel for large datasets. Job provides completion tracking + retry + parallelism.
CronJob adds time-based triggering. Together they model all batch patterns.

---

### 💻 Code Example

**Example 1: Spring Batch Job in Kubernetes**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: invoice-processor-20240115
  labels:
    job-type: invoice-processor
    batch-date: "20240115"
spec:
  # 10 parallel processors, run to all complete
  completions: 10
  parallelism: 3      # 3 pods at a time
  # Indexed: each pod knows its shard
  completionMode: Indexed
  # Retry each pod up to 2 times before failing
  backoffLimit: 2
  # Fail the entire job after 2 hours
  activeDeadlineSeconds: 7200
  # Auto-delete 24 hours after completion
  ttlSecondsAfterFinished: 86400
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: processor
        image: myregistry.io/invoice-processor:v1.5.0
        env:
        - name: JOB_INDEX
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations[
                'batch.kubernetes.io/job-completion-index']
        - name: TOTAL_SHARDS
          value: "10"
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-report
spec:
  schedule: "0 2 * * *"  # 2am daily
  # Skip if previous still running
  concurrencyPolicy: Forbid
  # Keep history
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 1
      activeDeadlineSeconds: 3600  # 1-hour max
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: reporter
            image: myregistry.io/report-generator:v2.0.0
```

> **Code walkthrough:** The indexed Job runs 10 completions (shards) with
> 3 concurrent pods. Each pod receives its index via the batch.kubernetes.io/
> job-completion-index annotation, allowing each pod to compute its data
> shard (pod 0 processes invoices 0-999, pod 1 processes 1000-1999). backoffLimit:
> 2 allows each pod to retry twice before the overall job fails that completion.
> activeDeadlineSeconds: 7200 is the safety valve: if the job stalls (not
> failing, not completing), it fails after 2 hours. ttlSecondsAfterFinished
> auto-deletes the completed Job after 24 hours to prevent Job accumulation.
> The CronJob uses concurrencyPolicy: Forbid to skip runs if the previous
> 2am run is still in progress - preventing overlapping batch runs that
> could process the same data twice.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> A Job runs pods until a specified number of completions succeed. A CronJob
> creates Jobs on a schedule. restartPolicy for Jobs must be Never or OnFailure
> (not Always). backoffLimit controls how many times a failed pod is retried
> before the Job is marked failed.

*Push deeper:* "The restartPolicy difference between Jobs and Deployments
is critical. Deployments use restartPolicy: Always (pods are continuously
restarted). Jobs use restartPolicy: Never (pod failure counts toward
backoffLimit and triggers a new pod, not a pod restart in-place) or
OnFailure (restart in-place). For Spring Batch jobs: restartPolicy: Never
is usually correct - a clean pod start ensures no in-memory state from
the failed run."

---

**Senior / Staff (5+ years):**

> The production considerations for Kubernetes Jobs in Spring Batch deployments:
> (1) Idempotency: Jobs may run multiple times due to backoffLimit retries or
>     CronJob concurrency issues. Spring Batch step execution must be idempotent.
>     Use step execution status in the JobRepository to detect and skip
>     already-processed items.
> (2) activeDeadlineSeconds: always set. A Job that hangs (waiting for a
>     resource that will never be available) should fail cleanly, not run
>     indefinitely.
> (3) CronJob's concurrencyPolicy: Forbid is critical for idempotency.
>     Without it, two batch runs can execute simultaneously if the previous
>     run overran its window.

*Push deeper:* "KEDA (Kubernetes Event Driven Autoscaler) ScaledJob is
the modern pattern for event-driven batch processing. Instead of a CronJob,
the ScaledJob scales from 0 to N pods based on the SQS queue depth or
Kafka lag. When the queue is empty: 0 pods (no cost). When 1000 messages
arrive: scale to min(1000/batch_size, maxReplicaCount) pods. This replaces
the polling CronJob pattern with reactive scaling."

---

### ⚖️ Comparison Table

| Pattern | Trigger | Scaling | Idempotency Required | Use Case |
|---|---|---|---|---|
| **CronJob (time)** | Schedule | Static (one Job/run) | Yes (retries possible) | Reports, cleanup |
| **CronJob (indexed)** | Schedule | Parallel shards | Yes | Parallel batch |
| **KEDA ScaledJob** | Queue depth | Dynamic (0 to N) | Yes | Event-driven batch |
| **Persistent consumer** | Continuous | HPA | N/A | Streaming processing |

**The deciding factor:** CronJob for scheduled batch. KEDA ScaledJob for
event-triggered batch (queue-based). Persistent consumer service for
continuous stream processing (Kafka).

---

### ⚠️ Common Misconceptions

**"CronJobs guarantee exactly-once execution."**

CronJobs can miss runs (if the Kubernetes cluster was down when the schedule
fired) or run twice (if concurrencyPolicy: Allow and the previous run is slow).
For exactly-once semantics: use a distributed lock (Redis, DB-based) or ensure
idempotent operations that are safe to run multiple times.

**"restartPolicy: Always works for Jobs."**

restartPolicy: Always is only valid for Pods managed by Deployments and
DaemonSets. Jobs require restartPolicy: Never or OnFailure. Using Always
in a Job spec causes a validation error.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Job backoffLimit exceeded | Job Failed, pods in Error state | `kubectl describe job` shows BackoffLimitExceeded | Fix application bug; `kubectl logs <failed-pod>` |
| CronJob overlapping runs | Two batch runs simultaneously | `kubectl get jobs` shows two active Jobs | Set concurrencyPolicy: Forbid |
| Job hangs forever | Job running past expected duration | No new completions; check pod logs | activeDeadlineSeconds forces failure; investigate |
| CronJob missed schedule | No Job created at expected time | Kubernetes was down or throttled during schedule | Check missed run window (default: 100 missed -> suspend) |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Job vs CronJob, restartPolicy difference |
| Mid | 5 min | Indexed completions, backoffLimit |
| Senior | 7 min | Idempotency, KEDA ScaledJob |
| Staff | 9 min | Event-driven batch, exactly-once patterns |

---

**[MID] Q1 - DEBUGGING: A Kubernetes Job completed
but some pods show Error status. Is the Job
successful?**

*Why they ask:* Job completion semantics.

*Likely follow-up:* "When does a Job's backoffLimit apply?"

This is a common point of confusion about Job success semantics.

Job success is determined by completions, not by whether any individual
pod had errors.

Example:
Job spec: completions: 3, backoffLimit: 2
- Pod 1: fails (attempt 1), fails (attempt 2), succeeds (attempt 3) - 1 completion
- Pod 2: succeeds on first attempt - 2 completions
- Pod 3: succeeds on first attempt - 3 completions
Job status: Complete (3 completions achieved)
Pod status: Pod 1 has two Failed pods in history (but overall Job is Complete)

`kubectl get job batch-processor`
  COMPLETIONS: 3/3  DURATION: 45s  AGE: 2m
  Status: Complete

The Error pods are the failed retry attempts from Pod 1's retries.
The Job itself is successful because 3 completions were achieved.

When backoffLimit applies:
backoffLimit is PER TOTAL failed attempts, not per pod.
If backoffLimit: 2 and pods fail 3 total times (not per pod):
  -> Job fails with BackoffLimitExceeded
  -> Remaining active pods are terminated

Diagnosis commands:
`kubectl get pods --selector=job-name=batch-processor`
Shows all pods including failed retries.

`kubectl describe job batch-processor`
Shows: Succeeded: 3, Failed: 2 (retry history)

*What separates good from great:* The distinction between Job-level
success (completions achieved) and pod-level success (all pods healthy).
Error pods in a completed Job are normal retry history.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Java engineer | Spring Batch | Integration patterns, restartPolicy |
| SRE | Operations | CronJob management, failure diagnosis |
| Platform engineer | Patterns | KEDA ScaledJob, indexed completions |
| Backend engineer | Basics | Job vs Deployment, completion semantics |
