---
layout: default
title: "Java Language - L3 Modern Java"
parent: "Java Language"
grand_parent: "SK Interview"
nav_order: 7
permalink: /java-language/l3-modern-java/
---

# Text Blocks: Indentation Stripping and Incidental Whitespace

**TL;DR** - Text blocks are multi-line string literals delimited by
`"""`. Java automatically strips common leading whitespace (incidental
indentation) so the text block can be indented to match surrounding
code without that indentation becoming part of the string value.

**Interview Weight:** medium - tested as part of Java 13-15 knowledge
and multi-line string handling.

---

### 🎯 Model Answer

**30 seconds:**

> Text blocks start and end with `"""`. The opening `"""` must be on
> its own line. Java strips the common leading indentation from all
> lines - this is incidental whitespace removal. The result is the
> logical content, not the indented content.

**3 minutes (Senior):**

> Before text blocks, multi-line strings required string concatenation
> or `\n` escapes - verbose and unreadable. Text blocks let you write
> multi-line content with the same indentation as surrounding code.
>
> The key algorithm: Java determines the "incidental indentation" as
> the minimum leading whitespace across all non-blank content lines
> plus the closing `"""` line. That amount is stripped from all lines.
> Trailing whitespace on each line is also removed unless explicitly
> preserved.
>
> The position of the closing `"""` controls the indent depth. Moving
> it further left strips less indentation. Moving it to column 0
> preserves all content indentation.
>
> Text blocks also allow `\s` (explicit trailing space) and `\<newline>`
> (line continuation without a newline in the result).

---

### 📘 Concept Explanation

**Basic Syntax**

```java
// The opening """ must be on its own line (immediately followed by newline)
String json = """
        {
            "name": "Alice",
            "age": 30
        }
        """;  // closing """ determines indent stripping

// Equivalent to:
String json = "{\n    \"name\": \"Alice\",\n    \"age\": 30\n}";
// Note: 8-space indent stripped (the minimum across all lines + closing """)
```

**Incidental Whitespace Algorithm**

```
Line 1:  "        {\n"           (8 spaces)
Line 2:  "            \"name\""  (12 spaces)
Line 3:  "        }\n"           (8 spaces)
Close:   "        "              (8 spaces)

Min indent = 8 -> strip 8 spaces from every line
Result:
"{\n"
"    \"name\": \"Alice\",\n"
"    \"age\": 30\n"
"}\n"
```

**Controlling the Trailing Newline**

The last content line determines if there is a trailing newline:

```java
// WITH trailing newline (closing """ on its own line):
String withNewline = """
        hello
        world
        """;
// "hello\nworld\n"

// WITHOUT trailing newline (closing """ on same line as last content):
String noNewline = """
        hello
        world""";
// "hello\nworld"
```

**Text Block Escapes**

```java
// \s: explicit space (prevents trailing whitespace trimming)
String aligned = """
        alpha  \s
        beta   \s
        gamma  \s
        """;   // trailing spaces preserved on each line

// \<newline>: line continuation (no newline in result)
String oneLiner = """
        SELECT * FROM users \
        WHERE active = true
        """;
// "SELECT * FROM users WHERE active = true\n"
```

**String Methods Added for Text Blocks**

```java
String.indent(n)      // add/remove n leading spaces per line
String.stripIndent()  // remove common leading whitespace
String.translateEscapes() // process escape sequences
String.formatted(args)    // same as String.format, instance method
```

---

### 💻 Code Example

```java
// BAD: traditional multi-line SQL - hard to read
String query = "SELECT u.id, u.name, o.total " +
    "FROM users u " +
    "JOIN orders o ON u.id = o.user_id " +
    "WHERE u.active = true " +
    "  AND o.created_at > ? " +
    "ORDER BY o.total DESC";
// One wrong space causes SQL syntax error
// Hard to visually verify query structure
```

> **Code walkthrough:** String concatenation forces SQL onto one logical
> line with manual spacing. The indentation of the Java code is noise
> in the string content. A missing space at a join boundary causes a
> runtime SQL error. There is no visual correspondence between the Java
> code and the resulting query.

```java
// GOOD: text block SQL - readable and correctly indented
String query = """
        SELECT u.id, u.name, o.total
        FROM users u
        JOIN orders o ON u.id = o.user_id
        WHERE u.active = true
          AND o.created_at > ?
        ORDER BY o.total DESC
        """;
// Exactly equivalent to the concatenation above
// Visual structure matches SQL formatting conventions
```

> **Code walkthrough:** The text block preserves the SQL's visual
> structure. The 8-space incidental indentation is stripped. Each
> SQL clause is on its own line with correct indentation. The closing
> `"""` is at the same indentation level as the content, so 8 spaces
> are stripped. The result is the SQL string without leading spaces.

```java
// Dynamic text block with formatted()
String jsonTemplate = """
        {
            "user": "%s",
            "role": "%s",
            "active": %b
        }
        """.formatted(user.getName(), user.getRole(), user.isActive());
```

> **Code walkthrough:** `.formatted()` is called directly on the text
> block literal - it is just a String. The `%s`, `%b` placeholders
> work identically to `String.format`. For dynamic JSON, prefer a
> proper JSON library (Jackson, Gson) over string formatting - but
> for small, controlled templates, `.formatted()` is idiomatic.

**How to test:** Compare text block result to the equivalent
concatenation string with `assertEquals`. Test edge cases: trailing
newline present/absent, indentation level control.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"Text blocks let you write multi-line strings without escaping
newlines or concatenating. The common leading whitespace is stripped
automatically. The closing `\"\"\"` position controls how much
indentation is stripped."

**Senior / Staff:**
"The incidental whitespace algorithm is elegant: it measures the
minimum indentation across all content lines and the closing `\"\"\"`.
This means you can move the entire text block left or right in the
file without changing the string value, as long as the closing `\"\"\"`
moves with it.

The `\s` escape is useful for whitespace-significant content (fixed-
width text, CSV, protocol messages). Without `\s`, trailing spaces
are stripped - any content relying on trailing spaces must use `\s`.

Text blocks are not templates - they do not evaluate expressions.
For dynamic content, you still use `.formatted()` or a template engine.
For complex templates, prefer dedicated libraries over text blocks
with many `%s` placeholders."

---

### ⚠️ Common Misconceptions

| #   | Misconception                                            | Reality                                                                                                              | Danger                                         |
| --- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| 1   | "Opening `\"\"\"` can be on same line as content"        | The opening `"""` must be immediately followed by a newline - content cannot start on the same line.                 | Compile error                                  |
| 2   | "All leading whitespace is stripped"                     | Only the COMMON (minimum) leading whitespace is stripped - content indentation relative to the minimum is preserved. | Unexpected stripping of structural indentation |
| 3   | "Text blocks evaluate expressions like template strings" | Text blocks are string literals - no expression evaluation. Use `.formatted()` for substitution.                     | Expecting JavaScript-style `${var}` to work    |
| 4   | "Trailing spaces are preserved by default"               | Trailing whitespace is stripped by default. Use `\s` to preserve intentional trailing spaces.                        | Whitespace-sensitive content truncated         |
| 5   | "Text blocks are slower than regular strings"            | Text blocks are processed at compile time. At runtime, they are plain String objects.                                | Performance concern that does not exist        |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Unexpected trailing newline in text block**

_Symptom:_ String comparison fails; extra `\n` at end.

_Root Cause:_ Closing `"""` is on its own line, which adds a trailing
newline to the result.

_Diagnostic:_

```java
String s = """
        hello
        """;
s.endsWith("\n");  // true - trailing newline present
s.length();        // 6: "hello\n"
```

_Fix:_ Move closing `"""` to end of last content line to omit trailing
newline: `hello""";`

**FM2 - Too much indentation stripped (content starts at column 0)**

_Symptom:_ Content lines lose their relative indentation; first token
appears at column 0.

_Root Cause:_ Closing `"""` is at column 0 (or less indented than
content), causing max stripping.

_Fix:_ Indent closing `"""` to the level you want as the zero baseline.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                                          |
| ---------------- | ----------------------------------------------------------------------------- |
| 5 minutes        | Syntax + automatic indent stripping + trailing newline rule                   |
| 15 minutes       | Add incidental whitespace algorithm + closing `"""` control                   |
| 30 minutes       | Add `\s`, `\<newline>`, String methods, template vs literal                   |
| Under pressure   | "Multi-line string; strips common indent; closing `\"\"\"` controls baseline" |

**[JUNIOR] Q1 - Hands-On**
_What does this text block evaluate to?_

```java
String s = """
        Hello
        World
        """;
```

The string is `"Hello\nWorld\n"`.

Reasoning:

- Opening `"""` is on its own line
- Content lines have 8-space indent
- Closing `"""` also has 8-space indent
- Minimum indent = 8 spaces (all lines including closing)
- Strip 8 spaces from each line
- Closing `"""` on its own line adds trailing `\n`

_What separates good from great:_ Working through the stripping
calculation step by step rather than just stating the result.

---

**[MID] Q2 - Trade-off**
_When would you prefer text blocks over String.format() for
multi-line output?_

Prefer text blocks when:

- The template structure is more important than the substitutions
- The literal content spans many lines (SQL, HTML, JSON templates)
- Readability of the template itself matters (code review, maintenance)

Prefer `String.format()` / `MessageFormat` when:

- Heavy parameterization (many `%s` close together)
- Format strings come from external sources (i18n, config)
- Named placeholders are needed (MessageFormat `{0}`, `{1}`)

Text blocks + `.formatted()` is the sweet spot for templates that
are long but have few substitution points.

_What separates good from great:_ The "named placeholder" point -
`String.format` uses positional `%s`, while `MessageFormat` supports
`{name}` which is better for i18n.

---

**[SENIOR] Q3 - Production**
_How do you handle SQL injection when using text blocks for queries?_

Text blocks are for query structure, not for values:

```java
// BAD: string interpolation for values = SQL injection
String badQuery = """
        SELECT * FROM users
        WHERE name = '%s'
        """.formatted(userInput);  // inject risk

// GOOD: text block for structure, PreparedStatement for values
String query = """
        SELECT * FROM users
        WHERE name = ?
          AND active = ?
        """;

try (PreparedStatement ps = conn.prepareStatement(query)) {
    ps.setString(1, userInput);  // parameterized - no injection
    ps.setBoolean(2, true);
    ResultSet rs = ps.executeQuery();
}
```

Text blocks eliminate SQL structure errors (missing spaces between
concatenated strings) but parameterized queries remain mandatory for
any user-supplied values.

_What separates good from great:_ Immediately connecting text blocks
to SQL injection risk - this is the security question behind "text
blocks + SQL."

---

### ⚖️ Comparison Table

| String form    | Multiline | Escaping    | Indent control     | Expressions        |
| -------------- | --------- | ----------- | ------------------ | ------------------ |
| Regular string | Via `\n`  | Manual `\"` | Manual             | None               |
| Concatenation  | Yes       | Manual      | Fragile            | Via +              |
| Text block     | Native    | Minimal     | Via `"""` position | Via `.formatted()` |
| StringBuilder  | Yes       | Manual      | Manual             | Manual             |

**Deciding factor:** Use text blocks for any multi-line string literal
that benefits from visual structure matching the actual content. Use
parameterized queries or template engines for dynamic content.

---

---

# Switch Expressions: Exhaustiveness, Arrow Syntax, and Yield

**TL;DR** - Switch expressions (Java 14 stable) compute a value from
a switch. Arrow form (`->`) eliminates fall-through and implicit break.
`yield` returns a value from a block-form arm. Exhaustiveness is
compiler-verified for switch expressions (unlike switch statements).

**Interview Weight:** medium - tested alongside pattern matching and
sealed class discussions.

---

### 🎯 Model Answer

**30 seconds:**

> Switch expressions differ from switch statements: they compute a
> value, require exhaustiveness (no missing cases), and the arrow form
> (`->`) eliminates fall-through. `yield` returns a value from a block
> arm. Switch expressions are the foundation for pattern matching in
> switches.

**3 minutes (Senior):**

> The traditional switch statement had two design problems: fall-through
> (execution continues to the next case without break) and no value
> computation (you had to assign to a variable in each case).
>
> Switch expressions solve both. The arrow form `case X -> expr` never
> falls through - each arm is independent. The colon form `case X:` in
> a switch expression still supports fall-through but requires `yield`
> to return the value.
>
> Exhaustiveness is required for switch expressions: if not all possible
> inputs are covered, it is a compile error. For switch statements,
> missing cases are silent. This is the key safety improvement.
>
> Pattern matching in switch (Java 21 stable) extends this: `case Integer i ->`,
> `case String s when s.length() > 5 ->` - all using the expression
> syntax and exhaustiveness checking.

---

### 📘 Concept Explanation

**Arrow Syntax (no fall-through)**

```java
// Switch expression - computes a value, arrow form
int numLetters = switch (day) {
    case MONDAY, FRIDAY, SUNDAY -> 6;    // comma: multiple labels
    case TUESDAY                -> 7;
    case THURSDAY, SATURDAY     -> 8;
    case WEDNESDAY              -> 9;
    // No default needed IF all enum values covered
};

// Arrow can be: expression, block, or throw
String result = switch (status) {
    case ACTIVE   -> "active";           // expression
    case INACTIVE -> {                   // block
        log.info("inactive status");
        yield "inactive";               // yield from block
    }
    case BANNED   -> throw new AccessException("banned"); // throw
};
```

**Colon Syntax in Switch Expression (fall-through + yield)**

```java
// Colon form still supports fall-through
int numLetters = switch (day) {
    case MONDAY:
    case FRIDAY:
    case SUNDAY:
        yield 6;     // yield required in colon-form expression
    case TUESDAY:
        yield 7;
    default:
        yield -1;
};
```

**Exhaustiveness Rules**

| Switch type                 | Exhaustiveness                                   |
| --------------------------- | ------------------------------------------------ |
| Switch statement            | Optional `default`                               |
| Switch expression           | Required: must cover all cases OR have `default` |
| Switch expression on enum   | All values OR `default`                          |
| Switch expression on sealed | All subtypes (no `default` needed)               |

**Sealed + Switch Expression (compile-time exhaustiveness)**

```java
sealed interface Shape permits Circle, Rectangle { }
record Circle(double r) implements Shape { }
record Rectangle(double w, double h) implements Shape { }

double area(Shape s) {
    return switch (s) {
        case Circle c    -> Math.PI * c.r() * c.r();
        case Rectangle r -> r.w() * r.h();
        // No default: sealed + all cases = exhaustive
    };
}
```

---

### 💻 Code Example

```java
// BAD: switch statement with fall-through bugs
String classify(int score) {
    String grade;
    switch (score / 10) {
        case 10:
        case 9:
            grade = "A";
        case 8:                    // BUG: falls through from A!
            grade = "B";           // 90-100 also reaches here
        case 7:
            grade = "C";
        default:
            grade = "F";
    }
    return grade;  // always returns "F" due to fall-through cascade
}
```

> **Code walkthrough:** Every case falls through to the next because
> there are no `break` statements. A score of 95 (case 9) sets grade
> to "A", then falls to "B", then "C", then "F" - returning "F". This
> is one of the most common Java beginner bugs and the primary reason
> switch expressions were designed without fall-through.

```java
// GOOD: switch expression, arrow form - no fall-through possible
String classify(int score) {
    return switch (score / 10) {
        case 10, 9 -> "A";     // comma = same arm, no fall-through
        case 8     -> "B";
        case 7     -> "C";
        case 6     -> "D";
        default    -> "F";
    };
}
// 95 -> case 9 -> "A". Done. Cannot fall through.
```

> **Code walkthrough:** The arrow form makes each case independent.
> `case 10, 9` handles both with a single arrow - the comma syntax
> replaces the fall-through pattern for same-action cases. The switch
> expression returns directly - no intermediate variable needed.
> Exhaustiveness requires `default` here (int is not sealed).

```java
// Complex arm with block + yield
HttpStatus mapToHttp(ServiceResult result) {
    return switch (result) {
        case ServiceResult.Success s -> HttpStatus.OK;
        case ServiceResult.NotFound f -> HttpStatus.NOT_FOUND;
        case ServiceResult.ValidationError e -> {
            log.warn("Validation failed: {}", e.message());
            yield e.isClientError()
                ? HttpStatus.BAD_REQUEST
                : HttpStatus.UNPROCESSABLE_ENTITY;
        }
        case ServiceResult.InternalError e -> {
            log.error("Service error", e.cause());
            yield HttpStatus.INTERNAL_SERVER_ERROR;
        }
        // Exhaustive via sealed ServiceResult
    };
}
```

> **Code walkthrough:** The block-form arm (curly braces) runs
> multiple statements before `yield`ing the value. `yield` is
> mandatory in block arms of switch expressions - the compiler
> enforces that every code path through a block arm yields or throws.
> This prevents silent return of null or uninitialized values.

**How to test:** Test each case arm in isolation. Test the default
arm. Verify `yield` returns the correct value from block arms.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"Switch expressions compute a value and have two forms: arrow (no
fall-through) and colon (traditional, uses yield). They require
exhaustiveness - all cases must be covered. Arrow syntax is preferred
for its clarity and safety."

**Senior / Staff:**
"The exhaustiveness guarantee is the most important property. A switch
statement with a missing case is a silent bug. A switch expression
with a missing case is a compile error. This shifts an entire class
of bugs from runtime to compile time.

Combined with sealed classes, switch expressions achieve the most
powerful form of type dispatch in Java: exhaustive, compile-verified,
no-cast, no-default. Adding a new sealed subtype makes all switch
expressions on that type compile errors until the new case is handled.

The `yield` keyword is intentionally verbose - it signals that you
are returning from a block inside a switch expression, distinct from
`return` (which returns from the method) and `break` (which exits
a statement)."

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                  | Reality                                                                                                                                                      | Danger                                               |
| --- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------- |
| 1   | "Arrow switch still needs break"                               | Arrow arms do not fall through. break is not needed or allowed.                                                                                              | Compile error from unnecessary break                 |
| 2   | "switch expressions and switch statements are interchangeable" | Expressions require exhaustiveness; statements do not. Expressions compute a value; statements cannot.                                                       | Missing default in expression causes compile error   |
| 3   | "yield works in switch statements"                             | yield is for switch expressions only. Switch statements use break or assign to variable.                                                                     | Compile error: yield in statement context            |
| 4   | "Multiple labels with arrow means fall-through"                | `case A, B ->` is not fall-through - it is one arm with two labels. Both labels execute the same arm, with no cascade.                                       | Confusing comma-labels with fall-through             |
| 5   | "Switch expression always needs default"                       | With sealed types covering all cases, no default needed. With enums covering all values, no default. Default is only needed when not all values are covered. | Unnecessary default suppressing exhaustiveness check |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Forgetting yield in block arm**

_Symptom:_ Compile error: "switch expression does not cover all
possible input values" or "missing return value."

_Root Cause:_ A block arm (`{...}`) in a switch expression does not
have a `yield` statement on all code paths.

_Fix:_

```java
// BAD: missing yield
case ERROR -> {
    log.error("failed");
    // no yield - compile error
}

// GOOD: yield required
case ERROR -> {
    log.error("failed");
    yield "error";
}
```

**FM2 - Using switch expression where statement is needed**

_Symptom:_ Compile error when trying to use a switch without consuming
its value.

_Root Cause:_ A switch expression must be used as a value (assigned,
returned, passed). If you just want side effects, use a switch statement.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                                   |
| ---------------- | ---------------------------------------------------------------------- |
| 5 minutes        | Arrow syntax + no fall-through + exhaustiveness                        |
| 15 minutes       | Add yield + comma labels + sealed integration                          |
| 30 minutes       | Add colon-form comparison + pattern matching on switch                 |
| Under pressure   | "Expression computes value; arrow=no-fallthrough; exhaustive required" |

**[MID] Q1 - Hands-On**
_What is wrong with this switch expression?_

```java
String label = switch (x) {
    case 1 -> "one";
    case 2 -> "two";
};
```

It is not exhaustive. `x` is an `int`, which has values beyond 1 and 2. The compiler requires a `default` arm.

Fix:

```java
String label = switch (x) {
    case 1 -> "one";
    case 2 -> "two";
    default -> "other";
};
```

Exception: if `x` were an enum with exactly values `ONE` and `TWO`,
and both are covered, no `default` needed.

_What separates good from great:_ Mentioning the sealed/enum exception

- the exhaustiveness check uses type information.

---

**[SENIOR] Q2 - Trade-off**
_When should you use switch statement vs switch expression?_

Switch expression when:

- A value is computed from cases (return or assign)
- Exhaustiveness check is valuable (enums, sealed types)
- Fall-through is not needed (use comma labels instead)

Switch statement when:

- Side effects only (logging, modifying state), no value needed
- Fall-through is intentional and necessary
- Complex multi-statement arms that do not yield a value

In practice: prefer switch expressions wherever you compute a value.
Use switch statements only for statement-oriented operations.

_What separates good from great:_ The statement for "intentional
fall-through" case - there are rare cases where fall-through is
genuinely the right model (e.g., parsing where cases share setup logic).

---

**[STAFF] Q3 - Architecture**
_How does switch expression exhaustiveness interact with library
evolution?_

When a sealed type adds a new permitted subtype, all switch expressions
over that type become compile errors. This is a breaking change.

Library design rule: if the sealed hierarchy is a public API, adding
a new subtype is a source-breaking change for all consumers with switch
expressions.

Strategies:

1. Provide a `default`-equivalent for library users:
   - Add a `sealed` + `non-sealed` subtype as an extension slot
   - Consumers handle `UnknownShape` as their default case
2. Use semantic versioning to signal the breaking change
3. Provide migration tooling (IntelliJ quick-fix inserts new case)

The trade-off: exhaustiveness catch bugs at compile time (benefit)
but requires all consumers to update when the hierarchy evolves (cost).
For internal sealed types, the cost is acceptable. For public library
APIs, consider whether the type should be sealed at all.

_What separates good from great:_ The library API perspective -
sealed + exhaustive switch is a bilateral contract between library
and consumer.

---

### ⚖️ Comparison Table

| Syntax             | Fall-through | Exhaustive | Value  | Multi-label        |
| ------------------ | ------------ | ---------- | ------ | ------------------ |
| Statement (colon)  | Yes          | No         | No     | Yes (fall-through) |
| Statement (arrow)  | No           | No         | No     | Yes (comma)        |
| Expression (colon) | Yes          | Yes        | yield  | Yes (fall-through) |
| Expression (arrow) | No           | Yes        | direct | Yes (comma)        |

**Deciding factor:** Use switch expressions with arrow syntax for
all value-computing dispatch. Switch statements remain for side-
effect-only dispatch. Colon form only when fall-through is intentional.

---

---

# var: Local Variable Type Inference and Its Limits

**TL;DR** - `var` infers the type of a local variable from its
initializer at compile time. It is purely a compile-time feature -
no runtime cost, no bytecode change. Key limits: `var` cannot be used
for fields, parameters, return types, or uninitialized variables.

**Interview Weight:** medium - tested as part of Java 10 features and
readability trade-off discussions.

---

### 🎯 Model Answer

**30 seconds:**

> `var` lets the compiler infer local variable types from the right-hand
> side of an assignment. It is a compile-time feature - the bytecode
> is identical to writing the type explicitly. `var` cannot be used
> for fields, method parameters, or return types.

**3 minutes (Senior):**

> `var` reduces boilerplate when the type is obvious from context -
> particularly for complex generic types like
> `Map<String, List<Optional<User>>>`. It is NOT dynamic typing:
> the type is fixed at compile time and type-checking is unchanged.
>
> The key trade-off: `var` reduces noise when the type is obvious
> (right side is a constructor call or a factory method with a clear
> name). It hurts readability when the type is not clear from context
> (method return values, streams of complex types).
>
> Limits: `var` requires an initializer (type must be inferable).
> It cannot be `null` (no type to infer). It cannot appear in
> lambdas (lambda parameters use a different `var` in Java 11 for
> annotation purposes only). It cannot be used for fields, parameters,
> or return types - only local variables.

---

### 📘 Concept Explanation

**Valid var Uses**

```java
// Constructor call - type obvious on right
var list = new ArrayList<String>();  // ArrayList<String>

// Factory methods - clear from name
var map = Map.of("a", 1, "b", 2);   // Map<String, Integer>

// Complex generic types - reduces noise
var cache = new HashMap<String, List<Optional<User>>>();

// Enhanced for loops
for (var entry : map.entrySet()) {   // Map.Entry<String, Integer>
    System.out.println(entry.getKey());
}

// Try-with-resources
try (var conn = dataSource.getConnection()) { // Connection
    // ...
}
```

**Invalid var Uses**

```java
// NO: uninitialized
var x;              // compile error: no initializer to infer from

// NO: null initializer
var obj = null;     // compile error: cannot infer type from null

// NO: fields
class Foo {
    var value = 42;  // compile error: var not allowed for fields
}

// NO: parameters
void process(var x) { }  // compile error

// NO: return type
var getValue() { return 42; }  // compile error

// NO: array initializer without explicit type
var arr = {1, 2, 3};   // compile error: no type to infer
var arr = new int[]{1, 2, 3};  // OK
```

**var for Lambda Parameters (Java 11)**

```java
// Java 11: var in lambda parameters (for annotation use)
Consumer<String> consumer = (@NonNull var s) -> System.out.println(s);
// This allows annotations on lambda parameters
// Without var: (@NonNull String s) also works
// var here is for annotation consistency, not type inference
```

**Type Inference is Compile-Time**

```java
var list = new ArrayList<String>();
list.add("hello");    // works - list is ArrayList<String>
list.add(42);         // compile error - still strongly typed

// var is NOT:
// - dynamic typing
// - runtime type resolution
// - JavaScript-style 'var'
```

---

### 💻 Code Example

```java
// BAD: var obscures type - method return not obvious
var result = processOrder(orderId);  // what is result?
var data = fetchUserData(userId);    // what is data?

// Reader must look up method signatures to understand the code
// var adds no value here - it removes type documentation
```

> **Code walkthrough:** When the right-hand side is a method call
> with a non-obvious return type, `var` forces readers to look up the
> method signature. The type IS documentation - `Result<Order>` tells
> you more than `var`. `var` works against readability here.

```java
// GOOD: var when type is obvious from context
// Constructor call - obviously ArrayList<String>
var names = new ArrayList<String>();

// Complex generic - var reduces noise without losing clarity
var groupedUsers = new HashMap<String, List<User>>();

// For loops - entry type is clear from map declaration
Map<String, Integer> scores = ...;
for (var entry : scores.entrySet()) {
    System.out.printf("%s: %d%n",
        entry.getKey(), entry.getValue());
}

// Stream with known intermediate types
var activeAdmins = users.stream()
    .filter(User::isActive)
    .filter(u -> u.hasRole("ADMIN"))
    .toList();
// 'activeAdmins' is List<User> - obvious from context
```

> **Code walkthrough:** `var` adds value when the type is already
> visible on the right side (constructor, factory) or the type is
> a consequence of a clearly-named operation. `new HashMap<String, List<User>>()`
> already shows the type - duplicating it on the left is noise.
> `activeAdmins` from a user stream filtered by isActive is clearly
> a List of Users.

**How to test:** There is no runtime difference from explicit types.
Test the logic, not `var`.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"`var` is compile-time type inference for local variables. The type
is inferred from the initializer. It is the same as writing the type
explicitly - no runtime difference. Cannot be used for fields or
method parameters."

**Senior / Staff:**
"The `var` guidelines I follow: use it when the type appears on the
right side (constructor, factory method). Avoid when the type is the
only documentation (method return values, abstract results).

The key misconception to avoid: `var` is not dynamic typing. It is
purely syntactic sugar. IntelliJ shows the inferred type inline.
Bytecode is identical.

The Java team's guidance from JEP 286: `var` should not be used
when it would make code harder to read. The omitted type information
must be recoverable from immediate context. If a code reviewer would
have to look up a method signature to understand the type, use the
explicit type."

---

### ⚠️ Common Misconceptions

| #   | Misconception                                | Reality                                                                                                                                                     | Danger                                                   |
| --- | -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| 1   | "var is dynamic typing like JavaScript"      | var is compile-time inference. Type is fixed. Type-checking is identical to explicit types.                                                                 | Wrong mental model of Java's type system                 |
| 2   | "var can be assigned different types later"  | Once inferred, the type is fixed. `var x = 1; x = "hello";` is a compile error.                                                                             | Expecting dynamic behavior                               |
| 3   | "var works for method parameters"            | var cannot be used for method parameters (except lambda parameters in Java 11).                                                                             | Compile error                                            |
| 4   | "var is a keyword"                           | `var` is a reserved type name, not a keyword. A variable named `var` is legal (though confusing).                                                           | Slight: `var` as variable name is valid but bad practice |
| 5   | "var makes code harder to maintain at scale" | With IDE support (inline type hints), var is as maintainable as explicit types. The guideline is readability at point of reading, not IDE-assisted reading. | Over-avoiding var where it genuinely reduces noise       |

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                                |
| ---------------- | ------------------------------------------------------------------- |
| 5 minutes        | What var does + key limits (no field/param/return)                  |
| 15 minutes       | Add compile-time only + when to use/avoid guidelines                |
| 30 minutes       | Add lambda var (Java 11) + JEP 286 guidelines                       |
| Under pressure   | "Compile-time inference, local only, type fixed, no dynamic typing" |

**[MID] Q1 - Conceptual**
_What are the rules for where var can and cannot be used?_

Can use: local variable declarations with an initializer.

```java
var x = 42;                    // local variable
for (var item : collection) {} // enhanced for
try (var res = open()) {}       // try-with-resources
```

Cannot use:

- Fields: `var field = 0;` in class body
- Method parameters: `void method(var x)`
- Return types: `var method()`
- Without initializer: `var x;`
- With null: `var x = null;`

The rule: `var` is syntactic sugar for local variables where the
initializer's type uniquely determines the variable type.

_What separates good from great:_ The "null" case - students often
forget that `var x = null` is invalid because null has no type.

---

**[SENIOR] Q2 - Trade-off**
_When should you use var vs explicit type?_

Use `var` when:

- Right side is a constructor: `var list = new ArrayList<String>()`
- Right side is a factory with clear name: `var map = Map.of(...)`
- Complex generic reduces noise significantly
- Short-lived variable in a narrow scope (for loop body)

Use explicit type when:

- Right side is a method call with non-obvious return type
- The type IS the documentation (interfaces: `List<T>` not `ArrayList<T>`)
- Public API or code that will be read by many people
- The variable is used far from its declaration

The test: "Can a reader determine the type without looking up the
method signature?" If yes, `var` is appropriate.

_What separates good from great:_ The "type as documentation" point -
declaring `List<User>` (interface) vs `ArrayList<User>` (concrete)
is lost with `var`.

---

### ⚖️ Comparison Table

| Context           | var             | Explicit type | Preference |
| ----------------- | --------------- | ------------- | ---------- |
| Constructor call  | Clear           | Redundant     | var        |
| Method return     | Unclear         | Documented    | Explicit   |
| Complex generics  | Noise reduction | Verbose       | var        |
| For loop variable | Clear           | Reasonable    | var        |
| Field             | Not allowed     | Required      | Explicit   |
| Parameter         | Not allowed     | Required      | Explicit   |

**Deciding factor:** Use `var` when type is obvious from right side.
Use explicit type when the type is the primary documentation.

---

---

# Default and Static Interface Methods: Evolution Without Breaking

**TL;DR** - `default` methods let interfaces ship new behavior without
breaking existing implementors. `static` methods provide utility
functions tied to the interface namespace. Together they enabled
the Java 8 Stream API without breaking any existing code.

**Interview Weight:** medium - tested in Java 8 evolution, API design,
and diamond-problem discussions.

---

### 🎯 Model Answer

**30 seconds:**

> `default` methods add implementations to interfaces. When you add
> a `default` to an existing interface, all implementors get the
> behavior for free without changing. `static` methods on interfaces
> provide utility functions tied to the interface name. Both enabled
> backward-compatible evolution of the Java collections framework.

**3 minutes (Senior):**

> Before Java 8, adding a method to an interface was a breaking change
>
> - every existing implementor had to add the new method. This made
>   Java collection framework evolution nearly impossible.
>
> `default` methods solved this by letting the interface provide a
> fallback implementation. `Collection.stream()`, `Iterable.forEach()`,
> `List.sort()` - all were added to existing interfaces in Java 8
> without breaking any existing code.
>
> The diamond problem (two interfaces with the same default method)
> is resolved deterministically: the most-specific implementation
> wins. If a class provides its own implementation, that always wins.
> If two interfaces tie, the compiler requires explicit disambiguation
> via `Interface.super.methodName()`. Abstract class implementations
> always beat interface defaults.
>
> `static` interface methods do not participate in inheritance - they
> must be called by interface name directly. `Comparator.comparing()`
> is the canonical example.

---

### 📘 Concept Explanation

**Default Method Syntax**

```java
interface Validator<T> {
    // Abstract: every implementor must define
    boolean validate(T value);

    // Default: fallback provided, optional override
    default boolean validateNonNull(T value) {
        return value != null && validate(value);
    }

    // Default composing the abstract contract
    default Validator<T> and(Validator<T> other) {
        return value ->
            this.validate(value) && other.validate(value);
    }
}

// Implementing class only needs validate()
class LengthValidator implements Validator<String> {
    @Override
    public boolean validate(String s) {
        return s.length() >= 8;
    }
    // validateNonNull and and() inherited automatically
}
```

> **Code walkthrough:** `validate` is abstract - every implementor
> must define it. `validateNonNull` and `and` are `default` - they
> have implementations that compose the abstract contract. A new
> implementation of `Validator` gets both defaults for free. This
> is the template method pattern applied to interfaces: abstract
> defines the primitive operation, default defines the algorithm.

**Static Interface Methods**

```java
interface Validator<T> {
    boolean validate(T value);

    // Static: utility factory, called as Validator.nonEmpty()
    static Validator<String> nonEmpty() {
        return s -> s != null && !s.isEmpty();
    }

    static Validator<String> minLength(int min) {
        return s -> s != null && s.length() >= min;
    }
}

// Usage: called on the interface name, not on instances
Validator<String> v =
    Validator.nonEmpty().and(Validator.minLength(8));
```

> **Code walkthrough:** Static interface methods are called on the
> interface name directly - `Validator.nonEmpty()`, not
> `myValidator.nonEmpty()`. They cannot be overridden by implementing
> classes and do not participate in inheritance. They act as
> namespace-attached factory methods. `Comparator.comparing()`,
> `Comparator.naturalOrder()`, and `Predicate.not()` are standard
> library examples of this pattern.

**Diamond Problem Resolution**

```java
interface A {
    default String greet() { return "Hello from A"; }
}

interface B {
    default String greet() { return "Hello from B"; }
}

// Ambiguous - compiler requires explicit disambiguation
class C implements A, B {
    @Override
    public String greet() {
        return A.super.greet();  // explicit: call A's default
    }
}

// Class override always wins over any default
class D implements A, B {
    @Override
    public String greet() { return "Hello from D"; }
}

// Abstract class always wins over interface default
abstract class E {
    public String greet() { return "Hello from E"; }
}

class F extends E implements A {
    // F.greet() -> E.greet(), not A's default
}
```

> **Code walkthrough:** The disambiguation rule has three levels:
> (1) class or abstract class implementations always win over all
> interface defaults; (2) more-specific interface wins when B extends
> A; (3) tie requires `Interface.super.method()`. The compiler
> enforces resolution - you cannot accidentally inherit the wrong
> default. This hierarchy is deterministic and compiler-checked.

**Inheritance Priority (Diamond)**

| Winner                     | Scenario                         |
| -------------------------- | -------------------------------- |
| Class method               | Always wins over any default     |
| More specific interface    | B extends A: B's default wins    |
| Explicit `Interface.super` | Required when two interfaces tie |

---

### 💻 Code Example

```java
// BAD: adding a method to an interface (Java 7 style)
// Any new method here breaks ALL existing implementors
interface Logger {
    void log(String message);
    // Adding logWithLevel below requires change in every
    // Logger implementation across the codebase
    // void logWithLevel(Level lvl, String msg); // BREAKING
}
```

> **Code walkthrough:** In Java 7, adding `logWithLevel` to `Logger`
> means every class implementing `Logger` fails to compile. Libraries
> with thousands of custom Logger implementations all break at once.
> This made evolving popular interfaces like `Collection`, `Iterable`,
> and `Iterator` nearly impossible without breaking the ecosystem.

```java
// GOOD: default method enables backward-compatible evolution
interface Logger {
    void log(String message);  // abstract: still required

    // New methods - existing implementors get these for free
    default void logWithLevel(Level level, String msg) {
        log("[" + level + "] " + msg);
    }

    default void logError(String msg, Throwable t) {
        log("ERROR: " + msg + " - " + t.getMessage());
    }

    static Logger stdout() {
        return msg -> System.out.println(msg);
    }
}

// Existing implementation: zero changes needed
class FileLogger implements Logger {
    private final PrintWriter writer;

    FileLogger(PrintWriter w) { this.writer = w; }

    @Override
    public void log(String message) {
        writer.println(message);
    }
    // logWithLevel, logError inherited automatically
}
```

> **Code walkthrough:** `FileLogger` only implements `log()` - the
> one abstract method. It automatically gets `logWithLevel()` and
> `logError()` via the default implementations. No change to
> `FileLogger` was needed. The static `stdout()` factory creates a
> lambda-based implementation. This is exactly how Java 8 added
> `Collection.stream()`: every existing collection in every codebase
> got `.stream()` for free without a single line of change.

**Real-world: Comparator.comparing()**

```java
List<Employee> employees = ...;

// Before Java 8: verbose anonymous Comparator
employees.sort(new Comparator<Employee>() {
    @Override
    public int compare(Employee a, Employee b) {
        return a.getName().compareTo(b.getName());
    }
});

// Java 8+: static interface method + default composition
employees.sort(Comparator.comparing(Employee::getName));

// Chaining via default methods thenComparing, reversed
employees.sort(
    Comparator.comparing(Employee::getDepartment)
              .thenComparing(Employee::getSalary)
              .reversed()
);
```

> **Code walkthrough:** `Comparator.comparing()` is a static method
> on the `Comparator` interface - a factory that creates a Comparator
> from a key extractor. `thenComparing()` and `reversed()` are
> default methods on `Comparator` that compose comparators into new
> ones. The entire fluent Comparator API is built from static
> factories and default composition methods added in Java 8.

**How to test:** Test that existing implementations get the correct
default behavior without changes. Test diamond disambiguation by
implementing two interfaces with the same default. Verify explicit
override takes precedence.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"`default` methods let interfaces provide implementations that
implementing classes can optionally override. `static` methods are
utility methods on the interface type. Both were added in Java 8
to allow backward-compatible API evolution without breaking
existing implementations."

**Senior / Staff:**
"Default methods enabled the Java 8 Stream API. Every `Collection`,
`Iterable`, and `Iterator` implementation in every codebase got
`stream()`, `forEach()`, and `spliterator()` for free.

The design principle: `default` is for optional behavior that
composes the abstract contract. The core contract stays abstract -
that is what the implementor MUST define. Default adds utility,
composition, and adapter behavior.

For library API design: adding a default shifts evolution burden
from implementors to the interface. This is deliberate - it enables
richer interfaces but requires correct defaults. A default method
with a bug is propagated to every implementor automatically.

Abstract class vs interface with defaults: if the type needs instance
state, use abstract class. Interfaces cannot have instance fields.
If you need multiple inheritance of behavior, interfaces are the
only option."

---

### ⚠️ Common Misconceptions

| #   | Misconception                                         | Reality                                                                                                                                          | Danger                                     |
| --- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| 1   | "Adding a default method is always non-breaking"      | Non-breaking for implementors. If two library interfaces both add the same default, any class implementing both gets a compile error on upgrade. | Diamond collision on library update        |
| 2   | "Static interface methods can be called on instances" | Static interface methods require the interface name: `Validator.nonEmpty()`, not `myValidator.nonEmpty()`.                                       | Compile error                              |
| 3   | "default methods make abstract classes obsolete"      | Abstract classes still provide: shared state, constructors, non-public API, single-inheritance structure. Defaults cannot have instance state.   | Wrong API choice for stateful base classes |
| 4   | "Interface.super.method() calls the class super"      | `Interface.super.method()` calls a specific interface's default, not the class hierarchy's super.                                                | Wrong mental model of resolution order     |
| 5   | "All methods with bodies in interfaces are default"   | `static` methods also have bodies but are not `default`. Only `default` participates in inheritance.                                             | Confusing static and default               |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Diamond collision after library update**

_Symptom:_ Code that compiled before stops compiling after updating
a dependency. Error: "class Foo inherits unrelated defaults for
`method()` from types A and B."

_Root Cause:_ Two interfaces both added a `default` method with the
same signature in separate library updates. The implementing class
now has an ambiguous inheritance.

_Diagnostic:_

```java
// Check which interface added the conflicting default
// IntelliJ: class highlighted with "must override" marker
// javac: "error: types X and Y are incompatible;
//         both define method(), but with unrelated return types"
```

> **Code walkthrough:** The compiler reports the two conflicting
> interfaces by name in the error message. To fix, override the
> method in the implementing class and call the desired default
> explicitly via `InterfaceA.super.method()`. The override is now
> permanent - future upgrades adding new defaults will also conflict
> if both interfaces define them, requiring another override update.

_Fix:_

```java
@Override
public String method() {
    return InterfaceA.super.method();  // explicit selection
}
```

> **Code walkthrough:** `InterfaceA.super.method()` is the only
> syntax for calling a specific interface's default from an
> implementing class. It is not `super.method()` (that calls the
> class hierarchy super) nor `InterfaceA.method()` (that would be
> a static call). The `Interface.super` syntax is unique to this
> disambiguation pattern.

**FM2 - Default ignores the abstract contract**

_Symptom:_ Default method works in isolation but silently ignores
the implementing class's behavior.

_Root Cause:_ The default has its own fixed logic instead of
composing the abstract method.

_Fix:_

```java
// BAD: default ignores the abstract validate()
default void process(T value) {
    System.out.println("processing " + value);
    // never calls validate() - useless for implementations
}

// GOOD: default composes the abstract contract
default void processIfValid(T value) {
    if (validate(value)) {  // calls the abstract method
        doProcess(value);
    }
}
```

> **Code walkthrough:** Default methods derive value from composing
> abstract methods. A default that hardcodes logic without calling
> any abstract method defeats the purpose of the interface contract.
> The pattern is: abstract defines WHAT (the contract the implementor
> provides), default defines HOW (a provided implementation using
> the WHAT). Defaults that bypass the abstract are typically bugs.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                                                                       |
| ---------------- | ---------------------------------------------------------------------------------------------------------- |
| 5 minutes        | Syntax + backward compatibility purpose                                                                    |
| 15 minutes       | Add diamond resolution + Comparator examples                                                               |
| 30 minutes       | Add library evolution story + abstract class comparison                                                    |
| Under pressure   | "default = evolution without breaking; static = interface utility; diamond = class wins or explicit super" |

**[JUNIOR] Q1 - Conceptual**
_What problem do default interface methods solve?_

Default methods solve the interface evolution problem. Before Java 8,
adding any method to an interface was a breaking change - every class
implementing that interface had to add the new method, or code would
not compile.

Default methods let the interface provide a fallback implementation.
Existing implementors get the method automatically without any change.

Real example: `Collection.stream()` was added in Java 8 as a default
method. Every existing class implementing `Collection` - ArrayList,
LinkedList, every custom collection - immediately had `.stream()`
available without a single line of change.

_Why they ask:_ Tests whether you understand the motivation behind
default methods, not just the syntax.

_Likely follow-up:_ "What is the diamond problem with defaults?"

_What separates good from great:_ Connecting the abstract answer
("backward-compatible evolution") to the concrete Java 8 story
(`Collection.stream()`) and knowing the scale of impact.

---

**[JUNIOR] Q2 - Conceptual**
_What is the difference between a default method and a static method
on an interface?_

`default` method:

- Called on instances: `myValidator.validateNonNull(x)`
- Participates in inheritance: implementing classes inherit it
- Can be overridden by implementing classes
- Can call other abstract interface methods

`static` method:

- Called on the interface name: `Validator.nonEmpty()`
- Does not participate in inheritance
- Cannot be overridden
- Cannot call abstract methods (no instance context)

Both have implementations in the interface body. The distinction:
`default` is about behavior that implements carry; `static` is about
factory/utility functions attached to the interface namespace.

_Why they ask:_ Separates syntax knowledge from conceptual
understanding of Java 8 interface features.

_Likely follow-up:_ "What are `private` methods on interfaces?" (Java 9+)

_What separates good from great:_ The inheritance distinction - static
methods are namespaced utilities, not inherited behavior.

---

**[MID] Q3 - Hands-On**
_What happens when two interfaces both have a default method with
the same name and a class implements both?_

Compile error: "class C inherits unrelated defaults for `method()`
from types A and B."

The class must override the method and explicitly choose which
default to delegate to:

```java
class C implements A, B {
    @Override
    public String method() {
        return A.super.method();  // explicit selection
    }
}
```

> **Code walkthrough:** `A.super.method()` is the only valid syntax
> for calling a specific interface default from an implementor. The
> override resolves the ambiguity at the implementing class level.
> If C provides its own implementation from scratch, no
> `Interface.super` call is needed - the class override wins.

If C provides its own implementation, no disambiguation is needed:
the class override always wins over any interface default.

_Why they ask:_ Tests the diamond problem resolution rules, which
are tested in almost every Java 8 interface discussion.

_Likely follow-up:_ "Which wins: abstract class method or interface
default?"

_What separates good from great:_ Stating the full hierarchy: (1)
class override wins; (2) more-specific interface wins; (3) tie
requires `Interface.super.method()`.

---

**[MID] Q4 - Trade-off**
_When should you use an abstract class instead of an interface with
default methods?_

Use **abstract class** when:

- Shared instance state (fields) is needed
- Constructor injection or initialization order matters
- Protected/package-private methods are needed
- Single inheritance is acceptable and desired

Use **interface + default** when:

- Multiple types need the capability (multiple inheritance)
- Pure behavior composition without state
- Backward-compatible API evolution is important
- The type should be a capability, not a lineage

Decision rule: **if you need state, use an abstract class**. If you
need multiple inheritance of behavior with no state, use interfaces
with defaults.

_Why they ask:_ This is the core OOP design question disguised as
a Java 8 question.

_Likely follow-up:_ "What if you need both state and multiple
inheritance?"

_What separates good from great:_ The state distinction is the
fundamental, irreducible difference. Defaults cannot have instance
fields.

---

**[SENIOR] Q5 - Architecture**
_How did default methods enable the Java 8 Stream API?_

Before Java 8, `Collection`, `Iterable`, and `Iterator` had no
streaming capability. Adding methods directly would have broken every
collection implementation in every Java codebase in existence.

The strategy:

1. Define `Stream<T>` and `Spliterator<T>` as new types
2. Add `default Spliterator<T> spliterator()` to `Iterable`
   (delegates to `iterator()` - the existing abstract method)
3. Add `default Stream<T> stream()` to `Collection`
   (delegates to `spliterator()`)
4. Add `default void forEach(Consumer<T> action)` to `Iterable`

Every existing collection inherited these defaults. Collections
that wanted better performance (ArrayList, ConcurrentHashMap)
overrode with faster implementations - the "opt-in" pattern.

This is the abstract-default layering: `stream()` delegates to
`spliterator()` which delegates to `iterator()` (the one abstract
method every collection already implemented).

_Why they ask:_ Tests whether you understand the architecture, not
just "Java 8 added streams."

_Likely follow-up:_ "What would have happened without default methods?"

_What separates good from great:_ The delegation chain - `stream()`
-> `spliterator()` -> `iterator()`. The abstract method is the
one thing every implementor must provide; everything else composes
from it.

---

**[SENIOR] Q6 - Trade-off**
_What are the risks of adding default methods to a public library
interface?_

**Risk 1 - Diamond collision:** if two library interfaces both add
the same default, every class implementing both gets a new compile
error without any action from the class author.

**Risk 2 - Wrong default propagation:** a bug in a default method
is automatically propagated to every implementor. Fixing requires
a new library version and potentially inconsistent behavior between
versions.

**Risk 3 - Semantic contract erosion:** the more behavior a default
provides, the less clear the interface's core contract becomes.

Mitigations:

- Test diamond conflicts with common dependency combinations
- Keep defaults thin - they should delegate to abstract methods
- Document defaults as "convenience implementations, not guarantees"
- Semantic versioning: adding defaults is minor (backward-compatible
  for implementors, potentially breaking for users of both interfaces)

_Why they ask:_ Tests library design thinking, not just syntax
awareness.

_Likely follow-up:_ "How would you design an interface for a plugin
system that must evolve?"

_What separates good from great:_ The diamond collision scenario -
it is breaking for consumers of both interfaces even though only
one library changed.

---

**[STAFF] Q7 - System Design**
_Design an extensible plugin interface that must evolve across
multiple library versions without breaking plugin authors._

Core principle: **abstract = core contract; default = extensions**

```java
// v1.0: minimal contract
interface Plugin {
    void execute(Context ctx);  // must implement

    // v1.1 backward-compatible additions
    default void onStart(Context ctx) { /* no-op */ }

    default void onStop() { /* no-op */ }

    default int apiVersion() { return 1; }
}
```

> **Code walkthrough:** `execute()` is the only abstract method -
> the non-negotiable core contract. New lifecycle hooks
> (`onStart`, `onStop`) are defaults with no-op implementations.
> Plugins that care override them; others get safe no-ops. Adding
> new defaults to v1.x is backward-compatible. The `apiVersion()`
> default lets the framework detect which version of the API the
> plugin was compiled against.

For major version evolution, add a new interface that extends the
old one:

- `Plugin` (v1): original contract
- `Plugin2 extends Plugin` (v2): new required behaviors
- Framework handles both: `if (plugin instanceof Plugin2 p2) ...`

Rule: **new abstract methods go into new interfaces**, never into
existing ones. This is how `javax` -> `jakarta` API evolution works.

_Why they ask:_ Tests API evolution design thinking at staff level.

_Likely follow-up:_ "How does this relate to the open/closed
principle?"

_What separates good from great:_ The "new abstract methods go into
new interfaces" rule - this is the key insight that prevents
accidental breaking changes.

---

**[STAFF] Q8 - Production Reality**
_Describe a scenario where a default method caused a production issue._

Classic case: `Map.getOrDefault()` added in Java 8.

Pre-Java 8 pattern:

```java
Integer val = map.get(key);
if (val == null) val = defaultValue;
```

Java 8 refactor:

```java
Integer val = map.getOrDefault(key, defaultValue);
```

The issue: `ConcurrentHashMap.getOrDefault()` was overridden, but
the null-key semantics differ between `HashMap` and
`ConcurrentHashMap`. Teams that refactored from the null-check
pattern to `getOrDefault()` on `ConcurrentHashMap` under concurrent
load encountered `NullPointerException` in code that previously
was safe - because the default implementation assumes
`containsKey`/`get` semantics that `ConcurrentHashMap` handles
differently.

The lesson: default method implementations assume the same semantic
contracts as the abstract methods. Concurrent collections have
different null-key semantics. The `Map` default could not be written
to handle both correctly.

_Why they ask:_ Tests production experience with concurrent code
and API contracts.

_Likely follow-up:_ "Why does ConcurrentHashMap not support null
keys?"

_What separates good from great:_ Understanding that defaults are
"best effort" for the general case - performance-sensitive or
semantics-sensitive implementations must override.

---

**[JUNIOR] Q9 - Conceptual**
_Can an interface have both abstract methods and default methods?
What is the relationship between them?_

Yes. An interface can have any mix. The relationship:

- **Abstract**: defines WHAT - what the implementing class must provide
- **Default**: defines HOW - a provided implementation using the WHAT

Default methods should compose abstract methods. They derive their
meaning from the abstract contract:

```java
interface Sortable<T extends Comparable<T>> {
    List<T> getItems();  // abstract: what to sort

    // default: HOW to sort, using the abstract getItems()
    default List<T> sorted() {
        List<T> copy = new ArrayList<>(getItems());
        Collections.sort(copy);
        return copy;
    }
}
```

> **Code walkthrough:** `sorted()` calls `getItems()` - the abstract
> method that every implementor must define. The default provides
> the sorting algorithm for free, but it relies on the implementing
> class to provide the data source. This is the Template Method
> pattern: abstract = primitive operation, default = algorithm
> that uses it. A default method that never calls any abstract
> method is a design smell.

This is the Template Method pattern applied to interfaces.

_Why they ask:_ Tests depth of understanding beyond "interfaces can
now have method bodies."

_Likely follow-up:_ "What is the Template Method pattern?"

_What separates good from great:_ The Template Method connection
and the design smell - defaults that bypass abstract methods.

---

### ⚖️ Comparison Table

| Feature                 | abstract class            | interface + default                  |
| ----------------------- | ------------------------- | ------------------------------------ |
| Instance state (fields) | Yes                       | No                                   |
| Constructor             | Yes                       | No                                   |
| Multiple inheritance    | No (single)               | Yes                                  |
| Non-public methods      | Yes                       | No (Java 8); private (Java 9+)       |
| Default behavior        | Concrete methods          | `default` methods                    |
| Evolution cost          | Adding method = recompile | Adding default = backward-compatible |
| Diamond problem         | N/A                       | Resolved by rules                    |

**Deciding factor:** Need state or constructor -> abstract class.
Need multiple inheritance of behavior without state or need
backward-compatible evolution -> interface + default.

---

---

# Structured Concurrency and Scoped Values (Java 21+)

**TL;DR** - `StructuredTaskScope` ensures concurrent subtasks live
and die within a defined scope - no orphaned tasks. `ScopedValue`
replaces `ThreadLocal` with immutable, auto-inherited context for
virtual threads. Both are part of Project Loom, finalized in Java 24.

**Interview Weight:** medium - tested in senior/staff interviews on
virtual threads, concurrency design, and modern Java evolution.

---

### 🎯 Model Answer

**30 seconds:**

> Structured concurrency means a parent task owns its subtasks.
> When the scope exits, all subtasks are complete or cancelled. No
> subtask can outlive its parent. `StructuredTaskScope` implements
> this. `ScopedValue` replaces `ThreadLocal` for immutable, inherited
> context that works correctly with virtual threads.

**3 minutes (Senior):**

> Traditional `ExecutorService` creates orphaned tasks - if the
> parent method returns early due to an exception, the subtasks keep
> running unobserved with no one to cancel them.
>
> Structured concurrency (`StructuredTaskScope`) treats concurrent
> tasks like nested blocks: the scope is a try-with-resources block.
> `scope.fork()` starts subtasks. `scope.join()` waits. When the
> try block exits, all tasks are complete or cancelled. This mirrors
> structured programming's guarantee for control flow.
>
> `ShutdownOnFailure` and `ShutdownOnSuccess` are built-in policies:
> cancel all remaining subtasks when any fails (fan-in) or when the
> first succeeds (race to first result).
>
> `ScopedValue` fixes the `ThreadLocal` problem: ThreadLocal is
> mutable, not inherited across forked threads, and leaks if you
> forget `remove()`. ScopedValue is immutable within a scope and
> automatically inherited by all child tasks forked within that scope.

---

### 📘 Concept Explanation

**The Unstructured Concurrency Problem**

```java
// BAD: traditional ExecutorService - tasks can outlive scope
ExecutorService exec =
    Executors.newVirtualThreadPerTaskExecutor();
Future<String> user  = exec.submit(() -> fetchUser(userId));
Future<String> order = exec.submit(() -> fetchOrder(orderId));

// If user.get() throws, order task keeps running unobserved
String u = user.get();   // throws: order task leaks
String o = order.get();  // never reached
```

> **Code walkthrough:** `exec.submit()` starts two independent tasks.
> If `user.get()` throws, execution jumps to the catch block. The
> `order` future is never cancelled - its task runs in the background,
> consuming virtual threads, potentially accessing shared resources,
> with no owner. This is the structured concurrency problem: subtasks
> that outlive their logical scope. With thousands of requests per
> second and virtual threads, leaked tasks accumulate silently.

**StructuredTaskScope - ShutdownOnFailure**

```java
// GOOD: scope owns all forked tasks, failure cancels siblings
try (var scope =
        new StructuredTaskScope.ShutdownOnFailure()) {
    Subtask<String> user  = scope.fork(() -> fetchUser(id));
    Subtask<String> order = scope.fork(() -> fetchOrder(id));

    scope.join()           // wait for both to complete
         .throwIfFailed(); // re-throw first failure

    // Both succeeded - safe to call get()
    return new RequestData(user.get(), order.get());
}
// scope.close(): all tasks guaranteed done or cancelled
```

> **Code walkthrough:** `ShutdownOnFailure` cancels all remaining
> subtasks as soon as any one fails. `scope.join()` waits for
> completion. `.throwIfFailed()` re-throws the first exception if
> any task failed. When the try block exits (normally or via
> exception), all forked tasks are complete or cancelled. No task
> can outlive the scope. This is the structured concurrency guarantee.

**StructuredTaskScope - ShutdownOnSuccess**

```java
// Race to first success: cancel others when any succeeds
try (var scope =
        new StructuredTaskScope.ShutdownOnSuccess<String>()) {
    scope.fork(() -> queryPrimaryDB(id));
    scope.fork(() -> queryReplicaDB(id));
    scope.fork(() -> queryCacheDB(id));

    scope.join();
    // Fastest responder wins; others are cancelled
    return scope.result();  // throws if ALL three failed
}
```

> **Code walkthrough:** `ShutdownOnSuccess` is for fan-out with
> early termination: start multiple redundant requests and use the
> first result. The remaining subtasks are cancelled when any one
> succeeds. `scope.result()` returns the winning result or throws
> `ExecutionException` if all tasks failed. This pattern replaces
> `CompletableFuture.anyOf()` with explicit lifecycle management.

**ScopedValue vs ThreadLocal**

```java
// ThreadLocal: mutable, not inherited, manual cleanup
static final ThreadLocal<User> CURRENT_USER =
    new ThreadLocal<>();

void processRequest(User user) {
    CURRENT_USER.set(user);
    try {
        handleRequest();
    } finally {
        CURRENT_USER.remove();  // MUST clean up manually
    }
}
// Risk: if remove() is forgotten, next request on same
// thread sees stale user (thread pool reuse bug)
```

> **Code walkthrough:** `ThreadLocal.set()` stores a value per
> thread. In a thread pool, threads are reused. If `remove()` is
> not called (exception path, early return), the next request that
> runs on the same thread sees the previous request's user context.
> This is a silent security/correctness bug that is hard to reproduce.
> With virtual threads at scale, this class of bug becomes systemic.

```java
// ScopedValue: immutable, auto-inherited, auto-cleaned
static final ScopedValue<User> CURRENT_USER =
    ScopedValue.newInstance();

void processRequest(User user) {
    ScopedValue.where(CURRENT_USER, user)
               .run(() -> handleRequest());
    // Binding gone when run() exits - no cleanup needed
}

// Child tasks inherit the binding automatically
void handleRequest() {
    User u = CURRENT_USER.get();  // works in any child scope
    // fork tasks: they also see CURRENT_USER
}
```

> **Code walkthrough:** `ScopedValue.where()` binds the value for
> the duration of `run()`. When `run()` exits, the binding is gone
> automatically - no `remove()` needed. Child tasks forked inside
> `StructuredTaskScope` within the `run()` block inherit the same
> binding. The value cannot be mutated within the scope - immutability
> means no race conditions, no accidental cross-request contamination.

**ThreadLocal vs ScopedValue**

| Property           | ThreadLocal              | ScopedValue              |
| ------------------ | ------------------------ | ------------------------ |
| Mutability         | Mutable (`set`/`get`)    | Immutable within scope   |
| Inheritance        | Not inherited by forks   | Inherited by child tasks |
| Cleanup            | Manual `remove()`        | Automatic at scope end   |
| Thread reuse risk  | High (pool context leak) | None (scope-bounded)     |
| Virtual thread fit | Poor at scale            | Designed for it          |

---

### 💻 Code Example

```java
// BAD: CompletableFuture fan-in - error handling is complex
CompletableFuture<User> userFuture =
    CompletableFuture.supplyAsync(() -> fetchUser(id));
CompletableFuture<Order> orderFuture =
    CompletableFuture.supplyAsync(() -> fetchOrder(id));

// If userFuture fails, orderFuture keeps running
// Cancellation does NOT happen automatically
CompletableFuture<Result> combined = userFuture.thenCombine(
    orderFuture,
    (u, o) -> new Result(u, o)
).exceptionally(e -> {
    // Which task failed? Are both cancelled? Leaked?
    return Result.empty();
});
```

> **Code walkthrough:** `supplyAsync()` runs tasks on the common
> fork-join pool. If `userFuture` fails, `orderFuture` is not
> automatically cancelled - it continues running until it completes.
> The `exceptionally` handler does not cancel the other future.
> The programmer must add explicit cancellation logic in the error
> handler. Under load, leaked futures accumulate. The exception
> model is callback-based and non-linear - difficult to reason about.

```java
// GOOD: structured concurrency - automatic lifecycle
record RequestData(User user, Order order) {}

RequestData fetchAll(String id) throws Exception {
    try (var scope =
            new StructuredTaskScope.ShutdownOnFailure()) {
        Subtask<User>  user =
            scope.fork(() -> fetchUser(id));
        Subtask<Order> order =
            scope.fork(() -> fetchOrder(id));

        scope.join().throwIfFailed();

        return new RequestData(user.get(), order.get());
    }
    // Both cancelled on failure before exception propagates
    // Both complete before return on success
}
```

> **Code walkthrough:** Two subtasks run concurrently. If either
> fails, `ShutdownOnFailure` cancels the other immediately and
> `throwIfFailed()` re-throws the exception. Both `.get()` calls
> are only reached when both succeed - no null checks needed.
> The scope's try-with-resources ensures cleanup. The exception
> model is synchronous and linear. The entire concurrent operation
> fits in 10 lines with full lifecycle safety.

```java
// ScopedValue carrying trace context through virtual threads
static final ScopedValue<String> TRACE_ID =
    ScopedValue.newInstance();

void handleRequest(HttpRequest req) {
    String traceId = req.header("X-Trace-Id");

    ScopedValue.where(TRACE_ID, traceId).run(() -> {
        try (var scope =
                new StructuredTaskScope.ShutdownOnFailure()) {
            scope.fork(() -> {
                // Child task inherits TRACE_ID automatically
                log.info("DB: trace={}", TRACE_ID.get());
                return queryDatabase();
            });
            scope.fork(() -> {
                log.info("Cache: trace={}", TRACE_ID.get());
                return queryCache();
            });
            scope.join().throwIfFailed();
        }
    });
}
```

> **Code walkthrough:** `TRACE_ID` is bound once at the request
> boundary and inherited by all forked tasks automatically. No
> explicit parameter passing to each subtask. Child tasks call
> `TRACE_ID.get()` to access the same immutable trace ID. Immutability
> means no task can corrupt another's context. When `run()` exits,
> the binding disappears. This is the canonical pattern for
> request-scoped context in virtual thread architectures.

**How to test:** Test with virtual threads, mock delays, and
injected failures. Verify that a failure in one subtask cancels
others. Verify ScopedValue is accessible in all child tasks.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"Structured concurrency means concurrent tasks are organized in a
parent-child hierarchy. The parent waits for all children before
returning. `StructuredTaskScope` implements this - you fork tasks,
call join(), and when the scope closes, all tasks are done or
cancelled. `ScopedValue` is an immutable thread-local alternative
that works correctly with virtual threads."

**Senior / Staff:**
"The structured concurrency insight is that unstructured concurrency
allows tasks to outlive their logical scope - creating ghost tasks
that consume resources and may corrupt state with no observer.

The analogy: `goto` was replaced by structured control flow (if,
while, for) because it made programs predictable. Ad-hoc thread
creation is replaced by structured task scopes for the same reason.

ScopedValue is the correct mental model for request context in
virtual thread architectures: bind trace ID, user context, and
database connection at the request boundary; all virtual threads
forked from that request inherit it immutably. No mutation means
no race conditions. No cleanup means no leak.

The virtual thread + structured concurrency + scoped value trinity
replaces three anti-patterns: raw thread pools, ThreadLocal leaks,
and CompletableFuture callback hell."

---

### ⚠️ Common Misconceptions

| #   | Misconception                                               | Reality                                                                                                                                              | Danger                               |
| --- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| 1   | "StructuredTaskScope is ExecutorService with auto-shutdown" | Different programming model: scope owns tasks, not executor. Tasks cannot outlive their scope.                                                       | Wrong lifetime mental model          |
| 2   | "ScopedValue is just a read-only ThreadLocal"               | ScopedValue is lexically scoped AND automatically inherited by child tasks. ThreadLocal is neither.                                                  | Missing the inheritance benefit      |
| 3   | "Virtual threads make StructuredTaskScope unnecessary"      | Virtual threads are the mechanism (lightweight threads). Structured concurrency is the discipline (task lifecycle). Complementary, not alternatives. | Conflating mechanism with discipline |
| 4   | "ShutdownOnFailure waits for ALL tasks to fail"             | It cancels remaining tasks on the FIRST failure. One failure triggers immediate cancellation of all siblings.                                        | Misunderstanding failure propagation |
| 5   | "StructuredTaskScope is stable in Java 21"                  | Preview in Java 21 (JEP 453). Finalized in Java 24 (JEP 505). Using preview API requires `--enable-preview`.                                         | Using unstable API in production     |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Subtask result read before join()**

_Symptom:_ `IllegalStateException` calling `subtask.get()` before
join completes.

_Root Cause:_ `Subtask.get()` is only valid after `scope.join()`
returns. The subtask may still be running before `join()`.

_Fix:_

```java
// BAD: get() before join()
Subtask<String> task = scope.fork(() -> work());
String result = task.get();  // IllegalStateException: not done

// GOOD: always join first
scope.join().throwIfFailed();
String result = task.get();  // safe: join() guarantees complete
```

> **Code walkthrough:** `scope.join()` is the synchronization point.
> Before it returns, subtasks are in an indeterminate state. After
> `join().throwIfFailed()`, you know all tasks completed successfully.
> The pattern `join().throwIfFailed()` then `.get()` is the canonical
> safe sequence. The `throwIfFailed()` call ensures only the success
> path reaches `.get()` - failed task state would have already thrown.

**FM2 - Not using try-with-resources**

_Symptom:_ Tasks run to completion even after the caller returns
or throws. Resource leaks.

_Root Cause:_ `StructuredTaskScope` implements `AutoCloseable`.
Not using try-with-resources means `close()` is never called.

_Diagnosis:_ Thread dumps showing task threads with no live parent
scope. JFR profiler showing leaked virtual thread tasks.

_Fix:_ Always declare `StructuredTaskScope` in a try-with-resources
block. The compiler gives no warning if you do not - it is a
programmer discipline enforced by code review.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                                                                          |
| ---------------- | ------------------------------------------------------------------------------------------------------------- |
| 5 minutes        | Scope guarantee + ShutdownOnFailure pattern                                                                   |
| 15 minutes       | Add ShutdownOnSuccess + ScopedValue vs ThreadLocal                                                            |
| 30 minutes       | Add virtual thread relationship + JDK version status                                                          |
| Under pressure   | "Tasks can't outlive scope; failure cancels siblings; ScopedValue = immutable inherited ThreadLocal for Loom" |

**[JUNIOR] Q1 - Conceptual**
_What guarantee does StructuredTaskScope provide that ExecutorService
does not?_

Lifetime guarantee: no forked task can outlive the scope.

With `ExecutorService.submit()`, there is no automatic relationship
between the caller and the submitted task. If the caller throws, the
task keeps running.

With `StructuredTaskScope`, when the try-with-resources block exits:

- All forked tasks are complete, OR
- All forked tasks are cancelled

No orphaned tasks. No resource leaks from forgotten futures. No
silent background work after the logical scope ends.

_Why they ask:_ Tests whether you understand the programming model,
not just the API.

_Likely follow-up:_ "How does this relate to virtual threads?"

_What separates good from great:_ Framing as a "lifetime guarantee"
not just "automatic shutdown" - it is about ownership and predictability.

---

**[JUNIOR] Q2 - Conceptual**
_What is the difference between ScopedValue and ThreadLocal?_

| Property    | ThreadLocal          | ScopedValue              |
| ----------- | -------------------- | ------------------------ |
| Mutability  | Mutable (set/remove) | Immutable in scope       |
| Inheritance | Not inherited        | Inherited by child tasks |
| Cleanup     | Manual `remove()`    | Automatic at scope end   |

The practical differences:

1. `ThreadLocal` is mutable. Any code can `set()` a new value,
   including subtasks, creating race conditions.
   `ScopedValue` is bound once and cannot change within the scope.

2. `ThreadLocal` is not inherited by forked threads.
   `ScopedValue` is automatically available in child tasks.

3. Forgetting `ThreadLocal.remove()` in a thread pool leaks the
   value to the next request. `ScopedValue` has no cleanup.

_Why they ask:_ Directly tests Loom knowledge depth.

_Likely follow-up:_ "When would ThreadLocal still be the right choice?"

_What separates good from great:_ The thread pool leak risk is the
practical reason ThreadLocal is dangerous at scale with virtual threads.

---

**[MID] Q3 - Hands-On**
_When would you use ShutdownOnSuccess instead of ShutdownOnFailure?_

`ShutdownOnSuccess` when: you want the first correct result and
do not care which source provides it.

Classic use cases:

- **Redundant services:** query primary DB and replica; use the
  first to respond (latency hedging)
- **Circuit breaker fan-out:** try multiple endpoints; stop on
  first success
- **Timeout with fallback:** race the real query against a cached
  fallback

```java
try (var scope =
        new StructuredTaskScope.ShutdownOnSuccess<Response>()) {
    scope.fork(() -> callPrimary());
    scope.fork(() -> callFallback());
    scope.join();
    return scope.result();  // first success wins
}
```

> **Code walkthrough:** Both tasks start concurrently. `ShutdownOnSuccess`
> cancels the slower task when either completes successfully.
> `scope.result()` returns the winning result or throws
> `ExecutionException` if both failed. The cancelled task receives
> a thread interrupt signal and stops. This pattern hedges latency
> without the manual cancellation logic that CompletableFuture would
> require.

`ShutdownOnFailure` when: all subtasks must succeed (fan-in, parallel
fetch where every result is needed).

_Why they ask:_ Tests understanding of the two canonical patterns.

_Likely follow-up:_ "What happens if all tasks fail with
ShutdownOnSuccess?"

_What separates good from great:_ The "latency hedging" terminology
and a concrete production example.

---

**[MID] Q4 - Trade-off**
_What are the trade-offs of structured concurrency vs
CompletableFuture?_

**Structured concurrency advantages:**

- Synchronous exception model (no callbacks)
- Automatic task cancellation on failure
- Clear task ownership (scope owns tasks)
- Better observability (thread dumps show task hierarchy)
- Natural fit for virtual threads

**CompletableFuture advantages:**

- Available since Java 8 (stable, widely used)
- Richer composition API (`thenApply`, `thenCombine`, `anyOf`)
- Works without virtual threads
- Better for complex async pipelines with many transformation steps

**Use structured concurrency when:**

- Java 21+ with virtual threads
- Fan-in or fan-out with failure handling
- Request-scoped context propagation is needed

**Use CompletableFuture when:**

- Pre-Java 21 codebase
- Complex multi-step async pipelines
- Library code that must be Java 8 compatible

_Why they ask:_ Tests whether you can reason about trade-offs rather
than just promoting new features.

_Likely follow-up:_ "Can you mix CompletableFuture and
StructuredTaskScope?"

_What separates good from great:_ Acknowledging CompletableFuture's
maturity and that structured concurrency is not universally better.

---

**[SENIOR] Q5 - Architecture**
_How does structured concurrency relate to virtual threads?_

They are complementary parts of Project Loom:

- **Virtual threads** solve the thread-per-request scalability
  problem. Millions of cheap virtual threads instead of thousands
  of expensive platform threads. Virtual threads are the mechanism.

- **Structured concurrency** solves the task lifecycle problem.
  Concurrent subtasks organized in parent-child hierarchy with
  automatic lifetime management. Structured concurrency is the
  discipline.

Without virtual threads, structured concurrency would create too
many platform threads. Without structured concurrency, virtual
threads still allow orphaned tasks and ThreadLocal leaks.

Together: each request gets a virtual thread. Within the request,
`StructuredTaskScope` organizes sub-requests. `ScopedValue` carries
request context (trace ID, user, transaction) to all child tasks.

This is the "Loom stack": virtual threads + structured tasks +
scoped values.

_Why they ask:_ Tests conceptual depth of the Loom initiative.

_Likely follow-up:_ "What is Project Loom trying to replace?"

_What separates good from great:_ "Mechanism vs discipline" framing

- virtual threads are the runtime mechanism, structured concurrency
  is the programming discipline built on top.

---

**[SENIOR] Q6 - Production Reality**
_How would you migrate a service from ThreadLocal-based request
context to ScopedValue?_

Current pattern (common in Spring with MDC):

```java
// MDC uses ThreadLocal internally
MDC.put("traceId", req.header("X-Trace-Id"));
try {
    handleRequest();
} finally {
    MDC.clear();  // manual cleanup, forgettable
}
```

> **Code walkthrough:** `MDC.put()` sets a ThreadLocal per thread.
> In a virtual thread-per-request model, each request has its own
> virtual thread so ThreadLocal works. But under concurrent subtasks
> (forked virtual threads), child tasks do not inherit MDC entries.
> Trace IDs are missing from child task logs. `MDC.clear()` must
> be called in finally - forgetting it in any code path leaks trace
> context to the next request on the same thread.

Migration strategy:

1. Define `ScopedValue` for each context element
2. Bind at the request boundary (filter/interceptor)
3. Update logging infrastructure to read the ScopedValue
4. Forked tasks inherit context automatically

Challenge: Logback and Log4j2 use `MDC` (ThreadLocal-based) for
log correlation. Full migration requires framework-level changes.
Logback 1.5+ added initial ScopedValue support.

_Why they ask:_ Tests practical migration knowledge.

_Likely follow-up:_ "What if you cannot upgrade the logging framework?"

_What separates good from great:_ Knowing the Logback/Log4j2
integration gap is the practical production blocker.

---

**[STAFF] Q7 - System Design**
_Design a timeout-with-fallback pattern using StructuredTaskScope._

Requirement: primary operation with a timeout; on timeout or failure,
use a fallback result.

```java
static <T> T withFallback(
        Callable<T> primary,
        T fallback,
        Duration timeout) throws InterruptedException {
    try (var scope =
            new StructuredTaskScope.ShutdownOnSuccess<T>()) {
        scope.fork(primary);
        scope.fork(() -> {
            Thread.sleep(timeout);
            return fallback;  // fallback is a "success"
        });
        scope.join();
        // e -> fallback: if both fail, return fallback
        return scope.result(e -> fallback);
    }
}
```

> **Code walkthrough:** The timeout task sleeps for `timeout` duration
> then returns the fallback value - this is treated as a "success"
> by `ShutdownOnSuccess`. If the primary completes first, it wins
> and the timeout task is cancelled. If the timeout elapses first,
> the fallback wins and the primary is cancelled. `ShutdownOnSuccess`
> is the right policy here because the fallback IS a valid result,
> not a failure. Using `ShutdownOnFailure` would require more complex
> exception-based signaling.

Usage:

```java
User user = withFallback(
    () -> fetchFromDB(id),
    User.anonymous(),
    Duration.ofMillis(200)
);
```

_Why they ask:_ Tests ability to compose structured concurrency
primitives into production patterns.

_Likely follow-up:_ "How would you add retry logic?"

_What separates good from great:_ Using `ShutdownOnSuccess` - the
insight is that the fallback is a success, not a failure. This is
the key design decision.

---

**[STAFF] Q8 - Architecture**
_What is the current JDK status and production readiness of
structured concurrency?_

JDK history:

| JDK | JEP | Status           |
| --- | --- | ---------------- |
| 19  | 428 | Incubator module |
| 21  | 453 | Second preview   |
| 22  | 462 | Third preview    |
| 24  | 505 | **Finalized**    |

Production guidance:

- **Java 24+:** finalized API, production-safe
- **Java 21-23:** preview - requires `--enable-preview`; API may change
- **Java 8-20:** not available

Spring Framework: Spring 6.2+ has structured concurrency integration.

Monitoring: JFR (Java Flight Recorder) and thread dumps show the
task hierarchy naturally. Debugging concurrent operations becomes
easier when you can see parent scope and all child tasks as a group.

The adoption decision: teams on Java 21 LTS must evaluate whether
the preview API stability and migration path to Java 24 justifies
adoption. For new services targeting Java 24+, `StructuredTaskScope`
is the preferred concurrency model for fan-in/fan-out operations.

_Why they ask:_ Tests up-to-date knowledge of the JDK roadmap.

_Likely follow-up:_ "Is Java 21 or Java 24 the LTS for your team?"

_What separates good from great:_ Knowing the exact JEP numbers,
the Java 24 finalization, and the Spring 6.2+ integration.

---

**[MID] Q9 - Conceptual**
_What happens when a forked task throws an exception inside
StructuredTaskScope?_

The behavior depends on the scope policy:

With `ShutdownOnFailure`:

1. The exception is stored internally in the scope
2. Remaining forked tasks receive cancellation signals
3. `scope.join()` returns normally (does NOT throw)
4. `scope.throwIfFailed()` re-throws as `ExecutionException`

```java
try (var scope =
        new StructuredTaskScope.ShutdownOnFailure()) {
    scope.fork(() -> { throw new IOException("DB down"); });
    scope.fork(() -> fetchOrder(id));

    scope.join();          // returns normally
    scope.throwIfFailed(); // throws ExecutionException(IOException)
} catch (ExecutionException e) {
    Throwable cause = e.getCause();  // original IOException
    log.error("Task failed: {}", cause.getMessage());
}
```

> **Code walkthrough:** The exception flow has two stages: `join()`
> is the synchronization point (returns normally, exceptions stored).
> `throwIfFailed()` is the rethrow point. This separation allows you
> to inspect the scope state before deciding whether to throw.
> `e.getCause()` unwraps the original exception from the
> `ExecutionException` wrapper. `join()` itself throws only
> `InterruptedException` if the waiting thread is interrupted -
> a different failure mode entirely.

_Why they ask:_ Tests the exact exception model, which is non-obvious.

_Likely follow-up:_ "What is the difference between InterruptedException
from join() and ExecutionException from throwIfFailed()?"

_What separates good from great:_ The two-stage model: `join()`
stores the exception, `throwIfFailed()` rethrows it.

---

### ⚖️ Comparison Table

| API                      | Task ownership      | Failure handling       | Context propagation    | Stable since |
| ------------------------ | ------------------- | ---------------------- | ---------------------- | ------------ |
| Thread / ExecutorService | None                | Manual future check    | ThreadLocal (leaks)    | All Java     |
| CompletableFuture        | None                | exceptionally()        | Manual passing         | Java 8       |
| StructuredTaskScope      | Strong (scope owns) | Automatic cancellation | ScopedValue (inherits) | Java 24      |

**Deciding factor:** Use `StructuredTaskScope` with virtual threads
for new Java 24+ code where fan-in, fan-out, or request-scoped
context propagation is needed. Use CompletableFuture for pre-Java 21
code or complex pipeline transformations with many steps.
