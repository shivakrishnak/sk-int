---
layout: default
title: "Software Architecture - L3 DDD Strategic"
parent: "Software Architecture"
grand_parent: "SK Interview"
nav_order: 8
permalink: /software-architecture/l3-ddd-strategic/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [DDD Strategic Patterns - Bounded Contexts](#ddd-strategic-patterns---bounded-contexts) | critical |
| 2   | [Microservices Architecture Principles](#microservices-architecture-principles) | high |

---

# DDD Strategic Patterns - Bounded Contexts

🎯 Interview Weight: critical - foundational for microservices
decomposition; the most common senior/staff DDD interview question;
separates DDD-informed architects from pattern-name recitors.

---

### 🎯 Model Answer

**30 seconds:**
> A Bounded Context is the boundary within which a domain model
> is consistent and valid. Inside the boundary, terms have precise
> meaning (an "Order" in the shipping context is not the same
> concept as an "Order" in the billing context). Bounded Contexts
> are defined by their Ubiquitous Language - the shared vocabulary
> between developers and domain experts. The Context Map describes
> how Bounded Contexts relate and integrate with each other.

**3 minutes (Senior):**
> Strategic DDD answers: "how do we organize the overall architecture?"
> while Tactical DDD answers: "how do we implement the domain model
> inside a Bounded Context?"
>
> The problem Strategic DDD solves: in large systems, the same word
> means different things in different parts of the business. "Customer"
> in the CRM context is a full profile with history and preferences.
> "Customer" in the billing context is a billing address and payment
> method. "Customer" in the shipping context is a delivery address.
> Forcing these into one unified model creates a model that serves
> no purpose well.
>
> A Bounded Context draws an explicit boundary: within this boundary,
> our Ubiquitous Language is precise and consistent. The `Customer`
> concept in our billing context has exactly the fields billing needs.
> We don't try to serve the CRM's needs.
>
> The Context Map describes integration patterns between contexts.
> Key patterns: Anti-Corruption Layer (ACL) - translate external
> models to your internal model, so external changes don't corrupt
> your domain model. Conformist - you adopt the upstream model
> as-is (low leverage situation). Customer/Supplier - upstream
> provides what downstream needs (collaborative). Shared Kernel -
> two contexts share a small, jointly-owned model.
>
> Why it matters for microservices: Bounded Contexts are the natural
> decomposition boundary for microservices. One microservice =
> one Bounded Context is the target state.

*Adapting up:* Staff adds: "The most common mistake: drawing Bounded
Context boundaries around technical tiers (a 'data layer' context,
a 'UI layer' context) rather than business capabilities. Bounded
Contexts should follow business capability boundaries. The team
that owns the context should understand and own the business
capability - Conway's Law."

*Adapting down:* Junior: "A Bounded Context is a section of your
system with its own consistent terminology. Within the 'Orders'
context, 'Order' means one specific thing. In the 'Billing' context,
'Order' might mean something slightly different. Keeping these
separate prevents confusion and tight coupling."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about DDD Strategic Patterns,
specifically Bounded Contexts - the way DDD organizes the overall
architecture."

**(2) First principles:** "In large systems, the same word means
different things in different business areas. 'Product' in
e-commerce (image, description, price) vs 'Product' in inventory
(warehouse location, stock level). Trying to unify these into one
model creates complexity. Bounded Contexts embrace this reality."

**(3) Bridge:** "A Bounded Context is like a country with its own
language. Inside France, 'pain' means bread. Inside the UK, 'pain'
means something else. Both are correct within their context.
The Context Map is the diplomatic relationships between countries."

---

### 📘 Concept Explanation

**What it is:**
Strategic DDD (Eric Evans, 2003) provides patterns for organizing
large-scale systems: Bounded Contexts (explicit model boundaries),
Ubiquitous Language (shared vocabulary within a context), and
the Context Map (relationships between contexts).

**The problem it solves:**
As systems grow, domain models become cluttered with concepts from
multiple business areas. A "single unified model" serves no use
case well and becomes a maintenance burden. Strategic DDD provides
a principled way to define model boundaries and manage integration.

**How it works:**

```
CONTEXT MAP - E-COMMERCE EXAMPLE

    +--[CRM Context]--+     +--[Catalog Context]--+
    | Customer        |     | Product             |
    | (full profile,  |     | (image, description,|
    |  history, prefs)|     |  pricing rules)     |
    +-------+---------+     +----------+----------+
            |  Conformist              |
            | (CRM is                  | Shared Kernel
            |  upstream)               | (Product ID type)
            v                          v
    +--[Order Context]--------------------+
    | Order, OrderLine                    |
    | Customer = {id, name, address}      |
    | Product = {id, name, price}         |
    |                                     |
    | Anti-Corruption Layer for CRM       |
    | (translates CRM Customer to local)  |
    +-------------------+-----------------+
                        | Customer/Supplier
                        | (Order is upstream)
                        v
    +--[Shipping Context]-+   +--[Billing Context]-+
    | Shipment            |   | Invoice             |
    | Address             |   | PaymentMethod       |
    | (Delivery concern   |   | (Financial concern  |
    |  only)              |   |  only)              |
    +---------------------+   +--------------------+
```

**Context integration patterns:**

| Pattern | Description | When to use |
|---|---|---|
| Anti-Corruption Layer (ACL) | Translate external model to internal via adapter | When upstream model is poorly designed or frequently changing |
| Conformist | Adopt upstream model as-is | When you have no leverage over the upstream team |
| Customer/Supplier | Upstream publishes what downstream needs; collaborative negotiation | When teams work closely and can negotiate API changes |
| Shared Kernel | Two contexts share a small, jointly-owned model | When contexts are highly cohesive; both teams maintain it |
| Open Host Service | Upstream provides a well-documented API for multiple consumers | Stable upstream with multiple downstream teams |
| Published Language | Shared formal model (OpenAPI schema, Avro schema) for integration | Cross-organization or multi-team integration |

**Ubiquitous Language:**
The shared vocabulary between developers and domain experts within
a Bounded Context. Terms have precise, agreed-upon meaning. "Order"
in the Order Context means exactly what the business expert means.
Developers and domain experts use the same words. Code class names
match the domain vocabulary.

**The key insight:**
Bounded Contexts embrace the reality that the same word means
different things in different parts of the business. Instead of
fighting this with a "canonical data model," Strategic DDD provides
patterns for managing the integration explicitly.

---

### 💻 Code Example

```java
// BAD: "God Model" trying to serve all contexts
// The Universal Customer object - a maintenance nightmare

@Entity
@Table(name = "customers")
public class Customer {
    // CRM fields
    private String firstName;
    private String lastName;
    private LocalDate birthDate;
    private String preferredLanguage;
    private List<PurchaseHistory> purchaseHistory;
    private LoyaltyTier loyaltyTier;
    private MarketingPreferences marketingPrefs;

    // Billing fields
    private String billingAddress;
    private String vatNumber;
    private PaymentMethod defaultPayment;
    private CreditLimit creditLimit;

    // Shipping fields
    private List<Address> deliveryAddresses;
    private DeliveryPreferences deliveryPrefs;

    // 80 fields that cannot all be relevant to any
    // single operation - this model serves no one well
}
// When billing says "we need Customer.creditLimit"
// they change a class that shipping and CRM also depend on.
// One change breaks three contexts.
```

> **Code walkthrough:** The universal `Customer` model accumulates
> fields from every context that needs customer data. The CRM,
> billing, and shipping teams all share this class. A billing
> requirement change triggers a change to this shared class,
> requiring coordination with CRM and shipping teams. The model
> is loaded entirely even when only the billing address is needed.
> Testing billing logic requires a full `Customer` object with
> CRM, shipping, and billing fields populated. This is the "canonical
> data model" anti-pattern.

```java
// GOOD: Bounded Context per business area

// ORDER CONTEXT - owns its view of Customer
// Customer here = only what Order context needs
public class Customer {  // Order Context's Customer
    private final CustomerId id; // Reference to CRM
    private final String displayName; // denormalized
    private final Address shippingAddress;
    // Only fields relevant to ordering
}

// BILLING CONTEXT - its own view of Customer
public class BillingAccount {  // Not "Customer" - precise
    private final BillingAccountId id;
    private final String vatNumber;
    private final BillingAddress address;
    private final PaymentMethod defaultPayment;
    private final CreditLimit creditLimit;
    // Only fields relevant to billing
}

// ANTI-CORRUPTION LAYER (ACL) in Order Context
// Protects Order Context from CRM's model instability
@Service
public class CrmCustomerAdapter {
    private final CrmClient crmClient; // External CRM API

    // Translates CRM's customer model to Order Context's
    public Customer getCustomer(CustomerId id) {
        CrmCustomerDto crm = crmClient.findById(
            id.getValue()
        );
        // Translation: CRM fields -> Order Context fields
        return new Customer(
            id,
            crm.getFirstName() + " " + crm.getLastName(),
            new Address(
                crm.getDefaultAddress().getStreet(),
                crm.getDefaultAddress().getCity(),
                crm.getDefaultAddress().getPostalCode()
            )
        );
    }
}
// When CRM changes its API:
// Only CrmCustomerAdapter needs to change.
// Order Context's Customer class is unaffected.
// The ACL absorbs external instability.
```

> **Code walkthrough:** Each Bounded Context defines its own
> `Customer` concept - or renames it entirely (`BillingAccount`)
> for clarity. The `CrmCustomerAdapter` (Anti-Corruption Layer)
> translates CRM's model to the Order Context's local model.
> When the CRM API changes its `getFirstName()` to `firstName`,
> only `CrmCustomerAdapter` needs updating. The `Order` aggregate
> is unaffected. Each context's model contains only the fields
> it needs, making loading, testing, and evolution simpler.

```java
// SHARED KERNEL example: ProductId shared across contexts
// Minimal shared model - just the identity type

// Shared Kernel (tiny, jointly maintained)
public final class ProductId {
    private final String value;
    public ProductId(String value) {
        this.value = Objects.requireNonNull(value);
    }
    // Equality, hashCode, toString only
    // NO business logic - just identity
}

// Order Context: uses ProductId, defines its own Product view
public class OrderLine {
    private final ProductId productId; // from Shared Kernel
    private final String productName;  // denormalized
    private final Money unitPrice;     // denormalized
    // No reference to Catalog Context's full Product
}

// Catalog Context: uses same ProductId, full Product model
public class Product {
    private final ProductId id;        // same Shared Kernel ID
    private final String name;
    private final String description;
    private final byte[] imageData;
    private final PricingRule pricingRule;
}
// ProductId is the only shared element.
// The rest of each context's Product concept is independent.
```

> **Code walkthrough:** The Shared Kernel contains only `ProductId`
> - the minimum shared element needed for cross-context references.
> The Order Context stores a denormalized `productName` and `unitPrice`
> at order time (so the order line is self-contained even if the
> catalog changes). The Catalog Context has its full `Product` model.
> Both use the same `ProductId` type for identity. The Shared Kernel
> is deliberately minimal - every field added to the Shared Kernel
> increases coupling between contexts.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A Bounded Context is a section of the system with its own
> consistent domain model and terminology. Within the boundary,
> terms have precise meaning. Outside, the same term might mean
> something different. This allows each part of the system to have
> a model optimized for its own needs without compromising for others.
> The Context Map shows how different Bounded Contexts integrate
> and which team is "upstream" (provides data) vs "downstream"
> (consumes data).

---

**Senior / Staff (5+ years):**
> Strategic DDD's most important contribution is making explicit
> the integration patterns between contexts. The ACL is the key
> pattern: it protects your context from external instability.
> When the external CRM changes its API, only the ACL changes -
> your domain model is insulated.
>
> The Context Map is also a team-structure tool. The upstream/downstream
> relationship corresponds to Conway's Law: the team with more
> power in the organization tends to be upstream. A Conformist
> relationship ("we adopt their model as-is") reflects that you
> have no leverage over the upstream team. An ACL reflects that
> you have the resources to build a translation layer.
>
> For microservices decomposition, Bounded Contexts define the
> right service boundaries. A service that crosses two Bounded
> Contexts will have two different domain models mixed together -
> this is a sign the service boundaries are wrong.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Bounded Context = microservice | A Bounded Context defines the model boundary. A microservice is a deployment unit. Often 1:1, but a modular monolith can have multiple Bounded Contexts, and a microservice should not span multiple Bounded Contexts |
| Bounded Context = database schema | A Bounded Context can have multiple schemas or tables. The boundary is the model, not the storage |
| ACL is about security | Anti-Corruption Layer is a translation layer for model concepts, not security. It protects your domain model from external model pollution |
| Shared Kernel is a good default | Shared Kernel creates coupling between contexts. It should be minimized, not used as a convenience for sharing code |
| Ubiquitous Language means the same words everywhere | Ubiquitous Language is per Bounded Context. The same word can have different precise meanings in different contexts |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Missing ACL - domain pollution from upstream**

*Symptom:* Your service imports and uses types directly from the
upstream service's package. When the upstream service changes its
model (renames a field, adds a required field), your tests fail
and your production code breaks.

*Root cause:* No ACL - your domain model directly exposes the
upstream model's types.

*Diagnostic:*
```java
// Code smell: upstream types in domain classes
import com.company.crm.dto.CrmCustomerDto; // BAD

public class Order {
    private CrmCustomerDto customer; // Upstream model in domain
}
// When CRM changes CrmCustomerDto -> Order breaks
```

*Fix:*
```java
// Order Context defines its own Customer type
public class Customer { // Local, Order Context owned
    private CustomerId id;
    private String name;
    private Address shippingAddress;
}

// ACL translates at the boundary
public class CrmAdapter {
    public Customer translate(CrmCustomerDto dto) {
        return new Customer(/* translation logic */);
    }
}
```

**Failure 2: Anemic Context Map - implicit integration**

*Symptom:* Services share a database schema. Changes to one service's
schema break other services without warning. No explicit integration
contracts.

*Root cause:* Context Map was never defined; integration is through
shared infrastructure, not through explicit context relationships.

*Diagnostic:*
```sql
-- Multiple services write to the same tables
SELECT usename, query FROM pg_stat_activity
WHERE datname = 'main_db'
  AND query LIKE '%INSERT INTO orders%';
-- Multiple service users = shared schema = no context boundary
```

*Fix:* Each Bounded Context owns its schema exclusively. Other
contexts access it only through its API or event stream.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 25 minutes |
| Core themes | Context Map patterns, ACL, Ubiquitous Language, decomposition |
| Seniority signal | Junior: knows the concept; Senior: ACL usage; Staff: team structure + Context Map |
| Common trap | Equating Bounded Context with microservice |
| Staff differentiator | Context Map as organizational tool (Conway's Law) |

---

**Q1 [JUNIOR]: What is a Bounded Context?**

*Why they ask:* Foundational DDD concept - gateway question.

*Likely follow-up:* "How does it differ from a microservice?"

A Bounded Context is an explicit boundary within which a domain
model is consistent and valid. Inside the boundary, all terms have
precise, agreed-upon meaning. The same term may have different
meanings in different Bounded Contexts.

Example: "Customer" in the CRM context means a full customer profile
with preferences and history. "Customer" in the billing context
means an entity with a billing address and payment method. These
are different concepts with the same word. A Bounded Context gives
each its own precise definition instead of fighting over a shared
definition.

The Bounded Context is defined by its Ubiquitous Language - the
vocabulary shared between the development team and the business
domain experts.

Difference from microservice: a Bounded Context is a logical
boundary (defines a domain model). A microservice is a deployment
unit (a process that owns a Bounded Context). Usually 1:1 in a
mature microservices architecture, but a modular monolith can
have multiple Bounded Contexts in one deployment.

*What separates good from great:* Most candidates say "Bounded Context
= microservice." Great candidates explain the logical vs deployment
distinction, give the same-word-different-meaning motivation, and
describe Ubiquitous Language as the defining characteristic.

---

**Q2 [MID]: What is the Anti-Corruption Layer and when do you need it?**

*Why they ask:* The ACL is the most practical Strategic DDD pattern;
tests whether candidates apply DDD, not just know it.

*Likely follow-up:* "How does an ACL differ from a Facade or Adapter?"

The Anti-Corruption Layer (ACL) is a translation layer at a Bounded
Context's boundary that translates the external context's model
into the local context's model. It "corrupts" nothing - it prevents
external model concepts from leaking into the local domain model.

When you need it: when the upstream context has a poorly designed
model (no DDD, procedural code, legacy system). When the upstream
model changes frequently and you do not want those changes to
propagate into your domain. When you have low leverage over the
upstream team (you cannot ask them to change their API for your
needs).

Implementation: typically an Adapter + Translator combination.
The Adapter implements the domain's repository or service interface.
The Translator converts between models. The domain only sees the
local interface.

The difference from Facade/Adapter: a Facade simplifies an interface.
An Adapter makes interfaces compatible. An ACL does both, but with
the explicit goal of protecting the local domain model's integrity
from an external model's "corruption" of its terminology and structure.

*What separates good from great:* Most candidates say "ACL translates
between models." Great candidates describe the isolation goal (protect
the local domain from external instability), give the implementation
approach (Adapter + Translator), and distinguish from the Gang of
Four Adapter pattern (similar structure, different goal).

---

**Q3 [SENIOR]: How do you identify Bounded Context boundaries
in a large system?**

*Why they ask:* The hardest strategic DDD question - tests design
judgment.

*Likely follow-up:* "What are the signs that a service spans two
Bounded Contexts?"

The primary technique: follow the Ubiquitous Language. When the
same word requires multiple definitions in the same conversation,
you have found a context boundary. "What do you mean by 'order'?"
- if a shipping expert and a billing expert give different answers,
these are two contexts.

Techniques for identification:

Event Storming: workshop where developers and domain experts map
out domain events on a timeline. Clusters of events that belong
together and use consistent vocabulary are candidates for Bounded
Contexts.

Business capability alignment: each Bounded Context should map
to one business capability. "Order Management," "Billing," "Inventory
Management," "Customer Relationship Management" are capabilities.
If a service crosses two capabilities, it may span two contexts.

Conway's Law: team boundaries often reveal context boundaries.
If two teams each have deep domain knowledge in a specific area,
those areas are likely Bounded Contexts. If one team owns a
service that spans the knowledge of two teams, that's a sign of
crossed context boundaries.

Signs that a service spans two contexts: the service has two
different versions of the "same" concept. Different classes named
`Customer` in different parts of the codebase with different fields.
The service has two teams working on it and they use different
terminology for the same operations.

*What separates good from great:* Most candidates say "use business
domains." Great candidates describe Event Storming, Conway's Law
alignment, and the Ubiquitous Language signal (same word, multiple
definitions = context boundary).

---

**Q4 [STAFF]: Compare the Context Map relationship patterns and
when to use each.**

*Why they ask:* Context Map is the most practical Strategic DDD
tool for real systems.

*Likely follow-up:* "How does the organizational relationship
affect your pattern choice?"

Anti-Corruption Layer: use when the upstream model is problematic
(legacy, poorly designed, frequently changing) and you have the
capacity to build a translation layer. The ACL absorbs external
instability.

Conformist: use when you have no leverage over the upstream team
and the cost of building an ACL outweighs the benefit. You adopt
the upstream model as-is. Risk: upstream changes break your code.
Reality: most integrations with third-party systems start as Conformist.

Customer/Supplier: collaborative relationship where the upstream
team provides what the downstream team needs. Requires both teams
to be willing to negotiate. Use when teams are within the same
organization and have aligned incentives.

Shared Kernel: a small, jointly-maintained model owned by two
contexts. Use sparingly - every field in the Shared Kernel creates
coupling. Only for truly shared identity types or concepts that
are genuinely identical in both contexts.

Open Host Service (OHS): the upstream provides a well-documented
API (REST, gRPC, events) designed for multiple consumers. Each
consumer may add their own ACL on top. Use when one service serves
many downstream teams.

Published Language (PL): a formal, stable schema (OpenAPI, Avro,
Protobuf) that multiple contexts use. Extends OHS with explicit
schema versioning. Use for cross-organization or multi-team stable
integration contracts.

The organizational dimension: the pattern often reflects power
dynamics. Conformist = upstream has power, downstream cannot
negotiate. Customer/Supplier = collaborative. ACL = downstream
invests in insulation when they have the resources.

*What separates good from great:* Most candidates list the patterns.
Great candidates explain the organizational power dynamics behind
each pattern choice and give specific scenarios for each.

---

**Q5 [STAFF]: How does Bounded Context design relate to microservices
team ownership?**

*Why they ask:* Staff signal: connecting architectural boundaries
to organizational structure.

*Likely follow-up:* "How do you handle Bounded Contexts that are
too small for a dedicated team?"

Conway's Law: the architecture will mirror the communication
structure of the organization. Bounded Context boundaries should
align with team boundaries. A team owns a Bounded Context and
is responsible for its Ubiquitous Language, its domain model,
and its integration contracts.

The Inverse Conway Maneuver: deliberately structure teams to
match the desired Bounded Context boundaries. If "Order Management"
and "Shipping" should be separate contexts, give them separate
teams. If they share a team, the team will tend to share their
model (context bleeding).

The "too small" problem: some Bounded Contexts are genuinely small
(not enough work for a dedicated team). Solutions: one team owns
multiple related Bounded Contexts (they maintain the context
boundaries in code even if they own both). Or: a modular monolith
with explicit module boundaries in code (not deployed as separate
services but the context boundaries are enforced by package-level
visibility rules).

The "team topology" alignment: Stream-aligned teams (own a
Bounded Context end-to-end). Platform teams (own enabling Bounded
Contexts like identity, payment). Complicated subsystem teams
(own specialist Bounded Contexts like machine learning, analytics).

*What separates good from great:* Most candidates say "one team per
microservice." Great candidates describe Conway's Law alignment,
the Inverse Conway Maneuver, the too-small context solutions
(one team, multiple contexts vs modular monolith), and Team
Topologies as the organizational framework.

---

**Q6 [SENIOR]: What is Ubiquitous Language and how do you enforce it?**

*Why they ask:* Ubiquitous Language is the foundation of DDD -
tests whether candidates understand the communication benefit.

*Likely follow-up:* "How do you prevent Ubiquitous Language drift
over time?"

Ubiquitous Language is the shared vocabulary between developers
and domain experts within a Bounded Context. Every term has a
precise, agreed-upon definition. The same words are used in:
conversations between developers and domain experts, code class
and method names, tests, documentation, and UI labels.

Why it matters: when developers use "entity" and domain experts
say "account" for the same concept, every conversation requires
translation. Misunderstandings accumulate. Code names diverge
from the business reality. The code becomes harder to read for
domain experts.

How to establish it: Event Storming workshops produce domain events
in business language. Glossary maintained by developers and
domain experts together. Code reviews check that new class names
and method names match the agreed vocabulary.

Enforcement in code:
- Class names match domain terms exactly: `Order`, `OrderLine`,
  `BillingAccount` (not `OrderEntity`, `OrderDTO`)
- Method names match domain operations: `order.place()` not
  `order.save()`, `order.process()` not `order.execute()`
- ArchUnit can enforce package naming conventions that prevent
  domain class names from being prefixed with technical terms

Preventing drift: regular glossary reviews with domain experts.
Code review checklist that includes naming alignment. Onboarding
for new developers explicitly covers the Ubiquitous Language
glossary before they write code.

*What separates good from great:* Most candidates say "use business
language in code." Great candidates describe the full scope (code,
tests, docs, conversations), Event Storming as the discovery
mechanism, and drift prevention through ongoing domain expert
collaboration.

---

**Q7 [STAFF]: How do you migrate from a monolith to Bounded Contexts?**

*Why they ask:* Tests practical application of Strategic DDD
to real legacy systems.

*Likely follow-up:* "What is the first Bounded Context to extract
from a monolith?"

Migrating from a monolith to Bounded Contexts is a three-phase
process:

Phase 1 - Identify existing contexts: run Event Storming on the
existing system. Find the context boundaries hidden in the monolith.
Map the current "Universal Customer" class to see which fields
belong to which context. Create a Context Map for the current
state (before any splitting).

Phase 2 - Define future Context Map: design the target state.
Which contexts should exist? Which team owns each? What are the
integration patterns between them? This is the architectural vision.

Phase 3 - Strangle the monolith: extract one Bounded Context at
a time using the Strangler Fig Pattern. Start with the context
that is: least coupled to others (fewest dependencies), most
valuable to extract independently (own deployment, own scaling),
or owned by a team ready to take full ownership.

The ACL during migration: extract the target context as a new
service. Build an ACL in both directions: the new service has an
ACL for data it needs from the monolith. The monolith has an ACL
for calling the new service. Eventually, the relevant code is
deleted from the monolith.

The database strangler: separate the database schema before
separating the code. Create a separate schema for the target
context. Run dual-write (write to both the old schema and the
new schema). Validate consistency. Switch reads to the new schema.
Remove dual-write.

*What separates good from great:* Most candidates say "extract
microservices one by one." Great candidates describe Event Storming
for context discovery, the Context Map as the migration plan,
the selection criteria for the first extraction, and the database
strangler as the data migration mechanism.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | ACL implementation, Context Map patterns |
| Hiring Manager | Team ownership and Conway's Law alignment |
| Bar Raiser | Identifying context boundaries, migration strategy |
| Peer Engineer | Practical: when to add ACL vs go Conformist |

---

### ⚖️ Comparison Table

| Pattern | Relationship | Coupling | When to use |
|---|---|---|---|
| Anti-Corruption Layer | Downstream translates upstream | Low (protected by ACL) | Upstream model is unstable or poorly designed |
| Conformist | Downstream adopts upstream model | High (direct dependency) | No leverage over upstream; low priority integration |
| Customer/Supplier | Collaborative; upstream provides what downstream needs | Medium (negotiated contract) | Same organization; aligned incentives |
| Shared Kernel | Joint ownership of small shared model | Medium (shared code) | Genuinely identical concepts in both contexts |
| Open Host Service | Upstream provides documented API for many consumers | Low (API contract) | Stable upstream serving many consumers |
| Published Language | Formal schema shared by multiple contexts | Low (schema contract) | Cross-org or multi-team stable integration |

---

---

# Microservices Architecture Principles

🎯 Interview Weight: high - foundational knowledge for any
senior/staff role at organizations running distributed systems;
often combined with "tell me about a microservices migration."

---

### 🎯 Model Answer

**30 seconds:**
> Microservices are small, independently deployable services, each
> owning a single business capability and its data. The core
> principles: single responsibility (one Bounded Context per service),
> loose coupling (services communicate via APIs or events, never
> through shared databases), high cohesion (related logic lives
> together), service autonomy (each service deploys and scales
> independently), and decentralized governance (teams choose
> their own technology within guardrails).

**3 minutes (Senior):**
> Microservices evolved from SOA by making service autonomy the
> primary goal. The key principles:
>
> Single responsibility: each microservice owns one business
> capability (an Ordering service owns the full order lifecycle:
> creation, modification, cancellation, confirmation). It does not
> share responsibility with another service.
>
> Loose coupling: services do not share databases. Integration
> is through well-defined APIs (REST, gRPC) or events (Kafka).
> A change to Service A's internal implementation does not break
> Service B.
>
> High cohesion: all code related to the "Order" capability lives
> in the Order service. Code that belongs to different capabilities
> lives in different services.
>
> Service autonomy: each service deploys independently. The Order
> service can deploy a new version without coordinating with the
> Payment service. This requires backward-compatible API changes.
>
> Data ownership: each service owns its persistent state. No two
> services write to the same table. Shared data is exposed via
> API or events.
>
> Decentralized governance: teams choose the best technology for
> their service (Java, Node.js, Python) within organizational
> guardrails (approved languages, security standards).

*Adapting up:* Staff adds: "The hardest microservices problem is
data consistency. With one database and one transaction, you can
guarantee ACID properties. With microservices, you must choose:
accept eventual consistency (sagas, Domain Events), or avoid
cross-service transactions by designing services with correct
boundaries (if you frequently need cross-service transactions,
your service boundaries are wrong)."

*Adapting down:* Junior: "Microservices means breaking a large
application into small, independent services. Each service does
one thing (like handling orders), has its own database, and can
be deployed separately. They communicate via HTTP APIs or messages."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Microservices Architecture
Principles - the design rules that define how microservices should
be built."

**(2) First principles:** "Large systems fail to scale when
every change requires coordinating with the whole system. Microservices
aim to give each service the autonomy to change and scale without
coordination."

**(3) Bridge:** "Microservices are like businesses in a mall. Each
business (service) operates independently: its own entrance, its
own staff, its own cash register (database). They share the building
(infrastructure) but not the operations. One business can renovate
without closing the others."

---

### 📘 Concept Explanation

**What it is:**
Microservices architecture is an approach where a system is
decomposed into small, independently deployable services, each
owning a single business capability and its own data store. Each
service can be developed, deployed, scaled, and maintained
independently by a small team.

**The problem it solves:**
Monolithic applications face organizational scaling problems:
as teams grow, coordinating changes to a shared codebase becomes
a bottleneck. Deployment requires coordinating all teams. A bug
in one part can break the whole system. Microservices enable team
autonomy by giving each team its own deployable unit.

**Core principles:**

```
MICROSERVICES PRINCIPLES

1. SINGLE RESPONSIBILITY
   One service = one business capability
   OrderService: create, modify, cancel, confirm orders
   NOT OrderService + InventoryService combined

2. LOOSE COUPLING
   Service A      API/Events      Service B
   +--------+  <----------->  +--------+
   |Internal|                  |Internal|
   |only    |                  |only    |
   +--------+                  +--------+
   NO shared database access

3. HIGH COHESION
   All order-related code: in OrderService
   All payment-related code: in PaymentService

4. SERVICE AUTONOMY
   OrderService deploys independently
   No coordination required with PaymentService
   Backward-compatible API changes required

5. DATA OWNERSHIP
   OrderService owns: orders, order_lines tables
   PaymentService owns: payments, payment_methods
   No cross-service schema writes
```

**The eight fallacies of distributed computing:**
(Peter Deutsch, 1994 - apply directly to microservices)
1. The network is reliable
2. Latency is zero
3. Bandwidth is infinite
4. The network is secure
5. Topology doesn't change
6. There is one administrator
7. Transport cost is zero
8. The network is homogeneous

Microservices practitioners must design for all eight being false.

**When microservices are appropriate:**
Large teams that need deployment autonomy. Multiple products or
business capabilities with different scaling requirements. Organization
ready for DevOps, container operations, and distributed system complexity.

**When microservices are NOT appropriate:**
Small teams (3-10 developers) - the operational overhead exceeds
the organizational benefit. Early-stage startups - the pace of
business change requires frequent cross-service changes. When
the team cannot operate containers, implement CI/CD, and manage
distributed tracing.

---

### 💻 Code Example

```java
// BAD: Distributed monolith - services share a database
// OrderService and InventoryService share schema

// OrderService writes to inventory directly
@Service
public class OrderService {
    @Autowired
    private InventoryRepository inventoryRepo; // WRONG!

    @Transactional
    public Order placeOrder(PlaceOrderCommand cmd) {
        Order order = orderFactory.create(cmd);
        // Reaches into another service's domain
        Inventory inventory =
            inventoryRepo.findByProduct(cmd.getProductId());
        inventory.reserve(cmd.getQuantity());
        inventoryRepo.save(inventory); // Writing other service's DB!
        orderRepo.save(order);
        return order;
    }
}
// The worst of both worlds:
// Not a monolith (multiple deployments) but
// not microservices (shared data, tight coupling)
// Renaming the inventory table breaks OrderService.
// Deploying InventoryService with a schema migration
// may break OrderService's queries.
```

> **Code walkthrough:** `OrderService` imports and uses
> `InventoryRepository` directly - it writes to Inventory's data.
> This is the distributed monolith anti-pattern: separately deployed
> services that are tightly coupled through a shared database. A
> schema migration to `inventory` table by the Inventory team
> breaks `OrderService`. The "service" boundary provides no
> isolation at the data layer. This creates all the operational
> complexity of microservices with none of the autonomy benefits.

```java
// GOOD: Proper microservices with data ownership

// OrderService owns orders/* tables only
// Communicates with InventoryService via its API

@Service
public class OrderService {
    // Communicates with InventoryService via client
    private final InventoryServiceClient inventoryClient;
    private final EventPublisher eventPublisher;

    @Transactional
    public Order placeOrder(PlaceOrderCommand cmd) {
        Order order = orderFactory.create(cmd);
        orderRepo.save(order);
        // Publish event - InventoryService reacts async
        eventPublisher.publish(new OrderPlaced(order));
        return order;
    }
}

// InventoryService client - communicates via HTTP/event
// NOT by writing to InventoryService's database
@Component
public class InventoryServiceClient {
    private final RestTemplate restTemplate;
    private final CircuitBreaker circuitBreaker;

    // Calls InventoryService's published API
    public InventoryAvailability checkAvailability(
        ProductId productId, int quantity
    ) {
        return circuitBreaker.run(
            () -> restTemplate.getForObject(
                "/inventory/{id}/availability?qty={qty}",
                InventoryAvailability.class,
                productId, quantity
            )
        );
    }
}
// InventoryService can change its internal schema freely.
// It only needs to maintain its API contract.
// OrderService is isolated from InventoryService internals.
```

> **Code walkthrough:** `OrderService` communicates with
> `InventoryService` through its published API (via `InventoryServiceClient`)
> or through events (`OrderPlaced`). It never writes to Inventory's
> database. The `CircuitBreaker` wraps the HTTP call - if
> `InventoryService` is down, the circuit opens and `OrderService`
> can return a graceful fallback instead of cascading failure.
> `InventoryService` can refactor its internal schema, switch
> databases, or change its implementation without affecting
> `OrderService` as long as it maintains the API contract.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Microservices are small, independent services that each do one
> thing and have their own database. They communicate via HTTP APIs
> or message queues. Each service can be deployed and scaled
> independently. The benefit over a monolith: teams can work and
> deploy independently. The cost: you now have a distributed
> system with network failures, eventual consistency, and operational
> complexity.

---

**Senior / Staff (5+ years):**
> Microservices are an organizational solution to a scaling problem.
> The technical benefits (independent deployment, independent
> scaling) are the mechanism; the goal is team autonomy.
>
> The most common failure mode: the distributed monolith. Services
> are "micro" in name (separately deployed) but tightly coupled
> in reality (shared databases, synchronous call chains that span
> five services). A synchronous chain A -> B -> C -> D -> E has
> the availability of the product of all five services. If each
> is 99.9% available, the chain is 99.5% available.
>
> The right question before "should we use microservices" is
> "do we have the organizational complexity that justifies the
> operational complexity?" For most systems below 50 developers,
> a well-structured modular monolith provides 80% of the benefit
> at 20% of the cost.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Microservices = small services | Service size should follow the Bounded Context boundary, not a line count. A "micro" service is not necessarily small in code |
| Microservices are always better | For small teams or early-stage systems, a modular monolith provides the development speed of a monolith with many of the structural benefits of microservices |
| Each microservice needs its own database technology | Service autonomy allows technology choice, it doesn't require it. Many services use the same database engine with separate schemas/databases |
| API versioning is optional | Independently deployable services require backward-compatible APIs. A breaking API change requires coordinating all consumers - defeating the autonomy goal |
| Microservices eliminate monolith coupling | Poorly bounded microservices create a distributed monolith: all the operational complexity with none of the autonomy benefits |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Synchronous call chain cascading failure**

*Symptom:* API gateway timeout. Every request fails. Investigation
shows Service E (deep in the call chain A->B->C->D->E) is slow.

*Root cause:* Synchronous dependency chain. When E is slow,
D waits, C waits, B waits, A waits, user waits.

*Diagnostic:*
```
# Distributed trace shows:
A: 5000ms (timeout)
  B: 4900ms
    C: 4800ms
      D: 4700ms
        E: 4600ms <-- root cause
# All threads in A, B, C, D are blocked waiting for E
```

*Fix:* (1) Circuit breaker on each client: break the chain before
thread exhaustion. (2) Timeout + fallback: each service has a
max timeout and a fallback response (cached data, default response).
(3) Consider making some calls asynchronous if a direct response
is not required.

**Failure 2: Distributed monolith via shared database**

*Symptom:* A schema migration for Service B requires coordination
with Service A, C, and D because they all query Service B's tables.

*Diagnostic:*
```sql
-- Check which applications access which tables
SELECT client_addr, query FROM pg_stat_activity
WHERE query LIKE '%service_b_owned_table%';
-- Multiple different client IPs = shared table = coupling
```

*Fix:* Services access only their own tables. Other services
access data via API or events. Schema migrations become internal
implementation details, not cross-team coordination events.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 25 minutes |
| Core themes | Data ownership, loose coupling, autonomy, distributed monolith anti-pattern |
| Seniority signal | Junior: service per capability; Senior: data ownership; Staff: when NOT microservices |
| Common trap | Calling a distributed monolith "microservices" |
| Staff differentiator | Microservices as organizational solution, not purely technical |

---

**Q1 [JUNIOR]: What are the key principles of microservices?**

*Why they ask:* Foundational knowledge test.

*Likely follow-up:* "What is service autonomy?"

The core microservices principles:

Single responsibility: each service owns one business capability.
`OrderService` owns the full order lifecycle. It does not share
responsibility with another service.

Loose coupling: services communicate through well-defined contracts
(REST APIs, event schemas). They do not share databases or internal
data structures. A change to Service A's internals does not break
Service B.

High cohesion: all code for one business capability lives in one
service. Split what belongs together and you create anemic services
that always change together.

Service autonomy: each service deploys independently. No release
coordination required.

Data ownership: each service exclusively owns its data store.
No other service writes directly to another service's database.

*What separates good from great:* Most candidates list principles.
Great candidates explain WHY each principle exists - single
responsibility enables team autonomy, data ownership enables
independent deployment, loose coupling prevents cascading failures.

---

**Q2 [SENIOR]: What is a distributed monolith and how do you avoid it?**

*Why they ask:* The most common microservices failure mode.

*Likely follow-up:* "How do you detect a distributed monolith in an existing system?"

A distributed monolith has the appearance of microservices (separately
deployed services) but the tight coupling of a monolith. Signs:

Shared database: multiple services write to the same tables.
Schema changes require coordinating all services. A migration to
the shared database is a "big bang" coordinated deployment.

Synchronous call chains: Service A calls B which calls C which
calls D. All must be deployed together because the API contracts
are too tightly coupled. A behavioral change in D requires
coordination with C, B, and A.

Shared code libraries with business logic: Services share a "common"
library that contains domain types. When the library changes, all
services must upgrade in lockstep.

Detection: draw a dependency graph. If it looks like a monolith
(dense connections, no clear boundary), it is a distributed monolith.
Check whether any schema migration requires coordination with
more than one other team.

Prevention: strict data ownership (each service owns its schema).
API-first contracts with semantic versioning. Backward-compatible
changes only (additive, not breaking). Shared libraries contain
only utilities (no business logic).

*What separates good from great:* Most candidates describe the
distributed monolith. Great candidates describe detection methods
(dependency graph, coordination requirements for schema changes)
and give the three specific signs with their operational symptoms.

---

**Q3 [STAFF]: When should you choose a modular monolith over microservices?**

*Why they ask:* Staff judgment - avoiding cargo-culting microservices.

*Likely follow-up:* "How do you migrate from modular monolith to microservices?"

Modular monolith: a single deployable unit with explicit module
boundaries (well-defined package structures, no cross-module
direct dependencies, module APIs enforced by package visibility
rules or ArchUnit). The modules correspond to Bounded Contexts.

Choose modular monolith when:

Small team (fewer than 15-20 developers): microservices operational
overhead (container orchestration, distributed tracing, service
discovery, circuit breakers) costs more than the deployment
autonomy benefit.

Early-stage product with frequent cross-boundary changes: when
you are still discovering the right Bounded Context boundaries,
having them in the same codebase is safer. Cross-module refactoring
in a monolith is a rename; cross-service refactoring requires
API versioning and coordinated deployment.

Operational immaturity: if the team does not have CI/CD pipelines,
container expertise, and distributed tracing, microservices will
have worse reliability than a monolith.

Single deployment unit requirement: if the product must be deployed
on-premises for enterprise customers, a single JAR is simpler.

The migration path: modular monolith -> microservices is lower
risk than monolith -> microservices. The module boundaries defined
in the monolith become the service boundaries. The module APIs
become the service APIs. The migration is extracting a module
into a separately deployed service.

*What separates good from great:* Most candidates reluctantly
admit monoliths exist. Great candidates advocate for modular
monolith as the recommended starting architecture, give specific
team-size and operational maturity thresholds, and describe the
modular-to-microservices migration path as lower risk.

---

**Q4 [SENIOR]: How do you handle cross-service transactions?**

*Why they ask:* Data consistency across services is the hardest
microservices problem.

*Likely follow-up:* "When would you use the Saga pattern vs redesigning service boundaries?"

Options for cross-service transactions:

Avoid them: the best solution is to design service boundaries
so that operations that require transactional consistency live
within one service. If "place order" requires updating both
`Order` and `Inventory` atomically, consider whether both belong
in the same service.

Saga pattern (eventual consistency): a saga coordinates a sequence
of local transactions. `Order.place()` succeeds. `InventoryService`
reserves inventory in a separate transaction. If inventory
reservation fails, a compensating transaction cancels the order.
No cross-service ACID transaction - eventual consistency.

Choreography saga: services publish events and react. `OrderPlaced`
event triggers `InventoryService` to reserve. `InventoryFailed`
event triggers `OrderService` to cancel.

Orchestration saga: a central `OrderSaga` service commands each
step. If inventory fails, the orchestrator sends a "cancel order"
command.

When to use saga vs redesign: if the saga involves more than
2-3 services, the compensating transaction logic becomes complex.
Consider whether the service decomposition is wrong. If `Order`
and `Inventory` always change together, they may be the same
Bounded Context.

*What separates good from great:* Most candidates describe sagas.
Great candidates also describe the "avoid cross-service transactions
by redesigning" approach, give the choreography vs orchestration
trade-off (distributed vs central coordinator), and name the
"always change together = same context" heuristic.

---

**Q5 [STAFF]: How do you decompose a domain into microservices?**

*Why they ask:* Tests the design process, not just pattern knowledge.

*Likely follow-up:* "What is the role of Event Storming?"

Decomposition process:

Start with business capabilities: list the top-level business
capabilities (Order Management, Inventory Management, Customer
Management, Payment Processing, Shipping). Each capability is
a microservice candidate.

Validate with DDD Bounded Contexts: run Event Storming. Map domain
events to Bounded Contexts. One Bounded Context = one microservice
candidate. Check: does each context have its own Ubiquitous Language?

Apply the "single team" heuristic: one microservice should be
small enough that a 5-8 person team can fully understand and own
it. If it requires two teams, it may be too large.

Check for cohesion and coupling: high cohesion (functions that
change together live together) and low coupling (the service
communicates through APIs/events, not direct database access).

Apply the "strangler" rule for extraction: when extracting from
a monolith, start with the capability that is most self-contained
(fewest dependencies on other capabilities). Validate the boundary
before fully extracting.

Apply the "two-pizza team" rule (Jeff Bezos): if you can't feed
the team owning the service with two pizzas, the service may be
too large. Not a precise rule but a useful heuristic for ownership.

*What separates good from great:* Most candidates say "decompose
by domain." Great candidates give the full process: business
capabilities, Event Storming validation, team size heuristic,
cohesion/coupling check, and strangler extraction order for
existing systems.

---

**Q6 [SENIOR]: How does API versioning work in microservices?**

*Why they ask:* Independent deployment requires backward-compatible
APIs - tests understanding of the practical constraint.

*Likely follow-up:* "What is Semantic Versioning for APIs?"

Independent deployment requires backward-compatible API changes:
if Service B deploys a new version while Service A is on the old
version, both versions of Service A must work with both versions
of Service B's API.

Breaking vs non-breaking changes:
- Non-breaking (safe): adding new optional fields, adding new
  endpoints, adding new enum values that consumers ignore
- Breaking (requires coordination): removing fields, changing
  field types, removing endpoints, changing required fields

The semantic versioning approach: `/api/v1/orders` and `/api/v2/orders`
run simultaneously. v2 introduces a breaking change. All consumers
migrate to v2. v1 is deprecated and removed when no consumers remain.

The tolerant reader pattern: consumers should ignore unknown fields.
When Service B adds a new optional field to its response, Service A
(a tolerant reader) ignores it. This allows non-breaking changes
without consumer coordination.

Consumer-Driven Contract Testing (CDCT, Pact): consumers define
what they use from the producer's API. The producer runs these
contract tests to ensure it does not break consumers. This catches
breaking changes before deployment without a shared test environment.

*What separates good from great:* Most candidates describe semantic
versioning. Great candidates describe the tolerant reader pattern
(ignore unknown fields), Consumer-Driven Contract Testing as the
pre-deployment safety net, and the process for breaking changes
(dual-version, migrate, deprecate).

---

**Q7 [STAFF]: What are the organizational prerequisites for
microservices success?**

*Why they ask:* Staff signal: microservices is an organizational
solution, not just a technical pattern.

*Likely follow-up:* "Why do microservices often fail in organizations?"

Technical prerequisites: CI/CD pipelines per service (each service
must be independently deployable at any time). Container orchestration
(Kubernetes or equivalent). Service discovery and load balancing.
Distributed tracing (Jaeger, Zipkin). Centralized logging
(ELK stack or equivalent). Circuit breakers and health checks.
API gateway for external traffic.

Organizational prerequisites: "you build it, you run it" culture
(teams own their services end-to-end including production incidents).
DevOps capability (developers operate their own services). Team
autonomy (teams can deploy without coordination with other teams).
Small, stable teams aligned with Bounded Context boundaries.

Why microservices fail: organizations adopt microservices technology
without the organizational change. A monolithic release process
(one weekly deployment for all services) negates all microservices
benefits. Operations owned by a separate "ops team" creates
a handoff bottleneck. Service owners who cannot deploy their
own service cannot achieve autonomous operation.

The minimum viable microservices capability: each team can deploy
their service to production without a change approval board,
without coordinating with another team, and with confidence
(automated tests, canary deployment).

*What separates good from great:* Most candidates describe technical
prerequisites. Great candidates describe the organizational
prerequisites (you build it you run it, DevOps culture, team
autonomy) and explain why technical microservices without
organizational change fails.

---

**Q8 [SENIOR]: Compare microservices, modular monolith, and
SOA as architecture styles.**

*Why they ask:* Tests breadth of architectural knowledge and
ability to compare and choose.

*Likely follow-up:* "For a greenfield application with 10 developers,
which would you recommend?"

SOA (Service-Oriented Architecture): services communicate via
a centralized ESB. Smart pipe, dumb endpoints. ESB handles routing,
transformation, orchestration. Appropriate for legacy enterprise
integration.

Modular monolith: single deployable unit with explicit module
boundaries. Modules communicate via in-process APIs. No distributed
system complexity. Appropriate for teams of fewer than 15 developers,
early-stage products, or when operational maturity is limited.

Microservices: independently deployable services per business
capability. Dumb pipes (HTTP, messaging), smart endpoints. High
operational overhead. Appropriate for large teams needing deployment
autonomy.

For a greenfield with 10 developers: modular monolith. Reason:
(1) you are still discovering the right Bounded Context boundaries -
refactoring within a monolith is cheaper than across service
boundaries; (2) 10 developers do not have the organizational
pressure that makes microservices valuable; (3) the operational
overhead is disproportionate to the team size. Design for
extractability (explicit module boundaries) so microservices
extraction is low-risk when the team grows.

*What separates good from great:* Most candidates advocate
for microservices unconditionally. Great candidates give the
conditional recommendation (modular monolith for 10 developers),
describe "design for extractability" as the forward-compatible
approach, and articulate why the team-size threshold matters.

---

**Q9 [STAFF]: BEHAVIORAL: Describe a time you made or influenced
a microservices architecture decision.**

*Why they ask:* Staff signal - tests real-world experience and
architectural judgment.

*Likely follow-up:* "What would you do differently?"

Strong answer structure:

Situation: "We had a single Spring Boot monolith for our e-commerce
platform. As the engineering team grew from 5 to 30 developers,
we experienced deployment bottlenecks - every team had to wait
for a weekly release window."

Task: "I was asked to architect a migration path to microservices
that maintained development velocity during the transition."

Action: "I ran Event Storming workshops with each domain team.
We identified 5 core Bounded Contexts: Orders, Inventory, Customer,
Payment, Shipping. Rather than a big-bang rewrite, I proposed
a modular monolith as an intermediate step. We enforced module
boundaries with ArchUnit, established CI/CD per module, and extracted
the most isolated context first (Inventory, which had the fewest
dependencies). We built the ACL and event contracts before
splitting the deployment."

Result: "After 6 months, Inventory was a standalone service with
independent deployment. Orders was in progress. The team's mean
time to deploy dropped from weekly to hourly for Inventory.
The modular-monolith phase gave us confidence in the Bounded
Context boundaries before committing to separate deployments."

What I'd do differently: "I would have established distributed
tracing infrastructure before the first service extraction.
We added Jaeger after extraction, and the first two months of
debugging cross-service issues was painful."

*What separates good from great:* Most candidates give a generic
description. Great candidates give specific decisions (Event
Storming, ACL-first, extraction order), specific outcomes (MTDD
metric), and a genuine lesson ("what I'd do differently") that
shows real experience.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Data ownership, distributed transactions, service decomposition |
| Hiring Manager | Team autonomy, organizational prerequisites, trade-off judgment |
| Bar Raiser | Modular monolith vs microservices decision, distributed monolith anti-pattern |
| Peer Engineer | Practical: circuit breakers, service communication patterns |

---

### ⚖️ Comparison Table

| Property | Microservices | Modular Monolith | SOA |
|---|---|---|---|
| Deployment | Independent per service | Single deployable unit | ESB + services |
| Team autonomy | High (own service, own deploy) | Medium (shared deploy) | Low (ESB bottleneck) |
| Operational complexity | High (distributed system) | Low (single process) | Medium (centralized ESB) |
| Network calls | Cross-service HTTP/events | In-process calls | ESB mediation |
| Data isolation | Each service owns its DB | Shared DB with module access rules | Often shared DB |
| Technology choice | Per service | Single codebase | Per service via ESB adapters |
| Debug complexity | High (distributed tracing required) | Low (single process trace) | Medium (ESB logs) |
| Best for | Large teams (20+), different scaling needs | Small-medium teams, early-stage | Legacy enterprise integration |
| Refactoring cost | High (cross-service API changes) | Low (in-process refactoring) | High (ESB + service changes) |
