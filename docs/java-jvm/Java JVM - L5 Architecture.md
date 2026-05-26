---
layout: default
title: "Java JVM - L5 Architecture"
parent: "Java JVM"
nav_order: 7
permalink: /java-jvm/l5-architecture/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [GraalVM and AOT Compilation](#graalvm-and-aot-compilation) | high |
| 2 | [JVM Tuning Strategy](#jvm-tuning-strategy) | high |
| 3 | [JVM Security Architecture](#jvm-security-architecture) | medium |

---

# GraalVM and AOT Compilation

**Interview Weight:** high - Architect-level. Tests knowledge
of the JVM evolution, GraalVM native image trade-offs, and AOT
vs JIT decisions for cloud-native workloads.

---

### 🎯 Model Answer

**30 seconds:**

> GraalVM is a polyglot JVM that includes: a new JIT compiler
> (Graal JIT, replacing C2 for some workloads), Native Image
> (AOT compilation to a standalone native executable), and a
> polyglot runtime (run JS, Python, Ruby on the JVM). Native
> Image uses closed-world assumption: all code must be analyzable
> at build time. Trade-off: microsecond startup, low memory vs
> no dynamic class loading, slow build, partial reflection support.

**3 minutes (Senior):**

> **GraalVM JIT vs HotSpot C2:**
> - Graal JIT is written in Java (C2 is in C++). Easier to
>   contribute to, more aggressive speculative optimizations.
> - Used by Truffle-based language runtimes (JS, Python on GraalVM).
> - For standard Java: marginal improvement in throughput (~5-10%)
>   but higher compilation overhead. Not universally better.
>
> **GraalVM Native Image (AOT):**
> - Build: `native-image -jar app.jar` → standalone binary.
> - Build time: analyzes all reachable classes statically.
>   Reflection, JNI, proxies, serialization: must be declared
>   in configuration files. Spring Boot 3 generates these automatically.
> - **Advantages**:
>   - Startup in milliseconds (vs seconds for JVM startup + JIT warmup)
>   - Memory footprint: 50-80% smaller RSS than equivalent JVM app
>   - No JIT: consistent latency from first request
> - **Disadvantages**:
>   - Closed-world assumption: dynamic class loading not supported
>   - No JIT warmup = peak throughput lower than long-running JVM
>   - Build takes minutes (full program analysis + compilation)
>   - Reflection must be configured (agent or manual config)
>
> **When to use Native Image:**
> - Serverless functions (cold start is critical)
> - CLI tools (startup time matters)
> - Microservices with predictable request patterns
>
> **When NOT to use:**
> - Long-running servers with variable workloads (JIT beats AOT)
> - Applications with heavy dynamic proxies / reflection (complex config)
> - When you need JVM diagnostic tools (JFR limited in native image)
>
> **Framework support (2024):**
> - Spring Boot 3 Native: first-class, uses build-time analysis
> - Quarkus: AOT-first design, best native image support
> - Micronaut: compile-time DI, smooth native build

---

### 💻 Code Example

**Example 1: Native Image reflection configuration**

```java
// BAD: Reflection without configuration (fails in native image)
Class<?> clazz = Class.forName("com.example.UserService");
Object instance = clazz.getDeclaredConstructor().newInstance();
// Native Image error: "Class not included in the image"
// Because: static analysis could not determine this class
// is reachable via normal control flow

// GOOD: Use reflect-config.json to declare reflective access
// resources/META-INF/native-image/reflect-config.json:
// [
//   {
//     "name": "com.example.UserService",
//     "allDeclaredConstructors": true,
//     "allPublicMethods": true
//   }
// ]

// GOOD: Or use GraalVM tracing agent to auto-generate config
// java -agentlib:native-image-agent=config-output-dir=./config -jar app.jar
// → runs app, records all reflection/JNI/proxy calls
// → generates reflect-config.json, jni-config.json, proxy-config.json

// GOOD: Or use @RegisterReflectionForBinding (Spring Boot 3)
@RegisterReflectionForBinding(UserService.class)
@Configuration
class AppConfig { ... }
// Spring Native processes this at build time
```

```bash
# Build native image (Quarkus example)
mvn package -Pnative
# or
./gradlew nativeBuild

# Build output:
# [1/7] Initializing...
# [7/7] Creating image... (may take 3-10 minutes)
# app-runner (native binary, ~50MB)

# Run: instant startup
time ./app-runner
# Started in 0.042s (vs 3-5s for JVM startup)

# Memory: compare RSS
ps aux | grep app  # native: ~80MB; JVM equivalent: ~300MB
```

> **Code walkthrough:** The `native-image-agent` is the key tool:
> run it with your application and a realistic workload, and it
> records all reflective access, generating the config files
> automatically. Spring Boot 3 integrates this into the build.
> The startup and memory trade-off is significant: 0.042s vs 5s
> startup, 80MB vs 300MB RSS - ideal for Functions-as-a-Service.

---

### ⚖️ Comparison

| Dimension | JVM (JIT) | GraalVM Native Image |
|---|---|---|
| Startup time | 1-10 seconds | 5-100ms |
| Memory (RSS) | 200-500MB | 50-150MB |
| Peak throughput | Excellent (JIT optimized) | Lower (no JIT warmup) |
| Latency consistency | Variable (GC pauses, JIT) | More consistent |
| Dynamic class loading | Yes | No (build-time closed world) |
| Reflection | Unrestricted | Requires configuration |
| Build time | Seconds | Minutes |
| Diagnostic tools | Full JFR, jstack, jmap | Limited (no full JFR) |
| Best use case | Long-running servers | Serverless, CLI, short-lived |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> GraalVM includes a Java JIT (Graal) and Native Image (AOT
> compilation to native binary). Native Image: fast startup, low
> memory, no dynamic class loading. Use for serverless. Regular
> JVM: better peak throughput, more flexible.

---

**Senior / Staff (5+ years):**

> I choose GraalVM Native Image for workloads where cold start
> matters (Lambda, GKE scale-to-zero). For long-running services,
> the JIT's adaptive optimization still outperforms AOT at peak
> throughput. The reflection configuration burden is now largely
> automated with Spring Boot 3 and Quarkus's build-time processing.

---

### ❓ Questions You Will Be Asked

#### Decision

- "When would you choose GraalVM Native Image over regular JVM
  for a new service?"

🗣️ "I would choose Native Image when: (1) startup time is critical
- for serverless functions (AWS Lambda, Google Cloud Run), cold
start can dominate latency, and 50ms vs 5s matters enormously;
(2) memory is constrained - 80MB RSS vs 300MB per instance matters
for dense microservice deployments on Kubernetes; (3) the workload
is predictable - functions with consistent request patterns benefit
from AOT's consistent latency without JIT warmup.
I would NOT choose it when: (1) the service runs continuously for
hours/days - JIT's adaptive optimization will eventually deliver
higher throughput than AOT; (2) heavy use of reflection, dynamic
proxies, or runtime class loading (Spring AOP, Hibernate proxies) -
the configuration overhead is significant even with automation;
(3) JVM diagnostic tooling is needed - JFR's event types are
limited in native image, no jstack, limited heap dumps."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | AOT vs JIT mechanics, closed-world assumption. |
| Hiring Manager   | Decision framework - when to use native. |
| Bar Raiser       | Truffle, Graal JIT vs C2, Substrate VM internals. |
| Peer Engineer    | "Spring Boot 3 native saved us 80% of our Lambda cost..." |

---

---

# JVM Tuning Strategy

**Interview Weight:** high - Architect-level. Tests ability to
approach JVM tuning systematically rather than randomly adding flags.

---

### 🎯 Model Answer

**30 seconds:**

> JVM tuning strategy: measure first, tune second. Identify the
> bottleneck - CPU, memory, GC, I/O - before changing flags.
> Key levers: heap size (-Xmx/-Xms), GC algorithm (-XX:+UseG1GC,
> UseZGC), GC pause targets (-XX:MaxGCPauseMillis), thread pool
> sizes, and JIT flags. Rule: never tune in production without
> a baseline. Never change more than one variable at a time.

**3 minutes (Senior):**

> **Tuning workflow:**
>
> Step 1: Establish baseline metrics. Capture: GC pause frequency
> and duration, heap usage pattern, CPU usage (GC vs application
> threads), latency percentiles (p50, p99, p999), throughput.
> Tools: JFR, GC logs (`-Xlog:gc*`), JMC, Prometheus + Grafana.
>
> Step 2: Identify bottleneck type.
> - GC pauses dominate? → Tune GC: increase heap, change algorithm,
>   adjust pause target.
> - CPU high with low GC? → Tune application: profiling,
>   algorithm changes.
> - Memory increasing unboundedly? → Memory leak. No flag helps.
>
> Step 3: GC tuning sequence.
> - First: right-size heap. Rule: heap should be 2-3x the live
>   data set size. Too small = too many GCs. Too large = longer
>   Full GCs.
> - Second: choose GC for your latency target.
>   - Throughput priority: G1GC (default) or Parallel GC.
>   - Low-latency priority (p99 < 50ms): ZGC or Shenandoah.
>   - Interactive small apps: CMS (deprecated) or G1GC.
> - Third: set pause target if using G1GC.
>   `-XX:MaxGCPauseMillis=100` (default 200ms).
>
> Step 4: Validate with load testing. Never tune without load.
> A heap size that looks fine under zero load will fail under
> production load patterns.
>
> Step 5: Document every change. JVM flags are code. Track them
> in version control alongside the application.

---

### 💻 Code Example

**Example 1: Production JVM flag baseline**

```bash
# BAD: Randomly copied flags from Stack Overflow
java -Xmx4g -Xms4g -XX:+UseConcMarkSweepGC \
     -XX:+CMSIncrementalMode -XX:+UseStringDeduplication \
     -XX:SurvivorRatio=8 -XX:+AggressiveOpts \
     -jar app.jar
# Problems:
# - CMS is deprecated (removed Java 15)
# - AggressiveOpts is removed in Java 11
# - Parameters not tuned to this application's actual behavior

# GOOD: Minimal, measured, documented flags
java \
  -Xmx8g -Xms8g \
  # Equal min/max avoids heap resizing pauses.
  # Size based on: live data set * 3 = measured at 2.5GB → 8G.
  -XX:+UseG1GC \
  # G1GC default in Java 9+, good for balanced throughput/latency.
  # Switch to ZGC if p99 GC pauses exceed 50ms under load.
  -XX:MaxGCPauseMillis=100 \
  # Target pause. G1 will try to stay under this (not a hard cap).
  -XX:G1HeapRegionSize=16m \
  # Tune if many humongous object allocations detected in GC log.
  -Xlog:gc*:file=/var/log/app/gc.log:time,tags:filecount=5,filesize=50m \
  # Rolling GC log. Essential for post-incident analysis.
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/var/log/app/heap-dump.hprof \
  # Dump on OOM for analysis.
  -XX:StartFlightRecording=duration=0,maxsize=200m,maxage=15m \
  # Continuous JFR. 200MB ring buffer, last 15 minutes.
  # Dump with: jcmd <pid> JFR.dump filename=/tmp/incident.jfr
  -jar app.jar

# Monitor after deploy:
# Check GC pauses: grep "GC pause" gc.log | awk '{print $NF}'
# Check promotion failures (sign of young gen too small):
# grep "to-space exhausted" gc.log
```

> **Code walkthrough:** The BAD example uses removed or deprecated
> flags that will either cause JVM startup failure or be silently
> ignored. The GOOD example sets only flags with known, measured
> rationale. Equal `-Xmx` and `-Xms` prevents heap resizing pauses.
> Rolling GC logs ensure post-incident data is always available.
> JFR continuous recording with a 15-minute ring buffer means any
> production incident can be diagnosed retrospectively.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Set Xmx/Xms equal, use G1GC default, enable GC logging, add
> HeapDumpOnOutOfMemoryError. Don't add flags without understanding
> them. Measure before tuning.

---

**Senior / Staff (5+ years):**

> My rule: each JVM flag must have a documented reason tied to a
> measured metric. I start with G1GC defaults, measure under
> production-like load, identify the bottleneck, and only then
> tune. For p99 latency requirements below 30ms, I switch to ZGC.
> The most impactful change is usually just correctly sizing the
> heap based on the actual live data set.

---

### ❓ Questions You Will Be Asked

#### Decision

- "How would you approach JVM tuning for a new microservice?"

🗣️ "I would follow four steps. Step 1: Deploy with minimal flags -
`-Xmx2g -Xms2g -XX:+UseG1GC` and GC logging enabled. Let it run
under realistic load. Step 2: Measure using GC logs and JFR.
Key metrics: GC pause frequency and duration, heap live data size
after major GC, allocation rate (MB/s). Step 3: Tune based on
the bottleneck. If GC pauses exceed my latency SLO (e.g., 100ms
p99), I adjust: increase heap if old gen is full too often,
reduce MaxGCPauseMillis if pauses are consistently over target,
or switch to ZGC if G1 can't meet the target. Step 4: Validate
under load. Re-run the load test with the new settings and
compare p50/p99/p999 latencies. Document every flag with the
measurement that justified it."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Tuning workflow, GC log analysis, ZGC vs G1. |
| Hiring Manager   | Process: measure-tune-validate. |
| Bar Raiser       | Ergonomics flags, NUMA awareness, Metaspace tuning, code cache sizing. |
| Peer Engineer    | "We cut p99 latency by 80% just by switching from CMS to ZGC..." |

---

---

# JVM Security Architecture

**Interview Weight:** medium - Architecture level security
awareness. Tests understanding of classloader security, bytecode
verification, and JVM security manager.

---

### 🎯 Model Answer

**30 seconds:**

> JVM security layers: (1) Bytecode verifier - validates that
> .class files conform to JVM spec before execution (no stack
> underflow, type safety). (2) ClassLoader isolation - different
> classloaders cannot see each other's classes. (3) Security
> Manager (deprecated in Java 17, removed in Java 24) - policy-based
> access control for system resources. (4) Module system (JPMS,
> Java 9+) - strong encapsulation prevents reflective access to
> module internals.

**3 minutes (Senior):**

> **Bytecode verification (key security layer):**
> The bytecode verifier runs when a class is loaded. It checks:
> - Stack consistency: no operation that would underflow the stack
> - Type safety: no method receives the wrong type argument
> - Access control: no access to private members via bytecode tricks
> - Final method: no override of final methods
> If verification fails: `VerifyError` at class load time.
> Significance: even if a .class file is hand-crafted maliciously,
> the verifier prevents type confusion attacks.
>
> **ClassLoader isolation:**
> Application servers (Tomcat, JBoss) use separate classloaders
> per deployed application. Each webapp cannot access another's
> classes. The parent classloader can see child classes if given
> a reference, but the child cannot see sibling classloaders.
> Security risk: classloader leaks (a reference to a class prevents
> GC of the entire classloader's classes - memory leak).
>
> **Module system (JPMS) as security boundary:**
> `module-info.java` declares exports. Un-exported packages cannot
> be accessed via reflection by default. `--add-opens` bypasses
> this (security risk if used broadly). Many frameworks previously
> used deep reflection on JVM internals - JPMS forces them to
> use stable APIs.
>
> **Security Manager (deprecated):**
> Controlled: file I/O, network, process execution, reflection,
> class loading. Replaced by more granular OS-level controls
> (containers, seccomp) and JPMS. Application code should not
> rely on Security Manager for security (it was never guaranteed
> to be a complete sandbox).

---

### 💻 Code Example

**Example 1: Module encapsulation and classloader isolation**

```java
// module-info.java (module descriptor)
module com.example.security {
    exports com.example.security.api;     // only API package exported
    // com.example.security.internal is NOT exported
    // → reflective access from outside blocked by default
}

// BAD: Bypassing module encapsulation (security risk)
// --add-opens java.base/java.lang=ALL-UNNAMED
// Allows reflective access to java.lang internals from all unnamed modules
// → Use in frameworks for backward compatibility only
// → Never use for new code; use published APIs instead

// GOOD: Use the public API
// If a class is not exported, it's not part of the contract.
// Request the module owner to export the package or provide a stable API.

// Bytecode verification: prevent type confusion
// This would fail VerifyError if hand-crafted:
// astore (storing into an int slot using reference store opcode)
// JVM verifier catches this at class load time before execution

// ClassLoader isolation (web application)
// Tomcat: each webapp gets a WebAppClassLoader
//         WebAppClassLoader cannot see sibling WebAppClassLoader's classes
// Spring: child ApplicationContext per webapp
// Risk: class leak via static field in shared parent classloader:
// BAD:
static Map<String, Object> CACHE = new HashMap<>();
// If CACHE is in a shared class (loaded by parent classloader)
// and we put objects from child classloader into it,
// we pin the child classloader → OutOfMemoryError on redeploy

// GOOD: Use WeakReference for cross-classloader associations
static Map<String, WeakReference<Object>> CACHE = new WeakHashMap<>();
```

> **Code walkthrough:** The module system enforces encapsulation
> at the JVM level - no amount of reflection can access unexported
> packages without explicit `--add-opens`. The classloader isolation
> example shows the common memory leak pattern: static caches in
> parent classloaders that hold strong references to objects from
> child classloaders, preventing garbage collection of redeployed
> applications.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JVM security includes bytecode verification (validates .class
> files), classloader isolation (applications can't see each
> other's classes), and JPMS module encapsulation (unexported
> packages cannot be reflected into).

---

**Senior / Staff (5+ years):**

> For modern Java security I rely on JPMS encapsulation rather
> than Security Manager (deprecated). The main JVM security risks
> I watch for: classloader leaks in application servers, `--add-opens`
> overuse exposing JVM internals, and deserialization attacks where
> malicious bytecode triggers gadget chains.

---

### ❓ Questions You Will Be Asked

#### Security

- "How does the JVM prevent malicious bytecode from compromising
  the host JVM?"

🗣️ "The JVM has several layers. First: bytecode verification.
Every `.class` file is verified before execution. The verifier
checks type safety (no type confusion), stack consistency (no
underflows), and access rules (no access to private members).
Hand-crafted bytecode that violates these rules causes a
`VerifyError` at class load time before any instruction executes.
Second: classloader namespacing. Each classloader has its own
namespace. A class loaded by classloader A is distinct from
the same-named class in classloader B, preventing namespace
pollution attacks. Third: module encapsulation (JPMS). Un-exported
packages cannot be accessed reflectively without explicit
`--add-opens`. This prevents library code from accessing internal
JVM classes. Fourth: the Security Manager (deprecated) provided
policy-based controls. Modern deployments use OS-level controls
(seccomp, namespaces) and container isolation instead."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Bytecode verifier, classloader isolation, JPMS encapsulation. |
| Hiring Manager   | Security Manager deprecation, modern alternatives. |
| Bar Raiser       | Deserialization exploits, serialization filters (JEP 290), module integrity. |
| Peer Engineer    | "We had a class leak per webapp redeploy - CACHE holding child classloader refs..." |
