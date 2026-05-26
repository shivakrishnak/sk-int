---
layout: default
title: "Java Performance - L5 Architecture"
parent: "Java Performance"
nav_order: 7
permalink: /java-performance/l5-architecture/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Performance Architecture Patterns](#performance-architecture-patterns) | high |
| 2 | [Capacity Planning and SLA Design](#capacity-planning-and-sla-design) | high |
| 3 | [Performance Governance](#performance-governance) | medium |

---

# Performance Architecture Patterns

**Interview Weight:** high - Architect-level. Tests ability
to design systems for performance, not just optimize existing code.

---

### 🎯 Model Answer

**30 seconds:**

> Performance architecture patterns address system-level latency
> and throughput, not individual method optimization. Key patterns:
> cache-aside (avoid repeated I/O), read-through/write-through
> (data consistency with cache), event-driven (async I/O hides
> latency), bulkhead (isolate failures and resource pools),
> and CQRS (separate read and write optimizations). Choose the
> right pattern for the bottleneck type.

**3 minutes (Senior):**

> **Cache-aside pattern:**
> Application checks cache first. Cache miss: load from DB, put
> in cache. Cache hit: serve from cache. DB access: only on miss.
> Requires: cache invalidation strategy (TTL, event-driven
> invalidation). Risk: thundering herd on cache miss.
> Java: Caffeine (in-process), Redis (distributed).
>
> **Bulkhead pattern:**
> Isolate resource pools by function. Thread pool for DB calls
> separate from thread pool for external HTTP calls. If DB is
> slow and DB pool exhausts, HTTP calls are unaffected.
> Java: `ThreadPoolExecutor` per subsystem + `CircuitBreaker`
> (Resilience4j).
>
> **CQRS (Command Query Responsibility Segregation):**
> Read model optimized for queries (denormalized, cached,
> read replicas). Write model optimized for consistency
> (normalized, transactional). High-read services (10:1 read/write
> ratio) benefit: reads go to read-optimized replicas or caches.
>
> **Event-driven / async messaging:**
> Decouple producers from consumers. Producers write to queue
> (Kafka, SQS) at their rate. Consumers process at their rate.
> Benefits: natural backpressure, horizontal scaling of consumers,
> retry without producer involvement.
> Cost: eventual consistency, message ordering complexity.
>
> **Sidecar pattern for observability:**
> Performance metrics, tracing, and logging handled by a sidecar
> process (Envoy, Fluentd) rather than in the main JVM. Reduces
> in-JVM overhead of instrumentation.

---

### 💻 Code Example

**Example 1: Bulkhead + cache-aside implementation**

```java
// BULKHEAD: Separate thread pools per subsystem
// Each pool has its own queue and rejection policy
ExecutorService dbPool = new ThreadPoolExecutor(
    20, 20, 0L, MILLISECONDS,
    new ArrayBlockingQueue<>(100),
    new ThreadFactory() {
        AtomicInteger count = new AtomicInteger();
        public Thread newThread(Runnable r) {
            return new Thread(r, "db-pool-" + count.incrementAndGet());
        }
    },
    new ThreadPoolExecutor.AbortPolicy()  // reject when saturated
);

ExecutorService httpPool = new ThreadPoolExecutor(
    10, 10, 0L, MILLISECONDS,
    new ArrayBlockingQueue<>(50),
    r -> new Thread(r, "http-pool"),
    new ThreadPoolExecutor.CallerRunsPolicy()  // backpressure for HTTP
);

// DB slowness cannot starve httpPool threads
// Even if all 20 dbPool threads are blocked on slow DB,
// httpPool's 10 threads remain available for external HTTP calls

// CACHE-ASIDE with thundering-herd protection
class UserService {
    private final Cache<Long, UserProfile> cache = Caffeine.newBuilder()
        .maximumSize(10_000)
        .expireAfterWrite(5, MINUTES)
        .recordStats()   // cache hit rate in metrics
        .build();

    // ConcurrentHashMap for in-flight requests (thundering herd prevention)
    private final ConcurrentHashMap<Long, CompletableFuture<UserProfile>>
        inFlight = new ConcurrentHashMap<>();

    CompletableFuture<UserProfile> getUser(long userId) {
        UserProfile cached = cache.getIfPresent(userId);
        if (cached != null) return CompletableFuture.completedFuture(cached);

        // BAD: cache miss → N threads all load from DB simultaneously
        // return CompletableFuture.supplyAsync(() -> db.loadUser(userId), dbPool);

        // GOOD: deduplicate in-flight requests (only ONE DB call per key)
        return inFlight.computeIfAbsent(userId, key ->
            CompletableFuture
                .supplyAsync(() -> db.loadUser(key), dbPool)
                .whenComplete((profile, ex) -> {
                    inFlight.remove(key);        // remove in-flight marker
                    if (profile != null) cache.put(key, profile);  // populate cache
                })
        );
        // All concurrent requests for same userId share the single CompletableFuture
    }
}
```

> **Code walkthrough:** The bulkhead uses named thread pools per
> subsystem. When the database is slow and all 20 `dbPool` threads
> are blocked, the `httpPool` threads are completely unaffected.
> Without bulkheads, a slow database could exhaust a shared thread
> pool and prevent HTTP calls from completing. The thundering herd
> protection in `getUser()` uses `computeIfAbsent` atomically:
> the first caller creates the `CompletableFuture`, all subsequent
> callers for the same `userId` receive the same future, and they
> all complete when the single DB load finishes.

---

### ⚖️ Comparison

| Pattern | Bottleneck Addressed | Java Implementation | Cost |
|---|---|---|---|
| Cache-aside | Repeated DB reads | Caffeine, Redis | Cache invalidation complexity |
| Bulkhead | Resource pool exhaustion | ThreadPoolExecutor per pool | Pool sizing overhead |
| CQRS | Read/write contention | Read replicas + event sourcing | Eventual consistency |
| Event-driven | Synchronous coupling | Kafka, SQS + consumers | Message ordering, duplication |
| Sidecar | Instrumentation overhead | Envoy, agent | Sidecar resource cost |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Cache-aside reduces DB load. Bulkheads prevent one slow
> subsystem from starving others. Event-driven decouples
> producers and consumers for independent scaling.

---

**Senior / Staff (5+ years):**

> I select patterns based on the measured bottleneck: cache
> if repeated I/O, bulkhead if subsystem failure cascades,
> CQRS if read/write contention limits scaling. Every pattern
> has trade-offs - I choose the simplest one that solves the
> measured problem.

---

### ❓ Questions You Will Be Asked

#### System Design

- "Design a high-performance user profile service that handles
  100,000 reads per second with 1% writes."

🗣️ "The 100:1 read/write ratio makes this cache-dominated.
Architecture: 1) Write path: user writes go to a primary DB
(PostgreSQL) and publish an event to Kafka. An async consumer
updates a distributed cache (Redis). Writes are consistent but
not on the critical read path. 2) Read path: application checks
local in-process cache (Caffeine, 10k entries, 1-minute TTL) first.
On miss, check Redis. On miss, load from PostgreSQL read replica.
Three cache levels: L1=Caffeine (~1ns), L2=Redis (~500µs),
L3=DB read replica (~5ms). 3) Cache invalidation: Kafka event from
write path consumed to invalidate Redis + Caffeine entries.
Eventually consistent: a read might see stale data for up to
1 minute (TTL). 4) Thread pools: separate pool for Redis calls,
separate for DB calls. Bulkhead: Redis failure does not cascade
to DB pool. 5) Throughput estimate: 100k RPS with 90% cache hit
= 10k DB reads/second. Each DB read = 5ms = 10,000 × 0.005 = 50
concurrent DB reads. Thread pool for DB: 75 threads."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Pattern mechanics, thundering herd, bulkhead setup. |
| Hiring Manager   | Trade-off awareness, pattern selection rationale. |
| Bar Raiser       | Write-behind cache, eventual consistency guarantees, circuit breaker integration. |
| Peer Engineer    | "Bulkhead saved our payment service when our notification DB went down..." |

---

---

# Capacity Planning and SLA Design

**Interview Weight:** high - Architect-level. Tests ability
to design SLAs and provision for growth.

---

### 🎯 Model Answer

**30 seconds:**

> Capacity planning determines: how many instances needed for a
> given load, how much headroom for growth, and what the SLA
> targets should be. Key inputs: measured p50/p99 latency per
> instance, CPU and memory utilization per instance, traffic
> growth rate. Key formula: instances = peak_throughput /
> max_throughput_per_instance. SLAs must be percentile-based
> (p99 < 100ms), not average-based.

**3 minutes (Senior):**

> **Capacity planning workflow:**
>
> Step 1: Load test to find single-instance capacity.
> - Run increasing load until: CPU >70%, p99 latency > SLO target,
>   OR error rate > 0.01%.
> - This is the maximum safe throughput per instance (MSTP).
>
> Step 2: Size for peak with headroom.
> `instances = ceil(peak_throughput / (MSTP * 0.7))`
> 0.7 = 70% utilization target. 30% headroom for spikes and
> rolling restarts.
>
> Step 3: Verify with load test at target instance count.
> Run at `peak_throughput * 1.3` (130% of expected peak).
> All instances at <100% CPU, p99 within SLO.
>
> **SLA design principles:**
> - Use percentiles: p99, not average.
> - Account for downstream latency: service SLA must be achievable
>   given upstream dependencies' SLAs.
> - Define error budget: 99.9% availability = 43 minutes/month
>   downtime budget. Burn rate alerts.
> - Seasonal peaks: design for 2x-3x normal peak.
>
> **Little's Law for capacity:**
> At target throughput T and target p50 latency L:
> Required concurrency C = T × L.
> Required threads (platform): C + 20% buffer.
> Required CPU: C × per-request CPU utilization.

---

### 💻 Code Example

**Example 1: Capacity planning calculation**

```bash
# STEP 1: Load test - find single-instance max safe throughput (MSTP)
# Using k6 (or wrk/gatling/locust)

k6 run --vus 100 --rps 500 --duration 5m load-test.js
# Ramp up RPS until p99 > 100ms or CPU > 70%:

# RESULTS (increasing load):
# RPS=200: p50=8ms  p99=45ms  CPU=25%  errors=0%   → healthy
# RPS=400: p50=10ms p99=65ms  CPU=48%  errors=0%   → healthy
# RPS=600: p50=15ms p99=95ms  CPU=68%  errors=0%   → near limit
# RPS=700: p50=25ms p99=180ms CPU=78%  errors=0.3% → over limit
# → MSTP = 600 RPS per instance (p99 < 100ms at 70% CPU)

# STEP 2: Size for production
# Expected peak: 3,000 RPS (Black Friday forecast: 2x normal 1,500 RPS)
# Required instances: ceil(3,000 / (600 * 0.7)) = ceil(7.14) = 8 instances
# Plus rolling restart headroom: deploy 10 instances
# Verify: 3,000 / 10 = 300 RPS per instance = 50% utilization (good headroom)

# STEP 3: Set Kubernetes HPA
# Target: scale up when CPU > 60% (before hitting MSTP at 70%)
kubectl autoscale deployment user-service \
  --min=3 --max=20 \
  --cpu-percent=60
# Alternatively: custom metric (requests per second / pod)

# STEP 4: Define SLA based on load test data
# Internal SLO: p99 < 100ms at peak load (3,000 RPS, 10 instances)
# External SLA: p99 < 150ms (50ms buffer for network and client processing)
# Availability SLO: 99.95% (2.2 hours/year downtime budget)

# MONITORING: track against SLO
# Prometheus alert rule:
# alert: UserServiceP99SLO
#   expr: histogram_quantile(0.99,
#         rate(http_request_duration_seconds_bucket[5m])) > 0.1
#   for: 5m
#   annotations: { summary: "p99 latency > 100ms for 5 minutes" }
```

> **Code walkthrough:** The load test determines MSTP empirically
> - the actual safe throughput for the specific application,
> not a theoretical calculation. The 70% utilization target
> (0.7 multiplier) provides 30% headroom: enough to absorb
> traffic spikes, rolling restarts (1 instance down means the
> rest handle its share), and measurement variance. The HPA
> threshold of 60% CPU triggers scale-out before hitting 70%
> MSTP - adding capacity before performance degrades.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Load test to find per-instance capacity. Size for peak with
> 30% headroom. Set SLAs as percentiles (p99), not averages.
> Use Little's Law for thread pool sizing.

---

**Senior / Staff (5+ years):**

> Capacity planning is a continuous process: load test before
> every major traffic event (launch, sale), review monthly.
> I set error budgets (e.g., 1 hour/month) and burn rate alerts
> to catch gradual degradation before an SLO breach.

---

### ❓ Questions You Will Be Asked

#### System Design

- "How do you determine the right SLA for a new service?"

🗣️ "Three inputs define the SLA: (1) Business requirements: what
is the user experience impact of latency? For payment APIs, p99
> 200ms is unacceptable. For batch reports, p99 > 5s is fine.
(2) Technical capability: what can the service reliably deliver
at peak load? Load test at 130% of expected peak, observe p99.
The SLA must be achievable under load. (3) Upstream dependency
budget: if the service calls three upstream APIs with p99 of 30ms,
50ms, and 40ms, the minimum achievable latency (serial calls)
is 120ms. For parallel calls, it's 50ms. The SLA must account
for the sum or max of dependencies. I set the SLA at 1.5x the
p99 observed in load testing at peak. This provides a buffer
for production variance (cold starts, GC pauses, network jitter).
For availability: start with 99.9% (43min/month downtime). Upgrade
to 99.99% only if the deployment, monitoring, and runbook are
mature enough to support it."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Capacity math, load test methodology. |
| Hiring Manager   | SLA design, business alignment. |
| Bar Raiser       | Error budget, burn rate alerts, multi-region capacity. |
| Peer Engineer    | "We load-tested our way to 10 instances instead of the 'feel right' 20..." |

---

---

# Performance Governance

**Interview Weight:** medium - Organizational meta-skill.
Tests ability to maintain performance standards across a team.

---

### 🎯 Model Answer

**30 seconds:**

> Performance governance ensures performance doesn't degrade over
> time: regression detection (CI benchmarks), performance budgets
> (p99 SLO enforced in staging), and production monitoring
> (alert on SLO breach). The key failure: treating performance
> as a one-time tuning task rather than an ongoing discipline.
> Governance makes performance a shared responsibility.

**3 minutes (Senior):**

> **Performance governance components:**
>
> **1. Regression detection in CI:**
> JMH benchmarks for critical hot paths. Run on every PR.
> Alert if a benchmark regresses > 10%.
> Tools: JMH + GitHub Actions + benchmark result comment on PR.
>
> **2. Performance gates in staging:**
> Automated load test before every production deployment.
> Fail deployment if p99 > SLO threshold or error rate > 0.1%.
> Tools: k6/Gatling + CI/CD pipeline gate.
>
> **3. Production SLO dashboards:**
> Grafana dashboard showing p50/p99 latency, error rate, GC
> pause frequency, CPU, and heap usage. Alert on SLO breach.
> Weekly review of p99 trend - gradual degradation is harder
> to catch than sudden spikes.
>
> **4. Heap and GC analysis on every incident:**
> Post-incident review includes JFR dump analysis. Any production
> incident with latency spikes gets a GC log review.
>
> **5. Performance champions:**
> One engineer per team is the performance point of contact.
> Reviews performance-sensitive PRs, maintains benchmarks,
> runs load tests before major releases.
>
> **6. Performance budgets:**
> Assigned to features: "this feature may add at most 5ms to
> p99 latency". Forces trade-off discussions before development,
> not after deployment.

---

### 💻 Code Example

**Example 1: CI performance gate setup**

```java
// JMH Benchmark in CI (Maven build)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
@State(Scope.Thread)
@Warmup(iterations = 3, time = 1)
@Measurement(iterations = 5, time = 1)
@Fork(2)
public class CriticalPathBenchmark {

    @Benchmark
    public OrderDto serializeOrder(Blackhole bh) {
        Order order = testOrder;
        return OrderMapper.toDto(order);  // critical hot path
    }

    @Benchmark
    public boolean validateOrder(Blackhole bh) {
        return OrderValidator.validate(testOrder);
    }
}
// Baseline stored in repository: benchmarks/baseline.json
// CI compares new results against baseline
// Fail if any benchmark > baseline * 1.1 (10% regression threshold)
```

```yaml
# GitHub Actions CI performance gate
name: Performance Check

on: [pull_request]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run JMH Benchmarks
        run: |
          mvn -pl benchmarks verify -Pbenchmark \
            -Djmh.output=json \
            -Djmh.result=target/benchmark-results.json

      - name: Compare Against Baseline
        run: |
          python3 scripts/compare_benchmarks.py \
            --baseline benchmarks/baseline.json \
            --current target/benchmark-results.json \
            --threshold 1.10
          # Exits with code 1 if any benchmark regressed > 10%

      - name: Post Results to PR
        uses: actions/github-script@v6
        with:
          script: |
            const results = require('./target/benchmark-results.json')
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              body: formatBenchmarkResults(results)
            })
```

> **Code walkthrough:** The CI benchmark gate provides the earliest
> possible regression signal: before code merges to main. The
> `compare_benchmarks.py` script fails the build if any benchmark
> regresses beyond 10%, requiring the author to justify the change.
> The PR comment with formatted benchmark results makes performance
> data visible to reviewers without needing to run benchmarks
> themselves.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Performance governance means: CI benchmarks catch regressions
> before production, staging load tests gate deployments, and
> production SLO dashboards alert on breaches.

---

**Senior / Staff (5+ years):**

> Performance governance is fundamentally about culture: treating
> performance as a first-class feature with the same rigor as
> correctness. I've seen services degrade 3x over a year from
> accumulated small regressions that each seemed minor but
> compounded. CI benchmarks and weekly p99 trend reviews prevent
> this.

---

### ❓ Questions You Will Be Asked

#### Behavioral

- "How have you prevented performance regressions from reaching
  production?"

🗣️ "Three layers: First, CI benchmarks on hot code paths. I used
JMH to benchmark our serialization and validation layers, stored
baseline results in the repo, and added a CI step that fails
the PR if any benchmark regresses more than 10%. This caught 4
regressions in 3 months - all from well-intentioned refactoring
that changed method sizes and broke JIT inlining. Second, staging
load test gate. Every release candidate runs a 10-minute k6 load
test at 110% of expected peak. If p99 exceeds our SLO or error
rate exceeds 0.1%, the deployment is blocked. Third, production
SLO monitoring with burn rate alerts. A Grafana alert fires if
p99 latency consumes our error budget faster than expected (burn
rate > 1x). This catches gradual degradations that stay under
the single-point alert threshold but will eventually breach
the SLO. The discipline: never treat a performance regression
as 'acceptable' just because it's small. Small regressions compound."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | CI benchmark setup, regression threshold. |
| Hiring Manager   | Team culture, prevention vs reaction. |
| Bar Raiser       | Error budget consumption, burn rate SLO, canary analysis. |
| Peer Engineer    | "JMH CI gate caught a 15% regression from an innocent-looking refactor..." |
