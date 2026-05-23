---
layout: default
title: "Design Patterns - Anti-Patterns"
parent: "Design Patterns"
grand_parent: "Interview Mastery"
nav_order: 5
permalink: /interview/design-patterns/anti-patterns/
topic: Design Patterns
subtopic: Anti-Patterns
keywords:
  - God Object
  - Spaghetti Code
  - Premature Optimization
  - Circular Dependencies
  - Feature Envy
difficulty_range: mixed
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [God Object](#god-object)
- [Spaghetti Code](#spaghetti-code)
- [Premature Optimization](#premature-optimization)
- [Circular Dependencies](#circular-dependencies)
- [Feature Envy](#feature-envy)

# God Object

**TL;DR** - A God Object is a class that knows too much or does too much, centralizing responsibility that should be distributed across multiple classes.
---

### The Problem This Creates

**HOW IT STARTS:**
A developer creates an `Application` class. It handles user authentication, processes orders, manages inventory, generates reports, and sends notifications. "It's convenient - everything's in one place!" The class works fine with 200 lines.

**HOW IT GROWS:**
Six months later, `Application` is 5,000 lines with 120 methods. Every feature touches this class. Three developers can't work simultaneously because they're all modifying the same file. A change to the notification format breaks the order processing. The class is untestable because setting up the test requires initializing authentication, database, email, and 15 other systems.

**WHY IT PERSISTS:**
Refactoring a 5,000-line class is risky. "We'll fix it later" becomes permanent. New developers add to it because "that's where things go." It becomes the class equivalent of a junk drawer.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why God Object was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

A God Object (or God Class) is an anti-pattern where a single class has too many responsibilities, knows too much about other parts of the system, or controls too much of the application's logic. It violates SRP, makes testing difficult, creates merge conflicts, and becomes a bottleneck for team productivity.
---

### How to Recognize It

**Warning signs:**

- Class has 500+ lines or 30+ methods
- Class name contains "Manager," "Handler," "Processor," "Utility," or "Helper" (too generic)
- Class imports from 10+ different packages
- Multiple developers modify the same class frequently
- Test setup requires initializing many unrelated systems
- You can't describe the class's purpose in one sentence without "and"

**Real examples:**

- `ApplicationController` that handles all HTTP endpoints
- `OrderManager` that validates, processes, ships, invoices, and emails
- `Utils` class with 80 static methods covering strings, dates, IO, and HTTP
---

### How to Fix It

**Strategy: Extract by responsibility**

```java
// BAD: God Object
public class OrderManager {
    public void validate(Order o) { /*...*/ }
    public void save(Order o) { /*...*/ }
    public void sendEmail(Order o) { /*...*/ }
    public void generateInvoice(Order o) { /*...*/ }
    public void updateInventory(Order o) { /*...*/ }
    public BigDecimal calculateTax(Order o) { /*...*/ }
    public void processRefund(Order o) { /*...*/ }
    // ... 50 more methods
}

// GOOD: Responsibilities distributed
public class OrderValidator { /*...*/ }
public class OrderRepository { /*...*/ }
public class OrderNotificationService { /*...*/ }
public class InvoiceGenerator { /*...*/ }
public class InventoryService { /*...*/ }
public class TaxCalculator { /*...*/ }
public class RefundService { /*...*/ }

// Thin orchestrator - delegates, doesn't do
@Service
public class OrderService {
    private final OrderValidator validator;
    private final OrderRepository repo;
    private final OrderNotificationService notifier;

    public OrderResult processOrder(Order order) {
        validator.validate(order);
        Order saved = repo.save(order);
        notifier.notifyOrderCreated(saved);
        return OrderResult.success(saved);
    }
}
```

**Refactoring steps:**

1. Identify responsibility clusters (methods that share state/imports)
2. Extract each cluster into a focused class
3. Create a thin orchestrator that delegates
4. Move tests to follow the new structure
5. Do it incrementally - one responsibility per PR
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
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
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

1. God Object = one class with too many responsibilities, violating SRP
2. Signs: 500+ lines, generic name, many imports, frequent merge conflicts
3. Fix: extract responsibilities into focused classes, keep a thin orchestrator

**Interview one-liner:**
"God Object centralizes too many responsibilities in one class - I fix it by extracting cohesive responsibility clusters into focused classes with a thin orchestrating service."
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

[TODO: Include if 2+ named alternatives exist for God Object. Otherwise remove this section.]
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

**Q1: You inherit a 3,000-line God Object in production. How do you refactor it safely?**

_Why they ask:_ Tests practical refactoring skills under real constraints.

**Answer:**

1. **Write characterization tests first:** Before any refactoring, write tests that capture the current behavior. These tests protect against regression during refactoring.

2. **Identify seams:** Find natural boundaries in the class - groups of methods that share instance variables or imports. These are candidate extraction points.

3. **Extract one responsibility at a time:** Start with the most independent cluster (fewest dependencies on the God Object's internal state). Extract into a new class. Run all tests.

4. **Use the Strangler Fig pattern:** Don't rewrite the God Object. Gradually route new code through the extracted classes. Old code still uses the God Object. Over time, the God Object shrinks until it's just a thin delegate.

5. **Set a class size budget:** Enforce a team rule: no class over 300 lines in new code. Existing God Objects get a "debt ceiling" that only goes down, never up.

The key: never refactor the entire God Object in one PR. Ship incremental extractions, each with its own tests. It took months to create the God Object; it'll take weeks to decompose it safely.
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

# Spaghetti Code

**TL;DR** - Spaghetti Code is unstructured, tangled code with no clear organization, where control flow jumps unpredictably and changes in one place break things in distant, unrelated places.
---

### The Problem This Creates

**HOW IT STARTS:**
A quick prototype is written under deadline pressure. "We'll clean it up later." Methods call other methods across modules with no clear hierarchy. Shared mutable state is accessed from everywhere. Copy-paste duplication creates subtle variations of the same logic.

**HOW IT GROWS:**
Bug fixes add more conditional branches. Each `if` statement adds a new path. Exception handling is inconsistent - some methods swallow exceptions, others rethrow, others log and continue. A single user action triggers a call chain that bounces through 15 classes with no discernible pattern.

**WHY IT PERSISTS:**
Nobody understands the full flow well enough to refactor safely. The code "works" - customers use it daily. Refactoring means re-testing everything, which takes weeks. New features are faster to add by following the existing chaotic patterns than by restructuring.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Spaghetti Code was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

Spaghetti Code is an anti-pattern characterized by unstructured, intertwined, and convoluted code that is difficult to follow, understand, or maintain. It typically lacks clear separation of concerns, has excessive coupling between components, and features control flow that is difficult to trace.
---

### How to Recognize It

**Warning signs:**

- You can't trace the execution path without a debugger
- Methods are 100+ lines with deeply nested if/else/try blocks
- Circular dependencies between classes/modules
- Changing one method breaks 5 seemingly unrelated features
- No consistent architectural pattern (MVC, layers, etc.)
- Copy-pasted code with slight variations
- Global mutable state accessed from multiple places
- Exception handling that swallows errors silently

**Code smells that indicate spaghetti:**

```java
// Deep nesting, mixed concerns, unclear flow
public void process(Request req) {
    if (req != null) {
        if (req.getUser() != null) {
            try {
                if (checkPermission(req.getUser())) {
                    var data = fetchData(req);
                    if (data != null) {
                        // 50 more lines of nested logic
                    } else {
                        // Different 30 lines
                    }
                }
            } catch (Exception e) {
                // Swallowed
            }
        }
    }
}
```
---

### How to Fix It

**Strategy: Structured refactoring**

1. **Extract early returns (Guard Clauses):**

```java
// GOOD: Flat, readable, exit early
public void process(Request req) {
    if (req == null) return;
    if (req.getUser() == null) return;
    if (!checkPermission(req.getUser())) {
        throw new AccessDeniedException();
    }
    var data = fetchData(req);
    if (data == null) {
        throw new DataNotFoundException();
    }
    processValidData(data);
}
```

2. **Extract methods by abstraction level:**
   Each method should operate at one level of abstraction. `processOrder()` calls `validate()`, `charge()`, `ship()` - not low-level database queries mixed with HTTP calls.

3. **Establish layered architecture:**
   Controller -> Service -> Repository. Each layer calls only the layer directly below it. No skipping layers. No circular calls.

4. **Replace shared mutable state with parameters:**
   Pass data through method arguments, not through shared fields that anyone can modify.
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
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
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

1. Spaghetti code has no clear structure, tangled control flow, and high coupling
2. Guard clauses, method extraction, and layered architecture are the cure
3. Prevention: code reviews enforcing single-level-of-abstraction and max method length

**Interview one-liner:**
"Spaghetti code is unstructured, tangled code where control flow is unpredictable and changes cascade unexpectedly - I prevent it with guard clauses, method extraction, layered architecture, and strict code review standards."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

The original spaghetti code was created by GOTO statements in assembly and early BASIC. Structured programming (functions, loops, conditionals) was invented specifically to eliminate it. Yet modern spaghetti code exists without a single GOTO - it's created by excessive callbacks, deeply nested promises, tangled event handlers, and complex state management. The anti-pattern survived the elimination of its original cause because spaghetti code is a symptom of unclear thinking about structure, not a specific language feature.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Spaghetti Code. Otherwise remove this section.]
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

**Q1: How do you prevent spaghetti code in a team?**

_Why they ask:_ Tests leadership and process skills.

**Answer:**
Process-level prevention:

1. **Max method length rule:** 20 lines per method. CI enforces it. Forces extraction.
2. **Cyclomatic complexity limit:** Max 10 per method. Tools like SonarQube enforce this automatically.
3. **Architecture Decision Records:** Document and enforce layer boundaries. "Controllers never call repositories directly" - make it a CI rule.
4. **Code review checklist:** "Can you trace the execution path without a debugger?" If no, reject.
5. **Pair programming for complex features:** Two heads prevent tangling in real time.

Technical prevention:

1. **Guard clauses:** Eliminate nesting
2. **Single Level of Abstraction Principle (SLAP):** Each method operates at one abstraction level
3. **Dependency injection:** Makes coupling explicit and testable
4. **Architecture tests (ArchUnit):** Automatically verify layer dependencies
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

# Premature Optimization

**TL;DR** - Premature optimization is optimizing code before you know where the actual bottleneck is, wasting effort on non-problems while making code harder to read and maintain.
---

### The Problem This Creates

**HOW IT STARTS:**
A developer writes a simple user lookup: `userRepository.findById(id)`. "But what if we have millions of users? I should add caching!" They add Redis caching before the application has 100 users. Then they add connection pooling, read replicas, and query optimization - all for a feature that handles 10 requests per day.

**HOW IT GROWS:**
The caching layer introduces cache invalidation bugs. The read replica introduces eventual consistency issues. The query optimization uses database-specific features that prevent migration. Six months of debugging time is spent on infrastructure that serves no purpose at current scale.

**THE REAL COST:**
The simple `findById()` that took 5ms now takes 3ms through cache. The 2ms improvement is invisible to users. But the code complexity tripled, bugs doubled, and onboarding time increased because every new developer must understand the caching, replication, and optimization layers.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Premature Optimization was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

"Premature optimization is the root of all evil" - Donald Knuth, 1974. It refers to the practice of optimizing code before profiling has identified actual bottlenecks, typically resulting in complex, hard-to-maintain code that solves performance problems that don't exist while making the code harder to change when real problems emerge.
---

### How to Recognize It

**Warning signs:**

- Optimizing before measuring ("this might be slow")
- Complex data structures for small data sets (B-tree for 50 elements)
- Caching with no evidence of repeated expensive queries
- Custom implementations replacing standard library code ("my ArrayList is faster")
- Micro-optimizations in non-hot code paths (bit shifting instead of division)
- Performance-motivated architecture decisions without load testing data

**Questions to ask:**

1. Have you profiled this? What does the profiler show?
2. How many requests/records does this actually handle?
3. What is the current response time? What is the target?
4. Is this code on the hot path?
---

### How to Fix It

**Strategy: Measure, then optimize**

```
The Optimization Process:
1. Write correct, readable code first
2. Measure performance under realistic load
3. Profile to find actual bottlenecks (top 20%)
4. Optimize the bottleneck with the simplest fix
5. Measure again to verify improvement
6. Repeat if target not met
```

**Real example:**

```java
// Stage 1: Correct and readable (START HERE)
public List<Order> getRecentOrders(String userId) {
    return orderRepository
        .findByUserIdOrderByDateDesc(userId);
}

// Stage 2: Profile shows this query is slow
// (only after measuring with real data)
// Add an index, not caching:
// CREATE INDEX idx_orders_user_date
//   ON orders(user_id, created_date DESC);

// Stage 3: If STILL slow after indexing,
// THEN consider caching:
@Cacheable("recentOrders")
public List<Order> getRecentOrders(String userId) {
    return orderRepository
        .findByUserIdOrderByDateDesc(userId);
}
```
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
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
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

1. "Premature optimization is the root of all evil" - profile before optimizing
2. 97% of code is not the bottleneck - find the 3% that is
3. Correct first, readable second, fast third - in that order

**Interview one-liner:**
"Premature optimization adds complexity to solve performance problems that don't exist - I always profile first, optimize the measured bottleneck with the simplest fix, then verify the improvement."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

The full Knuth quote is: "We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil. Yet we should not pass up our opportunities in that critical 3%." Most people quote only the middle part. Knuth was not saying "never optimize" - he was saying optimize the right 3%. The principle is about targeting effort, not avoiding performance work. Senior engineers know that architectural decisions (data model, communication patterns) are the 3% where early performance thinking matters enormously.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Premature Optimization. Otherwise remove this section.]
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

**Q1: When IS early optimization appropriate?**

_Why they ask:_ Tests nuanced understanding vs dogmatic rule-following.

**Answer:**
Early optimization is appropriate for:

1. **Algorithmic complexity:** Choosing O(n log n) sort over O(n^2) is not premature - it's basic engineering. This is design, not optimization.

2. **Data model design:** Choosing the right database schema, index strategy, or data structure at design time avoids expensive migrations later.

3. **Architecture decisions:** Choosing sync vs async, monolith vs microservice, REST vs gRPC - these have massive performance implications that are expensive to change.

4. **Known hot paths:** If you're building a payment gateway, the transaction processing path will be high-throughput. Designing for performance there is prudent.

The rule: optimize the architecture early (cheap to change in design, expensive later). Don't optimize the implementation early (easy to change later, and you don't know the bottleneck yet).
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

# Circular Dependencies

**TL;DR** - Circular dependencies occur when two or more modules depend on each other, creating a loop that prevents independent deployment, testing, and understanding of either module.
---

### The Problem This Creates

**HOW IT STARTS:**
`OrderService` calls `UserService.getUser()` to validate the order. `UserService` calls `OrderService.getRecentOrders()` to show user history. Each service imports the other. A bidirectional dependency is born.

**HOW IT GROWS:**
A third service, `NotificationService`, depends on both. `OrderService` needs `NotificationService` for order confirmation emails. `NotificationService` needs `UserService` for email addresses. `UserService` needs `NotificationService` for password reset emails. Now three services form a dependency cycle. Deploying any one requires deploying all three.

**WHY IT'S DANGEROUS:**

- **Compilation:** In languages with strict module systems, circular imports fail to compile
- **Testing:** You can't test `OrderService` without `UserService` and vice versa
- **Deployment:** You can't deploy one service independently
- **Understanding:** You can't understand one service without understanding the other
- **Spring:** Circular bean dependencies cause `BeanCurrentlyInCreationException`
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Circular Dependencies was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

A circular dependency is a relation between two or more modules that directly or indirectly depend on each other, creating a closed loop. It indicates a design flaw where responsibilities are not properly separated, leading to tight coupling and preventing independent compilation, testing, and deployment.
---

### How to Recognize It

**Warning signs:**

- Spring throws `BeanCurrentlyInCreationException` or `UnsatisfiedDependencyException`
- Modifying module A requires redeploying module B
- Test setup for class A requires setting up class B and vice versa
- Import statements form a cycle (`a.java` imports from `b`, `b.java` imports from `a`)
- Maven/Gradle dependency graph shows cycles

**Detection tools:**

- IntelliJ: Analyze -> Circular Dependencies
- Maven: `mvn dependency:tree -DverboseResolutionOutput`
- SonarQube: cyclic dependency detection
- ArchUnit: `slices().should().beFreeOfCycles()`
---

### How to Fix It

**Strategy 1: Dependency Inversion**

```java
// BAD: Circular dependency
// OrderService -> UserService -> OrderService
@Service
public class OrderService {
    @Autowired UserService userService;
    public List<Order> getOrders(String userId) {/**/}
}
@Service
public class UserService {
    @Autowired OrderService orderService;
    public UserProfile getProfile(String userId) {
        var orders = orderService.getOrders(userId);
        // ...
    }
}

// GOOD: Extract interface, invert dependency
public interface OrderLookup {
    List<Order> getOrders(String userId);
}

@Service
public class OrderService implements OrderLookup {
    // No dependency on UserService
    public List<Order> getOrders(String userId) {/**/}
}

@Service
public class UserService {
    @Autowired OrderLookup orderLookup; // Interface
    public UserProfile getProfile(String userId) {
        var orders = orderLookup.getOrders(userId);
        // ...
    }
}
```

**Strategy 2: Mediator / Event-based**

```java
// GOOD: Break cycle with events
@Service
public class OrderService {
    @Autowired ApplicationEventPublisher events;

    public void createOrder(Order order) {
        save(order);
        events.publishEvent(
            new OrderCreatedEvent(order));
    }
}

@Service
public class UserService {
    @EventListener
    public void onOrderCreated(OrderCreatedEvent e) {
        updateUserOrderHistory(e.order());
    }
}
// No direct dependency between services
```

**Strategy 3: Extract shared dependency**

```java
// GOOD: Extract the shared concern
@Service
public class UserOrderService {
    // Contains the logic both services needed
    // from each other
    public UserWithOrders getUserWithOrders(
            String userId) {
        /*...*/
    }
}
```
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
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
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

1. Circular dependencies prevent independent testing, deployment, and understanding
2. Fix with: dependency inversion (interfaces), events (decoupling), or extract shared service
3. Use ArchUnit to detect and prevent cycles in CI/CD

**Interview one-liner:**
"Circular dependencies create tight coupling that prevents independent testing and deployment - I break them with dependency inversion, event-driven communication, or extracting the shared concern into a third module."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Spring Boot used to allow circular dependencies by default through lazy proxy injection. Starting in Spring Boot 2.6, circular dependencies cause a startup failure by default. This was a deliberate change: the Spring team recognized that allowing circular dependencies, while convenient, encouraged poor architecture. The error message guides developers to fix the design rather than work around it. This shows that frameworks can enforce design principles - but only when the framework authors have the courage to break backward compatibility for better architecture.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Circular Dependencies. Otherwise remove this section.]
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

**Q1: How do you detect circular dependencies before they cause problems?**

_Why they ask:_ Tests proactive quality practices.

**Answer:**
Layer 1 - Static analysis:

```java
// ArchUnit test - runs in CI
@Test
void noCyclicDependencies() {
    slices().matching("com.myapp.(*)..")
        .should().beFreeOfCycles()
        .check(importedClasses);
}
```

Layer 2 - IDE analysis: IntelliJ's "Analyze -> Cyclic Dependencies" shows module-level cycles visually.

Layer 3 - Build tool: Maven Enforcer Plugin with `banCircularDependencies` rule fails the build on cycles.

Layer 4 - Architecture fitness function: Run ArchUnit tests in CI. Any cycle introduced in a PR is automatically rejected.

The proactive approach: define allowed dependencies in ArchUnit at project start. New modules must declare their position in the dependency hierarchy. Cycles are caught before code review.
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

# Feature Envy

**TL;DR** - Feature Envy is when a method uses more features (data, methods) of another class than its own, indicating the method belongs in the other class.
---

### The Problem This Creates

**HOW IT STARTS:**
A `BillingService` method calculates a customer's discount. It accesses `customer.getType()`, `customer.getYearsActive()`, `customer.getTotalPurchases()`, `customer.getRegion()`. The method uses 4 fields from `Customer` and 0 fields from `BillingService`. The logic belongs in `Customer`, not `BillingService`.

**HOW IT GROWS:**
When the discount rules change, `BillingService` changes. When `Customer` fields change, `BillingService` changes. `BillingService` is tightly coupled to `Customer`'s internal structure. Every new customer type requires modifying `BillingService`. The method is in the wrong class, creating fragile coupling.

**WHY IT MATTERS:**
Feature Envy violates encapsulation. The whole point of OOP is that data and behavior live together. When a method reaches into another object's fields extensively, it breaks encapsulation by proxy - it doesn't access private fields directly, but it depends on the object's data structure completely.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[TODO: Concrete pain scenario. 2-4 sentences.]

**THE BREAKING POINT:**
[TODO: Specific failure. 1-2 sentences.]

**THE INVENTION MOMENT:**
"This is exactly why Feature Envy was created."

**EVOLUTION:**
[TODO: predecessor -> current form -> future.]
---

### 📘 Textbook Definition

Feature Envy is a code smell (introduced by Martin Fowler in "Refactoring") where a method in one class uses the data or methods of another class more than its own. The envious method should be moved to the class whose features it uses, following the principle of "put behavior close to data."
---

### How to Recognize It

**Warning signs:**

- A method calls 3+ getters on the same external object
- A method doesn't use `this` or any instance fields
- After reading the method, you think "this belongs in the other class"
- Data and behavior are separated: data in one class, logic in another

**Detection:**

```java
// Feature Envy: method uses Customer's data
public class BillingService {
    public BigDecimal calculateDiscount(Customer c) {
        // 4 accesses to Customer, 0 to this
        if (c.getType() == CustomerType.VIP
                && c.getYearsActive() > 5
                && c.getTotalPurchases()
                    .compareTo(BigDecimal.valueOf(
                        10000)) > 0
                && "US".equals(c.getRegion())) {
            return c.getTotalPurchases()
                .multiply(new BigDecimal("0.15"));
        }
        return BigDecimal.ZERO;
    }
}
```
---

### How to Fix It

**Strategy: Move Method**

```java
// GOOD: Move behavior to the data owner
public class Customer {
    private CustomerType type;
    private int yearsActive;
    private BigDecimal totalPurchases;
    private String region;

    public BigDecimal calculateDiscount() {
        if (type == CustomerType.VIP
                && yearsActive > 5
                && totalPurchases.compareTo(
                    BigDecimal.valueOf(10000)) > 0
                && "US".equals(region)) {
            return totalPurchases
                .multiply(new BigDecimal("0.15"));
        }
        return BigDecimal.ZERO;
    }
}

// BillingService delegates to Customer
public class BillingService {
    public Invoice createInvoice(Customer c) {
        BigDecimal discount = c.calculateDiscount();
        // ... uses discount to build invoice
    }
}
```

**When Feature Envy is acceptable:**

- DTOs/value objects that are intentionally data-only
- Cross-cutting concerns (logging, metrics) that naturally access multiple objects
- Adapter/Facade classes whose purpose is to bridge between objects
- When moving the method would create a circular dependency
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
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
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

1. Feature Envy = method uses another class's data more than its own
2. Fix: move the method to the class whose data it uses
3. Put behavior close to data - that's encapsulation

**Interview one-liner:**
"Feature Envy is when a method accesses another class's data more than its own - I fix it by moving the method to the data owner, keeping behavior and data together for proper encapsulation."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

In an anemic domain model (common in enterprise Java), Feature Envy is everywhere by design. DTOs hold data, services hold behavior. Every service method is envious of its DTO's data. Martin Fowler considers anemic domain models an anti-pattern for exactly this reason. A rich domain model (DDD) puts behavior on entities, eliminating Feature Envy. The debate between anemic and rich domain models is essentially a debate about whether Feature Envy is acceptable architecture or an anti-pattern to eliminate.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Feature Envy. Otherwise remove this section.]
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

**Q1: How do you distinguish Feature Envy from legitimate service methods?**

_Why they ask:_ Tests nuanced design judgment.

**Answer:**
The distinction is about the method's primary purpose:

**Feature Envy (move it):**

```java
// This method ONLY uses Customer data
public BigDecimal calculateDiscount(Customer c) {
    return c.getTotal()
        .multiply(c.getDiscountRate());
}
```

This belongs in `Customer`. It uses only Customer data and nothing from the service.

**Legitimate service (keep it):**

```java
// This method orchestrates multiple objects
public OrderResult processOrder(
        Customer c, Cart cart, Coupon coupon) {
    BigDecimal total = cart.getTotal();
    BigDecimal discount = coupon.apply(total);
    c.charge(discount);
    return OrderResult.success();
}
```

This coordinates Customer, Cart, and Coupon. It doesn't envy any single class - it orchestrates.

**The test:** If the method uses data from ONE class and nothing else, move it. If it coordinates MULTIPLE classes, it's a legitimate service method.
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
