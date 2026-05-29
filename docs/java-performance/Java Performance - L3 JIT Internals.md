---
layout: default
title: "Java Performance - L3 JIT Internals"
parent: "Java Performance"
grand_parent: "SK Interview"
nav_order: 7
permalink: /java-performance/l3-jit-internals/
---

# Java Performance - L3 JIT Internals

## JIT Compilation and Escape Analysis: Deep Dive

### 🎯 Model Answer

**30 seconds:**
> JIT optimization stack: inlining -> escape analysis -> scalar replacement -> constant folding ->
> dead code elimination. The chain: inlining makes more code visible to C2, enabling escape analysis
> (local object -> stack), enabling scalar replacement (object fields -> registers). Result: zero
> heap allocation for short-lived local objects in hot paths.

**3 minutes (Senior):**
> How JIT optimizations compound:
>
> 1. **Inlining (the foundation)**: C2 replaces call sites with the callee's body. Now C2 sees
>    both caller and callee as one unit. Can prove properties that were opaque across method
>    boundaries. A method A calling B: does B's argument escape? Without inlining: C2 can't
>    know (B is a black box). With inlining: C2 sees B's body and knows the argument doesn't
>    escape.
>
> 2. **Escape analysis after inlining**: with B inlined into A, C2 now sees that the object
>    created in A and passed to B is only read, never stored. C2 marks it as "no-escape" ->
>    eligible for scalar replacement.
>
> 3. **Scalar replacement**: decompose the object into its constituent fields. If `Point(x, y)`:
>    two local variables `x` and `y`. These can be placed in CPU registers. No heap allocation,
>    no GC reference tracking.
>
> 4. **Loop optimizations (C2 specialty)**:
>    - Loop unrolling: expand 4 iterations inline (reduces loop overhead by 4x).
>    - Loop vectorization: use SIMD CPU instructions (SSE2/AVX) to process 4-8 values per instruction.
>    - Loop invariant hoisting: computations that don't change per iteration moved out of the loop.

**Blank Mind Recovery:**

**(1) Restate:** "JIT optimization chain: inlining -> escape analysis -> scalar replacement -> register allocation. Inlining enables escape analysis (can see across method boundaries). Scalar replacement: object fields become local variables/registers. Result: zero heap allocation for short-lived local objects."

**(2) First principles:** "C2's goal: produce native code as fast as compiled C++. Techniques: eliminate abstractions (inlining collapses call overhead), eliminate allocations (escape analysis + scalar replacement), eliminate memory access (register allocation puts hot values in CPU registers)."

**(3) Bridge:** "JIT optimization is like a supply chain optimizer. Inlining: merge separate warehouses into one facility so you can optimize across them. Escape analysis: identify which inventory never leaves the facility. Scalar replacement: convert that inventory from boxes (heap objects) to shelves (register variables) for instant access."

---

### 📘 Concept Explanation

**C2 optimization pipeline and interaction effects:**
```
INLINING PREREQUISITES:

  Method eligible for inlining if:
    Size < MaxInlineSize (default: 35 bytecodes)
    Virtual call: resolved to single implementation (monomorphic/bimorphic)
    Not too deep in call stack (MaxInlineLevel = 9 default)
    Not a native method
  
  Virtual call inline cache:
    Monomorphic: one implementation -> inline directly (fastest)
    Bimorphic: two implementations -> inline both with branch
    Megamorphic: > 2 implementations -> fall back to vtable dispatch
    (C2 gives up inlining megamorphic calls)
  
  Consequence for design:
    Interface with many implementations: megamorphic dispatch everywhere
    Specific interface called with 1-2 implementations per call site: inline
    
    EXAMPLE:
      Comparable<String>: always called with String -> monomorphic -> inline
      Collection.size(): called with ArrayList, HashSet, LinkedList (3+ types)
      at the same call site -> megamorphic -> no inline
    
    DESIGN IMPLICATION: avoid polymorphic dispatch in inner loops.
    Use the concrete type where performance-critical.

ESCAPE ANALYSIS: DETAILED RULES:

  An object ESCAPES if:
    1. Assigned to a field of an object (that may be accessible externally)
    2. Returned from the current method
    3. Passed to a native method
    4. Passed to a method that C2 didn't inline (can't see its behavior)
    5. Accessed from multiple threads (may escape via race)
  
  An object DOES NOT ESCAPE if:
    1. Used only within the current method
    2. Passed only to inlined methods that don't escape it
    3. Not accessed from other threads
  
  RESULT of no-escape:
    "Stack allocation": object fields on the stack (fast)
    "Scalar replacement": fields as separate local variables (can be in registers)
    Neither object's class metadata nor its reference is tracked by GC
    ZERO GC overhead for this object

SCALAR REPLACEMENT IN DETAIL:

  Before scalar replacement:
    Point p = new Point(3, 4);
    // JVM: allocate 16 bytes on heap, write x=3, y=4
    double dist = Math.sqrt(p.x * p.x + p.y * p.y);
    // JVM: read p.x (memory access), read p.y (memory access)
    // p is no longer needed
    // GC: must eventually collect the Point object
  
  After scalar replacement (C2 applies to local, non-escaping objects):
    int x = 3, y = 4;  // no object, just local vars
    double dist = Math.sqrt(x * x + y * y);
    // C2: x and y may be in CPU registers (no memory access at all!)
    // No heap allocation, no GC, no memory reads: all in registers
  
  Verification:
    JMH with -prof gc:
      Before: gc.alloc.rate.norm = 32 B/op (Point = 16B, overhead = 16B)
      After: gc.alloc.rate.norm = 0 B/op  (scalar replacement worked!)

LOOP OPTIMIZATIONS:

  Loop unrolling:
    Source: for (int i = 0; i < 100; i++) { sum += a[i]; }
    Unrolled (x4):
      for (int i = 0; i < 100; i += 4) {
          sum += a[i] + a[i+1] + a[i+2] + a[i+3];
      }
    Benefit: reduces loop overhead (4 increments + 4 condition checks -> 1 each)
    
  SIMD vectorization:
    Source: for (int i = 0; i < 8; i++) { c[i] = a[i] + b[i]; }
    C2 with AVX2: processes 8 ints simultaneously in one CPU instruction
    Source code: 8 additions. Generated code: 1 SIMD instruction.
    Requires: arrays of primitives (int[], float[], double[])
    Works for: simple arithmetic (add, multiply, compare, min, max)
    Doesn't work for: complex control flow within the loop
    
  Loop invariant hoisting:
    Source: for (int i = 0; i < list.size(); i++) { process(list.get(i)); }
    C2: hoists list.size() out of loop (if list doesn't change):
    int size = list.size();
    for (int i = 0; i < size; i++) { process(list.get(i)); }
    Result: list.size() called once instead of N times.
    MANUAL hoist if C2 can't prove list doesn't change (safer than relying on JIT)

WHEN C2 FAILS TO OPTIMIZE:

  Failure 1: Method too large to inline (> 325 bytecodes):
    Lambda or method containing complex logic.
    Result: the boundary between caller and callee is opaque.
    Escape analysis can't see across. Objects escape.
    Fix: break the method into smaller pieces (< 35 bytecodes for reliable inlining).
    
  Failure 2: Megamorphic virtual call:
    More than 2 concrete types at the same call site.
    C2 can't inline any of them -> vtable dispatch.
    Fix: avoid polymorphic dispatch in hot loops. Use type-specific code paths.
    
  Failure 3: Synchronized on local object:
    synchronized (localObj) { ... }
    C2 with escape analysis can ELIMINATE the lock (object doesn't escape,
    so no other thread can see it, so the lock is unnecessary).
    But: only if C2 can prove no escape. If the object escapes (even via
    reflection): lock elimination doesn't apply.
    
  Failure 4: Object escapes via lambda capture:
    Point p = new Point(x, y);
    list.stream().map(e -> compute(p, e))...  // p captured in lambda
    The lambda captures p -> p may escape via the lambda -> no scalar replacement.
    Fix: extract values before the lambda:
    int px = p.x, py = p.y;  // primitives don't "escape" in the heap sense
    list.stream().map(e -> compute(px, py, e))...
```

---

### 💻 Code Example

> **Code walkthrough:** The series of examples shows how to write code that enables C2's
> optimization chain. The canonical escape analysis example and the Lambda capture fix
> show concrete patterns with JMH-verifiable allocation reductions.

```java
// ENABLING ESCAPE ANALYSIS AND SCALAR REPLACEMENT:

// BAD: object escapes via field assignment (no scalar replacement):
class OrderProcessor {
    private Point lastPosition;  // field: escape via assignment
    
    void process(int x, int y) {
        lastPosition = new Point(x, y);  // Point ESCAPES to field
        // C2 cannot apply scalar replacement: Point must be heap-allocated
        doWork(lastPosition);
    }
}

// GOOD: object is local, doesn't escape (scalar replacement applies):
class OrderProcessor {
    
    void process(int x, int y) {
        Point p = new Point(x, y);  // p is LOCAL
        doWork(p);  // passed to doWork, but if doWork is inlined...
        // and doWork doesn't store p anywhere...
        // -> p does NOT escape -> scalar replacement -> no allocation
    }
    
    // For scalar replacement to work, doWork must be:
    //   (a) inlined by C2 (< 35 bytecodes), AND
    //   (b) not store 'p' anywhere
    private void doWork(Point p) {  // small method -> likely inlined
        double dist = Math.sqrt(p.x * p.x + p.y * p.y);
        log.debug("Distance: {}", dist);
        // p is never stored -> p does not escape via doWork
    }
}

// LAMBDA CAPTURE FIX (prevent escape via capture):

// BAD: Point captured in lambda (may escape via closure):
List<Double> computeDistances(List<Point> targets, Point origin) {
    return targets.stream()
        .map(t -> {
            double dx = t.x - origin.x;  // origin captured in lambda
            double dy = t.y - origin.y;
            return Math.sqrt(dx*dx + dy*dy);
        })
        .collect(Collectors.toList());
    // origin: captured by the lambda closure.
    // Lambda is an object -> origin reference held in the lambda object.
    // C2 may see origin as "escaping" into the lambda object.
    // Scalar replacement of origin: may not apply.
}

// GOOD: extract primitives before lambda (primitives are value-copied):
List<Double> computeDistances(List<Point> targets, Point origin) {
    final int ox = origin.x, oy = origin.y;  // primitives, not references
    return targets.stream()
        .map(t -> {
            double dx = t.x - ox;  // ox, oy are primitives (copied, not referenced)
            double dy = t.y - oy;
            return Math.sqrt(dx*dx + dy*dy);
        })
        .collect(Collectors.toList());
    // ox and oy are int values captured by the lambda.
    // origin.x and origin.y are accessed at lambda creation, not inside.
    // origin is no longer referenced inside the lambda -> may not escape.
}

// SIMD VECTORIZATION EXAMPLE:

// GOOD: simple array arithmetic (C2 will vectorize with AVX2):
void addArrays(float[] a, float[] b, float[] result, int n) {
    for (int i = 0; i < n; i++) {
        result[i] = a[i] + b[i];  // vectorizable: simple element-wise op
    }
    // C2 with AVX2: processes 8 floats per instruction
    // 1000 elements: 125 SIMD operations instead of 1000 scalar operations
}

// BAD: complex control flow prevents vectorization:
void conditionalAdd(float[] a, float[] b, float[] result, int n) {
    for (int i = 0; i < n; i++) {
        if (a[i] > 0) {  // branch inside loop: C2 may not vectorize
            result[i] = a[i] + b[i];
        } else {
            result[i] = b[i];
        }
    }
}

// Check if vectorization occurred:
// -XX:+PrintCompilation -XX:+UnlockDiagnosticVMOptions
// -XX:+PrintInlining -XX:+TraceLoopOpts
// Look for "loop vectorized" in the output
```

> **Code walkthrough:** The escape analysis example shows the critical property: `doWork` must be
> inlined AND not store `p` for scalar replacement to apply. The lambda capture fix shows that
> capturing an object reference (even read-only) may prevent scalar replacement of that object.
> Capturing its primitive fields avoids this. The SIMD example shows simple element-wise array
> operations that C2 can vectorize, vs complex control flow that prevents vectorization.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JIT inlines small methods. After inlining, escape analysis can determine if objects are truly local.
> Non-escaping local objects: scalar replacement (zero heap allocation). Loop vectorization: simple
> array arithmetic with C2 and AVX2. Write small methods to enable inlining. Avoid storing objects
> in fields when local scope is sufficient.

---

### ⚠️ Common Misconceptions

**Misconception: "Objects are always heap-allocated in Java."**
The JVM spec requires heap allocation for objects, but C2's scalar replacement effectively moves them
off the heap (onto the stack or into registers) for non-escaping local objects. This is a spec-compliant
optimization because the behavior is identical from the program's perspective. The practical effect:
in tight loops with local objects that don't escape, allocation can be zero. JMH's `gc.alloc.rate.norm`
measurement: if it shows 0 B/op, all objects in that benchmark path were eliminated by scalar replacement.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Expected zero allocation from escape analysis, but JMH shows allocation.**
```
Symptom: JMH -prof gc shows gc.alloc.rate.norm = 48 B/op.
  Expected: 0 B/op (small local Point object should be scalar-replaced).

Diagnosis (step by step):
  Step 1: Add -XX:+PrintEscapeAnalysis to JMH fork args:
    @Fork(value = 1, jvmArgsAppend =
      {"-XX:+UnlockDiagnosticVMOptions", "-XX:+PrintEscapeAnalysis"})
    Look for your class in the output.
    "NoEscape" -> scalar replacement eligible
    "GlobalEscape" -> escaping to heap (look for the reason)
  
  Step 2: Check inlining:
    @Fork(jvmArgsAppend = {
      "-XX:+UnlockDiagnosticVMOptions", "-XX:+PrintInlining"})
    If the method calling new Point() is NOT shown as inlined:
    C2 can't see what happens to Point -> assumes escape -> allocates.
    
    Fix: break the method into smaller pieces (< 35 bytecodes)
    Or: -XX:MaxInlineSize=50 (increase inline threshold)
  
  Step 3: Check for subtle escapes:
    - Is the object passed to any lambda? (capture = potential escape)
    - Does any method called on the object return 'this' (fluent API)?
      -> may make the object reachable from the returned reference
    - Is there a synchronized block on the object?
      (synchronized itself doesn't prevent scalar replacement, but
      being the object of a monitor check means its identity matters)
    - Is the object passed to any synchronized(obj) block?
      -> lock identity is observable, C2 may not replace
  
  Step 4: Confirm the fix:
    After removing the escape: re-run JMH with -prof gc.
    gc.alloc.rate.norm should drop to 0 B/op.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Inlining prerequisites | 2 minutes |
| Escape analysis rules | 2 minutes |
| Scalar replacement | 2 minutes |
| Megamorphic dispatch | 2 minutes |
| Loop vectorization | 1 minute |
| Lambda capture and escape | 1 minute |
| Verifying escape analysis worked | 1 minute |
| Lock elimination | 1 minute |
| Inline cache transitions | 1 minute |

---

**Q1 (inlining): What determines whether C2 will inline a method?**

A: Size: `< MaxInlineSize` bytecodes (default 35). Methods up to 325 bytecodes may be inlined in
some contexts. Virtual dispatch type: monomorphic (1 implementation at the call site) or bimorphic
(2 implementations): C2 can speculate and inline. Megamorphic (3+ implementations): C2 gives up,
uses vtable dispatch. Depth: max inlining depth = MaxInlineLevel (default 9). Beyond depth 9: no
further inlining. Native methods: cannot be inlined by C2 (except JVM intrinsics like `Math.abs`,
`Arrays.copyOf`).

*What separates good from great:* The "inline prediction" in production: C2 builds an "inline cache"
at every call site. Initial state: uninitialized. First call: monomorphic (C2 inlines + emits guard:
"deoptimize if the receiver is not the expected class"). Second implementation encountered: bimorphic
(C2 inlines both with a branch). Third: megamorphic (C2 falls back to vtable dispatch, no further
inlining). Once megamorphic: difficult to recover without recompilation. This inline cache state
is per-call-site (not per-method). The same `List.add()` call in two different contexts can be
monomorphic in one (always ArrayList) and megamorphic in another (mixed list types). The
`-XX:+PrintInlining` output shows which call sites are inlined and which are "too big" or "virtual".

---

**Q2 (escape analysis): Walk through what happens when escape analysis determines a local object doesn't escape.**

A: Step 1: C2 inlines all methods that use the object. Now C2 has a single large code block where
the object is created, used, and (hopefully) not stored. Step 2: C2 traces all uses of the object
reference. Checks each use: is this use a "store to an externally visible location"? Step 3: if no
such store found: object is "NoEscape" (local only). Step 4: Scalar replacement: C2 replaces each
field access (`p.x`) with a local variable (`int x_2 = 3`). The object itself is never allocated.
Step 5: Local variables may be placed in CPU registers. The final result: the loop body containing
`new Point(x, y)` produces zero heap allocations.

*What separates good from great:* The "partial escape analysis" - an extension where C2 can apply
scalar replacement on the COMMON path even if the object escapes on RARE paths (exception paths,
error handling). Example: `Point p = new Point(x, y); if (errorCondition) log.error("Point: " + p);
doCompute(p)`. The error condition is rare. Partial escape analysis: apply scalar replacement on
the non-error path (99.999% of executions), and actually allocate only on the error path (0.001%
of executions). This is more aggressive than standard escape analysis. GraalVM uses partial escape
analysis; HotSpot C2 uses standard escape analysis (HotSpot's escape analysis is conservative:
if ANY path escapes, the object is heap-allocated).

---

**Q3 (megamorphic): How does megamorphic dispatch hurt performance and what can you do about it?**

A: Megamorphic dispatch: C2 cannot inline the callee because it doesn't know which implementation
will be called. Each call: (1) load the class of the receiver, (2) look up the method in the vtable,
(3) indirect call (branch to the method). Cost: ~5-15 CPU cycles vs ~0 for inlined call.
In a loop calling a megamorphic virtual 1 million times: 5-15 million extra cycles vs inline.
Fix: (1) Use concrete type at the call site if the type is known (ArrayList instead of List).
(2) Guard: `if (list instanceof ArrayList) { (ArrayList)list.op() } else { list.op() }` -
the instanceof guard makes the common path monomorphic.

*What separates good from great:* The "inline cache miss rate" tracking: JFR event `jdk.NativeMethodSample`
or Perf (Linux): can count vtable dispatch events. If vtable dispatches are a significant % of
total operations: megamorphic dispatch is a bottleneck. The "call site type distribution" principle:
at each call site, what percentage of calls go to each implementation? If 99% go to `ConcreteA`:
the call site is "quasi-monomorphic" and C2 will inline with a guard. If 5 different implementations
each get 20%: truly megamorphic, no inline. The fix for quasi-monomorphic: ensure the 99% case
comes first in the code (C2 profiles based on actual execution frequency). For truly megamorphic:
consider refactoring to avoid the polymorphic call in the hot path.

---

---

## Tiered Compilation and Code Cache Management

### 🎯 Model Answer

**30 seconds:**
> Tiered compilation: interpreted -> C1 (with profiling) -> C2 (optimized). Code cache: stores
> JIT-compiled native code. Default: 240-512MB. If full: JVM stops JIT compiling ("CodeCache is full").
> Performance impact: severe degradation (reverts to interpreted/C1). Flag: `-XX:ReservedCodeCacheSize=512m`.
> Monitor: JFR CodeCache events or `-XX:+PrintCodeCache`.

**3 minutes (Senior):**
> Tiered compilation details and code cache management:
>
> **Compilation thresholds**: Level 0 (interpreted) -> Level 3 (C1 + profiling) at ~2,000 invocations.
> Level 3 -> Level 4 (C2) at ~10,000 invocations. These are invocation counts, not wall-clock time.
> At startup: all methods are Level 0. After initial traffic: hot methods promoted to C1, then C2.
>
> **Code Cache segments** (JDK 9+): three segments:
> - Non-method code: stubs, adapters, runtime code (doesn't grow much).
> - Profiled code: C1-compiled code (grows during warmup, stabilizes).
> - Non-profiled code: C2-compiled code (grows as hot methods are compiled, stabilizes).
>
> **Code Cache full**: when C2 can't compile new methods (code cache full), new code stays at C1
> or interpreted. Existing C2 code continues to run (code already in cache). Net effect: new code
> paths (e.g., new endpoint called for first time after cache fills) never get C2 optimized.
>
> **Deoptimization**: when a C2 assumption is violated (new class loaded, uncommon trap triggered),
> C2 "deoptimizes" that method: marks the compiled code as invalid, falls back to interpreter,
> re-profiles, re-compiles.

**Blank Mind Recovery:**

**(1) Restate:** "Tiered: Level 0 (interp) -> L3 (C1+profiling, ~2k invocations) -> L4 (C2, ~10k invocations). Code cache: holds compiled code. Full: JIT stops, code runs at C1. Fix: -XX:ReservedCodeCacheSize=512m. Deoptimization: C2 reverts when assumptions violated."

**(2) First principles:** "The JVM uses the execution profile to guide compilation: compile the hot paths, not everything. C1 is a quick compile for early speed. C2 uses C1's profile data for aggressive optimization. More accurate profiling = better C2 optimization."

**(3) Bridge:** "Tiered compilation is like training a surgeon. First: follow a manual (interpreter). Next: practice the most common procedures (C1). Finally: master the critical operations with deep expertise (C2). The code cache is the limited shelf space for the textbooks."

---

### 📘 Concept Explanation

**Tiered compilation details and code cache monitoring:**
```
COMPILATION THRESHOLDS IN DETAIL:

  Level 0 -> Level 3 (C1 with profiling):
    Trigger: invocation count ~2,000 (TieredCompileTaskTimeout)
    OR: loop back-edge count ~14,000 (triggers OSR compilation)
    
    OSR (On-Stack Replacement): if a loop is hot BEFORE the method
    is called enough times: C2 compiles the method while it's in the loop.
    The JVM replaces the interpreter frame with the compiled frame mid-loop.
    Result: long-running loops are JIT-compiled mid-execution.
  
  Level 3 -> Level 4 (C2):
    Trigger: invocation count ~10,000 (after C1 profiling phase)
    C2 uses: type profile, branch statistics, call frequency data from C1
    C2 then: makes speculative decisions (inline common types, optimize common branches)
    
  Compilation queue:
    When many methods hit the compilation threshold simultaneously:
    C2 compiler queue builds up. Methods remain at C1 until compiled.
    Under traffic burst (startup): many methods queued simultaneously.
    JVM uses priority: hotter methods compiled first.
    
  View queue:
    jcmd <pid> Compiler.queue  (shows pending compilations)
    jstat -printcompilation <pid> 1000  (compilation events per second)

CODE CACHE SEGMENTS (JDK 9+ segmented code cache):

  Non-method: 2.5-5MB (stubs, trampolines) - rarely a bottleneck
  Profiled code: C1 code (default ~2/3 of total code cache)
  Non-profiled code: C2 code (default ~1/3 of total code cache)
  
  Total default: ~240MB (JDK 17 x64, server VM)
  
  When to increase:
    Applications with > 10,000 compiled methods (large microservices,
    frameworks: Spring, Hibernate, Jackson - each loads many classes)
    Large Lambda/Stream usage (each lambda = potentially separate method)
    Long-running applications (accumulate more compiled code over time)
  
  Monitoring:
    JVM flags: -XX:+PrintCodeCache (at JVM exit, print code cache summary)
    JFR: jdk.CodeCacheFull event (fires when code cache reaches capacity)
    jcmd: jcmd <pid> Compiler.codecache
    
    Output example:
    CodeCache: size=262144Kb used=123456Kb max_used=123456Kb free=138688Kb
    
    Warning threshold: when used > 90% of size: increase ReservedCodeCacheSize

DEOPTIMIZATION:

  Types of deoptimization:
    
    1. Speculative inlining (bimorphic -> polymorphic):
       C2 inlined based on "object is always type A."
       New type B encountered at the call site.
       JVM deoptimizes: removes C2 code, restarts from interpreter,
       re-profiles, re-compiles as bimorphic or megamorphic.
    
    2. Uncommon trap:
       C2 compiled the "common" path optimistically.
       The "uncommon" path (rarely-executed branch, e.g., error handling)
       was compiled as a "trap" - when reached, triggers deoptimization.
       C2 then recompiles to include the uncommon path properly.
    
    3. Class loading:
       A new class is loaded that invalidates an assumption
       (e.g., "X is the only implementation of interface I").
       All code compiled under that assumption is deoptimized.
    
  Detection:
    JFR: jdk.Deoptimization event
    -XX:+PrintDeoptimizationDetails (verbose, use on staging)
    
    Frequent deoptimizations: performance degradation (recompilation overhead)
    Common cause: loading new plugin classes in a hot path,
                  code that mixes many types at one call site

CODE CACHE FULL DIAGNOSIS:

  Symptom:
    JVM log: "CodeCache is full. Compiler has been disabled."
    Performance: service was fast, suddenly degrades (new code paths
    running at C1/interpreted speed)
    
  Diagnosis:
    jcmd <pid> Compiler.codecache
    Check: used vs total. If > 95%: full soon.
    
    What's taking up space?
    jcmd <pid> VM.compiled_methods  (list all compiled methods + sizes)
    Large anonymous classes (lambdas): many small methods in code cache
    
  Fix:
    -XX:ReservedCodeCacheSize=512m  (double or triple the default)
    If memory constrained: identify and remove hot-path anonymous class
    proliferation (lambdas that create many unique lambda instances).
```

---

### 💻 Code Example

> **Code walkthrough:** The monitoring commands show how to detect code cache pressure before
> it causes a production incident. The JFR-based detection shows how to set up early warning
> for code cache exhaustion.

```java
// CODE CACHE MONITORING AND MANAGEMENT:

// MONITORING COMMAND (run periodically):
// jcmd <pid> Compiler.codecache
// Output:
// CodeCache: size=262144Kb used=180000Kb max_used=180000Kb free=82144Kb
//            68.7% used <- approaching 90% threshold: increase soon!

// JFR MONITORING FOR CODE CACHE:
// Enable in application.properties or JFR config:
// -XX:FlightRecorderOptions=stackdepth=128
// jcmd <pid> JFR.start settings=default
// Look for event: jdk.CodeCacheFull

// SPRING BOOT ACTUATOR: code cache is exposed via JVM metrics:
// /actuator/metrics/jvm.compilation.time
// Monitor: compilation time increasing -> code cache pressure

// DETECTING DEOPTIMIZATION WITH JFR:
// jcmd <pid> JFR.start settings=default duration=60s filename=recording.jfr
// jcmd <pid> JFR.dump name=default filename=recording.jfr
// Open in JMC: look for "Deoptimizations" view

// PROGRAMMATIC CODE CACHE CHECK (for startup health check):
import java.lang.management.ManagementFactory;
import com.sun.management.HotSpotDiagnosticMXBean;
import java.lang.management.MemoryPoolMXBean;
import java.util.List;

@Component
public class JvmHealthIndicator implements HealthIndicator {
    
    @Override
    public Health health() {
        List<MemoryPoolMXBean> pools = ManagementFactory.getMemoryPoolMXBeans();
        
        for (MemoryPoolMXBean pool : pools) {
            if (pool.getName().contains("CodeCache") ||
                pool.getName().contains("Code Cache")) {
                long used = pool.getUsage().getUsed();
                long max = pool.getUsage().getMax();
                double pct = (double) used / max * 100;
                
                if (pct > 90) {
                    return Health.down()
                        .withDetail("codeCache", "CRITICAL: " + pct + "% full")
                        .withDetail("used", used / (1024 * 1024) + "MB")
                        .withDetail("max", max / (1024 * 1024) + "MB")
                        .build();
                } else if (pct > 75) {
                    return Health.status("WARNING")
                        .withDetail("codeCache", pct + "% full")
                        .build();
                }
            }
        }
        return Health.up().build();
    }
}

// IDENTIFYING LAMBDA METHOD PROLIFERATION:
// jcmd <pid> VM.compiled_methods | grep "lambda$" | wc -l
// If large number: each lambda in a hot code path creates a separate
// compiled method in the code cache.
//
// Anti-pattern: new lambda per call:
IntStream.range(0, 1000).forEach(i -> {
    // This lambda: 1 class, 1 compiled method
    // But if called 1000 times: the SAME lambda instance, same method
    // This is fine.
});
// The problem: lambdas capturing different state:
for (Config config : configs) {
    Supplier<String> supplier = () -> config.getValue();  // captures config
    // Each iteration: new lambda instance (new class? No: same class, different instance)
    // Lambda classes are cached per capturing site -> single compiled method
    // This is fine (not a code cache issue)
}
```

> **Code walkthrough:** The `JvmHealthIndicator` shows a production-ready code cache monitoring
> pattern: expose a health check endpoint that alerts at 75% usage (warning) and 90% usage (critical).
> The critical check triggers before the "CodeCache is full" JVM message, giving operations time to
> increase the code cache size and redeploy. The lambda proliferation section clarifies that lambda
> classes don't proliferate (they're cached per call site), but shows how to verify this assumption.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Code cache: stores JIT-compiled code. Full = JIT stops, performance degrades. Set
> `-XX:ReservedCodeCacheSize=512m` proactively. Tiered compilation: methods start interpreted,
> promoted to C1 (fast compile), then C2 (optimized). Deoptimization: C2 reverts when assumptions
> violated. Enable JFR to detect code cache and deoptimization events.

---

**Senior / Staff (5+ years):**
> Code cache sizing: profile first. `jcmd VM.compiled_methods` shows all compiled methods and
> sizes. For large Spring Boot apps: 240MB is often too small. 512MB is safe for most applications.
> Deoptimization frequency: check JFR deoptimization events in production. Frequent deoptimization
> means assumptions are frequently violated (mixed types, class loading in hot paths). This is
> often a design problem (too much polymorphism in the hot path) not just a tuning problem.

---

### ⚠️ Common Misconceptions

**Misconception: "The code cache stores all Java classes."**
The code cache stores COMPILED NATIVE CODE (the output of C1 and C2 compilers). Class bytecode is
stored in Metaspace. The code cache: machine code, JNI stubs, and JVM runtime stubs. Each compiled
method takes 100-500 bytes in the code cache (varies by method complexity). Metaspace: class metadata,
bytecode, constant pools. These are distinct memory areas. OutOfMemoryError: Metaspace -> too many
classes loaded. "CodeCache is full" message -> too many methods compiled -> increase
`ReservedCodeCacheSize`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: After a hot deployment, performance degrades permanently until the next restart.**
```
Symptom: After deploying a new JAR (hot-reload via OSGi or Spring DevTools),
  performance drops by 50-70% and doesn't recover.
  JVM log: no explicit error.

Root cause: DeoptimizationCascade after class loading.
  New classes loaded -> invalidate C2 assumptions:
  C2 compiled methods that assumed "only one implementation of Interface I."
  New plugin loaded a second implementation -> all those C2 methods deoptimized.
  They fall back to interpreter, re-profile, re-compile.
  Recompilation takes seconds to minutes for large applications.
  
  Additional root cause (more severe):
  Code cache too small. After several hot-reload cycles:
  code cache fills with old compiled methods that are no longer needed
  (from the previous deployment). New code can't be compiled.
  Code runs at C1/interpreted permanently until restart.

Diagnosis:
  JFR: count deoptimization events during and after reload.
  jcmd <pid> Compiler.codecache: check usage % after reload.
  
  If code cache is filling after each reload:
  -XX:+EnableJVMCI -XX:+UseJVMCICompiler -XX:+TieredCompilation
  (GraalVM-based JIT may handle code cache better)
  
  Shorter-term fix:
  -XX:ReservedCodeCacheSize=1g  (give more room after reloads)
  
  Root fix:
  Avoid hot deployment in production (use blue-green deployment instead).
  Hot deployment inherits all the JVM state from the previous deployment,
  including JIT assumptions that may be invalidated by the new classes.
  Blue-green: fresh JVM process for each deployment (proper warmup, clean state).
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| OSR compilation | 2 minutes |
| Code cache segments | 2 minutes |
| Code cache full consequences | 2 minutes |
| Deoptimization triggers | 2 minutes |
| Compilation queue | 1 minute |
| Monitoring code cache | 1 minute |
| Why deoptimize on class loading | 1 minute |
| Hot deployment and JIT | 1 minute |
| ReservedCodeCacheSize guidance | 1 minute |

---

**Q1 (osr): What is On-Stack Replacement (OSR) and when does it occur?**

A: OSR: the JVM replaces an interpreter-running method with JIT-compiled code while the method is
executing (mid-loop). Trigger: a loop inside a method accumulates a large back-edge count before the
method itself is called enough times for method-entry JIT. The JVM detects the hot loop, JIT-compiles
the method, then swaps the interpreter frame with the compiled frame at the loop back-edge. Result:
the loop continues running, but now in native code (3-10x faster) without the method call returning
and being re-called.

*What separates good from great:* The OSR compilation quality difference: OSR-compiled code is slightly
less optimized than method-entry compiled code because OSR must maintain the interpreter frame state
at the OSR entry point (the loop back-edge). The compiler can't re-arrange state aggressively. After
the OSR-compiled loop exits and the method is called again: the JVM may RECOMPILE the method via
normal method-entry compilation (better quality, not OSR-constrained). This is the "OSR -> normal
compile" transition. For long-running server applications: methods start with OSR (during initial
traffic burst), then stabilize with method-entry compiled code. JFR compilation events show both
the OSR and the subsequent normal compilation.

---

**Q2 (deopt): What causes a JIT deoptimization and what are the performance consequences?**

A: Triggers: (1) Speculative inline fails: C2 inlined assuming receiver type X, different type Y
encountered. (2) Uncommon trap: a rarely-executed code path (exception handler, null check failing)
was omitted by C2 ("uncommon trap"). When that path is taken: deoptimize. (3) Class loading: new
class violates a "unique implementation" assumption. (4) Hotspot's "reprofile" request: method is
very hot, C2 wants to recompile with updated profile. Consequences: (1) method reverts to interpreter
(slow). (2) Re-profiling period (2,000+ invocations at C1). (3) Recompilation by C2. Total: method
runs slowly for hundreds-to-thousands of invocations while being re-JIT-compiled.

*What separates good from great:* The "deoptimization storm" scenario: a class loading event that
invalidates assumptions for many C2-compiled methods simultaneously. Example: loading a new JDBC
driver plugin: the driver registers itself as a new `Driver` implementation. All C2 methods that
inlined `DriverManager.getConnection()` under the assumption of one implementation: all deoptimized
at once. Hundreds of methods re-profiling simultaneously: heavy JIT compiler CPU load, significant
performance degradation for seconds. Detection: JFR "DeoptimizationCascade" pattern in JMC (many
deoptimization events in a short window). Prevention: load plugins/drivers at startup before serving
traffic, not during operation.

---

**Q3 (cache size): How do you determine the right code cache size for a Java application?**

A: Start with the default, monitor, increase proactively. Process: (1) Run the application under
production-like load for several hours. (2) Check code cache usage: `jcmd <pid> Compiler.codecache`.
(3) If usage is > 70% at steady state: double the `ReservedCodeCacheSize`. (4) Set up JFR alert
for `jdk.CodeCacheFull` event. Rule of thumb: 512MB for most applications, 1GB for large microservices
(Spring Boot with many modules, Hibernate, Jackson, Spring Security: easily 3,000-5,000 compiled methods).

*What separates good from great:* The code cache efficiency metric: `used / max` isn't the only signal.
The compilation rate (compilations per second from JFR or jstat -printcompilation) shows if the
JVM is still actively compiling. A fully warmed application: compilation rate drops to near zero (all
hot methods already compiled). An under-warmed or code-cache-full application: compilation rate is
either 0 (cache full, stopped compiling) or high (still warming up). Tracking compilation rate over
time: shows when the application reaches JIT steady state. For containers that restart every hour
(rolling deployments): the application may never fully warm up. In this case: profiling during the
warmup period (first 5 minutes) shows whether C2 is actively compiling hot paths. If it is: the
container lifetime is too short for full JIT benefit. Solution: AOT compilation or longer pod lifetimes.

---
