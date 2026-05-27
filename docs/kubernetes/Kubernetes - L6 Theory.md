---
layout: default
title: "Kubernetes - L6 Theory"
parent: "Kubernetes"
grand_parent: "SK Interview"
nav_order: 9
permalink: /kubernetes/l6-theory/
---

# Kubernetes Control Theory and Reconciliation

🎯 Interview Weight: high - Understanding the reconciliation loop
separates K8s practitioners from K8s experts. Expected at staff level.

---

### 🎯 Model Answer

**30 seconds:**
> Kubernetes uses a control loop (reconciliation loop): every
> controller watches the desired state (stored in etcd) and
> the actual state (observed via the API server), then acts
> to close the gap. `desired state - actual state = action`.
> If a Deployment says 3 replicas exist but only 2 pods are
> running, the ReplicaSet controller creates one more. This
> is level-triggered control: the system continuously strives
> to match desired state, regardless of how many times it
> must try.

**3 minutes (Senior):**
> Reconciliation loop mechanics:
>
> Control loop pattern (every K8s controller):
> ```
> while true:
>   desired = read spec from etcd (via informer)
>   actual = observe current state (pods, endpoints, etc.)
>   if desired != actual:
>     act to converge (create, update, delete)
>   wait for next event or re-queue
> ```
>
> Informer pattern (efficient watch):
> Controllers do not poll the API server. They use informers
> (shared cache + event handler). The informer watches the
> API server for changes (using HTTP long-polling / WebSocket).
> On change: event is queued in the controller's work queue.
> The controller dequeues and reconciles.
> This eliminates polling overhead and ensures no events are
> missed.
>
> Level-triggered vs edge-triggered:
> Edge-triggered: act when a change event occurs.
> Problem: if an event is missed (network interruption), the
> system diverges and never reconverges.
> Level-triggered: periodically re-evaluate the full desired
> vs actual state, regardless of events.
> K8s uses level-triggered: even without events, controllers
> re-sync on a periodic interval (default: 10-30 minutes).
> This makes K8s self-healing - transient failures are always
> corrected.
>
> Custom controller (Operator pattern):
> Operators extend K8s with custom resources (CRDs).
> A PostgreSQL Operator manages PostgreSQL clusters using
> the reconciliation loop: desired state is a
> `PostgresCluster` CR. The operator reconciles by creating
> Deployments, Services, Secrets, and performing failover.
> The reconciliation loop runs continuously - if a pod dies,
> the operator's reconcile re-creates it with correct config.
>
> Optimistic concurrency (resource version):
> Every K8s resource has a `resourceVersion`. When a controller
> writes an update, it includes the current resourceVersion.
> If another controller updated the resource first
> (resourceVersion changed), the API server returns 409 Conflict.
> The controller re-reads the resource and retries. This
> prevents concurrent controllers from overwriting each other.

**Blank Mind Recovery:**

**(1) Restate:** "K8s reconciliation: controllers watch desired vs
actual state and act to close the gap - continuously, self-healing."

---

### ⚖️ Comparison Table

| Aspect | Edge-Triggered | Level-Triggered (K8s) |
|--------|---------------|----------------------|
| Trigger | Change event | Periodic re-evaluation |
| Missed event | System diverges | System reconverges on next cycle |
| Complexity | Lower | Higher (full state comparison) |
| Self-healing | No | Yes |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Reconciliation loop + informer pattern |
| Staff | 10 min | Level-triggered semantics + custom controllers + optimistic concurrency |

**[TRADE-OFF] Why does Kubernetes use level-triggered instead
of edge-triggered control, and what are the costs?**
`[STAFF]`

*Why they ask:* Tests theoretical understanding of distributed
systems control theory as applied to Kubernetes.

*Likely follow-up:* "What happens if a controller crashes mid-reconciliation?"

Level-triggered guarantees eventual convergence regardless of
missed events. In a distributed system: events can be lost
(network partitions, controller crashes, API server restarts).
Edge-triggered: if the "create pod" event is lost, no pod is
ever created. Level-triggered: on the next reconciliation cycle,
the controller sees 2 pods where 3 are desired, and creates one.
The cluster self-heals without human intervention.

Cost of level-triggered:
(1) Write amplification: controllers re-read and potentially
    re-write state periodically even if nothing changed. At
    scale (1000+ controllers, 10,000+ resources), this generates
    significant API server load. Mitigated by informer caches:
    controllers read from local cache, not directly from etcd.
(2) Reconciliation storm: after a controller restart, all
    watched resources are re-queued simultaneously. A controller
    managing 500 StatefulSets will try to reconcile all 500
    at startup. Rate limiting in the work queue prevents overload.
(3) Consistency lag: the informer cache may be slightly stale
    (milliseconds). A controller may act on slightly old state.
    Optimistic concurrency handles the conflict when writing.

If a controller crashes mid-reconciliation: the in-progress
reconciliation is abandoned. On restart, the controller re-reads
current state and reconciles from scratch. Since K8s operations
are idempotent (`kubectl apply` is declarative), re-running
the reconciliation is safe.

*What separates good from great:* Explaining that the informer
cache is the key scalability mechanism - it decouples controller
read load from etcd read load.

---

---

# Distributed Scheduling Theory

🎯 Interview Weight: medium - K8s scheduler theory is a Staff+
topic. Tests depth of understanding.

---

### 🎯 Model Answer

**30 seconds:**
> The Kubernetes scheduler assigns pods to nodes using a
> two-phase algorithm: Filter (eliminate nodes that cannot
> run the pod) and Score (rank remaining nodes, select highest
> score). Filter plugins check: resource availability,
> taints/tolerations, affinity rules, node selectors.
> Score plugins rank by: resource utilization balance, pod
> affinity co-location, image locality. The scheduler is a
> single-threaded bottleneck - at extreme scale (10,000+ nodes),
> scheduling throughput limits cluster growth rate.

**3 minutes (Senior):**
> Kubernetes scheduler internals:
>
> Scheduling queue:
> Three queues: activeQ (pods ready to be scheduled),
> backoffQ (pods that failed to schedule, waiting for backoff),
> unschedulableQ (pods blocked by un-satisfiable constraints).
> Pods cycle through these queues until scheduled or stuck.
>
> Filter phase (hard constraints):
> NodeUnschedulable, NodeResourcesFit, TaintToleration,
> NodeAffinity, NodePorts, VolumeBinding, PodTopologySpread.
> All filter plugins must pass. Pod fails to schedule if any
> node passes fewer than 0 filters (minFeasibleNodesToFind).
>
> Score phase (soft constraints, 0-100 per plugin):
> LeastAllocated: prefer nodes with lowest resource allocation
> (spread pods across nodes). vs MostAllocated: prefer nodes
> with highest allocation (bin-pack for efficiency).
> ImageLocality: prefer nodes that already have the image cached.
> InterPodAffinity: co-locate with or away from other pods.
>
> Gang scheduling gap:
> K8s default scheduler schedules pods one at a time.
> For workloads requiring all pods to start simultaneously
> (MPI jobs, distributed training), default scheduler cannot
> guarantee all-or-nothing scheduling.
> Solution: Volcano scheduler or Coscheduling plugin.
>
> Preemption:
> If a high-priority pod cannot be scheduled, the scheduler
> evicts lower-priority pods from a node to make room.
> PriorityClass defines numeric priority values. Preemption
> is used by system-critical components and can be disabled
> for regular workloads.

**Blank Mind Recovery:**

**(1) Restate:** "K8s scheduler: Filter (which nodes can?) then
Score (which node is best?). Single-threaded at scale."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Filter + Score phases + scheduling decisions |
| Staff | 8 min | Gang scheduling + preemption + scheduler scalability |

---

---

# Declarative Infrastructure Formal Models

🎯 Interview Weight: medium - Theoretical foundation for why
Kubernetes is designed declaratively. L6 theory topic.

---

### 🎯 Model Answer

**30 seconds:**
> Declarative infrastructure specifies WHAT should exist, not
> HOW to create it. This is in contrast to imperative
> (step-by-step instructions). Kubernetes manifests are
> declarative: `desired: 3 replicas` - the system figures out
> how to reach that state. The formal model: desired state is
> a function of the spec; actual state is observed; a controller
> reduces the gap. This maps to control theory: the system has
> a setpoint (desired), an observed value (actual), and an
> actuator (controller) that minimizes the error.

**3 minutes (Senior):**
> Formal model of declarative Kubernetes:
>
> State function:
> Let S = set of all possible cluster states.
> Let D ⊆ S = desired states (encoded in etcd as Kubernetes resources).
> Let A ⊆ S = actual states (observed cluster reality).
> Controller function: C: A x D -> Operations
> C computes operations (create, update, delete) to transform
> A toward D.
>
> Properties of a well-designed controller:
> Idempotency: applying the same reconciliation N times has
> the same effect as applying it once. kubectl apply is idempotent.
> Convergence: from any A, repeatedly applying C(A, D) eventually
> reaches D (if D is achievable).
> Progress: the system makes progress toward D even after
> partial failures.
>
> The "eventual consistency" guarantee:
> Kubernetes does not guarantee IMMEDIATE convergence.
> It guarantees EVENTUAL convergence - given enough time and
> no new changes to D, the cluster will reach D.
> This is the Kubernetes availability promise: the cluster
> always works toward your desired state.
>
> Declarative vs imperative comparison:
> Imperative: `kubectl run my-pod --image=nginx`
> Problem: if the command fails halfway (pod started but
> networking not configured), the system is in an unknown state.
> Retry is dangerous (may create duplicate resources).
> Declarative: `kubectl apply -f deployment.yaml`
> The system compares desired spec to current state and applies
> only the delta. Idempotent. Safe to retry.
>
> CAP theorem in Kubernetes:
> etcd (the K8s backing store) uses Raft consensus algorithm.
> Raft guarantees CP (consistency + partition tolerance).
> During a network partition, etcd loses quorum and stops
> accepting writes (prioritizes consistency over availability).
> API server can still read from etcd cache but write operations
> are blocked. This means K8s is unavailable for deployments
> during etcd quorum loss - an operator decision: accept
> inconsistency (AP) or block writes (CP). K8s chooses CP.

**Blank Mind Recovery:**

**(1) Restate:** "Declarative = what, not how. Controller reduces
error between desired state and actual state. Convergence guaranteed eventually."

---

### ⚖️ Comparison Table

| Aspect | Imperative | Declarative |
|--------|------------|-------------|
| Definition | How to create | What should exist |
| Idempotency | Not guaranteed | Guaranteed (kubectl apply) |
| Convergence | Not self-healing | Self-healing on failures |
| Auditability | Command history | Git diff of spec |
| Partial failure | Unknown state | Re-apply from spec |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 4 min | Declarative vs imperative + idempotency |
| Staff | 8 min | Controller convergence proof + etcd CAP position |

**[BEHAVIORAL] Tell me about a time you had to debug a Kubernetes
issue that was caused by eventual consistency.**
`[STAFF]`

*Why they ask:* Behavioral + technical combination - tests
real experience with K8s timing/consistency gaps.

*Likely follow-up:* "How did you prevent this from recurring?"

Example scenario: Rolling deployment where new pods became
Ready before the Endpoints resource was updated in kube-proxy.
For 2-3 seconds after new pods were scheduled and passed
readiness probes, kube-proxy on some nodes had not yet received
the updated iptables rules (eventual consistency in endpoint
propagation). Load balancer sent traffic to the new pods
before the network path was fully established. Result: 0.1%
of requests returned 502 during the deployment window.

Root cause: the Service Endpoints propagation path is eventually
consistent: Endpoints Controller -> kube-proxy watch -> iptables
update. The path takes 1-5 seconds. If the pod starts
accepting traffic at T=0 but kube-proxy updates at T=3s,
traffic sent from nodes with stale iptables fails.

Fix: add `minReadySeconds: 30` to the Deployment. This delays
marking pods as Available (eligible for traffic) by 30 seconds
after passing readiness checks, giving all kube-proxy instances
time to update. Alternatively, add a preStop sleep to the old
pods to keep them alive while the new pods' endpoints propagate.

Prevention: use a Service Mesh (Istio/Envoy) which has faster
and more reliable endpoint propagation than kube-proxy.
Monitor: track 5xx rates during deployments with Prometheus
`kube_pod_container_status_ready` and `nginx_upstream_responses_total`.

*What separates good from great:* Connecting the abstract
"eventual consistency" concept to a real deployment failure
and the concrete `minReadySeconds` mitigation.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Reconciliation loop mechanics |
| Bar Raiser | Control theory + formal convergence properties |
| System Design | Declarative infra patterns + etcd CAP trade-offs |
