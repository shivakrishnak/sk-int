---
layout: default
title: "Distributed Systems - L3 Resilience Patterns"
parent: "Distributed Systems"
grand_parent: "SK Interview"
nav_order: 9
permalink: /distributed-systems/l3-resilience-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Circuit Breaker Pattern](#circuit-breaker-pattern) | medium |
| 2 | [Distributed Monolith Anti-pattern](#distributed-monolith-anti-pattern) | medium |

---

# Circuit Breaker Pattern

**TL;DR:** A circuit breaker wraps a remote call with a state machine
that stops sending requests when the downstream service is failing.
Three states: CLOSED (normal, requests pass through), OPEN (failing,
requests fail fast without calling downstream), HALF-OPEN (probe
state, one request allowed through to test recovery). Prevents
cascade failures and gives the failing service time to recover.
Implemented via Resilience4j in Java.

---

### 🎯 Model Answer

**30 seconds:**
> A circuit breaker stops calling a failing downstream service to
> prevent cascade failures. Like an electrical circuit breaker:
> when too many failures occur, it "trips" (opens), preventing
> further requests. After a timeout, it enters HALF-OPEN and lets
> one request through. If that succeeds: CLOSED (normal). If it
> fails: OPEN again. Fast-fail when open; protects the caller
> from blocked threads and protects the downstream from overload.

**3 minutes:**
> Without a circuit breaker: Service A calls Service B. Service B
> is slow (database overloaded). Each A-to-B request takes 30
> seconds to timeout. Service A's thread pool fills with threads
> waiting for B. New requests to A cannot be served. A also starts
> failing. Its callers also slow. This is a cascade failure - one
> downstream problem brings down the entire call chain.
>
> Circuit breaker prevents this: once B starts failing, the circuit
> breaker in A trips (opens). In OPEN state, A fails fast without
> calling B (returns an error or a fallback response immediately,
> in ~1ms). A's threads are freed. A remains available for requests
> that do not depend on B. The failing B gets no traffic, giving
> it a chance to recover.
>
> The three states: CLOSED - normal, all requests through, failure
> count tracked. If failure rate exceeds threshold (e.g., 50% of
> the last 10 calls): OPEN. OPEN - all requests fail fast, no call
> to downstream. After a wait duration (e.g., 60 seconds): HALF-OPEN.
> HALF-OPEN - one probe request allowed through. If it succeeds:
> CLOSED. If it fails: OPEN again.

**Blank Mind Recovery:**

**(1) Restate:** "Circuit breaker - stops calling a failing service
to prevent cascade failures. Opens when failure rate is too high;
resets after a timeout."

**(2) First principles:** "Remote calls fail. If you keep retrying
into a failing service, you block threads. If threads fill up,
you fail too. The solution: detect the failure and stop trying for
a while. Fail fast until the service recovers."

**(3) Bridge:** "Like an electrical circuit breaker: when overloaded,
the breaker trips and stops the current flow. The house remains safe.
After you fix the issue and reset the breaker, current flows again.
Software circuit breaker: same principle for service calls."

---

### 📘 Concept Explanation

**What it is:**
A resilience pattern implemented as a state machine around remote
calls that automatically stops sending requests to a failing
downstream service to prevent cascade failures.

**The problem it solves:**
Without circuit breakers, a slow or failed downstream service
causes callers to queue requests (blocking threads), which causes
thread pool exhaustion, which makes the caller itself appear
failed. This cascade failure amplifies a local problem into
a system-wide outage.

**State machine:**

```
              failures > threshold
CLOSED ───────────────────────────────> OPEN
  ^                                       |
  | success                               | wait duration
  |                                       v
HALF-OPEN <──────────────────────── HALF-OPEN
  |              probe request           (after wait)
  | failure                               
  v                                       
OPEN (back)
```

> **Code walkthrough:** This Circuit Breaker Pattern example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Resilience4j configuration:**

```java
CircuitBreakerConfig config = CircuitBreakerConfig.custom()
    // Percentage of failed calls to trip breaker
    .failureRateThreshold(50)
    // Minimum calls before failure rate is calculated
    .minimumNumberOfCalls(10)
    // Time in OPEN state before probing (HALF-OPEN)
    .waitDurationInOpenState(Duration.ofSeconds(60))
    // Max concurrent calls in HALF-OPEN state
    .permittedNumberOfCallsInHalfOpenState(3)
    // What counts as a failure
    .recordExceptions(
        IOException.class,
        TimeoutException.class)
    .build();
```

> **Code walkthrough:** This Circuit Breaker Pattern example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Fallback strategies:**

```
1. Fail fast: return error immediately (simplest)
   Result: caller gets error, can handle gracefully

2. Static fallback: return default/cached value
   Example: product catalog returns cached prices
   when pricing service is down

3. Fallback to secondary: use backup service/data
   Example: payment → Stripe primary, PayPal fallback

4. Queue request: persist request for later retry
   Example: order placed → outbox → retry when B recovers
```

> **Code walkthrough:** This Circuit Breaker Pattern example demonstrates a key ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Sliding window types (Resilience4j):**

```
COUNT_BASED: track last N calls
  - Threshold: X% of last 10 calls failed

TIME_BASED: track calls in last N seconds
  - Threshold: X% of calls in last 10 seconds
  
COUNT_BASED is simpler. TIME_BASED is better for
variable-rate services (different failure rates
at different times of day).
```

> **Code walkthrough:** This Circuit Breaker Pattern example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The circuit breaker serves two purposes: (1) protects the caller
from cascade failure, and (2) protects the downstream service from
thundering herd recovery (if B just recovered and all callers
immediately flood it, it may fail again). HALF-OPEN with a single
probe request tests recovery gently.

**When to use it:**
- Calls to external services (payment gateways, shipping APIs)
- Internal service-to-service calls with potential failure modes
- Database calls (slow queries, connection pool exhaustion)
- Any synchronous remote call in a microservices architecture

**When NOT to use it:**
- Local, in-process calls (add overhead without benefit)
- Async, fire-and-forget calls (circuit breaker cannot trip
  based on async responses)
- When retry is more appropriate (transient errors)

**Alternatives:**
- Bulkhead pattern: limit concurrent calls to a downstream
  service (prevents thread pool exhaustion regardless of
  circuit breaker state)
- Timeout + retry: simpler for transient failures

**First-principles derivation:**
"Failure detection in distributed systems requires observing
past behavior (failures) to predict near future behavior
(will the next call succeed?). The circuit breaker is a
sliding window failure detector: if recent failure rate is high,
assume the next call will also fail. Stop trying and save the
resources."

---

### 💻 Code Example


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// CIRCUIT BREAKER WITH RESILIENCE4J

// BAD: no circuit breaker - cascade failure risk
@Service
public class OrderService {
    private final PaymentClient paymentClient;

    public OrderResult placeOrder(Order order) {
        // BAD: if PaymentService is down and slow (30s
        // timeout), every order request blocks for 30s.
        // Thread pool exhausts. OrderService also fails.
        PaymentResult payment =
            paymentClient.charge(order.getTotal());
        return OrderResult.success(payment);
    }
}

// GOOD: circuit breaker + fallback
@Service
public class OrderService {
    private final PaymentClient paymentClient;
    private final CircuitBreaker paymentCircuitBreaker;

    public OrderService(PaymentClient paymentClient,
            CircuitBreakerRegistry registry) {
        this.paymentClient = paymentClient;
        this.paymentCircuitBreaker = registry
            .circuitBreaker("paymentService");
    }

    public OrderResult placeOrder(Order order) {
        // Decorate the call with circuit breaker
        Supplier<PaymentResult> decorated =
            CircuitBreaker.decorateSupplier(
                paymentCircuitBreaker,
                () -> paymentClient.charge(
                    order.getTotal()));

        return Try.ofSupplier(decorated)
            .recover(CallNotPermittedException.class,
                ex -> handleOpenCircuit(order))
            .recover(Exception.class,
                ex -> handlePaymentFailure(order, ex))
            .map(payment ->
                OrderResult.success(payment))
            .get();
    }

    // Fallback when circuit is OPEN
    private PaymentResult handleOpenCircuit(
            Order order) {
        // Queue the order for later processing
        // Return 202 Accepted to the caller
        pendingOrderQueue.add(order);
        log.warn("Payment circuit OPEN, order queued: {}",
            order.getId());
        return PaymentResult.queued(order.getId());
    }
}
```

> **Code walkthrough:** The BAD pattern calls the payment serviceice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> directly with no protection. A 30-second timeout on a slow
> payment service would hold a thread for the full duration,
> exhausting the thread pool under load. The GOOD pattern wraps
> the call in a Resilience4j circuit breaker. When the payment
> service fails beyond the threshold, the circuit opens and
> `CallNotPermittedException` is thrown immediately (no waiting).
> The `handleOpenCircuit` fallback queues the order for later
> processing - the order is not lost, just deferred. The caller
> gets a 202 Accepted response, which is semantically correct:
> the order was accepted but payment processing is asynchronous.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> A circuit breaker prevents cascade failures by stopping calls
> to a failing service. Three states: CLOSED (normal), OPEN
> (fail fast, no downstream calls), HALF-OPEN (probe for recovery).
> Resilience4j is the standard Java implementation. Configure
> failure rate threshold (e.g., 50%), minimum call count, and
> wait duration in OPEN state.

---

**Senior / Staff:**
> In production, circuit breaker configuration must be tuned per
> service. I set `minimumNumberOfCalls` high enough (10-20) to
> avoid tripping on random bursts. I use TIME_BASED windows for
> services with variable call rates. I monitor circuit breaker
> state as a health signal: if the payment service circuit is
> OPEN for > 5 minutes, that is a P1 incident. Combined with
> bulkhead (separate thread pools per downstream service), circuit
> breaker provides meaningful cascade failure protection. The
> fallback must be designed carefully: queuing is better than
> returning errors when the operation can be deferred.

---

### ⚠️ Common Misconceptions

**"Circuit breaker replaces retry"**

Reality: circuit breaker and retry serve different purposes.
Retry handles transient single-call failures (network blip).
Circuit breaker handles persistent downstream failures (service
is down for 5 minutes). Both are needed. Typical combination:
retry up to 3 times with exponential backoff. If all retries
fail: increment circuit breaker failure counter. If the circuit
breaks: no more retries until HALF-OPEN.

**"Circuit breaker should open on any exception"**

Reality: you should discriminate between exception types. Business
exceptions (invalid input, not found) are not failures of the
downstream service - they are expected responses. Only infrastructure
exceptions (timeout, connection refused, 500 errors) should
count toward the failure rate. Resilience4j supports `recordExceptions`
and `ignoreExceptions` configuration for this.

---

### ⚖️ Comparison Table

| Pattern| Protects Against| Mechanism| Use When|
|---|---------------------|--------------------------|-------------------------|
| Circuit Breaker| Cascade failure, thread exhaustion| State machine, fail fast|
| Retry| Transient failures| Re-execute on failure| Brief, recoverable|
| Timeout| Slow calls| Bounded wait time| All remote calls|
| Bulkhead| Thread pool exhaustion| Separate pools per service| High concurrency
| Rate Limiter| Overload| Throttle incoming requests| Downstream capacity limit|

**The deciding factor:** These are complementary, not competing.
Production resilience = Timeout + Retry + CircuitBreaker + Bulkhead
applied together (defense in depth).

---

### 🚨 Failure Modes and Diagnosis

---

**Failure Mode 1 - Circuit stuck OPEN after service recovery**

**Symptom:** Circuit breaker stays OPEN indefinitely even after the
downstream service has fully recovered. Requests fail fast with no
retry, degrading user experience long after the incident ended.

**Root cause:** The half-open probe request failed (network blip,
cold start latency spike), resetting the circuit back to OPEN. The
`successThreshold` for transitioning OPEN → CLOSED is set too high
(e.g., requires 5 consecutive successes), and the probe interval is
too long (e.g., 60s), so recovery takes 5+ minutes.

**Diagnosis:**
```bash
# Check circuit state in Resilience4j actuator endpoint
curl http://service/actuator/circuitbreakers
# Look for: state=OPEN, slowCallRate, failureRate, bufferedCalls

# Check transition events in logs
grep "CircuitBreaker.*state" app.log | tail -20
# Expected: CLOSED -> OPEN at incident start, OPEN -> HALF_OPEN,
# then HALF_OPEN -> CLOSED on recovery
```

> **Code walkthrough:** The `actuator/circuitbreakers` endpoint exposes the Resilience4j circuit state machine. KEY MECHANISM: the circuit transitions from OPEN to HALF_OPEN when `waitDurationInOpenState` elapses; it transitions to CLOSED only when `permittedNumberOfCallsInHalfOpenState` calls succeed at or above the success rate. WHY IT MATTERS: if `waitDurationInOpenState` is 60s and `permittedNumberOfCallsInHalfOpenState` is 5, recovery takes at least 60s plus 5 probe round-trips. WHAT BREAKS: setting probe count too high means any cold-start latency spike during probing triggers a reset back to OPEN. TAKEAWAY: tune half-open probe count to 2-3 and interval to 10-15s for fast recovery.

**Fix:** Reduce `waitDurationInOpenState` to 10-30s, set
`permittedNumberOfCallsInHalfOpenState: 3`, and set
`slowCallDurationThreshold` with realistic SLA values so cold-start
latency does not count as a failure.

---

**Failure Mode 2 - Retry storm amplifying downstream failure**

**Symptom:** A downstream service is at 80% capacity. Clients start
retrying on timeout. The retry storm pushes the downstream to 200%
capacity, causing a complete blackout. The circuit breaker opens
too late because failure rate threshold is not exceeded yet (timeouts
are not counted as failures in default config).

**Root cause:** Retries without circuit breakers and without
jitter cause coordinated thundering herds. Default Resilience4j
config counts only exceptions as failures, not slow calls, so a
slow (not failing) downstream triggers retries but not the circuit.

**Diagnosis:**
```bash
# Check if slow calls trigger circuit - look at slowCallRate
curl http://service/actuator/circuitbreakers | jq '.circuitBreakers'
# If slowCallRate is high but state is CLOSED, circuit misconfigured

# Check retry attempts in metrics
curl http://service/actuator/metrics/resilience4j.retry.calls
# High retry_count with FAILED_WITH_RETRY = retry storm in progress
```

> **Code walkthrough:** The metrics endpoint shows `resilience4j.retry.calls` with tags `kind=failed_with_retry` vs `kind=successful_without_retry`. KEY MECHANISM: when the upstream retries without circuit breakers, each timeout generates `maxAttempts` requests amplifying load by `maxAttempts` factor. WHY IT MATTERS: a service at 80% capacity receiving 3x retry amplification exceeds capacity completely, turning a partial failure into total outage. WHAT BREAKS: the circuit never opens because slow calls do not count as failures in default config. TAKEAWAY: always configure `slowCallRateThreshold` and `slowCallDurationThreshold` alongside the failure rate threshold.

**Fix:** Configure `slowCallRateThreshold: 50` (50% slow calls opens
circuit), add exponential backoff with jitter on retries, and ensure
the retry policy has a circuit breaker wrapping it.

---

### 🎯 Interview Deep-Dive

#### Production Failures

**[JUNIOR] Q1 - [MECHANISM] The payment service circuit breaker is OPEN. Orders are being queued. The payment service has recovered. The circuit is not closing. What is happening?**

The HALF-OPEN probe request is still failing. Possible causes:
(1) The payment service recovered at the application level but
its database is still degraded. The probe requests are hitting
the DB-dependent endpoint and failing. Check: are probes hitting
a health check endpoint or a real business endpoint? Probes should
hit a lightweight health check that validates the service is
ready. (2) The `waitDurationInOpenState` has not elapsed yet.
The circuit remains OPEN until the wait duration passes. Check
the circuit breaker's `getMetrics().getState()` and the last
state change time. (3) The probe is timing out. The timeout
on the probe request is the same as normal requests. If the
service is still slow (not fully recovered), probes time out
and the circuit does not close. Reduce probe timeout separately.

#### Candidate Mistakes

**[JUNIOR] Q2 - [FAILURE] How does a circuit breaker prevent cascade failures?**

**What NOT to say:** "It stops the failing service from receiving
requests."

**Say instead:** "The primary protection is for the CALLER, not
the downstream service. When the circuit is OPEN, calls to the
downstream service fail immediately (in ~1ms) instead of blocking
for the timeout duration (e.g., 30s). This frees the caller's
threads. Without a circuit breaker: if 100 concurrent requests
to the caller each wait 30 seconds for the downstream, the caller's
thread pool (typically 200 threads) fills up in 2 seconds. New
requests to the caller cannot be served. The caller appears to
have failed. Its callers also fill their thread pools. This cascade
propagates up the call chain. With a circuit breaker: after the
first few failures, subsequent requests fail fast. The caller's
thread pool remains available for requests not dependent on the
downstream service."

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


# Distributed Monolith Anti-pattern

**TL;DR:** A distributed monolith has the worst of both worlds:
the deployment complexity and network overhead of microservices,
plus the tight coupling and shared schema of a monolith. Services
cannot be deployed independently because they share databases,
synchronous call chains, or shared libraries. Signs: a deployment
of one service requires coordinated deployment of others; a failure
in one service cascades to all others; database schema changes
require multi-service coordination.

---

### 🎯 Model Answer

**30 seconds:**
> A distributed monolith looks like microservices (multiple services)
> but behaves like a monolith (tightly coupled). Services share
> databases, cannot be deployed independently, or are so
> interconnected that a failure in one brings down all. The result:
> the complexity of microservices without the benefits (independent
> deployment, isolated failure). The solution: enforce proper service
> boundaries with independent data stores and async communication.

**3 minutes:**
> Microservices promise: independent deployment, isolated failures,
> independent scaling. A distributed monolith delivers none of these.
>
> Signs: (1) Shared database - all services read from and write to
> the same database. A schema change requires updating all services.
> No service can scale its own data tier independently. (2) Synchronous
> call chains - Service A calls B which calls C which calls D. Every
> request must traverse all services. Latency accumulates. One slow
> service makes all requests slow. (3) Shared library coupling -
> all services use the same "common" library. A change to the
> library requires rebuilding and redeploying all services simultaneously.
>
> The root cause: teams "extracted" services from a monolith without
> cutting the dependencies. They split the code into separate
> deployables but kept the shared database, kept the synchronous
> call chains, kept the shared types library. The services are
> separate processes but logically one system.

**Blank Mind Recovery:**

**(1) Restate:** "Distributed monolith - a distributed system
(multiple services) that is still tightly coupled (cannot deploy
or fail independently). Worst of both worlds."

**(2) First principles:** "Independent deployment requires: (1) no
shared mutable state between services and (2) only contracts (APIs)
between services, not implementation dependencies. A distributed
monolith violates these at the database or library level."

**(3) Bridge:** "Like having multiple cashiers in a store but only
one cash register. You have the complexity of multiple people but
none of the throughput benefit, because everyone is waiting on
the same bottleneck."

---

### 📘 Concept Explanation

**What it is:**
A microservices architecture that retained the tight coupling
of a monolith - services share databases, are synchronously
chained, or share deployment-time dependencies - resulting
in none of the benefits of microservices.

**The problem it solves:**
Understanding this anti-pattern prevents teams from creating it
when decomposing a monolith. Recognizing it in an existing system
is the first step to fixing it.

**Symptoms (how to detect it):**

```
1. Shared database anti-pattern:
   ServiceA ─────────┐
   ServiceB ─────────┼──> shared_postgres_db
   ServiceC ─────────┘

   Signs:
   - Schema changes require updating multiple services
   - Services join tables owned by other services
   - One service's slow query affects other services

2. Synchronous chain:
   Client → A → B → C → D
   
   Signs:
   - D's failure causes cascading 500 errors
   - Latency = sum of all service latencies
   - Must deploy in coordinated order

3. Shared library:
   - All services use "company-common-1.0.jar"
   - A type change in common requires all services
     to update simultaneously
   - Shared version = shared release cycle

4. Shared configuration / environment:
   - All services use the same configuration server
     with the same keys
   - A bad config change affects all services

5. Shared infrastructure dependencies:
   - All services use the same Redis instance
   - One service's cache eviction storms affect all
```

> **Code walkthrough:** This Distributed Monolith Anti-pattern example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**What makes a TRUE microservice:**

```plaintext
Independence checklist:
✅ Owns its own database (private, not shared)
✅ Can be deployed without other services
✅ A failure in this service does not cascade
✅ Can scale independently (DB + app tier)
✅ Communicates via stable API contracts (not shared types)
✅ Has an independent release pipeline
✅ A team can work on it without coordinating with other teams
```

> **Code walkthrough:** This Distributed Monolith Anti-pattern example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Fix strategies:**

```
Shared DB → Private DB per service:
1. Identify which tables belong to which service
2. Service A stops joining Service B's tables;
   calls B's API instead
3. Data synchronization via events, not joins

Synchronous chain → Async events:
A → B → C → D (sync) becomes:
A publishes OrderCreated event
B subscribes, processes, publishes PaymentProcessed
C subscribes, processes, publishes InventoryReserved
D subscribes, processes independently
Each step is async; failures are isolated

Shared library → Published API contracts:
Remove shared domain objects from common library.
Share only: API client stubs, proto files, event schemas.
Never share: domain objects, business logic, JPA entities.
```

> **Code walkthrough:** This Distributed Monolith Anti-pattern example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The shared database is the most common and most severe form
of distributed monolith. Database joins across service
boundaries are the tell-tale sign. When a service must call
another service's API to get data it previously got via a DB
join, the design is being forced to respect service boundaries.

**When to use it:**
This is an anti-pattern - never deliberately choose it.

**When the trade-off is acceptable:**
During migration: a monolith being incrementally decomposed
passes through a "strangler fig" phase that temporarily has
shared databases. This is acceptable as an intermediate state,
not a final destination.

**Alternatives:**
- Database per service (true microservice)
- API Gateway + BFF (backends for frontends)
- Event-driven architecture with independent consumers

**First-principles derivation:**
"A service is independent when its behavior depends only on
its own data and its stable API contracts. Any dependency on
another service's internal implementation (database schema,
shared library class, synchronous call chain) violates
independence. A distributed monolith is just a monolith where
the shared internals are accessed across a network."

---

### 💻 Code Example


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// DISTRIBUTED MONOLITH ANTI-PATTERNS

// BAD: OrderService directly queries UserService's table
// (shared database - tight coupling)
@Repository
public class OrderRepository {
    @Query("""
        SELECT o.*, u.name, u.email, u.address
        FROM orders o
        JOIN users u ON o.user_id = u.id  -- BAD
        WHERE o.id = :orderId
        """)
    // BAD: OrderService is reading UserService's DB table
    // Schema changes to 'users' break OrderService
    // Cannot deploy separately; shared schema = shared destiny
    OrderWithUserDetails findOrderWithUser(
        long orderId);
}

// BAD: synchronous chain (no resilience)
@Service
public class CheckoutService {
    public CheckoutResult checkout(Cart cart) {
        // Synchronous chain: if ANY fails, all fail
        User user = userService.getUser(cart.getUserId());
        Price price = pricingService.price(cart);
        Payment result = paymentService.charge(price);
        Inventory inv = inventoryService.reserve(cart);
        Email email = emailService.send(result);
        return new CheckoutResult(result, inv);
    }
}

// GOOD: each service owns its data;
// cross-service data via API
@Service
public class OrderService {
    // OrderService has its OWN user cache/snapshot
    // It calls UserService API (not the DB) to get user data
    // and stores the relevant fields locally (address at
    // time of order - correct for historical record)
    public Order createOrder(CreateOrderRequest req) {
        // Call UserService API to get current user data
        // (HTTP or gRPC - not a DB join)
        UserSnapshot userSnap =
            userServiceClient.getUserSnapshot(
                req.getUserId());

        // Store a snapshot of user data with the order
        // This decouples the order from future user changes
        Order order = Order.builder()
            .userId(req.getUserId())
            .deliveryName(userSnap.getName())
            .deliveryAddress(userSnap.getAddress())
            .items(req.getItems())
            .build();

        return orderRepository.save(order);
        // Publishes OrderCreated event → other services
        // react independently (async)
    }
}
```

> **Code walkthrough:** The BAD patterns show the two most commonice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> distributed monolith symptoms. The JOIN across the `users` table
> creates a database-level coupling: any schema change to `users`
> breaks `OrderRepository`. The synchronous chain means a failure
> in `emailService` fails the entire checkout. The GOOD pattern
> shows "database per service" at the code level: `OrderService`
> calls `UserService` via an API client (not a DB join) and stores
> a snapshot of the relevant user data with the order. This is
> intentional redundancy: the order records the delivery name and
> address at the time of the order (correct for historical records).
> The user data snapshot is independent of future user profile changes.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> A distributed monolith has multiple services but they are tightly
> coupled: shared database, synchronous call chains, or shared
> libraries. Cannot deploy services independently; failures cascade.
> It is worse than a monolith because you have the deployment
> complexity of microservices without the isolation benefits. Fix:
> database per service, async communication between services.

---

**Senior / Staff:**
> When I see a service that joins another service's tables, that is
> a distributed monolith. The fix starts with identifying which
> data genuinely belongs to each service's bounded context. The
> hardest migration: moving from a shared DB to per-service DBs
> while the system is live. I use the strangler fig pattern:
> add an API in Service B for the data Service A needs. Route
> Service A to the API instead of the DB join. Once no service
> joins B's tables directly: make B's tables private. Decouple the
> schemas last (after the code is decoupled).

---

### ⚠️ Common Misconceptions

**"Using separate services means we have microservices"**

Reality: the number of processes/services is not the definition
of microservices. Microservices are defined by independence:
independent data, independent deployment, isolated failure.
A system with 50 separate services all connected to the same
database is a distributed monolith - all 50 services are coupled
at the data layer. True microservices require ownership of data
and communication only via stable contracts.

**"A shared library for common types is fine"**

Reality: shared libraries create shared release cycles. When the
"common" library is updated, all services that use it must test,
build, and release together. This is exactly the coupling that
microservices are designed to avoid. The acceptable sharing:
API contracts (OpenAPI specs, Protobuf files, event schemas) -
these describe the interface, not the implementation. Never share:
domain objects, JPA entities, business logic.

---

### ⚖️ Comparison Table

| Architecture| Deployment| Failure Isolation| Scale| Choose When|
|---|----------------|-----------------|-----------|---------------------------|
| Monolith| Single unit| None| Vertical| Small team, early stage|
| Distributed Monolith| Pseudo-independent| None| Constrained| NEVER (anti-patte
| Microservices| Independent| Isolated| Independent| Scale teams, complex domain
| Modular Monolith| Single unit| In-process| Vertical| Growing team, clear modul

**The deciding factor:** A modular monolith (strong module
boundaries, no shared state between modules, clean APIs between
modules) is often better than distributed microservices for
medium-scale systems. It avoids both the distributed monolith
trap and the operational overhead of microservices.

---

### 🎯 Interview Deep-Dive

#### Production Failures

**[JUNIOR] Q1 - [MECHANISM] Deploying a new version of the UserService caused OrderService, PaymentService, and InventoryService to all start returning errors. What went wrong and what does this indicate?**

This is a distributed monolith. The services are not
independently deployable. Most likely cause: the UserService
shared library (or shared database schema) was changed in a
backward-incompatible way. When UserService deployed with a new
schema (e.g., renamed a column), all services that join that
table or use a shared UserDTO class broke simultaneously.
Diagnosis: check the shared library versions and database schema
change logs for the UserService deployment. Identify the specific
breaking change. Fix: (1) roll back the UserService deployment
(immediate mitigation). (2) redesign: UserService should not have
a shared library with domain objects. Other services should not
join UserService tables directly. (3) Implement backward-compatible
API versioning for UserService, enabling gradual migration.

#### Candidate Mistakes

**[JUNIOR] Q2 - [MECHANISM] Our monolith is slow to deploy. We want to break it into microservices. Where do we start?**

**What NOT to say:** "Split it by technical layer: separate the
controllers, services, and DAOs into different deployables."

**Say instead:** "Never split by technical layer - that creates
a distributed monolith immediately. Every request would traverse
controller-service → service-service → DAO-service, adding
network round trips for every call. Instead: identify the bounded
contexts first. A bounded context is a cohesive subdomain with
its own data and language (Domain-Driven Design). The order of
extraction: (1) start with the service on the edge - the one with
the fewest inbound dependencies from other parts of the monolith.
(2) Use the strangler fig pattern: new requests go to the new
microservice; old functionality remains in the monolith. (3) Cut
the shared database dependency last - this is the hardest step.
Test independence thoroughly before removing the monolith code.
A good first extraction: the auth/identity service (usually
minimal outbound dependencies, clear ownership of user data)."

---

### 🚨 Failure Modes and Diagnosis

**Circuit breaker trips on non-infrastructure exceptions:**

Symptom: legitimate business requests start failing fast (circuit
OPEN) even though the downstream service is healthy. Example:
payment declines (400 responses) causing the circuit to open.

Cause: the circuit breaker is configured to record ALL exceptions,
including business-level exceptions (InvalidInputException,
PaymentDeclinedException). These are not downstream failures.

Diagnosis: check circuit breaker metrics for the failure type
distribution. Separate infrastructure failures (timeouts,
connection refused, 5xx) from business failures (4xx, business
exceptions).

Fix: configure `recordExceptions` to only include infrastructure
exceptions (IOException, TimeoutException, 5xx status codes).
Explicitly use `ignoreExceptions` for business exceptions.

**Circuit breaker masking a persistent failure:**

Symptom: circuit is OPEN. The downstream service recovered 2 hours
ago. The circuit never re-closes. Requests continue to fail fast.

Cause: HALF-OPEN probe requests are still failing because the
circuit is misconfigured (probe timeout too short, probe
endpoint still degraded).

Diagnosis: check circuit breaker state and last state change time.
Manually test the downstream service endpoint. Compare the probe
endpoint (used by circuit breaker) vs the actual service endpoint.

Fix: configure a dedicated health probe endpoint that is lightweight
and returns quickly. Set probe timeout separately (shorter than
normal request timeout but long enough for the service to respond).
Add alerting on circuit breaker state transitions.

---

### 🏛️ System Design

*(Omit: circuit breaker is a resilience component within a service.
System-level resilience design is covered in the L4 Failure Detection
and L5 Partition Tolerance files.)*

---

### 📊 Diagram

*(Omit: the circuit breaker state machine is described in the
Concept Explanation pseudocode. A visual state diagram adds
limited value. See Resilience4j documentation for official state
transition diagram.)*

---

### 🎯 Interview Deep-Dive

| Question Type| Count| Timing|
|--------------------|------------------|-----------------|
| Conceptual| 3| 2 min each|
| Trade-off| 2| 3 min each|
| Debugging| 2| 3 min each|
| Behavioral| 1| 4 min|
| Scale| 1| 3 min|

---

**[JUNIOR] Q1 - [MECHANISM] Explain the purpose of HALF-OPEN state in a circuit breaker. Why is it needed?**

After the circuit opens (too many failures), the system needs a
mechanism to discover when the downstream service has recovered
and resume normal traffic. Without HALF-OPEN: the circuit would
remain OPEN forever, never resuming service even after the
downstream recovers. Or it would transition OPEN → CLOSED on a
timer, flooding the recovering service with all queued traffic
at once (thundering herd).

HALF-OPEN solves both problems: after the wait duration, the
circuit allows exactly one probe request through. If the probe
succeeds: CLOSED (traffic gradually resumes). If the probe fails:
OPEN again (service still not ready, wait another interval).

The one-at-a-time probe is the thundering herd prevention. Instead
of all callers flooding the recovering service simultaneously,
only one request probes at a time. The recovering service handles
one request at its degraded capacity, confirms recovery, and then
full traffic resumes.

*What separates good from great:* Great candidates explain that
the HALF-OPEN probe must use a representative endpoint that
exercises the same code path as production traffic - not just
a ping endpoint. A ping succeeds even if the database connection
(used by all real requests) is still down.

---

**[JUNIOR] Q2 - [MECHANISM] What is the difference between circuit breaker and retry patterns? When should you use each or both?**

Retry: detects a single failed request and re-executes it.
Addresses transient failures (brief network blip, service
restarting). Retry logic: attempt → fail → wait (exponential
backoff) → retry → success. Retry assumes the failure is temporary
and the next attempt will succeed.

Circuit breaker: detects a pattern of failures and stops sending
requests for a period. Addresses persistent failures (service is
down for minutes or hours). Circuit breaker assumes the failure
is significant and retrying is wasteful/harmful.

Together (standard configuration):
1. Single request fails
2. Retry with exponential backoff (up to 3 attempts)
3. All 3 attempts fail → circuit breaker failure counter increments
4. After N failures (from multiple requests): circuit trips OPEN
5. New requests fail fast without retrying

The key distinction: retry is per-request behavior; circuit
breaker is per-service state maintained across requests.

*What separates good from great:* Great candidates note the
interaction: "If you retry 3 times and the circuit breaker
counts each retry as a failure, you can trip the circuit breaker
3x faster than you intended. Configure Resilience4j's
`recordExceptions` carefully to avoid counting retried exceptions
in the circuit breaker failure rate."

---

**[JUNIOR] Q3 - [MECHANISM] How does a bulkhead pattern complement a circuit breaker?**

Circuit breaker prevents calling a failed service. But before
the circuit trips, a slow service can still exhaust the caller's
shared thread pool. If 50 threads are waiting on a slow downstream
service for 30 seconds each, no other work can be processed.

Bulkhead isolates thread pools per downstream dependency. Service A
has:
- pool-payment: 10 threads for payment service calls
- pool-inventory: 10 threads for inventory service calls
- pool-general: 50 threads for everything else

Now, if the payment service becomes slow and consumes all 10 of
pool-payment's threads: the inventory and general work is
unaffected. 10 stuck threads do not bring down the 50-thread
general pool.

Together: bulkhead limits the blast radius of a slow service.
Circuit breaker stops calls entirely once the service is detected
as failed. Defense in depth: bulkhead reduces harm during the
window before the circuit trips.

*What separates good from great:* Great candidates explain Resilience4j's
implementation: `ThreadPoolBulkhead` uses separate thread pools per
resource. `SemaphoreBulkhead` limits concurrent calls using a
semaphore (lighter weight, works in reactive frameworks).

---

**[MID] Q4 - [TRADE-OFF] What is the cost of setting a circuit breaker threshold too low vs. too high?**

Too low (e.g., 10% failure rate threshold, minimum 5 calls):
A brief burst of 1 error in 5 calls trips the circuit (20%).
The circuit opens and stays open for the wait duration (e.g.,
60 seconds). During this time, all requests fail fast even though
the downstream was mostly healthy. False positives cause unnecessary
service degradation.

Too high (e.g., 90% failure rate threshold, minimum 100 calls):
The circuit does not open until 90% of the last 100 calls have
failed. By this time, the caller has already exhausted most of
its thread pool waiting for the downstream service. Cascade
failure has already begun. The circuit provides no meaningful
protection.

Tuning guidelines:
- Failure rate threshold: 50% is a common starting point
- Minimum calls: set high enough to avoid false positives (10-20)
- Use TIME_BASED window for variable-rate services
- Monitor false positive rate and adjust

Also: the wait duration matters. Too short (5s): the service is
still recovering when probed → circuit re-opens → longer overall
downtime. Too long (10 minutes): valid requests fail fast for
10 minutes unnecessarily.

*What separates good from great:* Connecting threshold tuning to
the underlying call rate. "At 1 call per second, a 10-call minimum
window means 10 seconds of data. At 1000 calls per second, 10
calls is 10ms of data. The minimum call count must be calibrated
to the expected call rate."

---

**[MID] Q5 - [TRADE-OFF] When is a fallback response the right choice vs. failing fast with an error?**

Fail fast (return error to caller): appropriate when there is no
reasonable alternative to the requested operation. If the payment
service is down, there is no valid fallback for processing a
payment. The caller must know the payment failed and display an
error. A fallback that pretends the payment succeeded would be
worse than an error.

Fallback response: appropriate when the operation has a degraded
alternative. Examples:
- Product pricing service down: return last cached price (slightly
  stale but allows purchase to continue)
- Recommendation service down: return popular items (default list
  instead of personalized)
- User preferences service down: return default preferences
  (no personalization, but the page still loads)

The distinction: is the fallback value acceptable to the business?
"Acceptable: serves the user's need, even if degraded. Unacceptable:
misleads the user or creates data inconsistency."

*What separates good from great:* Identifying that fallback data
freshness must be defined. "For pricing: cached prices no older
than 5 minutes are acceptable. Prices older than 1 day are not -
at that point, fail fast rather than sell products at outdated prices."

---

**[SENIOR] Q6 - [DEBUGGING] You are seeing intermittent 503 errors from Service A that calls Service B. Circuit breaker metrics show the circuit is CLOSED (not open). What are the possible causes?**

If the circuit is CLOSED but 503s are occurring, the failures
are not yet crossing the circuit breaker threshold (but they will
if the condition persists). Possible causes:

1. The failure rate is below the threshold. 20% of calls are
   failing but threshold is 50%. The circuit is closed but 20%
   of users are experiencing errors.

2. Timeout without circuit breaker integration. The 503s are
   timeout errors that are not being counted by the circuit
   breaker (wrong exception type configuration).

3. The circuit breaker is on a different code path than the
   failing path. Another call to Service B (not wrapped in
   circuit breaker) is failing.

4. Minimum call count has not been reached. The circuit requires
   100 calls before evaluating the failure rate. The service
   is low-traffic and never reaches 100 calls.

Diagnosis: (1) Check circuit breaker metrics: what is the current
failure rate? (2) Enable circuit breaker event logging to see
which exceptions are being recorded. (3) Verify all paths to
Service B are wrapped in the circuit breaker. (4) Check Service B
logs for error patterns.

*What separates good from great:* Immediately checking whether
the circuit breaker wraps ALL paths to Service B, not just the
main one. It is common to add a circuit breaker to one method
but miss another method in the same service that also calls
Service B.

---

**[SENIOR] Q7 - [DEBUGGING] The circuit breaker is causing more harm than good: it trips on normal business errors and stays open too long. How do you reconfigure it?**

Step 1: identify which exceptions are being counted as failures.
Enable Resilience4j event logging. Each `CircuitBreakerOnErrorEvent`
shows the recorded exception. If PaymentDeclinedException (a
normal business outcome) appears: this is misconfigured.

Step 2: separate infrastructure from business exceptions.

Before (records all exceptions):
```java
CircuitBreakerConfig.custom()
    .recordExceptions(Exception.class)
    .build()
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

After (records only infrastructure exceptions):
```java
CircuitBreakerConfig.custom()
    .recordExceptions(
        IOException.class,
        TimeoutException.class,
        ServiceUnavailableException.class)
    .ignoreExceptions(
        BusinessException.class,
        ValidationException.class,
        PaymentDeclinedException.class)
    .build()
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Step 3: if it stays open too long, reduce `waitDurationInOpenState`
and increase `permittedNumberOfCallsInHalfOpenState` (more probe
calls before transitioning to CLOSED).

*What separates good from great:* Great candidates know the
`ignoreExceptions` configuration. Ignored exceptions are counted
in the call count (denominator) but not in the failure count
(numerator). This is critical for services that legitimately
return business errors frequently.

---

**[SENIOR] Q8 - [BEHAVIORAL] Tell me about a time you implemented or debugged a circuit breaker in production.**

*(Personalize from experience.)*

Example structure: "We had a cascading failure where our checkout
service became unavailable whenever the inventory service was slow.
I implemented a Resilience4j circuit breaker on the inventory
service call with a 30-second wait duration and a fallback to
return 'check inventory at pickup' to the customer. I discovered
that the circuit was tripping on HTTP 404 responses (item not
found) which were normal business responses, not failures. I
reconfigured to only count 5xx responses and timeouts as failures.
After the fix, the circuit worked correctly: during an inventory
service outage (which happened 3 weeks later), checkout continued
working with the fallback, and the circuit reset correctly when
inventory recovered."

---

**[SENIOR] Q9 - [TRADE-OFF] How does circuit breaker behavior change when a service has many callers (thousands of instances)?**

In a single-instance circuit breaker: the circuit state is
in-memory, per instance. 1,000 service instances each have their
own circuit breaker for Service B. Each instance independently
tracks failure rates.

Behavior differences at scale:

1. **Detection lag:** when B starts failing, instances that
   happen to call B first detect it. Others continue sending
   requests until their own thresholds are reached. At 1,000
   instances with minimum 10 calls per instance: potentially
   10,000 failed calls before all circuits trip.

2. **Recovery load:** when B recovers, all 1,000 circuits are
   in HALF-OPEN simultaneously. Each sends one probe. B receives
   1,000 probe requests at once - a thundering herd. If B is
   fragile, this kills the recovery.

Mitigation for recovery thundering herd: add jitter to HALF-OPEN
transition timing. Instead of all instances waiting exactly
60 seconds, randomize: `60s + random(0, 30s)`. This staggers
the probe requests across 30 seconds.

For centralized circuit state: use a distributed circuit breaker
(share state via Redis or service mesh). The service mesh
(Istio, Linkerd) can enforce circuit breaking at the proxy level
for all traffic, eliminating the per-instance variability.

*What separates good from great:* Identifying the 1,000-instance
thundering herd during recovery. This is a real production
failure mode and shows operational awareness.

---

---

### 🚨 Failure Modes and Diagnosis

*(For Distributed Monolith Anti-pattern)*

**Schema change breaks multiple services simultaneously:**

Symptom: a single database migration causes errors in 5 different
services at once.

Cause: multiple services are reading the same database tables.
A column rename (breaking change) causes all services to fail
their queries simultaneously.

Diagnosis: check the deployment log for database migrations.
Compare the migration's changed columns against the code in
each failing service.

Fix (immediate): roll back the migration. Fix (long-term): identify
which services own which tables. Begin the migration to per-service
databases. In the meantime: implement backward-compatible schema
changes only (add columns, never rename or remove; use feature
flags to migrate consumers before removing old columns).

**Cascading failures through synchronous service chains:**

Symptom: a brief outage in Service D causes Services A, B, and
C to all fail simultaneously. Service D is a leaf service (no
downstream dependencies).

Cause: A → B → C → D is a synchronous chain. D's timeout
propagates up: C waits for D (30s), B waits for C (30s + D's
remaining timeout), A waits for B. Thread pools fill at each
level.

Diagnosis: draw the service dependency graph. Identify synchronous
chains longer than 2 services.

Fix: add circuit breakers at each hop. Convert the synchronous
chain to async where possible (events). Services that do not
strictly need D's response synchronously should communicate
via events.

---

### 🏛️ System Design

*(Omit: distributed monolith is an architectural anti-pattern
concept. System design for properly decomposed microservices
is covered in L3 Service Architecture, L5 Migration Strategy,
and L5 Global Scale files.)*

---

### 📊 Diagram

*(Omit: distributed monolith symptoms are best illustrated
with code examples (as in the Concept Explanation) rather
than a diagram. The service coupling patterns are code-level
concerns.)*

---

### 🎯 Interview Deep-Dive

| Question Type | Count | Timing |
|---|---|---|
| Conceptual | 3 | 2 min each |
| Trade-off | 2 | 3 min each |
| Debugging | 2 | 3 min each |
| Behavioral | 1 | 4 min |
| Scale | 1 | 3 min |

---

**[JUNIOR] Q1 - [MECHANISM] List 5 signs that a system is a distributed monolith, not true microservices.**

1. **Shared database:** multiple services read from and write
   to the same database schema. Tables owned by "Service A" are
   directly queried by Service B and C.

2. **Coordinated deployments:** deploying Service A requires
   simultaneously deploying Service B (because of shared library
   versions or API contract changes that are not backward-compatible).

3. **Cascading failures:** a failure in Service D causes Services
   A, B, and C to also fail, even though A, B, and C are not
   directly dependent on D's core functionality.

4. **Shared library with domain objects:** a `company-common.jar`
   contains domain classes (Order, User, Product) shared across
   all services. A change to these classes requires rebuilding
   and redeploying all services.

5. **Synchronous call chains spanning 4+ services:** a single
   user request traverses Service A → B → C → D → E before
   returning. Each service waits synchronously for the next.
   The latency is the sum of all services' latencies.

*What separates good from great:* Great candidates add: "I also
look for hidden coupling: services that share a message queue
topic and rely on message ordering guarantees. Or services that
share a Redis cache with inter-service keys. These are subtler
forms of the same anti-pattern."

---

**[JUNIOR] Q2 - [MECHANISM] What is the strangler fig pattern and how does it help migrate from a monolith to microservices without creating a distributed monolith?**

The strangler fig pattern (named after a tropical plant that
gradually replaces its host tree) involves incrementally migrating
functionality from the monolith to a new service while both
run simultaneously.

Steps for one service extraction:
1. Identify a bounded context to extract (e.g., User Management)
2. Create a new standalone User Service with its own database
3. Add an API gateway or proxy rule: route user-related requests
   to the new User Service
4. The monolith's user functionality is now the "backup" path;
   all new requests go to the new service
5. Gradually migrate monolith data to the new service's database
6. Once all users are migrated and the new service is stable,
   remove the user code from the monolith

Avoiding distributed monolith during migration:
- The new service must have its own database FROM THE START.
  Do not share the monolith's database.
- The monolith should call the new service's API (not the DB)
  for user data. This may be slow during migration - acceptable
  as an intermediate state.
- Never share domain objects between the monolith and the new
  service. Use separate types that are mapped at the API boundary.

*What separates good from great:* The anti-pattern in this process:
creating a new service that still connects to the monolith's
database. This creates a distributed monolith and does not
improve independence. "The test: after extraction, can we change
the new service's data schema without touching the monolith?"

---

**[JUNIOR] Q3 - [MECHANISM] Why is a shared domain object library across microservices an anti-pattern?**

A shared domain library (e.g., `Order`, `User`, `Product` classes
in `company-domain.jar`) creates temporal coupling: any change to
these classes requires all consuming services to update, rebuild,
and redeploy simultaneously. This is exactly the deployment
coupling that microservices are supposed to eliminate.

Additionally: shared domain objects tend to accumulate fields from
all consuming services' requirements. The `Order` class grows to
include fields relevant to OrderService, PaymentService, ShippingService,
and AnalyticsService simultaneously. No single service actually
needs all these fields, but all must carry the overhead.

The solution: each service owns its own domain model. Communication
is via contracts (OpenAPI specs, Protobuf files). Services share
the SCHEMA, not the IMPLEMENTATION. Service A publishes an
`OrderCreatedEvent` with a specific Avro schema. Service B consumes
this event and maps it to its own internal `Order` object.
The schema is shared; the class is not.

*What separates good from great:* The mapping overhead is real:
each service maps external contracts to internal models. But
this is the correct trade-off: a small mapping cost enables
fully independent evolution.

---

**[MID] Q4 - [TRADE-OFF] Monolith vs. microservices vs. modular monolith: when is each the right choice?**

Monolith: right for small teams (< 10 engineers), early product
stage where requirements change rapidly, systems where
cross-cutting concerns (transactions, reporting) dominate.
Cost of microservices (distributed tracing, network failure
handling, deployment complexity) exceeds benefit at this scale.

Microservices: right when independent scalability is required
(the shopping cart service needs 10x the capacity of the admin
service), when team autonomy is needed (20+ engineers who cannot
all coordinate on a single codebase), when different services
need different technology stacks (Python for ML, Java for
transactions).

Modular monolith: right for medium-scale systems (5-20 engineers)
where the product is well-understood and team coordination is
manageable. Modules have clean boundaries (separate packages with
defined APIs) but run in one process. Benefits: no network overhead,
local transactions, simple deployment. Easier to evolve into
microservices later because the module boundaries are already
well-defined.

*What separates good from great:* Great candidates advocate for
the modular monolith as an underappreciated option. "Most of the
microservices I have seen in practice would be better as a
modular monolith for their current scale. The complexity cost
of distributed systems is high and should only be paid when
the benefits are real."

---

**[MID] Q5 - [TRADE-OFF] What are the costs and risks of migrating from a distributed monolith to true microservices?**

The risks:

1. **Data migration:** splitting a shared database while the
   system is live requires careful orchestration. Data may be
   in both the old shared DB and the new service's DB during
   migration. Dual writes (write to both) or event sourcing
   are needed to keep them in sync.

2. **Performance regression:** replacing a DB join with a
   synchronous API call adds latency. A join that took 1ms
   becomes an API call that takes 5ms. For read-heavy paths,
   this is significant.

3. **Consistency changes:** the shared database provided
   implicit transactions across service boundaries. After
   splitting, these cross-service operations must use Sagas
   or the Outbox pattern. Eventual consistency replaces
   immediate consistency.

4. **Team coordination during migration:** the migration
   requires simultaneous changes across teams. The old and
   new patterns co-exist during the migration window, increasing
   cognitive load.

5. **Scope creep:** "microservices refactoring" often expands
   to rewriting everything, adding months to the timeline.

*What separates good from great:* Emphasizing that the migration
should be incremental (one service at a time) and that each
extracted service should be validated in production before
extracting the next.

---

**[SENIOR] Q6 - [DEBUGGING] A team extracted a service but deployments are still coordinated. What is the hidden coupling?**

Coordinated deployments after extraction indicate a hidden
coupling. Common causes:

1. **Shared library version requirement:** the new service uses
   `company-common-v2.jar`. The old service uses v1. The new
   version changed a class that is shared in the API contract.
   Callers must update to v2 simultaneously.

Diagnosis: check `pom.xml` / `build.gradle` for shared library
dependencies. Look for version constraints between services.

2. **API backward incompatibility:** the new service's API
   changed a required field name or response structure. Callers
   must update simultaneously.

Diagnosis: compare the old and new service API specs (OpenAPI).
Identify breaking changes.

3. **Database schema still shared:** the "new" service still
   reads a table in the old service's database. A schema change
   to that table requires coordinating both services.

Fix: version APIs (v1/v2 endpoints). Implement backward-compatible
schema changes. Decouple the shared library into separate API
contracts.

*What separates good from great:* Knowing the difference between
backward-compatible and breaking changes: adding a field = backward
compatible (callers ignore unknown fields). Removing/renaming a
required field = breaking. The fix: API versioning or field
deprecation with migration period.

---

**[SENIOR] Q7 - [DEBUGGING] How do you identify which service "owns" a table in a shared database?**

When there is no formal ownership, use these heuristics:

1. **Write analysis:** which service writes to this table?
   `SELECT client_addr, query FROM pg_stat_statements
   WHERE query LIKE '%INSERT INTO orders%'`. The service that
   originates the write is the owner.

2. **Business domain ownership:** which bounded context does
   this entity belong to? An `orders` table belongs to the
   Order Management bounded context, regardless of who reads it.

3. **Dependency direction:** if Service A references Service B's
   entities (order items reference product IDs), but products
   can exist without orders: the `products` table is owned by
   Product Service, `orders` by Order Service.

4. **Change frequency alignment:** which team changes this table's
   schema most frequently? Schema changes should be owned by
   the same team that owns the service.

Document ownership: add a comment or metadata to each table
(`COMMENT ON TABLE orders IS 'owned_by: order-service'`). Use
this as a lint rule in CI: a service that reads a table it does
not own must use an API instead.

*What separates good from great:* The insight that write ownership
is more definitive than read ownership. "Any service can read data.
The owner is the one that creates and modifies it. Start with
insert/update analysis."

---

**[SENIOR] Q8 - [BEHAVIORAL] Have you worked in a distributed monolith? How did you identify it and what steps did you take?**

*(Personalize from experience.)*

Example structure: "At my previous company, we had 15 microservices
all connecting to the same PostgreSQL database. A schema migration
for the `orders` table required a 3-hour maintenance window to
deploy 8 services simultaneously. I identified it as a distributed
monolith by mapping out which tables each service accessed.
I proposed a migration plan: (1) stop new cross-service DB joins
immediately (new features must use APIs). (2) For the orders table:
extract an OrderService that owns it, add API endpoints for all
needed queries, update all consumers to use the API. (3) Run a
45-day migration window: both the direct DB access and the API
were available. After 45 days: remove direct DB access.
We completed 4 service extractions in 6 months, reducing
deployment coordination from 8 services to 2."

---

**[SENIOR] Q9 - [TRADE-OFF] How does the impact of a distributed monolith change as the team and system scale?**

At small scale (5 engineers, 3 services): the shared database
is manageable. Everyone knows the schema. Coordinated deployments
are a 30-minute exercise. The distributed monolith is painful
but survivable.

At medium scale (20 engineers, 10 services): the shared database
becomes a merge conflict nightmare. Schema migrations take hours
to coordinate. One team's schema change breaks another team's
service. Deployments require a deployment coordinator role.
The distributed monolith is now a significant engineering tax.

At large scale (50+ engineers, 25+ services): the distributed
monolith is the primary bottleneck. The shared database becomes
a performance bottleneck (all services compete for connections
and I/O). Deployment coordination requires weeks of planning.
Feature velocity drops to a fraction of a small-team velocity.
Teams spend more time on coordination than on engineering.

The compounding effect: each additional service added to the
distributed monolith increases the coupling surface non-linearly
(O(n^2) coordination cost for n services). At 25 services: up
to 625 potential coupling points.

*What separates good from great:* The O(n^2) coupling cost
observation. This is why "just add another service" makes the
distributed monolith exponentially worse over time. The fix must
be architectural, not incremental.

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



