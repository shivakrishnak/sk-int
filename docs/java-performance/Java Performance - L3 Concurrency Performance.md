---
layout: default
title: "Java Performance - L3 Concurrency Performance"
parent: "Java Performance"
grand_parent: "SK Interview"
nav_order: 9
permalink: /java-performance/l3-concurrency-performance/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Performance - L3 Concurrency Performance](#java-performance---l3-concurrency-performance) | medium |

---

# Java Performance - L3 Concurrency Performance

## Lock Contention and Performance Anti-patterns

---

### 🎯 Model Answer

**30 seconds:**
> Lock contention: multiple threads competing for the same lock. Each blocked thread: context switch
> (OS), waiting, cache invalidation. Symptoms: high CPU but low throughput, thread dumps show
> BLOCKED threads. Fixes: lock-free data structures, lock splitting, reduced critical section size,
> read-write locks. `synchronized` in Java is biased -> thin -> inflated (escalating cost path).

**3 minutes (Senior):**
> Lock contention anatomy and mitigation:
>
> 1. **Java lock states (HotSpot)**: biased (single thread owns lock cheaply, no CAS), thin lock
>    (CAS-based, fast path for low contention), fat lock (OS mutex, parked threads). Transition is
>    one-way (or nearly so): once inflated to fat lock, rarely reverts. Implication: contention on
>    a lock permanently degrades it from CAS to OS mutex path.
>
> 2. **Cost of fat lock**: thread blocked on fat lock: OS park/unpark. Context switch: 1-10 microseconds.
>    Under high contention: most threads blocked most of the time, each unblock = context switch.
>    1,000 threads blocking at 10 microseconds each: 10ms wasted per operation cycle.
>
> 3. **Critical section minimization**: move everything except the shared state mutation outside the
>    lock. Common mistake: locking around IO, logging, or computation. Correct: compute outside,
>    lock only for the shared write.
>
> 4. **Lock splitting**: one lock for all state -> one lock per state shard (ConcurrentHashMap:
>    separate lock per segment/bucket). Thread A writes bucket 5, Thread B writes bucket 7: no contention.
>
> 5. **Lock-free**: `AtomicReference`, `ConcurrentLinkedQueue`, `CopyOnWriteArrayList`. CAS-based.
>    Under low contention: faster than locks. Under extreme contention: CAS retries are expensive.

**Blank Mind Recovery:**

**(1) Restate:** "Lock contention: threads compete for same lock. Cost: OS park/unpark (1-10us per context switch). Diagnosis: thread dump (BLOCKED threads), async-profiler. Fixes: minimize critical section, lock splitting, read-write locks, lock-free structures."

**(2) First principles:** "A lock serializes access. N threads competing: throughput = 1 / (lock_hold_time * N). To improve: reduce lock_hold_time (critical section), reduce N (sharding), or eliminate the lock (lock-free)."

**(3) Bridge:** "A single checkout lane at a supermarket: one customer at a time. Lock contention = one lane with 50 customers. Fixes: shorter transactions (fewer items per customer), more lanes (lock splitting), or self-checkout (lock-free CAS)."

---

### 📘 Concept Explanation

**Lock contention details and measurement:**
```
JAVA LOCK ESCALATION PATH (HotSpot JVM):

  State 1: Unlocked (no thread holds it)
  
  State 2: Biased locked (JDK < 21, deprecated in JDK 15):
    First thread to use the object gets the lock "biased" to it.
    Subsequent lock/unlock by the SAME thread: no CAS, very cheap.
    Another thread wants the lock: revoke the bias (expensive: stop-the-world)
    -> transitions to thin lock.
    Use case: objects locked only by one thread throughout their lifetime.
    Java 21+: biased locking removed (LockingMode=LightweightLocking default)
  
  State 3: Thin lock (lightweight lock):
    CAS-based acquisition. Fast if the CAS succeeds (no contention).
    If CAS fails (another thread holds it): spin briefly, then inflate to fat lock.
    Cost: ~10-30 ns (fast path), ~100-300 ns if spinning before inflation.
  
  State 4: Fat lock (inflated lock, OS mutex):
    Thread blocked on fat lock: OS park (surrender CPU time slice).
    Thread unblocked: OS unpark + context switch.
    Cost: 1,000-10,000 ns (1-10 microseconds) per acquire/release.
    
  Java 21 (LightweightLocking mode):
    Biased locking removed. Default path: lightweight CAS.
    Less biased->thin revocation overhead at startup.
    Fat lock behavior: unchanged.
  
  PRACTICAL IMPLICATION:
    Under zero contention: both synchronized and ReentrantLock are cheap.
    Under any contention: both escalate to OS mutex path.
    Difference: ReentrantLock provides tryLock(), timeout, fairness, conditions.
    synchronized: JVM can optimize it (lock elision, coarsening).

LOCK CONTENTION MEASUREMENT TOOLS:

  1. Thread dump (jstack or jcmd <pid> Thread.print):
     State: BLOCKED -> waiting to acquire a lock
     State: WAITING -> Object.wait() or LockSupport.park()
     If many threads show BLOCKED on the SAME lock: high contention.
     
  2. Async-profiler -e lock:
     ./profiler.sh -e lock -d 60 -f lock.html <pid>
     Shows: which locks are most contended + who holds them.
     Lock flame graph: thick bars = high lock wait time.
  
  3. JFR JavaMonitorEnter event:
     jcmd <pid> JFR.start settings=default
     In JMC: "Java Monitor Blocked" view -> sorted by duration.
     Shows: class name, lock holder stack trace, blocked thread stack trace.
  
  4. JVM metrics:
     jvm_threads_states_threads{state="blocked"} in Prometheus.
     Spike in BLOCKED threads: sudden lock contention.

LOCK SPLITTING EXAMPLE:

  // BAD: single lock for all key-value pairs (HashMap + synchronized):
  class SharedCache<K, V> {
      private final Map<K, V> map = new HashMap<>();
      
      synchronized V get(K key) { return map.get(key); }
      synchronized void put(K key, V value) { map.put(key, value); }
  }
  // All threads compete for the same lock.
  // 100 readers + 10 writers: readers block each other (no need!).
  
  // BETTER: ConcurrentHashMap (lock per bucket, read-mostly lock-free):
  class SharedCache<K, V> {
      private final ConcurrentHashMap<K, V> map = new ConcurrentHashMap<>();
      
      V get(K key) { return map.get(key); }  // lock-free read in most cases
      void put(K key, V value) { map.put(key, value); }  // lock per bucket
  }
  // get(): no lock (reads a volatile reference per bucket, then traverses).
  // put(): lock only the affected bucket (1 of 16 default segments).
  
  // EVEN BETTER for read-heavy: ReadWriteLock:
  class SharedCache<K, V> {
      private final Map<K, V> map = new HashMap<>();
      private final ReadWriteLock rwl = new ReentrantReadWriteLock();
      
      V get(K key) {
          rwl.readLock().lock();
          try { return map.get(key); }
          finally { rwl.readLock().unlock(); }
      }
      void put(K key, V value) {
          rwl.writeLock().lock();
          try { map.put(key, value); }
          finally { rwl.writeLock().unlock(); }
      }
  }
  // Multiple concurrent readers: no blocking between them.
  // Writer: exclusive lock (blocks all readers during write).
  // Benefit: 95% read workload -> 95% of operations proceed without blocking.

CRITICAL SECTION MINIMIZATION:

  // BAD: expensive work inside synchronized block:
  synchronized void processAndStore(String key, byte[] rawData) {
      byte[] processed = heavyCrypto(rawData);   // 50ms of CPU work
      byte[] compressed = compress(processed);   // 10ms of CPU work
      store.put(key, compressed);  // actual shared state (< 1ms)
  }
  // All threads blocked for 60ms while waiting for one thread's heavy work.
  
  // GOOD: expensive work outside synchronized block:
  void processAndStore(String key, byte[] rawData) {
      byte[] processed = heavyCrypto(rawData);   // 50ms, no lock needed
      byte[] compressed = compress(processed);   // 10ms, no lock needed
      synchronized (this) {
          store.put(key, compressed);  // lock held for < 1ms
      }
  }
  // Lock held for < 1ms instead of 60ms.
  // 60x less contention for the same throughput.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The critical section minimization example shows a concrete 60x improvement
> from moving compute outside the lock. The ReadWriteLock example shows the read-heavy optimization.
> The Striped lock pattern shows fine-grained locking for key-based access.

```java
// CRITICAL SECTION MINIMIZATION (production pattern):

// BAD: database write inside the lock (IO = long hold time):
class OrderService {
    private final Map<String, Order> pendingOrders = new HashMap<>();
    
    synchronized void submitOrder(String id, OrderRequest request) {
        Order order = new Order(id, request);
        db.save(order);          // 5-50ms blocking IO - lock held during IO!
        pendingOrders.put(id, order);
        eventBus.publish(new OrderCreated(id));  // another IO - still locked!
    }
    // Result: all callers blocked during every DB write + event publish.
    // At 100 RPS: threads queue up, latency spikes to seconds.
}

// GOOD: only the in-memory state update is locked:
class OrderService {
    private final ConcurrentHashMap<String, Order> pendingOrders = 
        new ConcurrentHashMap<>();
    
    void submitOrder(String id, OrderRequest request) {
        Order order = new Order(id, request);
        db.save(order);                         // no lock - concurrent IO ok
        pendingOrders.put(id, order);           // ConcurrentHashMap: thread-safe
        eventBus.publish(new OrderCreated(id)); // no lock - concurrent ok
    }
    // All IO is concurrent. pendingOrders.put() uses bucket-level lock (~1us).
}

// STRIPED LOCK PATTERN (per-key locking, Google Guava):
import com.google.common.util.concurrent.Striped;

class AccountService {
    // 64 striped locks: one per group of account IDs (based on ID.hashCode())
    private final Striped<Lock> stripedLocks = Striped.lock(64);
    private final Map<String, Account> accounts = new ConcurrentHashMap<>();
    
    void transfer(String fromId, String toId, BigDecimal amount) {
        // Lock both accounts (always in consistent order to prevent deadlock):
        String first = fromId.compareTo(toId) < 0 ? fromId : toId;
        String second = first.equals(fromId) ? toId : fromId;
        
        Lock lock1 = stripedLocks.get(first);
        Lock lock2 = stripedLocks.get(second);
        lock1.lock();
        try {
            lock2.lock();
            try {
                Account from = accounts.get(fromId);
                Account to = accounts.get(toId);
                // Critical section: only the state mutation is locked
                from.debit(amount);
                to.credit(amount);
            } finally {
                lock2.unlock();
            }
        } finally {
            lock1.unlock();
        }
    }
    // Two accounts in different stripes: no contention between them.
    // Two accounts in the same stripe: serialized (expected, rare).
    // 64 stripes: 64x less contention than a single global lock.
}
```

> **Code walkthrough:** The OrderService fix changes from a `synchronized` method (lock held
> during 50ms IO) to `ConcurrentHashMap.put()` (lock held for ~1us). The striped lock pattern
> shows per-key locking: 64 stripes reduce contention 64x vs a global lock, while the
> consistent lock ordering prevents deadlock.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Lock contention: threads block waiting for a lock. Symptoms: BLOCKED threads in thread dump.
> Fix: minimize critical section (keep IO outside locks), use ConcurrentHashMap instead of
> synchronized HashMap. ReadWriteLock for read-heavy workloads. LongAdder for counters.

---

**Senior / Staff (5+ years):**
> Fat lock cost: OS context switch (1-10us). At scale: this adds up to seconds per minute of
> wasted CPU. Diagnosis: async-profiler -e lock + JFR JavaMonitorEnter. Mitigation strategy:
> (1) measure first, (2) minimize critical section, (3) split locks, (4) consider lock-free
> structures. Striped locks (Guava Striped): production pattern for per-key locking. Avoid
> fairness (ReentrantLock(true)): fair locks have 3-5x overhead vs unfair; use only when
> starvation is proven.

---

### ⚠️ Common Misconceptions

**Misconception: "ReentrantLock is always faster than synchronized."**
`synchronized` can be optimized by the JVM: lock elision (if the lock object doesn't escape),
lock coarsening (multiple adjacent synchronized blocks on the same object merged into one),
biased locking (single-thread case: nearly free). `ReentrantLock` is a Java object; the JVM
doesn't apply the same JIT optimizations. For uncontended single-thread access: `synchronized`
may be faster than `ReentrantLock` due to JIT lock elision. For contended multi-thread access:
both escalate to OS mutex; performance is similar. Use `ReentrantLock` when you need: tryLock(),
timed lock, fairness, or multiple conditions. Use `synchronized` for simplicity in all other cases.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Service throughput plateaus under load despite adding threads.**
```
Symptom: 10 threads -> 10,000 RPS. 50 threads -> 10,200 RPS.
  Adding threads doesn't improve throughput (Amdahl's Law: serial fraction dominates).
  CPU usage: high (threads are running, not sleeping).
  p99 latency: high and growing with thread count.

Diagnosis:
  Step 1: thread dump:
  jcmd <pid> Thread.print | grep -E "BLOCKED|WAITING" | wc -l
  If many BLOCKED threads: lock contention confirmed.
  
  Step 2: identify the lock:
  jcmd <pid> Thread.print > threads.txt
  grep -A 5 "BLOCKED" threads.txt
  Shows: "waiting to lock <0x7f3a1234> (a com.example.SharedService)"
  
  Step 3: find all threads blocked on that lock:
  grep "0x7f3a1234" threads.txt
  Shows: 40 threads blocked on the SAME lock object.
  
  Step 4: find the lock holder:
  grep -B 5 "locked <0x7f3a1234>" threads.txt
  Shows the stack trace of the thread currently holding the lock.
  Root cause: that thread is doing IO (DB call) while holding the lock.

Fix: move the IO outside the lock (see Code Example above).
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Lock escalation | 2 minutes |
| Lock contention diagnosis | 2 minutes |
| Critical section minimization | 2 minutes |
| Lock splitting | 2 minutes |
| ReadWriteLock | 1 minute |
| synchronized vs ReentrantLock | 1 minute |
| Striped locks | 1 minute |
| Deadlock diagnosis | 1 minute |
| Amdahl's Law and concurrency | 1 minute |

---

**Q1 (escalation): How does JVM lock escalation work and what are the performance implications?**

A: HotSpot lock states: (1) Biased: single thread owns the lock, no CAS needed. Cost: near zero
for the owning thread. Revocation cost: stop-the-world safepoint. (2) Thin: CAS-based, no OS
involvement. Cost: ~10-30ns per lock/unlock. (3) Fat: OS mutex, parked threads. Cost: 1-10 microseconds
per lock/unlock. Escalation: biased -> thin (another thread wants the lock). Thin -> fat (CAS contention
spin timeout). Implication: once a lock becomes a fat lock under production load, it rarely reverts.
The lock's cost permanently increases. JDK 21: biased locking removed entirely (simpler model,
lightweight CAS is the default fast path).

*What separates good from great:* The "lock inflation storm" at startup: when a Spring application
starts and initializes beans concurrently, many locks get inflated (Spring bean registry, class loading,
etc.). The startup is I/O and lock-heavy. After startup: most locks deflate or stabilize. But some
locks that were contended at startup remain fat. Diagnosis: JFR JavaMonitorInflated events during
startup. If many locks inflate during startup and remain inflated: consider sequential bean initialization
for those components (or use lock-free data structures in the initialization path). The key insight:
lock inflation is a symptom of contention; the fix is to reduce contention, not to try to "deflate"
locks manually.

---

**Q2 (diagnostic): Walk through diagnosing a lock contention problem from production symptoms to root cause.**

A: Step 1: Initial signal. Service response time increases, thread pool saturation alert fires.
Step 2: Thread dump (jstack or jcmd). Count BLOCKED threads. If > 10% of threads are BLOCKED: lock
contention. Step 3: Identify the lock. BLOCKED thread shows "waiting to lock `<0x1234>` (a ClassName)".
Step 4: Find all waiters. Search for `0x1234` in the thread dump. Step 5: Find the holder. Search for
`locked <0x1234>`. The holder's stack trace shows what it's doing while holding the lock.
Step 6: Quantify. JFR `JavaMonitorEnter` event: sort by duration. Top locks: the bottleneck.
Step 7: Fix. Move IO outside the lock, or switch to ConcurrentHashMap/ReadWriteLock.

*What separates good from great:* The "lock hierarchy" diagnostic: complex lock contention often
involves chains. Thread A holds Lock 1, waiting for Lock 2. Thread B holds Lock 2, waiting for Lock 1.
This is deadlock. jstack shows: Thread A: locked Lock1, waiting Lock2. Thread B: locked Lock2, waiting
Lock1. JVM detects deadlocks: jstack -l prints "Found 1 Java-level deadlock". For production: JFR
`JavaMonitorDeadlockDetect` event. Prevention: always acquire locks in a consistent order (as shown in
the Striped lock transfer example). The consistent ordering rule prevents deadlock by construction.

---

---

## Non-Blocking Algorithms and CAS Performance

---

### 🎯 Model Answer

**30 seconds:**
> CAS (Compare-And-Swap): atomic CPU instruction. If memory[address] == expected: set to new value
> and return true. Else: return false. Enables lock-free data structures. Cost under no contention:
> ~10ns. Under high contention: CAS retries loop (busy-wait). Trade-off: lock-free is faster than
> locks at low-medium contention; at very high contention (> 8 threads on same CAS): lock-free
> degrades. LongAdder: solution for high-contention counters.

**3 minutes (Senior):**
> CAS mechanics and practical application:
>
> 1. **CAS instruction**: x86 LOCK CMPXCHG, ARM LDAXR/STLXR. Atomic read-modify-conditional-write.
>    JDK: `AtomicLong.compareAndSet(expected, update)`. Returns true if successful.
>
> 2. **ABA problem**: Thread 1 reads value A. Thread 2 changes A -> B -> A. Thread 1's CAS succeeds
>    (value is A again). But the state has changed and back. Fix: `AtomicStampedReference`: includes
>    a version stamp along with the value. CAS on (value, stamp). ABA impossible: each change increments
>    the stamp even if the value returns to A.
>
> 3. **Contention scaling**: 1-4 threads sharing an AtomicLong: near-linear throughput. 8+ threads:
>    CAS contention (most CAS fail, retry). 16 threads: throughput may plateau or decrease. Solution:
>    LongAdder (striped: separate cell per CPU, combined at read).
>
> 4. **Lock-free queue**: `ConcurrentLinkedQueue`: Michael-Scott two-pointer non-blocking queue.
>    Enqueue: CAS on the tail pointer. Dequeue: CAS on the head pointer. Both operations: single CAS
>    per operation. Linearizable (correct under concurrent access). But: under extreme throughput:
>    still bounded by CAS contention on tail/head.

**Blank Mind Recovery:**

**(1) Restate:** "CAS: atomic compare-and-swap. Returns true if value matched and was updated. Lock-free algorithms use CAS loops. ABA problem: stamp fixes it. LongAdder: shards CAS across multiple cells -> scales with thread count. Use LongAdder for high-contention counters; AtomicLong for read-heavy counters."

**(2) First principles:** "CAS: hardware-level atomicity. CPU guarantees: no other core can modify the memory location between the compare and the swap. When multiple threads CAS the same location: only one succeeds per cycle. At high thread count: N-1 threads waste time on failed CAS attempts. Solution: reduce the number of threads sharing a single CAS location (striping)."

**(3) Bridge:** "CAS is like a single toll booth lane: one car at a time. Many cars (threads): most wait. AtomicLong = one lane. LongAdder = 64 lanes (one per CPU), combined at the exit. More lanes = more throughput at the cost of combining time at the exit."

---

### 📘 Concept Explanation

**CAS internals and lock-free patterns:**
```
CAS CPU INSTRUCTION:

  x86: LOCK CMPXCHG dest, src
    Atomically: if (dest == rax) { dest = src; ZF=1; } else { rax = dest; ZF=0; }
  ARM: LDAXR/STLXR pair (load-exclusive, store-exclusive)
    More complex: two instructions, but also atomic.
  
  Java: Unsafe.compareAndSetLong(obj, offset, expected, update)
  Used by: AtomicLong, AtomicReference, ConcurrentHashMap, LongAdder, etc.
  
  Cost:
    Cache line uncontended: ~4-8 ns (just a CPU instruction)
    Cache line shared (MESI Modified): 20-50 ns (cache coherence protocol)
    High contention (many threads): CAS fails, retries. 
    Each retry: another LOCK CMPXCHG + failed CAS + backoff.
    At 32 threads on 1 AtomicLong: throughput ~= 1 thread 
    (all threads fighting, ~1 succeeds per cycle)

CAS RETRY LOOP PATTERN:

  // Standard CAS loop:
  void add(AtomicLong counter, long delta) {
      long current;
      do {
          current = counter.get();  // read current value
      } while (!counter.compareAndSet(current, current + delta));
      // If CAS fails: another thread changed the value between get() and CAS.
      // Loop: read the new value, try again.
      // Eventually: CAS succeeds (when there's a "quiet" moment between reads).
  }
  
  // AtomicLong.addAndGet() does exactly this internally.
  
  // Under low contention: ~0-1 retries per operation. Fast.
  // Under high contention: ~N retries (N = number of competing threads).
  // At 16 threads: ~15 failed CAS attempts per successful operation.
  // Wasted work: 15x overhead.

ABA PROBLEM AND STAMPS:

  Scenario: lock-free stack using AtomicReference<Node>.
  
    Node A -> Node B -> null  (initial state, head = A)
    
    Thread 1: reads head = A, preempted before CAS.
    Thread 2: pops A (head = B). Pops B (head = null).
              Pushes A back (head = A, but B is gone!).
    Thread 1: resumes. CAS: expected=A, update=B. Succeeds!
              But B was ALREADY POPPED and may be freed/reused.
              head = B (stale, possibly dangling reference).
              -> USE-AFTER-FREE or wrong state.
  
  Fix: AtomicStampedReference<Node>:
    State: (head, stamp) where stamp increments on every modification.
    
    Thread 1: reads (head=A, stamp=1).
    Thread 2: pop A: CAS (A,1) -> (B,2). Pop B: CAS (B,2) -> (null,3).
              Push A: CAS (null,3) -> (A,4).
    Thread 1: CAS (A, stamp=1) fails! Current stamp is 4 (not 1).
              Thread 1 retries with the fresh (A, stamp=4) state.
    -> ABA problem prevented. Stamp ensures each modification is unique.
  
  In practice: ABA matters for lock-free data structures with node reuse.
  For simple counters (AtomicLong): ABA is irrelevant (no structural state).

LONGADDER INTERNALS:

  Striped64 (base of LongAdder):
    - base: single AtomicLong for uncontended operations
    - cells: Cell[] (padded cells, one per CPU ideally)
    - Cell: @Contended long value (no false sharing between cells)
  
  increment():
    1. Try CAS on base (fast path, no contention).
    2. If CAS fails: find a cell for the current thread (based on thread ID % cells.length).
       CAS on that cell. Usually succeeds (one thread per cell on average).
    3. If cell CAS also fails: expand cells[] or rehash.
  
  sum():
    return base + sum(cells[])  // combine all cells
    Note: sum() is NOT atomic. A thread may increment a cell DURING sum().
    Result: LongAdder.sum() may be slightly stale.
    Use: metrics, counters where approximate read is acceptable.
    Don't use for: exact balance tracking (use AtomicLong or synchronized).
  
  Performance:
    AtomicLong (16 threads, high contention):  ~50M ops/sec
    LongAdder (16 threads, high contention): ~800M ops/sec  (16x better)
    LongAdder (1 thread):                    ~400M ops/sec  (2x worse than AtomicLong 1-thread)
    Break-even: ~2 threads on the same counter.
    -> Use AtomicLong for < 2 threads or read-heavy.
    -> Use LongAdder for 2+ threads with write-heavy counter.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The LongAdder vs AtomicLong comparison shows the concrete break-even
> point and the design rule. The AtomicStampedReference example shows the ABA fix in code.

```java
// LONGADDER VS ATOMICLONG DECISION:

// BAD: AtomicLong for high-contention counter in request handler:
class RequestMetrics {
    private final AtomicLong totalRequests = new AtomicLong(0);
    
    void recordRequest() {
        totalRequests.incrementAndGet();  // CAS: all threads compete
    }
    long getTotalRequests() {
        return totalRequests.get();  // exact, consistent read
    }
}
// Under 50 threads: CAS retries dominate.
// recordRequest() becomes a bottleneck at high RPS.

// GOOD: LongAdder for high-frequency increment, infrequent read:
class RequestMetrics {
    private final LongAdder totalRequests = new LongAdder();
    
    void recordRequest() {
        totalRequests.increment();  // per-CPU cell CAS, minimal contention
    }
    long getTotalRequests() {
        return totalRequests.sum();  // combines all cells (slightly stale: ok for metrics)
    }
}
// 50 threads: each increment goes to its own cell.
// Almost no CAS contention. Scales linearly with thread count.

// WHEN TO KEEP AtomicLong: compare-and-exchange (CAS with check):
class SequenceGenerator {
    private final AtomicLong currentSequence = new AtomicLong(0);
    
    // Allocate a batch of IDs atomically:
    long[] allocateBatch(int batchSize) {
        long start = currentSequence.getAndAdd(batchSize);
        // getAndAdd: returns old value, atomically adds batchSize.
        // Thread A gets [0, 1000). Thread B gets [1000, 2000). No overlap.
        return LongStream.range(start, start + batchSize).toArray();
    }
    // This pattern requires exact atomic increment: LongAdder won't work.
    // (LongAdder has no getAndAdd equivalent)
}

// ABA FIX WITH AtomicStampedReference:
class LockFreeStack<T> {
    private final AtomicStampedReference<Node<T>> head = 
        new AtomicStampedReference<>(null, 0);
    
    void push(T item) {
        Node<T> newNode = new Node<>(item);
        int[] stampHolder = new int[1];
        Node<T> currentHead;
        do {
            currentHead = head.get(stampHolder);
            newNode.next = currentHead;
        } while (!head.compareAndSet(
            currentHead, newNode, 
            stampHolder[0], stampHolder[0] + 1));  // increment stamp!
    }
    
    T pop() {
        int[] stampHolder = new int[1];
        Node<T> currentHead;
        do {
            currentHead = head.get(stampHolder);
            if (currentHead == null) return null;
        } while (!head.compareAndSet(
            currentHead, currentHead.next,
            stampHolder[0], stampHolder[0] + 1));  // increment stamp!
        return currentHead.item;
    }
    // stamp increments on every push/pop.
    // ABA impossible: returning to the same node has a different stamp.
}
```

> **Code walkthrough:** The `LongAdder` use is for high-frequency writes (request recording). The
> `AtomicLong` retention is for the `getAndAdd` pattern (allocate a batch atomically - requires the
> return of the old value, which `LongAdder` doesn't provide). The `AtomicStampedReference` in the
> lock-free stack shows the stamp increment on every structural change, making the ABA scenario
> detectable because the stamp won't match even if the node reference returns to the same value.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> CAS: atomic compare-and-swap. Used by AtomicLong, AtomicReference. LongAdder: use for
> high-contention counters (scales better than AtomicLong). ABA problem: use AtomicStampedReference
> if node reuse in lock-free structures is needed. ConcurrentLinkedQueue: lock-free FIFO.

---

**Senior / Staff (5+ years):**
> CAS contention behavior: throughput peaks at ~4 threads on a single AtomicLong, then degrades.
> LongAdder solves this with striped cells but sacrifices exact reads. For monitoring/metrics:
> LongAdder is the right default for counters (approximate sum is fine). For control flow
> (compare-and-exchange patterns): AtomicLong or AtomicReference. Lock-free != wait-free: CAS
> retry loops are lock-free but not wait-free (a thread may retry indefinitely under pathological
> contention). For hard real-time: CAS loops are still risky.

---

### ⚠️ Common Misconceptions

**Misconception: "Lock-free algorithms always outperform locks."**
Lock-free (CAS-based) algorithms are faster than locks at LOW TO MEDIUM contention. At high contention
(many threads continuously retrying CAS on the same location): CAS retries become as expensive as
lock acquisition, and throughput may be similar or even worse (busy-spinning wastes CPU that blocked
threads don't waste). Locks: blocked threads yield their CPU (OS parks them). CAS loops: failed CAS
threads continue spinning (burning CPU). Under extreme contention: lock implementations that use
fair queuing (no spinning) can outperform CAS loops. The correct choice: measure under realistic
contention. Don't default to "lock-free = faster" without benchmarking.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Service CPU usage 100% but throughput is low.**
```
Symptom: 16 threads, 100% CPU, but only 50,000 RPS
  (expected: 500,000 RPS with 16 threads).
  Thread dump: threads are RUNNABLE (not BLOCKED).

Root cause: CAS contention with retry loops (hot busy-spin).
  All 16 threads are running, but almost all are in CAS retry loops.
  Each thread: read, CAS fail, read, CAS fail... 
  Only ~1 CAS succeeds per cycle (one per CPU cycle, not 16).

Diagnosis:
  Thread dump: RUNNABLE threads. Look for:
    java.util.concurrent.atomic.AtomicLong.compareAndSet
    sun.misc.Unsafe.compareAndSwapLong
  All threads stuck in the same CAS loop.
  
  async-profiler:
    ./profiler.sh -d 60 -f cpu.html <pid>
  Flame graph: thick bar at AtomicLong.incrementAndGet() or equivalent.
  
  JMH benchmark: confirm throughput degrades with thread count.

Fix:
  Replace AtomicLong with LongAdder for the contended counter.
  
  Before: AtomicLong.incrementAndGet() at 16 threads -> 50M ops/sec
  After: LongAdder.increment() at 16 threads -> 800M ops/sec
  
  Alternatively: use Thread-Local counters and aggregate periodically:
  class ThreadLocalCounter {
      private ThreadLocal<long[]> local = ThreadLocal.withInitial(() -> new long[1]);
      private AtomicLong aggregate = new AtomicLong();
      
      void increment() { local.get()[0]++; }
      // Flush periodically (or on thread exit):
      void flush() { aggregate.addAndGet(local.get()[0]); local.get()[0] = 0; }
  }
  // No CAS on the hot path. Periodic aggregation is cheap.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| CAS instruction and cost | 2 minutes |
| ABA problem and fix | 2 minutes |
| LongAdder striping | 2 minutes |
| CAS vs lock under contention | 2 minutes |
| Lock-free vs wait-free | 1 minute |
| ConcurrentLinkedQueue internals | 1 minute |
| CPU spinning diagnosis | 1 minute |
| When NOT to use lock-free | 1 minute |
| AtomicStampedReference | 1 minute |

---

**Q1 (cas): Explain the ABA problem and how Java provides a solution.**

A: The problem: in a CAS operation, thread A reads value X. Thread B changes X -> Y -> X. Thread A's
CAS: expected = X, which still matches. CAS succeeds. But the state is actually different (Y was in
between). For counters: ABA doesn't matter (order of increments is irrelevant). For structural data
(linked lists, queues, lock-free stacks with node reuse): ABA is dangerous. A node that was popped and
reused at the same address: CAS succeeds using stale assumptions about structure. Fix: `AtomicStampedReference`:
(value, stamp) pair. Each modification increments the stamp. ABA scenario: the stamp changes even if the
value reverts to A. Thread A's CAS: checks both value AND stamp. Stamp mismatch: fails correctly.

*What separates good from great:* The "generational stamp" usage beyond lock-free structures: version
stamps are the standard solution for distributed optimistic concurrency (database MVCC, ETags in HTTP).
The same principle: "value same, but state changed" is detectable with a stamp/version. In Java JPA:
`@Version` field = stamp. In REST: ETag + If-Match = stamp. In ZooKeeper: zxid = stamp. The ABA
problem is a manifestation of the general "stale state" problem. AtomicStampedReference is the
low-level Java primitive; @Version and ETags are the domain-level solutions. Understanding ABA
enables recognizing and designing against stale-state bugs in any concurrency context.

---

**Q2 (striping): How does LongAdder achieve better throughput than AtomicLong under contention?**

A: LongAdder uses striped cells: one `Cell` per CPU (ideally). Each cell: a padded (no false sharing)
`volatile long`. Threads are assigned cells based on their thread ID. `increment()`: first tries a
CAS on the `base` field. If CAS fails (contention on base): switches to a cell matching the thread's
hash. CAS on the cell. Each cell is owned by approximately 1 thread -> CAS succeeds almost always.
`sum()`: base + sum of all cells. Not atomic (may return stale value during concurrent increments).
Throughput: scales linearly with thread count (each thread's CAS hits a different cell). Memory:
overhead = `cells.length * 64 bytes` (padded). Default: cells grow to match CPU count.

*What separates good from great:* The "thundering herd reset" in LongAdder: `reset()` sets all cells
to 0. Under concurrent increments during reset: cells may be non-zero after reset returns. This is
intentional (not a bug): `reset()` is best-effort for snapshots. The correct usage: `sumThenReset()`
for metrics collection (combine and reset in one call). The subtle design: LongAdder cells grow on
contention (detected by failed CAS on current cell) but don't shrink. For applications with burst-then-
idle patterns: a LongAdder may have 64 cells after a burst but access only 1 cell during idle periods.
The padded cells take 64 * 64 = 4KB of memory permanently. In memory-constrained environments (many
thousands of LongAdder instances): prefer AtomicLong to avoid the per-instance cell growth.

---

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



