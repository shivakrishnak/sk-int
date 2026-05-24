---
title: "Java Concurrency"
description: "Interview coverage for Java concurrency: threads, locks, executors, CompletableFuture, virtual threads"
tags: [interview, java, java-concurrency]
---

# Java Concurrency

Java's concurrency model - from low-level thread primitives through
the high-level java.util.concurrent package and Project Loom. Distinct
from JVM memory model fundamentals (java-jvm/) and performance
diagnostics (java-performance/).

**Interview focus:** Thread safety, lock semantics, executor patterns,
async composition, concurrent collection internals, virtual threads.

## Files

| File                                                                                                      | Level | Keywords | Status  |
| --------------------------------------------------------------------------------------------------------- | ----- | -------- | ------- |
| Java Concurrency - L0 Orientation                         | L0    | 4        | planned |
| Java Concurrency - L1 Foundations                         | L1    | 5        | planned |
| Java Concurrency - L2 Thread Coordination       | L2    | 5        | planned |
| Java Concurrency - L2 Executors                             | L2    | 5        | planned |
| Java Concurrency - L3 Lock API                             | L3    | 5        | planned |
| Java Concurrency - L3 Concurrent Collections | L3    | 5        | planned |
| Java Concurrency - L4 Diagnostics                         | L4    | 4        | planned |
| Java Concurrency - L4 Virtual Threads               | L4    | 4        | planned |
| Java Concurrency - META Patterns                           | META  | 3        | planned |

**Total: 40 keywords, 9 files**

---

## Keyword Registry

### Java Concurrency - L0 Orientation

| #   | Keyword                                                               | Difficulty | Status  |
| --- | --------------------------------------------------------------------- | ---------- | ------- |
| 1   | Why Concurrency? Parallelism, Responsiveness, and the Costs           | easy       | pending |
| 2   | CPU Caches, Memory Barriers, and Why Shared State is Hard             | easy       | pending |
| 3   | Java Concurrency Evolution: Thread to j.u.c to Project Loom           | easy       | pending |
| 4   | Concurrency Hazards: Race Conditions, Deadlocks, Starvation, Livelock | easy       | pending |

### Java Concurrency - L1 Foundations

| #   | Keyword                                                                      | Difficulty | Status  |
| --- | ---------------------------------------------------------------------------- | ---------- | ------- |
| 1   | Thread Lifecycle: NEW, RUNNABLE, BLOCKED, WAITING, TIMED_WAITING, TERMINATED | easy       | pending |
| 2   | Runnable vs Callable vs Thread: Design Choices and Composition               | easy       | pending |
| 3   | synchronized: Monitor Locks, Happens-Before, and Reentrancy                  | easy       | pending |
| 4   | volatile: Memory Visibility Without Mutual Exclusion                         | easy       | pending |
| 5   | Thread-Local Storage: ThreadLocal and InheritableThreadLocal                 | easy       | pending |

### Java Concurrency - L2 Thread Coordination

| #   | Keyword                                                              | Difficulty | Status  |
| --- | -------------------------------------------------------------------- | ---------- | ------- |
| 1   | wait(), notify(), notifyAll(): The Monitor Protocol                  | medium     | pending |
| 2   | join() and interrupt(): Thread Control and Graceful Shutdown         | medium     | pending |
| 3   | CountDownLatch, CyclicBarrier, Semaphore: High-Level Coordination    | medium     | pending |
| 4   | Atomic Variables: AtomicInteger, AtomicReference, and CAS Operations | medium     | pending |
| 5   | ThreadPoolExecutor: Core Pool, Max Pool, Queue, and Rejection Policy | medium     | pending |

### Java Concurrency - L2 Executors

| #   | Keyword                                                             | Difficulty | Status  |
| --- | ------------------------------------------------------------------- | ---------- | ------- |
| 1   | Executor Types: Fixed, Cached, Single, Scheduled - When to Use Each | medium     | pending |
| 2   | Future and Callable: Blocking for Results and Handling Exceptions   | medium     | pending |
| 3   | CompletableFuture: Composition, Error Handling, Combining Stages    | medium     | pending |
| 4   | ForkJoinPool: Work Stealing and Recursive Decomposition             | medium     | pending |
| 5   | ScheduledExecutorService: Replacing Timer and TimerTask             | medium     | pending |

### Java Concurrency - L3 Lock API

| #   | Keyword                                                             | Difficulty | Status  |
| --- | ------------------------------------------------------------------- | ---------- | ------- |
| 1   | ReentrantLock vs synchronized: Fairness, Timeout, Interruptibility  | medium     | pending |
| 2   | ReadWriteLock and StampedLock: Optimistic Reading Pattern           | medium     | pending |
| 3   | Condition Variables: Signal and Await for Fine-Grained Coordination | medium     | pending |
| 4   | AQS: AbstractQueuedSynchronizer - The Lock Implementation Backbone  | medium     | pending |
| 5   | Lock-Free Algorithms: CAS, ABA Problem, and Practical Boundaries    | medium     | pending |

### Java Concurrency - L3 Concurrent Collections

| #   | Keyword                                                              | Difficulty | Status  |
| --- | -------------------------------------------------------------------- | ---------- | ------- |
| 1   | ConcurrentHashMap: Segment-Free Concurrency and Compute Operations   | medium     | pending |
| 2   | CopyOnWriteArrayList: Iteration Safety at Mutation Cost              | medium     | pending |
| 3   | BlockingQueue: ArrayBlockingQueue, LinkedBlockingQueue, SynchronousQ | medium     | pending |
| 4   | ConcurrentLinkedQueue: Non-Blocking FIFO with CAS                    | medium     | pending |
| 5   | Concurrent Anti-Patterns: Compound Operations and Check-Then-Act     | medium     | pending |

### Java Concurrency - L4 Diagnostics

| #   | Keyword                                                              | Difficulty | Status  |
| --- | -------------------------------------------------------------------- | ---------- | ------- |
| 1   | Deadlock Detection: jstack, JFR Lock Events, Thread Dump Analysis    | hard       | pending |
| 2   | Thread Pool Starvation: Symptoms, Diagnosis, and Corrective Patterns | hard       | pending |
| 3   | False Sharing: CPU Cache Line Contention and @Contended              | hard       | pending |
| 4   | Memory Visibility Bugs: Reproducing, Diagnosing, and Fixing          | hard       | pending |

### Java Concurrency - L4 Virtual Threads

| #   | Keyword                                                               | Difficulty | Status  |
| --- | --------------------------------------------------------------------- | ---------- | ------- |
| 1   | Virtual Threads (Project Loom): Architecture and Carrier Thread Model | hard       | pending |
| 2   | Pinning: When Virtual Threads Block Carrier Threads                   | hard       | pending |
| 3   | Structured Concurrency: StructuredTaskScope and Cancellation          | hard       | pending |
| 4   | Virtual Thread Performance: Throughput Profiling and Latency          | hard       | pending |

### Java Concurrency - META Patterns

| #   | Keyword                                                                 | Difficulty | Status  |
| --- | ----------------------------------------------------------------------- | ---------- | ------- |
| 1   | Concurrency Design Patterns: Immutability, Confinement, Synchronization | hard       | pending |
| 2   | Choosing Synchronization Strategy: A Decision Framework                 | hard       | pending |
| 3   | Actor Model vs Shared-State Concurrency: Trade-off Analysis             | hard       | pending |
