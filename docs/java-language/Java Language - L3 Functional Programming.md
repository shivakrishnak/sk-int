---
layout: default
title: "Java Language - L3 Functional Programming"
parent: "Java Language"
grand_parent: "SK Interview"
nav_order: 9
permalink: /java-language/l3-functional-programming/
---

# Java Language - L3 Functional Programming

## Functional Interfaces and Composition

### 🎯 Model Answer

**30 seconds:**
> Functional interfaces: `@FunctionalInterface` with exactly one abstract method. Built-in:
> `Predicate`, `Function`, `Consumer`, `Supplier`, `BiFunction`, `UnaryOperator`, `BinaryOperator`.
> Composition: `Predicate.and()/.or()/.negate()`, `Function.andThen()/.compose()`. Method references:
> 4 kinds (static, instance specific, instance arbitrary, constructor). Enables strategy pattern,
> pipeline composition, and dependency injection via lambda.

**3 minutes (Senior):**
> Advanced functional interface design:
>
> 1. **Composing complex behavior**: `Function<A,B>.andThen(Function<B,C>)` = `Function<A,C>`.
>    Build processing pipelines from named, testable pieces. `Predicate.and()/or()/negate()`:
>    build filter logic from reusable named predicates.
>
> 2. **Higher-order functions**: methods that accept and/or return functions. `<T> Predicate<T> not(Predicate<T> p)` returns the negated predicate. `memoize(Function<K,V>)` returns a caching function.
>
> 3. **Partial application**: `Function<A, Function<B, C>>` = curried function. Apply one argument
>    now, get a function waiting for the second. Java doesn't have built-in currying but it's easy
>    to simulate.
>
> 4. **Combinator pattern**: building complex validation, transformation, or routing logic from
>    small named pieces that can be composed, tested independently, and reused.
>
> 5. **Custom functional interfaces**: needed when built-in don't match (checked exceptions,
>    3+ parameters, void return with checked exception).

**Blank Mind Recovery:**

**(1) Restate:** "Functional interface = SAM interface. Built-ins: Predicate, Function, Consumer, Supplier, BiFunction. Compose with: .and(), .or(), .andThen(). Higher-order: methods that take/return functions. Custom: when built-ins don't fit (checked exceptions, arity mismatch)."

**(2) First principles:** "Functional interfaces: the bridge between Java OOP and functional
programming. They make functions first-class: you can pass them as arguments, return them, and
compose them. Each composition creates a new function without changing the originals (immutable
function values)."

**(3) Bridge:** "Functional interfaces are like electrical connectors. `Function<A, B>` is a cable
with A-in, B-out. `andThen(Function<B, C>)`: plug two cables together, get A-in, C-out. `Predicate.and(other)`: a Y-splitter that sends the signal to both cables and only passes through if both pass. The pipeline is built by snapping pieces together."

---

### 📘 Concept Explanation

**Functional interface composition mechanics:**
```
COMPOSITION OPERATORS:

  Function<T, R>:
    andThen(Function<R, V>)  -> Function<T, V>  // T->R then R->V = T->V
    compose(Function<V, T>)  -> Function<V, R>  // apply V->T first, then T->R
    identity()               -> Function<T, T>   // static, returns x -> x
  
  // andThen vs compose:
  Function<String, String> trim  = String::trim;
  Function<String, String> upper = String::toUpperCase;
  
  // f.andThen(g) = g(f(x)) = first trim, then upper
  Function<String, String> normalize = trim.andThen(upper);
  
  // f.compose(g) = f(g(x)) = first upper, then trim
  // (applies g first, then f)
  Function<String, String> other = trim.compose(upper);

  Predicate<T>:
    and(Predicate<T>)   -> Predicate<T>  // both must be true
    or(Predicate<T>)    -> Predicate<T>  // at least one must be true
    negate()            -> Predicate<T>  // logical NOT
    not(Predicate<T>)   -> Predicate<T>  // static factory (Java 11+)
    isEqual(Object)     -> Predicate<T>  // static: tests equals to object
  
  Consumer<T>:
    andThen(Consumer<T>) -> Consumer<T>  // execute both in sequence

HIGHER-ORDER FUNCTIONS:

  // A function that returns a function (partial application):
  Function<String, Predicate<String>> startsWith =
      prefix -> s -> s.startsWith(prefix);
  
  Predicate<String> startsWithHttp = startsWith.apply("http");
  Predicate<String> startsWithFtp  = startsWith.apply("ftp");
  
  // Curried function (manual, Java doesn't support built-in currying):
  Function<Integer, Function<Integer, Integer>> add =
      a -> b -> a + b;
  Function<Integer, Integer> addFive = add.apply(5);  // partial application
  addFive.apply(3);  // = 8

MEMOIZATION (caching function results):
  static <K, V> Function<K, V> memoize(Function<K, V> fn) {
      Map<K, V> cache = new ConcurrentHashMap<>();
      return key -> cache.computeIfAbsent(key, fn);  // atomic, one compute per key
  }
  
  Function<Long, UserProfile> lookupProfile =
      memoize(userId -> profileService.load(userId));  // DB hit only once per userId

VALIDATION COMBINATOR PATTERN:
  @FunctionalInterface
  interface Validator<T> {
      Optional<String> validate(T value);
      
      default Validator<T> and(Validator<T> other) {
          return value -> {
              Optional<String> result = this.validate(value);
              return result.isPresent() ? result : other.validate(value);
          };
      }
  }
  
  // Compose validators:
  Validator<String> notEmpty = s ->
      s == null || s.isEmpty() ? Optional.of("must not be empty") : Optional.empty();
  Validator<String> maxLength = s ->
      s != null && s.length() > 100 ? Optional.of("too long") : Optional.empty();
  
  Validator<String> nameValidator = notEmpty.and(maxLength);
  nameValidator.validate("Alice");  // Optional.empty (valid)
  nameValidator.validate("");       // Optional.of("must not be empty")
```

---

### 💻 Code Example

> **Code walkthrough:** The pipeline builder demonstrates how to compose named transformation
> steps into a reusable processing pipeline. Each step is independently testable, the pipeline
> is lazily applied (Function composition creates descriptions, not results), and new steps can
> be added without modifying existing code.

```java
// PIPELINE COMPOSITION:
Function<String, String> normalize = 
    ((Function<String, String>) String::trim)
    .andThen(String::toLowerCase)
    .andThen(s -> s.replaceAll("\\s+", " "));

// Test each step independently:
// trim.apply("  Hello  ") = "Hello"
// toLowerCase.apply("Hello") = "hello"
// spaces.apply("hello  world") = "hello world"
// Combined: "  Hello   World  " -> "hello world"

// PREDICATE COMPOSITION:
Predicate<String> isEmail = s -> s.contains("@") && s.contains(".");
Predicate<String> isNotEmpty = Predicate.not(String::isEmpty);
Predicate<String> isModeratLength = s -> s.length() >= 5 && s.length() <= 255;

Predicate<String> isValidEmail = isNotEmpty.and(isModeratLength).and(isEmail);

List<String> candidates = List.of("", "a@b.c", "valid@email.com", "notanemail");
List<String> validEmails = candidates.stream()
    .filter(isValidEmail)
    .collect(Collectors.toList());

// STRATEGY PATTERN VIA FUNCTIONAL INTERFACE:
interface PricingStrategy {
    double apply(double basePrice, int quantity);
}
// BAD: separate class per strategy
class VolumeDiscountStrategy implements PricingStrategy { ... }

// GOOD: lambdas as strategies
PricingStrategy noDiscount = (price, qty) -> price * qty;
PricingStrategy volumeDiscount = (price, qty) -> {
    double discount = qty >= 100 ? 0.1 : qty >= 50 ? 0.05 : 0;
    return price * qty * (1 - discount);
};
PricingStrategy bulkFlat = (price, qty) -> qty > 500 ? price * qty * 0.85 : price * qty;

// Switch strategy at runtime:
PricingStrategy strategy = customer.isWholesaler() ? volumeDiscount : noDiscount;
double total = strategy.apply(29.99, orderQuantity);

// RETRY WITH FUNCTION:
static <T> T withRetry(
    Supplier<T> operation,
    int maxAttempts,
    long delayMs
) {
    for (int i = 0; i < maxAttempts; i++) {
        try {
            return operation.get();
        } catch (RuntimeException e) {
            if (i == maxAttempts - 1) throw e;
            try { Thread.sleep(delayMs); } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                throw new RuntimeException(ie);
            }
        }
    }
    throw new IllegalStateException("Unreachable");
}

// Usage:
User user = withRetry(() -> remoteService.getUser(id), 3, 500);
```

> **Code walkthrough:** The `isValidEmail` predicate chain demonstrates named predicates composed
> at runtime. Each predicate (`isNotEmpty`, `isModeratLength`, `isEmail`) is independently readable
> and testable. The composed `isValidEmail` expresses the business rule clearly. The `withRetry`
> function shows a higher-order function that accepts a `Supplier<T>` and returns T: the caller
> provides behavior (the operation), the utility provides the retry mechanism. This separation of
> what to do from how to retry it is the core benefit of higher-order functions.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Functional interfaces: SAM. Built-ins cover most cases. Compose predicates with `.and()`, `.or()`.
> Compose functions with `.andThen()`. Strategy pattern: use lambda instead of anonymous class.
> Method references: cleaner than lambdas when just delegating.

---

**Senior / Staff (5+ years):**
> Combinator pattern: build domain-specific languages from composed functional interfaces.
> Validation combinators, pricing strategy chains, transformation pipelines. Memoize expensive
> Function calls with `ConcurrentHashMap.computeIfAbsent`. Higher-order functions (accept/return
> functions) enable dependency injection and behavior parameterization. The functional model:
> immutable function values that compose purely.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`andThen` and `compose` do the same thing in different order."**
Yes, but the order confusion is real. `f.andThen(g)` = `g(f(x))` = f first. `f.compose(g)` = `f(g(x))` = g first. Mnemonic: `andThen` = "do f, THEN do g". `compose` = "g is applied before f is COMPOSED on top". In practice: `andThen` is more natural for pipeline reading (left-to-right). `compose` is used less often. Stick to `andThen` for readability unless there's a specific reason.

**Misconception 2: "Functional interfaces can only be lambdas."**
No. A functional interface can be implemented by: lambda, method reference, anonymous class, or regular class. `Predicate<String> p = new Predicate<String>() { public boolean test(String s) { return s.isEmpty(); } }` - an anonymous class implementing `Predicate`. The `@FunctionalInterface` annotation says "one abstract method" - it doesn't require lambda usage. But lambdas and method references are the idiomatic modern form.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Memoized function causes memory leak in production.**
```
Symptom: Memory usage grows continuously. OldGen heap usage climbs.
  JVM eventually fails with OutOfMemoryError.

Root cause:
  Function<Long, UserProfile> cachedProfile = memoize(userId -> load(userId));
  // The memoize cache is a ConcurrentHashMap with no eviction.
  // In production: userId is unique per user session -> cache grows unbounded.
  // After 1M unique users: 1M UserProfile objects in memory, never evicted.

Diagnosis:
  Heap dump: large CHM with Long keys and UserProfile values
  VisualVM: Old generation grows continuously, no GC recovery
  jcmd <pid> GC.heap_dump heap.hprof; analyze with Eclipse MAT
  MAT: "Problem Suspects" -> large cache object

Fix:
  Replace unbounded memoize with a proper cache (Caffeine):
  
  LoadingCache<Long, UserProfile> profileCache = Caffeine.newBuilder()
      .maximumSize(10_000)           // bound the size
      .expireAfterWrite(5, MINUTES)  // TTL eviction
      .build(userId -> profileService.load(userId));
  
  UserProfile p = profileCache.get(userId);  // loads if absent, returns cached if present

Prevention:
  NEVER use ConcurrentHashMap as an unbounded cache.
  For memoization in production:
    - Use a bounded cache (Caffeine, Guava Cache)
    - Size bound: choose based on working set size + available memory
    - TTL eviction: data freshness
    - Metrics: cache hit rate (Caffeine + Micrometer)
  
  Simple lambda memoize is correct only for:
    - Known-finite key space (e.g., enum-keyed operations)
    - Functions called with the same key repeatedly in a bounded session
    - Non-production / unit test scenarios
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Functional interface design | 2 minutes |
| andThen vs compose | 1 minute |
| Higher-order functions | 2 minutes |
| Combinator pattern | 2 minutes |
| Memoization | 2 minutes |
| Custom functional interface | 1 minute |
| Predicate composition | 1 minute |
| Strategy pattern via lambda | 2 minutes |
| Currying vs partial application | 1 minute |

---

**Q1 (functional interface design): How do you design a custom functional interface?**

A: When to create: (1) built-in function interfaces don't fit (checked exceptions, arity > 2,
specific semantics), (2) the interface should be self-documenting (named for domain concept,
not just "Function"). Annotate with `@FunctionalInterface`. Add default methods for composition
if useful. Name it for the domain operation: `Validator<T>`, `PricingStrategy`, `Transformer<A,B>`.

*What separates good from great:* The naming principle: `Function<String, Integer>` is technical.
`Parser<Integer>` (a named functional interface) is domain-specific. Both are SAM interfaces, both
can be used as lambdas. The difference: the name communicates intent. When reading `parse(Parser<T>
p)`, you understand the contract. When reading `parse(Function<String, T> p)`, it's less clear
what the function represents. Use named functional interfaces for API boundaries and domain operations.
Use built-in interfaces (`Function`, `Predicate`, etc.) for utility and internal code where the
generic name is clear from context.

---

**Q2 (composition): What is the combinator pattern and how do you implement it?**

A: Combinator pattern: a domain-specific type that supports composition via chainable methods.
`Validator<T>` with `and(Validator<T>)` returning `Validator<T>`. `Router` with `or(Route)` for
fallback routing. `PricingModifier` with `andThen(PricingModifier)`. The pattern: the interface
defines the operation AND composition methods as default methods. Callers compose from named pieces.

*What separates good from great:* The combinator pattern is the functional equivalent of
the Composite design pattern. In Composite: objects contain lists of children that are the same type.
In Combinator: functions take and return the same function type. Both allow building complex behavior
from simple pieces. The functional combinator advantage: lambdas as leaf nodes (no boilerplate class).
The Composite advantage: better with stateful nodes. Production example: Spring Security's
`HttpSecurity` configuration is a combinator: `http.authorizeRequests(auth -> auth.anyRequest().authenticated()).oauth2Login().and().csrf().disable()`. Each method returns the same builder/combinator,
enabling chaining.

---

**Q3 (partial application): How do you simulate partial application in Java?**

A: Partial application: fix some arguments of a function now, return a function waiting for the rest.
`Function<String, Predicate<String>> startsWith = prefix -> s -> s.startsWith(prefix)`. Apply the
first arg: `Predicate<String> startsWithHttp = startsWith.apply("http")`. Reuse the parameterized predicate multiple times.

*What separates good from great:* Partial application is most useful for creating context-specific
versions of general functions. `Function<Locale, Function<String, String>> formatCurrency = locale -> amount -> new DecimalFormat("", DecimalFormatSymbols.getInstance(locale)).format(amount)`. Apply locale: `Function<String, String> formatUSD = formatCurrency.apply(Locale.US)`. Now format many amounts without repeating the locale. In production: partial application creates domain-specific functions from general utilities. It's a form of dependency injection: the first argument (context, configuration) is "injected" at creation time, the second (data) at use time.

---

**Q4 (predicates): How do you build a rule engine using Predicate composition?**

A: Rule engine components: (1) individual rules as `Predicate<T>`, (2) combinator methods
(`and`, `or`, `negate`), (3) a `RuleEngine` that evaluates a list of rules. Named predicates:
`isEligible`, `isActive`, `hasSufficientBalance`. Combine at runtime: `isEligible.and(isActive).and(hasSufficientBalance)`. Can be loaded from configuration (predicate registry by name).

*What separates good from great:* The dynamic rule engine: rules are fetched from a database or
configuration, mapped to `Predicate<T>` instances, combined with `and`/`or` based on the
configuration's logic operators. This is how real rule engines work: the data (rules) drives which
predicates are combined and how. The static approach (hardcoded `and`/`or`): works for simple cases.
The dynamic approach (rules in database): requires a predicate registry (`Map<String, Predicate<Order>>`),
a combinator (reads `AND`, `OR` from the DB row), and a runtime assembly. Drools, EasyRules, and
custom mini-rule-engines all use this predicate composition model at their core.

---

**Q5 (higher order): What are the benefits of designing APIs that accept functional interfaces?**

A: (1) Behavior injection: callers provide the algorithm, the API provides the structure.
`withRetry(Supplier<T>, int, long)` - the caller provides what to retry. (2) Testability: mock the
behavior with a simple lambda. (3) Composition: callers can compose behaviors before passing.
(4) Decoupling: the API doesn't depend on specific implementations. (5) No anonymous class
boilerplate: callers use lambdas.

*What separates good from great:* The template method pattern (inheritance-based) vs functional
parameter (composition-based): template method = extend a class, override the variant step.
Functional parameter = pass the behavior as a lambda. Functional parameter wins for: (1) when
you don't control the class hierarchy (can't extend), (2) when you want multiple behaviors at once
(pass different lambdas to different calls), (3) when the behavior varies per call (not per class).
Template method wins for: (1) when the variation has state, (2) when the subclass needs multiple
related hook methods (template method can call multiple abstract methods in sequence; a single
lambda can only represent one function). Real-world: Spring's `JdbcTemplate`, `RestTemplate` use
functional callbacks (Callback interfaces) extensively for this reason.

---

**Q6 (function identity): What is Function.identity() and when is it useful?**

A: `Function.identity()` = `t -> t` - the identity function. Returns its argument unchanged.
Use case: when a method requires a `Function` argument but you want to keep the value as-is.
`stream.map(Function.identity())` - no-op map (effectively, usually optimized away). More useful:
`Collectors.toMap(Function.identity(), String::length)` - keys ARE the strings (identity key mapper), values are lengths.

*What separates good from great:* `Function.identity()` is semantically cleaner than `t -> t` because it names the intent: "the identity function." In a long stream pipeline: `Collectors.toMap(Function.identity(), this::computeValue)` is clearer than `Collectors.toMap(s -> s, this::computeValue)`. The identity function appears in the mathematics of function composition (it's the "zero element" for composition: `f.andThen(identity) = f` and `identity.andThen(f) = f`). In Java: used as a default "no transformation" in APIs that require a mapper but where the caller wants no mapping.

---

**Q7 (consumer chain): How do you chain multiple Consumer operations?**

A: `Consumer.andThen(Consumer)` - execute both consumers in sequence. Returns a new Consumer.
`consumer1.andThen(consumer2).andThen(consumer3)` - chain as many as needed. Each consumer gets
the same argument (no transformation). Use case: multiple side effects on the same object.
`logConsumer.andThen(saveConsumer).andThen(notifyConsumer)`.

*What separates good from great:* Consumer chaining for the observer/event-handler pattern:
`Consumer<Event> handlers = handlers.stream().reduce(Consumer::andThen).orElse(e -> {})`. This
reduces a list of handlers to a single composite consumer. The `orElse(e -> {})` handles the
empty list case (no-op consumer). This is the functional equivalent of iterating and calling each
handler, but expressed as a single composed Consumer. For high-performance: the composed Consumer
adds indirection overhead. Measure if performance-critical. For event dispatching: usually fine.

---

**Q8 (unchecked wrapper): What is the standard pattern for handling checked exceptions in functional interfaces?**

A: Three options: (1) catch inside the lambda and wrap in unchecked. (2) `ThrowingFunction<T, R>` - custom functional interface with `throws`. (3) Utility wrapper: `static <T,R> Function<T,R> unchecked(ThrowingFunction<T,R> f)`. Option 3 is the cleanest for stream pipelines.

*What separates good from great:* The subtle difference between (1) and (3): if you catch and wrap
inside the lambda, the lambda is a `Function<T, R>` (no checked exception). If you define
`ThrowingFunction` and use it ONLY with the unchecked wrapper: you separate the "what the function
does" from "how exceptions are handled." The `ThrowingFunction` can be stored separately and reused.
The wrapper handles the exception policy. This is the open/closed principle applied to exception
handling: the function is the "open" part (different behaviors), the wrapper is the "closed" part
(consistent exception handling policy). Libraries like Lombok (`@SneakyThrows`) handle this at the
bytecode level without the wrapper, but at the cost of transparency.

---

**Q9 (functional vs imperative): When does functional composition increase complexity rather than reduce it?**

A: Functional composition increases complexity when: (1) the pipeline is deep and operations are
not named (anonymous lambdas, no clear semantics), (2) debugging requires understanding the composed
state (breakpoints between chained calls are awkward), (3) the logic has many conditionals that
are better expressed as if/else, (4) side effects need to be in a specific complex order (hard to
express in a pure pipeline).

*What separates good from great:* The "functional purity" trap: trying to express all logic as
stream pipelines. A for-loop with nested ifs is sometimes clearer than a stream with multiple
`filter().map().flatMap().reduce()`. The engineering judgment: functional works best for transformation
pipelines (each step clearly transforms data). It fails for control flow (branching, looping with
state). Real production code: use stream pipelines for data transformations, use imperative code
for stateful business logic. The hybrid approach: convert to stream at the collection boundary,
process with imperative inside complex map steps, collect back to collection. Don't force everything
into stream form.

---

### ⚖️ Comparison Table

| Feature | Predicate | Function | Consumer | Supplier | BiFunction |
|---------|-----------|----------|----------|----------|------------|
| Signature | T -> boolean | T -> R | T -> void | void -> T | T, U -> R |
| Compose | and/or/negate | andThen/compose | andThen | N/A | andThen |
| Use for | Filter, test | Transform | Side effects | Lazy provide | Two-input transform |
| Primitive variants | IntPredicate etc. | IntFunction etc. | IntConsumer | IntSupplier | ToIntBiFunction |
| Null handling | Must handle | Must handle | Must handle | Returns nullable | Must handle |

---

### 🏛️ System Design

*(Omit: L3 file.)*

---

### 📊 Diagram

*(Omit: Functional composition is clearly expressed in the code examples.)*

---

---

## Stream Collectors and Reduction Operations

### 🎯 Model Answer

**30 seconds:**
> Collectors: terminal operations that fold a stream into a result. Common: `toList()`, `toSet()`,
> `toMap(key, value)`, `groupingBy(key)`, `partitioningBy(pred)`, `joining(delimiter)`, `counting()`,
> `summingInt()`, `summarizingInt()`. Downstream collectors: `groupingBy(key, counting())` = count
> per group. Custom collectors: `Collector.of(supplier, accumulator, combiner, finisher)`. Reduction:
> `reduce(identity, BinaryOp)` for fold operations.

**3 minutes (Senior):**
> Collector mechanics and design:
>
> 1. **Collector contract**: 4 components. Supplier: creates mutable result container. Accumulator:
>    folds one element into the container. Combiner: merges two containers (for parallel). Finisher:
>    final transformation of the container. Characteristics: `CONCURRENT` (combiner not used,
>    accumulator thread-safe), `UNORDERED` (order doesn't matter), `IDENTITY_FINISH` (finisher = identity).
>
> 2. **Mutable reduction vs immutable reduction**: `collect()` = mutable (adds to a container).
>    `reduce()` = immutable fold (creates new values at each step). For building collections: always
>    `collect`. For summing, combining values: `reduce`.
>
> 3. **groupingBy downstream collectors**: `groupingBy(f, counting())` = count per group.
>    `groupingBy(f, mapping(g, toList()))` = map then collect per group. `groupingBy(f, collectingAndThen(toList(), Collections::unmodifiableList))` = post-process collected result.
>
> 4. **teeing** (Java 12): collect into two collectors simultaneously.
>    `Collectors.teeing(c1, c2, merger)`.
>
> 5. **Custom collector**: for any aggregation not expressible with standard collectors or their
>    compositions. Implement the 4-component contract.

**Blank Mind Recovery:**

**(1) Restate:** "Collectors: fold stream to result. toList, toMap, groupingBy (downstream: counting,
summingInt, mapping), joining, partitioningBy. reduce(): fold to single value. Collector.of():
custom. teeing(): two collectors in parallel."

**(2) First principles:** "Collecting is structuring. The stream is a sequence of events. Collectors
shape that sequence into a result: a list, a map, a count, a string. The collector defines what
the 'bucket' looks like (supplier), how to fill it (accumulator), how to combine buckets (combiner),
and how to finalize it (finisher)."

**(3) Bridge:** "Collectors are like airport sorting conveyor belts. The stream is the baggage.
toList: one belt, everything on it. groupingBy: belt splits by destination (key). counting: counter
increments per bag. The combiner: two baggage sorters merge their sorted bags at the end (for parallel
sorting)."

---

### 📘 Concept Explanation

**Collector contract and built-in collectors:**
```
COLLECTOR INTERFACE:
  
  interface Collector<T, A, R> {
      Supplier<A>         supplier();       // creates mutable container
      BiConsumer<A, T>    accumulator();    // adds element to container
      BinaryOperator<A>   combiner();       // merges two containers (parallel)
      Function<A, R>      finisher();       // transforms container to result
      Set<Characteristics> characteristics();
  }
  
  // T = element type, A = accumulator container type, R = result type
  // For toList: T=T, A=ArrayList<T>, R=List<T>
  // supplier = ArrayList::new
  // accumulator = ArrayList::add
  // combiner = (left, right) -> { left.addAll(right); return left; }
  // finisher = identity (A=R for lists)

STANDARD COLLECTORS:

  // BASIC:
  .collect(toList())                  // modifiable list (implementation-specific)
  .collect(toUnmodifiableList())      // unmodifiable list (Java 10+)
  .toList()                           // shorthand (Java 16+, unmodifiable)
  .collect(toSet())
  .collect(toUnmodifiableSet())
  
  // MAP:
  .collect(toMap(keyFn, valueFn))                          // throws on dup key
  .collect(toMap(keyFn, valueFn, mergeFunction))           // handles dup key
  .collect(toMap(keyFn, valueFn, mergeFunction, TreeMap::new)) // specific map type
  
  // GROUPING:
  .collect(groupingBy(classifier))                   // Map<K, List<T>>
  .collect(groupingBy(classifier, counting()))       // Map<K, Long>
  .collect(groupingBy(classifier, summingInt(fn)))   // Map<K, Integer>
  .collect(groupingBy(classifier, mapping(fn, toList()))) // Map<K, List<R>>
  .collect(groupingBy(classifier, toMap(...)))       // Map<K, Map<...>>
  .collect(groupingBy(classifier, groupingBy(c2)))   // Map<K, Map<K2, List<T>>>
  
  // PARTITION:
  .collect(partitioningBy(predicate))                // Map<Boolean, List<T>>
  .collect(partitioningBy(predicate, counting()))    // Map<Boolean, Long>
  
  // STRING:
  .collect(joining())
  .collect(joining(", "))
  .collect(joining(", ", "[", "]"))  // prefix and suffix
  
  // STATISTICS:
  .collect(counting())               // Long
  .collect(summingInt(fn))           // Integer
  .collect(averagingInt(fn))         // Double
  .collect(summarizingInt(fn))       // IntSummaryStatistics
  
  // TRANSFORMATION:
  .collect(mapping(fn, downstream))          // map then collect
  .collect(collectingAndThen(c, finisher))   // collect then transform
  .collect(filtering(pred, downstream))      // filter then collect (Java 9+)
  .collect(flatMapping(fn, downstream))      // flatMap then collect (Java 9+)
  
  // TEEING (Java 12):
  .collect(teeing(c1, c2, (r1, r2) -> combine(r1, r2)))
  // collects with BOTH c1 and c2, then merges with the merger function

REDUCE vs COLLECT:
  // reduce: immutable folding (each step creates new value)
  int sum = IntStream.range(1, 5).reduce(0, Integer::sum);
  // 0 -> +1=1 -> +2=3 -> +3=6 -> +4=10
  
  // collect: mutable reduction (accumulates into a container)
  List<Integer> list = Stream.of(1,2,3).collect(toList());
  // new ArrayList<>() -> .add(1) -> .add(2) -> .add(3)
  
  // For complex reductions: use collect
  // For numeric aggregation: use reduce or specialized IntStream.sum()
```

---

### 💻 Code Example

> **Code walkthrough:** The `teeing` collector is the most underused standard collector. It enables
> two-pass computations in a single pass: both collectors see every element. The custom batch collector
> is a production pattern for chunking large streams into batches for API calls or database inserts.

```java
// STANDARD GROUPINGBY WITH DOWNSTREAM:
record Order(String userId, String category, double amount) {}
List<Order> orders = getOrders();

// Count orders per user:
Map<String, Long> orderCountByUser = orders.stream()
    .collect(Collectors.groupingBy(Order::userId, Collectors.counting()));

// Total amount per category:
Map<String, Double> totalByCategory = orders.stream()
    .collect(Collectors.groupingBy(
        Order::category,
        Collectors.summingDouble(Order::amount)
    ));

// Nested grouping: orders by user, grouped by category:
Map<String, Map<String, List<Order>>> byUserThenCategory = orders.stream()
    .collect(Collectors.groupingBy(
        Order::userId,
        Collectors.groupingBy(Order::category)  // downstream = another groupingBy
    ));

// TEEING: compute min and max in one pass
record MinMax(double min, double max) {}
MinMax stats = orders.stream()
    .collect(Collectors.teeing(
        Collectors.minBy(Comparator.comparingDouble(Order::amount)),
        Collectors.maxBy(Comparator.comparingDouble(Order::amount)),
        (min, max) -> new MinMax(
            min.map(Order::amount).orElse(0.0),
            max.map(Order::amount).orElse(0.0)
        )
    ));

// CUSTOM COLLECTOR: batch into fixed-size chunks
static <T> Collector<T, ?, List<List<T>>> batching(int batchSize) {
    return Collector.of(
        ArrayList::new,                          // supplier: new list of lists
        (batches, element) -> {                  // accumulator
            if (batches.isEmpty() || batches.get(batches.size() - 1).size() >= batchSize) {
                batches.add(new ArrayList<>());  // new batch
            }
            batches.get(batches.size() - 1).add(element);
        },
        (left, right) -> {                       // combiner: merge two partial results
            if (!left.isEmpty() && !right.isEmpty() &&
                left.get(left.size() - 1).size() < batchSize) {
                // Fill the last left batch from the first right batch
                List<T> lastLeft = left.get(left.size() - 1);
                List<T> firstRight = right.get(0);
                while (lastLeft.size() < batchSize && !firstRight.isEmpty()) {
                    lastLeft.add(firstRight.remove(0));
                }
                if (firstRight.isEmpty()) right.remove(0);
            }
            left.addAll(right);
            return left;
        }
        // No finisher: IDENTITY_FINISH (ArrayList<List<T>> is the result)
    );
}

// Usage:
List<Long> productIds = getProductIds();  // 10,000 ids
List<List<Long>> batches = productIds.stream()
    .collect(batching(100));  // 100 batches of 100 ids

batches.forEach(batch -> apiClient.fetchProducts(batch)); // batch API calls
```

> **Code walkthrough:** The `groupingBy` with `counting()` downstream replaces the imperative
> loop that builds a `Map<String, Long>` by checking for existence and incrementing. The nested
> `groupingBy` shows how to build a `Map<K, Map<K2, List<T>>>` in one pass. The `teeing` collector
> computes min AND max in a single stream pass instead of two. The custom `batching` collector
> solves a real production problem: chunking large ID lists for batch API calls, with a combiner
> that correctly handles batch boundaries when used in parallel.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `groupingBy` for grouping, `counting()` for counts per group, `joining()` for string building,
> `toMap()` for key-value collection. `summarizingInt()` for stats. `reduce(0, Integer::sum)` for
> numeric folds.

---

**Senior / Staff (5+ years):**
> Collector design: use `collectingAndThen` to post-process, `mapping` for pre-mapping, `filtering`
> (Java 9) for downstream filtering. `teeing` (Java 12) for two-pass computations in one pass.
> Custom collectors for domain-specific aggregations (batching, windowing, top-K). The collector
> characteristics (`CONCURRENT`, `UNORDERED`, `IDENTITY_FINISH`) affect parallel stream behavior:
> `CONCURRENT` = no combiner (single concurrent container), `UNORDERED` = parallel partitioning
> more efficient.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`reduce()` is better than `collect()` for building collections."**
`reduce()` for building collections is O(n^2) in most cases. `reduce((list, elem) -> { List<T> newList = new ArrayList<>(list); newList.add(elem); return newList; })` creates a new list at every step. `collect(toList())` uses a mutable accumulator (append in place). O(n) vs O(n^2). Rule: never use `reduce()` to build a mutable container. Use `collect()`.

**Misconception 2: "`groupingBy` with concurrent downstream requires a `ConcurrentHashMap`."**
The map returned by `groupingBy` is a `HashMap` by default (not thread-safe). For a thread-safe
grouping in a parallel stream: use `Collectors.groupingByConcurrent(...)`. It uses a `ConcurrentHashMap`
and the `CONCURRENT` characteristic (no combiner needed). Regular `groupingBy` in a parallel stream:
safe (each thread has its own accumulator, merged by the combiner), but not `groupingByConcurrent`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: toMap throws IllegalStateException for duplicate keys.**
```
Symptom: stream.collect(toMap(Order::userId, order -> order))
  throws java.lang.IllegalStateException: Duplicate key user123

Root cause:
  toMap with two args throws on duplicate keys (by design).
  If two orders have the same userId: the second one triggers the exception.
  The developer assumed userIds were unique (they're not in this data set).

Diagnosis:
  Stack trace: IllegalStateException at toMap merge
  Print duplicate keys: 
    Map<String, Long> dups = orders.stream()
        .collect(groupingBy(Order::userId, counting()))
        .entrySet().stream()
        .filter(e -> e.getValue() > 1)
        .collect(toMap(Map.Entry::getKey, Map.Entry::getValue));
  Output: {user123=3, user456=2}

Fix:
  Option A: Keep the last value (overwrite)
    .collect(toMap(Order::userId, o -> o, (existing, dup) -> dup));

  Option B: Keep the first value
    .collect(toMap(Order::userId, o -> o, (existing, dup) -> existing));

  Option C: Collect all to list (use groupingBy instead)
    .collect(groupingBy(Order::userId));  // Map<String, List<Order>>

  Option D: Merge values
    .collect(toMap(
        Order::userId,
        Order::amount,
        Double::sum  // sum amounts for the same user
    ));

Prevention: ALWAYS use the 3-arg toMap when uniqueness is not 100% guaranteed.
  If you're certain keys are unique: add an assertion or test that proves it.
  Default: prefer groupingBy to toMap for grouping scenarios.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Collector contract (4 components) | 2 minutes |
| groupingBy with downstream | 2 minutes |
| reduce vs collect | 2 minutes |
| toMap duplicate handling | 1 minute |
| teeing collector | 2 minutes |
| Custom collector | 2 minutes |
| parallel stream collectors | 2 minutes |
| collectingAndThen | 1 minute |
| summarizingInt | 1 minute |

---

**Q1 (contract): Explain the four components of the Collector interface.**

A: `Supplier<A> supplier()`: creates the mutable accumulator container. Called once for sequential,
once per thread for parallel. `BiConsumer<A, T> accumulator()`: adds one stream element `T` to
the container `A`. Called once per element. `BinaryOperator<A> combiner()`: merges two partial
containers (for parallel). For sequential: never called. `Function<A, R> finisher()`: transforms
the final container to the result type. For `IDENTITY_FINISH` collectors: `finisher = identity`.

*What separates good from great:* The combiner design: for parallel streams, the source is split
into segments, each segment is processed with its own accumulator container (supplier + accumulator).
At the end: the per-segment containers are merged pairwise (combiner). The combiner must be associative:
`combiner(combiner(a, b), c)` must equal `combiner(a, combiner(b, c))`. For the `toList` combiner:
`left.addAll(right); return left` - associative. For a custom collector with ordering requirements:
the combiner must maintain the order (left elements before right elements). The `UNORDERED`
characteristic: signals that element order doesn't matter, enabling more efficient parallel splitting.

---

**Q2 (downstream): What is a downstream collector and how does it compose with groupingBy?**

A: Downstream collector: a collector applied to each group's elements after grouping. `groupingBy(classifier, downstream)` = first group by classifier, then collect each group's elements with the downstream collector. `groupingBy(Order::category, counting())` - group by category, count each group. `groupingBy(Order::category, mapping(Order::amount, toList()))` - group by category, map amounts, collect to list.

*What separates good from great:* Downstream collectors chain: `groupingBy(f, collectingAndThen(mapping(g, toList()), Collections::unmodifiableList))` = group, map within each group, collect to unmodifiable list. Reading the chain: innermost first. The power of downstream collectors: a single stream pass can build arbitrarily complex nested data structures. Without downstream collectors: you'd need multiple stream passes or manual imperative loops. The `filtering` (Java 9) downstream: `groupingBy(f, filtering(pred, toList()))` = include only elements matching `pred` in each group. Different from `stream.filter(pred).collect(groupingBy(f))`: the latter removes elements from ALL groups; the former only removes from within each group (groups with no matching elements still appear as empty lists vs being absent entirely).

---

**Q3 (reduce semantics): What is the identity requirement for reduce()?**

A: `reduce(identity, op)`: `identity` must be the "zero element" for `op`. `op.apply(identity, x) == x` for all x. For `Integer.sum`: identity = 0 (0 + x = x). For multiplication: identity = 1 (1 * x = x). For string concatenation: identity = "" ("" + x = x). If identity is wrong: result is wrong for parallel streams (the wrong identity is combined with partial results).

*What separates good from great:* The identity requirement is critical for parallel `reduce`. Sequential `reduce`: uses the identity as the starting value for the single fold. Parallel `reduce`: each segment starts with the identity (not the first element of the previous segment). If the identity is wrong: `parallelStream().reduce(1, Integer::sum)` would give the wrong answer (each partition starts at 1, not 0; the final sum is too high by n-1 where n is the number of partitions). This is a silent bug: no exception, wrong number. Always validate the identity value. Rule: the identity for `+` is 0, for `*` is 1, for `max(a,b)` is `Integer.MIN_VALUE`, for `min(a,b)` is `Integer.MAX_VALUE`.

---

**Q4 (collect and then): When do you use collectingAndThen?**

A: `collectingAndThen(downstream, finisher)`: collect with `downstream`, then apply `finisher` to the result. Use cases: (1) create an unmodifiable collection: `collectingAndThen(toList(), Collections::unmodifiableList)`, (2) convert to a different type after collecting: `collectingAndThen(toList(), MyClass::fromList)`, (3) wrap in Optional: `collectingAndThen(toList(), list -> list.isEmpty() ? Optional.empty() : Optional.of(list.get(0)))`.

*What separates good from great:* `collectingAndThen(toList(), l -> Collections.unmodifiableList(l))` vs `toUnmodifiableList()` (Java 10). The latter is more concise. But `collectingAndThen` is the general mechanism: any transformation after collection. The most powerful use: `collectingAndThen(groupingBy(f), Collections::unmodifiableMap)` - create an unmodifiable map of lists. Or: `collectingAndThen(toList(), list -> list.size() >= 3 ? Optional.of(list.subList(0, 3)) : Optional.empty())` - top 3 or empty. This bridges the gap between stream operations and custom post-processing without needing two passes.

---

**Q5 (teeing): What problem does the teeing collector solve?**

A: `Collectors.teeing(c1, c2, merger)` (Java 12): passes every element to BOTH c1 and c2 in a single pass. Solves the two-pass problem: computing two independent aggregations over the same stream. Without teeing: either collect to a list first then run two streams over it (extra memory), or use `summarizingInt` (but limited to one int field). With teeing: compute min+max, sum+count (= average), first+last, or any two independent aggregations simultaneously.

*What separates good from great:* `teeing(minBy(...), maxBy(...), MinMax::new)` replaces `IntSummaryStatistics` for arbitrary types (not just primitive-typed fields). The pattern: teeing is most useful when you need two DIFFERENT aggregations (not just different fields of the same aggregation). For a single field with multiple stats: `summarizingInt(fn)` provides count, sum, min, max, average in one pass. For two DIFFERENT fields: teeing with two `summarizingInt` collectors merged into a combined result. The merger function is the "join" step that combines the two independent results.

---

**Q6 (parallel collector): What characteristics should a collector have for parallel streams?**

A: `UNORDERED`: element order doesn't matter for the result. Enables more efficient parallel splitting (no need to maintain encounter order). `IDENTITY_FINISH`: `finisher` is the identity function (no transformation of the container). Avoids one extra function call. `CONCURRENT`: a single accumulator container is shared by all threads (no combiner needed). The accumulator must be thread-safe. Most thread-safe: `ConcurrentHashMap` + atomic operations. `groupingByConcurrent`: uses `CONCURRENT`.

*What separates good from great:* The `CONCURRENT` characteristic: enables the most efficient parallel collection because there's no combining step. The thread-safe accumulator does the work. But: the accumulator must support concurrent calls. `ArrayList.add()` is not thread-safe. For `CONCURRENT` to work: use `ConcurrentHashMap` (for `groupingByConcurrent`), `ConcurrentLinkedQueue` (thread-safe queue), or explicit synchronization. Most custom collectors: should NOT declare `CONCURRENT` unless the accumulator is specifically thread-safe. Declaring `CONCURRENT` incorrectly (on a non-thread-safe accumulator): data corruption in parallel streams.

---

**Q7 (flatMapping): When do you use Collectors.flatMapping()?**

A: `flatMapping(Function<T, Stream<U>>, downstream)` (Java 9): within a grouping, flat-map each element's collection and collect the flattened elements. Use case: each order has multiple items; collect all items per user. Without `flatMapping`: `groupingBy(userId, mapping(Order::getItems, toList()))` gives `Map<String, List<List<Item>>>` (list of lists). With `flatMapping`: `groupingBy(userId, flatMapping(o -> o.getItems().stream(), toList()))` gives `Map<String, List<Item>>` (flat list per user).

*What separates good from great:* The `flatMapping` downstream collector (Java 9) is the solution to the "nested list" problem in groupBy. It was added specifically because `mapping(Order::getItems, toList())` produces a list of lists (awkward), and flattening requires a two-step approach without it. Java 9 added `flatMapping` and `filtering` downstream collectors to complete the set of composable transformations. Before using `flatMapping`: check if a simple `stream().flatMap().collect(groupingBy(...))` is clearer. The downstream form: use when the flat-mapping is specific to each group (different context per group), not a global transformation.

---

**Q8 (summarizing): What is IntSummaryStatistics and when do you use it?**

A: `IntSummaryStatistics` (also Long, Double variants): holds count, sum, min, max, average for a stream of primitive values. Collected via `summarizingInt(fn)`. All statistics computed in a single pass. Use when: you need more than one statistic from the same stream. `DoubleSummaryStatistics stats = orders.stream().collect(summarizingDouble(Order::amount))`. Access: `stats.getCount()`, `stats.getSum()`, `stats.getMin()`, `stats.getMax()`, `stats.getAverage()`.

*What separates good from great:* The alternative: five separate stream passes (one for count, one for sum, etc.). `summarizingInt`: one pass, all five. Or: `teeing(counting(), summingInt(fn), ...)` for two stats in one pass but not all five. `summarizingInt` is the most efficient for all-five-stats-of-a-single-field. For MULTIPLE fields: you'd need multiple collectors (or multiple passes). The `IntSummaryStatistics` object is also useful as a mutable accumulator for imperative code: `new IntSummaryStatistics()` + `.accept(value)` per element. This is rare but valid for cases where you're not using streams.

---

**Q9 (efficiency): How do you minimize the number of stream passes over a collection?**

A: Single-pass design: use a collector that computes all needed aggregations in one pass. `teeing` for two aggregations. `summarizingInt` for stats. Multi-step grouping with `groupingBy(f, downstream)` avoids multiple passes per group. If multiple passes are inevitable: collect to an intermediate `List<T>` first (avoiding re-reading from source), then run multiple streams over the list.

*What separates good from great:* The "two passes vs one pass" trade-off: one pass is O(n) with high constant factor (complex collector). Two passes: O(2n) = O(n) with lower constant factor (two simple collectors). For most data sizes: the difference is negligible. The real concern: data source that can only be read ONCE (a one-shot `Iterator`, a network stream, a `Files.lines()` stream). For one-shot sources: `teeing` or `summarizingInt` are necessary. For collections (re-readable): two-pass is fine and often simpler to read. The rule: optimize for single-pass only when the source is one-shot or when profiling shows the double-iteration is a bottleneck.

---

### ⚖️ Comparison Table

| Collector | Output | Duplicates | Order | Use Case |
|-----------|--------|------------|-------|----------|
| toList() | List | Yes | Preserved | General collection |
| toSet() | Set | No | None | Deduplication |
| toMap(k,v) | Map | Keys: no | None | Key-value lookup |
| groupingBy(f) | Map<K,List> | All | Per-group | Categorize elements |
| partitioningBy(p) | Map<Boolean,List> | All | Per-group | Binary split |
| joining(d) | String | Yes | Preserved | String concatenation |
| counting() | Long | N/A | N/A | Count elements |
| summarizingInt(f) | IntSummaryStats | N/A | N/A | Count+sum+min+max+avg |
| teeing(c1,c2,m) | custom | N/A | N/A | Two aggregations at once |

---

### 🏛️ System Design

*(Omit: L3 file.)*

---

### 📊 Diagram

*(Omit: Collector mechanics are clearly expressed in the concept explanation.)*
