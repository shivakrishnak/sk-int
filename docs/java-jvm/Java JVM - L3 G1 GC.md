---
layout: default
title: "Java JVM - L3 G1 GC"
parent: "Java JVM"
grand_parent: "SK Interview"
nav_order: 7
permalink: /java-jvm/l3-g1-gc/
render_with_liquid: false
---

# Java JVM - L3 G1 GC

## G1 GC Configuration and Region Selection

### 🎯 Model Answer

**30 seconds:**
> G1 (Garbage-First) GC splits the heap into 2048 equal-sized regions (1-32MB each)
> and dynamically assigns them as Eden, Survivor, Old, or Humongous. It targets
> a pause time goal (`-XX:MaxGCPauseMillis=200`). G1 prioritizes collecting regions
> with the most garbage (highest garbage density) to maximize collection efficiency
> per pause - hence "Garbage-First." G1 is the default GC since Java 9 and suits
> most production workloads.

**3 minutes (Senior):**
> G1 region mechanics:
> - Eden regions: new allocations (TLAB within each Eden region)
> - Survivor regions: Minor GC evacuation target
> - Old regions: promoted long-lived objects
> - Humongous regions: objects > 50% of region size (bypass Young Gen)
>
> Collection types:
> - Young-only GC: collects all Young Gen regions (always stop-the-world).
> - Concurrent Marking: background marking of Old Gen (mostly concurrent,
>   two brief STW phases: Initial Mark + Remark).
> - Mixed GC: Young Gen + highest-garbage Old Gen regions selected based on the
>   "predicted pause time" model.
>
> Region selection algorithm: G1 maintains a "predicted evacuation cost" per region
> based on observed live data ratio. For each Mixed GC: it selects as many Old Gen
> regions as possible while keeping the predicted pause under `MaxGCPauseMillis`.
> This is a "bin-packing" style selection: maximize garbage collected per pause budget.
>
> Key tuning flags: `G1HeapRegionSize` (auto-calculated, but can override),
> `G1MixedGCLiveThresholdPercent=85` (only reclaim regions with < 85% live data),
> `InitiatingHeapOccupancyPercent=45` (start concurrent marking at 45% heap full).

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "G1: heap = 2048 regions. Region types: Eden/Survivor/Old/Humongous.
Collection types: Young-only, Concurrent Mark, Mixed GC. Garbage-First = collect
highest-garbage regions first. Tuning: MaxGCPauseMillis, IHOP."

**(2) First principles:** "Traditional GC: fixed Young/Old split. G1: flexible regions
allow dynamic resizing of generational boundaries. Garbage-First: instead of sweeping
entire Old Gen, pick the profitable regions first."

**(3) Bridge:** "G1 regions are like a city with variable-density neighborhoods.
The GC crew (garbage collection) doesn't clean the whole city at once. They prioritize
the most littered neighborhoods (highest garbage density), cleaning those within
the time budget (MaxGCPauseMillis)."

---

### 📘 Concept Explanation

**G1 region types and selection:**
```
HEAP LAYOUT:
  Total heap split into ~2048 regions (1-32MB each, auto-sized)
  Region size = heap_size / 2048, rounded to power of 2
  Example: Xmx=8g -> 8192MB / 2048 = 4MB regions

REGION TYPES:
  Eden:     new allocations (created/destroyed each Minor GC)
  Survivor: Minor GC evacuation target (one "to" region set)
  Old:      promoted objects (collected during Mixed GC)
  Humongous: single large object spanning one or more consecutive regions
             > 50% of region size -> allocated in Humongous, counted as Old

YOUNG REGION COUNT:
  Dynamic: G1 adjusts how many regions are Eden
  Based on: past minor GC durations + MaxGCPauseMillis target
  More Eden regions -> longer Minor GC -> G1 reduces if over target
  Fewer Eden regions -> shorter Minor GC -> G1 increases for throughput

MIXED GC REGION SELECTION:
  After concurrent marking: each Old Gen region has "live bytes" count
  Selection criteria: live_bytes / region_size < G1MixedGCLiveThresholdPercent (85%)
  -> Only regions with < 85% live data are candidates (others: too expensive)
  Selection algorithm: sort candidates by garbage density (highest first)
  -> Select regions until: predicted_evacuation_time >= MaxGCPauseMillis * 0.8
  This is the "Garbage-First" selection
```

---

### 💻 Code Example

> **Code walkthrough:** G1 tuning is driven by GC log analysis, not guesswork.
> The key decision tree: observe allocation rate, check if pauses exceed target,
> identify the bottleneck (Young Gen too large, Old Gen pressure, Humongous objects),
> then adjust the specific flag.

```bash
# Enable detailed G1 logging:
-Xlog:gc*,gc+heap=debug,gc+ergo=debug:file=gc.log:time,uptime:filecount=5,filesize=20m

# G1-specific log messages:
# [gc+ergo] GC(5) Heap Regions: 50 Eden, 5 Survivor, 100 Old, 2 Humongous
# [gc+heap] GC(5) Eden: 200M->0B, Survivor: 10M->15M, Old: 500M->480M
# [gc+ergo] GC(5) To-Space Exhausted (not enough Survivor/Old space)
# [gc+ergo] Initiating concurrent GC (occupancy threshold exceeded)

# G1 region stats via jcmd:
jcmd <pid> GC.heap_info
# garbage-first heap  total 8192K, used 4096K
# region size 1024K, 4 young (4096K), 0 survivors, 0 humongous

# Typical G1 tuning decisions:
```

```java
// Checking G1 configuration programmatically:
GarbageCollectorMXBean g1Young = ManagementFactory
    .getGarbageCollectorMXBeans().stream()
    .filter(gc -> gc.getName().equals("G1 Young Generation"))
    .findFirst().orElseThrow();

GarbageCollectorMXBean g1Old = ManagementFactory
    .getGarbageCollectorMXBeans().stream()
    .filter(gc -> gc.getName().equals("G1 Old Generation"))
    .findFirst().orElseThrow();

// Monitor ratios:
long youngCount = g1Young.getCollectionCount();
long oldCount = g1Old.getCollectionCount();
long youngTime = g1Young.getCollectionTime();
long oldTime = g1Old.getCollectionTime();

System.out.printf("Young GC: %d collections, %dms total (avg %.1fms)%n",
    youngCount, youngTime, (double)youngTime/youngCount);
System.out.printf("Old GC:   %d collections, %dms total (avg %.1fms)%n",
    oldCount, oldTime, (double)oldTime/oldCount);

// Alert thresholds:
// Young avg > 100ms: Young Gen too large or write barrier overhead
// Old count > 2/hour: Old Gen pressure (potential leak or undersized heap)
// Old count = 0: no Mixed GC (may be fine or IHOP too high)
```

> **Code walkthrough:** The GarbageCollectorMXBean names for G1 are always
> "G1 Young Generation" (Minor GC) and "G1 Old Generation" (Mixed/Full GC).
> These names are JVM-version stable. Monitoring the ratio: a healthy service
> sees Old GC count growing slowly (1-2 per hour), Young GC count growing rapidly
> (many per hour). If Old GC frequency suddenly spikes: investigate for memory
> leaks or rapid Old Gen growth.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> G1 splits heap into regions, dynamically allocates them as Young or Old.
> Collects regions with most garbage first (Garbage-First). Set
> `MaxGCPauseMillis` for pause target. Default and appropriate for most services.

---

**Senior / Staff (5+ years):**
> G1 self-tunes within its model but has blind spots. Mixed GC may not keep up
> with allocation rate -> Old Gen grows -> Full GC fallback. Prevention: tune IHOP
> lower (start marking earlier), tune G1MixedGCCountTarget higher (more mixed GC
> cycles), or increase heap. G1's pause model: it predicts but doesn't guarantee
> `MaxGCPauseMillis`. During periods of high Old Gen reclamation (many live objects
> to evacuate): actual pause > target. The guarantee: G1 TRIES to stay under the
> target, but correctness wins over latency. For hard latency requirements (<5ms):
> G1 cannot deliver; use ZGC.

---

### ⚠️ Common Misconceptions

**Misconception 1: "G1 guarantees MaxGCPauseMillis will not be exceeded."**
`MaxGCPauseMillis` is a TARGET, not a guarantee. G1 adjusts its work to stay under
the target but cannot always succeed. High Old Gen pressure, large Humongous objects,
or to-space exhaustion can cause pauses longer than the target. G1 will try to stay
under but correctness takes priority over latency. ZGC is the only production GC with
a near-guarantee of sub-ms pauses.

**Misconception 2: "Increasing MaxGCPauseMillis improves throughput linearly."**
Increasing the pause target allows G1 to collect more regions per cycle (larger pause
= more work per pause = fewer pauses). But the relationship is not linear: diminishing
returns as pause target grows. Beyond a certain point: pause is bottlenecked by
evacuation cost (live objects in the selected regions), not region count. For
throughput workloads (no latency requirement): Parallel GC usually outperforms G1
regardless of MaxGCPauseMillis setting.

---

### 🚨 Failure Modes and Diagnosis

**Failure: G1 Mixed GC not reclaiming Old Gen - Old Gen fills despite GC.**
```
Symptom: Old Gen growing despite concurrent marking and Mixed GC cycles
  GC log: Concurrent Mark cycles every 30s but Old Gen still fills
  Eventually: Full GC triggered

Cause: G1MixedGCLiveThresholdPercent too high
  Old Gen regions are 80-90% live -> not selected for Mixed GC
  (threshold: only regions with < 85% live data are candidates)
  G1 marks them but won't collect them

Diagnosis:
  -Xlog:gc+ergo=debug
  Output:
    [gc+ergo] Not mixed GC candidate: region X (occupancy > threshold)
  Count how many candidates exist each cycle:
  grep "GC candidates" gc.log

Fix:
  Option A: Lower threshold to collect more-live regions
    -XX:G1MixedGCLiveThresholdPercent=65  (collect regions up to 65% live)
    Trade-off: evacuating 65% live objects = more work per cycle = longer pause
  
  Option B: Increase heap (more room before threshold hit)
    -Xmx larger
  
  Option C: Reduce live set (root cause: too many long-lived objects)
    Profile what's in Old Gen: jcmd GC.class_histogram
    Reduce cache sizes, fix memory leaks
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| G1 region types | 2 minutes |
| Garbage-First selection algorithm | 2 minutes |
| Young region count tuning | 2 minutes |
| Mixed GC phases | 2 minutes |
| IHOP threshold | 2 minutes |
| Humongous regions | 2 minutes |
| G1 fallback to Full GC | 2 minutes |
| G1 vs Parallel GC trade-off | 2 minutes |
| Remembered Sets in G1 | 2 minutes |

---

**Q1 (regions): How does G1 determine region size?**

A: G1 region size = total heap / 2048, rounded to the nearest power of 2 (1-32MB).
Example: 8GB heap -> 8192MB / 2048 = 4MB, rounded to 4MB. 32GB heap -> 16MB regions.
1GB heap -> 0.5MB, rounded to 1MB. Override: `-XX:G1HeapRegionSize=4m`. Larger region
size: fewer regions, lower Remembered Set overhead, but coarser heap management.
Smaller region size: more regions, finer allocation granularity, higher Remembered
Set memory overhead.

*What separates good from great:* Region size affects what qualifies as "Humongous."
An object is Humongous if > 50% of region size. For 4MB regions: objects > 2MB = Humongous.
For 16MB regions: objects > 8MB = Humongous. If your application creates 3MB byte arrays
frequently: with 4MB regions they're Humongous (bad, bypass Eden, cause Old Gen pressure);
with 8MB regions they're NOT Humongous (fine, allocated in Eden). Setting
`G1HeapRegionSize=8m` for applications with 3-7MB large allocations eliminates Humongous
allocation pressure. The trade-off: larger regions = higher minimum Young Gen overhead
(can't have a Young Gen smaller than one region).

---

**Q2 (garbage-first): Why is G1 called "Garbage-First"?**

A: G1 selects Old Gen regions for Mixed GC based on garbage density (highest garbage
first). After concurrent marking: each Old Gen region has a known "live objects ratio."
G1 sorts candidate regions by garbage ratio (1 - live_ratio). For each Mixed GC:
select regions with highest garbage density until the predicted pause budget is spent.
This maximizes garbage collected per pause, rather than collecting random regions.

*What separates good from great:* The "Garbage-First" strategy is provably optimal
for maximizing collection efficiency given a fixed pause time budget - it's a greedy
approximation of the knapsack problem. The "predicted pause" model accounts for:
region size, live object density (evacuation cost), Remembered Set scan time.
G1 builds this model from historical observations. The model is approximate: actual
pauses can be 2x the predicted value during unusual allocation patterns. When the
model systematically under-predicts: pauses exceed MaxGCPauseMillis and G1 reduces
the number of regions per cycle (over-correction) or adjusts its prediction model.

---

**Q3 (young sizing): How does G1 decide how many Young regions to use?**

A: G1 maintains a "target Eden pause time" based on `MaxGCPauseMillis`. After each
Minor GC: it measures actual pause time and compares to the target. If last pause
exceeded target: decrease Young region count (smaller Eden = fewer objects to evacuate
= faster pause). If last pause was well under target: increase Young region count
(larger Eden = more allocation before next GC = better throughput). This is the
"ergonomic Young Gen sizing" adaptive algorithm.

*What separates good from great:* The Young Gen size oscillates around a steady state.
In GC logs: Eden region count changes slightly each cycle - this is normal and correct.
You can pin the Young Gen size with `-XX:NewSize` and `-XX:MaxNewSize` (for Parallel GC)
or `-XX:G1NewSizePercent` / `-XX:G1MaxNewSizePercent` (for G1). Pinning Young Gen is
an advanced tuning step that prevents G1 from self-tuning. Before pinning: observe
G1's self-tuned behavior under production load for at least one day. If G1's self-tuned
Young Gen is stable: no action needed. If it oscillates wildly: pinning may help.

---

**Q4 (mixed GC count): What is G1MixedGCCountTarget?**

A: After one concurrent marking cycle, G1 distributes Old Gen reclamation across
`G1MixedGCCountTarget` Mixed GC cycles (default 8). Each Mixed GC: collect Young
Gen + (candidate_regions / CountTarget) Old Gen regions. Lower count target: more
Old Gen collected per cycle (longer pauses), fewer Mixed GC cycles. Higher count
target: less per cycle (shorter pauses), more cycles needed. Default is balanced.
G1 also stops mixed GC early if Old Gen occupancy drops below `G1HeapWastePercent=5%`.

*What separates good from great:* The "Heap Waste" threshold (5% by default) means
G1 stops Mixed GC when it's not "worth it" anymore. If Old Gen drops from 60% to 55%
occupied: G1 stops Mixed GC (5% waste threshold satisfied). The remaining 55% of Old Gen
will be collected in the next concurrent marking cycle when Old Gen grows again.
This prevents G1 from spending excessive time on diminishing returns. If your
application needs aggressive Old Gen reclamation (very tight memory): set
`G1HeapWastePercent=1` to continue collecting until Old Gen is nearly empty.
Trade-off: more Mixed GC cycles, more CPU for collection.

---

**Q5 (to-space exhausted): What causes "to-space exhausted" in G1?**

A: "To-space exhausted" (G1's version of "promotion failure") occurs when G1 cannot
find enough free regions to evacuate all live objects from the collected regions.
The Survivor and Old Gen regions that would receive the evacuated objects are full.
G1 must fall back to special handling: some objects are kept in-place (unsafe
evacuation). This triggers a Full GC to properly compact the heap.

```
Causes:
1. Old Gen occupancy too high when Minor GC runs
   -> Not enough free regions for evacuation target
2. Humongous allocation fails (no contiguous free regions)
3. Concurrent marking can't keep up (Old Gen fills before
   mixed GC starts)

Diagnosis:
grep "to-space exhausted\|Evacuation Failure\|G1 Evacuation Pause.*Humongous" gc.log

Fix:
1. Lower IHOP: -XX:InitiatingHeapOccupancyPercent=30
   Start concurrent marking earlier -> Old Gen less full when Minor GC runs
2. Increase heap: -Xmx (more free regions available)
3. Increase G1HeapRegionSize: makes Humongous threshold higher
4. Reduce Humongous allocations: profile with JFR, fix large allocations
```

*What separates good from great:* "To-space exhausted" during a Minor GC is the most
severe non-Full-GC event. Unlike a normal Minor GC: some objects are NOT evacuated
(kept in their original regions). The heap has mixed state (some collected, some not).
G1 must perform a Full GC immediately to resolve this inconsistency. This is why
"to-space exhausted" in GC logs is always followed by "Pause Full" a few milliseconds
later. The window between them: the application is still paused (the original Minor
GC pause extends into the Full GC).

---

**Q6 (IHOP): What is IHOP and how do you tune it?**

A: IHOP (Initiating Heap Occupancy Percent, default 45%) = heap occupancy
threshold that triggers G1's concurrent marking cycle. When heap reaches 45%
occupancy: G1 starts concurrent marking in the background. Purpose: ensure concurrent
marking completes before Old Gen fills, enabling Mixed GC before Full GC is needed.
Tune lower (30-40%): starts marking earlier, more headroom, better protection against
Full GC. Tune higher (50-60%): less frequent marking, lower CPU overhead.

*What separates good from great:* Adaptive IHOP (Java 9+, default enabled) automatically
adjusts the threshold based on measured allocation rate and concurrent marking duration.
The JVM learns: "at current 500MB/s allocation rate, concurrent marking takes 3 seconds,
so start marking when the heap has at least 3 * 500MB = 1.5GB headroom." This eliminates
the need for manual IHOP tuning in most cases. Manual IHOP tuning is only needed when:
(1) adaptive IHOP is disabled, (2) workload has extreme variability (IHOP adapts too slowly
for sudden load spikes), or (3) containers with strict memory limits where adaptive IHOP
starts marking too late. Monitor: if you see Full GC, lower IHOP; if you see constant
concurrent marking with healthy heap, raise IHOP.

---

**Q7 (G1 vs others): When should you switch from G1 to ZGC?**

A: Switch to ZGC when: (1) GC pause P99 > 50ms and latency SLA is < 100ms,
(2) application runs at large heap (>16GB) and G1's concurrent marking can't keep
up with allocation rate, (3) application has latency-critical paths (payment processing,
real-time APIs) where any GC pause is unacceptable.
Stay with G1 when: heap < 16GB, latency requirement > 100ms, or memory efficiency
is important (ZGC uses more memory for colored pointers and mapping).

*What separates good from great:* The overhead cost of switching to ZGC: ZGC's load
barriers on every object reference read add ~3% CPU overhead. For a 32-core box: 1 core
is now "consumed" by ZGC load barriers. For a 4-core container: 3% of all 4 cores.
G1's write barriers are cheaper (only reference writes, not reads). CPU-bound applications
may see overall throughput DECREASE with ZGC despite better pause times. The right comparison:
benchmark G1 vs ZGC under production-like CPU-contented load, measuring total throughput
(requests/second) + P99 latency. Often: G1 wins on throughput, ZGC wins on latency P99.
The trade-off is business-driven: does your SLA demand < 10ms P99, or is throughput more important?

---

**Q8 (Remembered Sets): How does G1 maintain Remembered Sets?**

A: Each G1 region has a Remembered Set (RS) tracking incoming references from OTHER
regions. When application code writes `a.field = b` (cross-region reference): write barrier
code is invoked, records `a`'s card (256-byte block) in `b`'s RS dirty card queue.
A refine thread processes the queue, updating `b`'s RS. During GC: when collecting region X,
G1 scans X's RS to find all incoming references -> can determine what's live in X
without scanning the entire heap.

*What separates good from great:* RS maintenance has a variable cost. For applications
with many cross-region references: RS update queue grows, refine threads consume CPU,
RS scan during GC is expensive. Monitoring: `-Xlog:gc+remset=trace` shows RS statistics.
If RS is large and expensive: consider reducing cross-region reference density by
allocating related objects in the same region (not directly controllable in Java, but
reducing large interconnected caches helps). High RS overhead is visible as: long
"Update RS" and "Scan RS" phases in GC log (`-Xlog:gc+phases=debug`).

---

**Q9 (string dedup): What is String Deduplication in G1?**

A: `-XX:+UseStringDeduplication` (G1 only): the GC identifies String objects with
identical content (different objects, same char[] value) and makes them share the
same backing byte[]. Identifies duplicate strings during concurrent marking.
Memory savings: depends on application, typically 5-25% for String-heavy applications
(web services with repetitive HTTP header strings, database queries, etc.).
Overhead: ~2-5% GC overhead for the deduplication scan.

*What separates good from great:* String Deduplication is most effective for:
application servers processing HTTP requests (same header keys/values repeated),
data pipelines processing repetitive field names, and cached query results.
Less effective for: applications with mostly unique strings (UUIDs, user-generated content),
already using `String.intern()` (manual deduplication). Measuring effectiveness:
JMX `StringDeduplication` MBean: shows how many strings were deduplicated and bytes
saved. If savings < 10MB: overhead not worth it. If savings > 100MB for a 1GB heap:
enable it.

---

### ⚖️ Comparison Table

| G1 GC Event | Frequency | Typical Pause | Scope | Trigger |
|---|---|---|---|---|
| Minor GC (Young-only) | High (every 5-60s) | 5-50ms | Young regions | Eden full |
| Concurrent Mark | Low (every 15-30min) | 1ms (initial) + 5ms (remark) | Old Gen analysis | IHOP threshold |
| Mixed GC | Medium (8 cycles after mark) | 10-50ms | Young + Old regions | After marking |
| Full GC | Rare (ALARM) | Seconds | Entire heap | Concurrent mark fails |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: G1 regions described adequately in Concept Explanation)*

---

---

## GC Pause Analysis and Tuning

### 🎯 Model Answer

**30 seconds:**
> GC pause analysis starts with GC logs: identify which GC phase causes the
> long pause, then tune the specific bottleneck. Key phases in a G1 Minor GC
> pause: root scanning, Remembered Set update, evacuation (copy live objects),
> reference processing. Long reference processing is the most common unexpected
> pause contributor. After analysis: tune MaxGCPauseMillis, heap size, or switch
> GC algorithm based on findings.

**3 minutes (Senior):**
> G1 pause breakdown (from `-Xlog:gc+phases=debug`):
> ```
> Pause Young (Normal)
>   Pre Evacuate Collection Set: 0.1ms    <- RS update work
>   Evacuate Collection Set:     7.5ms    <- Copy live objects (main work)
>   Post Evacuate Collection Set: 1.2ms  <- Reference processing, clear cards
>   Other:                         0.2ms
>   Total:                         9.0ms
> ```
> 
> Phase bottlenecks:
> - "Evacuate Collection Set" high: too many live Young Gen objects to copy
>   (large Eden + low death rate)
> - "Reference Processing" high: many SoftReference/WeakReference/Finalizers
>   (common in frameworks with many listeners, event buses)
> - "Update Remembered Sets" high: many cross-region references (interconnected
>   object graph)
> - "Scan Root Regions" high: large thread stacks or many loaded classes
>
> G1 parallel phases: most evacuation phases use multiple GC threads (`-XX:ParallelGCThreads`,
> default = min(8, n_cpus/2)). More threads: faster per-phase, but more CPU.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "GC pause analysis: read GC phases log, find bottleneck phase.
Main phases: root scanning, RS update, evacuation, reference processing. Each phase
has a specific tuning lever."

**(2) First principles:** "A GC pause has multiple sub-phases. Each phase does a
specific job. Total pause = sum of phases. To reduce total pause: identify which
phase takes the most time and tune that specific phase."

**(3) Bridge:** "GC pause analysis is like a project post-mortem breakdown.
A project (GC pause) takes 50ms. Breaking it down: planning=5ms, execution=35ms,
reporting=10ms. Execution is the bottleneck -> optimize the execution phase."

---

### 📘 Concept Explanation

**G1 pause phase breakdown:**
```
G1 MINOR GC PHASES (stop-the-world):

1. Pre-Evacuate Collection Set:
   - Choose Collection Set: which Young regions to collect (all Young)
   - Update Remembered Sets: finalize RS dirty card queue
   - Drain RS Update Buffers: process pending RS updates

2. Evacuate Collection Set (main work):
   - Root Scan: scan thread stacks, static fields, JNI
   - Update RS: process updated cards for collected regions
   - Scan RS: scan Remembered Sets of collected regions
   - Object Copy: copy live objects to Survivor/Old
   - Termination: work stealing, all GC threads sync

3. Post-Evacuate Collection Set:
   - Reference Processing: soft/weak/phantom refs, finalizers
   - Redirty Cards: mark cards that still have cross-region refs
   - Free Collection Set: reclaim empty regions
   - Clear Claimed Marks

4. Other:
   - Miscellaneous bookkeeping

GC PARALLEL THREADS:
  -XX:ParallelGCThreads=N  (STW GC threads, default min(8, n_cpus/2))
  -XX:ConcGCThreads=N      (Concurrent marking threads, default n_cpus/4)
```

---

### 💻 Code Example

> **Code walkthrough:** The phase debug output reveals the exact breakdown.
> Reference processing time > 2ms is a common unexpected bottleneck that
> frameworks introduce through heavy use of WeakReferences and ReferenceQueues.

```bash
# Enable phase-level GC logging:
-Xlog:gc+phases=debug:file=gc.log:time,uptime

# Sample output (Minor GC breakdown):
# [gc+phases] GC(5) Pause Young (Normal) (G1 Evacuation Pause) 8.123ms
# [gc+phases] GC(5)   Pre Evacuate Collection Set: 0.234ms
# [gc+phases] GC(5)   Evacuate Collection Set: 6.543ms
# [gc+phases] GC(5)     Root Scan: 0.890ms
# [gc+phases] GC(5)     Update RS: 0.456ms
# [gc+phases] GC(5)     Scan RS: 0.234ms
# [gc+phases] GC(5)     Code Root Scan: 0.012ms
# [gc+phases] GC(5)     Object Copy: 4.951ms  <- main work
# [gc+phases] GC(5)     Termination: 0.000ms
# [gc+phases] GC(5)   Post Evacuate Collection Set: 1.123ms
# [gc+phases] GC(5)     Reference Processing: 0.567ms  <- check this
# [gc+phases] GC(5)     Redirty Cards: 0.456ms
# [gc+phases] GC(5)     Free Collection Set: 0.100ms

# Analyzing Reference Processing overhead:
grep "Reference Processing" gc.log | awk '{sum += $NF} END {print "Total: " sum}'
# If Reference Processing > 20% of total pause: too many reference objects

# Root Scan high: many GC roots
# Object Copy high: too many live young objects (reduce Eden size or increase
#                   death rate)
# Update RS high: many cross-region writes (reduce object interconnectedness)
```

```java
// Finding Reference processing overhead cause:
// High "Reference Processing" in GC phases:
// Cause 1: too many WeakReferences (WeakHashMap, intern caches)
//   Check: jcmd <pid> GC.class_histogram | grep Reference
//   If many java.lang.ref.WeakReference: reduce their use

// Cause 2: Finalizers (deprecated but still in some libraries)
//   Check: jcmd <pid> GC.class_histogram | grep Finalizer
//   "java.lang.ref.Finalizer" count growing: finalizer backlog

// Cause 3: PhantomReferences (Cleaner API)
//   Usually not a problem unless very many Cleaner objects

// Monitoring reference queue lengths (JMX):
ManagementFactory.getMemoryPoolMXBeans().stream()
    .filter(p -> p.getName().contains("Survivor"))
    .forEach(p -> System.out.println(p.getName() + ": " + p.getUsage()));
```

> **Code walkthrough:** High Reference Processing time in GC phases is a
> common surprise for teams that haven't profiled their GC pause breakdown.
> A Spring application using event buses with WeakHashMap-backed listener
> registries, combined with many cache entries using SoftReferences, can
> generate thousands of reference objects that all need processing during GC.
> Fix: reduce WeakHashMap usage in hot paths, prefer Caffeine's explicit
> LRU/LFU cache over SoftReference-based caches.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> GC pause = multiple phases. Enable gc+phases logging to see the breakdown.
> Find which phase dominates. Common: "Object Copy" (live objects to evacuate),
> "Reference Processing" (soft/weak refs). Tune based on findings.

---

**Senior / Staff (5+ years):**
> Systematic GC pause reduction: (1) check GC log for phase breakdown, (2) if
> "Object Copy" dominates: reduce Eden to reduce Young Gen live set, or accept the
> cost and tune MaxGCPauseMillis. (3) If "Reference Processing" dominates: audit
> framework reference usage, consider `ParallelRefProcEnabled=true` (parallelize
> reference processing). (4) If "Update RS" or "Scan RS" dominates: reduce cross-region
> reference density. (5) If phases look fine but total pause is high: check for Remark
> safepoint delay (threads slow to reach safepoint).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Reducing MaxGCPauseMillis always reduces observed pauses."**
MaxGCPauseMillis is a target that G1 adapts to by reducing work per pause cycle.
If the work per cycle was already at the minimum: reducing MaxGCPauseMillis just
causes G1 to run more frequent, smaller GC cycles (same total pause time, more
context switches). Worse: if the work per cycle can't be reduced below MaxGCPauseMillis
(e.g., root scanning alone takes 10ms): lowering the target to 5ms is ignored by G1.
G1 always does the minimum required work per cycle - it cannot go below that floor.

**Misconception 2: "ParallelGCThreads = n_cpus always gives best performance."**
More GC threads reduce pause duration but increase CPU contention. On a 2-core
container, 4 GC threads compete for 2 CPUs: some threads spin waiting for CPU,
increasing latency variance. Optimal threads: match available CPUs at GC time.
For containers: `ParallelGCThreads = min(n_vcpus, default)`. Kubernetes CPU throttling
means cgroups limit the effective CPU - set ParallelGCThreads <= CPU limit / 1.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Safepoint delay inflates GC pause beyond the actual GC work time.**
```
Symptom: GC log shows 100ms pause, but gc+phases shows only 10ms of GC work
  GC pause = safepoint reach time + actual GC work time
  If reach time >> work time: application threads slow to safepoint

Diagnosis:
  Enable safepoint logging:
  -Xlog:safepoint:file=safepoint.log:time,uptime
  Output:
  [safepoint] Application time: 0.5000000 seconds
  [safepoint] Entering safepoint region: GenCollect
  [safepoint] Safepoint sync time: 0.0950000 seconds  <- 95ms reach time!
  [safepoint] Total time for which application threads were stopped: 0.1050000 seconds

Cause: Some threads are slow to reach safepoints
  JIT-compiled loop without safepoint poll (happens in counted loops)
  JNI frames (native code must return before safepoint)
  Large method bodies

Fix:
  1. For JIT loops: -XX:UseCountedLoopSafepoints
     Adds safepoint polls at loop back-edges (small overhead)
  2. For JNI: reduce JNI call duration
  3. For large methods: JIT usually handles safepoints in method calls
     If not: break large methods into smaller ones
  4. JDK 16+: improved safepoint handling by default
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| G1 pause phases | 2 minutes |
| Object Copy phase bottleneck | 2 minutes |
| Reference Processing overhead | 2 minutes |
| Safepoint delay | 2 minutes |
| ParallelGCThreads tuning | 2 minutes |
| GC ergonomics | 2 minutes |
| Evacuation failure in pauses | 2 minutes |
| Concurrent marking pause contributions | 2 minutes |
| MaxGCPauseMillis limitations | 2 minutes |

---

**Q1 (phases): What are the main phases of a G1 Minor GC pause?**

A: Pre-Evacuation (RS update finalization), Evacuation (main work: root scan, RS scan,
object copy), Post-Evacuation (reference processing, card cleaning). The evacuation
phase dominates: it's the actual copying of live objects. Within evacuation: "Object Copy"
is usually the largest sub-phase. After copying: young region memory is immediately
reclaimed (pointers reset).

*What separates good from great:* The parallel execution model of G1 evacuation:
multiple GC threads (`ParallelGCThreads`) work in parallel on different parts of the
Young Gen. Work stealing: when a thread finishes its allocated regions, it "steals"
work from other threads. The "Termination" phase in GC logs represents: threads trying
to steal work and finding none, then synchronizing. Long Termination time = poor load
balancing among GC threads. Cause: some regions have much more live data than others
(one thread does heavy work while others wait).

---

**Q2 (reference proc): Why is Reference Processing sometimes a GC pause bottleneck?**

A: Reference Processing phase handles: SoftReference (check if should be cleared),
WeakReference (clear if referent GC'd), PhantomReference (enqueue), Finalizers (enqueue).
If the application has thousands of references: processing each one is a sequential
O(n) operation in the pause. Frameworks that overuse WeakHashMap (e.g., intern caches,
event registries) or that use Finalizers (legacy code) can cause 10-50ms of reference
processing in each GC pause.

*What separates good from great:* Reference processing can be parallelized:
`-XX:+ParallelRefProcEnabled` enables multi-threaded reference processing (default: off
in some versions, on in others - check with `VM.flags`). This reduces reference processing
from O(n)/1_thread to O(n)/N_threads. If reference processing is 30% of pause time:
parallelizing can reduce it to 5-10% (for 4 threads). The fundamental fix: reduce
reference object count. Profile: `jcmd GC.class_histogram | grep -i reference` shows
count and total size of reference objects. If > 100K WeakReferences: investigate
what's creating them.

---

**Q3 (safepoint): How does safepoint delay affect GC pause time?**

A: The JVM must bring all application threads to a "safepoint" before starting STW
GC phases. A safepoint is a point in bytecode execution where thread state is consistent
and can be recorded for GC. All threads must reach a safepoint; the GC cannot start
until ALL threads are stopped. If one thread is slow to reach a safepoint (e.g., running
a tight JIT-compiled loop without a poll): the entire GC waits. "Safepoint latency"
= time from GC trigger to all threads stopped. This time is NOT included in the
GC "work" phases but IS included in the total pause.

*What separates good from great:* Safepoint delay diagnosis requires `-Xlog:safepoint`
logging. The "Safepoint sync time" (also called "time to safepoint") is the delay.
Long sync time (> 10ms) with identified cause: a JIT-compiled counted loop
(for-loop with integer index, no safepoint poll). Fix: `-XX:+UseCountedLoopSafepoints`
adds safepoint checks in counted loops (small overhead, ~1-2%). JDK 16+ improved
safepoint polling using thread-local polling pages, reducing overhead of safepoint
checks. For JNI-heavy code: JNI frames at a safepoint must return from native code
first - if a JNI call takes 50ms, that 50ms is safepoint delay.

---

**Q4 (remark): What happens during the G1 Remark phase?**

A: Remark (stop-the-world, ~5ms) is the final phase of G1 concurrent marking.
It processes the SATB (Snapshot-At-The-Beginning) buffer queues: all reference
changes that occurred DURING concurrent marking are recorded in SATB buffers.
Remark traverses these buffers to ensure any objects referenced by the pre-change
values are marked as live. Without Remark: objects that were "moved" (dereferenced
and re-referenced) during marking might be incorrectly considered dead.

*What separates good from great:* Remark duration depends on SATB buffer size.
SATB buffers accumulate during concurrent marking. If concurrent marking is slow
(long duration due to large Old Gen): more SATB buffers accumulate (more reference
changes happened during the longer marking period). Remark processes all accumulated
buffers. A large Remark pause (> 20ms) indicates: (1) concurrent marking is slow
(too many objects to mark), (2) application has high mutation rate (many reference
changes per second). The G1 Remark safepoint is relatively short compared to Parallel
GC's single STW full marking phase - this is G1's key advantage.

---

**Q5 (cleanup): What does the G1 Cleanup phase do?**

A: Cleanup (stop-the-world, ~1ms) runs after Remark. It: (1) identifies completely
empty regions (no live objects) -> immediately reclaim these regions (no evacuation
needed, just reset pointers); (2) identifies which regions are candidates for
Mixed GC (based on live data ratio); (3) resets region state for next marking cycle.
Then: concurrent cleanup phase (not STW) performs the actual reclamation of empty
regions and RS updates.

*What separates good from great:* The concurrent cleanup is where G1 reclaims
empty regions in the background. If many regions become empty after Mixed GC:
concurrent cleanup frees them for new allocations. This is why heap usage drops
after Mixed GC in the GC log: empty Old Gen regions reclaimed during concurrent
cleanup. The "Concurrent Cleanup" phase doesn't require a STW pause - it's one
of G1's advantages over Parallel GC where cleanup requires full STW compaction.

---

**Q6 (tuning order): What is the correct order for tuning G1?**

A: (1) Set `MaxGCPauseMillis` based on latency requirement. (2) Ensure heap is
adequately sized (live_set * 3x minimum). (3) Check GC logs for Full GC ->
lower IHOP if occurring. (4) Check for Humongous allocations -> increase region size
or fix large allocations. (5) Check phase breakdown -> if reference processing high:
reduce WeakReference usage; if object copy high: reduce promotion rate (more Survivor
space). (6) Check Remembered Set overhead -> if high: reduce cross-region references.
(7) Consider ZGC if G1 cannot meet latency requirements despite tuning.

*What separates good from great:* The "golden path" of G1 self-tuning: for most
applications, setting `MaxGCPauseMillis` and `MaxRAMPercentage` is sufficient. G1's
ergonomics handle the rest. The cases where manual tuning is needed: (1) unusual
workloads (batch + interactive mixed), (2) extreme latency requirements (<50ms P99),
(3) Humongous allocation anti-patterns, (4) specific framework interactions (heavy
reference processing). Before tuning any specific flag: establish a baseline with GC
log analysis. Measure the current P99 pause, identify which phase dominates, then tune
that phase. Blindly tuning multiple flags simultaneously: unpredictable results.

---

**Q7 (concurrent threads): What does ConcGCThreads control?**

A: `ConcGCThreads` = number of threads for G1's concurrent phases (marking, RS refinement).
Default: `max(1, n_cpus/4)`. These threads run concurrently with the application,
consuming CPU. More threads: faster concurrent marking (completes sooner, more headroom
before Old Gen fills). More CPU used during concurrent phases: application throughput
may decrease slightly (competing for CPU).

*What separates good from great:* On CPU-constrained containers (e.g., 2 vCPU):
default `ConcGCThreads=1` may not complete marking fast enough. The marking "falls behind"
allocation rate -> heap fills -> Full GC. Fix: if container allows bursting above the
limit: fine. If CPU is strictly limited: can't easily solve with `ConcGCThreads` (already
at max). Alternative: larger heap (more time for marking before filling) or ZGC
(more efficient marking algorithm). The RS refinement threads are separate from marking
threads (GCRefineThread). High RS refinement workload + insufficient refinement threads:
RS dirty card queue grows, application threads process the queue themselves -> application
CPU used for GC work = throughput degradation.

---

**Q8 (pause model): How does G1's pause time model predict evacuation cost?**

A: G1 maintains a prediction model based on observed measurements: (1) scan rate
for Remembered Set processing (bytes/ms), (2) object copy rate for evacuation (bytes/ms),
(3) constant overhead per region. For each GC cycle: model predicts time to collect
each candidate region. G1 selects regions whose combined predicted time fits within
`MaxGCPauseMillis * 0.8` (80% of budget, leaving headroom for unexpected work).

*What separates good from great:* The model uses exponential weighted moving average
(EWMA) of past observations - recent observations weighted more heavily. This means
the model adapts to workload changes but has inertia: a sudden workload change (batch
job starts, allocation rate doubles) causes model under-prediction for a few GC cycles.
During the adaptation period: actual pauses exceed predicted pauses. This is why
"steady state performance" for G1 is better than "variable workload performance."
For applications with predictable load patterns: G1's prediction accuracy is high.
For applications with sudden load changes (traffic spikes, scheduled batch): G1 may
temporarily exceed MaxGCPauseMillis during adaptation.

---

**Q9 (benchmarking): How do you correctly benchmark GC-impacted performance?**

A: (1) Include warm-up: run the workload for 5-10 minutes before measuring.
(2) Run for 30+ minutes: capture multiple GC cycles including concurrent marking.
(3) Measure P50, P95, P99, P999 latency - not just average (average hides GC pauses).
(4) Record GC overhead: `total_gc_time / total_run_time` should be < 3%.
(5) Compare: same workload, different JVM configs, same duration.
(6) Use JFR or async-profiler for CPU profile + GC event correlation.

*What separates good from great:* The "hiccup" metric is the most relevant benchmark
metric for GC-impacted applications. Hiccup = the maximum observed pause at any time
scale (1ms, 10ms, 1s intervals). Tools: `jHiccup` (open source) measures application
hiccups in a background thread. A G1-tuned application might have P99 latency of 50ms
(GC pauses contributing 40ms) but P999 = 300ms (a concurrent marking remark phase).
jHiccup captures both. Comparing jHiccup results for G1 vs ZGC: immediately shows
whether the latency tail is acceptable for the SLA.

---

### ⚖️ Comparison Table

| GC Phase | Duration Range | Main Bottleneck | Tuning Lever |
|---|---|---|---|
| Root Scan | 0.5-5ms | Large thread stacks, many loaded classes | Reduce threads, unload classes |
| Object Copy | 2-30ms | Many live Young Gen objects | Reduce Eden size, increase death rate |
| Reference Processing | 0.1-30ms | Many WeakRef/SoftRef/Finalizers | Reduce reference usage, ParallelRefProcEnabled |
| Update/Scan RS | 0.1-10ms | Many cross-region references | Reduce object interconnectedness |
| Remark | 1-20ms | Large SATB buffer, slow marking | Increase ConcGCThreads |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: GC pause phases described adequately in Concept Explanation)*
