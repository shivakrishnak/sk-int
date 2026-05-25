---
layout: default
title: "Java Performance"
nav_order: 5
has_children: true
permalink: /java-performance/
description: "Interview coverage for Java performance: JFR, async-profiler, GC tuning, heap analysis, JVM flags"
---

# Java Performance

Java performance tooling and diagnosis - how to find and fix slow or
memory-hungry Java applications. Distinct from GC algorithm internals
(java-jvm/) which focuses on HOW the JVM works. This folder focuses on
HOW TO TUNE and DIAGNOSE it when it's broken.

**Interview focus:** Profiling workflow, GC log analysis, heap dump
investigation, JVM flag choices, memory leak patterns, SLO-aware
performance testing.

## Files

| File                                        | Level   | Keywords | Status  |
| ------------------------------------------- | ------- | -------- | ------- |
| Java Performance - L0 Orientation           | L0      | 4        | planned |
| Java Performance - L2 Profiling             | L2      | 5        | planned |
| Java Performance - L3 GC Tuning             | L3      | 5        | planned |
| Java Performance - L4 Advanced Diagnostics  | L4      | 5        | planned |
| Java Performance - L5 Architecture and META | L5+META | 4        | planned |

**Total: 23 keywords, 5 files**

---

## Keyword Registry

### Java Performance - L0 Orientation

| #   | Keyword                                                             | Difficulty | Status  |
| --- | ------------------------------------------------------------------- | ---------- | ------- |
| 1   | Performance Engineering: Measure Before You Optimize                | easy       | pending |
| 2   | Latency vs Throughput vs Footprint: Choosing the Right Goal         | easy       | pending |
| 3   | The JVM Performance Toolbox: JFR, JMC, async-profiler, JMX          | easy       | pending |
| 4   | Java Performance Anti-Patterns: Premature Optimization and GC Abuse | easy       | pending |

### Java Performance - L2 Profiling

| #   | Keyword                                                                | Difficulty | Status  |
| --- | ---------------------------------------------------------------------- | ---------- | ------- |
| 1   | Java Flight Recorder: Custom Events, Configurations, Streaming API     | medium     | pending |
| 2   | JDK Mission Control: Flame Graphs, Hot Methods, Allocation Profiling   | medium     | pending |
| 3   | async-profiler: CPU, Allocation, Lock Profiling Without Safepoints     | medium     | pending |
| 4   | JMX and MBeans: Runtime Metrics, Remote Monitoring, and Alerting       | medium     | pending |
| 5   | Heap Dump Analysis: MAT, Retained Heap, Dominator Trees, Leak Suspects | medium     | pending |

### Java Performance - L3 GC Tuning

| #   | Keyword                                                              | Difficulty | Status  |
| --- | -------------------------------------------------------------------- | ---------- | ------- |
| 1   | GC Log Analysis: Parsing -Xlog:gc\* and Identifying Pause Patterns   | medium     | pending |
| 2   | Heap Sizing Strategy: Xms, Xmx, and Why Setting Them Equal Matters   | medium     | pending |
| 3   | Allocation Rate Optimization: Reducing Object Pressure               | medium     | pending |
| 4   | GC Tuning Anti-Patterns: MaxGCPauseMillis Myths and Over-Engineering | medium     | pending |
| 5   | Object Pooling vs Allocation: When Pools Help and When They Hurt     | medium     | pending |

### Java Performance - L4 Advanced Diagnostics

| #   | Keyword                                                                 | Difficulty | Status  |
| --- | ----------------------------------------------------------------------- | ---------- | ------- |
| 1   | Memory Leak Detection: ClassLoader Leaks, Static Collections, Listeners | hard       | pending |
| 2   | CPU Starvation vs Memory Pressure: Distinguishing the Diagnosis         | hard       | pending |
| 3   | JVM Flag Tuning Checklist: Production-Safe Flags and Pitfalls           | hard       | pending |
| 4   | Native Memory Tracking: Off-Heap Diagnostics with NMT                   | hard       | pending |
| 5   | Compressed OOPs and Object Header Optimization for Large Heaps          | hard       | pending |

### Java Performance - L5 Architecture and META

| #   | Keyword                                                                 | Difficulty | Status  |
| --- | ----------------------------------------------------------------------- | ---------- | ------- |
| 1   | Performance Testing Strategy: Microbenchmarks with JMH                  | hard       | pending |
| 2   | Continuous Performance Monitoring: Baselines, SLOs, Regression Alerts   | hard       | pending |
| 3   | JVM Warm-Up Strategies: Class Data Sharing (CDS) and Profile-Guided AOT | hard       | pending |
| 4   | Production Performance Thinking: First-Principles Reasoning             | hard       | pending |
