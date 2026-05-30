---
layout: default
title: "Design Patterns - L2 State and Chain"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 8
permalink: /design-patterns/l2-state-and-chain/
---

# State Pattern

---
id: DP-019
title: State Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: high
asked_at: Mid+
seniority: mid-senior
tags: #design-patterns, #state, #behavioral, #state-machine, #finite-automaton
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> State allows an object to alter its behavior when its internal state
> changes. The object appears to change its class. Instead of a large
> switch statement branching on a state enum, each state is a separate
> class. The context delegates behavior to the current state object.
> Transitioning to a new state replaces the state object. It is the
> pattern for implementing finite state machines cleanly.

**3 minutes (Senior):**
> The problem: an object with multiple states has methods whose behavior
> varies by state. Without State, every method has a switch statement
> on the state enum, and the switch gets duplicated across methods.
> Adding a new state requires adding a new case to every switch. With
> State, each state is a class: `OrderPendingState`, `OrderShippedState`,
> `OrderDeliveredState`. The `Order` context delegates `cancel()`, `ship()`,
> `markDelivered()` to the current state object. Each state handles only
> the transitions it supports; unsupported transitions throw
> `IllegalStateException`.
>
> Production context: workflow engines, order status machines,
> TCP connection state machines, user authentication state (anonymous,
> authenticated, expired), payment processing states (pending, authorized,
> captured, refunded). Spring State Machine (a Spring module) implements
> this pattern with a full configuration DSL.
>
> The trade-off vs enum-based switch: State pattern is appropriate when
> the number of states is medium to large (5+) and each state has
> meaningfully different behavior across multiple methods. For simple
> two-state or three-state objects with one behavior that varies, a
> simple flag or enum is clearer.

**Blank Mind Recovery:**

**(1) Restate:** "State - the pattern where an object's behavior changes
based on its state, implemented by delegating to state objects."

**(2) First principles:** "Problem: an object behaves differently
depending on its current state. Encoding this with switch statements
spreads state logic across all methods. Solution: extract each state into
a class that implements state-specific behavior."

**(3) Bridge:** "Like a traffic light: the light (context) has the same
physical interface. When it is in 'green state', cars can go. When in
'red state', cars must stop. The light delegates behavior to its current
state. Changing the light changes the behavior."

---

### 📘 Concept Explanation

**What it is:**
State allows an object (the Context) to change its behavior based on its
internal state. The Context delegates state-specific behavior to a State
object. When the context transitions to a new state, it replaces its
State object.

**The problem it solves:**
Objects with multiple states whose methods behave differently based on
the state. Without State, methods contain large `switch/if-else` blocks
on state enums. The state logic is scattered across all methods and
every new state requires modifying all of them.

**How it works:**

```
State interface:
  + handle(context: Context)
  // Or: operation1(), operation2() for each operation that varies

Context:
  - state: State  (current state)
  + setState(s: State)
  + request():
      state.handle(this)  // delegate to current state

ConcreteStateA implements State:
  + handle(context):
      // behavior when in State A
      // possibly transitions:
      context.setState(new ConcreteStateB())

ConcreteStateB implements State:
  + handle(context):
      // behavior when in State B
      // possibly transitions back:
      context.setState(new ConcreteStateA())

// Usage:
Context ctx = new Context(new ConcreteStateA());
ctx.request();  // delegates to StateA.handle()
ctx.request();  // now StateB.handle() (if A transitioned)
```

**Two transition styles:**
1. **State initiates transition**: State object calls `context.setState(newState)` -
   state knows what comes next. Appropriate when transitions are
   deterministic.
2. **Context initiates transition**: Context itself calls `setState()` based
   on conditions - appropriate when the transition depends on context data
   the state object should not know.

**The key insight:**
Eliminating switch/if-else from the Context. Each state class is a
cohesive unit of state-specific logic. Adding a new state: add a new
class, no modifications to existing state classes or to the Context.

**When to use it:**
- When an object's behavior depends on its state and it must change
  behavior at runtime
- When state-specific behaviors are large enough to warrant their own
  classes (more than a few lines)
- When you have many conditional branches that check the same state
  variable across multiple methods

**When NOT to use it:**
- When there are only 2-3 states and each state has trivial behavior -
  a boolean flag or enum is simpler
- When transitions are driven by external input but the state itself
  has no behavior - a state machine table is clearer
- When the state objects need to access private members of the Context
  extensively - this creates coupling

**Alternatives:**
- **Enum with abstract methods** - each enum constant overrides abstract
  methods; simpler for small state machines in Java
- **Spring State Machine** - full-featured state machine with guards,
  actions, and configuration DSL
- **Switch statement** - appropriate for small, simple state machines
  without behavioral variation per method

---

### 💻 Code Example

```java
// BAD: Switch on state enum - duplicated across methods
public class VendingMachine {
    private State state = State.IDLE;

    enum State { IDLE, HAS_MONEY, DISPENSING }

    public void insertCoin() {
        switch (state) {  // state check in every method
            case IDLE -> state = State.HAS_MONEY;
            case HAS_MONEY -> System.out.println("Already has coin");
            case DISPENSING -> System.out.println("Wait for dispense");
        }
    }

    public void pressButton() {
        switch (state) {  // SAME switch pattern repeated
            case IDLE -> System.out.println("Insert coin first");
            case HAS_MONEY -> { dispenseItem(); state = State.DISPENSING; }
            case DISPENSING -> System.out.println("Already dispensing");
        }
    }
    // Every new state: add case to ALL switches
}
```

> **Code walkthrough:** Every method duplicates the switch. Adding a
> fourth state (OUT_OF_STOCK) requires adding a case to every switch in
> every method. State logic is scattered across the class.

```java
// GOOD: State pattern - each state is a class
public interface VendingMachineState {
    void insertCoin(VendingMachineContext ctx);
    void pressButton(VendingMachineContext ctx);
    void dispenseItem(VendingMachineContext ctx);
}

public class IdleState implements VendingMachineState {
    public void insertCoin(VendingMachineContext ctx) {
        System.out.println("Coin inserted");
        ctx.setState(new HasMoneyState());
    }
    public void pressButton(VendingMachineContext ctx) {
        System.out.println("Insert coin first");
    }
    public void dispenseItem(VendingMachineContext ctx) {
        System.out.println("Insert coin first");
    }
}

public class HasMoneyState implements VendingMachineState {
    public void insertCoin(VendingMachineContext ctx) {
        System.out.println("Return previous coin");
        ctx.refundCoin();
    }
    public void pressButton(VendingMachineContext ctx) {
        ctx.setState(new DispensingState());
        ctx.getState().dispenseItem(ctx);
    }
    public void dispenseItem(VendingMachineContext ctx) {
        System.out.println("Press button to select");
    }
}

public class DispensingState implements VendingMachineState {
    public void insertCoin(VendingMachineContext ctx) {
        System.out.println("Wait for dispense to complete");
    }
    public void pressButton(VendingMachineContext ctx) {
        System.out.println("Already dispensing");
    }
    public void dispenseItem(VendingMachineContext ctx) {
        ctx.releaseItem();
        System.out.println("Item dispensed. Thank you!");
        ctx.setState(new IdleState());
    }
}

public class VendingMachineContext {
    private VendingMachineState state = new IdleState();

    public void setState(VendingMachineState s) {
        this.state = s;
    }
    public VendingMachineState getState() { return state; }

    // Delegates to current state - no switch needed:
    public void insertCoin() { state.insertCoin(this); }
    public void pressButton() { state.pressButton(this); }
    public void releaseItem() { /* dispense the item */ }
    public void refundCoin() { /* return coin */ }
}
```

> **Code walkthrough:** Each state class contains the complete behavior
> for that state. `IdleState.insertCoin()` transitions to `HasMoneyState`.
> `HasMoneyState.pressButton()` transitions to `DispensingState`.
> `DispensingState.dispenseItem()` transitions back to `IdleState`.
> Adding `OutOfStockState`: create one new class implementing
> `VendingMachineState`. Override the affected methods. No changes to
> any existing state class.

```java
// PRODUCTION: Order workflow state machine
public enum OrderStatus { PENDING, PAID, SHIPPED, DELIVERED, CANCELLED }

public interface OrderState {
    void pay(OrderContext ctx);
    void ship(OrderContext ctx);
    void deliver(OrderContext ctx);
    void cancel(OrderContext ctx);
}

// States reject invalid transitions by default:
public abstract class AbstractOrderState implements OrderState {
    // Default: reject invalid transitions
    public void pay(OrderContext ctx) {
        throw new IllegalStateException(
            "Cannot pay in state: " + ctx.getStatus());
    }
    public void ship(OrderContext ctx) {
        throw new IllegalStateException(
            "Cannot ship in state: " + ctx.getStatus());
    }
    // ... same for deliver, cancel
}

public class PendingState extends AbstractOrderState {
    @Override
    public void pay(OrderContext ctx) {
        ctx.capturePayment();
        ctx.setStatus(OrderStatus.PAID);
        ctx.setState(new PaidState());
    }
    @Override
    public void cancel(OrderContext ctx) {
        ctx.setStatus(OrderStatus.CANCELLED);
        ctx.setState(new CancelledState());
    }
}
```

> **Code walkthrough:** `AbstractOrderState` provides default rejection
> for all transitions. Each concrete state overrides only the transitions
> it supports. Calling `order.ship()` on a `PendingState` throws
> `IllegalStateException` (via the default in `AbstractOrderState`).
> This is better than an explicit check because: new states automatically
> reject all transitions unless explicitly allowed, and the default
> rejection message includes the current state.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> State pattern replaces large switch statements with state classes. Each
> state class implements the behavior for that state. The context delegates
> to the current state object. When the state changes, the context replaces
> its state object. I use it when an object has 4+ states and multiple
> methods that behave differently per state - the switch duplication
> becomes unmanageable.

*Push deeper:* "The key benefit: adding a new state is adding one new
class. Without State, adding a new state means adding a case to every
switch in every method - multiple files, risk of missing one."

---

**Senior / Staff (5+ years):**
> State is a finite state machine (FSM) implementation pattern. The
> context is the machine, state classes are the states, and transitions
> are method calls that change the state reference. For complex
> state machines in production, I use Spring State Machine, which
> adds: guard conditions (only transition if a condition is met),
> actions (execute on entry/exit), event-driven transitions (external
> events trigger state changes), and machine persistence (serialize
> state to database for long-running workflows).
>
> Design decision: who manages transitions? State-managed (state
> transitions itself by calling `ctx.setState(newState)`) vs context-managed
> (context calls `setState()` in its own methods). State-managed: each
> state is fully autonomous, good for deterministic FSMs. Context-managed:
> clearer when transition logic is complex or depends on context data.
> For business workflows: often hybrid - state validates, context transitions.

*Push deeper:* "State pattern memory concern: each transition creates
a new state object. For high-throughput systems (millions of state
changes per second), state object creation and GC pressure matters.
Solution: make state objects stateless (no mutable fields) and cache
them as singletons. `OrderContext` holds references to pre-created
`PendingState`, `PaidState` instances; transitions swap the reference
without allocation."

---

### ⚠️ Common Misconceptions

**Misconception 1: State pattern requires a large number of classes and is over-engineered for simple workflows.**

State pattern eliminates a large number of conditional checks across the context class. The tradeoff is explicit: N state classes vs N * M conditional blocks (N states × M operations). For a 3-state, 2-operation workflow: 3 State classes vs 6 if/else blocks. For a 10-state, 8-operation workflow: 10 State classes vs 80 if/else blocks. The class-per-state approach scales; the conditional approach becomes unmaintainable. If you have fewer than 3 states and 2 operations, the conditional approach may genuinely be simpler.

**Misconception 2: State and Strategy are interchangeable for stateful behavior.**

Strategy is about the CLIENT choosing an algorithm from outside. State is about the OBJECT itself transitioning based on internal conditions. A traffic light transitions from Red to Green to Yellow based on a timer - it does not expose "setColorStrategy()" to external clients. The state transition logic is encapsulated within the State objects themselves. If external clients need to control the behavior variant, use Strategy. If the object itself determines when to change behavior, use State.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Illegal state transition causes invalid business state.**

Symptom: an order transitions from CANCELLED directly to SHIPPED bypassing CONFIRMED; database contains records with impossible state combinations. Root cause: state transitions are not validated - the `transition()` method allows any target state regardless of current state. Diagnosis: create a state transition matrix and verify each transition path. Fix: implement explicit transition guards in each State: `if (currentState != CONFIRMED) throw new InvalidTransitionException("Cannot ship from state: " + currentState)`; encode valid transitions as a graph.

**Failure Mode 2: Context object's state becomes inconsistent when exceptions occur mid-transition.**

Symptom: a failed state transition leaves the context in an intermediate state that is neither the old state nor the new state; subsequent operations behave inconsistently. Root cause: state transition involves multiple operations (update state, persist to database, send event); if any step fails mid-transition, the state is partially updated. Diagnosis: add invariant assertions that check state consistency after each operation. Fix: wrap state transition in a transaction; perform all state change steps atomically or roll back to the previous valid state on failure.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the State pattern? When would you choose it over a switch?"

🗣️ "State allows a Context object to change its behavior when its
internal state changes, by delegating behavior to interchangeable State
objects. Choose State over switch when: (1) 4 or more states exist,
(2) multiple methods vary by state (state logic is scattered across
the class in multiple switches), (3) states are likely to grow over
time (adding a state means adding one class, not modifying N switches).
Choose switch/enum when: 2-3 states with trivial per-state behavior,
the state machine is stable and unlikely to grow, or when a configuration
table or external DSL is more appropriate than code."

#### Mechanism
- "How do State objects perform transitions in the State pattern?"

🗣️ "Transitions are usually performed by the state object calling
`context.setState(newState)`. Example: `IdleState.insertCoin()` calls
`ctx.setState(new HasMoneyState())`. The context method then returns;
on the next method call, the context delegates to `HasMoneyState`.
The state object transitions on its own actions. Alternative: the
context makes the transition decision - `ctx.request()` calls
`state.handle(ctx)`, which returns a `State` reference, and the context
updates its state field. This is appropriate when the transition depends
on data the state should not know. The key: after any transition,
subsequent calls to the context delegate to the new state object."

#### Comparison
- "Compare State vs Strategy."

🗣️ "Same structure: both have a Context with a reference to an interface
that can be swapped. The difference is intent and lifecycle. Strategy:
the algorithm is set once (or occasionally) and remains stable. Multiple
strategies are application-level choices (sort algorithm, payment method).
State: the state changes frequently based on events and the context's
own operations. States represent stages in a lifecycle. Strategy says
'how to do something.' State says 'what can be done depends on where
we are in the process.' A payment processor uses Strategy (which payment
algorithm) and State (what payment operations are valid - pending, captured,
refunded)."

#### Scenario
- "Design the state machine for a TCP connection."

🗣️ "TCP states: CLOSED, LISTEN, SYN_SENT, SYN_RECEIVED, ESTABLISHED,
FIN_WAIT_1, FIN_WAIT_2, TIME_WAIT, CLOSE_WAIT, LAST_ACK.
I define `TcpState` interface with `open()`, `send(data)`, `receive(data)`,
`close()`. Each state class implements the valid transitions.
`ClosedState.open()` sends SYN and transitions to `SynSentState`.
`SynSentState.receive(SYN_ACK)` sends ACK and transitions to
`EstablishedState`. `EstablishedState.close()` sends FIN and transitions
to `FinWait1State`. Invalid transitions throw `IllegalStateException`.
This is the canonical State pattern example from the GoF book - TCP's
state machine is complex enough to benefit from the pattern
(10+ states, all with different behavior per method)."

#### Debugging
- "A State machine is transitioning to the wrong state. How do you debug?"

🗣️ "Add state transition logging: every call to `setState()` logs
the previous state and the new state. For the failing scenario: trace
through the log to identify which transition was incorrect. Then examine
the State class responsible for that transition - what condition triggered
`setState()` with the wrong state? Common causes: (1) A state object is
transitioning based on an incorrect condition. (2) An external event
(thread pool, timer) is calling a method on the context while the state
is in the middle of a transition - concurrent state machines require
synchronization. (3) The state object is shared (singleton) and one
thread is in the middle of transition while another reads the state -
race condition."

#### Comparison Table

| Aspect | State | Strategy | Enum + switch | Spring State Machine |
|---|---|---|---|---|
| Changes at runtime | Frequently (auto) | Occasionally (manual) | Never (compile-time) | Event-driven |
| Transition logic | In state classes | N/A | In switch branches | External config DSL |
| Adding new state | New class | New class | New case in each switch | Config entry |
| Persistence | Manual (serialize state ref) | N/A | Easy (serialize enum) | Built-in |
| Best for | Workflow, FSM | Algorithm selection | 2-3 simple states | Complex enterprise FSM |

---

### ⚖️ Comparison Table

| Factor | State | Strategy | Command | Observer |
|---|---|---|---|---|
| Changes | Automatically on events | Manually by caller | N/A (executed once) | On Subject change |
| Behavioral unit | Per-state behavior set | Single algorithm | Single operation | Notification |
| History | Implicit (state transitions) | None | Explicit (undo stack) | None |
| Best for | FSM, workflows | Algorithm swap | Undo, queuing | Reactive notification |

---

### 🔥 Field Q&A

**Q: How do you persist a stateful State machine (like an order workflow)
so that it survives server restarts?**

A: Persist the current state as an enum value (or string) in the database.
On loading the entity, reconstruct the state object from the enum. Example:
`Order` entity has `OrderStatus status` column (enum persisted as string).
On load: `this.stateObject = StateFactory.create(this.status)` - maps the
enum to the corresponding state class instance. On transition: update
both `this.stateObject = newState` and `this.status = newState.getStatus()`.
In JPA: `@PreUpdate` hook can derive `status` from `stateObject.getStatus()`
so the state enum is always in sync. With Spring State Machine: the
framework provides machine context persistence via `StateMachinePersist`
interface backed by a database or Redis.

**Q: What happens if a State object needs access to the Context's private
fields to perform a transition?**

A: Three approaches. (1) Pass the context as a parameter and expose
the needed state via public getters in the Context (most common).
(2) Make state classes inner classes of Context - they have access to
private fields (tight coupling but simple for small state machines).
(3) Use a DTO: create a `StateContext` value object that contains all
state data, pass it to the State's method, return an updated
`StateContext`. This keeps State objects fully decoupled from Context.
The third approach is cleanest for testability: you can test state
transitions by passing a `StateContext` directly without constructing
the full Context.

---

# Chain of Responsibility Pattern

---
id: DP-020
title: Chain of Responsibility Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: high
asked_at: Mid+
seniority: mid-senior
tags: #design-patterns, #chain-of-responsibility, #behavioral, #pipeline
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Chain of Responsibility passes a request along a chain of handlers.
> Each handler decides whether to handle the request or pass it to the
> next handler. The sender does not know which handler will process it.
> This decouples the sender from the receiver and allows building flexible
> processing pipelines. Servlet filters, Spring Security filter chain,
> and logging frameworks are all built on this pattern.

**3 minutes (Senior):**
> Chain of Responsibility solves two problems: (1) decoupling the sender
> from the concrete receiver (the sender does not know who handles it),
> and (2) allowing multiple handlers to process a request in sequence
> (pipeline processing). Each handler in the chain decides: handle and
> stop the chain, handle and continue, or skip (pass to next without handling).
>
> Production context: Java Servlet filter chain (`FilterChain.doFilter()`)
> is the canonical production example. Spring Security builds its entire
> request processing on a `SecurityFilterChain` - each filter handles
> one concern (authentication, authorization, CSRF, CORS) and calls
> `chain.doFilter()` to continue. Logback/Log4j's appender chain processes
> log messages through a sequence of appenders. Spring's `HandlerInterceptor`
> chain processes every HTTP request. Exception handler chains process
> exceptions through a sequence of handlers.
>
> The distinction from Decorator: Decorator always delegates to the
> wrapped object (adds behavior). Chain of Responsibility may short-circuit
> (stop the chain). The handler decides whether to continue. In a security
> filter, if authentication fails, the handler returns 401 and does NOT
> call `chain.doFilter()` - the chain is stopped.

**Blank Mind Recovery:**

**(1) Restate:** "Chain of Responsibility - the pattern where a request
is passed through a chain of handlers, each deciding to handle or pass."

**(2) First principles:** "Problem: multiple handlers may process a
request; the sender should not know which. Solution: chain the handlers;
each calls the next or stops."

**(3) Bridge:** "Like customer support escalation: first-tier support
handles simple issues (and stops the chain). Complex issues are passed
to second-tier. Critical issues go to management. The caller just submits
a ticket - they do not choose the tier."

---

### 📘 Concept Explanation

**What it is:**
Chain of Responsibility lets you pass requests along a chain of handlers.
Each handler can process the request and/or pass it to the next handler.
The sender is decoupled from the concrete handler.

**The problem it solves:**
When more than one object might handle a request and the handler is not
known at design time. When a request should be processed by multiple
handlers in sequence (pipeline). When you want to add or remove handlers
at runtime.

**How it works:**

```
Handler interface:
  - nextHandler: Handler  (the next in chain)
  + setNext(handler: Handler)
  + handle(request: Request): Response

ConcreteHandlerA extends Handler:
  + handle(request):
      if (canHandle(request)):
          // handle it (and optionally stop chain)
          return result
      else:
          return nextHandler.handle(request)  // pass along

ConcreteHandlerB extends Handler:
  + handle(request):
      // may preprocess, then pass along
      preProcess(request)
      result = nextHandler.handle(request)
      postProcess(result)
      return result

// Building the chain:
handler = new AuthHandler()
  .setNext(new RateLimitHandler()
    .setNext(new CachingHandler()
      .setNext(new BusinessLogicHandler())));

result = handler.handle(request);
```

**Two chain behaviors:**
1. **Stop on match** - handler processes the request and does NOT call
   next (exception handling, routing). First matching handler wins.
2. **Pipeline** - all handlers process the request in sequence (filters,
   interceptors). Each handler calls next; the request passes through
   all handlers.

**The key insight:**
Each handler knows only its next handler, not the full chain. The chain
is assembled at configuration time and can be changed without modifying
any handler class.

**When to use it:**
- When more than one handler may handle a request and the correct
  handler is unknown at design time
- When you want to issue a request to multiple objects without specifying
  the receiver explicitly
- When you want to add or reorder handlers at runtime (filter configuration,
  plugin pipeline)

**When NOT to use it:**
- When exactly one handler should always handle each request (use Command
  or direct routing instead)
- When the chain order is complex with conditional routing - consider a
  Mediator or explicit routing table

**Alternatives:**
- **Mediator** - centralizes complex routing decisions
- **Decorator** - always delegates (no short-circuit); adds behavior
- **Rule Engine** - externalized chain with configurable conditions

---

### 💻 Code Example

```java
// BAD: nested if/else for handling hierarchy
public class ExpenseApprover {
    public boolean approve(double amount) {
        if (amount <= 100) {
            return teamLead.approve(amount);
        } else if (amount <= 1000) {
            return manager.approve(amount);
        } else if (amount <= 10000) {
            return director.approve(amount);
        } else {
            return cfo.approve(amount);
        }
    }
    // Adding a new approval level: modify this class
}
```

> **Code walkthrough:** The routing logic is hardcoded. Adding a VP
> approval level between director and CFO requires modifying this class.
> Each approver is directly referenced - tight coupling.

```java
// GOOD: Chain of Responsibility
public abstract class ExpenseHandler {
    private ExpenseHandler next;

    public ExpenseHandler setNext(ExpenseHandler next) {
        this.next = next;
        return next;  // fluent: allows chaining
    }

    // Template method: handle or pass along
    public final void handle(ExpenseRequest request) {
        if (canApprove(request.getAmount())) {
            approve(request);
        } else if (next != null) {
            next.handle(request);
        } else {
            // End of chain without approval
            request.reject("Exceeds all approval limits");
        }
    }

    protected abstract boolean canApprove(double amount);
    protected abstract void approve(ExpenseRequest request);
}

public class TeamLeadHandler extends ExpenseHandler {
    protected boolean canApprove(double amount) {
        return amount <= 100;
    }
    protected void approve(ExpenseRequest r) {
        r.approve("TeamLead");
    }
}

public class ManagerHandler extends ExpenseHandler {
    protected boolean canApprove(double amount) {
        return amount <= 1000;
    }
    protected void approve(ExpenseRequest r) {
        r.approve("Manager");
    }
}

// Chain assembly (configuration/startup):
TeamLeadHandler teamLead = new TeamLeadHandler();
ManagerHandler manager = new ManagerHandler();
DirectorHandler director = new DirectorHandler();
CFOHandler cfo = new CFOHandler();

teamLead.setNext(manager).setNext(director).setNext(cfo);

// Usage:
teamLead.handle(new ExpenseRequest(500));
// passes through TeamLead (can't), handled by Manager
```

> **Code walkthrough:** `setNext()` returns the next handler to enable
> fluent chaining. Each handler knows only whether it can approve and
> its next handler. Adding VPHandler between director and CFO: change
> only the chain assembly (one line). No existing handler class changes.
> The `handle()` method is `final` in the abstract class (Template Method):
> the routing (try to approve, else pass) is fixed; only `canApprove()`
> and `approve()` are customized.

```java
// PRODUCTION: Servlet Filter chain (Java EE/Spring)
@Component
@Order(1)
public class AuthenticationFilter implements Filter {
    public void doFilter(ServletRequest req,
                          ServletResponse res,
                          FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpReq = (HttpServletRequest) req;
        String token = httpReq.getHeader("Authorization");

        if (token == null || !isValid(token)) {
            // SHORT-CIRCUIT: stop the chain, return 401
            ((HttpServletResponse) res).setStatus(401);
            return;  // do NOT call chain.doFilter()
        }

        // Authentication passed: continue the chain
        chain.doFilter(req, res);
        // Post-processing (if any) after inner filters
    }
}

@Component
@Order(2)
public class RateLimitFilter implements Filter {
    public void doFilter(ServletRequest req,
                          ServletResponse res,
                          FilterChain chain)
            throws IOException, ServletException {
        if (rateLimiter.isThrottled(getClientId(req))) {
            ((HttpServletResponse) res).setStatus(429);
            return;  // SHORT-CIRCUIT: too many requests
        }
        chain.doFilter(req, res); // continue chain
    }
}
```

> **Code walkthrough:** Each filter is a handler in the chain.
> `chain.doFilter()` is "pass to next handler." NOT calling it
> short-circuits the chain (stops processing and returns a response).
> `@Order(1)` before `@Order(2)` - Spring assembles the chain in order.
> Authentication runs first; if it fails, the rate limit filter never
> runs. If both pass, the request reaches the controller. This is the
> Chain of Responsibility pattern built into the Java web framework.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Chain of Responsibility passes a request through a linked list of
> handlers. Each handler either handles it (and optionally stops the
> chain) or passes it to the next. The sender does not know which
> handler processes the request. Servlet filters and Spring Security
> are real-world examples: each filter handles its concern (auth, rate
> limiting, CORS) and passes the request to the next filter.

*Push deeper:* "The critical distinction: a handler that calls
`chain.doFilter()` (or `next.handle()`) is participating in a pipeline -
all handlers run. A handler that does NOT call it is short-circuiting
the chain - only handlers before it ran. Security filters short-circuit
on failure."

---

**Senior / Staff (5+ years):**
> Chain of Responsibility is how frameworks build extensible processing
> pipelines. The framework defines the chain structure; you add handlers
> (plugins, filters, interceptors) without modifying the framework code.
> Spring Security is a complete CoR implementation: the `SecurityFilterChain`
> has 20+ built-in filters in a specific order; you add custom filters
> with `addFilterBefore()` or `addFilterAfter()` to insert them at the
> correct position.
>
> The design decision: should unhandled requests silently pass through
> or throw? For a pipeline (all handlers run): reaching the end of the
> chain is normal. For exclusive routing (one handler handles): reaching
> the end without a handler is an error. The abstract base class should
> encode this: null-check on `next` and throw `NoHandlerFoundException`
> for exclusive routing patterns.

*Push deeper:* "Chain vs Mediator: Chain is a linear sequence, decentralized
(each handler knows only the next). Mediator is centralized (all handlers
communicate through one hub that contains the routing logic). Chain is
simpler but harder to modify the ordering. Mediator is more complex but
makes the full routing logic visible in one place. For request pipelines:
Chain. For component communication with complex routing: Mediator."

---

### ⚠️ Common Misconceptions

**Misconception 1: Chain of Responsibility guarantees the request will be handled.**

By default, a request that passes all handlers without any handling is simply dropped silently. This is intentional in some use cases (middleware pipelines where unmatched requests fall through) but a bug in others (authorization chains where unhandled means "allow" is a security vulnerability). Decide explicitly: should an unhandled request be a default-allow, default-deny, or an exception? Implement a terminal handler that enforces the correct default behavior.

**Misconception 2: Each handler in the chain always processes the request independently.**

Handlers in a chain can: (1) STOP the chain by handling the request and not calling the next handler, (2) PASS the request to the next handler without modifying it, or (3) PARTIALLY process the request and then pass to the next handler (typical in middleware pipelines). The chain is not a broadcast - it is a sequential pipeline with short-circuit capability. Logging middleware that records the request and then calls next() is different from authorization middleware that stops the chain on rejection.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Infinite loop from circular chain reference.**

Symptom: StackOverflowError or program hangs during request processing; stack trace shows the same handler methods repeated. Root cause: handler A sets handler B as its next handler, and handler B sets handler A as its next handler, creating a cycle. Diagnosis: print the chain structure at startup; trace `setNext()` calls. Fix: validate chain construction at startup to ensure no cycles; use a chain-building utility that detects circular references.

**Failure Mode 2: Security vulnerability from fallthrough in authorization chain.**

Symptom: requests that should be denied are allowed because no handler explicitly denied them; default behavior is allow. Root cause: authorization chain has no terminal deny handler; if a request matches no allow condition, it passes through all handlers and is implicitly allowed. Diagnosis: test with a request that matches no handler's allow condition; verify it is denied. Fix: add a terminal `DenyAllHandler` as the last handler in authorization chains that explicitly denies any unmatched request - default DENY, explicit ALLOW.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is Chain of Responsibility? Name a production example."

🗣️ "Chain of Responsibility allows a request to be passed along a chain
of handlers. Each handler decides whether to handle the request or pass
it to the next handler in the chain. The sender does not need to know
which handler will process it. Production example: Java Servlet filter
chain. Every incoming HTTP request passes through registered `Filter`
objects in order. Each filter calls `chain.doFilter()` to pass the
request forward, or returns a response directly to short-circuit the
chain (for example, returning 401 for unauthorized requests). Spring
Security builds its entire security model on this pattern: authentication
filter, authorization filter, CSRF filter, CORS filter - all chained."

#### Mechanism
- "Walk me through how Spring Security's filter chain works."

🗣️ "Spring Security registers a `SecurityFilterChain` in the servlet
container. The chain contains multiple filter objects in a specific order:
`SecurityContextPersistenceFilter` (loads security context), `UsernamePasswordAuthenticationFilter` (processes login), `BasicAuthenticationFilter`
(handles Basic Auth), `FilterSecurityInterceptor` (authorization check).
Each filter calls `chain.doFilter()` to invoke the next filter. If a
filter determines the request should not proceed (unauthenticated, not
authorized, CSRF token missing), it sets the response status and returns
WITHOUT calling `chain.doFilter()`. The chain is stopped. The controller
is never reached. You insert custom filters with `http.addFilterBefore(myFilter, UsernamePasswordAuthenticationFilter.class)` - this places your
filter at the correct position in the chain."

#### Comparison
- "Compare Chain of Responsibility vs Decorator vs Pipeline."

🗣️ "Decorator: wraps a single object; always delegates (no short-circuit);
adds behavior around one specific object. The chain is intentional and
fixed at construction. Chain of Responsibility: passes a request along
dynamic handlers; each handler may short-circuit; the chain is about
routing, not enrichment. Pipeline: a processing sequence where every
stage always runs (no short-circuit) and each stage transforms the input
for the next. Pipeline is a Chain of Responsibility where all handlers
participate and each transforms the data. In practice: Spring filters
combine all three - they are a CoR (can short-circuit), and each filter
also decorates the request/response (adds headers, etc.)."

#### Scenario
- "Design a Chain of Responsibility for processing loan applications."

🗣️ "Handlers in order: `IncomeVerificationHandler` (reject if income
below minimum), `CreditScoreHandler` (reject if score below threshold),
`DebtRatioHandler` (reject if debt-to-income above limit),
`FraudDetectionHandler` (reject if flagged by fraud service),
`ManualReviewHandler` (applications that passed all automated checks
go to manual review). The first handler to reject short-circuits the
chain. The final handler approves. Each handler is independently
configurable: change the credit score threshold in `CreditScoreHandler`
without touching others. Add a new `EmploymentVerificationHandler` by
inserting it into the chain between `IncomeVerification` and `CreditScore`.
No existing handler changes."

#### Debugging
- "A request is not being handled by any handler in the chain. How
  do you debug?"

🗣️ "Add chain traversal logging: each handler logs 'Handler X: can
handle? [true/false]'. Trace the log for the failing request. Three
common causes: (1) The first handler's `canHandle()` returns false for
this request, and it passes to `next` which is null - the chain was
not fully assembled. Verify chain assembly with a chain dump at startup.
(2) A handler's `canHandle()` has a bug - it returns false even for
valid input (off-by-one in threshold, case mismatch in string comparison).
(3) A handler short-circuits incorrectly - it returns without passing
the request and without producing a valid response. Add logging at every
short-circuit point. For Servlet filter chain: check `Filter.doFilter()`
- any filter that does not call `chain.doFilter()` stops the chain."

#### Comparison Table

| Aspect | Chain of Responsibility | Decorator | Mediator |
|---|---|---|---|
| Direction | Linear (one-way chain) | Wrapping (both ways) | Hub-and-spoke |
| Short-circuit | Yes | No (always delegates) | Centralized routing |
| Handler coupling | Only knows next | Knows wrapped object | All know Mediator |
| Adding handlers | Insert in chain | Add wrapper | Register with Mediator |
| Production example | Servlet filters | Java I/O streams | Spring event bus |

---

### ⚖️ Comparison Table

| Factor | Chain of Responsibility | Decorator | Strategy | Command |
|---|---|---|---|---|
| Request routing | Sequential, optional stop | Always delegates | Direct execution | Queued/deferred |
| Number of handlers | Multiple (chain) | Multiple (nested) | One (selected) | One (invoked) |
| Short-circuit | Yes | No | N/A | N/A |
| Pipeline semantics | Yes (all run or some) | Yes (all run) | No | No |
| Dynamic reconfiguration | Yes (add/remove links) | At construction | Yes (setStrategy) | N/A |

---

### 🔥 Field Q&A

**Q: How do you implement dynamic chain reconfiguration at runtime
(add or remove a handler without restarting the server)?**

A: Use a `List<Handler>` instead of a linked list. The "chain" is a
list that the head handler iterates: `for (Handler h : handlerList) { h.handle(request); }`. Adding a handler: `handlerList.add(handler)`.
Removing: `handlerList.remove(handler)`. For thread-safety: use
`CopyOnWriteArrayList` so the iteration snapshot is stable even while
another thread modifies the list. This is more flexible than the
linked-list form but loses per-handler `setNext()` control. For
ordering: store handlers as `(int order, Handler)` pairs and sort
the list on modification. Spring Security supports dynamic filter
registration via `FilterRegistrationBean` and Spring Boot auto-configuration.

**Q: What is the difference between a Pipeline pattern and Chain of
Responsibility?**

A: In Chain of Responsibility: a handler may or may not handle the
request; handlers are independent; the chain may stop early. In
Pipeline: every stage transforms the data; the output of one stage
is the input of the next; all stages always run. The patterns share
the structure (sequence of handlers) but differ in semantics.
Pipeline transforms; CoR routes or filters. In code: CoR handler
has `if (canHandle) handle else passToNext`. Pipeline stage always
processes and passes transformed data to next. A request validation
pipeline (all validators run, errors accumulate) is a Pipeline. An
authorization check chain (first failure stops the request) is CoR.
Many production systems use both: CoR for security filtering, Pipeline
for request transformation.
