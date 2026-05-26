---
layout: default
title: "Java Concurrency - L2 Concurrent Collections"
parent: "Java Concurrency"
nav_order: 4
permalink: /java-concurrency/l2-concurrent-collections/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [ConcurrentHashMap](#concurrenthashmap) | high |
| 2 | [CopyOnWriteArrayList](#copyonwritearraylist) | high |
| 3 | [BlockingQueue Implementations](#blockingqueue-implementations) | high |
| 4 | [ConcurrentLinkedQueue](#concurrentlinkedqueue) | high |
| 5 | [Concurrent Collections Design](#concurrent-collections-design) | high |

---

# ConcurrentHashMap

**Interview Weight:** high - The most important concurrent data
structure. Interviewers test segment locking, atomic compound
operations, and the Java 8 structural changes.

---

### 🎯 Model Answer

**30 seconds:**

> `ConcurrentHashMap` is a thread-safe map with significantly better
> throughput than `Collections.synchronizedMap()` because it uses
> bucket-level locking instead of full-map locking. In Java 8 it
> moved from 16 segments to per-bucket CAS/synchronized for writes.
> Critical: `get/put` are thread-safe, but compound operations like
> "check-then-put" are NOT atomic unless you use the provided atomic
> methods: `putIfAbsent()`, `computeIfAbsent()`, `merge()`,
> `compute()`.

**3 minutes (Senior):**

> In Java 7, `ConcurrentHashMap` used 16 segments (fixed), each a
> mini-`ReentrantLock`-guarded `HashMap`. The default concurrency
> level of 16 allowed 16 concurrent writes to different segments.
> In Java 8, this was replaced with per-bucket CAS for single-entry
> buckets and synchronized(bucket) for multi-entry buckets. Empty
> bucket insert uses CAS (no lock at all); non-empty bucket uses
> `synchronized(bucket)`, which is a very short lock. This allows
> effective parallelism equal to the number of buckets (millions),
> not just 16.
>
> The compound operation pitfall is critical in production. These
> patterns are NOT atomic:
> ```java
> if (!map.containsKey(k)) map.put(k, v);  // race window between check and put
> map.put(k, map.get(k) + 1);              // not atomic: read/increment/write
> ```
> Use `putIfAbsent()`, `computeIfAbsent()`, `merge()`, or `compute()`
> which are internally atomic.
>
> `ConcurrentHashMap` does not allow `null` keys or values
> (unlike `HashMap`). This is intentional: `get(key)` returning
> `null` is ambiguous in a concurrent context - does the key not
> exist, or does it map to `null`? In `HashMap` you disambiguate
> with `containsKey()`, but that is a two-operation check that is
> not thread-safe on a concurrent map.

---

### 💻 Code Example

**Example 1: Atomic compound operations**

```java
ConcurrentHashMap<String, Integer> wordCount = new ConcurrentHashMap<>();

// BAD: Race condition - check-then-put is two operations
if (!wordCount.containsKey(word)) {        // Thread A checks: absent
    wordCount.put(word, 1);                // Thread B also put(word, 1)
}                                          // Two threads: one write lost

// BAD: Read-modify-write race
int current = wordCount.getOrDefault(word, 0);
wordCount.put(word, current + 1);  // not atomic: lost update possible

// GOOD: Atomic compound operations (Java 8+)
// putIfAbsent: put only if key absent (returns existing or null)
wordCount.putIfAbsent(word, 0);

// merge: atomically combine with existing value
wordCount.merge(word, 1, Integer::sum);
// If absent: put(word, 1)
// If present: put(word, existing + 1)

// computeIfAbsent: compute value only if absent (lazy init)
Map<String, List<String>> groups = new ConcurrentHashMap<>();
groups.computeIfAbsent(key, k -> new ArrayList<>()).add(value);
// Atomic: creates list only if key absent, then returns it

// compute: always compute new value
wordCount.compute(word, (k, v) -> v == null ? 1 : v + 1);

// forEach with concurrency level (Java 8+)
wordCount.forEach(
    4,                                // parallelism threshold
    (k, v) -> System.out.println(k + "=" + v)
);
```

> **Code walkthrough:** `merge()` is the most concise word-count
> increment: if the key is absent, set to 1; if present, apply
> `Integer::sum` atomically. `computeIfAbsent()` for grouping creates
> the list only once - subsequent calls for the same key return the
> existing list. All these methods use `synchronized(bucket)` internally
> for the check+modify+put, making them atomic.

**Example 2: Size tracking and iteration**

```java
ConcurrentHashMap<String, User> users = new ConcurrentHashMap<>();

// size() is approximate during concurrent modification
// Use mappingCount() for large maps (returns long, not int)
long approxSize = users.mappingCount();

// Iteration is weakly consistent: reflects state at or after
// the iterator was created; does not throw ConcurrentModificationException
for (Map.Entry<String, User> entry : users.entrySet()) {
    // safe to call users.put() concurrently during this iteration
    process(entry.getValue());
}

// Search with early termination (parallel for large maps)
String found = users.search(
    4,                          // parallelism threshold
    (key, user) -> user.isAdmin() ? key : null
);  // returns first non-null result or null
```

> **Code walkthrough:** `size()` on `ConcurrentHashMap` is not
> guaranteed to be accurate during concurrent modifications - it is
> a snapshot that may be stale immediately. `mappingCount()` is
> more accurate for large maps (uses the Java 8 internal counter
> cells). Iteration is weakly consistent: you will see elements
> that existed at iteration start but may miss elements added after
> the iterator was created.

---

### ⚖️ Comparison

| | ConcurrentHashMap | Collections.synchronizedMap | Hashtable |
|--|-------------------|----------------------------|-----------|
| Lock granularity | per-bucket | full map | full map |
| Concurrent reads | yes, no lock | serialized | serialized |
| Null keys/values | no | depends on backing map | no |
| Iteration | weakly consistent | must externally lock | same |
| Java version | Java 5+ | Java 2+ | Java 1 (legacy) |

**The deciding factor:** Use `ConcurrentHashMap` for all concurrent
map needs. Use `synchronizedMap` only when wrapping legacy code.
Never use `Hashtable` in new code.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ConcurrentHashMap` is thread-safe and much faster than
> `synchronizedMap` because it uses per-bucket locking instead of
> locking the whole map. Use `merge()`, `computeIfAbsent()`, and
> `putIfAbsent()` for atomic compound operations.

*Push deeper:* Why can't you use `containsKey()` + `put()` safely?

---

**Senior / Staff (5+ years):**

> The difference between Java 7 and Java 8 internals matters for
> lock analysis. In Java 8, inserts to empty buckets use CAS (zero-
> lock). The segment model limitation (16 max concurrency) is gone.
> For metrics collection with high-contention counters, I use
> `LongAdder` per map entry rather than atomic map values. I also
> size `ConcurrentHashMap` explicitly at construction to avoid
> resizing under load.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "How does ConcurrentHashMap achieve better throughput than
  Collections.synchronizedMap()?"

🗣️ "`Collections.synchronizedMap()` wraps every operation with a
synchronized block on the entire map - all reads and writes
serialize on a single lock. `ConcurrentHashMap` uses bucket-level
locking: in Java 8, reads use no lock (volatile reads), inserts
to empty buckets use CAS (no lock), and inserts to non-empty
buckets use `synchronized(bucket)` - a very short lock on just
one bucket. Concurrent reads to different buckets never block each
other, and concurrent writes to different buckets don't block each
other either. The effective parallelism scales with the number of
buckets."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Java 8 bucket CAS vs Java 7 segments, compound ops. |
| Hiring Manager   | Why null values are not allowed - design reasoning. |
| Bar Raiser       | mappingCount(), forEach parallelism, weakly consistent iteration. |
| Peer Engineer    | "We had a lost update bug using containsKey+put on ConcurrentHashMap..." |

---

---

# CopyOnWriteArrayList

**Interview Weight:** high - Tests understanding of the copy-on-
write trade-off: safe concurrent iteration vs expensive mutation.
Interviewers want to know when this is appropriate.

---

### 🎯 Model Answer

**30 seconds:**

> `CopyOnWriteArrayList` (COWAL) is a thread-safe list where every
> mutation (add, set, remove) creates a new copy of the underlying
> array. Reads use the current snapshot with zero locking. The
> trade-off: concurrent iteration is safe and lock-free (iterates
> the snapshot at iteration start), but mutation is O(n) in time
> and memory because of the copy. Use it for read-heavy lists that
> are very rarely mutated.

**3 minutes (Senior):**

> COWAL iterators never throw `ConcurrentModificationException`
> because they iterate a frozen snapshot of the array from when
> the iterator was created. Elements added after the iterator was
> created are not visible to it. This makes COWAL iterators safe
> for concurrent access but potentially stale.
>
> The write cost is real: a list with 10,000 elements copies all
> 10,000 on each mutation. If mutations are frequent, this is
> both CPU-intensive (copying) and GC-intensive (discarding old
> arrays). A `ConcurrentHashMap` or a `ReadWriteLock`-guarded
> list is more appropriate for lists with frequent mutations.
>
> The ideal use case: a list of event listeners or subscribers that
> is set up once (or very rarely modified) and iterated by many
> threads to dispatch events. Adding a listener creates one copy;
> all concurrent event dispatches read the snapshot lock-free.
> Another ideal case: configuration lists that reload rarely but
> are read thousands of times per second.

---

### 💻 Code Example

**Example 1: Event listener dispatch - ideal COWAL use case**

```java
public class EventBus {
    // Listeners added/removed rarely; dispatched frequently
    private final CopyOnWriteArrayList<EventListener> listeners
        = new CopyOnWriteArrayList<>();

    public void addListener(EventListener listener) {
        listeners.add(listener);    // O(n): creates copy of array
    }

    public void removeListener(EventListener listener) {
        listeners.remove(listener); // O(n): creates copy of array
    }

    public void dispatch(Event event) {
        // Iteration: zero locking, safe even if add/remove concurrent
        for (EventListener listener : listeners) {  // iterates snapshot
            listener.onEvent(event);
        }
        // New listeners added during dispatch are NOT seen by this iteration
        // This is intentional: prevents ConcurrentModificationException
    }
}

// BAD: Using COWAL for a frequently mutated list
// This would create a new array copy on every cache miss, search result add, etc.
CopyOnWriteArrayList<SearchResult> results = new CopyOnWriteArrayList<>();
for (Document doc : documents) {
    if (matches(doc, query)) {
        results.add(doc.toResult());  // O(n) copy every add!
    }
}
// Better: use ArrayList in a single thread, or Collections.synchronizedList()
// if truly needed concurrently with locks
```

> **Code walkthrough:** The event bus pattern is the canonical COWAL
> use case. Listener registration is rare (add/remove are O(n)).
> Dispatch is frequent (every event = one iteration of the snapshot).
> The snapshot semantics are correct for event dispatch: if a
> listener is removed during dispatch, it still receives the current
> event (it was in the snapshot). The bad example shows the anti-
> pattern: adding to COWAL in a loop creates O(n) copies on every
> iteration.

---

### ⚖️ Comparison

| | CopyOnWriteArrayList | Collections.synchronizedList | ArrayList + ReadWriteLock |
|--|----------------------|------------------------------|---------------------------|
| Read cost | O(1), no lock | O(1), acquires lock | O(1), read lock |
| Write cost | O(n), array copy | O(n), holds lock | O(n), write lock |
| Iteration | snapshot, no lock | needs external sync | needs read lock |
| ConcurrentModException | never | possible without external sync | never (with lock) |
| Use case | rare write, many reads | balanced read/write | balanced read/write |

**The deciding factor:** Use COWAL when writes are very rare
(setup once, read forever). Use `ReadWriteLock`-guarded ArrayList
for balanced read/write with safe iteration.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `CopyOnWriteArrayList` is thread-safe for reads with no locking.
> Writes create a new copy. Safe for iteration - never throws
> `ConcurrentModificationException`. Use for read-heavy lists that
> are rarely modified.

---

**Senior / Staff (5+ years):**

> I use COWAL specifically for event listener registries and
> configuration lists - write-once-read-many patterns. The memory
> overhead (keeping old array alive until GC) is acceptable when
> writes are rare. For any list that gets mutations at non-trivial
> frequency, I use `ReadWriteLock`-guarded ArrayList or a different
> data structure.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "What is the trade-off of CopyOnWriteArrayList?"

🗣️ "Every mutation (add, set, remove) copies the entire underlying
array. For a list with N elements, that is O(n) time and O(n)
memory per mutation. Iteration is zero-cost and lock-free because
it reads a snapshot. So `CopyOnWriteArrayList` is optimal when:
reads are very frequent, mutations are very rare (or happen only
at startup), and iteration does not need to see concurrent mutations.
For lists with frequent writes, the copy overhead makes it worse
than `Collections.synchronizedList()` or a `ReadWriteLock`-guarded list."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Copy semantics, iterator snapshot, O(n) write cost. |
| Hiring Manager   | When appropriate: listener registries, config lists. |
| Bar Raiser       | Memory impact (double array during copy), CopyOnWriteArraySet. |
| Peer Engineer    | "We used COWAL for search results (mutated millions of times) - GC exploded..." |

---

---

# BlockingQueue Implementations

**Interview Weight:** high - The standard solution for producer-
consumer. Tests knowledge of bounded vs unbounded queues and the
blocking semantics.

---

### 🎯 Model Answer

**30 seconds:**

> `BlockingQueue` is the standard Java producer-consumer interface.
> `put()` blocks when the queue is full; `take()` blocks when the
> queue is empty. Key implementations: `ArrayBlockingQueue` (bounded,
> array, fair optionally), `LinkedBlockingQueue` (optionally bounded,
> better throughput via separate head/tail locks), `PriorityBlockingQueue`
> (unbounded, priority-ordered), `SynchronousQueue` (zero capacity,
> handoff only), `DelayQueue` (elements available only after delay).

**3 minutes (Senior):**

> `ArrayBlockingQueue` vs `LinkedBlockingQueue`: the critical
> production difference is back-pressure. `ArrayBlockingQueue`
> with a fixed capacity applies back-pressure: producers block
> when full, preventing memory exhaustion. `LinkedBlockingQueue`
> with default capacity is effectively unbounded (`Integer.MAX_VALUE`)
> - producers never block, and the queue grows until OOM under
> sustained overload. Always specify a capacity for `LinkedBlockingQueue`
> in production: `new LinkedBlockingQueue<>(1000)`.
>
> `LinkedBlockingQueue` has higher throughput than `ArrayBlockingQueue`
> because it uses two separate locks (head lock for take, tail lock
> for put), allowing concurrent put and take. `ArrayBlockingQueue`
> uses a single lock for both.
>
> `SynchronousQueue` has no capacity at all - it is a direct handoff
> channel. A put blocks until a take arrives and vice versa.
> This is the queue used by `Executors.newCachedThreadPool()` -
> submitted tasks are handed off directly to a (potentially newly
> created) thread with zero queue buffering.
>
> For the four operations on `BlockingQueue`:
> - `offer(e)`: non-blocking, returns false if full
> - `put(e)`: blocks until space available (or interrupted)
> - `poll()`: non-blocking, returns null if empty
> - `take()`: blocks until element available (or interrupted)

---

### 💻 Code Example

**Example 1: Producer-consumer with bounded queue**

```java
// Bounded queue: producer blocks when full (back-pressure)
BlockingQueue<LogEvent> logQueue = new LinkedBlockingQueue<>(1000);

// Producer thread: application code logging events
class LogProducer implements Runnable {
    public void run() {
        while (!Thread.currentThread().isInterrupted()) {
            LogEvent event = collectEvent();
            try {
                logQueue.put(event);       // blocks if queue full
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }
}

// Consumer thread: writes events to disk/remote
class LogConsumer implements Runnable {
    public void run() {
        while (!Thread.currentThread().isInterrupted()) {
            try {
                LogEvent event = logQueue.take();  // blocks if empty
                writeToSink(event);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                // drain remaining events before shutdown
                List<LogEvent> remaining = new ArrayList<>();
                logQueue.drainTo(remaining);
                remaining.forEach(this::writeToSink);
                break;
            }
        }
    }
}

// Non-blocking offer/poll for timeout-based producers
boolean accepted = logQueue.offer(event, 100, TimeUnit.MILLISECONDS);
if (!accepted) {
    droppedCount.increment();  // back-pressure: drop or circuit-break
}
```

> **Code walkthrough:** `put()` blocks when the queue reaches 1,000
> events - this is back-pressure in action. The producer slows
> down when the consumer cannot keep up, preventing OOM. The consumer
> uses `take()` to block efficiently without polling. On interrupt,
> the consumer drains remaining events before exiting - ensuring
> all buffered events are written. `offer(event, 100ms)` implements
> a deadline: if the queue is full after 100ms, the event is dropped
> with a counter increment.

**Example 2: SynchronousQueue and DelayQueue**

```java
// SynchronousQueue: thread pool handoff (newCachedThreadPool uses this)
SynchronousQueue<Runnable> handoff = new SynchronousQueue<>();
// Thread A: put(task)  - blocks until Thread B takes it
// Thread B: take()     - blocks until Thread A puts a task
// Zero buffering: direct producer-to-consumer handoff

// DelayQueue: tasks executable after a delay
class RetryTask implements Delayed {
    private final long executeAt;  // System.nanoTime() + delay
    public long getDelay(TimeUnit unit) {
        return unit.convert(executeAt - System.nanoTime(),
                            TimeUnit.NANOSECONDS);
    }
    public int compareTo(Delayed other) { /* compare executeAt */ }
}
DelayQueue<RetryTask> retryQueue = new DelayQueue<>();
retryQueue.put(new RetryTask(System.nanoTime() + RETRY_DELAY_NANOS));
// take() blocks until the first element's delay has expired
RetryTask task = retryQueue.take();  // returns when task is due
```

> **Code walkthrough:** `SynchronousQueue` is a zero-capacity
> rendezvous point - `put()` blocks until `take()` arrives. This
> creates maximum back-pressure: the producer cannot continue until
> the consumer is ready. `DelayQueue` is the standard mechanism for
> scheduled retry, timeout-based eviction from caches, or rate-
> limited task scheduling.

---

### ⚖️ Comparison

| Queue | Capacity | Lock | Use Case |
|-------|----------|------|----------|
| ArrayBlockingQueue | fixed | single | Bounded FIFO, fair option |
| LinkedBlockingQueue | optional | two (head/tail) | Bounded FIFO, higher throughput |
| SynchronousQueue | 0 | transfer | Direct handoff, CachedThreadPool |
| PriorityBlockingQueue | unbounded | single | Priority task scheduling |
| DelayQueue | unbounded | single | Scheduled/retry tasks |

**The deciding factor:** Always bound `LinkedBlockingQueue` in
production. Choose `LinkedBlockingQueue` for throughput.
`ArrayBlockingQueue` for fair guaranteed ordering.
`SynchronousQueue` for no buffering.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `BlockingQueue` is the producer-consumer interface. `put()` blocks
> when full; `take()` blocks when empty. Main implementations:
> `LinkedBlockingQueue` (optionally bounded), `ArrayBlockingQueue`
> (bounded), `SynchronousQueue` (zero capacity handoff).

---

**Senior / Staff (5+ years):**

> In production, I always set a capacity on `LinkedBlockingQueue`.
> An unbounded queue can cause OOM under sustained load - the producer
> outpaces the consumer but never blocks. The queue grows until
> heap exhaustion. Bounded queues with `offer(timeout)` give you
> a circuit-breaker point to shed load. I also instrument `queue.size()`
> as a metric - a queue growing toward capacity is an early warning
> of consumer lag.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between put() and offer() on a BlockingQueue?"

🗣️ "`put(e)` is a blocking call: it waits indefinitely until space
is available in the queue. `offer(e)` is non-blocking: it returns
false immediately if the queue is full. There is also `offer(e, timeout, unit)`:
it waits up to the timeout and returns false if still full. Use
`put()` for producers that should block under load (back-pressure).
Use `offer(timeout)` for producers that need to enforce a deadline
and drop or circuit-break when the queue is overwhelmed."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | put vs offer vs add, ArrayBlocking vs LinkedBlocking, two-lock design. |
| Hiring Manager   | Back-pressure and OOM prevention - production safety. |
| Bar Raiser       | TransferQueue, drainTo(), SynchronousQueue in CachedThreadPool. |
| Peer Engineer    | "Unbounded LinkedBlockingQueue caused our service's OOM at 3 AM..." |

---

---

# ConcurrentLinkedQueue

**Interview Weight:** high - Tests knowledge of non-blocking,
lock-free queue for high-throughput scenarios. Interviewers probe
the difference from BlockingQueue.

---

### 🎯 Model Answer

**30 seconds:**

> `ConcurrentLinkedQueue` is a non-blocking, lock-free, unbounded
> thread-safe FIFO queue implemented using CAS operations on a
> linked list. Key difference from `BlockingQueue`: it never blocks.
> `poll()` returns null if empty (never waits). `offer()` always
> returns true (unbounded). Use it for high-throughput task dispatch
> where producers and consumers run concurrently and you want
> non-blocking semantics.

**3 minutes (Senior):**

> `ConcurrentLinkedQueue` uses Michael-Scott queue algorithm: a
> linked list with CAS-based head and tail updates. Inserts CAS
> the tail pointer; removes CAS the head pointer. Multiple threads
> can insert and remove simultaneously without locking. The
> performance characteristic: very low overhead under low-to-moderate
> contention; under very high contention, CAS retries increase.
>
> The non-blocking nature is both the strength and the constraint.
> There is no `take()` method - you call `poll()` and get null if
> empty. If you need blocking semantics (wait for an element), you
> must poll in a loop with sleep - a busy-wait anti-pattern. Use
> `LinkedBlockingQueue` instead when you need blocking.
>
> `size()` is O(n) - it traverses the list to count. Never call
> `size()` in production in a loop; use `isEmpty()` for existence
> checks (O(1)).
>
> Typical use: high-throughput event processing where the producer
> never needs to block on the consumer, and the consumer polls
> continuously. Also used in the `ForkJoinPool` work-stealing
> deques.

---

### 💻 Code Example

**Example 1: Non-blocking producer-consumer**

```java
ConcurrentLinkedQueue<Event> eventQueue = new ConcurrentLinkedQueue<>();

// Producer: non-blocking, never waits
void produceEvents() {
    while (running) {
        Event e = generateEvent();
        eventQueue.offer(e);  // always returns true (unbounded)
        // Producer never blocks, never slows down for the consumer
        // Risk: if consumer is slow, memory grows unbounded
    }
}

// Consumer: poll-based (non-blocking)
void consumeEvents() {
    while (running) {
        Event e = eventQueue.poll();  // returns null if empty
        if (e == null) {
            // Empty: brief sleep to avoid CPU spin
            LockSupport.parkNanos(1_000_000L);  // 1ms park
            continue;
        }
        processEvent(e);
    }
}

// BAD: Busy-wait without sleep - 100% CPU on empty queue
// while (running) {
//     Event e = eventQueue.poll();
//     if (e != null) processEvent(e);
//     // If queue empty: spins 100M times/second, pegs CPU
// }

// GOOD alternative: batch drain to reduce overhead
List<Event> batch = new ArrayList<>(100);
while (running) {
    // Drain up to 100 events atomically (not truly atomic, but fast)
    Event e;
    int count = 0;
    while ((e = eventQueue.poll()) != null && count++ < 100) {
        batch.add(e);
    }
    if (!batch.isEmpty()) {
        processBatch(batch);
        batch.clear();
    } else {
        LockSupport.parkNanos(100_000L);  // 0.1ms if empty
    }
}
```

> **Code walkthrough:** `ConcurrentLinkedQueue` is truly non-blocking:
> `offer()` never blocks (unbounded). `poll()` returns null immediately
> if empty. The consumer must handle the null case without busy-
> waiting. The batch drain pattern is more efficient: draining
> multiple elements per iteration amortizes the per-element
> overhead. The `parkNanos` sleep prevents CPU spinning when the
> queue is consistently empty.

---

### ⚖️ Comparison

| | ConcurrentLinkedQueue | LinkedBlockingQueue |
|--|----------------------|---------------------|
| Blocking | never | put() blocks when full, take() blocks when empty |
| Bound | unbounded | optionally bounded |
| Empty check | poll() returns null | take() blocks |
| Size | O(n) - avoid | O(1) approximate |
| Use case | Non-blocking high-throughput | Producer-consumer with back-pressure |
| Algorithm | CAS linked list | Two-lock linked list |

**The deciding factor:** Need blocking semantics or back-pressure
= `LinkedBlockingQueue`. Need non-blocking, low-latency, non-blocking
dequeue = `ConcurrentLinkedQueue`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ConcurrentLinkedQueue` is a thread-safe, non-blocking queue.
> `offer()` adds elements without blocking. `poll()` removes
> and returns the head or null if empty. Unlike `BlockingQueue`,
> it never blocks.

---

**Senior / Staff (5+ years):**

> I use `ConcurrentLinkedQueue` in event-processing pipelines where
> I want zero blocking overhead at the producer. The consumer runs
> on a dedicated thread polling in a tight loop with minimal sleep.
> For throughput monitoring, I track queue depth (polling size() is
> too expensive - I maintain a separate AtomicLong counter) as a
> consumer lag metric.

---

### ❓ Questions You Will Be Asked

#### Definition

- "When would you use ConcurrentLinkedQueue vs BlockingQueue?"

🗣️ "`ConcurrentLinkedQueue` when I need non-blocking semantics:
the producer should never wait, and the consumer handles empty-
queue gracefully by polling with backoff. `BlockingQueue` when I
need back-pressure: the producer should block when the consumer
is overwhelmed, preventing OOM from queue growth. Most production
producer-consumer systems benefit from back-pressure, so
`BlockingQueue` with a bounded capacity is the safer default."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | CAS-based implementation, size() O(n), non-blocking contract. |
| Hiring Manager   | Trade-off vs BlockingQueue, when to use each. |
| Bar Raiser       | Michael-Scott queue algorithm, work-stealing deques. |
| Peer Engineer    | "Non-blocking queue + busy-wait consumer burned 100% CPU on quiet servers..." |

---

---

# Concurrent Collections Design

**Interview Weight:** high - Staff-level synthesis question.
Tests ability to articulate the design principles behind concurrent
collections and apply them to new scenarios.

---

### 🎯 Model Answer

**30 seconds:**

> Concurrent collections follow three design patterns: (1) Lock
> striping - divide the data into independent segments, each with
> its own lock (ConcurrentHashMap). (2) Copy-on-write - mutations
> create a new copy, reads operate on the current snapshot (COWAL).
> (3) Non-blocking algorithms - CAS-based operations without locks
> (`ConcurrentLinkedQueue`, `AtomicInteger`). The right choice
> depends on read/write ratio, need for blocking semantics,
> and consistency requirements.

**3 minutes (Senior):**

> Every concurrent collection design trades some property for
> another. `ConcurrentHashMap` trades memory (overhead of per-bucket
> sync objects) and iteration consistency (weakly consistent) for
> concurrent-write throughput. `CopyOnWriteArrayList` trades write
> performance (O(n) copy) for zero-cost, lock-free reads and safe
> iteration. `BlockingQueue` trades potential blocking (producers
> pause) for bounded memory and back-pressure. `ConcurrentLinkedQueue`
> trades blocking capability for zero-lock throughput.
>
> The collection `fail-fast` vs `fail-safe` distinction:
> `ArrayList`, `HashMap`, and standard collections throw
> `ConcurrentModificationException` if modified during iteration
> (fail-fast). Concurrent collections (`ConcurrentHashMap`,
> `CopyOnWriteArrayList`) use weakly consistent iterators that
> never throw (fail-safe but may not reflect recent mutations).
>
> Design principle: the right concurrent collection eliminates
> the need for external synchronization entirely. If you find
> yourself writing `synchronized (map) { ... }` around a
> `ConcurrentHashMap` operation, either the operation should be
> expressed as `merge()`, `computeIfAbsent()`, etc., or you need
> a different data structure entirely.

---

### 💻 Code Example

**Example 1: Choosing the right concurrent collection**

```java
// Scenario: Metrics counters, updated from many threads, read periodically

// BAD: Synchronized HashMap - all operations serialize
Map<String, Long> metrics = new HashMap<>();
synchronized (metrics) {
    metrics.merge("requests", 1L, Long::sum);
}
// BAD: ConcurrentHashMap with external synchronization
ConcurrentHashMap<String, Long> m = new ConcurrentHashMap<>();
synchronized (m) { m.put("k", m.getOrDefault("k", 0L) + 1); }
// External sync defeats ConcurrentHashMap purpose

// GOOD: ConcurrentHashMap with atomic merge
ConcurrentHashMap<String, LongAdder> metrics2 = new ConcurrentHashMap<>();
metrics2.computeIfAbsent("requests", k -> new LongAdder()).increment();
// ConcurrentHashMap for safe creation, LongAdder for high-contention increment

// GOOD: For read-heavy config, CopyOnWriteArrayList for listeners,
//       BlockingQueue for pipeline, CLQ for non-blocking dispatch:

// Read-heavy lookup (cache-like):
ConcurrentHashMap<String, Config> config = new ConcurrentHashMap<>();

// Event listener registry (set-once, read-many):
CopyOnWriteArrayList<Listener> listeners = new CopyOnWriteArrayList<>();

// Task pipeline with back-pressure:
LinkedBlockingQueue<Task> pipeline = new LinkedBlockingQueue<>(500);

// High-throughput event dispatch (no back-pressure):
ConcurrentLinkedQueue<Event> events = new ConcurrentLinkedQueue<>();
```

> **Code walkthrough:** The metrics pattern combines `ConcurrentHashMap`
> (thread-safe map creation) with `LongAdder` (thread-safe high-
> contention counter per key). This is the standard pattern for
> metrics collection. Each tool handles the part it is best at:
> map operations at the ConcurrentHashMap level, high-contention
> counting at the LongAdder level.

---

### ⚖️ Comparison

| Collection | Pattern | Read Perf | Write Perf | Blocking | Best For |
|------------|---------|-----------|------------|----------|----------|
| ConcurrentHashMap | Lock striping | O(1), no lock | O(1), per-bucket | no | Thread-safe map |
| CopyOnWriteArrayList | Copy-on-write | O(1), no lock | O(n), copies all | no | Rare-write list |
| LinkedBlockingQueue | Two-lock list | O(1), read lock | O(1), write lock | yes | Bounded P-C queue |
| ConcurrentLinkedQueue | CAS linked | O(1), no lock | O(1), CAS | no | Non-blocking queue |
| AtomicInteger | CAS | O(1) | O(1), CAS retry | no | Single variable |

**The deciding factor:** Match the pattern to the workload:
read-heavy → lock striping or copy-on-write. Write-heavy → atomic/CAS.
Need blocking semantics → BlockingQueue.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java concurrent collections use three patterns: lock striping
> (ConcurrentHashMap), copy-on-write (COWAL), and non-blocking CAS
> (CLQ, Atomic types). Choose based on read/write ratio and whether
> you need blocking semantics.

---

**Senior / Staff (5+ years):**

> When designing a concurrent component, I ask: what is the read/
> write ratio? What are the consistency requirements for iteration?
> Is back-pressure needed? From those answers, the collection choice
> follows. I never add external synchronization to concurrent
> collections - if I need an external lock, the collection is wrong
> for the use case.

---

### ❓ Questions You Will Be Asked

#### Deep Dive

- "Why should you never synchronize externally on ConcurrentHashMap?"

🗣️ "External synchronization on `ConcurrentHashMap` defeats its
purpose. `ConcurrentHashMap` is designed so that individual atomic
operations (get, put, merge, computeIfAbsent) are thread-safe without
external locking. Adding `synchronized (map) { map.put(...) }` creates
a full-map lock, degrading performance to `synchronizedMap` levels.
If you find yourself needing external sync, it means the compound
operation you need is not available natively. In that case, use
the `compute()` or `merge()` methods instead, which are internally
atomic. If the operation is truly complex, `synchronized` on a
dedicated lock with an inner `HashMap` may be clearer."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Three patterns, weakly consistent vs fail-fast, design principles. |
| Hiring Manager   | Choosing the right tool for a given scenario. |
| Bar Raiser       | SkipList-based collections (ConcurrentSkipListMap), wait-free vs lock-free. |
| Peer Engineer    | "We added synchronized around our ConcurrentHashMap and wondered why it was slow..." |
