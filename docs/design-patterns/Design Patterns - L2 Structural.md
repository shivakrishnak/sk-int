---
layout: default
title: "Design Patterns - L2 Structural"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 6
permalink: /design-patterns/l2-structural/
---

# Proxy Pattern

---
id: DP-015
title: Proxy Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: critical
asked_at: Mid+
seniority: mid-senior
tags: #design-patterns, #proxy, #structural, #aop, #lazy-loading
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Proxy provides a surrogate or placeholder for another object to
> control access to it. The proxy and the real object share the same
> interface. The proxy intercepts requests, adds behavior (security
> check, caching, lazy initialization, logging), and then optionally
> delegates to the real object. Spring AOP, JPA lazy loading, and
> dynamic proxies are all built on this pattern.

**3 minutes (Senior):**
> Proxy is structurally identical to Decorator - both wrap an object
> through the same interface. The intent differs: Decorator adds behavior
> to enrich functionality. Proxy controls access - it may add behavior
> but the primary concern is access control (who can call this, when,
> at what cost, with what caching).
>
> Four canonical Proxy types: (1) Virtual Proxy - delays expensive
> initialization until first use (JPA lazy loading). (2) Remote Proxy -
> represents an object in a different process/machine (RMI, gRPC stubs).
> (3) Protection Proxy - checks permissions before delegating (Spring
> Security method security). (4) Caching Proxy - returns cached result
> without delegating if data is fresh (Spring's `@Cacheable`).
>
> The Spring mechanism: `@Transactional`, `@Cacheable`, `@Async`,
> `@Secured` are all implemented via Spring AOP which creates a JDK
> dynamic proxy (interface-based) or CGLIB proxy (subclass-based) for
> each Spring bean. The proxy intercepts method calls and applies the
> cross-cutting concern. This is why `@Transactional` does not work on
> private methods or on `this.method()` calls - the proxy is bypassed.

**Blank Mind Recovery:**

**(1) Restate:** "Proxy - the pattern that controls access to an
object through a surrogate."

**(2) First principles:** "Problem: need to add cross-cutting behavior
(logging, security, caching) to objects without modifying them. Solution:
wrap the object in a proxy that implements the same interface and intercepts
calls."

**(3) Bridge:** "Like a receptionist in front of an executive: the
caller talks to the receptionist (proxy), who checks if the caller has
an appointment (access control), and then connects them to the executive
(real object) - or returns a cached answer from the last meeting."

---

### 📘 Concept Explanation

**What it is:**
Proxy provides a surrogate for another object to control access to it.
The proxy implements the same interface as the subject and intercepts
method calls, adding behavior (security, caching, lazy loading, logging)
before or after forwarding to the real subject.

**The problem it solves:**
Adding cross-cutting concerns (security, caching, logging, lazy initialization)
to an object without modifying the object's class. Direct modification
mixes concerns and requires changing the class for each new concern.

**How it works:**

```
Subject interface:
  + request(): Result

RealSubject implements Subject:
  + request(): does the actual work

Proxy implements Subject:
  - realSubject: RealSubject  (null for virtual proxy)
  + request():
      if (accessCheck fails) throw SecurityException
      if (cache has result) return cache.get()
      if (realSubject == null) realSubject = new RealSubject()
      result = realSubject.request()  // delegate
      cache.put(result)
      return result

// Dynamic proxy (Java):
Subject proxy = (Subject) Proxy.newProxyInstance(
    loader,
    new Class[]{Subject.class},
    (proxy, method, args) -> {
        // invocation handler: the proxy logic
        log.info("Before: {}", method.getName());
        Object result = method.invoke(realSubject, args);
        log.info("After: {}", method.getName());
        return result;
    });
```

**Four canonical Proxy types:**

1. **Virtual Proxy** - delays creation of expensive object until
   first use. JPA lazy-loaded associations: the `@OneToMany` collection
   is a proxy that loads from DB only when iterated.

2. **Remote Proxy** - represents an object in a remote location.
   gRPC stub, Feign client, RMI stub. The proxy marshals calls
   to the remote server.

3. **Protection Proxy** - controls access. Spring Security's method
   security: `@PreAuthorize("hasRole('ADMIN')")` is a protection proxy
   that checks permissions before delegating.

4. **Caching Proxy** - caches results. Spring's `@Cacheable` method:
   the proxy checks the cache before calling the real method.

**Dynamic vs Static Proxy:**
- **Static Proxy** - the proxy class is written manually or generated
  at compile time. More type-safe, more verbose.
- **Dynamic Proxy** - created at runtime using `java.lang.reflect.Proxy`
  (interface-based) or CGLIB (subclass-based). Spring AOP uses this.

**The key insight:**
The proxy is invisible to the caller - the caller uses the interface,
not knowing whether it is the real object or a proxy. This transparency
is what enables framework-level cross-cutting concerns (the Spring
container inserts proxies without application code knowing).

**When to use it:**
- Adding cross-cutting concerns without modifying the target class
- Lazy initialization of expensive resources
- Remote representation (network, IPC)
- Access control (permission checks before delegation)

**When NOT to use it:**
- When the concern should be in the business logic (use Decorator or
  direct modification instead)
- When proxying is not transparent: if callers need to know they have
  a proxy (use Decorator, which is explicit about wrapping)
- When all methods of an interface need the same interception:
  consider AOP at the framework level instead of a manual proxy

**Alternatives:**
- **Decorator** - adds functionality (same structure, different intent)
- **Spring AOP** - framework-level proxy creation via aspects
- **Interceptor / Filter** - HTTP-level proxy for web request concerns

---

### 💻 Code Example

```java
// BAD: No proxy - access control mixed into business logic
public class OrderRepository {
    public Order findById(Long id) {
        // Access control mixed with business logic
        String role = SecurityContext.getCurrentRole();
        if (!role.equals("ADMIN") &&
            !role.equals("USER")) {
            throw new AccessDeniedException("...");
        }
        // Actual business logic:
        return db.findById(id);
    }
}
// Problem: every method in OrderRepository has this check
// Can't test business logic without mocking SecurityContext
```

> **Code walkthrough:** Security concern is embedded in the repository.
> Every method must repeat the check. The repository has two reasons
> to change: business logic changes and security policy changes.
> Testing the DB logic requires setting up a security context.

```java
// GOOD: Protection Proxy separates concerns
// Real subject - pure business logic
public class OrderRepositoryImpl implements OrderRepository {
    public Order findById(Long id) {
        return db.findById(id); // pure business logic
    }
}

// Proxy - adds access control
public class SecuredOrderRepository implements OrderRepository {
    private final OrderRepository delegate;
    private final AuthorizationService auth;

    public Order findById(Long id) {
        auth.requireRole("USER", "ADMIN"); // protection
        return delegate.findById(id);      // delegate
    }
}

// PRODUCTION: Spring AOP (dynamic proxy) - zero hand-coding
@Repository
public class OrderRepository {
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public Order findById(Long id) {
        return db.findById(id);
    }
}
// Spring creates a CGLIB proxy at startup:
// the proxy intercepts findById, evaluates @PreAuthorize,
// throws AccessDeniedException if check fails,
// delegates to the real method if it passes.
// Zero changes to OrderRepository's code.
```

> **Code walkthrough:** The static Proxy (`SecuredOrderRepository`)
> separates security from business logic cleanly. The Spring AOP version
> goes further: no proxy class to write at all - the framework creates
> it at runtime from the `@PreAuthorize` annotation. The real repository
> method is pure business logic. Security policy is in the annotation.
> Testing the repository: use the class directly, bypassing the proxy.
> Testing the security: use the proxy in an integration test.

```java
// Virtual Proxy: JPA Lazy Loading
@Entity
public class Order {
    @Id Long id;

    // Lazy: a Hibernate proxy for the List, not loaded yet
    @OneToMany(fetch = FetchType.LAZY)
    private List<OrderItem> items;

    public List<OrderItem> getItems() {
        return items; // accessing this triggers DB load
    }
}

// N+1 problem: Proxy anti-pattern interaction
List<Order> orders = orderRepo.findAll();  // loads orders
for (Order order : orders) {
    // Each call triggers separate proxy load -> N+1 queries
    order.getItems().size();
}

// Fix: JOIN FETCH (loads in single query, no proxy load)
@Query("SELECT o FROM Order o "
     + "JOIN FETCH o.items WHERE o.status = 'PENDING'")
List<Order> findPendingWithItems();
```

> **Code walkthrough:** JPA's lazy loading is a Virtual Proxy:
> `items` is a Hibernate proxy object that loads from the database
> on first access. This delays the load until needed (good for
> performance when items are not always needed). The trap: the N+1
> problem occurs when iterating orders and accessing each order's
> items - each `getItems()` call fires a separate SQL query. Fix:
> `JOIN FETCH` loads the data in one query, bypassing the proxy.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Proxy is a wrapper that controls access to the real object. It looks
> like the real object to callers (same interface) but intercepts calls
> to add behavior: security checks, caching, logging. The most common
> form in Spring is the AOP proxy: annotations like `@Transactional`
> and `@Cacheable` cause Spring to create a proxy that adds transaction
> management or caching around method calls.

*Push deeper:* "The key limitation: Spring AOP proxies only intercept
calls coming from outside the bean. If a method calls another method
on `this` (internal call), the proxy is bypassed. This is why
`@Transactional` does not work on a method called from within the same
class."

---

**Senior / Staff (5+ years):**
> Proxy vs Decorator is the structural patterns interview trap - they
> look identical in code. Intent is the differentiator: Decorator adds
> functionality the caller wants (enriched output). Proxy controls access
> (the caller may not even know there is a proxy).
>
> The Spring AOP mechanism: JDK dynamic proxy requires the bean to have
> an interface; it creates a JDK `Proxy` that implements the interface.
> If the bean does not implement an interface (or `proxyTargetClass=true`
> is set), CGLIB creates a subclass proxy at runtime. This matters for:
> final classes (cannot be CGLIB-proxied), final methods (cannot be
> intercepted), and constructor injection (CGLIB subclass needs a
> no-arg constructor). These are real production bugs when teams
> do not understand the proxy mechanism.

*Push deeper:* "Spring AOP is limited to method-level interception.
For more complex interception (field access, constructor invocation),
AspectJ compile-time weaving is required. AspectJ is a real AOP
framework; Spring AOP is a proxy-based subset. The distinction matters
when someone says 'AOP bypassed on internal call' - that is a Spring
AOP limitation, not an AOP limitation."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What is the Proxy pattern? Name the four types."

🗣️ "Proxy provides a surrogate for another object to control access to it.
Both the proxy and the real object implement the same interface - callers
cannot distinguish them. Four canonical types: Virtual Proxy delays
expensive initialization (JPA lazy loading). Remote Proxy represents
an object in a different address space (gRPC stubs, Feign clients).
Protection Proxy controls access with permission checks (Spring Security
`@PreAuthorize`). Caching Proxy returns cached results to avoid redundant
computation (Spring `@Cacheable`). All four share the same structure;
the type is defined by the access control concern being addressed."

#### Mechanism
- "Why does @Transactional not work on a method called from within
  the same class?"

🗣️ "Spring AOP creates a proxy object in front of the Spring bean.
Method calls from external callers go through the proxy, which applies
the transaction advice. When a method inside the class calls another
method using `this.someMethod()`, the call goes directly to the bean
object, bypassing the proxy. The proxy never sees the call; the
transaction advice is never applied. Solutions: (1) Inject the bean
into itself (`@Autowired` self-reference) - the self-reference gets
the proxy, not `this`. (2) Use `AopContext.currentProxy()` to get
the proxy at runtime. (3) Refactor to extract the transactional method
to a separate bean. Best solution: (3) - the need for self-injection
is a code smell indicating a design issue."

#### Comparison
- "Compare Proxy vs Decorator - they look identical in code."

🗣️ "Same structure: both wrap an object through the same interface and
delegate to it. The difference is intent and transparency. Decorator:
the caller knows or accepts that the object is being decorated (enriched).
The decorator adds functionality the caller benefits from. Decorator
is explicit wrapping for enhanced behavior. Proxy: the caller usually
does not know there is a proxy (it is transparent). The proxy controls
access for the caller's benefit (cached result), or for the system's
benefit (security, auditing). The caller just wants the result; the
proxy handles access concerns. In Spring: `@Cacheable` is a Caching
Proxy (transparent to caller). A logging wrapper you write manually
is a Decorator."

#### Scenario
- "Design a caching proxy for an expensive external API call."

🗣️ "I define `WeatherService` interface with `getWeather(city)`.
`ExternalWeatherService implements WeatherService` calls the external API.
`CachingWeatherProxy implements WeatherService` holds a `WeatherService`
delegate and a `Map<String, CachedResult>`. In `getWeather(city)`:
check if cache has a fresh result for this city (within TTL). If yes:
return cached result. If no: delegate to `ExternalWeatherService`, cache
the result with a timestamp, return it. In production: use Spring's
`@Cacheable` instead of hand-rolling this. `@Cacheable` creates the
caching proxy automatically, supports configurable TTL, and can use
Redis as the cache store for distributed caching."

#### Debugging
- "@Cacheable is not caching results. How do you investigate?"

🗣️ "First check: is the method in a Spring-managed bean? `@Cacheable`
requires a Spring proxy. Second: is the method called from outside the
bean (external call) or internally? Internal `this.method()` calls bypass
the proxy. Third: is caching enabled? `@EnableCaching` must be on the
configuration class. Fourth: is the `@Cacheable` cache name configured?
Check `CacheManager` has a cache with the given name. Fifth: check the
key: if the cache key includes a mutable parameter that changes each
time, every call is a cache miss. Log the cache key by adding
`key = '#param.id'` explicitly. Sixth: check exception handling - if
the method throws, `@Cacheable` does not cache the result; the error
response is always re-queried."

#### Comparison Table

| Aspect | JDK Dynamic Proxy | CGLIB Proxy | AspectJ (full) |
|---|---|---|---|
| Requires | Interface | None (subclassing) | Agent/compile-time |
| Final class support | N/A (uses interface) | No | Yes |
| Final method interception | Via interface | No | Yes |
| Internal call interception | No | No | Yes |
| Performance | Fast | Fast (slightly slower) | Fast (compile-time) |
| Spring usage | Default (has interface) | `proxyTargetClass=true` | Rarely (explicit config) |

---

### ⚖️ Comparison Table

| Factor | Proxy | Decorator | Adapter | Facade |
|---|---|---|---|---|
| Intent | Control access | Add functionality | Translate interface | Simplify interface |
| Caller awareness | Transparent (often) | Aware (usually) | Does not know adaptee | Uses simplified API |
| Interface change | Same as real | Same as real | Different from adaptee | New, simpler API |
| Framework example | Spring AOP | Java I/O streams | Spring JdbcTemplate | Spring service layer |
| Key use case | Security, caching, lazy load | Enriched behavior | Legacy/3rd-party integration | Complex orchestration |

---

### 🔥 Field Q&A

**Q: Spring says "Bean not found" for a class annotated with
`@Transactional`. The class is `final`. Explain what is happening
and how to fix it.**

A: Spring AOP uses CGLIB subclass proxying when the target class does
not implement an interface (or when `proxyTargetClass=true` is set).
CGLIB works by creating a subclass of the target class at runtime.
A `final` class cannot be subclassed - the JVM prevents it. Spring
cannot create the CGLIB proxy, so the bean creation fails. Fix options:
(1) Make the class non-final. (2) Extract an interface and implement it
in the class; Spring will use JDK dynamic proxy instead of CGLIB.
(3) Use `@EnableTransactionManagement(proxyTargetClass=false)` to
force JDK proxy mode - but this requires an interface. The diagnostic:
Spring startup fails with `Unable to subclass final class` in the stack
trace.

**Q: When should you use a static (hand-written) Proxy vs Spring AOP
dynamic proxy?**

A: Static proxy when: the proxy logic is specific to this class (not
a general cross-cutting concern), the interface is small (few methods),
you want compile-time type safety and clear code for future maintainers.
Spring AOP dynamic proxy when: the concern is cross-cutting (applies
to many classes - logging, transactions, security), the concern is
declared via annotation (standard Spring idiom), and you want to apply
it consistently without boilerplate. Rule of thumb: if the proxy adds
behavior that a specific class needs (a circuit breaker around one
external service), static proxy or manual delegation is clearer. If
it is a concern that applies to N classes generically, Spring AOP.

---

# Composite Pattern

---
id: DP-016
title: Composite Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: medium
asked_at: Mid+
seniority: mid-senior
tags: #design-patterns, #composite, #structural, #tree-structure
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Composite composes objects into tree structures to represent part-whole
> hierarchies. Clients treat individual objects and compositions uniformly
> through the same interface. The classic example: a file system where
> both files and directories implement a `FileSystemNode` interface with
> `getSize()`. Getting the size of a directory recursively sums all
> children without the client knowing whether a node is a file or a
> directory.

**3 minutes (Senior):**
> Composite solves the part-whole problem: in a tree hierarchy, clients
> should not have to distinguish between a leaf node (simple object) and
> a composite node (container of objects). Without Composite, client code
> is full of `instanceof` checks: `if node is a Directory, iterate children;
> if node is a File, return size.` With Composite, both implement the same
> `Component` interface; the leaf returns its value, the composite delegates
> to children. Client code: `node.getSize()` - no `instanceof`.
>
> Production examples: file system hierarchies, expression trees (SQL
> query ASTs, mathematical expressions), organization hierarchies
> (departments containing sub-departments and employees), UI component
> trees (panels containing buttons and labels), HTML DOM tree, Spring's
> `CompositePropertySource`.
>
> The implementation choice: where to put child management methods
> (`add()`, `remove()`, `getChildren()`). Option 1: in the Component
> interface (maximum uniformity but leaves must implement operations
> that make no sense for them). Option 2: in the Composite class only
> (type-safe but clients must cast to add children). Modern Java uses
> Option 2 with the `sealed`/`instanceof` pattern matching.

**Blank Mind Recovery:**

**(1) Restate:** "Composite - the pattern where individual objects and
groups of objects are treated uniformly."

**(2) First principles:** "Problem: a tree structure where nodes are
either leaves (do the work) or composites (contain children). Client
should not care which. Solution: both leaf and composite implement the
same interface; composite delegates to children."

**(3) Bridge:** "Like a company org chart: you can ask 'what is the
total headcount?' to a department (composite) or an employee (leaf).
The department sums its sub-departments and employees; the employee
returns 1. You do not need to know which type you are asking."

---

### 📘 Concept Explanation

**What it is:**
Composite lets you compose objects into tree structures. A `Component`
interface is implemented by both `Leaf` (no children) and `Composite`
(contains children). Clients use the `Component` interface uniformly.

**The problem it solves:**
Tree structures where the same operation must be applied recursively
to both leaf nodes and container nodes. Without Composite, every tree
traversal requires type-checking and branching.

**How it works:**

```
Component interface:
  + operation(): Result

Leaf implements Component:
  + operation(): return my own value

Composite implements Component:
  - children: List<Component>
  + add(component: Component)
  + remove(component: Component)
  + operation():
      result = identity
      for each child:
          result = combine(result, child.operation())
      return result

// Tree:
root = new Composite()
  dir1 = new Composite()
    file1 = new Leaf("file1", 100)
    file2 = new Leaf("file2", 200)
  dir1.add(file1); dir1.add(file2)
  dir2 = new Composite()
    file3 = new Leaf("file3", 300)
  dir2.add(file3)
root.add(dir1); root.add(dir2)

root.operation()  // 600 (100+200+300)
// dir1.operation() returns 300
// dir2.operation() returns 300
// root combines: 300 + 300 = 600
```

**The key insight:**
The recursive delegation to `child.operation()` in the Composite class
is what makes the pattern work. The client calls the root's operation;
the tree self-evaluates recursively. The client never has a loop with
`instanceof` checks.

**When to use it:**
- When you need to represent part-whole hierarchies of objects
- When you want clients to be able to ignore the difference between
  individual objects and compositions (treat them uniformly)
- When the structure is tree-shaped and recursive operations are needed

**When NOT to use it:**
- When the tree is never more than one level deep - a simple list
  suffices
- When nodes at the same level are too different to share an interface
  meaningfully
- When the composite constraint (all children implement the same
  interface) does not hold in practice

---

### 💻 Code Example

```java
// BAD: Type checking in tree traversal
public long calculateSize(Object node) {
    // Must add instanceof check for every new node type
    if (node instanceof File) {
        return ((File) node).getSizeBytes();
    } else if (node instanceof Directory) {
        long total = 0;
        for (Object child : ((Directory) node).children) {
            total += calculateSize(child);  // recursive but fragile
        }
        return total;
    }
    throw new IllegalArgumentException("Unknown node type");
}
```

> **Code walkthrough:** Every new node type requires modifying this
> method. The `instanceof` chain is the signal that Composite is the
> right pattern. The traversal logic is outside the objects themselves.

```java
// GOOD: Composite pattern
public interface FileSystemNode {
    String getName();
    long getSize();
    void print(String indent);
}

public class File implements FileSystemNode {
    private final String name;
    private final long sizeBytes;

    public File(String name, long sizeBytes) {
        this.name = name;
        this.sizeBytes = sizeBytes;
    }

    public String getName() { return name; }
    public long getSize() { return sizeBytes; }
    public void print(String indent) {
        System.out.println(indent + name
            + " (" + sizeBytes + " bytes)");
    }
}

public class Directory implements FileSystemNode {
    private final String name;
    private final List<FileSystemNode> children =
        new ArrayList<>();

    public Directory(String name) { this.name = name; }

    public void add(FileSystemNode node) {
        children.add(node);
    }

    public String getName() { return name; }

    // Composite delegates to children - no instanceof
    public long getSize() {
        return children.stream()
            .mapToLong(FileSystemNode::getSize)
            .sum();
    }

    public void print(String indent) {
        System.out.println(indent + "[" + name + "]");
        children.forEach(
            c -> c.print(indent + "  "));
    }
}

// Build tree
Directory root = new Directory("root");
Directory src = new Directory("src");
src.add(new File("Main.java", 2048));
src.add(new File("Config.java", 1024));
Directory test = new Directory("test");
test.add(new File("MainTest.java", 512));
root.add(src);
root.add(test);

System.out.println("Total size: " + root.getSize()); // 3584
root.print(""); // prints tree structure
// Client calls root.getSize() - does not know the tree structure
```

> **Code walkthrough:** `root.getSize()` calls `src.getSize()` and
> `test.getSize()`. `src.getSize()` sums its children (2048 + 1024 = 3072).
> `test.getSize()` returns 512. The recursion happens inside `Directory.getSize()`
> via the `FileSystemNode::getSize` method reference - no `instanceof` anywhere.
> Adding a new node type (SymbolicLink): implement `FileSystemNode`, add to
> the tree. `Directory.getSize()` works unchanged - it calls `getSize()` on
> the interface.

```java
// PRODUCTION: Expression tree for discount calculation
public interface DiscountRule {
    boolean applies(Order order);
    double discount(Order order);
}

// Leaf: single condition
public class PremiumUserRule implements DiscountRule {
    public boolean applies(Order o) {
        return o.getUser().isPremium();
    }
    public double discount(Order o) { return 0.20; }
}

// Composite: AND/OR of rules
public class CompositeDiscountRule implements DiscountRule {
    private final List<DiscountRule> rules;
    private final Operator op; // AND or OR

    public boolean applies(Order order) {
        return op == AND
            ? rules.stream().allMatch(r -> r.applies(order))
            : rules.stream().anyMatch(r -> r.applies(order));
    }

    public double discount(Order order) {
        return rules.stream()
            .filter(r -> r.applies(order))
            .mapToDouble(r -> r.discount(order))
            .max().orElse(0.0);
    }
}
// Complex discount rules built as trees at runtime
```

> **Code walkthrough:** Discount rules form a Composite tree: a
> `CompositeDiscountRule` with AND combines `PremiumUserRule` and
> `LargeOrderRule`. The tree can be as deep as needed. Rules can be
> loaded from configuration and assembled at startup. The `discount()`
> method is recursive through the tree - no `instanceof` checks, no
> hardcoded rule combinations.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Composite lets you treat individual objects and groups of objects
> through the same interface. Both leaf nodes and composite nodes
> implement the same `Component` interface. Composites delegate to
> their children; leaves return their own values. The tree evaluates
> recursively. The classic example is a file system: files and directories
> both have a `getSize()` method; directories sum their children's sizes,
> files return their own size.

*Push deeper:* "The key benefit is eliminating `instanceof` checks in
tree traversal. Without Composite, every traversal must check if a
node is a leaf or composite. With Composite, just call `node.getSize()` -
the type handles itself."

---

**Senior / Staff (5+ years):**
> Composite is a good fit for business rule trees, expression evaluators,
> and any domain with recursive containment. I have used it for discount
> rule systems (rules composed with AND/OR), authorization policies
> (composite policies that combine multiple checks), and report component
> trees.
>
> The design decision: whether to put child management in the `Component`
> interface (transparency - clients can use the interface for everything)
> vs in the `Composite` class only (safety - clients do not accidentally
> call `add()` on a leaf). Modern Java: sealed interfaces let you express
> this cleanly. `sealed interface Node permits Leaf, Branch`. You use
> pattern matching (`instanceof Leaf l`) where needed and `node.operation()`
> uniformly elsewhere. This is more idiomatic than the original GoF design
> for modern Java.

*Push deeper:* "The Composite pattern requires a recursive structure that
can go deep. For very large trees (millions of nodes), memory layout
matters. A flat array representation with parent/child index relationships
can be 10x more memory-efficient than object-per-node trees. This is
how game engines (entity-component systems) and some rule engines store
their hierarchies."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What is the Composite pattern? What does 'uniform treatment' mean?"

🗣️ "Composite composes objects into tree structures to represent part-whole
hierarchies. Both leaf nodes (individual objects) and composite nodes
(containers of objects) implement the same `Component` interface. Uniform
treatment means: client code calls `component.operation()` without needing
to know if it is a leaf or a composite. The composite recursively delegates
to its children; the leaf returns its own value. This eliminates `instanceof`
branching in tree traversal code."

#### Mechanism
- "How does the recursive delegation work in Composite?"
- "Where does the tree evaluation terminate?"

🗣️ "Recursive delegation: when `composite.operation()` is called, it
iterates its `children` list and calls `child.operation()` on each.
Each child is a `Component` - it may be a leaf or another composite.
If a composite, the recursion continues. If a leaf, `leaf.operation()`
returns its own value without further delegation. The base case (recursion
termination) is the leaf node: it has no children and returns directly.
The tree evaluates bottom-up: leaves evaluate first, their parents
aggregate, up to the root. The caller receives the final aggregated value."

#### Comparison
- "Compare Composite vs Decorator."

🗣️ "Both are Structural patterns that involve object wrapping, but for
different purposes. Decorator: linear wrapping - object A wraps object B;
both implement the same interface but A adds behavior around B. Single
chain, one root per wrapper. Composite: tree structure - a composite node
has multiple children; both composite and leaf implement the same interface.
The composite aggregates its children's results. Composite is used for
representing hierarchies and recursive part-whole relationships. Decorator
is used for adding behaviors to a single object."

#### Scenario
- "Design a permission system where permissions can be grouped."

🗣️ "Define `Permission` interface with `boolean isGranted(User user, Action action)`.
`SimplePermission` (leaf): checks one specific action (`READ_ORDERS`).
`PermissionGroup` (composite): holds a list of `Permission` with AND/OR
semantics. `isGranted()` in the group: `rules.stream().allMatch(p -> p.isGranted(user, action))` for AND group.
Permissions are assembled as trees: `ADMIN_ROLE = PermissionGroup(AND, [READ_ORDERS, WRITE_ORDERS, DELETE_ORDERS])`.
`isGranted(user, action)` traverses the tree. The authorization check
calls `permission.isGranted()` on the root - the tree evaluates. Adding
a new composite permission type (XOR, threshold): create a new
`PermissionGroup` subtype, zero changes to existing code."

#### Debugging
- "A Composite is not including a node's contribution in the total.
  How do you debug?"

🗣️ "Three most common causes: (1) The node was not added to the parent.
Trace the tree construction: add logging in `add()` to verify every
node is registered. Print the tree structure after construction.
(2) The node's `operation()` returns zero or identity for specific
inputs. Add logging in the leaf's `operation()` method.
(3) A conditional in the composite skips certain children. Check if
the composite has any filtering logic that might skip the node.
Debugging tool: add a `print(indent)` method (as in the file system
example) that prints the entire tree with each node's computed value.
Visually comparing the expected tree to the actual output identifies
the missing node."

#### Comparison Table

| Aspect | Composite | Decorator | Iterator |
|---|---|---|---|
| Structure | Tree (one-to-many) | Chain (one wraps one) | Any collection |
| Purpose | Part-whole hierarchy | Add behavior | Traversal |
| Client knowledge | Interface only | Interface only | Interface only |
| Direction | Bottom-up aggregation | Wrapping chain | Sequential access |
| Example | File system, org chart | Java I/O streams | Java collections |

---

### ⚖️ Comparison Table

| Factor | Composite | Decorator | Proxy | Facade |
|---|---|---|---|---|
| Structure | Tree (1 to many) | Chain (1 to 1) | Wrapper (1 to 1) | Wrapper (1 to many subsystems) |
| Primary purpose | Part-whole aggregation | Behavior enrichment | Access control | Complexity reduction |
| Recursion | Yes (tree traversal) | Possible (stacked) | No | No |
| Client visibility | Sees Component | Sees Component | Sees Subject | Sees simplified API |
| Production example | File system, rules tree | Java I/O | Spring AOP | Service layer |

---

### 🔥 Field Q&A

**Q: You are building a reporting engine where reports can contain
sub-reports, which can contain charts and tables. How do you apply
Composite?**

A: Define `ReportComponent` interface with `render()`, `getEstimatedRows()`,
and `validate()`. Leaf types: `ChartComponent` and `TableComponent` implement
rendering for their specific visualization. Composite type: `ReportSection`
holds a list of `ReportComponent` children. `render()` on a section iterates
children and renders each. `getEstimatedRows()` sums children's estimated
rows. `validate()` returns all validation errors from children. The root
`Report` is a `ReportSection`. The report engine calls `report.render()` -
it does not know the structure. Reports can be nested arbitrarily:
a dashboard is a report containing four section reports, each containing
charts and tables. Adding a new component type (`PivotTable`): implement
`ReportComponent`, slot it into any section.

**Q: How does Composite interact with the Visitor pattern?**

A: Composite defines the tree structure; Visitor defines operations on
the tree without modifying the tree node classes. Instead of adding a
new method to every `Component` implementor for every new operation,
a `Visitor` accepts a `Component` and performs the operation. The
`Component` interface has `accept(Visitor v)`. Leaves call
`v.visitLeaf(this)`. Composites call `v.visitComposite(this)` and then
`child.accept(v)` for each child. New operations: add a new `Visitor`
class. No changes to the tree node classes. The combination is powerful:
Composite for tree structure, Visitor for extensible operations on the
tree. Expression trees in compilers use exactly this: AST is Composite,
type checking/code generation are Visitors.
