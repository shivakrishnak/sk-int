---
layout: default
title: "Java Language - L3 Exception Handling"
parent: "Java Language"
grand_parent: "SK Interview"
nav_order: 10
permalink: /java-language/l3-exception-handling/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Language - L3 Exception Handling](#java-language---l3-exception-handling) | medium |

---

# Java Language - L3 Exception Handling

## Exception Hierarchy: Checked vs Unchecked

---

### 🎯 Model Answer

**30 seconds:**
> Java exception hierarchy: `Throwable` -> `Error` (JVM failures, not catch), `Exception` ->
> `RuntimeException` (unchecked). Checked exceptions: must be caught or declared (`throws`).
> Unchecked: `RuntimeException` and subclasses, no declaration required. Rule: use checked
> for recoverable conditions (caller can/should handle), unchecked for programming errors
> (caller cannot reasonably recover).

**3 minutes (Senior):**
> Key mechanics and design:
>
> 1. **Checked exception contract**: forces API callers to acknowledge the exceptional case.
>    `IOException`, `SQLException`, `ParseException` - part of the method contract. The caller
>    either handles it (try-catch) or propagates it (throws declaration).
>
> 2. **Unchecked exception philosophy**: `NullPointerException`, `IllegalArgumentException`,
>    `IllegalStateException` - indicate programming errors that the caller cannot meaningfully
>    handle. No `throws` declaration required.
>
> 3. **Multi-catch and re-throw**: `catch (IOException | SQLException e)` - catch both in one
>    block. Re-throw as a different exception: `catch (Exception e) { throw new RuntimeException(e); }`.
>    Preserve the original cause: always pass the original exception as the cause.
>
> 4. **Exception chaining**: new exception wraps the original. The stack trace preserves both.
>    `new AppException("context message", originalException)`. Never lose the cause.
>
> 5. **try-with-resources**: `AutoCloseable` resources closed automatically. Multiple resources:
>    closed in reverse declaration order. Suppressed exceptions: if both the body and close()
>    throw, the close exception is suppressed (accessible via `e.getSuppressed()`).

**Blank Mind Recovery:**

**(1) Restate:** "Throwable: Error (don't catch), Exception (checked: must declare/catch), RuntimeException (unchecked: no declaration). try-with-resources: auto-close. Multi-catch: `IOException | SQLException`. Exception chaining: always pass cause."

**(2) First principles:** "Checked exceptions: a compile-time reminder that this operation might fail in a known way. Unchecked: developer mistakes. The design tension: checked exceptions force callers to think about failure; they also add noise to APIs that can't do anything about the failure."

**(3) Bridge:** "Checked exceptions are like mandatory safety warnings on a power tool: you must acknowledge the danger before using it. Unchecked exceptions are like programming the wrong inputs: the tool breaks and it's your fault. Errors are like a power blackout: you can't program around it."

---

### 📘 Concept Explanation

**Exception hierarchy and mechanics:**
```
EXCEPTION HIERARCHY:

  Throwable
    Error                     <- JVM/system-level, do not catch (generally)
      OutOfMemoryError        <- heap exhausted
      StackOverflowError      <- infinite recursion
      AssertionError          <- assert statement failed
      LinkageError
    Exception                 <- application-level
      IOException             <- checked: I/O failures
        FileNotFoundException <- checked: specific file I/O
      SQLException            <- checked: database failures
      InterruptedException    <- checked: thread interrupt
      ReflectiveOperationException <- checked: reflection failures
      RuntimeException        <- UNCHECKED: programming errors
        NullPointerException  <- null dereference
        IllegalArgumentException <- invalid argument
        IllegalStateException <- invalid object state
        ArrayIndexOutOfBoundsException
        ClassCastException
        NumberFormatException
        ConcurrentModificationException
        UnsupportedOperationException
        NoSuchElementException

CHECKED vs UNCHECKED DECISION:
  
  Use CHECKED when:
    - Caller can reasonably recover (try different path, ask user to retry)
    - The failure is predictable and expected (file not found, network timeout)
    - The failure represents a contract violation the caller should know about
    Example: FileNotFoundException (caller can show error to user, try alternative file)
    
  Use UNCHECKED when:
    - Failure is a programming error (NPE, wrong argument)
    - Caller cannot meaningfully recover
    - The failure is a contract violation by the caller (pre-condition not met)
    Example: IllegalArgumentException (fix the code that passed the bad argument)

TRY-WITH-RESOURCES:
  try (Connection conn = dataSource.getConnection();    // outer
       PreparedStatement ps = conn.prepareStatement(sql)) {  // inner
      // use conn and ps
  }
  // ps.close() called first (reverse order), then conn.close()
  // Even if close() throws, the original exception (if any) is preserved
  // The close() exception is added as a SUPPRESSED exception:
  //   originalException.getSuppressed()[0] = close exception
  
  // Access suppressed exceptions:
  try { ... }
  catch (Exception e) {
      for (Throwable suppressed : e.getSuppressed()) {
          log.warn("Suppressed exception during close", suppressed);
      }
  }

EXCEPTION CHAINING (ALWAYS INCLUDE CAUSE):
  // BAD: losing original cause
  try {
      processFile(path);
  } catch (IOException e) {
      throw new AppException("Failed to process file");  // WRONG: loses stack trace
  }
  
  // GOOD: chain the exception
  try {
      processFile(path);
  } catch (IOException e) {
      throw new AppException("Failed to process file: " + path, e);  // preserves cause
  }
  // In AppException: must call super(message, cause) in constructor

CHECKED EXCEPTION CONTROVERSY:
  Pro:
    - Forces callers to think about failure
    - Makes API contracts explicit
    - Good for critical operations (DB, file, network)
  
  Con:
    - Pollutes APIs (throws clauses cascade up call chains)
    - Often handled by empty catch blocks (swallowing)
    - Cannot use in lambdas (functional interfaces don't throw checked)
    - Modern frameworks (Spring, Hibernate): wrap all checked in unchecked
  
  Modern consensus: checked exceptions are valuable for library/framework boundaries,
  less useful for application-level code. Most modern Java APIs use unchecked.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The `DataProcessor` shows the correct try-with-resources pattern
> with exception chaining. The custom exception hierarchy shows how to structure domain
> exceptions that preserve context while wrapping low-level causes.

```java
// CORRECT EXCEPTION HANDLING:

// BAD: swallowing exceptions
try {
    process();
} catch (Exception e) {
    // empty: exception is silently ignored
}

// BAD: logging and rethrowing without proper chaining
try {
    process();
} catch (Exception e) {
    log.error("Error occurred");
    throw new RuntimeException("Error occurred");  // loses original cause
}

// GOOD: wrap with context, preserve cause
try {
    process();
} catch (IOException e) {
    throw new DataProcessingException("Failed to read config from " + configPath, e);
}

// TRY-WITH-RESOURCES: multiple resources, correct cleanup
class DataProcessor {
    List<Record> load(Path path) {
        try (
            FileInputStream fis = new FileInputStream(path.toFile());
            BufferedReader reader = new BufferedReader(new InputStreamReader(fis))
        ) {
            return reader.lines()
                .map(this::parseLine)
                .collect(Collectors.toList());
        } catch (IOException e) {
            throw new DataProcessingException(
                "Failed to load data from " + path, e);
        }
    }
    // reader.close() and fis.close() called automatically, in reverse order
}

// DOMAIN EXCEPTION HIERARCHY:
// Base: runtime (unchecked for modern apps), with context
class AppException extends RuntimeException {
    private final String errorCode;
    
    AppException(String message, String errorCode) {
        super(message);
        this.errorCode = errorCode;
    }
    
    AppException(String message, String errorCode, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }
    
    String getErrorCode() { return errorCode; }
}

class UserNotFoundException extends AppException {
    private final Long userId;
    
    UserNotFoundException(Long userId) {
        super("User not found: " + userId, "USER_NOT_FOUND");
        this.userId = userId;
    }
    
    Long getUserId() { return userId; }
}

// MULTI-CATCH (Java 7+):
try {
    Statement stmt = conn.prepareStatement(sql);
    ResultSet rs = stmt.executeQuery();
    // ...
} catch (SQLException | ParseException e) {
    // 'e' is the common supertype (Throwable in this case)
    throw new DataAccessException("Query failed", e);
}

// SNEAKY THROW (without checked exception declaration):
@SuppressWarnings("unchecked")
static <T extends Throwable, R> R sneakyThrow(Throwable t) throws T {
    throw (T) t;  // unchecked cast at compile time, but T is the actual type
}
// Usage in lambda (rare, use with care):
stream.forEach(item -> {
    try { process(item); }
    catch (IOException e) { sneakyThrow(e); }  // re-throw without declaring
});
```

> **Code walkthrough:** The `DataProcessor.load()` shows the correct `try-with-resources`
> form: resources declared in order of creation, closed in reverse. The `DataProcessingException`
> wraps the `IOException` with domain context. The domain exception hierarchy (`AppException`,
> `UserNotFoundException`) shows structured exception design: a base runtime exception with an
> error code for programmatic handling, specialized subclasses for specific domain errors.
> Error codes enable API responses to map exception types to HTTP status codes without
> `instanceof` chains.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Checked: must catch or declare. `Exception` and subclasses (except `RuntimeException`).
> Unchecked: `RuntimeException` - no declaration needed. try-with-resources: auto-close resources.
> Always include the cause when wrapping: `new RuntimeException("message", e)`.

---

**Senior / Staff (5+ years):**
> Exception design: use a domain exception hierarchy with an error code. Map to HTTP status in a
> global exception handler (`@ControllerAdvice` in Spring). Never lose exception causes (chain them
> always). Checked exceptions in lambdas: use the unchecked wrapper or custom `@FunctionalInterface`
> with `throws`. try-with-resources: understand suppressed exceptions (`getSuppressed()`) for
> diagnosing cleanup failures. The modern consensus: unchecked exceptions for application code,
> checked only at integration boundaries (and wrapped at the boundary).

---

### ⚠️ Common Misconceptions

**Misconception 1: "You should always catch the most specific exception type."**
Catch the most specific type that you can meaningfully handle differently. If `FileNotFoundException`
and `IOException` require the same handling: catch `IOException` (both are covered). If you need
different handling: `catch (FileNotFoundException e)` then `catch (IOException e)`. Don't create
5 catch blocks that all do the same thing just to be "specific." Multi-catch (`FileNotFoundException | NetworkException`) when two different types need the same handling.

**Misconception 2: "Error types should not be caught."**
The rule is "generally don't catch Errors" - but there are legitimate exceptions. `OutOfMemoryError`:
catching to log a meaningful message and exit cleanly can be appropriate in some production scenarios.
`AssertionError`: can be caught in test frameworks to report test failures. The general rule: don't
catch Errors in application code without a specific, documented reason. `Throwable` catch in global
handlers (e.g., Thread.uncaughtExceptionHandler): valid for logging and shutdown.

---

### 🚨 Failure Modes and Diagnosis

**Failure: InterruptedException swallowed inside a loop.**
```
Symptom: Thread shutdown takes 30 seconds instead of immediately.
  Thread.stop() was replaced with interrupt(), but it has no effect.

Root cause:
  class WorkerTask implements Runnable {
      @Override
      public void run() {
          while (running) {
              try {
                  process();
                  Thread.sleep(1000);  // wait between polls
              } catch (InterruptedException e) {
                  // swallowed: interrupt flag is cleared by the catch,
                  // not restored. The loop continues.
              }
          }
      }
  }
  
  When Thread.interrupt() is called on this thread:
  1. Thread.sleep() throws InterruptedException (good!)
  2. The catch block swallows it (bad!)
  3. The interrupt flag is cleared by the exception (bad! It's gone now.)
  4. The loop continues normally -> thread never stops

Fix:
  // Option A: Re-interrupt after catching
  catch (InterruptedException e) {
      Thread.currentThread().interrupt();  // restore the interrupt flag
      break;  // then exit the loop
  }
  
  // Option B: Propagate the exception (if method declares throws)
  catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new RuntimeException("Task interrupted", e);
  }
  
  // Option C: Check interrupt flag directly
  while (running && !Thread.currentThread().isInterrupted()) {
      process();
      Thread.sleep(1000);  // will throw InterruptedException if interrupted
  }

Prevention: NEVER swallow InterruptedException.
  ALWAYS do one of:
    - Re-interrupt: Thread.currentThread().interrupt()
    - Propagate: throw new RuntimeException(e)
    - Exit: break/return (after re-interrupting)
  
  Rule: InterruptedException = someone wants this thread to stop.
  Respect it or at least restore the flag.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Checked vs unchecked design | 2 minutes |
| Exception chaining | 1 minute |
| try-with-resources mechanics | 2 minutes |
| Suppressed exceptions | 2 minutes |
| InterruptedException handling | 2 minutes |
| Domain exception hierarchy | 2 minutes |
| Exception in lambda | 1 minute |
| Multi-catch | 1 minute |
| finally block behavior | 1 minute |

---

**Q1 (design): When do you choose a checked exception over an unchecked exception?**

A: Checked: when the caller has a reasonable, documented recovery path. `FileNotFoundException`: caller can use a default configuration file. `SQLException` (in JDBC layer): caller can retry or show an error message. Unchecked: when the failure is a programming error (wrong argument, wrong state), the caller can't recover, or the failure cascades far up the call stack (most callers can't do anything useful). Modern practice: unchecked for application code, checked only at system boundaries (file, network, database) wrapped into unchecked at the boundary.

*What separates good from great:* The "cascade problem" with checked exceptions: `a()` calls `b()` calls `c()`, and `c()` throws `IOException`. If uncaught: `b()` and `a()` must both declare `throws IOException` even if they don't know what to do with it. This "checked exception pollution" makes the API noisy. Solution: (1) handle at `c()` level, (2) wrap in unchecked at `c()` level, (3) use a checked exception that's meaningful at each level (translation). Spring, Hibernate: wrap ALL checked exceptions in `DataAccessException` (unchecked) so application code doesn't have to declare `throws SQLException` everywhere. This is the recommended pattern for any framework-wrapping layer.

---

**Q2 (chaining): Why is exception chaining critical and what happens when you lose the cause?**

A: Exception chaining: `throw new AppException("context", e)`. The original exception (`e`) is the "cause" - accessible via `getCause()`. Stack trace: both the wrapping and original exception's traces are printed. Without cause: the log shows `AppException: context` with AppException's stack trace. The root cause (the `IOException` from inside a third-party library call) is gone. Debugging: you see WHERE the error was thrown but not WHY (what the underlying system reported).

*What separates good from great:* The debugging scenario without cause: `AppException: Failed to load config at path /etc/app.yml`. Where did this fail? `AppException` was thrown at line 145. But WHY? The `IOException` at line 145 might have been `FileNotFoundException` (path wrong) or `AccessDeniedException` (permissions). Without the cause, you can't distinguish. With cause: the stack trace shows `Caused by: java.io.FileNotFoundException: /etc/app.yml (No such file or directory)`. The fix is obvious. In production: this is the difference between a 5-minute and a 2-hour debugging session. Rule: every `catch (Exception e) { throw new X("msg"); }` that drops `e` is a future debugging disaster.

---

**Q3 (try-with-resources): What happens when both the body and the close() throw exceptions?**

A: The body exception is the PRIMARY exception. The close() exception is "suppressed" (attached to
the primary via `addSuppressed()`). The primary exception propagates. You can access the suppressed:
`e.getSuppressed()` = array of exceptions that were suppressed during close(). If ONLY close() throws
(no body exception): the close exception is the primary exception (not suppressed). In Java 6
(before try-with-resources): close exceptions were typically lost or replaced the body exception
in finally blocks.

*What separates good from great:* The pre-try-with-resources `finally` pattern: `Connection conn = null; try { conn = ...; ... } finally { if (conn != null) conn.close(); }`. If both the body and `close()` throw: in Java 6, the `finally` exception REPLACES the body exception (the original exception is lost). This was a bug in many pre-Java 7 codebases. `try-with-resources` (Java 7) fixed this: the body exception is always the primary, close exceptions are always suppressed. This is why `try-with-resources` is mandatory for `AutoCloseable` resources: not just for brevity, but for correct exception semantics.

---

**Q4 (finally semantics): What always executes in a finally block and what are its pitfalls?**

A: `finally` always executes: after `try`, after any `catch`, on exception or normal return.
Exceptions: `System.exit()` in the try block terminates the JVM (finally doesn't run). Thread
kill (not interrupt) terminates the thread (finally may not run). Pitfall 1: `return` in
`finally` swallows any exception thrown in the try/catch. Pitfall 2: `throw` in `finally` replaces
the original exception (losing it). Use `try-with-resources` instead of finally for resource cleanup.

*What separates good from great:* The `return` in `finally` pitfall:
```java
String value() {
    try {
        return computeValue();  // throws RuntimeException
    } finally {
        return "default";       // SWALLOWS the exception! Returns "default"
    }
}
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

The `return` in `finally` causes the RuntimeException to be silently swallowed. The method
returns "default" instead of propagating the exception. This is one of the most subtle Java bugs.
Rule: NEVER use `return` (or `throw`) in a `finally` block. Use `finally` only for cleanup that
doesn't change the result (logging, closing resources that don't throw).

---

**Q5 (custom exceptions): What should a domain exception hierarchy look like?**

A: (1) Base unchecked exception: `AppException extends RuntimeException` with an `errorCode` field. (2) Specific domain exceptions extend the base: `UserNotFoundException`, `OrderProcessingException`, `ValidationException`. (3) Each exception includes: message (human-readable), error code (machine-readable for API responses), and cause (for chaining). (4) Factory methods or builders for complex exception creation. Global handler maps exception types to HTTP responses.

*What separates good from great:* The error code pattern enables mapping exceptions to API responses without `instanceof` chains. In a Spring `@ControllerAdvice`: `switch (exception.getErrorCode()) { case "USER_NOT_FOUND" -> ResponseEntity.notFound(); case "VALIDATION_ERROR" -> ResponseEntity.badRequest(); }`. Or: error codes as enums for type safety. The domain exception hierarchy is also the boundary for exception translation: at the service layer, wrap infrastructure exceptions (Hibernate's `DataAccessException`, Jackson's `JsonProcessingException`) into domain exceptions with context. Callers see only domain exceptions.

---

**Q6 (interrupt): What is the contract around InterruptedException?**

A: `Thread.interrupt()`: sets the interrupt flag on the target thread. Methods that check this flag (`Thread.sleep()`, `Object.wait()`, `BlockingQueue.take()`): throw `InterruptedException` AND clear the interrupt flag. Contract: when you catch `InterruptedException`, you have consumed the interrupt. You MUST re-set it (`Thread.currentThread().interrupt()`) or propagate it, or ensure the thread terminates. Ignoring it: the interrupt is lost, the thread continues as if it was never interrupted.

*What separates good from great:* The interrupt design in Java: it's cooperative. The thread being interrupted can choose to ignore it (if it catches and swallows). The convention: well-behaved code MUST cooperate. JDK's BlockingQueue, ExecutorService (shutdown + awaitTermination), `Thread.join()` all use interrupts for cancellation. If your code running in a thread pool swallows interrupts: `ExecutorService.shutdownNow()` will silently fail (the thread doesn't stop). This causes shutdown hangs in production. Rule: if you're running in a thread pool or any managed thread context, always cooperate with interrupts.

---

**Q7 (exception in constructor): What happens when a constructor throws an exception?**

A: Object construction fails. The partially-constructed object is eligible for GC. No reference to the object is returned to the caller. If the constructor acquires resources before throwing: those resources must be released in the constructor's try block (no `finally` via try-with-resources for constructor resources in the caller's scope, since the object doesn't reach the caller). Anti-pattern: constructors that acquire external resources (sockets, file handles) should be wrapped in a factory method.

*What separates good from great:* The resource leak in constructor: `class Connection { private final Socket socket; Connection(String host, int port) { socket = new Socket(host, port); // opens socket doSomethingThatThrows(); // throws -> Connection not returned // socket is now open but not accessible (no reference to Connection) } }`. The `socket` reference is in the partially-constructed `Connection` object which is GC'd. The `Socket` won't be closed until finalization (non-deterministic). Fix: use a factory method that opens the socket and closes it on construction failure: `static Connection create(...) { Socket s = new Socket(...); try { return new Connection(s); } catch (Exception e) { s.close(); throw e; } }`.

---

**Q8 (multi-catch): What are the restrictions on multi-catch blocks?**

A: Multi-catch: `catch (IOException | SQLException e)`. The variable `e` is effectively final in a multi-catch block (cannot be reassigned). The exception types must not be in a subtype relationship: `catch (Exception | IOException e)` is a compile error (IOException is a subtype of Exception - the IOException case is already covered by Exception). Useful for: two unrelated checked exceptions requiring the same handling.

*What separates good from great:* The "effectively final" restriction in multi-catch: `catch (IOException | SQLException e) { e = new IOException(); }` is a compile error. This prevents confusion about which exception type `e` is. The type of `e` in a multi-catch: the common supertype (usually `Exception` or `Throwable`). But because `e` is effectively final, the compiler knows which subtypes it might be. The practical consequence: you cannot `throw e` as `IOException` or `SQLException` specifically; it's the common supertype. If you need to re-throw as a specific type: use separate catch blocks.

---

**Q9 (exceptions in streams): What is the best approach for exceptions in stream pipelines?**

A: Problem: `Stream.map(f)` requires `f` to be a `Function<T,R>` which doesn't declare checked exceptions. Options: (1) catch inside the lambda and wrap in unchecked: `item -> { try { return parse(item); } catch (ParseException e) { throw new RuntimeException(e); } }`. (2) `unchecked()` wrapper utility. (3) Collect to list first, then process with try-catch in a for loop. (4) Custom `ThrowingFunction` interface.

*What separates good from great:* Each option has trade-offs. Option 1 (inline try-catch): works but verbose, mixes parsing logic with error handling. Option 2 (wrapper utility): clean pipeline, but exceptions lose their original type (wrapped in RuntimeException). Option 3 (for loop after collect): explicit and debuggable, but loses stream processing benefits. Option 4 (custom interface): cleanest API, but requires defining new interfaces. Production recommendation: Option 2 for simple cases, Option 3 for complex logic needing debuggability. The functional style should not be forced when it complicates error handling - sometimes a for loop IS the right answer.

---

### ⚖️ Comparison Table

| Feature | Checked Exception | Unchecked Exception | Error |
|---------|-------------------|---------------------|-------|
| Extends | Exception (not RuntimeException) | RuntimeException | Error |
| Must declare/catch | Yes | No | No |
| Recoverable | Intended to be | Not typically | Almost never |
| Use for | External system failures | Programming errors | JVM failures |
| Lambda compatible | No (must wrap) | Yes | No |
| Modern usage | Integration boundaries | Application code | Don't use |
| Example | IOException, SQLException | NPE, IllegalArg | OOM, SOE |

---

### 🏛️ System Design

*(Omit: L3 file.)*

---

### 📊 Diagram

*(Omit: Exception hierarchy expressed in text and comparison table.)*

---

---

## Exception Anti-patterns and Best Practices

---

### 🎯 Model Answer

**30 seconds:**
> Top exception anti-patterns: swallowing exceptions (empty catch block), catching `Exception`/
> `Throwable` too broadly, using exceptions for flow control, losing the cause when wrapping,
> over-catching (catching what you can't handle), and throwing `Exception` in method signatures.
> Best practices: fail fast, specific exceptions, always chain causes, let unchecked propagate,
> use structured logging with exception context.

**3 minutes (Senior):**
> Anti-pattern deep dive:
>
> 1. **Empty catch (swallowing)**: `catch (Exception e) {}` - silently hides failures. The
>    hardest bugs to diagnose are the ones that don't appear. Rule: NEVER have an empty catch
>    block without a comment explaining why it's intentional.
>
> 2. **Exception for flow control**: `try { return Integer.parseInt(s); } catch (NumberFormatException e) { return -1; }` is acceptable. But `try { findUser(id); return "found"; } catch (UserNotFoundException e) { return "not found"; }` - using exception as a control flow mechanism when the not-found case is expected is a performance and design anti-pattern.
>
> 3. **Catching `Throwable`**: catches Errors (OOM, SOE). Only legitimate in: top-level thread
>    uncaughtExceptionHandler for logging. Not in application code.
>
> 4. **Re-throwing without cause**: new exception wrapping the original without passing `e` as
>    cause. The original stack trace is gone.
>
> 5. **Logging and re-throwing**: `log.error("Error", e); throw e;` - the same exception is logged
>    twice (once here, once by the caller). Either log or rethrow, not both.

**Blank Mind Recovery:**

**(1) Restate:** "Anti-patterns: empty catch, catching too broadly (Throwable), flow control via exceptions, losing cause, log-and-rethrow (double logging). Best practices: specific types, chain causes, let propagate, log ONCE (at handler boundary)."

**(2) First principles:** "Exceptions signal the unexpected. Anti-patterns corrupt this signal:
swallowing = signal lost. Too-broad catching = signal handled incorrectly. Flow control = signal
misused (not unexpected). Double logging = signal amplified unnecessarily."

**(3) Bridge:** "Exception anti-patterns are like bad emergency protocols. Empty catch: fire alarm
rings but nobody looks. Too-broad catch: fire alarm triggers for any sound (false positives).
Flow control: fire alarm used as a doorbell. Losing cause: the incident report says 'building
was on fire' but not what started it."

---

### 📘 Concept Explanation

**Exception anti-patterns and their corrections:**
```
ANTI-PATTERN 1: SWALLOWING EXCEPTIONS

  // BAD:
  try {
      config.load(configFile);
  } catch (IOException e) {
      // nothing!
  }
  // Result: system continues with default config, silently
  
  // If intentional (rare), document it:
  catch (IOException e) {
      // Intentional: config is optional, defaults are used if not found
      log.debug("Config file not found, using defaults: {}", e.getMessage());
  }

ANTI-PATTERN 2: EXCEPTION FOR FLOW CONTROL

  // BAD (performance): exceptions are expensive (stack capture)
  try {
      return Integer.parseInt(input);
  } catch (NumberFormatException e) {
      return -1;
  }
  // Alternative: validate first
  // GOOD:
  return input.matches("-?\\d+") ? Integer.parseInt(input) : -1;
  // Or (Java 8 with Optional):
  return Optional.of(input)
      .filter(s -> s.matches("-?\\d+"))
      .map(Integer::parseInt)
      .orElse(-1);

ANTI-PATTERN 3: LOG AND RETHROW (DOUBLE LOGGING)

  // BAD: logged here AND by the caller = duplicate log entries
  try {
      process(item);
  } catch (ProcessingException e) {
      log.error("Failed to process item", e);  // log #1
      throw e;  // caller also logs -> log #2
  }
  
  // GOOD: choose one
  // Option A: Log here, don't rethrow
  catch (ProcessingException e) {
      log.error("Failed to process item", e);
      // handle it here (return default, skip item, etc.)
  }
  // Option B: Rethrow, don't log (let the caller log or let it propagate to boundary)
  catch (ProcessingException e) {
      throw new AppException("Failed to process item " + item.getId(), e);
  }
  // RULE: log at the boundary (the outermost handler), not at every rethrow point

ANTI-PATTERN 4: CATCHING EXCEPTION OR THROWABLE

  // BAD: catches everything including NPE (your bugs!), OOM, etc.
  try {
      process();
  } catch (Throwable t) {  // too broad
      log.error("Something went wrong", t);
  }
  
  // BAD: catches too broadly
  try {
      riskyOperation();
  } catch (Exception e) {
      return null;  // hides NPE, IllegalStateException etc.
  }
  
  // GOOD: catch specifically what you can handle
  try {
      return parseData(input);
  } catch (ParseException e) {   // only what you declared
      return defaultValue();     // meaningful handling
  }

ANTI-PATTERN 5: USING EXCEPTION MESSAGE FOR PARSING

  // BAD: parsing exception messages is brittle
  try {
      db.save(entity);
  } catch (DataIntegrityViolationException e) {
      if (e.getMessage().contains("Unique constraint")) {
          throw new DuplicateEntityException(...);
      }
  }
  // Message format changes between DB versions -> breaks
  
  // GOOD: check exception type hierarchy or vendor-specific error codes
  catch (DataIntegrityViolationException e) {
      Throwable cause = e.getCause();
      if (cause instanceof ConstraintViolationException cv) {
          String constraint = cv.getConstraintName();
          if (constraint != null && constraint.contains("uk_email")) {
              throw new DuplicateEmailException(entity.getEmail(), e);
          }
      }
      throw e;  // rethrow if not handled
  }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The exception handler demonstrates the boundary pattern: only the outermost
> handler logs the full exception. All intermediate methods add context and rethrow. This produces
> exactly one log entry with the full chain of context from the point of failure to the boundary.

```java
// CORRECT EXCEPTION HANDLING BOUNDARY PATTERN:

// Deep in the stack: wrap with context, don't log
class FileParser {
    Record parse(Path file) {
        try {
            return doParseFile(file);
        } catch (IOException e) {
            // Add context (which file), chain cause, don't log
            throw new ParsingException("Failed to parse: " + file, e);
        }
    }
}

// Mid stack: add more context, rethrow
class BatchProcessor {
    void processBatch(List<Path> files) {
        for (int i = 0; i < files.size(); i++) {
            try {
                parser.parse(files.get(i));
            } catch (ParsingException e) {
                // Add batch position context, chain
                throw new BatchProcessingException(
                    "Failed at file " + i + " of " + files.size(), e);
            }
        }
    }
}

// Boundary: log everything, respond appropriately
class JobController {
    ResponseEntity<Void> runJob(JobRequest request) {
        try {
            batchProcessor.processBatch(request.getFiles());
            return ResponseEntity.ok().build();
        } catch (BatchProcessingException e) {
            // LOG HERE (and only here) - full stack trace with all context
            log.error("Job {} failed: {}", request.getJobId(), e.getMessage(), e);
            return ResponseEntity.status(500)
                .header("X-Error-Code", e.getErrorCode())
                .build();
        }
    }
}
// Result: one log entry with:
// "Job job-123 failed: Failed at file 47 of 1000"
// Caused by: ParsingException: Failed to parse: /data/files/record_47.csv
// Caused by: IOException: Premature end of file

// FAIL FAST PATTERN:
void processOrder(Order order) {
    // Validate preconditions at entry - don't wait for NPE deep in the code
    Objects.requireNonNull(order, "order must not be null");
    Objects.requireNonNull(order.getUserId(), "order.userId must not be null");
    if (order.getItems().isEmpty()) {
        throw new IllegalArgumentException("order must have at least one item");
    }
    // Now process - no defensive null checks needed inside
    double total = order.getItems().stream()
        .mapToDouble(Item::getPrice)
        .sum();
    // ...
}
```

> **Code walkthrough:** The three-layer boundary pattern shows a disciplined approach to exception
> propagation. `FileParser` wraps `IOException` with file context. `BatchProcessor` adds batch
> position. `JobController` is the boundary: it logs once with the full context chain. The result:
> a single log line with complete context from all layers. Without this pattern: each layer logs
> the same exception, producing 3+ duplicate log entries that are hard to correlate.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Never have empty catch blocks. Always include the cause when wrapping. Don't use exceptions
> for normal flow control. Catch specifically, not broadly. Log at the boundary only.

---

**Senior / Staff (5+ years):**
> Exception handling is an architectural concern. Define the exception boundary (the layer where
> exceptions become API responses or log entries). Use structured logging with the exception
> attached. Add context at each layer without logging. The domain exception hierarchy should map
> to API error codes. Validate preconditions fail-fast at method entry (Objects.requireNonNull,
> Guava Preconditions). Use `@Validated` and Bean Validation at API boundaries instead of manual
> null checks.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Checked exceptions force better error handling."**
In practice: checked exceptions are often handled with empty catch blocks (`catch (Exception e) {}`)
or logging and rethrowing (double-log anti-pattern). The forced handling doesn't guarantee GOOD
handling. Many experienced developers argue that unchecked + `@Nullable` + static analysis
(NullAway, errorprone) provide better safety with less noise. The forcing mechanic of checked
exceptions is orthogonal to the quality of error handling.

**Misconception 2: "Exceptions are expensive and should be avoided."**
Exception CREATION is expensive (stack trace capture). Exceptions THROWN and CAUGHT: moderately
expensive. For truly hot code paths (millions/second): avoid exceptions for expected conditions.
But for IO-bound code (network calls, DB queries): exception overhead is negligible compared to
IO latency. The anti-pattern: avoiding exceptions in application code for performance. The correct
rule: avoid exceptions for EXPECTED control flow in CPU-intensive code. Use them normally for
error conditions.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Stack trace lost because exception message was parsed instead of cause chain.**
```
Symptom: Log shows "Database error: constraint violation" but no detail about
  WHICH constraint, WHICH entity, WHAT values were involved.
  Debugging a data integrity issue takes hours because the log lacks context.

Root cause:
  // BAD: catch and log message only
  try {
      repository.save(entity);
  } catch (DataIntegrityViolationException e) {
      log.error("Database error: " + e.getMessage());
      throw new DomainException("Constraint violation");  // no cause, no context
  }
  
  Log output: "Database error: constraint violation"
  Missing: which constraint, what data, original SQL exception

Fix:
  try {
      repository.save(entity);
  } catch (DataIntegrityViolationException e) {
      // Extract meaningful context from the exception hierarchy:
      String constraintName = Optional.ofNullable(e.getCause())
          .filter(c -> c instanceof ConstraintViolationException)
          .map(c -> ((ConstraintViolationException) c).getConstraintName())
          .orElse("unknown");
      
      throw new DomainException(
          "Constraint violation on entity " + entity.getId() +
          " (constraint: " + constraintName + ")" +
          " with data: " + entity,
          e  // always chain the original
      );
  }
  
  Log output: "Constraint violation on entity 42 (constraint: uk_email) with data: User{...}"
  Caused by: DataIntegrityViolationException -> ConstraintViolationException -> SQL error

Checklist for useful exception messages:
  1. WHAT failed (operation name)
  2. WHAT INPUT caused it (entity ID, key, value)
  3. WHICH component (file name, table name, service name)
  4. ALWAYS chain the original exception as cause
  5. Do NOT parse exception messages (brittle, use the exception hierarchy)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Swallowing exceptions | 1 minute |
| Exception for flow control | 2 minutes |
| Log vs rethrow | 2 minutes |
| Fail-fast pattern | 1 minute |
| Exception message content | 2 minutes |
| Catching Throwable | 1 minute |
| Exception hierarchy design | 2 minutes |
| Precondition validation | 1 minute |
| Structured logging | 1 minute |

---

**Q1 (swallowing): What is the most dangerous exception anti-pattern and why?**

A: Swallowing: an empty catch block `catch (Exception e) {}`. The failure is silently hidden.
The system continues in an undefined state. The bug is invisible: no log, no error, no indication
something went wrong. Diagnosis is extremely difficult: the system "works" but produces wrong results
or degrades silently. The only safe reason for an empty catch: documented intentional opt-out
(e.g., `catch (IllegalArgumentException e) { /* validated by precondition - unreachable */ }`).

*What separates good from great:* The second-most-dangerous: `catch (Exception e) { return null; }`.
This is "swallowing with a null return." The exception is hidden, and the null propagates to the
caller who might not expect it (NPE elsewhere). CI enforcement: PMD rule `EmptyCatchBlock` and
SonarQube rule `java:S108` catch empty catch blocks. Code review: grep for `catch (` followed
by `}` on the next line. The discipline: every `catch` block must have EITHER a log statement or
a `throw` or a clearly justified empty (with comment). This is a code review checkbox item.

---

**Q2 (flow control): When is it acceptable to use exceptions for flow control?**

A: Rarely acceptable: when the "exceptional" path is truly rare (not the common case). `Integer.parseInt` with untrusted input: `NumberFormatException` thrown on invalid input. Since most inputs ARE valid, this is acceptable (exceptions are expensive, but rare). The anti-pattern: when the "exceptional" path IS common. `Optional.get()` that throws on empty: don't call `get()` without `isPresent()` check (use `orElse` instead). `Iterator.next()` past the end: always check `hasNext()` first. The rule: if you're catching an exception more than once per 100 calls, it's being used for flow control.

*What separates good from great:* JVM exception performance: creating an exception captures a stack trace (expensive, O(stack depth)). Throwing and catching: moderately expensive (compared to a simple if-check). In a tight loop processing 1 million items with 1% invalid: 10,000 exceptions created and caught per million = measurable overhead. Mitigation: `new Exception(message, cause, enableSuppression, writableStackTrace)` with `writableStackTrace=false` creates an exception without stack trace capture. Use for sentinel exceptions in performance-critical code where the exception is purely for control flow (not for diagnostics).

---

**Q3 (boundary): What is the correct exception handling boundary pattern?**

A: The boundary pattern: let exceptions propagate up the call stack (with added context at each
layer) until they reach a boundary handler. The boundary: logs the exception once (with full context
chain), converts to an API response or error message, and stops propagation. Below the boundary:
never log (add context and rethrow). This ensures each exception is logged once with full context.

*What separates good from great:* Structured logging at the boundary: `log.error("Request failed", "requestId", requestId, "userId", userId, "path", path, exception)`. Modern logging frameworks (SLF4J + Logback with JSON output): log structured key-value pairs. The exception is attached as the last argument (SLF4J convention: if the last argument is a `Throwable`, it's logged as the exception with full stack trace). In Kibana or Datadog: filter by `requestId` to see all events for one request, including the exception. This replaces log.error("RequestId: " + requestId + " failed") which is harder to query.

---

**Q4 (validate): What is the fail-fast principle and how does it apply to exception handling?**

A: Fail-fast: detect and report errors as early as possible. Validate preconditions at method entry.
`Objects.requireNonNull(arg, "arg must not be null")` - throws NullPointerException with a clear
message immediately. Without fail-fast: the null propagates through 5 method calls and throws a NPE
at `someMap.get(null).getValue()` with no indication of where the null originated.

*What separates good from great:* Java 7's `Objects.requireNonNull` vs Guava's `Preconditions.checkNotNull` vs manual `if (arg == null) throw new NullPointerException()`: identical semantics, different API styles. Guava also provides `checkArgument(condition, message)` and `checkState(condition, message)`. Spring's `Assert` class: `Assert.notNull(arg, "message")`. The choice: Guava for Guava projects, Objects.requireNonNull for standard Java, Spring Assert for Spring code. The key: use SOME form of fail-fast at public method entry points. The benefit: the stack trace points EXACTLY to the invalid call site, not deep in the implementation.

---

**Q5 (structured logging): What information should be included in exception messages?**

A: Good exception message formula: what failed + what input + where (if known) + why (from cause).
`"Failed to parse user profile for userId=" + userId + " from file " + filePath` - what (parse user profile), what input (userId, filePath), where (implicit from stack trace). The cause: always chained, provides the why. Bad messages: "Error occurred", "Failed", "Something went wrong" - no actionable information.

*What separates good from great:* Including entity IDs and key values in exception messages enables correlation in distributed systems. `"Order processing failed: orderId=ORD-12345, userId=42, amount=99.99"`. In a microservices environment: multiple services process the same order. When an exception occurs: the `orderId` in the exception message lets you grep all service logs for that ID. Without it: you search by timestamp across multiple service logs manually. The rule: any exception message at a service boundary should include the primary entity IDs involved in the operation. Don't include sensitive data (passwords, PII) in exception messages (they end up in logs).

---

**Q6 (null handling): When do you use Objects.requireNonNull vs @NonNull annotation vs Optional?**

A: `Objects.requireNonNull(arg, msg)`: immediate fail-fast at method entry. Use for public API
methods where null is not acceptable. `@NonNull` (or `@NotNull`): static analysis annotation.
Enforced by NullAway, IntelliJ, errorprone at compile time (no runtime cost). Use for documenting
non-null contracts throughout the codebase. `Optional`: for return types that represent possible
absence. Use as a return type from methods that might not return a value. Combine: annotate parameters
with `@NonNull`, validate with `requireNonNull` at public boundaries, return `Optional` when absence
is expected.

*What separates good from great:* The three tools work at different layers: `@NonNull` = static
analysis (catches errors before runtime). `requireNonNull` = runtime validation (catches errors
with clear messages). `Optional` = type-safe representation of optional values. Using all three
consistently: parameters annotated `@NonNull` are validated with `requireNonNull` at public API
boundaries. Method returns annotated `@Nullable` when null is possible, or return `Optional` when
absence should be explicit. NullAway (from Uber, used at Netflix): enforces `@NonNull`/`@Nullable`
annotations throughout the codebase as a compile-time null safety tool. More practical than full
null safety as in Kotlin but effective when consistently applied.

---

**Q7 (exception translation): What is exception translation and when is it needed?**

A: Exception translation: converting a low-level exception to a domain-level exception. `SQLException` (JDBC) -> `DataAccessException` (Spring) -> `OrderNotFoundException` (domain). Each layer translates to the language of its abstraction. Why: callers shouldn't need to know that a user lookup uses JDBC. They see `UserNotFoundException`, not `SQLException`.

*What separates good from great:* Spring's `@Repository` annotation: automatically translates Hibernate/JPA exceptions to `DataAccessException` hierarchy (via `PersistenceExceptionTranslator`). This is why Spring apps can use `@Repository` and catch `DataAccessException` without knowing the underlying ORM. Without this translation: switching from Hibernate to jOOQ would require changing all the exception types in callers. The pattern: each architectural layer translates exceptions to its own language. Repository: translates persistence exceptions. Service: translates infrastructure exceptions to domain exceptions. Controller: translates domain exceptions to HTTP responses. The translation is part of the layer's responsibility.

---

**Q8 (propagation): When should you catch and when should you let exceptions propagate?**

A: Let propagate when: (1) you can't meaningfully handle it at this level, (2) you're not adding
useful context, (3) you're not at the boundary where logging should happen. Catch when: (1) you can
recover and continue meaningfully, (2) you need to add context before rethrowing, (3) you're at
the boundary (log and convert to response). The common mistake: catching at multiple levels "just
in case" which causes double-logging and obscures the real exception flow.

*What separates good from great:* The "don't catch what you can't handle" principle: if your
catch block is `catch (Exception e) { throw new RuntimeException(e); }` without adding any context:
it's worse than not catching (adds a wrapping layer to the stack trace without adding information).
The only valid reason to re-wrap without adding context: changing the exception TYPE for API purposes (wrapping checked into unchecked at a layer boundary). Any re-wrap should add either: different exception type, context information, or both. If you're not adding value: don't catch.

---

**Q9 (production): What exception handling patterns are essential in a production Spring Boot app?**

A: (1) `@ControllerAdvice` with `@ExceptionHandler`: global boundary handler. Maps domain exceptions to HTTP responses. (2) Structured logging: MDC (Mapped Diagnostic Context) for request correlation. (3) Exception metrics: count exception types with Micrometer (`Counter.builder("exceptions.total").tag("type", e.getClass().getName())`). (4) Alerting: specific exception types trigger PagerDuty/OpsGenie. (5) `@Transactional` boundary: exceptions rolled back are domain-specific (typically RuntimeException subclasses).

*What separates good from great:* The MDC (Mapped Diagnostic Context) pattern: at the HTTP filter layer, set `MDC.put("requestId", requestId)` and `MDC.put("userId", userId)`. All log entries within that request automatically include these fields (Logback's `%X{requestId}` in the log pattern). When an exception is logged: it has the `requestId` and `userId` attached without needing to pass them to every method. The MDC pattern is essential for request correlation in production microservices. Combined with distributed tracing (Micrometer Tracing, Zipkin): the `traceId` is also in the MDC, enabling correlation across service boundaries.

---

### ⚖️ Comparison Table

| Anti-pattern | Risk Level | Symptom | Fix |
|-------------|------------|---------|-----|
| Empty catch block | Critical | Silent failures, wrong state | Log or rethrow |
| Exception for flow control | Medium | Performance degradation | Validate before, Optional |
| Log and rethrow | Medium | Duplicate log entries | Log at boundary only |
| Catching Throwable | High | OOM/SOE masked | Catch specifically |
| Losing cause | High | Undiagnosable errors | Always chain cause |
| ParseException message | Medium | Brittle, breaks on upgrade | Use exception type hierarchy |
| Exceptions in tight loops | Medium | GC pressure, latency | Validate first, avoid |
| Catching Exception broadly | Medium | Hides bugs | Catch specifically |

---

### 🏛️ System Design

*(Omit: L3 file.)*

---

### 📊 Diagram

*(Omit: Exception hierarchy and patterns expressed through code examples.)*

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



