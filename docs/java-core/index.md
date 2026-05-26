---
title: "Java Core"
nav_order: 2
has_children: true
---

# Java Core

Java standard library APIs: Collections framework, I/O and NIO, exception
handling, String processing, Date/Time API, and core utility classes.
Covers daily usage patterns through production-depth internals.

## Files

| File | Level | Keywords | Status |
| ---- | ----- | -------- | ------ |
| [Java Core - L0 Orientation](Java%20Core%20-%20L0%20Orientation.md) | L0 | 4 | draft |
| [Java Core - L1 Foundations](Java%20Core%20-%20L1%20Foundations.md) | L1 | 5 | draft |
| [Java Core - L2 Collections](Java%20Core%20-%20L2%20Collections.md) | L2 | 5 | draft |
| [Java Core - L2 Collections Advanced](Java%20Core%20-%20L2%20Collections%20Advanced.md) | L2 | 5 | draft |
| [Java Core - L2 Date and Time](Java%20Core%20-%20L2%20Date%20and%20Time.md) | L2 | 4 | draft |
| [Java Core - L2 IO and NIO](Java%20Core%20-%20L2%20IO%20and%20NIO.md) | L2 | 5 | draft |
| [Java Core - L3 Internals](Java%20Core%20-%20L3%20Internals.md) | L3 | 5 | draft |
| [Java Core - L4 Security and Reflection](Java%20Core%20-%20L4%20Security%20and%20Reflection.md) | L4 | 4 | draft |
| [Java Core - L5 Architecture](Java%20Core%20-%20L5%20Architecture.md) | L5 | 3 | draft |
| [Java Core - META Patterns](Java%20Core%20-%20META%20Patterns.md) | META | 3 | draft |

**Keywords:** 43 | **Files:** 10 | **Status:** draft

---

## Keyword Registry

### Java Core - L0 Orientation

| #   | Keyword                                                        | Difficulty | Status  |
| --- | -------------------------------------------------------------- | ---------- | ------- |
| 1   | Java Standard Library: java.lang, java.util, java.io Architecture | ★☆☆     | draft   |
| 2   | Collections Framework Design: Interfaces, Implementations, Algorithms | ★☆☆ | draft   |
| 3   | java.util.concurrent: The Parallel Universe for Thread Safety  | ★☆☆        | draft   |
| 4   | Java I/O Generations: Streams, Readers/Writers, NIO, NIO.2     | ★☆☆        | draft   |

### Java Core - L1 Foundations

| #   | Keyword                                                            | Difficulty | Status  |
| --- | ------------------------------------------------------------------ | ---------- | ------- |
| 1   | Iterable, Iterator, and the Enhanced For Loop Contract             | ★☆☆        | draft   |
| 2   | Comparable vs Comparator: Natural vs External Ordering             | ★★☆        | draft   |
| 3   | List, Set, Map, Queue: The Four Core Collection Interfaces         | ★☆☆        | draft   |
| 4   | Checked vs Unchecked Exceptions: The Historical Design Debate      | ★★☆        | draft   |
| 5   | Exception Hierarchy: Throwable, Error, Exception, RuntimeException | ★☆☆        | draft   |

### Java Core - L2 Collections

| #   | Keyword                                                              | Difficulty | Status  |
| --- | -------------------------------------------------------------------- | ---------- | ------- |
| 1   | ArrayList vs LinkedList: Memory Layout and Access Cost               | ★★☆        | draft   |
| 2   | HashMap: Buckets, Load Factor, Rehashing, and Java 8 Treeification  | ★★☆        | draft   |
| 3   | LinkedHashMap and TreeMap: Ordered Map Variants                      | ★★☆        | draft   |
| 4   | HashSet, LinkedHashSet, and TreeSet: Set Semantics                   | ★★☆        | draft   |
| 5   | PriorityQueue and ArrayDeque: Queue and Deque Implementations        | ★★☆        | draft   |

### Java Core - L2 Collections Advanced

| #   | Keyword                                                                 | Difficulty | Status  |
| --- | ----------------------------------------------------------------------- | ---------- | ------- |
| 1   | Collections Utility Class: Sort, Binary Search, Shuffle, Min/Max        | ★★☆        | draft   |
| 2   | Unmodifiable vs Immutable: List.of() vs Collections.unmodifiableList()  | ★★☆        | draft   |
| 3   | Collectors: groupingBy, partitioningBy, joining, toUnmodifiableMap      | ★★☆        | draft   |
| 4   | Stream-to-Collection Patterns: collect(), toList(), and Materialization | ★★☆        | draft   |
| 5   | Array-to-Collection Bridges: Arrays.asList(), List.of(), Mutation Trap  | ★★☆        | draft   |

### Java Core - L2 Date and Time

| #   | Keyword                                       | Difficulty | Status  |
| --- | --------------------------------------------- | ---------- | ------- |
| 1   | Java Date Time API Overview                   | ★★☆        | draft   |
| 2   | LocalDate LocalTime and LocalDateTime         | ★★☆        | draft   |
| 3   | ZonedDateTime and Time Zones                  | ★★☆        | draft   |
| 4   | Duration Period and Temporal Arithmetic       | ★★☆        | draft   |

### Java Core - L2 IO and NIO

| #   | Keyword                                       | Difficulty | Status  |
| --- | --------------------------------------------- | ---------- | ------- |
| 1   | Java IO Streams: InputStream OutputStream     | ★★☆        | draft   |
| 2   | Reader Writer and Buffered IO                 | ★★☆        | draft   |
| 3   | File and Path API: java.nio.file              | ★★☆        | draft   |
| 4   | NIO Channels Buffers and Selectors            | ★★★        | draft   |
| 5   | try-with-resources and AutoCloseable          | ★★☆        | draft   |

### Java Core - L3 Internals

| #   | Keyword                                                          | Difficulty | Status  |
| --- | ---------------------------------------------------------------- | ---------- | ------- |
| 1   | equals and hashCode: The Full Contract and Cache Invalidation Bugs | ★★★      | draft   |
| 2   | HashMap vs ConcurrentHashMap: Concurrency Safety Guarantees      | ★★★        | draft   |
| 3   | Java Serialization: ObjectOutputStream, Externalizable, Versioning | ★★★      | draft   |
| 4   | Java Reflection: Class, Method, Field - Performance and Security Cost | ★★★   | draft   |
| 5   | Java NIO: Channels, Buffers, Selectors, and Non-Blocking I/O     | ★★★        | draft   |

### Java Core - L4 Security and Reflection

| #   | Keyword                                                               | Difficulty | Status  |
| --- | --------------------------------------------------------------------- | ---------- | ------- |
| 1   | Serialization Vulnerabilities: Gadget Chains and Deserialization Attacks | ★★★     | draft   |
| 2   | Java Security API: KeyStore, Cipher, MessageDigest, SecureRandom      | ★★★        | draft   |
| 3   | Memory-Mapped Files and Direct Buffers for Large Dataset Processing   | ★★★        | draft   |
| 4   | Collection Anti-Patterns: Wrong Abstractions and Compound Operation Bugs | ★★★    | draft   |

### Java Core - L5 Architecture

| #   | Keyword                                       | Difficulty | Status  |
| --- | --------------------------------------------- | ---------- | ------- |
| 1   | Core API Design Principles                    | ★★★        | draft   |
| 2   | Effective Collections Design                  | ★★★        | draft   |
| 3   | Java Standard Library Evolution               | ★★★        | draft   |

### Java Core - META Patterns

| #   | Keyword                                                                | Difficulty | Status  |
| --- | ---------------------------------------------------------------------- | ---------- | ------- |
| 1   | Fail-Fast vs Fail-Safe: Iterator Design and ConcurrentModificationException | ★★☆   | draft   |
| 2   | Choosing the Right Collection: A Decision Framework                    | ★★☆        | draft   |
| 3   | Abstraction Leakage: When Java Abstractions Expose Internals           | ★★☆        | draft   |

---

## Keyword Registry

### Java Core - L0 Orientation

| #   | Keyword                          | Difficulty | Status  |
| --- | -------------------------------- | ---------- | ------- |
| 1   | Java Core API Landscape          | ★☆☆        | pending |
| 2   | java.lang Package Essentials     | ★☆☆        | pending |
| 3   | Null and NullPointerException    | ★☆☆        | pending |
| 4   | Checked vs Unchecked Exceptions  | ★☆☆        | pending |

### Java Core - L1 Foundations

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | Exception Handling try-catch-finally   | ★☆☆        | pending |
| 2   | String and StringBuilder               | ★☆☆        | pending |
| 3   | Object Class Methods                   | ★☆☆        | pending |
| 4   | Arrays and Arrays Utility              | ★☆☆        | pending |
| 5   | Wrapper Classes and Autoboxing         | ★☆☆        | pending |

### Java Core - L2 Collections

| #   | Keyword                          | Difficulty | Status  |
| --- | -------------------------------- | ---------- | ------- |
| 1   | List ArrayList and LinkedList    | ★★☆        | pending |
| 2   | Map HashMap and TreeMap          | ★★☆        | pending |
| 3   | Set HashSet and LinkedHashSet    | ★★☆        | pending |
| 4   | Queue Deque and PriorityQueue    | ★★☆        | pending |
| 5   | Collections Utility Methods      | ★★☆        | pending |

### Java Core - L2 Date and Time

| #   | Keyword                                   | Difficulty | Status  |
| --- | ----------------------------------------- | ---------- | ------- |
| 1   | Java Date Time API Overview               | ★★☆        | pending |
| 2   | LocalDate LocalTime LocalDateTime         | ★★☆        | pending |
| 3   | ZonedDateTime and Time Zones              | ★★☆        | pending |
| 4   | Duration Period and Temporal Arithmetic   | ★★☆        | pending |

### Java Core - L2 IO and NIO

| #   | Keyword                          | Difficulty | Status  |
| --- | -------------------------------- | ---------- | ------- |
| 1   | Java IO Streams                  | ★★☆        | pending |
| 2   | Java NIO Channels and Buffers    | ★★☆        | pending |
| 3   | File and Path API                | ★★☆        | pending |
| 4   | try-with-resources AutoCloseable | ★★☆        | pending |
| 5   | Buffered IO and Performance      | ★★☆        | pending |

### Java Core - L3 Collections Internals

| #   | Keyword                                    | Difficulty | Status  |
| --- | ------------------------------------------ | ---------- | ------- |
| 1   | HashMap Internals and Collision Resolution | ★★★        | pending |
| 2   | TreeMap Red-Black Tree Internals           | ★★★        | pending |
| 3   | ConcurrentHashMap Architecture             | ★★★        | pending |
| 4   | ArrayList Resize and Iterator              | ★★☆        | pending |
| 5   | Generics with Collections                  | ★★☆        | pending |

### Java Core - L3 Advanced APIs

| #   | Keyword                          | Difficulty | Status  |
| --- | -------------------------------- | ---------- | ------- |
| 1   | Regex and Pattern API            | ★★☆        | pending |
| 2   | Java Reflection in Core APIs     | ★★★        | pending |
| 3   | ServiceLoader and SPI Pattern    | ★★☆        | pending |
| 4   | Iterator ListIterator Iterable   | ★★☆        | pending |
| 5   | Resource Management Patterns     | ★★☆        | pending |

### Java Core - L4 Production Depth

| #   | Keyword                              | Difficulty | Status  |
| --- | ------------------------------------ | ---------- | ------- |
| 1   | Collections Performance Anti-patterns| ★★★        | pending |
| 2   | String Memory and Interning          | ★★★        | pending |
| 3   | IO Performance and NIO2              | ★★★        | pending |
| 4   | Exception Handling Anti-patterns     | ★★★        | pending |
| 5   | Collections Thread Safety            | ★★★        | pending |

### Java Core - L5 Architecture

| #   | Keyword                               | Difficulty | Status  |
| --- | ------------------------------------- | ---------- | ------- |
| 1   | Core API Design Principles            | ★★★        | pending |
| 2   | Effective Collections Design          | ★★★        | pending |
| 3   | Java Standard Library Evolution       | ★★★        | pending |

### Java Core - META Patterns

| #   | Keyword                          | Difficulty | Status  |
| --- | -------------------------------- | ---------- | ------- |
| 1   | Choosing the Right Collection    | ★★☆        | pending |
| 2   | Core API Interview Strategy      | ★★☆        | pending |
| 3   | Java Core Anti-Patterns          | ★★☆        | pending |
