---
layout: default
title: "Spring - AOP"
parent: "Spring"
grand_parent: "Interview Mastery"
nav_order: 8
permalink: /interview/spring/aop/
topic: Spring
subtopic: AOP
keywords:
  - AOP Concepts and Proxies
  - Aspect Execution Order
  - Common AOP Use Cases
  - Self-Invocation and Proxy Pitfalls
  - Custom Annotations with AOP
difficulty_range: medium to hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [AOP Concepts and Proxies](#aop-concepts-and-proxies)
- [Aspect Execution Order](#aspect-execution-order)
- [Common AOP Use Cases](#common-aop-use-cases)
- [Self-Invocation and Proxy Pitfalls](#self-invocation-and-proxy-pitfalls)
- [Custom Annotations with AOP](#custom-annotations-with-aop)

# AOP Concepts and Proxies

**TL;DR** - Aspect-Oriented Programming (AOP) in Spring intercepts method calls via proxy objects to add cross-cutting concerns (logging, transactions, security) without modifying business code - using JDK dynamic proxies for interfaces or CGLIB proxies for concrete classes.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every service method starts with `log.info("entering...")`, followed by `securityCheck()`, then `startTimer()`, then business logic, then `stopTimer()`, then `log.info("exiting...")`. This cross-cutting code is duplicated in every method, tangling business logic with infrastructure concerns.

**THE BREAKING POINT:**
The team adds performance monitoring. Every method in 200 services needs timing code added. 2000 methods modified for the same 5 lines of boilerplate.

**THE INVENTION MOMENT:**
"This is exactly why AOP was created."

**EVOLUTION:**
Copy-paste cross-cutting code -> Template Method pattern -> Decorator pattern -> AspectJ (compile-time weaving, 2001) -> Spring AOP (runtime proxies, 2004) -> `@Aspect` annotation (AspectJ 5, 2005).

---

### 📘 Textbook Definition

Spring AOP uses the proxy pattern to intercept method calls at runtime. When a bean is proxied, callers get a proxy instead of the real object. The proxy executes advice (additional behavior) at join points (method executions) matched by pointcuts (expressions selecting methods). Spring AOP supports five advice types: `@Before`, `@After`, `@AfterReturning`, `@AfterThrowing`, and `@Around`. By default, Spring uses JDK dynamic proxies for beans implementing interfaces and CGLIB byte code generation for classes without interfaces.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Proxy wraps your bean, intercepts method calls, and runs additional code (logging, timing, security) before/after/around the real method.

**One analogy:**

> A phone call interceptor. The caller (client) dials a number (method call). The interceptor (proxy) picks up first, records the conversation (logging), checks caller ID (security), measures call duration (monitoring), then connects to the real person (target method). The real person never knows about the interceptor.

**One insight:**
AOP is the foundation of `@Transactional`, `@Cacheable`, `@Async`, `@Secured`, and `@Retryable`. Understanding AOP proxies explains all their behaviors and limitations (especially self-invocation).

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Spring AOP is proxy-based. The proxy intercepts external calls to the bean. Internal calls (self-invocation) bypass the proxy.
2. Only public methods can be advised (proxies intercept public method calls).
3. Spring AOP advises method execution only (not field access, constructor calls, etc.). For those, you need full AspectJ.

**DERIVED DESIGN:**
From invariant 1: `@Transactional`, `@Cacheable` do not work on self-invocation. From invariant 2: private/protected methods cannot be advised. From invariant 3: Spring AOP is simpler but less powerful than AspectJ.

**THE TRADE-OFFS:**

**Gain:** Clean separation of cross-cutting concerns. Business code is pure.

**Cost:** Proxy overhead (minimal). Self-invocation trap. Hidden behavior (magic).

---

### 🧠 Mental Model / Analogy

> AOP is like middleware in Express.js. Middleware (aspects) runs before/after route handlers (methods). You register middleware (pointcut + advice) once, and it applies to all matching routes. The route handler does not know about middleware. Same concept, different implementation.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is:**
AOP lets you add behavior (logging, timing) to methods without changing the methods themselves.

**Level 2 - How to use it (junior):**

AOP terminology:

| Term       | Meaning                 | Example                               |
| ---------- | ----------------------- | ------------------------------------- |
| Aspect     | Class containing advice | @Aspect class                         |
| Advice     | Code to run             | @Before, @Around                      |
| Pointcut   | Where to apply          | execution(_ com.app.service._.\*(..)) |
| Join Point | Method being advised    | Any matched method                    |
| Proxy      | Wrapper around bean     | JDK or CGLIB proxy                    |

```java
@Aspect
@Component
public class LoggingAspect {

    @Before("execution(* com.app"
        + ".service.*.*(..))")
    public void logBefore(
            JoinPoint jp) {
        log.info("Calling: {}",
            jp.getSignature().getName());
    }
}
```

**Level 3 - How it works (mid-level):**

Proxy creation:

```
  Spring creates bean: UserService
       |
  BeanPostProcessor detects
  aspects matching UserService methods
       |
  Creates proxy:
    Interface exists?
      Yes -> JDK dynamic proxy
      No  -> CGLIB subclass proxy
       |
  Proxy registered in context
  (instead of real bean)
       |
  Caller injects proxy,
  calls method on proxy
       |
  Proxy: run @Before advice
  Proxy: invoke real method
  Proxy: run @AfterReturning
  or @AfterThrowing
```

JDK proxy vs CGLIB:

| Feature        | JDK Dynamic Proxy     | CGLIB Proxy                        |
| -------------- | --------------------- | ---------------------------------- |
| Requires       | Interface             | Nothing                            |
| Mechanism      | Implements interface  | Subclass                           |
| Speed          | Slightly faster       | Slightly slower                    |
| Limitation     | Interface only        | Cannot proxy final class/method    |
| Spring default | When interface exists | Spring Boot default (forced CGLIB) |

**Level 4 - Mastery (senior/staff+):**

`@Around` advice (most powerful):

```java
@Around("execution(* com.app"
    + ".service.*.*(..))")
public Object timeExecution(
        ProceedingJoinPoint pjp)
        throws Throwable {
    long start = System.nanoTime();
    try {
        Object result = pjp.proceed();
        return result;
    } catch (Throwable t) {
        log.error("Failed: {}",
            pjp.getSignature(), t);
        throw t;
    } finally {
        long duration =
            System.nanoTime() - start;
        log.info("{} took {}ms",
            pjp.getSignature(),
            duration / 1_000_000);
    }
}
```

Pointcut expressions:

```java
// All service methods
@Pointcut("execution(* com.app"
    + ".service.*.*(..))")
void serviceMethods() {}

// Methods with custom annotation
@Pointcut("@annotation(Timed)")
void timedMethods() {}

// Combine
@Around("serviceMethods() "
    + "|| timedMethods()")
public Object advise(
    ProceedingJoinPoint pjp) { }
```

**The Senior-to-Staff Leap:**

**A Senior says:** "AOP is for logging and transactions."

**A Staff says:** "I understand that `@Transactional`, `@Cacheable`, `@Async`, `@Retryable`, and `@PreAuthorize` all use AOP proxies. The self-invocation limitation applies to ALL of them. I choose between Spring AOP (runtime, method-only) and AspectJ (compile-time, full power) based on needs. For production aspects, I use `@Around` with proper exception handling and metrics."

---

### ⚙️ How It Works

```
  Client calls proxy.doWork()
       |
  CGLIB/JDK Proxy intercepts
       |
  Aspect chain:
    @Before advice 1
    @Before advice 2
       |
    pjp.proceed() -> real method
       |
    @AfterReturning (success)
    or @AfterThrowing (exception)
       |
    @After (always)
       |
  Return result to client
```

---

### 💻 Code Example

**BAD scattered logging vs GOOD AOP:**

```java
// BAD - logging in every method
public User findById(Long id) {
    log.info("findById called: {}", id);
    long start = System.nanoTime();
    try {
        User user = repo.findById(id)
            .orElseThrow();
        log.info("findById success");
        return user;
    } finally {
        log.info("findById took {}ms",
            (System.nanoTime() - start)
            / 1_000_000);
    }
}

// GOOD - clean method + AOP aspect
public User findById(Long id) {
    return repo.findById(id)
        .orElseThrow();
}
// Logging handled by LoggingAspect
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Proxy-based method interception for cross-cutting concerns.

**KEY INSIGHT:** Foundation of @Transactional, @Cacheable, @Async. Self-invocation bypasses proxy.

**ANTI-PATTERN:** Using AOP for business logic. Overusing aspects (hidden behavior).

**ONE-LINER:** "Proxy intercepts method calls; advice runs before/after/around."

**TRIGGER PHRASE:** "Proxy-based, self-invocation limitation."

**If you remember only 3 things:**

1. Proxy wraps beans - external calls intercepted, self-calls bypass
2. JDK proxy for interfaces, CGLIB for classes (Boot defaults to CGLIB)
3. @Around is the most powerful advice (controls proceed, return, exception)

---

### ⚠️ Common Misconceptions

| #   | Misconception                   | Reality                                                                                 |
| --- | ------------------------------- | --------------------------------------------------------------------------------------- |
| 1   | "AOP advises all method calls"  | Only external calls through the proxy. Self-invocation bypasses.                        |
| 2   | "AOP works on private methods"  | No. Only public methods (proxy interception).                                           |
| 3   | "Spring AOP = AspectJ"          | Spring AOP is proxy-based (runtime). AspectJ is compile/load-time weaving (full power). |
| 4   | "AOP adds significant overhead" | CGLIB proxy adds < 1 microsecond per call. Negligible for most apps.                    |

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What is AOP and why use it in Spring?**

**Answer:**
AOP separates cross-cutting concerns (logging, transactions, security) from business logic. Instead of adding logging to 200 methods, you write one aspect that automatically applies to all matching methods.

Spring AOP uses proxies: callers get a proxy that runs advice (additional code) before/after the real method. `@Transactional` is the most common example - it is implemented as AOP advice that wraps methods in begin/commit/rollback.

---

**Q2 [MID]: JDK dynamic proxy vs CGLIB - when is each used?**

**Answer:**
JDK dynamic proxy: bean implements an interface. Proxy implements the same interface. Caller interacts through the interface.

CGLIB: bean has no interface. Proxy is a runtime subclass generated by bytecode manipulation. Cannot proxy final classes or methods.

Spring Boot defaults to CGLIB for all beans (even those with interfaces) via `spring.aop.proxy-target-class=true`. This avoids issues where the proxy type does not match the concrete class.

---

**Q3 [SENIOR]: How does understanding AOP explain the @Transactional self-invocation bug?**

**Answer:**
`@Transactional` is AOP advice. The proxy intercepts calls FROM OUTSIDE the bean. When a method calls another method in the SAME class (`this.method()`), it calls the real object directly, not the proxy. The transaction advice never runs.

This applies to ALL proxy-based features: `@Cacheable`, `@Async`, `@Retryable`, `@PreAuthorize`.

Fixes: inject self (call through proxy), extract to separate bean, or use AspectJ compile-time weaving (no proxy limitation).

---

### 🔗 Related Keywords

**Prerequisites:** IoC Container, Bean Lifecycle

**Builds on:** Transaction Management, Caching, Security

**Alternatives:** AspectJ (compile-time), Java Interceptors (Jakarta CDI)

---

---

# Aspect Execution Order

**TL;DR** - When multiple aspects apply to the same method, their execution order is controlled by `@Order` annotation or `Ordered` interface - critical because aspects like security must run before transaction management, which must run before caching.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Three aspects apply to a method: security, transaction, logging. Without explicit ordering, Spring executes them in undefined order. Security might run after the transaction starts, or logging might run before security - causing security bypasses or incorrect log entries.

---

### 📘 Textbook Definition

Aspect ordering in Spring AOP is controlled by the `@Order` annotation (lower value = higher priority) or by implementing the `Ordered` interface. For `@Around` advice, the aspect with the lowest order value executes its "before" logic first and its "after" logic last (like nested layers). Spring's built-in aspects have defined orders: Security (~0), Transaction (~Integer.MAX_VALUE), Cache (after transaction).

---

### ⏱️ Understand It in 30 Seconds

**One line:**
`@Order(1)` runs before `@Order(2)` on entry and after `@Order(2)` on exit - like nested Russian dolls.

**One analogy:**

> Nested envelopes. The outermost envelope (@Order(1) = security) is opened first and sealed last. The next envelope (@Order(2) = transaction) is inside. The innermost (@Order(3) = logging) is closest to the letter (actual method). Opening = before advice. Sealing = after advice. Security wraps everything.

---

### 📶 Gradual Depth

**Level 3 - How it works (mid-level):**

```
  @Order(1) Security - before
    @Order(2) Transaction - begin
      @Order(3) Logging - log entry
        Actual method executes
      @Order(3) Logging - log exit
    @Order(2) Transaction - commit
  @Order(1) Security - complete
```

If the method throws:

```
  @Order(1) Security - before
    @Order(2) Transaction - begin
      @Order(3) Logging - log entry
        Method throws exception
      @Order(3) Logging - log error
    @Order(2) Transaction - ROLLBACK
  @Order(1) Security - handle error
```

**Level 4 - Mastery (senior/staff+):**

Spring's built-in aspect ordering:

```java
// Security: Ordered.HIGHEST_PRECEDENCE
// (runs first on entry, last on exit)

// Transaction: default order
// (after security)

// Cache: after transaction
// (reads from cache before TX if cached)
```

Custom ordering:

```java
@Aspect
@Component
@Order(1)  // Runs first
public class SecurityAspect {
    @Around("serviceMethods()")
    public Object secure(
        ProceedingJoinPoint pjp)
        throws Throwable { }
}

@Aspect
@Component
@Order(2)  // Runs second
public class TransactionAspect {
    @Around("serviceMethods()")
    public Object transact(
        ProceedingJoinPoint pjp)
        throws Throwable { }
}
```

Important: `@Order` only controls ordering BETWEEN aspects. Multiple advice methods WITHIN the same aspect class follow a fixed order: `@Around` > `@Before` > `@After` > `@AfterReturning` > `@AfterThrowing`.

---

### 📌 Quick Reference Card

**WHAT IT IS:** Controlling execution order of multiple aspects on the same method.

**KEY INSIGHT:** Lower @Order = runs first on entry, last on exit (nesting).

**ANTI-PATTERN:** Relying on default order. Not controlling security vs transaction ordering.

**ONE-LINER:** "Security(1) wraps Transaction(2) wraps Logging(3) = nested execution."

**If you remember only 3 things:**

1. @Order(1) = highest priority (runs first on entry, last on exit)
2. Aspects nest like Russian dolls: outer wraps inner
3. @Order controls between-aspect order; within-aspect order is fixed

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How do you control the order of multiple aspects?**

**Answer:**
`@Order(n)` on the `@Aspect` class. Lower value = higher priority. Execution is nested: `@Order(1)` before-advice runs first, then `@Order(2)` before-advice, then the method, then `@Order(2)` after-advice, then `@Order(1)` after-advice. Like nested function calls or middleware chains.

Typical order: Security (1) -> Transaction (2) -> Caching (3) -> Logging (4).

---

### 🔗 Related Keywords

**Prerequisites:** AOP Concepts and Proxies

**Builds on:** Transaction Management, Caching, Security

**Alternatives:** Servlet Filter ordering (@Order on FilterRegistrationBean)

---

---

# Common AOP Use Cases

**TL;DR** - The most valuable AOP use cases in production are: logging/tracing, performance monitoring, transaction management, security enforcement, retry logic, and rate limiting - all cross-cutting concerns that would otherwise be duplicated across hundreds of methods.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Cross-cutting concerns (logging, monitoring, retry, rate limiting) are copy-pasted into every method. Adding a new concern requires modifying every service. Removing a concern requires finding and deleting code from every method.

---

### 📶 Gradual Depth

**Level 2 - Common use cases:**

| Use Case     | Spring Feature | How                   |
| ------------ | -------------- | --------------------- |
| Transactions | @Transactional | Begin/commit/rollback |
| Caching      | @Cacheable     | Cache method results  |
| Security     | @PreAuthorize  | Check permissions     |
| Async        | @Async         | Run in thread pool    |
| Retry        | @Retryable     | Retry on failure      |
| Logging      | Custom @Aspect | Log entry/exit        |
| Monitoring   | Custom @Aspect | Track latency         |

**Level 4 - Mastery (senior/staff+):**

Production monitoring aspect:

```java
@Aspect
@Component
public class MetricsAspect {
    private final MeterRegistry registry;

    @Around("@annotation(Monitored)")
    public Object monitor(
            ProceedingJoinPoint pjp)
            throws Throwable {
        String method = pjp.getSignature()
            .toShortString();
        Timer.Sample sample =
            Timer.start(registry);
        try {
            Object result =
                pjp.proceed();
            sample.stop(Timer.builder(
                "method.execution")
                .tag("method", method)
                .tag("status", "success")
                .register(registry));
            return result;
        } catch (Throwable t) {
            sample.stop(Timer.builder(
                "method.execution")
                .tag("method", method)
                .tag("status", "error")
                .register(registry));
            registry.counter(
                "method.errors",
                "method", method)
                .increment();
            throw t;
        }
    }
}
```

Retry with backoff:

```java
@Retryable(
    retryFor =
        TransientException.class,
    maxAttempts = 3,
    backoff = @Backoff(
        delay = 1000,
        multiplier = 2))
public ExternalData callApi() {
    return restClient.get()
        .retrieve()
        .body(ExternalData.class);
}

@Recover
public ExternalData fallback(
        TransientException ex) {
    return ExternalData.cached();
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Standard patterns where AOP eliminates cross-cutting boilerplate.

**KEY INSIGHT:** @Transactional, @Cacheable, @Async, @Retryable are all AOP aspects.

**ANTI-PATTERN:** Using AOP for business logic (should be explicit code, not hidden).

**ONE-LINER:** "If it is duplicated in 100 methods and is not business logic, use AOP."

**If you remember only 3 things:**

1. Transactions, caching, security, async, retry = all AOP
2. Custom aspects for monitoring and logging
3. Never use AOP for business logic (too hidden)

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: What are common AOP use cases in a Spring production app?**

**Answer:**

1. **Transactions** (@Transactional) - most common
2. **Caching** (@Cacheable) - method result caching
3. **Security** (@PreAuthorize) - method-level authz
4. **Monitoring** (custom @Aspect) - latency metrics with Micrometer
5. **Retry** (@Retryable) - transient failure handling
6. **Logging** (custom @Aspect) - structured entry/exit logging

All share the same proxy mechanism and self-invocation limitation.

---

### 🔗 Related Keywords

**Prerequisites:** AOP Concepts and Proxies

**Builds on:** Transaction Management, Caching, Security

**Related:** Micrometer, Spring Retry, Spring Cache

---

---

# Self-Invocation and Proxy Pitfalls

**TL;DR** - When a bean calls its own `@Transactional`, `@Cacheable`, or `@Async` method internally (`this.method()`), the AOP proxy is bypassed and the aspect does not execute - this is the single most common AOP bug in Spring applications.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Developers add `@Transactional` to a method and assume it works. When called from within the same class, no transaction is created. Data inconsistencies occur with no error or warning. The bug is silent and hard to diagnose.

---

### 📘 Textbook Definition

Self-invocation occurs when a bean method calls another method on the same bean instance using `this`. Since Spring AOP uses proxies that wrap the bean, `this` refers to the real object, not the proxy. The proxy only intercepts calls from external callers. Any `@Transactional`, `@Cacheable`, `@Async`, `@Retryable`, or `@PreAuthorize` annotation on the self-invoked method is silently ignored.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
`this.method()` calls the real object; proxy.method() calls through AOP. Self-calls skip the proxy, so all AOP annotations are silently ignored.

**One analogy:**

> A front desk that screens visitors. External visitors (callers) go through the front desk (proxy) which checks IDs (security), logs visits (logging), and manages appointments (transactions). But employees (same class methods) walk directly to each other's offices through internal hallways - completely bypassing the front desk. No screening, no logging, no appointments.

---

### 📶 Gradual Depth

**Level 3 - How it works (mid-level):**

```
  EXTERNAL call (through proxy):
  caller -> Proxy -> Aspect chain
  -> real method
  (AOP WORKS)

  SELF-INVOCATION (bypasses proxy):
  this.method() -> real method directly
  (AOP DOES NOT WORK)
```

Visual:

```
  External caller
       |
  [AOP Proxy]  <-- intercepts here
       |
  [Real Bean]
    methodA() calls this.methodB()
    -> goes directly to methodB()
    -> BYPASSES proxy
    -> @Transactional on methodB
       is IGNORED
```

**Level 4 - Mastery (senior/staff+):**

All affected annotations:

| Annotation     | Self-invocation effect |
| -------------- | ---------------------- |
| @Transactional | No transaction created |
| @Cacheable     | Cache not checked      |
| @Async         | Runs synchronously     |
| @Retryable     | No retry on failure    |
| @PreAuthorize  | Security not checked   |

Fixes:

```java
// Fix 1: Inject self (recommended)
@Service
public class OrderService {
    @Autowired
    private OrderService self;

    public void process() {
        self.save(); // through proxy!
    }

    @Transactional
    public void save() { }
}

// Fix 2: Extract to separate bean
@Service
public class OrderProcessor {
    private final OrderPersister persister;

    public void process() {
        persister.save(); // external call
    }
}

@Service
public class OrderPersister {
    @Transactional
    public void save() { }
}

// Fix 3: ObjectProvider (lazy)
@Service
public class OrderService {
    private final ObjectProvider<
        OrderService> selfProvider;

    public void process() {
        selfProvider.getObject().save();
    }

    @Transactional
    public void save() { }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Self-invocation is a known Spring issue."

**A Staff says:** "I design services so transactional boundaries are at the public API level. Internal helper methods do not need `@Transactional` because the caller's transaction propagates. When I must call a transactional method internally, I extract it to a separate bean (cleaner than self-injection). I review code for this pattern during PRs."

---

### 💻 Code Example

**BAD self-invocation vs GOOD external call:**

```java
// BAD - silent transaction bypass
@Service
public class PaymentService {
    public void processPayment(
            PaymentReq req) {
        validatePayment(req);
        // THIS CALL HAS NO TRANSACTION!
        this.executePayment(req);
    }

    @Transactional
    public void executePayment(
            PaymentReq req) {
        accountRepo.debit(
            req.getFrom(), req.getAmount());
        accountRepo.credit(
            req.getTo(), req.getAmount());
    }
}

// GOOD - separate bean
@Service
@RequiredArgsConstructor
public class PaymentService {
    private final PaymentExecutor executor;

    public void processPayment(
            PaymentReq req) {
        validatePayment(req);
        executor.execute(req);
    }
}

@Service
public class PaymentExecutor {
    @Transactional
    public void execute(PaymentReq req) {
        accountRepo.debit(
            req.getFrom(), req.getAmount());
        accountRepo.credit(
            req.getTo(), req.getAmount());
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** The #1 Spring AOP bug - self-invocation bypasses proxy.

**KEY INSIGHT:** this.method() skips proxy. @Transactional, @Cacheable, @Async all affected.

**FIX:** Extract to separate bean (cleanest) or inject self.

**ONE-LINER:** "this.method() = no proxy = no AOP. Always call through the proxy."

**TRIGGER PHRASE:** "Self-invocation bypass."

**If you remember only 3 things:**

1. Self-invocation (`this.method()`) bypasses ALL AOP annotations silently
2. Fix: extract to separate bean or inject self
3. Affects @Transactional, @Cacheable, @Async, @Retryable, @PreAuthorize

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: What is the self-invocation problem in Spring?**

**Answer:**
Spring AOP uses proxies. External calls go through the proxy (AOP works). Internal calls (`this.method()`) go directly to the real object, bypassing the proxy. Any AOP annotation (@Transactional, @Cacheable, etc.) on the self-invoked method is silently ignored. No error, no warning.

Fix: extract the method to a separate bean so the call goes through the proxy, or inject self via `@Autowired`.

---

### 🔗 Related Keywords

**Prerequisites:** AOP Concepts and Proxies

**Builds on:** Transaction Management, Caching

**Related:** AspectJ (compile-time weaving has no self-invocation issue)

---

---

# Custom Annotations with AOP

**TL;DR** - Creating custom annotations backed by AOP aspects lets you build reusable, declarative cross-cutting behaviors (like `@Timed`, `@RateLimit`, `@Audit`) that developers apply to methods with a single annotation - encapsulating complex infrastructure logic.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Adding timing to a method requires knowing the aspect's pointcut expression. If the pointcut changes, all matching methods are affected. There is no explicit marker on the method indicating it is being timed.

**THE INVENTION MOMENT:**
"This is exactly why custom annotations with AOP were created."

---

### 📘 Textbook Definition

A custom AOP annotation is a user-defined annotation (meta-annotated with `@Retention(RUNTIME)` and `@Target(METHOD)`) that serves as a pointcut marker. An `@Aspect` component matches methods annotated with it using `@annotation(CustomAnnotation)` pointcut expression, executing advice when the annotation is present. This creates a declarative API: developers annotate methods and the aspect handles the cross-cutting concern.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
// 1. Define annotation
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Timed {
    String value() default "";
}

// 2. Create aspect
@Aspect
@Component
public class TimedAspect {
    @Around("@annotation(timed)")
    public Object time(
            ProceedingJoinPoint pjp,
            Timed timed) throws Throwable {
        long start = System.nanoTime();
        try {
            return pjp.proceed();
        } finally {
            long ms = (System.nanoTime()
                - start) / 1_000_000;
            log.info("{} took {}ms",
                pjp.getSignature()
                    .toShortString(),
                ms);
        }
    }
}

// 3. Use it
@Service
public class OrderService {
    @Timed
    public Order placeOrder(
            OrderReq req) {
        // Method automatically timed
        return processOrder(req);
    }
}
```

**Level 4 - Mastery (senior/staff+):**

Annotation with parameters:

```java
@Target(METHOD)
@Retention(RUNTIME)
public @interface RateLimit {
    int maxPerSecond() default 10;
    String key() default "";
}

@Aspect
@Component
public class RateLimitAspect {
    private final Map<String,
        RateLimiter> limiters =
            new ConcurrentHashMap<>();

    @Around("@annotation(limit)")
    public Object rateLimit(
            ProceedingJoinPoint pjp,
            RateLimit limit)
            throws Throwable {
        String key = limit.key().isEmpty()
            ? pjp.getSignature()
                .toShortString()
            : limit.key();
        RateLimiter limiter = limiters
            .computeIfAbsent(key,
                k -> RateLimiter.create(
                    limit.maxPerSecond()));
        if (!limiter.tryAcquire()) {
            throw new RateLimitException(
                "Rate limit exceeded: "
                + key);
        }
        return pjp.proceed();
    }
}

// Usage:
@RateLimit(maxPerSecond = 100,
    key = "search-api")
public List<Product> search(
        String query) { }
```

Audit annotation:

```java
@Target(METHOD)
@Retention(RUNTIME)
public @interface Audited {
    String action();
}

@Aspect
@Component
public class AuditAspect {
    @AfterReturning(
        pointcut = "@annotation(audited)",
        returning = "result")
    public void audit(JoinPoint jp,
            Audited audited,
            Object result) {
        String user = SecurityContextHolder
            .getContext()
            .getAuthentication()
            .getName();
        auditService.log(
            user,
            audited.action(),
            jp.getArgs(),
            result);
    }
}

@Audited(action = "DELETE_USER")
public void deleteUser(Long userId) { }
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Create a custom annotation and match it with `@annotation()`."

**A Staff says:** "I design a library of custom AOP annotations (@Timed, @RateLimit, @Audit, @Retry) that encapsulate infrastructure concerns as a shared library. Each annotation has configurable parameters. Aspects are ordered correctly. The annotations are self-documenting - developers see exactly what cross-cutting behavior applies."

---

### 💻 Code Example

**BAD hardcoded monitoring vs GOOD @Timed annotation:**

```java
// BAD - monitoring code in method
public Order placeOrder(OrderReq req) {
    Timer.Sample sample =
        Timer.start(registry);
    try {
        Order order = process(req);
        sample.stop(Timer.builder(
            "order.place")
            .tag("status", "ok")
            .register(registry));
        return order;
    } catch (Exception e) {
        sample.stop(Timer.builder(
            "order.place")
            .tag("status", "error")
            .register(registry));
        throw e;
    }
}

// GOOD - declarative annotation
@Timed("order.place")
public Order placeOrder(OrderReq req) {
    return process(req);
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** User-defined annotations backed by AOP aspects for declarative cross-cutting.

**KEY INSIGHT:** Annotations are the API. Aspects are the implementation. Decoupled and reusable.

**ANTI-PATTERN:** Aspect without annotation (invisible behavior). Over-annotating methods.

**ONE-LINER:** "Custom annotation + @Aspect = reusable declarative infrastructure."

**If you remember only 3 things:**

1. @Target(METHOD) + @Retention(RUNTIME) for the annotation
2. @Around("@annotation(annotationParam)") for the aspect
3. Annotation parameters make aspects configurable

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How do you create a custom @Timed annotation in Spring?**

**Answer:**
Three steps:

1. Define `@Timed` annotation with `@Target(METHOD)`, `@Retention(RUNTIME)`
2. Create `@Aspect @Component` class with `@Around("@annotation(timed)")` advice
3. In the advice: measure time around `pjp.proceed()`, log or record metric

The annotation parameter (`timed`) in the pointcut expression gives access to annotation values. Use `@Around` for timing because you need to wrap the method execution.

---

### 🔗 Related Keywords

**Prerequisites:** AOP Concepts and Proxies, Java Annotations

**Builds on:** Common AOP Use Cases

**Related:** Micrometer @Timed, Spring Retry @Retryable
