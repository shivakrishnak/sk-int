# SK Interview - Topic Registry & Keyword Rubric

This file is the **single source of truth** for the keyword generation rubric and the topic registry. It is self-contained - it does not depend on any external dictionary or master keyword list.

| File                         | Purpose                                                         |
| ---------------------------- | --------------------------------------------------------------- |
| [interview.md](interview.md) | Master content generation spec (v1.0) - 24 sections per keyword |
| [topics_registry.md](topics_registry.md) | This file - topic registry + keyword rubric                     |

---

## Workflow Modes

1. **New topic (no folder under `docs/`):** Apply the [Level Coverage Rubric](#level-coverage-rubric-mandatory) to generate keywords. Create `docs/{topic}/` with `index.md` and subtopic files (3-5 keywords each, max 5). Generate content via `@generate-entries`.
2. **Brand-new topic (e.g., Angular):** Same as above; first identify the topic's natural grouping (language / framework / domain / platform / theory).
3. **New subtopic (e.g., React Hooks, parent topic exists):** Create a new file in the existing topic folder. Add keywords per the rubric, fill gaps in the topic's level coverage.
4. **From description / JD:** Parse the JD for technologies and skills. Map each to an existing topic or create a new one. Apply rubric per topic.

---

## Registry Format

| Topic        | Folder              | Status                                       | Description      |
| ------------ | ------------------- | -------------------------------------------- | ---------------- |
| [Topic Name] | docs/[folder-name]/ | planned / scaffolded / generating / complete | One-line summary |

## Active Topics

> No topics yet. Add a row here when you create a topic folder under `docs/`.

| Topic | Folder | Status | Description |
| ----- | ------ | ------ | ----------- |
|       |        |        |             |

---

## Level Coverage Rubric (MANDATORY)

Every interview topic MUST cover ALL eight knowledge levels. A topic missing L0/L1 (foundations) or L5/L6/META (architecture and theory) is **INCOMPLETE**.

### Level requirements

| Level | Icon | Name         | What It Covers                                   | Min Keywords |
| ----- | ---- | ------------ | ------------------------------------------------ | ------------ |
| L0    | 🌱   | Orientation  | Why it exists, ecosystem map, what came before   | 3-5          |
| L1    | ★☆☆  | Foundational | Core vocabulary, building blocks, setup          | 4-6          |
| L2    | ★★☆  | Working      | Common patterns, daily usage, idioms             | 5-8          |
| L3    | ★★☆+ | Intermediate | Design decisions, trade-offs, internals          | 5-10         |
| L4    | ★★★  | Expert       | Production diagnostics, failure modes, tuning    | 5-10         |
| L5    | 🔥   | Architect    | Strategy, migration, governance, at-scale design | 3-5          |
| L6    | 🔬   | Creator      | Theory, specification, research foundations      | 2-3          |
| META  | 🧠   | Meta-Skills  | Transferable thinking patterns                   | 2-3          |

**Total per topic: 30-50 keywords minimum.** Max 5 keywords per file, min 3.

### File organization by level

| File pattern                  | Levels           | Purpose                              |
|-------------------------------|------------------|--------------------------------------|
| `{Topic} - Foundations.md`    | L0 + L1          | Orientation + foundational           |
| `{Topic} - Getting Started.md` | L1 (overflow)    | Setup + first steps if L1 > 5        |
| `{Topic} - {Subtopic}.md`     | L2 + L3          | Working knowledge + design decisions |
| `{Topic} - {Subtopic}.md`     | L3 + L4          | Deep internals + production          |
| `{Topic} - Architecture.md`   | L5 + L6          | Strategy + theory                    |
| `{Topic} - Strategy.md`       | META             | meta-patterns                        | 

### Mandatory keyword types (at L3+)

Every topic at L3+ MUST include:

- At least 1 **anti-pattern** keyword (what NOT to do)
- At least 1 **decision framework** keyword (how to choose between alternatives)
- At least 1 **security** keyword (domain-specific risks)
- At least 1 **production diagnostic** keyword (real commands, log analysis)
- At least 1 **failure mode** keyword (what breaks, symptoms, fix)

### Level coverage verification (before generating content)

Confirm the keyword list covers:

1. **L0 exists?** At least 2 orientation keywords (why, what, ecosystem)
2. **L1 exists?** At least 3 foundational keywords (vocabulary, setup)
3. **L2-L3 balanced?** Working + intermediate keywords present (5 each)
4. **L4 present?** Production diagnostics, failure modes, tuning (5)
5. **L5 present?** Architecture decisions, migration strategies (2-3)
6. **L6 present?** Theory, specification, research foundations (1-2)
7. **META present?** At least 1 transferable thinking pattern
8. **File cap?** Every file has 3-5 keywords (never more than 5)

If ANY level is missing: add keywords before generating content.

---

## Knowledge Dimensions (10 total)

Every keyword must illuminate one or more of these 10 dimensions. Across a topic, all 10 dimensions should be covered collectively.

1. **Concept** - what it is, why it exists
2. **Mechanism** - how it works underneath
3. **Pattern** - idiomatic usage
4. **Trade-off** - what you gain vs sacrifice
5. **Failure** - what breaks and why
6. **Diagnostic** - how to debug it in production
7. **Decision** - when to use vs avoid
8. **Scale** - what changes at 10x/100x/1000x
9. **Security** - domain-specific risks
10. **Evolution** - how it changes over time / version differences

---

## Planning Reference: Sub-topic File Mapping

Reference splits for common topics. Use as a starting point - adapt per topic.

### Java (docs/java/)

| File                                | Keywords (approximate)                                                                 |
| ----------------------------------- | -------------------------------------------------------------------------------------- |
| Java - Foundations.md               | Why Java, JVM/JRE/JDK, Compilation Pipeline, Classpath, "Hello World" lifecycle        |
| Java - Basics.md                    | Variables/Data Types, Operators/Control Flow, Classes/Objects, Inheritance, Interfaces |
| Java - Collections.md               | Collections Framework, ArrayList/LinkedList, HashMap/TreeMap, HashSet, equals/hashCode |
| Java - Exceptions and IO.md         | Exception Hierarchy, Checked vs Unchecked, Try-with-Resources, NIO, Serialization      |
| Java - Java 8 Features.md           | Lambdas, Functional Interfaces, Stream API, Optional, Method References, Collectors    |
| Java - Java 11 to 17.md             | var, Text Blocks, Switch Expressions, Records, Sealed Classes, Pattern Matching, JPMS  |
| Java - Java 21 and Beyond.md        | Virtual Threads, Structured Concurrency, Scoped Values, Record Patterns, FFM API       |
| Java - JVM Internals.md             | JVM Architecture, Bytecode, Class Loading, Stack/Heap, Metaspace, JIT (C1/C2), GraalVM |
| Java - Garbage Collection.md        | GC Fundamentals, Generational GC, G1GC, ZGC, Shenandoah, GC Tuning, Reference Types    |
| Java - Diagnostics and Security.md  | JFR, Thread Dumps, Heap Dumps, Performance Tuning, Java Security, Version Migration    |
| Java - Architecture and Strategy.md | Module Strategy, Migration to LTS, Polyglot JVM, Build Strategy, Library Design        |

### Java Concurrency (docs/java-concurrency/)

| File                                            | Keywords (approximate)                                                       |
| ----------------------------------------------- | ---------------------------------------------------------------------------- |
| Java Concurrency - Foundations.md               | Why Concurrency, Thread vs Process, Memory Model, Visibility, Atomicity      |
| Java Concurrency - Threads and Locks.md         | Thread Lifecycle, synchronized, ReentrantLock, ReadWriteLock, StampedLock    |
| Java Concurrency - Collections and Atomics.md   | ConcurrentHashMap, CopyOnWriteArrayList, AtomicInteger, LongAdder            |
| Java Concurrency - Executors and Futures.md     | ExecutorService, ForkJoinPool, CompletableFuture, Scheduled Executors        |
| Java Concurrency - Virtual Threads.md           | Project Loom, Carrier Threads, Pinning, Structured Concurrency               |
| Java Concurrency - Architecture and Strategy.md | Thread Pool Sizing, Backpressure, Reactive vs Imperative, Migration Strategy |

---

## Adding a new topic

1. Add a row to **Active Topics** above with status `planned`.
2. Plan keywords using the [Level Coverage Rubric](#level-coverage-rubric-mandatory). Cover L0-L6 + META.
3. Plan files: group keywords into 3-5 per file (max 5). Use the level-band file pattern.
4. Run the scaffold generator (optional): `pwsh -File scripts/generate_topics.ps1 -Topic "MyTopic"`.
5. Update status to `scaffolded`, then `generating`, then `complete`.
6. Add the topic row to `docs/index.md`.
7. If using explicit nav in `mkdocs.yml`, add the topic there.
