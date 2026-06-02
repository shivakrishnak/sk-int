---
layout: default
title: "Spring - L3 AOP and Transactions"
parent: "Spring"
nav_order: 7
permalink: /spring/l3-aop-and-transactions/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Spring - L3 AOP and Transactions](#spring---l3-aop-and-transactions) | medium |
| 2 | [Spring AOP and Proxies](#spring-aop-and-proxies) | medium |
| 3 | [@Transactional and Transaction Management](#transactional-and-transaction-management) | medium |

---

# Spring AOP and Proxies

---
id: SPR-016
title: Spring AOP and Proxies
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: Mid/Senior
seniority: mid
tags: #spring-aop, #proxy, #cglib, #aspect, #crosscutting
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - AOP powers @Transactional, @Async, @Cacheable,
@Secured. Understanding proxies explains why self-invocation breaks these.

---

### 🎯 Model Answer

**30 seconds:**
> Spring AOP works by wrapping beans in proxies. When you annotate a method
> with @Transactional or @Cacheable, Spring creates a proxy class that
> intercepts method calls, runs the advice (open transaction, check cache),
> and delegates to your actual method. The critical implication: calling
> a @Transactional method on `this` inside the same class bypasses the proxy
> - no transaction is started. External calls through the injected bean go
> through the proxy correctly.

**3 minutes (Senior):**
> Spring uses two proxy mechanisms. JDK dynamic proxies require the bean to
> implement an interface - the proxy implements the same interface and
> intercepts calls. CGLIB proxies subclass the target class - no interface
> required. Spring Boot defaults to CGLIB since Spring 5.2 (spring.aop.
> proxy-target-class=true). CGLIB requires the class to be subclassable (not
> final) and methods to be overridable (not final/static/private).
>
> The self-invocation problem is the most important AOP limitation. A proxy
> only intercepts calls from OUTSIDE the bean. When a method calls another
> method in the same class via `this`, it calls the real object directly,
> bypassing the proxy. This is why @Transactional annotation on a private
> method or an internally-called method silently has no effect.
>
> AspectJ weaving is an alternative that instruments bytecode directly,
> without proxies. It works for self-invocation because the advice is woven
> into the bytecode itself. Spring supports AspectJ weaving via load-time
> weaving (LTW), but proxy-based AOP covers 95% of use cases.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - discuss writing custom @Aspect with @Around advice,
the Joinpoint API for accessing method metadata, and ProceedingJoinPoint for
calling through.

*Adapting down:* Junior - "Annotations like @Transactional work because Spring
wraps your class in a wrapper (proxy) that adds behaviour before/after your
method. The proxy only works when the method is called from outside the class."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking how Spring AOP works and why self-invocation
is a problem."

**(2) First principles:** "Cross-cutting concerns (transactions, caching,
security) should not be mixed with business code. AOP separates them by
intercepting method calls."

**(3) Bridge:** "AOP is like a call interceptor at the company reception -
all external calls go through reception (the proxy). Internal calls between
staff skip reception. That's why internal calls don't get processed."

---

### 📘 Concept Explanation

**What it is:**
Spring AOP is a proxy-based aspect-oriented programming implementation that
enables cross-cutting concerns (logging, transactions, caching, security) to
be applied to beans without modifying their code.

**The problem it solves:**
Business logic methods should not contain transaction management, security
checks, or cache lookups. AOP separates these concerns into aspects that
are applied declaratively via annotations (@Transactional, @Cacheable).

**How it works:**

```
AOP Proxy Creation (during context refresh):

Your bean:
  @Service
  public class OrderService {
      @Transactional  <- advice point
      public Order createOrder(OrderRequest req) {
          // business logic
      }
  }

Spring AOP detects @Transactional.
Creates CGLIB proxy (default in Spring Boot):

  class OrderService$$SpringCGLIB$$0
          extends OrderService {
      private final Interceptor[] interceptors;

      @Override
      public Order createOrder(OrderRequest req) {
          // 1. Run interceptors (open transaction)
          for (Interceptor i : interceptors) {
              i.before();
          }
          // 2. Delegate to super (real logic)
          Order result = super.createOrder(req);
          // 3. Post-process (commit/rollback)
          for (Interceptor i : interceptors) {
              i.after(result);
          }
          return result;
      }
  }

What is registered in the context:
  orderService bean = OrderService$$SpringCGLIB$$0
  (the proxy, not the real object)

External call (CORRECT - goes through proxy):
  orderService.createOrder(req)
  -> proxy.createOrder(req)
  -> interceptors run (transaction opens)
  -> super.createOrder(req) (your code runs)
  -> interceptors post-process (commit/rollback)

Internal call (BROKEN - bypasses proxy):
  public void batchCreate(List<OrderRequest> reqs) {
      for (OrderRequest r : reqs) {
          this.createOrder(r); // calls real object!
          // 'this' is NOT the proxy
          // @Transactional on createOrder IGNORED
      }
  }
```

> **Code walkthrough:** This Spring AOP and Proxies example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

**The key insight:**
The Spring context holds the PROXY, not your original object. When beans inject
OrderService, they receive the proxy. But `this` inside OrderService refers to
the real object - it skips the proxy. This is the root cause of the self-
invocation problem.

**When to use it:**
- @Transactional: transaction demarcation
- @Cacheable / @CacheEvict: method-level caching
- @Async: execute method in a thread pool
- @Secured / @PreAuthorize: method-level security
- Custom @Aspect for cross-cutting concerns: logging, metrics, rate limiting

**When NOT to use it:**
- Private methods: CGLIB cannot override private methods - @Transactional on
  private methods is silently ignored
- Final classes or methods: CGLIB cannot subclass final - Spring throws error
- Self-invocation patterns: use another bean to force calls through proxy

**Alternatives:**
- AspectJ load-time weaving: works for self-invocation but requires Java agent
- Manual try/finally: explicit transaction management without AOP
- Decorator pattern: explicit wrapper classes instead of proxy injection

**First-principles derivation:**
Cross-cutting concerns are inherently repetitive: open transaction, run code,
close transaction. AOP is the abstraction that extracts this repetition. The
proxy pattern is the implementation mechanism: wrap the object, intercept calls,
add behaviour without modifying the original.

---

### 💻 Code Example

```java
// BAD: self-invocation breaks @Transactional
@Service
public class OrderService {

    @Transactional
    public void createOrder(OrderRequest req) {
        // This @Transactional is applied correctly
        // when called from outside
        orderRepository.save(new Order(req));
    }

    public void batchCreate(List<OrderRequest> reqs) {
        for (OrderRequest req : reqs) {
            this.createOrder(req); // BUG: no transaction!
            // 'this' bypasses proxy
            // If any createOrder throws, previous saves
            // are NOT rolled back (each had no TX)
        }
    }
}
```

> **Code walkthrough:** batchCreate calls createOrder via `this` - the realice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> object, not the proxy. The @Transactional annotation on createOrder is
> completely ignored. Each createOrder call has no transaction - if the 5th
> call throws a runtime exception, the first 4 orders are committed to the
> database with no rollback.

```java
// GOOD: extract to separate bean to force proxy usage
@Service
public class OrderService {

    private final SingleOrderCreator creator;

    public OrderService(SingleOrderCreator creator) {
        this.creator = creator;
    }

    public void batchCreate(List<OrderRequest> reqs) {
        for (OrderRequest req : reqs) {
            creator.create(req); // calls proxy!
        }
    }
}

@Service
public class SingleOrderCreator {
    @Transactional  // proxy intercepts this correctly
    public void create(OrderRequest req) {
        orderRepository.save(new Order(req));
    }
}

// Alternative: self-inject (less clean, works)
@Service
public class OrderService {
    @Autowired  // inject the proxy of this bean
    @Lazy
    private OrderService self; // Spring injects proxy

    @Transactional
    public void createOrder(OrderRequest req) {
        orderRepository.save(new Order(req));
    }

    public void batchCreate(List<OrderRequest> reqs) {
        for (OrderRequest req : reqs) {
            self.createOrder(req); // calls proxy
        }
    }
}
```

> **Code walkthrough:** The clean fix is extracting the transactional methodice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> to a separate bean. When OrderService calls creator.create(), the call goes
> through the proxy of SingleOrderCreator - the @Transactional is correctly
> applied. The self-injection alternative works but smells: a bean injecting
> itself is a code smell that usually indicates a design issue worth addressing
> by extraction.

```java
// Custom @Aspect for cross-cutting concerns
@Aspect
@Component
public class ExecutionTimeAspect {

    // Pointcut: all public methods in service package
    @Around("execution(public * " +
            "com.example.service..*.*(..))")
    public Object trackExecutionTime(
            ProceedingJoinPoint pjp) throws Throwable {
        long start = System.currentTimeMillis();
        try {
            // ProceedingJoinPoint.proceed() calls the
            // actual method
            return pjp.proceed();
        } finally {
            long elapsed = System.currentTimeMillis()
                - start;
            log.info("{}.{} executed in {}ms",
                pjp.getTarget().getClass()
                   .getSimpleName(),
                pjp.getSignature().getName(),
                elapsed);
        }
    }
}

// Custom annotation for selective advice
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Monitored {
    String operationName() default "";
}

@Aspect
@Component
public class MonitoredAspect {
    @Around("@annotation(monitored)")
    public Object monitor(
            ProceedingJoinPoint pjp,
            Monitored monitored) throws Throwable {
        String opName = monitored.operationName()
            .isEmpty()
            ? pjp.getSignature().getName()
            : monitored.operationName();
        // metrics recording...
        return pjp.proceed();
    }
}
```

> **Code walkthrough:** @Around advice with ProceedingJoinPoint gives completeice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> control: you call pjp.proceed() to invoke the actual method. The try/finally
> ensures timing is recorded even on exceptions. The custom @Monitored annotation
> pattern is how @Transactional, @Cacheable, and @Async are implemented - an
> annotation + an @Aspect that recognizes it.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring AOP works by wrapping your beans in proxy objects. When you call a
> method on an injected bean, the proxy intercepts it and applies any aspects
> (like starting a transaction for @Transactional). The catch is that calling
> a method inside the same class using `this` bypasses the proxy - the aspect
> doesn't run. To fix this, move the method to a separate bean so calls go
> through the proxy.

*Push deeper:* Explain that @Transactional on private methods is silently
ignored because CGLIB cannot override private methods.

---

**Senior / Staff (5+ years):**
> Spring uses CGLIB by default (proxy-target-class=true). CGLIB subclasses
> the target class, overriding public and protected methods to add interceptors.
> Requirements: class must not be final, method must not be final/static/private.
> The proxy pattern's limitation is self-invocation: `this` refers to the real
> object, not the proxy. Solutions: extract to a separate bean, self-inject with
> @Lazy, or use ApplicationContext.getBean(). For use cases where self-invocation
> cannot be avoided (event dispatching within the same bean), AspectJ LTW is the
> correct tool.

*Push deeper:* @EnableAspectJAutoProxy(exposeProxy = true) enables
AopContext.currentProxy() to get the proxy from inside the bean. This is the
Spring-provided escape hatch for self-invocation, but it is an anti-pattern
for regular use.

---

### ⚠️ Common Misconceptions

**Misconception 1: "@Transactional works on private methods."**
CGLIB creates a subclass - it cannot override private methods. @Transactional
on private methods is silently ignored. Spring 6.0 logs a warning when this
is detected. Use package-private or public for transactional methods.

**Misconception 2: "JDK proxies are always used when an interface exists."**
Spring Boot 2.0+ defaults to CGLIB (proxy-target-class=true) even when an
interface exists. JDK proxies are used only when explicitly configured
(spring.aop.proxy-target-class=false).

**Misconception 3: "AOP aspects fire for ALL method calls."**
Spring AOP only fires for external calls via the proxy. Internal calls within
the same class bypass all aspects. This is a fundamental limitation of proxy-
based AOP.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: @Transactional silently not working**
Symptom: No transaction started; exceptions don't roll back data.
Cause: Self-invocation (calling this.transactionalMethod()), private method,
final method, or the annotated class is not a Spring bean.
Diagnosis: Add logging to see if the transaction interceptor fires; check
spring.jpa.show-sql output for transaction markers.
Fix: Extract to separate bean, or use @Transactional on the calling method.

**Failure 2: Cannot subclass - @Bean method on final class**
Symptom: "Cannot subclass final class com.example.Config" at startup.
Cause: @Configuration class or @Service class is final, CGLIB cannot proxy.
Fix: Remove final from the class.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] How does Spring AOP work?**

Spring AOP works by creating proxy objects around managed beans. When a Spring
bean has methods with AOP-applicable annotations (@Transactional, @Cacheable,
@Async), Spring creates a proxy class that:
1. Extends the target class (CGLIB) or implements its interfaces (JDK proxy)
2. Overrides public methods to insert interceptor chain
3. Registers the proxy (not the real object) in the ApplicationContext

At call time: caller calls proxy method -> proxy runs before advice ->
proxy calls target method via super (CGLIB) or delegation (JDK) ->
proxy runs after/around advice.

*What separates good from great:* AOP proxy creation happens in the
BeanPostProcessor post-initialization phase (AbstractAutoProxyCreator).
This is step 8 in the bean lifecycle - AFTER @PostConstruct. Any call
from @PostConstruct goes to the real object, not the proxy.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What is the self-invocation problem and how do you fix it?**

Self-invocation: calling a proxied method from within the same class via `this`.
`this` refers to the real object, not the proxy. The proxy never intercepts
the call. Any advice (@Transactional, @Cacheable, etc.) on the called method
is silently ignored.

Example:
```java
@Transactional
public void outer() {
    this.inner(); // inner() @Transactional NOT applied
}

@Transactional(propagation = REQUIRES_NEW)
public void inner() { ... }
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

Fixes (best to worst):
1. Extract inner() to a separate @Service - cleanest design
2. @Autowired @Lazy private MyService self; - self-injection hack
3. AopContext.currentProxy() with @EnableAspectJAutoProxy(exposeProxy=true)
4. AspectJ LTW - works for self-invocation but requires Java agent

*What separates good from great:* The need to work around self-invocation
usually indicates a design issue. If you need separate transactions for
multiple operations in one class, a separate service boundary is the right
structural answer.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What is the difference between JDK proxy and CGLIB proxy?**

**JDK dynamic proxy:**
- Requires the target class to implement at least one interface
- The proxy implements the same interfaces as the target
- Uses java.lang.reflect.Proxy
- Cannot proxy methods not in an interface
- Spring default before Spring Boot 2.0

**CGLIB proxy:**
- Subclasses the target class (no interface required)
- Overrides public and protected methods
- Cannot proxy final classes or final/static/private methods
- Spring Boot 2.0+ default (proxy-target-class=true)
- Slightly higher startup cost (bytecode generation)

Spring Boot 2.0 changed the default to CGLIB to solve a common injection bug:
@Autowired MyService service (where MyService is a class, not interface) failed
with JDK proxy because the proxy only implements the interface, not MyService.

*What separates good from great:* Spring Boot 3 improved CGLIB with "class-data
sharing" - CGLIB generated classes are reused across tests, speeding up test
context startup. For GraalVM native images, CGLIB proxies are pre-generated
at build time by the AOT engine.

---

**[MID] Q4 - [CONCEPTUAL] What AOP advice types does Spring support?**

Spring AOP supports five advice types matching the standard AOP vocabulary:

- **@Before**: runs before the method. Cannot veto execution.
  ```java
  @Before("execution(* com.example..*.*(..))")
  public void logBefore(JoinPoint jp) { ... }
  ```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

- **@After**: runs after the method (always - both success and exception).
  Like a finally block.

- **@AfterReturning**: runs after successful return. Has access to return value.

- **@AfterThrowing**: runs after an exception is thrown. Has access to exception.

- **@Around**: wraps the entire execution. Must call pjp.proceed() to invoke
  the method. Most powerful - can modify arguments, return value, or suppress
  exceptions.

*What separates good from great:* @Around should be used only when you need
to control execution (conditional proceed, modify return value, handle exceptions).
For simple before/after logging, @Before and @After are cleaner because they
have narrower responsibility.

---

**[MID] Q5 - [HANDS-ON] How do you write a custom aspect?**

```java
// 1. Custom annotation as joinpoint marker
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface AuditLog {
    String action();
}

// 2. Aspect class with @Around advice
@Aspect
@Component
public class AuditAspect {

    @Around("@annotation(auditLog)")
    public Object audit(
            ProceedingJoinPoint pjp,
            AuditLog auditLog) throws Throwable {

        String user = SecurityContextHolder.getContext()
            .getAuthentication().getName();
        String action = auditLog.action();

        try {
            Object result = pjp.proceed();
            auditService.log(user, action, "SUCCESS");
            return result;
        } catch (Exception e) {
            auditService.log(user, action, "FAILURE");
            throw e;
        }
    }
}

// 3. Usage
@Service
public class OrderService {
    @AuditLog(action = "CREATE_ORDER")
    public Order createOrder(OrderRequest req) { ... }
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using Spring annotation. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* The aspect method signature includes the
AuditLog parameter - Spring binds the annotation instance to it, giving you
access to annotation attributes. Without this, you'd need pjp.getMethod()
.getAnnotation(AuditLog.class) to access the annotation.

---

**[MID] Q6 - [HANDS-ON] What is a pointcut expression and how do you write one?**

A pointcut expression defines which joinpoints (method executions) an advice
applies to. Common expressions:

**execution()** - most common:
```java
// All public methods in all classes:
execution(public * *(..))

// All methods in a specific package:
execution(* com.example.service.*.*(..))

// Specific method signature:
execution(* com.example.OrderService.create*(..))
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**@annotation()** - match by annotation:
```java
// Any method with @Transactional
@annotation(org.springframework.transaction
    .annotation.Transactional)
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

**within()** - match by type:
```java
// All methods in a class hierarchy
within(com.example.service..*)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Combining with &&, ||, !**:
```java
// Public methods in service package with @Transactional
execution(public * com.example.service..*.*(..)) &&
@annotation(Transactional)
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

*What separates good from great:* Overly broad pointcut expressions (execution(* *(..)))
have significant performance impact - they intercept every method call.
Always scope pointcuts as narrowly as possible. Profile AOP overhead if you
have broad pointcuts in high-throughput code.

---

**[SENIOR] Q7 - [CONCEPTUAL] How does @Async work with Spring AOP?**

@Async submits the annotated method's execution to a thread pool instead of
running it on the calling thread. Spring AOP creates a proxy that:
1. Intercepts the method call
2. Wraps the method in a Runnable/Callable
3. Submits to the configured AsyncTaskExecutor
4. Returns immediately (void or CompletableFuture to caller)

```java
@Service
public class EmailService {
    @Async  // runs in thread pool
    public CompletableFuture<Boolean> sendEmail(
            String to, String content) {
        // executed in separate thread
        boolean success = smtpClient.send(to, content);
        return CompletableFuture.completedFuture(success);
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

Requirements:
- @EnableAsync on a @Configuration class
- The annotated method must return void or CompletableFuture
- Self-invocation limitation applies (same as @Transactional)

*What separates good from great:* Without a custom TaskExecutor, Spring uses
SimpleAsyncTaskExecutor which creates a new thread per call - no thread pool.
Always configure a bounded ThreadPoolTaskExecutor for @Async in production.
Also: exceptions in @Async void methods are swallowed unless you configure
an AsyncUncaughtExceptionHandler.

---

**[SENIOR] Q8 - [CONCEPTUAL] What is the difference between Spring AOP and AspectJ?**

**Spring AOP:**
- Proxy-based (CGLIB or JDK proxy)
- Intercepts only Spring bean method executions
- Does not work for: self-invocation, constructor calls, field access,
  new object creation, static methods
- No agent or compiler required
- Sufficient for 95% of use cases

**AspectJ:**
- Bytecode weaving (compile-time or load-time)
- Works for ALL Java constructs: self-invocation, constructors, fields, statics
- Requires AspectJ compiler (CTW) or Java agent (LTW)
- More powerful but more complex to configure
- Spring integrates with AspectJ via @EnableLoadTimeWeaving for LTW

Use Spring AOP for: @Transactional, @Async, @Cacheable, custom aspects on
Spring beans.
Use AspectJ for: self-invocation must work, weaving non-Spring objects,
aspect on new object creation.

*What separates good from great:* Spring's @Transactional, @Cacheable, @Async,
@Secured are ALL implemented as Spring AOP aspects. Understanding this means
understanding all their limitations (self-invocation, proxy requirements) from
first principles. You don't need to memorize which limitation applies to which
annotation.

---

**[SENIOR] Q9 - [CONCEPTUAL] How do you order multiple aspects on the same method?**

When multiple aspects apply to the same method, their order is controlled by:

1. **@Order annotation** on the @Aspect class:
   ```java
   @Aspect
   @Component
   @Order(1)  // lower = higher priority (runs first)
   public class SecurityAspect { ... }

   @Aspect
   @Component
   @Order(2)  // runs second
   public class AuditAspect { ... }
   ```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

2. **Ordered interface**: implement org.springframework.core.Ordered.

Order applies as a stack:
- Higher priority aspects wrap lower priority aspects
- @Order(1) preHandle runs before @Order(2) preHandle
- @Order(1) postHandle runs after @Order(2) postHandle
- Think of it as nested try/finally blocks

Default order when not specified: undefined (any order).

*What separates good from great:* Spring Security's @PreAuthorize checks run
in a specific order relative to @Transactional. Security check should happen
OUTSIDE the transaction (unauthorized requests don't open a DB transaction).
Spring Security's MethodSecurityInterceptor has lower order number
(higher priority) than Spring's TransactionInterceptor to ensure this.

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


# @Transactional and Transaction Management

---
id: SPR-017
title: "@Transactional and Transaction Management"
category: Spring
difficulty: ★★☆
interview_weight: critical
asked_at: All
seniority: mid
tags: #spring, #transactional, #transaction, #propagation, #isolation
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - @Transactional is used in every Spring data
application. Questions about propagation, isolation, and rollback rules are
standard interview questions at all levels.

---

### 🎯 Model Answer

**30 seconds:**
> @Transactional demarcates transaction boundaries. Spring opens a transaction
> before the method and commits or rolls back after it. By default, transactions
> roll back on RuntimeException but NOT on checked exceptions. The most important
> attributes are propagation (how to handle an existing transaction) and isolation
> (what concurrent transactions can see). The main pitfall is self-invocation:
> calling a @Transactional method from the same class bypasses the proxy.

**3 minutes (Senior):**
> Propagation defines what happens when a transactional method is called from
> within an existing transaction. REQUIRED (default) joins the existing transaction
> or creates a new one if none exists. REQUIRES_NEW always starts a new transaction,
> suspending the existing one. NESTED creates a savepoint in the existing transaction
> (partial rollback possible). MANDATORY requires an existing transaction and throws
> if none exists.
>
> Isolation defines what concurrent transactions can see. READ_UNCOMMITTED allows
> dirty reads. READ_COMMITTED (PostgreSQL/SQL Server default) prevents dirty reads.
> REPEATABLE_READ (MySQL InnoDB default) prevents dirty and non-repeatable reads.
> SERIALIZABLE prevents all anomalies but has highest contention.
>
> The rollback rule: RuntimeException (unchecked) triggers rollback by default.
> Checked exceptions do NOT trigger rollback by default (historical Servlet
> exception handling reason). Override with rollbackFor = Exception.class if
> you use checked exceptions for errors.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - @TransactionalEventListener for publishing events that
should be committed before delivery, distributed transactions (JTA vs saga patterns).

*Adapting down:* Junior - "@Transactional makes everything in the method happen
in one database transaction. If anything throws, all the changes are rolled back
together."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about @Transactional - what it does and its
key configuration options."

**(2) First principles:** "Transactions ensure atomicity: either all operations
succeed or none are visible. @Transactional is Spring's declarative way to apply
this guarantee to methods."

**(3) Bridge:** "Think of @Transactional as a try/commit/rollback wrapper. It
opens a connection, runs your code, and either commits or rolls back depending
on whether an exception was thrown."

---

### 📘 Concept Explanation

**What it is:**
@Transactional is a Spring annotation that demarcates transactional boundaries.
Spring wraps the annotated method in a transaction - opening, committing, or
rolling back as required.

**The problem it solves:**
Database operations that modify multiple tables must be atomic. Without
transactions, a partial failure leaves the database in an inconsistent state.
Writing try/commit/rollback code for every service method is repetitive and
error-prone. @Transactional externalizes this to the AOP proxy.

**How it works:**

```
@Transactional execution flow:

Without exception (commit path):
  Caller -> proxy.createOrder(req)
    -> TransactionInterceptor opens transaction
       (getConnection(), setAutoCommit(false))
    -> super.createOrder(req) executes
       (queries run in transaction)
    -> No exception: TransactionInterceptor commits
       (connection.commit())
    -> Connection returned to pool

With RuntimeException (rollback path):
  Caller -> proxy.createOrder(req)
    -> TransactionInterceptor opens transaction
    -> super.createOrder(req) throws RuntimeException
    -> TransactionInterceptor catches exception
    -> Rollback: connection.rollback()
    -> Exception re-thrown to caller

With checked Exception (commit by default - SURPRISE):
  Caller -> proxy.createOrder(req)
    -> TransactionInterceptor opens transaction
    -> super.createOrder(req) throws IOException
    -> TransactionInterceptor: IOException is not
       RuntimeException - default does NOT rollback
    -> Transaction COMMITTED even though exception thrown
    -> Exception re-thrown to caller

Fix: @Transactional(rollbackFor = IOException.class)
  OR: @Transactional(rollbackFor = Exception.class)

Propagation (nested transactional calls):
  @Transactional // outer method opens TX
  public void outer() {
      inner(); // what happens to this TX?
  }

  @Transactional(propagation = REQUIRED) // default
  public void inner() {
      // Joins outer TX. Rolls back = outer rolls back too
  }

  @Transactional(propagation = REQUIRES_NEW)
  public void inner() {
      // Suspends outer TX, starts new TX
      // inner rollback DOES NOT roll back outer
  }
```

> **Code walkthrough:** This @Transactional and Transaction Management example demonstrates a key concept in practice using @Transactional. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The default rollback rule - RuntimeException triggers rollback, checked
exception does not - is a historical accident from J2EE patterns. In modern
Java, using checked exceptions for business errors is less common, but if your
domain model throws checked exceptions (InsufficientFundsException extends
Exception), you MUST add rollbackFor = Exception.class or Spring will commit
the partial work even when the exception is thrown.

**When to use it:**
- Any service method that makes multiple database writes
- Read-only queries that span multiple repository calls (readOnly = true)
- Any unit of work that must be atomic

**When NOT to use it:**
- Methods that do no database work (pure computation)
- Private methods (AOP proxy cannot intercept)
- Methods with long processing time (holds DB connections and locks for duration)

**Alternatives:**
- Programmatic transaction management: TransactionTemplate for fine-grained control
- PlatformTransactionManager directly: for complex transaction logic

**First-principles derivation:**
A transaction is a database concept: a sequence of operations that are atomic,
consistent, isolated, and durable (ACID). @Transactional maps the database
transaction lifecycle to the Java method lifecycle. Open when the method starts,
commit when it returns normally, rollback when it throws.

---

### 💻 Code Example

```java
// BAD: incorrect rollback for checked exception
@Service
public class AccountService {
    @Transactional  // will COMMIT on checked exception!
    public void transfer(Long fromId, Long toId,
                        BigDecimal amount)
            throws InsufficientFundsException {
        Account from = accountRepository.findById(fromId)
            .orElseThrow();
        Account to = accountRepository.findById(toId)
            .orElseThrow();

        if (from.getBalance().compareTo(amount) < 0) {
            throw new InsufficientFundsException(
                "Insufficient funds");
            // This is checked - Spring does NOT rollback
            // But we haven't modified anything yet here
        }

        from.debit(amount);   // <-- if this saves
        accountRepository.save(from);

        throw new InsufficientFundsException(...);
        // After debit was saved, throwing checked exc
        // COMMITS the debit! Balance is debited, no credit!
    }
}
```

> **Code walkthrough:** InsufficientFundsException extends Exception (checked).
> Spring's default @Transactional does NOT rollback on checked exceptions.
> In the worst case, if the debit is saved and then a checked exception is
> thrown before the credit saves, the debit is committed with no credit.
> This is a real money loss bug.

```java
// GOOD: explicit rollback for domain exceptions
@Service
public class AccountService {
    // Always roll back on any exception
    @Transactional(rollbackFor = Exception.class)
    public void transfer(Long fromId, Long toId,
                         BigDecimal amount)
            throws InsufficientFundsException {
        Account from = accountRepository.findById(fromId)
            .orElseThrow();
        Account to = accountRepository.findById(toId)
            .orElseThrow();

        if (from.getBalance().compareTo(amount) < 0) {
            throw new InsufficientFundsException(
                "Insufficient balance");
        }

        from.debit(amount);
        to.credit(amount);
        accountRepository.save(from);
        accountRepository.save(to);
        // If any save fails OR if InsufficientFunds thrown,
        // the entire transaction is rolled back
    }
}

// Read-only optimization
@Service
public class ReportService {
    @Transactional(readOnly = true) // Hibernate hint
    public List<OrderSummary> getOrderReport(
            LocalDate from, LocalDate to) {
        // readOnly = true:
        // 1. Hibernate skips dirty checking
        // 2. First-level cache not flushed before queries
        // 3. Database may use read replica routing
        return orderRepository.findSummaries(from, to);
    }
}
```

> **Code walkthrough:** rollbackFor = Exception.class ensures both checked andice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> unchecked exceptions trigger rollback. This is the safe default for any
> transactional method. The readOnly = true flag tells Hibernate to skip dirty
> checking (no flush before queries), which improves performance for read-heavy
> service methods. It is also used by read replica routing datasources to
> direct queries to replicas.

```java
// Propagation examples
@Service
public class OuterService {

    @Transactional // default REQUIRED - opens TX1
    public void processOrder(Order order) {
        orderRepository.save(order);
        try {
            // REQUIRES_NEW suspends TX1, opens TX2
            auditService.recordAudit(order);
            // If recordAudit commits successfully,
            // audit record PERSISTS even if TX1 rolls back
        } catch (Exception e) {
            // TX2 failed, TX1 continues
            log.warn("Audit failed, continuing", e);
        }
        // TX1 commits: order saved (audit may or may not be)
    }
}

@Service
public class AuditService {
    @Transactional(propagation =
        Propagation.REQUIRES_NEW) // always new TX2
    public void recordAudit(Order order) {
        auditRepository.save(new AuditRecord(order));
        // Commits or rolls back INDEPENDENTLY of caller
    }
}
```

> **Code walkthrough:** REQUIRES_NEW is essential for audit logging andice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> notification systems that must persist regardless of the outer transaction's
> outcome. The audit record must survive even if the order transaction rolls
> back - you need to know why the order failed. REQUIRES_NEW starts a completely
> separate transaction with a separate database connection.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> @Transactional wraps a method in a database transaction. All database operations
> in the method run in one transaction. If a RuntimeException is thrown, the
> transaction rolls back and all changes are undone. If it completes normally,
> the transaction commits. Important: checked exceptions (like IOException) do
> not trigger rollback by default - add rollbackFor = Exception.class to be safe.

*Push deeper:* Explain the self-invocation limitation - @Transactional on a
method called from the same class does not work.

---

**Senior / Staff (5+ years):**
> @Transactional is AOP-based: Spring creates a proxy that wraps the method in
> transaction management. Critical attributes: propagation (how existing
> transactions interact - REQUIRED joins or creates, REQUIRES_NEW always creates
> separate), isolation (what concurrent transactions see - DATABASE DEFAULT is
> usually correct), rollbackFor (add Exception.class if using checked exceptions
> for domain errors). @Transactional(readOnly = true) is a Hibernate hint that
> skips dirty checking and enables read replica routing. The self-invocation
> limitation means transactional methods must be called via the injected proxy.
> For distributed transactions across services, @Transactional does NOT span
> service boundaries - use the Saga pattern with compensating transactions.

*Push deeper:* TransactionSynchronizationManager enables registering callbacks
for the current transaction (execute after commit, after rollback). This is
how @TransactionalEventListener works: it registers the event delivery as a
post-commit callback so the event fires only if the transaction commits.

---

### ⚠️ Common Misconceptions

**Misconception 1: "@Transactional rolls back on all exceptions."**
Default: only RuntimeException and Error trigger rollback. Checked exceptions
DO NOT trigger rollback. This is a real source of data corruption bugs when
service methods throw checked exceptions.

**Misconception 2: "@Transactional on the repository method is sufficient."**
Each repository method is in its own transaction (save, findAll each their own).
If your service calls save() and then fails, the save is already committed.
@Transactional on the SERVICE method combines multiple repository calls into
one atomic transaction.

**Misconception 3: "readOnly = true is purely an optimization hint with no
behavioral difference."**
readOnly = true causes Hibernate to skip dirty checking and first-level cache
flush. In applications with multiple DataSource beans (read/write separation),
readOnly = true can trigger routing to the read replica. This is behavioral,
not just advisory.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Partial commit on checked exception**
Symptom: Some writes committed, others not, after a checked exception.
Cause: Default @Transactional does not rollback checked exceptions.
Fix: Add rollbackFor = Exception.class to all @Transactional methods that
can throw checked exceptions.

**Failure 2: Transaction active in unexpected places**
Symptom: Long-running transaction holds locks; database connections exhausted.
Cause: @Transactional method doing I/O (HTTP calls, file reads) while transaction
is open, holding a DB connection for the entire duration.
Fix: Fetch all DB data first, close transaction, then do I/O. Use
TransactionTemplate for fine-grained transaction boundaries.

**Failure 3: Optimistic locking conflict - StaleObjectStateException**
Symptom: "Row was updated or deleted by another transaction" on save.
Cause: Two concurrent transactions both read the same entity, both modify it,
and the second save conflicts with the first.
Diagnosis: Check @Version field on the entity; check the exception type.
Fix: Retry logic for optimistic lock conflicts; or switch to pessimistic locking
for high-contention operations.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What does @Transactional do?**

@Transactional demarcates a transaction boundary. Spring's TransactionInterceptor
(a BeanPostProcessor-created proxy) wraps the annotated method:

1. Before method: begin transaction (open connection, setAutoCommit(false))
2. Method executes (all DB operations in the same connection)
3. Normal return: commit
4. RuntimeException thrown: rollback, re-throw exception
5. Checked exception thrown: commit by default (can be changed with rollbackFor)
6. Connection returned to pool

This ensures atomicity: multiple repository saves in one service method are
one atomic database operation.

*What separates good from great:* @Transactional on a @Service method is the
correct place for transactional boundary. Repository methods have their own
@Transactional, but they each start/commit their own transaction. Without a
service-level transaction, two repository calls in one service method use two
separate transactions.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What are the transaction propagation modes?**

Key propagation values:

- **REQUIRED** (default): join existing transaction; create new if none.
  Most common - service methods join or create.

- **REQUIRES_NEW**: always create a new transaction; suspend existing.
  Use for: audit logging, notifications (must persist independently).

- **SUPPORTS**: join existing transaction if present; no transaction if not.
  Use for: read operations that work in or out of a transaction.

- **MANDATORY**: must have existing transaction; throws if none.
  Use for: methods that should never be called without a transaction context.

- **NOT_SUPPORTED**: execute without transaction; suspend existing.
  Use for: bulk operations where transaction overhead is not worth it.

- **NEVER**: must NOT have a transaction; throws if one exists.

- **NESTED**: create a savepoint in the existing transaction.
  Nested rollback only rolls back to savepoint, not entire transaction.
  Only supported by some databases and JDBC drivers.

*What separates good from great:* REQUIRES_NEW creates a separate database
connection. In high-throughput systems, too many REQUIRES_NEW calls can
exhaust the connection pool. NESTED uses savepoints on the same connection,
which is more efficient but has limited database support.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What is the default rollback behavior and how do you change it?**

Default: rollback on RuntimeException (unchecked) and Error.
Default: NO rollback on checked Exception.

To change:
```java
// Roll back on ALL exceptions
@Transactional(rollbackFor = Exception.class)

// Roll back on specific checked exception
@Transactional(rollbackFor = MyCheckedException.class)

// Don't roll back on specific runtime exception
@Transactional(
    noRollbackFor = OptimisticLockingException.class)
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

Recommendation: always use rollbackFor = Exception.class if your service
methods throw or propagate checked exceptions.

*What separates good from great:* The "checked exceptions don't roll back"
default comes from J2EE history where checked exceptions indicated "expected
business errors" that were handled gracefully. Modern Spring convention uses
RuntimeException for domain errors and checked exceptions for external I/O.
The default works with this convention, but mixing checked exceptions with
domain errors requires explicit rollbackFor.

---

**[MID] Q4 - [CONCEPTUAL] What is transaction isolation and what are the levels?**

Isolation defines what concurrent transactions can see from each other's
uncommitted work.

Anomalies that isolation levels prevent:
- **Dirty read**: reading uncommitted data from another transaction
- **Non-repeatable read**: same row read twice returns different values
  (another transaction committed a change between reads)
- **Phantom read**: same query returns different rows (another transaction
  inserted/deleted rows)

Isolation levels:

| Level | Dirty Read | Non-Repeatable | Phantom |
|---|---|---|---|
| READ_UNCOMMITTED | Possible | Possible | Possible |
| READ_COMMITTED | Prevented | Possible | Possible |
| REPEATABLE_READ | Prevented | Prevented | Possible |
| SERIALIZABLE | Prevented | Prevented | Prevented |

Higher isolation = fewer anomalies = more contention = lower throughput.

Database defaults: PostgreSQL = READ_COMMITTED, MySQL InnoDB = REPEATABLE_READ.
Spring default = DEFAULT (use database default).

*What separates good from great:* PostgreSQL uses MVCC for REPEATABLE_READ
and SERIALIZABLE - readers don't block writers. This means READ_COMMITTED is
almost always appropriate. READ_UNCOMMITTED is rarely useful in production
(reads uncommitted data from other transactions - too risky).

---

**[MID] Q5 - [CONCEPTUAL] How does @Transactional(readOnly = true) affect behavior?**

readOnly = true sets a hint on the transaction:

1. **Hibernate flush mode**: set to FlushMode.NEVER or FlushMode.MANUAL.
   Hibernate skips dirty checking (no flush before queries). Dirty checking
   scans all loaded entities for changes - skipping it is a performance win
   for read-heavy methods with large entity graphs.

2. **Connection hint**: some JDBC drivers and connection pools (via
   ReadOnlyAwareDataSourceRouter) use the hint to route to read replicas.

3. **No optimization for non-Hibernate code**: JdbcTemplate ignores readOnly.

When to use: service methods that only read data, no writes. Makes the intent
explicit and gets a performance benefit from Hibernate.

*What separates good from great:* Read replica routing with @Transactional
(readOnly = true) is a common pattern for scaling read traffic. AbstractRoutingDataSource
or LazyConnectionDataSourceProxy inspect the readOnly flag and route to the
appropriate DataSource. This requires no code changes in the service layer - only
DataSource configuration changes.

---

**[MID] Q6 - [CONCEPTUAL] What is @TransactionalEventListener?**

@TransactionalEventListener publishes Spring application events AFTER the
current transaction commits. Contrast with @EventListener which fires immediately.

Use case: send email notification after order creation:

```java
// BAD: calling @Transactional method from same class
// Spring proxy is bypassed - no transaction started
public void processOrder(Order order) {
    saveOrder(order); // self-call bypasses proxy
}
@Transactional
public void saveOrder(Order order) { /* ... */ }
```

```java
// BAD: @EventListener fires BEFORE transaction commits
// Email sent even if order save fails and rolls back
@EventListener
public void onOrderCreated(OrderCreatedEvent event) {
    emailService.sendConfirmation(event.getOrder());
}

// GOOD: fires only after transaction commits
@TransactionalEventListener(
    phase = TransactionPhase.AFTER_COMMIT)
public void onOrderCreated(OrderCreatedEvent event) {
    emailService.sendConfirmation(event.getOrder());
    // Order is committed - safe to notify customer
}
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **WHAT BREAKS: never self-invoke @Transactional methods; inject the bean instead.**

TransactionPhase options:
- AFTER_COMMIT (default): fires if transaction committed
- AFTER_ROLLBACK: fires if transaction rolled back
- AFTER_COMPLETION: fires regardless
- BEFORE_COMMIT: fires before commit (within the transaction)

*What separates good from great:* @TransactionalEventListener AFTER_COMMIT
fires outside the transaction. If the email service throws, the exception does
not roll back the order (transaction already committed). Design your event
listeners to be idempotent and handle failures independently (retry queue).

---

**[SENIOR] Q7 - [CONCEPTUAL] How do you handle transactions programmatically?**

TransactionTemplate for programmatic control:
```java
@Service
public class OrderService {
    private final TransactionTemplate txTemplate;

    public OrderService(
            PlatformTransactionManager txManager) {
        this.txTemplate = new TransactionTemplate(
            txManager);
        txTemplate.setIsolationLevel(
            TransactionDefinition.ISOLATION_READ_COMMITTED);
    }

    public Order createOrder(OrderRequest req) {
        return txTemplate.execute(status -> {
            Order order = orderRepository.save(
                new Order(req));
            paymentRepository.save(
                new Payment(order));
            return order;
            // Automatically commits or rolls back
        });
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

When to use programmatic over declarative:
- Fine-grained control over transaction boundaries within a method
- Conditional transaction creation
- The transactional boundary is not at the method level

*What separates good from great:* TransactionTemplate.execute() returns the
result of the lambda. TransactionTemplate.executeWithoutResult() is for void
operations. The status parameter lets you manually mark the transaction for
rollback: status.setRollbackOnly() without throwing an exception.

---

**[SENIOR] Q8 - [CONCEPTUAL] What is optimistic vs pessimistic locking in JPA?**

**Optimistic locking** (@Version on entity field):
- No database lock held
- Entity has a @Version field (incrementing number or timestamp)
- On save: UPDATE ... WHERE id = ? AND version = ?
- If another transaction incremented version: UPDATE affects 0 rows
- JPA detects 0 rows updated: throws OptimisticLockingException
- Cost: exception on conflict; retry required
- Best for: low-contention resources, high-throughput systems

**Pessimistic locking** (@Lock annotation):
- Database row lock held for the transaction duration

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
Optional<Account> findById(Long id);
```

> **Code walkthrough:** `@Lock(PESSIMISTIC_WRITE)` annotates aice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Spring Data repository method to issue `SELECT ... FOR UPDATE`.
> The database row lock is held until the transaction commits,
> blocking concurrent writers entirely. This prevents phantom
> reads and lost updates but reduces throughput under contention.
> Use only for high-conflict resources like account balances where
> optimistic lock retries would loop indefinitely.

- SELECT ... FOR UPDATE: blocks other writes until lock released
- No conflicts possible, but lower throughput
- Best for: high-contention resources (account balances), guarantee-critical

Optimistic is default and preferred. Pessimistic for financial accounts,
inventory counts where conflicts would be costly.

*What separates good from great:* Optimistic locking requires retry logic in the
service layer. A failed optimistic lock should be retried, not surfaced to the
user as a 500 error. Spring Retry (@Retryable(OptimisticLockingFailureException.class))
adds automatic retry with configurable backoff.

---

**[SENIOR] Q9 - [CONCEPTUAL] How does @Transactional interact with Spring Data JPA?**

Spring Data JPA's SimpleJpaRepository:
- All write methods (save, delete) are @Transactional (read-write)
- All read methods (findAll, findById) are @Transactional(readOnly = true)

When you call orderRepository.save() from a non-transactional service:
- SimpleJpaRepository.save() opens its own transaction, commits, returns

When you call orderRepository.save() from a @Transactional service:
- SimpleJpaRepository.save() sees the existing transaction (REQUIRED propagation)
- Joins the existing transaction
- The commit happens when the service method returns

This is why @Transactional on the service method is essential for atomicity:
individual repository calls have their own transactions by default. The service
@Transactional wraps them all in one outer transaction.

*What separates good from great:* @Transactional(readOnly = true) on a service
method that calls multiple repository find methods is both a performance
optimization and a consistency guarantee. All reads in the method see a
consistent snapshot (no phantom reads within the read-only transaction scope).

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



