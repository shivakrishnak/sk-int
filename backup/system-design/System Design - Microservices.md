---
layout: default
title: "System Design - Microservices"
parent: "System Design"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/system-design/microservices/
topic: System Design
subtopic: Microservices
keywords:
  - Monolith vs Microservices
  - Service Decomposition and Bounded Contexts
  - Inter-Service Communication
  - API Gateway and Service Discovery
  - Resilience Patterns
  - Event-Driven Architecture and CQRS
difficulty_range: medium to hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Monolith vs Microservices](#monolith-vs-microservices)
- [Service Decomposition and Bounded Contexts](#service-decomposition-and-bounded-contexts)
- [Inter-Service Communication](#inter-service-communication)
- [API Gateway and Service Discovery](#api-gateway-and-service-discovery)
- [Resilience Patterns](#resilience-patterns)
- [Event-Driven Architecture and CQRS](#event-driven-architecture-and-cqrs)

# Monolith vs Microservices

**TL;DR** - A monolith is a single deployable unit where all business logic shares one process and database. Microservices are independently deployable services that own their data and communicate over the network. Monolith-first is almost always the right starting point; microservices solve organizational scaling problems, not technical ones.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT (monolith at scale):**
30 developers pushing to one repo. A one-line CSS change requires redeploying the entire 2M-line application. Payment team's release is blocked by a search team bug. Friday deploys terrify everyone because blast radius is the entire system. Release cadence: once every 2 weeks instead of daily.

**THE REAL DRIVER:**
Microservices solve TEAM scaling, not primarily technical scaling. Conway's Law: your architecture will mirror your organization. 10 teams need 10 independently deployable services to move at their own pace.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Monolith: One big app does everything. Simple to build, hard to scale organizationally. Microservices: Many small apps, each doing one thing, talking over the network. Complex to build, allows teams to move independently.

**Level 2 - How to use it (junior developer):**

| Aspect        | Monolith                    | Microservices                        |
| ------------- | --------------------------- | ------------------------------------ |
| Deploy        | One unit, all-or-nothing    | Each service independently           |
| Data          | Shared database             | Database per service                 |
| Communication | Function calls (in-process) | Network calls (HTTP, gRPC, events)   |
| Consistency   | ACID transactions           | Eventual consistency (sagas)         |
| Debugging     | Stack trace, step-through   | Distributed tracing, log correlation |
| Team size     | 1-15 developers             | 15-500+ developers                   |

**Level 3 - How it works (mid-level engineer):**

**The migration spectrum:**

```
Monolith
  -> Modular Monolith (clear module boundaries)
    -> Distributed Monolith (worst of both worlds!)
      -> Microservices (independent deployment)
```

**Distributed Monolith (the anti-pattern):**
You split into services but they still deploy together, share a database, or have synchronous call chains. You got all the complexity of distributed systems with none of the benefits.

Signs you have a distributed monolith:

- Can't deploy Service A without deploying Service B
- Services share a database schema
- A single request touches 10+ services synchronously
- All services must be updated for a schema change

**When to migrate from monolith:**

1. Team size exceeds ~15 developers
2. Release cadence is bottlenecked by coordination
3. Different parts need different scaling (CPU vs memory)
4. You have clear bounded contexts

**Level 4 - Mastery (senior/staff+ engineer):**

**The Modular Monolith (the often-missed middle ground):**

```java
// Modular Monolith: separate modules, one deploy
com.company.orders/     (module)
com.company.payments/   (module)
com.company.shipping/   (module)
com.company.shared/     (shared kernel)

// Each module:
// - Has its own package/namespace
// - Owns its DB tables (no cross-module queries)
// - Communicates via defined interfaces
// - Can be extracted to a service later

// Module boundary enforcement:
@ArchTest
void modulesShouldNotAccessEachOther() {
    slices().matching("com.company.(*)..")
        .should().notDependOnEachOther()
        .check(classes);
}
```

Benefits of starting modular monolith:

- Simple deployment and debugging
- ACID transactions within the monolith
- Extract to microservice ONLY when team/scale demands it
- Clear boundaries make extraction easy when needed




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Start with modular monolith, extract to microservices when team size demands it
2. Microservices solve organizational scaling (team independence), not primarily technical scaling
3. Distributed monolith = worst of both worlds. Test: can each service deploy independently?

**Interview one-liner:**
"Microservices solve organizational scaling - independent teams need independent deployments. Start monolith, extract when team coordination becomes the bottleneck, never before you have clear bounded contexts."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Monolith vs Microservices. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: You're starting a new product with a team of 5. The CTO wants microservices "to scale from day 1." What's your advice?**

_Why they ask:_ Tests practical judgment and pushback skills.

_Strong answer:_

Strong pushback: Start with a modular monolith. Reasons:

1. **Premature distribution:** You don't know your domain boundaries yet. Getting service boundaries wrong is 10x more expensive to fix than refactoring a monolith.

2. **Team size:** 5 engineers don't need deployment independence. They can coordinate releases easily.

3. **Velocity:** Monolith iteration speed is 3-5x faster in early stage. No service mesh, no distributed tracing, no saga choreography, no eventual consistency bugs.

4. **Counter-proposal:** Modular monolith with enforced boundaries (ArchUnit tests). Each module owns its tables and exposes a clean interface. When team hits 15-20 people and modules have clear boundaries -> extract the first service.

5. **"Scale from day 1" is about infrastructure, not architecture.** Use cloud auto-scaling, CDN, managed databases. A single well-written monolith on Kubernetes can handle 100K+ QPS.

Red flags that DO warrant early microservices:

- Fundamentally different tech stacks needed (ML model in Python + API in Java)
- Third-party integration that needs isolation (payment processor with strict compliance)
- Wildly different scaling profiles from day 1 (real-time video processing vs REST API)

---

**Q2: What is a Distributed Monolith and how do you detect one?**

_Why they ask:_ Tests real-world experience with microservices gone wrong.

_Strong answer:_

A distributed monolith has the network boundary of microservices but the coupling of a monolith. You got the worst of both worlds: network latency, partial failures, complex debugging - but still can't deploy independently.

Detection criteria:

1. **Deploy together:** "We always deploy services A, B, and C at the same time"
2. **Shared database:** Multiple services read/write the same tables
3. **Synchronous chains:** Service A -> B -> C -> D in a single request path
4. **Shared libraries with business logic:** Updating the library forces all services to redeploy
5. **No independent testing:** Can't run Service A's tests without Services B and C running

Fix:

- Define clear ownership (one team = one service = one database)
- Replace synchronous chains with async events where possible
- Extract shared DB into per-service databases with data duplication
- Use consumer-driven contracts instead of shared libraries
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Service Decomposition and Bounded Contexts

**TL;DR** - Service decomposition splits a system into services aligned with business capabilities, using Domain-Driven Design's Bounded Context as the primary decomposition heuristic. A Bounded Context is a boundary within which a domain model is consistent and terms have unambiguous meaning.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Teams split services by technical layer (UI service, business logic service, data service) or by entity (UserService, OrderService, ProductService). Result: every feature touches every service. No team can ship independently.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Instead of splitting by technology (frontend/backend/database), split by business capability (ordering, payments, shipping). Each team owns the full stack for their capability.

**Level 2 - How to use it (junior developer):**

**Bounded Context example - e-commerce:**

```
"Product" means different things in different contexts:

Catalog Context:
  Product = name, description, images, categories

Inventory Context:
  Product = SKU, warehouse location, quantity

Pricing Context:
  Product = base price, discounts, tax rules

Shipping Context:
  Product = weight, dimensions, shipping class
```

Each context is a service with its own model. They share a product ID but have completely different schemas.

**Level 3 - How it works (mid-level engineer):**

**Decomposition heuristics (ordered by reliability):**

1. **Business capability** (most reliable): What does the business do? Order management, fulfillment, billing -> each is a service.

2. **Bounded context** (DDD): Where do domain terms change meaning? Where do different teams use different models for the same real-world thing?

3. **Team ownership** (Conway's Law): Which team would own this? 1 team = 1-3 services max.

4. **Change frequency** (less reliable): Things that change together belong together.

**Anti-patterns:**

- Entity services (CRUD per entity): `UserService`, `OrderService` -> becomes anemic, every feature is cross-service
- Technical layer split: Frontend Service, Logic Service, Data Service -> same coupling as monolith with network overhead
- Too small (nano-services): One function per service -> drowning in infrastructure

**Ideal size:** A service is a team's cognitive budget. 2-pizza team (5-8 people) owns 1-3 services.

**Level 4 - Mastery (senior/staff+ engineer):**

**Context Mapping (how bounded contexts interact):**

| Pattern               | Description                            | When                                             |
| --------------------- | -------------------------------------- | ------------------------------------------------ |
| Shared Kernel         | Two contexts share a small model       | Core domain shared between closely-related teams |
| Customer-Supplier     | Upstream provides, downstream consumes | Clear dependency direction                       |
| Anti-Corruption Layer | Translator between contexts            | Integrating with legacy or external systems      |
| Published Language    | Shared schema (events, API contracts)  | Public API / event bus                           |
| Separate Ways         | No integration                         | Completely independent domains                   |

**The Strangler Fig pattern (extraction from monolith):**

```
1. Identify bounded context to extract
2. Build new service alongside monolith
3. Route traffic gradually:
   - New features -> new service
   - Existing features -> migrate one endpoint at a time
4. Old code in monolith becomes dead code
5. Remove dead code after full migration

MonoLith [====ORDERS====] [PAYMENTS] [SHIPPING]
         v   route /orders/new to new service
New Svc  [Orders v2]
         v   migrate all order endpoints
MonoLith [===========] [PAYMENTS] [SHIPPING]
New Svc  [Orders v2 (complete)]
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Decompose by business capability + bounded context, never by entity or tech layer
2. "Product" means different things in different contexts - each context is a service boundary
3. Strangler Fig: extract from monolith one bounded context at a time
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Service Decomposition and Bounded Contexts. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: How do you decide the boundaries for your first microservice extraction from a monolith?**

_Why they ask:_ Tests practical decomposition judgment.

_Strong answer:_

Selection criteria for first extraction (prioritized):

1. **Independently deployable:** Has minimal dependencies on other code
2. **Different change frequency:** Changes weekly while rest changes monthly
3. **Different scaling needs:** CPU-intensive while rest is IO-bound
4. **Clear data ownership:** Has tables no other code touches
5. **Small blast radius:** Low risk if the extraction has bugs

Common good first extractions:

- **Notification service:** Independent, async, different scale profile
- **Authentication:** Well-defined boundary, rarely changes business logic
- **File processing:** CPU/memory intensive, different scaling profile

Bad first extractions:

- **The core domain:** Too many dependencies, unclear boundaries
- **Shared utilities:** Not a business capability, becomes a coupling point
- **The biggest module:** Too risky, too many integration points

Process:

1. Draw dependency graph of monolith modules
2. Find the module with fewest inbound dependencies
3. Define its API (what calls it? What does it call?)
4. Build new service, implement the API
5. Strangler Fig: route traffic gradually
6. Monitor error rates during cutover
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Inter-Service Communication

**TL;DR** - Services communicate synchronously (HTTP/REST, gRPC) for request-response patterns or asynchronously (message queues, events) for fire-and-forget and eventual consistency. Choose based on coupling tolerance: sync = tight temporal coupling, async = loose coupling but complexity.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
After splitting into microservices, services need to talk. Bad choice: synchronous chains of 8 services where any single failure cascades. Or: everything async where you can't get a response in time.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Sync: "Call and wait for response" (like a phone call). Async: "Send message, continue working, handle response later" (like email).

**Level 2 - How to use it (junior developer):**

| Pattern               | Protocol               | Use When                   |
| --------------------- | ---------------------- | -------------------------- |
| Request/Response      | REST, gRPC             | Need immediate answer      |
| Fire and forget       | Message queue          | Don't need response        |
| Publish/Subscribe     | Event bus (Kafka)      | Multiple consumers care    |
| Request/Reply (async) | Queue + correlation ID | Need answer, but decoupled |

```java
// Sync: REST call
Order order = restTemplate.getForObject(
    "http://inventory-service/api/stock/" + sku,
    InventoryResponse.class);

// Async: Publish event
kafkaTemplate.send("order-events",
    new OrderCreatedEvent(orderId, items));
// Don't wait for response
```

**Level 3 - How it works (mid-level engineer):**

**Sync vs Async trade-offs:**

| Aspect           | Synchronous                | Asynchronous                  |
| ---------------- | -------------------------- | ----------------------------- |
| Latency          | Cumulative (A+B+C)         | Parallel possible             |
| Coupling         | Temporal (both must be up) | Decoupled (queue buffers)     |
| Consistency      | Immediate                  | Eventual                      |
| Debugging        | Easier (request/response)  | Harder (trace through queues) |
| Failure handling | Cascading failures         | Retry from queue              |
| Throughput       | Limited by slowest service | Buffered, smooth              |

**gRPC vs REST:**

| Aspect          | REST (HTTP/JSON)         | gRPC (HTTP/2 + Protobuf)                     |
| --------------- | ------------------------ | -------------------------------------------- |
| Payload         | JSON (text, larger)      | Protobuf (binary, 3-10x smaller)             |
| Performance     | Good                     | Excellent (2-5x faster)                      |
| Streaming       | No (or WebSocket)        | Bidirectional streaming                      |
| Contract        | OpenAPI (optional)       | .proto file (required)                       |
| Browser support | Native                   | Needs proxy (gRPC-Web)                       |
| Debugging       | Easy (curl, Postman)     | Harder (need tooling)                        |
| Best for        | Public APIs, simple CRUD | Internal service-to-service, high-throughput |

**Level 4 - Mastery (senior/staff+ engineer):**

**The right mix (typical microservices system):**

```
External clients -> REST/GraphQL (API Gateway)
Service-to-service queries -> gRPC (low latency)
Commands/mutations -> Events via Kafka (decoupled)
Notifications -> Async (SQS/SNS)
```

**Avoiding synchronous chains:**

```
// BAD: Synchronous chain (O(n) latency, fragile)
Client -> API -> Order -> Inventory -> Payment
                                         |
                              Response waits for all

// GOOD: Orchestration with async steps
Client -> API -> Order Saga Orchestrator
                    |
          Publish: OrderCreated event
                    |
     +--------+--------+
     |        |        |
Inventory  Payment  Notification
(async)    (async)  (async)
     |        |
     +--------+
          |
   Saga completes -> respond to client
   (or webhook/polling for long processes)
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Sync for queries (need answer now), async for commands (fire and handle later)
2. gRPC for internal service-to-service (fast, typed), REST for external APIs
3. Avoid synchronous chains > 2 services deep - use async events or sagas
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Inter-Service Communication. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: A user places an order. It needs inventory check, payment, and shipping. Design the communication.**

_Why they ask:_ Tests communication pattern selection in real scenarios.

_Strong answer:_

**Requirement analysis:**

- User needs immediate feedback (order confirmed or rejected)
- Inventory check: must be synchronous (need to know before charging)
- Payment: must complete before confirming to user
- Shipping: can be async (happens later)

**Design: Hybrid sync + async:**

```
User -> POST /orders
  -> Order Service:
     1. SYNC: gRPC to Inventory Service
        (reserve stock, fail-fast if unavailable)
     2. SYNC: gRPC to Payment Service
        (charge card, fail-fast if declined)
     3. Return 201 Created to user
     4. ASYNC: Publish OrderConfirmed event
        -> Shipping Service subscribes
        -> Notification Service subscribes
        -> Analytics Service subscribes
```

Why this hybrid:

- Steps 1-2 sync: User needs immediate yes/no response
- Step 4 async: User doesn't wait for shipping label creation
- Compensation: If payment fails after inventory reserved -> release inventory
- Timeout: 5s for inventory, 10s for payment. If timeout -> fail order, release inventory
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# API Gateway and Service Discovery

**TL;DR** - An API Gateway is the single entry point for external clients, handling routing, auth, rate limiting, and protocol translation. Service Discovery enables services to find each other dynamically without hardcoded URLs, supporting horizontal scaling and rolling deployments.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Clients must know the address of every microservice (20+ URLs). Each service's URL changes on every deployment. Adding a new instance requires updating every caller's configuration. Authentication logic duplicated in every service.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
API Gateway: One front door for all external requests. Routes to the right service internally. Service Discovery: A phone book that services use to find each other.

**Level 2 - How to use it (junior developer):**

**API Gateway responsibilities:**

```
Client -> API Gateway -> Routes to correct service

Gateway handles:
- Authentication/Authorization
- Rate limiting
- Request routing (/api/orders -> Order Service)
- SSL termination
- Response caching
- Request/Response transformation
- API versioning
```

**Service Discovery flow:**

```
1. Service starts -> registers with discovery
   (IP, port, health endpoint)
2. Service A needs Service B:
   -> asks discovery: "Where is Service B?"
   -> gets: [10.0.1.5:8080, 10.0.1.6:8080]
   -> load balances across instances
3. Service B stops -> deregisters (or health check fails)
   -> removed from registry
```

**Level 3 - How it works (mid-level engineer):**

**API Gateway options:**

| Gateway              | Type                      | Best For                         |
| -------------------- | ------------------------- | -------------------------------- |
| Kong                 | Open source, plugin-based | General purpose, extensible      |
| AWS API Gateway      | Managed                   | AWS-native, serverless           |
| Spring Cloud Gateway | Java-native               | Spring ecosystem                 |
| Envoy + Istio        | Service mesh              | K8s, advanced traffic management |
| Nginx/HAProxy        | Reverse proxy             | Simple routing, high performance |

**Service Discovery patterns:**

| Pattern               | How                                     | Example                  |
| --------------------- | --------------------------------------- | ------------------------ |
| Client-side discovery | Client queries registry, picks instance | Eureka + Ribbon          |
| Server-side discovery | Load balancer queries registry          | K8s Service + kube-proxy |
| DNS-based             | DNS resolves to service instances       | Consul DNS, K8s CoreDNS  |

**Level 4 - Mastery (senior/staff+ engineer):**

**Backend for Frontend (BFF):**

```
Mobile App -> Mobile BFF -> Order Svc, User Svc
Web App -> Web BFF -> Order Svc, User Svc
Partner API -> Partner BFF -> Order Svc

Each BFF:
- Aggregates multiple service calls into one
- Tailors response format for its client
- Different auth (OAuth for web, API key for partners)
- Different rate limits
```

Why BFF over single gateway:

- Mobile needs smaller payloads, fewer fields
- Web needs server-rendered data, different auth flow
- Partner API needs stable contract, versioning
- Each BFF owned by the client team (not shared)

**In Kubernetes (no separate discovery needed):**

```yaml
# K8s Service IS the discovery + load balancer
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service
  ports:
    - port: 8080
# DNS: order-service.namespace.svc.cluster.local
# kube-proxy load balances across all pods
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. API Gateway = single entry for external traffic (auth, routing, rate limiting)
2. In K8s: built-in discovery via Services + CoreDNS (no Eureka needed)
3. BFF pattern: separate gateway per client type (mobile, web, partner)
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for API Gateway and Service Discovery. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Should authentication happen at the gateway or at each service?**

_Why they ask:_ Tests security architecture understanding.

_Strong answer:_

**Gateway-level authentication (verify identity):**

- Validate JWT signature and expiration
- Reject invalid tokens immediately (fast fail)
- Add user identity to request header (X-User-Id, X-Roles)
- Downstream services trust these headers

**Service-level authorization (verify permissions):**

- Each service checks: "Can this user do THIS action?"
- Order Service: "Can user X access order Y?" (ownership check)
- Admin Service: "Does user have ADMIN role?"

```
Client -> [JWT] -> API Gateway
  -> Validate JWT (signature, expiry, issuer)
  -> Extract: userId=42, roles=[USER]
  -> Forward: X-User-Id: 42, X-Roles: USER
  -> Order Service:
     -> Trust X-User-Id (gateway verified)
     -> Check: order.userId == 42? (authorization)
```

Why split:

- Gateway handles expensive crypto (JWT verification) once
- Services don't duplicate auth code
- But services OWN their authorization logic (business rules)
- Gateway never makes business decisions (only identity verification)

Security: Internal network must be trusted (or use mTLS between services). If attacker bypasses gateway, services should still validate the token.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Resilience Patterns

**TL;DR** - Resilience patterns (Circuit Breaker, Bulkhead, Retry, Timeout, Fallback) prevent cascading failures in distributed systems. Without them, one slow service consumes all threads/connections across the system, turning a partial failure into total system failure.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Payment service responds slowly (30s timeout). Order service has 200 threads, all waiting for payment. Order service becomes unresponsive. Cart service depends on order service - also dies. Notification service depends on cart - also dies. One slow service kills the entire system in 60 seconds.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Patterns that stop failures from spreading. If one service is sick, isolate it so it doesn't infect healthy services. Fail fast, protect resources, degrade gracefully.

**Level 2 - How to use it (junior developer):**

**The five core patterns:**

```
1. TIMEOUT: Don't wait forever
   "If no response in 2s, fail immediately"

2. RETRY: Try again for transient failures
   "Try 3 times with 200ms, 400ms, 800ms waits"

3. CIRCUIT BREAKER: Stop calling a dead service
   "After 50% failures in 10 calls, stop trying
    for 30s, then test with one call"

4. BULKHEAD: Isolate resources
   "Payment calls get max 20 threads.
    Even if all stuck, other features still work"

5. FALLBACK: Degrade gracefully
   "If recommendations service is down,
    show popular items instead"
```

**Level 3 - How it works (mid-level engineer):**

**Implementation with Resilience4j:**

```java
@Service
public class ProductService {

    @CircuitBreaker(name = "inventory",
        fallbackMethod = "inventoryFallback")
    @Retry(name = "inventory")
    @Bulkhead(name = "inventory")
    @TimeLimiter(name = "inventory")
    public CompletableFuture<Stock>
            checkStock(String sku) {
        return CompletableFuture.supplyAsync(
            () -> inventoryClient.getStock(sku));
    }

    private CompletableFuture<Stock>
            inventoryFallback(String sku,
            Throwable t) {
        // Return cached stock or "check in store"
        return CompletableFuture.completedFuture(
            Stock.unknown(sku));
    }
}
```

```yaml
resilience4j:
  circuitbreaker:
    instances:
      inventory:
        sliding-window-size: 10
        failure-rate-threshold: 50
        wait-duration-in-open-state: 30s
  retry:
    instances:
      inventory:
        max-attempts: 3
        wait-duration: 200ms
        exponential-backoff-multiplier: 2
        retry-exceptions:
          - java.io.IOException
          - java.util.concurrent.TimeoutException
  bulkhead:
    instances:
      inventory:
        max-concurrent-calls: 20
        max-wait-duration: 500ms
  timelimiter:
    instances:
      inventory:
        timeout-duration: 2s
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Pattern application order (outermost to innermost):**

```
Request
 -> Bulkhead (limit concurrency)
   -> Circuit Breaker (fail fast if service is down)
     -> Retry (retry transient failures)
       -> Timeout (don't wait forever)
         -> Actual service call
```

**Retry considerations:**

- Only retry idempotent operations (GET, PUT with idempotency key)
- Never retry POST without idempotency key (double-submit risk)
- Exponential backoff with jitter (prevent thundering herd)
- Budget: total timeout > (retries \* per-retry-timeout)

```java
// Jitter prevents thundering herd:
long delay = baseDelay * (long)Math.pow(2, attempt);
long jitter = ThreadLocalRandom.current()
    .nextLong(0, delay / 2);
Thread.sleep(delay + jitter);
```

**Bulkhead types:**

- **Thread pool bulkhead:** Separate thread pool per dependency (complete isolation)
- **Semaphore bulkhead:** Limit concurrent calls (lighter weight, same thread)
- **Connection pool bulkhead:** Separate HTTP client per dependency




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Always set timeouts (2-5s for sync calls) - never rely on default (∞)
2. Circuit breaker = "stop hammering a dead service, try again later"
3. Only retry idempotent operations. Always use exponential backoff with jitter.
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Resilience Patterns. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Your checkout service calls 4 downstream services. One is slow. Design the resilience strategy.**

_Why they ask:_ Tests systematic resilience thinking.

_Strong answer:_

Services: Inventory (critical), Payment (critical), Shipping (deferrable), Notifications (deferrable)

```
Checkout Service:
  Thread pool: 200 threads total

  Inventory Client:
    - Timeout: 2s (fast fail)
    - Retry: 2 attempts (idempotent read)
    - Circuit Breaker: 50% failure -> open 30s
    - Bulkhead: max 50 threads (25% of pool)
    - Fallback: reject order (can't sell without stock)

  Payment Client:
    - Timeout: 10s (payment gateways are slow)
    - Retry: 1 attempt (idempotent with key)
    - Circuit Breaker: 30% failure -> open 60s
    - Bulkhead: max 50 threads
    - Fallback: "payment pending, will confirm via email"

  Shipping Client:
    - Timeout: 5s
    - Retry: 3 attempts (idempotent)
    - Circuit Breaker: 50% failure -> open 30s
    - Bulkhead: max 30 threads
    - Fallback: queue for async processing (non-blocking)

  Notification Client:
    - Fire-and-forget via message queue
    - No bulkhead needed (async)
    - Retry: handled by queue (3 attempts)
```

Key principles:

- Critical path (inventory + payment) gets more threads but stricter timeouts
- Deferrable operations (shipping, notifications) are async - don't block checkout
- Total bulkhead allocation < thread pool size (reserve capacity)
- Different timeout/retry per dependency (payment gateway is inherently slower)
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Event-Driven Architecture and CQRS

**TL;DR** - Event-Driven Architecture (EDA) decouples services by communicating through events (immutable facts about what happened). CQRS (Command Query Responsibility Segregation) separates read and write models for independent scaling and optimization. Combined, they enable highly scalable, loosely-coupled systems.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Order Service needs to notify Inventory, Payment, Shipping, Analytics, Recommendations, and Email services when an order is placed. Direct calls create 6 synchronous dependencies. Adding a 7th consumer requires changing Order Service code. Read-heavy endpoints (product listing) compete for resources with write-heavy endpoints (order processing).
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
EDA: Instead of "calling" other services, publish "this happened" events. Anyone interested subscribes. CQRS: Use one database optimized for writes, another optimized for reads.

**Level 2 - How to use it (junior developer):**

**Event-Driven Architecture:**

```java
// Order Service publishes event:
kafkaTemplate.send("order-events",
    new OrderPlacedEvent(orderId, items, total));

// Multiple services consume independently:
// Inventory: reserve stock
// Payment: initiate charge
// Analytics: update metrics
// Email: send confirmation
// Recommendations: update model

// Adding new consumer = zero changes to publisher
```

**CQRS (simplified):**

```
Commands (writes):       Queries (reads):
  POST /orders          GET /orders?status=pending
  -> Normalized DB      -> Denormalized read DB
  -> Complex domain     -> Flat, pre-joined views
  -> Few writes/sec     -> Many reads/sec
  -> Strong consistency -> Eventually consistent
```

**Level 3 - How it works (mid-level engineer):**

**Event types:**

| Type              | Example         | Characteristics             |
| ----------------- | --------------- | --------------------------- |
| Domain Event      | OrderPlaced     | Business fact, immutable    |
| Integration Event | order.placed.v1 | Cross-service communication |
| Command           | PlaceOrder      | Request to do something     |
| Notification      | EmailSent       | Side-effect confirmation    |

**CQRS implementation:**

```
Write Model (Command side):
  [Order] -normalize-> [order, order_item,
                        payment, shipment]
  -> PostgreSQL (ACID, relationships)

Sync mechanism:
  -> CDC (Debezium) or Domain Events
  -> Kafka topic: order-events

Read Model (Query side):
  Consumer builds materialized view:
  [OrderListView] = pre-joined, denormalized
  -> Elasticsearch (full-text search)
  -> Redis (fast key-value lookup)
  -> DynamoDB (scalable queries)
```

**Event Sourcing (often paired with CQRS):**

```
Instead of storing current state:
  Order { status: SHIPPED, total: $100 }

Store all events:
  1. OrderCreated { items: [...], total: $100 }
  2. PaymentReceived { amount: $100 }
  3. OrderShipped { trackingId: "ABC" }

Current state = replay all events
History: complete audit trail
Undo: replay without event #3
```

**Level 4 - Mastery (senior/staff+ engineer):**

**When to use CQRS (it adds complexity!):**

| Use CQRS when...                   | Don't use when...         |
| ---------------------------------- | ------------------------- |
| Read/write ratio > 100:1           | Simple CRUD               |
| Different read/write models needed | Same model works for both |
| Different scaling needs            | Uniform load              |
| Complex domain (DDD)               | Anemic domain model       |
| Audit trail required               | Simple operations         |

**Event Sourcing pitfalls:**

1. **Schema evolution:** Events are immutable, but schemas change. Need upcasting.
2. **Event replay time:** 10M events for one aggregate = slow reconstruction. Solution: snapshots every N events.
3. **Eventual consistency:** Read model is behind write model. UI might show stale data immediately after write.
4. **Complexity:** Simple CRUD becomes 5x more code. Only justified for complex domains.

**The Outbox Pattern (reliable event publishing):**

```sql
BEGIN;
  INSERT INTO orders (id, status) VALUES (...);
  INSERT INTO outbox (event_type, payload)
    VALUES ('OrderCreated', '{"id":...}');
COMMIT;
-- Debezium CDC reads outbox table
-- Publishes to Kafka
-- Guarantees at-least-once delivery
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. EDA: Publish events -> consumers subscribe. Adding consumers doesn't change publisher.
2. CQRS: Separate read model (optimized for queries) from write model (optimized for domain logic)
3. Use Outbox Pattern for reliable event publishing (same transaction as business write)

**Interview one-liner:**
"Events decouple services by replacing direct calls with published facts. CQRS separates read/write models for independent optimization. Combined with the Outbox pattern for reliable event publishing, you get scalable eventual consistency."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Event-Driven Architecture and CQRS. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Design an event-driven order processing system. How do you handle failures and ensure exactly-once processing?**

_Why they ask:_ Tests practical EDA implementation knowledge.

_Strong answer:_

**Architecture:**

```
Order API -> Write to Orders DB + Outbox
  -> Debezium CDC -> Kafka: order-events
    -> Inventory Consumer (reserve)
    -> Payment Consumer (charge)
    -> Notification Consumer (email)
```

**Handling failures:**

1. **Producer failure (Order Service crashes after DB write):**
   - Outbox pattern: event is in the same DB transaction
   - Debezium CDC captures from WAL (even if app crashed)
   - Guaranteed: if order is committed, event will be published

2. **Consumer failure (Payment crashes mid-processing):**
   - Kafka offset not committed until processing complete
   - On restart: message re-delivered (at-least-once)
   - Consumer must be idempotent:

   ```java
   public void handle(OrderCreatedEvent event) {
       if (paymentRepo.existsByOrderId(event.orderId()))
           return; // Already processed - idempotent
       processPayment(event);
       paymentRepo.save(event.orderId(), result);
       // THEN commit Kafka offset
   }
   ```

3. **Exactly-once semantics:**
   - True exactly-once is impossible across systems
   - Pattern: at-least-once delivery + idempotent consumers = effectively-once
   - Idempotency key: orderId (natural) or eventId (generated)
   - Deduplication window: store processed event IDs for 7 days

**Q2: Your read model is 30 seconds behind the write model. A user creates an order then immediately navigates to "My Orders" and doesn't see it. How do you handle this?**

_Why they ask:_ Tests eventual consistency UX handling.

_Strong answer:_

Options (from simplest to most complex):

1. **Write-through to read model (if same service):**
   After write, synchronously update the read model too. Breaks pure CQRS but solves the problem for the writing user.

2. **Client-side optimistic update:**
   Frontend adds the order to the UI immediately after 201 response. Background sync corrects if needed.

3. **Causal consistency via version token:**

   ```
   POST /orders -> returns {orderId, version: 42}
   GET /orders?afterVersion=42
   -> Read model waits until it has processed v42
   -> Or routes to primary/write DB for this user
   ```

4. **Read-your-writes pattern:**
   For 10 seconds after any write, route that user's reads to the write model (primary DB). After 10s, read model has caught up.

Best practice: Combine (2) and (4). Frontend shows optimistic state. Backend ensures read-your-writes for the writing user. Other users see eventual consistency (acceptable - they weren't watching).
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]
