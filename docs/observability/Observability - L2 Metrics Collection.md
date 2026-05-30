---
layout: default
title: "Observability - L2 Metrics Collection"
parent: "Observability"
nav_order: 5
permalink: /observability/l2-metrics-collection/
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Prometheus Metrics Collection](#prometheus-metrics-collection) | critical |
| 2   | [Grafana Dashboard Design](#grafana-dashboard-design) | high |

---

# Prometheus Metrics Collection

**TL;DR** - Prometheus scrapes HTTP /metrics endpoints at a
configured interval, stores time series, and provides PromQL
for querying. Understanding the scrape model, pull-based
architecture, and remote write pattern is essential for
operating Prometheus in production.

---

### 🎯 Model Answer

**30 seconds:**
> Prometheus is a pull-based metrics system: it scrapes HTTP /metrics
> endpoints from each service at a configured interval (typically 15
> seconds). Services expose metrics in Prometheus exposition format
> (key{label=value} numeric_value timestamp). Prometheus stores the
> scraped data as time series and provides PromQL for querying. For
> long-term storage, it uses remote_write to forward data to a TSDB
> like Thanos, Cortex, or Mimir. The pull model means each service
> must have its scrape endpoint discovered by Prometheus - typically
> via Kubernetes service discovery.

**3 minutes (Senior):**
> Prometheus' pull-based architecture has fundamental implications
> for how it operates in a Kubernetes environment. Each service
> exposes a /metrics HTTP endpoint that returns all current metric
> values in the text exposition format. Prometheus uses Kubernetes
> service discovery (via the Prometheus Operator's ServiceMonitor
> CRD or static configs) to discover which endpoints to scrape.
> It scrapes each endpoint at a configurable interval (15 seconds
> is the default and a reasonable production value). Scraped values
> are stored in a local TSDB (time series database) on disk in
> the Prometheus pod. The local TSDB is bounded (default 15 days
> retention) and not highly available. For long-term storage and
> HA, Prometheus uses remote_write: every scraped sample is
> forwarded to a remote_write endpoint in parallel with local
> storage. Thanos Receive, Cortex, or Grafana Mimir are the common
> remote_write targets. They provide long-term storage, multi-
> tenant isolation, and global query view across multiple Prometheus
> instances. The critical operational concern is scrape interval
> vs cardinality: every (metric name, label combination) is one
> time series. At 15-second scrape interval, 1 million time series
> consume approximately 1.5 bytes * 60 samples/hour * 24 hours =
> 2.2GB per day. Prometheus recommends a maximum of 10 million
> active time series per instance.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers design the Prometheus federation
topology: shard by scrape target to stay below 10M time series
per instance, deploy Thanos sidecar or remote_write to Mimir,
configure recording rules to pre-compute expensive queries, and
govern cardinality with budget limits per team.

*Adapting down:* "Prometheus asks each service 'how are you doing?'
every 15 seconds and stores the answer. PromQL is how you ask
questions about the stored data."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Prometheus collects
metrics - let me explain the pull model, service discovery,
and storage architecture."

**(2) First principles:** "From first principles, you need to
know the current state of all services at regular intervals.
Prometheus implements this with a pull loop: ask each service
for its metrics on a schedule."

**(3) Bridge:** "Think of a census: instead of everyone reporting
to the government (push), the government sends an agent to each
household on a schedule (pull). Prometheus is the census agent;
/metrics is each household's door."

---

### 📘 Concept Explanation

**What it is:**
A pull-based metrics collection system that scrapes HTTP /metrics
endpoints, stores time series in a local TSDB, and provides
PromQL as the query language.

**The problem it solves:**
In a Kubernetes environment with hundreds of service instances,
gathering metrics centrally without requiring each service to
know the metrics server's address (push model) simplifies
configuration and enables dynamic discovery. Prometheus discovers
targets via Kubernetes API; services just expose /metrics.

**How it works:**
Prometheus collection pipeline:

```
[Service /metrics endpoint]
  Exposes text exposition format:
    http_requests_total{method="GET",
      status="200"} 42045 1717000000000
      |
[Prometheus scrape loop (every 15s)]
  - ServiceMonitor CRD defines scrape targets
  - Kubernetes SD discovers pod IPs automatically
  - HTTP GET /metrics, parses response
  - Stores samples in local TSDB
      |
[Local TSDB]
  WAL -> chunks -> blocks (2h -> 1 day -> compaction)
  Retention: 15 days default
      |
[remote_write]
  Forwards all samples to remote TSDB
  (Thanos, Cortex, Mimir) for long-term storage
      |
[PromQL query layer]
  rate(), histogram_quantile(), sum by (), etc.
```

> **Diagram walkthrough:** Each stage adds value. The scrape
> loop discovers targets via Kubernetes SD - no manual target
> list needed. The TSDB provides fast local queries for recent
> data. remote_write extends retention and enables global queries
> across multiple Prometheus instances. The PromQL layer is the
> query interface for dashboards and alerts.

**The key insight:**
The ServiceMonitor CRD (Prometheus Operator) is the primary
mechanism for adding a service to Prometheus scraping. Kubernetes
pods need a label matching the ServiceMonitor's selector, and
the ServiceMonitor defines which port and path to scrape. No
Prometheus configuration file changes needed.

**When to use it:**
Prometheus is the standard metrics backend for Kubernetes.
Use it for all infrastructure and service metrics. Use a managed
vendor (Datadog, New Relic) when operating Prometheus is
too expensive (small teams, complex Kubernetes).

**When NOT to use it:**
Do not use Prometheus for event-based data (logs, traces).
Do not use Prometheus for metrics with cardinality > 10M time
series (use Grafana Mimir or Thanos for horizontal scaling).
Do not use Prometheus as a durable long-term store without
remote_write to a long-term backend.

**Alternatives:**
- Grafana Mimir: horizontally scalable Prometheus-compatible
  backend; drop-in replacement for remote_write target
- Thanos: adds long-term storage and global query view on top
  of existing Prometheus instances; no code changes
- Victoria Metrics: single-binary Prometheus-compatible TSDB;
  lower resource usage than Prometheus; good for high cardinality

**First-principles derivation:**
A time series database optimized for metrics has different
access patterns than a general OLTP database. Metrics are
written at regular intervals by many writers (all service instances)
and queried by range (give me the last 5 minutes) and by label
subset (give me all series where service=checkout). Prometheus'
TSDB design (WAL + 2-hour blocks + compaction) is optimized
for this pattern: fast ingestion, fast range queries, efficient
storage with delta-encoding and compression.

---

### 💻 Code Example

**Example 1: BAD - Prometheus scrape misconfiguration (push model)**

```yaml
# BAD: trying to push metrics from service to Prometheus
# This is backwards - Prometheus is pull-based
# Some teams confuse Prometheus with Graphite/StatsD

# What this tries to do (wrong model):
# Service -> pushes to pushgateway -> Prometheus scrapes
# Problems:
# - Pushgateway is for batch jobs, not services
# - Pushgateway is a single point of failure
# - Stale metrics stay in pushgateway after service dies
# - No health signal from pushgateway (service "looks alive")
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  METRICS_PUSH_URL: "http://pushgateway:9091/metrics/job/checkout"
# Service pushes to pushgateway - WRONG for a live service
```

> **Code walkthrough:** The BAD pattern uses Prometheus Pushgateway
> as a target for service metrics push. Pushgateway is designed for
> batch jobs that do not have a persistent process. For a live service,
> Pushgateway creates a false health signal: if the service crashes,
> its last-pushed metrics remain in Pushgateway indefinitely, making
> the service appear alive. Prometheus loses the scrape-based health
> check (a service that fails to respond to scrape is marked "down").
> This is a common misunderstanding by teams coming from StatsD or
> Graphite (push-based).

**Example 2: GOOD - Correct Prometheus setup (ServiceMonitor)**

```yaml
# GOOD: Prometheus pull model via ServiceMonitor CRD
# Step 1: Expose metrics in the service
apiVersion: v1
kind: Service
metadata:
  name: checkout
  labels:
    app: checkout
    # Label that ServiceMonitor selects
    monitoring: "true"
spec:
  ports:
    - name: http
      port: 8080
    - name: metrics
      port: 8081  # Separate port for metrics
  selector:
    app: checkout
---
# Step 2: ServiceMonitor tells Prometheus to scrape this service
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: checkout-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      monitoring: "true"  # Matches service label
  endpoints:
    - port: metrics
      path: /metrics
      interval: 15s
      # Scrape timeout must be < interval
      scrapeTimeout: 10s
  # Find services in these namespaces
  namespaceSelector:
    matchNames:
      - production
```

> **Code walkthrough:** The GOOD setup defines the Prometheus
> pull model correctly. The service exposes a dedicated metrics
> port (8081) separate from the application port to prevent
> accidental public exposure of metrics. The ServiceMonitor CRD
> tells the Prometheus Operator to scrape all services with
> `monitoring=true` in the production namespace every 15 seconds.
> When the checkout service scales from 2 to 10 instances, all 10
> pods are automatically discovered and scraped via Kubernetes
> endpoint discovery. No Prometheus configuration file changes
> are needed.

**Example 3: Recording rules for expensive queries**

```yaml
# Recording rules pre-compute expensive PromQL expressions
# at write time, making dashboard queries instant
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: checkout-recording-rules
spec:
  groups:
    - name: checkout.rules
      interval: 1m  # Pre-compute every minute
      rules:
        # Pre-compute p99 latency by service
        - record: job:checkout_p99_latency:rate5m
          expr: |
            histogram_quantile(0.99,
              sum by (le, service) (
                rate(
                  checkout_duration_seconds_bucket[5m]
                )
              )
            )

        # Pre-compute error rate
        - record: job:checkout_error_rate:rate5m
          expr: |
            sum by (service) (
              rate(
                checkout_requests_total{status="error"}[5m]
              )
            ) /
            sum by (service) (
              rate(checkout_requests_total[5m])
            )
# Dashboards query the recording rule results:
# job:checkout_p99_latency:rate5m{service="checkout"}
# Instant query against pre-computed data
```

> **Code walkthrough:** Recording rules pre-compute expensive PromQL
> expressions into new metric series every minute. The histogram_quantile
> computation over rate() is expensive to run at query time across
> millions of samples. Pre-computing it produces a simple scalar
> time series that dashboards can query instantly. This reduces
> Prometheus CPU load by 10-50x for dashboard heavy use cases.
> The naming convention (job:metric_name:aggregation_range) follows
> the Prometheus recording rule naming standard.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Prometheus is pull-based: it scrapes each service's /metrics endpoint
> every 15 seconds. Services expose metrics in text format; Prometheus
> stores time series locally and provides PromQL for queries. In
> Kubernetes, I use ServiceMonitor CRDs (Prometheus Operator) to tell
> Prometheus which services to scrape. For long-term storage, I configure
> remote_write to Thanos or Mimir.

*Push deeper:* Describe how a ServiceMonitor discovers pod IPs
automatically when a service scales up, so Prometheus always
scrapes all instances without manual configuration.

---

**Senior / Staff (5+ years):**
> The pull-based architecture has operational implications I design
> around. Prometheus' local TSDB is not HA: if the Prometheus pod
> dies, in-flight data is lost. I mitigate this with two techniques:
> remote_write sends data to a HA-capable remote TSDB (Mimir or
> Thanos) in real time, and I run two Prometheus instances scraping
> the same targets (Prometheus HA pairs) so if one dies the other
> continues without gaps. The cardinality budget is the other design
> constraint: each unique label value combination creates a time
> series. I enforce a per-service cardinality budget of 5,000 time
> series maximum, reviewed in code review and enforced by a CI
> check that validates metric cardinality in integration tests.

*Push deeper:* Describe the remote_write queue configuration and
how to tune send capacity vs memory usage.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
| ------------- | ------- |
| "Prometheus is a push-based system" | Prometheus is pull-based. Services expose /metrics; Prometheus scrapes them. Pushgateway is only for batch jobs |
| "More frequent scrapes = better data" | Scraping at 5 seconds instead of 15 increases Prometheus load 3x for negligible query accuracy improvement. 15 seconds is the production standard |
| "I can use Prometheus as a long-term metrics database" | Prometheus local TSDB has 15-day retention and is not HA. Use remote_write to a long-term backend (Thanos, Mimir) for durable storage |
| "ServiceMonitor needs to be in the same namespace" | ServiceMonitor can target services in other namespaces via namespaceSelector. The ServiceMonitor namespace determines which Prometheus instance picks it up |

---

### ⚖️ Comparison Table

| Backend | Best for | Scaling | Highlights |
|---------|----------|---------|------------|
| **Prometheus local** | Single cluster, 15-day retention | Single instance to 10M series | Zero ops, standard |
| **Thanos** | Long-term, multi-cluster query | Horizontal (object storage) | Works with existing Prometheus |
| **Grafana Mimir** | High scale, multi-tenant | Horizontal microservices | Prometheus-compatible API |
| **Victoria Metrics** | High cardinality, low resources | Horizontal with cluster version | Lower CPU than Prometheus |
| **Datadog** | Managed, low ops burden | Managed by vendor | High cost at scale |

**Choosing the right backend:**
Single cluster with < 5M series: Prometheus local + Thanos sidecar.
Multiple clusters or > 5M series: remote_write to Mimir or Thanos Receive.
Managed preference: Grafana Cloud or Datadog.

---

### 🚨 Failure Modes and Diagnosis

**Mode 1 - Prometheus OOMKilled due to cardinality spike**

Symptom: Prometheus pod restarts with OOMKilled exit code. After
restart, there is a gap in all metrics dashboards.

Root cause: A new metric with a high-cardinality label was
deployed. Each unique label value created a new time series.
At 1M time series, Prometheus uses approximately 4GB RAM.

Diagnostic:
```bash
# Check TSDB status for cardinality offenders
curl -s http://prometheus:9090/api/v1/status/tsdb |
  jq '.data.seriesCountByMetricName |
    sort_by(.seriesCount) | reverse | .[0:10]'
# Returns top 10 metrics by time series count
# Any metric > 100K series is a cardinality risk
```

Fix: Drop the high-cardinality metric via relabeling rule in
the ServiceMonitor or via Prometheus `metric_relabel_configs`.
Scale up Prometheus memory if needed as an immediate fix.

Prevention: CI check that validates metric cardinality in
integration tests. Cardinality budget: 5,000 series max per service.

---

**Mode 2 - Scrape gap during pod restart**

Symptom: Dashboard shows a gap in metrics during Prometheus pod
restart. Alertmanager fires spurious alerts for "no data."

Root cause: Prometheus stores recent data in memory (WAL). During
a pod restart, the WAL is replayed but takes 2-5 minutes. During
this window, queries return no data for recent time ranges.

Diagnostic:
```bash
# Check WAL replay status after restart
kubectl logs -n monitoring prometheus-0 | \
  grep "WAL replay"
# Shows replay progress:
# ts=... caller=head.go msg="WAL replay complete"
# duration=3m42s
```

Fix: Deploy Prometheus in HA mode: two replicas scraping
the same targets. When one restarts, the other continues.
Use a load balancer (Thanos Query or Grafana) that routes
queries to the healthy instance during restart.

Prevention: Run Prometheus in HA pairs in production.
Alert on Prometheus-level health, not just application-level.

---

### 🎯 Interview Deep-Dive

| Question type | Time budget | Goal |
| ------------- | ----------- | ---- |
| Conceptual | 60 sec | Describe pull model and scrape loop |
| Architecture | 2 min | Long-term storage with remote_write |
| Debugging | 90 sec | Diagnose cardinality OOM |
| Scenario | 2 min | Design metrics collection for 50 services |
| Trade-off | 60 sec | Pull vs push model |
| Comparison | 90 sec | Prometheus vs Mimir vs Victoria Metrics |
| Production | 2 min | Describe a scrape gap incident |
| Behavioral | 2-3 min | STAR story of fixing a cardinality explosion |
| Technical depth | 90 sec | Describe TSDB block structure and compaction |

---

**Q1 [MID] How does Prometheus discover scrape targets in Kubernetes?**

*Why they ask:* Tests practical Kubernetes + Prometheus integration.

*Likely follow-up:* What is the Prometheus Operator?

Prometheus discovers Kubernetes scrape targets through two
mechanisms. First, the Prometheus Operator pattern (production
standard): a ServiceMonitor CRD defines which services to scrape
by label selector. The Prometheus Operator watches for ServiceMonitor
objects and automatically updates Prometheus' scrape configuration.
A ServiceMonitor with `matchLabels: {monitoring: "true"}` tells
Prometheus to scrape all Services in the specified namespaces
with that label. Kubernetes endpoint discovery then resolves the
service to all healthy pod IPs, so Prometheus scrapes each pod
instance individually. When a deployment scales from 2 to 10
pods, all 10 pod IPs are automatically added to the scrape list.
Second, static configs (for simple setups or non-Kubernetes):
manually list target IPs and ports in the Prometheus configuration
file. This does not scale and requires manual updates when pods
change. In production Kubernetes, the Prometheus Operator with
ServiceMonitor CRDs is the standard because it handles dynamic
pod discovery automatically.

*What separates good from great:* Great candidates describe the
difference between pod-level scraping (one target per pod, using
PodMonitor CRD) vs service-level scraping (one target per endpoint
behind the service, using ServiceMonitor).

---

**Q2 [SENIOR] What is remote_write and when do you need it?**

*Why they ask:* Tests production Prometheus architecture knowledge.

*Likely follow-up:* What are the failure modes of remote_write?

remote_write is Prometheus' mechanism for forwarding scraped
samples to a remote storage backend in real time. Every sample
that Prometheus ingests is also queued for remote_write to one
or more remote endpoints. The use cases are: long-term retention
(Prometheus local retention is 15 days; remote backends like
Thanos, Mimir, or Victoria Metrics provide years of retention),
high availability (two Prometheus instances writing to the same
remote backend create a deduplicated HA setup), global query
(one query against a remote backend that receives data from
multiple Prometheus instances across clusters). The failure mode
of remote_write is queue backup: if the remote endpoint is slow
or unavailable, the remote_write queue grows in Prometheus
memory. The queue has a configurable capacity; if it fills,
samples are dropped. Prometheus logs `remote_write: queue is full`
when this happens. Mitigation: configure the remote_write queue
with a large enough capacity (`queue_config.capacity: 100000`)
and set up a Prometheus alert on `prometheus_remote_storage_queue_length
/ prometheus_remote_storage_queue_capacity > 0.8`.

*What separates good from great:* Great candidates describe the
WAL-based remote_write (remote_write 2.0) that persists the
remote_write queue to disk, preventing data loss on Prometheus
restarts when the remote backend is unavailable.

---

**Q3 [MID] How do you handle high cardinality in Prometheus?**

*Why they ask:* Common production Prometheus problem.

*Likely follow-up:* What are the signs of a cardinality explosion?

High cardinality in Prometheus means too many unique label value
combinations, each creating a separate time series. The limit is
approximately 10M active time series per Prometheus instance at
16GB RAM. Signs of a cardinality explosion: Prometheus memory
usage spikes, scrape duration increases (slow to parse and store
many new series), OOMKilled pods. Handling options: First, prevent
at the source by rejecting high-cardinality labels in code review.
Labels like user_id, request_id, or URL path parameters with
thousands of unique values are prohibited. Second, use metric
relabeling to drop the offending label: add `metric_relabel_configs`
to the ServiceMonitor to drop the high-cardinality label
(`source_labels: [__name__, user_id], target_label: __drop__`).
This drops the label value from ingested series. Third, replace
with cardinality-safe encoding: instead of a label per user_id,
use a counter with a finite label set (status, operation type)
and record per-user data in logs or traces. The cardinality budget
rule: no label with cardinality > 1,000 unique values on any metric.

*What separates good from great:* Great candidates describe the
TSDB status endpoint and how to use it to find cardinality offenders
before they cause an OOM.

---

**Q4 [JUNIOR] What is the text exposition format?**

*Why they ask:* Tests knowledge of the Prometheus protocol.

*Likely follow-up:* How does a Java service expose metrics in this format?

The Prometheus text exposition format is the HTTP response body
format that service /metrics endpoints return. Each metric is
one or more text lines. The format is: optional `# HELP` line
(description), optional `# TYPE` line (counter/gauge/histogram/
summary), then value lines: `metric_name{label_key="value"} numeric_value`.
Example:
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 42045
http_requests_total{method="POST",status="500"} 12
# HELP checkout_duration_seconds Checkout latency
# TYPE checkout_duration_seconds histogram
checkout_duration_seconds_bucket{le="0.1"} 9950
checkout_duration_seconds_bucket{le="0.5"} 9987
checkout_duration_seconds_bucket{le="+Inf"} 10000
checkout_duration_seconds_sum 1245.7
checkout_duration_seconds_count 10000
```
In Java, the Prometheus client library (simpleclient or the
OpenTelemetry Prometheus exporter) generates this format
automatically when you expose an HTTP endpoint. With
OpenTelemetry, adding the PrometheusHttpServer exporter
to your SDK configuration exposes /metrics in text exposition
format with no additional code.

*What separates good from great:* Great candidates describe
the OpenMetrics format (the standardized evolution of Prometheus
text exposition format) and how it differs.

---

**Q5 [SENIOR] How do you size a Prometheus instance?**

*Why they ask:* Tests production capacity planning.

*Likely follow-up:* When should you shard Prometheus?

Prometheus memory usage is approximately 2-3 bytes per active
time series per scrape sample in memory. With a 15-second scrape
interval, each time series contributes approximately 8 samples
per minute. The working memory for a 10-minute window of hot
data is: active_series * samples_per_minute * minutes * bytes.
For 1M time series: 1M * 8 * 10 * 3 bytes = 240MB working set.
Add TSDB chunk cache, rule evaluation, and query execution memory.
A practical sizing formula: RAM (GB) = (active_series / 1M) * 4GB.
For 5M active time series: 20GB RAM. For CPU: scrape CPU scales
linearly with target count; approximately 0.1 CPU core per 1,000
scrape targets per 15-second interval. Disk: at 15-second scrape,
1.5-2 bytes/sample/sec per time series. 1M time series * 2 bytes
* 86,400 seconds = 172GB/day uncompressed. With Prometheus 2.x
compression: approximately 1.5-2GB/day for 1M series. Sharding
threshold: when a single Prometheus instance exceeds 8M active
time series or 80% of RAM under peak load, shard by namespace
or service team.

*What separates good from great:* Great candidates describe the
`--query.max-concurrency` flag and how to tune it to prevent
dashboard queries from consuming all Prometheus CPU.

---

**Q6 [MID] What is a recording rule and when should you use one?**

*Why they ask:* Tests PromQL optimization knowledge.

*Likely follow-up:* How do you name recording rules?

A recording rule evaluates a PromQL expression at a regular
interval and stores the result as a new time series. This
pre-computes expensive queries so dashboard panels query
the result rather than recomputing the expression on demand.
Use recording rules for: queries used on multiple dashboards
(compute once, query many times), computationally expensive
queries like histogram_quantile over many series, and derived
metrics that are aggregated across many label dimensions.
The naming convention for recording rules is:
`{level}:{metric_name}:{aggregation}` where level is the
aggregation scope (job, cluster, namespace), metric_name
is the source metric, and aggregation describes the PromQL
operation. Example: `job:request_latency_seconds:p99_rate5m`
is the p99 latency pre-computed per job over a 5-minute window.
Do not create recording rules for queries only used in one
dashboard and not computationally expensive - the management
overhead is not justified.

*What separates good from great:* Great candidates explain how
recording rules interact with alerting rules: alert expressions
should query recording rule results, not raw metrics, to avoid
alert evaluation timeouts.

---

**Q7 [JUNIOR] What is the scrape interval and why does it matter?**

*Why they ask:* Tests foundational Prometheus knowledge.

*Likely follow-up:* What happens if the scrape interval is too short?

The scrape interval is how often Prometheus polls each /metrics
endpoint for new values. The default is 15 seconds. It matters
because it determines the minimum time resolution of metric data:
you cannot detect events that start and end within one scrape
interval. At 15-second interval, a 5-second spike in error rate
may not be visible if it happens between scrapes. Setting the
interval shorter (e.g., 5 seconds) increases resolution but
also increases Prometheus CPU and memory usage (3x more samples
to process and store), increases scrape load on services, and
increases disk usage and remote_write bandwidth. The 15-second
default is the right balance for most production use cases.
For SLO-critical services where sub-15-second resolution matters,
use 5-second scrape with a recording rule to pre-compute the
rate to avoid re-scanning all samples at query time. Never
set the scrape interval below 5 seconds without a strong
justification: the operational cost is significant.

*What separates good from great:* Great candidates explain the
Prometheus staleness mechanism: if a target fails to respond
to a scrape, its time series receives a "stale" marker after
5 minutes, and rate() returns no value for the stale window.

---

**Q8 [STAFF] How do you govern metric cardinality across 50 teams?**

*Why they ask:* Tests platform engineering governance thinking.

*Likely follow-up:* How do you handle a team that creates a high-cardinality metric?

Governing metric cardinality across many teams requires structural
enforcement, not just guidelines. My approach has four layers.
First, definition governance: teams submit a metric manifest
(name, type, labels, expected cardinality) via pull request.
A bot validates cardinality against the budget. High-cardinality
labels (user_id, request_id) are rejected automatically. Second,
build-time enforcement: a CI integration test instantiates the
service, generates 100 requests, and scrapes /metrics. A custom
validator checks that no metric has cardinality > 1,000 per
instance in the test data. This catches high-cardinality metrics
before production. Third, runtime monitoring: Prometheus' TSDB
status endpoint exposes per-metric series counts. An alert fires
if any metric exceeds 10,000 series and the team is notified.
Fourth, quota enforcement: the Prometheus Operator's
`metric_relabel_configs` automatically drops any new metric from
a team that has exceeded its overall series quota (50,000 series
per team default), forcing them to resolve the issue before new
metrics are accepted.

*What separates good from great:* Great candidates describe the
chargeback model: teams are allocated cardinality budgets based
on service criticality, and exceeding the budget has a cost
(engineering time to fix or negotiate a higher budget).

---

**Q9 [SENIOR] What is the difference between a Prometheus alert rule and an AlertManager route?**

*Why they ask:* Tests end-to-end alerting architecture.

*Likely follow-up:* How do you route alerts to different on-call teams?

A Prometheus alert rule is a PromQL expression that Prometheus
evaluates at a regular interval. When the expression evaluates
to a non-empty result for longer than the configured `for` duration,
Prometheus fires the alert (sends it to AlertManager). The alert
rule defines: when an alert fires (the PromQL condition), how
long it must be true before firing (for: 5m), and metadata
(severity label, description). AlertManager receives fired alerts
and is responsible for routing, deduplication, grouping, and
notification. An AlertManager route is a tree of routing rules
that match alert labels and forward matched alerts to a receiver
(PagerDuty, Slack, email). A route with `match: {severity: "critical",
team: "checkout"}` sends critical alerts labeled `team=checkout`
to the checkout team's PagerDuty integration. The separation
between Prometheus (when) and AlertManager (who gets notified)
is intentional: alert routing is an operational policy that
should not require Prometheus configuration changes.

*What separates good from great:* Great candidates describe the
AlertManager inhibition rule: suppress checkout-degraded alerts
when a lower-level infrastructure-down alert is firing, to
avoid alert storms.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with pull model mechanics and ServiceMonitor discovery |
| Hiring Manager | Lead with the HA gap problem and why remote_write is needed |
| Bar Raiser | Lead with cardinality governance across teams |
| Peer Engineer | Collaborative: "Recording rules are the biggest PromQL performance win I have seen - p99 query goes from 5s to 50ms" |

---

### 🏛️ System Design

*(Omit: L2 working keyword; system design covered in L4/L5 files.)*

---

### 📊 Diagram

*(Omit: the pipeline ASCII diagram in Concept Explanation
above illustrates the Prometheus collection architecture clearly.)*

---

---

# Grafana Dashboard Design

**TL;DR** - A Grafana dashboard is a set of panels querying
observability data sources. Effective dashboard design separates
health-check dashboards (SLO status at a glance) from debugging
dashboards (detailed signals for investigation). The most common
failure is building dashboards for average case instead of the
99th percentile scenario.

---

### 🎯 Model Answer

**30 seconds:**
> Grafana is the standard visualization layer for metrics, logs,
> and traces. A well-designed dashboard has two layers: the top
> section shows SLO health (error rate, latency vs threshold,
> RED metrics) so operators can answer "is this service healthy?"
> in 3 seconds. The bottom section has detailed panels for
> debugging: per-endpoint breakdown, latency heatmap, error log
> stream, trace links. During an incident, you use the top section
> to triage and the bottom section to diagnose.

**3 minutes (Senior):**
> Dashboard design has an audience problem. A health check dashboard
> for on-call engineers needs different panels than a performance
> analysis dashboard for capacity engineers. The two key design
> principles are: (1) The 3-second rule: the most important signal
> must be visible in 3 seconds without scrolling. For an on-call
> dashboard, that is the current SLO status - is error rate above
> threshold, is p99 latency above SLO, is the service down? These
> three signals should be at the top with clear color coding (green/
> yellow/red stat panels). (2) The incident layer: below the health
> summary, detailed panels support investigation: per-endpoint
> latency percentiles, error count by type, log stream filtered
> to ERROR, recent trace links. The incident layer is used after
> triage confirms something is wrong. A common failure is having only
> the incident layer: operators stare at a wall of charts and must
> mentally aggregate them to determine health status. The single panel
> that provides the most value in most dashboards is the latency
> heatmap: it shows the full distribution of latency over time,
> making p99 spikes immediately visible as dark bands at the high-
> latency rows.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers define the golden dashboard
template that every service gets automatically when it follows
metric naming conventions. They also govern dashboard sprawl:
dashboards for services that no longer exist or have never been
used should be archived.

*Adapting down:* "A Grafana dashboard is a configurable set of
charts. The most important design decision is: what question
should someone be able to answer in 3 seconds by looking at it?"

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Grafana dashboard design
- let me explain the key principles for effective dashboards."

**(2) First principles:** "From first principles, a dashboard
serves two purposes: rapid health assessment and detailed debugging.
Design for both use cases explicitly, not with one chart type."

**(3) Bridge:** "Think of a car dashboard: the speedometer and
fuel gauge give instant health status (triage layer). The
diagnostic computer port gives detailed data for mechanics
(investigation layer). Both are necessary; neither replaces
the other."

---

### 📘 Concept Explanation

**What it is:**
Grafana is a multi-source observability visualization platform.
A dashboard is a collection of panels, each querying a data source
(Prometheus, Loki, Tempo, Elasticsearch) with a specific query
and displaying the result in a configured visualization type.

**The problem it solves:**
Raw metrics, logs, and traces in their respective storage backends
are queryable but not at-a-glance. Dashboards make operational
state visible without requiring engineers to write queries during
incidents. A good dashboard transforms raw data into immediate
situational awareness.

**How it works:**
The dashboard design hierarchy:

```
LAYER 1 - HEALTH STATUS (top of dashboard)
  Stat panels: current SLO status (GREEN/RED)
    - Error rate: current vs threshold
    - p99 latency: current vs SLO target
    - Availability: uptime last 30 days
  Time series: SLO signals over time (1-hour view)
    - Error rate trend
    - p99 latency trend

LAYER 2 - SERVICE OVERVIEW (middle)
  Time series: RED metrics (rate, errors, duration)
  Heatmap: latency distribution over time
  Stat: request rate by endpoint

LAYER 3 - DEBUGGING AIDS (bottom or second tab)
  Table: top 5 slowest endpoints last 5 min
  Logs panel: ERROR log stream (Loki)
  Bar chart: error count by type (last 30 min)
  Trace panel: recent trace links (Tempo)
```

**The key insight:**
Template variables make one dashboard serve all services.
A `$service` variable selector at the top of a shared service
dashboard lets any engineer select their service and see the
same panel layout with service-specific data. This avoids
dashboard sprawl (one dashboard per service) while providing
per-service detail.

**When to use it:**
Every production service should have a Grafana dashboard
provisioned automatically from the service template. Ad-hoc
dashboards are appropriate for one-off investigations but
should be archived after 90 days of no views.

**When NOT to use it:**
Do not use Grafana dashboards as the alerting mechanism.
Alerting belongs in PrometheusRule CRDs with AlertManager
routing. Dashboards are for human-initiated investigation;
alerts are for system-initiated notification.

**Alternatives:**
- Datadog dashboards: bundled with Datadog APM; easier to
  set up but higher cost
- Kibana: bundled with Elasticsearch; better for log-heavy
  organizations
- Custom built: some organizations build internal dashboards;
  loses Grafana's rich panel ecosystem

**First-principles derivation:**
The goal of a dashboard is to minimize time-to-answer for
specific operational questions. Each question maps to a
panel: "what is the current error rate?" maps to a stat panel
with the current value. "How has latency changed over the last
hour?" maps to a time series panel. "What are the slowest
endpoints?" maps to a table panel. The design process is:
list the 5-10 questions engineers need to answer during
incidents, map each to a panel type, and arrange by priority
(most important first).

---

### 💻 Code Example

**Example 1: BAD - Dashboard as a wall of charts**

```json
{
  "title": "Checkout Service",
  "panels": [
    // BAD: no structure, all charts at same priority
    // Engineer must read all 12 panels to understand health
    {"title": "CPU Usage",
     "type": "timeseries"},
    {"title": "Memory Usage",
     "type": "timeseries"},
    {"title": "JVM Heap",
     "type": "timeseries"},
    {"title": "HTTP 200 count",
     "type": "timeseries"},
    {"title": "HTTP 500 count",
     "type": "timeseries"},
    {"title": "Database calls",
     "type": "timeseries"},
    {"title": "Cache hits",
     "type": "timeseries"},
    {"title": "Thread pool active",
     "type": "timeseries"},
    {"title": "Kafka consumer lag",
     "type": "timeseries"},
    // ... 8 more panels
    // Question: "Is this service healthy right now?"
    // Answer: read all 12 panels and decide manually
  ]
}
```

> **Code walkthrough:** The BAD dashboard is a flat list of
> technical metrics with no organization by priority. During an
> incident, the on-call engineer must read all 12 panels and
> mentally aggregate to determine health status. There is no
> clear signal that says "healthy" or "degraded." The missing
> elements are: SLO-based stat panels at the top, any connection
> between metrics and business impact, and a logical separation
> between health check panels and debugging panels.

**Example 2: GOOD - Structured service dashboard**

```json
{
  "title": "Checkout Service - SLO Dashboard",
  "templating": {
    "list": [
      {
        "name": "service",
        "type": "query",
        "query": "label_values(
          checkout_requests_total, service)"
      },
      {
        "name": "interval",
        "type": "interval",
        "values": ["1m", "5m", "15m"]
      }
    ]
  },
  "panels": [
    // ROW 1: SLO HEALTH (3-second triage)
    {
      "title": "SLO Status",
      "type": "stat",
      "fieldConfig": {
        "thresholds": {
          "steps": [
            {"value": 0, "color": "green"},
            {"value": 0.001, "color": "red"}
          ]
        }
      },
      "targets": [{
        "expr": "sum(rate(checkout_requests_total{
          service='$service',status='error'}[$interval]))
          / sum(rate(checkout_requests_total{
          service='$service'}[$interval]))"
      }]
    },
    {
      "title": "p99 Latency vs SLO (500ms)",
      "type": "stat",
      "fieldConfig": {
        "thresholds": {
          "steps": [
            {"value": 0, "color": "green"},
            {"value": 0.5, "color": "red"}
          ]
        }
      },
      "targets": [{
        "expr": "histogram_quantile(0.99, sum by(le)
          (rate(checkout_duration_seconds_bucket{
          service='$service'}[$interval])))"
      }]
    },

    // ROW 2: RED METRICS TRENDS
    {
      "title": "Request Rate",
      "type": "timeseries",
      "targets": [{"expr":
        "sum(rate(checkout_requests_total{
         service='$service'}[$interval]))"
      }]
    },
    {
      "title": "Latency Heatmap",
      "type": "heatmap",
      "targets": [{"expr":
        "sum by(le) (
          rate(checkout_duration_seconds_bucket{
          service='$service'}[$interval])
        )"
      }]
    },

    // ROW 3: DEBUGGING AIDS
    {
      "title": "Error Logs (last 30 min)",
      "type": "logs",
      "datasource": "Loki",
      "targets": [{"expr":
        "{app='$service'} | json | level='ERROR'"
      }]
    }
  ]
}
```

> **Code walkthrough:** The GOOD dashboard has three rows
> organized by use case. Row 1 (SLO health) has two stat panels
> that show current error rate and p99 latency with color thresholds.
> Green means healthy; red means degraded. An on-call engineer
> can assess health in 3 seconds. Row 2 shows RED metric trends
> over time for investigating how the situation developed. The
> heatmap shows latency distribution, making p99 spikes visible
> as dark bands at high-latency rows. Row 3 provides an inline
> log stream for Error logs from Loki, eliminating the need to
> switch to a separate tool. Template variables allow the same
> dashboard to serve any service by selecting a service name.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> An effective Grafana dashboard has a clear structure: health
> status at the top (stat panels showing current error rate and
> latency vs threshold), trend charts in the middle (RED metrics
> over time), and debugging tools at the bottom (error log stream,
> latency heatmap). The top section tells you if something is wrong
> in 3 seconds. The bottom section tells you what is wrong during
> investigation.

*Push deeper:* Describe the specific Grafana panel types: stat
(current value with threshold coloring), timeseries (trend over
time), heatmap (distribution over time), logs (Loki log stream).

---

**Senior / Staff (5+ years):**
> Dashboard design is about making operational knowledge explicit
> and accessible. The failure mode is that dashboards reflect what
> was easy to add (all available metrics) rather than what is useful
> to answer (is this service healthy? where is the latency coming
> from?). I design dashboards by starting with the question list:
> what 5 questions do on-call engineers ask during incidents with
> this service? Each question becomes a panel. I also separate
> health dashboards (for on-call triage) from analysis dashboards
> (for capacity and performance work) - these serve different
> audiences with different time horizons.

*Push deeper:* Describe how you implement dashboard-as-code using
Grafonnet (Jsonnet library for Grafana) or Grafana Terraform
provider to manage dashboards in version control.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
| ------------- | ------- |
| "More panels = better dashboard" | More panels increase cognitive load during incidents. The best dashboards have 5-10 focused panels answering specific questions |
| "Grafana is an alerting system" | Grafana can alert but Prometheus AlertManager is the production-grade alerting engine. Use Grafana for visualization; AlertManager for routing |
| "All engineers should be able to edit production dashboards" | Dashboard changes can break on-call investigations. Production dashboards should be version-controlled and changes reviewed |
| "Dashboards replace runbooks" | Dashboards show what is happening; runbooks explain what to do about it. Both are necessary |

---

### ⚖️ Comparison Table

| Panel Type | Best for | When to use |
|------------|----------|-------------|
| **Stat** | Current value with threshold | SLO health status at a glance |
| **Time series** | Trend over time | Error rate, latency trends |
| **Heatmap** | Distribution over time | Latency distribution, p99 visibility |
| **Table** | Ranked/sorted data | Top slowest endpoints, top error sources |
| **Logs** | Recent log stream | Live error investigation |
| **Bar chart** | Comparison across categories | Error count by type |
| **Gauge** | Current value vs range | Pool utilization, cache hit rate |

**When to use heatmap over time series for latency:**
Heatmap shows the full distribution at each point in time,
making slow outliers (p99 spikes) visible even when the
average is healthy. A time series panel showing only p99
hides bimodal distributions.

---

### 🚨 Failure Modes and Diagnosis

**Mode 1 - Dashboard shows healthy during active incident**

Symptom: On-call engineer checks the dashboard, sees all
panels green. Users are reporting errors. 20 minutes lost.

Root cause: The dashboard shows average metrics (avg error rate,
avg latency). The incident affects only 5% of requests (one
payment method). Average hides the problem.

Diagnostic:
```promql
# Add a panel that shows max error rate by dimension
# not just average:
max by (payment_method) (
  rate(checkout_requests_total{status="error"}[5m])
) / max by (payment_method) (
  rate(checkout_requests_total[5m])
)
# Credit card may have 15% error rate while
# avg across payment methods is 0.7%
```

Fix: Add per-dimension breakdown panels to the dashboard.
Replace average-based panels with max-over-dimensions or
per-label panels that show the worst-performing dimension.

Prevention: Dashboard review: every health dashboard must show
per-label breakdown, not just aggregated averages.

---

**Mode 2 - Dashboard query causes Prometheus OOM during incident**

Symptom: During an incident, engineers open multiple Grafana
dashboards. Prometheus CPU spikes. Dashboards timeout.
Incident diagnosis becomes impossible.

Root cause: Dashboard queries are expensive (raw histogram_quantile
over large time ranges) and run on every browser refresh
(every 30 seconds by default).

Fix: Replace expensive dashboard queries with recording rule
results. Pre-compute p99 latency into a recording rule;
dashboard queries the recording rule result (instant query
against a scalar time series).

Prevention: All histogram_quantile expressions in dashboards
must query a recording rule result, not raw histogram data.

---

### 🎯 Interview Deep-Dive

| Question type | Time budget | Goal |
| ------------- | ----------- | ---- |
| Design | 3 min | Design a service health dashboard |
| Conceptual | 60 sec | Explain the 3-second rule |
| Debugging | 90 sec | Diagnose false-healthy dashboard |
| Trade-off | 60 sec | Heatmap vs time series for latency |
| Comparison | 60 sec | Health vs analysis dashboards |
| Production | 2 min | Describe a dashboard that saved an incident |
| Behavioral | 2-3 min | STAR story of building an effective dashboard |
| Architecture | 90 sec | Dashboard-as-code approach |
| Technical depth | 60 sec | Template variables and their benefits |

---

**Q1 [MID] Design a Grafana dashboard for a checkout service.**

*Why they ask:* Tests practical dashboard design ability.

*Likely follow-up:* How would you know the dashboard is effective?

For a checkout service dashboard, I design three rows. Row 1
(health, 3-second triage): a stat panel showing current error
rate with threshold at 1% (green below, red above), a stat panel
showing current p99 latency with threshold at 500ms (the SLO),
and a stat panel showing current request rate (to confirm traffic
is reaching the service). These three answer "is checkout healthy?"
in one look. Row 2 (trends, 1-hour window): a time series panel
showing error rate trend to identify when the problem started,
a time series panel showing p99 and p50 latency trends, and a
latency heatmap showing the full distribution to make slow
outliers visible. Row 3 (debugging): an inline Loki logs panel
showing ERROR-level logs filtered to checkout, a table showing
the top 5 slowest recent traces (from Tempo), and a bar chart
showing error count by error_type label. The dashboard has a
$service template variable to serve other services. I validate
effectiveness by running a game day: ask on-call engineers to
diagnose a simulated failure using only the dashboard, and time
how long it takes. Target: < 3 minutes to identify the failing
component.

*What separates good from great:* Great candidates describe the
Grafana Explore link in the logs panel that opens the Loki Explorer
pre-filtered to the same service and time range.

---

**Q2 [JUNIOR] What panel type should you use for p99 latency?**

*Why they ask:* Tests panel selection knowledge.

*Likely follow-up:* Why is a heatmap better than a time series for latency?

For p99 latency as a single line trend over time, use a time
series panel with the PromQL query `histogram_quantile(0.99, ...)`.
But if I can only have one latency panel, I prefer a heatmap over
a time series panel. A time series of p99 shows you the 99th
percentile value at each moment. A heatmap shows the full
latency distribution at each moment: how many requests were in
the 0-10ms bucket, 10-50ms bucket, 100ms-500ms bucket, etc.
The heatmap makes two things visible that the p99 time series
hides. First, bimodal distributions: if 80% of requests take
10ms and 10% take 600ms, the heatmap shows two distinct bands.
The p99 time series shows only 600ms but you cannot see that
80% of requests are fast. Second, distribution changes: if
latency becomes more uniform (tail compression), the heatmap
shows the distribution narrowing even if p99 does not change.
For most service dashboards, I include both: a heatmap for
distribution understanding and a time series for SLO comparison.

*What separates good from great:* Great candidates describe how
to configure a Grafana heatmap panel to use histogram data from
Prometheus: the "Calculate" mode that aggregates histogram_bucket
series into heatmap cell values.

---

**Q3 [SENIOR] How do you implement dashboard-as-code?**

*Why they ask:* Tests DevOps maturity for observability.

*Likely follow-up:* How do you handle schema drift between code and Grafana?

Dashboard-as-code means managing Grafana dashboards as version-
controlled configuration files rather than as manual UI edits.
Two approaches: Grafonnet (a Jsonnet library for generating Grafana
JSON) and the Grafana Terraform provider. With Grafonnet, dashboards
are Jsonnet files in the application repository, co-located with
the service code. Changes to dashboards go through code review
alongside code changes. The build pipeline renders Jsonnet to
Grafana JSON and applies it to Grafana via the Grafana API.
With the Terraform provider, dashboards are Terraform resources
in an infrastructure repository. The CI pipeline runs terraform apply
to synchronize dashboards. The key benefit of both approaches is
preventing dashboard drift: the dashboard in production always
matches what is in version control. The risk is schema drift in
the reverse direction: engineers making emergency edits in the
Grafana UI. I handle this with a Grafana flag `provisioned=true`
on dashboard folders, which prevents UI edits. Engineers must
submit code changes for any dashboard modification.

*What separates good from great:* Great candidates describe the
golden dashboard template pattern: a Grafonnet library that
generates a standard service dashboard for any service that
follows the metric naming convention, providing zero-effort
dashboards for all compliant services.

---

**Q4 [JUNIOR] What is a template variable in Grafana?**

*Why they ask:* Tests practical Grafana usage.

*Likely follow-up:* How do you create a service selector variable?

A template variable in Grafana is a dynamic parameter at the
top of a dashboard that can be changed by the viewer. Dashboard
panel queries reference the variable with a `$variableName`
syntax. When the viewer changes the variable value using the
dropdown at the top of the dashboard, all panels automatically
re-execute their queries with the new value. This allows one
dashboard to serve many dimensions: a $service variable lets
a single checkout service dashboard serve checkout, payment,
and inventory services without duplicating the dashboard. Common
variable types: query variables (populate choices from a data
source, e.g., list all service label values from Prometheus),
interval variables (time range aggregations: 1m, 5m, 15m),
constant variables (fixed values, e.g., SLO threshold). To create
a service selector: add a query variable with data source Prometheus,
query `label_values(http_requests_total, service)`. This populates
the dropdown with all service names that have at least one scrape.
Reference in panel queries: `{service="$service"}`.

*What separates good from great:* Great candidates describe the
multi-value variable feature: selecting multiple services in
one dashboard using regex matching `{service=~"$service"}`.

---

**Q5 [SENIOR] How do you share a dashboard across different teams with different services?**

*Why they ask:* Tests dashboard architecture thinking.

*Likely follow-up:* How do you handle teams with non-standard metric names?

The golden dashboard template pattern solves this. Define a
metric naming convention: every service exposes
`${service}_requests_total{status}` (counter) and
`${service}_duration_seconds` (histogram). Create a single
Grafana dashboard with a $service template variable. All
queries use `$service` as a metric name prefix. Engineers
select their service from the dropdown and get a pre-built
dashboard that works for their service because their service
follows the convention. For teams with non-standard metric
names (legacy services that predate the convention), two options:
first, create an adapter recording rule that maps their metric
names to the convention (`record: ${service}_requests_total
expr: old_metric_name`); second, create a team-specific override
dashboard that inherits the layout from the template but overrides
the query expressions. The first option is preferred because it
normalizes the data at the metrics layer, making all downstream
tooling (alerts, dashboards, runbooks) consistent.

*What separates good from great:* Great candidates describe how
to publish the golden dashboard template via a Grafana plugin
or shared library that teams import into their Grafana instances.

---

**Q6 [MID] What is the difference between a dashboard and an alert?**

*Why they ask:* Tests understanding of when to use each tool.

*Likely follow-up:* When would you use Grafana alerting instead of Prometheus alerting?

A dashboard is a human-initiated investigation tool: you open
it when you want to understand current or historical system
state. It requires someone to look at it. An alert is a system-
initiated notification: it fires when a condition is met,
notifies a human via PagerDuty or Slack, and does not require
anyone to be looking at the dashboard. The alert triggers the
investigation that may then use the dashboard. In terms of
tooling: Prometheus alerting rules (evaluated by Prometheus)
plus AlertManager (routing and notification) is the production-
grade alerting stack for Prometheus metrics. Grafana alerting
(evaluated by Grafana) is appropriate for non-Prometheus data
sources (Loki log-based alerts, Elasticsearch thresholds) or
for unified alerting across many data sources. I use Prometheus
alerting for all Prometheus-based alerts because: alert rules
are co-located with their metric definitions in PrometheusRule
CRDs, AlertManager provides sophisticated routing and
deduplication, and Prometheus recording rules can pre-compute
expensive alert expressions.

*What separates good from great:* Great candidates describe the
AlertManager inhibition feature: when a database-down alert
fires, suppress all alerts from services that depend on that
database to prevent an alert storm.

---

**Q7 [JUNIOR] What is a Grafana data source?**

*Why they ask:* Tests foundational Grafana architecture knowledge.

*Likely follow-up:* How do you correlate between data sources in one dashboard?

A Grafana data source is a configured connection to a backend
data store: Prometheus, Loki, Tempo, Elasticsearch, or any of
100+ supported backends. Each panel in a dashboard queries one
data source. The same dashboard can have panels querying multiple
data sources: a time series panel queries Prometheus for error
rate, a logs panel queries Loki for error logs, a trace panel
queries Tempo for recent traces. Correlation between data sources
is enabled by Grafana Explore links and Grafana Scenes. The most
important correlation is logs-to-traces: in a Loki logs panel,
configure a "Derived Field" that extracts the trace_id from each
log line and creates a clickable link that opens the corresponding
trace in Tempo. This is only possible when logs contain trace_id
as a named field (structured logging). The derived field
configuration: match on field `trace_id`, create a link
to `${__value.raw}` in the Tempo data source. When you click
the trace_id in a log line, Grafana opens the trace visualization
in Tempo directly.

*What separates good from great:* Great candidates describe the
Grafana Exemplars feature: Prometheus histograms can include
exemplar samples that reference a specific trace ID. Grafana
renders these as dots on time series panels that link to the
corresponding trace.

---

**Q8 [STAFF] How do you govern dashboard sprawl at scale?**

*Why they ask:* Tests organizational scale thinking.

*Likely follow-up:* How do you handle dashboards for services that no longer exist?

Dashboard sprawl - hundreds of outdated, duplicate, or unused
dashboards - is a common problem at scale. My governance approach
has three components. First, lifecycle tracking: every dashboard
has metadata tags (owner, service, created_date, last_modified).
A weekly job identifies dashboards with no views in 90 days.
The owner receives an email: "Your dashboard has been unused for
90 days. Archive it or update it." Second, canonical dashboards:
each service has exactly one canonical health dashboard (created
from the golden template) and one analysis dashboard. Any additional
dashboards require a justification in the dashboard description.
Third, automated cleanup: dashboards belonging to services that
no longer exist (detected by Kubernetes service inventory) are
automatically moved to an archive folder and their owners notified.
After 30 days in archive, they are deleted. The golden template
pattern reduces the total dashboard count because 80% of service
health questions are answered by the standard template.

*What separates good from great:* Great candidates describe how
Grafana's API enables automated dashboard auditing and the
specific Grafana API calls to list all dashboards with their
last view time.

---

**Q9 [SENIOR] How do you design dashboards for SLO burn rate alerts?**

*Why they ask:* Tests SLO-native dashboard design.

*Likely follow-up:* How does burn rate relate to error budget?

SLO burn rate dashboards visualize error budget consumption
rather than just current error rate. The key panels are:
first, the error budget gauge: current remaining error budget
as a percentage of the 30-day budget. A 99.9% availability SLO
has a 30-day error budget of 43.2 minutes. The gauge shows how
much of those 43.2 minutes has been consumed. Second, burn rate
time series: current burn rate vs target (1.0 = consuming exactly
at budget rate, > 1.0 = burning faster than budget replenishes).
The burn rate is: `error_rate / (1 - SLO_target)`. For a 99.9%
SLO, normal burn rate at 0.1% error rate is exactly 1.0.
At 1% error rate, burn rate is 10x. A 5x burn rate over 1 hour
consumes 5/720 = 0.7% of the 30-day budget. Third, projection:
at current burn rate, how many days until error budget is exhausted?
These three panels together answer the question engineers really
care about: "how urgent is this issue in terms of SLO impact?"
A 5x burn rate is serious; a 1.1x burn rate warrants investigation
but not a 2am page.

*What separates good from great:* Great candidates connect the
burn rate panels to the multi-window multi-burn-rate alerting
strategy (1h/6h windows for fast and slow detection).

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with the 3-second rule and health vs debugging layers |
| Hiring Manager | Lead with the business case: well-designed dashboards reduce MTTR by 50% |
| Bar Raiser | Lead with dashboard-as-code and golden template governance |
| Peer Engineer | Collaborative: "The heatmap is the panel that changed how I debug latency - here is how to configure it for Prometheus histograms" |

---

### 🏛️ System Design

*(Omit: L2 working keyword; system design covered in L4/L5 files.)*

---

### 📊 Diagram

*(Omit: the dashboard layer hierarchy is described clearly
in the ASCII structure in the Concept Explanation section above.)*
