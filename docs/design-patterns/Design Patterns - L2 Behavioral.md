---
layout: default
title: "Design Patterns - L2 Behavioral"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 7
permalink: /design-patterns/l2-behavioral/
---

# Command Pattern

---
id: DP-017
title: Command Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: high
asked_at: Mid+
seniority: mid-senior
tags: #design-patterns, #command, #behavioral, #undo, #queue
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Command encapsulates a request as an object, allowing you to queue
> requests, log them, and support undoable operations. The Command object
> contains all information needed to perform the action: the receiver,
> the method, and the parameters. The invoker calls `execute()` without
> knowing what the command does. This separation enables undo/redo stacks,
> task queues, and audit logs.

**3 minutes (Senior):**
> The core value of Command is that it converts a method call into a
> first-class object. Once a command is an object, you can: store it
> in a list (command history), put it in a queue (async execution),
> serialize it (persistent job queue), and call an `undo()` method
> (reverse the action). None of these are possible with a direct method
> call.
>
> Production uses: Spring's `ApplicationEventPublisher` with events that
> trigger commands. Java's `Runnable` and `Callable` are single-method
> Command interfaces used by `ExecutorService`. Spring Batch `ItemProcessor`
> is a Command applied to each batch item. Undo/redo in editors (every
> edit action is a Command pushed onto a stack). CQRS write side: each
> write operation is a Command object that is validated, executed, and
> event-sourced.
>
> The pattern behind CQRS: in Command Query Responsibility Segregation,
> every write is literally a Command object that the command handler
> executes. The command is the unit of intent; it carries what to do,
> not how to do it.

**Blank Mind Recovery:**

**(1) Restate:** "Command - the pattern that turns a method call into
an object."

**(2) First principles:** "Problem: I need to do more with a request
than just invoke it - queue it, log it, undo it. A method call is
ephemeral. Solution: capture the request in an object that can be
stored, passed, executed, or reversed."

**(3) Bridge:** "Like a restaurant order slip: the waiter writes your
order on paper (Command object), gives it to the kitchen (Invoker),
and the chef executes it. The slip can be queued, cancelled, or looked
up later. Direct verbal orders cannot be queued or cancelled."

---

### 📘 Concept Explanation

**What it is:**
Command encapsulates a request as an object. The command object stores
all information needed for execution (receiver, action, parameters).
An invoker calls the command's `execute()` method without knowing the
specifics of what it does.

**The problem it solves:**
When you need to: parameterize objects with operations, support undo/redo,
queue or delay execution, log all operations (for audit or replay), or
implement transactional operations with rollback.

**How it works:**

```
Command interface:
  + execute()
  + undo()        (optional)

ConcreteCommand implements Command:
  - receiver: Receiver
  - params: ...
  + execute():
      receiver.doAction(params)
  + undo():
      receiver.undoAction(params)

Receiver:
  + doAction(params)    // the real business logic
  + undoAction(params)  // reversal logic

Invoker:
  - commandHistory: Deque<Command>
  + executeCommand(cmd: Command):
      cmd.execute()
      commandHistory.push(cmd)
  + undo():
      if not empty:
          commandHistory.pop().undo()

Client:
  cmd = new ConcreteCommand(receiver, params)
  invoker.executeCommand(cmd)
  // Later:
  invoker.undo()
```

**The key insight:**
The Invoker never knows what the command does - it only knows the
`execute()` interface. This means the same Invoker can run any command:
a redo stack, a task queue, or a scheduler all work with the generic
`Command` interface.

**When to use it:**
- When you need to support undo/redo operations
- When you want to queue or schedule requests for later execution
- When you need to log all operations for auditing or replay
- When you need transactional behavior (execute with rollback on failure)

**When NOT to use it:**
- When commands are simple and undo/redo is not needed: `Runnable`
  or a direct method call is simpler
- When the command history grows unboundedly without pruning: memory
  leak risk (each command object may hold references to large state)

**Alternatives:**
- **Runnable/Callable** - command without undo; used for async execution
- **Lambda** - anonymous Command for simple, no-undo cases
- **CQRS Command** - Domain-Driven Design form: command is a DTO of
  intent, the Command Handler is the invoker/receiver

---

### 💻 Code Example

```java
// BAD: Direct operation - no undo, no queue, no audit
public class TextEditor {
    private StringBuilder text = new StringBuilder();

    public void type(String s) {
        text.append(s);  // cannot undo this
    }

    public void delete(int chars) {
        int start = text.length() - chars;
        text.delete(start, text.length());  // cannot undo
    }
}
```

> **Code walkthrough:** Direct mutation cannot be undone. Every operation
> is lost the moment it executes. No history, no rollback. To add undo,
> you would need to intercept every method and store state - invasive
> modification of the class.

```java
// GOOD: Command pattern with undo
public interface EditorCommand {
    void execute();
    void undo();
}

public class TextEditor {
    private StringBuilder text = new StringBuilder();
    private final Deque<EditorCommand> history = new ArrayDeque<>();

    public void executeCommand(EditorCommand command) {
        command.execute();
        history.push(command);
    }

    public void undo() {
        if (!history.isEmpty()) {
            history.pop().undo();
        }
    }

    // Expose mutators for commands to use
    void appendText(String s) { text.append(s); }
    void removeText(int chars) {
        int start = text.length() - chars;
        text.delete(start, text.length());
    }
    String getText() { return text.toString(); }
}

public class TypeCommand implements EditorCommand {
    private final TextEditor editor;
    private final String typedText;

    public TypeCommand(TextEditor editor, String text) {
        this.editor = editor;
        this.typedText = text;
    }

    public void execute() {
        editor.appendText(typedText);
    }

    public void undo() {
        // Reverse: remove the characters we typed
        editor.removeText(typedText.length());
    }
}

// Usage
TextEditor editor = new TextEditor();
editor.executeCommand(new TypeCommand(editor, "Hello"));
editor.executeCommand(new TypeCommand(editor, " World"));
System.out.println(editor.getText()); // "Hello World"
editor.undo();
System.out.println(editor.getText()); // "Hello"
editor.undo();
System.out.println(editor.getText()); // ""
```

> **Code walkthrough:** `TypeCommand` stores the text that was typed
> (so `undo()` knows how many characters to remove). `executeCommand()`
> pushes each command onto the history stack. `undo()` pops the last
> command and calls its `undo()` method. Each command is responsible
> for its own reversal. The editor (`Invoker`) only knows the
> `EditorCommand` interface - it does not know about TypeCommand,
> DeleteCommand, or any other command type.

```java
// PRODUCTION: Job queue with Command
@FunctionalInterface  // Command IS a functional interface
public interface Job {
    void execute();
}

@Service
public class JobQueue {
    private final BlockingQueue<Job> queue =
        new LinkedBlockingQueue<>();
    private final ExecutorService executor =
        Executors.newFixedThreadPool(4);

    @PostConstruct
    public void start() {
        // Worker threads consume the command queue
        for (int i = 0; i < 4; i++) {
            executor.submit(() -> {
                while (!Thread.interrupted()) {
                    Job job = queue.take();
                    job.execute();
                }
            });
        }
    }

    public void enqueue(Job job) {
        queue.put(job);
    }
}

// Usage: lambda as Command
jobQueue.enqueue(() -> emailService.send(email));
jobQueue.enqueue(() -> reportService.generate(reportId));
// Or with explicit Command class for retry/logging:
jobQueue.enqueue(new RetryableJob(
    () -> paymentService.charge(order), 3));
```

> **Code walkthrough:** `Job` is the Command interface. The `JobQueue`
> (Invoker) holds a blocking queue of Jobs and worker threads that call
> `execute()` on each. Callers enqueue lambdas (anonymous Commands) for
> simple jobs, or explicit Command objects (`RetryableJob`) for jobs
> that need retry logic. The queue decouples job submission from job
> execution - submitter does not wait for the job to complete.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Command turns a request into an object. The object has an `execute()`
> method. Because it is an object, you can store it (history stack for
> undo), queue it (async execution), or log it (audit). Java's `Runnable`
> and `Callable` are single-method Command interfaces used by
> `ExecutorService` for async execution - you are using Command every
> time you submit a task to a thread pool.

*Push deeper:* "Adding undo to an application is the canonical Command
use case. Each user action is a Command pushed onto a stack. Undo pops
the stack and calls `undo()`. The Command object stores any state needed
to reverse the action."

---

**Senior / Staff (5+ years):**
> Command and CQRS share the same fundamental insight: write operations
> should be explicit intent objects, not just method calls. In CQRS,
> every write is a Command DTO (CreateOrderCommand, CancelOrderCommand)
> handled by a Command Handler. The Handler is the Receiver. The Command
> Bus is the Invoker. This maps exactly to the GoF Command pattern
> at the architectural level.
>
> The production challenge: Command history management. If each command
> stores a snapshot of pre-mutation state for undo, memory grows with
> history depth. Strategies: (1) limit undo depth (discard commands
> older than N). (2) Store deltas (diffs) instead of snapshots.
> (3) Event sourcing: store all commands as events; replay from the
> beginning to any point. Event sourcing is Command's undo at
> unlimited depth - you can replay the entire history.

*Push deeper:* "Macro Command: a Command that contains a list of
Commands. `execute()` runs all commands in sequence. `undo()` runs all
`undo()` methods in reverse order. This is how 'undo transaction' works
in a database: the transaction is a Macro Command; rollback calls
`undo()` on each step in reverse."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What is the Command pattern? What are its four main uses?"

🗣️ "Command encapsulates a request as an object. The four main uses:
(1) Undo/redo - the command stores state needed to reverse itself; a
history stack enables multi-level undo. (2) Queuing/scheduling - commands
can be stored in a queue and executed asynchronously by worker threads
(`ExecutorService` with `Runnable`/`Callable`). (3) Logging/auditing -
every command execution can be logged with its parameters, creating an
audit trail or an event log that can be replayed. (4) Transactional
operations - commands can be executed in a transaction; on failure, the
command's `undo()` method (or a compensating command) restores the
pre-action state."

#### Mechanism
- "How does Command enable undo? Walk through the data structures."

🗣️ "The invoker (editor, transaction manager) maintains a `Deque<Command>`.
On `executeCommand(cmd)`: call `cmd.execute()` and push `cmd` onto the
deque. On `undo()`: pop the top command, call `cmd.undo()`. Each command
stores the information needed for its own reversal: a `TypeCommand`
stores the text that was typed (to remove it on undo). A `DeleteCommand`
stores the deleted text (to re-insert it on undo). A `MoveCommand` stores
the previous position (to move back). The undo operation is always specific
to each command type - the Invoker just calls `undo()` polymorphically.
For redo: maintain a separate redo stack; on undo, push the command onto
the redo stack; on redo, pop from redo stack and re-execute."

#### Comparison
- "Compare Command vs Strategy."

🗣️ "Both encapsulate behavior as objects. The difference is intent and
state. Strategy: encapsulates an algorithm - the 'how' to do something.
Stateless or lightly stateful. Used repeatedly with different contexts.
Command: encapsulates a specific request with specific parameters and
possibly state for reversal. Often used once (or a few times). Carries
the 'what' (intent) and any state needed for undo. Strategy is about
selecting an algorithm. Command is about recording and managing an
operation. Concrete example: `SortStrategy` (how to sort - by name,
by date) vs `DeleteFileCommand` (delete this specific file, with the
file's path stored for undo)."

#### Scenario
- "Design a macro system for a spreadsheet application."

🗣️ "Every user action (type in cell, format cell, insert row, delete
column) is a `SpreadsheetCommand` with `execute()` and `undo()`.
A `Macro` is a `CompositeCommand` (list of commands) with `execute()`
that runs all commands in sequence and `undo()` that runs them in reverse.
Recording a macro: toggle record mode, execute user actions (each action
is pushed onto the macro's command list), stop recording. Playing back:
call macro's `execute()`. Undo the macro: call `undo()`. Saving macros:
serialize the command list to disk. The spreadsheet application's undo
stack tracks all actions including macro execution; one undo step undoes
the entire macro."

#### Debugging
- "Undo is not restoring the previous state correctly. How do you
  debug it?"

🗣️ "I check three things. First: is the command storing the correct
pre-mutation state? Add a logging assertion: before `execute()`, capture
the state; after `undo()`, compare. If the state after undo does not
match the pre-execute state, the `undo()` implementation has a bug.
Second: is the command being pushed onto the history stack before or
after execution? If pushed after a failed execution, the history may
have commands whose execution was partial. Third: are there side effects
the command does not reverse? For example, a `CreateOrderCommand` creates
a row in two tables; `undo()` must delete rows from both tables, not just
one. Any external effect (email sent, notification pushed) that is not
captured in `undo()` creates inconsistency - these require compensating
actions, not reversal."

#### Comparison Table

| Aspect | Command | Runnable | Strategy | Event |
|---|---|---|---|---|
| Encapsulates | Specific request + params | Runnable task | Algorithm | State change |
| Undo support | Yes (explicit undo()) | No | No | No |
| Queuing | Yes (serializable) | Yes | No | Via event bus |
| Identity | Specific (carries params) | Generic | Generic | Specific (event type) |
| Best for | Undo, auditing, CQRS | Thread pool tasks | Algorithm swap | Observer notifications |

---

### ⚖️ Comparison Table

| Factor | Command | Strategy | Observer | Template Method |
|---|---|---|---|---|
| Encapsulates | An operation (request) | An algorithm | A notification | A step in algorithm |
| Caller relationship | Invoker calls execute() | Context uses strategy | Subject notifies | Framework calls hook |
| Undo support | Built-in (undo()) | Not applicable | Not applicable | Not applicable |
| State carried | Yes (params, pre-state) | Sometimes | No (just event) | No |
| CQRS role | Write-side command | N/A | Event-driven | N/A |

---

### 🔥 Field Q&A

**Q: How does the Command pattern relate to Event Sourcing?**

A: Event Sourcing is Command at the persistence level. In Command:
commands are executed and their effects modify mutable state (the
editor's text buffer changes). In Event Sourcing: every command
generates an event (immutable fact) stored in an append-only log.
State is derived by replaying all events from the beginning. Undo in
Event Sourcing: instead of calling `command.undo()` (which mutates
state), you add a compensating event (a new event that reverses the
effect). The log is never mutated. The key benefit: complete audit
history, time-travel debugging, and replay capability. The cost:
rebuilding state from a long event log is slow; snapshots (periodic
state captures) are needed to avoid full replay on every query.

**Q: A job queue processes 10,000 commands/sec. A subset of commands
fail and must be retried with exponential backoff. Design this.**

A: Command decorator (`RetryableCommand`) wraps any `Command` and adds
retry logic. It stores: the wrapped command, current attempt count,
max attempts, last failure time, and exponential backoff configuration.
On `execute()`: try the wrapped command; if it throws a retriable
exception, check if max attempts exceeded. If not: calculate next
retry time (`baseDelay * 2^attempt`), schedule re-enqueue after the
delay (use `ScheduledExecutorService`). If max exceeded: emit a
`DeadLetterEvent`. The dead letter queue holds all permanently failed
commands for manual inspection. The original command is unchanged -
the retry logic is the decorator's responsibility. In production:
Resilience4j's `Retry` decorator handles this. For persistent retry
across JVM restarts: store failed commands in a `retry_queue` database
table with next_attempt_time column.

---

# Iterator Pattern

---
id: DP-018
title: Iterator Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: medium
asked_at: All
seniority: all
tags: #design-patterns, #iterator, #behavioral, #collections
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Iterator provides a way to sequentially access elements of a collection
> without exposing the collection's internal structure. The iterator
> interface decouples traversal from the collection. Java's `Iterable`,
> `Iterator`, and the enhanced `for-each` loop are direct implementations
> of this pattern. Every `Collection` in Java implements `Iterable`
> - you use the Iterator pattern every day.

**3 minutes (Senior):**
> The problem Iterator solves: different collection structures (array,
> linked list, tree, graph, database result set) have different traversal
> mechanisms. Without Iterator, client code must know the internal structure
> to traverse it. With Iterator, all collections expose a uniform
> `hasNext()/next()` interface; client code is identical regardless of
> the collection type.
>
> The Java design: `Collection` extends `Iterable<T>` which requires
> `iterator()` returning an `Iterator<T>`. The `for-each` loop calls
> `iterator()` and uses `hasNext()/next()`. `JdbcTemplate.query()` wraps
> a `ResultSet` - a database cursor (Iterator) - with a `RowMapper`
> that maps each row. The `ResultSet` is an Iterator over database records.
>
> The production variant: external vs internal iterator. External iterator
> (GoF): the client drives the iteration (`while (iter.hasNext()) iter.next()`).
> Internal iterator (streams): the collection drives the iteration
> (`collection.stream().forEach(action)`) - callers provide the action.
> Java streams are internal iterators with lazy evaluation and composition.

**Blank Mind Recovery:**

**(1) Restate:** "Iterator - the pattern that provides a uniform way to
traverse any collection."

**(2) First principles:** "Problem: I need to traverse a collection.
Each collection type traverses differently. Solution: standardize traversal
behind a `hasNext()/next()` interface. The collection creates its own
iterator; client code is universal."

**(3) Bridge:** "Like a tour guide: the guide (Iterator) knows the
route through the museum (collection). Visitors (clients) just say
'next exhibit please.' They do not need to know the museum's layout."

---

### 📘 Concept Explanation

**What it is:**
Iterator provides a way to access elements of an aggregate object
sequentially without exposing its internal representation. The iterator
object encapsulates traversal state and progress.

**The problem it solves:**
When clients need to traverse a collection but should not depend on the
collection's internal structure (array, tree, linked list). When you
want multiple simultaneous traversals of the same collection (each
traversal has its own iterator with its own position).

**How it works:**

```
Iterator interface:
  + hasNext(): boolean
  + next(): T

Iterable interface:
  + iterator(): Iterator<T>

ConcreteCollection implements Iterable<T>:
  - data: ...internal structure...
  + iterator(): ConcreteIterator(this)

ConcreteIterator implements Iterator<T>:
  - collection: ConcreteCollection
  - position: int  (traversal state)
  + hasNext(): position < collection.size()
  + next():
      element = collection.get(position)
      position++
      return element

// Usage - external iterator:
Iterator<String> iter = collection.iterator();
while (iter.hasNext()) {
    String element = iter.next();
    process(element);
}

// Java for-each (calls iterator() implicitly):
for (String element : collection) {
    process(element);
}
```

**External vs Internal Iterator:**
- **External Iterator** (GoF, Java `Iterator`): client controls the
  traversal pace. Client calls `hasNext()/next()`. Can pause, skip,
  or interleave multiple iterators.
- **Internal Iterator** (Java streams, `forEach`): the collection
  drives the iteration. Client provides a callback. Enables lazy
  evaluation, parallel execution, and fluent composition.

**The key insight:**
The iterator is a separate object from the collection. This means:
(1) Multiple iterators can traverse the same collection simultaneously,
each with independent position state. (2) The collection's internal
structure is not exposed. (3) Any aggregate can implement `Iterable`
to participate in for-each loops and stream operations.

**When to use it:**
- When you need to traverse a custom data structure in for-each loops
  or with Java streams
- When the traversal algorithm should be separated from the collection
  (e.g., breadth-first vs depth-first over the same tree)
- When you need to support multiple simultaneous traversals

**When NOT to use it:**
- For simple lists and maps: Java's built-in collection framework
  already provides Iterator
- When random access by index is needed (Iterator is sequential;
  use `get(index)` directly)

**Alternatives:**
- **Java Stream API** - internal iterator with lazy evaluation,
  parallel processing, and functional composition
- **Spliterator** - Java 8's parallelizable iterator
- **Cursor** - database result set (same concept, SQL context)

---

### 💻 Code Example

```java
// Custom tree iterator using external Iterator pattern
public class BinaryTree<T> implements Iterable<T> {
    private Node<T> root;

    // Inner Iterator - owns traversal state
    @Override
    public Iterator<T> iterator() {
        return new InOrderIterator();
    }

    private class InOrderIterator implements Iterator<T> {
        private final Deque<Node<T>> stack = new ArrayDeque<>();

        InOrderIterator() {
            // Push left spine of tree onto stack
            pushLeft(root);
        }

        @Override
        public boolean hasNext() {
            return !stack.isEmpty();
        }

        @Override
        public T next() {
            if (!hasNext()) throw new NoSuchElementException();
            Node<T> node = stack.pop();
            pushLeft(node.right);  // in-order: process right subtree
            return node.value;
        }

        private void pushLeft(Node<T> n) {
            while (n != null) {
                stack.push(n);
                n = n.left;
            }
        }
    }
}

// Usage - for-each works because Iterable is implemented
BinaryTree<Integer> tree = new BinaryTree<>();
// ... build tree
for (int value : tree) {  // uses InOrderIterator
    System.out.println(value);  // prints in sorted order
}
// Or with streams:
tree.stream().filter(v -> v > 10).forEach(System.out::println);
```

> **Code walkthrough:** The tree implements `Iterable`, exposing
> `iterator()` which returns an `InOrderIterator`. The iterator owns
> the traversal stack - it knows where it is in the tree. Two iterators
> on the same tree are independent: `Iterator<Integer> iter1 = tree.iterator(); Iterator<Integer> iter2 = tree.iterator()` - each has its own stack.
> The client uses `for-each` without knowing the tree's internal structure.
> The tree could change from a binary tree to a B-tree without changing
> any client code.

```java
// PRODUCTION: ResultSet as Iterator over database rows
// JdbcTemplate wraps ResultSet (database cursor = Iterator)
public interface RowMapper<T> {
    T mapRow(ResultSet rs, int rowNum) throws SQLException;
}

// JdbcTemplate.query() internals (simplified):
public <T> List<T> query(String sql,
                          RowMapper<T> rowMapper) {
    List<T> results = new ArrayList<>();
    try (Connection conn = dataSource.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql);
         ResultSet rs = ps.executeQuery()) {

        int rowNum = 0;
        // rs is the Iterator: rs.next() = Iterator.next()
        while (rs.next()) {
            // rowMapper maps the current row (Iterator position)
            results.add(rowMapper.mapRow(rs, rowNum++));
        }
    }
    return results;
}

// Usage - the client provides mapping (RowMapper), not traversal:
List<Order> orders = jdbcTemplate.query(
    "SELECT * FROM orders WHERE status = 'PENDING'",
    (rs, rowNum) -> Order.builder()
        .id(rs.getLong("id"))
        .customerId(rs.getLong("customer_id"))
        .build());
```

> **Code walkthrough:** `ResultSet` is an iterator over database rows:
> `rs.next()` advances and returns true if there are more rows (like
> `Iterator.hasNext()` and `Iterator.next()` combined). JdbcTemplate's
> `query()` is an internal iterator: it drives the traversal and calls
> the `RowMapper` for each row. The client provides the mapping function
> (what to do with each row), not the traversal (how to advance through
> rows). This is the internal iterator pattern in production.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Iterator provides a uniform way to traverse any collection. Java's
> `Iterator` interface (`hasNext()/next()`) and `Iterable` (returns an
> `Iterator`) are the direct implementation. The `for-each` loop uses
> `Iterable` behind the scenes. I use it when I build a custom data
> structure and want to make it iterable: implement `Iterable<T>` and
> return an inner class `Iterator`.

*Push deeper:* "The advantage of Iterator over direct field access:
you can change the collection's internal structure (from array to
linked list) without changing client traversal code. The iterator
is the abstraction that shields clients from storage details."

---

**Senior / Staff (5+ years):**
> The more interesting Iterator discussion is external (GoF) vs internal
> (streams). External: `while (iter.hasNext()) { iter.next(); }` - client
> controls pacing, can pause, skip, interleave. Internal: `stream.filter().map().collect()` - the stream framework controls execution, enabling
> lazy evaluation (elements computed only when needed) and transparent
> parallelism (`parallelStream()`).
>
> For custom data structures in Java, implement `Iterable` and `Spliterator`
> to support both sequential and parallel streams. The `Spliterator` defines
> how to split the traversal for parallel execution: give half the elements
> to one thread, half to another. `ArrayList` provides a `Spliterator` that
> splits by index range; a custom tree's `Spliterator` might split by subtree.

*Push deeper:* "The `ConcurrentModificationException` is the most common
Iterator bug. If you modify a collection while iterating it with an
external iterator (ArrayList, HashMap), the iterator detects it (via
`modCount`) and throws. Fix: use `Iterator.remove()` instead of
`collection.remove()` for removal during iteration, or use `removeIf()`,
or create a copy to iterate while removing from the original."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What is the Iterator pattern? How does Java implement it?"

🗣️ "Iterator provides sequential access to elements of an aggregate
without exposing the aggregate's internal representation. Java's
implementation: the `Iterator<T>` interface with `hasNext()` and
`next()`, and `Iterable<T>` with `iterator()`. Any class implementing
`Iterable` participates in for-each loops. The enhanced for-each
(`for (T item : collection)`) is syntactic sugar for calling `iterator()`
and looping with `hasNext()/next()`. All Java collections implement
`Iterable`. Custom data structures (trees, graphs) can become for-each
compatible by implementing `Iterable` and providing an inner `Iterator`
that manages traversal state."

#### Mechanism
- "How does ConcurrentModificationException work? When and why is it thrown?"

🗣️ "Java's fail-fast collections (ArrayList, HashMap, HashSet) track
a `modCount` integer that is incremented on every structural modification.
When an iterator is created, it captures the current `modCount`.
On each call to `hasNext()` or `next()`, the iterator checks if the
collection's `modCount` still matches. If it changed (another modification
happened), it throws `ConcurrentModificationException`. This is a
fail-fast mechanism - better to throw immediately than to silently
produce incorrect results. It is NOT thread-safe protection: two threads
can modify and iterate simultaneously; one might see the exception, or
neither might, depending on timing. Fix during iteration: use
`Iterator.remove()` for safe removal. For concurrent access: use
`CopyOnWriteArrayList` (copies on write, iterates the original) or
`ConcurrentHashMap.entrySet().removeIf()`."

#### Comparison
- "Compare external Iterator vs Java Streams (internal Iterator)."

🗣️ "External Iterator (`Iterator.hasNext()/next()`): client drives
traversal. Can pause midway, skip elements, interleave two iterators.
Suitable when traversal must be stateful or interleaved. Internal Iterator
(Java Streams): the collection drives traversal; client provides a function
for each element. Supports lazy evaluation (elements computed on demand),
parallel execution (transparent via `parallelStream()`), and composable
transformations (map/filter/reduce as a pipeline). Streams are more
expressive for bulk data transformations. External iterators are better
for interleaved or paused traversals. `for-each` is external. `.stream()`
is internal. Both use the Iterator concept; the control direction differs."

#### Scenario
- "You have a paginated API that returns 100 items per page. Design
  an Iterator that transparently fetches pages as needed."

🗣️ "Implement `Iterator<Item>`. Internal state: current page number,
current index within the page, current page's items, and a flag for
whether there are more pages. `hasNext()`: check if current index is
within the current page OR if there is a next page to fetch.
`next()`: if at the end of the current page, fetch the next page
(API call), reset the index. Return and advance the index.
The client iterates `for (Item item : paginatedIterator)` without
knowing that every 100 items triggers an API call. For high throughput:
prefetch the next page while the client processes the current page
(background thread). This is the cursor-based pagination pattern."

#### Debugging
- "An Iterator is throwing ConcurrentModificationException in a
  single-threaded application. Why?"

🗣️ "This happens when the collection is modified while being iterated.
Common single-threaded cause: calling `list.remove(item)` inside a
`for-each` loop. The for-each uses an Iterator internally; calling
`list.remove()` increments the list's `modCount`; the iterator detects
the mismatch. Fix: use `iterator.remove()` for safe removal, or collect
elements to remove in a separate list and call `list.removeAll(toRemove)`
after the loop, or replace the loop with `list.removeIf(predicate)` which
handles concurrent modification internally."

#### Comparison Table

| Aspect | External Iterator | Internal Iterator (Streams) | Spliterator |
|---|---|---|---|
| Control | Client-driven | Collection-driven | Parallelism-aware |
| Laziness | Not lazy (unless custom) | Lazy by default | Lazy |
| Parallel support | No | Via parallelStream() | Designed for splitting |
| Pausing/interleaving | Yes | No (terminal operation) | No |
| Use case | Custom traversal logic | Bulk transformations | Parallel streams |

---

### ⚖️ Comparison Table

| Factor | Iterator | Stream | Spliterator | ResultSet |
|---|---|---|---|---|
| Control | External (client) | Internal (pipeline) | Parallel-aware | External (client) |
| Lazy evaluation | No (by default) | Yes | Yes | Yes (DB cursor) |
| Composable | No (manual) | Yes (map/filter/reduce) | Yes | Via SQL |
| Parallel | No | Yes (parallelStream) | Yes | Via DB partitioning |
| Mutable? | Source can be mutated (CME) | Immutable source | Immutable source | Read-only |

---

### 🔥 Field Q&A

**Q: How do you implement an Iterator that traverses a tree in
depth-first and breadth-first order with the same tree class?**

A: Implement two inner Iterator classes. `DepthFirstIterator` uses
a `Deque` as a stack (push children, pop to visit - LIFO = DFS).
`BreadthFirstIterator` uses a `Deque` as a queue (offer children, poll
to visit - FIFO = BFS). The tree's `Iterable` interface can provide
both: `tree.depthFirst()` returns a `BreadthFirstIterator` and
`tree.breadthFirst()` returns a `DepthFirstIterator`. Both implement
`Iterable<T>`, so they work with for-each: `for (T node : tree.breadthFirst())`.
The tree structure is unchanged - only the traversal order is different.
This separates traversal strategy from collection structure. For Java
streams: `tree.depthFirst().stream()` or `tree.breadthFirst().stream()`.

**Q: You need to iterate over a database result set lazily, processing
one row at a time to avoid loading all rows into memory. How?**

A: Implement an `Iterator<MyEntity>` that wraps a `ResultSet` (kept
open). `hasNext()` calls `rs.isLast()` or maintains a lookahead flag.
`next()` calls `rs.next()` and maps the current row to `MyEntity`.
`close()` (implement `AutoCloseable`) closes the `ResultSet` and
connection. Use with try-with-resources. This is the cursor-based
processing pattern. Spring Data supports this with `Stream<Entity>`
from a `@Query` method - Spring opens a cursor, returns a lazy `Stream`,
you process and close. Never use this for high-concurrency: one DB
connection is held open per iterator instance, which can exhaust
the connection pool.
