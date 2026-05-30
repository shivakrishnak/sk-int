---
layout: default
title: "Design Patterns - L0 Orientation"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 1
permalink: /design-patterns/l0-orientation/
---

# What Are Design Patterns

---
id: DP-001
title: What Are Design Patterns
category: Design Patterns
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #design-patterns, #gof, #oop, #software-design
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Design patterns are reusable solutions to recurring software design
> problems. They were popularized by the Gang of Four book (1994) which
> catalogued 23 patterns into three categories: Creational (how to create
> objects), Structural (how to compose objects), and Behavioral (how
> objects communicate). They are not code to copy - they are blueprints
> describing the structure of a solution.

**3 minutes (Senior):**
> I think of design patterns as a shared vocabulary for design decisions.
> When I say "use an Observer here," an experienced engineer immediately
> understands: there is a Subject that maintains a list of Observers,
> notifies them on state change, and neither party is tightly coupled to
> the other. Without that vocabulary, I would need five minutes on a
> whiteboard to convey the same idea.
>
> The deeper value is the problem-solution pairing. Each pattern encodes
> a decision: the context in which a problem appears, the forces at play,
> and why this particular structure resolves those forces better than
> alternatives. When I see a class with ten boolean flags controlling
> behavior, I recognize "this is a State pattern problem waiting to be
> solved."
>
> The non-obvious insight: patterns describe structure, not implementation.
> Observer in Java looks different from Observer in JavaScript (events,
> reactive streams), but the structural relationship is identical. This
> is why patterns transfer across languages.

*Adapting up:* At staff level, add: "The real cost of patterns is
cognitive overhead. Every pattern adds indirection - another class,
another interface. The decision: does the flexibility justify the
complexity?"

*Adapting down:* Junior version - "Design patterns are named solutions
to common problems. Recognize the problem and apply the known solution."

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about design patterns - let me
think through what problem they exist to solve."

**(2) First principles:** "In software, the same structural problems
appear in many codebases: how to create objects flexibly, how to add
behavior without changing existing code, how to notify multiple
components of a change. Rather than solving each ad hoc, patterns
capture the canonical solution once."

**(3) Bridge:** "This is similar to algorithms: quicksort is a pattern
for sorting. The difference is patterns describe class structures and
object collaborations rather than computational steps."

---

### 📘 Concept Explanation

**What it is:**
A design pattern is a named, documented solution to a recurring design
problem. It describes a class structure, the relationships between
classes, and the responsibilities of each class in a way that can be
adapted to many contexts.

**The problem it solves:**
Before patterns were catalogued, every team solved the same structural
problems independently - different shapes, different names, inconsistent
trade-offs. The pattern movement gave the industry a shared vocabulary
and a library of proven solutions.

**How it works:**
A pattern consists of four elements:
1. **Name** - the vocabulary handle (Observer, Strategy, Factory)
2. **Problem** - the context and forces that create the need
3. **Solution** - the class structure and their relationships
4. **Consequences** - what you gain and what you give up

When you apply a pattern: identify that your problem matches the
pattern's problem description, then structure your classes to match
the solution, adapting specific names and types to your domain.

**The key insight:**
Patterns are about relationships and responsibilities, not code. Two
completely different codebases can both use Observer with zero shared
code. The pattern is the structural relationship: Subject knows Observers
through an interface; Observers do not know each other; Subject does not
know what Observers do with the notification.

**When to use it:**
- Designing an object structure and recognizing a recurring force
- Communicating a design decision clearly to teammates
- Leveraging known trade-offs rather than discovering them at runtime
- Writing framework code that others will extend

**When NOT to use it:**
- Simple problems: a function or plain class is enough
- When you do not have the recurring forces the pattern addresses
- When indirection obscures intent more than it clarifies it
- YAGNI: do not add pattern structure for flexibility you will never use

**Alternatives:**
- **Ad hoc structure** - direct implementation; choose for genuinely
  one-off problems
- **Functional composition** - functions as first-class objects replace
  many behavioral patterns (Strategy becomes a function parameter)
- **Framework abstractions** - Spring's event system replaces Observer;
  framework handles the structural complexity

**First-principles derivation:**
Given: OO code has recurring structural problems. Options: (A) solve each
ad hoc - inconsistent. (B) invent a personal library - not shared
vocabulary. (C) catalogue canonical solutions once, name them, document
trade-offs. Option C produces the GoF book.

---

### 💻 Code Example

```java
// BAD: ad hoc notification - tight coupling
public class OrderService {
    private EmailService emailSvc;
    private SmsService smsSvc;
    private AnalyticsService analyticsSvc;

    // Adding a 4th notification: must edit OrderService
    public void placeOrder(Order order) {
        // business logic...
        emailSvc.sendConfirmation(order);
        smsSvc.sendConfirmation(order);
        analyticsSvc.recordPurchase(order);
    }
}
```

> **Code walkthrough:** Every new notification channel requires
> modifying `OrderService`. The class knows all concrete listener
> types. Adding a 4th listener violates the Open/Closed Principle
> and creates tight coupling.

```java
// GOOD: Observer pattern - open for extension
public interface OrderListener {
    void onOrderPlaced(Order order);
}

public class OrderService {
    private final List<OrderListener> listeners = new ArrayList<>();

    public void addListener(OrderListener listener) {
        listeners.add(listener);
    }

    public void placeOrder(Order order) {
        // business logic...
        listeners.forEach(l -> l.onOrderPlaced(order));
    }
}

// Each listener is independent, added at runtime
public class EmailNotifier implements OrderListener {
    public void onOrderPlaced(Order order) { /* send email */ }
}
public class AnalyticsNotifier implements OrderListener {
    public void onOrderPlaced(Order order) { /* record event */ }
}
```

> **Code walkthrough:** `OrderService` depends on the `OrderListener`
> interface, not on concrete classes. Adding a new notification type
> requires zero changes to `OrderService` - create a new implementation
> and register it. This is Observer: Subject (`OrderService`) maintains
> a list of Observers (`OrderListener`), notifies them through an
> interface. Neither side knows the concrete type of the other.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Design patterns are named solutions to common object-oriented design
> problems. The GoF book catalogued 23 of them: Creational (how to
> create objects), Structural (how to compose objects), and Behavioral
> (how objects communicate). They give me a vocabulary to communicate
> design decisions precisely, and a proven structure to apply when I
> recognize the matching problem.

*Push deeper:* "I look for patterns as refactoring targets more than
upfront designs. When I see a class with many boolean flags or a
growing list of notification types hardcoded in a method, I recognize
the pattern that applies and refactor toward it."

---

**Senior / Staff (5+ years):**
> Design patterns are a vocabulary for design decisions and a library
> of proven solutions to recurring structural problems. The value is
> two-fold: precise communication between engineers, and encoded
> trade-offs so you do not rediscover them.

The production reality: most patterns arise as refactoring targets, not
upfront designs. You write ad hoc code, feel the pain of inflexibility,
then recognize "this is an Observer problem" and refactor. Designing
with patterns upfront requires experience to know which problems you
will actually hit.

*Push deeper:* "At staff level: which patterns does our framework
already provide? Spring's ApplicationEvent system gives you Observer.
Spring AOP gives you Proxy + Decorator. Using the framework's built-in
pattern implementations is almost always better than hand-rolling them."

---

### ⚠️ Common Misconceptions

**Misconception 1: Design patterns are specific code implementations to copy.**

Design patterns are problem-solution templates, not copy-paste code. The same Observer pattern looks very different in Java (interfaces + concrete classes), JavaScript (EventEmitter), and Python (property decorators + callbacks). What you copy is the STRUCTURE - the relationships between roles (Subject, Observer, update() contract) - not the specific class names or method signatures. A developer who can only recall the Java textbook version of Observer but not recognize the same pattern in Python event handling hasn't internalized the pattern, only the syntax.

**Misconception 2: Knowing design pattern names makes you a better engineer.**

Pattern names are a shared vocabulary for communicating design intent - they have no intrinsic value until applied to real problems. An engineer who applies the Strategy pattern to eliminate a chain of if/else statements without knowing its GoF name has demonstrated more design skill than one who uses the name correctly in conversation but writes the code with a 10-case switch statement. The goal is the problem-solving ability, not the terminology.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Forcing a pattern where none is needed.**

Symptom: simple method or class wrapped in Strategy/Factory/Decorator
with no additional implementations planned and none foreseeable. The
indirection adds three files and a new abstraction layer without any
concrete benefit. Diagnosis: ask "what is the second implementation
of this strategy?" If there is no answer: the pattern is premature.
Fix: delete the pattern, use the direct implementation.

**Failure Mode 2: Implementing the wrong pattern for the problem.**

Symptom: team uses Decorator where Composite fits (or Observer where
Mediator fits). Code works initially but extension causes cascading
rewrites. Root cause: pattern chosen by surface similarity ("it sort
of looks like X") rather than by problem structure. Diagnosis: write
out the problem forces explicitly (what varies, what is the
relationship, what is the extension point) and compare to the pattern
catalog. Fix: refactor to the correct structural pattern while
behavior is still limited.

**Failure Mode 3: Pattern applied to solo code read by no one else.**

Symptom: developer invests time in clean pattern architecture for a
script or one-off tool that is never read again. The pattern exists
for communication and maintenance - solo throwaway code does not
benefit from GoF structure. Reserve pattern investment for code that
will be read, extended, and maintained by a team.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is a design pattern?"
- "Can you name the three categories of GoF patterns?"
- "What is the difference between a pattern and a library?"

🗣️ "A design pattern is a named, reusable solution to a recurring
design problem. It describes class structure and relationships, not
specific code. GoF catalogued 23 patterns across three categories:
Creational (object instantiation), Structural (composition), and
Behavioral (communication). Unlike a library, a pattern is a template -
you adapt it to your types and context."

#### Mechanism
- "How do you apply a design pattern?"
- "Walk me through recognizing when a pattern is needed."

🗣️ "Applying a pattern is three steps. First, I recognize that my
problem's forces match a known pattern's problem description - for
example, I need to notify multiple components when an event occurs
without tight coupling. That matches Observer. Second, I structure
my classes to match the solution: Subject interface, Observer interface,
concrete implementations. Third, I adapt the names to my domain -
`OrderService` as Subject, `OrderListener` as Observer."

#### Comparison
- "What is the difference between a pattern and an anti-pattern?"
- "When are patterns overused?"

🗣️ "An anti-pattern is a commonly used solution that creates more
problems than it solves. Singleton looks like clean 'one instance'
design but is global mutable state that makes testing hard. Patterns
are overused when the forces they address do not exist in your problem.
Adding Factory Method when you have one concrete type that never changes
adds indirection with no benefit. Test: if removing the pattern simplifies
the code without losing flexibility you actually use - it should not
have been there."

#### Scenario
- "Design a payment processing system. Which patterns would you use?"
- "Your order service needs multiple notification channels. How do you
  design it?"

🗣️ "For notifications I would reach for Observer: the order service
fires an event, notification handlers register as listeners. I would
not start by asking 'which patterns?' - I identify the variable points
first: what changes across executions, what changes over time, what
needs to be pluggable. Those variable points drive pattern selection.
Payment providers vary at runtime - Strategy. The right processor
depends on configuration - Factory. Downstream notifications must not
couple to the payment domain - Observer."

#### Debugging
- "An Observer notification is not arriving. How do you debug it?"
- "A Decorator is not wrapping the object you expect. How do you
  investigate?"

🗣️ "For missing Observer notifications: three checks. First, is the
listener registered? Add logging in the registration code. Second, is
the Subject actually firing? Add a log in the notify loop. Third, is
an exception in an earlier listener silently swallowing the notification?
In the production version I wrap each listener call in try/catch so one
bad listener cannot block the rest. Most 'notification not arriving' bugs
are registration ordering issues or swallowed exceptions."

#### Deep Dive
- "Why were patterns invented? What industry problem did they solve?"
- "What are the limitations of the GoF patterns?"

🗣️ "GoF patterns solved a knowledge transfer problem. Expert designers
were solving the same structural problems repeatedly in different projects.
Capturing these solutions as named structures - not code, but descriptions
of class relationships - made them transferable. The limitation: they were
designed for OO languages of the 1990s. Many become unnecessary in
functional languages: Strategy is a function parameter, Observer is a
stream subscription. Modern frameworks also provide many patterns built-in,
reducing the need to hand-roll them. The patterns still have value as
vocabulary even when the implementation is framework-provided."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Name all 3 categories; show mechanism with one coded example. |
| Hiring Manager | "Shared vocabulary for design decisions - speeds up code review and design discussion." |
| Bar Raiser | "Patterns add indirection. The question is whether the flexibility justifies the complexity." |
| Peer Engineer | "I find patterns most useful as vocabulary. Which does your team use most?" |

---

# GoF Pattern Categories

---
id: DP-002
title: GoF Pattern Categories
category: Design Patterns
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #design-patterns, #creational, #structural, #behavioral, #gof
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> The 23 GoF patterns divide into three categories by purpose. Creational
> (5 patterns) abstract object creation - you decouple the code that uses
> objects from the code that creates them. Structural (7 patterns) compose
> classes and objects into larger structures while keeping them flexible.
> Behavioral (11 patterns) define how objects communicate and distribute
> responsibility. Knowing which category a problem falls into narrows the
> field from 23 patterns to 5, 7, or 11.

**3 minutes (Senior):**
> The category tells you where the complexity lies in your problem. If
> the problem is "I need different implementations created without the
> caller knowing which" - that is Creational (Factory Method, Abstract
> Factory). If the problem is "I have an existing class with the wrong
> interface and cannot modify it" - that is Structural (Adapter). If the
> problem is "I need to pass a request through a chain of handlers each
> of which may or may not handle it" - that is Behavioral (Chain of
> Responsibility).
>
> The category system is a mental search index. When I face a design
> problem I ask: is this about creation, composition, or communication?
> That narrows the field. Then I match the specific forces within the
> category.

**Blank Mind Recovery:**

**(1) Restate:** "GoF categories - the three groups the 23 patterns
divide into."

**(2) First principles:** "OO design has three types of problems: how
to create objects, how to arrange objects, and how objects talk to each
other. Each category addresses one."

**(3) Bridge:** "Think of it like grammar: nouns (what object to create
- Creational), adjectives (how it is structured - Structural), verbs
(what it does - Behavioral)."

---

### 📘 Concept Explanation

**What it is:**
The 23 GoF patterns organized into three groups by the type of design
problem they solve.

**The problem it solves:**
Without categorization, 23 patterns form a flat list that is hard to
search. Three categories create a mental index: identify the type of
problem, then scan only the relevant subset.

**How it works:**

```
CREATIONAL (5 patterns)
  Purpose: How to create objects

  Singleton        one globally shared instance
  Factory Method   defer type selection to subclasses
  Abstract Factory create a family of related objects
  Builder          step-by-step complex construction
  Prototype        clone an existing object

STRUCTURAL (7 patterns)
  Purpose: How to compose classes and objects

  Adapter    match incompatible interfaces
  Bridge     separate abstraction from implementation
  Composite  tree structure, uniform interface for leaf + node
  Decorator  add behavior without subclassing
  Facade     simplified interface to a subsystem
  Flyweight  share fine-grained objects to reduce memory
  Proxy      surrogate or placeholder for another object

BEHAVIORAL (11 patterns)
  Purpose: How objects communicate

  Chain of Responsibility  pass request through handlers
  Command                  encapsulate action as object
  Interpreter              grammar for a language
  Iterator                 sequential access without exposure
  Mediator                 centralized communication hub
  Memento                  capture and restore state
  Observer                 notify dependents of state change
  State                    behavior changes with state
  Strategy                 swappable algorithms
  Template Method          algorithm skeleton, defer steps
  Visitor                  operations on object structure
```

**The key insight:**
The category reveals the locus of change. Creational: what changes is
which object gets built. Structural: what changes is how objects connect.
Behavioral: what changes is what happens or how objects coordinate.
Identifying the locus of change first points to the right category.

**When to use it:**
Use the category as the first filter when facing a design problem:
classify the problem first, then select from the relevant category.

**When NOT to use it:**
Do not force a problem into a category. Some modern problems (reactive
programming, event streaming) are better addressed by patterns outside
the GoF 23.

**Alternatives:**
- **POSA (Pattern-Oriented Software Architecture)** - architectural
  patterns for distributed systems (Broker, Pipes and Filters, Layers)
- **Enterprise Integration Patterns** - messaging patterns (Message
  Channel, Router, Splitter)
- **Functional patterns** - monads, functors, fold/map replace many
  GoF behavioral patterns

**First-principles derivation:**
OO design activities: creating objects, organizing them, having them
work together. Three activities produce three categories.

---

### 💻 Code Example

```java
// CREATIONAL: Factory Method
// Problem: caller needs a Notifier but should not know the type
public abstract class NotifierFactory {
    // Subclass decides which Notifier to create
    public abstract Notifier createNotifier();

    public void sendAlert(String msg) {
        createNotifier().send(msg);
    }
}

public class EmailNotifierFactory extends NotifierFactory {
    public Notifier createNotifier() {
        return new EmailNotifier();
    }
}
```

> **Code walkthrough:** Factory Method separates object creation from
> use. `NotifierFactory` knows how to use a `Notifier` but not which
> concrete type to create. Subclasses fill in the creation. The caller
> picks the factory subclass at startup; after that, the type is hidden.

```java
// STRUCTURAL: Decorator
// Problem: add logging to any service without modifying it
public interface OrderService {
    void placeOrder(Order order);
}

public class LoggingOrderService implements OrderService {
    private final OrderService delegate;

    public LoggingOrderService(OrderService delegate) {
        this.delegate = delegate;
    }

    public void placeOrder(Order order) {
        log.info("Placing order {}", order.getId());
        delegate.placeOrder(order);
        log.info("Order placed {}", order.getId());
    }
}
```

> **Code walkthrough:** Decorator wraps an existing object through the
> same interface. `LoggingOrderService` adds logging to any `OrderService`
> without inheritance. This is structurally how Spring AOP works: a proxy
> wraps the target bean, adding cross-cutting behavior.

```java
// BEHAVIORAL: Strategy
// Problem: algorithm varies per customer tier
public interface DiscountStrategy {
    double calculate(Order order);
}

public class OrderProcessor {
    private final DiscountStrategy discount;

    public OrderProcessor(DiscountStrategy discount) {
        this.discount = discount;
    }

    public double finalPrice(Order order) {
        return order.total() - discount.calculate(order);
    }
}

// At runtime:
// new OrderProcessor(new PremiumDiscount())
// new OrderProcessor(order -> 0.0)  // lambda: no discount
```

> **Code walkthrough:** Strategy makes the algorithm pluggable.
> `OrderProcessor` knows it needs a discount calculation but not how
> it is computed. In Java 8+, `DiscountStrategy` is a `@FunctionalInterface`
> and can be a lambda - Strategy becomes a language primitive, not an
> extra class hierarchy.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The 23 GoF patterns split into Creational (5), Structural (7), and
> Behavioral (11). Creational: Singleton, Factory, Builder. Structural:
> Decorator, Adapter, Proxy. Behavioral: Observer, Strategy, Command.
> I find the category helpful because it narrows which patterns to
> consider once I know what kind of problem I have - creation, composition,
> or communication.

*Push deeper:* "Behavioral has the most patterns (11) because communication
problems have the most variety: notification, command queueing, state
transitions, iteration, request routing - each is a structurally different
shape."

---

**Senior / Staff (5+ years):**
> The three categories are a search index for pattern selection. First
> identify the locus of change in your problem. If what changes is how
> objects are created - Creational. If what changes is how classes connect
> or what interface they expose - Structural. If what changes is what
> objects do or how they coordinate - Behavioral.

In Spring, many GoF patterns are framework primitives. `BeanFactory` =
Factory. `ApplicationContext` + `ApplicationEvent` = Observer.
Spring AOP = Proxy + Decorator at the bytecode level. Recognizing the
underlying pattern helps when customizing framework behavior - you know
which extension point to use.

*Push deeper:* "Beyond GoF, the category system extends: POSA added
architectural patterns; EIP added integration patterns; DDD added domain
model patterns. Each category system reflects the type of problem in its
domain."

---

### ⚠️ Common Misconceptions

**Misconception 1: The three GoF categories reflect the purpose of objects, not the nature of the problem.**

The categories reflect the primary concern the pattern addresses: CREATIONAL patterns solve object creation complexity (decoupling instantiation from usage), STRUCTURAL patterns solve composition complexity (how objects and classes assemble into larger structures), BEHAVIORAL patterns solve communication complexity (how objects distribute responsibility and communicate). A Facade is structural because it simplifies a complex subsystem's interface; Composite is structural because it enables treating individual objects and compositions uniformly. Categorizing by "this is about how objects look" (structural) vs "this is about what objects do" (behavioral) often leads to confusion.

**Misconception 2: 23 GoF patterns is a complete list of all design patterns.**

The GoF book documents 23 patterns - specifically the ones the four authors found most relevant in 1994 object-oriented C++/Smalltalk codebases. The pattern literature has grown significantly since: POSA (Patterns of Software Architecture) documents architectural patterns, domain-driven design introduced tactical patterns (Repository, Aggregate, Domain Event), and enterprise patterns (Martin Fowler's "Patterns of Enterprise Application Architecture") cover persistence, session, and distribution patterns. GoF is the foundation, not the complete catalog.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Category confusion leads to wrong extension point.**

Symptom: developer reaches for a Structural pattern (Decorator,
Composite) to solve a communication problem (which is Behavioral
territory). Result: the extension point is wrong - you add wrappers
when you should add handlers. Diagnosis: ask "what is varying here -
the object structure or the object communication?" Structure varies:
Structural. Responsibility distribution varies: Behavioral. Object
creation varies: Creational.

**Failure Mode 2: Over-relying on 23 GoF patterns and ignoring
post-GoF patterns.**

Symptom: team tries to model a Repository, Domain Event, or
Publish/Subscribe system using only GoF categories and struggles
with the fit. Root cause: GoF does not cover domain, integration,
or enterprise patterns. Diagnosis: determine whether the problem
is infrastructure-level (GoF), domain-level (DDD tactical patterns),
or integration-level (EIP patterns). Fix: consult the right catalog.

**Failure Mode 3: Rigid category thinking blocks pattern hybrids.**

Symptom: developer debates whether Builder is Creational or
Behavioral rather than applying it to the problem. Pattern categories
are organizational heuristics, not formal type systems. Some patterns
sit at category boundaries (Abstract Factory is Creational but its
factory methods are Behavioral). The categories guide discovery;
they do not constrain application.

---

### 🎯 Interview Deep-Dive

#### Definition
- "Name the three GoF pattern categories."
- "What kinds of problems does each category solve?"
- "Which category has the most patterns and why?"

🗣️ "Three categories: Creational, Structural, and Behavioral. Creational
(5) addresses object instantiation - decoupling creation logic from usage.
Structural (7) addresses composition - how objects are wired together
and what interfaces they expose. Behavioral (11) addresses communication -
how objects coordinate, delegate, and distribute responsibility. Behavioral
has the most because communication problems have the most variety: event
notification, command queueing, state transitions, iteration, request
routing - each is a structurally distinct shape."

#### Mechanism
- "How do you decide which category a problem belongs to?"
- "How does knowing the category help you pick a specific pattern?"

🗣️ "I ask: what is varying in this system? If what changes is which
object gets created or how it is assembled - Creational. If what changes
is how objects are wired or what interface they expose - Structural. If
what changes is what happens when an event occurs or how a request is
processed - Behavioral. Once I have the category, I look at the patterns
in that group and match the specific forces. For example in Creational:
do I need one object from a family of related objects (Abstract Factory),
or do I need to defer the type to a subclass (Factory Method)?"

#### Comparison
- "Compare Structural Decorator vs Behavioral Strategy."
- "Proxy and Decorator are both Structural. How do they differ?"

🗣️ "Decorator and Proxy have identical structure: both wrap an object
through the same interface. The intent differs. Decorator adds behavior -
the wrapper adds functionality the original did not have (logging,
caching, validation). Proxy controls access - the wrapper manages how
and when the original is accessed (lazy loading, remote invocation,
security checks). In code they look the same; the difference is what
the wrapper knows about the wrapped object and why it exists."

#### Scenario
- "Design a plugin system for a reporting tool. Which categories apply?"

🗣️ "A plugin system spans all three categories. Creational: the plugin
loader uses Factory to instantiate plugin classes without knowing their
types - loads from configuration. Structural: a Facade provides a clean
API for plugins to register capabilities without exposing the internal
report engine. Behavioral: Strategy makes the plugin's report-generation
algorithm swappable; Observer notifies all registered plugins when a
report is requested. The category framing helps reason about each concern
separately."

#### Debugging
- "A newly added Behavioral pattern creates unexpected dependencies.
  How do you trace it?"

🗣️ "For unexpected Behavioral dependencies I trace the call chain by
temporarily adding logging to each observer or handler, which reveals
execution order and which components are being notified. For unexpected
Structural dependencies I inspect the object graph - in a DI container,
I print the bean definition tree to see which wrappers are applied. For
Creational issues I log in the factory creation method to see which
concrete type is being instantiated per call site."

#### Deep Dive
- "Why does Behavioral have the most patterns?"
- "Are there patterns that span categories?"

🗣️ "Behavioral has 11 because communication and collaboration problems
have the most variation: sequential access (Iterator), event notification
(Observer), algorithm selection (Strategy), state-dependent behavior
(State), responsibility delegation (Chain), command queuing (Command),
cross-structure operations (Visitor) - each captures a meaningfully
different structure with different trade-offs.
Some patterns span categories: Proxy and Decorator are Structural in
implementation but the distinction is Behavioral in intent. MVC uses
Observer (Model notifies View), Strategy (Controller selects behavior),
and Composite (View hierarchy) simultaneously."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Name all 23 patterns by category; explain one from each category with code. |
| Hiring Manager | "Categories give the team common classification for design reviews." |
| Bar Raiser | "Which category is most abused? Behavioral - Strategy gets applied everywhere." |
| Peer Engineer | "Which patterns do you reach for most? I find Observer and Strategy appear in almost every system." |

---

# Pattern Anatomy and Recognition

---
id: DP-003
title: Pattern Anatomy and Recognition
category: Design Patterns
difficulty: ★☆☆
interview_weight: medium
asked_at: All
seniority: all
tags: #design-patterns, #pattern-anatomy, #recognition, #refactoring
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> A pattern has four elements: name, problem (context and forces),
> solution (class structure), and consequences (what you gain and
> give up). Recognizing a pattern in existing code means spotting
> the structural signature: a set of roles, the interface between
> them, and the direction of dependency. Once you recognize the
> structure, you can name it and reason about it using the pattern's
> known trade-offs.

**3 minutes (Senior):**
> Pattern recognition is the reverse of pattern application.
> Application starts with a problem and selects a structure.
> Recognition starts with a structure and identifies the problem
> it was solving.
>
> The structural signatures are the key. Observer always has:
> Subject with a list of Observers registered through an interface;
> Subject calls a method on each Observer without knowing the concrete
> type. That signature is identifiable in code - look for a collection
> of interface references and a loop that calls a method on each.
> Decorator always has: two classes implementing the same interface,
> one wrapping the other.
>
> The non-obvious insight: naming the pattern communicates the entire
> structure and its trade-offs instantly. "This is Observer" tells the
> team: there is a Subject, there are Observers, notifications are
> asynchronous from the Subject's perspective, observers are decoupled,
> and the failure mode is stale or unhandled exceptions per listener.

**Blank Mind Recovery:**

**(1) Restate:** "Pattern anatomy - the structure of what makes up
a pattern description."

**(2) First principles:** "A pattern needs to be reusable. For
reusability it needs: a name (vocabulary), a problem description
(when to apply), a solution (what to build), and trade-offs (gain
and cost). Those four things are the anatomy."

**(3) Bridge:** "Like a recipe: the name (what dish?), the occasion
(when to cook it?), the ingredients and method (what to build?),
and the result and limitations (consequences)."

---

### 📘 Concept Explanation

**What it is:**
Pattern anatomy is the standard structure for describing a design
pattern. Pattern recognition is the skill of identifying which pattern
a piece of existing code implements.

**The problem it solves:**
Without a standard anatomy, patterns are described inconsistently.
Without recognition skills, you cannot leverage an existing pattern's
known trade-offs or refactor toward the correct solution.

**How it works:**

The GoF four-element anatomy:

```
NAME:
  The vocabulary handle.
  "Use Observer here" - instantly understood by pattern-literate
  engineers. Without the name, you need 5 minutes on a whiteboard.

PROBLEM:
  Context: where this problem arises
  Forces: competing constraints making the problem hard
  Example (Observer): "You have a one-to-many dependency. When one
  object changes state, all dependents need to update automatically.
  But the Subject should not know the concrete types of dependents."

SOLUTION:
  Which classes/interfaces exist, their responsibilities, and
  their collaborations. Not code - a structural description you
  adapt to your types.

CONSEQUENCES:
  Benefits: what the pattern enables
  Liabilities: what the pattern costs
  Observer benefits: loose coupling, broadcast communication.
  Observer liabilities: unexpected updates, hard-to-trace causation,
  cascade risk if one observer triggers another.
```

Structural fingerprints for common patterns:

```
Observer:
  Subject holds List<ObserverInterface>
  Method iterates list, calls notify(event) on each
  Subject does not hold concrete observer types
  Risk: exception in one observer blocks remaining observers

Strategy:
  Class has a field of interface type
  Key method calls field.execute(args)
  Field is injected at construction or set via setter
  Risk: strategy shared across threads if stateful

Decorator:
  Class implements Interface I, holds field of type I
  Methods delegate to field, adding behavior before/after
  Risk: double-wrapping if DI container misconfigured

Factory Method:
  Abstract class has method returning an interface
  Concrete subclasses override to return concrete type
  Risk: class explosion if many variants are needed

Builder:
  Class with many setter methods returning this
  Plus a build() method returning the target object
  Risk: partial builds if build() not called
```

**The key insight:**
Every pattern has a structural fingerprint. Once you know the fingerprint,
you can recognize the pattern in unfamiliar code without comments or
documentation. And once you name it, you know the known failure modes
and trade-offs without reading all the code.

**When to use it:**
Pattern recognition is always valuable: code reviews, architecture
discussions, refactoring planning, and technical interviews.

**When NOT to use it:**
Do not force code into a pattern name if the match is partial. A class
with a list field is not automatically Observer. Check all four elements:
does the problem match? Does the structure match?

**Alternatives:**
- **Code smell detection** - identifies structural problems (Large Class,
  Long Method) without prescribing a solution
- **Domain-specific vocabulary** - your team's own terms for recurring
  structures (sometimes clearer than generic pattern names)

**First-principles derivation:**
For a pattern to be reusable knowledge, it must be: communicable (name),
applicable (problem), actionable (solution), evaluable (consequences).
These four requirements produce the four-part anatomy.

---

### 💻 Code Example

```java
// RECOGNITION: What pattern is this?

public class UserRepository {
    private final List<UserChangeListener> listeners =
        new ArrayList<>();

    public void addListener(UserChangeListener l) {
        listeners.add(l);
    }

    public void updateUser(User user) {
        // ... update logic ...
        listeners.forEach(l -> l.onUserChanged(user));
    }
}

public interface UserChangeListener {
    void onUserChanged(User user);
}
```

> **Code walkthrough:** This is Observer. Fingerprint: `UserRepository`
> (Subject) holds `List<UserChangeListener>` (Observer interface).
> `updateUser` iterates the list and calls through the interface.
> Subject does not know concrete listener types. Production gap: if
> `onUserChanged` throws, remaining listeners are not notified. The
> correct production version wraps each call in try/catch.

```java
// RECOGNITION: What pattern is this?

public class SortedList<T extends Comparable<T>> {
    private final List<T> data = new ArrayList<>();
    private final Comparator<T> comparator;

    public SortedList(Comparator<T> comparator) {
        this.comparator = comparator;
    }

    public void add(T item) {
        data.add(item);
        data.sort(comparator);
    }
}

// Usage:
// new SortedList<>(Comparator.naturalOrder())
// new SortedList<>(Comparator.reverseOrder())
// new SortedList<>((a,b)->a.getName().compareTo(b.getName()))
```

> **Code walkthrough:** This is Strategy. `SortedList` holds a
> `Comparator<T>` field (the Strategy interface). The sort algorithm
> delegates to the strategy; the caller selects the strategy at
> construction time. In Java 8+, the strategy is passed as a lambda -
> Strategy is a language primitive, not a separate class hierarchy.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A pattern has four parts: name, problem, solution, and consequences.
> To recognize a pattern in code, I look for the structural signature.
> For Observer: a list of interface references and a loop calling a
> method on each. For Strategy: a field of interface type called in
> a key method. Once I recognize it, I can apply the known trade-offs
> without reading all the code.

*Push deeper:* "The most common patterns in Java codebases: Observer
(event listeners), Strategy (comparators, handlers), Factory (bean
creation), Decorator (interceptors, wrappers), Builder (config objects
with many optional fields)."

---

**Senior / Staff (5+ years):**
> Pattern recognition changes how I read code. Without it, I read
> line by line. With it, I see structure: "this is Observer" means I
> immediately know the notification model, the coupling direction, and
> the three failure modes I need to check.
>
> In code reviews I look for pattern misuse: the structural signature
> of a known pattern but with missing safeguards. Observer without
> exception handling in the notification loop - one bad listener
> silently prevents all subsequent listeners from running. Pattern
> recognition finds these issues faster than line-by-line analysis.

*Push deeper:* "At staff level, pattern anatomy extends to
architectural patterns. The anatomy is identical: name, problem,
solution, consequences. But the solution is boxes and arrows
(services, queues, databases) rather than classes and interfaces."

---

### ⚠️ Common Misconceptions

**Misconception 1: A pattern is only present if all its roles are named exactly as in the textbook.**

Patterns are recognized by STRUCTURE and INTENT, not by naming. A Spring `@Component` class that registers event handlers on an `ApplicationEventPublisher` IS the Observer pattern, even though the classes are named Publisher/Listener rather than Subject/Observer. Recognition requires understanding the problem being solved and the structural relationships, not matching class names to a diagram. Engineers who only recognize patterns when they see the exact textbook names miss 90% of pattern usage in real codebases.

**Misconception 2: Complex patterns are better designs than simple ones.**

Pattern complexity should match problem complexity. Using a full Abstract Factory with multiple factories, products, and type hierarchies to create one class in a codebase that will never have a second implementation is over-engineering. The test: does this pattern make the code MORE understandable and flexible for the actual requirements? If the answer is "it would, if we had multiple implementations" but you don't - the pattern adds indirection without benefit. Simplicity is a valid design value.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Incomplete pattern implementation breaks the
pattern's safety guarantees.**

Symptom: Observer pattern implemented without exception handling
in the notification loop - one bad listener throws an exception
and all subsequent listeners are silently skipped. The pattern
works 95% of the time but fails unpredictably under error
conditions. Diagnosis: test with a listener that throws on
notification. Fix: wrap each notification call in try/catch;
log and continue. Pattern anatomy includes the failure behavior,
not just the happy path.

**Failure Mode 2: Pattern recognized by name, not structure -
misses real instances in code review.**

Symptom: code review passes a subtle design flaw because the
reviewer did not recognize the structural fingerprint. An
event listener that holds a reference to a view component
and is never unregistered IS an Observer with a memory leak -
but only visible to someone who reads structure, not names.
Diagnosis: train yourself to read structural fingerprints:
collection of interface references = Observer. Single interface
called by context = Strategy. Wrapper that delegates to
a component = Decorator.

**Failure Mode 3: Pattern anatomy studied without the
"Consequences" section - consequences are where the failures
live.**

Symptom: team applies Singleton without reading the consequences:
tight coupling to global state, difficulty testing, hidden
dependencies, multithreading hazards. Each GoF pattern's
consequences section lists what you give up. Pattern anatomy
study that skips consequences produces engineers who know how
to build patterns but not when they will hurt them.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What are the four parts of a design pattern?"
- "What is a structural fingerprint?"

🗣️ "A pattern has four parts: name (vocabulary handle), problem (context
and forces), solution (class structure - roles, interfaces, collaborations),
and consequences (what you gain and give up). In code I recognize a pattern
by its structural fingerprint - the characteristic combination of roles and
interfaces that identifies it. Observer's fingerprint: a collection of
interface references in a Subject, a method iterating that collection and
calling through the interface. That pattern appears in event listeners,
message bus subscribers, and reactive streams - all Observer variants."

#### Mechanism
- "Walk me through recognizing Observer in unfamiliar code."
- "How do you verify code is correctly implementing a pattern?"

🗣️ "To recognize Observer: first, find a class with a collection field
holding an interface type - that is the Subject. Second, find a method
iterating that collection and calling a method through the interface -
that is the notification. Third, find other classes implementing that
interface - those are the Observers. To verify correctness I check the
consequences: are observers registered before events fire? Is there
protection against concurrent modification? Is there exception handling
per observer to prevent one bad observer from blocking the rest?"

#### Comparison
- "How does pattern recognition differ from code smell detection?"

🗣️ "Code smell detection identifies structural problems (Large Class,
Long Method, Feature Envy) without prescribing a solution. Pattern
recognition identifies structural solutions and names them. They are
complementary: a code smell says something is wrong; a pattern name
says the correct structure that resolves it. 'This class has Feature
Envy' pairs with 'refactor to Strategy - move the behavior to where
the data lives.' The smell identifies the problem; the pattern names
the solution."

#### Scenario
- "You are reviewing an unfamiliar codebase. How do you build a
  mental model quickly?"

🗣️ "I start by identifying key interfaces and their implementations.
Then I look for pattern signatures: does any class hold a list of
interface references (Observer)? Does any class wrap another of the
same interface (Decorator/Proxy)? Do methods take interface parameters
that vary (Strategy)? Are there abstract creation methods (Factory
Method)? Each pattern I recognize gives me a frame: the intent, the
coupling direction, and the known failure modes. After 15-20 minutes
I have a mental architecture map even before understanding any business
logic."

#### Debugging
- "A Decorator chain is producing wrong results. How do you diagnose?"

🗣️ "I trace the chain by temporarily logging the class name and
arguments at each wrapper level. In Java I use `getClass().getSimpleName()`
and log at entry to each decorator's method. This reveals the actual
execution order (sometimes wrapping order differs from intention),
the arguments at each level (a transformation might be applied twice),
and where behavior diverges from expectations. Root cause is usually
either double-wrapping (decorator applied twice in DI config) or wrong
ordering (two decorators in the wrong sequence)."

#### Deep Dive
- "Which patterns are most commonly misrecognized or confused?"
- "Can the same code implement multiple patterns simultaneously?"

🗣️ "Most commonly confused pairs: Decorator vs Proxy (same structure,
different intent), Factory Method vs Abstract Factory (single type vs
family of objects), Observer vs Mediator (direct vs centralized
notification). For interviews I always clarify intent: 'It has the
structure of Decorator, and the intent is to add behavior, so it is
Decorator. If the intent were access control, same structure but it
would be Proxy.'
Yes, the same code can implement multiple patterns: a typical Spring
controller involves Strategy (request handling), Facade (simplifying
the service layer), and Template Method (the request processing
lifecycle in DispatcherServlet)."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Demonstrate recognition on a real code snippet; name the pattern and its failure modes. |
| Hiring Manager | "Recognition speeds onboarding - I build a mental model of unfamiliar code faster." |
| Bar Raiser | "What is the cost of misidentifying a pattern? You apply the wrong known trade-offs and miss the real failure mode." |
| Peer Engineer | "I use pattern names in code reviews to shorthand design concerns: 'This Observer needs per-listener exception handling.'" |
