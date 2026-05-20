---
layout: default
title: "Microservices - Decomposition and DDD"
parent: "Microservices"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/microservices/decomposition-ddd/
topic: Microservices
subtopic: Decomposition and DDD
keywords:
  - Service Decomposition
  - Domain-Driven Design (DDD)
  - Bounded Context
  - Aggregate
  - Ubiquitous Language
  - Anti-Corruption Layer
difficulty_range: medium to hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Service Decomposition](#service-decomposition)
- [Domain-Driven Design (DDD)](#domain-driven-design-ddd)
- [Bounded Context](#bounded-context)
- [Aggregate](#aggregate)
- [Ubiquitous Language](#ubiquitous-language)
- [Anti-Corruption Layer](#anti-corruption-layer)

# Service Decomposition

**TL;DR** - Service decomposition determines how to split a system into microservices. The primary heuristic is business capability alignment using DDD's Bounded Contexts, not technical layers or entity-per-service. Getting boundaries wrong is the #1 reason microservices projects fail.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Teams split services by technical layer (UI service, business logic service, data service) or by entity (UserService, OrderService, ProductService). Every feature touches every service. No team can ship independently. You built a distributed monolith.
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
Instead of splitting by technology (frontend/backend/database), split by what the business DOES (ordering, payments, shipping). Each team owns the full stack for their business area.

**Level 2 - How to use it (junior developer):**

**Decomposition heuristics (best to worst):**

| Approach                      | Example                                                | Quality |
| ----------------------------- | ------------------------------------------------------ | ------- |
| Business capability           | "Order Management" service                             | Best    |
| Bounded Context (DDD)         | "Pricing" vs "Catalog" (same product, different model) | Best    |
| Subdomain                     | Core/Supporting/Generic domains                        | Good    |
| Team ownership (Conway's Law) | 1 team = 1-3 services                                  | Good    |
| Entity/Resource               | UserService, OrderService                              | Poor    |
| Technical layer               | Frontend Service, Data Service                         | Worst   |

**Anti-pattern: Entity services (CRUD per entity)**

```
// BAD: Entity-per-service
UserService     -> CRUD on users table
OrderService    -> CRUD on orders table
ProductService  -> CRUD on products table

Problem: "Place Order" touches ALL three services.
Every feature is cross-service. No team independence.

// GOOD: Capability-per-service
OrderManagement -> handles entire order lifecycle
  (creates order, validates items, reserves stock,
   stores order + line items)
  Owns: orders table, line_items table
```

**Level 3 - How it works (mid-level engineer):**

**The decomposition process:**

```
Step 1: Event Storming (workshop with domain experts)
  Identify domain events:
  "OrderPlaced", "PaymentReceived",
  "InventoryReserved", "ItemShipped"

Step 2: Identify aggregates
  Group events around the entities they affect:
  Order aggregate: OrderPlaced, OrderConfirmed
  Payment aggregate: PaymentReceived, PaymentRefunded

Step 3: Draw bounded contexts
  Cluster aggregates that share a model:
  Order Context: Order, LineItem, OrderStatus
  Payment Context: Payment, Refund, PaymentMethod

Step 4: Map contexts to services
  Each bounded context = one service (or one team)
  Order Service, Payment Service, Shipping Service

Step 5: Define interfaces
  Commands: PlaceOrder, CancelOrder
  Events: OrderPlaced, OrderShipped
  Queries: GetOrderStatus, ListOrders
```

**Service size heuristic:**

- Too small (nano-services): one function per service. Infrastructure overhead overwhelms value.
- Too large: can't deploy independently, multiple teams contend.
- Just right: one team (5-8 people) owns 1-3 services. Each service represents a complete business capability.

**Level 4 - Mastery (senior/staff+ engineer):**

**Decomposition by subdomain type (DDD strategic design):**

| Type        | Definition                        | Investment                            | Example                           |
| ----------- | --------------------------------- | ------------------------------------- | --------------------------------- |
| Core domain | Competitive advantage             | Maximum (best engineers, custom code) | Recommendation algorithm          |
| Supporting  | Necessary but not differentiating | Moderate (build or buy)               | Customer support ticketing        |
| Generic     | Commodity                         | Minimum (buy/SaaS)                    | Email sending, payment processing |

**Rules for initial decomposition:**

1. Start coarse-grained (fewer, larger services)
2. Split when a team can't ship independently
3. Merge when two services always deploy together
4. Never split in the middle of a transaction boundary




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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Service Decomposition. Otherwise remove this section.]
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

**Selection criteria for first extraction (prioritized):**

1. **Independently deployable:** Has minimal dependencies on other monolith code
2. **Different change frequency:** Changes weekly while rest changes monthly
3. **Different scaling needs:** CPU-intensive while rest is I/O-bound
4. **Clear data ownership:** Has tables no other code touches
5. **Small blast radius:** Low risk if the extraction has bugs

**Good first extractions:**

- Notification service (independent, async, different scale profile)
- File processing service (CPU-intensive, clear boundary)
- Authentication service (well-defined API, rarely changes business logic)

**Bad first extractions:**

- The core domain (too many dependencies, unclear boundaries)
- Shared utilities (not a business capability, becomes a coupling point)
- The biggest module (too risky, too many integration points)

**Process:**

1. Draw dependency graph of monolith modules
2. Find the module with fewest inbound dependencies
3. Define its API contract
4. Build new service, implement the contract
5. Strangler Fig: route traffic gradually (5% -> 100%)
6. Monitor error rates during cutover
7. Remove dead code from monolith after full migration
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

# Domain-Driven Design (DDD)

**TL;DR** - DDD is a software design approach that models complex business domains by aligning code structure with business language. It provides two levels: Strategic DDD (bounded contexts, context maps - for service boundaries) and Tactical DDD (entities, value objects, aggregates - for internal design). In microservices, Strategic DDD is the primary tool for decomposition.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Domain-Driven Design (DDD) was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
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
Write code using the same words the business uses. If the business says "Place Order," code has `placeOrder()`. Structure your system around business concepts, not technical ones.

**Level 2 - How to use it (junior developer):**

**Strategic DDD (system level - WHERE to draw boundaries):**

- Bounded Context = service boundary
- Context Map = how services interact
- Ubiquitous Language = shared vocabulary within a context

**Tactical DDD (code level - HOW to model within a service):**

- Entity = has identity and lifecycle (Order, User)
- Value Object = defined by attributes, immutable (Money, Address)
- Aggregate = transactional boundary (Order + LineItems)
- Repository = persistence abstraction
- Domain Event = something that happened (OrderPlaced)
- Domain Service = logic spanning multiple entities

**Level 3 - How it works (mid-level engineer):**

**The power of Bounded Contexts:**

"Product" means different things in different contexts:

```
Catalog Context:
  Product = name, description, images, categories

Inventory Context:
  Product = SKU, warehouse location, quantity

Pricing Context:
  Product = base price, discounts, tax rules

Shipping Context:
  Product = weight, dimensions, shipping class
```

Each context is a service with its own model. They share a product ID but have completely different schemas and behaviors. Forcing one "Product" class to serve all contexts creates a God Object.

**Level 4 - Mastery (senior/staff+ engineer):**

**DDD and microservices alignment:**

```
Strategic DDD          Microservices
--------------         -------------
Bounded Context   ->   Service boundary
Context Map       ->   Service integration patterns
Ubiquitous Lang.  ->   Service API language
Subdomain         ->   Team/service ownership
Anti-Corruption   ->   API adapter/translator
  Layer
```

**Common DDD mistakes in microservices:**

1. **Too many bounded contexts:** Every entity gets its own service. Results in nano-services with massive integration overhead.
2. **Ignoring shared kernel:** Some model overlap is OK (e.g., Money value object shared across services).
3. **DDD everywhere:** Not every service needs tactical DDD. Generic/supporting subdomains can be simple CRUD.
4. **No event storming:** Jumping to service boundaries without understanding domain events leads to wrong boundaries.




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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Domain-Driven Design (DDD). Otherwise remove this section.]
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

**Q1: How does DDD help prevent a distributed monolith?**

_Why they ask:_ Tests understanding of DDD's strategic value for microservices.

_Strong answer:_

DDD prevents distributed monoliths in three ways:

1. **Bounded Contexts define true independence:** Each context has its own model, language, and data. If two contexts share a model, they're not truly bounded - they'll need coordinated changes (= distributed monolith).

2. **Context Maps make coupling explicit:** Instead of discovering hidden dependencies in production, you map them upfront:
   - Customer-Supplier: clear direction, upstream provides API
   - Anti-Corruption Layer: translator prevents model leakage
   - Shared Kernel: explicitly shared code (kept small)
   - Separate Ways: no integration (truly independent)

3. **Ubiquitous Language detects wrong boundaries:** If the same word means different things across teams ("Order" in fulfillment vs "Order" in billing), those should be separate bounded contexts. If a term's definition spans two services, the boundary is wrong.

**Red flag:** If changing a feature requires updating multiple services' domain models, your bounded contexts are wrong. Go back to event storming.
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

# Bounded Context

**TL;DR** - A Bounded Context is a boundary within which a domain model is consistent and terms have unambiguous meaning. In microservices, each Bounded Context typically maps to one service. It's the #1 tool for finding correct service boundaries.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Bounded Context was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
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
A Bounded Context is a "bubble" where words have one clear meaning. Inside the "Sales" bubble, "Customer" means someone who buys. Inside the "Support" bubble, "Customer" means someone with a ticket. Same word, different meaning, different models.

**Level 2 - How to use it (junior developer):**

```
E-commerce bounded contexts:

+-------------------+  +-------------------+
| CATALOG CONTEXT   |  | ORDERING CONTEXT  |
|                   |  |                   |
| Product:          |  | Order:            |
|   name            |  |   orderId         |
|   description     |  |   lineItems       |
|   images          |  |   status          |
|   categories      |  |                   |
|                   |  | Product (ref):    |
| "Product" =       |  |   productId       |
|   rich display    |  |   name (copy)     |
|   item            |  |   price (snapshot) |
+-------------------+  +-------------------+

Same real-world "product" has different models
in different contexts.
```

**Level 3 - How it works (mid-level engineer):**

**How bounded contexts communicate:**

| Pattern               | When                                      | Example                                 |
| --------------------- | ----------------------------------------- | --------------------------------------- |
| Shared Kernel         | Closely related teams, small shared model | Money value object                      |
| Customer-Supplier     | Clear direction, upstream provides        | Catalog provides product data to Orders |
| Conformist            | Downstream accepts upstream's model as-is | Using a 3rd-party API's data model      |
| Anti-Corruption Layer | Protect your model from external/legacy   | Translating legacy system's model       |
| Published Language    | Public API with documented schema         | OpenAPI spec, Protobuf                  |
| Separate Ways         | No integration needed                     | Independent modules                     |

**Level 4 - Mastery (senior/staff+ engineer):**

**Context boundary discovery techniques:**

1. **Event Storming:** Workshop mapping domain events on a timeline, clustering into aggregates, then bounded contexts
2. **Language boundaries:** Where do domain experts use different terms for the same thing? That's a context boundary.
3. **Data ownership:** Who is the single source of truth for this data? Each owner is a bounded context.
4. **Team boundaries:** Conway's Law - teams that communicate heavily should share a context.




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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Bounded Context. Otherwise remove this section.]
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

**Q1: How do you handle data that seems to belong to multiple bounded contexts?**

_Why they ask:_ Tests nuanced understanding of data ownership.

_Strong answer:_

Data that "belongs to multiple contexts" is actually data that is **used differently** in each context. Each context owns its own representation:

**Example: Customer data**

```
Sales Context (owns core customer record):
  Customer: name, email, phone, address,
            acquisition_channel, lifetime_value

Support Context (owns tickets, references customer):
  Customer: customerId (reference), name (cached),
            support_tier, ticket_history

Billing Context (owns payment info):
  Customer: customerId (reference), name (cached),
            billing_address, payment_methods, invoices
```

**Rules:**

1. **One context owns the truth:** Sales owns the customer record. Others have copies.
2. **Copies are eventually consistent:** Sales publishes `CustomerUpdated` events. Others update their cached copies.
3. **Copies may have different shapes:** Support doesn't need `lifetime_value`. Billing doesn't need `acquisition_channel`.
4. **Never reach into another context's data:** Support never queries Sales' database. It subscribes to events or calls Sales' API.
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

# Aggregate

**TL;DR** - An Aggregate is a cluster of domain objects (entities + value objects) treated as a single unit for data changes. The Aggregate Root is the entry point - all external access goes through it. In microservices, one aggregate = one transactional boundary. Never span a transaction across aggregates.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Aggregate was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
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
An Aggregate is a group of related objects that must be consistent together. You can only change them through the "boss" object (the root). Like a company: outsiders talk to the CEO (aggregate root), not to individual employees directly.

**Level 2 - How to use it (junior developer):**

```java
// Aggregate Root: Order
// Children: LineItem (entity), Money (value object)
public class Order { // Aggregate Root
    private OrderId id;
    private List<LineItem> items; // child entity
    private Money total;          // value object
    private OrderStatus status;

    // All changes go through the root
    public void addItem(Product product, int qty) {
        if (status != DRAFT)
            throw new IllegalStateException(
                "Cannot modify confirmed order");
        items.add(new LineItem(product, qty));
        total = recalculate();
    }
}

// BAD: Accessing child entity directly
lineItemRepository.save(lineItem); // NO!

// GOOD: Always through aggregate root
order.addItem(product, 2);
orderRepository.save(order); // Saves entire aggregate
```

**Level 3 - How it works (mid-level engineer):**

**Aggregate design rules:**

1. **One transaction = one aggregate.** Never span a transaction across aggregates.
2. **Reference other aggregates by ID only.** Not direct object references.
3. **Keep aggregates small.** 1 root + a few children. Large aggregates = concurrency bottleneck.
4. **Aggregate root enforces all invariants.** Business rules live on the root, not scattered.

**Example - Too large aggregate:**

```
// BAD: Order aggregate with 10,000 line items
Order -> [10,000 LineItems]
Loading Order = loading 10K items
Any change locks entire aggregate

// GOOD: Separate aggregates
Order { id, status, totalAmount, itemCount }
LineItem { id, orderId, sku, qty, price }
// LineItem is its own aggregate
// Order.total updated via domain event
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Aggregate and microservices:**

- One service can have multiple aggregates
- But one aggregate should NEVER span services
- Cross-aggregate consistency = eventual (domain events, sagas)
- Cross-service consistency = eventual (always)

**Optimistic concurrency on aggregates:**

```java
@Entity
public class Order {
    @Version
    private Long version; // JPA manages this

    // Two concurrent updates:
    // Thread 1: loads Order version=5
    // Thread 2: loads Order version=5
    // Thread 1: saves -> version becomes 6
    // Thread 2: saves -> OptimisticLockException!
    //   (expected version 5, found 6)
    //   Retry: reload and re-apply
}
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Aggregate. Otherwise remove this section.]
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

**Q1: How do you handle consistency between two aggregates in the same service?**

_Why they ask:_ Tests aggregate transaction boundary understanding.

_Strong answer:_

**Rule: One transaction = one aggregate. Use domain events for cross-aggregate consistency.**

```java
// Scenario: Placing order must update inventory

// BAD: One transaction across two aggregates
@Transactional
public void placeOrder(OrderRequest req) {
    Order order = Order.create(req);
    orderRepo.save(order);
    Inventory inv = inventoryRepo.findBySku(req.sku());
    inv.reserve(req.qty()); // Two aggregates in one TX
    inventoryRepo.save(inv);
}
// Problem: Locks both aggregates. Contention.

// GOOD: Domain event for cross-aggregate
@Transactional
public void placeOrder(OrderRequest req) {
    Order order = Order.create(req);
    order.registerEvent(
        new OrderPlacedEvent(order.getId(), req.sku(),
            req.qty()));
    orderRepo.save(order); // One aggregate
    // Event published after commit
}

@EventListener
@Transactional
public void onOrderPlaced(OrderPlacedEvent event) {
    Inventory inv = inventoryRepo
        .findBySku(event.sku());
    inv.reserve(event.qty());
    inventoryRepo.save(inv); // Separate TX
}
```

Trade-off: Eventual consistency between aggregates. If inventory reservation fails, need a compensating action (cancel order or notify user). This is the price of correct aggregate boundaries.
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

# Ubiquitous Language

**TL;DR** - Ubiquitous Language is a shared vocabulary between developers and domain experts within a Bounded Context. The same words appear in code, database schemas, API names, and business conversations. It eliminates the "translation layer" where bugs hide.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Ubiquitous Language was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
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
Developers and business people use the same words. If the business says "Loan Origination," code has `LoanOrigination`, not `LoanProcessingService.startLoan()`.

**Level 2 - How to use it (junior developer):**

```java
// BAD: Developer jargon, not business language
class DataProcessor {
    void processRecord(Map<String, Object> data) {
        insertIntoDb(data);
        triggerHook("post_process");
    }
}

// GOOD: Ubiquitous Language from business domain
class LoanApplication {
    void submit(Applicant applicant, LoanTerms terms) {
        creditCheck.evaluate(applicant);
        underwriting.assess(terms, applicant);
        registerEvent(new ApplicationSubmitted(...));
    }
}
```

**Level 3 - How it works (mid-level engineer):**

**How to build Ubiquitous Language:**

1. **Event Storming workshop:** Domain experts and devs map events using business terms
2. **Glossary:** Document terms with precise definitions in a shared wiki
3. **Code reviews:** Reject code that uses technical jargon instead of domain terms
4. **API design:** REST endpoints use domain terms (`/applications/submit`, not `/data/process`)

**Red flags that language is broken:**

- Developers say "we need to update the user record" but business says "customer changes their profile"
- Same word means different things: "Account" in banking vs "Account" in identity
- Code comments translate between developer and business language
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Ubiquitous Language. Otherwise remove this section.]
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

**Q1: How does Ubiquitous Language relate to API design in microservices?**

_Why they ask:_ Tests practical application of DDD concepts.

_Strong answer:_

The API IS the Ubiquitous Language boundary. It should read like a business conversation:

```
// BAD: Technical CRUD API
POST /api/v1/resources
PUT /api/v1/resources/{id}
DELETE /api/v1/resources/{id}

// GOOD: Domain-language API
POST /orders/place
POST /orders/{id}/cancel
POST /orders/{id}/ship
GET /orders/{id}/tracking

// BAD: Event names
event: "ENTITY_UPDATED"

// GOOD: Domain event names
event: "OrderShipped"
event: "PaymentDeclined"
event: "InventoryReserved"
```

The API becomes the contract of the Bounded Context. When another team reads your API, they should understand your domain without reading your code.
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

# Anti-Corruption Layer

**TL;DR** - An Anti-Corruption Layer (ACL) is a translation layer between two Bounded Contexts that prevents one model from "corrupting" another. It translates between different domain languages, typically used when integrating with legacy systems, third-party APIs, or contexts with incompatible models.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Anti-Corruption Layer was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
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
A translator between your clean domain model and a messy external system. Like a diplomatic interpreter: the foreign system speaks its language, your code speaks yours, the ACL translates between them.

**Level 2 - How to use it (junior developer):**

```java
// External payment API uses different terms
public class StripePaymentAdapter
        implements PaymentPort {

    private final StripeClient stripeClient;

    public PaymentResult charge(
            Money amount, CustomerId customer) {
        // Translate OUR model to Stripe's model
        StripeCharge charge = new StripeCharge();
        charge.setAmountInCents(amount.toCents());
        charge.setCurrency(
            amount.getCurrency().getCode());
        charge.setCustomer(
            lookupStripeId(customer));

        // Call Stripe
        StripeResponse resp =
            stripeClient.createCharge(charge);

        // Translate Stripe's response to OUR model
        return new PaymentResult(
            PaymentId.of(resp.getId()),
            mapStatus(resp.getStatus()),
            Money.of(resp.getAmount(), resp.getCcy())
        );
    }

    private PaymentStatus mapStatus(String s) {
        return switch (s) {
            case "succeeded" -> PaymentStatus.COMPLETED;
            case "pending" -> PaymentStatus.PENDING;
            case "failed" -> PaymentStatus.FAILED;
            default -> PaymentStatus.UNKNOWN;
        };
    }
}
```

**Level 3 - How it works (mid-level engineer):**

**When to use ACL:**
| Scenario | ACL needed? | Why |
|----------|------------|-----|
| Legacy system integration | Yes | Legacy model is rigid, can't change |
| Third-party API (Stripe, Twilio) | Yes | Their model will change without your consent |
| Between your own services | Rarely | If models are very different, maybe |
| Within same bounded context | No | Same model, no translation needed |

**ACL placement:**

```
Your Service -> [ACL Adapter] -> External System

The ACL lives in YOUR service, not in the external
system. It's YOUR translator.

Package structure:
  order-service/
    domain/         (your clean model)
    port/out/       (PaymentPort interface)
    adapter/out/    (StripePaymentAdapter = ACL)
```

**Level 4 - Mastery (senior/staff+ engineer):**

**ACL for legacy migration (Strangler Fig + ACL):**

```
New Service -> [ACL] -> Legacy System
  ACL translates:
  - New domain model <-> Legacy data model
  - New API format <-> Legacy SOAP/XML
  - New error codes <-> Legacy error strings

As migration progresses:
  ACL routes some operations to new DB,
  others to legacy. Eventually all to new.
  Then remove ACL + legacy.
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

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
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

[TODO: Include if 2+ named alternatives exist for Anti-Corruption Layer. Otherwise remove this section.]
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

**Q1: You're integrating with a legacy system that returns XML with field names like `CUST_NM`, `ORD_DT`, `AMT_DUE`. How do you protect your domain model?**

_Why they ask:_ Tests practical ACL implementation.

_Strong answer:_

**Build an ACL adapter that translates legacy abbreviations to domain language:**

```java
public class LegacyOrderAdapter implements OrderPort {
    private final LegacyClient client;

    public Order getOrder(OrderId id) {
        LegacyXmlResponse xml =
            client.fetchOrder(id.value());

        return Order.builder()
            .id(OrderId.of(xml.get("ORD_ID")))
            .customerName(xml.get("CUST_NM"))
            .orderDate(parseDate(xml.get("ORD_DT")))
            .amountDue(parseMoney(xml.get("AMT_DUE")))
            .status(mapLegacyStatus(
                xml.get("STAT_CD")))
            .build();
    }

    private OrderStatus mapLegacyStatus(String code) {
        return switch (code) {
            case "A" -> OrderStatus.ACTIVE;
            case "C" -> OrderStatus.COMPLETED;
            case "X" -> OrderStatus.CANCELLED;
            case "H" -> OrderStatus.ON_HOLD;
            default -> {
                log.warn("Unknown status: {}", code);
                yield OrderStatus.UNKNOWN;
            }
        };
    }
}
```

**Key principles:**

1. ACL lives in your service's adapter layer
2. Domain code NEVER sees `CUST_NM` or `ORD_DT`
3. Map unknown values to safe defaults (log + UNKNOWN)
4. When legacy system changes field names, only ACL changes - domain is protected
5. Unit test the ACL with sample legacy responses
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
