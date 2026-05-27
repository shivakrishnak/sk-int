---
layout: default
title: "Messaging - L4 Production Depth"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 7
permalink: /messaging/l4-production-depth/
---

# Kafka Performance Tuning

🎯 Interview Weight: very high - Kafka performance tuning is
a production engineering skill tested at senior+ level.

---

### 🎯 Model Answer

**30 seconds:**
> Kafka performance levers: producer - `linger.ms`, `batch.size`,
> `compression.type`, `buffer.memory`. Consumer - `fetch.min.bytes`,
> `max.poll.records`, `fetch.max.wait.ms`. Broker - `num.io.threads`,
> `log.dirs` (spread across SSDs), `log.segment.bytes`,
> `replica.fetch.max.bytes`. OS - page cache (large RAM),
> network buffers, filesystem (`ext4` with `noatime`).

**3 minutes (Senior):**
> Performance tuning by bottleneck:
>
> Producer throughput bottleneck:
> Symptom: producer throughput lower than broker capacity.
> Fix 1: increase `linger.ms` (1-50ms) to build larger batches.
> Fix 2: increase `batch.size` (64KB - 1MB).
> Fix 3: enable `compression.type=snappy` or `lz4`.
>   Smaller network payload = higher throughput.
>   lz4 > snappy in throughput; gzip = best compression ratio.
> Fix 4: increase `buffer.memory` (32MB -> 128MB) to buffer more
>   in-flight batches without blocking.
>
> Consumer throughput bottleneck:
> Symptom: consumer lag growing, high fetch latency.
> Fix 1: increase `max.poll.records` (500 -> 1000). Process more
>   per poll loop iteration.
> Fix 2: increase `fetch.min.bytes` (1 -> 100KB). Fetch larger
>   batches from broker when available.
> Fix 3: increase consumer parallelism - add more partitions
>   + increase `concurrency` in Spring Kafka listener.
> Fix 4: optimize processing - profile the consumer code.
>   DB batch writes instead of single row inserts per message.
>
> Broker I/O bottleneck:
> Symptom: broker CPU high, disk I/O high.
> Fix 1: spread log directories across multiple SSDs.
>   `log.dirs=/disk1/kafka,/disk2/kafka,/disk3/kafka`.
>   Kafka stripes partitions across log dirs.
> Fix 2: NVMe SSDs (100K+ IOPS) vs spinning disks (150 IOPS).
> Fix 3: tune OS page cache. Kafka relies heavily on OS file
>   caching. Heap size small (6GB), rest of 32GB = page cache.
>
> Replication throughput:
> `replica.fetch.max.bytes=10MB`: max bytes fetched by replica
> from leader per request. Increase for high-throughput topics.
> `num.replica.fetchers=4`: increase parallel replication threads.

**Blank Mind Recovery:**

**(1) Restate:** "Kafka performance: producer batching + compression.
Consumer parallelism + fetch tuning. Broker: NVMe SSDs + page cache."

---

### 💻 Code Example

```properties
# Producer - high-throughput configuration
bootstrap.servers=kafka:9092
acks=all
enable.idempotence=true

# Batching: accumulate for up to 20ms or 256KB
linger.ms=20
batch.size=262144

# Compression: lz4 is fast, good ratio
compression.type=lz4

# Large in-memory buffer for batching
buffer.memory=134217728

# Consumer - high-throughput configuration
group.id=analytics-service
enable.auto.commit=false
auto.offset.reset=earliest

# Fetch 500KB minimum before returning (larger batches)
fetch.min.bytes=524288
fetch.max.wait.ms=500

# Process 1000 records per poll loop iteration
max.poll.records=1000

# 5 min processing budget for 1000 records
max.poll.interval.ms=300000

# Key/value deserializers
key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
value.deserializer=io.confluent.kafka.serializers.KafkaAvroDeserializer
```

> **Code walkthrough:** Producer configuration trades 20ms
> latency for batching (linger.ms=20). Batches up to 256KB
> are compressed with lz4 before sending - reducing network
> I/O by 50-70%. The 128MB buffer allows the producer to
> continue accumulating batches while broker I/O catches up.
> Consumer fetches at least 512KB per request (not one message
> at a time) and processes 1000 records per poll loop - enabling
> bulk DB writes and amortizing commit overhead.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Producer batching + consumer parallelism |
| Staff | 10 min | Broker I/O + OS page cache + replication tuning |

---

---

# Consumer Lag Diagnosis and Resolution

🎯 Interview Weight: very high - Consumer lag is the primary
Kafka production health metric.

---

### 🎯 Model Answer

**30 seconds:**
> Consumer lag = number of messages produced but not yet consumed
> (difference between latest offset and consumer committed offset).
> High lag means consumers are falling behind producers. Root
> causes: insufficient consumer parallelism, slow processing,
> producer throughput spike. Diagnosis: `kafka-consumer-groups.sh
> --describe --group <group>` shows lag per partition. Alert when
> lag exceeds SLA threshold (e.g., > 10,000 messages).

**3 minutes (Senior):**
> Consumer lag diagnosis:
>
> Check lag per consumer group:
> ```bash
> kafka-consumer-groups.sh \
>   --bootstrap-server kafka:9092 \
>   --describe --group payment-service
> # Shows: TOPIC, PARTITION, CURRENT-OFFSET, LOG-END-OFFSET, LAG
> # LAG = LOG-END-OFFSET - CURRENT-OFFSET
> ```
>
> Interpret lag patterns:
> Lag growing uniformly across all partitions:
> -> Consumer throughput < producer throughput.
> -> Fix: add more partitions + consumer instances.
> Lag concentrated on specific partitions:
> -> One consumer instance is slower (hot partition).
> -> Check which consumer instance has the hot partition.
> -> Is that instance GC-pausing or under CPU/memory pressure?
> Lag spikes then recovers:
> -> Periodic producer burst (batch processing upstream).
> -> Consumers catch up during low-traffic periods. Acceptable
>    if within SLA.
> Lag at 0 for some partitions, high for others:
> -> Partition skew (one key dominates). All messages for that
>    key go to one partition, one consumer handles all load.
>
> Resolution by root cause:
> Insufficient parallelism: add partitions (requires consumer
> rebalance) + add consumer instances.
> Slow processing: profile consumer code. Batch DB writes.
> GC pressure: tune JVM heap. Reduce GC pause frequency.
> Downstream dependency slow: async processing, increase
> timeout, or decouple with internal queue.
>
> Alerting:
> Prometheus `kafka_consumer_group_lag` metric.
> Alert: lag > 10K for 5 minutes -> PagerDuty.
> Alert: lag growing rate > 1K/minute -> warning.

**Blank Mind Recovery:**

**(1) Restate:** "Lag = unconsumed messages. Diagnose: which partitions?
Growing or spiking? Fix: more consumers, faster processing, partition rebalance."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Lag concept + kafka-consumer-groups command |
| Senior | 8 min | Lag patterns + root cause analysis + alerting |

---

---

# Message Loss Prevention Strategies

🎯 Interview Weight: very high - Silent message loss is the
worst messaging failure mode. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Message loss in Kafka: producer fails to send (no retry, no acks),
> broker leader fails before replication (acks=1), consumer commits
> offset before processing (auto-commit), or network partition causes
> data loss on the producer buffer. Prevention: `acks=all` + retries
> + idempotence on producer, `enable.auto.commit=false` + manual
> commit after processing on consumer, min.insync.replicas=2 on broker.

**3 minutes (Senior):**
> Message loss scenarios and prevention:
>
> Scenario 1 - Producer buffer loss:
> Network partition while producer is buffering. Buffer fills up.
> `max.block.ms` expires -> exception. Messages are dropped if
> producer doesn't handle the exception.
> Prevention: handle producer send exceptions, log failed sends
> to a fallback (local DB or S3). Retry strategy with exponential
> backoff.
>
> Scenario 2 - Leader failure before replication (acks=1):
> Producer sends with `acks=1`. Leader acknowledges.
> Leader dies before follower replicates.
> New leader (previously a follower) does not have this message.
> Message is lost.
> Prevention: `acks=all` + `min.insync.replicas=2`. Message
> acknowledged only after 2 ISR replicas have it.
>
> Scenario 3 - Consumer auto-commit before processing:
> Kafka auto-commits offsets every 5 seconds.
> Consumer receives 1000 messages at T=0.
> Processes 200, crashes at T=3s.
> Auto-commit fires at T=5s (or did fire at T=0 on the previous cycle).
> On restart: messages 201-1000 are not reprocessed (offset committed).
> Prevention: `enable.auto.commit=false`. Manual commit AFTER processing.
>
> Scenario 4 - Unclean leader election:
> If a non-ISR replica is elected leader (when ISR is empty):
> it may be behind by many messages. Those messages are lost.
> Prevention: `unclean.leader.election.enable=false`.
> This prefers availability loss (no leader elected) over
> data loss. Better to have a brief outage than silent data loss.

**Blank Mind Recovery:**

**(1) Restate:** "Prevent loss: acks=all + min.insync=2 + no auto-commit
+ unclean.leader.election=false. Never silently drop messages."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Producer acks + consumer commit timing |
| Staff | 10 min | Unclean leader election + ISR + buffer loss recovery |

---

---

# Messaging Anti-Patterns

🎯 Interview Weight: high - Anti-patterns distinguish senior
engineers from mid-level.

---

### 🎯 Model Answer

**30 seconds:**
> Top messaging anti-patterns: Large messages (Kafka max 1MB
> default - use S3 reference), using messaging as RPC (request/reply
> via queues = brittle correlation), fat events (embedding full
> object vs event notification), shared topics for unrelated
> data (coupling consumers), and using Kafka as a database
> (retaining everything forever without cleanup strategy).

**3 minutes (Senior):**
> Anti-pattern catalog:
>
> Anti-pattern 1 - Large messages (claim check missing):
> Uploading 10MB PDF as a Kafka message.
> Kafka default max: 1MB. Broker rejects or slows.
> Fix: Claim Check pattern - store large payload in S3/blob store.
> Publish a small message with the reference URL.
> Consumer fetches payload from S3 using the reference.
>
> Anti-pattern 2 - Chatty queue (synchronous via async):
> Implementing request-reply with `reply-to` queue and correlation ID.
> Service A sends to queue, waits for response on reply queue.
> This is synchronous communication disguised as async.
> Loses all async benefits. Adds latency and complexity.
> Fix: use REST/gRPC for synchronous request-reply. Use events
> only for genuinely asynchronous notifications.
>
> Anti-pattern 3 - Fat events (entity snapshots):
> Every event contains the full entity state (100 fields).
> Consumers receive 100 fields even if they need 2.
> Schema evolution nightmare: adding a field = update all consumers.
> Fix: thin events (event notification + reference).
> `OrderStatusChanged{orderId, newStatus}`.
> Consumers fetch full order if needed (or subscribe to projections).
>
> Anti-pattern 4 - Single topic for all events:
> Dumping all domain events into one Kafka topic.
> All consumers read all events and filter by type.
> Ordering not preserved across domains.
> Fix: one topic per aggregate type (`orders`, `payments`).
>
> Anti-pattern 5 - No idempotency:
> Processing payments by incrementing balances.
> At-least-once delivery = possible duplicate.
> Balance incremented twice.
> Fix: idempotency key on every message + deduplication store.

**Blank Mind Recovery:**

**(1) Restate:** "Messaging anti-patterns: large messages, sync-as-async,
fat events, single topic, no idempotency. Each has a clear fix."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Large messages + idempotency + fat events |
| Staff | 10 min | Claim check + topic design + sync-as-async detection |

---

---

# Event-Driven Security Patterns

🎯 Interview Weight: medium-high - Security in event-driven
systems is a Staff-level concern often overlooked.

---

### 🎯 Model Answer

**30 seconds:**
> Event-driven security risks: unauthorized event publishing
> (anyone can produce to a topic), data leakage in events
> (PII in event payloads), replay attacks (old events re-sent
> to trigger actions), and broker compromise (all events exposed).
> Mitigations: Kafka ACLs (producer/consumer authorization),
> event encryption or PII masking, event signing, and TLS
> for transport encryption.

**3 minutes (Senior):**
> Security layers in event-driven systems:
>
> Transport security:
> Kafka TLS: encrypt data in transit between producers,
> consumers, and brokers.
> `security.protocol=SSL`, `ssl.truststore.location=...`.
> mTLS (mutual TLS): clients also authenticate with certificates.
> Prevents man-in-the-middle attacks.
>
> Authorization (Kafka ACLs):
> `bin/kafka-acls.sh --add --allow-principal User:payment-service
> --operation WRITE --topic orders`
> Restricts which service accounts can produce to which topics.
> Pattern: producer ACL per topic, consumer ACL per consumer group.
> Anti-pattern: super-user access for all services.
>
> Data classification and masking:
> PII in event payloads (email, credit card, SSN) must be masked.
> Pattern 1: tokenize PII before publishing (replace email with token ID).
> Pattern 2: encrypt PII fields in event payload.
> Encryption key per tenant (envelope encryption).
> Kafka Streams can decrypt + re-encrypt when routing events
> between teams with different access levels.
>
> Event integrity (signing):
> Sign event payload with producer's private key.
> Consumer verifies signature before processing.
> Prevents tampered events from compromised internal services.
>
> Audit logging:
> Log all events with producer identity, timestamp, partition,
> offset. Essential for SOC2 and GDPR compliance.
> Use Kafka audit topics (`__confluent.support.metrics`
> or custom audit pipeline).

**Blank Mind Recovery:**

**(1) Restate:** "Event security: TLS for transport, ACLs for authorization,
PII masking in payloads, event signing for integrity."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Kafka ACLs + TLS + PII masking |
| Staff | 8 min | mTLS + event signing + GDPR compliance |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Consumer lag + performance tuning |
| Platform/SRE | Message loss prevention + anti-patterns |
| Bar Raiser | Security patterns + exactly-once trade-offs |
