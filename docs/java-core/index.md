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

| File                                   | Level | Keywords | Status  |
| -------------------------------------- | ----- | -------- | ------- |
| Java Core - L0 Orientation             | L0    | 4        | planned |
| Java Core - L1 Foundations             | L1    | 5        | planned |
| Java Core - L2 Collections             | L2    | 5        | planned |
| Java Core - L2 Collections Advanced    | L2    | 5        | planned |
| Java Core - L3 Internals               | L3    | 5        | planned |
| Java Core - L4 Security and Reflection | L4    | 4        | planned |
| Java Core - META Patterns              | META  | 3        | planned |

**Total: 31 keywords, 7 files**

---

## Keyword Registry

### Java Core - L0 Orientation

| #   | Keyword                                                               | Difficulty | Status  |
| --- | --------------------------------------------------------------------- | ---------- | ------- |
| 1   | Java Standard Library: java.lang, java.util, java.io Architecture     | easy       | pending |
| 2   | Collections Framework Design: Interfaces, Implementations, Algorithms | easy       | pending |
| 3   | java.util.concurrent: The Parallel Universe for Thread Safety         | easy       | pending |
| 4   | Java I/O Generations: Streams, Readers/Writers, NIO, NIO.2            | easy       | pending |

### Java Core - L1 Foundations

| #   | Keyword                                                            | Difficulty | Status  |
| --- | ------------------------------------------------------------------ | ---------- | ------- |
| 1   | Iterable, Iterator, and the Enhanced For Loop Contract             | easy       | pending |
| 2   | Comparable vs Comparator: Natural vs External Ordering             | easy       | pending |
| 3   | List, Set, Map, Queue: The Four Core Collection Interfaces         | easy       | pending |
| 4   | Checked vs Unchecked Exceptions: The Historical Design Debate      | easy       | pending |
| 5   | Exception Hierarchy: Throwable, Error, Exception, RuntimeException | easy       | pending |

### Java Core - L2 Collections

| #   | Keyword                                                            | Difficulty | Status  |
| --- | ------------------------------------------------------------------ | ---------- | ------- |
| 1   | ArrayList vs LinkedList: Memory Layout and Access Cost             | medium     | pending |
| 2   | HashMap: Buckets, Load Factor, Rehashing, and Java 8 Treeification | medium     | pending |
| 3   | LinkedHashMap and TreeMap: Ordered Map Variants                    | medium     | pending |
| 4   | HashSet, LinkedHashSet, and TreeSet: Set Semantics                 | medium     | pending |
| 5   | PriorityQueue and ArrayDeque: Queue and Deque Implementations      | medium     | pending |

### Java Core - L2 Collections Advanced

| #   | Keyword                                                                 | Difficulty | Status  |
| --- | ----------------------------------------------------------------------- | ---------- | ------- |
| 1   | Collections Utility Class: Sort, Binary Search, Shuffle, Min/Max        | medium     | pending |
| 2   | Unmodifiable vs Immutable: List.of() vs Collections.unmodifiableList()  | medium     | pending |
| 3   | Collectors: groupingBy, partitioningBy, joining, toUnmodifiableMap      | medium     | pending |
| 4   | Stream-to-Collection Patterns: collect(), toList(), and Materialization | medium     | pending |
| 5   | Array-to-Collection Bridges: Arrays.asList(), List.of(), Mutation Trap  | medium     | pending |

### Java Core - L3 Internals

| #   | Keyword                                                               | Difficulty | Status  |
| --- | --------------------------------------------------------------------- | ---------- | ------- |
| 1   | equals and hashCode: The Full Contract and Cache Invalidation Bugs    | medium     | pending |
| 2   | HashMap vs ConcurrentHashMap: Concurrency Safety Guarantees           | medium     | pending |
| 3   | Java Serialization: ObjectOutputStream, Externalizable, Versioning    | medium     | pending |
| 4   | Java Reflection: Class, Method, Field - Performance and Security Cost | medium     | pending |
| 5   | Java NIO: Channels, Buffers, Selectors, and Non-Blocking I/O          | medium     | pending |

### Java Core - L4 Security and Reflection

| #   | Keyword                                                                  | Difficulty | Status  |
| --- | ------------------------------------------------------------------------ | ---------- | ------- |
| 1   | Serialization Vulnerabilities: Gadget Chains and Deserialization Attacks | hard       | pending |
| 2   | Java Security API: KeyStore, Cipher, MessageDigest, SecureRandom         | hard       | pending |
| 3   | Memory-Mapped Files and Direct Buffers for Large Dataset Processing      | hard       | pending |
| 4   | Collection Anti-Patterns: Wrong Abstractions and Compound Operation Bugs | hard       | pending |

### Java Core - META Patterns

| #   | Keyword                                                                     | Difficulty | Status  |
| --- | --------------------------------------------------------------------------- | ---------- | ------- |
| 1   | Fail-Fast vs Fail-Safe: Iterator Design and ConcurrentModificationException | hard       | pending |
| 2   | Choosing the Right Collection: A Decision Framework                         | hard       | pending |
| 3   | Abstraction Leakage: When Java Abstractions Expose Internals                | hard       | pending |
