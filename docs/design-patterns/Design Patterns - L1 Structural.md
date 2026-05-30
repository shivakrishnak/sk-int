---
layout: default
title: "Design Patterns - L1 Structural"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 3
permalink: /design-patterns/l1-structural/
render_with_liquid: false
---

# Decorator Pattern

---
id: DP-007
title: Decorator Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #design-patterns, #decorator, #structural, #composition, #open-closed
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Decorator attaches additional responsibilities to an object dynamically
> without subclassing. Both the decorator and the wrapped object implement
> the same interface; the decorator delegates to the wrapped object and
> adds behavior before or after. It follows the principle "favor composition
> over inheritance": instead of N subclasses for N behavior combinations,
> you compose N decorators at runtime.

**3 minutes (Senior):**
> The inheritance alternative to Decorator explodes exponentially. If you
> have a `Coffee` class and want to support milk, sugar, and vanilla as
> add-ons: you need Milk, Sugar, Vanilla, MilkAndSugar, MilkAndVanilla,
> SugarAndVanilla, MilkSugarAndVanilla subclasses. Seven subclasses for
> three add-ons. With Decorator: three Decorator classes, any combination
> assembled at runtime.
>
> Production examples are everywhere. Java I/O is built on Decorator:
> `new BufferedReader(new InputStreamReader(new FileInputStream(file)))`
> is three decorators stacked. `BufferedReader` adds buffering to any
> `Reader`. `InputStreamReader` adapts bytes to chars. `FileInputStream`
> reads raw bytes. Spring Security uses Decorator chains for request
> filtering. Spring AOP adds behavior to beans via Decorator (Proxy).

**Blank Mind Recovery:**

**(1) Restate:** "Decorator - the pattern that adds behavior to objects
without subclassing."

**(2) First principles:** "Problem: I need to add behavior to an object
but not to every object of its class. Subclassing adds it to all objects.
Solution: wrap the specific object in another object that adds the behavior."

**(3) Bridge:** "Like a gift box: the box (decorator) wraps the present
(original object) and adds a bow. Both 'are a gift' - same interface.
You can wrap the box in another box to add more bows."

---

### 📘 Concept Explanation

**What it is:**
Decorator wraps an object with another object implementing the same
interface, adding behavior before or after delegating to the wrapped object.

**The problem it solves:**
Adding behavior to individual objects without modifying their class, and
doing so in a composable way. Subclassing adds behavior to all instances
of a class and cannot be composed without class explosion.

**How it works:**

```
Component interface: both Concrete and Decorators implement this
  + operation(): Result

ConcreteComponent: the real thing
  + operation(): does the actual work

Decorator (abstract): wraps a Component
  - component: Component  (the wrapped object)
  + operation():
      return component.operation()  (delegates)

ConcreteDecoratorA: adds behavior A
  + operation():
      before behavior A
      result = component.operation()  (delegates)
      after behavior A
      return result

ConcreteDecoratorB: adds behavior B
  + operation(): similar

// Composing at runtime:
Component c = new ConcreteDecorator(  // outer
                new ConcreteDecoratorB(   // middle
                  new ConcreteComponent())); // inner
```

**The key insight:**
The Decorator implements the same interface as the object it wraps. This
means a Decorator can wrap another Decorator - they compose naturally.
Adding new behavior is creating a new Decorator class, not a new subclass.
This is Open/Closed Principle: the `ConcreteComponent` is never modified.

**When to use it:**
- Adding responsibilities to individual objects without affecting others
- When a combination of behaviors is needed (any-order composability)
- When subclassing for every combination is impractical

**When NOT to use it:**
- When the object's identity matters (Decorator changes the object's type
  from the caller's perspective - `instanceof` checks fail)
- When the number of decorators is large and composition order is complex
- When a framework already provides the decoration mechanism (Spring AOP,
  servlet filters)

**Alternatives:**
- **Inheritance** - for fixed, small hierarchies; breaks for many
  behavior combinations
- **Spring AOP / Proxies** - framework-level Decorator for
  cross-cutting concerns
- **Functional composition** - in functional code, wrap functions
  rather than objects

**First-principles derivation:**
Given: an object that needs additional behavior for specific instances.
Subclassing affects all instances of the class. Direct mutation modifies
the object permanently. Solution: wrap the object in another object with
the same interface - the wrapper adds behavior, the original is unchanged.

---

### 💻 Code Example

```java
// BAD: inheritance for behavior combinations
public class Coffee { double cost() { return 1.0; } }
public class CoffeeWithMilk extends Coffee {
    double cost() { return super.cost() + 0.25; }
}
public class CoffeeWithSugar extends Coffee {
    double cost() { return super.cost() + 0.10; }
}
public class CoffeeWithMilkAndSugar extends CoffeeWithMilk {
    double cost() { return super.cost() + 0.10; }
}
// grows as 2^N combinations - 3 add-ons = 8 classes
```

> **Code walkthrough:** Three add-ons require eight subclasses. Four
> add-ons require sixteen. This is the class explosion problem. No
> runtime combination is possible - a latte with milk and sugar is a
> fixed class, not a composition.

```java
// GOOD: Decorator pattern
public interface Coffee {
    double cost();
    String description();
}

public class SimpleCoffee implements Coffee {
    public double cost() { return 1.0; }
    public String description() { return "Coffee"; }
}

// Abstract decorator
public abstract class CoffeeDecorator implements Coffee {
    protected final Coffee delegate;
    CoffeeDecorator(Coffee coffee) { this.delegate = coffee; }
}

public class MilkDecorator extends CoffeeDecorator {
    public MilkDecorator(Coffee coffee) { super(coffee); }

    public double cost() {
        return delegate.cost() + 0.25;
    }

    public String description() {
        return delegate.description() + ", Milk";
    }
}

public class SugarDecorator extends CoffeeDecorator {
    public SugarDecorator(Coffee coffee) { super(coffee); }

    public double cost() {
        return delegate.cost() + 0.10;
    }

    public String description() {
        return delegate.description() + ", Sugar";
    }
}

// Runtime composition - any combination without new classes:
Coffee latte = new MilkDecorator(new SimpleCoffee());
Coffee sweetLatte = new SugarDecorator(
    new MilkDecorator(new SimpleCoffee()));
Coffee doubleSugar = new SugarDecorator(
    new SugarDecorator(new SimpleCoffee()));
```

> **Code walkthrough:** Three classes support all combinations: any
> number of add-ons, in any order, applied at runtime. `SugarDecorator`
> wraps any `Coffee` - including another `SugarDecorator` (double sugar).
> Each decorator adds one responsibility cleanly. Adding a `VanillaDecorator`
> class does not touch any existing code.

```java
// PRODUCTION: Java I/O is built on Decorator
// Reading a gzip-compressed, buffered file line by line:
try (BufferedReader reader = new BufferedReader(
        new InputStreamReader(
            new GZIPInputStream(
                new FileInputStream("data.csv.gz")), "UTF-8"))) {

    String line;
    while ((line = reader.readLine()) != null) {
        process(line);
    }
}
// FileInputStream: reads raw bytes from file
// GZIPInputStream: decompresses; wraps InputStream
// InputStreamReader: converts bytes to chars
// BufferedReader: buffers; adds readLine()
```

> **Code walkthrough:** This is Decorator in the Java standard library.
> `FileInputStream` is the ConcreteComponent. `GZIPInputStream`,
> `InputStreamReader`, and `BufferedReader` are decorators, each
> implementing the same `Reader` interface (or compatible interface).
> Removing `BufferedReader` removes buffering. Removing `GZIPInputStream`
> removes decompression. The composition is explicit and composable.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Decorator adds behavior to an object by wrapping it in another object
> that implements the same interface. The wrapper calls the original
> object and adds behavior around it. This is better than subclassing
> when you need combinations of behaviors: three decorators give you
> all combinations without writing extra classes.

*Push deeper:* "Java I/O uses Decorator throughout: `BufferedReader`,
`InputStreamReader`, `GZIPInputStream` are all decorators that wrap
each other. Spring AOP proxies are also decorators: they wrap beans
and add transaction management, logging, or security checks."

---

**Senior / Staff (5+ years):**
> Decorator is the practical implementation of "favor composition over
> inheritance." The key production insight: Spring AOP and servlet filter
> chains are Decorator patterns at the framework level. You rarely write
> Decorator manually in Spring applications because the framework provides
> the decoration mechanism.
>
> Where I do write it manually: request validation pipelines (chain of
> validators), result transformation pipelines (chain of transformers),
> or API clients (wrap the HTTP client with a retry decorator, then wrap
> that with a circuit breaker decorator). The wrapping order matters:
> circuit breaker should be outermost (if circuit is open, do not even
> try), retry should be innermost around the actual call.

*Push deeper:* "The failure mode to know: Decorator breaks `instanceof`
and concrete-type checks. `coffee instanceof SimpleCoffee` is `false`
when coffee is wrapped. If downstream code checks for the concrete type,
it breaks silently. Solution: use interface checks only."

---

### ⚠️ Common Misconceptions

**Misconception 1: Decorator and Inheritance solve the same problem.**

Inheritance adds behavior at compile time by extending a class - every instance of the subclass has the same additional behavior. Decorator adds behavior at RUNTIME by wrapping objects - different instances can have different wrapper combinations. If you need logging for only SOME database connections, not all, Decorator lets you wrap only those connections. With inheritance, all subclass instances always have logging. Decorator enables combinatorial behavior composition; inheritance creates rigid behavior hierarchies.

**Misconception 2: Java I/O streams use Decorator in an overly complex way.**

Java I/O streams (InputStream -> BufferedInputStream -> GzipInputStream -> FileInputStream) demonstrate Decorator's power. Each wrapper adds one concern: buffering, compression, encryption, counting bytes. You compose exactly the combination you need: `new CipherInputStream(new BufferedInputStream(new FileInputStream(path)))`. The alternative (a separate class for every combination: BufferedGzipEncryptedFileInputStream, etc.) would require exponential class combinations. The "complexity" is the price of the runtime composability Decorator provides.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Decorator breaks object identity checks.**

Symptom: code that checks `if (obj instanceof ConcreteComponent)` or compares references (`obj == expectedComponent`) fails after decoration; objects that should match are not recognized. Root cause: a Decorator IS-A Component (via interface), but is NOT the ConcreteComponent. `instanceof ConcreteComponent` returns false for a wrapped instance. Diagnosis: search for `instanceof` checks against concrete decorated types; check for reference equality on decorated objects. Fix: add an `unwrap()` method to the Component interface that returns the innermost wrapped object; use interface-based identity instead of concrete class checks.

**Failure Mode 2: Deep decorator chains cause stack overflow on recursive operations.**

Symptom: StackOverflowError in decorator chains that delegate method calls recursively; typically occurs when a decorator accidentally calls itself or creates a circular delegation chain. Root cause: circular reference in wrapper chain (`A wraps B wraps A`) or excessive chain depth on recursive operations. Diagnosis: add logging to each decorator's delegation to trace the chain; check for reference cycles. Fix: validate chain construction to prevent circular wrapping; use iterative delegation rather than recursive for performance-critical paths.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Decorator pattern?"
- "How is Decorator different from subclassing?"

🗣️ "Decorator adds behavior to individual objects dynamically by
wrapping them in a class that implements the same interface. Both
the decorator and the wrapped object share an interface; the decorator
delegates to the wrapped object and adds behavior before or after.
Unlike subclassing, which adds behavior to all instances of a class
and requires a new class for each combination, Decorator can be
composed at runtime: three Decorator classes provide any combination
of three behaviors. No new classes needed for combinations."

#### Mechanism
- "Walk me through how stacked decorators work."
- "What happens to the call chain when decorators are nested?"

🗣️ "Stacked decorators form a chain. Outermost decorator receives the
call, executes before-behavior, delegates to the next decorator, gets
the result, executes after-behavior, returns. This repeats through
each decorator until the ConcreteComponent is reached. So three stacked
decorators: outer.operation() calls middle.operation() calls inner
.operation() calls concreteComponent.operation(). The result travels
back through the chain in reverse order. This is the same structure
as a servlet filter chain or Spring AOP advice chain."

#### Comparison
- "Compare Decorator vs Proxy."

🗣️ "Decorator and Proxy have the same structure: both wrap an object
through the same interface. The intent differs. Decorator's purpose
is to add functionality - more behavior, different output, enriched
result. The caller knows they are getting a decorated object. Proxy's
purpose is to control access - lazy loading, remote invocation,
security check, caching. The caller usually does not know there is
a proxy: the proxy is transparent. In Spring AOP, the proxy is a
Proxy by intent (it controls access for AOP advice) but structurally
it looks like Decorator."

#### Scenario
- "How would you implement a retry mechanism as a Decorator?"

🗣️ "I define a `ServiceClient` interface with the API methods. A
`RetryDecorator` implements `ServiceClient`, wraps a delegate
`ServiceClient`, and overrides each method to retry on specified
exceptions up to N times with exponential backoff. Callers inject
`ServiceClient` - they do not know whether it is the real client or
the retry wrapper. The decorator handles retry logic; the real client
handles the HTTP call. For production I use Resilience4j's Retry
wrapper instead of hand-rolling this - it handles edge cases
(thread interruption, idempotency, backoff jitter) correctly."

#### Debugging
- "A Decorator is not executing. How do you investigate?"

🗣️ "Three common causes: (1) The object was not wrapped - the decorator
was never applied. I verify by logging `getClass().getSimpleName()` on
the injected object: should show the decorator class, not the concrete
class. (2) The decorator was applied to the wrong interface: if the
decorator wraps `ServiceClientImpl` not the `ServiceClient` interface,
code that injects `ServiceClient` gets the unwrapped version. Always
decorate at the interface level, not the concrete class. (3) In Spring:
the bean was retrieved before AOP was applied, or the method is called
internally (Spring AOP only intercepts external calls). For internal
calls, use `AopContext.currentProxy()` - though this is a code smell."

#### Deep Dive
- "How is Java I/O designed as a Decorator?"
- "What are the drawbacks of Decorator?"

🗣️ "Java I/O is a Decorator hierarchy. `InputStream` is the Component
interface. `FileInputStream`, `ByteArrayInputStream` are Concrete
Components. `FilterInputStream` is the abstract Decorator holding a
delegate `InputStream`. `BufferedInputStream`, `DataInputStream`,
`GZIPInputStream` are Concrete Decorators. The criticism of this
design: the chain syntax is verbose and construction order is obscure.
`new BufferedInputStream(new GZIPInputStream(new FileInputStream(f)))`
- getting the order wrong (putting GZIPInputStream outside) causes
incorrect behavior silently.
Drawbacks of Decorator generally: complex chains are hard to debug
(many delegation hops before reaching the real component), the
`instanceof` issue (type checks on the interface, not concrete class),
and proliferation of small classes if taken to extremes."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implement a logging + timing decorator chain; explain delegation order. |
| Hiring Manager | "Decorator is how we add retry and circuit-breaking to API clients without changing the client code." |
| Bar Raiser | "How does Spring AOP use Decorator at the bytecode level? What are the limitations of interface-based proxies?" |
| Peer Engineer | "I see Decorator in servlet filters, Spring interceptors, and API client wrappers constantly." |

---

# Adapter Pattern

---
id: DP-008
title: Adapter Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #design-patterns, #adapter, #structural, #integration, #legacy
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Adapter converts the interface of a class into another interface that
> clients expect. It lets classes work together that could not otherwise
> because of incompatible interfaces. The classic analogy is a power
> adapter: the plug shape is wrong for the socket, so you add an adapter
> between them - neither the plug nor the socket changes.

**3 minutes (Senior):**
> The production context for Adapter is integration with external systems
> and legacy code. You have a third-party library or a legacy service that
> works perfectly but has a different interface from what your code expects.
> Instead of modifying either side (often impossible for third-party or
> risky for legacy), you write an Adapter that bridges them.
>
> Two structural forms. Object Adapter (composition): the Adapter holds
> an instance of the Adaptee and translates calls. Class Adapter
> (multiple inheritance): the Adapter extends both the Target interface
> and the Adaptee class - only possible in languages that support multiple
> inheritance (C++, rare in Java). Object Adapter is the standard Java form.
>
> The Spring context: `JpaRepository` extends `PagingAndSortingRepository`
> which extends `CrudRepository` - each is an Adapter over the JPA `EntityManager`.
> JdbcTemplate is an Adapter over JDBC's verbose `Connection/Statement/ResultSet`
> API. Adapter is how Java frameworks make low-level APIs usable.

**Blank Mind Recovery:**

**(1) Restate:** "Adapter - the pattern that makes incompatible interfaces
work together."

**(2) First principles:** "Two components need to work together. They have
different interfaces. You cannot change either. Solution: add a third
component that translates between them."

**(3) Bridge:** "Like a USB-C to HDMI adapter: the laptop and the monitor
did not change, the adapter speaks both languages."

---

### 📘 Concept Explanation

**What it is:**
Adapter wraps a class with a different interface to match the interface
that clients expect, enabling integration without modifying either the
client or the class being adapted.

**The problem it solves:**
Two components need to work together but have incompatible interfaces.
Modifying either side is not possible (third-party library, legacy system,
team boundary) or not desirable (would break other callers).

**How it works:**

```
Target interface: what the client expects
  + request(): Result

Adaptee: the existing class with the wrong interface
  + specificRequest(): AltResult

Adapter implements Target:
  - adaptee: Adaptee
  + request():
      result = adaptee.specificRequest()
      translate(result) -> Result
      return translated Result

Client:
  target = new Adapter(new Adaptee())
  target.request()  // client uses Target interface
                    // Adaptee is hidden inside Adapter
```

**The key insight:**
Adapter is a translation layer. It never adds new functionality;
it only translates. If you find yourself adding business logic
to an Adapter, that logic belongs elsewhere.

**When to use it:**
- Integrating a third-party library with a different interface
- Wrapping a legacy API to expose a modern interface to new code
- Standardizing multiple different implementations behind a single
  interface (multiple external payment APIs adapted to one internal
  interface)

**When NOT to use it:**
- When you control both sides: change the interface directly
- When the translation is so complex it becomes a Facade (multiple
  subsystems unified) - use Facade instead
- When the difference is behavior, not just interface - that is a
  different pattern

**Alternatives:**
- **Facade** - unifies multiple subsystems; Adapter translates one
  interface to another
- **Bridge** - separates an abstraction from implementation for
  extensibility in both dimensions
- **Direct modification** - when you own the code being adapted

**First-principles derivation:**
Given: component A expects interface X; component B provides interface Y;
you cannot change A (client) or B (adaptee). The only option: create C
that implements X and delegates to B (translating the calls). That is
the Adapter.

---

### 💻 Code Example

```java
// Scenario: existing payment code uses our PaymentGateway
// interface. Third-party Stripe SDK has a different interface.

// Our internal interface (Target)
public interface PaymentGateway {
    PaymentResult charge(String customerId,
                         long amountCents,
                         String currency);
}

// Third-party Stripe API (Adaptee - cannot modify)
public class StripeClient {
    public StripeCharge createCharge(StripeChargeRequest req)
            throws StripeException {
        // Stripe-specific implementation
    }
}

// BAD: calling Stripe directly in business code
public class OrderService {
    private final StripeClient stripe;

    public void checkout(Order order) {
        try {
            StripeChargeRequest req = new StripeChargeRequest();
            req.setAmount(order.getTotalCents());
            req.setCurrency("usd");
            req.setCustomer(order.getStripeCustomerId());
            stripe.createCharge(req);  // Stripe API leaked into domain
        } catch (StripeException e) { ... }
    }
}
```

> **Code walkthrough:** Stripe-specific types (`StripeChargeRequest`,
> `StripeException`) are leaked into the business domain. Switching
> to PayPal requires modifying `OrderService`. Testing requires a real
> or mocked Stripe client.

```java
// GOOD: Adapter - translates StripeClient to PaymentGateway
public class StripePaymentAdapter implements PaymentGateway {
    private final StripeClient stripe;

    public StripePaymentAdapter(StripeClient stripe) {
        this.stripe = stripe;
    }

    public PaymentResult charge(String customerId,
                                long amountCents,
                                String currency) {
        try {
            StripeChargeRequest req = new StripeChargeRequest();
            req.setAmount(amountCents);
            req.setCurrency(currency);
            req.setCustomer(customerId);

            StripeCharge charge = stripe.createCharge(req);

            // Translate Stripe result to our domain result
            return PaymentResult.success(charge.getId());

        } catch (StripeException e) {
            return PaymentResult.failure(e.getMessage());
        }
    }
}

// Business code is clean - uses PaymentGateway only
public class OrderService {
    private final PaymentGateway payment;  // Adapter injected

    public void checkout(Order order) {
        PaymentResult result = payment.charge(
            order.getCustomerId(),
            order.getTotalCents(),
            order.getCurrency());

        if (!result.isSuccess()) throw new PaymentException(...);
    }
}
```

> **Code walkthrough:** `StripePaymentAdapter` translates between
> the Stripe API and our domain's `PaymentGateway` interface.
> `OrderService` knows only `PaymentGateway` - it has zero Stripe
> dependencies. Switching to PayPal: create `PayPalPaymentAdapter`,
> inject it instead. Testing: inject a `MockPaymentGateway`.
> The Adapter is the seam between our domain and the external system.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Adapter makes two incompatible interfaces work together by translating
> between them. You create a class that implements the interface your
> code expects but delegates to the class that has the different interface.
> I use it whenever integrating a third-party library: wrap the library
> in an Adapter that implements our internal interface, so our code never
> depends on the library's types directly.

*Push deeper:* "The benefit is testability: if business code depends on
our interface, I can inject a mock in tests. If it depends on the
Stripe SDK directly, I need a real Stripe connection or a complex
stub."

---

**Senior / Staff (5+ years):**
> Adapter is the seam between our domain and external systems. Every
> third-party SDK integration should go through an Adapter. The benefit
> is not just interface compatibility - it is isolation. When Stripe
> changes their API, only the Adapter changes. When we want to test
> payment logic, we inject a mock Adapter. When we evaluate a new
> provider, we write a new Adapter.
>
> The anti-pattern I see: Adapters that grow to include business logic.
> An Adapter should translate, not decide. If the Adapter contains
> `if (amount > 1000) use PayPal else use Stripe` - that business logic
> belongs in a Strategy or Policy object, not the Adapter.

*Push deeper:* "Adapter vs Facade: Adapter bridges one interface to
another (one-to-one). Facade unifies multiple subsystems behind a
simpler interface (many-to-one). If your 'Adapter' calls three
different services to fulfill one request, it is actually a Facade."

---

### ⚠️ Common Misconceptions

**Misconception 1: Adapter changes the behavior of the adaptee.**

Adapter is a structural pattern that translates interfaces without changing behavior. The adaptee does the same work; Adapter just makes it accessible through the expected interface. If you find yourself adding business logic inside an Adapter, you are mixing Adapter with Facade or Decorator - the Adapter should contain only interface translation code (method delegation, parameter conversion, return type mapping). Business logic in Adapters creates untestable, hidden behavior.

**Misconception 2: Adapter and Bridge are the same pattern.**

Adapter FIXES interface incompatibility between existing classes. Bridge PREVENTS interface and implementation binding at design time. Adapter is applied AFTER the fact to make two independently designed classes work together. Bridge is designed upfront so abstraction and implementation can vary independently. The key temporal distinction: Adapter is a retrofit; Bridge is a forward-looking design decision.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Adapter leaks the adaptee's exception types to the client.**

Symptom: clients that use the target interface start catching exceptions specific to the adaptee's implementation (e.g., `SQLExceptions` in a database adapter, `FileNotFoundException` in a file adapter); client code becomes coupled to the implementation detail it should be shielded from. Root cause: Adapter methods declare or propagate the adaptee's checked exceptions instead of translating them to target interface exceptions. Fix: translate adaptee exceptions to target interface exceptions in the adapter; wrap in a generic `AdapterException` or the appropriate domain exception.

**Failure Mode 2: Object adapter holding stale adaptee reference after adaptee lifecycle ends.**

Symptom: NullPointerException or IllegalStateException when adapter methods are called after the underlying adaptee is closed/disposed; adapter does not detect adaptee lifecycle transitions. Root cause: object adapter holds a direct reference to the adaptee with no lifecycle coordination. Diagnosis: check whether the adaptee is closeable and whether the adapter implements the same lifecycle contract. Fix: implement the same lifecycle interface (Closeable, AutoCloseable) in the adapter and delegate lifecycle calls to the adaptee.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Adapter pattern?"
- "What is the difference between Object Adapter and Class Adapter?"

🗣️ "Adapter converts the interface of an existing class into the
interface that clients expect. Object Adapter uses composition:
the Adapter class holds an instance of the Adaptee and translates
calls. Class Adapter uses multiple inheritance: the Adapter extends
both the Target interface and the Adaptee class. In Java, Class
Adapter requires the Adaptee to be a class (not a final class) and
is less common because Java supports single inheritance only. Object
Adapter is the standard Java form - it is more flexible because it
can adapt subclasses of the Adaptee as well."

#### Mechanism
- "Walk me through an Adapter for a third-party payment SDK."

🗣️ "The third-party SDK (Adaptee) has a `StripeClient.createCharge()`
method. Our code expects a `PaymentGateway.charge()` method (Target).
The Adapter: a class that implements `PaymentGateway`, holds a
`StripeClient`, and in the `charge()` method translates the call:
maps our parameters to `StripeChargeRequest`, calls `createCharge()`,
translates the `StripeCharge` result to our `PaymentResult`, and
translates `StripeException` to our domain exception. The business
code injects `PaymentGateway` - the Adapter is invisible."

#### Comparison
- "Compare Adapter vs Facade vs Bridge."

🗣️ "Three related structural patterns: Adapter translates one interface
to another - the client has an expectation (Target interface) and you
bridge it to an incompatible existing class. Facade provides a simplified
interface to a complex subsystem - the client does not care about the
internal structure, just the simple surface. Bridge separates an
abstraction from its implementation so both can vary independently -
designed for extensibility in two dimensions from the start, not for
adapting an existing class. Adapter: existing incompatible class.
Facade: existing complex system. Bridge: new design for future
extensibility."

#### Scenario
- "You are integrating five different email providers. How do you use
  Adapter?"

🗣️ "I define one internal `EmailService` interface with a `send()` method.
I write five adapter classes: `SendGridAdapter`, `MailgunAdapter`,
`SESAdapter`, `PostmarkAdapter`, and `SmtpAdapter`. Each adapter
implements `EmailService` and holds the SDK client for its provider.
Application code injects `EmailService` - it never knows which provider
is active. The active adapter is selected by Spring `@ConditionalOnProperty`
based on `email.provider` configuration. Testing: inject a
`MockEmailService` that records sent messages. This is textbook Adapter
use."

#### Debugging
- "An Adapter is losing data in translation. How do you diagnose?"

🗣️ "I add logging at both the input and output of the adapter's translate
step: log the raw Adaptee response before translation and the translated
Target result after. I compare them field by field. Common causes:
(1) field mapping mismatch - the Adaptee returns the amount in dollars
but we store it in cents; the Adapter forgets to multiply by 100.
(2) null propagation - the Adaptee returns null for an optional field;
the Adapter does not handle null and passes it through, causing NPE
downstream. (3) exception swallowing - the Adapter catches exceptions
but returns a generic error, losing the specific failure code."

#### Deep Dive
- "Where does Adapter appear in the Spring framework?"
- "How does Adapter relate to the Strangler Fig architectural pattern?"

🗣️ "Spring is full of Adapters. `JdbcTemplate` adapts the JDBC API
(verbose `Connection/PreparedStatement/ResultSet`) to a simpler template
API. Spring MVC's `HandlerAdapter` adapts any controller type (annotated
controllers, old-style `Controller` interface, HttpRequestHandler) to
the uniform `handle()` method DispatcherServlet expects. `JmsTemplate`
adapts JMS API. The pattern is consistent: messy or verbose API on one
side, clean Spring API on the other.
Strangler Fig: an architectural pattern for migrating from a legacy system.
You put an Adapter layer in front of the legacy system that also routes
new features to the new system. The legacy system is strangled gradually
as the Adapter routes more requests to the new system. Adapter is the
mechanism that enables the Strangler Fig: both old and new systems can
exist behind the same interface."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implement an Adapter for a payment SDK; explain why business logic belongs outside the Adapter. |
| Hiring Manager | "Every external system integration in our codebase goes through an Adapter. It is how we keep our domain clean." |
| Bar Raiser | "What is the difference between Adapter and Facade? When does an Adapter become a Facade?" |
| Peer Engineer | "I use Adapter on every third-party integration. The rule: never let external types cross the service boundary." |

---

# Facade Pattern

---
id: DP-009
title: Facade Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #design-patterns, #facade, #structural, #simplification, #api-design
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Facade provides a simplified interface to a complex subsystem of
> classes. It does not add functionality - it reduces the interface
> surface. Callers use the Facade; they do not need to know the
> subsystem's internal components. It is the pattern behind every
> "service layer" or "API layer" that shields callers from complexity.

**3 minutes (Senior):**
> The problem Facade solves: a subsystem has multiple classes with
> complex interdependencies. Callers need to know which classes to use,
> in what order, with what parameters. The cognitive load is high. Facade
> provides a single entry point with a simpler API, orchestrating the
> subsystem internally.
>
> The production pattern: every service layer in an application is a
> Facade. The `OrderService` is a Facade over `InventoryRepository`,
> `PaymentGateway`, `NotificationService`, and `ShipmentService`.
> Callers call `orderService.placeOrder(request)` - they do not know
> that it checks inventory, charges payment, creates a shipment, and
> sends a notification in sequence.
>
> The distinction from other patterns: Facade reduces complexity for
> callers (many-to-one interface simplification). Adapter translates
> incompatible interfaces (one-to-one translation). Mediator reduces
> coupling between sibling components (they communicate through a hub
> instead of directly). The intent and the direction of simplification
> differ.

**Blank Mind Recovery:**

**(1) Restate:** "Facade - the pattern that provides a simple interface
to a complex system."

**(2) First principles:** "Problem: a subsystem is complex. Many classes
to understand, many methods to call in the right order. Solution: add
a front desk (facade) that exposes a simple interface and handles the
complexity internally."

**(3) Bridge:** "A hotel concierge is a Facade: instead of booking the
restaurant, ordering the taxi, and arranging the tour yourself, you ask
the concierge and they orchestrate everything."

---

### 📘 Concept Explanation

**What it is:**
Facade is a Structural pattern that provides a simplified, unified
interface to a set of interfaces in a subsystem, reducing the complexity
visible to callers.

**The problem it solves:**
Subsystems become complex over time. Direct access to a subsystem requires
callers to understand all its classes, their dependencies, and the correct
interaction sequence. Facade shields callers from this complexity.

**How it works:**

```
Subsystem classes (complex internals):
  InventoryService   - checks stock
  PaymentService     - processes charges
  ShipmentService    - creates and tracks shipments
  NotificationService- sends emails/SMS
  AuditService       - records events

Facade (OrderService):
  + placeOrder(request: OrderRequest): OrderResult
    1. inventory.reserve(request.items)
    2. payment.charge(request.customerId, request.total)
    3. shipment.create(request.items, request.address)
    4. notification.sendConfirmation(request.email)
    5. audit.record(OrderPlaced event)
    6. return OrderResult with all IDs

Caller:
  orderService.placeOrder(request)
  // No knowledge of 5 subsystem classes needed
```

**The key insight:**
Facade does not prevent access to subsystem classes - it just provides
a simpler path. Callers who need fine-grained control can still use
the subsystem directly. Facade is a convenience layer, not a wall.

**When to use it:**
- When a subsystem is complex and most callers need only a subset of
  its functionality
- When you want to layer a subsystem: the Facade provides the common
  path, the subsystem provides the advanced path
- When decoupling callers from subsystem internals (subsystem can be
  refactored without changing callers)

**When NOT to use it:**
- When the Facade becomes a "God class" - orchestrating everything
  including business logic (business logic belongs in domain objects)
- When callers routinely bypass the Facade and use the subsystem
  directly - the Facade is not providing the simplification it should

**Alternatives:**
- **Adapter** - translates one interface to another; Facade unifies
  multiple
- **Mediator** - reduces coupling between sibling components;
  Facade reduces coupling between callers and a subsystem
- **Service Layer (DDD)** - the application service layer is Facade
  in DDD terminology

**First-principles derivation:**
Given: a subsystem of N classes. Callers need to coordinate calls
across these classes. Options: (A) callers know all N classes -
high cognitive load, change in subsystem breaks all callers. (B)
provide a single entry point that orchestrates N classes - callers
depend on one interface, subsystem can change internally. Option B
is Facade.

---

### 💻 Code Example

```java
// BAD: controller directly orchestrates subsystem
@RestController
public class OrderController {

    @Autowired InventoryService inventory;
    @Autowired PaymentService payment;
    @Autowired ShipmentService shipment;
    @Autowired NotificationService notification;

    @PostMapping("/orders")
    public OrderResponse placeOrder(@RequestBody OrderRequest req) {
        // Controller knows the orchestration sequence
        // Any change to sequence breaks this controller
        inventory.reserve(req.getItems());
        String chargeId = payment.charge(
            req.getCustomerId(), req.getTotal());
        String shipId = shipment.create(
            req.getItems(), req.getAddress());
        notification.send(req.getEmail(), chargeId);
        return new OrderResponse(chargeId, shipId);
    }
}
```

> **Code walkthrough:** The controller knows five subsystem classes
> and their interaction order. If the notification must now wait until
> shipment confirmation, the controller changes. If a new step (fraud
> check) is added, the controller changes. The controller has too many
> responsibilities.

```java
// GOOD: Service layer as Facade
@Service
public class OrderFacade {
    private final InventoryService inventory;
    private final PaymentService payment;
    private final ShipmentService shipment;
    private final NotificationService notification;

    public OrderResult placeOrder(OrderRequest request) {
        // Facade orchestrates subsystem
        // Callers do not see this complexity
        validateRequest(request);
        inventory.reserve(request.items());

        String chargeId = payment.charge(
            request.customerId(), request.totalCents());

        String shipId = shipment.create(
            request.items(), request.address());

        notification.sendConfirmation(
            request.email(), chargeId, shipId);

        return new OrderResult(chargeId, shipId);
    }

    private void validateRequest(OrderRequest req) {
        // validation centralized in facade
    }
}

// Controller is thin - only HTTP concerns
@RestController
public class OrderController {
    private final OrderFacade orderFacade;  // injected

    @PostMapping("/orders")
    public ResponseEntity<OrderResponse> placeOrder(
            @RequestBody @Valid OrderRequest request) {
        OrderResult result = orderFacade.placeOrder(request);
        return ResponseEntity.ok(
            OrderResponse.from(result));
    }
}
```

> **Code walkthrough:** `OrderFacade` is the Facade: it provides a
> simple `placeOrder` method and orchestrates five subsystem services.
> `OrderController` has one dependency (`OrderFacade`) instead of five.
> The controller handles HTTP concerns only. Testing `OrderFacade`:
> inject mock services. Testing `OrderController`: inject a mock
> `OrderFacade`. Each layer is testable in isolation. Adding a fraud
> check step: modify only `OrderFacade`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Facade provides a simple interface to a complex subsystem. Instead
> of callers needing to know multiple classes and the order to call
> them, the Facade handles all of that internally. In Spring, the
> service layer is the Facade: controllers call service methods, the
> service orchestrates repositories, external APIs, and domain objects.

*Push deeper:* "The benefit is encapsulation of orchestration logic.
If the business process changes, only the Facade changes - not every
controller that calls it."

---

**Senior / Staff (5+ years):**
> Facade is the application service layer in DDD. Each application
> service method (Facade method) represents one use case: placeOrder,
> cancelOrder, refundOrder. The Facade knows the sequence of domain
> operations and infrastructure calls to fulfill the use case.
>
> The common mistake: Facade becomes a God class. When OrderFacade
> grows to 3000 lines with business logic mixed in: it is no longer
> a Facade, it is a procedural monolith. The fix: move business logic
> into domain objects. The Facade should be thin - it orchestrates
> domain objects and services, it does not contain business rules itself.

*Push deeper:* "Facade vs Mediator: Facade simplifies caller-to-subsystem
interaction (vertical). Mediator simplifies subsystem-to-subsystem
interaction (horizontal). In a domain model, domain events and a
Mediator (like Spring's `ApplicationEventPublisher`) let domain objects
communicate without direct coupling - that is Mediator. The service
layer that coordinates them is Facade."

---

### ⚠️ Common Misconceptions

**Misconception 1: Facade completely hides the subsystem - clients should never access subsystem classes directly.**

Facade provides a SIMPLIFIED interface to a complex subsystem for common use cases. It does NOT prevent direct subsystem access for advanced use cases. A well-designed Facade is a convenience layer, not an enforcement boundary. If a client needs fine-grained control that the Facade does not expose, accessing the subsystem directly is acceptable. Enforcing Facade as the only access point turns it into a bottleneck that defeats its simplicity goal.

**Misconception 2: Facade and Mediator are the same pattern.**

Facade simplifies client access to a complex SUBSYSTEM - it coordinates multiple subsystem classes to perform high-level operations. Mediator simplifies communication between PEER objects by centralizing coordination between them. The directionality differs: Facade clients call the facade (one-way, client → facade → subsystem); Mediator peers communicate through the mediator (bidirectional, peers ↔ mediator ↔ peers). Facade is about simplifying a subsystem API; Mediator is about decoupling peers that would otherwise reference each other.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Facade becomes a God Class as more subsystem operations are added.**

Symptom: Facade class exceeds 500-1000 lines, contains methods for dozens of unrelated subsystem concerns, and is modified for every new feature. Root cause: Facade pattern used as a single entry point for ALL subsystem operations rather than for a coherent set of client-facing operations. Diagnosis: measure Facade cohesion - do all its methods serve the same high-level client purpose? Fix: split the Facade by client perspective (OrderFacade for order operations, PaymentFacade for payment operations) rather than one Facade per subsystem.

**Failure Mode 2: Facade creates a false sense of subsystem encapsulation.**

Symptom: developers add business logic to the Facade that belongs in the subsystem; the subsystem is bypassed by code that needs the logic without the simplified interface; business rules are duplicated between Facade and subsystem. Root cause: Facade treated as the business logic layer rather than an interface simplification layer. Fix: Facade should delegate, not decide. Business logic belongs in domain/service objects, not in the Facade. If the Facade contains conditionals or calculations, those likely belong in the subsystem.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Facade pattern?"
- "Does Facade prevent direct access to subsystem classes?"

🗣️ "Facade provides a simplified, unified interface to a complex subsystem.
It reduces the number of objects a caller needs to know about. Facade
does not prevent direct access to subsystem classes - callers who need
fine-grained control can still use them. Facade is a convenience layer:
most callers use the simple path, advanced callers use the subsystem
directly. In Spring MVC, the service layer is the Facade: most operations
go through service methods; complex operations can call repositories
directly."

#### Mechanism
- "How does Facade differ from hiding complexity through encapsulation?"

🗣️ "Standard encapsulation hides implementation details within a single
class. Facade hides the complexity of coordinating multiple classes. A
class encapsulates its fields; a Facade encapsulates the interaction
sequence across a subsystem. The distinction: encapsulation is about
one class's internals; Facade is about a system of classes' coordination.
Both reduce coupling, at different levels of abstraction."

#### Comparison
- "Compare Facade vs Adapter vs Mediator."

🗣️ "Three structural patterns that simplify, but in different ways.
Adapter: translates one interface into another - one-to-one interface
translation for an existing incompatible class. Facade: provides a
simplified interface to multiple subsystem classes - many-to-one
simplification. Mediator: reduces direct dependencies between sibling
components by centralizing their communication through a hub - reduces
coupling within a peer group.
Concrete example: Adapter bridges your code to the Stripe SDK.
Facade orchestrates payment, inventory, and shipment for the placeOrder
use case. Mediator lets domain events flow between Order, Payment, and
Inventory services without direct coupling."

#### Scenario
- "Design a HomeAutomation Facade."
- "When does a Facade become too large?"

🗣️ "A HomeAutomation Facade could have methods like `leavingHome()`,
`arrivingHome()`, `nighttime()`. Behind the scenes: `leavingHome()`
turns off lights (LightingSystem), locks doors (SecuritySystem), adjusts
thermostat (HVACSystem), and activates alarm (AlarmSystem). Callers
call `homeAutomation.leavingHome()` - they do not know the four
subsystems or the correct sequence. The Facade becomes too large when:
its methods start containing conditional logic ('if it is weekday,
set thermostat to 70 instead of 65'), when it has 30+ methods, or
when it becomes the only way to access the subsystem (blocking advanced
callers who need fine-grained control)."

#### Debugging
- "A Facade is not propagating errors correctly from subsystems.
  How do you diagnose?"

🗣️ "I check whether the Facade is swallowing exceptions. A common bug:
the Facade catches all exceptions and returns a generic error response,
losing the specific failure reason. I trace by adding logging before
each subsystem call and in each catch block, then observe which call
throws and what happens to the exception. Another common issue: partial
success handling - if `payment.charge()` succeeds but `shipment.create()`
fails, the Facade must either rollback the payment or record it as
a compensating action to retry the shipment. Distributed transaction
management across subsystems is a common Facade design challenge."

#### Deep Dive
- "How does Spring's JdbcTemplate implement the Facade pattern?"
- "What is the relationship between Facade and the Law of Demeter?"

🗣️ "JdbcTemplate is a Facade over JDBC. Raw JDBC requires: get Connection,
create PreparedStatement, set parameters, execute, iterate ResultSet,
close Statement, close Connection, handle multiple exception types.
JdbcTemplate provides: `jdbcTemplate.query(sql, params, rowMapper)` -
one method, no resource management, uniform exception hierarchy (Spring
DataAccessException). JdbcTemplate implements the Facade by orchestrating
the JDBC subsystem internally.
Law of Demeter says a method should only call methods on: itself, its
direct parameters, objects it creates, and its fields. A Facade helps
satisfy this: instead of `order.getCustomer().getAddress().getCity()`,
you have `orderFacade.getOrderCity(orderId)`. The chain of gets violates
Demeter; the Facade encapsulates the traversal."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implement a Facade for a multi-step business process; explain the service layer as a Facade. |
| Hiring Manager | "The service layer as a Facade is what makes our API layer thin and testable. Controllers just delegate." |
| Bar Raiser | "How does a Facade become a God class? What signals tell you it has grown too large?" |
| Peer Engineer | "I see Facade everywhere in service layers. The key smell: when the Facade starts making decisions - extract that to domain objects." |
