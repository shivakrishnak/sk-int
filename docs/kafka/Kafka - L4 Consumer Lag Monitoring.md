---
layout: default
title: "Kafka - L4 Consumer Lag Monitoring"
parent: "Kafka"
nav_order: 12
permalink: /kafka/l4-consumer-lag-monitoring/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Kafka - L4 Consumer Lag Monitoring](#kafka---l4-consumer-lag-monitoring) | medium |

---

# Kafka - L4 Consumer Lag Monitoring

## Consumer Lag Monitoring

---

### 🎯 Model Answer

**30 seconds:**
> Consumer lag: the difference between the log end offset (LEO) of a partition and the consumer's
> committed offset. Lag = LEO - committed_offset. High lag: consumer is falling behind. Zero lag:
> consumer is caught up. Monitor with: `kafka-consumer-groups.sh`, JMX
> `records-lag-max`, Burrow, Kafka Exporter + Grafana. Alert: lag growing beyond SLA threshold.

**3 minutes (Senior):**
> Lag monitoring depth:
>
> 1. **Lag vs lag rate**: absolute lag (e.g., 50,000 records) may be acceptable if the consumer
>    is catching up (lag rate < 0). Lag growing at +1000 records/sec: consumer is falling behind
>    at that rate. Track both: absolute lag AND the rate of change.
> 2. **Time lag vs offset lag**: offset lag (50,000 records) is less actionable than time lag
>    (50 seconds of data). Convert: time_lag = offset_lag / producer_rate. A topic producing
>    100 records/sec: 50,000 records = ~500 seconds (8 minutes) behind. More intuitive SLA
>    threshold: "consumer must stay within 60 seconds of real-time."
> 3. **Consumer group health vs partition health**: a consumer group may have zero aggregate lag
>    but one partition with 100,000 lag (hidden by others at zero). Monitor lag PER PARTITION.
>    Alert: max partition lag, not average.
> 4. **Burrow**: LinkedIn's consumer lag monitoring system. Evaluates consumer group status
>    as OK, WARNING, ERROR, STOP, or STALLED based on a sliding window of lag observations.
>    Not just threshold: identifies lag trends (growing, shrinking, steady).
> 5. **Dead consumer** vs **slow consumer**: both show high lag. Dead: committed offset is not
>    moving. Slow: committed offset is moving but slower than producer. Different root causes,
>    different fixes.

**Blank Mind Recovery:**

**(1) Restate:** "Lag = LEO - committed_offset. Track: absolute lag + lag rate + time lag.
Monitor per partition (max lag). Tools: kafka-consumer-groups.sh, JMX, Burrow, Grafana.
Alert: growing lag. Dead consumer: offset not moving. Slow consumer: offset moving, just slow."

**(2) First principles:** "Kafka lag is the system's buffer queue depth. Low lag: consumer keeps
up with producers. High lag: consumers are the bottleneck or are stopped. Lag rate = how fast
the queue is growing. Time lag = business impact (how stale is my data?)."

**(3) Bridge:** "Consumer lag is like a post office mailbox fill level. Current mail volume:
producer rate. You check your mail rate: consumer rate. Full mailbox (high lag): you haven't
checked in a while. Mailbox filling faster than you read: lag growing. Burrow: not just current
fill level, but the trend over time."

---

### 📘 Concept Explanation

**Lag calculation, monitoring tools, and alerting strategy:**

{% raw %}
```plaintext
LAG CALCULATION:

  For each partition in a consumer group:
    Log End Offset (LEO): latest offset on the partition (from broker metadata).
    Committed Offset: consumer's last committed offset (from __consumer_offsets topic).
    Lag = LEO - Committed Offset.
  
  Total group lag = sum(lag across all partitions).
  Max partition lag = max(lag across all partitions).
  
  Example:
    Topic "orders", 4 partitions.
    P0: LEO=1000, committed=990  -> lag=10
    P1: LEO=1000, committed=1000 -> lag=0
    P2: LEO=1000, committed=500  -> lag=500  <- PROBLEM PARTITION
    P3: LEO=1000, committed=990  -> lag=10
    Total lag: 520. Max partition lag: 500.
    Alert: P2 lag is 500, growing. Root cause: consumer assigned to P2 is slow or down.

CONSUMER GROUP MONITORING COMMANDS:

  // Basic lag check:
  kafka-consumer-groups.sh \
    --bootstrap-server broker:9092 \
    --describe \
    --group order-processor
  
  // Output columns:
  TOPIC       PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG  CONSUMER-ID  HOST
  orders      0          990             1000            10   pod1-...     10.0.0.1
  orders      2          500             1000            500  pod3-...     10.0.0.3
  
  // Check all consumer groups:
  kafka-consumer-groups.sh --bootstrap-server broker:9092 --list
  kafka-consumer-groups.sh --bootstrap-server broker:9092 \
    --describe --group order-processor --verbose
  
  // Watch lag change over time (run twice, compare):
  kafka-consumer-groups.sh ... --describe --group order-processor > before.txt
  sleep 60
  kafka-consumer-groups.sh ... --describe --group order-processor > after.txt
  diff before.txt after.txt  # check if CURRENT-OFFSET is advancing

JMX METRICS FOR LAG:

  Consumer (kafka.consumer):
    records-lag-max: max lag across all partitions for this consumer instance.
      Alert threshold: > 10,000 (tune per topic/SLA).
    records-lag-avg: avg lag (less useful than max for alerting).
    records-lag: per-partition lag (labelized by topic+partition).
    records-consumed-rate: consumption rate (records/sec).
    bytes-consumed-rate: bytes/sec consumed.
    fetch-rate: fetches/sec.
  
  Broker (kafka.server):
    FetchRequestsPerSec: fetch requests to this broker.
    ConsumerLag (per group+partition): exposed if configured.

BURROW (LAG EVALUATION):

  Burrow evaluates consumer group status using a sliding window:
    Window: last N offsets for each partition.
    Rules:
      STOP: consumer committed same offset N consecutive times = consumer is frozen.
      STALLED: consumer is committing but lag is not decreasing.
      WARNING: lag is growing (consumer slower than producer).
      OK: lag is stable or decreasing.
      ERROR: consumer is not active (no recent commits).
  
  Advantage over simple threshold: detects TRENDS not just snapshots.
    A threshold alert fires at lag=10,000 even if the consumer just had a brief pause
    and is now catching up (false positive).
    Burrow: if lag is decreasing, status = OK (no alert). Cleaner alerting.

PROMETHEUS + GRAFANA SETUP:

  Kafka Exporter (by danielqsj or Bitnami):
    Scrapes Kafka broker JMX and consumer group offsets.
    Exposes as Prometheus metrics:
      kafka_consumer_group_current_offset{topic, partition, consumergroup}
      kafka_consumer_group_lag{topic, partition, consumergroup}
      kafka_topic_partition_current_offset{topic, partition}
  
  Alert rules:
    # Growing lag alert:
    - alert: KafkaConsumerLagGrowing
      expr: |
        increase(kafka_consumer_group_lag[5m]) > 0
        and kafka_consumer_group_lag > 1000
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Consumer lag growing for group {{ $labels.consumergroup }}"
        description: "Partition {{ $labels.partition }} lag: {{ $value }}"
    
    # High absolute lag:
    - alert: KafkaConsumerHighLag
      expr: kafka_consumer_group_lag > 50000
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Consumer lag critically high"

LAG TO TIME CONVERSION:

  Compute: time_lag_seconds = lag / producer_records_per_second
  
  producer_rate = kafka_topic_partition_current_offset increase over 60s / 60
  time_lag = kafka_consumer_group_lag / producer_rate
  
  Example:
    P2 lag = 500 records. Producer rate for P2 = 50 records/sec.
    Time lag = 500 / 50 = 10 seconds.
    SLA: consumer must be within 60 seconds. OK.
  
  But:
    P2 lag = 50,000 records. Producer rate = 50 records/sec.
    Time lag = 50,000 / 50 = 1000 seconds (16+ minutes behind). ALERT.
```
{% endraw %}

> **Code walkthrough:** This High absolute lag: example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** The AdminClient-based lag checker gives programmatic access to consumer
> group lag for custom monitoring, health checks, and backpressure control.

```java
// WRONG: relying only on application-level metrics for consumer health:
@GetMapping("/health")
public ResponseEntity<String> health() {
    // Only checks if the application is running, not if it is keeping up:
    return ResponseEntity.ok("UP");
    // Consumer could be stuck at lag=500,000 and health returns "UP".
}

// RIGHT: programmatic lag check using AdminClient:
@Component
public class ConsumerLagMonitor {
    
    private final AdminClient adminClient;
    private final String groupId;
    private static final long MAX_ACCEPTABLE_LAG = 10_000L;
    
    public ConsumerLagReport getLagReport() throws Exception {
        // Step 1: get committed offsets for this consumer group:
        Map<TopicPartition, OffsetAndMetadata> committed =
            adminClient.listConsumerGroupOffsets(groupId)
                .partitionsToOffsetAndMetadata()
                .get();
        
        if (committed.isEmpty()) {
            return ConsumerLagReport.empty("No committed offsets found for group " + groupId);
        }
        
        // Step 2: get log end offsets for those partitions:
        Map<TopicPartition, OffsetSpec> specs = committed.keySet().stream()
            .collect(Collectors.toMap(tp -> tp, tp -> OffsetSpec.latest()));
        
        Map<TopicPartition, ListOffsetsResult.ListOffsetsResultInfo> endOffsets =
            adminClient.listOffsets(specs).all().get();
        
        // Step 3: compute lag per partition:
        Map<TopicPartition, Long> lagPerPartition = new HashMap<>();
        long totalLag = 0;
        long maxLag = 0;
        TopicPartition maxLagPartition = null;
        
        for (Map.Entry<TopicPartition, OffsetAndMetadata> entry : committed.entrySet()) {
            TopicPartition tp = entry.getKey();
            long committedOffset = entry.getValue().offset();
            long endOffset = endOffsets.get(tp).offset();
            long lag = endOffset - committedOffset;
            
            lagPerPartition.put(tp, lag);
            totalLag += lag;
            
            if (lag > maxLag) {
                maxLag = lag;
                maxLagPartition = tp;
            }
        }
        
        boolean healthy = maxLag <= MAX_ACCEPTABLE_LAG;
        return new ConsumerLagReport(totalLag, maxLag, maxLagPartition, lagPerPartition, healthy);
    }
    
    @GetMapping("/health/consumer-lag")
    public ResponseEntity<ConsumerLagReport> healthCheck() throws Exception {
        ConsumerLagReport report = getLagReport();
        HttpStatus status = report.isHealthy() ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE;
        return ResponseEntity.status(status).body(report);
    }
}
```

> **Code walkthrough:** The monitor uses two AdminClient calls: `listConsumerGroupOffsets` to
> get committed offsets, and `listOffsets` with `OffsetSpec.latest()` to get the current log
> end offset for each partition. Lag = end - committed. The health endpoint returns HTTP 200
> if max partition lag is within the acceptable threshold, HTTP 503 otherwise. This enables
> Kubernetes liveness/readiness probes and load balancer health checks that account for Kafka
> consumer lag, not just JVM uptime. A consumer stuck with high lag fails this health check
> and can be automatically restarted.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Consumer lag = LEO - committed offset. Check with `kafka-consumer-groups.sh --describe --group`.
> Monitor JMX `records-lag-max`. Alert: lag growing. Root causes: slow consumer, dead consumer,
> processing bottleneck. Fix: add consumer instances (up to partition count) or optimize
> processing.

---

**Senior / Staff (5+ years):**
> The lag metric alone is insufficient. You need lag rate (is it growing?), time lag (business
> impact), and per-partition lag (which partition is the problem?). Burrow adds trend analysis:
> avoids false alarms when consumer briefly pauses and catches up. For SLA-based alerting:
> convert offset lag to time lag (lag / producer rate). "We are 60 seconds behind" is more
> actionable than "we have 3000 records of lag". Monitor: the correlation between producer rate
> spikes and lag spikes. A traffic spike that resolves in <5 minutes: normal. Sustained lag
> growth after a spike: consumer is permanently behind (needs scaling).

---

### ⚠️ Common Misconceptions

**Misconception: "Lag of zero means the consumer is healthy."**
Lag zero means the consumer's committed offset equals the log end offset at the time of the
check. It does NOT mean the consumer is processing records in a timely manner. Scenarios where
lag is zero but the consumer is "unhealthy": (1) The topic receives very few records (1 per
minute). Lag is zero simply because the consumer commits within that minute. But if the consumer
is processing records 55 seconds after they arrive: the time lag is 55 seconds. (2) The consumer
is consuming and committing very quickly, but the downstream system (the database or API) is
silently failing. Lag zero, but records are being dropped. (3) The consumer is in a loop
committing without actually processing (auto-commit with an exception handler that swallows
exceptions). Lag zero because offsets are advancing, but no business processing occurs. True
consumer health monitoring requires: lag + processing latency metrics (end-to-end latency from
produce time to process time using record timestamp) + error rate + downstream health.

---

### ⚖️ Comparison Table

| Tool | What It Measures | Trend Analysis | Production Use |
|---|---|---|---|
| kafka-consumer-groups.sh | Offset lag snapshot | No (manual) | Debugging |
| JMX records-lag-max | Max lag per consumer | No (time series via JMX) | Dashboards |
| Burrow | Group health (sliding window) | Yes | Alerting |
| Kafka Exporter + Prometheus | Offset lag, rates | Yes | Dashboards + Alerting |
| Custom AdminClient | Per-partition lag (programmatic) | Custom | Health endpoints |

---

### 🏛️ System Design

**Consumer lag monitoring architecture:**

```
  KAFKA CLUSTER                 MONITORING STACK
  ┌─────────────────┐          ┌────────────────────┐
  │ Brokers (3)     │          │ Kafka Exporter     │
  │ __consumer_offs ├─────────>│ (Prometheus scrape)│
  │ partition LEOs  │          └─────────┬──────────┘
  └─────────────────┘                    │
                                         v
                               ┌─────────────────────┐
                               │  Prometheus          │
                               │  (15s scrape)        │
                               │  lag metrics         │
                               └─────────┬───────────┘
                                         │
                               ┌─────────v───────────┐
                               │  Grafana Dashboard  │
                               │  + Alertmanager     │
                               └─────────────────────┘
  
  Alerts:
    - lag growing for 5+ minutes -> WARNING
    - lag > 50,000 records -> CRITICAL
    - committed offset frozen (STALLED) -> CRITICAL
```

> **Code walkthrough:** This High absolute lag: example demonstrates a key conceice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 📊 Diagram

**Lag measurement components:**

```
  PARTITION P2:
  
  Offset: 0  100  200  300  400  500  [producer here]
                                       ^
                                       LEO = 500
  
  Consumer committed:   0   100   200  300
                                        ^
                                        committed_offset = 300
  
  LAG = LEO - committed = 500 - 300 = 200 records
  
  Time lag (producer rate = 50 records/s):
    200 / 50 = 4 seconds behind.
    SLA = 60 seconds: OK.
```

```mermaid
xychart-beta
    title "Consumer Lag Over Time (P2)"
    x-axis [10:00, 10:05, 10:10, 10:15, 10:20, 10:25, 10:30]
    y-axis "Lag (records)" 0 --> 50000
    line [200, 1500, 5000, 15000, 40000, 30000, 5000]
```

> **Diagram walkthrough:** The chart shows a realistic lag event pattern. From 10:00 to 10:20:
> lag grows exponentially (a traffic spike exceeds consumer capacity). At 10:20: the operations
> team scaled consumer instances from 4 to 8. From 10:20 to 10:30: lag shrinks as the expanded
> consumer group catches up. The alert fires at ~10:10 (lag threshold crossed). The recovery
> completes at ~10:30. The key insight: lag is a time-series metric. A single snapshot is
> insufficient. The trend (growing, stable, shrinking) determines urgency. Burrow's sliding
> window algorithm captures this trend.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Consumer group STALLED - offset not advancing despite active consumers.**
```plaintext
Symptom: kafka-consumer-groups.sh shows consumers assigned to partitions.
  CURRENT-OFFSET: same value in repeated checks (not advancing).
  LAG: growing. Consumers: appear healthy (no pod crashes).
  
  Burrow status: STALLED.

Root cause analysis:
  1. Consumer is polling and auto-committing, but processing is failing silently.
     Exception handler swallows exceptions without committing offset properly.
     Check: application error logs. Grep for "Exception" in consumer logs.
  
  2. manual commitSync is never reached (exception before commit):
     Consumer polls records -> processes -> exception -> loop.
     No commit. CURRENT-OFFSET frozen.
     Check: consumer code for exception paths that skip commitSync.
  
  3. Consumer blocked on downstream system (DB, HTTP):
     Consumer polls, blocks waiting for response.
     max.poll.interval.ms exceeded. Consumer leaves group.
     New rebalance -> consumer re-joins -> same partition -> same block.
     Cycle: consumer joins, processes first record (blocks), leaves, rejoins.
     Offset: never committed.
  
  4. Transaction hung (read_committed consumer + hanging transaction):
     LSO not advancing. Consumer stuck at LSO.
     Check: kafka-transactions.sh --list for open transactions.

Diagnosis steps:
  Step 1: check CURRENT-OFFSET movement over 5 minutes.
    If frozen: committed offset not advancing.
  Step 2: check if consumer is active (CONSUMER-ID in output):
    Active: consumer is connected but not committing.
    Empty: consumer is not connected. Dead.
  Step 3: review consumer application logs:
    Exception patterns: look for repeated exceptions.
    "max.poll.interval.ms exceeded": consumer leaving group due to slow processing.
  Step 4: check downstream health (DB, API endpoint).
  Step 5: check for open transactions (if isolation.level=read_committed).

Fix:
  Uncaught exception in processing: add error handling with DLQ (route bad records to DLT).
  Slow downstream: add timeouts, circuit breakers, or process async.
  Transaction hung: kafka-transactions.sh --abort for the hung transaction.
  Dead consumer: resolve crash cause, restart pod.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Lag definition and calculation | 1 minute |
| Time lag vs offset lag | 2 minutes |
| Per-partition vs total lag | 1 minute |
| Monitoring tools comparison | 2 minutes |
| Burrow evaluation algorithm | 2 minutes |
| Dead vs slow consumer diagnosis | 2 minutes |
| Stalled consumer diagnosis | 2 minutes |
| Alerting strategy | 2 minutes |
| Lag to time conversion | 1 minute |
| AdminClient-based monitoring | 2 minutes |
| read_committed consumer lag | 1 minute |
| At-scale lag management | 2 minutes |

---

**Q1 (mechanism): How do you calculate consumer lag, and what are the meaningful ways to measure it?**

A: Consumer lag = (partition's log end offset) - (consumer group's committed offset for that
partition). For each partition in the group: fetch the committed offset from `__consumer_offsets`
and the current LEO from the partition leader. Difference = lag. Three meaningful ways to measure:
(1) Offset lag: the raw count of unprocessed records. Actionable for: capacity planning (how
many records to process to catch up). Less intuitive for business SLAs. (2) Time lag: offset
lag / producer rate (records per second). Example: 10,000 records behind / 100 records per
second = 100 seconds of lag. SLA "consumer must process data within 60 seconds of production"
is directly checkable. Producer rate: computed from LEO change over time.
(3) Consumer throughput vs producer throughput: if consumer rate > producer rate: catching up
(lag decreasing). If consumer rate < producer rate: falling behind (lag increasing). The rate
of change is more important than the absolute value for alerting. Track all three: offset lag
for dashboards, time lag for SLA reporting, rate comparison for trend alerting. Per-partition
monitoring is critical: aggregate lag may hide a single problem partition. Always alert on
max partition lag, not average or total.

*What separates good from great:* The `fetch.lag` vs `records-lag` distinction. `records-lag`
(JMX) is the lag between the consumer's last fetched offset and the LEO. This includes records
fetched but not yet processed (in the consumer's buffer). `records-lag` can be zero even if the
consumer is processing records slowly (they are fetched but not committed). For accurate lag
measurement of processing progress: use `kafka-consumer-groups.sh` which reads committed offsets
(not fetch progress). The committed offset represents actual processing completion. For Kafka
Streams: `kafka.streams.processor.thread` JMX metrics expose both records-lag and processing
latency. `process-latency-avg` = average time from record consumption to state store write.
This is the most accurate measure of Kafka Streams processing health.

---

**Q2 (architecture): Design a consumer lag alerting system for a production Kafka cluster with 50 consumer groups.**

A: For 50 consumer groups, a custom alerting system needs to scale and avoid alert fatigue.
Architecture: (1) Metrics collection: deploy Kafka Exporter (or Confluent's kafka-lag-exporter)
as a sidecar or separate deployment. Scrapes `__consumer_offsets` and broker LEO every 30-60s.
Exposes Prometheus metrics: `kafka_consumer_group_lag{group, topic, partition}`. (2) Prometheus:
record time series. Retention: 30 days. (3) Alert rules: avoid threshold-only alerts. Rules:
`increase(kafka_consumer_group_lag[5m]) > 0 AND kafka_consumer_group_lag > threshold` (growing
AND above threshold). This prevents alerts for brief pauses that self-resolve. Thresholds by
topic tier: critical topics (payments, orders): alert at 10,000 records or 30 seconds time lag.
Non-critical (analytics, metrics): alert at 500,000 records or 30 minutes. (4) Per-group health
aggregation: one alert per consumer group, not per partition. Group-level alert: shows max
partition lag within the group. Route: PagerDuty for critical topics (business hours and off-hours).
Slack for non-critical (business hours only). (5) Dashboard: Grafana with one panel per consumer
group (lag over time, with producer rate overlay). Enables: is the lag growing because producer
spiked (transient) or because consumer slowed (persistent)?

*What separates good from great:* The SLO-based alerting approach. Instead of "lag > X records":
define a per-topic SLO of "consumer must process records within Y seconds of production." Monitor
`time_lag = lag / producer_rate`. Alert when time_lag > SLO_threshold for > 5 minutes. This
is both more meaningful and more stable than offset-based thresholds. Throughput fluctuations
(e.g., topic goes from 100/s to 50/s on a weekend): offset-based threshold stays constant but
SLO threshold self-adjusts (lower producer rate = acceptable higher offset lag). Build a runbook
per consumer group: for each alert, pre-document the diagnosis steps, known causes, and resolution
paths. This reduces MTTR dramatically and enables on-call engineers who are unfamiliar with the
specific consumer to resolve incidents faster.

---

**Q3 (debugging): A consumer group's lag has been at 500,000 records for 2 hours. What do you investigate?**

A: Persistent high lag without growth or recovery is the "STALLED" state in Burrow's terminology.
Step 1: check if the consumer's committed offset is advancing:
`kafka-consumer-groups.sh --describe --group <group>`. Run twice, 60 seconds apart. Compare
CURRENT-OFFSET columns. If frozen: consumer is not committing (dead, stalled, or hanging).
If advancing (but slower than LEO advances): consumer is alive but slower than the producer.
Case A: offset frozen. Sub-cases: (a) Consumer is dead (no CONSUMER-ID in output). Check: pod
status, OOM kill, crash. Restart the consumer. (b) Consumer is active but exception before
commit. Check: consumer application logs. Look for repeated exceptions. Fix: DLQ for bad records,
fix the processing exception. (c) Downstream system unavailable. Consumer processes but cannot
write to DB/API. Check: downstream health. Fix: repair downstream, add circuit breaker.
Case B: offset advancing but lag stable at 500,000. Consumer throughput = producer throughput.
Consumer caught up to a stable lag (arrived at steady state). To reduce lag: scale consumers.
`kafka-consumer-groups.sh` shows CONSUMER-ID -> host mapping. Count active consumers.
If consumers < partitions: scale up. If consumers = partitions and still lagging: each consumer
is maxed out. Options: optimize processing (async, batch DB writes), increase processing
parallelism per consumer (worker threads), or increase partition count (requires topic migration).
Also check: is the lag 500k records everywhere or just one partition? A single slow partition
is a hotspot issue (bad key distribution).

*What separates good from great:* The `last.commit.time` field (Burrow provides this, not
the CLI directly). If the last commit was 2 hours ago: the consumer has been dead for 2 hours
(matches the lag duration). If the last commit was 5 minutes ago: consumer was working but
recently stopped. Very different debugging paths. For the CLI: run `kafka-consumer-groups.sh`
twice with a 60-second gap. If CURRENT-OFFSET moves in the second run: consumer is alive.
If not: consumer committed once (2 hours ago) and stopped. Also: check the max.poll.interval.ms
setting. If the consumer crashes due to processing timeout and the group is large (many consumers):
the rebalance may distribute the problem partition to another consumer that also times out.
A "hot potato" partition - no consumer can process it because all have slow processing. The
partition cycles through consumers, each timing out. Lag grows continuously despite many
active consumers.

---

**Q4 (production): How do you reduce consumer lag during a traffic spike?**

A: A traffic spike causes lag when producer rate temporarily exceeds consumer capacity. Response
strategy: (1) Immediate: if partition count > current consumer count, scale out consumers
immediately. Cloud environments: auto-scaling consumer pods based on `records-lag-max` metric
(KEDA - Kubernetes Event-driven Autoscaling supports Kafka lag as a trigger). Rule: scale up
if max lag > 10,000 for 3 minutes. Scale down if max lag < 1,000 for 10 minutes. (2) Short-term
(existing consumer count = partition count): increase processing efficiency. If processing
includes HTTP calls: use async HTTP client (WebClient, CompletableFuture). If DB writes: batch
inserts (JDBC batch, JPA saveAll). Reduce per-record overhead: minimize logging, avoid per-record
lock contention. (3) Medium-term: if the spike is predictable (e.g., end-of-day batch or daily
traffic peak): pre-scale before the spike. Scheduled scaling: add consumers 5 minutes before
expected spike time. (4) Circuit breaker: if the consumer's downstream is slow (causing the
lag): apply backpressure. Pause consuming (`consumer.pause(partitions)`) when downstream latency
exceeds threshold. Resume when it recovers. This prevents the consumer from accumulating more
work it cannot process. (5) Long-term: if spikes are frequent: re-evaluate partition count.
More partitions = higher maximum consumer parallelism. Migration: create new topic with more
partitions, redirect producers, migrate consumers.

*What separates good from great:* KEDA (Kubernetes Event-driven Autoscaling) is the production
solution for Kafka-driven consumer autoscaling. KEDA's `kafkaTopic` scaler monitors consumer
group lag and scales the Kubernetes Deployment (consumer pods) accordingly. Configuration:
`lagThreshold=1000` (scale up when lag > 1000 per consumer instance). KEDA evaluates:
`desired_replicas = ceil(total_lag / lagThreshold)`. At 100,000 lag: desired = 100. Capped
at `maxReplicaCount` (often partition count). The lag threshold is per consumer instance, not
total. This creates a proportional controller: more lag = more consumers. KEDA cooldown period
(typically 60-120s before scale-down) prevents oscillation. Combined with CooperativeStickyAssignor
(minimal rebalance impact when adding/removing consumers): KEDA + cooperative rebalance is the
production-standard auto-scaling pattern for Kafka consumers.

---

**Q5 (architecture): How does consumer lag monitoring differ for Kafka Streams applications?**

A: Kafka Streams applications differ from plain consumers in several ways that affect lag monitoring.
(1) The Kafka Streams application processes records from input topics and produces to output
topics. Lag on the INPUT topic: same as any consumer group lag. Monitor: the consumer group ID
of the Streams application (`application.id` property, which is the group ID). (2) Kafka Streams
also has STATE LAG: the restore consumer that rebuilds state stores from changelog topics. During
startup or after a crash: the restore consumer reads from the beginning of the changelog topic.
Lag on the changelog topic restoration: `kafka.streams.state.*: restore-consumer-records-lag`.
High restore lag: Kafka Streams startup is slow (state store recovery in progress). Service is
not ready to process until restore completes. Monitor: `rebalance-latency` and `restore-consumer`
lag for Streams health. (3) Kafka Streams processing latency metrics: `process-latency-avg` and
`process-rate`: how fast records are processed through the stream topology. High process-latency-avg
with low input topic lag: processing is keeping up but slowly (each record takes longer to process).
(4) Thread metrics: `kafka.streams.processor.thread`: `poll-records-avg`, `process-records-avg`.
Multi-threaded Streams (`num.stream.threads`): per-thread metrics. Combine with input topic lag
for complete health picture. Alert recommendations: input topic lag (standard Kafka lag alert) +
restore consumer lag (alert if startup lag > 5 minutes) + process-latency-avg (alert if > SLA).

*What separates good from great:* The `num.standby.replicas` configuration for Kafka Streams.
Standby replicas are pre-warmed copies of the state store on other instances. When the active
instance fails: a standby instance takes over with minimal restore lag (only recent records,
not the full history). For stateful Kafka Streams applications with large state stores: setting
`num.standby.replicas=1` dramatically reduces failover time (from minutes to seconds). The
trade-off: each standby replica consumes memory (for the RocksDB state store) and changelog
read throughput. For applications where availability SLA requires < 30 second recovery: standby
replicas are essential. For applications where minutes of unavailability are acceptable: skip
standby replicas to reduce memory and replication overhead.

---

**Q6 (production): How do you handle consumer groups that need to reset offsets to reprocess data?**

A: Offset reset is needed when: a bug was fixed and records need to be reprocessed, a new
consumer group needs to read from the beginning, or a consumer group was deleted and needs to
restart. Procedure: (1) Stop the consumer group (all consumers must be inactive before reset):
`kafka-consumer-groups.sh --describe --group my-group` -> verify all consumers are inactive
(no CONSUMER-ID in output). If still active: stop all consumer pods. (2) Reset offsets:
`kafka-consumer-groups.sh --bootstrap-server broker:9092 --group my-group --reset-offsets
--to-earliest --topic orders --execute`. Options: `--to-earliest` (beginning), `--to-latest`
(skip all lag), `--to-datetime <timestamp>` (specific time), `--by-duration PT6H` (6 hours ago),
`--to-offset <offset>` (specific offset). (3) Verify the reset:
`kafka-consumer-groups.sh --describe --group my-group` -> CURRENT-OFFSET should show new value.
(4) Restart consumers. They will start from the reset offset. Caution: re-processing sends
records to downstream systems (DB, APIs) again. Ensure downstream is idempotent or apply a
re-processing flag to skip double-writes. For partial reprocessing (only from a specific time):
`--to-datetime` is the most useful. ISO 8601 format: `2024-01-15T10:00:00.000`.

*What separates good from great:* The `--dry-run` flag. Always preview the reset before executing:
`--reset-offsets --to-earliest --topic orders --dry-run`. This shows what the new offsets will
be without applying them. Verify: does the reset cover the intended time range? How many records
will be reprocessed? For large-scale reprocessing (billions of records): estimate time-to-complete
before executing (total records / consumer throughput). If reprocessing will take days: consider
a separate consumer group (not resetting the production group). Process old records in a separate
group (shadow mode), compare outputs to new records processed by the production group. Once
verified: cut over the production group. This approach: zero downtime reprocessing. The
production group continues processing new records at the HEAD of the topic. The shadow group
processes historical records in parallel, without affecting the production SLA.

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




