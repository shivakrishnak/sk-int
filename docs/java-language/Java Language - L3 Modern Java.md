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
