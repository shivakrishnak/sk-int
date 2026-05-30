---
layout: default
title: "Java Performance - L1 Measurement"
parent: "Java Performance"
grand_parent: "SK Interview"
nav_order: 3
permalink: /java-performance/l1-measurement/
render_with_liquid: false
---

# Java Performance - L1 Measurement

## Performance Measurement: Metrics, Percentiles, and Baselines

### 🎯 Model Answer

**30 seconds:**
> Performance measurement: collect the right metrics, report as percentiles (not averages),
> establish baselines. Key metrics: latency (p50/p95/p99), throughput (RPS), error rate,
> resource usage (CPU, GC, memory). A baseline is the measured value under a known workload.
> Without a baseline: you can't quantify improvement or detect regression.

**3 minutes (Senior):**
> Measurement discipline:
>
> 1. **Metric selection**: not all metrics matter equally. Identify the SLO (Service Level Objective):
>    e.g., "p99 latency < 200ms, error rate < 0.1%, throughput > 500 RPS." These are the metrics
>    that define success. Everything else is diagnostic (helps explain why, but doesn't define the target).
>
> 2. **Percentiles**: measure distributions, not averages. p50 = median (typical). p95 = 95th percentile
>    (most users). p99 = 99th percentile (tail, SLA-critical). Collect percentile metrics with
>    Micrometer + Prometheus. Visualize with Grafana.
>
> 3. **Baselines**: before any optimization: measure the current state under production-representative
>    load. Record in documentation or version control. After optimization: re-measure same conditions.
>    Delta = improvement. Without baseline: regression tests fail silently.
>
> 4. **Benchmarking correctness**: JVM warmup (first N invocations are slow, JIT not yet compiled).
>    Measurement noise (OS scheduling, GC during measurement). Statistical significance (multiple
>    runs, outlier detection).
>
> 5. **THROUGHPUT vs LATENCY in measurement**: don't measure latency at max throughput (the system
>    is saturated, queuing inflates latency). Measure latency at a realistic concurrency level.
>    Load test: ramp from 0 to target concurrency, record latency at each step. The "knee" of the
>    curve: where latency starts rising steeply (saturation point).

**Blank Mind Recovery:**

**(1) Restate:** "Metrics: latency (p99), throughput (RPS), error rate, resource (CPU/GC). Percentiles, not averages. Baseline = current state under known load. Without baseline: can't measure improvement."

**(2) First principles:** "A metric is a number that answers a specific question. Choose the question first. Percentile: what is the threshold that N% of requests stay under? Baseline: what is the starting point before any change?"

**(3) Bridge:** "Measuring performance without a baseline is like a fitness program without an initial weigh-in. You do all the work, then have no way to know if it helped. The baseline is your 'before photo.' The post-optimization measurement is your 'after photo.' Without both, you're just guessing."

---

### 📘 Concept Explanation

**Metric taxonomy and baseline methodology:**
```
LATENCY MEASUREMENT:

  What to collect (at minimum):
    p50 (median): 50% of requests complete within this time
    p95:          95% of requests complete within this time
    p99:          99% of requests complete within this time (SLA metric)
    p999 or max:  for identifying extreme outliers
  
  How percentiles are computed:
    Option A: Client-side (Micrometer with publishPercentiles):
      Computed in-process, published as gauge.
      Fast, low-cardinality, but cannot aggregate across instances.
      Use when: 1 instance, or each instance's p99 matters separately.
    
    Option B: Server-side (Micrometer publishPercentileHistogram):
      Publishes histogram buckets to Prometheus.
      Prometheus computes percentiles at query time.
      Use histogram_quantile(0.99, rate(...bucket[5m]))
      Can aggregate across instances:
      histogram_quantile(0.99, sum(rate(...bucket[5m])) by (le))
      Use when: multiple instances, need fleet-wide p99.
  
  What NOT to collect:
    Average (hides tail)
    Max (single outlier, not actionable)

THROUGHPUT:
  Requests per second (RPS): total requests / elapsed seconds
  Saturation point: when adding more requests causes latency to rise
  Measure via: load generator (Gatling, k6) or APM (Datadog)

ERROR RATE:
  Percentage of requests ending in error (HTTP 5xx, exception)
  SLO example: "error rate < 0.1% over 5-minute window"
  Alert: if error rate > 0.5% for 5 minutes: page on-call

RESOURCE METRICS:
  CPU utilization (%)
  GC overhead (% of CPU time in GC) - from JFR or GC logs
  Heap utilization (%)
  Thread count

BASELINE ESTABLISHMENT:
  1. Choose representative workload:
     - Production traffic replay (best), or
     - Load test matching production rate (realistic RPS, data distribution)
  2. Stabilize the system: let it warm up (JIT), reach steady-state
  3. Measure for >= 5 minutes (captures multiple GC cycles)
  4. Record: date, JVM version, code version, workload type, all metrics
  5. Store: in git (docs/performance-baselines.md), tied to commit hash
  
  Baseline example (documentation format):
  Date: 2025-01-15 | Version: main@3a4b2c | JVM: JDK 21, G1
  Workload: 200 concurrent users, GET /api/users, 60s duration
  p50: 12ms | p95: 45ms | p99: 120ms | RPS: 1,850 | Error: 0.02%
  CPU: 65% | GC overhead: 3.2% | Heap: 1.8GB / 4GB max

PERFORMANCE REGRESSION TESTING:
  After any code change: re-measure against baseline.
  Regression: any metric degrades > 10% (configurable threshold).
  Tools: Gatling with CI integration, k6 cloud thresholds,
         JMH with perfomance thresholds in CI pipeline.
```

---

### 💻 Code Example

> **Code walkthrough:** The Micrometer timer configuration shows the difference between
> client-side and server-side percentiles. The Prometheus query shows how to compute fleet-wide
> p99 by aggregating histogram buckets across all instances.

```java
// MICROMETER PERCENTILE CONFIGURATION (Spring Boot):

// application.properties - global percentile configuration:
// management.metrics.distribution.percentiles.http.server.requests=0.5,0.95,0.99
// management.metrics.distribution.percentiles-histogram.http.server.requests=true

// Custom timer (for non-HTTP operations):
@Configuration
public class MetricsConfig {
    
    @Bean
    public MeterRegistryCustomizer<MeterRegistry> timerCustomizer() {
        return registry -> {
            registry.config()
                .meterFilter(MeterFilter.maxExpected("order.processing",
                    Duration.ofSeconds(2)));  // histogram bucket upper bound
        };
    }
}

@Service
public class OrderService {
    
    private final Timer orderTimer;
    
    public OrderService(MeterRegistry registry) {
        this.orderTimer = Timer.builder("order.processing")
            .description("Order processing latency")
            .publishPercentiles(0.50, 0.95, 0.99)  // client-side
            .publishPercentileHistogram()            // server-side (Prometheus)
            .register(registry);
    }
    
    public Order processOrder(OrderRequest request) {
        return orderTimer.record(() -> doProcessOrder(request));
    }
    
    private Order doProcessOrder(OrderRequest request) {
        // actual business logic
        return new Order(request);
    }
}

// PROMETHEUS QUERIES (Grafana dashboard):

// p99 per instance (client-side metric):
// order_processing_seconds{quantile="0.99"}

// p99 fleet-wide (aggregated histogram):
// histogram_quantile(0.99, 
//   sum(rate(order_processing_seconds_bucket[5m])) by (le)
// )

// Throughput (RPS):
// sum(rate(order_processing_seconds_count[5m]))

// Error rate:
// sum(rate(http_server_requests_total{status=~"5.."}[5m]))
// /
// sum(rate(http_server_requests_total[5m]))
```

> **Code walkthrough:** The `publishPercentiles` call computes percentiles in-process (fast, no
> Prometheus aggregation needed, but can't combine instances). The `publishPercentileHistogram`
> publishes HDR histogram buckets (high dynamic range) to Prometheus. The Prometheus
> `histogram_quantile` function can then compute any percentile at query time AND aggregate
> across all pod instances - critical for getting the actual fleet-wide p99 instead of per-pod p99.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Use p99 latency, not average. Establish a baseline before optimizing. Micrometer records metrics,
> Prometheus stores them, Grafana shows them. Baseline: write down the current p99/RPS before any
> change. Compare after the change.

---

**Senior / Staff (5+ years):**
> Histogram vs gauge percentiles: gauge percentiles are cheap but can't aggregate. Histogram
> percentiles are slightly larger (bucket series) but allow Prometheus to compute fleet-wide
> quantiles. For a load-balanced service: fleet-wide p99 is the real user experience. Per-pod
> p99: can hide that one pod has a memory leak causing p99 = 2000ms while others are 100ms.
> The fleet-wide metric catches this. Also: histogram buckets must cover the range (use
> `maxExpected` to set the upper bucket bound, or buckets above the SLA are meaningless).

---

### ⚠️ Common Misconceptions

**Misconception: "A 10-second load test is sufficient to establish a baseline."**
10 seconds captures maybe 2-3 GC cycles and 1-2 JIT compilation events. It doesn't capture:
memory growth patterns (which take minutes to manifest), GC behavior at steady state, or
scheduled tasks (running every minute or 5 minutes). A production-representative baseline:
minimum 5 minutes, ideally 30 minutes. This allows GC to cycle multiple times, caches to warm
up, connection pools to stabilize. For applications with periodic batch jobs: measure over at
least one batch cycle duration.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Performance regression undetected until user complaints.**
```
Symptom: Users report slowness 2 weeks after a major refactor.
  No alerts fired. Dashboard shows "normal."

Root cause: No performance baseline was established before the refactor.
  The monitoring thresholds were set to alert only on 5x degradation
  (set high to reduce false alarms). The refactor introduced a 2x
  p99 degradation (from 100ms to 200ms): below alert threshold.

Fix:
  1. Establish a baseline tied to a specific commit:
     Run load test on the commit before the refactor.
     Record: p99 = 100ms, RPS = 500, error = 0.01%.
  
  2. Add regression gate in CI:
     After every PR: run a 5-minute load test.
     Threshold: p99 must be < 1.2x the baseline (< 120ms).
     If exceeded: fail the build and block merge.
  
  3. Tools: Gatling + baseline comparison plugin, k6 thresholds,
     JMH with historical result tracking (jmh-visualizer).
  
  4. Dashboard improvement: set alerts at 1.5x baseline, not 5x.
     False alarms are preferable to missed regressions.

Prevention:
  Before every significant refactor:
    Run load test -> record baseline -> commit to docs/
    After refactor: re-run same load test -> compare to baseline
    Gate: if p99 > baseline * 1.2: review before merging
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Why percentiles over averages | 1 minute |
| Client-side vs server-side percentiles | 2 minutes |
| Baseline establishment steps | 2 minutes |
| What makes a good load test | 2 minutes |
| Performance regression detection | 1 minute |
| SLO vs SLA | 1 minute |
| Little's Law for throughput modeling | 1 minute |

---

**Q1 (percentiles): If average latency is fine but users are complaining, what's likely wrong?**

A: Tail latency (p99 or p999) is elevated. Example: p50 = 10ms, p95 = 30ms, p99 = 5000ms.
Average may be 50ms (acceptable) but 1 in 100 requests is 5 seconds. Users who hit the 5-second
request have a bad experience. Common root cause of p99 elevation: GC pauses (stop-the-world),
lock contention (thread waiting), slow DB queries (occasional cache miss hits the DB), external
service timeout (circuit breaker not triggered).

*What separates good from great:* The "tail latency amplification" in microservices: if a user
request makes 10 downstream service calls, and each service has 1% p99 outliers, the probability
of hitting at least one outlier is `1 - 0.99^10 = 9.6%`. Nearly 1 in 10 user requests hits a slow
component. This is why microservice architectures need p99 targets for internal services that are
much lower than the user-facing SLA. If user SLA is p99 < 200ms for a request with 10 internal calls:
each internal service needs p99 < 20ms to have reasonable probability of the end-to-end SLA being met.

---

**Q2 (baselines): What should be included in a performance baseline document?**

A: Environment: JVM version, JVM flags, hardware/instance type, container limits. Application:
git commit hash, key configuration (thread pool sizes, cache sizes). Workload: load generator
tool and config, number of concurrent users, test duration, data distribution (realistic data,
not synthetic). Results: p50/p95/p99 latency, throughput (RPS), error rate, CPU utilization,
GC overhead (%), heap usage. Storage: in the repository (docs/baselines/ or in CI artifacts).
Date and who ran it.

*What separates good from great:* The "reproducibility" criterion: a baseline only has value if
the test that produced it can be reproduced exactly. This means: the load test script must be
version-controlled, the test data must be recreatable (fixed seed or static dataset), the
environment must be specifiable (instance type, JVM flags). Without reproducibility: the baseline
is a historical artifact with no comparison value. When a regression occurs 6 months later: you
need to re-run the baseline test on the current code to confirm the regression and isolate it.

---

**Q3 (slo): What is the difference between SLA and SLO?**

A: SLO (Service Level Objective): the internal target. "We aim for p99 < 100ms." This is what the
team commits to internally and what alerts fire against. SLA (Service Level Agreement): the
contractual commitment to an external customer. "We guarantee p99 < 200ms to paying customers.
Breach: credits issued." SLO is stricter than SLA: internal target is tighter than the external
contract to leave buffer. If SLO is at 100ms and SLA at 200ms: there's 100ms of "error budget"
before breaching the customer-facing commitment.

*What separates good from great:* The SRE concept of "error budget": the allowable violation of
the SLO. "p99 < 100ms 99.9% of the time" means 0.1% of 5-minute windows can have p99 > 100ms.
Over a 30-day month: 0.001 * 30 * 24 * 60 / 5 = 8.6 5-minute windows. The error budget =
8.6 windows per month. Tracking error budget burn rate: if you've used 80% of your monthly
budget in the first week: you're burning 4x faster than target. Alert engineers, freeze deployments.
This transforms SLO monitoring from a binary pass/fail to a rate-based early warning system.

---

---

## CPU Profiling Basics: Flame Graphs and Sampling

### 🎯 Model Answer

**30 seconds:**
> CPU profiler: samples the call stack of all threads at regular intervals (e.g., every 1ms).
> After N samples: a flame graph shows which stack frames appear most often = hot spots = where
> CPU time is spent. Async-profiler: the standard tool. Output: SVG/HTML flame graph.
> Wide frame = more CPU time. Read from bottom (main) to top (where time is spent).

**3 minutes (Senior):**
> CPU profiling mechanics:
>
> 1. **Sampling**: at each interval, pause one thread, capture its stack trace, resume. No code
>    modification needed. Low overhead (~1-2%). Async-profiler uses OS signals (`SIGPROF`)
>    to interrupt threads, captures stacks using `AsyncGetCallTrace` API.
>
> 2. **Flame graph**: aggregate all captured stacks. x-axis = % of CPU time (wider = more time).
>    y-axis = call depth. Bottom = `main()`. Top = where time was actually spent. A wide plateau
>    near the top = the hot method. Reading: find the widest frame near the top.
>
> 3. **Differential flame graph**: compare two flame graphs (before/after optimization). Red frames =
>    more CPU time after. Blue frames = less CPU time. Shows exactly what changed.
>
> 4. **Wall-clock mode**: instead of CPU time, samples all threads including those waiting on IO,
>    sleeping, or blocked on locks. Useful for finding where LATENCY time is spent (not just CPU).
>    A thread blocked waiting for a DB response: shows up in wall-clock, not in CPU mode.
>
> 5. **Allocation mode**: samples allocation events instead of CPU. Shows which code paths allocate
>    the most objects. The foundation of GC optimization work.

**Blank Mind Recovery:**

**(1) Restate:** "async-profiler: sample call stacks every 1ms. Flame graph: x-axis = % time, y-axis = depth. Wide frame at top = hot spot. Modes: cpu (CPU time), wall (all threads including IO wait), alloc (allocation rate)."

**(2) First principles:** "To find where time is spent: observe the system at random moments. If a method is running in 50% of observations: it consumes 50% of the time. This is sampling. Enough samples: accurate statistical representation of CPU usage."

**(3) Bridge:** "A flame graph is like a bar chart of what your code is doing. Tall and narrow = deep call chain but fast. Short and wide = shallow but expensive. The widest bar near the top = the bottleneck. Fix the widest bar first."

---

### 📘 Concept Explanation

**Flame graph anatomy and async-profiler usage:**
```
FLAME GRAPH ANATOMY:

  main() ################################################# [100%]
  |
  handleRequest() ########################################  [95%]
  |
  processOrder() #######################################    [88%]
  |              |
  serialize()    compute()   db.query()
  ##########     ####        #####
  [42%]          [20%]       [26%]
  |
  JSON.write()  ##########
  |             [40%]
  ObjectMapper.serialize() ########## [35%]  <- HOTSPOT (wide, near top)
  |
  ReflectionUtils.getFields() ####### [30%]  <- actual hot method

  Reading: ObjectMapper.serialize() via reflection is 35% of all CPU time.
  Fix: switch from reflection-based (Jackson) to generated code (Protobuf/record)

ASYNC-PROFILER COMMANDS:

  Attach to running JVM (most common):
  # CPU profiling, 30 seconds, output HTML flame graph:
  ./profiler.sh -d 30 -f flamegraph.html <pid>
  
  # Wall-clock mode (includes IO wait, blocked threads):
  ./profiler.sh -d 30 -e wall -f wall-flamegraph.html <pid>
  
  # Allocation profiling:
  ./profiler.sh -d 30 -e alloc -f alloc-flamegraph.html <pid>
  
  Agent mode (start with JVM):
  java -agentpath:/opt/async-profiler/lib/libasyncProfiler.so=\
    start,event=cpu,file=flamegraph.html,interval=1ms,duration=60 \
    -jar myapp.jar
  
  JFR output (can open in JDK Mission Control):
  ./profiler.sh -d 60 -o jfr -f recording.jfr <pid>

READING THE FLAME GRAPH:

  Top-down reading:
    Start from the top (leaf frames). Find the WIDEST leaf frame.
    That method is where the most CPU time is spent.
    Below it: the callers. This is the hot path.
  
  Bottom-up reading:
    Start from a specific method you care about.
    Look at its width: its proportion of total CPU time.
    Look at callers (below): which call chain leads to it.
  
  Colors: async-profiler uses colors by default to indicate:
    Green: Java (interpreted)
    Yellow: Java (JIT compiled) - most application code will be here
    Orange: C1-compiled code
    Red: JVM internal / native code
    Green with stripes: inlined code (good - escape analysis may apply)

CPU vs WALL TIME:

  CPU mode: counts only cycles where the thread is running on CPU.
    Good for: finding compute bottlenecks.
    Misses: IO wait, sleep, lock wait, GC pause (running on GC threads, not app threads).
  
  Wall mode: counts all time regardless of thread state.
    Good for: finding latency sources (why requests are slow).
    Shows: time waiting for DB, time waiting for lock, time in GC.
    Use when: p99 is high but CPU profile shows no hot code.
```

---

### 💻 Code Example

> **Code walkthrough:** The profiling workflow shows how to interpret a flame graph output and
> map it to a code change. The before/after comparison demonstrates how to verify that the
> optimization actually worked using profiler data, not just latency metrics.

```java
// PROFILING WORKFLOW - step by step:

// STEP 1: Run async-profiler during a load test
// Terminal 1: Load test
//   ./gradlew test --tests "*LoadTest*"
//   or: k6 run k6-load-test.js
// Terminal 2: Profile
//   ./profiler.sh -d 60 -f cpu-before.html $(jps | grep App | awk '{print $1}')

// STEP 2: Open cpu-before.html in browser
// Observation:
//   OrderService.processOrder() - 100%
//   |- JsonSerializer.serialize() - 68%  <- hot
//      |- ObjectMapper.writeValueAsBytes() - 65%
//         |- BeanSerializer._serialize() - 60%  <- reflection! very wide
//   |- Repository.findById() - 20%
//   |- PriceCalculator.calculate() - 12%

// STEP 3: Targeted optimization (top hotspot: reflection serialization)
// BAD (current code):
@RestController
public class OrderController {
    private final ObjectMapper mapper;
    
    @GetMapping("/orders/{id}")
    public ResponseEntity<byte[]> getOrder(@PathVariable Long id) {
        Order order = orderService.findById(id);
        byte[] json = mapper.writeValueAsBytes(order); // reflection!
        return ResponseEntity.ok()
            .contentType(MediaType.APPLICATION_JSON)
            .body(json);
    }
}

// GOOD: switch to record + text/json (Jackson's record support is 
// faster than POJO because fields are final, no setter scanning):
@JsonAutoDetect(fieldVisibility = JsonAutoDetect.Visibility.ANY)
public record OrderResponse(
    Long id, String status, BigDecimal total, String customerId
) {}

// Or: use Protobuf / Avro for binary serialization (faster still):
// .proto file -> generated class -> OrderProto.newBuilder()...build()
//   .toByteArray()  // ~3x faster than JSON for same data

// STEP 4: Re-profile after optimization
// ./profiler.sh -d 60 -f cpu-after.html <pid>
// Observation:
//   OrderService.processOrder() - 100%
//   |- JsonSerializer.serialize() - 18%  <- was 68%!
//   |- Repository.findById() - 52%  <- now the bottleneck
//   |- PriceCalculator.calculate() - 30%
// 
// Serialization improved. Repository is now the bottleneck.
// Next optimization target: add query caching or optimize the query.
```

> **Code walkthrough:** The two flame graph descriptions show the before/after optimization cycle.
> Before: `BeanSerializer._serialize()` (reflection) = 60% of CPU time. After switching to
> record-based serialization: serialization drops to 18%. The repository is now the bottleneck
> (52%). This is the iterative optimization process: fix the top hotspot, re-profile, find the
> new top hotspot, repeat until the system meets its SLA.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Flame graph: x-axis = % CPU time, y-axis = call depth. Wider = more time. Find the widest
> frame near the top = the hotspot. async-profiler: `-d 30 -f flamegraph.html <pid>`. CPU mode:
> compute time. Wall mode: all time including IO wait. Use CPU mode first, wall mode if CPU
> profile looks empty.

---

**Senior / Staff (5+ years):**
> Sampling bias: async-profiler uses AsyncGetCallTrace (no safepoint bias). VisualVM/JProfiler CPU
> sampling: safepoint-biased (misses tight loops). For production profiling: use async-profiler in
> jfr output mode, copy the recording off-server, analyze in JMC. This minimizes production impact
> (< 1% overhead) and doesn't require the profiler to stay running. Allocation flame graphs: the
> first step for GC optimization - find which code path creates the most objects per request.

---

### ⚠️ Common Misconceptions

**Misconception: "A flat flame graph means the code is well-optimized."**
A flat flame graph (all methods at roughly equal widths) can mean: (1) the workload is balanced
across many operations, or (2) the profiler can't resolve frames (missing debug symbols, safepoint
bias hiding the real hotspot). Before concluding "no hotspot": verify the profiler is working
(check for resolved frames, try async-profiler if using VisualVM). Also verify: is the application
actually doing work during the profiling session (are requests being sent)? A flat flame graph
under zero load is meaningless.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Flame graph shows no application code - all time in "vm_thread" or "GC_Thread".**
```
Symptom: CPU flame graph shows > 60% in "[GC_Thread]" or "G1 Young Evacuation."
  Application frames are narrow (< 40% of total).

Root cause: GC is consuming most CPU time.
  CPU profiler captures GC threads too. If GC runs 60% of the time:
  the flame graph reflects that.

Diagnosis:
  Switch to allocation profiling to find root cause:
    ./profiler.sh -d 60 -e alloc -f alloc.html <pid>
  The allocation flame graph shows which application code is
  creating the most objects -> causing the GC pressure.
  
  Also check GC log:
    -Xlog:gc*:file=gc.log:time
  GC overhead calculation:
    grep "GC pause" gc.log | awk '{sum += $NF; count++} END {print sum, count}'
    Compare sum of pause times to total elapsed: overhead %.

Fix:
  Reduce allocation rate (see allocation flame graph hotspot).
  Common culprits:
    - JSON parsing/serialization per request (byte[] + String copies)
    - Stream.toList() in hot paths (creates intermediate objects)
    - Logging with String.format() even when log level is disabled
      (Fix: use parameterized logging: log.debug("val={}", val))
    - Large list copies (new ArrayList<>(existingList))
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| How sampling-based profiling works | 2 minutes |
| Reading a flame graph | 2 minutes |
| CPU vs wall-clock mode | 1 minute |
| Safepoint bias | 1 minute |
| Allocation profiling | 1 minute |
| Production profiling safety | 1 minute |
| When flame graph shows mostly GC | 1 minute |

---

**Q1 (sampling): How does a sampling profiler work and what are its limitations?**

A: At regular intervals (e.g., every 1ms), the profiler sends a signal to the target JVM. The JVM
(or OS via async-profiler) captures the current call stack of the running thread. After N seconds:
thousands of stack snapshots. The profiler aggregates: if `ObjectMapper.serialize()` appears in
40% of snapshots, it consumed ~40% of CPU time. Limitations: (1) minimum resolution = sampling
interval (1ms, so methods taking < 1ms may be underrepresented). (2) Safepoint bias (standard
profilers). (3) High sampling frequency: higher overhead.

*What separates good from great:* The statistical confidence calculation: 100 samples/sec for 60 seconds
= 6,000 samples. A method appearing in 300 of 6,000 samples = 5% CPU time. Margin of error at 95%
confidence: ~0.5%. This is precise enough for most optimization decisions. But: if you need to compare
two similar methods (method A = 5.1% vs method B = 4.9%): 6,000 samples may not be statistically
significant. JMH with thousands of iterations: gives statistical significance for micro-benchmark
comparisons. The right tool for the right question.

---

**Q2 (reading): Walk me through how you read a flame graph from a Java application.**

A: Step 1: open the HTML flame graph in a browser. Step 2: look at the bottom frame - this is
the thread entry point (main, Thread.run). Step 3: scan upward, following the widest frames.
Width = proportion of CPU time. Step 4: find the "plateau" - the widest frame near the top that
has few or no wide children. This is the hot method. Step 5: hover over frames for the full class
+ method name and exact percentage. Step 6: identify the call path from the plateau to the root -
this is the hot code path.

*What separates good from great:* The "Java vs native" frame reading: if the top frames are in
red (native C code) or in Java frames like `Unsafe.compareAndSwapInt` or `sun.misc.Unsafe`:
the bottleneck may be in JVM internals (GC, JIT, JNI call). These are harder to optimize directly
at the application level. Solutions: reduce GC (allocation profiling), reduce JNI calls (batch
native calls), use more efficient JVM operations. The "inlined frame" reading: if frames appear
with "(inlined)" annotation in async-profiler: those methods were inlined by C2 but still
appear as separate frames with their own CPU contribution. This is the correct view - each
logical method still has a measured cost even when inlined.

---

**Q3 (wall): When would you use wall-clock mode instead of CPU mode?**

A: CPU mode: shows only time the thread is running on CPU. Useful for compute bottlenecks.
Wall-clock mode: shows all thread time including: waiting for IO (file, network, DB), blocked
on locks, sleeping, waiting for condition variables. Use wall-clock when: CPU profile looks
good but p99 latency is still high. The latency is being spent waiting, not computing. Wall-clock
shows WHERE the thread is blocked - which IO call, which lock.

*What separates good from great:* The wall-clock mode's "common suspect" patterns: (1) JDBC thread
blocked in `Socket.read()` - DB query is slow. Flame graph shows: `OrderRepository.findById() -> JDBC4Connection.prepareStatement() -> ... -> SocketInputStream.read()`. Time in `SocketInputStream.read()` = DB response time. Fix: optimize the query, add index. (2) Lock contention: thread blocked in `Object.wait()` or `AbstractQueuedSynchronizer.parkAndCheckInterrupt()`. Wide wall-clock frame = high contention. Fix: reduce lock scope, use lock-free structures. (3) HTTP client timeout: `HttpURLConnection.getInputStream()` waiting for external service. Fix: async calls, circuit breaker.

---

---

## Heap Profiling: Memory Leak Detection

### 🎯 Model Answer

**30 seconds:**
> Heap profiling: finding which code creates the most objects, and which objects are kept alive
> (memory leaks). Tools: async-profiler allocation mode (who allocates), jmap + MAT (what's
> alive). Memory leak = objects that are reachable (referenced) but no longer needed. GC can't
> collect them. Heap grows until OOM.

**3 minutes (Senior):**
> Two types of heap analysis:
>
> 1. **Allocation profiling** (who is allocating): async-profiler `-e alloc`. Flame graph shows
>    which call paths create the most objects. Used for: reducing allocation rate (fewer GC cycles).
>    Target: methods with high allocation rate in the hot path. Fix: object pooling, avoid temporary
>    objects, use primitives instead of boxed types.
>
> 2. **Heap dump analysis** (what is alive): `jmap -dump:live,format=b,file=heap.hprof <pid>`.
>    Open in MAT (Eclipse Memory Analyzer). Dominator tree: which objects retain the most heap.
>    Leak suspect report: identifies potential leaks. Used for: diagnosing memory leaks (objects
>    accumulating in old gen causing Full GC or OOM).
>
> 3. **Common leak patterns**: (1) static collections growing without bound, (2) ThreadLocal
>    not removed (ThreadLocal held by thread pool threads = permanent), (3) listeners/callbacks
>    registered but not deregistered, (4) ClassLoader leaks (in redeploy scenarios), (5) caches
>    without eviction policy.

**Blank Mind Recovery:**

**(1) Restate:** "Allocation profiling: who creates objects (async-profiler alloc). Heap dump: what's alive (jmap + MAT). Memory leak: reachable but no longer needed. Common leaks: static collections, ThreadLocal, listeners not removed, caches without eviction."

**(2) First principles:** "A memory leak = an object that is reachable (GC won't collect it) but the application no longer uses it. The fix: break the reference. Find it: heap dump -> dominator tree (who's holding the memory)."

**(3) Bridge:** "Memory leak investigation is detective work. The heap dump is the crime scene. The dominator tree is the evidence chain. The object holding the most memory is the suspect. The GC root that keeps it alive is the root cause."

---

### 📘 Concept Explanation

**Memory leak investigation methodology:**
```
MEMORY LEAK INDICATORS:

  Symptom 1: Heap used grows over time (even between GC cycles)
    jstat -gcutil <pid> 5000  # print GC stats every 5 seconds
    Column OU (Old Utilization %): growing continuously? Leak.
  
  Symptom 2: Increasing Full GC frequency
    GC logs: Full GC every 30 minutes -> every 10 minutes -> every 5 min
    Old gen fills faster over time -> GC collecting less garbage per cycle
    -> Objects are accumulating (not being freed)
  
  Symptom 3: OOM (OutOfMemoryError: Java heap space)
    The end state of an unchecked memory leak.
    Heap dump taken at OOM: -XX:+HeapDumpOnOutOfMemoryError
    -XX:HeapDumpPath=/var/dumps/

HEAP DUMP ANALYSIS WITH MAT:

  Step 1: Generate heap dump
    jmap -dump:live,format=b,file=heap.hprof <pid>
    # 'live' = GC first, then dump (only live objects, no garbage)
    # Creates a file: typically 1/2 to 1/3 of heap size
    # Warning: jmap causes a full GC pause + dump time (seconds to minutes)
  
  Step 2: Open in Eclipse MAT
    File -> Open Heap Dump -> heap.hprof
  
  Step 3: Dominator tree
    Window -> Heap Dump Details -> Dominator Tree
    Sort by "Retained Heap" column
    Top entry: the object that retains the most memory
    If it's an ArrayList: expand -> see what's in it -> find the GC root
  
  Step 4: Path to GC Root
    Right-click the large object -> "Path to GC Roots" -> "Exclude weak references"
    This shows: WHICH REFERENCE is keeping this object alive
    The reference at the top of the path = the leak source

COMMON JAVA MEMORY LEAKS:

  1. STATIC COLLECTION:
     static Map<Long, User> userCache = new HashMap<>();
     cache.put(userId, user);  // added, never removed
     -> grows without bound, never GC'd
     Fix: use Caffeine/Guava cache with eviction (size, time)
  
  2. THREADLOCAL LEAK:
     static ThreadLocal<Context> ctx = new ThreadLocal<>();
     ctx.set(new Context());
     // ... request done, but ctx.remove() NOT CALLED
     // Thread pool thread keeps ctx alive forever
     // After 1000 requests: 1000 Context objects in memory
     Fix: always call ctx.remove() in finally block
  
  3. LISTENER NOT DEREGISTERED:
     eventBus.register(this);  // adds reference to 'this' in eventBus
     // object goes out of scope but eventBus holds reference
     // object never GC'd until eventBus deregisters it
     Fix: eventBus.unregister(this) in close/destroy/cleanup
  
  4. CACHE WITHOUT EVICTION:
     Map<Key, Value> cache = new HashMap<>();
     // items added, never expired or removed
     Fix: Caffeine.newBuilder().maximumSize(10000).expireAfterAccess(1h)

ALLOCATION PROFILING (reduce allocation rate):

  async-profiler alloc mode:
  ./profiler.sh -d 60 -e alloc -f alloc.html <pid>
  
  Flame graph shows: which call stacks triggered the most object allocation
  Wide frame near top = code allocating the most objects
  
  Typical Java high-allocation sources:
  - String.format() in hot loops (creates new String each call)
  - JSON parsing (Jackson): many intermediate objects
  - Stream pipelines: collectors create temporary lists
  - Autoboxing: int -> Integer in Map.put(int, int) calls
    Fix: use IntToObjectMap (Eclipse Collections, Koloboke)
  - toString() logging: computed even if log level is disabled
    Fix: if (log.isDebugEnabled()) { log.debug(toString()); }
    Or: log.debug("val={}", val);  // lazy, no toString unless DEBUG
```

---

### 💻 Code Example

> **Code walkthrough:** The leak patterns show the three most common memory leaks in
> production Java. Each follows the same structure: a reference keeps the object alive
> past its useful lifetime. The ThreadLocal example is particularly dangerous because
> thread pool threads live forever, so an unreleased ThreadLocal never gets collected.

```java
// COMMON MEMORY LEAKS AND FIXES:

// LEAK 1: Static cache without eviction (VERY COMMON):
// BAD:
public class UserService {
    private static final Map<Long, UserProfile> CACHE = new HashMap<>();
    
    public UserProfile getProfile(Long userId) {
        return CACHE.computeIfAbsent(userId, this::loadFromDb);
        // Once added to CACHE: never removed.
        // After serving 100,000 users: 100,000 profiles in memory. LEAK.
    }
}

// GOOD: Caffeine cache with eviction:
public class UserService {
    private final Cache<Long, UserProfile> cache = Caffeine.newBuilder()
        .maximumSize(10_000)           // LRU eviction after 10k entries
        .expireAfterAccess(30, MINUTES)  // expire idle entries
        .build();
    
    public UserProfile getProfile(Long userId) {
        return cache.get(userId, this::loadFromDb);
    }
}

// LEAK 2: ThreadLocal not removed (VERY COMMON in servlet containers):
// BAD:
private static final ThreadLocal<RequestContext> CONTEXT = new ThreadLocal<>();

@Component
public class RequestFilter implements Filter {
    
    @Override
    public void doFilter(ServletRequest req, ServletResponse res,
                         FilterChain chain) throws IOException, ServletException {
        CONTEXT.set(new RequestContext((HttpServletRequest) req));
        chain.doFilter(req, res);
        // Missing: CONTEXT.remove()!
        // Thread pool thread retains RequestContext after request ends.
    }
}

// GOOD: always remove in finally:
@Override
public void doFilter(ServletRequest req, ServletResponse res,
                     FilterChain chain) throws IOException, ServletException {
    CONTEXT.set(new RequestContext((HttpServletRequest) req));
    try {
        chain.doFilter(req, res);
    } finally {
        CONTEXT.remove();  // MANDATORY: release before thread returns to pool
    }
}

// LEAK DETECTION IN MAT:
// After taking a heap dump of the BAD code above:
// MAT Dominator Tree:
//   Thread[http-nio-8080-exec-1] - 45MB retained
//   |_ ThreadLocalMap$Entry[0] - 44MB retained
//      |_ RequestContext@0x12345 - 44MB retained (10k contexts!)
//         |_ list of previous requests' data...
// Path to GC Root: ThreadLocalMap in the thread object (GC root = active thread)
```

> **Code walkthrough:** The static cache leak shows the most common production pattern: add to cache,
> never remove. After N distinct users: N entries in memory. The Caffeine fix adds both size-based
> LRU eviction (bounded memory) and time-based expiry (stale entries removed). The ThreadLocal leak
> shows that in thread pool environments, threads are reused - so a ThreadLocal set in one request
> and not removed is retained for the lifetime of the thread. The `finally` block is mandatory.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Memory leak = reachable but unneeded. Indicators: heap growing over time, increasing GC frequency.
> Common causes: static collections, ThreadLocal not removed, listeners not deregistered. Tools:
> jmap + MAT for heap dump analysis. `-XX:+HeapDumpOnOutOfMemoryError` flag: always set in production.

---

**Senior / Staff (5+ years):**
> Soft references (SoftReference): GC'd when heap is low. Useful for memory-sensitive caches.
> But: a SoftReference cache that fills the entire old gen before being collected causes GC pressure
> even if it eventually gets collected. Caffeine with `softValues()`: may behave poorly under load.
> Prefer explicit size-bounded caches. For diagnostic tooling: `-XX:NativeMemoryTracking=detail`
> tracks all JVM memory areas. HeapDumpOnOutOfMemoryError + path to writable location: essential
> for post-mortem debugging of OOM in production.

---

### ⚠️ Common Misconceptions

**Misconception: "Setting a maximum heap size (-Xmx) prevents memory leaks."**
`-Xmx` limits the heap size. A memory leak with `-Xmx8g`: the leak accumulates in old gen until
8GB is used, then OOM. `-Xmx` doesn't prevent the leak - it sets the failure point. The correct
action: detect the leak early (monitoring old gen growth), diagnose (heap dump), fix (break the
reference). `-Xmx` is not a memory leak fix; it's a time delay.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Heap dump is too large to analyze on a dev laptop.**
```
Symptom: Service has -Xmx32g. OOM occurred. Heap dump: 25GB.
  Developer machine: 16GB RAM. Can't open in MAT.

Options:
  1. Use MAT server-side (headless):
     java -jar mat.app/Contents/MacOS/../Eclipse -consolelog \
       -nosplash -application org.eclipse.mat.api.parse \
       /path/to/heap.hprof \
       org.eclipse.mat.api:suspects

  2. Use JVM heap histogram (no full dump needed):
     jmap -histo:live <pid>  # doesn't require full dump, just a live histogram
     Shows: which classes have the most instances and retained bytes.
     Not as detailed as MAT but works without a large dump.
  
  3. Partial dump with JCMD filter:
     Not directly supported, but: compare two histograms over time
     (before/after leak accumulation) to find which class grew.
     jmap -histo <pid> > histo_before.txt
     # wait 5 minutes
     jmap -histo <pid> > histo_after.txt
     diff histo_before.txt histo_after.txt  # find growing classes
  
  4. Use GraalVM VisualVM with low memory mode for large dumps.
  
  5. Production prevention: if OOM is expected, configure smaller heap
     per pod and run more pods. Smaller heaps = smaller dump files.
     8 pods * 4GB each > 1 pod * 32GB (easier to diagnose per pod).
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Memory leak definition | 1 minute |
| How to detect a memory leak | 2 minutes |
| Heap dump analysis workflow | 2 minutes |
| ThreadLocal leak pattern | 2 minutes |
| Allocation profiling vs heap dump | 1 minute |
| Production heap dump considerations | 1 minute |
| Soft vs weak references for caches | 1 minute |

---

**Q1 (detect): How do you detect a memory leak before OOM?**

A: Monitoring indicators: (1) old gen utilization grows between major GC cycles (not recovering
to baseline after GC). Monitor: `jstat -gcutil <pid> 30000` - watch OU (old utilization) column
over time. (2) Increasing major GC frequency. (3) Heap used at steady state grows over time in APM
dashboard. Alert: if old gen utilization increases by > 5% per hour under constant load: investigate.
This gives days of warning before OOM.

*What separates good from great:* The "sawtooth vs slope" pattern in heap monitoring: normal heap
under load: sawtooth (rises as allocation fills heap, drops sharply when GC collects, repeating).
A memory leak: the floor of the sawtooth rises over time (each GC collects less, floor is higher).
Eventually the floor is so high that GC can't free enough -> OOM. Early detection: the rising floor
is visible in the heap graph long before OOM. Setting a Grafana alert on "minimum heap after GC
over the last hour is N% higher than the previous hour" is a leak early warning. Building this
alert requires tracking heap-after-GC (available from JFR GC events or GC log parsing).

---

**Q2 (threadlocal): What happens if you don't remove a ThreadLocal value in a thread pool?**

A: Thread pool threads are reused. If a request sets `threadLocal.set(value)` and the thread returns
to the pool without calling `threadLocal.remove()`: the value remains in the thread's `ThreadLocalMap`
for the lifetime of the thread (potentially the application lifetime). The value is a GC root (reachable
via the active thread). If the request sets a large object: that object is retained forever per thread.
With 200 thread pool threads: 200 permanently retained objects.

*What separates good from great:* The cascading effect: if the value contains references to other
objects (a `RequestContext` with a reference to the `HttpServletRequest`, which has headers, body,
etc.): the entire request object graph is retained. With 200 threads doing 10 requests per second:
200 thread pool threads, each with one leaked context. Memory: 200 * (size of RequestContext + all
referenced objects). If each request context is 10KB: 2MB. Sounds small. But if the context contains
the request body (e.g., a file upload): 200 * 10MB = 2GB leak in the thread pool after moderate
traffic. The `finally { threadLocal.remove(); }` pattern prevents this entirely. Spring's
`RequestContextHolder` manages this automatically; custom ThreadLocals require manual cleanup.

---

**Q3 (dump): What are the risks of running jmap to generate a heap dump in production?**

A: (1) Stop-the-world: `jmap -dump:live,format=b,file=heap.hprof <pid>` triggers a full GC +
pauses the JVM while dumping. For a 4GB heap: pause can be 10-60 seconds. All requests blocked
during dump. (2) Disk I/O: heap dump file = 50-100% of heap size. For 16GB heap: 8-16GB file.
Must have disk space and fast I/O. (3) Memory: writing the dump adds temporary memory overhead.
(4) Impact: production service is effectively down during dump.

*What separates good from great:* Safer alternatives: (1) JFR continuous recording (< 2% overhead,
no pause): provides allocation and memory insights without stopping the JVM. Analyze the JFR recording
off-heap. (2) jmap -histo:live: much faster than full dump, only shows the histogram (class + count +
size). Enough to identify which class is leaking without the full dump pause. (3) `-XX:+HeapDumpOnOutOfMemoryError`: the JVM dumps automatically when OOM occurs (already paused from OOM). The safest
approach: trigger the dump from the OOM, not manually from a running healthy instance. (4) Take the
dump during a maintenance window or on a canary instance that's been removed from the load balancer.

---
