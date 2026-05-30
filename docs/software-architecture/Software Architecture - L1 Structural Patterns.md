---
layout: default
title: "Software Architecture - L1 Structural Patterns"
parent: "Software Architecture"
grand_parent: "SK Interview"
nav_order: 4
permalink: /software-architecture/l1-structural-patterns/
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Hexagonal Architecture - Ports and Adapters](#hexagonal-architecture---ports-and-adapters) | critical |
| 2   | [Model-View-Controller](#model-view-controller) | high |
| 3   | [Component Design Principles](#component-design-principles) | high |

---

# Hexagonal Architecture - Ports and Adapters

🎯 Interview Weight: critical - appears in most senior/staff
architecture interviews; tests understanding of dependency inversion
and testable domain design.

---

### 🎯 Model Answer

**30 seconds:**
> Hexagonal Architecture (Ports and Adapters) organizes code so
> the domain (business logic) is at the center and knows nothing
> about infrastructure. Ports are interfaces that the domain defines.
> Adapters are implementations that connect ports to the real world
> (databases, HTTP, message queues). The domain never imports from
> infrastructure - infrastructure depends on the domain. This makes
> the domain purely testable and makes infrastructure swappable.

**3 minutes (Senior):**
> Hexagonal Architecture inverts the traditional layered dependency.
> In a layered architecture, the business layer depends on the data
> layer - the domain model uses JPA annotations, repository classes
> are imported into services. This ties the business logic to the
> database technology.
>
> Hexagonal Architecture flips this. The domain is at the center
> and depends on nothing. It defines Ports - interfaces that represent
> what the domain needs from the outside world: "I need to save an
> Order," "I need to send a notification." The domain does not care
> HOW these are done.
>
> Adapters implement the Ports for specific technologies: a
> `JpaOrderRepository` implements the `OrderRepository` port.
> An `EmailNotificationAdapter` implements the `NotificationPort`.
> The adapters depend on the domain (they implement its interfaces);
> the domain never depends on the adapters.
>
> This creates three critical properties. First: the domain is
> perfectly isolated and can be unit-tested without any
> infrastructure. Second: infrastructure is swappable - switch from
> MySQL to MongoDB by implementing a new adapter without touching
> the domain. Third: the same domain can be driven by multiple entry
> points - REST API, GraphQL, batch job, CLI - each implemented as
> an adapter.
>
> The "hexagon" name comes from the design: each face of the hexagon
> is a port. Some ports are "primary" (driving the domain - HTTP,
> CLI, tests), some are "secondary" (driven by the domain - database,
> email, external APIs).

*Adapting up:* Staff adds: "Hexagonal Architecture is the correct
foundation for Domain-Driven Design. The Bounded Context's domain
model stays pure. Clean Architecture (Uncle Bob) is Hexagonal
Architecture with named concentric rings and an explicit rule:
source code dependencies only point inward."

*Adapting down:* Junior: "Hexagonal Architecture puts your business
logic in the center. Everything else (database, web, external APIs)
is a plugin. The business logic defines what it needs via interfaces
(ports). Actual implementations (adapters) connect to real systems.
You can test the business logic without a real database."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Hexagonal Architecture -
let me explain the core idea of ports, adapters, and the dependency
inversion it achieves."

**(2) First principles:** "Business logic should not depend on
technology. The choice of database, web framework, or messaging
system should be changeable without rewriting the business logic.
Hexagonal Architecture achieves this by making technology depend
on business logic, not the other way around."

**(3) Bridge:** "Like a universal power adapter. Your device
(domain) has a specific power requirement (port interface). The
wall socket (database, HTTP, etc.) is different in each country.
The adapter converts the wall socket to what your device needs.
Your device works in any country without modification."

---

### 📘 Concept Explanation

**What it is:**
Hexagonal Architecture (also called Ports and Adapters, coined by
Alistair Cockburn) is an architecture pattern that isolates the
domain (business logic) from infrastructure and external systems
by inverting the dependency direction. The domain defines interfaces
(ports); infrastructure implements them (adapters).

**The problem it solves:**
In traditional layered architecture, the business layer depends on
the data access layer. When the database technology changes, the
domain model must change. When tests need a database to run business
logic tests, they are slow and fragile. Hexagonal Architecture
breaks this dependency so the domain is pure and independently
testable.

**How it works:**

```
HEXAGONAL ARCHITECTURE

         +--HTTP Adapter--+
         |  (driving)     |
         |  REST/GraphQL  |
         +-------+--------+
                 |
    Inbound Port (interface defined by domain)
                 |
         +-------v--------+
         |                |
  +----->+   DOMAIN       +------->
  |      |   (hexagon     |  Outbound Port
  |      |   core)        |  (interface defined by domain)
  |      |                |        |
  |      +----------------+        v
  |                         +------+----------+
  |                         |  JPA Adapter    |
  |                         |  (secondary)    |
  |                         |  implements     |
  |                         |  Repository Port|
  +--Test Adapter--+        +------+----------+
     (driving)              |   Database      |
     (replaces HTTP         +-----------------+
     in test context)

DEPENDENCY RULE:
  All arrows point INTO the domain.
  Domain depends on NOTHING external.
  Adapters depend on domain interfaces (ports).
```

**The key insight:**
The dependency inversion principle applied at architecture level.
In layered architecture: domain imports repository classes. In
Hexagonal: domain defines repository interfaces (ports), adapters
implement them. Dependency arrow reversed - now adapters depend on
the domain, not the domain on adapters.

**When to use it:**
When the domain is complex enough to justify isolation (rich business
logic, not CRUD). When testability of the domain is critical. When
infrastructure technologies are likely to change. When multiple
entry points (REST API + batch jobs + CLI) must drive the same domain.

**When NOT to use it:**
For simple CRUD systems, Hexagonal Architecture adds overhead without
benefit. A Rails-style MVC that directly maps HTTP requests to
database operations is simpler and faster for CRUD-heavy, low-domain
systems.

**Alternatives:**
- Clean Architecture (Uncle Bob): named concentric rings, explicit dependency rule
- Onion Architecture: similar to Hexagonal with layer names (Infrastructure, Domain Services, Domain Model)
- Traditional Layered: simpler, appropriate for CRUD-heavy systems

**First-principles derivation:**
The core insight: business logic changes when business rules change.
Infrastructure changes when technology changes. These are different
change rates from different change drivers. Hexagonal Architecture
separates them by requiring that the direction of dependency runs
from technology toward business logic, never the reverse. This
maximizes the ability to change each independently.

---

### 💻 Code Example

```java
// BAD: Traditional layered - domain depends on infrastructure
@Service
public class OrderService {
    // Direct dependency on JPA repository (infrastructure!)
    @Autowired
    private JpaOrderRepository orderRepository; // JPA class

    public void placeOrder(OrderRequest request) {
        // Domain logic mixed with JPA concerns
        OrderEntity entity = new OrderEntity(); // JPA entity
        entity.setStatus("PENDING");
        entity.setCustomerId(request.getCustomerId());
        // @Column, @Table annotations in "domain" model
        orderRepository.save(entity);
    }
}
// Problem: Can't test placeOrder() without a database.
// Problem: Switching from JPA to JDBC requires changing
// OrderService.
// Problem: OrderEntity carries @Entity, @Table, @Column
// (infrastructure concerns) in the domain model.
```

> **Code walkthrough:** The traditional layered approach has the
> domain service importing `JpaOrderRepository` - a JPA-specific
> class with framework annotations. The domain model (`OrderEntity`)
> is polluted with `@Entity` and `@Column` annotations that are
> infrastructure concerns. Unit testing `placeOrder()` requires
> setting up a JPA context. Switching to MongoDB means changing
> `OrderService` - a domain class should not change when the
> database technology changes.

```java
// GOOD: Hexagonal Architecture

// --- DOMAIN LAYER (depends on nothing) ---

// Domain entity (no framework annotations)
public class Order {
    private final OrderId id;
    private final CustomerId customerId;
    private OrderStatus status;

    // Domain behavior (not just getters/setters)
    public void place() {
        if (this.status != OrderStatus.DRAFT) {
            throw new OrderAlreadyPlacedException(id);
        }
        this.status = OrderStatus.PENDING;
    }
}

// OUTBOUND PORT: domain defines what it needs from storage
// (infrastructure will implement this)
public interface OrderRepository {
    void save(Order order);
    Optional<Order> findById(OrderId id);
}

// OUTBOUND PORT: domain defines what it needs from notifications
public interface OrderNotifier {
    void notifyPlaced(Order order);
}

// APPLICATION SERVICE: orchestrates domain and ports
public class OrderApplicationService {
    private final OrderRepository orderRepository;
    private final OrderNotifier orderNotifier;

    // Constructor injection - works with any implementation
    public OrderApplicationService(
        OrderRepository orderRepository,
        OrderNotifier orderNotifier
    ) {
        this.orderRepository = orderRepository;
        this.orderNotifier = orderNotifier;
    }

    public void placeOrder(PlaceOrderCommand cmd) {
        Order order = new Order(
            OrderId.generate(),
            cmd.getCustomerId()
        );
        order.place(); // domain logic here
        orderRepository.save(order);
        orderNotifier.notifyPlaced(order);
    }
}

// --- INFRASTRUCTURE ADAPTERS (depend on domain ports) ---

// Secondary adapter: JPA implementation of domain port
@Repository
public class JpaOrderRepository implements OrderRepository {
    private final JpaOrderJpaRepository jpaRepo;

    @Override
    public void save(Order order) {
        // Map domain Order -> JPA entity
        OrderJpaEntity entity = OrderMapper.toJpa(order);
        jpaRepo.save(entity);
    }

    @Override
    public Optional<Order> findById(OrderId id) {
        return jpaRepo.findById(id.value())
            .map(OrderMapper::toDomain);
    }
}

// Primary adapter: HTTP entry point
@RestController
public class OrderController {
    private final OrderApplicationService appService;

    @PostMapping("/orders")
    public ResponseEntity<Void> placeOrder(
        @RequestBody PlaceOrderRequest request
    ) {
        appService.placeOrder(
            new PlaceOrderCommand(request.getCustomerId())
        );
        return ResponseEntity.ok().build();
    }
}
```

> **Code walkthrough:** The domain layer (`Order`, `OrderRepository`,
> `OrderNotifier`) has zero infrastructure imports. `Order` is a
> pure Java class with business behavior. `OrderRepository` is an
> interface defined by the domain - it says "I need to save orders"
> without specifying how. `JpaOrderRepository` implements this
> interface and contains all JPA concerns. To test `placeOrder()`
> in `OrderApplicationService`: create an in-memory `OrderRepository`
> implementation and pass it. No Spring context, no database, tests
> run in milliseconds. To switch from JPA to MongoDB: write a new
> `MongoOrderRepository` without touching the domain.

```java
// TESTING: domain tested without any infrastructure
class OrderApplicationServiceTest {
    // In-memory adapter (test double, not mock)
    private final OrderRepository inMemoryRepo =
        new InMemoryOrderRepository();

    private final List<Order> notifiedOrders = new ArrayList<>();
    private final OrderNotifier captureNotifier =
        order -> notifiedOrders.add(order);

    private final OrderApplicationService service =
        new OrderApplicationService(
            inMemoryRepo,
            captureNotifier
        );

    @Test
    void placingOrderTransitionsStatusToPending() {
        service.placeOrder(
            new PlaceOrderCommand(CustomerId.of("cust-1"))
        );

        Order saved = inMemoryRepo.findAll().get(0);
        assertThat(saved.getStatus())
            .isEqualTo(OrderStatus.PENDING);
        assertThat(notifiedOrders).hasSize(1);
    }
}
// No Spring, no JPA, no database.
// Tests run in < 10ms.
// Tests verify domain behavior, not infrastructure wiring.
```

> **Code walkthrough:** The test uses an `InMemoryOrderRepository`
> (a simple `HashMap`-backed implementation of the port interface)
> and a lambda `captureNotifier` that records notified orders. No
> `@SpringBootTest`, no `@Mock`, no `@Autowired`. The domain behavior
> is verified by calling the application service and asserting on
> the in-memory state. This is the key payoff of Hexagonal Architecture:
> the domain behavior is fully exercisable without infrastructure.
> Adding a real integration test (JPA + database) is separate from
> testing the domain logic.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Hexagonal Architecture puts business logic in the center and treats
> everything else (database, HTTP, external APIs) as a plugin.
> The business logic defines interfaces (ports) that describe what
> it needs: "I need to save an order." Actual database code
> (adapters) implements those interfaces. The result: business logic
> can be tested with a simple in-memory implementation, no database
> needed. Switching databases means writing a new adapter, not
> changing any business logic.

*Push deeper:* Explain the dependency arrow direction. In layered
architecture, the service depends on the repository class. In
Hexagonal, the service depends on the repository interface (port),
and the JPA repository depends on that interface. The arrow is
reversed.

---

**Senior / Staff (5+ years):**
> Hexagonal Architecture is the correct structural pattern when
> the domain is complex enough to justify isolation. The domain
> defines ports - it says "I need to persist orders" via an interface
> - and adapters implement those ports for specific technologies.
> The dependency rule is absolute: domain never imports infrastructure.
>
> I apply Hexagonal Architecture for three concrete benefits. First,
> pure domain testing: all domain logic tests are unit tests with
> in-memory adapters. The test suite for the entire domain logic
> runs in seconds. Second, infrastructure swapability: I have swapped
> database technologies (MySQL to PostgreSQL, then to a read replica
> strategy) without touching any domain code. Third, multiple entry
> points: the same domain is driven by REST, GraphQL, and a batch
> job, each as a separate primary adapter.
>
> The cost: more code per feature (domain model, port interface,
> adapter implementation, mapper). Justified when domain complexity
> and infrastructure uncertainty are both high. Not justified for
> simple CRUD.

*Push deeper:* Staff angle: "Hexagonal Architecture is the foundation
for Domain-Driven Design. The Bounded Context's core domain model
is the hexagon's interior. Ports map to the domain's external
contracts. Anti-Corruption Layers between Bounded Contexts are
implemented as adapters that translate between contexts."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Hexagonal and Clean Architecture are the same | Clean Architecture is Robert Martin's named extension of Hexagonal, adding explicit concentric ring names and the Entities/Use Cases/Interface Adapters/Frameworks distinction |
| Ports are the interfaces, adapters are the implementations | Ports are the interfaces defined BY the domain; adapters are the implementations of ports FOR specific technologies. Primary adapters (HTTP controllers) drive the domain; secondary adapters (databases) are driven by the domain |
| You need a hexagonal architecture for every project | Hexagonal is justified for complex domains with real business logic; CRUD systems benefit more from simplicity than from port/adapter isolation |
| The domain can depend on frameworks for convenience | The domain must be completely framework-free; putting Spring annotations in domain classes defeats the purpose of hexagonal isolation |
| All code in the "domain" folder is domain code | Infrastructure concerns (JPA mappers, email formatters) in the domain package are architecture violations even if they are in the right folder |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Leaking infrastructure into the domain**

*Symptom:* Domain entities have `@Entity`, `@Column`, `@JsonProperty`
annotations. The `Order` class imports from `javax.persistence` or
`org.springframework`. The domain is tightly coupled to frameworks.

*Root cause:* Using the JPA entity as the domain model - the most
common shortcut that destroys Hexagonal Architecture.

*Diagnostic:*
```bash
# Find framework imports in domain package
grep -r "javax.persistence\|org.springframework\|com.fasterxml" \
  src/main/java/com/example/domain/
# Any hits = domain is leaking infrastructure
```

*Fix:* Separate domain model from JPA entity. The domain `Order`
class has no annotations. The `OrderJpaEntity` class has `@Entity`
and maps the JPA model. `OrderMapper` converts between them.

*Prevention:* ArchUnit rule: no class in `..domain..` may import
from `org.springframework`, `javax.persistence`, or
`com.fasterxml.jackson`.

**Failure 2: Port defined by the wrong layer**

*Symptom:* The database schema drives the domain model. The
`OrderRepository` interface has methods like `findByStatusAndCreatedAt
AfterAndCustomerIdIn(status, date, ids)` - methods that expose
database query patterns, not domain concepts.

*Root cause:* The port interface was designed by the adapter
(database team) rather than by the domain. It exposes infrastructure
leaking into port design.

*Diagnostic:*
```
- Do repository port methods have parameter names that
  sound like SQL (IN, BETWEEN, AFTER)?
- Do port methods return infrastructure types (Pageable,
  Sort, JPA Specification)?
- Are port methods named for database operations rather
  than domain concepts?
```

*Fix:* Redefine ports from the domain's perspective. The domain
says `findOrdersReadyForFulfillment()`. The adapter figures out
the SQL needed to implement this domain concept.

*Prevention:* Port interfaces should be designed by the domain
engineer, not the database engineer. Port method names should use
domain ubiquitous language.

**Failure 3: Thick adapters (business logic in adapters)**

*Symptom:* The `JpaOrderRepository` adapter contains business logic
(eligibility checks, pricing calculations, status transitions).
Changing the business rule requires finding and updating code in
the adapter.

*Root cause:* Business logic migrated to the adapter for
"convenience" (already have the database connection).

*Diagnostic:*
```
- Do adapter classes have if/else logic beyond mapping
  and error handling?
- Are there business rule calculations in repository
  implementations?
- Do adapters import domain services?
```

*Fix:* Move any business logic found in adapters back to the domain.
Adapters should contain: mapping, error translation, and
infrastructure-specific concerns only. No business logic.

*Prevention:* Adapter code review checklist: "Does this adapter
code contain if/else logic? If yes, is it infrastructure logic
(retry, circuit breaker) or business logic (eligibility rules)?
Business logic belongs in the domain."

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | Dependency inversion, ports vs adapters, testability |
| Seniority signal | Junior: knows the concept; Senior: implements correctly; Staff: relates to DDD |
| Common trap | Confusing Hexagonal with Clean Architecture or with just "using interfaces" |
| Staff differentiator | Anti-Corruption Layer as adapter pattern in DDD Bounded Contexts |

---

**Q1 [JUNIOR]: What is the difference between a port and an adapter
in Hexagonal Architecture?**

*Why they ask:* Tests whether the candidate understands the
fundamental building blocks, not just the high-level concept.

*Likely follow-up:* "Which layer defines the port interface?"

A port is an interface. It represents a boundary of the domain -
either how the domain is driven (primary/inbound port: a use case
interface like `PlaceOrderUseCase`) or how the domain reaches out
to infrastructure (secondary/outbound port: `OrderRepository`,
`NotificationService`).

Critically: ports are defined BY the domain, not by the
infrastructure. The domain says "I need to be able to save an order"
via the `OrderRepository` interface. The domain does not know or
care whether that is JPA, MongoDB, or an in-memory HashMap.

An adapter is an implementation of a port for a specific technology.
`JpaOrderRepository` implements `OrderRepository` using JPA.
`RestOrderController` implements the primary port by handling HTTP
and delegating to the application service.

The dependency direction: adapters depend on ports (domain interfaces).
The domain never imports adapters.

*What separates good from great:* Most candidates say "port = interface,
adapter = implementation." Great candidates explain which layer DEFINES
the port (the domain, not the infrastructure) and give the full
dependency direction: adapters import domain types, domain never
imports adapter types.

---

**Q2 [MID]: How do you test domain logic in Hexagonal Architecture
without a database?**

*Why they ask:* Tests whether the candidate understands the testability
benefit and can operationalize it.

*Likely follow-up:* "Show me what the test looks like."

In Hexagonal Architecture, domain logic is tested by replacing
secondary adapters (database, email) with test doubles that implement
the same port interfaces. No Spring context, no database, no mocking
framework needed.

The test setup:

1. Define an `InMemoryOrderRepository` that implements `OrderRepository`
   using a `HashMap`. This is a test adapter - a real implementation
   of the port, but backed by memory instead of a database.

2. Inject it into the application service via constructor injection.

3. Test the domain behavior by asserting on the in-memory state.

```java
@Test
void placeOrder_creates_pending_order() {
    InMemoryOrderRepository repo =
        new InMemoryOrderRepository();
    OrderApplicationService service =
        new OrderApplicationService(repo, email -> {});

    service.placeOrder(new PlaceOrderCommand("cust-1"));

    assertThat(repo.findAll())
        .extracting(Order::getStatus)
        .containsOnly(OrderStatus.PENDING);
}
```

No `@SpringBootTest`. No Mockito. No database. Runs in under 10ms.
The domain behavior is fully tested without infrastructure.

*What separates good from great:* Most candidates say "use Mockito
to mock the repository." Great candidates describe the InMemory
adapter approach - a real implementation of the port that uses
memory instead of a database. This is cleaner than Mockito mocks
because it is a proper implementation, not a stub that may not
honor the contract.

---

**Q3 [SENIOR]: What is the difference between Hexagonal Architecture
and Clean Architecture?**

*Why they ask:* Tests architectural breadth. Many candidates conflate
the two. Precise distinction is a senior signal.

*Likely follow-up:* "Which would you choose and why?"

Hexagonal Architecture (Alistair Cockburn, 2005) introduced the
core concept: domain at the center, ports (interfaces), adapters
(implementations), dependency inversion rule.

Clean Architecture (Robert Martin, 2012) extends Hexagonal with:
- Named concentric rings: Entities (enterprise business rules),
  Use Cases (application business rules), Interface Adapters
  (controllers, presenters, gateways), Frameworks and Drivers
  (web, database, external interfaces)
- Explicit Dependency Rule: source code dependencies only point
  inward toward Entities
- Distinction between Entities (core domain rules) and Use Cases
  (application-specific workflows)

In practice: Clean Architecture gives more naming discipline.
"Hexagonal Architecture" developers sometimes put application
workflows in the domain model; Clean Architecture explicitly separates
them (Entities vs Use Cases). If you are building a new system and
want a framework for naming conventions, Clean Architecture provides
more guidance. If you are explaining the core concept, Hexagonal
Architecture is simpler.

I use "Hexagonal Architecture" as the concept and "Clean Architecture"
as the implementation guide when I want named conventions for
where specific types of code belong.

*What separates good from great:* Most candidates say they are "the
same thing." Great candidates give the specific additions in Clean
Architecture (named rings, Entities vs Use Cases distinction) and
describe when the naming guidance of Clean Architecture is worth
the additional conceptual overhead.

---

**Q4 [STAFF]: How does Hexagonal Architecture relate to Domain-Driven
Design?**

*Why they ask:* Staff signal: connecting multiple architectural
concepts into a coherent framework.

*Likely follow-up:* "What is an Anti-Corruption Layer in this context?"

Hexagonal Architecture is the structural foundation for Domain-Driven
Design at the technical level. DDD provides the strategic design
(Bounded Contexts, Ubiquitous Language, Aggregates) while Hexagonal
Architecture provides the structural pattern that preserves the
domain's integrity.

The connections:

The hexagon's interior = the Bounded Context's domain model.
The domain model (Aggregates, Value Objects, Domain Events) lives
inside the hexagon with no infrastructure dependencies.

Ports = the Bounded Context's external contracts.
The inbound ports are the use cases that other contexts can trigger.
The outbound ports are the dependencies the context needs from
outside (repositories, event publishers, external service clients).

Adapters = the implementation of those contracts.
A JPA repository adapter implements the persistence port.
An HTTP adapter implements the inbound port for external triggers.

Anti-Corruption Layer (ACL) = a specialized adapter pattern between
two Bounded Contexts. When Bounded Context A needs data from Bounded
Context B, the ACL translates B's model into A's domain language.
This prevents B's model from leaking into A's domain. The ACL is
implemented as an adapter in A's hexagon: it implements A's outbound
port and calls B's API or reads B's events, translating as needed.

*What separates good from great:* Most candidates describe Hexagonal
Architecture and DDD separately. Great candidates explain the mapping
(hexagon interior = bounded context model, ports = external contracts,
adapters = implementations) and the Anti-Corruption Layer as the
adapter pattern between bounded contexts.

---

**Q5 [SENIOR]: What are the primary adapters in Hexagonal Architecture?**

*Why they ask:* Tests precision - many candidates only know about
secondary (database) adapters.

*Likely follow-up:* "Give examples of primary adapters."

Hexagonal Architecture has two types of adapters, named for their
relationship to the domain.

Primary adapters (also called driving adapters) drive the domain.
They call the domain's inbound ports (use case interfaces). Examples:
REST controllers (handle HTTP and call use case methods), GraphQL
resolvers (handle GraphQL and call use cases), message consumers
(handle incoming Kafka messages and call use cases), CLI commands
(handle command-line arguments and call use cases), and unit test
harnesses (directly call use cases in tests - the test IS an adapter
that drives the domain in a test scenario).

Secondary adapters (also called driven adapters) are driven by the
domain. The domain calls outbound port interfaces, and secondary
adapters implement them. Examples: JPA repository (implements
`OrderRepository` port), email sender (implements `NotificationPort`),
external API client (implements `InventoryPort`), event publisher
(implements `DomainEventPublisher`).

The "hexagon" image: primary adapters are on the left side of the
hexagon (driving). Secondary adapters are on the right side (driven).
The domain is the hexagon in the center.

*What separates good from great:* Most candidates only describe
secondary adapters (database, external APIs). Great candidates
describe primary adapters (REST, CLI, test harnesses) and use the
driving/driven terminology to show they understand the directional
distinction.

---

**Q6 [STAFF]: How do you organize packages in a Hexagonal Architecture
project?**

*Why they ask:* Tests whether the candidate can translate the
architectural concept into a concrete, reproducible project structure.

*Likely follow-up:* "How do you prevent infrastructure from importing
domain classes (in the wrong direction)?"

I organize packages to enforce the dependency rule structurally:

```
src/main/java/com/example/
  domain/
    model/              <- Entities, Value Objects, Aggregates
    port/
      in/               <- Inbound ports (use case interfaces)
      out/              <- Outbound ports (repository, notifier interfaces)
    service/            <- Application services (orchestrators)
  adapter/
    in/
      web/              <- REST controllers (primary adapters)
      messaging/        <- Message consumers (primary adapters)
    out/
      persistence/      <- JPA repositories (secondary adapters)
      email/            <- Email adapters (secondary adapters)
      external/         <- External API adapters
  application/          <- Spring Boot main, config, wiring
```

The dependency rule enforced by package structure: `domain/`
imports from nothing external. `adapter/in/` imports from
`domain/port/in/`. `adapter/out/` imports from `domain/port/out/`.
Nothing in `adapter/` is imported by `domain/`.

ArchUnit rule to enforce at build time:

```java
@ArchTest
static final ArchRule domainIsolation =
    noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat()
        .resideInAPackage("..adapter..");
```

*What separates good from great:* Most candidates describe "domain
package and infrastructure package." Great candidates give a specific
package tree with `port/in` vs `port/out` separation and the ArchUnit
rule that enforces the dependency direction automatically.

---

**Q7 [SENIOR]: When would you NOT use Hexagonal Architecture?**

*Why they ask:* Tests architectural judgment. Candidates who
recommend Hexagonal Architecture for every project reveal cargo-cult
thinking.

*Likely follow-up:* "What would you use instead?"

Hexagonal Architecture is not appropriate when the overhead exceeds
the benefit. Three clear cases.

First: CRUD-heavy systems with thin domain logic. If the application
is 90% "take this HTTP request and put it in the database," the
port and adapter abstractions add ceremony without isolating anything
meaningful. A direct Spring Data JPA layer with validation is simpler
and produces the same result faster.

Second: early-stage systems with unknown domain boundaries. The
premium of Hexagonal Architecture (isolated domain, swappable
adapters) requires knowing the domain well enough to design stable
port interfaces. If the domain model is changing weekly because
the product is being discovered, the port interfaces will break
constantly. Start with a simpler structure that can be refactored
into Hexagonal once the domain stabilizes.

Third: read-optimized query services. A service that serves dashboard
queries with complex joins and aggregations is not expressing a
rich domain - it is expressing database queries. Hexagonal
Architecture's domain model is for write-side business logic.
Read-side query services are better implemented as direct database
queries (without domain model abstraction).

In practice: I recommend a Modular Monolith with well-bounded modules
that use Hexagonal internally for modules with complex domains,
and simple layered structure for CRUD modules within the same
codebase.

*What separates good from great:* Most candidates say "I would always
use Hexagonal." Great candidates give specific conditions where it
adds overhead without benefit (CRUD, unstable domain, query services)
and describe the modular hybrid (Hexagonal for complex domains,
layered for simple CRUD) as the practical production approach.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Port vs adapter distinction, dependency direction, test without database |
| Hiring Manager | Business value: domain isolated from technology choices |
| Bar Raiser | Anti-Corruption Layer, relation to DDD Bounded Contexts |
| Peer Engineer | Practical: package structure, ArchUnit enforcement, when not to use |

---

---

# Model-View-Controller

🎯 Interview Weight: high - the most widely implemented UI
architecture pattern; essential knowledge for any developer working
with web frameworks.

---

### 🎯 Model Answer

**30 seconds:**
> Model-View-Controller (MVC) separates an application into three
> components: the Model (data and business logic), the View (user
> interface rendering), and the Controller (handles user input,
> coordinates Model and View). The Controller receives a request,
> asks the Model for data or to perform an action, then selects a
> View to render the response. The key benefit: View and Model
> are decoupled - the same Model data can render in HTML, JSON,
> or XML depending on which View is chosen.

**3 minutes (Senior):**
> MVC originated in Smalltalk-80 as a desktop UI pattern and was
> adapted for web applications by frameworks like Spring MVC,
> Rails, and Django. In the web adaptation, the HTTP request cycle
> maps cleanly to MVC roles.
>
> The Controller receives the HTTP request: it parses parameters,
> validates the request format, and determines what action to take.
> It then calls the Model layer - not directly manipulating data
> but delegating to service/domain classes. The Model contains
> the application's data and business logic. The Controller receives
> the Model's response and selects the appropriate View to render.
>
> The key separation MVC provides: the View does not contain business
> logic (it only renders Model data). The Model does not know about
> HTTP or rendering (it is pure business logic). The Controller is
> a thin coordinator.
>
> The failure mode: "fat controller" antipattern. Controllers that
> contain business logic (validation, calculations, data manipulation)
> rather than delegating to the Model. When this happens, the
> controller becomes untestable without HTTP context and business
> logic is not reusable.
>
> Modern web development has shifted MVC toward MVC variants:
> front-end frameworks (React, Vue) use variations like Flux/Redux
> where the "Model" is a unidirectional data store, REST APIs use
> MVC on the server side where the "View" is JSON serialization.

*Adapting up:* Staff adds: "MVC is the right pattern for the
presentation layer. It should NOT extend into the business layer -
the 'M' in MVC is a presentation-layer model (DTOs, view models),
not the domain model. Confusing them is what creates the 'smart
model, fat controller' vs 'anemic model, fat controller' debate."

*Adapting down:* Junior: "MVC splits a web application into three
parts: the Controller handles incoming requests, the Model contains
the data and business rules, and the View renders the HTML (or
JSON) response. They are kept separate so changing how data is
displayed (View) does not require changing the business logic
(Model)."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Model-View-Controller - let
me explain each component and how they interact in a web request."

**(2) First principles:** "Every web application does three things:
processes user input, applies business logic, and renders output.
MVC assigns each of these to a separate component so they can
change independently."

**(3) Bridge:** "MVC is like a restaurant. The waiter (Controller)
takes your order, passes it to the kitchen (Model), and brings back
the plated food (View). You (the user) never go to the kitchen.
The kitchen never talks to the customer directly."

---

### 📘 Concept Explanation

**What it is:**
Model-View-Controller (MVC) is an architectural pattern that separates
an application into three components. The Model manages data and
business logic. The View handles rendering/presentation. The
Controller handles user input and coordinates between Model and View.

**The problem it solves:**
Without MVC, UI code (HTML/CSS), business logic (calculations, rules),
and data access (database queries) become intermingled. Changing
the UI breaks the business logic. Testing the business logic requires
a browser. Adding a new output format (JSON in addition to HTML)
requires duplicating the business logic.

**How it works:**

```
MVC WEB REQUEST FLOW

  Browser/Client
       |
       | HTTP Request (GET /orders/42)
       v
  +--------------------+
  |   CONTROLLER       |
  |   OrderController  |
  |   .getOrder(42)    |
  |                    |
  |   1. Parse request |
  |   2. Call model    |
  |   3. Select view   |
  +----+---------------+
       |                    ^
       | calls              | returns OrderDTO
       v                    |
  +--------------------+    |
  |   MODEL             |    |
  |   OrderService     +----+
  |   .findById(42)    |
  |                    |
  |   Business rules   |
  |   Data access      |
  +--------------------+

       |
       | passes model data to
       v
  +--------------------+
  |   VIEW              |
  |   order.html       |
  |   (or OrderDTO     |
  |   serialized JSON) |
  +--------------------+
       |
       | HTTP Response
       v
  Browser/Client
```

**The key insight:**
The Model knows nothing about Views or HTTP. The View knows nothing
about business logic or database. The Controller knows only about
HTTP requests and how to coordinate - it is a thin coordinator, not
a logic container. This separation allows: multiple Views for the
same Model data (HTML + JSON + XML), testable Model without HTTP
infrastructure, and changeable Views without touching business logic.

**When to use it:**
Web application frameworks (Spring MVC, Rails, Django, ASP.NET MVC).
Any application that separates user interface from business logic.
REST APIs (where the "View" is JSON serialization).

**When NOT to use it:**
Complex domain logic that requires more than a thin service layer -
MVC's "Model" is a presentation-layer concept; complex domains need
Hexagonal or Clean Architecture with a proper domain model. Event-
driven or reactive architectures where the request-response cycle
does not map cleanly to MVC.

**Alternatives:**
- MVP (Model-View-Presenter): View is more passive, Presenter handles all logic
- MVVM (Model-View-ViewModel): ViewModel provides data binding, common in desktop/mobile apps
- Flux/Redux: unidirectional data flow, used in React ecosystem

**First-principles derivation:**
Web applications have three distinct types of change: the business
rules change (Model), the presentation changes (View), and the
request handling changes (Controller). Organizing code by these
change types means each type of change is isolated to one component.

---

### 💻 Code Example

```java
// BAD: Fat controller - business logic in the controller
@RestController
public class OrderController {
    @Autowired private JdbcTemplate jdbc;

    @GetMapping("/orders/{id}")
    public Map<String, Object> getOrder(
        @PathVariable Long id,
        @RequestParam(required = false) String format
    ) {
        // Business logic in controller (wrong!)
        Map<String, Object> order =
            jdbc.queryForMap(
                "SELECT * FROM orders WHERE id = ?", id
            );

        // Price calculation in controller (wrong!)
        double subtotal = (double) order.get("quantity")
            * (double) order.get("unit_price");
        double tax = subtotal * 0.1;
        order.put("total", subtotal + tax);

        // Output format logic in controller (wrong!)
        if ("csv".equals(format)) {
            // CSV serialization here - controller does
            // 3 jobs
        }
        return order;
    }
}
// Testing total calculation requires an HTTP request
// and a database. CSV logic is stuck in the controller.
```

> **Code walkthrough:** This fat controller violates MVC by doing
> three things: data access (JDBC query), business logic (price
> calculation with tax), and view selection (CSV format logic).
> Testing the tax calculation requires standing up the HTTP layer
> and a database. Adding a new output format requires modifying
> the controller. A bug in the tax calculation sits in a controller
> method, not in a testable service. This is the fat controller
> antipattern MVC was designed to prevent.

```java
// GOOD: Thin controller, Model with business logic

// MODEL - Service layer (business logic)
@Service
public class OrderService {
    private final OrderRepository orderRepository;

    public OrderSummary getOrderSummary(Long id) {
        Order order = orderRepository.findById(id)
            .orElseThrow(() -> new OrderNotFoundException(id));
        // Business logic: pricing calculation here
        BigDecimal total = order.getSubtotal()
            .multiply(BigDecimal.ONE.add(TAX_RATE));
        return new OrderSummary(
            order.getId(),
            order.getItems(),
            total
        );
    }
}

// VIEW - DTO (what the view layer renders)
public record OrderSummaryDTO(
    Long id,
    List<OrderItemDTO> items,
    BigDecimal total
) {}

// CONTROLLER - thin coordinator
@RestController
@RequiredArgsConstructor
public class OrderController {
    private final OrderService orderService;
    private final OrderMapper mapper;

    @GetMapping("/orders/{id}")
    public ResponseEntity<OrderSummaryDTO> getOrder(
        @PathVariable Long id
    ) {
        OrderSummary summary = orderService.getOrderSummary(id);
        return ResponseEntity.ok(mapper.toDTO(summary));
    }
}
```

> **Code walkthrough:** The controller is now three lines of meaningful
> code: parse the path variable, call the service, return the DTO.
> All business logic (tax calculation, order lookup) is in `OrderService`,
> testable with a mocked repository. The `OrderSummaryDTO` is the
> "View" for JSON clients - a separate class specifically for the
> HTTP response, not the domain model exposed directly. Adding a new
> output format (CSV) means adding a new controller method or a
> content negotiation handler - the business logic does not change.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> MVC splits a web application into three parts: the Controller
> handles incoming HTTP requests, the Model contains the business
> logic and data, and the View renders the response (HTML, JSON).
> The controller calls the model, gets the result, and passes it
> to the view. The key benefit: business logic lives in the model
> and can be tested independently of HTTP. Changing the view (HTML
> to JSON) does not require changing the business logic.

*Push deeper:* Explain the fat controller antipattern. When
controllers contain business logic, what breaks? (Untestable without
HTTP context, logic cannot be reused by other entry points like
batch jobs or CLI.)

---

**Senior / Staff (5+ years):**
> MVC is the correct pattern for the presentation layer of a web
> application. The controller is a thin HTTP coordinator. The "M"
> in MVC should be a service/domain layer with real business logic,
> not an anemic data model.
>
> The distinction I maintain: the MVC "Model" is a presentation-layer
> concern, not the domain model. The controller calls a service
> (domain) layer and maps the result to a DTO (view model). The
> domain model never leaks directly into the view - that is what
> creates the @Entity-in-the-JSON-response problem.
>
> At scale: MVC on its own is not sufficient architecture. It handles
> the presentation layer. The service layer (domain logic) needs
> its own architecture - Hexagonal, Clean Architecture, or DDD.
> "MVC all the way down" means the service layer becomes a fat model
> with direct JPA access.

*Push deeper:* Staff angle: "The original Smalltalk MVC had the
View observe the Model directly (Observer pattern). Web MVC abandoned
this because HTTP is stateless. Modern frontend frameworks (React)
return to something like the original: the ViewModel (state) is
observed by the View component. Understanding this evolution shows
deep pattern knowledge."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| The "Model" in MVC is the domain model | In web MVC, the "M" is typically a view model (DTO) or a service result - the domain model is a separate concern beneath MVC |
| MVC is an architecture for the whole application | MVC is a presentation-layer pattern; it describes the presentation tier, not the business logic or data storage architecture |
| Fat models are better than fat controllers | Fat models (business logic in domain objects) are good DDD practice; fat controllers (business logic in controllers) are an antipattern - these are different things |
| React uses MVC | React uses a Flux/Redux unidirectional data flow variant, not classical MVC; the component IS the View, and state management replaces the Controller/Model split |
| The View is only HTML templates | In REST APIs, the View is JSON serialization; in GraphQL, it is the resolver output; View = any presentation layer, not just HTML |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Fat controller**

*Symptom:* Controllers with hundreds of lines of code. Business
validation, calculations, and workflow logic in controller methods.
Difficult to unit test business rules without HTTP context.

*Root cause:* Controller used as a transaction script instead of
a thin coordinator.

*Diagnostic:*
```bash
# Find large controller files
find src -name "*Controller*" |
  xargs wc -l | sort -rn | head -10
# Controllers > 100 lines are suspicious
# Controllers > 300 lines are almost always fat

# Find business logic in controllers
grep -r "if.*status\|calculate\|BigDecimal" \
  src/**/controller/
```

*Fix:* Extract all business logic into service classes. The
controller should be: parse request, call service, return response.
Three lines per endpoint method is the ideal.

*Prevention:* Code review rule: "Does this controller method do
anything other than parse the request, call a service, and return
the response? If yes, that logic belongs in the service layer."

**Failure 2: Business logic in the view**

*Symptom:* Complex conditional logic in templates (Thymeleaf, JSP).
Business rules expressed as if/else in template code. Discount
calculations or eligibility checks in the template.

*Root cause:* Convenience - template has the data, so the rule
is added in the template.

*Diagnostic:*
```html
<!-- Symptom: business rule in template -->
<!-- BAD -->
<span th:if="${user.subscriptionEndDate.isAfter(now)
  and !user.suspended and user.verifiedEmail}">
  ACTIVE
</span>
<!-- "Active" definition is a business rule in the view -->
```

*Fix:* Compute the business state in the Model layer and pass it
to the view. The view renders `user.isActive()` - a boolean set by
the model. The template has no business rules.

*Prevention:* Template code review: any template with if/else logic
beyond simple null checks should be reviewed. If the condition
uses multiple fields or business terms, it is a business rule.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 15 minutes |
| Core themes | Component responsibilities, fat controller antipattern, web adaptation |
| Seniority signal | Junior: names components; Senior: knows failure modes and MVC variants |
| Common trap | Treating MVC as the complete architecture |
| Staff differentiator | MVC as presentation layer only; domain architecture is separate |

---

**Q1 [JUNIOR]: What are the three components of MVC and what
does each do?**

*Why they ask:* Fundamental knowledge check. Tests whether the
candidate understands responsibilities, not just names.

*Likely follow-up:* "Who calls whom in an HTTP request?"

The three components, with their responsibilities in a web context:

Model: manages the application's data and business logic. When a
user places an order, the Model is responsible for validating the
order, applying business rules (check inventory, calculate price),
and persisting the result. The Model has no knowledge of HTTP or
how its data will be presented.

View: responsible for rendering the output. In a REST API, the View
is JSON serialization. In a traditional web application, the View
is an HTML template (Thymeleaf, JSP). The View should contain
display logic only - formatting dates, conditionally showing sections
based on data provided by the Controller.

Controller: the coordinator. It receives the HTTP request, extracts
parameters, calls the appropriate Model logic, and selects which
View to use for the response. It should be thin - a coordinator,
not a logic container.

In an HTTP request: Browser -> Controller -> Model -> Controller ->
View -> Browser. The Controller calls the Model. The Model returns
data. The Controller passes data to the View. The View renders.

*What separates good from great:* Most candidates list the three
components. Great candidates explain the HTTP flow direction and
emphasize that the Controller calls the Model (not the other way
around) and the Model knows nothing about HTTP or rendering.

---

**Q2 [MID]: What is the fat controller antipattern and what
causes it?**

*Why they ask:* Tests practical experience - the fat controller
is one of the most common antipatterns in MVC applications.

*Likely follow-up:* "What symptoms tell you a controller is too fat?"

The fat controller antipattern: business logic, validation logic,
or data access logic placed in the controller method instead of
in the Model/service layer. The controller becomes a transaction
script that does everything.

Causes: the controller is the first place a developer touches when
adding a new feature (handle the request); it already has the parsed
request data; it feels natural to just "add the logic here."

Symptoms: controller methods that exceed 30-50 lines, `if/else`
logic based on business conditions, `BigDecimal` calculations,
direct calls to repositories or JDBC, business terminology in the
controller method names (rather than HTTP action names).

Consequences: business logic is not reusable (a batch job cannot
call a controller method to use the same logic), untestable without
HTTP context, logic duplication when multiple endpoints need the
same business rules.

The fix: every business decision moves to a service class. The
controller method becomes: parse request -> call service -> return
response. Three steps, typically 5-10 lines.

*What separates good from great:* Most candidates describe fat
controllers abstractly. Great candidates give specific symptoms
(line count, business terminology, JDBC/JPA imports) and describe
the untestability consequence with an example.

---

**Q3 [SENIOR]: How does MVC differ between traditional server-side
rendering and modern REST APIs?**

*Why they ask:* Tests whether the candidate can adapt a classic
pattern to different contexts.

*Likely follow-up:* "Is React MVC?"

In server-side rendering MVC: the View is an HTML template
(Thymeleaf, JSP). The Controller renders the template and returns
HTML to the browser. The entire request-response cycle happens
server-side.

In REST API MVC: the View is the JSON/XML serialization layer.
The Controller serializes the Model result to the appropriate
media type (negotiated via Accept header). The client (mobile app,
SPA) does its own rendering with the received data.

The structural difference: in server-side MVC, the View is a
template engine on the server. In REST MVC, the "View" is
effectively the client application. The server provides the Model
(data) and the client provides the View (rendering).

React is NOT MVC in the classical sense. It uses a Flux-inspired
unidirectional data flow where state changes are unidirectional
(action -> dispatcher -> store -> view update). The component tree
IS the view, and the state management system (Redux, Zustand,
Context) plays the Model/Controller role. The distinction matters
because React's state management has very different properties
(immutability, time-travel debugging) from MVC.

*What separates good from great:* Most candidates describe server-side
MVC. Great candidates explain that REST API MVC has a "headless" View
(the client renders), and distinguish React's unidirectional data flow
from classical MVC with a clear explanation of why React is NOT MVC.

---

**Q4 [STAFF]: How does MVC relate to the overall application
architecture?**

*Why they ask:* Staff signal: MVC is a presentation pattern, not
a full application architecture. Tests whether the candidate
understands the full picture.

*Likely follow-up:* "What replaces MVC for the business layer?"

MVC describes the presentation tier of an application - how the
presentation layer is organized. It does not describe the business
logic layer or the data layer.

In a complete architecture: the Controller is a presentation-layer
component. It delegates to an Application/Service layer that contains
business logic. The Application layer delegates to domain models
and repositories. The repositories access the database.

The "M" in MVC is ambiguous and often misunderstood. In a CRUD
application, the "Model" might directly be the JPA entity with a
service thin enough to be transparent. In a DDD application, the
"M" the controller knows about is a DTO or Application Service -
the domain model is further inside, never exposed directly to the
presentation layer.

The common mistake: treating MVC as the complete application
architecture. This leads to "MVC all the way down" - the service
layer is just a thin wrapper over repositories with no real domain
model, all business logic is either in controllers (bad) or
in fat services with no encapsulation.

The correct model: MVC handles the presentation tier. For business
logic, add Layered Architecture, Hexagonal Architecture, or DDD
patterns on top of (or beneath) MVC. Spring MVC gives you the
presentation layer; what you do in the service and domain layers
is a separate architectural decision.

*What separates good from great:* Most candidates describe MVC as
the architecture. Great candidates describe MVC as a presentation-layer
pattern, explicitly separate the "M" in MVC from the domain model,
and describe the multi-tier architecture stack above which MVC sits.

---

**Q5 [SENIOR]: What is the difference between MVP, MVVM, and MVC?**

*Why they ask:* Tests architectural breadth across UI patterns.

*Likely follow-up:* "When would you choose each?"

MVC (Model-View-Controller): Controller handles user input and
coordinates. View can directly access Model data for rendering.
Used in: web frameworks (Spring MVC, Rails, Django).

MVP (Model-View-Presenter): View is completely passive - it only
renders data provided by the Presenter. The Presenter handles all
logic and all View interaction. The View has no knowledge of the
Model. Used in: Android (traditional), desktop UI testing where
the View is hard to test (MVP isolates testable logic in the
Presenter).

MVVM (Model-View-ViewModel): ViewModel provides a data binding
interface - View binds directly to ViewModel properties and updates
automatically when ViewModel changes. Two-way data binding between
View and ViewModel. Used in: WPF (Windows), Angular (TypeScript),
Vue.js.

Choosing: MVC for server-side web (HTTP request-response maps
cleanly to Controller). MVP when the View is hard to test and
business logic must be testable in isolation (e.g., Android before
modern architecture components). MVVM for rich client UIs with
complex state management and data binding (Angular, Vue, Windows
desktop).

*What separates good from great:* Most candidates vaguely describe
the patterns. Great candidates give the key distinction (passive
View in MVP, data binding in MVVM, direct Model access in MVC)
and identify specific technology contexts where each is the right
choice.

---

**Q6 [STAFF]: What are the problems with "smart model, fat
controller" and "anemic model, thin controller" extremes?**

*Why they ask:* Staff signal: understanding the spectrum between
two failure modes in MVC design.

*Likely follow-up:* "Where is the right balance?"

"Fat controller, anemic model" (most common): business logic in
the controller, domain objects are just data holders. Problems:
untestable business logic without HTTP, logic cannot be reused by
batch jobs or other entry points, controller grows unbounded.

"Thin controller, fat domain" (DDD target): business logic in
domain objects, controllers delegate to them. This is correct for
complex domains. Problems: can over-engineer simple CRUD operations
(a user profile edit does not need a `UserProfileUpdatePolicy`
domain service).

"Smart model, dumb controller" (MVC ideal): the Model (service
layer) contains all business rules. The Controller is a pure
HTTP coordinator - parse, call, return. The domain objects carry
behavior (order.place(), user.deactivate()). Problems: can become
too abstract for simple CRUD.

The right balance depends on domain complexity: for CRUD-heavy
features, the controller can be slightly smarter (more direct).
For business-rule-heavy features, all logic moves to the model/domain
layer. The test: "If I needed a CLI or batch job to do the same
operation, could it call the same Model code?" If yes, the
decomposition is right.

*What separates good from great:* Most candidates describe the fat
controller as bad and leave it there. Great candidates describe
both failure extremes (fat controller AND over-engineered thin
controller), give the specific test for correct decomposition
(CLI/batch reuse), and note that the right balance depends on
domain complexity.

---

**Q7 [STAFF]: How does MVC work in a microservices architecture?**

*Why they ask:* Tests whether the candidate can apply a pattern at
different scales.

*Likely follow-up:* "How do you handle shared model data across
multiple services?"

In a microservices architecture, MVC applies within each service.
Each microservice has its own MVC structure: REST controllers
(primary adapters) that delegate to service/domain logic (Model)
and return DTOs (View).

The challenge across services: the "Model" of each service is
isolated. Service A's Order model and Service B's Order model may
be different projections of the same business concept. This is
correct - each service has its own model appropriate to its
responsibilities (bounded context).

Cross-service "shared model" is an antipattern. When Service A
exposes its JPA entity directly as an API response, Service B's
controller binds to that exact structure. Any change to Service
A's internal model breaks Service B - tight coupling through
schema sharing.

The correct pattern: each service defines its own API model (DTO/
resource representation) as its View layer output. Internal model
changes do not automatically break the API because there is a
mapping layer between internal model and API representation.

API versioning in this context: the Controller layer manages API
versions by routing to different View (DTO) representations of
the same underlying Model. `/v1/orders` and `/v2/orders` can return
different DTOs from the same service logic.

*What separates good from great:* Most candidates say "each
microservice has MVC." Great candidates discuss the cross-service
model isolation problem (bounded context models), the danger of
shared JPA entity as API response, and API versioning via DTO
versioning in the View layer.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Fat controller antipattern, component responsibilities, MVC variants |
| Hiring Manager | Maintainability: testable business logic separated from HTTP handling |
| Bar Raiser | MVC as presentation-layer only, domain architecture beneath MVC |
| Peer Engineer | Practical: code review signals for fat controller, refactoring approach |

---

---

# Component Design Principles

🎯 Interview Weight: high - foundational design theory that
demonstrates architectural maturity; commonly asked at senior and
staff levels.

---

### 🎯 Model Answer

**30 seconds:**
> Component Design Principles (from Robert Martin's "Clean
> Architecture") are six rules for organizing code into deployable
> units: three cohesion principles (what goes into a component)
> and three coupling principles (how components relate to each other).
> The cohesion principles ensure components are focused. The coupling
> principles ensure the dependency graph has no cycles and that
> instability flows in the right direction - stable components
> are independent; unstable components depend on stable ones.

**3 minutes (Senior):**
> Robert Martin's component design principles extend SOLID from
> the class level to the component (module, JAR, package) level.
> They answer two questions: which classes belong in the same
> component, and how should components depend on each other?
>
> The three cohesion principles: REP (Release/Reuse Equivalency) -
> the granule of reuse is the granule of release; classes released
> together should be designed to be reused together. CCP (Common
> Closure) - classes that change for the same reason belong together;
> this is SRP at the component level. CRP (Common Reuse) - do not
> force users to depend on things they do not need.
>
> The three coupling principles: ADP (Acyclic Dependencies) -
> the dependency graph must have no cycles. SDP (Stable Dependencies)
> - depend in the direction of stability; unstable components should
> not be depended on by stable components. SAP (Stable Abstractions)
> - the more stable a component is, the more abstract it should be.
>
> The key metrics that operationalize these: Afferent coupling (Ca)
> measures how many depend on you (stability indicator). Efferent
> coupling (Ce) measures how many you depend on (instability
> indicator). Instability I = Ce / (Ce + Ca). A stable core domain
> component should have I near 0. An adapter or plugin should have
> I near 1.

*Adapting up:* Staff adds: "These principles provide the architecture
metrics for building architecture fitness functions. An automated
test that verifies no dependency cycles exist (ADP), and that
component instability values flow from higher to lower toward the
core, is an architecture fitness function that prevents architectural
drift."

*Adapting down:* Junior: "Component Design Principles are rules
for how to organize packages (groups of classes). The main ideas:
classes that change together should be in the same package, packages
should not have circular dependencies, and stable packages
(things that many others depend on) should be abstract."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Component Design Principles
- let me walk through the six principles and what each ensures."

**(2) First principles:** "Code is organized into components
(packages, JARs, modules). Good component design ensures: each
component is cohesive (contains related things), components
can be deployed and versioned independently, and the dependency
structure supports changeability."

**(3) Bridge:** "Component principles are like city zoning laws.
Zoning determines what belongs in the same district (cohesion
principles) and what districts should be adjacent vs separate
(coupling principles). Good zoning produces a city that functions
well; bad zoning creates traffic and inefficiency."

---

### 📘 Concept Explanation

**What it is:**
Component Design Principles (from Robert Martin's "Clean Architecture"
and "Agile Software Development") are six principles for designing
the boundaries and relationships between components - deployable
units like JARs, packages, or modules.

**The problem it solves:**
Without component design principles, packages become arbitrary
collections of classes. Dependencies between packages create
cycles that make packages impossible to release independently.
Classes are grouped by convenience rather than by reason-to-change,
leading to unnecessary redeployments when unrelated features change.

**How it works:**

```
THE SIX COMPONENT PRINCIPLES

COHESION PRINCIPLES (what belongs in a component):

  REP - Release/Reuse Equivalency Principle
    The granule of reuse == granule of release
    Classes released together should be designed together
    A library with 100 classes where you need 2 but must
    include all 100 has poor REP granularity

  CCP - Common Closure Principle
    Classes that change for same reason belong together
    Classes that change for different reasons belong apart
    SRP at the component level
    Design components so one change affects one component

  CRP - Common Reuse Principle
    Do not force users to depend on things they do not need
    Classes used together belong together
    Classes NOT used together should NOT be in same component

COUPLING PRINCIPLES (how components relate):

  ADP - Acyclic Dependencies Principle
    The dependency graph must have NO cycles
    If A -> B -> C -> A, you cannot release any in isolation
    Break cycles: extract a new component, use DIP

  SDP - Stable Dependencies Principle
    Depend in the direction of stability
    Stable components should not depend on unstable ones
    Instability I = Ce / (Ce + Ca)
    Core domain: I near 0 (stable, many depend on it)
    Adapters/plugins: I near 1 (unstable, depends on many)

  SAP - Stable Abstractions Principle
    A component should be as abstract as it is stable
    Stable components should consist of interfaces
    Unstable components can be concrete
    SAP + SDP = Dependency Inversion at component level
```

**The key insight:**
SDP and SAP together implement the Dependency Inversion Principle
at the component level. The stable (widely depended-upon) components
should be abstract (interfaces, ports). The unstable (plugin)
components should be concrete (implementations, adapters). This
is exactly Hexagonal Architecture's structure stated as metrics.

**When to use it:**
When designing module boundaries in a large codebase. When planning
the release and versioning strategy for libraries. When evaluating
whether a refactoring improves or degrades component cohesion.

**When NOT to use it:**
Small codebases with one or two packages do not need formal component
principle analysis. The principles apply at the module/library scale,
not at the individual class scale.

**Alternatives:**
- Domain-Driven Design's Bounded Contexts: business-domain-driven component boundaries
- Package by feature (vertical slice) vs package by layer (horizontal)
- Conway's Law: component boundaries should mirror team communication structures

**First-principles derivation:**
Components are deployed together. When component A is released,
all classes in A must be compatible. Cohesion principles ensure
that classes with different release schedules are not forced into
the same component. Coupling principles ensure the dependency
graph can be traversed for release ordering (no cycles) and that
the direction of dependency supports changeability (stable
components at the core).

---

### 💻 Code Example

```java
// BAD: ADP violation - circular dependency between components
// Package: com.example.orders
package com.example.orders;
import com.example.inventory.InventoryService;

public class OrderService {
    private InventoryService inventoryService;
    // OrderService DEPENDS ON InventoryService
}

// Package: com.example.inventory
package com.example.inventory;
import com.example.orders.OrderRepository;

public class InventoryService {
    private OrderRepository orderRepository;
    // InventoryService DEPENDS ON OrderRepository
    // CYCLE: orders -> inventory -> orders
}
// Can't release orders without inventory.
// Can't release inventory without orders.
// Can't test orders without inventory.
```

> **Code walkthrough:** This circular dependency (orders package
> imports inventory, inventory package imports orders) violates the
> Acyclic Dependencies Principle. Neither package can be compiled,
> tested, or released independently. Adding a feature to orders
> potentially requires changing inventory. This structure would
> eventually require the two packages to be merged into one
> (increasing their size) or the cycle to be broken.

```java
// GOOD: ADP - break cycle by extracting shared abstraction
// New package: com.example.shared (no dependencies on orders
// or inventory)
package com.example.shared;

// Shared abstraction extracted from cycle
public interface StockChecker {
    boolean hasStock(ProductId productId, int quantity);
}

// Package: com.example.inventory
package com.example.inventory;
import com.example.shared.StockChecker;

@Service
public class InventoryService implements StockChecker {
    @Override
    public boolean hasStock(
        ProductId productId, int quantity
    ) {
        // inventory-specific implementation
        return stockRepository
            .findByProduct(productId)
            .map(s -> s.getQuantity() >= quantity)
            .orElse(false);
    }
}

// Package: com.example.orders
package com.example.orders;
import com.example.shared.StockChecker;
// NO import from com.example.inventory!

@Service
public class OrderService {
    private final StockChecker stockChecker;
    // Depends on shared abstraction, not inventory impl
}

// Dependency graph: orders -> shared <- inventory
// No cycles. Each package releases independently.
```

> **Code walkthrough:** The cycle is broken by extracting a shared
> abstraction (`StockChecker` interface) into a third component that
> neither orders nor inventory depends on initially. The orders
> component depends on the interface; the inventory component
> implements it. The dependency graph is now a directed acyclic
> graph: `orders -> shared <- inventory`. Each component can be
> compiled, tested, and released independently. This is the ADP
> fix pattern: when you find a cycle, extract the shared dependency
> into a new component.

```java
// SDP VIOLATION EXAMPLE: stable component depends on
// unstable component
// Stable: com.example.domain (many things depend on this)
package com.example.domain;
// BAD: domain depends on a frequently-changing utility
import com.example.utils.experimental.JsonFormatter;

public class OrderPrinter {
    // Depends on experimental/unstable utility
    private JsonFormatter formatter;
}
// Problem: a change to experimental JsonFormatter forces
// recompile/retest of the stable domain package.
// The stable component has taken on the instability
// of the unstable one.

// FIX: domain defines the abstraction it needs
package com.example.domain;
public interface Formatter {
    String format(Order order);
}
// experimental.JsonFormatter implements Formatter.
// domain depends on nothing unstable.
```

> **Code walkthrough:** The SDP violation shows the stable domain
> component importing from an experimental (unstable) utility. Every
> time the experimental formatter changes, the domain must be
> recompiled and retested - the domain has taken on the instability
> of the formatter. The fix is identical to the Dependency Inversion
> Principle at the component level: the domain defines the interface
> it needs (`Formatter`), and the unstable experimental component
> implements it. The dependency arrow points from unstable to stable.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Component Design Principles are rules for organizing packages
> and modules. The main ones: classes that change for the same reason
> should be in the same package (Common Closure Principle - SRP at
> package level), packages should not have circular dependencies
> (Acyclic Dependencies Principle), and stable packages (things many
> others depend on) should be abstract interfaces rather than concrete
> implementations (Stable Abstractions Principle).

*Push deeper:* Explain what a "cycle" between packages means and
why it is a problem. If package A depends on package B and B depends
on A, neither can be released or tested independently.

---

**Senior / Staff (5+ years):**
> I use three principles day-to-day. CCP (Common Closure) when
> designing module boundaries: classes that are owned by the same
> team and change in the same business events belong together. ADP
> when reviewing package dependencies: I run JDepend or build the
> dependency graph to verify no cycles exist - cycles are always
> fixed before merging. SDP + SAP together to verify that my
> component stability metrics flow correctly: the domain core (high
> stability, I near 0, should be abstract) and adapters (low
> stability, I near 1, should be concrete).
>
> The SAP + SDP combination is just the Dependency Inversion
> Principle stated as metrics. A Hexagonal Architecture's domain
> ports (interfaces with high stability) satisfy SAP. The adapters
> (concrete implementations with low stability) satisfy SDP by
> depending on the stable ports.

*Push deeper:* Staff angle: "CCP is the principle that drives how
I structure microservice boundaries. Services should be structured
so that a single business change touches one service, not many.
When a pricing rule change requires updating four services, CCP is
violated at the service level - those four services have mixed
concerns that share a closure."

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| Component principles only apply to Java/OOP | The principles apply to any language's module/package system - Python modules, Node.js packages, Rust crates, Go modules all have these relationships |
| Stable means "doesn't change" | Stable means "hard to change because many things depend on it." A component can be stable and rarely change, or stable and frequently need to change (which is a design problem) |
| CCP and SRP are the same | SRP applies to classes; CCP applies to components (packages, modules, JARs). CCP asks "which classes should be packaged together," not "what should this class do" |
| No cycles means no dependencies | ADP requires no CYCLES (circular dependencies), not no dependencies. Components can depend on each other freely as long as the graph is acyclic |
| The most stable component should have the most classes | Stability is measured by afferent coupling (how many depend on it), not by size. A single interface can be maximally stable |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Dependency cycle between modules**

*Symptom:* Changing module A requires changing module B which
requires changing module A (or a longer chain). Modules cannot
be tested in isolation. Maven build fails with circular dependency
errors.

*Root cause:* ADP violation. Two or more modules have created
a dependency cycle.

*Diagnostic:*
```bash
# Detect cycles in Java with JDepend or Maven enforcer
mvn jdepend:generate  # generates dependency report

# Or with ArchUnit
@ArchTest
static final ArchRule noCycles =
    slices()
        .matching("com.example.(*)..")
        .should().beFreeOfCycles();

# Or with dependency-cruiser (Node.js)
npx depcruise --include-only "^src" \
  --output-type dot src | dot -T svg > deps.svg
```

*Fix:* Extract the shared abstraction causing the cycle into a new
component. Use Dependency Inversion (define an interface in the
more stable component). Sometimes: merge the two components if
they truly belong together (CCP says they should be together if
they always change together).

*Prevention:* ADP fitness function in CI/CD. Build fails if a
cycle is introduced. Review dependency graphs at architecture
review gates.

**Failure 2: Unstable component in the stable core**

*Symptom:* A frequently-changed utility or framework-dependent
class is imported by the domain core. Every framework upgrade forces
the domain to be recompiled and retested. Domain tests break when
a logging library upgrades.

*Root cause:* SDP violation. A stable component (domain core)
depends on an unstable component (framework utility).

*Diagnostic:*
```
# Compute instability metric for each component:
# I = Ce / (Ce + Ca)
# Domain core: should have low I (many depend on it,
#   it depends on little)
# If domain core has high I, it is depending on
#   too many components
```

*Fix:* Define an interface in the domain core for what it needs
(Stable Abstractions Principle). Move the unstable implementation
to an adapter component that depends on the core interface.

*Prevention:* ArchUnit rules that prevent domain packages from
importing framework or utility packages directly.

**Failure 3: Package-per-layer creates cross-cutting monolith**

*Symptom:* Packages organized as `controller/`, `service/`,
`repository/`, `model/`. Adding a new feature requires changes in
all four packages. Git diffs for a single feature touch 8-10 files
across multiple packages. Different teams each "own" a layer.

*Root cause:* CCP violation at the package level. Classes for one
business feature are split across multiple packages organized by
technical concern rather than by closure.

*Diagnostic:*
```
- How many packages are changed in a typical feature PR?
  (> 2 = likely CCP violation if organized by layer)
- Are there imports from "service" package in every
  "controller" class? (tight cross-package coupling)
```

*Fix:* Reorganize to package-by-feature. All classes for "Order
Management" in `order/` package: `OrderController`, `OrderService`,
`OrderRepository`, `Order` domain model. Each feature team owns one
package. CCP: classes that change together (for Order Management
business events) belong together.

*Prevention:* When creating a new feature, ask: "Which existing
package should this belong to by closure?" If the answer is "all
of them," that is a CCP violation in the existing structure.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | Six principles, stability metrics, ADP cycles |
| Seniority signal | Junior: knows the names; Senior: applies metrics; Staff: fitness functions |
| Common trap | Conflating component principles with SOLID (different scope) |
| Staff differentiator | SAP + SDP = DIP at component level; fitness functions for ADP |

---

**Q1 [JUNIOR]: What are the component cohesion principles?**

*Why they ask:* Tests foundational knowledge of module organization
principles.

*Likely follow-up:* "Which one is most related to the Single
Responsibility Principle?"

There are three cohesion principles that determine what classes
belong in the same component:

REP - Release/Reuse Equivalency Principle: classes released together
should be designed to be reused together. If you publish a library
and users only ever need 10% of it, but must take all 100% as a
dependency, the granularity is wrong.

CCP - Common Closure Principle: classes that change for the same
reason (same team, same business event) belong in the same component.
This is the Single Responsibility Principle applied at the component
level. "One component should have one reason to change" - where
"reason" means the business force that drives the change.

CRP - Common Reuse Principle: do not force users to depend on
things they do not use. If a component has 50 classes and a user
only needs 2, changes to the other 48 still force the user to
recompile and test against the new version. Keep components cohesive
enough that users of any part need all parts.

CCP is most related to SRP: both say "group things that change
together, separate things that change for different reasons." SRP
does this at the class level; CCP at the component level.

*What separates good from great:* Most candidates describe one or
two principles vaguely. Great candidates give all three with concrete
examples (library granularity for REP, team/business-event ownership
for CCP, unused dependency for CRP).

---

**Q2 [MID]: What is the Acyclic Dependencies Principle and why
does it matter?**

*Why they ask:* ADP is a practical principle with direct build and
release consequences. Tests whether the candidate understands it
at the operational level.

*Likely follow-up:* "How do you break a dependency cycle?"

The Acyclic Dependencies Principle states that the component
dependency graph must contain no cycles. If Component A depends
on B, and B depends on C, and C depends on A, there is a cycle.

Why it matters: with a dependency cycle, you cannot compile, test,
or release any component in the cycle independently. Changing
component A requires releasing B and C (because they depend on A);
but B and C cannot compile without A. The cycle creates a forced
simultaneous release of all components in it.

Practically: Maven and Gradle refuse to build module-level cycles.
In packages within a single module, cycles are allowed by the
build system but create the same conceptual problem.

Breaking a cycle: extract the shared abstraction. If A and B are
in a cycle because B calls A for one interface, extract that
interface into a new component C. Now: A depends on C, B depends
on C. No cycle. C can be released independently. A and B can be
released independently.

Alternative: use dependency inversion. A defines an interface.
B implements the interface. A never imports B. The arrow is reversed
(B now depends on A's interface).

*What separates good from great:* Most candidates describe the
principle. Great candidates explain the practical consequence
(cannot build in isolation) and give the specific fix patterns
(extract interface, dependency inversion).

---

**Q3 [SENIOR]: What is the Stable Dependencies Principle and how
do you measure stability?**

*Why they ask:* Tests whether the candidate has moved from conceptual
knowledge to quantitative evaluation.

*Likely follow-up:* "What is the instability metric?"

The Stable Dependencies Principle: a component should depend only
on components that are more stable than itself. "Stable" means
hard to change because many things depend on it.

The instability metric: I = Ce / (Ce + Ca)

Ce (Efferent coupling): how many components does this component
depend on? High Ce = depends on many = could be broken by many.

Ca (Afferent coupling): how many components depend on this
component? High Ca = many things depend on it = changing it breaks
many things.

I = Ce / (Ce + Ca)
- I = 0: maximally stable. Nothing it depends on, but many things
  depend on it. Hard to change (breaking changes affect many).
- I = 1: maximally unstable. Depends on many things, nothing depends
  on it. Easy to change (no one is broken by a change).

SDP: the direction of dependency should be from I=1 (unstable)
toward I=0 (stable). The domain core should have I near 0 (many
things depend on it, it depends on nothing). Adapters should have
I near 1 (depends on domain interfaces, nothing depends on the
adapter).

Tools: JDepend for Java computes these metrics per package. A report
showing a component with I near 0 that has many efferent couplings
is an SDP violation.

*What separates good from great:* Most candidates say "stable means
doesn't change." Great candidates give the instability metric formula,
explain what I=0 and I=1 mean operationally, and describe the SDP
arrow direction (from I=1 to I=0) with an example (adapters depend
on domain, domain depends on nothing).

---

**Q4 [STAFF]: How do you use component principles to design
service boundaries in a microservices system?**

*Why they ask:* Staff signal: applying package-level principles
at the service level.

*Likely follow-up:* "What does a CCP violation look like at the
service level?"

The three cohesion principles apply directly to service boundary
design.

CCP at the service level: services should be organized so that
a single business change requires modifying one service, not many.
If adding a new promotional discount type requires changing the
Order Service, the Pricing Service, the Cart Service, and the
Notification Service, those four services are not closed to the
"promotions change." They have a cross-service CCP violation.
The fix: consolidate promotion logic into one service.

CRP at the service level: a service that handles ten different
business capabilities forces every consumer to depend on all ten.
When the consumer only uses two capabilities, changes to the other
eight still create deployment coordination concerns. High CRP
violations at the service level are a signal that a service is
doing too much.

ADP between services: service dependency graphs should be acyclic.
Service A calls Service B which calls Service C which calls Service
A is a distributed cycle. It creates circular deployment dependencies
and runtime coupling loops. Break cycles using events: rather than
C calling back to A, C publishes an event that A subscribes to.

SDP between services: the most-depended-on services (Auth, User,
Product catalog) should be the most stable (rarely change APIs).
Rapidly-evolving services should not be deeply in the dependency
graph.

*What separates good from great:* Most candidates describe the
principles at class/package level. Great candidates apply all three
cohesion principles to service boundaries with specific examples
of violations and fixes at the service level.

---

**Q5 [STAFF]: How do you build architecture fitness functions
from component principles?**

*Why they ask:* Staff signal: turning principles into automated
enforcement.

*Likely follow-up:* "What fitness function would you implement
for the ADP?"

Architecture fitness functions (from the Evolutionary Architecture
book) are automated tests that verify architectural properties
continuously. Component principles translate directly into fitness
functions.

ADP fitness function - no dependency cycles:
```java
@ArchTest
static final ArchRule noCycles =
    slices()
        .matching("com.example.(*)..")
        .should().beFreeOfCycles();
```
This runs in the test suite and fails the build if a cycle is
introduced.

SDP fitness function - domain components must not depend on
adapters:
```java
@ArchTest
static final ArchRule sdpRule =
    noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat()
        .resideInAPackage("..adapter..");
```

Component size / CCP fitness function - flag components that are
growing toward a god component:
```java
// Custom ArchUnit check: warn if a package has > 20 classes
// (signal that CCP may be violated)
```

Stability metric drift - track average instability of domain
packages over time. If domain package instability increases
(gaining efferent couplings), it is a SDP violation in progress.
This can be tracked as a JDepend metric exported to a dashboard.

*What separates good from great:* Most candidates describe manual
code review. Great candidates give specific ArchUnit implementations
of ADP and SDP fitness functions and describe the metric dashboard
approach for tracking stability trends over time.

---

**Q6 [STAFF]: What is the Stable Abstractions Principle and how
does it relate to the Dependency Inversion Principle?**

*Why they ask:* Tests deep understanding of the connection between
component principles and the SOLID principles.

*Likely follow-up:* "Show how SAP + SDP gives you DIP at component level."

The Stable Abstractions Principle: the abstractness of a component
should be proportional to its stability. Highly stable components
(many things depend on them) should be highly abstract (interfaces
and abstract classes). Highly unstable components (few things
depend on them) can be concrete.

The reasoning: if a stable component is concrete (a class with
implementation), changing that implementation breaks all its
dependents. But if it is abstract (an interface), dependents can
change their implementations without the stable component changing.

The abstractness metric: A = abstract classes / total classes.
A = 1: maximally abstract. A = 0: maximally concrete.

SAP + SDP together give the "Main Sequence":
- Stable (I=0) and Abstract (A=1): core domain ports, perfectly positioned
- Unstable (I=1) and Concrete (A=0): adapters/plugins, perfectly positioned
- Stable (I=0) and Concrete (A=0): "Zone of Pain" - hard to change, hard to test
- Unstable (I=1) and Abstract (A=1): "Zone of Uselessness" - abstract but nobody uses it

This is exactly the Dependency Inversion Principle at component scale:
- DIP says "depend on abstractions, not concretions"
- SAP says "stable components should be abstract"
- SDP says "depend in the direction of stability"
- Together: depend on abstract stable components = DIP

Hexagonal Architecture's domain interfaces (stable, abstract) and
adapters (unstable, concrete) land exactly on the Main Sequence.

*What separates good from great:* Most candidates know DIP and SAP
separately. Great candidates connect them: SAP + SDP = DIP at
component level, give the Main Sequence diagram positions, and
describe the "Zone of Pain" (stable + concrete) as the failure
mode to avoid.

---

**Q7 [SENIOR]: How does package-by-layer differ from package-by-feature,
and which is better?**

*Why they ask:* Tests practical understanding of the CCP principle
applied to real project structure decisions.

*Likely follow-up:* "Can you mix both approaches?"

Package-by-layer: code organized by technical concern.
`com.example.controller`, `com.example.service`,
`com.example.repository`, `com.example.model`. All controllers
in one package, all repositories in another.

Package-by-feature: code organized by business capability.
`com.example.order`, `com.example.user`, `com.example.payment`.
All order-related code (controller, service, repository, model)
in one package.

Which is better? Depends on team structure (Conway's Law) and the
CCP principle.

Package-by-layer aligns with functional specialization (frontend
team, backend team, DBA team). It also makes it easy to find "all
controllers" in one place. The problem: every feature spans multiple
packages - adding a new field to orders changes files in four
packages. This is the CCP violation - classes that change together
(for Order Management business events) are in different packages.

Package-by-feature aligns with feature-team organization (team
owns all of orders, team owns all of payments). CCP is satisfied:
all classes that change together for Order Management are in the
`order` package. A git diff for a new order feature is in one
directory.

For large projects: package-by-feature at the top level, package-
by-layer within a feature. `com.example.order.controller`,
`com.example.order.service`, `com.example.order.repository`.
Top-level: feature boundary. Inner level: layer organization for
navigation.

*What separates good from great:* Most candidates have an opinion
but cannot explain WHY one is better. Great candidates connect
the choice to CCP (package-by-feature satisfies CCP; package-by-layer
violates it for multi-layer features) and to Conway's Law (team
structure should drive package structure).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Six principles, instability metric, cycle detection |
| Hiring Manager | Business impact: CCP reduces multi-team coordination for features |
| Bar Raiser | SAP + SDP = DIP at component level; fitness functions |
| Peer Engineer | Practical: package structure, JDepend metrics, ArchUnit enforcement |
