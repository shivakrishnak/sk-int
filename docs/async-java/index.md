---
title: "Async Java"
nav_order: 32
has_children: true
---

# Async Java

Interview-focused deep-dive into Asynchronous and Reactive Programming
in Java - from CompletableFuture basics through Project Reactor, Spring
WebFlux, Virtual Threads (Project Loom), Structured Concurrency, and
staff-level reactive architecture decisions. Every keyword entry follows
Interview Mastery Dictionary v1.0.

Covers the full spectrum from L0 orientation (why async exists, the
Java async evolution) through L1 CompletableFuture fundamentals, L2
reactive streams and patterns, L3 reactor internals and modern Java async
(Virtual Threads, Structured Concurrency), L4 production failure modes
and debugging, L5 architecture decisions and migration strategy, L6
theory (CPS, Reactive Manifesto), and META transferable patterns.

Includes all mandatory keyword types at L3+: anti-patterns, decision
frameworks, security patterns, production diagnostics, and failure modes.

## Files

| nav_order | File | Level | Difficulty | Keywords | Status |
|-----------|------|-------|------------|----------|--------|
| 1 | Async Java - L0 Orientation.md | L0 | ★☆☆ | 3 | complete |
| 2 | Async Java - L1 CompletableFuture Basics.md | L1 | ★☆☆ | 3 | complete |
| 3 | Async Java - L1 CompletableFuture Patterns.md | L1 | ★☆☆ | 3 | complete |
| 4 | Async Java - L2 Reactive Streams.md | L2 | ★★☆ | 2 | complete |
| 5 | Async Java - L2 Async Patterns.md | L2 | ★★☆ | 2 | complete |
| 6 | Async Java - L3 Reactor Internals.md | L3 | ★★☆ | 2 | complete |
| 7 | Async Java - L3 Modern Java Async.md | L3 | ★★☆ | 2 | complete |
| 8 | Async Java - L3 Reactive Frameworks.md | L3 | ★★☆ | 2 | complete |
| 9 | Async Java - L3 Error Handling and Testing.md | L3 | ★★☆ | 2 | complete |
| 10 | Async Java - L3 Security.md | L3 | ★★☆ | 1 | complete |
| 11 | Async Java - L4 CF Internals.md | L4 | ★★★ | 1 | complete |
| 12 | Async Java - L4 Reactor Production.md | L4 | ★★★ | 1 | complete |
| 13 | Async Java - L4 Async Anti-Patterns.md | L4 | ★★★ | 1 | complete |
| 14 | Async Java - L5 Reactive Architecture.md | L5 | ★★★ | 1 | complete |
| 15 | Async Java - L5 Async Migration.md | L5 | ★★★ | 1 | complete |
| 16 | Async Java - L6 Theory.md | L6 | ★★☆ | 2 | complete |
| 17 | Async Java - META Patterns.md | META | ★☆☆ | 3 | complete |

**Total: 17 files, 32 keywords**

---

## Keyword Registry

### Async Java - L0 Orientation.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Why Async Programming in Java | ★☆☆ | complete |
| 2 | Java Async Evolution: Threads to Virtual Threads | ★☆☆ | complete |
| 3 | Concurrency vs Async Programming in Java | ★☆☆ | complete |

### Async Java - L1 CompletableFuture Basics.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | CompletableFuture Basics | ★☆☆ | complete |
| 2 | thenApply vs thenCompose vs thenCombine | ★☆☆ | complete |
| 3 | Future and Callable Interface | ★☆☆ | complete |

### Async Java - L1 CompletableFuture Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | CompletableFuture Error Handling | ★☆☆ | complete |
| 2 | ExecutorService and Custom Thread Pools | ★☆☆ | complete |
| 3 | CompletableFuture Completion and Cancellation | ★☆☆ | complete |

### Async Java - L2 Reactive Streams.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Reactive Streams Specification | ★★☆ | complete |
| 2 | Project Reactor Flux and Mono | ★★☆ | complete |

### Async Java - L2 Async Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Chaining and Combining CompletableFutures | ★★☆ | complete |
| 2 | Java HttpClient Async API | ★★☆ | complete |

### Async Java - L3 Reactor Internals.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Backpressure in Reactive Streams | ★★☆ | complete |
| 2 | Schedulers and Threading in Project Reactor | ★★☆ | complete |

### Async Java - L3 Modern Java Async.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Virtual Threads and Project Loom | ★★☆ | complete |
| 2 | Structured Concurrency | ★★☆ | complete |

### Async Java - L3 Reactive Frameworks.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Spring WebFlux Architecture | ★★☆ | complete |
| 2 | Reactor vs RxJava Comparison | ★★☆ | complete |

### Async Java - L3 Error Handling and Testing.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Error Handling in Reactive Pipelines | ★★☆ | complete |
| 2 | Testing Reactive and Async Code in Java | ★★☆ | complete |

### Async Java - L3 Security.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Secure Async Patterns in Java | ★★☆ | complete |

### Async Java - L4 CF Internals.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | CompletableFuture Internals and Thread Safety | ★★★ | complete |

### Async Java - L4 Reactor Production.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Reactor in Production - Debugging and Diagnostics | ★★★ | complete |

### Async Java - L4 Async Anti-Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Async Java Anti-Patterns and Dangerous Pitfalls | ★★★ | complete |

### Async Java - L5 Reactive Architecture.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Reactive vs Imperative Architecture Decision Framework | ★★★ | complete |

### Async Java - L5 Async Migration.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Migrating Blocking Java to Async and Reactive | ★★★ | complete |

### Async Java - L6 Theory.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Continuation-Passing Style and Event-Driven Theory | ★★☆ | complete |
| 2 | Reactive Manifesto and Reactive Systems Theory | ★★☆ | complete |

### Async Java - META Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | The Async Mental Model for Java Engineers | ★☆☆ | complete |
| 2 | Threading Model Trade-offs Decision Framework | ★☆☆ | complete |
| 3 | When Async Hurts: The Complexity Cliff | ★☆☆ | complete |
