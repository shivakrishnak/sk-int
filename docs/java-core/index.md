---
layout: default
title: "Java Core APIs"
parent: "SK Interview"
nav_order: 2
has_children: true
permalink: /java-core/
description: "Interview coverage for Java platform APIs: collections, I/O, serialization, reflection, exceptions"
---

# Java Core APIs

Java standard library APIs - Collections framework, I/O, NIO,
serialization, reflection, and exceptions. Distinct from language
features (java-language/) and JVM internals (java-jvm/).

**Interview focus:** Collections internals and selection, I/O API
generations, serialization security, reflection cost, exception design.

## Files

| File                                                                  | Level | Keywords | Status   |
| --------------------------------------------------------------------- | ----- | -------- | -------- |
| [Java Core - L0 Orientation](l0-orientation/)                         | L0    | 4        | complete |
| [Java Core - L1 Foundations](l1-foundations/)                         | L1    | 5        | complete |
| [Java Core - L2 Collections](l2-collections/)                         | L2    | 5        | complete |
| [Java Core - L2 Collections Advanced](l2-collections-advanced/)       | L2    | 5        | complete |
| [Java Core - L3 Internals](l3-internals/)                             | L3    | 5        | complete |
| [Java Core - L4 Security and Reflection](l4-security-and-reflection/) | L4    | 4        | complete |
| [Java Core - META Patterns](meta-patterns/)                           | META  | 3        | complete |

**Total: 31 keywords, 7 files**

---

## Keyword Registry

### Java Core - L0 Orientation

| #   | Keyword                                                               | Difficulty | Status |
| --- | --------------------------------------------------------------------- | ---------- | ------ |
| 1   | Java Standard Library: java.lang, java.util, java.io Architecture     | easy       | draft  |
| 2   | Collections Framework Design: Interfaces, Implementations, Algorithms | easy       | draft  |
| 3   | java.util.concurrent: The Parallel Universe for Thread Safety         | easy       | draft  |
| 4   | Java I/O Generations: Streams, Readers/Writers, NIO, NIO.2            | easy       | draft  |

### Java Core - L1 Foundations

| #   | Keyword                                                            | Difficulty | Status |
| --- | ------------------------------------------------------------------ | ---------- | ------ |
| 1   | Iterable, Iterator, and the Enhanced For Loop Contract             | easy       | draft  |
| 2   | Comparable vs Comparator: Natural vs External Ordering             | easy       | draft  |
| 3   | List, Set, Map, Queue: The Four Core Collection Interfaces         | easy       | draft  |
| 4   | Checked vs Unchecked Exceptions: The Historical Design Debate      | easy       | draft  |
| 5   | Exception Hierarchy: Throwable, Error, Exception, RuntimeException | easy       | draft  |

### Java Core - L2 Collections

| #   | Keyword                                                            | Difficulty | Status |
| --- | ------------------------------------------------------------------ | ---------- | ------ |
| 1   | ArrayList vs LinkedList: Memory Layout and Access Cost             | medium     | draft  |
| 2   | HashMap: Buckets, Load Factor, Rehashing, and Java 8 Treeification | medium     | draft  |
| 3   | LinkedHashMap and TreeMap: Ordered Map Variants                    | medium     | draft  |
| 4   | HashSet, LinkedHashSet, and TreeSet: Set Semantics                 | medium     | draft  |
| 5   | PriorityQueue and ArrayDeque: Queue and Deque Implementations      | medium     | draft  |

### Java Core - L2 Collections Advanced

| #   | Keyword                                                                 | Difficulty | Status |
| --- | ----------------------------------------------------------------------- | ---------- | ------ |
| 1   | Collections Utility Class: Sort, Binary Search, Shuffle, Min/Max        | medium     | draft  |
| 2   | Unmodifiable vs Immutable: List.of() vs Collections.unmodifiableList()  | medium     | draft  |
| 3   | Collectors: groupingBy, partitioningBy, joining, toUnmodifiableMap      | medium     | draft  |
| 4   | Stream-to-Collection Patterns: collect(), toList(), and Materialization | medium     | draft  |
| 5   | Array-to-Collection Bridges: Arrays.asList(), List.of(), Mutation Trap  | medium     | draft  |

### Java Core - L3 Internals

| #   | Keyword                                                               | Difficulty | Status |
| --- | --------------------------------------------------------------------- | ---------- | ------ |
| 1   | equals and hashCode: The Full Contract and Cache Invalidation Bugs    | medium     | draft  |
| 2   | HashMap vs ConcurrentHashMap: Concurrency Safety Guarantees           | medium     | draft  |
| 3   | Java Serialization: ObjectOutputStream, Externalizable, Versioning    | medium     | draft  |
| 4   | Java Reflection: Class, Method, Field - Performance and Security Cost | medium     | draft  |
| 5   | Java NIO: Channels, Buffers, Selectors, and Non-Blocking I/O          | medium     | draft  |

### Java Core - L4 Security and Reflection

| #   | Keyword                                                                  | Difficulty | Status |
| --- | ------------------------------------------------------------------------ | ---------- | ------ |
| 1   | Serialization Vulnerabilities: Gadget Chains and Deserialization Attacks | hard       | draft  |
| 2   | Java Security API: KeyStore, Cipher, MessageDigest, SecureRandom         | hard       | draft  |
| 3   | Memory-Mapped Files and Direct Buffers for Large Dataset Processing      | hard       | draft  |
| 4   | Collection Anti-Patterns: Wrong Abstractions and Compound Operation Bugs | hard       | draft  |

### Java Core - META Patterns

| #   | Keyword                                                                     | Difficulty | Status |
| --- | --------------------------------------------------------------------------- | ---------- | ------ |
| 1   | Fail-Fast vs Fail-Safe: Iterator Design and ConcurrentModificationException | hard       | draft  |
| 2   | Choosing the Right Collection: A Decision Framework                         | hard       | draft  |
| 3   | Abstraction Leakage: When Java Abstractions Expose Internals                | hard       | draft  |
