# Native Image Performance Profiling

**Interview Weight:** hard - Performance profiling in native
image requires different tools than JVM. Tested for production expertise.

---

### 🎯 Model Answer

**30 seconds:**

> Native image profiling: JVM tools (VisualVM, JProfiler,
> async-profiler via JVMTI) don't work with native binaries.
> Available tools: async-profiler native agent (attaches
> to native process, generates flamegraphs), perf (Linux
> CPU profiling), and -XX:+PrintGC (GC metrics).
> Quarkus: Micrometer metrics endpoint (/q/metrics) provides
> application-level metrics. For deep analysis: build with
> debug symbols and use perf or async-profiler.

**3 minutes (Senior):**

> Native image profiling options:
>
> 1. Async Profiler (recommended):
>    Native agent: attaches to native process.
>    Generates: flamegraph of CPU usage.
>    Works: Linux, macOS.
>    Installation: github.com/async-profiler/async-profiler.
>
> 2. Linux perf:
>    OS-level: samples CPU at regular intervals.
>    Shows: which native functions are hot.
>    Limitation: symbol resolution needs debug symbols.
>
> 3. GraalVM performance profiler (Oracle GraalVM):
>    --language:profiler extension (only Truffle).
>    Not for application code.
>
> 4. Application metrics (Micrometer):
>    /q/metrics endpoint (Prometheus).
>    Counters, timers, gauges.
>    Works in native (Quarkus extension).
>    Best for: request latency, throughput, error rate.
>
> 5. Heap profiling:
>    -XX:+HeapDumpOnOutOfMemoryError.
>    Heap dump analyzable with Eclipse MAT (limited).
>    GC verbose: -XX:+PrintGC -XX:+PrintGCDetails.
>
> Debug symbols:
>   Native image: no debug symbols by default.
>   Add: -g (compile with debug info).
>   Size: binary 2-3x larger with debug symbols.
>   Use: profiling/debugging builds only.
>
> Build with debug:
>   quarkus.native.debug.enabled=true (Quarkus).
>   Then: async-profiler shows Java symbol names.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to profile
a GraalVM native image in production."

**(2) First principles:** "JVM tools won't work. Use OS-level
tools and native-specific agents."

**(3) Bridge:** "Native image profiling is like C application
profiling: perf, flamegraphs, debug symbols."

---

### 💻 Code Example

```bash
# PROFILING WORKFLOW

# Method 1: Async Profiler (best option)
# Download and install
wget https://github.com/async-profiler/async-profiler/\
  releases/latest/download/async-profiler-linux-x64.zip
unzip async-profiler-linux-x64.zip

# Start native app with profiling
LD_PRELOAD=./libasyncProfiler.so \
  ASYNCPROF_OPTIONS="start,event=cpu,file=/tmp/profile.html" \
  ./target/app-runner

# Generate under load (k6, JMeter, etc.)
k6 run --vus 100 --duration 60s load-test.js

# Stop profiling and generate flamegraph
kill -USR2 $APP_PID  # Stop recording
# Output: /tmp/profile.html (flamegraph)

# Method 2: Linux perf
# Build with debug symbols
./mvnw package -Pnative \
  -Dquarkus.native.debug.enabled=true
# Produces: app-runner with debug symbols

perf record -F 99 -g -p $(pgrep app-runner) \
  sleep 30
perf report

# Method 3: GC monitoring
./target/app-runner \
  -XX:+PrintGC \
  -XX:+PrintGCTimeStamps
# Output:
# [0.524 GC (Allocation Failure) 35.3MB→22.1MB(64.0MB)
#   1.2ms]
# Parse: time, reason, before→after(max), pause

# Method 4: Micrometer metrics
# application.properties:
# quarkus.micrometer.export.prometheus.enabled=true

# Query metrics endpoint
curl http://localhost:8080/q/metrics | \
  grep "http_server_requests"
# http_server_requests_seconds_count{
#   method="GET",outcome="SUCCESS",
#   status="200",uri="/orders"} 1234.0
# http_server_requests_seconds_sum{...} 56.789

# Analyze: avg latency
# = sum / count = 56.789 / 1234 = 0.046s (46ms)

# P95 latency (requires histogram)
# application.properties:
# quarkus.micrometer.binder.http-server.\
#   histogram.enabled=true
# Then: http_server_requests_seconds_bucket{le="0.1"}
```

> **Code walkthrough:** The async-profiler LD_PRELOAD
> approach is the cleanest for native image: no code
> changes, generates a flamegraph showing where CPU time
> is spent. Linux perf requires debug symbols for Java
> symbol names; without them, you see native function
> addresses. Micrometer metrics work at application level
> and are the primary production monitoring tool.

---

### 🎓 Answers by Seniority

**Senior:** "JVM profilers don't work on native. Use async-profiler
(native agent), perf (OS-level), and Micrometer for application
metrics. Build with debug symbols for human-readable flamegraphs."

**Staff:** "Production profiling of native: Micrometer gives
the what (slow endpoints), async-profiler gives the why
(which code is hot). Never run production with debug symbols
(2-3x binary size). Use a staging environment with debug
build for flamegraph analysis."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | Profiling tools, async-profiler, Micrometer |
| Staff | 10 min | Full workflow, debug symbols, production vs staging |

---

**[STAFF] Q1 - How do you identify a memory
leak in a GraalVM native image service?**

*Why they ask:* Production diagnosis skill.

Memory leak in native: RSS grows without bound over time.
Different from JVM: metaspace leak unlikely, no JIT code cache leak.
Most likely: heap allocation leak.

Diagnosis:
```bash
# Step 1: Observe RSS over time
watch -n30 "cat /proc/$(pgrep app-runner)/smaps_rollup \
  | grep Rss"
# Rss: 78432 kB  (T=0)
# Rss: 84120 kB  (T=30s)  ← growing

# Step 2: Trigger GC and observe
./target/app-runner \
  -XX:+PrintGC
# After GC: if RSS drops → heap leak (expected behavior)
# After GC: if RSS doesn't drop → native memory leak

# Step 3: Heap dump on OOM
./target/app-runner \
  -Xmx128m \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/tmp/heap.hprof

# Analyze heap dump
# Eclipse MAT (limited native support):
java -jar mat.exe /tmp/heap.hprof
# Find: top objects by size, unreachable objects

# Step 4: Native memory tracking
# valgrind (slow, thorough)
valgrind --tool=massif \
  --pages-as-heap=yes \
  ./target/app-runner
ms_print massif.out.* > massif-analysis.txt
# Shows: what native memory is allocated over time
```

Leak categories in native:
1. Heap leak: objects held by static caches.
   Symptom: heap grows before GC, RSS grows after GC.
   Fix: cap cache sizes, use weak references.

2. Native memory leak: off-heap allocations not freed.
   Symptom: RSS grows, heap stable.
   Usually: third-party native library.
   Fix: identify library, update or replace.

3. Thread leak: threads created but not terminated.
   Symptom: /proc/PID/status Threads: grows.
   Fix: use thread pools, not unbounded thread creation.

*What separates good from great:* Distinguish heap vs
native memory leak by correlating RSS with GC events.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Profiling tools, GC verbose. |
| Hiring Manager | Production debugging capability. |
| Bar Raiser | Full leak diagnosis workflow, tool chain. |
| Staff | "Native memory diagnosis: correlate RSS with GC. If RSS drops after GC: heap. If RSS stays high: native memory." |

---

---

# GraalVM Anti-Patterns and Closed-World Violations

**Interview Weight:** hard - Anti-patterns are Staff
differentiator. Tests applied experience.

---

### 🎯 Model Answer

**30 seconds:**

> The primary GraalVM anti-patterns: using the JVM as-is
> and expecting native image to work (reflection everywhere,
> CGLIB proxies, dynamic plugins); neglecting to test in
> native mode until deployment; using native image for
> throughput-critical services where JIT outperforms AOT;
> and treating native build failures as emergencies rather
> than planning for them with a systematic reflection
> configuration strategy.

**3 minutes (Senior):**

> Anti-patterns and consequences:
>
> 1. Not testing in native mode until late:
>    Anti-pattern: develop in JVM mode, test native at release.
>    Consequence: dozens of reflection errors found at release.
>    Fix: native CI gate on every PR.
>
> 2. Over-using @RegisterForReflection:
>    Anti-pattern: blanket-register entire packages.
>    Consequence: binary size bloat, longer build.
>    Fix: register only what's needed.
>    Pattern: generate registration from test coverage.
>
> 3. Dynamic plugin loading in native:
>    Anti-pattern: build a plugin system with native image.
>    Consequence: plugins can't be loaded at runtime.
>    Fix: use ServiceLoader for build-time plugin discovery.
>    Or: use JVM mode for plugin-heavy services.
>
> 4. Native image for throughput-critical batch:
>    Anti-pattern: use native for long-running batch job.
>    Consequence: 10-20% lower throughput than JVM JIT.
>    Fix: JVM mode for sustained high-throughput.
>    Native advantage: startup. Not applicable to batch.
>
> 5. Ignoring build time in CI:
>    Anti-pattern: every commit triggers native build.
>    Consequence: 10-minute CI per commit = slow delivery.
>    Fix: native build on main branch or daily, not every PR.
>
> 6. Not planning for image heap size:
>    Anti-pattern: add more Quarkus extensions without
>    measuring binary size.
>    Consequence: 200MB+ binary, slow pod startup.
>    Fix: measure binary size per added dependency.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about common mistakes
when using GraalVM native image."

**(2) First principles:** "Every anti-pattern violates a
core principle: test early, profile before optimizing,
design for constraints."

**(3) Bridge:** "GraalVM anti-patterns mirror general
engineering anti-patterns: deferred testing, premature
optimization, ignoring constraints."

---

### 💻 Code Example

```java
// ANTI-PATTERN 1: Mass reflection registration
// BAD: register everything, deal with it later
@RegisterForReflection(
    targets = {
        OrderDto.class,
        PaymentDto.class,
        UserDto.class,
        AddressDto.class,
        CartDto.class,
        ProductDto.class,
        InventoryDto.class,
        ShipmentDto.class,
        InvoiceDto.class,
        ReviewDto.class
        // 50 more classes...
    }
)
// Binary size: +2-5MB per 50 registered classes
// Build time: +30s per 100 extra registrations

// GOOD: Jackson annotation-based (processed by extension)
// Jackson extension automatically registers
// classes with @JsonSerialize/@JsonDeserialize
// Only register explicitly: non-annotated DTOs

// ANTI-PATTERN 2: Native for batch jobs
// BAD: use native image for ETL batch processing
// application.properties (batch service):
// quarkus.native.enabled=true

// Consequences:
// - Startup saved: 2s (irrelevant for 8hr batch)
// - Throughput: 15% lower than JVM (matters for 8hr)
// - ROI: negative

// GOOD: JVM mode for batch
// quarkus.native.enabled=false (JVM profile)
// Quarkus JVM: JIT-compiled, full throughput

// ANTI-PATTERN 3: Forgetting native CI
// BAD: no native tests in CI
// (no CI configuration for native)
// First native failure: production deployment day

// GOOD: native CI gate
// .github/workflows/native-test.yml:
// on:
//   pull_request:
//     paths:
//       - 'src/main/**'
//       - 'pom.xml'
// jobs:
//   native-test:
//     runs-on: ubuntu-latest
//     steps:
//       - uses: actions/checkout@v4
//       - name: Build native
//         run: ./mvnw package -Pnative
//           -Dquarkus.native.container-build=true
//       - name: Test native
//         run: ./mvnw verify -Pnative

// ANTI-PATTERN 4: Static configuration
// BAD: hardcoded config that changes per environment
@ApplicationScoped
public class ServiceConfig {
    // Hardcoded in native binary:
    // Cannot change without rebuild
    private static final int TIMEOUT_MS = 5000;
    private static final String API_URL =
        "https://api.prod.company.com";
}

// GOOD: externalized config
@ApplicationScoped
public class ServiceConfig {
    @ConfigProperty(name = "api.timeout-ms",
        defaultValue = "5000")
    int timeoutMs;

    @ConfigProperty(name = "api.url")
    String apiUrl;
    // Set via env vars or ConfigMaps
    // Same binary for all environments
}
```

> **Code walkthrough:** The mass registration anti-pattern
> shows how blanket @RegisterForReflection increases binary
> size and build time unnecessarily. The batch job anti-pattern
> illustrates the key decision axis: native image provides
> startup time benefit. If startup doesn't matter (long-running
> batch), JVM mode with JIT is better. The CI gate pattern
> is the most important: native failures discovered in PR
> review, not at 2am production deployment.

---

### 🎓 Answers by Seniority

**Senior:** "Top anti-patterns: deferred native testing (fix:
native CI gate), over-registration (fix: targeted reflection),
native for batch (fix: JVM mode). Each anti-pattern has a
specific cost and fix."

**Staff:** "The meta anti-pattern: treating native image as
'just JVM but smaller.' It requires explicit design choices:
interfaces not classes, CDI lifecycle not static init, externalized
config not hardcoded. Services designed for native are better
services overall."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Anti-patterns, consequences, fixes |
| Staff | 10 min | Meta anti-pattern, design philosophy, CI strategy |

---

**[STAFF] Q1 - How do you build a "native-first"
culture in a Java team?**

*Why they ask:* Engineering culture and adoption.

Steps to build native-first:

1. Education: native image constraints as code quality rules.
   "No reflection without registration" = explicit code.
   "No static init side effects" = better lifecycle.
   Reframe constraints as quality improvements.

2. Tooling: make native testing easy.
   - Add native test profile to project template.
   - CI gate: one click to see native failure.
   - Native build cached: <5 min for most services.

3. Incremental adoption:
   - New services: start native-first.
   - Existing services: native-last (migrate when stable).
   - Never: force native migration under deadline.

4. Celebrate wins:
   - Share: "We reduced memory 60% with native."
   - Show: cost savings from reduced pod count.
   - Track: startup time improvement post-migration.

5. Explicit anti-patterns list:
   - Document: "Class.forName is forbidden without config."
   - Review checklist: "Does this PR have a native CI test?"

*What separates good from great:* Native-first culture
requires reframing constraints as quality improvements,
not obstacles.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Anti-patterns, consequences, fixes. |
| Hiring Manager | How to adopt native image at scale. |
| Bar Raiser | Culture building, incremental adoption. |
| Staff | "Native constraints improve design. Teams that see them as obstacles never succeed. Teams that see them as quality rules ship better software." |
