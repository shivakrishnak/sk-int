---
title: "Java Language"
description: "Interview coverage for Java language features: types, OOP, generics, lambdas, and modern Java (8-21)"
tags: [interview, java, java-language]
---

# Java Language

Java language specification features - from type system fundamentals
through modern Java 21 additions. Distinct from JVM internals (java-jvm/)
and platform APIs (java-core/).

**Interview focus:** Language semantics, type system, OOP design,
functional programming idioms, modern Java features, backward
compatibility reasoning.

## Files

| File                                                                                          | Level | Keywords | Status   |
| --------------------------------------------------------------------------------------------- | ----- | -------- | -------- |
| [Java Language - L0 Orientation](Java%20Language%20-%20L0%20Orientation.md)                   | L0    | 5        | complete |
| [Java Language - L1 Foundations](Java%20Language%20-%20L1%20Foundations.md)                   | L1    | 5        | complete |
| [Java Language - L2 Object Model](Java%20Language%20-%20L2%20Object%20Model.md)               | L2    | 5        | complete |
| [Java Language - L2 Generics and Types](Java%20Language%20-%20L2%20Generics%20and%20Types.md) | L2    | 5        | complete |
| [Java Language - L2 Functional](Java%20Language%20-%20L2%20Functional.md)                     | L2    | 5        | complete |
| [Java Language - L3 Type System Depth](Java%20Language%20-%20L3%20Type%20System%20Depth.md)   | L3    | 5        | complete |
| [Java Language - L3 Modern Java](Java%20Language%20-%20L3%20Modern%20Java.md)                 | L3    | 5        | planned  |
| Java Language - L4 Language Internals   | L4    | 4        | planned  |
| Java Language - L5 Architecture                 | L5    | 3        | planned  |
| Java Language - META Patterns                     | META  | 3        | planned  |

**Total: 46 keywords, 10 files**

---

## Keyword Registry

### Java Language - L0 Orientation

| #   | Keyword                                            | Difficulty | Status |
| --- | -------------------------------------------------- | ---------- | ------ |
| 1   | Why Java? Design Philosophy and Guiding Principles | easy       | draft  |
| 2   | Java Timeline: From Oak to Java 21                 | easy       | draft  |
| 3   | Java Editions: SE, EE, ME, and Jakarta EE          | easy       | draft  |
| 4   | Java Community Process and JEPs: How Java Evolves  | easy       | draft  |
| 5   | JVM Languages Ecosystem: Kotlin, Scala, Groovy     | easy       | draft  |

### Java Language - L1 Foundations

| #   | Keyword                                            | Difficulty | Status |
| --- | -------------------------------------------------- | ---------- | ------ |
| 1   | Primitives vs References: The Two Type Universes   | easy       | draft  |
| 2   | Variables, Scope, and Definite Assignment          | easy       | draft  |
| 3   | Operators, Precedence, and Implicit Widening       | easy       | draft  |
| 4   | Packages, Imports, and Classpath Resolution        | easy       | draft  |
| 5   | Control Flow: Loops, Conditionals, Jump Statements | easy       | draft  |

### Java Language - L2 Object Model

| #   | Keyword                                                      | Difficulty | Status |
| --- | ------------------------------------------------------------ | ---------- | ------ |
| 1   | Classes, Abstract Classes, and Interfaces: When to Use Which | medium     | draft  |
| 2   | Inheritance, Overriding, and the Diamond Problem             | medium     | draft  |
| 3   | The Object Class: equals, hashCode, toString, and clone      | medium     | draft  |
| 4   | Access Modifiers and Encapsulation Patterns                  | medium     | draft  |
| 5   | Inner Classes: Static Nested, Member, Local, Anonymous       | medium     | draft  |

### Java Language - L2 Generics and Types

| #   | Keyword                                                  | Difficulty | Status |
| --- | -------------------------------------------------------- | ---------- | ------ |
| 1   | Generics: Type Parameters, Bounds, and Type Safety       | medium     | draft  |
| 2   | Wildcards and PECS: Producer Extends, Consumer Super     | medium     | draft  |
| 3   | Enums: State Machines, Abstract Methods, and EnumMap     | medium     | draft  |
| 4   | Autoboxing, Unboxing, and the Integer Cache Trap         | medium     | draft  |
| 5   | Type Inference: Diamond Operator, var, and Target Typing | medium     | draft  |

### Java Language - L2 Functional

| #   | Keyword                                                          | Difficulty | Status |
| --- | ---------------------------------------------------------------- | ---------- | ------ |
| 1   | Lambda Expressions: Syntax, Capture Rules, and Effectively Final | medium     | draft  |
| 2   | Functional Interfaces: Predicate, Function, Consumer, Supplier   | medium     | draft  |
| 3   | Method References: Four Kinds and When Each Applies              | medium     | draft  |
| 4   | Streams API: Lazy Evaluation, Pipelines, and Terminal Operations | medium     | draft  |
| 5   | Optional: The Null-Safety Pattern and When NOT to Use It         | medium     | draft  |

### Java Language - L3 Type System Depth

| #   | Keyword                                                          | Difficulty | Status |
| --- | ---------------------------------------------------------------- | ---------- | ------ |
| 1   | Records: Value Semantics and Compact Constructors                | medium     | draft  |
| 2   | Sealed Classes: Exhaustive Polymorphism and ADTs                 | medium     | draft  |
| 3   | Pattern Matching: instanceof, Switch Expressions, Deconstruction | medium     | draft  |
| 4   | Annotations: Retention, Target, and Custom Processors            | medium     | draft  |
| 5   | Covariance, Contravariance, and Wildcard Capture                 | medium     | draft  |

### Java Language - L3 Modern Java

| #   | Keyword                                                          | Difficulty | Status  |
| --- | ---------------------------------------------------------------- | ---------- | ------- |
| 1   | Text Blocks: Indentation Stripping and Incidental Whitespace     | medium     | pending |
| 2   | Switch Expressions: Exhaustiveness, Arrow Syntax, and Yield      | medium     | pending |
| 3   | var: Local Variable Type Inference and Its Limits                | medium     | pending |
| 4   | Default and Static Interface Methods: Evolution Without Breaking | medium     | pending |
| 5   | Structured Concurrency and Scoped Values (Java 21+)              | medium     | pending |

### Java Language - L4 Language Internals

| #   | Keyword                                                               | Difficulty | Status  |
| --- | --------------------------------------------------------------------- | ---------- | ------- |
| 1   | Type Erasure: Heap Pollution, Bridge Methods, Unchecked Warnings      | hard       | pending |
| 2   | Immutability: Defensive Copies, Unmodifiable Views, Deep Immutability | hard       | pending |
| 3   | Reflection: Class, Method, Field - Power, Cost, Security              | hard       | pending |
| 4   | String Pool and Interning: Memory Footprint at Scale                  | hard       | pending |

### Java Language - L5 Architecture

| #   | Keyword                                                        | Difficulty | Status  |
| --- | -------------------------------------------------------------- | ---------- | ------- |
| 1   | Backward Compatibility: The Java Social Contract and Its Costs | hard       | pending |
| 2   | Java Language Specification: Type System Formal Rules          | hard       | pending |
| 3   | Java Platform Module System: Encapsulation at Module Level     | hard       | pending |

### Java Language - META Patterns

| #   | Keyword                                                          | Difficulty | Status  |
| --- | ---------------------------------------------------------------- | ---------- | ------- |
| 1   | The Billion-Dollar Mistake: Java Null Safety History and Lessons | hard       | pending |
| 2   | API Design Principles: Effective Java Distilled                  | hard       | pending |
| 3   | The Expression Problem: Extensibility Trade-offs in OOP vs FP    | hard       | pending |
