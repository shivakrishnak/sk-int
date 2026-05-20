---
layout: default
title: "Design Patterns - SOLID"
parent: "Design Patterns"
grand_parent: "Interview Mastery"
nav_order: 4
permalink: /interview/design-patterns/solid/
topic: Design Patterns
subtopic: SOLID
keywords:
  - Single Responsibility Principle (SRP)
  - Open-Closed Principle (OCP)
  - Liskov Substitution Principle (LSP)
  - Interface Segregation Principle (ISP)
  - Dependency Inversion Principle (DIP)
difficulty_range: mixed
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Single Responsibility Principle (SRP)](#single-responsibility-principle-srp)
- [Open-Closed Principle (OCP)](#open-closed-principle-ocp)
- [Liskov Substitution Principle (LSP)](#liskov-substitution-principle-lsp)
- [Interface Segregation Principle (ISP)](#interface-segregation-principle-isp)
- [Dependency Inversion Principle (DIP)](#dependency-inversion-principle-dip)

# Single Responsibility Principle (SRP)

**TL;DR** - A class should have only one reason to change, meaning it should have only one job or responsibility.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your `UserService` class authenticates users, validates input, queries the database, sends welcome emails, generates PDF reports, and logs audit events. A change to the email template requires modifying `UserService`. A change to the database schema requires modifying `UserService`. A change to the report format requires modifying `UserService`. Six different teams modify the same class for six different reasons.

**THE BREAKING POINT:**
A developer changes the email template and accidentally breaks the authentication logic. The test suite catches it, but the code review takes 3 days because the class is 2,000 lines and nobody understands all six responsibilities.

**THE INVENTION MOMENT:**
"This is exactly why SRP was created."

**EVOLUTION:**
Robert C. Martin (Uncle Bob) introduced SRP as the first SOLID principle. The original formulation was "a class should have only one reason to change." Martin later refined it to: "a module should be responsible to one, and only one, actor" - shifting from technical reasons to organizational actors. This refinement matters: the "reason to change" is defined by who requests the change, not by the code's structure.
---

### 📘 Textbook Definition

The Single Responsibility Principle states that a class should have only one reason to change. Each class should encapsulate a single responsibility, where a "responsibility" is defined as a single axis of change driven by one actor (stakeholder or user group).
---

### ⏱️ Understand It in 30 Seconds

**One line:**
One class, one job, one reason to change.

**One analogy:**

> A Swiss Army knife has 20 tools. It's a terrible knife, a terrible screwdriver, and a terrible saw. A chef's knife does one thing brilliantly. SRP says: be a chef's knife, not a Swiss Army knife.

**One insight:**
SRP is not about a class doing "one thing" - it's about having "one reason to change." A `UserRepository` might have 10 CRUD methods, but they all change for the same reason (the user data model changes). That's one responsibility. A `UserService` that does CRUD and sends emails has two: data access and notification. Different teams, different change cycles.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Each class serves one actor (stakeholder group)
2. Changes from different actors should not affect the same class
3. Responsibilities that change together belong together

**THE TRADE-OFFS:**
**Gain:** Smaller classes, easier testing, fewer merge conflicts, changes are isolated
**Cost:** More classes, more files, potential over-fragmentation if taken too far

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Separating concerns requires organizing code into distinct units
**Accidental:** Over-applying SRP (one method per class) creates fragmentation that's harder to understand
---

### 🧠 Mental Model / Analogy

> Think of SRP as departments in a company. Accounting doesn't do marketing. Marketing doesn't do legal. Each department has one domain of expertise. When tax law changes, only accounting adjusts. When ad regulations change, only marketing adjusts. Cross-functional changes (company rebrand) are coordinated, not centralized.

Where this analogy breaks down: Departments communicate through meetings; classes communicate through method calls, which are more rigid.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Each class should do one thing well. Like a toaster just toasts bread - it doesn't also brew coffee.

**Level 2 - How to use it (junior developer):**
If your class does X and Y, and X might change without Y changing, separate them. `UserService` -> `UserRepository` (data access) + `EmailService` (notifications) + `AuditLogger` (logging).

**Level 3 - How it works (mid-level engineer):**
The test for SRP: identify the actors. Who requests changes to this class? If the answer is "the database team AND the marketing team AND the security team," the class has too many responsibilities. Each actor gets their own class. In Spring, this naturally maps to the layered architecture: Controller (handles HTTP) -> Service (business logic) -> Repository (data access) -> each with one responsibility.

**Level 4 - Mastery (senior/staff+ engineer):**
SRP at the macro level is the single most important factor in maintainable codebases. It applies not just to classes but to modules, services, and teams. In microservices, SRP means each service owns one business capability. The anti-pattern: a "user service" that handles authentication, profiles, preferences, and notifications. The fix: auth service, profile service, notification service. The judgment call: SRP is a spectrum. Too few responsibilities per class = God objects. Too many = class explosion. The right granularity matches your team's change frequency.




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

### 💻 Code Example

**BAD: Multiple responsibilities**

```java
// BAD: Three reasons to change
public class Employee {
    // Responsibility 1: Business logic
    public BigDecimal calculatePay() { /*...*/ }

    // Responsibility 2: Persistence
    public void save() {
        db.execute("INSERT INTO employees...");
    }

    // Responsibility 3: Reporting
    public String generateReport() {
        return String.format("Name: %s, Pay: %s",
            name, calculatePay());
    }
}
```

**GOOD: Single responsibility each**

```java
// GOOD: Each class has one reason to change
public class Employee {
    private String name;
    private BigDecimal basePay;
    // Only domain logic
    public BigDecimal calculatePay() {
        return basePay.multiply(hoursWorked);
    }
}

public class EmployeeRepository {
    // Only persistence
    public void save(Employee e) {
        db.execute("INSERT INTO employees...");
    }
}

public class EmployeeReportGenerator {
    // Only reporting
    public String generate(Employee e) {
        return String.format("Name: %s, Pay: %s",
            e.getName(), e.calculatePay());
    }
}
```
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

1. SRP means one reason to change, not one method - a class with 10 CRUD methods can still be SRP-compliant
2. "Reason to change" is defined by actors (stakeholders), not code structure
3. Spring's Controller/Service/Repository layers are SRP applied to web applications

**Interview one-liner:**
"SRP says a class should have one reason to change - I apply it by identifying which actor requests changes and ensuring each class serves exactly one actor, which naturally leads to the controller-service-repository pattern."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Uncle Bob refined SRP years after introducing it. The original "one reason to change" was ambiguous - one developer's "reason" is another's "detail." The refined definition is "responsible to one actor." This means: if the CFO wants the payroll calculation changed and the CTO wants the database schema changed, those are different actors and different responsibilities - even if both currently live in the same class. SRP is about organizational boundaries, not code structure.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Single Responsibility Principle (SRP). Otherwise remove this section.]
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

**Q1: How do you know when a class violates SRP? What's the practical test?**

_Why they ask:_ Tests whether you apply SRP mechanically or with judgment.

**Answer:**
Three practical tests:

1. **The actor test:** List who would request changes to this class. If more than one stakeholder group, it violates SRP. "Who would ask us to change this class?" If the answer is "the accounting team OR the IT team," split it.

2. **The description test:** Describe what the class does in one sentence without using "and" or "or." If you can't, it has multiple responsibilities. "This class manages user authentication" - fine. "This class manages user authentication and sends email notifications" - violation.

3. **The change frequency test:** If methods in the same class change for different reasons at different times, they're different responsibilities. If `calculatePay()` changed last month for a tax update and `generateReport()` changed this week for a formatting request - different responsibilities.

---

**Q2: Can SRP be taken too far? Give an example.**

_Why they ask:_ Tests judgment about principle application.

**Answer:**
Absolutely. Over-applying SRP creates "ravioli code" - hundreds of tiny classes that are individually simple but collectively incomprehensible.

Example of SRP taken too far:

```
UserNameValidator.java
UserEmailValidator.java
UserPasswordValidator.java
UserAgeValidator.java
UserAddressValidator.java
UserValidationOrchestrator.java
```

All six classes change when user validation rules change (same actor). A single `UserValidator` with multiple methods is better. The separate-class approach adds 6 files, 6 constructor injections, and 6 test files for something that's logically one concern.

My rule: if two classes always change together, they should be one class. SRP is about isolating independent change axes, not maximizing class count.
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

# Open-Closed Principle (OCP)

**TL;DR** - Software entities should be open for extension but closed for modification - add new behavior without changing existing code.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your payment system processes credit cards. A new requirement: support PayPal. You modify the `PaymentProcessor` class, adding PayPal logic. Then Apple Pay. Then crypto. Each addition modifies the same class, risking regression in existing payment methods. Every deployment is a full regression test of all payment methods.

**THE BREAKING POINT:**
A bug fix for crypto payments accidentally changes the credit card flow. The credit card processing fails in production for 2 hours before detection.

**THE INVENTION MOMENT:**
"This is exactly why OCP was created."

**EVOLUTION:**
Bertrand Meyer introduced OCP in 1988, originally through inheritance. Robert C. Martin adapted it for SOLID using polymorphism and abstraction. Modern OCP is primarily achieved through Strategy pattern, plugin architectures, and dependency injection. Spring's component scanning is OCP in action: new beans are added without modifying existing configuration.
---

### 📘 Textbook Definition

The Open-Closed Principle states that software entities (classes, modules, functions) should be open for extension but closed for modification. You should be able to add new behavior without changing existing, working code.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Add new features by writing new code, not changing old code.

**One analogy:**

> A power strip. When you need a new appliance, you plug it in. You don't rewire the electrical panel. The power strip is closed for modification (you don't change its internals) but open for extension (you plug in new devices).

**One insight:**
OCP doesn't mean you never modify code. It means the most common change scenario (adding a new variant) should not require modifying existing code. The setup: define an abstraction. New variants implement it. Existing code uses the abstraction, not the implementation. Strategy pattern is OCP's poster child.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Abstractions are the extension point
2. Existing code depends on abstractions, not implementations
3. New implementations are added without touching existing code

**THE TRADE-OFFS:**
**Gain:** Existing code is never at risk from new features, each implementation is independently testable
**Cost:** Requires upfront abstraction design, over-abstracting for unlikely extension points wastes effort

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Supporting extension without modification requires some abstraction mechanism
**Accidental:** Creating interfaces for every class "just in case" is premature abstraction - only abstract where you've seen or anticipate multiple implementations
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
Add a new feature by plugging in a new piece, not by rewriting what already works.

**Level 2 - How to use it (junior developer):**
Extract an interface. Existing code programs to the interface. New features = new implementation classes. `PaymentProcessor` depends on `PaymentMethod` interface. Adding Apple Pay = new `ApplePayMethod implements PaymentMethod`. `PaymentProcessor` is unchanged.

**Level 3 - How it works (mid-level engineer):**
OCP is achieved through: (1) Strategy pattern - new algorithm = new strategy class. (2) Plugin architecture - new functionality = new plugin JAR. (3) Spring auto-discovery - new `@Component` implementing an interface is automatically picked up. The key: identify the axis of change. What's the most likely new requirement? Abstract that axis.

**Level 4 - Mastery (senior/staff+ engineer):**
OCP is the most misapplied SOLID principle. Over-eager OCP creates "speculative generality" - abstractions for extension points that never materialize. The pragmatic approach: don't abstract preemptively. When the second implementation appears, refactor to OCP. When the third appears, you're glad you did. In large codebases, OCP's real value is organizational: team A can add features without team B's code review or risk. In microservices, OCP maps to the "open for extension" nature of event-driven architectures: new consumers can subscribe to existing events without modifying producers.




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

### 💻 Code Example

**BAD: Modifying existing code for each new type**

```java
// BAD: Adding a shape requires modifying this
public double area(Object shape) {
    if (shape instanceof Circle c) {
        return Math.PI * c.radius() * c.radius();
    } else if (shape instanceof Rectangle r) {
        return r.width() * r.height();
    }
    // Adding Triangle = modifying this method
    throw new IllegalArgumentException();
}
```

**GOOD: Open for extension**

```java
// GOOD: New shapes don't change existing code
public interface Shape {
    double area();
}
public record Circle(double radius) implements Shape {
    public double area() {
        return Math.PI * radius * radius;
    }
}
public record Rectangle(double w, double h)
        implements Shape {
    public double area() { return w * h; }
}
// Adding Triangle = new class, zero changes above
public record Triangle(double base, double height)
        implements Shape {
    public double area() { return 0.5 * base * height; }
}
```
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

1. New features should be new code (new classes), not modified code (existing classes)
2. Strategy pattern is OCP's primary implementation mechanism
3. Don't abstract speculatively - apply OCP when the second implementation appears

**Interview one-liner:**
"OCP says extend behavior by adding new implementations of an abstraction rather than modifying existing code - I apply it through Strategy pattern and Spring's auto-discovered beans so new payment methods, validators, or handlers are just new @Component classes."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

The `if/else` chain that OCP eliminates is often faster than polymorphic dispatch. JVM branch prediction on `instanceof` checks can outperform virtual method table lookups in hot paths. Performance-critical code (game engines, HFT systems) sometimes deliberately violates OCP with switch statements for speed. The lesson: OCP is a maintainability principle, not a performance principle. Apply it where change is frequent, not where nanoseconds matter.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Open-Closed Principle (OCP). Otherwise remove this section.]
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

**Q1: How do you apply OCP without creating premature abstractions?**

_Why they ask:_ Tests pragmatic judgment.

**Answer:**
The "Rule of Three":

1. First implementation: write it concretely
2. Second implementation: consider abstracting (but it's OK not to yet)
3. Third implementation: refactor to OCP - the pattern is clear

Premature OCP creates: interfaces with one implementation, factories that return one type, plugins with one plugin. These are overhead with no benefit.

Signs you need OCP now: (1) you've modified the same switch/if-else 3+ times, (2) different teams add different cases to the same class, (3) the modification risk is higher than the abstraction cost.
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

# Liskov Substitution Principle (LSP)

**TL;DR** - Subtypes must be substitutable for their base types without altering the correctness of the program.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You have a `Rectangle` class with `setWidth()` and `setHeight()`. `Square extends Rectangle`. But a square must keep width and height equal, so `Square.setWidth()` also sets height. Code that expects a `Rectangle` calls `setWidth(5); setHeight(10); assert area() == 50;`. With a `Square`, the area is 100. The subclass breaks the parent's contract.

**THE BREAKING POINT:**
A `List<Rectangle>` contains some `Square` instances. A method iterates and resizes rectangles independently. All squares are distorted because the width/height coupling violates the client's expectations.

**THE INVENTION MOMENT:**
"This is exactly why LSP was created."

**EVOLUTION:**
Barbara Liskov defined the principle in 1987. It formalizes what "is-a" really means in inheritance. A `Square` "is-a" `Rectangle` geometrically, but not behaviorally (they have different constraints on mutation). Java's `Collections.unmodifiableList()` returns a `List` that throws on `add()` - technically an LSP violation, but pragmatically accepted with documentation. Modern approaches: use composition, sealed interfaces, and value objects to avoid LSP problems entirely.
---

### 📘 Textbook Definition

The Liskov Substitution Principle states that objects of a superclass should be replaceable with objects of a subclass without affecting the correctness of the program. Subtypes must honor the behavioral contract of their supertypes: preconditions cannot be strengthened, postconditions cannot be weakened, and invariants must be preserved.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Subclasses must work anywhere the parent class works without surprises.

**One analogy:**

> A universal remote control works with any TV brand. If Samsung's TV responds to "Volume Up" by changing the channel instead, the remote is useless. Every TV must honor the contract: "Volume Up" means volume increases.

**One insight:**
LSP is not about inheritance syntax - it's about behavioral contracts. If a method accepts `Bird` and calls `bird.fly()`, passing a `Penguin extends Bird` that throws `CannotFlyException` violates LSP. The fix isn't making penguins fly - it's fixing the type hierarchy. `Penguin` should not extend `FlyingBird`. Inheritance models behavior, not taxonomy.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Preconditions cannot be strengthened (subclass can't demand more)
2. Postconditions cannot be weakened (subclass can't promise less)
3. Invariants of the supertype must be preserved

**THE TRADE-OFFS:**
**Gain:** Polymorphism works safely, code using base types is reliable
**Cost:** Constrains inheritance design, sometimes forces composition over inheritance
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
If you promise something works a certain way, every version of it must work that way. A substitute teacher must still teach the class, not show movies all day.

**Level 2 - How to use it (junior developer):**
Before creating a subclass, ask: "Can I use this subclass everywhere the parent is used without the caller noticing?" If `setWidth()` on a `Square` has unexpected side effects, the answer is no - don't inherit.

**Level 3 - How it works (mid-level engineer):**
LSP violations manifest as: (1) subclass methods throwing exceptions the parent doesn't, (2) subclass methods ignoring parameters (no-op overrides), (3) subclass methods having different side effects. Java's `Stack extends Vector` is a classic violation: `Stack` inherits `add(index, element)`, which lets you insert at any position - violating stack semantics. The fix: composition (`Stack` holds a `List`, not extends it).

**Level 4 - Mastery (senior/staff+ engineer):**
LSP is the formal statement of "design by contract." In practice, I use LSP as a code review check: for every method override, verify the three rules (preconditions, postconditions, invariants). Modern Java features help: `sealed` interfaces limit who can subtype, reducing the surface area for LSP violations. `record` classes are immutable, eliminating the Square/Rectangle mutation problem entirely. The ultimate LSP strategy: prefer composition over inheritance, and use inheritance only for genuine behavioral subtypes, not taxonomic classifications.




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

### 💻 Code Example

**BAD: LSP violation**

```java
// BAD: Square violates Rectangle's contract
public class Rectangle {
    protected int width, height;
    public void setWidth(int w) { width = w; }
    public void setHeight(int h) { height = h; }
    public int area() { return width * height; }
}

public class Square extends Rectangle {
    @Override
    public void setWidth(int w) {
        width = w;
        height = w; // Surprise side effect!
    }
    @Override
    public void setHeight(int h) {
        width = h;
        height = h; // Surprise side effect!
    }
}

// Client code breaks with Square
void resize(Rectangle r) {
    r.setWidth(5);
    r.setHeight(10);
    assert r.area() == 50; // Fails for Square!
}
```

**GOOD: Separate types, no violation**

```java
// GOOD: No inheritance, no violation
public interface Shape {
    int area();
}

public record Rectangle(int width, int height)
        implements Shape {
    public int area() { return width * height; }
}

public record Square(int side) implements Shape {
    public int area() { return side * side; }
}
```
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

1. Subclasses must honor the parent's behavioral contract - not just the type signature
2. Classic violations: Square/Rectangle, Penguin/Bird, Stack/Vector
3. Fix: composition over inheritance, or redesign the type hierarchy

**Interview one-liner:**
"LSP says subtypes must be substitutable for their base types without breaking correctness - I verify this by checking that overridden methods don't strengthen preconditions, weaken postconditions, or violate invariants, and I prefer composition over inheritance to avoid violations entirely."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Java's `Collections.unmodifiableList()` returns a `List` that throws `UnsupportedOperationException` on `add()`. This is technically an LSP violation - callers expecting `List` semantics get an exception. The Java designers accepted this pragmatic compromise because the alternative (separate `ReadOnlyList` interface) would split the entire collection ecosystem. Sometimes a documented LSP violation is better than a perfect type hierarchy.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Liskov Substitution Principle (LSP). Otherwise remove this section.]
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

**Q1: Give three LSP violations in the Java standard library.**

_Why they ask:_ Tests deep knowledge of real-world trade-offs.

**Answer:**

1. **`Stack extends Vector`:** Stack inherits `add(index, element)` which allows inserting at any position. Real stacks only support push/pop. You can insert at the bottom of a Java Stack.

2. **`Properties extends Hashtable`:** `Properties` is for String key-value pairs, but inheriting from `Hashtable<Object, Object>` allows `properties.put(42, new Date())`. Non-string entries corrupt the properties file when saved.

3. **`Collections.unmodifiableList()`:** Returns a `List` that throws on `add()`, `remove()`, `set()`. The `List` contract implies mutability; the returned list violates that contract.

All three exist because the Java designers prioritized reuse over correctness. Today, composition would be preferred: `Stack` would hold a `Deque`, `Properties` would hold a `Map<String,String>`, and `UnmodifiableList` would be a separate type.
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

# Interface Segregation Principle (ISP)

**TL;DR** - Clients should not be forced to depend on interfaces they don't use - split fat interfaces into smaller, focused ones.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your `Worker` interface has methods: `work()`, `eat()`, `sleep()`. A `HumanWorker` implements all three naturally. A `RobotWorker` must implement `eat()` and `sleep()` as no-ops or throw exceptions. The robot is forced to depend on methods it doesn't need.

**THE BREAKING POINT:**
The interface gets 15 methods. Every new implementation must implement all 15, even if it uses only 3. Mock objects in tests require stubbing all 15. Changing one unrelated method forces recompilation of all implementations.

**THE INVENTION MOMENT:**
"This is exactly why ISP was created."

**EVOLUTION:**
Uncle Bob introduced ISP as part of SOLID. It's related to SRP but applied to interfaces. Java 8's default methods partially address ISP by providing default implementations, but they don't solve the dependency problem. Modern approach: small, focused interfaces composed by implementors. Spring's `@Repository`, `@Service`, `@Controller` annotations implicitly follow ISP - each interface serves one client role.
---

### 📘 Textbook Definition

The Interface Segregation Principle states that no client should be forced to depend on methods it does not use. Large interfaces should be split into smaller, more specific ones so that clients only know about the methods they need.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Many small interfaces are better than one large interface.

**One analogy:**

> A restaurant menu with separate sections: appetizers, mains, desserts, drinks. A vegetarian only looks at the vegetarian section. They're not forced to read the entire 20-page menu. Each section is a "segregated interface" for its audience.

**One insight:**
ISP is about coupling. A client that depends on 15 methods is coupled to 15 change axes. If it only uses 3, the other 12 are false dependencies. Any change to those 12 methods forces recompilation/retesting of the client even though its behavior hasn't changed. Smaller interfaces = fewer false dependencies.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Interfaces should be client-specific, not implementation-specific
2. A class can implement multiple small interfaces
3. Clients depend only on the methods they actually call

**THE TRADE-OFFS:**
**Gain:** Reduced coupling, easier mocking, fewer unnecessary recompilations
**Cost:** More interfaces to manage, risk of over-splitting into single-method interfaces
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
Don't force people to carry a toolbox when they need one screwdriver. Give them just the screwdriver.

**Level 2 - How to use it (junior developer):**
If a class implements an interface and leaves some methods as empty/throwing, the interface is too fat. Split it. `Worker` -> `Workable` (has `work()`) + `Feedable` (has `eat()`) + `Sleepable` (has `sleep()`). `RobotWorker implements Workable` - no empty methods.

**Level 3 - How it works (mid-level engineer):**
ISP aligns with the Dependency Inversion Principle: clients define the interfaces they need. A `PaymentService` doesn't need the full `CustomerRepository` (20 methods). It needs `CustomerEmailLookup` (1 method). Define the small interface in the client's package, have the repository implement it. The client's compile scope shrinks from 20 methods to 1.

**Level 4 - Mastery (senior/staff+ engineer):**
ISP's deepest impact is on compile-time dependencies and deployment. In a monolithic codebase with fat interfaces, changing one method recompiles everything that depends on the interface. With segregated interfaces, only the clients of that specific interface recompile. In microservices, ISP maps to API contracts: don't give every consumer the same API. BFF (Backend for Frontend) is ISP at the service level - mobile gets a different interface than web.




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

### 💻 Code Example

**BAD: Fat interface**

```java
// BAD: Printer doesn't scan or fax
public interface MultiFunctionDevice {
    void print(Document d);
    void scan(Document d);
    void fax(Document d);
    void staple(Document d);
}

public class SimplePrinter
        implements MultiFunctionDevice {
    public void print(Document d) { /* works */ }
    public void scan(Document d) {
        throw new UnsupportedOperationException();
    }
    public void fax(Document d) {
        throw new UnsupportedOperationException();
    }
    public void staple(Document d) {
        throw new UnsupportedOperationException();
    }
}
```

**GOOD: Segregated interfaces**

```java
// GOOD: Each client depends on what it needs
public interface Printer {
    void print(Document d);
}
public interface Scanner {
    void scan(Document d);
}
public interface Fax {
    void fax(Document d);
}

// Simple printer - only implements what it can do
public class SimplePrinter implements Printer {
    public void print(Document d) { /* works */ }
}

// Multi-function device implements all
public class OfficeMachine
        implements Printer, Scanner, Fax {
    public void print(Document d) { /* works */ }
    public void scan(Document d) { /* works */ }
    public void fax(Document d) { /* works */ }
}

// Client depends on minimal interface
public class PrintService {
    private final Printer printer; // Not MFD
    public PrintService(Printer p) {
        this.printer = p;
    }
}
```
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

1. Fat interfaces force clients to depend on methods they don't use
2. Split by client need, not by implementation convenience
3. Java's `Iterable`, `Comparable`, `Serializable` are examples of well-segregated single-purpose interfaces

**Interview one-liner:**
"ISP says clients shouldn't depend on interfaces they don't use - I split fat interfaces into focused ones so each client depends only on the methods it calls, reducing coupling and making tests simpler."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Java 8's functional interfaces (`Predicate`, `Function`, `Consumer`, `Supplier`) are ISP taken to the extreme - each has exactly one method. This is why lambdas work: a lambda can implement any single-method interface. ISP and functional programming converge at the same endpoint: small, composable contracts. The difference between a "well-segregated interface" and a "functional interface" is just the degree of segregation.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Interface Segregation Principle (ISP). Otherwise remove this section.]
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

**Q1: How does ISP relate to microservice API design?**

_Why they ask:_ Tests ability to apply class-level principles at system level.

**Answer:**
ISP at the microservice level means: don't expose a single REST API to all consumers. Different consumers need different data.

- **Mobile app:** needs minimal payload (bandwidth matters)
- **Web dashboard:** needs rich data with aggregations
- **Partner API:** needs stable contract, different schema

Solution: BFF pattern (Backend for Frontend). Each consumer gets a tailored API. The internal service stays rich, but the interface is segregated by consumer type.

This is ISP: the "fat interface" is the monolithic REST API. The "segregated interfaces" are consumer-specific BFFs. Each client depends only on the data it actually uses, reducing coupling and allowing independent evolution.
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

# Dependency Inversion Principle (DIP)

**TL;DR** - High-level modules should not depend on low-level modules; both should depend on abstractions. Abstractions should not depend on details.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your `OrderService` directly instantiates `MySQLOrderRepository`. To switch to PostgreSQL, you modify `OrderService`. To test without a database, you can't - the `new MySQLOrderRepository()` call is hardcoded. The business logic is welded to the infrastructure.

**THE BREAKING POINT:**
You need to add Redis caching. Without DIP, `OrderService` now depends on `MySQLOrderRepository` AND `RedisCache`. Every infrastructure change ripples into business logic. Tests require a running MySQL and Redis instance.

**THE INVENTION MOMENT:**
"This is exactly why DIP was created."

**EVOLUTION:**
Uncle Bob introduced DIP as the "D" in SOLID. It's the theoretical foundation for dependency injection (DI), which is the implementation mechanism. Spring Framework is built on DIP: business logic depends on interfaces, Spring injects the implementations. DIP also drives hexagonal architecture (ports & adapters): the domain defines the ports (interfaces), adapters implement them.
---

### 📘 Textbook Definition

The Dependency Inversion Principle states: (1) High-level modules should not depend on low-level modules. Both should depend on abstractions. (2) Abstractions should not depend on details. Details should depend on abstractions. The direction of dependency is inverted: instead of high-level depending on low-level, both depend on a shared abstraction.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Depend on abstractions, not implementations.

**One analogy:**

> An electrical outlet. Your laptop doesn't care if the power comes from coal, solar, or nuclear. It depends on the outlet specification (abstraction), not the power plant (implementation). The outlet interface is defined by the consumer, not the producer.

**One insight:**
The word "inversion" is key. Normally, `OrderService` (high-level) depends on `MySQLRepository` (low-level). DIP inverts this: `OrderService` depends on `OrderRepository` (abstraction), and `MySQLRepository` implements `OrderRepository`. The dependency arrow flips. The high-level module defines the contract; the low-level module conforms to it.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. High-level modules define the abstractions they need
2. Low-level modules implement those abstractions
3. The dependency points toward the abstraction, not the implementation

**THE TRADE-OFFS:**
**Gain:** Swappable implementations, testable business logic, infrastructure independence
**Cost:** Indirection, requires DI framework or manual wiring, over-abstraction risk

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Decoupling business logic from infrastructure requires some abstraction boundary
**Accidental:** Creating interfaces for classes that will never have a second implementation
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
Don't hardcode dependencies. Use interchangeable parts. Like a USB port that works with any USB device - you don't build the device into the computer.

**Level 2 - How to use it (junior developer):**
Define an interface for the dependency. Code to the interface. Let Spring (or any DI framework) inject the implementation. `OrderService` constructor takes `OrderRepository repository` (interface), not `MySQLOrderRepository` (concrete class).

**Level 3 - How it works (mid-level engineer):**
DIP has two halves: (1) Depend on abstractions - use interfaces. (2) Abstractions don't depend on details - the interface is defined by the consumer (high-level), not the provider (low-level). In hexagonal architecture, the domain layer defines `port` interfaces. The infrastructure layer provides `adapter` implementations. The domain never imports infrastructure packages - the dependency arrow points inward.

**Level 4 - Mastery (senior/staff+ engineer):**
DIP is the architectural principle that enables clean architecture, hexagonal architecture, and microservice independence. It's not just about classes - it applies to modules, services, and teams. In a microservice, the domain service defines the events it publishes (abstraction). Consumers subscribe to those events. The producer doesn't know about consumers. At the module level, DIP through interfaces enables parallel team development: team A builds the domain, team B builds the infrastructure, both agree on the interface contract. The pragmatic limit: don't apply DIP to stable, unlikely-to-change dependencies. `String`, `List`, `BigDecimal` are low-level details you should depend on directly - abstracting them adds no value.




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

### 💻 Code Example

**BAD: High-level depends on low-level**

```java
// BAD: Business logic coupled to MySQL
public class OrderService {
    private final MySQLOrderRepository repo;

    public OrderService() {
        // Hardcoded dependency - can't swap or test
        this.repo = new MySQLOrderRepository();
    }

    public Order getOrder(String id) {
        return repo.findById(id);
    }
}
```

**GOOD: Both depend on abstraction**

```java
// GOOD: Abstraction defined by high-level module
public interface OrderRepository {
    Order findById(String id);
    void save(Order order);
}

@Service
public class OrderService {
    private final OrderRepository repo;

    // Spring injects the implementation
    public OrderService(OrderRepository repo) {
        this.repo = repo;
    }

    public Order getOrder(String id) {
        return repo.findById(id);
    }
}

// Low-level module implements the abstraction
@Repository
public class MySQLOrderRepository
        implements OrderRepository {
    public Order findById(String id) { /*...*/ }
    public void save(Order order) { /*...*/ }
}

// Test with fake - no database needed
class OrderServiceTest {
    @Test
    void testGetOrder() {
        var fakeRepo = new InMemoryOrderRepository();
        fakeRepo.save(new Order("1", items));
        var service = new OrderService(fakeRepo);
        assertEquals("1",
            service.getOrder("1").getId());
    }
}
```
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

1. "Inversion" means the high-level module defines the interface, low-level implements it
2. Spring's entire DI container is DIP in action - `@Autowired` injects abstractions
3. Don't abstract stable dependencies (String, List) - only abstract volatile ones (database, external API)

**Interview one-liner:**
"DIP inverts the dependency direction: high-level modules define interfaces that low-level modules implement, which is the foundation of Spring's dependency injection - I apply it at every boundary between business logic and infrastructure."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

DIP is often confused with dependency injection (DI), but they're different concepts. DIP is the principle: depend on abstractions. DI is the mechanism: a framework injects the implementation. You can follow DIP without DI (manually wire implementations). You can use DI without DIP (inject concrete classes). The principle is about direction of dependency; the framework is about object construction. Understanding this distinction separates developers who follow SOLID by principle from those who follow it by tooling.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Dependency Inversion Principle (DIP). Otherwise remove this section.]
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

**Q1: DIP vs DI vs IoC - what's the difference?**

_Why they ask:_ Tests precise understanding of related but distinct concepts.

**Answer:**
| Concept | What it is | Level |
| ------- | ---------- | ----- |
| **DIP** | Principle: depend on abstractions | Design principle |
| **IoC** | Principle: framework calls you, not the other way | Control flow |
| **DI** | Technique: framework injects dependencies | Implementation mechanism |

DIP tells you to depend on interfaces. IoC tells you to let the framework control the lifecycle. DI is one way to implement both: the framework creates objects and injects their dependencies.

You can have DI without DIP: `@Autowired MySQLRepository repo` is injected but still depends on a concrete class.
You can have DIP without DI: manually create `new OrderService(new MySQLOrderRepository())` with interface types.
You can have IoC without DI: Template Method is IoC (framework calls your override) without injection.

In Spring, all three work together: DIP (interface dependencies), IoC (Spring manages bean lifecycle), DI (Spring injects implementations).

---

**Q2: How does DIP apply to microservice architecture?**

_Why they ask:_ Tests ability to scale principles beyond class design.

**Answer:**
DIP at the service level means services communicate through contracts (abstractions), not direct knowledge of each other.

1. **Event-driven architecture:** Service A publishes `OrderCreated` event (abstraction). Service B subscribes to it. Neither knows about the other. The event schema is the abstraction both depend on.

2. **API contracts:** Service A defines a REST API (OpenAPI spec). Service B calls it. The spec is the abstraction. Either service can be reimplemented without affecting the other.

3. **Consumer-driven contracts:** The consuming service defines the contract it needs (DIP: high-level defines the abstraction). The provider confirms it can satisfy that contract. This is pure DIP at the system level.

The anti-pattern: Service A directly calls Service B's internal API, coupled to B's database schema. Change B's schema -> A breaks. DIP says: define an interface (API contract) that both depend on.
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
