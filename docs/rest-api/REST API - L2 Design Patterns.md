---
layout: default
title: "REST API - L2 Design Patterns"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 3
permalink: /rest-api/l2-design-patterns/
---

# API Versioning Strategies

🎯 Interview Weight: high - Every senior API interview includes
versioning. The candidate must know all three strategies, their
trade-offs, and when to apply each.

---

### 🎯 Model Answer

**30 seconds:**
> API versioning allows evolving an API without breaking existing
> clients. The three main strategies are: URL versioning (`/api/v2/`),
> header versioning (`API-Version: 2`), and content-type versioning
> (`Accept: application/vnd.example.v2+json`). URL versioning is
> the most practical for most APIs.

**3 minutes (Senior):**
> API versioning exists because breaking changes break clients, and
> clients cannot all update at the same time. The goal is to introduce
> changes without forcing all clients to update simultaneously.
>
> URL versioning (`/api/v1/orders`, `/api/v2/orders`): the version
> is in the path. Highly visible, easy to route at the gateway level,
> easy to test with a browser or curl. CDNs and load balancers route
> by URL naturally. The downside: different versions appear as
> different resources (pedantically wrong: the same resource is at
> different URLs). Used by Twitter, GitHub, Stripe.
>
> Header versioning (`API-Version: 2` or `X-API-Version: 2`): single
> URL for all versions, version in a custom header. Cleaner URLs.
> Harder to test (must set headers on every request), harder to
> route at gateway level, does not appear in browser address bar.
> Used by some enterprise APIs.
>
> Content-type versioning (`Accept: application/vnd.company.v2+json`):
> most RESTful (uses HTTP content negotiation), version is part of
> the media type. Very rarely used in practice - too complex.
>
> Versioning scope: versioning applies to the entire API (`/v2/`),
> a resource group (`/orders/v2/`), or individual endpoints
> (least clean). Versioning granularity is a governance decision.
>
> Deprecation strategy: announce deprecation date, add
> `Deprecation: Sat, 01 Jan 2025 00:00:00 GMT` and `Sunset:
> Sat, 01 Jan 2025 00:00:00 GMT` headers to deprecated responses
> (RFC 8594). Monitor traffic to old versions. Sunset old versions
> after a grace period (6-12 months for public APIs).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking how to release a new API version
without breaking existing clients."

**(2) First principles:** "Clients cannot all update at once.
Versioning creates a contract: old clients use v1, new clients use v2.
Both can coexist."

**(3) Bridge:** "Like software release channels: stable, beta, v2.
Users opt into the channel when ready. You keep the old channel
alive until enough users have migrated."

---

### 📘 Concept Explanation

**What counts as a breaking change:**

```
BREAKING (require a new version):
  - Removing a field from a response
  - Renaming a field (same as remove + add)
  - Changing a field type (string -> number)
  - Changing a response status code meaning
  - Removing an endpoint
  - Changing required/optional on request fields

NON-BREAKING (backward compatible):
  - Adding a new optional field to a response
  - Adding a new optional request field
  - Adding a new endpoint
  - Making a required request field optional
```

---

### 💻 Code Example

**BAD - Breaking change without versioning:**

```java
// BAD: Changed response structure without versioning
// Old field: "customer_name"
// New field: "customer_full_name"
// All clients using "customer_name" break

@GetMapping("/api/orders/{id}")
public OrderResponse getOrder(@PathVariable String id) {
    // Changed field name - BREAKING
    return new OrderResponse(
        order.getId(),
        order.getCustomerFullName() // renamed field
    );
}
```

**GOOD - URL versioning with Spring Boot:**

```java
// GOOD: Separate controllers per major version
// Routes: /api/v1/orders and /api/v2/orders

@RestController
@RequestMapping("/api/v1/orders")
public class OrderControllerV1 {

    @GetMapping("/{id}")
    public OrderResponseV1 getOrder(
        @PathVariable String id
    ) {
        // V1 response: field is "customer_name"
        Order order = orderService.findById(id);
        return OrderResponseV1.from(order);
    }
}

@RestController
@RequestMapping("/api/v2/orders")
public class OrderControllerV2 {

    @GetMapping("/{id}")
    public OrderResponseV2 getOrder(
        @PathVariable String id
    ) {
        // V2 response: field is "customer" object
        Order order = orderService.findById(id);
        return OrderResponseV2.from(order);
    }
}

// V1 response: flat customer fields
public record OrderResponseV1(
    String id,
    String customerId,
    String customerName,    // flat field
    String status
) {
    static OrderResponseV1 from(Order order) {
        return new OrderResponseV1(
            order.getId(),
            order.getCustomer().getId(),
            order.getCustomer().getFullName(),
            order.getStatus().name()
        );
    }
}

// V2 response: nested customer object
public record OrderResponseV2(
    String id,
    CustomerSummary customer,    // nested object
    String status
) {
    static OrderResponseV2 from(Order order) {
        return new OrderResponseV2(
            order.getId(),
            CustomerSummary.from(order.getCustomer()),
            order.getStatus().name()
        );
    }
}
```

> **Code walkthrough:** The BAD example renames a field without
> versioning - all V1 clients that read `customer_name` now get
> null (field missing). The GOOD example uses separate controller
> classes for `/api/v1/` and `/api/v2/`. Both share the same service
> layer (`orderService`) and domain model (`Order`). Only the response
> mapping changes between versions. V1 returns a flat `customerName`
> string; V2 returns a nested `CustomerSummary` object. Old clients
> continue using V1 with no changes. New clients use V2 with the
> richer response format.

---

### ⚖️ Comparison Table

| Strategy | URL Pattern | Pros | Cons | Used By |
|----------|-------------|------|------|---------|
| URL versioning | `/api/v2/orders` | Visible, easy to route, CDN-friendly | "Impure" REST | Stripe, GitHub, Twitter |
| Header versioning | `API-Version: 2` | Clean URLs | Hard to test, harder to route | Azure REST APIs |
| Content-type | `Accept: .../v2+json` | Most RESTful | Complex, rare | Academic preference |
| Query param | `?version=2` | Simple | Pollutes query space | Least recommended |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> URL versioning (`/api/v2/`) is the standard approach. Include
> the version in the base URL. Make a new version when a breaking
> change is needed. Keep old versions running during a deprecation
> period.

---

**Senior / Staff (5+ years):**
> I always add `Deprecation` and `Sunset` headers (RFC 8594) to
> deprecated version responses. This allows automated tooling (like
> API gateways and client SDK generators) to surface warnings. I
> also track traffic by version in Grafana. When V1 traffic drops
> below 1% for 30 days, I schedule the sunset. Never sunset a version
> based on time alone - base it on measured traffic.

---

### ⚠️ Common Misconceptions

**"Adding a field is always safe":** Adding a field to a response
is usually safe (clients ignore unknown fields). Adding a REQUIRED
field to a request is a breaking change. Also: if a client uses
strict JSON deserialization (failing on unknown properties), then
adding a field to the response also breaks it. Always configure
clients to ignore unknown fields.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Version explosion** - Versions accumulate (v1, v2, v3, v4...)
with no sunset dates. Teams maintain 4+ live versions simultaneously.
Diagnosis: `GET /api/v*/orders` traffic by version via access logs.
Fix: enforce 2-version limit (current + 1 deprecated), mandatory sunset dates.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 3 min | Three strategies + URL versioning |
| Mid | 5 min | Breaking vs non-breaking changes |
| Senior | 7 min | Deprecation strategy + version governance |

---

**[TRADE-OFF] Your API has 100 consumers, some internal and some
external. Do you use the same versioning strategy for both?**
`[SENIOR]`

*Why they ask:* Tests understanding of versioning in different
API governance contexts.

*Likely follow-up:* "How do you enforce sunset dates?"

Internal consumers: you have visibility into who they are, can
contact them, and can force upgrades via organizational policy.
Header versioning is viable internally (easier to add to
service-to-service calls via HTTP client interceptors). Sunset
dates can be enforced with hard cutoffs. External consumers:
no direct control over client update schedules. URL versioning
is essential (visible, easy to test, easy to document). 12-month
sunset notice minimum for public APIs. Enforcement: return 410
(Gone) for sunsetted versions, not 404 (distinguishes "does not
exist" from "was removed"). Never return 200 for a sunsetted
version - it silently corrupts clients. Strategy: publish the
sunset date in the API developer portal, send email notifications
to registered client developers, use the `Sunset` header in
all responses from the version being sunset (so the client can
detect it programmatically).

*What separates good from great:* The `Sunset` header (RFC 8594)
usage and the 410 Gone (not 404) status for sunsetted versions.

---

---

# Pagination, Filtering, and Sorting

🎯 Interview Weight: high - Every API with collections needs
pagination. The choice of strategy (offset vs cursor) is a
classic interview decision question.

---

### 🎯 Model Answer

**30 seconds:**
> Pagination limits the amount of data returned per request.
> Offset pagination (`page=0&size=20`) is simple but inconsistent
> on live data. Cursor-based pagination (`cursor=<opaque_token>`)
> is stable on live data and scales better. Filtering uses query
> parameters. Sorting uses `sort=field,direction` parameters.

**3 minutes (Senior):**
> Offset pagination: client specifies offset and limit (`?page=2&size=10`
> means skip 20, take 10). Simple to implement and understand.
> Problems: (1) If a row is inserted before the current page, the
> offset shifts - items are duplicated or skipped. (2) Count queries
> are slow on large tables. (3) Does not scale to very large offsets
> (a database must scan `offset` rows before returning `size` results).
> `OFFSET 10000000 LIMIT 20` is slow.
>
> Cursor pagination: client passes an opaque cursor (base64-encoded
> last-item ID, or a compound key). The server queries:
> `WHERE id > :cursor ORDER BY id ASC LIMIT 20`. Returns the next
> cursor in the response. No count queries, no offset scan, consistent
> on live data. Problem: cannot jump to page N; can only go to
> next/previous page. Not suitable for user-facing pagination UI
> with page numbers.
>
> When to use which: user-facing pagination with page numbers and
> total count = offset pagination. Infinite scroll (like Facebook
> feed, Twitter timeline), API clients consuming all records,
> analytics export = cursor pagination.
>
> Filtering: query parameters for simple filters
> (`?status=PENDING&createdAfter=2024-01-01`). For complex filters,
> a POST /search endpoint with a filter body.
>
> Sorting: `?sort=createdAt,desc` or `?sort=name,asc&sort=createdAt,desc`
> for multi-field sorting.

**Blank Mind Recovery:**

**(1) Restate:** "How should large collections be paginated, and
how does filtering and sorting work?"

**(2) First principles:** "Never return unlimited data. Pagination
divides large collections into manageable pages. Cursor is more
stable but less flexible."

---

### 💻 Code Example

**GOOD - Cursor pagination with Spring Data:**

```java
// Cursor-based pagination for stable iteration

@GetMapping("/api/v1/orders")
public CursorPage<OrderSummary> listOrders(
    @RequestParam(required = false) String cursor,
    @RequestParam(defaultValue = "20") int size,
    @RequestParam(required = false) String status
) {
    // Decode the cursor (last seen order ID + createdAt)
    OrderCursor decodedCursor =
        cursor != null
        ? OrderCursor.decode(cursor)
        : null;

    List<OrderSummary> orders = orderRepository
        .findNextPage(decodedCursor, status, size + 1);

    // Fetch size+1 to detect if there is a next page
    boolean hasMore = orders.size() > size;
    if (hasMore) {
        orders = orders.subList(0, size);
    }

    // Encode the cursor from the last item
    String nextCursor = hasMore
        ? OrderCursor.encode(orders.get(orders.size() - 1))
        : null;

    return new CursorPage<>(orders, nextCursor, hasMore);
}

// JPA query for cursor pagination
public interface OrderRepository extends JpaRepository<Order, String> {

    // If no cursor: get first page
    // If cursor: get after the cursor position
    @Query("""
        SELECT o FROM Order o
        WHERE (:status IS NULL OR o.status = :status)
          AND (:cursor IS NULL
               OR (o.createdAt < :cursorCreatedAt)
               OR (o.createdAt = :cursorCreatedAt
                   AND o.id > :cursorId))
        ORDER BY o.createdAt DESC, o.id ASC
        LIMIT :size
        """)
    List<Order> findNextPage(
        String status,
        Instant cursorCreatedAt,
        String cursorId,
        int size
    );
}

// Response shape
public record CursorPage<T>(
    List<T> data,
    String nextCursor,  // null if last page
    boolean hasMore
) {}
```

> **Code walkthrough:** Cursor pagination requests `size+1` items.
> If the result has more than `size` items, there is a next page
> (`hasMore=true`), and we trim the extra item. The cursor is
> the encoded position of the last item (its `createdAt` and `id`).
> The next query uses `WHERE (createdAt < :cursorCreatedAt) OR
> (createdAt = :cursorCreatedAt AND id > :cursorId)` for stable
> ordering even when two records have the same timestamp.
> The cursor is opaque (base64-encoded) - clients treat it as a
> token, not parse it. This prevents clients from constructing
> cursors manually (which would couple them to the implementation).

---

### ⚖️ Comparison Table

| | Offset Pagination | Cursor Pagination |
|--|------------------|------------------|
| Consistency on live data | No (inserts/deletes shift pages) | Yes (stable) |
| Random access (jump to page N) | Yes | No |
| Performance at large offsets | Poor (`OFFSET 1M LIMIT 20`) | Excellent (index seek) |
| Total count | Yes (with COUNT query) | No (expensive) |
| Best for | UI with page numbers | Infinite scroll, export |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Offset pagination (`page=0&size=20`) is simple. Cursor pagination
> is more scalable and consistent. Use query parameters for filtering
> (`?status=ACTIVE`) and sorting (`?sort=createdAt,desc`).

---

**Senior / Staff (5+ years):**
> In a high-throughput order system I replaced offset pagination
> with cursor-based pagination for the export use case. The old
> approach: `OFFSET 100000 LIMIT 100` was taking 4 seconds per page
> because MySQL scanned 100,000 rows to skip. The cursor approach
> using `WHERE id > :lastId` used an index seek and ran in 2ms.
> The export went from 2 hours to 4 minutes.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | Offset pagination + query params |
| Mid | 4 min | Offset vs cursor trade-offs |
| Senior | 6 min | Cursor implementation + large dataset design |

---

---

# HATEOAS and Hypermedia APIs

🎯 Interview Weight: medium - HATEOAS is the highest REST maturity
level. Most interviewers ask "what is it" and "why is it not
commonly used."

---

### 🎯 Model Answer

**30 seconds:**
> HATEOAS (Hypermedia as the Engine of Application State) is a REST
> constraint where responses include links to valid next actions.
> A GET /orders/123 response includes links like `cancel: /orders/123/cancellations`
> and `payment: /orders/123/payments`. The client discovers
> capabilities from the response rather than hard-coding URLs.

**3 minutes (Senior):**
> HATEOAS is the final constraint in Richardson Maturity Model Level 3.
> The idea: responses are self-describing. A client starts at one
> URL and navigates the entire API by following links in responses.
> The client never constructs URLs from templates.
>
> Benefits: server can change URL structure without breaking clients
> (clients follow links, not hard-coded URLs). The API documents
> valid actions in context (only shows `cancel` link if the order
> is in a cancellable state). Client complexity decreases (no need
> to know business rules about what operations are valid in what states).
>
> Why HATEOAS is rarely implemented in practice:
> (1) Client complexity actually increases: the client must parse
> `_links` and follow them dynamically, which is harder than calling
> a known URL. (2) Human-readable link names (`rel` values) must be
> agreed on and documented anyway. (3) Response size increases.
> (4) Strong coupling between server state logic and response format.
> (5) Most API consumers are not generic hypermedia clients - they
> are purpose-built for a specific API and know the URL structure.
>
> Spring HATEOAS: the library for building hypermedia responses
> in Spring. Produces JSON with `_links` section (HAL format).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the HATEOAS constraint
and whether it is practical."

**(2) First principles:** "HATEOAS makes the API discoverable.
Like a website - you do not know all URLs upfront, you follow
links. REST APIs can work the same way."

---

### 💻 Code Example

**HATEOAS response with Spring HATEOAS:**

```java
// Response with hypermedia links
// Shows only valid actions for the current order state

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    @GetMapping("/{orderId}")
    public EntityModel<OrderResponse> getOrder(
        @PathVariable String orderId
    ) {
        Order order = orderService.findById(orderId);
        OrderResponse body = OrderResponse.from(order);

        EntityModel<OrderResponse> model =
            EntityModel.of(body);

        // Always include self link
        model.add(linkTo(methodOn(OrderController.class)
            .getOrder(orderId)).withSelfRel());

        // Add cancel link only if cancellable
        if (order.canCancel()) {
            model.add(Link.of(
                "/api/v1/orders/" + orderId +
                    "/cancellations",
                "cancel"
            ));
        }

        // Add payment link only if payment needed
        if (order.requiresPayment()) {
            model.add(Link.of(
                "/api/v1/orders/" + orderId +
                    "/payments",
                "pay"
            ));
        }

        return model;
    }
}

// HAL JSON response:
// {
//   "id": "123",
//   "status": "PENDING",
//   "_links": {
//     "self": { "href": "/api/v1/orders/123" },
//     "cancel": { "href": "/api/v1/orders/123/cancellations"},
//     "pay": { "href": "/api/v1/orders/123/payments" }
//   }
// }
```

> **Code walkthrough:** Spring HATEOAS `EntityModel` wraps the
> response body and adds a `_links` section. The `cancel` link is
> only added when `order.canCancel()` is true - so the client does
> not need to know the business rules for when cancellation is
> allowed. A cancelled order's response would not include the `cancel`
> link. The `pay` link is only present for orders awaiting payment.
> This is state-driven hypermedia: the response encodes the allowed
> state transitions as links.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> HATEOAS adds `_links` to responses so clients can discover next
> actions from the response. It is the highest level of REST maturity.
> In practice, most APIs do not implement it because clients are
> purpose-built and do not need dynamic link discovery.

---

**Senior / Staff (5+ years):**
> HATEOAS has one practical use case where it genuinely simplifies
> clients: state machine APIs where the valid operations depend on
> the current state. Instead of the client hard-coding `if order.status == 'PENDING' then show_cancel_button`, the server encodes this logic
> in the `_links`. The client just checks: does the response have
> a `cancel` link? This removes the state machine logic from the
> client and keeps it in the server where it belongs.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What HATEOAS is + Richardson Level 3 |
| Mid | 3 min | Why rarely used in practice |
| Senior | 5 min | When HATEOAS adds value + state machine APIs |

---

---

# Idempotency in REST APIs

🎯 Interview Weight: very high - Idempotency is a payment systems
must-know. Appears in every senior distributed systems interview.

---

### 🎯 Model Answer

**30 seconds:**
> Idempotency means calling an operation multiple times produces the
> same result as calling it once. GET, PUT, and DELETE are idempotent
> by definition. POST and PATCH are not. To make POST idempotent,
> use an Idempotency-Key header: the client generates a unique key
> per request; the server stores the response and returns the same
> response for subsequent requests with the same key.

**3 minutes (Senior):**
> Why idempotency matters: HTTP requests can fail in transit. A
> connection drops after the server processes the request but before
> the client receives the response. The client retries. Without
> idempotency: the order is created twice, the payment is charged
> twice. With idempotency: the server recognizes the retry and returns
> the original response.
>
> Idempotency-Key pattern: the client generates a UUID before the
> first attempt and sends it as `Idempotency-Key: <uuid>` on every
> retry. The server: (1) Checks if it has seen this key before.
> (2) If yes: return the stored response (do not re-execute). (3) If
> no: execute the operation, store the response keyed by the idempotency
> key, return the response.
>
> Storage: idempotency keys are stored in Redis or database with a TTL
> (24 hours is typical). The key stores the request hash (to detect
> if the client changed the payload on retry) and the response body
> and status code.
>
> Stripe's implementation: Stripe requires an idempotency key on all
> payment charge requests. The key is stored for 24 hours. Retrying
> with the same key returns the original charge, not a new one.
> Changing the request body with the same key returns 409 Conflict.
>
> Race condition: two concurrent requests with the same key. Use
> an atomic "set if not exists" (Redis `SET NX`) or a database
> unique constraint on the key.

**Blank Mind Recovery:**

**(1) Restate:** "How to make non-idempotent operations safe to retry."

**(2) First principles:** "Network calls can fail after processing.
Retries create duplicates. An idempotency key lets the server say
'I already did this' and return the original result."

**(3) Bridge:** "Like a bank deduplication number: if the same
transfer reference appears twice, the bank ignores the second.
The transfer happens exactly once."

---

### 💻 Code Example

**GOOD - Idempotency key implementation:**

```java
// Idempotency key middleware / filter

@Service
public class IdempotencyService {

    private final RedisTemplate<String, IdempotencyRecord>
        redis;
    private static final Duration TTL = Duration.ofHours(24);

    public Optional<IdempotencyRecord> findExisting(
        String key
    ) {
        return Optional.ofNullable(
            redis.opsForValue().get("idempotency:" + key)
        );
    }

    // Atomic: only stores if key does not exist
    public boolean tryLock(String key) {
        return Boolean.TRUE.equals(
            redis.opsForValue().setIfAbsent(
                "idempotency:lock:" + key,
                "LOCKED",
                Duration.ofSeconds(30) // processing timeout
            )
        );
    }

    public void store(
        String key,
        int statusCode,
        String responseBody,
        String requestHash
    ) {
        redis.opsForValue().set(
            "idempotency:" + key,
            new IdempotencyRecord(
                statusCode, responseBody, requestHash
            ),
            TTL
        );
    }
}

// Usage in order creation
@PostMapping("/api/v1/orders")
public ResponseEntity<String> createOrder(
    @RequestHeader("Idempotency-Key") String idempotencyKey,
    @RequestBody @Valid CreateOrderRequest request
) {
    String requestHash = hash(request);

    // Check for existing response
    Optional<IdempotencyRecord> existing =
        idempotencyService.findExisting(idempotencyKey);

    if (existing.isPresent()) {
        IdempotencyRecord record = existing.get();
        // Request body must match original
        if (!record.requestHash().equals(requestHash)) {
            return ResponseEntity.status(409)
                .body("Idempotency key reused " +
                    "with different request body");
        }
        // Return the original response
        return ResponseEntity
            .status(record.statusCode())
            .body(record.responseBody());
    }

    // Acquire processing lock (prevent duplicate execution)
    if (!idempotencyService.tryLock(idempotencyKey)) {
        return ResponseEntity.status(409)
            .body("Concurrent request with same key");
    }

    // Execute the operation
    Order order = orderService.createOrder(request);
    String responseBody = toJson(order);

    // Store the result
    idempotencyService.store(
        idempotencyKey, 201, responseBody, requestHash
    );

    return ResponseEntity.status(201).body(responseBody);
}
```

> **Code walkthrough:** The idempotency service uses Redis with a
> 24-hour TTL. The `tryLock` call uses Redis `SET NX` (set if not
> exists) to prevent two concurrent requests with the same key from
> both executing the order creation - only one succeeds, the other
> gets 409. If the key is found, the request hash is compared: if the
> client retried with a different body (a programming error), 409 is
> returned. If the hash matches, the stored response is returned
> verbatim (same status code and body as the original). This pattern
> is what Stripe uses for payment charges.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Idempotency means repeating an operation gives the same result.
> GET, PUT, DELETE are idempotent. POST is not. To make POST safe to
> retry, the client sends an `Idempotency-Key` header. The server
> checks if it has processed that key before and returns the stored
> result instead of re-executing.

---

**Senior / Staff (5+ years):**
> In payment systems, idempotency is non-negotiable. The charge
> must happen exactly once even if the network drops between the
> server completing the charge and the client receiving the
> confirmation. The key insight: the idempotency check must be
> inside the transaction boundary, or between the lock and the
> business logic execution, to prevent the double-execution window
> during concurrent retries.

---

### ⚠️ Common Misconceptions

**"PUT is always idempotent":** PUT replaces the entire resource,
which is idempotent for the same body. But `PUT /counter/1` with
`{"value": current_value + 1}` is not idempotent - the `current_value`
changes each time. The issue is read-modify-write in the request logic.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Idempotency store race condition** - Two retries
in a race both find the key missing and both execute the operation.
Diagnosis: duplicate orders/charges with the same idempotency key.
Fix: use Redis `SET NX` as an atomic distributed lock before
executing (as shown in the code example). The second concurrent
request gets the lock, finds the result, and returns it.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What idempotency is + HTTP method properties |
| Mid | 4 min | Idempotency-Key pattern + use cases |
| Senior | 7 min | Full implementation + race conditions + payment systems |

---

**[TRADE-OFF] How do you handle the case where the first request
succeeded but the response was lost in transit, and the client
retries with the same idempotency key?** `[SENIOR]`

*Why they ask:* This is the exact scenario idempotency solves.
Tests understanding of the full flow.

*Likely follow-up:* "What if the operation failed the first time -
should the retry re-execute or return the failure?"

Scenario: client sends POST /payments with key K123. Server
processes the charge successfully, stores the response in Redis
keyed by K123, but the TCP connection drops before the response
reaches the client. Client retries with the same key K123.
Server checks Redis: finds the stored successful response,
returns it immediately without re-executing. The client receives
the 201 Created response as if the first request succeeded.
The charge happened exactly once. For the second question: if
the first attempt failed (e.g., 400 Validation Error), the stored
response is the error response. Subsequent retries get the same
400. The client must fix the request and generate a NEW idempotency
key (the key is bound to the original request). Storing failure
responses is a deliberate design choice: it prevents retrying a
clearly invalid request indefinitely. Exceptions: for infrastructure
failures (503, 502), some implementations do NOT store the error
response, allowing the client to retry and potentially succeed
once the infrastructure recovers.

*What separates good from great:* The distinction between storing
4xx (client error) vs 5xx (server error) responses - 4xx should
be stored (client bug, retrying is pointless), 5xx may not be
stored (transient failure, client should retry).

---

---

# Bulk Operations and Batch APIs

🎯 Interview Weight: medium - Appears in performance-focused
interviews. Tests awareness of the N+1 HTTP call problem.

---

### 🎯 Model Answer

**30 seconds:**
> Bulk operations allow creating, updating, or deleting multiple
> resources in one HTTP request. This reduces N round trips to 1.
> Options: `POST /resource/batch` (non-standard but practical),
> JSON Patch for batch updates, or GraphQL mutations for complex
> multi-resource operations.

**3 minutes (Senior):**
> N+1 HTTP call problem: a client needs to create 100 orders.
> Calling `POST /orders` 100 times: 100 HTTP round trips, 100 database
> transactions. At 50ms round trip latency: 5 seconds minimum.
> With bulk operations: 1 HTTP request, 1 or N database operations.
>
> REST does not define a bulk standard. Common pragmatic approaches:
>
> 1. `POST /orders/batch` with array body: creates multiple orders
> in one request. Non-standard but universally understood.
>
> 2. `PATCH /orders` with an array of partial updates (each with an
> `id`): batch update. Some use JSON Patch (RFC 6902) for structured
> patch operations.
>
> 3. `DELETE /orders?ids=1,2,3` (with comma-separated IDs in query
> parameter): batch delete. Simple.
>
> Response design for partial failures: some items may succeed and
> some may fail. Return 207 Multi-Status with a per-item result.
> Do NOT return 200 with errors in the body (breaks monitoring).
>
> Atomicity choice: all-or-nothing (transaction) vs best-effort
> (process what you can, report failures). Document the choice
> explicitly. Most payment systems use atomic batch operations.
> Most import systems use best-effort.
>
> Size limits: batch requests must have a size limit (e.g., max
> 100 items per batch). Unlimited batch requests can be used for
> DoS attacks and cause excessive memory usage.

**Blank Mind Recovery:**

**(1) Restate:** "How to handle operations on multiple resources
efficiently."

**(2) First principles:** "HTTP round trips are expensive.
One request carrying 100 items is faster than 100 requests.
The trade-off is complexity in error handling."

---

### 💻 Code Example

**GOOD - Batch create with 207 Multi-Status:**

```java
@PostMapping("/api/v1/orders/batch")
public ResponseEntity<BatchResponse<OrderResponse>>
    createOrderBatch(
        @RequestBody @Valid BatchCreateRequest<CreateOrderReq>
            request
    ) {
    // Enforce size limit (DoS protection)
    if (request.items().size() > 100) {
        return ResponseEntity.status(400)
            .body(BatchResponse.error(
                "Max batch size is 100 items"
            ));
    }

    List<BatchItem<OrderResponse>> results = new ArrayList<>();
    boolean hasErrors = false;
    boolean hasSuccess = false;

    for (CreateOrderReq orderReq : request.items()) {
        try {
            Order order = orderService.create(orderReq);
            results.add(BatchItem.success(
                orderReq.clientId(),
                OrderResponse.from(order),
                201
            ));
            hasSuccess = true;
        } catch (ValidationException e) {
            results.add(BatchItem.failure(
                orderReq.clientId(),
                e.getMessage(),
                422
            ));
            hasErrors = true;
        }
    }

    // 207 Multi-Status when mixed results
    // 201 when all succeeded
    // 400 when all failed
    int status = (hasSuccess && hasErrors) ? 207
        : (hasErrors ? 400 : 201);

    return ResponseEntity.status(status)
        .body(new BatchResponse<>(results));
}

// Response structure
public record BatchResponse<T>(
    List<BatchItem<T>> results
) {
    // Convenience constructor for error
    static <T> BatchResponse<T> error(String message) {
        return new BatchResponse<>(List.of(
            BatchItem.failure(null, message, 400)
        ));
    }
}

public record BatchItem<T>(
    String clientId,  // client-provided correlation ID
    T data,           // null on failure
    String error,     // null on success
    int status        // per-item HTTP status code
) { }
```

> **Code walkthrough:** The batch endpoint enforces a 100-item size
> limit to prevent DoS attacks via huge payloads. Each item is
> processed independently (best-effort) and returns either a success
> or failure entry. The `clientId` is a client-provided correlation ID
> so the client can match each result to its original request item.
> The top-level status code is 207 when there is a mix of successes
> and failures, 201 when all succeeded, 400 when all failed.
> Using 207 Multi-Status (rather than 200 with errors in the body)
> ensures HTTP monitoring tools correctly identify partial failures.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Batch APIs let clients send multiple items in one request.
> Use `POST /resource/batch` with an array body. Return 207
> Multi-Status with per-item results for partial failures.
> Always enforce a size limit.

---

**Senior / Staff (5+ years):**
> At scale, bulk APIs need more than just batching: async processing
> with status polling. `POST /orders/batch` returns 202 Accepted
> with a job ID. `GET /orders/batch/{jobId}` returns status (PENDING,
> PROCESSING, COMPLETE). `GET /orders/batch/{jobId}/results` returns
> the results when complete. This is essential when processing
> 10,000-item batches that take longer than the HTTP timeout.

---

### ⚠️ Common Misconceptions

**"Batch APIs are atomic":** Only if you implement them that way.
Most bulk APIs are best-effort (process each item independently).
The API contract must explicitly state whether the batch is atomic
or best-effort.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Batch request DoS** - A client sends a batch with 100,000
items, exhausting server memory. Diagnosis: 503 errors on batch
endpoints, high memory usage correlated with batch requests.
Fix: enforce a hard size limit (100-1000 items), validate at
the request binding layer before processing starts.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What batch APIs are + why needed |
| Mid | 3 min | 207 Multi-Status + error handling |
| Senior | 5 min | Async batch + atomicity decisions + size limits |

---

**[DEBUGGING] A batch import of 10,000 products is taking 45
minutes through the existing POST /products endpoint (one at a
time). Design a solution.** `[MID]`

*Why they ask:* Tests ability to identify the N+1 HTTP call
problem and design a practical solution.

*Likely follow-up:* "How do you handle failures in a large batch?"

Problem: 10,000 POST /products requests at 270ms average = 45
minutes. Each request has HTTP overhead (TCP + TLS if not keep-alive,
request parsing, authorization check, database transaction
overhead). Solution 1 (simple): POST /products/batch with chunks
of 100. 100 requests at 1-2s each = 2-3 minutes. Solution 2
(recommended for 10,000+): async batch job. POST /products/import
with the full CSV file or JSON array, returns 202 Accepted with
jobId. The server processes items in batches of 500 using database
bulk insert (100x faster than individual inserts). Returns job
status via GET /products/import/{jobId}. Database bulk insert
design: use `INSERT INTO products (...) VALUES (...), (...), (...)`
or Spring Data's `saveAll()` with a JDBC batch insert configured
via `spring.jpa.properties.hibernate.jdbc.batch_size=50`. This
reduces database round trips from 10,000 to 200.

*What separates good from great:* The database bulk insert
optimization (JDBC batch insert) in addition to the HTTP
batch endpoint.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Implementation + 207 Multi-Status |
| Bar Raiser | Async batch + scale design |
