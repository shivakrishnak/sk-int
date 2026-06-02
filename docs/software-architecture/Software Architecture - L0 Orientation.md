---
layout: default
title: "Software Architecture - L0 Orientation"
parent: "Software Architecture"
grand_parent: "SK Interview"
nav_order: 2
permalink: /software-architecture/l0-orientation/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [What Is Software Architecture](#what-is-software-architecture) | critical |
| 2   | [Architecture Styles Landscape](#architecture-styles-landscape) | high |
| 3   | [Architecture vs Design - Levels of Abstraction](#architecture-vs-design---levels-of-abstraction) | high |

---

# What Is Software Architecture

🎯 Interview Weight: critical - the foundational question in any
architecture interview; calibrates whether the candidate thinks at
system level or only at code level.

---

### 🎯 Model Answer

**30 seconds:**
> Software architecture is the set of significant decisions about
> a system's structure, component responsibilities, and interaction
> patterns that are expensive to change later. It answers three
> questions: what are the system's major components, how do they
> communicate, and which quality attributes (performance, security,
> maintainability) have been prioritized. Architecture is not the
> code - it is the decisions that constrain how code can be written.

**3 minutes (Senior):**
> I define software architecture as the set of decisions you regret
> not making early - because they are expensive to reverse. This is
> the practical test: a decision is architectural if changing it later
> requires significant system-wide rework.
>
> In practice, architecture addresses three layers. First, structure:
> what major components exist and what are their responsibilities?
> Choosing microservices vs monolith shapes how every feature is built
> for years. Second, interaction: how do components communicate?
> Synchronous REST vs asynchronous events is architectural - it
> affects latency, coupling, and failure behavior across the entire
> system. Third, quality attributes: which non-functional requirements
> have been prioritized? A system optimized for consistency
> (a financial ledger) is structured differently from one optimized
> for availability (a product catalog).
>
> The role of the architect is not to make all these decisions alone
> but to establish the decision framework: which decisions require
> architectural alignment, which can be delegated to teams, and which
> guardrails prevent architectural drift.
>
> The non-obvious insight: architecture is not about drawing boxes
> and arrows. It is about making explicit the decisions that would
> otherwise be made implicitly - in ways that optimize locally and
> create global problems.

*Adapting up:* Staff adds: "Architecture is also about enabling
decisions to be reversed. Good architecture isolates high-risk
decisions behind abstractions so they can change later. The best
architects minimize irreversible decisions, not maximize diagrams."

*Adapting down:* Junior: "Software architecture is the big-picture
design - which major components exist, how they talk, and which
quality properties (speed, security, reliability) are most important.
The blueprint before the code."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking what software architecture is -
let me walk through what decisions it covers and why they matter."

**(2) First principles:** "Any system has structure (what parts),
interaction (how parts communicate), and constraints (what properties
matter). Architecture is the set of decisions about all three that
are expensive to change later."

**(3) Bridge:** "Architecture is like a city plan. The city plan
decides where roads, parks, and zones go. Individual buildings (code)
can change, but moving a road is expensive. Architecture decisions
are the roads - they constrain everything built on top."

---

### 📘 Concept Explanation

**What it is:**
Software architecture is the set of significant structural decisions
about a system - the decomposition into major components, the
interaction patterns between them, and the quality attributes
explicitly traded off against each other. Architecture decisions
are expensive to change later.

**The problem it solves:**
Without explicit architecture, each team makes local decisions that
are individually reasonable but globally incoherent. One team builds
synchronous calls; another builds async events; a third uses shared
databases. The result: a system where scaling one part requires
understanding all parts, and changing one component cascades
unexpectedly to others.

**How it works:**

```
Architecture answers four questions:

1. DECOMPOSITION
   What major components exist?
   Component = deployable unit or significant boundary
   (service, module, layer, subsystem)
   Decision: monolith vs microservices? Domain boundaries?

2. INTERACTION
   How do components communicate?
   Synchronous (REST, gRPC): immediate response expected
   Asynchronous (events, queues): decoupled timing
   Decision affects: latency, coupling, failure modes

3. DATA OWNERSHIP
   Who owns which data?
   Shared DB = implicit coupling
   DB-per-service = deployment independence
   Decision affects: consistency, team autonomy

4. QUALITY ATTRIBUTES
   What is prioritized?
   Availability vs consistency (CAP theorem trade-off)
   Performance vs maintainability
   Security vs developer velocity

Architecture DECISIONS = explicit answers to these four.
Architecture DOCUMENT = record of decisions AND their rationale.
```

> **Code walkthrough:** This What Is Software Architecture example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Architecture is not the code - it is the decisions that constrain
how code can be written. Test: "if I want to change this decision,
how expensive is the rework?" Expensive-to-change decisions are
architectural. Cheap-to-change decisions are implementation details.

**When to use it:**
At the start of a new system. When a system reaches the limits of
its current architecture (scaling, team growth). When non-functional
requirements change significantly (startup MVP to regulated enterprise).

**When NOT to use it:**
Over-architecturing early-stage systems is a common mistake. A startup
with five engineers and one service does not need microservices - it
needs a modular monolith with clear internal boundaries that can be
extracted later. "Big Design Up Front" is an antipattern when
requirements are uncertain.

**Alternatives:**
- Emergent architecture - let structure evolve from refactoring
- No explicit architecture - common in small teams, creates chaos at scale
- Evolutionary architecture - design explicitly for changeability over time

**First-principles derivation:**
As a system grows, it faces a combinatorial explosion of decisions:
how to split work, how to deploy, how to ensure quality. Without
a framework for making and communicating these decisions, they are
made ad hoc and locally. Local decisions optimize locally and
create global problems. Architecture is the mechanism for making
decisions globally - ensuring local choices serve the system's
overall quality attributes.

---

### 💻 Code Example

*(Omit: Software architecture is a design discipline, not a
programmatic concept. Code examples appear in specific architecture
style keywords: Clean Architecture, Hexagonal Architecture, etc.)*

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Software architecture is the big-picture design of a system: what
> major components exist (services, modules, layers), how they
> communicate (REST, events, shared database), and what quality
> properties are most important (speed, reliability, security).
> Architecture decisions are expensive to change - once you build
> twenty services communicating via REST, switching to an event-
> driven model requires touching all twenty.

*Push deeper:* Explain the "expensive to change" test. Give an
example: choosing a database (SQL vs NoSQL) is architectural because
migrating 10 million records and changing all data access code is
expensive. Choosing variable names is not architectural.

---

**Senior / Staff (5+ years):**
> I think of architecture as the set of decisions you regret not
> making early - because they are expensive to reverse. It covers
> four things: component decomposition (what major boundaries exist),
> interaction patterns (sync vs async, who calls whom), data
> ownership (who owns which data), and quality attribute trade-offs
> (what have we prioritized - consistency, availability, maintainability).
>
> The role of the architect is to make these decisions explicit.
> In the absence of explicit architecture, teams make implicit
> architectural decisions every day - and those implicit decisions
> tend to optimize locally and create global problems. The architect
> is not a solo decision-maker but a decision facilitator who ensures
> the team has the framework to make good local decisions that are
> globally coherent.

*Push deeper:* Staff angle: "The best architectural decision is
often the one that preserves optionality - keeps expensive choices
reversible by isolating them behind abstractions. An architecture
that explicitly says 'we are uncertain about this decision' and hides
it behind an interface is more valuable than one that commits early
and requires a rewrite to change."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Architecture means UML diagrams and documents | Architecture is decisions and rationale; documents are a medium, not the goal |
| The architect writes the architecture, developers write the code | Architecture is a team activity; the best architectures emerge from developers with architectural guidance |
| More architecture is always better | Over-architecture is as harmful as under-architecture; architecture for uncertainty creates waste |
| Architecture is fixed at project start | Architecture evolves; evolutionary architecture explicitly designs for change over time |
| Microservices is "correct" architecture | Microservices is one style with specific trade-offs; a modular monolith is correct for many systems |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Implicit architecture (no architecture)**

*Symptom:* Every team makes its own decisions about communication
patterns, data storage, and deployment. The system is a patchwork
of incompatible choices.

*Root cause:* Architecture decisions left to local teams without
a shared framework. Each team optimizes locally.

*Diagnostic:*
```
- How many different communication patterns in one system?
  (REST, gRPC, GraphQL, events, direct DB - all present)
- How many different database technologies?
- Can a new engineer understand the system from documentation?
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Retrospective architecture review. Document the as-is
state. Identify which decisions created the most pain. Write ADRs.
Publish standards (not mandates) for new development.

*Prevention:* Architecture Decision Records from the start.
Even a one-page "why we chose X" is more valuable than a formal
document created to satisfy a process.

**Failure 2: Big Design Up Front (over-architecture)**

*Symptom:* Six months of architecture design before any code.
Architecture becomes stale as requirements change. Developers
work around the architecture because it does not fit reality.

*Root cause:* Treating architecture as a one-time design phase
rather than an ongoing practice. Designing for requirements that
are not yet known.

*Diagnostic:*
```
- How long since the architecture document was updated?
- How often do developers say "the architecture says X but
  in practice we do Y"?
- How many architecture decisions are reversed after
  implementation begins?
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Shift to just-in-time architecture. Make the minimum
decisions needed to start. Defer decisions that can be deferred.
Record decisions as they are made (ADRs), not all upfront.

*Prevention:* Apply YAGNI to architecture. Make minimum irreversible
decisions first. Build thin vertical slices quickly to validate
assumptions.

**Failure 3: Architecture drift**

*Symptom:* The documented architecture does not match the actual
system. New engineers learn the architecture but the codebase tells
a different story. "Accidental architecture" has emerged.

*Root cause:* Architecture decisions made at start but not enforced
or evolved as the system grew. Developers made pragmatic deviations
without updating the architecture.

*Diagnostic:*
```bash
# Check if layer boundaries are respected (example):
# In a layered architecture, does the data layer
# import from the presentation layer?
grep -r "import.*presentation" src/data/
grep -r "import.*controller" src/repository/
```

> **Code walkthrough:** This import from the presentation layer? example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*Fix:* Architecture fitness functions. Automated tests that verify
architectural constraints: ArchUnit for Java, dependency-cruiser
for Node.js. Tests fail when code violates architecture boundaries.

*Prevention:* Architecture as a living document. ADRs for every
major decision. Regular architecture reviews (quarterly).
Fitness functions that automatically detect drift.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 15 minutes |
| Core themes | Definition, decisions, quality attributes, architect role |
| Seniority signal | Junior: defines structure; Senior: quality attributes and trade-offs |
| Common trap | Conflating architecture with implementation or with diagrams |
| Staff differentiator | Architecture as enabling reversibility |

---

**Q1 [JUNIOR]: What is software architecture?**

*Why they ask:* Calibration question. The answer reveals whether
the candidate thinks at system level (architecture) or code level
(implementation).

*Likely follow-up:* "What makes a decision architectural?"

about a system that are expensive to change later. It covers: what
major components exist (services, modules, layers), how they
communicate (REST, events, shared database), who owns which data,
and which quality properties have been prioritized (performance,
security, maintainability).

The practical test for whether a decision is architectural: how
expensive would it be to change this decision after the system is
built? Choosing between REST and gRPC is architectural - changing
it later requires updating all client and server implementations.
Choosing how to name a method is not architectural - it is cheap
to rename with an IDE.

I think of architecture as the skeleton of the system. The skeleton
constrains the shape of everything built on it. You can change
muscles (code) relatively easily. Changing the skeleton (architecture)
requires much more significant surgery.

*What separates good from great:* Most candidates describe
architecture as "big picture design" or "boxes and arrows." Great
candidates explain the "expensive to change" criterion that
distinguishes architectural from implementation decisions. The
skeleton analogy or the "decisions you regret not making early"
test shows internalized understanding.

---

**Q2 [MID]: What is the difference between an architect's job and
a senior developer's job?**

*Why they ask:* Tests whether the candidate has thought about career
progression and what architectural thinking actually means in practice.

*Likely follow-up:* "Can developers make architectural decisions?"

The distinction is not seniority but scope and reversibility.
A senior developer makes the best decision for the code they are
writing - local optimization. An architect considers how that
decision affects the overall system, other teams, and future decisions.

Concretely: a senior developer chooses the best algorithm for a
component. An architect decides whether that component should be
a library called in-process or a service called via API - a decision
that affects deployment, versioning, team ownership, and performance
across the entire system.

But this does not mean architects make all decisions. The most
effective architects establish the decision framework: which decisions
require architectural review, which can be made by teams autonomously,
and what guardrails prevent local decisions from creating global
problems. They enable good decisions rather than making all decisions.

Every experienced developer makes some architectural decisions.
The difference is intentionality - architects make these decisions
explicitly, with visibility into the full system, and document the
rationale so future decisions can build on them.

*What separates good from great:* Most candidates describe the
architect as "more senior" or "draws the diagrams." Great candidates
explain the scope difference (local vs global optimization) and the
enabling vs mandating distinction. The best describe architecture
as a team practice, not a solo role.

---

**Q3 [SENIOR]: How do you decide which decisions are architectural
vs implementation details?**

*Why they ask:* Tests whether the candidate has an operational
definition they actually use, not just theoretical knowledge.

*Likely follow-up:* "Give an example of a decision you initially
treated as implementation that turned out to be architectural."

My working test: "How expensive is it to change this decision after
the system is built?" If expensive - requires changes across many
components, teams, or deployments - it is architectural. If cheap
- I can change it in one file - it is an implementation detail.

Some decisions look like implementation but are architectural:
the choice of HTTP caching headers (affects every CDN in front of
the service), the format of IDs (UUID vs auto-increment - determines
whether you can shard), the decision to use shared transactions
across services (determines whether services can deploy independently).

I made the mistake in the other direction: treating the choice of
an ORM as architectural when it was not. We spent two weeks evaluating
Hibernate vs JDBC in an architecture review. We could have changed
the ORM in a week of coding. It was an implementation detail dressed
up as an architecture decision.

The other useful test: "Who needs to know about this decision?"
Decisions that affect multiple teams, their interfaces, or their
deployment timelines are architectural. Decisions that affect one
team's internal implementation are not.

*What separates good from great:* Most candidates describe
architecture as "big" decisions without a clear criterion. Great
candidates give an operational test ("expensive to change" or "who
needs to know") and an example where they classified wrong in both
directions - treated an implementation detail as architectural
(waste) and vice versa (technical debt).

---

**Q4 [STAFF]: What is evolutionary architecture and when is it
appropriate?**

*Why they ask:* Tests whether the candidate knows architectural
approaches beyond "design up front" - a staff-level design
philosophy question.

*Likely follow-up:* "What are fitness functions in evolutionary
architecture?"

Evolutionary architecture is the practice of designing systems to
accommodate change over time rather than designing them to be
"correct" upfront. The core idea from Ford, Parsons, and Kua:
architecture evolves through guided change - fitness functions
measure whether the architecture still supports its quality
attributes as it changes.

It is appropriate when: requirements are uncertain (early-stage
products), the system will grow in unpredictable directions
(platform businesses), or the team has learned from past
over-architecture.

The key mechanism is fitness functions: automated tests that verify
architectural properties. "All service calls must complete in under
200ms at p99" is a fitness function. "No module in the core layer
may import from the infrastructure layer" is a fitness function.
These run in CI/CD and fail the build if architecture drifts.

Without fitness functions, evolutionary architecture becomes just
"we will figure it out later" - an excuse for no architecture.
With fitness functions, you get continuous verification that the
architecture evolves within intended boundaries.

*What separates good from great:* Most candidates say "make it
flexible." Great candidates describe fitness functions as the
mechanism that makes evolutionary architecture disciplined. Specific
examples (performance budgets, layer dependency checks, API
compatibility tests) are the staff differentiator.

---

**Q5 [STAFF]: How do you communicate architecture decisions to
non-technical stakeholders?**

*Why they ask:* Staff architects must bridge technical teams and
business stakeholders. The ability to translate is a staff-level skill.

*Likely follow-up:* "What happens when a non-technical stakeholder
overrules an architectural decision?"

The key is translating architectural decisions into business
consequences, not technical mechanisms. Stakeholders care about
time to market, cost of change, risk of failure, and compliance.
They do not care about microservices vs monolith.

For a major architectural decision I present three things. First:
the context - what problem are we solving and what constraints do
we have? Second: two or three options with their business consequences
(not technical merits). Third: my recommendation and the trade-off
I am accepting.

For example: "We need to decide whether to keep the payments system
as part of our main application or separate it. Option A (keep
together): faster to build initially, but any bug in the rest of
the application can cause payment failures and PCI audit scope
covers everything. Option B (separate service): 6 weeks more work
initially, but payment failures are isolated and PCI audit scope
is 90% smaller." That is an architectural decision in business
language.

When a non-technical stakeholder overrules: I respect the decision
but document the trade-off they accepted ("Option A chosen; the
accepted risk is full PCI scope exposure"). If the risk materializes,
the team is protected.

*What separates good from great:* Most candidates describe "using
simpler language." Great candidates describe the frame shift: from
technical mechanisms to business consequences. The ADR-as-protection
strategy (documenting accepted risks) is the staff differentiator.

---

**Q6 [SENIOR]: What is the relationship between architecture and
technical debt?**

*Why they ask:* Tests whether the candidate understands that
architectural decisions create the environment in which technical
debt accumulates or is controlled.

*Likely follow-up:* "How do you prioritize architectural improvements
vs new features?"

Architecture and technical debt have a parent-child relationship.
Architectural decisions create the context in which debt accumulates.
A monolith with tightly coupled components does not just have a bad
architecture - it has a context where every feature adds more
coupling, making debt grow exponentially. A well-architected system
with clear boundaries allows debt to accumulate locally within
components, not across the entire system.

The most dangerous technical debt is architectural debt: decisions
that were correct at a system's smaller scale but become constraints
as it grows. A shared-database design is appropriate for a team
of five. At 50 engineers, it becomes a bottleneck (schema change
coordination) and a source of accidental coupling. Fixing it
requires architectural change, not just refactoring.

For prioritization: I use error budget thinking. "Our shared
database causes three migrations per sprint to be coordinated
across four teams, costing roughly one sprint per quarter in
coordination overhead." Make the cost visible. Stakeholders can
make rational prioritization when the trade-off is explicit.

*What separates good from great:* Most candidates describe technical
debt as "messy code." Great candidates distinguish architectural
debt (structural constraints from past decisions) from code debt
(quality issues within components). The quantification approach
(coordination cost per sprint) is the senior differentiator.

---

**Q7 [STAFF]: What makes a software architect effective vs one
who is a bottleneck?**

*Why they ask:* Tests understanding of organizational dynamics -
a critical staff question about engineering leadership.

*Likely follow-up:* "How do you avoid being the gatekeeper?"

The central tension in architecture is between centralization (for
coherence) and decentralization (for velocity). An effective
architect navigates this by clearly distinguishing centralized
decisions (architectural standards, integration patterns, security
requirements) from delegated decisions (implementation choices
within those boundaries).

An architect becomes a bottleneck when they require sign-off on
implementation decisions - choosing which library to use for an
internal function, approving the structure of an internal module.
This is the wrong level. It creates dependency without value.

The best pattern: publish guardrails, not mandates. A guardrail
says "all service APIs must support versioning" and leaves
implementation choice to the team. A mandate says "use this exact
versioning library and this exact pattern." Guardrails enable
autonomy within boundaries. Mandates create dependency.

The other pattern: architecture as a service (the platform team
model). Instead of approving decisions, the architect team builds
templates, libraries, and golden paths that make the right way
the easy way. Teams opt in because it is easier than building
from scratch, not because they are required to.

*What separates good from great:* Most candidates describe good
communication. Great candidates describe the structural mechanism:
guardrails vs mandates, and the "architecture as a service" model
where the right way is the easy way. Specific examples make the
distinction concrete.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Definition precision: what makes a decision architectural |
| Hiring Manager | Business value: architecture reduces cost of change |
| Bar Raiser | Trade-offs: over-architecture vs under-architecture |
| Peer Engineer | Practical: how architecture decisions are made and recorded |

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# Architecture Styles Landscape

🎯 Interview Weight: high - interviewers use this to calibrate
whether the candidate has breadth (knows multiple styles) and can
apply trade-off thinking (knows when each style fits).

---

### 🎯 Model Answer

**30 seconds:**
> Software architecture styles are recurring high-level organizational
> patterns for entire systems. Major styles: Layered (organize by
> technical concern), Hexagonal (isolate domain from infrastructure),
> Event-Driven (communicate via events for decoupling), Microservices
> (deploy independently by domain), and Serverless (push operational
> concerns to the platform). Each style optimizes for different
> trade-offs - there is no universally correct style, only styles
> that fit a given context better than others.

**3 minutes (Senior):**
> I categorize architecture styles along two axes: deployment coupling
> (one deployable unit vs many independent deployables) and
> communication coupling (synchronous shared state vs asynchronous
> events). These axes are orthogonal - you can have a monolith with
> event-driven internal communication, or microservices with
> synchronous REST calls.
>
> Monolithic styles - Layered, Modular Monolith - have a single
> deployment unit. Simpler to develop, test, and debug, but scale
> as a unit and make independent team deployment harder.
>
> Service-oriented styles - SOA, Microservices, Serverless - decompose
> into independently deployable units. They enable team autonomy and
> independent scaling but introduce distributed system complexity:
> network failures, latency, consistency challenges, and operational
> overhead.
>
> The non-obvious insight: most production systems are hybrids.
> They have a modular monolith for core functionality, a few
> microservices for genuinely independent capabilities, and event
> streams for cross-domain communication. Pure style implementations
> are textbook examples; production is a spectrum.

*Adapting up:* Staff adds: "Style selection is a business decision
masquerading as a technical one. Microservices optimize for team
autonomy at the cost of distributed complexity. A startup with ten
engineers choosing microservices is optimizing for a problem they
do not yet have."

*Adapting down:* Junior: "Architecture styles are patterns for how
to organize a whole system. Layered (presentation-business-data)
is the most common. Microservices splits into many small independent
services. Event-driven uses a message bus instead of direct calls.
Each has different trade-offs."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about architecture styles - let
me walk through the major ones and what each optimizes for."

**(2) First principles:** "Every architecture style makes a choice
on two axes: how many deployment units, and how do those units
communicate. Monolith vs microservices is the first. Synchronous
vs asynchronous is the second."

**(3) Bridge:** "Architecture styles are like city layouts. A
traditional city is one connected organism (monolith). A suburban
sprawl is many independent zones connected by highways
(microservices). Each suits a different combination of density,
traffic patterns, and governance needs."

---

### 📘 Concept Explanation

**What it is:**
Architecture styles are named, recurring organizational patterns
for entire systems. They describe the high-level structure of
components and their interaction patterns. Unlike design patterns
(component-level), architecture styles describe system-wide
organizational approach.

**The problem it solves:**
Without named styles, each new system is designed from scratch with
no shared vocabulary for trade-offs. Named styles provide shorthand
that conveys a full set of design decisions, trade-offs, and known
failure modes in one word.

**How it works:**

```plaintext
LAYERED (N-TIER)
  Presentation -> Business Logic -> Data Access
  Coupling: each layer calls only the layer below
  Best for: traditional web apps, CRUD systems
  Trade-off: changes often span all three layers

HEXAGONAL (PORTS AND ADAPTERS)
  Domain Core <-> Ports <-> Adapters (DB, UI, APIs)
  Coupling: domain does NOT depend on infrastructure
  Best for: domain-rich systems, swappable technology
  Trade-off: more abstractions to manage

EVENT-DRIVEN
  Components communicate via events (pub/sub or queue)
  Coupling: producers do not know consumers
  Best for: async workflows, audit trails, decoupling
  Trade-off: harder to trace, eventual consistency

MICROSERVICES
  Many independently deployable services by domain
  Coupling: API contracts between services
  Best for: large teams, independent scaling
  Trade-off: distributed system complexity

SERVERLESS / FaaS
  Functions deployed to cloud, infrastructure managed
  Coupling: event triggers, API gateway
  Best for: spiky workloads, operational simplicity
  Trade-off: cold starts, vendor lock-in, limited runtime

MODULAR MONOLITH
  Single deployment unit, clean internal module boundaries
  Coupling: in-process calls, bounded modules
  Best for: small teams, early stage, clear domains
  Trade-off: scales as a unit when scaling is needed
```

> **Code walkthrough:** This Architecture Styles Landscape example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
No architecture style is universally correct. Each is a set of
trade-offs optimized for specific constraints. Microservices is
not "better" than monoliths - it solves different problems (team
autonomy, independent scaling) at different cost (distributed
complexity, operational overhead).

**When to use it:**
Layered for simple CRUD systems with a small team. Hexagonal when
the domain is complex and infrastructure will change. Event-Driven
for loose coupling between domains. Microservices when team size
and independent deployment requirements justify operational
complexity. Serverless for spiky, stateless workloads.

**When NOT to use it:**
Microservices for a team under 10 engineers is premature - operational
complexity exceeds the team coordination benefit. Event-Driven for
simple synchronous request-response workflows adds unnecessary
complexity. Serverless for long-running or latency-sensitive
workloads is inappropriate.

**Alternatives:**
- Modular Monolith - single deployment with internal boundaries (often the right starting point)
- Mini-services - a middle ground between micro and mono
- Service Mesh - adds observability/routing to microservices without changing the style

**First-principles derivation:**
Any system faces three tensions: (1) deployment flexibility (how
quickly can you change and deploy parts independently), (2)
operational simplicity (how easy is it to run and debug), and
(3) team autonomy (can teams work without coordinating). No single
style maximizes all three. Architecture styles are named trade-offs
along these three dimensions.

---

### 💻 Code Example

*(Omit: Architecture styles are structural patterns for systems,
not programming interfaces. Code examples for specific styles
appear in their individual keyword entries: Layered Architecture,
Hexagonal Architecture, Clean Architecture, CQRS, etc.)*

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Architecture styles are patterns for organizing entire systems.
> The most common is Layered - three tiers: presentation (web, API),
> business logic, and data access. Microservices splits the system
> into many small services, each independently deployable,
> communicating via APIs. Event-Driven uses messages so services do
> not directly call each other - they publish events and subscribe
> to them. Each style has trade-offs: microservices enables independent
> scaling but adds distributed system complexity; layered is simple
> but scales as one unit.

*Push deeper:* Explain the Modular Monolith - a single deployment
unit with clean internal module boundaries. Often the right starting
point before deciding whether microservices are needed.

---

**Senior / Staff (5+ years):**
> I categorize architecture styles along two axes: deployment topology
> (monolithic vs distributed) and communication pattern (synchronous
> vs asynchronous). These are orthogonal.
>
> For most new systems I recommend a modular monolith - clean module
> boundaries, single deployment, no distributed system complexity.
> Extract services when you have a specific, demonstrated need: a
> component that scales differently, a team that needs full autonomy,
> or a component with a dramatically different lifecycle. Do not
> design microservices up front for a system whose domain boundaries
> you have not yet discovered.
>
> The most common mistake: choosing microservices for a new product
> and spending 60% of engineering time on infrastructure (service
> mesh, distributed tracing, container orchestration) instead of
> the product itself.

*Push deeper:* Staff angle: "Architecture style selection is primarily
a team topology decision. Microservices optimize for team autonomy -
if a team cannot independently build, test, and deploy their service,
they do not have microservices, they have a distributed monolith
with extra complexity."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Microservices is the modern/correct architecture | Microservices solves team autonomy and independent scaling problems that small teams do not have |
| Event-Driven and Microservices are the same thing | EDA is a communication pattern; microservices is a deployment topology - orthogonal and combinable |
| A monolith is legacy/bad | A well-structured modular monolith is simpler, easier to debug, and often faster for small-medium systems |
| Serverless eliminates architecture decisions | Serverless eliminates infrastructure decisions; architectural decisions (data ownership, boundaries, communication patterns) remain |
| More services equals better architecture | Service granularity should match team granularity; more services than teams creates overhead without autonomy benefit |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Distributed monolith**

*Symptom:* Many independently deployed services but deployments
must still be coordinated because services share a database,
have long synchronous call chains, or have tight API coupling.

*Root cause:* Microservices style chosen but coupling patterns of
a monolith retained. Services share databases (shared state) and
have synchronous call chains (tight operational coupling).

*Diagnostic:*
```
- How many services must be deployed in a single release?
  (> 2 = likely distributed monolith)
- Do multiple services share a database schema?
- Is there a long synchronous call chain across 4+ services
  for a single user request?
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Address the coupling, not just the deployment topology.
Each service needs its own database. Long synchronous chains must
be broken with events or async patterns. API contracts must be
versioned so services can deploy independently.

*Prevention:* Validate the "independent deployability" rule before
calling the system microservices: can each service be deployed
without coordinating with any other?

**Failure 2: Architecture style mismatch to team size**

*Symptom:* Small team (5-10 engineers) spending majority of time
on infrastructure and coordination overhead (container orchestration,
service mesh, distributed tracing) rather than on product features.

*Root cause:* Microservices chosen before team size and domain
complexity justified it. Complexity imported without the benefits.

*Diagnostic:*
```plaintext
- Ratio of infrastructure code/config to business logic
- Time spent per sprint on deployment/infrastructure vs features
- How many of the services could reasonably be merged?
  (> 30% = probably too granular)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Consolidate services aggressively. The rule: one team should
own 3-5 services maximum. If a team owns 10 services, most should
be merged.

*Prevention:* Start with a modular monolith. Split into services
only when a specific, demonstrated need exists.

**Failure 3: Style selected without trade-off awareness**

*Symptom:* Architecture chosen because it is "the industry standard"
rather than because it fits the system's specific constraints.

*Root cause:* Architecture decision made without explicitly
identifying the primary quality attribute to optimize for.

*Diagnostic:*
```
Ask the team: "Why did we choose this architecture style?"
Answers indicating a problem:
- "Because everyone uses microservices now"
- "Because it is more scalable" (without knowing actual scale
  requirements)
- "Because our previous company used it"
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Run Architecture Trade-Off Analysis. Identify top 3 quality
attributes the system must prioritize. Select the style that best
fits. Document the decision.

*Prevention:* Before selecting a style, explicitly list constraints:
team size, domain complexity, performance requirements, compliance.
Then evaluate styles against those constraints.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | Style comparison, trade-offs, when to use each |
| Seniority signal | Junior: knows the names; Senior: knows the trade-offs |
| Common trap | Treating microservices as universally correct |
| Staff differentiator | Team topology drives style choice |

---

**Q1 [JUNIOR]: What is the difference between a monolith and
microservices?**

*Why they ask:* Fundamental vocabulary check. Tests whether the
candidate knows the trade-offs, not just the definitions.

*Likely follow-up:* "Which would you choose for a new project?"

A monolith is a single deployable unit where all components share
the same runtime process and are deployed together. A microservices
system is many independently deployable services, each running
in its own process and communicating over a network.

Key trade-offs: Monolith pros - simple to develop locally, easy
to test (no network), fast in-process calls, simple debugging.
Monolith cons - scales as a unit, team coupling, deployment risk.

Microservices pros - independent scaling, independent deployment,
fault isolation. Microservices cons - distributed system complexity
(network failures, latency), operational overhead (container
orchestration, service mesh, distributed tracing), data consistency
challenges.

For a new project: I start with a modular monolith. The domain
boundaries are not yet clear, the team is small, the product is
not yet validated. Microservices complexity is imported before
the benefits are earned. Once the domain is understood and teams
are growing, I extract services at natural boundary points.

*What separates good from great:* Most candidates list pros and
cons. Great candidates explain that the choice is team-topology-
driven: microservices make sense when teams can own entire domains
and deploy independently. Without that team structure, you have
a distributed monolith, not microservices.

---

**Q2 [MID]: What is Event-Driven Architecture and when is it
appropriate?**

*Why they ask:* Many candidates conflate EDA with microservices.
Tests conceptual clarity.

*Likely follow-up:* "What are the trade-offs of eventual consistency?"

Event-Driven Architecture is a communication pattern where
components communicate by producing and consuming events rather
than making direct API calls. When Order Service processes an
order, it publishes an `OrderPlaced` event to a message broker.
Any service that cares about orders - Inventory, Billing,
Notifications - subscribes independently.

EDA is appropriate when: the action and its downstream effects
are not tightly coupled (placed order does not need to wait for
the notification to be sent), you need an audit trail (every event
is a record), you need to add new consumers without modifying
producers (open/closed at service level), or you need to handle
spiky load (message queue absorbs the burst).

Not appropriate when: the caller needs an immediate response
(synchronous REST is simpler), the downstream action must complete
before the caller's action is considered done (saga pattern needed,
which adds complexity), or the domain requires strong consistency.

*What separates good from great:* Most candidates describe pub/sub.
Great candidates explain the eventual consistency consequence and
when it is acceptable. The "add new consumers without modifying
producer" benefit and the strong consistency disqualifier are the
mid-level differentiators.

---

**Q3 [SENIOR]: How do you choose between architecture styles for
a new system?**

*Why they ask:* Tests whether the candidate has a decision framework
or just picks the current trendy architecture.

*Likely follow-up:* "Walk me through a specific decision you made."

I use a three-step process.

Step 1: Identify the primary constraints and quality attributes.
Not all quality attributes are equal - typically two or three
dominate. "We need high availability" is a constraint. "Our team
of five needs to ship fast" is a constraint. "We have strict PCI
compliance" is a constraint.

Step 2: Evaluate candidate styles against each constraint.
For a team of five with tight deadlines: modular monolith wins
on team velocity; microservices loses on operational overhead.
For a team of fifty with three independent product areas:
microservices wins on team autonomy; monolith loses on deployment
coordination.

Step 3: Select the simplest style that meets the constraints.
Simplicity is a quality attribute. The simplest style that meets
your constraints is usually correct. Do not import complexity
you have not yet earned.

I applied this for a new fintech product: five engineers, early
stage, high regulatory requirements. Constraints: ship fast
(simple architecture), PCI compliance (isolated payment processing).
We chose a modular monolith with one separate payment service for
PCI scope isolation. Not full microservices - just the one service
where compliance required isolation.

*What separates good from great:* Most candidates describe trade-offs
of each style. Great candidates describe a decision PROCESS:
constraints first, then style evaluation, then simplest fit. The
specific example with explicit constraints is the senior differentiator.

---

**Q4 [STAFF]: Why do many microservices migrations fail?**

*Why they ask:* Tests whether the candidate has seen the migration
pattern and understands the systemic failure modes.

*Likely follow-up:* "What would you do differently?"

Microservices migrations fail for three consistent reasons.

First: they address the wrong problem. Microservices solve team
autonomy and independent scaling. If the real problem is slow
development velocity caused by poor code quality or unclear domain
model, microservices do not help - they add complexity on top.
The distributed version of a big ball of mud is still a big ball
of mud.

Second: the team does not change with the architecture. Conway's
Law means the architecture mirrors the team structure. If you
decompose a monolith into services without reorganizing teams to
match the service boundaries, the teams recreate the original
coupling across service boundaries - now with network hops.
The "distributed monolith" failure mode.

Third: the migration is done as a big-bang rewrite. The Strangler
Fig pattern - wrapping the monolith and extracting services
incrementally while it still runs - is more successful because
risk is contained. A full rewrite has a multi-year runway with
no value delivery, and requirements change before it finishes.

*What separates good from great:* Most candidates describe
microservices trade-offs. Great candidates describe the failure
pattern: solving team/code problems with architecture, misaligned
team structure (Conway's Law), and the big-bang rewrite trap.
The Strangler Fig recommendation is the staff differentiator.

---

**Q5 [SENIOR]: When is Serverless the right architecture style?**

*Why they ask:* Tests trade-off awareness for a newer style.
Candidates who cannot articulate limitations reveal shallow knowledge.

*Likely follow-up:* "What are the limitations of Serverless for
production systems?"

Serverless is right when: the workload is event-driven and spiky
(periodic batch jobs, webhook handlers, image processing pipelines),
operational simplicity matters more than control, the cost model
of paying per invocation is favorable (low or unpredictable volume),
and execution time is short (under the 15-minute Lambda limit).

Limitations that disqualify Serverless: cold starts introduce
latency unacceptable for user-facing requests (though provisioned
concurrency mitigates this at cost), long-running computations
exceed time limits, vendor lock-in is significant (Lambda + API
Gateway + DynamoDB tightly couples you to AWS), and local
development is harder than with containerized services.

In practice: I use Serverless for non-critical-path workloads in
a larger system. A webhook ingestion endpoint (Serverless) that
enqueues to Kafka, consumed by a traditional microservice for
complex processing. Best fit: asynchronous background processing
where cold starts are acceptable and the function is small.

*What separates good from great:* Most candidates describe Serverless
as "no infrastructure to manage." Great candidates give specific
disqualifying conditions (cold start latency budget, execution
time limits, vendor lock-in) and describe the hybrid pattern.

---

**Q6 [STAFF]: How do you evaluate whether to decompose a modular
monolith into microservices?**

*Why they ask:* Tests whether the candidate can make the migration
decision with rigor rather than following trends.

*Likely follow-up:* "What triggers the extraction of a service?"

The decision to extract a service should be driven by a specific,
demonstrated problem. I use five triggers.

First: the component has genuinely different scaling requirements.
If image processing needs 100x more CPU during campaigns but the
rest of the application has low utilization, extraction enables
independent scaling.

Second: a team needs full deployment autonomy. If the payments team
is blocked on a shared deployment train every two weeks, extraction
enables independent shipping.

Third: a component has dramatically different reliability
requirements. If reporting can tolerate hours of downtime but order
processing needs five-nines, isolation prevents reporting failures
from affecting orders.

Fourth: a component needs different technology. If ML inference
needs Python and CUDA but everything else is Java, extraction
enables the right technology choice without polluting the monolith.

Fifth: a compliance boundary demands isolation. PCI DSS requires
isolating cardholder data. Extraction creates a smaller compliance
scope.

If none of these five triggers apply, the modular monolith is
correct for now. Wait for the signal, then extract.

*What separates good from great:* Most candidates say "extract when
you need to scale independently." Great candidates give all five
triggers with specific problems each extraction solves. The
compliance isolation trigger and the team autonomy (not technical)
framing are the staff differentiators.

---

**Q7 [SENIOR]: What is the strangest architecture that has worked
well in your experience?**

*Why they ask:* Tests adaptability and experience. Candidates with
real production experience have seen unconventional systems succeed.

*Likely follow-up:* "Would you recommend it to others?"

The most unconventional architecture I have seen work well was a
"micro-monolith" at a fintech company: a single deployable JAR
containing 15 well-bounded modules communicating via in-process
events (Guava EventBus). No microservices, but not a traditional
layered monolith - each module had strict dependency rules enforced
by ArchUnit, its own domain model, and was extractable as a
standalone service when needed.

It worked because: the team was 12 engineers on the same product,
deployment was monthly (fintech compliance requirements), and the
domain was well-understood. In-process event-driven communication
gave the loose coupling of EDA without distributed system complexity.
ArchUnit gave architectural integrity without the operational overhead.

I would recommend it for teams with: a well-understood domain (stable
module boundaries), infrequent deployment windows (compliance,
regulated industries), and a team small enough to fit in one product.
The pattern collapses when the domain grows beyond what one team can
hold and teams need independent deployment.

*What separates good from great:* "I always use standard patterns"
reveals limited production exposure. Great candidates describe a
specific unconventional choice with the constraints that made it
succeed and the conditions that would cause it to fail.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Trade-off precision: specific constraints that favor each style |
| Hiring Manager | Business impact: style choice affects team velocity and cost |
| Bar Raiser | When microservices is wrong: the distributed monolith failure mode |
| Peer Engineer | Practical: specific style chosen recently and why |

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# Architecture vs Design - Levels of Abstraction

🎯 Interview Weight: high - frequently asked to distinguish candidates
who think at system level from those who only think at code level.

---

### 🎯 Model Answer

**30 seconds:**
> Architecture and design are both about structure but at different
> levels of abstraction and reversibility. Architecture: system-wide
> structure, component boundaries, communication patterns, quality
> attribute trade-offs - expensive to change. Design: class-level
> structure, algorithms, patterns within a component - cheap to
> change. The test: "how expensive is it to change this decision?"
> Expensive = architecture. Cheap = design.

**3 minutes (Senior):**
> I think of the difference as zoom levels on a map. Architecture is
> the satellite view: you see continents (services), countries
> (domains), and roads between them (communication patterns). Design
> is the street view: you see buildings (classes), rooms (methods),
> and the plumbing (data structures).
>
> The practical difference is reversibility. Architectural decisions
> shape the context for all future design decisions - if you chose
> microservices, every new feature is implemented as a microservice.
> Changing to a monolith later costs a significant rewrite. Design
> decisions are local and reversible - changing how a class is
> structured is a refactoring, not a migration.
>
> This matters for governance. Architectural decisions require cross-team
> visibility and stakeholder alignment. Design decisions can and should
> be delegated to the engineers writing the code. Over-centralizing
> design decisions is the architect-as-bottleneck failure mode.
>
> The non-obvious insight: the boundary between architecture and design
> is contextual. In a small team, "which ORM to use" might be a local
> design decision. In a large platform with 50 services all using the
> same ORM, it is architectural because changing it requires
> coordinating 50 teams.

*Adapting up:* Staff adds: "The most valuable skill at the boundary
is knowing which decisions to DEFER. A deferred decision deliberately
held open until you have enough information to make it well is not
laziness; it is preserving optionality."

*Adapting down:* Junior: "Architecture is the big-picture view - how
major components fit together. Design is the close-up view - how code
within a component is structured. Architecture decisions are hard to
change; design decisions are relatively easy."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the difference between
architecture and design - let me walk through what distinguishes
the two levels."

**(2) First principles:** "Every system has decisions at different
scales: system-wide (architecture) and component-level (design).
The key distinction: system-wide decisions are expensive to change
because they constrain all the component-level decisions made on
top of them."

**(3) Bridge:** "Like urban planning vs interior design. The city
planner decides where roads and utilities go - expensive to change,
constrains everything built on top. The interior designer decides
room layout - cheap to change, local to one building."

---

### 📘 Concept Explanation

**What it is:**
Architecture and design are both concerned with the structure of
software, but at different levels of abstraction. Architecture
operates at the system level (components, their boundaries, and
their interactions). Design operates at the component level
(classes, modules, data structures, algorithms within a component).

**The problem it solves:**
Without distinguishing the levels, teams either over-centralize
(architect approves all class structures) or under-architect (no
shared framework for system-wide decisions). Clarity about levels
enables the right decisions to be made at the right scope.

**How it works:**

```plaintext
LEVELS OF ABSTRACTION

SYSTEM LEVEL (Architecture):
  - Component identification: which services/modules exist
  - Component boundaries: responsibilities
  - Interaction patterns: sync vs async, who calls whom
  - Quality attribute trade-offs
  - Platform choices: cloud, runtime, database type
  SCOPE: cross-component, cross-team
  COST TO CHANGE: high (coordination, migration)

MODULE LEVEL (High-Level Design):
  - Module internal structure (subcomponent breakdown)
  - Module's public API (interface to other components)
  - Local architectural patterns (layered within module)
  SCOPE: within component, affects callers' interfaces
  COST TO CHANGE: medium (API versioning required)

CLASS LEVEL (Low-Level Design / Code Design):
  - Class responsibilities (SRP)
  - Method design (parameters, return values)
  - Algorithm selection
  - Design pattern selection (factory, observer, strategy)
  SCOPE: within module
  COST TO CHANGE: low (IDE refactoring)
```

> **Code walkthrough:** This Levels of Abstraction example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Architecture and design exist on a continuum, not in separate boxes.
A decision that is "design" in a small team becomes "architecture"
in a large platform. The criterion is not the nature of the decision
but its scope: how many teams are affected and how expensive is it
to change?

**When to use it:**
Architecture-level thinking: decisions affect multiple teams, the
system boundary is being designed, quality attribute trade-offs are
being made, or decisions will be very expensive to reverse.
Design-level thinking: decisions are local to one component or team.

**When NOT to use it:**
Do not apply architecture-level governance to design-level decisions.
Requiring cross-team review for class naming or method design kills
velocity without adding value.

**Alternatives:**
- Conway's Law as the practical guide: decisions affecting multiple teams are architectural
- Parnas's information hiding: what information should be hidden across which boundaries

**First-principles derivation:**
All software decisions have scope (how many components affected) and
reversibility (how expensive to change). Low scope + high
reversibility = design decisions (delegate to engineers). High scope
+ low reversibility = architecture decisions (require broad alignment).
This is the principled basis for distinguishing the two levels.

---

### 💻 Code Example

*(Omit: The architecture vs design distinction is a conceptual
framework, not a programmatic interface. Code examples are provided
for specific architecture patterns in their respective keyword entries.)*

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Architecture is the big-picture view: what major components exist,
> how they communicate, what quality properties are important. Design
> is the close-up view: how code within a component is structured -
> classes, methods, design patterns. The practical difference:
> architecture decisions are expensive to change (choosing microservices
> shapes years of development), design decisions are cheap (renaming
> a class is a few minutes of work).

*Push deeper:* Give an example at each level. Architecture: "shared
database or database-per-service?" Design: "use the Factory pattern
or a constructor for this class?" The scope and cost-to-change
clearly differ.

---

**Senior / Staff (5+ years):**
> Architecture and design are both about structure but at different
> granularities. Architecture defines the system boundary: which
> components exist, how they communicate, which quality attributes
> are prioritized. Design defines component internals: class structure,
> data models, algorithm choices within a component.
>
> The critical skill is knowing WHICH level a decision belongs to.
> A caching strategy within one service is design. When five services
> need the same caching layer, the choice affects interface boundaries
> and requires a shared library decision - now it is architectural.
> Scope determines the level.
>
> The governance implication: architectural decisions need cross-team
> visibility. Design decisions should be delegated to the team closest
> to the problem. Getting this wrong in either direction is costly:
> over-centralizing design kills velocity, under-architecting creates
> chaos at scale.

*Push deeper:* Staff angle: "The most valuable skill is identifying
which decisions can be DEFERRED. An architectural decision deferred
until requirements are clear is better than one made too early on
incomplete information. Architecture discipline includes knowing what
NOT to decide yet."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Architecture is just high-level design | Architecture is defined by scope and reversibility, not abstraction level alone |
| Only architects make architectural decisions | Every senior engineer makes architectural decisions daily; the difference is whether they are made explicitly or implicitly |
| Design patterns are architecture patterns | Design patterns (Factory, Observer) are code-level; architecture patterns (Microservices, Event-Driven, Layered) are system-level structural decisions |
| Architecture comes before design in strict sequence | Architecture and design are iterative; implementation discoveries often require revisiting architecture decisions |
| Good architecture means detailed upfront planning | Good architecture means making minimum necessary decisions upfront, deferring others, enabling future changes |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Architecture at wrong level (over-governance)**

*Symptom:* Every class structure and design pattern requires
architecture review. Engineers wait days for approval on local
implementation choices. Velocity drops.

*Root cause:* Architecture governance applied at design level.
All decisions treated as architectural regardless of scope.

*Diagnostic:*
```
- How many decisions per week require architecture review?
- What percentage affect more than one team?
  (If < 50%, governance scope is too broad)
- How long does a "simple" change take from idea to production?
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Define explicit boundaries: "Architecture review is required
for decisions affecting component interfaces, data models shared
across services, or platform choices. Design decisions within a
component are delegated to the team."

*Prevention:* RACI for architecture decisions. Local decisions are
team-owned by default.

**Failure 2: Design treated as architecture (under-governance)**

*Symptom:* Each team makes its own technology choices and
communication patterns. The result: 12 different approaches to
the same cross-cutting concern, incompatible interfaces.

*Root cause:* No architecture governance for decisions that affect
multiple teams. Design autonomy extended to system-level concerns.

*Diagnostic:*
```plaintext
- How many different messaging libraries are in use?
  (> 2 = likely under-governance)
- How many different API authentication mechanisms?
- How many teams must coordinate for a cross-domain feature?
  (> 3 = lacking architecture standards)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* Architecture Decision Records for cross-team standards.
Establish guardrails: "all inter-service communication must use the
standard API gateway with standard auth tokens."

*Prevention:* At system start, clearly identify "architectural
concerns." Communication patterns, data formats, and error handling
across service boundaries are always architectural.

**Failure 3: Irreversible design decisions as throwaway choices**

*Symptom:* What was intended as a temporary choice becomes
permanently embedded. The "temporary" database schema from the MVP
is still in production six years later.

*Root cause:* Decisions made at design level that had architectural
consequences (affected many components, expensive to change) without
recognizing their architectural nature.

*Diagnostic:*
```
Ask: "What decisions are we now paying technical debt for?"
Classify each by: how many components affected, and how
expensive to change?
High-count, high-cost = architectural decisions made
without architectural rigor.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Fix:* ADR retrospective. For each pain-point: write an ADR
documenting the original decision, why it was made, and the current
cost. Then plan the migration as a project.

*Prevention:* At end of feature spike or MVP phase, explicitly
review "which temporary decisions need to be hardened before they
become permanent constraints?"

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 15 minutes |
| Core themes | Level distinction, reversibility, governance, scope |
| Seniority signal | Junior: defines levels; Senior: identifies scope and cost |
| Common trap | Treating all "important" decisions as architectural |
| Staff differentiator | Deliberately deferring architecture decisions |

---

**Q1 [JUNIOR]: What is the difference between software architecture
and software design?**

*Why they ask:* Checks whether the candidate thinks at system level
or code level. The answer reveals their mental model of software
structure.

*Likely follow-up:* "Give an example decision at each level."

Architecture and design are both concerned with structure, but at
different levels and with different reversibility.

Architecture is the system-wide view: which major components exist,
how they communicate, what quality attributes are prioritized.
An architectural decision: "shared database or database per service?"
This affects multiple teams and is expensive to change - migrating
a shared database to per-service databases means schema changes,
data migration, and API changes across all services.

Design is the component-level view: class structure, data models,
algorithms, design patterns within a component. A design decision:
"should this class use the Strategy pattern or a long if-else chain?"
This affects one class in one component, is cheap to change, and
does not require cross-team coordination.

The test: how many teams are affected, and how expensive is it to
change? Architectural decisions affect many teams and are expensive.
Design decisions affect one team and are cheap.

*What separates good from great:* Most candidates describe architecture
as "big picture" and design as "detailed." Great candidates give the
scope and reversibility criteria with concrete examples showing the
cost difference.

---

**Q2 [MID]: At what point does a design decision become an
architectural decision?**

criterion they actually use in practice.

*Likely follow-up:* "Give me an example you got wrong in either
direction."

A design decision becomes architectural when its scope expands
beyond one component or team. Two signals:

First: when it affects the interface boundary between components.
A class naming decision within a component is design. A field naming
in a shared API response is architectural - changing it requires
coordinating all callers.

Second: when the cost to reverse becomes high. A database schema
decision starts as design (choose a column name). After data is in
production and ten services query that column, the reversal cost
is architectural.

An example where I got this wrong: we treated the choice of event
format in a message queue as a design decision local to the producing
service. Six months later, 12 consuming services had hardcoded the
field names. Changing the format required coordinating all 12 services
- it had become architectural without us recognizing it. If we had
recognized the cross-service scope at the start, we would have
versioned the event schema from day one.

*What separates good from great:* Most candidates describe the
"scope" criterion. Great candidates give a real example where they
misclassified a decision and describe the consequence and fix.

---

**Q3 [SENIOR]: How do you communicate the architecture-design
boundary to your team?**

*Why they ask:* Senior engineers mentor teams. Tests whether the
candidate can operationalize the distinction.

*Likely follow-up:* "How do you handle it when a developer makes
what you consider an architectural decision without review?"

Two mechanisms to make the boundary concrete.

First, a published "what requires architecture review" document with
explicit examples: "inter-service API changes: yes. Internal class
structure: no. New service creation: yes. Refactoring within a
service: no." This removes ambiguity.

Second, a lightweight ADR template that any engineer can use. I
want engineers to capture the architectural decisions they ARE making
- not to block them, but to record context. A one-page ADR (context,
decision, consequences) is enough. When engineers write their own
ADRs, they naturally identify when a decision has system-wide scope.

When a developer makes an architectural decision without review:
I treat it as a learning opportunity, not a policy violation. "This
turned out to be architectural because of X - let's write an ADR
for it now so others know the reasoning." Rarely do I reverse the
decision unless the scope creates genuine cross-team risk.

*What separates good from great:* Most candidates describe explaining
the difference in a meeting. Great candidates describe structural
mechanisms - the written list of what requires review, the
lightweight ADR as a natural forcing function, and the restorative
(not punitive) response when boundaries are accidentally crossed.

---

**Q4 [STAFF]: How do you decide which architecture decisions to
DEFER rather than make upfront?**

*Why they ask:* Staff signal: deferring architectural decisions
is a skill, not a failure.

*Likely follow-up:* "How do you keep deferred decisions from
becoming implicit decisions?"

Architecture decisions made with incomplete information often need
to be reversed at high cost. Strategic goal: make the minimum set
of binding decisions needed to move forward, explicitly defer
everything else.

A decision can be deferred when: an abstraction can hide it (inject
a `NotificationService` interface - defer the choice of provider
until requirements are clearer), the system is small enough that
changing it later is acceptable, or the decision is not on the
critical path for the current development phase.

A decision must NOT be deferred when: it affects the interface
boundary between teams (teams need a stable contract to work in
parallel), it affects deployment infrastructure (CI/CD pipelines
need a clear target), or making it wrong and reversing it would
require a full system migration.

The mechanism for keeping deferred decisions from becoming implicit:
maintain an "open architecture decisions" list alongside the ADR
log. Each open decision has: the decision to make, what information
would close it, and a review date. When the information arrives or
the date passes, the decision is made explicitly.

*What separates good from great:* Most candidates treat all
architectural decisions as things to decide immediately. Great
candidates describe the explicit deferral mechanism (interface
abstraction, open decisions list, trigger conditions). Deferral as
a discipline applied to architecture is the staff differentiator.

---

**Q5 [SENIOR]: How does the architecture-design boundary differ
at a startup vs a large company?**

*Why they ask:* Tests contextual judgment. The boundary shifts with
team size, product maturity, and organizational structure.

*Likely follow-up:* "How does this affect how you document decisions?"

At a startup with five engineers, almost nothing is architectural.
With one team, every decision is local - the "scope" criterion
rarely triggers architectural classification. Governance overhead
is waste.

The boundary shifts as teams grow. At 20 engineers: inter-team
communication patterns, shared platform choices, and data ownership
decisions become architectural because they affect multiple teams.
At 100 engineers: API versioning policies, error handling standards,
observability requirements, and security baselines are all
architectural because each decision affects 20+ teams.

Documentation follows the same principle. At a startup: a
Confluence page with "here is how the system works" is enough. At
a large company: ADRs, API specifications, runbook templates, and
service catalogs are necessary because no individual can hold the
system's context.

The mistake at both ends: startups creating elaborate architecture
governance for a team of five (unnecessary overhead), and large
companies treating cross-team decisions as individual choices
(architectural debt at scale).

*What separates good from great:* Most candidates describe the
startup-enterprise spectrum. Great candidates articulate the
MECHANISM that shifts the boundary (team size, number of teams
affected) and give specific examples of which decisions crossed
from design to architecture as the organization grew.

---

**Q6 [STAFF]: What is the relationship between architecture
decisions and technical debt?**

*Why they ask:* Tests understanding that architectural decisions
create the environment in which technical debt accumulates.

*Likely follow-up:* "How do you prioritize architectural refactoring
vs new features?"

Architecture decisions create the structural context in which
technical debt either accumulates locally (contained) or globally
(uncontrolled). A well-architected system with clear component
boundaries allows debt to accumulate within a component without
affecting others. A poorly-architected system with shared databases
and implicit coupling means debt in one component propagates
everywhere.

The most insidious category of technical debt is
architectural debt: decisions correct at smaller scale
that become hard constraints as the system grows.
A shared database for a team of five is pragmatic.
For 50 engineers, it becomes a coordination bottleneck
and deployment constraint. Fixing it requires
architectural change, not just refactoring.

For prioritization: quantify the cost of the architectural debt.
"Our shared database causes three migrations per sprint to be
coordinated across four teams - roughly one sprint per quarter in
coordination overhead." When the cost is explicit, investment in
architectural refactoring can be compared against new feature work
in business terms.

*What separates good from great:* Most candidates describe technical
debt as "messy code." Great candidates distinguish architectural debt
(structural constraints) from code debt (quality issues within
components). The quantification approach (cost per sprint) enabling
rational prioritization is the senior differentiator.

---

**Q7 [STAFF]: How do you build an architecture culture in a team
that has never had explicit architecture practices?**

*Why they ask:* Organizational change is as important as technical
decisions. Building culture is a staff-level skill.

*Likely follow-up:* "What is the first thing you do?"

First: conduct an architecture retrospective rather than proposing
a new framework. Gather the team and ask: "What decisions do you
most regret not making earlier? What would you design differently
if starting over?" This identifies real architectural pain points
rather than imposing an abstract framework.

From the retrospective: write ADRs for the top three pain points -
not for future decisions, but for the decisions that created the
current pain. ADRs for past decisions show the team the practice
is about learning, not bureaucracy.

Then: establish the lightest governance that addresses the pain.
If the retrospective reveals that cross-team API changes caused the
most pain, establish an API review process. Do not implement full
architecture governance - just address the demonstrated pain.

The culture builds gradually: engineers who write ADRs find them
useful for their own thinking. Teams who have architecture reviews
find them catching real problems. The practice becomes self-
reinforcing when it is genuinely useful rather than compliance
theater.

*What separates good from great:* Most candidates describe
"introducing SOLID principles" or "hiring an architect." Great
candidates describe starting from pain (retrospective), using past
decisions as teaching material (ADRs for existing decisions), and
implementing minimum governance that addresses real problems. The
self-reinforcing culture insight is the staff differentiator.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Precision: what makes a decision architectural vs design level |
| Hiring Manager | Governance: architecture review as velocity enabler, not blocker |
| Bar Raiser | Scope: when design becomes architecture as teams grow |
| Peer Engineer | Practical: how the team decides what needs architecture review |

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



