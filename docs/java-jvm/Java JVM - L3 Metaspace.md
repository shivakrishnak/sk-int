---
layout: default
title: "Java JVM - L3 Metaspace"
parent: "Java JVM"
grand_parent: "SK Interview"
nav_order: 8
permalink: /java-jvm/l3-metaspace/
render_with_liquid: false
---

# Java JVM - L3 Metaspace

## Metaspace and Dynamic Class Generation

### 🎯 Model Answer

**30 seconds:**
> Metaspace (Java 8+) stores class metadata: bytecode, constant pool, field
> descriptors, method descriptors, and static field values. It lives in native
> OS memory (outside the Java heap), grows dynamically, and has no hard limit
> by default. Classes are garbage-collected when their ClassLoader is collected.
> Dynamic class generation (Proxies, CGLIB, Lambda MetaFactory) creates new
> classes at runtime, increasing Metaspace usage. Cap with
> `-XX:MaxMetaspaceSize` to detect leaks early.

**3 minutes (Senior):**
> Metaspace memory layout:
> - Class space: stores compressed class pointers (klass metadata), separate
>   region mapped with Compressed Class Space pointers.
> - Non-class space: everything else (method bytecode, constant pool, etc.)
>
> Metaspace is organized in "chunks" allocated from OS. Each ClassLoader has its
> own Metaspace allocator. When a ClassLoader is collected: its Metaspace chunks
> are returned to the OS (or a per-chunk-size free list for reuse).
>
> Dynamic class generation sources:
> - `java.lang.reflect.Proxy`: generates proxy class per interface combo
> - CGLIB (Spring AOP): subclass-based proxy per concrete class
> - Lambda forms (Java 8+): anonymous method objects stored in Metaspace
> - Groovy/JRuby/Kotlin: generate companion classes, object adapter classes
> - Hibernate: entity proxy classes
>
> Each generated class: adds Metaspace overhead. If generated classes accumulate
> (not unloaded because their ClassLoader is held): Metaspace grows indefinitely
> -> `OutOfMemoryError: Metaspace`.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Metaspace: class metadata in native memory. Grows dynamically.
Dynamic classes (Proxy, CGLIB, Lambda) accumulate. If ClassLoader leaks: all its
classes leak. Set MaxMetaspaceSize to catch leaks."

**(2) First principles:** "Classes (code + metadata) need to live somewhere.
Metaspace is that somewhere. Classes live as long as their ClassLoader lives.
Dynamic code generation = more classes = more Metaspace."

**(3) Bridge:** "Metaspace is like a library's catalog system. Each book (class)
requires a catalog entry (metadata). More books added (dynamic generation) = more
catalog space needed. If books are never removed (ClassLoader leak) = catalog overflows."

---

### 📘 Concept Explanation

**Metaspace internals:**
```
METASPACE STRUCTURE:
  Metaspace = Class Space + Non-Class Space

  Non-Class Space:
    Class bytecode (method bytecode)
    Constant pool (literals, symbolic references)
    Field and method descriptors
    Virtual method tables
    Interpreter tables

  Class Space (compressed klass pointers):
    Klass structures (class headers pointed to by object headers)
    Limited to 1GB (32-bit compressed class pointers)
    Managed separately for pointer compression

MEMORY SOURCE:
  Native OS memory (mmap/VirtualAlloc)
  NOT counted in -Xmx (outside heap)
  NOT GC-managed directly (freed when ClassLoader unloads)
  Grows automatically up to MaxMetaspaceSize (unlimited by default)

GARBAGE COLLECTION:
  Classes collected when: ClassLoader becomes unreachable AND
  no references to Class objects from that ClassLoader remain
  GC TRIGGERS: Metaspace full -> trigger Full GC to find unloadable ClassLoaders

DYNAMIC CLASS CONSUMERS:
  java.lang.reflect.Proxy: 1 class per unique interface combination
  CGLIB: 1-3 classes per proxied concrete class
  Lambda forms: 1 InvokeMethodHandle class per unique lambda shape
  Groovy: multiple companion classes per script class
  JVM-based languages: typically more classes per source file
```

---

### 💻 Code Example

> **Code walkthrough:** The Proxy generation example shows how each unique interface
> combination creates a new class in Metaspace. The BAD pattern recreates proxies
> on every call (each unique interface combo = new class). The GOOD pattern caches
> the proxy class. The key diagnostic: `jcmd GC.class_histogram | grep -i proxy`
> should NOT show thousands of entries.

```java
// BAD: creating new Proxy class per call (unique interface combinations)
// Each call with different target creates a new proxy CLASS (not just instance!)
InvocationHandler handler = (proxy, method, args) -> {
    return method.invoke(target, args);
};

// If called with different interfaces each time: new class per call!
Object proxy1 = Proxy.newProxyInstance(
    loader, new Class[]{ServiceA.class}, handler);
Object proxy2 = Proxy.newProxyInstance(
    loader, new Class[]{ServiceA.class, Loggable.class}, handler); // NEW CLASS!
Object proxy3 = Proxy.newProxyInstance(
    loader, new Class[]{ServiceA.class, Auditable.class}, handler); // NEW CLASS!
// 3 different interface combos = 3 proxy classes in Metaspace

// GOOD: reuse the same proxy instance (or same interface combination)
// Java's Proxy.newProxyInstance CACHES the generated class per interface combo
// -> Only 1 class per unique interface set, unlimited instances
Object proxy4 = Proxy.newProxyInstance(
    loader, new Class[]{ServiceA.class}, handler1);
Object proxy5 = Proxy.newProxyInstance(
    loader, new Class[]{ServiceA.class}, handler2); // REUSES same class!

// CGLIB proxy generation (Spring AOP):
// One proxy class generated PER concrete class that needs AOP advice
// Example: 500 @Service beans with @Transactional = 500 CGLIB proxy classes
// Each CGLIB proxy class: ~3-10KB Metaspace
// 500 classes: 1.5-5MB Metaspace (usually fine)
// Problem: if proxies generated dynamically per request (test code, not Spring beans)

// Monitoring Metaspace:
ManagementFactory.getMemoryPoolMXBeans().stream()
    .filter(p -> p.getName().contains("Metaspace"))
    .forEach(p -> {
        MemoryUsage usage = p.getUsage();
        System.out.printf("%s: used=%dMB committed=%dMB%n",
            p.getName(),
            usage.getUsed() / (1024*1024),
            usage.getCommitted() / (1024*1024));
    });
// Output:
//   Metaspace: used=150MB committed=155MB
//   Compressed Class Space: used=12MB committed=13MB

// Lambda Metaspace overhead:
// Each unique lambda SIGNATURE gets a class (LambdaForm)
// But: each lambda INSTANCE is a class object -> small but adds up
// Example: 1000 different lambda bodies in a large codebase
// = ~1000 LambdaForm classes in Metaspace (small, ~1-2KB each)
// Not usually a problem unless lambda generation is in hot path
```

> **Code walkthrough:** Java's `Proxy.newProxyInstance` internally caches the
> generated proxy class using a `WeakHashMap` keyed by ClassLoader + interface list.
> Same ClassLoader + same interfaces = same cached class. This means creating 1M
> proxy instances of the same interface does NOT create 1M classes - only 1 class
> and 1M instances. Metaspace grows with the number of UNIQUE interface combinations,
> not the number of proxy instances. The leak scenario: different ClassLoaders (one
> per request in some frameworks) each generating proxies -> 1 proxy class per
> ClassLoader -> ClassLoaders held -> classes accumulate.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Metaspace stores class code and metadata in native memory. Unlike PermGen (pre-Java 8):
> no fixed size, grows dynamically. Dynamic proxies (Spring AOP, JDK Proxy) generate
> classes at runtime and add to Metaspace. Set `-XX:MaxMetaspaceSize=256m` to get early
> warnings on leaks.

---

### **Senior / Staff (5+ years):**
> Metaspace management is critical for frameworks that do heavy code generation. Spring
> Boot with CGLIB proxies: each `@Service`, `@Component`, `@Controller` class gets a
> proxy class. A large application with 2000 Spring beans: 2000 proxy classes = ~5-10MB
> Metaspace (fine). A framework that generates proxies per request or per user session:
> catastrophic. The diagnostic pattern: Metaspace growing after redeployments or
> request processing = ClassLoader leak. Tools: `jcmd GC.class_histogram | sort -rk2 | head`,
> Eclipse MAT "unreachable objects" histogram, `jmap -permstat` (legacy).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Metaspace is unlimited and never needs attention."**
Metaspace is unlimited by default but consumes OS memory. On a host with 64GB RAM:
Metaspace growing to 10GB is possible if there's a ClassLoader leak. This reduces
available OS memory for other processes and file system cache. Always set
`-XX:MaxMetaspaceSize` to a reasonable bound (256-512MB for typical applications).
When it's exceeded: you get a clear OOM signal instead of a gradual resource exhaustion.

**Misconception 2: "Lambda functions don't use Metaspace."**
Lambda forms (the method handle infrastructure for lambdas) use Metaspace.
Each unique lambda "shape" (signature pattern) generates a LambdaForm class.
In practice: Java 8+ lambda bodies are compiled to static methods in the containing
class (not separate class files), so the overhead is minimal. But `MethodHandle`
operations and the LinkageHelper infrastructure do use Metaspace. For applications
with extreme lambda usage (functional pipeline frameworks, DSLs): monitor Metaspace
growth under load.

---

### 🚨 Failure Modes and Diagnosis

**Failure: OutOfMemoryError: Metaspace - class loading without class unloading.**
```
Symptom: java.lang.OutOfMemoryError: Metaspace
  OR: if MaxMetaspaceSize set, triggered before actual OOM

Cause 1: ClassLoader leak
  Generated classes (proxy, CGLIB, lambda) held by leaking ClassLoader
  ClassLoader held by static field, ThreadLocal, or live thread reference
  Each ClassLoader's classes: never unloaded

Cause 2: Legitimate growth (many plugins, hot-deploy)
  Each plugin deployment creates new ClassLoader + new classes
  If old ClassLoaders not released: Metaspace grows per deployment

Diagnosis:
  1. Check Metaspace growth rate:
     jcmd <pid> VM.native_memory summary | grep "Class space"
     Take snapshots 1h apart

  2. Count loaded classes over time:
     jcmd <pid> GC.class_statistics | wc -l
     Growing over time = classes accumulating

  3. Find accumulated class types:
     jcmd <pid> GC.class_histogram | sort -rk 2 | head -20
     Look for: generated class names (contain "$" or "_$$_"):
       com.example.Service$$EnhancerByCGLIB$$abc123
       $Proxy42, $Proxy43, ...  <- JDK Proxy classes
       groovy.runtime.callsite.xxx <- Groovy call sites

  4. If proxy classes accumulating: find what holds their ClassLoader
     Heap dump -> Eclipse MAT -> search for ClassLoader instances
     "Path to GC Roots" for the ClassLoader

Fix:
  Short-term: increase MaxMetaspaceSize (buys time)
  Long-term: fix ClassLoader leak
    - Ensure ThreadLocal.remove() called in thread pools
    - Spring: don't generate CGLIB proxies outside the ApplicationContext
    - Test frameworks: use proper lifecycle management
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Metaspace vs PermGen | 2 minutes |
| What goes in Metaspace | 2 minutes |
| Dynamic class generation | 2 minutes |
| Class unloading | 2 minutes |
| Metaspace leak diagnosis | 2-3 minutes |
| Lambda overhead | 90 seconds |
| CGLIB vs JDK Proxy Metaspace | 2 minutes |
| MaxMetaspaceSize setting | 90 seconds |
| ClassLoader and Metaspace | 2 minutes |

---

**Q1 (vs PermGen): How is Metaspace different from PermGen?**

A: PermGen (Java 7 and earlier): fixed-size region INSIDE the JVM heap, counted
toward `-Xmx`, caused `OutOfMemoryError: PermGen space`. Metaspace (Java 8+):
native OS memory OUTSIDE the heap, dynamic size (grows as needed), not counted
toward heap. Key changes: (1) Metaspace doesn't compete with object heap for space;
(2) Metaspace can grow much larger without heap allocation issues; (3) `OutOfMemoryError:
Metaspace` only if `-XX:MaxMetaspaceSize` is set and exceeded; (4) interned Strings
moved from PermGen to heap in Java 7 (before Metaspace); (5) static field values
remain in Metaspace (not heap).

*What separates good from great:* The PermGen -> Metaspace migration in Java 8
eliminated the most common Java deployment pain: `OutOfMemoryError: PermGen space`
after a few hot-redeploys. With PermGen: each hot-redeploy adds classes to a
fixed 64-256MB PermGen (default), filling it within a few redeploys. With Metaspace:
old ClassLoader classes CAN be unloaded (if no ClassLoader leaks), and Metaspace
grows dynamically. However: ClassLoader leaks are just as problematic in Metaspace,
they just cause gradual OS memory exhaustion instead of hard PermGen OOM. Setting
MaxMetaspaceSize gives an explicit OOM signal, reproducing PermGen-style alerting.

---

**Q2 (what's in): What information does Metaspace store for each class?**

A: For each loaded class: bytecode (compiled method bodies), constant pool (literals,
symbolic references to other classes/methods/fields), field descriptors (name, type,
offset for each field), method descriptors (name, signature, bytecode offset), class
hierarchy info (superclass, interfaces), virtual method table (vtable), interface
dispatch table (itable), static field values (for reference types; primitive statics
may be in JIT-compiled code), and internal JVM data structures for reflection and
introspection.

*What separates good from great:* Static field values in Metaspace is a subtle point.
Java specification: static fields are "class variables" owned by the class. In HotSpot:
reference-type static fields are stored in a mirror object (java.lang.Class object on
the heap), not directly in Metaspace. Primitive static fields are stored in the class
metadata in Metaspace. The `Class<?>` object is on the heap - it holds reference-type
statics. This is why: `Class<?>` objects are GC-collected when the ClassLoader is collected
(class + its static reference fields go together).

---

**Q3 (dynamic classes): Which Java features generate classes dynamically?**

A: `java.lang.reflect.Proxy`: one class per unique interface set + ClassLoader.
CGLIB (used by Spring AOP): one subclass proxy per concrete class. AspectJ weaving:
modified versions of target classes. JDK Lambda forms (Java 8+): one LambdaForm per
unique signature. Groovy: companion class, metaclass per script class. JRuby: class
per Ruby method. Kotlin companion objects: extra classes. Java Compiler API: dynamic
compilation (Javac at runtime). Method handles (MethodHandle.lookup()): invoker classes.
Serialization ObjectOutputStream: class descriptors.

*What separates good from great:* Understanding which are "hot" (generated per request)
vs "cold" (generated once at startup) is key. Cold = fine. Hot = potential problem.
Spring's CGLIB proxies: cold (generated once per bean at ApplicationContext startup).
A custom "method dispatcher" that uses `Proxy.newProxyInstance` with new interface
combinations per request: hot -> Metaspace leak. JDK's `Proxy.newProxyInstance` caches
by interface set + ClassLoader. If ClassLoader is the same (e.g., the AppClassLoader):
caching works perfectly. If a new ClassLoader is created per request: no caching possible ->
one proxy class per request -> Metaspace fills. This pattern appears in some testing
frameworks that create new ClassLoaders per test.

---

**Q4 (class unloading): When are dynamically-generated classes unloaded?**

A: A class is unloaded when: (1) its defining ClassLoader becomes unreachable (no
strong references to the ClassLoader object), AND (2) all `Class<?>` objects for
classes from that ClassLoader become unreachable (no strong references to the Class
objects or their instances). When both conditions met: next Full GC or when Metaspace
pressure triggers GC with class unloading. Classes loaded by the AppClassLoader
(most application classes): AppClassLoader is never collected -> those classes are
never unloaded (JVM lifetime).

*What separates good from great:* OSGi, application servers (Tomcat, JBoss), and
test frameworks create new ClassLoaders to enable class isolation and hot-reload.
For class unloading to work: the ClassLoader, all Class objects, AND all instances
of those classes must become unreachable. The failure mode: one instance of a
dynamically-loaded class is still live (e.g., held in a static collection by a
JVM-lifetime class) -> that ClassLoader can't be collected -> all classes from that
loader leak. Finding the retaining reference: heap dump + Eclipse MAT "Path to GC Roots"
for the ClassLoader object.

---

**Q5 (leak diagnosis): How do you diagnose a Metaspace leak?**

A: (1) Enable Metaspace monitoring: `-Xlog:gc+metaspace=trace`. (2) Observe growth
rate: `jcmd <pid> VM.native_memory summary | grep Class`. (3) Count loaded classes
over time: `jcmd <pid> GC.class_statistics | wc -l` (or class count in JMX
`java.lang:type=ClassLoading`). (4) GC class histogram with grep for generated
class names: `jcmd <pid> GC.class_histogram | grep '\$\|Proxy\|CGLIB'`. (5) If
accumulating: heap dump + Eclipse MAT, search for ClassLoader objects, use "Path
to GC Roots."

*What separates good from great:* The most efficient Metaspace leak diagnosis uses
JFR: `ClassLoad` and `ClassUnload` events. These record: class name, loading ClassLoader,
timestamp. Running JFR for 10 minutes: you see exactly which classes are being loaded
and at what rate. If a class appears hundreds of times: something generates it repeatedly.
If classes are loaded but never unloaded: ClassLoader is being held. This is more
diagnostic than heap dumps because it shows the RATE of class generation, not just
the current accumulation.

---

**Q6 (Spring AOP): How does Spring's use of CGLIB affect Metaspace?**

A: Spring Boot with CGLIB creates proxy subclasses for: `@Service`, `@Component`,
`@Repository` beans with `@Transactional`, `@Async`, or other AOP advice.
Each proxied bean: 1-3 additional classes in Metaspace (proxy class + potentially
interceptor glue). A large Spring application with 1000 proxied beans: ~3000 extra
classes, ~30-60MB additional Metaspace. This is a startup cost, not a runtime leak.
The proxy classes live for the JVM's lifetime (loaded by AppClassLoader).

*What separates good from great:* Spring Boot 3.x with GraalVM native image: CGLIB
is replaced with bytecode instrumentation at compile time (proxyBeanMethods=false
for lightweight @Configuration). No runtime CGLIB = no Metaspace overhead for
proxies. For standard JVM deployments: CGLIB overhead is usually acceptable.
For Metaspace-constrained environments: use Spring's `@Configuration(proxyBeanMethods=false)`
to reduce proxy class count, and `@EnableAspectJAutoProxy(proxyTargetClass=false)` to
use JDK Proxy (interface-based, slightly fewer classes than CGLIB for the same bean count).

---

**Q7 (lambda): How do Java lambdas affect Metaspace?**

A: Lambda bytecode is compiled to a private static method in the enclosing class.
At runtime: `invokedynamic` + LambdaMetafactory creates a class implementing the
functional interface on first call (using ASM, stored in Metaspace). Subsequent calls
to the SAME lambda: reuse the same class (cached by LambdaMetafactory). Different
lambda bodies (different captured variables, different code): same class (the class
is per lambda "shape," not per closure). Lambda instances are just object allocations.

*What separates good from great:* The LambdaMetafactory class generation is "hidden"
- the generated classes have names like `Application$$Lambda$123`. These are usually
stable (one per unique lambda in the source code). They're loaded by the
AppClassLoader -> never unloaded -> small permanent Metaspace overhead per lambda
in the source. For most applications: thousands of lambdas in source code = thousands
of small (~1-2KB) LambdaForm classes in Metaspace = ~2-10MB. Not a practical issue.
The Metaspace lambda issue: test frameworks that dynamically generate lambda-like
constructs using `MethodHandles.Lookup.defineClass()` in hot paths.

---

**Q8 (class count): How many classes does a typical Spring Boot application load?**

A: A minimal Spring Boot REST application: ~3000-4000 classes at startup.
A medium-complexity Spring Boot application with common dependencies (Hibernate,
Jackson, Spring Security, Metrics): 8000-15000 classes. A large enterprise
application: 20000-40000 classes. Each class: 1-50KB Metaspace depending on
method count and bytecode size. Total: ~100-500MB Metaspace for large apps.
Monitor: `jcmd <pid> GC.class_statistics | wc -l`.

*What separates good from great:* Class count directly correlates with startup time.
Each class: loading + verification + (potentially) initialization. A 15000-class
application: 15 seconds of startup class loading (at 1000 classes/second with disk I/O).
AppCDS (Application Class Data Sharing): pre-processes the class loading, reducing startup
time. With AppCDS: 15000 classes loaded from memory-mapped archive = <1 second.
Spring Boot 3.x + GraalVM native image: compiles all 15000 classes to native code at
build time, startup in milliseconds. The class count / startup time trade-off is one
of the main motivations for GraalVM native image in microservice architectures.

---

**Q9 (Metaspace GC): How does the JVM GC Metaspace?**

A: Metaspace is NOT GC-managed like the heap. Class metadata is freed when the
ClassLoader is collected. GC indirectly drives this: when heap GC can't make space
(Metaspace-induced Full GC), the JVM also examines ClassLoader reachability. If a
ClassLoader is unreachable: its Metaspace chunks are freed. There's no incremental
Metaspace compaction - it's chunk-based: when a ClassLoader's chunks are all freed,
those chunks become available for new ClassLoaders.

*What separates good from great:* Metaspace fragmentation: if small ClassLoaders
with few classes are loaded and unloaded frequently, their small chunks leave gaps
in the Metaspace arena. These gaps can't be used by larger ClassLoaders (different
chunk size). Result: Metaspace "used" drops but "committed" stays high (holes).
Monitoring: `jcmd VM.native_memory detail | grep "Class space"` shows committed vs
used. Growing committed with stable used = fragmentation. In practice: Metaspace
fragmentation is rare except in hot-reload scenarios (Tomcat, OSGi with many plugins).

---

### ⚖️ Comparison Table

| Feature | PermGen (Java 7-) | Metaspace (Java 8+) |
|---|---|---|
| Location | JVM heap (counted in -Xmx) | Native OS memory (outside heap) |
| Default size | 64-256MB (fixed) | Unlimited (dynamic) |
| OOM message | `PermGen space` | `Metaspace` (if MaxMetaspaceSize set) |
| Class unloading | Same rules | Same rules |
| String interning | In PermGen | On heap |
| Tuning flag | `-XX:MaxPermSize` | `-XX:MaxMetaspaceSize` |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: Metaspace structure described adequately in Concept Explanation)*

---

---

## ClassLoader Memory Leaks

### 🎯 Model Answer

**30 seconds:**
> A ClassLoader leak occurs when a ClassLoader (and all the classes it loaded)
> cannot be garbage-collected because something outside the ClassLoader's scope
> holds a reference to it - typically via a class it loaded. The classic scenario:
> a ThreadLocal in a thread pool thread holds an object of a webapp class, preventing
> the webapp's ClassLoader from being collected on undeploy. Each deployment leaks
> ALL webapp classes into Metaspace, eventually causing `OutOfMemoryError: Metaspace`.

**3 minutes (Senior):**
> For a ClassLoader to be collected: ALL references to it must be released.
> References to a ClassLoader come from:
> 1. Direct: code holding `ClassLoader cl` reference (a static field, a ThreadLocal)
> 2. Indirect through loaded classes: any live object that is an INSTANCE of a class
>    loaded by that ClassLoader. The instance holds a reference to its Class,
>    and the Class holds a reference to its ClassLoader.
>
> The reference chain that causes leaks:
> ```
> ThreadPool (live forever)
>   -> Thread (live as long as pool)
>     -> ThreadLocalMap (thread-private)
>       -> WeakRef(WebappClassLoader) + object (value)
>         -> Value object is of type "com.example.UserContext"
>           -> UserContext.class -> WebappClassLoader
>             -> ALL classes loaded by WebappClassLoader (LEAK!)
> ```
>
> The ThreadLocal key is a WeakReference to the ThreadLocal object. But the VALUE
> in the ThreadLocalMap is a STRONG reference. If the value is an instance of a
> class from the WebappClassLoader: the ClassLoader is pinned.
>
> Common leak sources: ThreadLocal without remove(), static field in a framework class
> pointing to a webapp object, JDBC driver registration (old versions), AWT/Swing
> event queue, logging appenders.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "ClassLoader leak = ClassLoader held alive when it should be
collected. Reference chain: live object -> instance of webapp class -> webapp's Class
object -> webapp's ClassLoader -> ALL webapp classes. Common cause: ThreadLocal
without remove() in thread pool."

**(2) First principles:** "An object can't be GC'd if anything live references it.
A ClassLoader is an object. It's referenced by every Class it loaded. Classes are
referenced by their instances. One live instance of a webapp class = entire webapp's
ClassLoader stays alive."

**(3) Bridge:** "ClassLoader leak is like a hotel checkout problem. The hotel
(JVM) wants to reuse the room (Metaspace) after the guest checks out (webapp undeployed).
But the guest left their key card (ThreadLocal) at the hotel pool (thread pool).
The room can't be cleaned until the key card is returned."

---

### 📘 Concept Explanation

**ClassLoader leak reference chain:**
```
MINIMAL REFERENCE CHAIN FOR A LEAK:

  static or thread-local live reference
    -> instance of com.example.Foo  (a webapp class)
      -> Foo.class  (java.lang.Class on the heap)
        -> Foo.class.classLoader = WebappClassLoader
          -> Map of all classes loaded by WebappClassLoader
            -> FooClass, BarClass, BazClass, ...  (Metaspace entries)

EACH CLASS HAS:
  -> its own Class object (heap)
  -> its own Metaspace entry (class metadata, bytecode)
  -> static field values (Class object holds references)

LEAK SIZE:
  Metaspace:
    each class metadata: 1-100KB
    500 classes: 10-50MB per deployment
    After 10 redeploys without fix: 100-500MB leaked -> OOM

COMMON LEAK SOURCES:
  ThreadLocal:        ThreadLocal.remove() never called in thread pool
  JDBC DriverManager: old drivers register static listener holding ClassLoader
  Log4j FileAppender: static logger holding reference in external ClassLoader
  AWT event queue:    event listeners holding webapp objects
  static fields:      framework singleton with reference to webapp object
  Shutdown hooks:     Runtime.addShutdownHook with webapp Runnable
```

---

### 💻 Code Example

> **Code walkthrough:** ThreadLocal leak is the most common ClassLoader leak in
> servlet containers. The BAD pattern leaves the ThreadLocal value after processing.
> In a thread pool: the thread keeps running (pool doesn't create new threads),
> so the ThreadLocal value lives forever, holding the ClassLoader of the class
> it was initialized from.

```java
// BAD: ThreadLocal leak in servlet filter (very common)
class RequestContextFilter implements Filter {
    // ThreadLocal of a webapp class (RequestContext) in a thread pool thread
    private static final ThreadLocal<RequestContext> REQUEST_CONTEXT
        = new ThreadLocal<>();

    @Override
    public void doFilter(ServletRequest req, ServletResponse res,
                         FilterChain chain) throws Exception {
        REQUEST_CONTEXT.set(new RequestContext(req)); // set before
        try {
            chain.doFilter(req, res);
        } finally {
            // MISSING: REQUEST_CONTEXT.remove() !
            // Thread pool thread now holds RequestContext, which is an instance
            // of a class from WebappClassLoader -> WebappClassLoader cannot be
            // collected on undeploy -> LEAK!
        }
    }
}

// GOOD: always remove in finally block
class RequestContextFilter_GOOD implements Filter {
    private static final ThreadLocal<RequestContext> REQUEST_CONTEXT
        = new ThreadLocal<>();

    @Override
    public void doFilter(ServletRequest req, ServletResponse res,
                         FilterChain chain) throws Exception {
        REQUEST_CONTEXT.set(new RequestContext(req));
        try {
            chain.doFilter(req, res);
        } finally {
            REQUEST_CONTEXT.remove(); // MANDATORY - prevent ClassLoader leak
        }
    }
}

// Diagnosing ClassLoader leaks:
// 1. After redeploy, check if ClassLoader count grows:
jcmd <pid> GC.class_statistics | grep "ClassLoader"
// Each redeploy: if ClassLoader count grows by 1 = leak
// If it stays constant (or drops): ClassLoader was collected correctly

// 2. Trigger GC and check Metaspace:
jcmd <pid> GC.run
jcmd <pid> VM.native_memory summary | grep "Class space"
// If Metaspace drops after GC: old ClassLoaders were collected
// If Metaspace stays same: ClassLoader leak

// 3. Heap dump to find ClassLoader retention:
jcmd <pid> GC.heap_dump /tmp/heap.hprof
// In Eclipse MAT:
// Window -> Heap Dump Details -> Class Loaders -> WebappClassLoader
// Path to GC Roots -> What holds the ClassLoader alive?
```

> **Code walkthrough:** The `ThreadLocal.remove()` in a finally block is the single
> most important pattern for servlet-based Java applications. Without it: every
> request that sets a ThreadLocal value and completes leaves that value permanently
> in the thread pool thread's ThreadLocalMap. After each hot-redeploy: the old
> WebappClassLoader is pinned by these stale ThreadLocal values. Tomcat's "memory
> leak prevention" feature detects and warns about this (check Tomcat logs for
> "A web application is creating ThreadLocal...").

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> ClassLoader leaks happen when something holds a reference to an object of a dynamically-
> loaded class, preventing that ClassLoader from being collected. Most common: ThreadLocal
> without `remove()` in thread pool. Fix: always call `ThreadLocal.remove()` in finally.
> Diagnose: check Metaspace growth over redeploys.

---

**Senior / Staff (5+ years):**
> ClassLoader leak diagnosis requires understanding the reference chain. Eclipse MAT's
> "Path to GC Roots" for a leaked ClassLoader is the definitive tool. Common retained
> paths in enterprise apps: (1) ThreadLocal in shared thread pool (fix: remove in finally),
> (2) JDBC drivers (fix: deregister in ServletContextListener.contextDestroyed()),
> (3) logging framework appenders (fix: use shutdown in app lifecycle), (4) JMX MBeans
> (fix: unregister in stop()), (5) Hibernate's SessionFactory holding Spring context
> reference. Each requires a specific fix in the app lifecycle (contextDestroyed,
> @PreDestroy, shutdown hook).

---

### ⚠️ Common Misconceptions

**Misconception 1: "WeakHashMap is sufficient to prevent ClassLoader leaks."**
WeakHashMap weakly holds KEYS (the WeakHashMap entry's key is a WeakReference).
If you store `(classLoaderRelatedObject -> value)` in a WeakHashMap: when the key
becomes weakly reachable (ClassLoader not otherwise referenced), the entry IS cleared.
BUT: if the VALUE has a reference back to the ClassLoader (e.g., value is an instance
of a webapp class): the ClassLoader is strongly reachable via the value -> the
WeakHashMap key never becomes weakly reachable -> no entry clearing -> leak.
WeakHashMap leak: value holds a reference to its key (directly or through class chain).

**Misconception 2: "Calling System.gc() after undeploy ensures ClassLoader is collected."**
`System.gc()` suggests a GC but doesn't guarantee one (and even if it runs, doesn't
guarantee ClassLoaders are collected). ClassLoaders are collected when ALL references
are gone. If a ThreadLocal in a thread pool still holds an instance of a webapp class:
no amount of `System.gc()` calls will collect the ClassLoader. Fix the reference chain,
not the GC schedule.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Metaspace OOM after multiple hot-redeploys.**
```
Symptom: OOM after deploy 3-5 in application server
  java.lang.OutOfMemoryError: Metaspace
  Occurs ~15-30 minutes after each redeploy
  JVM restart fixes it (temporary)

Cause: ClassLoader leak per redeploy
  Each deployment: new WebappClassLoader + N classes loaded
  Old ClassLoader: not collected (ThreadLocal/static holds ref)
  Metaspace: grows by N * class_size per deployment

Detection:
  1. Set -XX:MaxMetaspaceSize=512m -> OOM will trigger on leak (clearer signal)
  2. Monitor class count between deploys:
     jcmd <pid> GC.class_statistics | wc -l
     Before deploy: 5000 classes
     After 1st redeploy: 10000 classes (5000 new + 5000 leaked old)
     After 2nd redeploy: 15000 classes -> CONFIRMED LEAK

Diagnosis steps:
  1. After confirming leak, take heap dump immediately after deploy:
     jcmd <pid> GC.heap_dump /tmp/heap.hprof
  2. Eclipse MAT: list ClassLoaders -> count WebappClassLoader instances
     Should be 1 (current) -> if 2+: previous ClassLoaders leaked
  3. "Path to GC Roots" for the OLDEST WebappClassLoader
     (highest generation, not the newest)
  4. Follow the path: reveals the retaining reference

Fix:
  ThreadLocal: add remove() in finally
  JDBC driver: DriverManager.deregisterDriver() in contextDestroyed
  JMX MBeans: MBeanServer.unregisterMBean() in stop
  Logging: LogManager.getLogManager().reset() in contextDestroyed
  Static caches: clear in @PreDestroy
  Event listeners: remove all listeners in contextDestroyed
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| ClassLoader leak definition | 2 minutes |
| Reference chain for leaks | 2 minutes |
| ThreadLocal leak pattern | 2 minutes |
| JDBC driver deregistration | 2 minutes |
| Diagnosing ClassLoader leaks | 2-3 minutes |
| Eclipse MAT for ClassLoader | 2 minutes |
| WeakHashMap pitfall | 2 minutes |
| App server context lifecycle | 2 minutes |
| Prevention patterns | 2 minutes |

---

**Q1 (chain): Walk through the reference chain in a ThreadLocal ClassLoader leak.**

A: Thread pool thread (live forever) -> `ThreadLocalMap` (thread-private field) ->
`Entry` (key=WeakRef(ThreadLocal), value=STRONG ref to object) -> object is an
instance of `WebappClass` -> `WebappClass.class` (Class object) -> `WebappClass.class.classLoader`
= `WebappClassLoader` -> `WebappClassLoader` has a registry of ALL loaded classes ->
each class's Metaspace entry. The WebappClassLoader cannot be collected because
the strong reference from the ThreadLocalMap value keeps it alive transitively.

*What separates good from great:* The key insight: the ThreadLocalMap's VALUE is a
strong reference (intentional - you want the value to stay alive while the key is
present). The KEY is a WeakReference (so ThreadLocal objects can be GC'd). This means:
even after the ThreadLocal OBJECT is collected (weak key is cleared), the VALUE remains
in the ThreadLocalMap as a "stale entry." JVM does clean up stale entries on the NEXT
get/set/remove call on the same map. But in thread pool threads that stop using the
ThreadLocal: stale entries persist indefinitely. This is the exact mechanism of the leak.

---

**Q2 (JDBC): Why do JDBC drivers cause ClassLoader leaks and how do you fix them?**

A: Old JDBC drivers use `DriverManager.registerDriver()` in a static initializer.
DriverManager is a JVM-lifetime class (AppClassLoader). It holds a reference to the
Driver instance. The Driver instance is of a class from the webapp ClassLoader. Therefore:
DriverManager -> webapp Driver class -> WebappClassLoader = LEAK. Fix: in `ServletContextListener.contextDestroyed()`:
```java
Enumeration<Driver> drivers = DriverManager.getDrivers();
while (drivers.hasMoreElements()) {
    Driver driver = drivers.nextElement();
    if (driver.getClass().getClassLoader() == getClass().getClassLoader()) {
        DriverManager.deregisterDriver(driver);
    }
}
```

*What separates good from great:* Modern JDBC 4.0+ uses `ServiceLoader` for driver
discovery, not static initialization. But: `DriverManager` still registers drivers.
The WebappClassLoader isolation: the JDBC driver JAR is often in the SHARED classpath
(loaded by the server's ClassLoader, not the webapp's ClassLoader). In that case:
no leak (driver class is from a ClassLoader that lives as long as the server, not the
webapp). Leak occurs only when the JDBC JAR is INSIDE the webapp's WEB-INF/lib.
Best practice: put JDBC JARs in the application server's shared lib, not in each webapp.

---

**Q3 (detection): How do you detect a ClassLoader leak before it causes OOM?**

A: (1) Monitor class count trend: `jcmd <pid> GC.class_statistics | wc -l` every
5 minutes after each redeploy. Growing by the same amount each deploy = leak.
(2) Monitor Metaspace committed: JMX `java.lang:type=MemoryPool,name=Metaspace`.
Growing per deploy without recovery = leak. (3) Prometheus alert: rate of class loading
> 100 classes/min (excluding startup) signals leak. (4) JFR ClassLoad events: capture
10 minutes of events during normal operation; filter out startup class loads.

*What separates good from great:* Proactive ClassLoader leak detection should be
built into the deployment pipeline for servlet-based applications. A simple smoke test:
deploy app, send 1000 requests, undeploy, wait 30s, force GC (`jcmd GC.run`), check
class count. If class count drops back to pre-deployment level: no leak. If it stays
elevated: leak detected in staging, before production OOM. This test takes < 2 minutes
and prevents the most common production Metaspace OOM.

---

**Q4 (fix patterns): What patterns prevent ClassLoader leaks?**

A: (1) Always call `ThreadLocal.remove()` in finally blocks in thread pool code.
(2) Implement `ServletContextListener.contextDestroyed()` for cleanup: deregister
drivers, MBeans, loggers, event listeners, shutdown schedulers. (3) Use `@PreDestroy`
in Spring beans for cleanup. (4) Don't store webapp class instances in JVM-scope
static fields (factories, managers). (5) Use `@ApplicationScoped` CDI beans carefully
(may live longer than expected). (6) Avoid registering shutdown hooks in webapps
(they reference the webapp ClassLoader and run during JVM shutdown, not webapp undeploy).

*What separates good from great:* The "contextDestroyed cleanup checklist" for
servlet applications: (1) `DriverManager.deregisterDriver()` for JDBC drivers,
(2) `java.util.logging.LogManager.getLogManager().reset()` if using JUL,
(3) Executor/ScheduledExecutor.shutdown() for any scheduled tasks,
(4) `JMXService.unregisterAll()` for MBeans registered by the webapp,
(5) `RuntimeMXBean.addShutdownHook()` shutdown hooks (don't add these in webapps).
Spring Boot handles most of these automatically in its application lifecycle.
For raw servlet-based apps or legacy code: each must be done explicitly.

---

**Q5 (Eclipse MAT): How do you use Eclipse MAT to find what holds a ClassLoader?**

A: (1) Take heap dump: `jcmd <pid> GC.heap_dump /tmp/heap.hprof`. (2) Open in
Eclipse MAT. (3) "Window" -> "Heap Dump Details" -> "Class Loaders" tab. Lists all
ClassLoader instances with retained heap. (4) If multiple instances of WebappClassLoader
(or your app's ClassLoader): old ones leaked. (5) Right-click old ClassLoader ->
"Path to GC Roots" -> "Exclude all phantom/weak/soft references" -> shows the strong
reference chain that prevents collection.

*What separates good from great:* MAT's "Path to GC Roots" is the most powerful
ClassLoader leak tool. It shows the EXACT field names and types along the path from
the GC root to the ClassLoader. Example output:
`Thread (main pool thread) -> threadLocals (ThreadLocalMap) -> table[5] (Entry) -> value (RequestContext) -> context.class (Class<RequestContext>) -> classLoader (WebappClassLoader)`.
This is immediately actionable: find the `RequestContext` usage in the filter that
sets the ThreadLocal and add `ThreadLocal.remove()`. The path shows the retaining
reference - the fix is always: break the first strong reference in the chain.

---

**Q6 (containers): How do Docker/Kubernetes change ClassLoader leak risk?**

A: In Docker/Kubernetes: microservices typically run ONE JVM per container, with
NO hot redeploy. The container is killed and replaced (immutable infrastructure).
This eliminates the classic "multiple redeploys cause ClassLoader leak OOM" scenario.
However: ClassLoader leaks still matter if the application uses custom ClassLoaders
(OSGi, plugin systems, scripting engines with multiple scripts) within the single JVM.

*What separates good from great:* Kubernetes + immutable containers shift the risk
profile: ClassLoader leaks in containers are visible as "container restarts" if OOM
kills the pod. The monitoring signal changes from "Metaspace grows over deployments"
to "container OOM kill shortly after startup" (if the leak is fast) or "gradually
increasing memory usage leading to OOM" (if the leak is slow). The prevention:
same as before (proper lifecycle management), but now the failure mode is container
OOM rather than application server OOM. Tools: `kubectl top pods` for memory trend,
`kubectl logs` for OOM kill events, and the same JVM heap/Metaspace monitoring.

---

**Q7 (static fields): How do static fields cause ClassLoader leaks in frameworks?**

A: A static field in a JVM-lifetime class holding an instance of an application class
creates a persistent GC root to that instance. That instance's class is from the
application ClassLoader. The ClassLoader can't be collected. Example: a framework's
singleton registry (static `Map<String, Object>` in a framework class) holding
application objects. On undeploy: the map still holds the application objects,
the application ClassLoader is pinned.

*What separates good from great:* This is the least visible ClassLoader leak pattern.
In JSP compilers: the page compiler generates servlet classes and may cache them in
a static map in the container's ClassLoader. Old Spring versions: some static BeanFactory
caches. Modern frameworks handle this correctly in their lifecycle management. For
custom frameworks: never hold application class instances in static fields of
framework/server classes. Use weak references for framework-held references to
application objects: `static WeakHashMap<String, Object>` where keys are
framework-scoped, values are application objects.

---

**Q8 (JMX leak): How does JMX cause ClassLoader leaks?**

A: When a webapp registers an MBean with the JVM's MBeanServer (which lives at
JVM scope): the MBean object is held by MBeanServer (JVM-lifetime). If the MBean
is an instance of a webapp class -> webapp ClassLoader pinned. On undeploy: MBean
still registered -> ClassLoader leak.

```java
// BAD: register MBean without unregistering
@Override
public void contextInitialized(ServletContextEvent sce) {
    MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
    mbs.registerMBean(new AppStats(), new ObjectName("app:name=stats"));
    // MBeanServer (JVM-scope) now holds AppStats (webapp class) -> LEAK on undeploy
}

// GOOD: unregister in contextDestroyed
@Override
public void contextDestroyed(ServletContextEvent sce) {
    MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
    mbs.unregisterMBean(new ObjectName("app:name=stats"));
}
```

*What separates good from great:* Tomcat's JmxRemoteLifecycleListener and most
modern app servers (WildFly, WebLogic) automatically unregister MBeans when the webapp
is undeployed - if you used the container's JMX framework for registration. The leak
occurs when you use `ManagementFactory.getPlatformMBeanServer()` directly (bypassing
container management) and don't unregister. Using Spring's JmxMBeanExporter with
proper Spring application lifecycle: beans are unregistered when ApplicationContext
closes. For manual JMX registration: implement `contextDestroyed` cleanup.

---

**Q9 (prevention): What are the best practices to prevent ClassLoader leaks in new code?**

A: (1) Use dependency injection (Spring, CDI) for all singletons and lifecycle management.
(2) Implement `Closeable`/`AutoCloseable` for resources and use try-with-resources.
(3) Never store application class instances in static fields of framework/utility classes.
(4) Always `ThreadLocal.remove()` in finally blocks for thread pool code.
(5) Implement `@PreDestroy` / `contextDestroyed` for all external registrations
(JMX, JDBC, logging, event listeners).
(6) In tests: use proper setup/teardown for ClassLoader-creating test isolation.

*What separates good from great:* The most effective prevention: use Spring Boot's
ApplicationContext lifecycle management. Spring's context shutdown sequence: calls
`@PreDestroy` on all beans, calls `DisposableBean.destroy()`, runs `ApplicationEvent`
listeners, then disposes the context. This provides a reliable, ordered cleanup sequence
that prevents most ClassLoader leaks IF you register cleanup in the Spring lifecycle.
The anti-pattern: bypassing Spring's lifecycle with `new` and manual management.
For legacy codebases: adding a `ServletContextListener` that acts as an "application
cleanup orchestrator" - explicitly cleaning up all known leak sources in `contextDestroyed`.

---

### ⚖️ Comparison Table

| Leak Source | Retaining Reference | Fix | Detection |
|---|---|---|---|
| ThreadLocal | Thread -> ThreadLocalMap -> value (webapp obj) | `ThreadLocal.remove()` in finally | JFR thread locals |
| JDBC Driver | DriverManager (static) -> Driver (webapp class) | `deregisterDriver()` in contextDestroyed | Class histogram: DriverWrapper |
| JMX MBean | MBeanServer (JVM) -> MBean (webapp obj) | `unregisterMBean()` in stop | Class histogram: MBean count |
| Event Listener | EventBus (static) -> listener (webapp obj) | `removeListener()` in destroy | Heap dump, path to GC roots |
| Static Cache | Static Map -> value (webapp obj) | Clear in contextDestroyed | Growing class count per deploy |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: ClassLoader leak chain described adequately in Concept Explanation)*
