---
layout: default
title: "REST API - L6 Theory"
parent: "REST API"
grand_parent: "SK Interview"
nav_order: 11
permalink: /rest-api/l6-theory/
---

# Roy Fielding REST Architectural Style

---

### 🎯 Model Answer

**30 seconds:**
> Roy Fielding defined REST in his 2000 PhD dissertation as an architectural style (not a protocol or standard) for distributed hypermedia systems. REST is characterized by six constraints: client-server, stateless, cacheable, uniform interface, layered system, and code-on-demand. These constraints, applied together, produce the scalability and evolution properties that made the web work at internet scale.

**3 minutes:**
> Fielding's dissertation derives REST from first principles. He starts with the null architectural style (no constraints) and adds constraints one at a time, analyzing what each constraint adds in terms of properties (scalability, simplicity, evolvability) and what it costs (performance overhead, implementation complexity). This derivation approach - each constraint has a purpose - is what makes REST a rigorous architectural style rather than a set of conventions. The constraints: (1) Client-server separation: separates the user interface from data storage, improving portability (UI can evolve independently) and scalability (server doesn't store UI state). (2) Statelessness: each request contains all information needed to complete it. Server holds no session state. Improves scalability (any server can handle any request), reliability (no session state to lose on crash), visibility (request can be monitored in isolation). Cost: increased per-request overhead (client must send auth context with every request). (3) Cache: responses must be labeled cacheable or non-cacheable. Caching reduces latency, reduces server load, improves scalability. Cost: cache staleness can reduce correctness. (4) Uniform interface: the central architectural constraint that distinguishes REST. Four sub-constraints: identification of resources (URIs), manipulation through representations, self-descriptive messages, HATEOAS. The uniform interface simplifies architecture and improves visibility but reduces efficiency (information in standardized form rather than optimized for each application). (5) Layered system: client doesn't know if it's talking to the origin server or an intermediary (proxy, CDN). Enables scalability through intermediaries, security through firewalls. (6) Code-on-demand (optional): server can extend client functionality by transferring executable code (JavaScript). The key insight Fielding emphasizes: REST is not HTTP. REST is an architectural style. HTTP happens to be designed to satisfy REST's constraints. Any protocol designed this way would enable the same web-scale properties.

**Blank Mind Recovery:**
**(1) Restate:** "Roy Fielding's REST - architectural style for distributed hypermedia from his 2000 dissertation."
**(2) First principles:** "Six constraints added to the null style. Each constraint adds properties (scalability, evolvability) at a cost."
**(3) Bridge:** "Like engineering design rules - each rule exists for a reason. Break a rule, lose the property it provides."

---

### 📘 Concept Explanation

**What it is:**
REST (Representational State Transfer) is an architectural style for distributed hypermedia systems, defined by Roy Fielding in his 2000 doctoral dissertation at UC Irvine. It is a set of constraints that, when applied, produce the desired properties for web-scale distributed systems.

**The problem it solves:**
The web grew from thousands to billions of users while remaining functional. Fielding analyzed why the web architecture scaled while other distributed systems did not. REST documents those architectural properties as constraints that any system can adopt.

**How it works:**
```
Derivation of REST:

Null Style (no constraints)
  |
  + Client-Server
    -> Separates UI from data storage
    -> Improves portability and scalability
  |
  + Stateless
    -> Each request is self-contained
    -> Improves visibility, reliability, scalability
    -> Cost: increased per-request data
  |
  + Cache
    -> Responses labeled cacheable/non-cacheable
    -> Improves efficiency and scalability
    -> Cost: stale data risk
  |
  + Uniform Interface
    -> Central REST constraint
    -> Four sub-constraints:
       1. Resource identification (URIs)
       2. Manipulation via representations
       3. Self-descriptive messages
       4. HATEOAS
    -> Improves visibility, evolvability
    -> Cost: inefficiency vs optimized protocols
  |
  + Layered System
    -> Intermediaries transparent to client
    -> Enables CDN, proxies, firewalls
    -> Cost: latency (additional hops)
  |
  + Code-on-Demand (optional)
    -> Server extends client via code transfer
    -> Example: JavaScript
    -> Cost: reduces visibility

= REST
```

**The key insight:**
Fielding explicitly states that REST is NOT about CRUD or HTTP methods. It is about the uniform interface constraint, specifically HATEOAS: a truly RESTful API drives client behavior through hyperlinks in responses. The client starts at a known URI and discovers all capabilities through links. This is what made the web evolvable - you can change server behavior by changing the links, without updating clients.

**When to use:**
Designing APIs intended for long-term stability, broad adoption, and independent client evolution.

**When NOT to use:**
Fielding himself criticized "REST APIs" that are actually HTTP RPC. If you need human-readable documentation of all endpoints to use the API: it's not REST in Fielding's sense.

---

### 💻 Code Example

```java
// BAD: Not RESTful - client has hardcoded URLs
// Client code knows all endpoints in advance
public class OrderClient {
  public Order getOrder(Long id) {
    // Client knows the URL structure
    return restTemplate.getForObject(
        "https://api.myapp.com/orders/" + id,
        Order.class);
  }

  public void cancelOrder(Long id) {
    // Client knows this URL too
    restTemplate.postForObject(
        "https://api.myapp.com/orders/"
        + id + "/cancel",
        null, Void.class);
  }
}

// GOOD: HATEOAS-compliant REST
// Client follows links from responses
// (Fielding's actual intent)
public class RestfulOrderClient {

  public void processOrder(String startUri) {
    // Client only knows the starting URI
    Resource<Order> orderResource =
        halClient.get(startUri, Order.class);

    Order order = orderResource.getContent();

    // Actions discovered from response links
    // Not hardcoded in the client
    if (orderResource.hasLink("cancel")) {
      Link cancelLink =
          orderResource.getRequiredLink("cancel");
      // Follow the link the server provided
      halClient.post(cancelLink.getHref(), null);
    }
  }
}

// Server: Spring HATEOAS response
@GetMapping("/orders/{id}")
public EntityModel<Order> getOrder(
    @PathVariable Long id) {

  Order order = orderService.findById(id);

  EntityModel<Order> resource =
      EntityModel.of(order);

  // Add self link
  resource.add(linkTo(methodOn(
      OrderController.class).getOrder(id))
      .withSelfRel());

  // Conditionally add action links
  // based on state - this is the key
  if (order.getStatus() == PENDING) {
    resource.add(linkTo(methodOn(
        OrderController.class)
        .cancelOrder(id)).withRel("cancel"));

    resource.add(linkTo(methodOn(
        OrderController.class)
        .confirmOrder(id)).withRel("confirm"));
  }

  if (order.getStatus() == SHIPPED) {
    resource.add(linkTo(methodOn(
        OrderController.class)
        .trackOrder(id)).withRel("track"));
  }

  return resource;
}
```

> **Code walkthrough:** The BAD pattern shows the most common "REST" API implementation - client has hardcoded URLs for every operation. This violates Fielding's uniform interface (HATEOAS sub-constraint). If the server changes `/orders/{id}/cancel` to `/orders/{id}/cancellation`, every client breaks. The GOOD pattern shows true HATEOAS: the client starts at one URI and discovers available actions from the response links. The server conditionally includes links based on order state (pending orders have cancel/confirm links; shipped orders have track link). This means the server can change available actions, URL structures, and state transitions without any client changes - the core evolvability benefit.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Roy Fielding invented REST in his PhD dissertation. REST stands for Representational State Transfer. The main constraints are statelessness (each request contains all needed information), client-server separation, caching, and uniform interface (using HTTP methods and status codes consistently). HATEOAS means the API includes links in responses."

**Senior / Staff:** "Fielding's dissertation is important because REST is often misunderstood as 'HTTP with JSON and nouns in URLs' rather than what Fielding actually specified. The critical insight: REST's most important constraint is HATEOAS - hypermedia as the engine of application state. In a truly RESTful system, clients only know one URI (the entry point). All other capabilities are discovered via links in responses. This makes the API evolvable: server can change URLs, add new actions, deprecate old ones, and no client breaks because no client has hardcoded URLs. In practice, almost no production API implements HATEOAS this strictly. The reason: HATEOAS requires sophisticated clients that can follow arbitrary links, which is harder to implement than a client with hardcoded URL knowledge. Most APIs implement the REST constraints partially: statelessness (yes), uniform interface (partially - HTTP methods and status codes), caching headers (sometimes), HATEOAS (almost never). The implication: when you say 'our API is RESTful,' you probably mean 'our API uses HTTP with JSON and resource-based URLs.' That's fine - it works well in practice. But Fielding's dissertation is the origin and intent."

---

### ⚠️ Common Misconceptions

**Misconception:** "Using HTTP methods (GET, POST, PUT, DELETE) correctly makes an API RESTful."
Reality: Correct HTTP method usage is one small part of REST's uniform interface constraint. Fielding defines four sub-constraints for the uniform interface: (1) Identification of resources (URIs). (2) Manipulation of resources through representations. (3) Self-descriptive messages (each message includes enough information to describe how to process it). (4) Hypermedia as the engine of application state (HATEOAS). Most "RESTful" APIs satisfy (1) and (2) but not (3) and (4). Self-descriptive messages means the media type in the Content-Type header is sufficient to understand how to parse and process the message. HATEOAS means all actions are represented as hyperlinks in responses. Fielding famously wrote in 2008: "What needs to be done to make the REST architectural style clear on the notion that hypertext is a constraint? In other words, if the engine of application state (and hence the API) is not being driven by hypertext, then it cannot be RESTful and cannot be a REST API. Period."

---

### 🚨 Failure Modes and Diagnosis

**Failure: API breaks clients when URLs change**

Symptom: A URL refactoring breaks all API clients. Clients get 404 errors. Must coordinate with every client team to update to new URLs.

Root cause: Clients have hardcoded knowledge of URL structures (violating HATEOAS). When the server changes its internal URL scheme, all clients break.

The HATEOAS solution: clients only know the entry point URI. All other URIs are discovered via links in server responses. Server can change any URL except the entry point without breaking clients. In practice (most teams): maintain URL stability as a contract (use API versioning instead of HATEOAS). Put the URL stability guarantee in an SLA with clients. This is pragmatic but is acknowledging that HATEOAS is not implemented.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Mechanism | 3 min | 2 |
| Design | 3 min | 2 |
| Theory | 3 min | 2 |
| Trade-off | 2 min | 2 |
| Behavioral | 2 min | 1 |

#### Q1 - "What are the six REST constraints and what property does each add?"
> "REST constraints and properties: (1) Client-Server: separates UI from data storage. Property: portability (UI evolves independently), scalability (server doesn't store UI state). Cost: initial interface contract design. (2) Stateless: each request contains all information needed. Server holds no session state. Property: visibility (any monitor can see complete request), reliability (no session state lost on crash), scalability (any server handles any request, no session affinity). Cost: increased per-request overhead (client sends auth context every time). (3) Cache: responses labeled cacheable or not. Property: efficiency (reduced latency for cached responses), scalability (reduced server load). Cost: stale data if caching misconfigured. (4) Uniform Interface: central constraint. Four sub-constraints: resource identification (URIs), manipulation via representations, self-descriptive messages, HATEOAS. Property: decouples implementation from service interface, visibility, evolvability. Cost: inefficiency vs optimized protocols. (5) Layered System: client can't tell if talking to origin or intermediary. Property: scalability (CDN, proxy caching), security (firewalls, security gateways). Cost: added latency from intermediary hops. (6) Code-on-Demand (optional): server transfers executable code to client. Property: extends client functionality without prior deployment. Cost: reduces visibility (code behavior is opaque). The key test: 'What is this constraint buying us?' If you remove a constraint: you lose the property it provides."

*What separates good from great:* "Framing each constraint as a property purchased at a cost (Fielding's actual derivation method) shows you've read and understood the dissertation, not just a summary."

---

#### Q2 - "What did Fielding actually mean by HATEOAS and why is it so rarely implemented?"
> "HATEOAS (Hypermedia As The Engine Of Application State): the client starts at a known entry point URI. All subsequent actions are discovered from links in server responses. The client never constructs URLs. The server drives the application state machine through links. Why it enables evolution: server changes the `cancel` action URL from `/orders/{id}/cancel` to `/orders/{id}/cancellation`. Since clients follow links (not hardcoded URLs), they automatically use the new URL on their next request. No client code change needed. Why rarely implemented: (1) Requires sophisticated clients. The client must be able to follow arbitrary links, not hardcoded URL templates. Building such a client is harder than building a client with documented URLs. (2) Requires link-aware media types (HAL+JSON, JSON-API, Siren). Most teams use plain JSON. (3) The evolvability benefit materializes only when URLs actually change. Many API providers use API versioning instead - a simpler mechanism to manage change. (4) Discovery has overhead. Client makes a request to discover what it can do, then makes the action request. Two round trips instead of one. In practice: most teams document all endpoints, use URL versioning, and accept that clients will break if undocumented URLs change. This works well but is not REST in Fielding's sense."

*What separates good from great:* "The two-round-trip discovery overhead and the API versioning as a practical HATEOAS substitute show the pragmatic engineering trade-offs that explain why HATEOAS is theoretically correct but practically uncommon."

---

#### Q3 - "Why does Fielding say most 'REST APIs' are not actually RESTful?"
> "Fielding's 2008 blog post directly addressed this. He defined REST explicitly. Modern 'REST APIs' typically: use HTTP with JSON, have resource-based URLs (nouns), use HTTP methods (GET/POST/PUT/DELETE), return status codes. What they don't do: implement HATEOAS (clients have hardcoded URL knowledge). Self-descriptive messages (Content-Type is usually `application/json`, not a semantic media type). Fielding's statement: 'I am getting frustrated by the number of people calling any HTTP-based interface a REST API. What needs to be done to make the REST architectural style clear on the notion that hypertext is a constraint? If the engine of application state is not being driven by hypertext, then it cannot be RESTful.' In practice: the industry adopted the term 'REST' to mean 'HTTP + JSON + nouns in URLs.' This is a useful practical pattern even without HATEOAS. Richardson's Maturity Model (see next keyword) provides a nuanced framework: Level 0-3, where Level 3 is full HATEOAS and most production APIs are Level 2. Being clear about which level you've implemented avoids confusion. The practical conclusion: saying 'our API is RESTful' in the industry means Level 2 (HTTP methods + resources). Being precise about this distinction shows architectural depth."

*What separates good from great:* "Quoting Fielding's actual 2008 criticism and the Richardson Maturity Model as the industry's pragmatic resolution of the 'true REST' tension shows the full historical and practical context."

---

#### Q4 - "What is the uniform interface constraint and why is it the most important?"
> "The uniform interface is the central differentiating constraint of REST. Fielding: 'The central feature that distinguishes the REST architectural style from other network-based styles is its emphasis on a uniform interface between components.' Four sub-constraints: (1) Identification of resources: resources are identified by URIs. The URI is a stable identifier for the resource concept, not for a specific representation. `/orders/123` identifies the Order 123 concept regardless of whether you receive it as JSON, XML, or HTML. (2) Manipulation of resources through representations: clients interact with resources through representations (JSON, XML). The representation can differ from the internal storage format. (3) Self-descriptive messages: each message includes enough information to describe how to process it. `Content-Type: application/hal+json` tells the client how to parse the message and that it contains HAL links. (4) HATEOAS: hypermedia drives application state transitions. What the uniform interface buys: decoupling. Client and server can evolve independently because the interface between them is uniform and stable. Server can change implementation. Client can change usage patterns. As long as the representations and links don't break, both sides are independent. The cost: less efficient than a specialized protocol. HTTP + JSON is not as efficient as a binary protocol optimized for the specific data. Fielding accepts this cost explicitly for the evolvability benefit."

*What separates good from great:* "The 'URI identifies the resource concept not a representation' distinction (ordering vs JSON ordering) and the explicit acknowledgment of the efficiency cost show deep understanding of Fielding's trade-off reasoning."

---

#### Q5 - "How does REST enable web-scale systems and why does statelessness matter?"
> "Statelessness is the constraint that most directly enables web scale. Without statelessness (session-based architecture): every client request must be routed to the specific server that holds the session. Adding server capacity requires migrating sessions. Server crashes lose sessions (client state lost). Load balancing requires session affinity (sticky sessions) - some servers are overloaded while others are idle. With statelessness (REST's model): any server can handle any client request. The client sends all necessary context with each request (JWT token, request parameters). Load balancer routes freely - no session affinity needed. Scaling is linear: double the servers, double the capacity. Server crashes are transparent to clients - the next request goes to any healthy server. This is how the web scaled from thousands to billions of users. Each HTTP request is stateless - the server doesn't need to remember previous requests. CDNs can cache responses because there's no per-user server state. Proxies can route requests because they're self-contained. The cost Fielding acknowledges: increased per-request data. Every REST request must include auth context (JWT), which may be 500+ bytes. For a chatty API (100 requests per page), this adds overhead vs session cookies. The trade-off: accept the per-request overhead for the scalability and reliability benefits."

*What separates good from great:* "The linear scaling (double servers = double capacity) and the CDN cacheability as direct consequences of statelessness connect the architectural constraint to its operational benefits."

---

#### Q6 - "What does Fielding say about REST and HTTP? Are they the same thing?"
> "Fielding explicitly separates REST (an architectural style) from HTTP (a protocol). REST is a set of constraints applicable to any distributed hypermedia system. HTTP was designed to satisfy REST's constraints. But REST is not HTTP and HTTP is not REST. Fielding designed HTTP 1.1 while developing REST theory - REST is the architectural principle behind HTTP's design choices. Key point: the GET method is safe and idempotent because the stateless and cacheable REST constraints require it. HTTP methods were chosen to satisfy REST constraints, not the other way around. Could you implement REST over another protocol? Theoretically yes - if the protocol supports: resource identification (some form of addressing), uniform interface (standard operations), stateless communication, cacheability marking. In practice: HTTP became the standard. The industry built REST APIs on HTTP. Fielding's regret: the industry adopted HTTP as synonymous with REST. When people say 'use REST,' they mean 'use HTTP.' This conflation obscures the architectural purpose of REST's constraints. A system can use HTTP without satisfying REST constraints (stateful sessions, non-uniform interfaces, no caching headers). A system could theoretically satisfy REST constraints without HTTP. Understanding the separation clarifies why each HTTP feature exists."

*What separates good from great:* "The historical causality (Fielding designed HTTP 1.1 while developing REST theory, so HTTP's design choices reflect REST's constraints) is the architectural history that explains why GET is idempotent and cacheable."

---

#### Q7 - "What is the layered system constraint and how does it enable the CDN?"
> "Layered system: the client cannot tell if it's communicating directly with the origin server or with an intermediary (proxy, CDN, load balancer, gateway). Each layer knows only its immediate neighbors. This constraint enables: (1) CDN caching: a CDN edge server can serve cached responses on behalf of the origin. The client sends a request to the CDN edge. The CDN checks its cache. If cached: serve from edge (low latency, no load on origin). If not cached: forward to origin, cache the response. Client is unaware of the CDN layer. This works because responses are labeled cacheable and stateless: the CDN can safely serve the cached response to any client. (2) Security proxies: a WAF (Web Application Firewall) can sit between the client and origin, inspecting and filtering requests. The origin sees requests that have passed WAF inspection without knowing the WAF exists. (3) Load balancers: route requests across origin servers. Clients don't know they're behind a load balancer. (4) API Gateway: transforms requests, enforces rate limits, handles auth - all transparent to clients. The constraint: layers cannot violate the uniform interface. A CDN must preserve HTTP semantics. A WAF must not alter response content. Each intermediary can add but not break. Cost: latency added by each layer. 3 layers (CDN + WAF + load balancer) each add 1-5ms."

*What separates good from great:* "The CDN caching working specifically because REST responses are stateless and cacheable-labeled (the layered system and cache constraints enabling each other) shows how the constraints work together, not independently."

---

#### Q8 - "Why did Fielding write his dissertation and what was the historical context?"
> "Fielding wrote his dissertation in 2000 at the University of California, Irvine. He was a principal author of HTTP/1.1 and a co-author of the URI specification. The historical context: the web had grown explosively (1991-2000) from a research project to billions of users. But the architectural principles that made this scale possible were implicit, not documented. Fielding's goal: extract and document the architectural constraints that made the web work, so future systems could be designed to achieve the same properties. The timing is significant: 2000 was when web services (SOAP, XML-RPC) were emerging as an alternative to HTTP-based APIs. SOAP was designed as an RPC system with a formal contract (WSDL). Fielding's dissertation provided an architectural alternative - REST - that explicitly leveraged HTTP's strengths rather than treating HTTP as a transport layer (as SOAP does). The dissertation's impact: REST won. SOAP is used in legacy enterprise systems. REST + JSON is the dominant web API style. But Fielding's actual REST constraints (especially HATEOAS) are rarely implemented fully. The industry adopted the name 'REST' and a subset of the constraints. The practical result is good enough. Fielding's regret is that the evolvability benefit (HATEOAS) was sacrificed for simplicity."

*What separates good from great:* "The historical context (SOAP vs REST as a contemporary debate when the dissertation was written) and Fielding's role in designing HTTP 1.1 and URI specs show the dissertation in its actual engineering context."

---

#### Q9 - "How does Fielding's REST theory apply to modern API design decisions?"
> "Applying Fielding's theory to modern decisions: (1) Statelessness decision: should you use sessions or JWT? Fielding's answer: JWT (stateless). Sessions violate the stateless constraint. The benefits - any server handles any request, linear scalability, no session affinity - are worth the JWT overhead. In practice: most teams use JWT for REST APIs. Sessions for web applications (stateful). (2) Caching decision: should you cache this response? REST's cache constraint says mark every response cacheable or non-cacheable. In practice: add Cache-Control headers to every GET response. Public, time-limited responses: `Cache-Control: public, max-age=300`. User-specific responses: `Cache-Control: private, no-store`. (3) Versioning decision: breaking change in API contract. REST's uniform interface says don't break the interface. HATEOAS would allow changes without breaking clients. In practice: use URL versioning (`/v2/`) or header versioning. This is a pragmatic compromise on the HATEOAS ideal. (4) URL design: `/orders/123/cancel` vs `POST /orders/123/cancellations`. Fielding's REST: resource-based. Cancel as a noun resource (`cancellations`) is more RESTful than cancel as an action verb. Most teams use the verb form for clarity. Pragmatic > dogmatic. The framework: understand Fielding's reasoning for each constraint, then make deliberate decisions about which constraints to implement and which to trade off."

*What separates good from great:* "The cancellation-as-noun vs cancel-as-verb example and the explicit 'pragmatic > dogmatic' conclusion show balanced architectural thinking - you can discuss Fielding at depth while also acknowledging when full implementation is impractical."

---

---

# Richardson Maturity Model

---

### 🎯 Model Answer

**30 seconds:**
> The Richardson Maturity Model (RMM) is a classification framework by Leonard Richardson that grades REST API implementations from Level 0 to Level 3. Level 0: HTTP as transport for RPC. Level 1: resources (nouns in URLs). Level 2: HTTP verbs and status codes. Level 3: HATEOAS (hypermedia links). Most production APIs are Level 2. Level 3 is Fielding's "true REST."

**3 minutes:**
> The RMM provides a practical progression from RPC-style HTTP to Fielding's fully RESTful APIs. Level 0 (HTTP Tunnel or Swamp of POX): HTTP is a transport protocol only. All requests go to one endpoint. Operations are specified in the request body. SOAP and XML-RPC operate at Level 0. Example: `POST /api - body: { action: "getOrder", id: 123 }`. Level 1 (Resources): individual resources get their own URLs. `/orders/123` instead of passing the resource in the body. This is the minimum for "REST-like" APIs. Level 2 (HTTP Verbs): uses HTTP methods semantically. `GET /orders/123` (read, cacheable). `POST /orders` (create). `PUT /orders/123` (full update). `DELETE /orders/123` (delete). Returns appropriate HTTP status codes (201 Created, 404 Not Found, 409 Conflict). Level 2 is the de facto industry standard. Level 3 (HATEOAS): responses include links to available actions. The server drives the client's state machine through hyperlinks. Full Fielding REST. The model's value: it gives teams a vocabulary for discussing API design maturity. "Our API is Level 2 - we use HTTP verbs and status codes correctly." It also provides a progression path: you don't have to implement Level 3 to have a well-designed API. Level 2 is practical and serves most use cases well.

**Blank Mind Recovery:**
**(1) Restate:** "RMM - four levels of REST maturity from HTTP-as-transport to full HATEOAS."
**(2) First principles:** "0: HTTP tunnel. 1: add resources. 2: add HTTP verbs. 3: add hypermedia links."
**(3) Bridge:** "Like software development maturity models. You don't have to be at Level 3 to ship good software. Level 2 is solid production-ready."

---

### 📘 Concept Explanation

**What it is:**
The Richardson Maturity Model (RMM) is a framework created by Leonard Richardson, popularized by Martin Fowler, that classifies REST API implementations into four levels based on their use of HTTP features and REST constraints.

**The problem it solves:**
REST is often misunderstood. Teams disagree about what "RESTful" means. The RMM provides a shared vocabulary and a progression framework for API maturity discussions.

**How it works:**
```
Level 0 - Swamp of POX (Plain Old XML/JSON):
POST /api HTTP/1.1
{ "action": "getOrder", "id": 123 }
One endpoint, all operations in body.
HTTP is just a transport. SOAP, XML-RPC.

Level 1 - Resources:
GET /api?resource=order&id=123
Resources identified by URL or parameter.
Still using POST for everything.

Level 2 - HTTP Verbs (Industry Standard):
GET    /orders/123     -> 200 OK + body
POST   /orders         -> 201 Created
PUT    /orders/123     -> 200 OK
DELETE /orders/123     -> 204 No Content
GET    /orders/999     -> 404 Not Found
POST   /orders (dup)   -> 409 Conflict
HTTP methods and status codes used correctly.

Level 3 - HATEOAS (Fielding's REST):
GET /orders/123
Response:
{
  "id": 123,
  "status": "pending",
  "_links": {
    "self":    { "href": "/orders/123" },
    "cancel":  { "href": "/orders/123/cancel" },
    "confirm": { "href": "/orders/123/confirm" }
  }
}
Server drives client via links. Client
only knows the entry point URI.
```

**The key insight:**
The RMM is descriptive, not prescriptive. It doesn't say Level 3 is always better. It says: here is a continuum. Know where your API is. Make deliberate choices about how far you go. For most APIs: Level 2 is the right pragmatic target.

---

### 💻 Code Example

```java
// Level 0 - HTTP Tunnel (BAD)
// One endpoint, action in request body
@PostMapping("/api")
public Response handleAll(
    @RequestBody ApiRequest request) {
  // PROBLEM: HTTP semantics ignored
  // No caching possible
  // No standard client behavior
  switch (request.getAction()) {
    case "getOrder":
      return orderService.get(request.getId());
    case "createOrder":
      return orderService.create(request);
    case "cancelOrder":
      return orderService.cancel(request.getId());
  }
}

// Level 2 - HTTP Verbs (GOOD - industry standard)
@RestController
@RequestMapping("/orders")
public class OrderController {

  // GET = safe, idempotent, cacheable
  @GetMapping("/{id}")
  public ResponseEntity<Order> getOrder(
      @PathVariable Long id) {
    return orderService.findById(id)
        .map(order -> ResponseEntity
            .ok()
            .cacheControl(
                CacheControl.maxAge(60, SECONDS))
            .body(order))
        .orElse(ResponseEntity
            .notFound().build()); // 404
  }

  // POST = non-idempotent create
  @PostMapping
  public ResponseEntity<Order> createOrder(
      @RequestBody @Valid CreateOrderRequest req,
      UriComponentsBuilder uriBuilder) {
    Order created = orderService.create(req);
    URI location = uriBuilder
        .path("/orders/{id}")
        .buildAndExpand(created.getId())
        .toUri();
    return ResponseEntity
        .created(location)  // 201 + Location
        .body(created);
  }

  // DELETE = idempotent remove
  @DeleteMapping("/{id}")
  public ResponseEntity<Void> deleteOrder(
      @PathVariable Long id) {
    orderService.delete(id);
    return ResponseEntity
        .noContent().build(); // 204
  }
}

// Level 3 - HATEOAS (Fielding's intent)
@GetMapping("/{id}")
public EntityModel<Order> getOrder(
    @PathVariable Long id) {
  Order order = orderService.findById(id);
  EntityModel<Order> model =
      EntityModel.of(order);

  // Always: self link
  model.add(linkTo(methodOn(
      OrderController.class)
      .getOrder(id)).withSelfRel());

  // Conditional: state-driven links
  if (order.getStatus() == PENDING) {
    model.add(linkTo(methodOn(
        OrderController.class)
        .cancelOrder(id)).withRel("cancel"));
  }

  return model;
}
```

> **Code walkthrough:** Three levels shown side by side. Level 0 (BAD): all requests to `/api` with action in body - loses HTTP caching (POST is not cacheable), loses client type safety, loses standard tooling support. Level 2 (GOOD): GET for reads (cacheable, safe), POST for creates (returns 201 + Location header with the new resource URL), DELETE for removes (returns 204 No Content). This is the industry standard. Level 3: conditionally includes action links based on order state - the `cancel` link only appears when the order is cancellable. Clients discover actions rather than hardcoding them.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "The Richardson Maturity Model has four levels. Level 0 uses HTTP just as a transport like SOAP does. Level 1 adds resources with separate URLs. Level 2 adds proper HTTP methods and status codes, which is what most REST APIs do. Level 3 adds HATEOAS where responses include links to available actions."

**Senior / Staff:** "The RMM is useful in architecture reviews when teams debate 'how RESTful is our API.' My practical take: Level 2 is the appropriate target for most APIs. It gives you: correct caching semantics (GET is cacheable, POST is not), idiomatic client code (clients understand GET vs POST vs DELETE), and standard error communication (404 vs 200 with an error body). Level 3/HATEOAS is theoretically superior for evolvability but has real costs: client complexity (client must follow links, not use hardcoded URLs), discovery overhead (extra requests to find available actions), and media type requirements (HAL+JSON or similar). The teams that implement Level 3 are building APIs consumed by clients they don't control over a very long time horizon (public APIs with many external clients and long deprecation cycles). GitHub's API is Level 2 with partial Level 3 elements. Most internal microservice APIs are Level 2. If you're building an API for a single internal consumer: Level 2 is fine. If you're building a platform API for thousands of external developers: invest in the Level 3 elements that provide long-term stability."

---

### ⚠️ Common Misconceptions

**Misconception:** "Any API that uses GET/POST/PUT/DELETE is Level 2."
Reality: Level 2 requires correct use of both HTTP methods AND HTTP status codes. Both components are required. Using GET for reads but returning `200 OK` with `{ "success": false, "error": "not found" }` is NOT Level 2 - it's Level 1 with HTTP method theater. Level 2 correctly means: GET is safe and idempotent (cacheable, no side effects). POST is for non-idempotent creates. PUT is idempotent (same result if called multiple times). DELETE is idempotent. 404 for not found (not 200 with error body). 201 for created resources (with Location header). 409 for conflict. 422 for validation errors. 503 for service unavailable. Many self-described "Level 2 REST APIs" have error handling that returns 200 with error information in the body. This breaks HTTP clients that use status codes to decide behavior (retries, caching, error handling). The status code is part of the HTTP uniform interface - using it correctly is what makes Level 2 interoperate with standard HTTP tooling.

---

### 🚨 Failure Modes and Diagnosis

**Failure: API clients implement incorrect retry logic due to non-standard status codes**

Symptom: Client retries a POST request after a timeout, creating duplicate orders. Investigation shows the API returned 200 for the timeout case (the request succeeded on the server but the client timed out waiting for the response).

Root cause: Non-idiomatic status code usage. The server should return 409 Conflict if the client retries a request that already succeeded. Or implement idempotency keys: clients send `Idempotency-Key: uuid` header. Server stores the response for each key. If the same key is received again: return the stored response (not execute again).

Diagnosis: Check the access log. Was the POST executed once or twice? Check the database - are there duplicate orders? The client timed out but the server may have completed the request. Solution: idempotency keys for all non-idempotent operations.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Mechanism | 3 min | 2 |
| Design | 3 min | 2 |
| Trade-off | 2 min | 2 |
| Theory | 2 min | 1 |
| Behavioral | 2 min | 2 |

#### Q1 - "What distinguishes Level 2 from Level 1 in the Richardson Maturity Model?"
> "Level 1 vs Level 2: Level 1 introduces resource-based URLs but uses HTTP methods without semantic meaning. In a Level 1 API: `POST /orders/123` might return the order. `POST /orders/123` might also update it. The POST method is overloaded for all operations. HTTP status codes may not be used correctly - everything returns 200. Level 2 uses HTTP methods according to their semantic contracts: GET is safe (no side effects) and idempotent (same response if called multiple times). Cacheable: `Cache-Control: public, max-age=300` is valid. POST creates a new resource, non-idempotent, not cacheable. PUT replaces a resource at a known URI, idempotent. DELETE removes a resource, idempotent. Level 2 also uses HTTP status codes correctly. The practical impact of Level 2: HTTP caching infrastructure (CDN, browser cache) works correctly because GET responses are marked cacheable. Standard HTTP clients understand the operation type. `GET /orders/123` can be called without fear of side effects. Monitoring tools can classify requests by method. Retry logic: clients safely retry GET (idempotent), but not POST (not idempotent, could create duplicates). Level 1 breaks all of this."

*What separates good from great:* "The retry logic consequence (safely retry GET but not POST because Level 2 GET is idempotent) and the CDN caching working because GET is cacheable connect the Level 2 semantics to operational behaviors."

---

#### Q2 - "When should you implement Level 3 HATEOAS and what does it actually require?"
> "HATEOAS implementation decision: appropriate when: (1) Your API has a large number of external consumers you don't control. (2) The API will live for 5-10+ years with multiple breaking change cycles. (3) You have resources to build and maintain the link infrastructure. (4) Your clients can be built to follow links rather than hardcoded URLs. What HATEOAS actually requires: (1) Link-aware media type. Plain `application/json` doesn't define link format. Use HAL+JSON (`application/hal+json`): `{ '_links': { 'self': {'href': '...'}, 'cancel': {'href': '...'} } }`. Or JSON:API, Siren. (2) Server generates links based on state. Conditional links based on resource state (pending order has cancel link, shipped order has track link). (3) Clients follow links. Client must not construct URLs. Must parse link relations and follow them. (4) Entry point discovery. Client knows one URI (the API root). All resources discovered from root. In practice: a hybrid is common. GitHub API includes some HAL-style links for pagination (`link: <...>; rel='next'`) but not for all operations. Stripe uses documented URLs (Level 2) with extremely stable URL contracts. Both approaches work in practice."

*What separates good from great:* "The GitHub and Stripe examples as real-world Level 2 and hybrid Level 3 implementations anchor the theoretical framework in production APIs."

---

#### Q3 - "How does the RMM help in API design reviews?"
> "RMM as a design review tool: explicit level declaration. When reviewing an API design, establish the target level first. 'This is a public developer API. We're targeting Level 2 with stable URL contracts. HATEOAS is out of scope.' This prevents theological debates about 'true REST.' Common Level 2 violations to catch in reviews: (1) GET with side effects. `GET /orders/123/process` that processes the order. Should be POST - GET is assumed safe by clients and intermediaries. Breaking GET's safety contract causes unintended side effects from browser prefetch, CDN HEAD requests. (2) 200 OK for errors. `GET /orders/999` returning `200 OK` with `{ 'error': 'not found' }`. Should be 404. Breaks HTTP client error handling. (3) POST where PUT should be used. `POST /orders/123` to update order 123. Should be PUT or PATCH. POST implies creating a new child resource. (4) Lack of idempotency. Multiple `PUT /orders/123` with the same body should produce the same result. If they don't: the server is not truly idempotent. (5) Missing Location header on 201. `POST /orders` returns 201 without Location header. Client doesn't know the URL of the created resource. The review checklist: method semantics, status code correctness, idempotency, Location on 201, Content-Type/Accept headers."

*What separates good from great:* "The GET with side effects violation (browser prefetch can trigger unintended side effects if GET is not safe) is the real production bug caused by Level 2 violation."

---

#### Q4 - "What is the 'Swamp of POX' and why is it a problem?"
> "Swamp of POX (Plain Old XML, or Plain Old JSON): Level 0. A single endpoint receives all API calls. The HTTP method has no meaning (usually POST for everything). The operation is specified in the request body. Example: `POST /api - { 'method': 'getOrder', 'params': {'id': 123} }`. Problems: (1) No caching. POST is not cacheable. Even read operations (getOrder) use POST. No CDN caching, no browser caching, no proxy caching. Every request hits the origin. (2) Client type safety lost. What operations are available? What parameters? Buried in the request body format. Not inferable from HTTP semantics. (3) Monitoring and logging complexity. All requests are POST to the same endpoint. Monitoring can't distinguish read vs write operations without parsing request bodies. Alerting on write errors requires body inspection. (4) Load balancer routing impossible. Can't route `getOrder` to read replicas and `createOrder` to the write master based on HTTP semantics. (5) Standard tooling fails. API testing tools, documentation generators, code generators all rely on HTTP method semantics. POX requires custom tooling. SOAP is the most common Level 0 protocol in enterprise systems. SOAP explicitly uses HTTP as a transport layer (not a semantic layer). This is by design for SOAP - it prioritizes protocol-neutral messaging over HTTP semantics."

*What separates good from great:* "The load balancer routing consequence (can't route reads to read replicas based on HTTP method if everything is POST) is a concrete infrastructure limitation of Level 0 that shows operational impact."

---

#### Q5 - "What level is the GitHub API and what does it get right or wrong?"
> "GitHub API analysis: GitHub's REST API is primarily Level 2 with selective Level 3 elements. What it gets right: correct HTTP methods and status codes. `GET /repos/{owner}/{repo}` for reads. `POST /repos/{owner}/{repo}/issues` for creates. `PATCH /repos/{owner}/{repo}/issues/{issue_number}` for partial updates. Correct status codes: 201 Created with Location header, 404 for not found, 422 for validation errors. Pagination: Level 3 element. Responses include `Link` header: `Link: <https://api.github.com/repos/...?page=2>; rel='next', <https://api.github.com/repos/...?page=34>; rel='last'`. Clients should follow the `next` link rather than constructing pagination URLs. This is HATEOAS for pagination. What it doesn't implement: full HATEOAS for non-pagination operations. Clients know that the create issue URL is `/repos/{owner}/{repo}/issues` from the documentation, not from following links. This is pragmatic: GitHub has thousands of API clients. Teaching all of them to follow links for every operation would be a massive ecosystem change with minimal benefit (URL stability guarantees serve the same purpose). The lesson: you can implement Level 3 selectively for the cases where it provides the most value (pagination, hypermedia navigation) without committing to full Level 3 everywhere."

*What separates good from great:* "Analyzing GitHub's actual API implementation (Level 2 with selective Level 3 pagination) and connecting the pragmatic choice to URL stability guarantees serving the same purpose as HATEOAS shows how theory meets production engineering."

---

#### Q6 - "How does idempotency relate to REST levels and HTTP methods?"
> "Idempotency in REST: idempotent means calling the operation multiple times has the same effect as calling it once. HTTP method idempotency contracts: GET: idempotent + safe (no side effects). Call 100 times, same result, no side effects. PUT: idempotent (not safe). `PUT /orders/123 {status: shipped}` called 100 times: order 123 is shipped. Same result. POST: NOT idempotent. `POST /orders {items: [...]}` called 100 times: creates 100 orders. Different result. DELETE: idempotent. `DELETE /orders/123` called twice: first call deletes the order (204), second call returns 404. Net effect: order is gone. Same outcome (order doesn't exist). Level 2 implication: using POST for updates (instead of PUT/PATCH) breaks idempotency expectations. Clients retry on timeout. `POST /orders/123` to update order 123 is not idempotent in HTTP semantics (even if your server implementation is idempotent). The client's retry logic assumes POST is not idempotent and may not retry. PUT/PATCH signal idempotency to clients, enabling safe retry. Idempotency keys for POST: when you must use POST (creates), use idempotency keys: `Idempotency-Key: uuid`. Server stores result by key. If key seen again: return stored result. Client can safely retry on timeout."

*What separates good from great:* "The idempotency key pattern for POST (enabling safe retry on timeout for creates) and the DELETE 404-on-second-call still being idempotent (the outcome is the same: resource doesn't exist) show production-informed REST semantics."

---

#### Q7 - "What does the RMM tell us about designing error responses?"
> "RMM and error responses: Level 2 requires status codes to carry the error semantics. The status code is the primary error signal. The body adds detail. Common Level 2 error response patterns: 400 Bad Request: malformed request syntax. 401 Unauthorized: no valid authentication credentials. 403 Forbidden: authenticated but not authorized for this resource. 404 Not Found: resource doesn't exist. 409 Conflict: state conflict (duplicate key, version mismatch). 422 Unprocessable Entity: valid syntax but semantic validation failed (invalid field value). 429 Too Many Requests: rate limit exceeded. 500 Internal Server Error: unexpected server failure. 503 Service Unavailable: server temporarily unavailable (maintenance, overload). The error body standard: RFC 7807 Problem Details for HTTP APIs. `Content-Type: application/problem+json` body: `{ 'type': 'https://api.myapp.com/errors/validation', 'title': 'Validation Failed', 'status': 422, 'detail': 'Email format is invalid', 'instance': '/orders/new-order-form' }`. This standardizes error bodies across APIs. Clients can parse any RFC 7807 error without API-specific error parsing code. The failure to implement correctly: `200 OK` with `{ 'error': 'not found', 'success': false }`. HTTP clients that check status codes will treat this as success. The distinction is not just aesthetic - it affects retry logic, logging, and monitoring."

*What separates good from great:* "RFC 7807 Problem Details as the standardized error response format and the monitoring implication (200 with error body bypasses error-rate monitoring that uses HTTP status codes) show production-complete Level 2 error handling."

---

#### Q8 - "How does the RMM apply to GraphQL and gRPC APIs?"
> "RMM and non-REST protocols: The RMM is specific to HTTP+REST. It doesn't directly apply to GraphQL or gRPC. But the underlying questions translate: (1) GraphQL: operates at Level 0 by RMM standards - all requests are POST to one endpoint (`/graphql`). HTTP semantics are not used. But GraphQL has its own maturity dimension: basic queries and mutations vs subscriptions vs persisted queries vs schema stitching. For GraphQL, caching requires workarounds (GET for queries with cache keys, persisted query IDs) because POST is not cacheable. Error handling: GraphQL returns 200 OK even for errors, with errors in the response body. This is intentional (partial success is possible) but loses HTTP error semantics. (2) gRPC: operates below the HTTP level (HTTP/2 transport, binary protocol). HTTP status codes are replaced by gRPC status codes. gRPC has its own maturity: basic unary calls vs server streaming vs bidirectional streaming. The RMM's underlying question applied to gRPC: are you using gRPC's features correctly? (proper status codes, backpressure in streaming, proper deadline propagation). The broader principle: every protocol has a correct way to use it. The RMM formalizes this for REST. Each protocol has an analogous maturity model."

*What separates good from great:* "GraphQL's Level 0 status by RMM (single POST endpoint) and the 200 OK for partial success (intentional design choice, not Level 1 anti-pattern) show the RMM's limits and the protocol-specific maturity dimensions."

---

#### Q9 - "What would your ideal API design review checklist look like, using the RMM?"
> "API design review checklist using RMM: Pre-review: declare the target level. Internal API or public developer API? Long-term contract or short-term? This determines if Level 3 elements are in scope. Level 2 checklist: Resources: are nouns used for resource URLs? (`/orders` not `/getOrders`). HTTP methods: GET for reads (safe, idempotent). POST for creates (non-idempotent). PUT/PATCH for updates (PUT = full replacement, PATCH = partial). DELETE for removes. Status codes: 201 + Location for creates. 200 for successful reads. 204 for successful deletes. 404 for not found. 409 for conflicts. 422 for validation errors. 400 for malformed syntax. Idempotency: PUT and DELETE idempotent? POST uses idempotency keys? Caching: GET responses have Cache-Control headers? Cache-Control: no-store for private data? Content negotiation: Accept and Content-Type headers supported? Error bodies: RFC 7807 Problem Details format? Optional Level 3 elements: pagination links in responses? Related resource links for navigation? Versioning: how are breaking changes communicated? The goal of the review: ensure the API uses HTTP correctly so standard tooling, caching infrastructure, and client retry logic work as expected. A well-designed Level 2 API is a force multiplier for every client that uses it."

*What separates good from great:* "The 'declare the target level before review' step (preventing theological debates about true REST) and the connection to standard tooling and retry logic are the practical benefits of systematic Level 2 implementation."

---
