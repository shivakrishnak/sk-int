---
layout: default
title: "Distributed Systems - L3 Delivery Semantics"
parent: "Distributed Systems"
grand_parent: "SK Interview"
nav_order: 11
permalink: /distributed-systems/l3-delivery-semantics/
render_with_liquid: false
---

# Idempotency in Distributed Systems

**TL;DR:** An operation is idempotent if applying it multiple times
produces the same result as applying it once. In distributed systems,
idempotency is essential because at-least-once delivery guarantees
that consumers may receive the same message multiple times. Design
operations to be idempotent using unique idempotency keys (UUID
stored with the operation), check-then-act with unique constraints,
or natural idempotency (SET, not INCREMENT).

---

### 🎯 Model Answer

**30 seconds:**
> Idempotency means performing an operation multiple times has
> the same effect as doing it once. In distributed systems,
> retries and at-least-once delivery make duplicate requests
> inevitable. An idempotent operation handles duplicates gracefully:
> the second and third call produce the same result as the first.
> Implemented via unique idempotency keys (client generates a UUID
> per request, server deduplicates).

**3 minutes:**
> In a distributed system, at-least-once delivery is the practical
> guarantee: the network may drop the response (not the request),
> causing the client to retry. If the server processed the first
> request but the response was lost, the retry sends a duplicate.
> Without idempotency, the server processes the request again:
> double charge, duplicate email, inventory decremented twice.
>
> Idempotency prevents this. The client generates a UUID for each
> distinct operation (idempotency key). The server stores the
> result alongside the idempotency key. When a duplicate request
> arrives (same key): the server looks up the stored result and
> returns it without reprocessing. The client gets the same result
> as the original request.
>
> Natural idempotency: some operations are idempotent by design.
> `SET balance = 100` is idempotent (applying it 3 times still
> results in balance = 100). `INCREMENT balance BY 50` is not
> (applying it 3 times gives balance + 150).

**Blank Mind Recovery:**

**(1) Restate:** "Idempotency - designing operations so that
running them multiple times is safe. Duplicates are harmless."

**(2) First principles:** "Networks fail and retries are necessary.
Retries produce duplicate requests. Without idempotency: duplicates
cause incorrect state. With idempotency: the system recognizes
duplicates and returns the same result without reprocessing."

**(3) Bridge:** "Like sending a payment and not getting a receipt.
You send it again. Idempotency = the bank recognizes it as the
same payment (not a second payment) and shows 'already processed.'
Non-idempotency = the bank charges you twice."

---

### 📘 Concept Explanation

**What it is:**
The property of an operation that its result is the same whether
the operation is applied once or multiple times.

**The problem it solves:**
At-least-once delivery (Kafka, SQS, HTTP with retries) means
messages and requests may arrive multiple times. Idempotency
ensures that duplicates do not cause incorrect system state
(double charges, double emails, double inventory decrements).

**Natural idempotency:**

```
Idempotent by design:
SET key = value      → same result every time
DELETE row           → first deletes, subsequent no-op
GET/SELECT           → read-only, always idempotent
PUT (HTTP)           → replace resource completely

Not idempotent:
INCREMENT counter    → each call changes the result
INSERT INTO table    → each call adds a new row
POST /payments       → each call may charge the card
APPEND to log        → each call adds a new entry
```

**Idempotency key pattern:**

```
Client generates UUID per distinct logical operation:
  UUID = "550e8400-e29b-41d4-a716-446655440000"

Request:
  POST /payments
  X-Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
  { "amount": 100, "currency": "USD" }

Server processing:
  1. Check idempotency_keys table for this UUID
  2. If NOT EXISTS:
     a. Process the payment
     b. Store result + UUID in idempotency_keys
        (atomically with the payment commit)
     c. Return result
  3. If EXISTS:
     a. Return stored result (do NOT reprocess)

Result: second request returns same PaymentResult
as the first, without charging the card again.
```

**Atomic check-and-insert (prevent race conditions):**

```sql
-- BAD: separate check and insert (race condition)
-- Two concurrent requests both pass the SELECT check
SELECT 1 FROM idempotency_keys WHERE key = ?; -- both see nothing
INSERT INTO idempotency_keys ... -- both insert, one fails

-- GOOD: unique constraint handles atomically
CREATE UNIQUE INDEX ON idempotency_keys(key);
-- First INSERT succeeds
-- Second INSERT fails with unique constraint violation
-- Application catches UniqueConstraintViolation,
-- queries and returns the existing result
```

**The key insight:**
The check-and-insert must be atomic. A non-atomic check
(SELECT) followed by a non-atomic insert (INSERT) has a
TOCTOU (time-of-check-to-time-of-use) race condition: two
concurrent requests both pass the SELECT and both try to
INSERT - one succeeds, one fails. The application must handle
the constraint violation as an idempotency detection signal
(not as an error).

**When to use it:**
- All payment and financial operations (non-negotiable)
- Email and notification sending (prevent duplicate sends)
- Inventory operations (prevent double-decrement)
- Any operation that has side effects and may be retried
- Kafka/SQS consumer handlers (at-least-once delivery)

**When NOT to use it:**
- Read-only operations (already naturally idempotent)
- Operations that must be applied multiple times intentionally
  (incrementing a counter per event, not per unique event)

**Alternatives:**
- Exactly-once semantics (Kafka transactions): more complex,
  not always available
- Deduplication at the infrastructure layer (SQS FIFO:
  deduplication IDs)

**First-principles derivation:**
"Retries are a fundamental reliability mechanism. If retries can
cause incorrect state, the system is unreliable in the presence of
transient failures. Making operations idempotent enables safe
retries, which enables at-least-once delivery, which enables
reliable distributed communication."

---

### 💻 Code Example

```java
// IDEMPOTENCY KEY PATTERN IN JAVA

// BAD: no idempotency - double charge on retry
@PostMapping("/payments")
public PaymentResult processPayment(
        @RequestBody PaymentRequest req) {
    // BAD: no idempotency check
    // If the response is lost and client retries:
    // this charges the card a second time
    return paymentGateway.charge(
        req.getCustomerId(), req.getAmount());
}

// GOOD: idempotency with unique key
@PostMapping("/payments")
public ResponseEntity<PaymentResult> processPayment(
        @RequestHeader("X-Idempotency-Key")
            String idempotencyKey,
        @RequestBody PaymentRequest req) {

    // Step 1: check for existing result
    Optional<PaymentResult> existing =
        idempotencyStore.findByKey(idempotencyKey);
    if (existing.isPresent()) {
        // Return cached result - do NOT reprocess
        return ResponseEntity.ok(existing.get());
    }

    // Step 2: process (with unique constraint guard)
    try {
        // Save a "PROCESSING" record first
        // (prevents duplicate concurrent processing)
        idempotencyStore.saveProcessing(idempotencyKey);

        PaymentResult result = paymentGateway.charge(
            req.getCustomerId(), req.getAmount());

        // Step 3: save result atomically
        idempotencyStore.saveResult(
            idempotencyKey, result);

        return ResponseEntity.ok(result);

    } catch (DuplicateKeyException e) {
        // Concurrent duplicate request:
        // another thread already started processing
        // Wait briefly and return the stored result
        PaymentResult result = idempotencyStore
            .waitForResult(idempotencyKey);
        return ResponseEntity.ok(result);
    }
}
```

> **Code walkthrough:** The BAD pattern processes every POST
> without deduplication. The client retrying after a lost
> response charges the card twice. The GOOD pattern uses an
> idempotency key (UUID from the client). Before processing,
> the server checks if this key has been seen before. If yes:
> return the stored result immediately without calling the
> payment gateway. The `DuplicateKeyException` handler covers
> the race condition where two concurrent retries both pass
> the initial check - the unique database constraint prevents
> both from processing, and the one that loses the race waits
> for the winner's result.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Idempotency means an operation can be safely applied multiple
> times. In distributed systems, retries cause duplicate requests.
> An idempotent operation handles duplicates safely: the second
> request returns the same result as the first without side effects.
> Implementation: client generates a UUID (idempotency key),
> server stores the result with the key, and returns the stored
> result on duplicate requests.

---

**Senior / Staff:**
> Idempotency is a contract between client and server. The client
> is responsible for generating unique keys per distinct operation
> (not per retry of the same operation). The server is responsible
> for deduplication within a reasonable TTL (I store idempotency
> keys for 24 hours - long enough to cover all retry windows).
> After the TTL: the record is purged and a new request with the
> same key is treated as a new operation. I always enforce
> idempotency at the service boundary for non-idempotent operations,
> even if the internal implementation "should be" idempotent.
> Defense in depth: multiple layers of idempotency checking.

---

### ⚠️ Common Misconceptions

**"Checking before inserting makes the operation idempotent"**

Reality: a SELECT followed by INSERT is not atomic. Two concurrent
requests both observe the absence of the idempotency key (SELECT
returns nothing), and both proceed to INSERT. This is a race
condition. The correct approach: use a unique database constraint
on the idempotency key and handle the constraint violation as
an idempotency signal. The database's atomic INSERT with unique
constraint provides the required atomicity.

**"Kafka guarantees exactly-once, so I do not need idempotency
in my consumer"**

Reality: Kafka's exactly-once semantics (EOS) apply to producer →
broker delivery with Kafka transactions. They guarantee that a
message is written to the Kafka log exactly once. Consumer
processing is separate: Kafka offsets can be committed before
the consumer's side effects complete (crash after commit but
before processing = message "processed" in Kafka but side effect
not applied). For consumer-side processing (database writes, API
calls), the consumer must implement idempotency independently.

---

### ⚖️ Comparison Table

| Approach | Atomicity | Complexity | TTL | Use When |
|---|---|---|---|---|
| Unique DB constraint | Database atomic | Low | Manual cleanup | Simple operations |
| Redis SETNX + result | Redis atomic | Low | Redis TTL | High-throughput, no DB join |
| Idempotency table | DB transaction | Medium | Scheduled cleanup | Payment, financial |
| SQS FIFO dedup ID | Infrastructure | Minimal | 5 minutes (SQS) | SQS-based processing |
| Kafka transactions | Broker-level | High | N/A | Kafka-to-Kafka pipelines |

**The deciding factor:** Is the operation financial or critical?
Use an idempotency table with proper TTL and cleanup. For
infrastructure-level deduplication (message queue): use the
queue's native deduplication (SQS FIFO, Kafka exactly-once).

---

### 🎯 Interview Deep-Dive

#### Production Failures

Q: Users are reporting double charges on their credit cards.
The payment service uses retries. How do you debug and fix?

A: Double charges indicate non-idempotent payment processing
with retries. Diagnosis: check payment service logs for requests
with the same order ID appearing twice within seconds (the retry
window). Compare timestamps - if two identical payment requests
are < 30 seconds apart (the retry interval), it is a duplicate.
Check if the client sends an idempotency key header. If not:
the payment service cannot distinguish a retry from a new request.
Immediate fix: (1) Add idempotency keys to all payment requests
(client-side change). (2) Add idempotency check to the payment
endpoint (server-side). (3) For the Stripe API: Stripe natively
supports idempotency keys - pass the order ID as the Stripe
idempotency key. Long-term: add a unique constraint on
(customer_id, order_id) in the payments table as a backup
deduplication layer.

#### Candidate Mistakes

Q: How would you implement idempotency for an email notification service?

**What NOT to say:** "Check if the email was already sent before sending."

**Say instead:** "A simple 'check before send' has a race condition:
two concurrent requests both check, both see 'not sent,' and both
send. The correct approach: (1) When a notification event is received,
extract the event's unique ID (or generate one if absent). (2) Insert
the event ID into a `sent_notifications` table with a unique constraint.
If the INSERT fails with a unique constraint violation: the notification
was already processed. Return success without sending. (3) If INSERT
succeeds: send the email. (4) This INSERT is atomic - no race condition.
(5) Additional safeguard: use SQS FIFO with deduplication IDs for
the email queue. SQS deduplicates messages with the same deduplication
ID within a 5-minute window at the infrastructure level - before the
message even reaches the consumer."

---

---

# Exactly-Once Delivery Semantics

**TL;DR:** Exactly-once delivery means a message is processed
exactly one time: no loss (at-least-once) and no duplicates
(at-most-once). It is the hardest delivery guarantee in distributed
systems. Kafka's exactly-once semantics (EOS) uses idempotent
producers and transactions to guarantee exactly-once writing to
Kafka topics. Exactly-once end-to-end processing (including side
effects) requires idempotent consumers in addition.

---

### 🎯 Model Answer

**30 seconds:**
> Exactly-once is the hardest delivery guarantee: messages are
> neither lost nor duplicated. The three delivery levels:
> at-most-once (may lose, no duplicates), at-least-once (no loss,
> may duplicate), exactly-once (no loss, no duplicates).
> Kafka achieves exactly-once at the broker level using idempotent
> producers and transactions. End-to-end exactly-once requires
> idempotent consumer logic on top.

**3 minutes:**
> The three delivery semantics represent different trade-offs:
> at-most-once (fire and forget) - fast, simple, acceptable for
> metrics and logs where loss is tolerable. At-least-once (retry
> until acknowledged) - most common; duplicates possible.
> Exactly-once - no loss, no duplicates; hardest to achieve.
>
> Kafka's exactly-once: the producer uses an idempotent producer
> (sequence number on each batch). The broker deduplicates
> batches with the same sequence number - prevents producer retries
> from causing duplicate messages. Kafka transactions extend this:
> the producer can atomically write to multiple topics and commit
> a consumer offset in the same transaction. If the transaction
> is not committed: the consumer cannot see the messages (read
> committed). This enables stream-processing exactly-once: consume
> from topic A, process, produce to topic B, commit offset A -
> all in one atomic transaction.
>
> The critical caveat: Kafka's EOS covers the Kafka broker.
> If the consumer processes a message (e.g., writes to a database)
> and then crashes before committing the Kafka offset, the message
> will be redelivered. The database write (external side effect)
> is not covered by Kafka's EOS. For external side effects:
> the consumer must implement idempotency.

**Blank Mind Recovery:**

**(1) Restate:** "Exactly-once delivery - each message processed
exactly one time. No loss, no duplicates."

**(2) First principles:** "At-least-once: retry until acknowledged.
Duplicates possible. At-most-once: no retry. Loss possible.
Exactly-once: retry until acknowledged AND detect/discard duplicates.
Both guarantees together."

**(3) Bridge:** "Like delivery confirmation for a package:
(1) fire-and-forget = postal service ships, no tracking;
(2) at-least-once = you keep shipping until you get a delivery
confirmation; (3) exactly-once = delivery confirmed exactly once,
and any duplicate shipment is automatically returned. The last
requires the most infrastructure."

---

### 📘 Concept Explanation

**What it is:**
The message delivery guarantee that ensures each message is
processed exactly one time - combining at-least-once delivery
(no message loss) with at-most-once semantics (no duplicates).

**The problem it solves:**
At-least-once delivery (the practical standard for reliable systems)
produces duplicates under failures. Processing every message
exactly once without duplicates while also not losing messages is
the challenge that exactly-once semantics address.

**Delivery semantics comparison:**

```
At-most-once (fire and forget):
  Producer sends → does not wait for ack
  If message lost: never redelivered
  Duplicates: impossible
  Loss: possible
  Use: metrics, debug logs, telemetry

At-least-once (retry on failure):
  Producer sends → retries until ack received
  If ack lost: message redelivered (duplicate)
  Duplicates: possible
  Loss: impossible (assuming durable broker)
  Use: standard default, combined with idempotency

Exactly-once:
  Producer sends → retries until ack
  Broker deduplicates based on sequence number
  Consumer commits processed state + offset atomically
  Duplicates: impossible
  Loss: impossible
  Use: financial processing, stream-to-stream pipelines
```

**Kafka exactly-once semantics (EOS):**

```
Step 1: Idempotent producer
  - Producer gets a PID (Producer ID) from broker
  - Each message batch has a sequence number
  - Broker rejects batches with duplicate sequence numbers
  - Producer retries are safe: duplicate batches rejected

Step 2: Transactions (read-process-write pattern)
  producer.initTransactions();
  producer.beginTransaction();
  
  // Consume from input topic:
  ConsumerRecords<K,V> records = consumer.poll(...);
  
  // Process and produce to output topic:
  for (record : records) {
      V result = process(record);
      producer.send(new ProducerRecord(
          outputTopic, result));
  }
  
  // Commit input offset + output messages atomically:
  producer.sendOffsetsToTransaction(
      offsets, consumer.groupMetadata());
  producer.commitTransaction();
  
  // If crash occurs anywhere:
  // Transaction is aborted, no incomplete writes visible
  // Consumers with isolation.level=read_committed
  // do NOT see the aborted messages
```

**End-to-end exactly-once:**

```
Kafka EOS covers: producer → broker delivery
                  read-process-produce within Kafka

NOT covered:      consumer → external database write
                  consumer → external API call
                  consumer → email send

For external side effects: consumer must implement
idempotency (unique constraint on processed event ID).

Full exactly-once end-to-end:
  = Kafka EOS (broker layer)
  + Idempotent external writes (consumer layer)
```

**The key insight:**
True end-to-end exactly-once for external side effects (database,
API) is achieved through the combination of at-least-once delivery
+ idempotent processing. Kafka's EOS covers the Kafka-to-Kafka
path; the consumer is responsible for external idempotency.

**When to use it:**
- Financial transaction processing (debit/credit calculations)
- Stream processing pipelines with Kafka Streams / Flink
- Any stateful stream processing where duplicates produce
  incorrect aggregates (count, sum)

**When NOT to use it:**
- Stateless transformations where duplicates produce the
  same output (map operations, projection)
- Systems where idempotent processing is sufficient and
  simpler than Kafka EOS (most cases)
- Low-throughput systems where the transaction overhead is
  not justified

**Alternatives:**
- Idempotent at-least-once (simpler): at-least-once delivery
  + idempotent consumer. Effective for most cases.
- Exactly-once with saga: guarantee at the business logic level
  using saga compensation

**First-principles derivation:**
"Exactly-once = at-least-once + deduplication. At-least-once
is achieved by retrying. Deduplication is achieved by the broker
rejecting duplicates (idempotent producer) and the consumer
reading only committed messages (transactions). The two mechanisms
together give exactly-once."

---

### 💻 Code Example

```java
// KAFKA EXACTLY-ONCE SEMANTICS

// BAD: at-most-once (fire and forget)
// Could lose messages
public void processEvent(String event) {
    // BAD: auto-commit mode commits offset BEFORE
    // processing is complete. If crash during processing:
    // offset is committed, event lost.
    consumer.commitSync(); // commits before processing!
    processAndWriteToDb(event); // if crash here: event lost
}

// BAD: at-least-once without idempotency
// Duplicates cause incorrect state
public void processEvent(ConsumerRecord<K,V> record) {
    processAndWriteToDb(record.value()); // side effect
    consumer.commitSync(Map.of(
        new TopicPartition(
            record.topic(), record.partition()),
        new OffsetAndMetadata(record.offset() + 1)));
    // If crash after write but before commit:
    // record is redelivered → duplicate write
    // Without idempotency: duplicate entry in DB
}

// GOOD: Kafka Streams exactly-once (recommended)
// (application-level stream processing)
StreamsConfig config = new StreamsConfig(Map.of(
    PROCESSING_GUARANTEE_CONFIG, EXACTLY_ONCE_V2,
    APPLICATION_ID_CONFIG, "payment-processor",
    BOOTSTRAP_SERVERS_CONFIG, "kafka:9092"));

// Kafka Streams handles EOS automatically:
// read-process-produce all in one transaction
KStream<K, V> source = builder.stream("payments-input");
source
    .mapValues(payment -> processPayment(payment))
    .to("payments-output");
// Kafka Streams commits output messages AND
// input offsets atomically per processing batch.

// GOOD: producer transactions (manual EOS)
Properties props = new Properties();
props.put(ENABLE_IDEMPOTENCE_CONFIG, true);
props.put(TRANSACTIONAL_ID_CONFIG, "payment-txn-1");

KafkaProducer<K,V> producer = new KafkaProducer<>(props);
producer.initTransactions();

try {
    producer.beginTransaction();
    producer.send(new ProducerRecord<>(
        "output-topic", processedValue));
    producer.sendOffsetsToTransaction(
        getProcessedOffsets(), consumer.groupMetadata());
    producer.commitTransaction();
} catch (Exception e) {
    producer.abortTransaction();
    // re-seek consumer to retry
}
```

> **Code walkthrough:** The BAD at-most-once pattern commits
> the offset before processing - a crash during processing loses
> the event permanently. The BAD at-least-once pattern commits
> after processing but without idempotency - a crash between
> processing and commit causes the event to be reprocessed and
> written twice. The GOOD Kafka Streams approach is the simplest
> path to exactly-once: just set `EXACTLY_ONCE_V2` and Kafka
> Streams handles all the transaction management automatically.
> The manual producer transaction approach gives fine-grained
> control: the output messages and the input offset commit happen
> atomically - either both commit or neither does, preventing
> both loss and duplication within the Kafka ecosystem.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Exactly-once delivery means messages are neither lost nor
> duplicated. Kafka achieves this with idempotent producers
> (sequence numbers prevent duplicate writes to the broker)
> and transactions (commit output messages + input offset
> atomically). Kafka Streams provides exactly-once out of the box.
> External side effects still need idempotency at the consumer level.

---

**Senior / Staff:**
> In practice I use at-least-once + idempotent consumers for
> most systems - simpler than Kafka EOS and sufficient for most
> use cases. Kafka EOS has ~10-20% throughput overhead due to
> transactions. I use Kafka EOS for: stream processing where
> aggregations (count, sum) would be incorrect with duplicates,
> and Kafka-to-Kafka pipelines where I want the simplest exactly-once
> path. For external writes (database, API): EOS does not help -
> idempotent consumer is required regardless. The practical answer:
> "at-least-once + idempotent consumer = effectively exactly-once."

---

### ⚠️ Common Misconceptions

**"Kafka exactly-once covers all my processing, including
database writes"**

Reality: Kafka's EOS covers the Kafka producer → broker path and
Kafka-to-Kafka stream processing. It does NOT cover external
side effects (database writes, API calls, email sends). If the
consumer writes to a database and then crashes before committing
the Kafka offset, the message is redelivered and the database
write happens again. For external side effects: idempotent
consumer logic is required independently of Kafka EOS.

**"At-least-once is always better than exactly-once"**

Reality: at-least-once with idempotency is effectively exactly-once
for most operations. Pure at-least-once (without idempotency) is
unsafe for non-idempotent operations. The question is not
"at-least-once vs. exactly-once" but "which layer handles
deduplication": the infrastructure (Kafka EOS) or the application
(idempotent consumer). For simple pipelines: Kafka EOS is elegant.
For operations with external side effects: idempotent consumer
is mandatory regardless.

---

### ⚖️ Comparison Table

| Semantics | Loss | Duplicates | Complexity | Throughput | Use When |
|---|---|---|---|---|---|
| At-most-once | Possible | Never | Lowest | Highest | Metrics, logs |
| At-least-once | Never | Possible | Low | High | Default; add idempotency |
| Exactly-once (Kafka) | Never | Never (Kafka) | High | ~20% lower | Stream aggregations |
| Idempotent at-least-once | Never | Harmless | Medium | High | Most business operations |

**The deciding factor:** Are duplicates harmful to your data?
If duplicates are filtered out by unique constraints or
natural idempotency: at-least-once + idempotency. If duplicates
affect aggregations (incorrect count/sum): Kafka EOS for the
aggregation pipeline.

---

### 🎯 Interview Deep-Dive

#### Production Failures

Q: A Kafka consumer is writing duplicate records to the database.
The Kafka configuration uses at-least-once delivery. How do you fix?

A: The consumer is processing a message multiple times (after a
crash or rebalance) and writing to the database each time.
Fix: (1) Add an idempotency key column to the database table.
Use the Kafka message key + partition + offset as the idempotency
key (this uniquely identifies a specific message in a Kafka topic).
(2) Add a unique constraint on this column. (3) Wrap the insert
in a try-catch for unique constraint violations - treat violations
as successful (message already processed). (4) Alternatively:
use Kafka Streams with `EXACTLY_ONCE_V2` for stream processing
that stays within Kafka. For external writes, option 1-3 are still
necessary.

#### Candidate Mistakes

Q: How does Kafka achieve exactly-once delivery?

**What NOT to say:** "Kafka stores each message with a unique ID
and checks for duplicates."

**Say instead:** "Kafka exactly-once has two mechanisms: (1) the
idempotent producer: each Kafka producer gets a producer ID (PID)
from the broker. Each message batch has a sequence number per
partition. If the producer retries a batch (network timeout after
the broker already wrote it), the broker detects the duplicate
sequence number and drops it silently. This prevents producer
retries from duplicating messages. (2) Kafka transactions: the
producer can open a transaction, write to multiple topics and
partitions, send the consumer offset commit as part of the
transaction, and commit atomically. If the transaction is aborted
or the producer crashes, consumers with `read_committed` isolation
level do not see the uncommitted messages. Together, these allow
read-process-produce pipelines (Kafka Streams) to be exactly-once
within the Kafka ecosystem. For external side effects (database),
the consumer must separately implement idempotency."

### 🚨 Failure Modes and Diagnosis

**Failure 1: Race condition in idempotency check (double processing)**

Symptom: Two concurrent requests with the same idempotency key
both succeed in processing despite deduplication logic.

Root cause: Non-atomic check-and-insert. Two threads both execute
`SELECT WHERE key = ?`, both see nothing, both proceed to INSERT
and process.

Diagnosis:
```sql
-- Find duplicate idempotency key events
SELECT idempotency_key, COUNT(*) as occurrences
FROM processed_events
GROUP BY idempotency_key
HAVING COUNT(*) > 1;
-- Non-zero result: race condition hit
```

Fix: Add UNIQUE constraint on idempotency_key column. Handle
`DuplicateKeyException` as an idempotency signal, not an error.

---

**Failure 2: Idempotency key TTL too short (reused keys treated
as new)**

Symptom: A payment processed days ago is processed again when the
customer's bank retries the authorization (some banks retry
after 24 hours).

Root cause: Idempotency key TTL (24 hours) shorter than the
retry window.

Diagnosis: Compare idempotency key expiry timestamp with the
incoming request timestamp. If the key was purged but the
original request is within the business retry window:
false negative.

Fix: Set idempotency key TTL to 7 days (covers all bank retry
windows). Use a background job to purge keys older than TTL
rather than database row expiry (allows flexible TTL changes).

---

**Failure 3: Kafka consumer - uncommitted offset after
external write (at-least-once duplication)**

Symptom: Database has duplicate records for the same Kafka
message (same content, different primary keys).

Root cause: Consumer writes to DB (success), then crashes before
committing Kafka offset. Message redelivered → second write.

Diagnosis:
```bash
# Check consumer group lag (high lag = recent crash/restart)
kafka-consumer-groups.sh --describe \
  --group payment-consumer-group \
  --bootstrap-server kafka:9092
# Check DB for duplicate event IDs
SELECT kafka_offset, COUNT(*) FROM events
GROUP BY kafka_offset HAVING COUNT(*) > 1;
```

Fix: Add unique constraint on (kafka_topic, kafka_partition,
kafka_offset) in the events table. Treat unique constraint
violation as successful deduplication.

---

### 🎯 Interview Deep-Dive

| Category | Count |
|---|---|
| Clarification | 1 |
| Mechanism | 2 |
| Failure / Debugging | 2 |
| Trade-off | 1 |
| Production | 1 |
| Code | 1 |
| Behavioral | 1 |

---

**Q1 (Clarification) - Why is checking before inserting not
sufficient for idempotency?**

A: A SELECT followed by INSERT is two separate operations - not
atomic. Between the SELECT (returning "key not found") and the
INSERT, another thread or process can also SELECT (also returning
"key not found") and also INSERT. Both threads pass the check;
both process the operation. This is the TOCTOU (time-of-check-
time-of-use) race condition.

The solution: rely on the database's atomic semantics. Add a
UNIQUE constraint on the idempotency key column. Issue the INSERT
directly. If the INSERT fails with a unique constraint violation:
the key exists (another thread already processed it). Retrieve
and return the existing result. The database's INSERT with unique
constraint is atomic at the row level.

*What separates good from great:* the ability to identify TOCTOU
race conditions. Most developers think "I checked first, it should
be safe." The experienced developer knows that "check then act" is
a pattern that is safe only within a single synchronous thread.
In a multi-threaded or distributed context, the check is stale
the moment it completes. Database constraints are the correct tool.

---

**Q2 (Mechanism) - How does Kafka's idempotent producer work?**

A: When `enable.idempotence=true`, the Kafka producer receives a
Producer ID (PID) from the broker during initialization. Every
message batch sent to a specific partition has a sequence number
that starts at 0 and monotonically increases. The broker maintains
the highest sequence number seen from each PID per partition.

When a batch arrives: if the sequence number is exactly
`(highest seen) + 1`, the broker accepts it and increments the
counter. If the sequence number is `<= highest seen`, the broker
identifies it as a duplicate (from a producer retry) and silently
drops it. If the sequence number is `> (highest seen) + 1`, the
broker rejects it as an out-of-order batch.

This guarantees that producer retries (caused by network timeouts
where the broker acknowledged but the ack was lost) do not produce
duplicate messages in the Kafka log.

*What separates good from great:* understanding the per-partition
scope. The idempotent producer guarantees no duplicates per
partition. Across partitions: the producer can write to multiple
partitions in one transaction (Kafka transactions extend the
idempotent producer guarantee to multiple partitions).

---

**Q3 (Mechanism) - What is the difference between
idempotency key TTL and natural idempotency?**

A: Natural idempotency is a property of the operation itself -
applying it multiple times produces the same result. `SET x = 100`
is naturally idempotent: the 10th application still results in
`x = 100`. For naturally idempotent operations, no tracking is
required - the operation can be applied freely.

Idempotency key TTL is an external mechanism added to operations
that are NOT naturally idempotent (like charging a credit card).
The server stores the operation's result alongside a client-generated
key. If the same key arrives within the TTL window: return the
stored result without reprocessing. After TTL: the key is purged.
A new request with the same key (after TTL) is treated as a
new, distinct operation.

TTL must be longer than the maximum retry window. For payment
systems: I use 7 days (covers bank retry windows). For
notification systems: 24 hours is typically sufficient.

*What separates good from great:* recognizing that TTL is a
policy decision, not a technical implementation detail. Setting
the wrong TTL (too short: enables duplicates after expiry;
too long: storage and memory overhead from stale keys) requires
understanding the specific retry behavior of clients and upstream
systems. Design TTL based on observed retry patterns.

---

**Q4 (Failure / Debugging) - A payment service has been running
fine for months. Suddenly, users report double charges. What changed
and how do you find it?**

A: Double charges appearing suddenly (not from day one) indicate
a behavior change, not a missing idempotency implementation.
Investigation sequence:

1. Check recent deployments (was the payment endpoint or client
   changed in the last 24-48 hours?). Look for changes to retry
   logic, timeout configuration, or client-side request generation.

2. Check if the idempotency key generation changed. Common mistake:
   a client-side change that regenerates the key on each retry
   (instead of using the same key for all retries of the same
   operation). If the client generates a new UUID on every retry,
   the server sees each retry as a new request.

3. Check if the idempotency key TTL was reduced. If a batch job
   recently purged old keys more aggressively, retries arriving
   after TTL are treated as new operations.

4. Check if the client's retry backoff changed (shorter backoff =
   retries arrive closer together = race condition more likely).

5. Query for duplicate payment transactions with the same
   order_id to confirm the scope.

*What separates good from great:* framing the investigation around
"what changed" rather than "is idempotency broken." Idempotency
that worked for months does not spontaneously break - a change
in behavior or configuration is the cause. Systematic change
log review is the fastest diagnostic path.

---

**Q5 (Failure / Debugging) - How do you test that an operation is
truly idempotent?**

A: Three testing layers:

Layer 1 - Unit test: call the operation three times with the same
input and idempotency key. Assert: (a) the operation's side effect
occurred exactly once (DB row count = 1), (b) all three calls
returned identical responses, (c) no error was thrown on calls 2-3.

Layer 2 - Concurrent test: use a barrier (CountDownLatch) to
release 10 threads simultaneously, each calling the operation with
the same idempotency key. Assert: exactly one row in the database
(unique constraint test), all threads received a valid response
(no unhandled exceptions).

Layer 3 - Chaos test: inject a crash between the operation and the
idempotency key commit (mock the idempotency store to throw on
the first INSERT, succeed on the second). Assert: the operation
eventually completes exactly once without double-processing.

Kafka consumer specific: use Testcontainers with a Kafka container.
Publish a message, let the consumer process it, manually reset
the consumer offset to re-deliver the message. Assert: the side
effect (DB row) was not duplicated.

*What separates good from great:* Layer 3 (crash testing) is
what most engineers skip. The happy path and concurrent path are
necessary but insufficient. The crash between processing and
idempotency key commit is the failure scenario that actually
occurs in production (network partition, OOM crash). Testing
it explicitly gives confidence that the idempotency mechanism
works under real failure conditions.

---

**Q6 (Trade-off) - What are the trade-offs of using Redis for
idempotency key storage vs. a relational database?**

A: Redis SETNX (set if not exists):
- Pros: sub-millisecond lookups; TTL is native (Redis automatically
  expires keys); no schema change required; very high throughput.
- Cons: if Redis fails and the key is lost, the next retry is
  treated as a new operation (false negative); Redis is
  memory-limited (idempotency keys must fit in RAM); if the
  main database transaction rolls back after Redis SETNX succeeds,
  the key is consumed but the operation never completed (stuck state).

Relational database:
- Pros: ACID guarantees; the idempotency key can be committed in
  the same transaction as the operation (atomic); transactional
  rollback reverts both the operation and the key.
- Cons: adds a table scan / index lookup to every request;
  manual TTL cleanup required (scheduled job to delete expired keys);
  higher latency than Redis.

Decision: for financial operations, I use the relational database
(same transaction as the payment row - atomic rollback if the
payment fails). For notification services, I use Redis (speed,
built-in TTL, tolerable false negative risk).

*What separates good from great:* identifying the "stuck state"
risk with Redis. If Redis SETNX succeeds but the database
transaction rolls back: the idempotency key is consumed for an
operation that never completed. The next retry sees the key
and returns "already processed" - but the operation was never
actually done. Mitigation: Redis idempotency keys should have a
"processing" state that is updated to "complete" on success.
A key stuck in "processing" beyond a timeout is retried.

---

**Q7 (Production) - At your scale (10,000 payments/second), how
do you manage the idempotency key table?**

A: Three concerns at 10k/sec: write throughput, storage growth,
and lookup latency.

Write throughput: the idempotency key check + insert adds one
additional database operation per request. At 10k/sec with
99th percentile DB latency of 2ms: acceptable (within the
overall request budget). Partition the idempotency_keys table
by customer_id or by date to avoid hot spots on a single index.

Storage growth: at 10k/sec, 7-day TTL: 10,000 x 86,400 x 7 =
~6 billion rows. At 100 bytes per row: ~600 GB. This is manageable
in PostgreSQL with table partitioning by day - drop entire
partitions older than 7 days (much faster than row-level DELETE).

Lookup latency: the idempotency key lookup must complete before
the payment processing. Use a covering index on (idempotency_key,
result) to avoid a table heap read. With a B-tree index on a
UUID column, lookups are O(log N) ≈ 3-5ms at this scale.

*What separates good from great:* proposing table partitioning by
date and partition drop (not row-level TTL DELETE). At high
throughput, a DELETE WHERE created_at < NOW() - INTERVAL 7 DAYS
causes table bloat, write amplification, and lock contention.
Range partitioning with partition drops is the production-grade
solution for high-throughput idempotency tables.

---

**Q8 (Code) - Implement an idempotency decorator in Java for
Spring service methods.**

A:
```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Idempotent {}

@Aspect
@Component
public class IdempotencyAspect {

    @Autowired
    private IdempotencyStore store;

    @Around("@annotation(Idempotent)")
    public Object enforceIdempotency(
            ProceedingJoinPoint pjp) throws Throwable {

        // Expect first arg to be request with
        // getIdempotencyKey() method
        Object request = pjp.getArgs()[0];
        String key = (String) request.getClass()
            .getMethod("getIdempotencyKey")
            .invoke(request);

        Optional<Object> cached = store.find(key);
        if (cached.isPresent()) {
            return cached.get();
        }

        try {
            store.markProcessing(key);
            Object result = pjp.proceed();
            store.saveResult(key, result);
            return result;
        } catch (DuplicateKeyException e) {
            return store.waitAndGet(key);
        }
    }
}
```

*What separates good from great:* using an AOP aspect makes
idempotency a cross-cutting concern - applied declaratively
without polluting every service method with boilerplate. The
`@Idempotent` annotation is the contract. The aspect handles
the check-insert-race via `DuplicateKeyException` handling.
In a code review I would also ask: what happens if the
result is not serializable to the store? The aspect should
document the contract on the return type.

---

**Q9 (Behavioral) - Describe a time when a lack of idempotency
caused a production incident. What was the impact and how did
you resolve it?**

A: Example structure:

"At [company], our order confirmation email service processed
events from an SQS queue. During a deployment, the service
restarted mid-batch, causing SQS to redeliver 1,500 messages
that had already been processed (SQS at-least-once). Customers
received duplicate confirmation emails - some received 4-5 copies
within minutes.

Impact: ~1,500 customers affected; customer support volume
spiked 3x for 2 hours; 200 customers raised fraud concerns
about duplicate order confirmations.

Resolution (immediate): identified the SQS consumer was committing
visibility timeout extensions before processing. Deployed a hotfix
that added a unique constraint on (customer_id, order_id) in the
email_sent table, with UPSERT handling.

Resolution (permanent): changed the SQS consumer to: (1) extract
the order_id from each message, (2) attempt INSERT INTO email_sent
with a UNIQUE constraint, (3) proceed to send email only on
INSERT success - treat constraint violation as 'already sent,
skip.'

Lesson: any SQS or Kafka consumer that has observable side effects
(email, push notification, webhook) must be idempotent by design,
not as an afterthought."

*What separates good from great:* connecting the technical cause
(at-least-once delivery + restart during batch) to specific
business impact (customer trust, support cost). Also showing the
two-phase response: immediate hotfix (prevent recurrence) and
permanent solution (systematic fix). Behavioral answers that
include impact metrics and the decision-making process behind
the fix demonstrate senior-level incident management.

---

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Kafka consumer at-least-once duplication to external DB**

Symptom: Duplicate rows in the database for the same Kafka message.
Same business data, different primary keys.

Root cause: Consumer wrote to DB (success), then crashed before
committing the Kafka offset. On restart, the message was redelivered
and processed again.

Diagnosis:
```bash
# Check recent consumer group restarts
kafka-consumer-groups.sh --describe \
  --group my-group --bootstrap-server kafka:9092
# High "LAG" immediately after restart = reprocessing
# Check DB for duplicate event IDs
SELECT event_id, COUNT(*) FROM processed_events
GROUP BY event_id HAVING COUNT(*) > 1;
```

Fix: add unique constraint on event_id (Kafka key or message ID).
Handle `DuplicateKeyException` as successful deduplication.

---

**Failure 2: Kafka Streams EOS - zombie producers**

Symptom: Kafka Streams application occasionally produces duplicate
records to the output topic after a rebalance, despite
`EXACTLY_ONCE_V2` being configured.

Root cause: A "zombie producer" - a Streams thread that was
considered dead (due to a slow processing step exceeding the
session timeout) but was still alive and producing. Two producers
(the zombie and the replacement) both commit transactions to the
same output partition.

Diagnosis: Check Kafka broker logs for `ProducerFencedException`.
Check Kafka Streams `commit.interval.ms` vs. consumer
`session.timeout.ms`. If `commit.interval.ms` > `session.timeout.ms`:
a long processing batch can cause the consumer to appear dead.

Fix: Ensure `commit.interval.ms` < `session.timeout.ms`. Upgrade
to `EXACTLY_ONCE_V2` (EOS version 2) which uses epoch-based
producer fencing to definitively fence zombies. Reduce processing
per batch if individual records take too long.

---

**Failure 3: Transaction timeout - partial at-least-once
under Kafka EOS**

Symptom: Messages are not visible to consumers for extended periods
(minutes), then suddenly appear in bulk. Occasionally messages
appear twice.

Root cause: Kafka producer transaction timeout (`transaction.timeout.ms`)
is too short for slow processing. The transaction times out;
the broker aborts it. The producer retries in a new transaction,
potentially duplicating the produce if the abort is not detected.

Diagnosis:
```bash
# Check broker for transaction abort rate
kafka-topics.sh --describe \
  --topic __transaction_state \
  --bootstrap-server kafka:9092
# High abort count indicates frequent transaction timeouts
```

Fix: Increase `transaction.timeout.ms` to match maximum expected
processing latency (with margin). Reduce the number of records
processed per transaction batch to reduce per-transaction latency.

---

### 🎯 Interview Deep-Dive

| Category | Count |
|---|---|
| Clarification | 1 |
| Mechanism | 2 |
| Failure / Debugging | 2 |
| Trade-off | 1 |
| Production | 1 |
| Code | 1 |
| Behavioral | 1 |

---

**Q1 (Clarification) - What is the difference between at-least-once
and exactly-once, and when does the difference matter?**

A: At-least-once: the broker guarantees delivery, but the consumer
may see the same message more than once (after failures, retries,
or rebalances). The consumer is responsible for deduplication.

Exactly-once: the broker and consumer together guarantee that
each message is processed exactly one time - no loss, no
duplicates.

The difference matters when duplicates affect correctness:
- Count/sum aggregations: `+1` applied twice gives the wrong count.
  Requires exactly-once for correct results.
- Financial transactions: a credit applied twice gives the wrong balance.
  Requires idempotency or exactly-once.

The difference does NOT matter when:
- Operations are naturally idempotent (SET x = v; read operations).
- Duplicates are harmless (logging, non-critical metrics).

In practice: "exactly-once at the application layer" = at-least-once
delivery + idempotent consumer = same safety guarantee, lower
infrastructure complexity.

*What separates good from great:* distinguishing between Kafka's
EOS (broker-level) and end-to-end exactly-once (including external
side effects). Kafka EOS does not automatically give exactly-once
for database writes - idempotent consumers are still required.

---

**Q2 (Mechanism) - How do Kafka transactions work? Walk through
a read-process-produce cycle.**

A: Kafka transactions use a transaction coordinator (a special
Kafka broker) and a two-phase protocol.

Setup: `producer.initTransactions()` - the producer registers with
the transaction coordinator. Receives a transactional ID and PID.

Begin: `producer.beginTransaction()` - the producer enters
transactional state. All subsequent sends are buffered.

Produce: `producer.send(new ProducerRecord(...))` - messages are
staged but marked "uncommitted" on the broker. Consumers with
`isolation.level=read_committed` do NOT see these messages yet.

Offset commit: `producer.sendOffsetsToTransaction(offsets, groupMetadata)`
- the input consumer offsets are included in the transaction.
If the transaction commits: input offset advances. If aborted:
input offset stays, message redelivered.

Commit: `producer.commitTransaction()` - the coordinator marks
the transaction committed. All staged messages become visible to
`read_committed` consumers. Input offsets are advanced.

Abort: `producer.abortTransaction()` - staged messages are dropped.
Input offset unchanged. `read_committed` consumers never see
the aborted messages.

*What separates good from great:* understanding the
`read_committed` isolation level for consumers. Without setting
`isolation.level=read_committed` on consumers, they see
uncommitted (staged) messages - including messages from
transactions that are eventually aborted. EOS requires the
consumer isolation level to be set explicitly.

---

**Q3 (Mechanism) - What is the "zombie producer" problem in Kafka
EOS and how is it solved?**

A: A zombie producer is a Streams application instance that the
cluster considers dead (session timeout exceeded) but is still
running and producing messages. When a rebalance occurs: the
coordinator assigns the Streams task to a new instance (the
replacement). Both the zombie and the replacement now have
producers writing to the same output partitions.

Without fencing: both commit transactions, producing duplicates.

EOS Version 1 (EXACTLY_ONCE, deprecated): uses epoch fencing.
When the replacement producer initializes for the same
transactional ID, it gets a new epoch. The broker rejects
writes from the zombie (lower epoch = fenced). However, if the
zombie's transaction commits before being fenced: duplicates occur.
Race window exists.

EOS Version 2 (EXACTLY_ONCE_V2, current): uses the consumer group
epoch for producer fencing. The coordinator ties the producer epoch
to the consumer group generation. When a rebalance happens: the
new generation's producer fences the old generation's producer at
the consumer protocol level - tighter coupling, smaller race window.

*What separates good from great:* understanding that zombie producers
are a consequence of the session timeout and processing latency
interaction. The root cause is `processing_time > session_timeout`.
The fix is: reduce processing time per batch, increase session
timeout, or use `EXACTLY_ONCE_V2` with proper epoch fencing.
Mechanical knowledge of EOS v1 vs v2 demonstrates production depth.

---

**Q4 (Failure / Debugging) - A Kafka Streams application produces
duplicate records to an output topic despite EXACTLY_ONCE_V2.
How do you diagnose?**

A: Diagnosis steps:

1. Check for zombie producers: look for `ProducerFencedException`
   in application logs. This confirms fencing is happening
   (indicates multiple instances fighting for the same transactional ID).

2. Check commit interval vs session timeout:
   `commit.interval.ms` should be less than `session.timeout.ms`.
   If processing a single batch takes longer than `session.timeout.ms`,
   the consumer is considered dead mid-transaction. Add timing
   metrics to the processing function.

3. Verify consumer isolation level:
   `isolation.level=read_committed` must be set on all consumers
   reading the output topic. Without this, they read uncommitted
   messages from aborted transactions.

4. Check `transactional.id` uniqueness per Streams instance.
   If two Streams instances share the same `transactional.id`
   (misconfigured deployment), they fight for the transactional ID.

5. Verify output topic replication factor. If a broker fails during
   a transaction commit with RF=1, the transaction cannot commit
   durably. Restart can produce a duplicate from the retry.

*What separates good from great:* step 4 (transactional ID
uniqueness). This is a deployment-level misconfiguration that
appears identical to a zombie producer at the symptom level but
has a completely different root cause and fix. Production engineers
know to check configuration first, then behavior.

---

**Q5 (Failure / Debugging) - Users are receiving messages from a
Kafka consumer application, but with a consistent ~30-second delay
in bursts. What is the likely cause?**

A: Burst delay with at-least-once delivery often indicates
transaction timeout and retry behavior.

Hypothesis: the Kafka producer is using transactions with a short
`transaction.timeout.ms`. Processing takes > `transaction.timeout.ms`.
The transaction times out, the broker aborts it, the producer
retries (new transaction). Consumers see the messages only when
the retry commits - with a ~30-second lag matching the timeout.

Diagnosis:
```bash
# Check transaction.timeout.ms configuration
kafka-configs.sh --describe --broker 0 \
  --bootstrap-server kafka:9092 | grep transaction.timeout

# Check producer metrics for transaction abort rate
# (application metrics or JMX)
# High transaction-abort-rate confirms hypothesis

# Verify consumer end-to-end latency histogram:
# If P95 is ~30s and P50 is ~2s: transaction retry pattern
```

Fix: increase `transaction.timeout.ms` beyond the maximum
processing latency. Reduce the batch size to reduce per-transaction
processing time. Add a timer around the processing step to
measure actual latency and set `transaction.timeout.ms` to
2x the P99 processing latency.

*What separates good from great:* connecting the burst latency
pattern to the transaction timeout mechanism. Many engineers
would investigate network or consumer group rebalances first.
The burst pattern (not consistent latency) and the specific
~30-second delay matching a configuration value is the signal
that points to transaction timeouts.

---

**Q6 (Trade-off) - When would you choose at-least-once + idempotent
consumer over Kafka exactly-once transactions?**

A: I choose at-least-once + idempotent consumer in the
following situations:

(1) External side effects are required: Kafka EOS covers the
Kafka broker only. Writing to a database, calling an external
API, or sending emails requires idempotent consumer logic
regardless of EOS. If idempotency is already required for
external side effects, adding Kafka EOS provides no additional
safety guarantee for those operations.

(2) Throughput is a constraint: Kafka EOS has ~10-20% throughput
overhead due to transaction coordination overhead (2 RPCs per
batch: begin + commit). For high-throughput systems (100k+ msg/sec),
this is significant. At-least-once + idempotent consumer runs at
full throughput.

(3) Language / framework limitation: Kafka transactions are
well-supported in the Java client. Other language clients (Go,
Python) have less complete EOS support. Idempotent consumer is
a pure application-level pattern, framework-agnostic.

(4) Cross-system consistency: if the "exactly-once" scope
extends beyond Kafka (e.g., Kafka → PostgreSQL → Redis), Kafka
EOS handles only the Kafka portion. The application must handle
the rest regardless.

I choose Kafka EOS when: the entire pipeline is Kafka-to-Kafka,
the operation is a stateful stream aggregation (count, sum,
join), and the team is experienced with Kafka Streams or Flink.

*What separates good from great:* the insight that Kafka EOS
and idempotent consumer are not alternatives for external side
effects - EOS does not substitute for idempotency when writing
to external systems. They address different scopes.

---

**Q7 (Production) - How would you implement exactly-once processing
for a payment service that consumes from Kafka and writes to
PostgreSQL?**

A: Kafka EOS does not cover PostgreSQL writes. The practical
design for exactly-once payment processing:

Pattern: outbox + at-least-once + idempotent consumer

Step 1 - Consumer reads Kafka message (at-least-once delivery):
```
consumer.poll() → get payment event with unique event_id
```

Step 2 - Attempt INSERT with unique constraint:
```sql
INSERT INTO payments (event_id, customer_id, amount, status)
VALUES (?, ?, ?, 'pending')
ON CONFLICT (event_id) DO NOTHING;
-- If event_id already exists: skip processing (duplicate)
-- RETURNING 1 to check if row was actually inserted
```

Step 3 - Process only if INSERT succeeded (new event):
```java
boolean isNew = jdbcTemplate.queryForObject(
    "INSERT INTO payments ... RETURNING 1", ...)
    != null;
if (isNew) {
    paymentGateway.charge(customerId, amount);
    jdbcTemplate.update(
        "UPDATE payments SET status='complete' WHERE ...");
}
```

Step 4 - Commit Kafka offset (standard manual commit):
```java
consumer.commitSync();
```

Why this works: the `event_id` unique constraint on the payments
table deduplicates at the database level. A redelivered Kafka
message produces the same `event_id`. The INSERT returns nothing
(CONFLICT DO NOTHING), `isNew = false`, the payment gateway is
not called again. The offset is committed. Safe.

*What separates good from great:* the explicit "RETURNING 1"
pattern to detect whether the INSERT was a new row or a conflict.
A simple INSERT without return value detection cannot distinguish
success from no-op (both return without exception in PostgreSQL
with ON CONFLICT DO NOTHING). The detection is critical: without
it, you call `paymentGateway.charge()` on every duplicate.

---

**Q8 (Code) - Implement a Kafka Streams topology with exactly-once
semantics for a payment aggregation pipeline.**

A:
```java
@Configuration
public class PaymentStreamConfig {

    @Bean
    public KafkaStreams paymentAggregationStreams() {
        Properties props = new Properties();
        props.put(APPLICATION_ID_CONFIG,
            "payment-aggregator-v1");
        props.put(BOOTSTRAP_SERVERS_CONFIG,
            "kafka:9092");
        // Enable exactly-once semantics
        props.put(PROCESSING_GUARANTEE_CONFIG,
            EXACTLY_ONCE_V2);
        // Consumer must read committed only
        props.put(ISOLATION_LEVEL_CONFIG,
            "read_committed");
        props.put(COMMIT_INTERVAL_MS_CONFIG, 100);

        StreamsBuilder builder = new StreamsBuilder();

        KTable<String, Long> dailyTotals = builder
            .stream("payment-events",
                Consumed.with(Serdes.String(),
                    paymentSerde()))
            // Key by customer ID
            .groupByKey()
            // Aggregate: sum amounts
            .aggregate(
                () -> 0L,
                (customerId, payment, total) ->
                    total + payment.getAmount(),
                Materialized.<String, Long,
                    KeyValueStore<Bytes, byte[]>>as(
                    "daily-totals-store")
                    .withValueSerde(Serdes.Long()));

        dailyTotals.toStream().to(
            "daily-totals-output",
            Produced.with(Serdes.String(),
                Serdes.Long()));

        Topology topology = builder.build();
        KafkaStreams streams =
            new KafkaStreams(topology, props);
        streams.start();
        return streams;
    }
}
```

*What separates good from great:* setting BOTH
`PROCESSING_GUARANTEE_CONFIG=EXACTLY_ONCE_V2` AND
`ISOLATION_LEVEL_CONFIG=read_committed`. The processing guarantee
configures the producer side (transactions). The isolation level
configures the consumer side (only read committed messages).
Without both: the aggregation is not truly exactly-once. Many
engineers set only the processing guarantee and forget the
consumer isolation level, which means the Streams topology can
read and aggregate uncommitted messages from aborted transactions.

---

**Q9 (Behavioral) - Describe a system design decision you made
around delivery semantics. What trade-offs did you consider?**

A: Example structure:

"At [company], we were designing a notification service that
consumed from a Kafka topic and sent push notifications to mobile
devices. Initial design used at-least-once delivery. The concern:
users receiving duplicate push notifications (the classic 'you have
a new message' notification appearing twice).

Trade-offs evaluated: (1) Kafka EOS: would prevent duplicate
messages in the Kafka log, but push notifications via APNs/FCM
are external side effects - EOS would not prevent the service
from calling the push gateway twice if it crashed between sending
and committing the offset. (2) Idempotent at-least-once with
APNs deduplication ID: APNs (Apple Push Notification service)
and FCM both support a 'collapse key' or 'notification ID' that
deduplicates at the delivery layer. We used the Kafka message key
as the APNs/FCM notification ID.

Decision: at-least-once consumer + APNs/FCM deduplication ID.
No Kafka EOS needed. The push gateway handles the final
deduplication - our consumer can deliver the same message ID
twice, and the push gateway silently deduplicates on the device.

Lesson: look for deduplication support in the downstream system
before implementing it at the application layer. The push gateway
already had exactly what we needed. Adding Kafka EOS would have
been over-engineering for this case."

*What separates good from great:* identifying that the downstream
system (APNs/FCM) had native deduplication support that made
application-layer idempotency unnecessary for this specific case.
Experienced engineers know the capabilities of the systems they
integrate with and choose the simplest mechanism that achieves
the correctness guarantee.
