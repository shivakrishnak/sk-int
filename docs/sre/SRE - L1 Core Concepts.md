---
layout: default
title: "SRE - L1 Core Concepts"
parent: "SRE"
grand_parent: "SK Interview"
nav_order: 3
permalink: /sre/l1-core-concepts/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Service Level Indicator (SLI)](#service-level-indicator-sli) | critical |
| 2   | [Service Level Objective (SLO)](#service-level-objective-slo) | critical |
| 3   | [Service Level Agreement (SLA)](#service-level-agreement-sla) | high |

---

# Service Level Indicator (SLI)

🎯 Interview Weight: critical - the most fundamental SRE
measurement concept; every SRE interview asks about SLIs
and your ability to define them reveals operational maturity.

---

### 🎯 Model Answer

**30 seconds:**
> An SLI is a specific quantitative measurement of a service's
> behavior that is meaningful to users. The canonical SLIs are
> availability (percentage of requests that succeed), latency
> (what fraction complete within a threshold), error rate, and
> throughput. An SLI is the raw measurement from which SLOs are
> defined. If you cannot measure it, you cannot manage it - SLIs
> are how SRE makes reliability measurable.

**3 minutes (Senior):**
> An SLI is a carefully selected metric that captures user-visible
> service quality. The word "carefully" is load-bearing: most metrics
> in a system are not SLIs. A CPU utilization metric is not an SLI -
> users do not experience CPU. A request success rate is an SLI -
> users directly experience whether their request succeeds.
>
> The Google SRE book defines four canonical SLI types for most
> services: availability (what fraction of requests succeed over
> a window), latency (what fraction complete below a latency
> threshold), error rate (what fraction return errors), and
> saturation (how close the service is to capacity). For streaming
> or batch services, throughput and freshness are also common SLIs.
>
> Defining a good SLI requires three decisions. First, what is the
> right measurement point? Measuring at the load balancer captures
> different behavior than measuring at the client. Client-side
> measurement includes DNS resolution and network transit, which
> are closer to the user experience. Second, what is the right
> aggregation window? Five-minute windows detect short spikes but
> have high noise. Rolling 28-day windows are appropriate for SLO
> compliance reporting. Third, what is the numerator and denominator?
> An availability SLI is: (successful requests) / (total requests).
> A latency SLI is: (requests completing in < 200ms) / (total requests).
>
> The most common mistake is measuring the wrong thing: measuring
> what is easy to observe rather than what the user actually experiences.
> Internal queue depth is easy to measure, but user-visible request
> latency is the SLI that matters.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "The SLI choice is a design decision, not
just a measurement decision. Choosing client-side latency as your
SLI instead of server-side latency means your SLO counts network and
infrastructure problems that the service itself cannot control. The
trade-off: more complete user experience measurement, but more noise
from factors outside the team's control."

*Adapting down:* Junior: "An SLI is a number that measures how well
your service is working from the user's perspective. The most common
SLIs are: what percentage of requests succeed (availability), and
how fast requests complete (latency). These are the numbers you track
to know if your service is meeting its reliability goals."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about SLIs - Service Level Indicators -
let me walk through what they are and how to define a good one."

**(2) First principles:** "From first principles, to manage reliability
you need to measure it. To measure reliability you need a user-visible
metric that captures service quality. An SLI is exactly that: the
specific quantitative measurement of a service behavior that matters
to users."

**(3) Bridge:** "An SLI is like a vital sign for a service. A doctor
measures blood pressure and heart rate because these directly reflect
patient health. An SRE measures request success rate and latency
because these directly reflect service health from the user's
perspective."

---

### 📘 Concept Explanation

**What it is:**
A Service Level Indicator (SLI) is a carefully defined quantitative
measurement of a service's behavior that is directly meaningful to
users. SLIs form the measurement foundation of SRE: SLOs are defined
over SLIs, error budgets are calculated from SLIs, and SLO compliance
is tracked by observing SLIs over time.

**The problem it solves:**
Before SLIs, reliability was described with vague goals ("the service
should be fast and available") or measured with internal infrastructure
metrics (CPU, memory, queue depth) that do not directly reflect user
experience. These metrics made it impossible to have precise
reliability conversations and impossible to know objectively whether
reliability was improving or degrading.

**How it works:**

```
SLI STRUCTURE
=============

DEFINITION COMPONENTS
  Numerator: what you count as "good"
    e.g. requests returning HTTP 2xx
  Denominator: total measurement window
    e.g. all HTTP requests in the window
  Formula: numerator / denominator = ratio
  Window: rolling 5m, 1h, 28d, etc.

CANONICAL SLI TYPES
  Availability:
    good = request succeeds (non-5xx response)
    SLI = (successful requests) / (total requests)
    e.g. 99.95% of requests return 2xx

  Latency:
    good = request completes below threshold
    SLI = (requests < 200ms) / (total requests)
    e.g. 99% of requests complete in < 200ms

  Error Rate:
    good = request does not return 5xx
    SLI = (non-5xx requests) / (total requests)
    Note: often the complement of availability

  Throughput:
    good = sufficient throughput for workload
    SLI = (requests/sec) / (target requests/sec)
    For batch: records processed per hour

  Freshness (data pipelines):
    good = data is recent enough
    SLI = (data age < threshold) / (measurements)
    e.g. 99% of measurements show data < 5min old

MEASUREMENT POINT CHOICES
  Client-side:  full user experience (DNS, network)
  Load balancer: excludes client-side network
  Service:      excludes infra, includes app logic
  Synthetic:    probes from outside, controlled
```

> **Code walkthrough:** This Service Level Indicator (SLI) example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
An SLI must be chosen for its relevance to user experience, not
for its convenience. The distinction between an SLI and a general
metric is the user-visible test: "Does a change in this number
directly correlate with a degradation in user experience?" CPU
utilization fails this test. Request success rate passes it. This
is why defining SLIs requires product and SRE collaboration -
understanding what "good" means to users is not a technical question.

**When to use it:**
For every production service that has users (internal or external).
Define SLIs before setting SLOs, because the SLO threshold is
meaningless without a clear definition of what is being measured.

**When NOT to use it:**
Not every metric should be an SLI. A service may have 200 metrics.
Choosing three to five as SLIs focuses the reliability conversation.
Infrastructure metrics (CPU, memory, disk) are inputs and early
warning signals, not SLIs - they measure resource consumption, not
user experience.

**Alternatives:**
- Health checks - binary up/down, less granular than SLIs
- Apdex score - combines availability and latency into one index
- RED metrics (Rate, Errors, Duration) - simpler framework for
  request-based services

**First-principles derivation:**
To define an SLO, you need to know what you are measuring. To measure
reliability, you need a unit. The unit of reliability measurement is
the SLI: a ratio of "good events" to "total events" over a time window.
The ratio format is essential - it normalizes for traffic variation
(10 errors out of 100 requests is 10% error rate regardless of time
of day or traffic volume).

---

### 💻 Code Example

**Example 1: SLI measurement in Prometheus (wrong vs right)**


```promql
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```promql
# BAD: measuring internal infrastructure metric
# (not user-visible)
avg(node_cpu_seconds_total{mode="idle"})

# This tells you CPU is idle but says nothing about
# whether users are experiencing good service.

# GOOD: availability SLI - ratio of successful requests
# to total requests over a 5-minute window
sum(rate(http_requests_total{
  status=~"2.."
}[5m]))
/
sum(rate(http_requests_total[5m]))

# Output: 0.9995 = 99.95% availability SLI
```

> **Code walkthrough:** The BAD query measures server CPU - easyice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> to query but not what users experience. The GOOD query computes
> the availability SLI as the ratio of 2xx responses to all responses
> over a rolling 5-minute window. `rate()` computes per-second rate
> from a counter, normalizing for traffic variation. The division
> gives a ratio between 0 and 1, which maps directly to a percentage
> availability SLI that can be compared to an SLO threshold.

**Example 2: Latency SLI with histogram**

```promql
# Latency SLI: fraction of requests completing
# within the target threshold (200ms)

# Using histogram_quantile (wrong for SLI)
histogram_quantile(0.99,
  rate(http_request_duration_seconds_bucket[5m])
)
# This gives the 99th percentile value in seconds
# but NOT the fraction completing under a threshold

# Correct SLI: fraction of requests < threshold
sum(rate(http_request_duration_seconds_bucket{
  le="0.2"
}[5m]))
/
sum(rate(http_request_duration_seconds_count[5m]))

# Output: 0.987 = 98.7% of requests in < 200ms
```

> **Code walkthrough:** The wrong approach uses histogram_quantileice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> which gives a latency value at a percentile - not an SLI ratio.
> The correct SLI uses the `le="0.2"` (less than or equal to 0.2
> seconds) bucket from the histogram, which counts all requests that
> completed within 200ms. Dividing by total request count gives the
> SLI ratio: what fraction of requests meet the latency target.
> This is the numerator/denominator pattern essential for all SLIs.

**Example 3: Freshness SLI for a data pipeline**

```promql
# Freshness SLI for a data pipeline:
# What fraction of checks show data is current?

# data_pipeline_lag_seconds: metric tracking
# how old the newest data in the pipeline is

sum(data_pipeline_lag_seconds < 300)
/
count(data_pipeline_lag_seconds)
# 0.99 = data fresh (< 5 min) in 99% of checks

# Alert when SLI drops below 0.98 (2% budget)
# ALERT: DataPipelineFreshnessSLO
# IF (freshness SLI < 0.98) for 10 minutes
```

> **Code walkthrough:** Freshness SLI applies the same good/totalice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> ratio pattern to data recency. The numerator counts measurements
> where the pipeline lag is under the threshold (300 seconds = 5
> minutes). The denominator is total measurements. This SLI is
> appropriate for data pipelines, ETL jobs, and caches where
> data staleness is the user-visible failure mode.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> An SLI is a specific metric that measures how well a service is
> working from the user's perspective. The most common SLIs are
> availability (percentage of requests that succeed), latency
> (percentage of requests completing within a time limit), and
> error rate (percentage of requests that fail). The key requirement
> is that the SLI is user-visible - it measures something users
> actually experience, not an internal infrastructure metric like
> CPU usage.

*Push deeper:* Explain the numerator/denominator ratio format: an
SLI is (good events) / (total events), not just a raw count. This
normalizes for traffic variation and enables meaningful comparisons
over time.

---

**Senior / Staff (5+ years):**
> The most important decision when defining an SLI is the measurement
> point. A server-side latency SLI measures what the server spends
> time on. A load-balancer latency SLI includes queuing and connection
> time. A client-side latency SLI includes DNS resolution and network
> transit - the full experience the user has. For a payment API, I
> choose server-side measurement because I want to alert on things
> my team can control. For a user-facing web application, I choose
> client-side (real user monitoring) because that is what determines
> whether the user had a good experience.
>
> The second key decision is what "good" means in the numerator. For
> availability: is a 500 error always bad? If a 500 is the correct
> response to a malformed request, counting it as a failure inflates
> the error rate artificially. Some teams exclude requests to invalid
> endpoints, or requests from monitoring probes, from the SLI
> denominator. These exclusions must be documented.

*Push deeper:* Staff angle: "Multi-window SLI measurement is the
production-grade approach. Track SLIs over 5-minute windows for
fast alerting, and 28-day rolling windows for SLO compliance
reporting. The same SLI value at different time scales reveals
different failure patterns."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Any metric can be an SLI | An SLI must be user-visible; CPU, memory, and queue depth are operational metrics, not SLIs |
| Latency SLI is the p99 value | A latency SLI is the ratio of requests completing below a threshold, not a single percentile value |
| More SLIs is better | Two or three well-chosen SLIs are more actionable than twenty; choose the fewest that fully capture user experience |
| SLI measurement at the server is the same as at the client | Server-side measurement misses network and infrastructure latency; for user-facing services, client-side measurement is more representative |
| An SLI of 100% is achievable | Any system with real users will have occasional failures; an SLI target below 100% is not a failure, it is an honest representation of realistic reliability |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: SLI measures the wrong thing**

*Symptom:* SLI shows 99.99% availability, but users are
reporting failures. Support tickets are up 30%. The SLI
disagrees with user experience.

*Root cause:* SLI is measured at the server only. A DNS or CDN
failure prevents requests from reaching the server - they are
never counted, so the server SLI does not include them.

*Diagnostic:*
```promql
# Compare server-side SLI to synthetic probe SLI
# Server-side:
sum(rate(http_requests_total{status=~"2.."}[5m]))
/ sum(rate(http_requests_total[5m]))
# Returns: 0.9999 (looks healthy)

# External synthetic probe:
probe_success{job="blackbox",target="api.service.com"}
# Returns: 0 (external probe failing)
# DNS or CDN failure: probe cannot reach server
```

> **Code walkthrough:** This DNS or CDN failure: probe cannot reach server example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Add external synthetic monitoring (Prometheus Blackbox
Exporter, Pingdom, Datadog Synthetic) to capture failures the
server never sees.

*Prevention:* For user-facing services, include at least one
synthetic probe SLI from outside the service boundary.

**Failure 2: SLI denominator includes non-user traffic**

*Symptom:* SLI shows higher availability than users experience.
Health check requests dilute the SLI denominator.

*Root cause:* Health check requests (always 200) are counted
in the denominator, diluting real user error rates.

*Diagnostic:*
```promql
# Check traffic breakdown by path
sum by (path) (rate(http_requests_total[5m]))
# If /health dominates: SLI is diluted

# Exclude health checks from SLI
sum(rate(http_requests_total{
  status=~"2..",path!="/health"
}[5m]))
/ sum(rate(http_requests_total{
  path!="/health"
}[5m]))
```

> **Code walkthrough:** This Exclude health checks from SLI example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Exclude health checks, synthetic probes, and monitoring
traffic from the SLI denominator. Document the exclusion.

**Failure 3: SLI alert threshold too tight - alert fatigue**

*Symptom:* SLI alerts fire multiple times per week for short
anomalies. On-call engineers stop responding.

*Root cause:* Alert threshold at SLO level with short evaluation
window. Normal traffic variance causes brief SLI dips.

*Fix:* Use burn rate alerting - alert when the error budget is
being consumed faster than the allowed rate, not just when the
SLI dips below the SLO.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | SLI definition, numerator/denominator, measurement point |
| Seniority signal | Junior: defines SLI; Senior: explains point and exclusions |
| Common trap | Confusing SLI with any monitoring metric |
| Staff differentiator | Multi-window measurement, measurement point trade-offs |

---

**Q1 [JUNIOR]: What is an SLI and how is it different from
any other metric?**

*Why they ask:* Foundational SRE vocabulary. The answer reveals
whether the candidate understands the user-centric framing.

*Likely follow-up:* "Give me an example of an SLI for a REST API."

An SLI is a Service Level Indicator - a specific quantitative
measurement of a service's behavior that directly reflects user
experience. The key distinction from an ordinary metric is that
an SLI must be user-visible: it measures something users actually
experience, not an internal system detail.

CPU utilization is a metric, not an SLI. A user does not experience
CPU - they experience slow responses and failed requests. Request
success rate is an SLI because a failed request is directly
experienced by the user.

For a REST API, the canonical SLIs are availability (fraction of
requests returning 2xx), latency (fraction completing within a
target duration), and error rate (fraction returning 5xx). These
are expressed as ratios: successful events divided by total events
over a time window.

*What separates good from great:* Most candidates define SLI as
"a metric." Great candidates explain the user-visible test and the
ratio format, giving a specific example with numerator and
denominator clearly defined.

---

**Q2 [MID]: How do you choose what to measure as an SLI
versus a supporting metric?**

*Why they ask:* Decision framework question. Most services have
dozens of metrics; choosing which ones are SLIs is a judgment call.

*Likely follow-up:* "What is the right number of SLIs per service?"

The user-visible test is the primary filter: does a change in this
number directly correlate with degraded user experience? Request
success rate passes. Kafka consumer group lag might pass for a
data-dependent user feature. Memory utilization fails - users do
not experience memory directly.

The secondary filter is controllability: do I want to be alerted
about things I can control? Client-side latency is more user-
accurate but less controllable by the server team.

The right number of SLIs per service is two to four. One or two
availability/error rate SLIs, one or two latency SLIs, and
possibly a freshness SLI if data staleness is user-visible.

*What separates good from great:* Most candidates describe all
metrics as potential SLIs. Great candidates apply the user-visible
test as a filter and name the controllability dimension.

---

**Q3 [MID]: Why is a latency SLI the ratio of requests below
a threshold rather than a percentile value?**

*Why they ask:* Common misunderstanding in SLI definition. The
ratio format is essential to error budget calculation.

*Likely follow-up:* "How does this format connect to error budgets?"

The SLO and error budget system requires SLIs to be ratios - they
must produce a value between 0 and 1 representing the fraction of
"good" events. A percentile value (p99 = 150ms) does not satisfy
this requirement.

The latency SLI as a ratio: (requests completing in < 200ms) /
(total requests) = e.g., 0.987 = 98.7% of requests meet the target.

This format has three properties: it is comparable over time
regardless of traffic volume; it feeds directly into error budget
calculation; and the threshold is a specific user commitment.

Percentile values like p99 are useful diagnostic metrics but not
SLIs - they tell you a latency value at a percentile, not the
fraction of users experiencing good service.

*What separates good from great:* Most candidates present p99 as
their latency SLI. Great candidates explain the ratio requirement
and why percentile values are diagnostic tools, not SLIs.

---

**Q4 [SENIOR]: What are the trade-offs of measuring SLIs at
the client versus the server?**

*Why they ask:* Architectural measurement decision testing holistic
SLI design thinking.

*Likely follow-up:* "Which would you use for a mobile API backend?"

Server-side: low overhead, consistent measurement, easy to implement.
Misses failures outside the service: DNS, CDN, load balancer failures.

Client-side (Real User Monitoring): captures full user experience
including network. Noisy from client environment, harder to
distinguish service vs. client problems.

Synthetic: controlled probes from multiple locations. Detects full-
path failures, complements server-side SLIs.

For a mobile API backend: server-side for primary SLO measurement
(controllable, actionable), synthetic monitoring to detect full-path
failures, and client-side RUM for understanding actual user experience.

*What separates good from great:* Most candidates default to
server-side. Great candidates describe all three and recommend
a combination based on failure mode coverage.

---

**Q5 [SENIOR]: How do you handle "bad" requests that should not
count against the availability SLI?**

*Why they ask:* Real implementation detail separating candidates
with hands-on SLI experience.

*Likely follow-up:* "What if a bad client exhausts your error
budget unfairly?"

Not all HTTP 5xx responses should count as SLI failures. The test:
does this failure represent the service failing to serve a valid
user request?

Categories to consider excluding: requests to invalid endpoints,
monitoring probe traffic, authenticated internal system traffic
with different reliability expectations.

However, I am cautious about excessive exclusions. Excluding client-
caused 5xx (malformed requests) is reasonable. Excluding server-
caused 5xx because they came from a "bad" client is not - the
service still failed.

All exclusions must be documented explicitly in the SLO document.

*What separates good from great:* Most candidates do not think about
SLI denominators. Great candidates explain the exclusion decision
framework and emphasize documentation to prevent gaming.

---

**Q6 [STAFF]: How do multi-window SLI measurements improve
alerting over single-window measurements?**

*Why they ask:* Advanced alerting architecture relevant to anyone
building production SLO alerting.

*Likely follow-up:* "What burn rate thresholds does the SRE
workbook recommend?"

Single-window measurements: short window (5 minutes) - fast detection
but high false positive rate. Long window (24 hours) - low false
positives but slow detection.

Multi-window multi-burn-rate alerting covers both:

Fast burn alert (1-hour + 5-minute windows): fires when the 1-hour
burn rate is high AND the 5-minute rate confirms it is ongoing.
Catches severe fast incidents.

Slow burn alert (6-hour + 1-hour windows): fires for sustained
moderate degradation consuming error budget over hours.

SRE workbook recommended thresholds:
- 14.4x burn rate: budget exhausted in ~2 days (page urgently)
- 6x burn rate over 6 hours: budget exhausted in 5 days (page soon)

*What separates good from great:* Most candidates describe single-
threshold alerting. Great candidates explain the noise vs. detection
lag trade-off and cite specific burn rate numbers.

---

**Q7 [STAFF]: What is the relationship between SLIs and user
journeys in reliability measurement?**

*Why they ask:* Staff-level reliability design connecting SLIs
to end-to-end user experience.

*Likely follow-up:* "How would you define SLIs for a checkout flow?"

Individual endpoint SLIs measure component reliability, but user
journeys - the multi-step flows users actually perform - may have
different reliability than any individual component. A checkout flow
involves search, cart, payment, and confirmation. Users care whether
checkout succeeds end-to-end.

User journey SLIs: (journeys completing successfully) / (journeys
attempted). For checkout: (orders placed successfully) / (checkout
flows initiated).

The implementation challenge: journey measurement requires tracking
multi-step flows across service calls, needing distributed tracing
or client-side instrumentation. The simpler path: compose journey
SLIs from critical endpoint SLIs (checkout = product * cart *
payment availability).

Goal: endpoint SLIs for diagnosing where failures occur, journey
SLIs for measuring what users actually experience.

*What separates good from great:* Most candidates think per-endpoint.
Great candidates describe journey SLIs, the composition approach,
and the implementation challenge.

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# Service Level Agreement (SLA)

🎯 Interview Weight: high - asked to test whether you understand
the customer contract dimension of reliability; clarifying
question after SLO discussion.

---

### 🎯 Model Answer

**30 seconds:**
> An SLA is a contract between a service provider and a customer
> specifying the minimum acceptable service level and the financial
> or legal consequences if that level is not met. Unlike an SLO
> (internal engineering target), an SLA is external and legally
> binding. The SLA target should always be less stringent than the
> SLO - the SLO creates a buffer so the team catches breaches
> internally before violating the customer commitment.

**3 minutes (Senior):**
> An SLA is the contractual reliability commitment to customers.
> For SaaS services, it specifies monthly uptime guarantee (e.g.,
> 99.9%) and service credits if availability falls below that.
>
> The relationship between SLA, SLO, and SLI is a hierarchy of
> strictness. SLI is the raw measurement. SLO is the internal
> target that should be met consistently. SLA is the external
> commitment, always less strict than the SLO.
>
> If the SLO is 99.95% and the SLA is 99.9%, the team has 0.05%
> additional budget before a customer contract is breached. Without
> this buffer, every SLO breach would be an SLA breach, creating
> perverse incentives to set the SLO low rather than genuinely
> improve reliability.
>
> From an SRE perspective, the SLA is context but not the primary
> target. SREs work to meet the SLO; the SLA is managed by product
> and legal. The SRE's job is to alert the team before the SLA is
> breached, not after.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff adds: "When product management wants aggressive
SLAs to win sales, the SRE's role is to quantify the engineering
cost. A commitment to 99.99% SLA when the system achieves 99.5%
requires a reliability investment roadmap with cost and timeline
that must be included in the deal economics."

*Adapting down:* Junior: "An SLA is the formal contract with
customers that specifies a reliability guarantee and what happens
(service credits) if it is missed. The SLA target is lower than
the SLO so there is a safety margin - the team knows about a breach
before the customer contract is violated."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about SLAs - let me explain what
they are and how they relate to SLOs and SLIs."

**(2) First principles:** "From first principles, a customer paying
for a service needs to know what reliability they are buying. An
SLA is the formal guarantee. The SLO is what engineering targets
to ensure that guarantee is met. The buffer between them protects
the customer relationship."

**(3) Bridge:** "An SLA is like a manufacturer's warranty. If a
product fails within the warranty period, the manufacturer replaces
it (service credit). The manufacturer builds to a higher internal
standard (SLO) than the warranty (SLA) to ensure most products
outlast the warranty period."

---

### 📘 Concept Explanation

**What it is:**
A Service Level Agreement (SLA) is a formal contract between a
service provider and a customer that defines the minimum acceptable
service level (typically availability or performance) and specifies
financial or contractual remedies if that level is not achieved.
SLAs are customer-facing commitments with business consequences.

**The problem it solves:**
Before SLAs, customers had no formal basis for reliability expectations
or compensation when services failed. A business relying on a cloud
provider or SaaS tool needed contractual clarity on what reliability
they could count on. SLAs create the commercial framework for
reliability commitments.

**How it works:**

```
SLA STRUCTURE
=============

TYPICAL SLA COMPONENTS
  Uptime commitment: e.g., 99.9% monthly availability
  Measurement method: how uptime is calculated
  Exclusions: planned maintenance, force majeure
  Remedies: service credits by downtime tier
  Escalation: how to report and resolve breaches
  Term: how long the SLA applies

COMMON SLA TIERS (cloud providers)
  Free / Basic:    no SLA or 95-99%
  Standard:        99.9% (~43 min/month downtime)
  Business:        99.95% (~22 min/month)
  Enterprise:      99.99% (~5 min/month)

SLA vs SLO HIERARCHY
  SLI (measurement):     99.97% (actual)
  SLO (internal target): 99.95% (engineering goal)
  SLA (customer commit): 99.9% (contractual floor)
  Buffer (SLO - SLA):    0.05%

REMEDY CALCULATION (common example)
  Monthly uptime 99.9%-99.5%: 10% credit
  Monthly uptime 99.5%-99.0%: 25% credit
  Monthly uptime below 99.0%: 50% credit
  Credit = % of affected month's subscription
```

> **Code walkthrough:** This Service Level Agreement (SLA) example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The SLA is the floor, not the target. An SRE team that aims to
meet the SLA rather than the SLO is setting a dangerously low bar.
SLA compliance means "we did not breach the customer contract."
SLO compliance means "we met our engineering reliability standard."

**When to use it:**
SLAs are appropriate for any commercial relationship where reliability
matters: B2B SaaS, cloud infrastructure, API platforms, payment
processors. Internal services between teams use SLOs, not SLAs.

**When NOT to use it:**
Internal developer tools and non-critical internal services do not
need SLAs. Over-contracting creates bureaucratic overhead without
reliability benefit.

**Alternatives:**
- Informal reliability commitments (status pages)
- Platform-wide SLAs (all services under one agreement)
- Tiered SLAs per subscription level

**First-principles derivation:**
A customer paying for a service needs predictability. The business
relationship requires knowing what reliability to plan around. An
SLA formalizes this with a quantitative commitment and financial
consequences. Without the financial consequence, a reliability
commitment has no enforcement mechanism.

---

### 💻 Code Example

*(Omit: SLAs are contractual documents, not programmatic constructs.
The technical implementation is the SLO and SLI monitoring that
enables SLA compliance measurement - covered in the SLI and SLO
sections above.)*

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> An SLA is a formal contract with customers guaranteeing a minimum
> reliability level and specifying service credits if it is missed.
> For example: "99.9% monthly availability; if missed, 10% credit."
> The SLA target is always lower than the SLO (internal engineering
> target) so the team catches and fixes reliability problems before
> the customer contract is breached. SREs work to meet the SLO;
> the SLA is the legal safety net below the SLO.

*Push deeper:* Explain the business impact of SLA breaches beyond
credits - customer trust, contract renewal risk, competitive
disadvantage. SLA breaches are business events, not just metrics.

---

**Senior / Staff (5+ years):**
> The most important SRE contribution to SLA management is pre-breach
> alerting. The on-call SRE should be notified when the SLO buffer
> between SLO and SLA is being consumed, not after the SLA is
> breached. If the SLO is 99.95% and the SLA is 99.9%, I set an
> alert when the rolling 28-day SLI drops below 99.92% - halfway
> through the buffer. This gives the team time to respond before
> the SLA breach.
>
> When product management wants an aggressive SLA to win a customer
> contract, my role is to provide the reliability cost estimate:
> "Committing to 99.99% SLA when we achieve 99.5% requires 3-6
> months of reliability engineering investment."

*Push deeper:* Staff angle: "The SLA is a product positioning
document. A company charging premium pricing for higher SLAs
monetizes reliability directly. The SRE team's work supports the
revenue model - making this connection visible to engineering
leadership changes the organizational conversation."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| SLA and SLO are the same thing | SLA is an external customer contract with financial consequences; SLO is an internal engineering target; SLO should be stricter than SLA |
| Meeting the SLA means reliability is good | SLA compliance is the floor; SLO compliance is the actual standard; a service can meet its SLA while providing poor user experience |
| SLAs should be set as high as possible | SLAs must be achievable; an SLA the system cannot meet leads to chronic credits and customer trust erosion |
| Once agreed, SLAs cannot change | SLAs are renegotiated at contract renewal; organizations improve SLAs over time as reliability improves |
| Internal services need SLAs | Internal services use SLOs; SLAs add contractual overhead appropriate only for external customer relationships |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: SLA set without SRE input, unreachable by design**

*Symptom:* Sales commits to 99.99% SLA. Service achieves 99.5%.
Service credit payouts begin immediately. Customer trust erodes.

*Root cause:* SLA was a sales commitment without engineering
validation. Cost of meeting the SLA not included in deal economics.

*Diagnostic:*
```
Check: historical 90-day SLI vs. SLA commitment.
If SLA > current SLO: commitment cannot be met
without reliability investment.
Current SLI 99.5% vs SLA 99.99%
= error budget exhausted 60x faster than allowed.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Add SRE review as a gate to the sales process. No
enterprise SLA above current SLO tier without SRE sign-off
and a reliability roadmap.

*Prevention:* Create a standard SLA tier catalog approved by SRE.
Sales commits to any catalog tier without extra review. Above
the highest tier requires SRE review and roadmap.

**Failure 2: SLA breach discovered after customer notices**

*Symptom:* Customer submits credit request for previous month's
breach. SRE team was unaware. Internal monitoring did not detect
the SLA-relevant breach.

*Root cause:* SLA measurement methodology differs from SLO
measurement (different window, different exclusions). Discrepancy
was not monitored.

*Diagnostic:*
```promql
# Compare SLO query vs SLA calculation method
# SLO (rolling 28-day):
increase(http_requests_total{status=~"2.."}[28d])
/ increase(http_requests_total[28d])

# SLA (calendar month, different exclusions)
# Manual: check contract for exact method
# If results differ: monitoring gap identified
```

> **Code walkthrough:** This If results differ: monitoring gap identified example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Implement SLA-specific measurement matching the contractual
calculation exactly.

*Prevention:* When drafting SLAs, involve SRE to ensure measurement
method is implementable. SLA and SLO measurement should be aligned.

**Failure 3: No buffer between SLO and SLA**

*Symptom:* Every SLO breach becomes an SLA breach. Customer
notifications required for every reliability event. Legal overhead
is high.

*Root cause:* SLO target equals SLA commitment. No buffer between
internal engineering target and customer contract.

*Fix:* Reset the SLO to be at least 0.1 percentage points stricter
than the SLA. SLO breach triggers internal escalation; only SLA
breach triggers customer notification.

*Prevention:* Policy: SLO target must always be at least 0.1%
stricter than SLA target. Document in SLO management guidelines.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 15 minutes |
| Core themes | SLA vs SLO distinction, SLA design, SLA management |
| Seniority signal | Junior: defines SLA correctly; Senior: explains buffer |
| Common trap | Equating SLA with SLO or treating SLA as engineering target |
| Staff differentiator | SLA as product positioning, SRE's role in sales process |

---

**Q1 [JUNIOR]: What is the difference between an SLA and an SLO?**

*Why they ask:* Vocabulary check revealing understanding of the
reliability contract hierarchy.

*Likely follow-up:* "Why should the SLO be stricter than the SLA?"

An SLA is a Service Level Agreement - a contract with customers
specifying minimum reliability and financial consequences if missed.
Breaching an SLA means the customer gets service credits or contract
protections activate.

An SLO is a Service Level Objective - an internal engineering target.
Breaching an SLO triggers internal escalation (deployment freeze,
incident response). It is an engineering management tool.

The SLO should be stricter than the SLA by at least 0.1 percentage
points. When the service drops to 99.91% (SLO breach at 99.95%),
the team is alerted and working to fix it before the 99.9% SLA
threshold is breached.

*What separates good from great:* Most candidates describe both as
nearly equivalent. Great candidates explain the buffer relationship
and describe the reaction window it creates.

---

**Q2 [MID]: What are the common components of an SLA for a
SaaS product?**

*Why they ask:* Operational awareness of what SLAs actually contain.

*Likely follow-up:* "What does 'monthly uptime' typically exclude?"

A typical SaaS SLA includes: uptime commitment (e.g., 99.9%
monthly availability), measurement method, exclusions (planned
maintenance, force majeure, customer-caused outages), remedy
structure (service credits by downtime tier), reporting process
(how customers report a breach), and SLA term.

Monthly uptime typically excludes: scheduled maintenance windows,
outages caused by customer actions (exceeding rate limits), third-
party provider outages outside the provider's control, and force
majeure events.

The exclusions are contractually significant. An SLA excluding all
third-party failures is much weaker than one that does not.
Customers should read exclusions carefully.

*What separates good from great:* Most candidates describe uptime
commitments only. Great candidates list all components and explain
exclusions, where the real contractual nuance lives.

---

**Q3 [MID]: How does an SRE team monitor for SLA compliance?**

*Why they ask:* Practical monitoring question testing implementation
ability.

*Likely follow-up:* "What alerts prevent SLA breaches?"

SLA monitoring should exactly replicate the contractual measurement
method: same denominator, same exclusions, same time zone.

The key alert: month-to-date projection alert. If at day 15 the
current month's availability trend projects to breach the SLA by
month end, alert now. Set the alert at 99.92% when the SLA is 99.9%
(giving buffer above the contractual floor).

Run both SLO (rolling 28-day) and SLA (calendar-month) dashboards.
Discrepancies reveal where the measurement methods diverge.

*What separates good from great:* Most candidates monitor SLOs
assuming they cover SLAs. Great candidates describe the contractual
measurement match and month-to-date projection alerting.

---

**Q4 [SENIOR]: How do you handle an SLA breach caused by an
upstream dependency failure?**

*Why they ask:* Business reality question testing maturity in
handling commercial consequences.

*Likely follow-up:* "What belongs in the postmortem?"

Honor the SLA regardless of root cause. If the customer experienced
downtime, they are entitled to credits even if an AWS outage caused
it. Do not argue causation - issue credits, explain the root cause,
describe future mitigation.

For internal learning: document the dependency failure as root cause
and analyze similar dependency risks. "AWS us-east-1 outage caused
breach" is the immediate cause. "Single-region dependency with no
multi-region failover" is the structural root cause.

For future mitigation: multi-region deployment, circuit breakers
with graceful degradation, or negotiating an SLA with the dependency
provider that covers business impact.

*What separates good from great:* Most candidates focus on the
technical cause. Great candidates handle customer communication
professionally, perform risk analysis beyond the immediate cause,
and propose structural mitigation.

---

**Q5 [SENIOR]: What is SRE's role in the SLA negotiation process
with enterprise customers?**

*Why they ask:* Cross-functional collaboration testing whether the
candidate can operate outside pure engineering.

*Likely follow-up:* "What do you bring to the meeting?"

SRE provides three inputs to SLA negotiation:

First, current reliability baseline: "Our rolling 6-month SLI shows
99.95% availability. This is measured reality, not an aspiration."

Second, gap analysis: "99.99% requires reducing monthly downtime
from 22 minutes to 5 minutes. This requires multi-AZ deployment,
chaos engineering, faster on-call response. Estimated: 6-8 FTE-months."

Third, timeline: "We can commit to 99.99% SLA in Q4 after these
investments. Before then, our SLA should match current capability:
99.95%."

This framing gives sales a credible path to the higher SLA rather
than forcing a choice between losing the deal and over-committing.

*What separates good from great:* Most candidates describe SRE as
purely technical. Great candidates describe the business-advisory
role, translating reliability into cost and timeline estimates.

---

**Q6 [STAFF]: How does tiered SLA design enable a
reliability-based pricing model?**

*Why they ask:* Staff-level product and business strategy question
connecting reliability to revenue.

*Likely follow-up:* "How do you staff reliability engineering
for tiered SLAs economically?"

Tiered SLA design creates a reliability ladder: lower-cost plans
with less stringent SLAs (99.9%), higher-cost plans with more
stringent SLAs (99.99%). This allows charging premium pricing for
premium reliability, making reliability investment revenue-generating.

From SRE's perspective, tiered SLAs mean tiered SLOs and potentially
dedicated infrastructure for the highest tier (isolated from
traffic that degrades SLO for other customers).

The staffing reality: moving from 99.9% to 99.99% requires
disproportionately more engineering - multi-region active-active,
automated failover, chaos engineering, dedicated on-call with
< 5 minute response. Premium pricing must cover this cost.

SRE's contribution: provide engineering cost estimates per SLA tier
so pricing teams can set economically sustainable prices.

*What separates good from great:* Most candidates describe tiered
SLAs technically. Great candidates explain the non-linear engineering
cost across tiers and SRE's role in making pricing sustainable.

---

**Q7 [STAFF]: What are the SLA implications of a multi-tenant
SaaS architecture?**

*Why they ask:* Complex architecture and commercial risk for staff
candidates designing enterprise SaaS.

*Likely follow-up:* "How do you prevent a noisy tenant from causing
SLA breaches for others?"

A noisy or abusive tenant can degrade service quality for all others
in a multi-tenant architecture - potentially causing SLA breaches
for tenants who did nothing wrong.

Technical mitigations: resource quotas per tenant (rate limiting,
CPU/memory limits), bulkhead isolation (separate thread pools per
tenant tier), dedicated infrastructure for enterprise tenants.

Commercial implications: the SLA must define what counts as
"downtime" in multi-tenant context. Customer-caused outages are
typically excluded, but this requires attribution tooling - the
provider must prove which tenant caused the degradation.

Staff-level design: enterprise tenants with strict SLAs deploy on
dedicated infrastructure (separate clusters, databases), physically
isolated from standard-tier tenants. The isolation cost is absorbed
by premium enterprise pricing. Standard tenants share infrastructure
with quota enforcement.

*What separates good from great:* Most candidates describe per-
tenant SLAs without considering multi-tenancy. Great candidates
explain the noisy neighbor risk, technical mitigations, attribution
requirements, and dedicated infrastructure design for enterprise SLAs.

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



