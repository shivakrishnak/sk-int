---
layout: default
title: "Micronaut - L2 HTTP"
parent: "Micronaut"
grand_parent: "SK Interview"
nav_order: 3
permalink: /micronaut/l2-http/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Micronaut HTTP Routing and Controllers](#micronaut-http-routing-and-controllers) | medium |
| 2 | [Micronaut Declarative HTTP Client](#micronaut-declarative-http-client) | medium |
| 3 | [Micronaut Reactive HTTP](#micronaut-reactive-http) | medium |
| 4 | [Micronaut Server Filters and Middleware](#micronaut-server-filters-and-middleware) | medium |
| 5 | [Micronaut Service Discovery](#micronaut-service-discovery) | medium |

---

# Micronaut HTTP Routing and Controllers

**Interview Weight:** medium - HTTP routing is core
to every Micronaut application. Tested for route
definitions, parameter binding, and response control.

---

### 🎯 Model Answer

**30 seconds:**

> @Controller sets the base path. Route methods use
> @Get, @Post, @Put, @Delete with optional path templates.
> Parameters bind via @PathVariable, @QueryValue, @Body,
> @Header. Return a POJO for 200 JSON response, Optional<T>
> for automatic 404 on empty, HttpResponse<T> for full
> status control, or reactive types (Single/Flux) for
> non-blocking. Route binding is generated at compile
> time - no reflection-based HashMap matching at runtime.

**3 minutes (Senior):**

> Route matching (compile-time generated):
> Routes are compiled into RouterBean at build time.
> Matching is code, not a runtime HashMap lookup.
>
> Content negotiation:
> @Produces(MediaType.APPLICATION_JSON): response type
> @Consumes(MediaType.APPLICATION_JSON): accepted type
>
> Status codes:
> @Status(HttpStatus.CREATED): default 201 for method
> Return HttpResponse.created(body): explicit 201
>
> Streaming:
> Return Publisher<T> or Flux<T> for streaming response.
> Uses chunked transfer encoding.
>
> Versioning:
> @Version("1") on method or controller.
> Request routing by Accept-Version header or
> X-API-Version header.
>
> Server Sent Events (SSE):
> Return Publisher<Event<T>> for SSE endpoint.
> Client receives stream of server-sent events.
>
> Validation:
> @Valid on @Body parameter triggers Bean Validation.
> ConstraintViolationException → 400 Bad Request.
>
> Encoding:
> @Body supports form encoding:
> @Body(value = "param", defaultValue = "")

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how HTTP routing
and controller methods work in Micronaut."

**(2) First principles:** "HTTP = URL + method → handler.
Controllers define the mapping. Parameters come from
the request. Response goes back."

**(3) Bridge:** "Micronaut @Controller + @Get is
Spring @RestController + @GetMapping. Same concept,
compile-time implementation."

---

### 💻 Code Example

```java
@Controller("/api/v1/orders")
@Produces(MediaType.APPLICATION_JSON)
public class OrderController {

    private final OrderService orderService;

    OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    // GET /api/v1/orders/{id}
    // Returns: 200 with body or 404
    @Get("/{id:\\d+}")  // Regex: digits only
    public HttpResponse<OrderDto> findById(
            @PathVariable Long id) {
        return orderService.findById(id)
            .map(HttpResponse::ok)
            .orElse(HttpResponse.notFound());
    }

    // GET /api/v1/orders?status=PAID&page=0
    @Get
    public Page<OrderDto> list(
            @QueryValue(defaultValue = "PENDING")
            String status,
            @QueryValue(defaultValue = "0")
            int page,
            @QueryValue(defaultValue = "20")
            int size) {
        return orderService.list(status, page, size);
    }

    // POST /api/v1/orders
    @Post
    @Status(HttpStatus.CREATED)
    public OrderDto create(
            @Valid @Body CreateOrderRequest request) {
        return orderService.create(request);
    }

    // PUT /api/v1/orders/{id}
    @Put("/{id}")
    public HttpResponse<OrderDto> update(
            @PathVariable Long id,
            @Valid @Body UpdateOrderRequest request) {
        return orderService.update(id, request)
            .map(HttpResponse::ok)
            .orElse(HttpResponse.notFound());
    }

    // Reactive streaming endpoint
    @Get("/stream")
    @Produces(MediaType.TEXT_EVENT_STREAM)
    public Publisher<OrderDto> streamOrders() {
        return orderService.streamNewOrders();
    }

    // Error handling for this controller
    @Error
    public HttpResponse<ErrorDto> onConstraintViolation(
            HttpRequest<?> request,
            ConstraintViolationException e) {
        return HttpResponse.badRequest(
            ErrorDto.from(e.getConstraintViolations()));
    }
}
```

> **Code walkthrough:** @Controller("/api/v1/orders")ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> sets the base path. The {id:\\d+} path pattern
> uses regex to constrain the path variable to digits
> only - enforced at compile-time route generation.
> @Status(CREATED) sets the default status code for
> POST. @Valid on @Body triggers bean validation before
> the method body runs. The streaming endpoint returns
> Publisher<OrderDto> with TEXT_EVENT_STREAM content
> type - Netty handles the async streaming without
> blocking a thread.

---

### 📘 Concept Explanation

**What it is:**

Micronaut HTTP routing maps incoming HTTP requests to
controller methods based on URL path patterns, HTTP methods,
and content types. Routes are compiled at build time into
an efficient lookup structure, not assembled at runtime.

**How it works:**

`@Controller("/api/users")` marks a class as handling all
requests under `/api/users`. Method-level annotations
specify the route:
- `@Get("/{id}")` - GET /api/users/{id}
- `@Post` - POST /api/users
- `@Put("/{id}")` - PUT /api/users/{id}
- `@Delete("/{id}")` - DELETE /api/users/{id}

Parameter binding (resolved at compile time):
- `@PathVariable String id` - from URL path `{id}`
- `@QueryValue Optional<String> filter` - from ?filter=
- `@Body UserRequest request` - from request body (JSON)
- `@Header("Authorization") String token` - from HTTP header

Return types:
- Plain POJO → serialized to JSON with 200 OK
- `HttpResponse<T>` → full control over status/headers
- `Mono<T>` (reactive) → async response

**Why it matters:**

Compile-time route compilation means: route conflicts are
detected at build time (not startup), routing is O(1)
(not linear scan), and route metadata is available for
documentation generation without running the app.

---

### 🎓 Answers by Seniority

**Junior:** "@Controller sets the path. @Get/@Post map
methods. @PathVariable, @QueryValue, @Body bind
parameters. Return HttpResponse<T> for full control."

**Senior:** "Regex constraints on path variables ({id:\\d+})
prevent bad requests from reaching the service layer.
Reactive return types (Publisher/Flux) keep the thread
free during I/O. @Error at method level handles
specific exceptions for this controller without polluting
the global error handler."

---

### ⚠️ Common Misconceptions

**Misconception 1: Path variable names in @Get("/{id}")
must match the Java parameter name.**

Micronaut resolves path variable binding by MATCHING the
name in the path template (`{id}`) to the parameter name
(`@PathVariable String id`) OR to `@PathVariable("id")`.
Without `@PathVariable`, Micronaut infers the binding from
the parameter name. With Java's default compilation (no
`-parameters` flag), parameter names may be stripped; add
`-parameters` to the Micronaut compiler plugin, or use
explicit `@PathVariable("id")` to avoid ambiguity. Without
either, path binding silently fails in some JVM versions.

**Misconception 2: @Controller classes must be stateless.**

Like Spring's `@RestController`, Micronaut `@Controller`
classes are `@Singleton` by default - one instance shared
across all requests. Mutable instance fields are a data race
in concurrent environments. However, INJECTED dependencies
(services, repositories) are safe if those dependencies are
themselves thread-safe singletons. The controller class itself
should be stateless (no request-specific instance variables)
even though it is a singleton.

**Misconception 3: Micronaut's @Controller automatically
handles CORS for all endpoints.**

CORS (Cross-Origin Resource Sharing) must be explicitly
configured in Micronaut. Without configuration, cross-origin
requests fail with browser CORS errors. Configure CORS in
`application.yml` under `micronaut.server.cors.configurations.*`.
Each configuration specifies allowed origins, methods, and
headers. Enabling `cors.single-header: true` is necessary
for some client configurations. CORS headers are NOT added
by `@Controller` automatically.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: 404 Not Found for controller endpoint
that should exist, with no error message.**

Symptom: `GET /api/users` returns 404 even though the
controller exists and the method appears correct. Root
cause: route not registered due to: package not under
application root (APT did not process it), wrong path
prefix combination (controller prefix + method path
concatenation mismatch), or HTTP method mismatch (annotated
`@Get` but called with `POST`). Diagnosis: enable route
logging (`micronaut.router=DEBUG`) at startup to list all
registered routes. Fix: check the logged routes match
the expected path; verify the controller is in an APT-
processed package.

**Failure Mode 2: @Body binding fails silently for
requests with URL-encoded form data.**

Symptom: controller `@Body UserRequest user` receives
a null or empty object when the client sends
`Content-Type: application/x-www-form-urlencoded`.
Root cause: `@Body` with a POJO attempts JSON deserialization;
URL-encoded form data requires `@Body Map<String, Object>` or
`@Part` parameter annotations. Diagnosis: log the raw
Content-Type header and body in a filter. Fix: use
`@Body Map<String, Object>` for form data; or add the
`micronaut-multipart` dependency and use `@Part` for
individual form fields.

**Failure Mode 3: Route conflict not detected at
build time causes one route to shadow another.**

Symptom: `GET /users/profile` returns the response for
`GET /users/{id}` (with id="profile") instead of the
dedicated profile endpoint. Root cause: both routes match
the URL but the parameterized route `{id}` is resolved
first. Diagnosis: list routes in debug mode to see
resolution order; test with a known numeric ID and the
"profile" path. Fix: restructure the API to use distinct
paths that cannot conflict (`/users/me/profile` vs
`/users/{id}`); Micronaut resolves static segments before
parameterized ones, but specific overlaps must be avoided
through API design.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Route annotations, parameter binding |
| Senior | 6 min | Regex paths, streaming, validation, compile-time routing |

---

**[SENIOR] Q1 - How does Micronaut handle content
negotiation for an endpoint that must return JSON
or XML based on Accept header?**

*Why they ask:* Content negotiation in production APIs.

Declare multiple @Produces:
```java
@Get("/{id}")
@Produces({
    MediaType.APPLICATION_JSON,
    MediaType.APPLICATION_XML
})
public OrderDto findById(@PathVariable Long id) {
    return orderService.findById(id);
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Micronaut matches the request Accept header to a
registered serializer. JSON: Jackson (or Micronaut
Serialization). XML: Jackson XML or Micronaut XML
module.

If Accept: application/xml is sent, the response is
XML-serialized. If Accept: application/json (or */*),
JSON is returned.

The serializer registration is compile-time (Micronaut
Serialization) or runtime (Jackson auto-detection).

*What separates good from great:* The serializer
registration mechanism (compile-time Micronaut
Serialization vs runtime Jackson).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Route annotations, parameter binding, streaming. |
| Hiring Manager | HTTP endpoints for REST APIs. |
| Bar Raiser | Compile-time routing, regex paths, content negotiation, streaming Publisher. |
| Peer Engineer | "The {id:\\d+} regex constraint caught a SQL injection attempt before it reached the service layer." |

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


# Micronaut Declarative HTTP Client

**Interview Weight:** medium - Declarative HTTP clients
are one of Micronaut's strongest features. Compile-time
generated client code eliminates boilerplate.

---

### 🎯 Model Answer

**30 seconds:**

> @Client annotation on an interface declares an HTTP
> client. Method signatures mirror the server API:
> @Get("/{id}") returns the expected type. Micronaut
> generates the client implementation at compile time.
> @Client supports: URL, service IDs (for service
> discovery), load balancing, retry, circuit breaker.
> No RestTemplate, no WebClient boilerplate - just
> an interface.

**3 minutes (Senior):**

> Declarative client patterns:
>
> @Client("http://orders-service"):
>   Fixed URL. Use for simple clients.
>
> @Client("orders-service"):
>   Service ID. Resolved via service discovery
>   (Consul, Kubernetes DNS, Eureka).
>   Client-side load balancing enabled.
>
> @Retryable: retries the method on failure.
> @CircuitBreaker: circuit breaker pattern.
> @Fallback: fallback class when circuit open.
>
> Reactive support:
>   Return Single<T>, Flux<T>, or Publisher<T>.
>   Micronaut HTTP client uses reactive Netty.
>   Non-blocking HTTP calls.
>
> Low-level HttpClient:
>   Inject HttpClient for imperative style.
>   .retrieve() for response body only.
>   .exchange() for HttpResponse<T>.
>   .toBlocking() for synchronous (avoid in prod).
>
> Request customization:
>   @RequestBean: bind POJO to request parameters.
>   Request filters: modify outgoing request
>     (add auth headers, tracing context).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Micronaut's
declarative HTTP client - how to call other services."

**(2) First principles:** "HTTP client = encode a request,
send it, decode the response. A declarative client
hides this machinery behind a Java interface."

**(3) Bridge:** "Micronaut's @Client interface is like
Feign (Spring Cloud) but compile-time generated.
The interface mirrors the server controller API."

---

### 💻 Code Example

```java
// Declarative client: matches server API shape
@Client("${service.inventory.url}")
public interface InventoryClient {

    @Get("/inventory/{productId}")
    Optional<InventoryDto> findByProduct(
        @PathVariable Long productId);

    @Post("/inventory/reserve")
    @Status(HttpStatus.CREATED)
    ReservationDto reserve(
        @Body ReserveRequest request);

    @Delete("/inventory/reservations/{id}")
    void cancel(@PathVariable String id);
}

// With service discovery (Kubernetes/Consul)
@Client(id = "inventory-service")
public interface InventoryClient {
    // Resolved via DNS: inventory-service.svc.cluster.local
    // Load balanced across multiple instances
    @Get("/inventory/{productId}")
    Single<InventoryDto> findByProduct(
        Long productId);  // Reactive - non-blocking
}

// With resilience
@Singleton
@Retryable(
    attempts = "3",
    delay = "500ms",
    multiplier = "2")  // exponential backoff
@CircuitBreaker(reset = "30s")
public interface InventoryClient {
    @Get("/inventory/{productId}")
    Optional<InventoryDto> findByProduct(
        Long productId);
}

// Fallback implementation
@Singleton
@Fallback
public class InventoryClientFallback
        implements InventoryClient {
    @Override
    public Optional<InventoryDto> findByProduct(
            Long productId) {
        // Return cached or default value
        return Optional.empty();
    }
}

// Low-level: HttpClient for custom requests
@Singleton
public class RawOrderClient {
    private final HttpClient client;

    RawOrderClient(
        @Client("https://external-api.example.com")
        HttpClient client) {
        this.client = client;
    }

    public Single<OrderDto> fetchOrder(Long id) {
        return client.retrieve(
            HttpRequest.GET("/orders/" + id)
                .header("X-API-KEY", apiKey),
            OrderDto.class);
    }
}
```

> **Code walkthrough:** The declarative client interfaceice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> is compiled to an implementation class at build time.
> @Client("${service.inventory.url}") resolves the URL
> from config. The reactive variant (Single<T>) makes
> non-blocking HTTP calls via Netty. @Retryable with
> multiplier implements exponential backoff - 500ms,
> 1000ms, 2000ms between retries. @Fallback provides
> the circuit-open behavior when @CircuitBreaker trips.

---

### 📘 Concept Explanation

**What it is:**

Micronaut's Declarative HTTP Client allows defining HTTP API
calls as Java interfaces with annotations, similar to OpenFeign
in Spring Cloud. The implementation (actual HTTP calls) is
generated at compile time by Micronaut's APT.

**How it works:**

```java
@Client("https://api.example.com")
interface UserClient {
    @Get("/users/{id}")
    User getUser(@PathVariable String id);

    @Post("/users")
    User createUser(@Body UserRequest request);
}
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Micronaut generates a concrete implementation of this
interface at compile time. The implementation uses Micronaut's
`HttpClient` internally. Inject `UserClient` like any other
Micronaut bean - no instantiation code needed.

Configuration: `@Client` can reference a service ID
(`@Client("user-service")`) which resolves via service
discovery (Consul, Eureka, Kubernetes). Or use a literal URL.

Reactive support: return `Mono<User>` or `Flowable<User>`
for non-blocking calls. Blocking return types are wrapped
automatically.

Retry and circuit breaker: combine `@Client` with
`@Retryable` and `@CircuitBreaker` annotations for
resilience policies.

**Why it matters:**

Generated at compile time: no runtime reflection, GraalVM
compatible. Built-in load balancing for service discovery.
Cleaner code than manually building HTTP requests.

---

### 🎓 Answers by Seniority

**Junior:** "@Client on an interface generates an HTTP
client. Methods with @Get/@Post call the matching
endpoint. Micronaut generates the implementation."

**Senior:** "Declarative clients + service ID + @Retryable +
@CircuitBreaker gives production-ready service-to-service
communication with minimal code. For non-blocking:
return Single<T> or Flux<T> - Micronaut uses reactive
Netty underneath. @Fallback provides graceful degradation
when the circuit opens."

---

### ⚠️ Common Misconceptions

**Misconception 1: @Client("http://...") always uses
the literal URL as the service endpoint.**

`@Client` with a literal URL uses that URL as a static
endpoint. But `@Client("user-service")` uses SERVICE
DISCOVERY to resolve the URL dynamically. In a Kubernetes
environment with Micronaut Kubernetes support, "user-service"
resolves to the in-cluster service DNS. With Consul enabled,
it queries Consul for service instances. Without service
discovery configured, `@Client("user-service")` fails at
startup with "Unknown host." Understand which mode your
client is using.

**Misconception 2: Declarative client methods can return
any Java type and it will be deserialized automatically.**

Automatic deserialization works for: simple POJOs (with
Jackson), `Map<String, Object>`, `List<T>` of simple types,
`HttpResponse<T>` for full response access, and reactive
types wrapping these. It does NOT work for: polymorphic
types without `@JsonTypeInfo` configuration, types with
constructor parameters and no default constructor (add
`@Introspected` + `@JsonCreator`), or types in third-party
JARs without Jackson annotations. Test your client with
actual API responses in integration tests.

**Misconception 3: HTTP client errors (4xx, 5xx) throw
exceptions automatically.**

By default, Micronaut's HTTP client throws `HttpClientResponseException`
for 4xx and 5xx responses. But the EXACT behavior depends on
the error response body format. If the server returns a 4xx
with a JSON body, Micronaut attempts to deserialize it; if
deserialization fails, the original `HttpClientResponseException`
is thrown. For 5xx responses, connection errors throw
different exception types. Write explicit error handling and
test each error case.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Declarative client fails at startup
with "No bean of type UserClient found."**

Symptom: startup fails when `UserClient` is injected in
another bean. Root cause: `UserClient` interface is not in
a package processed by APT; or the generated implementation
class is not being created because the `micronaut-http-client`
dependency is missing from the module's dependencies; or
`@Client` annotation is missing. Diagnosis: check if
`$UserClient$Intercepted.class` exists in build output.
Fix: add `implementation "io.micronaut:micronaut-http-client"`
to the module's dependencies; verify APT configuration.

**Failure Mode 2: Reactive client results in memory
leak because Publisher is never subscribed.**

Symptom: heap grows over time; network connections are
opened but never fully closed. Root cause: declarative client
returns `Mono<T>` or `Flowable<T>`, but the caller creates
the reactive type (triggering HTTP call) but never subscribes
to it (never reads the result). In reactive programming,
Publishers are lazy - they execute only when subscribed.
If the Publisher is created but discarded, the HTTP call
may open a connection and leak it. Diagnosis: connection
pool metrics show connections never returned to pool.
Fix: always subscribe to reactive client results; use
`block()` if synchronous behavior is needed in non-reactive
code.

**Failure Mode 3: Client follows redirects silently,
bypassing authentication headers.**

Symptom: authenticated API calls succeed initially but fail
after a service redirect; or sensitive data is sent to an
unexpected host due to redirect following. Root cause: HTTP
301/302 redirects are followed by default; the new request
may strip or re-include the `Authorization` header depending
on configuration. Diagnosis: enable HTTP client logging
(`micronaut.http.client=DEBUG`) to see redirect following.
Fix: configure `micronaut.http.client.follow-redirects: false`
for sensitive endpoints; or verify that the redirect
destination is in your expected domain before following.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | Service ID, reactive returns, Retryable, CircuitBreaker |
| Staff | 10 min | Load balancing, retry strategies, resilience patterns |

---

**[SENIOR] Q1 - How do you add authentication headers
to all outgoing requests from a Micronaut HTTP client?**

*Why they ask:* Cross-cutting concern on outgoing calls.

Implement HttpClientFilter:
```java
@Filter("/**")
@Client   // applies to client requests
public class AuthHeaderFilter
        implements HttpClientFilter {

    private final TokenProvider tokenProvider;

    AuthHeaderFilter(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @Override
    public Publisher<? extends HttpResponse<?>> doFilter(
            MutableHttpRequest<?> request,
            ClientFilterChain chain) {

        return chain.proceed(
            request.header(
                "Authorization",
                "Bearer " + tokenProvider.getToken()
            )
        );
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using authentication. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

The filter intercepts ALL outgoing client requests
matching "/**". Adds the Bearer token header before
forwarding. Non-blocking (returns Publisher chain).

Scope to specific client: @Filter annotate the specific
@Client interface instead of /**. 

*What separates good from great:* @Filter as the
non-blocking interceptor chain (not a synchronous
filter).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Client declaration, compile-time generation. |
| Hiring Manager | Declarative clients = less boilerplate for service calls. |
| Bar Raiser | Service discovery, circuit breaker, @Fallback, HttpClientFilter. |
| Peer Engineer | "Declarative client + @Retryable replaced 200 lines of RestTemplate code with 20 lines." |

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


# Micronaut Reactive HTTP

**Interview Weight:** medium - Reactive HTTP is
critical for high-throughput Micronaut services.
Tested for when and how to use reactive types.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut's HTTP server is Netty-based (async, non-blocking).
> Controller methods can return reactive types: Single<T>
> (RxJava) or Mono<T> (Reactor) for single response,
> Flowable<T> or Flux<T> for streaming. Micronaut
> subscribes to the reactive pipeline on an I/O thread
> and writes the response asynchronously. No thread
> blocking during I/O. Use reactive return types when
> the service layer is reactive (e.g., R2DBC, reactive
> HTTP client calls).

**3 minutes (Senior):**

> Reactive types supported:
>
> RxJava 3: Single<T>, Maybe<T>, Flowable<T>, Completable
> Project Reactor: Mono<T>, Flux<T>
> Java 9+: CompletableFuture<T>, CompletionStage<T>
>
> Response behavior:
> Single<T> / Mono<T>: 200 response when resolved.
>   Empty: 404 or empty body depending on type.
> Flowable<T> / Flux<T>: streaming response.
>   JSON array: application/json (buffered)
>   SSE: application/x-ndjson or text/event-stream
>
> Thread model:
> Incoming request: Netty event loop thread
> Non-blocking controller: stays on event loop
> Blocking controller: offloaded to @Blocking thread pool
>   (@Blocking annotation or reactive subscribeOn)
>
> @Blocking annotation:
>   @Get("/{id}")
>   @Blocking
>   public OrderDto findById(Long id) {
>     // Runs on scheduled executor, not event loop
>     // Use for blocking I/O (JDBC, synchronous calls)
>   }
>
> Best practice:
>   Return reactive types when the source is reactive.
>   Use @Blocking for legacy blocking code.
>   Never block the Netty event loop thread
>   (Thread.sleep, JDBC on event loop = performance problem).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about reactive HTTP
in Micronaut - non-blocking request handling."

**(2) First principles:** "Non-blocking = don't waste
a thread waiting for I/O. Reactive = describe what to
do when data arrives. Micronaut runs the whole pipeline
without blocking."

**(3) Bridge:** "Reactive Micronaut is like a relay
race: each non-blocking operation passes the baton
to the next without waiting. Blocking code stops and
waits at each step."

---

### 💻 Code Example


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: Blocking code on Netty event loop
@Get("/{id}")
public OrderDto findById(@PathVariable Long id) {
    // JDBC call on event loop thread!
    // Blocks the event loop
    // Under load: event loop thread busy,
    // new requests wait
    return orderRepository.findById(id)
        .orElseThrow(NotFoundException::new);
}

// GOOD: Non-blocking with reactive repository
@Get("/{id}")
public Single<HttpResponse<OrderDto>> findById(
        @PathVariable Long id) {
    return orderService.findById(id)  // Returns Single
        .map(HttpResponse::ok)
        .defaultIfEmpty(HttpResponse.notFound());
    // Event loop free during DB I/O
}

// GOOD: @Blocking for legacy JDBC
@Get("/{id}")
@Blocking  // Offloads to worker thread pool
public HttpResponse<OrderDto> findById(
        @PathVariable Long id) {
    // Runs on executor, not event loop
    // Safe for blocking JDBC
    return orderService.findById(id)
        .map(HttpResponse::ok)
        .orElse(HttpResponse.notFound());
}

// Streaming: Flux<T> for multiple items
@Get("/stream")
@Produces(MediaType.APPLICATION_NDJSON)
public Flux<OrderDto> streamOrders(
        @QueryValue String status) {
    return orderService.streamByStatus(status);
    // Each OrderDto emitted as a separate JSON line
    // Client receives chunked response
}

// Combining reactive chains
@Post("/process")
public Single<ProcessResult> processOrder(
        @Body @Valid ProcessRequest req) {

    return inventoryClient
        .checkStock(req.getProductId())  // HTTP client call
        .flatMap(stock -> {
            if (!stock.isAvailable()) {
                return Single.error(
                    new StockException());
            }
            return paymentClient
                .charge(req.getPayment());  // HTTP call
        })
        .flatMap(payment ->
            orderService.create(req, payment));
    // All async - no thread blocking
}
```

> **Code walkthrough:** The BAD case calls JDBC onice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> the Netty event loop - blocks the I/O thread, degrades
> throughput. @Blocking offloads to a worker thread pool
> (safe for JDBC). The reactive version returns Single<T>
> from a reactive repository - the event loop subscribes
> and continues when data arrives. The combined reactive
> chain (checkStock → charge → create) runs entirely
> non-blocking via flatMap composition.

---

### 📘 Concept Explanation

**What it is:**

Micronaut Reactive HTTP is the pattern of writing HTTP
controllers and clients that use reactive programming models
(Reactive Streams: `Publisher<T>`, `Mono<T>`, `Flux<T>`)
to handle concurrent requests without blocking threads.

**How it works:**

Micronaut's Netty server is non-blocking. A controller method
returning a reactive type tells Micronaut: "don't wait for
this result on the current thread; send the response when
the publisher completes."

```java
@Get("/{id}")
Mono<User> getUser(String id) {
    return userRepository.findById(id);  // non-blocking DB call
}
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Execution: Netty I/O thread calls `getUser`, gets a `Mono`
back immediately (not the result), and becomes free to handle
other requests. When the DB call completes (on a DB I/O
thread), the `Mono` emits the result. Micronaut's response
writer subscribes to the `Mono` and writes the response bytes
to the network.

Supported reactive libraries: Project Reactor (`Mono`/`Flux`),
RxJava 2/3 (`Single`/`Observable`/`Flowable`), JDK 9+
`Flow.Publisher`.

**Why it matters:**

One Netty I/O thread can handle thousands of in-flight
requests concurrently (while they wait for I/O). Without
reactive, each blocking request ties up one thread.

---

### 🎓 Answers by Seniority

**Junior:** "Return Mono<T> or Single<T> from controller
methods for non-blocking response. @Blocking annotation
for methods that call blocking JDBC."

**Senior:** "Never block the Netty event loop. Two
options: reactive all the way (reactive DB + reactive
client), or @Blocking for legacy JDBC code. @Blocking
uses a separate thread pool - doesn't block the event
loop but still occupies a thread. For true non-blocking:
R2DBC reactive database + reactive HTTP client chain."

---

### ⚠️ Common Misconceptions

**Misconception 1: Reactive programming automatically
makes an application faster for all workloads.**

Reactive HTTP is faster under HIGH CONCURRENCY with I/O-bound
operations. For CPU-bound operations or low-concurrency
scenarios, reactive adds overhead (scheduler context
switching, operator chain overhead) with no benefit. A
sequential batch processing job that does CPU-heavy work
is NOT faster in reactive mode - it may be slower. Use
reactive for: high-concurrency API gateways, streaming
responses, parallel fanout requests to multiple services.

**Misconception 2: You can block inside a reactive chain
if you execute it on a different thread.**

Blocking inside a reactive chain (even on a dedicated thread)
can cause issues: the Netty event loop cannot be blocked ever
(even indirectly), and blocking a reactor scheduler thread
defeats the purpose of the reactive model. The CORRECT
pattern: use `Mono.fromCallable(() -> blockingOperation()
).subscribeOn(Schedulers.boundedElastic())` to explicitly
execute blocking code on a bounded-elastic thread pool
designed for blocking operations. Never block on the default
reactor or Netty scheduler.

**Misconception 3: Reactive HTTP clients and blocking
HTTP clients are interchangeable in Micronaut.**

Reactive clients (returning `Mono<T>`) and blocking clients
(returning `T` directly) have different characteristics.
Reactive clients do not block; they compose with the
reactive pipeline. Blocking clients MUST run on blocking
thread pools (not event loops). Mixing blocking HTTP client
calls in a reactive pipeline without `subscribeOn(Schedulers.
boundedElastic())` will block the event loop and cause
cascading failures under load.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Event loop blocked by blocking
reactive operation causes request queuing and timeouts.**

Symptom: under load, response times increase linearly with
request rate; thread dump shows all Netty worker threads in
WAITING state. Root cause: controller or reactive chain is
calling a blocking operation (JDBC, Thread.sleep, blocking
HTTP) on the Netty event loop thread. Diagnosis: thread dump
during load test; look for Netty worker threads (`reactor-http-nio-*`)
in WAITING or TIMED_WAITING states waiting for locks/I/O.
Fix: annotate controller with `@ExecuteOn(TaskExecutors.IO)`
or wrap blocking calls in `Mono.fromCallable().subscribeOn
(Schedulers.boundedElastic())`.

**Failure Mode 2: Reactive stream never completes because
error handling missing - request hangs indefinitely.**

Symptom: some HTTP requests never receive a response; they
hang until client timeout. Root cause: reactive chain has
no error handling; an exception causes the stream to error,
but without `onErrorResume` or `onErrorReturn`, the error
is not converted to an HTTP response. Micronaut may not
always catch unhandled reactive errors. Diagnosis: add
`doOnError(e -> log.error("...", e))` to the reactive chain.
Fix: always add `.onErrorResume(e -> Mono.just(errorResponse(e)))`
or handle errors in the reactive chain.

**Failure Mode 3: Backpressure not applied causes
memory overflow when consuming streaming endpoints.**

Symptom: application runs out of memory when consuming a
streaming response (`Flux<Event>`) faster than it can
process events. Root cause: the reactive consumer does not
implement backpressure - it requests `Long.MAX_VALUE` events
(unbounded demand), overwhelmed by the source publishing
events faster than they can be consumed. Diagnosis: heap dump
shows event objects accumulating in the reactive buffer.
Fix: apply backpressure operators: `limitRate(N)` on the
`Flux`, `bufferTimeout`, or use `flatMap` with `concurrency`
limit instead of unlimited parallel processing.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | @Blocking, reactive chain, event loop model |
| Staff | 10 min | Thread model, R2DBC, backpressure |

---

**[SENIOR] Q1 - What is backpressure and how does
Micronaut handle it in streaming endpoints?**

*Why they ask:* Reactive programming production knowledge.

Backpressure: the consumer signals to the producer
"slow down, I can't keep up." Without backpressure,
a fast producer overwhelms a slow consumer (buffer
overflow, OOM).

Micronaut's Netty HTTP server handles backpressure for
streaming endpoints:
- Flux<T>/Flowable<T> streaming responses
- Netty applies TCP backpressure: when the client's
  TCP buffer is full, Netty signals the Flux to pause
- The Flux (backed by a reactive DB or message queue)
  pauses emission
- When client consumes more, the signal propagates back

In practice:
```java
// Backpressure-aware streaming
@Get("/export")
@Produces(MediaType.APPLICATION_NDJSON)
public Flux<OrderDto> exportOrders() {
    return orderRepository.findAll()
        // Flux.fromStream() is NOT backpressure-safe
        // Use reactive repository (R2DBC) instead:
        // Returns backpressure-aware Publisher
        .onBackpressureBuffer(1000)  // buffer up to 1000
        .onBackpressureDrop(dropped ->
            log.warn("Dropped: {}", dropped));
}
```

> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

For file downloads or large exports: consider chunking
and cursor-based streaming rather than loading all
into memory.

*What separates good from great:* onBackpressureBuffer
and TCP propagation as the implementation of backpressure.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Reactive types, @Blocking, event loop model. |
| Hiring Manager | Reactive = high throughput without more hardware. |
| Bar Raiser | Backpressure, R2DBC, event loop blocking consequences. |
| Peer Engineer | "Adding @Blocking to our JDBC endpoints was a 3-line fix. Throughput doubled immediately." |

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


# Micronaut Server Filters and Middleware

**Interview Weight:** medium - Server filters handle
cross-cutting HTTP concerns (auth, logging, CORS).
Tested for filter implementation and ordering.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut HttpServerFilter intercepts HTTP requests
> before they reach controllers and responses before
> they're sent to clients. Annotate with @Filter("/path/**")
> to apply to matching paths. Implement doFilter()
> returning a reactive publisher chain. Multiple filters
> chain via filterOrder. Built-in: Security filter,
> CORS filter, rate limiting via annotations. Custom
> filters: request logging, tenant resolution, header
> injection.

**3 minutes (Senior):**

> Filter implementation:
>
> @Filter: applies to URL pattern
> @Filter("/**"): all requests
> @Filter("/api/**"): only /api/* paths
> @Filter(patterns="/api/**", methods=GET): specific methods
>
> HttpServerFilter interface:
>   Publisher<MutableHttpResponse<?>> doFilter(
>     HttpRequest<?> request,
>     ServerFilterChain chain)
>
> chain.proceed(request): passes to next filter.
> Modify request before proceed: add headers, validate.
> Modify response after proceed: add response headers.
>
> Filter ordering: implement Ordered interface.
>   Ordered.HIGHEST_PRECEDENCE: first
>   Ordered.LOWEST_PRECEDENCE: last
>
> Built-in filter integration:
>   Security: token validation filter at high priority
>   CORS: cors filter runs before route matching
>   Rate limiting: @RequestRateLimit annotation
>
> Reactive chain: return Publisher chain.
>   Request modification: chain.proceed(modifiedRequest)
>   Response modification: .map() on the response publisher

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about HTTP filters in
Micronaut - middleware that runs before/after controllers."

**(2) First principles:** "Every HTTP request and response
passes through a middleware chain. Filters = each link
in the chain."

**(3) Bridge:** "Micronaut server filters are like Spring
HandlerInterceptor but reactive and non-blocking."

---

### 💻 Code Example

```java
// Request logging filter
@Filter("/**")
public class RequestLoggingFilter
        implements HttpServerFilter {

    private static final Logger log =
        LoggerFactory.getLogger(
            RequestLoggingFilter.class);

    @Override
    public Publisher<MutableHttpResponse<?>> doFilter(
            HttpRequest<?> request,
            ServerFilterChain chain) {

        long start = System.currentTimeMillis();
        String requestId = UUID.randomUUID()
            .toString().substring(0, 8);

        log.info("[{}] {} {}",
            requestId,
            request.getMethod(),
            request.getPath());

        return chain.proceed(
            // Add request ID header for downstream
            request.mutate()
                .header("X-Request-Id", requestId)
        ).map(response -> {
            long duration =
                System.currentTimeMillis() - start;
            log.info("[{}] {} {}ms",
                requestId,
                response.getStatus().getCode(),
                duration);
            // Add header to response
            response.header(
                "X-Request-Id", requestId);
            return response;
        });
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 10;
        // Run early, after security filter
    }
}

// Tenant resolution filter
@Filter("/api/**")
public class TenantFilter
        implements HttpServerFilter {

    @Override
    public Publisher<MutableHttpResponse<?>> doFilter(
            HttpRequest<?> request,
            ServerFilterChain chain) {

        String tenantId = request
            .getHeaders()
            .get("X-Tenant-Id");

        if (tenantId == null) {
            return Publishers.just(
                HttpResponse.badRequest(
                    "X-Tenant-Id header required"));
        }

        // Store in request attributes
        return chain.proceed(
            request.setAttribute(
                "tenantId", tenantId));
    }
}
```

> **Code walkthrough:** The logging filter wraps theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> chain.proceed() in a reactive map - response modification
> happens inside map() on the returned publisher. Mutating
> the request (adding a header) before chain.proceed()
> passes the modified request downstream. The tenant
> filter returns an error response without calling
> chain.proceed() if the header is missing - short-circuits
> the chain. The filter order ensures logging filter
> runs after security (HIGHEST_PRECEDENCE is lowest
> number = first).

---

### 📘 Concept Explanation

**What it is:**

Micronaut Server Filters (also called HTTP Filters) are
components that intercept HTTP requests and responses before
they reach controllers (request filters) or after controllers
produce responses (response filters). They implement
cross-cutting HTTP concerns: authentication, rate limiting,
request logging, response compression, correlation ID injection.

**How it works:**

Implement `HttpServerFilter` or annotate a method with
`@Filter` + pattern:

```java
@Filter("/api/**")
@Singleton
class AuthFilter implements HttpServerFilter {
    @Override
    Publisher<MutableHttpResponse<?>> doFilter(
        HttpRequest<?> request, ServerFilterChain chain) {
        // Check auth header
        if (!isAuthorized(request)) {
            return Mono.just(HttpResponse.unauthorized());
        }
        return chain.proceed(request);  // Continue to controller
    }
}
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Filters are ordered by `@Order` annotation. The filter chain
is: inbound filters (in order) → controller → outbound filters
(in reverse order). Filters can short-circuit (return early)
without calling `chain.proceed()`.

**Why it matters:**

Centralizes cross-cutting HTTP concerns. Prevents duplicated
authentication code across controllers. Enables middleware-
style composition similar to Express.js or ASP.NET middleware.

---

### 🎓 Answers by Seniority

**Junior:** "@Filter applies a filter to matching paths.
chain.proceed() forwards to the next filter or controller.
Modify request before proceed, modify response after."

**Senior:** "Filters are reactive: doFilter returns a
Publisher chain. Mutate request via request.mutate()
before chain.proceed(). Modify response via .map() on
the result. getOrder() controls execution sequence.
Short-circuit (return error) without chain.proceed()
for authentication failures."

---

### ⚠️ Common Misconceptions

**Misconception 1: @Filter with a pattern applies to ALL
requests matching the pattern, including error responses.**

`@Filter` applies to the inbound request path. If a controller
throws an exception and Micronaut serves an error response,
the filter IS invoked for the original request but the
response transformation in the filter may not apply to
error responses returned via `@Error` handlers. Filters
that need to process error responses should check the
response status in their response handling logic.

**Misconception 2: Filters and AOP interceptors are
equivalent and interchangeable.**

Filters operate at the HTTP layer (before routing) and can
access raw `HttpRequest`/`HttpResponse` objects, URL paths,
and HTTP headers. AOP interceptors operate at the Java method
level after routing occurs and can access method parameters
and return types. They are complementary: use filters for
HTTP-level concerns (authentication, rate limiting, CORS);
use AOP for method-level concerns (transaction, caching,
retry).

**Misconception 3: Calling chain.proceed() multiple times
in a filter processes the request twice.**

`chain.proceed()` returns a `Publisher`. Calling it creates
a Publisher that represents the remaining filter chain
execution. If you subscribe to it twice (call `subscribe()` or
`block()` twice), the request may be processed twice. In
reactive filters, always subscribe to `chain.proceed()` only
once within the filter logic. Using `flatMap` rather than
`subscribe()` ensures single subscription.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Filter executes but cannot modify
request body because body is streamed.**

Symptom: filter reads `request.getBody(String.class)` to
inspect or modify the request body, but subsequent processing
receives an empty body. Root cause: reading the request body
consumes the underlying input stream; subsequent components
(other filters, controller binding) cannot read it again.
Diagnosis: add logging before and after body read; check
if the controller receives an empty body. Fix: use
`request.getBody(byte[].class)` and then re-create a new
request with the bytes re-set; Micronaut provides utilities
for request body caching in filters.

**Failure Mode 2: Filter pattern "/api/**" does not
match "/api" (without trailing slash).**

Symptom: requests to `/api` bypass the authentication filter
while `/api/users` is correctly filtered. Root cause: the Ant
path pattern `/api/**` matches `/api/anything` but not `/api`
(the empty path after `/api/`). Diagnosis: test with exact
URL `/api` (no trailing slash or path segment). Fix: use
`/api*` or specify both `/api` and `/api/**` as patterns;
or implement the filter matching logic to handle root paths
explicitly.

**Failure Mode 3: Filter-added request attributes not
available in downstream controller.**

Symptom: security principal set by an auth filter via
`request.setAttribute("principal", user)` is not available
when `@Controller` method accesses `HttpRequest.getAttribute()`.
Root cause: some Micronaut versions or filter configurations
create a new request wrapper for each filter, potentially
losing attributes set on the previous wrapper. Diagnosis:
log the request identity (object hashCode) at each filter
and the controller. Fix: use Micronaut's `ServerRequestContext.
currentRequest()` for cross-thread context; or use a thread-
local propagation mechanism for security contexts.

---

### 🎯 Interview Deep-Dive

| Experience| Time| Depth|
|----------|-----|------------------------------------------------------|
| Senior| 5 min| Filter implementation, chain.proceed, ordering|
| Staff| 8 min| Reactive chain, request mutation, security integration|

---

**[SENIOR] Q1 - How do you share data between a filter
and a controller in Micronaut?**

*Why they ask:* Cross-cutting data passing pattern.

Use request attributes:
```java
// In filter:
chain.proceed(
    request.setAttribute("tenantId", tenantId)
)

// In controller:
@Get("/{id}")
public OrderDto findById(
        @PathVariable Long id,
        HttpRequest<?> request) {

    String tenantId = request
        .getAttribute("tenantId", String.class)
        .orElseThrow(() -> new IllegalStateException(
            "TenantFilter must run first"));

    return orderService.findByIdAndTenant(
        id, tenantId);
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using gice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Alternatively, use @RequestScope beans:
```java
@RequestScope
public class RequestContext {
    private String tenantId;
    // Set by filter, read by service
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Filter sets requestContext.setTenantId(tenantId).
Controller or service injects @RequestScope RequestContext.
Shared for the lifetime of the HTTP request.

*What separates good from great:* @RequestScope as the
clean DI-based approach vs raw request attributes.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Filter, doFilter, chain.proceed. |
| Hiring Manager | Filters for cross-cutting concerns (logging, auth, CORS). |
| Bar Raiser | Reactive chain, request mutation, @RequestScope for data sharing. |
| Peer Engineer | "Our tenant filter sets a @RequestScope TenantContext. Zero coupling between filter and service." |

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


# Micronaut Service Discovery

**Interview Weight:** medium - Service discovery is
essential for Micronaut in Kubernetes and Consul.
Tested for client-side vs server-side discovery and
configuration.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut supports client-side service discovery:
> @Client("service-id") resolves the service URL
> through a discovery registry (Consul, Eureka, or
> Kubernetes DNS). In Kubernetes, Micronaut uses DNS
> service names (service.namespace.svc.cluster.local).
> With Consul: the service registers itself and queries
> for others. Load balancing is client-side round-robin
> by default.

**3 minutes (Senior):**

> Service discovery options:
>
> Kubernetes DNS (most common for k8s):
>   micronaut.http.services.orders.url:
>     http://orders-service
>   Kubernetes DNS resolves "orders-service" to the
>   ClusterIP. No special registration - Kubernetes
>   handles it.
>
> Consul:
>   micronaut.consul.client.registration.enabled: true
>   App registers on startup, deregisters on shutdown.
>   @Client("inventory-service") queries Consul for
>   healthy instances.
>
> Eureka (Netflix):
>   micronaut.discovery.eureka.registration.enabled: true
>   Netflix OSS-compatible registration.
>
> Manual configuration:
>   micronaut.http.services.orders.urls:
>     - http://orders-1:8080
>     - http://orders-2:8080
>   Client round-robins across the list.
>
> @LoadBalanced:
>   Applies load balancing to a manually configured
>   list or discovery results.
>   Default: round-robin.
>   Custom: implement LoadBalancer interface.
>
> Health-aware routing:
>   Consul/Eureka: only routes to healthy instances.
>   Kubernetes: kube-proxy handles health-based routing.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about service discovery
in Micronaut - how services find each other."

**(2) First principles:** "Services have dynamic IPs.
Service discovery maps a stable name to dynamic IPs.
Client resolves the name before making the call."

**(3) Bridge:** "Service discovery is like a phone
book: you look up 'inventory-service' and get the
current IP. Kubernetes DNS is the phone book. Consul
is a programmable phone book with health checks."

---

### 📘 Concept Explanation

**What it is:**

Service Discovery is the mechanism by which a Micronaut
service locates other services by logical name rather than
hard-coded URLs. Micronaut integrates with multiple service
registry backends: Consul, Eureka, Kubernetes DNS, and
AWS ELB/ECS.

**How it works:**

Registration: at startup, Micronaut registers the service
with the configured registry (Consul PUT request with service
ID, address, port, health check URL). Deregistration happens
on shutdown.

Discovery: `@Client("user-service")` triggers a lookup in
the registry before making HTTP calls. The resolved URL
changes as instances come and go. Client-side load balancing
distributes requests across healthy instances using the
`LoadBalancer` interface (default: round-robin).

Kubernetes mode: Micronaut discovers services via Kubernetes
DNS (`http://user-service.namespace.svc.cluster.local`).
No registry is needed - Kubernetes DNS is the source of truth.

Health filtering: only HEALTHY service instances (health check
passing in Consul) are included in the discovery results.
Failed health checks remove instances from the pool.

**Why it matters:**

Eliminates hard-coded service URLs from configuration.
Enables zero-downtime deployments (deregister before stopping).
Provides automatic load distribution across instances.

---

### 🎓 Answers by Seniority

**Junior:** "@Client with a service name instead of a URL
triggers service discovery. Micronaut looks up the
service in the configured registry."

**Senior:** "For Kubernetes: just use the Kubernetes
service name. Kubernetes DNS handles discovery natively.
No Consul or Eureka needed. For multi-cluster or
hybrid: Consul provides cross-cluster discovery with
health-check integration."

---

### ⚠️ Common Misconceptions

**Misconception 1: Service discovery and load balancing
eliminate the need for a Kubernetes Service resource.**

In Kubernetes, Micronaut's service discovery and Kubernetes
Service resources serve complementary purposes. Kubernetes
Services provide stable DNS names and stable cluster-IP
addresses. Micronaut's service discovery provides CLIENT-
SIDE load balancing and health-aware routing. In most
Kubernetes deployments, you want BOTH: Kubernetes Service
for cluster networking, and either Micronaut discovery
or a service mesh for advanced load balancing. Using only
Micronaut discovery in Kubernetes bypasses Kubernetes' own
health checking and service routing.

**Misconception 2: Consul health checks automatically
remove unhealthy pods from the service mesh.**

Consul health checks update the service's health status in
Consul's registry. Micronaut's service discovery will stop
routing to unhealthy instances. BUT: there is a delay between
a pod becoming unhealthy and Consul marking it as failed
(depends on health check interval and retry configuration).
During this window, requests may still be sent to the
unhealthy pod. Design for this: implement circuit breakers
(`@CircuitBreaker`) as a complementary resilience pattern.

**Misconception 3: Micronaut auto-registers with service
discovery in any cloud environment.**

Auto-registration requires explicit configuration. Micronaut
does not automatically register with Consul or Eureka without
enabling the integration: `consul.client.registration.enabled:
true` or `eureka.client.registration.enabled: true`. In
Kubernetes, the Micronaut Kubernetes integration must be
configured. Without explicit registration, `@Client("service-name")`
will fail with "No instances of service [name] available."

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Service discovery flapping causes
intermittent request failures during deployments.**

Symptom: during rolling deployments, a percentage of requests
fail with "No instances available" or connection refused.
Root cause: old instances are deregistered and new instances
are not yet registered (or not yet healthy), creating a window
with no available instances. Diagnosis: monitor Consul's
service instance count during deployments. Fix: implement a
pre-registration health check that ensures the new instance
passes its own health check before the deployment proceeds;
use Kubernetes readiness probes to delay registration until
the pod is ready; use `@CircuitBreaker` to handle temporary
unavailability.

**Failure Mode 2: Stale service instances remain in
Consul after pod crashes (no graceful shutdown).**

Symptom: service discovery returns instances that no longer
exist; HTTP requests to those instances timeout. Root cause:
crashed pods cannot send Consul deregistration; TTL-based
health checks mark them as failed eventually, but the window
of stale instances can be minutes. Diagnosis: compare Consul
service instances with running Kubernetes pods. Fix: configure
shorter Consul health check intervals and fail threshold
(TTL: 30s, deregister-critical-service-after: 1m); use
Consul's TTL-based health (pod must send heartbeat) rather
than HTTP health check (more reliable for crash detection).

**Failure Mode 3: Client-side load balancing does not
recover after a transient service outage.**

Symptom: after all instances of a downstream service
temporarily fail and then recover, the client continues
returning errors even after healthy instances are available.
Root cause: `@CircuitBreaker` opened during the outage and
has not yet entered the half-open state to test recovery.
Diagnosis: monitor circuit breaker state metrics. Fix: tune
circuit breaker reset timeout (`reset: 5s`) to match expected
recovery time; implement health check feedback to actively
close the circuit when health checks pass.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Service ID in @Client, Kubernetes DNS |
| Senior | 6 min | Consul vs Kubernetes, health-aware routing, load balancing |

---

**[SENIOR] Q1 - What happens to a Micronaut service
when a Consul health check fails?**

*Why they ask:* Production resilience knowledge.

Consul health checks: each service registers with a
health endpoint (e.g., /health). Consul polls it every
10s. If the check fails:
1. Consul marks the service instance as unhealthy.
2. @Client("service-id") resolving against Consul
   receives only healthy instances.
3. Traffic no longer routed to the failing instance.

Micronaut integration:
- micronaut-consul with registration.enabled=true
- Micronaut registers the /health endpoint
- Consul polls it
- Instance removed from routing on failure

Gap: there's a propagation delay (10s poll interval).
Requests may still reach a failing instance for up to
10s. @Retryable on the client mitigates this.

```yaml
micronaut:
  discovery:
    consul:
      registration:
        health-path: /health
        check-interval: 10s
        deregister-critical-service-after: 3m
```

> **Code walkthrough:** This Unknown example demonstrates YAML configuration pattern. **KEY MECHANISM:** YAML parsers are whitespace-sensitive; indentation errors cause silent value misinterpretation. **WHY IT MATTERS:** unquoted strings starting with special chars (*, &, ?, |) trigger YAML parser errors. **TAKEAWAY: quote strings containing YAML special chars; validate YAML before deploying to production.**

*What separates good from great:* Health check propagation
delay and @Retryable as the mitigation.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Service discovery config, @Client with service ID. |
| Hiring Manager | Service discovery enables dynamic Kubernetes scaling. |
| Bar Raiser | Health check propagation delay, @Retryable mitigation, Consul vs Kubernetes DNS. |
| Peer Engineer | "We pair @Retryable(attempts=2) on all client calls. Handles the 10-second Consul health check lag." |

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



