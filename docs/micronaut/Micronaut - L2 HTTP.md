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

> **Code walkthrough:** @Controller("/api/v1/orders")
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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** The declarative client interface
> is compiled to an implementation class at build time.
> @Client("${service.inventory.url}") resolves the URL
> from config. The reactive variant (Single<T>) makes
> non-blocking HTTP calls via Netty. @Retryable with
> multiplier implements exponential backoff - 500ms,
> 1000ms, 2000ms between retries. @Fallback provides
> the circuit-open behavior when @CircuitBreaker trips.

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** The BAD case calls JDBC on
> the Netty event loop - blocks the I/O thread, degrades
> throughput. @Blocking offloads to a worker thread pool
> (safe for JDBC). The reactive version returns Single<T>
> from a reactive repository - the event loop subscribes
> and continues when data arrives. The combined reactive
> chain (checkStock → charge → create) runs entirely
> non-blocking via flatMap composition.

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** The logging filter wraps the
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

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Filter implementation, chain.proceed, ordering |
| Staff | 8 min | Reactive chain, request mutation, security integration |

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Alternatively, use @RequestScope beans:
```java
@RequestScope
public class RequestContext {
    private String tenantId;
    // Set by filter, read by service
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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



