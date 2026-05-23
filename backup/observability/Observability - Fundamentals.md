---
layout: default
title: "Observability - Fundamentals"
parent: "Observability"
grand_parent: "Interview Mastery"
nav_order: 1
permalink: /interview/observability/fundamentals/
topic: Observability
subtopic: Fundamentals
keywords:
  - Three Pillars of Observability
  - Golden Signals
  - SLI SLO SLA
  - Structured Logging
  - Distributed Tracing
  - Alerting Strategy
difficulty_range: medium-hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Three Pillars of Observability](#three-pillars-of-observability)
- [Golden Signals](#golden-signals)
- [SLI SLO SLA](#sli-slo-sla)
- [Structured Logging](#structured-logging)
- [Distributed Tracing](#distributed-tracing)
- [Alerting Strategy](#alerting-strategy)

# Three Pillars of Observability

**TL;DR** - The three pillars of observability are Metrics (numeric measurements over time), Logs (discrete event records), and Traces (request flow across services) - together they answer what's broken, why it broke, and where it broke in distributed systems.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A user reports "the app is slow." With no observability, you SSH into servers, tail logs, guess which service is slow, add print statements, redeploy, and hope to reproduce it. Hours wasted on a problem that should take minutes to diagnose.

**THE INVENTION MOMENT:**
"This is exactly why observability was formalized as a discipline."

**EVOLUTION:**
Monitoring (is it up?) -> Logging (what happened?) -> APM (where is it slow?) -> Observability (understand ANY system behavior from external outputs without deploying new code).
---

### 📘 Textbook Definition

Observability is the ability to understand a system's internal state by examining its external outputs. The three pillars - metrics (aggregated numeric measurements), logs (discrete timestamped events), and traces (causal chains across services) - together provide the data needed to answer arbitrary questions about system behavior without deploying new instrumentation.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Metrics tell you WHAT is wrong, logs tell you WHY, traces tell you WHERE.

**One analogy:**

> Metrics are like a car dashboard (speed, RPM, temperature - quick health check). Logs are like a mechanic's diagnostic report (detailed record of every event). Traces are like GPS tracking a package through the delivery network (which hub caused the delay).

**One insight:**
Observability != monitoring. Monitoring answers predetermined questions ("Is CPU > 80%?"). Observability answers questions you didn't know you'd ask ("Why do 3% of users in EU see 5s latency only on Tuesdays?"). You need all three pillars for true observability.
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
Three Pillars:

METRICS (What's happening? How much?)
  - Numeric values over time (counters, gauges, histograms)
  - Aggregatable, cheap to store, fast to query
  - Example: request_count, error_rate, latency_p99
  - Tools: Prometheus, Datadog, CloudWatch

LOGS (What happened? Why?)
  - Discrete events with context (structured JSON)
  - Rich detail but expensive at scale
  - Example: {"level":"error", "msg":"DB timeout",
              "user_id":"123", "latency_ms":5200}
  - Tools: ELK, Loki, CloudWatch Logs

TRACES (Where? Which path?)
  - Request flow across services (spans)
  - Shows causality and timing breakdown
  - Example: Frontend(50ms) -> API(200ms) -> DB(4800ms)
  - Tools: Jaeger, Zipkin, Tempo, X-Ray

Correlation (the real power):
  Metric alert: "p99 latency > 2s"
    -> Exemplar links to a trace ID
      -> Trace shows: DB query took 4.8s
        -> Logs with trace ID show: "lock wait timeout"
          -> Root cause identified in minutes
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

1. Metrics = WHAT (aggregated, cheap, alerts). Logs = WHY (detailed, expensive). Traces = WHERE (causal path across services).
2. Correlation between pillars is key: metric alert -> exemplar trace -> correlated logs = fast root cause analysis
3. OpenTelemetry unifies all three pillars with one SDK/protocol - the industry standard replacing vendor-specific agents

**Interview one-liner:**
"The three observability pillars - metrics for aggregated signals and alerting, logs for detailed event context, and traces for request flow across services - are most powerful when correlated via trace IDs, enabling metric alert -> trace -> log drill-down for rapid root cause analysis, unified by OpenTelemetry."
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

[TODO: Include if 2+ named alternatives exist for Three Pillars of Observability. Otherwise remove this section.]
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

# Golden Signals

**TL;DR** - The Four Golden Signals (Latency, Traffic, Errors, Saturation) are the essential metrics to monitor for any service - from Google's SRE book, they tell you if your service is healthy and where to look when it's not.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Teams monitor 500 metrics. Dashboards have 50 panels. Alert fatigue from noise. When something breaks, nobody knows which metric matters. Too much data, not enough signal.

**THE INVENTION MOMENT:**
"This is exactly why Google SRE defined the four golden signals."
---

### 📘 Textbook Definition

The Four Golden Signals (from Google's SRE book) are the four critical measurements for monitoring user-facing systems: Latency (time to serve a request), Traffic (demand on the system), Errors (rate of failed requests), and Saturation (how full the system is).
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
Four Golden Signals:

1. LATENCY (How fast?)
   - Time to service a request
   - Measure: p50, p95, p99 (not just average!)
   - Important: separate successful vs failed latency
     (a fast 500 error is NOT good latency)
   - Example: p99 response time < 200ms

2. TRAFFIC (How much?)
   - Demand on the system
   - Measure: requests/second, transactions/second
   - For different systems:
     Web: HTTP requests/sec
     DB: queries/sec
     Stream: messages/sec

3. ERRORS (How broken?)
   - Rate of failed requests
   - Types: explicit (5xx), implicit (200 with wrong data),
            policy (response > 1s counted as error)
   - Measure: error rate = errors / total requests

4. SATURATION (How full?)
   - How close to capacity
   - Measure: CPU%, memory%, disk%, queue depth
   - Most useful as "how close to degradation"
   - Saturation often predicts FUTURE problems

Also known as: RED method (Rate, Errors, Duration)
  for request-driven services

And: USE method (Utilization, Saturation, Errors)
  for resource-based systems (CPU, disk, network)
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

1. Four signals: Latency (how fast), Traffic (how much), Errors (how broken), Saturation (how full). Monitor these FIRST for any service.
2. Latency: always use percentiles (p95, p99), never averages. Average hides the tail. Separate success vs error latency.
3. Related frameworks: RED (Rate/Errors/Duration) for services, USE (Utilization/Saturation/Errors) for resources.

**Interview one-liner:**
"I structure monitoring around Google's four golden signals - latency (percentile-based, p95/p99 not averages), traffic (requests/sec), errors (explicit 5xx + implicit failures), and saturation (resource headroom) - using RED for services and USE for infrastructure resources."
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

[TODO: Include if 2+ named alternatives exist for Golden Signals. Otherwise remove this section.]
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

# SLI SLO SLA

**TL;DR** - SLIs measure service quality (latency percentile), SLOs set internal targets (99.9% requests < 200ms), SLAs are contractual guarantees with consequences (99.5% uptime or credits) - together they create a framework for reliability decisions and error budget management.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
"We need 100% uptime!" (impossible and expensive). No shared understanding of "good enough" reliability. Engineering over-invests in reliability for non-critical services. Under-invests for critical ones. No framework for deciding when to prioritize reliability vs features.

**THE INVENTION MOMENT:**
"This is exactly why SLIs/SLOs/SLAs were formalized."
---

### 📘 Textbook Definition

**SLI** (Service Level Indicator): A quantitative measure of service behavior (e.g., proportion of requests faster than 200ms). **SLO** (Service Level Objective): A target value for an SLI that the service aims to meet (e.g., 99.9% of requests < 200ms over 30 days). **SLA** (Service Level Agreement): A contractual guarantee with consequences for violation (e.g., financial credits if availability < 99.5%).
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
SLI -> SLO -> SLA (from specific to contractual):

SLI (what you measure):
  - "Proportion of HTTP requests returning in < 200ms"
  - "Proportion of HTTP requests that are not 5xx"
  - Measured from user perspective (not server CPU!)

SLO (your internal target):
  - "99.9% of requests complete in < 200ms"
  - "99.95% availability (measured at load balancer)"
  - Internal team commitment, drives error budget

SLA (contractual promise):
  - "99.5% monthly availability (or 10% credit)"
  - Always LESS strict than SLO (buffer zone!)
  - Violation = legal/financial consequences

  SLO > SLA (always!)
  If SLO = 99.9%, SLA might be 99.5%
  Buffer between SLO and SLA = safety margin

Error Budget:
  SLO = 99.9% -> Error budget = 0.1%
  In 30 days = 43.2 minutes of allowed downtime

  Budget remaining -> Ship features (move fast)
  Budget exhausted -> Focus on reliability (freeze features)

  This is THE mechanism for balancing speed vs reliability
```

```
Availability levels and downtime:
  | SLO     | Downtime/month | Downtime/year |
  |---------|----------------|---------------|
  | 99%     | 7.3 hours      | 3.65 days     |
  | 99.9%   | 43.8 minutes   | 8.77 hours    |
  | 99.95%  | 21.9 minutes   | 4.38 hours    |
  | 99.99%  | 4.38 minutes   | 52.6 minutes  |
  | 99.999% | 26.3 seconds   | 5.26 minutes  |

  Each additional "9" costs 10x more to achieve!
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

1. SLI (measured indicator) -> SLO (internal target, drives error budget) -> SLA (contractual, less strict than SLO, has consequences)
2. Error budget = 100% - SLO%. When exhausted, freeze features and fix reliability. When available, ship features. THIS is how you balance speed vs stability.
3. Measure SLIs from user perspective (load balancer, not server CPU). "Was the user's request fast and successful?"

**Interview one-liner:**
"SLIs quantify user-facing quality (latency, availability), SLOs set reliability targets driving error budgets (the mechanism for balancing feature velocity vs stability), and SLAs are looser contractual guarantees - I measure SLIs at the load balancer and use error budget burn rate for alerting."
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

[TODO: Include if 2+ named alternatives exist for SLI SLO SLA. Otherwise remove this section.]
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

**Q1: How do you choose the right SLO for a service?**

_Why they ask:_ Tests practical SLO engineering.

**Answer:**
Process:

1. **Start with user expectations**: What latency/availability do users actually notice? Measure current performance as baseline.
2. **Consider dependencies**: Your SLO can't exceed your dependencies. If your DB is 99.95%, your service can't be 99.99%.
3. **Consider cost**: Each additional 9 costs ~10x more. 99.99% needs multi-region, automatic failover, etc. Is the business value worth it?
4. **Start conservative, tighten later**: Begin with 99.5%, measure, then tighten to 99.9% when you can sustain it.

Per service tier:

- **Tier 1** (revenue-critical: checkout, auth): 99.95%, p99 < 200ms
- **Tier 2** (user-facing: search, recommendations): 99.9%, p99 < 500ms
- **Tier 3** (internal: batch processing, reports): 99.5%, p99 < 5s
- **Tier 4** (best-effort: analytics, logs): 99%, no latency SLO

Key insight: Not all services deserve the same SLO. Over-engineering reliability for a Tier 3 service wastes resources that should improve Tier 1.
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

# Structured Logging

**TL;DR** - Structured logging outputs log events as machine-parseable key-value pairs (typically JSON) instead of free-text strings, enabling efficient searching, filtering, aggregation, and correlation across distributed services.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**

```
[2024-01-15 10:23:45] ERROR - Failed to process order 12345 for user john@example.com: timeout after 5000ms
```

How do you find all errors for user X? All timeouts > 3s? Aggregate error count by endpoint? With free-text logs: regex, hoping format is consistent. At 1TB/day: impossible.
---

### 📘 Textbook Definition

Structured logging is the practice of recording log events as structured data (key-value pairs, typically JSON) with consistent fields across all services, enabling programmatic querying, filtering, aggregation, and correlation through log management systems.
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
Unstructured (BAD):
  "2024-01-15 10:23:45 ERROR OrderService - Failed
   to process order 12345 for user john: timeout"

Structured (GOOD):
  {
    "timestamp": "2024-01-15T10:23:45.123Z",
    "level": "error",
    "service": "order-service",
    "trace_id": "abc123def456",
    "span_id": "789ghi",
    "message": "Order processing failed",
    "order_id": "12345",
    "user_id": "user-789",
    "error_type": "timeout",
    "duration_ms": 5000,
    "endpoint": "/api/orders",
    "environment": "production"
  }

Now you can:
  - Find all errors: level == "error"
  - User's history: user_id == "user-789"
  - Timeout analysis: error_type == "timeout" AND
                      duration_ms > 3000
  - Aggregate: count by service, endpoint, error_type
  - Correlate: trace_id links to distributed trace

Essential fields:
  timestamp, level, service, trace_id, message
  + context-specific fields (user_id, order_id, etc.)
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

1. JSON structured logs = machine-parseable. Free-text logs = requires regex and prayer at scale.
2. Always include trace_id in logs - this is what connects logs to distributed traces for correlation
3. Log levels matter: ERROR (something broke, needs attention), WARN (degraded but working), INFO (notable events), DEBUG (development only, never in production at volume)

**Interview one-liner:**
"I implement structured JSON logging with mandatory fields (timestamp, level, service, trace_id) plus context fields (user_id, request_id) - enabling efficient search and aggregation in ELK/Loki, automatic correlation with distributed traces, and meaningful alerting on structured queries."
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

[TODO: Include if 2+ named alternatives exist for Structured Logging. Otherwise remove this section.]
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

# Distributed Tracing

**TL;DR** - Distributed tracing tracks a single request as it flows through multiple services, showing exactly which service/operation caused latency or failure - essential for debugging microservices where a user request touches 10+ services.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
User reports "checkout is slow." Request hits: API gateway -> auth service -> product service -> inventory service -> payment service -> order service -> notification service. Which one is slow? Logs from 7 services, no correlation. You're guessing.

**THE INVENTION MOMENT:**
"This is exactly why distributed tracing was created."
---

### 📘 Textbook Definition

Distributed tracing is an observability technique that records the causal chain of operations (spans) that comprise a distributed transaction, propagating a unique trace context (trace ID) across service boundaries to provide end-to-end visibility into request latency, errors, and dependencies.
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
Trace structure:
  Trace (entire request lifecycle):
    trace_id: abc123
    |
    +-- Span: API Gateway (50ms)
    |     |
    |     +-- Span: Auth Service (20ms)
    |     |
    |     +-- Span: Product Service (150ms)
    |           |
    |           +-- Span: Database Query (120ms) <-- BOTTLENECK!
    |
    +-- Span: Payment Service (200ms)
    |     |
    |     +-- Span: Stripe API call (180ms)
    |
    +-- Span: Order Service (30ms)

  Total: 450ms. Root cause: DB query in product service

Context propagation:
  Service A adds header: traceparent: 00-abc123-span1-01
    -> Service B reads header, creates child span
      -> Service C reads header, creates child span
        -> All spans linked by trace_id: abc123

W3C Trace Context standard:
  traceparent: 00-{trace-id}-{parent-span-id}-{flags}
  Example: 00-abc123def456-span789-01
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

1. A trace is a tree of spans. Each span = one operation (HTTP call, DB query, queue publish). trace_id links them all.
2. Context propagation (W3C traceparent header) passes trace_id across service boundaries automatically via SDK/agent
3. OpenTelemetry is the standard for instrumentation. Jaeger/Tempo/Zipkin/X-Ray are backends for storage and visualization.

**Interview one-liner:**
"Distributed tracing propagates trace context (W3C traceparent) across service boundaries, building a span tree showing exactly where time is spent - I use OpenTelemetry for auto-instrumentation with Jaeger/Tempo as backend, correlating traces with metrics (exemplars) and logs (trace_id field) for full observability."
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

[TODO: Include if 2+ named alternatives exist for Distributed Tracing. Otherwise remove this section.]
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

# Alerting Strategy

**TL;DR** - An effective alerting strategy focuses on symptoms (user impact) not causes (CPU high), uses multi-window burn rate for SLO-based alerts, routes by severity, and minimizes noise to prevent alert fatigue - every alert must be actionable.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
1000 alerts fire daily. On-call ignores them (alert fatigue). The one critical alert (database about to fail) is lost in noise. CPU alerts fire for autoscaling events. "Everything is red but nothing is actually broken."
---

### 📘 Textbook Definition

An alerting strategy defines what to alert on (symptoms over causes), when to alert (thresholds, burn rates), how to route (severity tiers), and how to respond (runbooks), designed to maximize signal-to-noise ratio and ensure every alert represents actionable user impact.
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
Alerting principles:
  1. Alert on SYMPTOMS (user impact), not CAUSES
     BAD:  "CPU > 80%" (might be fine during autoscale)
     GOOD: "Error rate > 1% for 5 minutes" (users affected)

  2. Every alert must be ACTIONABLE
     If you can't act on it -> it's not an alert, it's a log
     "Disk at 85%": actionable (expand or cleanup)
     "Pod restarted once": not actionable (K8s self-healed)

  3. Severity routing:
     P1 (Critical): Page immediately, user impact NOW
        "Payment service down, orders failing"
     P2 (High): Page within 15min, degraded service
        "Latency > 2s for 10% of users"
     P3 (Medium): Ticket, business hours
        "Disk at 80%, will fill in 3 days"
     P4 (Low): Dashboard only
        "Deprecated API usage increasing"

SLO-based alerting (burn rate):
  Error budget = 0.1% (SLO 99.9%)
  Monthly budget = 43.2 minutes

  Multi-window burn rate alert:
    "Burning 14.4x budget rate for 5 min"
    (At this rate, budget exhausted in 2 days)
    AND "Burning 1x budget rate for 1 hour"
    (Sustained, not a blip)

    -> Page on-call (real, sustained user impact)

  This replaces: "error rate > 1% for 5 min"
    (arbitrary threshold, no SLO context)
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

1. Alert on symptoms (user-visible impact), not causes (CPU, memory). "Error rate high" > "CPU high."
2. Every alert must be actionable. If the response is "wait and see," it's not an alert. Ruthlessly prune non-actionable alerts.
3. SLO-based alerting with burn rate > threshold-based. "Burning error budget at 14.4x rate" tells you impact and urgency in SLO context.

**Interview one-liner:**
"I implement symptom-based alerting using multi-window error budget burn rates (catching sustained impact without false positives), route by severity tier (P1 pages, P3 tickets), and ruthlessly prune non-actionable alerts - every alert must have a runbook and a human action."
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

[TODO: Include if 2+ named alternatives exist for Alerting Strategy. Otherwise remove this section.]
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
