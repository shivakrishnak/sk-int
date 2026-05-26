---
layout: default
title: "Java Concurrency - L5 Architecture"
parent: "Java Concurrency"
nav_order: 8
permalink: /java-concurrency/l5-architecture/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Concurrency Architecture Patterns](#concurrency-architecture-patterns) | high |
| 2 | [Thread Safety Design Strategies](#thread-safety-design-strategies) | high |
| 3 | [Distributed Locking Strategies](#distributed-locking-strategies) | high |

---

# Concurrency Architecture Patterns

**Interview Weight:** high - Architect-level topic. Tests ability
to select the right concurrency pattern for a given system requirement
and explain the trade-offs between actor, event-loop, CSP, and
shared-state models.

---

### 🎯 Model Answer

**30 seconds:**

> Four dominant concurrency architecture patterns: (1) Shared-state
> with locks - multiple threads share mutable data, protected by
> synchronization. Simple but error-prone. (2) Actor model - each
> actor has private state; communication via async message passing.
> No shared mutable state - no races. (3) Event-loop - single
> thread processes events from a queue; callbacks/futures for
> async results. Node.js, Vert.x. (4) CSP/channels - goroutine-
> style; communication via blocking channels. Java via
> `SynchronousQueue` or reactive pipelines.

**3 minutes (Senior):**

> **Shared-state with locks** is the Java default. Works well
> for bounded concurrency with clear ownership. Fails at high
> concurrency (contention), complex object graphs (lock ordering),
> and distributed systems (no global lock).
>
> **Actor model** (Akka) - each actor processes messages serially
> in its own thread/fiber. No concurrent access to actor state.
> Scales naturally: add actors = add parallelism. Fault isolation:
> actor failure can be supervised independently. Downside: actors
> must never block the message dispatcher; all I/O must be async.
> Dead-letter queues handle undeliverable messages.
>
> **Event-loop** - one thread runs the event loop; async I/O
> callbacks are scheduled onto it. Netty, Vert.x use this model.
> Maximum throughput with minimal threads. Hard constraint: NO
> blocking on the event loop. Long computation must be offloaded
> to a worker pool.
>
> **Thread-per-request** (classic Java EE) + **Virtual Threads**
> (Java 21): one virtual thread per request. Write blocking code.
> JVM schedules virtual threads onto a small OS thread pool.
> Combines the simplicity of shared-state with the scalability of
> event-loop. Best fit for request-response services in Java 21+.
>
> **Decision rule**: request/response API = virtual threads (Java 21+).
> Event-driven/streaming = event-loop (Vert.x) or reactive.
> Actor-based domain logic = Akka. Legacy/small-scale = synchronized.

---

### 💻 Code Example

**Example 1: Actor pattern vs event-loop vs virtual threads**

```java
// PATTERN 1: Actor model (conceptual with Java primitives)
// Each "actor" is a thread with its own queue
class OrderActor {
    private final BlockingQueue<Order> inbox = new LinkedBlockingQueue<>();
    private final Map<String, Order> localState = new HashMap<>(); // private - no lock needed

    public void start() {
        Thread.ofVirtual().start(() -> {
            while (true) {
                Order msg = inbox.take();   // blocks actor, not carrier thread
                process(msg);               // serial access: no synchronization
            }
        });
    }
    public void send(Order o) { inbox.put(o); }  // async message send
}

// PATTERN 2: Event loop (Netty-style)
// - One thread, all callbacks on the event loop thread
// - BAD: blocking on event loop
EventLoop loop = channel.eventLoop();
loop.execute(() -> {
    byte[] data = Files.readAllBytes(path);  // BAD: blocks event loop!
    // ALL other I/O on this loop stalls until readAllBytes returns
});

// GOOD: offload blocking work to worker pool
loop.execute(() -> {
    workerPool.submit(() -> Files.readAllBytes(path))
        .thenAccept(data -> loop.execute(() -> sendResponse(data)));
});

// PATTERN 3: Virtual threads (Java 21) - simplest
// Thread-per-request: write blocking code, JVM handles scheduling
ExecutorService vtp = Executors.newVirtualThreadPerTaskExecutor();
vtp.submit(() -> {
    Order order = orderRepo.findById(id);    // blocks virtual thread (not OS thread)
    User user   = userRepo.findById(order.userId);
    notify(user, order);
    return "done";
});
```

> **Code walkthrough:** The actor model with virtual threads: the
> actor's `inbox.take()` parks the virtual thread (not the OS thread),
> allowing the carrier thread to serve other actors. No locks needed
> because only this actor's thread accesses `localState`. The event-
> loop pattern requires zero blocking on the loop thread - blocking
> calls must be dispatched to workers and results returned via
> callbacks or futures scheduled back on the loop.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Key patterns: shared-state with locks (standard Java), actor model
> (private state, message passing), event-loop (one thread, callbacks),
> virtual threads (blocking code, JVM-managed). Use virtual threads
> for new Java 21+ services; reactive for streaming.

---

**Senior / Staff (5+ years):**

> Pattern selection depends on three axes: state ownership (shared vs
> actor-private), I/O model (blocking vs non-blocking), and throughput
> requirement. For most Java 21+ REST APIs I default to virtual
> threads. For event-driven backplane or streaming I use reactive.
> For complex domain logic with isolated failure boundaries I consider
> actors (Akka). I avoid shared-state locks beyond simple bounded
> scenarios.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "When would you choose the actor model over virtual threads?"

🗣️ "The actor model excels in two scenarios: (1) fault isolation -
if an actor fails (throws), only that actor's supervisor handles
it; other actors continue running. Virtual threads have no built-in
supervision. (2) state machines with many concurrent entities where
each entity has complex private state (e.g., online game players,
IoT device sessions). The actor inbox serializes messages to each
actor, eliminating concurrency bugs without locks. Virtual threads
are simpler for request-response I/O but do not provide message
ordering or actor supervision by default."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Four patterns, when each applies, tradeoffs. |
| Hiring Manager   | Architectural decision for high-throughput services. |
| Bar Raiser       | Akka actors, structured concurrency, virtual thread supervision. |
| Peer Engineer    | "We moved from Akka to virtual threads and the code complexity dropped significantly..." |

---

---

# Thread Safety Design Strategies

**Interview Weight:** high - Staff/Principal level. Tests ability
to design thread-safe APIs and choose between immutability,
confinement, synchronization policy, and lock-free approaches.

---

### 🎯 Model Answer

**30 seconds:**

> Four strategies for thread safety: (1) Immutability - objects
> that cannot be changed are always thread-safe. (2) Thread
> confinement - an object is only accessed by one thread, so no
> synchronization needed. (3) Synchronization - lock-based access
> with monitors or `java.util.concurrent` locks. (4) Lock-free -
> atomic operations (CAS) via `java.util.concurrent.atomic`.
> The priority order: prefer immutability, then confinement, then
> `java.util.concurrent` classes, then manual synchronization.

**3 minutes (Senior):**

> **Immutability**: `final` fields set in constructor, no setters,
> no mutable state. Inherently thread-safe. No synchronization
> overhead. Copy-on-write patterns for "modifications": create a
> new object with the changed value, return it. `String`, `Integer`,
> and all boxed types are immutable.
>
> **Thread confinement**: stack confinement (local variables never
> escape the creating thread), thread-local storage (`ThreadLocal`),
> and design-enforced confinement (only a designated thread
> accesses the object). Event dispatch thread (EDT) in Swing is
> an example: all UI operations are confined to the EDT.
>
> **Synchronization policy documentation**: the most underrated
> practice. Every mutable object should document: which fields are
> guarded by which lock; which operations must be called on which
> thread; which invariants must hold across which operations.
> Without this documentation, a future maintainer has no way to
> know if adding a new field or method maintains thread safety.
>
> **Atomic vs lock granularity**: fine-grained locking reduces
> contention but increases complexity. Coarse-grained locking
> (one lock for the whole object) is easier but limits parallelism.
> A `ConcurrentHashMap` with 16 default segments balances both.

---

### 💻 Code Example

**Example 1: Four strategies applied**

```java
// STRATEGY 1: Immutability (preferred)
public final class Money {
    private final BigDecimal amount;     // final: set once in constructor
    private final Currency currency;

    public Money(BigDecimal amount, Currency currency) {
        this.amount   = Objects.requireNonNull(amount);
        this.currency = Objects.requireNonNull(currency);
    }
    // No setters: modification returns new object
    public Money add(Money other) {
        if (!currency.equals(other.currency))
            throw new IllegalArgumentException("Currency mismatch");
        return new Money(amount.add(other.amount), currency);
    }
    // Thread-safe: read-only after construction; final guarantees visibility
}

// STRATEGY 2: Thread confinement via ThreadLocal
// Reuse SimpleDateFormat (NOT thread-safe) per-thread
private static final ThreadLocal<SimpleDateFormat> DATE_FORMAT =
    ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd"));
// Each thread has its own instance: zero synchronization needed

// STRATEGY 3: Synchronization policy (documented)
public class UserCache {
    // Invariant: cache.size() <= maxSize at all times
    // Lock order: acquire this.lock before any cache operation
    @GuardedBy("this")
    private final Map<String, User> cache = new HashMap<>();
    @GuardedBy("this")
    private int maxSize = 1000;

    public synchronized void put(String key, User user) {
        if (cache.size() >= maxSize) evictOldest();
        cache.put(key, user);
    }
}

// STRATEGY 4: Lock-free with CAS
public class IdGenerator {
    // BAD: synchronized for simple increment - unnecessary overhead
    private long nextId = 0;
    public synchronized long next() { return ++nextId; }

    // GOOD: AtomicLong - CAS-based, no lock, lower latency
    private final AtomicLong counter = new AtomicLong(0);
    public long next() { return counter.incrementAndGet(); }
}
```

> **Code walkthrough:** `Money` is immutable: `final` fields prevent
> modification; every "mutation" returns a new `Money` object.
> No thread can observe a partially-constructed or modified state.
> `ThreadLocal<SimpleDateFormat>` gives each thread its own
> `SimpleDateFormat` instance - expensive to create, safe to reuse
> per-thread. `@GuardedBy("this")` is documentation-only but
> tools like FindBugs/SpotBugs enforce it. `AtomicLong.incrementAndGet()`
> uses CAS: cheaper than a synchronized block for single-variable
> operations.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Thread safety strategies: immutability (no state = no problem),
> confinement (one thread owns the object), synchronization (locks),
> and atomic operations. Prefer immutability and confinement;
> use locks only when necessary.

---

**Senior / Staff (5+ years):**

> I document the synchronization policy for every shared mutable
> object: which fields, which lock, which invariants. This is the
> most impactful practice I've seen for reducing concurrency bugs
> in large codebases. When reviewing, I look for undocumented fields
> that are accessed from multiple threads - those are the latent bugs.

---

### ❓ Questions You Will Be Asked

#### Decision

- "How do you decide which thread safety strategy to use?"

🗣️ "I evaluate in order. First: can the object be immutable?
If there is no requirement to modify state after construction,
make it immutable. Zero synchronization overhead, no bugs. Second:
can the object be confined to one thread? Use stack confinement
for local operations, `ThreadLocal` for per-thread caches.
Third: does a `java.util.concurrent` class already solve this?
`ConcurrentHashMap`, `CopyOnWriteArrayList`, `AtomicLong` cover
most common patterns. Fourth: does the object need complex invariants
across multiple fields? Use a single coarse-grained lock to start,
then profile to determine if fine-grained locking is needed.
Manual synchronized blocks are the last resort."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Four strategies, @GuardedBy, synchronization policy. |
| Hiring Manager   | Design review - recognizing thread safety anti-patterns. |
| Bar Raiser       | Happens-before and final fields, ScopedValues (Java 21). |
| Peer Engineer    | "Our 'immutable' class was not actually immutable - mutable list field..." |

---

---

# Distributed Locking Strategies

**Interview Weight:** high - System design topic at L5. Tests
knowledge of when local JVM locks are insufficient, the patterns
for distributed locks, and the failure modes.

---

### 🎯 Model Answer

**30 seconds:**

> Distributed locks coordinate access to a shared resource across
> multiple JVM instances. Three main approaches: (1) Redis-based
> locks with `SET key NX PX timeout` (or Redlock for multi-node);
> (2) database-based locks with `SELECT FOR UPDATE`; (3) ZooKeeper
> or etcd ephemeral nodes. Key properties needed: mutual exclusion,
> liveness (no lock held forever - TTL), safety (lock not released
> by non-owner). Failure mode: network partition causes the lock
> holder to appear dead while still holding the lock.

**3 minutes (Senior):**

> **Redis SETNX lock**: `SET lockKey ownerId NX PX 30000` acquires
> a lock with a 30-second TTL. The `ownerId` (unique per process)
> prevents a different process from releasing it. On release:
> Lua script atomically checks the value and deletes only if it
> matches the ownerId. TTL prevents permanent lock if the holder
> crashes.
>
> **The Redlock problem (Martin Fowler/Kleppmann critique)**: even
> with TTL, a GC pause or process freeze can cause the holder to
> wake up after the TTL has expired, while another process has
> acquired the lock. Both processes now think they hold the lock.
> Solutions: fencing tokens (an incrementing token from the lock
> service; the resource checks the token and rejects older tokens).
>
> **ZooKeeper / etcd**: ephemeral nodes are deleted automatically
> when the session disconnects. SEQUENTIAL ephemeral nodes implement
> a fair queue: the node with the lowest sequence number holds the
> lock; others watch the preceding node and acquire when it disappears.
> More complex than Redis but provides stronger consistency
> (ZooKeeper uses ZAB consensus).
>
> **Database advisory locks** (`pg_advisory_lock`): locks acquired
> within the database session. Released on session close. Simple
> for single-database deployments. Does not scale across multiple
> databases.

---

### 💻 Code Example

**Example 1: Redis distributed lock with Lua release**

```java
// Jedis-based distributed lock (conceptual)
public class RedisDistributedLock {
    private final JedisPool pool;
    private final String lockKey;
    private final String ownerId;     // unique per JVM instance + thread

    public boolean tryAcquire(int ttlSeconds) {
        try (Jedis jedis = pool.getResource()) {
            // SET lockKey ownerId NX PX ttlMs - atomic: NX=only if not exists
            String result = jedis.set(
                lockKey, ownerId,
                SetParams.setParams().nx().px(ttlSeconds * 1000L)
            );
            return "OK".equals(result);
        }
    }

    public boolean release() {
        // ATOMIC: check ownerId AND delete in same Lua script
        // Without Lua: check-then-delete is a race condition
        String script =
            "if redis.call('get', KEYS[1]) == ARGV[1] then " +
            "  return redis.call('del', KEYS[1]) " +
            "else " +
            "  return 0 " +
            "end";
        try (Jedis jedis = pool.getResource()) {
            Object result = jedis.eval(script,
                List.of(lockKey), List.of(ownerId));
            return Long.valueOf(1L).equals(result);
        }
    }
}

// Usage pattern with lock timeout
RedisDistributedLock lock = new RedisDistributedLock(pool, "resource:123", uuid);
if (lock.tryAcquire(30)) {
    try {
        processResource();  // critical section - at most 30s
    } finally {
        lock.release();     // always release; TTL is safety net
    }
} else {
    throw new ResourceLockedException("Resource already locked");
}
```

> **Code walkthrough:** The Lua script is critical for correctness.
> Without it: read the key (it matches ownerId), then DELETE. Between
> the read and delete, the TTL expires and another process acquires
> the lock. The DELETE removes the other process's lock - not yours.
> The Lua script runs atomically in Redis: the check-and-delete is
> an indivisible operation. The TTL is the safety net: if the JVM
> crashes after acquiring, the lock auto-expires after 30 seconds.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JVM locks only work within one process. Distributed locks use
> Redis or a database to coordinate across multiple servers. Always
> set a TTL so a crashed process releases the lock automatically.

---

**Senior / Staff (5+ years):**

> The fencing token problem is the hard part. If a GC pause causes
> the lock holder to wake after TTL expiry, two processes hold the
> lock simultaneously. For correctness-critical sections, I use
> fencing tokens: the lock service returns an incrementing token;
> the protected resource rejects operations with a token lower than
> the last seen. This makes the resource itself the last line of
> defense against concurrent access.

---

### ❓ Questions You Will Be Asked

#### System Design

- "Design a distributed rate limiter using Redis. How do you ensure
  correctness under concurrent requests?"

🗣️ "Use a sliding window counter in Redis. The key is
`rate:userId:windowStart`. On each request: (1) Lua script:
increment the counter for the current window, set TTL on the key
to window size + buffer, check if counter exceeds limit, return
allowed/denied atomically. The Lua script ensures the increment-
and-check is atomic: no race between two concurrent requests
seeing each other's count. For sub-millisecond accuracy, use
a sorted set with request timestamps as members and scores:
count members in the range `(now - windowMs, now]`. A Lua script
trims old members and counts current-window members atomically.
This handles burst patterns correctly without fixed-window artifacts."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Redis SETNX, Lua atomicity, TTL for crash safety. |
| Hiring Manager   | Failure modes: split-brain, GC pause, network partition. |
| Bar Raiser       | Fencing tokens, Redlock critique, ZooKeeper consensus (ZAB). |
| Peer Engineer    | "We had a bug where GC pause caused two services to process the same order..." |
