---
title: "Java JVM"
nav_order: 14
has_children: true
---

# Java JVM

Interview-focused notes and concise study material for Java JVM internals,
garbage collection, JIT compilation, memory management, and production tuning.

## Files

| nav_order | File | Level | Difficulty | Keywords | Status |
|-----------|------|-------|------------|----------|--------|
| 1 | Java JVM - L0 Orientation.md | L0 | ★☆☆ | 3 | complete |
| 2 | Java JVM - L1 Fundamentals.md | L1 | ★☆☆ | 3 | complete |
| 3 | Java JVM - L2 Heap Internals.md | L2 | ★★☆ | 2 | complete |
| 4 | Java JVM - L2 GC Mechanics.md | L2 | ★★☆ | 2 | complete |
| 5 | Java JVM - L2 Tuning Basics.md | L2 | ★★☆ | 2 | complete |
| 6 | Java JVM - L3 JIT and Deopt.md | L3 | ★★☆ | 2 | complete |
| 7 | Java JVM - L3 G1 GC.md | L3 | ★★☆ | 2 | complete |
| 8 | Java JVM - L3 Metaspace.md | L3 | ★★☆ | 2 | complete |
| 9 | Java JVM - L3 Safepoints and Sync.md | L3 | ★★☆ | 2 | complete |
| 10 | Java JVM - L4 ZGC.md | L4 | ★★★ | 1 | complete |
| 11 | Java JVM - L4 Escape Analysis.md | L4 | ★★★ | 1 | complete |
| 12 | Java JVM - L4 GC Diagnostics.md | L4 | ★★★ | 1 | complete |
| 13 | Java JVM - L4 JVM Security.md | L4 | ★★★ | 1 | complete |
| 14 | Java JVM - L4 JVM Crashes.md | L4 | ★★★ | 1 | complete |
| 15 | Java JVM - L5 Capacity Planning.md | L5 | ★★★ | 1 | complete |
| 16 | Java JVM - L5 Deployment Architecture.md | L5 | ★★★ | 1 | complete |
| 17 | Java JVM - L6 Theory.md | L6 | ★★☆ | 2 | complete |
| 18 | Java JVM - META Patterns.md | META | ★☆☆ | 3 | complete |

---

## Keyword Registry

### Java JVM - L0 Orientation

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | JVM Purpose and Write-Once-Run-Anywhere | ★☆☆ | complete |
| 2 | JVM Architecture Components | ★☆☆ | complete |
| 3 | JVM Implementations: HotSpot OpenJ9 GraalVM | ★☆☆ | complete |

### Java JVM - L1 Fundamentals

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 4 | Bytecode Loading and Class Initialization | ★☆☆ | complete |
| 5 | JVM Memory Areas | ★☆☆ | complete |
| 6 | Garbage Collection Fundamentals | ★☆☆ | complete |

### Java JVM - L2 Heap Internals

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 7 | Heap Regions: Eden Survivor Old Gen | ★★☆ | complete |
| 8 | Object Layout and Memory Overhead | ★★☆ | complete |

### Java JVM - L2 GC Mechanics

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 9 | Minor GC and Major GC Mechanics | ★★☆ | complete |
| 10 | GC Roots and Object Reachability | ★★☆ | complete |

### Java JVM - L2 Tuning Basics

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 11 | JVM Startup Flags and Memory Sizing | ★★☆ | complete |
| 12 | GC Log Analysis | ★★☆ | complete |

### Java JVM - L3 JIT and Deopt

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 13 | JIT Compilation Tiers and Method Inlining | ★★☆ | complete |
| 14 | Deoptimization and Speculative Compilation | ★★☆ | complete |

### Java JVM - L3 G1 GC

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 15 | G1 GC Configuration and Region Selection | ★★☆ | complete |
| 16 | GC Pause Analysis and Tuning | ★★☆ | complete |

### Java JVM - L3 Metaspace

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 17 | Metaspace and Dynamic Class Generation | ★★☆ | complete |
| 18 | ClassLoader Memory Leaks | ★★☆ | complete |

### Java JVM - L3 Safepoints and Sync

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 19 | JVM Safepoints and Stop-the-World | ★★☆ | complete |
| 20 | JVM Synchronization Internals | ★★☆ | complete |

### Java JVM - L4 ZGC

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 21 | ZGC Architecture and Low-Latency GC | ★★★ | complete |

### Java JVM - L4 Escape Analysis

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 22 | Escape Analysis and Allocation Elision | ★★★ | complete |

### Java JVM - L4 GC Diagnostics

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 23 | GC Diagnostics with JFR and JVM Flags | ★★★ | complete |

### Java JVM - L4 JVM Security

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 24 | JVM Class Verification and Security | ★★★ | complete |

### Java JVM - L4 JVM Crashes

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 25 | JVM Crash Analysis and hs_err Logs | ★★★ | complete |

### Java JVM - L5 Capacity Planning

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 26 | JVM Sizing and Capacity Planning at Scale | ★★★ | complete |

### Java JVM - L5 Deployment Architecture

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 27 | JVM Selection and Deployment Architecture | ★★★ | complete |

### Java JVM - L6 Theory

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 28 | Garbage Collection Algorithms Theory | ★★☆ | complete |
| 29 | JIT Compiler Theory and Optimization | ★★☆ | complete |

### Java JVM - META Patterns

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 30 | JVM Performance Debugging Mental Model | ★☆☆ | complete |
| 31 | GC Selection Decision Framework | ★☆☆ | complete |
| 32 | JVM Observability and Monitoring Strategy | ★☆☆ | complete |

