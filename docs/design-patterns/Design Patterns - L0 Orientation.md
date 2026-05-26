---
layout: default
title: "Design Patterns - L0 Orientation"
parent: "Design Patterns and SOLID"
grand_parent: "SK Interview"
nav_order: 1
permalink: /design-patterns/l0-orientation/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Why Design Patterns Exist](#why-design-patterns-exist) | foundational |
| 2 | [Gang of Four Pattern Catalog Overview](#gang-of-four-pattern-catalog-overview) | foundational |
| 3 | [OOP Design Principles Landscape](#oop-design-principles-landscape) | foundational |
| 4 | [Pattern Language and Pattern Thinking](#pattern-language-and-pattern-thinking) | foundational |

---

# Why Design Patterns Exist

**Interview Weight:** foundational - Asked at every level to
gauge whether you think in terms of reusable solutions or
reinvent from scratch each time.

---

### 🎯 Model Answer

**30 seconds:**

> Design patterns exist because software has recurring structural
> problems that experienced engineers have already solved. A pattern
> is a named, reusable solution to a common design problem in a
> given context. They exist not as rules but as a shared vocabulary:
> "use Strategy here" communicates more in three words than a
> paragraph of description. Without patterns, every team reinvents
> solutions, names them differently, and loses knowledge when
> people leave.

**3 minutes (Senior):**

> Why patterns exist - three forces:
>
> Force 1: Recurring problems.
>   Software systems share structural challenges:
>   "create objects without coupling to concrete classes"
>   "add behavior without modifying existing code"
>   "decouple producers from consumers"
>   These problems recur across every codebase.
>
> Force 2: Communication efficiency.
>   "We used Observer for event propagation" is 7 words.
>   Without the pattern name, you need a whiteboard session.
>   Patterns compress design knowledge into vocabulary.
>   New team members ramp faster when patterns are named.
>
> Force 3: Proven trade-offs.
>   Each pattern carries known consequences:
>   Singleton: global access but testing difficulty.
>   Observer: decoupling but potential memory leaks.
>   Factory: flexibility but indirection.
>   Knowing the pattern means knowing the trade-off.
>
> What patterns are NOT:
>   Not copy-paste templates (context matters).
>   Not mandatory (YAGNI applies).
>   Not proof of good design (pattern abuse exists).
>   Not language-specific (they transcend Java).
>
> Historical context:
>   Christopher Alexander (1977): "A Pattern Language" (architecture).
>   GoF (1994): "Design Patterns" - 23 patterns for OOP.
>   Martin Fowler (2002): "Patterns of Enterprise Application Architecture."
>   Each generation addressed the recurring problems of its era.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the fundamental
purpose of design patterns in software engineering."

**(2) First principles:** "Recurring problems need reusable
solutions. Patterns name those solutions so teams can
communicate and reason about trade-offs efficiently."

**(3) Bridge:** "Design patterns are to software what
standard plays are to basketball - named strategies
that the whole team understands without explanation."

---

### 📘 Concept Explanation

Design patterns solve the communication problem first and
the technical problem second. A team that shares pattern
vocabulary makes design decisions in minutes instead of hours.

**The three categories (GoF):**

Creational: how objects are created.
- Singleton, Factory Method, Abstract Factory, Builder, Prototype.
- Problem solved: decouple object creation from usage.

Structural: how objects are composed.
- Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy.
- Problem solved: build flexible structures from simple parts.

Behavioral: how objects interact.
- Chain of Responsibility, Command, Iterator, Mediator, Memento,
  Observer, State, Strategy, Template Method, Visitor.
- Problem solved: define communication without tight coupling.

**Beyond GoF:**

Enterprise patterns (Fowler): Repository, Unit of Work, DTO,
Service Layer, Domain Model, Active Record.

Concurrency patterns: Producer-Consumer, Thread Pool,
Read-Write Lock, Double-Checked Locking.

Architectural patterns: MVC, MVVM, Hexagonal, CQRS,
Event Sourcing, Microservices.

**The pattern format:**

Every pattern documents: Name, Problem, Context, Forces,
Solution, Consequences, Known Uses, Related Patterns.
The consequences section is the most important: it tells
you what you sacrifice when you apply the pattern.

---

### 🎓 Answers by Seniority

**Junior:** "Design patterns are reusable solutions to
common software problems. They help teams communicate."

**Mid:** "Patterns provide a shared vocabulary and encode
trade-offs. I use Factory for object creation flexibility,
Strategy for interchangeable algorithms, Observer for
event-driven decoupling."

**Senior:** "I choose patterns based on the forces present:
if I need to vary creation independently, Factory. If I
need to add behavior without subclassing, Decorator. The
pattern name communicates intent to the team instantly."

**Staff:** "Patterns are a communication tool, not a goal.
I see teams over-apply patterns (AbstractSingletonProxyFactory)
which adds complexity without solving a real problem. The
test: does removing this pattern make the code simpler?
If yes, remove it."

---

### ⚠️ Common Misconceptions

**"Every problem needs a design pattern."**
False. Patterns solve specific recurring problems. Simple
problems need simple solutions. Pattern abuse creates
unnecessary indirection and complexity.

**"Design patterns are Java-specific."**
False. Patterns are language-agnostic. Some patterns
(Iterator, Observer) are so common that languages build
them in natively (for-each loops, event systems).

**"Knowing patterns makes you a good designer."**
Partially true. Knowing WHEN NOT to use a pattern is
equally important. Over-engineering with patterns is
a common anti-pattern itself.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis |
|---|---|---|
| Pattern abuse | 15 classes for a simple CRUD | Count indirection layers. If removing pattern simplifies: remove it |
| Wrong pattern | Strategy applied where a simple if-else suffices | Check: does the variation actually change at runtime? |
| Pattern cargo-culting | Pattern names in code but incorrect implementation | Review: does the code actually solve the pattern's stated problem? |
| Missing pattern | Duplicated logic across 10 classes | If you see copy-paste: a pattern is trying to emerge |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Name patterns, state purpose |
| Mid | 5 min | Categorize, give examples, name trade-offs |
| Senior | 8 min | When NOT to use, pattern abuse, real stories |
| Staff | 12 min | Design philosophy, pattern evolution, team vocabulary |

---

**[JUNIOR] Q1 - What are design patterns and why
do they matter?**

*Why they ask:* Baseline awareness of design vocabulary.

Design patterns are reusable solutions to recurring software
design problems. They matter for three reasons:

First, communication. When I say "we need a Factory here,"
every engineer on the team understands the intent without
a lengthy explanation. This shared vocabulary accelerates
code reviews, design discussions, and onboarding.

Second, proven trade-offs. Each pattern carries known
consequences. Singleton gives global access but hurts
testability. Observer decouples publishers from subscribers
but can cause memory leaks if listeners are not removed.
Knowing the pattern means knowing what you sacrifice.

Third, design acceleration. Instead of solving the same
structural problem from scratch, patterns give you a
starting point. Factory Method: how to create objects
without coupling to concrete classes. Strategy: how to
vary an algorithm independently from its caller.

The key insight: patterns are not templates to copy.
They are named solutions that adapt to your specific
context. Applying a pattern without the matching problem
is worse than no pattern at all.

*What separates good from great:* Explaining when NOT
to use patterns (YAGNI, simplicity) shows maturity beyond
pattern memorization.

---

**[MID] Q2 - How do you decide which pattern to apply
in a given situation?**

*Why they ask:* Tests decision-making, not just knowledge.

I use a forces-based approach. First, I identify the
problem precisely: what is varying? What constraint am
I working against?

If object creation is the concern:
- Need one instance: Singleton (with DI container, not static).
- Need to vary which class is instantiated: Factory Method.
- Need complex object assembly: Builder.

If structure/composition is the concern:
- Need to add behavior dynamically: Decorator.
- Need to simplify a complex subsystem: Facade.
- Need to make incompatible interfaces work together: Adapter.

If behavior/interaction is the concern:
- Need interchangeable algorithms: Strategy.
- Need to notify multiple listeners: Observer.
- Need to define a skeleton with variable steps: Template Method.

The second filter: do I actually need this pattern now?
YAGNI check - if the variation doesn't exist yet and
isn't likely, a simple implementation is better. I can
always refactor to a pattern when the need emerges.

Third filter: team familiarity. If the team doesn't know
Visitor, using it creates a maintenance burden. Prefer
patterns the team already understands.

*What separates good from great:* The YAGNI filter -
showing you don't apply patterns preemptively.

---

**[SENIOR] Q3 - Give an example where you removed a
design pattern to improve the code.**

*Why they ask:* Tests mature judgment - pattern removal
is harder than pattern application.

We had a payment processing service with a full Strategy
pattern for payment method selection. Three classes:
PaymentStrategy interface, CreditCardStrategy,
DebitCardStrategy. Each strategy had identical logic
except for one field value (payment type enum).

The "pattern" added three files, an interface, two
implementations, a factory to select between them, and
a configuration mapping. Total: 5 classes for what was
essentially an if-else on payment type.

I refactored it to a single PaymentProcessor class with
an enum parameter. Removed 4 classes, simplified the
dependency graph, and the team could now read the payment
flow in one file instead of jumping across 5.

The lesson: Strategy pattern solves "algorithms that
vary independently and are selected at runtime." Our
payment types never varied at runtime - they were fixed
at compile time. The pattern was solving a problem we
didn't have.

Metric: PR review time for payment changes dropped from
20 minutes (navigating 5 files) to 3 minutes (one file).

*What separates good from great:* Having a concrete story
with measurable improvement (PR review time reduction).

---

**[STAFF] Q4 - How do you establish pattern vocabulary
in a team without over-engineering?**

*Why they ask:* Leadership and culture influence.

I use a three-part approach:

Part 1: Pattern recognition in code review.
Instead of mandating patterns upfront, I identify them
during review. "This looks like it wants to be a Strategy -
the algorithm varies by customer tier." This teaches
patterns in context, not abstractly.

Part 2: ADR documentation.
When we introduce a pattern, we write a short Architecture
Decision Record: why this pattern, what it replaces, what
we sacrifice. Future engineers can evaluate whether the
pattern is still justified.

Part 3: Anti-pattern examples.
I maintain a short "patterns we removed" document. Real
examples from our codebase where a pattern was applied
prematurely and later simplified. This gives permission
to not use patterns.

The balance: I prefer "grow patterns from need" over
"design with patterns upfront." Start simple. When
duplication or coupling becomes painful, refactor toward
the pattern. The code tells you when it needs a pattern
through code smells (duplication, long conditionals,
tight coupling).

Measurement: I track "classes per feature." If a simple
feature touches 15 classes, we're over-patterned. If it
touches 1 god-class, we're under-patterned. Sweet spot:
3-5 classes for a typical feature.

*What separates good from great:* "Grow patterns from need"
philosophy with a measurable heuristic (classes per feature).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Name patterns, categorize, give Java examples. |
| Hiring Manager | Communication, team vocabulary, pragmatism. |
| Bar Raiser | When NOT to use patterns, removal stories. |
| Peer Engineer | "We removed 4 Strategy classes. Payment code review: 20min to 3min." |

---

---

# Gang of Four Pattern Catalog Overview

**Interview Weight:** foundational - Context question to
assess whether candidate knows the full landscape or just
3-4 popular patterns.

---

### 🎯 Model Answer

**30 seconds:**

> The Gang of Four (Gamma, Helm, Johnson, Vlissides) published
> 23 design patterns in 1994, organized into three categories:
> Creational (5 patterns - object creation), Structural (7
> patterns - composition), Behavioral (11 patterns - interaction).
> In modern Java backend work, about 10-12 of these appear
> regularly. The others (Memento, Flyweight, Visitor) appear
> in specialized contexts. Knowing the full catalog means
> you recognize patterns in frameworks (Spring uses Factory,
> Proxy, Template Method, Observer extensively).

**3 minutes (Senior):**

> The 23 GoF patterns mapped to modern Java usage:
>
> CREATIONAL (5):
>   Singleton: Spring beans (default scope), connection pools.
>   Factory Method: Spring BeanFactory, JDBC DriverManager.
>   Abstract Factory: GUI toolkits, cross-platform builders.
>   Builder: Lombok @Builder, StringBuilder, Stream pipelines.
>   Prototype: clone(), Spring prototype scope.
>
> STRUCTURAL (7):
>   Adapter: Spring MVC HandlerAdapter, legacy integration.
>   Bridge: JDBC API (abstraction) vs drivers (impl).
>   Composite: UI trees, file systems, Spring Security filters.
>   Decorator: Java I/O streams, Spring interceptors.
>   Facade: Spring JdbcTemplate, service layers.
>   Flyweight: Integer cache (-128 to 127), string pool.
>   Proxy: Spring AOP, JPA lazy loading, java.lang.reflect.Proxy.
>
> BEHAVIORAL (11):
>   Chain of Responsibility: Servlet filters, Spring Security.
>   Command: Spring MVC handler, Runnable, undo systems.
>   Iterator: java.util.Iterator, enhanced for-loop.
>   Mediator: Spring ApplicationContext, message brokers.
>   Memento: serialization, undo/redo systems.
>   Observer: Spring Events, Java Beans PropertyChangeListener.
>   State: workflow engines, order status machines.
>   Strategy: Comparator, Spring Resource, validation.
>   Template Method: Spring JdbcTemplate, AbstractController.
>   Visitor: compiler AST processing, reporting.
>
> Frequency in Java backend interviews (top 10):
>   1. Singleton  2. Factory  3. Builder
>   4. Strategy   5. Observer 6. Decorator
>   7. Proxy      8. Template Method  9. Adapter
>   10. Chain of Responsibility

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the complete GoF
pattern catalog and its organization."

**(2) First principles:** "23 patterns in 3 categories:
5 Creational (making objects), 7 Structural (composing
objects), 11 Behavioral (objects communicating)."

**(3) Bridge:** "Think of it like a toolbox: creational
tools build things, structural tools connect things,
behavioral tools coordinate things."

---

### 📘 Concept Explanation

The GoF catalog is not a textbook to memorize - it is a
pattern recognition aid. When you see a problem, the
catalog helps you find the pattern that solves it.

**Pattern relationships (key connections):**

Factory + Singleton: factories are often singletons.
Decorator + Composite: both use recursive composition.
Strategy + Template Method: both vary behavior (Strategy
via delegation, Template Method via inheritance).
Observer + Mediator: Observer for one-to-many broadcast,
Mediator for many-to-many coordination.
Proxy + Decorator: both wrap an object (Proxy controls
access, Decorator adds behavior).

**Framework pattern density:**

Spring Framework uses at least 15 of the 23 patterns:
- BeanFactory (Factory Method)
- ApplicationContext (Mediator)
- AOP proxies (Proxy)
- JdbcTemplate (Template Method)
- ApplicationEvent (Observer)
- HandlerInterceptor (Chain of Responsibility)
- @Scope("prototype") (Prototype)
- bean scopes (Singleton)

Recognizing patterns in frameworks accelerates learning.

---

### 🎓 Answers by Seniority

**Junior:** "GoF has 23 patterns in three categories.
I use Builder for complex objects, Singleton for shared
resources, Strategy for interchangeable algorithms."

**Mid:** "I can identify patterns in Spring: BeanFactory
(Factory), AOP (Proxy), JdbcTemplate (Template Method).
I use this recognition to learn new frameworks faster."

**Senior:** "The GoF patterns are building blocks. Most
production code uses pattern combinations: Factory +
Strategy, Observer + Command, Proxy + Decorator. I focus
on which 10-12 appear in backend systems and ignore the
rest unless the problem demands them."

---

### ⚠️ Common Misconceptions

**"You need to memorize all 23 patterns."**
False. Know the top 10-12 deeply. Recognize the rest
when you see them. Memento, Visitor, and Flyweight
rarely appear in typical Java backend code.

**"GoF patterns are outdated (1994)."**
Partially true. The patterns are timeless but some
implementations changed. Java 8 lambdas replaced many
single-method Strategy/Command classes. Functional
composition replaced some Decorator chains.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Name categories, list 5-6 patterns |
| Mid | 5 min | Map patterns to Java/Spring examples |
| Senior | 8 min | Pattern relationships, frequency analysis |

---

**[JUNIOR] Q1 - Name the three GoF categories and give
two patterns from each.**

*Why they ask:* Baseline pattern vocabulary.

The three categories are Creational, Structural, and
Behavioral.

Creational patterns handle object creation. Singleton
ensures one instance exists (like Spring's default bean
scope). Builder constructs complex objects step by step
(like Lombok @Builder or StringBuilder).

Structural patterns handle object composition. Decorator
wraps objects to add behavior (like Java I/O streams -
BufferedReader wraps FileReader). Adapter makes incompatible
interfaces work together (like Spring's HandlerAdapter).

Behavioral patterns handle object interaction. Strategy
lets you swap algorithms at runtime (like passing a
Comparator to Collections.sort). Observer notifies
subscribers of state changes (like Spring's
ApplicationEventPublisher).

The key insight: these categories answer different
questions. "How do I create it?" (Creational). "How do
I compose it?" (Structural). "How does it communicate?"
(Behavioral).

*What separates good from great:* Giving concrete Java/
Spring examples instead of abstract definitions.

---

**[MID] Q2 - Which GoF patterns does Spring Framework
use internally?**

*Why they ask:* Tests whether you understand framework
internals through pattern recognition.

Spring uses at least 12 GoF patterns:

Singleton: default bean scope. One instance per container.
Factory Method: BeanFactory.getBean() creates beans without
caller knowing the concrete class.
Prototype: prototype-scoped beans. New instance per request.
Template Method: JdbcTemplate, RestTemplate, TransactionTemplate.
The template defines the skeleton; you supply the variable parts
(RowMapper, callbacks).
Proxy: AOP creates JDK dynamic proxies or CGLIB subclasses.
Every @Transactional, @Cacheable, @Async uses Proxy.
Observer: ApplicationEvent + ApplicationListener. Publish
events without coupling publisher to subscriber.
Chain of Responsibility: Spring Security filter chain.
Each filter decides to handle or pass to the next.
Adapter: HandlerAdapter adapts different handler types
(annotated controllers, simple controllers) to a uniform
interface that DispatcherServlet can call.
Facade: JdbcTemplate is a facade over raw JDBC (Connection,
Statement, ResultSet, exception handling).
Decorator: HttpServletRequestWrapper, ResponseBodyAdvice.
Strategy: multiple ViewResolver implementations, multiple
HandlerMapping implementations.

This pattern recognition helps when debugging: if
@Transactional doesn't work, knowing it's Proxy-based
tells you self-invocation bypasses the proxy.

*What separates good from great:* Connecting pattern
knowledge to debugging (e.g., Proxy explains @Transactional
self-invocation bug).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Name patterns, categorize, framework mapping. |
| Hiring Manager | Breadth of knowledge, learning speed. |
| Bar Raiser | Pattern relationships and combinations. |
| Peer Engineer | "Knowing Spring uses Proxy for AOP helped me debug a @Transactional issue in 5 minutes instead of 2 hours." |

---

---

# OOP Design Principles Landscape

**Interview Weight:** foundational - The principles behind
patterns. Asked to assess design thinking maturity.

---

### 🎯 Model Answer

**30 seconds:**

> OOP design principles are the rules that patterns encode.
> SOLID (5 principles), plus DRY, KISS, YAGNI, Composition
> over Inheritance, Tell Don't Ask, Law of Demeter, and
> Separation of Concerns. SOLID gets the most interview
> attention: Single Responsibility, Open-Closed, Liskov
> Substitution, Interface Segregation, Dependency Inversion.
> These principles guide when and how to apply patterns.
> Violating them creates rigid, fragile code. Over-applying
> them creates over-engineered abstractions.

**3 minutes (Senior):**

> The principle landscape organized by concern:
>
> COHESION principles (what belongs together):
>   SRP: one class, one reason to change.
>   Separation of Concerns: distinct responsibilities in
>     distinct modules.
>   DRY: single source of truth for every piece of knowledge.
>
> COUPLING principles (what should be independent):
>   DIP: depend on abstractions, not concretions.
>   Law of Demeter: talk to friends, not strangers.
>   ISP: clients shouldn't depend on methods they don't use.
>   Tell Don't Ask: command objects, don't query and decide.
>
> EXTENSION principles (how to change safely):
>   OCP: open for extension, closed for modification.
>   LSP: subtypes must be substitutable for base types.
>   Composition over Inheritance: prefer has-a over is-a.
>
> SIMPLICITY principles (when to stop):
>   KISS: simplest solution that works.
>   YAGNI: don't build it until you need it.
>
> The tension: SOLID pushes toward abstraction and
> flexibility. KISS/YAGNI push toward simplicity. Senior
> judgment = knowing where on this spectrum to land for
> a given context. Startup MVP: lean toward KISS. Platform
> serving 50 teams: lean toward SOLID.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the landscape of
object-oriented design principles."

**(2) First principles:** "Principles guide how to structure
code: high cohesion, low coupling, safe extension, appropriate
simplicity."

**(3) Bridge:** "Principles are the grammar rules; patterns
are sentences written with those rules."

---

### 📘 Concept Explanation

Principles exist in tension. Good design navigates this tension
rather than maximizing any single principle.

**Principle conflicts:**

DRY vs Readability:
  Extracting a 2-line duplicate into a helper method
  adds indirection for minimal DRY gain. Sometimes
  duplication is cheaper than the wrong abstraction.

OCP vs KISS:
  Making everything extensible via interfaces adds
  complexity. If only one implementation exists and
  is unlikely to change, a concrete class is simpler.

SRP vs Cohesion:
  Over-splitting responsibilities creates too many tiny
  classes. A UserService with createUser, findUser, deleteUser
  is fine - splitting into three classes violates cohesion.

**The pragmatic approach:**

Start simple (KISS/YAGNI). When pain emerges (duplication,
tight coupling, difficult testing), apply the relevant
principle (DRY, DIP, ISP). The code tells you when it
needs more structure through symptoms: long methods,
deep nesting, test difficulty, merge conflicts.

---

### 🎓 Answers by Seniority

**Junior:** "SOLID principles: Single Responsibility,
Open-Closed, Liskov, Interface Segregation, Dependency
Inversion. They help write maintainable code."

**Mid:** "I balance SOLID with YAGNI. I don't create
interfaces for classes with one implementation. When a
second implementation appears, I extract the interface."

**Senior:** "Principles are navigation aids, not laws.
I've seen codebases destroyed by over-application of
SRP (500 tiny classes) and by under-application (god
classes). Context determines the right balance."

---

### ⚠️ Common Misconceptions

**"Every class needs an interface (DIP)."**
False. Interfaces exist for polymorphism and testability.
If a class has one implementation and is easily mockable,
skip the interface. Extract when a second implementation
or a testing seam is needed.

**"DRY means never repeat any code."**
False. DRY means "every piece of KNOWLEDGE has a single
representation." Two code blocks that look the same but
represent different business rules should remain separate.
Premature DRY creates the wrong abstraction.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Name SOLID, give examples |
| Mid | 5 min | Principle trade-offs, when to relax |
| Senior | 8 min | Principle conflicts, team context |

---

**[SENIOR] Q1 - When have you deliberately violated a
SOLID principle and why?**

*Why they ask:* Tests judgment and pragmatism over dogma.

I deliberately violated DIP (Dependency Inversion) in a
startup's early-stage order service. Instead of defining
an OrderRepository interface, I used the concrete Spring
Data JPA repository directly in my service class.

Why: we had one database (PostgreSQL), one implementation,
and speed-to-market mattered more than future flexibility.
Adding an interface would have added a file, import
complexity, and zero actual benefit since we were not
going to swap databases.

When we later needed to support both PostgreSQL and DynamoDB
(multi-region), I extracted the interface then. The
refactoring took 30 minutes. The 6 months of not maintaining
an unnecessary interface saved hours of ceremony.

The principle: "You Aren't Gonna Need It" until you do.
When you do need it, refactor. The cost of refactoring
later was far less than the cost of abstraction overhead
for 6 months.

The guard rail: I only violate DIP when testing is not
impacted. If I need to mock the dependency in unit tests,
I need the interface. If integration tests suffice (which
they did for this service), concrete is fine.

*What separates good from great:* Naming the specific
guard rail (testing impact) that decides when violation
is acceptable.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Name principles, give Java examples. |
| Hiring Manager | Pragmatism, speed vs quality balance. |
| Bar Raiser | Principle conflicts, deliberate violations. |
| Peer Engineer | "No interface for 6 months. Extracted in 30 min when needed. Zero regret." |

---

---

# Pattern Language and Pattern Thinking

**Interview Weight:** foundational - Tests whether
candidate thinks in patterns or just memorizes solutions.

---

### 🎯 Model Answer

**30 seconds:**

> Pattern thinking is recognizing recurring problems and
> mapping them to known solutions. It is the difference
> between "I need to write code that creates objects" and
> "I recognize the Factory pattern here." Pattern language
> is the shared vocabulary that emerges: when a team says
> "Factory," "Strategy," or "Observer," everyone visualizes
> the same structure. This vocabulary accelerates design
> discussions, code reviews, and onboarding. The skill is
> pattern recognition, not pattern memorization.

**3 minutes (Senior):**

> Pattern thinking operates at three levels:
>
> Level 1: Recognition.
>   See a switch statement selecting behavior → recognize Strategy.
>   See nested object creation → recognize Builder.
>   See event listeners → recognize Observer.
>   This is pattern detection in existing code.
>
> Level 2: Selection.
>   Given a problem: "I need to add logging without modifying
>   the service." Map the forces (adding behavior, no modification)
>   to a pattern (Decorator or Proxy). This is pattern application.
>
> Level 3: Composition.
>   Combine patterns to solve complex problems:
>   Factory + Strategy: create the right strategy dynamically.
>   Observer + Command: queue commands triggered by events.
>   Proxy + Decorator: control access AND add behavior.
>   This is pattern architecture.
>
> Pattern language in practice:
>   Code review comment: "This feels like Chain of Responsibility."
>   Design meeting: "Let's use Builder for the query construction."
>   Architecture doc: "Event-driven via Observer pattern with
>   Command pattern for replay capability."
>
> The anti-skill: pattern forcing.
>   "I learned Visitor, so I'll use it here."
>   Forcing patterns creates complexity without solving problems.
>   The test: can you explain WHY this pattern and not another?
>   If you can't articulate the forces, you're forcing.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about pattern thinking
as a skill and pattern language as communication."

**(2) First principles:** "Pattern thinking = recognizing
problems that match known solutions. Pattern language =
shared vocabulary for those solutions."

**(3) Bridge:** "Pattern thinking is like a doctor recognizing
symptoms as a known disease - the diagnosis accelerates
treatment because it maps to a known protocol."

---

### 📘 Concept Explanation

Pattern thinking transforms you from a coder into a designer.
Without it, every problem is novel. With it, 80% of problems
map to known solutions with known trade-offs.

**How to develop pattern thinking:**

Step 1: Learn patterns by problem, not by solution.
  Don't memorize "Singleton has a private constructor."
  Memorize "When I need exactly one instance with global
  access, I consider Singleton (and its downsides)."

Step 2: Read framework source code through pattern lens.
  Spring: identify Factory, Proxy, Template Method, Observer.
  Java I/O: identify Decorator chain.
  java.util: identify Iterator, Strategy (Comparator).

Step 3: Practice recognition in code reviews.
  Every PR: "Is there a pattern trying to emerge here?"
  Long switch → Strategy. Nested creation → Builder.
  Notification logic → Observer.

Step 4: Practice combination in system design.
  Real systems use 3-5 patterns working together.
  E-commerce order: Builder (construction) + State (lifecycle)
  + Observer (notifications) + Strategy (pricing).

---

### 🎓 Answers by Seniority

**Junior:** "Pattern thinking means recognizing which
pattern fits a problem. Like seeing a switch statement
and thinking 'that could be a Strategy.'"

**Senior:** "Pattern thinking at Staff level means
recognizing pattern COMBINATIONS that solve system-level
problems. An event-driven microservice uses Observer +
Command + Factory + Strategy composed together."

---

### ⚠️ Common Misconceptions

**"Pattern thinking means using more patterns."**
False. Pattern thinking includes recognizing when a
pattern is NOT needed. The best pattern thinkers write
simple code that uses patterns only at natural seams.

**"Pattern language is academic jargon."**
False. It is engineering communication efficiency. A
team with shared pattern language makes decisions 5x
faster in design meetings.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Recognize pattern in code snippet |
| Senior | 7 min | Pattern composition, when not to pattern |

---

**[MID] Q1 - Look at this code. What pattern is it
implementing? (code shows Strategy-like structure)**

*Why they ask:* Tests pattern recognition in real code.

Looking at this code, I see three elements:
1. An interface defining an algorithm contract.
2. Multiple implementations providing different behaviors.
3. A context class that holds a reference to the interface
   and delegates execution to it.

This is the Strategy pattern. The interface is the Strategy,
the implementations are ConcreteStrategies, and the caller
is the Context.

The giveaway: the behavior varies independently from the
caller. The caller doesn't know which implementation it
holds - it just calls the interface method.

In Java backend: Comparator is Strategy (sort algorithm
varies). Validator implementations are Strategy (validation
logic varies). Spring's ResourceLoader is Strategy (resource
loading varies by protocol).

Why it matters: recognizing this pattern tells me:
- New behaviors can be added without modifying existing code.
- The algorithm can be swapped at runtime.
- Testing: I can inject a mock strategy for unit tests.

*What separates good from great:* Going beyond naming
to explaining the consequences (extensibility, testability,
runtime swappability).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Pattern recognition in code. |
| Hiring Manager | Communication clarity using pattern vocabulary. |
| Bar Raiser | Pattern composition and when to simplify. |
| Peer Engineer | "Pattern language in our team cut design meeting time in half." |
