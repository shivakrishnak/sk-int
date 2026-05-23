---
id: JCO-014
title: ReentrantLock
category: Java Concurrency
difficulty: ★★★
interview_weight: high
asked_at: FAANG, Mid-size
seniority: senior, staff
tags: #java-concurrency #locking #threading #java-interview #synchronization
status: draft
version: 0
---

# 🔒 JCO-014 — REENTRANTLOCK

🎯 Interview Weight: High — Frequently asked at Senior and Staff interviews, especially as a follow-up to `synchronized` or in threading-heavy system design discussions.

---

### ⚡ The 30-Second Answer

> `ReentrantLock` is an explicit, flexible locking mechanism that does the same job as `synchronized`, but with more control. It was created because `synchronized` cannot time out, cannot be interrupted, and supports only one condition queue. You use it when you need to try for a lock and give up after a deadline, or signal specific waiting threads. The key insight is that the word "reentrant" is not the interesting part — the same guarantee `synchronized` already gives you — the interesting parts are `tryLock` and multiple `Condition` objects.

---

### 🎯 Why Interviewers Ask This

**What they are really testing:**

- Whether you understand _why_ `synchronized` is sometimes insufficient
- Whether you know the lock/unlock contract and what happens if you skip `unlock()` in a `finally` block
- Whether you can articulate the fairness trade-off and when it matters

**Roles that ask this most:**
Backend / Full Stack / SRE / All senior+ Java roles

**Seniority signal:**

| Answer Quality                                                                | Seniority Signal |
| ----------------------------------------------------------------------------- | ---------------- |
| "It's like `synchronized` but explicit"                                       | Junior           |
| Explains lock/unlock contract + `finally` rule                                | Mid-level        |
| Discusses fairness, `tryLock`, condition variables, starvation risk           | Senior           |
| Chooses between `ReentrantLock` / `ReadWriteLock` / `StampedLock` by workload | Staff            |

---

### 📘 Concept Explanation

**What it is:**
`ReentrantLock` is a mutual exclusion lock from `java.util.concurrent.locks` that provides all the guarantees of `synchronized`, plus timed acquisition, interruptible acquisition, fairness control, and multiple condition variables.

**The problem it solves:**
Before `ReentrantLock`, `synchronized` was the only built-in option, but it was a blunt instrument. You could not attempt to acquire a lock and give up after 200ms. You could not be interrupted while waiting. You could not wake only producers without waking consumers. These limits caused real production problems — deadlocks where no thread could break out, and starvation where some threads never got scheduled.

**How it works:**

```
Thread A                          AQS State
   |
   lock.lock()  ─────────────→  [owner=A, holdCount=1]
   lock.lock()  ─────────────→  [owner=A, holdCount=2]  ← reentrant
   lock.unlock()─────────────→  [owner=A, holdCount=1]
   lock.unlock()─────────────→  [owner=null, holdCount=0]
                                       ↓ unpark next waiter
Thread B (was waiting)           Wait Queue: [B → C → D]
   gets lock   ←──────────────  AQS wakes B
                                (in unfair mode, a new arrival
                                 may cut the queue before B)
```

Internally, `ReentrantLock` uses `AbstractQueuedSynchronizer` (AQS) — a state machine that manages a CAS-protected owner field and a FIFO queue of parked threads. When the hold count reaches zero, AQS unparks the next thread in the queue.

**The key insight:**
The "reentrant" part is not what makes this interesting — `synchronized` is also reentrant. The features that justify choosing `ReentrantLock` over `synchronized` are exactly two: `tryLock(long, TimeUnit)` and multiple independent `Condition` objects per lock. These eliminate entire classes of deadlock and starvation that `synchronized` cannot address.

**When to use it:**

- Need a timed lock: `lock.tryLock(500, TimeUnit.MILLISECONDS)` to shed load or avoid deadlock
- Need interruptible acquisition: `lock.lockInterruptibly()` so a waiting thread can respond to interrupt
- Need multiple wait queues: `lock.newCondition()` to separately signal producers vs consumers
- Need fair scheduling: `new ReentrantLock(true)` to serve threads in arrival order

**When NOT to use it:**

- Simple critical sections that need none of the above — `synchronized` is clearer, less error-prone, and the JIT can apply biased locking optimisations more aggressively
- High-read, low-write workloads — prefer `ReadWriteLock` (separate read/write locks) or `StampedLock` (optimistic reads with zero contention overhead)
- Non-blocking scenarios — lock-free structures (`AtomicInteger`, `ConcurrentHashMap`) are better

**Alternatives:**

- `synchronized` → simpler syntax, JIT-optimised, no try/finally required; choose for simple cases
- `ReadWriteLock` → separate read and write locks; readers do not block each other; choose when reads dominate
- `StampedLock` → non-reentrant, no conditions, but optimistic reads have zero lock overhead; fastest for read-heavy
- `Semaphore` → allows N concurrent threads rather than exactly 1; choose for rate limiting or connection pools

**First-principles derivation:**
Given the constraint "only one thread may modify shared state at a time," we need mutual exclusion. `synchronized` achieves this but with one wait queue and one condition — all waiting threads share the same `Object.wait()` pool. Once we need "wake only producers" or "give up after 100ms," a single monolithic queue is insufficient. We need: a hold counter (for re-entrancy), a queue with per-waiter metadata (interrupt flag, deadline), and named condition queues. That is exactly what `ReentrantLock` + `Condition` provides — we inevitably arrive here from first principles.

---

### 🎓 Interview Answers by Seniority

**Junior Answer (0-2 years):**

> "`ReentrantLock` is like `synchronized` but you write `lock()` and `unlock()` explicitly instead of using a block. It lets you do things `synchronized` cannot — like trying to get the lock and giving up after a timeout instead of waiting forever. The name reentrant means the same thread can lock it again if it already holds it, which prevents the thread from deadlocking with itself."

_What makes this answer strong:_

- Correctly anchors it to the problem `synchronized` cannot solve
- Explains "reentrant" accurately without jargon

_What to add if they push deeper:_

- Mention the `finally { lock.unlock(); }` rule — always unlock in a finally block regardless of exceptions

---

**Mid-Level Answer (2-5 years):**

> "I use `ReentrantLock` when `synchronized` is not flexible enough. The three main use cases are: timed acquisition — `tryLock(500, TimeUnit.MILLISECONDS)` so a thread does not block forever; interruptible acquisition — `lockInterruptibly()` so a waiting thread can respond to interrupt; and multiple conditions — `lock.newCondition()` to separately signal producers vs consumers, which `synchronized`'s `notifyAll()` cannot do cleanly. The critical rule is always `unlock()` in a `finally` block. If an exception fires before unlock, every thread waiting on that lock is stuck permanently."

_What makes this answer strong:_

- Three concrete use cases — not just "it's more flexible"
- The `finally` rule mentioned unprompted, signalling production awareness

_What to add if they push deeper:_

- Fair vs unfair mode: `new ReentrantLock(true)` ensures arrival-order scheduling; default unfair mode has higher throughput but risks starvation under sustained load

---

**Senior Answer (5-8 years):**

> "I have used `ReentrantLock` in two real contexts. First, implementing a bounded buffer where producers and consumers need separate conditions — `notFull.await()` and `notEmpty.signal()`. With `synchronized + notifyAll()` you wake all waiting threads on every insert or remove; most cannot proceed, so you burn CPU. With two conditions you wake only the right side. Second, in a service calling a slow external dependency I used `tryLock(200, MILLISECONDS)` to shed load — if the lock is unavailable after 200ms, return a 503 immediately rather than queuing hundreds of blocked threads. The one mistake I have seen repeatedly is forgetting `finally { lock.unlock(); }`. One unchecked exception and the lock is held permanently. On fairness: I default to unfair for throughput and switch to fair only when I can measure starvation in production metrics or thread dumps."

_What makes this answer strong:_

- Two concrete production use cases with specific numbers and reasoning
- Failure mode (missing `finally`) stated explicitly
- Fairness decision expressed as a measurement-driven choice, not a default

_What to add if they push deeper:_

- `StampedLock` for optimistic reads: if writes are rare, `tryOptimisticRead()` + `validate(stamp)` does zero locking for reads

---

**Staff Answer (8+ years):**

> "My first instinct when I see `ReentrantLock` in a design is to question whether shared mutable state can be eliminated instead. Locks are correct; lock-free designs or immutable messaging are often better. That said, `ReentrantLock` is the right tool in three specific cases: bounded blocking queues with two conditions (this is `ArrayBlockingQueue`'s own implementation), connection pools with `tryLock` and graceful degradation, and lock splitting — replacing one coarse `synchronized(this)` with two independent `ReentrantLock` objects protecting disjoint state. At scale I watch for contention, not correctness. I profile with `async-profiler` looking for `AbstractQueuedSynchronizer.acquire()` appearing in hot paths. When I see that, I either move to `StampedLock` for reads — optimistic reads have zero overhead when writes are rare — or redesign to remove the shared state entirely. The fairness flag is a last resort: it trades throughput for predictability, which is rarely the right trade in a high-RPS service."

_What makes this answer strong:_

- Opens by questioning the premise — signals architectural maturity
- Three specific use cases with clear reasoning, not a generic list
- Names exact profiling tool (`async-profiler`) and the method to watch
- Clear escalation path: `ReentrantLock` → `StampedLock` → redesign

_What to add if they push deeper:_

- `StampedLock` optimistic read pattern: `long stamp = lock.tryOptimisticRead(); read state; if (!lock.validate(stamp)) { stamp = lock.readLock(); /* retry */ }`

---

**TIME-CALIBRATED VERSIONS:**

_30-second:_ "`ReentrantLock` is an explicit lock that adds timeout, interrupt, and multiple condition queues over `synchronized`. Always unlock in a finally block."

_90-second:_ Add: three use cases — `tryLock` for timeout, `lockInterruptibly` for interrupt, `newCondition` for separate producer/consumer queues. Mention unfair is default and faster.

_3-minute:_ Add: one production story (bounded buffer or load-shedding service). Mention the missing-finally failure mode. Compare to `synchronized` with explicit deciding factor.

_5-minute:_ Add: `StampedLock` comparison, when to escalate away from `ReentrantLock`, profiling approach with `async-profiler`, and when the lock itself is the wrong answer.

---

### ❓ Questions You Will Be Asked

**Definition Questions:**

- "What is `ReentrantLock` and how does it differ from `synchronized`?"
  → Cover: explicit lock/unlock, timeout, interrupt, multiple conditions; same mutual exclusion and re-entrancy guarantee

- "What does 'reentrant' mean in the context of locks?"
  → Cover: same thread can re-acquire; hold count increments; must call `unlock()` same number of times as `lock()`

**Mechanism Questions:**

- "What happens internally when you call `lock.lock()` on a `ReentrantLock`?"
  → Cover: AQS checks owner; if free, CAS to set owner + holdCount=1; if current thread owns, holdCount++; otherwise enqueue thread and park

- "Walk me through what happens if a thread holding a `ReentrantLock` throws an unchecked exception."
  → Cover: if `unlock()` is not in a `finally` block, the lock is never released; all waiting threads are blocked permanently; this is the #1 production bug with explicit locks

**Comparison Questions:**

- "When would you use `ReentrantLock` instead of `synchronized`?"
  → Cover: need timeout (`tryLock`), need interruptibility (`lockInterruptibly`), or need multiple separate conditions

- "What is the difference between `ReentrantLock` and `StampedLock`?"
  → Cover: `StampedLock` is non-reentrant, has no conditions, but supports optimistic reads with zero lock overhead; choose `StampedLock` for read-heavy workloads where writes are rare

**Scenario Questions:**

- "Implement a bounded buffer using `ReentrantLock`."
  → Cover: one lock, two conditions (`notFull`, `notEmpty`); producers await `notFull` and signal `notEmpty`; consumers await `notEmpty` and signal `notFull`

- "You have a service calling a slow external API. How would you use `ReentrantLock` to avoid thread exhaustion?"
  → Cover: `tryLock(200, MILLISECONDS)`, return 503 if unavailable; prevents unbounded thread pile-up under sustained load

**Debugging Questions:**

- "A service deadlocked. Threads are stuck in `AbstractQueuedSynchronizer.acquire()`. What happened?"
  → Cover: likely lock not released — missing `finally`; or lock ordering inconsistency; use `jstack` to identify lock owner and all waiters

- "How would you detect thread starvation on a `ReentrantLock`?"
  → Cover: `async-profiler` for per-thread blocking time; `jstack` for threads in WAITING state; `lock.getQueueLength()` as a live metric; consider `new ReentrantLock(true)` if starvation is confirmed

**Deep Dive Questions:**

- "Why is `ReentrantLock` built on `AbstractQueuedSynchronizer`?"
  → Cover: AQS provides a reusable CAS + park/unpark framework shared by `Semaphore`, `CountDownLatch`, and `ReentrantLock`; avoids duplicating synchronisation primitives

- "What are the limitations of `ReentrantLock` at high concurrency?"
  → Cover: still a blocking lock — threads queue and park/unpark has OS-level overhead; at high read-to-write ratios `StampedLock` optimistic reads have zero contention cost

---

### 🏗️ The Answer Framework

**WHAT → WHY → HOW → TRADE-OFF → EXAMPLE**

```
WHAT:    Explicit mutual exclusion lock with timeout, interrupt,
         and multiple condition queues
WHY:     synchronized has no timeout, cannot be interrupted,
         supports only one condition (Object.wait)
HOW:     lock() → critical section → unlock() in finally;
         hold count tracks re-entrancy depth in AQS
TRADE:   More control than synchronized, but more error-prone —
         one missing finally = permanent deadlock
EXAMPLE: Bounded connection pool: tryLock(500, MILLISECONDS)
         to shed load rather than queuing 500 blocked threads
```

_Adapt the depth:_

| Level  | Use                                                           |
| ------ | ------------------------------------------------------------- |
| Junior | WHAT + WHY + EXAMPLE                                          |
| Mid    | WHAT + WHY + HOW + "always unlock in finally"                 |
| Senior | All five + production failure + condition variable use case   |
| Staff  | All five + when to reach for StampedLock + profiling approach |

---

### ⚖️ How It Compares

| Option            | Re-entrant | Timeout | Conditions        | Best For                           |
| ----------------- | ---------- | ------- | ----------------- | ---------------------------------- |
| **ReentrantLock** | ✅         | ✅      | Multiple          | Flexible exclusion, bounded queues |
| `synchronized`    | ✅         | ❌      | One (wait/notify) | Simple critical sections           |
| `ReadWriteLock`   | ✅         | ✅      | Yes               | Read-heavy, write-rare             |
| `StampedLock`     | ❌         | ✅      | ❌                | Maximum read throughput            |
| `Semaphore`       | ❌         | ✅      | ❌                | Exactly N concurrent slots         |

**The deciding factor:**
Use `ReentrantLock` when you need multiple conditions or timed acquisition; use `StampedLock` when reads dominate; use `synchronized` when neither extra feature is needed.

**Interview tip:**
Bring up this comparison proactively: "Before I answer, let me clarify which lock primitive fits best here..." — signals trade-off thinking without being prompted.

---

### 🔥 Production Scenarios

**Scenario 1: Missing `finally` Block Deadlocks the Service**

Situation:
A Java service processed payment confirmations. After a deploy, threads started accumulating and within minutes the service was unresponsive. No exceptions appeared in logs — threads were simply stuck.

What happened:
A developer added a `ReentrantLock` to protect a payment record cache but called `lock.lock()` inside a try block without a corresponding `finally { lock.unlock(); }`. A `NullPointerException` in a downstream call left the lock permanently held. All subsequent threads queued on `lock.lock()` and never progressed.

How it was diagnosed:

```bash
# Capture thread dump — look for threads WAITING on ReentrantLock
jstack <pid> | grep -A 30 "BLOCKED\|waiting to lock"

# Find which thread holds the lock (look for "locked <0x...>")
jstack <pid> | grep -B 5 "locked <0x"

# Count threads stuck waiting on the same lock address
jstack <pid> | grep -c "waiting on <0x"
```

How it was resolved:
Added `finally { lock.unlock(); }` around every lock acquisition. Added a Spotbugs rule to flag `lock()` calls not guarded by a finally block in CI.

Interview use:
"I once investigated a payment service where threads backed up silently — no errors, just a growing queue and rising response times. `jstack` showed every thread WAITING on the same `ReentrantLock`. The owner thread had thrown an NPE and terminated without releasing the lock. Since that incident I treat `lock.unlock()` in a `finally` block as an absolute rule."

**RCA chain:**

- Symptom → thread count climbing, response time approaching timeout, no error logs
- Hypotheses → H1: lock not released — most likely; H2: deadlock cycle between two locks; H3: slow downstream holding lock
- Tests → `jstack <pid>` to check BLOCKED/WAITING threads and identify lock owner
- Root Cause → `lock.lock()` in try without finally; owner thread died holding it
- Fix → wrap every `lock.lock()` call in `try { ... } finally { lock.unlock(); }`
- Prevention → Spotbugs / Checkstyle rule to flag unguarded `lock()` calls

**STAR story:**
Situation: Payment service unresponsive two minutes after deploy; SLA breach imminent.
Task: On-call engineer; identify and resolve within SLA window.
Action: Captured thread dump with `jstack`; found all threads WAITING on one `ReentrantLock`; identified owner thread had terminated; added `finally` block and redeployed in 8 minutes.
Result: Service recovered immediately; added static analysis rule to catch this class of bug in CI.

---

**Scenario 2: Thread Starvation Under Load with Unfair Mode**

Situation:
A high-throughput order processing service used `ReentrantLock` in default (unfair) mode to protect an in-memory order book. Under sustained load, tail latency spiked to seconds while median latency remained normal.

What happened:
Unfair mode allows a thread that just released the lock to re-acquire it immediately, before waking the next queued thread. Under sustained high throughput, the same active threads kept winning the re-acquisition race, while threads that arrived slightly earlier and were queued were effectively starved.

How it was diagnosed:

```bash
# async-profiler: identify per-thread lock contention time
./profiler.sh -e lock -d 60 -f lock-profile.html <pid>

# Check current queue depth on the lock (add to metrics/health endpoint)
System.out.println("Queue length: " + lock.getQueueLength());
System.out.println("Has queued threads: " + lock.hasQueuedThreads());
```

How it was resolved:
Switched to `new ReentrantLock(true)` (fair mode). Aggregate throughput dropped approximately 8–10% but tail latency improved substantially and starvation was eliminated. Added `lock.getQueueLength()` to the metrics dashboard.

Interview use:
"We had a starvation problem in our order service — `async-profiler` showed certain threads spending 90%+ of their time waiting for a lock that other threads kept re-acquiring. Switching to fair mode cost throughput but fixed the tail latency. The lesson: unfair is the right default for most services, but when you measure starvation, fair mode is the lever."

---

### ⚠️ Common Mistakes Candidates Make

| Mistake                                                 | Why It Hurts                                                              | Say This Instead                                                                                                                                             |
| ------------------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| "`ReentrantLock` is always better than `synchronized`"  | Signals hammer/nail thinking; ignores JIT optimisations for simple blocks | "Each has its place — I use `synchronized` for simple critical sections and `ReentrantLock` when I need timeout, interrupt, or multiple conditions."         |
| Forgetting `finally { lock.unlock(); }` in written code | Demonstrates unfamiliarity with the critical contract                     | "The first rule of explicit locks: always unlock in a finally block."                                                                                        |
| "`new ReentrantLock(true)` is always the safe choice"   | Fair mode has lower throughput; implies naïve understanding               | "Fair mode prevents starvation but reduces throughput. I use it only when I can measure starvation in production."                                           |
| Not knowing what `tryLock()` returns when it fails      | Signals read-only knowledge, no hands-on experience                       | "`tryLock()` returns `false` if the lock is unavailable — the caller must handle that case explicitly, typically with a fallback."                           |
| Confusing `Condition` with `Object.wait()/notify()`     | Conflates different abstractions                                          | "`Condition` is the explicit-lock equivalent of `wait()/notify()`, but you can have multiple per lock — one per logical state — which is the key advantage." |
| "I would just use `synchronized` for performance"       | Misleads — both are fast for uncontended locks                            | "Both are fast uncontended. The choice is about semantics: timeout, interrupt, and multiple conditions — not raw speed."                                     |

**RED FLAG DETECTOR:**

| Red Flag Answer                                          | Signal It Sends                      | Correct Framing                                                                                                       |
| -------------------------------------------------------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| "I always use `ReentrantLock` instead of `synchronized`" | No engineering judgment; hammer/nail | "I choose based on whether I need timeout, interrupt, or multiple conditions — otherwise `synchronized` is cleaner"   |
| "It's thread-safe so it's fine"                          | No failure-mode awareness            | "Thread-safe means correct, not deadlock-proof — you must still handle lock release in finally"                       |
| "I've never seen it deadlock"                            | Limited production exposure          | "The deadlock I always guard against is missing `finally { lock.unlock(); }` — one NPE and everything freezes"        |
| "It depends" [with no follow-up]                         | Avoidance                            | "It depends on whether I need timed acquisition, interruptibility, or multiple conditions — let me walk through each" |

**DANGEROUS OVER-SIMPLIFICATIONS:**

| Oversimplification                      | What It Misses                                                     | Better Answer                                                                                               |
| --------------------------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| "Fair mode is safer"                    | Throughput cost; starvation is uncommon in most services           | "Fair mode prevents starvation at a throughput cost — measure first, switch if starvation is confirmed"     |
| "Just use `synchronized` — it's faster" | Ignores cases requiring timeout or interrupt                       | "For simple blocks yes, but for bounded queues or load-shedding, you need `tryLock` or multiple conditions" |
| "Use `AtomicInteger` for concurrency"   | Solves single-variable atomicity, not multi-step critical sections | "`AtomicInteger` is for single-variable CAS; for multi-step critical sections you still need a lock"        |

---

### 🗣️ Follow-Up Questions to Ask the Interviewer

- "What kind of contention pattern does the system have — is it read-heavy or write-heavy?"
  _Why this signals depth:_ Shows you know `ReadWriteLock` or `StampedLock` may be more appropriate and that you do not default to one lock type for everything.

- "How many threads would typically contend for this lock?"
  _Why this signals depth:_ High contention changes the analysis — AQS queue overhead and park/unpark cost become significant, and the argument for lock-free structures or finer-grained locking strengthens.

- "Is tail latency or aggregate throughput more important for this service?"
  _Why this signals depth:_ Directly maps to the fair vs unfair decision — you signal that you make this choice deliberately, not by convention.

- "Is the critical section holding the lock for microseconds or milliseconds?"
  _Why this signals depth:_ Lock duration affects strategy — long-held locks need timeout mechanisms and the cost of missed `tryLock` calls matters; short sections may not need `ReentrantLock` at all.

---

### 🏛️ System Design Connections

**Where `ReentrantLock` appears in system design:**

- Bounded blocking queue implementation — the core of `ArrayBlockingQueue`
- In-memory connection pool with timed acquisition and graceful 503 fallback
- In-process rate limiter with per-bucket locks
- Thread-safe cache with separate read (`StampedLock`) and write (`ReentrantLock`) paths

**How to bring it up naturally:**
"For this bounded queue I would use `ReentrantLock` with two conditions — `notFull` for producers, `notEmpty` for consumers. This avoids the `notifyAll()` thundering herd you get with `synchronized`, where every insert wakes consumers who may not be able to proceed."

**Design decisions it influences:**

- Lock granularity — one coarse lock on the whole structure vs multiple fine-grained locks protecting independent state (lock splitting)
- Fair vs unfair mode — throughput optimisation vs tail latency / starvation guarantees
- Whether to escalate to `ReadWriteLock` or `StampedLock` if profiling shows read contention

**Example system design question:**
"Design a thread-safe bounded blocking queue with blocking `put()` and `take()` operations."

_How `ReentrantLock` fits the answer:_
One `ReentrantLock`, two `Condition` objects. `put()` calls `notFull.await()` when the buffer is full, then calls `notEmpty.signal()` after inserting. `take()` calls `notEmpty.await()` when empty, then calls `notFull.signal()` after removing. This is the exact internal design of `java.util.concurrent.ArrayBlockingQueue`.

**6-STEP FRAMEWORK:**

```
Step 1 CLARIFY   Is this in-process or distributed?
                 What are the capacity and throughput requirements?

Step 2 ESTIMATE  At 10,000 RPS with 100 producer threads:
                 contention is medium; lock overhead is measurable

Step 3 HLD       Producer threads → [Bounded Queue] → Consumer threads

Step 4 DEEP DIVE ReentrantLock + two Conditions for producer/consumer
                 signalling; capacity enforced in put()/take()

Step 5 ALT       LinkedBlockingQueue (uses two separate locks — head
                 and tail — for higher throughput); Disruptor for
                 ultra-low-latency ring buffer without locking

Step 6 EVOLUTION At 100× scale, the in-process queue is no longer the
                 bottleneck — move to a distributed queue (Kafka/SQS)
                 and eliminate the in-process synchronisation entirely
```

**STAFF / PRINCIPAL THINKING:**

- Cost: The lock itself is cheap; the cost is the critical section — minimise time held
- Org: If multiple services or teams consume from this queue, make it an external system, not an in-process lock
- Migration: Move from `synchronized` to `ReentrantLock` only when profiling identifies a specific need; avoid premature complexity
- Simplification: `ArrayBlockingQueue` already wraps this correctly — do not re-implement unless you need custom behaviour

**LLD GUIDANCE:**

```
interface BlockingQueue<T> {
    void put(T item) throws InterruptedException;
    T take()        throws InterruptedException;
    int size();
}

class BoundedBlockingQueue<T> implements BlockingQueue<T> {
    private final ReentrantLock lock  = new ReentrantLock();
    private final Condition notFull   = lock.newCondition();
    private final Condition notEmpty  = lock.newCondition();
    private final Queue<T>  buffer    = new ArrayDeque<>();
    private final int       capacity;
    ...
}
```

Key design decisions:

1. Why `ReentrantLock` not `synchronized`: need two separate conditions
2. Why `ArrayDeque` not `LinkedList`: lower memory overhead, better cache locality
3. Why `await()` in a loop (`while (!condition) { cond.await(); }`): spurious wakeup guard

---

### 📊 Whiteboard / Diagram

```
┌─────────────────────────────────────────────────────────┐
│           REENTRANTLOCK — AQS STATE MACHINE             │
│                                                         │
│  Thread A calls lock.lock()                             │
│  ┌──────────────────────────────────────────────┐       │
│  │ AQS State: owner=null → CAS → owner=A        │       │
│  │             holdCount: 0   →   1             │       │
│  └──────────────────────────────────────────────┘       │
│                                                         │
│  Thread A calls lock.lock() again (re-entrant)          │
│  ┌──────────────────────────────────────────────┐       │
│  │ AQS: owner=A (same thread) → holdCount: 2   │       │
│  └──────────────────────────────────────────────┘       │
│                                                         │
│  Thread B calls lock.lock() ─ BLOCKS                    │
│  ┌──────────────────────────────────────────────┐       │
│  │ AQS Wait Queue: [B] ← parked                │       │
│  └──────────────────────────────────────────────┘       │
│                                                         │
│  Thread A calls unlock() × 2 → holdCount=0             │
│  ┌──────────────────────────────────────────────┐       │
│  │ AQS: owner=null → unpark(B)                 │       │
│  │ (unfair: new arrival C may win first)        │       │
│  └──────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────┘
```

_What to say while drawing:_
"I will draw the hold count because that is what 'reentrant' actually means at the implementation level. Thread A acquires — count goes to 1. It calls `lock()` again in a nested method — count goes to 2. Only when count reaches zero does AQS unpark the next waiting thread. In unfair mode — the default — a newly arriving thread can cut ahead of B. That is the throughput advantage and the starvation risk, in the same mechanism."

---

### 📌 Quick Reference Card

```
┌──────────────────────────────────────────────────────────┐
│ ONE-LINE DEF  │ Explicit lock: adds timeout + interrupt  │
│               │ + multiple conditions to synchronized    │
├───────────────┼──────────────────────────────────────────┤
│ PROBLEM       │ synchronized: no timeout, one condition, │
│               │ cannot be interrupted while waiting      │
├───────────────┼──────────────────────────────────────────┤
│ KEY INSIGHT   │ "Reentrant" is not the point — tryLock   │
│               │ and multiple Conditions are the point    │
├───────────────┼──────────────────────────────────────────┤
│ USE WHEN      │ Need timeout, interrupt, or separate     │
│               │ producer/consumer condition queues       │
├───────────────┼──────────────────────────────────────────┤
│ AVOID WHEN    │ Simple blocks (use synchronized);        │
│               │ read-heavy workloads (use StampedLock)   │
├───────────────┼──────────────────────────────────────────┤
│ TRADE-OFF     │ More powerful vs more error-prone —      │
│               │ missing finally = permanent deadlock     │
├───────────────┼──────────────────────────────────────────┤
│ VS ALTERNATIVE│ vs StampedLock: no optimistic reads;     │
│               │ vs synchronized: must unlock explicitly  │
├───────────────┼──────────────────────────────────────────┤
│ INTERVIEW TIP │ Mention the finally rule and fair/unfair │
│               │ trade-off unprompted — signals depth     │
└──────────────────────────────────────────────────────────┘
```

---

### 🚀 Last-Minute Prep

**Remember these 3 things:**

1. Always `unlock()` in a `finally` block — missing this is the #1 production bug with explicit locks
2. "Reentrant" = same thread can re-acquire; hold count must hit zero before other threads proceed
3. `tryLock` and multiple `Condition` objects are the two features that justify choosing this over `synchronized`

**If you blank on the definition, say:**

> "It is Java's explicit locking API — think `synchronized` but with more controls. You can time out waiting for the lock, be interrupted while waiting, and have multiple named wait queues. Let me walk through when I would choose one over the other..."

**The example that always works:**
Bounded blocking queue: one `ReentrantLock`, two conditions — `notFull` for producers, `notEmpty` for consumers. Producers call `notFull.await()` when the buffer is full; consumers signal `notFull` when they remove. This is exactly how `ArrayBlockingQueue` is implemented in the JDK.

**One sentence that signals depth:**

> "The `finally { lock.unlock(); }` rule is non-negotiable — one unhandled exception without it and every thread waiting on that lock is stuck permanently."

**RECOVERY LANGUAGE TEMPLATES:**

- Blank on AQS internals: "Let me reason from the state machine level — AQS maintains a CAS-protected owner field and a FIFO queue of parked threads..."
- Pushback "synchronized is just as good": "For simple critical sections, absolutely — it is cleaner and the JIT optimises it well. The specific cases where I reach for `ReentrantLock` are timeout, interrupt, and multiple conditions..."

**CONFIDENCE UNDER PRESSURE:**
When pushed: "That is a fair challenge — in most services `synchronized` is sufficient. I reach for `ReentrantLock` specifically when at least one of these is required: timed acquisition, interrupt response, or multiple condition queues."

---

### 🗣️ Spoken Answer Templates

**TYPE 1 (Definition):**

> "`ReentrantLock` is Java's explicit mutual exclusion lock. It exists because `synchronized` has no timeout, cannot be interrupted, and supports only one condition. A concrete example: `lock.tryLock(200, MILLISECONDS)` for load shedding. The key thing most people miss: it is called 'reentrant' but so is `synchronized` — what actually matters is `tryLock` and multiple `Condition` objects."

**TYPE 2 (Mechanism):**

> "When you call `lock.lock()`, AQS checks if any thread owns the lock. If not, it CAS-sets the owner to the calling thread with hold count 1. If the same thread calls `lock()` again — reentrant — hold count becomes 2. To release, call `unlock()` once per `lock()` call. When count hits zero, AQS unparks the next thread in the wait queue. When this goes wrong you see threads stuck in `AQS.acquire()` — diagnose with `jstack <pid>`."

**TYPE 3 (Comparison):**

> "Both `ReentrantLock` and `synchronized` give you mutual exclusion with re-entrancy. The difference is `ReentrantLock` adds three things: timeout via `tryLock`, interruptibility via `lockInterruptibly`, and multiple conditions via `newCondition`. I choose `ReentrantLock` when I need at least one of those three. I choose `synchronized` when I need none of them — it is simpler and the JIT can optimise it more aggressively."

**TYPE 4 (Scenario):**

> "For a bounded blocking queue I would use one `ReentrantLock` with two conditions — `notFull` and `notEmpty`. Producers call `notFull.await()` when the buffer is full, then signal `notEmpty` after inserting. Consumers call `notEmpty.await()` when empty, then signal `notFull` after removing. The failure mode I watch for: forgetting `finally { lock.unlock(); }` — one exception and everything deadlocks."

**TYPE 5 (Debugging):**

> "The most common failure I have seen is missing `finally { lock.unlock(); }`. Symptom: threads accumulating in BLOCKED state, service gradually unresponsive, no error logs. Diagnose: `jstack <pid>` — look for threads all WAITING on the same `ReentrantLock` address with an owner that has terminated. Fix: add `finally { lock.unlock(); }`. Prevent: Spotbugs rule that flags `lock()` not guarded by finally."

**TYPE 6 (Deep Dive):**

> "`ReentrantLock` is built on `AbstractQueuedSynchronizer` because Doug Lea designed a single reusable synchronisation primitive — CAS state + parked thread queue — that powers `ReentrantLock`, `Semaphore`, and `CountDownLatch` without duplication. The trade-off: explicit, so missing `finally` is a permanent deadlock. The fundamental limitation: still a blocking lock — at very high read-to-write ratios, `StampedLock` with optimistic reads achieves zero lock overhead for reads entirely."

**INTERVIEWER TYPE ADAPTATION:**

| Interviewer Type | Lead With                                                                                                                                               | Tone                 |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| Technical panel  | AQS internals, `jstack` diagnosis, `async-profiler`                                                                                                     | Precise terminology  |
| Hiring manager   | "Prevents thread exhaustion — services shed load gracefully instead of queuing forever"                                                                 | Outcome language     |
| Bar raiser       | "I would first ask whether shared mutable state can be eliminated — `ReentrantLock` is the right tool for bounded queues, but a design smell elsewhere" | Intellectual honesty |
| Peer engineer    | "The pattern I keep reaching for is two conditions on one lock — have you seen the same thing in your codebase?"                                        | Collaborative        |

---

### 🔄 Elite Learning Loop

**The 8-Step Cycle:** READ → RECALL → COMPARE → EXPLAIN → DIAGRAM → APPLY → MOCK → TEACH

**Weakness → Strength progression:**

| State  | Symptom                              | Action                                                             |
| ------ | ------------------------------------ | ------------------------------------------------------------------ |
| WEAK   | Cannot define without notes          | Write "ReentrantLock vs synchronized" from memory three times      |
| OKAY   | Can define, cannot explain mechanism | Draw the AQS hold count diagram on paper until fluent              |
| SOLID  | Can explain, no examples             | Trace `ArrayBlockingQueue` source — it uses exactly this pattern   |
| STRONG | Example ready, no trade-offs         | Answer "When would you NOT use ReentrantLock?" aloud, timed 90 sec |
| ELITE  | Trade-offs ready, not fluent aloud   | Explain to a colleague; find gaps in your spoken explanation       |

**Technical Fluency:** Explain `ReentrantLock` to each audience, timed:

| Audience        | Time  | Key Points                                                                             |
| --------------- | ----- | -------------------------------------------------------------------------------------- |
| Junior engineer | 2 min | `synchronized` but explicit; timeout; always unlock in finally                         |
| Product manager | 1 min | "A bathroom lock that lets you knock and walk away after 30 seconds if no one answers" |
| Senior engineer | 3 min | Three use cases + AQS hold count + fair/unfair trade-off                               |
| Staff engineer  | 5 min | Full answer including when NOT to use it, `StampedLock` escalation, profiling          |

---

### 📅 Deliberate Recall Schedule

**Day 1:**
What is `ReentrantLock` in one sentence? What problem does it solve that `synchronized` cannot? How does the hold count work? Key trade-off vs `synchronized`? One failure mode?

**Day 3:**
Walk through `lock.lock()` step-by-step in AQS terms. When would you NOT use `ReentrantLock`? What is the closest alternative and deciding factor? Describe the missing-`finally` production scenario.

**Day 7:**
Explain `ReentrantLock` to a junior engineer (2 min, aloud). System design scenario where it appears naturally. Name 3 interview red flags for this topic.

**Day 14:**
Draw the AQS hold count diagram from memory. Give the 3-minute senior answer with the production story. What question would a bar raiser ask that most candidates fail?

**Day 30:**
Give the full 5-minute staff answer unprompted. At 10,000 concurrent threads, what breaks? Compare `ReentrantLock` to `StampedLock` in 90 seconds.

**Day 60:**
Teach `ReentrantLock` to another engineer (15 min, no notes). Answer all 6 question types cold. Rate your confidence on all 5 signals 1-5:
🧠 Technical Depth / 🏭 Production Experience / ⚖️ Trade-off Thinking / 💬 Communication Clarity / 🎯 Engineering Judgment

**Pressure Drill:** Set 2-minute timer. Speak aloud. Rotate per session:

- "Tell me about a time `ReentrantLock` caused a production problem."
- "I prefer `synchronized`. Why would you use `ReentrantLock` instead?"
- "Explain `ReentrantLock` assuming I have never heard of Java locking."
- "What would you change about `ReentrantLock` if you designed it today?"
- "How does `ReentrantLock` behave when 10,000 threads contend for it simultaneously?"
