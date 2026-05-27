---
layout: default
title: "Kubernetes - L1 Foundations"
parent: "Kubernetes"
nav_order: 2
permalink: /kubernetes/l1-foundations/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Pods and Container Lifecycle](#pods-and-container-lifecycle) | foundational |
| 2 | [Deployments and ReplicaSets](#deployments-and-replicasets) | foundational |
| 3 | [Services and Networking Fundamentals](#services-and-networking-fundamentals) | high |
| 4 | [ConfigMaps and Secrets](#configmaps-and-secrets) | high |
| 5 | [Namespaces and RBAC Basics](#namespaces-and-rbac-basics) | high |

---

# Pods and Container Lifecycle

**Interview Weight:** foundational - Pods are the fundamental unit of
deployment. Understanding pod lifecycle, init containers, and graceful
shutdown is required knowledge for any Kubernetes interview.

---

### 🎯 Model Answer

**30 seconds:**

> A pod is the smallest deployable unit in Kubernetes: one or more containers
> that share a network namespace (same IP address) and can share volumes.
> Pod lifecycle: Pending (scheduled, pulling image) -> Running (containers
> started) -> Succeeded or Failed. Kubernetes terminates pods with SIGTERM
> (graceful shutdown window) then SIGKILL. Java services must handle SIGTERM
> to drain in-flight requests before the JVM exits.

**3 minutes (Senior):**

> The pod lifecycle has distinct phases with different operational implications.
> Pending: the pod has been accepted by the API server but containers are not
> yet running. Reasons: scheduler is finding a node, images are being pulled,
> init containers are running. Running: at least one container is running.
> Succeeded: all containers exited with status 0. Failed: one or more containers
> exited non-zero.
>
> The container lifecycle within a pod: Init containers run sequentially before
> app containers start. They complete and exit. App containers then start. If
> an init container fails, the pod restarts it (with backoff) until it succeeds.
> Sidecar containers (Kubernetes 1.28+ native sidecars) run alongside the main
> container and have their own lifecycle independent from the main container.
>
> Termination sequence: SIGTERM is sent to PID 1. The pod waits
> terminationGracePeriodSeconds (default: 30). After the grace period,
> SIGKILL is sent. For Java services: Spring Boot 2.3+ handles SIGTERM via
> a graceful shutdown mode that completes in-flight requests. Set
> terminationGracePeriodSeconds >= spring.lifecycle.timeout-per-shutdown-phase
> to ensure the JVM completes shutdown before SIGKILL.
>
> preStop hooks: if the main container does not handle SIGTERM well, a preStop
> exec hook runs before SIGTERM. This is a common pattern for services that
> need a brief sleep before termination to allow load balancer deregistration.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about pod lifecycle - the states a pod
goes through from creation to termination."

**(2) First principles:** "A pod is a process group. Its lifecycle follows
the process lifecycle: start, run, terminate. Kubernetes adds management
around each phase."

**(3) Bridge:** "Like a contractor engagement: init containers are pre-work
(setup), app containers are the main work, preStop and SIGTERM handling are
project closeout."

---

### 📘 Concept Explanation

**What it is:**
A pod is the atomic unit of deployment in Kubernetes - a set of containers
that share a network namespace and optionally storage, managed as a single
unit with a defined lifecycle from scheduling through termination.

**The problem it solves:**
Containers often need co-location (same IP, same volumes) for helper patterns
(logging sidecar, init setup, proxies). Pods provide this co-location model
while maintaining each container's independent process boundary.

**How it works:**

```
Pod Lifecycle States:

  Pending:
    - Scheduler finds a node
    - Images pulled (if not cached)
    - Init containers run (sequentially)
    - Wait for readinessGate conditions

  Running:
    - At least one container running
    - Containers may be Waiting/Running/Terminated

  Succeeded:
    - All containers exited 0
    - Terminal state (pods do not restart)

  Failed:
    - One+ containers exited non-zero
    - restartPolicy=Never: terminal state
    - restartPolicy=OnFailure: restart containers

  Unknown:
    - Node communication lost
    - Pods marked Unknown after timeout

Termination Sequence:
  1. Pod deleted (kubectl delete pod)
  2. SIGTERM sent to PID 1 of each container
  3. Wait terminationGracePeriodSeconds (default 30)
  4. SIGKILL sent (force kill)
  5. Pod removed from Endpoints (traffic stops)

Parallel: Endpoints removal and SIGTERM happen
  simultaneously. Race condition: SIGTERM before
  endpoints removed -> requests still arrive during
  shutdown. Fix: preStop sleep to wait for endpoints
  removal before app shutdown begins.
```

**The key insight:**
Kubernetes removes the pod from the Service Endpoints at the same time
as SIGTERM is sent. This creates a race: the app starts shutting down
but the load balancer may still route traffic for a few seconds. The
preStop sleep (5-10 seconds) ensures endpoint deregistration completes
before the application starts declining requests.

**When init containers are appropriate:**
Database migrations that must complete before the app starts; configuration
fetching that requires credentials not available in the main container;
waiting for a dependency to be ready before the main container starts.

**First-principles derivation:**
A pod groups containers that have tight coupling: they need the same IP
address (because they communicate on localhost), the same volumes (because
they share data), and the same lifecycle (if one dies, the pod is affected).
Containers within a pod are not independent - they form a unit of co-execution.

---

### 💻 Code Example

**Example 1: Pod with init container and preStop hook**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: payment-service
spec:
  terminationGracePeriodSeconds: 60
  initContainers:
  # Init: wait for database to be ready
  - name: wait-for-db
    image: busybox:1.35
    command:
    - sh
    - -c
    - |
      until nc -z postgres-service 5432; do
        echo "Waiting for postgres..."; sleep 5
      done
      echo "Postgres is ready"
  # Init: run DB migrations
  - name: db-migrate
    image: myregistry.io/payment-service:v2.1.0
    command: ["java", "-jar", "app.jar",
              "--spring.flyway.run=true",
              "--exit-on-migrate=true"]
    env:
    - name: SPRING_DATASOURCE_URL
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: url

  containers:
  - name: app
    image: myregistry.io/payment-service:v2.1.0
    lifecycle:
      preStop:
        exec:
          # Sleep before shutdown to allow Endpoints removal
          # Prevents requests arriving after shutdown starts
          command: ["/bin/sh", "-c", "sleep 5"]
    # Spring Boot graceful shutdown: drain in-flight requests
    # terminationGracePeriodSeconds must be > 5 (preStop) +
    # spring.lifecycle.timeout (30s) = 35s minimum
    env:
    - name: SPRING_LIFECYCLE_TIMEOUT_PER_SHUTDOWN_PHASE
      value: "30s"
```

> **Code walkthrough:** Init containers run to completion before the
> main container starts. The wait-for-db init container polls the database
> endpoint, preventing the app from starting with no database connection.
> The db-migrate init container runs Flyway migrations - safely separated
> from the application lifecycle so they run exactly once per pod start.
> The preStop sleep of 5 seconds gives the Kubernetes endpoints controller
> time to remove the pod from the Service before the app begins declining
> requests. Spring's timeout-per-shutdown-phase configures how long Spring
> Boot waits for in-flight requests to complete before force-shutting down.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> A pod runs one or more containers that share the same network (same IP).
> Pod lifecycle: Pending (not started) -> Running -> Succeeded/Failed.
> When a pod is deleted, Kubernetes sends SIGTERM, waits 30 seconds (default),
> then sends SIGKILL.

*Push deeper:* "The preStop hook is an important operational detail.
Kubernetes removes the pod from Service Endpoints and sends SIGTERM at
approximately the same time. If SIGTERM is processed first, the application
starts shutting down while the load balancer still routes traffic to it.
A 5-second preStop sleep ensures endpoint removal completes before the
application shuts down."

---

**Senior / Staff (5+ years):**

> Pod lifecycle management for Java services requires attention to three
> details: (1) startupProbe to prevent premature liveness failures during
> Spring Boot initialization, (2) preStop sleep to handle the Endpoints
> race condition on shutdown, (3) terminationGracePeriodSeconds set to
> exceed preStop time + Spring Boot shutdown timeout.
>
> I have seen production rolling update issues from all three. Missing
> startupProbe: pods crash-loop before Spring Boot finishes starting.
> Missing preStop: users see errors during rolling updates as new pods
> receive traffic before old pods finish draining. Insufficient grace period:
> in-flight requests are SIGKILL'd mid-processing.

*Push deeper:* "The Kubernetes 1.28 native sidecar feature changes the
sidecar pattern significantly. Before 1.28, sidecars were regular containers
(they start in undefined order). With native sidecars, you declare a
container as a sidecar in initContainers with restartPolicy: Always. It
starts before app containers and keeps running. This solves the race condition
where the app starts before the sidecar (e.g., Envoy proxy) is ready."

---

### ⚖️ Comparison Table

| Container Type | Lifecycle | Use Case |
|---|---|---|
| **Init container** | Run to completion before app | DB migration, dependency wait |
| **App container** | Runs for pod lifetime | Main application |
| **Sidecar (native, K8s 1.28+)** | Starts before app, lives for pod | Proxy, log shipper, secrets agent |
| **Ephemeral container** | Debug-only, not in spec | Live debugging (kubectl debug) |

**The deciding factor:** Init containers for one-time setup. Native sidecars
(K8s 1.28+) for ongoing helpers. Ephemeral containers for production debugging
without modifying the pod spec.

---

### ⚠️ Common Misconceptions

**"Pods restart after SIGKILL."**

A pod container restart (via restartPolicy) happens when a container exits.
After SIGKILL, the container exits non-zero, and the kubelet restarts it
based on restartPolicy. SIGKILL does not prevent restarts - it just ends
the graceful shutdown window.

**"Init containers and app containers share environment variables."**

Init containers and app containers have independent environment variable
declarations. They can share volumes. They share the network namespace (same
IP). But each container's env section is independent.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| App starts before init completes | App crashes with no DB | Init container still running; app waits | Correct behavior (init runs first) - check init logs |
| preStop missing | Errors during rolling update | 502/503 during deployments | Add preStop: sleep 5 |
| Grace period too short | In-flight requests killed | Container exit log shows force kill | Increase terminationGracePeriodSeconds |
| Init container fails | Pod stuck in Init:CrashLoopBackOff | `kubectl logs pod -c init-container-name` | Fix init container error |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Pod phases, termination sequence |
| Mid | 6 min | preStop, init containers, Java shutdown |
| Senior | 10 min | Endpoints race condition, grace period sizing |
| Staff | 12 min | Native sidecars, complex lifecycle management |

---

**[MID] Q1 - How does a Java Spring Boot service
handle graceful shutdown in Kubernetes?**

*Why they ask:* Java-specific pod lifecycle knowledge.

*Likely follow-up:* "How do you size terminationGracePeriodSeconds?"

Spring Boot graceful shutdown + Kubernetes configuration:

Spring Boot side:
Enable graceful shutdown in application.properties:
```
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
```
This tells Spring Boot to stop accepting new requests on SIGTERM and
wait up to 30 seconds for in-flight requests to complete.

Kubernetes side:
Set terminationGracePeriodSeconds to exceed the total shutdown time:
Total time = preStop duration + Spring shutdown timeout + buffer
= 5s (preStop sleep) + 30s (Spring timeout) + 5s buffer = 40s minimum
Recommended: terminationGracePeriodSeconds: 60

preStop hook:
```yaml
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 5"]
```
This 5-second sleep allows Kubernetes endpoints controller to remove
the pod from the Service before Spring Boot starts declining requests.

The complete sequence:
1. Pod deletion triggered (rolling update or manual delete)
2. Pod removed from Service Endpoints (simultaneous with step 3)
3. preStop sleep(5) runs
4. SIGTERM sent to JVM after preStop completes
5. Spring Boot: stop accepting new requests
6. Spring Boot: wait for in-flight requests (up to 30s)
7. Spring Boot: shutdown context (DB connections, thread pools)
8. JVM exits cleanly (before 60s grace period)

*What separates good from great:* Understanding the Endpoints removal
race condition and why preStop sleep is necessary.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Java engineer | Spring Boot | Spring graceful shutdown config |
| Platform/SRE | Operations | Grace period sizing, preStop hook |
| Backend | Basics | Pod phases, init containers |
| Staff | Architecture | Native sidecars, sidecar race conditions |

---
---

# Deployments and ReplicaSets

**Interview Weight:** foundational - Deployments are the primary way
to run Java services in production. Understanding the Deployment/ReplicaSet
relationship and rolling update mechanics is required knowledge.

---

### 🎯 Model Answer

**30 seconds:**

> A Deployment manages a ReplicaSet, which manages pods. The Deployment
> handles versioning and rollout strategy. The ReplicaSet handles the
> pod count (ensures N replicas are always running). When you update a
> Deployment, it creates a new ReplicaSet and gradually shifts pods from
> the old to the new - that is a rolling update. You can roll back to the
> previous ReplicaSet with kubectl rollout undo.

**3 minutes (Senior):**

> The Deployment -> ReplicaSet -> Pod hierarchy is the standard abstraction
> for running stateless services.
>
> ReplicaSet: its only job is to ensure that N pods matching a label selector
> are running at all times. If a pod dies, the ReplicaSet controller creates
> a replacement. ReplicaSets should not be created directly in production -
> use Deployments which add versioning and rollout management on top.
>
> Deployment: manages the ReplicaSet lifecycle. When you change the pod template
> (new image tag, new env var), the Deployment creates a new ReplicaSet and
> scales it up while scaling down the old one. The rollout strategy controls
> this transition. maxSurge: how many extra pods can exist above the desired
> count during the rollout. maxUnavailable: how many pods can be unavailable
> during the rollout.
>
> The rollout uses readinessProbe to gate progression. New pods must pass
> readiness before old pods are terminated. This ensures the new version is
> serving requests before removing the old version. minReadySeconds adds an
> additional stabilization delay (wait N seconds after readiness passes before
> considering the pod stable).
>
> Rolling back: kubectl rollout undo deployment/myapp reverts to the previous
> ReplicaSet (which is kept after rollout by default). The Deployment tracks
> revisionHistoryLimit past ReplicaSets (default: 10). kubectl rollout history
> shows the revision log.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Deployments and ReplicaSets - how
Kubernetes manages pod groups and rolling updates."

**(2) First principles:** "Running N copies of a service requires: something
to ensure N replicas (ReplicaSet) and something to update those replicas
safely (Deployment)."

**(3) Bridge:** "ReplicaSet is like a supervisor that replaces absent workers.
Deployment is like HR that manages the transition when the company replaces
a job position with a new hire."

---

### 📘 Concept Explanation

**What it is:**
A Deployment manages the desired state of a stateless application as a set
of replicated pods, providing rolling updates, rollbacks, and scaling through
the ReplicaSet primitive.

**The problem it solves:**
Running multiple replicas of a service with zero-downtime updates requires
coordinated pod lifecycle management: scaling new version up while scaling
old version down, gating on health, and enabling rollback.

**How it works:**

```
Deployment -> ReplicaSet -> Pods

Initial deploy (replicas: 3, image: v1.0):
  Deployment: myapp
    ReplicaSet: myapp-abc123 (v1.0)
      Pod: myapp-abc123-1  [Running]
      Pod: myapp-abc123-2  [Running]
      Pod: myapp-abc123-3  [Running]

Update image to v2.0 (rolling update):
  Deployment: myapp
    ReplicaSet: myapp-abc123 (v1.0) -> scale down
      Pod: myapp-abc123-1  [Running]   -> terminate
      Pod: myapp-abc123-2  [Running]   -> terminate
      Pod: myapp-abc123-3  [Running]   -> terminate
    ReplicaSet: myapp-def456 (v2.0) -> scale up
      Pod: myapp-def456-1  [Running]  -> started
      Pod: myapp-def456-2  [Running]  -> started
      Pod: myapp-def456-3  [Running]  -> started

After rollout:
  ReplicaSet myapp-abc123 retained (0 pods, for rollback)
  ReplicaSet myapp-def456 active (3 pods)

Rollout strategy (RollingUpdate):
  maxSurge: 1    -> at most 4 pods during rollout
  maxUnavailable: 0 -> always 3+ pods serving (no downtime)
```

**The key insight:**
The Deployment keeps the old ReplicaSet with 0 replicas after a rollout.
This enables rollback without needing to rebuild the old image. kubectl rollout
undo simply scales the old ReplicaSet back to the desired count and scales
the current one to 0.

**When to use Recreate strategy:**
When old and new versions cannot run simultaneously (incompatible DB schemas
that were not backward-compatible, exclusive resource locking). Recreate
terminates all old pods before starting new ones (brief downtime).

**First-principles derivation:**
Zero-downtime deployment requires the old version to serve requests while
the new version starts, until the new version is verified ready. maxUnavailable:
0 ensures the old version continues serving. readinessProbe verification
ensures the new version is confirmed ready before the old is terminated.
These constraints together define the rolling update algorithm.

---

### 💻 Code Example

**Example 1: Production Deployment with rolling update config**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  annotations:
    # Rollout reason for history (visible in rollout history)
    kubernetes.io/change-cause: "v2.2.0: add payment retry"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-service
  # Rolling update strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1       # max 4 pods total during rollout
      maxUnavailable: 0 # always 3+ pods serving
  # Stabilization: wait 10s after pod passes readiness
  minReadySeconds: 10
  # Keep 5 old ReplicaSets for rollback
  revisionHistoryLimit: 5
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
      - name: app
        image: myregistry.io/payment-service:v2.2.0
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          periodSeconds: 5
          failureThreshold: 3
```

```bash
# Monitor rolling update progress
kubectl rollout status deployment/payment-service
# Waiting for deployment "payment-service" rollout...
# -> 1 of 3 updated replicas are available
# -> 2 of 3 updated replicas are available
# deployment "payment-service" successfully rolled out

# Check rollout history
kubectl rollout history deployment/payment-service
# REVISION  CHANGE-CAUSE
# 1         Initial deploy v2.1.0
# 2         v2.2.0: add payment retry

# Rollback if needed
kubectl rollout undo deployment/payment-service
# Rolled back to v2.1.0 (revision 1)
```

> **Code walkthrough:** maxUnavailable: 0 ensures zero downtime by requiring
> all 3 original pods to remain available throughout the rollout. maxSurge: 1
> allows one extra pod temporarily (4 total) to enable the first new pod to
> start before any old pod is terminated. minReadySeconds: 10 adds a 10-second
> stabilization period after readiness passes before the Deployment considers
> the pod stable - preventing brief readiness flickers from being treated as
> stable. The change-cause annotation appears in rollout history, providing
> an audit trail of what each rollout changed.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> A Deployment manages pods using a ReplicaSet. The Deployment handles rolling
> updates: it creates a new ReplicaSet (new version), scales it up, and scales
> down the old ReplicaSet. maxUnavailable: 0 ensures all old pods continue
> serving until new pods are ready. kubectl rollout undo reverts to the previous
> version.

*Push deeper:* "The key to zero-downtime rolling updates is the combination
of maxUnavailable: 0 AND a readinessProbe. Without maxUnavailable: 0, some
old pods terminate before new pods are ready - brief traffic reduction. Without
readinessProbe, Kubernetes cannot know if new pods are actually ready - it
terminates old pods as soon as new pods start, possibly before they can serve."

---

**Senior / Staff (5+ years):**

> The Deployment/ReplicaSet pattern is the correct abstraction for stateless
> Java services. The three rolling update parameters I configure for every
> production Deployment:
> (1) maxUnavailable: 0 - zero downtime guarantee
> (2) maxSurge: 1 - controlled resource overhead during rollout
> (3) minReadySeconds: 10 - stabilization to prevent flapping deployments
>
> The subtle issue with fast-failing services: if a new version has a bug that
> causes it to fail after 30 seconds (not at startup), readinessProbe passes
> initially and pods scale up, then fail. Kubernetes starts rolling back. But
> this scenario can cause traffic errors if all new pods fail simultaneously.
> Canary deployments (progressive traffic shifting) are the more robust approach
> for high-risk changes.

*Push deeper:* "The Deployment uses its own selector.matchLabels to own pods.
If you change the selector (which is immutable), you must delete and recreate
the Deployment. This is a destructive operation. Always avoid changing the
selector. Use label versioning in annotations (not labels) if you need to
track versions."

---

### ⚖️ Comparison Table

| Strategy | Downtime | Use Case | Risk |
|---|---|---|---|
| **RollingUpdate** (maxUnavailable:0) | None | Standard stateless services | Slow if readiness fails |
| RollingUpdate (maxUnavailable:1) | Minimal | Faster rollout, slight risk | 1 pod unavailable briefly |
| Recreate | Yes (brief) | Incompatible DB schema, exclusive resources | Downtime equals startup time |
| Blue/green (external) | None | High-risk changes, instant rollback | Double resource cost during switch |
| Canary (Argo Rollouts) | None | Progressive validation of changes | Complex tooling |

**The deciding factor:** RollingUpdate with maxUnavailable: 0 for standard
production deployments. Blue-green or canary for high-risk changes where
instant rollback or traffic validation is required.

---

### ⚠️ Common Misconceptions

**"Deployments and ReplicaSets are interchangeable."**

ReplicaSets can be created directly but lack rollout management (no revision
history, no rollback, no strategy). Deployments add these capabilities. Always
use Deployments for application workloads, never bare ReplicaSets.

**"kubectl rollout undo rebuilds the old image."**

kubectl rollout undo reactivates the previous ReplicaSet (which is kept with
0 replicas). It does not rebuild anything - the previous pod template is
already stored in the ReplicaSet. Rollback is fast (seconds) because the
previous configuration already exists.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Rollout stuck | kubectl rollout status hangs | New pods failing readiness; `kubectl describe pod` | Fix readiness failure; kubectl rollout undo |
| maxSurge: 0, maxUnavailable: 0 | Rollout never progresses | 0 extra pods allowed, 0 can be unavailable = deadlock | Set maxSurge: 1 minimum |
| Wrong selector | Deployment does not own pods | Pods exist but Deployment shows 0 ready | Selector must match pod template labels exactly |
| Image pull failure | Pods stuck in ErrImagePull | `kubectl describe pod` shows image pull error | Fix image tag; check registry credentials (imagePullSecrets) |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Deployment vs ReplicaSet, rolling update |
| Mid | 6 min | Strategy parameters, rollback mechanics |
| Senior | 10 min | Zero-downtime guarantee, fast-fail scenarios |
| Staff | 12 min | Canary vs rolling, selector immutability |

---

**[SENIOR] Q1 - DEBUGGING: A rolling update is taking
too long and some pods are stuck in Pending. What
do you check?**

*Why they ask:* Production rollout debugging.

*Likely follow-up:* "How do you pause and resume a rollout?"

Pending pods during a rolling update indicate a scheduling issue.

Diagnosis steps:
1. Check pod events: `kubectl describe pod <new-pod-name>`
   Look for: Insufficient cpu, Insufficient memory, 0/3 nodes available
   This tells you why the scheduler cannot place the pod.

2. If insufficient resources:
   The node pool may be at capacity. New pods (maxSurge) cannot be
   scheduled because no node has enough CPU/memory.
   Fix: cluster autoscaler should add a node. If not using autoscaler:
   manually scale the node group.
   Alternative: reduce pod resource requests or maxSurge.

3. If node affinity/taint mismatch:
   The new pod spec has an affinity rule or tolerations change that
   prevents scheduling on existing nodes.
   Fix: check the new pod spec for affinity/toleration changes.

4. If readiness failing (pods Running but not Ready):
   The rollout waits for new pods to pass readiness before continuing.
   `kubectl describe pod` shows readiness probe failures.
   Fix: check application logs (`kubectl logs <pod>`), fix the readiness
   failure, or rollback: `kubectl rollout undo deployment/myapp`.

Pause and resume:
If you need to pause mid-rollout to investigate:
kubectl rollout pause deployment/myapp
After fixing: kubectl rollout resume deployment/myapp

*What separates good from great:* Knowing the difference between Pending
(scheduling issue) and Running + not Ready (readiness issue) - they require
completely different remediation.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Java engineer | Day-to-day | Rolling update flow, kubectl rollout commands |
| SRE | Operations | Rollout debugging, pause/resume |
| Platform engineer | Strategy | maxSurge/maxUnavailable trade-offs |
| Staff engineer | Architecture | Canary vs rolling, blue-green |

---
---

# Services and Networking Fundamentals

**Interview Weight:** high - Services are how pods are discovered and
accessed in Kubernetes. Understanding ClusterIP, NodePort, LoadBalancer,
and headless services, plus why kube-dns is needed, is required.

---

### 🎯 Model Answer

**30 seconds:**

> A Kubernetes Service provides a stable IP and DNS name for a set of pods
> (selected by label). Pod IPs are ephemeral - they change when pods restart.
> Services provide a stable endpoint. Service types: ClusterIP (internal
> only - most common for inter-service communication), NodePort (exposes on
> every node's IP), LoadBalancer (provisions a cloud load balancer), and
> Headless (returns pod IPs directly, used by StatefulSets).

**3 minutes (Senior):**

> Kubernetes networking solves the pod-to-pod discovery problem. Pods have
> ephemeral IPs that change on restart. Services provide stable virtual IPs
> (ClusterIP) backed by kube-proxy rules that forward traffic to healthy pods.
>
> ClusterIP: a virtual IP that only works within the cluster. kube-proxy
> programs iptables rules: traffic to the ClusterIP is DNAT'd to one of the
> backing pod IPs (round-robin by default). DNS: Kubernetes DNS (CoreDNS) creates
> an A record for each Service: myservice.mynamespace.svc.cluster.local -> ClusterIP.
>
> kube-proxy modes: iptables (default - rules per endpoint, scales poorly
> with 10,000+ endpoints), ipvs (L4 load balancer, scales better), eBPF
> with Cilium (replaces kube-proxy entirely, most efficient).
>
> Endpoints: the Service does not directly know about pods. It knows about
> Endpoints (a separate resource). The Endpoints controller watches pods
> matching the Service's selector and updates the Endpoints resource with
> the current healthy pod IPs. kube-proxy watches Endpoints to update its
> rules.
>
> For Java services: the Service provides load balancing across all pod IPs.
> Spring Boot services connect to `http://myservice` (or the FQDN). When
> HPA scales from 3 to 10 pods, the Service automatically routes to all 10.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kubernetes Services - how pods
are discovered and accessed within and outside the cluster."

**(2) First principles:** "Pod IPs change. Services provide stability.
A Service is a stable endpoint that proxies to current healthy pods."

**(3) Bridge:** "A Kubernetes Service is like a restaurant phone number.
The chefs (pods) change shifts, but the phone number (Service IP/DNS)
stays the same. CoreDNS is the phone book."

---

### 📘 Concept Explanation

**What it is:**
A Kubernetes Service is a stable network endpoint (IP and DNS name)
that load-balances traffic to a set of pods identified by a label selector,
abstracting the ephemeral nature of pod IPs.

**The problem it solves:**
Pods have ephemeral IPs (changed on restart, rescheduling, or rollout).
Clients cannot track pod IPs directly. Services provide a stable endpoint
that always routes to currently running, healthy pods.

**How it works:**

```
Service -> Endpoints -> Pods

  Service: payment-service
    ClusterIP: 10.96.0.100
    Selector: app: payment-service
    Port: 8080 -> 8080

  Endpoints: payment-service
    172.17.0.5:8080 (pod-1)
    172.17.0.6:8080 (pod-2)
    172.17.0.7:8080 (pod-3)

  kube-proxy iptables rules:
    -A KUBE-SVC-XYZ -m statistic --mode random
      --probability 0.33 -j KUBE-SEP-1
    -A KUBE-SVC-XYZ -m statistic --mode random
      --probability 0.50 -j KUBE-SEP-2
    -A KUBE-SVC-XYZ -j KUBE-SEP-3

  DNS (CoreDNS):
    payment-service.default.svc.cluster.local
      -> 10.96.0.100 (ClusterIP)

Service Types:
  ClusterIP:    Internal only (default)
  NodePort:     NodeIP:30000-32767 (exposed externally)
  LoadBalancer: Cloud LB provisioned (ELB/GLB)
  ExternalName: CNAME to external DNS
  Headless:     No ClusterIP; returns pod IPs directly
```

**The key insight:**
When a pod fails readiness, the Endpoints controller removes it from the
Endpoints list. kube-proxy updates its rules. Traffic stops flowing to the
unready pod within a few seconds. This is how Services provide automatic
circuit breaking: unready pods are automatically excluded from routing.

**When to use headless services:**
For StatefulSets where each pod needs a stable DNS name (pod-0.myservice,
pod-1.myservice). For client-side load balancing where the client should
receive all pod IPs and make its own load balancing decision (Cassandra,
Kafka consumers).

**First-principles derivation:**
The Service provides name stability (DNS) and IP stability (ClusterIP).
kube-proxy provides routing (ClusterIP -> pod IP). The Endpoints controller
provides health-based membership (only ready pods in Endpoints). These three
components together implement service discovery with health filtering.

---

### 💻 Code Example

**Example 1: Service configuration for Spring Boot**

```yaml
# Standard ClusterIP service for internal communication
apiVersion: v1
kind: Service
metadata:
  name: payment-service
  namespace: default
spec:
  selector:
    app: payment-service    # matches pod labels
  ports:
  - name: http
    protocol: TCP
    port: 80          # port on ClusterIP (client-facing)
    targetPort: 8080  # port on pods
  type: ClusterIP     # internal only (default)

---
# LoadBalancer for external access (creates cloud LB)
apiVersion: v1
kind: Service
metadata:
  name: payment-service-external
spec:
  selector:
    app: payment-service
  ports:
  - port: 443
    targetPort: 8080
  type: LoadBalancer
  # AWS specific: configure ACM cert
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: >
      arn:aws:acm:us-east-1:123456789:certificate/abc123
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
```

```bash
# Verify service and endpoints
kubectl get service payment-service
# NAME              TYPE        CLUSTER-IP    EXTERNAL-IP  PORT(S)
# payment-service   ClusterIP   10.96.0.100   <none>       80/TCP

kubectl get endpoints payment-service
# NAME              ENDPOINTS                           AGE
# payment-service   172.17.0.5:8080,172.17.0.6:8080,...

# DNS resolution from within cluster
kubectl exec -it debug-pod -- nslookup payment-service
# Server: 10.96.0.10 (CoreDNS)
# payment-service.default.svc.cluster.local: 10.96.0.100
```

> **Code walkthrough:** The ClusterIP Service is the standard for
> inter-service communication. The selector `app: payment-service` matches
> pod labels. The port mapping (80 -> 8080) allows the external port (80)
> to differ from the application port (8080). The LoadBalancer type triggers
> the cloud provider controller to provision an external load balancer.
> The AWS annotation configures ACM TLS termination at the load balancer.
> The endpoints verification confirms the Service is routing to the correct
> pods - if endpoints is empty, the label selector is likely misconfigured.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> A Service provides a stable IP and DNS name for a group of pods identified
> by a label selector. ClusterIP: internal only. LoadBalancer: creates a cloud
> load balancer. kube-proxy programs iptables rules that route traffic from the
> ClusterIP to pod IPs. CoreDNS provides DNS resolution: service-name.namespace
> .svc.cluster.local resolves to the ClusterIP.

*Push deeper:* "When pods fail readiness, the Endpoints controller removes
them from the Endpoints list. kube-proxy updates its iptables rules to stop
routing to the unhealthy pod. This happens within 1-5 seconds. During this
window, the Service may still send traffic to the failing pod. This is why
readinessProbe failure threshold is important - it controls how quickly the
pod is removed from routing."

---

**Senior / Staff (5+ years):**

> The Service + Endpoints + kube-proxy pipeline is the core networking model.
> Understanding where latency is introduced: kube-proxy's iptables implementation
> has O(N) rules lookup for N endpoints. For a Service with 1,000 backing pods,
> iptables has 1,000+ rules. Kubernetes recommends switching to ipvs mode for
> large Endpoint counts.
>
> Cilium as a kube-proxy replacement: eBPF programs handle connection routing
> at the kernel level without iptables rules. Lower overhead (5x less CPU for
> routing) and better observability (Hubble shows per-connection metrics).
> Recommended for clusters with > 100 nodes or > 500 endpoints.

*Push deeper:* "The connection tracking table (conntrack) is a hidden
bottleneck for high-connection-rate services. iptables uses conntrack to
track TCP connections for DNAT. At high connection rates (100,000+ new
connections/second), the conntrack table fills up. Symptoms: new connections
fail silently. Fix: tune net.netfilter.nf_conntrack_max or switch to ipvs
mode which has its own connection tracking."

---

### ⚖️ Comparison Table

| Service Type | Scope | Provisioning | Use Case |
|---|---|---|---|
| **ClusterIP** | Internal only | None (virtual IP) | Inter-service communication |
| **NodePort** | Node IP + port | None | Dev/test external access |
| **LoadBalancer** | External | Cloud LB | Production external access |
| **Headless** | DNS (pod IPs) | None | StatefulSets, client-side LB |
| **ExternalName** | CNAME | None | Alias external services |

**The deciding factor:** ClusterIP for internal communication (99% of services).
LoadBalancer (via Ingress controller for HTTP, direct for non-HTTP) for external.
Headless for StatefulSets and services requiring direct pod addressing.

---

### ⚠️ Common Misconceptions

**"LoadBalancer Services are the right way to expose HTTP services."**

LoadBalancer creates one cloud load balancer per Service - expensive and
unscalable for many services. Use an Ingress controller (nginx-ingress,
AWS ALB controller) instead: one load balancer routes to many services
based on hostname/path rules.

**"Services load balance equally to all pods."**

kube-proxy iptables mode uses random probability rules, which is approximately
round-robin for long-lived connections but can be uneven. For short-lived
connections (HTTP/1.1 with connection reuse), connections are pinned to one
pod. Long-lived TCP connections need application-level load balancing or a
service mesh for even distribution.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Empty endpoints | Service traffic fails (connection refused) | `kubectl get endpoints` shows empty | Check selector matches pod labels exactly |
| DNS resolution fails | Service not reachable by name | `kubectl exec nslookup service-name` fails | Check CoreDNS pods in kube-system; check namespace |
| NodePort unreachable | Cannot reach service from outside | Node firewall/security group blocking | Open port in node security group; check 30000-32767 range |
| iptables rule stale | Traffic occasionally fails | Recent pod scale; kube-proxy slow update | Check kube-proxy logs; may be transient during scale |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Service types, ClusterIP vs LoadBalancer |
| Mid | 6 min | Endpoints lifecycle, DNS resolution |
| Senior | 10 min | kube-proxy modes, conntrack bottleneck |
| Staff | 12 min | Cilium/eBPF, Ingress vs LoadBalancer |

---

**[MID] Q1 - How does Kubernetes DNS work for service
discovery?**

*Why they ask:* Service discovery is fundamental to microservice communication.

*Likely follow-up:* "What is the full DNS name for a service in a different namespace?"

Kubernetes DNS (CoreDNS) provides automatic service discovery via DNS.

How it works:
1. A Service is created: `name: payment-service, namespace: default`
2. CoreDNS creates an A record:
   `payment-service.default.svc.cluster.local -> ClusterIP 10.96.0.100`
3. Pods in the default namespace can resolve by short name: `payment-service`
4. Pods in other namespaces need the full qualified name:
   `payment-service.default.svc.cluster.local`
   Or the namespace-relative name: `payment-service.default`

The search domain makes short names work:
Each pod has /etc/resolv.conf with:
`search default.svc.cluster.local svc.cluster.local cluster.local`
When the pod resolves `payment-service`, the resolver appends each search
domain in order. First match wins. This is why `payment-service` resolves
to `payment-service.default.svc.cluster.local`.

Cross-namespace resolution:
For `payment-service` in namespace `payments` accessed from namespace `orders`:
`payment-service.payments.svc.cluster.local` is the FQDN.
Or: `payment-service.payments` (namespace-relative).

Spring Boot: set `SPRING_DATASOURCE_URL=jdbc:postgresql://postgres.data:5432/db`
Where `postgres` is the Service name and `data` is the namespace.

*What separates good from great:* Explaining the search domain mechanism
that makes short names work and the FQDN format for cross-namespace access.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Backend engineer | Usage | DNS names, how to connect services |
| Platform/SRE | Operations | Endpoint lifecycle, kube-proxy modes |
| Network engineer | Architecture | iptables vs ipvs vs eBPF |
| Java engineer | Spring | JDBC URLs, service names for Spring config |

---
---

# ConfigMaps and Secrets

**Interview Weight:** high - Configuration management in Kubernetes is a
critical production concern. Interviewers test whether you understand the
security implications of Secrets, how to inject config, and when to use
external secrets managers.

---

### 🎯 Model Answer

**30 seconds:**

> ConfigMaps store non-sensitive configuration as key-value pairs injected
> into pods as environment variables or mounted as files. Secrets store
> sensitive data (passwords, tokens, certs) similarly. The key operational
> difference: Kubernetes Secrets are base64-encoded (NOT encrypted) by default.
> Anyone with kubectl read access to the namespace can see the secret values.
> For production: enable etcd encryption at rest or use an external secrets
> manager (AWS Secrets Manager, HashiCorp Vault) for sensitive data.

**3 minutes (Senior):**

> ConfigMaps and Secrets both provide configuration injection for pods.
> The difference is the intended data type and access controls, not the
> underlying storage mechanism (both go in etcd).
>
> Injection methods: environment variables (loaded at pod start, static for
> the pod's lifetime) or volume mounts (files in the container's filesystem,
> can be updated without pod restart when projected correctly).
>
> The critical security caveat: Kubernetes Secrets are base64-encoded in
> etcd by default. Base64 is encoding, not encryption. Anyone with etcd
> access or kubectl get secret permission can read plaintext values with:
> kubectl get secret mysecret -o jsonpath='{.data.password}' | base64 -d
>
> Security options:
> (1) etcd encryption at rest: encrypts Secret data in etcd using an
> encryption provider (AES-CBC, AES-GCM). Requires control plane config change.
> (2) External Secrets Operator: syncs secrets from AWS Secrets Manager,
> HashiCorp Vault, or GCP Secret Manager into Kubernetes Secrets. The actual
> values are not stored long-term in etcd.
> (3) Pod-level: avoid mounting secrets as env vars (visible in process env);
> prefer volume mounts (files with controlled permissions).
>
> ConfigMap updates: changes to a ConfigMap volume-mount are reflected in pods
> within ~1 minute without pod restart. Changes to ConfigMap env vars require
> pod restart. Spring Cloud Kubernetes provides automatic Spring context refresh
> on ConfigMap changes.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about ConfigMaps and Secrets - how
Kubernetes manages configuration injection."

**(2) First principles:** "12-factor apps externalize configuration.
Kubernetes provides the externalized config mechanism: ConfigMaps for
non-sensitive config, Secrets for sensitive config."

**(3) Bridge:** "ConfigMap is like a config file checked into a shared
drive accessible to the app. Secret is like a password manager - except
the default Kubernetes implementation stores it in the equivalent of an
unencrypted shared drive."

---

### 📘 Concept Explanation

**What it is:**
ConfigMaps and Secrets are Kubernetes API objects that store configuration
data (key-value pairs or files) and inject it into pods at runtime as
environment variables or file mounts.

**The problem it solves:**
Java services need environment-specific configuration (database URLs, feature
flags, credentials) without baking environment-specific values into the image.
ConfigMaps and Secrets provide runtime configuration injection.

**How it works:**

```
Configuration Injection:

ConfigMap: payment-service-config
  data:
    spring.profile: "production"
    log.level: "INFO"
    db.host: "postgres.data.svc.cluster.local"

Injection as env vars:
  containers:
  - env:
    - name: SPRING_PROFILES_ACTIVE
      valueFrom:
        configMapKeyRef:
          name: payment-service-config
          key: spring.profile

Injection as volume mount:
  volumes:
  - name: config
    configMap:
      name: payment-service-config
  containers:
  - volumeMounts:
    - mountPath: /config
      name: config
  # Files at /config/spring.profile, /config/log.level, etc.
  # Updated within ~1 min when ConfigMap changes

Secret injection (SAME patterns):
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: payment-service-secrets
        key: db-password

Security: base64 decode reveals plaintext
  echo "cGFzc3dvcmQ=" | base64 -d
  # password
  # NOT encrypted by default
```

**The key insight:**
Kubernetes Secrets are not secret by default. They require additional
configuration (etcd encryption at rest, RBAC restrictions, external
secrets manager) to provide real security. The name "Secret" implies
more security than the default implementation provides.

**When to use external secrets:**
For any secret that would violate compliance if etcd were compromised
(database passwords, API keys, TLS private keys). AWS Secrets Manager +
External Secrets Operator is the standard pattern for AWS deployments.

**First-principles derivation:**
Configuration is data that changes between environments. It should be
separate from code. Kubernetes provides the mechanism (ConfigMap/Secret)
but delegates the security implementation to the operator. The security
posture of Kubernetes Secrets is: "restricted from casual access, not
protected from determined attacks without encryption at rest."

---

### 💻 Code Example

**Example 1: ConfigMap and Secret for Spring Boot**

```yaml
# ConfigMap: non-sensitive Spring Boot configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: payment-service-config
  namespace: production
data:
  # Spring Boot externalized properties
  SPRING_PROFILES_ACTIVE: "production"
  MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS: "never"
  SPRING_DATASOURCE_URL: >
    jdbc:postgresql://postgres.data.svc.cluster.local:5432/payments
  # Multi-line properties file (Spring reads this automatically)
  application.properties: |
    spring.jpa.hibernate.ddl-auto=validate
    server.tomcat.max-threads=100
    logging.level.com.company=INFO

---
# Secret: sensitive configuration (DB password)
# In production: use External Secrets Operator instead
# This shows the Kubernetes Secret structure for learning
apiVersion: v1
kind: Secret
metadata:
  name: payment-service-secrets
  namespace: production
type: Opaque
data:
  # base64: echo -n "mysecretpassword" | base64
  db-password: bXlzZWNyZXRwYXNzd29yZA==
  # Not encrypted! Visible to anyone with kubectl access.

---
# ExternalSecret: sync from AWS Secrets Manager (BETTER)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: payment-service-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: payment-service-secrets
    creationPolicy: Owner
  data:
  - secretKey: db-password
    remoteRef:
      key: payment-service/db-password
```

> **Code walkthrough:** The ConfigMap stores non-sensitive Spring Boot
> config including a multi-key application.properties block that Spring
> Boot auto-discovers when mounted at /config/. The Kubernetes Secret shows
> the structure with base64-encoded values - note the comment that this is
> visible to anyone with kubectl access. The ExternalSecret (External Secrets
> Operator) is the production alternative: it reads from AWS Secrets Manager
> and syncs to a Kubernetes Secret. The actual secret value is never stored
> permanently in etcd - only the current sync is present.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> ConfigMaps store non-sensitive configuration. Secrets store sensitive data.
> Both can be injected as environment variables or volume mounts. Important
> security caveat: Kubernetes Secrets are base64-encoded (not encrypted) by
> default. Anyone with read access to the namespace can decode them.

*Push deeper:* "The difference between env var injection and volume mount
injection matters for updates. ConfigMap env var injection: loaded at pod
start, changes require pod restart. ConfigMap volume mount: the file is
updated within about 60 seconds when the ConfigMap changes, without pod
restart. Spring Cloud Kubernetes can watch for these changes and refresh
the Spring Environment automatically."

---

**Senior / Staff (5+ years):**

> In production, I use the External Secrets Operator pattern: secrets live
> in AWS Secrets Manager, and ExternalSecret resources sync them into
> Kubernetes Secrets on a schedule. When a secret rotates, the ExternalSecret
> refreshes. Pod-level: inject via volume mount (not env var) to avoid the
> secret being visible in ps aux output or environment dumps.
>
> The RBAC model for secrets: secrets should have their own RBAC rules
> separate from ConfigMaps. Most application developers should have read
> access to ConfigMaps but NOT to Secrets. Create Roles that grant get/list
> only on specific secrets, not on all secrets in the namespace.

*Push deeper:* "The secret rotation problem: even with external secrets,
pods that loaded the secret as an env var at startup need to restart to
pick up the rotated secret. Volume mounts update automatically within
~60 seconds. For short-lived secrets (tokens with 15-minute TTL): volume
mount with a sidecar agent (Vault Agent) that renews tokens automatically
is the correct pattern."

---

### ⚖️ Comparison Table

| Approach | Security | Rotation | Complexity |
|---|---|---|---|
| **Kubernetes Secret (default)** | Low (base64 in etcd) | Manual restart | Low |
| **Kubernetes Secret + etcd encryption** | Medium (encrypted in etcd) | Manual restart | Medium |
| **External Secrets Operator** | High (values in secrets manager) | Auto-refresh | Medium |
| **Vault Agent Sidecar** | Highest (short-lived, auto-renewed) | Automatic | High |

**The deciding factor:** External Secrets Operator for teams already using
AWS Secrets Manager or HashiCorp Vault. etcd encryption at rest as a baseline
for all clusters. Vault Agent for high-security workloads requiring secret
leasing and automatic renewal.

---

### ⚠️ Common Misconceptions

**"Kubernetes Secrets are secure because they are called Secrets."**

By default, Kubernetes Secrets are only base64-encoded in etcd. This
is not encryption. The name "Secret" is a naming convention, not a security
guarantee. Security requires either etcd encryption at rest or an external
secrets manager.

**"ConfigMap volume mounts update instantly."**

ConfigMap volume mounts update asynchronously, typically within 30-60
seconds of the ConfigMap change. The update relies on the kubelet's sync
period and the node's caching mechanism. It is not instant and may take
longer under high load.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Missing ConfigMap | Pod fails to start: missing env key | `kubectl describe pod` shows MissingConfigMap | Create ConfigMap with required keys |
| Secret value leaked | Credential exposed in kubectl output | Anyone can `kubectl get secret -o yaml` | Enable etcd encryption; use External Secrets |
| ConfigMap update not reflected | Old config values after ConfigMap change | Env vars: correct (need restart); volume: wait 60s | Restart pod for env vars; wait for volume sync |
| RBAC prevents Secret access | Pod fails to start: Forbidden | Pod ServiceAccount lacks Secret access | Add Role binding for Secret access |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | ConfigMap vs Secret, injection methods |
| Mid | 6 min | Security caveat, etcd encryption |
| Senior | 10 min | External Secrets Operator, rotation strategy |
| Staff | 12 min | Vault Agent, RBAC for secrets, update behavior |

---

**[SENIOR] Q1 - ARCHITECTURE: What is the correct
way to manage database credentials for a Java
service in Kubernetes?**

*Why they ask:* Practical secrets management.

*Likely follow-up:* "How do you handle rotation without pod restart?"

The progression of database credential management in Kubernetes:

Level 1 (not acceptable): Hardcoded in application.properties or environment
variable baked into the image. Credentials in source code/image.

Level 2 (minimal - acceptable for dev only): Kubernetes Secret with base64-encoded
password. `kubectl create secret generic db-creds --from-literal=password=...`
Accessible to anyone with kubectl get secret. No encryption at rest.

Level 3 (production baseline): AWS Secrets Manager + External Secrets Operator.
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: db-credentials-k8s
  data:
  - secretKey: password
    remoteRef:
      key: production/payment-service/db-password
```
The Kubernetes Secret syncs from Secrets Manager. When rotated in Secrets
Manager, the ExternalSecret refreshes within 1 hour. Pod restart required
to pick up new env var value.

Level 4 (auto-rotation without restart): Volume mount instead of env var.
Mount the secret as a file. When ExternalSecret refreshes, the file updates
within 60 seconds. Spring Boot with @ConfigurationProperties and proper
scope can pick up new values.

Level 5 (IAM-based, no password): IRSA (IAM Roles for Service Accounts)
with RDS IAM authentication. The pod assumes an IAM role that grants
temporary database credentials via rds-ca-bundle. No static password.
Credentials are 15-minute tokens, automatically renewed.

*What separates good from great:* Level 5 (IAM-based auth) - eliminating
the static password entirely in favor of short-lived IAM tokens.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Security engineer | Threat model | etcd encryption, RBAC, external secrets |
| Java backend | Practical | Spring property injection, volume mounts |
| DevOps | Operations | External Secrets Operator, rotation |
| Staff engineer | Architecture | IRSA, Vault, credential lifecycle |

---
---

# Namespaces and RBAC Basics

**Interview Weight:** high - Multi-team Kubernetes usage requires
namespaces for isolation and RBAC for access control. Interviewers
test whether you understand the scope of namespace isolation and
how to apply least-privilege access.

---

### 🎯 Model Answer

**30 seconds:**

> Namespaces provide logical isolation of Kubernetes resources: each
> namespace has its own pods, services, ConfigMaps, secrets, and resource
> quotas. They are NOT security boundaries (pods in different namespaces
> can communicate unless NetworkPolicy prevents it). RBAC (Role-Based
> Access Control) grants identities (users, service accounts) access
> to specific Kubernetes API resources using Roles (namespace-scoped) or
> ClusterRoles (cluster-scoped).

**3 minutes (Senior):**

> Namespaces partition the Kubernetes API: each resource lives in exactly
> one namespace (or is cluster-scoped like Nodes, PersistentVolumes, ClusterRoles).
> Namespaces provide: resource quota enforcement (how much CPU/memory/storage
> a namespace can consume), RBAC scope (permissions are granted per namespace),
> name scoping (two services can have the same name in different namespaces),
> and network segmentation (when combined with NetworkPolicy).
>
> RBAC has four components: Role (what you can do, namespace-scoped),
> ClusterRole (what you can do, cluster-wide), RoleBinding (who can do
> what in a namespace), ClusterRoleBinding (who can do what cluster-wide).
>
> The principle of least privilege: each service account should have only
> the permissions it needs. A Spring Boot service's pod typically needs:
> no Kubernetes API access at all (automountServiceAccountToken: false).
> An operator or controller needs: read/write on specific CRDs only.
> A developer kubectl user: create/delete pods in their namespace, not
> in production namespaces.
>
> Service Accounts: pods run with a service account identity. The default
> service account has no permissions (good default). automountServiceAccountToken:
> true (default) mounts the token at /var/run/secrets/kubernetes.io/serviceaccount.
> If your application does not talk to the Kubernetes API: set
> automountServiceAccountToken: false to prevent token exposure in the container.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kubernetes namespaces and RBAC -
how to partition the cluster and control access."

**(2) First principles:** "Multi-tenancy requires resource isolation (different
teams should not affect each other's resources) and access control (different
teams should not see each other's secrets). Namespaces + RBAC provide this."

**(3) Bridge:** "Namespaces are like floors in an office building. RBAC is
the key card system. Different teams (floors) have their own resources, and
the key card controls which floors each person can access."

---

### 📘 Concept Explanation

**What it is:**
Kubernetes namespaces provide logical partitioning of cluster resources by
name scope, quota, and RBAC boundary. RBAC (Role-Based Access Control) grants
specific API permissions to users and service accounts, following least-privilege.

**The problem it solves:**
In a multi-team Kubernetes cluster, teams need resource isolation (team A's
mistake should not affect team B's workloads) and access control (team A should
not be able to read team B's secrets or modify team B's deployments).

**How it works:**

```
Namespace Structure:

  Cluster-scoped resources (no namespace):
    Nodes, PersistentVolumes, ClusterRoles,
    ClusterRoleBindings, Namespaces

  Namespace-scoped resources:
    Pods, Deployments, Services, ConfigMaps,
    Secrets, ResourceQuotas, LimitRanges

RBAC Components:

  Role (namespace-scoped):
    - What API resources: pods, deployments, secrets
    - What verbs: get, list, watch, create, update, delete

  ClusterRole (cluster-scoped):
    - Same as Role but applies cluster-wide
    - Can also be bound per-namespace via RoleBinding

  RoleBinding: binds Role/ClusterRole to a subject
    Subjects: User, Group, ServiceAccount
    Scope: one namespace

  ClusterRoleBinding: binds ClusterRole cluster-wide
    Scope: entire cluster

Principle of Least Privilege:
  Developer: get/list/watch pods in team namespace
  Operator: get/list/watch cluster-wide
  Application pod: NO permissions (automountServiceAccountToken: false)
  CI/CD: create/update deployments in target namespace
```

**The key insight:**
Namespaces are NOT network security boundaries. Pods in namespace A can
talk to pods in namespace B by default. The separation is only at the
Kubernetes API level (naming, quotas, RBAC). For network isolation between
namespaces: add NetworkPolicy with namespace selectors.

**When to use ClusterRole vs Role:**
ClusterRole: permissions that span all namespaces (monitoring, operators,
platform admin). Role: permissions scoped to one namespace (application
developer access, CI/CD service account).

**First-principles derivation:**
Least privilege requires that each identity has exactly the permissions
needed, no more. RBAC provides the mechanism. Namespace scoping limits
the blast radius of a compromised credential: if a developer's credentials
are compromised, they can only affect their own namespace, not production.

---

### 💻 Code Example

**Example 1: RBAC for a Java service and developer**

```yaml
# ServiceAccount for the Java service
# Most Spring Boot services need NO K8s API access
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-service
  namespace: production
automountServiceAccountToken: false  # Security: no token

---
# Role for developers in the team namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: team-a
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec"]
  verbs: ["get", "list", "watch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "update", "patch"]
# NOT allowed:
# - No access to secrets
# - No access to production namespace
# - No cluster-level operations

---
# RoleBinding: binds role to developer user
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: team-a
subjects:
- kind: User
  name: "alice@company.com"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io

---
# ResourceQuota: limit namespace resource consumption
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    count/pods: "20"
```

> **Code walkthrough:** The ServiceAccount with automountServiceAccountToken:
> false prevents the Kubernetes API token from being mounted in the container.
> Most application pods never talk to the Kubernetes API - the token is a
> security exposure without benefit. The developer Role grants access to
> pods and deployments but explicitly omits Secrets (developers should not
> read production secrets via kubectl). The RoleBinding applies the Role
> only within namespace team-a. The ResourceQuota enforces that team-a
> cannot consume more than 8 cores and 16 GB memory, preventing noisy
> neighbor issues in a shared cluster.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Namespaces logically partition the cluster: each has its own pods, services,
> ConfigMaps, and resource quotas. RBAC controls who can do what: Roles define
> permissions in a namespace, RoleBindings grant those permissions to users or
> service accounts. Principle of least privilege: give each identity only the
> permissions it needs.

*Push deeper:* "Important caveat: namespaces do not provide network isolation.
Pods in namespace A can communicate with pods in namespace B by default. You
need NetworkPolicy to enforce network segmentation between namespaces. The
namespace selector in NetworkPolicy allows `from` or `to` rules scoped to
specific namespaces."

---

**Senior / Staff (5+ years):**

> Namespaces + RBAC + NetworkPolicy + ResourceQuota together provide
> soft multi-tenancy. "Soft" because they all share the same kernel -
> a kernel exploit bypasses all of these. For untrusted multi-tenancy
> (running customer code), you need stronger isolation (Kata Containers).
>
> RBAC design principles I apply:
> (1) Service accounts: automountServiceAccountToken: false unless the app
> explicitly needs Kubernetes API access
> (2) CI/CD service accounts: scoped to specific namespaces with create/update
> on deployments only (not full admin)
> (3) ClusterRoleBinding: used sparingly; prefer namespace-scoped bindings
> (4) audit periodically: kubectl get rolebindings,clusterrolebindings -A
> to find overly permissive bindings

*Push deeper:* "The escalation principle in RBAC: a user cannot grant
permissions they do not have. If a developer has pod:get in namespace A,
they cannot create a RoleBinding that grants pod:get to others in namespace A
unless they also have rolebindings:create permission. This prevents privilege
escalation via RBAC manipulation."

---

### ⚖️ Comparison Table

| Isolation Type | Namespace | NetworkPolicy | Resource Quota | Security Level |
|---|---|---|---|---|
| **Name scoping only** | Yes | No | No | Minimal |
| **Access control** | Yes | No | No | RBAC isolation |
| **Network isolation** | Yes | Yes | No | API + network |
| **Resource isolation** | Yes | No | Yes | API + resource limits |
| **Full soft multi-tenancy** | Yes | Yes | Yes | All soft controls |

**The deciding factor:** For production multi-team clusters: all three
controls (RBAC + NetworkPolicy + ResourceQuota) together. Each addresses
a different attack vector.

---

### ⚠️ Common Misconceptions

**"Namespaces prevent pods from talking to each other."**

Namespaces provide API isolation (RBAC, naming, quotas) but NOT network
isolation. Pods in different namespaces can communicate unless NetworkPolicy
explicitly prevents it.

**"ClusterRoleBinding should be used for broad access."**

ClusterRoleBindings grant cluster-wide access. A compromised service account
with a ClusterRoleBinding can access every namespace. Prefer namespace-scoped
RoleBindings (even using ClusterRoles) to limit scope.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis | Fix |
|---|---|---|---|
| Service account lacks permission | Pod cannot call K8s API; 403 Forbidden | `kubectl auth can-i get pods --as system:serviceaccount:ns:sa` | Add Role + RoleBinding for required permissions |
| ResourceQuota prevents pod start | Pod stuck in Pending: exceeded quota | `kubectl describe quota -n namespace` | Request quota increase or reduce resource requests |
| Namespace cross-access | Developer modifies wrong namespace | RBAC audit shows broad ClusterRoleBinding | Scope to namespace-specific RoleBinding |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Namespace purpose, RBAC components |
| Mid | 6 min | Least privilege, namespace scoping |
| Senior | 10 min | Soft multi-tenancy, automountServiceAccountToken |
| Staff | 12 min | Multi-team governance, RBAC audit |

---

**[SENIOR] Q1 - How do you design RBAC for a team
using a shared Kubernetes cluster?**

*Why they ask:* Multi-team cluster governance.

*Likely follow-up:* "How do you audit for over-privileged roles?"

Multi-team RBAC design:

1. Namespace per team:
   Each team gets dedicated namespaces: team-a-dev, team-a-staging,
   team-a-prod. Separate namespaces for environments allows different
   RBAC policies: developers have full access to -dev, limited access
   to -staging, read-only access to -prod.

2. Standard roles per team:
   Create a Team-Admin ClusterRole (bound per namespace):
   - Deployments, Services, ConfigMaps: full CRUD
   - Secrets: read only (no create of new secrets - those come from external secrets)
   - Pods: get/list/watch/delete
   
   Team-Developer Role:
   - Pods: get/list/watch, exec (for debugging)
   - Logs: get
   - Deployments: get/list/watch/update (image tag updates)
   - NO secrets, NO ConfigMap modification

3. CI/CD service account:
   Separate ServiceAccount per team for CI/CD (Argo CD, Jenkins).
   Bind to: create/update/patch Deployments, Services in the team's namespaces.
   Never use cluster-admin for CI/CD.

Auditing:
`kubectl get clusterrolebindings -o json | jq '.items[] | select(.roleRef.name=="cluster-admin") | .subjects'`
Shows all bindings to cluster-admin. Any non-platform-admin subjects are a finding.

`kubectl auth can-i --list --as system:serviceaccount:team-a:default -n team-a`
Shows all permissions for the default service account in team-a namespace.

*What separates good from great:* The audit command to find cluster-admin
bindings - the most common RBAC misconfiguration.

---

**Interviewer Type Adaptation:**

| Interviewer | Focus | What to Emphasize |
|---|---|---|
| Platform engineer | Governance | Multi-team RBAC design, audit commands |
| Security engineer | Compliance | Least privilege, secret access restriction |
| Engineering manager | Team isolation | Namespace isolation, resource quotas |
| Developer | Access | What developers can/cannot do |
