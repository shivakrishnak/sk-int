---
layout: default
title: "Microservices - Deployment and Delivery"
parent: "Microservices"
grand_parent: "Interview Mastery"
nav_order: 6
permalink: /interview/microservices/deployment-delivery/
topic: Microservices
subtopic: Deployment and Delivery
keywords:
  - Blue-Green Deployment
  - Canary Deployment
  - Zero-Downtime Deployment
  - Feature Flags
  - Progressive Delivery
  - Graceful Shutdown
difficulty_range: medium to hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Blue-Green Deployment](#blue-green-deployment)
- [Canary Deployment](#canary-deployment)
- [Zero-Downtime Deployment](#zero-downtime-deployment)
- [Feature Flags](#feature-flags)
- [Progressive Delivery](#progressive-delivery)
- [Graceful Shutdown](#graceful-shutdown)

# Blue-Green Deployment

**TL;DR** - Blue-Green deployment maintains two identical production environments. "Blue" runs the current version, "Green" runs the new version. Traffic switches from Blue to Green instantly. If Green fails, switch back to Blue in seconds.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Blue-Green Deployment was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
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
You have two identical stages. One is live (Blue), one is standby (Green). Deploy new code to Green, test it, then flip the switch. If something breaks, flip back to Blue instantly.

**Level 2 - How to use it (junior developer):**

```
Step 1: Blue is LIVE, Green is idle
  Load Balancer -> [Blue v1.0] (serving traffic)
                   [Green] (empty)

Step 2: Deploy v2.0 to Green
  Load Balancer -> [Blue v1.0] (still serving)
                   [Green v2.0] (ready, tested)

Step 3: Switch traffic
  Load Balancer -> [Green v2.0] (now serving!)
                   [Blue v1.0] (standby)

Step 4 (if v2.0 has issues): Rollback
  Load Balancer -> [Blue v1.0] (serving again!)
                   [Green v2.0] (investigate)
```

**Level 3 - How it works (mid-level engineer):**

**Implementation options:**

| Platform   | Switch Mechanism                                    |
| ---------- | --------------------------------------------------- |
| Kubernetes | Update Service selector labels                      |
| AWS        | Route 53 weighted routing / ALB target group switch |
| Nginx      | Change upstream server in config + reload           |
| DNS        | Update A/CNAME record (slow - DNS TTL cache)        |

```yaml
# Kubernetes blue-green
# Blue deployment (current)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
  labels:
    version: blue
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: myapp
        version: blue

# Service points to blue
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: blue  # <- Change to "green" to switch

# Deploy green, test, then change selector to "green"
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Database migration challenge:**
Blue-Green assumes both versions can work with the same database. If v2.0 changes the schema, v1.0 (rollback target) won't work.

**Solution: Expand-Contract migrations**

1. **Expand:** Add new column (v2.0 writes to both old and new columns)
2. **Deploy v2.0:** Both Blue and Green can read/write
3. **Contract:** After v1.0 is decommissioned, remove old column




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Blue-Green Deployment. Otherwise remove this section.]
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

**Q1: What's the main disadvantage of Blue-Green deployment?**

_Why they ask:_ Tests awareness of trade-offs.

_Strong answer:_

**Cost:** You need 2x infrastructure. Two full production environments running simultaneously. For a 100-pod service, that's 200 pods during deployment.

**Mitigations:**

1. Cloud auto-scaling: Green environment scales up only during deployment, scales down after Blue is decommissioned
2. Kubernetes: Use rolling update (default) for most services, reserve Blue-Green for critical services needing instant rollback
3. Short deployment window: Green only needs to be fully provisioned for the switch + validation period (minutes, not hours)
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

# Canary Deployment

**TL;DR** - Route a small percentage of production traffic (1-5%) to the new version while the rest stays on the old version. Monitor error rates, latency, and business metrics. If the canary is healthy, gradually increase traffic (10%, 25%, 50%, 100%). If unhealthy, route all traffic back to the old version.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Canary Deployment was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
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
Like a "canary in a coal mine" - send a small test group first. If they're fine, send everyone. If something's wrong, only a few users were affected.

**Level 2 - How to use it (junior developer):**

```
Step 1: 5% to canary
  95% -> [v1.0 - 19 pods]
   5% -> [v2.0 - 1 pod]    <- canary
  Monitor: error rate, latency, 5xx rate

Step 2: Canary healthy (15 min) -> 25%
  75% -> [v1.0 - 15 pods]
  25% -> [v2.0 - 5 pods]

Step 3: Still healthy (30 min) -> 100%
  100% -> [v2.0 - 20 pods]
  v1.0 decommissioned

Canary unhealthy at any step -> 100% back to v1.0
```

**Level 3 - How it works (mid-level engineer):**

**Automated canary analysis:**

```yaml
# Argo Rollouts canary strategy
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
        - setWeight: 5
        - pause: { duration: 10m }
        - analysis:
            templates:
              - templateName: success-rate
            args:
              - name: service-name
                value: myapp
        - setWeight: 25
        - pause: { duration: 15m }
        - setWeight: 50
        - pause: { duration: 15m }
        - setWeight: 100
```

**Canary metrics to monitor:**

| Metric                            | Threshold                | Action      |
| --------------------------------- | ------------------------ | ----------- |
| Error rate (5xx)                  | >1% higher than baseline | Rollback    |
| P99 latency                       | >2x baseline             | Rollback    |
| Business metric (conversion rate) | >5% drop                 | Rollback    |
| CPU/memory                        | >80%                     | Investigate |

**Level 4 - Mastery (senior/staff+ engineer):**

**Canary vs Blue-Green:**

| Aspect              | Canary                         | Blue-Green                                  |
| ------------------- | ------------------------------ | ------------------------------------------- |
| Blast radius        | Small (5% of traffic)          | 100% (all traffic)                          |
| Validation time     | Longer (gradual)               | Shorter (test then switch)                  |
| Rollback speed      | Instant                        | Instant                                     |
| Infrastructure cost | Minimal (1 extra pod)          | 2x (full environment)                       |
| Complexity          | Higher (traffic splitting)     | Lower (simple switch)                       |
| Best for            | Risky changes, large user base | Database migrations, infrastructure changes |




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Canary Deployment. Otherwise remove this section.]
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

**Q1: Your canary shows 0.5% error rate vs 0.3% baseline. Is that significant enough to rollback?**

_Why they ask:_ Tests judgment and statistical reasoning.

_Strong answer:_

**Depends on context:**

1. **Sample size:** If canary has only 100 requests, 0.5% vs 0.3% is 0.5 errors vs 0.3 errors - not statistically significant. Need at least 10,000+ requests.
2. **Error types:** Are the errors new error types or existing ones? New 500s on a previously-stable endpoint = rollback even at 0.1%.
3. **Business impact:** If errors affect payment processing, even 0.2% increase is critical. If errors are on non-critical endpoints, might be acceptable.
4. **Trend:** Is error rate stable at 0.5% or increasing? Stable = might be okay. Increasing = rollback.
5. **Duration:** Wait at least 15-30 minutes to establish a pattern. Short spikes might be noise.

**Decision framework:** Use automated analysis (Kayenta, Argo Rollouts analysis) with statistical significance tests. Don't rely on human eyeballing metrics.
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

# Zero-Downtime Deployment

**TL;DR** - Deploying new code without any service interruption. Users never see a 503 or a dropped connection during deployment. Requires: rolling updates, graceful shutdown, backward-compatible changes, and database migration strategy.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Zero-Downtime Deployment was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
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
Users don't notice you deployed. No maintenance window. No "We'll be back in 5 minutes" page.

**Level 2 - How to use it (junior developer):**

**Requirements for zero-downtime:**

1. Multiple instances (can't update single instance without downtime)
2. Rolling update (update one instance at a time)
3. Health checks (don't send traffic to instances still starting)
4. Graceful shutdown (finish in-flight requests before stopping)
5. Backward-compatible changes (old and new versions run simultaneously)

**Level 3 - How it works (mid-level engineer):**

```yaml
# Kubernetes rolling update
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1 # 1 extra pod during update
      maxUnavailable: 0 # Never reduce below 4
  template:
    spec:
      containers:
        - name: app
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 5
          lifecycle:
            preStop:
              exec:
                command: ["sh", "-c", "sleep 10"]
                # Wait for LB to stop sending traffic
```

**Rolling update sequence:**

```
Start: [v1] [v1] [v1] [v1]  (4 pods)
Step 1: [v1] [v1] [v1] [v1] [v2-starting]
Step 2: [v1] [v1] [v1] [v2-ready] [v1-terminating]
Step 3: [v1] [v1] [v2] [v2-starting]
...
End:    [v2] [v2] [v2] [v2]
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Database migration for zero-downtime:**

```
// BAD: Drop column (breaks old version)
ALTER TABLE orders DROP COLUMN legacy_status;
// Old pods still running -> crash

// GOOD: 3-phase migration
// Phase 1: Add new column (both versions work)
ALTER TABLE orders ADD COLUMN status_v2 VARCHAR;
// Both v1 and v2 can run - v1 ignores status_v2

// Phase 2: Deploy v2 (writes to both columns)
// v2 writes: status_v2 = 'CONFIRMED'
// v2 also writes: legacy_status = 'C' (compat)

// Phase 3: After all pods are v2, drop old column
// (next deploy cycle, not same deploy)
ALTER TABLE orders DROP COLUMN legacy_status;
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Zero-Downtime Deployment. Otherwise remove this section.]
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

**Q1: During a rolling deployment, old pods run v1 and new pods run v2 simultaneously. What problems can this cause?**

_Why they ask:_ Tests awareness of version compatibility.

_Strong answer:_

**Problems:**

1. **API incompatibility:** v2 returns a new response format. Load balancer sends requests randomly to v1 and v2 -> client gets inconsistent responses.
2. **Database schema mismatch:** v2 adds a NOT NULL column. v1 pods can't insert rows.
3. **Cache format change:** v1 writes cache in format A. v2 reads cache expecting format B. Cache corruption.
4. **Message format change:** v2 publishes events with new fields. v1 consumers can't deserialize.

**Prevention:**

1. **Backward-compatible APIs:** v2 adds fields but doesn't remove or rename them. Use API versioning headers.
2. **Expand-contract DB migrations:** Add nullable columns first. Make NOT NULL only after all pods are v2.
3. **Cache versioning:** Include version in cache key (`order:123:v2`). Or clear cache during deploy.
4. **Schema-registered events:** Use Avro/Protobuf with backward compatibility mode. New fields have defaults.
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

# Feature Flags

**TL;DR** - Feature flags decouple deployment from release. Code is deployed to production but hidden behind a flag. The flag controls which users see the new feature. This enables trunk-based development, A/B testing, gradual rollouts, and instant kill switches without redeployment.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Feature Flags was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
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
An on/off switch for features. Deploy code with the switch off. Turn it on for 5% of users. If it works, turn it on for everyone. If it breaks, turn it off instantly - no deploy needed.

**Level 2 - How to use it (junior developer):**

```java
// Simple feature flag
if (featureFlags.isEnabled("new-checkout")) {
    return newCheckoutFlow(order);
} else {
    return oldCheckoutFlow(order);
}

// Gradual rollout
if (featureFlags.isEnabled("new-checkout",
        user.getId())) { // Per-user targeting
    return newCheckoutFlow(order);
}
```

**Level 3 - How it works (mid-level engineer):**

**Types of feature flags:**

| Type              | Lifetime   | Use                                 |
| ----------------- | ---------- | ----------------------------------- |
| Release toggle    | Days-weeks | Gradual rollout of new feature      |
| Experiment toggle | Weeks      | A/B testing (conversion rates)      |
| Ops toggle        | Permanent  | Kill switch for features under load |
| Permission toggle | Permanent  | Premium/free tier features          |

**Feature flag platforms:**

- LaunchDarkly (SaaS, most popular)
- Unleash (open source)
- Flagsmith (open source)
- Split.io (SaaS, experimentation focus)
- Custom (database/config, simplest)

```java
// LaunchDarkly integration
@Service
public class CheckoutService {
    private final LDClient ldClient;

    public CheckoutResponse checkout(
            User user, Order order) {
        LDContext context = LDContext.builder(
            user.getId())
            .set("plan", user.getPlan())
            .set("country", user.getCountry())
            .build();

        boolean useNewFlow = ldClient
            .boolVariation("new-checkout",
                context, false); // default: false

        if (useNewFlow) {
            return newCheckout(order);
        }
        return oldCheckout(order);
    }
}
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Feature flag hygiene:**

1. **Remove flags after full rollout.** Dead flags accumulate. Track flag creation date.
2. **Flag naming convention:** `feature.checkout-redesign`, `ops.disable-recommendations`
3. **Default to off:** New features default to disabled. Fail safe.
4. **Test both paths:** CI must test with flag on AND off. Otherwise flag-off path rots.
5. **Flag dependency:** If feature B depends on feature A, document it. Don't enable B without A.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Feature Flags. Otherwise remove this section.]
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

**Q1: Your team has 47 feature flags in production, some from 2 years ago. What's the risk and how do you fix it?**

_Why they ask:_ Tests operational maturity.

_Strong answer:_

**Risks:**

1. **Code complexity:** 47 flags = potentially 2^47 code paths. Impossible to test all combinations.
2. **Technical debt:** Old flag branches never removed. Dead code everywhere.
3. **Performance:** Each flag evaluation is a check. 47 evaluations per request adds up.
4. **Incidents:** Someone accidentally toggles a 2-year-old flag. Unknown behavior.

**Fix:**

1. **Audit:** List all flags with owner, creation date, last toggled date
2. **Classify:** Release flags >30 days old -> remove. Ops flags -> keep but document.
3. **Policy:** Every release flag gets an expiration date (max 30 days). CI fails if expired flag exists.
4. **Automation:** Scheduled job alerts when flag is older than 30 days. Auto-create cleanup tickets.
5. **Limit:** Max 15 active flags at any time. New flag = remove an old one first.
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

# Progressive Delivery

**TL;DR** - Progressive delivery extends CI/CD with gradual, automated rollout strategies: canary, feature flags, A/B testing, and automated rollback based on real-time metrics. It's CI/CD + canary + feature flags + automated analysis as a unified practice.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Progressive Delivery was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
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
Instead of deploying to everyone at once, deploy gradually with automated safety checks at each step. If any check fails, automatically roll back.

**Level 2 - How to use it (junior developer):**

```
Traditional CI/CD:
  Build -> Test -> Deploy to ALL users

Progressive Delivery:
  Build -> Test -> Deploy to 1% (canary)
    -> Automated metric analysis (10 min)
    -> Passed? -> 10% -> Analysis (15 min)
    -> Passed? -> 50% -> Analysis (15 min)
    -> Passed? -> 100%
    -> Failed at ANY step? -> Automatic rollback
```

**Level 3 - How it works (mid-level engineer):**

**Progressive delivery toolchain:**

| Tool              | Role                              |
| ----------------- | --------------------------------- |
| Argo Rollouts     | Canary + blue-green on Kubernetes |
| Flagger           | Automated canary analysis for K8s |
| LaunchDarkly      | Feature flags for user targeting  |
| Kayenta (Netflix) | Automated canary analysis         |
| Istio             | Traffic splitting for canary      |

**Level 4 - Mastery (senior/staff+ engineer):**

**Full progressive delivery pipeline:**

```
PR merged -> CI builds + tests
  -> Deploy to staging (100% of staging traffic)
  -> Automated smoke tests pass
  -> Deploy canary to production (1%)
  -> Automated analysis: error rate, latency, biz metrics
  -> Expand to 10% (feature flag for beta users)
  -> Expand to 50% (general availability)
  -> Full rollout 100%
  -> Feature flag removed in next sprint
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Progressive Delivery. Otherwise remove this section.]
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

**Q1: How is progressive delivery different from just doing canary deployments?**

_Why they ask:_ Tests understanding of the broader concept.

_Strong answer:_

Canary is one technique within progressive delivery. Progressive delivery is the philosophy + toolchain:

1. **Canary:** Infrastructure-level traffic splitting (by pods/percentage)
2. **Feature flags:** Application-level targeting (by user, segment, geography)
3. **Automated analysis:** No human decides to promote - metrics do
4. **Rollback automation:** Machine triggers rollback, not an engineer at 3 AM
5. **Experimentation:** A/B test business metrics, not just technical health

Progressive delivery = canary + feature flags + automation + experimentation as a unified pipeline.
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

# Graceful Shutdown

**TL;DR** - Graceful shutdown ensures a service instance completes in-flight requests, drains connections, and deregisters from service discovery before stopping. Without it, users see connection resets, 502 errors, and lost messages during deployments.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Graceful Shutdown was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
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
When a store closes, they don't lock the doors with customers inside. They stop letting new people in, serve everyone already inside, then close. Graceful shutdown does the same for a service.

**Level 2 - How to use it (junior developer):**

```
Graceful shutdown sequence:
1. Receive SIGTERM (K8s sends this before killing)
2. Stop accepting new requests
3. Deregister from service discovery / load balancer
4. Complete all in-flight requests (up to timeout)
5. Close database connections, flush buffers
6. Exit process with code 0
```

```java
// Spring Boot graceful shutdown
// application.yml
server:
  shutdown: graceful

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
```

**Level 3 - How it works (mid-level engineer):**

**Kubernetes shutdown sequence:**

```
1. K8s sends SIGTERM to pod
2. Pod marked as "Terminating"
3. Pod removed from Service endpoints
   (BUT LB might still route traffic for ~5s!)
4. preStop hook runs
   (sleep 10 - wait for LB to catch up)
5. App handles SIGTERM -> graceful shutdown
6. After terminationGracePeriodSeconds (30s default)
   -> K8s sends SIGKILL (force kill)
```

```yaml
spec:
  terminationGracePeriodSeconds: 60
  containers:
    - name: app
      lifecycle:
        preStop:
          exec:
            command: ["sh", "-c", "sleep 10"]
            # Wait for load balancer to stop
            # sending new traffic
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Kafka consumer graceful shutdown:**

```java
@PreDestroy
public void shutdown() {
    // 1. Stop polling for new messages
    consumer.wakeup();

    // 2. Process current batch to completion
    // (in-flight batch finishes naturally)

    // 3. Commit offsets for processed messages
    consumer.commitSync();

    // 4. Close consumer (triggers rebalance)
    consumer.close(Duration.ofSeconds(30));

    // Without this: messages processed but offset
    // not committed -> reprocessed after restart
    // -> duplicates!
}
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Graceful Shutdown. Otherwise remove this section.]
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

**Q1: During deployment, users report sporadic 502 errors for about 5 seconds. What's happening?**

_Why they ask:_ Tests understanding of the shutdown timing gap.

_Strong answer:_

**Root cause:** Race condition between pod termination and load balancer update.

```
Timeline:
T+0s: K8s sends SIGTERM to pod
T+0s: App starts shutdown immediately
T+2s: App stops accepting connections
T+3s: K8s endpoint controller removes pod
T+5s: kube-proxy updates iptables rules
T+5s: Load balancer stops sending traffic

Between T+0s and T+5s: LB still sends requests
to a pod that's shutting down -> 502 errors
```

**Fix:** Add `preStop` hook with `sleep 10`:

```yaml
lifecycle:
  preStop:
    exec:
      command: ["sh", "-c", "sleep 10"]
```

This delays app shutdown by 10 seconds. During those 10 seconds, the load balancer catches up and stops sending traffic. Then the app shuts down gracefully.
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
