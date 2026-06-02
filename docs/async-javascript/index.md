---
title: "Async JavaScript"
nav_order: 36
has_children: true
---

# Async JavaScript

Interview-focused deep-dive into Asynchronous and Reactive Programming
in JavaScript and TypeScript - from the event loop and Promises through
async/await, RxJS, Web Workers, Service Workers, and staff-level frontend
async architecture decisions. Every keyword entry follows Interview
Mastery Dictionary v1.0.

Covers the full spectrum from L0 orientation (why async JavaScript exists,
the event loop) through L1 Promise fundamentals and async/await, L2
advanced patterns and RxJS basics, L3 RxJS internals, Web Workers,
Service Workers, TypeScript async types, and security, L4 production
debugging (Promise leaks, event loop blocking, RxJS subscriptions), L5
architecture decisions, L6 theory, and META transferable patterns.

Includes all mandatory keyword types at L3+: anti-patterns, decision
frameworks, security patterns, production diagnostics, and failure modes.
Covers both JavaScript (ES2022+) and TypeScript where applicable.

## Files

| nav_order | File | Level | Difficulty | Keywords | Status |
|-----------|------|-------|------------|----------|--------|
| 1 | Async JavaScript - L0 Orientation.md | L0 | ★☆☆ | 3 | complete |
| 2 | Async JavaScript - L1 Promise Basics.md | L1 | ★☆☆ | 3 | complete |
| 3 | Async JavaScript - L1 Async/Await.md | L1 | ★☆☆ | 3 | complete |
| 4 | Async JavaScript - L2 Advanced Promises.md | L2 | ★★☆ | 2 | complete |
| 5 | Async JavaScript - L2 RxJS Basics.md | L2 | ★★☆ | 2 | complete |
| 6 | Async JavaScript - L3 RxJS Advanced.md | L3 | ★★☆ | 2 | complete |
| 7 | Async JavaScript - L3 Web Workers.md | L3 | ★★☆ | 2 | complete |
| 8 | Async JavaScript - L3 Service Workers.md | L3 | ★★☆ | 2 | complete |
| 9 | Async JavaScript - L3 TypeScript Async.md | L3 | ★★☆ | 2 | complete |
| 10 | Async JavaScript - L3 Security.md | L3 | ★★☆ | 2 | complete |
| 11 | Async JavaScript - L4 Promise Debugging.md | L4 | ★★★ | 1 | complete |
| 12 | Async JavaScript - L4 Event Loop Blocking.md | L4 | ★★★ | 1 | complete |
| 13 | Async JavaScript - L4 RxJS Production.md | L4 | ★★★ | 1 | complete |
| 14 | Async JavaScript - L5 Frontend Async Architecture.md | L5 | ★★★ | 1 | complete |
| 15 | Async JavaScript - L5 Reactive vs Imperative.md | L5 | ★★★ | 1 | complete |
| 16 | Async JavaScript - L6 Theory.md | L6 | ★★☆ | 2 | complete |
| 17 | Async JavaScript - META Patterns.md | META | ★☆☆ | 3 | complete |

**Total: 17 files, 33 keywords**

---

## Keyword Registry

### Async JavaScript - L0 Orientation.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Why Async JavaScript Exists | ★☆☆ | complete |
| 2 | The JavaScript Event Loop and Call Stack | ★☆☆ | complete |
| 3 | JavaScript Async Evolution: Callbacks to Async/Await | ★☆☆ | complete |

### Async JavaScript - L1 Promise Basics.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Promises Basics | ★☆☆ | complete |
| 2 | Promise States and the Microtask Queue | ★☆☆ | complete |
| 3 | Promise Chaining | ★☆☆ | complete |

### Async JavaScript - L1 Async/Await.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | async/await Syntax and Semantics | ★☆☆ | complete |
| 2 | Error Handling in Async Functions | ★☆☆ | complete |
| 3 | Promise.all vs Promise.race vs Promise.allSettled | ★☆☆ | complete |

### Async JavaScript - L2 Advanced Promises.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Advanced Promise Combinators | ★★☆ | complete |
| 2 | Generator Functions and Async Iteration | ★★☆ | complete |

### Async JavaScript - L2 RxJS Basics.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | RxJS Observables vs Promises | ★★☆ | complete |
| 2 | Core RxJS Operators | ★★☆ | complete |

### Async JavaScript - L3 RxJS Advanced.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | RxJS Subjects and Multicasting | ★★☆ | complete |
| 2 | Error Handling in RxJS Pipelines | ★★☆ | complete |

### Async JavaScript - L3 Web Workers.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Web Workers and Off-Main-Thread Processing | ★★☆ | complete |
| 2 | SharedArrayBuffer and Atomics | ★★☆ | complete |

### Async JavaScript - L3 Service Workers.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Service Workers and Async Fetch Intercepts | ★★☆ | complete |
| 2 | IndexedDB Async Patterns | ★★☆ | complete |

### Async JavaScript - L3 TypeScript Async.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | TypeScript Types for Async Code | ★★☆ | complete |
| 2 | Cancellation Patterns in JavaScript | ★★☆ | complete |

### Async JavaScript - L3 Security.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Security Risks in Async JavaScript | ★★☆ | complete |
| 2 | Safe Async Data Handling in TypeScript | ★★☆ | complete |

### Async JavaScript - L4 Promise Debugging.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Promise Memory Leaks and Debugging | ★★★ | complete |

### Async JavaScript - L4 Event Loop Blocking.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Event Loop Blocking and Performance Anti-Patterns | ★★★ | complete |

### Async JavaScript - L4 RxJS Production.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | RxJS Memory Leaks and Subscription Management | ★★★ | complete |

### Async JavaScript - L5 Frontend Async Architecture.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Frontend Async Architecture Patterns | ★★★ | complete |

### Async JavaScript - L5 Reactive vs Imperative.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Reactive vs Imperative Frontend Architecture Decision | ★★★ | complete |

### Async JavaScript - L6 Theory.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Continuation-Passing Style and the Promise Connection | ★★☆ | complete |
| 2 | Event-Driven Architecture Theory in JavaScript | ★★☆ | complete |

### Async JavaScript - META Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | Mental Models for JavaScript Async Reasoning | ★☆☆ | complete |
| 2 | Promise vs Observable Decision Framework | ★☆☆ | complete |
| 3 | Debugging Async Code: Systematic Approach | ★☆☆ | complete |
