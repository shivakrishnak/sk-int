---
layout: default
title: "Spring - L2 Injection and MVC"
parent: "Spring"
nav_order: 5
permalink: /spring/l2-injection-and-mvc/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Spring - L2 Injection and MVC](#spring---l2-injection-and-mvc) | medium |
| 2 | [@Autowired and Injection Types](#autowired-and-injection-types) | medium |
| 3 | [Spring MVC Request Lifecycle](#spring-mvc-request-lifecycle) | medium |

---

# @Autowired and Injection Types

---
id: SPR-012
title: "@Autowired and Injection Types"
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #spring, #autowired, #dependency-injection, #constructor-injection
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - "Constructor vs field injection" is a standard
mid-level Spring interview question with a clear right answer.

---

### 🎯 Model Answer

**30 seconds:**
> Spring supports three injection types: constructor injection, setter injection,
> and field injection. Constructor injection is the recommended approach: it
> makes dependencies mandatory, immutable (final fields), and testable without
> a Spring container. Field injection with @Autowired is the most common in
> legacy code but is discouraged because it hides dependencies, prevents final
> fields, and requires Spring to run tests.

**3 minutes (Senior):**
> Constructor injection wins on all quality dimensions. Dependencies are declared
> as final fields set once via the constructor - they cannot be null, cannot
> change, and are explicit. Testing is clean: `new OrderService(mockRepo, mockPayment)`.
> No Spring context needed. The constructor makes the dependency contract visible.
>
> Field injection with @Autowired uses reflection to set private fields after
> object construction. The object appears constructed (constructor returned) but
> is actually in an incomplete state until Spring finishes injection. You cannot
> write `new OrderService()` in a test and have it work - the private fields
> remain null. You either need Spring context or use Mockito's @InjectMocks.
>
> Setter injection is for optional dependencies - it allows re-injection after
> construction. Rarely used in modern Spring. If you have optional dependencies,
> prefer @Autowired(required = false) on a constructor parameter or use
> Optional<DependencyType> in the constructor.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - circular dependency handling (constructor injection
prevents circular deps at compile/startup time rather than runtime), and
@Primary/@Qualifier resolution strategies.

*Adapting down:* Junior - "Always use constructor injection. It looks like
a regular Java constructor, works without Spring in tests, and forces you
to declare what your class needs up front."

**Blank Mind Recovery:**

**(1) Restate:** "You are comparing constructor injection vs field injection
in Spring."

**(2) First principles:** "Dependencies must be provided somehow. Constructor
is the Java-standard way. Field injection is Spring-specific reflection magic."

**(3) Bridge:** "Constructor injection is like a function signature - parameters
are explicit and required. Field injection is like a function with global
variables - hidden dependencies."

---

### 📘 Concept Explanation

**What it is:**
Dependency injection in Spring can be performed via constructor, setter methods,
or direct field assignment. The mechanism differs in how Spring provides the
dependency to the bean.

**The problem it solves:**
Classes need their dependencies. The question is how to provide them: compile-
time explicit contracts (constructor) or runtime reflection injection (field).
The choice has major implications for testability, immutability, and clarity.

**How it works:**

```
Three injection mechanisms:

1. CONSTRUCTOR INJECTION (recommended)
   Spring calls the constructor with dependencies
   If single constructor: @Autowired optional (Spring 4.3+)

   @Service
   public class OrderService {
       private final OrderRepository repo;  // final!
       private final PaymentService payment;

       public OrderService(OrderRepository repo,
                          PaymentService payment) {
           this.repo = repo;
           this.payment = payment;
       }
   }

2. SETTER INJECTION (optional dependencies)
   Spring calls setter after construction

   @Service
   public class OrderService {
       private EmailService emailService; // optional

       @Autowired(required = false)
       public void setEmailService(
               EmailService emailService) {
           this.emailService = emailService;
       }
   }

3. FIELD INJECTION (legacy/discouraged)
   Spring uses reflection to set private fields

   @Service
   public class OrderService {
       @Autowired  // sets field via reflection
       private OrderRepository repo; // cannot be final!
   }
```

> **Code walkthrough:** This @Autowired and Injection Types example demonstrates null-safe value wrapping using Spring annotation. **KEY MECHANISM:** Optional.of() throws NPE on null; Optional.ofNullable() wraps null safely. **WHY IT MATTERS:** calling get() without isPresent() check produces NoSuchElementException. **TAKEAWAY: prefer orElseThrow() with a meaningful message over bare get().**

**The key insight:**
Constructor injection makes the dependency graph explicit and verifiable. If a
required dependency is missing, you get a compile error or a clear startup
failure. With field injection, a missing dependency manifests as NullPointerException
at runtime, often deep in the call stack.

**When to use it:**
- Constructor injection: always, for all required dependencies
- Setter injection: optional dependencies that can be changed after creation
- Field injection: never in new code; tolerate in legacy until refactored

**When NOT to use it:**
- Do not use field injection in new code
- Do not use setter injection for required dependencies

**Alternatives:**
- @Resource (JSR-250): similar to @Autowired but matches by name first
- @Inject (JSR-330 / Jakarta): equivalent to @Autowired (no required=false)

**First-principles derivation:**
A class with hidden dependencies (field injection) is harder to reason about
than one with explicit dependencies (constructor). The single-responsibility
principle and testability principle both push toward constructor injection -
explicit contracts, testable without infrastructure.

---

### 💻 Code Example

```java
// BAD: field injection - hidden dependencies, untestable
@Service
public class OrderService {
    @Autowired
    private OrderRepository orderRepository; // hidden dep

    @Autowired
    private PaymentService paymentService;   // hidden dep

    @Autowired
    private EmailService emailService;       // hidden dep

    public Order createOrder(OrderRequest req) {
        // What are this class's dependencies?
        // You have to read every field to know.
        Order order = orderRepository.save(
            new Order(req));
        paymentService.charge(order);
        emailService.send(order.getCustomerEmail());
        return order;
    }
}
// Problem 1: Untestable without Spring
// new OrderService() -> all fields null -> NPE
// Problem 2: Fields cannot be final
// Problem 3: Dependencies hidden - not in constructor
```

> **Code walkthrough:** Field injection hides the dependency contract. A developerice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> reading only the class signature sees no dependencies - they must inspect all
> fields. Testing requires either starting a Spring context or using Mockito
> @InjectMocks which injects via reflection. Neither is clean. The fields cannot
> be declared final, so they could theoretically be replaced at runtime.

```java
// GOOD: constructor injection - explicit, immutable, testable
@Service
public class OrderService {
    // Dependencies are final - set once, never change
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final EmailService emailService;

    // All dependencies explicit in constructor signature
    // Spring 4.3+: no @Autowired needed if single constructor
    public OrderService(
            OrderRepository orderRepository,
            PaymentService paymentService,
            EmailService emailService) {
        this.orderRepository = Objects.requireNonNull(
            orderRepository,
            "orderRepository required");
        this.paymentService = Objects.requireNonNull(
            paymentService,
            "paymentService required");
        this.emailService = Objects.requireNonNull(
            emailService,
            "emailService required");
    }

    public Order createOrder(OrderRequest req) {
        Order order = orderRepository.save(
            new Order(req));
        paymentService.charge(order);
        emailService.send(order.getCustomerEmail());
        return order;
    }
}

// Clean unit test - no Spring context!
class OrderServiceTest {
    @Test
    void createOrder_chargesPayment() {
        var repo = mock(OrderRepository.class);
        var payment = mock(PaymentService.class);
        var email = mock(EmailService.class);

        var service = new OrderService(
            repo, payment, email); // simple construction

        when(repo.save(any())).thenReturn(testOrder());
        service.createOrder(testRequest());
        verify(payment).charge(any());
    }
}
```

> **Code walkthrough:** Constructor injection makes dependencies visible inice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> the constructor signature - a contract reviewable at a glance. Fields are
> final, guaranteeing immutability after construction. Unit testing requires
> no Spring infrastructure - just `new OrderService(mock, mock, mock)`. The
> Objects.requireNonNull calls provide instant failure with a clear message if
> Spring fails to provide a dependency (defensive programming).

```java
// @Qualifier and @Primary for multiple bean candidates
@Service
public class ReportService {
    private final DataSource primaryDs;
    private final DataSource readReplicaDs;

    public ReportService(
            @Qualifier("primaryDataSource")
            DataSource primaryDs,
            @Qualifier("readReplicaDataSource")
            DataSource readReplicaDs) {
        this.primaryDs = primaryDs;
        this.readReplicaDs = readReplicaDs;
    }
}

// Defining beans with qualifiers
@Configuration
public class DataSourceConfig {
    @Bean("primaryDataSource")
    @Primary  // default when no qualifier specified
    public DataSource primary() { /* ... */ return null; }

    @Bean("readReplicaDataSource")
    public DataSource readReplica() {
        /* ... */ return null;
    }
}
```

> **Code walkthrough:** When multiple beans of the same type exist, Springice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> requires disambiguation. @Qualifier on the injection point selects by bean name.
> @Primary marks the default bean when no qualifier is specified. The bean name
> defaults to the @Bean method name. This pattern is common for read/write
> database separation.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring can inject dependencies three ways: constructor (recommended), setter,
> and field. Constructor injection is best because dependencies are clearly
> declared in the constructor, fields can be final, and you can test without
> Spring by just calling the constructor with mocks. Field injection is convenient
> but makes testing harder and hides dependencies.

*Push deeper:* Explain circular dependency handling - constructor injection
detects circular dependencies at startup; field injection allows them but is
often a sign of poor design.

---

**Senior / Staff (5+ years):**
> Constructor injection enforces the object's contract: all required dependencies
> are explicit, final, and checked at construction. Circular dependencies with
> constructor injection fail at context startup with a clear error
> (BeanCurrentlyInCreationException), which is better than silent runtime failures.
> Field injection allows circular dependencies (Spring breaks them with early
> references), which often indicates a design problem worth fixing. @Primary and
> @Qualifier resolve ambiguity when multiple beans of the same type exist;
> @Primary designates the default, @Qualifier provides specific selection.

*Push deeper:* @Lazy on a constructor parameter breaks circular dependencies
without field injection - Spring creates a proxy for the lazy dependency,
breaking the cycle. This is a legitimate use case.

---

### ⚠️ Common Misconceptions

**Misconception 1: "@Autowired is required for injection."**
Since Spring 4.3, if a class has a single constructor, Spring uses it for
injection without @Autowired. This is the standard for modern Spring code.
@Autowired is only needed for multiple constructors or field injection.

**Misconception 2: "Field injection is simpler than constructor injection."**
Field injection creates maintenance debt. Tests require Spring context or
reflection-based injection (@InjectMocks). The "simplicity" is the immediate
simplicity of not writing a constructor - the cost comes at test time and
when debugging null injection failures.

**Misconception 3: "Spring automatically resolves multiple beans of the same type."**
When multiple beans of the same type exist, Spring throws
NoUniqueBeanDefinitionException unless you provide @Primary or @Qualifier.
This is intentional - implicit resolution of ambiguous beans causes hard-to-debug
bugs.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: NoUniqueBeanDefinitionException**
Symptom: "No qualifying bean of type 'DataSource': expected single matching
bean but found 2."
Cause: Multiple beans of the same type, no @Primary or @Qualifier.
Fix: Add @Primary to the default bean or @Qualifier at the injection point.

**Failure 2: BeanCurrentlyInCreationException (circular dependency)**
Symptom: "The dependencies of some of the beans form a cycle:
ServiceA -> ServiceB -> ServiceA"
Cause: Circular constructor injection.
Fix: Redesign to break the cycle. If not possible, use @Lazy on one injection
point or restructure to extract shared functionality into a third service.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What are the three types of dependency injection in Spring?**

1. **Constructor injection**: dependencies provided via constructor parameters.
   Spring calls the constructor. Recommended for all required dependencies.

2. **Setter injection**: dependencies provided via setter methods annotated
   with @Autowired. For optional dependencies that can be changed post-construction.

3. **Field injection**: dependencies injected directly into fields via reflection.
   @Autowired on a field. Convenient but discouraged for new code.

*What separates good from great:* Spring also supports method injection
(@Lookup) for prototype beans, and @ConfigurationProperties which binds
properties to POJOs. These are specialised injection forms.

---

**[JUNIOR] Q2 - [TRADE-OFF] Why is constructor injection preferred over field injection?**

Constructor injection advantages:
1. **Immutability**: fields can be final - set once, never changed.
2. **Explicitness**: all dependencies visible in constructor signature.
3. **Testability**: `new Service(mockDep1, mockDep2)` - no Spring needed.
4. **Null safety**: constructors can validate and throw if dep is null.
5. **Circular detection**: circular constructor deps fail at startup.
6. **No reflection**: Spring calls the constructor normally.

Field injection disadvantages:
1. Fields cannot be final.
2. Object is in partially constructed state between constructor and injection.
3. Testing requires Spring context or reflection.
4. Circular dependencies silently allowed.

*What separates good from great:* The "partially constructed state" issue is
subtle. Between the constructor returning and Spring finishing field injection,
the object exists with null fields. Constructor injection eliminates this window.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How does @Qualifier work and when do you use it?**

@Qualifier specifies which bean to inject when multiple beans of the same
type are available.

```java
@Bean("primary")
@Primary
public DataSource primaryDataSource() { /* ... */ }

@Bean("replica")
public DataSource replicaDataSource() { /* ... */ }

// Gets replicaDataSource specifically
@Service
public class ReportService {
    public ReportService(
            @Qualifier("replica") DataSource ds) {
        /* ... */
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

@Primary marks the default: if no @Qualifier is specified, the @Primary bean
is chosen. @Qualifier overrides @Primary.

Custom qualifier annotations: create your own annotation meta-annotated with
@Qualifier for type-safe qualification without string names.

*What separates good from great:* Creating custom qualifier annotations is
cleaner than string qualifiers because they are refactor-safe.

---

**[MID] Q4 - [CONCEPTUAL] How do you handle optional dependencies in Spring?**

Three approaches:

1. **@Autowired(required = false) on setter**:
   ```java
   @Autowired(required = false)
   public void setEmailService(EmailService s) {
       this.emailService = s;
   }
   ```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

2. **Optional<T> constructor parameter**:
   ```java
   public MyService(Optional<EmailService> email) {
       this.emailService = email.orElse(null);
   }
   ```

> **Code walkthrough:** This Unknown example demonstrates null-safe value wrapping. **KEY MECHANISM:** Optional.of() throws NPE on null; Optional.ofNullable() wraps null safely. **WHY IT MATTERS:** calling get() without isPresent() check produces NoSuchElementException. **TAKEAWAY: prefer orElseThrow() with a meaningful message over bare get().**

3. **@Autowired(required = false) on field** (avoid in new code):
   ```java
   @Autowired(required = false)
   private EmailService emailService; // null if no bean
   ```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Best approach for new code: constructor with Optional<T> parameter.
It makes the optionality explicit in the class contract.

*What separates good from great:* Optional<T> in constructor makes the
optionality explicit - a developer reading the constructor immediately knows
EmailService is optional.

---

**[MID] Q5 - [CONCEPTUAL] What is @Primary and when do you use it?**

@Primary marks a bean as the default candidate when multiple beans of the
same type exist and no @Qualifier is specified.

Use case: primary DataSource and read-replica DataSource. Most code uses
primary. Annotate primary bean with @Primary. Code needing replica qualifies
with @Qualifier("replica").

@Primary has implications for auto-configuration: defining a @Primary DataSource
causes DataSourceAutoConfiguration to skip (ConditionalOnMissingBean). This
is the correct way to override auto-configured beans.

*What separates good from great:* @Primary is the override mechanism for
auto-configuration beans without explicit exclusion.

---

**[MID] Q6 - [CONCEPTUAL] How does Spring resolve injection when multiple beans exist?**

Resolution order:
1. **Type match**: find all beans of the required type.
2. **@Primary**: if exactly one @Primary bean, use it.
3. **@Qualifier**: if injection point has @Qualifier, use matching name.
4. **Name match**: if field/parameter name matches a bean name, use it.
5. **NoUniqueBeanDefinitionException**: if none resolve uniquely.

The name-match fallback is fragile. Changing a bean name can break injection
points relying on name matching. Always use @Qualifier explicitly when choosing
from multiple candidates.

*What separates good from great:* Implicit name matching is a fallback, not
a design strategy. Use @Qualifier for self-documenting, refactor-safe injection.

---

**[SENIOR] Q7 - [CONCEPTUAL] How do you break a circular dependency in Spring?**

A circular dependency is usually a design problem. Correct fix: redesign.

If needed:
1. **Extract shared functionality** into a third service C (best solution).
2. **@Lazy on one injection point**:
   ```java
   @Service
   public class ServiceA {
       public ServiceA(@Lazy ServiceB b) { /* ... */ }
   }
   ```
> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

   Spring creates a proxy for ServiceB, breaking the constructor cycle.

3. **Setter/field injection on one side**: Spring uses early bean references.
   Not recommended - the design issue remains.

Spring Boot 2.6+: circular dependencies disallowed by default
(spring.main.allow-circular-references=false). Fix the design.

*What separates good from great:* @Lazy is legitimate when the circular
dependency is inherent to the domain model and refactoring is not feasible.

---

**[SENIOR] Q8 - [CONCEPTUAL] What is the difference between @Autowired, @Resource, and @Inject?**

**@Autowired (Spring):**
- Resolves by type first, then name
- Supports required=false
- Spring-specific

**@Resource (JSR-250 / Jakarta):**
- Resolves by name first, then type
- name attribute specifies explicit name
- Standard Java annotation

**@Inject (JSR-330 / Jakarta):**
- Resolves by type (same as @Autowired)
- No required equivalent - always required
- Standard Java annotation

Recommendation: use @Autowired for consistency in Spring applications.
Use @Inject/@Resource if minimizing Spring coupling is a goal.

*What separates good from great:* JSR-330 annotations allow classes to be
portable between Spring and Jakarta EE/CDI containers.

---

**[SENIOR] Q9 - [CONCEPTUAL] How does constructor injection work with Lombok?**

@RequiredArgsConstructor generates a constructor for all final fields:

```java
@Service
@RequiredArgsConstructor  // generates constructor
public class OrderService {
    private final OrderRepository repo;
    private final PaymentService payment;
    // Lombok generates:
    // public OrderService(OrderRepository repo,
    //                     PaymentService payment) { ... }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Spring 4.3+ finds the single generated constructor and uses it without
@Autowired. @RequiredArgsConstructor + @NonNull adds null checks in the
generated constructor.

*What separates good from great:* @RequiredArgsConstructor with @NonNull on
fields adds null safety without the boilerplate of manual Objects.requireNonNull.

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


# Spring MVC Request Lifecycle

---
id: SPR-013
title: Spring MVC Request Lifecycle
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #spring-mvc, #dispatcherservlet, #handlermap, #interceptor
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - understanding DispatcherServlet and the request
processing pipeline demonstrates real Spring MVC knowledge beyond basic
@RequestMapping.

---

### 🎯 Model Answer

**30 seconds:**
> Every HTTP request in Spring MVC goes through DispatcherServlet - the front
> controller. It consults HandlerMapping to find which controller method handles
> the request, uses HandlerAdapter to invoke it, and uses ViewResolver or
> HttpMessageConverter to render the response. The full pipeline is:
> DispatcherServlet -> HandlerMapping -> HandlerInterceptors (pre) ->
> HandlerAdapter -> your @Controller -> HandlerInterceptors (post) -> Response.

**3 minutes (Senior):**
> DispatcherServlet is a single servlet registered in the servlet container.
> All requests to your application flow through it - this is the Front Controller
> pattern.
>
> HandlerMapping maps incoming requests to handler objects - typically
> @Controller methods via RequestMappingHandlerMapping. HandlerAdapter bridges
> the gap between the generic Handler object and the actual invocation - it
> knows how to call a method annotated with @RequestMapping.
>
> HandlerInterceptors are executed before and after the handler. They are the
> right place for cross-cutting concerns: authentication checks, logging,
> performance metrics. Different from Servlet filters - interceptors have access
> to Spring MVC context (handler method, model).
>
> @ExceptionHandler methods in @ControllerAdvice classes are resolved by
> HandlerExceptionResolver. When a controller throws, the exception resolver
> finds the matching @ExceptionHandler and invokes it instead.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - discuss custom HandlerMethodArgumentResolver for binding
custom request data, or custom HandlerInterceptor for distributed tracing.

*Adapting down:* Junior - "When a request arrives, Spring's DispatcherServlet
finds the right controller method using HandlerMapping, calls it, and sends back
the response. It is the central traffic director for all web requests."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking how Spring MVC processes an HTTP request from
arrival to response."

**(2) First principles:** "A web framework needs to map incoming requests to
code, execute that code, and render the result. Each of those steps has a
Spring component."

**(3) Bridge:** "Think of an airport: the dispatcher (DispatcherServlet) receives
all flights, the routing system (HandlerMapping) assigns gates, ground crew
(HandlerAdapter) manages the work, customs (Interceptors) checks passengers."

---

### 📘 Concept Explanation

**What it is:**
Spring MVC processes HTTP requests through a pipeline of components coordinated
by DispatcherServlet. Understanding this pipeline enables writing correct
interceptors, exception handlers, and custom argument resolvers.

**The problem it solves:**
Without a standard request processing pipeline, each web framework component
(authentication, routing, validation, rendering) would need to be combined
manually and inconsistently. The Front Controller pattern with a defined pipeline
gives a consistent, extensible, well-ordered processing chain.

**How it works:**

```
Spring MVC Request Lifecycle:

HTTP Request
     |
     v
[Servlet Container] (Tomcat/Jetty)
     |
     v
[DispatcherServlet] <-- registered as servlet
     |
     v
[HandlerMapping]
  Matches URL + method to HandlerExecutionChain
  Chain = handler method + interceptors
     |
     v
[HandlerInterceptor.preHandle()]
  Can veto request (return false)
  Auth check, rate limit, logging
     |
     v
[HandlerAdapter]
  Resolves @RequestParam, @PathVariable,
  @RequestBody params
  Calls your @Controller method
  Converts @ResponseBody via HttpMessageConverter
     |
     v
[Your @Controller method executes]
     |
     v
[HandlerInterceptor.postHandle()]
  Access to ModelAndView
  Can add model attributes
     |
     v
[ViewResolver] OR [HttpMessageConverter]
  ViewResolver: resolves view name to template
  MessageConverter: JSON/XML serialization
     |
     v
[HandlerInterceptor.afterCompletion()]
  Always called (even on exception)
  Cleanup: log response time, release resources
     |
     v
HTTP Response

On Exception -> [HandlerExceptionResolver]
  ExceptionHandlerExceptionResolver: @ExceptionHandler
  ResponseStatusExceptionResolver: @ResponseStatus
  DefaultHandlerExceptionResolver: Spring defaults
```

> **Code walkthrough:** This Spring MVC Request Lifecycle example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
HandlerInterceptors run inside the DispatcherServlet context - they have access
to the handler method and Spring MVC abstractions. Servlet Filters run outside
DispatcherServlet - they operate on raw HttpServletRequest/Response with no
MVC awareness. For MVC-specific cross-cutting concerns, interceptors are better.
For raw request manipulation (CORS headers, request wrapping), filters are better.

**When to use it:**
- HandlerInterceptor: authentication/authorization based on Spring context,
  request logging with controller info, performance metrics
- @ControllerAdvice + @ExceptionHandler: centralised exception handling
- Custom HandlerMethodArgumentResolver: binding custom request data

**When NOT to use it:**
- Do not use HandlerInterceptor for CORS or security headers - use Servlet Filters
- Do not use HandlerInterceptors for response body transformation - use
  ResponseBodyAdvice

**Alternatives:**
- Servlet Filter: for non-MVC request processing (raw HTTP manipulation)
- @ControllerAdvice: for response modification and exception handling
- AOP: for cross-cutting concerns on service layer (not HTTP-specific)

**First-principles derivation:**
Every MVC framework needs routing, execution, and rendering. Spring MVC
externalizes each step as an interface: HandlerMapping (routing), HandlerAdapter
(execution), ViewResolver/MessageConverter (rendering). Each step is replaceable.

---

### 💻 Code Example

```java
// Custom HandlerInterceptor for request timing
@Component
public class RequestLoggingInterceptor
        implements HandlerInterceptor {

    private static final String START_TIME =
        "request.startTime";

    @Override
    public boolean preHandle(
            HttpServletRequest req,
            HttpServletResponse resp,
            Object handler) {
        req.setAttribute(START_TIME,
            System.currentTimeMillis());
        if (handler instanceof HandlerMethod method) {
            log.info("Request: {} {} -> {}.{}",
                req.getMethod(),
                req.getRequestURI(),
                method.getBeanType().getSimpleName(),
                method.getMethod().getName());
        }
        return true; // continue processing
    }

    @Override
    public void afterCompletion(
            HttpServletRequest req,
            HttpServletResponse resp,
            Object handler, Exception ex) {
        Long start = (Long) req.getAttribute(START_TIME);
        long ms = System.currentTimeMillis() - start;
        log.info("Response: {} {}ms status={}",
            req.getRequestURI(), ms, resp.getStatus());
    }
}

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
    private final RequestLoggingInterceptor interceptor;

    public WebMvcConfig(
            RequestLoggingInterceptor interceptor) {
        this.interceptor = interceptor;
    }

    @Override
    public void addInterceptors(
            InterceptorRegistry registry) {
        registry.addInterceptor(interceptor)
            .addPathPatterns("/api/**")
            .excludePathPatterns("/actuator/**");
    }
}
```

> **Code walkthrough:** A practical timing and logging interceptor. preHandleice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> stores the start time in the request and logs which controller method handles
> it. afterCompletion calculates duration and logs the response status.
> afterCompletion is guaranteed to run even if the handler throws, making it
> safe for cleanup. Registered via WebMvcConfigurer with path pattern filtering.

```java
// Centralised exception handling with @ControllerAdvice
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(
        MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleValidation(
            MethodArgumentNotValidException ex) {
        List<String> errors = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .map(e -> e.getField() + ": " +
                      e.getDefaultMessage())
            .toList();
        return new ErrorResponse(
            "VALIDATION_FAILED", errors);
    }

    @ExceptionHandler(EntityNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handleNotFound(
            EntityNotFoundException ex) {
        return new ErrorResponse(
            "NOT_FOUND", ex.getMessage());
    }

    // Catch-all - do NOT expose stack trace to clients
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ErrorResponse handleAll(Exception ex) {
        log.error("Unhandled exception", ex);
        return new ErrorResponse(
            "INTERNAL_ERROR",
            "An unexpected error occurred");
    }
}

record ErrorResponse(String code, Object details) {}
```

> **Code walkthrough:** @RestControllerAdvice combines @ControllerAdvice andice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> @ResponseBody - all methods serialize to JSON automatically. Three handlers
> cover: validation errors (400), domain not-found (404), and catch-all (500).
> The catch-all logs for ops visibility while returning a generic message -
> never expose stack traces to clients, as this is a security vulnerability
> (information disclosure).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> When a request arrives, DispatcherServlet is the entry point. It uses
> HandlerMapping to find which @RequestMapping controller method handles the
> request. The controller method runs, returns data or a view name, and
> DispatcherServlet renders the response. HandlerInterceptors run before and
> after the controller, like security checks or logging.

*Push deeper:* Explain the difference between @Controller (returns view names)
and @RestController (returns JSON via @ResponseBody on all methods).

---

**Senior / Staff (5+ years):**
> DispatcherServlet is a Front Controller - one entry point for all requests.
> The pipeline is configurable: HandlerMapping (routing), HandlerAdapter
> (invocation), HandlerInterceptors (cross-cutting), HandlerExceptionResolvers
> (error handling), ViewResolvers/MessageConverters (rendering). HandlerInterceptors
> vs Servlet Filters: interceptors run inside DispatcherServlet with MVC context;
> filters run outside with raw Servlet API. For distributed tracing, a filter
> is better (fires for all requests including static resources); for controller-
> specific authorization, an interceptor is better.

*Push deeper:* HandlerMethodArgumentResolver is the extension point for binding
custom method parameters. Spring Security's @AuthenticationPrincipal is
implemented as a HandlerMethodArgumentResolver.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Servlet Filters and HandlerInterceptors are interchangeable."**
Filters run BEFORE DispatcherServlet - they see all requests. Interceptors run
INSIDE DispatcherServlet - only for requests that reach the dispatcher. Spring
Security's filter chain runs BEFORE DispatcherServlet, which is why security
decisions happen before any MVC processing.

**Misconception 2: "@ExceptionHandler methods handle all exceptions."**
@ExceptionHandler in a @Controller handles exceptions from THAT controller.
@ExceptionHandler in @ControllerAdvice handles exceptions from ALL controllers.
However, exceptions thrown from HandlerInterceptors are NOT handled by
@ControllerAdvice - they bypass the exception handler mechanism.

**Misconception 3: "Spring MVC processes only REST API requests."**
Spring MVC handles all HTTP requests: HTML form submissions, file uploads,
server-sent events. @RestController is just @Controller + @ResponseBody.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: HandlerInterceptor not firing**
Symptom: Interceptor code not executing for certain requests.
Cause: Path pattern not matching, or interceptor not registered in WebMvcConfigurer.
Fix: Verify with addPathPatterns("/**") to match all, then narrow down.

**Failure 2: @ExceptionHandler not catching exception**
Symptom: Exception bubbles up, global handler not invoked.
Cause: Exception thrown from interceptor (not caught by @ControllerAdvice),
or exception thrown before DispatcherServlet (Servlet filter layer).
Diagnosis: Check the exception stack trace - if it shows outside DispatcherServlet,
@ControllerAdvice cannot catch it.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What is DispatcherServlet and what is its role?**

DispatcherServlet is a standard Java Servlet registered with the embedded
servlet container. Every HTTP request to a Spring MVC application passes through
it. This is the Front Controller pattern.

Responsibilities:
1. Receive all HTTP requests
2. Delegate to HandlerMapping to find the handler
3. Execute HandlerInterceptors (preHandle)
4. Delegate to HandlerAdapter to invoke the handler
5. Execute HandlerInterceptors (postHandle)
6. Resolve the response (view or message converter)
7. Execute HandlerInterceptors (afterCompletion)

Spring Boot auto-configures DispatcherServlet via
DispatcherServletAutoConfiguration. Mapped to "/" by default.

*What separates good from great:* DispatcherServlet is itself a Spring bean,
configured in the WebApplicationContext. It reads HandlerMapping, HandlerAdapter,
ViewResolver, and other MVC beans from the context. You customize its behavior
by defining these beans.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What is HandlerMapping and what does it do?**

HandlerMapping maps incoming requests (URL + HTTP method) to a handler.
In @RequestMapping-based Spring MVC, the handler is a HandlerMethod (a
reference to the specific @Controller method).

Key implementations:
- RequestMappingHandlerMapping: maps @RequestMapping, @GetMapping, etc.
- SimpleUrlHandlerMapping: maps URLs to handler beans by name
- RouterFunctionMapping: maps functional route definitions

HandlerMapping returns a HandlerExecutionChain: the handler + any
HandlerInterceptors registered for the matched path pattern.

*What separates good from great:* Multiple HandlerMappings can coexist.
DispatcherServlet iterates them by @Order. The first one that returns a
non-null HandlerExecutionChain wins. This is how @RequestMapping controllers
and router functions can coexist.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What is the difference between HandlerInterceptor and Servlet Filter?**

**Servlet Filter:**
- Part of the Servlet specification
- Runs BEFORE DispatcherServlet
- Applies to all requests (static resources, error dispatches, everything)
- Raw HttpServletRequest/Response access only
- Spring Security runs here

**HandlerInterceptor:**
- Spring MVC-specific
- Runs INSIDE DispatcherServlet, AFTER routing
- Only applies to requests handled by DispatcherServlet
- Access to handler method and ModelAndView

Use filter for: headers for all responses, authentication infrastructure.
Use interceptor for: controller-aware logic, audit logging of endpoints called.

*What separates good from great:* Spring Security's DelegatingFilterProxy is
a plain Filter that delegates to a Spring-managed Filter bean. This bridges
Servlet Filter and Spring context - security runs in the filter chain while
being a Spring bean with full DI support.

---

**[MID] Q4 - [HANDS-ON] How do you implement centralized exception handling?**

**@ControllerAdvice + @ExceptionHandler** (preferred):
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(EntityNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handle(
            EntityNotFoundException ex) {
        return new ErrorResponse(ex.getMessage());
    }
}
```
> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Catches exceptions from any @Controller in the application.

Selection order: controller-level @ExceptionHandler first, then
@ControllerAdvice global handlers. Most specific exception type wins.

*What separates good from great:* ResponseEntityExceptionHandler is a
convenience base class for @ControllerAdvice that handles all Spring MVC
standard exceptions with RFC 7807 Problem Detail responses.

---

**[MID] Q5 - [CONCEPTUAL] What is HandlerMethodArgumentResolver?**

Resolves @Controller method parameters from the HTTP request. Each @RequestParam,
@PathVariable, @RequestBody has a corresponding resolver.

Custom resolver - bind authenticated user:
```java
@Component
public class CurrentUserResolver
        implements HandlerMethodArgumentResolver {
    @Override
    public boolean supportsParameter(
            MethodParameter parameter) {
        return parameter.hasParameterAnnotation(
            CurrentUser.class);
    }

    @Override
    public Object resolveArgument(
            MethodParameter parameter,
            ModelAndViewContainer mav,
            NativeWebRequest req,
            WebDataBinderFactory binder) {
        Authentication auth = SecurityContextHolder
            .getContext().getAuthentication();
        return auth.getPrincipal();
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates metadata declaration using Spring annotation. **KEY MECHANISM:** annotations are processed at compile-time or runtime via reflection. **WHY IT MATTERS:** annotation processing adds compile time; runtime reflection disables JIT optimizations. **TAKEAWAY: prefer compile-time annotation processors (APT) over runtime reflection for performance.**

*What separates good from great:* Spring Security's @AuthenticationPrincipal
is implemented this way. Understanding this mechanism means you can implement
the same pattern for tenant ID from header, pagination from query params, etc.

---

**[MID] Q6 - [CONCEPTUAL] What is the difference between @Controller and @RestController?**

@RestController = @Controller + @ResponseBody on the class.

@Controller:
- Each method must explicitly have @ResponseBody to return JSON/XML
- Or return a view name resolved by ViewResolver

@RestController:
- @ResponseBody applied to ALL methods automatically
- Method return values always serialized to response body
- Cannot return view names (they would be serialized as strings)

Choose @Controller when mixing REST and view rendering.
Choose @RestController for pure REST API controllers.

*What separates good from great:* A common mistake is using @RestController and
returning a String (page name) expecting ViewResolver to render a template.
The String is serialized as a JSON string instead.

---

**[SENIOR] Q7 - [CONCEPTUAL] How does @RequestBody parsing work?**

@RequestBody triggers HttpMessageConverter to deserialize the request body.

Process:
1. Spring inspects Content-Type header.
2. Finds HttpMessageConverter (e.g., MappingJackson2HttpMessageConverter
   for application/json).
3. Converter reads and deserializes the body.
4. If @Valid is present, JSR-303 validation runs.

Failure: HttpMessageNotReadableException thrown -> 400 Bad Request.

Customizing Jackson: define an ObjectMapper bean. Spring Boot auto-config
picks it up via JacksonAutoConfiguration.

*What separates good from great:* @RequestBody reads the input stream once.
The stream is not resettable. If you need to read the body multiple times
(interceptor + controller), use ContentCachingRequestWrapper.

---

**[SENIOR] Q8 - [CONCEPTUAL] How do you add custom headers to all responses?**

Option 1 - Servlet Filter (for ALL requests):
```java
@Component
public class SecurityHeadersFilter
        extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(
            HttpServletRequest req,
            HttpServletResponse resp,
            FilterChain chain) throws Exception {
        resp.setHeader("X-Content-Type-Options",
            "nosniff");
        resp.setHeader("X-Frame-Options", "DENY");
        chain.doFilter(req, resp);
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Option 2 - HandlerInterceptor (MVC requests only):
```java
@Override
public void afterCompletion(...) {
    resp.setHeader("X-Request-Id",
        MDC.get("requestId"));
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Security headers should use Servlet Filter to apply to all responses
including error pages and static content.

*What separates good from great:* Spring Security's HeaderWriterFilter adds
security headers automatically (X-Content-Type-Options, X-Frame-Options,
HSTS). Configure via HttpSecurity.headers() rather than writing your own filter.

---

**[SENIOR] Q9 - [SYSTEM DESIGN] How do you handle multipart file uploads?**

```java
@RestController
@RequestMapping("/uploads")
public class FileUploadController {
    @PostMapping(
        consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public UploadResponse upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam("description") String desc) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException(
                "File cannot be empty");
        }
        // Security: validate content type
        if (!isAllowedType(file.getContentType())) {
            throw new IllegalArgumentException(
                "File type not allowed");
        }
        String filename = storage.store(file);
        return new UploadResponse(filename, desc);
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Configuration:
```
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* getContentType() returns the MIME type from
HTTP headers - user-controlled and not trustworthy for security decisions.
Use Apache Tika to detect the actual content type from file bytes. Using
Content-Type header for security validation is an OWASP-listed vulnerability
(Unrestricted File Upload). Also: store files outside the webroot, use UUID
filenames (not the original - path traversal prevention).

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



