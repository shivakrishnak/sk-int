---
layout: default
title: "Quarkus - L0 Orientation"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 1
permalink: /quarkus/l0-orientation/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Quarkus Ecosystem Overview](#quarkus-ecosystem-overview) | foundational |
| 2 | [Why Quarkus Exists - Kubernetes-Native Java](#why-quarkus-exists---kubernetes-native-java) | medium |
| 3 | [Quarkus vs Spring Boot vs Micronaut](#quarkus-vs-spring-boot-vs-micronaut) | high |
| 4 | [Quarkus Build-Time Augmentation Philosophy](#quarkus-build-time-augmentation-philosophy) | high |

---

# Quarkus Ecosystem Overview

**Interview Weight:** foundational - Context question.
Every Quarkus interview starts here.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus is a Kubernetes-native Java framework built
> on top of Jakarta EE standards (CDI, JAX-RS/RESTEasy,
> JPA/Hibernate, MicroProfile). It achieves fast startup
> and low memory via build-time augmentation: processing
> CDI, configuration, and ORM metadata at build time
> rather than runtime. Created by Red Hat in 2019.
> Primary use cases: Kubernetes microservices, AWS
> Lambda, serverless, and workloads where memory and
> startup time are constrained.

**3 minutes (Senior):**

> Core components:
>
> CDI implementation: ArC (Augmented Runtime Container)
>   CDI beans, producers, interceptors processed at
>   build time. No dynamic proxy generation.
>
> HTTP/REST: RESTEasy Reactive (preferred) or
>   RESTEasy Classic (blocking)
>   RESTEasy Reactive: Vert.x-based, non-blocking
>   JAX-RS annotations: @GET, @POST, @Path, @QueryParam
>
> ORM/Data:
>   Hibernate ORM (JPA standard)
>   Panache: active record and repository pattern
>   Hibernate Reactive + Mutiny for reactive
>   Panache Reactive for reactive active record
>
> Configuration:
>   MicroProfile Config specification
>   application.properties (primary)
>   Profiles: %dev, %test, %prod
>
> Extensions ecosystem:
>   ~600 official extensions, ~200 community
>   Each extension integrates a library AND adds
>   build-time processing for that library
>
> Tooling:
>   Quarkus CLI (recommended)
>   Maven/Gradle plugins
>   Quarkus Dev Mode: live reload without restart
>
> Native image:
>   GraalVM native-image via quarkus build --native
>   Extensions provide native configuration
>   (reflection, resources) automatically

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about what Quarkus
is and what it's for."

**(2) First principles:** "Java frameworks exist to
provide DI, HTTP serving, data access. Quarkus does
all this using Jakarta EE standards, optimized for
cloud-native deployment."

**(3) Bridge:** "Quarkus is Spring Boot for
Jakarta EE with a cloud-native focus. Same concepts
(DI, HTTP, JPA) but optimized for Kubernetes and
Lambda startup."

---

### 🎓 Answers by Seniority

**Junior:** "Quarkus is a Java framework from Red Hat.
Uses CDI for dependency injection, RESTEasy for HTTP,
Hibernate/Panache for data. Fast startup via build-time
processing."

**Senior:** "Quarkus is notable for two things: first,
it uses existing Java standards (CDI, JAX-RS, JPA)
rather than custom APIs. Second, it extends those
standards with build-time augmentation - processing
CDI at build time instead of runtime. This is the
mechanism for both fast startup and GraalVM native
image support."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Framework overview, core components |
| Senior | 5 min | Build-time augmentation concept, extension model |

---

**[SENIOR] Q1 - What is the Quarkus Extension system
and why does it exist?**

*Why they ask:* Extensions are Quarkus's architecture.

Every library that works with Quarkus needs two things:
1. The runtime dependency (the library itself)
2. A Quarkus extension (adds build-time processing)

Without the extension: the library works but doesn't
get build-time optimization. Hibernate without the
Quarkus Hibernate ORM extension would require manual
reflection configuration for GraalVM native image.

With the extension: the extension registers all
necessary reflection, resources, and configurations
for both JVM and native builds automatically.

Why this matters:
- Hibernate extension: generates Hibernate ORM config
  at build time (schema validation pre-computed)
- Jackson extension: registers DTOs for reflection
  automatically
- REST Client Reactive extension: generates client
  implementations at build time

Developer experience: add the extension, the library
works correctly in JVM and native modes without manual
configuration.

*What separates good from great:* Extensions are
build-time processors, not just dependencies.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Core components, extension system. |
| Hiring Manager | What is Quarkus and why are we considering it? |
| Bar Raiser | Extension architecture, build-time vs runtime processing. |
| Peer Engineer | "We had a library without a Quarkus extension. Spent 2 days writing reflection config. Extension-based libraries save all that." |

---

---

# Why Quarkus Exists - Kubernetes-Native Java

**Interview Weight:** medium - Motivation question.
Shows you understand why it was created, not just how to use it.

---

### 🎯 Model Answer

**30 seconds:**

> Java's JVM startup time and memory footprint were
> designed for long-running server processes, not
> Kubernetes pods (which start and stop frequently)
> or Lambda functions (charged per invocation). Quarkus
> was created by Red Hat in 2019 to give Java first-class
> support for cloud-native workloads: fast startup
> (<1s JVM, <100ms native), low RSS memory (50MB native
> vs 500MB JVM), and native image compilation via GraalVM.

**3 minutes (Senior):**

> The problem Quarkus solves:
>
> Traditional Java (Spring Boot) in Kubernetes:
>   - Pod startup: 5-30 seconds
>   - Rolling deploy of 10 pods: 50-300 seconds
>   - Memory per pod: 300-500MB
>   - Lambda cold start: 2-5 seconds
>   - Lambda pricing: pay for cold start time
>
> Go/Node.js in Kubernetes:
>   - Pod startup: <500ms
>   - Memory per pod: 30-100MB
>   - Lambda cold start: <100ms
>
> Java talent + cloud-native efficiency → Quarkus (and Micronaut).
>
> Quarkus's approach:
>
> Build-time augmentation (same concept as Micronaut AOT):
>   CDI bean graph computed at build time.
>   No ClassLoader scanning at startup.
>   Hibernate ORM schema validated at build time.
>   REST client implementations generated at build time.
>
> GraalVM native image:
>   Compiles to platform binary.
>   No JVM at runtime.
>   JVM startup (200-400ms) eliminated.
>   Image heap: pre-initialized singleton objects.
>
> Developer experience preservation:
>   Same CDI/JAX-RS/JPA APIs developers know.
>   Quarkus handles the optimization.
>   Dev Mode: live reload during development.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about why Quarkus
was created - what problem it solves."

**(2) First principles:** "Java's historical runtime
model isn't suited for ephemeral cloud workloads.
Quarkus adapts Java for cloud-native usage patterns."

**(3) Bridge:** "Quarkus is Java's answer to Go and
Node.js in cloud environments - same Java code, cloud-native
operational characteristics."

---

### 🎓 Answers by Seniority

**Junior:** "Quarkus was created to make Java applications
start faster and use less memory - important for
Kubernetes and AWS Lambda."

**Senior:** "The economics drove Quarkus's creation:
Lambda pricing is per-invocation-millisecond. A 3-second
Java cold start costs 30x more than a 100ms native
cold start. Kubernetes density: 50MB native vs 500MB
JVM = 10x more pods per node. Same team, 10x more
throughput per hardware dollar."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Problem statement, cloud-native requirements |
| Senior | 5 min | Economic drivers, JVM vs native trade-off |

---

**[SENIOR] Q1 - Is Quarkus always faster than
Spring Boot?**

*Why they ask:* Critical thinking test - not just
hype-driven answers.

No. Quarkus is faster for: startup time and memory
at start.

Quarkus is NOT faster for: peak throughput (sustained
CPU-intensive work). JVM JIT compilation profile-guides
hot code. Quarkus native image has no JIT. For sustained
CPU-bound work: JVM Spring Boot may outperform Quarkus
native image after warmup.

Quarkus JVM mode (not native): similar throughput to
Spring Boot after JIT warmup. Startup is faster but
peak throughput is comparable.

Use case where Quarkus native excels:
- Lambda functions (invocations are short, cold starts
  matter)
- Kubernetes sidecars (memory-constrained)
- Auto-scaling services (scale to 0 and back)

Use case where JVM Spring Boot may be better:
- Monolithic services with high sustained CPU usage
- Batch processing
- Services with complex reflection-dependent libraries

*What separates good from great:* Distinguishing
startup performance (Quarkus/Micronaut win) from
sustained throughput (JVM with JIT can win).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Problem statement, build-time augmentation concept. |
| Hiring Manager | Why are we considering Quarkus? Business case. |
| Bar Raiser | JIT vs AOT sustained throughput, economic calculation. |
| Peer Engineer | "We benchmarked: native Quarkus cold start 80ms vs Spring Boot 4s. Lambda bill dropped 60%." |

---

---

# Quarkus vs Spring Boot vs Micronaut

**Interview Weight:** high - Comparison questions
are standard. Shows ability to make informed framework
decisions.

---

### 🎯 Model Answer

**30 seconds:**

> All three are cloud-native Java frameworks targeting
> fast startup and low memory. Key differences:
> Spring Boot uses annotation-driven runtime DI
> (mature ecosystem, best library support). Micronaut
> uses compile-time DI via annotation processing
> (custom DI model, no CDI standard). Quarkus uses
> build-time CDI augmentation (CDI standard compliant,
> MicroProfile support, Red Hat backing). For teams
> familiar with CDI/Jakarta EE: Quarkus. For Spring
> teams: Spring Boot or Spring + Spring AOT. For
> greenfield with max performance focus: Micronaut or Quarkus.

**3 minutes (Senior):**

> Technical differences:
>
> Dependency Injection:
>   Spring Boot: Spring IoC (custom, annotation-driven)
>   Micronaut: custom compile-time DI (JSR-330 inspired)
>   Quarkus: CDI 4.0 (Jakarta standard, ArC container)
>
> Build-time processing:
>   Spring Boot: runtime reflection (Spring AOT optional)
>   Micronaut: compile-time annotation processing
>   Quarkus: build-time augmentation (Quarkus build step)
>
> HTTP layer:
>   Spring Boot: Spring MVC (Tomcat) or WebFlux (Reactor)
>   Micronaut: Micronaut HTTP (Netty, custom)
>   Quarkus: RESTEasy Reactive (Vert.x, JAX-RS)
>
> Reactive:
>   Spring Boot: Project Reactor (Mono/Flux)
>   Micronaut: RxJava, Reactor, CompletableFuture
>   Quarkus: SmallRye Mutiny (Uni<T>, Multi<T>)
>
> Standards compliance:
>   Spring Boot: partial Jakarta EE
>   Micronaut: minimal (JSR-330 for DI)
>   Quarkus: CDI 4.0, MicroProfile, JAX-RS, JPA
>
> Ecosystem:
>   Spring Boot: largest (thousands of starters)
>   Micronaut: medium (~500 extensions)
>   Quarkus: medium-large (~600 extensions)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Quarkus,
Spring Boot, and Micronaut compare and when to choose each."

**(2) First principles:** "All three solve the same
problem (DI, HTTP, data access) with different approaches.
The choice depends on team expertise, ecosystem needs,
and performance requirements."

**(3) Bridge:** "Choosing between these frameworks
is like choosing between three cars with the same
destination capability but different designs. The
best choice depends on who's driving and the road."

---

### ⚖️ Comparison Table

| Aspect | Spring Boot | Micronaut | Quarkus |
|---|---|---|---|
| DI standard | Spring IoC | Custom (JSR-330 inspired) | CDI 4.0 (Jakarta) |
| HTTP | Spring MVC/WebFlux | Micronaut HTTP | RESTEasy Reactive |
| Reactive types | Mono/Flux (Reactor) | Mono/Flux/Single | Uni/Multi (Mutiny) |
| Build-time DI | Optional (Spring AOT) | Yes (APT) | Yes (augmentation) |
| Standards | Partial Jakarta EE | Minimal | Full MicroProfile |
| Native image | Spring AOT (some config) | Mostly automatic | Extensions handle it |
| Dev Mode | Spring DevTools | Not as seamless | Quarkus Dev Mode (live reload) |
| JPA | Spring Data JPA | Micronaut Data JPA | Hibernate ORM + Panache |

---

### 🎓 Answers by Seniority

**Junior:** "Quarkus uses CDI (Jakarta standard), Spring
Boot uses Spring DI (custom). Quarkus is backed by
Red Hat. Both support native image. Quarkus is better
for Jakarta EE familiarity."

**Senior:** "The reactive library difference is
significant: Micronaut uses Reactor (Mono/Flux),
Quarkus uses Mutiny (Uni/Multi). Mutiny has a
different API (smallrye-mutiny). If your team is
Reactor-trained, Micronaut may be more natural.
If your team knows CDI from Java EE, Quarkus is
the clear choice."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | DI comparison, reactive library, standards compliance |
| Staff | 10 min | Framework selection criteria, migration paths |

---

**[SENIOR] Q1 - If a team is migrating from a Spring
Boot monolith, which framework should they choose
for new microservices?**

*Why they ask:* Practical decision question.

Analysis:

Spring Boot → new services:
Pros: same framework, team knowledge transfers fully,
same security model, Spring Batch/Integration available.
Cons: same startup/memory characteristics.

Spring Boot + Spring AOT → native:
Pros: same code, native image possible with Spring AOT.
Cons: Spring AOT doesn't cover all use cases (some
CGLIB, some reflection still needed).

Spring Boot → Quarkus:
Pros: better native image support, CDI is a known standard.
Cons: team must learn Quarkus DI (CDI vs Spring IoC),
new reactive library (Mutiny vs Reactor), new security
model.

Spring Boot → Micronaut:
Pros: simpler DI model, good native support.
Cons: not standards-based CDI, different reactive library.

Recommendation framework:
1. New services that must integrate with existing
   Spring services: Spring Boot (shared concepts).
2. New greenfield services with Lambda/serverless:
   Quarkus or Micronaut (native image first-class).
3. Team familiar with Jakarta EE/CDI: Quarkus.
4. Team has no framework expertise: either Quarkus
   or Micronaut (comparable ramp-up time).

*What separates good from great:* Considering team
learning cost alongside technical capabilities.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | DI model, reactive library, standards. |
| Hiring Manager | Which framework should we choose? |
| Bar Raiser | Migration cost analysis, team expertise factor. |
| Peer Engineer | "Our team had Jakarta EE background. Quarkus felt natural from day 1." |

---

---

# Quarkus Build-Time Augmentation Philosophy

**Interview Weight:** high - This is the core
differentiator of Quarkus. Tested at senior level
to verify deep understanding.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus build-time augmentation is a build step
> that runs before the application is packaged. During
> augmentation: CDI beans are discovered and processed,
> Hibernate ORM schema is validated, REST endpoints
> are analyzed, extension-specific code is generated.
> The results are stored in the quarkus-run.jar or
> compiled into the native image. At runtime: no CDI
> scanning, no schema analysis - only execution of
> pre-computed metadata.

**3 minutes (Senior):**

> Augmentation phases:
>
> Phase 1: Static init (at augmentation time):
>   Extension DeploymentProcessors run.
>   Each extension processes its annotations.
>   CDI ArC analyzes all beans and generates
>   a CDI container at build time.
>   Hibernate ORM: validates schema, generates
>   enhanced entity classes.
>   REST: generates method dispatchers.
>
> Phase 2: Runtime init (at startup):
>   Load pre-computed augmentation results.
>   Initialize DB connections (DataSource).
>   Bind HTTP server to port.
>   Only dynamic/environment-specific work.
>
> Extension architecture:
>   Each extension has two parts:
>   - deployment: BuildStep processors (augmentation)
>   - runtime: beans used at runtime
>
>   BuildItem: unit of augmentation data.
>   BuildStep: consumes and produces BuildItems.
>   Example: HibernateOrmProcessor consumes entity
>   class list (EntityClassBuildItem), produces
>   JPA config (JpaModelBuildItem).
>
> Comparison:
>   Spring: classpath scan at startup (runtime).
>   Micronaut: annotation processing at compile time.
>   Quarkus: augmentation at build time (after compile).
>
> When augmentation runs:
>   mvn package: runs augmentation, produces JAR
>   quarkus build --native: augmentation + native compile
>   quarkus dev: augmentation + dev mode (hot reload)
>
> Augmentation output:
>   quarkus-run.jar: launcher
>   quarkus-app/: augmented application classes
>   quarkus-native-runner: native binary (if native)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Quarkus's
build-time augmentation works mechanically."

**(2) First principles:** "Build time is before
deployment. Anything computed at build time is paid
once, not per restart. Augmentation moves startup
computation to build time."

**(3) Bridge:** "Augmentation is Quarkus's equivalent
of Micronaut's annotation processing, but running
at Maven package time rather than inside javac."

---

### 🎓 Answers by Seniority

**Junior:** "Quarkus processes CDI and configuration
at build time (maven package). When the app starts,
the CDI container is already built."

**Senior:** "Augmentation has two phases: static init
(before JAR creation) and runtime init (at JVM startup).
Static init processes CDI, generates entity enhancers,
validates REST contracts. Runtime init only does the
dynamic parts: DB connections, port binding. This
is why Quarkus starts fast."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | Augmentation phases, extension architecture |
| Staff | 10 min | BuildItem/BuildStep model, extension development |

---

**[STAFF] Q1 - How does the Quarkus augmentation
model enable extensions to support native image
without manual configuration?**

*Why they ask:* Understanding extension architecture.

Without extensions: GraalVM native-image requires
reflection configuration (reflect-config.json) for
every class accessed reflectively. Manually maintaining
this is error-prone and framework-specific.

With Quarkus extensions:
Each extension's BuildStep registers its reflection
needs during augmentation:
```java
@BuildStep
ReflectiveClassBuildItem registerHibernateClasses(
        CombinedIndexBuildItem index) {
    // Find all @Entity classes
    List<String> entityClasses = index.getIndex()
        .getAnnotations(DotName.createSimple(
            "jakarta.persistence.Entity"))
        .stream()
        .map(ann -> ann.target()
            .asClass()
            .name()
            .toString())
        .collect(toList());

    // Register ALL entity classes for reflection
    // Native image: no manual reflect-config needed
    return ReflectiveClassBuildItem
        .builder(entityClasses.toArray(new String[0]))
        .methods().fields()
        .build();
}
```

During native image build:
Quarkus collects all ReflectiveClassBuildItems from all
extension BuildSteps and generates the reflect-config.json
automatically. Developer adds @Entity: extension handles
the reflection registration.

*What separates good from great:* BuildStep producing
ReflectiveClassBuildItem as the mechanism (not magic).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Augmentation phases, extension architecture. |
| Hiring Manager | Build-time processing = reliable native image. |
| Bar Raiser | BuildItem/BuildStep model, native image reflection automation. |
| Peer Engineer | "Quarkus Hibernate extension handles all entity reflection. Zero manual reflect-config for our 80 entities." |
