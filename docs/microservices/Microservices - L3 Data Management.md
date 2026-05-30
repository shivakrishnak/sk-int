---
layout: default
title: "Microservices - L3 Data Management"
parent: "Microservices"
grand_parent: "SK Interview"
nav_order: 7
permalink: /microservices/l3-data-management/
render_with_liquid: false
---

# Distributed Data Management - Database per Service

---

### 🎯 Model Answer

**30 seconds:**
> Database per service means each microservice owns its own database schema and is the only service that can read from or write to it. Other services access the data through the owning service's API, not through direct database queries. This creates true data isolation - schema changes in one service don't break other services, and each service can choose the storage technology best suited to its data (relational, document, key-value, time-series).

**3 minutes:**
> A shared database is the most common microservices anti-pattern. When multiple services share a database: schema changes become cross-team coordination nightmares (changing a column requires notifying all teams that query it), one service's slow query affects all services, services become coupled through the database layer even if their APIs are separate, and it's impossible to independently scale or replace storage for different services. Database per service enforces boundaries: InventoryService owns the inventory schema. OrderService owns the order schema. If OrderService needs to know current inventory, it calls InventoryService's API - not the inventory table directly. The tradeoffs are real: queries that were simple JOINs across tables become API calls or eventual consistency via events. Reporting that JOINed five tables now requires data federation or a separate read model. These are not free. The design principle: each service is the source of truth for its bounded context's data. Data duplication across service boundaries is acceptable and expected - OrderService stores the product name and price at order time, even though ProductService is the source of truth, because the order is a point-in-time snapshot and must not change when product data changes. Understanding when data duplication is correct (immutable snapshot) vs wrong (stale copy of live data) is the key design skill.

**Blank Mind Recovery:**
**(1) Restate:** "Each service owns its own database. No direct cross-service database access."
**(2) Benefit:** "Schema isolation, independent technology choice, no shared coupling."
**(3) Challenge:** "Cross-service queries become API calls. JOIN queries require data federation or events."

---

### 📘 Concept Explanation

**What it is:**
Database per service is an architectural pattern where each microservice exclusively owns a database (or schema) and exposes data only through its API. No other service may query its database tables directly. This creates hard data boundaries aligned with service boundaries.

**Shared database vs database per service:**
```
SHARED DATABASE (anti-pattern):
  OrderService    -----+
  InventoryService ----+----> [Single Shared DB]
  ShippingService -----+

  OrderService queries inventory tables directly
  InventoryService can see order data
  Schema change in inventory table breaks OrderService
  One slow inventory query degrades OrderService

DATABASE PER SERVICE (correct):
  OrderService -> [Order DB]
  InventoryService -> [Inventory DB]
  ShippingService -> [Shipping DB]

  OrderService needs inventory: calls InventoryService API
  Services isolated: schema changes don't propagate
  Each DB can use best technology for its data
  Independent scaling: scale Inventory DB without
    affecting Order DB
```

**Data isolation patterns:**
```
TECHNOLOGY PER SERVICE:
  OrderService: PostgreSQL (complex queries, ACID)
  ProductCatalog: Elasticsearch (full-text search)
  SessionService: Redis (TTL, fast key-value)
  TimeseriesMetrics: InfluxDB (time-series queries)
  Recommendations: Neo4j (graph relationships)

  Each service uses the BEST storage for its data
  Not possible with a shared database

QUERY FEDERATION APPROACHES:
  1. API Composition: call multiple services,
     join results in memory
     - Works for: small result sets
     - Fails at: large result sets, complex joins

  2. CQRS Read Model: maintain a denormalized
     read model (Elasticsearch, ClickHouse) that
     combines data from multiple services
     - Works for: reporting, analytics, search
     - Cost: eventual consistency, additional store

  3. Event-driven denormalization: when service A
     changes data service B needs, B listens to
     A's events and maintains its own copy
     - Works for: frequent cross-service queries
     - Cost: data duplication, sync complexity
```

**Data ownership decisions:**
The most important design question for any piece of data: which service is its authoritative source? The source of truth service:
- Owns the schema and migrations
- Has the write path
- Publishes events on changes
- Other services query via API or subscribe to events

Other services may hold derived copies of this data but must treat the owning service as authoritative. Stale copies are acceptable; the owning service never reads from a copy.

**The key insight:**
Data duplication across service boundaries is not a bug - it is a feature. OrderService storing the product price at order time is correct because the price may change later and the historical order price must be preserved. The discipline: understand the difference between a snapshot (immutable, correct to duplicate) and a live reference (must query the source of truth service).

---

### 💻 Code Example

```java
// BAD: Direct cross-service database access
@Service
public class OrderService {
  // WRONG: OrderService directly queries
  // InventoryService's database tables
  @Autowired
  private InventoryRepository inventoryRepo;
  // InventoryRepository is from another team's codebase
  // - Now OrderService depends on InventoryService schema
  // - InventoryService cannot change schema without
  //   coordinating with OrderService team
  // - If InventoryService migrates to MongoDB,
  //   OrderService breaks

  public boolean canFulfillOrder(String productId,
      int qty) {
    // Direct SQL query against inventory DB
    Inventory inv = inventoryRepo
        .findByProductId(productId);
    return inv != null &&
        inv.getAvailableQuantity() >= qty;
  }
}
```

> **Code walkthrough:** OrderService directly instantiates and uses InventoryRepository, coupling it to the Inventory DB schema. Any schema migration in inventory tables must coordinate with the order team. InventoryService loses the ability to evolve independently. This is the shared-database anti-pattern even if the codebases are separate.

```java
// GOOD: Access via API (service boundary respected)
@Service
public class OrderService {
  private final InventoryServiceClient inventoryClient;

  public boolean canFulfillOrder(String productId,
      int qty) {
    // API call - respects service boundary
    return inventoryClient
        .checkAvailability(productId, qty);
  }
  
  @Transactional
  public Order createOrder(OrderRequest req) {
    // Reserve inventory via API
    ReservationResult reservation =
        inventoryClient.reserve(
            req.getProductId(), req.getQuantity());
    if (!reservation.isSuccessful()) {
      throw new InsufficientInventoryException();
    }
    
    // Store snapshot of product data at order time
    // NOT a live reference - correct to duplicate
    Order order = Order.builder()
        .orderId(UUID.randomUUID().toString())
        .productId(req.getProductId())
        // Store current price as snapshot:
        // if price changes, historical orders unchanged
        .priceAtOrderTime(reservation.getCurrentPrice())
        .productNameAtOrderTime(
            reservation.getProductName())
        .quantity(req.getQuantity())
        .build();
    
    return orderRepo.save(order);
  }
}
```

> **Code walkthrough:** OrderService calls InventoryService through a typed client (HTTP/gRPC). InventoryService's database schema is invisible to OrderService. The reservation call is transactional from InventoryService's perspective. The price and product name are stored as a snapshot in the order - this is correct data duplication, capturing point-in-time facts. If the product is renamed or repriced, historical orders show the correct historical data.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Database per service means each microservice has its own separate database and only it can access that database directly. If another service needs data, it has to call the owning service's API. This way, if one team changes their database schema, it doesn't break other teams. Each service can also choose the best database for their needs - like using Elasticsearch for search or Redis for caching."

**Senior / Staff:** "Database per service creates the right technical incentives. With a shared database, teams avoid schema migrations because they don't know who else is querying their tables. With database-per-service, the owning team can refactor freely because no one else accesses their tables directly. The real challenge is cross-service queries. Every JOIN that was 'free' in SQL now becomes an API call, an event subscription, or a read model. The design discipline: identify which cross-service data access patterns are frequent and performance-sensitive, and design the right mechanism for each (API for transactional, events + read model for analytics). Accept that some queries will be more expensive. This is the price of independent deployability."

---

### ⚠️ Common Misconceptions

**Misconception:** "Database per service means each service must have a completely separate database server."
Reality: In practice, different services often share the same database server (PostgreSQL cluster, for example) but have strictly separate schemas and access credentials. Service A's application user is granted access only to schema A. Service B's application user is granted access only to schema B. This provides logical isolation (correct schema separation, no cross-service queries possible through normal application code) without requiring separate database servers for each service in development. For production, dedicated database servers provide operational isolation (one service's load doesn't affect another), but this is a deployment decision separate from the architectural principle.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Distributed data inconsistency - services have conflicting views of shared business state**

Symptoms: An order shows as confirmed in OrderService but InventoryService shows inventory was never decremented. Customer support reports orders that exist without corresponding inventory reservations.

Root cause: OrderService created the order and then called InventoryService to decrement inventory. The InventoryService call failed silently (timeout, ignored exception) or the services are not participating in a consistent transaction.

Diagnosis: Compare order IDs in OrderService DB to reservation records in InventoryService. Identify gap: orders created in a time window with no corresponding inventory reservations. Check OrderService logs for the time window for InventoryService call failures.

Fix: Immediate: manually create inventory adjustments to reconcile the gap. Long-term: implement the saga pattern - if InventoryService call fails, OrderService must roll back the order creation (compensating transaction). Or use event-driven with the order in PENDING state until InventoryService confirms reservation.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Trade-off | 3 min | 2 |
| Scenario | 5 min | 1 |
| Anti-pattern | 3 min | 1 |
| Design | 3 min | 2 |
| Debugging | 2 min | 1 |
| Scale | 2 min | 1 |
| Misconception | 2 min | 1 |

#### Q1 - "A service needs data from two other services - how do you handle this without cross-service database joins?"
> "Three patterns: (1) API Composition: the aggregate service calls both services' APIs, fetches the data, joins in memory. Best for: small result sets where each API call returns few records. Fails at: if you need to aggregate 10,000 orders with their customer profiles - 10,000 API calls is not acceptable. (2) CQRS read model: an event-driven read model subscribes to both services' events and maintains a denormalized projection combining the data. Query the projection instead of the two services. Best for: frequent queries that need data from multiple services. (3) Data duplication: the querying service subscribes to events from the source service and maintains its own local copy of the needed fields. Best for: a small subset of fields needed very frequently. Tradeoff: eventual consistency in options 2 and 3."

*What separates good from great:* "The choice of pattern depends on query frequency, data freshness requirements, and data volume. For a user's dashboard (high frequency, all their own data, freshness important): API composition or a per-user CQRS projection. For an admin analytics dashboard (lower frequency, large dataset, freshness flexible): ClickHouse read model. For a frequently-queried field on every order (customer name at order time): data duplication (snapshot) in the order."

---

#### Q2 - "How do you handle database migrations in a database-per-service architecture?"
> "Each service owns its own migration scripts (Flyway, Liquibase). Migrations are applied on service deployment, autonomously, without coordinating with other teams. The discipline: backward-compatible migrations. Adding a column: backward compatible (old code ignores new columns). Renaming a column: not backward compatible. Migration strategy for renames: (1) add new column with new name, (2) deploy service that writes to both old and new columns, (3) migrate existing data to new column, (4) deploy service that reads from new column only, (5) drop old column. This expand-contract migration ensures no downtime and no coordination with other teams. Since no other service queries this table directly, migrations don't require cross-team coordination (a key benefit of database per service)."

*What separates good from great:* "Column rename in a shared database requires coordinating with every team that queries the table. In a database-per-service world, the same migration is a single team's internal concern. This is the independence dividend that makes teams faster. The organizational velocity improvement from database-per-service often exceeds the technical complexity cost."

---

#### Q3 - "Design data architecture for an e-commerce platform with 10 services."
> "Service data ownership: OrderService owns order state machine and line items. ProductService owns product catalog, descriptions, pricing rules. InventoryService owns stock levels and reservations. CustomerService owns profiles, addresses, payment methods. ShippingService owns carrier integrations, tracking. SearchService maintains an Elasticsearch index (read-only projection, updated via events). NotificationService owns notification preferences and delivery history. Cross-service data flow: ProductService publishes ProductUpdated events. SearchService updates its index. InventoryService subscribes to product IDs for new products. OrderService stores product snapshot at order time. CustomerService publishes CustomerDeleted events. OrderService, NotificationService, ShippingService each purge PII (GDPR). Reports: a ClickHouse data warehouse subscribes to all services' events for analytics."

*What separates good from great:* "The data warehouse receiving all services' events is a legitimate use of a shared store for reporting, not a violation of database-per-service. The key distinction: the data warehouse is read-only (no service writes through it). Services never query the data warehouse for business logic. It is a downstream projection, not an upstream shared database."

---

#### Q4 - "What is the N+1 problem in microservices and how do you solve it?"
> "N+1 in microservices: you need to display a list of 100 orders with customer names. For each order: call CustomerService to get the customer name. 100 orders = 100 API calls. N orders = N+1 API calls (1 to get order list + N for customer lookup). Solutions: (1) Batch API: design CustomerService to accept an API call with N customer IDs and return all N customers in one response. One API call regardless of N. (2) Include data in events: when OrderCreated event is published, include the customer name in the event payload. OrderService stores the name at order time (snapshot). No CustomerService call needed for display. (3) CQRS projection: maintain a combined order+customer projection. Pre-joined data available for fast list queries. The root cause: treating microservices like in-process objects (calling each one individually) instead of designing for the actual access patterns (bulk API endpoints, pre-computed joins)."

*What separates good from great:* "Bulk API design is a critical microservices skill. Every service that another service might need to query for lists should expose a bulk GET endpoint: GET /customers?ids=id1,id2,id3,...idN. This converts N+1 API calls into 2 API calls (get list + batch get). Retrofit this endpoint when N+1 is observed in production."

---

#### Q5 - "How do you handle data ownership boundaries when business requirements span multiple services?"
> "The challenge: a business requirement needs 'all orders for customers who joined in the last 30 days who haven't yet made a second purchase'. This query spans CustomerService (join date) and OrderService (order history). Options: (1) API composition in an aggregate service: get recent customers from CustomerService, get orders for each from OrderService. Expensive at scale. (2) Data warehouse: CustomerService and OrderService publish events to a data warehouse. The query runs against the warehouse. Not real-time but acceptable for analytics. (3) Question the service boundary: if this query is core to a business process, maybe these services are too granular. A CRM bounded context might own both customer profiles and order history for customer-centric queries. (4) Shared reporting database: services write to a shared read-only store for analytics only."

*What separates good from great:* "The data ownership decision should be driven by which queries the business actually needs to run. If multiple cross-service queries are consistently needed, the service boundaries may be wrong. Conway's Law: services that are always queried together are likely owned by the same team and can be a single service or bounded context."

---

#### Q6 - "How do you implement data lineage and audit trails in database-per-service?"
> "Each service maintains its own audit log. Standard pattern: every write operation records the audit event (entity changed, who changed it, what the old and new values were, timestamp). Options: (1) Application-level audit: service code explicitly writes to an audit table in the same transaction as the data change. Complete control, but code required in every write path. (2) Database triggers: database trigger on every table insert/update/delete writes to an audit table. No application code changes, but triggers have performance overhead and can be bypassed by direct SQL. (3) CDC (Debezium): captures all database changes from WAL. Complete audit trail with no application code or triggers. Published to a central audit Kafka topic. Cross-service audit: a central audit service subscribes to all services' Debezium topics. Aggregate audit trail across all services. Query: 'all changes to customer ID 123 across all services.'"

*What separates good from great:* "For compliance purposes, the audit trail must be tamper-evident. Application-level audit tables can be deleted by a DBA. Immutable audit: write audit events to write-once S3 (Object Lock) or to a append-only database. Signed audit events (HMAC with a service key) detect tampering even if the audit store is writable."

---

#### Q7 - "A new requirement needs data from a service that currently exposes no API for it. What is your process?"
> "Process: (1) Identify the data need. What exact fields are needed? For what use case? How frequently? (2) Request an API from the owning team. They own the data; they design the API. (3) If the owning team has high latency to implement: negotiate a temporary read access (documented, time-bounded). Document this as technical debt to be replaced by the proper API. Never make 'temporary' direct database access permanent. (4) If the use case is analytics, not transactional: request the team publish relevant events. Subscribe to events and build your own read model for your use case. (5) If the owning team is unavailable or unresponsive: escalate to architecture team. Service ownership boundaries must be enforced by the organization, not just convention."

*What separates good from great:* "The 'request an API from the owning team' step is where database-per-service governance lives. If teams can bypass this step by granting temporary direct database access that never gets removed, database-per-service erodes. Enforce: no service-to-service database access at the network level (VPCs, connection credentials), not just by convention."

---

#### Q8 - "How does database per service interact with data consistency requirements?"
> "Database per service exchanges synchronous consistency for autonomy. Within a service: full ACID consistency guaranteed (single database transaction). Across services: no distributed transactions. Patterns for cross-service consistency: (1) Two-phase commit (2PC): coordinated commit across services. Theoretical solution but practically fragile (coordinator failure leaves participants in uncertain state). Almost never used. (2) Saga pattern: sequence of local transactions with compensating transactions for failure cases. No distributed lock, eventual consistency. (3) Accept inconsistency: some cross-service inconsistency is acceptable (order shows as processing while inventory is still updating). Design the UX and business process to tolerate this. The question: what is the actual cost of temporary inconsistency for this specific use case? Often: lower than teams fear."

*What separates good from great:* "The consistency requirement analysis: distinguish between consistency that is legally required (financial records must be immediately consistent), operationally required (inventory reservation must be confirmed before accepting payment), and cosmetically required (dashboard counts may lag by seconds). Only the first two categories justify the complexity of synchronous consistency mechanisms. Cosmetic consistency requirements are routinely satisfied with eventual consistency."

---

#### Q9 - "At scale with 200 services, how do you manage data governance?"
> "Data governance challenges at scale: schema discovery (what tables/fields does each service own?), data lineage (where does this data come from, what has it touched?), PII tracking (which services hold customer PII?), compliance (GDPR deletion cascades across 200 services). Solutions: service catalog with data ownership annotations. Every service registers: what data it owns, what PII fields it holds, what schemas it publishes via events, what other services' data it depends on. Schema registry (Confluent Schema Registry or AWS Glue) for event schemas. All services register their event schemas. Changes tracked, backwards compatibility enforced. GDPR automation: CustomerDeleted event triggers automated PII deletion handlers in all services that registered PII dependency on customer data. Tested in staging: delete a test customer, verify all 200 services respond correctly."

*What separates good from great:* "At 200 services, manual data governance is impossible. The service catalog and schema registry must be automated: CI/CD pipeline verifies that all new data fields are annotated (PII or not-PII), all schema changes are backwards compatible, all services have a GDPR deletion handler registered. Governance by convention fails at scale; governance by enforcement (CI gates) succeeds."

---

### ⚖️ Comparison Table

| Pattern | Coupling | Query Flexibility | Consistency | Operational Cost |
|---|---|---|---|---|
| Shared Database | Tight | SQL JOINs (easy) | Strong | Low |
| Database per Service | Loose | API or events (complex) | Eventual | High |
| Database per Service + Read Model | Loose | Query-optimized | Eventual | Very High |
| Schema per Service (same server) | Medium | SQL JOINs blocked | Strong | Medium |

---

---

# Saga Pattern for Distributed Transactions

---

### 🎯 Model Answer

**30 seconds:**
> The saga pattern manages distributed transactions across multiple services by breaking them into a sequence of local transactions, each with a corresponding compensating transaction. If any step fails, the saga executes the compensating transactions for all previously completed steps to undo the work. This achieves eventual consistency without distributed locks or 2PC. Two implementations: choreography (services react to events and publish events) and orchestration (a central saga orchestrator sends commands and tracks state).

**3 minutes:**
> The problem: an e-commerce order requires: (1) check and reserve inventory, (2) charge payment, (3) create shipping record. Each is a separate service with its own database. No distributed transaction is available. If step 2 (payment) fails after step 1 (inventory reserved): the inventory reservation must be released. If step 3 (shipping) fails after steps 1 and 2: the payment must be refunded and inventory released. This is the saga. Each step has a corresponding compensation: inventory reservation is cancelled by a release-reservation step, payment charge is reversed by a refund step. The saga pattern ensures that either all steps complete successfully, or all previously completed steps are compensated. This gives ACD properties (Atomicity through compensation, Consistency through eventual, Durability through local transactions) but not I (Isolation) - other processes can see intermediate state. Choreography sagas: each service listens for events and publishes the next event in the flow. Decoupled but the full flow is distributed across multiple services with no single place to see it. Orchestration sagas: a saga orchestrator (a dedicated service or workflow engine like Temporal) sends commands to each service and tracks state. The full flow is visible in one place. For complex flows with multiple compensation paths: orchestration is more maintainable.

**Blank Mind Recovery:**
**(1) Restate:** "Distributed transaction via local transactions + compensating transactions for rollback."
**(2) Two styles:** "Choreography (event-driven, decoupled) vs Orchestration (central coordinator, visible)."
**(3) What it lacks:** "No isolation - other processes see intermediate state during the saga."

---

### 📘 Concept Explanation

**What it is:**
The saga pattern is a sequence of local database transactions where each local transaction updates the service's own database and publishes a message or event to trigger the next transaction. If a local transaction fails, the saga executes compensating transactions to undo all previous transactions.

**Saga flow (orchestration style):**
```
SAGA ORCHESTRATOR STATE MACHINE:

State: ORDER_PENDING
  -> Send: ReserveInventory to InventoryService
  
State: INVENTORY_RESERVED
  (on: InventoryReserved event)
  -> Send: ProcessPayment to PaymentService

State: PAYMENT_PROCESSED
  (on: PaymentProcessed event)
  -> Send: CreateShipment to ShippingService
  
State: COMPLETED
  (on: ShipmentCreated event)
  -> Order status = CONFIRMED

COMPENSATION PATHS:

PaymentFailed (from PAYMENT_PROCESSED):
  -> Send: ReleaseInventoryReservation
  -> Order status = CANCELLED

ShipmentFailed (from INVENTORY_RESERVED + PAYMENT):
  -> Send: RefundPayment
  -> Send: ReleaseInventoryReservation
  -> Order status = CANCELLED
```

**Choreography style:**
```
CHOREOGRAPHY (no central coordinator):

OrderService:
  creates order -> publishes OrderCreated

InventoryService:
  listens to OrderCreated
  reserves inventory
  publishes InventoryReserved OR InventoryFailed

PaymentService:
  listens to InventoryReserved
  processes payment
  publishes PaymentProcessed OR PaymentFailed

ShippingService:
  listens to PaymentProcessed
  creates shipment
  publishes ShipmentCreated OR ShipmentFailed

CompensationHandlers:
  OrderService: listens to *Failed events -> cancel order
  InventoryService: listens to PaymentFailed -> release
  PaymentService: listens to ShipmentFailed -> refund

PROBLEM: full flow is distributed across 4+ services,
hard to understand and debug
```

**The key insight:**
Sagas are compensating, not rolling back. A database transaction rolls back atomically (nothing is visible until committed). A saga rolls forward through compensation (intermediate state is visible to other transactions during the saga's execution). This is the ACD-without-I of saga transactions. Design compensating transactions carefully: they must succeed reliably (cannot fail), must be idempotent (may be called multiple times), and must address the business reality of undoing an action that may have already had side effects (an email was sent, a payment was initiated at a bank).

---

### 💻 Code Example

```java
// Orchestration saga with Temporal workflow
// (production-grade saga orchestration framework)
@WorkflowInterface
public interface OrderFulfillmentSaga {
  @WorkflowMethod
  OrderResult fulfillOrder(OrderRequest request);
}

@WorkflowImpl
public class OrderFulfillmentSagaImpl
    implements OrderFulfillmentSaga {

  private final InventoryActivities inventory;
  private final PaymentActivities payment;
  private final ShippingActivities shipping;

  @Override
  public OrderResult fulfillOrder(
      OrderRequest request) {
    // Step 1: reserve inventory
    ReservationId reservationId = null;
    try {
      reservationId = inventory.reserveStock(
          request.getProductId(),
          request.getQuantity());
    } catch (InventoryException e) {
      return OrderResult.failed("Insufficient stock");
    }

    // Step 2: process payment
    PaymentId paymentId = null;
    try {
      paymentId = payment.processPayment(
          request.getCustomerId(),
          request.getAmount());
    } catch (PaymentException e) {
      // Compensate: release inventory
      inventory.releaseReservation(reservationId);
      return OrderResult.failed("Payment failed");
    }

    // Step 3: create shipment
    try {
      ShipmentId shipmentId =
          shipping.createShipment(request);
      return OrderResult.success(shipmentId);
    } catch (ShippingException e) {
      // Compensate: refund payment AND release inventory
      payment.refund(paymentId);
      inventory.releaseReservation(reservationId);
      return OrderResult.failed("Shipping failed");
    }
  }
}
```

> **Code walkthrough:** Temporal workflow executes the saga with automatic durability: if the workflow process crashes mid-execution, Temporal replays from the last checkpoint. Each activity (inventory.reserveStock, payment.processPayment, etc.) is retried automatically on transient failures. Compensation is explicit: on PaymentException, we call releaseReservation. On ShippingException, we call both refund and releaseReservation. The compensation logic is clear and co-located with the saga flow.

```java
// Compensating transaction - idempotent design
@Component
public class InventoryActivitiesImpl
    implements InventoryActivities {

  @Override
  public void releaseReservation(
      ReservationId reservationId) {
    // Idempotent: calling twice is safe
    // First call: find reservation, mark released
    // Second call: find already-released, do nothing
    Reservation reservation =
        reservationRepo.findById(
            reservationId.getValue())
        .orElse(null);
    
    if (reservation == null) {
      // Already deleted or never existed
      // Log but do not throw - idempotent
      log.warn("Reservation not found: {}",
          reservationId);
      return;
    }
    
    if (reservation.getStatus() == RELEASED) {
      // Already compensated
      log.info("Reservation already released: {}",
          reservationId);
      return;
    }
    
    reservation.setStatus(RELEASED);
    reservation.setReleasedAt(Instant.now());
    reservationRepo.save(reservation);
    
    log.info("Released reservation: {}",
        reservationId);
  }
}
```

> **Code walkthrough:** The compensating transaction is idempotent by design. If Temporal retries the compensation (due to failure), calling releaseReservation twice produces the same result as calling it once. The pattern: check current state before applying the compensation. If already compensated: log and return without error. This is essential - compensation failures that re-throw will block the saga from completing its compensation path.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "The saga pattern is for when you need a transaction that spans multiple services, but you can't use a regular database transaction because each service has its own database. A saga breaks the transaction into smaller steps. If one step fails, the saga runs compensating actions to undo the steps that already completed. For example, if payment fails after inventory was reserved, the saga releases the inventory reservation."

**Senior / Staff:** "The saga pattern's critical design challenge is the compensating transactions. A saga compensation is not a rollback - it is a forward action that undoes a previous forward action. Email confirmations sent during the saga cannot be unsent. Payment authorizations may have already been captured. Compensation must address reality: the refund goes to the customer's payment method, a cancellation email is sent (not an unsend). Design compensating transactions with these questions: Can this compensation fail? It must be reliable (retry with backoff, idempotent). Can this compensation have already been applied? It must be idempotent. What business side effects need addressing beyond the data change? The hardest sagas to design are those with external side effects (email sent, bank notified) that cannot be reliably undone."

---

### ⚠️ Common Misconceptions

**Misconception:** "Saga transactions provide full ACID properties like a database transaction."
Reality: Sagas provide ACD (Atomicity through compensation, Consistency through eventual, Durability through local transactions) but NOT Isolation. During a saga's execution, intermediate state is visible to other transactions. Another process can see an order with inventory reserved but payment not yet processed. This is the fundamental difference from database transactions. Design for this: services must handle partially-completed saga state gracefully. An inventory query showing a reservation in PENDING state for 30 seconds is expected behavior, not a bug.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Saga compensation stuck - saga neither completes nor compensates**

Symptoms: Orders are stuck in COMPENSATING state in the saga orchestrator. Inventory reservations and payment records exist with no corresponding completed or cancelled order. Customer support reports orders in limbo.

Root cause: A compensating transaction is failing. releaseReservation or refund is throwing exceptions on every retry. Temporal or the saga orchestrator is stuck in a retry loop for the compensation step.

Diagnosis: Check saga orchestrator workflow state (Temporal Web UI, Cadence Web). Find all workflows in COMPENSATING or STUCK state. Check the activity history for the failing compensation step. Find the exception message in the activity task logs.

Fix: Fix the root cause of the compensating transaction failure (the service it's calling may be unavailable or the reservation ID may not exist anymore). If the compensation cannot be completed automatically: a saga orchestrator must have a FAILED COMPENSATION state that alerts a human operator for manual resolution. Never leave sagas in infinite retry loops for compensation failures.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Comparison | 3 min | 1 |
| Trade-off | 3 min | 2 |
| Scenario | 5 min | 1 |
| Debugging | 3 min | 1 |
| Design | 3 min | 2 |
| Scale | 2 min | 1 |
| Anti-pattern | 2 min | 1 |

#### Q1 - "What is the difference between choreography and orchestration sagas?"
> "Choreography: each service listens for events, reacts, and publishes the next event. No central coordinator. OrderService publishes OrderCreated. InventoryService listens, reserves, publishes InventoryReserved. PaymentService listens, charges, publishes PaymentProcessed. Benefits: fully decoupled, no central point of failure, each service is autonomous. Drawbacks: the full saga flow is distributed across N services - understanding the flow requires reading all N service codebases. Adding a new step requires modifying the last service in the chain to publish the new trigger event. Debugging a stuck saga requires checking events in each service. Orchestration: a central orchestrator (dedicated service or workflow engine) sends commands and listens for results. Benefits: the full flow is visible in one place, easy to add/modify steps, saga state is tracked centrally, debugging shows the full execution history. Drawbacks: the orchestrator is a central dependency, business logic centralized in one place rather than distributed."

*What separates good from great:* "For simple 2-3 step sagas: choreography is often simpler. For complex sagas with multiple failure paths, multiple compensation paths, and human approval steps: orchestration (Temporal, Camunda) is significantly more maintainable. The complexity of tracking saga state across a choreography grows quadratically with the number of steps."

---

#### Q2 - "How do you design an idempotent compensating transaction?"
> "Idempotency requirement: compensation may be called multiple times (network retry, process restart). Same result regardless of call count. Pattern for idempotent compensation: (1) Check current state before applying. If already compensated: return without error. (2) Use conditional update: UPDATE reservations SET status='released' WHERE id=? AND status='active'. If 0 rows updated: already compensated (status was already not 'active'). (3) Use idempotency key: include the saga ID in the compensation call. The compensated service stores (saga_id, compensation_type) as a unique key. Duplicate compensation rejected at the database constraint level. The principle: compensation is not 'undo the action', it is 'ensure the result is X, regardless of current state'. ReleaseReservation means 'ensure this reservation is in RELEASED state', not 'change this reservation from ACTIVE to RELEASED'."

*What separates good from great:* "External compensations (bank refunds, email sends) require different idempotency strategies. Bank refund APIs typically accept an idempotency key (UUID per refund attempt). Provide a stable key (saga_id + step_id). The bank returns the same result for the same key. Email 'cancellation' for a saga compensation: first cancellation sends email. Second call (retry): check if cancellation email already sent for this order ID, skip if yes."

---

#### Q3 - "A saga is stuck mid-execution. How do you diagnose and recover?"
> "Diagnosis: (1) Identify stuck workflows: in Temporal, query workflows by status=OPEN and age > expected completion time. (2) Inspect the workflow history: Temporal Web UI shows every activity call, result, and failure in the saga's execution. Find the step where the failure occurred. (3) Check the failing activity's logs: what exception is it throwing? Is it a transient error (network timeout) or permanent (business validation failed, data not found)? Recovery: (1) Transient failure: Temporal auto-retries with exponential backoff. If retrying for too long: may need manual intervention (increase timeout, fix infrastructure issue, then let Temporal retry). (2) Permanent failure: the activity needs a code fix. Deploy the fix, then either let Temporal retry (if the workflow is still retrying) or manually restart the workflow from the failed step. (3) Compensation stuck: compensation logic has a bug. Fix the compensating activity code. Deploy. Trigger manual retry of the compensation step."

*What separates good from great:* "Temporal provides workflow signal: send a signal to a stuck workflow to change its behavior (e.g., skip a step, use a different strategy) without redeployment. This is the emergency escape hatch for production incidents: signal the stuck workflow to take a compensating path manually."

---

#### Q4 - "Design a saga for booking a flight + hotel + car rental package."
> "Steps: (1) reserve flight (FlightService), (2) reserve hotel (HotelService), (3) reserve car (CarService). All three must succeed or all are cancelled. Orchestration approach: BookingOrchestrator. Step 1: FlightService.reserveFlight(). On failure: return error (nothing to compensate yet). On success: flightReservationId stored in saga state. Step 2: HotelService.reserveHotel(). On failure: compensate -> FlightService.cancelReservation(flightReservationId). Return error. On success: hotelReservationId stored. Step 3: CarService.reserveCar(). On failure: compensate -> HotelService.cancelReservation(hotelReservationId) AND FlightService.cancelReservation(flightReservationId). Return error. On success: package is complete. Confirm all three reservations simultaneously (or confirm each in sequence). Design issue: external reservation systems (airlines, hotels) may not support cancellation after confirmation. Saga step: hold reservation (not confirm) until all three succeed. Confirm all three only after all holds are successful."

*What separates good from great:* "The hold-then-confirm strategy (also called tentative-then-final) is the key insight for sagas involving external systems. Reserve at each step (no commitment, cancellable). Only confirm (commit) when all steps succeed. This limits the compensation problem: holding can be cancelled; confirmed reservations may require refund processes that are much more expensive."

---

#### Q5 - "Compare saga pattern to 2PC (two-phase commit)."
> "Two-Phase Commit (2PC): Phase 1 (prepare): coordinator asks all participants to prepare. Each participant locks resources and responds ready/abort. Phase 2 (commit or rollback): if all ready, coordinator sends commit to all. If any abort, sends rollback to all. 2PC gives ACID isolation but: requires all participants to hold locks during the entire transaction (blocking), coordinator failure leaves participants in uncertain locked state (blocking), all participants must be available simultaneously (tight temporal coupling). Saga: no locking, no coordinator blocking point, participants don't need simultaneous availability. Gives eventual consistency without isolation. Comparison: use 2PC when: all participants are on the same database server or support XA, the transaction is short, and isolation is required (traditional monolith with distributed databases, not microservices). Use saga when: services have separate databases, services may have different availability windows, you can tolerate temporary inconsistency."

*What separates good from great:* "In practice, 2PC is rarely used in microservices because most microservice databases don't support XA transactions (Kafka doesn't, many NoSQL databases don't). Even where 2PC is technically feasible, the coordination overhead and locking behavior is incompatible with high-availability distributed systems. Saga + eventual consistency is the pragmatic choice."

---

#### Q6 - "How do you test a saga implementation?"
> "Three levels: (1) Unit test compensating transactions in isolation: test that releaseReservation is idempotent (call twice, same result), test that it handles not-found gracefully. (2) Integration test the happy path: run the full saga with all services, verify all steps complete and state is consistent. (3) Chaos test failure scenarios: inject failures at each step (kill the service, inject exception, trigger timeout), verify the correct compensation steps execute, verify final state is consistent (no orphaned reservations or payments). Test each failure point: fail after step 1 (verify: no compensation needed), fail after step 2 (verify: step 1 compensated), fail after step 3 (verify: steps 1 and 2 compensated). Test duplicate event/command delivery: send each command twice, verify idempotency. In Temporal: use testkit for workflow testing that simulates time, signals, and failures."

*What separates good from great:* "Compensation testing is the most neglected part of saga testing. Teams test the happy path thoroughly but not the compensation paths. The compensation paths are where production incidents happen. Create a dedicated chaos test suite that runs against staging and injects failures at every saga step programmatically."

---

#### Q7 - "What is the dual-write problem in sagas and how do you solve it?"
> "Dual-write: a service updates its database AND publishes an event. If the database write succeeds but the event publish fails: the service's state is updated but downstream services never know. The saga state is corrupt (service believes step completed, saga doesn't know). Solutions: (1) Transactional outbox pattern: write the event to an outbox table in the same database transaction as the state update. A Debezium CDC or poller publishes from the outbox to Kafka. The event is only published if the database committed. (2) Event sourcing: the database IS the event log. The service writes events that are both the state change and the trigger for downstream processing. No dual write problem since there is only one write."

*What separates good from great:* "The dual-write problem is fundamental to all distributed systems, not just sagas. Every service that writes to a database and publishes an event has this problem. The transactional outbox is the most common solution. Recognizing that every service should use the outbox pattern (not just those participating in sagas) is the insight that prevents a class of production consistency bugs."

---

#### Q8 - "How does saga pattern scale at high transaction volume?"
> "Scaling saga orchestration: orchestrator is stateful but can be horizontally scaled with consistent hashing. Temporal clusters scale to thousands of workflows per second. Each workflow instance is independent - no shared state between concurrent sagas. Scaling compensation capacity: compensation activities (release inventory, refund payment) must scale to handle the compensation rate. If 1% of sagas compensate, and you process 10K sagas/second, compensation services need capacity for 100 compensation calls/second plus burst capacity. Event volume: at high volume, Kafka consumers for choreography sagas must keep up with event volume. Size partitions and consumers for peak event rate * peak compensation rate (e.g., all sagas failing simultaneously)."

*What separates good from great:* "Saga state durability is the scale concern often missed. Temporal persists workflow state to its backing database (Cassandra or PostgreSQL). At 10K concurrent sagas, that's 10K workflow history updates. The Temporal database becomes the throughput bottleneck. Size the Temporal cluster backing database for the concurrent workflow state write volume, not just the workflow count."

---

#### Q9 - "Design compensation for a saga where a confirmation email was sent mid-saga."
> "Email sent in step 2 (after inventory reserved, before payment). Payment fails. Must compensate. The email cannot be 'unsent.' Compensation options: (1) Send a cancellation email. This is the correct approach for most customer-facing communications. Design the email at step 2 to be implicitly provisional: 'Your order is being processed' rather than 'Your order is confirmed'. On compensation: send 'Your order could not be completed' email. (2) Delay the confirmation email until all saga steps succeed. The saga orchestrator sends the email only in the final step (or after the saga completes successfully). This avoids premature commitment in customer communication. Option 2 is better design: never communicate confirmation until the saga is genuinely complete. Only operational status updates ('processing', 'in review') are appropriate during saga execution."

*What separates good from great:* "The saga design principle: external side effects with high reversal cost (emails, SMS, third-party notifications) should happen only in the final saga step or after success confirmation. Any side effect that cannot be reliably reversed is a commitment that should only happen when the saga is certain to complete. Design the flow: all reversible steps first, irreversible commitments last."

---

### ⚖️ Comparison Table

| Pattern | Consistency | Isolation | Coupling | Failure Recovery |
|---|---|---|---|---|
| Saga (Choreography) | Eventual | None | Loose | Event-driven compensation |
| Saga (Orchestration) | Eventual | None | Medium (orchestrator) | Orchestrator tracks and compensates |
| 2PC | Strong | Full | Tight | Coordinator-managed rollback |
| Outbox + Event | Eventual | None | Loose | At-least-once delivery |
| Accept inconsistency | None | None | None | Manual reconciliation |
