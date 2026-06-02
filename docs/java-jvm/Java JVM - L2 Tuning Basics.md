---
layout: default
title: "Java JVM - L2 Tuning Basics"
parent: "Java JVM"
nav_order: 5
permalink: /java-jvm/l2-tuning-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java JVM - L2 Tuning Basics](#java-jvm---l2-tuning-basics) | medium |

---

# Java JVM - L2 Tuning Basics

## JVM Startup Flags and Memory Sizing

---

### 🎯 Model Answer

**30 seconds:**
> The three most important JVM flags for production: `-Xms` (initial heap),
> `-Xmx` (max heap), and the GC selection flag (`-XX:+UseG1GC` for most,
> `-XX:+UseZGC` for latency-critical). Best practice: set `-Xms` equal to
> `-Xmx` to avoid heap resizing pauses. For containers: use
> `-XX:MaxRAMPercentage=75` instead of `-Xmx` so the JVM auto-calculates
> heap from container memory limit. Always enable GC logging for production observability.

**3 minutes (Senior):**
> Heap sizing principles:
> - `-Xms` = `-Xmx`: prevents heap growth/shrink pauses (OS memory pre-allocated
>   at JVM startup). Good for stable services with predictable memory needs.
> - Rule of thumb: heap max = 2-3x the "live set" (heap used after full GC).
>   Too small: constant GC pressure. Too large: long Full GC pauses.
>
> GC tuning hierarchy:
> 1. GC algorithm selection (biggest impact): G1, ZGC, Shenandoah, Parallel GC
> 2. Heap size (fundamental): -Xmx, -XX:MaxRAMPercentage
> 3. Pause time goal (G1): -XX:MaxGCPauseMillis
> 4. Young Gen sizing (advanced): -XX:NewRatio, -XX:NewSize
> 5. Specific GC tuning (rarely needed): IHOP, SurvivorRatio, etc.
>
> Key flags for production:
> ```
> -server                     # 64-bit server-class JVM (default on modern JVMs)
> -Xms2g -Xmx2g               # Heap: fixed size (equal = no resize)
> -XX:+UseG1GC                # GC algorithm (default Java 9+)
> -XX:MaxGCPauseMillis=200    # G1 pause target
> -XX:+UseStringDeduplication # Reduce String memory (G1 only)
> -XX:NativeMemoryTracking=summary  # Enable native memory tracking
> -Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=5,filesize=20m
> ```

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Key JVM flags: -Xms/-Xmx for heap, GC selection, pause target.
Container: MaxRAMPercentage. Production: GC logging. Set Xms=Xmx for stability."

**(2) First principles:** "JVM memory configuration determines: how much OS memory
is used, how often GC runs, and how long each GC pause is. More heap = less frequent
GC but potentially longer Full GC. Smaller pause target = more frequent GC."

**(3) Bridge:** "JVM flags are like calibrating a car's fuel tank. Too small a tank
(Xmx): you stop at every gas station (frequent GC). Too large a tank: the car
is heavier (longer Full GC). The sweet spot: 2-3x your fuel needs (live set size)."

---

### 📘 Concept Explanation

**Essential production flags:**
```
HEAP SIZING:
  -Xms<n>g         Initial heap size
  -Xmx<n>g         Maximum heap size
  Set equal: -Xms4g -Xmx4g (avoid resize pauses, predictable memory)
  Container-aware: -XX:MaxRAMPercentage=75 (heap = 75% of container memory)
  -XX:MinRAMPercentage=50  (lower bound for small containers)

GC SELECTION:
  -XX:+UseG1GC           Default Java 9+, balanced
  -XX:+UseZGC            Sub-ms pauses, Java 15+
  -XX:+UseShenandoahGC   Low-pause, OpenJDK only
  -XX:+UseParallelGC     Throughput-focused, batch jobs
  -XX:+UseSerialGC       Single-core, embedded/minimal

GC TUNING (G1):
  -XX:MaxGCPauseMillis=200  Pause target (default 200ms)
  -XX:G1HeapRegionSize=4m   Region size (auto-selected normally)
  -XX:InitiatingHeapOccupancyPercent=45  Concurrent mark trigger
  -XX:ConcGCThreads=4       Concurrent GC threads (default: n_cpus/4)

METASPACE:
  -XX:MaxMetaspaceSize=256m  Cap Metaspace (unlimited by default)

OBSERVABILITY (mandatory for production):
  -Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=5,filesize=20m
  -XX:NativeMemoryTracking=summary
  -XX:+HeapDumpOnOutOfMemoryError
  -XX:HeapDumpPath=/var/log/
```

> **Code walkthrough:** This L2 Tuning Basics example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** The Dockerfile example shows correct JVM containerice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> configuration. Using `MaxRAMPercentage` lets Kubernetes change the container
> memory limit without changing the Java command line. The GC log flags ensure
> production observability without significant overhead (<1% CPU).


```dockerfile
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```dockerfile
# BAD: hardcoded heap, ignores container limits
FROM eclipse-temurin:21-jre
CMD ["java", "-Xmx2g", "-jar", "app.jar"]
# Problem: if container memory limit changes, Xmx is wrong

# GOOD: container-aware, production-ready JVM configuration
FROM eclipse-temurin:21-jre
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 \
  -XX:MaxMetaspaceSize=256m \
  -XX:ReservedCodeCacheSize=256m \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/var/log/heapdump.hprof \
  -Xlog:gc*:file=/var/log/gc.log:time,uptime,level,tags:filecount=5,filesize=20m \
  -XX:NativeMemoryTracking=summary"
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# Kubernetes container resources:
# resources:
#   requests:
#     memory: "2Gi"
#   limits:
#     memory: "2Gi"
# -> JVM heap = 2048MB * 0.75 = 1536MB (auto-calculated by JVM)
# -> Non-heap overhead: ~512MB
# -> Total: ~2048MB (fits limit)

# Checking applied JVM flags at runtime:
// Code to log effective JVM configuration:
RuntimeMXBean runtimeMXBean = ManagementFactory.getRuntimeMXBean();
List<String> inputArgs = runtimeMXBean.getInputArguments();
log.info("JVM flags: {}", String.join(" ", inputArgs));

// Verify heap settings:
MemoryMXBean memBean = ManagementFactory.getMemoryMXBean();
MemoryUsage heap = memBean.getHeapMemoryUsage();
log.info("Heap max: {}MB, init: {}MB",
    heap.getMax() / 1_000_000,
    heap.getInit() / 1_000_000);
```

> **Code walkthrough:** The `JAVA_OPTS` approach in Dockerfiles allowsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> operators to override flags without rebuilding the image. Setting
> `MaxRAMPercentage` rather than a fixed `-Xmx` makes the application
> "autoscalable" - the JVM adapts to whatever memory limit the orchestrator
> assigns. The HeapDumpOnOutOfMemoryError flag automatically captures a heap
> dump on OOM, enabling post-mortem diagnosis without manual intervention.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Set `-Xms` and `-Xmx` to the same value for stability. Use `-XX:+UseG1GC`
> for general services. Add `-Xlog:gc*:file=gc.log` for production.
> Use `-XX:MaxRAMPercentage=75` in containers.

---

**Senior / Staff (5+ years):**
> JVM tuning should be evidence-based: start with defaults, observe via GC logs,
> identify the bottleneck (allocation rate? promotion rate? pause time?), then
> tune the specific parameter. Premature GC tuning without data: wastes time and
> often makes things worse. The JVM's self-tuning (Adaptive IHOP, Ergonomics) is
> surprisingly effective. The flags that matter most in practice: heap size (determines
> GC frequency), MaxGCPauseMillis (determines GC work per cycle), and GC algorithm
> (fundamental throughput vs latency trade-off). Everything else is advanced tuning
> for specific diagnosed issues.

---

### ⚠️ Common Misconceptions

**Misconception 1: "More heap always means better performance."**
Larger heap reduces GC frequency (less time in GC), but increases Full GC duration
(more to compact). Beyond the optimal point: adding heap makes Full GC so slow that
applications appear frozen. Rule: live set * 2-3x. For G1/ZGC with concurrent
marking: larger heap is generally fine (Full GC is rare/avoided). For Parallel GC
with large heap: Full GC can be catastrophically long.

**Misconception 2: "JVM flags only affect GC."**
Many JVM flags affect behavior beyond GC: `-XX:+BiasedLocking` (lock optimization,
disabled Java 15+), `-XX:+OptimizeStringConcat` (string concatenation optimization),
`-XX:CompileThreshold` (JIT compilation threshold), `-XX:+UseCompressedOops`
(pointer compression), `-server` vs `-client` (JIT optimization level).
These flags affect startup time, peak throughput, and memory layout, not just GC.

---

### 🚨 Failure Modes and Diagnosis

**Failure: JVM using much more memory than Xmx - container OOM kills.**
```
Symptom: Container OOM killed despite JVM heap usage < Xmx

Diagnosis:
  1. Start with: jcmd <pid> VM.native_memory summary
  2. Check all memory categories:
     Java Heap (expected ~Xmx)
     Class/Metaspace (unlimited by default -> check for leaks)
     Thread stacks (threads * Xss)
     Code Cache (JIT compiled code)
     Compiler (JIT compiler data)
     GC (GC data structures)
     Internal, Other (JVM internals)
  3. Identify the growing category

Fix by category:
  Metaspace growing: set -XX:MaxMetaspaceSize=256m
    If OOM: ClassLoader leak -> heap dump needed
  Code Cache: set -XX:ReservedCodeCacheSize=256m
    Monitor with: jcmd <pid> Compiler.codecache
  Threads too many: reduce thread count, use virtual threads (Java 21)
    Each thread stack: 1MB by default
    100 threads: 100MB just for stacks
  Direct Buffers: set -XX:MaxDirectMemorySize=256m
    Find allocators: jstack for ByteBuffer.allocateDirect call sites
```

> **Code walkthrough:** This Checking applied JVM flags at runtime: example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Essential production flags | 2 minutes |
| Xms vs Xmx - why equal? | 90 seconds |
| Container memory sizing | 2 minutes |
| GC algorithm selection | 2 minutes |
| MaxGCPauseMillis behavior | 2 minutes |
| Metaspace sizing | 2 minutes |
| GC logging flags | 90 seconds |
| NativeMemoryTracking | 2 minutes |
| Ergonomics (auto-tuning) | 2 minutes |

---

**Q1 (Xms=Xmx): Why set -Xms equal to -Xmx?**

A: When -Xms < -Xmx: JVM starts with small heap and grows as needed. Each growth
requires: requesting memory from OS (may incur OS-level memory allocation overhead),
JVM heap resize operation (brief pause). Setting them equal: heap is fully allocated
at JVM startup, no resize during runtime. Benefits: no resize pauses during
load spikes, predictable memory footprint, faster startup (OS might zero-initialize
all pages upfront rather than lazily). Trade-off: uses peak memory even during
quiet periods.

*What separates good from great:* In Kubernetes: matching -Xms with -Xmx (or
using MaxRAMPercentage consistently) ensures the pod's memory request = memory
limit = actual JVM footprint. This prevents the "slowly growing then OOM" pattern
where the JVM heap gradually expands to max. With equal Xms=Xmx: the pod
immediately shows its true memory usage after startup. This helps with:
Kubernetes scheduling (accurate memory requests), alerting (no gradual growth
masking a leak), and GC stability (heap size constant = GC behavior predictable).

---

**Q2 (MaxRAMPercentage): How does -XX:MaxRAMPercentage work?**

A: `MaxRAMPercentage=75` sets heap to 75% of available memory. "Available memory"
is read from: container cgroup memory limit (if running in a container, Java 8u191+),
or physical host memory (if no container limit). Example: container with 4GB limit:
heap = 4096MB * 0.75 = 3072MB. Works transparently in Docker/Kubernetes. Complementary
flags: `-XX:MinRAMPercentage=50` (floor for small containers, < 250MB), `-XX:InitialRAMPercentage=50`
(sets Xms as percentage).

*What separates good from great:* Before Java 8u191: JVM didn't recognize container
memory limits. It read total host memory (e.g., 64GB). With `-XX:MaxRAMPercentage=75`:
heap = 48GB, but container limit is 2GB -> immediate OOM kill on startup. Fix for
old JVMs: use `-Xmx` explicitly. For Java 11+: `MaxRAMPercentage` is fully container-aware.
Kubernetes pattern: set memory `requests == limits` (QoS = Guaranteed), use
`MaxRAMPercentage=75`. The 25% margin covers: Metaspace (~200MB), Code Cache (~240MB),
thread stacks (~100MB), GC overhead (~50MB). For a 1GB container: don't use 75%
(leaves only 256MB for non-heap, may not be enough). Use 50% instead.

---

**Q3 (GC logging): What GC logging flags should be in every production JVM?**

A: Java 11+ unified logging:
```
-Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=5,filesize=20m
```
> **Code walkthrough:** This Checking applied JVM flags at runtime: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

- `gc*`: all GC events (log level info)
- `file=gc.log`: write to file (not stdout)
- `time,uptime,level,tags`: decorators (wall time, JVM uptime, log level, tags)
- `filecount=5,filesize=20m`: rotate (5 files, 20MB each = max 100MB)

Additional observability:
```
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/
-XX:NativeMemoryTracking=summary
-XX:+PrintFlagsFinal  (startup only: print all effective JVM flags)
```

> **Code walkthrough:** This Checking applied JVM flags at runtime: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* `-XX:+PrintFlagsFinal` at startup outputs all
3000+ JVM flags with their actual values. This is the definitive record of "what
JVM settings were actually applied." Log the first 100 lines at startup - it shows
whether your flags took effect or were ignored (some flags are ignored if conflicting).
For log shipping: write GC logs to a file and tail into log aggregator (ELK, Splunk).
Don't write to stdout (mixed with application logs, hard to parse). Many organizations
use GCeasy.io for cloud-based GC log analysis with alerts.

---

**Q4 (ergonomics): What is JVM ergonomics?**

A: JVM ergonomics = automatic JVM configuration based on hardware detection.
The JVM detects: number of CPU cores, available memory, and whether running on
a "server-class" machine (≥2 CPUs, ≥2GB). Based on these: selects default GC
(G1 for server-class), sets default heap sizes (-Xmx = ~25% of physical RAM),
sets JIT compiler settings (-server for server-class). Most ergonomics defaults
are reasonable for general workloads. Containers: ergonomics reads container
limits (Java 10+ container-aware ergonomics).

*What separates good from great:* Ergonomics' `-Xmx` default is 25% of physical
RAM, capped at 256MB for environments under 1GB. For a 16GB host with no container:
default Xmx = 4GB. This seems reasonable but may be wrong for your app. Common
issue: running multiple JVMs on the same host, each with 4GB default Xmx = 16GB
total heap competing for 16GB host memory -> each JVM actually gets 4GB but
competes with others. In containers: each container gets its own view (correct).
On bare metal with multiple services: set explicit Xmx for each JVM rather than
relying on ergonomics.

---

**Q5 (flags): How do you verify what JVM flags are actually in effect?**

A:
```bash
# Print all final effective flags (after ergonomics applied):
java -XX:+PrintFlagsFinal -version 2>&1 | grep -i heapsize

# Or: check a running JVM:
jcmd <pid> VM.flags

# Check specific flag:
jcmd <pid> VM.flags | grep -i MaxGCPauseMillis

# Print only non-default flags (flags you changed):
jcmd <pid> VM.flags -all | grep " :="  <- := means modified from default
```

> **Code walkthrough:** This Print only non-default flags (flags you changed): example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* The ` :=` vs `=` distinction in `PrintFlagsFinal`
output: `=` means using the default value, `:=` means modified (by ergonomics,
command line, or JVM internal decision). When diagnosing "why is the JVM behaving
differently": `VM.flags` shows what actually took effect, not what you put on the
command line. Sometimes flags conflict (e.g., setting a flag that requires another
flag to be set first), and the JVM silently ignores one. The `:=` annotation is
the ground truth.

---

**Q6 (CodeCache): What is the Code Cache and what happens when it fills?**

A: Code Cache stores JIT-compiled native code. Default max: 240MB. When full:
JVM stops JIT-compiling new methods. Methods that would have been compiled: run
in interpreter (10-100x slower). GC log shows: `"CodeCache is full. Compiler has
been disabled."` Throughput gradually degrades as more "hot" code runs interpreted.

```bash
# Monitor Code Cache:
jcmd <pid> Compiler.codecache
# Output:
# CodeCache: size=245760Kb used=12345Kb max_used=12678Kb free=233415Kb
# bounds [0x00007f8c80000000, 0x00007f8c80c10000, 0x00007f8c8f000000]

# Alert threshold: > 80% usage
```

> **Code walkthrough:** This Alert threshold: > 80% usage example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Fix: `-XX:ReservedCodeCacheSize=512m`. Also: `-XX:+UseCodeCacheFlushing` enables
eviction of old compiled code (default varies by JVM version).

*What separates good from great:* Code Cache filling is commonly seen in:
large Spring Boot applications (hundreds of service classes, all compiled),
applications that use heavy reflection/code generation (Jackson, Hibernate
proxies, CGLIB), and applications that run for days without restart (compilation
accumulates over time). A common symptom: application runs well for 2-4 hours,
then throughput gradually drops. GC log check shows no GC issues. Code Cache
check reveals `>90% full`. Fix: increase ReservedCodeCacheSize and restart.
Long-term: profile which methods are JIT-compiled (JFR JITCompilation events)
and look for code generation creating many classes unnecessarily.

---

**Q7 (startup): What flags improve JVM startup time?**

A: JVM startup optimization flags:
- `-XX:TieredStopAtLevel=1`: stop JIT at C1 (quick, less optimized). Useful
  for scripts/lambdas that run briefly.
- `-Xshare:on` (CDS - Class Data Sharing): pre-load class data from archive,
  skip loading/verification. Reduces startup by 10-40%.
- `-XX:+UseAppCDS` (AppCDS, Java 10+): application classes in share archive.
  Large impact for fat JARs.
- GraalVM native-image: AOT compilation to native binary. Startup in milliseconds.

*What separates good from great:* AppCDS (Application Class Data Sharing) is
the most practical startup optimization for JVM services. Process: (1) run with
`-XX:DumpLoadedClassList=classes.lst` to capture loaded classes; (2) create archive
`java -Xshare:dump -XX:SharedArchiveFile=app.jsa ...`; (3) run with
`-Xshare:on -XX:SharedArchiveFile=app.jsa`. Result: startup time reduced 20-40%
for typical Spring Boot applications. Container images include the JSA file.
GraalVM native image: even faster startup (milliseconds) but no JIT optimization
at runtime - peak throughput lower than JIT-optimized JVM. Best for: serverless
functions, CLI tools, startup-critical microservices.

---

**Q8 (safe flags): What are safe defaults for production Java services?**

A: A baseline safe configuration:
```
-server
-Xms$(MAX_HEAP) -Xmx$(MAX_HEAP)  # or MaxRAMPercentage=75
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:MaxMetaspaceSize=256m
-XX:ReservedCodeCacheSize=256m
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/tmp/heapdump.hprof
-Xlog:gc*:file=/var/log/gc.log:time,uptime:filecount=5,filesize=20m
-XX:NativeMemoryTracking=summary
-Djava.security.egd=file:/dev/./urandom
```

> **Code walkthrough:** This Alert threshold: > 80% usage example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

The last flag: `/dev/./urandom` (note the extra `.`) avoids blocking on
`/dev/random` for secure random number generation during SSL handshakes
or UUID generation.

*What separates good from great:* The `java.security.egd` flag is the most
commonly forgotten production flag. Without it: `SecureRandom` on Linux
reads from `/dev/random`, which blocks when entropy is low. In containers with
low entropy (no mouse/keyboard input): `/dev/random` can block for seconds
during HTTPS connection setup or JWT signing. Symptom: random 1-30 second
hangs in HTTPS endpoints with no GC or application-level cause. Fix:
`-Djava.security.egd=file:/dev/./urandom` (the dot in `/./` is intentional -
it prevents old JVM versions from mapping `./urandom` back to `/dev/random`).
Java 17+: secure random defaults are better; this is still a good practice
for compatibility.

---

**Q9 (GC comparison flags): How do you A/B test JVM GC configurations?**

A: (1) Enable GC logging on both configurations: `-Xlog:gc*:file=gc.log:time,uptime`.
(2) Run same workload (load test or production traffic shadow). (3) Compare:
GC overhead (total GC time / uptime), P99 pause time, throughput (ops/second).
Tools: GCeasy.io (uploads logs, generates comparison report), JFR (Flight
Recorder captures GC events + application metrics in one profile).

```bash
# Quick comparison script:
# Extract GC overhead from log:
total_gc_ms=$(grep -oP '\d+\.\d+ms' gc.log | \
  awk '{sum += $1} END {print sum}')
uptime_ms=$(tail -1 gc.log | grep -oP '^\d+\.\d+' | awk '{print $1*1000}')
echo "GC overhead: $(echo "scale=2; $total_gc_ms/$uptime_ms*100" | bc)%"
```

> **Code walkthrough:** This Extract GC overhead from log: example demonstrates ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* A/B testing GC configurations should be
done under PRODUCTION-LIKE load (actual request patterns, not synthetic benchmar
GC behavior is highly sensitive to allocation patterns - a benchmark that alloca
differently from production gives misleading results. The gold standard: canary
deployment. Run new JVM flags on 5% of production traffic, compare metrics
(latency P99, CPU utilization, GC overhead in JMX). Roll back if metrics worsen.
The 5% canary runs for at least one "GC cycle" - for G1 with IHOP=45%: until
a concurrent marking cycle completes (typically 30-60 minutes at moderate load).

---

### ⚖️ Comparison Table

| Flag| Purpose| Default| When to Change|
|--------|-----------------------|---------|-----------------------------------|
| `-Xmx`| Max heap| 25% RAM| Always set explicitly in production|
| `-XX:MaxGCPauseMillis`| G1 pause target| 200ms| < 200ms for low-latency APIs|
| `-XX:MaxMetaspaceSize`| Metaspace cap| Unlimited| Always set to detect leaks|
| `-XX:ReservedCodeCacheSize`| JIT code storage| 240MB| 512m for large apps|
| `-XX:InitiatingHeapOccupancyPercent`| Concurrent mark trigger| 45%| Lower (30%

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: flag configuration described adequately in Concept Explanation)*

---

---

## GC Log Analysis

---

### 🎯 Model Answer

**30 seconds:**
> GC logs are the primary diagnostic tool for JVM performance issues. Enable wit
> `-Xlog:gc*:file=gc.log:time,uptime,level,tags` (Java 11+). Key metrics to watc
> pause duration (should be < 200ms for G1), frequency (how often GC runs = allo
> rate indicator), heap before/after each GC (growing "after" = memory pressure)
> and GC type (Young = normal, Full = alarm). Ten minutes of GC log analysis oft
> reveals root causes that take hours to find via heap dumps.

**3 minutes (Senior):**
> Reading G1 GC log:
> ```
> [time][gc] GC(N) Pause Young (Normal) (G1 Evacuation Pause) 100M->30M(512M) 8.
> ```
> - `GC(N)`: GC sequence number (N) - sequential per JVM lifetime
> - `Pause Young (Normal)`: Minor GC, normal reason
> - `G1 Evacuation Pause`: G1 GC's term for copying GC (evacuation)
> - `100M->30M(512M)`: heap before->after(max)
> - `8.5ms`: stop-the-world pause duration
>
> Patterns that indicate problems:
> - Increasing "after GC" heap values: live set growing (potential leak or more 
> - Frequent `Concurrent Start` with `G1 Humongous Allocation` reason: humongous
> - `Pause Full` appearing: G1 fallback to Full GC (serious problem)
> - Very short interval between Minor GCs (< 1 second): high allocation rate

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "GC log key info: GC type, pause duration, heap before/after,
reason. Patterns: growing heap = leak, frequent GC = allocation rate, Full GC = critical."

**(2) First principles:** "GC logs provide a time-series record of every GC even
when it happened, how long it paused, how much memory it freed. This data directly
answers: is GC the problem? Is there a memory leak? Is the heap sized correctly?"

**(3) Bridge:** "GC logs are like a car's trip computer. Every time the engine
performs a maintenance cycle (GC), it records: duration, before/after fuel level
(heap), reason. Reviewing the log reveals: unusually long stops (long pauses),
stops too frequent (high allocation rate), fuel running low (heap pressure)."

---

### 📘 Concept Explanation

**GC log anatomy:**
```plaintext
Java 11+ unified logging format:
[TIMESTAMP][UPTIME][LEVEL][TAGS] MESSAGE

Examples:
[2024-01-15T10:23:45.123+0000][1.234s][info][gc] GC(5)
  Pause Young (Normal) (G1 Evacuation Pause)
  50M->20M(512M) 5.678ms

Decoded:
  2024-01-15T10:23:45.123+0000  Wall clock time
  1.234s                        JVM uptime
  info                          Log level
  gc                            Tag
  GC(5)                         5th GC event since start
  Pause Young (Normal)          Type: Minor GC, Normal reason
  G1 Evacuation Pause           G1-specific: copying GC
  50M->20M(512M)               Heap: before->after(max)
  5.678ms                       Pause duration

Key indicators:
  "Pause Young"     -> Minor GC (normal, fast)
  "Pause Remark"    -> G1 concurrent mark remark (brief STW)
  "Pause Cleanup"   -> G1 after concurrent mark (brief STW)
  "Pause Young (Mixed)" -> G1 Mixed GC (Young + some Old)
  "Pause Full"      -> Full GC (ALARM: investigate immediately)
  "Concurrent Mark Cycle" -> G1 background marking (not STW)
```

> **Code walkthrough:** This Extract GC overhead from log: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** These shell commands analyze GC logs without specializedice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> tools. The grep/awk pipeline is reproducible on any Linux/Mac server,
> requires no GUI, and works on production hosts. These patterns catch the
> most common GC issues in minutes.

```bash
# Download a GC log to analyze:
# scp prod-server:/var/log/gc.log ./gc.log

# 1. Count GC events by type:
grep -oP 'Pause [A-Za-z ]+' gc.log | sort | uniq -c | sort -rn
# Output:
#  450 Pause Young (Normal)
#   12 Pause Young (Mixed)
#    2 Pause Full          <- ALARM: only 2, but any = investigate

# 2. Get pause duration statistics:
grep -oP 'Pause Young.*\K\d+\.\d+ms' gc.log | \
  awk '{n++;sum+=$1;if($1>max)max=$1} END {printf "count=%d avg=%.1fms max=%s\n",n,sum/n,max}'

# 3. Check if heap is growing after GC (memory leak indicator):
grep "Pause Young" gc.log | \
  grep -oP '\d+M->\d+M' | \
  awk -F'[-M>]+' '{print $3}' | \  # extract "after" value
  tail -20
# If numbers keep increasing: Old Gen filling (potential leak)

# 4. Find GC intervals (allocation rate):
grep "Pause Young" gc.log | \
  grep -oP '^\[\d+\.\d+s\]' | \
  awk -F'[\[\]s]' 'NR>1 {printf "%.3fs between GCs\n", $2-prev} {prev=$2}' | \
  tail -10
# Short intervals (< 1s): high allocation rate

# 5. Full GC detection and context:
grep -B5 -A2 "Pause Full" gc.log
# Shows what happened before Full GC (usually to-space-exhausted or explicit GC)

# 6. G1 concurrent marking frequency:
grep "Concurrent Mark Cycle" gc.log | wc -l
# Many concurrent cycles = heap pressure (marking runs frequently)
```

> **Code walkthrough:** Pattern 3 (heap growth) is the memory leak detector.
> After each Minor GC, the "after" heap value should be relatively stable.
> If it increases by 5-10MB every few minutes under constant load: Old Gen is
> accumulating objects faster than they're being collected -> potential memory
> leak. Once the trend is identified in logs: take two heap dumps 1 hour apart
> and compare in Eclipse MAT to identify the leaking class.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> GC logs show pause times, heap usage, and GC type for every GC event. Enable
> with `-Xlog:gc*:file=gc.log`. Watch for: pauses > 200ms, Full GC events,
> heap after GC increasing over time. GCeasy.io can analyze log files online.

---

**Senior / Staff (5+ years):**
> GC log correlation with application latency is the advanced diagnostic skill.
> Tools: distributed tracing (OpenTelemetry) + GC logs + system metrics. When a
> customer reports "random 500ms spikes every few minutes": overlay GC pause
> timeline with latency spike timeline. If they correlate: GC is the root cause.
> If they don't: GC is innocent (look at network, database, thread pool saturation).
> JFR (Java Flight Recorder) correlates GC events with application events in a
> single timeline - more powerful than separate GC logs.

---

### ⚠️ Common Misconceptions

**Misconception 1: "GC pause duration in logs equals user-perceived latency increase."**
GC pause = all threads paused for that duration. A request that ARRIVED during a
GC pause experiences the full pause. A request that arrived 10ms BEFORE the GC
pause may also be delayed (it's executing when GC starts, then frozen for the
GC duration). P99 latency impact from GC: any request whose processing overlaps
with a GC pause sees added latency. Distribution: requests randomly starting
before GC see partial overlap; requests during GC see full pause.

**Misconception 2: "Frequent GC means GC is the bottleneck."**
Frequent GC means high allocation rate, not necessarily a GC problem. If each
Minor GC is 5ms and runs every 2 seconds: GC overhead = 0.25% (negligible).
The problem is only when: (1) GC pauses are long (> 200ms), (2) GC overhead
is high (> 5% of wall time), or (3) Old Gen fills despite frequent GC (promotion
rate exceeds collection rate). Check GC overhead (`total_gc_ms / total_uptime_ms`)
before concluding GC is a problem.

---

### 🚨 Failure Modes and Diagnosis

**Failure: GC log file not rotating - disk full from unbounded GC log.**
```plaintext
Symptom: Server disk full, application crashes
  find / -name "gc.log" -size +1G -> found at /var/log/gc.log

Cause: GC logging without file rotation
  -Xlog:gc*:file=gc.log  <- NO rotation flags!
  Logs accumulate indefinitely

Fix:
  CORRECT logging flag with rotation:
  -Xlog:gc*:file=/var/log/gc.log:time,uptime,level,tags:filecount=5,filesize=20m
  |                                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  This limits: 5 files x 20MB each = max 100MB total

  For existing runaway log:
  1. DO NOT delete the log while JVM is running (log file handle open)
  2. Truncate safely: > /var/log/gc.log  (truncate to zero)
  3. Or: logrotate with copytruncate
  
  Monitor disk usage:
  df -h /var/log
  du -sh /var/log/gc*
  
  Alerting: add disk usage alert at 70% -> investigate before full
```

> **Code walkthrough:** This Many concurrent cycles = heap pressure (marking runs frequently) example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Reading a GC log line | 2 minutes |
| Finding memory leaks via GC logs | 2 minutes |
| GC overhead calculation | 90 seconds |
| Identifying Full GC in logs | 90 seconds |
| Allocation rate analysis | 2 minutes |
| JFR vs GC logs | 2 minutes |
| G1 concurrent mark in logs | 2 minutes |
| Correlating GC with latency | 2 minutes |
| GC log tooling | 90 seconds |

---

**Q1 (read log): Walk me through reading a GC log line.**

A: `[1.234s][info][gc] GC(5) Pause Young (Normal) (G1 Evacuation Pause) 50M->20M(512M) 5.678ms`
- `1.234s`: JVM uptime when GC occurred
- `GC(5)`: 5th GC event
- `Pause Young (Normal)`: Minor GC with reason "Normal" (Eden full, routine collection)
- `G1 Evacuation Pause`: G1's copying operation
- `50M->20M(512M)`: heap was 50MB before GC, 20MB after, max 512MB
- `5.678ms`: stop-the-world pause duration (all threads paused this long)

*What separates good from great:* The GC cause in parentheses encodes the root
cause. Common G1 causes: "Normal" (Eden full, routine), "Concurrent Start"
(triggers concurrent marking cycle - check what triggered it), "G1 Humongous
Allocation" (large object bypassed Eden), "GCLocker" (JNI code held GC lock
too long), "System.gc()" (explicit call). Each cause has a different fix.
"Concurrent Start" is informational. "G1 Humongous Allocation" means your objects
are too large for Eden. "GCLocker" means JNI code runs too long without allowing GC
(rare in pure Java apps, common with native library wrappers).

---

**Q2 (allocation rate): How do you calculate allocation rate from GC logs?**

A: Allocation rate = (heap before GC - heap after previous GC) / time between GCs.
From logs: between two consecutive Minor GC events, heap grew from 20MB (after last GC)
to 50MB (before this GC) in 2 seconds = 15MB/s allocation rate.
```bash
# Automated:
grep "Pause Young" gc.log | awk '
  BEGIN {prev_after=0; prev_time=0}
  {
    # Extract uptime [1.234s]
    match($0, /\[([0-9.]+)s\]/, t)
    # Extract before->after (50M->20M)
    match($0, /([0-9]+)M->([0-9]+)M/, m)
    if (prev_time > 0) {
      alloc = m[1] - prev_after
      interval = t[1] - prev_time
      printf "%.1f MB/s allocation rate\n", alloc/interval
    }
    prev_after = m[2]; prev_time = t[1]
  }'
```

> **Code walkthrough:** This Extract before->after (50M->20M) example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* High allocation rate (> 500MB/s) is not
automatically a problem if the GC overhead is low. The question is whether
the allocation is necessary. JFR ObjectAllocationInNewTLAB events profile
allocation by stack trace: which code paths allocate the most? Common findings:
(1) JSON deserialization creating intermediate Map/List objects (fix: streaming
JSON parser), (2) String concatenation in hot loops (fix: StringBuilder or
template), (3) logging with object.toString() calls on disabled log levels
(fix: use `log.isDebugEnabled()` guard or lazy logging with `{}`).

---

**Q3 (Full GC): How do you use GC logs to diagnose why Full GC happened?**

A: Look for events BEFORE the Full GC:
```bash
grep -B20 "Pause Full" gc.log | head -30
```
> **Code walkthrough:** This Extract before->after (50M->20M) example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Common patterns:
- `"to-space exhausted"` before Full GC: Survivor or Old Gen overflow during Minor GC
- `"System.gc()"` as cause: explicit GC call (check for System.gc() in code)
- `"GCLocker Initiated GC"`: JNI lock held too long
- `"Metadata GC Threshold"`: Metaspace full -> triggered GC
- `"Ergonomics"`: JVM heuristic decided to run Full GC (adaptive tuning)
- Rapidly growing heap before Full GC: Old Gen filled before concurrent mark completed

*What separates good from great:* Full GC post-mortem: check heap AFTER Full GC.
If `Pause Full: 1024M->800M` (after Full GC, heap is still 800MB): live set is
800MB. This means: (1) normal if application has a large cache and 800MB is expected;
(2) potential leak if 800MB is growing (compare with Full GCs from an hour ago).
Full GC should bring heap to near the "true live set" (objects that really need
to stay alive). If Full GC can't reclaim more than 20% of heap: the live set is
growing -> memory leak.

---

**Q4 (JFR vs logs): When do you use JFR instead of GC logs?**

A: GC logs: GC event timeline, pause durations, heap usage - cheap, always enabled.
JFR (Java Flight Recorder): GC events PLUS application events (CPU hot methods,
object allocation by stack trace, thread states, lock contention, network, I/O)
in one correlated timeline. Use JFR for: finding which CODE is causing GC pressure
(allocation profiling), correlating GC with latency spikes (GC event + request
duration in one view), diagnosing mixed problems (GC + CPU + lock).

```bash
# Start JFR on running JVM (low overhead, ~2-5% CPU):
jcmd <pid> JFR.start duration=60s settings=profile \
  filename=/tmp/profile.jfr

# Open with JDK Mission Control (JMC):
# Shows: GC view, Memory view, CPU hot methods, allocations by stack trace
```

> **Code walkthrough:** This Shows: GC view, Memory view, CPU hot methods, allocations by stack trace example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* JFR's "Object Allocation" profiling is the most
valuable GC diagnosis tool that doesn't require a heap dump. It shows: which call
stacks allocate the most bytes per second. Filtering by allocation-in-new-TLAB events
(regular allocations) vs allocation-outside-TLAB (large objects) gives a complete
allocation profile. The data is sampled (not every allocation) so overhead is low
(~2-5% CPU). A 60-second JFR capture under production load reveals the top allocation
contributors. This data, combined with GC log allocation rate analysis, gives actionable
optimization targets.

---

**Q5 (pause histogram): How do you build a GC pause histogram?**

A:
```bash
# Extract all pause durations and generate a histogram:
grep -oP 'Pause.*\K(\d+\.\d+)ms' gc.log | \
  awk '{
    bucket = int($1/10)*10  # bucket by 10ms
    count[bucket]++
  } END {
    for (b in count) print b "ms:", count[b]
  }' | sort -n

# Output:
# 0ms: 400  (0-10ms: 400 GC events)
# 10ms: 45  (10-20ms: 45 events)
# 20ms: 8   (20-30ms: 8 events)
# 100ms: 2  (100-110ms: 2 events) <- outliers

# P95, P99 pauses:
grep -oP 'Pause.*\K(\d+\.\d+)ms' gc.log | \
  sort -n | \
  awk 'END {print "count=" NR; p95=int(NR*0.95); p99=int(NR*0.99)} \
    NR==p95{print "P95=" $1 "ms"} NR==p99{print "P99=" $1 "ms"}'
```

> **Code walkthrough:** This P95, P99 pauses: example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* GC pause P99 is the correct metric for latency
SLAs, not average. A web API with P99 latency SLA of 100ms: GC pause P99 must be
< 30ms (leaving 70ms for actual processing). If GC pause P99 is 80ms: every 100th
GC event adds 80ms to request latency, likely breaching the 100ms SLA. With G1 and
`MaxGCPauseMillis=50`: G1 targets P50 around 50ms (it's a target, not a guarantee).
P99 may be 3-5x the target during high-load periods. ZGC: P99 consistently < 1ms.
For P99 < 10ms requirements: ZGC is the only option.

---

**Q6 (tooling): What tools help analyze GC logs?**

A: (1) GCeasy.io: cloud-based, upload log, instant analysis report (pause time
distribution, memory trends, GC recommendations). (2) GCViewer: desktop Java app,
graphs GC data over time. (3) GCPlot: browser-based, handles large logs.
(4) JDK Mission Control (JMC): analyzes JFR recordings with GC view.
(5) Prometheus + Grafana: JVM metrics via Micrometer/JMX exporter, real-time
dashboard. (6) Manual: grep/awk scripts for targeted analysis.

*What separates good from great:* Prometheus JVM metrics exporter
(`io.micrometer:micrometer-registry-prometheus`) exposes GC metrics as time-series
data: `jvm_gc_pause_seconds_count`, `jvm_gc_pause_seconds_sum`, `jvm_memory_used_bytes`.
With Grafana dashboards: real-time visualization of GC behavior over days/weeks.
Alerting: GC overhead > 5%, Full GC count increasing, heap usage > 80% after GC.
This proactive monitoring catches memory leaks before they cause OOM. The Grafana
JVM dashboard (ID 4701, "JVM overview") is a standard starting point - import it
and connect to your Prometheus to get instant GC visibility.

---

**Q7 (G1 concurrent mark): How do you identify concurrent marking in GC logs?**

A: G1 concurrent marking phases appear as info events (not pause events):
```
[5.123s][info][gc] GC(15) Concurrent Mark Cycle
[5.456s][info][gc] GC(15) Pause Remark 200M->200M(512M) 3.45ms
[5.600s][info][gc] GC(15) Pause Cleanup 200M->190M(512M) 0.23ms
[5.612s][info][gc] GC(15) Concurrent Mark Cycle 489ms  <- total concurrent time
```
> **Code walkthrough:** This P95, P99 pauses: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

The "Concurrent Mark Cycle" spans several seconds. "Pause Remark" and "Pause Cleanup"
are the brief STW phases within. If concurrent marking completes and is followed
by Mixed GC events: healthy. If concurrent marking doesn't keep up (heap fills
before cycle completes) -> Full GC.

*What separates good from great:* The frequency of concurrent marking cycles
reveals the pressure on Old Gen. One cycle per 10-30 minutes under normal load:
healthy. One cycle per minute: Old Gen under pressure (allocation rate high
relative to heap size). Concurrent marking immediately followed by another
concurrent marking cycle: Old Gen is never "clean" - allocation rate equals
reclamation rate (near saturation point). This state can lead to
"Allocation Stall" where threads must wait for GC to make room.
Monitoring metric: time between concurrent marking cycle starts.

---

**Q8 (correlation): How do you correlate GC pauses with application latency spikes?**

A: (1) Enable GC logging with millisecond timestamps. (2) Enable distributed
tracing with millisecond timestamps (OpenTelemetry, Zipkin, Jaeger). (3) When a
latency spike is reported: find the timestamp. (4) Check GC log at that time:
was there a GC pause? If GC pause matches latency spike (same timestamp, similar
duration): GC is the cause. If no GC: look elsewhere (network, database, thread
pool saturation).

```bash
# Find GC events at a specific time window:
# Latency spike at 2024-01-15 10:23:45
grep "10:23:4[0-9]" gc.log
# OR by uptime: latency spike at ~3600s JVM uptime:
awk '/^\[3[5-9][0-9][0-9]\.[0-9]+s\]/' gc.log
```

> **Code walkthrough:** This OR by uptime: latency spike at ~3600s JVM uptime: example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* The definitive correlation tool is JFR: it
records both JVM GC events and application thread activity in the same timeline.
In JMC: the "GC view" shows GC pauses overlaid with thread state changes.
During a GC pause: all threads show "GC" state in thread view. Requests running
during GC show as "stalled for 15ms in GC" in their flamegraph. This makes the
GC->latency causality unambiguous, without manual log correlation.

---

**Q9 (automatic analysis): What does a healthy GC log look like vs an unhealthy one?**

A:
```plaintext
HEALTHY patterns:
  - Minor GC every 5-60s (depends on allocation rate)
  - Minor GC pauses: < 50ms
  - Heap after GC: stable (no growing trend)
  - Concurrent marking every 15-30 min
  - Mixed GC occasionally after marking
  - No "Pause Full" events
  - GC overhead: < 3%

UNHEALTHY patterns (alarm):
  - "Pause Full" appearing: CRITICAL - investigate immediately
  - Minor GC every < 1s (very high allocation rate)
  - Heap after GC growing steadily: potential leak
  - Pause > 200ms for Minor GC: something wrong (large Young Gen, slow IO during GC)
  - Concurrent marking every < 2 min: Old Gen pressure
  - "to-space exhausted" or "evacuation failure": Survivor/Old Gen overflow
```

> **Code walkthrough:** This OR by uptime: latency spike at ~3600s JVM uptime: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* A subtle "healthy" indicator: the ratio of
(heap before GC - heap after GC) / (heap before GC - heap after last GC).
This is the Minor GC "collection efficiency." If it's consistent (e.g., always
reclaims 60-80% of Young Gen): GC is predictable. If it varies wildly: allocation
patterns are irregular (batch processing, scheduled jobs creating spikes). For
applications with scheduled batch jobs: GC behavior should be analyzed separately
during batch periods vs interactive periods - they have different allocation patterns
and may require different GC configurations.

---

### ⚖️ Comparison Table

| GC Log Indicator | Severity | Likely Cause | Action |
|---|---|---|---|
| Minor GC > 200ms | High | Large Young Gen, slow write barriers | Reduce Young Gen, profile write barriers |
| Heap after GC growing | High | Memory leak | Heap dump, Eclipse MAT analysis |
| Full GC appearing | Critical | Concurrent mark failing | Check allocation rate, increase IHOP |
| GC overhead > 5% | Medium | High alloc rate or undersized heap | Profile allocations, resize heap |
| Concurrent mark every < 2min | Medium | Old Gen pressure | Increase heap or reduce live set |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: GC log format described adequately in Concept Explanation)*

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



