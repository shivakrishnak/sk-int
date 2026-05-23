# Design Principles Interview Guide

## 1. Overview
At Staff+ level, you are expected to apply design principles as a **system of checks and balances**—not as rules, but as guidelines for creating maintainable, scalable, and testable software. Interviewers will probe your ability to:
- **Recognize and articulate** underlying design forces
- **Make conscious trade-offs** between competing principles (e.g., DRY vs. KISS vs. YAGNI)
- **Lead architectural decisions** grounded in SOLID, Separation of Concerns, and other core principles
- **Identify violations** in code reviews and mentor teams toward better design

This guide covers the most influential design principles, each with a textbook definition, a plain-English explanation, the “why”, “how”, and “when not to use”, plus code examples.

## 2. Deep Dive into Key Principles

### 2.1 SOLID Principles

#### 2.1.1 Single Responsibility Principle (SRP)
- **Textbook Definition**: A class should have only one reason to change (Robert C. Martin).
- **Simple Explanation**: Each class should do one thing and do it well. If a class mixes concerns (e.g., business rules and database access), a change in one area can break the other.
- **Why used**: Improves maintainability, testability, and reduces coupling. Classes that do one thing are easier to understand, reuse, and refactor.
- **How used**: Identify all responsibilities; extract each into a separate class. Use facade or delegation if needed.
- **When not to use**: Over-zealous splitting into nano-classes can lead to excessive indirection and “class explosion”. If a responsibility is trivial and stable, merge it.
- **Pros**:
  - Clear boundaries, easier testing.
  - Reduced impact of change.
- **Cons**:
  - More classes and files.
  - May increase initial design complexity.

**Code Example** (violation → compliant):
```java
// Violation: Employee manages both data and persistence
class Employee {
    private String name;
    private double salary;
    public void save() { /* JDBC to save employee */ }
    public double calculateTax() { /* tax logic */ }
}

// SRP compliant: separate persistence and tax calculation
class Employee {
    private String name;
    private double salary;
    // getters/setters
}
class EmployeeRepository {
    public void save(Employee e) { /* JDBC */ }
}
class TaxCalculator {
    public double calculateTax(Employee e) { /* tax logic */ }
}
```

#### 2.1.2 Open/Closed Principle (OCP)
- **Textbook Definition**: Software entities (classes, modules, functions) should be open for extension, but closed for modification.
- **Simple Explanation**: You should be able to add new behavior without changing existing source code. Use polymorphism, strategies, plugins.
- **Why used**: Prevents regression bugs when adding features; enables stable interfaces and easy scaling.
- **How used**: Depend on abstractions (interfaces, abstract classes). Use patterns like Strategy, Decorator, Template Method. Add new implementations instead of modifying existing code.
- **When not to use**: If the domain is extremely stable and no extensions are foreseeable, over-engineering with abstractions may be unnecessary. Over-application can lead to premature complexity.
- **Pros**:
  - Robustness, minimal side-effects on existing code.
  - Encourages reusable, composable components.
- **Cons**:
  - Increased number of abstractions.
  - Can be misapplied if extension points are guessed wrong.

**Code Example** (shipping cost calculator):
```java
// Violation: adding a new shipping method requires modifying the class
class ShippingCost {
    double calculate(String method, double weight) {
        if ("AIR".equals(method)) return weight * 5;
        else if ("GROUND".equals(method)) return weight * 2;
        else if ("SEA".equals(method)) return weight * 1; // added, modified class
        throw new IllegalArgumentException();
    }
}

// OCP compliant: use strategy pattern
interface ShippingStrategy { double cost(double weight); }
class AirShipping implements ShippingStrategy { public double cost(double w) { return w * 5; } }
class GroundShipping implements ShippingStrategy { public double cost(double w) { return w * 2; } }
class ShippingCost {
    double calculate(ShippingStrategy strategy, double weight) { return strategy.cost(weight); }
}
```

#### 2.1.3 Liskov Substitution Principle (LSP)
- **Textbook Definition**: Subtypes must be substitutable for their base types without altering the correctness of the program (Barbara Liskov).
- **Simple Explanation**: A derived class should extend behavior without breaking the contract of the base class. It should not throw unexpected exceptions, tighten preconditions, or weaken postconditions.
- **Why used**: Guarantees that code written against a base class works with any subclass, essential for polymorphism and frameworks.
- **How used**: Design by contract; ensure overridden methods adhere to same invariants. Avoid overriding methods to throw `UnsupportedOperationException`. Use composition if substitution is impossible.
- **When not to use**: If a subclass cannot truly substitute, inheritance should not be used; prefer composition.
- **Pros**:
  - Reliable polymorphic behavior.
  - Safe code reuse via inheritance.
- **Cons**:
  - Misuse leads to fragile hierarchies when violated.
  - Requires strict discipline in contract definition.

**Code Example** (classic rectangle-square problem):
```java
// Violation: Square extends Rectangle but breaks setWidth/setHeight contract
class Rectangle {
    protected int width, height;
    public void setWidth(int w) { width = w; }
    public void setHeight(int h) { height = h; }
    public int area() { return width * height; }
}
class Square extends Rectangle {
    public void setWidth(int w) { width = w; height = w; } // silently changes height
    public void setHeight(int h) { width = h; height = h; } // violates Rectangle's behavior
}

// LSP compliant: don't use inheritance for incompatible types
interface Shape { int area(); }
class Rectangle implements Shape { ... } // no Square inheriting
class Square implements Shape { ... }
```

#### 2.1.4 Interface Segregation Principle (ISP)
- **Textbook Definition**: Clients should not be forced to depend on interfaces they do not use.
- **Simple Explanation**: Prefer small, focused interfaces over fat, monolithic ones. A class should not need to implement methods it doesn't need.
- **Why used**: Reduces coupling, avoids unnecessary dependencies, increases cohesion.
- **How used**: Split large interfaces into role-specific ones. Clients depend only on the interfaces relevant to them.
- **When not to use**: Over-segmenting can lead to an explosion of tiny interfaces with only one method, adding complexity. Balance with cohesion.
- **Pros**:
  - Decouples components, easier to implement and mock.
  - Clear contracts.
- **Cons**:
  - Interface proliferation might make discovery harder.
  - May increase the number of types.

**Code Example**:
```java
// Violation: fat interface
interface Worker {
    void work();
    void eat();
    void sleep();
}
class Robot implements Worker {
    public void work() { /* ... */ }
    public void eat() { throw new UnsupportedOperationException(); } // not needed
    public void sleep() { throw new UnsupportedOperationException(); } // not needed
}

// ISP compliant: segregated
interface Workable { void work(); }
interface Eatable { void eat(); }
interface Sleepable { void sleep(); }
class Human implements Workable, Eatable, Sleepable { ... }
class Robot implements Workable { ... }
```

#### 2.1.5 Dependency Inversion Principle (DIP)
- **Textbook Definition**: High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details. Details should depend on abstractions.
- **Simple Explanation**: Depend on interfaces, not on concrete implementations. Invert the direction of dependencies so that high-level policy is not tied to low-level details like database or network.
- **Why used**: Decouples core business logic from infrastructure, enabling easy testing and replacement of components.
- **How used**: Define interfaces in the high-level module. Low-level modules implement those interfaces. Use dependency injection to wire them.
- **When not to use**: For very small applications or scripts where DI adds overhead without benefit. Also, if a low-level module is stable and never changes, direct dependency might be acceptable.
- **Pros**:
  - Testability (mocking), flexibility, clean architecture.
  - High-level policy is protected from change.
- **Cons**:
  - More interfaces and indirection.
  - Requires discipline and tooling.

**Code Example**:
```java
// Violation: high-level OrderService directly depends on MySQLDatabase
class OrderService {
    private MySQLDatabase db = new MySQLDatabase();
    public void save(Order o) { db.save(o); }
}
// DIP compliant:
interface Database { void save(Order o); }
class MySQLDatabase implements Database { public void save(Order o) { /*...*/ } }
class OrderService {
    private Database db;
    public OrderService(Database db) { this.db = db; } // injected
    public void save(Order o) { db.save(o); }
}
```

### 2.2 DRY (Don't Repeat Yourself)
- **Textbook Definition**: Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.
- **Simple Explanation**: Avoid duplicating code, logic, or configuration. Reuse abstractions.
- **Why used**: Reduces maintenance burden; a change should happen in one place.
- **How used**: Extract common code into methods, classes, or modules. Use utilities, base classes, or composition. Parameterize.
- **When not to use**: Premature abstraction can couple unrelated things. If repetition is coincidental (not same knowledge), forcing DRY can make code rigid. Also, microservices may duplicate code intentionally to avoid coupling.
- **Pros**:
  - Single source of truth.
  - Easier to maintain and less error-prone.
- **Cons**:
  - Over-abstraction leads to tangled code.
  - Performance impact if abstracted too many layers.

**Code Example**:
```java
// Repetition
double priceWithTax(double price) { return price * 1.2; }
double priceWithDiscount(double price) { return price * 0.9; }

// DRY: extract tax rate constant, use functions
final double TAX_RATE = 0.2;
double applyTax(double price) { return price * (1 + TAX_RATE); }
double applyDiscount(double price, double discount) { return price * (1 - discount); }
```

### 2.3 KISS (Keep It Simple, Stupid)
- **Textbook Definition**: Most systems work best if they are kept simple rather than made complicated; therefore, simplicity should be a key goal.
- **Simple Explanation**: Prefer straightforward solutions over intricate ones. Avoid unnecessary complexity.
- **Why used**: Simpler code is easier to understand, debug, and modify. Reduces cognitive load.
- **How used**: Choose the simplest data structures, algorithms, and design that satisfy requirements. Refactor complex code into small, clear pieces.
- **When not to use**: When simplicity sacrifices essential performance, security, or scalability that is truly required (e.g., a simple brute-force algorithm might be too slow).
- **Pros**:
  - Faster development and fewer bugs.
  - Easier onboarding.
- **Cons**:
  - Might need refactoring later as requirements grow (but that’s acceptable).

**Code Example**:
```java
// Complex
public boolean isEven(int x) { return (x & 1) == 0 ? true : false; }
// KISS: use clear expression
public boolean isEven(int x) { return x % 2 == 0; }
```

### 2.4 YAGNI (You Ain't Gonna Need It)
- **Textbook Definition**: Always implement things when you actually need them, never when you just foresee that you need them.
- **Simple Explanation**: Don't build features, hooks, or flexibility until they are required. Extend only as necessary.
- **Why used**: Saves time, reduces complexity, avoids maintaining unused code.
- **How used**: During design, resist adding extra parameters, extension points, or unused features. Refactor when needed.
- **When not to use**: When the cost of adding later would be extremely high (e.g., database schema changes, public API changes)—sometimes planning for known upcoming needs is wise.
- **Pros**:
  - Lean codebase, less waste.
  - Faster iterations.
- **Cons**:
  - Risk of expensive refactoring if foreseen requirements eventually arrive (but usually less than expected).

**Code Example**:
```java
// Over-engineered with future hook
class OrderProcessor {
    private PaymentGateway payment;
    private NotificationService notification; // not needed yet
    private FutureExpansion expansion; // YAGNI violation
    public void process(Order order) { payment.charge(order); }
}
// YAGNI: start simple
class OrderProcessor {
    private PaymentGateway payment;
    public void process(Order order) { payment.charge(order); }
}
```

### 2.5 Separation of Concerns (SoC)
- **Textbook Definition**: A design principle for separating a computer program into distinct sections, such that each section addresses a separate concern.
- **Simple Explanation**: Organize code by its responsibilities (UI, business logic, data access). Don't mix them.
- **Why used**: Increases modularity, testability, and maintainability.
- **How used**: Layered architecture (MVC, MVVM), bounded contexts, microservices. Each layer/module focuses on one aspect.
- **When not to use**: Over-separation into too many layers without need adds complexity. In very small programs, it might be overkill.
- **Pros**:
  - Loose coupling, high cohesion.
  - Easier to evolve or replace parts.
- **Cons**:
  - Increased number of modules and integration code.
  - Potential performance overhead due to inter-layer communication.

**Code Example**:
```java
// Violation: UI mixes logic and data access
class UserController {
    void register(String name) {
        // validate
        // directly SQL insert
        Connection conn = ...;
        // send email inside
    }
}
// SoC compliant: separate Controller, Service, Repository
class UserController { void register(String name) { userService.register(name); } }
class UserService { void register(String name) { ... } }
class UserRepository { void save(User u) { ... } }
```

### 2.6 Law of Demeter (Principle of Least Knowledge)
- **Textbook Definition**: Only talk to your immediate friends; don't talk to strangers.
- **Simple Explanation**: A method of an object should only call methods of:
  - itself
  - its parameters
  - objects it creates
  - its direct component objects
  Avoid chain calls like `a.getB().getC().doSomething()`.
- **Why used**: Reduces coupling, helps with encapsulation, makes code less brittle.
- **How used**: Instead of chaining, introduce wrapper methods that delegate internally. Or use DTOs.
- **When not to use**: If chaining is shallow and stable, strict adherence might lead to many pass-through methods and verbosity. Judicious use is fine.
- **Pros**:
  - More resilient to internal structure changes.
  - Better encapsulation.
- **Cons**:
  - Can lead to too many wrapper methods, increasing class size.
  - Might reduce readability of fluent APIs.

**Code Example**:
```java
// Violation: chain getting deep
String city = order.getCustomer().getAddress().getCity();

// Law of Demeter compliant: give order method
class Order {
    private Customer customer;
    public String getCustomerCity() { return customer.getAddressCity(); }
}
String city = order.getCustomerCity();
```

### 2.7 Composition Over Inheritance
- **Textbook Definition**: Favor object composition over class inheritance to achieve polymorphic behavior and code reuse.
- **Simple Explanation**: Instead of inheriting behavior from a parent class, combine simple, focused objects (strategies, delegates). It gives more flexibility and avoids tight coupling.
- **Why used**: Inheritance creates a static relationship; composition allows dynamic change of behavior at runtime, easier testing, and avoids deep hierarchies.
- **How used**: Define interfaces for the behaviors; the main class holds references to them and delegates. For example, a `Duck` may have `FlyBehavior` and `QuackBehavior` interfaces, composed at construction.
- **When not to use**: When there is a clear “is-a” relationship and the base class is stable, simple inheritance might be sufficient. Over-engineering with composition for trivial cases adds complexity.
- **Pros**:
  - Greater flexibility, easier to swap implementations.
  - Promotes better separation of concerns.
- **Cons**:
  - More boilerplate; many small objects.
  - Debugging can be harder due to delegation.

**Code Example**:
```java
// Inheritance
class Animal { void eat() { ... } }
class Bird extends Animal { void fly() { ... } }
class Dog extends Animal { } // Cannot fly, but might not need it. Still, if Bird needs swim, hierarchy deepens.

// Composition
interface FlyBehavior { void fly(); }
class FlyWithWings implements FlyBehavior { public void fly() { ... } }
class CantFly implements FlyBehavior { public void fly() { ... } }
class Bird {
    private FlyBehavior flyBehavior;
    public Bird(FlyBehavior fb) { this.flyBehavior = fb; }
    void performFly() { flyBehavior.fly(); }
}
// Ducks can use different fly behaviors at runtime.
```

### 2.8 Principle of Least Astonishment (POLA)
- **Textbook Definition**: A component should behave in a way that most users will expect it to behave; it should not “astonish” them.
- **Simple Explanation**: Design APIs, functions, and UIs so they are consistent with common conventions and intuition. Avoid surprises like a method that returns null when undocumented, or unpredictable side effects.
- **Why used**: Usability, reduce bugs due to misunderstanding.
- **How used**: Follow naming conventions, return predictable types, adhere to established patterns (like JavaBeans getters/setters). Document any non-obvious behavior.
- **When not to use**: Sometimes a trade-off with performance might require an unusual API; still, document clearly.
- **Pros**:
  - Lower learning curve, fewer errors.
- **Cons**:
  - Might limit innovative designs if rigidly enforced.

**Code Example**:
```java
// Astonishing: getById returns null, but caller expects always a User.
User user = userRepo.getById(id); // could be null, and cause NPE later.
// Better: return Optional or throw specific exception, aligning with expectation.
Optional<User> user = userRepo.findById(id);
```

### 2.9 Tell, Don't Ask
- **Textbook Definition**: Rather than asking an object for data and acting on that data, tell the object what to do.
- **Simple Explanation**: Encourage an object to contain its own logic instead of exposing its internal state for others to manipulate. Moves behavior to the data.
- **Why used**: Improves encapsulation, reduces coupling, makes code more object-oriented.
- **How used**: Instead of `if (user.getAge() > 18) ...`, have `user.isAdult()`.
- **When not to use**: When the operation truly doesn’t belong to the object (e.g., formatting a report), asking is fine.
- **Pros**:
  - Better encapsulation.
  - Fewer getter-frequent procedural-style code.
- **Cons**:
  - Possibility of bloated objects if too many operations are added.

**Code Example**:
```java
// Asking
if (order.getStatus() == Status.PAID && order.getAmount() > 0) { ship(order); }
// Telling
if (order.isReadyToShip()) { order.ship(); }
```

### 2.10 Design by Contract
- **Textbook Definition**: Software designers should define formal, precise and verifiable interface specifications for software components, which extend the ordinary definition of abstract data types with preconditions, postconditions and invariants.
- **Simple Explanation**: Methods specify what they expect (preconditions) and what they guarantee (postconditions). Invariants are properties that remain true. Violations indicate bugs.
- **Why used**: Clear contracts help catch errors early, document assumptions, improve reliability.
- **How used**: Use assertions, `Objects.requireNonNull`, validation frameworks, documentation. In Java, `@NonNull` annotations, `assert`, and checks.
- **When not to use**: Over-using contracts in performance-critical code might add overhead; choose critical modules. Also, not all languages have native support.
- **Pros**:
  - Early failure, clear blame assignment.
  - Self-documenting code.
- **Cons**:
  - Potential runtime overhead.
  - Can be verbose.

**Code Example**:
```java
public class Stack {
    private List<String> items = new ArrayList<>();
    /**
     * @throws IllegalStateException if stack is empty
     */
    public String pop() {
        if (items.isEmpty()) throw new IllegalStateException("Cannot pop empty stack");
        return items.remove(items.size() - 1);
    }
    public void push(String item) { items.add(Objects.requireNonNull(item)); }
}
```

## 3. Putting Principles Together
- Principles often complement each other (SRP + SoC + Composition). But there are tensions: DRY vs. YAGNI (premature abstraction) or KISS vs. Design Patterns (over-engineering).
- A Staff Architect balances them: For a critical authentication module, you might invest in strict contracts and OCP; for a simple internal tool, KISS and YAGNI dominate.
- Anti-patterns: “SOLID overdose” leading to hundreds of tiny interfaces; “DRY madness” coupling unrelated code. Always evaluate context.
- Use Architecture Decision Records (ADRs) to document why a principle was applied or traded off.

## 4. Interview Intelligence
### Topic: How would you apply SOLID principles to a legacy monolithic application?

#### ❌ Mid-level Answer
“I’ll refactor the entire codebase to follow SRP, extract interfaces for DIP, use ISP, etc.”

#### ✅ Senior Answer
“I focus on the parts that change most. For instance, if we need to support a new payment gateway, I’ll extract an interface (OCP, DIP) and create a strategy. I ensure new features follow SOLID; existing code refactored gradually. I introduce ISP by splitting fat services as needed.”

#### 🚀 Staff-level Answer
“I treat principles as a guide, not a dogmatic checklist. I start by identifying the most painful coupling points. For a monolithic order management, I’d apply DIP to invert the dependency on the database, extracting a repository interface, enabling testability. Then I’d ensure OCP for shipping strategies. Meanwhile, I coach the team on SRP: we split a bloated `OrderService` into `OrderPlacementService`, `OrderFulfillmentService`, each with single responsibility. I introduce LSP awareness by forbidding inheritance for code reuse; we favor composition. I measure maintainability index and track regression to ensure refactoring doesn’t introduce bugs. I prioritize based on business need and risk, not purity.”

## 5. High ROI Questions
- Explain the Single Responsibility Principle with a real-world example where its violation caused a production incident.
- How do you balance DRY and KISS when designing a new feature?
- Give an example where you intentionally broke a SOLID principle. Why?
- What is the difference between Dependency Inversion and Dependency Injection?
- How do you enforce OCP in a microservice architecture?
- Describe a scenario where Composition Over Inheritance saved your project.
- What is a common LSP violation and how would you detect it?
- Explain Law of Demeter and when you would ignore it.
- How do you teach design principles to junior developers?
- What are the pitfalls of over-applying SOLID?

**Tricky Follow-ups:**
- “You have a class with 10 methods. Is it automatically violating SRP?”
- “How does ISP apply to REST API design?”
- “Can you write a test that proves a subclass violates LSP?”

## 6. Cheat Sheet (Revision)
- **SRP**: One reason to change.
- **OCP**: Open for extension, closed for modification.
- **LSP**: Subtypes must be substitutable.
- **ISP**: No client should be forced to depend on unused methods.
- **DIP**: Depend on abstractions, not concretions.
- **DRY**: Don’t duplicate knowledge.
- **KISS**: Keep it simple.
- **YAGNI**: Don’t build what you don’t need.
- **SoC**: Separate concerns into distinct modules.
- **LoD**: Only talk to friends.
- **Composition > Inheritance**: Prefer object composition for flexibility.
- **Design by Contract**: Explicit pre/postconditions and invariants.

---

### 🎤 Communication Training
- “When I design, I think about what will change and encapsulate it (OCP). I make sure my classes have a single job (SRP) and depend on interfaces, not details (DIP). Simplicity (KISS) comes first; I add complexity only when proven necessary (YAGNI). I often use composition to avoid fragile hierarchies.”

### 📈 Personalised Self-Assessment (12 YOE)
- **Strong**: likely you apply SOLID concepts naturally; DRY and KISS are daily habits.
- **Hidden gaps**: You may over-apply principles (especially OCP and ISP) leading to over-engineered code. Might not formally apply Design by Contract. The Law of Demeter might be followed without conscious thought but could be violated in deep chain calls.
- **Overconfidence risks**: Assuming following all principles always yields good design; ignoring context and trade-offs. Forgetting that principles are guidelines, not laws.

Proceed to remaining topics when ready.
