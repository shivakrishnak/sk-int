---
layout: default
title: "Microservices - L4 Fault Tolerance"
parent: "Microservices"
grand_parent: "SK Interview"
nav_order: 13
permalink: /microservices/l4-fault-tolerance/
---

# Fault Tolerance Patterns - Timeout, Retry, Fallback

---

### 🎯 Model Answer

**30 seconds:**
> Fault tolerance patterns in microservices prevent a single service failure from cascading to take down the entire system. The three core patterns: timeout (set a maximum wait time so a slow service doesn't block your threads indefinitely), retry (automatically re-attempt failed calls for transient failures, with exponential backoff), and circuit breaker (stop calling a failing service entirely after a threshold of failures, returning a fast error until the service recovers). Used together, these patterns make your service resilient to downstream failures.

**3 minutes:**
> In a system with 10 services, if any one fails, you have two choices: fail the entire user request (no fault tolerance) or degrade gracefully (fault tolerance). The timeout pattern: without a timeout, one slow service holds a thread indefinitely. With 10 concurrent users hitting a slow service, all 10 threads block. No more threads available. Your service appears down even though the service itself is running. A 5-second timeout ensures threads are released. The retry pattern: some failures are transient (brief network glitch, pod restart). A retry after 100ms succeeds. But retries amplify load on a struggling service. Rule: retry only on idempotent operations, with exponential backoff and a max of 2-3 retries. Never retry non-idempotent operations (payment processing - retrying a failed payment may charge twice). The circuit breaker pattern: when a service has been failing for 60% of calls in the last 30 seconds, open the circuit. All calls return immediately with an error (no call made to the failing service). After 30 seconds, allow a test call. If it succeeds: close the circuit. This prevents: thread exhaustion waiting for a failing service, log flooding with repeated failure logs, compounding retry load on an already-failing service. The fallback pattern: when a service is unavailable, return a degraded but useful response. Recommendation service down: return the default recommended products. User preferences service down: return default preferences. This keeps the user experience functional even during downstream failures.

**Blank Mind Recovery:**
**(1) Timeout:** "Every service call needs a max wait time. Never wait indefinitely."
**(2) Retry:** "For transient failures. Idempotent operations only. Exponential backoff. Max 2-3 attempts."
**(3) Circuit breaker:** "Stop hammering a failing service. Open circuit -> fail fast -> test -> close if healthy."

---

### 📘 Concept Explanation

**What it is:**
Fault tolerance patterns are defensive techniques that prevent a service from being destroyed by the failures of its dependencies. Each pattern addresses a specific failure mode.

**The failure cascade (why fault tolerance matters):**
```
Without fault tolerance:

  RequestHandler (100 threads)
     |
     v
  PaymentService [DOWN - takes 30s to timeout]
  
  Timeline:
    T=0:  Thread 1 calls PaymentService, WAITS
    T=1:  Thread 2 calls PaymentService, WAITS
    ...
    T=100: Thread 100 calls PaymentService, WAITS
    T=101: All threads busy waiting
    T=102: New request arrives, NO THREADS AVAILABLE
    T=102: OrderService appears DOWN to users
    T=102: 100 threads wasted blocking on 1 broken service
    
With fault tolerance (timeout + circuit breaker):
    T=0:   Thread 1 calls PaymentService
    T=5:   TIMEOUT -> thread released, error returned
    T=30:  5 consecutive failures -> circuit OPENS
    T=31+: All calls fail-fast (0ms) -> thread released
    T=31+: OrderService responds (with error) in < 10ms
           Users see "Payment unavailable" immediately
           OrderService is FUNCTIONAL
```

**Timeout - the foundation:**
```
Never call a service without a timeout.

Timeout hierarchy (all required):
  1. Connection timeout: time to establish TCP connection
     Default: 1-3 seconds
     High value: 200-500ms for same-datacenter

  2. Read timeout: time to receive response after sending
     Default: varies widely
     Set based on service SLO: 2-3x normal P99

  3. Overall/call timeout: total time budget for the call
     Often missing - add this as the safety net
     Example: connection=500ms, read=5s,
              overall=5.5s

  Configuration in Spring:
    RestTemplate:
      SimpleClientHttpRequestFactory factory = ...
      factory.setConnectTimeout(500);    // 500ms
      factory.setReadTimeout(5000);      // 5s
      
    WebClient (reactive):
      .timeout(Duration.ofSeconds(5))    // overall
```

**Retry - with discipline:**
```
WHEN TO RETRY:
  - Network timeouts (likely transient)
  - 503 Service Unavailable (transient overload)
  - 429 Too Many Requests (after waiting)
  - 500 Internal Server Error (sometimes safe)

WHEN NOT TO RETRY:
  - 400 Bad Request (your request is wrong;
    retry won't fix it)
  - 401/403 (auth problem; retry won't fix it)
  - 404 (resource doesn't exist; retry won't fix it)
  - Non-idempotent operations without
    idempotency keys (POST /payments)

RETRY CONFIGURATION:
  Max attempts: 3 (1 original + 2 retries)
  Backoff: exponential with jitter
    Attempt 1: immediate
    Attempt 2: 100ms + random(0-100ms)
    Attempt 3: 200ms + random(0-200ms)
  
  Without jitter (BAD):
    1000 failed requests all retry at exactly
    T+100ms -> retry storm hits recovering service
  
  With jitter (GOOD):
    1000 failed requests retry between
    T+100ms and T+200ms -> spread load
```

**Circuit breaker states:**
```
CLOSED (normal):
  All requests pass through
  Track failure rate in sliding window
  If failures > threshold -> OPEN

OPEN (failing fast):
  All requests REJECTED immediately
  No calls to downstream service
  Wait for reset timeout (30-60 seconds)
  After timeout -> HALF-OPEN

HALF-OPEN (testing):
  Allow limited requests through
  If requests succeed -> CLOSED
  If requests fail -> OPEN again

Parameters to configure:
  failure_rate_threshold: 50%
    (open when >50% of calls fail)
  slow_call_rate_threshold: 80%
    (open when >80% of calls are slow)
  slow_call_duration_threshold: 2000ms
    (calls >2s count as "slow")
  sliding_window_size: 100 (last 100 calls)
  wait_duration_in_open: 30s
  half_open_max_calls: 10
```

**The key insight:**
The three patterns are defensive layers, not alternatives. Every service call should have ALL THREE: a timeout to prevent thread exhaustion, a retry to handle transient failures, and a circuit breaker to prevent hammering a failing service. Missing any one creates a specific vulnerability: no timeout = thread exhaustion, no retry = unnecessary failures on transient errors, no circuit breaker = retry storms on sustained failures.

---

### 💻 Code Example

```java
// BAD: No fault tolerance
@Service
public class OrderService {
  @Autowired
  private PaymentClient paymentClient;
  
  public OrderResult createOrder(OrderRequest req) {
    // No timeout: if PaymentService is slow,
    // this thread blocks indefinitely
    // No circuit breaker: if PaymentService is
    // down, every request waits for timeout
    // No retry: transient failures always fail
    PaymentResult payment =
        paymentClient.processPayment(req.getPayment());
    return OrderResult.success(payment);
  }
}
```

> **Code walkthrough:** No fault tolerance at all. When PaymentService is slow: threads block indefinitely. When 50 concurrent requests hit a 30-second slow PaymentService: 50 threads blocked for 30 seconds each. Thread pool exhausted. OrderService becomes unresponsive. One downstream failure cascades to take down the entire order creation flow.

```java
// GOOD: Full fault tolerance with Resilience4j
@Configuration
public class FaultToleranceConfig {
  
  @Bean
  public CircuitBreakerRegistry circuitBreakerRegistry() {
    CircuitBreakerConfig config = CircuitBreakerConfig
        .custom()
        .failureRateThreshold(50f)         // 50% failures
        .slowCallRateThreshold(80f)        // 80% slow calls
        .slowCallDurationThreshold(
            Duration.ofSeconds(2))         // slow = >2s
        .slidingWindowSize(100)            // last 100 calls
        .waitDurationInOpenState(
            Duration.ofSeconds(30))        // wait 30s
        .permittedNumberOfCallsInHalfOpenState(10)
        .build();
    
    return CircuitBreakerRegistry.of(config);
  }
  
  @Bean
  public RetryRegistry retryRegistry() {
    RetryConfig config = RetryConfig.custom()
        .maxAttempts(3)
        .waitDuration(Duration.ofMillis(100))
        .intervalFunction(
            // Exponential backoff with jitter
            IntervalFunction
                .ofExponentialRandomBackoff(100, 2.0))
        // Retry on these exceptions only
        .retryExceptions(
            TimeoutException.class,
            ConnectException.class)
        // Never retry on these:
        .ignoreExceptions(
            BadRequestException.class,
            UnauthorizedException.class)
        .build();
    
    return RetryRegistry.of(config);
  }
}

@Service
public class OrderService {
  private final PaymentClient paymentClient;
  private final CircuitBreaker paymentCB;
  private final Retry paymentRetry;
  
  public OrderService(
      PaymentClient paymentClient,
      CircuitBreakerRegistry cbRegistry,
      RetryRegistry retryRegistry) {
    this.paymentClient = paymentClient;
    this.paymentCB = cbRegistry
        .circuitBreaker("payment-service");
    this.paymentRetry = retryRegistry
        .retry("payment-service");
  }
  
  public OrderResult createOrder(OrderRequest req) {
    // Decorate: retry -> circuit breaker -> timeout
    Supplier<PaymentResult> paymentCall =
        () -> paymentClient.processPayment(
            req.getPayment());
    
    // Layer fault tolerance decorators
    Supplier<PaymentResult> resilientCall =
        CircuitBreaker.decorateSupplier(
            paymentCB,
            Retry.decorateSupplier(
                paymentRetry,
                paymentCall));
    
    try {
      PaymentResult payment = resilientCall.get();
      return OrderResult.success(payment);
    } catch (CallNotPermittedException e) {
      // Circuit is open: fail fast
      log.warn("Payment circuit breaker open",
          kv("state", paymentCB.getState()));
      return OrderResult.paymentUnavailable();
    } catch (Exception e) {
      // All retries exhausted
      log.error("Payment failed after retries",
          kv("attempts", 3));
      return OrderResult.paymentFailed(e.getMessage());
    }
  }
}
```

> **Code walkthrough:** Resilience4j decorates the payment call with a circuit breaker and retry. The circuit breaker tracks failure rate over a sliding window (last 100 calls). If 50% fail: circuit opens - all subsequent calls return immediately with CallNotPermittedException (0ms, no network call). Retry handles transient errors with exponential backoff and jitter. Important: BadRequestException and UnauthorizedException are NOT retried (retrying won't fix these). The 30-second wait in OPEN state gives the failing service time to recover before testing.

```java
// Fallback pattern: degrade gracefully
@Service
public class RecommendationService {
  private final RecommendationClient client;
  private final CircuitBreaker cb;
  
  // Default recommendations when service is down
  private static final List<String> DEFAULTS =
      List.of("product-101", "product-202",
              "product-303");
  
  public List<String> getRecommendations(String userId) {
    return cb.executeSupplier(
        // If circuit open or call fails: use fallback
        () -> client.getRecommendations(userId),
        // Fallback: called when circuit is open
        throwable -> {
          log.warn("Using default recommendations",
              kv("reason", throwable.getMessage()));
          return DEFAULTS;
        });
  }
}
```

> **Code walkthrough:** The fallback function is invoked when the circuit is open or the call fails all retries. The user receives default recommendations instead of an error. This graceful degradation keeps the checkout page functional even when the recommendation service is down. The key principle: degrade the feature, not the entire user experience. Only truly critical operations (payment processing, cart save) should fail the request. Non-critical features (recommendations, social proof) should degrade silently.

---

### 📊 Diagram

```
FAULT TOLERANCE PATTERNS STATE MACHINE

TIMEOUT:
  Request ----[5s limit]----> Response
              |
              [TIMEOUT: 5s exceeded]
              |
              v
         TimeoutException
         (thread released)

RETRY:
  Attempt 1 -> Fail -> Wait 100ms
  Attempt 2 -> Fail -> Wait 200ms
  Attempt 3 -> Success (or MaxAttemptsException)

  Jitter prevents retry storms:
  1000 clients all fail at T=0
  Without jitter: all retry at T=100ms (storm)
  With jitter: all retry between T=100-200ms (spread)

CIRCUIT BREAKER:
  [CLOSED]
      |
      | failure_rate > 50% in last 100 calls
      v
  [OPEN] <----fail------ [HALF-OPEN]
      |                       ^
      | wait 30s              | success
      +------------------------+
  
  In OPEN: calls return immediately (0ms)
  No calls made to downstream service
  System conserves resources
```

```mermaid
stateDiagram-v2
    [*] --> CLOSED: Initial state
    
    CLOSED --> CLOSED: Success (track)
    CLOSED --> CLOSED: Failure < threshold
    CLOSED --> OPEN: failure_rate > 50%\nor slow_call_rate > 80%
    
    OPEN --> HALF_OPEN: Wait duration elapsed (30s)
    OPEN --> OPEN: Reject all calls fast (0ms)
    
    HALF_OPEN --> CLOSED: Permitted calls succeed
    HALF_OPEN --> OPEN: Any call fails
    
    note right of OPEN: All calls fail immediately\nNo network calls made\nSaves threads + downstream load
    
    note right of HALF_OPEN: 10 probe calls allowed\nDecides: recover or re-open
```

> **Diagram walkthrough:** The circuit breaker transitions between three states driven by failure metrics. CLOSED is normal operation with failure tracking. OPEN is the protective state: 0ms responses, no load on the failing service, threads not blocked. The automatic recovery via HALF-OPEN prevents permanent circuit opening while also preventing premature re-opening before the downstream service has recovered. The sliding window (last 100 calls) means a recovering service's early successes are counted toward re-closing.

---

### 🏛️ System Design

**Problem:** Design the fault tolerance strategy for an order processing system. Critical path: checkout -> inventory check -> payment -> fulfillment notification. Requirements: (1) System must be available even when payment gateway has intermittent issues (99.5% SLA), (2) must handle bursts up to 10x normal load, (3) payment must never be duplicated.

**Design:**

**Inventory Service (internal, critical):**
- Timeout: 1000ms (99th percentile < 200ms normally)
- Retry: 3 attempts with 50ms backoff, retry only on timeout/5xx
- Circuit Breaker: open at 50% failures, 30s recovery
- Fallback: if circuit open, allow order to proceed with eventual inventory validation (async check post-order). Acceptable because inventory is updated asynchronously anyway.

**Payment Gateway (external, critical, non-idempotent):**
- Idempotency key: generate a UUID per payment attempt. Include in every call to the gateway. Idempotency key prevents double-charging on retry.
- Timeout: 30000ms (payment gateways are slow) - but use async processing.
- Retry: 2 attempts (with idempotency key). Retry only on timeout, not on 5xx (5xx may mean the charge went through).
- Circuit Breaker: open at 30% failures (stricter threshold because payment errors are high-impact), 60s recovery.
- Fallback: put payment request in a Kafka queue. Process asynchronously. Show user "payment processing" status. Notify via email when complete.

**Fulfillment Notification (internal, non-critical):**
- Timeout: 500ms
- Retry: 2 attempts
- Circuit Breaker: open at 60% failures, 30s recovery
- Fallback: write notification to a local retry table. A background job sends notifications with exponential backoff. User experience: order confirmation email may be delayed 1-5 minutes, acceptable.

**Burst handling:**
- Bulkhead pattern: separate thread pools for payment vs other services. Payment pool: 50 threads. Other services pool: 200 threads. A slow payment gateway doesn't exhaust the thread pool for inventory checks.
- Rate limiting at API Gateway: 1000 req/s per client during bursts. Excess returns 429 with Retry-After header.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Fault tolerance patterns protect your service when the services it calls fail or are slow. Timeout means if a service takes too long, give up and return an error rather than waiting forever. Retry means try again automatically for transient failures like brief network issues. Circuit breaker means stop trying to call a service that is clearly broken - return an error immediately instead of wasting time on calls you know will fail. Fallback means return a default or cached response when a service is unavailable."

**Senior / Staff:** "Fault tolerance design requires three questions per dependency: (1) What is the blast radius if this service is down? Critical = circuit breaker + fallback mandatory. Non-critical = circuit breaker + fallback to degraded experience. (2) Is the operation idempotent? If yes: retry freely with backoff. If no: use idempotency keys (include a client-generated UUID in the request; the server detects duplicate requests and returns the cached result). (3) What is the fallback? Every circuit breaker that opens needs a defined behavior. 'Return error' is a fallback. 'Return cached data' is a better fallback. 'Process asynchronously' is often the best fallback for write operations. The most sophisticated use: the Saga pattern replaces the circuit breaker fallback with a compensating transaction. Payment fails: the saga triggers inventory release and order cancellation automatically. The fallback is not just an error response but a full distributed transaction rollback."

---

### ⚠️ Common Misconceptions

**Misconception:** "Retries make the system more reliable by automatically recovering from failures."
Reality: Retries can make a system less reliable when applied without discipline. Retry amplification: if ServiceA, ServiceB, and ServiceC all retry failed calls 3 times, and ServiceD is failing: ServiceA gets 1 request. ServiceA retries ServiceB 3 times. ServiceB retries ServiceC 3 times each. ServiceC retries ServiceD 3 times each. Total calls to ServiceD: 1 * 3 * 3 * 3 = 27 for 1 original request. Retry amplification at scale: at 1000 req/s with 3-tier retry at each layer = 27,000 calls to ServiceD while it's struggling to recover. This turns a partial outage into a full outage. Rule: retry only at one layer (the outermost client), or carefully limit retry amplification (max 1 retry per hop for N-hop calls).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Retry storm - recovering service is re-overwhelmed by retries**

Symptoms: Service was failing (high error rate). Metrics show the service started recovering (error rate dropping). Then error rate spikes again immediately after recovery. Service bounces between recovering and re-failing repeatedly.

Root cause: Accumulated retries from upstream services all fire simultaneously when the service recovers. The recovering service is overwhelmed by the retry burst and fails again.

Diagnosis: Check upstream service retry configurations. Are multiple services all configured with the same fixed retry delay? Metrics: check request rate to the recovering service - if it spikes sharply the moment the service starts responding: retry storm confirmed.

Fix: (1) Add jitter to all retry configurations immediately (random(0, wait_duration) added to base wait). (2) Reduce max retry attempts at each hop (1 retry per hop maximum for multi-hop chains). (3) Add bulkhead patterns to limit max pending retries per service. (4) Consider tail-based circuit breaker that opens based on response time, not just error rate - catches the pre-failure slowdown before errors reach the retry-storm threshold.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Trade-off | 3 min | 2 |
| Scenario | 5 min | 2 |
| Debugging | 3 min | 2 |
| Design | 5 min | 2 |
| Advanced | 3 min | 2 |
| Comparison | 2 min | 1 |
| Anti-pattern | 2 min | 1 |
| Behavioral | 3 min | 1 |
| Security | 2 min | 1 |
| Scale | 3 min | 1 |

#### Q1 - "Explain the circuit breaker states and their transitions."
> "Three states: CLOSED, OPEN, HALF-OPEN. CLOSED: normal operation. Each call passes through. The circuit breaker tracks outcomes in a sliding window (count-based: last N calls, or time-based: last N seconds). When the failure rate or slow call rate exceeds the threshold: transition to OPEN. OPEN: no calls pass through. All calls return immediately with CallNotPermittedException. This state lasts for the configured wait duration (30 seconds). Purpose: give the downstream service time to recover without being hammered by requests. After wait duration: transition to HALF-OPEN. HALF-OPEN: limited calls pass through (configured permitted_number_of_calls_in_half_open_state = 10). The circuit breaker evaluates: if enough of these test calls succeed (based on the same threshold): transition to CLOSED. If any test call fails: transition back to OPEN. HALF-OPEN prevents false recovery: the circuit won't close on a single lucky request. It requires a statistically significant number of successes."

*What separates good from great:* "The wait duration in OPEN state is critical. Too short: the circuit re-closes before the downstream service has recovered. You get bounce between OPEN and HALF-OPEN. Too long: the circuit stays open after the downstream service has recovered. You unnecessarily reject requests. Dynamic wait duration: start at 30 seconds, double for each consecutive re-opening. The service that's been failing for 30 minutes probably needs more than 30 seconds of recovery time."

---

#### Q2 - "How do you make retry safe for non-idempotent operations?"
> "Non-idempotent means: calling the operation twice produces different side effects than calling it once. Example: POST /payments charges the user. Retry on failure: user might be charged twice. Solution: idempotency keys. Client generates a UUID before the first attempt: idem-key = UUID.randomUUID(). Client includes the key in every attempt: POST /payments with header Idempotency-Key: {idem-key}. Server: before processing, check if idem-key exists in the idempotency table. If yes: return the cached result. If no: process the payment, store the result with the idem-key, return the result. On retry: client sends the same idem-key. Server finds it in the idempotency table. Returns the cached result. Payment is NOT processed again. Key details: idempotency key must be unique per operation (generate a new UUID per checkout, not per session). Server must store the result for at least the max retry duration + some buffer (typically 24 hours). The idempotency store (Redis or a DB table) has TTL-based expiration."

*What separates good from great:* "Conditional idempotency for database writes: use optimistic locking with a version field. The payment table has a version column. The first write succeeds (INSERT with idempotency key). A duplicate write returns a unique constraint violation on the idempotency key. The client catches this, queries for the existing result, and returns it. This approach is database-native and requires no separate idempotency store."

---

#### Q3 - "What is a bulkhead and when should you use one?"
> "Bulkhead: isolation of resources for different consumers. Named after ship bulkheads that divide the hull into compartments. A hole in one compartment doesn't sink the ship. In microservices: separate thread pools for separate dependencies. Without bulkhead: OrderService has 200 threads. PaymentService is slow. 200 requests to checkout all call PaymentService. All 200 threads block waiting for PaymentService. InventoryService calls also use the same pool. 0 threads available for InventoryService. Both checkout AND inventory APIs fail, even though InventoryService is healthy. With bulkhead: PaymentService pool: 50 threads. InventoryService pool: 100 threads. General pool: 50 threads. PaymentService slow: 50 threads blocked. InventoryService continues with its 100 threads. Other APIs continue with their 50 threads. Only the payment checkout flow is affected, not the entire OrderService. Implementation (Resilience4j Bulkhead): configure max-concurrent-calls per bulkhead. When the bulkhead is full (all threads busy): new calls return BulkheadFullException immediately. This is faster than blocking and more predictable under load."

*What separates good from great:* "Thread pool vs semaphore bulkheads: thread pool bulkhead uses separate thread pools (more isolation, more resource overhead). Semaphore bulkhead limits concurrent calls using a counting semaphore (lighter weight, calls still run on the caller's thread). Semaphore bulkhead is appropriate for reactive (non-blocking) code where threads are not blocked. Thread pool bulkhead is appropriate for blocking I/O code where threads are blocked waiting for responses."

---

#### Q4 - "How do you test fault tolerance code in unit and integration tests?"
> "Unit testing circuit breakers: (1) Resilience4j provides test utilities. CircuitBreakerRegistry.ofDefaults() creates an in-memory registry. Manually transition the circuit: cb.transitionToOpenState(). Verify that CallNotPermittedException is thrown. Verify that the fallback is invoked. (2) Mock the downstream client to return failures. Verify the circuit transitions to OPEN after the configured threshold. Test the HALF-OPEN -> CLOSED transition. (3) Retry testing: configure a retry with small delays (1ms) for tests. Mock the client to fail twice then succeed. Verify the call ultimately succeeds after retries. Verify the correct number of attempts. Integration testing: (1) Chaos engineering in staging: use Istio fault injection to add 100% error rate to a service. Verify circuit breaker opens and fallback activates. (2) Timeout testing: Istio fault injection adds a fixed delay. Verify timeout triggers before the delay completes. (3) WireMock: stub the external service to return specific error codes or take specific delays. Test the retry and circuit breaker behavior end-to-end in a real application context."

*What separates good from great:* "Fault tolerance tests are often skipped because they seem hard to write. The cost: discovering during a production incident that the circuit breaker configuration is wrong. Test every state transition: CLOSED -> OPEN on failures, OPEN -> HALF-OPEN after wait duration, HALF-OPEN -> CLOSED on success, HALF-OPEN -> OPEN on failure. Each transition has a specific user experience impact. Test that impact explicitly."

---

#### Q5 - "A service has a circuit breaker but users still see 30-second hangs. What is wrong?"
> "Circuit breaker open should return 0ms errors, not 30-second hangs. Diagnosis: (1) Check if the circuit breaker is actually configured. Is it decorating the HTTP client call? A common mistake: the circuit breaker decorates a method that doesn't make the HTTP call. The HTTP call is in a sub-method that is not decorated. Check with metrics: is circuitbreaker.calls count increasing? If not: the decorator is not wrapping the actual call. (2) Timeout missing: the circuit breaker might be correctly configured, but there is no timeout on the HTTP call. Circuit breaker closes: calls pass through. PaymentService is slow: calls take 30 seconds. The circuit breaker counts these as slow calls but the failure rate threshold hasn't been hit yet. Add a timeout. (3) Circuit breaker threshold too permissive: failure_rate_threshold = 90% means the circuit opens only when 90% of the last 100 calls fail. If only 60% are timing out (30-second hangs), the circuit stays closed. Lower the slow_call_rate_threshold. (4) Wrong exception type: the circuit breaker is configured to count IOException. But the actual exception is SocketTimeoutException (a subclass). If configuration uses `ignoreExceptions: SocketTimeoutException`: the timeout exceptions are not counted."

*What separates good from great:* "Instrument the circuit breaker: Micrometer + Resilience4j publishes circuit breaker state as a metric (resilience4j_circuitbreaker_state). Create a Grafana dashboard showing circuit breaker state over time per service. When you see the circuit open at T=0 and close at T=30s and open again at T=60s (rapid bouncing), your wait_duration_in_open_state is too short. When the circuit never opens despite errors: your thresholds are wrong or the exceptions aren't being counted."

---

#### Q6 - "How does the saga pattern relate to fault tolerance?"
> "The saga pattern handles fault tolerance for distributed transactions. A distributed transaction across multiple services cannot use a single ACID transaction (different databases). The saga provides: if any step in a multi-step transaction fails: execute compensating transactions for already-completed steps. Example: order checkout. Step 1: reserve inventory. Step 2: charge payment. Step 3: confirm order. If Step 2 (payment) fails: compensating transaction = release inventory (reverse Step 1). If Step 3 fails: compensating transaction = refund payment (reverse Step 2) + release inventory (reverse Step 1). This is fault tolerance at the business transaction level, not just the service call level. The saga ensures the system is in a consistent state after any failure. The circuit breaker handles the mechanics (fail fast when PaymentService is down). The saga handles the business logic (what does a failed payment mean for the order and inventory state)."

*What separates good from great:* "Sagas come in two flavors: choreography (each service listens for events and reacts) and orchestration (a central saga orchestrator commands each step). The orchestrator flavor is easier to debug (one place to look for the saga state machine), easier to implement timeout handling, and provides better visibility into saga progress. The choreography flavor is more decoupled but harder to trace when failures occur (the compensating transactions are distributed across multiple services)."

---

#### Q7 - "How do you design a fallback that is actually useful?"
> "Useful fallback design: (1) Ask: what does the user need from this service, and what is the minimum acceptable response when the service is unavailable? Recommendations service: show top-selling products (static list). Not useful: show nothing. Cart price validation service: use cached price. Not useful: reject the checkout. User preference service: use default preferences. Not useful: fail the page. (2) Fallback data sources: Cache (Redis/local): the last known good response. Works for read operations with tolerable staleness. Static default: hardcoded response. Works for non-personalized data. Partial response: return what's available, omit what isn't. Works for pages with multiple data sources. Async queue: accept the request, process later. Works for write operations. (3) Communicate degradation to users transparently: if showing default recommendations, add a brief UI indicator. If checkout is processing asynchronously, show a 'payment processing' message. (4) Log all fallback activations: alert if fallback rate exceeds a threshold (1% fallback rate for 5 minutes = circuit breaker open)."

*What separates good from great:* "Fallback quality determines user experience during failures. A well-designed fallback: the user may not notice anything changed. A poorly-designed fallback (empty recommendations, missing prices, broken layout): the user perceives the service as broken. Invest in designing useful fallbacks for every circuit breaker. A circuit breaker without a useful fallback is incomplete fault tolerance."

---

#### Q8 - "What are the security implications of retry patterns?"
> "Retry security risks: (1) Retry amplification on auth endpoints: if a login service rate-limits to 10 attempts per minute and a client retries 3 times per attempt: 30 login attempts per minute instead of 10. If the rate limit is enforced per request (not per unique operation): retries bypass the intent of rate limiting. Fix: include the same idempotency key in retried auth requests. The auth service counts this as 1 attempt, not 3. (2) Retry on non-idempotent writes: already covered - can cause duplicate charges, duplicate records. Always verify idempotency before adding retries. (3) Information leakage from retry timing: different error codes or different response times on retried requests can reveal information about the server state to an attacker. Use consistent error responses and timing for auth failures. (4) Retry on rejected-by-policy requests: a 403 Forbidden means the request was understood and rejected. Retrying a 403 is security policy bypass attempt. The retry configuration must explicitly not retry 401/403. (5) DDoS amplification: if a retry multiplier (3 retries per hop x 3 hops = 27x amplification) is triggered by an attacker with a small load: the attacker sends 100 req/s, the system generates 2700 req/s internally."

*What separates good from great:* "Retry budgets: define a global retry budget. Each service has a token bucket of retry credits. When the budget is exhausted: no more retries until the bucket refills. This prevents retry amplification in attack scenarios. The retry budget is tracked per downstream service, not per request. A sudden spike in retries to PaymentService (possible indicator of payment service degradation or attack) consumes the budget quickly, which then limits retries and prevents the amplification storm."

---

#### Q9 - "How do you configure fault tolerance for a service that calls both internal and external services?"
> "Different tolerances for different dependency types: Internal services (same organization, same SLA commitment): Timeout: 500-1000ms (internal services are fast). Retry: 3 attempts with 100ms base backoff. Circuit Breaker: 50% failure rate, 30s recovery. Expectation: internal service is your team's responsibility to keep healthy. External services (third-party, SLA is theirs not yours): Timeout: depends on their SLA. Payment gateways: 30 seconds is their SLA, but your service can't block for 30 seconds. Set timeout at 10 seconds - user gets an error faster, but you've exhausted reasonable wait time. Retry: more conservative (2 attempts). You cannot control their capacity. External retry amplification is costly. Circuit Breaker: stricter threshold (30% failure = open). External service degradation should fail faster to protect your system. Fallback: async queue or 'payment processing' state for external writes. Different thread pools: use bulkheads to separate internal and external service calls. External service slowness should not exhaust threads for internal service calls."

*What separates good from great:* "Vendor SLA != your service timeout. A payment gateway with a 99.95% SLA does not guarantee < 5 seconds per call. 0.05% of calls might take 60 seconds. Your service's timeout must reflect the latency you can tolerate for your users, not the vendor's SLA. Set your timeout at the user experience limit. Then use async processing for operations that exceed that limit."

---

#### Q10 - "How do health checks interact with circuit breakers and fault tolerance?"
> "Kubernetes readiness probe: marks a pod as 'not ready' when it fails. Traffic is not routed to unready pods. This is a coarse circuit breaker at the Kubernetes level. Interaction: (1) Readiness probe fails -> pod removed from service endpoints -> traffic routed to healthy pods. The circuit breaker on callers of this service: callers have fewer healthy endpoints. If all pods become unready: the circuit breaker opens on the caller side. (2) Consistency concern: Kubernetes readiness probe removes the pod from the load balancer in the kernel (kube-proxy/Envoy). The circuit breaker in the application layer may not be aware of this change immediately. Both operate independently. The Kubernetes level provides infrastructure-level isolation. The circuit breaker provides application-level failure detection with custom logic (failure rate threshold, slow call rate). (3) Spring Boot: expose separate readiness and liveness endpoints. Readiness fails when the application's dependencies (DB, Kafka) are unreachable. Liveness fails only when the JVM is in an unrecoverable state (deadlock). Kubernetes uses readiness to route traffic - not liveness."

*What separates good from great:* "Readiness probe design: a readiness probe that queries the database on every probe request is wrong. It makes every pod's readiness dependent on DB health. During a DB maintenance window: all pods become unready simultaneously. The probe should check: is the DB connection pool responding? Not: does a specific query return the correct result. Use Spring Actuator's built-in health indicators for this: the DB health indicator does a connection test, not a business logic query."

---

#### Q11 - "How do you configure fault tolerance for a streaming (event-driven) service?"
> "Streaming services consume events from Kafka. The fault tolerance model is different from request-response. Kafka consumer fault tolerance: (1) Kafka retains messages: if the consumer fails, the messages remain in the topic. On recovery: the consumer resumes from the last committed offset. This is built-in fault tolerance at the messaging layer. (2) Consumer group rebalancing: if a consumer pod fails, Kafka rebalances partitions to healthy consumers. Messages from the failed pod's partitions are processed by other pods. (3) Dead letter queue (DLQ): for messages that consistently fail processing (invalid format, downstream always rejects): after N retries, publish to a DLQ. Human intervention or a DLQ processor handles these. (4) Retry in consumer: retry a failed Kafka message up to N times before sending to DLQ. Use a RetryTopics pattern: message goes to retry-topic-1 (immediate retry), retry-topic-2 (retry after 5s), retry-topic-3 (retry after 60s), then DLQ. (5) Circuit breaker on downstream calls from consumer: if the consumer calls ServiceB and ServiceB is down: open a circuit breaker. While circuit is open: pause consuming from Kafka (backpressure). ServiceB recovers -> resume consuming."

*What separates good from great:* "Message processing idempotency: a Kafka consumer processes a message, calls downstream services, but fails to commit the offset (crash before commit). On restart: the message is reprocessed. The downstream service receives the message again. If the downstream call is not idempotent: duplicate processing occurs. Design all event consumers to be idempotent: store a processed event ID table, check before processing. If already processed: skip and commit."

---

#### Q12 - "At scale with 500 services, how do you ensure consistent fault tolerance configuration across all services?"
> "The consistency challenge: 500 services, 50 teams, each team configures its own circuit breakers. Results: wildly inconsistent timeout and retry configurations. Some services are too permissive (30% failure rate threshold - circuit never opens). Some are too strict (5% failure rate - circuit opens constantly). Solution approaches: (1) Service mesh (Istio): offload timeout, retry, and circuit breaker configuration to VirtualService and DestinationRule YAML. Centrally managed by Platform Engineering. Consistent defaults across all services. Teams can override defaults for their specific needs. (2) Shared library with opinionated defaults: provide a company-wide Spring Boot starter that configures Resilience4j with sensible defaults. Teams override only what they need to customize. Enforce via CI: any override of a protected configuration requires an architecture review. (3) ADR (Architecture Decision Record): document the standard fault tolerance configuration. All services must comply. Validator in CI checks configuration against standard. (4) Service catalog: each service registers its fault tolerance configuration. Automated audit checks for non-compliant configurations quarterly."

*What separates good from great:* "The Istio service mesh solution is the cleanest for polyglot environments: the fault tolerance configuration is infrastructure, not code. It applies consistently to Java, Python, and Go services without requiring each team to implement Resilience4j or its equivalent. The tradeoff: the Platform Engineering team must own and maintain the Istio configuration templates, and teams must understand that their service's resilience behavior is controlled externally."

---

### ⚖️ Comparison Table

| Pattern | Problem Solved | Implementation | When to Use |
|---|---|---|---|
| Timeout | Thread exhaustion from slow service | `connectTimeout`, `readTimeout` | Always - no call without timeout |
| Retry | Transient failures | Resilience4j Retry, Istio VirtualService | Idempotent ops only, backoff+jitter |
| Circuit Breaker | Cascading failures | Resilience4j CB, Istio outlierDetection | Always for synchronous dependencies |
| Fallback | Graceful degradation | CB fallback function | Non-critical features; async for writes |
| Bulkhead | Thread pool exhaustion | Resilience4j Bulkhead | Multiple downstream dependencies |
| Rate Limiter | Overload prevention | API Gateway, Resilience4j RateLimiter | Entry points, external API calls |
| Idempotency Key | Duplicate writes on retry | Client UUID + server dedup table | Non-idempotent write operations |
