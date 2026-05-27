---
layout: default
title: "Messaging - L2 RabbitMQ and Patterns"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 4
permalink: /messaging/l2-rabbitmq-patterns/
---

# RabbitMQ Exchanges and Routing

🎯 Interview Weight: high - RabbitMQ routing model is the
defining feature that differentiates it from Kafka.

---

### 🎯 Model Answer

**30 seconds:**
> RabbitMQ routing works through exchanges. Producers publish
> to an exchange. The exchange routes to one or more queues
> based on bindings. Exchange types: direct (routing key
> exact match), fanout (broadcast), topic (wildcard match),
> headers (attribute match). Consumers subscribe to queues,
> not topics. This gives more flexible routing than Kafka but
> less throughput and no message replay.

**3 minutes (Senior):**
> Exchange and routing patterns:
>
> Direct exchange - unicast:
> Binding: `queue.payment` bound to exchange with key "payment".
> Message with routing key "payment" -> goes to `queue.payment`.
> Message with routing key "notification" -> goes to `queue.notification`.
> Use case: work distribution to dedicated queues.
>
> Fanout exchange - broadcast:
> All bound queues receive every message.
> No routing key used (ignored if provided).
> Use case: notification fan-out. OrderPlaced goes to
> payment.queue, inventory.queue, email.queue simultaneously.
> Each queue is independent - consumer lag in one does not
> affect others.
>
> Topic exchange - pattern matching:
> Routing key: dot-separated words (`order.placed.us`).
> Binding keys: `order.*` matches `order.placed` but not
> `order.placed.us` (single word). `order.#` matches any
> suffix.
> Use case: multi-tenant or multi-region routing.
> `order.#.us` -> US-specific order queue.
> `order.#` -> all-orders queue.
>
> Default exchange:
> Every queue is implicitly bound to the default exchange
> with the queue name as routing key.
> `channel.basicPublish("", "my-queue", ...)` publishes
> directly to `my-queue`. Simple for point-to-point.
>
> Dead-letter exchange (DLX):
> Queue configured with a DLX. Messages that are rejected
> (NACK with requeue=false), expire (TTL), or exceed max-length
> are forwarded to the DLX -> routed to dead-letter queue.

**Blank Mind Recovery:**

**(1) Restate:** "RabbitMQ: producer -> exchange -> queue -> consumer.
Exchange type = routing logic. Direct = exact key. Fanout = all queues."

---

### 💻 Code Example

```java
// Spring AMQP - fanout exchange for order events

@Configuration
public class RabbitMQConfig {

    @Bean
    public FanoutExchange orderExchange() {
        // durable=true - survives broker restart
        return new FanoutExchange("order.events", true, false);
    }

    @Bean
    public Queue paymentQueue() {
        return QueueBuilder.durable("payment.queue")
            .withArgument("x-dead-letter-exchange", "dlx.exchange")
            .withArgument("x-message-ttl", 3600000) // 1hr TTL
            .build();
    }

    @Bean
    public Queue inventoryQueue() {
        return QueueBuilder.durable("inventory.queue")
            .withArgument("x-dead-letter-exchange", "dlx.exchange")
            .build();
    }

    @Bean
    public Binding paymentBinding(
        FanoutExchange orderExchange,
        Queue paymentQueue
    ) {
        return BindingBuilder.bind(paymentQueue)
            .to(orderExchange);
    }
}

// Producer: publish to fanout exchange
@Component
public class OrderEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    public void publishOrderPlaced(Order order) {
        rabbitTemplate.convertAndSend(
            "order.events",  // exchange name
            "",              // routing key (ignored for fanout)
            order
        );
    }
}
```

> **Code walkthrough:** The `FanoutExchange` sends every
> published message to all bound queues simultaneously.
> Each queue (`paymentQueue`, `inventoryQueue`) is independently
> durable and configured with its own dead-letter exchange.
> The `x-message-ttl` on paymentQueue means messages expire
> after 1 hour if the payment consumer is down - preventing
> stale orders from being processed. The producer publishes
> once to the exchange; RabbitMQ handles fan-out internally.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Exchange types + binding configuration |
| Senior | 8 min | Fan-out topology + DLX configuration |

---

---

# Dead Letter Queues and Retry

🎯 Interview Weight: very high - DLQ is a critical production
pattern for handling message processing failures.

---

### 🎯 Model Answer

**30 seconds:**
> A Dead Letter Queue (DLQ) receives messages that could not be
> processed successfully. Messages move to DLQ when: they are
> rejected (NACK without requeue), exceed TTL, or exceed the
> queue's max-length. Retry patterns: immediate retry (requeue),
> delayed retry (using retry queue with TTL), exponential backoff
> (increasing delay queues). After N retries: send to DLQ for
> manual inspection or alerting.

**3 minutes (Senior):**
> DLQ implementation in RabbitMQ:
>
> Simple DLQ setup:
> Queue A configured with `x-dead-letter-exchange=dlx.exchange`.
> Consumer NACKs with requeue=false.
> Message -> DLX -> DLQ.
> DLQ: separate queue for failed messages.
> Monitoring: alert when DLQ depth > 0 (PagerDuty, Prometheus).
>
> Retry with delay (using TTL + DLX):
> Queue flow: main.queue -> retry.queue (30s TTL) -> main.queue.
>
> Message processing fails in main.queue consumer.
> Consumer NACKs with requeue=false.
> Message moves to DLX -> retry.queue (configured with 30s TTL).
> After 30 seconds: message expires from retry.queue.
> Retry queue's DLX points back to main.queue.
> Message reappears in main.queue for retry.
> After N retries: forward to permanent DLQ.
>
> Retry count tracking:
> Add a `x-retry-count` header to the message.
> Increment on each reroute (custom consumer logic or Shovel plugin).
> When count > maxRetries: send to final DLQ instead of retry queue.
>
> DLQ in Kafka:
> No native DLQ. Pattern: on unrecoverable exception, producer
> sends message to `<topic>.dlq` topic. Spring Kafka:
> `@RetryableTopic` with `dltTopicSuffix="-dlt"`.
> Kafka DLQ message includes original topic, partition, offset,
> exception type, and stack trace as headers.

**Blank Mind Recovery:**

**(1) Restate:** "DLQ: final destination for unprocessable messages.
Retry queue: delay + reroute back to main queue. Alert on DLQ depth > 0."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | DLQ concept + basic setup |
| Senior | 7 min | Retry with delay pattern + retry count + Kafka DLQ |

---

---

# Message Acknowledgment Patterns

🎯 Interview Weight: high - ACK patterns are the basis of
delivery guarantee selection.

---

### 🎯 Model Answer

**30 seconds:**
> RabbitMQ acknowledgment modes: auto-ack (message deleted on
> delivery, at-most-once), manual-ack (consumer calls basicAck
> after processing, at-least-once), transaction (wraps multiple
> operations in a transaction, at-exactly-once within one broker).
> Spring AMQP: `@RabbitListener` with `containerFactory` configured
> for `AcknowledgeMode.MANUAL`. Acknowledge via the `Channel`
> parameter or `Message` header.

**3 minutes (Senior):**
> Acknowledgment mechanics and pitfalls:
>
> Auto-ack (AcknowledgeMode.NONE):
> Message is acked as soon as delivered to consumer.
> Consumer receives 1000 messages and crashes while processing
> message 5. Messages 6-1000 are lost.
> Use case: non-critical, high-throughput, loss-tolerant.
>
> Manual ack (AcknowledgeMode.MANUAL):
> Consumer calls `ack.acknowledge()` only after successful processing.
> Consumer receives 1000 messages, processes 5, crashes.
> Messages 6-1000 return to queue (unacked, will be redelivered).
> Message 5 might be redelivered if crash happened after processing
> but before ack. Make processing idempotent.
>
> Bulk acknowledgment:
> `channel.basicAck(deliveryTag, multiple=true)`: ack all
> unacknowledged messages up to this delivery tag.
> Efficient: one network round-trip for N messages.
> Risk: one processing failure means you may bulk-ack messages
> you haven't processed yet.
>
> Negative acknowledgment patterns:
> `basicNack(deliveryTag, requeue=true)`: message returns to
> queue HEAD (immediate retry). Risk: hot loop if message
> always fails.
> `basicNack(deliveryTag, requeue=false)`: message goes to DLQ
> (if configured). Correct pattern for unrecoverable errors.
>
> Channel-per-consumer pattern:
> Best practice: one Channel per consumer thread.
> Channel is not thread-safe. Sharing channels across threads
> causes race conditions in acknowledgment.

**Blank Mind Recovery:**

**(1) Restate:** "Auto-ack: fast, may lose. Manual-ack: safe,
must be idempotent. NACK+requeue: retry. NACK+no-requeue: DLQ."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | ACK modes + trade-offs |
| Senior | 7 min | Bulk ACK + NACK patterns + channel thread safety |

---

---

# Poison Message Handling

🎯 Interview Weight: high - Poison messages cause consumer
loops in production. Critical pattern.

---

### 🎯 Model Answer

**30 seconds:**
> A poison message is one that always fails processing (bad data,
> schema mismatch, code bug). Without handling: it is rejected,
> returned to queue, processed again, rejected - infinite retry
> loop consuming 100% of consumer CPU. Solution: detect
> after N failures and route to DLQ. Kafka: `@RetryableTopic`
> with max attempts. RabbitMQ: retry count header + DLQ.

**3 minutes (Senior):**
> Poison message detection strategies:
>
> RabbitMQ - x-death header:
> When a message is routed to DLX, RabbitMQ adds an `x-death`
> header containing: the source queue, reason (rejected/expired),
> and a count. Consumer can inspect this header to detect
> message retry count.
> Check `x-death[0].count` - if > maxRetries: send to permanent DLQ.
>
> Kafka - @RetryableTopic (Spring):
> `@RetryableTopic(attempts=4)`: on failure, message is sent
> to `topic-retry-0`, then `topic-retry-1`, etc. After 4 attempts:
> message sent to `topic-dlt` (dead letter topic).
> DLT message headers contain: original topic, original partition,
> original offset, exception class, exception message.
> DLT consumer can inspect and alert or replay.
>
> Poison message in Kafka (consumer commits stale offset):
> Consumer fetches message. Deserialization fails (schema mismatch).
> Exception thrown before processing. Spring Kafka by default
> commits the offset anyway (moves past the poison message).
> This silently drops messages.
> Fix: configure `ErrorHandler` to send to DLT instead of
> committing and skipping.
>
> Spring Kafka DefaultErrorHandler:
> Retries N times with backoff.
> After maxAttempts: forwards to dead letter topic.
> Crucially: does not seek past the message until DLT send succeeds.

**Blank Mind Recovery:**

**(1) Restate:** "Poison message = always fails = retry loop.
Detect via retry count or x-death header. Route to DLQ after N retries."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Poison message concept + retry loop risk |
| Senior | 7 min | x-death header + @RetryableTopic + deserialization errors |

---

---

# Message TTL Priority and Expiry

🎯 Interview Weight: medium - TTL and priority are advanced
queue features used in production scheduling.

---

### 🎯 Model Answer

**30 seconds:**
> Message TTL (Time-To-Live): a message is discarded (or moved to DLQ)
> if not consumed within the TTL period. Set per-queue
> (`x-message-ttl`) or per-message (`expiration` property).
> Use case: time-sensitive notifications (order confirmation email
> valid for 24 hours only). Priority queues: assign higher-priority
> messages a higher priority value. Broker delivers higher-priority
> messages first. RabbitMQ: `x-max-priority` on queue (1-255).

**3 minutes (Senior):**
> TTL patterns:
>
> Queue-level TTL (`x-message-ttl=86400000` = 24h):
> All messages in the queue expire after 24 hours.
> Useful: time-bounded processing (notification queue where
> stale messages are irrelevant).
> When TTL expires: if DLX configured -> moves to DLQ.
> Otherwise: silently discarded.
>
> Per-message TTL (`expiration` property):
> Individual message can have different TTL.
> Useful: messages with varying urgency.
> Caveat: per-message TTL is checked lazily (only when message
> reaches queue head). A long queue may deliver expired messages.
> Queue-level TTL is more efficient (enforced on arrival).
>
> Priority queues:
> `x-max-priority=10`: queue supports priorities 0-10.
> Producer sets `AMQP.BasicProperties.priority=8` for high-priority.
> RabbitMQ delivers higher-priority messages first.
> Use case: premium customers' orders processed before standard.
>
> Priority anti-pattern: priority inversion.
> Low-priority messages arrive in bursts at high priority.
> Legitimate high-priority messages starve if the queue is
> flooded with falsely elevated priorities. Solution: separate
> queues for different priorities with separate consumer pools.

**Blank Mind Recovery:**

**(1) Restate:** "TTL: expire stale messages. Priority: high-priority
processed first. Both prevent stale or low-value work."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 3 min | TTL per-queue vs per-message |
| Senior | 5 min | Priority queues + anti-patterns |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Exchange routing + DLQ setup |
| System Design | Retry patterns + poison message handling |
| Bar Raiser | Priority inversion + TTL production scenarios |
