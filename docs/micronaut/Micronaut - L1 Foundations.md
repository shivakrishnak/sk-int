---
layout: default
title: "Micronaut - L1 Foundations"
parent: "Micronaut"
nav_order: 2
permalink: /micronaut/l1-foundations/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Micronaut Bean Model and DI Basics](#micronaut-bean-model-and-di-basics) | medium |
| 2 | [Micronaut Application Startup](#micronaut-application-startup) | medium |
| 3 | [Micronaut HTTP Server Basics](#micronaut-http-server-basics) | medium |
| 4 | [Micronaut Configuration System](#micronaut-configuration-system) | medium |
| 5 | [Micronaut Testing Fundamentals](#micronaut-testing-fundamentals) | medium |

---

# Micronaut Bean Model and DI Basics

**Interview Weight:** medium - The bean model is the
foundation of all Micronaut development. Tested to
verify understanding of scope, injection, and the
difference from Spring's model.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut's DI uses standard JSR-330 annotations:
> @Singleton, @Inject, @Qualifier. Beans are discovered
> via annotation processing at compile time. A @Singleton
> class gets a generated BeanDefinition class in the
> build output. At runtime, Micronaut loads these
> pre-built definitions instead of scanning classpath.
> Injection works: constructor injection (preferred),
> field injection (@Inject), method injection.

**3 minutes (Senior):**

> Bean scopes:
> @Singleton: one instance per application context.
>   The default for most services.
> @Prototype: new instance per injection point.
>   Expensive to create objects - be careful.
> @RequestScope: one instance per HTTP request.
>   Useful for request-context objects.
> @Infrastructure: internal Micronaut beans
>   (not typically used in application code).
>
> Bean qualification:
> @Named("name"): qualifies beans by name.
> @Primary: default bean when multiple implementations.
> @Requires: conditional bean based on configuration,
>   class presence, or bean presence.
>
> Injection types:
> Constructor injection (recommended):
>   @Singleton class OrderService {
>     OrderService(OrderRepository repo) {...}
>   }
>   - Immutable, testable, no circular dependency surprise
>
> Field injection (@Inject):
>   @Inject OrderRepository repo;
>   - Requires mutable field, harder to unit test
>
> @Requires conditions (Micronaut-specific):
>   @Requires(property="feature.enabled", value="true")
>   @Requires(classes = SomeClass.class)
>   @Requires(beans = SomeBean.class)
>   @Requires(env = "production")

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Micronaut's
dependency injection works - how beans are declared
and injected."

**(2) First principles:** "DI = declare what you need,
framework provides it. Micronaut declares all the
wiring at compile time; at runtime, it's just loading
pre-built configurations."

**(3) Bridge:** "Micronaut beans work like Spring beans
but with one key difference: the wiring documentation
(BeanDefinition) is written at compile time, not
assembled at runtime."

---

### 💻 Code Example

```java
// Declare a singleton bean
@Singleton
public class OrderService {
    private final OrderRepository repository;

    // Constructor injection - preferred
    public OrderService(
            OrderRepository repository) {
        this.repository = repository;
    }

    public Order findById(Long id) {
        return repository.findById(id)
            .orElseThrow(NotFoundException::new);
    }
}

// Conditional bean
@Singleton
@Requires(property = "notification.email.enabled",
          value = "true")
public class EmailNotificationService
        implements NotificationService {
    // Only loaded when property is true
}

// Multiple implementations, @Primary default
@Singleton
@Primary
public class DatabaseOrderRepository
        implements OrderRepository {
    // Used by default when OrderRepository injected
}

@Singleton
@Named("cache")
public class CachingOrderRepository
        implements OrderRepository {
    // Used when @Inject @Named("cache") is specified
}

// Injection of the non-default:
@Singleton
public class AnalyticsService {
    AnalyticsService(
            @Named("cache")
            OrderRepository cacheRepo) {
        // Gets CachingOrderRepository
    }
}

// Test: no mocking framework needed
@MicronautTest
class OrderServiceTest {
    @Inject
    OrderService orderService;
    // Micronaut injects the real service
    // (or use MockBean for mocking)
}
```

> **Code walkthrough:** @Singleton on OrderServiceice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> triggers compile-time generation of OrderServiceBeanDefinition
> in the build output. At runtime, this definition
> is loaded, and the constructor injection is called
> with the resolved OrderRepository. @Requires(property=...)
> means the EmailNotificationService bean is only
> registered when the config property is true - evaluated
> at startup, not compile time. @Primary marks the
> default when multiple implementations of an interface
> exist; @Named provides a qualifier for non-default
> selection.

---

### 📘 Concept Explanation

**What it is:**

Micronaut's Dependency Injection model is based on JSR-330
(`javax.inject`/`jakarta.inject`) annotations. Beans are plain
Java classes annotated with scope annotations (`@Singleton`,
`@Prototype`, `@RequestScope`, etc.). Micronaut generates
`BeanDefinition` implementation classes at compile time.

**How it works:**

When you annotate a class with `@Singleton`, Micronaut's APT
generates a class like `$MyService$Definition` that implements
`BeanDefinition<MyService>`. This definition class knows:
- How to construct MyService (which constructor to use)
- What to inject (all `@Inject`-annotated fields/constructors)
- The bean's lifecycle (singleton = shared instance)

At startup, `ApplicationContext.run()` loads all
`BeanDefinition` classes from the classpath, builds the
dependency graph, and creates bean instances in the correct
order. No reflection needed - all construction is via
generated code.

**Constructor injection vs field injection:**

Micronaut recommends constructor injection: `@Inject` is
implicit on constructors with one constructor; it is explicit
when there are multiple constructors. Field injection works
but makes beans harder to test (cannot create without running
a full context). Constructor injection also makes required
dependencies explicit.

**Why it matters:**

Beans are available immediately after context startup. No lazy
proxy creation means no first-call overhead. Test speed:
`ApplicationContext.run()` in tests completes in ~50ms.

---

### 🎓 Answers by Seniority

**Junior:** "@Singleton marks a bean. @Inject injects
it. Micronaut processes annotations at compile time
so startup is fast."

**Senior:** "Constructor injection is always preferred:
it makes dependencies explicit, final, and testable
without a DI container. @Requires is Micronaut's
equivalent of Spring's @ConditionalOnProperty - useful
for environment-specific beans."

---

### ⚠️ Common Misconceptions

**Misconception 1: @Singleton in Micronaut behaves
exactly like Spring's @Component.**

Both create a single shared instance, but there are important
differences. Spring's `@Component` is discovered by classpath
scan at runtime. Micronaut's `@Singleton` creates a bean that
was registered at compile time - there is no runtime scan.
Additionally, Spring's singleton scope is per-ApplicationContext
while Micronaut's is per-ApplicationContext too, but the
context is typically the whole application. The practical
difference: Micronaut beans cannot be added dynamically at
runtime (post-startup) while Spring supports some runtime
registration patterns.

**Misconception 2: You need to use @Inject everywhere in
Micronaut for injection to work.**

Micronaut uses constructor injection as the primary mechanism.
If a bean has a SINGLE constructor with parameters, Micronaut
injects them automatically without `@Inject`. `@Inject` is
only required for: field injection, method injection, or when
a bean has multiple constructors (to mark which one to use).
The recommended pattern is a single annotated constructor or
a single unannotated constructor - either works.

**Misconception 3: Micronaut beans are thread-safe because
they are singletons.**

Singleton scope means ONE INSTANCE shared across all requests.
The instance itself is not thread-safe unless you make it so.
A `@Singleton` service with mutable instance fields accessed
by concurrent requests is a data race. Micronaut's scope control
ensures one bean instance but does NOT add synchronization.
Use immutable fields (set via constructor, never changed), or
use `@RequestScope` for request-local state, or explicitly
synchronize mutable shared state.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Bean not found despite @Singleton
annotation being present on the class.**

Symptom: `No bean of type [MyService] found` at startup
even though `@Singleton` is on the class. Root cause: the
class is in a package not processed by Micronaut's APT -
either the package is not under the application's root
package or the APT is not configured for that module.
Diagnosis: check if `$MyService$Definition.class` exists in
`build/classes`; if it does not, APT did not run on that class.
Fix: ensure the class is in a package under the application
root; add `micronaut-inject-java` APT dependency to the module.

**Failure Mode 2: Scope mismatch - injecting
@Prototype into @Singleton shares one prototype instance.**

Symptom: a `@Prototype` bean (new instance per injection)
behaves like a singleton when injected into a `@Singleton`.
Root cause: the `@Singleton` holds a reference to the
`@Prototype` bean injected at startup - that single reference
is reused for the lifetime of the singleton. Fix: inject
`ApplicationContext` and call `context.getBean(MyProto.class)`
each time you need a fresh instance; or use a `Provider<T>`
injection which creates a new instance on each `get()` call.

**Failure Mode 3: @Requires condition evaluated incorrectly
causes bean to be created when it should not be (or vice versa).**

Symptom: a feature-flagged bean is always created regardless
of configuration, or never created despite correct config.
Root cause: `@Requires(property="x", value="true")` compares
string values; if the config value is `True` (capital T) or
the property is not set (defaults differ from what `@Requires`
checks), the condition fails silently. Diagnosis: enable
Micronaut debug logging (`micronaut.context.condition=DEBUG`)
to see which `@Requires` conditions were evaluated and why
they passed/failed. Fix: check property key case sensitivity
and match the exact configured value.

---

### 🎯 Interview Deep-Dive

| Experience| Time| Depth|
|----------|-----|-------------------------------------------------------------|
| Junior| 3 min| Scopes, @Inject, annotation basics|
| Senior| 6 min| @Requires conditions, @Primary/@Named, compile-time mechanics|

---

**[SENIOR] Q1 - How does Micronaut handle circular
dependencies compared to Spring?**

*Why they ask:* Circular dependency is a common gotcha
in DI frameworks.

Spring: detects circular dependencies at startup.
For field/setter injection: Spring can resolve circular
dependencies by creating a partially-constructed bean.
For constructor injection: fails with BeanCreationException.

Micronaut: has zero tolerance for circular dependencies.
Circular dependency at compile time → compile error.
Since wiring is generated at compile time, Micronaut
can detect the cycle before the application even runs.

Benefit: compile-time error is better than runtime error.
Circular dependencies indicate design problems (two
beans too tightly coupled). Micronaut forces you to
fix them.

Fix: introduce a @Lazy injection, extract a third
class, or redesign responsibilities to break the cycle.

```java
// In Spring, this might "work" (field injection):
@Component class A { @Autowired B b; }
@Component class B { @Autowired A a; }

// In Micronaut: compile error
// "Circular dependency detected..."
// Forced to fix the design.
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* "Compile-time circular
dependency detection is a feature, not a limitation."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Singleton, @Requires, injection types. |
| Hiring Manager | Compile-time DI = fewer runtime surprises. |
| Bar Raiser | Circular dependency handling, @Requires conditions, compile-time detection. |
| Peer Engineer | "Micronaut caught a circular dependency at compile time that had been silently 'working' in our Spring code for months." |

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


# Micronaut Application Startup

**Interview Weight:** medium - Startup mechanics explain
why Micronaut is fast and how to further optimize
startup time.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut starts by scanning the classpath for
> generated BeanDefinition classes (not for annotations
> at runtime). These were generated by annotation
> processors during compilation. The ApplicationContext
> loads BeanDefinitionRegistry, resolves dependencies
> using the pre-built graphs, starts the HTTP server,
> and the application is ready. Total time: typically
> 100-500ms. No classpath scanning, no proxy generation.

**3 minutes (Senior):**

> Startup sequence:
>
> 1. Main.run() creates ApplicationContext
> 2. ApplicationContext scans classpath for classes
>    implementing BeanDefinition (NOT for @Singleton
>    annotations - those were already processed)
> 3. Builds BeanDefinitionRegistry from the discovered
>    definitions
> 4. Resolves dependency graph (already computed at
>    compile time; just loading the result)
> 5. Creates @Singleton instances eagerly (or lazily
>    based on @Requires conditions)
> 6. Starts embedded HTTP server (Netty)
> 7. ApplicationEventPublisher fires
>    ApplicationStartupEvent
> 8. Application ready
>
> Compare Spring:
> 1. Main.run() creates ApplicationContext
> 2. ClassPathScanningCandidateComponentProvider
>    scans packages for @Component annotations
> 3. AnnotationConfigApplicationContext processes
>    @Configuration classes
> 4. CGLIB creates runtime proxies for beans
> 5. BeanFactory resolves and injects dependencies
> 6. Application ready
>
> The key step that's eliminated in Micronaut:
> steps 2-4 of the Spring sequence.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Micronaut's
startup process - why it's fast and what happens
when the application starts."

**(2) First principles:** "Startup = doing work. Less
work = faster startup. Micronaut moves Spring's startup
work to compile time."

**(3) Bridge:** "Micronaut startup is like loading
a compiled binary vs assembling source code. Spring
assembles the DI wiring at startup. Micronaut loads
pre-compiled wiring."

---

### 📘 Concept Explanation

**What it is:**

Micronaut's application startup sequence is the process from
`ApplicationContext.run()` (or `Micronaut.run()`) to the
application ready state. Unlike Spring's complex multi-phase
refresh cycle, Micronaut's startup is a straightforward
sequential initialization of pre-built components.

**How it works:**

Startup phases:
1. **ServiceLoader**: Micronaut uses Java ServiceLoader to
   discover `BeanDefinitionReference` implementations
   generated by APT. These are cheap to load (no reflection).
2. **Context creation**: `DefaultApplicationContext` is
   created with the detected environment(s).
3. **Bean registration**: All discovered `BeanDefinition`s
   are registered with the context.
4. **Eager singleton initialization**: Beans annotated with
   `@Singleton` and referenced by eager-start components
   are instantiated. `@Context` beans (always-eager) are
   instantiated immediately.
5. **Server start**: `EmbeddedServer` starts (Netty by
   default), binds to port, registers routes from compiled
   controller definitions.
6. **ApplicationStartedEvent**: Published; `@EventListener`
   methods triggered for startup hooks.

Total time (simple app): 50-200ms on modern hardware.

**Why it matters:**

Sub-200ms startup enables Lambda cold starts within budget,
rapid Kubernetes pod scale-out, and fast test cycles.
The key enabler: no classpath scanning and no runtime proxy
generation - all work was done at build time.

---

### 🎓 Answers by Seniority

**Junior:** "Micronaut starts by loading pre-built
BeanDefinition classes. These were generated at compile
time so there's no scanning or proxy generation at
startup."

**Senior:** "The startup sequence: load BeanDefinitions
(generated classes), resolve the dependency graph
(pre-computed), instantiate beans, start Netty. The
eliminated steps vs Spring: no classpath scanning, no
CGLIB proxy generation. Those are the expensive operations
that slow Spring startup."

---

### ⚠️ Common Misconceptions

**Misconception 1: Micronaut's fast startup means all
beans are lazy-loaded on first use.**

Micronaut starts fast because it uses pre-built definitions,
NOT because beans are lazy. `@Singleton` beans are created
at startup (eagerly) when they are part of the dependency
graph of an eagerly-created bean. `@Context` beans are always
created at startup. Lazy bean creation (`@Singleton` bean
never requested) only applies if no other bean depends on it
or if `@Requires` conditions exclude it. The speed comes from
the initialization cost being pre-paid at compile time.

**Misconception 2: ApplicationContext.run() blocks until
all background tasks complete.**

`ApplicationContext.run()` returns after the server is bound
and ready to accept requests. Background tasks started by
`@Async` methods, scheduled tasks, or event listeners running
after `ApplicationStartedEvent` may still be running. If your
startup logic involves async tasks (pre-warming caches, loading
reference data), you need explicit synchronization mechanisms
(CountDownLatch, CompletableFuture) to ensure they complete
before the service is considered healthy.

**Misconception 3: The startup time guarantee holds
regardless of what initialization code you add.**

Micronaut's framework startup is fast. Your APPLICATION startup
may be slow if: (1) `@Context` or early `@Singleton` beans
run expensive work (slow database queries, HTTP calls to remote
services, reading large files) during their `@PostConstruct`
methods, (2) you have hundreds of eagerly-initialized complex
beans, or (3) you use frameworks that do runtime work inside
Micronaut beans. Micronaut gives you a fast foundation;
application code can still make startup slow.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Application appears to start but
health endpoint returns DOWN.**

Symptom: `ApplicationContext.run()` completes and server binds,
but `/health` returns `{"status": "DOWN"}`. Root cause:
a `HealthIndicator` bean is reporting DOWN because a dependency
(database connection, Redis, external service) is not available
or failed its initial health check. Diagnosis: call `/health`
with details: `/health?details=true` to see which indicator
is failing. Fix: verify the failing dependency is accessible
from the application; check connection pool configuration;
add `@Requires(beans = DataSource.class)` to conditional health
indicators that should only run when their dependency is present.

**Failure Mode 2: Startup succeeds but first request
is slow due to JIT compilation warmup.**

Symptom: first few requests take 10-100x longer than steady-
state latency (e.g., 2000ms first request vs 20ms steady state).
Root cause: JVM JIT compiler has not yet compiled the hot paths.
Micronaut's startup is fast but JIT warmup still occurs on the
JVM. Diagnosis: measure request latency over the first 100
requests vs subsequent requests. Fix: add JVM warming in health
probes (Kubernetes readinessProbe delays traffic until the pod
is JIT-warmed); use GraalVM native image (JIT warmup eliminated);
or use Spring-style precompilation hints.

**Failure Mode 3: @EventListener startup hooks run but
their exceptions are silently swallowed.**

Symptom: post-startup initialization appears to run but data
that should be loaded is missing; no error visible in logs.
Root cause: exceptions in `@EventListener ApplicationStartedEvent`
methods may be caught and logged at DEBUG level (not ERROR)
depending on the Micronaut version and event publisher configuration.
Diagnosis: add explicit try/catch with error logging in event
listener methods; enable DEBUG logging for `io.micronaut.context`.
Fix: always log and re-throw (or throw a custom fatal exception)
in critical startup listeners; consider using a dedicated
`ApplicationStartup` hook with failure handling.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Why startup is fast, BeanDefinition concept |
| Senior | 5 min | Startup sequence comparison with Spring |

---

**[SENIOR] Q1 - What slows Micronaut startup and
how do you diagnose it?**

*Why they ask:* Production optimization question.

Startup can slow when:
1. Many @Singleton beans initialized eagerly (each
   must be constructed).
2. External service initialization in @PostConstruct
   (database connections, cache warmup).
3. Large number of @Requires conditions evaluated.
4. @EventListener initialization chains.

Diagnosis:
```java
// Enable startup timing
micronaut.application.name: myapp
micronaut.metrics.enabled: true

// Or: start with system property
// -Dmicronaut.startup.verbose=true

// Check: io.micronaut.context.DefaultBeanContext
// logs bean instantiation time
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Optimization:
1. Use @Lazy injection where beans aren't needed
   at startup.
2. Move heavy initialization to background tasks
   (ApplicationReadyEvent listener).
3. Reduce eager singleton count.
4. Profile with async startup logging.

*What separates good from great:* @PostConstruct
as the most common startup slowdown (developer-controlled).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | BeanDefinition loading, startup sequence. |
| Hiring Manager | Micronaut starts in milliseconds. |
| Bar Raiser | Startup optimization, @PostConstruct overhead, diagnosis commands. |
| Peer Engineer | "We had a 1.5s Micronaut startup. Traced it to @PostConstruct database pool warmup. Made it async: 200ms startup." |

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


# Micronaut HTTP Server Basics

**Interview Weight:** medium - HTTP server configuration
is core daily usage. Tested for @Controller annotations,
route binding, and response types.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut's HTTP server is Netty-based (async, non-blocking).
> Controllers are annotated with @Controller. Methods
> map to HTTP methods via @Get, @Post, @Put, @Delete.
> Route parameters: @PathVariable for path, @QueryValue
> for query string, @Body for request body. Responses:
> return a POJO (auto-serialized to JSON), HttpResponse<T>
> for full control, or reactive types (Single/Flux)
> for non-blocking responses.

**3 minutes (Senior):**

> Controller model:
>
> @Controller("/orders"): maps to /orders base path
> @Get("/{id}"): GET /orders/{id}
> @Post: POST /orders
> @Put("/{id}"): PUT /orders/{id}
> @Delete("/{id}"): DELETE /orders/{id}
>
> Parameter binding:
> @PathVariable Long id: from /orders/{id}
> @QueryValue String status: from ?status=PAID
> @Body OrderRequest body: from JSON body
> @Header String accept: from request header
>
> Response types:
> Return POJO: 200 OK with JSON serialization
> Return Optional<T>: 200 or 404 on empty
> Return HttpResponse<T>: full control over status/headers
> Return Single<T>: reactive, non-blocking
> Return Flux<T> / Publisher<T>: streaming
>
> Error handling:
> @Error annotation on method handles specific errors
> @Error(global = true) handles all errors
>
> Filters: @Filter annotation on classes
> implementing HttpServerFilter
> (before/after request processing)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Micronaut HTTP
controller basics - how to define routes and handle
requests."

**(2) First principles:** "Controllers map HTTP methods
and paths to Java methods. Parameters are bound from
the request. Responses are serialized."

**(3) Bridge:** "Micronaut HTTP controllers feel like
Spring MVC with different annotation package names.
@Controller, @Get, @Post vs @RestController, @GetMapping,
@PostMapping. Same concept, different implementation."

---

### 💻 Code Example

```java
@Controller("/orders")
public class OrderController {

    private final OrderService orderService;

    // Constructor injection
    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    // GET /orders/{id}
    @Get("/{id}")
    public HttpResponse<OrderDto> findById(
            @PathVariable Long id) {
        return orderService.findById(id)
            .map(HttpResponse::ok)
            .orElse(HttpResponse.notFound());
    }

    // GET /orders?status=PAID&page=0&size=20
    @Get
    public List<OrderDto> listByStatus(
            @QueryValue(defaultValue = "PENDING")
            String status,
            @QueryValue(defaultValue = "0")
            int page,
            @QueryValue(defaultValue = "20")
            int size) {
        return orderService
            .findByStatus(status, page, size);
    }

    // POST /orders
    @Post
    @Status(HttpStatus.CREATED)
    public OrderDto create(
            @Valid @Body CreateOrderRequest req) {
        return orderService.create(req);
    }

    // Error handling
    @Error(status = HttpStatus.NOT_FOUND)
    public HttpResponse<ErrorDto> onNotFound(
            HttpRequest<?> request) {
        return HttpResponse.notFound(
            ErrorDto.of("Resource not found"));
    }
}
```

> **Code walkthrough:** @Controller registers theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> class at route /orders at compile time. @Get("/{id}")
> maps GET requests with a path variable. @PathVariable
> binds the {id} segment. Returning HttpResponse<T>
> gives full control - ok() for 200, notFound() for 404.
> @QueryValue(defaultValue=...) provides a default if
> the query param is absent. @Valid triggers bean
> validation on the request body. @Error handles 404s
> globally for this controller.

---

### ⚖️ Comparison Table

| Feature| Micronaut| Spring MVC|
|---|-------|------------------------------------------------------------------|
| Controller annotation| @Controller| @RestController|
| GET route| @Get| @GetMapping|
| Path variable| @PathVariable| @PathVariable|
| Query param| @QueryValue| @RequestParam|
| Request body| @Body| @RequestBody|
| Response control| HttpResponse<T>| ResponseEntity<T>|
| Error handling| @Error| @ExceptionHandler|

---

### 📘 Concept Explanation

**What it is:**

Micronaut's HTTP server is built on Netty - a non-blocking,
event-driven network library. Unlike traditional servlet
containers (Tomcat, Jetty), Netty does not use one thread per
connection. Instead, it uses a fixed-size event loop pool
(typically 2× CPU cores) to handle thousands of concurrent
connections.

**How it works:**

When `Micronaut.run()` starts, it creates a Netty
`EmbeddedServer`. Routes are registered from compiled
`@Controller` definitions. A request arrives:
1. Netty's event loop thread receives the request bytes
2. Micronaut's `RoutingInBoundHandler` matches the route
3. The controller method is invoked
4. If the return type is a plain object: response is
   serialized (JSON via Jackson) and returned synchronously
5. If the return type is `Publisher<T>` (reactive): the
   event loop continues handling other requests while the
   reactive pipeline runs; the response is sent when the
   Publisher completes

`@Controller` maps to URL prefixes; `@Get`, `@Post` etc.
map to HTTP methods and path patterns. Micronaut compiles
route definitions into an efficient `RouteExecutor` at
build time.

**Why it matters:**

Netty's non-blocking model enables handling 10,000+
concurrent connections with a small thread pool. Traditional
servlet containers need one thread per concurrent request
(thread-per-request model). At high concurrency, Micronaut's
model has dramatically lower thread overhead.

---

### 🎓 Answers by Seniority

**Junior:** "@Controller defines the base path. @Get,
@Post map HTTP methods. @PathVariable and @QueryValue
bind parameters."

**Senior:** "HttpResponse<T> gives full response control
(status, headers, body). For reactive endpoints: return
Single<OrderDto> from a reactive repository chain -
no thread blocking. Micronaut's HTTP binding is
compile-time: route matching generates code at compile
time, not a runtime reflection HashMap."

---

### ⚠️ Common Misconceptions

**Misconception 1: Micronaut's Netty server replaces the
need for a reverse proxy like Nginx.**

Netty is excellent for application-level HTTP serving but
is not a replacement for a reverse proxy. Nginx/HAProxy handle:
SSL termination with hardware offload, static file serving
with sendfile system call, connection rate limiting,
request buffering for slow clients, and load balancing.
Micronaut recommends putting Netty behind Nginx or a cloud
load balancer for production. Netty handles application logic;
the proxy handles infrastructure concerns.

**Misconception 2: Blocking operations in @Controller
methods work fine because the framework handles threading.**

Micronaut's Netty server uses event loop threads for I/O.
If a controller method performs a BLOCKING operation (JDBC
query, synchronous HTTP call, Thread.sleep), it blocks the
event loop thread - preventing it from handling other requests.
This leads to thread starvation and request queuing. Fix:
annotate blocking controller methods with `@ExecuteOn(TaskExecutors.IO)`
to offload them to a blocking I/O thread pool, or use
reactive non-blocking I/O throughout.

**Misconception 3: HTTP/2 is automatically enabled when
using Micronaut's Netty server.**

Micronaut supports HTTP/2 but it is NOT enabled by default.
To enable: configure SSL (HTTP/2 requires TLS in most browsers)
and set `micronaut.server.http-version: HTTP_2_0` in
application.yml. HTTP/2 provides multiplexing (multiple
requests on one connection), header compression (HPACK),
and server push - valuable for APIs with many small requests.
Without explicit configuration, Micronaut uses HTTP/1.1.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: 503 errors under high load due to
Netty event loop thread starvation.**

Symptom: under load, response times spike and some requests
return 503. Root cause: blocking operations in controllers
(DB calls, synchronous HTTP) are blocking Netty event loop
threads, preventing them from accepting new connections.
Diagnosis: thread dump shows Netty worker threads in BLOCKED
state waiting for JDBC or HTTP socket I/O. Fix: annotate
blocking controller methods with `@ExecuteOn(TaskExecutors.IO)`;
switch to reactive R2DBC (reactive database) or reactive
HTTP client instead of blocking alternatives.

**Failure Mode 2: JSON serialization errors produce
500 responses with no useful client-facing message.**

Symptom: API returns 500 with `{"message": "Internal Server
Error"}` when the response object has a serialization issue
(circular reference, missing no-arg constructor, non-serializable
type). Root cause: Jackson serialization fails at response
writing time; Micronaut's default error handler returns a
generic 500. Diagnosis: enable DEBUG logging for
`io.micronaut.http.server.exceptions`; add `@JsonIgnore`
to circular reference fields. Fix: implement `@Error` handler
for serialization exceptions; add custom Jackson configuration
via `ObjectMapperBeanCreatedEventListener`.

**Failure Mode 3: Request body not bound to controller
parameter due to missing Content-Type header.**

Symptom: controller method receives a null or empty object
for a `@Body`-annotated parameter when the client sends a
POST request. Root cause: client does not send
`Content-Type: application/json` header; Micronaut cannot
determine how to deserialize the body and uses the default
binding (no body binding without a content type). Diagnosis:
capture raw HTTP traffic (Wireshark, tcpdump) to verify
Content-Type header. Fix: configure the HTTP client to always
send `Content-Type: application/json` with JSON bodies; add
server-side validation that returns 400 for missing content types.

---

### 🎯 Interview Deep-Dive

| Experience| Time| Depth|
| Junior| 3 min| @Controller, @Get, @Post, parameter binding|
| Senior| 6 min| HttpResponse, reactive types, error handling, compile-time rout

---

**[SENIOR] Q1 - How does Micronaut's route binding
work compared to Spring's DispatcherServlet?**

*Why they ask:* Deep framework understanding.

Spring MVC: DispatcherServlet receives all requests.
Calls RequestMappingHandlerMapping (runtime HashMap of
route → handler method). Uses reflection to invoke the
handler method. Parameter binding via
HandlerMethodArgumentResolver list.

Micronaut: Netty receives requests directly.
RouterBean (generated at compile time) contains route
definitions. Route matching runs generated code (no
HashMap lookup, no reflection for invocation). Parameter
binding is compile-time generated code.

Result: Micronaut route handling is measurably faster
per request (~1-2ms less overhead per request). In
high-throughput scenarios (10,000+ RPS), this adds up.

*What separates good from great:* "Micronaut's route
matching is compiled code, not a runtime registry."

| Interviewer Type| Emphasis|
|---|--------------------------------------------------------------------------|
| Technical Panel| Annotations, parameter binding, HttpResponse.|
| Hiring Manager| HTTP server basics, REST endpoint creation.|
| Bar Raiser| Compile-time routing vs Spring DispatcherServlet, reactive types.|
| Peer Engineer| "Switching from Spring MVC to Micronaut HTTP was mostly annotat

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


# Micronaut Configuration System

**Interview Weight:** medium - Configuration is essential
for production applications. Tested for property
hierarchy, @Property injection, and @ConfigurationProperties.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut configuration uses application.yml (or
> .properties) with cascading overrides: defaults in
> application.yml, environment-specific in
> application-{env}.yml, system properties, and
> environment variables. Inject values with @Property
> or bind an entire configuration block to a POJO
> with @ConfigurationProperties. @Requires(property=...)
> enables conditional beans based on config.

**3 minutes (Senior):**

> Configuration hierarchy (highest to lowest priority):
>
> 1. System properties (-Dmy.property=value)
> 2. Environment variables (MY_PROPERTY=value,
>    Micronaut auto-converts UPPER_CASE to lower.case)
> 3. application-{environment}.yml
>    (activated by -Dmicronaut.environments=prod)
> 4. application.yml (default)
>
> Injection:
>
> @Property(name="my.value"):
>   Injects a single value. Can be String, Integer,
>   Boolean, Duration, etc. Micronaut handles type
>   conversion.
>
> @Value("${my.value}"):
>   Spring-style expression injection.
>   Supports defaults: @Value("${my.value:default}")
>
> @ConfigurationProperties("my.block"):
>   Binds an entire YAML block to a POJO.
>   Compile-time generated binding (not reflection).
>
> @EachProperty("services"):
>   Binds a list/map of configuration entries.
>   Each child creates a separate bean instance.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Micronaut
reads and injects configuration values."

**(2) First principles:** "Configuration = values that
change between environments. A framework must provide
a hierarchy so environment-specific values override
defaults."

**(3) Bridge:** "Micronaut configuration feels like
Spring Boot's configuration - same YAML, same @Value.
The difference: @ConfigurationProperties binding is
compile-time generated, not reflection-based."

---

### 💻 Code Example

```java
// application.yml
// service:
//   order:
//     timeout-seconds: 30
//     max-retries: 3
//     base-url: https://orders.internal

// Option 1: @Property for single values
@Singleton
public class OrderClient {

    @Property(name = "service.order.base-url")
    private String baseUrl;

    @Property(name = "service.order.timeout-seconds",
              defaultValue = "30")
    private int timeoutSeconds;
}

// Option 2: @ConfigurationProperties (recommended)
@ConfigurationProperties("service.order")
public class OrderClientConfig {
    // Binds service.order.* block
    private String baseUrl;
    private int timeoutSeconds = 30;  // default
    private int maxRetries = 3;

    // Getters and setters required
    public String getBaseUrl() { return baseUrl; }
    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }
    // ...
}

@Singleton
public class OrderService {
    OrderService(OrderClientConfig config) {
        // Full typed config object
        // All values pre-bound
    }
}

// Environment variable override
// Set: SERVICE_ORDER_BASE_URL=https://prod.orders
// Micronaut maps SERVICE_ORDER_BASE_URL
//           → service.order.base-url

// @EachProperty for multiple instances
// application.yml:
// data-sources:
//   primary:
//     url: jdbc:postgresql://db1/prod
//   reporting:
//     url: jdbc:postgresql://db2/reporting

@EachProperty("data-sources")
public class DataSourceConfig {
    private String url;
    private String name;  // auto-set from key ("primary")
    // ...
}
// Creates: one DataSourceConfig per data-sources entry
```

> **Code walkthrough:** @ConfigurationProperties isice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> preferred over @Property: it groups related config
> into a typed class, validates the config block at startup,
> and is refactor-safe (rename the Java field, not
> the string). @EachProperty creates multiple bean
> instances for lists of configuration entries - one
> DataSourceConfig for "primary" and one for "reporting".
> Environment variable conversion: Micronaut converts
> SERVICE_ORDER_BASE_URL → service.order.base-url
> automatically (uppercase + underscores → lowercase + dots).

---

### 📘 Concept Explanation

**What it is:**

Micronaut's configuration system provides type-safe, hierarchical
configuration binding from multiple sources (environment variables,
system properties, YAML/properties files, config servers).
It uses compile-time generated binding code rather than runtime
reflection.

**How it works:**

Configuration sources are merged in priority order (highest first):
1. Environment variables (MICRONAUT_SERVER_PORT -> micronaut.server.port)
2. System properties (-Dmicronaut.server.port=8080)
3. Application-specific config (application-prod.yml)
4. Application default config (application.yml)
5. Application-{env}.yml for active environments

`@ConfigurationProperties("datasource")` on a class generates
a compile-time binding that maps `datasource.*` properties to
the class fields. The binding uses generated code (no reflection)
so it is type-safe and fast.

Environment activation: `micronaut.environments=production` or
`MICRONAUT_ENVIRONMENTS=production` environment variable activates
the `production` environment, loading `application-production.yml`
and enabling `@Requires(env="production")` beans.

**Why it matters:**

Type-safe configuration binding catches configuration errors at
startup (wrong types, missing required values) rather than at
request time. The hierarchical override system enables environment-
specific configuration without code changes - the standard
twelve-factor app approach.

---

### 🎓 Answers by Seniority

**Junior:** "@Property injects a single config value.
@ConfigurationProperties binds a YAML block to a class.
Environment variables override application.yml."

**Senior:** "@ConfigurationProperties over @Property
for groups of related config. It enables type safety,
default values, and validation. @EachProperty for
dynamic multi-instance configurations (multiple data
sources, multiple service clients)."

---

### ⚠️ Common Misconceptions

**Misconception 1: Micronaut's configuration system works
identically to Spring Boot's @ConfigurationProperties.**

The annotation name is the same but the mechanism differs.
Spring Boot uses `@EnableConfigurationProperties` and runtime
reflection to bind properties. Micronaut uses APT-generated
code. The practical difference: Spring can bind to any bean
if you add `@ConfigurationProperties`; Micronaut requires
the class to be compile-time processed. Also, Micronaut uses
environment-specific naming conventions differently: Spring
uses `application-{profile}.properties`; Micronaut uses both
environments and named configurations with `@EachProperty`.

**Misconception 2: Environment variables always override
YAML configuration in Micronaut.**

Environment variables DO have higher priority than YAML files.
But the key translation matters: Micronaut converts environment
variables to property keys using specific rules - all uppercase,
underscores replace dots (DATASOURCE_URL -> datasource.url),
and double underscore replaces hyphen (DATABASE__HOST ->
database.host). If the environment variable key does not
exactly translate to the property key Micronaut expects, the
override silently fails. Always test environment variable
overrides explicitly.

**Misconception 3: @Value annotation is the recommended
way to inject configuration in Micronaut.**

`@Value("${my.property}")` works but is not the preferred
approach because it is a string expression with no type safety.
The preferred approach is `@ConfigurationProperties` which
generates type-safe binding. `@Value` is appropriate for
simple single-property injection where a full configuration
class would be overkill. For anything with more than one or
two properties, use `@ConfigurationProperties` for
refactoring safety and IDE navigation support.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Configuration not loaded in tests because
test environment configuration is missing.**

Symptom: `@MicronautTest` tests fail with null configuration
values or wrong defaults. Root cause: the test environment
activates `test` environment by default; if `application-test.yml`
is missing from test resources, the test uses `application.yml`
which may have production defaults (wrong DB URL, wrong service
endpoints). Diagnosis: log the active environment at test startup
(`micronaut.env=test` in logs). Fix: create `application-test.yml`
in `src/test/resources` with overrides for all environment-
specific settings (DB URL to H2/test DB, external service URLs
to mock server URLs).

**Failure Mode 2: @EachProperty beans created for wrong
number of configured items.**

Symptom: `@EachProperty` beans (which create one bean per
configured map entry) are not created, or extra beans are
created. Root cause: YAML list vs map syntax mismatch;
`@EachProperty` works with YAML map syntax but not list syntax.
Diagnosis: verify that the YAML uses named map entries
(`datasources.primary.url`) not list syntax
(`datasources[0].url`). Fix: restructure YAML to use named
entries; use `@EachProperty(value = "sources", list = true)`
for index-based lists.

**Failure Mode 3: Secret values logged by configuration
debug logging expose credentials.**

Symptom: enabling Micronaut configuration debug logging
(`micronaut.context=DEBUG`) shows database passwords and API
keys in plain text in log output. Root cause: Micronaut's
config debug logging logs property values including secrets.
Diagnosis: grep logs for credential patterns. Fix: use
`@ConfigurationProperties` with fields annotated with
`@io.micronaut.core.annotation.Introspected` and mask
sensitive fields in toString(); configure log4j/logback to
mask patterns; use a secrets manager (Vault, AWS Secrets
Manager) with Micronaut's secrets integration so values are
never in YAML files at all.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Property hierarchy, @Property, @ConfigurationProperties |
| Senior | 6 min | @EachProperty, environment overrides, validation |

---

**[SENIOR] Q1 - How do you validate configuration
at startup in Micronaut?**

*Why they ask:* Production-quality configuration management.

Add Bean Validation annotations to @ConfigurationProperties:

```java
@ConfigurationProperties("service.order")
@Validated
public class OrderClientConfig {

    @NotNull @NotBlank
    private String baseUrl;

    @Min(1) @Max(300)
    private int timeoutSeconds = 30;

    @Pattern(regexp = "https://.*")
    private String baseUrl;
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

With @Validated, Micronaut validates the bound
configuration at startup. If baseUrl is missing or
invalid, the application fails to start with a clear
error: "service.order.base-url: must not be blank."

Fail-fast on missing configuration: better to fail at
startup than fail on first request.

*What separates good from great:* Fail-fast startup
validation as the engineering reason for @Validated.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Property hierarchy, @ConfigurationProperties. |
| Hiring Manager | Environment-specific config overrides for deployment. |
| Bar Raiser | @Validated for startup validation, @EachProperty for multi-instance config. |
| Peer Engineer | "We add @Validated to every @ConfigurationProperties class. Missing config fails at startup, not at 2 AM." |

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


# Micronaut Testing Fundamentals

**Interview Weight:** medium - Testing in Micronaut
uses @MicronautTest for embedded server tests and
compile-time injection for unit tests.

---

### 🎯 Model Answer

**30 seconds:**

> @MicronautTest starts an embedded Micronaut server
> for integration tests. @Inject provides beans in
> tests. MockBean replaces beans with mocks. HTTP client
> tests use EmbeddedServer + HttpClient or a declarative
> @Client. Unit tests need no Micronaut container:
> just call the service directly with constructor
> injection.

**3 minutes (Senior):**

> Testing layers:
>
> Unit test (no container):
>   Construct service directly with mock dependencies.
>   No annotation processing needed.
>   Fastest, most isolated.
>
> Integration test (@MicronautTest):
>   Starts full Micronaut context.
>   @Inject injects beans from the running context.
>   MockBean replaces a real bean with a mock.
>   @Client injects an HTTP client pointing at the
>   embedded server.
>
> HTTP endpoint test:
>   @MicronautTest
>   Use EmbeddedServer URL or @Client for HTTP calls.
>   Verify HTTP status codes and response bodies.
>
> Database test:
>   @MicronautTest with in-memory database config
>   (H2 for integration tests).
>   Or: Testcontainers for real database.
>
> Key Micronaut advantage: no Spring Boot TestContext
>   caching complexity. Micronaut test starts fresh
>   context quickly due to fast startup.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to test
Micronaut applications - unit tests, integration tests,
HTTP tests."

**(2) First principles:** "Tests verify behavior.
Unit tests verify class logic. Integration tests verify
the wired system. HTTP tests verify the API surface."

**(3) Bridge:** "Micronaut testing is similar to Spring
Boot testing. @MicronautTest is @SpringBootTest.
@MockBean replaces @MockBean. Fast startup means
integration tests start in <500ms."

---

### 💻 Code Example

```java
// Unit test: no container needed
class OrderServiceTest {
    // Construct directly with mock
    OrderRepository mockRepo =
        mock(OrderRepository.class);
    OrderService service =
        new OrderService(mockRepo);

    @Test
    void findById_returnsOrder_whenExists() {
        Order expected = new Order(1L, "PENDING");
        when(mockRepo.findById(1L))
            .thenReturn(Optional.of(expected));

        Order result = service.findById(1L);
        assertThat(result.getStatus())
            .isEqualTo("PENDING");
    }
}

// Integration test with @MicronautTest
@MicronautTest
class OrderControllerIntegrationTest {

    @Inject
    EmbeddedServer server;

    @Inject
    @Client("/")
    HttpClient client;

    // Replace a bean with a mock
    @MockBean(OrderService.class)
    OrderService mockOrderService() {
        return mock(OrderService.class);
    }

    @Inject
    OrderService orderService;
    // Injected mock (same instance as above)

    @Test
    void findById_returns200_whenOrderExists() {
        Order order = new Order(1L, "PAID");
        when(orderService.findById(1L))
            .thenReturn(Optional.of(order));

        HttpResponse<OrderDto> response =
            client.toBlocking()
                .exchange(
                    HttpRequest.GET("/orders/1"),
                    OrderDto.class);

        assertThat(response.status())
            .isEqualTo(HttpStatus.OK);
        assertThat(response.body().getStatus())
            .isEqualTo("PAID");
    }
}
```

> **Code walkthrough:** Unit test: plain Java, noice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> container. Constructor injection makes this trivial.
> Integration test: @MicronautTest starts embedded
> server. @Client("/") injects an HTTP client pointed
> at the embedded server. @MockBean replaces the real
> OrderService with a mock - Micronaut's compile-time
> DI picks up the @MockBean factory method. The injected
> orderService in the test is the same mock instance.

---

### 📘 Concept Explanation

**What it is:**

Micronaut provides `@MicronautTest` - a JUnit 5/Spock test
annotation that starts a real Micronaut `ApplicationContext`
for integration testing. Context startup takes 50-200ms,
making full integration tests practical for rapid test cycles.

**How it works:**

`@MicronautTest` starts the full application context including
the embedded HTTP server (unless configured otherwise). Test
class fields annotated with `@Inject` are populated from the
context. The context is shared across tests in the same class
for performance; a new context is created for tests that
modify configuration.

Testing approaches:
1. **Unit tests**: `ApplicationContext.run()` for lightweight
   context without embedded server; inject the specific bean.
2. **Integration tests**: `@MicronautTest` with full context;
   use `RxHttpClient` or `HttpClient` (injected) to call
   the embedded server.
3. **Mocking**: Use `@MockBean(MyService.class)` to replace
   a real bean with a Mockito mock for the test context.
4. **Test property override**: `@MicronautTest(propertySources
   = "classpath:test.yml")` to load test-specific config.

**Why it matters:**

50-200ms context startup means you can write and run tens of
real integration tests in a normal test suite cycle, not
just unit tests. This gives confidence that the DI wiring
and HTTP routing work end-to-end.

---

### 🎓 Answers by Seniority

**Junior:** "@MicronautTest starts an embedded server.
@Inject gets beans. @MockBean replaces real beans with
mocks in tests."

**Senior:** "Constructor injection makes Micronaut unit
tests trivial - no container needed. @MicronautTest
integration tests start quickly (300ms) compared to
Spring Boot's 2-5 seconds. For HTTP contract testing:
inject @Client and call the embedded server endpoint
with full request/response verification."

---

### ⚠️ Common Misconceptions

**Misconception 1: @MockBean in Micronaut works exactly
like Mockito's @MockBean in Spring Boot.**

Spring Boot's `@MockBean` (from `spring-boot-test`) replaces
a bean in the Spring ApplicationContext with a Mockito mock.
Micronaut's `@MockBean` works similarly but must be applied
as a method-level annotation on a `@Factory` method that
returns the mock. It does NOT work as a field annotation
directly. The `@MockBean(ExistingBean.class)` parameter
specifies which real bean to replace. Common mistake: applying
it as a field annotation as in Spring Boot, which silently
has no effect in Micronaut.

**Misconception 2: @MicronautTest tests are slower than
pure unit tests because they start a full context.**

`@MicronautTest` starts a context in 50-200ms on modern
hardware - comparable to JVM startup overhead. For a test
suite of 100 integration tests, the context is typically
shared (context caching), so total overhead is 50-200ms
plus test execution time. This is acceptable for most
test suites. The bigger test speed issue is usually
database fixtures and I/O operations within tests,
not context startup.

**Misconception 3: You must use @MicronautTest for all
Micronaut tests.**

Many Micronaut tests do not need `@MicronautTest`. Pure
business logic (domain services, utilities, calculators)
should be tested with plain JUnit 5/Spock tests without
any context. `@MicronautTest` is appropriate when testing:
HTTP endpoints (routing, serialization), dependency injection
wiring, database operations, integration with other beans.
Use the simplest test approach that exercises the behavior
you care about.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Test ApplicationContext fails to start
because test-scoped beans conflict with production beans.**

Symptom: `@MicronautTest` fails with `Multiple beans found
for type [X]` or `No bean found for type [X]`. Root cause:
test class defines `@MockBean` methods that create extra
beans alongside real beans, or mock configuration is
incomplete. Diagnosis: enable context debug logging to see
all registered beans. Fix: ensure `@MockBean(TargetClass.class)`
correctly identifies the bean to REPLACE (not add to); verify
`@Replaces` annotation usage for complete bean substitution.

**Failure Mode 2: HTTP client injection fails in tests
with "no bean of type HttpClient".**

Symptom: `@Inject HttpClient client` in a `@MicronautTest`
class results in null or not-found error. Root cause: HTTP
clients in Micronaut tests must be created with the test
server's URL; using the global `HttpClient.create(url)` factory
is correct but does not support injection. Fix: use the
`@Client` annotation with the test server: `@Client("/")
HttpClient client` - Micronaut will inject a client pointed
at the embedded test server. Alternatively, inject
`EmbeddedServer` and use `server.getURL()` to construct
the client.

**Failure Mode 3: @TransactionalEventListener not working
in Micronaut tests because transactions are not active.**

Symptom: event listener annotated with `@TransactionalEventListener`
is never invoked in tests. Root cause: `@MicronautTest` does
not automatically wrap test methods in transactions. Without
an active transaction, transactional event listeners do not
fire. Fix: annotate the test method with `@Transactional`
explicitly; or use `@MicronautTest(transactional = true)`
to wrap all test methods in transactions.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | @MicronautTest, @Inject, @MockBean |
| Senior | 6 min | Unit vs integration layers, @Client HTTP testing, Testcontainers |

---

**[SENIOR] Q1 - How do you test Micronaut with a
real database using Testcontainers?**

*Why they ask:* Real-world integration testing strategy.

```java
// Use @Testcontainers in @MicronautTest
@MicronautTest
@Testcontainers
class OrderRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:15")
            .withDatabaseName("test");

    // Override datasource config via @Property
    @Property(name = "datasources.default.url",
              value = "#{@postgres.jdbcUrl}")
    void testFindByStatus() {
        // Tests run against real PostgreSQL
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using container. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Simpler: Micronaut Test Resources automatically
starts PostgreSQL (or any Testcontainer-supported DB)
when `micronaut-test-resources-jdbc-*` is on the
classpath. Zero configuration.

```yaml
# application-test.yml
test-resources:
  containers:
    postgres:
      image-name: postgres:15
```

> **Code walkthrough:** This application-test.yml example demonstrates YAML configuration pattern using container. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

Micronaut Test Resources starts the container, injects
the JDBC URL automatically. No @Container annotation needed.

*What separates good from great:* Micronaut Test Resources
as the zero-config Testcontainers solution.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @MicronautTest, @MockBean, @Client HTTP testing. |
| Hiring Manager | Testing at all levels (unit → integration → HTTP). |
| Bar Raiser | Test Resources, Testcontainers integration, compile-time @MockBean. |
| Peer Engineer | "Micronaut Test Resources is magic. Add postgres to classpath, run tests. Database starts automatically." |

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



