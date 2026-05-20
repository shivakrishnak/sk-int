---
layout: default
title: "Design Patterns - Additional GoF"
parent: "Design Patterns"
grand_parent: "Interview Mastery"
nav_order: 6
permalink: /interview/design-patterns/additional-gof/
topic: Design Patterns
subtopic: Additional GoF
keywords:
  - Iterator
  - Visitor
  - Mediator
  - Memento
difficulty_range: mixed
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Iterator](#iterator)
- [Visitor](#visitor)
- [Mediator](#mediator)
- [Memento](#memento)

# Iterator

**TL;DR** - Iterator provides a uniform way to traverse elements of a collection without exposing its internal structure - enabling the same traversal code for arrays, lists, trees, and custom data structures.
---

### 🔥 The Problem This Solves

You have an `ArrayList`, a `HashSet`, a `TreeMap`, and a custom graph. Each has a different internal structure. Without Iterator, you'd need different traversal code for each: index-based loops for lists, bucket-walking for sets, tree-walking for maps. Adding a new collection type means new traversal code everywhere.
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

### ⚙️ How It Works

```
WITHOUT ITERATOR:
for (int i = 0; i < list.size(); i++)  // list
for (Node n = head; n != null; n=n.next) // linked
for (bucket : table) for (entry : bucket) // hash

WITH ITERATOR:
for (Element e : anyCollection)  // works for ALL
  // Same code regardless of underlying structure
```
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

```java
// Java's Iterator pattern (built into language)
List<String> list = List.of("A", "B", "C");
Set<String> set = Set.of("X", "Y", "Z");

// Same traversal code for both:
for (String s : list) { process(s); }
for (String s : set)  { process(s); }

// Custom Iterator for a Tree
public class BinaryTree<T> implements Iterable<T> {
    private Node<T> root;

    @Override
    public Iterator<T> iterator() {
        return new InOrderIterator<>(root);
    }

    private static class InOrderIterator<T>
            implements Iterator<T> {
        private final Deque<Node<T>> stack =
            new ArrayDeque<>();

        InOrderIterator(Node<T> root) {
            pushLeft(root);
        }

        private void pushLeft(Node<T> node) {
            while (node != null) {
                stack.push(node);
                node = node.left;
            }
        }

        @Override
        public boolean hasNext() {
            return !stack.isEmpty();
        }

        @Override
        public T next() {
            Node<T> node = stack.pop();
            pushLeft(node.right);
            return node.value;
        }
    }
}

// Now works with enhanced for-loop:
BinaryTree<Integer> tree = buildTree();
for (int val : tree) {
    System.out.println(val);
}

// And with Streams:
tree.stream().filter(v -> v > 10).toList();
```
---

### Java's Iterator Ecosystem

| Interface         | Method                       | Used for                     |
| ----------------- | ---------------------------- | ---------------------------- |
| `Iterable<T>`     | `iterator()`                 | Enhanced for-loop support    |
| `Iterator<T>`     | `hasNext()`, `next()`        | One-direction traversal      |
| `ListIterator<T>` | `previous()`, `add()`        | Bidirectional + modification |
| `Spliterator<T>`  | `tryAdvance()`, `trySplit()` | Parallel stream support      |
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

1. Implement `Iterable<T>` to enable enhanced for-loop and Stream API on custom collections
2. Iterator encapsulates traversal logic - clients don't need to know if it's an array, tree, or graph
3. `Spliterator` extends the concept for parallel processing (used by `parallelStream()`)

**Interview one-liner:**
"Iterator decouples traversal from collection structure - in Java, implementing Iterable gives you enhanced for-loops and Stream API for free, while Spliterator enables parallel processing."
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

[TODO: Include if 2+ named alternatives exist for Iterator. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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

# Visitor

**TL;DR** - Visitor lets you add new operations to a class hierarchy without modifying the classes themselves, using double dispatch to call the right method based on both the element type and the operation.
---

### 🔥 The Problem This Solves

You have a document AST: `Paragraph`, `Heading`, `Image`, `Table`. You need operations: export to HTML, export to PDF, word count, spell check. Adding each operation to each class creates an explosion of methods. Adding a new operation means modifying all 4 classes. In a sealed hierarchy, you may not be able to modify the classes at all.
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

### ⚙️ How It Works

```
WITHOUT VISITOR (operations mixed into classes):
Paragraph.toHTML()   Heading.toHTML()
Paragraph.toPDF()    Heading.toPDF()
Paragraph.count()    Heading.count()
  -> 4 classes x 3 operations = 12 methods
  -> Adding export-to-Markdown: modify 4 classes

WITH VISITOR (operations separated):
HTMLVisitor.visit(Paragraph)  visit(Heading)
PDFVisitor.visit(Paragraph)   visit(Heading)
CountVisitor.visit(Paragraph) visit(Heading)
  -> Adding export-to-Markdown: add 1 new visitor
  -> Zero changes to element classes
```
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

```java
// Element hierarchy (closed, rarely changes)
public sealed interface DocElement
        permits Paragraph, Heading, Image {
    <R> R accept(DocVisitor<R> visitor);
}

public record Paragraph(String text)
        implements DocElement {
    public <R> R accept(DocVisitor<R> visitor) {
        return visitor.visit(this); // double dispatch
    }
}

public record Heading(int level, String text)
        implements DocElement {
    public <R> R accept(DocVisitor<R> visitor) {
        return visitor.visit(this);
    }
}

public record Image(String url, String alt)
        implements DocElement {
    public <R> R accept(DocVisitor<R> visitor) {
        return visitor.visit(this);
    }
}

// Visitor interface
public interface DocVisitor<R> {
    R visit(Paragraph p);
    R visit(Heading h);
    R visit(Image img);
}

// Operation 1: HTML export
public class HTMLVisitor
        implements DocVisitor<String> {
    public String visit(Paragraph p) {
        return "<p>" + p.text() + "</p>";
    }
    public String visit(Heading h) {
        return "<h" + h.level() + ">"
            + h.text() + "</h" + h.level() + ">";
    }
    public String visit(Image img) {
        return "<img src=\"" + img.url()
            + "\" alt=\"" + img.alt() + "\">";
    }
}

// Operation 2: Word count
public class WordCountVisitor
        implements DocVisitor<Integer> {
    public Integer visit(Paragraph p) {
        return p.text().split("\\s+").length;
    }
    public Integer visit(Heading h) {
        return h.text().split("\\s+").length;
    }
    public Integer visit(Image img) {
        return 0;
    }
}

// Usage:
List<DocElement> doc = List.of(
    new Heading(1, "Title"),
    new Paragraph("Hello world"));

HTMLVisitor html = new HTMLVisitor();
for (DocElement el : doc) {
    System.out.println(el.accept(html));
}
```

**Modern alternative (Java 21+ pattern matching):**

```java
// Sealed types + switch replaces Visitor
String toHTML(DocElement el) {
    return switch (el) {
        case Paragraph p -> "<p>" + p.text() + "</p>";
        case Heading h -> "<h" + h.level() + ">"
            + h.text() + "</h" + h.level() + ">";
        case Image img -> "<img src=\""
            + img.url() + "\">";
    };
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

1. Visitor adds new operations without modifying element classes (Open/Closed Principle)
2. Double dispatch: element.accept(visitor) -> visitor.visit(element) - selects the right overload
3. In modern Java (21+), sealed types + pattern matching switch often replaces Visitor pattern

**Interview one-liner:**
"Visitor separates operations from element hierarchies using double dispatch - I use it for stable class hierarchies that need frequent new operations, though in Java 21+ I prefer sealed types with pattern matching as a cleaner alternative."
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

[TODO: Include if 2+ named alternatives exist for Visitor. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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

# Mediator

**TL;DR** - Mediator centralizes complex communication between multiple objects, replacing many-to-many dependencies with a single coordination point - preventing spaghetti coupling between components.
---

### 🔥 The Problem This Solves

A chat room with 10 users. Without Mediator, each user has a reference to all 9 others. User A sends a message - it directly calls B, C, D, E, F, G, H, I, J. Adding user K means modifying all 10 existing users. 10 users = 90 direct connections. 100 users = 9,900 connections.

With a Mediator (the chat room): User A sends a message to the chat room. The chat room distributes it. Each user only knows about the chat room. Adding user K: register with the chat room. Zero changes to existing users.
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

### ⚙️ How It Works

```
WITHOUT MEDIATOR:
[A] <--> [B]
[A] <--> [C]    N objects = N(N-1)/2 connections
[B] <--> [C]

WITH MEDIATOR:
[A] <--> [Mediator] <--> [B]
                    <--> [C]
  N objects = N connections
```
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

```java
// Spring's ApplicationEventPublisher is a Mediator
@Service
public class OrderService {
    private final ApplicationEventPublisher events;

    @Transactional
    public Order createOrder(OrderRequest req) {
        Order order = processOrder(req);
        // Mediator distributes to all listeners
        events.publishEvent(
            new OrderCreatedEvent(order));
        return order;
    }
}

// Listeners don't know about each other
@Component
public class InventoryListener {
    @EventListener
    public void on(OrderCreatedEvent e) {
        inventoryService.reserve(e.getItems());
    }
}

@Component
public class NotificationListener {
    @EventListener
    public void on(OrderCreatedEvent e) {
        emailService.sendConfirmation(e);
    }
}
// Adding AnalyticsListener: create new class
// Zero changes to OrderService or other listeners
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

1. Mediator reduces N-to-N coupling to N-to-1 by centralizing communication
2. Spring's `ApplicationEventPublisher` is a built-in Mediator implementation
3. Trade-off: simplifies components but the mediator itself can become a god object

**Interview one-liner:**
"Mediator centralizes complex inter-object communication through a single coordination point - Spring's ApplicationEventPublisher is a natural Mediator that lets me decouple services without direct dependencies."
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

[TODO: Include if 2+ named alternatives exist for Mediator. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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

# Memento

**TL;DR** - Memento captures an object's internal state so it can be restored later, enabling undo/redo functionality without violating encapsulation.
---

### 🔥 The Problem This Solves

Your text editor needs undo/redo. You need to save the document's state at each edit so you can restore it. But the document's internal state (cursor position, formatting data, selection range) is private. You can't just expose getters for everything - that breaks encapsulation.
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

### ⚙️ How It Works

```
[Originator]           [Caretaker]
(Document)             (Undo Stack)
    |                       |
    |-- createMemento() --> |  push(memento)
    |                       |
    | (user makes edits)    |
    |                       |
    |<- restore(memento) -- |  pop()
    |                       |
  (state restored)
```
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

```java
// Originator: the object whose state is saved
public class TextEditor {
    private StringBuilder content =
        new StringBuilder();
    private int cursorPos = 0;

    public void type(String text) {
        content.insert(cursorPos, text);
        cursorPos += text.length();
    }

    public void delete(int chars) {
        int start = Math.max(0,
            cursorPos - chars);
        content.delete(start, cursorPos);
        cursorPos = start;
    }

    // Create snapshot (memento)
    public EditorMemento save() {
        return new EditorMemento(
            content.toString(), cursorPos);
    }

    // Restore from snapshot
    public void restore(EditorMemento memento) {
        this.content = new StringBuilder(
            memento.content());
        this.cursorPos = memento.cursorPos();
    }
}

// Memento: immutable snapshot of state
public record EditorMemento(
    String content, int cursorPos) {}

// Caretaker: manages undo/redo stacks
public class UndoManager {
    private final Deque<EditorMemento> undoStack =
        new ArrayDeque<>();
    private final Deque<EditorMemento> redoStack =
        new ArrayDeque<>();
    private final TextEditor editor;

    public void save() {
        undoStack.push(editor.save());
        redoStack.clear();
    }

    public void undo() {
        if (!undoStack.isEmpty()) {
            redoStack.push(editor.save());
            editor.restore(undoStack.pop());
        }
    }

    public void redo() {
        if (!redoStack.isEmpty()) {
            undoStack.push(editor.save());
            editor.restore(redoStack.pop());
        }
    }
}
```
---

### Real-World Applications

| Application | Originator | Memento           | Caretaker           |
| ----------- | ---------- | ----------------- | ------------------- |
| Text editor | Document   | Document snapshot | Undo stack          |
| Game        | Game state | Save file         | Save slots          |
| Transaction | DB state   | Savepoint         | Transaction manager |
| Form wizard | Form data  | Step snapshot     | Navigation history  |
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

1. Memento = immutable snapshot of an object's internal state
2. Three roles: Originator (creates/restores), Memento (holds state), Caretaker (manages history)
3. In Java, use `record` for the Memento type (immutable by design, perfect fit)

**Interview one-liner:**
"Memento captures object state for undo/redo without breaking encapsulation - the originator creates immutable snapshots, and the caretaker manages the undo/redo stacks, as seen in text editors, game saves, and database savepoints."
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

[TODO: Include if 2+ named alternatives exist for Memento. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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
