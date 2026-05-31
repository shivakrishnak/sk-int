---
layout: default
title: "Java EE - L1 CDI and Beans"
parent: "Java EE"
nav_order: 3
permalink: /java-ee/l1-cdi-and-beans/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 7 | [CDI Beans and Scopes](#cdi-beans-and-scopes) | ★☆☆ |
| 8 | [Dependency Injection with CDI](#dependency-injection-with-cdi) | ★☆☆ |
| 9 | [Bean Validation](#bean-validation) | ★☆☆ |

---

# CDI Beans and Scopes

**Interview Weight:** ★☆☆ - Foundational. CDI is the
standard dependency injection framework for Jakarta EE.
Understanding CDI scopes is required for any Java EE
interview.

---

### 🎯 Model Answer

**30 seconds:**

> CDI (Contexts and Dependency Injection) is the
> Jakarta EE standard for managing bean lifecycle and
> injection. A CDI bean is any Java class in a CDI-enabled
> archive. Scopes control how long a bean instance lives:
> `@RequestScoped` (per HTTP request), `@SessionScoped`
> (per user session), `@ApplicationScoped` (one instance
> for the whole app), `@Dependent` (same lifetime as
> the injecting bean, the default). Scope choice determines
> thread safety requirements: ApplicationScoped beans
> are shared across all threads and must be thread-safe.

**3 minutes:**

> CDI's central concept is the managed bean lifecycle,
> controlled by scopes:
>
> @RequestScoped: created at the start of an HTTP
> request, destroyed at the end. One instance per request.
> Not shared across threads. Appropriate for: Servlet
> handlers, JAX-RS resources, request-specific services.
>
> @SessionScoped: created when a user session starts,
> destroyed when the session expires or is invalidated.
> Must implement `Serializable` (for session passivation).
> Appropriate for: user preferences, shopping cart.
> Risk: memory bloat with many concurrent sessions.
>
> @ApplicationScoped: one instance for the entire
> application. Shared across all requests and sessions.
> Must be thread-safe - multiple threads access it
> concurrently. Appropriate for: caches, connection
> pools, stateless services.
>
> @Dependent (default): bean instance is created for
> each injection point and destroyed when the owning
> bean is destroyed. No shared state. Appropriate for:
> utilities, helpers, non-shared components.
>
> @ConversationScoped: developer-controlled scope
> that spans multiple requests within a user session.
> Started/ended via `Conversation.begin()` and
> `end()`. Appropriate for: multi-step wizards.
>
> The key insight: scope determines thread safety.
> @ApplicationScoped = must be thread-safe. @RequestScoped
> = one thread at a time (within an HTTP request).

**Blank Mind Recovery:**

**(1) Restate:** "Scopes: Request (per request), Session
(per user), Application (one instance, thread-safe),
Dependent (default, per injection point)."

**(2) First principles:** "DI containers create and destroy
bean instances. Scope = when to create a new instance
vs reuse an existing one."

**(3) Bridge:** "Same as Spring: @RequestScope, @SessionScope,
@ApplicationScope. CDI uses @RequestScoped, @SessionScoped,
@ApplicationScoped."

---

### 📘 Concept Explanation

**What it is:**

CDI (JSR 299/346/365) is the Jakarta EE specification
for type-safe dependency injection and contextual
bean lifecycle management. It defines how beans
are created, injected, and destroyed based on scope
annotations.

**The problem it solves:**

Without CDI: code instantiates its dependencies
with `new` - tightly coupled, untestable. With CDI:
the container manages dependencies and their lifetimes.
Classes just declare what they need with `@Inject`.

**CDI scope comparison:**

```
CDI SCOPE LIFETIME:

@Dependent       created per injection point
@RequestScoped   |----request----|
@SessionScoped   |--user session (minutes to hours)--|
@ApplicationScoped |--app lifetime--|

CDI SCOPE THREAD SAFETY:

@Dependent       no sharing, no concern
@RequestScoped   single HTTP thread (usually safe)
@SessionScoped   one user, but async requests can share
@ApplicationScoped many threads - MUST be thread-safe
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**beans.xml activation:**

```xml
<!-- WEB-INF/beans.xml: CDI activation (pre-CDI 4.0) -->
<!-- Empty file is sufficient: -->
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="https://jakarta.ee/xml/ns/jakartaee"
       version="4.0"
       bean-discovery-mode="all">
</beans>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

CDI 4.0 (Jakarta EE 10): `bean-discovery-mode="annotated"`
is the new default - only annotated classes are
CDI beans. `"all"` was the old default.

**Scope annotations:**

```java
@RequestScoped
public class OrderProcessor {
    // new instance per HTTP request
    // safe: only one thread accesses this per request
}

@SessionScoped
public class ShoppingCart
        implements java.io.Serializable {
    // one per user session
    // must be Serializable for session passivation
    private final List<Item> items = new ArrayList<>();
    // thread safety: usually one user, one thread
    // but async requests can violate this
}

@ApplicationScoped
public class ProductCache {
    // one instance for entire application
    // MUST be thread-safe: many concurrent threads
    private final java.util.concurrent.ConcurrentHashMap<
        Long, Product> cache = new ConcurrentHashMap<>();
}

// @Dependent is default - no annotation needed
public class EmailFormatter {
    // created fresh for each injection point
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Key insight:**

`@ApplicationScoped` is the CDI equivalent of
a Spring `@Singleton` bean. It is shared across all
threads. This is the most common source of
thread safety bugs in CDI applications.

---

### 💻 Code Example

```java
// Full example: scopes in a shopping flow

// ApplicationScoped: shared service, thread-safe
@ApplicationScoped
public class ProductService {
    // ConcurrentHashMap: thread-safe
    private final Map<Long, Product> productDb =
        new ConcurrentHashMap<>();

    public Product find(Long id) {
        return productDb.get(id);
    }

    // AtomicLong: thread-safe counter
    private final AtomicLong requestCount =
        new AtomicLong();

    public long totalRequests() {
        return requestCount.incrementAndGet();
    }
}

// SessionScoped: per-user cart
@SessionScoped
public class ShoppingCart
        implements Serializable {
    private static final long serialVersionUID = 1L;

    // No thread-safety concern usually,
    // but use synchronized for async requests:
    private final List<CartItem> items =
        Collections.synchronizedList(new ArrayList<>());

    public void addItem(Product p, int qty) {
        items.add(new CartItem(p, qty));
    }

    public List<CartItem> getItems() {
        return Collections.unmodifiableList(items);
    }
}

// RequestScoped: per-request handler
@Path("/cart")
@RequestScoped
public class CartResource {

    @Inject
    private ShoppingCart cart; // session-scoped, proxied

    @Inject
    private ProductService productService; // app-scoped

    @POST
    @Path("/{productId}")
    public Response addToCart(
        @PathParam("productId") Long productId,
        @QueryParam("qty") @DefaultValue("1") int qty
    ) {
        Product p = productService.find(productId);
        if (p == null) {
            return Response.status(404).build();
        }
        cart.addItem(p, qty);
        return Response.ok(cart.getItems()).build();
    }
}
```

> **Code walkthrough:** Three scopes in one flow.
> `ProductService` is `@ApplicationScoped`: one instance
> serves all requests, so `ConcurrentHashMap` and
> `AtomicLong` are essential. `ShoppingCart` is
> `@SessionScoped`: one per logged-in user. It implements
> `Serializable` because the container may passivate
> sessions to disk. `Collections.synchronizedList`
> guards against async requests on the same session.
> `CartResource` is `@RequestScoped`: new instance per
> HTTP request. It injects both `ShoppingCart` (session-scoped)
> and `ProductService` (app-scoped) via CDI proxies.
> CDI automatically resolves the scope difference:
> the session-scoped cart is always the correct one
> for the current HTTP session.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "CDI scopes determine how long a bean instance lives.
> @RequestScoped: one per HTTP request. @SessionScoped:
> one per user session (must be Serializable). @ApplicationScoped:
> one for the whole app (must be thread-safe). @Dependent
> (default): one per injection point. The thread safety
> rule: @ApplicationScoped beans are shared across
> all threads and must be designed for concurrency."

---

**Senior / Staff:**

> "The subtle CDI scope issue I've seen in production:
> injecting a @RequestScoped bean into a @ApplicationScoped
> one. CDI allows this via proxies, but the @ApplicationScoped
> bean holds a proxy that delegates to the current
> request's bean. If the @ApplicationScoped bean stores
> the injected reference in an instance variable and
> uses it outside a request context (e.g., in an
> @Asynchronous method or @Schedule), the proxy throws
> ContextNotActiveException. The fix: never store
> narrower-scoped beans as instance fields in wider-scoped beans."

---

### ⚠️ Common Misconceptions

**Misconception: "@ApplicationScoped beans are automatically thread-safe."**

CDI makes `@ApplicationScoped` beans shared across
all threads, but it does NOT make them thread-safe.
Your code must ensure thread safety: use immutable
state, `ConcurrentHashMap`, `AtomicLong`, or
explicit synchronization. A plain `HashMap` as an
instance field in a `@ApplicationScoped` bean is
a race condition waiting to happen. The annotation
only means "one instance for the application" - the
developer is responsible for thread safety within
that instance.

---

### 🚨 Failure Modes and Diagnosis

**Failure: ContextNotActiveException for @RequestScoped
bean in async context**

*Symptom:* `jakarta.enterprise.context.ContextNotActiveException`
thrown from an EJB @Asynchronous method or @Schedule
task that injects a @RequestScoped bean.

*Root cause:* @RequestScoped requires an active HTTP
request context. Background threads don't have one.

*Diagnosis:*
```bash
# Stack trace shows ContextNotActiveException
# originating from a Proxy class (CDI client proxy)
java.lang.Exception:
  ContextNotActiveException: CDI context not active
  at Proxy$_$$_WeldClientProxy.getItem(Generated)
  at com.example.OrderJob.process(OrderJob.java:42)
  at com.example.OrderJob$Proxy.process(Generated)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:*
```java
// WRONG: inject @RequestScoped bean into @Singleton EJB
@Singleton
@Startup
public class ScheduledJob {
    @Inject
    private RequestScopedService svc; // BROKEN in timer

    @Schedule(second="*/30")
    public void run() {
        svc.process(); // ContextNotActiveException
    }
}

// RIGHT: use @ApplicationScoped or @Dependent for
// beans that run in background contexts
@Singleton
@Startup
public class ScheduledJob {
    @Inject
    private ApplicationScopedService svc; // correct

    @Schedule(second="*/30")
    public void run() {
        svc.process(); // works: no request context needed
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| CDI scope comparison | 2-3 min |
| @ApplicationScoped thread safety | 3 min |
| Scope mismatch injection issue | 3-4 min |
| SessionScoped Serializable requirement | 2 min |
| CDI vs Spring beans | 2-3 min |
| beans.xml and discovery mode | 2-3 min |
| @ConversationScoped use case | 2-3 min |

---

**[MID] Q1 - Why must @SessionScoped beans
implement Serializable?**

*Why they ask:* CDI contract understanding.

`@SessionScoped` beans are associated with an HTTP
session. The Servlet container may:
1. Passivate sessions to disk when memory is low.
2. Replicate sessions to other cluster nodes (WildFly
   Infinispan / Redis-backed sessions).

Both operations require serialization. If a `@SessionScoped`
bean doesn't implement `Serializable`, passivation
throws a `NotSerializableException` and the session
may be lost.

Practical implication:
- All instance variables of a `@SessionScoped` bean
  must also be serializable.
- If a field can't be serialized (e.g., database connection),
  mark it `transient` and reinitialize it with `@PostActivate`.

```java
@SessionScoped
public class UserPreferences implements Serializable {
    private static final long serialVersionUID = 1L;

    private String theme;
    private Locale locale;

    @Transient  // not serialized
    private transient SomeService service;

    // Reinitialize after session passivation
    @PostActivate
    public void onActivate() {
        // re-inject or reinitialize transient fields
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "The serialVersionUID matters for session replication across cluster nodes running different application versions. Without a consistent serialVersionUID, upgrading the app while sessions are active causes InvalidClassException. I always add serialVersionUID explicitly to @SessionScoped beans."

---

**[MID] Q2 - What is the difference between
@Dependent and other CDI scopes?**

*Why they ask:* Understanding the default CDI scope.

`@Dependent` is CDI's default scope. A `@Dependent`
bean:
- Is created fresh for each injection point
- Does not have its own context - it shares the
  lifecycle of the bean that injected it
- Is destroyed when its owner is destroyed
- Is NOT proxied by CDI (unlike @ApplicationScoped etc.)

Implications:
1. Multiple injections of the same @Dependent bean
   = multiple instances (not shared):
   ```java
   @ApplicationScoped
   public class Service {
       @Inject Helper h1; // instance A
       @Inject Helper h2; // instance B - different!
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. Stateful @Dependent beans: state is private to
   each injection point.

3. No proxy: @Dependent beans are injected directly
   (no wrapper). Other scopes get a proxy.

Use @Dependent for: utility classes, formatters,
helper objects that should not be shared.

*What separates good from great:* "The no-proxy behavior of @Dependent is important for performance in tight loops. @ApplicationScoped beans are accessed through a CDI proxy that adds a method dispatch overhead. For utility objects called millions of times, @Dependent avoids this proxy overhead."

---

**[MID] Q3 - How does CDI handle injecting a
narrower-scoped bean into a wider-scoped one?**

*Why they ask:* CDI proxy mechanism.

CDI uses client proxies to inject narrower-scoped
beans:

```java
@ApplicationScoped
public class OrderService {
    @Inject
    private ShoppingCart cart; // @SessionScoped
    // cart is a CDI proxy, not the actual bean
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

When `cart.addItem()` is called: the proxy looks
up the current session context and delegates to
the actual `ShoppingCart` for that session.

This works as long as there IS a current context.
Failure case: calling through the proxy when no
context is active:
- Background thread (no session context)
- @Asynchronous EJB method
- @Schedule timer

CDI throws `ContextNotActiveException` in these cases.

Rule: inject only same-scoped or wider-scoped beans
as persistent references. For narrower scopes: use
`Instance<T>` to programmatically obtain the bean
when the context is active.

*What separates good from great:* "The proxy-based injection is transparent for HTTP request paths. The bug only appears in non-HTTP contexts. Always check: does this injection point get used in a background thread? If yes, the injected bean must be at least @ApplicationScoped or @Dependent."

---

**[MID] Q4 - What is CDI's bean-discovery-mode
and why does it matter?**

*Why they ask:* CDI 4.0 behavior change awareness.

`bean-discovery-mode` in beans.xml controls which
classes CDI discovers and manages:

- `"all"`: every class in the archive is a potential
  CDI bean (CDI 1.0-3.0 default behavior).
- `"annotated"` (CDI 4.0 default): only classes
  with CDI annotations (@ApplicationScoped, @Inject, etc.)
  are beans. Reduces scan overhead and surprises.
- `"none"`: no CDI scanning. Used to exclude JARs.

Problem with `"all"`: CDI tries to manage every
class, including third-party library classes. This
causes deployment errors ("ambiguous dependency")
when libraries include classes that CDI shouldn't manage.

Migrating from Jakarta EE 9 to 10 (CDI 3 to 4):
existing apps that relied on `"all"` discovery must
either add a beans.xml with `bean-discovery-mode="all"`
or annotate their beans explicitly.

*What separates good from great:* "bean-discovery-mode='annotated' is the better default for large applications: it speeds up CDI startup scanning and prevents accidental CDI management of library classes. I always add @ApplicationScoped or @RequestScoped explicitly to all CDI beans rather than relying on 'all' mode."

---

**[MID] Q5 - How do you produce a CDI bean
conditionally with @Produces?**

*Why they ask:* CDI factory/conditional bean pattern.

`@Produces` creates CDI beans via factory methods:
```java
@ApplicationScoped
public class ConfigFactory {

    @Produces
    @ApplicationScoped
    public DataSource produceDataSource() {
        // Create datasource based on environment
        if (System.getenv("DB_URL") != null) {
            return createFromEnv();
        }
        return createInMemoryForTesting();
    }

    @Produces
    @RequestScoped
    public EntityManager produceEntityManager(
        @Inject EntityManagerFactory emf
    ) {
        return emf.createEntityManager();
    }

    // Dispose: called when scope ends
    public void closeEntityManager(
        @Disposes EntityManager em
    ) {
        if (em.isOpen()) em.close();
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Use cases:
- Conditional bean creation based on config
- Producing non-CDI resources (EntityManager, Logger)
- Creating beans from external libraries

*What separates good from great:* "The @Disposes method paired with @Produces is critical for resources like EntityManager. Without @Disposes, the EntityManager leaks when the @RequestScoped context ends. CDI calls @Disposes automatically when the scope context closes."

---

**[MID] Q6 - What is @PostConstruct and @PreDestroy
in CDI?**

*Why they ask:* Bean lifecycle hooks.

`@PostConstruct`: called after CDI injects all
dependencies into the bean, before the bean is
used:
```java
@ApplicationScoped
public class ConnectionPool {
    @Inject
    private DataSourceConfig config;

    private HikariDataSource pool;

    @PostConstruct // config is injected by now
    public void init() {
        HikariConfig hk = new HikariConfig();
        hk.setJdbcUrl(config.getUrl());
        hk.setMaximumPoolSize(config.getMaxPoolSize());
        pool = new HikariDataSource(hk);
    }

    @PreDestroy // called before bean is destroyed
    public void shutdown() {
        if (pool != null) pool.close();
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Why use @PostConstruct instead of constructor injection:
- Constructor runs before CDI injects fields
- @PostConstruct runs after injection is complete
- Safe to use injected fields

*What separates good from great:* "Constructor injection (via @Inject on the constructor) is actually preferred over field injection + @PostConstruct in CDI because it makes dependencies explicit and testable without a container. But for initialization that depends on config (which itself needs injection), @PostConstruct is the correct hook."

---

**[MID] Q7 - How does CDI compare to Spring's
dependency injection?**

*Why they ask:* Ecosystem comparison.

Core similarities:
- Both use @Inject (JSR-330) for injection points
- Both have scope concepts
- Both support producer methods / @Bean factory methods
- Both support events (@Observes / @EventListener)
- Both support interceptors / AOP

Key differences:
- Spring uses @Autowired (by type, also supports @Inject)
  CDI uses @Inject + @Qualifier for disambiguation
- Spring @Configuration + @Bean vs CDI @Produces
- Spring @Value for config injection; CDI uses
  MicroProfile @ConfigProperty or @Inject + @ConfigProperty
- Spring Boot: auto-configuration via @EnableAutoConfiguration;
  CDI: no equivalent, manual extension registration
- Testing: Spring @SpringBootTest; CDI needs Arquillian
  or CDI SE for container testing

Code using only JSR-330 (@Inject, @Named, @Qualifier)
is portable between CDI and Spring.

*What separates good from great:* "Spring's auto-configuration (Spring Boot starters) is the main competitive advantage: wiring up a complete stack with minimal configuration. CDI has no equivalent out of the box. MicroProfile partially addresses this with standardized APIs, but each server wires them differently. This is why Spring Boot dominates new applications."

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


# Dependency Injection with CDI

**Interview Weight:** ★☆☆ - Foundational. @Inject,
qualifiers, alternatives, and stereotypes are the
day-to-day CDI API that every Jakarta EE developer uses.

---

### 🎯 Model Answer

**30 seconds:**

> CDI dependency injection uses `@Inject` to declare
> an injection point. The container finds the matching
> bean by type and injects it. When multiple beans
> match the same type, use `@Qualifier` annotations
> to disambiguate. `@Named` is a string-based qualifier.
> `@Alternative` marks a bean as an alternative to
> the default - activated in beans.xml for testing
> or environment-specific overrides.

**3 minutes:**

> CDI injection works by type matching: when you
> declare `@Inject private PaymentService payment`,
> CDI finds a bean of type PaymentService in the context.
>
> Disambiguation with qualifiers: if multiple beans
> implement PaymentService (e.g., PayPalService and
> StripeService), you create a `@Qualifier` annotation
> to select the right one:
> ```java
> @Qualifier
> @Target({METHOD, FIELD, TYPE, PARAMETER})
> @Retention(RUNTIME)
> public @interface PayPal {}
>
> @PayPal @ApplicationScoped
> public class PayPalService implements PaymentService {...}
>
> @Inject @PayPal
> private PaymentService payment; // gets PayPalService
> ```
>
> `@Named`: string-based qualifier. `@Named("paypal")` is
> equivalent to a custom qualifier but uses a string.
> Useful for EL expressions in JSP/Thymeleaf:
> `${paypal.charge()}`. But prefer typed qualifiers
> for Java code (refactoring-safe).
>
> Injection styles:
> - Field injection: `@Inject private Service s` (simplest, hard to test without container)
> - Constructor injection: `@Inject public Service(Dep d)` (testable, recommended)
> - Method injection: `@Inject public void setService(Service s)` (rare)
>
> `@Alternative`: register a bean as an alternative.
> Not active by default. Activate in beans.xml for
> specific environments:
> ```xml
> <alternatives>
>   <class>com.example.MockPaymentService</class>
> </alternatives>
> ```
> Use for: test doubles, environment-specific implementations.

**Blank Mind Recovery:**

**(1) Restate:** "@Inject = inject by type. @Qualifier = disambiguate
multiple implementations. @Named = string qualifier.
@Alternative = inactive bean activated per environment."

**(2) First principles:** "DI: declare what you need, not how
to build it. Qualifiers tell the container WHICH matching
bean to inject."

**(3) Bridge:** "Same as Spring @Autowired + @Qualifier.
CDI uses @Inject + custom @Qualifier annotations."

---

### 📘 Concept Explanation

**What it is:**

CDI injection connects Java classes without explicit
`new` calls. The CDI container finds the right bean
by type (and qualifier) and injects it at the declared
injection point.

**The problem it solves:**

`new SomeService()` couples code to a specific implementation,
makes testing hard, and doesn't respect lifecycle
(scope). @Inject decouples the injection point from
the implementation - the container picks the right
bean, respects scope, and manages lifecycle.

**CDI qualifier mechanism:**

```
CDI INJECTION RESOLUTION:

@Inject PaymentService payment
  |
  v
CDI scans all beans for PaymentService type
  |
  +--> No match: deployment error
  +--> Exactly one match: inject it
  +--> Multiple matches:
         Check qualifiers on injection point
         and beans for disambiguation
         If still ambiguous: deployment error
           (AmbiguousResolutionException)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Custom qualifier:**

```java
// Define qualifier annotation
@Qualifier
@Target({METHOD, FIELD, TYPE, PARAMETER})
@Retention(RUNTIME)
public @interface Production {}

@Qualifier
@Target({METHOD, FIELD, TYPE, PARAMETER})
@Retention(RUNTIME)
public @interface Testing {}

// Annotate beans
@Production @ApplicationScoped
public class RealPaymentService
        implements PaymentService { ... }

@Testing @ApplicationScoped
@Alternative  // only activated in beans.xml
public class MockPaymentService
        implements PaymentService { ... }

// Injection points
@Inject @Production
private PaymentService payment; // always RealPaymentService
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// Service interface
public interface NotificationService {
    void send(String message, String recipient);
}

// Custom qualifiers
@Qualifier
@Retention(java.lang.annotation.RetentionPolicy.RUNTIME)
@java.lang.annotation.Target({
    java.lang.annotation.ElementType.METHOD,
    java.lang.annotation.ElementType.FIELD,
    java.lang.annotation.ElementType.TYPE,
    java.lang.annotation.ElementType.PARAMETER
})
public @interface Email {}

@Qualifier
@Retention(java.lang.annotation.RetentionPolicy.RUNTIME)
@java.lang.annotation.Target({
    java.lang.annotation.ElementType.METHOD,
    java.lang.annotation.ElementType.FIELD,
    java.lang.annotation.ElementType.TYPE,
    java.lang.annotation.ElementType.PARAMETER
})
public @interface SMS {}

// Implementations
@Email @ApplicationScoped
public class EmailNotificationService
        implements NotificationService {
    @Override
    public void send(String message, String to) {
        System.out.println(
            "Email to " + to + ": " + message
        );
    }
}

@SMS @ApplicationScoped
public class SmsNotificationService
        implements NotificationService {
    @Override
    public void send(String message, String to) {
        System.out.println(
            "SMS to " + to + ": " + message
        );
    }
}

// Caller - constructor injection (preferred)
@RequestScoped
public class OrderConfirmationService {

    private final NotificationService emailSvc;
    private final NotificationService smsSvc;

    // Constructor injection: testable without container
    @Inject
    public OrderConfirmationService(
        @Email NotificationService emailSvc,
        @SMS NotificationService smsSvc
    ) {
        this.emailSvc = emailSvc;
        this.smsSvc = smsSvc;
    }

    public void confirmOrder(Order order) {
        String msg = "Order " + order.getId()
            + " confirmed!";
        emailSvc.send(msg, order.getEmail());
        smsSvc.send(msg, order.getPhone());
    }
}

// Instance<T>: programmatic bean lookup
@RequestScoped
public class DynamicNotifier {

    @Inject @Any
    private jakarta.enterprise.inject.Instance<
        NotificationService
    > services;

    public void notifyAll(String msg, String to) {
        // Iterate all NotificationService beans
        for (NotificationService svc : services) {
            svc.send(msg, to);
        }
    }
}
```

> **Code walkthrough:** Custom qualifier annotations
> `@Email` and `@SMS` carry no runtime data - they're
> purely marker types used by CDI for injection resolution.
> Both `EmailNotificationService` and `SmsNotificationService`
> implement the same interface; the qualifiers distinguish
> them. `OrderConfirmationService` uses constructor
> injection: both dependencies are declared as constructor
> parameters with qualifiers, making the class testable
> with plain `new OrderConfirmationService(mockEmail, mockSms)`
> without a CDI container. The `DynamicNotifier` shows
> `Instance<T>`: a CDI-provided holder that lazily
> resolves all beans of a type. `@Any` includes
> all matching beans regardless of qualifier.
> Iterating `Instance<T>` sends to all notification
> services - a clean extension point.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "CDI uses @Inject to inject beans by type. When
> multiple beans implement the same type, use @Qualifier
> annotations to disambiguate - create a custom annotation
> marked with @Qualifier, apply it to both the bean
> and the injection point. @Named is a built-in string
> qualifier. @Alternative marks a bean inactive by
> default, activated in beans.xml for testing."

---

**Senior / Staff:**

> "The injection style matters for testability.
> Field injection (@Inject private Service s) is
> simple but requires a CDI container for testing
> - you can't inject a mock without reflection.
> Constructor injection makes dependencies explicit
> and testable: test with new MyService(mock1, mock2).
> In new code I always prefer constructor injection.
> Field injection is fine for JAX-RS resources since
> those are tested with integration tests anyway."

---

### ⚠️ Common Misconceptions

**Misconception: "@Named is the CDI equivalent of
Spring's @Component/@Service."**

In CDI, `@Named` is a qualifier that provides a
string-based name for a bean - it is used for EL
expression injection in JSP/JSF and as a qualifier
for disambiguation. It does NOT trigger CDI scanning
or make a class a CDI bean. Any POJO in a CDI-enabled
archive is automatically a CDI bean in `bean-discovery-mode="all"`,
or must have a scope annotation in `"annotated"` mode.
`@Named` just adds a name. By contrast, Spring's
`@Component` is what triggers Spring to manage the class.

---

### 🚨 Failure Modes and Diagnosis

**Failure: AmbiguousResolutionException at deployment**

*Symptom:* Application fails to deploy with
`AmbiguousResolutionException: Ambiguous dependencies
for type PaymentService`.

*Root cause:* Multiple CDI beans of the same type
exist, no qualifier to distinguish them.

*Diagnosis:*
```bash
# Check deployment log for the ambiguous type name
grep -i "AmbiguousResolutionException\|Ambiguous" \
  server.log

# Look for all beans implementing the type
grep -r "implements PaymentService\|class.*Payment" \
  src/main/java/
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:*
```java
// Option 1: Add @Qualifier to distinguish beans
@Production @ApplicationScoped
class RealPaymentService implements PaymentService {...}

@Testing @Alternative @ApplicationScoped
class MockPaymentService implements PaymentService {...}

// Option 2: Mark one bean @Alternative (inactive by default)
// Activate the alternative in beans.xml for testing only

// Option 3: Use @Priority to set preference
@Priority(1) @ApplicationScoped
class PreferredService implements PaymentService {...}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| How CDI resolves injection by type | 2-3 min |
| Custom qualifiers vs @Named | 2-3 min |
| Constructor vs field injection | 3 min |
| @Alternative and testing | 2-3 min |
| Instance<T> programmatic lookup | 2-3 min |
| CDI interceptors | 2-3 min |
| Ambiguous resolution error | 2 min |

---

**[MID] Q1 - When would you use @Named over
a custom @Qualifier?**

*Why they ask:* CDI API selection.

`@Named("paypalService")`: string-based name.
Use when: accessing beans from EL in JSF/JSP views,
where you need to reference the bean by string name.
Also useful for quick disambiguation when you don't
want to create a new annotation file.

Custom `@Qualifier` annotation: type-safe.
Use when: Java code injection points. Typos in
string names are caught at compile time. The custom
annotation carries semantic meaning (the name documents
the intent). Refactoring (rename) works safely.

```java
// @Named: risky - string, refactoring-unfriendly
@Inject @Named("paypal")
private PaymentService payment;

// Custom qualifier: type-safe, self-documenting
@Inject @PayPal
private PaymentService payment;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Rule: use @Named for EL in views, custom qualifiers
for all Java injection points.

*What separates good from great:* "@Named is how JSF managed beans were originally exposed to JSF EL pages. In modern Jakarta EE with JAX-RS + JSON, you rarely need @Named unless you have JSF views. Custom qualifiers for all Java injection points."

---

**[MID] Q2 - How do you inject a configuration
value with CDI (non-MicroProfile)?**

*Why they ask:* CDI configuration pattern.

Without MicroProfile Config, use @Produces:
```java
@ApplicationScoped
public class ConfigProducer {

    @Produces
    @ApplicationScoped
    @Named("db.url")
    public String produceDatabaseUrl() {
        return System.getProperty(
            "db.url",
            "jdbc:h2:mem:test"
        );
    }
}

// Injection:
@Inject @Named("db.url")
private String dbUrl;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

With MicroProfile Config (preferred in modern Jakarta EE):
```java
@Inject
@ConfigProperty(name = "db.url",
                defaultValue = "jdbc:h2:mem:test")
private String dbUrl;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

MicroProfile Config reads from: system properties,
environment variables, META-INF/microprofile-config.properties.
Order of precedence: env vars > system properties > config file.

*What separates good from great:* "MicroProfile Config is the production answer - it respects the 12-factor app principle of configuration from environment. The @Produces approach is a workaround. For cloud deployments, config comes from environment variables or Kubernetes ConfigMaps, and MicroProfile Config bridges these to @Inject."

---

**[MID] Q3 - What is Instance<T> and when do
you use it?**

*Why they ask:* CDI programmatic API.

`Instance<T>` is a CDI holder for programmatically
obtaining beans:

```java
@Inject
@Any  // include all beans regardless of qualifier
private Instance<NotificationService> services;

// Obtain specific bean with qualifier:
@Inject @Any
private Instance<PaymentService> paymentServices;

// Select by qualifier programmatically:
Instance<PaymentService> paypal =
    paymentServices.select(
        new PayPalLiteral()  // AnnotationLiteral
    );
PaymentService ps = paypal.get(); // resolve instance

// Iterate all implementations:
for (NotificationService svc : services) {
    svc.notify(message);
}

// Destroy if not using a container scope:
services.destroy(ps);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Use cases:
- Extension points (iterate all implementations)
- Factory: select implementation based on runtime condition
- Lazy injection: delay bean creation to first use
- Optional beans: `services.isUnsatisfied()` checks
  if no bean exists

*What separates good from great:* "Instance<T> is the CDI equivalent of the ServiceLoader pattern, but with full DI. It's how to build plugin architectures in CDI: define an interface, let teams implement it, and use Instance<T> to discover all implementations at runtime."

---

**[MID] Q4 - What are CDI interceptors and how
do you create one?**

*Why they ask:* Cross-cutting concerns in CDI.

CDI interceptors implement cross-cutting concerns
(logging, transactions, security) via annotations:

```java
// Step 1: Define interceptor binding annotation
@InterceptorBinding
@Target({METHOD, TYPE})
@Retention(RUNTIME)
public @interface Audited {}

// Step 2: Implement interceptor
@Audited
@Interceptor
@Priority(2000)  // ordering among interceptors
public class AuditInterceptor {

    @AroundInvoke
    public Object audit(InvocationContext ctx)
            throws Exception {
        System.out.printf(
            "AUDIT: %s.%s called%n",
            ctx.getTarget().getClass().getSimpleName(),
            ctx.getMethod().getName()
        );
        long start = System.nanoTime();
        try {
            return ctx.proceed(); // call actual method
        } finally {
            long elapsed = System.nanoTime() - start;
            System.out.printf(
                "AUDIT: %s took %d ns%n",
                ctx.getMethod().getName(),
                elapsed
            );
        }
    }
}

// Step 3: Apply to beans
@ApplicationScoped
public class OrderService {

    @Audited  // interceptor invoked on this method
    public void placeOrder(Order order) {
        // business logic
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Built-in interceptors: `@Transactional` (CDI-based
transaction management in Jakarta EE 10+).

*What separates good from great:* "CDI interceptors are what @Transactional is built on in Jakarta EE 10+. You don't need @Stateless EJB just for transactions anymore: annotate a @RequestScoped CDI bean with @Transactional and the CDI interceptor manages the transaction."

---

**[MID] Q5 - What is CDI event publishing and
observation?**

*Why they ask:* CDI loose coupling pattern.

CDI events decouple producers from observers:
```java
// Event payload
public class OrderPlacedEvent {
    private final Order order;
    public OrderPlacedEvent(Order order) {
        this.order = order;
    }
    public Order getOrder() { return order; }
}

// Event producer
@ApplicationScoped
public class OrderService {

    @Inject
    private jakarta.enterprise.event.Event<
        OrderPlacedEvent
    > orderEvent;

    public void placeOrder(Order order) {
        processOrder(order);
        // Fire event - all observers notified
        orderEvent.fire(new OrderPlacedEvent(order));
    }
}

// Observer 1: sends confirmation email
@ApplicationScoped
public class EmailNotifier {
    public void onOrderPlaced(
        @Observes OrderPlacedEvent event
    ) {
        sendEmail(event.getOrder());
    }
}

// Observer 2: updates inventory
@ApplicationScoped
public class InventoryUpdater {
    public void onOrderPlaced(
        @Observes OrderPlacedEvent event
    ) {
        decrementStock(event.getOrder());
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Async events (CDI 2.0+):
```java
orderEvent.fireAsync(new OrderPlacedEvent(order));
// Observers annotated with @ObservesAsync
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "CDI events are synchronous by default - all observers run in the same thread and transaction as the producer. If an observer throws, the producer's transaction may roll back. For post-commit notifications (send email AFTER the order is committed), use @Observes(during=AFTER_SUCCESS) to ensure the observer only runs when the surrounding transaction commits successfully."

---

**[MID] Q6 - How does CDI stereotype work?**

*Why they ask:* CDI annotation composition.

`@Stereotype` is a meta-annotation that bundles CDI
annotations together:

```java
// Define a stereotype for JAX-RS resources
@Stereotype
@ApplicationScoped  // includes this scope
@Transactional      // includes this interceptor
@Named              // includes @Named
@Target(TYPE)
@Retention(RUNTIME)
public @interface Service {}

// Apply stereotype: replaces all bundled annotations
@Service
public class OrderService {
    // effectively @ApplicationScoped @Transactional @Named
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Built-in stereotype: `@Model` (Jakarta EE) = `@Named`
+ `@RequestScoped`. Used for JSF backing beans.

Benefits: reduces annotation verbosity, enforces
conventions (all @Service beans are @Transactional),
easier team-wide policy changes (update stereotype,
all beans updated).

*What separates good from great:* "Stereotypes are how you enforce architectural conventions with CDI: 'all our repository beans are @ApplicationScoped @Transactional @Logged'. Define the stereotype, and the convention is enforced by the type system rather than code review."

---

**[MID] Q7 - How do you test CDI beans without
a full application server?**

*Why they ask:* CDI testability.

Option 1: Constructor injection + plain Java tests:
```java
// No container needed when using constructor injection
class OrderServiceTest {
    @Test
    void shouldPlaceOrder() {
        // Manual injection with mocks
        PaymentService mockPayment =
            Mockito.mock(PaymentService.class);
        InventoryService mockInventory =
            Mockito.mock(InventoryService.class);
        OrderService svc = new OrderService(
            mockPayment, mockInventory
        );
        // test directly
        svc.placeOrder(new Order());
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Option 2: CDI SE (standalone CDI 2.0+):
```java
try (SeContainer container =
        SeContainerInitializer.newInstance()
            .initialize()) {
    OrderService svc = container.select(
        OrderService.class
    ).get();
    svc.placeOrder(new Order()); // full CDI context
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Option 3: Arquillian + embedded WildFly:
Full container test, slower but tests full stack.

Option 4: Quarkus @QuarkusTest:
Fast startup (~1s) with full CDI context.

*What separates good from great:* "Constructor injection makes CDI beans testable as plain Java objects - no CDI container, no Arquillian, no embedded server. This is the single most important CDI best practice for testability. Field injection forces you into Arquillian or CDI SE for any test that exercises injection."

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


# Bean Validation

**Interview Weight:** ★☆☆ - Foundational. Bean Validation
is used everywhere in Java EE: at the REST layer,
service layer, and persistence layer. Security teams
use it for input validation.

---

### 🎯 Model Answer

**30 seconds:**

> Bean Validation (jakarta.validation) defines constraint
> annotations for Java beans: `@NotNull`, `@NotBlank`,
> `@Size`, `@Min`, `@Max`, `@Email`, `@Pattern`. Add
> them to fields or method parameters, then trigger
> validation by calling `validator.validate(object)`
> or using `@Valid` on JAX-RS parameters or JPA
> entities. Jakarta EE integrates validation automatically:
> JAX-RS validates annotated request bodies, JPA validates
> before persisting entities.

**3 minutes:**

> Bean Validation decouples validation rules from
> the code that triggers them. You declare constraints
> as annotations on the model, and the framework
> validates at the right moments:
>
> Standard constraints:
> - `@NotNull`: field is not null
> - `@NotBlank`: string not null and not whitespace-only
> - `@NotEmpty`: collection/string not null and not empty
> - `@Size(min, max)`: string length or collection size
> - `@Min(value)`, `@Max(value)`: numeric range
> - `@Email`: valid email format
> - `@Pattern(regexp)`: matches regex
> - `@Positive`, `@PositiveOrZero`: positive number
>
> Integration points:
> 1. JAX-RS: `@Valid` on method parameter triggers
>    validation before the method body runs. Failure
>    = 400 Bad Request (with ExceptionMapper).
> 2. JPA: `@PrePersist` and `@PreUpdate` automatically
>    validate entities before writing to DB.
> 3. CDI: `@ValidateOnExecution` triggers validation
>    on CDI bean method calls.
> 4. Programmatic: `Validator.validate(obj)` returns
>    a set of `ConstraintViolation<T>`.
>
> Custom constraints: create an annotation + a ConstraintValidator
> implementation. Use when standard constraints don't
> cover your business rule.

**Blank Mind Recovery:**

**(1) Restate:** "Bean Validation = constraint annotations on
fields (@NotNull, @Email, etc.). @Valid triggers them.
JAX-RS and JPA integrate automatically."

**(2) First principles:** "Input validation should be declared
close to the data model, not scattered in service code.
Annotations achieve this."

**(3) Bridge:** "Same as Spring's @Validated + @Valid,
which delegates to Bean Validation (Hibernate Validator)."

---

### 📘 Concept Explanation

**What it is:**

Bean Validation (JSR 380 / Jakarta Bean Validation 3.x)
is a specification for declaring and enforcing validation
constraints on Java objects via annotations.
Hibernate Validator is the reference implementation.

**The problem it solves:**

Without Bean Validation: validation code is duplicated
across REST layer, service layer, and persistence layer.
Each layer re-validates the same rules. With Bean
Validation: declare constraints once on the model,
validate at multiple integration points automatically.

**Standard constraints:**

```java
public class UserRegistration {

    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50,
          message = "Username must be 3-50 chars")
    private String username;

    @NotNull
    @Email(message = "Must be a valid email address")
    private String email;

    @NotNull
    @Size(min = 8,
          message = "Password minimum 8 characters")
    private String password;

    @NotNull
    @Min(value = 18, message = "Must be 18 or older")
    @Max(value = 150)
    private Integer age;

    @Pattern(
        regexp = "^\\+[1-9]\\d{1,14}$",
        message = "Must be E.164 phone format"
    )
    private String phone; // optional: null is ok

    @Valid  // cascade: validate address fields too
    private Address address;
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**@Valid cascading:**

```java
public class Address {
    @NotBlank
    private String city;

    @NotBlank
    @Size(max = 10)
    private String postalCode;
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

`@Valid` on the `address` field in `UserRegistration`
triggers validation of `Address` fields too.

---

### 💻 Code Example

```java
// 1. Custom constraint: uniqueUsername
@Target({ FIELD, PARAMETER })
@Retention(RUNTIME)
@Constraint(validatedBy = UniqueUsernameValidator.class)
public @interface UniqueUsername {
    String message() default "Username already taken";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

// Validator implementation
@ApplicationScoped  // CDI bean: can inject services
public class UniqueUsernameValidator
        implements ConstraintValidator<UniqueUsername, String> {

    @Inject
    private UserRepository userRepo;

    @Override
    public boolean isValid(
        String username,
        ConstraintValidatorContext ctx
    ) {
        if (username == null) return true; // @NotNull handles null
        return !userRepo.existsByUsername(username);
    }
}

// Apply custom constraint
public class UserRegistration {
    @NotBlank
    @UniqueUsername  // custom constraint
    private String username;
}

// 2. JAX-RS integration with custom error response
@Path("/users")
@Stateless
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class UserResource {

    @POST
    public Response register(
        @Valid UserRegistration reg  // triggers validation
    ) {
        // Only reaches here if validation passes
        User user = userService.register(reg);
        return Response.status(201).entity(user).build();
    }
}

// Custom error mapper for validation failures
@Provider
public class ValidationExceptionMapper
        implements ExceptionMapper<
            jakarta.validation.ConstraintViolationException
        > {

    @Override
    public Response toResponse(
        jakarta.validation.ConstraintViolationException ex
    ) {
        Map<String, String> errors = new LinkedHashMap<>();
        for (jakarta.validation.ConstraintViolation<?> cv
                : ex.getConstraintViolations()) {
            // Extract field name from property path
            String field = cv.getPropertyPath()
                .toString()
                .replaceFirst(".*\\.", "");
            errors.put(field, cv.getMessage());
        }
        return Response.status(400)
            .entity(Map.of("errors", errors))
            .build();
    }
}

// 3. Programmatic validation
@ApplicationScoped
public class OrderService {

    @Inject
    private jakarta.validation.Validator validator;

    public void processOrder(Order order) {
        Set<jakarta.validation.ConstraintViolation<Order>>
            violations = validator.validate(order);
        if (!violations.isEmpty()) {
            throw new jakarta.validation.ConstraintViolationException(
                violations
            );
        }
        // proceed with processing
    }
}
```

> **Code walkthrough:** Three key validation patterns.
> The custom `@UniqueUsername` constraint shows how
> to validate business rules (DB uniqueness check) using
> the same annotation mechanism as built-in constraints.
> The validator is a CDI bean so it can `@Inject` the
> `UserRepository`. The null-check guard is important:
> if the field is nullable, return `true` for null
> (let `@NotNull` handle the null case separately -
> constraint composition). The `ValidationExceptionMapper`
> converts `ConstraintViolationException` to a structured
> JSON 400 response - essential for REST APIs so clients
> receive actionable error information. The programmatic
> approach uses `Validator.validate()` directly for
> service-layer validation where `@Valid` annotations
> aren't available.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Bean Validation uses annotations like @NotNull,
> @NotBlank, @Email, @Size to declare constraints
> on fields. @Valid on a JAX-RS parameter triggers
> validation before the method runs. JPA automatically
> validates entities before persisting. When validation
> fails, JAX-RS throws ConstraintViolationException
> - you handle it with an ExceptionMapper to return
> a clean 400 response."

---

**Senior / Staff:**

> "Bean Validation's real value is in layered validation:
> the same constraint annotation is checked at the REST
> layer, service layer, and persistence layer. This
> prevents invalid data from ever reaching the database.
> The production risk I watch for: custom validators
> that make database calls (@UniqueUsername). These
> must be CDI beans to inject the repository. More
> critically: if the validator queries the database,
> a slow database causes slow validation, which manifests
> as slow request response times. Cache username checks
> or only validate uniqueness at the service layer
> where you control the transaction."

---

### ⚠️ Common Misconceptions

**Misconception: "@NotEmpty and @NotBlank are the same."**

They are different for String fields.
`@NotEmpty`: not null and not empty string (`""`).
A string of spaces ("   ") passes `@NotEmpty` but fails
`@NotBlank`. `@NotBlank`: not null, not empty, and
not only whitespace. For user input like names and emails,
always use `@NotBlank` - `@NotEmpty` allows a username
of all spaces, which is almost certainly a bug.
For collections, `@NotEmpty` is appropriate (a collection
of spaces would be unusual).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Validation not triggered on service method calls**

*Symptom:* Bean Validation annotations on service
method parameters have no effect; invalid data reaches
the database.

*Root cause:* `@Valid` / `@ValidateOnExecution` only
triggers validation when:
1. The bean is a JAX-RS resource (auto-validation on @Valid params)
2. The bean is a CDI bean with `@ValidateOnExecution`
3. JPA entity is being persisted/updated

It does NOT automatically validate CDI bean method
parameters without `@ValidateOnExecution`.

*Fix:*
```java
// On CDI bean: requires @ValidateOnExecution
import jakarta.validation.executable.ValidateOnExecution;
import jakarta.validation.executable.ExecutableType;

@ApplicationScoped
@ValidateOnExecution(type = ExecutableType.ALL)
public class OrderService {
    public void placeOrder(
        @Valid @NotNull Order order
    ) {
        // now validated automatically
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Or validate programmatically with `Validator.validate()`
as a guard at the service boundary.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Standard Bean Validation constraints | 2 min |
| Custom constraint creation | 3-4 min |
| JAX-RS validation integration | 2-3 min |
| @NotEmpty vs @NotBlank | 2 min |
| Validation groups | 3 min |
| JPA validation | 2-3 min |
| Cross-field validation | 3 min |

---

**[MID] Q1 - What are validation groups and when
do you use them?**

*Why they ask:* Advanced Bean Validation.

Validation groups allow running different constraints
for different operations:

```java
// Define groups (marker interfaces)
public interface OnCreate {}
public interface OnUpdate {}

public class User {
    @Null(groups = OnCreate.class)     // null on create
    @NotNull(groups = OnUpdate.class)  // not null on update
    private Long id;

    @NotBlank  // always required (Default group)
    private String username;

    @NotBlank(groups = OnCreate.class)  // required only on create
    private String password;
}

// JAX-RS: activate specific group
@POST
public Response create(
    @Validated(OnCreate.class) User user
) { ... }

@PUT
public Response update(
    @Validated(OnUpdate.class) User user
) { ... }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

`@Validated` (Spring) or `@ConvertGroup` (Bean Validation)
activates specific groups. Without group specification,
the `Default` group runs.

*What separates good from great:* "Validation groups prevent the anti-pattern of having separate create/update DTOs just to have different validation rules. One entity class with groups covers both operations."

---

**[MID] Q2 - How do you validate cross-field
constraints (e.g., password confirmation)?**

*Why they ask:* Complex validation scenario.

Cross-field validation requires a class-level constraint:
```java
// Constraint annotation at class level
@Target(TYPE)
@Retention(RUNTIME)
@Constraint(validatedBy = PasswordMatchValidator.class)
public @interface PasswordsMatch {
    String message() default "Passwords do not match";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

// Validator checks two fields
public class PasswordMatchValidator
        implements ConstraintValidator<
            PasswordsMatch,
            RegistrationForm   // validates the whole class
        > {
    @Override
    public boolean isValid(
        RegistrationForm form,
        ConstraintValidatorContext ctx
    ) {
        if (form.getPassword() == null) return true;
        return form.getPassword().equals(
            form.getConfirmPassword()
        );
    }
}

// Apply at class level
@PasswordsMatch  // class-level constraint
public class RegistrationForm {
    @NotBlank @Size(min = 8)
    private String password;

    @NotBlank
    private String confirmPassword;
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "Class-level constraints get the whole object and can access any field. The constraint violation is associated with the class, not a specific field. To associate it with a specific field in the error response, use ctx.buildConstraintViolationWithTemplate(msg).addPropertyNode('confirmPassword').addConstraintViolation() and ctx.disableDefaultConstraintViolation()."

---

**[MID] Q3 - How does JPA validate entities before persisting?**

*Why they ask:* JPA + Bean Validation integration.

JPA calls Bean Validation automatically for `@PrePersist`
(INSERT) and `@PreUpdate` (UPDATE) operations:

```java
// Entity with constraints
@Entity
public class Product {
    @Id @GeneratedValue
    private Long id;

    @NotBlank
    @Size(max = 255)
    @Column(nullable = false)
    private String name;

    @NotNull
    @Positive
    private BigDecimal price;
}

// Validation happens automatically:
em.persist(new Product()); // throws ConstraintViolationException
// because name is blank and price is null
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

JPA validation modes (in persistence.xml):
```xml
<properties>
  <!-- auto (default): validate on persist and update -->
  <property name="jakarta.persistence.validation.mode"
            value="auto"/>
  <!-- callback: always validate -->
  <!-- none: disable JPA-triggered validation -->
</properties>
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

If validation fails: `ConstraintViolationException`
is thrown, the transaction is marked for rollback.

*What separates good from great:* "JPA validation is the last defense: it catches constraints that the service layer missed. But it's not a replacement for service-layer validation. JPA validation happens inside a transaction; a ConstraintViolationException rolls back the transaction. If you only validate at the JPA layer, you waste the transaction's work before finding out the data is invalid."

---

**[MID] Q4 - How do you handle validation errors
in JAX-RS to return useful 400 responses?**

*Why they ask:* REST API error handling.

Default JAX-RS behavior when `@Valid` fails: throws
`ConstraintViolationException`. Without an ExceptionMapper,
the server returns 400 or 500 with container-specific output.

Custom ExceptionMapper:
```java
@Provider
public class ConstraintViolationExceptionMapper
        implements ExceptionMapper<
            jakarta.validation.ConstraintViolationException
        > {

    @Override
    public Response toResponse(
        jakarta.validation.ConstraintViolationException ex
    ) {
        List<Map<String, String>> errors =
            ex.getConstraintViolations().stream()
                .map(cv -> Map.of(
                    "field", extractField(cv),
                    "message", cv.getMessage(),
                    "rejectedValue",
                        cv.getInvalidValue() != null ?
                        cv.getInvalidValue().toString() :
                        "null"
                ))
                .collect(java.util.stream.Collectors.toList());

        return Response.status(
            Response.Status.BAD_REQUEST
        ).entity(Map.of("errors", errors)).build();
    }

    private String extractField(
        jakarta.validation.ConstraintViolation<?> cv
    ) {
        String path = cv.getPropertyPath().toString();
        // "createUser.arg0.email" -> "email"
        return path.substring(path.lastIndexOf('.') + 1);
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "Never include the rejected value in production error responses for password or sensitive fields - that leaks the actual password in the 400 response body. Filter out sensitive field names before including rejectedValue."

---

**[MID] Q5 - What is @Valid vs @Validated?**

*Why they ask:* Spring vs Jakarta EE validation.

`@Valid` (Jakarta Bean Validation / JSR 380):
Standard annotation. Triggers validation on the
annotated parameter. Supports cascading (@Valid
on nested objects). Works in JAX-RS and JPA.

`@Validated` (Spring Framework):
Spring-specific annotation. Supports validation
groups (which @Valid alone cannot target in Spring).
```java
// Spring only:
@Validated(OnCreate.class)
public void create(@Valid User user) {...}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

In Jakarta EE (non-Spring):
Use `@Valid` with Bean Validation groups + `@ConvertGroup`
or manual group activation.

In Quarkus / WildFly: `@Valid` is the standard.

*What separates good from great:* "@Validated is a Spring enhancement that adds group support to @Valid. In pure Jakarta EE, you get group support via Validator.validate(obj, OnCreate.class) or @ValidateOnExecution with group configuration. @Validated is not available in non-Spring Jakarta EE."

---

**[MID] Q6 - What is the constraint composition
pattern in Bean Validation?**

*Why they ask:* Reducing annotation duplication.

Compose multiple constraints into one custom annotation:
```java
// Composed constraint: @NotBlankEmail
@NotBlank
@Email
@Size(max = 255)
@Target({ FIELD, PARAMETER })
@Retention(RUNTIME)
@Constraint(validatedBy = {})  // no validator needed
@ReportAsSingleViolation  // report one message, not three
public @interface ValidEmail {
    String message() default "Must be a valid email";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

// Usage:
public class UserForm {
    @ValidEmail  // replaces @NotBlank @Email @Size
    private String email;
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

`@ReportAsSingleViolation`: if any composed constraint
fails, report only the composed constraint's message
(not all individual messages).

*What separates good from great:* "Constraint composition is how you build a domain vocabulary: @ValidEmail, @ValidPhoneNumber, @ValidPostalCode. Each wraps multiple primitive constraints. The domain model reads naturally and the validation rules are defined in one place."

---

**[MID] Q7 - How do you write a message interpolation
for custom constraint messages?**

*Why they ask:* Internationalization of validation.

Bean Validation supports message interpolation via:

1. Literal message in annotation:
   ```java
   @NotBlank(message = "Username is required")
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. Message bundle key:
   ```java
   @NotBlank(message = "{validation.username.required}")
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Define in `ValidationMessages.properties`:
   ```
   validation.username.required=Username is required
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Or locale-specific: `ValidationMessages_fr.properties`

3. EL expressions (Bean Validation 1.1+):
   ```java
   @Size(min=3, max=50,
         message = "Must be between {min} and {max} chars")
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   `{min}` and `{max}` are replaced with the annotation
   attribute values.

4. Custom interpolator for complex logic.

*What separates good from great:* "For internationalized applications, always use message bundle keys instead of literal strings. This allows translation without changing Java code. Place ValidationMessages.properties in src/main/resources and add locale-specific variants. The Hibernate Validator picks them up automatically."

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



