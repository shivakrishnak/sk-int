---
layout: default
title: "Kubernetes - Workloads"
parent: "Kubernetes"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/kubernetes/workloads/
topic: Kubernetes
subtopic: Workloads
keywords:
  - Pod
  - Deployment
  - StatefulSet
  - DaemonSet
  - Job and CronJob
  - ReplicaSet
difficulty_range: medium-hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Pod](#pod)
- [Deployment](#deployment)
- [StatefulSet](#statefulset)
- [DaemonSet](#daemonset)
- [Job and CronJob](#job-and-cronjob)
- [ReplicaSet](#replicaset)

# Pod

**TL;DR** - A Pod is the smallest deployable unit in Kubernetes - a group of one or more containers that share network namespace (same IP), storage volumes, and lifecycle, scheduled together on the same node.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Containers are isolated by default (separate network, storage). Some applications need tightly-coupled containers (app + sidecar) that must share localhost and storage. Running them independently on different nodes breaks this coupling.

**THE INVENTION MOMENT:**
"This is exactly why Kubernetes has Pods as the atomic unit."
---

### 📘 Textbook Definition

A Pod is a Kubernetes abstraction representing a group of one or more containers with shared storage/network resources and a specification for how to run the containers. Containers within a Pod share the same network namespace (IP and port space), IPC namespace, and can share volumes.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
A Pod is one or more containers that share an IP address and storage.

**One analogy:**

> A Pod is like passengers in a car. They travel together (co-scheduled), share the same vehicle (network namespace, IP address), can talk to each other easily (localhost), and arrive/depart together (lifecycle). You don't put strangers in the same car unless they need to travel together.

**One insight:**
Most pods have exactly ONE container. Multi-container pods exist for the sidecar pattern (logging, proxying, secret injection). If containers don't need localhost communication, they should be separate pods for independent scaling.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  labels:
    app: web
spec:
  containers:
    - name: app
      image: myapp:1.0
      ports:
        - containerPort: 8080
      resources:
        requests:
          memory: "256Mi"
          cpu: "250m"
        limits:
          memory: "512Mi"
      livenessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 10
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
  restartPolicy: Always
```

```
Pod internals:
+---------------------------------+
| Pod (shared network namespace)  |
| IP: 10.244.1.5                  |
|                                 |
| +-------+  localhost  +-------+ |
| | app   |<---------->| envoy | |
| | :8080 |            | :15001| |
| +---+---+            +-------+ |
|     |                           |
|  +--+----+                      |
|  | volume |  (shared storage)   |
|  +--------+                     |
+---------------------------------+
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Pods share network namespace (same IP, can use localhost between containers) and can share volumes
2. Most pods have ONE container - multi-container is for sidecars/helpers that need tight coupling
3. Pods are ephemeral - never create bare pods in production, always use Deployments/StatefulSets for management

**Interview one-liner:**
"A Pod is Kubernetes' atomic scheduling unit - one or more containers sharing a network namespace and volumes, co-located on one node. I always use higher-level controllers (Deployment, StatefulSet) rather than bare Pods, as they provide replication, self-healing, and declarative updates."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Pod. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: When would you put multiple containers in one Pod vs separate Pods?**

_Why they ask:_ Tests understanding of Pod design principles.

**Answer:**
Same Pod when:

- Containers MUST communicate via localhost (sidecar proxy pattern)
- Containers share files via volume (log shipper reading app's log directory)
- Tight lifecycle coupling (init container + app container)
- Cannot function independently (helper process that the app depends on)

Separate Pods when:

- Containers scale independently (web server and database)
- Containers have different resource needs
- Containers can run on different nodes
- Failure of one shouldn't affect the other

Rule of thumb: "Would this container make sense running on a different machine?" If yes -> separate Pod.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Deployment

**TL;DR** - A Deployment manages the lifecycle of stateless application Pods - handling replication, rolling updates, rollbacks, and self-healing through a declarative desired-state model.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You manually create pods. One crashes - nobody recreates it. You need to update the image - you delete pods one by one and create new ones, hoping traffic isn't dropped. Rollback means remembering the old image tag.

**THE INVENTION MOMENT:**
"This is exactly why Kubernetes Deployments were created."
---

### 📘 Textbook Definition

A Deployment provides declarative updates for Pods and ReplicaSets. You describe a desired state (image, replicas, strategy), and the Deployment controller progressively changes the actual state to the desired state at a controlled rate through rolling updates.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
A Deployment ensures the right number of the right version of your app is always running.

**One analogy:**

> A Deployment is like a restaurant staffing schedule. It says "always have 3 chefs on duty." If one calls in sick (pod crash), a replacement is called (new pod). If you hire a new chef (new image), they gradually replace existing chefs (rolling update) so the kitchen never stops.

**One insight:**
Deployments create ReplicaSets. Each update creates a NEW ReplicaSet (keeping old ones for rollback). A "rollback" is just scaling the previous ReplicaSet back up and the current one down. Revision history is free.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1 # 1 extra pod during update
      maxUnavailable: 0 # Never fewer than 3 healthy
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: myapp:2.0
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
```

```
Rolling Update sequence (3 replicas, v1 -> v2):

Step 1: [v1] [v1] [v1] [v2-starting]  (maxSurge: 1)
Step 2: [v1] [v1] [v2-ready] [v2]     (one v1 terminated)
Step 3: [v1] [v2] [v2] [v2-starting]
Step 4: [v2] [v2] [v2]                 (complete)

Rollback:
  kubectl rollout undo deployment/api-server
  -> Scales down current RS, scales up previous RS
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```bash
# Deploy
kubectl apply -f deployment.yaml

# Check rollout status
kubectl rollout status deployment/api-server

# Update image (triggers rolling update)
kubectl set image deployment/api-server \
  api=myapp:2.1

# View rollout history
kubectl rollout history deployment/api-server

# Rollback to previous version
kubectl rollout undo deployment/api-server

# Rollback to specific revision
kubectl rollout undo deployment/api-server \
  --to-revision=3

# Scale
kubectl scale deployment/api-server --replicas=5

# Pause/resume (for batched changes)
kubectl rollout pause deployment/api-server
kubectl set image deployment/api-server api=myapp:3.0
kubectl set resources deployment/api-server -c api \
  --limits=memory=1Gi
kubectl rollout resume deployment/api-server
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Deployments manage stateless app lifecycle: replication, rolling updates, rollbacks, self-healing
2. Rolling update: `maxSurge` (extra pods during update) + `maxUnavailable` (how many can be down) control the rollout speed
3. Always set readiness probes - without them, traffic routes to pods before they can serve, causing errors during updates

**Interview one-liner:**
"A Deployment declaratively manages stateless Pod replicas through ReplicaSets - providing rolling updates (controlled by maxSurge/maxUnavailable), automatic rollback (previous ReplicaSets preserved), and self-healing (controller recreates failed pods) - always with readiness probes to ensure zero-downtime deployments."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Deployment. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: You deploy a new version and users start seeing 500 errors. What happened and how do you handle it?**

_Why they ask:_ Tests incident response and deployment knowledge.

**Answer:**
Immediate action:

```bash
# Check rollout status
kubectl rollout status deployment/api-server
# Rollback immediately
kubectl rollout undo deployment/api-server
```

Why errors occurred despite rolling update:

1. **Missing readiness probe**: Pods received traffic before being ready
2. **Probe too lenient**: Health check passes but app fails on real requests
3. **Graceful shutdown missing**: Old pods terminated before finishing in-flight requests (need `preStop` hook or `terminationGracePeriodSeconds`)
4. **Resource limits too low**: New version uses more memory, gets OOM killed after probe passes

Prevention:

- Readiness probes that test real functionality (not just `/health` returning 200)
- `preStop: sleep 5` to allow service endpoint removal before container stops
- Canary deployments (route 5% traffic first) for early detection
- Automated rollback on error rate threshold (Argo Rollouts, Flagger)

---

**Q2: Compare RollingUpdate vs Recreate strategy. When do you use each?**

_Why they ask:_ Tests understanding of deployment strategies.

**Answer:**
| | RollingUpdate | Recreate |
|--|-------------|----------|
| Downtime | Zero (gradual) | Yes (all old killed before new start) |
| Resource | Needs extra capacity (maxSurge) | No extra capacity needed |
| Versions | Two versions run simultaneously | Never two versions at once |
| Use case | Stateless APIs, web apps | DB schema changes, breaking API changes |

Use Recreate when:

- New version is incompatible with old (breaking database schema change)
- Shared resource that can't handle two versions (single-writer pattern)
- Cost: you can accept brief downtime for simpler deployment

In practice: 95% of deployments use RollingUpdate. Recreate is rare and usually indicates a design problem (should decouple schema migration from app deployment).
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# StatefulSet

**TL;DR** - StatefulSet manages stateful applications that need stable network identities, persistent storage per replica, and ordered deployment/scaling - used for databases, message brokers, and distributed systems.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your PostgreSQL cluster needs: pod-0 is always primary, pod-1 is always replica. Pods need stable DNS names that survive restarts. Each pod needs its own persistent disk that follows it. Deployments can't provide any of this.

**THE INVENTION MOMENT:**
"This is exactly why StatefulSets were created."
---

### 📘 Textbook Definition

A StatefulSet is a workload controller that manages stateful applications by providing: stable, unique network identifiers for each pod (pod-0, pod-1), stable persistent storage (per-pod PVCs), and ordered, graceful deployment, scaling, and termination.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
StatefulSet gives pods stable identity and persistent storage - essential for databases and distributed systems.

**One analogy:**

> A Deployment is like interchangeable waiters (any can serve any table). A StatefulSet is like assigned parking spots - spot #1 is always yours, it's always in the same location, and your stuff (persistent volume) stays there even when your car (pod) is replaced.

**One insight:**
StatefulSet pods have predictable names: `myapp-0`, `myapp-1`, `myapp-2`. Each has a stable DNS name: `myapp-0.myapp-headless.namespace.svc.cluster.local`. This identity persists across restarts - if `myapp-0` dies, the new pod is STILL `myapp-0` with the same volume.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless # Required!
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates: # Per-pod PVC
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
```

```
StatefulSet guarantees:
  Ordered deployment: pod-0 ready -> pod-1 created -> ...
  Stable identity:    postgres-0, postgres-1, postgres-2
  Stable DNS:         postgres-0.postgres-headless.ns.svc
  Stable storage:     PVC: data-postgres-0 (never reused)

  vs Deployment:
  Random names:       myapp-5d8f7b-xk2s (changes on restart)
  Shared PVC:         Same PVC for all replicas (if any)
  Any order:          All pods start simultaneously
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. StatefulSet = stable identity (pod-0 is always pod-0) + stable storage (PVC per pod) + ordered operations
2. Use for databases, message brokers (Kafka), distributed systems needing peer identity (ZooKeeper, etcd)
3. Requires a headless Service (`clusterIP: None`) for stable DNS names per pod

**Interview one-liner:**
"StatefulSets provide stable network identity (predictable pod names and DNS), persistent per-replica storage (volumeClaimTemplates), and ordered deployment/scaling - essential for stateful workloads like databases where pod identity and storage persistence must survive restarts."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for StatefulSet. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: When would you use StatefulSet vs Deployment for a database?**

_Why they ask:_ Tests decision-making about stateful workloads.

**Answer:**
Use StatefulSet when:

- Running database IN Kubernetes (PostgreSQL cluster, Kafka, Elasticsearch)
- Need per-pod persistent storage (each replica has its own disk)
- Need stable network identity (replication configuration references pod-0 as primary)
- Need ordered scaling (primary must be running before replicas)

BUT: in most cases, DON'T run databases in Kubernetes:

- Managed services (RDS, CloudSQL) are simpler, auto-backup, auto-patch
- StatefulSet operational complexity: backup, restore, failover, resize

Decision framework:

- Small/medium team + cloud environment -> Managed database (RDS)
- Platform team + specific requirements -> StatefulSet with operator (CloudNativePG, Strimzi)
- Multi-cloud/on-prem + strong ops team -> StatefulSet with operator

The operator pattern (CloudNativePG for Postgres, Strimzi for Kafka) adds automated failover, backup, and scaling on top of StatefulSets, bringing operational maturity closer to managed services.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# DaemonSet

**TL;DR** - A DaemonSet ensures one pod runs on every (or selected) node in the cluster - used for infrastructure agents like log collectors, monitoring, and network plugins.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You need a log collector on every node to ship logs from all pods on that node. With Deployments, you'd need to manually match replicas to node count and handle node additions.
---

### 📘 Textbook Definition

A DaemonSet ensures that all (or a subset of) nodes run a copy of a specific Pod. As nodes are added/removed from the cluster, the DaemonSet controller automatically adds/removes pods to maintain one-per-node coverage.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
DaemonSet = exactly one pod per node, automatically.

**One analogy:**

> A DaemonSet is like a smoke detector mandate - every room (node) must have exactly one detector (pod). When a new room is built (node added), a detector is automatically installed. When removed, the detector goes too.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentbit
spec:
  selector:
    matchLabels:
      app: fluentbit
  template:
    metadata:
      labels:
        app: fluentbit
    spec:
      containers:
        - name: fluentbit
          image: fluent/fluent-bit:2.2
          volumeMounts:
            - name: varlog
              mountPath: /var/log
              readOnly: true
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
      tolerations:
        - effect: NoSchedule
          operator: Exists
```

```
DaemonSet behavior:
  3-node cluster:
    Node 1: [fluentbit pod]
    Node 2: [fluentbit pod]
    Node 3: [fluentbit pod]

  Node 4 added:
    Node 4: [fluentbit pod] (auto-created)

  Node 2 removed:
    Node 2: [pod terminated] (auto-removed)

Common DaemonSet use cases:
  - Log collection (Fluentbit, Filebeat)
  - Monitoring (Prometheus node-exporter, Datadog)
  - Networking (Calico, Cilium CNI agents)
  - Storage (CSI node driver)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. DaemonSet = one pod per node (automatically scales with cluster size)
2. Used for infrastructure agents: logging (Fluentbit), monitoring (node-exporter), networking (CNI)
3. Add tolerations to run on ALL nodes including control plane and tainted nodes

**Interview one-liner:**
"DaemonSets ensure exactly one pod per node for infrastructure concerns - I use them for log shipping (Fluentbit reading /var/log), monitoring (node-exporter), and CNI agents (Cilium), with tolerations to cover all nodes including control plane."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for DaemonSet. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Job and CronJob

**TL;DR** - Jobs run pods to completion (batch processing, migrations), while CronJobs schedule Jobs on a time-based schedule (periodic reports, cleanup, backups).
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Not everything is a long-running service. Database migrations, batch reports, and nightly cleanups run once (or periodically) and exit. Deployments restart finished pods - the opposite of what you want.
---

### 📘 Textbook Definition

A Job creates one or more Pods and ensures they successfully terminate. A CronJob creates Jobs on a repeating schedule defined by a cron expression, managing job history and concurrency policy.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```yaml
# One-shot Job (database migration)
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
spec:
  backoffLimit: 3
  activeDeadlineSeconds: 300
  template:
    spec:
      containers:
        - name: migrate
          image: flyway/flyway:10
          args: ["migrate"]
      restartPolicy: Never

---
# CronJob (nightly backup)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
spec:
  schedule: "0 2 * * *" # 2 AM daily
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 5
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: postgres:16
              command: ["pg_dump", "-h", "db-svc"]
          restartPolicy: OnFailure
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Jobs run to completion (exit 0 = success). Deployments run forever. Different tools for different needs.
2. CronJobs schedule Jobs on a cron expression with concurrency control (Allow, Forbid, Replace)
3. Always set `activeDeadlineSeconds` (timeout) and `backoffLimit` (max retries) to prevent runaway jobs

**Interview one-liner:**
"Jobs ensure pods run to completion with configurable retries and timeouts - for migrations, batch processing, and one-shot tasks. CronJobs schedule Jobs periodically with concurrency policies preventing overlap - for backups, reports, and cleanup tasks."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Job and CronJob. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# ReplicaSet

**TL;DR** - A ReplicaSet ensures a specified number of identical pod replicas are running at all times, providing self-healing and horizontal scaling - typically managed by a Deployment rather than directly.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You create 3 pods manually. One dies. Now you have 2. Nobody creates the replacement. You need to constantly watch and manually intervene.
---

### 📘 Textbook Definition

A ReplicaSet maintains a stable set of replica Pods running at any given time by creating or deleting pods as needed to reach the desired replica count. It's identified by its selector (matching pods by labels).
---

### ⏱️ Understand It in 30 Seconds

**One line:**
ReplicaSet = "always have N pods matching this template running."

**One insight:**
You almost NEVER create ReplicaSets directly. Deployments create and manage them. Each Deployment update creates a new ReplicaSet (the previous one is scaled to 0 but kept for rollback history). Understanding ReplicaSets helps debug deployment issues.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Deployment -> ReplicaSet -> Pods

Deployment: "api-server"
  |
  +-> ReplicaSet: "api-server-5d8f7b" (current, 3 replicas)
  |     +-> Pod: api-server-5d8f7b-x7k2s
  |     +-> Pod: api-server-5d8f7b-m9p4t
  |     +-> Pod: api-server-5d8f7b-r3n8w
  |
  +-> ReplicaSet: "api-server-2c4a1e" (previous, 0 replicas)
        (kept for rollback)

Self-healing:
  Pod dies -> ReplicaSet detects 2/3 running
    -> Creates new pod -> Back to 3/3
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. ReplicaSet ensures N pods are always running - creates/deletes pods to match desired count
2. Managed by Deployments - don't create directly (you lose rolling updates and rollback)
3. Deployments keep old ReplicaSets (scaled to 0) for rollback history (`revisionHistoryLimit` controls how many)

**Interview one-liner:**
"ReplicaSets ensure a stable set of identical pods are running by reconciling actual vs desired replica count - in practice always managed by Deployments which create new ReplicaSets on each update and keep old ones for rollback history."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for ReplicaSet. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]
