---
layout: default
title: "Design Patterns - META Patterns"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 18
permalink: /design-patterns/meta-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Pattern Recognition in Code](#pattern-recognition-in-code) | medium |
| 2 | [Patterns vs Over-engineering](#patterns-vs-over-engineering) | medium |
| 3 | [Refactoring to Patterns](#refactoring-to-patterns) | medium |

---

# Pattern Recognition in Code

---
id: DP-034
title: Pattern Recognition in Code
category: Design Patterns
difficulty: ★☆☆
interview_weight: medium
asked_at: Junior+
seniority: junior
tags: #design-patterns, #meta, #recognition, #code-reading, #refactoring
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Pattern recognition in code means seeing the structure beneath the
> implementation. When you see a method that accepts a strategy object
> with a single method, you recognize Strategy. When you see an object
> that maintains a list of listeners and notifies them on state changes,
> you recognize Observer. Recognizing patterns lets you understand unfamiliar
> code faster, communicate structure clearly, and spot where to apply
> the right pattern to improve a design.

**3 minutes (Senior):**
> The two sides of pattern recognition: (1) recognizing patterns in existing
> code - reading and understanding; (2) recognizing where a pattern should
> be applied - refactoring and designing.
>
> Reading: a class that wraps another class and adds behavior on every
> method call - that is a Decorator or Proxy. A class that creates other
> objects and the caller does not know the concrete type - that is a
> Factory Method or Abstract Factory. A class that holds a reference to
> another class and delegates to it - that is a Wrapper or Facade.
>
> Designing: code with repeated if/else chains that switch on type to
> call different behavior - consider Strategy. Code where one object
> calls methods on 5 other objects directly - consider Mediator (too
> many dependencies). Code where you pass state through 10 method calls
> to reach a deep component - consider Command or Context object.
>
> Pattern recognition is pattern fluency. Like language fluency: at first,
> you decode each word. Later, you read phrases whole. With patterns:
> at first, you analyze each class. Later, you see Observer or Factory at a glance.

**Blank Mind Recovery:**

**(1) Restate:** "Pattern recognition = seeing structural patterns in code.
Helps read unfamiliar code, communicate design, and identify improvements."

**(2) First principles:** "Patterns are recurring structures. If you have
seen a structure before and named it, you recognize it when you see it
again. The more patterns you know, the more structures you recognize."

**(3) Bridge:** "Like recognizing bird species. At first you see 'a bird'.
Then 'a small brown bird'. Then 'a house sparrow' in 2 seconds. Pattern
fluency is the software equivalent: 'I see a Strategy pattern' in 2 seconds."

---

### 📘 Concept Explanation

**Recognition signals by pattern type:**

```
Strategy:
  Signal: interface with one method passed as constructor arg
  or method parameter. Multiple implementations.
  Code clue: "if (algorithm != null) algorithm.execute(input)"

Observer:
  Signal: a list of listeners/subscribers maintained in a class.
  notifyAll() or notifyListeners() method.
  Code clue: "listeners.forEach(l -> l.onEvent(event))"

Decorator:
  Signal: class implements same interface as the class it wraps.
  Adds behavior before/after delegation.
  Code clue: "return wrapped.doThing() + extraBehavior()"

Factory Method:
  Signal: abstract class with createX() method. Subclasses override
  to return different concrete types.
  Code clue: "protected abstract Product createProduct()"

Proxy:
  Signal: class implements same interface as real object.
  May add logging, caching, authorization before delegating.
  Code clue: "log.info('calling'); return real.method(); log.info('done')"

Singleton:
  Signal: private constructor, static INSTANCE field,
  static getInstance() method.
  Code clue: "private static final X INSTANCE = new X()"

Template Method:
  Signal: abstract class with a concrete final method calling
  abstract methods (hooks).
  Code clue: "public final void execute() { before(); doX(); after(); }"
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Pattern fingerprints (structural clues):**

- Wraps another object of the same type = Decorator or Proxy
- Takes an interface as constructor argument = Strategy or Command injection
- List of listeners + notifyAll = Observer
- Private constructor + static getInstance = Singleton
- Abstract class + hook methods = Template Method or Builder
- One object creating many types without caller knowing the type = Factory

---

### 💻 Code Example

```java
// Identifying patterns by reading code:

// RECOGNITION EXERCISE: What pattern is this?
public class CachingRepository implements UserRepository {
    private final UserRepository delegate;
    private final Cache<UserId, User> cache;

    public CachingRepository(
            UserRepository delegate, Cache<UserId, User> cache) {
        this.delegate = delegate;
        this.cache = cache;
    }

    @Override
    public Optional<User> findById(UserId id) {
        return cache.get(id).or(
            () -> {
                Optional<User> user = delegate.findById(id);
                user.ifPresent(u -> cache.put(id, u));
                return user;
            });
    }
}
// ANSWER: Decorator (adds caching behavior to UserRepository
// without changing the interface or the real implementation).
// Recognition signals:
// 1. Implements the same interface as the wrapped object
// 2. Constructor takes the same interface as a parameter
// 3. Adds behavior (cache check/put) around the delegation call
```

> **Code walkthrough:** `CachingRepository` is a Decorator. The three
> recognition signals: (1) implements `UserRepository` - same interface
> as the delegate. (2) takes `UserRepository` as constructor argument -
> wraps the real implementation. (3) adds behavior (cache check) around
> `delegate.findById()`. Decorators are easy to miss because they look
> like normal implementations. The tell: "this class implements the same
> interface it takes as a constructor argument."

```java
// REFACTORING TO A PATTERN: recognizing where to apply

// BAD: type switch - a Strategy signal
public class ReportExporter {
    public void export(Report report, String format) {
        if ("PDF".equals(format)) {
            // 30 lines of PDF export logic
        } else if ("CSV".equals(format)) {
            // 25 lines of CSV export logic
        } else if ("EXCEL".equals(format)) {
            // 40 lines of Excel export logic
        }
        // Adding JSON requires editing this method
    }
}

// GOOD: Strategy - each format is a strategy
public interface ExportStrategy {
    byte[] export(Report report);
}

@Component("PDF")
public class PdfExportStrategy implements ExportStrategy {
    public byte[] export(Report report) {
        // PDF logic (isolated, testable)
    }
}

@Component("CSV")
public class CsvExportStrategy implements ExportStrategy {
    public byte[] export(Report report) { /* CSV logic */ }
}

public class ReportExporter {
    private final Map<String, ExportStrategy> strategies;

    public ReportExporter(
            Map<String, ExportStrategy> strategies) {
        this.strategies = strategies;
    }

    public byte[] export(Report report, String format) {
        ExportStrategy strategy = strategies.get(format);
        if (strategy == null) {
            throw new IllegalArgumentException(
                "Unknown format: " + format);
        }
        return strategy.export(report);
    }
}
// Adding JSON: create JsonExportStrategy, register it. Done.
// No changes to ReportExporter.
```

> **Code walkthrough:** The `if/else on type` in `ReportExporter` is the
> OCP violation signal: adding a new format requires modifying `ReportExporter`.
> The Strategy pattern recognition: multiple branches doing "the same thing,
> differently" is always a Strategy candidate. After refactoring: `ReportExporter`
> is closed for modification; open for extension. In Spring: strategy
> registration is done via `@Component` + injecting `Map<String, ExportStrategy>`
> (Spring auto-maps bean names to map keys).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Pattern recognition means seeing structural patterns when reading code.
> The signals: a class implementing the same interface it wraps = Decorator/Proxy.
> A class with a list of listeners and a notifyAll method = Observer.
> Multiple if/else branches doing "the same thing differently" = Strategy
> opportunity. Getting fluent takes practice: read open-source projects
> and try to name the patterns before reading documentation.

---

**Senior / Staff (5+ years):**
> Experienced engineers read code at the pattern level, not the class level.
> "This is a Chain of Responsibility" immediately communicates the structure,
> the extension point, and the failure modes - without reading each class.
> The skill: recognizing patterns by their structural signals, not just
> by their code structure. The structural signals: how dependencies flow,
> what the extension point is, how objects are created, and what
> relationships exist between objects.

---

### ⚠️ Common Misconceptions

**Misconception 1: A class implementing an interface means a pattern is in use.**

Interfaces are a language mechanism, not a pattern indicator. Most interfaces in production code exist for testability (inject mock in tests), not to implement a GoF pattern. Recognizing patterns requires identifying the STRUCTURAL RELATIONSHIP and INTENT: does one object hold a reference to another via an interface and call it to perform an operation? That's delegation - possibly Strategy, Command, Observer, or Template Method depending on who controls invocation and lifecycle. Look for the intent, not the interface.

**Misconception 2: The original developer's intent determines what pattern is present.**

Patterns are in the structure, not the developer's mind. Code that has the structure of Observer - a subject maintaining a list of observer interfaces and notifying them on state change - IS Observer, whether or not the developer called it that. Conversely, code named "OrderStrategyFactory" may not implement either Strategy or Factory Method correctly. Pattern recognition is structural analysis; naming is documentation. Read the structure, not the comments.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Name-driven recognition misses 90% of real
pattern usage.**

Symptom: engineer only flags a pattern in code review when the
class names match textbook examples (ObserverInterface, Subject,
ConcreteObserver). Misses the Spring ApplicationEventPublisher
+ ApplicationListener structure, the Guava EventBus subscribers,
and the Reactor/RxJava Observable chain - all structural Observer
implementations. Diagnosis: stop looking at class names; look at
the dependency graph. A collection of callbacks, listeners, or
subscribers that are notified on state change = Observer regardless
of naming.

**Failure Mode 2: False positive pattern recognition leads to
wrong refactoring decisions.**

Symptom: code is named "OrderFactory" but does not implement
Factory Method (it just has a static create() method with no
polymorphism). Treating it as Factory Method leads to refactoring
that adds AbstractFactory, Creator, and Product hierarchies
around a method that had no extension requirement. Diagnosis:
verify BOTH structure AND intent. A method named "create" is not
a pattern without the polymorphic extension point.

**Failure Mode 3: Pattern blindness in architecture review
misses structural problems.**

Symptom: architecture review approves a design with a god
object that has 20 listener types registered on it. The god
object IS the Observer Subject - and it violates SRP because
it has 20 responsibilities. Pattern recognition in architecture
review means reading structural implications: who owns what,
what are the dependency directions, what is the blast radius
of a change.

---

### 🎯 Interview Deep-Dive

**Q: How do you identify which design pattern to use for a given problem?**

🗣️ "I look at three dimensions: (1) What varies? If the algorithm varies =
Strategy. If the object creation varies = Factory/Builder. If the object
structure varies = Decorator/Composite. (2) What is the relationship between
the objects? One-to-many notification = Observer. One controls many =
Mediator or Facade. Chain of handlers = Chain of Responsibility. (3) What
is the extension point? How will this change in the future? Strategy extends
by adding implementations. Observer extends by adding listeners. Decorator
extends by adding wrappers. Matching the extension point to the expected
change direction is the key design decision."

**Q: What are signs that a codebase needs pattern refactoring?**

🗣️ "Five code smells that signal specific patterns: (1) Type switch
(if/else on type in multiple places) - Strategy pattern. (2) Long
constructor parameter lists - Builder pattern. (3) Direct dependencies
on many unrelated classes in one method - Mediator or Facade. (4) State
machines implemented as if/else chains - State pattern. (5) Repeated
code that differs only in one algorithm step - Template Method or Strategy.
The pattern is not the goal; removing the duplication or the fragility
is. The pattern is the named, known-good solution to that specific problem."

**Q: How do you recognize a Decorator vs a Proxy?**

🗣️ "Both implement the same interface as the object they wrap. The
distinction: Decorator adds behavior (extends functionality); Proxy
controls access (lazy loading, caching, authorization, remote access).
Functional test: does it change WHAT the method does (Decorator) or does
it control WHETHER/HOW the method is accessed (Proxy)? JDK dynamic proxy
in Spring: controls access to beans for AOP (transaction, logging). A
`CachingRepository`: Decorator (adds caching behavior). A `SecureRepository`
that checks permissions before delegating: Proxy. In practice: the line
is blurry; both are 'wrappers.' The intent and naming matter more than
the strict distinction."

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


# Patterns vs Over-engineering

---
id: DP-035
title: Patterns vs Over-engineering
category: Design Patterns
difficulty: ★☆☆
interview_weight: medium
asked_at: Mid+
seniority: mid
tags: #design-patterns, #meta, #over-engineering, #yagni, #simplicity
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Pattern overuse (over-engineering) is as harmful as pattern ignorance
> (under-engineering). Every pattern adds indirection - a layer of
> abstraction that makes the code harder to read without a compelling reason.
> The test: "What problem does this pattern solve in this specific code?"
> If the answer is "it might be useful in the future" = over-engineering.
> If the answer is "it solves X concrete problem" = appropriate use.

**3 minutes (Senior):**
> The three forms of pattern over-engineering: (1) Premature abstraction:
> adding Strategy before you have more than one strategy. One strategy
> with no concrete variation coming is just an interface with one implementation.
> YAGNI (You Aren't Gonna Need It) applies. (2) Pattern fetish: using
> a pattern because it is a known pattern, not because it solves a problem.
> Abstract Factory when you have one product family and no concrete variation.
> Decorator chain of 5 for behavior that would be clearer as direct code.
> (3) Complexity escalation: patterns that cascade. An event-driven
> Observer that triggers another Observer that triggers a Command that
> fires an event that updates another Observer. The debugging cost is high.
>
> The test: read the code without the pattern. If the code is simpler
> and loses nothing - the pattern is over-engineering. If the code is
> harder to maintain, extend, or understand without the pattern - it belongs.

**Blank Mind Recovery:**

**(1) Restate:** "Pattern overuse = over-engineering. Every pattern adds
indirection. Use a pattern when it solves a concrete, present problem."

**(2) First principles:** "Simplicity is a feature. The simplest code
that is correct and maintainable is the right code. Patterns are
complexity reduction tools, not complexity addition tools."

**(3) Bridge:** "Like medical treatment. Aspirin for a headache: appropriate.
Surgery for a headache: over-engineering. The treatment should match
the severity of the problem."

---

### 📘 Concept Explanation

**YAGNI (You Aren't Gonna Need It):**

XP principle: do not add functionality until it is needed. Applied to
patterns: do not add a pattern until the problem it solves is present.
"We might have multiple strategies in the future" is not a current problem.

**When patterns are appropriate:**

- The problem the pattern solves is present NOW (not "might be" in the future)
- The pattern reduces duplication or improves clarity
- The extension point the pattern provides will be used
- The team knows the pattern and can work with it

**When patterns are over-engineering:**

- One implementation of a Strategy interface
- Observer with one observer
- Builder for an object with 2 fields
- Factory for objects where the concrete type never changes
- Abstract Factory when there is one product family
- Singleton for a class that does not need global state

**The complexity cost of patterns:**

Each pattern adds:
- More classes/interfaces to navigate
- Indirection (follow the interface to find the implementation)
- Abstraction (the concrete behavior is hidden)
- Documentation burden (team needs to understand the pattern)

These costs are worth it when the benefit (extension, isolation, clarity)
outweighs them. They are not worth it when the benefit is hypothetical.

---

### 💻 Code Example

```java
// OVER-ENGINEERING: Strategy with one implementation

// BAD: Pattern added "just in case"
public interface UserNotifier {
    void notify(User user, String message);
}

@Service
public class EmailUserNotifier implements UserNotifier {
    // ... email implementation
}

// There is only one implementation. There are no plans for another.
// The interface adds indirection with no current benefit.

// GOOD: Start simple
@Service
public class UserNotifier {
    public void notify(User user, String message) {
        // ... email implementation
    }
}
// When a second notification channel is needed: refactor to Strategy.
// IDEs make this trivial: "Extract Interface" in 2 seconds.
// No performance penalty for extracting the interface later.
```

> **Code walkthrough:** The "BAD" example adds an interface before there
> is a reason to have one. Every reader must check "are there other
> implementations of `UserNotifier`?" - and the answer is no. Cognitive
> overhead with zero benefit. The "GOOD" example: simple class, easy to
> read, easy to test (no interface needed for mocking in Mockito - `@Mock`
> works on classes too). When a second implementation is needed: `Extract
> Interface` in IntelliJ takes 3 seconds. YAGNI.

```java
// APPROPRIATE PATTERN USE: Strategy with multiple present implementations

// GOOD: Strategy is appropriate - variations exist NOW
@Component("EMAIL")
public class EmailNotificationStrategy
        implements NotificationStrategy {
    public void notify(User user, String message) {
        // email logic
    }
}

@Component("SMS")
public class SmsNotificationStrategy
        implements NotificationStrategy {
    public void notify(User user, String message) {
        // SMS logic
    }
}

@Component("PUSH")
public class PushNotificationStrategy
        implements NotificationStrategy {
    public void notify(User user, String message) {
        // push notification logic
    }
}
// Three strategies exist. The pattern eliminates the type switch.
// New notification channels: add one class. Done.
// This is the right use of Strategy.
```

> **Code walkthrough:** Three implementations of `NotificationStrategy`
> exist. The Strategy pattern eliminates a three-branch if/else chain
> in the caller. Adding a new channel: create a new class annotated
> with `@Component("SLACK")`, Spring auto-registers it. This is appropriate
> pattern use: a concrete, present problem (three algorithms, more expected)
> is solved by a concrete, proven solution (Strategy). No "might be useful"
> reasoning needed.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Over-engineering means adding more complexity than the problem requires.
> With patterns: a Singleton for a class that could be a simple static,
> a Builder for a 2-field object, a Strategy interface with only one
> implementation. The test: "What specific problem in this specific code
> does this pattern solve?" If the answer is vague ("it is more flexible")
> or future ("we might need it later") - reconsider.

---

**Senior / Staff (5+ years):**
> The most common over-engineering I see in Java: premature abstraction.
> An interface for every class "for testability" - but then the test mocks
> the interface and never tests the real behavior. An event bus for every
> internal call "for decoupling" - but then debugging requires tracing
> through 5 event types to understand one feature. The rule I apply:
> "Is there a specific, present benefit that justifies this indirection?"
> Abstraction for future flexibility is sometimes wise and sometimes
> "speculative generality" (a code smell). The difference: domain-level
> extension points (payment providers, notification channels) tend to
> vary. Internal utility calls rarely do.

---

### ⚠️ Common Misconceptions

**Misconception 1: Refactoring to patterns always improves code quality.**

Refactoring TO a pattern adds abstraction; the question is whether the abstraction buys more than it costs. Adding a Strategy pattern where there is exactly one strategy (and realistically will only ever be one) adds an interface, a concrete class, a context class, and four more files to understand for a feature that could be a simple method. Code quality means appropriate complexity for the problem. Over-abstracted code is just as harmful as under-abstracted code.

**Misconception 2: Experienced engineers use more patterns than junior engineers.**

Experienced engineers use patterns APPROPRIATELY - which often means using FEWER patterns, more deliberately. A senior engineer who writes a clean, direct 50-line implementation is demonstrating more skill than a junior engineer who wraps the same functionality in three layers of Pattern-named abstractions. The mark of experience is knowing when NOT to apply a pattern, not knowing more patterns.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Speculative generality - patterns applied for
problems that never materialize.**

Symptom: Abstract Factory hierarchy with 4 implementations
"in case we need to support multiple databases" - but the
product has one database and no roadmap item for a second.
The codebase has 15 files (factories, products, builders)
for a feature that needed 2. Diagnosis: count how many
pattern-role classes exist with a single implementation.
If a Strategy has 1 concrete class: the abstraction is not
earning its cost. Fix: inline the single implementation,
reintroduce abstraction when the second case arrives.

**Failure Mode 2: Pattern avoidance causes the very problem
patterns prevent.**

Symptom: team avoids design patterns as "over-engineering".
Result: business logic duplicated in 8 service classes, each
with its own if/else chain for the same algorithm variants.
The code that most benefits from Strategy or Template Method
is written as procedural duplication. Diagnosis: search for
duplicated switch/if-else blocks across multiple classes
selecting behavior by type. That IS the pattern problem; the
pattern is the solution.

**Failure Mode 3: Pattern applied to wrong scope causes cascade
rewrites.**

Symptom: Decorator pattern applied at the wrong abstraction
level - wrapping concrete classes instead of interfaces.
When the concrete class changes: all decorators break. Diagnosis:
check that the pattern's roles use the correct abstraction
level. Decorator must wrap the component interface. Strategy
must inject the strategy interface. Fix: introduce the
correct interface first, then apply the pattern.

---

### 🎯 Interview Deep-Dive

**Q: How do you decide when a design pattern is appropriate vs overkill?**

🗣️ "Three questions: (1) What problem does it solve right now? If the
problem is hypothetical: wait. (2) What is the cost? Patterns add classes,
interfaces, and indirection. A 2-file solution is more maintainable than
a 5-file solution if the complexity is the same. (3) Will the extension
point be used? Strategy is appropriate when you have 2+ algorithms or
will add them soon. Strategy with 1 algorithm and no planned variation:
YAGNI. The practical approach: write the simplest correct code first.
If a pattern would reduce duplication, improve extension, or add clarity
to existing code: refactor to it. Patterns are refactoring targets, not
starting points."

**Q: What is the "speculative generality" code smell?**

🗣️ "Martin Fowler's term for over-engineering: adding abstractions,
parameters, or hooks for cases that do not yet exist and may never exist.
Examples: abstract class with 3 hook methods when only 1 is ever overridden.
A Strategy interface with 1 implementation. A plugin system for extensions
that were never added. The symptom: the code is hard to understand because
of abstract names and hook methods that 'do nothing' in all current paths.
The fix: YAGNI. Remove the generality until it is needed. Modern IDEs
make refactoring toward generality trivial - the risk of not having it
early is low."

**Q: Give an example of code that was made worse by a design pattern.**

🗣️ "A common case: applying Singleton to a service that should be
stateless. The Singleton makes testing hard (shared state across tests),
prevents parallel test execution, and ties lifecycle management to the
class itself instead of the IoC container. Spring beans are singletons
by default - use Spring's singleton scope instead of implementing the
Singleton pattern. Another example: applying Abstract Factory when there
is one product family. The Abstract Factory pattern requires 2 interfaces
(factory + product), 2 concrete classes, and a creation method. For
one family: `new ConcreteProduct()` is clearer. The pattern adds 3 classes
and 2 interfaces without adding flexibility."

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


# Refactoring to Patterns

---
id: DP-036
title: Refactoring to Patterns
category: Design Patterns
difficulty: ★☆☆
interview_weight: medium
asked_at: Mid+
seniority: mid
tags: #design-patterns, #meta, #refactoring, #incremental, #legacy-code
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Refactoring to patterns means improving existing code incrementally
> by introducing a design pattern where the code needs it - without
> changing behavior. The trigger: a code smell that a pattern solves.
> Long if/else chains on type: Strategy. God class doing too much: Facade
> or decompose. Direct dependencies everywhere: Mediator or DI. Refactoring
> to patterns is the application of patterns to real code, not greenfield.

**3 minutes (Senior):**
> "Refactoring to Patterns" is the title of a book by Joshua Kerievsky
> (2004). The premise: patterns are the destination of incremental
> refactoring, not the starting point. You write simple code first.
> As complexity grows and code smells appear, you refactor toward the
> appropriate pattern.
>
> The workflow: (1) identify a code smell (duplicated algorithm, if/else
> chain on type, God class, tight coupling). (2) identify which pattern
> addresses that smell. (3) apply the pattern incrementally using
> standard refactoring moves: Extract Method, Extract Class, Extract
> Interface, Move Method. (4) run tests after each move. (5) the pattern
> emerges from the refactoring.
>
> Key insight: code reaches a pattern through refactoring, not through
> planning. If you plan a pattern upfront (top-down), you often pick
> the wrong one. If you let the code tell you what it needs (bottom-up),
> the right pattern is usually obvious: "all these if/else branches
> are algorithms - they want to be Strategy."

**Blank Mind Recovery:**

**(1) Restate:** "Refactoring to patterns: apply patterns to existing code
to remove code smells. Bottom-up, not top-down. Code tells you the pattern."

**(2) First principles:** "Clean code is an ongoing process. Start simple.
Refactor when complexity arrives. Patterns are the destination, not
the starting point."

**(3) Bridge:** "Like urban planning. You do not design a city from scratch.
You start with roads and buildings. Over time: widen roads under traffic,
add parks where density is too high, add transit where travel is heavy.
Refactoring is the same: respond to actual complexity, not hypothetical."

---

### 📘 Concept Explanation

**Code smells and their pattern destinations:**

```
Smell: Long if/else chains on type
  if (type.equals("PDF")) { ... }
  else if (type.equals("CSV")) { ... }
Pattern: Strategy or Command

Smell: Duplicated code with one varying step
  processOrder(...) {
    validate();
    ...(same 20 lines)...
    calculateTax();  // <-- only this varies
    ...(same 10 lines)...
  }
Pattern: Template Method

Smell: God class (too many responsibilities)
  OrderService: creates orders, sends emails,
    updates inventory, charges payment, sends receipts
Pattern: Extract services, use Facade or Mediator

Smell: Constructor with 8+ parameters
  new Order(id, user, items, address, coupon,
    payment, notes, priority)
Pattern: Builder

Smell: Object with many states + complex transitions
  if (status.equals("DRAFT")) { ... }
  else if (status.equals("PLACED")) { ... }
Pattern: State

Smell: Tight coupling - one class knows 5 others
  OrderService knows: InventoryService,
    PaymentService, ShippingService,
    EmailService, NotificationService
Pattern: Mediator or Event-driven (Observer)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Refactoring mechanics:**

- Extract Method: isolate a section of code into a method.
  Prerequisite for most pattern refactorings.
- Extract Class: when a class has too many responsibilities.
  Create a new class with the extracted responsibility.
- Extract Interface: when you need to abstract a class.
  IDE does this in one step.
- Move Method: move a method to the class that owns its data.

**Incremental refactoring to Strategy:**

```
Step 1: Identify the varying algorithm in the if/else chain
Step 2: Extract each branch into a separate method
Step 3: Extract an interface for those methods
Step 4: Extract each method to a class implementing the interface
Step 5: Replace the if/else chain with a lookup (map or DI)
Run tests after EVERY step.
Total time: 20-30 minutes.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// REFACTORING STEPS: Moving from if/else to Strategy

// STEP 0 (before): type switch in PricingService
public class PricingService {
    public BigDecimal calculateDiscount(
            Order order, String customerType) {
        // Business logic buried in if/else
        if ("VIP".equals(customerType)) {
            BigDecimal vipDiscount = order.getTotal()
                .multiply(BigDecimal.valueOf(0.20));
            if (order.getTotal().compareTo(
                    BigDecimal.valueOf(1000)) > 0) {
                vipDiscount = vipDiscount.add(
                    BigDecimal.valueOf(50));
            }
            return vipDiscount;
        } else if ("LOYAL".equals(customerType)) {
            return order.getTotal()
                .multiply(BigDecimal.valueOf(0.10));
        } else if ("NEW".equals(customerType)) {
            return order.getItemCount() > 3
                ? BigDecimal.valueOf(15)
                : BigDecimal.ZERO;
        }
        return BigDecimal.ZERO;
    }
}

// STEP 1: Extract each branch to a private method
// STEP 2: Extract interface
public interface DiscountStrategy {
    BigDecimal calculate(Order order);
}

// STEP 3: Extract classes
public class VipDiscountStrategy
        implements DiscountStrategy {
    public BigDecimal calculate(Order order) {
        BigDecimal discount = order.getTotal()
            .multiply(BigDecimal.valueOf(0.20));
        if (order.getTotal().compareTo(
                BigDecimal.valueOf(1000)) > 0) {
            discount = discount.add(
                BigDecimal.valueOf(50));
        }
        return discount;
    }
}

public class LoyalDiscountStrategy
        implements DiscountStrategy {
    public BigDecimal calculate(Order order) {
        return order.getTotal()
            .multiply(BigDecimal.valueOf(0.10));
    }
}

public class NewCustomerDiscountStrategy
        implements DiscountStrategy {
    public BigDecimal calculate(Order order) {
        return order.getItemCount() > 3
            ? BigDecimal.valueOf(15)
            : BigDecimal.ZERO;
    }
}

// STEP 4: Replace if/else with map
@Service
public class PricingService {
    private final Map<String, DiscountStrategy> strategies;

    public PricingService(
            Map<String, DiscountStrategy> strategies) {
        this.strategies = strategies;
    }

    public BigDecimal calculateDiscount(
            Order order, String customerType) {
        return strategies
            .getOrDefault(customerType,
                order2 -> BigDecimal.ZERO)
            .calculate(order);
    }
}
// Adding a new customer type: create one class, register it.
// No changes to PricingService or any other class.
```

> **Code walkthrough:** Four refactoring steps, each independently
> verifiable with tests. Step 0: the if/else is correct but not
> extensible (OCP violation). Steps 1-3: Extract Method, Extract
> Interface, Extract Class. Step 4: replace the if/else dispatch with
> a map lookup. After refactoring: each discount strategy is isolated,
> independently testable, and named clearly. `VipDiscountStrategy` tests
> run in isolation without constructing a full `PricingService`.
> Cognitive load per class drops from "understand all the if/else" to
> "understand one discount calculation."

```java
// REFACTORING TO BUILDER: Constructor parameter explosion

// BAD: 8-parameter constructor
public EmailMessage(
        String to, String from, String replyTo,
        String subject, String body,
        boolean htmlEnabled, List<Attachment> attachments,
        Map<String, String> headers) {
    // ... validation and assignment
}
// Calling it: new EmailMessage(to, from, null, subject, body,
//     true, Collections.emptyList(), Collections.emptyMap())
// What does null mean? What does true mean?

// GOOD: Builder with named parameters
public class EmailMessage {
    private final String to;
    private final String from;
    private final String subject;
    private final String body;
    // ... other fields with defaults

    private EmailMessage(Builder builder) {
        this.to = builder.to;
        this.from = builder.from;
        this.subject = builder.subject;
        this.body = builder.body;
        // ... etc
    }

    public static Builder builder(
            String to, String from) {  // required params
        return new Builder(to, from);
    }

    public static class Builder {
        private final String to;
        private final String from;
        private String replyTo;
        private String subject = "";
        private String body = "";
        private boolean htmlEnabled = false;
        private List<Attachment> attachments =
            Collections.emptyList();

        private Builder(String to, String from) {
            this.to = to;
            this.from = from;
        }

        public Builder subject(String s) {
            this.subject = s; return this;
        }
        public Builder body(String b) {
            this.body = b; return this;
        }
        public Builder htmlEnabled(boolean h) {
            this.htmlEnabled = h; return this;
        }
        public Builder attachments(
                List<Attachment> a) {
            this.attachments = a; return this;
        }
        public EmailMessage build() {
            // validate required fields
            Objects.requireNonNull(to, "to required");
            Objects.requireNonNull(from, "from required");
            return new EmailMessage(this);
        }
    }
}

// Usage: self-documenting
EmailMessage msg = EmailMessage
    .builder(to, from)
    .subject("Your order has been placed")
    .body(bodyHtml)
    .htmlEnabled(true)
    .attachments(attachments)
    .build();
```

> **Code walkthrough:** The Builder refactoring solves two problems:
> (1) telescoping constructors (5 overloaded constructors with different
> optional parameter combinations); (2) parameter position confusion
> (which positional argument is which?). The Builder's named methods
> (`subject()`, `body()`, `htmlEnabled()`) are self-documenting.
> Optional fields have defaults. Required fields are in the `builder()`
> factory method. `build()` validates. Lombok's `@Builder` generates
> this boilerplate automatically: `@Builder` on the class creates an
> equivalent builder at compile time.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Refactoring to patterns means taking existing code that has grown
> messy and improving it by introducing a pattern where it fits.
> You do not start with patterns - you start with simple code and
> refactor toward patterns when the code tells you it needs one.
> Common starting points: too many if/else on type (Strategy),
> too many constructor parameters (Builder), complex state transitions
> (State), one class doing everything (decompose with Facade or Mediator).

---

**Senior / Staff (5+ years):**
> The most impactful refactoring targets in production Java codebases:
> (1) the God Service: a `@Service` class with 1,500 lines and 20 methods.
> Decompose by responsibility: each extracted class has 1-3 responsibilities.
> (2) the if/else type switch repeated in 5 places. One Strategy class
> hierarchy eliminates the duplication and the OCP violation. (3) the 
> integration test with `@SpringBootTest` that loads 200 beans to test
> one method. Hexagonal architecture refactoring: pure domain logic is
> testable without Spring. The test becomes a unit test. 100ms instead
> of 10 seconds. All three of these are pattern-driven refactorings that
> compound over time.

---

### ⚠️ Common Misconceptions

**Misconception 1: Refactoring to a pattern is only worth it if you have a failing test to protect the change.**

Refactoring to a pattern SHOULD be protected by tests, but the absence of tests does not prevent the refactoring - it increases the risk. The correct response to missing tests is to write them FIRST (characterization tests), then refactor. "We can't refactor because we have no tests" is a catch-22 that keeps codebases stuck. Write tests for the current behavior, refactor to the pattern, run tests to verify behavior is preserved.

**Misconception 2: Refactoring to a pattern is a large, risky change.**

Martin Fowler's refactoring catalog (which includes several pattern-directed refactorings) shows that refactoring to patterns is a series of small, safe steps: Extract Interface, Extract Class, Move Method, Introduce Parameter Object. Each step is individually safe and verifiable by running tests. A refactoring that feels like a "big bang" rewrite is not a refactoring - it is rewriting. Any pattern introduction should be decomposable into atomic refactoring steps.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Big-bang refactoring without test coverage
corrupts behavior silently.**

Symptom: team refactors legacy OrderService to use Strategy
for pricing in a single large commit. Three edge cases break
in production: promotional pricing, B2B tier pricing, and
zero-quantity guard. No tests existed for these paths before
refactoring. Diagnosis: check coverage before refactoring. If
branch coverage < 80%: stop, write characterization tests,
then refactor. Fix: the correct sequence is tests FIRST,
then refactoring steps, then verify tests pass.

**Failure Mode 2: Partial refactoring leaves code in a worse
state than the original.**

Symptom: Extract Interface done but the concrete class still
holds all logic - the interface is never injected, old code
uses the concrete type directly. Result: two parallel
representations of the same class with no benefit. Diagnosis:
a refactoring is incomplete if callers still depend on the
concrete type after the interface was extracted. Fix: complete
the refactoring (update call sites) or revert and plan the
full sequence before starting.

**Failure Mode 3: Refactoring in a live feature branch diverges
far from main.**

Symptom: pattern refactoring started in a feature branch.
Main continues to evolve. Two weeks later: 40 merge conflicts
between the refactoring branch and main. The refactoring cannot
be merged safely. Diagnosis: structural refactorings (introducing
patterns) must be merged frequently - at minimum daily. Fix:
use branch-by-abstraction (introduce interface on main, make
concrete class implement it on main, then shift call sites one
at a time) rather than a separate long-running branch.

---

### 🎯 Interview Deep-Dive

**Q: How do you introduce a design pattern into legacy code without
breaking existing behavior?**

🗣️ "The safety net: tests. Before refactoring, ensure the code has
tests that cover the current behavior. If no tests exist: write
characterization tests first (tests that document current behavior,
not what it should be). Then refactor in small steps: Extract Method,
Extract Interface, Extract Class - each step is independently testable.
Run tests after every step. If a test fails: revert the last step and
reconsider. The refactoring moves toward the pattern but never changes
behavior. The tests confirm this. In practice: 30 minutes of test writing
saves 3 hours of debugging the refactoring."

**Q: What is the biggest risk when refactoring to a pattern?**

🗣️ "Changing behavior while refactoring structure. The most common cause:
extracting a method and accidentally changing the order of operations,
or extracting a class and losing state that the original class maintained.
Mitigation: (1) run tests after every change; (2) use IDE automated
refactorings (Extract Method, Extract Interface) rather than manual
copy-paste - IDE refactorings are behavior-preserving; (3) review the
diff before committing. Second risk: over-refactoring - applying 3 patterns
where 1 was needed, making the code harder to read than the original.
The test: 'Is the refactored code clearer and more maintainable?' Not
just 'Is it a known pattern?'"

**Q: You have a 2,000-line service class in a production codebase.
How do you start refactoring it?**

🗣️ "Systematically, not all at once. Step 1: understand the class -
list all the responsibilities (payment, notification, inventory, audit).
Step 2: add tests for the current behavior if missing. Step 3: pick
the smallest, most self-contained responsibility. Extract that into
a new class using 'Extract Class' in the IDE. Run tests. Step 4: repeat
for the next responsibility. Over 3-5 sprints: the 2,000-line class
becomes 5-7 focused classes. Each sprint's refactoring is small enough
to review and safe enough to ship. The key: never do a big-bang rewrite.
Each small extraction is a shippable, testable change. The 2,000-line
class shrinks incrementally."

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



