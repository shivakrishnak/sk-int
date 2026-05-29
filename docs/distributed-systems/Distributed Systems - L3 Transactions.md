---
layout: default
title: "Distributed Systems - L3 Transactions"
parent: "Distributed Systems"
grand_parent: "SK Interview"
nav_order: 8
permalink: /distributed-systems/l3-transactions/
---

# Distributed Transactions and Two-Phase Commit

**TL;DR:** Distributed transactions guarantee ACID properties across
multiple services or databases. Two-Phase Commit (2PC) is the classic
protocol: Phase 1 (prepare) asks all participants if they can commit;
Phase 2 (commit or abort) executes the outcome. 2PC is blocking
on coordinator failure and suffers from the blocking problem. In
modern microservices, 2PC is largely replaced by the Saga pattern
or idempotent operations.

---

### 🎯 Model Answer

**30 seconds:**
> A distributed transaction coordinates changes across multiple
> services or databases atomically - all commit or all abort.
> Two-Phase Commit (2PC) is the classic protocol: the coordinator
> asks all participants to prepare (vote), then commits or aborts
> based on unanimous agreement. 2PC is blocking: if the coordinator
> crashes after prepare but before commit, participants are
> blocked indefinitely. This is why modern systems avoid 2PC and
> use Sagas instead.

**3 minutes:**
> Distributed transactions solve the problem of coordinating writes
> across multiple systems atomically. Example: transfer money from
> bank A to bank B. You need to debit A AND credit B, with neither
> partial failure possible. In a single database, a transaction
> handles this. Across two databases, you need coordination.
>
> 2PC: Phase 1 (prepare) - the coordinator (transaction manager)
> sends "prepare" to both databases. Each database persists its
> prepared state to disk (so it can commit even after a restart)
> and votes yes or no. Phase 2 (commit/abort) - if all votes are
> yes, the coordinator sends "commit" to all participants. If any
> vote is no, the coordinator sends "abort."
>
> The fundamental problem: the coordinator is a SPOF. If the
> coordinator crashes after sending "prepare" but before deciding
> commit or abort, participants are in a "prepared" state -
> they hold locks and cannot proceed or abort on their own. They
> are blocked until the coordinator recovers. This is the "blocking
> problem" of 2PC.
>
> 3PC (Three-Phase Commit) was designed to address this by adding
> a "pre-commit" phase, but introduces its own problems under
> network partitions. In practice, XA transactions (2PC standard)
> are used in enterprise systems (JTA in Java EE). Modern cloud
> microservices use Sagas instead.

**Blank Mind Recovery:**

**(1) Restate:** "2PC - a protocol for atomically committing a
transaction across multiple databases. Two phases: prepare, then
commit or abort."

**(2) First principles:** "Any distributed commit needs agreement.
If you just send 'commit' to both systems simultaneously, a network
failure means one commits and one does not. 2PC solves this by
first asking both 'can you commit?' before actually committing."

**(3) Bridge:** "Like organizing a wedding: first the planner asks
all vendors 'can you be there on date X?' All must say yes before
confirming. If any says no: cancel all. If the planner disappears
after asking but before confirming: all vendors are on hold,
unable to take other bookings."

---

### 📘 Concept Explanation

**What it is:**
A distributed transaction protocol that coordinates atomic commits
across multiple data stores or services, ensuring all-or-nothing
semantics across the distributed system.

**The problem it solves:**
Writes to multiple independent systems are not atomic by default.
Without coordination, a failure between writes leaves the system
in a partial state: money debited from source account but not
credited to destination.

**2PC Protocol:**

```
Phase 1: PREPARE

Coordinator → Participant A: "PREPARE txn_id=123"
Coordinator → Participant B: "PREPARE txn_id=123"

Participant A:
  - Write prepare log to durable storage
  - Acquire locks on affected rows
  - Reply: VOTE_COMMIT (or VOTE_ABORT if error)

Participant B:
  - Same as A
  - Reply: VOTE_COMMIT

Phase 2: COMMIT (if all voted COMMIT)

Coordinator:
  - Write COMMIT decision to durable log
  - Send COMMIT to all participants

Participant A: execute commit, release locks
Participant B: execute commit, release locks

Phase 2: ABORT (if any voted ABORT)

Coordinator sends ABORT to all participants.
All participants roll back their prepared writes.
```

**The blocking problem:**

```
Timeline:
[Coordinator sends PREPARE to A and B]
[Both vote COMMIT]
[Coordinator writes COMMIT to log]
[Coordinator crashes HERE]

Participants A and B:
  - Are in "prepared" state
  - Hold locks on affected rows
  - Cannot proceed (do not know the decision)
  - Cannot abort (they voted COMMIT - aborting
    now violates the protocol)
  - BLOCKED until coordinator recovers

If coordinator takes 2 hours to recover:
  - A and B hold locks for 2 hours
  - All queries on those rows are blocked
```

**XA Transactions (Java EE / JTA):**

```java
// XA is the standard for distributed transactions
// (2PC underlying protocol)
UserTransaction tx = ctx.lookup(
    "java:comp/UserTransaction");
tx.begin();
// All resource managers (DB connections, JMS)
// automatically enlist in the XA transaction
dbConnectionA.update(...); // enlists in XA
dbConnectionB.update(...); // enlists in XA
jmsSession.send(...);       // enlists in XA
tx.commit(); // 2PC across all three resources
```

**The key insight:**
2PC trades availability for consistency: participants must wait
for the coordinator's decision. During the blocking window, the
system is unavailable for the affected rows. CAP theorem applies:
2PC is CP (consistent, not available during coordinator failure).

**When to use it:**
- Enterprise systems with existing XA-capable infrastructure
- Cross-database transactions where ACID is mandatory and
  blocking is acceptable (low-volume financial operations
  within a single organization's systems)

**When NOT to use it:**
- Microservices across organizational boundaries
- Systems requiring high availability
- Operations spanning more than 2-3 services
- Cloud-native systems (most cloud databases do not support XA)

**Alternatives:**
- Saga pattern: choreography or orchestration of compensating
  transactions - no distributed lock
- Outbox pattern: write to local DB + message queue in one
  local transaction; no 2PC needed
- Try-Confirm-Cancel (TCC): application-level compensation

**First-principles derivation:**
"Any multi-party agreement requires two steps: ask everyone if
they can agree (prepare), then confirm the agreement (commit).
This is 2PC. The flaw: the coordinator who knows the outcome can
fail. 3PC tries to add a third step to address this but introduces
other problems. The modern solution: avoid distributed transactions
entirely by using compensating transactions (Sagas)."

---

### 💻 Code Example

```java
// DISTRIBUTED TRANSACTION COMPARISON

// BAD: two separate database updates, no transaction
// (partial failure risk)
public void transferMoney(
        String fromId, String toId,
        BigDecimal amount) {
    // BAD: if this succeeds but the next fails,
    // money disappears (debited, not credited)
    accountDb.debitAccount(fromId, amount);
    // CRASH HERE? Money is gone.
    accountDb.creditAccount(toId, amount);
    // No atomicity: partial failure creates
    // inconsistent state
}

// ACCEPTABLE (same DB): local transaction
@Transactional
public void transferMoneyLocal(
        String fromId, String toId,
        BigDecimal amount) {
    accountRepository.debit(fromId, amount);
    accountRepository.credit(toId, amount);
    // Spring @Transactional wraps both in one
    // local DB transaction: atomic, consistent
}

// MODERN PATTERN: Outbox pattern
// (avoids 2PC for cross-service events)
@Transactional // single local transaction
public void transferMoney(TransferRequest req) {
    // 1. Update account balance (local DB)
    account.debit(req.getFromId(), req.getAmount());

    // 2. Write to outbox table (same local DB)
    // This is atomic with the balance update
    OutboxEvent event = OutboxEvent.builder()
        .type("MoneyTransferred")
        .payload(toJson(req))
        .status(PENDING)
        .build();
    outboxRepository.save(event);

    // Both writes in the SAME local transaction:
    // either both commit or both rollback.
    // No 2PC, no distributed lock.
}
// A separate outbox poller reads PENDING events
// and publishes to Kafka/SQS.
// Consumer credits the target account and
// marks the event as PROCESSED.
```

> **Code walkthrough:** The BAD pattern shows the partial failure
> problem directly - money debited but not credited. The ACCEPTABLE
> pattern works only if both accounts are in the same database.
> The MODERN pattern uses the Outbox pattern: both the account
> debit and the event record are written in a single local database
> transaction - no 2PC needed. The outbox poller asynchronously
> publishes the event. The consumer credits the target account.
> This is eventually consistent (the credit happens asynchronously)
> but avoids the blocking problem of 2PC. The trade-off: a brief
> window where the source account is debited but the target is
> not yet credited - acceptable for most applications.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> 2PC coordinates transactions across multiple databases. Phase 1:
> ask all participants to prepare (acquire locks, persist prepared
> state). Phase 2: commit if all agreed, abort if any disagreed.
> The problem: if the coordinator crashes during phase 2, all
> participants are blocked. Modern microservices prefer the Saga
> pattern which uses compensating transactions instead of distributed
> locks.

---

**Senior / Staff:**
> I avoid 2PC in microservices. The blocking problem and the
> requirement for all services to support XA makes it impractical.
> Instead: the Outbox pattern for local consistency + async
> messaging for eventual consistency across services. For cases
> that truly need coordination: Saga with orchestration
> (transaction coordinator tracks the saga state, retries on
> failure, issues compensating transactions on abort). The key
> insight: Sagas provide eventual consistency, not ACID isolation.
> Two Sagas running concurrently can see each other's partial
> state.

---

### ⚠️ Common Misconceptions

**"2PC guarantees no data loss"**

Reality: 2PC guarantees atomicity (all or nothing), but the
coordinator failure creates a window where participants are
blocked (not making progress). If the coordinator's log is
corrupted (not just crashed), the outcome of the transaction may
be permanently unknown. The participants are then "in doubt"
indefinitely. Most real-world 2PC implementations use a
transaction coordinator with durable logging and automatic
recovery to minimize this window - but it cannot be fully
eliminated.

**"Microservices can use 2PC if all services have XA-compatible databases"**

Reality: even if technically possible, XA across microservices is
an architectural anti-pattern. It tightly couples services at the
protocol level. The performance impact of holding locks across
network calls (including external service calls with variable
latency) makes XA impractical for high-throughput microservices.
The design alternative is to accept eventual consistency across
services and use compensating transactions.

---

### ⚖️ Comparison Table

| Protocol | Atomicity | Blocking | Availability | Use When |
|---|---|---|---|---|
| Local transaction | ACID | No | High | Same DB |
| 2PC / XA | ACID | Yes | Low | Legacy enterprise, same org |
| Saga (choreography) | Eventual | No | High | Microservices, async |
| Saga (orchestration) | Eventual | No | High | Complex workflows |
| Outbox + consumer | Eventual | No | High | Event-driven, simple |
| TCC (Try-Confirm-Cancel) | Strong | Brief | Medium | Business compensation |

**The deciding factor:** Can you tolerate eventual consistency?
If yes: Saga or Outbox. If no and you control all participants:
2PC as last resort. If no and you use microservices: rethink
the domain boundaries.

---

### 🔥 Field Q&A

#### Production Failures

Q: An XA transaction is blocking database reads on critical
tables. The coordinator service is down. How do you recover?

A: Participants are in "in-doubt" state holding locks. Recovery
steps: (1) Restart the coordinator service. It reads its
transaction log and resolves in-doubt transactions by either
committing or aborting based on logged decisions. (2) If the
coordinator log is unavailable: manually resolve the in-doubt
transaction. In MySQL XA: `XA RECOVER` lists in-doubt transactions.
`XA COMMIT` or `XA ROLLBACK` manually resolves them. (3) Check
the log of the other participant to determine the intended outcome
before manually resolving. (4) After recovery: add monitoring to
alert on in-doubt XA transactions immediately. (5) Long-term:
migrate to Saga pattern to eliminate XA dependency.

#### Candidate Mistakes

Q: When would you use a distributed transaction in a
microservices architecture?

**What NOT to say:** "Whenever I need ACID across multiple services."

**Say instead:** "Almost never. Distributed transactions (2PC/XA)
in microservices create tight coupling and blocking failures.
Instead, I design for eventual consistency: (1) the Saga pattern
for multi-step business transactions with compensating actions,
(2) the Outbox pattern for reliable event publishing without 2PC.
The only case where I would consider 2PC: two internal databases
within the same service (not across service boundaries), both
supporting XA, and where eventual consistency is truly unacceptable.
Even then, I would first ask whether the two databases should be
combined into one."

---

---

# Saga Pattern

**TL;DR:** The Saga pattern manages distributed transactions without
two-phase commit. A saga is a sequence of local transactions, each
publishing an event that triggers the next. If any step fails, the
saga executes compensating transactions in reverse to undo completed
steps. Two variants: choreography (event-driven, decentralized) and
orchestration (central saga orchestrator coordinates steps). Sagas
provide eventual consistency, not ACID isolation.

---

### 🎯 Model Answer

**30 seconds:**
> The Saga pattern replaces distributed transactions with a sequence
> of local transactions. Each local transaction publishes an event.
> If a step fails, compensating transactions undo the completed steps.
> Two variants: choreography (each service listens to events from
> the prior service) and orchestration (a central orchestrator
> commands each service). Sagas are eventually consistent - no
> isolation between concurrent sagas.

**3 minutes:**
> 2PC holds locks across all participants until the final commit.
> This is blocking and limits availability. Sagas break the distributed
> transaction into a series of local transactions, each atomic within
> its own database.
>
> Example: place an order. (1) OrderService creates order in PENDING
> state (local transaction). Publishes OrderCreated event.
> (2) PaymentService processes payment (local transaction). Publishes
> PaymentProcessed. (3) InventoryService reserves stock (local
> transaction). If stock unavailable: publishes InventoryFailed.
> (4) On InventoryFailed: OrderService compensates by canceling
> the order; PaymentService compensates by refunding.
>
> Key difference from 2PC: no locks span multiple services. Each
> local transaction commits immediately. If a later step fails,
> compensating transactions reverse the completed steps. This is
> "backward recovery." Compensating transactions must be idempotent
> (retried on failure) and designed for eventual execution (the
> compensation may run minutes after the original transaction).
>
> Choreography vs. Orchestration: choreography is decentralized -
> each service subscribes to relevant events and reacts. Simpler
> for small sagas but harder to trace and debug as sagas grow.
> Orchestration has a central coordinator (saga orchestrator) that
> sends commands to services. Easier to reason about the flow,
> easier to debug, but the orchestrator is a new service to maintain.

**Blank Mind Recovery:**

**(1) Restate:** "Saga - a sequence of local transactions with
compensating transactions to undo on failure. No distributed
locking."

**(2) First principles:** "Instead of locking all resources and
atomically committing: commit each step locally and immediately.
If a later step fails: run compensating actions to reverse earlier
steps. Eventually consistent - not immediately atomic."

**(3) Bridge:** "Like booking a vacation: first book flight, then
hotel, then car. If the car is unavailable: cancel the hotel, then
cancel the flight. Each booking is committed immediately; failures
trigger reverse bookings. This is a saga."

---

### 📘 Concept Explanation

**What it is:**
A sequence of local database transactions, each completing and
publishing an event, with compensating transactions to undo
completed steps if any step fails.

**The problem it solves:**
Distributed transactions (2PC) require all participants to hold
locks until the coordinator commits. This is blocking and impractical
for microservices. Sagas provide eventual atomicity without
distributed locking.

**Saga variants:**

**Choreography-based Saga:**
```
OrderService             PaymentService         InventoryService
    |                         |                       |
    |--[OrderCreated]-------->|                       |
    |                    process payment              |
    |                    [PaymentProcessed]---------->|
    |                         |               reserve stock
    |<--[StockReserved]------------------------------[|
    |  finalize order          |                       |
    |                         |                       |
    --- Failure path ---
    |                         |       [StockFailed]-->|
    |<--[PaymentRefundNeeded]--[compensate payment]    |
    |  cancel order            |                       |
```

**Orchestration-based Saga:**
```
SagaOrchestrator
    |--[PlaceOrder cmd]-------> OrderService
    |<-- OrderCreated ----------|
    |--[ProcessPayment cmd]---> PaymentService
    |<-- PaymentProcessed ------|
    |--[ReserveStock cmd]-----> InventoryService
    |<-- StockFailed -----------|
    |--[RefundPayment cmd]----> PaymentService
    |<-- PaymentRefunded -------|
    |--[CancelOrder cmd]------> OrderService
    |<-- OrderCancelled --------|
```

**Compensating transactions:**
```
Original:                    Compensation:
Create order (PENDING)  -->  Cancel order (CANCELLED)
Process payment         -->  Refund payment
Reserve inventory       -->  Release reservation
Send email              -->  Send cancellation email
                              (cannot unsend email,
                               so a compensating action
                               is sent instead)
```

**Isolation (the critical gap vs. 2PC):**
```
Saga A: Create order -> Process payment -> ...
Saga B: Create order -> Process payment -> ...

Both sagas run concurrently. Saga B may observe Saga A's
intermediate state: an order created but not yet paid.
This is "dirty read" equivalent in Sagas.

This is called: lost update, dirty read, non-repeatable read
at saga level.

Mitigations:
- Semantic locks: mark records as "PENDING" so other sagas
  know they are in-flight
- Order by: process the same entity in a canonical order
- Countermeasures: design compensations to handle
  partial state
```

**The key insight:**
Sagas provide *atomicity* (eventually, all steps complete OR
all are compensated) but not *isolation* (concurrent sagas
can see each other's partial state). The "ACI" properties
of ACID are available; the "I" (isolation) is not.

**When to use it:**
- Long-running business transactions (order fulfillment)
- Transactions that span multiple microservices
- Workflows where individual steps may take minutes to hours
- Any distributed operation where 2PC is impractical

**When NOT to use it:**
- Short, single-database transactions (use local ACID instead)
- Operations where intermediate state visibility is
  unacceptable (use 2PC or redesign to single service)
- When compensating transactions cannot be designed
  (some operations are not reversible)

**Alternatives:**
- 2PC / XA: for strong isolation requirement within same org
- Outbox pattern: simpler alternative for single-step
  async events

**First-principles derivation:**
"ACID transactions solve partial failure by rolling back. In
distributed systems, rollback requires coordination (2PC). Instead:
accept that individual steps are committed, but design a reverse
path (compensation) for failures. This trades isolation for
availability - each step commits immediately without waiting for
global agreement."

---

### 💻 Code Example

```java
// SAGA ORCHESTRATION WITH SPRING STATE MACHINE

// BAD: calling multiple services in sequence without
// compensation logic (brittle, no rollback on failure)
public void placeOrder(Order order) {
    paymentService.charge(order.getCustomerId(),
        order.getAmount()); // What if next line fails?
    inventoryService.reserve(order.getItems());
    // BAD: payment charged, stock not reserved,
    // customer charged for nothing
    orderRepository.save(order);
}

// GOOD: Saga orchestrator with compensation
@Service
public class OrderSagaOrchestrator {

    // State machine: PENDING -> PAYMENT_PROCESSING
    // -> INVENTORY_RESERVING -> COMPLETED
    // Failure path: -> PAYMENT_REFUNDING -> FAILED

    public void execute(CreateOrderCommand cmd) {
        SagaState state = SagaState.create(cmd);
        sagaRepository.save(state);

        try {
            // Step 1: Create order (local transaction)
            Order order = orderService.create(cmd);
            state.recordStep(OrderCreated, order.getId());
            sagaRepository.save(state);

            // Step 2: Process payment
            PaymentResult payment =
                paymentService.charge(
                    cmd.getCustomerId(),
                    cmd.getAmount());
            state.recordStep(PaymentCharged,
                payment.getId());
            sagaRepository.save(state);

            // Step 3: Reserve inventory
            inventoryService.reserve(cmd.getItems());
            state.complete();
            sagaRepository.save(state);

        } catch (PaymentException e) {
            // Payment failed: compensate step 1
            compensate(state);
        } catch (InventoryException e) {
            // Inventory failed: compensate steps 1+2
            compensate(state);
        }
    }

    private void compensate(SagaState state) {
        // Execute compensations in reverse order
        // Each compensation is idempotent (retry-safe)
        for (SagaStep step : state.getCompletedReversed()) {
            switch (step.getType()) {
                case PaymentCharged:
                    // Compensation: refund payment
                    // Idempotent: if already refunded, no-op
                    paymentService.refund(step.getRef());
                    break;
                case OrderCreated:
                    // Compensation: cancel order
                    orderService.cancel(step.getRef());
                    break;
            }
        }
        state.fail();
        sagaRepository.save(state);
    }
}
```

> **Code walkthrough:** The BAD pattern calls services sequentially
> with no compensation - an exception between the payment charge
> and the order save leaves the customer charged for an order that
> was never created. The GOOD pattern implements an orchestrated
> saga: each step's result is persisted in `SagaState` before
> proceeding to the next step. On failure, compensating actions
> run in reverse order. Each compensation is idempotent (a payment
> that is already refunded does nothing when refunded again),
> enabling safe retries. The SagaState is persisted in the
> orchestrator's local database - if the orchestrator crashes,
> it can resume from the last recorded state.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> The Saga pattern breaks a distributed transaction into local
> transactions with compensating actions for failure. No distributed
> locking. Two variants: choreography (event-driven, decentralized)
> and orchestration (central coordinator). Sagas are eventually
> consistent - no ACID isolation across steps.

---

**Senior / Staff:**
> The hardest part of Sagas in production is the lack of isolation.
> Two concurrent sagas can see each other's partial state. Semantic
> locks mitigate this: when an order is in progress, mark it
> PENDING so other processes know not to act on it. The other hard
> part: compensating transactions that cannot undo an action (sending
> an email, calling an external payment API that already charged).
> For truly irreversible actions: use pivot transactions (the point
> of no return) and design compensations as explicit business actions
> (send a cancellation email, issue a refund) rather than true
> rollbacks.

---

### ⚠️ Common Misconceptions

**"Sagas provide the same guarantees as 2PC transactions"**

Reality: Sagas provide atomicity (eventually) but NOT isolation.
Concurrent sagas can observe each other's partial state. A Saga is
not a transaction replacement - it is a business workflow with
failure recovery. The developer must explicitly design for the lack
of isolation (semantic locks, countermeasures, idempotent operations).

**"Choreography is always better than orchestration because it is
more decoupled"**

Reality: choreography is more decoupled at the service level, but
the saga workflow is implicit in the events and handlers. When a
choreography-based saga has 8 steps, understanding the full flow
requires reading 8 different services' event handlers. Debugging
failures requires tracing events across all services. Orchestration
makes the saga flow explicit in one place (the orchestrator), which
is easier to reason about and debug in production. Neither is
universally better - choreography for simple, stable flows;
orchestration for complex, changing workflows.

---

### ⚖️ Comparison Table

| Aspect | Choreography | Orchestration | 2PC |
|---|---|---|---|
| Coupling | Loose (events) | Medium (orchestrator) | Tight (protocol) |
| Observability | Hard (distributed) | Easy (one place) | Easy |
| Complexity | Low (per service) | Medium (orchestrator) | High (XA) |
| Failure tracing | Hard | Easy | Medium |
| Scalability | High | Medium | Low |
| Isolation | None | None | ACID |
| Choose for | Simple, stable | Complex, changing | Same-org, legacy |

---

### 🔥 Field Q&A

#### Production Failures

Q: An order saga got stuck in PAYMENT_REFUNDING state for 48 hours.
No compensation has completed. What do you investigate?

A: The payment refund compensation is failing and retries are
exhausted or not configured. Investigation: (1) Check the saga
state table for the specific saga ID - what step is failing,
and what is the last error recorded? (2) Check the payment service
logs for refund attempts. Is the payment service returning errors?
Is the payment provider API down? (3) Check if the compensation
is idempotent - if the refund was already issued but the saga
state was not updated (saga orchestrator crashed after issuing
the refund but before recording completion), retrying would try
to refund again. An idempotent compensation would return success
for an already-processed refund. Fix: implement idempotency in
the compensation (check before acting). Retry the compensation.
Add a dead-letter queue for permanently failed sagas that require
manual intervention. Add SLA alerts: if a saga is stuck for > 1
hour, alert on-call.

#### Candidate Mistakes

Q: How do you handle a scenario where a Saga step calls an
external payment API that cannot be idempotent?

**What NOT to say:** "Make the call and hope it does not fail twice."

**Say instead:** "For external payment APIs, I implement idempotency
at the application level using an idempotency key. Before calling
the API, I generate a UUID for this specific saga step and store it
in the saga state. I pass this UUID as the idempotency key in the
payment API request. If the call fails and I retry, I use the same
UUID. The payment provider uses the idempotency key to detect
and deduplicate the retry. If the first call succeeded but my
network connection dropped before I received the response, the
retry with the same idempotency key returns the original success
result without double-charging. Stripe, Braintree, and most
modern payment APIs support this pattern natively."

### 🚨 Failure Modes and Diagnosis

**In-doubt XA transaction blocking the database:**

Symptom: database queries on specific rows time out; `SHOW PROCESSLIST`
shows threads waiting for locks; `XA RECOVER` returns in-doubt
transaction IDs.

Cause: XA transaction coordinator failed after participants voted
COMMIT but before the coordinator sent the final COMMIT/ABORT.

Diagnosis: `XA RECOVER` in MySQL lists all in-doubt XA transactions
with their XIDs. Check coordinator logs to determine the intended
decision. If coordinator logs are intact: restart coordinator (it
will auto-resolve). If coordinator logs are lost: must manually
decide based on other participants' state.

Fix: `XA COMMIT 'xid'` or `XA ROLLBACK 'xid'` in MySQL to manually
resolve. Only do this after confirming the decision from the
coordinator's backup log or the other participants' state.
Prevention: use distributed transaction coordinator with durable
log replication (not just a single-point coordinator).

**Heuristic completion leaving inconsistent state:**

Symptom: some participants committed, others aborted; data is
inconsistent across databases.

Cause: after a long blocking period (coordinator down), a DBA
manually forced a "heuristic decision" (forced rollback or commit
on one participant without coordinator agreement).

Diagnosis: compare the state of all participants for the affected
transaction. Check which committed and which rolled back.

Fix: determine the correct business state. Write compensating
SQL to bring the inconsistent participant(s) into alignment.
This is manual and risky. Prevention: avoid heuristic completions
entirely; let the coordinator resolve.

---

### 🏛️ System Design

*(Omit: 2PC and XA are protocol-level patterns. System design
for distributed transactions across microservices is best covered
under the Saga Pattern (next keyword in this file) and the
L5 Migration Strategy file.)*

---

### 📊 Diagram

*(Omit: 2PC protocol flow is described fully in the Concept
Explanation pseudocode. A visual sequence diagram adds limited
value over the textual representation.)*

---

### 🎯 Interview Deep-Dive

| Question Type | Count | Timing |
|---|---|---|
| Conceptual | 3 | 2 min each |
| Trade-off | 2 | 3 min each |
| Debugging | 2 | 3 min each |
| Behavioral | 1 | 4 min |
| Scale | 1 | 3 min |

---

**Q1 (Conceptual): Explain why 2PC is called a "blocking"
protocol and what specific failure scenario causes blocking.**

2PC is blocking because participants cannot make progress
(commit or abort) independently if the coordinator fails at
a specific point.

The exact failure scenario:
1. Coordinator sends PREPARE to all participants
2. All participants vote COMMIT (they have written
   prepared state to disk and are locked)
3. Coordinator writes COMMIT decision to its log
4. Coordinator crashes before sending COMMIT to participants
5. Coordinator comes back online after recovery

During the window between step 4 and recovery:
- Participants are in "prepared" state
- They hold locks on all affected rows
- They cannot unilaterally abort (they voted COMMIT)
- They cannot unilaterally commit (they do not have the
  coordinator's permission)
- They are blocked: waiting for the coordinator

This is the blocking problem. If the coordinator takes 30
minutes to recover: all locks are held for 30 minutes.
If the coordinator's log is corrupted and unrecoverable:
participants are blocked permanently.

*What separates good from great:* Great candidates explain
why participants cannot unilaterally commit or abort. A
unilateral commit might mean the other participant aborted
(data inconsistency). A unilateral abort might mean the
other participant committed (also inconsistency). The
participants genuinely cannot proceed safely without the
coordinator's decision.

---

**Q2 (Conceptual): What is the XA specification and how does
Java implement it with JTA?**

XA is a specification from The Open Group that defines an
interface between a transaction manager and resource managers
(databases, message queues) for distributed transactions.
XA defines two calls: `xa_prepare()` and `xa_commit()` /
`xa_rollback()` - the 2PC protocol.

Java EE implements XA through JTA (Java Transaction API) and
JTS (Java Transaction Service):

- `UserTransaction` interface: application-level transaction
  boundaries (`begin()`, `commit()`, `rollback()`)
- `TransactionManager`: manages the 2PC protocol on the
  application server side
- `XADataSource` / `XAConnection`: JDBC connections that
  support the XA protocol (enlisted automatically by the
  transaction manager)
- `XAResource`: the resource manager interface that implements
  `prepare()`, `commit()`, `rollback()`, `recover()`

When you use `@Transactional` in Spring and have two different
`XADataSource` beans: Spring's `JtaTransactionManager` (or the
app server's TM) automatically orchestrates 2PC across both
data sources transparently.

*What separates good from great:* Knowing that non-XA data sources
(regular `DataSource`) cannot participate in XA transactions.
A common mistake is mixing XA and non-XA resources in the same
transaction - the non-XA resource does not participate in the
2PC and can commit before the coordinator decides.

---

**Q3 (Conceptual): Why is 3PC not widely used despite being
designed to fix 2PC's blocking problem?**

3PC adds a "pre-commit" phase between prepare and commit:
1. Prepare: ask participants if they can commit
2. Pre-commit: coordinator sends "yes, all agreed, prepare
   to commit"
3. Commit: final commit

This allows participants to commit autonomously if they see
pre-commit and lose connection to the coordinator. In 2PC,
participants in prepared state cannot act autonomously. In 3PC,
participants in pre-commit state know everyone voted COMMIT,
so they can safely commit unilaterally.

Why 3PC is not widely used:
1. **Network partitions break the assumption:** 3PC assumes
   fail-stop failures (crashes, not network partitions). In a
   network partition, some nodes might be in pre-commit and
   some in prepared state. The pre-commit nodes commit; the
   prepared nodes time out and abort. Result: split-brain.
2. **Three round trips instead of two:** worse latency.
3. **Paxos/Raft do it better:** Paxos consensus achieves
   non-blocking agreement under network partitions. Modern
   systems use Paxos/Raft rather than 3PC.

*What separates good from great:* Knowing that 3PC assumes
crash-stop failures and fails under network partitions. This is
a nuanced point that demonstrates deep understanding of distributed
systems failure modes.

---

**Q4 (Trade-off): When should you use the Outbox pattern vs.
the Saga pattern for cross-service data consistency?**

Outbox pattern: best for publishing domain events reliably as a
side effect of a local business operation. Example: when an order
is created, reliably publish `OrderCreated` event to Kafka.
The event is written to an outbox table in the same local
transaction as the order. An outbox poller (or CDC - Change Data
Capture) publishes the event to Kafka asynchronously.

Use Outbox when: there is one primary database operation and you
need to reliably notify downstream services. No compensation
needed - if the downstream service fails, it retries consuming
the event. Simple, low overhead.

Saga pattern: best for multi-step business workflows that span
multiple services, where failure at any step requires explicit
compensation of completed steps.

Use Saga when: there are multiple sequential service calls that
form a business unit (order → payment → inventory). Failure of
any step must trigger explicit undo of previous steps.

Combination: Outbox is often used within a Saga. The saga
orchestrator writes to its state table AND an outbox table in the
same local transaction, ensuring reliable command delivery to
participants.

*What separates good from great:* Correctly identifying that the
Outbox pattern is a messaging reliability pattern, not a
transaction pattern. It solves the "at-least-once delivery to
Kafka" problem, not the "multi-step distributed transaction" problem.

---

**Q5 (Trade-off): Describe the consistency guarantees of a Saga
vs. a 2PC transaction. What does a Saga NOT guarantee?**

A 2PC transaction provides ACID:
- Atomicity: all-or-nothing (within the 2PC window)
- Consistency: business rules are maintained atomically
- Isolation: concurrent transactions cannot see each other's
  intermediate state (using locking or MVCC)
- Durability: committed data persists

A Saga provides:
- Atomicity (eventually): either all saga steps complete OR
  all are compensated. But between these extremes, partial
  state exists.
- Consistency: business rules are maintained within each
  local transaction. Across the saga: depends on compensation
  correctness.
- Durability: each local transaction is durable.

A Saga does NOT guarantee:
- Isolation: concurrent sagas CAN see each other's partial state.
  A saga step in a different saga can observe an order in
  PAYMENT_PROCESSING state (not yet complete).
- Immediate atomicity: between steps, partial state exists.
  A crashed saga leaves artifacts (PENDING order, locked inventory).

*What separates good from great:* Great candidates explain the
practical implication of missing isolation: "If two sagas are
processing orders for the same customer simultaneously, and the
customer has a credit limit, both sagas might check the credit
limit before either has decremented it - both see the full limit
available. Both approve orders that together exceed the limit.
This is the lost update problem at saga level. Mitigation: semantic
locks (mark resources in use with PENDING state and check before
proceeding)."

---

**Q6 (Debugging): A saga has been executing for 2 hours and is
stuck in INVENTORY_RESERVING state. How do you debug it?**

Step 1: check the saga state table for the specific saga ID.
What step is it on? What is the last event recorded? When was
the last update?

Step 2: check the inventory service logs for the reservation
command. Was the command received? Did it produce an error?
Is the inventory service up and healthy?

Step 3: check the event/message queue (Kafka, SQS) for the
message that should trigger the inventory step. Is the message
stuck in the queue? Is the inventory service consumer running?
Check consumer group lag.

Step 4: check for idempotency issues. Has the inventory service
attempted the reservation multiple times? Is the retry mechanism
working?

Root causes:
- Inventory service is down (consumer lag builds up)
- The reservation message was published but the consumer threw
  an exception and the message is in the dead-letter queue
- The saga orchestrator published the command but crashed
  before recording the step - on recovery, it re-publishes
  but the inventory service got the first message and the
  second is a duplicate (idempotency key prevents double
  reservation, but saga thinks it has not proceeded)

Fix: implement saga recovery: on orchestrator restart, check
all in-flight sagas and re-issue their pending commands with
idempotency keys.

*What separates good from great:* Immediately thinking about
dead-letter queues and consumer lag. In event-driven sagas,
the most common failure mode is a message sitting in a DLQ
after a consumer exception.

---

**Q7 (Debugging): You are seeing duplicate orders created in your
system. Investigation shows the OrderService saga handler is
processing the same `OrderCreated` event twice. How do you fix this?**

This is a lack of idempotency in the saga step. The event was
delivered twice (at-least-once delivery is the norm for Kafka,
SQS, etc.), and the handler created an order both times.

Immediate fix: add idempotency checking to the order creation
step. Use the event's unique ID (message ID, idempotency key)
as the idempotency key. Before creating the order, check if an
order with this idempotency key already exists. If yes: return
the existing order (or a success response). If no: create.

Make the check-and-create atomic: use a database unique constraint
on the idempotency key column. If a duplicate arrives, the INSERT
fails with a unique constraint violation, which the handler catches
and treats as a success.

Systematic fix: apply this pattern to every saga step handler.
The rule: every event/command handler MUST be idempotent. Kafka
and most message systems guarantee at-least-once delivery, not
exactly-once. Idempotency at the consumer level provides
effectively-once processing semantics.

*What separates good from great:* Using a database unique
constraint (not just an application-level check) for atomicity.
An application-level check has a TOCTOU (time-of-check to
time-of-use) race condition between the check and the insert.
The unique constraint is atomic.

---

**Q8 (Behavioral): Tell me about a time you had to design or
debug a distributed transaction in a microservices architecture.**

*(Personalize from experience.)*

Example structure: "In our e-commerce platform, we initially used
an orchestrated Saga for the order checkout flow: OrderService →
PaymentService → InventoryService. We had a bug where orders stuck
in PAYMENT_PROCESSING state because the PaymentService was throwing
a non-retriable error but the saga was retrying it endlessly. I
diagnosed it by checking the saga state table and seeing thousands
of retry attempts with the same error. Fix: categorize errors as
retriable (transient network error) vs. non-retriable (payment
declined). Non-retriable errors skip retries and go straight to
compensation. This reduced the saga failure investigation time
from 2 hours to 5 minutes because failures resolved themselves
immediately."

*What separates good from great:* The distinction between retriable
and non-retriable errors is a key operational pattern that shows
production experience.

---

**Q9 (Scale): How does Saga performance compare to 2PC at
high transaction volumes?**

At low volume (100 transactions/second):
- 2PC: acceptable latency for same-datacenter resources
  (2 round trips of ~5ms each = 10ms overhead)
- Saga: comparable or lower latency per transaction
  (local commits + async events)

At high volume (10,000+ transactions/second):
- 2PC: lock contention becomes significant. Phase 1 holds
  locks across multiple services. If services have variable
  latency, the slowest service blocks all others. Thread pools
  in the coordinator exhaust under high concurrency.
- Saga: each step commits locally and immediately. No cross-service
  locking. Services can scale independently. The saga orchestrator
  becomes a potential bottleneck but is stateless (can horizontally
  scale). Throughput scales with the number of orchestrator instances.

The critical difference at scale: 2PC serializes transactions
(each transaction holds locks on all participants until global
commit). Sagas do not hold locks across services. Two concurrent
Sagas on different orders can proceed fully in parallel.

At 10,000 TPS: 2PC would need to hold 10,000 cross-service lock
sets simultaneously. Saga processes 10,000 independent local
transactions per step.

*What separates good from great:* Quantifying the lock hold time.
"With 2PC at 5ms per step, a 3-service transaction holds locks
for ~15ms. At 10,000 TPS, that is 150,000 concurrent lock holders
across your services at any given moment - likely exceeding
connection pool limits."

---

---

### 🚨 Failure Modes and Diagnosis

*(For Saga Pattern)*

**Saga left in inconsistent state (partial compensation):**

Symptom: records in the database show an order that is CANCELLED
but the payment refund record does not exist.

Cause: the saga compensation step (refund payment) failed and
was not retried; or the orchestrator crashed after canceling
the order but before issuing the refund.

Diagnosis: query the saga state table for saga IDs with status
COMPENSATING that have been in that state > 30 minutes. Check
which compensation steps have not completed.

Fix: implement compensation retry with exponential backoff.
Store compensation step status separately. Alert on sagas stuck
in COMPENSATING > threshold. For permanent compensation failures:
add to a manual review queue for human intervention.

**Zombie saga steps (compensated saga continues receiving events):**

Symptom: the inventory service receives a stock reservation command
for a saga that was already compensated and aborted.

Cause: a delayed event (network queue backup, retry from a dead
service) was delivered after the saga completed compensation.

Diagnosis: check event timestamps and saga state timestamps.
The event was produced before the saga aborted but consumed after.

Fix: include the saga ID and step sequence number in every command.
Each service checks: is this saga ID still in an active state?
Is this step sequence still expected? Reject events from aborted
sagas.

---

### 🏛️ System Design

*(Omit: the Saga orchestration pattern is a workflow design pattern.
System-level architecture for microservices with Saga is covered
in L3 Service Architecture and L5 Migration Strategy files.)*

---

### 📊 Diagram

*(Omit: Saga sequence diagrams are shown in the Concept Explanation
pseudocode for both choreography and orchestration variants.
Visual enhancement is available in the L3 Service Architecture
file which includes service mesh diagrams.)*

---

### 🎯 Interview Deep-Dive

| Question Type | Count | Timing |
|---|---|---|
| Conceptual | 3 | 2 min each |
| Trade-off | 2 | 3 min each |
| Debugging | 2 | 3 min each |
| Behavioral | 1 | 4 min |
| Scale | 1 | 3 min |

---

**Q1 (Conceptual): Explain the difference between a compensating
transaction and a rollback. When can a compensation fail where
a rollback cannot?**

A database rollback reverts changes that are still in a pending
(uncommitted) transaction. The rollback is a database-internal
operation: the database discards uncommitted writes from the
transaction's log buffer. It is guaranteed to succeed because
the data was never durably committed.

A compensating transaction executes a new business operation
to undo a previously committed transaction. The compensation is
a new transaction that reverses the effect: refund a payment,
cancel an order, release a reservation.

Where compensation can fail but rollback cannot:
1. The external system is unavailable (payment provider is down
   when you try to refund). Rollback cannot fail this way - it
   is internal.
2. The compensated state has been further modified. If a saga
   cancels an order that a customer subsequently modified,
   the cancellation might fail because the order's state has
   changed.
3. The operation is externally irreversible. An email was sent.
   A "compensation" must be a new email saying "disregard," not
   an undo.
4. The compensation itself has a bug. Unlike a rollback (automatic),
   compensation is application code that can have bugs.

*What separates good from great:* The irreversibility point.
"Some saga steps cross the point of no return. Once a package is
shipped, there is no compensation - only a new 'return' process.
The saga must be designed with this in mind: the 'pivot transaction'
is the last reversible step. After the pivot, the saga must
succeed."

---

**Q2 (Conceptual): What is semantic locking and why does a Saga
need it?**

Semantic locking is an application-level mechanism to prevent
other saga instances from accessing a resource that is currently
being modified by a saga in progress.

Without semantic locking: Saga A starts an order for Customer X
and sets the order status to PENDING. While processing payment,
another saga (Saga B) starts a second order for Customer X. Both
sagas read Customer X's credit limit: both see $500 available.
Both approve orders. Together they exceed the $500 limit.
This is a saga-level dirty read (Saga B read Saga A's partial state).

Semantic lock implementation: when Saga A starts processing
Customer X's order, it sets a `saga_lock` column on the customer
record to the saga ID. When Saga B starts, it checks for
existing saga locks on the customer. If a lock exists: Saga B
waits (or fails with a "please retry" response). When Saga A
completes: it releases the lock.

This is pessimistic concurrency control at the saga level.
Optimistic alternative: use optimistic locking with version
numbers at each saga step. If a later saga step fails the
version check: abort and compensate.

*What separates good from great:* Knowing that semantic locking
is optional but necessary for business correctness in many
domains. The credit limit example is the canonical illustration.

---

**Q3 (Conceptual): How does the Outbox pattern integrate with
a Saga to ensure reliable message delivery?**

The Outbox pattern ensures that every state change in the saga
orchestrator is reliably reflected as a published event/command
without using 2PC between the database and the message broker.

Without Outbox in a Saga:
1. Orchestrator records "step complete" in its database
2. Orchestrator publishes next command to Kafka
3. Orchestrator crashes between steps 1 and 2

When orchestrator recovers: it sees "step complete" but never
published the next command. The saga is stuck.

With Outbox:
1. Orchestrator writes "step complete" to saga_state table
   AND writes the next command to outbox table
   (single local transaction - atomic)
2. Outbox poller reads pending outbox entries and publishes
   to Kafka (at-least-once)
3. Even if orchestrator crashes after step 1, the outbox entry
   exists and will be published by the poller

The Outbox guarantees at-least-once delivery. Combined with
idempotent command handlers in each service, this achieves
effectively-exactly-once processing semantics.

*What separates good from great:* The phrase "single local
transaction" is the key. The Outbox is powerful because it
uses a local database transaction (atomic, no 2PC) to guarantee
that the command is durably queued for delivery.

---

**Q4 (Trade-off): Compare choreography vs. orchestration for
a Saga with 8 steps and multiple failure paths. Which is better?**

For an 8-step saga with multiple failure paths, orchestration
is significantly better. Reasons:

1. **Explicitness:** the full saga flow (including all failure
   paths) is in one place - the orchestrator. With choreography,
   the flow is implicit across 8 service event handlers. To
   understand the failure path, you read 8 services.

2. **Debuggability:** when a saga fails, check the orchestrator's
   state table. With choreography: trace distributed events
   across all services' logs.

3. **Compensations are managed in one place:** the orchestrator
   knows which steps completed and issues compensations in
   reverse order. With choreography: each service must decide
   which compensation events to publish, and they must be
   consistent with each other.

4. **Testing:** test the orchestrator as a state machine.
   Inject failures at each step. With choreography: must
   integration test all event combinations.

Choreography is better when: the saga has 2-3 steps,
the flow is simple and stable, and you want to avoid the
additional orchestrator service.

*What separates good from great:* The testing argument.
"Choreography is harder to test exhaustively because the
saga flow is emergent from event interactions. The orchestrator
is a state machine - I can unit test every state transition
including compensation paths."

---

**Q5 (Trade-off): When is a Saga not the right solution, and
what should be used instead?**

Sagas are not the right solution when:

1. **Strong isolation is required:** if the business cannot
   tolerate intermediate state visibility (credit limit example
   without semantic locks), Sagas add significant complexity.
   Consider: can you redesign the domain boundary so the
   operation fits in a single service with a local transaction?

2. **The operation is inherently single-system:** if you are
   debating using a Saga to coordinate two tables in the same
   database - do not. Use a local ACID transaction.

3. **The compensating transactions are too complex or impossible:**
   if every saga failure path requires weeks of business logic
   to compensate, the saga becomes a liability. Consider: can
   the business design prevent the need for compensation?
   (Pre-validating all conditions before starting the saga.)

4. **The required latency is very low:** Sagas are async by
   nature. If a multi-step operation must complete in < 10ms,
   an async Saga (which involves multiple message round-trips)
   is not suitable. Use a synchronous, single-service operation.

Alternatives: event sourcing for audit-heavy domains, process
managers for long-running workflows, reformulate the domain
model to reduce cross-service coupling.

*What separates good from great:* The domain boundary question.
"Before using a Saga, I ask: why do these operations span multiple
services? Can I redesign the bounded context to bring them
into one service? Sagas solve an integration problem - if
the integration can be eliminated by rethinking domain boundaries,
the Saga is unnecessary."

---

**Q6 (Debugging): Your Saga orchestrator is reprocessing
already-completed sagas after a restart, causing duplicate
compensations. What is the root cause?**

The orchestrator is not correctly persisting saga completion
state, or it is not reading completion state on startup.

Possible causes:
1. The saga state is stored in-memory (not persisted). After
   restart, all in-memory state is lost. The orchestrator
   re-reads pending commands from Kafka (which includes
   commands for already-completed sagas) and reprocesses them.
   Fix: persist saga state to a database, not in-memory.

2. The saga state is persisted but the Kafka consumer group
   offset is not committed (or is committed before processing,
   leading to re-delivery after restart). The orchestrator
   sees old commands again.
   Fix: use consumer group offset commit AFTER processing,
   with idempotent saga step handling.

3. The orchestrator uses the wrong saga state table name
   (configuration bug after restart), creating new saga records
   for existing saga IDs.
   Fix: add a unique constraint on saga_id in the state table.
   Duplicate inserts fail, preventing reprocessing.

*What separates good from great:* Identifying in-memory state as
the root cause immediately. "Any orchestrator that stores saga
state in memory is not production-ready. State must survive restarts."

---

**Q7 (Debugging): How would you add observability to a Saga
to enable production debugging?**

Key observability additions:

1. **Saga state table:** every state transition stored with
   timestamp, step name, correlation IDs, and error details.
   A single query returns the full history of any saga.

2. **Structured logging:** every saga step logs `sagaId`,
   `stepName`, `correlationId`, `status`, `duration`.
   Enables log aggregation (Splunk, Datadog) to show all
   events for a saga ID.

3. **Distributed tracing:** propagate the saga ID as a
   trace header. Each service's span includes the saga ID.
   Use OpenTelemetry to visualize the full saga execution
   in Jaeger or Zipkin - including which service took how long.

4. **Metrics:** track per-step success/failure rates,
   per-step latency (P50, P99), saga completion rate,
   saga compensation rate. Alert on elevated compensation
   rate (sagas failing and needing rollback) - this is
   a business health signal.

5. **Dead letter queue monitoring:** alert when a saga step
   message lands in the DLQ. This indicates a consumer
   exception that stopped the saga.

*What separates good from great:* Knowing that compensation rate
is a business health metric, not just a technical one. "If
compensation rate spikes from 1% to 15%, something significant
changed in the business conditions: inventory shortage, payment
provider issues, etc."

---

**Q8 (Behavioral): How have you handled the need for exactly-once
processing in an event-driven or Saga-based system?**

*(Personalize from experience.)*

Example structure: "In our Saga, we needed exactly-once
inventory reservation. The inventory service consumed reservation
commands from Kafka. Kafka guarantees at-least-once delivery.
We implemented exactly-once by: (1) adding an `idempotency_key`
column to the `reservations` table with a unique constraint.
(2) Setting the idempotency key to `sagaId + stepId`. (3) When the
consumer received a duplicate message (same `sagaId + stepId`),
the INSERT failed with a unique constraint violation. The handler
caught this and returned success without creating a duplicate.
(4) We also used a transactional outbox for publishing the
'reserved' event back to the orchestrator - ensuring we only
published the event once, atomically with recording the reservation.
Combined: at-least-once delivery + idempotent consumer =
effectively-exactly-once processing."

---

**Q9 (Scale): How do you scale a Saga orchestrator to handle
high transaction volume without the orchestrator becoming a
bottleneck?**

The saga orchestrator can become a bottleneck if it is a single
instance with a sequential processing loop.

Scaling strategies:

1. **Partition sagas by key:** assign sagas to orchestrator
   instances based on a partition key (customer ID, order ID).
   Consistent hashing ensures the same saga always routes to the
   same instance (preserving ordering). Multiple instances
   process different partitions in parallel.

2. **Stateless orchestrator + shared state store:** the orchestrator
   instance is stateless. All saga state is in a shared database
   (PostgreSQL, DynamoDB). Any instance can process any saga step.
   Add optimistic locking on the saga state to prevent
   concurrent processing of the same saga step.

3. **Async, non-blocking processing:** use reactive/async code
   (CompletableFuture, Project Reactor). A single orchestrator
   instance can handle thousands of concurrent sagas without
   blocking threads.

4. **Separate instances per saga type:** an order saga orchestrator
   and a payment saga orchestrator are separate services.
   Each scales independently.

5. **Kafka partitions as work queues:** the orchestrator consumes
   from Kafka. Scaling = adding partitions + consumer instances.
   Kafka's consumer group protocol distributes partitions across
   instances automatically.

*What separates good from great:* The stateless orchestrator point.
"A saga orchestrator does not need to hold saga state in memory.
If it is stateless and reads from/writes to a database, it is
trivially horizontally scalable. The database (shared state store)
is the bottleneck in this model - addressed with connection pooling,
read replicas for state queries, and write batching."
