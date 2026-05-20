---
layout: default
title: "Microservices - Observability"
parent: "Microservices"
grand_parent: "Interview Mastery"
nav_order: 7
permalink: /interview/microservices/observability/
topic: Microservices
subtopic: Observability
keywords:
  - Distributed Logging
  - Correlation ID
  - OpenTelemetry
  - Chaos Engineering
  - Cross-Cutting Concerns
  - Observability Architecture
difficulty_range: medium to hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Distributed Logging](#distributed-logging)
- [Correlation ID](#correlation-id)
- [OpenTelemetry](#opentelemetry)
- [Chaos Engineering](#chaos-engineering)
- [Cross-Cutting Concerns](#cross-cutting-concerns)
- [Observability Architecture](#observability-architecture)

# Distributed Logging

**TL;DR** - In microservices, a single user request traverses multiple services. Distributed logging aggregates logs from all services into a centralized system (ELK, Loki, CloudWatch) so you can trace a request end-to-end using a correlation ID. Without it, debugging requires SSH-ing into 10 different servers and grepping logs manually.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Distributed Logging was created."

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
Collect all logs from all services into one place. Search for a request ID and see what happened across every service it touched.

**Level 2 - How to use it (junior developer):**

```
Without centralized logging:
  Order Service logs to /var/log/order.log
  Payment Service logs to /var/log/payment.log
  Shipping Service logs to /var/log/shipping.log
  Debugging: SSH into 3 servers, grep each file

With centralized logging:
  All services -> [Log Aggregator (ELK/Loki)]
  Search: correlationId = "abc-123"
  See all logs from all services for that request
```

**Structured logging (JSON):**

```java
// BAD: Unstructured log
log.info("Order placed for user " + userId
    + " total " + total);
// Output: "Order placed for user 42 total 99.99"
// Can't search by userId or total

// GOOD: Structured log (JSON)
log.info("Order placed",
    kv("userId", userId),
    kv("orderId", orderId),
    kv("total", total),
    kv("correlationId", correlationId));
// Output: {"msg":"Order placed","userId":42,
//   "orderId":"ORD-123","total":99.99,
//   "correlationId":"abc-123"}
// Searchable, filterable, aggregatable
```

**Level 3 - How it works (mid-level engineer):**

**Logging stack options:**

| Stack          | Components                        | Best For                          |
| -------------- | --------------------------------- | --------------------------------- |
| ELK            | Elasticsearch + Logstash + Kibana | Full-text search, dashboards      |
| EFK            | Elasticsearch + Fluentd + Kibana  | Kubernetes-native                 |
| Loki + Grafana | Loki (label-indexed) + Grafana    | Cost-effective, Grafana ecosystem |
| CloudWatch     | AWS native                        | AWS workloads                     |
| Datadog        | SaaS                              | Full observability platform       |

**Log levels in production:**

```
ERROR: Something broke. Needs attention.
WARN:  Something unexpected. Might need attention.
INFO:  Business event occurred (order placed, etc.)
DEBUG: Only enable temporarily for debugging.

Rule: Production runs at INFO level.
  Enable DEBUG per-service/per-class dynamically
  (Spring Boot Actuator: POST /loggers/com.myapp)
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Log volume management:**

- 50 microservices _ 1000 req/s _ 5 log lines = 250K log lines/second
- At 500 bytes/line = 125 MB/second = 10 TB/day
- Retention: 7-30 days for detailed, 1 year for aggregated

**Strategies:**

1. **Sampling:** Log 100% of errors, 10% of successful requests
2. **Dynamic log levels:** Normal = INFO. During incident = DEBUG for affected service
3. **Tiered retention:** Hot (7 days, fast search) -> Warm (30 days, slow search) -> Cold (1 year, S3 archive)




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

[TODO: Include if 2+ named alternatives exist for Distributed Logging. Otherwise remove this section.]
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

**Q1: A user reports their order is stuck. How do you trace the request across 5 microservices?**

_Why they ask:_ Tests practical debugging approach.

_Strong answer:_

1. **Get the order ID from the user.** Search centralized logs for `orderId = "ORD-456"`.
2. **Find the correlation ID.** First log entry shows `correlationId = "abc-123"`.
3. **Search all logs by correlation ID.** See the full journey:
   ```
   10:00:01 [Order]    OrderReceived    abc-123
   10:00:02 [Inventory] StockReserved   abc-123
   10:00:03 [Payment]   ChargeAttempted  abc-123
   10:00:03 [Payment]   ChargeDeclined   abc-123
   10:00:04 [Order]    PaymentFailed    abc-123
   ```
4. **Root cause:** Payment was declined. But Order Service never updated the order status (bug: missing event handler for PaymentFailed).
5. **Fix:** Add PaymentFailed handler that sets order status to PAYMENT_FAILED and notifies the user.
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

# Correlation ID

**TL;DR** - A Correlation ID is a unique identifier assigned at the system entry point and propagated through every service call, event, and log entry for a single user request. It's the thread that ties distributed logs together and makes end-to-end tracing possible.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Correlation ID was created."

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
A tracking number for your request. Like a FedEx tracking number - follow it through every facility (service) until delivery.

**Level 2 - How to use it (junior developer):**

```java
// API Gateway generates correlation ID
@Component
public class CorrelationIdFilter
        implements Filter {

    public void doFilter(ServletRequest req,
            ServletResponse res, FilterChain chain) {
        HttpServletRequest httpReq =
            (HttpServletRequest) req;
        String correlationId = httpReq
            .getHeader("X-Correlation-ID");
        if (correlationId == null) {
            correlationId = UUID.randomUUID()
                .toString();
        }
        MDC.put("correlationId", correlationId);
        chain.doFilter(req, res);
        MDC.remove("correlationId");
    }
}

// Propagate to downstream calls
@Bean
public RestTemplate restTemplate() {
    RestTemplate template = new RestTemplate();
    template.getInterceptors().add((req, body, exec)
        -> {
        req.getHeaders().add("X-Correlation-ID",
            MDC.get("correlationId"));
        return exec.execute(req, body);
    });
    return template;
}
```

**Level 3 - How it works (mid-level engineer):**

**Propagation across communication styles:**

| Communication | Propagation                         |
| ------------- | ----------------------------------- |
| REST/gRPC     | HTTP header: `X-Correlation-ID`     |
| Kafka         | Message header: `correlationId`     |
| RabbitMQ      | Message properties: `correlationId` |
| Thread pools  | Copy MDC context to new threads     |

**MDC (Mapped Diagnostic Context):**

```java
// MDC is thread-local storage for log context
MDC.put("correlationId", "abc-123");
MDC.put("userId", "42");

// logback-spring.xml pattern
// %X{correlationId} %X{userId} %msg%n

// Every log line automatically includes:
// abc-123 42 Order placed
// abc-123 42 Payment processed
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Correlation ID vs Trace ID (OpenTelemetry):**

| Aspect         | Correlation ID          | Trace ID (OTel)          |
| -------------- | ----------------------- | ------------------------ |
| Scope          | Business request        | Technical trace          |
| Generated by   | Application code        | Tracing library          |
| Survives async | Must propagate manually | Auto-propagated by SDK   |
| Standard       | Custom header           | W3C Trace Context        |
| Visualization  | Log search              | Trace waterfall (Jaeger) |

Best practice: Use both. Correlation ID for business tracing. Trace ID for performance analysis.




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

[TODO: Include if 2+ named alternatives exist for Correlation ID. Otherwise remove this section.]
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

**Q1: How do you ensure the correlation ID survives async operations (Kafka, thread pool)?**

_Why they ask:_ Tests understanding of context propagation challenges.

_Strong answer:_

**Problem:** MDC is thread-local. When you publish to Kafka or submit to a thread pool, the new thread doesn't have the MDC context.

**Solutions:**

1. **Kafka producer:** Copy correlation ID to message header before publishing
2. **Kafka consumer:** Extract from message header, set in MDC before processing
3. **Thread pool:** Use MDC-aware executor that copies context to child threads

```java
// Kafka: propagate via headers
kafkaTemplate.send(
    new ProducerRecord<>("topic", key, value)
        .headers()
        .add("correlationId",
            MDC.get("correlationId").getBytes()));

// Thread pool: MDC-aware executor
ExecutorService mdcExecutor =
    new MDCExecutorService(
        Executors.newFixedThreadPool(10));
// Automatically copies MDC to child threads
```
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

# OpenTelemetry

**TL;DR** - OpenTelemetry (OTel) is the vendor-neutral standard for collecting traces, metrics, and logs from microservices. It provides auto-instrumentation (zero-code) and manual instrumentation APIs. Data is exported to backends like Jaeger, Prometheus, Grafana, or Datadog.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why OpenTelemetry was created."

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
A universal adapter for observability. Instrument your code once with OTel, then send data to any backend (Jaeger, Datadog, Grafana). Switch backends without changing application code.

**Level 2 - How to use it (junior developer):**

**Three pillars of observability:**

| Pillar  | What                         | OTel Support                       |
| ------- | ---------------------------- | ---------------------------------- |
| Traces  | Request path across services | Full (auto + manual)               |
| Metrics | Counters, gauges, histograms | Full (auto + manual)               |
| Logs    | Structured log events        | Evolving (correlation with traces) |

```
Request flow with OTel:
  User -> API Gateway [Span 1: gateway]
    -> Order Service [Span 2: order-create]
      -> DB query [Span 3: postgres.query]
      -> Payment Service [Span 4: payment-charge]
    <- Response

Trace = all 4 spans linked by trace ID
Visualized as waterfall in Jaeger/Zipkin
```

**Level 3 - How it works (mid-level engineer):**

```java
// Java auto-instrumentation (zero code change)
// Just add the agent:
// java -javaagent:opentelemetry-javaagent.jar
//   -jar myapp.jar
// Auto-instruments: Spring, JDBC, Kafka, gRPC,
//   HTTP clients, etc.

// Manual instrumentation for custom spans
Tracer tracer = GlobalOpenTelemetry.getTracer(
    "order-service");

Span span = tracer.spanBuilder("process-order")
    .setAttribute("order.id", orderId)
    .setAttribute("order.total", total)
    .startSpan();
try (Scope scope = span.makeCurrent()) {
    // Business logic here
    processOrder(order);
} catch (Exception e) {
    span.setStatus(StatusCode.ERROR);
    span.recordException(e);
    throw e;
} finally {
    span.end();
}
```

**OTel Collector architecture:**

```
Services -> [OTel Collector]
              |    |    |
          [Jaeger] [Prometheus] [Loki]
              (traces) (metrics)  (logs)

Collector handles:
  - Receiving (OTLP, Jaeger, Zipkin formats)
  - Processing (sampling, filtering, enriching)
  - Exporting (to any backend)
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Sampling strategies (critical for cost):**
| Strategy | How | Use When |
|----------|-----|----------|
| Head-based | Decide at start: trace 10% of requests | High volume, cost-sensitive |
| Tail-based | Collect all, decide after: keep errors + slow | Need all error traces |
| Adaptive | Adjust rate based on traffic volume | Variable load patterns |

**Production setup:**

```yaml
# OTel Collector config
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
processors:
  batch:
    send_batch_size: 1024
    timeout: 5s
  tail_sampling:
    policies:
      - name: errors
        type: status_code
        status_code: { status_codes: [ERROR] }
      - name: slow
        type: latency
        latency: { threshold_ms: 2000 }
      - name: sample-rest
        type: probabilistic
        probabilistic: { sampling_percentage: 10 }
exporters:
  jaeger:
    endpoint: jaeger:14250
  prometheus:
    endpoint: 0.0.0.0:8889
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

[TODO: Include if 2+ named alternatives exist for OpenTelemetry. Otherwise remove this section.]
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

**Q1: Your tracing shows a request taking 3 seconds, but individual spans total only 500ms. Where's the missing 2.5 seconds?**

_Why they ask:_ Tests practical trace analysis.

_Strong answer:_

**Possible causes for uninstrumented time:**

1. **Uninstrumented code:** Business logic between instrumented calls (missing spans). Add custom spans.
2. **Thread pool queue wait:** Request waiting in a thread pool queue (not in any span). Add span for queue wait time.
3. **Connection pool wait:** Waiting for a database or HTTP connection from pool. Enable connection pool instrumentation.
4. **DNS resolution:** First call to a service involves DNS lookup. Not instrumented by default.
5. **Serialization/deserialization:** Large payloads take time to marshal. Not typically instrumented.
6. **GC pause:** A garbage collection pause doesn't show in any span but adds to total time.

**Diagnosis:** Look at the trace waterfall. The gap between span end and next span start is the uninstrumented time. Add spans to cover that gap.
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

# Chaos Engineering

**TL;DR** - Chaos Engineering is the discipline of experimenting on a production system to build confidence in its ability to handle failures. Deliberately inject failures (kill pods, add latency, corrupt network) and verify the system degrades gracefully. "If you don't test failure in production, production will test it for you."
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Chaos Engineering was created."

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
Break things on purpose (in a controlled way) to find weaknesses before real failures find them. Like a fire drill for your system.

**Level 2 - How to use it (junior developer):**

**Common chaos experiments:**

| Experiment         | What You Inject                | What You Learn                                   |
| ------------------ | ------------------------------ | ------------------------------------------------ |
| Pod kill           | Kill random pod                | Does K8s restart it? Do users see errors?        |
| Latency injection  | Add 5s delay to network calls  | Do circuit breakers trigger? Do timeouts work?   |
| CPU stress         | Max out CPU on one node        | Does auto-scaling kick in?                       |
| Dependency failure | Kill database connection       | Does fallback work? Does health check detect it? |
| Network partition  | Block traffic between services | Does the system degrade gracefully?              |

**Level 3 - How it works (mid-level engineer):**

**Chaos Engineering process:**

```
1. Define steady state (normal behavior)
   "P99 latency < 500ms, error rate < 0.1%"

2. Form hypothesis
   "If we kill 1 of 3 Payment pods,
    error rate stays below 0.5%"

3. Run experiment
   Kill 1 Payment pod during business hours

4. Observe
   Error rate spiked to 2% for 30 seconds
   Circuit breaker opened at T+10s
   Traffic rerouted to 2 remaining pods
   Error rate back to 0.1% at T+30s

5. Learn & fix
   30s of 2% errors = circuit breaker too slow
   Fix: Reduce sliding window from 10 to 5 calls
```

**Tools:**
| Tool | Platform | Features |
|------|----------|----------|
| Chaos Monkey (Netflix) | Cloud VMs | Random instance termination |
| Litmus Chaos | Kubernetes | Pod, network, disk, DNS chaos |
| Chaos Mesh | Kubernetes | Time skew, I/O fault, kernel fault |
| Gremlin | SaaS/Multi | Enterprise, safety controls |
| AWS Fault Injection Service | AWS | Native AWS resource chaos |

**Level 4 - Mastery (senior/staff+ engineer):**

**Chaos maturity model:**

1. **Level 1:** Kill pods in staging, verify restart
2. **Level 2:** Kill pods in production, verify graceful degradation
3. **Level 3:** Network partition between services, verify circuit breakers
4. **Level 4:** Multi-AZ failure simulation, verify cross-AZ failover
5. **Level 5:** Continuous chaos in production (GameDay culture)
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

[TODO: Include if 2+ named alternatives exist for Chaos Engineering. Otherwise remove this section.]
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

**Q1: Your team wants to start chaos engineering. What's your plan for the first 90 days?**

_Why they ask:_ Tests practical implementation planning.

_Strong answer:_

**Days 1-30: Foundation**

1. Ensure all services have health checks, circuit breakers, and timeouts
2. Set up monitoring dashboards with clear steady-state metrics
3. Run chaos experiments in staging only (build confidence and tooling)

**Days 31-60: Production experiments** 4. Start with low-risk: kill one pod of a stateless service during low traffic 5. Graduate to: add latency to one downstream dependency 6. Document all experiments: hypothesis, results, fixes

**Days 61-90: Automation** 7. Schedule recurring experiments (weekly pod kills) 8. Add chaos tests to CI/CD pipeline (staging gate) 9. Run first "GameDay" (coordinated multi-failure scenario with the team)

**Key principle:** Never run chaos experiments without monitoring and a rollback plan. The goal is learning, not breaking things.
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

# Cross-Cutting Concerns

**TL;DR** - Cross-cutting concerns are functionalities needed by every service: logging, authentication, tracing, rate limiting, error handling, configuration. Instead of implementing them in each service, centralize them in shared libraries, API gateways, or service mesh sidecars.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Cross-Cutting Concerns was created."

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
Things every service needs but that aren't part of the service's core business. Logging, security, monitoring - these "cut across" all services.

**Level 2 - How to use it (junior developer):**

| Concern          | Options                                     |
| ---------------- | ------------------------------------------- |
| Authentication   | API Gateway (centralized)                   |
| Authorization    | Each service (business rules)               |
| Logging          | Shared library + centralized aggregator     |
| Tracing          | OTel auto-instrumentation agent             |
| Rate limiting    | API Gateway or service mesh                 |
| Circuit breaking | Shared library (Resilience4j)               |
| Configuration    | Config server (Spring Cloud Config, Consul) |
| Health checks    | Shared library (Spring Actuator)            |

**Level 3 - How it works (mid-level engineer):**

**Implementation strategies:**

| Strategy             | Mechanism                              | Pros                              | Cons                     |
| -------------------- | -------------------------------------- | --------------------------------- | ------------------------ |
| Shared library       | Maven/npm dependency in each service   | Simple, language-specific         | Must update all services |
| API Gateway          | Gateway handles before routing         | Centralized, easy to change       | Only for ingress traffic |
| Service mesh sidecar | Envoy proxy handles transparently      | Language-agnostic, no code change | Operational complexity   |
| Platform chassis     | Starter template (Spring Boot starter) | Consistent defaults               | Coupling to platform     |

**Level 4 - Mastery (senior/staff+ engineer):**

**The polyglot challenge:** With Java, Node.js, and Python services, a shared Java library doesn't help Node.js services. Solutions:

1. **Service mesh (Istio/Linkerd):** Handles mTLS, retries, tracing, rate limiting at the network level. Language-agnostic.
2. **Sidecar containers:** Deploy an Envoy sidecar with each pod. All traffic flows through the sidecar.
3. **Platform abstraction:** Build a thin SDK per language that wraps the same API (OTel SDK exists for every major language).




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

[TODO: Include if 2+ named alternatives exist for Cross-Cutting Concerns. Otherwise remove this section.]
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

**Q1: You have 30 microservices in 3 languages (Java, Node.js, Go). How do you standardize cross-cutting concerns?**

_Why they ask:_ Tests architecture thinking for heterogeneous environments.

_Strong answer:_

**Layered approach:**

1. **Service mesh (Istio):** Handles mTLS, retry, circuit breaking, rate limiting at network level. Works for all languages, zero application code.
2. **OTel auto-instrumentation:** Each language has an OTel agent. Java agent, Node.js SDK, Go SDK. Standardized trace/metric format.
3. **Thin platform SDK per language:** Common logging format (JSON), health check endpoint (`/health`), config loading (from Consul/env vars). 3 small SDKs, not 3 copies of complex logic.
4. **API Gateway (Kong/Envoy):** Authentication, rate limiting, request logging at the edge. One place, all traffic.
5. **Templates:** Cookiecutter/Yeoman templates for new services. Include all cross-cutting concerns from day 1.
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

# Observability Architecture

**TL;DR** - Observability architecture is the unified system of traces, metrics, and logs that enables understanding system behavior from external outputs. The three pillars (traces for request paths, metrics for aggregates, logs for details) must be correlated so you can drill from a dashboard alert to the exact log line in the exact service for the exact request.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Observability Architecture was created."

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
Three tools working together: Dashboards show WHAT's wrong (metrics), traces show WHERE in the system it happened, logs show WHY it happened.

**Level 2 - How to use it (junior developer):**

```
Incident workflow:
1. Alert fires: "P99 latency > 2s"     (METRICS)
2. Dashboard: Order Service latency up  (METRICS)
3. Trace search: slow requests          (TRACES)
4. Find trace: DB query taking 5s       (TRACES)
5. Check logs for that trace ID         (LOGS)
6. Log: "Slow query: SELECT * FROM
   orders WHERE status = 'PENDING'"     (LOGS)
7. Fix: Add index on status column
```

**Level 3 - How it works (mid-level engineer):**

**Unified observability stack:**

```
                   [Grafana]
                  /    |    \
          [Prometheus] [Jaeger] [Loki]
           (metrics)   (traces) (logs)
                \      |      /
              [OTel Collector]
                     |
              [All Services]
```

**Correlation is key:**

```java
// Every log line includes trace ID
// Every metric has service + endpoint labels
// Every trace has service + operation name

// Log: {"traceId":"abc","service":"order",
//   "msg":"DB query slow","duration":5000}
// Metric: http_request_duration{
//   service="order",endpoint="/orders"} = 5.0
// Trace: abc -> order-service -> db.query (5s)

// Grafana: Click metric spike
//   -> Show traces with high latency
//     -> Click trace -> Show logs for that trace
```

**Level 4 - Mastery (senior/staff+ engineer):**

**SLIs, SLOs, SLAs (Google SRE model):**

| Concept         | Definition                       | Example                           |
| --------------- | -------------------------------- | --------------------------------- |
| SLI (Indicator) | Metric measuring service quality | P99 latency, error rate           |
| SLO (Objective) | Target for the SLI               | P99 latency < 500ms, 99.9% uptime |
| SLA (Agreement) | Contract with consequences       | 99.9% uptime or credits issued    |
| Error Budget    | 100% - SLO = acceptable downtime | 0.1% = 8.7 hours/year             |

```
SLO: 99.9% of requests complete in < 500ms

Error budget: 0.1% = 43 minutes/month

If error budget consumed:
  - Freeze feature work
  - Focus on reliability
  - No deployments until budget replenished
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

[TODO: Include if 2+ named alternatives exist for Observability Architecture. Otherwise remove this section.]
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

**Q1: How do you set up alerting that actually works (not too noisy, not too quiet)?**

_Why they ask:_ Tests operational maturity.

_Strong answer:_

**Alerting principles:**

1. **Alert on symptoms, not causes.** Alert: "P99 latency > 2s" (symptom). NOT: "CPU > 80%" (cause - might not affect users).
2. **Two severity levels only:** Page (wake someone up) vs Ticket (fix during business hours).
3. **Page-worthy:** Users are affected RIGHT NOW. Error rate > 1%. Service completely down.
4. **Ticket-worthy:** Will become a problem. Disk 80% full. Certificate expires in 7 days.
5. **Eliminate noise:** If an alert fires and no action is taken, delete it. Every alert must have a runbook.
6. **SLO-based alerting:** Alert when error budget burn rate suggests SLO will be missed.

```yaml
# Prometheus alert examples
# Page-worthy:
- alert: HighErrorRate
  expr: rate(http_errors_total[5m])
    / rate(http_requests_total[5m]) > 0.01
  for: 5m
  labels:
    severity: page
  annotations:
    runbook: https://wiki/runbook/high-error-rate

# Ticket-worthy:
- alert: DiskSpaceLow
  expr: node_filesystem_avail_bytes
    / node_filesystem_size_bytes < 0.2
  for: 30m
  labels:
    severity: ticket
```
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
