---
layout: default
title: "Micronaut - L2 Core"
parent: "Micronaut"
grand_parent: "SK Interview"
nav_order: 3
permalink: /micronaut/l2-core/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Compile-Time Dependency Injection](#compile-time-dependency-injection) | critical |
| 2 | [Micronaut AOP and Interceptors](#micronaut-aop-and-interceptors) | medium |
| 3 | [Micronaut Bean Scopes and Lifecycle](#micronaut-bean-scopes-and-lifecycle) | medium |
| 4 | [Micronaut Environment and Property Sources](#micronaut-environment-and-property-sources) | medium |
| 5 | [Micronaut Annotation Processing Pipeline](#micronaut-annotation-processing-pipeline) | medium |

---

# Compile-Time Dependency Injection

**Interview Weight:** critical - Compile-time DI is
Micronaut's defining characteristic. Every Micronaut
interview will probe this mechanism.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut uses Java annotation processing (APT) at
> compile time to generate BeanDefinition classes for
> every @Singleton, @Prototype, or scoped bean.
> These generated classes encode the dependency graph,
> constructor arguments, and lifecycle methods. At
> runtime, Micronaut loads these pre-built definitions
> instead of scanning classpath or using reflection.
> No classpath scanning. No reflection on the startup
> critical path.

**3 minutes (Senior):**

> Compile-time DI mechanics:
>
> Step 1: Annotation processing during javac/kotlinc
>   BeanDefinitionInjectProcessor runs for every class
>   annotated with @Singleton, @Bean, @Inject, etc.
>   Generates: OrderServiceBeanDefinition.java in
>   target/generated-sources/
>
> Step 2: Generated class structure
>   class OrderServiceBeanDefinition
>       extends AbstractBeanDefinition<OrderService> {
>     // Pre-computed metadata:
>     // - Constructor arguments (types, qualifiers)
>     // - Injection points (fields, methods)
>     // - Lifecycle methods (@PostConstruct)
>     // - Scope (Singleton, Prototype)
>     // - @Requires conditions
>   }
>
> Step 3: Runtime loading
>   ApplicationContext finds all BeanDefinition
>   classes on the classpath (normal class loading,
>   no scanning for annotations).
>   Creates the bean graph from the pre-built definitions.
>
> Result: startup O(n) where n = number of bean
>   definitions. No annotation analysis. No proxy
>   generation. Just definition loading.
>
> Native image advantage:
>   The generated code contains no reflection.
>   GraalVM native-image sees only normal Java classes.
>   No reflection configuration files needed for
>   core DI.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Micronaut's
compile-time dependency injection works mechanically."

**(2) First principles:** "DI requires two things:
knowing what beans exist and how to wire them. Spring
discovers this at runtime. Micronaut computes it at
compile time."

**(3) Bridge:** "Compile-time DI is like a shipping
warehouse that pre-assembles packages before orders
arrive. Spring assembles each package when the order
arrives (runtime). Micronaut assembles all packages
during the day (compile time) and ships instantly
when the order arrives."

---

### 💻 Code Example

```java
// Source code
@Singleton
public class OrderService {
    private final OrderRepository repository;
    private final NotificationService notif;

    public OrderService(
            OrderRepository repository,
            NotificationService notif) {
        this.repository = repository;
        this.notif = notif;
    }
}

// Generated at compile time by APT
// (in target/generated-sources/annotations)
// Simplified representation:
public class $OrderServiceDefinition
        extends AbstractBeanDefinition<OrderService> {

    // Generated constructor metadata
    private static final AbstractBeanDefinition
            .ConstructorInjectionPoint CONSTRUCTOR =
        new ConstructorInjectionPoint(
            OrderService.class,
            // Argument 1:
            DefaultArgument.of(
                OrderRepository.class, "repository"),
            // Argument 2:
            DefaultArgument.of(
                NotificationService.class, "notif")
        );

    @Override
    protected OrderService doBuild(
            BeanResolutionContext ctx,
            BeanContext context,
            BeanDefinition<OrderService> definition) {
        // Generated wiring - no reflection!
        return new OrderService(
            ctx.getBean(OrderRepository.class),
            ctx.getBean(NotificationService.class)
        );
    }
}
```

> **Code walkthrough:** The BeanDefinitionInjectProcessorice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> reads @Singleton on OrderService and generates the
> $OrderServiceDefinition class. This class contains
> pre-computed constructor argument types. The doBuild()
> method is generated Java code: new OrderService(...)
> with the resolved dependencies. No reflection in
> doBuild() - it's a direct Java constructor call.
> At runtime, the ApplicationContext calls doBuild()
> to create the bean. No classpath scanning needed.

---

### ⚖️ Comparison Table

| Aspect | Micronaut (AOT) | Spring (Runtime) |
|---|---|---|
| DI resolution timing | Compile time | Runtime |
| Classpath scanning | No | Yes |
| Proxy generation | No (for DI) | CGLIB/JDK proxy |
| Reflection in DI | No | Yes |
| Startup cost | O(n) definitions load | O(n*m) scan + proxy |
| Native image | No config needed | Spring AOT config needed |
| Dynamic beans | Limited | Full support |

---

### 📘 Concept Explanation

**What it is:**

Compile-Time Dependency Injection (CT-DI) is an architectural
pattern where the dependency injection wiring - which beans
exist, how they are constructed, and what they depend on - is
fully determined and code-generated during compilation, not
at application runtime.

**How it works:**

Java's Annotation Processing Tool (APT) runs during `javac`.
Micronaut's annotation processors (`io.micronaut:micronaut-inject-java`)
implement `javax.annotation.processing.Processor`. They read
all classes annotated with Micronaut annotations and generate
concrete `BeanDefinition` implementation files. These generated
files live in `build/classes` alongside regular compiled classes.

At runtime, `ApplicationContext.run()` finds all
`BeanDefinitionReference` instances via Java ServiceLoader.
These references point to the generated `BeanDefinition` classes.
The context builds a dependency graph from the definitions and
creates bean instances using generated `BeanFactory` code -
no reflection involved.

**Generated code example (conceptual):**

For `@Singleton class MyService(@Inject val repo: Repo)`,
Micronaut generates a class that implements
`BeanDefinition<MyService>` and contains:
- `build(ctx, registry)` method that calls `new MyService(ctx.getBean(Repo.class))`
- scope metadata (singleton)
- qualifier metadata

**Why it matters:**

Compile-time validation (missing beans detected at build time),
no runtime classpath scanning overhead, GraalVM native image
compatibility (no reflection), and fast startup (bean factory
code is pre-compiled, not interpreted at runtime).

---

### 🎓 Answers by Seniority

**Junior:** "Micronaut generates BeanDefinition classes
during compilation. These are loaded at startup instead
of scanning for annotations at runtime."

**Senior:** "The generated BeanDefinition contains
no reflection - it's compiled Java code calling the
constructor directly. This is why GraalVM native-image
works without reflection configuration for Micronaut
beans. The trade-off: you can't register beans
dynamically at runtime."

**Staff:** "Compile-time DI has an architectural
consequence: your application's bean graph is fixed
at compile time. This is a constraint for plugin
architectures but a safety net for most applications.
Unexpected bean wiring errors surface at compile time
or startup, not in production."

---

### ⚠️ Common Misconceptions

**Misconception 1: Compile-time DI cannot support
conditional beans that depend on runtime configuration.**

Micronaut's `@Requires` allows conditions that are evaluated
at startup against the RUNTIME environment, but the bean
DEFINITION exists statically in the compiled output. This
is the critical distinction: the bean definition (structure)
is compile-time; the bean ACTIVATION (whether the instance
is created) is runtime. `@Requires(property="feature.x",
value="true")` compiles the bean definition but only creates
the bean instance if the property is "true" at startup.

**Misconception 2: All injection must be via constructor;
field injection does not work in compile-time DI.**

Micronaut supports constructor injection (recommended), field
injection (`@Inject` on fields), method injection (`@Inject`
on setter methods), and even `@Inject` on arbitrary methods.
All three are processed at compile time and generate
corresponding factory code. Constructor injection is preferred
for testability (can create the bean without a container),
but field injection works correctly with Micronaut.

**Misconception 3: Compile-time DI means you cannot add
beans to the context after application startup.**

Micronaut supports `BeanDefinitionRegistry.registerSingleton()`
for programmatic bean registration at startup time (before
the context is fully initialized). However, registering beans
AFTER startup (like Spring's `ctx.getBeanFactory().registerSingleton()`)
is more limited in Micronaut. Most dynamic registration
scenarios can be handled by `@Factory` methods with `@Requires`
conditions or by using `@Replaces` for bean substitution.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: APT not running because annotation
processor not on annotation processor classpath.**

Symptom: no `$MyBean$Definition.class` files generated;
`No bean of type [X]` at runtime for annotated classes.
Root cause: `micronaut-inject-java` is on the compile classpath
but not the ANNOTATION PROCESSOR classpath. In Gradle:
`implementation` vs `annotationProcessor` configuration.
Diagnosis: check `build.gradle` for `annotationProcessor
"io.micronaut:micronaut-inject-java"`. Fix: move to
`annotationProcessor` configuration; in Kotlin projects use
`kapt` configuration.

**Failure Mode 2: Generated bean definitions become stale
after refactoring, causing runtime type mismatches.**

Symptom: after renaming a class or moving a package, beans
that reference the old class name fail at startup even though
the source code looks correct. Root cause: incremental
compilation left stale generated `$OldClass$Definition.class`
files in the build directory. Diagnosis: check `build/classes`
for old class names. Fix: run `./gradlew clean build` to
regenerate all annotation processor output; this is a known
issue with incremental APT in some build tool versions.

**Failure Mode 3: Generic type injection fails because
type parameters are erased at compile time.**

Symptom: `@Inject List<MyService>` does not inject all
registered beans of type `MyService`. Root cause: Java type
erasure means the JVM sees `List` not `List<MyService>`;
Micronaut's APT works with erased types and may not resolve
the generic type correctly in all cases. Diagnosis: use
`BeanContext.getBeansOfType(MyService.class)` instead.
Fix: prefer `Collection<MyService>` injection over `List<T>`;
or inject `ApplicationContext` and use `getBeansOfType()`;
check Micronaut documentation for supported generic injection
patterns.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Generated classes, BeanDefinition structure, native image |
| Staff | 10 min | Trade-offs, dynamic bean limits, architectural consequences |

---

**[SENIOR] Q1 - How can you inspect the compile-time
generated BeanDefinition classes?**

*Why they ask:* Debugging and deep understanding.

Generated classes are in:
```plaintext
target/generated-sources/annotations/
  (Maven, Java source generation)

build/generated/sources/annotationProcessor/
  (Gradle)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

They have the format: `$TypeName$DefinitionClass.java`
or compiled as `$TypeName$Definition.class`.

To inspect:
```bash
# Find generated definition files:
find target -name "*Definition*.class" | head -20

# Decompile with javap:
javap -p -c \
  target/classes/\
  io/example/$OrderService$Definition.class
```

> **Code walkthrough:** This Decompile with javap: example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

The decompiled output shows:
- Which constructor is used
- Argument types and qualifiers
- @Requires conditions as if/else in the code
- @PostConstruct method reference

Useful when debugging: "Why is the wrong implementation
injected?" - check the generated definition class.

*What separates good from great:* Knowing WHERE to
look when DI doesn't behave as expected.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | APT generation, BeanDefinition structure. |
| Hiring Manager | Compile-time DI = fewer runtime surprises. |
| Bar Raiser | Generated class structure, native image implication, dynamic bean trade-off. |
| Peer Engineer | "I look at the generated $Definition class when Micronaut injects the wrong bean. Usually a missing @Qualifier." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut AOP and Interceptors

**Interview Weight:** medium - AOP in Micronaut is
compile-time, making it more predictable but less
dynamic than Spring AOP.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut AOP uses compile-time interceptors, not
> runtime CGLIB proxies. Create a custom annotation
> and annotate an interceptor class with @Around or
> @InterceptorBean. At compile time, Micronaut wraps
> the annotated methods with the interceptor code.
> Standard use cases: @Transactional (built-in),
> @Cacheable (built-in), custom audit logging,
> circuit breaker. No proxy class at runtime - the
> wrappers are generated source code.

**3 minutes (Senior):**

> AOP without proxies:
>
> Spring AOP: creates CGLIB subclass at runtime.
>   Target method is overridden; interceptors run.
>   Cannot intercept private or final methods.
>   Creates a new proxy class per intercepted bean.
>
> Micronaut AOP: uses introduction advice.
>   At compile time: generates wrapper code around
>   the target method.
>   The interceptor runs in the generated wrapper.
>   No new proxy class (the original class is unchanged).
>   Can intercept any method visible to the annotation.
>
> Custom interceptor pattern:
>   1. Create annotation: @AuditLog
>   2. Create interceptor:
>      @Singleton @InterceptorBean(AuditLog.class)
>      class AuditLogInterceptor
>          implements MethodInterceptor<Object,Object> {
>        @Override
>        public Object intercept(MethodInvocationContext) {
>          // pre-execution
>          Object result = ctx.proceed();
>          // post-execution
>          return result;
>        }
>      }
>   3. Apply: @AuditLog on method or class
>
> Built-in interceptors:
>   @Transactional: transaction management
>   @Cacheable/@CachePut/@CacheInvalidate: caching
>   @Retryable: retry with backoff
>   @CircuitBreaker: circuit breaker

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about aspect-oriented
programming in Micronaut - how to add cross-cutting
concerns without modifying business logic."

**(2) First principles:** "AOP = inject code before/after
methods. Spring does this with runtime proxies. Micronaut
does this with compile-time code generation."

**(3) Bridge:** "Micronaut AOP is generated code, not
runtime magic. The result is the same: @Transactional
wraps your method in a transaction. The mechanism is
compile-time code, not a runtime CGLIB class."

---

### 💻 Code Example

```java
// Custom AOP annotation
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
@Around   // Tells Micronaut this is an AOP annotation
public @interface AuditLog {
    String action() default "";
}

// Interceptor
@Singleton
@InterceptorBean(AuditLog.class)
public class AuditLogInterceptor
        implements MethodInterceptor<Object, Object> {

    private final AuditRepository auditRepo;

    AuditLogInterceptor(AuditRepository auditRepo) {
        this.auditRepo = auditRepo;
    }

    @Override
    public Object intercept(
            MethodInvocationContext<Object, Object> ctx) {

        String methodName = ctx.getMethodName();
        String action = ctx.getAnnotationMetadata()
            .stringValue(AuditLog.class, "action")
            .orElse(methodName);

        try {
            Object result = ctx.proceed();
            auditRepo.logSuccess(action,
                ctx.getParameterValues());
            return result;
        } catch (Exception e) {
            auditRepo.logFailure(action, e);
            throw e;
        }
    }
}

// Usage
@Singleton
public class OrderService {

    @AuditLog(action = "CREATE_ORDER")
    public Order createOrder(CreateOrderRequest req) {
        // Compile time: wrapped with AuditLogInterceptor
        // AuditLog fires before and after this method
        return orderRepository.save(
            Order.from(req));
    }
}
```

> **Code walkthrough:** @Around marks the customice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> annotation as an AOP trigger. @InterceptorBean links
> the interceptor to the annotation. At compile time,
> Micronaut sees @AuditLog on createOrder() and generates
> code that calls AuditLogInterceptor.intercept() around
> the method body. ctx.proceed() calls the original
> method. Unlike Spring AOP, no CGLIB proxy class is
> created at runtime.

---

### 📘 Concept Explanation

**What it is:**

Micronaut AOP (Aspect-Oriented Programming) allows adding
cross-cutting behavior (logging, caching, transactions,
validation, retry) to bean methods without modifying the
methods themselves. Unlike Spring AOP (which uses CGLIB
runtime proxies), Micronaut AOP is compile-time: interceptors
are woven into generated subclasses during compilation.

**How it works:**

Creating a Micronaut interceptor:
1. Define a `@Around` meta-annotation (the AOP annotation
   users will apply to methods)
2. Create an `MethodInterceptor<T, R>` implementation
3. The APT generates a subclass of the target bean that
   overrides all intercepted methods to call the interceptor
   chain before/after the original method

The generated subclass is what gets injected as the bean
(transparent to the caller). The interceptor chain is
resolved once at startup, not on each method call.

Built-in Micronaut AOP annotations:
- `@Retryable` - automatic retry with backoff
- `@Cacheable` / `@CachePut` / `@CacheInvalidate` - caching
- `@Transactional` - database transaction demarcation
- `@Validated` - JSR-380 bean validation on method parameters
- `@ExecuteOn` - execute on a specific thread executor

**Why it matters:**

AOP with compile-time weaving means: no runtime proxy creation
cost, no Spring-specific CGLIB or JDK proxy behaviors (AOP
always works, not just for interface-based proxies), and full
GraalVM native image compatibility.

---

### 🎓 Answers by Seniority

**Junior:** "Micronaut AOP uses annotations on methods
and interceptor classes. @Transactional and @Cacheable
are built-in interceptors. Custom interceptors implement
MethodInterceptor."

**Senior:** "Micronaut AOP generates the interceptor
wrapper at compile time - no runtime proxy. This means
AOP works on any method (not just public, not limited
to Spring proxy rules). The trade-off: you can't add
AOP to a class at runtime."

---

### ⚠️ Common Misconceptions

**Misconception 1: AOP annotations like @Transactional
work when called from within the same class.**

This is a classic AOP limitation: method calls between methods
in the SAME bean instance bypass the AOP proxy. If
`methodA()` calls `this.methodB()`, and `methodB()` has
`@Transactional`, the transaction annotation is NOT applied
because `this.methodB()` bypasses the generated subclass.
This is the same limitation as Spring AOP. Fix: inject the
bean into itself via `@Inject MyBean self` and call
`self.methodB()`, which routes through the AOP proxy.

**Misconception 2: Multiple AOP annotations on the same
method always execute in a consistent order.**

When multiple interceptors apply to the same method, their
execution order is determined by their `@InterceptorBinding`
order or `@Priority` annotation. Without explicit ordering,
the execution order is determined by annotation processing
order, which may vary. In Micronaut, interceptors are
ordered by `getOrder()` method (lower number = higher priority).
Define explicit priorities for interceptors whose relative
order matters (e.g., security check before audit logging).

**Misconception 3: @Cacheable caches the return value
regardless of whether the method throws an exception.**

Micronaut's `@Cacheable` only caches SUCCESSFUL returns
(no exception thrown). If the method throws an exception,
nothing is cached. This is the correct behavior (you don't
want to cache error states). However, `@Cacheable` also does
NOT cache `null` returns by default - if the method returns
null, the next invocation re-executes the method. Configure
`cacheNull = true` if null is a valid cacheable result.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: @Retryable retries on all exceptions
including non-transient errors.**

Symptom: a validation exception (400 Bad Request equivalent)
or an authorization exception is retried 3 times before
ultimately failing - adding unnecessary latency and log noise.
Root cause: `@Retryable` without `includes`/`excludes`
parameters retries on any exception. Fix: specify which
exceptions should trigger retry: `@Retryable(includes =
[ConnectException.class, SocketTimeoutException.class])`;
exclude business exceptions that indicate permanent failures.

**Failure Mode 2: @Cacheable on a reactive method (returning
Mono/Flux) does not cache because the cache integration
does not support reactive types by default.**

Symptom: `@Cacheable` on a method returning `Mono<T>`
creates a new Mono on every call - no caching occurs.
Root cause: the default Micronaut cache implementation
(Caffeine, Redis) expects synchronous return values and does
not subscribe to reactive publishers automatically. Fix:
use Micronaut's reactive cache annotations with reactor
integration; or collect the result to a blocking call before
caching (only appropriate when the reactive overhead is
not significant); or use explicit manual caching in the
reactive pipeline.

**Failure Mode 3: AOP interceptors cause StackOverflowError
due to recursive interception.**

Symptom: `StackOverflowError` in production after deploying
new interceptor code. Root cause: an interceptor calls a
method on a bean that triggers the SAME interceptor again
in a recursive loop. Common scenario: a logging interceptor
logs by calling a bean method that is also intercepted by
the same logging interceptor. Diagnosis: analyze the stack
trace - repeated frames show the recursive pattern. Fix:
add a guard to prevent re-entrant interception; use
`@NonBlocking` or `@InterceptorBinding` with specific
method patterns to limit which methods are intercepted.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Compile-time interceptors vs Spring CGLIB, custom interceptors |
| Staff | 8 min | AOP limitations, Introduction advice, comparison |

---

**[SENIOR] Q1 - Can Micronaut AOP intercept calls
within the same class (self-invocation)?**

*Why they ask:* The Spring AOP self-invocation gotcha
is famous. Does Micronaut have the same problem?

Spring AOP problem: method A calls method B in the same
class. If B has @Transactional, the call goes directly
(not through the proxy). No transaction.

Micronaut AOP: compile-time interceptors are woven
into the class itself (introduction advice), not an
external proxy class. Therefore: self-invocation DOES
go through the interceptor.

Example:
```java
@Singleton
public class OrderService {
    public void processAndShip(Long id) {
        this.createShipment(id); // self-call
    }

    @AuditLog(action = "SHIP")
    public void createShipment(Long id) {
        // In Micronaut: AuditLogInterceptor fires
        // even on self-invocation
        // In Spring: @AuditLog would NOT fire
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

This is a significant advantage over Spring's proxy-based
model. No need for self-injection (injecting yourself
as a Spring bean to get proxy behavior).

*What separates good from great:* Self-invocation works
in Micronaut because of compile-time (not proxy-based)
AOP.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Around, MethodInterceptor, compile-time weaving. |
| Hiring Manager | AOP for cross-cutting concerns without boilerplate. |
| Bar Raiser | Self-invocation works in Micronaut, comparison to Spring proxy limitation. |
| Peer Engineer | "Migrated from Spring to Micronaut. Fixed a silent @Transactional self-invocation bug we'd had for years." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Bean Scopes and Lifecycle

**Interview Weight:** medium - Bean scopes control
instance creation and lifecycle. Tested to verify
understanding of scope choices and lifecycle hooks.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut bean scopes: @Singleton (one instance per
> ApplicationContext), @Prototype (new instance per
> injection point), @RequestScope (one per HTTP request).
> Lifecycle: @PostConstruct method runs after all
> dependencies injected; @PreDestroy runs on context
> shutdown. @Singleton beans are created eagerly by
> default unless marked @Lazy.

**3 minutes (Senior):**

> Scopes:
>
> @Singleton:
>   One instance per ApplicationContext.
>   Thread-safe access required if mutable state.
>   Created at startup (eager by default).
>
> @Prototype:
>   New instance per injection point.
>   Not cached; each injection creates a new bean.
>   Use for stateful, non-thread-safe objects.
>
> @RequestScope:
>   One instance per HTTP request.
>   Bound to the request context.
>   Cleaned up after response sent.
>   Use for: request-scoped security context,
>     per-request caching.
>
> @Refreshable:
>   Singleton that can be refreshed via
>   RefreshEvent. Config changes trigger refresh.
>
> @Context:
>   Same as @Singleton but initialized very early
>   in the ApplicationContext lifecycle.
>   Use for infrastructure beans.
>
> @Infrastructure:
>   Internal Micronaut beans. Not used in application.
>
> Lifecycle hooks:
>   @PostConstruct: initialization after injection.
>   @PreDestroy: cleanup before context shutdown.
>   ApplicationEventListener<StartupEvent>: alternative
>   to @PostConstruct for startup tasks.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Micronaut's
bean scopes - how many instances are created and
when they are created and destroyed."

**(2) First principles:** "Scope = the lifetime of
a bean instance. Singleton = shared. Prototype = each
gets its own. Request = scoped to one request."

**(3) Bridge:** "Bean scopes are like hotel room policies:
Singleton = the mayor always uses room 1. Prototype =
new room for every guest. RequestScope = room assigned
for your stay, released on checkout."

---

### 💻 Code Example

```java
// @Singleton: shared across the app
@Singleton
public class OrderService {
    // One instance, thread-safe required for state
    private final OrderRepository repository;
    OrderService(OrderRepository repository) {
        this.repository = repository;
    }
}

// @Prototype: new instance per injection
@Prototype
public class RequestContextBuilder {
    private final List<String> trace =
        new ArrayList<>();  // Safe: new instance each time

    public RequestContextBuilder add(String step) {
        trace.add(step);
        return this;
    }
}

// @RequestScope: per HTTP request
@RequestScope
public class AuditContext {
    private String requestId;
    private String userId;
    // Holds per-request audit state
    // Cleaned up automatically after response
}

// Lifecycle hooks
@Singleton
public class ConnectionPool {
    @Inject
    DataSourceConfig config;

    @PostConstruct
    public void initialize() {
        // Called after all dependencies injected
        // Safe to use config here
        pool = createPool(config.getUrl());
    }

    @PreDestroy
    public void shutdown() {
        // Called on ApplicationContext.close()
        pool.close();
        log.info("Connection pool closed");
    }
}

// @Lazy: defers creation until first use
@Singleton
@Lazy
public class ExpensiveAnalyticsEngine {
    // Not created at startup
    // Created on first injection
}
```

> **Code walkthrough:** @Prototype on RequestContextBuilderice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> means each injection point creates a new instance
> with a fresh trace list - safe for per-request accumulation.
> @RequestScope on AuditContext binds the instance
> to the HTTP request lifecycle. @PostConstruct fires
> after @Inject resolves all dependencies - safe to
> use injected config. @Lazy defers expensive initialization
> to first use, keeping startup faster.

---

### 📘 Concept Explanation

**What it is:**

Micronaut bean scopes determine the lifecycle of bean
instances: how many instances are created, when they are
created, and when they are destroyed. Micronaut supports
standard JSR-330 scopes plus several Micronaut-specific ones.

**How it works:**

Core scopes:
- `@Singleton`: one instance per ApplicationContext (entire
  application lifetime). Created at context startup if eager.
- `@Prototype`: new instance for each injection point. Created
  on each `getBean()` call or injection.
- `@RequestScope`: one instance per HTTP request. Created when
  the request starts, destroyed when the request ends.
  Requires the `micronaut-http` module.
- `@Context`: always eagerly initialized at startup. Use for
  beans that must start immediately (server init, event
  subscription).

Lifecycle hooks:
- `@PostConstruct`: method runs after bean is fully initialized
  (all injections completed)
- `@PreDestroy`: method runs before bean is destroyed (context
  shutdown or scope end)

These are JSR-250 annotations (`jakarta.annotation.*`).

**Why it matters:**

Wrong scope causes bugs: `@Singleton` with mutable state
shared across requests is a data race; `@Prototype` when
you want shared state creates unexpected duplication.

---

### 🎓 Answers by Seniority

**Junior:** "@Singleton shares one instance. @Prototype
creates a new instance per injection. @RequestScope
creates one per HTTP request. @PostConstruct runs
after injection."

**Senior:** "@Prototype is underused. Use it when a
bean needs fresh mutable state per caller. @RequestScope
is ideal for per-request security or tracing context.
@Lazy for expensive beans not needed at startup."

---

### ⚠️ Common Misconceptions

**Misconception 1: @RequestScope works the same way
in Micronaut as in Spring (request-scoped beans
automatically tied to the current HTTP request).**

Both frameworks support request-scoped beans but the
mechanism differs. In Micronaut, `@RequestScope` uses
Micronaut's `ServerRequestContext` to associate the bean
with the current HTTP request. In async/reactive code,
the request context may not propagate automatically across
thread boundaries. Spring's `@RequestScope` has the same
limitation. Fix: use `ServerRequestContext.currentRequest()`
explicitly in async operations; or pass request-specific
data as parameters rather than using scoped beans in
reactive chains.

**Misconception 2: @PreDestroy is called when a @Prototype
bean goes out of scope or is garbage collected.**

`@PreDestroy` on a `@Prototype` bean is NOT called
automatically when the bean becomes unreachable. Unlike
`@Singleton` (destroyed on context shutdown) and
`@RequestScope` (destroyed on request end), `@Prototype`
beans are not tracked for destruction by default. To get
destruction callbacks for `@Prototype` beans, you must
register the bean as `Closeable` or explicitly call
`context.destroyBean(bean)`. This is a common surprise
for developers expecting Spring-like behavior.

**Misconception 3: @Context scope is equivalent to
Spring's singleton scope with @Lazy(false).**

`@Context` scope IS eagerly initialized like a non-lazy
Spring singleton. But `@Context` beans are initialized
VERY early in the context startup - before most other
beans. This makes them appropriate for infrastructure
initialization but requires that `@Context` beans do not
depend on application beans (which may not be initialized
yet). Use `@Context` for: server configuration, JVM-level
setup, and infrastructure initialization. Use `@Singleton`
(eager by default when depended upon) for application beans.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Memory leak from @Prototype beans
injected into @Singleton beans held for application lifetime.**

Symptom: heap usage grows over time; heap dump shows many
instances of a `@Prototype` bean accumulating. Root cause:
a `@Prototype` bean is injected into a `@Singleton`. The
singleton keeps a reference to the single prototype instance
created at injection time, preventing garbage collection.
New prototypes needed later are not requested. Diagnosis:
heap dump analysis (Eclipse Memory Analyzer) shows many
retained instances. Fix: inject `ApplicationContext` or
`Provider<PrototypeBean>` and call `getBean()` / `get()`
when a fresh instance is needed.

**Failure Mode 2: @PostConstruct method executes before
all injected dependencies are fully initialized.**

Symptom: `@PostConstruct` method calls a method on an
injected dependency, but the dependency's own `@PostConstruct`
has not run yet, causing NPE or unexpected behavior.
Root cause: `@PostConstruct` execution order follows bean
initialization order in the dependency graph, but complex
multi-level graphs may execute in unexpected order. Diagnosis:
add logging to `@PostConstruct` methods to trace execution
order. Fix: use `@EventListener(ApplicationStartedEvent.class)`
instead of `@PostConstruct` for initialization that must run
after ALL beans are fully initialized.

**Failure Mode 3: @RequestScope bean not injected in
background threads (scheduled jobs, async tasks).**

Symptom: `@RequestScope` bean injection in a scheduled
task or `@Async` method fails with "No request bound to
the current thread." Root cause: `@RequestScope` requires
an active HTTP request context; scheduled tasks and async
executors do not have one. Diagnosis: check thread name in
the error - if it is a scheduler thread (not a Netty I/O
thread), no request context exists. Fix: use `@Singleton`
for data needed in scheduled tasks; or explicitly create a
request scope context using `ServerRequestContext`.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Singleton, Prototype, PostConstruct |
| Senior | 6 min | RequestScope, Lazy, Refreshable |

---

**[SENIOR] Q1 - What happens if a @Singleton bean
injects a @Prototype bean?**

*Why they ask:* Scope mismatch is a common bug.

If a @Singleton injects a @Prototype via constructor
injection: the @Prototype is resolved once at
construction time. The same instance is used forever.
The @Prototype is effectively a Singleton in this context.

The @Prototype is NOT re-created per use of the Singleton.

Fix options:
1. Inject Provider<PrototypeBean>: calling provider.get()
   creates a new instance each time.
2. Inject ApplicationContext and look up the bean each time.
3. Reconsider if @Prototype is really needed for this dependency.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
@Singleton
public class OrderProcessor {
    // BAD: shared instance despite @Prototype
    private final RequestContextBuilder builder;
    OrderProcessor(
            RequestContextBuilder builder) {
        this.builder = builder;
        // builder created once at startup
    }

    // GOOD: Provider re-creates per call
    private final Provider<RequestContextBuilder>
        builderProvider;
    OrderProcessor(
            Provider<RequestContextBuilder> p) {
        this.builderProvider = p;
    }
    public void process() {
        RequestContextBuilder ctx =
            builderProvider.get(); // new instance
    }
}
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Java API ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Provider<T> as the
idiomatic fix for scope mismatch.

| Interviewer Type| Emphasis|
|---|--------------------------------------------------------------------------|
| Technical Panel| Scope definitions, lifecycle hooks.|
| Hiring Manager| Bean lifecycle determines how your services behave.|
| Bar Raiser| Scope mismatch bug, Provider<T> fix, @RequestScope lifecycle.|
| Peer Engineer| "Singleton injecting Prototype is a silent bug. Added @Prototyp

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanation


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compar


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Environment and Property Sources

**Interview Weight:** medium - Environment-driven
configuration is essential for production deployments.
Tested for environment activation and property source
hierarchy.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut environments are activated via
> -Dmicronaut.environments=production or the
> MICRONAUT_ENVIRONMENTS environment variable. Active
> environments cause environment-specific config files
> to be loaded: application-production.yml overrides
> application.yml. Multiple environments can be active
> simultaneously. @Requires(env = "production") enables
> beans only in specific environments. Property sources
> can be extended (Consul, AWS Secrets Manager) via
> plugins.

**3 minutes (Senior):**

> Environment system:
>
> Built-in environments (auto-detected):
> - "cloud": detected on cloud providers
>   (ECS, GCE, Kubernetes - reads metadata endpoints)
> - "ec2": Amazon EC2
> - "gcp": Google Cloud
> - "k8s": Kubernetes (pod metadata available)
> - "test": Micronaut test (set by @MicronautTest)
>
> Custom environments:
> - -Dmicronaut.environments=production,feature-x
> - or: MICRONAUT_ENVIRONMENTS=production,feature-x
>
> Property source priority (highest first):
> 1. System properties
> 2. Environment variables
> 3. application-{env}.yml (per active environment)
> 4. application.yml
> 5. application.properties (fallback)
>
> Distributed configuration:
> - micronaut-consul: loads config from Consul KV store
> - micronaut-aws-secrets-manager: AWS Secrets Manager
> - micronaut-kubernetes: Kubernetes ConfigMaps/Secrets
> - All distributed sources override local files
>
> @Requires(env = ...):
> @Requires(env = {"cloud", "k8s"}): active on cloud/k8s
> @Requires(notEnv = "test"): excludes from test

**Blank Mind Recovery:**

environment system - how environment-specific configuration
works."

**(2) First principles:** "Applications run in multiple
environments (dev, staging, prod). Config must differ.
Environments provide the override mechanism."

**(3) Bridge:** "Micronaut environments are like project
profiles: a base config (application.yml) and
environment-specific overlays (application-production.yml).
Micronaut also auto-detects cloud environments."

---

### 📘 Concept Explanation

**What it is:**

Micronaut's Environment system is the mechanism for managing
multi-environment configuration. It combines: active environment
names (dev, test, production, cloud), multiple property sources
(YAML, properties, environment variables), and conditional bean
activation (`@Requires(env=...)`).

**How it works:**

Active environments are detected from:
1. `MICRONAUT_ENVIRONMENTS` environment variable
2. `micronaut.environments` system property
3. Auto-detection: cloud environments (EC2, GCP, Azure,
   K8s, Cloud Foundry) are detected from metadata endpoints
   and filesystem markers at startup

Property source loading order (highest priority first):
1. `application-{env}.yml` for each active environment
2. `application.yml` (base config)
3. System properties
4. Environment variables (uppercase, dots→underscores)

`@Requires(env = "cloud")` means the bean is only created
when "cloud" is an active environment. Multiple environments
can be active simultaneously.

**Why it matters:**

Environment-based configuration allows different database
connections, service endpoints, and feature flags per
deployment without code changes. Auto-detected cloud
environments enable cloud-specific beans (KV store, secret
providers) to activate automatically.

---

### 🎓 Answers by Seniority

**Junior:** "Set -Dmicronaut.environments=production
and Micronaut loads application-production.yml on
top of application.yml. Use @Requires(env=...) to
activate beans only in certain environments."

**Senior:** "Micronaut auto-detects cloud environments
(Kubernetes, EC2, GCP) by querying metadata endpoints.
This is useful for @Requires(env='k8s'): activate
Kubernetes-specific service discovery only in k8s.
Distributed config (Consul, AWS Secrets Manager)
integrates as a property source that overrides local
YAML."

---

### ⚠️ Common Misconceptions

**Misconception 1: Micronaut's environment system is
the same as Spring Boot's profiles.**

Spring Profiles and Micronaut Environments are conceptually
similar but differ in activation and detection. Spring profiles
are manually activated via `spring.profiles.active`. Micronaut
environments are: manually activated (same pattern) AND
automatically detected (cloud environment detection). Multiple
Micronaut environments can be active simultaneously (e.g., both
"production" and "cloud" active together), while Spring allows
multiple profiles but they are all manual. Micronaut's auto-
detection is unique - it checks AWS metadata, GCP metadata,
Kubernetes service account presence, etc.

**Misconception 2: Setting MICRONAUT_ENVIRONMENTS=production
is equivalent to activating the 'production' Spring profile.**

While functionally similar, the key difference is that Micronaut
environments STACK with auto-detected environments. If your pod
runs on Kubernetes, Micronaut auto-detects the "k8s" environment
regardless of `MICRONAUT_ENVIRONMENTS`. This means beans with
`@Requires(env="k8s")` are activated without explicit
configuration - which is the desired behavior for cloud-native
apps, but can surprise developers unfamiliar with auto-detection.

**Misconception 3: All property source types have equal
refresh/reload capability.**

Different property sources have different mutability profiles.
YAML files are loaded at startup and do not refresh unless you
use Micronaut's `RefreshableScope` and trigger a
`/refresh` endpoint. Environment variables are resolved at
startup and do not change in a running JVM. Micronaut's
distributed configuration (Consul, AWS Parameter Store) CAN
reload if you enable the refresh feature. Without explicit
refresh configuration, assume all configuration is static after
startup.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Wrong environment activated in production
because MICRONAUT_ENVIRONMENTS not set.**

Symptom: production application uses development defaults
(H2 in-memory DB, debug logging, mock external services).
Root cause: `MICRONAUT_ENVIRONMENTS=production` not set in
the production deployment configuration; Micronaut uses only
auto-detected environments (may detect "cloud" from metadata
but not "production"). Diagnosis: log `Environment.getActiveNames()`
at startup. Fix: always explicitly set `MICRONAUT_ENVIRONMENTS`
in production deployments; do not rely solely on auto-detection
for business-logic-affecting environments.

**Failure Mode 2: Property value resolution differs between
local and CI because of environment variable naming conflicts.**

Symptom: application works locally but CI environment loads
wrong configuration values. Root cause: CI platform sets
environment variables with the same name as Micronaut's
expected property translations. For example, CI sets
`DATABASE_URL` which translates to `database.url`, but
`APPLICATION_DATABASE_URL` translates to
`application.database.url` - different keys. Diagnosis:
log all active property sources with their values at startup
level. Fix: prefix all application-specific environment
variables consistently; document the translation rules.

**Failure Mode 3: @Requires(env="test") beans persist
in staging environment because 'test' environment is
accidentally activated.**

Symptom: staging environment uses mock services because
`@Requires(env="test")` beans are active. Root cause:
`MICRONAUT_ENVIRONMENTS=test,staging` was set in staging
deployment (both "test" and "staging" active). Fix: review
all `@Requires(env=...)` annotations to ensure the environment
names are specific; use `@Requires(notEnv="production")` for
beans that should be absent in production; enforce environment
variable values via infrastructure-as-code (Terraform,
Helm values).

---

### 🎯 Interview Deep-Dive

| Experience| Time| Depth|
|---|-----------|--------------------------------------------------------------|
| Junior| 3 min| Environment activation, config overlay|
| Senior| 6 min| Auto-detected environments, distributed config, @Requires(env)|

---

**[SENIOR] Q1 - How does Micronaut load Kubernetes
secrets safely?**

*Why they ask:* Production Kubernetes deployment concern.

Micronaut Kubernetes integration:
```yaml
# pom.xml / build.gradle
# micronaut-kubernetes dependency
```

```yaml
# application.yml
micronaut:
  config-client:
    enabled: true

kubernetes:
  client:
    namespace: production
    config-maps:
      enabled: true
      paths:
        - /config/app-config
    secrets:
      enabled: true
      paths:
        - /secrets/db-password
```

> **Code walkthrough:** This application.yml example demonstrates YAML configuraice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Kubernetes mounts secrets as files or env vars.
Micronaut reads them as property sources.

For secrets:
1. Mount secret as an environment variable
   (Kubernetes Secret → env var).
2. Micronaut reads the env var as a normal property.
3. Never log property values that may be secrets.

@Requires(env = "k8s") ensures Kubernetes-specific
config (service discovery via DNS) only activates
in the Kubernetes environment.

*What separates good from great:* Env var mounting
over file mounting (env vars are ephemeral and not
stored on disk in the container).

| Interviewer Type| Emphasis|
| Technical Panel| Environment activation, property source hierarchy.|
| Hiring Manager| Environment-specific config = clean deployment.|
| Bar Raiser| Auto-detected environments, distributed config, Kubernetes secrets
| Peer Engineer| "We use @Requires(env='k8s') for all Kubernetes-specific beans.

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanation


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compar


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Annotation Processing Pipeline

**Interview Weight:** medium - Understanding the
annotation processing pipeline is essential for
advanced Micronaut development and debugging.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut uses Java Annotation Processing (JSR 269)
> to generate code at compile time. When javac/kotlinc
> processes source files, Micronaut's annotation
> processors (BeanDefinitionInjectProcessor, etc.) scan
> for Micronaut annotations and generate BeanDefinition,
> interceptor wrapper, HTTP route binding, and
> configuration binding classes. These generated classes
> are compiled and included in the JAR. At runtime,
> no annotation processing occurs.

**3 minutes (Senior):**

> Key annotation processors:
>
> BeanDefinitionInjectProcessor:
>   @Singleton, @Prototype, @Bean →
>   Generates BeanDefinition classes.
>
> AopProxyWriter:
>   @Around, @Transactional, @Cacheable →
>   Generates AOP wrapper code.
>   (No CGLIB; generates source code instead)
>
> HttpServerRouteGenerator:
>   @Controller, @Get, @Post →
>   Generates route binding code.
>   Route matching is compiled code (faster).
>
> ConfigurationPropertiesProcessor:
>   @ConfigurationProperties →
>   Generates property binding code.
>   No reflection for config binding.
>
> TypeElementVisitor:
>   Extension point: implement custom annotation
>   processors that integrate with Micronaut's APT.
>
> Build tool integration:
>   Maven: micronaut-inject-java in annotationProcessorPaths
>   Gradle: annotationProcessor("io.micronaut:micronaut-inject-java")
>
> Incremental annotation processing:
>   Micronaut 3+ supports incremental APT.
>   Only reprocesses changed classes.
>   Reduces compile time for large projects.

**Blank Mind Recovery:**

compile-time code generation works under the hood."

**(2) First principles:** "Annotation processing is
a Java compiler plugin that reads source code and
generates additional source files before compilation
completes."

**(3) Bridge:** "Micronaut's annotation processing
is like a code generator that reads your annotations
and writes the plumbing code you'd otherwise have to
write manually - DI wiring, AOP wrappers, HTTP routes."

---

### 💻 Code Example

```java
// Source: your code
@Singleton
public class OrderService {
    private final OrderRepository repo;
    OrderService(OrderRepository repo) {
        this.repo = repo;
    }
}

// Generated (simplified): target/generated-sources/
// File: $OrderService$Definition.java

@Generated("io.micronaut.annotation.processing..."
           + ".BeanDefinitionInjectProcessor")
public class $OrderService$Definition
    extends AbstractInitializableBeanDefinition<
        OrderService>
    implements BeanFactory<OrderService> {

    // Pre-computed constructor argument metadata
    private static final AbstractInitializableBeanDefinition
        .MethodOrFieldReference CONSTRUCTOR =
        new AbstractInitializableBeanDefinition
            .MethodReference(
                OrderService.class,
                "<init>",
                new Argument[] {
                    Argument.of(
                        OrderRepository.class,
                        "repo")
                }
            );

    @Override
    public OrderService build(
            BeanResolutionContext context,
            BeanContext beanContext,
            BeanDefinition<OrderService> definition) {
        // Direct constructor call - no reflection
        return new OrderService(
            (OrderRepository) super.getBeanForConstructorArgument(
                context, beanContext, 0, null)
        );
    }
}
```

> **Code walkthrough:** The generated $OrderService$Definitionice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> encodes the constructor signature as metadata objects
> (not String-based reflection). The build() method
> calls new OrderService(...) directly - a compiled Java
> constructor call. super.getBeanForConstructorArgument()
> resolves the OrderRepository dependency by looking
> it up in the BeanContext. No java.lang.reflect.Constructor.newInstance()
> anywhere in this path.

---

### 📘 Concept Explanation

**What it is:**

The Micronaut Annotation Processing Pipeline is the compile-
time workflow that transforms annotated Java/Kotlin/Groovy source
code into pre-built `BeanDefinition` classes, HTTP client stubs,
route tables, and AOP-enhanced subclasses. It runs during the
standard compilation step via Java APT.

**How it works:**

Compilation sequence:
1. `javac` (or `kotlinc`) compiles source files
2. APT discovers registered annotation processors in the
   annotation processor classpath (`annotationProcessor` in
   Gradle / `<annotationProcessorPaths>` in Maven)
3. Micronaut's processors (`TypeElementVisitor` implementations)
   inspect annotated elements using the `javax.lang.model` API
4. Processors generate `.java` or `.class` files into the
   output directory
5. Generated files are compiled as part of the same build
6. ServiceLoader `META-INF/services/` entries register the
   generated `BeanDefinitionReference` classes for runtime discovery

Key processors:
- `BeanDefinitionInjectProcessor`: handles `@Singleton`, `@Inject`, etc.
- `HttpClientIntroductionAdvice`: generates declarative HTTP client stubs
- `ControllerIntroductionAdvice`: compiles route definitions

**Why it matters:**

The pipeline is the foundation of all Micronaut features.
Understanding it is essential for debugging missing beans,
configuring multi-module projects, and adding custom Micronaut
extensions.

---

### 🎓 Answers by Seniority

**Junior:** "Micronaut's annotation processors run
during compilation and generate classes that describe
each bean. At runtime these classes are loaded instead
of scanning for annotations."

**Senior:** "During annotation processing, Micronaut
emits a BeanDefinition class with a build() method that
calls the constructor directly via compiled bytecode.
For AOP, a separate $Intercepted subclass wraps the
original with generated interceptor dispatch calls.
GraalVM native-image sees only regular Java classes
with no reflection registration needed."

---

### ⚠️ Common Misconceptions

**Misconception 1: Micronaut's annotation processor runs
at runtime like Spring's annotation scanning.**

Spring's annotation processing is done at RUNTIME via
reflection-based classpath scanning. Micronaut's APT runs
at COMPILE TIME - it is part of the build, not the startup.
The output of the APT (`.class` files) is shipped in the
application JAR. At runtime, Micronaut reads these pre-built
files, not the source annotations. This distinction is critical:
adding a new Micronaut annotation to a class requires a
recompile; Spring sometimes allows adding Spring beans
without recompilation via component scanning.

**Misconception 2: The annotation processing pipeline
can be disabled for faster builds in development.**

Disabling Micronaut's APT would prevent bean definitions from
being generated, making the application non-functional.
The APT is not optional - it is how Micronaut works.
For faster incremental builds: enable Gradle incremental
annotation processing (Micronaut 3.2+ supports it), use
Gradle build cache, and split large monoliths into smaller
modules to reduce the per-module compilation scope.

**Misconception 3: Kotlin and Java Micronaut projects
use the same annotation processor configuration.**

Kotlin uses `kapt` (Kotlin Annotation Processing Tool) instead
of Gradle's `annotationProcessor` configuration. Micronaut
processors must be in `kapt` dependencies for Kotlin. In
Micronaut 4.x and Kotlin 1.9+, `ksp` (Kotlin Symbol Processing)
is the preferred alternative to `kapt` for better performance.
Misconfiguring (using `implementation` or wrong configuration)
silently results in no bean definitions being generated.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Custom annotation not processed because
TypeElementVisitor not registered in META-INF/services.**

Symptom: custom Micronaut extension annotation has no effect;
beans using it behave as if unAnnotated. Root cause: the
`TypeElementVisitor` implementation is not registered in
`META-INF/services/io.micronaut.inject.visitor.TypeElementVisitor`.
Diagnosis: check the extension JAR's META-INF/services directory
for the registration file. Fix: add the registration file,
or use Micronaut's `@Singleton` on the `TypeElementVisitor`
(Micronaut registers it via its own service discovery if
properly annotated).

**Failure Mode 2: APT error messages reference internal
Micronaut classes, hiding the actual user code error.**

Symptom: build fails with a stack trace showing Micronaut
internal classes but not pointing to the user's source file.
Root cause: exception thrown in the annotation processor
propagates through Micronaut internal code before being
reported by `javac` as an APT error. Diagnosis: look for
the LAST frame in the stack trace that references user code
(`com.mycompany.*`); also try running with `--stacktrace`
in Gradle. Fix: the actual error is usually: missing `@Introspected`,
type mismatch, circular dependency, or incorrect annotation
placement.

**Failure Mode 3: Incremental builds miss changes to
annotated interfaces, breaking HTTP client stubs.**

Symptom: after changing an `@Client`-annotated interface
(adding a new method), the application uses the stale stub
at runtime, missing the new method or using wrong types.
Root cause: Gradle incremental compilation determined the
interface file did not need recompilation; APT did not
regenerate the stub. Diagnosis: check if `build/classes`
has a stale stub by comparing method signatures. Fix: run
`./gradlew clean build` to force full regeneration; report
the incremental compilation issue to the Micronaut issue
tracker; as a workaround, touch the interface file to mark
it as changed.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | APT processors, generated class structure |
| Staff | 10 min | Custom TypeElementVisitor, incremental processing |

---

**[STAFF] Q1 - How would you write a custom Micronaut
annotation processor to enforce a coding rule?**

*Why they ask:* Extension point knowledge for advanced use.

Use TypeElementVisitor:
```java
@SupportedAnnotationTypes("io.example.*")
public class NoSpringAnnotationVisitor
        implements TypeElementVisitor<Object,Object> {

    @Override
    public void visitClass(
            ClassElement element,
            VisitorContext context) {

        // Check if class uses @Autowired (Spring)
        if (element.hasAnnotation(
                "org.springframework.beans.factory"
                + ".annotation.Autowired")) {
            context.fail(
                "Use @Inject instead of @Autowired",
                element);
            // Compile error!
        }
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates metadata declaration using Spring annotation. **KEY MECHANISM:** annotations are processed at compile-time or runtime via reflection. **WHY IT MATTERS:** annotation processing adds compile time; runtime reflection disables JIT optimizations. **TAKEAWAY: prefer compile-time annotation processors (APT) over runtime reflection for performance.**

Register in META-INF/services/
io.micronaut.core.annotation.Generated (SPI).

This runs at compile time and fails the build if
@Autowired is used - enforcing the team's migration
from Spring to Micronaut.

Other uses:
- Verify @ConfigurationProperties classes have @Validated
- Check @Controller return types are DTOs (not entities)
- Enforce naming conventions on bean classes

*What separates good from great:* TypeElementVisitor
as a compile-time linting tool for team conventions.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | APT processors list, generated class structure. |
| Hiring Manager | Compile-time code generation = fewer runtime errors. |
| Bar Raiser | TypeElementVisitor for custom rules, incremental APT. |
| Peer Engineer | "I wrote a TypeElementVisitor that fails the build if @Entity is returned from @Controller. Zero security leaks." |

---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*



