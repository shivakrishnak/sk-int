# Ahead-of-Time Compilation Theory

**Interview Weight:** hard - AOT theory is Principal-level
knowledge. Tests theoretical grounding for architectural decisions.

---

### 🎯 Model Answer

**30 seconds:**

> Ahead-of-time (AOT) compilation translates source or
> bytecode to native machine code before execution. Unlike
> JIT, which compiles during execution with access to runtime
> profile data, AOT compiles with only static analysis.
> This produces binaries that start instantly (no compilation
> delay) but with conservative optimizations (no speculative
> optimization, no deoptimization). The fundamental trade-off:
> AOT trades runtime adaptability for predictability and
> startup speed.

**3 minutes (Senior):**

> Compilation spectrum:
>
> Interpretation (no compilation):
>   Execute: decode instruction, perform operation, repeat.
>   Pros: instant start, portable.
>   Cons: 10-100x slower than native.
>   Examples: Python CPython, Ruby MRI, early Java.
>
> JIT (Just-In-Time):
>   Execute: start interpreted.
>   Profile: identify hot paths.
>   Compile: hot paths to native code.
>   Execute: native for hot, interpreted for cold.
>   Pros: best throughput (speculative optimization).
>   Cons: startup cost, memory for JIT structures.
>   Examples: Java HotSpot, V8, PyPy.
>
> AOT (Ahead-Of-Time):
>   Before execution: compile all reachable code.
>   Execute: native from first instruction.
>   Pros: fast startup, low memory, predictable.
>   Cons: can't speculate on runtime profile.
>   Examples: C/C++, GraalVM native, Rust.
>
> Tiered compilation (hybrid):
>   Tier 1: compile fast (low optimization).
>   Tier 2: profile and compile hot paths (full optimization).
>   Java HotSpot: 5 tiers.
>   Pros: fast start (T1) + high throughput (T5).
>   Cons: complex, memory pressure.
>
> PGO (Profile-Guided Optimization):
>   Collect profile data from representative workload.
>   Use profile for AOT compilation decisions.
>   Bridges AOT-JIT gap: AOT performance approaches JIT.
>   GraalVM: 3-pass build (instrument, run, optimize).
>   Result: 10-30% better throughput vs plain AOT.
>
> Partial evaluation:
>   Given: a program + known inputs.
>   Specialize: compile the program for those inputs.
>   Truffle: partial evaluate interpreter + known AST = native.
>   Result: language interpreter quality = hand-written C.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the theoretical
foundations of ahead-of-time compilation."

**(2) First principles:** "Compilation: translate source to
machine code. AOT: before execution. JIT: during execution."

**(3) Bridge:** "AOT vs JIT is the static vs dynamic trade-off:
predictability vs adaptability."

---

### 💻 Code Example

```java
// DEMONSTRATING: AOT compilation effects

// Speculative optimization (JIT does, AOT cannot)
// JIT observation: 99% of calls pass Circle
// JIT generates: fast Circle.area() path + guard
// If Square arrives: deoptimize → interpreter → recompile

// AOT: cannot assume Circle (no runtime data)
// AOT: generates: polymorphic dispatch
//   if (shape instanceof Circle) return circle.area();
//   if (shape instanceof Square) return square.area();
//   return generic.area();
// Slower: two extra type checks vs JIT's speculative path

// DEMONSTRATING: PGO closes the gap
// Step 1: instrument build
// ./mvnw package -Pnative
//   -Dquarkus.native.additional-build-args=--pgo-instrument
// Binary: collects execution frequency data

// Step 2: run under production-representative traffic
// ./target/app-runner-instrumented
// k6 run --vus 100 --duration 5min production-load.js
// Profile collected: which methods called, how often,
//   which branches taken, which types observed

// Step 3: recompile with profile
// ./mvnw package -Pnative
//   -Dquarkus.native.additional-build-args=
//   --pgo=profile.iprof
// AOT now has: call frequency, branch probabilities,
//   type observations
// Result: approaches JIT performance

// DEMONSTRATING: Partial evaluation
// Truffle interpreter for addition:
// execute(frame) {
//   long left = leftNode.execute(frame);   // virtual call
//   long right = rightNode.execute(frame); // virtual call
//   return addLongs(left, right);          // method call
// }

// After partial evaluation (Graal):
// If AST stable: leftNode is always LiteralNode(5)
// Partial eval: leftNode.execute() → constant 5
// If rightNode is always ArgNode:
//   rightNode.execute() → frame.getLong(slot_0)
// Final: return 5 + frame.getLong(slot_0)
// Machine code: one load + one add = 2 instructions
// Same as: int addFive(int x) { return 5 + x; } in C
```

> **Code walkthrough:** The polymorphic dispatch shows
> why AOT is 10-20% slower than JIT for OO code: JIT
> can speculate on the most common type and generate a
> fast path, then deoptimize on exceptions. AOT must
> generate safe code for all types upfront. PGO provides
> the profile data that JIT collects at runtime, letting
> AOT make similar decisions. Partial evaluation demonstrates
> the theoretical maximum: with enough static information,
> AOT can match native C performance.

---

### 🎓 Answers by Seniority

**Staff:** "AOT theory: compile without runtime profile → conservative
code. JIT: compile with runtime profile → speculative optimizations.
PGO: inject profile into AOT. Partial evaluation: AOT can
match JIT when inputs are known at compile time (Truffle)."

**Principal:** "The compilation spectrum is a trade-off
between startup cost and peak throughput. There is no
universally optimal point: Lambda needs AOT (startup), batch
needs JIT (throughput), interactive needs tiered (both).
The 'right' answer is always context-dependent."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 6 min | AOT vs JIT theory, PGO |
| Principal | 12 min | Full spectrum, partial evaluation, Futamura projections |

---

**[PRINCIPAL] Q1 - What are the Futamura projections
and why do they matter for understanding Truffle?**

*Why they ask:* Deep theoretical foundation.

Futamura projections (1971): three fundamental specializations.

Projection 1:
- Specialize interpreter I for program P.
- Result: a compiled version of P.
- spec(I, P) = target program.
- This is: what AOT compilation does.

Projection 2:
- Specialize the specializer for I.
- Result: a compiler for language L.
- spec(spec, I) = compiler for L.
- This is: what partial evaluators achieve.

Projection 3:
- Specialize the specializer for itself.
- Result: a compiler compiler (meta-compiler).
- spec(spec, spec) = compiler generator.

Truffle implements Projection 1 + 2:
- Interpreter: written in Java (Truffle framework).
- Partial evaluator: Graal compiler.
- Result: Projection 1: compiles guest programs.
- Graal specializes its own compilation: Projection 2.

Practical implication:
- Language implementer writes: one Truffle interpreter.
- Gets for free: an optimizing compiler for that language.
- Economic efficiency: 1 interpreter → 1 compiler.
- GraalJS, GraalPy, TruffleRuby: all use this model.
- Alternative: write a separate compiler per language.
  (GHC for Haskell, rustc for Rust - years of work).

*What separates good from great:* Futamura projections
explain WHY Truffle can provide high-performance language
implementations with a simple interpreter pattern.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | AOT theory, PGO, tiered compilation. |
| Hiring Manager | AOT practical implications. |
| Bar Raiser | Partial evaluation, compilation spectrum. |
| Principal | "Futamura Projection 1: spec(interpreter, program) = compiled program. Truffle implements this via Graal's partial evaluator." |

---

---

# Points-To Analysis and Escape Analysis

**Interview Weight:** hard - Static analysis foundations
explain native image behavior and optimization opportunities.

---

### 🎯 Model Answer

**30 seconds:**

> Points-to analysis determines what objects each variable
> can point to during execution. In GraalVM native image,
> it finds all reachable code. Escape analysis determines
> whether an object is accessible outside its allocation
> context. Objects that don't escape can be stack-allocated
> (no GC pressure). Both are flow-insensitive, whole-program
> analyses. Understanding both explains native image constraints
> (why strings can't be followed in Class.forName) and
> optimizations (why short-lived objects may be stack-allocated).

**3 minutes (Senior):**

> Points-to analysis:
>
> Problem: which objects can variable x point to?
>
> Simple example:
>   void foo() {
>     Object a = new A();
>     Object b = new B();
>     Object x = (flag) ? a : b;
>     // x can point to: A or B (imprecise)
>     use(x);
>   }
>
> Analysis result:
>   Points-to set of x: {A, B}.
>   use(x): must handle both A and B.
>
> Precision levels:
>   Context-insensitive: one analysis for all call sites.
>   Over-approximate: include both A and B everywhere.
>   Faster but less precise.
>
>   Context-sensitive: separate analysis per call site.
>   More precise: different variables for different calls.
>   Exponentially more expensive.
>
> GraalVM: context-insensitive (practical compromise).
>
> Why Class.forName violates analysis:
>   points-to of Class.forName(stringVar) = unknown.
>   String variable: not a type reference.
>   Analysis: cannot resolve string to class.
>   Result: class excluded from binary (safe under-approx).
>
> Escape analysis:
>
> Problem: does object allocated at point P escape?
>   Escape: object reaches a thread, field, or return.
>   Local: object only used in creating method.
>
> Example:
>   void bar() {
>     Point p = new Point(x, y);  // local?
>     return p.x + p.y;           // p used locally only
>     // p does NOT escape bar()
>   }
>
> JIT optimization: stack allocate p.
>   p on stack: freed when bar() returns.
>   No GC involvement.
>   Faster: no allocation overhead.
>
> GraalVM escape analysis:
>   Identifies: objects that don't escape.
>   Optimizes: allocate on stack or eliminate entirely.
>   Effect: fewer GC-managed allocations.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about points-to and escape
analysis and how they relate to GraalVM."

**(2) First principles:** "Points-to: what can x point to?
Escape: does this object leave its scope?"

**(3) Bridge:** "These analyses explain both GraalVM's
power (escape analysis → stack allocation) and limitations
(points-to can't follow strings)."

---

### 💻 Code Example

```java
// ESCAPE ANALYSIS: objects Graal may stack-allocate

// Example 1: Short-lived calculation object
public double processOrder(double base, double tax) {
    // PriceCalc: created locally, used locally
    // Does NOT escape: not assigned to field,
    //   not passed to other threads,
    //   not returned
    PriceCalc calc = new PriceCalc(base, tax);
    double total = calc.computeTotal();
    // calc goes out of scope here
    return total;
    // Graal: may eliminate PriceCalc entirely
    // Or: stack-allocate (free when frame pops)
}

// Example 2: Object that escapes (can't stack-allocate)
public Order createOrder(Request req) {
    Order order = new Order(req);
    orders.add(order);  // Escapes: added to field
    return order;       // Escapes: returned
    // Graal: heap-allocate (must be GC-managed)
}

// Example 3: Iterator may be eliminated
// (if loop is inlined and iterator doesn't escape)
public int sumList(List<Integer> list) {
    int sum = 0;
    // Iterator object created for for-each
    // Graal may: inline the iterator,
    //   prove it doesn't escape,
    //   eliminate the allocation
    for (Integer value : list) {
        sum += value;
    }
    return sum;
}

// POINTS-TO ANALYSIS: what analysis can/cannot follow

// CAN follow: direct type references
OrderService svc = new OrderServiceImpl();
svc.createOrder(req);
// Analysis: svc points to OrderServiceImpl
// createOrder on OrderServiceImpl: reachable

// CANNOT follow: string-based class lookup
String className = "com.example.OrderServiceImpl";
Class<?> clazz = Class.forName(className);
// Analysis: className is a String
// Analysis: cannot resolve String to class
// Analysis: Class.forName result = unknown
// OrderServiceImpl: MAY NOT be in points-to set
// → excluded from native binary if not otherwise reached

// WHY this is correct (under-approximation):
// Analysis: conservative → include all reachable
// String-based: cannot verify reachability
// Under-approximate: exclude (may cause ClassNotFound)
// Fix: explicit registration bridges the gap
@RegisterForReflection  // Explicit entry into binary
public class OrderServiceImpl { ... }
```

> **Code walkthrough:** PriceCalc in Example 1 is a
> candidate for escape analysis: created locally, used
> locally, not stored or returned. Graal may stack-allocate
> it or eliminate the allocation entirely (scalar replacement:
> replace the object with its fields directly). The iterator
> in Example 3 is a classic escape analysis target: modern
> JITs often eliminate iterator allocations for simple loops.
> The Class.forName example shows why the analysis is
> conservative: better to under-include and require explicit
> registration than to over-include and produce incorrect code.

---

### 🎓 Answers by Seniority

**Staff:** "Points-to analysis: over-approximate what x can
point to. String-based class lookup: cannot follow → excluded.
Escape analysis: proves local lifetime → stack allocation.
Both are whole-program analyses that explain GraalVM's
behavior."

**Principal:** "Points-to and escape analysis are the
theoretical foundation for both native image constraints
and JIT optimizations. Every 'why does Class.forName fail
in native?' trace back to points-to analysis precision.
Every 'why are short-lived objects cheap?' traces back
to escape analysis."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 6 min | Points-to, escape analysis, native image connection |
| Principal | 12 min | Precision levels, analysis complexity, theoretical foundations |

---

**[PRINCIPAL] Q1 - How does k-CFA (k-context-sensitive
points-to analysis) improve precision?**

*Why they ask:* Deep compiler theory.

Basic (0-CFA, context-insensitive):
- One analysis for all call sites.
- merge: caller A → foo() and caller B → foo()
  analyzed together.
- Imprecise: objects from A and B mixed.

1-CFA:
- Separate analysis per direct call site.
- foo() from caller A: separate from foo() from caller B.
- More precise but O(n^2) memory.

k-CFA:
- k levels of context.
- k=1: call site context.
- k=2: call site + its caller.
- k=3: deeper context.
- Precision grows with k.
- Cost: exponential in k.

Practical limits:
- k=0 (context-insensitive): fast, used in native-image.
- k=1: 2-5x slower, used in some JIT inlining decisions.
- k=3+: rarely practical for whole-program analysis.

Why native-image uses k=0:
- Analyzing 60,000+ methods with k=1: hours.
- k=0: minutes.
- Result: over-inclusive binary (larger) but correct.

Alternative: on-demand context sensitivity.
- Some analyses: context-sensitive only for "important" methods.
- Important: generic collection methods (List, Map).
- Unimportant: infrastructure methods.
- Practical k-CFA: better precision without full k=1 cost.

*What separates good from great:* k-CFA explains why
native image is conservative: k=0 over-approximates,
over-includes, producing a larger but correct binary.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Points-to, escape analysis, native image connection. |
| Hiring Manager | Why Class.forName fails in native. |
| Bar Raiser | Analysis precision, context sensitivity. |
| Principal | "k=0 CFA: fast but over-approximate. Native image over-includes (larger binary). Explicit registration guides analysis past string barriers." |
