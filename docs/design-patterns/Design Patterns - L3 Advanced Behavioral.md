---
layout: default
title: "Design Patterns - L3 Advanced Behavioral"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 9
permalink: /design-patterns/l3-advanced-behavioral/
render_with_liquid: false
---

# Mediator Pattern

---
id: DP-021
title: Mediator Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: high
asked_at: Mid+
seniority: mid-senior
tags: #design-patterns, #mediator, #behavioral, #decoupling, #event-bus
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Mediator defines an object that encapsulates how a set of objects
> interact. Components communicate through the mediator rather than
> directly with each other. This reduces the number of connections
> from O(n^2) (every component knows every other) to O(n) (every
> component knows only the mediator). Spring's `ApplicationEventPublisher`
> and MediatR (C#) are the canonical implementations.

**3 minutes (Senior):**
> The problem Mediator solves: in a complex UI or domain model, many
> components need to react to each other's changes. Without Mediator,
> component A calls B, B calls C, C calls A - a web of dependencies.
> Adding a new component requires updating every component it needs
> to interact with. With Mediator, each component publishes events to
> the mediator; the mediator routes them to interested components.
> Adding a new component: register it with the mediator; no other
> component changes.
>
> In Spring: `ApplicationEventPublisher` is the Mediator. Services
> publish domain events (`OrderPlacedEvent`); listeners (`@EventListener`
> methods) react without coupling to the publisher. This is Mediator
> at the framework level. CQRS's command bus is a Mediator: commands
> are dispatched to the mediator, which routes each command to its
> handler without the caller knowing which handler handles it.
>
> The distinction from Observer: Observer is one-to-many (one subject,
> many observers). Mediator is many-to-many (many components, all
> communicating through one hub). Observer's subject knows it has
> observers. Mediator's components know only the mediator, not each other.

**Blank Mind Recovery:**

**(1) Restate:** "Mediator - the pattern where components communicate
through a central hub instead of directly with each other."

**(2) First principles:** "Problem: N components need to communicate
with each other. N^2 connections. Solution: route all communication
through one hub. N connections total."

**(3) Bridge:** "Like air traffic control: planes (components) don't
communicate directly with each other. They all communicate through the
tower (mediator). The tower coordinates who goes where without planes
knowing each other's routes."

---

### 📘 Concept Explanation

**What it is:**
Mediator defines an object that encapsulates how a set of objects
interact. It promotes loose coupling by preventing objects from
referring to each other explicitly, letting you vary their interaction
independently.

**The problem it solves:**
Many objects communicate with many other objects. Direct coupling creates
O(n^2) dependencies. Adding new objects requires modifying all others
that interact with it. Mediator reduces this to O(n) by centralizing
all communication.

**How it works:**

```
Mediator interface:
  + notify(sender: Component, event: String)

ConcreteMediator implements Mediator:
  - componentA: ComponentA
  - componentB: ComponentB
  - componentC: ComponentC
  + notify(sender, event):
      if sender == componentA and event == "click":
          componentB.react()
          componentC.update()
      else if sender == componentB and event == "change":
          componentA.disable()

Component:
  - mediator: Mediator
  + trigger(event):
      mediator.notify(this, event)  // tell mediator; done

// Without Mediator (bad):
componentA.setComponentB(componentB)  // A knows B
componentA.setComponentC(componentC)  // A knows C
componentB.setComponentA(componentA)  // B knows A (circular!)
```

**The key insight:**
Components only know the `Mediator` interface. They never call each other
directly. When a component needs to cause a side effect elsewhere, it
calls `mediator.notify(this, "event")`. The mediator knows the routing.

**When to use it:**
- When a set of objects communicate in complex ways, resulting in
  unstructured and hard-to-understand interdependencies
- When reusing a component is difficult because it refers to many
  other components
- When you want to customize an interaction distributed across many classes
  without extensive subclassing

**When NOT to use it:**
- When the mediator itself grows too complex (God Object anti-pattern):
  it knows too much and becomes a bottleneck and point of complexity
- When the communication is simple and predictable: direct calls
  are clearer than routing through a hub

**Alternatives:**
- **Observer** - one-to-many; simpler when one component notifies many
- **Event Bus (Spring ApplicationEventPublisher, Guava EventBus)** -
  framework-level Mediator with pub/sub semantics
- **CQRS Command Bus** - specialized Mediator for command routing

---

### 💻 Code Example

```java
// BAD: Direct coupling - O(n^2) connections
public class OrderService {
    @Autowired InventoryService inventory;  // direct coupling
    @Autowired PaymentService payment;      // direct coupling
    @Autowired NotificationService notification; // direct

    public void placeOrder(Order order) {
        inventory.reserve(order);      // direct call
        payment.charge(order);         // direct call
        notification.notify(order);    // direct call
        // Adding analytics: modify THIS class
        // Adding fraud check: modify THIS class
    }
}
```

> **Code walkthrough:** `OrderService` directly depends on three services.
> Adding a fourth (analytics) means modifying `OrderService`. If payment
> also needs to notify inventory, `PaymentService` must also know
> `InventoryService`. The dependencies multiply.

```java
// GOOD: Spring ApplicationEventPublisher as Mediator
// Publisher (Component) - knows only the Mediator
@Service
public class OrderService {
    private final ApplicationEventPublisher mediator;

    public void placeOrder(Order order) {
        Order saved = orderRepo.save(order);
        // Publish event - does not know who listens
        mediator.publishEvent(
            new OrderPlacedEvent(this, saved));
        // OrderService is DONE. Reactions happen asynchronously.
    }
}

// Listeners (Components) - know only the Mediator
@Component
public class InventoryListener {
    @EventListener
    public void onOrderPlaced(OrderPlacedEvent event) {
        inventoryService.reserve(event.getOrder());
    }
}

@Component
public class PaymentListener {
    @EventListener
    public void onOrderPlaced(OrderPlacedEvent event) {
        paymentService.charge(event.getOrder());
    }
}

@Component
public class AnalyticsListener {  // Add without ANY existing changes
    @EventListener
    public void onOrderPlaced(OrderPlacedEvent event) {
        analyticsService.track(event.getOrder());
    }
}
// Spring (Mediator) routes OrderPlacedEvent to all 3 listeners.
// Adding another listener: add a class. Zero changes to OrderService.
```

> **Code walkthrough:** `OrderService` depends only on `ApplicationEventPublisher`
> (the Mediator). Each listener depends only on the event type and its
> own service. No component knows any other component. Adding
> `FraudDetectionListener`: create the class, annotate with `@Component`
> - Spring registers it automatically. The number of connections stays O(n),
> not O(n^2).

```java
// PRODUCTION: MediatR-style Command Bus (CQRS pattern)
// Commands are routed to exactly one handler
public interface CommandBus {
    <R> R dispatch(Command<R> command);
}

@Component
public class SimpleCommandBus implements CommandBus {
    private final Map<Class<?>, CommandHandler<?, ?>> handlers;

    // Spring injects all CommandHandler beans
    public SimpleCommandBus(
            List<CommandHandler<?, ?>> handlerList) {
        this.handlers = handlerList.stream()
            .collect(Collectors.toMap(
                h -> getCommandType(h),
                h -> h));
    }

    @SuppressWarnings("unchecked")
    public <R> R dispatch(Command<R> command) {
        CommandHandler<Command<R>, R> handler =
            (CommandHandler<Command<R>, R>)
            handlers.get(command.getClass());
        if (handler == null) throw new NoHandlerException(command);
        return handler.handle(command);
    }
}

// Usage:
PlaceOrderResult result = commandBus.dispatch(
    new PlaceOrderCommand(customerId, items));
// Caller does not know PlaceOrderCommandHandler exists
```

> **Code walkthrough:** The `CommandBus` is the Mediator. Callers
> `dispatch()` a command object without knowing which handler processes it.
> The mediator routes to the correct handler via the command type map.
> Adding a new command (`CancelOrderCommand`) means adding a new
> `CancelOrderCommandHandler` class - the command bus map is populated
> via Spring's `List<CommandHandler>` injection and requires no changes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Mediator is a communication hub: instead of components talking directly
> to each other, they all talk through the mediator. This reduces
> dependencies from every-to-every to every-to-one. Spring's
> `ApplicationEventPublisher` is the mediator pattern in production:
> one service publishes an event, multiple services listen without
> knowing who published.

*Push deeper:* "The benefit: adding a new component only requires
registering it with the mediator. Without the mediator, you would
need to find every component that should know about the new one and
add a direct dependency."

---

**Senior / Staff (5+ years):**
> Mediator vs Observer is a common confusion. Observer: one subject,
> many observers; the subject is the central object. Adding a new
> observer means subscribing to the subject. Mediator: no central
> subject; any component can publish; the mediator routes to interested
> components. The Mediator pattern is more symmetric - any component
> can be both publisher and subscriber.
>
> The Mediator anti-pattern: the mediator grows into a God Object.
> If the `notify()` method has 50 cases, the mediator knows too much
> about every component's internals. Solution: split the mediator into
> domain-specific event channels (Order events, Payment events, User events)
> or use a type-safe event bus where routing is determined by event type
> (Spring's `ApplicationEventPublisher` with `@EventListener` typed methods).

*Push deeper:* "CQRS's command bus is Mediator specialized for commands:
one publisher (the application), one handler per command type, one-to-one
routing. It enforces the CQRS convention that commands have exactly one
handler. This is different from domain events (one-to-many routing).
Separating command bus (Mediator, one-to-one) from event bus (Mediator,
one-to-many) is a clean CQRS design."

---

### ⚠️ Common Misconceptions

**Misconception 1: Mediator is only useful for GUI component coordination.**

The GoF example uses GUI form components, but Mediator solves N-to-N coupling between any set of objects that would otherwise reference each other directly. Air traffic control (planes communicate through the tower, not directly), microservice event buses (services emit events to a central broker instead of calling each other's APIs), and chat room systems all use Mediator at different scales. Anywhere you have many objects that need to coordinate and direct references would create a tangled dependency graph, Mediator is applicable.

**Misconception 2: Mediator eliminates all coupling between colleagues.**

Mediator eliminates DIRECT references between colleagues but creates a new coupling: all colleagues depend on the Mediator interface. The Mediator itself knows about all colleagues and contains all coordination logic. This is acceptable when the Mediator encapsulates complex coordination that would otherwise be spread across many colleagues, but if the Mediator knows too much about colleagues' internals, it becomes a God Class. The tradeoff: many small couplings between colleagues vs one centralized coupling hub.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Mediator becomes a God Object as system grows.**

Symptom: Mediator class exceeds 500+ lines, handles dozens of distinct notification types, and is modified for every new feature; unit testing the mediator requires extensive mocking. Root cause: all coordination logic centralized in one class without sub-delegation; Mediator's responsibility grew as more colleagues were added. Diagnosis: count the distinct notification cases the mediator handles; measure test setup complexity. Fix: split the mediator by bounded context (FormValidationMediator, FormSubmissionMediator); or delegate to separate handler classes for each notification type.

**Failure Mode 2: Circular notification cascade causes infinite loop.**

Symptom: stack overflow or infinite loop during Mediator notification; colleague A notifies mediator, which notifies colleague B, which notifies mediator, which notifies colleague A. Root cause: colleague update() method triggers another notification while the first notification is being processed. Diagnosis: add notification depth logging; look for mutual notification triggers. Fix: track whether a notification is in progress (re-entrancy guard); batch notifications and process after all immediate updates complete.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Mediator pattern? How does it reduce coupling?"

🗣️ "Mediator defines an object that encapsulates how a set of objects
interact. Components communicate through the mediator instead of directly.
Without Mediator: N components with N^2/2 pairwise connections. Each new
component requires updating K other components. With Mediator: N components
each with 1 connection to the mediator. Each new component registers with
the mediator only. The mediator knows all routing; components know only
the mediator interface. Spring's `ApplicationEventPublisher` is the
canonical Java implementation: services publish events; listeners react
via `@EventListener`; no service knows any other service."

#### Mechanism
- "Walk me through how Spring's ApplicationEventPublisher
  implements Mediator."

🗣️ "Spring's `SimpleApplicationEventMulticaster` (the default mediator
implementation) maintains a list of `ApplicationListener` beans. When
`publishEvent(event)` is called, the multicaster iterates registered
listeners and calls `onApplicationEvent(event)` on each listener whose
event type matches. `@EventListener` methods are wrapped in
`ApplicationListenerMethodAdapter` objects registered at startup.
The publisher never knows who listens. The listeners subscribe by their
method parameter type (the event type). Adding a new listener: create
a `@Component` with an `@EventListener` method. Spring registers it
automatically. This is Mediator with type-safe routing."

#### Comparison
- "Compare Mediator vs Observer vs Event Bus."

🗣️ "Observer: one Subject, many Observers. The Subject is the publisher.
Observers register directly with the Subject. Subject must know the
Observer interface. One-directional: Subject publishes, Observers react.
Mediator: any component can publish, any can subscribe. No single Subject.
All components know only the Mediator. The Mediator routes based on event
type or sender identity. Event Bus is Mediator with type-based pub/sub:
publishers post event objects; subscribers declare the event type they
handle (method parameter); the bus routes by type. Spring ApplicationEventPublisher
is an Event Bus. MediatR is a Command Bus (Mediator specialized for
one-to-one command routing)."

#### Scenario
- "Design a chat room system using Mediator."

🗣️ "ChatRoom is the Mediator. User is the Component. `ChatRoom` has
`register(user)` and `send(message, sender)`. `User` has a reference to
`ChatRoom`. When a user sends a message: `chatRoom.send(message, this)`.
The ChatRoom mediator receives the message and routes it: iterate all
registered users, call `receive(message, sender)` on each (except the
sender). Adding a ChatBot: implement `User`, register with the chatroom
- it receives all messages and can reply. Adding a moderation filter:
modify `ChatRoom.send()` - the single routing point - to filter messages
before distributing. All users are unaffected. The chatroom is a central
hub; users are components."

#### Debugging
- "Events are not reaching their intended listeners. How do you debug?"

🗣️ "For Spring ApplicationEventPublisher: enable debug logging for
`org.springframework.context.event`. Each event dispatch and listener
invocation is logged. Check: (1) Is the listener bean created? Check
the Spring context for the component. (2) Is the event type matching?
`@EventListener(OrderPlacedEvent.class)` matches exact type; a subclass
event may not match unless the listener declares the parent type.
(3) Is the listener synchronous or async? `@Async @EventListener` may
fail silently if the executor is misconfigured or if exceptions are not
logged. (4) Is there a transaction boundary issue? If the event is
published inside a transaction and the listener uses the same transaction
to read data, the data may not yet be committed."

#### Comparison Table

| Aspect | Mediator | Observer | Event Bus | Command Bus |
|---|---|---|---|---|
| Relationship | Many-to-many | One-to-many | Many-to-many | One-to-one |
| Routing logic | In Mediator | In Subject | By event type | By command type |
| Coupling | Component-Mediator | Observer-Subject | Type-based | Type-based |
| Direction | Bidirectional | Source-to-observer | Bidirectional | Request-Response |
| Spring impl | ApplicationEventPublisher | ApplicationListener | Same | CommandBus |

---

### ⚖️ Comparison Table

| Factor | Mediator | Observer | Facade | Chain of Responsibility |
|---|---|---|---|---|
| Communication | Many-to-many via hub | One-to-many | Caller-to-subsystem | Sequential chain |
| Who knows whom | Components know Mediator | Observers know Subject | Caller knows Facade | Each handler knows next |
| Adding new component | Register with Mediator | Subscribe to Subject | Add to Facade | Insert in chain |
| Routing | Central (Mediator) | Push to all observers | In Facade method | Sequential per handler |
| God Object risk | High (Mediator grows) | Low | Medium (Facade grows) | Low |

---

### 🔥 Field Q&A

**Q: When does a Mediator become a God Object, and how do you fix it?**

A: A Mediator becomes a God Object when its routing logic grows
to know the internals of every component: `if (sender == ComponentA && event == "X") { componentB.doThis(); componentC.setField(value); }`.
Signs: the mediator has hundreds of lines of if/else, it imports every
component class, and changing any component requires changing the mediator.
Fixes: (1) Type-based routing: route by event type, not by component
identity. The mediator looks up registered listeners for the event type.
Spring's ApplicationEventPublisher does this - it never has `if sender == OrderService` logic. (2) Split by domain: `OrderMediator`, `PaymentMediator`,
`UserMediator` - each handles one domain's events. (3) Replace with
domain events: if the "mediator" is routing commands (request/response),
replace with a direct command pattern or explicit service calls.

**Q: How is Mediator used in a CQRS architecture?**

A: In CQRS: the Write side uses a Command Bus (Mediator). Write
operations are command objects (`PlaceOrderCommand`). The caller dispatches
the command to the Command Bus. The Bus routes to the single registered
handler (`PlaceOrderCommandHandler`). The handler processes and emits
domain events. The Read side uses an Event Bus (Mediator). Domain events
published by handlers are routed to projections (query model updaters).
Both buses are Mediator: one-to-one (Command Bus) and one-to-many
(Event Bus). The caller knows neither the handler nor the projections.
This enables full decoupling between the command issuer and the command
processor, and between the event emitter and the read model updaters.

---

# Visitor Pattern

---
id: DP-022
title: Visitor Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: medium
asked_at: Mid+
seniority: mid-senior
tags: #design-patterns, #visitor, #behavioral, #double-dispatch, #ast
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Visitor lets you add operations to a class hierarchy without modifying
> the classes. Instead of adding each new operation to every class,
> you create a Visitor class with a `visit` method for each class in
> the hierarchy. Each element class calls `visitor.visit(this)`, enabling
> double dispatch. It is the pattern for adding operations to stable
> class hierarchies: expression trees, ASTs, XML parsing.

**3 minutes (Senior):**
> Visitor solves the problem of adding new operations to a fixed object
> structure. The classic case: an AST (Abstract Syntax Tree) with many
> node types. Operations needed: type checking, code generation,
> pretty printing, optimization. Without Visitor, each operation is
> spread across all AST node classes. Adding a new operation means
> modifying every node class. With Visitor, each operation is in one
> Visitor class: `TypeCheckVisitor`, `CodeGenVisitor`, `PrintVisitor`.
> Adding a new operation means adding one Visitor class.
>
> The technical mechanism is double dispatch: normal method dispatch
> selects the method based on the receiver's type. Double dispatch selects
> based on both the receiver and the argument type. `element.accept(visitor)`
> dispatches to the correct `accept()` method (based on element type);
> inside `accept()`, `visitor.visit(this)` dispatches to the correct
> `visit()` method (based on `this` type). The result: the method called
> depends on both the element type AND the visitor type.
>
> The trade-off: Visitor makes adding operations easy (add Visitor class)
> but makes adding new element types hard (must add `visit()` to every
> existing Visitor). Use Visitor when the element types are stable and
> operations change. Use Composite/inheritance when operations are stable
> and element types change.

**Blank Mind Recovery:**

**(1) Restate:** "Visitor - the pattern that adds operations to a class
hierarchy by creating Visitor classes instead of modifying the classes."

**(2) First principles:** "Problem: adding a new operation to N classes.
Modifying N files is risky. Solution: create a Visitor class with one
method per class type. Each class calls `visitor.visit(this)`. One file
change for each new operation."

**(3) Bridge:** "Like a tax assessor (Visitor) evaluating different
property types (house, land, commercial). The assessor visits each
property; each property says 'here I am, do your assessment.' Adding
a new assessor (insurance appraiser) doesn't change the properties."

---

### 📘 Concept Explanation

**What it is:**
Visitor represents an operation to be performed on elements of an object
structure. It lets you define a new operation without changing the classes
of the elements on which it operates.

**The problem it solves:**
You have a stable class hierarchy and need to add many different operations
to it over time. Adding each operation as a method to every class spreads
the operation across many files. Visitor centralizes each operation in
one class.

**How it works:**

```
Visitor interface:
  + visitConcreteElementA(element: ConcreteElementA)
  + visitConcreteElementB(element: ConcreteElementB)

ConcreteVisitor1 implements Visitor:
  + visitConcreteElementA(el): // operation 1 on A
  + visitConcreteElementB(el): // operation 1 on B

ConcreteVisitor2 implements Visitor:
  + visitConcreteElementA(el): // operation 2 on A
  + visitConcreteElementB(el): // operation 2 on B

Element interface:
  + accept(visitor: Visitor)

ConcreteElementA implements Element:
  + accept(visitor):
      visitor.visitConcreteElementA(this)  // double dispatch

ConcreteElementB implements Element:
  + accept(visitor):
      visitor.visitConcreteElementB(this)

// Usage:
Element[] elements = {new ConcreteElementA(), new ConcreteElementB()};
Visitor v1 = new ConcreteVisitor1();
for (Element e : elements) {
    e.accept(v1);  // double dispatch selects correct visit()
}
```

**Double dispatch explained:**

Step 1: `element.accept(visitor)` - dispatched by element's runtime type.
Step 2 (inside `accept`): `visitor.visit(this)` - dispatched by visitor's
runtime type AND the element's compile-time type (which is exact inside
`accept`).

Result: the method called is a function of BOTH element type and visitor type.

**The key insight:**
Visitor violates the principle that adding a method to a class should
modify that class. It works around this by moving the method into a
separate Visitor object. The trade-off: element types must be stable,
because adding a new element requires adding `visit(NewType)` to all
existing Visitors.

**When to use it:**
- Many distinct and unrelated operations on an object structure
- The object structure rarely changes (element types are stable)
- Operations on elements of different types that depend on concrete type
- Want to accumulate state across elements during traversal (counters,
  builders)

**When NOT to use it:**
- When the element hierarchy changes frequently (adding a new element
  type breaks all existing Visitors)
- When only one or two operations exist (not worth the pattern overhead)
- In Java 21+: `sealed` classes with `switch` pattern matching often
  replace Visitor more idiomatically

**Alternatives:**
- **Switch with pattern matching (Java 21+)** - `switch (element) { case ConcreteA a -> ...; case ConcreteB b -> ...; }` - more idiomatic
- **Reflection-based dispatch** - single visit method that uses
  `instanceof` - loses type safety
- **Interpreter** - when the object structure is an expression tree
  and operations are evaluations

---

### 💻 Code Example

```java
// Expression tree - classic Visitor use case
// Element hierarchy (stable):
public interface Expression {
    <T> T accept(ExpressionVisitor<T> visitor);
}

public class NumberLiteral implements Expression {
    final double value;
    NumberLiteral(double v) { this.value = v; }

    public <T> T accept(ExpressionVisitor<T> visitor) {
        return visitor.visitNumber(this);  // double dispatch
    }
}

public class Addition implements Expression {
    final Expression left, right;
    Addition(Expression l, Expression r) {
        left = l; right = r;
    }

    public <T> T accept(ExpressionVisitor<T> visitor) {
        return visitor.visitAddition(this);
    }
}

// Visitor interface - one method per element type:
public interface ExpressionVisitor<T> {
    T visitNumber(NumberLiteral n);
    T visitAddition(Addition a);
}

// Operation 1: Evaluate - one Visitor class
public class EvaluateVisitor
        implements ExpressionVisitor<Double> {
    public Double visitNumber(NumberLiteral n) {
        return n.value;
    }
    public Double visitAddition(Addition a) {
        // Recursive: visit sub-expressions
        return a.left.accept(this)
             + a.right.accept(this);
    }
}

// Operation 2: Pretty print - another Visitor class
public class PrintVisitor
        implements ExpressionVisitor<String> {
    public String visitNumber(NumberLiteral n) {
        return String.valueOf(n.value);
    }
    public String visitAddition(Addition a) {
        return "(" + a.left.accept(this)
             + " + " + a.right.accept(this) + ")";
    }
}

// Usage:
Expression expr = new Addition(
    new NumberLiteral(3),
    new Addition(
        new NumberLiteral(4),
        new NumberLiteral(5)));

EvaluateVisitor eval = new EvaluateVisitor();
System.out.println(expr.accept(eval)); // 12.0

PrintVisitor print = new PrintVisitor();
System.out.println(expr.accept(print)); // (3.0 + (4.0 + 5.0))
```

> **Code walkthrough:** Adding a new operation (`TypeCheckVisitor`,
> `OptimizeVisitor`): create one new class implementing `ExpressionVisitor`.
> Zero changes to `NumberLiteral` or `Addition`. The double dispatch:
> `expr.accept(eval)` calls `Addition.accept()` (dispatched by element type).
> Inside, `visitor.visitAddition(this)` calls `EvaluateVisitor.visitAddition()`
> (dispatched by visitor type). Both types resolved: the right method is called.

```java
// Java 21+ alternative: sealed + pattern matching switch
// More idiomatic, eliminates Visitor boilerplate
public sealed interface Expression
    permits NumberLiteral, Addition {}

public record NumberLiteral(double value) implements Expression {}
public record Addition(Expression left, Expression right)
    implements Expression {}

// Operation as a function:
public static double evaluate(Expression expr) {
    return switch (expr) {
        case NumberLiteral n -> n.value();
        case Addition a -> evaluate(a.left())
                         + evaluate(a.right());
    };
}

public static String print(Expression expr) {
    return switch (expr) {
        case NumberLiteral n -> String.valueOf(n.value());
        case Addition a -> "(" + print(a.left())
                         + " + " + print(a.right()) + ")";
    };
}
```

> **Code walkthrough:** Java 21 sealed classes + pattern matching `switch`
> replaces Visitor idiomatically. The `sealed` keyword means the compiler
> knows all subtypes; the exhaustive `switch` checks that all cases are
> covered at compile time. Adding a new element type: add a new `permits`
> subtype. The compiler flags all switch expressions that are now non-
> exhaustive - the safety guarantee Visitor provides manually. This is
> preferred over the Visitor pattern in modern Java.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Visitor lets you add new operations to a class hierarchy without
> modifying the classes. You create a Visitor class with a method for
> each class type in the hierarchy. Each class has an `accept(visitor)`
> method that calls `visitor.visit(this)`. The mechanism is double
> dispatch: the operation selected depends on both the element type and
> the visitor type. Use case: adding operations to a stable class
> hierarchy (AST, expression tree, document object model).

*Push deeper:* "The limitation: if you add a new element type to the
hierarchy, every Visitor must add a new `visit()` method. Visitor
optimizes for adding new operations at the cost of adding new element
types."

---

**Senior / Staff (5+ years):**
> Visitor is essentially a workaround for Java lacking multi-methods.
> In languages with multi-dispatch (Common Lisp, Julia), you simply
> define `(defmethod process ((v TypeCheckVisitor) (e NumberLiteral)) ...)`
> and the runtime picks the right method by both argument types. Java
> picks by the first argument only (the receiver). Visitor implements
> double dispatch by hand using the `accept()` indirection.
>
> In modern Java: sealed classes + pattern matching switch is cleaner
> than Visitor for most cases. The compiler enforces exhaustiveness,
> functions are collocated (all operations on the switch are visible),
> and there is no `accept()` boilerplate. I use the traditional Visitor
> only when the visitor must maintain state across the traversal or when
> the visitor is passed as a parameter through a deep traversal.

*Push deeper:* "AST pattern: most compilers and query optimizers use
Visitor to process their ASTs. Each compiler pass (parsing, semantic
analysis, optimization, code generation) is a Visitor. The AST node
types are stable (they define the language grammar); the operations
(passes) change and grow. This is exactly the Visitor sweet spot:
stable element types, growing operations."

---

### ⚠️ Common Misconceptions

**Misconception 1: Visitor requires modifying element classes whenever a new visitor is added.**

Visitor's key property is the OPPOSITE: new VISITORS (operations) can be added WITHOUT modifying elements. The tradeoff is that adding a new ELEMENT type requires modifying all existing visitors. This is the expression problem: Visitor optimizes for adding new operations over a fixed set of types. If your set of types is stable but you frequently add new operations (reports, formatters, validators), Visitor is ideal. If your set of operations is stable but you frequently add new types, Visitor creates high maintenance cost.

**Misconception 2: Visitor requires double dispatch in all languages.**

Double dispatch (element calls `visitor.visit(this)` so the visitor method resolves to the correct overload for the concrete element type) is the standard implementation in languages without multiple dispatch (Java, C++). In languages with multiple dispatch (Common Lisp, Clojure multimethods, Julia) or pattern matching (Haskell, Scala), Visitor-like behavior is built into the type system without the double-dispatch ceremony. Languages with pattern matching can express Visitor as a `match (element)` expression without any visitor interface.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Visitor breaks when new element types are added without updating all visitors.**

Symptom: `UnsupportedOperationException` at runtime when a visitor encounters a new element type; or silent incorrect behavior if the visitor falls back to a parent class `visit()` method. Root cause: element hierarchy extended with a new concrete type but not all visitor implementations were updated. Diagnosis: check if the element hierarchy has a new concrete type added recently; search for visitor implementations missing the corresponding `visit(NewElement)` overload. Fix: make the Visitor interface's `visit(NewElement)` method abstract (not default), ensuring compile-time failure when a new element type is added without updating visitors.

**Failure Mode 2: Visitor accessing internal state breaks encapsulation.**

Symptom: visitor operations require access to private element fields not exposed via public API; developers add getters just for visitors, polluting the element's public API. Root cause: visitor operations need data that the element correctly keeps private. Diagnosis: count getters added specifically for visitor use. Fix: pass visitor context objects rather than returning raw internal state; use a "report" or "accept visitor context" approach where the element populates a context object with the data the visitor needs without exposing raw fields.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Visitor pattern? What problem does it solve?"

🗣️ "Visitor lets you add new operations to a stable class hierarchy
without modifying the class hierarchy. Without Visitor: adding an operation
means adding a method to every class in the hierarchy (N file changes).
With Visitor: adding an operation means adding one Visitor class. The
element hierarchy stays unchanged. The key enabling mechanism: double
dispatch. Each element class has `accept(visitor)` that calls
`visitor.visit(this)`. This ensures the correct overloaded `visit()`
method is called based on the element's concrete type, even when the
element is accessed through a base interface."

#### Mechanism
- "Explain double dispatch in the Visitor pattern."

🗣️ "Normal Java dispatch: when you call `element.accept(visitor)`,
Java looks at the runtime type of `element` and calls the correct
`accept()` method. Inside `accept()`, `this` has the compile-time
type of the concrete class (e.g., `ConcreteElementA`). So when
`visitor.visit(this)` is called, Java can select the overloaded
`visitConcreteElementA(this)` based on the compile-time type of `this` -
which is the exact concrete type. This is why the dispatch works:
first dispatch selects the `accept()` method based on element type.
Second dispatch selects the `visit()` overload based on the element's
exact type (now known as the compile-time type inside `accept()`)."

#### Comparison
- "Compare Visitor vs adding methods to the element classes."

🗣️ "Adding methods directly to element classes: each operation is
spread across all classes in the hierarchy. N element types, M operations:
each class has M methods. Adding a new operation: M file changes.
Adding a new element type: 1 file (new class). Visitor: each operation
is in one Visitor class. N element types, M operations: M Visitor
classes, N `accept()` methods. Adding a new operation: 1 file (new Visitor).
Adding a new element type: M file changes (add `visit()` to each Visitor).
The trade-off is called the Expression Problem: easily extensible in
operations XOR easily extensible in types. Visitor solves extensibility
in operations; inheritance solves extensibility in types."

#### Scenario
- "Design a Visitor-based export system for an invoice object model."

🗣️ "Invoice object model: `Invoice` (contains `LineItem`s), `LineItem`
(contains `Product` and `Discount`). These are the element types.
Operations: export to PDF, export to JSON, export to XML, compute tax.
Without Visitor: 4 operations * 4 element types = 16 methods scattered
across 4 classes. With Visitor: 4 `InvoiceVisitor` implementations
(`PdfExportVisitor`, `JsonExportVisitor`, `XmlExportVisitor`,
`TaxComputeVisitor`), each with 4 visit methods. Adding a new export
format: one new Visitor class. Adding a new element type (Surcharge):
add `visitSurcharge()` to all 4 visitors - but invoice structures are
stable; export formats are not. Good Visitor fit."

#### Debugging
- "A Visitor is calling the wrong visit() method. How do you investigate?"

🗣️ "This is almost always a missing or incorrect `accept()` method.
If a subclass does not override `accept()` and inherits the parent's
`accept()`, the parent's `visit(ParentType)` is called instead of
`visit(SubclassType)`. Log which `accept()` is invoked: add a log statement
in every `accept()` method showing `this.getClass().getSimpleName()`.
Compare the logged class to the `visit()` method that was called. If they
don't match: the element's `accept()` is calling `visitor.visit(this)`
with the wrong `this` (inherited from parent). Fix: override `accept()`
in every concrete class without exception - never rely on inheritance for
`accept()`."

#### Comparison Table

| Aspect | Visitor | Strategy | Decorator | Template Method |
|---|---|---|---|---|
| Primary goal | New operations on stable hierarchy | Algorithm swap | Add behavior | Algorithm skeleton |
| Where operation lives | Visitor class | Strategy class | Wrapper class | Base class |
| Dispatch type | Double (element + visitor) | Single (context + strategy) | Single (wrapper + wrapped) | Single (base + override) |
| Element modification | None (accept() only) | None | None | Yes (adds methods) |
| Adding element types | Costly (all Visitors) | N/A | N/A | Subclass |

---

### ⚖️ Comparison Table

| Factor | Visitor | Switch (instanceof) | Strategy | Composite |
|---|---|---|---|---|
| Type safety | Yes (compile-time exhaustiveness via Visitor interface) | Not exhaustive by default | N/A | Yes |
| Adding new operation | 1 class | 1 switch block | 1 class | 1 method per element |
| Adding new element type | N visitors (breaking) | 1 case per switch | N/A | 1 new class |
| State during traversal | Yes (visitor accumulates) | Requires external state | N/A | Via return value |
| Modern Java alternative | Sealed + pattern switch | Pattern switch (Java 21) | Functional interface | N/A |

---

### 🔥 Field Q&A

**Q: How does the Visitor pattern interact with the Composite pattern?**

A: Composite defines the tree structure (each node has an `accept(Visitor)`
method); Visitor defines operations on the tree. The canonical combination:
`CompositeNode.accept(visitor)` calls `visitor.visitComposite(this)`
and then iterates children, calling `child.accept(visitor)` for each.
The visitor accumulates results (or side effects) across the entire tree.
This is how compilers work: the AST is a Composite. Compiler passes
(type checker, optimizer, code generator) are Visitors. Each pass
traverses the entire tree. The traversal order (pre-order, post-order)
is controlled by where in the `accept()` method you call children's
`accept()` - before or after the visit call.

**Q: In Java 21, when would you still use the Visitor pattern over
sealed classes with pattern matching?**

A: Use Visitor when: (1) The visitor must maintain state across the
traversal (e.g., a `SymbolTableVisitor` that builds a symbol table while
visiting each declaration - the state is accumulated in the Visitor object).
(2) The visitor is passed as a parameter through a deep recursive traversal
(all nodes use the same visitor instance). (3) You need to support
different traversal strategies (depth-first, breadth-first) with the same
operations - the Visitor decouples the operation from the traversal order.
(4) The hierarchy is in a library you cannot modify with sealed - you add
`accept()` once, and visitors are added externally. For most new code in
Java 21+: sealed + pattern switch is cleaner, more concise, and the
compiler enforces exhaustiveness at compile time without boilerplate.
