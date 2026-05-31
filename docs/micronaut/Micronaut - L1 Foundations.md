---
layout: default
title: "Micronaut - L1 Foundations"
parent: "Micronaut"
grand_parent: "SK Interview"
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

> **Code walkthrough:** @Singleton on OrderService
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

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Scopes, @Inject, annotation basics |
| Senior | 6 min | @Requires conditions, @Primary/@Named, compile-time mechanics |

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** @Controller registers the
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

| Feature | Micronaut | Spring MVC |
|---|---|---|
| Controller annotation | @Controller | @RestController |
| GET route | @Get | @GetMapping |
| Path variable | @PathVariable | @PathVariable |
| Query param | @QueryValue | @RequestParam |
| Request body | @Body | @RequestBody |
| Response control | HttpResponse<T> | ResponseEntity<T> |
| Error handling | @Error | @ExceptionHandler |

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

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | @Controller, @Get, @Post, parameter binding |
| Senior | 6 min | HttpResponse, reactive types, error handling, compile-time routing |

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

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Annotations, parameter binding, HttpResponse. |
| Hiring Manager | HTTP server basics, REST endpoint creation. |
| Bar Raiser | Compile-time routing vs Spring DispatcherServlet, reactive types. |
| Peer Engineer | "Switching from Spring MVC to Micronaut HTTP was mostly annotation renaming. @RequestParam → @QueryValue." |

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

> **Code walkthrough:** @ConfigurationProperties is
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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** Unit test: plain Java, no
> container. Constructor injection makes this trivial.
> Integration test: @MicronautTest starts embedded
> server. @Client("/") injects an HTTP client pointed
> at the embedded server. @MockBean replaces the real
> OrderService with a mock - Micronaut's compile-time
> DI picks up the @MockBean factory method. The injected
> orderService in the test is the same mock instance.

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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



