# SK Interview - Topic Registry & Keyword Rubric

This file is the **single source of truth** for the keyword generation rubric and the topic registry. It is self-contained - it does not depend on any external dictionary or master keyword list.

| File                                                             | Purpose                                                                    |
|------------------------------------------------------------------|----------------------------------------------------------------------------|
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
|--------------|---------------------|----------------------------------------------|------------------|
| [Topic Name] | docs/[folder-name]/ | planned / generating / complete | One-line summary |

## Active Topics

| Topic | Folder | Status | Description |
|---|---|---|---|
| Software Architecture | docs/software-architecture/ | complete | Styles, patterns, principles, and production decisions - L0 through META (18 files, 35 keywords) |
| SRE | docs/sre/ | complete | Site Reliability Engineering - SLIs/SLOs/SLAs, error budgets, on-call, chaos engineering, and staff-level governance - PRE + L0 through META (17 files, 35 keywords) |
| Java EE | docs/java-ee/ | incomplete | Jakarta EE specification stack - Servlets, CDI, EJB, JAX-RS, JTA, security, app server tuning, and migration strategy (16 files, 31 keywords) |
| Cloud Fundamentals | docs/cloud-fundamentals/ | incomplete | Cloud computing models, IaC, networking, security, HA/DR, cost optimization, multi-cloud, and migration strategy (15 files, 29 keywords) |
| AWS | docs/aws/ | complete | Amazon Web Services - compute, storage, networking, databases, messaging, serverless, security, observability, and architecture (17 files, 33 keywords) |
| Observability | docs/observability/ | complete | Logs, metrics, traces, OpenTelemetry, distributed tracing, cardinality, sampling, alerting, eBPF profiling, and staff-level platform design (20 files, 35 keywords) |
| Platform Engineering | docs/platform-engineering/ | complete | Internal Developer Platforms, golden paths, DevEx, Backstage, GitOps, Kubernetes-based platforms, Team Topologies, platform SLOs, TCO/ROI, and staff-level strategy (19 files, 36 keywords) |
| CSS | docs/css/ | complete | Cascade, box model, Flexbox, Grid, responsive design, animations, CSS architecture methodologies, preprocessors, performance, container queries, and design token systems (15 files, 27 keywords) |
| Frontend Build Tools | docs/frontend-build-tools/ | complete | npm, Webpack, Vite, code splitting, tree shaking, bundle analysis, monorepos, supply chain security, esbuild/SWC build performance, and module federation (14 files, 27 keywords) |
| Frontend Testing | docs/frontend-testing/ | complete | Jest, React Testing Library, Playwright, Cypress, Vitest, mocking with MSW, visual regression, accessibility testing, flaky test diagnosis, and quality architecture (13 files, 25 keywords) |
| HTML | docs/html/ | complete | Document structure, semantic HTML, forms, accessibility/ARIA, web components, shadow DOM, resource hints, critical rendering path, SEO, and HTML standards governance (14 files, 27 keywords) |
| JavaScript | docs/javascript/ | complete | Types, closures, prototypes, async/await, event loop, DOM, ES6+ features, design patterns, memory model, V8 internals, security, performance profiling, and JS architecture at scale (18 files, 35 keywords) |
| Node.js | docs/nodejs/ | complete | Event-driven architecture, core modules, CommonJS/ESM, streams, buffers, Express, worker threads, libuv internals, security vulnerabilities, production deployment, and microservices (14 files, 28 keywords) |
| React | docs/react/ | incomplete | JSX, hooks, component patterns, Context API, state management, routing, performance optimization, Fiber reconciler, server components, security, and React architecture at scale (16 files, 30 keywords) |
| TypeScript | docs/typescript/ | complete | Type system, generics, conditional/mapped types, utility types, decorators, tsconfig, module resolution, type inference internals, build performance, migration strategy, and type theory (13 files, 26 keywords) |
| Async Java | docs/async-java/ | complete | CompletableFuture, Project Reactor, Spring WebFlux, Virtual Threads, Structured Concurrency, reactive architecture, async patterns, and migration strategy (17 files, 32 keywords) |
| GraalVM | docs/graalvm/ | incomplete | GraalVM ecosystem, native-image AOT, SubstrateVM, polyglot engine, Truffle framework, and Spring Boot/Quarkus/Micronaut native integration (10 files, 34 keywords) |
| Micronaut | docs/micronaut/ | incomplete | Micronaut framework, AOT compilation, HTTP client/server, data access, cloud-native patterns, and production deployment (10 files, 43 keywords) |
| Quarkus | docs/quarkus/ | incomplete | Quarkus framework, Panache, reactive extensions, cloud-native deployment, GraalVM native image, and production depth (10 files, 43 keywords) |

## Level Coverage Rubric (MANDATORY)

Every interview topic MUST cover ALL knowledge levels. A topic missing L0/L1 (foundations) or L5/META (architecture and meta-skills) is **INCOMPLETE**. PRE (prerequisites), L6 (theory), and L5 (architect) are required for complex/deep topics and optional for narrow topics.

### Level requirements

| Level | Icon | Name          | What It Covers                                    | Max per file |
|-------|------|---------------|---------------------------------------------------|--------------|
| PRE   | 🔑   | Prerequisites | Prior knowledge from other topics; dependency map | 5            |
| L0    | 🌱   | Orientation   | Why it exists, ecosystem map, what came before    | 5            |
| L1    | ★☆☆  | Foundational  | Core vocabulary, building blocks, setup           | 5            |
| L2    | ★★☆  | Working       | Common patterns, daily usage, idioms              | 5            |
| L3    | ★★☆+ | Intermediate  | Design decisions, trade-offs, internals           | 5            |
| L4    | ★★★  | Expert        | Production diagnostics, failure modes, tuning     | 5            |
| L5    | 🔥   | Architect     | Strategy, migration, governance, at-scale design  | 5            |
| L6    | 🔬   | Creator       | Theory, specification, research foundations       | 5            |
| META  | 🧠   | Meta-Skills   | Transferable thinking patterns                    | 5            |

> **Capacity rules (two separate constraints):**
>
> **Keywords per level** have no fixed ceiling. Topic complexity decides
> the count - a deep language may need 40+ L3 keywords; a micro-topic
> may need only 3. Generate as many as the topic genuinely requires.
>
> **Keywords per file** are difficulty-capped (non-negotiable):
> ★★★ (hard) = 1 per file, ★★☆ (medium) = 2 per file, ★☆☆ (easy) = 3 per file.
> This cap equals the generation batch size, so every file completes
> in a single call. L0/L1/META entries are ★☆☆; L2/L3/L6 are ★★☆;
> L4/L5 entries are ★★★. Split any level that exceeds its cap across
> multiple files named by descriptive subtopic (e.g.,
> `Java - L2 Collections.md`, `Java - L2 Streams.md`). Never split
> by sequence number ("Part 1", "Part 2").

**Total per topic: 30+ keywords minimum.** The upper bound is set by
topic complexity - not an arbitrary cap. All values in the Max per file
column above are 5. **One level per file - never mix levels.**

### File organization by level

| File pattern                   | Level | Purpose                                             |
|--------------------------------|-------|-----------------------------------------------------|
| `{Topic} - Prerequisites.md`   | PRE   | Dependency map - optional, complex topics only      |
| `{Topic} - L0 {Subtopic}.md`  | L0    | Why it exists, ecosystem, what came before          |
| `{Topic} - L1 {Subtopic}.md`  | L1    | Core vocabulary, building blocks, setup             |
| `{Topic} - L2 {Subtopic}.md`   | L2    | Working patterns - split when >2 keywords    |
| `{Topic} - L3 {Subtopic}.md`   | L3    | Design decisions - split when >2 keywords    |
| `{Topic} - L4 {Subtopic}.md`   | L4    | Production depth - 1 per file (★★★)          |
| `{Topic} - L5 Architecture.md` | L5    | Strategy, migration, at-scale governance            |
| `{Topic} - L6 Theory.md`       | L6    | Theory, specification, research - optional          |
| `{Topic} - META Patterns.md`   | META  | Transferable cross-domain thinking                  |

> **Rule:** one level per file, always. Never mix levels in a single file. When a level needs multiple files, name them
> by subtopic: `{Topic} - L2 {Subtopic}.md`.

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

Every keyword must illuminate one or more of these 10 dimensions. Across a topic, all 10 dimensions should be covered
collectively.

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

---

## Adding a new topic

1. Add a row to **Active Topics** above with status `planned`.
2. Plan keywords using the [Level Coverage Rubric](#level-coverage-rubric-mandatory). Cover PRE (if needed), L0–L6,
   META.
3. Plan files: one file per level. Use the [level-per-file pattern](#file-organization-by-level). Respect
   content-capacity limits. Split by subtopic when a level exceeds capacity.
4. Update status to `generating`, then `complete`.
5. Add the topic row to `docs/index.md`.
