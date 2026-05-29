---
layout: default
title: "Java JVM - L1 Fundamentals"
parent: "Java JVM"
grand_parent: "SK Interview"
nav_order: 2
permalink: /java-jvm/l1-fundamentals/
---

# Java JVM - L1 Fundamentals

## Bytecode Loading and Class Initialization

### 🎯 Model Answer

**30 seconds:**
> When the JVM needs a class, it goes through five phases: Loading (find
> the .class file), Linking (verify bytecode, prepare static field memory,
> optionally resolve symbolic references), and Initialization (run static
> initializers and assign static field values). Loading uses the ClassLoader
> hierarchy with parent delegation. Initialization runs exactly once per
> ClassLoader, lazily (when the class is first actively used: creating an
> instance, calling a static method, accessing a static field).

**3 minutes (Senior):**
> Loading: the ClassLoader reads the .class bytes (from jar, filesystem, network,
> or generated at runtime). The JVM creates a `Class<?>` object in the method area
> (Metaspace).
>
> Linking has three steps: (1) Verification - bytecode type safety checks
> (StackMapTable validation, type correctness); (2) Preparation - allocate
> memory for static fields, set to defaults (0, null, false); (3) Resolution -
> optionally resolve symbolic references (class names, method names) to direct
> references.
>
> Initialization: runs static initializers (`static { }` blocks) and static
> field assignments IN ORDER. Runs exactly once. The JVM guarantees thread-safe
> initialization: if two threads race to initialize a class, one runs the
> initializer and the other waits. This is the foundation of the "class holder
> singleton" idiom (`private static class Holder { static final X instance = new X(); }`).
>
> Circular initialization: ClassA's initializer triggers ClassB's initializer,
> which needs ClassA - Java detects this and reports `ExceptionInInitializerError`.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Class loading phases - Loading, Linking (verify/prepare/resolve),
Initialization. Then thread-safety guarantee and the class holder pattern."

**(2) First principles:** "Before executing code from a class, the JVM must
have it in memory and verified. The five sub-phases are ordered: can't run
static initializers before verifying the bytecode is safe."

**(3) Bridge:** "Class loading is like immigrating to a country: Loading =
arrive at the border, Linking = pass through customs (verify documents, prepare
paperwork), Initialization = get settled (run setup tasks). You can't work until
all three phases complete."

---

### 📘 Concept Explanation

**Class lifecycle:**
```
1. LOADING:
   - ClassLoader.loadClass() called
   - Reads .class bytes from source (jar, classpath, generated)
   - Creates java.lang.Class object in Metaspace

2. LINKING:
   2a. Verification:
       - Bytecode format valid (magic number, version)
       - Type safety (StackMapTable verified)
       - No illegal field/method accesses
   2b. Preparation:
       - Static fields allocated, set to defaults
       - (int fields = 0, reference fields = null, boolean = false)
   2c. Resolution (may be lazy):
       - Symbolic references -> direct references
       - "com.example.Foo" string -> actual Class object pointer

3. INITIALIZATION:
   - static field assignments executed
   - static { } blocks executed
   - ORDER: top-to-bottom in source file
   - THREAD-SAFE: JVM serializes initialization
   - ONCE: per ClassLoader instance
```

---

### 💻 Code Example

> **Code walkthrough:** The class holder idiom exploits the JVM's
> thread-safe, lazy class initialization guarantee. `Holder` class is not
> initialized until `getInstance()` is called. JVM guarantees only one thread
> runs the `Holder` initializer. No `synchronized` keyword needed.

```java
// Static initializer ordering:
class InitOrder {
    static int a = computeA();       // 1st: assigned during initialization
    static int b;

    static {
        b = a + 10;                  // 2nd: static block runs
        System.out.println("b=" + b);
    }

    static int c = b + 5;           // 3rd: assigned after static block

    static int computeA() { return 42; }
}
// Result: a=42, b=52, c=57 (order matters!)

// BAD: circular static initialization
class A {
    static int x = B.y + 1; // triggers B initialization
}
class B {
    static int y = A.x + 1; // triggers A initialization (circular!)
}
// Result: A.x=1, B.y=2 (NOT 42!) - one class sees the other's default value

// GOOD: Class holder singleton (leverages JVM initialization guarantee)
class Singleton {
    private Singleton() {}

    // Holder not loaded until getInstance() is first called
    private static class Holder {
        static final Singleton INSTANCE = new Singleton();
        // JVM guarantees: thread-safe, lazy, no synchronized needed
    }

    public static Singleton getInstance() {
        return Holder.INSTANCE; // triggers Holder initialization on first call
    }
}

// Verifying class loading order:
// JVM flag: -verbose:class
// Output:
//   [Loaded java.lang.String from /path/to/jdk/modules]
//   [Loaded com.example.MyClass from file:/path/to/myapp.jar]
// Shows: exactly when each class is loaded (lazy = when first needed)
```

> **Code walkthrough:** The circular initialization example shows a subtle
> Java bug: when `A` initializes, it reads `B.y`. This triggers `B`'s
> initialization. `B` needs `A.x`, but `A` is currently being initialized
> by the SAME thread - the JVM detects this and uses A's current (default/partial)
> value (0 + 1 = 1). Then `B.y = 0 + 1 = 1`, `A.x = 1 + 1 = 2`. Not what you
> intended. The fix: avoid circular static dependencies between classes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Classes go through Loading, Verification, Preparation, Resolution, and
> Initialization. Static blocks run during initialization, exactly once per
> JVM. The JVM guarantees thread-safe initialization.

---

**Senior / Staff (5+ years):**
> Class initialization is the foundation of lazy, thread-safe singletons in Java.
> The class holder idiom is more performant than double-checked locking because
> it requires no volatile reads on the happy path - the JVM's happens-before
> guarantee from class initialization covers the singleton publication.
> Initialize-on-demand: constructors, static methods, and static field accesses
> trigger initialization. Reflection: `Class.forName()` triggers initialization
> by default; `Class.forName(name, false, cl)` loads without initializing (useful
> for service discovery). Class unloading: a class is GC'd when its ClassLoader
> is GC'd AND there are no other references to the Class object - important for
> hot-reload scenarios (application servers, test frameworks).

---

### ⚠️ Common Misconceptions

**Misconception 1: "static fields are initialized when the JVM starts."**
Static fields are initialized when the CLASS is first initialized (lazily).
Not at JVM startup, not when the .class file is loaded - when first actively used.
This is why the class holder singleton is lazy: `Holder.INSTANCE` is not
created until the first call to `getInstance()`. This lazy initialization property
is guaranteed by the JVM specification.

**Misconception 2: "static { } blocks always run once at program start."**
They run once per ClassLoader, not once per JVM. An application server with
multiple webapps loads the same class separately per webapp's ClassLoader,
running static initializers once per ClassLoader. A test framework that uses
isolated ClassLoaders per test class may run static initializers many times.
"Once per JVM" is only true if there's only one ClassLoader (simple applications).

---

### 🚨 Failure Modes and Diagnosis

**Failure: ExceptionInInitializerError - static initializer threw an exception.**
```
Symptom: java.lang.ExceptionInInitializerError
Caused by: java.lang.NullPointerException at MyService.<clinit>(MyService.java:15)
  + NoClassDefFoundError on ALL subsequent uses of MyService

Cause: The static initializer threw an exception.
  JVM marks the class as permanently failed to initialize.
  ALL subsequent attempts to use MyService: NoClassDefFoundError
  (even if the underlying cause could be fixed!)

Diagnosis:
  1. Find the "Caused by:" chain in the stacktrace
  2. Look at the static initializer code (line 15 in <clinit>)
  3. Common causes: static field initialized from missing env variable,
     static field depends on a system resource (file, DB) not available

Fix:
  1. Ensure static initializers don't throw (validate before init)
  2. Move initialization to a lazy init method or constructor
  3. Static fields depending on environment:
     BAD:  static final String HOST = System.getenv("DB_HOST"); // null?
     GOOD: static final String HOST = Objects.requireNonNull(
               System.getenv("DB_HOST"), "DB_HOST env var required");
     BEST: Move to instance constructor, throw on missing config at startup
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Class loading phases | 2 minutes |
| Static initializer ordering | 90 seconds |
| Thread-safe class initialization | 2 minutes |
| Class holder singleton | 2 minutes |
| ExceptionInInitializerError | 2 minutes |
| Class unloading | 2 minutes |
| Lazy vs eager loading | 90 seconds |

---

**Q1 (loading phases): What are the five phases of class loading?**

A: Loading, Verification, Preparation, Resolution, Initialization.
Loading: ClassLoader reads .class bytes, creates Class object.
Verification: JVM checks bytecode safety (types, stack integrity).
Preparation: static fields allocated with defaults.
Resolution: symbolic references converted to direct references.
Initialization: static blocks and field assignments executed.

*What separates good from great:* Resolution can be lazy (deferred to first use)
or eager (at linking time). The JVM specification allows both. HotSpot resolves
lazily: symbolic references are resolved on first access, not at class load time.
This enables circular class references to compile without circular ClassLoader
issues. Lazy resolution also means a class can be loaded even if it references
classes that don't exist yet (e.g., optional dependencies), as long as those
references are never used at runtime.

---

**Q2 (class holder): Why is the class holder singleton pattern thread-safe without synchronized?**

A: The JVM specification (JLS 12.4.2) guarantees: if multiple threads attempt
to initialize the same class simultaneously, all but one are blocked until the
initializer completes. The thread that runs the initializer publishes the result
with a happens-before guarantee - all threads that access the initialized field
subsequently see the fully constructed object. The class holder creates the singleton
in a static field initializer: this creation is protected by the JVM's initialization
lock, with automatic happens-before. No `synchronized`, no `volatile` needed.

*What separates good from great:* The class holder pattern was popularized by Bill
Pugh. It's the cleanest lazy singleton in Java. Compare: (1) synchronized getInstance()
- works but every call acquires lock; (2) double-checked locking with volatile -
works but verbose; (3) enum singleton - works but prevents lazy init; (4) class
holder - works, lazy, no synchronization overhead on the fast path. The fast path
is: `return Holder.INSTANCE` - this is a static field read, no lock, no volatile
read (the happens-before from initialization covers it).

---

**Q3 (circular init): What happens with circular class initialization?**

A: If ClassA's static initializer triggers ClassB's initialization, which
needs ClassA - the JVM's initialization lock detects the cycle. The thread
initializing A also needs B, then B needs A. Since the same thread is already
initializing A (holding A's initialization lock), the JVM doesn't block
(that would deadlock). Instead: B sees A's partially initialized state
(static fields at their default values or partially assigned). This produces
incorrect results silently.

*What separates good from great:* The Java Memory Model specifies this
exactly: a thread that re-encounters a class being initialized by itself
(re-entrant initialization) proceeds with the partially initialized state.
The warning sign in code: static field of type X refers to static field of type Y,
and Y has a static field of type X. Fix: break the cycle by using lazy
initialization (compute on first method call rather than in static initializer)
or by restructuring to eliminate the circular dependency.

---

**Q4 (verification): What does bytecode verification check?**

A: The JVM verifier runs once at class load and checks: (1) magic number and
class file version are valid; (2) constant pool entries have correct types and
mutual references; (3) for each method: operand stack never overflows its
declared `max_stack`; no underflow (pop from empty stack); types match at each
instruction (iadd requires two int, invokevirtual requires object + args);
(4) local variable access is within declared `max_locals`; (5) all control flow
paths have consistent stack state at merge points (StackMapTable).

*What separates good from great:* The StackMapTable attribute (mandatory since
Java 7) pre-computes the expected type state at each branch target and exception
handler. Without it: verification required iterative fixed-point computation
(O(n^2) or worse). With StackMapTable: single-pass O(n) verification. Bytecode
generators (ASM with COMPUTE_FRAMES, Javassist) compute StackMapTable automatically.
Manual bytecode without StackMapTable: `VerifyError` in Java 7+ JVMs.

---

**Q5 (unloading): When is a class unloaded from the JVM?**

A: A class is unloaded when: (1) its defining ClassLoader is GC-eligible
(no live references to the ClassLoader object), AND (2) all Class objects for
classes loaded by that ClassLoader are GC-eligible (no live references to the
Class objects or their instances). In practice: application classes loaded by
the AppClassLoader are almost never unloaded (AppClassLoader is held by the main
thread). Classes loaded by custom ClassLoaders CAN be unloaded when the ClassLoader
is GC'd - critical for hot-reload and plugin systems.

*What separates good from great:* ClassLoader leaks prevent class unloading.
Classic leak: thread pool thread holds a ThreadLocal referencing an object of
a webapp class. When the webapp is undeployed: the WebappClassLoader can't be
GC'd because the thread pool holds a reference (via ThreadLocal) to a class
loaded by the WebappClassLoader. The WebappClassLoader references all webapp
classes (via the loaded class registry). Result: each deployment leaks the
entire webapp's classes into Metaspace -> eventual Metaspace OOM.
Fix: always call `ThreadLocal.remove()` and ensure thread pool threads
don't retain class references across redeploy.

---

**Q6 (forName): What does Class.forName() do and when would you use it?**

A: `Class.forName(className)` loads and initializes a class by name at runtime.
Use cases: JDBC driver loading (`Class.forName("org.postgresql.Driver")`),
plugin systems (load plugin class by name), reflection-based frameworks.
Variants: `Class.forName(name, false, classLoader)` - load but don't initialize
(useful for existence checks); `Class.forName(name, true, classLoader)` -
load and initialize with specific ClassLoader.

*What separates good from great:* `Class.forName("org.postgresql.Driver")` is
historical JDBC boilerplate. Since Java 6, JDBC 4.0 added ServiceLoader-based
auto-discovery: any JDBC driver JAR that contains `META-INF/services/java.sql.Driver`
is automatically loaded by `DriverManager` without explicit `Class.forName`.
Modern code doesn't need it. The ServiceLoader pattern (`java.util.ServiceLoader`)
is the standard for plugin discovery: define an interface, put implementations
in `META-INF/services/`, and `ServiceLoader.load(Interface.class)` discovers all.

---

**Q7 (lazy loading): Is class loading lazy or eager in the JVM?**

A: Lazy by specification: a class is initialized only when it is first actively used.
"Active use" triggers: creating an instance (`new Foo()`), calling a static method,
accessing a static field that's not a compile-time constant, class is the top-level
class containing `main()`, or reflection (`Class.forName()`). "Passive use" (does
NOT trigger): using a subclass, referencing a compile-time constant static field,
a class name in a type declaration.

*What separates good from great:* Understanding what counts as "active use"
prevents surprises. Compile-time constants (`static final String X = "literal"`)
are inlined by javac into every usage site - the class containing X might never
be loaded even if X is used. `static final int MAX_SIZE = 100` is inlined as the
literal `100` in all callers. `static final Integer MAX_SIZE = 100` is NOT a
compile-time constant (autoboxing) - the class is loaded when MAX_SIZE is used.
This distinction matters for lazy initialization and ClassLoader lifecycle.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: class loading lifecycle described adequately in Concept Explanation)*

---

---

## JVM Memory Areas

### 🎯 Model Answer

**30 seconds:**
> JVM has five memory areas: Heap (all objects, GC-managed), JVM Stack
> (per-thread frames with locals and operand stack), Method Area/Metaspace
> (class metadata, static fields), PC Register (per-thread program counter),
> and Native Method Stack (for JNI). Most tuning focuses on Heap (Xmx) and
> Metaspace. The JVM Stack causes StackOverflowError (deep recursion).
> The Heap causes OutOfMemoryError: Java heap space (memory leaks).

**3 minutes (Senior):**
> Heap is the primary GC-managed area. Divided into Young Generation (Eden +
> two Survivor spaces, for short-lived objects) and Old Generation (for
> long-lived objects). New objects are born in Eden. Minor GC promotes
> surviving objects through Survivors to Old Gen. Full GC collects the entire
> heap.
>
> Metaspace (Java 8+) replaced PermGen. Stores: class bytecode, constant pool,
> field descriptors, static field values, interned strings (in Java 7+ moved
> to heap). Grows dynamically from native OS memory (not JVM heap). Cap with
> `-XX:MaxMetaspaceSize`.
>
> JVM Stack: per-thread, LIFO stack of method frames. Each frame contains:
> local variable array, operand stack, reference to constant pool. Frame pushed
> on method entry, popped on return. Default size 256KB-1MB depending on platform.
> Increase with `-Xss` but every thread uses this memory.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Five JVM memory areas: Heap (objects), Metaspace (class data),
JVM Stack (per-thread frames), PC Register, Native Method Stack. Most important:
Heap and Metaspace for tuning."

**(2) First principles:** "A running program needs: code (instructions),
class definitions, active stack frames (current call chain), and heap data
(objects alive during execution). Each memory area serves one of these needs."

**(3) Bridge:** "JVM memory areas are like a company. Heap = the warehouse
(stores products = objects). Metaspace = the company handbook (class definitions,
rules). JVM Stack = the employees' desks (each thread's working memory). PC Register
= the employee's task list (current instruction). Native Stack = the contractor
office (JNI native code)."

---

### 📘 Concept Explanation

**Memory area details:**
```
HEAP (shared):
  Young Generation:
    Eden: new objects allocated here (TLAB per thread)
    Survivor 0, Survivor 1: objects surviving Minor GC
  Old Generation:
    Objects surviving multiple Minor GCs
    Large objects (humongous, if > region_size/2 in G1)
  Tuning: -Xms, -Xmx, -XX:NewRatio, -XX:SurvivorRatio

METASPACE (native memory, shared):
  Class bytecode and metadata
  Static field values (moved here from PermGen in Java 8)
  Interned strings (moved to HEAP in Java 7)
  Tuning: -XX:MaxMetaspaceSize (unlimited by default)

JVM STACK (per-thread):
  Stack of method frames
  Frame: local variables + operand stack + frame data
  Tuning: -Xss (default 256KB-1MB)
  Error: StackOverflowError

PC REGISTER (per-thread):
  Current bytecode instruction address
  Undefined for native methods

NATIVE METHOD STACK (per-thread):
  Stack for native (C/C++) method calls via JNI
  Tuning: -XX:MaxJNILocalRefSize
```

---

### 💻 Code Example

> **Code walkthrough:** `Runtime.getRuntime()` exposes basic heap stats,
> but JMX beans and JFR give more accurate data. The `jcmd VM.native_memory`
> command gives the complete JVM memory breakdown including off-heap components.

```java
// Checking heap memory programmatically:
Runtime rt = Runtime.getRuntime();
long maxHeap   = rt.maxMemory();     // -Xmx value
long totalHeap = rt.totalMemory();   // current heap (may be < maxHeap)
long freeHeap  = rt.freeMemory();    // free in current heap
long usedHeap  = totalHeap - freeHeap;

System.out.printf("Heap: used=%dMB, total=%dMB, max=%dMB%n",
    usedHeap / 1_000_000,
    totalHeap / 1_000_000,
    maxHeap / 1_000_000);

// Better: JMX memory beans
MemoryMXBean memBean = ManagementFactory.getMemoryMXBean();
MemoryUsage heapUsage = memBean.getHeapMemoryUsage();
System.out.printf("Heap used=%d max=%d%n",
    heapUsage.getUsed(), heapUsage.getMax());

// Metaspace via MemoryPoolMXBeans:
ManagementFactory.getMemoryPoolMXBeans().stream()
    .filter(p -> p.getName().contains("Metaspace"))
    .forEach(p -> System.out.println(p.getName() + ": " + p.getUsage()));

// JVM command-line tools:
// $ jcmd <pid> VM.native_memory
// Output:
// Total:  reserved=2.5GB, committed=400MB
// Java Heap (reserved=2GB, committed=256MB)
// Class (Metaspace reserved=1GB, committed=50MB)
// Thread (reserved=100MB, committed=100MB) <- all thread stacks
// Code (reserved=250MB, committed=20MB)    <- JIT compiled code cache
// GC (reserved=100MB, committed=30MB)
// Compiler, Internal, ...

// Note: VM.native_memory requires -XX:NativeMemoryTracking=summary or detail
// JVM startup flag: -XX:NativeMemoryTracking=summary
```

> **Code walkthrough:** `jcmd VM.native_memory` reveals the full picture:
> the JVM uses much more OS memory than just the Java heap. Code Cache stores
> JIT-compiled native code (capped by `-XX:ReservedCodeCacheSize`, default
> 240MB). Thread stacks are outside the heap. GC data structures are separate.
> Metaspace is outside the heap. When diagnosing "container OOM (memory limit
> exceeded)" even though `java.lang.OutOfMemoryError: Java heap space` hasn't
> been thrown: check native memory with `VM.native_memory` - the total JVM
> footprint exceeds the heap alone by 200-500MB typically.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Heap = objects, GC-managed, tuned with -Xmx. Metaspace = class metadata,
> unlimited by default. Stack = per-thread, holds method frames,
> StackOverflowError on deep recursion. Main tuning: set -Xms equal to -Xmx
> (avoid heap resize pauses), cap Metaspace to detect leaks.

---

**Senior / Staff (5+ years):**
> The total JVM footprint for container sizing is: heap + Metaspace + Code Cache
> + thread stacks + GC data structures + Direct Buffers. A JVM with `-Xmx4g` may
> consume 5-6GB of OS memory. Rule of thumb: add 500MB-1GB overhead to -Xmx for
> container memory limit. Modern alternative: `-XX:MaxRAMPercentage=75` lets the
> JVM auto-calculate heap based on container memory. Code Cache limit: if JIT
> compilation is disabled (code cache full), JVM falls back to interpreter -
> performance drops 10-100x. Monitor with: `jcmd <pid> Compiler.codecache` or
> JFR CodeCache events.

---

### ⚠️ Common Misconceptions

**Misconception 1: "The JVM heap includes all JVM memory."**
The heap is just one component. Total JVM process memory includes: Heap, Metaspace
(class data, outside heap), Code Cache (JIT native code), thread stacks (per-thread
outside heap), Direct Buffers (NIO, outside heap), JVM internal data structures.
Total JVM OS footprint = all of the above combined. Sizing containers: don't use
`-Xmx` as the container memory limit - add 500MB-1GB for non-heap overhead.

**Misconception 2: "PermGen and Metaspace are the same thing."**
Both store class metadata but are different implementations. PermGen (pre-Java 8):
fixed-size, part of the JVM heap (counted toward `-Xmx`), caused `OutOfMemoryError:
PermGen space`. Metaspace (Java 8+): native memory (outside the heap), dynamic size
(grows on demand), causes `OutOfMemoryError: Metaspace` only if `-XX:MaxMetaspaceSize`
is set and reached. The migration from Java 7 to 8: `PermGen space` errors stopped;
heap utilization decreased. Some blogs still confuse the two.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Container OOM kill despite no JVM OOM - JVM uses more memory than heap.**
```
Symptom: Kubernetes pod killed with OOMKilled exit code 137
  But: no java.lang.OutOfMemoryError in logs
  Heap usage looks healthy (<75% of Xmx)

Cause: Container memory limit < total JVM process memory
  JVM heap = 4GB (Xmx)
  Metaspace = 200MB
  Code Cache = 240MB
  Thread stacks = 100 threads * 1MB = 100MB
  Direct Buffers (Netty/NIO) = 500MB
  GC data = 100MB
  TOTAL JVM memory: ~5.1GB > container limit (5GB)

Diagnosis:
  1. jcmd <pid> VM.native_memory summary
     (needs -XX:NativeMemoryTracking=summary at startup)
  2. Or: /proc/<pid>/smaps | grep -i pss (Linux)
  3. Check JVM direct buffer usage:
     jcmd <pid> VM.native_memory | grep "Direct"

Fix:
  1. Add -XX:NativeMemoryTracking=summary to all production JVMs
  2. Use -XX:MaxRAMPercentage=75 (JVM auto-sizes heap to 75% of container)
  3. Cap Direct Buffers: -XX:MaxDirectMemorySize=256m
  4. Set -XX:MaxMetaspaceSize=256m
  5. Container limit = Xmx + 500MB at minimum
     Better: let MaxRAMPercentage handle it
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Five memory areas | 2 minutes |
| Heap regions | 2 minutes |
| Metaspace vs PermGen | 2 minutes |
| JVM Stack frame | 90 seconds |
| Container memory sizing | 2-3 minutes |
| Direct buffers | 2 minutes |
| Code Cache | 2 minutes |

---

**Q1 (five areas): Name the five JVM memory areas and their purpose.**

A: Heap (objects and arrays, GC-managed), Metaspace (class metadata, bytecode,
static fields, native memory), JVM Stack (per-thread LIFO of method frames),
PC Register (per-thread current instruction pointer), Native Method Stack
(per-thread stack for JNI native methods). Main tuning targets: Heap (-Xmx),
Metaspace (-XX:MaxMetaspaceSize), Stack (-Xss).

*What separates good from great:* "Shared vs per-thread" is the key distinction.
Shared: Heap, Metaspace (all threads access the same class definitions and objects).
Per-thread: JVM Stack, PC Register, Native Method Stack. This is why the Heap
needs synchronization (GC must pause all threads to collect), while stacks are
thread-local (no synchronization needed). Thread-safety in Java is about protecting
shared heap access - stack variables are inherently thread-safe (each thread has
its own stack).

---

**Q2 (heap young gen): What is the young generation and why does it exist?**

A: Young generation (Eden + two Survivor spaces) holds new objects. Most
objects die young (empirical observation: "generational hypothesis"). Minor GC
collects only the young gen - much faster than full GC. Objects surviving N
Minor GCs are promoted to old generation. Having a small, separate young gen
enables frequent, cheap garbage collection without touching long-lived objects.

*What separates good from great:* The two Survivor spaces are the copy mechanism.
Minor GC copies live objects from Eden and the "from" Survivor into the "to"
Survivor (or Old Gen if tenuring threshold reached). After Minor GC: Eden is
completely empty, "to" Survivor holds survivors, roles flip. This is a copying
GC for young gen: only live objects pay cost (dead objects are free). If Eden is
99% garbage after each cycle (common in high-throughput systems): collecting
Eden is very fast (only 1% copied). This is why high allocation rate doesn't
necessarily mean high GC overhead.

---

**Q3 (Code Cache): What is the Code Cache and why does it matter?**

A: The Code Cache stores JIT-compiled native machine code. When the JIT compiles
a hot method to native code, it stores the result here. Default maximum:
240MB (Java 11+). If the Code Cache fills: JVM prints "CodeCache is full"
and stops JIT compiling new methods - those methods execute in interpreter mode
(10-100x slower). Monitor: `jcmd <pid> Compiler.codecache`.

*What separates good from great:* Code Cache pressure is a real issue in large
applications with many hot methods. A complex Spring application with hundreds of
service classes, all hot: Code Cache fills after hours of steady load. Symptom:
gradual throughput degradation ("getting slower over time"). Diagnosis: JFR
CodeCache events, or `jcmd Compiler.codecache` showing "full". Fix: increase
with `-XX:ReservedCodeCacheSize=512m`. Also: `-XX:+UseCodeCacheFlushing` enables
the JVM to evict old compiled methods when cache is full (default: off in some
JVM versions, on in others).

---

**Q4 (TLAB): What is a TLAB?**

A: Thread-Local Allocation Buffer. Each thread has a small private portion of
Eden pre-allocated for its exclusive use. `new Object()` allocates by incrementing
a pointer within the TLAB - no locking needed (private to the thread). When TLAB
fills, the thread requests a new TLAB from the shared Eden (brief locking).
For typical workloads: 99%+ of allocations use TLAB (no lock), <1% require
new TLAB allocation from shared Eden. TLAB is transparent to Java code.

*What separates good from great:* TLAB size is automatically tuned by the JVM
based on allocation rate. `-XX:+PrintTLAB` shows TLAB statistics. If allocation
rate is very high: TLAB allocation becomes a bottleneck (frequent new TLAB
requests). This is when you see contention in TLAB statistics. Fix: reduce
object allocation (object pooling, reuse) or profile with JFR
`ObjectAllocationInNewTLAB` events to find the largest allocators.

---

**Q5 (direct buffers): What are Direct Buffers and how do they differ from heap?**

A: `ByteBuffer.allocateDirect(n)` allocates memory OUTSIDE the Java heap,
directly in OS native memory. Advantages: no GC pressure (not in heap), can
be directly mapped to DMA/network I/O (no copy between Java heap and OS kernel).
Used by Netty, Kafka, NIO selectors. Disadvantages: no GC tracking (manual release
via `((DirectBuffer) buf).cleaner().clean()`), counted against native memory, OOM
if `-XX:MaxDirectMemorySize` exceeded.

*What separates good from great:* Netty's PooledByteBufAllocator uses direct buffers
with its own slab allocator - avoiding Java heap entirely for network I/O buffers.
This eliminates: heap GC pressure from buffer objects, CPU overhead of copying
between heap and kernel buffer, JVM's inability to directly share heap memory
with OS (heap can move during GC). The result: Netty achieves kernel-bypass
network I/O efficiency. Diagnosing direct buffer leaks: `jcmd <pid> VM.native_memory`
shows "Direct" usage; `java.nio.BufferPoolMXBean` from JMX gives count and size.

---

**Q6 (Stack frame): What is in a JVM Stack frame?**

A: Each JVM Stack frame contains: (1) Local Variable Array - indexed slots
for method parameters and local variables; (2) Operand Stack - the working
"scratch pad" for bytecode instructions (push, pop operations); (3) Frame Data -
reference to the current method's constant pool, return address. Frame is
created when a method is invoked, popped when the method returns (normally or
via exception).

*What separates good from great:* The Local Variable Array slot 0 is `this`
for instance methods. Slots are typed (int, long, float, double, reference).
long and double take two slots (64-bit values). The max slot count is declared
in the class file (`max_locals`). Debuggers work by reading the Local Variable
Array from the stack frame - this requires `LocalVariableTable` attribute
(compiled with `-g` flag). Without `-g`: variables show as `slot_0`, `slot_1`
in debuggers - this is why production JARs should include debug info (minimal
overhead, huge debuggability improvement).

---

**Q7 (frame depth): How many stack frames can a thread have?**

A: Determined by `-Xss` (thread stack size) and the size of each frame.
A frame's size depends on `max_locals + max_stack` declared in the class file.
Default `-Xss` is 256KB-1MB (platform dependent). A typical method frame
(10 local variables, operand stack depth 5) uses roughly 100-200 bytes.
So: 1MB stack / 200 bytes per frame = ~5000 frames max before StackOverflowError.
For recursive algorithms: StackOverflow typically occurs at 500-2000 deep
depending on frame size.

*What separates good from great:* Tail-call optimization (TCO) would allow
infinite recursion by reusing the current frame for tail calls. The JVM
specification does NOT support TCO (unlike JVM-targeting Scala, which manually
transforms tail-recursive methods into loops at the compiler level via `@tailrec`).
In Java: convert deep recursion to explicit stack (`Deque<State>`) iteration.
Virtual threads (Java 21): use "continuation stacks" stored in the heap, not
OS thread stacks. A virtual thread's "stack depth" is limited by heap memory,
not `-Xss`. This allows virtual threads to have deeper call stacks than platform
threads without consuming OS memory per thread.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: memory areas described adequately in Concept Explanation)*

---

---

## Garbage Collection Fundamentals

### 🎯 Model Answer

**30 seconds:**
> GC automatically reclaims heap memory by finding objects with no live
> references and freeing that memory. The JVM starts from "GC roots"
> (static fields, local variables on the stack, JNI references) and traces
> all reachable objects. Unreachable objects are garbage. GC uses generations:
> Young Gen (short-lived objects), Old Gen (long-lived objects). Minor GC
> collects Young Gen (fast). Major/Full GC collects everything (slow, pauses
> longer).

**3 minutes (Senior):**
> GC algorithms differ in their approach to the core challenge: finding and
> reclaiming dead objects while minimizing application pause time. Three
> fundamental approaches:
> (1) Mark-and-sweep: mark live objects, sweep (free) unmarked. Problem:
> fragmentation. (2) Mark-compact: mark, then compact live objects to one end.
> No fragmentation, but requires more movement. (3) Copying GC: copy live objects
> to new region, discard old region. Young Gen uses copying (Eden -> Survivor).
>
> GC roots: the starting points for reachability tracing. Include: local
> variables and parameters on all thread stacks, static fields, JNI references,
> class loader references, monitor locks held by threads.
>
> Write barriers: when the application modifies a reference (stores an object
> pointer), the JVM's write barrier records this for the GC. G1 uses remembered
> sets (per-region reference tracking) via write barriers. Without write barriers:
> concurrent GC couldn't track reference changes happening during concurrent
> marking.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "GC fundamentals - GC roots, reachability tracing, mark/sweep/compact/copy
algorithms, generational hypothesis, Young vs Old Gen, Minor vs Major GC, stop-the-world."

**(2) First principles:** "You can't free memory while holding a reference to it.
GC finds all references (from roots), determines what's reachable, and frees everything
not reachable. The complexity is doing this efficiently while the application runs."

**(3) Bridge:** "GC is like a city waste management system. GC roots are the city
inhabitants. Live objects are things they actively use. Dead objects (garbage) are
unclaimed items. The GC crew (collector) visits every house (GC root), follows chains
(references), and marks what's used. Everything unmarked gets collected."

---

### 📘 Concept Explanation

**GC algorithm comparison:**
```
MARK AND SWEEP:
  1. Mark: traverse from GC roots, mark all reachable objects
  2. Sweep: free unmarked objects
  Downside: heap fragmentation (holes between live objects)

MARK AND COMPACT:
  1. Mark live objects
  2. Compact: move live objects to one end, update all references
  No fragmentation, enables fast bump-pointer allocation
  Downside: more CPU (update all references)

COPYING COLLECTOR (Young Gen):
  Two spaces (from, to). Live objects copied from -> to
  'from' space completely freed after copy
  Pro: fast (only live objects pay cost), no fragmentation
  Con: requires 2x the space

GENERATIONAL COLLECTION:
  Empirical observation: most objects die young
  Young Gen: frequent, fast Minor GC (copying)
  Old Gen: infrequent, slow Major GC (mark-compact)
  Efficiency: collect only young gen most of the time
```

---

### 💻 Code Example

> **Code walkthrough:** Common memory patterns show the generational behavior:
> short-lived objects (created and discarded in one request) stay in Eden and
> are collected cheaply. Long-lived objects (caches, Spring beans) are promoted
> to Old Gen. Understanding this separation is the foundation of GC tuning.

```java
// Short-lived object: dies in Young Gen (cheap to collect)
void processRequest(HttpRequest request) {
    // These objects are created and become garbage within this method:
    String body = request.getBody();           // String: short-lived
    Map<String, String> params = parse(body);  // HashMap: short-lived
    Response resp = buildResponse(params);     // Response: short-lived
    // When method returns: body, params, resp have no more references
    // -> eligible for GC in next Minor GC
    // Since they never left Eden/Survivor: collected cheaply
}

// Long-lived object: promoted to Old Gen (expensive to collect)
class UserCache {
    // This Map is created once and lives for the JVM lifetime:
    private final Map<Long, User> cache = new ConcurrentHashMap<>();
    // -> promoted from Young -> Survivor -> Old Gen after multiple Minor GCs
    // -> collected only during Full GC (expensive)
}

// Triggering GC manually (NOT recommended for production):
System.gc(); // HINT to JVM - JVM may ignore it
// DON'T: this is non-deterministic and often hurts performance
// DO: let the JVM's GC heuristics manage collection timing

// Observing GC activity:
// JVM flag for GC logging (Java 11+):
// -Xlog:gc*:file=/var/log/gc.log:time,uptime,level,tags:filecount=5,filesize=20m
// Sample output:
// [0.123s][info][gc] GC(0) Pause Young (Normal) (G1 Evacuation Pause) 20M->5M(256M) 3.123ms
// [0.456s][info][gc] GC(1) Pause Young (Normal) (G1 Evacuation Pause) 35M->8M(256M) 4.567ms
// Minor GC: "Pause Young", Major GC: "Pause Full"
// Shows: heap before -> after(max), pause duration
```

> **Code walkthrough:** The `-Xlog:gc*` unified logging format (Java 11+)
> replaces the old `-XX:+PrintGCDetails` and `-XX:+PrintGCDateStamps`.
> Each GC event shows: pause type (Young=Minor, Full=Major), cause, heap
> before and after GC, and pause duration. "20M->5M(256M) 3.123ms" means:
> heap was 20MB before, 5MB after, max heap is 256MB, pause was 3.1ms.
> Tracking this over time reveals: increasing "after GC" numbers = growing
> live set (potential leak), frequent Full GCs = Old Gen pressure.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> GC frees objects with no references. Starts from GC roots, marks reachable objects,
> frees the rest. Generational: Young Gen collected frequently (fast), Old Gen
> collected rarely (slow, pauses longer). Enable GC logging to observe.

---

**Senior / Staff (5+ years):**
> GC tuning is about matching the GC algorithm to the workload. High allocation
> rate with short lifetimes: maximize Young Gen size (large Eden, frequent Minor GC).
> Latency-sensitive API: ZGC or Shenandoah (sub-ms pauses). High-throughput batch:
> Parallel GC (maximum throughput, less latency concern). Mixed workload: G1
> (default, balances throughput and pause time). The key GC metric: "promoted
> live set size after full GC" should be stable. Growing live set = memory leak.
> GC pause time goal: P99 < 100ms for web APIs. ZGC achieves P99 < 1ms.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Setting a reference to null helps GC."**
Setting `obj = null` makes an object eligible for GC only if that was the LAST
live reference. In most cases, local variables go out of scope naturally (method
returns), making the object eligible without explicit nulling. The JIT compiler
may already treat a variable as dead if it's not used after a certain point.
Explicit `obj = null` is only useful in specific cases: a long-lived local variable
(in a long loop body) that you want GC-eligible before the loop ends.

**Misconception 2: "Full GC and Major GC mean the same thing."**
They're similar but not identical. Major GC specifically refers to collecting the
Old Generation. Full GC collects the ENTIRE heap (Young + Old + Metaspace cleaning).
A Full GC is always a stop-the-world event. A Major GC may be concurrent in modern
collectors (G1, ZGC concurrent marking, though the final pause is stop-the-world).
In G1: "Concurrent Mark Cycle" is the Major GC phase (mostly concurrent). "Full GC"
in G1 is the fallback when concurrent marking can't keep up (fully stop-the-world).

---

### 🚨 Failure Modes and Diagnosis

**Failure: GC overhead limit exceeded - application spends >98% time in GC.**
```
Symptom: java.lang.OutOfMemoryError: GC overhead limit exceeded
  Application extremely slow, GC runs continuously, <2% useful work

Cause: Memory leak or insufficient heap
  Heap nearly full -> frequent full GC -> cleans very little -> repeat
  JVM gives up after 98% time in GC threshold

Diagnosis:
  1. Enable GC logging: -Xlog:gc*:file=gc.log
  2. Check if heap usage AFTER full GC is increasing over time:
     grep "Pause Full" gc.log | awk '{print $NF}'  <- heap after GC
     If increasing: memory leak
  3. Take heap dump: jcmd <pid> GC.heap_dump /tmp/heap.hprof
  4. Analyze with Eclipse MAT: "Leak Suspects" report

Fix options:
  - Memory leak: fix the leak (common: unbounded cache, listener not removed)
  - Insufficient heap: increase -Xmx
  - Disable the overhead limit (NOT recommended, masks the real problem):
    -XX:-UseGCOverheadLimit

Common leak causes found via heap dump:
  - Unbounded HashMap used as a cache
  - EventListener registered but never removed
  - ThreadLocal not cleared in thread pool
  - Session objects not invalidated (HTTP sessions)
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| GC roots | 2 minutes |
| Mark-sweep-compact | 2 minutes |
| Generational hypothesis | 2 minutes |
| Minor vs Major GC | 2 minutes |
| GC overhead limit | 2 minutes |
| Write barriers | 2 minutes |
| Choosing a GC | 2 minutes |

---

**Q1 (GC roots): What are GC roots?**

A: GC roots are the starting points for reachability analysis. The JVM considers
an object alive if it is reachable from any GC root through a chain of references.
GC roots include: local variables and parameters on all running thread stacks,
static fields of loaded classes, JNI references (native code holding Java object
references), references from the JVM itself (class loader references, monitors
held by threads), Finalizer queue references.

*What separates good from great:* Thread stack roots are why thread-local state
can prevent GC. A `ThreadLocal<Connection>` in a thread pool: the connection is
referenced by the ThreadLocal, which is referenced by the thread's stack. The
thread is always live (it's a pool thread). The ThreadLocal is a GC root via the
thread stack. The Connection never becomes unreachable. If you add 1000 connections
to the ThreadLocal without removing them: 1000 connections leak. This is why
`ThreadLocal.remove()` in a finally block is mandatory.

---

**Q2 (generational): Why is generational GC more efficient?**

A: The generational hypothesis: most objects die young (created in one request,
used briefly, then abandoned). Only a small fraction live long enough to be
promoted to Old Gen. By collecting Young Gen frequently (Minor GC: 1-10ms)
and Old Gen rarely (Full GC: 100ms-seconds): the GC does frequent, cheap
work on the majority of garbage instead of frequently doing expensive full
heap scans. The cost of a Minor GC is proportional to LIVE objects (copied to
Survivor/Old), not dead objects. If 95% of Eden is garbage, Minor GC is fast.

*What separates good from great:* The generational hypothesis holds for most
workloads but fails for: object pooling (objects are intentionally long-lived),
large caches (explicitly long-lived), event sourcing (events may be held until
processed), and some functional programming styles (immutable data structures
allocate heavily but some live long). For these workloads: generational GC still
works but efficiency drops. A cache that fills Old Gen and causes frequent Full
GC has higher GC overhead than if it were in a bounded off-heap cache (Ehcache,
Caffeine off-heap).

---

**Q3 (write barrier): What is a write barrier in GC?**

A: A write barrier is code injected by the JIT compiler around every reference
store (`obj.field = otherObject`). It notifies the GC that a reference has changed.
In G1 GC: the write barrier maintains "Remembered Sets" - for each heap region,
a set of pointers INTO that region from other regions. When Minor GC collects
Young Gen, it must also scan Old-to-Young references (old objects may reference
young objects). Instead of scanning all of Old Gen: G1 uses Remembered Sets
to find only those Old Gen cards that reference Young Gen.

*What separates good from great:* Write barriers have performance implications.
Every reference store executes the write barrier code. For high-allocation
workloads: millions of write barriers execute per second. Barrier overhead is
typically 2-5% of CPU for normal workloads, can reach 10%+ for write-heavy
workloads. ZGC and Shenandoah use different barrier types: load barriers (read
barriers on object reference reads) for their concurrent relocation schemes.
G1 uses write barriers for remembered sets. The choice of GC affects application
code performance even when GC isn't running.

---

**Q4 (Minor vs Major): When does a Minor GC happen vs a Major/Full GC?**

A: Minor GC: triggered when Eden is full. Collects Young Gen only (Eden + one
Survivor). Fast: 1-30ms typical. Objects surviving enough Minor GCs are promoted
to Old Gen. Major GC: triggered when Old Gen is full, or when G1/ZGC's concurrent
marking detects Old Gen occupancy above threshold. Full GC: stop-the-world
collection of entire heap. Triggered when concurrent GC can't keep up (allocation
rate exceeds collection rate) or explicitly via `System.gc()`.

*What separates good from great:* The "promotion failure" condition is when
old generation has no room for surviving young generation objects. Minor GC
tries to promote objects to Old Gen -> Old Gen full -> triggers Full GC immediately.
The fix: increase old gen size (change `-XX:NewRatio`), reduce promotion rate
(tune survivor spaces to hold more objects longer), or reduce the long-lived
object set (cache eviction). Monitoring: G1 GC log shows "to-space exhausted"
and "promotion failed" messages when this occurs.

---

**Q5 (finalization): How does finalization interact with GC?**

A: `Object.finalize()` (deprecated Java 9, removed Java 18) added overhead to GC:
objects with finalizers could not be immediately reclaimed. When GC finds a
finalizable object with no live references: it's placed in the "F-Queue" (finalizer
queue) and kept alive. The JVM's Finalizer thread calls `finalize()`. Only after
finalization does the object become truly GC-eligible. This delayed collection
caused: heap pressure, long GC pauses, unpredictable resource release.
Modern alternative: `AutoCloseable` + try-with-resources for resource management.
`java.lang.ref.Cleaner` (Java 9+) for post-GC cleanup without the finalizer overhead.

*What separates good from great:* The Cleaner API is the correct replacement
for `finalize()`. It uses weak references: when the object becomes weakly
reachable (no strong references), the Cleaner runs the registered cleanup action.
Unlike `finalize()`, the Cleaner action runs in a separate thread with a defined
lifecycle and doesn't participate in the finalization slowdown. For resources
(files, connections): still prefer explicit `close()` via try-with-resources.
Cleaner is a safety net for cases where `close()` might be forgotten - it's not
a replacement for explicit resource management.

---

**Q6 (STW): What is stop-the-world (STW) and why does it happen?**

A: Stop-the-world (STW) is when the JVM pauses ALL application threads to
perform GC operations safely. Required for operations that need a consistent
snapshot of the heap: compacting live objects (all references to moved objects
must be updated - can't do this while application is modifying references),
final marking phase (ensure all live objects are found), and class unloading.
Duration: 1ms (ZGC) to 30+ seconds (large Full GC with Parallel GC).

*What separates good from great:* Modern GC algorithms minimize STW by making
most operations concurrent. G1: concurrent marking, concurrent cleanup. ZGC:
concurrent relocation using colored pointers (load barriers redirect reads to
new object location, no STW for relocation). Shenandoah: concurrent relocation
using forwarding pointers. The residual STW phases in G1/ZGC are 1-10ms
(initial/final mark, initial/final cleanup). ZGC achieves <1ms STW by moving
GC's need for consistent heap views from STW to load barriers. Tradeoff: load
barriers add ~3% overhead to every object read.

---

**Q7 (choosing GC): How do you choose a garbage collector?**

A:
- **Serial GC** (`-XX:+UseSerialGC`): single-threaded. Use for: single-core VMs, client apps.
- **Parallel GC** (`-XX:+UseParallelGC`): multi-threaded STW. Use for: batch processing, maximum throughput, pause time not critical.
- **G1 GC** (default): balanced. Use for: most production services, heap 4GB+, acceptable pause time < 200ms.
- **ZGC** (`-XX:+UseZGC`): sub-millisecond pauses. Use for: latency-critical services, heap 8GB+, trading latency for throughput.
- **Shenandoah** (`-XX:+UseShenandoahGC`): similar to ZGC, Red Hat maintained.

*What separates good from great:* G1's default pause target is 200ms (`-XX:MaxGCPauseMillis=200`).
Reducing this target increases GC frequency and CPU overhead (GC runs more often
to keep pauses short). Setting it to 50ms: more frequent GC, more CPU consumed.
Setting it to 500ms: less frequent GC, less CPU, but longer pauses. ZGC's pause
target is not configurable - it's always sub-ms regardless. The trade-off: ZGC
uses more CPU for concurrent operations (concurrent relocation, load barriers)
but never pauses >1ms. For a streaming API at P99 < 10ms latency: ZGC is the
right choice despite higher CPU overhead.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: GC concepts described adequately in Concept Explanation)*
