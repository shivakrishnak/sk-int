---
layout: default
title: "Messaging - L3 Delivery Semantics"
parent: "Messaging"
grand_parent: "SK Interview"
nav_order: 7
permalink: /messaging/l3-delivery-semantics/
---

# Exactly-Once Delivery Semantics

---

### 🎯 Model Answer

**30 seconds:**
> Exactly-once delivery means every message is processed precisely one time - never lost, never duplicated. It is the hardest guarantee to achieve because network failures force a choice: re-send and risk duplication, or do not re-send and risk loss. Kafka achieves exactly-once via transactional producers combined with idempotent consumers. The practical cost is latency and throughput reduction - most systems use at-least-once delivery plus idempotent consumers to achieve the same effective outcome at lower cost.

**3 minutes (Senior):**
> Exactly-once is frequently misunderstood as a single guarantee. It is actually three distinct guarantees: the message is produced exactly once to the broker, delivered exactly once to the consumer, and the consumer processes it exactly once with a resulting state change. Kafka's transactional API achieves the first two by combining idempotent producers (deduplication at the broker level) with consumer-to-producer transactions (atomically read-from-topic, process, write-to-topic in one transaction). This is called end-to-end exactly-once in Kafka Streams. The subtle limitation: Kafka's exactly-once applies to Kafka-to-Kafka processing. If your consumer writes to a database, Kafka cannot participate in that database transaction. You are back to at-least-once for the database write. The practical resolution is: Kafka exactly-once for stream-to-stream processing, plus idempotency guard on the external write. I have seen teams spend weeks implementing Kafka transactions to get exactly-once semantics for a database write, then realize the database deduplication key would have achieved the same result in one hour. Exactly-once is worth the complexity when processing results are themselves Kafka topics consumed by other systems - event sourcing, stream aggregation, replication.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Add: Kafka's two-phase commit protocol for transactions, read_committed isolation level, performance impact of transactions.

*Adapting down:* "Exactly-once means every message is handled exactly one time. It is hard to achieve because of network failures. Most systems use at-least-once plus idempotency checks, which gives the same practical result."

**Blank Mind Recovery:**
If you blank in the interview:

**(1) Restate:** "Exactly-once delivery - let me think through why it is hard to achieve."

**(2) First principles:** "When a message is sent and the ACK is lost, the sender does not know if the message arrived. It must either resend (risk duplicate) or give up (risk loss). Exactly-once requires a third option - a way to know if the message already arrived."

**(3) Bridge:** "This is the two generals problem applied to messaging. Exactly-once requires a coordination protocol to achieve consensus - Kafka uses a transactional log for this."

---

### 📘 Concept Explanation

**What it is:**
Exactly-once delivery is the guarantee that each message in the system produces exactly one state change - no message is lost, and no message triggers processing more than once. It requires coordination at multiple layers: producer, broker, and consumer.

**The problem it solves:**
At-least-once delivery causes duplicate processing when retries occur. At-most-once delivery causes message loss when failures occur. Applications requiring financial accuracy or deterministic state cannot tolerate either - they need exactly-once.

**How it works:**

Kafka exactly-once (idempotent producer + transactions):
```
Idempotent Producer:
  Each producer gets a Producer ID (PID) from the broker
  Each message gets a monotonic sequence number per partition
  Broker tracks: last written (PID, partition, seqNum)
  Duplicate: same (PID, seqNum) -> broker discards, returns OK
  Out-of-order: seqNum gap -> broker rejects

Transactional Producer (read-process-write):
  producer.initTransactions()
  producer.beginTransaction()
    consumer.poll() -> get offset range
    process records
    producer.send() to output topic
    producer.sendOffsetsToTransaction(offsets, groupId)
  producer.commitTransaction()  // atomic
  // Either all writes committed or all rolled back
  // Consumer with isolation.level=read_committed
  // will not see messages from aborted transactions
```

**The key insight:**
Kafka's transactional API achieves exactly-once for Kafka-to-Kafka workflows only. The moment a consumer writes to an external system (database, REST API, file), that write is outside the transaction boundary. External exactly-once requires the external system to participate in the transaction (2PC, outbox pattern, or idempotency key).

**When to use it:**
- Kafka Streams pipelines where output is another Kafka topic
- Financial aggregation where duplicate credits/debits are unacceptable
- Event replication where source and destination must stay exactly synchronized
- Audit systems where each event must appear exactly once in the audit log

**When NOT to use it:**
- Do not use transactional API for simple consumer-to-database workflows - idempotency key is simpler
- Do not use exactly-once when throughput is the priority - transactions reduce Kafka throughput by 20-50%
- Do not conflate Kafka exactly-once with end-to-end exactly-once including external systems

**Alternatives:**
- At-least-once + idempotency key - achieves effectively exactly-once for database writes with simpler implementation
- Outbox pattern - transactional database write + message publication atomically
- Two-phase commit - expensive, rarely the right answer in modern systems

**First-principles derivation:**
Given: network failures make it impossible to atomically "write to broker" and "receive ACK" as one operation. Given: the only way to prevent both loss and duplication is to either: (a) track whether the write succeeded using a durable identifier, or (b) make writes idempotent. Kafka's PID+sequence approach is option (a). Idempotency keys are option (b). Both work - the difference is implementation scope.

---

### 💻 Code Example

```java
// BAD: at-least-once causes duplicate payment credits
@KafkaListener(topics = "payment-events")
public void processPayment(PaymentEvent event) {
  // No idempotency check
  accountService.creditAccount(
      event.getAccountId(), event.getAmount());
  // If consumer crashes after credit but before commit:
  // restart redelivers event -> double credit
}
```

> **Code walkthrough:** This is the classic at-least-once duplication bug. The payment is credited, then the consumer crashes before committing the Kafka offset. On restart, the event is redelivered and the account is credited again. No exception, no alert - silent double credit. Financial systems need protection against this.

```java
// GOOD: Kafka transactional producer for exactly-once
// (Kafka-to-Kafka stream processing)
Properties props = new Properties();
props.put("transactional.id", "payment-processor-1");
props.put("enable.idempotence", "true"); // implicit with tx
KafkaProducer<String, String> txProducer =
    new KafkaProducer<>(props);
txProducer.initTransactions();

// Consumer reads with read_committed isolation
Properties consumerProps = new Properties();
consumerProps.put("isolation.level", "read_committed");
consumerProps.put("enable.auto.commit", "false");
KafkaConsumer<String, String> consumer =
    new KafkaConsumer<>(consumerProps);
consumer.subscribe(List.of("payment-events"));

while (true) {
  ConsumerRecords<String, String> records =
      consumer.poll(Duration.ofMillis(500));
  txProducer.beginTransaction();
  try {
    for (ConsumerRecord<String, String> record : records) {
      PaymentEvent event = parse(record.value());
      String processed = processPayment(event);
      txProducer.send(new ProducerRecord<>(
          "processed-payments", event.getId(), processed));
    }
    // Atomically commit: consume + produce
    Map<TopicPartition, OffsetAndMetadata> offsets =
        getOffsets(records);
    txProducer.sendOffsetsToTransaction(
        offsets, consumerProps.getProperty("group.id"));
    txProducer.commitTransaction();
  } catch (Exception e) {
    txProducer.abortTransaction(); // rollback both
  }
}
```

> **Code walkthrough:** This is exactly-once for Kafka-to-Kafka: consume from `payment-events`, process, produce to `processed-payments`, all in one atomic transaction. Either all records in the batch are consumed AND the output is written, or neither happens. The `read_committed` isolation level on the consumer prevents reading messages from aborted transactions.

```java
// PRODUCTION: effectively exactly-once for database writes
// (idempotency key approach - simpler than Kafka transactions
//  when the output is a database, not a Kafka topic)
@KafkaListener(topics = "payment-events")
@Transactional  // database transaction
public void processPayment(
    ConsumerRecord<String, String> record,
    Acknowledgment ack) {
  PaymentEvent event = parse(record.value());
  String idempotencyKey = event.getPaymentId(); // unique ID
  // Check if already processed (within DB transaction)
  if (paymentRepo.existsByIdempotencyKey(idempotencyKey)) {
    ack.acknowledge(); // already done, safe to skip
    return;
  }
  // Credit account and record processed event atomically
  accountService.creditAccount(
      event.getAccountId(), event.getAmount());
  paymentRepo.save(new Payment(
      idempotencyKey,
      event.getAccountId(),
      event.getAmount(),
      Instant.now()));
  ack.acknowledge(); // commit Kafka offset
}
```

> **Code walkthrough:** The database idempotency check inside a database transaction is the practical exactly-once pattern for DB writes. The unique constraint on `idempotency_key` prevents double-processing even if the consumer crashes after the DB commit but before the Kafka commit - the next delivery finds the record already exists and skips. This is simpler and more performant than Kafka transactions for external writes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> "Exactly-once delivery means each message is processed precisely one time - never lost, never duplicated. It is hard to achieve because network failures force a choice: retry and risk a duplicate, or give up and risk loss. Kafka achieves it for Kafka-to-Kafka processing using transactional producers that atomically consume input and produce output. For writing to databases or external systems, most systems use at-least-once delivery plus an idempotency key - a unique identifier that lets the consumer check whether it has already processed that message."

*Push deeper:* "Kafka's idempotent producer assigns each producer a producer ID and each message a sequence number. The broker tracks these and discards duplicates with the same sequence number. Combined with transactions, you get atomically: consume from topic A, produce to topic B, commit consumer offset - all succeed or all roll back."

---

**Senior / Staff (5+ years):**
> "Exactly-once is the most expensive delivery guarantee in distributed systems, and it is frequently over-specified. Teams request exactly-once but actually need: no data loss plus idempotent processing. Those are achievable at much lower cost. Kafka's transactional API delivers exactly-once for Kafka-to-Kafka workflows - the transaction spans the consume-offset and the produce. The key limitation: external writes are outside the transaction. If I write to PostgreSQL inside a Kafka consumer, I need a distributed transaction (two-phase commit) or an idempotency key in the database. In production, I use idempotency keys for external writes, Kafka transactions only for stream-to-stream pipelines. The performance cost of Kafka transactions is 20-50% throughput reduction due to the coordinator round trips. That cost is only justified when the downstream is another Kafka topic."

*Push deeper:* "Staff angle: exactly-once at the system level requires all components to participate. You can have Kafka exactly-once producing to a topic, but if the downstream consumer is at-least-once to S3, the end-to-end guarantee is at-least-once. Draw the entire message flow and identify every delivery boundary - each boundary has its own guarantee. The weakest link determines the system-level guarantee."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What is exactly-once delivery and why is it hard to achieve?"
- "How is exactly-once different from at-least-once plus idempotency?"

🗣️ "Exactly-once means every message produces exactly one state change - no loss, no duplication. It is hard because distributed systems have no way to atomically send a message and receive confirmation in a single operation. Network failures force a choice: retry (risk duplicate) or give up (risk loss). Kafka solves this by tracking a producer ID and sequence number per partition - duplicates are rejected by the broker. For end-to-end exactly-once including the consumer, Kafka transactions atomically couple the consume offset commit with the produce operation. Versus at-least-once plus idempotency: the outcome is the same - no duplicate state changes - but the implementation is different. Kafka transactions enforce it at the broker level; idempotency keys enforce it at the application level. Idempotency keys are simpler and more portable when writing to external systems."

#### Mechanism
- "Walk me through how Kafka's idempotent producer prevents duplicate messages."
- "How does Kafka's transactional API achieve exactly-once for stream processing?"

🗣️ "Idempotent producer: when enabled, the broker assigns the producer a Producer ID. Each message sent to a partition gets a monotonically increasing sequence number. The broker tracks the last written sequence per producer-partition pair. If a retry arrives with the same sequence number, the broker discards the duplicate and returns success. If a sequence arrives out of order, the broker rejects it as a sequencing violation. Transactions: the producer calls beginTransaction, sends output records, calls sendOffsetsToTransaction to atomically bind the consumer offset commit to the transaction, then commitTransaction. The broker atomically marks all output records and the consumer offset commit as committed. Consumers reading with isolation.level=read_committed never see records from uncommitted or aborted transactions."

#### Comparison
- "Compare Kafka transactions, Outbox pattern, and idempotency keys for achieving effectively exactly-once."
- "When is at-least-once plus idempotency preferable to Kafka transactions?"

🗣️ "Kafka transactions work only for Kafka-to-Kafka pipelines. They are atomic at the broker level but do not cross system boundaries. The outbox pattern achieves exactly-once for database-to-Kafka by writing the event to an outbox table in the same database transaction as the business change, then a separate process reads the outbox and publishes to Kafka. Idempotency keys work for any external system - database, REST API, filesystem - by including a unique ID in each request that the target uses to deduplicate. At-least-once plus idempotency is preferable to Kafka transactions in almost every case where the output is an external system: simpler implementation, no throughput penalty, more portable. Kafka transactions are justified when you need strict exactly-once semantics for Kafka Streams aggregations or event replication where even temporary inconsistency during a crash is unacceptable."

#### Scenario
- "Design a payment processing system that requires exactly-once crediting of accounts."
- "How would you implement exactly-once event replication between two Kafka clusters?"

🗣️ "For payment account crediting: use at-least-once Kafka delivery with database idempotency key. Each payment event carries a unique paymentId. The consumer checks whether that paymentId has already been processed by querying the payments table. The credit and the idempotency record insertion happen in the same database transaction. This achieves effectively-exactly-once for the database write without Kafka transactions. For cross-cluster replication with exactly-once: use Kafka's MirrorMaker 2 with exactly-once configured via transactional IDs. The replicator reads from the source cluster with read_committed and writes to the target cluster using transactions, atomically advancing both the source offset and the target partition write. This ensures no message is duplicated or lost across clusters even during failures."

#### Debugging
- "Users are reporting duplicate payment credits - how do you diagnose the root cause?"
- "How do you verify whether exactly-once is actually working in a Kafka transactional pipeline?"

🗣️ "Duplicate payment credits: first check the payment processing logs for redelivered Kafka message IDs. The redelivery flag in the message headers and the message offset will be the same if it is a Kafka retry. If duplicates have different Kafka offsets, the producer is duplicating at the source - check idempotent producer configuration. If the same offset appears twice in processing logs, the consumer committed the Kafka offset but crashed before saving to the database - the next startup reprocessed from the last committed offset. Fix: ensure the database idempotency check is inside the same transaction as the business write. To verify transactional pipeline correctness: compare input topic record count with output topic record count - they should match exactly after a defined window. Use Kafka consumer-groups to check committed offsets and verify they advance only with successful transactions."

#### Deep Dive
- "What are the performance costs of Kafka's exactly-once transactional API?"
- "How does read_committed isolation level affect consumer throughput?"

🗣️ "Transactional producer costs: each beginTransaction and commitTransaction requires a round trip to the transaction coordinator (a specific broker). For high-throughput pipelines, this adds 5-20ms per batch. Additionally, the broker must write transaction markers to the log. Benchmarks typically show 20-50% throughput reduction compared to non-transactional producers at the same settings. Read_committed isolation adds latency on the consumer side: the consumer must wait for the transaction marker (COMMIT or ABORT) before reading records from an open transaction. For producers with large transaction intervals, this adds significant consumer lag. The consumer-visible lag includes in-flight transaction records that it cannot process until committed."

#### Misconception / Trap
- "If I use Kafka's transactional API, I get end-to-end exactly-once including database writes, right?"
- "Exactly-once is always worth implementing because duplicates cause bugs - at-least-once is unsafe, right?"

🗣️ "Both wrong. Kafka transactions cover Kafka-to-Kafka processing only. The transaction boundary is the Kafka broker. Any write to an external system - database, REST API, cache - is outside the transaction. For database writes, you need either the outbox pattern or application-level idempotency. At-least-once with idempotency is not unsafe - it is the right choice for most systems. Idempotent operations are a fundamental design principle: design your processing so it can handle the same message twice without incorrect outcomes. For most business operations, this is achievable at lower cost than transactions. Exactly-once transactions add real throughput costs and operational complexity. Use them only when the downstream is a Kafka topic and the cost of even temporary inconsistency exceeds the performance penalty."

#### Performance & Scalability
- "How does Kafka's transactional exactly-once scale with partition count?"
- "What is the throughput ceiling for a Kafka Streams exactly-once pipeline?"

🗣️ "Each transaction coordinator handles transactions for a subset of partitions (by transactional.id hash). Increasing partition count increases parallelism without increasing coordinator load proportionally - multiple transaction coordinators handle different producers. The throughput ceiling for exactly-once is lower than at-least-once because each transaction requires coordinator round trips. Typical ceiling: 50-200MB/s per Kafka Streams exactly-once instance, versus 200-500MB/s for at-least-once. The practical ceiling is often network-bound rather than transaction-coordinator-bound. Scaling: run multiple Kafka Streams instances with different input partition assignments - each instance manages its own transactions independently."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with PID/sequence mechanism and transaction protocol details |
| Hiring Manager | Lead with: exactly-once is expensive - idempotency key achieves same outcome cheaper |
| Bar Raiser | Lead with: Kafka transactions cover Kafka-to-Kafka only - external systems need separate approach |
| Peer Engineer | "The pattern I use 95% of the time: at-least-once plus database idempotency key" |

---

---

# Idempotent Consumers

---

### 🎯 Model Answer

**30 seconds:**
> An idempotent consumer processes the same message multiple times without causing additional side effects after the first processing. It is the practical mechanism for achieving effectively-exactly-once behavior in at-least-once delivery systems. The key design principle: every state-changing operation must include a unique identifier that lets the system detect and skip already-applied operations.

**3 minutes (Senior):**
> Idempotency is the most important property to design into a consumer in any at-least-once messaging system. The guarantee from the broker is: you will receive every message at least once. Your job as the consumer designer is to ensure that the second and third delivery of the same message produce no additional effect. The implementation pattern is the idempotency key: a unique identifier in the message that the consumer uses to check whether it has already processed that message. For database writes, this is a unique constraint on the business key or a processed-events table. For API calls, it is an idempotency header that the downstream API uses for deduplication. The non-obvious complexity is: what counts as the idempotency boundary? If your consumer writes to two different services in sequence and crashes between them, the second retry must be idempotent for both writes. This requires either a two-phase commit, a saga with compensating transactions, or an ordering guarantee that lets you detect and skip the already-applied first write. I have debugged idempotency failures where the unique constraint existed but was on the wrong combination of fields - the deduplication key did not uniquely identify the business operation, so different redeliveries of the same Kafka message with different processing timestamps both passed the uniqueness check.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Add: partial idempotency (first N steps idempotent, last step not), saga-based compensating transactions for non-idempotent operations.

*Adapting down:* "An idempotent consumer can receive the same message twice and produce the same result as if it received it once. Like pressing an elevator button twice - the elevator only comes once."

**Blank Mind Recovery:**
If you blank in the interview:

**(1) Restate:** "Idempotent consumers - let me think through when the same message arrives twice."

**(2) First principles:** "At-least-once delivery guarantees the message arrives. It does not guarantee it arrives only once. So the consumer must handle the case where it already did the work. That is idempotency."

**(3) Bridge:** "This is the same as SQL INSERT OR IGNORE or UPSERT. You design the write so it is safe to execute multiple times. The second execution produces no new side effect."

---

### 📘 Concept Explanation

**What it is:**
An idempotent consumer is one where executing the same message processing logic multiple times produces the same result as executing it once. Mathematically: f(f(x)) = f(x). The implementation requires unique identification of each operation and detection of already-applied operations.

**The problem it solves:**
In any at-least-once delivery system, the consumer will occasionally receive the same message twice. Without idempotency, the second processing causes incorrect state: double credits, duplicate emails, repeated API calls. Idempotent consumers make at-least-once delivery safe for stateful operations.

**How it works:**

Pattern 1 - Database unique constraint:
```
Message: {paymentId: "pay-123", amount: 100}
Consumer:
  BEGIN TRANSACTION
    INSERT INTO payments (payment_id, amount, processed_at)
    VALUES ('pay-123', 100, NOW())
    ON CONFLICT (payment_id) DO NOTHING
    -- or ON DUPLICATE KEY in MySQL
    -- If already inserted: no-op, no error
    -- Credit account only if insert succeeded
    IF rows_affected > 0:
      creditAccount(accountId, 100)
  COMMIT
```

Pattern 2 - Processed events table:
```
Consumer:
  BEGIN TRANSACTION
    SELECT 1 FROM processed_events
    WHERE message_id = 'pay-123'
    FOR UPDATE  -- prevent race condition
    IF found: ROLLBACK, return  -- already processed
    INSERT INTO processed_events (message_id, processed_at)
    VALUES ('pay-123', NOW())
    -- Do the actual work
    creditAccount(accountId, 100)
  COMMIT
```

Pattern 3 - Idempotency key in external API:
```
// HTTP header approach
POST /api/payments
Idempotency-Key: pay-123
{ "accountId": "acc-456", "amount": 100 }

// Server stores Idempotency-Key -> response mapping
// Second request with same key returns cached response
// No double credit
```

**The key insight:**
The idempotency check and the business operation must be atomic. If the check succeeds but the application crashes before the business operation, the next retry fails the check (marks it as done) but the work was never done - false idempotency. The check and the work must be in the same database transaction, or you need a state machine that tracks partial completion.

**When to use it:**
- Any consumer that writes to a database, calls an API, sends a notification, or changes external state
- Financial operations: payments, credits, debits, transfers
- Email/notification sending: use event ID as idempotency key to prevent duplicate sends
- Inventory management: reserve/release operations that must not double-apply

**When NOT to use it:**
- Append-only logs where duplicates are acceptable (telemetry, analytics)
- Pure read operations with no side effects
- Operations where the business logic itself is inherently idempotent (e.g., SET balance = X rather than balance += X)

**Alternatives:**
- Natural idempotency: design operations as SET (absolute) rather than DELTA (relative) - eliminates the need for deduplication
- Outbox pattern: make the message publication itself idempotent by tying it to a DB transaction
- Kafka exactly-once transactions: broker-level idempotency for Kafka-to-Kafka pipelines

**First-principles derivation:**
Idempotency is required whenever: (1) an operation can be retried, (2) the operation has side effects, and (3) executing the side effect twice produces incorrect outcomes. These three conditions are always true for at-least-once messaging consumers. Therefore idempotency is not optional - it is a correctness requirement for any stateful at-least-once consumer.

---

### 💻 Code Example

```java
// BAD: non-idempotent consumer - double credit on retry
@KafkaListener(topics = "payment-events")
public void handlePayment(PaymentEvent event) {
  // If this crashes after credit but before commit:
  // restart will reprocess -> double credit
  BigDecimal amount = event.getAmount();
  account.setBalance(account.getBalance().add(amount));
  accountRepo.save(account); // save new balance
  // No idempotency protection whatsoever
}
```

> **Code walkthrough:** This is a DELTA operation (balance += amount) with no deduplication. If the Kafka offset commit fails after the database save, the next delivery applies the amount again. The account balance grows without bound under repeated failures. This is the idempotency failure pattern.

```java
// GOOD: idempotent via database unique constraint
@KafkaListener(topics = "payment-events")
@Transactional
public void handlePayment(
    ConsumerRecord<String, String> record,
    Acknowledgment ack) {
  PaymentEvent event = parse(record.value());
  String paymentId = event.getPaymentId(); // unique per event
  try {
    // INSERT OR IGNORE: second attempt is a no-op
    int inserted = jdbcTemplate.update(
        "INSERT INTO processed_payments "
        + "(payment_id, account_id, amount, processed_at) "
        + "VALUES (?, ?, ?, NOW()) "
        + "ON CONFLICT (payment_id) DO NOTHING",
        paymentId,
        event.getAccountId(),
        event.getAmount());
    if (inserted > 0) {
      // Only apply the credit if not already processed
      accountService.credit(
          event.getAccountId(), event.getAmount());
    }
    // inserted == 0: already processed, safe to skip
    ack.acknowledge();
  } catch (DataAccessException e) {
    log.error("DB error for payment {}", paymentId, e);
    // Do NOT ack - will retry
  }
}
```

> **Code walkthrough:** The `ON CONFLICT DO NOTHING` is the idempotency guard. The unique constraint on `payment_id` ensures the second attempt to insert the same payment returns `rows_affected = 0`. The credit is only applied when `inserted > 0`, making the consumer safe for any number of redeliveries. Both the INSERT and the credit happen in the same database transaction for atomicity.

```java
// PRODUCTION: idempotency with TTL to prevent dedup store bloat
// For long-running systems, dedup store can grow unboundedly
// Solution: TTL-based expiry matching message retention

@Service
public class IdempotentPaymentConsumer {
  private static final Duration DEDUP_TTL =
      Duration.ofDays(7); // >= Kafka retention.ms

  @KafkaListener(topics = "payment-events")
  @Transactional
  public void handle(
      ConsumerRecord<String, String> record,
      Acknowledgment ack) {
    PaymentEvent event = parse(record.value());
    String key = "payment:" + event.getPaymentId();

    // Redis-based dedup with TTL
    Boolean isNew = redisTemplate.opsForValue()
        .setIfAbsent(key, "1",
            DEDUP_TTL.toSeconds(), TimeUnit.SECONDS);

    if (Boolean.FALSE.equals(isNew)) {
      // Already processed - safe to skip
      ack.acknowledge();
      metrics.counter("payment.deduplicated").increment();
      return;
    }
    try {
      accountService.credit(
          event.getAccountId(), event.getAmount());
      ack.acknowledge();
    } catch (Exception e) {
      // Delete Redis key to allow retry
      redisTemplate.delete(key);
      throw e; // Do NOT ack - will retry
    }
  }
}
```

> **Code walkthrough:** Redis `SET NX` (set if not exists) with TTL provides a lightweight dedup store with automatic expiry. The TTL is set to at least the Kafka retention period - ensuring any redeliverable message can be deduplicated. If processing fails, the Redis key is deleted to allow the next retry to proceed. Critical: delete the Redis key on failure, not on success.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> "An idempotent consumer is one that can receive and process the same message multiple times without incorrect side effects. Since message brokers guarantee at-least-once delivery - meaning the same message might arrive twice - consumers must be designed to handle duplicates safely. The standard implementation is an idempotency key: a unique identifier in the message that the consumer records when it first processes that message. On the second delivery, it finds the key already recorded and skips processing."

*Push deeper:* "The idempotency check must be inside the same database transaction as the business operation. If you check, find the message is new, then the application crashes before the business write, the next retry will check again, find the message is new, and duplicate the work. The check and the work must be atomic."

---

**Senior / Staff (5+ years):**
> "Idempotency is a correctness property, not a performance optimization. Every consumer that writes to an external state store must be idempotent - the delivery guarantee is at-least-once, period. The design pattern I follow is: assign a stable unique ID to each message at the source (in the producer), propagate it through the entire processing chain, and check it atomically with every state-changing operation. The failure mode that trips teams up is partial idempotency: the first step of a multi-step process is idempotent, but the second step is not. If the consumer crashes between steps, the retry detects step one is already done, skips it, but now step two runs twice. You need per-step idempotency or a state machine that tracks the pipeline position."

*Push deeper:* "Staff concern: natural idempotency vs deduplication. Where possible, redesign operations to be naturally idempotent - SET rather than DELTA. `SET balance = X` is naturally idempotent; `balance += Y` requires deduplication. Natural idempotency eliminates the dedup store, the TTL concern, and the race condition between check and write. This is a design-time decision that pays dividends for the lifetime of the system."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What is an idempotent consumer and why do you need one?"
- "What is the difference between a naturally idempotent operation and one that requires a deduplication guard?"

🗣️ "An idempotent consumer processes the same message multiple times with the same result as processing it once - no additional side effects after the first processing. You need one because at-least-once delivery means the same message will occasionally arrive twice - during retries, rebalances, or crash recovery. Without idempotency, those redeliveries cause incorrect state: double credits, duplicate emails, repeated API calls. A naturally idempotent operation produces the correct outcome regardless of how many times it is executed - setting a field to a specific value, or an SQL UPSERT. An operation requiring a deduplication guard changes state by a delta - adding, subtracting, sending - and must record whether it has already been applied."

#### Mechanism
- "Walk me through implementing an idempotent consumer that credits a bank account from Kafka events."
- "How do you prevent a race condition in the idempotency check?"

🗣️ "For idempotent account crediting: each payment event carries a unique paymentId generated by the payment service. The consumer, in a single database transaction, inserts a record into a `processed_payments` table with a unique constraint on `payment_id`. If the INSERT succeeds, the account credit is also applied in the same transaction. If the INSERT fails with a unique constraint violation, the message was already processed - skip the credit and acknowledge the Kafka message. This is atomic because both operations are in the same database transaction. The race condition concern: two consumer instances process the same redelivered message simultaneously. Both check processed_payments, both find it absent, both credit. The unique constraint prevents this: only one INSERT succeeds; the other fails and rolls back its transaction."

#### Comparison
- "Compare database unique constraint vs Redis SET NX for idempotency deduplication."
- "When would you use Kafka's transactional API over application-level idempotency?"

🗣️ "Database unique constraint is simpler and transactionally consistent with the business operation - the check and the write are atomic. Use it when the consumer writes to a relational database. The limitation is long-term growth: the processed_payments table grows forever unless you partition and purge old entries. Redis SET NX with TTL is faster and has built-in expiry, but is not transactional with the database write - if Redis says it is new but the DB write fails, the Redis key remains set and the next retry is incorrectly skipped. Fix by deleting the Redis key on failure. Use Redis when the consumer writes to non-relational systems or when the volume makes database dedup too slow. Kafka transactions vs idempotency: Kafka transactions are for Kafka-to-Kafka exactly-once where you want broker-level enforcement. Idempotency keys are for external systems. For most practical workloads, idempotency keys are simpler and cover more cases."

#### Scenario
- "Your order service sends emails from Kafka events and users are getting duplicate emails - how do you fix it?"
- "How do you implement idempotency in a multi-step saga that creates an order, reserves inventory, and charges payment?"

🗣️ "Duplicate emails: add an email-sent deduplication store. Each order confirmation email event carries the orderId and an event type. Before sending, check Redis (or a DB table): has_email_been_sent(orderId, 'order_confirmation'). If yes, skip. If no, send and record. Use a Redis key with TTL of 7 days - longer than the Kafka retention window. For the multi-step saga: each step needs its own idempotency. The saga orchestrator tracks which steps have completed for each orderId. On retry after a crash, it re-reads the saga state, finds the completed steps, and only re-executes the incomplete ones. The inventory reservation step checks whether the reservation already exists. The payment charge step passes the orderId as the idempotency key to the payment API. Each step must be safe to re-execute independently."

#### Debugging
- "How do you detect whether duplicate processing is occurring in a production consumer?"
- "An idempotency check is in place but users still report doubles - what do you investigate?"

🗣️ "Detecting duplicate processing: add a counter metric that increments when the deduplication guard fires. If this counter is zero in production, either no retries are happening (unlikely) or the deduplication code path is not being reached. For order data, compare your processed event count against the unique message ID count - if processed events > unique message IDs, duplication is occurring. Still reporting doubles with idempotency in place: the most common causes I have seen are: (1) the idempotency key is not unique per logical operation - two messages for the same order have the same key, but they are different operations (order.created vs order.updated); (2) the check and the write are not atomic - check passes, application crashes, next retry passes again; (3) the idempotency store has insufficient TTL and the key expired before the message retention window expired, allowing a redelivered message to bypass deduplication."

#### Deep Dive
- "How do you handle idempotency for operations that interact with external APIs that do not support idempotency keys?"
- "What is the difference between idempotent consumers and saga compensating transactions?"

🗣️ "For external APIs without idempotency support: use an application-level surrogate. Before calling the API, write your intent to a local database with a unique constraint. If you find a record already exists, skip the API call. If no record exists, insert the record and make the API call in sequence - not atomically. The gap between record insertion and API call is an at-most-once window: if you crash there, the record shows it was processed but the API was not called. You need to detect this orphaned state and handle it during recovery. Versus saga compensating transactions: idempotency prevents duplicate forward execution of the same operation. Compensating transactions reverse a successfully executed operation when a later step fails. They are complementary, not alternatives. A saga needs both: idempotency to handle retries of forward steps, and compensating transactions to undo completed steps when the overall saga must abort."

#### Misconception / Trap
- "If I use UUIDs as idempotency keys, I am protected from all duplicate processing issues, right?"
- "Idempotency means my consumer is safe to run in parallel - multiple instances can process the same message simultaneously, right?"

🗣️ "Both wrong. UUIDs protect against duplicates only if the UUID uniquely identifies the business operation AND the check-and-write is atomic. If two message redeliveries use the same UUID but the check happens concurrently in two consumer instances before either writes, both pass the check and both execute the operation. The unique constraint in the database prevents this, but only if you use it and include the right column combination. On parallelism: idempotency means multiple sequential executions produce the same result. It says nothing about concurrent execution. Running two consumer instances simultaneously against the same message without the unique constraint protection causes both to pass the check and both to write. Idempotency solves sequential duplicates; your database's uniqueness constraints solve concurrent duplicates."

#### Performance & Scalability
- "How do you scale idempotency deduplication to 100,000 messages per second?"
- "What is the deduplication store's impact on consumer throughput?"

🗣️ "At 100,000 messages per second with a 7-day TTL: the dedup store holds approximately 60 billion entries. A database unique constraint does not scale here - the lookup time and storage cost are prohibitive. Redis clusters can handle this with memory-efficient key designs. Use a compact key format: base64-encoded message ID. Redis Bloom filter (RedisBloom module) can serve as a probabilistic dedup check - memory-efficient, O(1) lookup, but with a configurable false-positive rate. For financial systems, false positives (incorrectly thinking a message was processed when it was not) are unacceptable - use exact dedup. For analytics or notifications, a 0.01% false positive rate may be acceptable. Throughput impact: a Redis SET NX adds 0.5-2ms of latency per message check. At 100,000 messages/sec, Redis must handle 100,000 SET NX operations per second - achievable with a Redis cluster of 3-5 nodes."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with atomicity requirement - check and write must be in same transaction |
| Hiring Manager | Lead with: idempotency is a correctness requirement for at-least-once delivery |
| Bar Raiser | Lead with: partial idempotency failure in multi-step operations |
| Peer Engineer | "The pattern I always add: dedup counter metric to detect whether the guard is actually firing" |

---

### ⚖️ Comparison

| Approach | Atomicity | Scale | TTL Support | External System Support |
|---|---|---|---|---|
| DB unique constraint | Strong (transactional) | Moderate (DB-bound) | Via partition/purge | No |
| Processed events table | Strong (transactional) | Moderate | Via cleanup job | No |
| Redis SET NX + TTL | Weak (not with DB write) | High (Redis cluster) | Native | Yes |
| Kafka transactions | Strong (broker-level) | High (Kafka-native) | Kafka retention | Kafka only |
| Natural idempotency | N/A (no guard needed) | Unlimited | N/A | Yes |

**The deciding factor:** If writing to a relational database, use DB unique constraint for atomicity. If writing to external systems or needing high throughput, use Redis with explicit failure handling. If Kafka-to-Kafka pipeline, use Kafka transactions.

---

### 🔥 Field Q&A

#### Production Failures

Q: A consumer processed 10,000 payment credits correctly but after a deployment, 500 were double-applied. What failed?

A: The deployment changed the idempotency key format or field. If the new code generates a different key for the same logical event - say, old code used paymentId, new code uses orderId+amount - the dedup store sees different keys and treats redelivered messages as new. Check: compare the idempotency key format in old and new code. Also check: was the dedup store cleared during deployment? If the processed_payments table was truncated as part of the migration, all historical messages would re-pass the dedup check.

Q: Consumer lag spiked from 100 to 500,000 messages during a Redis failover. After Redis recovered, some payments were credited twice. How?

A: During the Redis outage, the idempotency check failed or was bypassed (depends on error handling). If the consumer was configured to fail-safe (skip Redis check on error, process anyway), messages were processed without dedup guards. When Redis recovered, its data was stale or reset - it did not know about messages processed during the outage. All messages redelivered after the spike re-passed the dedup check. Fix: configure Redis check to fail-closed during outage (skip processing, not just the check), or use database dedup as fallback when Redis is unavailable.

Q: An order processing system intermittently creates duplicate orders. The idempotency key is the Kafka message offset. What is wrong?

A: Kafka message offsets are not stable idempotency keys. When a topic is compacted, offsets change. When messages are replayed from DLQ to the original topic, they get new offsets. When a consumer reprocesses from the beginning (offset reset), the same business event has the same offset but the dedup store may have expired. The idempotency key must be derived from the business event content - the orderId from the message payload - not from broker metadata like offset.

#### Candidate Mistakes

Q: What is the wrong way to describe idempotency to an interviewer?

**What NOT to say:** "Idempotency means the system can handle failures." 
**Say instead:** "Idempotency means each message produces exactly one state change regardless of how many times it is delivered. It is the property that makes at-least-once delivery correct for stateful operations."

Q: What do candidates typically get wrong about idempotency key placement?

**What NOT to say:** "I would use the Kafka message offset as the idempotency key." 
**Say instead:** "The idempotency key must be derived from the business content of the message - typically a business transaction ID or event ID generated by the producer. Broker metadata like offsets can change during compaction, replay, or topic recreation."

Q: What is the common mistake in multi-step idempotency?

**What NOT to say:** "I would make step one idempotent - that's enough." 
**Say instead:** "Every step that changes external state must have its own idempotency guard. If step one is idempotent and step two is not, a crash between them causes step two to execute twice on retry. I track per-step completion state or use natural idempotency where possible."

#### Questions to Ask the Interviewer

Q: "How does your team handle the TTL for idempotency deduplication stores?"

*Why:* Reveals whether the team has thought through long-term dedup store growth and what happens when TTL expires before a redelivery occurs.
*If asked back:* "I recommend setting TTL to at least the Kafka message retention window plus the maximum time to investigate and replay a DLQ message - often 7-14 days."

Q: "Is there a natural business key in your events that can serve as the idempotency key, or does the team rely on broker-generated identifiers?"

*Why:* Business keys are more stable and meaningful than broker metadata; this question signals architectural maturity.
*If asked back:* "I prefer business-generated UUIDs assigned at event creation time, propagated through all events derived from that business operation."

#### Live Coding Context

Coding question template: "Implement an idempotent Kafka consumer that processes payment events and credits accounts. Handle the case where the consumer may crash between any two operations."

What the interviewer watches:
- Whether the candidate includes a deduplication check before the credit
- Whether the check and credit are inside the same database transaction
- Whether the Kafka offset is committed after the database transaction, not before

Most common implementation mistake: Acknowledging the Kafka offset before the database commit, or not including the idempotency check at all.

*Why this signals:* Candidates who understand delivery semantics naturally include the guard. Those who have only used fire-and-forget messaging do not think about redelivery.
