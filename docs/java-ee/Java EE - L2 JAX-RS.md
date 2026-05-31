---
layout: default
title: "Java EE - L2 JAX-RS"
parent: "Java EE"
nav_order: 4
permalink: /java-ee/l2-jax-rs/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 10 | [JAX-RS REST Services](#jax-rs-rest-services) | ★★☆ |
| 11 | [JAX-RS Filters and Interceptors](#jax-rs-filters-and-interceptors) | ★★☆ |

---

# JAX-RS REST Services

**Interview Weight:** ★★☆ - Working. JAX-RS is the
standard Jakarta EE REST API. Every senior Java EE
engineer must be fluent in resource design, exception
handling, content negotiation, and async patterns.

---

### 🎯 Model Answer

**30 seconds:**

> JAX-RS (Jakarta RESTful Web Services) is the Jakarta EE
> specification for building REST APIs. You annotate
> plain Java classes with `@Path`, `@GET`/`@POST`/etc.,
> `@Produces`, `@Consumes`. Parameters come from the
> URL (`@PathParam`), query string (`@QueryParam`),
> headers (`@HeaderParam`), or the request body (auto-deserialized
> by a `MessageBodyReader`). Responses use `Response.ok(entity).build()`
> or return the entity directly. `ExceptionMapper<T>` maps
> exceptions to HTTP status codes.

**3 minutes:**

> JAX-RS maps HTTP semantics to Java annotations:
>
> Resource class:
> ```java
> @Path("/orders")          // base path
> @Produces(APPLICATION_JSON)
> @Consumes(APPLICATION_JSON)
> @RequestScoped            // CDI scope
> public class OrderResource {...}
> ```
>
> HTTP methods:
> - `@GET`: read, no body, idempotent
> - `@POST`: create, has body, not idempotent
> - `@PUT`: replace, has body, idempotent
> - `@PATCH`: partial update
> - `@DELETE`: remove, idempotent
>
> Parameter injection:
> - `@PathParam("id")` -> `/orders/{id}`
> - `@QueryParam("page")` -> `?page=1`
> - `@HeaderParam("X-Correlation-Id")` -> request header
> - Method parameter without annotation -> request body
>
> Response building:
> ```java
> return Response.ok(entity).build();          // 200
> return Response.status(201).entity(e).build(); // 201
> return Response.noContent().build();          // 204
> return Response.status(404).build();          // 404
> ```
>
> Application bootstrap:
> ```java
> @ApplicationPath("/api")
> public class RestApplication
>         extends Application { }
> ```
>
> Exception handling:
> ```java
> @Provider
> public class NotFoundMapper
>         implements ExceptionMapper<NotFoundException> {
>     public Response toResponse(NotFoundException ex) {
>         return Response.status(404)
>             .entity(Map.of("error", ex.getMessage()))
>             .build();
>     }
> }
> ```
>
> The key insight: JAX-RS is implemented by the app
> server (RESTEasy in WildFly, Jersey in GlassFish/Payara,
> CXF in Liberty). Quarkus uses RESTEasy Reactive.
> These implementations share the JAX-RS spec but
> have provider-specific extensions.

**Blank Mind Recovery:**

**(1) Restate:** "@Path, @GET/@POST/@PUT/@DELETE, @Produces,
@Consumes, @PathParam, @QueryParam. Response.ok(entity).build().
ExceptionMapper for error handling."

**(2) First principles:** "REST maps HTTP verbs to CRUD.
JAX-RS maps HTTP verbs to Java methods via annotations."

**(3) Bridge:** "Same as Spring MVC @RestController +
@GetMapping/@PostMapping, but with JAX-RS annotations."

---

### 📘 Concept Explanation

**What it is:**

JAX-RS (JSR 370 / Jakarta RESTful Web Services) is a
specification for building REST APIs using annotations
on Java classes. The runtime (RESTEasy, Jersey, CXF)
scans annotated classes, maps HTTP requests to methods,
and handles serialization/deserialization.

**The problem it solves:**

Without JAX-RS: parsing HTTP manually via raw Servlets
(getParameter, getInputStream, setHeader). With JAX-RS:
annotate Java methods, the framework handles HTTP parsing,
parameter injection, and response serialization.

**JAX-RS resource structure:**

```
HTTP REQUEST:
  GET /api/orders/42?format=summary
  Accept: application/json
  X-Correlation-Id: abc-123
       |
       v
JAX-RS RUNTIME:
  Finds matching @Path("/orders")
  Finds matching @GET @Path("/{id}")
  Injects: @PathParam("id") = 42
            @QueryParam("format") = "summary"
            @HeaderParam("X-Correlation-Id") = "abc-123"
  Calls: getOrder(42, "summary", "abc-123")
  Serializes return value to JSON
       |
       v
HTTP RESPONSE:
  200 OK
  Content-Type: application/json
  {"id": 42, "status": "SHIPPED", ...}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Full resource example:**

```java
@Path("/orders")
@Stateless  // or @RequestScoped CDI bean
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OrderResource {

    @Inject
    private OrderService orderService;

    // GET /api/orders?page=0&size=20
    @GET
    public Response list(
        @QueryParam("page") @DefaultValue("0") int page,
        @QueryParam("size") @DefaultValue("20") int size
    ) {
        Page<Order> result =
            orderService.findAll(page, size);
        return Response.ok(result).build();
    }

    // GET /api/orders/42
    @GET
    @Path("/{id}")
    public Response getById(
        @PathParam("id") Long id
    ) {
        return orderService.findById(id)
            .map(order -> Response.ok(order).build())
            .orElse(Response.status(404).build());
    }

    // POST /api/orders
    @POST
    public Response create(
        @Valid CreateOrderRequest request
    ) {
        Order order = orderService.create(request);
        URI location = UriBuilder
            .fromResource(OrderResource.class)
            .path(OrderResource.class, "getById")
            .build(order.getId());
        return Response.created(location)
            .entity(order).build();
    }

    // PUT /api/orders/42
    @PUT
    @Path("/{id}")
    public Response update(
        @PathParam("id") Long id,
        @Valid UpdateOrderRequest request
    ) {
        Order updated = orderService.update(id, request);
        return Response.ok(updated).build();
    }

    // DELETE /api/orders/42
    @DELETE
    @Path("/{id}")
    public Response delete(
        @PathParam("id") Long id
    ) {
        orderService.delete(id);
        return Response.noContent().build(); // 204
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Key insight:**

JAX-RS resources can be either EJB (@Stateless)
for automatic transaction management, or CDI beans
(@RequestScoped) for lightweight DI. In Jakarta EE 10+,
use `@RequestScoped` with `@Transactional` - no EJB needed.

---

### 💻 Code Example

```java
// Production-grade resource with all critical features

@Path("/products")
@RequestScoped
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ProductResource {

    @Inject
    private ProductService productService;

    @Context
    private UriInfo uriInfo;

    // 1. List with pagination + HATEOAS links
    @GET
    public Response list(
        @QueryParam("page") @DefaultValue("0") int page,
        @QueryParam("size") @DefaultValue("20") int size,
        @QueryParam("category") String category
    ) {
        if (size > 100) {
            return Response.status(400)
                .entity(Map.of("error",
                    "Max page size is 100"))
                .build();
        }
        List<Product> products =
            productService.search(page, size, category);
        // Add pagination metadata
        return Response.ok(Map.of(
            "data", products,
            "page", page,
            "size", products.size(),
            "links", Map.of(
                "self", uriInfo.getRequestUri()
            )
        )).build();
    }

    // 2. Create with validation and proper 201
    @POST
    @Transactional
    public Response create(
        @Valid ProductRequest request
    ) {
        Product product = productService.create(request);
        URI created = uriInfo.getAbsolutePathBuilder()
            .path(product.getId().toString())
            .build();
        return Response.created(created)
            .entity(product)
            .build();
    }

    // 3. Conditional GET with ETags
    @GET
    @Path("/{id}")
    public Response getById(
        @PathParam("id") Long id,
        @Context Request request
    ) {
        Product product = productService.findOrThrow(id);
        // Generate ETag from version/timestamp
        EntityTag etag = new EntityTag(
            String.valueOf(product.getVersion())
        );
        Response.ResponseBuilder builder =
            request.evaluatePreconditions(etag);
        if (builder != null) {
            // Client has current version: 304 Not Modified
            return builder.build();
        }
        return Response.ok(product)
            .tag(etag)
            .build();
    }

    // 4. Async processing for long operations
    @POST
    @Path("/{id}/reindex")
    public void reindex(
        @PathParam("id") Long id,
        @Suspended AsyncResponse asyncResponse
    ) {
        asyncResponse.setTimeout(
            30, java.util.concurrent.TimeUnit.SECONDS
        );
        asyncResponse.setTimeoutHandler(ar ->
            ar.resume(Response.status(503)
                .entity("Reindex timed out").build())
        );
        // Hand off to executor
        CompletableFuture.runAsync(() -> {
            try {
                productService.reindex(id);
                asyncResponse.resume(
                    Response.accepted().build()
                );
            } catch (Exception e) {
                asyncResponse.resume(e);
            }
        });
    }
}

// Global exception mapper
@Provider
public class ApplicationExceptionMapper
        implements ExceptionMapper<Exception> {

    @Override
    public Response toResponse(Exception ex) {
        if (ex instanceof jakarta.ws.rs.NotFoundException) {
            return Response.status(404)
                .entity(Map.of("error", "Not found"))
                .build();
        }
        if (ex instanceof jakarta.ws.rs.BadRequestException) {
            return Response.status(400)
                .entity(Map.of("error", ex.getMessage()))
                .build();
        }
        // Generic 500 - do not expose internal details
        return Response.status(500)
            .entity(Map.of("error",
                "Internal server error"))
            .build();
    }
}
```

> **Code walkthrough:** A production JAX-RS resource
> showing five real-world patterns. The list endpoint
> validates page size (max 100) before delegating -
> without this guard, clients can trigger memory exhaustion
> with `?size=100000`. The create endpoint returns
> `Response.created(location)` with the URI of the
> new resource in the `Location` header - required
> by REST best practices for POST. The conditional GET
> with ETags enables browser/proxy caching: if the
> client sends `If-None-Match: "42"` and the ETag
> matches, the server returns 304 without sending the
> body - saves bandwidth. The async endpoint uses
> `@Suspended AsyncResponse`: the JAX-RS thread is
> released immediately; the response is sent when
> `asyncResponse.resume()` is called from the executor.
> The global ExceptionMapper catches all unhandled
> exceptions - the 500 path deliberately returns a
> generic message (no stack traces in production).

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "JAX-RS builds REST APIs with annotations: @Path
> for the URL, @GET/@POST/@PUT/@DELETE for HTTP methods,
> @PathParam/@QueryParam for parameters, @Produces/@Consumes
> for media types. Return a Response object to set
> the status code and body. ExceptionMapper maps
> Java exceptions to HTTP responses. @Valid on a
> request body parameter triggers Bean Validation."

---

**Senior / Staff:**

> "The JAX-RS features that matter in production:
> conditional GETs with ETags for efficient caching,
> @Suspended AsyncResponse for long-running operations
> without blocking Servlet threads, proper exception
> mapping that never exposes stack traces in 500 responses,
> and input validation with max page size guards.
> The subtle design choice: should JAX-RS resources
> be @RequestScoped CDI beans or @Stateless EJBs?
> In Jakarta EE 10+, @RequestScoped with @Transactional
> (CDI-based) is the clean choice - no EJB overhead.
> In older applications, @Stateless was used specifically
> for container-managed transactions."

---

### ⚠️ Common Misconceptions

**Misconception: "JAX-RS automatically returns 200
for all successful responses."**

JAX-RS returns 200 for methods that return an entity
(object or Response with a body), 204 No Content
for void methods or `Response.noContent().build()`,
and 201 Created ONLY if you explicitly use `Response.created(uri)`.
A POST that creates a resource and returns the entity
without `Response.created()` returns 200, not 201.
The REST convention is POST should return 201 with
a `Location` header pointing to the created resource.
Clients and API contracts expect this distinction.

---

### 🚨 Failure Modes and Diagnosis

**Failure: JAX-RS resource returns 415 Unsupported
Media Type**

*Symptom:* Client sends a POST request with JSON body
but receives 415 Unsupported Media Type.

*Root cause:* Either:
1. Client is missing `Content-Type: application/json` header.
2. Resource is missing `@Consumes(MediaType.APPLICATION_JSON)`.
3. Jackson MessageBodyReader is not registered in the JAX-RS application.

*Diagnosis:*
```bash
# Check Content-Type in the request:
curl -v -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"test"}'

# If 415 still: check if Jackson provider is on classpath
# WildFly: RESTEasy-Jackson2 is built in
# Open Liberty: add jackson-jaxrs-json-provider to pom.xml
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:*
```xml
<!-- If Jackson is not auto-detected, register it: -->
@ApplicationPath("/api")
public class RestApp extends Application {
    @Override
    public Set<Class<?>> getClasses() {
        return Set.of(
            com.fasterxml.jackson.jaxrs.json
                .JacksonJsonProvider.class
        );
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| JAX-RS resource design | 3-4 min |
| HTTP method semantics | 2-3 min |
| ExceptionMapper pattern | 2-3 min |
| Async JAX-RS | 3-4 min |
| ETags and conditional GETs | 3 min |
| JAX-RS vs Spring MVC | 2-3 min |
| Content negotiation in depth | 2-3 min |
| POST vs PUT semantics | 2 min |
| Versioning REST APIs | 3 min |

---

**[MID] Q1 - What is the difference between
@POST and @PUT in REST?**

*Why they ask:* HTTP semantics understanding.

Both create/update resources, but with different semantics:

`@POST`:
- Not idempotent: calling twice creates two resources
- Creates subordinate resources: `POST /orders` creates a new order
- Response: 201 Created + Location header
- Body may or may not contain the ID (server generates ID)

`@PUT`:
- Idempotent: calling twice has the same result as calling once
- Replaces the resource at the given URI: `PUT /orders/42`
- Creates or replaces entirely (full entity required)
- Response: 200 OK or 204 No Content

`@PATCH`:
- Partial update: only the provided fields are changed
- Not idempotent (depends on implementation)
- Response: 200 OK or 204

Design rule: if the client determines the resource ID
(PUT /resources/client-id), use PUT.
If the server determines the ID, use POST.

*What separates good from great:* "PUT idempotency is important for reliability: if a network failure causes uncertainty about whether the request was received, the client can safely retry a PUT. Retrying a POST may create duplicates. This is why payment initiation should use POST (never retry automatically) while idempotent config updates use PUT."

---

**[MID] Q2 - How does JAX-RS handle exceptions?**

*Why they ask:* Error handling pattern.

Three ways to return error responses:

1. Return `Response.status(4xx).entity(...)`:
   ```java
   if (notFound) {
       return Response.status(404)
           .entity(Map.of("error", "Not found"))
           .build();
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. Throw JAX-RS exceptions:
   ```java
   throw new jakarta.ws.rs.NotFoundException(
       "Order 42 not found"
   );
   // JAX-RS automatically maps to 404
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Standard JAX-RS exceptions: `NotFoundException` (404),
   `BadRequestException` (400), `NotAuthorizedException` (401),
   `ForbiddenException` (403), `ServerErrorException` (500).

3. ExceptionMapper (global):
   ```java
   @Provider
   public class OrderNotFoundMapper
       implements ExceptionMapper<OrderNotFoundException> {
       public Response toResponse(OrderNotFoundException ex) {
           return Response.status(404)
               .entity(Map.of("error", ex.getMessage()))
               .build();
       }
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Best practice: use domain exceptions (OrderNotFoundException)
with ExceptionMapper. Keeps business code free of
HTTP concerns.

*What separates good from great:* "Hierarchy matters: if you have an ExceptionMapper for Exception and another for NotFoundException, JAX-RS will pick the most specific one. Always handle specific exceptions before the generic Exception catchall."

---

**[SENIOR] Q3 - How do you implement API versioning
in JAX-RS?**

*Why they ask:* API lifecycle management.

Three common strategies:

1. URI path versioning (most common, most visible):
   ```java
   @Path("/v1/orders")
   public class OrderResourceV1 { ... }

   @Path("/v2/orders")
   public class OrderResourceV2 { ... }
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Simple, cache-friendly. Breaking change = new major version.

2. Header versioning (Accept or custom header):
   ```java
   @GET
   @Path("/{id}")
   public Response get(
       @PathParam("id") Long id,
       @HeaderParam("API-Version")
           @DefaultValue("1") int version
   ) {
       if (version >= 2) {
           return Response.ok(v2Service.find(id)).build();
       }
       return Response.ok(v1Service.find(id)).build();
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

3. Content type versioning (media type):
   ```
   Accept: application/vnd.example.order-v2+json
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   JAX-RS `@Produces` matches custom media types.

Trade-offs:
- Path: simple, cache-friendly, creates URL proliferation
- Header: clean URLs, harder to test/debug (curl needs headers)
- Media type: most RESTful but most complex

*What separates good from great:* "I always use path versioning for external APIs - the version is visible in the URL, logs, and browser bookmarks without special tooling. Header versioning is cleaner technically but teams spend half their time debugging 'why is it using v1?' because they forgot the header. Clarity beats purity."

---

**[SENIOR] Q4 - How does JAX-RS content negotiation work?**

*Why they ask:* Protocol-level JAX-RS knowledge.

Content negotiation: client specifies `Accept` header;
server picks the best matching `@Produces` media type.

```java
@GET
@Path("/{id}")
@Produces({
    MediaType.APPLICATION_JSON,   // application/json
    MediaType.APPLICATION_XML,    // application/xml
    "text/csv"                    // custom
})
public Response getOrder(@PathParam("id") Long id) {
    Order order = orderService.find(id);
    return Response.ok(order).build();
    // JAX-RS picks the correct MessageBodyWriter based on Accept
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Negotiation algorithm:
1. Parse `Accept` header (e.g., `application/json, */*;q=0.9`)
2. Match against `@Produces` types with quality factor (q)
3. Highest q-value match wins
4. If no match: 406 Not Acceptable

Client sends: `Accept: application/json;q=0.9, application/xml;q=0.8`
Server picks: JSON (higher q)

Produces `*/*` is a wildcard - matches any Accept.

*What separates good from great:* "A real production case: an older iOS client sends Accept: */* but our API returns application/json. A newer Android client sends Accept: application/json explicitly. Both work because */* matches JSON. The bug: a script that sends Accept: text/html gets a 406 from a JSON-only API. Always handle 406 with a user-friendly error."

---

**[SENIOR] Q5 - What are JAX-RS Sub-resources
and when do you use them?**

*Why they ask:* JAX-RS advanced structure.

Sub-resources delegate path handling to a returned object:
```java
@Path("/departments")
public class DepartmentResource {

    @Inject
    private DepartmentService deptService;

    // Sub-resource locator: returns resource object
    @Path("/{deptId}/employees")
    public EmployeeResource getEmployeeResource(
        @PathParam("deptId") Long deptId
    ) {
        Department dept = deptService.findOrThrow(deptId);
        return new EmployeeResource(dept);
    }
}

// Sub-resource class (not annotated @Path at class level)
public class EmployeeResource {
    private final Department dept;

    public EmployeeResource(Department dept) {
        this.dept = dept;
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Employee> listEmployees() {
        return dept.getEmployees();
    }

    @GET
    @Path("/{empId}")
    public Employee getEmployee(
        @PathParam("empId") Long empId
    ) { ... }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

URL: `GET /departments/5/employees/12`

When to use: hierarchical resources where the sub-resource
needs context from the parent. The sub-resource is
initialized with parent context data.

*What separates good from great:* "Sub-resources are useful for hierarchical APIs, but I'd avoid deep nesting (more than 2 levels). Deep nesting creates long, fragile URLs and couples client code to the server's data model. Prefer flat URLs with query parameters for filtering: GET /employees?department=5."

---

**[SENIOR] Q6 - How does @Suspended AsyncResponse
work in JAX-RS?**

*Why they ask:* JAX-RS async handling.

Problem: long-running operations hold a Servlet thread
for the duration. Servlet thread pools are limited
(typically 50-200 threads). If 100 requests each
take 30 seconds, all threads are blocked.

`@Suspended AsyncResponse`: tells JAX-RS to release
the Servlet thread immediately. The response is
sent when `asyncResponse.resume()` is called from
any thread.

```java
@POST
@Path("/reports/generate")
public void generateReport(
    @QueryParam("type") String reportType,
    @Suspended AsyncResponse asyncResponse
) {
    // Configure timeout
    asyncResponse.setTimeout(
        60, TimeUnit.SECONDS
    );
    asyncResponse.setTimeoutHandler(
        ar -> ar.resume(
            Response.status(503)
                .entity("Report generation timeout")
                .build()
        )
    );

    // Submit to background thread pool
    executorService.submit(() -> {
        try {
            byte[] report =
                reportService.generate(reportType);
            asyncResponse.resume(
                Response.ok(report,
                    "application/pdf").build()
            );
        } catch (Exception e) {
            asyncResponse.resume(e);
            // JAX-RS applies ExceptionMapper to exception
        }
    });
    // This thread is released here - not blocked
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Modern alternative: Quarkus RESTEasy Reactive uses
Mutiny/Uni for reactive async without @Suspended.

*What separates good from great:* "Always set a timeout on AsyncResponse. Without it, a suspended response can hang forever if the background task dies without calling resume(). The timeout handler sends a 503 to the client and cleans up the async context."

---

**[SENIOR] Q7 - How do you implement ETags and
conditional requests in JAX-RS?**

*Why they ask:* HTTP caching and efficiency.

ETags: a version identifier for a resource.
Conditional GET: client sends `If-None-Match: "etag-value"`;
server returns 304 if unchanged.

```java
@GET
@Path("/{id}")
public Response getProduct(
    @PathParam("id") Long id,
    @Context Request request  // JAX-RS Request for condition
) {
    Product product = productService.find(id);

    // ETag based on version or hash
    EntityTag etag = new EntityTag(
        Integer.toString(product.hashCode())
    );

    // Check If-None-Match from request
    Response.ResponseBuilder precondition =
        request.evaluatePreconditions(etag);

    if (precondition != null) {
        // ETag matches: 304 Not Modified
        // No body sent - saves bandwidth
        return precondition.build();
    }

    // Return full response with ETag header
    return Response.ok(product)
        .tag(etag)
        .cacheControl(buildCacheControl())
        .build();
}

private CacheControl buildCacheControl() {
    CacheControl cc = new CacheControl();
    cc.setMaxAge(300); // 5 minutes
    cc.setMustRevalidate(true);
    return cc;
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Benefits: reduces payload for GET requests when
data hasn't changed. Critical for mobile clients
on slow networks.

*What separates good from great:* "ETag-based conditional requests reduce bandwidth but also reduce load on the server: if 90% of GET requests for a popular product return 304, the database query for that product runs only when it changes. Combine with cache-control max-age for full HTTP caching."

---

**[SENIOR] Q8 - What is the JAX-RS Application
class and when do you need it?**

*Why they ask:* JAX-RS bootstrap understanding.

`Application` class configures the JAX-RS runtime:
```java
// Minimal: registers all resources and providers
// by classpath scanning
@ApplicationPath("/api")
public class RestApplication extends Application {
    // Empty: JAX-RS scans and registers all
    // @Path and @Provider annotated classes
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Override `getClasses()` or `getSingletons()` for
explicit registration:
```java
@ApplicationPath("/api")
public class RestApplication extends Application {
    @Override
    public Set<Class<?>> getClasses() {
        return Set.of(
            OrderResource.class,
            ProductResource.class,
            CorsFilter.class,
            JacksonJsonProvider.class
        );
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

When explicit registration is needed:
- Disabling classpath scanning (performance)
- Registering only specific resources (multi-WAR)
- Registering providers from JAR dependencies that
  aren't auto-discovered

When not needed (classpath scanning):
- Simple applications with all resources in one module
- App servers with good JAX-RS scanning support

*What separates good from great:* "An empty Application class (just @ApplicationPath) enables classpath scanning - JAX-RS finds all @Path and @Provider classes automatically. If the Application class overrides getClasses() with explicit resources, scanning is disabled and ONLY the explicitly listed classes are used. Mixing both causes confusion."

---

**[SENIOR] Q9 - How do you design RESTful error
responses for production APIs?**

*Why they ask:* API design maturity.

Production error response requirements:
1. Machine-readable error code (for programmatic handling)
2. Human-readable message
3. Correlation ID for log tracing
4. Field-level validation errors (for 400s)
5. No internal details (no class names, no stack traces)

Standard format (RFC 7807 Problem Details):
```json
{
  "type": "https://api.example.com/errors/invalid-input",
  "title": "Invalid Input",
  "status": 400,
  "detail": "Validation failed for 2 fields",
  "instance": "/api/orders/create",
  "errors": [
    {"field": "quantity", "message": "Must be positive"},
    {"field": "productId", "message": "Product not found"}
  ],
  "correlationId": "abc-123-def"
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

JAX-RS implementation:
```java
@Provider
public class ValidationExceptionMapper
        implements ExceptionMapper<
            ConstraintViolationException
        > {
    @Context
    private HttpHeaders headers;

    @Override
    public Response toResponse(
        ConstraintViolationException ex
    ) {
        String corrId = headers.getHeaderString(
            "X-Correlation-Id"
        );
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("type",
            "https://api.example.com/errors/invalid-input");
        body.put("status", 400);
        body.put("correlationId", corrId);
        body.put("errors",
            violationsToList(ex.getConstraintViolations()));
        return Response.status(400).entity(body).build();
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "RFC 7807 (Problem Details for HTTP APIs) is the emerging standard. Many client libraries know how to parse it. Using a consistent error format across all APIs means client teams write error handling once. The correlationId links the API error to the server log entry - essential for debugging production issues."

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


# JAX-RS Filters and Interceptors

**Interview Weight:** ★★☆ - Working. Filters and
interceptors are how production JAX-RS APIs implement
cross-cutting concerns: authentication, rate limiting,
request logging, and payload transformation.

---

### 🎯 Model Answer

**30 seconds:**

> JAX-RS has two cross-cutting extension points:
> Filters and Interceptors. **Filters** operate on
> the HTTP request/response layer: `ContainerRequestFilter`
> runs before resource method execution (authentication,
> rate limiting, logging), `ContainerResponseFilter`
> runs after (CORS headers, response enrichment).
> **Entity Interceptors** operate on the message body
> read/write pipeline: `ReaderInterceptor` wraps
> `MessageBodyReader`, `WriterInterceptor` wraps
> `MessageBodyWriter`. Both use `@Provider` for
> global registration or `@NameBinding` for selective application.

**3 minutes:**

> JAX-RS cross-cutting concerns break into two layers:
>
> Filters (HTTP layer):
> - `ContainerRequestFilter`: runs before the resource
>   method. Access request headers, path, method.
>   Call `requestContext.abortWith(Response)` to short-circuit
>   (auth failure: return 401 without calling the method).
> - `ContainerResponseFilter`: runs after the resource
>   method, before the response is sent.
>   Modify response headers.
>
> Entity Interceptors (body layer):
> - `ReaderInterceptor`: wraps the deserialization of
>   the request body. Call `context.proceed()` to delegate
>   to the actual reader.
> - `WriterInterceptor`: wraps the serialization of
>   the response body.
>
> Registration:
> - Global: `@Provider` - applied to all resources
> - Selective: `@NameBinding` annotation - applied
>   only to resources/methods annotated with it
> - Priorities: `@Priority(Priorities.AUTHENTICATION)`
>   sets filter execution order
>
> Standard priority constants:
> - `Priorities.AUTHENTICATION` = 1000
> - `Priorities.AUTHORIZATION` = 2000
> - `Priorities.HEADER_DECORATOR` = 3000
> - `Priorities.ENTITY_CODER` = 4000
> - `Priorities.USER` = 5000

**Blank Mind Recovery:**

**(1) Restate:** "ContainerRequestFilter = before method.
ContainerResponseFilter = after method. @Provider = global.
@NameBinding = selective."

**(2) First principles:** "AOP for HTTP: intercept request/response
lifecycle without modifying resource code."

**(3) Bridge:** "Same as Spring's HandlerInterceptor or
OncePerRequestFilter, but for JAX-RS."

---

### 📘 Concept Explanation

**What it is:**

JAX-RS filters and interceptors implement the interceptor
pattern for HTTP request handling. They separate
cross-cutting concerns from business logic without
modifying resource classes.

**The problem it solves:**

Without filters: each resource method must check
authentication, add CORS headers, log the request.
Duplicated, error-prone. With filters: declare once,
applied everywhere (or selectively).

**Filter execution flow:**

```
HTTP REQUEST:
  ContainerRequestFilter (priority 1000 - auth)
  ContainerRequestFilter (priority 2000 - rate limit)
  ContainerRequestFilter (priority 5000 - logging)
        |
        v
  JAX-RS resource method executes
        |
        v
  ContainerResponseFilter (priority 5000 - logging)
  ContainerResponseFilter (priority 3000 - CORS headers)
        |
        v
  HTTP RESPONSE sent to client
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Entity interceptor flow:**

```
REQUEST BODY:
  ReaderInterceptor (wrap MessageBodyReader)
  -> context.proceed() -> actual deserialization

RESPONSE BODY:
  WriterInterceptor (wrap MessageBodyWriter)
  -> context.proceed() -> actual serialization
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// 1. Authentication filter (request filter)
@Provider
@Priority(Priorities.AUTHENTICATION)
public class JwtAuthenticationFilter
        implements ContainerRequestFilter {

    @Inject
    private JwtValidator jwtValidator;

    private static final Set<String> PUBLIC_PATHS =
        Set.of("/auth/login", "/auth/register",
               "/health");

    @Override
    public void filter(
        ContainerRequestContext requestContext
    ) {
        String path = requestContext.getUriInfo()
            .getPath();

        // Skip auth for public paths
        if (PUBLIC_PATHS.stream()
                .anyMatch(path::startsWith)) {
            return;
        }

        String authHeader =
            requestContext.getHeaderString("Authorization");

        if (authHeader == null ||
            !authHeader.startsWith("Bearer ")) {
            requestContext.abortWith(
                Response.status(401)
                    .entity(Map.of("error", "Unauthorized"))
                    .build()
            );
            return;
        }

        String token = authHeader.substring(7);
        try {
            java.security.Principal principal =
                jwtValidator.validate(token);
            // Store in request context for resource use
            requestContext.setProperty(
                "principal", principal
            );
        } catch (Exception e) {
            requestContext.abortWith(
                Response.status(401)
                    .entity(Map.of("error",
                        "Invalid token"))
                    .build()
            );
        }
    }
}

// 2. CORS response filter
@Provider
@Priority(Priorities.HEADER_DECORATOR)
public class CorsFilter
        implements ContainerResponseFilter {

    private static final Set<String> ALLOWED_ORIGINS =
        Set.of("https://app.example.com");

    @Override
    public void filter(
        ContainerRequestContext req,
        ContainerResponseContext resp
    ) {
        String origin = req.getHeaderString("Origin");
        if (origin != null &&
                ALLOWED_ORIGINS.contains(origin)) {
            resp.getHeaders().add(
                "Access-Control-Allow-Origin", origin
            );
            resp.getHeaders().add(
                "Access-Control-Allow-Methods",
                "GET, POST, PUT, DELETE, OPTIONS"
            );
            resp.getHeaders().add(
                "Access-Control-Allow-Headers",
                "Content-Type, Authorization"
            );
            resp.getHeaders().add(
                "Access-Control-Allow-Credentials",
                "true"
            );
        }
    }
}

// 3. Selective @NameBinding: apply only to annotated methods
@NameBinding
@Target({METHOD, TYPE})
@Retention(RUNTIME)
public @interface Audited {}

@Provider
@Audited  // only runs on methods/classes annotated @Audited
@Priority(Priorities.USER)
public class AuditFilter
        implements ContainerRequestFilter,
                   ContainerResponseFilter {

    private final ThreadLocal<Long> startTime =
        new ThreadLocal<>();

    @Override
    public void filter(ContainerRequestContext req) {
        startTime.set(System.currentTimeMillis());
    }

    @Override
    public void filter(
        ContainerRequestContext req,
        ContainerResponseContext resp
    ) {
        long elapsed = System.currentTimeMillis()
            - startTime.get();
        startTime.remove(); // prevent leak
        System.out.printf(
            "AUDIT: %s %s -> %d (%dms)%n",
            req.getMethod(),
            req.getUriInfo().getPath(),
            resp.getStatus(),
            elapsed
        );
    }
}

// Apply selectively to a resource
@Path("/payments")
@Audited  // only payment endpoints are audited
@RequestScoped
public class PaymentResource {
    @POST
    public Response process(@Valid PaymentRequest req) {
        // Audit filter runs for all methods in this class
        return Response.ok().build();
    }
}

// 4. ReaderInterceptor: decompress gzip request body
@Provider
@Priority(Priorities.ENTITY_CODER)
public class GzipReaderInterceptor
        implements ReaderInterceptor {
    @Override
    public Object aroundReadFrom(
        ReaderInterceptorContext context
    ) throws IOException,
             WebApplicationException {
        String encoding =
            context.getHeaders().getFirst(
                "Content-Encoding"
            );
        if ("gzip".equals(encoding)) {
            context.setInputStream(
                new java.util.zip.GZIPInputStream(
                    context.getInputStream()
                )
            );
        }
        return context.proceed();
    }
}
```

> **Code walkthrough:** Four filter/interceptor patterns
> in sequence. The `JwtAuthenticationFilter` shows
> the critical `abortWith()` pattern: calling it
> prevents any further filter execution AND the resource
> method from running. Without `abortWith()`, a filter
> cannot stop the request - it can only modify the
> context. The CORS filter runs on the response side,
> adding headers only for allowlisted origins (never
> wildcard for authenticated endpoints). The `@NameBinding`
> `AuditFilter` uses `ThreadLocal<Long>` to carry
> the start time from the request filter to the response
> filter - crucial for timing. The `remove()` in
> finally prevents ThreadLocal memory leaks in pooled
> app server threads. The `GzipReaderInterceptor`
> shows entity interceptors: wrap the InputStream
> before passing to `context.proceed()` which calls
> the actual Jackson deserializer.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "JAX-RS ContainerRequestFilter runs before the
> resource method - used for authentication and rate
> limiting. ContainerResponseFilter runs after - used
> for CORS headers and response enrichment. Register
> with @Provider for all resources or use @NameBinding
> to apply only to specific resources/methods. Use
> requestContext.abortWith() to short-circuit the
> request (e.g., return 401 without calling the method)."

---

**Senior / Staff:**

> "The filter priority system matters in production.
> Authentication must run before authorization
> (AUTHENTICATION=1000, AUTHORIZATION=2000). If you
> have a rate limiter filter, it should run after auth
> (so you rate limit authenticated users, not anonymous
> 401s). The ThreadLocal pattern in two-phase filters
> (request + response in one class) requires `remove()`
> in the response phase - app server thread pools reuse
> threads, and a ThreadLocal that's not cleared will
> have stale values on the next request that thread
> handles."

---

### ⚠️ Common Misconceptions

**Misconception: "ContainerResponseFilter can modify
the response body."**

`ContainerResponseFilter` can add/modify response
headers but cannot easily replace the response body.
It receives a `ContainerResponseContext` with the
entity (Java object) not yet serialized to bytes.
You can call `context.setEntity(newEntity)` to replace
the entity, but this only works before serialization.
For wrapping or transforming the serialized bytes,
you need a `WriterInterceptor`, which wraps the
`OutputStream` before `MessageBodyWriter` serializes
to it. The two extension points have different power:
filters for headers/status/abort, interceptors for body transformation.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Filter runs after the resource method
despite being a request filter**

*Symptom:* A `ContainerRequestFilter` that should
authenticate requests is not preventing unauthorized access.

*Root cause:* The filter is registered as a response
filter (`ContainerResponseFilter`) instead of a request
filter, or the `@Provider` annotation is missing,
or the filter is in a different module that isn't
scanned.

*Diagnosis:*
```bash
# Enable JAX-RS request tracing (WildFly)
# Add to standalone.xml:
<subsystem xmlns="urn:jboss:domain:undertow:12.0">
  ...
  <server default-server="...">
    <host name="..." enable-http2="true">
      <filter-ref name="request-dumper"/>  ← add this
    </host>
  </server>
  <filters>
    <filter name="request-dumper"
        class-name="io.undertow.server.handlers
.RequestDumpingHandler"/>
  </filters>
</subsystem>

# Or add debug logging:
grep "RESTEasy\|filter\|provider" server.log
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*Fix:* Verify:
1. Correct interface: `ContainerRequestFilter` (not Response).
2. `@Provider` annotation present.
3. Class is in a CDI-enabled archive (has beans.xml or
   has scope annotations).
4. No Exception thrown during filter instantiation.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Filter vs interceptor | 2-3 min |
| ContainerRequestFilter authentication | 3-4 min |
| @NameBinding selective filter | 3 min |
| Filter priority ordering | 2-3 min |
| WriterInterceptor for compression | 3 min |
| ThreadLocal in two-phase filters | 2-3 min |
| Filter vs CDI interceptor | 2-3 min |
| Pre-matching filters | 2 min |
| abortWith behavior | 2 min |

---

**[MID] Q1 - What is a pre-matching filter and
when do you use it?**

*Why they ask:* JAX-RS filter types.

Standard `ContainerRequestFilter` runs AFTER JAX-RS
has matched the request to a resource method.
Pre-matching filter (`@PreMatching`): runs BEFORE
method matching.

```java
@Provider
@PreMatching
public class MethodOverrideFilter
        implements ContainerRequestFilter {
    @Override
    public void filter(
        ContainerRequestContext ctx
    ) {
        // Allow HTTP method override via header
        // (for clients that can't send PUT/DELETE)
        String override =
            ctx.getHeaderString("X-HTTP-Method-Override");
        if (override != null) {
            ctx.setMethod(override.toUpperCase());
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Other pre-matching uses:
- Normalize URLs (remove trailing slashes) before matching
- Redirect HTTP to HTTPS before any resource processes the request
- Log ALL requests including unmatched ones (404s)

*What separates good from great:* "Pre-matching filters can change the URI and method before matching, which means you can handle URL normalization (trailing slash redirect) before any resource code runs. Post-matching filters see 404 before it's returned - useful for logging all requests including unmatched paths."

---

**[MID] Q2 - How do you pass data from a request
filter to the resource method?**

*Why they ask:* Filter context sharing pattern.

Use `ContainerRequestContext.setProperty(name, value)`:
```java
// In ContainerRequestFilter (authentication):
Principal principal = jwtValidator.validate(token);
requestContext.setProperty("user.principal", principal);

// In resource method:
@GET
@Path("/profile")
public Response getProfile(
    @Context ContainerRequestContext ctx
) {
    Principal principal = (Principal)
        ctx.getProperty("user.principal");
    // use principal
    return Response.ok(profile).build();
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Or inject `SecurityContext`:
```java
// Filter: set security context
requestContext.setSecurityContext(
    new SecurityContext() {
        @Override
        public Principal getUserPrincipal() {
            return principal;
        }
        @Override
        public boolean isUserInRole(String role) {
            return principal.hasRole(role);
        }
        @Override
        public boolean isSecure() {
            return requestContext.getSecurityContext()
                .isSecure();
        }
        @Override
        public String getAuthenticationScheme() {
            return "Bearer";
        }
    }
);

// Resource method:
@GET
public Response get(@Context SecurityContext sc) {
    Principal user = sc.getUserPrincipal();
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "Setting the SecurityContext is the cleanest approach: the resource method uses the standard @Context SecurityContext injection, which is also used by @RolesAllowed checks. setProperty is more flexible but relies on string key names."

---

**[MID] Q3 - How do you implement rate limiting
with a JAX-RS filter?**

*Why they ask:* Production API protection.

Rate limiting filter using a token bucket or sliding window:
```java
@Provider
@Priority(Priorities.USER)
public class RateLimitFilter
        implements ContainerRequestFilter {

    // Simple in-memory rate limit (use Redis for distributed)
    private final java.util.concurrent.ConcurrentHashMap<
        String, AtomicLong> requestCounts =
        new ConcurrentHashMap<>();

    @Override
    public void filter(
        ContainerRequestContext ctx
    ) {
        String clientIp =
            ctx.getHeaderString("X-Forwarded-For");
        if (clientIp == null) {
            clientIp = "unknown";
        }

        long count = requestCounts
            .computeIfAbsent(clientIp, k -> new AtomicLong())
            .incrementAndGet();

        // Simplified: 100 requests, reset externally
        if (count > 100) {
            ctx.abortWith(
                Response.status(429)
                    .header("Retry-After", "60")
                    .entity(Map.of("error",
                        "Rate limit exceeded"))
                    .build()
            );
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Production rate limiting:
- Use Redis with sliding window (not in-memory per node)
- Rate limit by: IP, user ID, API key
- Return Retry-After header with seconds until reset
- Return X-RateLimit-Remaining, X-RateLimit-Reset headers

*What separates good from great:* "In-memory rate limiting doesn't work in a cluster: each node has independent counters. A client routed to different nodes can exceed the rate limit N times (once per node). Use Redis with atomic INCR + EXPIRE for distributed rate limiting."

---

**[MID] Q4 - What is the difference between JAX-RS
filters and CDI interceptors?**

*Why they ask:* Choosing the right cross-cutting mechanism.

JAX-RS filters (`ContainerRequestFilter`,
`ContainerResponseFilter`): operate at the HTTP layer.
- Access HTTP headers, method, URI, status code
- Can abort the request with an HTTP response
- Applied to JAX-RS request/response pipeline
- Cannot intercept non-JAX-RS code

CDI interceptors (`@Interceptor`, `@AroundInvoke`): operate
at the Java method invocation level.
- Intercept any CDI bean method call (not just HTTP)
- Access method arguments and return value
- Applied via interceptor bindings (@Transactional is one)
- No access to HTTP context without @Context injection

When to use:
- HTTP-specific concerns (auth, CORS, rate limiting): JAX-RS filter
- Business-logic concerns (transactions, auditing method calls,
  timing any service method): CDI interceptor

*What separates good from great:* "@Transactional is a CDI interceptor, not a JAX-RS filter - that's why it works on any CDI bean method, not just JAX-RS resources. If I need to time all service layer calls, I use a CDI interceptor. If I need to add a response header, I use a JAX-RS filter."

---

**[MID] Q5 - How does WriterInterceptor work
for response compression?**

*Why they ask:* Entity interceptor understanding.

`WriterInterceptor` wraps the `OutputStream` before
`MessageBodyWriter` serializes to it:
```java
@Provider
@Priority(Priorities.ENTITY_CODER)
public class GzipWriterInterceptor
        implements WriterInterceptor {

    @Override
    public void aroundWriteTo(
        WriterInterceptorContext context
    ) throws IOException,
             WebApplicationException {
        String acceptEncoding =
            context.getHeaders().getFirst("Accept-Encoding");

        if (acceptEncoding != null &&
                acceptEncoding.contains("gzip")) {
            // Wrap output stream with gzip
            java.io.OutputStream os =
                context.getOutputStream();
            java.util.zip.GZIPOutputStream gzipOs =
                new java.util.zip.GZIPOutputStream(os);
            context.setOutputStream(gzipOs);
            context.getHeaders().putSingle(
                "Content-Encoding", "gzip"
            );
            try {
                context.proceed(); // serialize to gzip stream
            } finally {
                gzipOs.finish(); // flush gzip footer
            }
        } else {
            context.proceed(); // no compression
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Calling `context.proceed()` triggers the actual
`MessageBodyWriter` to write the entity (e.g., Jackson
writes JSON). By swapping the OutputStream first,
all writes go through the GzipOutputStream.

*What separates good from great:* "The gzipOs.finish() in finally is critical - without it, the gzip footer isn't written and the client gets a truncated, invalid gzip stream. The Content-Encoding header tells the client to decompress."

---

**[SENIOR] Q6 - How do you implement request
logging with correlation IDs using JAX-RS filters?**

*Why they ask:* Production observability.

Request logging with correlation ID tracing:
```java
@Provider
@Priority(Priorities.USER + 100)
public class RequestLoggingFilter
        implements ContainerRequestFilter,
                   ContainerResponseFilter {

    // Thread-safe start time
    private final ThreadLocal<Long> startTime =
        new ThreadLocal<>();
    private final ThreadLocal<String> correlationId =
        new ThreadLocal<>();

    @Override
    public void filter(ContainerRequestContext req) {
        long start = System.currentTimeMillis();
        startTime.set(start);

        // Get or generate correlation ID
        String corrId =
            req.getHeaderString("X-Correlation-Id");
        if (corrId == null) {
            corrId = java.util.UUID.randomUUID().toString();
        }
        correlationId.set(corrId);
        req.setProperty("correlationId", corrId);

        // Set MDC for log4j2/logback correlation
        org.slf4j.MDC.put("correlationId", corrId);

        System.out.printf(
            "REQ [%s] %s %s%n",
            corrId, req.getMethod(),
            req.getUriInfo().getPath()
        );
    }

    @Override
    public void filter(
        ContainerRequestContext req,
        ContainerResponseContext resp
    ) {
        long elapsed = System.currentTimeMillis()
            - startTime.get();
        String corrId = correlationId.get();

        // Echo correlation ID in response
        resp.getHeaders().add(
            "X-Correlation-Id", corrId
        );

        System.out.printf(
            "RESP [%s] %s %s -> %d (%dms)%n",
            corrId, req.getMethod(),
            req.getUriInfo().getPath(),
            resp.getStatus(), elapsed
        );

        // Cleanup ThreadLocals (critical for thread reuse)
        startTime.remove();
        correlationId.remove();
        org.slf4j.MDC.clear();
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "MDC (Mapped Diagnostic Context) from SLF4J is the key: once set in the filter, every log statement within the request execution automatically includes the correlationId in the log line. Without it, correlating a sequence of log lines to one request requires timestamp guessing."

---

**[SENIOR] Q7 - How do you implement authorization
checks in JAX-RS?**

*Why they ask:* Security enforcement pattern.

Three approaches:

1. `@RolesAllowed` annotation (container-managed):
   ```java
   @Path("/admin")
   @RolesAllowed("ADMIN")  // container checks role
   public class AdminResource { ... }
   ```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

   Requires: SecurityContext set by auth filter.
   Container throws `ForbiddenException` (403) if role not present.

2. Authorization filter with `@NameBinding`:
   ```java
   @Provider
   @Secured  // @NameBinding annotation
   @Priority(Priorities.AUTHORIZATION)
   public class AuthorizationFilter
           implements ContainerRequestFilter {
       @Override
       public void filter(ContainerRequestContext ctx) {
           SecurityContext sc = ctx.getSecurityContext();
           if (!sc.isUserInRole("ADMIN")) {
               ctx.abortWith(
                   Response.status(403)
                       .entity(Map.of("error",
                           "Forbidden"))
                       .build()
               );
           }
       }
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

3. Programmatic in resource method:
   ```java
   @GET
   public Response get(@Context SecurityContext sc) {
       if (!sc.isUserInRole("ADMIN")) {
           return Response.status(403).build();
       }
       return Response.ok(adminData()).build();
   }
   ```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "@RolesAllowed is clean and declarative. The filter approach is more flexible (dynamic role checks, attribute-based access). For complex authorization (RBAC, ABAC), use a dedicated authorization library like OPA (Open Policy Agent) and call it from an authorization filter."

---

**[SENIOR] Q8 - What is the execution order of
multiple JAX-RS filters?**

*Why they ask:* Filter ordering for correct behavior.

Order is controlled by `@Priority`:
```java
@Provider
@Priority(1000)  // Priorities.AUTHENTICATION
class AuthFilter implements ContainerRequestFilter {}

@Provider
@Priority(2000)  // Priorities.AUTHORIZATION
class AuthzFilter implements ContainerRequestFilter {}

@Provider
@Priority(5000)  // Priorities.USER
class LoggingFilter implements ContainerRequestFilter {}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Request filters: executed in ASCENDING priority order
(1000 before 2000 before 5000).

Response filters: executed in DESCENDING priority order
(5000 before 2000 before 1000). This is the inverse
of request order - response filters unwind in reverse.

If no `@Priority` is set: undefined order (avoid this
for security-critical filters).

*What separates good from great:* "The response filter inversion is non-obvious: if authentication is priority 1000 and logging is priority 5000, the logging RESPONSE filter runs FIRST (5000 > 1000 in response phase). This means the logging filter sees the response BEFORE the authentication filter's response phase. For most cases this doesn't matter, but if a response filter depends on state set by a lower-priority request filter, verify the execution order."

---

**[SENIOR] Q9 - How do you unit test JAX-RS
resources and filters?**

*Why they ask:* Testing strategy for JAX-RS.

Testing JAX-RS resources without a container:
```java
// Using JerseyTest or RESTEasy testing support
// OR: use Arquillian with embedded WildFly

// WildFly/RESTEasy: using in-process test server
@QuarkusTest  // Quarkus: fastest option
class OrderResourceTest {
    @Test
    void shouldReturn404ForMissingOrder() {
        given()
            .header("Authorization", "Bearer " + testToken)
        .when()
            .get("/api/orders/9999")
        .then()
            .statusCode(404)
            .body("error", notNullValue());
    }
}

// Without server (plain Java): test business logic only
class OrderServiceTest {
    @Test
    void shouldCreateOrder() {
        // Inject mocks via constructor
        OrderService svc = new OrderService(
            mockOrderRepo, mockPayment
        );
        Order result = svc.create(validRequest);
        assertNotNull(result.getId());
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Testing filters specifically:
```java
class AuthFilterTest {
    @Test
    void shouldRejectMissingToken() {
        ContainerRequestContext ctx =
            mock(ContainerRequestContext.class);
        when(ctx.getHeaderString("Authorization"))
            .thenReturn(null);
        when(ctx.getUriInfo()).thenReturn(mockUriInfo);
        when(mockUriInfo.getPath()).thenReturn("/api/orders");

        AuthFilter filter = new AuthFilter();
        filter.filter(ctx);

        verify(ctx).abortWith(argThat(
            r -> r.getStatus() == 401
        ));
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "Testing JAX-RS resources with RestAssured (or Quarkus @QuarkusTest + REST Assured) is the most productive approach for integration tests. Unit testing filters with Mockito works but misses HTTP integration. For production code: unit test business logic, integration test the HTTP layer."

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



