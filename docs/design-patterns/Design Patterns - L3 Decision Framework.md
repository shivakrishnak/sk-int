---
layout: default
title: "Design Patterns - L3 Decision Framework"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 11
permalink: /design-patterns/l3-decision-framework/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [When to Use Design Patterns](#when-to-use-design-patterns) | medium |
| 2 | [Pattern Selection Framework](#pattern-selection-framework) | medium |

---

# When to Use Design Patterns

---
id: DP-025
title: When to Use Design Patterns
category: Design Patterns
difficulty: ★★☆
interview_weight: high
asked_at: Senior+
seniority: senior
tags: #design-patterns, #decision, #yagni, #oop, #refactoring
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Use a design pattern when you have the problem it solves - not before.
> The question is never "which pattern should I use here?" but "what
> problem do I have that a known pattern solves?" If no problem exists,
> no pattern is needed. The two triggers: (1) a variation point - you
> have or are certain to have multiple implementations; (2) a recurring
> change - you consistently change the same part of code for each new
> requirement. When those triggers are present, apply the matching pattern.

**3 minutes (Senior):**
> The correct workflow for applying patterns: (1) Identify the pain.
> Something is hard to test, hard to extend, or frequently breaks when
> requirements change. (2) Name the pattern of pain. "Every time we add
> a new payment provider, we touch 6 places." (3) Match to a pattern.
> Strategy encapsulates algorithms - matches payment provider variation.
> (4) Apply the pattern. Extract an interface; create implementations.
> (5) Verify the pain is gone. Adding a new payment provider now touches
> 1 place.
>
> The opposite workflow (wrong): "I should use Strategy here because
> this is a service and services should be interchangeable" leads to
> interfaces with one implementation that never changes. That is premature
> abstraction.
>
> The Rule of Three: do not extract an abstraction until you have seen
> the same pattern three times. First time: write it inline. Second time:
> note the duplication. Third time: now you understand the shape of the
> variation well enough to abstract it correctly. Abstracting after one
> instance creates abstractions that do not fit the second instance.

**Blank Mind Recovery:**

**(1) Restate:** "When to use patterns - use them when you have the
problem they solve, not in anticipation."

**(2) First principles:** "Patterns are solutions to problems. No problem:
no pattern. Problem identified: match to pattern. Rule of Three: wait
for three instances before abstracting."

**(3) Bridge:** "Like buying a car: you buy it when you need to travel
distances regularly, not when you might need to travel someday. The
cost of the car (complexity of the pattern) is only justified by the
benefit (solving the travel problem)."

---

### 📘 Concept Explanation

**When patterns ARE appropriate:**

1. **Variation exists or is certain.** You have 2+ implementations of
   the same behavior, or the business has confirmed multiple implementations
   are coming. Strategy, Factory, Abstract Factory, Bridge.

2. **A common change pattern is emerging.** Every new requirement causes
   the same type of modification (always adding to a class, always
   changing one method). Observer, Chain of Responsibility, Command.

3. **Cross-cutting concerns need decoupling.** Logging, security, caching
   should not be in every method. Proxy, Decorator, AOP.

4. **Complex construction.** Object construction requires many parameters,
   multi-step initialization, or resource acquisition. Builder, Abstract
   Factory.

5. **Subsystem complexity needs hiding.** A complex API (legacy system,
   third-party library) needs a simple surface. Facade.

**When patterns are NOT appropriate:**

1. **Only one implementation exists and none is planned.** Do not add
   Strategy, Factory, or Abstract Factory for one variant.

2. **The object is simple to construct.** If `new User(name, email)` is
   all that is needed, a UserFactory adds no value.

3. **The code is stable.** It never changes. No observers needed if
   nothing subscribes.

4. **YAGNI applies.** "We might need flexibility someday" is not a
   justification. "Business confirmed we need three payment providers
   by Q2" is.

**The key diagnostic questions:**

```
Decision tree for adding a pattern:

1. What problem am I trying to solve?
   -> "Nothing - I just think this should be a pattern"
   -> STOP. No pattern needed.
   -> "I have N implementations of the same interface" -> PROCEED

2. Has this pattern of change already happened?
   -> Yes (3+ times) -> Abstract now
   -> Yes (1-2 times) -> Note it, wait
   -> No -> STOP, YAGNI

3. Would a new team member understand why
   this pattern is here?
   -> Yes ("payment provider varies") -> Good
   -> No ("just seemed like a good idea") -> REMOVE

4. Does the pattern make testing easier or
   harder?
   -> Easier (mock the interface) -> Good pattern use
   -> Harder (complex factory hierarchy) -> WRONG use
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The refactoring trigger (most reliable signal):**

```
Code smell                    | Pattern to consider
-----------------------------|---------------------------
if/else chain on object type  | Visitor or Strategy
if/else chain on config value | Strategy or Factory
Large class (>500 lines)      | Facade decomposition
Duplicate construction code   | Builder or Factory
Direct coupling to 3rd party  | Adapter or Proxy
Cross-cutting code in methods | Decorator or Proxy
Chain of conditionals         | Chain of Responsibility
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// The Wrong Trigger: "I should add a pattern here"
// BAD: Pattern added before the variation exists
public interface UserRepository {
    User findById(Long id);
    void save(User user);
}

public class JpaUserRepository implements UserRepository {
    // The only implementation, ever
}

public interface UserRepositoryFactory {
    UserRepository create();
}

public class DefaultUserRepositoryFactory
    implements UserRepositoryFactory {
    public UserRepository create() {
        return new JpaUserRepository();
    }
}
// PROBLEM: UserRepositoryFactory exists for no reason.
// There is one repository type.
// Remove UserRepositoryFactory. Keep UserRepository interface
// only if you will need a test double.
```

> **Code walkthrough:** `UserRepositoryFactory` adds two files and
> a layer of indirection for a repository that never varies. The factory
> creates `JpaUserRepository` and nothing else. If the interface
> `UserRepository` is kept (it is useful for testing - `@MockBean`
> can mock it), the factory is still not needed: Spring can inject
> the `JpaUserRepository` directly. Only add the factory when the
> choice of repository type must vary at runtime.

```java
// The Right Trigger: variation exists
// Context: Company confirmed three payment providers in Q1
// The variation IS REAL. Strategy is justified.

// BAD: Before Strategy - if/else grows with each provider
public class PaymentService {
    public void charge(Order order, String provider) {
        if ("stripe".equals(provider)) {
            // Stripe API calls...
            // 20 lines of Stripe code
        } else if ("paypal".equals(provider)) {
            // PayPal API calls...
            // 20 lines of PayPal code
        } else if ("braintree".equals(provider)) {
            // Braintree API calls...
            // 20 lines of Braintree code
        }
        // Adding 4th provider: modify this class
        // Risk: breaking all 3 providers while adding 4th
    }
}
```

> **Code walkthrough:** Each new payment provider requires modifying
> `PaymentService`. Three providers: the method is 60+ lines.
> Four providers: 80+ lines. The change pattern: "every new provider
> adds to the if/else chain." This is the correct trigger for Strategy.

```java
// GOOD: Strategy applied with real variation
public interface PaymentProvider {
    PaymentResult charge(Order order);
    boolean supports(String providerCode);
}

@Component
public class StripeProvider implements PaymentProvider {
    public PaymentResult charge(Order order) { /* Stripe */ }
    public boolean supports(String c) {
        return "stripe".equalsIgnoreCase(c);
    }
}

@Component
public class PayPalProvider implements PaymentProvider {
    public PaymentResult charge(Order order) { /* PayPal */ }
    public boolean supports(String c) {
        return "paypal".equalsIgnoreCase(c);
    }
}

@Service
public class PaymentService {
    private final List<PaymentProvider> providers;

    public PaymentService(List<PaymentProvider> providers) {
        this.providers = providers;
    }

    public PaymentResult charge(Order order) {
        String code = order.getPaymentProvider();
        return providers.stream()
            .filter(p -> p.supports(code))
            .findFirst()
            .orElseThrow(() ->
                new IllegalArgumentException(
                    "Unknown provider: " + code))
            .charge(order);
    }
}
// Adding 4th provider: create new class, @Component, done.
// PaymentService not modified.
```

> **Code walkthrough:** Strategy applied to real variation. Each
> provider is a separate class. `PaymentService` is closed for
> modification (Open/Closed Principle). Adding Braintree: create
> `BraintreeProvider implements PaymentProvider`, annotate `@Component`,
> Spring discovers it. `PaymentService` is untouched. Testing any
> provider: inject the mock list. The pattern is justified by the
> real, existing variation.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Use a pattern when you have the problem it solves. The most important
> rule: Rule of Three. Do not extract an abstraction until you have seen
> the same pattern three times. First time: write it directly. Second time:
> notice the duplication. Third time: now abstract. Patterns applied too
> early often do not fit the second or third instance and have to be
> reworked anyway. Wait until the shape of the variation is clear.

---

**Senior / Staff (5+ years):**
> My decision framework: "Can I state the problem in one sentence, and
> does a standard pattern name that sentence?" If yes: apply the pattern.
> If not: no pattern. The second question: "What changes when requirements
> change?" If the answer is "this one place" (the Strategy implementation),
> the pattern is working. If the answer is "this class and this class and
> that class," the pattern is not isolating the variation.
>
> The meta-principle: patterns are vocabulary, not instructions. When
> I say "Strategy" in a design review, every senior engineer knows what
> I mean without further explanation. That vocabulary value is real.
> But vocabulary value does not justify a premature abstraction.

---

### ⚠️ Common Misconceptions

**Misconception 1: Design patterns should be applied at the start of a project for good architecture.**

Patterns should EMERGE from refactoring when a problem appears, not be imposed upfront. Starting with "we'll use an Abstract Factory, Strategy, and Command for flexibility" before knowing the actual requirements creates speculative abstractions that may not match real needs. Martin Fowler's principle: "You Aren't Gonna Need It." Write the simplest code that works; refactor to a pattern when you have duplication, unclear code, or real variability that the pattern addresses. Patterns are refactoring targets, not starting points.

**Misconception 2: Well-known patterns are always superior to custom solutions.**

A pattern's value comes from solving the right problem. A custom solution perfectly fit to the specific context may be simpler and more maintainable than a well-known pattern that almost fits. The Observer pattern with a custom `EventBus` implementation that matches the team's event handling requirements may be better than adopting a heavyweight event framework. Use patterns as vocabulary and inspiration, not as requirements.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Pattern applied to wrong problem creates complexity without benefit.**

Symptom: developers struggle to understand why the pattern is there; the problem the pattern solves doesn't exist in this codebase; removing the pattern simplifies the code without losing any functionality. Root cause: pattern selected from a catalog rather than derived from the actual problem. Diagnosis: ask "what problem does this pattern solve here?" - if the answer is vague or refers to a problem that doesn't exist yet, the pattern may be premature. Fix: if the pattern provides no benefit for current requirements, remove it (refactor to simpler code); if it anticipates real future requirements, document the rationale explicitly.

**Failure Mode 2: Pattern proliferation across the team without shared understanding.**

Symptom: different developers implement the same concept using different patterns (one uses Observer, another uses callbacks, another uses polling); inconsistent patterns for similar problems across the codebase; high mental overhead when reading code. Root cause: no agreed pattern language for the team. Diagnosis: audit how similar problems are solved across the codebase. Fix: establish team coding standards that specify which patterns to use for which problem categories; document pattern choices in architecture decision records.

---

### 🎯 Interview Deep-Dive

#### Definition
- "How do you decide when to apply a design pattern?"

🗣️ "Two-trigger rule: apply when (1) variation exists - you have or
are about to have multiple implementations of the same behavior - or
(2) a recurring change pattern is emerging - the same class changes
for every new requirement. If neither trigger is present: no pattern.
Rule of Three complements this: even when variation exists, wait until
the third instance to abstract. The first two instances do not tell you
the shape of the variation precisely enough to abstract correctly.
Abstracting after one instance often creates an abstraction that
breaks when the second instance arrives."

#### Mechanism
- "What is YAGNI and how does it apply to design patterns?"

🗣️ "You Ain't Gonna Need It. Applied to patterns: do not add flexibility
you do not yet need. Patterns create extensibility at a cost: more files,
more indirection, more complexity. The cost is justified when the
extensibility is used. If it is never used, you have paid the cost for
nothing. In practice: 'We might need a second payment provider someday'
is not a justification for Strategy. 'Business confirmed three payment
providers by Q2' is. The test: can you name the second implementation
that exists or is confirmed? If not: YAGNI applies. Add the abstraction
when the second implementation arrives."

#### Scenario
- "A junior developer has added a Factory, Strategy, and Abstract Factory
  to a simple data export feature. The feature exports to CSV. Only CSV.
  What do you do?"

🗣️ "Code review feedback: simplify. Ask: 'How many export formats do we
support?' - 'One: CSV.' Ask: 'Do we have plans for more?' - 'No.' Then:
'Remove the Factory, Strategy, and Abstract Factory. Write `new CsvExporter()`
directly. Add the Strategy interface when the second format is confirmed.'
This is not an attack on patterns - it is applying YAGNI. If the developer
pushes back: 'We should be ready for future formats.' Counter: The code is
not ready - it is encumbered. Adding a second format to a well-designed
Strategy interface takes 30 minutes. Removing unnecessary complexity and
then adding the right abstraction takes 2 hours. The YAGNI version is
faster to change when the requirement actually arrives."

#### Debugging
- "How do you audit a codebase for over-engineering from patterns?"

🗣️ "Three checks: (1) Count implementations per interface. Any interface
with exactly one implementation and no test doubles: candidate for removal.
Run: `find . -name '*.java' | xargs grep -l 'implements'` then check
each. (2) Measure Factory complexity. Any Factory that does nothing but
call `new`: remove it. (3) Check Strategy use: any Strategy interface
whose `switch`/`if-else` logic was moved from the caller to a dispatcher:
measure if it is simpler. If the dispatcher is as complex as the original
if/else: the Strategy did not help. Code metrics help: cyclomatic
complexity per class. Over-engineered code often has low cyclomatic
complexity per method (each method does little) but high total class
count. Correct engineering has the reverse."

#### Comparison Table

| Trigger | Pattern | Symptom if missing |
|---|---|---|
| Multiple algorithms | Strategy | if/else chain per algorithm |
| Multiple object types | Factory/Abstract Factory | if/else chain on type |
| Complex construction | Builder | Long constructors, null parameters |
| Subsystem complexity | Facade | Tight coupling to many classes |
| Cross-cutting concern | Proxy/Decorator | Duplicated code in many methods |
| Event-based decoupling | Observer | Tight coupling between emitter/consumer |

---

### ⚖️ Comparison Table

| Approach | When | Cost | Benefit |
|---|---|---|---|
| No pattern (inline) | One variant, stable code | Low | Simple, obvious |
| Pattern (premature) | Before need exists | Medium | None (negative) |
| Pattern (timed) | On second variant | Medium | Encapsulates variation |
| Pattern (Rule of 3) | After 3 instances | Medium | Well-shaped abstraction |
| Refactor to pattern | Pain exists, change is hard | High | Removes pain |

---

### 🔥 Field Q&A

**Q: You join a codebase with patterns everywhere but no clear benefit.
How do you propose simplification without a culture war?**

A: Empirical argument: pick one example of over-engineering (a Factory
with one implementation), remove it in a branch, show the diff. "Before:
3 files, 80 lines. After: 0 files, 1 line." Show the tests still pass.
Measure: the change takes 30 minutes; the removed complexity reduces
cognitive load for every future developer. Present it as a team standard
("Rule of Two: we add the abstraction when the second implementation
arrives") rather than "we did it wrong." Never make it personal. The
standard is the constraint, not the opinion. Over time: propose adding
the rule to the team's definition-of-done for pull requests.

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


# Pattern Selection Framework

---
id: DP-026
title: Pattern Selection Framework
category: Design Patterns
difficulty: ★★☆
interview_weight: high
asked_at: Senior+
seniority: senior
tags: #design-patterns, #decision, #selection, #framework, #solid
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Given a problem, map it to a pattern by answering four questions:
> (1) What varies? The thing that changes points to the pattern.
> (2) What is the relationship between objects? Composition points to
> Decorator/Composite; delegation points to Proxy/Adapter.
> (3) Who should know what? If coupling is the problem, patterns like
> Observer, Mediator, and Facade reduce it.
> (4) What is created? If object creation is complex or varying,
> Creational patterns apply.

**3 minutes (Senior):**
> The GoF's own selection framework organizes by intent: Creational
> (object creation), Structural (class/object composition), Behavioral
> (communication between objects). But intent alone is not enough for
> selection. The sharper lens: what SOLID principle violation does the
> code exhibit? That tells you which pattern family to use.
>
> Open/Closed violation (class changes for each new variant) -> Strategy,
> Factory, Observer. Single Responsibility violation (class does too much)
> -> Facade to decompose, Command to encapsulate actions, Mediator to
> decouple communication. Dependency Inversion violation (high-level
> modules depend on low-level) -> Abstract Factory, Builder, Proxy.
> Liskov violation (subclass does not behave like base class) -> usually
> a composition pattern over inheritance - Decorator, Strategy.
>
> The refinement: after identifying the pattern family, ask: "Does the
> pattern match my specific structure?" Strategy requires: a family of
> algorithms, interchangeable at runtime, with a common interface.
> If any of those three is missing, Strategy is not the right fit.

**Blank Mind Recovery:**

**(1) Restate:** "Pattern selection framework - mapping a problem to
the right pattern by asking what varies, what relates, what is created."

**(2) First principles:** "Patterns solve specific structural problems.
Map the structure of your problem to the structure of the pattern.
If the structures match, the pattern fits."

**(3) Bridge:** "Like a plumber's toolbox: you pick the wrench for the
pipe (size match) and the sealant for the joint (material match).
Picking by name alone ('I'll use a wrench') without checking the fit
breaks the pipe. Pattern selection is the same: match the tool to the
structure of the problem."

---

### 📘 Concept Explanation

**The SOLID-to-Pattern mapping (primary selection axis):**

| SOLID Violation | Symptom | Pattern Family |
|---|---|---|
| Open/Closed (OCP) | Class modified for each new variant | Strategy, Factory, Observer |
| Single Responsibility (SRP) | Large class, many reasons to change | Facade, Command, Mediator |
| Dependency Inversion (DIP) | High-level depends on low-level impl | Abstract Factory, Builder, Proxy |
| Interface Segregation (ISP) | Fat interface many clients don't use | Adapter, Facade |
| Liskov Substitution (LSP) | Subclass breaks base class behavior | Strategy over inheritance |

**The variation-to-pattern mapping (secondary axis):**

| What Varies? | Pattern |
|---|---|
| Algorithm / behavior | Strategy |
| Object type to create | Factory Method / Abstract Factory |
| Number of steps in construction | Builder |
| Interface between components | Adapter |
| Access control / lazy init / remote | Proxy |
| Responsibilities added to object | Decorator |
| System topology (tree structure) | Composite |
| Request handling chain | Chain of Responsibility |
| Reaction to state changes | Observer |
| State machine transitions | State |
| Sequence of operations | Template Method |
| Object collaboration logic | Mediator |
| Operations on object structure | Visitor |

**The structural fit test (validation step):**

Before applying a pattern, verify the structural fit:

```
Strategy fit test:
  [ ] There are 2+ algorithms solving the same problem
  [ ] The algorithms are interchangeable at a point in time
  [ ] A common interface can represent all algorithms
  [ ] The choice of algorithm is a separate concern from the caller
  If ALL 4: Strategy fits.
  If any is NO: reconsider.

Observer fit test:
  [ ] One object (Subject) changes state
  [ ] Multiple others (Observers) need to react
  [ ] The subject should not know observer specifics
  [ ] Observers are added/removed dynamically
  If ALL 4: Observer fits.
  If any is NO: reconsider.

Factory fit test:
  [ ] Multiple types of objects can be created here
  [ ] The caller should not know the concrete type
  [ ] Construction logic is complex or varies
  If ALL 3: Factory fits.
  If all NO: use new directly.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The relationship structure (tertiary axis):**

```
IS-A (inheritance) problems -> favor COMPOSITION patterns
  Decorator over inheritance for adding behavior
  Strategy over inheritance for varying behavior

HAS-A (composition) problems -> most patterns fit here
  Proxy HAS-A real subject
  Composite HAS-A list of components
  Facade HAS-A subsystem references

KNOWS-ABOUT problems -> decouple with mediator/observer
  If A knows B AND B knows A: Mediator
  If A knows B but not reverse: Observer or Callback
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// Example: Selecting the right pattern from a symptom

// SYMPTOM: Adding new report types requires modifying ReportGenerator
public class ReportGenerator {
    public void generate(String type, Data data) {
        if ("pdf".equals(type)) {
            // 50 lines of PDF generation
        } else if ("excel".equals(type)) {
            // 50 lines of Excel generation
        } else if ("csv".equals(type)) {
            // 50 lines of CSV generation
        }
    }
}
// SOLID violation: OCP (each new type modifies this class)
// What varies? The algorithm (report format algorithm)
// -> Strategy pattern

// SELECTED PATTERN: Strategy
// Structural fit check:
// [x] 3 algorithms exist (PDF, Excel, CSV)
// [x] Interchangeable at runtime (same input/output)
// [x] Common interface possible (ReportStrategy)
// [x] Algorithm choice is separate from business logic
// -> FIT CONFIRMED
```

> **Code walkthrough:** The symptom (if/else on type) maps to an OCP
> violation. OCP violations with algorithm variation map to Strategy.
> The structural fit test confirms: 3 algorithms exist, they are
> interchangeable, a common interface is possible, the choice is
> a separate concern. Strategy is the correct selection.

```java
// SELECTED PATTERN: Strategy - implementation
public interface ReportStrategy {
    byte[] generate(Data data);
}

@Component("pdf")
public class PdfReportStrategy implements ReportStrategy {
    public byte[] generate(Data data) {
        // PDF generation only
        return pdfBytes;
    }
}

@Component("excel")
public class ExcelReportStrategy implements ReportStrategy {
    public byte[] generate(Data data) {
        return excelBytes;
    }
}

@Service
public class ReportService {
    private final Map<String, ReportStrategy> strategies;

    public ReportService(
            Map<String, ReportStrategy> strategies) {
        this.strategies = strategies;
    }

    public byte[] generate(String type, Data data) {
        ReportStrategy strategy = strategies.get(type);
        if (strategy == null)
            throw new IllegalArgumentException(
                "Unknown report type: " + type);
        return strategy.generate(data);
    }
}
// Adding CSV: create CsvReportStrategy @Component("csv")
// ReportService untouched.
```

> **Code walkthrough:** Spring's `Map<String, ReportStrategy>` injection
> collects all `ReportStrategy` beans keyed by their bean name. `ReportService`
> never changes for new report types - it dispatches to the strategy by
> name. Adding a new format: one new class, one `@Component`. This is
> the Open/Closed Principle achieved through Strategy. Contrast: the
> if/else version required modifying `ReportService` for every new type.

```java
// DIFFERENT SYMPTOM: Complex object construction
// SYMPTOM: Constructor with 8 parameters, many null/optional
public class Notification {
    public Notification(
        String userId,
        String message,
        String channel,        // "email" | "sms" | "push"
        boolean urgent,
        LocalDateTime sendAt,  // null = immediate
        String templateId,     // null = no template
        Map<String, String> params,  // null = no params
        String correlationId   // null = auto-generated
    ) { ... }
}
// SOLID violation: SRP (construction complexity in one place)
// What varies? The construction parameters (many optional)
// -> Builder pattern

// SELECTED PATTERN: Builder
// Structural fit check:
// [x] Complex construction (8 params, many optional)
// [x] Multiple valid configurations
// [x] Immutable object wanted after construction
// -> FIT CONFIRMED

// SELECTED PATTERN: Builder - implementation
public class Notification {
    // final fields
    private final String userId;
    private final String message;
    private final String channel;
    private final boolean urgent;
    private final LocalDateTime sendAt;
    private final String templateId;

    private Notification(Builder b) {
        this.userId = Objects.requireNonNull(b.userId);
        this.message = Objects.requireNonNull(b.message);
        this.channel = Objects.requireNonNull(b.channel);
        this.urgent = b.urgent;
        this.sendAt = b.sendAt;      // null = immediate
        this.templateId = b.templateId;
    }

    public static class Builder {
        private final String userId;
        private final String message;
        private String channel = "email";
        private boolean urgent = false;
        private LocalDateTime sendAt;
        private String templateId;

        public Builder(String userId, String message) {
            this.userId = userId;
            this.message = message;
        }
        public Builder channel(String c) {
            this.channel = c; return this;
        }
        public Builder urgent() {
            this.urgent = true; return this;
        }
        public Builder sendAt(LocalDateTime t) {
            this.sendAt = t; return this;
        }
        public Builder template(String id) {
            this.templateId = id; return this;
        }
        public Notification build() {
            return new Notification(this);
        }
    }
}

// Usage: clear, readable, no nulls for optional params
Notification n = new Notification.Builder(userId, msg)
    .channel("sms")
    .urgent()
    .build();
```

> **Code walkthrough:** Builder applied to complex construction.
> Required parameters are in the Builder constructor (guaranteed non-null).
> Optional parameters have defaults or are set via fluent methods.
> The usage site is readable - each method call names the parameter.
> Contrast: `new Notification(userId, msg, "sms", true, null, null, null, null)` -
> 8 positional parameters with 5 nulls. The Builder removes the null
> noise and names each optional value.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> To select a pattern: ask "what changes in my code?" The thing that
> changes points to the pattern. Algorithm changes -> Strategy. Object
> type changes -> Factory. Number of responsibilities -> Facade or
> Command. Construction complexity -> Builder. The GoF categories help:
> Creational (construction), Structural (composition), Behavioral
> (communication). Match your problem's category to the GoF category first,
> then narrow within the category.

---

**Senior / Staff (5+ years):**
> My selection process: SOLID first. Identify which SOLID principle the
> current design violates. OCP violation: Strategy or Observer. SRP
> violation: Command, Facade, or Mediator decomposition. DIP violation:
> Abstract Factory or Builder. Then structural fit test: verify the
> pattern's structural requirements all match the problem. Only then
> implement. This prevents cargo-culting (applying a pattern by name
> without verifying fit).
>
> The meta-skill: patterns are not ends. They are means to better
> SOLID adherence. If applying a pattern does not improve SOLID compliance,
> the pattern is wrong or not needed.

---

### ⚠️ Common Misconceptions

**Misconception 1: The GoF book's pattern-by-intent table is sufficient for pattern selection.**

The GoF intent table helps narrow candidates but the final selection requires understanding the specific forces in your problem: How often will the type hierarchy change vs how often will operations change? (Visitor vs Polymorphism). How many implementations will you realistically have? (Strategy vs single implementation). How important is runtime composability? (Decorator vs inheritance). Pattern selection is a judgment call based on forces, not a lookup table exercise. The table narrows to 3-5 candidates; context determines the winner.

**Misconception 2: Following SOLID principles automatically leads to correct pattern selection.**

SOLID principles guide OOP design quality but do not prescribe specific patterns. Multiple design patterns can satisfy all SOLID principles for the same problem. Open/Closed Principle can be satisfied by Strategy, Decorator, or Template Method depending on whether you want algorithm replacement, behavioral extension, or skeletal implementation. SOLID tells you WHAT properties good designs should have; patterns tell you HOW to achieve those properties for specific recurring problem types.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Wrong pattern selected due to structural similarity rather than intent match.**

Symptom: the code structure appears pattern-like but the pattern fights the requirements; workarounds accumulate to make the chosen pattern fit; code becomes more complex than necessary. Root cause: pattern selected based on structural template ("it has an interface and implementations - that's Strategy") rather than intent match ("is the algorithm being swapped by the client at runtime?"). Diagnosis: articulate the problem the pattern is supposed to solve; verify the problem actually exists. Fix: don't be afraid to replace one pattern with another - extract the core logic, then apply the correct pattern.

**Failure Mode 2: Correct pattern identified but wrong scope of application.**

Symptom: Observer used for events that only have one subscriber (no benefit); Strategy used where there is only one algorithm (adds indirection with no flexibility). Root cause: pattern applied at too small or too large a scope for the actual variability in the system. Diagnosis: identify how many concrete implementations actually exist vs how many are speculative. Fix: validate that the pattern matches real, existing variability; remove abstraction layers that protect against variability that hasn't materialized.

---

### 🎯 Interview Deep-Dive

#### Definition
- "Walk me through how you would select a design pattern for a new requirement."

🗣️ "Four steps. (1) Identify the variation: what changes with each
new requirement? Algorithm, object type, construction, structure, or
communication? (2) Map to SOLID: which principle does the current design
violate? OCP -> Strategy/Factory. SRP -> Facade/Command. DIP -> Abstract
Factory/Builder. (3) Structural fit check: verify the pattern's structural
requirements match your problem. Strategy requires 2+ interchangeable
algorithms with a common interface - confirm all three. (4) Validate:
after applying the pattern, is the violation resolved? Does adding the
next requirement touch only the new class (correct) or still require
modifying existing classes (wrong pattern or wrong application)?"

#### Mechanism
- "How does the GoF organize patterns? Is that organization useful for selection?"

🗣️ "GoF organizes by purpose: Creational (object creation), Structural
(class/object composition), Behavioral (communication). And by scope:
class patterns (use inheritance) vs object patterns (use composition).
The organization is useful as a first filter: if your problem is about
object creation, look at Creational patterns. If it is about object
communication, look at Behavioral. But within a category, 5-10 patterns
exist. The secondary filter (what varies, which SOLID principle is
violated) narrows to 1-2 candidates. The tertiary filter (structural
fit check) confirms. The GoF categories are a starting point, not a
complete selection guide."

#### Scenario
- "An interviewer asks: 'Which pattern would you use for a notification
  system that sends emails, SMS, and push notifications?' Walk through
  your decision."

🗣️ "What varies: the delivery channel (email, SMS, push). OCP violation
incoming: without a pattern, every new channel adds to an if/else chain.
Strategy fits: multiple algorithms (delivery implementations),
interchangeable, common interface (notify(user, message)). Structural
fit: 3 implementations exist, interchangeable at runtime, common
interface possible. Confirm. Now consider: who chooses the channel?
If at runtime by user preference: Strategy with a channel registry.
If multiple channels for one notification: Strategy + Composite (send
to all applicable channels). If channels are added/removed dynamically
with no downtime: Observer-like subscription. The answer reveals
which additional complexity needs solving beyond the basic pattern."

#### Comparison Table

| Selection Method | Speed | Accuracy | Risk |
|---|---|---|---|
| Name-based ("I'll use Strategy") | Fast | Low (cargo-culting) | Wrong fit |
| Category-based (Behavioral first) | Medium | Medium | Multiple candidates |
| SOLID violation mapping | Medium | High | None |
| Structural fit check | Slow | Very high | None |
| All four steps | Slowest | Highest | None |

---

### ⚖️ Comparison Table

| Pattern Category | Selection Signal | Key Structural Requirement |
|---|---|---|
| Strategy | Algorithm varies, OCP violated | 2+ interchangeable implementations |
| Factory Method | Created type varies, DIP violated | 1 creation point, N types |
| Abstract Factory | Family of related objects varies | Products must be compatible |
| Builder | Construction is complex, many optionals | Object immutable after build |
| Observer | Reaction to state change, SRP violated | N observers, 1 subject |
| Decorator | Adding responsibilities to object | Decorators compose recursively |
| Proxy | Controlled access / cross-cutting | Proxy implements same interface |
| Facade | Subsystem too complex, ISP violated | Thin layer, no business logic |
| Mediator | N-to-N coupling, SRP violated | All communication through center |
| Command | Actions need undo/queue/log | Action is encapsulated as object |

---

### 🔥 Field Q&A

**Q: What is cargo-cult programming with design patterns?**

A: Cargo-cult: applying a pattern because it sounds right or because
the team "does things this way" rather than because it solves a specific
problem. Examples: "We use Service classes, Repository classes, and
Factory classes for everything" even when the Factory has one implementation.
"All our business logic is in Strategies" even when it never varies.
The symptom: engineers who can name the pattern but cannot explain the
problem it solves. The diagnosis question: "If I removed this pattern,
what problem would return?" If the answer is "none" or vague: cargo cult.
Prevention: code reviews require naming the problem the pattern solves
in the PR description. If the author cannot name it, the pattern is removed.

**Q: Should every class follow a named pattern?**

A: No. Most application-layer code in Spring Boot should be: plain service
classes (no pattern name needed), plain domain objects (Entities, Value
Objects from DDD, not pattern named), plain repositories. Patterns are
for structural problems: places where variation, coupling, or complexity
requires a structural solution. A `UserRegistrationService` that creates
a user and sends an email does not need a pattern. It is a service class.
Patterns appear at the integration points: where the notification channel
varies (Strategy), where the payment provider varies (Strategy/Factory),
where cross-cutting concerns must be added (Proxy/Decorator). Rule: the
pattern name should appear in your design vocabulary, not in every class
name (no `OrderStrategyFactoryAdapterImpl`).

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



