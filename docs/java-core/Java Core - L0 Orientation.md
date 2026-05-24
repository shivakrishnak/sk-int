---
layout: default
title: "Java Core - L0 Orientation"
parent: "Java Core APIs"
grand_parent: "SK Interview"
nav_order: 1
permalink: /java-core/l0-orientation/
---

# Java Standard Library: java.lang, java.util, java.io Architecture

**Interview Weight:** low - Warm-up and context-setting; signals whether
you understand the Java ecosystem map before diving into specifics.

---

### 🎯 Model Answer

**30 seconds:**

> The Java Standard Library is split into packages by purpose.
> `java.lang` is auto-imported - it holds Object, String, Integer,
> Math, System, Thread. `java.util` holds the Collections framework,
> Optional, and functional interfaces. `java.io` provides classic
> blocking I/O. `java.nio` (Java 1.4) adds non-blocking channels
> and buffers. `java.nio.file` (Java 7) provides the modern Path
> and Files API.

**3 minutes (Senior):**

> The standard library is layered. `java.lang` is the base - loaded
> automatically because every class needs it: Object (universal
> superclass), String, primitive wrappers (Integer, Long, Double),
> Math, System, Thread, and Throwable.
>
> `java.util` is the toolkit layer: Collections interfaces and
> implementations, Optional, `java.util.function` (functional
> interfaces), `java.util.stream` (Streams API), and
> `java.util.concurrent` (thread-safe collections, executors).
>
> The I/O stack has three generations: classic `java.io` (blocking
> InputStream/OutputStream, Reader/Writer, the old File class),
> `java.nio` (non-blocking channels + buffers + Selector for
> multiplexed I/O), and `java.nio.file` (Path, Files, FileVisitor
>
> - the modern file API that replaced `java.io.File` by throwing
>   exceptions instead of returning silent booleans).
>
> In Java 9+, the module system formalizes this: `java.base` contains
> `java.lang`, `java.util`, `java.io`, `java.nio`, `java.net`. Other
> features (`java.sql`, `java.xml`) are separate modules requiring
> explicit `requires` declarations.

**Framework:** LAYERS (lang -> util -> io/nio -> net -> specialized) +
KEY-CLASSES-PER-PACKAGE + WHEN-TO-USE-EACH-GENERATION

_Adapting up:_ Discuss JPMS `java.base` module structure, `jlink`
for minimal JVM images, and why `java.io.File` was replaced.

_Adapting down:_ Name the 3-4 most important packages and one key
class from each.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Java standard library
organization - the main package families: java.lang (always
available), java.util (collections), java.io and java.nio (I/O)."

**(2) First principles:** "A standard library solves the 'every
program needs this' problem. Java organizes it by purpose into
packages, with java.lang being special - auto-imported because
every class needs Object and String."

**(3) Bridge:** "The standard library is like a building: java.lang
is the foundation (always present), java.util is the main floor
(everyday tools), java.io/java.nio are the utility wings. Every
room builds on the foundation."

---

### 📘 Concept Explanation

**What it is:**

The Java Standard Library bundled with every JDK/JRE, organized into
package namespaces by purpose. `java.lang` is the only package
auto-imported by the compiler.

**Package map:**

```
java.lang          Auto-imported. Language foundation.
  Object, String, Integer/Long/Double/Boolean
  Math, System, Runtime
  Thread, Runnable, ThreadLocal
  Throwable, Exception, Error
  Enum, Record (Java 16+)
  reflect/ (Class, Method, Field - must import)
  invoke/  (MethodHandle, VarHandle - must import)

java.util          Toolkit. Must import.
  Collection, List, Set, Map, Queue, Deque
  ArrayList, HashMap, TreeMap, HashSet, LinkedHashMap
  Collections, Arrays (utility algorithms)
  Optional, Objects
  function/ (Predicate, Function, Consumer, Supplier)
  stream/   (Stream, Collectors, Spliterator)
  concurrent/ (see separate keyword)

java.io            Classic blocking I/O (Java 1.0).
  InputStream, OutputStream (byte streams)
  Reader, Writer (character streams)
  File (legacy - prefer Path)
  BufferedInputStream, ObjectInputStream
  PrintStream, PrintWriter

java.nio           Non-blocking I/O (Java 1.4).
  ByteBuffer, CharBuffer (typed buffers)
  FileChannel, SocketChannel, ServerSocketChannel
  Selector (I/O multiplexing)
  CharsetEncoder/Decoder

java.nio.file      Modern file API (Java 7 - NIO.2).
  Path, Paths, Files, FileSystems
  FileVisitor, WatchService
  OpenOption, CopyOption

java.net           Networking.
  URL, URI, HttpURLConnection
  Socket, ServerSocket, InetAddress

java.security / javax.crypto  Security.
  MessageDigest, Cipher, KeyStore
  SecureRandom, KeyPair
```

**Why `java.lang` is special:**

The JVM loads `java.lang.*` before any user code and the compiler
automatically inserts `import java.lang.*;` in every file. Sub-packages
(`java.lang.reflect.*`) are NOT auto-imported - they require explicit
imports.

**When to use each I/O generation:**

- New file operations: always `java.nio.file.Files` + `Path`
- Network servers at scale: `java.nio.Selector` + `SocketChannel`
- Simple sequential reads: `BufferedReader` from `java.io` is fine
- Never use `java.io.File` for new code - it swallows errors silently

---

### 💻 Code Example

#### java.lang, java.util, java.nio.file together

```java
import java.nio.file.Files;   // NIO.2 - explicit import required
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;
// String, System, Math: java.lang - no import needed

public class LibraryExample {

    // java.lang.Math (auto-imported)
    public static int clamp(int val, int min, int max) {
        return Math.min(Math.max(val, min), max);
    }

    // java.nio.file + java.util.stream
    public static List<String> nonEmptyLines(
            Path path) throws Exception {
        // Files.readAllLines: NIO.2 - throws IOException on fail
        return Files.readAllLines(path).stream()
            .filter(line -> !line.isBlank())
            .collect(Collectors.toList());
    }

    public static void main(String[] args) throws Exception {
        // System: java.lang.System (auto-imported)
        System.out.println(clamp(150, 0, 100)); // 100
        Path p = Path.of("data.txt");
        List<String> lines = nonEmptyLines(p);
        System.out.println(lines.size());
    }
}
```

> **Code walkthrough:** `Math`, `String`, `System` come from
> `java.lang` and need no import. `List`, `Collectors`, `stream()`
> come from `java.util`. `Files`, `Path` come from `java.nio.file`
> (NIO.2). `Files.readAllLines()` throws `IOException` on failure -
> contrast with `new File("data.txt").exists()` which silently
> returns `false` for both "not found" and "permission denied".

---

### 🎓 Answers by Seniority

**Junior:** `java.lang` is auto-imported - has String, Integer, Math,
System. `java.util` has ArrayList, HashMap. `java.io` has file
reading. Everything else needs an explicit import.

**Mid-level:** Three I/O generations: `java.io` (classic blocking),
`java.nio` (non-blocking channels), `java.nio.file` (modern Path/Files
API from Java 7). For thread-safe collections, use `java.util.concurrent`

- not `Collections.synchronizedList()`.

**Senior:** `java.io.File` returns booleans for failures (silent
errors) - always use `java.nio.file.Files` for new code. The
`java.util.concurrent` package uses CAS-based lock-free algorithms
that outperform synchronized wrappers under contention. Java 9's
module system puts `java.lang`, `java.util`, `java.io`, `java.nio`
in `java.base` - always available.

**Staff:** At scale, I/O generation choice matters. `FileChannel`
with direct `ByteBuffer` (off-heap) avoids double-buffering (OS
buffer to heap). `transferTo()` maps to the OS `sendfile()` syscall
for zero-copy file serving. Memory-mapped files via `MappedByteBuffer`
allow random access to files larger than RAM.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                | Reality                                                                                        | Danger                                                       |
| --- | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| 1   | `java.util.Date` is the correct class for dates              | `Date` is legacy and mutable. Use `java.time.LocalDate`, `Instant`, `ZonedDateTime` (Java 8+)  | Time zone bugs, threading issues in production               |
| 2   | `java.io.File` and `java.nio.file.Files` are equivalent      | `File` returns booleans on failure. `Files` throws `IOException` with the reason               | Silent failures that are impossible to debug                 |
| 3   | All of `java.lang` is auto-imported including sub-packages   | Only `java.lang.*` is auto-imported. `java.lang.reflect.Method` still needs an explicit import | Compile error surprise                                       |
| 4   | `java.util.concurrent` is needed for any multi-threaded code | For truly immutable/read-only shared state, no synchronization is needed                       | Over-engineering with concurrent wrappers for immutable data |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - `java.io.File` silent failure**

Symptom: Application reports a file does not exist when it does;
or silently fails to delete/create a file.

Root cause: `File.delete()`, `File.createNewFile()`, and similar
methods return `boolean` - `false` on failure with no reason.

Diagnostic: Replace with NIO.2: `Files.delete(path)` throws
`NoSuchFileException` or `AccessDeniedException` - the exact reason
is always available.

Fix: Migrate to `java.nio.file.Files`. Convert old code with
`file.toPath()` as the bridge.

---

**Failure 2 - `SimpleDateFormat` corruption in multi-threaded code**

Symptom: Intermittent wrong dates in logs or database entries under
load.

Root cause: `java.text.SimpleDateFormat` maintains mutable internal
state. Sharing a `static SimpleDateFormat` across threads causes
data corruption.

Diagnostic: Look for `static SimpleDateFormat` fields. Thread dump
showing multiple threads in `format()` or `parse()`.

Fix: Use `java.time.format.DateTimeFormatter` (immutable, thread-safe).

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                      |
| ---------------- | --------------------------------------------------------- |
| 15 min           | Which packages are auto-imported; key classes per package |
| 30 min           | Add NIO vs classic I/O distinction                        |
| 45 min           | Add java.util.concurrent overview; Date vs java.time      |
| 1 hour           | Add JPMS module structure; File silent-failure trap       |
| 2 hours          | Read java.nio.file.Files javadoc; NIO Selector model      |

---

**[JUNIOR] Q1: Which Java package is automatically imported in every
Java file, and why?** [CONCEPTUAL]

_Why they ask:_ Baseline check - also tests why `String` and `System`
never need an import.

_Likely follow-up:_ "Does that include sub-packages?"

`java.lang` is the only package automatically imported by the Java
compiler into every `.java` file. This is why `String`, `Integer`,
`System`, `Object`, `Math`, `Thread`, and `Throwable` never need
explicit import statements.

It is auto-imported because it contains the foundation types every
Java program uses. Without it, every file would start with identical
boilerplate imports. The JVM loads `java.lang` before any user code.

Sub-packages are NOT auto-imported: `java.lang.reflect.Method` and
`java.lang.invoke.MethodHandle` require explicit imports even though
they are under the `java.lang` namespace.

In Java 9+, these classes are in the `java.base` module, which is
always implicitly available in the module system.

_What separates good from great:_ Knowing sub-packages are NOT
auto-imported, and connecting to `java.base` module in JPMS.

---

**[JUNIOR] Q2: What is the difference between `java.io.File` and
`java.nio.file.Path`?** [COMPARISON]

_Why they ask:_ Tests whether the candidate knows which API to use
for new code.

_Likely follow-up:_ "When would you still use `File`?"

The core difference is the error contract:

`java.io.File` (Java 1.0) uses boolean return values: `file.delete()`
returns `false` if deletion fails with no reason. `file.exists()`
returns `false` for both "doesn't exist" AND "permission denied to
check" - these are indistinguishable. Silent failures make debugging
extremely difficult.

`java.nio.file.Path` with `Files` (Java 7) uses exceptions:
`Files.delete(path)` throws `NoSuchFileException` or
`AccessDeniedException`. The exact failure is always available
in the stack trace.

Additional Path advantages: atomic move via `Files.move()` with
`StandardCopyOption.ATOMIC_MOVE`, symbolic link awareness,
`WatchService` for file change notifications, and integration with
Java streams via `Files.list()`, `Files.walk()`.

When to still use `File`: bridging to older APIs that require
`File` objects - use `path.toFile()` to convert.

_What separates good from great:_ The boolean vs exception difference
as the core reason, not just "it's newer."

---

**[MID] Q3: How is the standard library modularized in Java 9+?**
[CONCEPTUAL]

_Why they ask:_ Tests awareness of JPMS and its practical impact.

_Likely follow-up:_ "What can you do with this modularization?"

Java 9's Platform Module System (JPMS) split the JDK into ~70 named
modules. The key ones:

`java.base`: Always available. Contains `java.lang`, `java.util`,
`java.io`, `java.nio`, `java.net`, `java.security`, `java.math`.
Every module implicitly requires it.

`java.sql`: JDBC API. Requires `requires java.sql;` in
`module-info.java`.

`java.xml`: DOM, SAX, StAX, XSLT parsers.

`java.logging`: `java.util.logging`.

`java.desktop`: Swing, AWT, ImageIO.

Practical impact: `jlink` can create a minimal JVM image containing
only the modules your application uses - a typical server app needs
`java.base` + `java.sql` + maybe `java.logging`. This reduces Docker
image size from ~200MB to ~30-50MB.

_What separates good from great:_ Connecting JPMS to `jlink` for
minimal container images, and knowing that JPMS also prevents access
to JDK internals (like `sun.misc.Unsafe`) via the `--add-opens` flag.

---

**[MID] Q4: Why was `java.util.Date` replaced by `java.time`?**
[TRADE-OFF]

_Why they ask:_ Tests API evolution awareness.

_Likely follow-up:_ "Which `java.time` class for each use case?"

Three major problems with `java.util.Date`:

1. **Mutable and not thread-safe.** `date.setTime(millis)` mutates
   the object. Sharing a `Date` across threads causes race conditions,
   common in JPA entities.

2. **Confusing API.** `new Date(2024, 1, 1)` is NOT 2024-01-01. Year
   is offset from 1900 (so 2024 = 124) and months are 0-indexed
   (January = 0). This caused countless production bugs.

3. **No timezone model.** `Date` is just milliseconds since epoch
   with no timezone. `Calendar` was added for timezone handling but
   is mutable and complex.

The `java.time` package (Java 8, based on Joda-Time) is immutable
and thread-safe throughout:

- `LocalDate`: date without time/timezone
- `LocalDateTime`: date + time, no timezone
- `ZonedDateTime`: date + time + timezone (user-facing timestamps)
- `Instant`: machine timestamp (epoch millis, always UTC)
- `DateTimeFormatter`: thread-safe (unlike `SimpleDateFormat`)

_What separates good from great:_ Knowing `Instant` vs `ZonedDateTime`

- `Instant` for machine-to-machine (store as UTC), `ZonedDateTime`
  for user-facing local times.

---

**[SENIOR] Q5: What is the performance advantage of `java.nio` over
`java.io` for file processing?** [TRADE-OFF]

_Why they ask:_ Tests depth of I/O knowledge at the OS level.

_Likely follow-up:_ "What is zero-copy?"

Classic `java.io` is simpler but has two performance costs:

1. **Double-buffering.** Data moves: OS kernel buffer → Java heap
   buffer → your code. Each step copies bytes.

2. **Blocking.** Each read/write call blocks the thread until the OS
   completes it. High-concurrency servers need many threads.

`java.nio` improvements:

**Direct `ByteBuffer`** (`ByteBuffer.allocateDirect()`): Buffer lives
off-heap (not in the Java heap). OS can DMA directly into it without
copying to the heap. Avoids one copy step.

**Zero-copy with `transferTo()`**: `FileChannel.transferTo()` maps
to the OS `sendfile()` syscall. The kernel copies directly from the
file's page cache to the socket buffer without involving user space.
Used in HTTP file serving, Kafka log replication.

**Non-blocking `Selector`**: One thread can monitor thousands of
`SocketChannel` objects. The `Selector.select()` call returns only
channels with available data. This is how Netty/Undertow handle
100k+ connections with a small thread pool.

For high-throughput file processing (ETL, log parsing):

- Small files: `Files.readAllBytes()` is fine
- Large sequential: `FileChannel` + direct `ByteBuffer`
- Large random-access: memory-mapped `MappedByteBuffer`

_What separates good from great:_ Naming `sendfile()`/`transferTo()`
as zero-copy and knowing why direct buffers avoid double-buffering.

---

**[SENIOR] Q6: DEBUGGING: A developer reports their file deletion
code "works fine locally but fails silently in production."
Diagnose this.** [DEBUGGING]

_Why they ask:_ Tests ability to connect API design flaws to real
failure patterns.

_Likely follow-up:_ "How would you fix it?"

This is almost certainly a `java.io.File` API issue. The classic
pattern:

```java
// BAD - returns false silently, no diagnostic
boolean deleted = file.delete();
// deleted == false; no exception, no log, no stack trace
```

In production, `file.delete()` returns `false` when:

- File is locked by another process (Windows common)
- Insufficient permissions (container running as non-root)
- File does not exist (already deleted by another instance)
- NFS mount issues

Locally, none of these conditions apply, so it appears to work.

Diagnosis steps:

1. Search for `file.delete()` or `File` boolean-returning calls in
   the codebase
2. Add temporary `if (!file.delete()) { logger.error("delete failed
for {}", file.getAbsolutePath()); }` to get the location
3. Migrate to NIO.2 to get the real exception

Fix:

```java
// GOOD - throws NoSuchFileException, AccessDeniedException, etc.
Files.delete(path);
// Or to silently skip if absent:
Files.deleteIfExists(path);
```

_What separates good from great:_ Identifying that the root cause is
the boolean API design of `java.io.File` (not a permissions issue per
se) and proposing NIO.2 as the structural fix.

---

**[STAFF] Q7: How do you design a file processing pipeline that
handles 10GB files without running out of memory?** [ARCHITECTURE]

_Why they ask:_ Tests ability to reason about I/O APIs at scale.

_Likely follow-up:_ "What is the GC impact of direct buffers?"

Key techniques:

**1. Streaming, not loading.** Never `Files.readAllBytes()` for large
files - it loads everything into the heap. Use `Files.lines()` (lazy
`Stream<String>`) or `BufferedReader.lines()` for line-by-line processing.

**2. Memory-mapped files for random access.** `FileChannel.map()` with
`MapMode.READ_ONLY` creates a `MappedByteBuffer`. The OS manages paging

- only the accessed pages (4KB each) are loaded into RAM. A 10GB file
  can be "mapped" and randomly accessed without 10GB of RAM.

**3. Direct ByteBuffer for sequential processing.** Allocate a fixed
buffer (`ByteBuffer.allocateDirect(8192)`), loop: `channel.read(buffer)`,
flip, process, clear. The same buffer is reused for the entire file.

**4. Chunked parallel processing.** For CPU-bound processing (parsing,
transformation), split the file into chunks (`FileChannel.position()`)
and process with a `ForkJoinPool`. Chunk boundaries must respect record
delimiters.

GC impact of direct buffers: they live off-heap and are freed when
the GC collects the `ByteBuffer` wrapper object. Under memory pressure
without GC, direct buffer space can be exhausted. Use `-XX:MaxDirectMemorySize`
to control the limit.

_What separates good from great:_ Knowing `Files.lines()` returns a
lazy stream (single-pass, not loaded), and the difference between
heap `ByteBuffer` (GC'd) and direct `ByteBuffer` (off-heap, freed
with the wrapper object).

---

---

# Collections Framework Design: Interfaces, Implementations, Algorithms

**Interview Weight:** low-medium - Foundational; tests whether you
understand the design philosophy before diving into specific classes.

---

### 🎯 Model Answer

**30 seconds:**

> The Java Collections Framework separates type (interface) from
> storage strategy (implementation). `List`, `Set`, `Map`, `Queue`
> define contracts. `ArrayList`, `HashSet`, `HashMap`, `ArrayDeque`
> are implementations you choose based on access pattern and memory
> cost. The `Collections` utility class provides algorithms (sort,
> binarySearch, shuffle) that work on any implementation through
> the interface contract.

**3 minutes (Senior):**

> The design principle is interface-implementation separation: you
> code to `List<T>`, not `ArrayList<T>`, so you can swap the
> implementation without changing callers.
>
> Four root interfaces define the four access patterns: `List`
> (ordered, indexed, duplicates allowed), `Set` (unique, no
> guaranteed order unless TreeSet/LinkedHashSet), `Queue` (FIFO
> or priority ordering), and `Map` (key-value, not a `Collection`
> subtype). `Deque` extends `Queue` for both-end access.
>
> Each interface has multiple implementations trading off speed,
> memory, and ordering: `ArrayList` vs `LinkedList` for `List`,
> `HashSet` vs `TreeSet` vs `LinkedHashSet` for `Set`,
> `HashMap` vs `TreeMap` vs `LinkedHashMap` for `Map`.
>
> The `Collections` utility class provides algorithm implementations:
> `Collections.sort()` uses TimSort (merge + insertion, O(n log n)),
> `Collections.binarySearch()` requires a sorted list,
> `Collections.shuffle()` is Fisher-Yates. These work on any
> `List` implementation through the interface contract.

**Framework:** INTERFACES (contract) + IMPLEMENTATIONS (strategy)

- ALGORITHMS (utility) = Strategy Pattern at scale

_Adapting up:_ Discuss how the framework uses the Iterator pattern,
Comparable/Comparator for ordering, and how Java 8+ streams are
a separate pipeline that works on top of the collections.

_Adapting down:_ List vs Set vs Map - what each stores, one
example of each.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Collections Framework
design - the key insight is interface-implementation separation:
you program to List, not ArrayList, so you can swap storage
strategies."

**(2) First principles:** "A collection framework needs to answer:
what operations are needed (interface) and how to store data
efficiently (implementation). Separating these lets you change
the storage without changing the contract."

**(3) Bridge:** "The Collections Framework is like a car rental:
the interface is 'a vehicle' (drive, steer, brake), the
implementations are sedan, SUV, truck. You drive the same way;
the storage capacity and fuel cost differ. You pick the right
one for the cargo."

---

### 📘 Concept Explanation

**What it is:**

A unified architecture for representing and manipulating collections
of objects. First introduced in Java 1.2, significantly expanded
in Java 5 (generics) and Java 8 (streams, default methods).

**The hierarchy:**

```
java.util.Iterable
  java.util.Collection
    java.util.List      (ordered, indexed, allows duplicates)
      ArrayList         linked: O(1) get, O(n) insert middle
      LinkedList        O(n) get, O(1) add at ends
      Vector            legacy, synchronized - avoid
      Stack             legacy, use Deque instead

    java.util.Set       (unique elements)
      HashSet           O(1) contains, no order
      LinkedHashSet     O(1) contains, insertion order
      TreeSet           O(log n) contains, sorted order

    java.util.Queue     (FIFO or priority)
      ArrayDeque        resizable circular array, preferred
      LinkedList        implements both List and Deque
      PriorityQueue     heap-based, O(log n) poll
      BlockingQueue (j.u.c.)
        ArrayBlockingQueue   bounded
        LinkedBlockingQueue  bounded or unbounded

    java.util.Deque     (double-ended queue)
      ArrayDeque        preferred over Stack/LinkedList

java.util.Map           (NOT a Collection)
  HashMap               O(1) get/put, no order
  LinkedHashMap         O(1) get/put, insertion or access order
  TreeMap               O(log n) get/put, sorted by key
  Hashtable             legacy, synchronized - avoid
  ConcurrentHashMap (j.u.c.)  thread-safe, O(1) reads
  EnumMap               dense array, best for enum keys
```

**The algorithms (Collections utility class):**

```java
Collections.sort(list)           // TimSort, O(n log n)
Collections.sort(list, cmp)      // with custom Comparator
Collections.binarySearch(list, key)  // O(log n), list must be sorted
Collections.shuffle(list)        // Fisher-Yates random permutation
Collections.min(collection)      // O(n) linear scan
Collections.max(collection)
Collections.frequency(coll, obj) // count occurrences
Collections.disjoint(c1, c2)     // true if no common elements
Collections.nCopies(n, obj)      // immutable list of n copies
```

**Design patterns used:**

- **Iterator pattern**: every Collection is `Iterable<T>`, providing
  `Iterator<T>` for sequential access without exposing internals
- **Strategy pattern**: algorithms in `Collections` work on any
  implementation through the `List`/`Collection` interface
- **Adapter pattern**: `Arrays.asList()` wraps an array as a `List`

**Interface default methods (Java 8+):**

`Collection.removeIf()`, `List.sort()`, `Map.getOrDefault()`,
`Map.putIfAbsent()`, `Map.computeIfAbsent()` were added via default
methods, extending the framework without breaking implementations.

---

### 💻 Code Example

#### Interface-implementation swap (Wrong vs Right)

```java
// BAD: coded to implementation - hard to swap
private ArrayList<String> names = new ArrayList<>();

public ArrayList<String> getNames() {
    return names;
}
// Caller is now forced to use ArrayList,
// cannot swap to LinkedList or an unmodifiable list
```

> **Code walkthrough:** Returning `ArrayList` exposes the
> implementation detail. Every caller depends on `ArrayList`-specific
> methods (like `ensureCapacity()`). Changing to a different List
> implementation requires changing the method signature and all callers.

```java
// GOOD: code to the interface
private List<String> names = new ArrayList<>();

public List<String> getNames() {
    // Protect: return unmodifiable view
    return Collections.unmodifiableList(names);
}
// Internally can swap to LinkedList, List.of(), etc.
// without changing the public contract
```

> **Code walkthrough:** The public API contract is `List<T>` -
> the smallest interface that satisfies the caller's needs. The
> ArrayList implementation can be swapped to any List without
> touching callers. `Collections.unmodifiableList()` prevents callers
> from mutating internal state - critical when exposing collections
> from encapsulated objects.

---

#### Choosing the right implementation

```java
// Scenario: need fast lookup by key, insertion order matters
// BAD: HashMap - O(1) lookup but no insertion order
Map<String, User> cache = new HashMap<>();

// GOOD: LinkedHashMap - O(1) lookup + insertion order preserved
Map<String, User> cache = new LinkedHashMap<>();

// Or for LRU cache (evict least-recently-accessed):
Map<String, User> lruCache = new LinkedHashMap<>(
    16, 0.75f, true) { // accessOrder=true
    @Override
    protected boolean removeEldestEntry(Map.Entry e) {
        return size() > MAX_CACHE_SIZE;
    }
};
```

> **Code walkthrough:** `LinkedHashMap` with `accessOrder=true`
> moves accessed entries to the tail on every `get()`. Overriding
> `removeEldestEntry()` enables automatic eviction when the size
> exceeds the limit - this is a complete O(1) LRU cache in 5 lines,
> available purely from the standard library.

---

### 🎓 Answers by Seniority

**Junior:** There are four main interfaces: `List` (ordered, allows
duplicates), `Set` (unique elements), `Map` (key-value pairs), `Queue`
(FIFO). Common implementations: `ArrayList` for most List use cases,
`HashMap` for most Map use cases, `HashSet` for unique collections.

**Mid-level:** The design separates interface from implementation so
you code to `List<T>` not `ArrayList<T>`. This allows swapping
implementations without changing callers. Choose based on access
pattern: `ArrayList` for indexed access, `LinkedList` for frequent
head/tail ops, `TreeMap` for sorted key iteration, `LinkedHashMap`
for insertion-ordered maps.

**Senior:** The Iterator pattern lets `Collections.sort()` work on
any List without knowing its storage. Java 8 added default methods
to extend the interfaces (`removeIf`, `computeIfAbsent`) without
breaking implementations. `EnumMap` is often overlooked: for enum
keys it uses a dense array internally - O(1) with better cache
locality than HashMap.

**Staff:** Collections framework design decisions have long-term
consequences. Returning `List<T>` from a public API is a commitment
to ordered, indexed access. If you later discover you need uniqueness,
changing to `Set<T>` is a breaking change. Design review question:
"What is the minimal interface that satisfies the consumer's needs?"
At scale, choose `ArrayList` over `LinkedList` in 95% of cases -
`LinkedList`'s pointer chasing is catastrophic for CPU cache
performance compared to `ArrayList`'s contiguous memory.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                          | Reality                                                                                                                                                                                                                                                               | Danger                                                                                        |
| --- | ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| 1   | `LinkedList` is faster than `ArrayList` for insertions | `LinkedList` is faster only for O(1) add at head/tail. For middle insertions it needs O(n) traversal first, then pointer updates; ArrayList does O(n) array copy which is extremely cache-friendly. In practice ArrayList beats LinkedList even for middle insertions | Choosing LinkedList for "insert performance" and making things worse                          |
| 2   | `HashMap` maintains insertion order                    | `HashMap` has no ordering guarantee. `LinkedHashMap` maintains insertion order. `TreeMap` maintains sorted key order                                                                                                                                                  | Depending on HashMap order (which may happen to work on one JVM version and break on another) |
| 3   | `Collections.sort()` is unstable                       | `Collections.sort()` uses TimSort which IS stable (equal elements maintain their relative order). `Arrays.sort(int[])` uses dual-pivot QuickSort which is NOT stable, but for primitive arrays stability is irrelevant                                                | Incorrect assumptions about element ordering after sort                                       |
| 4   | `Arrays.asList()` and `List.of()` are equivalent       | `Arrays.asList()` returns a fixed-size but mutable list (you can `set()` but not `add()`/`remove()`). `List.of()` returns a fully immutable list (throws on any structural modification AND on `set()`)                                                               | UnsupportedOperationException surprises                                                       |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - `ConcurrentModificationException` during iteration**

Symptom: `java.util.ConcurrentModificationException` in a for-each
loop.

Root cause: Structural modification (add/remove) of a `java.util`
collection during iteration. The iterator's `expectedModCount`
diverges from the collection's `modCount`.

Fix: Use `Iterator.remove()`, `list.removeIf()`, or collect items to
remove then call `list.removeAll(toRemove)` after the loop.

---

**Failure 2 - `UnsupportedOperationException` on "list"**

Symptom: `UnsupportedOperationException` when calling `add()` or
`remove()` on what appears to be a list.

Root cause: `Arrays.asList()` or `List.of()` was used. Both return
non-structural modification views.

Diagnostic: Check stack trace - the exception comes from
`AbstractList.add()`. Look for `Arrays.asList()` or `List.of()` in
the call chain.

Fix: Wrap in `new ArrayList<>(Arrays.asList(...))` to get a fully
mutable list.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                       |
| ---------------- | ---------------------------------------------------------- |
| 15 min           | 4 interfaces; key implementations; ArrayList vs HashMap    |
| 30 min           | Add implementation selection criteria                      |
| 45 min           | Add Collections algorithms; Iterator pattern               |
| 1 hour           | Add LinkedHashMap LRU; Arrays.asList vs List.of            |
| 2 hours          | Read Collections Javadoc; implement LRU cache from scratch |

---

**[JUNIOR] Q1: What are the four root collection interfaces in Java?**
[CONCEPTUAL]

_Why they ask:_ Baseline knowledge check.

_Likely follow-up:_ "What is the difference between List and Set?"

The four root interfaces in `java.util`:

**List**: ordered sequence, indexed access (get by index), allows
duplicates. Use when element order matters or you need positional
access. Implementations: `ArrayList` (contiguous array, fast
random access), `LinkedList` (pointer chain, fast head/tail ops).

**Set**: unique elements, no duplicates by contract. `HashSet` (O(1)
contains, no order), `LinkedHashSet` (insertion order), `TreeSet`
(sorted order, O(log n) operations).

**Queue**: elements added at the back, removed from the front (FIFO).
`ArrayDeque` (preferred), `PriorityQueue` (heap-based priority).
`Deque` extends Queue for both-end access.

**Map**: key-value pairs. Not a sub-interface of `Collection`. Keys
are unique. `HashMap` (O(1), no order), `TreeMap` (sorted keys),
`LinkedHashMap` (insertion or access order).

_What separates good from great:_ Knowing Map is NOT a Collection
subtype and explaining why (it represents associations, not a
"group of elements").

---

**[JUNIOR] Q2: When would you use `LinkedList` instead of `ArrayList`?**
[TRADE-OFF]

_Why they ask:_ Tests understanding of implementation trade-offs.

_Likely follow-up:_ "Is there a case where you should ALWAYS prefer
LinkedList?"

`ArrayList` should be your default. It beats `LinkedList` in almost
every benchmark because of CPU cache effects: `ArrayList` stores
elements in contiguous memory - iterating it is a sequential memory
scan (cache-friendly). `LinkedList` nodes are scattered on the heap -
each `next()` is a pointer chase (cache miss).

When `LinkedList` wins: O(1) add/remove at the HEAD of the list when
you have the reference (not when you need to traverse to find it).
A deque (double-ended queue) use case: `queue.addFirst()` and
`queue.pollFirst()` or `queue.addLast()` and `queue.pollLast()`.

But even then: use `ArrayDeque` instead. `ArrayDeque` is a circular
array with O(1) amortized add/remove at both ends AND better cache
performance than `LinkedList`. The Java docs say `ArrayDeque` is
"likely to be faster than LinkedList when used as a queue."

Rule of thumb: `ArrayList` for list, `ArrayDeque` for queue/stack,
`LinkedList` is rarely the right choice.

_What separates good from great:_ Recommending `ArrayDeque` instead
of `LinkedList` for queue/deque use cases.

---

**[MID] Q3: What is the difference between `Arrays.asList()` and
`List.of()`?** [COMPARISON]

_Why they ask:_ A common source of `UnsupportedOperationException` bugs.

_Likely follow-up:_ "How do you create a fully mutable list from an array?"

Both create a list backed by an array, but with different mutability:

`Arrays.asList(array)`: Returns a fixed-SIZE list backed by the array.
You CAN call `set(index, value)` (element replacement). You CANNOT
call `add()` or `remove()` (structural modification) - these throw
`UnsupportedOperationException`. The list is also a LIVE VIEW of the
original array - mutations via `set()` are reflected in the array.

`List.of(elements...)` (Java 9+): Returns a FULLY immutable list.
`set()`, `add()`, and `remove()` all throw `UnsupportedOperationException`.
It also disallows `null` elements (throws `NullPointerException` on
construction). Not backed by an array - it is a separate object.

To get a fully mutable list from an array:

```java
List<String> mutable = new ArrayList<>(Arrays.asList(array));
// or
List<String> mutable = new ArrayList<>(List.of(elements));
```

_What separates good from great:_ Knowing `Arrays.asList()` is a
LIVE VIEW of the array (mutating the list via `set()` mutates the
original array).

---

**[MID] Q4: How does `Collections.sort()` work and what algorithm
does it use?** [CONCEPTUAL]

_Why they ask:_ Tests algorithmic awareness tied to standard library.

_Likely follow-up:_ "Is it stable? Does it matter?"

`Collections.sort()` uses TimSort - a hybrid of merge sort and
insertion sort. Characteristics:

- **Time complexity**: O(n log n) worst case, O(n) for nearly-sorted
  data (the "natural run" detection)
- **Stable**: equal elements maintain their relative order. This
  matters when sorting by one field then another: sort by name, then
  stable-sort by age - elements with the same age preserve their
  name order.
- **Space complexity**: O(n) for the merge scratch space

TimSort is also used by Python's `sorted()`, making it one of the
most battle-tested sort algorithms in production.

`Arrays.sort(Object[])` also uses TimSort. `Arrays.sort(int[])` uses
dual-pivot Quicksort (not stable, but stability is irrelevant for
primitives).

`Collections.sort(list, comparator)` delegates to `list.sort(comparator)`
(Java 8+) which calls `Arrays.sort()` on the backing array.

_What separates good from great:_ Knowing TimSort detects existing
sorted runs, making it O(n) for nearly-sorted data - relevant for
production lists that are often "almost sorted."

---

**[SENIOR] Q5: DEBUGGING: A team is getting `ConcurrentModificationException`
only on some requests, not all. What is happening?** [DEBUGGING]

_Why they ask:_ Tests concurrent iteration failure pattern knowledge.

_Likely follow-up:_ "How would you fix it without switching to a
concurrent collection?"

`ConcurrentModificationException` on some requests suggests a race
condition - two threads sharing the same collection, one iterating
while another modifies.

Diagnosis steps:

1. Add `Thread.currentThread().getName()` to the exception handler
   to confirm two different threads are involved
2. Find the shared collection - look for non-final fields in
   service/singleton classes that hold collection references
3. Check if a `static` or instance-level collection is iterated
   in one place and modified in another without synchronization

The modCount mechanism that triggers the exception is NOT guaranteed
to always fire in concurrent scenarios (modCount is not volatile,
so a CPU's cache might not see the change immediately). This means:

- Sometimes it fires (lucky visibility)
- Sometimes it silently produces wrong results (missed visibility)

Fix options:

1. `CopyOnWriteArrayList`: iteration sees a stable snapshot, writes
   create a new copy. Good for read-heavy, rare-write scenarios.
2. `Collections.synchronizedList(list)` with explicit synchronized
   block around iteration: `synchronized(list) { for (item : list) }`
3. Redesign: avoid sharing mutable collections across threads -
   pass immutable snapshots (`List.copyOf()`) instead.

_What separates good from great:_ Noting that `ConcurrentModificationException`
is best-effort and may NOT fire even when concurrent modification
occurs - the absence of the exception does not mean thread safety.

---

**[SENIOR] Q6: How would you implement an LRU cache using only the
Java standard library?** [HANDS-ON]

_Why they ask:_ Tests depth of Collections knowledge and ability to
use framework features creatively.

_Likely follow-up:_ "What is the thread-safety of your solution?"

The `LinkedHashMap` with `accessOrder=true` and overriding
`removeEldestEntry()` is the standard answer:

```java
public class LRUCache<K, V> extends LinkedHashMap<K, V> {
    private final int capacity;

    public LRUCache(int capacity) {
        // accessOrder=true: get() moves entry to tail
        super(capacity, 0.75f, true);
        this.capacity = capacity;
    }

    @Override
    protected boolean removeEldestEntry(
            Map.Entry<K, V> eldest) {
        return size() > capacity; // evict when over limit
    }
}
```

Usage: `LRUCache<String, User> cache = new LRUCache<>(1000);`
Each `get()` promotes the entry to the tail. When size exceeds
capacity, `removeEldestEntry()` returns true and the eldest
(least recently accessed) entry is automatically removed.

Thread safety: this implementation is NOT thread-safe. Options:

- Wrap with `Collections.synchronizedMap(cache)` - but `get()`
  must also be synchronized externally
- Use `ConcurrentHashMap` with a `LinkedBlockingDeque` for the
  access order tracking (more complex but lock-free)
- Or use Caffeine/Guava Cache for production use

_What separates good from great:_ Knowing `accessOrder=true` in
the `LinkedHashMap` constructor (not the default insertion order)
is what makes it LRU, and identifying the thread-safety gap.

---

**[STAFF] Q7: How would you choose between `EnumMap` and `HashMap`
when keys are enum values?** [TRADE-OFF]

_Why they ask:_ Tests knowledge of specialized implementations.

_Likely follow-up:_ "Are there any HashMap operations EnumMap doesn't support?"

`EnumMap` should always be preferred over `HashMap` when keys are
enum values:

**Internal implementation**: `EnumMap` uses a dense array indexed
by the ordinal of the enum constant. If the enum has 10 values,
the map is backed by a 10-element array. There is no hashing, no
collision handling, no load factor.

**Performance**: O(1) get/put with no hash computation and excellent
CPU cache performance (array = contiguous memory). Iteration is in
enum declaration order (predictable).

**Memory**: A `HashMap<MyEnum, V>` wraps each key in an `Entry`
object with a hash. `EnumMap` stores only values - the key is
implicit in the array index.

**When HashMap wins**: when enum constants are not known at compile
time (dynamic key sets), or when null keys are needed (`EnumMap`
throws on null keys, same as `HashMap` but more explicit).

`EnumSet` has the same advantage for Set use cases: it is
implemented as a bit vector (one `long` for up to 64 enum constants).
`contains()` is a single bit-AND operation.

_What separates good from great:_ Knowing `EnumSet` alongside
`EnumMap`, and the bit-vector implementation of `EnumSet` for
extremely fast set operations on enum types.

---

---

# java.util.concurrent: The Parallel Universe for Thread Safety

**Interview Weight:** medium - Core senior Java question; demonstrates
whether you know thread-safe primitives and when to use each.

---

### 🎯 Model Answer

**30 seconds:**

> `java.util.concurrent` (j.u.c.) was introduced in Java 5 to replace
> coarse-grained synchronized blocks and the `synchronized` collection
> wrappers. It provides: fine-grained concurrent collections
> (ConcurrentHashMap), blocking queues for producer-consumer patterns,
> the Executor framework for thread pool management, atomic variables
> for lock-free counter/reference updates, and explicit Lock
> implementations (ReentrantLock, ReadWriteLock) that offer more
> control than `synchronized`.

**3 minutes (Senior):**

> The pre-Java-5 approach was either `synchronized` methods/blocks
> (acquiring one object lock) or `Collections.synchronizedList()`
> (wrapping with synchronized methods). Both are coarse-grained:
> they serialize ALL operations, including reads that could safely
> run concurrently.
>
> j.u.c. solves this with three mechanisms:
>
> 1. Lock-free algorithms using CAS (compare-and-swap) hardware
>    instruction. `AtomicInteger.incrementAndGet()` is a CAS loop -
>    no mutex acquired. `ConcurrentHashMap` reads are lock-free (Java 8).
> 2. Fine-grained locking. `ConcurrentHashMap` (Java 8) locks only
>    the individual bucket being written, not the entire map.
> 3. Blocking primitives. `LinkedBlockingQueue.take()` blocks the
>    thread until an element is available, avoiding busy-waiting.
>    `CountDownLatch`, `CyclicBarrier`, `Semaphore` are coordination
>    primitives for thread synchronization.
>
> The Executor framework separates task submission from thread
> management: `ExecutorService.submit(callable)` returns a `Future<T>`,
> and the thread pool decides which thread runs it. `CompletableFuture`
> (Java 8) chains async operations and handles exceptions in the
> async pipeline.

**Framework:** PROBLEM (coarse locks) -> THREE MECHANISMS (CAS, fine
locks, blocking) -> KEY-CLASSES + WHEN-TO-USE

_Adapting up:_ Discuss the Java Memory Model (happens-before) and
how j.u.c. provides happens-before guarantees (synchronizer actions),
and how `StampedLock` provides an optimistic read path.

_Adapting down:_ ConcurrentHashMap for thread-safe maps, ExecutorService
for thread pools, AtomicInteger for counters.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about java.util.concurrent - the
thread-safety toolkit. The main categories: concurrent collections
(ConcurrentHashMap), executor framework (thread pools), atomic
variables (lock-free counters), and synchronizers (CountDownLatch)."

**(2) First principles:** "Thread safety requires that two threads
accessing shared mutable state do not corrupt it. Synchronized
blocks (one mutex for everything) work but serialize even reads.
j.u.c. achieves thread safety with finer granularity - different
strategies for different contention patterns."

**(3) Bridge:** "j.u.c. is like a bank: synchronized is one teller
serving every customer serially. j.u.c. is multiple specialized
windows - deposits, withdrawals, inquiries, each with their own
queue - serving customers concurrently."

---

### 📘 Concept Explanation

**What it is:**

The `java.util.concurrent` package (Java 5, JSR-166) provides
building blocks for concurrent programming. Designed by Doug Lea
to replace ad-hoc synchronized code with well-tested, optimized
concurrent primitives.

**Category map:**

```
CONCURRENT COLLECTIONS
  ConcurrentHashMap     O(1) reads (lock-free), fine-grained writes
  CopyOnWriteArrayList  read-lock-free, write copies the array
  ConcurrentLinkedQueue lock-free queue (CAS-based)
  ConcurrentSkipListMap sorted concurrent map (skip list)

BLOCKING QUEUES (producer-consumer)
  ArrayBlockingQueue    bounded, backed by array, FIFO
  LinkedBlockingQueue   bounded or unbounded, linked nodes
  PriorityBlockingQueue unbounded, priority order
  SynchronousQueue      zero-capacity: handoff only
  DelayQueue            elements become available after delay

EXECUTOR FRAMEWORK
  Executor              submit(Runnable)
  ExecutorService       submit(Callable<T>): Future<T>
  Executors             factory: newFixedThreadPool(n),
                                 newCachedThreadPool(),
                                 newSingleThreadExecutor()
  ScheduledExecutorService  schedule(task, delay, unit)
  ForkJoinPool          work-stealing for divide-and-conquer

FUTURES & ASYNC COMPOSITION
  Future<T>             get() blocks until result available
  CompletableFuture<T>  chain async operations (thenApply,
                        thenCompose, exceptionally, allOf)

ATOMIC VARIABLES (lock-free)
  AtomicInteger         incrementAndGet(), compareAndSet()
  AtomicLong
  AtomicReference<T>    compareAndSet() for object references
  AtomicIntegerArray    per-element atomic ops on arrays
  LongAdder             high-contention counter (striped)
  LongAccumulator       generalized atomic accumulator

LOCKS
  ReentrantLock         explicit lock/unlock, tryLock(timeout)
  ReentrantReadWriteLock  separate read/write locks
  StampedLock           optimistic reads (no lock acquisition)
  Condition             await/signal (more flexible than wait/notify)

SYNCHRONIZERS
  CountDownLatch        await until count reaches 0, one-shot
  CyclicBarrier         await until N threads arrive, reusable
  Semaphore             control access to N permits
  Phaser                generalized barrier (flexible party count)
  Exchanger             swap data between two threads
```

**Key design: CAS (compare-and-swap):**

Hardware CAS: "if memory location M has value OLD, set it to NEW
atomically." Implemented in a single CPU instruction (`CMPXCHG` on
x86). j.u.c. atomics use CAS loops:

```
loop:
  read current value
  compute new value
  CAS(memory, current, new) -> if CPU wins, done
                             -> if lost (another thread wrote first), retry loop
```

This is optimistic concurrency: assume no contention, retry on failure.
Under low contention, zero lock overhead. Under high contention,
retries become expensive - use `LongAdder` (striped accumulator)
instead of `AtomicLong` for high-contention counters.

---

### 💻 Code Example

#### ExecutorService + CompletableFuture (production pattern)

```java
import java.util.concurrent.*;
import java.util.List;

public class AsyncProcessor {
    private final ExecutorService pool =
        Executors.newFixedThreadPool(
            Runtime.getRuntime().availableProcessors());

    // BAD: blocking approach - each call blocks a thread
    public List<Result> processBlocking(List<Item> items) {
        return items.stream()
            .map(item -> expensiveOp(item)) // blocks
            .collect(java.util.stream.Collectors.toList());
    }

    // GOOD: async approach with CompletableFuture
    public CompletableFuture<List<Result>> processAsync(
            List<Item> items) {
        List<CompletableFuture<Result>> futures = items.stream()
            .map(item -> CompletableFuture.supplyAsync(
                () -> expensiveOp(item), pool))
            .collect(java.util.stream.Collectors.toList());

        return CompletableFuture.allOf(
                futures.toArray(new CompletableFuture[0]))
            .thenApply(v -> futures.stream()
                .map(CompletableFuture::join)
                .collect(java.util.stream.Collectors.toList()));
    }

    private Result expensiveOp(Item item) { /* ... */ return null; }
    record Item(String id) {}
    record Result(String val) {}
}
```

> **Code walkthrough:** `CompletableFuture.supplyAsync()` submits
> each item's processing to the thread pool without blocking the
> caller. `allOf()` waits for all futures to complete. `join()`
> (unlike `get()`) throws unchecked exceptions, suitable for
> stream usage. The fixed thread pool is bounded to
> `availableProcessors` to prevent thread explosion under load.

---

#### ConcurrentHashMap vs synchronized (thread safety comparison)

```java
// BAD: HashMap with external synchronization
// entire map locked for every operation
private final Map<String, Integer> counts =
    Collections.synchronizedMap(new HashMap<>());

// Every call acquires the same lock - reads block reads
counts.put("key", counts.getOrDefault("key", 0) + 1);
// BUG: not atomic - read + increment + put is 3 operations
// another thread can interleave between them

// GOOD: ConcurrentHashMap with atomic compute
private final ConcurrentHashMap<String, Integer> counts =
    new ConcurrentHashMap<>();

// Atomic: entire read-modify-write is one operation
counts.merge("key", 1, Integer::sum);
// or
counts.compute("key", (k, v) -> v == null ? 1 : v + 1);
```

> **Code walkthrough:** `synchronizedMap` locks the whole map but
> the read-then-write pattern is still not atomic (race condition
> between `get` and `put`). `ConcurrentHashMap.merge()` is a
> single atomic operation - it reads and updates in one bucket-level
> lock acquisition. `merge(key, 1, Integer::sum)` means "add 1 to
> the current value, or set 1 if absent" atomically.

---

### 🎓 Answers by Seniority

**Junior:** `java.util.concurrent` provides thread-safe collections
like `ConcurrentHashMap` (thread-safe HashMap), `CopyOnWriteArrayList`
(thread-safe ArrayList), and `BlockingQueue` for producer-consumer
patterns. `ExecutorService` manages a thread pool.

**Mid-level:** Three main areas: concurrent collections
(`ConcurrentHashMap`, `CopyOnWriteArrayList`, `BlockingQueue`),
executor framework (`ExecutorService`, `CompletableFuture`), and
atomic variables (`AtomicInteger`, `AtomicReference`). Key principle:
prefer j.u.c. over raw `synchronized` because it uses finer-grained
locking and CAS operations.

**Senior:** ConcurrentHashMap reads are lock-free (Java 8+) because
reads don't need the bucket lock. `merge()` and `compute()` provide
atomic read-modify-write. `LongAdder` beats `AtomicLong` for
high-contention counters because it stripes the counter across
multiple cells - threads update different cells, then sum on
`longValue()`. Under low contention they're equivalent.

**Staff:** At scale, thread pool sizing is critical. `newCachedThreadPool()`
creates threads on demand up to `Integer.MAX_VALUE` - under load,
it creates thousands of threads causing memory exhaustion. Always
use bounded `newFixedThreadPool()` or `newWorkStealingPool()` in
production. `CompletableFuture` chains run on the
`ForkJoinPool.commonPool()` by default - always pass an explicit
executor for I/O-bound work to avoid blocking the common pool.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                 | Reality                                                                                                                                                                                                                    | Danger                                                                 |
| --- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 1   | `ConcurrentHashMap` makes all compound operations thread-safe | Individual operations (get, put) are thread-safe. Compound operations (check-then-act: "if absent, put") are NOT thread-safe unless using `computeIfAbsent()` or `merge()`                                                 | Race conditions on check-then-act patterns                             |
| 2   | `synchronized` on a method is equivalent to a `ReentrantLock` | `synchronized` cannot be interrupted while waiting, cannot try without blocking, and cannot have separate conditions. `ReentrantLock` supports `tryLock(timeout)`, `lockInterruptibly()`, and multiple `Condition` objects | Deadlock scenarios where `tryLock` with timeout would prevent deadlock |
| 3   | `volatile` makes a field fully thread-safe                    | `volatile` only guarantees visibility (reads always see the latest write) and prevents reordering. It does NOT make compound operations (read-modify-write like `i++`) atomic                                              | Race condition on `volatile int counter` with `counter++`              |
| 4   | `newCachedThreadPool()` is good for production                | It creates threads up to `Integer.MAX_VALUE`. Under load spikes it creates thousands of threads, exhausting memory                                                                                                         | OOM in production under unexpected load                                |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Thread pool exhaustion causing task queue build-up**

Symptom: Requests start queuing, latency spikes, eventually OOM or
timeouts.

Root cause: Fixed thread pool with blocking I/O tasks - all threads
blocked waiting for external I/O, new tasks queue up.

Diagnostic: Thread dump showing all worker threads in `WAITING` or
`BLOCKED` state in I/O calls. Queue size growing in JMX metrics.

Fix: Separate I/O thread pool from CPU thread pool. Use virtual
threads (Java 21) for I/O-heavy tasks.

---

**Failure 2 - Memory leak from `ThreadLocal` in thread pool**

Symptom: Memory grows over time; heap dump shows many thread-local
instances being held alive.

Root cause: `ThreadLocal` values set inside tasks are not removed
before the thread returns to the pool. The thread (and its
ThreadLocal map) live for the pool's lifetime.

Fix: Always call `threadLocal.remove()` in a `finally` block
when using ThreadLocal in pool tasks.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                      |
| ---------------- | --------------------------------------------------------- |
| 15 min           | ConcurrentHashMap vs synchronized; ExecutorService basics |
| 30 min           | Add CompletableFuture chaining; atomic variables          |
| 45 min           | Add BlockingQueue producer-consumer; LongAdder            |
| 1 hour           | Add CountDownLatch; thread pool sizing rules              |
| 2 hours          | Read Java Concurrency in Practice (JCIP) chapters 5-6     |

---

**[JUNIOR] Q1: What is the difference between `HashMap` and
`ConcurrentHashMap`?** [COMPARISON]

_Why they ask:_ Most common concurrent collection interview question.

_Likely follow-up:_ "Is `ConcurrentHashMap` slower than `HashMap`?"

`HashMap` is not thread-safe: concurrent reads while a resize is
happening can cause infinite loops (Java 7 - the circular linked
list bug). Even in Java 8+, concurrent modification produces
corrupted state.

`ConcurrentHashMap` provides thread safety without locking the entire
map: reads are lock-free (use volatile reads of the internal table).
Writes lock only the single bucket being modified (CAS for empty
buckets, synchronized for non-empty). This means reads never block
each other and writes to different buckets proceed in parallel.

Performance: `ConcurrentHashMap` has overhead compared to `HashMap`
due to volatile reads and CAS operations, but it is significantly
faster than `Collections.synchronizedMap(new HashMap<>())` under
contention because `synchronizedMap` acquires a single lock for
every operation including reads.

In summary: use `ConcurrentHashMap` for any shared mutable map.
The performance cost is negligible for correctness guarantee.

_What separates good from great:_ Knowing reads are lock-free in
`ConcurrentHashMap`, and that `merge()`/`compute()` provide atomic
compound operations.

---

**[JUNIOR] Q2: What is an `ExecutorService` and why use it instead
of creating threads directly?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of thread management.

_Likely follow-up:_ "What happens to a task submitted to a full thread pool?"

Creating threads with `new Thread(runnable).start()` has several
problems: thread creation is expensive (JVM + OS overhead), unbounded
thread creation leads to memory exhaustion, and there is no mechanism
to get results back or handle exceptions.

`ExecutorService` solves these with a thread pool: threads are created
once and reused. Task submission is `submit(Callable<T>)` which
returns `Future<T>` - you can wait for the result with `get()` and
handle exceptions.

The three standard pools from `Executors`:

- `newFixedThreadPool(n)`: always n threads, tasks queue when all busy
- `newCachedThreadPool()`: grows as needed, shrinks when idle (avoid in production)
- `newSingleThreadExecutor()`: one thread, tasks run sequentially in order

When a `FixedThreadPool` is full, additional tasks are queued in an
unbounded `LinkedBlockingQueue`. Under very high load, this queue can
grow until `OutOfMemoryError`. Always monitor queue depth in production.

_What separates good from great:_ Knowing the backing queue type
of `FixedThreadPool` (unbounded `LinkedBlockingQueue`) and that
unbounded queuing can cause OOM.

---

**[MID] Q3: What is `CompletableFuture` and how does it differ from
`Future`?** [COMPARISON]

_Why they ask:_ Tests awareness of async programming APIs.

_Likely follow-up:_ "What thread runs the callbacks?"

`Future<T>` (Java 5) represents a pending result. `future.get()`
blocks the calling thread until the result is available. It cannot
be composed, it has no callback mechanism, and cancellation is
coarse-grained.

`CompletableFuture<T>` (Java 8) adds non-blocking composition:

- `thenApply(Function)`: transform result without blocking
- `thenCompose(Function)`: chain another async operation (flatMap)
- `exceptionally(Function)`: handle exceptions in the chain
- `allOf(futures...)`: wait for multiple futures
- `anyOf(futures...)`: proceed when first future completes

```java
CompletableFuture.supplyAsync(() -> fetchUser(id))
    .thenApply(user -> enrichUser(user))
    .thenCompose(user -> saveAsync(user))
    .exceptionally(ex -> handleError(ex));
```

Thread execution: without an explicit executor, callbacks run on
`ForkJoinPool.commonPool()`. For I/O-heavy operations, always pass
an explicit `ExecutorService` to avoid starving the common pool.

_What separates good from great:_ Knowing that without an explicit
executor, `thenApply`/`thenCompose` run on the common pool, which
can be starved by blocking I/O.

---

**[SENIOR] Q4: When would you use `LongAdder` vs `AtomicLong`?**
[TRADE-OFF]

_Why they ask:_ Tests depth of lock-free concurrency knowledge.

_Likely follow-up:_ "Does `LongAdder` have any downside?"

Both `LongAdder` and `AtomicLong` are thread-safe counters. The
difference matters under high contention.

`AtomicLong.incrementAndGet()` uses a CAS loop: read, compute, CAS.
Under high contention (many threads incrementing simultaneously),
most threads' CAS fails (another thread won the CAS) and they
retry. This causes CPU spin and cache-line contention (all threads
competing for the same cache line).

`LongAdder` uses a striped approach: it maintains an array of
counters (`cells`). Threads increment different cells based on a
hash of their thread ID. Contention is distributed across cells.
`longValue()` sums all cells. This is much faster under high
contention because threads rarely compete for the same cell.

When to use each:

- `AtomicLong`: when you need exact current value frequently with
  `get()` and the increment rate is moderate. Also for CAS (compare-and-swap)
  semantics (`compareAndSet()`).
- `LongAdder`: high-frequency incrementing (metrics, counters) where
  you read the sum infrequently. `LongAdder` has no `get()` that
  is consistent with the increments - `longValue()` is a snapshot.

_What separates good from great:_ Knowing the striped cell approach
and identifying the trade-off: `LongAdder` is faster under
contention but `longValue()` is not a consistent snapshot with
in-progress increments.

---

**[SENIOR] Q5: DEBUGGING: A service is deadlocked. How do you
diagnose and fix it?** [DEBUGGING]

_Why they ask:_ Tests practical debugging skill for the hardest
concurrency bug.

_Likely follow-up:_ "How do you prevent deadlocks by design?"

Deadlock diagnosis:

1. `jstack <pid>` or `kill -3 <pid>`: prints all thread stacks.
   Look for threads in `BLOCKED` state waiting for a lock held by
   another `BLOCKED` thread.
2. JVM thread dump shows: `Thread-1 waiting for lock 0x...` and
   `Thread-2 waiting for lock 0x...` with circular dependency.
3. In VisualVM or JConsole: "Detect Deadlock" button highlights the
   cycle.

Typical patterns:

- Two threads acquiring locks A and B in opposite order
- Thread pool deadlock: a task submits a child task and `get()`s
  it, but all pool threads are waiting - no thread to run the child

Fix strategies:

1. **Lock ordering**: always acquire locks in the same global order
   (e.g., by lock ID). Prevents circular wait.
2. `ReentrantLock.tryLock(timeout)`: if timeout expires, release
   all held locks and retry - avoids indefinite waiting.
3. **Lock-free design**: use `ConcurrentHashMap.compute()` instead
   of manual synchronized blocks.
4. **Thread pool deadlock**: use a separate pool for child tasks,
   or use a `ForkJoinPool` which supports work stealing (child
   tasks can run on the same thread).

_What separates good from great:_ Identifying thread pool deadlock
as a distinct pattern (submitting blocking subtasks to the same
pool all threads are blocked in).

---

**[STAFF] Q6: How would you design a rate limiter using j.u.c.
primitives?** [ARCHITECTURE]

_Why they ask:_ Tests ability to compose j.u.c. primitives into
a real system design.

_Likely follow-up:_ "How would you make it distributed?"

Token bucket rate limiter using `Semaphore` + `ScheduledExecutorService`:

```java
public class RateLimiter {
    private final Semaphore tokens;
    private final int maxRate;
    private final ScheduledExecutorService scheduler;

    public RateLimiter(int requestsPerSecond) {
        this.maxRate = requestsPerSecond;
        // Start with full bucket
        this.tokens = new Semaphore(requestsPerSecond);
        this.scheduler = Executors
            .newSingleThreadScheduledExecutor();
        // Refill tokens every second
        scheduler.scheduleAtFixedRate(
            this::refill, 1, 1, TimeUnit.SECONDS);
    }

    private void refill() {
        int toAdd = maxRate - tokens.availablePermits();
        if (toAdd > 0) tokens.release(toAdd);
    }

    // Returns false immediately if rate limit exceeded
    public boolean tryAcquire() {
        return tokens.tryAcquire();
    }

    public void shutdown() { scheduler.shutdown(); }
}
```

The `Semaphore` is the token bucket. `tryAcquire()` attempts to
take a token without blocking - returns false if limit exceeded.
The `ScheduledExecutorService` refills tokens every second.

For distributed rate limiting: the local `Semaphore` would be
replaced with an atomic compare-and-set on a Redis counter (using
`INCR` + `EXPIRE`). The `ScheduledExecutorService` refill becomes
a Redis key TTL.

_What separates good from great:_ Using `Semaphore.tryAcquire()`
(non-blocking) vs `acquire()` (blocking), and sketching the path
to distributed rate limiting with Redis.

---

**[STAFF] Q7: TRADE-OFF: Virtual threads (Java 21) vs platform
threads + j.u.c. - when do you still need j.u.c.?** [TRADE-OFF]

_Why they ask:_ Tests awareness of Java 21 features and their
impact on concurrent programming patterns.

_Likely follow-up:_ "Does ConcurrentHashMap become unnecessary
with virtual threads?"

Virtual threads (Project Loom, Java 21) are lightweight threads
managed by the JVM, not the OS. Blocking I/O on a virtual thread
unmounts the thread from its carrier (a platform thread) while
the I/O waits - the carrier is free to run other virtual threads.

**What virtual threads make easier:**

- I/O-bound thread pools: can create millions of virtual threads -
  no need for `newFixedThreadPool(n)` tuned to I/O concurrency.
  `Thread.ofVirtual().start(task)` or `Executors.newVirtualThreadPerTaskExecutor()`.

**What still requires j.u.c.:**

- `ConcurrentHashMap`: thread safety of shared mutable state is
  independent of whether threads are virtual or platform. Multiple
  virtual threads modifying a `HashMap` still race.
- `Semaphore`, `CountDownLatch`, `CyclicBarrier`: coordination
  primitives remain necessary.
- `CompletableFuture`: async composition is a programming model
  choice, not just a performance optimization.
- `AtomicInteger`, `LongAdder`: lock-free counters are still
  needed for high-frequency concurrent updates.

Virtual threads replace the executor-per-I/O-task pattern. They
do NOT replace concurrent collections, atomic variables, or
explicit synchronizers.

_What separates good from great:_ Clearly separating "thread
management" (where virtual threads help) from "shared mutable
state safety" (where j.u.c. collections/atomics are still
required).

---

---

# Java I/O Generations: Streams, Readers/Writers, NIO, NIO.2

**Interview Weight:** low-medium - Foundational for senior engineers;
tests whether you know which I/O API to use and why.

---

### 🎯 Model Answer

**30 seconds:**

> Java has three I/O generations. Classic `java.io` (Java 1.0):
> blocking byte streams (InputStream/OutputStream) and character
> streams (Reader/Writer), the old `File` class. NIO (Java 1.4):
> non-blocking channels, typed buffers, and `Selector` for
> multiplexed I/O. NIO.2 (Java 7): modern file API with `Path`,
> `Files`, and `WatchService`. Use NIO.2 for all file operations
> in new code. Use NIO channels for high-performance network I/O.
> Use classic `java.io` streams when an API requires them.

**3 minutes (Senior):**

> Classic `java.io` was designed around blocking streams: every
> `read()` and `write()` call blocks until the OS completes the
> operation. This works for simple sequential I/O but requires one
> thread per connection for network servers - at 10,000 connections
> you need 10,000 threads.
>
> NIO (Java 1.4) introduced: (1) `Channel` - a bidirectional
> connection to an I/O resource supporting both reading and writing.
> (2) `ByteBuffer` - a typed buffer that data is read INTO (not
> into a `byte[]` directly). (3) `Selector` - a multiplexer that
> monitors multiple `SocketChannel` objects and returns only those
> ready for I/O. This is the reactor pattern: one thread handles
> thousands of connections.
>
> NIO.2 (Java 7) added a clean file API: `Path` (replaces `File`),
> `Files` utility class (throws exceptions instead of returning
> boolean), `FileSystems`, `FileVisitor`, and `WatchService`. This
> is unrelated to the networking NIO - it is simply a better file
> system API.

**Framework:** GENERATION (what it solved) + KEY-CLASSES + WHEN-TO-USE

_Adapting up:_ Discuss `AsynchronousFileChannel` (Java 7 async
file I/O with `CompletableFuture`), memory-mapped files
(`MappedByteBuffer`), and how Netty wraps NIO Selectors.

_Adapting down:_ Three generations: java.io (blocking), java.nio
(non-blocking channels), java.nio.file (modern file API).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Java I/O generations - three
main generations: classic blocking streams, NIO channels/buffers
for non-blocking, and NIO.2 modern file API."

**(2) First principles:** "I/O has two dimensions: blocking vs
non-blocking, and file vs network. Java evolved its APIs as
requirements changed: one thread per connection didn't scale, and
File's boolean return values made debugging impossible."

**(3) Bridge:** "Classic I/O is a garden hose - you hold it and
water flows through. NIO is an irrigation system - one pump controls
many pipes, each pipe has a valve, one person monitors all valves.
NIO.2 is just a better control panel for the hose."

---

### 📘 Concept Explanation

**Generation 1: `java.io` (Java 1.0) - Blocking Streams**

```
Byte streams (binary data):
  InputStream / OutputStream (abstract base)
  FileInputStream / FileOutputStream (file)
  BufferedInputStream / BufferedOutputStream (buffered)
  ObjectInputStream / ObjectOutputStream (serialization)
  ByteArrayInputStream / ByteArrayOutputStream (in-memory)
  DataInputStream / DataOutputStream (primitive types)

Character streams (text with encoding):
  Reader / Writer (abstract base)
  FileReader / FileWriter (file, uses default charset - avoid)
  InputStreamReader / OutputStreamWriter (byte-to-char bridge)
  BufferedReader / BufferedWriter (buffered)
  PrintWriter (formatted output)

File abstraction (legacy):
  File (represents path; boolean APIs; prefer Path instead)
```

Every operation blocks the calling thread until the OS completes it.
One thread per connection = the "C10K problem."

**Generation 2: `java.nio` (Java 1.4) - Non-blocking I/O**

```
ByteBuffer / CharBuffer / IntBuffer  (typed buffers with position/limit/capacity)
  allocate(n)     - heap buffer
  allocateDirect(n) - off-heap buffer (faster for I/O, avoids copy)

Channel (bidirectional, closeable)
  FileChannel             (file read/write, map, transferTo)
  SocketChannel           (TCP client, non-blocking)
  ServerSocketChannel     (TCP accept, non-blocking)
  DatagramChannel         (UDP)

Selector (I/O multiplexing - the reactor core)
  channel.register(selector, SelectionKey.OP_READ)
  selector.select()  - blocks until at least one channel ready
  selector.selectedKeys()  - iterate ready channels
```

The NIO programming model (reactor pattern):

```
register channels with Selector (non-blocking mode)
loop:
  selector.select()  <- blocks waiting for events
  for each ready key:
    if OP_ACCEPT: accept new connection, register new channel
    if OP_READ:   read from channel into ByteBuffer, process
    if OP_WRITE:  write ByteBuffer to channel
```

**Generation 3: `java.nio.file` (Java 7) - NIO.2 File API**

```
Path              (immutable path representation)
  Path.of("dir", "file.txt")  (Java 11; or Paths.get())
  path.resolve(other)
  path.getParent(), path.getFileName()
  path.toAbsolutePath()

Files (utility class - all methods throw IOException on failure)
  Files.readAllBytes(path)          small files only
  Files.readAllLines(path)          list of lines
  Files.lines(path)                 lazy Stream<String>
  Files.write(path, bytes)
  Files.copy(src, dst, options...)
  Files.move(src, dst, options...)
  Files.delete(path)                throws if not found
  Files.deleteIfExists(path)        silent if not found
  Files.exists(path)
  Files.createDirectories(path)
  Files.walk(path)                  lazy Stream<Path>
  Files.list(path)                  directory entries

WatchService  (file change notifications)
  FileSystems.getDefault().newWatchService()
  path.register(watcher, ENTRY_CREATE, ENTRY_MODIFY, DELETE)
  watcher.take()  // blocks until event
```

**When to use each:**

| Scenario                          | API                                    |
| --------------------------------- | -------------------------------------- |
| New file read/write code          | `java.nio.file.Files` + `Path`         |
| Parse large file line by line     | `Files.lines()` (lazy stream)          |
| High-throughput file copy         | `FileChannel.transferTo()` (zero-copy) |
| Random access large file          | `FileChannel.map()` (memory-mapped)    |
| Network server (many connections) | NIO `SocketChannel` + `Selector`       |
| Simple client HTTP call           | `HttpClient` (Java 11)                 |
| Legacy API requires `File`        | `path.toFile()` bridge                 |
| File change monitoring            | `WatchService`                         |

---

### 💻 Code Example

#### File reading: three generations

```java
import java.io.*;
import java.nio.file.*;

public class IOGenerations {

    // BAD: java.io.File - boolean failures, no encoding control
    static void readOldWay(String path) {
        File file = new File(path);
        if (!file.exists()) {
            // is this "not found" or "permission denied"? Unknown.
            System.err.println("file not found");
            return;
        }
        try (BufferedReader br =
                new BufferedReader(new FileReader(file))) {
            // FileReader uses platform default charset - DANGEROUS
            String line;
            while ((line = br.readLine()) != null) {
                process(line);
            }
        } catch (IOException e) { e.printStackTrace(); }
    }

    // GOOD: java.nio.file.Files - explicit exceptions, UTF-8
    static void readNIO2Way(Path path) throws IOException {
        // Files.lines: lazy stream, one line at a time
        // Automatically closed by try-with-resources on stream
        try (var lines = Files.lines(path,
                java.nio.charset.StandardCharsets.UTF_8)) {
            lines.forEach(IOGenerations::process);
        }
        // IOException includes: NoSuchFileException,
        // AccessDeniedException, FileSystemException
        // Stack trace tells you exactly what went wrong
    }

    static void process(String line) { /* ... */ }
}
```

> **Code walkthrough:** The old approach fails silently if
> `file.exists()` returns false for any reason (not found OR
> permission denied). `FileReader` uses the platform default charset
>
> - reading UTF-8 files on Windows with cp1252 default produces
>   corrupted text. `Files.lines()` throws `IOException` with the
>   exact reason, uses an explicit charset, and the try-with-resources
>   closes the underlying file channel automatically.

---

### 🎓 Answers by Seniority

**Junior:** `java.io` has `InputStream`/`OutputStream` for bytes and
`Reader`/`Writer` for text. `java.nio.file.Files` is the modern way
to read and write files. `Path` replaces `File`.

**Mid-level:** Three generations: `java.io` (blocking, `File` has
silent failures), `java.nio` (non-blocking channels + Selector for
server scalability), `java.nio.file` (clean file API - `Path`,
`Files`, always use for new code). `Files.lines()` returns a lazy
stream for large files without loading everything.

**Senior:** NIO's `Selector` enables the reactor pattern - one thread
monitoring thousands of `SocketChannel` objects, blocking only in
`selector.select()` until any channel has data. This is how Netty
achieves massive connection counts with a small thread pool. For
file I/O, `FileChannel.transferTo()` maps to the OS `sendfile()`
syscall (zero-copy) - data goes directly from file page cache to
socket buffer without user space involvement.

**Staff:** Memory-mapped files (`FileChannel.map()`) are the right
tool for random access in large files. The OS maps the file into
virtual address space - only the accessed pages (4KB) are loaded
into RAM, transparently paged in/out. A 100GB file can be processed
without 100GB of RAM. Caveat: `MappedByteBuffer` is not immediately
released when closed (a JVM bug/limitation) - use `Cleaner` or
`sun.misc.Unsafe.invokeCleaner()` to force release on Java 9+.

---

### ⚠️ Common Misconceptions

| #   | Misconception                              | Reality                                                                                                                                                                                                         | Danger                                                  |
| --- | ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| 1   | `FileReader` uses UTF-8 encoding           | `FileReader` uses the platform default charset (e.g., Windows-1252 on Windows). Always use `new InputStreamReader(new FileInputStream(file), StandardCharsets.UTF_8)` or `Files.newBufferedReader(path, UTF_8)` | Text corruption on non-UTF-8 platforms                  |
| 2   | NIO is always faster than classic I/O      | For simple sequential reads of single files, buffered `java.io` streams are comparable. NIO wins for concurrent access to many files/connections or when zero-copy is available                                 | Premature NIO migration for simple cases                |
| 3   | `Files.lines()` loads the entire file      | `Files.lines()` returns a lazy `Stream<String>` - lines are read one at a time. However, the underlying stream MUST be closed (try-with-resources) to release the file handle                                   | File handle leak if stream is not closed                |
| 4   | `Path` and `File` represent the same thing | `Path` is an interface (can represent paths in non-default file systems, e.g., ZipFileSystem). `File` is always a platform file system path. `Path.of("zipfs:/...")` works; `new File("zipfs:/...")` doesn't    | Missing NIO.2 capabilities when bridging to legacy code |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - File handle leak from unclosed stream**

Symptom: `Too many open files` OS error after hours or days of
running. JVM eventually crashes.

Root cause: `InputStream`, `Files.lines()`, or `FileChannel` not
closed on every code path. Exceptions bypass the close call.

Diagnostic: `lsof -p <pid>` (Linux) counts open file handles.
Heap dump shows many unclosed `FileInputStream` or similar objects.

Fix: Always use try-with-resources: `try (InputStream in = Files.newInputStream(path))`.

---

**Failure 2 - `FileReader` charset mismatch**

Symptom: Text files display correctly locally (macOS/Linux, UTF-8)
but show garbled characters in production (Windows, cp1252).

Root cause: `FileReader` uses `Charset.defaultCharset()` which
differs per platform.

Fix: Replace `new FileReader(file)` with `Files.newBufferedReader(path, StandardCharsets.UTF_8)`.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                             |
| ---------------- | ------------------------------------------------ |
| 15 min           | Three generations; NIO.2 Path/Files advantages   |
| 30 min           | Add NIO channel/buffer/selector model            |
| 45 min           | Add zero-copy transferTo(); memory-mapped files  |
| 1 hour           | Add WatchService; FileReader charset trap        |
| 2 hours          | Implement a simple echo server with NIO Selector |

---

**[JUNIOR] Q1: What is the difference between a byte stream and
a character stream in `java.io`?** [CONCEPTUAL]

_Why they ask:_ Baseline I/O knowledge check.

_Likely follow-up:_ "When would you use each?"

Byte streams (`InputStream`/`OutputStream`) work with raw bytes.
They are the foundation and are used for binary data: images,
audio files, zip archives, serialized objects, anything where
the bytes must not be interpreted as characters.

Character streams (`Reader`/`Writer`) add encoding/decoding:
they translate between Java's internal `char` (UTF-16) and a
byte encoding (UTF-8, UTF-16, ISO-8859-1). They are used for text:
reading configuration files, parsing CSV, writing JSON.

The bridge: `InputStreamReader` wraps an `InputStream` and
decodes bytes to characters. `OutputStreamWriter` wraps an
`OutputStream` and encodes characters to bytes.

```java
// Explicit encoding (always specify - never rely on default)
BufferedReader reader = new BufferedReader(
    new InputStreamReader(
        new FileInputStream("file.txt"),
        StandardCharsets.UTF_8));
```

Rule: for text, use character streams with explicit `UTF_8`. For
binary, use byte streams.

_What separates good from great:_ Knowing `InputStreamReader` as
the byte-to-char bridge, and always specifying charset explicitly.

---

**[MID] Q2: How does the NIO `Selector` enable one thread to handle
many connections?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of the reactor pattern.

_Likely follow-up:_ "What is the alternative (blocking I/O) cost?"

Classic blocking I/O: one thread per connection. When 1,000 clients
are connected, 1,000 threads exist. Each thread uses ~1MB stack by
default. 1,000 threads = 1GB RAM just for stacks, plus the OS
scheduling overhead.

NIO `Selector` (reactor pattern):

1. Set all `SocketChannel` objects to non-blocking mode
2. Register them with a `Selector` specifying which events to monitor
   (ACCEPT, READ, WRITE)
3. One thread calls `selector.select()` - blocks until at least
   one channel is ready
4. Iterate `selector.selectedKeys()` and handle each ready channel

When a channel becomes readable, `read()` returns data immediately
(non-blocking). If it would block (no data yet), `read()` returns 0
and the channel is skipped - we loop back to `select()`.

One thread handles thousands of connections because it never blocks
waiting for a single slow client. Context switching between threads
is replaced by a single `select()` system call.

_What separates good from great:_ Knowing `select()` is a single
OS syscall that the kernel handles, and connecting this to Netty's
boss/worker thread pool model (boss thread accepts connections,
worker threads handle I/O via Selectors).

---

**[MID] Q3: What is wrong with `new File("path").exists()`?
What should you use instead?** [DEBUGGING]

_Why they ask:_ A common production issue that trips up many developers.

_Likely follow-up:_ "How does NIO.2 solve it?"

Three problems with `File.exists()`:

1. **Ambiguous false**: returns `false` for "file doesn't exist"
   AND "insufficient permissions to check." You can't tell which.

2. **TOCTOU race condition**: between `file.exists()` and the
   subsequent operation (open, delete), the file state can change.
   Another process could create or delete the file in that window.

3. **Returns boolean, not exception**: there is no stack trace to
   follow when debugging.

NIO.2 solution:

For checking existence: `Files.exists(path)` - still boolean but
at least it is explicit. Better: just attempt the operation and
handle the specific exception.

```java
// GOOD: attempt and handle specific exception
try {
    Files.delete(path);
} catch (NoSuchFileException e) {
    // file didn't exist - handle if needed
} catch (IOException e) {
    // real error - log with full details
    logger.error("Failed to delete {}", path, e);
}

// Or one-liner if absence is acceptable:
Files.deleteIfExists(path);
```

_What separates good from great:_ Identifying the TOCTOU race
condition as the structural problem with check-then-act patterns,
not just the boolean API design.

---

**[SENIOR] Q4: What is zero-copy I/O and how does `FileChannel.transferTo()`
implement it?** [CONCEPTUAL]

_Why they ask:_ Tests OS-level I/O knowledge.

_Likely follow-up:_ "What is the performance gain in practice?"

In classic file-to-socket transfer, data moves through four steps:

1. OS reads file from disk into kernel buffer
2. OS copies kernel buffer to user-space Java buffer
3. Java writes buffer back to kernel socket buffer
4. OS sends socket buffer to network

Steps 2 and 3 are unnecessary copies through user space.

`FileChannel.transferTo(position, count, targetChannel)` calls the
OS `sendfile()` syscall (Linux) or `TransmitFile()` (Windows). The
OS copies directly from the file's page cache to the socket buffer
without involving user space - steps 2 and 3 are eliminated.

Benefits:

- CPU usage drops significantly (no user-space copy loops)
- Memory bandwidth is halved (one copy instead of two)
- JVM heap is not involved - no GC pressure from large byte arrays

This is used by: Kafka (log replication), Nginx (file serving),
Netty (HTTP file responses), HDFS (data node transfers).

Limitation: only works when data does not need transformation.
If you need to encrypt or compress in flight, the data must pass
through user space.

_What separates good from great:_ Naming `sendfile()` as the
syscall and identifying when it does NOT apply (when transformation
is needed).

---

**[SENIOR] Q5: DEBUGGING: A service running fine for days starts
getting `Too many open files` and crashes. Diagnose.** [DEBUGGING]

_Why they ask:_ Classic resource leak diagnosis.

_Likely follow-up:_ "What OS tool confirms this?"

`Too many open files` means the process has hit the OS file
descriptor limit (default 1024 on many Linux systems).

Diagnosis:

1. `lsof -p <pid> | wc -l` - count open file descriptors. If
   it's growing over time, there is a leak.
2. `lsof -p <pid> | sort -k9 | uniq -c -f8 | sort -rn | head`
   - group by file path to see which file type is leaking.
3. Heap dump + memory analyzer: look for `FileInputStream`,
   `FileChannel`, `InputStream` objects that are not in a
   closed state.

Common causes:

- `Files.lines(path)` result stream not closed: the underlying
  `FileChannel` leaks
- `Files.walk(path)` not closed in try-with-resources
- `InputStream` opened but exception prevents close call
  (missing try-with-resources)
- Network connections: `Socket`/`SocketChannel` not closed on
  exception paths

Fix: grep for `new FileInputStream(`, `Files.lines(`, `Files.walk(`
without try-with-resources. Require code review rule: every
`AutoCloseable` opened must be in a try-with-resources.

Set OS limit: `ulimit -n 65536` for the JVM process.

_What separates good from great:_ Knowing `Files.lines()` creates
a file handle that must be explicitly closed, and using `lsof`
for diagnosis rather than guessing.

---

**[STAFF] Q6: How do you design a file ingestion pipeline for
100GB daily log files with minimal memory?** [ARCHITECTURE]

_Why they ask:_ Tests I/O API selection at scale.

_Likely follow-up:_ "How would you parallelize it?"

Key requirement: process without loading into memory. Three approaches
depending on access pattern:

**Sequential processing** (most common for log ingestion):

```java
// O(1) memory: one line at a time, never loads the file
try (Stream<String> lines =
        Files.lines(path, StandardCharsets.UTF_8)) {
    lines
        .filter(line -> line.contains("ERROR"))
        .forEach(processor::handle);
}
```

`Files.lines()` is a lazy stream backed by a `BufferedReader` -
only one line is in memory at a time. A 100GB file processes in
constant memory.

**Parallel processing** (for CPU-bound parsing):

Split by file position: use `FileChannel.size() / N` to get N
equal chunks. Each chunk is processed by a separate thread using
`FileChannel.position(offset)`. Must handle record boundaries
(a chunk boundary may split a log line - read until next newline
to find the true record boundary).

**Random access** (rare, for indexed lookups):

`MappedByteBuffer map = channel.map(READ_ONLY, 0, channel.size())`.
The OS pages in 4KB segments on access. Random reads anywhere in
the file without loading the whole thing. Best for indexed log
retrieval by byte offset.

Memory monitoring: even `Files.lines()` builds an OS page cache.
For 100GB files on a shared host, monitor OS page cache pressure.

_What separates good from great:_ Knowing `Files.lines()` is a
lazy stream (constant memory) not a list, and the chunk-splitting
approach for parallel processing with boundary handling.

---

**[STAFF] Q7: How does `WatchService` work and what are its
limitations?** [ARCHITECTURE]

_Why they ask:_ Tests NIO.2 depth for production file monitoring.

_Likely follow-up:_ "What is the alternative for reliable file
change detection?"

`WatchService` uses OS-level file change notifications:

- Linux: `inotify`
- macOS: `kqueue` (or polling fallback)
- Windows: `ReadDirectoryChangesW`

Usage:

```java
WatchService watcher =
    FileSystems.getDefault().newWatchService();
Path dir = Path.of("/var/log/app");
dir.register(watcher,
    StandardWatchEventKinds.ENTRY_CREATE,
    StandardWatchEventKinds.ENTRY_MODIFY,
    StandardWatchEventKinds.ENTRY_DELETE);

while (true) {
    WatchKey key = watcher.take(); // blocks
    for (WatchEvent<?> event : key.pollEvents()) {
        Path changed = (Path) event.context();
        // handle event
    }
    key.reset(); // MUST reset to receive more events
}
```

Limitations:

1. **Event overflow**: if changes happen faster than consumed,
   `OVERFLOW` events are generated and individual events are lost.
   WatchService is not reliable for high-frequency change detection.
2. **Non-recursive**: `register()` only watches one directory.
   For recursive watching, you must register each subdirectory.
3. **macOS polling**: on macOS without native `kqueue` support,
   WatchService falls back to polling (slow, high CPU for many dirs).
4. **No initial scan**: `WatchService` only reports changes after
   registration; it misses files created before watching started.

Production alternative for critical file monitoring: Apache Commons
VFS, or a dedicated solution like `fswatch`. For event-driven file
ingestion at scale, use S3/GCS event notifications + SQS/Pub-Sub.

_What separates good from great:_ Knowing `key.reset()` is mandatory
(forgetting it means no more events), and that macOS uses polling.
