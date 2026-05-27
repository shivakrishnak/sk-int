---
layout: default
title: "REST API - L1 Foundations"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 2
permalink: /rest-api/l1-foundations/
---

# HTTP Methods Semantics and Safety

🎯 Interview Weight: high - Correct HTTP method usage is the
foundation of RESTful design. Misuse is a code smell that reveals
shallow API design knowledge.

---

### 🎯 Model Answer

**30 seconds:**
> HTTP methods have defined semantics: GET retrieves (safe, idempotent),
> POST creates (neither), PUT replaces (idempotent), PATCH partially
> updates (not idempotent in general), DELETE removes (idempotent).
> Safe means no side effects. Idempotent means multiple identical
> requests have the same effect as one.

**3 minutes (Senior):**
> HTTP method semantics matter because HTTP infrastructure (proxies,
> caches, retry logic) behaves differently based on the method.
>
> Safe methods (GET, HEAD, OPTIONS): no side effects. Proxies and
> browsers can retry safely. GET requests can be cached. GET requests
> should NEVER modify server state.
>
> Idempotent methods (GET, HEAD, PUT, DELETE, OPTIONS): multiple
> identical requests have the same result as one. Retry is safe.
> PUT replaces the entire resource: PUT /orders/123 with a body
> replaces ALL fields of order 123 (missing fields are deleted).
>
> Non-idempotent (POST, PATCH): POST creates a new resource each time
> (sending the same POST twice creates two orders). PATCH applies a
> delta - the semantics depend on the patch representation. A PATCH
> that replaces a single field is idempotent; a PATCH that appends
> to a list is not.
>
> Practical misuse: using GET with a request body (body is ignored
> by many intermediaries), using POST for retrieval operations,
> using GET for operations with side effects. GET for operations with
> side effects is particularly dangerous: `GET /admin/delete-all`
> will be triggered by web crawlers, browser prefetch, and HTTP
> cache refreshes.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about what each HTTP method means
and the safety/idempotency properties."

**(2) First principles:** "HTTP methods are contracts between client
and infrastructure. GET = read-only, safe to retry. PUT = replace,
safe to retry. POST = create once."

**(3) Bridge:** "Like postal operations: GET is reading a letter
(safe, no changes). POST is sending a new letter (creates a new
one each time). PUT is replacing a letter's contents. DELETE is
shredding it."

---

### 📘 Concept Explanation

**Method properties table:**

```
Method   | Safe | Idempotent | Body | Purpose
---------|------|------------|------|--------------------
GET      | Yes  | Yes        | No*  | Retrieve resource
HEAD     | Yes  | Yes        | No   | Get headers only
OPTIONS  | Yes  | Yes        | No   | Discover methods
POST     | No   | No         | Yes  | Create resource
PUT      | No   | Yes        | Yes  | Replace resource
PATCH    | No   | No**       | Yes  | Partial update
DELETE   | No   | Yes        | No   | Remove resource
CONNECT  | No   | No         | Yes  | HTTP tunnel (proxy)
TRACE    | Yes  | Yes        | No   | Diagnostic

*Body allowed by spec but ignored by many implementations
**Depends on the patch representation
```

**PUT vs PATCH - the full resource vs delta distinction:**

```
Given: GET /users/123 returns
  { "name": "Alice", "email": "alice@example.com",
    "role": "admin" }

PUT /users/123 with body:
  { "name": "Alice", "email": "new@example.com" }
  -> Role is now NULL (full replacement)
  -> Old: role = admin; New: role = NULL

PATCH /users/123 with body:
  { "email": "new@example.com" }
  -> Only email changed; role stays admin
  -> Partial update: only specified fields modified
```

**The key insight:**
Infrastructure makes decisions based on method semantics. Nginx,
CDNs, and browsers will NOT cache POST responses. Automated retry
on connection failure only retries idempotent methods (GET, PUT,
DELETE) by default. Using POST for retrieval loses caching and
retry benefits.

---

### 💻 Code Example

**BAD - Method misuse:**

```java
// BAD: Using GET for a state-changing operation
// Web crawlers and browser prefetch WILL trigger this
@GetMapping("/admin/deactivate-user/{userId}")
public String deactivateUser(@PathVariable String userId) {
    userService.deactivate(userId); // DANGEROUS
    return "User deactivated";
}

// BAD: Using POST for retrieval
// Loses HTTP caching; POST is not idempotent
@PostMapping("/users/search")
public List<User> searchUsers(@RequestBody SearchRequest r) {
    // This works but cannot be cached by CDN/proxy
    return userService.search(r);
}
```

**GOOD - Correct method usage:**

```java
// GOOD: State-changing operations use POST/PUT/PATCH/DELETE
@PostMapping("/admin/users/{userId}/deactivate")
public ResponseEntity<Void> deactivateUser(
    @PathVariable String userId
) {
    userService.deactivate(userId);
    return ResponseEntity.noContent().build(); // 204
}

// GOOD: Read-only search via GET with query params
@GetMapping("/users")
public List<UserSummary> searchUsers(
    @RequestParam String name,
    @RequestParam(required = false) String email,
    @RequestParam(defaultValue = "0") int page
) {
    // Cacheable, safe to retry, browser-native
    return userService.search(name, email, page);
}

// GOOD: Complex search (too complex for query params) via POST
// Accept that it is not cached - this is OK
@PostMapping("/users/search")
public Page<UserSummary> complexSearch(
    @RequestBody @Valid UserSearchCriteria criteria
) {
    // Acceptable: complex queries that cannot fit in URL
    return userService.complexSearch(criteria);
}
```

> **Code walkthrough:** The BAD example is dangerous: GET
> `/admin/deactivate-user/{userId}` will be executed by web crawlers,
> browser prefetch, and HTTP cache refreshes - all thinking it is
> a read-only operation. The GOOD example uses POST `/admin/users/{userId}/deactivate`
> for the state change (a named action). For search, GET with query
> params is the correct choice for simple queries (cacheable by CDN).
> For complex search criteria that cannot fit in query params, POST
> is acceptable with the trade-off that it cannot be cached by
> HTTP infrastructure.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> HTTP methods have specific meanings: GET retrieves, POST creates,
> PUT replaces, PATCH partially updates, DELETE removes. Safe methods
> (GET) have no side effects - infrastructure can retry them freely.
> Idempotent methods (GET, PUT, DELETE) can be called multiple times
> with the same result. POST is neither safe nor idempotent.

---

**Senior / Staff (5+ years):**
> The operational impact of method misuse: using GET for side effects
> causes those side effects to execute on every cache refresh, every
> browser prefetch, and every link scanner. I have seen "delete" and
> "activate" operations triggered by Googlebot and link preview
> services because someone exposed them via GET. Using correct methods
> is not just style - it is correctness for the HTTP ecosystem.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | GET/POST/PUT/DELETE semantics |
| Mid | 3 min | Safe + idempotent + infrastructure implications |
| Senior | 5 min | PUT vs PATCH + method misuse consequences |

---

**[TRADE-OFF] When is it acceptable to use POST for a read
operation?** `[SENIOR]`

*Why they ask:* Tests understanding of when to break the rule
and why.

*Likely follow-up:* "How do you handle caching for POST search?"

Acceptable to use POST for read: (1) The search criteria are too
complex to encode in query parameters (deeply nested filters, large
sets of IDs). URL length limit is ~2KB in many proxies; a filter
with 500 product IDs exceeds this. (2) The search criteria contain
sensitive information that should not appear in server access logs
(which log the URL). A filter containing user IDs or similar PII
should not be in the URL. (3) A "search as a resource" where the
search is saved (POST /searches returns a search ID, GET /searches/123
returns the results - this is RESTfully correct). The trade-off:
POST for read loses HTTP caching (CDN will not cache POST responses
by default). Mitigation: application-level caching (Redis) keyed
on the request body hash. The cache is explicit rather than relying
on HTTP infrastructure.

*What separates good from great:* "Always use GET for read" without
the URL length, PII, and search-as-resource scenarios where POST
is the better choice.

---

---

# HTTP Status Codes and Error Responses

🎯 Interview Weight: high - Status code misuse is one of the
most common REST API quality issues.

---

### 🎯 Model Answer

**30 seconds:**
> HTTP status codes communicate the result of a request. 2xx =
> success, 3xx = redirect, 4xx = client error (request was wrong),
> 5xx = server error (server failed to process a valid request).
> The most important: 200 (success), 201 (created), 204 (no content),
> 400 (bad request), 401 (not authenticated), 403 (not authorized),
> 404 (not found), 409 (conflict), 429 (rate limited), 500 (server error).

**3 minutes (Senior):**
> The purpose of status codes: HTTP clients (browsers, HTTP libraries,
> load balancers, retry logic) make decisions based on status codes.
> Using the wrong status code causes these automated behaviors to
> be wrong.
>
> Common misuses:
>
> 200 for everything: returning 200 with `{ "success": false }` in
> the body breaks all HTTP clients. Retry logic will not retry (it
> sees success). Error monitoring will not alert (it sees 2xx). The
> correct approach: return the appropriate error status code in
> the HTTP response.
>
> 401 vs 403: 401 Unauthorized actually means Unauthenticated (the
> request has no valid credentials). 403 Forbidden means Authenticated
> but not authorized (you are identified, but you do not have permission).
> Returning 403 for unauthenticated requests leaks information (confirms
> the resource exists).
>
> 404 vs 410: 404 Not Found (may exist in the future). 410 Gone
> (explicitly removed, will never exist again). Use 410 for deleted
> resources to tell clients to remove their bookmarks.
>
> 400 vs 422: 400 Bad Request (malformed request - could not parse
> the JSON). 422 Unprocessable Entity (syntactically correct but
> semantically invalid - valid JSON but invalid business rules).
>
> Error response format: always include a machine-readable error code,
> a human-readable message, and a correlation ID for support. RFC 7807
> (Problem Details for HTTP APIs) is the standard format.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about which HTTP status codes
to use and how to format error responses."

**(2) First principles:** "Status codes are the API's communication
channel to HTTP infrastructure. Correct codes enable retries,
caching, and monitoring to work correctly automatically."

**(3) Bridge:** "Like a postal delivery system: 200 = delivered,
404 = address not found, 503 = post office is closed, 429 = too
many letters at once."

---

### 💻 Code Example

**BAD - Return 200 for everything:**

```java
// BAD: 200 for all responses, error in body
// Breaks HTTP client retry logic and monitoring

@PostMapping("/orders")
public Map<String, Object> createOrder(
    @RequestBody CreateOrderRequest req
) {
    try {
        Order order = orderService.create(req);
        return Map.of("success", true, "order", order);
    } catch (InsufficientStockException e) {
        // WRONG: returns 200 with error in body
        return Map.of("success", false,
            "error", "Insufficient stock");
    }
}
```

**GOOD - RFC 7807 Problem Details error format:**

```java
// GOOD: Appropriate status codes + RFC 7807 error format

@PostMapping("/orders")
public ResponseEntity<OrderResponse> createOrder(
    @RequestBody @Valid CreateOrderRequest req
) {
    Order order = orderService.create(req);
    return ResponseEntity
        .status(HttpStatus.CREATED)  // 201
        .location(URI.create(
            "/api/v1/orders/" + order.getId()
        ))
        .body(toResponse(order));
}

// Global exception handler with RFC 7807 format
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(InsufficientStockException.class)
    public ResponseEntity<ProblemDetail> handleInsufficientStock(
        InsufficientStockException e,
        HttpServletRequest request
    ) {
        ProblemDetail problem = ProblemDetail
            .forStatusAndDetail(
                HttpStatus.CONFLICT,  // 409
                e.getMessage()
            );
        problem.setTitle("Insufficient Stock");
        problem.setType(URI.create(
            "https://api.example.com/errors/insufficient-stock"
        ));
        problem.setProperty(
            "productId", e.getProductId()
        );
        problem.setProperty(
            "requestedQuantity", e.getRequestedQty()
        );
        problem.setProperty(
            "availableQuantity", e.getAvailableQty()
        );
        // Correlation ID from request header
        problem.setProperty(
            "traceId",
            request.getHeader("X-Request-ID")
        );
        return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(problem);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(
        MethodArgumentNotValidException e
    ) {
        ProblemDetail problem = ProblemDetail
            .forStatus(HttpStatus.UNPROCESSABLE_ENTITY); // 422
        problem.setTitle("Validation Failed");
        problem.setProperty(
            "errors",
            e.getBindingResult().getFieldErrors()
                .stream()
                .map(fe -> Map.of(
                    "field", fe.getField(),
                    "message", fe.getDefaultMessage()
                ))
                .collect(toList())
        );
        return ResponseEntity
            .status(HttpStatus.UNPROCESSABLE_ENTITY)
            .body(problem);
    }
}
```

> **Code walkthrough:** The BAD example returns 200 for all outcomes.
> A monitoring tool counting 5xx errors will show 0% - masking all
> business errors. The GOOD example returns 201 for creation (with
> `Location` header) and uses proper error codes: 409 for a business
> conflict (insufficient stock), 422 for validation failures.
> The RFC 7807 `ProblemDetail` format provides: `type` (machine-readable
> URI error code), `title` (human-readable), `detail` (specific message),
> `status` (HTTP status code), and custom extension properties
> (`productId`, `requestedQuantity`, `traceId`). The `traceId` enables
> customer support to find the error in logs.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> HTTP status codes communicate the request outcome. 2xx is success
> (200 = OK, 201 = created, 204 = no content). 4xx is client errors
> (400 = bad request, 401 = not authenticated, 403 = not authorized,
> 404 = not found). 5xx is server errors (500 = internal error,
> 503 = service unavailable). Always include the error status code
> in the HTTP response - not in the response body with 200.

---

**Senior / Staff (5+ years):**
> The monitoring impact of correct status codes: with proper 4xx/5xx
> codes, dashboards, alerting, and APM tools automatically categorize
> errors without custom logic. SLI (Service Level Indicator) for
> error rate is the 5xx percentage - this only works if server errors
> actually return 5xx. Error budgets in SLO monitoring are driven
> by status codes. RFC 7807 is the standard error format I always
> mandate: it adds a `type` URI (stable, machine-readable error code)
> that client code can switch on, and a `traceId` field that
> operations teams can use to find the exact request in logs.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | 2xx/4xx/5xx categories + common codes |
| Mid | 4 min | 401 vs 403, 404 vs 410, 400 vs 422 |
| Senior | 5 min | RFC 7807 + monitoring implications of correct codes |

---

---

# REST Resource Naming and URL Design

🎯 Interview Weight: high - URL design reveals API design quality.
Tested in senior interviews as a practical design task.

---

### 🎯 Model Answer

**30 seconds:**
> REST URLs identify resources. Conventions: use nouns (not verbs),
> plural for collections, lowercase with hyphens, resource hierarchies
> reflect domain relationships. Use query parameters for filtering
> and sorting. Use path parameters for resource identity.

**3 minutes (Senior):**
> REST resource naming reflects the domain model. Rules:
>
> Nouns, not verbs: `/orders` not `/getOrders`. The verb is encoded
> in the HTTP method. `/orders` with GET retrieves, with POST creates.
> The anti-pattern: RPC-style URLs like `/cancelOrder?id=123` should
> be `POST /orders/123/cancellations` or `DELETE /orders/123`.
>
> Collections are plural nouns: `/users`, `/orders`, `/products`.
> Sub-resources for hierarchy: `/users/123/orders` (orders for a
> specific user), `/orders/456/line-items` (line items of an order).
>
> IDs in paths: `/users/{userId}` where `userId` is a stable,
> opaque identifier (UUID preferred over sequential int - sequential
> IDs enable enumeration attacks).
>
> Query parameters for filtering, sorting, pagination:
> `GET /orders?status=PENDING&customerId=123&sort=createdAt:desc&page=0&size=20`
>
> Lowercase with hyphens for multi-word resources:
> `/user-profiles`, `/line-items` (not camelCase, not underscores).
>
> Actions on resources: use sub-resources for named actions.
> `POST /orders/123/cancellations` (create a cancellation sub-resource).
> `POST /orders/123/confirmations`. This is more RESTful than
> `POST /orders/123/cancel`.
>
> Versioning in URL: `/api/v1/orders`. The version belongs in the
> URL for easy routing and visibility (not in headers).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to design REST URLs."

**(2) First principles:** "A URL is the address of a resource.
Resource names are nouns (what you are accessing, not what you are doing).
Operations are HTTP methods (how you access it)."

**(3) Bridge:** "Like a physical address: '123 Main St' is the
address (URL) of the house (resource). 'Give me', 'Paint', 'Demolish'
are operations on it (methods). The address doesn't include the
operation."

---

### 📘 Concept Explanation

**URL design patterns:**

```
RESOURCES (plural nouns):
  /products          - collection
  /products/{id}     - single item
  /products/{id}/reviews  - sub-collection

BAD vs GOOD URLs:
  BAD                          GOOD
  /getProducts                 GET /products
  /createProduct               POST /products
  /deleteProduct?id=123        DELETE /products/123
  /products/cancel?id=123      POST /products/123/cancellations
  /product_images              /product-images (hyphens)
  /Products                    /products (lowercase)
  /getUserOrders?userId=123    GET /users/123/orders

QUERY PARAMETERS:
  Filtering:  /orders?status=PENDING&customerId=123
  Sorting:    /orders?sort=createdAt,desc
  Pagination: /orders?page=0&size=20
              /orders?cursor=eyJpZCI6MTIzfQ
  Searching:  /products?q=laptop
  Fields:     /orders/123?fields=id,status,total

PATH PARAMETERS for identity:
  /orders/{orderId}
  /users/{userId}/orders/{orderId}
```

**The key insight:**
Sub-resources (`/users/123/orders`) express ownership or containment
in the domain model. However, deeply nested URLs (`/a/1/b/2/c/3/d/4`)
become unwieldy. Limit nesting to 2-3 levels. If a resource's
identity does not depend on a parent, it can be a top-level resource
referenced by ID.

---

### 💻 Code Example

**BAD - RPC-style URL design:**

```java
// BAD: Verbs in URLs, non-standard patterns
@GetMapping("/getUserById")         // verb in URL
@GetMapping("/getAllOrders")        // verb in URL
@PostMapping("/cancelOrder/{id}")   // should be sub-resource
@GetMapping("/getActiveOrders")     // should be query param
```

**GOOD - RESTful resource naming:**

```java
// GOOD: Noun-based resource URLs

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    // Collection: GET /api/v1/orders?status=PENDING
    @GetMapping
    public Page<OrderSummary> listOrders(
        @RequestParam(required = false) OrderStatus status,
        @RequestParam(required = false) String customerId,
        @RequestParam(defaultValue = "createdAt,desc")
            String sort,
        @PageableDefault(size = 20) Pageable pageable
    ) {
        return orderService.findAll(
            status, customerId, pageable
        );
    }

    // Single resource: GET /api/v1/orders/{orderId}
    @GetMapping("/{orderId}")
    public OrderResponse getOrder(
        @PathVariable String orderId
    ) {
        return orderService.findById(orderId);
    }

    // Sub-resource action: POST /api/v1/orders/{orderId}/cancellations
    // Creates a cancellation as a resource (idempotent-capable)
    @PostMapping("/{orderId}/cancellations")
    public ResponseEntity<CancellationResponse> cancelOrder(
        @PathVariable String orderId,
        @RequestBody @Valid CancellationRequest request
    ) {
        CancellationResponse response =
            orderService.cancel(orderId, request);
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .location(URI.create(
                "/api/v1/orders/" + orderId +
                "/cancellations/" + response.getId()
            ))
            .body(response);
    }
}
```

> **Code walkthrough:** The controller uses noun-based, resource-
> oriented URLs. The `listOrders` endpoint uses query parameters for
> filtering (`status`, `customerId`) and sorting - these are
> modifiers on the collection, not path segments. The `cancelOrder`
> operation is expressed as `POST /orders/{id}/cancellations` - creating
> a cancellation sub-resource - rather than `POST /orders/{id}/cancel`.
> This is more RESTful and allows `GET /orders/{id}/cancellations`
> to list all cancellations. Returning 201 with a `Location` header
> follows the pattern for resource creation.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Use nouns not verbs in URLs. Collections are plural. Operations
> are HTTP methods. Use path params for resource identity (`/orders/123`)
> and query params for filtering and pagination (`?status=PENDING&page=0`).

---

**Senior / Staff (5+ years):**
> The action-as-sub-resource pattern is the cleanest solution for
> domain actions that do not fit CRUD: `POST /orders/123/cancellations`
> is RESTful (creates a cancellation), idempotent-capable (using an
> idempotency key), and allows `GET /orders/123/cancellations` to
> list the cancellation history. This is more useful than
> `POST /orders/123/cancel` which cannot be GET-listed.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | Noun-based URLs + collection/item pattern |
| Mid | 4 min | Query params vs path params + actions |
| Senior | 5 min | Design an API for a given domain |

---

**[ARCHITECTURE] Design the REST API URL structure for an
e-commerce order management system.** `[MID]`

*Why they ask:* Practical URL design assessment.

Collections and items: `GET /orders` (list), `POST /orders` (create),
`GET /orders/{id}` (get), `PUT /orders/{id}` (replace),
`PATCH /orders/{id}` (partial update), `DELETE /orders/{id}` (delete).
Sub-resources: `GET /orders/{id}/line-items` (list items),
`POST /orders/{id}/line-items` (add item),
`DELETE /orders/{id}/line-items/{itemId}` (remove item). Actions
as sub-resources: `POST /orders/{id}/cancellations` (cancel),
`POST /orders/{id}/confirmations` (confirm). Customer orders:
`GET /customers/{customerId}/orders` (list a customer's orders).
Filtering and pagination: `GET /orders?status=SHIPPED&customerId=C123&sort=createdAt,desc&page=0&size=20`.

---

---

# HTTP Headers and Content Negotiation

🎯 Interview Weight: medium-high - Headers are the HTTP metadata
layer. Content negotiation enables serving multiple formats from
one endpoint.

---

### 🎯 Model Answer

**30 seconds:**
> HTTP headers carry metadata about the request and response. Content
> negotiation is the mechanism where client and server agree on the
> response format: the client sends `Accept: application/json` or
> `Accept: application/xml`, the server responds with
> `Content-Type: application/json` matching what it chose. This
> allows one URL to serve multiple formats.

**3 minutes (Senior):**
> HTTP headers serve several purposes:
>
> Content headers: `Content-Type` (what format is the body), `Accept`
> (what format the client accepts), `Content-Encoding` (is the body
> compressed?), `Accept-Encoding` (what compression the client accepts).
>
> Caching headers: `Cache-Control` (caching directive), `ETag` (resource
> version hash), `If-None-Match` (conditional GET using ETag),
> `If-Modified-Since` (conditional GET using timestamp), `Last-Modified`
> (when the resource last changed), `Expires` (absolute cache expiry).
>
> Security headers: `Authorization` (credentials), `WWW-Authenticate`
> (challenge for 401 responses), `Strict-Transport-Security` (HTTPS
> required), `Content-Security-Policy` (XSS protection).
>
> CORS headers: `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods`,
> `Access-Control-Allow-Headers` (from server), `Origin` (from client).
>
> Tracing headers: `X-Request-ID`, `X-Correlation-ID` (custom correlation),
> `traceparent` (W3C standard for distributed tracing).
>
> Content negotiation: the client specifies its preferences via `Accept`
> header. The server selects the best match from its supported formats
> and responds with `Content-Type` indicating what it chose. If no
> format is acceptable, 406 Not Acceptable.
>
> In Spring Boot: `@GetMapping(produces = {MediaType.APPLICATION_JSON_VALUE,
> MediaType.APPLICATION_XML_VALUE})` enables content negotiation.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about HTTP headers and how clients
and servers agree on the response format."

**(2) First principles:** "Headers carry metadata. Content-Type says
'here is what I am sending'. Accept says 'here is what I accept'.
Content negotiation is the handshake between these two."

---

### 📘 Concept Explanation

**Important headers by category:**

```
Request Headers (client -> server):
  Content-Type: application/json     - body format
  Accept: application/json           - desired response format
  Authorization: Bearer <jwt>        - auth credentials
  If-None-Match: "version-5"         - conditional request
  Cache-Control: no-cache            - bypass cache
  X-Request-ID: uuid-here            - client correlation ID
  Accept-Encoding: gzip, deflate     - compression support

Response Headers (server -> client):
  Content-Type: application/json     - response body format
  ETag: "version-5"                  - resource version
  Cache-Control: max-age=3600        - cache for 1 hour
  Location: /api/v1/orders/123       - created resource URL
  Retry-After: 60                    - rate limit recovery
  X-Request-ID: uuid-here            - echo client correlation
  WWW-Authenticate: Bearer           - 401 auth challenge
```

**Content negotiation quality factors:**

```
Accept: text/html,application/json;q=0.9,*/*;q=0.8

Parsed:
  text/html     q=1.0 (default, most preferred)
  application/json  q=0.9
  */*           q=0.8 (any format, least preferred)

Server chooses the highest-quality match it supports.
If no match: 406 Not Acceptable
```

**The key insight:**
`Cache-Control` is the most important header for API performance.
`Cache-Control: max-age=3600, public` enables CDN caching for
public resources (product catalog). `Cache-Control: private,
no-cache` prevents caching for user-specific data (account details).

---

### 💻 Code Example

**Content negotiation with Spring Boot:**

```java
// Spring Boot automatically negotiates content type
// based on Accept header and produces list

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    // Produces both JSON and XML
    // Spring picks based on Accept header
    @GetMapping(
        value = "/{productId}",
        produces = {
            MediaType.APPLICATION_JSON_VALUE,
            MediaType.APPLICATION_XML_VALUE
        }
    )
    public ProductResponse getProduct(
        @PathVariable String productId
    ) {
        // Spring serializes to JSON or XML automatically
        return productService.findById(productId);
    }

    // Setting cache headers for public read-only resources
    @GetMapping
    public ResponseEntity<List<ProductSummary>> listProducts() {
        List<ProductSummary> products =
            productService.findAll();

        return ResponseEntity.ok()
            .cacheControl(
                CacheControl
                    .maxAge(Duration.ofMinutes(5))
                    .cachePublic()  // CDN can cache
            )
            .eTag(
                Integer.toHexString(
                    products.hashCode()
                )
            )
            .body(products);
    }
}

// Using custom MIME type for API versioning via content type
@GetMapping(
    value = "/{id}",
    produces = "application/vnd.example.order.v2+json"
)
public OrderResponseV2 getOrderV2(
    @PathVariable String id
) {
    return orderService.findByIdV2(id);
}
```

> **Code walkthrough:** The first `getProduct` endpoint uses Spring's
> content negotiation: `produces` declares supported formats. Spring
> inspects the `Accept` header and serializes to JSON (using Jackson)
> or XML (using JAXB) accordingly. No extra code needed. The
> `listProducts` endpoint sets `Cache-Control: max-age=300, public`
> enabling CDN caching for 5 minutes, and includes an `ETag` based
> on the collection's hash. A CDN or proxy will serve cached responses
> without hitting the origin server. The custom MIME type
> `application/vnd.example.order.v2+json` demonstrates header-based
> API versioning as an alternative to URL versioning.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> HTTP headers carry metadata about request and response. Key headers:
> `Content-Type` (body format), `Authorization` (credentials), `ETag`
> (resource version for caching), `Cache-Control` (caching behavior).
> Content negotiation: client sends `Accept: application/json`, server
> responds with `Content-Type: application/json`.

---

**Senior / Staff (5+ years):**
> The Cache-Control header design for a REST API: resources fall into
> three categories. (1) Public, immutable: `Cache-Control: max-age=31536000, immutable`
> (product images, versioned assets). (2) Public, mutable: `Cache-Control: max-age=300, public, must-revalidate`
> (product catalog, prices). (3) Private or dynamic: `Cache-Control: private, no-cache`
> (user-specific data, account details). Correct cache headers at
> the API level have a direct impact on CDN hit rate and origin server
> load. A 90% CDN hit rate for a product catalog API means 90% fewer
> requests to the origin.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | Common headers + Content-Type/Accept |
| Mid | 3 min | Cache-Control + ETag + conditional requests |
| Senior | 5 min | Cache strategy design + content negotiation |

---

**[TRADE-OFF] When should you use header-based API versioning
vs URL-based versioning?** `[SENIOR]`

*Why they ask:* There are multiple versioning approaches with
different trade-offs.

*Likely follow-up:* "What are the limitations of header-based versioning?"

URL versioning (`/api/v2/orders`): visible in URLs (easy to test
with curl, easily routable at gateway level), obvious to developers,
appears in log entries naturally. Standard approach and most commonly
used. Limitation: multiple versions appear as different URLs,
complicating OpenAPI documentation. Header versioning (`Accept:
application/vnd.api.v2+json` or `API-Version: 2`): keeps URLs
clean - same URL for all versions. Preferred by purists (the URL
identifies the resource, not the version of the representation).
Limitation: harder to test (every request needs the header),
CDN routing is harder (must route by header, not URL), not obvious
in browser address bars or shared URLs. Content negotiation
versioning (`Accept: application/vnd.example.order.v2+json`): most
RESTful (using HTTP content type mechanism). Limitation: most complex
to implement, least well-understood by API consumers.
My recommendation: use URL versioning for public APIs (clear,
universally understood), header versioning for internal APIs where
clean URLs matter more. The key non-negotiable: be consistent
across all endpoints within an API. Mixing URL and header versioning
in the same API is worse than either alone.

*What separates good from great:* "URL versioning is always better"
without the trade-offs and the routing/testability considerations
that favor URL versioning.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Cache-Control + ETag + content negotiation |
| Bar Raiser | Header strategy + API versioning governance |

---

---

# Request and Response Body Formats

🎯 Interview Weight: medium - Body format choice affects client
compatibility, performance, and interoperability.

---

### 🎯 Model Answer

**30 seconds:**
> REST APIs use structured formats for request and response bodies.
> JSON (`application/json`) is the dominant format for web APIs.
> XML, Protocol Buffers, and MessagePack are alternatives for specific
> use cases. Multipart/form-data is used for file uploads. The format
> is negotiated via `Content-Type` and `Accept` headers.

**3 minutes (Senior):**
> Format selection trade-offs:
>
> JSON: human-readable, universally supported, every language has
> parsers. Drawback: verbose (keys repeat on every object in an
> array), no binary support, no schema enforcement by default.
> JSON is the correct choice for most REST APIs.
>
> XML: verbose but has schema validation (XSD), namespacing, and
> transformation (XSLT). Still required for some enterprise systems,
> SOAP interoperability, financial systems. More bytes than JSON
> for the same data.
>
> Protocol Buffers (protobuf): binary, schema-enforced (`.proto`
> files), 3-10x smaller than JSON, faster to parse. Used by gRPC.
> Not human-readable - cannot inspect in a browser. Suitable for
> internal high-performance APIs.
>
> MessagePack: binary JSON alternative. Schema-optional. Smaller
> than JSON but without protobuf's type safety.
>
> Multipart/form-data: required for file uploads. The body is
> split into parts (each with its own Content-Type). Binary files
> do not need base64 encoding (unlike JSON). For large files, use
> multipart upload directly to object storage (S3 presigned URLs).
>
> JSON pitfalls: large numbers (JavaScript's Number type loses
> precision for integers > 2^53, so use string for IDs and financial
> amounts), null vs absent fields (use `Optional` and configure
> Jackson to omit nulls), date formats (use ISO 8601:
> `2024-01-15T10:30:00Z`).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about what formats REST API bodies
use and how to choose."

**(2) First principles:** "The body carries the data payload. The
format must be understood by both sides. JSON won because every
browser and server supports it natively."

**(3) Bridge:** "Like shipping containers: JSON is the standard
container, universally accepted. Protobuf is a specialized container
- smaller and faster but requires special equipment to open."

---

### 💻 Code Example

**BAD - JSON pitfalls:**

```java
// BAD: Large ID as number loses precision in JavaScript
// BAD: Null fields included in response (noisy)
// BAD: Date as non-standard format

public class OrderResponse {
    private Long id;        // 9876543210987654L
    // JavaScript will parse this as 9876543210987656L!
    // (2^53 precision limit)

    private String status;
    private Date createdAt; // Serializes as epoch millis
    // Client must know it's millis, not seconds, not ISO

    private String cancelledAt; // null if not cancelled
    // null "cancelledAt" on every non-cancelled order is noise
}
```

**GOOD - JSON response design:**

```java
// GOOD: String IDs, ISO 8601 dates, null exclusion

@JsonInclude(JsonInclude.Include.NON_NULL)
public class OrderResponse {

    // String to avoid JavaScript precision issues
    private String id;           // "9876543210987654"

    private OrderStatus status;  // Enum serialized as string

    @JsonFormat(
        shape = JsonFormat.Shape.STRING,
        pattern = "yyyy-MM-dd'T'HH:mm:ssXXX"
    )
    private Instant createdAt;   // "2024-01-15T10:30:00Z"

    // Only present if cancelled - @NON_NULL removes when null
    @JsonFormat(
        shape = JsonFormat.Shape.STRING,
        pattern = "yyyy-MM-dd'T'HH:mm:ssXXX"
    )
    private Instant cancelledAt;

    // Financial amounts as string to preserve precision
    private String totalAmount;  // "1234.56" not 1234.56
    private String currency;     // "USD"
}

// Jackson config for consistent behavior
@Configuration
public class JacksonConfig {
    @Bean
    public ObjectMapper objectMapper() {
        return JsonMapper.builder()
            .addModule(new JavaTimeModule())
            // Prevent Instant -> epoch millis default
            .disable(
                SerializationFeature.WRITE_DATES_AS_TIMESTAMPS
            )
            // Omit null fields globally
            .serializationInclusion(
                JsonInclude.Include.NON_NULL
            )
            // Ignore unknown fields in requests
            .disable(
                DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES
            )
            .build();
    }
}
```

> **Code walkthrough:** The BAD example has three critical bugs.
> `Long id` serialized as a JSON number loses precision in JavaScript
> for IDs larger than 2^53 (about 9 quadrillion). `Date` serializes
> as epoch milliseconds - clients must know the unit. Null fields
> on every response add noise and force clients to null-check
> everything. The GOOD example uses `String id` (JavaScript-safe),
> `@JsonFormat` for ISO 8601 dates (universally understood), and
> `@JsonInclude(NON_NULL)` to omit absent optional fields. The
> Jackson `ObjectMapper` configuration disables epoch timestamps
> globally and ignores unknown fields in incoming requests (enabling
> forward compatibility when clients send new fields the server does
> not yet know).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JSON (`application/json`) is the standard for REST API bodies.
> Use ISO 8601 date format, string IDs, and exclude null fields.
> For file uploads use `multipart/form-data`. XML is used for
> legacy/enterprise systems.

---

**Senior / Staff (5+ years):**
> Financial APIs have strict body format requirements: all monetary
> amounts as strings (to avoid floating-point precision loss), all
> large IDs as strings (JavaScript 53-bit integer limit), all dates
> as ISO 8601 UTC. I also configure Jackson globally to:
> (1) omit null fields (cleaner responses, less bandwidth),
> (2) ignore unknown fields on deserialization (forward compatibility
> when clients send fields the server does not yet support),
> (3) serialize enums as strings not ordinals (ordinals break if
> the enum order changes).

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | JSON as default + content types |
| Mid | 3 min | JSON pitfalls (IDs, dates, nulls) |
| Senior | 5 min | Format selection trade-offs + JSON config |

---

**[DEBUGGING] A JavaScript client is getting incorrect order IDs
in the response. The server is sending the right ID but the client
shows a different number.** `[MID]`

*Why they ask:* Tests knowledge of JavaScript number precision limit.

*Likely follow-up:* "How do you fix this in the API response?"

The issue is JavaScript's `Number` type (IEEE 754 double-precision
float) can represent integers exactly only up to 2^53 (9,007,199,254,740,992).
Integers larger than this lose precision when parsed by `JSON.parse()`.
If the server is using a `Long` and serializing it as a JSON number,
any ID greater than 9 quadrillion will be corrupted. Fix: serialize
the ID as a string. In Jackson: annotate the field with
`@JsonSerialize(using = ToStringSerializer.class)` or configure
the `ObjectMapper` to serialize longs as strings globally.
The client uses the string value as-is (no JSON.parse number
conversion). Diagnostic: test in a browser console:
`JSON.parse('{"id": 9876543210987654}').id === 9876543210987656`
(returns true - showing corruption). This is a common bug in
systems that use Twitter-style snowflake IDs or database sequences
that grow large over time.

*What separates good from great:* Diagnosing the JavaScript
precision issue and fixing it at the serialization layer, not by
changing the ID generation strategy.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Jackson config + JSON pitfalls |
| Bar Raiser | Format selection at scale + client compatibility |
