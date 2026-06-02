---
layout: default
title: "JPA - L2 Transactions"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 5
permalink: /jpa/l2-transactions/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [JPA - L2 Transactions](#jpa---l2-transactions) | medium |

---

# JPA - L2 Transactions

## JPA Transactions: @Transactional and Persistence Context Lifecycle

---

### 🎯 Model Answer

**30 seconds:**
> `@Transactional`: Spring begins a DB transaction before the method, commits on success, rolls
> back on unchecked exception (RuntimeException). Persistence context: lives for the transaction
> duration. Entities loaded within the transaction are managed (dirty checked on commit).
> `readOnly=true`: skips dirty checking (performance win for read-only methods).

**3 minutes (Senior):**
> `@Transactional` behavior:
>
> 1. **Proxy model**: Spring creates a proxy around the `@Transactional` bean. When an external
>    caller invokes a `@Transactional` method: the proxy intercepts, begins a transaction, delegates
>    to the real method, commits or rolls back. Self-invocation (calling `@Transactional` method
>    from within the same class): BYPASSES the proxy. No transaction started.
>
> 2. **Propagation**: `REQUIRED` (default): join existing transaction or create new one. `REQUIRES_NEW`:
>    always create new transaction (suspends current if any). `NOT_SUPPORTED`: suspend current
>    transaction and run without. `MANDATORY`: throw if no active transaction. `NEVER`: throw if
>    transaction is active.
>
> 3. **Rollback rules**: by default, Spring rolls back on `RuntimeException` (unchecked) and
>    `Error`. Does NOT roll back on checked exceptions (`IOException`, `Exception`). Override:
>    `@Transactional(rollbackFor = Exception.class)` or `noRollbackFor = BusinessException.class`.
>
> 4. **Isolation levels**: READ_UNCOMMITTED, READ_COMMITTED (PostgreSQL default), REPEATABLE_READ
>    (MySQL InnoDB default), SERIALIZABLE. Higher isolation: more locking, lower concurrency.
>    Most apps: `READ_COMMITTED` with optimistic locking for consistency.

**Blank Mind Recovery:**

**(1) Restate:** "Spring proxy: begin transaction -> method -> commit/rollback. Self-invocation: no proxy, no transaction. Rollback: RuntimeException default. Propagation: REQUIRED (join/create) or REQUIRES_NEW (always new). readOnly: skip dirty check."

**(2) First principles:** "A transaction is an atomic unit of work. Either all operations succeed (commit) or all are rolled back (rollback). Spring @Transactional: declares the boundaries. The DB enforces the ACID properties within those boundaries."

**(3) Bridge:** "@Transactional is like a receipt at a store. If you pay for all items and leave: the receipt is issued (commit). If you leave without paying for one item: the entire purchase is cancelled (rollback). The 'transaction' groups all items into one atomic operation."

---

### 📘 Concept Explanation

**@Transactional behavior and pitfalls:**
```plaintext
SELF-INVOCATION (PROXY BYPASS):

  @Service
  public class OrderService {
      
      @Transactional  // this method has a transaction
      public void processOrder(Order order) {
          validateOrder(order);  // no @Transactional
          chargePayment(order);  // @Transactional - BUT: self-invocation!
      }
      
      @Transactional(propagation = Propagation.REQUIRES_NEW)
      public void chargePayment(Order order) {
          // Intended: run in a new, independent transaction.
          // Actual: called from within the same class.
          //         Spring proxy not involved.
          //         Runs in the SAME transaction as processOrder.
          //         REQUIRES_NEW has NO EFFECT.
      }
  }
  
  Fix: inject OrderService into itself (or extract to a separate service bean):
  
  @Service
  public class OrderService {
      @Autowired OrderService self;  // injects the proxied instance
      
      public void processOrder(Order order) {
          validateOrder(order);
          self.chargePayment(order);  // goes through proxy -> correct behavior
      }
      
      @Transactional(propagation = Propagation.REQUIRES_NEW)
      public void chargePayment(Order order) { ... }
  }
  
  Or better: extract chargePayment to a PaymentService bean.

PROPAGATION LEVELS:

  REQUIRED (default):
    Outer @Transactional: creates a TX.
    Inner @Transactional: joins the SAME TX.
    Inner rollback: rolls back the outer TX too (they share one TX).
    
  REQUIRES_NEW:
    Inner @Transactional: creates a NEW TX, suspends the outer.
    Inner commit: outer TX continues (regardless of inner outcome).
    Inner rollback: only the new TX is rolled back. Outer continues.
    Use case: audit logging (save audit record even if main TX rolls back).
    
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void saveAuditLog(AuditRecord record) {
        auditRepository.save(record);
        // New TX: committed even if the caller's TX rolls back.
    }
  
  NESTED:
    Uses DB savepoints (JDBC savepoint support required).
    Inner rollback: reverts to savepoint (outer TX continues from savepoint).
    Inner commit: part of outer TX (committed when outer commits).
    Rarely used in practice.

ROLLBACK RULES:

  Default:
    Rollback on: RuntimeException, Error.
    No rollback on: checked exceptions (Exception, IOException, etc.)
    
  Common mistake:
    public void createUser(String email) throws UserAlreadyExistsException {
        // UserAlreadyExistsException extends Exception (checked).
        if (userExists(email)) throw new UserAlreadyExistsException(email);
        userRepository.save(new User(email));  // saved but exception thrown
        // Default: no rollback. User is saved. Exception is thrown.
        // Caller: handles exception but user already in DB. Inconsistent.
    }
    
  Fix: extend RuntimeException or add rollbackFor:
    class UserAlreadyExistsException extends RuntimeException { ... }
    // Or:
    @Transactional(rollbackFor = UserAlreadyExistsException.class)
    public void createUser(String email) throws UserAlreadyExistsException { ... }

READONLY TRANSACTIONS:

  @Transactional(readOnly = true) benefits:
  
  1. Hibernate: skips dirty checking at flush (no entity-to-snapshot comparison).
     For 100 loaded entities: no snapshot comparison at flush. Small but measurable gain.
  
  2. Hibernate: may skip creating snapshots at all (less heap usage).
  
  3. Spring: sets JDBC Connection to read-only mode.
     Some JDBC drivers/pools: route to read replica.
     DataSource routing: can route read-only connections to replicas.
  
  4. DB: some DBs (MySQL): read-only transaction hint -> better optimizer...
  
  Anti-pattern: @Transactional(readOnly=true) on a method that writes.
    Write inside readOnly transaction: may succeed (readOnly is a hint, not enforced).
    Or may fail with "connection is read-only" (if driver enforces it).
    Result: unpredictable. Don't mix.
```

> **Code walkthrough:** This L2 Transactions example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

---

### 💻 Code Example

> **Code walkthrough:** The REQUIRES_NEW audit log pattern is the most common legitimate use of
> non-default propagation. The rollback exception type is the most common `@Transactional` bug.

```java
// REQUIRES_NEW FOR AUDIT (independent transaction):

@Service
public class OrderService {
    
    private final OrderRepository orderRepository;
    private final AuditService auditService;
    
    @Transactional
    public Order createOrder(CreateOrderRequest req) {
        try {
            Order order = new Order(req);
            order = orderRepository.save(order);
            auditService.logOrderCreated(order);  // REQUIRES_NEW: independent TX
            return order;
        } catch (PaymentException e) {
            auditService.logOrderFailed(req, e);  // still logged even on rollback
            throw e;  // rethrow -> rolls back the main TX
        }
    }
}

@Service
public class AuditService {
    
    private final AuditRepository auditRepository;
    
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void logOrderCreated(Order order) {
        auditRepository.save(new AuditLog(
            "ORDER_CREATED", order.getId(), Instant.now()));
        // Own transaction: committed regardless of outer TX outcome.
    }
    
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void logOrderFailed(CreateOrderRequest req, Exception e) {
        auditRepository.save(new AuditLog(
            "ORDER_FAILED", null, e.getMessage(), Instant.now()));
        // Own transaction: committed even though outer TX is rolling back.
    }
}
```

> **Code walkthrough:** `logOrderCreated` and `logOrderFailed` use `REQUIRES_NEW` so each audit
> log entry gets its own independent transaction. If `createOrder`'s main transaction rolls back
> (e.g., PaymentException), the audit log entries are still committed (their REQUIRES_NEW transactions
> are not affected). Without REQUIRES_NEW: the audit logs would be rolled back with the order,
> losing the failure audit trail.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `@Transactional`: auto commit/rollback. Rollback on RuntimeException. `readOnly=true` for read
> methods. Don't call `@Transactional` methods from within the same class (self-invocation bypasses
> the proxy). Propagation: `REQUIRED` (default). `REQUIRES_NEW` for independent transactions.

---

**Senior / Staff (5+ years):**
> `@Transactional` on repository methods: Spring Data applies `readOnly=true` automatically on
> finder methods. Override with `@Transactional(readOnly=false)` if needed. The self-invocation
> proxy bypass is the #1 `@Transactional` debugging issue in production. Isolation level tuning:
> in PostgreSQL, `SERIALIZABLE` eliminates phantom reads but causes serialization failures under
> concurrent load (retry logic needed). `READ_COMMITTED` + `@Version` optimistic locking: correct
> for most use cases with better concurrency.

---

### ⚠️ Common Misconceptions

**Misconception: "`@Transactional` on a private method works."**
`@Transactional` on a private method: Spring cannot create a proxy for it. The annotation is
silently ignored. The method runs without a transaction. This is a common source of "transaction
not starting" bugs that are hard to detect because: (1) no error is thrown, (2) the code may work
for small data sets (auto-commit mode on some DBs), (3) the issue only manifests when partial
failure reveals missing atomicity. Rule: `@Transactional` must be on public methods of Spring beans
(called via the Spring proxy). For transaction demarcation on a private method: extract it to a
public method in a separate bean.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Exception thrown but DB changes not rolled back.**
```
Symptom: createOrder() throws UserNotFoundException.
  Order is partially created in DB. Customer balance deducted.
  Exception logged. No rollback.

Root cause: UserNotFoundException extends Exception (checked).
  Default rollback: only RuntimeException.
  Spring: sees Exception -> no rollback -> commits partial work.

Diagnosis:
  Check exception hierarchy: does it extend RuntimeException or Exception?
  Check @Transactional annotation: is rollbackFor specified?
  
Fix option 1: extend RuntimeException:
  class UserNotFoundException extends RuntimeException { ... }

Fix option 2: add rollbackFor:
  @Transactional(rollbackFor = Exception.class)
  public void createOrder(OrderRequest req) throws UserNotFoundException { ... }

Fix option 3: explicit rollback:
  @Autowired PlatformTransactionManager txManager;
  @Transactional
  public void createOrder(OrderRequest req) throws UserNotFoundException {
      try {
          // ...
      } catch (UserNotFoundException e) {
          TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
          throw e;
      }
  }
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| @Transactional mechanics | 2 minutes |
| Self-invocation bypass | 2 minutes |
| Rollback rules | 2 minutes |
| Propagation REQUIRED vs REQUIRES_NEW | 2 minutes |
| readOnly optimization | 1 minute |
| Isolation levels | 1 minute |
| Transaction on private method | 1 minute |

---

**Q1 (self-invocation): Why doesn't `@Transactional` work when called from within the same class?**

A: Spring `@Transactional` works via a dynamic proxy (AOP). When you inject a Spring bean and call
a `@Transactional` method: the call goes through the Spring proxy, which begins/commits the
transaction. When you call a `@Transactional` method from within the SAME class (self-invocation):
the call bypasses the Spring proxy (direct method call on `this`). The proxy intercepts nothing.
No transaction is started. The method runs in whatever transaction context exists (or none). Fix:
(1) Extract the `@Transactional` method to a separate Spring bean. (2) Inject the bean into itself
(`@Autowired OrderService self`) to go through the proxy. (3) Use AspectJ weaving (compile-time AOP)
instead of proxy-based AOP: weaves transactions directly into bytecode, works for self-invocation.
Option 1 (separate bean) is the cleanest and most maintainable.

*What separates good from great:* The "half-transactional" failure pattern: a service has a public
`@Transactional` method that calls a private `@Transactional(REQUIRES_NEW)` method. The private
method runs in the same transaction (proxy bypass). The developer intends independent transactions
(for audit logging). The audit log is rolled back with the main transaction on failure. Result:
silent loss of audit data on failures - the exact scenario where audit data is most critical.
Detection: enable `logging.level.org.springframework.transaction=TRACE`: shows transaction begin,
commit, rollback for every operation. The trace reveals whether a new transaction was actually
started for the inner method.

---

---

## Entity Lifecycle: Managed, Detached, Removed, and Persist Cascades

---

### 🎯 Model Answer

**30 seconds:**
> JPA entity lifecycle states: Transient (new object, not tracked), Managed (loaded from DB or
> persisted, tracked by persistence context), Detached (session closed, no longer tracked), Removed
> (marked for delete). Key operations: `persist()` -> Transient to Managed, `detach()` -> Managed
> to Detached, `merge()` -> Detached to Managed (copy), `remove()` -> Managed to Removed.

**3 minutes (Senior):**
> Entity lifecycle details:
>
> 1. **Transient**: newly created Java object, no ID assigned (or assigned but not persisted). Not
>    tracked by any persistence context.
>
> 2. **Managed**: tracked by the persistence context. Changes automatically detected. Two ways to
>    become managed: `em.persist(newEntity)` or `em.find(Entity.class, id)` (or Spring Data
>    `findById`, `save`).
>
> 3. **Detached**: was managed, but the persistence context was closed (transaction committed). Or
>    explicitly detached via `em.detach(entity)`. Changes to a detached entity: NOT tracked.
>    Re-attach: `em.merge(detachedEntity)` -> copies detached state to a new managed instance.
>
> 4. **Removed**: `em.remove(managedEntity)` marks it for DELETE. On flush: `DELETE SQL`. Entity
>    becomes transient after delete.
>
> 5. **CascadeType.PERSIST**: `em.persist(parent)` also persists children in the collection.
>    `CascadeType.MERGE`: `em.merge(parent)` merges children. Without cascade: children must be
>    persisted/merged individually.

**Blank Mind Recovery:**

**(1) Restate:** "Transient: new. Managed: tracked, dirty-checked. Detached: untracked (after session close). Removed: marked for DELETE. persist(): Transient -> Managed. merge(): Detached -> Managed (copy). detach(): Managed -> Detached. remove(): -> Removed."

**(2) First principles:** "The persistence context (session) is a unit of work. Managed entities are watched for changes. When the unit of work ends (transaction commits): pending SQL is executed, entities are detached. After detachment: changes invisible to JPA."

**(3) Bridge:** "Entity lifecycle is like a bank transaction with the teller. Transient: you holding cash (not involved with teller). Managed: cash on the teller's desk (tracked). Detached: teller hands it back (transaction complete, no longer tracked). Removed: teller puts it in the void (scheduled for deletion)."

---

### 📘 Concept Explanation

**Entity lifecycle states and transitions:**
```plaintext
LIFECYCLE STATE DIAGRAM:

  new()           persist()         flush()
  Transient  ----------> Managed  ---------> DB INSERT
                          |   ^
                detach()  |   | merge()
                          v   |
                        Detached
  
  Managed  ---remove()--> Removed  --flush()--> DB DELETE
  Managed  ---close()---> Detached  (all managed entities)

MANAGED STATE DETAILS:

  @Transactional
  public void updateProduct(Long id, BigDecimal newPrice) {
      // findById: entity becomes MANAGED.
      Product p = productRepository.findById(id).orElseThrow();
      
      // Change field: persistence context records the change.
      p.setPrice(newPrice);
      
      // No save() needed. Dirty checking on flush:
      // JPA: compares current state to snapshot taken at load time.
      // Changed field detected -> UPDATE SQL generated.
      
      // Transaction commit: flush() called automatically.
      // UPDATE products SET price=? WHERE id=?
  } // Entity becomes DETACHED after transaction commit.

DETACHED STATE DETAILS:

  @Transactional(readOnly = true)
  public Product findProduct(Long id) {
      Product p = productRepository.findById(id).orElseThrow();
      return p;  // Transaction commits here. p is now DETACHED.
  }
  
  // Calling code:
  Product p = service.findProduct(42L);  // DETACHED entity
  p.setPrice(new BigDecimal("99.99"));   // change field
  // Change is NOT tracked. No transaction. Will NOT be saved.
  
  // To re-attach and save:
  @Transactional
  public Product updateDetachedProduct(Product detachedProduct) {
      // merge(): copies detachedProduct's state to a NEW managed entity.
      // Returns the managed copy (NOT the same object as input).
      Product managed = em.merge(detachedProduct);
      // managed: managed state. detachedProduct: still detached.
      return managed;
  }
  
  // merge() internals:
  // 1. Load Product by ID from DB (SELECT).
  // 2. Copy fields from detachedProduct to the loaded entity.
  // 3. Return the loaded (now managed) entity.
  // 4. On commit: dirty checking -> UPDATE with copied fields.

PERSIST CASCADE:

  @Entity
  public class Invoice {
      @OneToMany(mappedBy = "invoice",
                 cascade = CascadeType.PERSIST)  // persist children too
      private List<InvoiceLine> lines = new ArrayList<>();
  }
  
  // Without CascadeType.PERSIST:
  Invoice invoice = new Invoice(...);
  InvoiceLine line1 = new InvoiceLine(...);
  invoice.getLines().add(line1);
  line1.setInvoice(invoice);
  
  em.persist(invoice);  // persists invoice
  em.persist(line1);    // MUST persist line separately (no cascade)
  
  // With CascadeType.PERSIST:
  em.persist(invoice);  // persists invoice AND all lines in the collection
  // No separate em.persist(line1) needed.
  
  // Spring Data save() triggers em.persist (for new) or em.merge (for existing).
  // merge() cascades with CascadeType.MERGE.
  // For Spring Data: CascadeType.ALL (or at least PERSIST+MERGE) is common.

DETACH PATTERN (prevent unintended dirty check):

  // Pattern: load entity, share with untrusted code, but don't want changes saved:
  Product product = productRepository.findById(id).orElseThrow();
  em.detach(product);  // detach BEFORE passing to code that might modify it
  
  // Any modifications to product: not tracked.
  // On commit: no UPDATE generated.
  
  // Use case: read-only service that loads entities for display but should
  // not accidentally save modifications made by display logic.
  // Alternative: use DTO projection (never load the entity at all).
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

---

### 💻 Code Example

> **Code walkthrough:** The merge() behavior is the most misunderstood lifecycle operation.
> The returned managed entity is a different Java object from the input.

```java
// ENTITY LIFECYCLE TRANSITION EXAMPLES:

@Service
public class ProductLifecycleService {
    
    @PersistenceContext EntityManager em;
    
    // persist(): Transient -> Managed:
    @Transactional
    public Product create(String name, BigDecimal price) {
        Product p = new Product(name, price);  // TRANSIENT: no ID, no session
        em.persist(p);         // MANAGED: tracked, scheduled for INSERT
        // p.getId() is null before flush (IDENTITY strategy)
        em.flush();            // INSERT executed, ID assigned
        System.out.println(p.getId());  // now has ID
        return p;
        // After return: p becomes DETACHED (transaction committed)
    }
    
    // merge(): Detached -> Managed (RETURNS A DIFFERENT OBJECT):
    @Transactional
    public Product update(Product detachedProduct) {
        // merge() steps:
        // 1. SELECT product by detachedProduct.id from DB.
        // 2. Copy fields from detachedProduct to the loaded entity.
        // 3. Return the managed copy.
        Product managed = em.merge(detachedProduct);
        
        // Common mistake: continuing to use detachedProduct after merge:
        detachedProduct.setName("New Name");  // BAD: modifying detached, not managed
        // Only changes to 'managed' are tracked.
        
        return managed;
        // Commit: UPDATE SQL with merged fields.
    }
    
    // remove(): Managed -> Removed:
    @Transactional
    public void delete(Long id) {
        Product p = em.find(Product.class, id);  // must be MANAGED before remove
        if (p != null) {
            em.remove(p);  // REMOVED: scheduled for DELETE
            // Cannot do: em.remove(new Product(id)); // Detached entity not allowed
        }
    }
}
```

> **Code walkthrough:** The `create` method shows the Transient-to-Managed transition via `persist`,
> followed by `flush` to execute the INSERT and assign the ID. The `update` method highlights the
> key misunderstanding about `merge`: it returns a NEW managed instance, not the same object. The
> `delete` method shows that `remove` requires a managed entity - you cannot remove a detached
> object by creating a new instance with the ID.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Four states: Transient, Managed, Detached, Removed. Entity is managed within a `@Transactional`
> method. After the method returns: detached. `merge()` re-attaches a detached entity (returns a
> new managed copy). `remove()` requires a managed entity. Cascade: parent operations (persist,
> merge, remove) propagate to children.

---

**Senior / Staff (5+ years):**
> `merge()` executing a SELECT before the UPDATE is a hidden performance cost for update-heavy
> workloads. Alternative: JPQL bulk UPDATE (no SELECT). Or: load within the transaction, modify,
> commit (dirty checking generates just the UPDATE without a merge SELECT). `CascadeType.REMOVE`
> on large collections: generates N individual DELETE statements. Alternative: `DELETE FROM
> table WHERE parent_id = ?` (bulk DELETE, one statement). Lifecycle callbacks (`@PrePersist`,
> `@PostLoad`) for audit fields are cleaner than putting audit logic in every service method.

---

### ⚠️ Common Misconceptions

**Misconception: "`em.merge(entity)` updates the same Java object that was passed in."**
`merge()` returns a NEW managed entity instance. The passed-in entity remains DETACHED. Changes
made to the input entity after calling `merge()` are NOT tracked. Code pattern: `Product updated =
em.merge(detachedProduct); updated.setName("New");` - correct (changes `updated`, which is managed).
`em.merge(detachedProduct); detachedProduct.setName("New");` - wrong (changes `detachedProduct`,
which is still detached and will not be saved). This is a very common bug: developers modify the
original object thinking the merge made it managed.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Detached entity modifications not saved to DB.**
```
Symptom: service method modifies a product and returns it. DB not updated.
  No exception. Just silent data loss.

// Buggy code:
@Transactional(readOnly = true)
public Product findAndModify(Long id) {
    Product p = productRepository.findById(id).orElseThrow();
    p.setName("Modified");   // change on managed entity
    return p;                // transaction commits (readOnly=true)
    // readOnly transaction: Hibernate may SKIP dirty checking.
    // Or: dirty check runs but readOnly transaction commits without UPDATE.
}

// Even without readOnly: transaction committed, then:
// Caller receives DETACHED entity.
// Caller modifies it. Change not tracked.

Fix: ensure writes happen within a read-write @Transactional:
@Transactional  // read-write
public Product modify(Long id) {
    Product p = productRepository.findById(id).orElseThrow();
    p.setName("Modified");  // managed, will be dirty-checked
    return p;
    // Transaction commits: UPDATE generated. Correct.
}
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using @Transactional. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Entity lifecycle states | 2 minutes |
| Transient vs Managed | 1 minute |
| Managed vs Detached | 1 minute |
| merge() internals | 2 minutes |
| CascadeType selection | 1 minute |
| orphanRemoval | 1 minute |
| Lifecycle callbacks | 1 minute |

---

**Q1 (merge): What does `em.merge()` do, and what is the common mistake developers make with it?**

A: `em.merge(detachedEntity)`: (1) Checks if there's already a managed entity with the same ID in
the current persistence context. If yes: copies the detached state onto the managed entity. If no:
loads the entity from the DB (SELECT), then copies the detached state. (2) Returns the managed
entity. The detached input remains detached. Common mistake: continuing to modify the input entity
after calling merge. Example: `em.merge(product); product.setName("New Name");` - the `product`
variable still points to the detached entity. The name change is not tracked. Only changes to the
RETURNED managed entity are tracked. Pattern: `Product managed = em.merge(product); managed.setName("New Name");`

*What separates good from great:* The "merge SELECT penalty" and when to avoid it. Every `merge()`
with an existing entity: executes a SELECT before the UPDATE. If you're updating 1,000 entities:
1,000 SELECTs + 1,000 UPDATEs = 2,000 DB operations. Alternative for known updates: JPQL bulk UPDATE
(0 SELECTs + 1 UPDATE = 1 operation). For Spring Data users: calling `save(existingEntity)` on a
non-managed entity calls `merge()` internally (also executes a SELECT). If the entity was loaded in
the same transaction: it's already managed, and `save()` is a no-op (dirty checking handles the
UPDATE). The merge SELECT is only necessary when operating with detached entities. Design to minimize
detached entity operations: load and modify within the same transaction.

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



