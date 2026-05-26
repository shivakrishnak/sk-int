---
layout: default
title: "Java JVM - L1 Foundations"
parent: "Java JVM"
nav_order: 2
permalink: /java-jvm/l1-foundations/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [JVM Memory Areas](#jvm-memory-areas) | high |
| 2 | [Heap vs Stack](#heap-vs-stack) | high |
| 3 | [Object Lifecycle in JVM](#object-lifecycle-in-jvm) | high |
| 4 | [Class Loading Basics](#class-loading-basics) | high |
| 5 | [Metaspace and Method Area](#metaspace-and-method-area) | high |

---

# JVM Memory Areas

**Interview Weight:** high - Fundamental JVM knowledge. Tests
ability to classify memory concerns (OOM types, leaks) by area.

---

### 🎯 Model Answer

**30 seconds:**

> The JVM has five main memory areas: (1) Heap - object instances,
> GC-managed; (2) Stack - per-thread frames with local variables;
> (3) Metaspace - class metadata (Java 8+, replaced PermGen);
> (4) Code Cache - JIT-compiled native code; (5) Native Memory -
> direct buffers, JNI code, thread stacks. Each has a distinct
> OOM type: heap = `OutOfMemoryError: Java heap space`,
> metaspace = `OOM: Metaspace`, code cache = JIT deoptimization.

**3 minutes (Senior):**

> **Heap**: young generation (Eden + S0/S1) + old generation.
> Configured by `-Xms` (initial) and `-Xmx` (max). Shared across
> threads. GC-managed. OOM when heap is full and GC cannot reclaim
> enough.
>
> **Stack**: each thread has its own stack. Each method call creates
> a stack frame (local variables, operand stack, return address).
> Default size: 512KB-1MB per thread. 1,000 threads = 1GB stack.
> `StackOverflowError` = recursion too deep. OOM `unable to create
> new native thread` = OS thread limit or native memory exhausted.
>
> **Metaspace**: class metadata (class structure, method bytecode,
> constant pool). Not in heap - in native memory. Unbounded by
> default (can grow without limit). Set `-XX:MaxMetaspaceSize=256m`
> to cap it. OOM: Metaspace = too many loaded classes (classloader
> leak or dynamic code generation).
>
> **Code Cache**: JIT-compiled native code. Default: 240MB. If full,
> JIT compilation stops; methods deoptimize to interpreter. Symptom:
> sudden throughput drop after high class loading activity.
>
> **Direct (off-heap) Memory**: `ByteBuffer.allocateDirect()`, NIO
> channels, Netty. Outside Java heap, GC cannot manage it directly.
> Leaked direct buffers cause native OOM. Sized by `-XX:MaxDirectMemorySize`.

---

### 💻 Code Example

**Example 1: Monitoring each memory area**

```java
// Monitor heap
MemoryMXBean mem = ManagementFactory.getMemoryMXBean();
MemoryUsage heap = mem.getHeapMemoryUsage();
System.out.printf("Heap used: %dMB / max: %dMB%n",
    heap.getUsed()/(1024*1024), heap.getMax()/(1024*1024));

// Monitor Metaspace (non-heap)
MemoryUsage nonHeap = mem.getNonHeapMemoryUsage();
System.out.printf("NonHeap (Metaspace+CodeCache): %dMB%n",
    nonHeap.getUsed()/(1024*1024));

// Monitor per-pool breakdown (Eden, Old, Metaspace, CodeCache)
for (MemoryPoolMXBean pool : ManagementFactory.getMemoryPoolMXBeans()) {
    System.out.printf("%-30s  used=%6dMB  max=%6dMB%n",
        pool.getName(),
        pool.getUsage().getUsed()/(1024*1024),
        pool.getUsage().getMax()/(1024*1024));
}

// OOM triggers (diagnostic only)
// java.lang.OutOfMemoryError: Java heap space
//     → -Xmx too small, or memory leak
// java.lang.OutOfMemoryError: Metaspace
//     → classloader leak, -XX:MaxMetaspaceSize exceeded
// java.lang.OutOfMemoryError: unable to create native thread
//     → too many threads, OS limit, stack size too large
// java.lang.OutOfMemoryError: Direct buffer memory
//     → ByteBuffer.allocateDirect() leak, -XX:MaxDirectMemorySize exceeded
```

> **Code walkthrough:** `MemoryPoolMXBean` gives per-area metrics.
> The `max` value for Eden is typically -1 (unknown) because G1 uses
> adaptive region sizing. The OOM error message tells you exactly
> which area is exhausted - essential for diagnosis. `Java heap
> space` = look for leaks or increase `-Xmx`. `Metaspace` = look
> for classloader leaks or dynamic class generation without cleanup.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JVM has heap (objects, GC-managed), stack (per-thread frames),
> metaspace (class metadata), code cache (JIT code), and native
> memory. Different OOM errors correspond to different areas.

---

**Senior / Staff (5+ years):**

> The production OOM I see most often is `Metaspace` from classloader
> leaks in applications that use reflection-heavy frameworks or
> dynamic proxies (Spring, Hibernate). The second most common is
> `unable to create native thread` - caused by too many threads
> exhausting the OS pid limit or virtual address space.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "You see OutOfMemoryError: Metaspace in production. How do
  you diagnose it?"

🗣️ "Metaspace OOM means too many class definitions are loaded.
Common causes: (1) classloader leak - frameworks that create new
classloaders (hot deployment, OSGi, custom classloaders) without
unloading the old ones. Classes are retained as long as their
classloader is live. (2) Excessive dynamic proxy generation (Spring
AOP, CGLIB, Javassist) creates new classes at runtime. (3) Scripts
or Groovy code evaluated in a loop, each evaluation creating new
classes. Diagnostic: enable `-verbose:class` or JFR ClassLoad
event to count class loading. Look for classloader instances in
a heap dump - if the same application classloader has thousands of
instances, it is leaked. Fix: ensure custom classloaders are closed,
or increase `-XX:MaxMetaspaceSize` as a temporary measure."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Five areas, OOM error types, direct memory. |
| Hiring Manager   | OOM diagnosis - mapping error to root cause. |
| Bar Raiser       | Compressed OOPs, code cache deoptimization, off-heap libraries. |
| Peer Engineer    | "Our Metaspace grew to 2GB before crashing - classloader leak..." |

---

---

# Heap vs Stack

**Interview Weight:** high - First-principles question. Tests
understanding of where objects live and why stack allocation is
faster.

---

### 🎯 Model Answer

**30 seconds:**

> Stack: per-thread, LIFO, holds primitive values and object
> references. Fast (just move a pointer). Automatic cleanup when
> method returns. Heap: shared across threads, holds object instances.
> Slower to allocate (GC-managed bump pointer). GC determines
> lifetime. Primitives (int, long, boolean) are on the stack if
> declared as local variables; objects (even wrapped Integer) are
> on the heap (usually, unless escape analysis optimizes them away).

**3 minutes (Senior):**

> Stack allocation mechanics: each method push creates a stack
> frame. The frame contains: local variable array, operand stack
> (JVM's "scratch space"), and a reference to the constant pool.
> Allocation = increment stack pointer. Deallocation = decrement
> stack pointer (when method returns). No GC involvement.
>
> Heap allocation mechanics: the JVM uses bump-pointer allocation
> in Eden (fast - increment a pointer). Allocation = increment
> Eden top-of-heap pointer. If Eden fills → Minor GC. Live objects
> moved to Survivor; dead objects reclaimed. Repeated survivors
> eventually promoted to Old generation.
>
> Escape analysis: the JIT can allocate objects on the stack if
> they are provably non-escaping (they do not outlive the method).
> Enabled by default since Java 6 (`-XX:+DoEscapeAnalysis`). Benefit:
> no GC pressure for short-lived objects. Example: `new Point(x, y)`
> used only within a method - JIT replaces heap allocation with
> stack "scalar replacement" (field values stored in local variables).
>
> `StackOverflowError` vs `OutOfMemoryError: Java heap space`:
> `StackOverflowError` = recursion too deep, stack exceeded.
> `OOM: heap space` = heap exhausted, GC cannot free enough memory.

---

### 💻 Code Example

**Example 1: Stack vs heap allocation patterns**

```java
// STACK: local primitives and references (not the objects they point to)
void compute() {
    int x = 5;              // stack: primitive value
    String msg = "hello";   // stack: reference; "hello" is in heap/string pool
    Point p = new Point(1,2); // stack: reference; Point object is on HEAP
}
// After compute() returns: x, msg, p are gone (stack frame popped)
// The Point object may be GC'd (no live references)

// HEAP: objects, whether local or field
class Service {
    private Map<String, String> config = new HashMap<>();  // HEAP: config lives as long as Service
}

// ESCAPE ANALYSIS: stack scalar replacement (JIT optimization)
void process(int x, int y) {
    Point p = new Point(x, y);  // may be stack-replaced if p doesn't escape
    return p.x + p.y;           // p stays local: JIT replaces with x+y
}
// -XX:+EliminateAllocations (default enabled) triggers this

// STACK OVERFLOW: deep recursion
int factorial(int n) {
    return n * factorial(n - 1);  // missing base case = StackOverflowError
}

// HEAP OOM: allocation faster than GC
List<byte[]> leak = new ArrayList<>();
while (true) {
    leak.add(new byte[1024 * 1024]);  // 1MB per iteration - OutOfMemoryError: heap space
}
```

> **Code walkthrough:** Local variable `p` holds a reference (8 bytes
> on the stack for a 64-bit JVM with compressed OOPs). The actual
> `Point` object is on the heap. When `compute()` returns, `p` is
> gone, and the `Point` becomes GC-eligible. Escape analysis can
> prove that `p` in `process()` never escapes (no return, no field
> assignment) and replace the heap allocation with scalar variables.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Primitives and references are on the stack per-method. Objects
> are on the heap, shared, GC-managed. Stack is faster because
> allocation is just a pointer increment. StackOverflowError = too
> deep recursion; OOM = heap full.

---

**Senior / Staff (5+ years):**

> Escape analysis is important in high-throughput code. Short-lived
> value objects (coordinates, request contexts) are often eligible
> for stack/scalar replacement - zero GC pressure. I measure with
> JFR allocation profiling to see actual object allocation hotspots.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What determines whether an object is on the stack or heap?"

🗣️ "By default, all Java objects are on the heap. Object references
(pointers) are on the stack when they are local variables. The JIT's
escape analysis can optimize objects onto the stack via scalar
replacement: if the JIT proves an object never escapes the creating
method (not returned, not stored in a field, not passed to another
method that stores it), it decomposes the object into individual
fields stored as local variables (on the stack). This is an
optimization, not a language guarantee. Primitives declared as
local variables are always on the stack. Primitives declared as
object fields are on the heap (as part of the object)."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Stack frame structure, bump-pointer allocation, escape analysis. |
| Hiring Manager   | OOM types and their causes. |
| Bar Raiser       | Compressed OOPs, scalar replacement, stack-allocated lambdas. |
| Peer Engineer    | "Our hot path was allocating 10M objects/sec - escape analysis saved us..." |

---

---

# Object Lifecycle in JVM

**Interview Weight:** high - Tests understanding of object creation,
promotion, finalization, and weak/soft/phantom reference semantics.

---

### 🎯 Model Answer

**30 seconds:**

> Object lifecycle: allocation (Eden), survival (GC → Survivor),
> promotion (after N GCs → Old generation), death (GC determines
> unreachable, reclaims memory). `finalize()` is deprecated and
> slow. Use try-with-resources instead. `WeakReference` allows GC
> to collect the object. `SoftReference` allows GC to collect when
> memory pressure is high. `PhantomReference` enables post-finalization
> cleanup (off-heap resource management).

**3 minutes (Senior):**

> Object creation steps: (1) `new` bytecode allocates memory in
> Eden using bump-pointer (thread-local allocation buffer = TLAB).
> (2) Default-initializes fields (numerics to 0, references to null).
> (3) Calls constructor. (4) Returns reference.
>
> TLAB: each thread has a private buffer in Eden. Allocations within
> TLAB are bump-pointer: no synchronization needed. When TLAB fills,
> the thread requests a new TLAB from Eden.
>
> Promotion: object survives Minor GC → copied to Survivor space.
> After `MaxTenuringThreshold` GCs (default: 15 for G1), object
> moves to Old. Premature promotion: objects promoted before dying
> cause Old to fill and trigger Major GC. Symptom: Old generation
> growing faster than expected.
>
> Reference types:
> - `WeakReference<T>`: GC collects the referent the next time it
>   finds it unreachable. Used for weak caches (entry removed when
>   key is no longer referenced externally).
> - `SoftReference<T>`: GC may retain until memory pressure is high.
>   Use for caches that should grow to fill available memory.
> - `PhantomReference<T>`: referent was finalized but not yet
>   reclaimed. Used for cleanup actions (close NIO resources after
>   GC). Must be used with a `ReferenceQueue`.

---

### 💻 Code Example

**Example 1: Object creation, reference types, and TLAB**

```java
// TLAB allocation (invisible to developer - automatic optimization)
// Each thread writes to its own TLAB segment of Eden
// Only when TLAB fills does synchronization occur for a new TLAB segment

// Reference type cache example
class ImageCache {
    // SoftReference cache: grows when memory available, shrinks under pressure
    private final Map<String, SoftReference<byte[]>> cache = new HashMap<>();

    public byte[] get(String key) {
        SoftReference<byte[]> ref = cache.get(key);
        if (ref != null) {
            byte[] img = ref.get();  // null if GC collected under memory pressure
            if (img != null) return img;
            cache.remove(key);       // clean stale entry
        }
        byte[] img = loadFromDisk(key);
        cache.put(key, new SoftReference<>(img));
        return img;
    }
}

// WeakReference for canonical maps (entries GC'd when key is unreachable)
Map<Key, WeakReference<Resource>> weakCache = new WeakHashMap<>();
// WeakHashMap: keys are weak; when key is GC'd, entry is removed automatically

// PhantomReference for off-heap resource cleanup (Java 9 Cleaner API)
class DirectBuffer {
    private final Cleaner.Cleanable cleanable;

    DirectBuffer(long address, long size) {
        cleanable = CleanerHolder.CLEANER.register(this,
            new DeallocateAction(address, size)  // cleanup action (lambda)
        );
    }
    // When DirectBuffer is GC'd, the Cleaner calls DeallocateAction.run()
    // This frees the off-heap memory
    static class DeallocateAction implements Runnable {
        private final long address, size;
        DeallocateAction(long address, long size) {
            this.address = address; this.size = size;
        }
        public void run() { unsafe.freeMemory(address); }
    }
}
```

> **Code walkthrough:** `SoftReference` caches are perfect for
> image/file caches: the JVM retains soft-referenced objects as
> long as memory is available and clears them before throwing OOM.
> The `WeakHashMap` automatically removes entries when the key object
> is only weakly referenced - no manual cache eviction needed.
> The `Cleaner` API (Java 9) uses phantom references under the hood
> to execute cleanup actions after GC.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Objects start in Eden, survive to Survivor, then Old. GC reclaims
> unreachable objects. Weak, Soft, and Phantom references control
> how aggressively GC can reclaim the referent.

---

**Senior / Staff (5+ years):**

> TLAB is the key to understanding why Eden allocation is essentially
> free: each thread owns a private buffer, no synchronization needed
> until the buffer fills. Premature promotion is a common GC
> performance problem: short-lived objects that survive Minor GC
> due to timing promote to Old unnecessarily. Increase Eden size or
> tune `MaxTenuringThreshold` to reduce it.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What is the difference between WeakReference and SoftReference?"

🗣️ "`WeakReference` is collected as soon as the GC determines
the referent has no strong references - on the next GC cycle.
`SoftReference` is collected when the JVM needs memory: before
throwing `OutOfMemoryError`, the JVM clears all soft references.
Use `WeakReference` for caches where you want entries to be
collected as soon as the key is no longer in use by any other code
- `WeakHashMap` uses this model. Use `SoftReference` for caches
where you want entries retained as long as memory is available -
a page cache or thumbnail cache that should grow to fill available
memory and shrink under pressure."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | TLAB, promotion thresholds, reference types. |
| Hiring Manager   | Cache strategies using SoftReference/WeakReference. |
| Bar Raiser       | Premature promotion, Cleaner API vs finalize(), ReferenceQueue. |
| Peer Engineer    | "Our image cache held SoftReferences but the cache kept getting cleared..." |

---

---

# Class Loading Basics

**Interview Weight:** high - Foundation for understanding hot
deployment, OSGI, and classloader leaks.

---

### 🎯 Model Answer

**30 seconds:**

> The class loader reads .class bytecode from the classpath and
> creates a `Class<?>` object in the JVM. Three phases: loading
> (find and read the .class file), linking (verify bytecode safety,
> prepare static fields, resolve symbolic references), and
> initialization (run static initializers). Class loaders follow
> parent delegation: check parent first, then load locally.
> A class is uniquely identified by (class name, classloader pair).

**3 minutes (Senior):**

> The delegation model prevents duplicate definitions from
> different classloaders accidentally conflicting. The Bootstrap
> ClassLoader (C code, no Java parent) loads core JDK classes
> (java.lang, java.util). Platform ClassLoader (Java 9+) loads
> JDK extensions. App ClassLoader loads the application classpath.
>
> When `loadClass("com.example.Foo")` is called:
> 1. Check `this.findLoadedClass()` - is it already loaded?
> 2. Delegate to parent: `parent.loadClass("com.example.Foo")`
> 3. If parent throws `ClassNotFoundException`: try `this.findClass()`
>
> This means java.lang.String is always loaded by Bootstrap -
> application classloaders cannot override core classes.
>
> Static initialization: runs exactly once, the first time the
> class is accessed. Order: parent class first, then child.
> A static initializer that throws causes `ExceptionInInitializerError`
> and makes the class permanently broken (`NoClassDefFoundError`
> on subsequent attempts).

---

### 💻 Code Example

**Example 1: ClassLoader inspection and custom loading**

```java
// Inspect classloader hierarchy
Class<?> stringClass  = String.class;
Class<?> appClass     = MyService.class;

System.out.println(stringClass.getClassLoader());
// null → loaded by Bootstrap ClassLoader (native - no Java object)

System.out.println(appClass.getClassLoader());
// jdk.internal.loader.ClassLoaders$AppClassLoader@...

System.out.println(appClass.getClassLoader().getParent());
// jdk.internal.loader.ClassLoaders$PlatformClassLoader@...

// Dynamic class loading from URL
URL[] urls = { new File("/plugin/feature.jar").toURI().toURL() };
try (URLClassLoader pluginCL = new URLClassLoader(urls,
        Thread.currentThread().getContextClassLoader())) {
    Class<?> featureClass = pluginCL.loadClass("com.plugin.Feature");
    Object feature = featureClass.getDeclaredConstructor().newInstance();
    // Cast to known interface (interface loaded by parent CL)
}
// URLClassLoader is AutoCloseable: close releases jar file handles

// Class identity: same name, different classloaders = different class
Class<?> c1 = cl1.loadClass("com.example.Foo");
Class<?> c2 = cl2.loadClass("com.example.Foo");
System.out.println(c1 == c2);  // FALSE - different Class objects
System.out.println(c1.isInstance(c2.newInstance()));  // FALSE - cast fails!
```

> **Code walkthrough:** `String.getClassLoader()` returns null
> because Bootstrap ClassLoader is native (no Java object). `URLClassLoader`
> is the standard way to load plugins from JAR files. Closing it
> releases the file handle. The class identity check illustrates
> why classloader leaks cause `ClassCastException`: the same
> fully-qualified name loaded by different classloaders is NOT
> the same class in the JVM's eyes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> ClassLoader finds .class files and loads them into the JVM.
> Three phases: load, link, initialize. Parent delegation: Bootstrap
> → Platform → App. A class is loaded only once per classloader.

---

**Senior / Staff (5+ years):**

> The class identity rule (name + classloader = identity) is critical
> for understanding hot deployment and plugin architectures. A fresh
> `URLClassLoader` for each plugin version means the plugin can be
> updated without restarting the JVM - but the old classloader
> must be closed and all references to old classes released,
> or Metaspace leaks.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "How does parent delegation work and why does it matter?"

🗣️ "When a classloader is asked to load a class, it first asks
its parent to load it. If the parent fails with
`ClassNotFoundException`, only then does the classloader try its
own classpath. The chain: App ClassLoader → Platform ClassLoader
→ Bootstrap ClassLoader. Bootstrap is asked first for every class.
Why it matters: it prevents duplicate definitions of core classes.
If the App ClassLoader could load its own version of
`java.lang.String`, the JVM would have two incompatible String
types and every cast involving String would fail. Parent delegation
ensures that `java.lang` classes come exclusively from the Bootstrap
ClassLoader."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Three phases, delegation chain, class identity rule. |
| Hiring Manager   | Hot deployment and plugin loading patterns. |
| Bar Raiser       | Context classloader, ServiceLoader, OSGi vs modules. |
| Peer Engineer    | "We got ClassCastException even though the class names matched - classloader isolation..." |

---

---

# Metaspace and Method Area

**Interview Weight:** high - Production concern: classloader leaks
fill Metaspace, causing OOM. Tests understanding of what lives
in Metaspace and how to monitor it.

---

### 🎯 Model Answer

**30 seconds:**

> Metaspace (Java 8+) stores class metadata: class definitions,
> method bytecode, field descriptors, constant pools, and interned
> strings (interned strings moved to heap in Java 7). Before Java 8,
> this was "PermGen" - a fixed-size heap region. Metaspace is in
> native memory and grows dynamically (no fixed limit by default).
> OOM: Metaspace occurs when classloaders are not garbage collected,
> accumulating class definitions without bound.

**3 minutes (Senior):**

> What lives in Metaspace:
> - Class structures (field names, types, methods)
> - Method bytecode (bytecode for all compiled methods)
> - Constant pool entries (string literals, class references)
> - Annotations metadata
> - JVM-internal class data structures
>
> What does NOT live in Metaspace:
> - Object instances (heap)
> - Class-level (static) fields' values: static reference fields
>   live on the heap as part of the class object
> - String literals (Java 7+): in the heap string pool
>
> Metaspace GC: class metadata is reclaimed when its ClassLoader
> becomes unreachable AND all Class objects loaded by it become
> unreachable. If any reference to any class or its ClassLoader
> is alive, the entire ClassLoader and ALL its classes are pinned
> in Metaspace. This is the classloader leak mechanism.
>
> Tuning flags:
> - `-XX:MetaspaceSize=N`: initial metaspace size (triggers GC when exceeded)
> - `-XX:MaxMetaspaceSize=N`: hard cap (prevents runaway native memory)
> - `-XX:MinMetaspaceFreeRatio=N`: target free ratio after GC
>
> PermGen vs Metaspace: PermGen was heap-allocated with a fixed max
> (`-XX:MaxPermSize=256m`). OOM:PermSpace was a common pre-Java 8
> problem. Metaspace in native memory avoids the fixed-size problem
> but makes the cap explicit: always set `-XX:MaxMetaspaceSize`.

---

### 💻 Code Example

**Example 1: Metaspace monitoring and leak detection**

```java
// Monitor Metaspace programmatically
for (MemoryPoolMXBean pool : ManagementFactory.getMemoryPoolMXBeans()) {
    if (pool.getName().toLowerCase().contains("metaspace")) {
        MemoryUsage usage = pool.getUsage();
        System.out.printf("Metaspace: used=%dMB, committed=%dMB, max=%s%n",
            usage.getUsed()/(1024*1024),
            usage.getCommitted()/(1024*1024),
            usage.getMax() < 0 ? "unlimited" : usage.getMax()/(1024*1024)+"MB"
        );
    }
}

// Detect Metaspace leak: count loaded classes
ClassLoadingMXBean clBean = ManagementFactory.getClassLoadingMXBean();
System.out.println("Loaded classes:   " + clBean.getLoadedClassCount());
System.out.println("Unloaded classes: " + clBean.getUnloadedClassCount());
System.out.println("Total loaded:     " + clBean.getTotalLoadedClassCount());
// If loadedClassCount grows continuously with no decrease -> leak

// JVM flags to cap and monitor Metaspace
// -XX:MaxMetaspaceSize=256m  (always set in production)
// -XX:+PrintGCDetails        (logs Metaspace sizes on GC)
// -Xlog:class+load=info      (Java 9+: log every class load)
// -XX:+TraceClassLoading     (legacy: log class loading)

// Heap dump to find leaked classloaders
// jmap -dump:live,format=b,file=heap.hprof <pid>
// In Eclipse MAT: OQL: SELECT * FROM java.lang.ClassLoader
// A list of thousands of ClassLoader instances = leak
```

> **Code walkthrough:** `ClassLoadingMXBean.getLoadedClassCount()`
> returns the count of currently loaded classes. In a healthy
> application, this stabilizes after warmup. A continuously rising
> count is the signature of a classloader leak. The Eclipse MAT
> OQL query finds all ClassLoader instances in the heap dump -
> too many is the smoking gun.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Metaspace stores class metadata. It replaces PermGen in Java 8.
> Grows in native memory. OOM: Metaspace = classloader leak or
> too many dynamic classes. Set `-XX:MaxMetaspaceSize` to prevent
> unbounded native memory growth.

---

**Senior / Staff (5+ years):**

> Classloader leaks are my main Metaspace concern. Spring's
> `@Configuration` classes, Hibernate entity metadata, CGLIB
> proxies all use class generation at startup. If the application
> is redeployed in the same JVM without the old classloader being
> released, each deployment adds ~50-200MB to Metaspace. I always
> set `MaxMetaspaceSize` and alert when `ClassLoadingMXBean.getLoadedClassCount()`
> grows beyond expected class count.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "How does Metaspace differ from PermGen? Why was the change made?"

🗣️ "PermGen (Permanent Generation) in Java 7 and earlier was a
fixed-size region in the Java heap. The default max was 64-128MB.
Running out of PermGen was a common operational problem because
the correct size was hard to predict. Metaspace in Java 8 moved
class metadata to native memory, which is managed by the OS
rather than the JVM heap allocator. The main benefit: Metaspace
grows dynamically up to available physical memory, eliminating
fixed-size OOM errors. The tradeoff: without `-XX:MaxMetaspaceSize`,
a classloader leak can consume all available native memory.
In PermGen, the leak would OOM much faster with a helpful message.
In Metaspace, the leak silently consumes memory until the OS is
exhausted."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | What lives in Metaspace, PermGen migration, GC reclaim conditions. |
| Hiring Manager   | Production: MaxMetaspaceSize, classloader leak monitoring. |
| Bar Raiser       | Compressed class space, metaspace GC triggers, virtual vs committed. |
| Peer Engineer    | "Permgen OOM every 3 days before we migrated to Java 8..." |
