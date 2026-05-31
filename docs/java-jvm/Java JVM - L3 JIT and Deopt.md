---
layout: default
title: "Java JVM - L3 JIT and Deopt"
parent: "Java JVM"
grand_parent: "SK Interview"
nav_order: 6
permalink: /java-jvm/l3-jit-and-deopt/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java JVM - L3 JIT and Deopt](#java-jvm---l3-jit-and-deopt) | medium |

---

# Java JVM - L3 JIT and Deopt

## JIT Compilation Tiers and Method Inlining

---

### 🎯 Model Answer

**30 seconds:**
> The JVM uses tiered compilation (Java 8+): methods start in the interpreter,
> get profiled, then compiled by C1 (fast compiler, quick but less optimized),
> and hot methods get recompiled by C2 (slow compiler, highly optimized). Method
> inlining is the single most impactful JIT optimization: callee method bytecode
> is injected directly into the caller, eliminating call overhead and enabling
> further optimizations (constant folding, dead code elimination) across method
> boundaries.

**3 minutes (Senior):**
> Tiered compilation has 5 levels (0-4):
> - Level 0: Interpreted
> - Level 1: C1 compiled, no profiling
> - Level 2: C1 compiled, limited profiling (invocation/backedge counters)
> - Level 3: C1 compiled, full profiling (type profiles, branch probabilities)
> - Level 4: C4 compiled (C2 with full optimizations based on profiles)
>
> Default path for a hot method: 0 (interpreted) -> 3 (C1 with profiling) ->
> 4 (C2 optimized). Fast path for trivial methods: 0 -> 1 (C1, no profiling).
>
> Method inlining: the JIT copies the bytecode of the inlined method into the
> caller's compilation unit. Then the combined code is optimized as a unit.
> Example: `getX()` returning a field -> inlined as `obj.x` field access directly.
> Enables: escape analysis (can now see the whole object flow), dead code elimination
> (inlined code with constant arguments), loop unrolling (inlined loop body).
>
> Inlining limits: `+XX:MaxInlineSize=35` (bytecodes, default), hot methods
> can inline up to 325 bytecodes. "Not inlined due to size" is the most common
> inlining failure. Break large methods into smaller ones to enable inlining.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "JIT tiers: interpreted -> C1 (profiled) -> C2 (optimized).
Inlining: copies callee into caller, eliminates call overhead, enables cross-method
optimizations. Bottleneck: method too large to inline."

**(2) First principles:** "The JVM starts executing code slowly (interpreter),
gathers data about which code is hot and how it behaves (profiling), then compiles
it to highly optimized native code based on that data (speculative optimization).
Inlining is the gateway optimization that enables all other optimizations."

**(3) Bridge:** "JIT compilation is like a road system. Initially all traffic
goes through local roads (interpreter). Busy routes get a first express lane
built (C1). The busiest routes get upgraded to a high-speed highway (C2).
Inlining is like merging intersections directly into the highway, eliminating
traffic lights (call overhead)."

---

### 📘 Concept Explanation

**JIT compilation tiers:**
```
TIER 0: Interpreted
  - All methods start here
  - Bytecode interpreted one instruction at a time
  - 10-100x slower than compiled code
  - Invocation counter incremented per call

TIER 1: C1 (no profiling)
  - Trivial/small methods
  - Quick compilation
  - No profiling data collected
  - Used for: final methods, trivial accessors

TIER 2: C1 (limited profiling)
  - Invocation and backedge counters
  - Faster to compile than full profiling

TIER 3: C1 (full profiling)
  - Type profiles (which class implements the interface?)
  - Branch probabilities (which branch is taken 99%?)
  - Call profiles (virtual call target statistics)
  - Data feeds C2 compilation

TIER 4: C2 (full optimizations)
  - Uses profile data from Tier 3
  - Speculative optimizations: inline virtual calls (assuming one receiver type)
  - Escape analysis, loop optimizations, vectorization
  - 2-5x slower to compile than C1, but 2-10x faster output

COMPILATION THRESHOLDS (approximate defaults):
  C1: ~200 invocations + loop iterations
  C2: ~10,000 invocations + loop iterations
  (actual: adaptive, depends on number of compiler threads)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The `@Benchmark` annotation approach shows that
> tiny accessor methods are completely transparent to the JIT - they get
> inlined to field access. The key insight is that Java's "everything is
> a method call" design has zero overhead for inlined methods.

```java
// Demonstrating JIT inlining benefits:

// This method will be inlined:
class Point {
    private final double x, y;

    // After inlining, point.getX() becomes just 'point.x' at call site
    // No method call overhead, no stack frame push/pop
    public double getX() { return x; }
    public double getY() { return y; }

    // NOT inlined if too large (> MaxInlineSize bytecodes):
    public double distanceTo(Point other) {
        double dx = this.x - other.x;
        double dy = this.y - other.y;
        return Math.sqrt(dx * dx + dy * dy);  // 30+ bytecodes -> may not inline
    }
}

// BAD: large method prevents inlining of its CALLERS
class BigProcessor {
    // 200+ bytecodes -> never inlined -> call site always has overhead
    // AND prevents caller from seeing optimizations within this method
    public Object processEverything(Object... args) {
        // 200 lines of complex logic - cannot inline
        // Each invocation: method call overhead + JIT can't optimize across boundary
    }
}

// GOOD: split for inlining
class GoodProcessor {
    // Each step is small enough to inline
    public Object process(Object data) {
        Object step1 = validate(data);   // 15 bytecodes -> inline
        Object step2 = transform(step1); // 20 bytecodes -> inline
        return persist(step2);           // 25 bytecodes -> inline
    }
    // After inlining: process() = inline(validate, transform, persist)
    // C2 can optimize the combined code as a unit
}

// Checking JIT compilation: -XX:+PrintCompilation
// Output:
//   45  1 3   java.lang.String::hashCode (55 bytes)
//    ^  ^ ^   method info
//    |  | |-- 3 = Tier 3 (C1 full profiling)
//    |  |---- 1 = compile ID
//    |------- 45ms = JVM uptime when compiled
//
//   120  2 4   java.lang.String::hashCode (55 bytes)  <- recompiled at Tier 4
//   130  1 4  made zombie  <- old Tier 3 version deoptimized

// Checking inlining: -XX:+PrintInlining (verbose)
// Output:
//   @ 10   Point::getX (5 bytes)   inline (hot)
//   @ 20   Point::getY (5 bytes)   inline (hot)
//   @ 30   Point::distanceTo (45 bytes)   too big to inline

// JFR alternative: JITCompilation event
// Shows: method name, tier, compilation time, code size
```

> **Code walkthrough:** `PrintCompilation` output is the first diagnostic
> for JIT issues. A method appearing multiple times (Tier 3, then Tier 4)
> is normal - it means the method is hot enough to warrant C2 compilation.
> "Made zombie" after a recompile means the old version was deoptimized and
> the new version replaced it. If you see a method repeatedly recompiled and
> deoptimized in a loop: you have a deoptimization problem (see Deoptimization keyword).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JVM compiles hot methods to native code through C1 (fast compile) then C2
> (optimized compile). Method inlining copies small method bodies into callers,
> eliminating call overhead. Big methods don't get inlined. JIT is what makes
> Java fast despite starting from bytecode.

---

**Senior / Staff (5+ years):**
> JIT compilation decisions are data-driven. C2 inlines virtual method calls
> based on type profiles from Tier 3: if 95% of calls to `Collection.size()`
> are `ArrayList.size()`, C2 inlines `ArrayList.size()` directly with a
> type guard. This is speculative: if a different type appears, the speculative
> inline is invalid -> deoptimization occurs. Good JIT performance requires:
> (1) monomorphic call sites (one receiver type), (2) small methods (inlinable),
> (3) stable code paths (same branch taken consistently). Tests that change
> code behavior from production patterns can degrade production JIT effectiveness.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Warm-up time is only needed for the first few requests."**
JIT warm-up takes time proportional to code complexity. A large Spring application
with hundreds of service classes: full JIT optimization may take 10-30 minutes
under load. During warm-up: CPU is higher (JIT compiler running), performance is
lower (unoptimized code paths). Load tests run for < 5 minutes often show better
performance than production (test hits warm JVM). Load tests should include a
"warm-up phase" of at least 5-10 minutes before measuring steady-state performance.

**Misconception 2: "Final methods are always inlined."**
Final methods CAN be inlined but are not guaranteed to be. Inlining depends on:
method size (must be under MaxInlineSize), call frequency (must be hot enough
for JIT to compile), and Code Cache space. Final only helps the JVM by confirming
no override exists (easier devirtualization). A final method of 200 bytecodes will
not be inlined despite being final.

---

### 🚨 Failure Modes and Diagnosis

**Failure: JIT not compiling hot code - throughput plateaus at interpreter speed.**
```
Symptom: High CPU, low throughput, -XX:+PrintCompilation shows no tier 4 compiles
  Or: throughput significantly lower than expected for warm JVM

Cause: Code Cache full -> JIT compilation disabled
  Or: Method too polymorphic for JIT to optimize

Diagnosis:
  1. Check Code Cache:
     jcmd <pid> Compiler.codecache
     If > 80% full: increase ReservedCodeCacheSize

  2. Check JIT compilation logs:
     -XX:+PrintCompilation | grep -v "       2"  <- skip Tier 2
     If many methods stay at Tier 3 (never reach 4): insufficient compile budget
     (too many methods competing for C2 compiler threads)

  3. Check compilation statistics:
     jcmd <pid> Compiler.statistics
     Shows: queue size, compile counts per tier

Fix:
  Code Cache: -XX:ReservedCodeCacheSize=512m
  More C2 threads: -XX:CICompilerCount=8 (default: CPU_cores/2, min 2)
  Emergency (throughput over latency): disable tiering
    -XX:-TieredCompilation  (all methods go direct to C2)
    Warning: higher compilation overhead, longer warm-up
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Tiered compilation levels | 2 minutes |
| Why inlining matters | 2 minutes |
| Inlining size limits | 2 minutes |
| Monomorphic vs polymorphic call sites | 2 minutes |
| JIT warm-up in production | 2 minutes |
| Code Cache | 2 minutes |
| PrintCompilation output | 2 minutes |
| C1 vs C2 trade-offs | 2 minutes |
| JIT and microservices | 2 minutes |

---

**Q1 (tiers): Explain the five tiers of JIT compilation.**

A: Level 0: interpreted. Level 1: C1 compiled without profiling (fast, used for
trivial methods). Level 2: C1 with invocation/backedge counters. Level 3: C1 with
full profiling (type profiles, branch probabilities - this data feeds C2). Level 4:
C2 fully optimized using profile data. Normal hot path: 0 -> 3 -> 4. Short path for
small/trivial methods: 0 -> 1. The key: Tier 3 profile data enables Tier 4 speculative
optimizations (inline the most common virtual call target, optimize the most common branch).

*What separates good from great:* Tiered compilation was introduced in Java 7
(as an option) and made default in Java 8. Before tiering: methods went directly
from interpreter to C2 (slow C2 compilation of unprofiled code, OR run in interpreter
while waiting). Tiering solves the "cold start" problem: C1 quickly makes methods
faster than interpreter while C2 compiles the truly hot methods optimally. The
JVM's compiler queue management: if many methods need compiling simultaneously
(startup burst), C1 gets priority (faster compile = sooner benefit). C2 compiles
fewer, hotter methods. The ratio: roughly 10 C1 compiles per 1 C2 compile.

---

**Q2 (inlining): Why is method inlining the most important JIT optimization?**

A: Inlining is the "meta-optimization" that enables all other optimizations.
When a callee is inlined into the caller: the combined code is optimized as a
unit. This enables: (1) constant folding across call boundaries (if a constant
is passed to an inlined method, the calculation can be folded); (2) dead code
elimination (if the inlined condition is always true/false in context); (3)
escape analysis (the JVM can see that an object created in the caller and passed
to the callee doesn't escape - enable stack allocation); (4) vectorization
(loop body inlined from separate method becomes optimizable as a loop unit).

*What separates good from great:* The indirect benefits of inlining explain
why Java (with JIT inlining) can match C++ performance for hot code. In C++: the
compiler sees ALL code at compile time, so inlining is always possible (with `inline`
hint or `-O2`). In Java: the JIT discovers at runtime which call sites are hot and
inlines those specifically. For systems code (tight loops, value processing):
structure code in small methods that inline well. One method calling 5 small methods
that all get inlined: same performance as one big method, better maintainability.

---

**Q3 (virtual call): How does the JIT handle virtual method calls?**

A: Virtual method calls (interface calls, overridden methods) require runtime
dispatch: look up the vtable/itable to find the actual method to call. This
prevents inlining. JIT optimization: if Tier 3 profiling shows 95%+ of calls
to `interface.method()` are one type (monomorphic call site), C2 generates:
inline type check -> if type matches, use inlined fast path; else call fallback.
This is "speculative devirtualization." Allows inlining even for virtual calls.

*What separates good from great:* A call site that has exactly ONE receiver type
in all profiling data: monomorphic - JIT inlines it directly. A call site with
two receiver types: bimorphic - JIT may still inline with a type check. Three or
more types (polymorphic/megamorphic): JIT uses vtable dispatch, cannot inline.
This is why megamorphic call sites are performance killers: a hot loop calling
`process(list)` where `list` is sometimes `ArrayList`, sometimes `LinkedList`,
sometimes `TreeList` -> megamorphic -> no inlining -> virtual dispatch on every call.
Design fix: use `ArrayList` exclusively in the hot path. Use interfaces for API
boundaries, concrete types internally.

---

**Q4 (escape): How does inlining enable escape analysis?**

A: Escape analysis determines if an object "escapes" from its creation scope:
if an object is passed to a method call, the JVM can't know if it escapes
(the called method might store it in a field, return it, etc.). After inlining
the called method: the JVM can see the complete usage. If the object is only
used locally (never returned, never stored in a field): it "doesn't escape."
Non-escaping objects can be stack-allocated (no GC overhead) or even eliminated
entirely (scalar replacement: replace the object with its field values).

```java
// Without inlining: iterator MIGHT escape
for (int x : list) { ... }  // Iterator created, passed to hasNext()/next()

// With inlining of Iterator methods: JVM sees iterator never escapes
// -> Stack allocation or scalar replacement
// -> No GC pressure from iterator objects in tight loops!
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Escape analysis + scalar replacement is why
Java code doesn't pay the allocation/GC overhead for short-lived objects in
tight loops (when fully JIT-optimized). The `for-each` loop over `ArrayList`:
JIT inlines `iterator()`, `hasNext()`, `next()` -> sees the iterator never escapes
-> eliminates the iterator object entirely. Under JIT: the `for-each` loop has
zero allocation overhead. This is NOT the case during JVM warm-up (before JIT
optimization) - warm-up measurements may show allocation overhead that disappears
in steady state.

---

**Q5 (on-stack replacement): What is OSR (On-Stack Replacement)?**

A: OSR allows the JVM to replace an interpreted method with a compiled version
WHILE the method is executing. Useful for: long-running methods or loops that
spend most of their execution time in one hot loop. Without OSR: the method must
complete in the interpreter before the compiled version can be used. With OSR:
the JVM can "switch horses mid-stream" at a safepoint (typically at backward
branch = end of loop iteration). The method frame is reconstructed in the
compiled form.

*What separates good from great:* OSR-compiled code is typically less optimized
than normally compiled code. Reason: OSR compilation happens at a specific point
in the bytecode (the loop back-edge). The compiled code must accept the interpreter's
existing frame state at that point, limiting some optimizations (e.g., can't
eliminate variables that the interpreter frame holds). This is why benchmark
frameworks like JMH run methods many times: to ensure the compiled version (not OSR)
is being benchmarked. OSR is visible in `-XX:+PrintCompilation` output as methods
marked with `%` (e.g., `45  3 % 3 MyBenchmark::doWork @ 23`).

---

**Q6 (inlining failure): What causes inlining failures?**

A: Method too large (`> MaxInlineSize` = 35 bytecodes for cold, 325 for hot).
Method is called through a megamorphic call site (3+ receiver types). Method
uses `synchronized` at the call site (adds stack frames that prevent inlining
for some JVM versions). Method throws checked exceptions in a complex flow.
JIT compiler budget exhausted (Code Cache full, too many compilation tasks).

```bash
# See why methods are not inlined:
-XX:+PrintInlining  # verbose inlining log

# Sample output:
# @ 15   Foo::bar (45 bytes)   too big to inline
# @ 20   Collection::size (10 bytes)   virtual call (megamorphic)
# @ 25   MyService::process (35 bytes)   inline (hot)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The `-XX:MaxInlineSize=35` default is
conservative. For the highest-priority hot loop in your application:
`-XX:MaxInlineSize=100` or `-XX:FreqInlineSize=400` can enable inlining of
larger methods. But: wider inlining increases Code Cache pressure and compilation
time. Profile first: if a specific method is on the hot path and NOT inlining:
measure the impact of enabling it before tuning. JMH benchmark + `-XX:+PrintInlining`
gives precise data on whether increasing MaxInlineSize helps your specific case.

---

**Q7 (CICompilerCount): What does CICompilerCount control?**

A: `CICompilerCount` = number of JIT compiler threads. Default: max(2, n_cpus/2).
On a 4-core machine: default is 2 compiler threads. These threads run the
C1 and C2 compilers concurrently with the application. More threads: faster
compilation (shorter code stays in lower tiers), higher peak CPU during warm-up.
For latency-sensitive applications: JIT compilation threads can cause CPU
spikes during warm-up. `-XX:CICompilerCount=1` reduces CPU usage during warm-up
at the cost of slower compilation.

*What separates good from great:* The "compilation burst" at startup is a common
source of poor initial latency in Java services. At startup: many methods need
JIT compilation simultaneously, JIT threads consume 1-2 CPU cores for compilation,
application threads compete for CPU. Symptom: high CPU + poor response times
for first 2-5 minutes. Mitigation: (1) increase CICompilerCount (more parallel
compilation, shorter burst), (2) use AppCDS (pre-compiled data, skip some JIT),
(3) warm-up period before routing traffic (Kubernetes readiness probe delays),
(4) GraalVM AOT compilation (eliminate JIT entirely at the cost of peak optimization).

---

**Q8 (profile-guided): How does profile data affect C2 optimizations?**

A: C2 uses Tier 3 profile data for: (1) type profiles -> speculative devirtualization
(inline the most common receiver type); (2) branch probabilities -> optimize layout
(hot branch taken -> jump-free layout, cold branch taken -> far jump); (3) null
check profiles -> eliminate null checks for always-non-null values; (4) range
check profiles -> eliminate array bounds checks for always-in-range accesses.
These are "speculative" optimizations: if profiled assumptions are violated,
deoptimization occurs.

*What separates good from great:* Profile pollution is a subtle performance issue.
If the code path used during warm-up differs from production code paths: C2
compiles optimizations based on wrong profiles. Example: unit tests that pass
mock objects (different types than production) pollute type profiles. Running unit
tests in the same JVM as production code can pollute JIT profiles. Similarly:
synthetic load test traffic with simpler data patterns may produce different type
profiles than real user traffic. For JIT optimization accuracy: warm-up with
production-representative traffic.

---

**Q9 (microservice JIT): How does JIT performance differ in microservices vs monoliths?**

A: Microservices restart frequently (deployments, scaling). Each restart: JIT
starts from scratch (no compiled code, full warm-up needed). Short-lived instances
(container scale-down): may never fully warm up. This is the "serverless JIT
problem." Monoliths run for days/weeks: JIT reaches steady-state and stays there.
Solutions: (1) GraalVM native image (AOT compilation, instant startup, no warm-up,
but lower peak performance); (2) AppCDS (faster warm-up, some compilation shared
across restarts); (3) Checkpoint/Restore (CRIU/CRaC: snapshot a warm JVM and
restore it for new instances).

*What separates good from great:* CRaC (Coordinated Restore at Checkpoint), available
in OpenJDK 21+ and Azul Zulu, checkpoints a running JVM to disk after warm-up and
restores the warm state for new instances. Startup time: milliseconds with a warm
JIT state. This is the most impactful solution for microservices with frequent
restarts. Trade-off: requires explicit checkpoint/restore lifecycle hooks in the
application (`Resource` interface for handling pre-checkpoint/post-restore events).
Kubernetes + CRaC + proper readiness probes: removes the JIT warm-up problem for
containerized Java microservices entirely.

---

### ⚖️ Comparison Table

| Compilation Tier | Compiler | Profile Data | Speed vs Interpreter | Compilation Cost |
|---|---|---|---|---|
| 0 (Interpreted) | None | None | 1x | 0 |
| 1 (C1 simple) | C1 | None | 5-10x | Very low |
| 3 (C1 full) | C1 | Type/branch profiles | 5-10x | Low |
| 4 (C2 full) | C2 | Uses Tier-3 data | 10-100x | High |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: JIT tiers described adequately in Concept Explanation)*

---

---

## Deoptimization and Speculative Compilation

---

### 🎯 Model Answer

**30 seconds:**
> Deoptimization occurs when the JVM compiled code based on speculative assumptions
> (e.g., "this virtual call always goes to ArrayList"), and those assumptions are
> violated at runtime. The JVM "backs out" the compiled code, returns to the
> interpreter or a lower tier, then recompiles with updated (less optimistic) assumptions.
> Frequent deoptimization ("deopt traps") is a performance killer - the method
> oscillates between compiled and interpreted states instead of staying at Tier 4.

**3 minutes (Senior):**
> C2 makes speculative optimizations based on Tier 3 profiles:
> - "Only one class implements this interface" -> inline it directly
> - "This branch is never taken" -> compile it as dead code
> - "This method never throws" -> remove exception table entries
>
> When an assumption is violated at runtime:
> 1. JVM detects violation (uncommon trap).
> 2. Current execution is "deoptimized": the compiled frame is reconstructed
>    as an interpreted frame at the exact bytecode position.
> 3. Execution continues in the interpreter.
> 4. JVM marks the compiled method as "not entrant" (new callers get interpreter).
> 5. The method is eventually recompiled with the updated profiles (less speculative).
>
> Key deoptimization reasons:
> - `unstable_if`: branch that was "never taken" in profiling was taken.
> - `class_check`: object type was different from profiled type.
> - `range_check`: array access out of bounds (range check was eliminated).
> - `make_not_entrant`: method recompilation triggers old version deopt.
> - `null_check`: null was encountered where profiling showed always non-null.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Deoptimization: JIT assumed something (type, null check, branch),
assumption violated at runtime, fall back to interpreter, recompile. Frequent deopt
= performance trap."

**(2) First principles:** "JIT optimizes based on past behavior (profiling). If future
behavior differs: the optimization is invalid. The JVM must detect this and fall back
to correct (but slower) execution."

**(3) Bridge:** "JIT deoptimization is like a GPS rerouting. The GPS planned an optimal
route (JIT compiled code) based on traffic data (profiling). When traffic changes
(assumption violated): GPS reroutes (deoptimize and recompile). Frequent rerouting means
unpredictable journey time."

---

### 📘 Concept Explanation

**Deoptimization triggers:**
```
SPECULATIVE OPTIMIZATION       ASSUMPTION VIOLATED    DEOPT REASON
Inline monomorphic call site   New class appears      class_check
Remove dead branch             Branch actually taken  unstable_if
Remove null check              Null object seen       null_check
Remove range check             Array out of bounds    range_check
Inline constant field          Field value changed    field_changed
Remove exception handling      Exception thrown       exception_handler

DEOPTIMIZATION SEVERITY:
  Rare deopts (< 1/minute): acceptable (warm-up artifact)
  Frequent deopts (> 100/s): serious performance issue
  Repeated class_check for same site: megamorphic call site
  
RECOMPILATION AFTER DEOPT:
  Method deoptimized -> interpreter -> profile updated
  -> C1 recompile (Tier 3) -> C2 recompile (Tier 4 with new data)
  New Tier 4 version: less speculative (handles both types,
  checks both branches, etc.)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The BAD pattern triggers repeated class_check deoptimizations
> because the JIT inlines `Comparable.compareTo()` for `Integer` but then encounters
> `String` objects. The JIT must deoptimize and recompile with a polymorphic
> (non-speculative) call. The GOOD pattern keeps types consistent.

```java
// BAD: mixing types in same call site -> deoptimization
List<Comparable> mixed = new ArrayList<>();
mixed.add(42);          // Integer
mixed.add("hello");     // String - different class!
mixed.add(3.14);        // Double - third class!

// JIT profiles mixed.get(i).compareTo(other):
//   Tier 3: sees Integer, Integer, String -> megamorphic
//   C2: cannot inline compareTo -> slower dispatch

// After mixing: deopts, recompiles as polymorphic
mixed.sort(Comparator.naturalOrder());
// Every compareTo() call: virtual dispatch (no inlining)

// GOOD: keep call sites monomorphic
List<Integer> integers = new ArrayList<>();
integers.add(42);
integers.add(100);
// JIT: compareTo always Integer.compareTo -> inline!
integers.sort(Comparator.naturalOrder());
// compareTo: inlined, fast

// Detecting deoptimizations:
// JVM flag: -XX:+TraceDeoptimization (verbose)
// Better: JFR Deoptimization event
jcmd <pid> JFR.start duration=30s filename=/tmp/deopt.jfr
// Open in JMC: "JVM Internals" -> "Deoptimizations"
// Shows: method, reason, count

// Shell shortcut - PrintDeoptimizationAtCompile:
// -XX:+PrintCompilation | grep deopt
// Output:
//   234  45 s  4  com.example.Service::process (234 bytes)
//                  ^ 's' = deoptimized/made not entrant, recompiling

// Checking deopt counters:
// jcmd <pid> Compiler.stats | grep deopt
// Or: JMX MBean sun.management.HotSpotDiagnosticMXBean
```

> **Code walkthrough:** The `List<Comparable>` mixing example is a real-world
> problem in generic utility code that handles multiple types. The JIT cannot
> know at Tier 3 profiling which types will appear, so it builds a polymorphic
> profile and C2 generates slower non-inlined dispatch. The pattern of "pass
> different types through the same call site" is the number one cause of
> megamorphic call sites and deoptimization in Java application code.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Deoptimization is when JIT compiled code is invalidated because an assumption
> it made (about types, null checks) turned out to be wrong. JVM falls back to
> interpreter, then recompiles. Rare deopt is fine. Frequent deopt = investigate.

---

**Senior / Staff (5+ years):**
> Deoptimization-driven performance issues are among the hardest to diagnose
> without knowing to look for them. Symptoms: throughput lower than expected for
> "warm" JVM, periodic CPU spikes correlating with recompilation, JFR showing
> high deopt counts. Root cause: polymorphic code that prevents speculative
> inlining. Fix: constrain types at hot call sites. For frameworks: use `final`
> classes, avoid generic `Object` parameters at hot paths, prefer concrete return
> types over interfaces in internal hot code. The JVM's speculative compilation
> is most effective on monomorphic, type-stable code paths.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Deoptimization means the JVM gave up on optimizing the method."**
Deoptimization is a temporary state. After deoptimization: the method runs in the
interpreter, profiles update with the newly observed data (new type, new branch),
C1 recompiles with fresh profiles, C2 recompiles with the updated data. The final
Tier 4 compilation includes handling for both observed behaviors. It's not "giving up"
- it's "learning from the unexpected and recompiling correctly." The overhead is the
transition period (interpreter execution + recompilation latency).

**Misconception 2: "null checks are free in JIT-compiled code."**
C2 eliminates null checks only when profiling shows the reference is ALWAYS non-null.
If a reference is ever null in profiling: the null check stays. If C2 eliminates
a null check (profiling shows always-non-null) and then a null appears: deoptimization.
For methods that COULD receive null (APIs where null is a valid value): JIT retains
the null check. The null check itself is fast (a comparison + conditional branch),
so "remaining null checks" in JIT code are usually not performance issues.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Repeated deoptimization loop - method never reaches stable Tier 4.**
```
Symptom: PrintCompilation shows method repeatedly compiled and deoptimized:
  t=100ms  45   3  mymethod (50 bytes)         <- C1
  t=200ms  45   4  mymethod (50 bytes)         <- C2 (compiled based on profile)
  t=201ms  45   4  mymethod (50 bytes)  deopt  <- assumption violated!
  t=250ms  45   3  mymethod (50 bytes)         <- back to C1 with new profile
  t=350ms  45   4  mymethod (50 bytes)         <- C2 recompile
  t=351ms  45   4  mymethod (50 bytes)  deopt  <- another assumption violated!

Cause: code has unstable behavior: new types appearing, branches flipping,
  previously-null values becoming non-null after warm-up

Diagnosis:
  1. Enable JFR deoptimization events:
     jcmd <pid> JFR.start settings=profile
  2. In JMC: JVM Internals -> Deoptimizations tab
     Shows: which method, which reason, how many times
  3. -XX:+PrintDeoptimizationAtCompile

Fix based on reason:
  class_check: restrict the types passing through the call site
  unstable_if: the condition is legitimately variable -> no fix (JIT handles it)
  range_check: add bounds check before array access to make profile stable
  null_check: add Objects.requireNonNull at method entry (fail-fast before profiling)

Nuclear option: CompileThreshold increase
  -XX:CompileThreshold=50000 (compile less aggressively, better profile first)
  Risk: longer warm-up time
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| What triggers deoptimization | 2 minutes |
| Unstable_if deoptimization | 2 minutes |
| class_check vs null_check | 2 minutes |
| JIT compilation + deopt cycle | 2 minutes |
| Megamorphic call sites | 2 minutes |
| Diagnosing deopt in production | 2 minutes |
| Uncommon traps | 2 minutes |
| Profile-guided speculation | 2 minutes |
| CHA (class hierarchy analysis) | 2 minutes |

---

**Q1 (trigger): What are the common reasons for deoptimization?**

A: `class_check`: object's runtime type differs from the profiled/assumed type
(speculative devirtualization failed). `null_check`: null encountered where
always-non-null was assumed. `unstable_if`: branch taken that was assumed never
taken. `range_check`: array index out of bounds for a range check that was
eliminated. `make_not_entrant`: method recompiled at higher tier; old compiled
version must be abandoned. `not_compiled_exception_handler`: exception thrown
through a path that was compiled without exception handling.

*What separates good from great:* "Uncommon trap" is the JIT mechanism for
speculative exits. When C2 encounters a code path it considers unlikely (based
on profiles): it compiles an "uncommon trap" - a special stub that triggers
deoptimization if that path is ever taken. This allows C2 to compile the
"expected" fast path without handling every edge case, while still being
correct. The uncommontrap count per method is visible in JFR.
If a trap fires frequently (> 100x/minute): the speculation is wrong and
the JIT is spending significant time on the deopt/recompile cycle.

---

**Q2 (CHA): What is Class Hierarchy Analysis?**

A: CHA (Class Hierarchy Analysis) is a JIT optimization that uses the currently
known class hierarchy to make inlining decisions. If `processPayment(Payment p)`
and `Payment` has only ONE implementation (`CreditCard`) currently loaded:
JIT can devirtualize the call without type profiling - CHA guarantees uniqueness.
This CHA-based inlining is invalidated when a NEW class is loaded that extends `Payment`.
Deoptimization: all CHA-based inlined call sites are immediately deoptimized.

*What separates good from great:* CHA-based deoptimization at class load time is
why plugin systems and hot-deploy frameworks (OSGi, JNDI) cause JIT "cliff drops":
when a new plugin class is loaded that extends a core interface, ALL CHA-based
inlinings of that interface are deoptimized simultaneously. This causes a brief
performance cliff (all those methods back in interpreter, recompiling). In production:
if a service loads plugins at startup (Kafka Connectors, Hibernate dialects):
allow 5-10 minutes warm-up AFTER all plugins are loaded before routing load.

---

**Q3 (deopt cycle): What is the performance impact of a method caught in a deopt loop?**

A: Each deopt/recompile cycle: method runs in interpreter (10-100x slower than
compiled), C1 compiles (CPU overhead, ~1ms), C2 compiles (CPU overhead, ~10-50ms).
If a hot method cycles every few seconds: significant throughput impact. Each
cycle: interpreter execution is slower, compilation consumes JIT threads. The
steady state: never reached. Performance: permanently degraded relative to a
stable Tier 4 compilation.

*What separates good from great:* In practice, most deopts are transient -
occurring during warm-up when new types appear for the first time. After all
types have been seen once: profiles stabilize, C2 recompiles with stable
data, no more deopts. The "deopt loop" problem typically comes from: (1) code
that genuinely sees different types at different times (a deserializer handling
different message types), (2) test code mixing types that production code never
mixes, (3) benchmarks that use heterogeneous test data to measure "average" performance
(actually measuring the deopt overhead). Fix: separate hot paths by type (use
separate methods for String processing vs Integer processing).

---

**Q4 (assumption): How does speculative devirtualization work?**

A: After Tier 3 profiling shows `Collection.size()` is always `ArrayList.size()`:
C2 generates: `if (obj.class == ArrayList) { return obj.length; } else { DEOPT; }`.
The fast path: no vtable lookup, directly reads the ArrayList's size field. The slow
path: deoptimize (triggers if a non-ArrayList is ever encountered). This is "inline
cache" or "speculative devirtualization." The type check (`instanceof`-like) is a
single comparison - much cheaper than vtable dispatch.

*What separates good from great:* Inline caches have three states: uninitialized
(no type seen), monomorphic (one type seen, inlined), polymorphic (two types seen,
two fast paths), megamorphic (three+ types, fall back to virtual dispatch). The
transition from mono to poly triggers recompilation. The transition from poly to
mega: C2 gives up on inlining this call site. This "mega" state is permanent for
that compilation unit (until the method is recompiled). Monitoring megamorphic call
sites: JFR `CallTypeStatistics` event in Java 21+ (not universally available
in all versions).

---

**Q5 (null_check): When does JIT eliminate null checks and what are the risks?**

A: JIT eliminates null checks when Tier 3 profiles show: a reference is NEVER null
in all observed executions. C2 removes the null check and jumps directly to field
access/method call. If a null appears: deoptimization. Specific pattern: method
parameter that was always non-null in profiling. The deoptimization is correct -
it catches the null and falls back to the interpreter, which will throw `NullPointerException`
at the correct bytecode location.

*What separates good from great:* Null check elimination is safe (JVM correctly
deoptimizes and throws NPE) but can cause surprises in profiling. If a method is
tested with non-null values and deployed with null-check elimination: the first null
in production triggers deoptimization. This is observable as: "NPE in weird method"
in the stack trace showing deoptimization frames. The null check is reliably eliminated
for `final` fields initialized in constructors and for fields with `@NotNull` validation
at entry (profiler never sees null). Using `Objects.requireNonNull` at method entry:
fails-fast AND prevents the JIT from profiling "unexpected null" paths, keeping null
check elimination valid for the actual business logic.

---

**Q6 (unstable_if): Why is unstable_if deoptimization different from class_check?**

A: `unstable_if`: a branch condition was assumed "always false" (or "always true")
from profiling, then it was true (or false) at runtime. After deoptimization, C2
recompiles and handles both branch directions. Result: the recompiled code is correct
and stable (both branches handled). `class_check`: a class assumption failed. After
deoptimization: C2 recompiles with the polymorphic type handling. Result: similar -
stable after recompile. The key difference: `unstable_if` typically stabilizes after
ONE deopt (the branch state becomes stable). `class_check` can recur if new classes
keep appearing at the same call site.

*What separates good from great:* The most benign deoptimization is `make_not_entrant`.
This means a higher-tier compilation replaced a lower-tier one. Every Tier 3 -> Tier 4
transition generates a `make_not_entrant` deopt for the Tier 3 code. This is NORMAL
and should be ignored in deopt analysis. Filter it out when analyzing: count only
`class_check`, `null_check`, `unstable_if`, and `range_check` deopts as potential
performance issues. `make_not_entrant` is a sign of healthy JIT progression (methods
being upgraded to better compilations).

---

**Q7 (bimorphic): What is a bimorphic inline cache?**

A: A bimorphic (two-type) inline cache is generated when C2 profiles show two
receiver types at a virtual call site. C2 generates: `if (type == A) { inline A's method } else if (type == B) { inline B's method } else { DEOPT or vtable dispatch }`.
Both A and B paths are inlined - fast. The else path: rare, handle via deopt or
polymorphic stub. Slightly slower than monomorphic (one extra check), still much
faster than vtable dispatch.

*What separates good from great:* The transition from bimorphic to megamorphic
happens when a third type appears. The JVM replaces the two fast paths with a
general vtable dispatch. This "morphic transition" is effectively a permanent
performance downgrade for that call site (until method recompile or JVM restart).
Defensive coding for performance-sensitive interfaces: minimize the number of
concrete types that flow through a hot call site. Use composition over inheritance
to limit subtype polymorphism at hot paths. In practice: most natural Java code
has 1-2 types at critical call sites (the common case and one exceptional case),
so bimorphic is common and well-optimized.

---

**Q8 (uncommon trap): What happens when an uncommon trap fires?**

A: When C2 considers a code path "cold" (rarely or never executed based on profiles):
it compiles that path as an "uncommon trap" - essentially: `if (cold_path_taken) { trigger_deopt(); }`.
If the cold path fires: the deoptimization handler is invoked, execution returns to
interpreter at the corresponding bytecode. The JVM records the trap firing.
If the trap fires repeatedly: the method is recompiled with the "cold" path treated as
"warm" (included in the main compiled code).

*What separates good from great:* The "never executed path becomes hot after JIT" case
is a real production issue. Example: error handling code. In testing (happy path):
error branches never execute -> JIT compiles them as uncommon traps. In production under
high load: error conditions start occurring (external service failures). The error handling
code (which was compiled as uncommon traps) fires -> deoptimizations -> JVM recompiles
with error paths included. The burst of deopts during an incident degrades JVM performance
exactly when you need it most. Fix: inject error conditions into load testing to ensure
error paths are profiled and compiled before production load.

---

**Q9 (trade-off): What is the fundamental trade-off of speculative JIT?**

A: Speculative JIT trades: (1) compilation assumptions (may be wrong) for (2) optimization
quality (much better when assumptions hold). Without speculation: JIT must handle all
possible cases -> conservative optimizations -> lower peak performance.
With speculation: JIT optimizes for the common case, handles exceptions via
deoptimization -> higher peak performance at the cost of deopt overhead when
assumptions fail. The bet: speculative assumptions hold most of the time in real workloads
(common case optimized, exceptions rare). For workloads where the "common case" shifts
over time: more frequent deopts, less benefit.

*What separates good from great:* The speculative JIT model is why "warm-up time"
is fundamental to Java performance (not a bug or limitation). It's the time required
for: (1) profiling to collect stable data, (2) C2 to compile methods with good
speculative assumptions, (3) all deopt/recompile cycles from initial "wrong assumptions"
to stabilize. A fully warmed-up JVM running production-representative traffic: speculative
assumptions are correct, code is optimally compiled, deoptimizations rare. This is why
JVM performance benchmarks that include only steady-state performance show Java
competitive with C++, while benchmarks that include startup/warm-up show a disadvantage.

---

### ⚖️ Comparison Table

| Deopt Reason | Cause | Stability After Recompile | Fix |
|---|---|---|---|
| `class_check` | New type at call site | Stable if no more new types | Restrict types at hot call site |
| `null_check` | Null encountered | Stable after first null | Fail-fast with requireNonNull |
| `unstable_if` | Branch taken | Usually stable | No fix needed (valid behavior) |
| `range_check` | Array OOB | Stable with check reinserted | Validate index before access |
| `make_not_entrant` | Higher tier compiled | Always stable (normal) | Ignore |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: deoptimization flow described adequately in Concept Explanation)*

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



