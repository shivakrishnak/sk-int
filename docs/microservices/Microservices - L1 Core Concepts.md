---
layout: default
title: "Microservices - L1 Core Concepts"
parent: "Microservices"
nav_order: 2
permalink: /microservices/l1-core-concepts/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Service Decomposition Principles](#service-decomposition-principles) | medium |
| 2 | [Bounded Context and Domain-Driven Design Basics](#bounded-context-and-domain-driven-design-basics) | medium |
| 3 | [API Contract Design](#api-contract-design) | medium |

---

# Service Decomposition Principles

---

### 🎯 Model Answer

**30 seconds:**
> Service decomposition is the process of splitting a larger system into individual microservices. Good decomposition results in services with high cohesion (everything in a service belongs together) and loose coupling (services do not depend heavily on each other's internals). The primary decomposition strategies are: decompose by business capability (each service owns a vertical slice of business functionality) and decompose by subdomain using Domain-Driven Design (align services with bounded contexts identified by domain experts).

**3 minutes:**
> The hardest part of microservices is finding the right service boundaries. Too granular (nanoservices) and every business operation requires 10 network calls. Too coarse and you have distributed monoliths. The best decomposition principle: each service should be deployable independently and have a clear business capability. Domain-Driven Design provides the tooling: bounded contexts define the natural boundaries. A bounded context is a domain within which a model is internally consistent. Order management has its own model of a Product (line item at purchase price). Catalog management has its own model of a Product (current attributes, tags, images). These are different models of the same real-world concept - putting them in the same service would force one model to accommodate both concerns, creating complexity. The practical heuristic: if two components are always deployed together and always queried together, they belong in the same service. If they have different change rates, different teams, or different scaling requirements, they belong in separate services. The anti-pattern to avoid: decomposing by technical layer instead of business capability. A 'data layer service' and a 'logic layer service' creates technical coupling - any feature change touches both. Decompose vertically (all layers of one business capability in one service) not horizontally.

**Blank Mind Recovery:**
**(1) Restate:** "How do we split a system into the right-sized microservices?"
**(2) Principles:** "Business capability per service. Loose coupling. High cohesion. Independent deployability. Own your data."
**(3) Framework:** "Use DDD bounded contexts. Ask: does this service change for the same reasons as that one? If yes, same service. If different reasons, different service."

---

### 📘 Concept Explanation

**What it is:**
Service decomposition is the process of identifying the right boundaries for individual microservices. It applies principles from Domain-Driven Design (bounded contexts), software engineering (single responsibility, loose coupling), and organizational design (team ownership) to create a service map.

**Decomposition strategies:**

```
STRATEGY 1: BUSINESS CAPABILITY
  Each service = one business capability
  
  Business capabilities:
  - Order Management: place, track, cancel orders
  - Inventory Management: stock levels, reservations
  - Customer Management: profiles, preferences
  - Payment Processing: charges, refunds, disputes
  - Notification: email, SMS, push
  
  Each capability is cohesive - all related functions
  together. Each has its own data. Each team owns one.

STRATEGY 2: DOMAIN-DRIVEN DESIGN SUBDOMAIN
  Identify Core, Supporting, Generic subdomains
  
  Core: competitive differentiation
    (ProductRecommendations, FraudDetection)
  Supporting: necessary but not differentiating
    (OrderManagement, Inventory)
  Generic: commodity (UserAuth, Notifications)
  
  Prioritize microservice investment on Core subdomains.
  Generic can be SaaS (Auth0, SendGrid).

DECOMPOSE VERTICALLY (good):
  OrderService:
    - API layer (OrderController)
    - Business logic (OrderService)  
    - Data layer (OrderRepository)
    - Own database (orders_db)
  
DECOMPOSE HORIZONTALLY (bad - anti-pattern):
  APIGatewayService (all controllers)
  BusinessLogicService (all services)
  DataAccessService (all repositories)
  All share one database
  - Changing any feature touches all three services
```

> **Code walkthrough:** This Service Decomposition Principles example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Services should change for the same business reasons. If OrderController and OrderService always change together when an order feature changes, they belong in the same service. If OrderService and ShippingService never change for the same reason, they belong in separate services.

**Single Responsibility for services:**
Like the SOLID principle applied to services: a service should have one reason to change. If a service must be updated when order workflows change AND when payment processing rules change, it has two responsibilities and should be split.

---

### 💻 Code Example

```java
// BAD: Horizontally decomposed services
// CustomerService + OrderService share OrderData DTO
// Change in order schema forces change in CustomerService

// CustomerService code references Order internals
@Service
public class CustomerOrderSummary {
  // BAD: CustomerService knows about Order internals
  public List<OrderData> getCustomerOrders(
      String customerId) {
    // Direct DB access to orders table
    // CustomerService owns no orders data but
    // queries it directly - coupling!
    return orderRepository
        .findByCustomerId(customerId);
  }
}
```

> **Code walkthrough:** CustomerService directly accessing the orders table creates tight coupling. Any schema change to the orders table requires coordination with CustomerService. Deploying OrderService independently becomes impossible if the shared table structure changes.

```java
// GOOD: Vertically decomposed by business capability
// CustomerService calls OrderService API - no shared DB

// CustomerService calls OrderService via HTTP client
@FeignClient(name = "order-service")
public interface OrderServiceClient {
  @GetMapping("/api/v1/orders/by-customer/"
      + "{customerId}")
  List<OrderSummary> getOrdersForCustomer(
      @PathVariable String customerId);
}

// OrderSummary is OrderService's public contract
// CustomerService knows nothing about Order internals
// OrderService can change implementation freely
// as long as OrderSummary contract is maintained
@Service
public class CustomerProfileService {
  private final OrderServiceClient orderClient;

  public CustomerProfile getProfile(
      String customerId) {
    List<OrderSummary> orders =
        orderClient.getOrdersForCustomer(customerId);
    return new CustomerProfile(customerId, orders);
  }
}
```

> **Code walkthrough:** CustomerService depends only on OrderService's public API (OrderSummary). OrderService's database schema, internal logic, and implementation details are hidden. OrderService can be deployed independently. The Feign client defines the contract - a compile-time interface that documents the dependency explicitly.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Service decomposition means splitting an application into services that each do one thing. The main strategies are: decompose by business capability (each service handles one business function like orders or payments) or use domain-driven design where domain experts help identify the natural boundaries. The key rule is that each service should have its own database and communicate with others through APIs, not by directly accessing their data."

**Senior / Staff:** "The hardest question in service decomposition is not 'how do we split this' but 'is this the right time to split it'. Premature decomposition creates boundaries that are wrong and expensive to change. I use the heuristic: 'decompose when the cost of not decomposing exceeds the cost of decomposing.' The cost of not decomposing: two teams stepping on each other, deployment coordination friction, inability to scale one component without the other. When those costs are daily pain points, decompose. Use DDD bounded contexts to find where the boundaries should be - if the same concept (like 'Product') has a different meaning in two parts of the system, that is a clear boundary. If changing the shipping speed logic requires touching the same code as changing the payment gateway, that is a signal that two responsibilities are incorrectly combined."

---

### ⚠️ Common Misconceptions

**Misconception:** "Each microservice should be as small as possible - a few hundred lines of code."
Reality: Service size should be determined by business capability, not lines of code. A 10,000-line OrderService that owns all order lifecycle management is appropriately sized. A 100-line service that just validates email addresses is probably too granular - it can be a library function instead of a separate service. The operational overhead of a service (deployment, monitoring, health checks, service discovery) is constant regardless of size. Very small services multiply this overhead without proportional benefit.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Chatty microservices - simple operation requires 15 sequential inter-service calls**

Symptoms: A user-facing operation (load product page) takes 2-3 seconds even though each service responds in 100ms. Distributed trace shows 15 sequential hops across services.

Root cause: Services are too granular. Each service has one responsibility but that responsibility is too narrow. Loading a product page requires: ProductService, PriceService, InventoryService, ImageService, ReviewService... and they are called sequentially.

Diagnosis: Distributed trace the slow operation. Count the service hops. If more than 5-7 sequential hops for a single user operation, services are too granular.

Fix: Consolidate related services (ProductService absorbs PriceService and InventoryService for the product view use case). Use async parallel calls where sequential ordering is not required. Build a BFF (Backend For Frontend) that aggregates and caches data for specific client views.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Scenario | 5 min | 2 |
| Comparison | 2 min | 1 |
| Misconception | 2 min | 1 |

**[JUNIOR] Q1 - [MECHANISM] What is the single responsibility principle for microservices?**
> "A service should have one reason to change. In practice: a service should own one bounded context or business capability. If you find that a service must change when the order workflow changes AND when the payment gateway changes, it has two responsibilities. The key question when designing: 'What changes would require modifying this service?' If the answer covers two unrelated business domains, the service should be split. Amazon's internal framing: a service is owned by one two-pizza team. If two teams both need to modify the same service for different business reasons, split the service."

*What separates good from great:* "Single responsibility at the service level means accepting that the service will be larger than a single class. A ProductCatalogService with controllers, business logic, and repositories - potentially thousands of lines - has single responsibility if all that code changes for the same business reason (catalog management). Don't confuse code size with responsibility count."

---

**[JUNIOR] Q2 - [MECHANISM] How do you identify bounded contexts using event storming?**
> "Event storming is a workshop technique. Put domain experts and developers in a room with a large wall covered in paper. Start with 'domain events' (things that happened in the business past tense): OrderPlaced, PaymentProcessed, ItemShipped. Use orange sticky notes. Cluster events around the commands that cause them (blue stickies: PlaceOrder, ProcessPayment). Add aggregates (yellow stickies: Order aggregate, Payment aggregate). Policies that react to events (lilac stickies: when OrderPlaced, trigger FraudCheck). After mapping 2-3 hours of business events: look for natural clusters. Events and commands that deal with the same aggregate and belong to the same team form a bounded context. A wall with a dense Order cluster and a separate Shipment cluster with few connections between them suggests those are two bounded contexts - two potential services."

*What separates good from great:* "The value of event storming is not the map - it is the conversation. Domain experts disagree on terminology, reveal hidden business rules, and surface implicit workflows that developers never knew existed. The language disagreements are bounded context signals: if 'Order' means different things to the warehouse team and the finance team, that is a boundary."

---

**[MID] Q3 - [DESIGN] Design the service decomposition for an online learning platform.**
> "Identify business capabilities: User Management (registration, profiles, permissions), Course Catalog (browse, search, metadata), Enrollment (enroll, drop, track progress), Content Delivery (video streaming, slides, quizzes), Assessment (exams, grading, certificates), Notifications (email, in-app, reminders), Payments (subscriptions, one-time purchases, refunds). Each maps to a service with its own team and database. Why these boundaries: Course Catalog and Enrollment are separate because catalog changes (add a new course) and enrollment changes (user completes a course) happen for different reasons by different teams. Assessment is separate from Content Delivery because grading logic is complex and changes frequently, while content delivery is infrastructure-heavy. Payments is separate because it is a compliance-sensitive domain requiring different security controls and team expertise."

*What separates good from great:* "Before finalizing the decomposition, ask: which service pairs are most likely to be changed together? If Enrollment and Assessment are always co-deployed, maybe they should be one service. The deployment frequency alignment is a better boundary signal than the conceptual model."

---

**[MID] Q4 - [TRADE-OFF] What is the difference between decomposing by business capability vs by subdomain?**
> "Business capability decomposition: identify what the business does (not how or why) and create one service per capability. It is functional and relatively stable - 'order management' is a capability that survives even large technical changes. Subdomain decomposition (DDD): categorize subdomains as core (competitive advantage, invest here), supporting (necessary but generic), and generic (commodity, buy rather than build). More strategic - tells you where to invest engineering excellence vs where to use off-the-shelf solutions. In practice, they are complementary: use subdomain analysis to decide which services to build vs buy, then use capability analysis to define the boundaries of the services you build."

*What separates good from great:* "The key insight from subdomain analysis: generic subdomains should rarely be custom microservices. User authentication is a generic subdomain - use Auth0, Okta, or Cognito. Email notification is generic - use SendGrid or SES. Custom-building these as microservices is waste. Build only the core and supporting subdomains as custom services."

---

**[SENIOR] Q5 - [MECHANISM] How do you handle shared business logic that belongs in multiple services?**
> "Three options: (1) Duplicate it in both services if it is simple and unlikely to change - duplication avoids coupling. (2) Extract to a shared library if the logic is non-trivial and changes together. Risk: all consuming services must upgrade when the library changes, creating implicit coupling. Version the library carefully. (3) Create a separate service that exposes the logic as an API if the logic has its own lifecycle (changes for business reasons independent of consumers). The principle: prefer duplication over coupling for simple logic. Prefer a shared library for stable, domain-specific calculations. Prefer a service only when the logic has its own scaling requirements or business lifecycle."

*What separates good from great:* "Shared libraries are the hidden coupling mechanism in microservices. If OrderService, PaymentService, and ShippingService all depend on a shared 'domain-commons' library at version X, upgrading the library requires coordinating all three services. This is softer coupling than a shared database but it is still coupling. Audit shared library dependencies regularly; extract to a separate service if the library is changing frequently."

---

**[SENIOR] Q6 - [TRADE-OFF] What is domain event vs integration event and how do they relate to service decomposition?**
> "Domain event: something significant that happened within a bounded context. OrderService publishes OrderPlacedDomainEvent internally. Only OrderService consumers know about it. It carries all the context needed within the domain. Integration event: a deliberately designed event for cross-service communication. OrderService publishes OrderPlacedIntegrationEvent to Kafka for FulfillmentService and NotificationService. It is a public contract. Domain events are implementation details. Integration events are API surface area. The design discipline: convert domain events to integration events explicitly at the service boundary, rather than directly exposing internal domain events as the public contract. This lets you refactor internal domain events without breaking other services."

*What separates good from great:* "The translation layer between domain events and integration events is where you apply schema governance. A domain event can have 50 fields. The integration event exposes only what consumers actually need, following the interface segregation principle. Fewer fields in the integration event = fewer breaking changes as the internal domain evolves."

---

**[SENIOR] Q7 - [MECHANISM] What is the two-pizza team rule and how does it inform service sizing?**
> "Amazon's Jeff Bezos: if two pizzas can't feed the team, the team is too large. Applied to microservices: a single microservice should be ownable by a two-pizza team (5-8 engineers). This is not a technical rule - it is an organizational constraint. A service that requires 20 engineers to maintain and modify is likely a distributed monolith, not a microservice. The corollary: the number of microservices in an organization should roughly equal the number of two-pizza teams. A 100-engineer organization has roughly 12-15 two-pizza teams and should have roughly 12-15 primary service domains (though each team may own 2-3 services). This provides a reality check: if someone proposes 200 microservices for a 50-engineer organization, the ratio does not work - no team can own multiple services without operational strain."

*What separates good from great:* "The team-service alignment principle extends to on-call rotations. If a team cannot maintain on-call coverage for their services (meaning the services are too many or too complex for the team size), the services are over-decomposed relative to team capacity. Operational sustainability is as important as architectural cleanliness."

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


# Bounded Context and Domain-Driven Design Basics

---

### 🎯 Model Answer

**30 seconds:**
> A bounded context is a Domain-Driven Design (DDD) concept defining the boundary within which a domain model has a specific, consistent meaning. Inside a bounded context, terminology is precise and unambiguous. Across bounded context boundaries, the same word may mean different things. Bounded contexts map directly to microservice boundaries: one bounded context, one service (or one team that owns related contexts). The bounded context solves the model proliferation problem: without explicit boundaries, large systems develop contradictory models that confuse both the code and the team.

**3 minutes:**
> Domain-Driven Design provides the vocabulary for designing systems around business domains rather than technical layers. Three core concepts for microservices: bounded context (the boundary within which a domain model is consistent), ubiquitous language (the shared terminology between developers and domain experts within a context), and context map (the relationships between contexts - who provides what to whom). In practice: the same real-world entity can have different models in different contexts. An 'Account' in BankingContext is a balance, transactions, and compliance metadata. An 'Account' in CustomerContext is name, email, and preferences. These are different models. Forcing them into one 'Account' class creates complexity - the class must serve both contexts and evolves for different reasons. DDD says: keep them separate. The BankingContext defines its own Account. The CustomerContext defines its own Account. They communicate via context maps (well-defined integration interfaces). This maps directly to microservices: BankingService and CustomerService each maintain their own model. For microservices, DDD is not just theoretical - it is the most practical tool for finding good service boundaries.

**Blank Mind Recovery:**
**(1) Restate:** "Bounded context - where does one service's domain model end and another's begin?"
**(2) First principles:** "The same word means different things in different business contexts. 'Order' in the warehouse means a fulfillment task. 'Order' in finance means a revenue event. They are different models. Bounded context names this boundary."
**(3) Bridge:** "Like departments in a company. The Sales department and Finance department both talk about 'orders' but they track different attributes and have different rules. Bounded context = department boundary."

---

### 📘 Concept Explanation

**What it is:**
A bounded context is an explicit boundary within which a domain model is internally consistent and the ubiquitous language is precise. Everything inside the context has a specific meaning agreed upon by the team and domain experts. Outside the context, the same terms may mean different things.

**Context map - relationships between bounded contexts:**
```
CONTEXT MAP RELATIONSHIPS:

SHARED KERNEL:
  Two contexts share a small common model
  (e.g., shared Money type used by both
   OrderContext and PaymentContext)
  Risk: changes to kernel require coordinating
  both teams. Use sparingly.

CUSTOMER-SUPPLIER:
  SupplierContext produces; CustomerContext consumes
  Supplier defines the integration contract
  Customer adapts to supplier's model
  (e.g., OrderContext is customer to
   InventoryContext supplier for stock checks)

ANTICORRUPTION LAYER (ACL):
  Translates between two incompatible models
  so one context doesn't pollute another
  (e.g., LegacyERPContext -> ACL -> ModernOrderContext)
  ACL converts ERP's data structures into
  the modern context's model

OPEN HOST SERVICE:
  A context publishes a well-defined API
  for other contexts to consume
  (e.g., ProductCatalogContext exposes
   ProductSearchAPI used by many consumers)
```

> **Code walkthrough:** This Bounded Context and Domain-Driven Design Basics example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Ubiquitous language:**
```
WITHIN OrderContext:
  "Order" = customer's purchase intent
           + items + shipping address + status
  "Line Item" = product in order + quantity + price
  "Fulfillment" = physical preparation and shipping

WITHIN FulfillmentContext:
  "Order" = work order for warehouse team
           = pick list + packing instructions
  "Line Item" = physical item to be picked from shelf
  "Fulfillment" = the process of physical packaging

Same words, different models.
If both contexts share one class, the class
must serve contradictory requirements.
```

> **Code walkthrough:** This Bounded Context and Domain-Driven Design Basics example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Bounded contexts let you maintain multiple models of the same real-world concept without contradiction. You acknowledge that different parts of the business have legitimately different views of the same entity and model them separately rather than forcing a universal model.

---

### 💻 Code Example

```java
// BAD: One Order class forced to serve all contexts
// Results in a bloated class that changes for
// multiple different business reasons

@Entity
public class Order {
  // CustomerContext fields:
  private String customerId;
  private String shippingAddress;
  private List<LineItem> items;
  
  // WarehouseContext fields:
  private String warehouseBinLocation;
  private List<PickInstruction> pickList;
  private String packagingInstructions;
  
  // FinanceContext fields:
  private BigDecimal taxableAmount;
  private String vatRegistrationNumber;
  private String invoiceNumber;
  
  // All contexts must coordinate on schema changes
  // Testing this class requires knowledge of all
  // three domains - impossible to test in isolation
}
```

> **Code walkthrough:** A single Order class serving warehouse, customer, and finance contexts creates an omnibus object where any change to the warehouse's needs requires touching the same class as finance changes. Teams from different domains must coordinate on every modification. The class becomes a meeting point for organizational friction.

```java
// GOOD: Separate models per bounded context

// OrderContext - customer's perspective
// package: com.example.orders.domain
public class Order {
  private OrderId id;
  private CustomerId customerId;
  private List<OrderLineItem> items;
  private ShippingAddress shippingAddress;
  private OrderStatus status;
  // Methods are order lifecycle operations:
  // place(), cancel(), confirmPayment()
}

// FulfillmentContext - warehouse perspective
// package: com.example.fulfillment.domain
public class FulfillmentOrder {
  private FulfillmentId id;
  private OrderReference orderId; // just the ID
  private List<PickItem> pickList;
  private WarehouseLocation binLocation;
  private PackagingRequirement packaging;
  // Methods are warehouse operations:
  // startPicking(), packItems(), shipOut()
}

// Context boundary: FulfillmentService receives
// an OrderPlacedIntegrationEvent and creates its
// OWN FulfillmentOrder domain object.
// It does NOT use the OrderContext's Order class.
@EventHandler
public void on(OrderPlacedIntegrationEvent event) {
  FulfillmentOrder fo = FulfillmentOrder.create(
      event.getOrderId(),
      pickListFrom(event.getItems()));
  fulfillmentRepo.save(fo);
}
```

> **Code walkthrough:** Each context maintains its own model. OrderContext's Order has shipping address and customer ID. FulfillmentContext's FulfillmentOrder has bin locations and pick instructions. They share only the order ID as a cross-context reference. The FulfillmentService translates the integration event into its own domain object via the event handler - this is the anti-corruption layer pattern.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "A bounded context is a boundary where domain model terms have specific, agreed-upon meanings. Inside the boundary, everyone uses the same vocabulary. Outside the boundary, the same word might mean something different. For microservices, bounded contexts help us find where one service ends and another begins. A 'product' in the catalog service means the item for sale. The same 'product' in the order service means what the customer bought at a specific price."

**Senior / Staff:** "Bounded contexts are the most practical tool from DDD for microservices design. The key insight: inconsistency in terminology is not a miscommunication problem to be fixed - it is a signal that there are legitimate different models of the same concept. When the sales team and the warehouse team disagree on what an 'order' contains, that disagreement is a bounded context boundary. My process for finding bounded contexts: event storming workshop, then look for where the vocabulary breaks down (where people start qualifying terms: 'a warehouse order, not a customer order'), and draw the boundary there."

---

### ⚠️ Common Misconceptions

**Misconception:** "Bounded contexts should match database tables or microservice technical boundaries."
Reality: Bounded contexts are a modeling concept aligned with business domains, not technical artifacts. A single bounded context might need multiple database tables. Multiple bounded contexts might initially be in one service (a modular monolith) before being extracted. The bounded context defines where model consistency ends. The service boundary follows from the context, not the other way around.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Model pollution across contexts causes cascade refactoring**

Symptoms: When the catalog team changes the Product schema, the order team and warehouse team both need to update their code. Every schema change requires a multi-team coordination meeting.

Root cause: All services share a common ProductDto or Product class from a shared library. No anti-corruption layer exists. Context boundaries are absent.

Diagnosis: Search for cross-service import statements. If OrderService imports classes from catalog-service-model library, context pollution exists. Any change to that library cascades.

Fix: Introduce bounded context isolation. Each service defines its own model for external entities. Use integration events (not shared model classes) for cross-service communication. Add an anti-corruption layer in each service that translates integration events into the service's own domain model.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Scenario | 5 min | 2 |
| Misconception | 2 min | 1 |
| Application | 3 min | 1 |

**[JUNIOR] Q1 - [MECHANISM] What is the ubiquitous language and why does it matter for microservices?**
> "The ubiquitous language is the shared vocabulary between developers and domain experts within a bounded context. It is used in code (class names, method names, variable names), in team conversations, and in documentation. It is specific to its bounded context. 'Account' in a banking context means something different from 'Account' in an authentication context. Using the ubiquitous language in code means your classes and methods read like business language. If a domain expert reads your code and recognizes the vocabulary, the model is well-aligned with the domain. For microservices: the ubiquitous language defines the vocabulary of each service's API. A service that exposes OrderService.place() using vocabulary from its bounded context is well-designed. A service that exposes OrderService.insertRecord() uses technical vocabulary, not domain vocabulary - sign of misalignment."

*What separates good from great:* "The inverse: when developers invent their own vocabulary that does not match the domain, the code becomes a translation layer between developer terms and business terms. This translation tax increases over time as the domain evolves. Ubiquitous language eliminates the tax."

---

**[JUNIOR] Q2 - [MECHANISM] What is an anti-corruption layer and when do you need one?**
> "An anti-corruption layer (ACL) is a translation layer at the boundary between two contexts with incompatible models. Without an ACL, one context's model leaks into the other: the modern OrderService imports classes from the legacy ERP system and its code becomes polluted with ERP concepts. With an ACL: the ERP integration code is isolated in a single translator class. The ACL receives ERP's XML response and produces OrderContext's Order object. OrderService code only knows about its own model. Use an ACL when: integrating with legacy systems that have different modeling conventions, integrating with external vendor systems (Salesforce, SAP) whose models don't match your domain, or any time a context boundary crosses a significantly different model. The ACL is a design pattern, not a separate service - it is a class or package within the consuming service."

*What separates good from great:* "The ACL is most valuable when the external model changes independently. If the ERP vendor releases a new API version, only the ACL changes. The OrderService domain model is insulated. Without the ACL, an ERP API change requires updating every class in OrderService that uses ERP types."

---

**[MID] Q3 - [MECHANISM] How does a context map document service integration patterns?**
> "A context map is a diagram (and supporting documentation) that shows all bounded contexts and the relationships between them. For each pair of interacting contexts, it specifies: the relationship type (Customer-Supplier, Conformist, ACL, Shared Kernel, Open Host), the direction of influence (which context adapts to the other), and the integration mechanism (synchronous API, event stream, shared database - though the last should be rare). A context map reveals: which contexts are tightly coupled (Shared Kernel, Conformist) and which are well-isolated (ACL). It shows the power dynamics: a context conforming to an external system's model is a Conformist. If the external system is a vendor, you can't change its model. If it is an internal service, you might negotiate a better contract. The context map is a living document - update it as integration patterns change."

*What separates good from great:* "Context maps are most valuable for identifying architectural risk. A cluster of Conformist relationships around one internal service means that service is a dependency bottleneck - its model changes cascade to many consumers. This is the signal that the bottleneck service should publish a stable, versioned API rather than allowing direct model coupling."

---

**[MID] Q4 - [DESIGN] Apply DDD bounded contexts to design an e-commerce catalog and ordering system.**
> "ProductCatalogContext: manages products for browsing. Ubiquitous language: Product (title, description, images, category, tags), Category, SearchQuery, ProductVariant. Exposed via: ProductSearchAPI (Open Host Service). OrderContext: manages the purchase lifecycle. Ubiquitous language: Order, LineItem (product ID + price at purchase + quantity), Customer, ShippingAddress. Integration: when displaying an order, OrderContext needs product titles. It stores the product ID and name at purchase time (not a reference to the current catalog product - price and description can change). PricingContext: manages current prices, discounts, promotions. Ubiquitous language: Price, Discount, Promotion, PriceCalculation. Provides a PricingAPI for the OrderContext to get current prices at checkout. Context relationships: OrderContext is Customer to PricingContext Supplier. OrderContext integrates with ProductCatalogContext via ACL (to map catalog product IDs to stored line item data at order creation time)."

*What separates good from great:* "The critical design decision: OrderContext stores product names and prices at purchase time, not references to the current catalog. Prices change and products are discontinued. A historical order must reflect what the customer purchased at the time, not current catalog state. This decision is only visible if you explicitly define the OrderContext model."

---

**[SENIOR] Q5 - [TRADE-OFF] What is the difference between a bounded context and an aggregate?**
> "Different DDD concepts operating at different scopes. Bounded context: the macro-level boundary around a domain model. Applies to a service or a significant module. Inside a bounded context, terminology is consistent. Aggregate: a micro-level pattern within a bounded context. An aggregate is a cluster of domain objects (an Order with its LineItems) that are treated as a single unit for consistency. The Order aggregate root (Order) enforces invariants across all its LineItems. You always access LineItems through the Order, never directly. The aggregate root is the only entry point into the aggregate. A bounded context contains multiple aggregates. An Order bounded context might have Order aggregates and Discount aggregates."

*What separates good from great:* "Aggregates define transaction boundaries within a context. If an operation must update Order and LineItem atomically, they should be in the same aggregate. If two updates need to be eventually consistent (not atomic), they should be in different aggregates. Getting aggregate boundaries right is critical for performance - an aggregate with 1000 child entities is loaded from the database on every access. Design aggregates as small as possible while maintaining consistency."

---

**[SENIOR] Q6 - [MECHANISM] How does DDD apply when working with third-party APIs or external systems?**
> "External systems have their own models that do not match your domain. The DDD approach: always use an anti-corruption layer. Never let the external system's model classes leak into your domain. Practical example: integrating Stripe for payments. Stripe has its own model: PaymentIntent, Customer, PaymentMethod. Your domain has: Payment, Order, BillingProfile. The ACL translates: StripePaymentResult -> PaymentConfirmedEvent (your domain event). Your domain code never imports Stripe classes beyond the ACL. Benefits: if you switch payment providers, only the ACL changes. If Stripe changes its API version, only the ACL changes. If you want to test your Payment domain logic without Stripe, stub the ACL."

*What separates good from great:* "The ACL for external systems should be tested with integration tests (against the real API or a contract mock) while the domain logic is tested with unit tests against the ACL interface. This separation allows fast unit tests for business logic and slower integration tests for the external boundary."

---

**[SENIOR] Q7 - [SCENARIO] What is a shared kernel and when should you use it?**
> "A shared kernel is a deliberately shared subset of the domain model between two bounded contexts. Both contexts agree to keep the shared piece consistent. Example: a Money type (amount + currency) shared between OrderContext and PaymentContext. Both contexts need the same money semantics and agree not to change the Money type independently. Use it for: stable, foundational concepts that are semantically identical across contexts (date ranges, money, identifiers), and when the overhead of maintaining separate models exceeds the coupling cost. Avoid it for: large domain models, frequently changing models, or models where the semantic meaning differs slightly between contexts (even if they are called the same thing). The shared kernel creates a coordination requirement: any change to the kernel must be agreed upon by both teams. This is a form of coupling that should be conscious and deliberate."

*What separates good from great:* "The shared kernel should be versioned like a public library. Major versions for breaking changes, with a migration period where both the old and new versions are supported. Treating the shared kernel as just 'common code' leads to casual modifications that cascade to all consumers - the same problem as any shared mutable dependency."

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


# API Contract Design

---

### 🎯 Model Answer

**30 seconds:**
> API contracts are the explicit agreements between services: what endpoints exist, what request/response formats are expected, and what guarantees are provided. Good contract design follows three principles: consumer-driven (design for the actual needs of consumers, not the provider's internal model), versioned (breaking changes are introduced through new versions, not in-place modifications), and stable (once published, contracts are honored until explicitly deprecated).

**3 minutes:**
> API contracts in microservices are not just documentation - they are the primary integration mechanism and the source of coupling between services. A poorly designed contract couples producer implementation to consumers: if the contract exposes the provider's database schema, any schema change is a breaking change. A well-designed contract exposes only what consumers need (Postel's Law: be liberal in what you accept, conservative in what you send). Contract-first vs code-first: in contract-first design, the interface is defined (OpenAPI, Protobuf, AsyncAPI) before implementation. This forces you to design for consumers before writing a line of code. Consumer-driven contract testing (Pact) formalizes this: consumers define the interactions they expect from providers. Providers run tests against these expectations. If a provider change would break a consumer's expectation, the provider's tests fail. This prevents breaking changes from reaching consumers silently. REST vs gRPC vs messaging contracts: REST/OpenAPI is best for external-facing APIs and browser clients. gRPC/Protobuf is better for internal service-to-service calls (stronger typing, binary serialization, bi-directional streaming). AsyncAPI for event-based contracts (Kafka, AMQP). Choose the contract format that best serves the communication pattern.

**Blank Mind Recovery:**
**(1) Restate:** "API contracts - what services promise each other and how we manage those promises."
**(2) Principles:** "Consumer-driven, versioned, stable. Don't expose internals. Add fields freely, never remove them."
**(3) Framework:** "REST for external APIs. gRPC for internal service-to-service. Async/event for messaging. Test contracts with Pact or schema compatibility checks."

---

### 📘 Concept Explanation

**What it is:**
An API contract is the explicit specification of how two services interact: endpoints, request/response schemas, error codes, and behavioral guarantees. A contract is a boundary artifact - it belongs to the integration surface between services, not to either service's internals.

**Contract types:**
```
REST/HTTP CONTRACT (OpenAPI):
  GET /api/v1/orders/{orderId}
  Response 200:
    { "orderId": string, "status": string,
      "items": [...], "total": number }
  Response 404: { "error": "ORDER_NOT_FOUND" }
  Contract is public API surface.
  
GRPC CONTRACT (Protobuf):
  service OrderService {
    rpc GetOrder(GetOrderRequest)
        returns (OrderResponse);
  }
  message OrderResponse {
    string order_id = 1;
    string status = 2;
    repeated LineItem items = 3;
    int64 total_cents = 4;
  }
  
ASYNC CONTRACT (AsyncAPI):
  event: order.created.v1
  payload:
    orderId: string
    customerId: string
    items: array
  publisher: OrderService
  subscriber: [FulfillmentService, NotificationService]
```

> **Code walkthrough:** This API Contract Design example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Contract versioning strategies:**
```
URL VERSIONING (REST):
  /api/v1/orders   <- stable v1
  /api/v2/orders   <- new breaking contract
  Both run simultaneously during migration period
  Consumers migrate at their own pace
  
HEADER VERSIONING:
  Accept: application/vnd.company.v2+json
  Content-Type: application/vnd.company.v2+json
  More flexible; harder to discover
  
PROTOCOL BUFFER FIELD EVOLUTION:
  message OrderResponse {
    string order_id = 1;    // field 1 - stable
    string status = 2;      // field 2 - stable
    // New field added (backward compatible):
    string customer_name = 3; // consumers can ignore
    // NEVER: remove or change type of field 1 or 2
  }
  
KAFKA SCHEMA EVOLUTION:
  BACKWARD_TRANSITIVE compatibility:
  - Add optional fields: OK (old consumers ignore)
  - Remove required fields: BREAKING
  - Change field type: BREAKING
```

> **Code walkthrough:** This API Contract Design example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
A contract is a promise. Once you publish a contract and consumers depend on it, breaking it requires coordination with all consumers. Design contracts to be stable by hiding implementation details and exposing only what consumers need.

---

### 💻 Code Example

```java
// BAD: Contract exposes internal entity - leaks DB schema
// Any database schema change breaks the contract
@RestController
public class OrderController {
  @GetMapping("/orders/{id}")
  // PROBLEM: OrderEntity is a JPA entity
  // If DB column is renamed, contract breaks
  public OrderEntity getOrder(@PathVariable Long id) {
    return orderRepository.findById(id)
        .orElseThrow(NotFoundException::new);
  }
}
// @Entity class has: @Column(name = "cust_id")
// Rename column to "customer_id" = contract broken
// Database change = API breaking change
// Consumer must update to handle the new field name
```

> **Code walkthrough:** Returning a JPA entity directly from a controller creates tight coupling between the database schema and the API contract. A database refactoring (column rename) becomes an API breaking change that affects all consumers.

```java
// GOOD: Contract defined with separate response DTO
// Internal entity can change without breaking contract

// The public contract - only what consumers need
public record OrderResponse(
    String orderId,
    String status,
    List<LineItemResponse> items,
    MoneyResponse total
) {}

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {
  private final OrderService orderService;
  private final OrderResponseMapper mapper;

  @GetMapping("/{orderId}")
  @ResponseStatus(HttpStatus.OK)
  public OrderResponse getOrder(
      @PathVariable String orderId) {
    Order order = orderService.findById(orderId);
    return mapper.toResponse(order);
    // Mapper translates internal Order to public
    // OrderResponse. Internal changes don't break
    // the contract as long as mapper is updated.
  }
}

// New field: backward compatible addition
// (existing consumers can safely ignore it)
public record OrderResponse(
    String orderId,
    String status,
    List<LineItemResponse> items,
    MoneyResponse total,
    String trackingNumber  // new optional field - OK
) {}
```

> **Code walkthrough:** The response DTO is the contract artifact. It is separate from the internal entity and only exposes what consumers need. The mapper handles the translation. When the internal Order model changes (new fields, renamed attributes), only the mapper changes - the contract is stable. Adding optional fields to the response is backward-compatible; removing fields is breaking.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "API contracts define what requests a service accepts and what responses it returns. Good contract design means keeping the contract stable so consumers don't break when the service updates internally. Common practices: use versioned URLs (v1, v2) for breaking changes, never remove fields from responses, add new optional fields instead of changing existing ones, and return specific error codes so consumers can handle failures correctly."

**Senior / Staff:** "API contracts are the primary coupling mechanism in microservices. Every field you put in a contract is a commitment - it must remain there until you explicitly negotiate a breaking change with all consumers. The discipline I enforce: before adding a field to a response, ask 'do any consumers actually need this?' Unnecessary fields in contracts create false dependencies. Consumer-driven contract testing (Pact) formalizes this: consumers specify exactly which fields they need, and providers are tested against those specifications. This prevents providers from removing fields that consumers use and prevents providers from adding unnecessary fields that consumers might inadvertently depend on."

---

### ⚠️ Common Misconceptions

**Misconception:** "Adding new fields to a REST API response is always safe."
Reality: Adding optional fields is generally backward-compatible for JSON REST APIs. However, if consumers use strict deserialization (fail on unknown fields - a common setting in strict Jackson configurations), a new field in the response can cause consumer failures. Best practice: configure consumers to be liberal in what they accept (Jackson DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES = false). Then adding new fields is safely backward-compatible.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Silent contract breakage - consumer silently processing wrong data**

Symptoms: Order service is processing orders with $0 total price. No errors in logs. The bug appears after a recent OrderService deployment.

Root cause: OrderService changed the response field name from 'totalPrice' to 'total'. Consumers that accessed 'totalPrice' now get null (JSON field not found). If the consumer's deserialization does not fail on null, it processes zero values silently.

Diagnosis: Check the OrderService deploy log for schema changes. Check if any response fields were renamed or removed. Run consumer-driven contract tests if available.

Fix: Never rename fields - add the new field and deprecate the old one. Mark the old field as @Deprecated in documentation. Remove only after all consumers have migrated. Use Pact consumer-driven contract tests to catch this before deployment.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Scenario | 5 min | 2 |
| Comparison | 2 min | 1 |
| Debugging | 3 min | 1 |

**[JUNIOR] Q1 - [MECHANISM] What is consumer-driven contract testing (CDCT)?**
> "CDCT (commonly implemented with Pact) is a testing approach where consumers define the interactions they expect from providers. Workflow: the consumer team writes a Pact test that specifies: 'when I call GET /orders/123, I expect to receive a response with these specific fields.' The test generates a Pact file (a JSON contract). The provider team runs provider verification: they run the service against the Pact file and verify that their service actually returns what the consumer expects. If the provider team changes the response schema in a way that breaks the consumer's Pact contract, the provider verification tests fail - before deployment. This prevents breaking changes from reaching consumers."

*What separates good from great:* "CDCT flips the traditional testing model. Instead of providers testing what they think consumers need, consumers express what they actually use. Providers only need to fulfill what consumers actually test for. This avoids providers adding fields 'just in case' and encourages minimal, stable contracts."

---

**[JUNIOR] Q2 - [TRADE-OFF] Compare REST/OpenAPI vs gRPC/Protobuf for internal service contracts.**
> "REST/OpenAPI: human-readable, works with browsers, language-agnostic (JSON is everywhere), mature tooling for documentation and client generation. Downsides for internal use: JSON serialization is slower than binary, no native streaming, no built-in strong typing across languages. gRPC/Protobuf: binary serialization (3-10x faster than JSON), strongly typed with code generation in any language, native bi-directional streaming, built-in service definition. Downsides: not browser-native (requires gRPC-Web proxy), harder to debug (binary format), steeper learning curve. For internal service-to-service: gRPC is usually better when performance matters, services are in different languages, or streaming is needed. REST is fine for simpler cases or when the team already has REST expertise."

*What separates good from great:* "The type safety argument for gRPC is significant in large organizations. With REST/JSON, a field type change (string to int) may not cause a compile error but will cause a runtime deserialization error. With Protobuf, the generated code enforces types at compile time. For teams shipping rapidly across multiple services, this compile-time safety prevents a class of production incidents."

---

**[MID] Q3 - [MECHANISM] What is Postel's Law and how does it apply to API contracts?**
> "Postel's Law (robustness principle): 'Be liberal in what you accept, and conservative in what you send.' For API consumers: accept additional fields in responses without failing (ignore unknown fields). Accept old versions of request formats. For API providers: send only what is documented in the contract. Never send extra fields that consumers might accidentally depend on. Do not remove fields without explicit deprecation and migration. Applied practically: configure Jackson to ignore unknown fields by default. Validate outbound responses against a schema to ensure you are only sending contracted fields. This combination creates resilient integrations: providers can extend responses and consumers won't break."

*What separates good from great:* "Postel's Law has limits. Being 'liberal in what you accept' for security-sensitive fields can create vulnerabilities. API security: do not apply the liberal acceptance principle to authentication, authorization, or input validation. Validate and sanitize all inputs strictly regardless of Postel's Law."

---

**[MID] Q4 - [MECHANISM] How do you handle API versioning in a microservices system with 50 services?**
> "At 50 services, unmanaged versioning creates chaos: each service has its own versioning strategy, consumers don't know which version to use, and version proliferation creates maintenance debt. Standardized approach: all services follow the same versioning convention (URL versioning: /api/v1/, /api/v2/). Versioning is in the path, not headers - it is explicit and discoverable. Breaking changes always require a new version. A breaking change is: removing a field, changing a field's type, changing required fields, changing error codes that consumers handle. Adding optional fields is not a breaking change. Sunset timeline: a deprecated version is supported for a minimum of 6 months (or as specified in the deprecation notice). After sunset, the old version returns 410 Gone. API catalog: publish all service contracts to a central catalog (Confluence, Backstage) so consumers can find and monitor their dependencies."

*What separates good from great:* "Automate deprecation enforcement: add a custom HTTP response header (Deprecation: true, Sunset: Mon, 01 Jan 2025) to deprecated endpoints. Consumers can configure alerts when they receive a Deprecation header. This provides automatic visibility without requiring manual communication for every deprecated endpoint."

---

**[SENIOR] Q5 - [MECHANISM] What is the open/closed principle for API contracts?**
> "A well-designed API contract is open for extension but closed for modification. Open for extension: you can add new optional fields, new endpoints, new optional parameters. These additions do not break existing consumers. Closed for modification: you cannot change the meaning of existing fields, remove fields, or change required parameters without creating a new version. This is the same principle as the SOLID open/closed principle applied to APIs. A contract that is truly closed means existing consumers can depend on it forever without updates. Practical discipline: before releasing an API version, review it assuming it will exist for 3+ years. Is every field named well? Is the structure correct? Mistakes in v1 become permanent technical debt because v1 must be supported until all consumers migrate to v2."

*What separates good from great:* "The most expensive API mistakes: choosing a too-specific name ('orderCreatedAt' vs 'createdAt'), using integers for IDs (breaks when you need string IDs later), and mixing concerns in a response (returning shipping information in the order response, then needing to remove it for privacy compliance). Review contracts with security and domain experts before publishing."

---

**[SENIOR] Q6 - [MECHANISM] How do you document and discover APIs across 50 microservices?**
> "A service catalog is essential at this scale. Backstage (open-source by Spotify) is the most common choice: each service registers itself with metadata (owner, API contract location, dependencies, deployment status). API contracts (OpenAPI specs, AsyncAPI event schemas) are published to the catalog automatically from CI. Developers can browse the catalog to: find services that provide functionality they need, review the API contract before integrating, see who owns the service for questions, understand the service's dependencies for change impact analysis. The catalog reduces the 'who do I talk to about the order API?' friction and the 'does an API for this already exist?' discovery problem."

*What separates good from great:* "The catalog is only valuable if it is kept up to date. Automate: CI pipelines validate that every service has a registered catalog entry and a published OpenAPI spec. Break the build if the spec is out of date (compare spec to actual API using contract testing). Manual documentation goes stale. Automated, spec-driven documentation stays current."

---

**[SENIOR] Q7 - [DESIGN] What are the security considerations for API contract design?**
> "API contracts are attack surfaces. Security considerations: (1) Input validation: document and enforce input constraints in the contract (max lengths, allowed characters, enum values). Reject inputs that violate constraints with 400 Bad Request, not 500 Internal Server Error. (2) Response minimization: do not include sensitive fields (SSNs, full card numbers, passwords) in responses unless the consumer has a legitimate need. Each API version should return the minimum necessary data. (3) Authentication contracts: document auth requirements clearly. Is the endpoint public, internal-only, or role-scoped? (4) Rate limiting: contract should document rate limits and return 429 Too Many Requests with Retry-After header when exceeded. (5) Error responses: do not leak internal implementation details (stack traces, database error messages) in error responses. Return generic error codes for internal failures."

*What separates good from great:* "Treat your API contract as a security boundary. Every field in the request is a potential injection vector. Every field in the response is potential data disclosure. Design reviews for API contracts should include a security review as part of the contract approval process."

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



