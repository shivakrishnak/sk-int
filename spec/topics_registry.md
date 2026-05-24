# SK Interview - Topic Registry & Keyword Rubric

This file is the **single source of truth** for the keyword generation rubric and the topic registry. It is self-contained - it does not depend on any external dictionary or master keyword list.

| File                                                             | Purpose                                                                    |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [interview_content_generator.md](interview_content_generator.md) | Master content generation spec (v1.0) - 18 sections per keyword (4.1-4.18) |
| [topics_registry.md](topics_registry.md)                         | This file - topic registry + keyword rubric                                |

---

## Workflow Modes

1. **New topic (no folder under `docs/`):** Apply the [Level Coverage Rubric](#level-coverage-rubric-mandatory) to generate keywords. Create `docs/{topic}/` with `index.md` and one file per level (capacity varies; see rubric). Generate content via `@generate-entries`.
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

| Topic            | Folder                 | Status  | Description                                                                        |
| ---------------- | ---------------------- | ------- | ---------------------------------------------------------------------------------- |
| Java Language    | docs/java-language/    | planned | Language spec: types, OOP, generics, lambdas, modern Java (8-21) - 46 kw, 10 files |
| Java Core APIs   | docs/java-core/        | planned | Platform APIs: collections, I/O, NIO, serialization, reflection - 31 kw, 7 files   |
| Java JVM         | docs/java-jvm/         | planned | VM internals: class loading, GC, JIT, bytecode, memory model - 39 kw, 9 files      |
| Java Concurrency | docs/java-concurrency/ | planned | Threads, locks, executors, CompletableFuture, virtual threads - 40 kw, 9 files     |
| Java Performance | docs/java-performance/ | planned | JFR, async-profiler, GC tuning, heap analysis, JVM flags - 23 kw, 5 files          |

---

## Level Coverage Rubric (MANDATORY)

Every interview topic MUST cover ALL knowledge levels. A topic missing L0/L1 (foundations) or L5/META (architecture and meta-skills) is **INCOMPLETE**. PRE (prerequisites), L6 (theory), and L5 (architect) are required for complex/deep topics and optional for narrow topics.

### Level requirements

| Level | Icon | Name          | What It Covers                                    | Capacity (max/file) |
| ----- | ---- | ------------- | ------------------------------------------------- | ------------------- |
| PRE   | 🔑   | Prerequisites | Prior knowledge from other topics; dependency map | 5 concepts          |
| L0    | 🌱   | Orientation   | Why it exists, ecosystem map, what came before    | 10                  |
| L1    | ★☆☆  | Foundational  | Core vocabulary, building blocks, setup           | 10                  |
| L2    | ★★☆  | Working       | Common patterns, daily usage, idioms              | 7                   |
| L3    | ★★☆+ | Intermediate  | Design decisions, trade-offs, internals           | 7                   |
| L4    | ★★★  | Expert        | Production diagnostics, failure modes, tuning     | 5                   |
| L5    | 🔥   | Architect     | Strategy, migration, governance, at-scale design  | 5                   |
| L6    | 🔬   | Creator       | Theory, specification, research foundations       | 3                   |
| META  | 🧠   | Meta-Skills   | Transferable thinking patterns                    | 5                   |

> **Capacity rule:** target ~25,000–35,000 words of generated content per file so generation completes in one pass without quality degradation. L0/L1 entries are short (~1,500–2,500 words each); L4/L5 entries are complex (~7,000–9,000 words each). Split by subtopic if a level exceeds its capacity (e.g., `Java - L2 Collections.md`, `Java - L2 Streams.md`).

**Total per topic: 30-50 keywords minimum.** File capacity is content-driven (see Capacity column above). **One level per file — never mix levels.**

### File organization by level

| File pattern                   | Level | Purpose                                             |
| ------------------------------ | ----- | --------------------------------------------------- |
| `{Topic} - Prerequisites.md`   | PRE   | Dependency map — optional, complex topics only      |
| `{Topic} - L0 Orientation.md`  | L0    | Why it exists, ecosystem, what came before          |
| `{Topic} - L1 Foundations.md`  | L1    | Core vocabulary, building blocks, setup             |
| `{Topic} - L2 {Subtopic}.md`   | L2    | Working patterns — split by subtopic if >7 keywords |
| `{Topic} - L3 {Subtopic}.md`   | L3    | Design decisions — split by subtopic if >7 keywords |
| `{Topic} - L4 {Subtopic}.md`   | L4    | Production depth — split by subtopic if >5 keywords |
| `{Topic} - L5 Architecture.md` | L5    | Strategy, migration, at-scale governance            |
| `{Topic} - L6 Theory.md`       | L6    | Theory, specification, research — optional          |
| `{Topic} - META Patterns.md`   | META  | Transferable cross-domain thinking                  |

> **Rule:** one level per file, always. Never mix levels in a single file. When a level needs multiple files, name them by subtopic: `{Topic} - L2 {Subtopic}.md`.

### Mandatory keyword types (at L3+)

Every topic at L3+ MUST include:

- At least 1 **anti-pattern** keyword (what NOT to do)
- At least 1 **decision framework** keyword (how to choose between alternatives)
- At least 1 **security** keyword (domain-specific risks)
- At least 1 **production diagnostic** keyword (real commands, log analysis)
- At least 1 **failure mode** keyword (what breaks, symptoms, fix)

### Level coverage verification (before generating content)

Confirm the keyword list covers:

1. **PRE included?** Required if topic depends on ≥ 2 other topics — list prerequisite concepts
2. **L0 exists?** At least 2 orientation keywords (why it exists, ecosystem position)
3. **L1 exists?** At least 3 foundational keywords (core vocabulary, setup)
4. **L2 present?** Working patterns, daily idioms — covers at least 3 Knowledge Dimensions
5. **L3 present?** Design decisions, trade-offs, internals
6. **L4 present?** Production diagnostics, failure modes, tuning
7. **L5 present?** Architecture decisions, migration strategies (optional for narrow topics)
8. **L6 present?** Theory, specification, research foundations (optional; for historically deep topics)
9. **META present?** At least 1 transferable thinking pattern
10. **File capacity?** Every file respects its level's capacity limit; one level per file

If a required level is missing: add keywords before generating content.

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

| File                            | Level | Keywords (indicative)                                                                  |
| ------------------------------- | ----- | -------------------------------------------------------------------------------------- |
| Java - L0 Orientation.md        | L0    | Why Java, JVM ecosystem, Java vs alternatives, platform independence, history          |
| Java - L1 Foundations.md        | L1    | JVM/JRE/JDK, compilation pipeline, classpath, data types, classes/objects, interfaces  |
| Java - L2 Collections.md        | L2    | Collections framework, ArrayList/LinkedList, HashMap/TreeMap, HashSet, equals/hashCode |
| Java - L2 Language Features.md  | L2    | Lambdas, Stream API, Optional, var, Records, Sealed Classes, Switch Expressions        |
| Java - L2 Exceptions and IO.md  | L2    | Exception hierarchy, Checked vs Unchecked, Try-with-Resources, NIO, Serialization      |
| Java - L3 JVM Internals.md      | L3    | Class loading, bytecode, JIT (C1/C2), stack/heap, Metaspace, memory model, GraalVM     |
| Java - L3 Modern Java.md        | L3    | Virtual Threads (Loom), Structured Concurrency, Records, Pattern Matching, JPMS, FFM   |
| Java - L4 GC and Diagnostics.md | L4    | G1GC, ZGC, Shenandoah, GC tuning, JFR, thread dumps, heap dumps, perf profiling        |
| Java - L5 Architecture.md       | L5    | Module strategy, LTS migration, polyglot JVM, build strategy, library design           |
| Java - L6 Theory.md             | L6    | JVM specification, bytecode design, GC algorithm research, Project Valhalla rationale  |
| Java - META Patterns.md         | META  | JVM-as-abstraction principle, platform-independence reasoning, evolution cadence       |

### Java Concurrency (docs/java-concurrency/)

| File                                             | Level | Keywords (indicative)                                                        |
| ------------------------------------------------ | ----- | ---------------------------------------------------------------------------- |
| Java Concurrency - L0 Orientation.md             | L0    | Why concurrency matters, concurrency hazards, thread vs process mental model |
| Java Concurrency - L1 Foundations.md             | L1    | Thread lifecycle, memory model, visibility, atomicity, happens-before        |
| Java Concurrency - L2 Locks.md                   | L2    | synchronized, ReentrantLock, ReadWriteLock, StampedLock, tryLock patterns    |
| Java Concurrency - L3 Collections and Atomics.md | L3    | ConcurrentHashMap, CopyOnWriteArrayList, AtomicInteger, LongAdder, Phaser    |
| Java Concurrency - L3 Executors and Futures.md   | L3    | ExecutorService, ForkJoinPool, CompletableFuture, Scheduled Executors        |
| Java Concurrency - L4 Diagnostics.md             | L4    | Race conditions, deadlocks, livelocks, thread dumps, JFR concurrency events  |
| Java Concurrency - L4 Virtual Threads.md         | L4    | Project Loom, carrier threads, pinning, structured concurrency, migration    |
| Java Concurrency - L5 Architecture.md            | L5    | Thread pool sizing, backpressure, reactive vs imperative, migration strategy |
| Java Concurrency - META Patterns.md              | META  | Lock contention as traffic congestion, shared-state vs message-passing       |

---

## Adding a new topic

1. Add a row to **Active Topics** above with status `planned`.
2. Plan keywords using the [Level Coverage Rubric](#level-coverage-rubric-mandatory). Cover PRE (if needed), L0–L6, META.
3. Plan files: one file per level. Use the [level-per-file pattern](#file-organization-by-level). Respect content-capacity limits. Split by subtopic when a level exceeds capacity.
4. Run the scaffold generator (optional): `pwsh -File scripts/generate_topics.ps1 -Topic "MyTopic"`.
5. Update status to `scaffolded`, then `generating`, then `complete`.
6. Add the topic row to `docs/index.md`.
7. Add the topic row to `docs/index.md` with link and keyword count.
