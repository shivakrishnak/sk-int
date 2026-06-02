---
layout: default
title: "REST API - L1 Core Concepts"
parent: "REST API"
grand_parent: "SK Interview"
nav_order: 2
permalink: /rest-api/l1-core-concepts/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [HTTP Methods in REST APIs](#http-methods-in-rest-apis) | medium |
| 2 | [HTTP Status Codes](#http-status-codes) | medium |
| 3 | [REST Resource Naming and URL Design](#rest-resource-naming-and-url-design) | medium |

---

# HTTP Methods in REST APIs

---

### 🎯 Model Answer

**30 seconds:**
> REST APIs use HTTP methods to express intent: GET reads, POST creates, PUT replaces, PATCH updates partially, DELETE removes. The two critical properties are safety (does the operation have side effects?) and idempotency (is calling it N times the same as calling it once?). GET is safe and idempotent. PUT and DELETE are idempotent but not safe. POST is neither - it's the method for non-idempotent creation and actions.

**3 minutes:**
> HTTP methods are the verbs of REST - the URL identifies the resource (noun), the method expresses what to do with it. The safety/idempotency properties determine how clients and infrastructure treat the method. Safe methods (GET, HEAD, OPTIONS) can be retried freely without concern for side effects - caches, crawlers, and prefetchers can call them at will. Idempotent methods (GET, HEAD, PUT, DELETE, OPTIONS) produce the same result when called multiple times - clients can retry on network failure. POST is neither safe nor idempotent: creating the same order twice creates two orders. This is why payment processing is hard: you cannot simply retry a POST on network timeout without risking a duplicate charge. The solution: idempotency keys (the client sends a unique key; the server deduplicates on the key). Method semantics also determine caching: only GET and HEAD responses are cached by default in HTTP caches. PUT and DELETE should return the updated/deleted resource or 204 No Content. PATCH is like PUT but for partial updates - send only the fields that change. The difference between PUT and PATCH matters for concurrency: PUT requires the client to send all fields (risk of clobbering concurrent updates), PATCH only updates specified fields (safer for concurrent clients).

**Blank Mind Recovery:**
**(1) Restate:** "HTTP methods - GET, POST, PUT, PATCH, DELETE."
**(2) First principles:** "What verbs do we need to do anything with data? Read, Create, Replace, Update, Delete. HTTP methods are these verbs."
**(3) Bridge:** "It's like database operations: GET=SELECT, POST=INSERT, PUT=UPDATE (full replace), PATCH=UPDATE (partial), DELETE=DELETE."

---

### 📘 Concept Explanation

**What it is:**
HTTP methods (also called HTTP verbs) define the operation to be performed on the resource identified by the URL. REST uses them as a standardized vocabulary for API interactions.

**The problem it solves:**
Without standardized verbs, every API would invent its own operation naming: `/getUser`, `/createOrder`, `/doDelete`. REST uses HTTP's existing method vocabulary to standardize intent, enabling caches, clients, and documentation tools to make assumptions about behavior.

**How it works:**
```
HTTP Method Properties:

Method  Safe  Idempotent  Typical Response
------  ----  ----------  ----------------
GET     Yes   Yes         200 OK + body
HEAD    Yes   Yes         200 OK (no body)
OPTIONS Yes   Yes         200 OK (CORS headers)
POST    No    No          201 Created + body
PUT     No    Yes         200 OK or 204
PATCH   No    No          200 OK or 204
DELETE  No    Yes         200 OK or 204

Safe = no side effects (read-only)
Idempotent = N identical calls = 1 call result
```

> **Code walkthrough:** This HTTP Methods in REST APIs example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Idempotency is the property that enables safe retries. In distributed systems, network timeouts are common - you send a request but don't receive the response (was it processed?). If the operation is idempotent (PUT, DELETE), you can safely retry: calling it again produces the same result. If it's not idempotent (POST), retrying risks duplicates. This is why the payment industry invented idempotency keys: turn a POST (non-idempotent) into an effectively idempotent operation by deduplicating on the key.

**When to use it:**
- GET: any read operation with no side effects
- POST: creating a resource (ID assigned by server), or any operation that doesn't fit GET/PUT/DELETE
- PUT: full resource replacement when the client knows the complete new state
- PATCH: partial update - only the changed fields
- DELETE: removing a resource

**When NOT to use it:**
- Don't use GET for operations that modify data (even if convenient) - caches and bots will call them
- Don't use POST for idempotent operations if PUT fits better
- Don't use PUT when you only want to change one field - use PATCH

**Alternatives:**
- gRPC has no method concept - operations are defined in Protobuf service definitions (similar to RPC)
- GraphQL uses POST for everything - mutations for writes, queries for reads (loses HTTP method semantics)
- SOAP uses POST for everything via action headers

**First-principles derivation:**
The web needs multiple kinds of operations on the same resource: read it, create it, replace it, delete it. HTTP method names are semantic labels for these operations. Making the labels standard (GET always reads) allows infrastructure (caches, proxies, firewalls) to make decisions about requests without parsing the body. A cache can decide to cache a GET response without knowing anything about the resource type. This separation of concerns (URL=what, Method=how) is REST's uniform interface.

---

### 💻 Code Example

```java
// Spring Boot REST controller - correct method usage
@RestController
@RequestMapping("/products")
public class ProductController {

  // GET - safe and idempotent - returns product
  @GetMapping("/{id}")
  public ResponseEntity<Product> getProduct(
      @PathVariable Long id) {
    return productService.findById(id)
        .map(ResponseEntity::ok)
        .orElse(ResponseEntity.notFound().build());
  }

  // POST - creates product, server assigns ID
  // Not idempotent: calling twice creates two products
  @PostMapping
  public ResponseEntity<Product> createProduct(
      @RequestBody CreateProductRequest req) {
    Product created = productService.create(req);
    URI uri = URI.create("/products/" + created.getId());
    return ResponseEntity.created(uri).body(created);
    // 201 Created with Location header
  }

  // PUT - full replacement, client sends all fields
  // Idempotent: calling twice has same result
  @PutMapping("/{id}")
  public ResponseEntity<Product> replaceProduct(
      @PathVariable Long id,
      @RequestBody Product product) {
    return ResponseEntity.ok(
        productService.replace(id, product));
  }

  // PATCH - partial update, only changed fields
  // Safer for concurrent clients
  @PatchMapping("/{id}")
  public ResponseEntity<Product> updateProduct(
      @PathVariable Long id,
      @RequestBody Map<String, Object> fields) {
    return ResponseEntity.ok(
        productService.partialUpdate(id, fields));
  }

  // DELETE - idempotent: deleting twice = deleted
  @DeleteMapping("/{id}")
  public ResponseEntity<Void> deleteProduct(
      @PathVariable Long id) {
    productService.delete(id);
    return ResponseEntity.noContent().build(); // 204
  }
}
```

> **Code walkthrough:** Each HTTP method maps to a distinct operation. POST returns 201 Created with a Location header pointing to the newly created resource - this is the correct REST convention (client knows where to find the resource it just created). DELETE returns 204 No Content (nothing to return for a successful deletion). GET returns 404 if not found rather than 200 with an empty body - the status code communicates the semantics, not the body.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "REST uses HTTP methods as verbs: GET to read, POST to create, PUT to replace an entire resource, PATCH to update specific fields, DELETE to remove. The important properties are safety (GET doesn't change anything) and idempotency (PUT and DELETE produce the same result whether called once or ten times). POST is neither - calling it multiple times creates multiple resources. This matters for error handling: if a GET request times out, I can retry safely. If a POST times out, I might have created two records."

**Senior / Staff:** "The safety and idempotency properties have real production implications. Safe methods are call-freely by infrastructure: search crawlers, CDN prefetchers, browser back/forward navigation. If I put a side-effecting operation behind GET, it will be triggered unexpectedly. Idempotency enables automatic retry logic: a well-designed HTTP client can retry PUT and DELETE on network failure without risk. For POST, the solution is server-side idempotency keys: the client includes a unique `Idempotency-Key: uuid` header, the server stores processed keys and returns the cached response on duplicate. Stripe, Braintree, and most payment APIs implement this. The subtlety with PUT vs PATCH: PUT requires the client to send ALL fields or risk clobbering concurrent updates. If client A and client B both GET a resource, client A updates the name via PUT (sending all fields with the new name), client B updates the price via PUT (sending all fields including the old name), client B's PUT arrives second and reverts the name change. PATCH avoids this by only sending changed fields."

---

### ⚠️ Common Misconceptions

**Misconception:** "PUT and PATCH are the same - both update a resource."
Reality: PUT replaces the entire resource. PATCH applies a partial modification. The difference matters in three ways. First, semantics: a PUT request must contain the complete desired state of the resource. If you omit a field, it becomes null/empty. A PATCH contains only the fields to change. Second, concurrency: PUT is prone to last-write-wins conflicts (both clients read, both modify different fields, second PUT clobbers first update). PATCH, when implemented correctly with JSON Patch or JSON Merge Patch formats, only touches the specified fields. Third, idempotency: PUT is idempotent (send the same PUT twice, same result). PATCH may or may not be idempotent depending on the operation (set price to 100 is idempotent, increment price by 10 is not). The practical guidance: use PATCH for partial updates where the client doesn't have or need the full resource state, use PUT for replacing complete resources.

---

### 🚨 Failure Modes and Diagnosis

**Failure: POST creates duplicate records on client retry**

Symptoms: Payment processed twice. Order created twice. User registered twice. Clients retry POST requests on timeout without deduplication, creating multiple identical records.

Root cause: POST is not idempotent. Clients should not blindly retry POST. But network libraries often retry all failed requests by default (Apache HttpClient retries on `IOException` by default).

Diagnosis: Check application logs for duplicate record creation with identical data and timestamps close together. Look for the same IP creating near-identical resources within a timeout window.

Fix: Implement idempotency keys. Client generates UUID before sending: `Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000`. Server checks if this key was processed. If yes: return cached response. If no: process and store result with the key. Use a database unique constraint or a distributed lock (Redis `SET key value NX PX 86400000`) to ensure only one processing per key. Stripe API reference implementation available.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 2 min | 1 |
| Comparison | 2 min | 1 |
| Scenario | 2 min | 1 |
| Debugging | 2 min | 1 |
| Trade-off | 2 min | 1 |
| Design | 2 min | 1 |

**[JUNIOR] Q1 - [CONCEPTUAL] "What is the difference between safe and idempotent HTTP methods?"**
> "Safe means the operation has no side effects - calling it doesn't change server state. GET, HEAD, and OPTIONS are safe. Safe methods can be called freely by infrastructure without concern for unintended state changes. Idempotent means calling the method N times produces the same result as calling it once. GET, PUT, DELETE, HEAD, and OPTIONS are idempotent. POST is neither safe nor idempotent. The distinction matters for retry logic and caching. Infrastructure (CDNs, caches) caches GET because it's safe. Clients retry PUT and DELETE on failure because idempotency guarantees no side effects from retrying. Clients must not retry POST automatically because it might create duplicate records. The corner cases: DELETE is idempotent - deleting a resource that doesn't exist returns 404 (resource gone) both the first and second time. The client achieves the goal (resource is absent) either way. PUT is idempotent - sending the same PUT twice results in the same state. PATCH is tricky - it depends on the operation: setting a field to a specific value is idempotent; incrementing a counter by 1 is not."

*What separates good from great:* "The corner case about PATCH idempotency (setting a value vs. incrementing) shows precise understanding. Many candidates say PATCH is idempotent - it's not always."

---

**[JUNIOR] Q2 - [HANDS-ON] "How do you implement idempotent POST requests?"**
> "Idempotent POST via idempotency keys. Protocol: client generates a UUID before sending the request and includes it as a header. Server checks if this key was already processed. If yes: return the stored response without re-executing. If no: execute and store the result keyed by the idempotency key. Implementation in Java/Spring: store processed idempotency keys in Redis with TTL (24 hours is typical). Key: `idempotency:{uuid}`, value: serialized response body + status code. Use Redis SETNX (set-if-not-exists) with a short lock TTL to handle concurrent duplicate requests - only one processing allowed per key. Client side: generate UUID before the request, retry on timeout/failure with the same UUID. On success: clear the stored key after the response is confirmed received (optional - TTL handles cleanup). Production considerations: key storage must be durable (Redis AOF persistence or database). Key deduplication window must be longer than client retry window (client retries for 5 minutes, store keys for 24 hours). Stripe's API reference implementation: `Idempotency-Key` header with 24-hour window."

*What separates good from great:* "SETNX (or SET NX) for distributed locking when two concurrent duplicates arrive simultaneously is the production detail. Without this, two concurrent requests with the same key can both pass the 'key exists?' check and both execute."

---

**[JUNIOR] Q3 - [CONCEPTUAL] "When should you use PUT vs PATCH?"**
> "Use PUT when the client has the complete resource and wants to replace it entirely. Use PATCH when the client wants to modify specific fields without knowing or sending the complete resource. The practical tiebreaker: who owns the resource shape? If the client constructs the resource from scratch and knows all fields, PUT. If the client receives the resource from the server and modifies some fields, PATCH. Concurrency safety: PATCH is safer for concurrent clients. If two clients both GET the same resource, modify different fields, and send back their changes: PUT (last write wins) may clobber one client's changes. PATCH only touches declared fields. For PUT, use optimistic locking via ETag: client includes `If-Match: abc123` header, server rejects with 412 Precondition Failed if the resource changed since the client read it. For PATCH format: RFC 7396 JSON Merge Patch (`Content-Type: application/merge-patch+json`) is simple - send a JSON object with the fields to change. RFC 6902 JSON Patch is more powerful but more complex - send an array of operations (add, remove, replace, move, copy, test)."

*What separates good from great:* "Knowing the specific RFC numbers (7396 for Merge Patch, 6902 for JSON Patch) and their trade-offs shows depth. The optimistic locking via ETag + If-Match for PUT is a production pattern most candidates miss."

---

**[MID] Q4 - [CONCEPTUAL] "A client is calling your POST endpoint and getting duplicate orders on timeout. How do you fix it without changing the client?"**
> "Without changing the client: the server must detect and deduplicate the retry. Options: (1) Natural deduplication: if two identical orders (same items, same user, same amount) within a 30-second window are a business impossibility, reject the second as a duplicate (return 200 with the first order instead of creating a new one). Risk: false positives if legitimate identical orders can occur. (2) Request fingerprint: hash the request body + user ID + timestamp-window (floor to 5-second bucket). Store seen fingerprints for 30 seconds. Reject if fingerprint seen before. Risk: hash collisions, legitimate retries rejected. (3) Client IP + endpoint throttle: if the same IP calls POST /orders more than 3 times in 10 seconds, treat after the first as a retry. Return the first successful response. Risk: NAT / shared IP false positives. Long-term fix: require the client to send an idempotency key. Soft migration: if no idempotency key is present, the server uses fingerprinting as a fallback. When clients start sending the key, the server uses it. This allows gradual migration."

*What separates good from great:* "The graduated migration approach (fingerprinting as fallback when no idempotency key is present, key takes priority when sent) is the production answer for systems with existing clients that cannot change immediately."

---

**[MID] Q5 - [CONCEPTUAL] "Should you use 200 or 204 for a successful DELETE?"**
> "Both are acceptable, but they have different semantics. 204 No Content: the operation succeeded, there is nothing to return. This is the most semantically correct - what would you return after deleting a resource? The deleted resource no longer exists. A simple `204 No Content` with no body is clean and correct. 200 OK with the deleted resource: some APIs return the deleted resource in the response. Useful if the client might want to display 'item X was deleted' with the item's name. Useful if the client needs the data for undo functionality. 200 OK with empty body: incorrect - don't return empty body with 200. Use 204 No Content if there's nothing to return. My recommendation: 204 for most DELETE operations. 200 with the deleted resource if the client has a UX need for the deleted data (undo, confirmation display). Never 200 with empty body. Edge case: deleting a resource that was already deleted. Two approaches: 404 Not Found (correct - resource doesn't exist), or 204 No Content (idempotent response - the goal was to delete it, it is deleted). I prefer the idempotent 204 approach: it simplifies client logic (no need to handle 404 on DELETE as a special case)."

*What separates good from great:* "The idempotency argument for returning 204 on 'already deleted' resources is a production-pragmatic choice that simplifies client logic. Knowing both the 'correct' (404) and 'pragmatic' (204 idempotent) approaches and being able to argue for each shows engineering judgment."

---

**[MID] Q6 - [CONCEPTUAL] "How do HTTP methods interact with CORS preflight?"**
> "CORS (Cross-Origin Resource Sharing) preflight is triggered for 'non-simple' requests. Simple requests: GET, HEAD, POST with standard content types (application/x-www-form-urlencoded, multipart/form-data, text/plain). Non-simple (triggers preflight): any request with PUT, PATCH, DELETE, or POST with Content-Type: application/json. For non-simple requests, the browser first sends an OPTIONS request (the preflight): `OPTIONS /users/123 HTTP/1.1; Origin: https://app.example.com; Access-Control-Request-Method: DELETE`. The server responds with the allowed origins, methods, and headers: `Access-Control-Allow-Origin: https://app.example.com; Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE`. If the preflight succeeds, the browser sends the actual DELETE request. Implication for REST API design: CORS must be configured to allow the HTTP methods your API uses. Many CORS bugs come from server CORS config allowing GET and POST but forgetting DELETE and PATCH. The fix: configure CORS to explicitly allow all methods your API uses. In Spring: `@CrossOrigin(methods = {GET, POST, PUT, PATCH, DELETE})` or global configuration via WebMvcConfigurer."

*What separates good from great:* "Knowing that PUT, PATCH, DELETE always trigger preflight (because they're non-simple) while GET doesn't is the specific detail that helps debug CORS issues. The Spring configuration example makes it actionable."

---

**[SENIOR] Q7 - [CONCEPTUAL] "Why shouldn't you use POST for a search endpoint?"**
> "POST for search is a common mistake. The problem: HTTP caches (CDN, reverse proxy, browser) only cache GET and HEAD responses by default. POST responses are not cached. A search endpoint that processes the same query 1000 times per second (high traffic, common search terms) requires the origin server to process every single request when implemented as POST. With GET (/search?q=shoes&category=women), the CDN can cache the response for 60 seconds and serve thousands of requests per second with zero origin load. The argument for POST search: queries can be complex (large JSON body with many filters, facets, sort options) that don't fit in a URL. Counter-argument: most search APIs use GET with query parameters fine. Elasticsearch's Query DSL uses POST (/index/_search with JSON body) because of query complexity, but this is the exception. The pragmatic rule: if the query fits in a URL (up to ~2048 characters), use GET for cacheability. If the query is complex enough to require a JSON body, POST is justified - but document the caching implications and add application-layer caching if needed."

*What separates good from great:* "Mentioning Elasticsearch's specific exception (POST for search because of query complexity) shows real-world knowledge while still clearly articulating the general rule. The practical URL length limit (~2048 chars) gives candidates a concrete decision threshold."

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


# HTTP Status Codes

---

### 🎯 Model Answer

**30 seconds:**
> HTTP status codes are three-digit numbers in API responses that communicate the outcome: 2xx means success, 3xx means redirect, 4xx means the client made an error, 5xx means the server made an error. The most important codes to know: 200 (success), 201 (created), 204 (no content), 400 (bad request), 401 (unauthorized), 403 (forbidden), 404 (not found), 409 (conflict), 422 (unprocessable entity), 429 (too many requests), 500 (server error), and 503 (service unavailable).

**3 minutes:**
> HTTP status codes are the most underused feature of REST APIs. Developers often return 200 for everything and put the "real" status in the response body (`{"status": "error", "message": "..."`). This breaks HTTP clients, caches, monitoring tools, and load balancers that rely on HTTP semantics. The status code classes have specific meanings: 1xx informational (rarely used in REST APIs - 100 Continue for large uploads). 2xx success: 200 OK (generic success with body), 201 Created (resource created, Location header points to it), 202 Accepted (request received, processing async), 204 No Content (success, nothing to return). 3xx redirects: 301 Moved Permanently (URL changed forever), 302 Found (temporary redirect), 304 Not Modified (conditional GET, cached response is still valid). 4xx client errors: 400 Bad Request (malformed request, invalid params), 401 Unauthorized (not authenticated - despite the name), 403 Forbidden (authenticated but not authorized), 404 Not Found (resource doesn't exist), 405 Method Not Allowed, 409 Conflict (resource conflict - duplicate key, optimistic lock failure), 410 Gone (resource permanently deleted), 422 Unprocessable Entity (semantically invalid request - validation error), 429 Too Many Requests (rate limited). 5xx server errors: 500 Internal Server Error (generic server error), 502 Bad Gateway (upstream service returned invalid response), 503 Service Unavailable (server temporarily down), 504 Gateway Timeout (upstream service timeout). Using status codes correctly allows monitoring (5xx rate alert), client retry logic (retry on 503, don't retry on 400), and caching (304 responses have no body).

**Blank Mind Recovery:**
**(1) Restate:** "HTTP status codes - the number the server sends back."
**(2) First principles:** "What outcomes can an API call have? Success, redirect, client error, server error. The hundreds digit (2, 3, 4, 5) tells you which."
**(3) Bridge:** "Like traffic lights: 2xx = green (success), 4xx = red (your fault), 5xx = red (our fault), 3xx = yellow (go this way instead)."

---

### 📘 Concept Explanation

**What it is:**
HTTP status codes are standardized three-digit integers returned in API responses. The first digit defines the class (success/redirect/client error/server error), the remaining two digits distinguish specific cases within the class.

**The problem it solves:**
Without standardized status codes, every API would invent its own way to communicate outcomes: `{"success": false, "errorCode": "AUTH_FAILED"}`. HTTP clients (browsers, monitoring tools, load balancers, CDNs) cannot interpret these - they understand HTTP semantics. Standardized status codes allow the entire HTTP infrastructure to react correctly to outcomes.

**How it works:**
```
Status Code Classes:

1xx Informational  (rare in REST APIs)
  100 Continue     - upload the rest of the body
  
2xx Success
  200 OK           - success, body contains result
  201 Created      - new resource, Location header
  202 Accepted     - async, processing started
  204 No Content   - success, no body
  
3xx Redirection
  301 Moved Perm.  - URL changed permanently
  304 Not Modified - cached response valid

4xx Client Error
  400 Bad Request  - malformed request
  401 Unauthorized - authentication required
  403 Forbidden    - authenticated, not authorized
  404 Not Found    - resource doesn't exist
  409 Conflict     - duplicate or version conflict
  422 Unprocessable- valid JSON, invalid semantics
  429 Too Many Req - rate limited
  
5xx Server Error
  500 Internal Err - unhandled exception
  502 Bad Gateway  - upstream error
  503 Unavailable  - maintenance/overload
  504 Gateway Tmout- upstream timeout
```

> **Code walkthrough:** This HTTP Status Codes example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The 401/403 distinction is subtle but important. 401 Unauthorized means "I don't know who you are - authenticate first." 403 Forbidden means "I know who you are, and you're not allowed." The naming is confusing (401 is authentication, 403 is authorization), but the distinction matters: 401 prompts the client to log in, 403 tells the user they don't have permission. Returning 403 for unauthenticated requests is a security best practice (don't reveal whether a resource exists to unauthenticated users).

**When to use it:**
Use the most specific status code that applies. Prefer 422 over 400 for validation errors (the body was valid JSON but semantically invalid). Prefer 409 over 400 for conflict errors (the request was valid but conflicts with existing state). Use 204 instead of 200 with empty body.

**When NOT to use it:**
Never use 200 for all responses including errors (the "HTTP 200 is the new 500" anti-pattern). Never use 401 for authorization failures (use 403). Never return 500 for client errors - it obscures where the fault lies.

**Alternatives:**
- Application-level error codes: include in the body alongside correct HTTP status (RFC 7807 Problem Details)
- gRPC status codes: different taxonomy but same concept (OK, NOT_FOUND, PERMISSION_DENIED, INTERNAL, etc.)

**First-principles derivation:**
HTTP was designed for the web. Status codes are the protocol's way of communicating outcomes to all participants - not just the application but also the infrastructure. A 304 response saves bandwidth without the server knowing who the client is. A 503 tells the load balancer to route to a different server. A 429 tells API gateway to throttle. These behaviors require standardized codes.

---

### 💻 Code Example

```java
// Spring Boot - correct status code usage

@RestController
@RequestMapping("/orders")
public class OrderController {

  @PostMapping
  public ResponseEntity<Order> create(
      @Valid @RequestBody CreateOrderRequest req,
      BindingResult result) {
    // Validation failed: 422, not 400
    if (result.hasErrors()) {
      throw new ResponseStatusException(
          HttpStatus.UNPROCESSABLE_ENTITY,
          "Validation failed: " +
          result.getFieldErrors().stream()
              .map(e -> e.getField() + " " +
                   e.getDefaultMessage())
              .collect(joining(", ")));
    }

    try {
      Order order = orderService.create(req);
      URI uri = URI.create("/orders/" + order.getId());
      return ResponseEntity.created(uri).body(order);
      // 201 Created
    } catch (DuplicateOrderException e) {
      // Order with same idempotency key exists
      return ResponseEntity
          .status(HttpStatus.CONFLICT)  // 409
          .body(e.getExistingOrder());
    }
  }

  @GetMapping("/{id}")
  public ResponseEntity<Order> get(
      @PathVariable Long id,
      @RequestHeader(value = "If-None-Match",
                     required = false) String etag) {
    Order order = orderService.findById(id)
        .orElseThrow(() -> new ResponseStatusException(
            HttpStatus.NOT_FOUND));
    
    String currentEtag = "\"" + order.getVersion() + "\"";
    if (currentEtag.equals(etag)) {
      return ResponseEntity.status(
          HttpStatus.NOT_MODIFIED).build(); // 304
    }
    return ResponseEntity.ok()
        .eTag(currentEtag)
        .body(order);
  }
}
```

> **Code walkthrough:** Validation errors return 422 (not 400) because the JSON was valid but the data didn't pass business validation. Duplicate idempotency keys return 409 Conflict with the existing order. Conditional GET returns 304 Not Modified when the ETag matches - saving bandwidth for unchanged resources. This is correct HTTP semantics: status codes communicate to infrastructure, not just the application.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "HTTP status codes tell the client what happened: 2xx means success, 4xx means the client made an error, 5xx means the server had a problem. The most important ones I use: 200 for successful GET, 201 for created resources (with POST), 204 for successful DELETE, 400 for bad input, 401 for authentication failure, 403 for permission denied, 404 when a resource doesn't exist, 422 for validation failures, 500 for server errors. The 401/403 distinction I always remember: 401 means 'who are you?' (not authenticated), 403 means 'I know who you are, but no' (not authorized)."

**Senior / Staff:** "Status codes are the REST API's contract with the HTTP infrastructure - not just the application layer. Getting them right enables: monitoring (alert on 5xx rate spikes), client retry logic (retry 503 with backoff, don't retry 400 - it's a client bug), CDN caching (cache 200 responses, never cache 500), load balancer health checks (route away from instances returning 5xx). Common production mistakes: returning 200 for all responses with errors in the body - monitoring can't distinguish success from failure. Returning 500 for client errors - the operator gets paged for something the client did wrong. Not returning 429 for rate limiting - client doesn't know to back off. At staff level: I've seen systems where all API errors return 200 with an error object in the body. The immediate consequence: the CDN caches these 'error' responses (because it sees 200), serving cached errors to subsequent clients. Fixing status code usage in legacy APIs requires versioning because clients have adapted to the wrong behavior."

---

### ⚠️ Common Misconceptions

**Misconception:** "Use 400 Bad Request for all client error cases."
Reality: 400 Bad Request is for malformed requests - the HTTP request itself is invalid (bad JSON syntax, missing required headers, invalid URL). For semantically valid requests that fail business validation: 422 Unprocessable Entity. For resource conflicts: 409 Conflict. For rate limiting: 429 Too Many Requests. For authentication failures: 401. For authorization failures: 403. For missing resources: 404. Using 400 for all of these collapses the signal: a client receiving 400 doesn't know if it should retry (resource might exist later), fix its request format, authenticate, or slow down. Each specific status code enables a specific client response. The RFC 7807 Problem Details format helps: include a `type` URI and `title` string in the response body to give human-readable and machine-readable error context alongside the correct HTTP status code.

---

### 🚨 Failure Modes and Diagnosis

**Failure: CDN caches error responses because of wrong status codes**

Symptoms: After a bug was fixed and deployed, clients still receive the old error response for minutes or hours. Cache invalidation doesn't fix it because the cached response was a 200 with an error body, not a 5xx.

Root cause: Developer returned 200 with `{"error": "database connection failed"}` instead of 503 Service Unavailable. The CDN cached the 200 response (which is cacheable by default). After the bug was fixed, clients hit the CDN and got the cached error response.

Diagnosis: Check CDN access logs for 200 responses with error bodies. Check if the CDN is configured with cache rules for status codes.

Fix: Return 503 for server errors, not 200. 5xx responses are not cached by default. Configure explicit Cache-Control: no-store for dynamic API endpoints. If you must return an error inside a 200 response (legacy reasons): configure Cache-Control: no-cache, no-store on all such responses.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Comparison | 2 min | 2 |
| Scenario | 2 min | 2 |
| Debugging | 2 min | 1 |
| Trade-off | 2 min | 1 |

**[JUNIOR] Q1 - [CONCEPTUAL] "What is the difference between 401 and 403?"**
> "401 Unauthorized means the request lacks valid authentication credentials - 'I don't know who you are.' The server expects the client to authenticate (send a valid JWT, API key, or Basic auth header). Despite the name 'Unauthorized,' it's actually about authentication. 403 Forbidden means the server knows who you are (authentication succeeded) but you're not allowed to perform this action. Despite the name 'Forbidden,' it's actually about authorization. The naming confusion (401=auth, 403=authz) is historical. The practical HTTP consequence: 401 responses typically include a `WWW-Authenticate` header telling the client HOW to authenticate. 403 has no such header - you're authenticated, just not permitted. Security best practice: some teams return 403 for all cases (both unauthenticated and unauthorized) to avoid revealing whether a resource exists. If an unauthenticated user requests GET /admin/users and gets 401, they know the /admin/users endpoint exists. If they get 403 (or 404), they learn nothing. This is particularly important for sensitive resource paths."

*What separates good from great:* "The security best practice of returning 403 (or 404) for unauthenticated requests to sensitive paths to avoid information leakage is what separates a developer who has thought about API security from one who just uses the codes correctly."

---

**[JUNIOR] Q2 - [TRADE-OFF] "How do you choose between 400, 422, and 409 for error responses?"**
> "The three have distinct semantics: 400 Bad Request: the HTTP request itself is malformed. The JSON body can't be parsed, a required header is missing, the URL format is invalid. The client must fix the request structure. 422 Unprocessable Entity: the request is well-formed (valid JSON, correct headers) but the data fails business validation. Email address is invalid, required field is missing, value is out of range. The client must fix the data values. 409 Conflict: the request is valid and the data is correct, but it conflicts with the current state of the server. Trying to create a user with an email that already exists. Optimistic lock failure (version mismatch). Trying to transition an order to a state that's not valid from the current state (e.g., 'ship' a canceled order). Decision tree: can I parse the request? No -> 400. Can I validate the data? No -> 422. Does the data conflict with server state? Yes -> 409. Is everything fine? -> 2xx. Using these consistently lets clients handle errors appropriately: 400 = fix your HTTP request, 422 = show validation error to user, 409 = resolve the conflict (retry with latest version, present 'email taken' error)."

*What separates good from great:* "The decision tree (can I parse? can I validate? does it conflict?) is a memorable and practical framework. Giving concrete examples for each (optimistic lock failure for 409) makes the distinction tangible."

---

**[JUNIOR] Q3 - [PRODUCTION] "A monitoring alert fires for elevated 500 rate on your API. What do you do?"**
> "Immediate triage: check the 500 rate across all endpoints. Is it one endpoint or broad? Check if the timing correlates with a recent deployment (look at deployment logs or feature flags). Narrow the scope: `kubectl logs -l app=myapi --tail=100 | grep 'ERROR\|Exception'` or check ELK/Splunk for exception stack traces in the time window. If the 500s started after deployment: rollback the deploy first (fastest recovery), investigate root cause after traffic is restored. If not deployment-related: look at the exception type. NullPointerException - logic bug, probably recent code change. DatabaseException or Connection refused - database issue (check RDS/Postgres metrics, connection pool exhaustion). External service timeout - check calls to payment processor, email service, third-party APIs. HttpStatus 502 from internal calls - upstream microservice is down. Monitoring improvement: 500 should carry an error ID that maps to a specific log entry (correlation ID). Log at ERROR level with: endpoint, user_id, request_id, stack trace, upstream service name (if applicable). This allows instant root cause identification from the alert payload."

*What separates good from great:* "The rollback first for deployment-correlated incidents is the right operational priority (restore service, investigate after). Checking connection pool exhaustion and upstream service timeouts shows production experience with the real causes of 500 spikes."

---

**[MID] Q4 - [CONCEPTUAL] "Should you return 404 or 403 when an authenticated user tries to access a resource they don't own?"**
> "Security best practice: return 404. The argument for 403: it's more honest - the resource exists, you just can't access it. The argument for 404: you don't want to confirm to the requester that the resource exists. If user A owns resource /documents/456 and user B tries to access it, returning 403 confirms that /documents/456 exists and belongs to someone. An attacker can enumerate all IDs and determine which ones exist. Returning 404 prevents this information leakage - user B learns nothing about the existence of resource 456. This matters more for some resources than others. For a social media post marked as private: leaking existence is relatively low risk. For medical records or financial documents: leaking existence is a compliance issue. My default: return 404 for ownership failures on sensitive resources. Return 403 for permission failures on clearly-existing public resources (e.g., GET /admin/config when you're not an admin). Document the choice in API documentation so clients know what 404 can mean in context."

*What separates good from great:* "The distinction between 'resource is sensitive' (use 404 to hide existence) and 'resource is publicly known to exist' (use 403 for authorization failure) shows nuanced security thinking. This is the kind of decision made during threat modeling."

---

**[MID] Q5 - [CONCEPTUAL] "What does 202 Accepted mean and when do you use it?"**
> "202 Accepted means: I received your request, I'm working on it, but I haven't finished yet. The request has been queued for async processing. When to use it: long-running operations (video transcoding, report generation, batch processing) that would exceed HTTP timeout if processed synchronously. Notification dispatch (email, SMS) that involves third parties with variable latency. Idempotent operations that are safe to retry if the client doesn't receive confirmation. The 202 response should include in the body: a resource URL to poll for status (or a webhook callback option), an estimated completion time, a unique job ID. Example: POST /video/transcode returns 202 with body `{jobId: "abc123", status: "queued", checkStatusAt: "/jobs/abc123"}`. Client polls GET /jobs/abc123 to check status. Completion returns 200 with `{status: "completed", outputUrl: "..."}`. The alternative to polling: webhooks (server calls the client when done). Webhooks require the client to expose an HTTP endpoint, which isn't always possible. 202 + polling is the universal fallback."

*What separates good from great:* "The response body format for 202 (job ID + poll URL + estimated time) and the discussion of webhooks as an alternative shows you've designed async APIs in production. The 'universal fallback' comment about polling shows practical thinking."

---

**[MID] Q6 - [CONCEPTUAL] "How do clients know when to retry on 503 vs 429?"**
> "Both 503 (Service Unavailable) and 429 (Too Many Requests) suggest retrying later, but with different strategies. 503 Service Unavailable: the server is temporarily down for maintenance or overloaded. The server may include `Retry-After` header (seconds or HTTP-date for when to retry). If no Retry-After: exponential backoff starting at 1 second, doubling each retry, with jitter (random +/- 50% to prevent thundering herd), capped at 60 seconds. 429 Too Many Requests: the client is sending too fast. The server should include `Retry-After` header. The client must wait the specified duration. If no Retry-After: slow down significantly - the client is the source of the problem. For 429, exponential backoff is too slow to recover - the client should wait the full Retry-After duration, not binary search. The difference in client behavior: 503 = server problem, retry after brief wait, it should resolve soon. 429 = client problem, wait the specified time, then reduce request rate going forward. Circuit breaker behavior: 503s trigger the circuit to open (stop sending requests). 429s don't trigger circuit opening - the service is up, the client is just too fast. Rate limiting library should track 429s separately from 5xx errors."

*What separates good from great:* "The nuance about circuit breakers (503 opens circuit, 429 doesn't) is a production detail that most candidates miss. The jitter recommendation for 503 backoff shows understanding of thundering herd."

---

**[SENIOR] Q7 - [CONCEPTUAL] "Why is returning 200 with an error body a problem?"**
> "Returning 200 with `{error: true, message: '...'}` is called the 'HTTP 200 is the new 500' anti-pattern. Five specific problems: (1) CDN caching: CDNs cache 200 responses. An error response cached by Cloudflare is served to all subsequent clients even after the error is fixed. (2) Monitoring gaps: alerting on 5xx rate catches nothing. The error rate appears as 0% while clients receive errors. (3) Client retry logic: clients that retry on 5xx don't retry on 200. Error responses reach the client without retry. (4) Load balancer health checks: load balancers route away from servers returning 5xx. Servers returning 200+error look healthy and keep receiving traffic. (5) HTTP client libraries: libraries that throw exceptions on 4xx/5xx (like Spring's RestTemplate with a ResponseErrorHandler) don't throw on 200 - client code never sees the error. The root cause: developers learned to return 200 because "the HTTP layer worked, the business logic failed." But REST says HTTP codes ARE the business outcome communication channel - that's the uniform interface."

*What separates good from great:* "Enumerating the five specific consequences (CDN caching, monitoring, retry logic, load balancer health, library exceptions) rather than just saying 'it's wrong' shows you've seen all five of these failure modes in production."

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


# REST Resource Naming and URL Design

---

### 🎯 Model Answer

**30 seconds:**
> REST URL design rule: URLs are nouns (resources), HTTP methods are verbs. Use plural nouns, lowercase, hyphens for multi-word names. Hierarchical structure to express relationships. Never put verbs in URLs. The URL identifies WHAT, the HTTP method identifies WHAT TO DO.

**3 minutes:**
> Good REST URL design makes APIs self-documenting and predictable. The fundamental rule: URLs identify resources, HTTP methods express operations. Violating this - putting verbs in URLs like `/getUser`, `/createOrder` - forces clients to read documentation for every endpoint instead of inferring behavior from conventions. The conventions: plural nouns (`/users`, `/orders`), not singular (`/user`, `/order`). Lowercase with hyphens for multi-word resources (`/payment-methods`, not `/paymentMethods` or `/payment_methods`). Hierarchical nesting for relationships (`/users/{id}/orders` for a specific user's orders). Path parameters for identity (`/users/123`), query parameters for filtering, sorting, pagination (`/users?role=admin&sort=name`). Sub-resources for actions when the action doesn't map to CRUD (`/orders/{id}/cancel` is cleaner than `PATCH /orders/{id}` with body `{status: canceled}`). The debate: Stripe uses IDs like `cus_1234567890` instead of plain integers. This prevents ID enumeration (you can't guess customer IDs), prevents accidental cross-resource ID confusion (order IDs and customer IDs are visually different), and makes logs easier to read. The trade-off: longer URLs, more complex ID generation. My preference for public APIs: prefixed IDs. For internal APIs: plain integers are fine.

**Blank Mind Recovery:**
**(1) Restate:** "URL design - how to name the paths in a REST API."
**(2) First principles:** "What does a URL identify? A resource. Resources are things (nouns), not actions (verbs). Users, orders, products."
**(3) Bridge:** "Think of it like a file system path. /documents/456/comments means: in the documents collection, document 456, in its comments subcollection."

---

### 📘 Concept Explanation

**What it is:**
REST resource naming defines how URLs are structured to identify resources in a REST API. Well-named URLs follow conventions that make the API predictable, self-documenting, and consistent.

**The problem it solves:**
Without naming conventions, every team invents different URL patterns: some use `/getUser`, others use `/user/get`, others use `/v1/User/Get`. Clients must read documentation for every endpoint instead of learning the pattern once and applying it everywhere.

**How it works:**
```
URL Design Conventions:

# Collection endpoints
GET  /users          - list all users
POST /users          - create a user

# Resource instance endpoints
GET    /users/123    - get user 123
PUT    /users/123    - replace user 123
PATCH  /users/123    - update user 123
DELETE /users/123    - delete user 123

# Nested resources (relationships)
GET  /users/123/orders  - orders by user 123
POST /users/123/orders  - create order for user 123
GET  /orders/456        - specific order (direct access)

# Filtering and pagination (query params)
GET /users?role=admin&sort=name&page=2&size=20

# Multi-word resources (kebab-case)
GET /payment-methods
GET /shipping-addresses

# Actions (sub-resource when action doesn't map to CRUD)
POST /orders/456/cancel
POST /users/123/verify-email
```

> **Code walkthrough:** This Actions (sub-resource when action doesn't map to CRUD) example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The URL should read like a path through a hierarchy of resources, not like a function call. `/users/123/orders/456/items` reads: "user 123's order 456's items." A client who has never seen this API before can infer what this path means. This is the uniform interface constraint in practice.

**When to use it:**
Every REST API. These conventions are sufficiently universal that clients can make assumptions: `GET /{collection}` lists resources, `GET /{collection}/{id}` gets a specific one, `POST /{collection}` creates one.

**When NOT to use it:**
Overly deep nesting (`/a/1/b/2/c/3/d/4`) becomes hard to read and work with. Limit nesting to two levels. If you need deeper access, provide direct resource URLs: `/items/789` instead of `/users/123/orders/456/items/789`.

**Alternatives:**
- GraphQL: single `/graphql` endpoint, resource identification in the query body
- gRPC: service/method names in the RPC definition, no URL-based resource hierarchy
- JSON:API: strict convention for URLs, relationships, and pagination

**First-principles derivation:**
The web uses hierarchical URLs to identify documents: `/category/subcategory/document.html`. REST borrows this hierarchy for APIs. The hierarchy maps naturally to domain model relationships: users have orders, orders have items. The URL hierarchy mirrors the data hierarchy, making it intuitive.

---

### 💻 Code Example


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: Verb-based URLs (common mistake)
@GetMapping("/getUser")          // should be GET /users/{id}
@PostMapping("/createOrder")     // should be POST /orders
@GetMapping("/getAllProducts")   // should be GET /products
@PostMapping("/deleteUser")      // should be DELETE /users/{id}
@GetMapping("/searchProducts")   // should be GET /products?q=...
// Problems: not predictable, verbs in URLs,
// POST for idempotent delete, GET for search is OK
// but /searchProducts hides cacheability

// GOOD: Resource-based URLs
@RestController
@RequestMapping("/users")
public class UserController {

  // GET /users - list users (optionally filtered)
  @GetMapping
  public Page<User> listUsers(
      @RequestParam(required = false) String role,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    return userService.findAll(role, page, size);
  }

  // GET /users/{id} - get specific user
  @GetMapping("/{id}")
  public User getUser(@PathVariable Long id) {
    return userService.findById(id)
        .orElseThrow(() -> new ResourceNotFoundException(
            "User", id));
  }

  // POST /users - create user
  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public User createUser(
      @Valid @RequestBody CreateUserRequest req) {
    return userService.create(req);
  }
}

// Nested resources
@RestController
@RequestMapping("/users/{userId}/orders")
public class UserOrderController {

  // GET /users/123/orders - orders for user 123
  @GetMapping
  public List<Order> getUserOrders(
      @PathVariable Long userId) {
    return orderService.findByUser(userId);
  }

  // POST /users/123/orders - create order for user 123
  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public Order createOrder(
      @PathVariable Long userId,
      @Valid @RequestBody CreateOrderRequest req) {
    return orderService.createForUser(userId, req);
  }
}
```

> **Code walkthrough:** The BAD examples show the verb-in-URL anti-pattern - each endpoint requires custom documentation because the URL doesn't follow predictable conventions. The GOOD examples follow REST conventions: collection endpoints with GET (list) and POST (create), instance endpoints with GET/PUT/PATCH/DELETE by ID, nested resources for relationships. Note the pagination parameters (page, size) on the list endpoint - clients can paginate without separate documentation.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "REST URL design uses plural nouns for collections (/users, /orders), adds /{id} for specific resources, and nests for relationships (/users/123/orders). No verbs in URLs - the HTTP method is the verb. Lowercase with hyphens for multi-word names. Query parameters for filtering and pagination. Actions that don't fit CRUD go as sub-resources: /orders/123/cancel instead of /cancelOrder."

**Senior / Staff:** "URL design is an API contract that's expensive to change. Three decisions I make explicitly at design time: (1) Nesting depth - maximum two levels (/users/{id}/orders is fine, deeper gets unwieldy). Always provide direct access to nested resources: GET /orders/{id} works alongside GET /users/{id}/orders. (2) ID format - prefixed opaque IDs (`usr_abc123`) for public APIs (prevent enumeration attacks, prevent ID collision confusion) vs. plain integers for internal APIs. (3) Action sub-resources vs. state updates - POST /orders/{id}/cancel is clearer than PATCH /orders/{id} with status=canceled when the cancellation triggers side effects (notifications, inventory release). When the operation is pure state change with no side effects: PATCH. When it triggers business logic: sub-resource. These decisions are hard to reverse after v1 because clients build URL construction logic. The URL is part of the API contract."

---

### ⚠️ Common Misconceptions

**Misconception:** "Nesting is always better because it shows the relationship clearly."
Reality: Deep nesting (`/users/123/orders/456/items/789/variants/012`) creates fragile client code. The client must know the full parent chain to access any resource. If the URL structure changes (items move to a different parent context), all client URLs break. The REST best practice: nest a maximum of two levels for hierarchy expression (`/users/123/orders`), provide direct top-level access for all resources that are primary entities (`/orders/456` works alongside `/users/123/orders/456`). This way, clients with a reference to an order ID can access it directly without traversing the user hierarchy. Deep nesting is appropriate for resources that literally only exist in the context of their parent (an invoice line item only exists within an invoice), but for most resources, two-level nesting is sufficient.

---

### 🚨 Failure Modes and Diagnosis

**Failure: URL design changes break existing API clients**

Symptoms: After renaming `/api/user/list` to `/api/users`, mobile app clients (which cannot be force-updated) get 404 responses. Clients that hardcoded the old URL stop working.

Root cause: URL was treated as an implementation detail, not an API contract. The URL changed without a versioning or backward-compatibility strategy.

Fix: Treat URLs as immutable contracts after release. For changes: (1) Keep the old URL working (redirect 301 or maintain the endpoint). (2) Add the new URL as an additive change. (3) Use versioning: `/v2/users` while `/v1/user/list` remains active. (4) Communicate sunset timeline to known clients with a Deprecation header: `Deprecation: true; Sunset: "2027-01-01"` (RFC 8594). The lesson: design URLs for longevity. Avoid dates, version numbers, implementation details in URLs - these lock in decisions that will need to change.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Design | 2 min | 2 |
| Comparison | 2 min | 1 |
| Scenario | 2 min | 1 |
| Debugging | 2 min | 1 |
| Trade-off | 2 min | 1 |

**[JUNIOR] Q1 - [ARCHITECTURE] "How do you handle actions that don't fit CRUD in REST URL design?"**
> "REST's uniform interface is optimized for CRUD on resources. Actions that don't map to CRUD are the hardest design decision in REST URL design. Three approaches: (1) Model the action as a resource: the action creates a resource. 'Publish a post' becomes `POST /posts/{id}/publications` (creates a Publication resource). 'Cancel an order' becomes `POST /orders/{id}/cancellations`. The resources model the history of actions. Benefit: cacheable, REST-pure. Cost: can feel contrived for simple state changes. (2) Sub-resource action: `POST /orders/{id}/cancel`. Simple, readable, clearly intentional. Not pure REST (verb in URL) but widely used. (3) State transition via PATCH: `PATCH /orders/{id}` with body `{status: canceled}`. Pure REST, but conflates pure data updates with business logic actions. My rule: PATCH for pure state updates with no side effects (update the name field). Sub-resource POST for actions with business side effects (cancellation triggers refund, notification, inventory release). Either approach is fine as long as it's consistent."

*What separates good from great:* "The distinction between 'pure state change' (PATCH is fine) and 'action with business side effects' (sub-resource POST is cleaner) is the judgment call that separates someone who has thought about API design from someone who picked one pattern and applied it everywhere."

---

**[JUNIOR] Q2 - [ARCHITECTURE] "How do you design pagination URLs for a REST API?"**
> "Two pagination strategies with different URL designs: (1) Offset pagination: `GET /orders?page=2&size=20` or `GET /orders?offset=40&limit=20`. Simple. Clients can jump to any page. Works well for small to medium datasets where items are stable. URL is bookmarkable. Problem: inconsistent results if items are added/deleted during pagination (items can skip or repeat). (2) Cursor pagination: `GET /orders?cursor=eyJpZCI6MTAwfQ==&size=20`. The cursor is an opaque token encoding the last-seen position (base64 of `{id: 100, created_at: ...}`). The server queries items with `WHERE id > 100`. Stable pagination: no skipping/repeating even with concurrent inserts/deletes. No random access (can't jump to page 5). Best for: real-time feeds, infinite scroll, export operations. Response should include pagination metadata: `{data: [...], meta: {total: 500, nextCursor: "...", prevCursor: "...", hasNext: true}}`. Or use Link header (RFC 5988): `Link: </orders?cursor=abc>;rel="next", </orders?cursor=xyz>;rel="prev"`. GitHub uses Link header pagination."

*What separates good from great:* "Explaining WHY cursor pagination prevents the skipping/repeating problem (INSERT during pagination with offset causes items to shift) shows you understand the limitation, not just the terminology."

---

**[JUNIOR] Q3 - [CONCEPTUAL] "Should collection URLs be plural or singular? Why?"**
> "Always plural. `/users` not `/user`. The collection URL represents a collection of resources. The plural form is consistent with the English language: a collection of users is 'users.' When you GET `/users`, you get multiple users. When you POST `/users`, you create one user in the collection. Singular is confusing: GET `/user` - which user? The specific instance URL is `/users/{id}` - the collection is plural, the instance has an ID. The consistency rule: keep the same base noun throughout: `GET /users/{id}` (not `/user/{id}` for instance vs `/users` for collection). This symmetry makes the API predictable. The only exception: singleton resources - resources with only one instance per context. `GET /users/{id}/profile` - a user has exactly one profile. `/profile` could be singular. But even here, pluralizing (`/profiles`) is more consistent if profiles might someday support multiple instances. The rule of thumb: when in doubt, pluralize. You can always have one item in a plural collection. You can't cleanly expand a singular resource to a collection without a breaking URL change."

*What separates good from great:* "The singleton resource exception (one profile per user) is a nuanced case that shows deeper knowledge. The 'future-proof' argument (a singular resource can't cleanly expand to a collection) is the practical justification beyond convention."

---

**[MID] Q4 - [CONCEPTUAL] "How do you version a REST API URL?"**
> "URI versioning: include the version in the URL path. `/v1/users`, `/v2/users`. Simplest to implement and test. Most widely used (Stripe `/v1/`, GitHub `/v2020-01-01/`). Cache-friendly (different URLs cache independently). Visible in logs and proxies. The alternatives: header versioning (`Accept: application/vnd.myapp.v2+json`) - clean URLs but cannot be tested with a browser or curl without extra flags. Query parameter versioning (`/users?version=2`) - easy to test but pollutes query string. My recommendation: URI versioning for public APIs. It is the most universally understood pattern and requires zero client configuration to test. What 'versioning' means: a new major version when you make breaking changes (remove fields, rename fields, change semantics). Additive changes (add new fields, add new endpoints) don't require a version bump. RFC 8594 Sunset header: add `Sunset: "2027-01-01"` to v1 responses when v2 is available. Clients that monitor HTTP headers can auto-detect deprecation. Keep v1 running until sunset date."

*What separates good from great:* "Knowing what constitutes a breaking change (removal vs. addition) and the RFC 8594 Sunset header for deprecation communication shows you've managed API lifecycle in production."

---

**[MID] Q5 - [CONCEPTUAL] "How do you handle search in a REST API?"**
> "Search in REST: use GET with query parameters. `GET /products?q=blue+shoes&category=footwear&min_price=50&sort=price_asc`. This is correct REST (GET = read, no side effects, cacheable). URL design for complex filters: flat query parameters for simple filters (field=value). For complex filters (range, nested conditions): `GET /products?filter[price][gte]=50&filter[price][lte]=200` (bracket notation, used by JSON:API). Or: POST /search with JSON body (used by Elasticsearch). The caching trade-off: GET searches are cacheable at CDN/proxy level. POST searches are not. For high-traffic, common searches: GET is significantly more scalable. For rare, complex searches with large filter bodies: POST is pragmatic. Full-text search: typically delegate to Elasticsearch, Solr, or Algolia. The REST API acts as a proxy: `GET /products/search?q=blue+shoes` calls the search backend. Don't expose search engine query syntax directly in the URL (leaks implementation, breaks if you change backends)."

*What separates good from great:* "The caching trade-off (GET for common searches = CDN cacheable, POST for complex searches = not cacheable) is the production-relevant consideration. Mentioning search backend delegation and not exposing query syntax shows architectural thinking."

---

**[MID] Q6 - [ARCHITECTURE] "What are the naming anti-patterns to avoid in REST URL design?"**
> "Six anti-patterns: (1) Verbs in URLs: `/getUser`, `/createOrder`, `/deleteProduct`. The HTTP method is the verb. (2) Mixed case or underscores: `/paymentMethods` or `/payment_methods`. Use lowercase kebab-case: `/payment-methods`. (3) File extensions: `/users.json`, `/products.xml`. Use Accept header for content type negotiation, not file extensions. (4) Implementation details: `/mysql/users`, `/v1_2_3/users`, `/internal/users`. URLs are contracts - internal details should not leak. (5) CRUD action names in paths: `/users/123/update`, `/orders/456/delete`. Use the HTTP method, not path segments. (6) Query parameters for resource identity: `/user?id=123`. Use path parameters for identity (`/users/123`), query parameters for optional filtering. The litmus test: can I learn the API's structure by looking at the URL? If yes, the naming is good. If I need documentation to understand what each URL segment means, the naming is poor."

*What separates good from great:* "The 'litmus test' framing (can you understand the URL without documentation?) is a memorable heuristic. The point about file extensions and content negotiation is often missed - it's the correct REST approach using Accept headers."

---

**[SENIOR] Q7 - [ARCHITECTURE] "How do you design URLs for a multi-tenant REST API?"**
> "Multi-tenant URL design: two main patterns. (1) Tenant in subdomain: `https://tenant-a.api.example.com/users`. Clean, enables per-tenant SSL certificates, DNS-level routing, and completely isolated infrastructure. Complex to implement (certificate management, DNS, routing rules). Used by Salesforce, Zendesk, Shopify. (2) Tenant in URL path: `https://api.example.com/tenants/{tenantId}/users` or `https://api.example.com/{tenantSlug}/users`. Simple to implement. Tenant isolation is at the application layer (extract tenantId from URL, apply in query). Easier to operate (one certificate, one endpoint). Used by GitHub (github.com/{org}/{repo}). The security concern: tenant ID in URL must be validated on every request. The authenticated user must have access to the tenant specified in the URL. Failing to validate this creates insecure direct object reference (IDOR) vulnerabilities - a user from Tenant A accessing Tenant B's data by changing the tenant ID. For internal APIs: put tenant ID in a header or JWT claim rather than the URL. This prevents clients from accidentally constructing cross-tenant requests."

*What separates good from great:* "Naming the IDOR vulnerability (insecure direct object reference) from OWASP as a specific risk of tenant IDs in URLs shows security awareness. The recommendation to use headers/JWT for internal APIs (prevents cross-tenant URL construction accidents) is a production-safety insight."

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



