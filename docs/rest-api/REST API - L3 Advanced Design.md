---
layout: default
title: "REST API - L3 Advanced Design"
parent: "REST API"
grand_parent: "SK Interview"
nav_order: 6
permalink: /rest-api/l3-advanced-design/
render_with_liquid: false
---

# HATEOAS and Hypermedia APIs

---

### 🎯 Model Answer

**30 seconds:**
> HATEOAS (Hypermedia as the Engine of Application State) is a REST constraint where API responses include links to related actions and resources. Instead of hardcoding URLs, clients discover available actions from the response. An order response includes links to cancel, ship, and get invoice actions. Clients follow links rather than constructing URLs.

**3 minutes:**
> HATEOAS is the highest level of REST maturity (Level 3 in Richardson's model). The core idea: a REST API client should need no prior knowledge of the URL structure. Every response includes a `_links` section with URLs for available next actions. GET /orders/123 returns the order data plus `_links: {self: '/orders/123', cancel: '/orders/123/cancel', invoice: '/orders/123/invoice', ship: '/orders/123/ship'}`. The client doesn't hardcode these URLs - it discovers them from the response. The theoretical benefit: the server can change URL structures without breaking clients (clients follow links, not hardcoded URLs). The practical reality: most HATEOAS implementations are aspirational. Real clients still hardcode entry points (they must know /orders to start). URL changes break bookmarks and API consumers who hardcode despite the links. HATEOAS adds significant response payload and serialization complexity. The legitimate value: state machine representation. The order is in PENDING state. Available actions are only `cancel` (you can't ship a pending order). The server includes only the links for currently-valid actions. The client UI renders the Cancel button because the cancel link is present. When the order ships, the cancel link disappears and track link appears. This dynamic UI control from server state is HATEOAS's genuine practical value.

**Blank Mind Recovery:**
**(1) Restate:** "HATEOAS - API responses include links to available next actions."
**(2) First principles:** "What if the client didn't need to know any URLs? Just follows the links the server provides."
**(3) Bridge:** "Like a web page - you don't type URLs, you click links. HATEOAS makes APIs work like web pages."

---

### 📘 Concept Explanation

**What it is:**
HATEOAS is a REST architectural constraint where API responses include hypermedia links that tell the client what actions are available from the current state, enabling clients to navigate the API by following links.

**The problem it solves:**
REST clients typically hardcode API URLs (`/v1/orders/{id}/cancel`). When URLs change, clients break. HATEOAS clients discover URLs from the responses - the server can change URL structure without breaking link-following clients. Additionally, HATEOAS enables state-driven UI: the server communicates which actions are valid in the current state via which links are present.

**How it works:**
```json
GET /orders/123
HTTP/1.1 200 OK

{
  "id": 123,
  "status": "pending",
  "items": [...],
  "total": 99.99,
  "_links": {
    "self": {
      "href": "/orders/123",
      "method": "GET"
    },
    "cancel": {
      "href": "/orders/123/cancel",
      "method": "POST"
    },
    "update": {
      "href": "/orders/123",
      "method": "PUT"
    }
  }
}

After order ships, state changes:
{
  "id": 123,
  "status": "shipped",
  "_links": {
    "self": {"href": "/orders/123"},
    "track": {"href": "/orders/123/tracking"},
    "invoice": {"href": "/orders/123/invoice"}
  }
  // cancel and update links ABSENT (invalid now)
}
```

**The key insight:**
The absence of a link IS information. A client renders a Cancel button only when the cancel link is present. When it's gone, the button disappears. The server encodes the order's state machine in the presence/absence of links. This moves state machine logic from clients to the server - a single source of truth.

**When to use it:**
Complex state machines where valid transitions depend on current state. Resource discovery APIs (HAL Browser, API explorers). APIs where state-driven UI behavior is valuable.

**When NOT to use it:**
Simple CRUD APIs - HATEOAS adds complexity without value. Internal APIs where clients are controlled. Mobile APIs where bandwidth matters (links add payload).

**Alternatives:**
- Explicit state field with enum of allowed actions: `{"status":"pending","allowedActions":["cancel","update"]}`
- Client-side state machine with server-provided state enum
- GraphQL mutations with available fields per type

**First-principles derivation:**
The web is a hypermedia system: browsers follow links, don't hardcode URLs. REST was designed by Roy Fielding to capture the properties that made the web scalable. HATEOAS is the REST constraint that mirrors the web's navigation model. The web has never broken even as URLs changed because browsers follow links. HATEOAS applies the same principle to API clients.

---

### 💻 Code Example

```java
// Spring HATEOAS implementation

@RestController
@RequestMapping("/orders")
public class OrderController {

  private final OrderService orderService;
  
  @GetMapping("/{id}")
  public EntityModel<OrderDto> getOrder(
      @PathVariable Long id) {
    
    Order order = orderService.findById(id);
    OrderDto dto = orderMapper.toDto(order);
    
    // Build links dynamically based on order state
    EntityModel<OrderDto> model =
        EntityModel.of(dto,
            linkTo(methodOn(OrderController.class)
                .getOrder(id))
                .withSelfRel());
    
    // Add links based on current state
    if (order.canCancel()) {
      model.add(linkTo(
          methodOn(OrderController.class)
              .cancelOrder(id))
          .withRel("cancel"));
    }
    
    if (order.canShip()) {
      model.add(linkTo(
          methodOn(OrderController.class)
              .shipOrder(id))
          .withRel("ship"));
    }
    
    if (order.isShipped()) {
      model.add(linkTo(
          methodOn(OrderController.class)
              .getTracking(id))
          .withRel("tracking"));
    }
    
    return model;
  }
}

// Response with HAL (Hypertext Application Language):
// {
//   "id": 123,
//   "status": "pending",
//   "_links": {
//     "self": {"href": "/orders/123"},
//     "cancel": {"href": "/orders/123/cancel"}
//   }
// }
```

> **Code walkthrough:** Spring HATEOAS's `EntityModel` wraps the DTO with a `_links` section. `linkTo(methodOn(...))` generates URLs from controller method references - if the URL changes (due to refactoring), the links update automatically. The state-driven logic (`canCancel()`, `canShip()`) is on the domain object, keeping business logic out of the controller. The client receives only the links for actions valid in the current state.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "HATEOAS adds links to API responses showing what actions are available. Instead of hardcoding URLs like /orders/123/cancel, the client reads the cancel link from the response. The benefit is state-awareness: a pending order response includes a cancel link. A shipped order doesn't. The client shows buttons based on which links are present."

**Senior / Staff:** "HATEOAS is theoretically elegant but has poor adoption in practice. The ideal: a generic HATEOAS client that navigates any REST API by following links. The reality: clients hardcode the root entry point and follow links inconsistently. URL changes break clients regardless of HATEOAS because bookmarks, mobile apps, and cached links are everywhere. The value I find legitimate: the state machine representation - using link presence/absence to drive available client-side actions. This is a cleaner alternative to `allowedActions: ['cancel', 'update']` because the links already carry the URL, method, and action identifier in a standard structure. For most internal APIs: the complexity cost of Spring HATEOAS exceeds the benefit. Use a simple `allowedActions` array or a status field with a well-documented state machine. For public APIs with complex resources: HAL format with `_links` is worth the investment."

---

### ⚠️ Common Misconceptions

**Misconception:** "HATEOAS means clients never need to hardcode any URLs."
Reality: Every HATEOAS client must hardcode at least one URL - the entry point (the root or the first resource URL). You can't discover links without starting somewhere. The practical limit: HATEOAS reduces (not eliminates) hardcoded URLs from N to 1 (or a handful of root URLs). Additionally, clients must still know the link relation names (cancel, ship, invoice) to do anything useful - these are a contract that changes break. The deeper issue: most API consumers don't implement HATEOAS link following. They read the JSON, find the id field, and construct the URL manually. Without disciplined client implementation, HATEOAS links become documentation that the client ignores. For HATEOAS to deliver its promised benefit: the client must be written to follow links (not hardcode). This requires a different client design philosophy that most teams don't adopt.

---

### 🚨 Failure Modes and Diagnosis

**Failure: HATEOAS links have incorrect host/scheme in production**

Symptoms: API returns `_links: {self: {href: "http://internal-service:8080/orders/123"}}` in production. The link uses the internal container hostname instead of the public API URL. Clients clicking the link get connection refused.

Root cause: Spring HATEOAS generates links using the request's Host header and scheme. In a containerized environment, the Host header may reflect the internal service address, not the public API URL.

Diagnosis: `curl -v /orders/123` in production - check the `_links.self.href` value. Does it contain the internal hostname?

Fix: Configure Spring HATEOAS's `ForwardedHeaderFilter` to use the X-Forwarded-Host and X-Forwarded-Proto headers set by the load balancer. Or set a fixed base URL: `spring.hateoas.default-media-type=application/hal+json`. In the load balancer: set `X-Forwarded-Host: api.mysite.com` and `X-Forwarded-Proto: https` on all requests.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Comparison | 3 min | 2 |
| Trade-off | 3 min | 2 |
| Mechanism | 2 min | 1 |
| Design | 3 min | 1 |
| Behavioral | 2 min | 1 |

#### Q1 - "What is the Richardson Maturity Model and where does HATEOAS fit?"
> "Richardson Maturity Model: four levels of REST API design maturity. Level 0: one endpoint, one method. RPC-style: `POST /api/command` with action in the body. Level 1: resources. Separate endpoints per resource: `/orders`, `/users`. Level 2: HTTP verbs. Use HTTP methods correctly: GET to read, POST to create, PUT to update, DELETE to delete. HTTP status codes carry meaning (200, 201, 404, 409). Most commercial APIs are at Level 2. Level 3: HATEOAS. Responses include hypermedia links for available next actions. The API is self-describing. The level that matters most for interviews: Level 2. Almost all 'RESTful' APIs in practice are Level 2. Level 3 is aspirational. The model's value: it gives vocabulary for discussing API design quality. A Level 2 API is RESTful in the practical sense. A Level 0 API is HTTP transport for RPC calls. The common mistake: calling your API 'REST' when it's Level 0 or 1. Richardson's model makes the distinction precise."

*What separates good from great:* "Knowing that 'most commercial APIs are Level 2' and that Level 3/HATEOAS is aspirational shows realistic industry perspective. Candidates who confidently explain why Level 2 is the practical standard over Level 3 show production experience over theory."

---

#### Q2 - "Compare HATEOAS to GraphQL for resource discovery."
> "HATEOAS and GraphQL solve different discovery problems. HATEOAS: runtime link discovery. The client follows server-provided links to find available actions. Decouples client from URL structure. Dynamic state representation (links change with state). GraphQL: schema-based type discovery. The client queries the schema to find all types, fields, and mutations. Introspection allows tools to auto-generate clients, documentation, and type-safe queries. Static discovery (the schema changes between deployments, not per-resource). The client experience: HATEOAS client reads response links, makes follow-on requests to linked resources. GraphQL client queries exactly the fields it needs in one request. For complex related data: GraphQL avoids the N+1 request problem that HATEOAS link-following creates (follow order link -> follow customer link -> follow address link = 3 requests). GraphQL can fetch all in one query. For state machines: HATEOAS has no GraphQL equivalent for dynamic action availability. GraphQL mutations are static (always defined). HATEOAS links are dynamic (present only for valid state transitions). For most modern APIs: GraphQL is adopted for its query flexibility and type system. HATEOAS is adopted for its state machine representation. They're not direct competitors."

*What separates good from great:* "The N+1 request problem with HATEOAS link-following (multiple round trips to traverse the link graph) vs GraphQL single-query fetching shows you've implemented both and understand the operational difference."

---

#### Q3 - "A team member proposes adding HATEOAS to your existing REST API. How do you evaluate the proposal?"
> "Evaluation framework: (1) What problem are they solving? If clients are hardcoding URLs that change: HATEOAS addresses URL coupling. But evaluate: are the URLs actually changing? Stable, versioned URL structures don't need HATEOAS. (2) What are the clients? If all clients are JavaScript SPAs or mobile apps you control: you can update them when URLs change. HATEOAS benefit is marginal. If the API is public (third-party integrations, partners): stable URLs are more valuable than HATEOAS links. (3) Does the resource have a complex state machine? Pending -> processing -> shipped -> delivered with different allowed actions per state? HATEOAS links map naturally to this. If CRUD only: HATEOAS is overhead. (4) What's the cost? Response size increases (links add payload). Server complexity increases (link generation logic). Client complexity increases (link following instead of URL construction). Documentation complexity increases (clients must understand link relation semantics). (5) Incremental adoption: you can add HATEOAS to one resource (orders) without changing others. Start small and measure client adoption. If no clients use the links after 3 months: remove them. My recommendation: if the team is building a new API with complex state machines for third-party clients - evaluate HAL format. For an existing API with internal clients: the migration cost likely exceeds the benefit."

*What separates good from great:* "The incremental adoption suggestion (one resource first, measure client adoption) and the time-boxed evaluation (3 months) shows pragmatic staff engineer thinking over theoretical idealism."

---

#### Q4 - "What is HAL and how does it relate to HATEOAS?"
> "HAL (Hypertext Application Language) is a media type that specifies a standard JSON format for HATEOAS links. Without HAL, different APIs put links in different places: `links: [...]`, `_href: ...`, `related: {...}`. With HAL: always `_links` property, always `href` property inside each link, standard structure for embedded resources (`_embedded`). HAL example: `{data: {...}, _links: {self: {href: '/orders/123'}, cancel: {href: '/orders/123/cancel', title: 'Cancel Order'}}}`. The title field in HAL links is a human-readable label. Spring HATEOAS defaults to HAL for responses with `application/hal+json` media type. HAL Browser: a generic web interface that can browse any HAL API by following `_links`. This is the 'promise' of HATEOAS - a client that works with any HAL API without custom integration. The reality: HAL Browser is useful for exploring APIs, not for building production clients. Production clients need specific link relations (cancel, track) with known semantics. A generic link follower can't know that cancel is a destructive action. Other hypermedia formats: JSON:API (different envelope format), Siren (form-based actions with types and fields), Collection+JSON (for collections). HAL is the most widely adopted for Spring/Java ecosystems."

*What separates good from great:* "Knowing HAL Browser as the generic HATEOAS API explorer and why it's limited (can't know the semantics of link relations) shows you've actually used HATEOAS tooling."

---

#### Q5 - "When would you NOT implement HATEOAS despite it being theoretically better?"
> "Cases where HATEOAS is not worth the cost: (1) Internal microservices with contract testing: teams using Pact for consumer-driven contracts can safely change URLs with all affected consumers verified. HATEOAS provides no additional decoupling when contracts are tested. (2) High-throughput APIs: each response carries link payload. At 10,000 requests/second with 5 links per response averaging 200 bytes per link block: 1MB/s of extra bandwidth for links that no client uses. (3) Simple CRUD APIs: a user settings API with GET/PUT on a few fields has no state machine, no transitions, and no discovery value. Links would be a documentation exercise with no runtime value. (4) Mobile APIs: mobile apps are long-lived and cache aggressively. A mobile client that followed a cached HATEOAS link pointing to an old URL would be broken anyway. Mobile clients hardcode the stable versioned base URL. (5) Teams without discipline for link following: if the client team will read the id from the response and construct `/orders/{id}/cancel` anyway (ignoring the link), HATEOAS links become dead weight. Measuring this is simple: log whether the cancel link is ever actually used in a request by clients. If it's consistently ignored: remove it."

*What separates good from great:* "The bandwidth calculation (5 links × 200 bytes × 10K req/s = 1MB/s) and the logging-to-measure-adoption approach show staff-level pragmatism. Most candidates either advocate for or against HATEOAS theoretically; this answer shows empirical measurement thinking."

---

#### Q6 - "Describe the state machine design for an e-commerce order and how HATEOAS would represent it."
> "Order state machine: PENDING (just created) -> CONFIRMED (payment verified) -> PROCESSING (warehouse picking) -> SHIPPED (with tracking) -> DELIVERED (confirmed receipt). Also: PENDING -> CANCELLED, CONFIRMED -> CANCELLED (before processing starts). The HATEOAS link map: PENDING: self, cancel, update, confirm (add payment). CONFIRMED: self, cancel, track (no yet - not shipped). PROCESSING: self, track (for warehouse status). SHIPPED: self, track (public carrier tracking). DELIVERED: self, invoice, review. CANCELLED: self, refundStatus. Client behavior: render only the action buttons corresponding to present links. A mobile app shows 'Cancel Order' only when the cancel link is present. The button disappears automatically when the order moves to PROCESSING (server stops including the cancel link). No client-side state machine needed - the server drives the UI. Implementation: the Order domain object has `getAllowedLinks()` method that examines the current status and returns a list of allowed link relations. The HATEOAS controller calls this method to generate the `_links` section. State machine transitions in the domain: `order.confirm()` throws `InvalidStateException` if not in PENDING/CONFIRMED status. The domain enforces transitions; HATEOAS reflects them."

*What separates good from great:* "The implementation detail of `getAllowedLinks()` on the domain object (keeping state machine logic in the domain, not the controller) and the mobile UI behavior driven by link presence/absence shows how HATEOAS actually integrates into a real system."

---

---

# Error Handling and Problem Details

---

### 🎯 Model Answer

**30 seconds:**
> REST API error responses should use HTTP status codes correctly AND include a machine-readable error body. RFC 9457 (Problem Details) is the standard format: `{"type": "/errors/insufficient-balance", "title": "Insufficient Balance", "status": 402, "detail": "Your balance is $10.00 but the order total is $25.00."}`. This enables clients to handle errors programmatically without parsing human error messages.

**3 minutes:**
> Error handling has two layers: the HTTP status code communicates the error category, and the response body provides machine-readable details. HTTP status codes are not sufficient alone: 400 could mean invalid JSON, missing required field, business rule violation, or rate limit. Each needs different client handling. The response body discriminates. RFC 9457 Problem Details is the standard for REST API error bodies. The `type` field is a URI identifying the specific error type (a URL that could link to documentation). The `title` is human-readable. The `status` echoes the HTTP status code. The `detail` explains this specific occurrence. Extensions add domain-specific fields: `{"balance": 10.00, "required": 25.00}`. This structured error format enables clients to: catch specific error types (`if (error.type == '/errors/insufficient-balance') showTopUpDialog()`), display accurate user messages (the `detail` field is safe to show users), and handle errors programmatically without brittle string parsing. Spring Boot's problem detail support is built in via `@ControllerAdvice` and `ProblemDetail` class. Spring Boot 3+ includes automatic Problem Details for standard exceptions.

**Blank Mind Recovery:**
**(1) Restate:** "REST error handling - structured error responses clients can handle programmatically."
**(2) First principles:** "What does a client need from an error? Which category (status code), what specifically went wrong (type URI), how to display it (detail), what to do next (documentation link)."
**(3) Bridge:** "Like a diagnostic code from a doctor: a code number (status), a diagnosis name (type), and an explanation (detail). The patient (client) understands exactly what happened."

---

### 📘 Concept Explanation

**What it is:**
REST error handling is the design of API error responses to be informative, consistent, and machine-readable. RFC 9457 Problem Details provides a standard JSON schema for error responses.

**The problem it solves:**
Inconsistent error formats force clients to handle errors differently for each API. Unstructured errors (just an HTTP status code, or `{"error": "something went wrong"}`) cannot be handled programmatically. Leaking implementation details (stack traces, SQL error messages) in error responses is a security risk.

**How it works:**
```
RFC 9457 Problem Details format:

HTTP/1.1 422 Unprocessable Entity
Content-Type: application/problem+json

{
  "type": "https://api.myapp.com/errors/
           insufficient-balance",
  "title": "Insufficient Balance",
  "status": 422,
  "detail": "Account balance $10.00 is below
             the required $25.00.",
  "instance": "/orders/attempt-789",
  // Extension fields (domain-specific)
  "balance": 10.00,
  "required": 25.00,
  "accountId": "acc-123"
}

Validation error (multiple errors):
HTTP/1.1 400 Bad Request
Content-Type: application/problem+json

{
  "type": "https://api.myapp.com/errors/
           validation-failed",
  "title": "Validation Failed",
  "status": 400,
  "detail": "Request validation failed.",
  "errors": [
    {
      "field": "email",
      "code": "INVALID_FORMAT",
      "message": "Must be a valid email address"
    },
    {
      "field": "age",
      "code": "MIN_VALUE",
      "message": "Must be at least 18"
    }
  ]
}
```

**The key insight:**
The error `type` URI is a machine-readable identifier that clients can use for conditional error handling without string parsing. Different error types for the same HTTP status code enable specific handling: `insufficient-balance` shows a top-up dialog. `account-locked` redirects to the support page. Both are 422 but need completely different client behavior.

**When to use it:**
All REST APIs that have clients doing programmatic error handling. Any public API. Any API where the client needs to show meaningful error messages to end users.

**When NOT to use it:**
Internal debug endpoints where detailed exception info is acceptable. Health check endpoints.

**Alternatives:**
- Error codes in a custom format: `{"code": "INSUF_BAL", "message": "..."}` - works but non-standard
- Error objects in the response body with HTTP 200: anti-pattern common in legacy APIs. Forces clients to check the body even for success responses.
- GraphQL errors array: format for GraphQL-specific error handling

**First-principles derivation:**
Errors are part of the API contract. A client that cannot distinguish between "invalid JSON" and "business rule violation" (both are 400) cannot handle errors appropriately. The error response must communicate: what category (HTTP status), what specifically (type URI), what for this instance (detail), and optionally what to do (extensions with actionable data). RFC 9457 standardizes this to avoid each API inventing its own format.

---

### 💻 Code Example

```java
// Spring Boot 3+ Problem Details

@ControllerAdvice
public class GlobalExceptionHandler {

  // Handle domain exceptions -> Problem Details
  @ExceptionHandler(
      InsufficientBalanceException.class)
  public ResponseEntity<ProblemDetail>
      handleInsufficientBalance(
          InsufficientBalanceException ex,
          HttpServletRequest request) {

    ProblemDetail problem = ProblemDetail
        .forStatusAndDetail(
            HttpStatus.UNPROCESSABLE_ENTITY,
            ex.getMessage());

    problem.setType(URI.create(
        "https://api.myapp.com/errors/"
        + "insufficient-balance"));
    problem.setTitle("Insufficient Balance");
    problem.setInstance(
        URI.create(request.getRequestURI()));

    // Domain-specific extension fields
    problem.setProperty("balance",
        ex.getCurrentBalance());
    problem.setProperty("required",
        ex.getRequiredAmount());

    return ResponseEntity
        .unprocessableEntity()
        .contentType(
            MediaType.APPLICATION_PROBLEM_JSON)
        .body(problem);
  }

  // Handle validation errors
  @ExceptionHandler(
      MethodArgumentNotValidException.class)
  public ResponseEntity<ProblemDetail>
      handleValidation(
          MethodArgumentNotValidException ex) {

    ProblemDetail problem = ProblemDetail
        .forStatus(HttpStatus.BAD_REQUEST);
    problem.setType(URI.create(
        "https://api.myapp.com/errors/"
        + "validation-failed"));
    problem.setTitle("Validation Failed");
    problem.setDetail(
        "Request validation failed.");

    // Collect all field errors
    List<Map<String, String>> fieldErrors =
        ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .map(e -> Map.of(
                "field", e.getField(),
                "code",
                    e.getCode() != null
                        ? e.getCode() : "INVALID",
                "message",
                    e.getDefaultMessage() != null
                        ? e.getDefaultMessage()
                        : "Invalid"))
            .toList();

    problem.setProperty("errors", fieldErrors);

    return ResponseEntity.badRequest()
        .contentType(
            MediaType.APPLICATION_PROBLEM_JSON)
        .body(problem);
  }

  // Catch-all: never leak internal exceptions
  @ExceptionHandler(Exception.class)
  public ResponseEntity<ProblemDetail>
      handleUnexpected(Exception ex,
          HttpServletRequest request) {

    // Log internally with full details
    log.error("Unexpected error: {} {}",
        request.getMethod(),
        request.getRequestURI(), ex);

    // Return safe generic error
    ProblemDetail problem = ProblemDetail
        .forStatusAndDetail(
            HttpStatus.INTERNAL_SERVER_ERROR,
            "An unexpected error occurred.");
    problem.setType(URI.create(
        "https://api.myapp.com/errors/internal"));
    problem.setTitle("Internal Server Error");

    return ResponseEntity
        .internalServerError()
        .contentType(
            MediaType.APPLICATION_PROBLEM_JSON)
        .body(problem);
  }
}
```

> **Code walkthrough:** Three exception handlers in a single `@ControllerAdvice`: (1) Domain exception handler for business rule violations - returns specific type URI and domain-specific extension fields (balance, required). (2) Validation exception handler - collects all field errors into a structured errors array. (3) Catch-all handler - logs the full exception internally but returns a SAFE generic error to the client. Never leaking stack traces or exception messages is a security requirement. The content type is `application/problem+json` (RFC 9457 media type), distinguishing error responses from success responses.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "I handle errors in REST APIs using HTTP status codes and a consistent error response body. I use Spring's `@ControllerAdvice` and `@ExceptionHandler` to convert exceptions to error responses. The error body includes a message describing what went wrong. I try to use specific status codes: 400 for invalid input, 404 for not found, 409 for conflicts, 422 for business rule violations, 500 for unexpected errors."

**Senior / Staff:** "Error handling is a first-class API design concern, not an afterthought. The RFC 9457 Problem Details standard solves the format question - don't invent a proprietary error schema. The critical design decisions: (1) Error type URIs must be stable identifiers. Clients write `if (error.type == 'X')` - that type must never change. Put it under a stable path. (2) Never include internal information in 500 errors. Log everything internally; return only a correlation ID. `errorId: 'f8a3d2b1'` allows ops to find the log entry. (3) Validation errors need to return ALL validation failures in one response, not just the first. The client shows all fields with errors simultaneously, not one at a time. (4) Use the correct status code: 400 (client input error), 401 (not authenticated), 403 (authenticated but not authorized), 404 (resource not found), 409 (state conflict), 422 (business rule violation - valid structure, invalid semantics), 429 (rate limited), 500 (server error). The 422 vs 400 distinction: 400 is a technical error (invalid JSON, wrong type). 422 is a semantic error (valid request, violated business rule). Clients handle these differently."

---

### ⚠️ Common Misconceptions

**Misconception:** "Returning HTTP 200 with an error flag in the body is just another valid pattern."
Reality: This anti-pattern, common in legacy SOAP/RPC systems, forces every client to check the body even after receiving a success status code. HTTP status codes exist precisely to communicate the outcome category without body inspection. The practical consequences: HTTP caches serve 200 responses from cache even when they contain errors. Load balancers and health checks interpret 200 as success. Monitoring tools alert on 5xx rates, not body-level errors. Client error handling becomes complex: you check the status code AND inspect the body for every request. The correct approach: use HTTP status codes for their intended purpose. 2xx = success. 4xx = client error. 5xx = server error. If an operation partially succeeds (some items processed, some failed): return 207 Multi-Status with a body describing each item's outcome. GraphQL's always-200 approach is the exception - GraphQL has its own error model that compensates, and even there it's considered a trade-off, not a best practice.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Error responses leaking database schema in production**

Symptoms: API returns `{"error": "Column 'users.email_adress' doesn't exist: SELECT * FROM users WHERE email_adress = ?"}`. The error message from the database is returned directly to the API caller. A typo in a column name in a SQL query is visible to external clients.

Root cause: A generic exception handler that catches all exceptions and returns `exception.getMessage()` directly. This leaks database errors, SQL queries, column names, and schema details to API consumers.

Diagnosis: Invoke an endpoint with invalid input that triggers a database error. If the response contains SQL keywords or column names: this leaking is happening.

Fix: Catch-all exception handler must NOT use `exception.getMessage()` in the response. Log internally with full details. Return a generic "An error occurred" message with an internal error ID. In Spring: ensure the global `@ControllerAdvice` has an `@ExceptionHandler(Exception.class)` method that returns a safe Problem Detail. Also: disable Spring Boot's `/error` endpoint default behavior which may also leak exception messages (set `server.error.include-message=never` and `server.error.include-exception=false` in production).

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 2 min | 1 |
| Design | 3 min | 2 |
| Security | 3 min | 1 |
| Debugging | 2 min | 1 |
| Comparison | 2 min | 1 |
| Trade-off | 2 min | 1 |
| Behavioral | 2 min | 1 |

#### Q1 - "What HTTP status code would you use for a business rule violation?"
> "422 Unprocessable Entity. The request was technically valid (correct JSON structure, correct field types) but violated a business rule (insufficient balance, duplicate email, invalid state transition). 400 Bad Request: use for technically malformed requests (invalid JSON, wrong data type, missing required field at input validation layer). 422 Unprocessable Entity: use for semantically invalid requests (technically valid but business logic rejects it). Why the distinction matters: clients can handle 400 errors by fixing the request format (validate fields, add missing data). Clients handle 422 errors differently based on the specific business rule (show top-up dialog for insufficient funds, show 'email taken' error for duplicates). The differentiation requires different client logic. 409 Conflict: use when the request is valid but conflicts with the current state (trying to create a resource that already exists, or an optimistic locking conflict). 404 Not Found: resource doesn't exist. Don't return 404 for a user that exists but the current user can't access - that's 403 Forbidden (to avoid information disclosure). 403 vs 401: 401 means not authenticated (no credentials). 403 means authenticated but not authorized (credentials valid, but no permission)."

*What separates good from great:* "The 422 vs 400 distinction (technical vs semantic error) and the 403 vs 404 security consideration (returning 403 for inaccessible resources vs 404 to prevent information disclosure) are the nuanced status code decisions."

---

#### Q2 - "How do you design error responses for validation failures with multiple errors?"
> "Return all validation errors in one response - never make clients round-trip multiple times to discover all validation issues. Format: `HTTP 400 Bad Request` with an errors array in the Problem Details body: `{type: 'validation-failed', errors: [{field: 'email', code: 'INVALID_FORMAT', message: 'Must be valid email'}, {field: 'age', code: 'MIN_VALUE', message: 'Must be 18+'}]}`. The `field` identifies which field failed. `code` is a machine-readable error code (not a human message). `message` is the human-readable message safe to display. Why `code` AND `message`: the code lets clients apply their own locale-specific message. The message is a fallback. In Spring: `MethodArgumentNotValidException` collects all `@Valid` failures before throwing. `getBindingResult().getFieldErrors()` returns all field errors. Without `@Valid`: manual validation that throws on the first error creates a frustrating client experience. Use Spring's validation framework or Bean Validation (JSR-380). For nested objects: use the full path as the field name: `address.postalCode`. For array items: `items[2].quantity`. For cross-field validation errors (passwords don't match): use `null` or the class name as the field, or a separate `globalErrors` array."

*What separates good from great:* "The `code` + `message` separation (machine-readable code for programmatic handling, human message as fallback) and the full path for nested field names (`address.postalCode`, `items[2].quantity`) show production validation error design experience."

---

#### Q3 - "How do you handle errors in a microservices environment where one service's error propagates to the client?"
> "Error propagation in microservices requires a translation layer. Service A calls Service B, which returns an error. Service A should not blindly forward Service B's error to the client. Translation rules: (1) Technical infrastructure errors from downstream should become 503 Service Unavailable or 500 Internal Server Error at the API boundary. The client doesn't need to know that Order Service is down - they need to know 'orders are temporarily unavailable.' (2) Business errors from downstream may propagate with transformation. If Payment Service returns `insufficient-balance`, Order Service propagates this as a payment-specific error to the client - but translated to the Order Service's error vocabulary. (3) Internal details must never leak. Service B's internal error IDs, stack traces, and system names should not appear in the response to the external client. Use correlation IDs to link external error reports to internal log traces: the client gets `errorId: 'f8a3d2b1'`. Operations searches logs for that ID to find the complete internal error chain. Implementation: circuit breakers (Resilience4j) return fallback responses when downstream services fail. The fallback response must follow the Problem Details format with an appropriate 503 status."

*What separates good from great:* "The translation layer requirement (never blindly forward downstream errors) and the correlation ID pattern (client gets a safe ID, ops can find the full trace) are the production microservices error handling patterns."

---

#### Q4 - "You're getting reports that your API is returning 500 errors but you can't find them in the logs. How do you investigate?"
> "Missing 500s in logs despite client reports: (1) Load balancer or CDN is returning the 500, not your application. The CDN times out waiting for the application and returns 504 to the client (client may see it as 500). The application never processes the request, so no logs. Diagnosis: compare client-reported error times with load balancer access logs and application logs. If load balancer shows 500 but application shows nothing: the request never reached the application. (2) Application crashed and is restarting. JVM OOM, segfault, or uncaught exception on startup. The application returns nothing (connection refused) or incomplete response. Diagnosis: check container/process restart events. (3) Log level filtering. The 500 handler logs at ERROR level, but the log configuration is set to INFO. ERROR logs are dropped. Check the log level configuration for the exception handler package. (4) Log aggregation lag. The 500 happened, was logged, but the log aggregator hasn't ingested it yet (Logstash/Fluentd ingestion lag). Wait a few minutes and search again. (5) Wrong correlation between client reports and logs. Client reports are delayed (user noticed error 10 minutes after it occurred). The log timestamp doesn't match the client's reported time. Search a wider time window."

*What separates good from great:* "The load balancer 504 appearing as 500 to the client is the production debugging insight. The request never reaching the application but clients seeing an error is a common on-call investigation scenario."

---

#### Q5 - "What is the difference between error type URI and error code in API error design?"
> "Two different identifier styles for error types. Error code (string enum): `{'code': 'INSUFFICIENT_BALANCE'}`. Simple, consistent, version-safe. Does not resolve to documentation. Error type URI: `{'type': 'https://api.myapp.com/errors/insufficient-balance'}`. Resolvable: the URL can serve HTML documentation about this error type. Globally unique: `type` URIs are unique across all APIs (unlike error codes that may collide between systems). Self-describing: the URI path communicates the error taxonomy. RFC 9457 recommends type URIs for these reasons. The pragmatic reality: type URIs that actually resolve to documentation are valuable. URIs that return 404 or an empty page are type URIs in name only - they add payload without adding value. Recommendation: if you commit to type URIs, host actual documentation at each URI. An error documentation page: error title, when it occurs, extension fields description, how to resolve. This is the RFC 9457 intent. If documentation hosting is not feasible: use stable string error codes. Error codes are better than type URIs that don't resolve - they're simpler and equally machine-readable."

*What separates good from great:* "The pragmatic recommendation (type URIs only if documentation is hosted there; otherwise error codes are fine) shows RFC 9457 RFC awareness combined with operational realism."

---

#### Q6 - "How do you implement a global error ID / correlation ID system for API errors?"
> "Error ID: a unique identifier for a specific error occurrence. Returned to the client in the error response. Used by operations to find the full error context in logs. Implementation: generate a UUID in the error handler: `String errorId = UUID.randomUUID().toString()`. Include in the Problem Detail: `problem.setProperty('errorId', errorId)`. Include in the log: `log.error('Error {} processing {} {}: {}', errorId, request.getMethod(), request.getRequestURI(), ex.getMessage(), ex)`. The client can then contact support with the errorId and support can find the exact log entry, stack trace, and context. The correlation ID (X-Request-Id or traceparent) is different from the error ID: the correlation ID is set at request entry and propagated through the system. The error ID is generated when the error occurs. For a failed request: use the correlation ID to find all log entries (across microservices) for that request. The error ID specifically identifies the error handler's log entry. Best practice: use the correlation ID as the primary lookup in distributed systems. Use the error ID for single-service error lookup. Return both to the client in error responses: `{errorId: 'err-123', correlationId: 'req-456', ...}`."

*What separates good from great:* "The distinction between correlation ID (follows the full request through microservices) and error ID (identifies the specific error occurrence in one service) and returning both to the client is the complete production observability pattern."

---

#### Q7 - "How does error response design relate to API security?"
> "Three security principles in error response design: (1) Never leak internal details. Exception messages, stack traces, SQL queries, column names, internal service names, infrastructure details. All of these are attack reconnaissance. A stack trace tells an attacker what framework version you use (look up known vulnerabilities). A SQL error message tells them your table and column names (facilitates SQL injection). The rule: log everything internally, return nothing sensitive externally. Use generic messages for 500 errors. Use error IDs to link client reports to internal logs without exposing the logs themselves. (2) Consistent error responses for security-sensitive operations. `GET /users/123` for a non-existent user: return 404. `GET /users/123` for a user that exists but the current user can't access: also return 404 (not 403). Why: 403 confirms the resource exists. An attacker enumerating user IDs can distinguish 'user exists but I can't access it' (403) from 'user doesn't exist' (404). Information disclosure. Exception: authenticated admin endpoints where the user can be expected to know whether the resource exists. (3) Rate limit errors must not include sensitive data. The 429 response shouldn't include other users' rate limit state. Only the current client's remaining quota."

*What separates good from great:* "The 404 vs 403 information disclosure prevention (returning 404 for both 'not found' AND 'found but unauthorized' to prevent resource enumeration) is the OWASP security design pattern. Most candidates know 'don't leak stack traces' but miss the enumeration vulnerability."

---

### ⚖️ Comparison Table

| Format | Standard | Machine Readable | Extension Fields | Spring Support |
|---|---|---|---|---|
| RFC 9457 Problem Details | RFC standard | Yes (type URI) | Yes (custom fields) | Built-in (Spring 6+) |
| Custom JSON error | None | Varies | Yes (custom) | Manual |
| HTTP status only | HTTP spec | No | No | Partial |
| JSend | Community | Partial | Yes | Manual |

**The deciding factor:** Use RFC 9457 Problem Details for any new REST API. It is the standard and has Spring Boot 3+ built-in support via `ProblemDetail` class.
