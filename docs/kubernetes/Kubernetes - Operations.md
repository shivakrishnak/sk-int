---
layout: default
title: "Kubernetes - Operations"
parent: "Kubernetes"
grand_parent: "Interview Mastery"
nav_order: 6
permalink: /interview/kubernetes/operations/
topic: Kubernetes
subtopic: Operations
keywords:
  - Horizontal Pod Autoscaler
  - Resource Management
  - Health Probes
  - Rolling Updates
  - Helm
  - Cluster Upgrades
difficulty_range: hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Horizontal Pod Autoscaler](#horizontal-pod-autoscaler)
- [Resource Management](#resource-management)
- [Health Probes](#health-probes)
- [Rolling Updates](#rolling-updates)
- [Helm](#helm)
- [Cluster Upgrades](#cluster-upgrades)

# Horizontal Pod Autoscaler

**TL;DR** - HPA automatically scales pod replicas based on observed metrics (CPU, memory, custom metrics) to match demand - scaling up during traffic spikes and down during quiet periods to optimize cost and performance.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You set replicas: 3. At 2 AM, 3 pods waste money serving no traffic. At 2 PM during a sale, 3 pods are overwhelmed. Manual scaling means someone watching dashboards 24/7 or over-provisioning permanently.

**THE INVENTION MOMENT:**
"This is exactly why Horizontal Pod Autoscaler was created."
---

### 📘 Textbook Definition

The Horizontal Pod Autoscaler automatically scales the number of pod replicas in a Deployment, ReplicaSet, or StatefulSet based on observed CPU utilization, memory usage, or custom/external metrics, using a control loop that periodically (default 15s) queries the metrics API and adjusts replicas.
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
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 2
  maxReplicas: 20
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

```
HPA Control Loop:
  desiredReplicas = ceil(currentReplicas *
    (currentMetric / desiredMetric))

  Example: 3 replicas, 90% CPU, target 70%
    ceil(3 * (90/70)) = ceil(3.86) = 4 replicas

  Scale-up: Fast (react to spikes quickly)
  Scale-down: Slow (avoid flapping)
    stabilizationWindow prevents rapid down-scaling

Prerequisites:
  1. metrics-server installed (resource metrics)
  2. Pods MUST have resource requests set
     (HPA uses requests as 100% baseline)
  3. Custom metrics: Prometheus adapter or KEDA
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

1. HPA requires resource requests on pods - without them, CPU/memory percentage can't be calculated
2. Scale up fast, scale down slow (stabilization window prevents flapping during transient spikes)
3. For advanced use cases (queue depth, request latency, events): use KEDA (Kubernetes Event-Driven Autoscaler) with 50+ scalers

**Interview one-liner:**
"HPA scales replicas based on observed metrics against target utilization - I set CPU target at 70%, configure asymmetric behavior (fast scale-up, slow scale-down with 5-min stabilization), always ensure pods have resource requests, and use KEDA for event-driven scaling from queues or custom metrics."
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

[TODO: Include if 2+ named alternatives exist for Horizontal Pod Autoscaler. Otherwise remove this section.]
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

**Q1: HPA keeps scaling up but pods aren't getting more traffic. What's wrong?**

_Why they ask:_ Tests debugging autoscaler behavior.

**Answer:**
Root causes:

1. **Pods failing readiness probes** - HPA sees high CPU on existing pods (they're overloaded), scales up, but new pods fail readiness so they don't receive traffic. Existing pods stay overloaded. Infinite scaling.
2. **Resource requests too low** - Pod requests 100m CPU but uses 500m normally. HPA thinks it's at 500% utilization and keeps scaling.
3. **Insufficient cluster capacity** - Pods are pending (not enough nodes). Need Cluster Autoscaler to add nodes.
4. **External bottleneck** - Database connection pool exhausted. More pods can't help if the bottleneck is downstream.

Debug:

```bash
kubectl get hpa api-hpa
kubectl describe hpa api-hpa  # Check events and metrics
kubectl top pods -l app=api   # Actual resource usage
kubectl get pods -l app=api   # Check for pending/crashloop
```
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

# Resource Management

**TL;DR** - Resource management (requests, limits, LimitRanges, ResourceQuotas) controls how much CPU and memory pods can use, enabling fair scheduling, preventing noisy neighbors, and controlling costs across teams.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
One team deploys a memory-leaking app that consumes all node memory, causing OOM kills of other teams' pods. No way to limit cost per team. Scheduler can't make informed placement decisions. Everything fights for resources.
---

### 📘 Textbook Definition

Kubernetes resource management uses requests (guaranteed minimum for scheduling) and limits (maximum allowed, enforced by kernel) for CPU and memory, with LimitRanges setting per-pod defaults and ResourceQuotas capping total namespace consumption.
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
# Pod resource specification
spec:
  containers:
    - name: app
      resources:
        requests: # Guaranteed (scheduling)
          cpu: "250m" # 0.25 CPU cores
          memory: "256Mi" # 256 MiB
        limits: # Maximum (enforcement)
          cpu: "1000m" # 1 CPU core
          memory: "512Mi" # OOM killed if exceeded

---
# LimitRange (defaults for namespace)
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
    - type: Container
      default: # Default limits
        cpu: "500m"
        memory: "512Mi"
      defaultRequest: # Default requests
        cpu: "100m"
        memory: "128Mi"
      max:
        cpu: "4"
        memory: "4Gi"

---
# ResourceQuota (total for namespace)
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "20"
    requests.memory: "40Gi"
    limits.cpu: "40"
    limits.memory: "80Gi"
    pods: "50"
```

```
Key concepts:
  Request: Used for SCHEDULING decisions
    "I need at least this much to function"
    Scheduler places pod on node with enough free

  Limit: ENFORCED by kernel
    CPU limit: throttled (not killed)
    Memory limit: OOM killed (no throttling possible)

  QoS Classes (based on requests/limits):
    Guaranteed: requests == limits (both set, equal)
      Last to be evicted
    Burstable:  requests < limits (partially set)
      Evicted after BestEffort
    BestEffort: No requests or limits
      First to be evicted under pressure
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

1. Requests = scheduling guarantee (node must have capacity). Limits = kernel enforcement (CPU throttled, memory OOM killed).
2. Always set memory limits (OOM kills without them are unpredictable). CPU limits are debatable (throttling can cause latency spikes).
3. QoS: Guaranteed (req=limit) is evicted last. BestEffort (no req/limit) is evicted first. Always set at least requests.

**Interview one-liner:**
"Requests guarantee scheduling capacity and define QoS class, limits enforce maximums (CPU=throttle, memory=OOM-kill) - I always set memory limits and requests, use LimitRanges for namespace defaults, and ResourceQuotas for team-level cost control and fair sharing."
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

[TODO: Include if 2+ named alternatives exist for Resource Management. Otherwise remove this section.]
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

# Health Probes

**TL;DR** - Liveness, readiness, and startup probes tell Kubernetes when to restart a pod (broken), when to route traffic to it (ready), and when to give it extra startup time - critical for zero-downtime operations.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A pod's container is running (PID 1 alive) but the application is deadlocked. Kubernetes thinks it's healthy and routes traffic to it. Users get timeouts. Nobody restarts the broken pod because the container technically hasn't crashed.

**THE INVENTION MOMENT:**
"This is exactly why Kubernetes health probes were created."
---

### 📘 Textbook Definition

Kubernetes probes are periodic diagnostic checks performed by the kubelet: liveness probes determine if a container should be restarted (application stuck), readiness probes determine if traffic should be routed to it (ready to serve), and startup probes disable liveness checks during slow initialization.
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
spec:
  containers:
    - name: app
      image: myapp:1.0
      ports:
        - containerPort: 8080

      # Restart if this fails (deadlock detection)
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 15
        periodSeconds: 10
        failureThreshold: 3
        timeoutSeconds: 3

      # Remove from Service if this fails
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 3
        successThreshold: 1

      # Give slow-starting app time to boot
      startupProbe:
        httpGet:
          path: /healthz
          port: 8080
        failureThreshold: 30
        periodSeconds: 10
        # Total: 300s to start before liveness kicks in
```

```
Probe types:
  httpGet:    HTTP GET, success = 200-399
  tcpSocket:  TCP connection, success = port open
  exec:       Run command, success = exit code 0
  grpc:       gRPC health check protocol

Three probes, three purposes:
  Startup:   "Are you done starting?"
             (disables liveness until success)
  Liveness:  "Are you still alive?"
             (failure -> container restart)
  Readiness: "Can you handle traffic now?"
             (failure -> removed from Service endpoints)

Common mistakes:
  - Liveness checking dependencies (DB down ->
    restart app -> doesn't help, causes restart storm)
  - No readiness probe during rolling update
    (traffic hits unready pods -> errors)
  - Timeout too short for heavy endpoints
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

1. Liveness = restart if broken (check APP health, not dependencies). Readiness = remove from traffic if busy/starting.
2. NEVER check external dependencies in liveness probe - DB being down doesn't mean your app should restart (causes cascade)
3. Always use startup probe for slow-starting apps (Java, etc.) to prevent liveness from killing during boot

**Interview one-liner:**
"I configure all three probes: startup for slow-initializing apps (avoids premature liveness kills), liveness checking only internal application health (never external deps), and readiness for traffic routing - critical for zero-downtime rolling updates where new pods must pass readiness before receiving traffic."
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

[TODO: Include if 2+ named alternatives exist for Health Probes. Otherwise remove this section.]
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

# Rolling Updates

**TL;DR** - Rolling updates gradually replace old pods with new ones, maintaining availability throughout the deployment by controlling how many pods can be unavailable (maxUnavailable) and how many extra pods can exist (maxSurge) during the transition.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Deployment update = kill all old pods, start new ones. During the gap, zero capacity. Users experience downtime. If new version is broken, 100% of traffic hits the broken version before anyone notices.
---

### 📘 Textbook Definition

A rolling update incrementally replaces pods of the previous version with pods of the new version in a controlled manner, ensuring that a minimum number of pods remain available and a maximum number of extra pods are created during the update process.
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
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25% # Max extra pods (ceiling)
      maxUnavailable: 25% # Max pods down (floor)
  # With 4 replicas:
  #   maxSurge: 1 (25% of 4, ceil)
  #   maxUnavailable: 1 (25% of 4, floor)
  #   During update: min 3, max 5 pods
```

```
Zero-downtime rolling update recipe:
  1. maxUnavailable: 0 (never fewer than desired)
  2. maxSurge: 1+ (allow extra pods to start)
  3. readinessProbe configured (don't route to unready)
  4. preStop hook: sleep 5 (drain connections)
  5. terminationGracePeriodSeconds: 30+ (finish requests)

Sequence (maxUnavailable:0, maxSurge:1):
  [v1] [v1] [v1]          - Desired: 3
  [v1] [v1] [v1] [v2...]  - v2 starting (surge)
  [v1] [v1] [v1] [v2 OK]  - v2 passes readiness
  [v1] [v1] [v2] [v2...]  - Old v1 terminating, new v2 starting
  [v1] [v2] [v2] [v2...]  - Continue...
  [v2] [v2] [v2]          - Complete

Graceful shutdown:
  1. Pod marked for termination
  2. Removed from Service endpoints (no new traffic)
  3. preStop hook executes (sleep 5 -> time for endpoints to propagate)
  4. SIGTERM sent to container
  5. App drains in-flight requests
  6. Container exits (or killed after grace period)
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

1. maxSurge + maxUnavailable control update speed. `maxUnavailable: 0` ensures zero downtime but requires extra capacity (maxSurge).
2. Without readiness probes, rolling updates route traffic to unready pods - the #1 cause of errors during deployments
3. Graceful shutdown: preStop hook (5s sleep) + SIGTERM handler + terminationGracePeriod to drain in-flight requests

**Interview one-liner:**
"Zero-downtime rolling updates require: maxUnavailable:0 with maxSurge for capacity, readiness probes to gate traffic routing, and preStop hooks with graceful SIGTERM handling to drain in-flight requests before pod termination - validated with `kubectl rollout status` and automated rollback on error rates."
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

[TODO: Include if 2+ named alternatives exist for Rolling Updates. Otherwise remove this section.]
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

# Helm

**TL;DR** - Helm is the package manager for Kubernetes - it templates, packages, versions, and manages complex multi-resource applications as a single unit (chart), enabling reusable deployments across environments with value-based customization.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Deploying an application requires 10+ YAML files (Deployment, Service, ConfigMap, Secret, HPA, PDB, NetworkPolicy...). Customizing for dev vs prod means duplicating all files or maintaining error-prone sed scripts. No versioning, no rollback.

**THE INVENTION MOMENT:**
"This is exactly why Helm was created."
---

### 📘 Textbook Definition

Helm is a package manager for Kubernetes that bundles multiple resource manifests into versioned charts, uses Go templates for parameterization via values files, manages releases with upgrade/rollback history, and provides dependency management for complex applications.
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

```
Helm chart structure:
  mychart/
    Chart.yaml          # Chart metadata, version
    values.yaml         # Default config values
    templates/
      deployment.yaml   # Templated manifest
      service.yaml
      _helpers.tpl      # Template helpers
    charts/             # Dependencies

Template example (deployment.yaml):
  replicas: {{ .Values.replicaCount }}
  image: {{ .Values.image.repository }}:{{ .Values.image.tag }}

values.yaml (defaults):
  replicaCount: 3
  image:
    repository: myapp
    tag: "1.0"

values-prod.yaml (override):
  replicaCount: 10
  image:
    tag: "2.1"
```

```bash
# Install chart
helm install my-release ./mychart \
  -f values-prod.yaml -n production

# Upgrade (new chart version or new values)
helm upgrade my-release ./mychart \
  --set image.tag=2.2

# Rollback to previous revision
helm rollback my-release 1

# List releases
helm list -n production

# View computed manifests (debug)
helm template my-release ./mychart \
  -f values-prod.yaml
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

1. Helm = Kubernetes package manager. Chart = package. Release = installed instance. Values = configuration per environment.
2. `helm template` renders YAML locally without installing - essential for GitOps (render then apply via ArgoCD)
3. Helm 3 is tiller-less (no server component) - releases stored as secrets in the namespace, purely client-side

**Interview one-liner:**
"Helm packages Kubernetes applications as versioned charts with Go templating for environment customization - I use it with values files per environment, `helm template` for GitOps integration with ArgoCD, and maintain charts with proper dependency management and semantic versioning."
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

[TODO: Include if 2+ named alternatives exist for Helm. Otherwise remove this section.]
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

# Cluster Upgrades

**TL;DR** - Kubernetes cluster upgrades follow a sequential version progression (one minor version at a time), upgrading control plane first then nodes, with proper testing, pod disruption budgets, and rollback plans to maintain availability.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Kubernetes releases every 4 months with a 14-month support window. Falling behind means no security patches, deprecated APIs breaking workloads, and eventually a painful multi-version jump.
---

### 📘 Textbook Definition

Cluster upgrades update Kubernetes components (API server, etcd, kubelet, kube-proxy) to newer versions following the version skew policy: kube-apiserver can be at most one minor version ahead of kubelet, and upgrades must proceed sequentially (1.27 -> 1.28 -> 1.29, never skip).
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

```
Upgrade strategy (managed K8s: EKS/GKE/AKS):

1. Pre-upgrade:
   - Check deprecated API usage:
     kubectl get --raw /metrics | grep apiserver_requested_deprecated_apis
     OR: pluto detect-helm
   - Test in staging cluster first
   - Review K8s changelog for breaking changes
   - Ensure PodDisruptionBudgets are set

2. Control plane upgrade (managed):
   - EKS: aws eks update-cluster-version
   - GKE: gcloud container clusters upgrade
   - Automatic, zero-downtime for workloads

3. Node upgrade (rolling):
   - Cordon node (no new pods scheduled)
   - Drain node (evict pods respecting PDBs)
   - Upgrade node (new AMI/image)
   - Uncordon node (rejoin cluster)
   - Repeat for each node

4. Post-upgrade:
   - Verify all workloads healthy
   - Update client tools (kubectl, helm)
   - Update any version-locked addons
```

```yaml
# PodDisruptionBudget (protects during drain)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  minAvailable: 2 # OR maxUnavailable: 1
  selector:
    matchLabels:
      app: api-server
# During node drain, won't evict if it would violate PDB
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

1. Upgrade sequentially (never skip minor versions). Control plane first, then nodes. Version skew: kubelet can be up to 2 minor versions behind API server.
2. PodDisruptionBudgets protect workloads during node drains - set them for all production workloads (minAvailable or maxUnavailable)
3. Check deprecated APIs BEFORE upgrading (`pluto detect-helm`, `kubectl deprecations`) - removed APIs break workloads immediately

**Interview one-liner:**
"I maintain quarterly upgrade cadence (within support window), testing in staging first, checking deprecated APIs with pluto, ensuring PDBs protect workloads during node rolling upgrades, and using managed K8s (EKS/GKE) where control plane upgrades are handled automatically."
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

[TODO: Include if 2+ named alternatives exist for Cluster Upgrades. Otherwise remove this section.]
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

**Q1: Your company is on K8s 1.24 and needs to get to 1.29. What's your upgrade plan?**

_Why they ask:_ Tests upgrade planning across multiple versions.

**Answer:**
Five sequential upgrades required: 1.24->1.25->1.26->1.27->1.28->1.29

Plan:

1. **Audit all clusters** for deprecated/removed APIs at each version:
   - 1.25: PodSecurityPolicy REMOVED (must migrate to PSS)
   - 1.27: Several beta APIs removed
   - Use `pluto` and `kubent` to scan

2. **Staging first for EACH hop**:
   - Upgrade staging cluster one version
   - Run full test suite
   - Verify all workloads healthy (7 days soak)
   - Only then upgrade production

3. **Per-hop execution** (each version):
   - Pre-check: deprecated API scan, addon compatibility
   - Control plane upgrade (managed service handles this)
   - Node group rolling upgrade (surge strategy: create new node group, drain old)
   - Post-check: all pods running, metrics normal
   - 1-week observation before next hop

4. **Critical for 1.24->1.25 specifically**:
   - PodSecurityPolicy -> Pod Security Standards migration
   - This is the hardest hop - plan 2-4 weeks for PSP migration alone

Timeline: ~3-4 months for 5 hops with proper testing. Don't rush it.
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
