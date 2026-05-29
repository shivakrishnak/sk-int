---
layout: default
title: "Java Concurrency - META Patterns"
parent: "Java Concurrency"
grand_parent: "SK Interview"
nav_order: 16
permalink: /java-concurrency/meta-patterns/
---

# Java Concurrency - META Patterns

## Concurrency Mental Models

### 🎯 Model Answer

**30 seconds:**
> Concurrency mental models are the frameworks experienced engineers use
> to reason about concurrent behavior without running the code. Key models:
> (1) Happens-before: "does write A happen-before read B?" - if yes,
> B sees A's value. (2) Visibility vs atomicity: separate bugs, separate
> fixes. (3) Ownership: which thread "owns" a resource determines whether
> locking is needed. (4) Contention model: shared-nothing vs shared-state
> determines throughput limits. Having these models lets you identify
> concurrency bugs by reading code rather than reproducing race conditions.

**3 minutes (Senior):**
> The happens-before model is the foundation: a write is safe if HB
> guarantees ensure any reading thread sees the write. Bugs are of two
> types - visibility (thread doesn't see latest value) and atomicity
> (read-modify-write not atomic). Visibility fix: volatile or synchronized.
> Atomicity fix: synchronized, Lock, or atomic operations. Conflating
> these leads to over-engineering (synchronizing when volatile suffices)
> or under-engineering (using volatile when atomicity is needed).
>
> The ownership model: identify which thread "owns" a piece of data.
> Data owned by one thread needs no synchronization (thread-confined).
> Data with shared read access needs visibility (volatile / final).
> Data with shared write access needs synchronization for both visibility
> AND atomicity.
>
> The cost model: each synchronization mechanism has a cost. volatile
> read/write: ~4ns (memory barrier). synchronized (uncontended): ~8ns.
> synchronized (contended): microseconds to milliseconds depending on
> wait time. Lock-free CAS (uncontended): ~4ns. Design to avoid the
> contended case.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Discuss the "Confinement, Immutability, Synchronization"
design triangle, the happens-before closure (transitive), and how to
apply formal reasoning tools (TLA+, Java Pathfinder) to validate mental
models for critical code.

*Adapting down:* "A mental model is a shortcut for correct reasoning.
Instead of running the code 10,000 times to find a race, you ask: 'Is
there a guarantee that write A will be visible before read B?' If no
guarantee exists: there is a potential bug."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about mental models for concurrency
reasoning - the frameworks that let you read concurrent code and know
if it is correct."

**(2) First principles:** "From first principles: concurrent bugs are
invisible (they require specific timing to manifest). Mental models
give you a rule-based way to detect them without running the code."

**(3) Bridge:** "A concurrency mental model is like a building code
for concurrent programs. Just as a code inspector can look at a blueprint
and identify that the staircase violates fire safety rules without
lighting a fire, a good mental model lets you look at code and identify
race conditions without running it."

---

### 📘 Concept Explanation

**Mental model 1 - Happens-Before:**
For every write W and read R in a concurrent program, ask:
"Is W happens-before R?" If yes: R is guaranteed to see W's value.
If no: R may see W's value, a stale value, or a partially updated value.

HB relationships in Java:
- Thread.start(): all writes before start() HB all actions in the new thread
- Thread.join(): all actions in the thread HB actions after join()
- synchronized: release HB acquire on the same monitor
- volatile: write HB subsequent read of same variable
- AtomicXxx CAS: successful CAS HB subsequent read of same variable

**Mental model 2 - Visibility vs Atomicity:**
```
Visibility bug: thread reads a stale value because no HB exists.
Fix: volatile (for single-field visibility)

Atomicity bug: compound read-modify-write is not atomic.
Fix: synchronized, Lock, or atomic operation

COMMON MISTAKE: using volatile for atomicity
// BROKEN: volatile gives visibility but not atomicity
volatile int counter = 0;
void increment() { counter++; } // read-modify-write NOT atomic
// Fix: AtomicInteger or synchronized
```

**Mental model 3 - Thread ownership:**
```
Thread-confined: data only accessed by one thread
  -> No synchronization needed
  -> Example: local variables, ThreadLocal state

Shared read-only (immutable): data written once, never modified after publication
  -> Need: safe publication (volatile or final for the reference)
  -> Example: List.of(), config objects created at startup

Shared mutable: data read and written by multiple threads
  -> Need: both visibility AND atomicity guarantees
  -> Example: shared cache, counters, session state
```

**Mental model 4 - Contention topology:**
```
Shared-nothing: each thread has its own data
  -> Throughput scales linearly with threads
  -> Best for: stateless request handlers, functional pipelines

Shared-read: many threads read, few write
  -> ReadWriteLock, volatile, CopyOnWrite
  -> Throughput scales for reads

Shared-write (hot spot): many threads write the same location
  -> Lock contention bottleneck
  -> Fix: partition (lock striping) or aggregate (LongAdder)
```

---

### 💻 Code Example

> **Code walkthrough:** The BAD example shows two common mental model
> failures: conflating visibility with atomicity, and assuming thread
> start implies HB with the thread's work. The GOOD example applies
> the HB mental model to identify the correct synchronization.

```java
// BAD: visibility fix applied to an atomicity problem
volatile int counter = 0;    // volatile: only visibility fix
void increment() { counter++; } // STILL BROKEN: ++ is read-modify-write
// Mental model: visibility is satisfied (volatile HB), but atomicity is not.
// Two threads both read 5, both write 6, net increment = 1 not 2.
```

```java
// GOOD: apply the correct mental model
// Ask: is this a visibility issue or an atomicity issue?
// counter++ = read, modify, write = atomicity issue
AtomicInteger counter = new AtomicInteger(0);
void increment() { counter.incrementAndGet(); } // atomic CAS

// If only one thread writes (ownership model: single writer):
volatile int counter = 0; // volatile is sufficient for single-writer
void writerIncrement() { counter++; } // OK: only ONE thread writes
int readerGet() { return counter; } // OK: volatile read
```

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> When I look at concurrent code, I ask two questions: (1) Is there a
> happens-before guarantee between the write and the read? If not:
> visibility bug. (2) Is a compound operation (like read-modify-write)
> done atomically? If not: atomicity bug. Visibility fix: volatile.
> Atomicity fix: synchronized or AtomicXxx. I also think about ownership:
> if only one thread ever touches a variable, it needs no synchronization.

---

**Senior / Staff (5+ years):**
> My primary model is happens-before. Before adding any synchronization,
> I ask: "Does a HB chain already exist?" (Thread.start, volatile, sync
> release-acquire). If yes: no additional sync needed. If no: add the
> minimum synchronization to create the required HB. Then I classify the
> bug: visibility (add volatile/final) or atomicity (add sync/atomic).
> I also apply the ownership model at design time: design thread confinement
> into the architecture (command pattern, actor model, thread-local state)
> to minimize shared mutable state. The less shared mutable state, the
> fewer synchronization decisions you need to get right.

---

### ⚠️ Common Misconceptions

**Misconception 1: "synchronized on different objects doesn't protect the same data."**
Two methods both modifying `this.count`: if method A uses `synchronized(lockA)`
and method B uses `synchronized(lockB)`, they are NOT mutually exclusive.
Both methods can run simultaneously. The lock must be the SAME object.

**Misconception 2: "Thread.sleep() provides a happens-before."**
`Thread.sleep()` provides NO happens-before guarantee to other threads.
It only pauses the current thread. Any code that "works" due to sleep
timing is coincidence, not correctness. Use actual synchronization.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Visibility assumed from non-HB initialization.**
Symptom: newly started thread doesn't see a value written before `Thread.start()`.
Actually impossible (start() creates HB), but common confusion leads
to unnecessary volatile. Worse: assuming write before thread creation
is visible WITHOUT using Thread.start() (e.g., thread started by a pool).
```java
// SUBTLE: pre-creating tasks and submitting to a pool
Runnable task = () -> System.out.println(config); // config read here
config = loadConfig();  // written AFTER creating the runnable
executor.submit(task);  // PROBLEM: task captures reference to config variable
// The HB from executor.submit() covers the state AT SUBMIT TIME
// Writing config before submit(): write HB submit HB task execution = SAFE
// Writing config after submit(): NO HB guarantee
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| HB mental model | 2-3 minutes |
| Visibility vs atomicity | 2-3 minutes |
| Ownership model | 2-3 minutes |
| Contention topology | 2-3 minutes |
| Applying the models | 3-4 minutes |
| Common mistakes caught | 2-3 minutes |
| Teaching concurrency | 2-3 minutes |

---

**Q1 (HB mental model): Walk through applying the happens-before
model to a specific code review.**

A: Code review scenario:
```java
class Config {
    private Map<String, String> settings;

    void reload() {
        settings = loadFromDisk(); // write to settings
    }

    String get(String key) {
        return settings.get(key);  // read from settings
    }
}
```

Apply HB mental model:
1. Is there a HB between `settings = loadFromDisk()` and `settings.get(key)`?
   If reload() and get() are called from different threads: NO HB exists.
   The field `settings` is neither volatile nor accessed in a synchronized block.
2. Bug type: visibility. Thread calling get() may see the old Map reference.
3. Fix: `volatile Map<String, String> settings;`
   Volatile write HB volatile read.

Now check atomicity:
4. Is the write compound? `settings = loadFromDisk()` is a single reference
   assignment to a volatile field. Atomic in Java (reference writes are atomic).
5. Is the Map itself safely accessible? After the volatile write, all threads
   see the new Map reference. But is the Map itself thread-safe?
   If loadFromDisk() returns a new Map that is never modified after assignment:
   safe (effectively immutable after publication).
6. Correct fix: `private volatile Map<String, String> settings;` + ensure
   the new Map is not modified after being assigned to settings.

*What separates good from great:* The HB chain must extend through
all relevant operations. A volatile write creates HB with a SUBSEQUENT
volatile read of the SAME variable. Any reads of OTHER variables done
before the volatile read are NOT covered. The "volatile piggybacking"
technique: by reading a volatile variable, you pick up all happens-before
relationships from the last write to that volatile, including non-volatile
writes that preceded that volatile write.

---

**Q2 (Visibility vs atomicity): How do you distinguish between a
visibility bug and an atomicity bug?**

A:

**Visibility bug:** A thread reads a stale (old) value of a variable
because no happens-before chain ensures the write is visible.
```java
boolean stop = false;        // no volatile
void run() {
    while (!stop) { /* work */ }  // may never see stop=true
}
void requestStop() { stop = true; } // write not guaranteed visible
```
Test for visibility bug: the operation is a single read or single write
(not a compound operation). Adding volatile fixes it.

**Atomicity bug:** A compound operation (read-modify-write, check-then-act)
is not executed as a single unit. Multiple operations with windows for
other threads to intervene.
```java
volatile int count = 0;       // volatile: visibility OK
void increment() { count++; } // atomicity BROKEN: 3 steps
// read count, add 1, write count - another thread can interleave
```
Test for atomicity bug: the operation requires multiple steps to complete
(read then write, check then act, compare then update). Volatile alone
does NOT fix atomicity bugs.

**Fix matrix:**
| Bug type | Fix |
|---|---|
| Visibility only (single write, single read) | volatile or synchronized |
| Atomicity only (no visibility issue - single thread, or checked) | synchronized or AtomicXxx |
| Both visibility and atomicity | synchronized or AtomicXxx (NOT just volatile) |

*What separates good from great:* Many engineers add synchronized when
volatile would suffice, adding unnecessary lock contention. Conversely,
many engineers add volatile when atomicity is needed, creating a subtle
race that only manifests under concurrent access. The question is always:
"Is this a single-step operation or a multi-step operation?" Single step:
volatile. Multi-step: synchronized or atomic.

---

**Q3 (Ownership model): How do you apply thread ownership to reduce
the synchronization surface area?**

A: Thread ownership is a design strategy: minimize shared mutable state
by confining mutable state to single-thread ownership.

**Confinement patterns:**

Stack confinement: local variables are automatically thread-confined.
```java
void processRequest(Request req) {
    Map<String, Object> context = new HashMap<>(); // stack-confined
    context.put("userId", req.userId);
    // context never escapes this method -> no synchronization needed
}
```

Thread-local confinement:
```java
// Pattern: each thread has its own SimpleDateFormat (not thread-safe)
ThreadLocal<SimpleDateFormat> formatter = ThreadLocal.withInitial(
    () -> new SimpleDateFormat("yyyy-MM-dd"));
// Each thread gets its own instance -> no sharing -> no synchronization
```

Actor-style confinement: one thread owns each entity.
```java
// Account is owned by one thread (its "actor" thread)
// Mutations only from the owning thread -> no locks on Account
class AccountActor {
    private final Account account; // NOT shared - owned by this thread
    private final BlockingQueue<Transaction> inbox;
    void run() {
        while (true) {
            Transaction t = inbox.take();
            account.apply(t); // single-threaded - no lock needed
        }
    }
}
```

Design rule: start with confinement. Only introduce sharing when
the design requires it. Each sharing decision requires a synchronization
decision. Minimize sharing to minimize synchronization complexity.

*What separates good from great:* ThreadLocal is widely used but has
a subtle danger in thread pools: the thread is reused across requests,
so `ThreadLocal` state persists from request to request. Always
clean up ThreadLocal state at the end of a request:
```java
try { doWork(); }
finally { threadLocal.remove(); }
```
Without this: ThreadLocal accumulates state from previous requests,
causing data leaks or security issues (user A's data visible to user B).

---

**Q4 (Contention topology): How does the contention topology of a
system determine its concurrency architecture?**

A: Contention topology describes where threads compete for shared
resources. It drives the concurrency model choice:

**Shared-nothing (best case):**
Each thread processes its own data. No shared mutable state in the
hot path.
```
Thread 1: processes Order 101 (no shared state)
Thread 2: processes Order 102 (no shared state)
Throughput: linear with threads (Amdahl S=0%)
```
Achieve this by: partitioning work by key (Kafka partition model),
thread-local state, event-driven isolation.

**Shared read (read-heavy):**
Many threads read the same data; writes are rare.
```
Thread 1-100: read config (very frequent)
Config loader: writes config (once per minute)
```
Solution: volatile reference (visibility), ReadWriteLock (many readers),
CopyOnWrite structures.

**Shared write hot spot (worst case):**
Many threads write the same location.
```
Thread 1-100: increment the same counter (request counter)
Throughput: O(1/N) - decreases with threads!
```
Solution: LongAdder (stripe), partition (each thread's own counter +
periodic aggregation), message passing.

**Mixed (typical):**
Hot path: shared-nothing or shared-read.
Cold path: shared write (aggregation, reporting).
Move shared writes off the hot path.

*What separates good from great:* The architecture should match the
contention topology. A Kafka consumer that processes messages in
parallel naturally gets shared-nothing topology (each partition handled
by one thread). Breaking this with a shared counter is a common mistake.
The counter should use LongAdder or be moved to a periodic aggregation
thread.

---

**Q5 (Applying the models): Use all four mental models to analyze a
piece of concurrent code.**

A: Code under analysis:
```java
class SessionCache {
    Map<String, Session> sessions = new HashMap<>();

    Session getOrCreate(String userId) {
        Session s = sessions.get(userId);    // Step 1: check
        if (s == null) {
            s = new Session(userId);         // Step 2: create
            sessions.put(userId, s);         // Step 3: put
        }
        return s;
    }
}
```

**Model 1 - Happens-Before:**
No HB relationship on `sessions`. Multiple threads can read and write
the HashMap concurrently. HashMap is not thread-safe. HB gap: no sync.

**Model 2 - Visibility vs Atomicity:**
Both issues. Visibility: threads may read stale Map contents.
Atomicity: check-then-act (Step 1 then Step 3) is not atomic.
Two threads may both see null for the same userId and both create a
new Session.

**Model 3 - Ownership:**
`sessions` is shared mutable state (multiple threads read and write).
Not thread-confined, not immutable. Requires synchronization.

**Model 4 - Contention Topology:**
This is a shared-write pattern (multiple threads update the map).
Not the worst case (not all threads writing the same key), but
still shared mutable.

**Fix:**
```java
class SessionCache {
    // ConcurrentHashMap: thread-safe with atomic computeIfAbsent
    ConcurrentHashMap<String, Session> sessions = new ConcurrentHashMap<>();

    Session getOrCreate(String userId) {
        // computeIfAbsent: atomic check-and-create (CAS internally)
        return sessions.computeIfAbsent(userId, Session::new);
    }
}
```

*What separates good from great:* The four mental models converge on
the same diagnosis from different angles. HB shows the gap. Visibility/
atomicity classification shows what kind of fix is needed. Ownership
shows the architectural issue. Contention topology guides the choice
of fix (ConcurrentHashMap is appropriate for a shared cache with
moderate write rate; for high-write scenarios, consider local caches
with periodic sync or Caffeine with expiry).

---

**Q6 (Common mistakes caught): What are the top 3 concurrency mistakes
that good mental models catch immediately?**

A:

**Mistake 1: Thread.sleep() as synchronization.**
```java
void init() {
    startBackgroundThread();
    Thread.sleep(1000); // "wait for thread to finish"
    useResult(); // assumes thread is done
}
```
Mental model catch: Thread.sleep() creates NO happens-before. If the
thread takes > 1000ms, useResult() reads stale data.
Correct: CountDownLatch, CompletableFuture, or Thread.join().

**Mistake 2: Checking size() then operating (check-then-act).**
```java
if (!queue.isEmpty()) {
    Object item = queue.poll(); // item may be null!
}
```
Mental model catch: atomicity bug. isEmpty() and poll() are two
separate operations. Another thread may poll() between isEmpty()
and poll(). Use `Object item = queue.poll(); if (item != null) ...`

**Mistake 3: Publishing mutable object through volatile reference.**
```java
volatile List<String> list = new ArrayList<>();
// Thread A:
list.add("item"); // modifies the list object

// Thread B:
for (String s : list) { ... } // ConcurrentModificationException!
```
Mental model catch: volatile protects the REFERENCE (list field),
not the OBJECT contents. list.add() is not volatile-protected.
Fix: use Collections.unmodifiableList() and reassign the volatile
reference with a new List each update (copy-on-write pattern).

---

**Q7 (Teaching concurrency): How do you explain concurrency mental
models to a junior engineer?**

A:

**Start with the fundamental question:**
"Will thread B see thread A's write?" 
If you can answer this, you understand concurrent correctness.

**The traffic light metaphor:**
- Synchronized = traffic light: all cars stop, one direction goes
- Volatile = one-way street sign: tells you what direction traffic
  flows (visibility), but two cars can still collide (atomicity)
- CAS = self-checkout: try to scan and pay; if someone grabbed your
  item, start over

**The three rules:**
1. If only ONE thread writes (and others only read): volatile is enough.
2. If MULTIPLE threads write to the same data: use synchronized or atomic ops.
3. If data is ONLY within one thread: no sync needed.

**The test:**
"Can two threads be in this code at the same time?" (atomicity)
"Can one thread not see what another thread wrote?" (visibility)
Yes to either: need synchronization.

*What separates good from great:* Teaching concurrency effectively
means making the invisible visible. Have junior engineers annotate
every shared field with: who writes it, who reads it, what synchronization
exists. When a shared field has NO synchronization annotation, that's
a flag to investigate. This makes the default assumption "this needs
synchronization" until proven otherwise, rather than the dangerous
"this is fine until it breaks."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: no visual component that adds value over the mental model descriptions)*

---

---

## Thread Safety Decision Framework

### 🎯 Model Answer

**30 seconds:**
> The thread safety decision framework is a step-by-step process:
> (1) Is this data accessed by multiple threads? If not: no action.
> (2) Is the data read-only after publication? If yes: make it final/
> immutable. (3) Is it a single variable with a single writer? If yes:
> volatile. (4) Is it a compound operation (multiple steps)? If yes:
> synchronized or AtomicXxx. (5) Is contention high? If yes: lock-free
> structures (LongAdder, ConcurrentHashMap) or lock striping.

**3 minutes (Senior):**
> The decision tree has five questions and five outcomes. Start with
> the question that eliminates the most options: "Is this accessed by
> multiple threads?" If no: nothing needed. This eliminates most cases
> (most variables are method-local).
>
> For truly shared data: "Is it ever written after safe publication?"
> If no (effectively immutable): ensure safe publication (volatile
> final field, or return from synchronized method) then no further sync.
>
> For shared mutable: classify the access pattern. Single-field read/
> write with single writer: volatile. Compound operations: synchronized
> or atomic. High contention: concurrent data structures. Cross-object
> invariants: single lock covering all related state.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Discuss applying the framework to entire subsystems
(not just single variables), the "minimally synchronized interface"
design pattern, and how to document thread safety contracts using
`@ThreadSafe`, `@NotThreadSafe`, `@Immutable` annotations from
`net.jcip.annotations`.

*Adapting down:* "The framework is a checklist. Each question reduces
the set of correct solutions. The goal: always use the weakest
(cheapest) synchronization that is still correct."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking for a systematic framework to decide
what thread safety mechanism to use for a given piece of code."

**(2) First principles:** "From first principles: thread safety is
needed only when (a) data is shared across threads AND (b) at least
one thread writes. The framework systematically checks these conditions
and matches the simplest correct solution."

**(3) Bridge:** "The framework is like a diagnostic questionnaire at
a doctor's office. Each question narrows down the diagnosis, and the
treatment (synchronization mechanism) follows from the diagnosis."

---

### 📘 Concept Explanation

**Decision Tree:**

```
Q1: Is this data accessed by multiple threads?
  NO  -> No synchronization needed (thread-confined)
  YES -> Q2

Q2: Is the data effectively immutable after construction?
  YES -> Ensure safe publication (final field or volatile reference)
         Then: no further synchronization
  NO  -> Q3

Q3: Is it a simple single-field value (no compound operations)?
  YES (single write, single read):
       -> volatile (for visibility between writer and readers)
  NO (compound: read-modify-write, check-then-act):
       -> Q4

Q4: Is contention expected to be low to medium?
  YES -> synchronized block (simple, correct, low overhead uncontended)
         or Lock (if advanced features needed)
  NO (high contention): -> Q5

Q5: What is the access pattern?
  COUNTER / ACCUMULATOR -> LongAdder or AtomicLong
  MAP -> ConcurrentHashMap
  LIST (rare writes) -> CopyOnWriteArrayList
  QUEUE -> LinkedBlockingQueue or ConcurrentLinkedQueue
  REFERENCE SWAP -> AtomicReference
  MULTIPLE FIELDS (must be consistent) -> single synchronized block
                                          covering all fields
```

**When to use each mechanism:**

| Mechanism | Use When |
|---|---|
| Nothing | Thread-confined, stack-local, ThreadLocal |
| final | Written once (constructor), read many times |
| volatile | One writer, many readers, single field |
| synchronized | Compound ops, multiple fields, simple critical section |
| ReentrantLock | Need tryLock, interruptible, fairness |
| ReadWriteLock | Read-heavy, writes infrequent |
| AtomicInteger | Single numeric counter with CAS |
| LongAdder | High-contention counter |
| ConcurrentHashMap | Shared map, concurrent reads and writes |
| CopyOnWriteArrayList | List with rare writes, frequent reads |

---

### 💻 Code Example

> **Code walkthrough:** The BAD example applies synchronized everywhere
> without analysis. The GOOD example walks through the decision tree
> to apply the minimum correct synchronization for each field.

```java
// BAD: synchronize everything out of caution
class UserProfile {
    private String name;       // written once at construction
    private int loginCount;    // incremented by request threads
    private String sessionId;  // written/read by session threads
    private List<Role> roles;  // read-only after initial load

    // Over-synchronized: every field treated as high-contention mutable
    synchronized String getName() { return name; }
    synchronized void incrementLogin() { loginCount++; }
    synchronized String getSessionId() { return sessionId; }
    synchronized List<Role> getRoles() { return roles; }
}
```

```java
// GOOD: apply decision tree per field
class UserProfile {
    // name: written once in constructor -> final, safe publication
    private final String name;

    // loginCount: incremented by multiple threads -> atomic
    private final AtomicInteger loginCount = new AtomicInteger(0);

    // sessionId: written and read by multiple threads, single field
    //            one writer at a time -> volatile
    private volatile String sessionId;

    // roles: written once, read many times (effectively immutable after init)
    //        final reference, unmodifiable list
    private final List<Role> roles;

    UserProfile(String name, List<Role> roles) {
        this.name = name;
        this.roles = Collections.unmodifiableList(new ArrayList<>(roles));
        // Safe publication: constructor completes before reference escapes
    }

    String getName() { return name; } // no sync: final
    void recordLogin() { loginCount.incrementAndGet(); } // atomic
    String getSessionId() { return sessionId; } // volatile read
    List<Role> getRoles() { return roles; } // no sync: immutable
}
```

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> My decision process: first, is this data shared across threads? If
> no, nothing to do. If yes, is it read-only? Then I use final or
> make it immutable. If it's mutable, I check if it's a single value
> or a compound operation. Single value: volatile. Compound: synchronized
> or AtomicXxx. I always prefer the weakest (simplest) synchronization
> that is still correct.

---

**Senior / Staff (5+ years):**
> The framework starts with ownership analysis at design time, not
> just at the individual field level. I ask: which threads access which
> components? Can I partition the design to minimize sharing? For data
> that must be shared, I apply the decision tree: final, volatile,
> atomic, or synchronized in order of simplicity. I annotate all
> classes with `@ThreadSafe`, `@NotThreadSafe`, or `@Immutable` to
> document the contract. For high-contention scenarios, I replace
> synchronized with concurrent data structures (ConcurrentHashMap,
> LongAdder) measured with JMH before and after.

---

### ⚠️ Common Misconceptions

**Misconception 1: "synchronized on every method = thread-safe class."**
Synchronizing every method ensures INDIVIDUAL method atomicity but
NOT compound invariants. If two methods must run together to maintain
an invariant:
```java
synchronized boolean isEmpty() { return size == 0; }
synchronized void add(T item) { /* add item */ }

// STILL NOT THREAD-SAFE for this pattern:
if (!set.isEmpty()) { set.add(item); } // check-then-act: not atomic!
```
Thread-safe classes require client-side locking or explicit atomic
compound operations.

**Misconception 2: "Immutability requires making everything final."**
Effective immutability: the object's observable state does not change
after safe publication - even if internal fields are not final
(e.g., lazy initialization with double-checked locking and volatile).
What matters: no mutations visible to external callers after the object
is published.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Wrong level of the decision tree applied.**
Symptom: data corruption under concurrent access that only appears
under load (hard to reproduce).
Cause: volatile applied to a compound operation, or synchronized applied
but on wrong object.
Diagnosis: JFR thread contention events; enable `-ea` assertions with
invariant checks in critical sections.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Walking through the framework | 3-4 minutes |
| Final vs volatile | 2-3 minutes |
| When synchronized is not enough | 2-3 minutes |
| High-contention decisions | 2-3 minutes |
| Applying to a real class | 3-4 minutes |
| Documenting thread safety | 2-3 minutes |
| When NOT to synchronize | 2-3 minutes |

---

**Q1 (Walking through the framework): Apply the decision framework to
decide thread safety for a shopping cart class.**

A:
```java
class ShoppingCart {
    String userId;          // set once on creation, never changed
    List<CartItem> items;   // added/removed by user requests
    BigDecimal discount;    // calculated on demand, cached
    int viewCount;          // incremented on each page view
}
```

Walk through each field:

**userId:**
Q1: Multiple threads read, never write after construction? YES (write-once)
Q2: Effectively immutable? YES
Decision: `final String userId` - no sync needed

**items:**
Q1: Multiple threads? YES (concurrent requests from same user session)
Q2: Mutable after construction? YES (add/remove items)
Q3: Compound? YES (read-add-check-return sequences)
Q4: Contention level? Low-medium (user's own cart, bounded concurrency)
Decision: `synchronized` on items or use `CopyOnWriteArrayList` if
reads dominate

**discount:**
Q1: Multiple threads? YES
Q2: Mutable? YES (recalculated when items change)
Q3: Compound? YES (compute if absent pattern)
Decision: synchronized getter with lazy init, or `volatile` if single
recalculation thread, or recalculate on each call (if cheap)

**viewCount:**
Q1: Multiple threads? YES (any request increments it)
Q3: Compound? YES (read-increment-write)
Q4: Contention? Medium-high (every page view)
Decision: `AtomicInteger viewCount` (lock-free, sufficient)

Result: one field per synchronization decision, minimum necessary.

*What separates good from great:* The framework produces DIFFERENT
answers for DIFFERENT fields. A common mistake: applying the same
synchronization to all fields. This either under-protects (volatile
on compound ops) or over-synchronizes (synchronized on effectively
immutable fields). Spending 30 seconds at the framework for each field
during code review prevents months of debugging.

---

**Q2 (Final vs volatile): When does `final` replace the need for
`volatile`?**

A: `final` provides the strongest guarantee: once written in the
constructor and the constructor completes normally, ALL threads see
the correct value WITHOUT any synchronization, PROVIDED the reference
to the object is safely published.

Safe publication means: the reference is published via:
- A final field of another object
- A volatile field
- A synchronized block
- Thread.start() (all writes before start() are visible to the new thread)

```java
class Config {
    final String host;    // safe: final, visible after construction
    final int port;       // safe: final
    final List<String> allowedIPs; // final reference, but list contents?

    Config(String h, int p, List<String> ips) {
        host = h;
        port = p;
        // CORRECT: defensive copy + unmodifiable
        allowedIPs = List.copyOf(ips); // immutable list
    }
}

// Safe publication:
volatile Config config = new Config(...);
// Any thread reading 'config' volatile field will see all final fields
// correctly initialized
```

**Final limitation:**
`final` only guarantees the value written in the constructor. If the
class has a mutable field (even if it's final) - like a final `List`
whose elements change - the list contents are not protected by final.

```java
class BadConfig {
    final List<String> items = new ArrayList<>(); // MUTABLE list!
    // final means 'items' always points to the same ArrayList
    // but items.add() and items.remove() are NOT thread-safe
}
```

*What separates good from great:* The "final field + safe publication"
pattern is the most efficient possible read path: no synchronization
on reads at all. Libraries like Guava's ImmutableList are designed
to be final-safe: truly immutable after construction, safe to read
from any thread after safe publication.

---

**Q3 (When synchronized is not enough): Describe scenarios where
synchronized doesn't provide full thread safety.**

A:

**Scenario 1: client-side compound operations.**
```java
// Thread-safe class:
ConcurrentHashMap<String, Integer> map;

// Client code (NOT thread-safe despite thread-safe map):
Integer value = map.get(key);
if (value == null) {
    map.put(key, 1);  // race: two threads may both see null!
}
// Fix: map.computeIfAbsent(key, k -> 1)
```

**Scenario 2: conditional check-then-act.**
```java
synchronized Vector<String> list; // thread-safe vector

// Client code (NOT thread-safe):
if (!list.isEmpty()) {
    String last = list.get(list.size() - 1); // IndexOutOfBoundsException!
}
// Another thread may clear() the list between isEmpty() and get()
```

**Scenario 3: multiple fields must be consistent together.**
```java
class Counter {
    volatile int value = 0;
    volatile int max = 0;

    void record(int v) {
        value = v;   // write 1
        max = Math.max(max, v); // write 2 (not atomic with write 1)
    }
    // A reader may see new value but old max (inconsistent)
    // Fix: synchronized on both writes, or AtomicReference<int[]>
}
```

*What separates good from great:* Synchronized makes INDIVIDUAL methods
atomic, but multi-method sequences are only atomic if the caller holds
the lock for the entire sequence. Java's documentation for
`java.util.concurrent.ConcurrentHashMap` explicitly states: compound
actions like "put-if-absent" require the built-in `computeIfAbsent()`.
Thread-safe collection classes document which compound operations are
atomically supported.

---

**Q4 (High-contention decisions): How do you choose between LongAdder
and AtomicLong for a counter?**

A: Decision:
- Single read after write (or infrequent sum): either is fine
- Frequent increment, infrequent sum: LongAdder
- Increment AND frequent compare-and-set: AtomicLong

**LongAdder internals:**
- Striped: N cells, each hashed by thread ID
- Increment: CAS on one cell (likely uncontended)
- sum(): traverse all cells (approximate, not atomic with increments)

**AtomicLong:**
- Single cell: all threads CAS on the same value
- Under high contention: CAS storm (throughput degrades)
- sum() / get(): exact current value, atomic read

**Benchmark (8 threads, 1M increments each):**
```
AtomicLong:  ~90M ops/sec (decreases with threads)
LongAdder:   ~400M ops/sec (stable with threads)
```

**Rule of thumb:**
- Rate meters (ops per second): LongAdder
- Monotonic counter with check (queue depth, rate limiter): AtomicLong
- Total accumulation (byte count, event count): LongAdder + call sum() periodically

*What separates good from great:* LongAdder's sum() is not synchronized
with increment() calls. During a sum() call, increments to individual
cells may be happening simultaneously. The sum() result represents
"approximately what the count was at some point during the iteration."
For rate meters and approximate totals, this is fine. For exact balance
counts or distributed locks, use AtomicLong or synchronized.

---

**Q5 (Applying to a real class): Apply the thread safety decision
framework to Spring's @Component beans.**

A: Spring-managed @Component beans are SINGLETONS by default: one
instance shared by ALL request threads. This makes thread safety
critical.

Decision per field type:

**Injected dependencies (@Autowired fields):**
```java
@Autowired UserRepository userRepo; // set once by Spring, then read-only
```
Effectively final after Spring initialization. No sync needed.
BUT: must ensure Spring initialization is thread-safe (it is by
application context startup ordering).

**Configuration values (@Value):**
```java
@Value("${api.timeout}") int timeoutMs; // set once at startup
```
Effectively final. No sync needed.

**Instance state (accumulate across requests):**
```java
int requestCount; // incremented by all requests
```
Q3: compound (read-increment-write) -> AtomicInteger.

**Caches:**
```java
Map<String, User> userCache = new HashMap<>(); // written and read by requests
```
Q3: compound (get-then-put) -> ConcurrentHashMap with computeIfAbsent().

**Thread-local request context:**
```java
ThreadLocal<RequestContext> context = ThreadLocal.withInitial(() -> null);
```
Thread-confined. But: pool thread reuse -> MUST call remove() at
request end.

**Rule for Spring beans:**
Inject collaborators as final fields (constructor injection).
State that accumulates across requests: AtomicXxx or ConcurrentXxx.
Per-request state: method-local or ThreadLocal with cleanup.

*What separates good from great:* Constructor injection (vs field
injection) enforces immutability: fields can be final, making the
dependency thread-safe by construction. Field injection with
@Autowired forces the field to be non-final, tempting engineers to
treat it as mutable.

---

**Q6 (Documenting thread safety): How do you document thread safety
contracts?**

A: Thread safety documentation prevents future engineers from misusing
a class.

**Annotations from jcip-annotations:**
```java
@ThreadSafe     // class is safe for concurrent use
@NotThreadSafe  // class is NOT safe for concurrent use
@Immutable      // class is immutable (also implies @ThreadSafe)
@GuardedBy("lockName") // field guarded by this lock
```

**Example:**
```java
@ThreadSafe
public class BoundedCounter {
    @GuardedBy("this")
    private int count = 0;
    private final int max;

    public synchronized boolean increment() {
        if (count >= max) return false;
        count++;
        return true;
    }

    public synchronized int get() { return count; }
}
```

**Javadoc contract:**
```java
/**
 * Thread-safe lazy configuration loader.
 * Configuration is loaded once on first access and never modified.
 * Safe for concurrent reads after initialization.
 *
 * <p>Thread-safety: all public methods are thread-safe.
 * Internal state is protected by the instance monitor lock.
 */
@ThreadSafe
public class ConfigLoader { ... }
```

*What separates good from great:* `@GuardedBy("lockName")` is the
most actionable annotation. It tells code reviewers: "this field MUST
only be accessed while holding 'lockName'." Tools like ErrorProne and
FindBugs can automatically verify @GuardedBy constraints, catching
unsynchronized access at compile or static analysis time.

---

**Q7 (When NOT to synchronize): When is it correct to NOT synchronize
even for shared data?**

A:

**Case 1: Racy-but-ok initialization.**
Java guarantees that a class's static fields are initialized exactly
once by the class loader (with HB guarantees). No explicit sync needed
for effectively-immutable static final fields.
```java
// Initialized exactly once by class loader - thread-safe by JLS:
static final List<String> ALLOWED = List.of("READ", "WRITE");
```

**Case 2: Publishing once, reading many (safe publication).**
If an object is written to a volatile field exactly once:
```java
volatile Config config = null;
// Later, exactly one writer:
config = new Config(...); // safe publication
// All readers see fully initialized Config via volatile HB
```

**Case 3: Statistical or non-critical data.**
For some metrics (e.g., a hit counter where approximate counts are
acceptable), a non-synchronized read-modify-write is acceptable.
```java
long hitCount = 0; // no sync
void recordHit() { hitCount++; } // racy - may miss some increments
// Acceptable if approximate reporting is sufficient
```
This is a deliberate trade-off, not an oversight. Document it.

**Case 4: Single-threaded entry point.**
Configuration loaded at startup before any request threads start:
```java
@PostConstruct
void init() { config = loadConfig(); } // Spring calls this on main thread
// After init(), all request threads start and read config
// Thread.start() HB ensures config is visible
```

*What separates good from great:* The decision NOT to synchronize
should be as deliberate as the decision TO synchronize. Document why
no sync is needed (effectively immutable, thread-confined, happens-before
already established). "I didn't synchronize because I didn't think
about it" vs. "I didn't synchronize because this is thread-confined
and the HB chain from Thread.start() covers initialization."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: decision tree adequately described in the Concept Explanation section)*

---

---

## Production Concurrency Incident Patterns

### 🎯 Model Answer

**30 seconds:**
> Production concurrency incidents follow repeating patterns. The top 5:
> (1) Thread pool exhaustion - all threads stuck in slow I/O operations.
> (2) Deadlock - two threads hold locks the other needs.
> (3) Thundering herd - a cache expiry triggers many threads to rebuild
> simultaneously.
> (4) Thread leak - threads created but never terminated.
> (5) Context not cleared - ThreadLocal data from one request leaks to
> the next. Recognition patterns come from thread dumps, metrics, and
> logs.

**3 minutes (Senior):**
> Each pattern has a diagnostic signature. Thread pool exhaustion:
> all pool threads RUNNABLE in the same slow method (multiple dumps
> identical). Deadlock: "Found one Java-level deadlock" in thread dump
> or health check reporting deadlocked threads. Thundering herd: CPU
> spike when a cache TTL expires, many threads rebuilding the same cache
> entry (lock contention on cache key). Thread leak: `jstack` shows
> ever-growing list of named threads; JVM heap also grows from thread
> stacks.
>
> Prevention is better than diagnosis. Checklists: always use bounded
> thread pools with names and metrics. Never leave ThreadLocal without
> cleanup in finally blocks. Use circuit breakers on all external calls
> (prevents pool exhaustion). Use lock-checked cache loading
> (computeIfAbsent) to prevent thundering herd.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Discuss SRE-level incident runbooks for each pattern,
correlation between thread dump states and Prometheus metrics (thread
pool queue depth, active count), and how chaos engineering (chaos monkey,
toxiproxy) tests resilience against these patterns proactively.

*Adapting down:* "Production concurrency incidents are like factory
accidents. Thread pool exhaustion: all workers stuck waiting for a
delivery that never comes. Deadlock: two workers each holding one
half of the tool set. Thundering herd: fire drill triggers and everyone
rushes to the same exit at once."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the common patterns of concurrency
failures in production and how to diagnose and prevent them."

**(2) First principles:** "From first principles: concurrent systems
fail when the coordination between threads breaks down. Each failure
pattern is a specific breakdown mode: exhaustion, deadlock, herd effect,
leak, or data corruption."

**(3) Bridge:** "Production concurrency incidents are like specific
machine failure modes. A car mechanic recognizes 'engine knocking'
as a specific pattern with a specific fix. An experienced engineer
recognizes 'thread pool exhaustion' from its metrics signature the
same way."

---

### 📘 Concept Explanation

**Pattern 1 - Thread Pool Exhaustion:**
All pool threads occupied by slow operations. New tasks queue indefinitely.
Signature: all pool threads BLOCKED or RUNNABLE in same slow method.
Pool queue depth growing. Downstream latency spike.

**Pattern 2 - Deadlock:**
Two or more threads each hold a lock the other needs. All involved
threads blocked permanently.
Signature: "Found one Java-level deadlock" in thread dump. Health
check reports deadlock. Service appears frozen but CPU is low.

**Pattern 3 - Thundering Herd:**
Many threads simultaneously attempt a slow operation (cache rebuild,
DB query) because a cached result expired at the same moment.
Signature: CPU spike on cache TTL boundaries. Lock contention burst
on cache key. Many identical slow DB queries in APM.

**Pattern 4 - Thread Leak:**
Threads created but never shut down. JVM slowly accumulates threads.
Signature: `jstack` thread count growing over time. JVM heap grows
(thread stacks are in JVM heap). Eventually: `OutOfMemoryError:
unable to create new native thread`.

**Pattern 5 - Context Not Cleared (ThreadLocal Leak):**
ThreadLocal set for request A not cleared. Thread pool reuses the
thread for request B. Request B reads stale data from request A's
ThreadLocal.
Signature: intermittent wrong user data visible. Security incidents
where user A sees user B's data.

---

### 💻 Code Example

> **Code walkthrough:** The BAD example shows a ThreadLocal that is set
> but never cleared. The GOOD example uses try/finally to guarantee
> cleanup, preventing context leakage to the next request.

```java
// BAD: ThreadLocal without cleanup
class RequestFilter {
    static final ThreadLocal<String> userId = new ThreadLocal<>();

    void before(Request req) {
        userId.set(req.getUserId()); // set for this request
    }

    void after() {
        // MISSING: userId.remove()
        // Pool thread now carries this userId into the NEXT request!
    }
}
// Second request: userId.get() returns previous request's userId!
// Security bug: user B sees user A's data
```

```java
// GOOD: always remove ThreadLocal in finally
class RequestFilter {
    static final ThreadLocal<String> userId = new ThreadLocal<>();

    void doFilter(Request req, FilterChain chain) throws Exception {
        userId.set(req.getUserId());
        try {
            chain.doFilter(req); // all downstream code can read userId
        } finally {
            userId.remove(); // GUARANTEED: always cleaned up even on exception
        }
    }

    static String current() { return userId.get(); }
}
```

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The most common issues I watch for: thread pool exhaustion (all pool
> threads stuck waiting for slow I/O) and ThreadLocal leaks (not calling
> remove() after a request). For pool exhaustion: check thread dump for
> all pool threads doing the same slow operation. For ThreadLocal leaks:
> always use try/finally to call remove(). Deadlocks are the other major
> one - check the thread dump for "Found one Java-level deadlock."

---

**Senior / Staff (5+ years):**
> I operate from a pattern library. Thread pool exhaustion: if P99
> latency spikes and CPU drops while thread pool queue grows, the pool
> is exhausted. Diagnosis: take 3 thread dumps. If all pool threads
> show the same stack (blocked on the same slow operation), that's the
> root cause. Fix: circuit breaker on the slow dependency, or isolate
> into its own pool.
>
> Thundering herd: cache TTL expiry causes latency spike because all
> threads rebuild simultaneously. Fix: probabilistic early expiration
> (refresh before expiry if load approaches 100%). Or: single-flight
> mutex (computeIfAbsent ensures only ONE thread rebuilds per key).
>
> Thread leak: `jstack` thread count > expected. Check for threads
> that are RUNNABLE but in unexpected states, or threads that are
> WAITING indefinitely (never-signaled callbacks).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Thread pool exhaustion = need more threads."**
The root cause is usually that threads are BLOCKED on slow dependencies
(database timeout, external service hanging). Adding more threads just
delays the exhaustion by seconds. Fix the slow dependency (circuit
breaker, timeout, fallback) or isolate it to its own pool.

**Misconception 2: "Deadlock only happens with explicit locks."**
Deadlocks occur with any mutual exclusion: database row locks (two
transactions locking rows in different orders), ReentrantLock, and
thread pool tasks waiting for each other (pool starvation deadlock:
a task submits a sub-task to the same pool that is already full).

---

### 🚨 Failure Modes and Diagnosis

**All five patterns are failure modes. Diagnosis commands:**

```bash
# Thread pool exhaustion:
jstack <pid> | grep "pool-name" | grep "State:" | sort | uniq -c

# Deadlock:
jstack <pid> | grep -A 20 "deadlock"

# Thread count growth:
jstack <pid> | grep "^\"" | wc -l  # monitor over time

# ThreadLocal leaks (indirect: check for wrong data in responses):
grep "threadLocal" src/**/*.java | grep -v "\.remove()"
# Any ThreadLocal.set() without corresponding .remove() = risk
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Pool exhaustion diagnosis | 3-4 minutes |
| Deadlock root cause | 2-3 minutes |
| Thundering herd | 3-4 minutes |
| Thread leak detection | 2-3 minutes |
| ThreadLocal leak | 2-3 minutes |
| Prevention checklist | 2-3 minutes |
| Real incident story | 3-4 minutes |

---

**Q1 (Pool exhaustion diagnosis): Walk through diagnosing and fixing
thread pool exhaustion.**

A: Incident: service P99 latency goes from 50ms to 10s. CPU drops.
Error rate rises.

**Step 1: Check metrics.**
Thread pool active count: 20/20 (all threads busy).
Thread pool queue: 500 (500 tasks waiting).
Downstream database latency: 25s per call (DB is slow).

**Step 2: Take thread dumps.**
```bash
for i in 1 2 3; do jstack <pid> > dump-$i.txt; sleep 5; done
grep -A 10 "pool-thread" dump-1.txt | grep "State:"
```
Result: all 20 threads RUNNABLE in `executeQuery()` waiting for DB.

**Step 3: Identify root cause.**
DB query timeout is set to 30s. Pool size is 20. With 20 threads
each blocking for 25s, new requests queue until one thread frees.
At 100 req/s: backlog grows at 80 req/s.

**Step 4: Immediate mitigation.**
- Deploy circuit breaker: if DB P99 > 5s, open circuit, return cached
  or degraded response.
- OR: reduce DB query timeout to 2s (fail fast, allow thread to free).

**Step 5: Long-term fix.**
- Separate DB pool from API pool (isolation).
- Add circuit breaker with fallback.
- Cache common query results.
- Tune DB query performance.

*What separates good from great:* The thread pool is a symptom; the
slow DB is the cause. Adding more threads (20 -> 40) just delays the
exhaustion by 5 minutes. The correct fix: circuit breaker to stop
adding more tasks to the pool when the DB is degraded, allowing
existing threads to complete and the pool to drain.

---

**Q2 (Deadlock root cause): Explain the most common deadlock root
causes in Java services.**

A:

**Cause 1: Lock ordering inconsistency.**
Thread A: lock(account1), then lock(account2).
Thread B: lock(account2), then lock(account1).
Under concurrent execution: circular wait.
Fix: always acquire locks in a canonical order (e.g., sorted by ID).

**Cause 2: Holding a lock while calling external code.**
```java
synchronized void processWithCallback() {
    doWork();
    callback.onComplete(); // callback tries to acquire ANOTHER lock!
    // If callback code acquires a lock held by another thread
    // that's waiting for THIS synchronized block: deadlock
}
```
Fix: release the lock before calling external code or callbacks.

**Cause 3: Thread pool starvation deadlock.**
```java
// Pool size: 5 threads
ExecutorService pool = Executors.newFixedThreadPool(5);

// Task submits a sub-task to the SAME pool:
pool.submit(() -> {
    // ... does work ...
    Future<?> subtask = pool.submit(() -> helper()); // submits to same pool
    subtask.get(); // waits for subtask
    // If all 5 threads are doing this, all 5 are waiting for their
    // subtasks, which are in the queue, never getting a thread!
});
```
Fix: use a separate pool for sub-tasks, or use ForkJoinPool work-stealing.

*What separates good from great:* Thread pool starvation deadlock is
especially insidious because no "Found deadlock" message appears in
thread dump (no locked monitors). All threads are in WAITING state
in `Future.get()`. Diagnosis: all pool threads waiting for Futures
submitted to the same pool.

---

**Q3 (Thundering herd): How do you prevent thundering herd on a
cached resource?**

A: Thundering herd: a cache entry expires, all threads simultaneously
try to rebuild it.

```
Normal: cache hit -> 1ms response
Expiry: 500 threads simultaneously -> 500 DB queries -> DB overloaded
```

Prevention strategies:

**Strategy 1: Single-flight (compute once, all wait):**
```java
// ConcurrentHashMap.computeIfAbsent is atomic:
// Only ONE thread runs the function, all others wait
cache.computeIfAbsent(key, k -> expensiveLoad(k));
// First thread that wins the CAS computes the value;
// other threads see the same key in the map and wait for it
```

**Strategy 2: Probabilistic early expiration:**
```java
// Don't wait until expiry - start refreshing when probability rises:
double expiresIn = cache.ttlRemaining(key);
double totalTtl = cache.originalTtl(key);
// If elapsed > 90% of TTL: 10% chance of refreshing now
if (expiresIn / totalTtl < 0.1 && Math.random() < 0.1) {
    scheduleRefresh(key); // only ~10% of requests trigger refresh
}
```

**Strategy 3: Staggered TTLs:**
Instead of exact TTL, add jitter:
```java
int baseTtl = 300; // 5 minutes
int jitter = (int)(Math.random() * 30); // 0-30 seconds jitter
cache.put(key, value, baseTtl + jitter);
// Different entries expire at slightly different times -> no mass expiry
```

**Strategy 4: Cache refresh in background:**
Serve stale while refreshing asynchronously. Stale-while-revalidate.

*What separates good from great:* computeIfAbsent is the standard
first fix. It ensures only ONE thread builds the cache value per key.
But if the build takes 10 seconds, ALL threads for that key block for
10 seconds. For very slow builds, the background refresh (stale-while-
revalidate) pattern is better: serve stale data immediately, refresh
in a background thread.

---

**Q4 (Thread leak detection): How do you detect and fix a thread leak?**

A: Thread leak symptoms:
- JVM thread count grows continuously (visible in JConsole, JFR, or jstack)
- JVM heap grows (thread stacks are on-heap)
- Eventually: `OutOfMemoryError: unable to create new native thread`

Detection:
```bash
# Monitor thread count over time:
while true; do
    COUNT=$(jstack <pid> 2>/dev/null | grep "^\"" | wc -l)
    echo "$(date): $COUNT threads"
    sleep 60
done

# If count grows monotonically: thread leak
```

Common causes:
1. Thread created in a loop without termination check:
```java
// BAD: new thread per request
void handleRequest(Request req) {
    new Thread(() -> processAsync(req)).start(); // never tracked, never joined
}
// 1000 req/min = 1000 new threads/min -> leak
```

2. ExecutorService not shut down:
```java
// BAD: new executor per request, never shut down
ExecutorService executor = Executors.newFixedThreadPool(5);
executor.submit(task);
// executor.shutdown() never called -> 5 threads leak per request
```

3. ThreadPoolExecutor keepAlive set to 0 for non-core threads but
   core threads never idle (core threads don't terminate by default).

Fix: use shared executors. For truly task-specific executors:
```java
ExecutorService exec = Executors.newFixedThreadPool(5);
try {
    exec.submit(task).get();
} finally {
    exec.shutdown(); // always shut down
}
```

*What separates good from great:* Virtual threads in Java 21 change
the economics: creating 1M virtual threads is fine. But monitoring
virtual thread count is still important - an unbounded virtual thread
executor can still exhaust JVM memory if virtual threads accumulate
indefinitely. Monitor with `ManagementFactory.getThreadMXBean().getThreadCount()`.

---

**Q5 (ThreadLocal leak): Walk through a production incident caused
by ThreadLocal not being cleared.**

A: Incident: users occasionally see another user's profile data in
their response. Customer complaints. Security incident.

Investigation:
- Code review finds: `ThreadLocal<UserContext>` set in request filter.
- Request filter was updated to not call `remove()` (introduced in a refactor).
- Thread pool reuses threads. Thread serving request A carries A's context.
- Thread pool recycles thread for request B.
- B's code calls `UserContext.get()` -> returns A's context!
- B's response contains A's data.

The key pattern:
```java
// BAD:
static ThreadLocal<UserContext> ctx = new ThreadLocal<>();
filter.doFilter: ctx.set(userContext);
// forgot: ctx.remove()
```

Fix and prevention:
```java
// GOOD: always remove in finally
void doFilter(Request req, FilterChain chain) {
    ctx.set(extractContext(req));
    try {
        chain.doFilter(req);
    } finally {
        ctx.remove(); // ALWAYS, even on exception
    }
}

// BETTER: use InheritableThreadLocal only if intentional inheritance is needed
// Default to ThreadLocal (not InheritableThreadLocal)
```

Automated detection: lint rule or PR checklist:
"Every `ThreadLocal.set()` must be followed by `ThreadLocal.remove()`
in a finally block."

*What separates good from great:* The security impact of ThreadLocal
leaks is underappreciated. Leaking userId from request A to request B
can: expose user A's sensitive data to user B, bypass authorization
checks (request B runs with request A's permissions), or corrupt
financial calculations (request B uses request A's pricing context).
ThreadLocal leaks are security vulnerabilities in multi-tenant systems,
not just performance bugs.

---

**Q6 (Prevention checklist): What is your production concurrency
incident prevention checklist?**

A: Pre-deployment checklist for concurrent code:

**Thread pools:**
- [ ] Named with descriptive names (`payment-processor`, not `pool-3`)
- [ ] Bounded queue (not `new LinkedBlockingQueue()` unbounded)
- [ ] Rejection policy explicit and appropriate
- [ ] Metrics exposed (active count, queue depth, completed count)
- [ ] Pool size appropriate for workload type (CPU vs I/O)

**Locks:**
- [ ] Lock acquisition order documented and consistent across methods
- [ ] No external calls (callbacks, I/O) while holding a lock
- [ ] ReentrantLock.unlock() always in finally block
- [ ] No lock held across thread pool task submission to same pool

**ThreadLocal:**
- [ ] Every ThreadLocal.set() has corresponding remove() in finally
- [ ] No InheritableThreadLocal unless parent-child thread inheritance
  is intentionally required

**Circuit breakers:**
- [ ] Every external service call has a circuit breaker
- [ ] Every blocking call has a timeout
- [ ] Fallback defined for each circuit breaker

**Testing:**
- [ ] Stress tested with jcstress or multithreaded JUnit tests
- [ ] Thread dump analysis done on a load test run
- [ ] JFR lock contention profile reviewed

*What separates good from great:* Automate as much of this checklist
as possible. Static analysis (SpotBugs, ErrorProne) catches some patterns.
Code review templates can include the checklist. Integration tests
that submit requests concurrently (not just sequentially) catch
threading bugs before production.

---

**Q7 (Real incident story): Tell a concurrency incident story and
the lessons learned.**

A: Story pattern (template for interviews):

**Situation:** High-traffic e-commerce checkout service.

**Problem:** Deployment at 2pm caused P99 latency to increase from
50ms to 8s. Errors at 5%.

**Diagnosis (15 minutes):**
1. Metrics: CPU dropped to 20% (threads not doing work). Pool queue depth climbing.
2. Thread dump: all 50 checkout threads RUNNABLE in `InventoryService.check()`.
3. Second dump (5 seconds later): same 50 threads, SAME STACK. Stuck.
4. InventoryService logs: no response from external inventory API (timeout was 30s).

**Root cause:** The new release removed the circuit breaker on the
inventory API call (was accidentally deleted in a refactor). The
inventory service was having a slow day (secondary incident). Without
circuit breaker: all 50 threads blocked for 30s waiting for timeouts.

**Mitigation (30 minutes):**
- Redeploy previous version: circuit breaker restored.
- Alternatively: reduce inventory API timeout from 30s to 2s.

**Fix (next sprint):**
- Add circuit breaker as a mandatory code review check.
- Integration test that verifies circuit breaker is present on all
  external service calls.
- Use dependency analysis to flag refactors that remove circuit breakers.

**Lessons:**
- Circuit breakers must be tested in CI (not just deployed and hoped).
- Thread dumps should be the FIRST diagnostic step for any latency spike.
- Pool thread count = pool queue depth metric threshold should alert
  BEFORE full exhaustion (alert at 80% queue capacity).

*What separates good from great:* This type of incident repeats across
companies because circuit breakers are added reactively (after the
first outage) and then removed by accident in refactors. The systemic
fix is a lint rule or framework-level enforcement: "if you call an
external service, you MUST use a circuit breaker. PRs that remove
circuit breakers require explicit approval." Turning a one-time fix
into a structural prevention is the Staff Engineer level of incident
response.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: patterns adequately described through text; no visual component required)*
