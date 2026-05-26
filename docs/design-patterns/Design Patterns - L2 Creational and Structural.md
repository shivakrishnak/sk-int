---
layout: default
title: "Design Patterns - L2 Creational and Structural"
parent: "Design Patterns and SOLID"
grand_parent: "SK Interview"
nav_order: 3
permalink: /design-patterns/l2-creational-and-structural/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Singleton Pattern](#singleton-pattern) | high |
| 2 | [Factory Method and Abstract Factory](#factory-method-and-abstract-factory) | high |
| 3 | [Builder Pattern](#builder-pattern) | high |
| 4 | [Adapter Pattern](#adapter-pattern) | working |
| 5 | [Decorator Pattern](#decorator-pattern) | high |

---

# Singleton Pattern

**Interview Weight:** high - The most-discussed pattern.
Tests understanding of trade-offs, thread safety, and
why modern frameworks handle it differently.

---

### 🎯 Model Answer

**30 seconds:**

> Singleton ensures exactly one instance of a class exists
> and provides global access to it. In modern Java: Spring's
> default bean scope IS Singleton - managed by the container,
> not the class itself. The classic double-checked locking
> implementation is obsolete. The real interview question is:
> why is Singleton considered an anti-pattern in testing
> (global state, tight coupling) and how does DI solve it
> (container-managed singletons are injectable and mockable).

**3 minutes (Senior):**

> Singleton evolution in Java:
>
> Era 1: Eager initialization (pre-Java 5).
>   private static final INSTANCE = new Singleton();
>   Simple. Thread-safe. But: loaded even if never used.
>
> Era 2: Double-checked locking (Java 5+ with volatile).
>   volatile + synchronized. Complex. Error-prone.
>   Most implementations before Java 5 were BROKEN due
>   to memory model issues.
>
> Era 3: Enum singleton (Effective Java, Josh Bloch).
>   enum MySingleton { INSTANCE; }
>   Thread-safe, serialization-safe, reflection-safe.
>   Gold standard for classic singleton.
>
> Era 4: Container-managed (Spring, CDI - modern).
>   @Service, @Component: Spring manages the single instance.
>   No static state. Injectable. Mockable. Testable.
>   This is NOT the GoF Singleton pattern - it's better.
>
> Why classic Singleton is an anti-pattern:
>   1. Hidden dependency: MySingleton.getInstance() hides
>      the dependency from constructors. Hard to trace.
>   2. Global mutable state: if Singleton has state,
>      tests interfere with each other.
>   3. Not mockable: cannot inject a test double.
>   4. Tight coupling: callers coupled to concrete class.
>
> When Singleton is still valid:
>   - Framework internals (logging, configuration).
>   - Expensive resources (connection pools).
>   - Pure utilities with no state (formatters, converters).
>   - When the DI container IS the singleton mechanism.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Singleton
pattern, its implementations, and modern alternatives."

**(2) First principles:** "Singleton = one instance +
global access. Modern Java: let the DI container manage
the single instance instead of the class itself."

**(3) Bridge:** "Classic Singleton is like a global variable
with extra steps. Spring-managed singleton is like a
receptionist who gives everyone the same shared resource
without them knowing the resource is shared."

---

### 💻 Code Example

```java
// BAD: Classic Singleton - anti-pattern for services
public class PaymentProcessor {
    private static PaymentProcessor instance;

    private PaymentProcessor() {}

    public static synchronized PaymentProcessor getInstance() {
        if (instance == null) {
            instance = new PaymentProcessor();
        }
        return instance;
    }

    public void process(Payment p) { /* ... */ }
}
// Usage:
// PaymentProcessor.getInstance().process(payment);
// Problems:
// 1. Cannot mock in tests
// 2. Hidden dependency (not in constructor)
// 3. Global state if PaymentProcessor has fields
// 4. synchronized: performance bottleneck

// GOOD: Container-managed singleton (Spring)
@Service  // Spring creates ONE instance (default scope)
public class PaymentProcessor {
    private final PaymentGateway gateway;

    // Constructor injection: explicit dependency
    public PaymentProcessor(PaymentGateway gateway) {
        this.gateway = gateway;
    }

    public void process(Payment p) {
        gateway.charge(p.amount());
    }
}

// Test: injectable, mockable
@Test
void shouldProcessPayment() {
    PaymentGateway mock = mock(PaymentGateway.class);
    PaymentProcessor proc = new PaymentProcessor(mock);
    proc.process(payment);
    verify(mock).charge(payment.amount());
}
```

> **Code walkthrough:** The classic Singleton hides
> dependencies and cannot be mocked. The Spring version
> is a regular class with constructor injection - Spring
> manages the single instance lifecycle. Testing is trivial:
> construct with a mock. The class doesn't know or care
> that it's a singleton; that's the container's job.

---

### ⚖️ Comparison Table

| Implementation | Thread-Safe | Testable | Serialization-Safe | Recommended |
|---|---|---|---|---|
| Static field | Yes | No | No | No |
| Double-checked locking | Yes (Java 5+) | No | No | No |
| Enum | Yes | Partially | Yes | For non-DI contexts |
| Spring @Service | Yes (container) | Yes | N/A | Yes (default) |

---

### 🎓 Answers by Seniority

**Junior:** "Singleton ensures one instance. I use Spring's
@Service which is singleton by default."

**Mid:** "Classic Singleton is an anti-pattern because it
hides dependencies and prevents mocking. Spring-managed
singletons via DI are the modern approach - testable and
explicit."

**Senior:** "Singleton is a lifecycle concern, not a design
pattern. The DI container manages lifecycle. The class itself
should be a regular POJO with no static state. The only
valid use of GoF Singleton is where no DI container exists."

---

### ⚠️ Common Misconceptions

**"Singleton means static getInstance() method."**
Not in modern Java. Singleton means one instance per scope.
Spring manages this without any static methods. The class
is a normal POJO.

**"Singleton is always an anti-pattern."**
It depends on implementation. Container-managed singletons
(Spring beans) are fine. Static-access singletons with
global mutable state are the anti-pattern.

---

### 🚨 Failure Modes and Diagnosis

| Failure | Symptom | Diagnosis |
|---|---|---|
| Thread-unsafe lazy init | Duplicate instances under load | Race condition in getInstance(). Use enum or DI |
| State leakage in tests | Test B fails only when run after Test A | Singleton holds mutable state. Reset between tests or use DI |
| Serialization creates duplicate | Deserialize produces new instance | Implement readResolve() or use enum |
| Memory leak | Singleton holds references to expired objects | Singleton lifecycle = application lifetime. Be careful with collections |

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Implementation, thread safety |
| Mid | 6 min | Anti-pattern analysis, DI alternative |
| Senior | 9 min | Lifecycle management, scope decisions |

---

**[MID] Q1 - Why is the classic Singleton pattern
considered an anti-pattern in testable code?**

*Why they ask:* Tests understanding beyond implementation.

Four testing problems with classic Singleton:

1. Hidden dependency. The service calls
   `PaymentProcessor.getInstance()` somewhere inside its
   method body. The test cannot see this dependency in the
   constructor. Surprise dependencies break test isolation.

2. Global mutable state. If the Singleton holds state
   (transaction count, cache entries), one test modifies
   it and the next test sees corrupted state. Tests become
   order-dependent.

3. Cannot inject mock. `getInstance()` returns the real
   object. There's no seam to inject a test double. You
   must use PowerMock or reflection hacks - fragile tests.

4. Tight coupling. Every caller is coupled to the concrete
   Singleton class. Cannot swap implementations (e.g.,
   test Singleton vs production Singleton).

The DI solution eliminates all four:
1. Explicit: dependency in constructor parameter.
2. Scoped: Spring creates fresh instances for tests if needed.
3. Mockable: inject mock via constructor.
4. Decoupled: depend on interface, not concrete.

*What separates good from great:* Naming all four problems
with concrete test scenarios, not just "it's hard to test."

---

**[SENIOR] Q2 - When would you still use a GoF Singleton
(not container-managed)?**

*Why they ask:* Tests nuanced judgment.

Three valid cases where GoF Singleton is appropriate:

1. Library code without DI. If you're writing a utility
   library (logging, metrics) that must work without Spring
   or any DI container, GoF Singleton (enum-based) is the
   cleanest approach. SLF4J LoggerFactory is effectively
   a Singleton.

2. JVM-level resources. Thread pools, connection pools, or
   classloader-scoped resources that must be exactly one
   per JVM regardless of DI container lifecycle. Example:
   a global shutdown hook registry.

3. Performance-critical hot paths. In extremely hot code
   where DI container lookup overhead matters (millions of
   calls per second), a static final reference eliminates
   the indirection. Rare, but valid in framework internals.

The heuristic: if the Singleton has NO mutable state and
NO dependencies that need mocking, GoF is acceptable. The
moment it has injectable dependencies or mutable state:
use DI-managed instead.

*What separates good from great:* The heuristic at the end
(no mutable state + no mockable deps = GoF acceptable).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Thread-safe implementations, enum singleton. |
| Hiring Manager | Testability, modern practices. |
| Bar Raiser | Anti-pattern analysis, when Singleton IS valid. |
| Peer Engineer | "Removed 12 static singletons. Test suite: 45 min to 8 min. Flaky tests: 23 to 0." |

---

---

# Factory Method and Abstract Factory

**Interview Weight:** high - Fundamental creational pattern.
Spring's BeanFactory is a Factory. Asked frequently.

---

### 🎯 Model Answer

**30 seconds:**

> Factory Method defines an interface for creating objects
> but lets subclasses decide which class to instantiate.
> Abstract Factory creates families of related objects without
> specifying concrete classes. In Java backend: Spring's
> BeanFactory is a Factory. JDBC's DriverManager.getConnection()
> is a Factory Method. Use Factory when: object creation is
> complex, the caller shouldn't know the concrete class, or
> you need to return different implementations based on context.

**3 minutes (Senior):**

> Factory Method vs Abstract Factory:
>
> Factory Method:
>   One method creates one product.
>   The caller knows the interface, not the concrete class.
>   Example: `PaymentGateway createGateway(String provider)`
>   Returns: StripeGateway or PayPalGateway based on config.
>
> Abstract Factory:
>   One factory creates a FAMILY of related products.
>   Example: `DatabaseFactory` creates Connection, Statement,
>     ResultSet - all compatible with each other.
>   JDBC: each driver provides a compatible family.
>
> When to use Factory (decision framework):
>   1. Creation logic is complex (multi-step, conditional).
>   2. Caller shouldn't know the concrete type.
>   3. Different implementations selected at runtime.
>   4. Object creation needs configuration/validation.
>
> Factory in Spring:
>   @Bean method = Factory Method.
>   FactoryBean<T> = Factory that Spring manages.
>   @Conditional + @Bean = conditional Factory.
>
> Modern Java alternatives:
>   Simple cases: static factory method (List.of(), Optional.of()).
>   Spring cases: @Bean or @Component + interface.
>   Complex cases: Builder pattern (not Factory).
>
> The anti-pattern: FactoryFactory.
>   If you need a factory to create a factory:
>   you've over-abstracted. Simplify.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Factory patterns
and when to use them for object creation."

**(2) First principles:** "Factory encapsulates creation
logic. Caller knows the interface; factory decides the
concrete implementation."

**(3) Bridge:** "Factory is like a restaurant kitchen:
you order 'coffee' (interface); the kitchen decides which
beans, machine, and preparation method to use (concrete)."

---

### 💻 Code Example

```java
// Factory Method: create payment processors by type
public interface PaymentGateway {
    PaymentResult charge(Money amount, CardDetails card);
}

// Factory that selects implementation
@Component
public class PaymentGatewayFactory {
    private final Map<String, PaymentGateway> gateways;

    public PaymentGatewayFactory(
            List<PaymentGateway> allGateways) {
        this.gateways = allGateways.stream()
            .collect(Collectors.toMap(
                g -> g.getProviderName(),
                Function.identity()));
    }

    public PaymentGateway create(String provider) {
        PaymentGateway gw = gateways.get(provider);
        if (gw == null) {
            throw new UnsupportedProviderException(
                provider);
        }
        return gw;
    }
}

// Implementations: each is a Spring bean
@Component
public class StripeGateway implements PaymentGateway {
    public String getProviderName() { return "stripe"; }
    public PaymentResult charge(Money amount,
            CardDetails card) {
        // Stripe API call
    }
}

@Component
public class PayPalGateway implements PaymentGateway {
    public String getProviderName() { return "paypal"; }
    public PaymentResult charge(Money amount,
            CardDetails card) {
        // PayPal API call
    }
}

// Usage: caller doesn't know concrete class
@Service
public class CheckoutService {
    private final PaymentGatewayFactory factory;

    public PaymentResult checkout(
            Order order, String provider) {
        PaymentGateway gw = factory.create(provider);
        return gw.charge(order.total(), order.card());
    }
}
```

> **Code walkthrough:** The factory collects all PaymentGateway
> beans via Spring DI and indexes them by provider name.
> CheckoutService doesn't know about Stripe or PayPal.
> Adding a new provider: create a new @Component implementing
> PaymentGateway. Factory auto-discovers it. OCP satisfied.

---

### ⚖️ Comparison Table

| Pattern | Creates | Selection | Use Case |
|---|---|---|---|
| Factory Method | Single object | By parameter/config | Different impl by context |
| Abstract Factory | Family of objects | By factory impl | Compatible object sets |
| Builder | Complex object | Step-by-step | Many optional params |
| Static factory | Single object | By method name | Simple, descriptive creation |

---

### 🎓 Answers by Seniority

**Junior:** "Factory creates objects without the caller
knowing the concrete class. Like JDBC DriverManager
returning different Connection implementations."

**Mid:** "I implement Factory with Spring DI: inject all
implementations of an interface into a Map, then select
by key. Adding new implementations requires zero changes
to existing code."

**Senior:** "I distinguish Factory Method (one product),
Abstract Factory (product family), and static factory methods
(just naming). Most backend code needs Factory Method via
Spring DI. Abstract Factory is rare outside framework code."

---

### ⚠️ Common Misconceptions

**"Any method named create() is the Factory pattern."**
False. Factory pattern means the caller doesn't know the
concrete class. If `create()` always returns the same
concrete type, it's just a constructor wrapper, not Factory.

**"Factory replaces constructors everywhere."**
False. Use Factory only when creation varies by context,
is complex, or needs to hide the concrete type. Simple
object creation with `new` is fine.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Define, give JDBC example |
| Mid | 6 min | Spring DI-based factory implementation |
| Senior | 9 min | Factory vs Builder vs static factory decisions |

---

**[MID] Q1 - How would you implement a Factory for
notification channels that's extensible?**

*Why they ask:* Practical design exercise combining Factory + OCP.

I'd use Spring's auto-wiring as the factory mechanism:

Define the interface: NotificationChannel with send() and
supports(NotificationType) methods.

Create implementations: EmailChannel, SmsChannel, PushChannel -
each a @Component.

The "factory" is just Spring collecting all implementations:
```java
@Service
public class NotificationRouter {
    private final List<NotificationChannel> channels;

    public void send(Notification n) {
        channels.stream()
            .filter(c -> c.supports(n.type()))
            .forEach(c -> c.send(n));
    }
}
```

> **Code walkthrough:** This isn't a traditional Factory
> (no create method) but achieves the same goal: the
> caller doesn't know concrete channels. Adding a new
> channel: one new @Component. NotificationRouter never
> changes.

This is simpler than a traditional Factory because Spring
handles the registry. The supports() method handles the
selection logic. Multiple channels can handle the same
notification type (fanout).

*What separates good from great:* Recognizing that Spring DI
IS the factory registry, no separate Factory class needed.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Factory Method vs Abstract Factory distinction. |
| Hiring Manager | Extensibility, OCP compliance. |
| Bar Raiser | When NOT to use Factory (over-abstraction). |
| Peer Engineer | "Spring DI + interface = Factory without FactoryFactory. 3 lines replace 50." |

---

---

# Builder Pattern

**Interview Weight:** high - Used daily in Java backend
(Lombok, Stream API, HttpClient). Every Java dev must know it.

---

### 🎯 Model Answer

**30 seconds:**

> Builder constructs complex objects step by step,
> separating construction from representation. In Java
> backend: Lombok @Builder, StringBuilder, HttpClient.newBuilder(),
> Stream pipeline construction. Use Builder when: object has
> many optional parameters, construction requires validation,
> or you want immutable objects with flexible creation.
> The fluent API makes code self-documenting:
> `.name("X").age(25).email("x@y.com").build()`.

**3 minutes (Senior):**

> Builder variants in Java:
>
> Classic Builder (GoF):
>   Director calls builder steps in order.
>   Builder creates different representations.
>   Example: DocumentBuilder creates PDF or HTML.
>
> Fluent Builder (modern Java, most common):
>   Method chaining: each setter returns this.
>   build() validates and creates immutable object.
>   Example: Lombok @Builder, custom builders.
>
> Step Builder (guided construction):
>   Each step returns next step's interface.
>   Compiler enforces required fields.
>   Example: Immutables @Value.Immutable.
>
> When to use Builder vs constructor vs setters:
>   Constructor: <4 params, all required.
>   Builder: >4 params OR optional params OR validation.
>   Setters: mutable object, not recommended for domain objects.
>
> Builder + immutability:
>   Builder collects mutable state during construction.
>   build() creates immutable object (final fields).
>   Result: thread-safe, predictable objects.
>
> Builder in frameworks:
>   Spring: WebClient.builder(), RestTemplate builder.
>   JPA: CriteriaBuilder (query construction).
>   Java SDK: HttpClient.newBuilder(), ProcessBuilder.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Builder pattern
for constructing complex objects."

**(2) First principles:** "Builder separates construction
logic from the object itself. Enables step-by-step creation
with validation at build() time."

**(3) Bridge:** "Builder is like ordering a custom sandwich:
you choose ingredients step by step, and the final sandwich
is assembled only when you say 'done.'"

---

### 💻 Code Example

```java
// BAD: Telescoping constructor anti-pattern
public class EmailMessage {
    public EmailMessage(String to, String subject,
            String body) { ... }
    public EmailMessage(String to, String subject,
            String body, String cc) { ... }
    public EmailMessage(String to, String subject,
            String body, String cc, String bcc) { ... }
    public EmailMessage(String to, String subject,
            String body, String cc, String bcc,
            List<Attachment> attachments) { ... }
    // 6 constructors, confusing parameter order
}
// Usage: which String is cc? which is bcc?
// new EmailMessage("a@b.com", "Hi", "Body", null, null, null)

// GOOD: Builder pattern (manual implementation)
public class EmailMessage {
    private final String to;
    private final String subject;
    private final String body;
    private final String cc;
    private final String bcc;
    private final List<Attachment> attachments;

    private EmailMessage(Builder builder) {
        this.to = builder.to;
        this.subject = builder.subject;
        this.body = builder.body;
        this.cc = builder.cc;
        this.bcc = builder.bcc;
        this.attachments = List.copyOf(
            builder.attachments);
    }

    public static Builder builder(String to,
            String subject) {
        return new Builder(to, subject);
    }

    public static class Builder {
        // Required
        private final String to;
        private final String subject;
        // Optional with defaults
        private String body = "";
        private String cc;
        private String bcc;
        private List<Attachment> attachments =
            new ArrayList<>();

        private Builder(String to, String subject) {
            this.to = Objects.requireNonNull(to);
            this.subject = Objects.requireNonNull(subject);
        }

        public Builder body(String body) {
            this.body = body;
            return this;
        }

        public Builder cc(String cc) {
            this.cc = cc;
            return this;
        }

        public Builder attachment(Attachment att) {
            this.attachments.add(att);
            return this;
        }

        public EmailMessage build() {
            // Validation at build time
            if (body.isEmpty() && attachments.isEmpty()) {
                throw new IllegalStateException(
                    "Email must have body or attachment");
            }
            return new EmailMessage(this);
        }
    }
}

// Usage: self-documenting, order-independent
EmailMessage email = EmailMessage.builder("a@b.com", "Hi")
    .body("Hello, world")
    .cc("boss@company.com")
    .attachment(invoice)
    .build();

// With Lombok (same result, zero boilerplate):
@Builder
@Value  // immutable
public class EmailMessage {
    String to;
    String subject;
    @Builder.Default String body = "";
    String cc;
    String bcc;
    @Singular List<Attachment> attachments;
}
```

> **Code walkthrough:** Telescoping constructors become
> unreadable with >3 parameters. Builder solves this:
> named methods make parameters clear, optional fields
> have defaults, validation happens at build(). The Lombok
> version generates identical code with zero boilerplate.
> @Singular enables adding attachments one at a time.

---

### 🎓 Answers by Seniority

**Junior:** "Builder constructs objects step by step. I use
Lombok @Builder for DTOs with many fields."

**Mid:** "Builder enables immutable objects with flexible
creation. build() is the validation gate. I use it for
any object with >3 parameters or complex construction logic."

**Senior:** "I choose Builder for domain objects (validation,
immutability), records for simple data carriers (<5 fields),
and static factory methods for well-known configurations
(EmailMessage.welcome(user))."

---

### ⚠️ Common Misconceptions

**"Builder is only for objects with many fields."**
Also valuable for: immutability enforcement, complex
validation at build time, self-documenting construction
(named methods vs positional args).

**"Lombok @Builder replaces understanding the pattern."**
Understanding how Builder works underneath (inner class,
method chaining, build() validation) is needed to extend
it or debug issues with Lombok-generated code.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Basic implementation, Lombok |
| Mid | 6 min | Validation in build(), immutability |
| Senior | 9 min | Step Builder, Builder + inheritance |

---

**[MID] Q1 - How does Builder enforce required vs
optional fields?**

*Why they ask:* Tests understanding beyond basic fluent API.

Three approaches to enforce required fields:

Approach 1: Required in constructor, optional via methods.
```java
Builder(String to, String subject)  // required
.body(...)  // optional
.build()
```
If `to` is null, constructor throws immediately.

Approach 2: Step Builder (compile-time enforcement).
```java
interface NeedsTo { NeedsSubject to(String to); }
interface NeedsSubject { OptionalFields subject(String s); }
interface OptionalFields {
    OptionalFields body(String b);
    EmailMessage build();
}
```

> **Code walkthrough:** The Step Builder forces a specific
> order via interfaces. The compiler prevents calling
> build() before to() and subject(). Optional fields are
> available after required fields are set.

Approach 3: Validation in build().
```java
public EmailMessage build() {
    if (to == null) throw new IllegalStateException(
        "to is required");
    if (subject == null) throw new IllegalStateException(
        "subject is required");
    return new EmailMessage(this);
}
```

Trade-off: Step Builder catches errors at compile time
but creates more interfaces. build() validation is simpler
but fails at runtime.

*What separates good from great:* Naming all three approaches
with trade-offs rather than just one implementation.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implementation, thread safety, immutability. |
| Hiring Manager | Code readability, API design. |
| Bar Raiser | Builder vs record, Step Builder trade-offs. |
| Peer Engineer | "Switched from 8-param constructors to Builder. PR review comments about wrong parameter order: eliminated." |

---

---

# Adapter Pattern

**Interview Weight:** working knowledge - Essential for
integration work. Every backend integrates external APIs.

---

### 🎯 Model Answer

**30 seconds:**

> Adapter makes incompatible interfaces work together by
> wrapping one interface to match another. In Java backend:
> converting external API responses to your domain model,
> wrapping legacy code behind modern interfaces, or making
> a third-party library conform to your port interface.
> Spring's HandlerAdapter adapts different controller types
> to DispatcherServlet's uniform calling interface.

**3 minutes (Senior):**

> Adapter use cases in backend:
>
> Integration adapter (most common):
>   External Stripe API returns StripeCharge.
>   Your domain expects PaymentResult.
>   Adapter: converts StripeCharge to PaymentResult.
>
> Legacy adapter:
>   Old system uses XML SOAP interface.
>   New system expects REST DTOs.
>   Adapter: wraps SOAP client, returns DTOs.
>
> Framework adapter:
>   Spring HandlerAdapter: adapts @Controller methods
>   to uniform handle() method that DispatcherServlet calls.
>
> Two forms:
>   Object Adapter (composition): holds reference to adaptee.
>     Preferred in Java - flexible, testable.
>   Class Adapter (inheritance): extends adaptee.
>     Rare in Java - tight coupling, inflexible.
>
> Adapter vs Facade:
>   Adapter: makes ONE interface look like ANOTHER.
>   Facade: simplifies a COMPLEX subsystem into one interface.
>
> Adapter in hexagonal architecture:
>   Ports = interfaces your domain defines.
>   Adapters = implementations that convert external
>     systems to match your ports.
>   Primary adapters: inbound (REST controller).
>   Secondary adapters: outbound (database, APIs).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Adapter pattern
for making incompatible interfaces work together."

**(2) First principles:** "Adapter wraps one interface to
present another. The caller sees the expected interface;
the adapter translates calls to the incompatible target."

**(3) Bridge:** "Adapter is like a power plug converter:
your device expects one plug shape, the adapter converts
to the wall socket's shape."

---

### 💻 Code Example

```java
// Your domain port (what your service expects)
public interface PaymentGateway {
    PaymentResult charge(Money amount, PaymentMethod method);
}

// External Stripe SDK (incompatible interface)
public class StripeClient {
    public StripeCharge createCharge(
            long amountCents, String currency,
            String token) { ... }
}

// ADAPTER: makes Stripe conform to your port
@Component
public class StripePaymentAdapter implements PaymentGateway {
    private final StripeClient stripe;

    public StripePaymentAdapter(StripeClient stripe) {
        this.stripe = stripe;
    }

    @Override
    public PaymentResult charge(
            Money amount, PaymentMethod method) {
        try {
            StripeCharge charge = stripe.createCharge(
                amount.toCents(),
                amount.currency().getCode(),
                method.token());
            return PaymentResult.success(charge.getId());
        } catch (StripeException e) {
            return PaymentResult.failure(e.getMessage());
        }
    }
}

// Service: knows nothing about Stripe
@Service
public class CheckoutService {
    private final PaymentGateway gateway;

    public OrderResult checkout(Order order) {
        PaymentResult result = gateway.charge(
            order.total(), order.paymentMethod());
        // Works with Stripe, PayPal, or any adapter
        return result.isSuccess()
            ? OrderResult.confirmed(order)
            : OrderResult.failed(result.reason());
    }
}
```

> **Code walkthrough:** The adapter converts between Stripe's
> interface (amountCents, currency, token) and your domain's
> interface (Money, PaymentMethod). CheckoutService depends
> only on PaymentGateway (your port). Swapping to PayPal:
> write PayPalAdapter. Zero changes to CheckoutService.
> Exception handling is localized in the adapter.

---

### 🎓 Answers by Seniority

**Junior:** "Adapter wraps one interface to match another.
Like converting a third-party API response to your DTO."

**Mid:** "I use Adapter in hexagonal architecture: my domain
defines a port interface, adapters implement it by wrapping
external systems. This isolates external API changes from
domain code."

**Senior:** "Adapter is the integration isolation pattern.
Every external dependency (payment, email, storage) gets
an adapter. When Stripe changes their SDK, I change one
adapter. Domain and tests are unaffected."

---

### ⚠️ Common Misconceptions

**"Adapter and Wrapper are different patterns."**
They're the same thing. "Wrapper" is the informal name.
Adapter is the GoF name.

**"Adapter adds functionality."**
No - that's Decorator. Adapter CONVERTS interfaces.
Decorator ADDS behavior. If you're adding logging,
caching, or retry logic: that's Decorator, not Adapter.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Define, simple example |
| Mid | 6 min | Hexagonal architecture adapter role |
| Senior | 9 min | Adapter vs Facade vs Decorator |

---

**[MID] Q1 - How does Adapter pattern help when
an external API changes its SDK version?**

*Why they ask:* Tests practical integration strategy.

When Stripe updates from v20 to v21 with breaking changes,
only the StripePaymentAdapter needs updating. The domain
port (PaymentGateway interface) stays the same. All
services using PaymentGateway are unaffected.

The workflow:
1. Stripe releases SDK v21 with new method signatures.
2. Update StripePaymentAdapter to use new SDK methods.
3. Adapter still returns PaymentResult (your domain type).
4. Run adapter-level integration tests.
5. All service-level tests pass without changes.

Without adapter: Stripe SDK types leak into your domain.
SDK v21 breaks 50 files across 12 services. Migration
becomes a multi-sprint project.

With adapter: SDK v21 breaks 1 file (the adapter). Fix
takes 30 minutes. No downstream impact.

The investment: one adapter class per external dependency.
The payoff: external changes contained to one file.

*What separates good from great:* Quantifying the blast
radius difference (1 file vs 50 files).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Adapter implementation, class vs object adapter. |
| Hiring Manager | Integration isolation, change containment. |
| Bar Raiser | Adapter vs Decorator vs Facade distinction. |
| Peer Engineer | "Stripe SDK update: 1 adapter class, 30 min. Without adapter last time: 3 sprints." |

---

---

# Decorator Pattern

**Interview Weight:** high - Used extensively in Java
(I/O streams, Spring interceptors). Tests composition thinking.

---

### 🎯 Model Answer

**30 seconds:**

> Decorator adds behavior to objects dynamically by wrapping
> them in another object with the same interface. Java's
> classic example: I/O streams (BufferedReader wraps FileReader
> wraps InputStreamReader). In Spring: HandlerInterceptors
> decorate request handling, ResponseBodyAdvice decorates
> serialization. Key advantage: add behavior without modifying
> the original class and without subclass explosion.

**3 minutes (Senior):**

> Decorator mechanics:
>   Both decorator and target implement same interface.
>   Decorator holds reference to target (composition).
>   Decorator delegates to target + adds behavior.
>   Multiple decorators can be stacked (chain).
>
> Java I/O (textbook Decorator):
>   new BufferedReader(new InputStreamReader(
>       new FileInputStream("file.txt")))
>   Each layer adds behavior:
>     FileInputStream: raw bytes from file.
>     InputStreamReader: bytes to characters.
>     BufferedReader: buffering for efficiency.
>
> Backend use cases:
>   Logging decorator: log method calls before/after.
>   Caching decorator: check cache before calling target.
>   Retry decorator: retry on failure.
>   Validation decorator: validate input before processing.
>   Metrics decorator: measure execution time.
>
> Decorator vs Spring AOP:
>   Decorator: explicit, visible in code.
>   AOP: implicit, annotation-driven (@Cacheable, @Retryable).
>   Both add cross-cutting behavior without modifying target.
>   AOP = "magic" (proxy-based). Decorator = explicit wrapping.
>
> When to prefer Decorator over AOP:
>   1. Behavior is domain-specific (not cross-cutting).
>   2. Order of decoration matters and must be explicit.
>   3. Testing: easier to unit test explicit decorators.
>   4. Debugging: stack trace shows decorator chain.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Decorator pattern
for adding behavior dynamically through composition."

**(2) First principles:** "Same interface, wraps target,
delegates + adds behavior. Stack multiple decorators
for combined behavior."

**(3) Bridge:** "Decorator is like adding toppings to a
pizza: each topping wraps the previous one, adding flavor
without changing the base pizza recipe."

---

### 💻 Code Example

```java
// Interface
public interface OrderProcessor {
    OrderResult process(Order order);
}

// Core implementation
@Component("coreProcessor")
public class CoreOrderProcessor implements OrderProcessor {
    public OrderResult process(Order order) {
        // Business logic: validate, persist, return
        return OrderResult.success(order);
    }
}

// Decorator 1: logging
public class LoggingOrderProcessor
        implements OrderProcessor {
    private final OrderProcessor delegate;
    private static final Logger log =
        LoggerFactory.getLogger(LoggingOrderProcessor.class);

    public LoggingOrderProcessor(OrderProcessor delegate) {
        this.delegate = delegate;
    }

    public OrderResult process(Order order) {
        log.info("Processing order: {}", order.id());
        OrderResult result = delegate.process(order);
        log.info("Order result: {}", result.status());
        return result;
    }
}

// Decorator 2: retry
public class RetryOrderProcessor
        implements OrderProcessor {
    private final OrderProcessor delegate;
    private final int maxRetries;

    public RetryOrderProcessor(
            OrderProcessor delegate, int maxRetries) {
        this.delegate = delegate;
        this.maxRetries = maxRetries;
    }

    public OrderResult process(Order order) {
        for (int i = 0; i <= maxRetries; i++) {
            try {
                return delegate.process(order);
            } catch (TransientException e) {
                if (i == maxRetries) throw e;
                // retry
            }
        }
        throw new IllegalStateException("unreachable");
    }
}

// Composition: stack decorators
@Configuration
public class OrderConfig {
    @Bean
    public OrderProcessor orderProcessor(
            @Qualifier("coreProcessor")
            OrderProcessor core) {
        return new LoggingOrderProcessor(
            new RetryOrderProcessor(core, 3));
    }
}
// Call chain: Logging → Retry → Core
```

> **Code walkthrough:** Each decorator wraps the next,
> adding one behavior. LoggingOrderProcessor logs before/after.
> RetryOrderProcessor retries on transient failures.
> The core processor handles business logic. Adding
> a new behavior (caching, metrics): write a new decorator,
> add it to the chain. No existing code modified.

---

### 🎓 Answers by Seniority

**Junior:** "Decorator wraps an object to add behavior.
Like BufferedReader wrapping FileReader adds buffering."

**Mid:** "I use Decorator for cross-cutting concerns when
I want explicit control over ordering. Logging → Retry →
Validation → Core. Each decorator is independently testable."

**Senior:** "I choose Decorator over AOP when the behavior
is specific to one service (not cross-cutting), when ordering
must be explicit, or when debugging needs clear stack traces.
AOP for generic cross-cutting (logging, metrics). Decorator
for domain-specific behavior chains."

---

### ⚠️ Common Misconceptions

**"Decorator and Proxy are the same thing."**
Different intent. Decorator ADDS behavior (logging, retry).
Proxy CONTROLS ACCESS (lazy loading, security check).
Implementation is similar (both wrap), but purpose differs.

**"Spring AOP replaces the need for Decorator."**
AOP handles cross-cutting concerns. Decorator handles
domain-specific behavior chains where explicit ordering
and composition matter. Both have their place.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | I/O streams example |
| Mid | 6 min | Custom decorator implementation |
| Senior | 9 min | Decorator vs AOP decision |

---

**[SENIOR] Q1 - When would you prefer explicit Decorator
over Spring AOP?**

*Why they ask:* Tests nuanced decision-making.

I prefer explicit Decorator in three situations:

First, domain-specific behavior chains. If the retry logic
is specific to order processing (retry 3x with exponential
backoff for payment failures only), it belongs in an
explicit OrderRetryDecorator, not a generic @Retryable
that applies uniformly.

Second, when ordering is critical and must be visible.
If validation must happen before logging, and logging
before retry, explicit composition makes this crystal clear:
`new ValidationDecorator(new LoggingDecorator(new RetryDecorator(core)))`.
AOP ordering via @Order is implicit and error-prone.

Third, testing. Each decorator is independently unit-testable.
Pass a mock delegate, verify the decorator adds its behavior.
AOP aspects are harder to unit test in isolation.

I prefer AOP for: generic cross-cutting (all methods get
timing metrics), widely-applied concerns (@Transactional
on all service methods), and when the team expects annotations.

*What separates good from great:* Three concrete criteria
for the decision rather than "it depends."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implementation, I/O streams, Spring decorators. |
| Hiring Manager | Code extensibility, behavior composition. |
| Bar Raiser | Decorator vs Proxy vs AOP decision. |
| Peer Engineer | "Explicit decorator chain: stack trace shows exactly where retry failed. AOP: 'somewhere in a proxy.'" |
