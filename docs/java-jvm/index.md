---
title: "Java JVM"
description: "Interview coverage for JVM internals: class loading, garbage collection, JIT, bytecode, memory model"
tags: [interview, java, java-jvm]
---

# Java JVM

JVM internals - how the virtual machine works under the hood. Distinct
from language features (java-language/), platform APIs (java-core/),
and performance tooling (java-performance/).

**Interview focus:** Memory layout, class loading delegation, GC
algorithm trade-offs, JIT optimization, bytecode, JPMS, JMM.

## Files

| File                                                                          | Level   | Keywords | Status  |
| ----------------------------------------------------------------------------- | ------- | -------- | ------- |
| Java JVM - L0 Orientation             | L0      | 4        | planned |
| Java JVM - L1 Foundations             | L1      | 5        | planned |
| Java JVM - L2 Memory Model         | L2      | 5        | planned |
| Java JVM - L3 Class Loading       | L3      | 5        | planned |
| Java JVM - L3 GC Foundations     | L3      | 4        | planned |
| Java JVM - L4 GC Algorithms       | L4      | 5        | planned |
| Java JVM - L4 JIT Compilation   | L4      | 4        | planned |
| Java JVM - L5 Architecture           | L5      | 3        | planned |
| Java JVM - L6 Theory and META | L6+META | 4        | planned |

**Total: 39 keywords, 9 files**

---

## Keyword Registry

### Java JVM - L0 Orientation

| #   | Keyword                                                            | Difficulty | Status  |
| --- | ------------------------------------------------------------------ | ---------- | ------- |
| 1   | What is the JVM? Write-Once-Run-Anywhere Architecture              | easy       | pending |
| 2   | JVM Components: Class Loader, Runtime Data Areas, Execution Engine | easy       | pending |
| 3   | .class Files and Bytecode: What javac Produces                     | easy       | pending |
| 4   | JVM vs Native Execution: The Abstraction Layer Trade-off           | easy       | pending |

### Java JVM - L1 Foundations

| #   | Keyword                                                               | Difficulty | Status  |
| --- | --------------------------------------------------------------------- | ---------- | ------- |
| 1   | JVM Memory Areas: Heap, Stack, Metaspace, PC Register, Code Cache     | easy       | pending |
| 2   | Stack Frames: Local Variables, Operand Stack, Constant Pool Reference | easy       | pending |
| 3   | Class File Format: Magic Number, Constant Pool, Method Table          | easy       | pending |
| 4   | Bytecode Instructions: The JVM Instruction Set Overview               | easy       | pending |
| 5   | JVM Startup Sequence: Bootstrap to main()                             | easy       | pending |

### Java JVM - L2 Memory Model

| #   | Keyword                                                            | Difficulty | Status  |
| --- | ------------------------------------------------------------------ | ---------- | ------- |
| 1   | Java Memory Model: happens-before, Visibility, Ordering Guarantees | medium     | pending |
| 2   | volatile: What It Guarantees and What It Does Not                  | medium     | pending |
| 3   | Object Layout in Heap: Mark Word, Klass Pointer, Fields, Padding   | medium     | pending |
| 4   | Escape Analysis: Stack Allocation, Scalar Replacement, Elision     | medium     | pending |
| 5   | String Deduplication: G1GC Feature for Reduced Heap Footprint      | medium     | pending |

### Java JVM - L3 Class Loading

| #   | Keyword                                                          | Difficulty | Status  |
| --- | ---------------------------------------------------------------- | ---------- | ------- |
| 1   | Class Loading: Bootstrap, Platform, Application Loader Hierarchy | medium     | pending |
| 2   | ClassLoader Delegation: Parent-First Lookup and Bootstrap Trust  | medium     | pending |
| 3   | Class Initialization: Clinit, Static Initializers, Circular Deps | medium     | pending |
| 4   | Dynamic Class Loading: URLClassLoader and Custom ClassLoaders    | medium     | pending |
| 5   | JPMS: Module System Encapsulation, Requires, Exports, Opens      | medium     | pending |

### Java JVM - L3 GC Foundations

| #   | Keyword                                                             | Difficulty | Status  |
| --- | ------------------------------------------------------------------- | ---------- | ------- |
| 1   | GC Fundamentals: Mark-Sweep-Compact and the Generational Hypothesis | medium     | pending |
| 2   | Young Generation: Eden, Survivor Spaces, and Minor GC               | medium     | pending |
| 3   | Old Generation: Promotion, Full GC Triggers, Humongous Objects      | medium     | pending |
| 4   | GC Roots: Thread Stacks, Static Fields, JNI, Class Loaders          | medium     | pending |

### Java JVM - L4 GC Algorithms

| #   | Keyword                                                           | Difficulty | Status  |
| --- | ----------------------------------------------------------------- | ---------- | ------- |
| 1   | G1GC: Region-Based Heap, Mixed GC, and Humongous Allocation       | hard       | pending |
| 2   | ZGC: Colored Pointers, Load Barriers, and Sub-Millisecond Pauses  | hard       | pending |
| 3   | Shenandoah: Brooks Forwarding Pointers and Concurrent Compaction  | hard       | pending |
| 4   | GC Log Analysis: Parsing -Xlog:gc\* and Diagnosing Stop-the-World | hard       | pending |
| 5   | GC Selection Framework: Latency vs Throughput vs Footprint        | hard       | pending |

### Java JVM - L4 JIT Compilation

| #   | Keyword                                                           | Difficulty | Status  |
| --- | ----------------------------------------------------------------- | ---------- | ------- |
| 1   | JIT Compilation: C1, C2, and Tiered Compilation Strategy          | hard       | pending |
| 2   | HotSpot Optimizations: Inlining, Loop Unrolling, Devirtualization | hard       | pending |
| 3   | JIT Deoptimization: When Assumptions Break and Code Falls Back    | hard       | pending |
| 4   | Graal JIT: The New Compiler and Its Trade-offs vs C2              | hard       | pending |

### Java JVM - L5 Architecture

| #   | Keyword                                                           | Difficulty | Status  |
| --- | ----------------------------------------------------------------- | ---------- | ------- |
| 1   | GraalVM Native Image: AOT Compilation and Closed-World Assumption | hard       | pending |
| 2   | JVM Version Migration: Java 8 to 21 - Modules, APIs, Deprecations | hard       | pending |
| 3   | JPMS Governance: Modularizing a Legacy Application                | hard       | pending |

### Java JVM - L6 Theory and META

| #   | Keyword                                                             | Difficulty | Status  |
| --- | ------------------------------------------------------------------- | ---------- | ------- |
| 1   | JVM Specification: Bytecode Verification and Class File Constraints | hard       | pending |
| 2   | Java Memory Model: JSR-133, happens-before, Sequential Consistency  | hard       | pending |
| 3   | JVM Internals Mental Model: Reasoning About Performance             | hard       | pending |
| 4   | Platform Abstraction Thinking: The JVM as a Design Pattern          | hard       | pending |
