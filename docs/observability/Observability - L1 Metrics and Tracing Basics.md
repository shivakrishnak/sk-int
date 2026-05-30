---
layout: default
title: "Observability - L1 Metrics and Tracing Basics"
parent: "Observability"
nav_order: 4
permalink: /observability/l1-metrics-and-tracing-basics/
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Metric Types](#metric-types) | critical |
| 2   | [Distributed Trace Anatomy](#distributed-trace-anatomy) | high |
| 3   | [Instrumentation Fundamentals](#instrumentation-fundamentals) | high |

---

# Metric Types

**TL;DR** - Four metric types cover all measurement needs: counters
(always increasing), gauges (current value), histograms (distribution),
and summaries (percentile estimates). Choosing the wrong type makes
percentile calculation wrong or impossible.

---

### 🎯 Model Answer

**30 seconds:**
> Prometheus defines four metric types. A counter always increases
> (requests total, errors total). A gauge is a point-in-time value
> that can go up or down (active connections, memory in use). A
> histogram samples observations into buckets to compute approximate
> percentiles (latency distribution). A summary computes percentiles
> client-side (accurate but cannot aggregate across instances).
> The most common mistake is using gauges for latency instead of
> histograms, making p99 calculation impossible.

**3 minutes (Senior):**
> The four Prometheus metric types encode fundamentally different
> measurement semantics. A counter is a monotonically increasing
> integer: total HTTP requests, total bytes written. You never reset
> it; you compute rates using the rate() or increase() functions.
> A gauge is a value that can increase or decrease: goroutine count,
> CPU temperature, active database connections. You read it directly
> for current state. A histogram is a set of pre-defined buckets
> that counts observations falling below each bucket boundary.
> For latency, you define buckets at 1ms, 5ms, 10ms, 50ms, 100ms,
> 500ms. Each request's latency is counted in all buckets above
> its duration. Prometheus can compute approximate percentiles from
> histograms using histogram_quantile(). A summary computes
> percentiles on the client side (streaming quantile algorithm)
> and exports them as gauges. Summaries are more accurate than
> histograms but cannot be aggregated across instances (you cannot
> combine two summaries and get a correct 99th percentile). The
> practical rule: use histograms for anything you want to percentile-
> aggregate across service instances. Use summaries only for
> single-instance metrics where accuracy matters more than
> aggregability.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers design histogram bucket boundaries
that match expected latency distributions, choose between native
histograms (Prometheus 2.40+, more accurate) and classic histograms,
and govern cardinality across all metric dimensions.

*Adapting down:* "Counters count things. Gauges measure current
state. Histograms show how values are distributed (like how many
requests were fast vs slow). Summaries are like histograms but
calculated differently."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about metric types - let me walk
through counter, gauge, histogram, and summary."

**(2) First principles:** "From first principles, there are four
fundamental measurement questions: how many times did X happen
(counter), what is the current value of X (gauge), how are values
of X distributed (histogram), and what is the Nth percentile of X
(summary)."

**(3) Bridge:** "Think of driving: your odometer is a counter (always
increasing miles), your speedometer is a gauge (current speed), a
histogram is a frequency chart of how fast you drove, and a summary
is the median speed for the trip."

---

### 📘 Concept Explanation

**What it is:**
The four fundamental metric types in Prometheus and OpenTelemetry
that model different measurement semantics: counters, gauges,
histograms, and summaries.

**The problem it solves:**
Using the wrong metric type produces incorrect results. If you
measure request latency as a gauge (recording the last observed
value), you cannot compute accurate percentiles. If you store
error count as a gauge (value that can be decremented), rate()
calculations are incorrect. Each type is designed for specific
mathematical operations.

**How it works:**

**Counter:**
- Monotonically increasing integer
- Resets to 0 on service restart (Prometheus handles reset correctly)
- Operations: rate(), increase(), sum()
- Never use: for values that can decrease

**Gauge:**
- Arbitrary current value, can increase or decrease
- Operations: read directly, avg(), max(), min()
- Never use: for count of events over time

**Histogram:**
- Pre-defined buckets; each observation increments all buckets
  where boundary >= observation
- Always exports three time series per name:
  `_bucket{le="N"}`, `_sum`, `_count`
- Operations: histogram_quantile(0.99, ...)
- Can aggregate across instances (federated p99)

**Summary:**
- Sliding window percentile computation on client
- Exports pre-computed quantiles as gauges
- Cannot aggregate across instances

```
METRIC TYPE DECISION FLOWCHART

Does the value only increase?
    YES -> Counter
Does the value change arbitrarily?
    YES -> Gauge
Do you need percentiles across instances?
    YES -> Histogram
Do you need high percentile accuracy,
single instance only?
    YES -> Summary
```

> **Diagram walkthrough:** The flowchart is the fastest way
> to select the right metric type. Counter is for cumulative
> totals. Gauge is for current state. Histogram is the standard
> choice for latency and request sizes because it supports
> federation. Summary is the specialist choice for single-instance
> high-accuracy percentiles.

**The key insight:**
Histograms can be aggregated; summaries cannot. If you run 10
instances of a service, `histogram_quantile(0.99, sum(rate(
http_request_duration_bucket[5m])))` correctly computes the
p99 across all instances. The same operation on a summary
gives a wrong answer because you are averaging pre-computed
percentiles, which is mathematically incorrect.

**When to use it:**
Choose metric type at instrumentation time. The type is part
of the metric definition and cannot be changed without renaming.

**When NOT to use it:**
Do not use summaries when running multiple service instances
unless you need high-accuracy single-service percentiles. Do
not use histograms when you need an exact current value (use
a gauge).

**Alternatives:**
- Native histograms (Prometheus 2.40+): variable bucket boundaries
  computed dynamically; more accurate than classic histograms;
  requires newer Prometheus client SDK support
- OpenTelemetry UpDownCounter: equivalent to Prometheus gauge
  (allows decrements)
- OpenTelemetry ObservableGauge: gauge with a callback for
  asynchronous measurement (current CPU, active connections)

**First-principles derivation:**
Four questions exhaust the measurement space: how many times
did X happen (counter), what is X right now (gauge), what
is the distribution of X values (histogram), and what is the
Nth percentile of X (summary). Each question requires a
different data structure optimized for its storage and query
characteristics. Histograms pre-aggregate during collection
(cheap to query later). Summaries aggregate at query time
(accurate but expensive to combine).

---

### 💻 Code Example

**Example 1: BAD - Using gauge for latency (no percentiles)**

```java
// BAD: gauge for latency - cannot compute p99 correctly
Gauge checkoutLatency = Gauge.build()
    .name("checkout_latency_ms")
    .help("Checkout latency")
    .register();

// Records only the LAST observed value
// At 10,000 RPS, only 1 in 10,000 latency values
// is visible at any point in time
// histogram_quantile() cannot be used on gauges
checkoutLatency.set(durationMs);

// PromQL attempt: avg(checkout_latency_ms)
// Returns: average of last-observed values across instances
// Meaning: statistically meaningless
```

> **Code walkthrough:** Recording latency as a gauge stores only
> the last observed value. At 10,000 RPS, this gauge is overwritten
> 10,000 times per second, so at any query time it represents one
> request's latency. Averaging this gauge across instances gives
> a statistically meaningless result. The p99 latency cannot be
> computed at all. This is one of the most common metric type
> mistakes in real production systems.

**Example 2: GOOD - Histogram for latency with correct percentile**

```java
// GOOD: histogram for latency - correct p99 computation
Histogram checkoutDuration = Histogram.build()
    .name("checkout_duration_seconds")
    .help("Checkout request duration")
    // Buckets must cover expected latency range
    // Include a bucket at your SLO threshold
    .buckets(
        0.005, 0.01, 0.025, 0.05, 0.1,
        0.25, 0.5, 1.0, 2.5, 5.0
    )
    .register();

// Record each observation
try (Histogram.Timer timer =
    checkoutDuration.startTimer()) {
    Order order = processCheckout(req);
}

// PromQL: compute p99 across all instances
// histogram_quantile(0.99, sum by (le) (
//   rate(checkout_duration_seconds_bucket[5m])
// ))
// Result: correct p99 across all service instances
// combining their histogram bucket counts
```

> **Code walkthrough:** The histogram records each observation
> into pre-defined buckets. When 1000 requests have latency
> between 50ms and 100ms, the le="0.1" bucket's count increases
> by 1000. Prometheus aggregates these bucket counts across all
> service instances and computes an approximate percentile using
> linear interpolation within the bucket containing the target
> percentile. The result is correct for any number of instances.
> The bucket boundaries should include your SLO threshold (e.g.,
> 0.5 for a 500ms SLO) to maximize the accuracy of the p99
> calculation at that value.

**Example 3: Counter and Gauge examples**

```java
// Counter: requests and errors (always increasing)
Counter requests = Counter.build()
    .name("checkout_requests_total")
    .labelNames("status")  // "success", "error"
    .help("Total checkout requests by status")
    .register();

requests.labels("success").inc();
requests.labels("error").inc();

// PromQL: error rate as a ratio
// rate(checkout_requests_total{status="error"}[5m])
// / rate(checkout_requests_total[5m])

// Gauge: active connections (point-in-time)
Gauge activeConnections = Gauge.build()
    .name("db_active_connections")
    .help("Currently active DB connections")
    .register();

// Increment when connection acquired
activeConnections.inc();
// Decrement when connection released
activeConnections.dec();
// Set to current value of connection pool
activeConnections.set(pool.getActive());

// PromQL: current active connections
// db_active_connections
// Alert when near pool limit:
// db_active_connections > 90
```

> **Code walkthrough:** The counter increments on each request
> with a status label. PromQL's rate() function computes the
> per-second rate, handling counter resets (service restarts)
> correctly. The gauge tracks the current active connection count
> by incrementing on acquire and decrementing on release. Reading
> the gauge gives the current instantaneous value, which is the
> right use case. An alert at `> 90` on a gauge with pool size
> 100 fires before exhaustion.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> There are four metric types. Counters always increase - total
> requests, total errors. Gauges are current values - active
> connections, memory used. Histograms distribute observations
> into buckets - useful for latency p99. Summaries compute
> percentiles on the client. The most important thing I know is
> to use histograms for latency, not gauges - a gauge cannot
> answer "what was the 99th percentile latency?"

*Push deeper:* Explain the aggregation property: histograms
can be combined across multiple service instances to compute
a correct federated p99; summaries cannot.

---

**Senior / Staff (5+ years):**
> The critical distinction is histogram vs summary and their
> aggregation properties. Histograms pre-aggregate into buckets
> at observation time and support correct p99 computation across
> any number of instances via histogram_quantile. Summaries
> compute percentiles client-side using a streaming algorithm
> and cannot be correctly aggregated across instances - you
> cannot average two p99 values and call it a p99. In practice,
> I always use histograms for latency. I use summaries only for
> single-instance JVM metrics like GC pause duration where I
> need high accuracy and run one instance. Histogram bucket
> design is critical: buckets should be dense around your SLO
> threshold to maximize accuracy at that value.

*Push deeper:* Describe native histograms (Prometheus 2.40+)
and when they improve accuracy over classic histograms.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
| ------------- | ------- |
| "Summaries are better than histograms because they are exact" | Summaries cannot be aggregated across instances. Histograms give approximate but aggregatable percentiles, which is almost always more useful |
| "I can use a gauge for error rate" | Error rate requires a counter (always increasing error count) divided by a counter (always increasing request count). A gauge cannot correctly represent an error rate over time |
| "More histogram buckets = more accurate percentiles" | Buckets beyond 20-30 add minimal accuracy and increase metric storage cost. Concentrate buckets around your SLO threshold |
| "Counter resets cause calculation errors" | Prometheus rate() and increase() functions handle counter resets automatically. You never need to manually detect resets |

---

### 🚨 Failure Modes and Diagnosis

**Mode 1 - Wrong metric type causing incorrect p99**

Symptom: The p99 latency chart in Grafana shows values that
jump wildly between 2ms and 2000ms, not matching user-reported
experience. The metric is a gauge.

Root cause: Latency recorded as a gauge stores only the last
observed value. At any instant, the gauge holds one request's
latency, so the "p99" is actually the last latency value, which
changes 10,000 times per second.

Diagnostic:
```bash
# Check metric type in Prometheus
curl -s 'http://prometheus:9090/api/v1/metadata' \
  --data-urlencode 'metric=checkout_latency_ms' | \
  jq '.data.checkout_latency_ms[0].type'
# If result is "gauge" for a latency metric, wrong type
```

Fix: Rename the metric (type changes require name changes),
add a histogram with the same base name and _seconds suffix
following Prometheus conventions, migrate alerting rules to
use histogram_quantile().

Prevention: Metric type review in code review. Latency
metrics must be histograms or summaries.

---

**Mode 2 - Missing histogram buckets causing inaccurate p99**

Symptom: p99 latency shows exactly 5000ms repeatedly.
Actual p99 is likely between 1000ms and 10000ms but the
histogram cannot compute it accurately.

Root cause: The histogram has no bucket at 5000ms (5.0 second
boundary). The highest bucket is 5.0 seconds. All observations
above 5000ms land in the +Inf bucket. histogram_quantile
returns the upper boundary of the last finite bucket (5.0)
for any percentile where the sample falls in the +Inf bucket.

Diagnostic:
```bash
# Check histogram bucket configuration
curl -s 'http://prometheus:9090/api/v1/query' \
  --data-urlencode \
  'query=checkout_duration_seconds_bucket{le="+Inf"}' | \
  jq '.data.result[0].value[1]'
# Compare to total count - if they are equal,
# ALL observations are in the +Inf bucket
# Means all latency is above the highest defined bucket
```

Fix: Redefine buckets with higher boundaries: add 10.0, 30.0
buckets. Also investigate why all latency is above 5 seconds.

Prevention: Set histogram boundaries to 2x the maximum
expected latency. Check p99 against the +Inf bucket count
before declaring the histogram correctly configured.

---

**Mode 3 - Label cardinality explosion**

Symptom: Prometheus memory usage grows unboundedly after
adding a new metric with a user_id label. Time series count
exceeds 10 million.

Root cause: A metric was defined with a user_id label. Each
unique user creates a new time series. At 1 million users,
1 million time series.

Diagnostic:
```bash
# Find cardinality offenders
curl -s 'http://prometheus:9090/api/v1/query' \
  --data-urlencode \
  'query=topk(10, count by(__name__)({__name__!=""}))' | \
  jq '.data.result[] | {name: .metric.__name__,
    series: .value[1]}'
# Any metric > 100,000 series is a cardinality risk
```

Fix: Remove user_id from the metric label set. Use traces
and logs to investigate per-user data; metrics are for
aggregate signals.

Prevention: Code review: reject metric definitions with labels
having cardinality > 1,000 unique values.

---

### 🎯 Interview Deep-Dive

| Question type | Time budget | Goal |
| ------------- | ----------- | ---- |
| Conceptual | 60 sec | Describe all four types |
| Comparison | 90 sec | Histogram vs summary trade-off |
| Debugging | 90 sec | Diagnose incorrect p99 |
| Scenario | 2 min | Choose types for a checkout service |
| Trade-off | 60 sec | Gauge vs counter for error counting |
| Production | 2 min | Describe a metric type bug you found |
| Behavioral | 2-3 min | STAR story of fixing cardinality issue |

---

**Q1 [JUNIOR] What are the four Prometheus metric types?**

*Why they ask:* Foundation for any Prometheus/observability role.

*Likely follow-up:* When would you use a histogram vs a summary?

The four Prometheus metric types are counter, gauge, histogram,
and summary. A counter is a monotonically increasing number that
only goes up: total requests served, total bytes written, total
errors. You use rate() to compute the per-second rate. A gauge
is a current measurement that can go up or down: active connections,
memory usage, queue depth. You read it directly for current state.
A histogram counts observations in pre-defined buckets and is
used for measuring distributions: request latency, response sizes.
It exports three sub-metrics: `_bucket` (count per bucket),
`_sum` (total of all observations), and `_count` (number of
observations). You use histogram_quantile() to compute percentiles.
A summary computes streaming percentiles on the client side and
exports them as gauges. The key difference between histogram and
summary is that histograms can be aggregated across multiple
service instances while summaries cannot.

*What separates good from great:* Great candidates explain why
histogram aggregation works mathematically (summing bucket counts
is valid) but summary aggregation does not (averaging percentiles
is not the same as the percentile of the union).

---

**Q2 [MID] Why can histograms be aggregated but summaries cannot?**

*Why they ask:* Tests mathematical depth behind metric type choice.

*Likely follow-up:* Give an example where using a summary caused incorrect results.

Histogram aggregation works because bucket counts are additive.
If instance A has 100 requests below 100ms and instance B has
150 requests below 100ms, the combined count below 100ms is 250.
This is correct because bucket counts measure "how many observations
fell in this bucket" and counts can always be summed. From the
aggregated bucket counts, histogram_quantile computes an accurate
approximation of the percentile. Summary aggregation fails because
percentiles are not additive. If instance A has a p99 of 200ms
and instance B has a p99 of 400ms, the combined p99 is NOT
300ms. The combined p99 depends on how many requests each instance
handled and the full distribution of each, not just the p99 values.
If instance A handled 1000 requests and instance B handled 1, the
combined p99 is very close to instance A's 200ms. If they handled
equal traffic, the combined p99 could be anywhere between 200ms
and 400ms. A summary that exports only the percentile value
discards the information needed to compute the aggregate correctly.

*What separates good from great:* Great candidates state the
mathematical property: the p99 of a union of two distributions
requires the full distributions, not their individual p99s.

---

**Q3 [SENIOR] How do you choose histogram bucket boundaries?**

*Why they ask:* Tests practical histogram configuration knowledge.

*Likely follow-up:* What are the default Prometheus buckets and why are they often wrong?

Histogram bucket boundaries should be chosen to maximize accuracy
around your SLO threshold. The default Prometheus buckets are
0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10 seconds.
These are appropriate for a service with a 1-second SLO. For a
checkout service with a 500ms SLO (0.5 second), I want buckets
dense around 500ms: 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.75, 1.0.
The accuracy of histogram_quantile depends on how narrow the
bucket containing the target percentile is. With a single bucket
from 0.25 to 0.5, the p99 at 450ms is computed by linear
interpolation within that 250ms range, giving 25% inaccuracy.
With buckets at 0.4 and 0.5, the p99 at 450ms is interpolated
within a 100ms range, giving 10% inaccuracy. The rule is:
make buckets tight around your SLO threshold. The maximum bucket
should be at least 2x the expected p99 to avoid +Inf bucket
saturation. In OpenTelemetry, you can use exponential histograms
(native histograms) that adapt bucket boundaries automatically
to observed data.

*What separates good from great:* Great candidates describe the
native histogram (Prometheus 2.40+) as the current best practice
for avoiding the bucket boundary calibration problem.

---

**Q4 [JUNIOR] What is a counter reset and how does Prometheus handle it?**

*Why they ask:* Tests practical counter knowledge.

*Likely follow-up:* Why should you never decrement a counter?

A counter reset occurs when a counter's value drops, typically
because the service restarted. If a service is at 50,000 requests
and restarts, the counter resets to 0. The raw value jumps from
50,000 to 0, then starts incrementing again. If you plot the
raw counter value, you see a drop to zero at the restart point.
Prometheus handles this with the rate() and increase() functions:
both detect resets (when the current value is less than the
previous value) and automatically adjust the calculation. The
rate() function computes the average rate of increase per second
within the lookback window, treating resets as a discontinuity
and not as a negative rate. You should never manually decrement
a counter because rate() and increase() cannot distinguish
between a counter reset (expected, handled automatically) and
a manual decrement (not expected, mathematically incorrect).
If you need to track a value that decreases, use a gauge.

*What separates good from great:* Great candidates describe the
stale marker mechanism: when a service disappears, Prometheus
adds a stale marker to prevent old values from polluting rate
calculations.

---

**Q5 [MID] Design metrics for a payment processing service.**

*Why they ask:* Tests ability to apply metric types to a real service.

*Likely follow-up:* What would you use to alert on payment failure rate?

For a payment processing service I would define four metric groups.
First, RED metrics: `payment_requests_total` (counter with labels:
status=success/error/timeout) for rate and error rate calculations;
`payment_duration_seconds` (histogram with buckets at 0.1, 0.25,
0.5, 1.0, 2.5, 5.0) for latency p99 computation. Second, business
metrics: `payment_amount_total_cents` (counter) for total volume;
`payment_failed_amount_total_cents` (counter) for failed volume.
Third, infrastructure metrics: `payment_processor_active_connections`
(gauge) for connection pool monitoring; `payment_queue_depth`
(gauge) for async payment queue backlog. Fourth, SLO support:
the payment_requests_total counter enables computing error budget
burn rate: `sum(rate(payment_requests_total{status="error"}[5m]))
/ sum(rate(payment_requests_total[5m]))`. Alert on 14x burn rate
over 1 hour for page-worthy incidents. The key design decision
is using a histogram for duration so that p99 can be computed
across all service instances in aggregate.

*What separates good from great:* Great candidates also describe
the cardinality governance: no user_id or payment_id labels on
any metric.

---

**Q6 [SENIOR] What are native histograms and how do they improve on classic histograms?**

*Why they ask:* Tests awareness of modern Prometheus advances.

*Likely follow-up:* What is the trade-off of using native histograms?

Native histograms (available in Prometheus client libraries 0.16+
and storage in Prometheus 2.40+) use a fixed-schema exponential
bucket layout rather than user-defined static buckets. The
boundaries double with each bucket: roughly ...0.5ms, 1ms, 2ms,
4ms, 8ms, 16ms... automatically covering any observed range.
Two improvements over classic histograms. First, accuracy: native
histograms adapt to observed data, so the target percentile always
falls in a narrow relative-error bucket (5% relative error at
default schema). Classic histograms require manual calibration;
a 0-to-1-second bucket gives 100% relative error for any
observation. Second, fewer time series: a classic histogram with
20 bucket boundaries generates 22 time series per metric instance.
A native histogram generates approximately one floatHistogram
per metric instance. The trade-off is compatibility: native
histograms require Prometheus 2.40+, OpenTelemetry client 0.16+,
and Grafana 10+. Classic histograms work with all Prometheus
versions since 1.0.

*What separates good from great:* Great candidates describe the
migration path from classic to native histograms in a production
environment with existing alerting rules.

---

**Q7 [JUNIOR] How do you compute request rate from a counter?**

*Why they ask:* Tests practical PromQL knowledge.

*Likely follow-up:* What is the difference between rate() and irate()?

The rate() function in PromQL computes the per-second average
increase of a counter over a lookback window. For example,
`rate(http_requests_total[5m])` divides the total increase in
the counter over the last 5 minutes by the number of seconds
in 5 minutes (300). If the counter increased by 15,000 in 5
minutes, rate() returns 50 (requests per second). Rate handles
counter resets automatically. The lookback window should be at
least 4x the scrape interval (15-second scrape needs 60-second
minimum window); 5 minutes is a safe default. irate() uses only
the last two data points to compute the instantaneous rate,
making it more responsive to spikes but noisier. I use rate()
for SLO calculations and alerts (stable, smooth). I use irate()
for short-term anomaly detection in dashboards where responsiveness
to spikes is more important than smoothness. The key practical
note: rate() returns 0 when there is no traffic (counter stops
increasing). Always use a non-zero minimum in alerting expressions
when you want to detect absence of traffic.

*What separates good from great:* Great candidates describe the
staleness interval: Prometheus marks time series as stale after
5 minutes of no scrape, and rate() returns no value (not 0) for
stale data.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with the histogram aggregation vs summary non-aggregation mathematical reasoning |
| Hiring Manager | Lead with the impact of wrong metric type on SLO reporting accuracy |
| Bar Raiser | Lead with native histograms and bucket boundary calibration |
| Peer Engineer | Collaborative: "Gauge for latency is the most common metric type mistake I see in code review - here is how to catch it" |

---

### ⚖️ Comparison Table

| Type | Semantics | Aggregatable | Use for |
|------|-----------|-------------|---------|
| **Counter** | Always increases | Yes (sum counts) | Request count, error count, bytes written |
| **Gauge** | Current value | Yes (but carefully) | Active connections, queue depth, memory |
| **Histogram** | Distribution in buckets | Yes (sum buckets) | Latency, request size, any distribution |
| **Summary** | Client-side percentiles | No | Single-instance high-accuracy percentiles |

**The deciding factor:**
Use histogram for any measurement you want to aggregate across
multiple service instances and compute percentiles on. Summary
only when running one instance and accuracy matters more than
aggregation.

---

### 🏛️ System Design

*(Omit: L1 foundational keyword; system design connections covered
in L4/L5 files.)*

---

### 📊 Diagram

*(Omit: the metric type decision flowchart and code examples
above illustrate the types clearly.)*

---

---

# Distributed Trace Anatomy

**TL;DR** - A distributed trace is a tree of spans. Each span
represents one operation in one service. The trace ID links spans
across services; the parent span ID defines the causality tree.

---

### 🎯 Model Answer

**30 seconds:**
> A distributed trace is a tree of spans, where each span represents
> one operation in one service. All spans share a trace ID (a 128-bit
> random identifier). Each span has a parent span ID pointing to
> the span that caused it. Together, the spans form a causality tree
> that shows exactly which service called which, in what sequence,
> and for how long. The trace lets you answer "where did the 900ms
> go?" by showing each service's contribution to total latency.

**3 minutes (Senior):**
> A distributed trace models the causal chain of a request as it
> moves through a distributed system. The data model has two levels.
> A trace is identified by a unique 128-bit trace ID, consistent
> across all services. Within a trace, each operation is a span:
> a span has its own 64-bit span ID, a reference to the parent span
> ID (or null for the root span), a service name, an operation name,
> start timestamp, end timestamp, and a set of key-value attributes.
> The root span is created by the first service that receives the
> request. When it calls service B, it propagates the trace ID and
> its own span ID (now the parent) in the outgoing request headers
> using W3C Trace Context (the traceparent header). Service B creates
> a child span with parent_id set to service A's span ID. This
> continues recursively across all services. The trace viewer (Jaeger,
> Tempo, Zipkin) reconstructs the tree from the span parent IDs and
> renders it as a Gantt chart: each span is a horizontal bar, its
> length proportional to duration, its position showing when it
> started relative to the root span. Reading this Gantt chart
> immediately shows which service was the largest contributor to
> total latency.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers reason about trace context propagation
across async boundaries, design sampling strategies that retain
interesting traces while managing storage cost, and use trace
exemplars to link metric spikes to specific traces.

*Adapting down:* "A trace is like a receipt that follows your
order through every department in a store, recording how long each
department took to process it."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the anatomy of a distributed
trace - let me walk through traces, spans, and how they relate."

**(2) First principles:** "From first principles, a distributed
request visits multiple services. To understand it, you need to
record what each service did and connect those records causally.
That is what traces and spans do."

**(3) Bridge:** "Think of a relay race. Each runner has a baton
pass (trace context) and runs their segment (span). The full
race record (trace) shows each runner's time and when passes
happened."

---

### 📘 Concept Explanation

**What it is:**
A distributed trace is a tree of spans representing all operations
performed by a request as it moves through a distributed system.
Spans share a trace ID and are linked by parent-child span ID
relationships that define the causality structure.

**The problem it solves:**
In a distributed system with 15 services, a single user request
triggers operations in potentially all 15. Understanding which
service contributed 800ms to a 1-second total latency requires
a data structure that records timing at each service and links
all records causally. Logs with correlation IDs provide the
records but not the timing relationships. Traces provide both.

**How it works:**
Key span fields and their purposes:

```
Span fields:
  trace_id:    128-bit random ID shared by all spans
               in the same request's trace
  span_id:     64-bit random ID unique to this span
  parent_span_id: span_id of the span that created
               this one (null for root span)
  service:     name of the service that owns this span
  operation:   name of the operation being traced
               (HTTP GET /checkout, DB SELECT, etc.)
  start_time:  absolute timestamp (nanosecond precision)
  end_time:    absolute timestamp
  duration:    end_time - start_time
  status:      OK / ERROR / UNSET
  attributes:  key-value pairs for additional context
               (http.method, db.statement, user.id)
  events:      timestamped point-in-time records
               within a span (not child spans)
  links:       references to other traces (for async)
```

Trace context propagation: when service A calls service B,
it injects the current trace_id and its own span_id into the
outgoing request via the W3C Trace Context header:
`traceparent: 00-4bf92f3577b34da6-00f067aa0ba902b7-01`
(version-traceId-parentSpanId-flags).

Service B extracts this header, creates a new span with the
extracted trace_id and parent_span_id, and records its
operation as a child of service A's span.

**The key insight:**
The trace Gantt chart reveals the critical path: the sequence
of spans that must complete serially before the root span can
complete. The critical path determines total latency. Optimizing
a span off the critical path has zero effect on total latency.

**When to use it:**
Apply distributed tracing to every user-facing service. The
critical path analysis traces provide is not available from
any other observability signal.

**When NOT to use it:**
Batch jobs that process millions of records need a single span
for the batch, not a span per record. High-frequency internal
operations (every cache lookup) should be span events, not
child spans. Use traces for operation boundaries, not internal
implementation details.

**Alternatives:**
- Correlation IDs in logs: simple, no trace viewer needed; loses
  timing relationships and critical path analysis
- Zipkin: older distributed trace format; compatible with Jaeger/OTel
- OpenTelemetry: current standard; vendor-neutral SDK + format

**First-principles derivation:**
A distributed request creates a partial order of operations:
A called B, B called C. To understand latency, you need both
the partial order (causality) and the timing of each operation.
The span tree provides the partial order (via parent_span_id
relationships) and the timing (via start_time and end_time
on each span). The root span duration is the request latency;
each span's duration is its service's contribution. The width
of each span on the Gantt chart is directly proportional to
its latency contribution.

---

### 💻 Code Example

**Example 1: Creating and propagating spans (Java OTel)**

```java
// Service A: creates root span, calls Service B
@GetMapping("/checkout")
public ResponseEntity<Order> checkout(
    @RequestBody CartRequest req) {

    // Root span - no parent span
    Span rootSpan = tracer
        .spanBuilder("POST /checkout")
        // Semantic convention attributes
        .setAttribute(SemanticAttributes.HTTP_METHOD,
            "POST")
        .setAttribute(SemanticAttributes.HTTP_ROUTE,
            "/checkout")
        .setAttribute("user.id", req.getUserId())
        .startSpan();

    try (Scope s = rootSpan.makeCurrent()) {
        // Child span for inventory check
        Span inventorySpan = tracer
            .spanBuilder("inventory.check")
            .startSpan();
        try (Scope is = inventorySpan.makeCurrent()) {
            // OTel auto-instrumentation propagates
            // traceparent header automatically
            inventoryClient.check(req.getItems());
        } finally {
            inventorySpan.end();
        }

        // Child span for payment
        Span paymentSpan = tracer
            .spanBuilder("payment.capture")
            .startSpan();
        try (Scope ps = paymentSpan.makeCurrent()) {
            paymentClient.capture(req.getPayment());
        } finally {
            paymentSpan.end();
        }

        return ResponseEntity.ok(buildOrder(req));

    } catch (Exception e) {
        rootSpan.recordException(e);
        rootSpan.setStatus(StatusCode.ERROR, e.getMessage());
        throw e;
    } finally {
        rootSpan.end();
    }
}
```

> **Code walkthrough:** This example shows the span tree creation.
> The root span (POST /checkout) is created without a parent.
> Two child spans (inventory.check and payment.capture) are created
> sequentially. Each child span is created while the parent span is
> "current" (in scope), which means the OTel SDK automatically sets
> the parent_span_id to the parent's span_id. The try-with-Scope
> pattern ensures spans are ended even on exception. Auto-
> instrumentation for HTTP clients (RestTemplate, WebClient)
> automatically injects the traceparent header when calling the
> inventory and payment services, so their spans become children
> of the respective child spans without manual code.

**Example 2: Reading the trace structure**

```
Trace ID: 4bf92f3577b34da6
Root span: POST /checkout [Service A] 0ms -> 850ms
  |-- inventory.check [Service A] 0ms -> 50ms
  |     |-- GET /inventory/check [Service B] 5ms -> 45ms
  |           |-- SELECT inventory [DB] 8ms -> 42ms
  |-- payment.capture [Service A] 50ms -> 850ms
        |-- POST /payment [Service C] 55ms -> 845ms
              |-- Stripe API call [Service C] 60ms -> 840ms

Critical path: A -> payment.capture -> C -> Stripe API
Total latency: 850ms
Critical path latency: 780ms (Stripe API: 780ms)
Inventory contribution: 45ms (parallel, off critical path)
```

> **Code walkthrough:** Reading the Gantt chart: the root span
> is 850ms. The inventory.check completes in 50ms and is on the
> critical path only until payment.capture starts. The payment
> chain (Service A -> C -> Stripe) is the critical path:
> 780ms comes from the Stripe API call. Optimizing inventory
> check from 50ms to 10ms has zero effect on total latency
> because it is not on the critical path. The only way to
> reduce the 850ms total is to optimize the Stripe API call.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A distributed trace is a tree of spans. Each span represents
> one operation in one service. Spans share a trace ID that connects
> them across services. The parent span ID shows who called whom.
> The trace viewer draws them as a Gantt chart showing each service's
> contribution to total latency. The most useful thing a trace tells
> you is: which service is on the critical path and how much of the
> total latency it contributes.

*Push deeper:* Explain the W3C Trace Context header format and
how services extract and propagate it.

---

**Senior / Staff (5+ years):**
> Distributed trace anatomy - trace ID, span ID, parent span ID,
> timestamps, status, and attributes - is the data model that enables
> critical path analysis across services. The most important concept
> is the critical path: the sequence of spans that cannot be
> parallelized, whose total duration determines the request latency.
> Optimizing any span not on the critical path has no effect on
> latency. I use critical path analysis as the primary tool for
> directing performance work: identify the critical path first,
> then optimize only spans on it.

*Push deeper:* Describe how to compute the critical path
programmatically from a trace, and how Jaeger's critical path
analysis feature (or its equivalent) works.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
| ------------- | ------- |
| "Reducing any span's latency reduces total latency" | Only spans on the critical path affect total latency. Parallel spans can be slow without affecting the total |
| "The root span duration equals the sum of child span durations" | Root span = critical path duration, not sum. Parallel spans contribute their duration only once |
| "Traces are only useful for debugging slow requests" | Traces also document system dependencies (which service calls which), enable performance profiling, and validate correctness of business workflows |
| "A trace always starts and ends in one service" | Traces span all services touched by a request. The trace is complete when the root span ends |

---

### 🚨 Failure Modes and Diagnosis

**Mode 1 - Broken trace context at async boundary**

Symptom: Traces for checkout end at the service that publishes
to Kafka. Background order processing spans have a different
trace ID and appear as unrelated orphan traces.

Root cause: Kafka message published without W3C Trace Context
headers. Consumer starts a new root span instead of continuing
the trace.

Diagnostic:
```bash
# Check Kafka message headers for traceparent
kafka-console-consumer.sh \
  --bootstrap-server kafka:9092 \
  --topic order-events \
  --property print.headers=true \
  --max-messages 5 | grep traceparent
# No traceparent header = broken context propagation
```

Fix: Use OTel Kafka instrumentation that automatically injects
traceparent into message headers. If using a non-standard
Kafka client, inject manually before publish and extract on
consume.

Prevention: Integration test that verifies traceparent header
presence in published messages.

---

**Mode 2 - Clock skew causing negative span durations**

Symptom: In Jaeger, a child span appears to start before its
parent span, or has a negative duration. The trace is confusing
to read.

Root cause: Service A and Service B have different system
clocks. A's clock is 200ms ahead of B's. A span recorded by
B appears to start before A started the parent span.

Diagnostic:
```bash
# Check clock skew between services
# On each service:
chronyc tracking | grep "System time"
# Compare output across services
# Skew > 100ms will cause visible trace anomalies
```

Fix: Ensure all services use NTP with the same upstream time
server. Kubernetes pods synchronize to the node clock; ensure
node clocks are synchronized. For microservices in multiple
datacenters, consider clock skew as a known limitation and
use relative timing within a single datacenter only.

Prevention: Alert on NTP synchronization error exceeding
50ms. Include clock synchronization in infrastructure health
checks.

---

**Mode 3 - Span explosion from high-frequency instrumentation**

Symptom: A trace contains 10,000+ spans. The trace viewer
is unusable. Export to Jaeger times out.

Root cause: Instrumentation added a span for every item in
a batch processing loop.

Diagnostic:
```bash
# Query Jaeger for traces with high span count
curl 'http://jaeger:16686/api/traces?service=batch-processor' | \
  jq '.data[] | {traceID: .traceID,
    spans: (.spans | length)} |
    select(.spans > 100)'
# Any trace with > 100 spans is probably over-instrumented
```

Fix: Replace per-item spans with span events on a batch span.
Record one span for the batch operation, and record per-item
errors as span events.

Prevention: Code review rule: no spans inside loops processing
more than 100 items.

---

### 🎯 Interview Deep-Dive

| Question type | Time budget | Goal |
| ------------- | ----------- | ---- |
| Conceptual | 60 sec | Describe trace, span, and their relationship |
| Debugging | 90 sec | Diagnose broken trace context |
| Comparison | 60 sec | Traces vs logs with correlation IDs |
| Scenario | 2 min | Read a trace and identify the critical path |
| Trade-off | 60 sec | Manual vs auto instrumentation |
| Production | 2 min | Describe a trace context propagation bug |
| Behavioral | 2-3 min | STAR story of using traces to find a latency bug |

---

**Q1 [JUNIOR] What is the difference between a trace and a span?**

*Why they ask:* Foundational understanding test.

*Likely follow-up:* What connects spans across services?

A trace is the complete record of a request as it moves through
a distributed system. It contains all the spans generated by all
services involved in handling that request. A span is a single
unit of work within one service: "service A processed the checkout
request," "service B queried the database," "service C called the
payment API." Spans are connected by two identifiers. The trace ID
is a 128-bit random number generated at the start of the request
by the first service. Every span in the trace shares the same trace
ID. The parent span ID tells you which span created this span -
when service A calls service B, A passes its span ID to B, and B
creates a new span with parent_span_id set to A's span ID. This
parent-child relationship forms a tree. The trace is the whole tree;
a span is one node in the tree.

*What separates good from great:* Great candidates describe the W3C
Trace Context header format (traceparent) and how services pass
trace and parent span IDs across service boundaries.

---

**Q2 [MID] How do you propagate trace context across an HTTP service boundary?**

*Why they ask:* Tests practical trace propagation knowledge.

*Likely follow-up:* How do you handle trace propagation with message queues?

W3C Trace Context is the standard for HTTP trace propagation.
When service A calls service B, A injects a `traceparent` header
into the HTTP request. The format is:
`traceparent: 00-{trace_id}-{parent_span_id}-{flags}`
where trace_id is the 128-bit hex trace identifier, parent_span_id
is the 64-bit hex span ID of the current span in service A, and
flags is one byte with the sampling bit (01 = sampled, 00 = not
sampled). Service B extracts this header on receiving the request
and creates a new span with parent_span_id set to the extracted
span ID and trace_id set to the extracted trace ID. With
OpenTelemetry auto-instrumentation, this is automatic for most
HTTP frameworks: the Java agent instruments Spring MVC or Quarkus
and injects/extracts traceparent headers without any code changes.
For message queues (Kafka, RabbitMQ), trace context is passed
as message metadata headers. OTel auto-instrumentation handles
this for supported queue clients. For custom clients, you inject
manually: `message.setHeader("traceparent", currentSpanContext)`.

*What separates good from great:* Great candidates describe the
tracestate header (vendor-specific sampling state) and when
it is needed.

---

**Q3 [SENIOR] How do you use a trace to identify the critical path?**

*Why they ask:* Tests ability to use traces operationally.

*Likely follow-up:* What tools help identify the critical path automatically?

The critical path of a trace is the sequence of spans that must
complete serially (without parallelism) and whose total duration
equals the root span duration. To find it: start with the root span.
Look at its direct children. If two children overlap in time, they
are parallel and only the slower one is on the critical path.
If children execute sequentially, all are on the critical path.
Recursively apply this analysis to each span on the critical path.
In practice: open the trace in Jaeger or Tempo. The waterfall
visualization shows spans as horizontal bars with time on the x-axis.
A span that starts where another ends (sequential) is on the critical
path. A span that starts at the same x position as a sibling (parallel)
is on the critical path only if it is the slower sibling. Jaeger's
"Critical Path" feature highlights the critical path automatically
using a graph algorithm. Optimization strategy: only optimize spans
on the critical path. A 200ms improvement to a parallel span that
takes 100ms less than the critical path span saves 0ms total latency.

*What separates good from great:* Great candidates describe a
specific case where they identified that a parallel span appeared
to be the problem but was off the critical path, and how they
redirected the optimization work.

---

**Q4 [JUNIOR] What is a span attribute vs a span event?**

*Why they ask:* Tests precision of span data model knowledge.

*Likely follow-up:* When would you use a span event instead of a child span?

A span attribute is a key-value pair that describes properties
of the span's operation - things that are true for the entire span's
duration: `http.method=POST`, `user.id=u-9182`, `db.table=orders`.
Attributes are set at span creation or at any time before the span
ends. A span event is a timestamped record of something that happened
at a specific point during the span's execution: "cache miss at
14:32:05.123", "retry attempt 2 at 14:32:05.500". Events are like
log lines attached to the span - they have a timestamp, a name,
and optional attributes. When to use events vs child spans: use
child spans for significant sub-operations that have measurable
duration and represent a distinct call or operation boundary.
Use span events for point-in-time occurrences within an operation:
errors that were handled, retries, state transitions. In a batch
processing span, record each item's error as a span event, not
a child span. This keeps the trace compact while still recording
per-item failures.

*What separates good from great:* Great candidates describe the
`span.recordException(exception)` method as a convenience for
creating a standardized "exception" event with stack trace attributes.

---

**Q5 [MID] What is the difference between auto-instrumentation and manual instrumentation?**

*Why they ask:* Tests OpenTelemetry implementation knowledge.

*Likely follow-up:* When is manual instrumentation preferred over auto?

Auto-instrumentation uses bytecode manipulation (Java agent) or
monkey-patching (Python, Node.js) to automatically add spans to
known framework code: Spring MVC request handlers, JDBC calls,
Redis operations, Kafka producers/consumers. It requires zero
application code changes - just add the OTel agent to the JVM
startup command. It covers all standard framework calls
automatically. Manual instrumentation uses the OTel SDK API
directly in application code to create spans for business-specific
operations. It requires code changes at each instrumentation point.
When to prefer manual: when auto-instrumentation creates too many
spans for a particular framework (e.g., auto-instrumented Hibernate
generates a span per SQL query; for batch operations you may want
only one span for the entire batch). When you need business-context
attributes (user.id, order.type) that auto-instrumentation does not
add. For custom protocols or communication patterns not covered by
auto-instrumentation. The best practice is auto-instrumentation
as the base (zero-effort coverage) plus manual spans for business
operations that auto-instrumentation does not model correctly.

*What separates good from great:* Great candidates describe how to
suppress specific auto-instrumentation libraries while keeping others.

---

**Q6 [JUNIOR] What does a trace status of ERROR mean?**

*Why they ask:* Tests span lifecycle knowledge.

*Likely follow-up:* How do you set a span's status in code?

A trace status of ERROR means the span's operation failed.
A span has three possible statuses: UNSET (the default, meaning
"I have not explicitly set a status"), OK (the operation
completed successfully), and ERROR (the operation failed).
Setting ERROR status on a span makes it visible in trace tools
as a failed operation and enables filtering by status:
"show me all traces with at least one ERROR span." To set it:
`span.setStatus(StatusCode.ERROR, "Payment processing failed")`.
The second argument is an optional description. You should also
call `span.recordException(exception)` before setting ERROR status
when an exception caused the failure - this creates a span event
with the exception type, message, and stack trace as attributes.
Setting ERROR status without recording the exception loses the
stack trace. The common mistake is forgetting to set ERROR status
in catch blocks, so failed operations look successful in traces.

*What separates good from great:* Great candidates describe the
difference between setting ERROR on the immediate span (the
operation that failed) vs propagating ERROR up through parent spans.

---

**Q7 [SENIOR] How does sampling affect trace data quality?**

*Why they ask:* Tests understanding of sampling trade-offs.

*Likely follow-up:* What percentage of traces should be sampled in production?

Sampling determines which requests have their trace data retained
versus discarded. At 100,000 RPS, retaining 100% of traces would
generate terabytes of data per day. Sampling reduces this to a
manageable volume. There are two sampling approaches. Head-based
sampling decides at request start: keep 1% of requests randomly.
It is cheap (one decision per request) but discards 99% of error
and slow traces. Tail-based sampling buffers the complete trace
until the request completes, then decides: keep all traces with
ERROR spans, keep all traces above 500ms, keep 1% of everything
else. It is more expensive (buffering infrastructure) but retains
the traces you most want. For production I use tail-based sampling
with the policy: 100% of ERROR traces, 100% of traces above the
p99 SLO threshold, 0.1% of successful traces below the threshold.
This keeps the storage cost low while preserving all diagnostic
value. The risk of heavy sampling: a failure mode that only affects
0.01% of requests may not appear in the 0.1% success sample.
Solution: use error-based sampling (always keep errors) plus
maintain request-level error counters in metrics to detect low-
frequency error rates even when traces are sampled.

*What separates good from great:* Great candidates describe the
OTel Collector tail-sampling processor configuration and the
infrastructure requirements (routing all spans from a trace to
the same collector instance).

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with trace data model (trace_id, span_id, parent_span_id) and critical path |
| Hiring Manager | Lead with "which service caused the latency" diagnosis workflow |
| Bar Raiser | Lead with sampling strategy and the tail-based vs head-based trade-off |
| Peer Engineer | Collaborative: "Context propagation breaks at async boundaries every time I set up a new queue - here is the pattern I use" |

---

### ⚖️ Comparison Table

*(Omit: distributed trace anatomy is a data model definition.
The comparison between traces and logs-with-correlation-IDs is
covered in the Q&A above.)*

---

### 🏛️ System Design

*(Omit: L1 foundational keyword; system design connections covered
in L4/L5 files.)*

---

### 📊 Diagram

*(Omit: the trace structure and Gantt chart are described clearly
in the ASCII block in the Concept Explanation section and the
Example 2 code block above.)*

---

---

# Instrumentation Fundamentals

**TL;DR** - Instrumentation is the practice of adding telemetry
to code. The RED method (Rate, Errors, Duration) is the minimum
viable instrumentation for any request-handling service.

---

### 🎯 Model Answer

**30 seconds:**
> Instrumentation is adding telemetry to code - metrics, logs, and
> traces - so the system can be observed in production. The minimum
> viable instrumentation for any service is the RED method: Rate
> (how many requests per second), Errors (how many fail), Duration
> (how long each takes). With just these three signals, you can
> answer "is this service healthy?" for any service. Everything
> else builds on this foundation.

**3 minutes (Senior):**
> Instrumentation is the deliberate addition of telemetry to code
> to make it observable. There are two types: automatic (agent-based
> or framework-based) and manual (SDK calls in application code).
> Auto-instrumentation via OpenTelemetry Java agent covers the
> framework layer automatically: HTTP request handlers, JDBC calls,
> Redis operations, Kafka producers/consumers. Manual instrumentation
> adds business-context telemetry that frameworks cannot provide:
> user IDs, order types, business event names. The guiding principle
> for what to instrument is the RED method: Rate, Errors, Duration
> at every service boundary. RED gives you three fundamental signals
> that answer "is this service healthy?" - the first question asked
> during any incident. Beyond RED, USE (Utilization, Saturation,
> Errors) covers infrastructure components: database connection pool
> utilization, queue saturation, cache error rate. For business-
> level instrumentation, I add custom metrics and logs for events
> that indicate whether the business function is working: order
> creation rate, payment success rate, notification delivery rate.
> The goal is that any question about system behavior can be answered
> from instrumentation data, without SSH access or code changes.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers design instrumentation as an
organizational practice: service templates with auto-instrumentation
built in, CI validation that rejects services without RED metrics,
and golden dashboards per service type that work automatically
when instrumentation conventions are followed.

*Adapting down:* "Instrumentation means adding code that records
what your service is doing - how many requests, how many errors,
how long things take - so you can see it in a dashboard."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about instrumentation fundamentals
- let me explain what instrumentation is, the RED method, and how
to apply it."

**(2) First principles:** "From first principles, a service running
in production must communicate its internal state to operators.
That communication is instrumentation: emitting telemetry that
records what the service did."

**(3) Bridge:** "A doctor instrumenting a patient adds vital sign
monitors. RED metrics are the vital signs of a software service:
pulse rate (request rate), symptom rate (errors), and response
time (duration)."

---

### 📘 Concept Explanation

**What it is:**
Instrumentation is the practice of adding telemetry (metrics,
logs, and traces) to application code to make its behavior
observable in production.

**The problem it solves:**
An uninstrumented service is a black box. When it fails or
behaves unexpectedly, operators have no data to understand what
happened. Instrumentation converts the black box into an observable
system where any question about behavior can be answered from data.

**How it works:**
The RED method provides the minimum viable instrumentation for
any request-handling service:

```
RED Method
  R - Rate: requests per second
      metric: counter("requests_total", labels=["status"])
  E - Errors: error count and rate
      metric: same counter with status="error"
  D - Duration: request latency distribution
      metric: histogram("request_duration_seconds")

USE Method (for resources)
  U - Utilization: what % of capacity is in use
      metric: gauge("db_pool_active_connections")
  S - Saturation: how much is waiting
      metric: gauge("db_pool_queue_depth")
  E - Errors: resource-level failures
      metric: counter("db_connection_errors_total")
```

Two instrumentation approaches:

Auto-instrumentation: Framework code is instrumented
automatically by an agent. Zero code changes in the application.
Covers HTTP, JDBC, Redis, Kafka, gRPC automatically.

Manual instrumentation: Developer adds SDK calls in application
code. Required for business-context telemetry, custom operation
boundaries, and frameworks not covered by auto-instrumentation.

**The key insight:**
Auto-instrumentation is the baseline; manual instrumentation adds
business context. A service with only auto-instrumentation shows
you that "the checkout HTTP handler is slow." Manual instrumentation
for the payment capture sub-operation shows you that "the payment
capture step is slow, not the inventory check."

**When to use it:**
Instrument every production service. Start with RED metrics
(30 minutes). Add structured logging with trace correlation
(1-2 hours). Add manual spans for business operations (1-3 days).

**When NOT to use it:**
Do not instrument unit tests or local development utilities.
The overhead is unnecessary outside production-facing code.
Do not add instrumentation for metrics you do not have alerts
or dashboards for - unused metrics increase storage cost
without providing value.

**Alternatives:**
- APM vendors (New Relic, Datadog APM): bundle instrumentation
  and tooling; reduce engineering effort at higher cost
- Custom metrics frameworks: home-built before Prometheus/OTel
  era; technical debt if not migrated
- eBPF-based auto-instrumentation: no code changes, no agent;
  instruments at kernel level; emerging technology in 2025

**First-principles derivation:**
A production system is complex and fails in unanticipated ways.
The cost of diagnosing an instrumented service is proportional
to the quality of telemetry emitted. The cost of diagnosing an
uninstrumented service is proportional to the engineer's luck
and SSH access. The ROI of instrumentation is: (MTTR reduction
value) / (instrumentation implementation cost). For any service
with non-trivial traffic, this ratio is positive within the
first incident.

---

### 💻 Code Example

**Example 1: BAD - No instrumentation**

```java
// BAD: completely uninstrumentated service
@RestController
public class CheckoutController {
    @PostMapping("/checkout")
    public Order checkout(
        @RequestBody CartRequest req) {
        // No metrics, no traces, no structured logs
        // Diagnosis requires: SSH + grep + luck
        return orderService.create(req);
    }
}
// During an incident: "Something is wrong with checkout"
// How do you find out? You guess.
```

> **Code walkthrough:** An uninstrumented controller gives
> zero signal during incidents. The only observable signal is
> whether the HTTP response code is 200 or 500, but that requires
> already knowing which requests to look at. There is no way to
> compute error rate, latency distribution, or trace which service
> caused a slowdown. This is a Stage 1 service: reactive, opaque,
> and expensive to debug.

**Example 2: GOOD - RED instrumentation with OTel SDK**

```java
// GOOD: RED metrics + structured logs + trace
// Using OpenTelemetry SDK (API is vendor-neutral)
@RestController
public class CheckoutController {

    private final Counter requests;
    private final Histogram duration;
    private final Tracer tracer;

    public CheckoutController(
        OpenTelemetry otel, Meter meter) {
        this.tracer = otel.getTracer("checkout");
        this.requests = meter
            .counterBuilder("checkout.requests")
            .setDescription("Checkout requests by status")
            .build();
        this.duration = meter
            .histogramBuilder("checkout.duration")
            .setUnit("ms")
            .setDescription("Checkout latency")
            .build();
    }

    @PostMapping("/checkout")
    public ResponseEntity<Order> checkout(
        @RequestBody CartRequest req) {

        long start = System.currentTimeMillis();
        Span span = tracer
            .spanBuilder("checkout.process")
            .setAttribute("user.id", req.getUserId())
            .startSpan();

        try (Scope s = span.makeCurrent()) {
            Order order = orderService.create(req);
            long ms = System.currentTimeMillis() - start;

            // RED: increment success counter
            requests.add(1,
                Attributes.of(
                    AttributeKey.stringKey("status"),
                    "success"
                )
            );
            // RED: record duration
            duration.record(ms,
                Attributes.of(
                    AttributeKey.stringKey("status"),
                    "success"
                )
            );

            log.atInfo()
                .addKeyValue("event","checkout.complete")
                .addKeyValue("user_id", req.getUserId())
                .addKeyValue("order_id", order.getId())
                .addKeyValue("duration_ms", ms)
                .log("Checkout completed");

            return ResponseEntity.ok(order);

        } catch (Exception e) {
            long ms = System.currentTimeMillis() - start;
            // RED: increment error counter
            requests.add(1,
                Attributes.of(
                    AttributeKey.stringKey("status"),
                    "error"
                )
            );
            duration.record(ms,
                Attributes.of(
                    AttributeKey.stringKey("status"),
                    "error"
                )
            );

            span.recordException(e);
            span.setStatus(StatusCode.ERROR, e.getMessage());

            log.atError()
                .addKeyValue("event","checkout.failed")
                .addKeyValue("user_id", req.getUserId())
                .addKeyValue("error", e.getMessage())
                .log("Checkout failed");

            return ResponseEntity.status(500).build();

        } finally {
            span.end();
        }
    }
}
```

> **Code walkthrough:** The GOOD example implements all three
> RED signals. The request counter has a status label (success/error)
> enabling error rate computation: `rate(checkout.requests_total
> {status="error"}[5m]) / rate(checkout.requests_total[5m])`.
> The duration histogram enables p99 computation. The span records
> the operation boundary with user context. The log entries include
> trace correlation. With this instrumentation, every observability
> question about the checkout service can be answered: error rate,
> latency p99, specific slow requests (trace), and per-request
> event context (logs).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Instrumentation is adding metrics, logs, and traces to code so
> the service is observable in production. The minimum I add to any
> service is RED metrics: request rate, error rate, and latency
> distribution. With just RED, I can answer "is this service healthy?"
> using a simple Grafana dashboard. Then I add structured logging
> with trace correlation and manual spans for business operations.

*Push deeper:* Describe the specific code to add RED metrics using
the OpenTelemetry SDK - counter for requests with status label,
histogram for duration.

---

**Senior / Staff (5+ years):**
> Instrumentation is a design discipline, not an afterthought.
> I treat instrumentation requirements the same as functional
> requirements: before writing a new service, I define the RED
> metrics it will emit, the log events with their mandatory fields,
> and the spans for its key operations. I enforce this through a
> service template that includes auto-instrumentation by default
> and a CI step that validates RED metric presence. The harder
> part is business instrumentation: ensuring that business events
> (order created, payment captured, notification sent) are
> instrumented with enough context that business-level questions
> can be answered from telemetry alone, not just technical questions.

*Push deeper:* Describe how you validated that your instrumentation
was sufficient by designing a table-top incident drill where
engineers diagnose a simulated failure using only telemetry.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
| ------------- | ------- |
| "Auto-instrumentation is sufficient" | Auto-instrumentation covers framework calls. Business events (payment captured, order created) require manual instrumentation |
| "Instrumentation is done once" | Instrumentation must evolve with the service. New features need new metrics; changed business logic needs updated log events |
| "More metrics are always better" | Unused metrics cost storage and processing. Only add metrics you have dashboards or alerts for |
| "Instrumentation slows down the service" | RED instrumentation with histograms adds < 1% overhead at production scale with the OTel SDK |

---

### 🚨 Failure Modes and Diagnosis

**Mode 1 - Business function fails silently (no business metrics)**

Symptom: The checkout service shows healthy RED metrics (low
error rate, good latency). Users report that checkouts succeed
but orders never appear in the order system.

Root cause: The order creation step succeeds from the checkout
service's perspective, but the background job that writes to
the order system is failing silently. No business-level metric
tracks "order successfully created in order system."

Diagnostic:
```bash
# Check if order creation events appear in logs
{app="checkout"} | json | event="order.created"
# Check if order processing jobs complete
{app="order-processor"} | json | event="order.processed"
# If checkout has order.created but order-processor
# has no order.processed, the gap is in the async step
```

Fix: Add a business metric for order creation success:
`counter("orders_created_total", labels=["status"])` in the
order processor. Alert on `sum(rate(...{status="error"})) > 0`.

Prevention: For every user-facing business function, define
at least one business metric that measures success from the
user's perspective (not just the HTTP response code).

---

**Mode 2 - Missing status label on RED counter**

Symptom: Checkout error rate is 0 according to Prometheus.
Users are reporting errors. The error rate calculation
(`rate(errors) / rate(total)`) returns 0 because there is
no separate error counter.

Root cause: Request counter was defined with no status label.
Both successes and errors increment the same counter. There
is no way to separate them.

Diagnostic:
```bash
# Check available labels on the checkout counter
curl -s http://prometheus:9090/api/v1/query \
  --data-urlencode 'query={__name__="checkout_requests_total"}' \
  | jq '.data.result[].metric'
# If no "status" label appears, both success and error
# are in the same counter
```

Fix: Add a status label to the counter. Deploy the updated
service. Historical data will not be retroactively corrected,
but new data will have the status dimension.

Prevention: Code review checklist: every request counter must
have a status label. Template provides this by default.

---

**Mode 3 - Cardinality from high-cardinality attribute on span**

Symptom: Jaeger storage is growing faster than expected. Trace
query performance degrades.

Root cause: A span attribute with a high-cardinality value
(user_id, order_id, full SQL query) was added to every span.
Trace indexing (Elasticsearch backend for Jaeger) creates an
index entry per unique attribute value.

Diagnostic:
```bash
# Check Elasticsearch index size and growth
curl http://elasticsearch:9200/_stats/store | \
  jq '.indices | to_entries[] | {
    index: .key, size_mb: (.value.total.store.size_in_bytes / 1048576)
  } | select(.size_mb > 1000)'
# Check which attribute has the most unique values
# in a sample of 1000 traces
```

Fix: Replace full SQL query string with a parameterized query
name: `db.statement="SELECT * FROM orders WHERE id=?"` (safe,
low cardinality) instead of the actual value. Remove user_id
from span attributes for high-traffic services; use trace
ID correlation with logs instead.

Prevention: Span attribute code review. Full query strings
and user-generated content are not allowed as span attributes.

---

### 🎯 Interview Deep-Dive

| Question type | Time budget | Goal |
| ------------- | ----------- | ---- |
| Conceptual | 60 sec | Describe RED and why it is the minimum |
| Scenario | 2 min | Instrument a new service from scratch |
| Debugging | 90 sec | Diagnose a silent business failure |
| Comparison | 60 sec | Auto vs manual instrumentation |
| Trade-off | 60 sec | Overhead vs coverage |
| Production | 2 min | Describe a missing instrumentation incident |
| Behavioral | 2-3 min | STAR story of setting up instrumentation from scratch |

---

**Q1 [JUNIOR] What is the RED method?**

*Why they ask:* One of the most common observability interview
questions. Tests knowledge of minimum viable instrumentation.

*Likely follow-up:* What does each signal tell you?

RED stands for Rate, Errors, and Duration. It is the minimum
viable instrumentation for any service that handles requests.
Rate is the number of requests the service receives per second:
it tells you how much load the service is under and whether
traffic patterns are normal. Errors is the count (and rate)
of requests that fail: it tells you whether the service is
performing its function correctly. Duration is the latency
distribution of requests: it tells you whether the service
is fast enough to meet its SLO. Together, these three signals
answer the fundamental question "is this service healthy?" for
any request-handling service. A service with low error rate and
latency within SLO is healthy. A spike in error rate or latency
indicates a problem. With RED, you have enough signal to fire
an SLO-based alert and begin investigation. Without any of the
three, you have a blind spot: no rate means you cannot compute
error rate; no errors means failures are invisible; no duration
means latency SLOs cannot be measured.

*What separates good from great:* Great candidates describe how
RED is implemented: one counter with a status label for Rate+Errors,
one histogram for Duration.

---

**Q2 [MID] How do you decide what to instrument manually vs leave to auto-instrumentation?**

*Why they ask:* Tests practical instrumentation design judgment.

*Likely follow-up:* What does auto-instrumentation miss?

Auto-instrumentation covers the framework layer: HTTP requests,
SQL queries, Redis commands, Kafka messages. It provides latency
and error data for each operation at the framework level. I use
it as the baseline because it requires zero code changes and
immediately gives me RED metrics for all framework calls. Manual
instrumentation is needed for three cases. First, business events:
auto-instrumentation does not know about "checkout.payment_capture"
vs "checkout.inventory_check." I add manual spans to distinguish
business operations within a request. Second, business context
attributes: auto-instrumentation adds http.url and http.method
but not user.id or order.type. I add these manually as span
attributes. Third, business metrics: I manually emit counters for
business success events (orders created, payments captured) that
the framework layer cannot infer. My rule: auto-instrumentation
for framework-level signals (latency, errors by HTTP status),
manual instrumentation for business-level signals (latency and
errors by business operation, business event counters).

*What separates good from great:* Great candidates describe how
to suppress auto-instrumentation for specific operations (like
health check endpoints) that create noise.

---

**Q3 [SENIOR] What is the USE method and when does it apply?**

*Why they ask:* Tests whether you know both RED (request-based)
and USE (resource-based) instrumentation.

*Likely follow-up:* What resources in a Java service should use the USE method?

USE stands for Utilization, Saturation, and Errors. It applies
to resources that can become saturated rather than to services
that handle requests. RED applies to services; USE applies to
their supporting resources. Utilization is what percentage of
the resource's capacity is currently in use: 80% CPU, 60%
memory, 45/50 database connections active. Saturation is how
much demand is waiting: thread pool queue depth, database
connection wait time. Errors is resource-level failures:
connection timeouts, disk write errors, network packet loss.
In a Java microservice, USE applies to: the database connection
pool (Utilization: active connections/pool size; Saturation:
queue of waiting threads; Errors: connection failures), the
thread pool (Utilization: active threads/max; Saturation:
queue depth; Errors: rejected tasks), and the JVM heap
(Utilization: heap used/heap max; Saturation: GC pause
frequency/duration; Errors: OutOfMemoryErrors). RED+USE
together provide complete coverage: RED for whether requests
are being handled correctly, USE for whether resources
supporting those requests are healthy.

*What separates good from great:* Great candidates describe
the specific Prometheus metrics for HikariCP (Java connection
pool) and Spring thread pool that implement USE.

---

**Q4 [JUNIOR] Why is the trace ID the most important field to include in logs?**

*Why they ask:* Tests understanding of log-to-trace correlation.

*Likely follow-up:* How do you include it automatically without changing every log call?

The trace ID connects a log line to its full distributed trace
context. Without the trace ID in logs, finding the trace for
a specific error requires searching by time range and then
manually correlating trace data - a slow, imprecise process.
With the trace ID as a named field in every log line, the
workflow becomes: open the log entry in Grafana Loki, click
the trace_id field value, and jump directly to the full trace
in Grafana Tempo. This one-click correlation is only possible
when the trace ID is a discrete named field, not embedded in
the message string. In Java with OpenTelemetry, the trace ID
is automatically injected into every log line via MDC when
the OTel Java agent is running. The agent sets MDC key
"trace_id" to the current span's trace ID at the start of
each traced operation. The Logback JSON encoder includes MDC
fields in every log entry. Zero code changes are needed at
log call sites.

*What separates good from great:* Great candidates describe
Grafana's "Derived Field" feature in the Loki data source
configuration that creates a clickable link from the trace_id
value in log lines to the corresponding trace in Tempo.

---

**Q5 [MID] What is the instrumentation cost on request latency?**

*Why they ask:* Tests understanding of overhead trade-offs.

*Likely follow-up:* How do you measure instrumentation overhead?

The overhead of RED instrumentation using the OpenTelemetry SDK
is typically 1-3% of request latency for a service at moderate
load. The breakdown: counter increment (lock-free atomic
operation, approximately 5-20 nanoseconds), histogram record
(bucket array update, approximately 50-100 nanoseconds), span
creation (context propagation + attribute map creation,
approximately 1-5 microseconds). For a service with 100ms
average latency, a 5-microsecond span creation is 0.005%
overhead. For a service with 1ms average latency, it is 0.5%.
For ultra-low-latency services (< 100 microseconds), OTel
overhead is measurable and may require optimization: reduce
attribute count on spans, use no-op OTel implementations for
hot paths, or use sampling to only fully instrument 1% of requests.
I measure overhead with a load test: run 30 minutes without
instrumentation, 30 minutes with instrumentation, compare p99
latency. A difference > 5% indicates the instrumentation needs
optimization.

*What separates good from great:* Great candidates describe the
`exporterTimeout` and batch export configuration that reduces
overhead by asynchronously exporting spans rather than blocking.

---

**Q6 [SENIOR] How do you add instrumentation to a legacy service without breaking it?**

*Why they ask:* Tests practical risk management for instrumentation work.

*Likely follow-up:* How do you validate that the new instrumentation is correct?

Adding instrumentation to a legacy service has three risks:
performance regression, behavior change (instrumentation that
catches exceptions may change exception propagation), and log
volume explosion (adding INFO logs where none existed). I manage
these risks with the following approach. First, start with
OpenTelemetry Java agent: attach to the JVM startup command
with zero code changes. Monitor latency and error rate before
and after in the staging environment. If no regression, deploy
to production. Second, add structured logging: replace existing
log.info("string") calls one file at a time, starting with
the highest-traffic code path. Deploy and monitor log volume
per day. Third, add manual spans only for the two or three
most important business operations - not every method. Validate
each span by triggering the operation and verifying the trace
appears in Jaeger. Fourth, add business metrics in a separate
PR from the framework metrics, one metric at a time. The key
safety rule: every instrumentation change is in its own PR
with a specific metric or trace it adds, and validated in
staging before production.

*What separates good from great:* Great candidates describe the
canary deployment strategy for instrumentation changes: deploy
to 5% of instances and compare telemetry health before full rollout.

---

**Q7 [STAFF] How do you enforce instrumentation standards at an organization?**

*Why they ask:* Tests platform engineering thinking.

*Likely follow-up:* How do you handle teams that are moving too fast to add instrumentation?

Instrumentation enforcement at an organizational level requires
making the standard the path of least resistance. I implement
this in three layers. First, a service template: every new
service created from the template includes the OTel agent
in the Dockerfile, RED metrics defined in a metrics registry
class, structured logging configured in logback-spring.xml,
and an example trace span. The engineer gets instrumentation
for free - no effort required. Second, a CI validation step:
a test in every service's build pipeline launches the service
and verifies that the RED metric names exist in the Prometheus
metrics endpoint and the OTel agent injects trace_id into log
lines. This catches services that remove instrumentation or
misconfigure the agent. Third, golden dashboards: a Grafana
dashboard template that uses the standard metric names generates
automatically for every service. Engineers who follow the standard
get a working dashboard; engineers who do not follow it have to
create their own. The incentive structure makes compliance the
easier path. For teams moving too fast to add instrumentation:
the CI check makes non-compliance visible. I negotiate a 2-sprint
grace period for new services, then the build fails.

*What separates good from great:* Great candidates describe the
specific CI validation code and how they made it fast enough
to not block developers (< 30 second validation time).

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with the RED method implementation in code |
| Hiring Manager | Lead with the business case: uninstrumented service costs X hours per incident |
| Bar Raiser | Lead with service templates and CI validation as the organizational enforcement mechanism |
| Peer Engineer | Collaborative: "The first 30 minutes of a new service should produce working RED metrics - here is the template pattern I use" |

---

### ⚖️ Comparison Table

*(Omit: instrumentation fundamentals is a methodology with
no direct competing alternatives. Tool comparisons are in the
Q&A above.)*

---

### 🏛️ System Design

*(Omit: L1 foundational keyword; system design connections covered
in L4/L5 files.)*

---

### 📊 Diagram

*(Omit: the RED method structure and code examples above
illustrate instrumentation clearly. A separate diagram does
not add meaningful signal for this L1 concept.)*
