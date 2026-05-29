---
layout: default
title: "Java Performance"
parent: "SK Interview"
nav_order: 11
has_children: true
permalink: /java-performance/
---

# Java Performance

JVM performance engineering: measurement, GC tuning, JIT compilation internals,
memory optimization, profiling, and production diagnostics.

## Files

| File | Level | Keywords | Status |
|------|-------|----------|--------|
| Java Performance - L0 Orientation.md | L0 | 3 | complete |
| Java Performance - L1 JVM Basics.md | L1 | 3 | complete |
| Java Performance - L1 Measurement.md | L1 | 3 | complete |
| Java Performance - L2 GC Basics.md | L2 | 2 | complete |
| Java Performance - L2 Code Patterns.md | L2 | 2 | complete |
| Java Performance - L2 Profiling.md | L2 | 2 | complete |
| Java Performance - L3 JIT Internals.md | L3 | 2 | complete |
| Java Performance - L3 Memory.md | L3 | 2 | complete |
| Java Performance - L3 Concurrency Performance.md | L3 | 2 | complete |
| Java Performance - L4 GC Internals.md | L4 | 1 | complete |
| Java Performance - L4 JIT Advanced.md | L4 | 1 | complete |
| Java Performance - L4 Production Profiling.md | L4 | 1 | complete |
| Java Performance - L4 Memory Diagnosis.md | L4 | 1 | complete |
| Java Performance - L5 Performance Strategy.md | L5 | 1 | complete |
| Java Performance - L5 Caching Architecture.md | L5 | 1 | complete |
| Java Performance - L6 Theory.md | L6 | 2 | complete |
| Java Performance - META Patterns.md | META | 3 | complete |

## Keyword Registry

### Java Performance - L0 Orientation.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | What Java Performance Means: Latency vs Throughput vs Memory | ★☆☆ | complete |
| 2 | Java Performance Ecosystem: Tools and Disciplines | ★☆☆ | complete |
| 3 | When Performance Optimization Is Worth It | ★☆☆ | complete |

### Java Performance - L1 JVM Basics.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 4 | JVM Memory Areas: Heap, Stack, Metaspace, Code Cache | ★☆☆ | complete |
| 5 | Garbage Collection Fundamentals | ★☆☆ | complete |
| 6 | Bytecode and JIT Compilation Basics | ★☆☆ | complete |

### Java Performance - L1 Measurement.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 7 | Performance Measurement: Metrics, Percentiles, and Baselines | ★☆☆ | complete |
| 8 | CPU Profiling Basics: Flame Graphs and Sampling | ★☆☆ | complete |
| 9 | Heap Profiling: Memory Leak Detection | ★☆☆ | complete |

### Java Performance - L2 GC Basics.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 10 | GC Algorithms: G1, ZGC, Shenandoah Comparison | ★★☆ | complete |
| 11 | GC Tuning Fundamentals: Heap Sizing and Pause Goals | ★★☆ | complete |

### Java Performance - L2 Code Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 12 | Object Allocation Reduction: Pool and Flyweight Patterns | ★★☆ | complete |
| 13 | Collection Performance: ArrayList vs LinkedList vs HashMap Trade-offs | ★★☆ | complete |

### Java Performance - L2 Profiling.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 14 | JMH: Java Microbenchmark Harness Basics | ★★☆ | complete |
| 15 | Async-Profiler and CPU Sampling | ★★☆ | complete |

### Java Performance - L3 JIT Internals.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 16 | JIT Compilation: Inlining, Escape Analysis, Loop Optimization | ★★☆ | complete |
| 17 | Tiered Compilation and Code Cache | ★★☆ | complete |

### Java Performance - L3 Memory.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 18 | Memory Layout: Object Header, Field Alignment, and Padding | ★★☆ | complete |
| 19 | Off-Heap Memory: ByteBuffer and Direct Memory | ★★☆ | complete |

### Java Performance - L3 Concurrency Performance.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 20 | Lock Contention and False Sharing | ★★☆ | complete |
| 21 | Non-Blocking Algorithms and CAS Operations | ★★☆ | complete |

### Java Performance - L4 GC Internals.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 22 | G1 GC Internals: Region Structure and GC Cycle Deep Dive | ★★★ | complete |

### Java Performance - L4 JIT Advanced.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 23 | JIT Deoptimization and Performance Cliffs | ★★★ | complete |

### Java Performance - L4 Production Profiling.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 24 | Production Performance Diagnosis: JFR and Async-Profiler in Production | ★★★ | complete |

### Java Performance - L4 Memory Diagnosis.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 25 | Memory Leak Diagnosis and GC Anti-patterns | ★★★ | complete |

### Java Performance - L5 Performance Strategy.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 26 | Application Performance Engineering: Strategy and Process | ★★★ | complete |

### Java Performance - L5 Caching Architecture.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 27 | JVM Caching Strategy: Application, Query, and Object Cache Trade-offs | ★★★ | complete |

### Java Performance - L6 Theory.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 28 | Mechanical Sympathy: CPU Cache, NUMA, and Hardware Awareness | ★★☆ | complete |
| 29 | Performance Theory: Amdahl's Law, Little's Law, and Queuing Theory | ★★☆ | complete |

### Java Performance - META Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 30 | Performance Investigation Framework: Hypothesis-Driven Optimization | ★☆☆ | complete |
| 31 | Benchmark Design and Pitfalls | ★☆☆ | complete |
| 32 | Performance Regression Prevention | ★☆☆ | complete |
