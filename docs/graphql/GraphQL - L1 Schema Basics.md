---
layout: default
title: "GraphQL - L1 Schema Basics"
parent: "GraphQL"
nav_order: 2
permalink: /graphql/l1-schema-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 4 | [GraphQL Schema Definition Language](#graphql-schema-definition-language) | ★☆☆ |
| 5 | [Types: Scalar, Object, Enum, Interface, and Union](#types-scalar-object-enum-interface-and-union) | ★☆☆ |
| 6 | [Queries, Mutations, and Subscriptions](#queries-mutations-and-subscriptions) | ★☆☆ |

---

# GraphQL Schema Definition Language

---

### 🎯 Model Answer

**30 seconds:**
> SDL (Schema Definition Language) is the syntax for defining a GraphQL schema. It describes
> all types, fields, relationships, and operations that the API exposes. SDL is declarative
> (you describe what the API looks like, not how it works), language-agnostic (the same SDL
> works for any server language), and the formal contract between client and server.
> Key syntax: `type Name { field: Type }`, `type Query { ... }`, `type Mutation { ... }`.

**3 minutes (Senior):**
> SDL is the formal grammar for GraphQL schemas, defined in the GraphQL specification.
> It serves three roles: (1) documentation - the schema IS the docs; every field can
> have a description string; tooling (GraphiQL) renders descriptions. (2) Validation
> contract - the GraphQL execution engine validates every incoming query against the schema
> before executing resolvers; invalid field names, wrong argument types, and type mismatches
> are rejected at validation time, not resolver execution. (3) Code generation input -
> graphql-codegen, Relay Compiler, and Apollo Client code generation all consume the SDL
> to produce type-safe client code. SDL syntax: object types (`type`), scalar types
> (built-in: `Int`, `Float`, `String`, `Boolean`, `ID`; custom: `scalar Date`), enum
> types (`enum Direction { NORTH SOUTH }`), interface types, union types, input types
> (for mutation arguments), and directives (`@deprecated`, custom directives). Non-null
> modifier (`!`) and list modifier (`[]`) combine to express cardinality: `[Post!]!`
> means "non-null list of non-null Posts."

**Blank Mind Recovery:**

**(1) Restate:** "SDL: the syntax for defining GraphQL schemas. Type definitions: `type User { name: String! }`. Entry points: `type Query { user(id: ID!): User }`. Non-null: `!`. Lists: `[Post!]!`. Language-agnostic - same syntax whether your server is Node.js, Python, or Go. The schema is the API contract."

---

### 📘 Concept Explanation

**SDL Syntax Reference:**

```graphql
# Object type - the most common type
type User {
  id: ID!              # Built-in ID scalar; non-null
  name: String!        # Built-in String; non-null
  email: String!       # Non-null String
  age: Int             # Nullable Int (age is optional)
  createdAt: String!   # Could be a DateTime scalar
  posts: [Post!]!      # Non-null list of non-null Posts
}

# Root operation types
type Query {
  # Arguments: named, typed, optionally default
  user(id: ID!): User           # Returns nullable User
  users(limit: Int = 10): [User!]! # With default
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  deleteUser(id: ID!): Boolean!
}

type Subscription {
  userCreated: User!
}

# Input type - used for mutation arguments
input CreateUserInput {
  name: String!
  email: String!
}

# Custom scalar (date handling)
scalar DateTime

# Enum type
enum UserRole {
  ADMIN
  USER
  GUEST
}

# Updated User with enum and custom scalar
type User {
  id: ID!
  name: String!
  email: String!
  role: UserRole!
  createdAt: DateTime!
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the full SDL syntax reference covering object types, root types (Query/Mutation/Subscription), input types, custom scalars, and enums with real field examples. (2) KEY MECHANISM: the `!` non-null modifier changes the resolver contract - a non-null field resolver that returns `null` causes a null-propagation error that can bubble up to the parent type, potentially making the entire parent field null; `!` is a strong commitment. (3) WHY IT MATTERS: every SDL type and field generates a corresponding entry in the introspection schema that clients and tools consume; the SDL is not just source code - it is the live runtime schema that the GraphQL execution engine uses for validation. (4) WHAT BREAKS: `input` types cannot be used as output types (and vice versa); a mutation argument must use `input CreateUserInput` not `type CreateUserInput`; the spec separates input and output types explicitly. (5) TAKEAWAY: model the schema from the client's perspective, not the database schema; the database has `user_accounts` and `post_entries`; the GraphQL schema has `User` and `Post`; the schema is the API domain model, not a database reflection.

**Non-Null and List Cardinality Rules:**

```text
CARDINALITY MATRIX:

  String     = nullable string (can be null)
  String!    = non-null string (will never be null)
  [String]   = nullable list of nullable strings
               (list can be null; items can be null)
  [String!]  = nullable list of non-null strings
               (list can be null; items won't be null)
  [String]!  = non-null list of nullable strings
               (list won't be null; items can be null)
  [String!]! = non-null list of non-null strings
               (list won't be null; items won't be null)

  MOST COMMON:
  [Post!]!   = use for collections (the list exists,
               all items are valid objects)
  Post       = use for single-object relationships
               that may not exist (nullable)
  Post!      = use when the object always exists
               (parent always has this field)

  NULL PROPAGATION:
  If Post! resolver returns null:
  -> error bubbles up to parent
  -> parent becomes null (if nullable parent)
  -> or error propagates to root query
  Design fields nullable when resolver might return null
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the cardinality matrix showing all combinations of list notation `[]` and non-null `!` modifiers and the most common usage patterns. (2) HOW TO READ IT: read from left to right for each row; `[String!]!` means the outer `!` (after `]`) makes the list itself non-null, and the inner `!` (after `String`) makes each list element non-null. (3) KEY RELATIONSHIP: null propagation is the critical non-null consequence; marking a field non-null is a promise to clients that the field will never be null; if the resolver breaks that promise and returns null, GraphQL does not silently coerce it - it replaces the field with an error and propagates nullness up the tree. (4) EDGE CASE: null propagation can cause an entire query to return `null` if a non-null field deep in the tree has a resolver error; design top-level fields as nullable unless guaranteed to always have data. (5) INSIGHT: a senior engineer defaults to nullable fields in the schema unless there is a strict guarantee the field will always resolve; the cost of a nullable field is a `?.` in the client; the cost of a non-null field that returns null in production is a null-propagated query response that discards all sibling data.

---

### 💻 Code Example

```graphql
# BAD: Schema that mirrors database tables directly
# (exposes implementation, leaks internal naming)

type user_account {
  user_id: Int!          # Database column name exposed
  full_name: String!
  email_address: String!
  created_timestamp: String!  # Not typed properly
  is_active: Int!        # Boolean stored as Int in DB
  fk_department_id: Int! # Foreign key exposed directly
}

type Query {
  get_user_by_id(user_id: Int!): user_account
  get_all_active_users: [user_account]
}
# Problems:
# 1. snake_case violates GraphQL convention (camelCase)
# 2. is_active is Int; should be Boolean
# 3. user_id is Int; should be ID
# 4. fk_department_id is a DB FK; clients want
#    user.department { name } not user.fk_department_id
# 5. Changing DB schema breaks client queries
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the database-mirroring anti-pattern where the GraphQL schema directly reflects database table/column names and types, creating tight coupling between the API and the database implementation. (2) KEY MECHANISM: GraphQL convention is camelCase for fields and PascalCase for types; `snake_case` violates the convention that all GraphQL clients and tools expect; it does not cause a runtime error but signals poor schema design. (3) WHY IT MATTERS: when the database column `full_name` is renamed to `display_name`, every client using the `full_name` field must update; with a properly designed schema, the GraphQL field name is independent of the database column name. (4) WHAT BREAKS: `fk_department_id` exposes a foreign key to clients; clients want to query `user.department.name` (traversing the relationship) not manually join on `fk_department_id`; the schema should express relationships, not foreign keys. (5) TAKEAWAY: design GraphQL schemas for clients, not databases; map database columns to GraphQL fields explicitly in resolvers; use resolver logic to bridge naming and type differences; the client API is stable, the database schema can evolve independently.

```graphql
# GOOD: Schema designed for clients (not database)

"""
A registered user of the system.
"""
type User {
  "Unique user identifier"
  id: ID!
  "Display name shown in UI"
  name: String!
  "Primary email address"
  email: String!
  "Whether the account is active"
  isActive: Boolean!
  "When the account was created"
  createdAt: DateTime!
  "The user's department (null if unassigned)"
  department: Department
  "Posts authored by this user"
  posts(
    limit: Int = 10
    offset: Int = 0
  ): [Post!]!
}

type Department {
  id: ID!
  name: String!
  members: [User!]!
}

type Query {
  "Get a user by ID. Returns null if not found."
  user(id: ID!): User
  "List all active users, paginated"
  users(
    active: Boolean = true
    limit: Int = 20
    offset: Int = 0
  ): [User!]!
}

scalar DateTime

# Resolvers handle name/type mapping:
# user.isActive -> DB: is_active (Int) -> Boolean
# user.createdAt -> DB: created_timestamp -> DateTime
# user.department -> DB: fk_department_id -> JOIN query
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a client-focused GraphQL schema with: description strings on types and fields, camelCase field names, proper type mapping (Boolean/ID/DateTime), relationship traversal (`department: Department` not `departmentId: Int`), and paginated list fields. (2) KEY MECHANISM: description strings (triple-quoted `"""..."""` or single-quoted `"..."`) appear in introspection; GraphiQL and Apollo Studio render them as documentation; they are the primary documentation mechanism. (3) WHY IT MATTERS: the `department: Department` field returns the full `Department` type; clients can query `user { department { name members { name } } }`; the foreign key join is handled in the resolver, invisible to the client. (4) WHAT BREAKS: adding `limit` and `offset` to `posts` as field arguments requires all resolvers to handle pagination; omitting default values for pagination arguments means all callers must provide them; defaults (`limit: Int = 10`) make the API ergonomic. (5) TAKEAWAY: always use description strings on public-facing schema types and fields; they appear in GraphiQL and Apollo Studio as documentation for every developer using the API; a schema without descriptions is a schema without documentation.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> SDL (Schema Definition Language) is the syntax for defining a GraphQL schema using
> `type` declarations. Object types have named fields with types: `type User { name: String! }`.
> The `!` makes a field non-null (guaranteed to return a value). Lists use `[]`: `[Post!]!`
> means a non-null list of non-null Posts. The special types `Query`, `Mutation`, and
> `Subscription` define what operations clients can perform. Custom scalars (like `DateTime`)
> can be added. The schema is the complete description of what data the API can serve.

---

**Senior / Staff (5+ years):**
> SDL is the language-agnostic schema format defined in the GraphQL spec. Production concerns:
> (1) Null propagation - non-null fields that resolve to null cause errors to bubble upward;
> design fields nullable unless there is a strict guarantee they will never be null. (2)
> Descriptions as documentation - triple-quoted descriptions are rendered by all tooling; a
> schema without descriptions is a schema without docs. (3) Input vs output types - input
> types (for mutation arguments) and output types (for query results) cannot be mixed; the
> spec enforces this. (4) Custom scalars - `DateTime`, `JSON`, `URL` must have custom
> serialization/deserialization logic; the scalar definition in SDL is just a declaration;
> the resolver logic handles serialization. (5) Schema-first development - write the SDL
> before implementing resolvers; the SDL is the contract that frontend and backend agree on;
> this enables parallel development.

---

### ⚠️ Common Misconceptions

**Misconception: "The `!` in GraphQL means the field is required in queries."**

The `!` modifies the response type, not the query requirement. `name: String!` means the
server guarantees `name` will not be null in responses. It does NOT mean clients must
include `name` in every query. A client can write `query { user(id: "1") { email } }` and
omit `name` entirely - the server returns only `email`. The `!` is about the server's
null guarantee for the field, not about which fields clients must request. Input type
arguments also use `!`: `createUser(input: CreateUserInput!)` means the `input` argument
is required (cannot be omitted from the mutation call). These are two different uses of
`!` in SDL, but both mean "non-null" - the argument cannot be null, and the return value
cannot be null.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Null propagation from non-null field causing entire query to return null.**

Symptom: a query returns `{ "data": null, "errors": [...] }` for an unrelated error in
a deeply nested field. The entire query result is lost because of one failing resolver.

Root cause: a non-null field resolver returned null; GraphQL propagated the null upward
through the parent chain until it reached a nullable field; if no nullable ancestor exists,
the entire query root becomes null.

```graphql
# Schema that causes wide-area null propagation
type Query {
  currentUser: User!    # Non-null - dangerous!
}

type User {
  id: ID!
  profile: Profile!    # Non-null - dangerous!
}

type Profile {
  bio: String!         # Non-null - dangerous!
  # bio resolver throws an exception
  # -> bio becomes null (but it's String!)
  # -> profile becomes null (bio is non-null inside Profile)
  # -> user becomes null (profile is non-null)
  # -> query returns { "data": null }
  # -> ENTIRE QUERY FAILS due to one field resolver error
}

# Fix: make fields nullable unless guaranteed
type Query {
  currentUser: User     # Nullable - error isolated here
}
type User {
  id: ID!
  profile: Profile      # Nullable - error isolated
}
type Profile {
  bio: String           # Nullable - bio can be null
}
# Now bio resolver error -> bio: null
# profile still returns { bio: null }
# user still returns { id: "1", profile: {...} }
# Query returns partial data instead of total failure
```

> **Code walkthrough:** (1) WHAT IT SHOWS: null propagation in action - a non-null chain from `Query.currentUser!` through `User.profile!` through `Profile.bio!` causes a single failing resolver to null out the entire query result. (2) KEY MECHANISM: GraphQL's null propagation rule: when a non-null field resolver returns null (or throws), GraphQL sets the field to `null`; since it is non-null, it propagates the null to the parent field; if the parent is also non-null, it propagates further up; if all ancestors are non-null, the entire query result becomes `{ "data": null }`. (3) WHY IT MATTERS: a bio resolver failure on one user's profile field causes the entire user query to return null data; the user's page goes completely blank instead of showing partial data with a graceful error. (4) WHAT BREAKS: the common assumption "non-null means the field is always available" ignores the possibility of transient resolver errors (database timeouts, service unavailability); non-null + occasional failure = occasional total query failure. (5) TAKEAWAY: use non-null only at the boundary of absolute guarantees (ID fields, system-generated timestamps); for user-provided or conditionally-available data, use nullable fields; nullable fields isolate errors to their own field without affecting siblings or parents.

---

### ⚖️ Comparison Table

| SDL Element | Syntax | Purpose | Notes |
|---|---|---|---|
| Object type | `type User { ... }` | Define data shapes | Most common element |
| Query type | `type Query { ... }` | Read operations | Entry point for reads |
| Mutation type | `type Mutation { ... }` | Write operations | Entry point for writes |
| Input type | `input CreateInput { ... }` | Mutation arguments | Cannot be used as output |
| Scalar | `scalar DateTime` | Custom primitive types | Needs serialization code |
| Enum | `enum Status { ACTIVE }` | Fixed value sets | Type-safe string constants |
| Interface | `interface Node { id: ID! }` | Shared field contracts | Types must implement all fields |
| Union | `union Result = A \| B` | Polymorphic returns | No shared fields |
| Non-null | `String!` | Null guarantee | Propagates errors if broken |
| List | `[Post!]!` | Collections | Inner/outer nullability independent |

---

### 🏛️ System Design

*(Omit: L1 keyword; system design patterns covered in L5 Architecture entry.)*

---

### 📊 Diagram

```text
SDL SYNTAX MAP:

  schema                        (optional, usually omitted)
  {
    query: Query
    mutation: Mutation
    subscription: Subscription
  }

  type Query {                  <- Root query type
    user(id: ID!): User         <- Field with argument
    posts: [Post!]!             <- List field
  }

  type User {                   <- Object type
    id: ID!                     <- Non-null built-in scalar
    name: String!               <- Non-null String
    email: String               <- Nullable String
    posts: [Post!]!             <- Relationship field
  }

  type Post {                   <- Another object type
    id: ID!
    title: String!
    author: User!               <- Bidirectional relationship
    tags: [String!]             <- List of scalars
  }

  enum Role { ADMIN USER }      <- Enum type
  scalar DateTime               <- Custom scalar
  input CreatePostInput { ... } <- Input type for mutations
  interface Node { id: ID! }    <- Interface type

  RELATIONSHIP: User.posts and Post.author
  create a bidirectional graph in SDL
  Resolvers handle the actual DB joins
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a complete SDL syntax map showing all major SDL constructs - schema block, root types (Query), object types (User/Post), enums, scalars, input types, and interfaces - with annotations explaining each element's purpose. (2) HOW TO READ IT: the schema block at the top is optional (GraphQL convention auto-discovers `Query`, `Mutation`, `Subscription` as root types); the `type Query` is the entry point for all reads; all other types are reachable from Query through field traversal. (3) KEY RELATIONSHIP: `User.posts` and `Post.author` create a bidirectional relationship in the schema; this is a graph, not a tree; GraphQL clients can traverse in both directions; resolvers handle the underlying database joins. (4) EDGE CASE: circular type references (`User.posts` -> `Post.author` -> `User.posts`) are valid in SDL; they do not cause infinite loops unless a client constructs an infinitely deep query; depth limiting (L2 Performance) prevents infinite query traversal. (5) INSIGHT: a senior engineer recognizes that the SDL is a type system, not a data model; the same SDL can be backed by a SQL database, MongoDB, a REST API, or an in-memory cache; the SDL abstracts the data source.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | SDL syntax, type system |
| Application | 2 | schema design, null handling |
| Trade-off | 2 | nullable vs non-null, SDL design choices |
| Scenario | 1 | schema change diagnosis |

---

**[JUNIOR] Q1 (Definition): What is the Schema Definition Language (SDL) and what does it contain?**

SDL is the text format for defining a GraphQL schema. It is standardized in the GraphQL
specification; every GraphQL implementation (JavaScript, Python, Java, Go) uses the same
SDL syntax. The schema is both the server's implementation contract and the client's
API reference.

SDL contains:

1. Object types: define data shapes with named, typed fields.
```graphql
type Product {
  id: ID!
  name: String!
  price: Float!
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a minimal object type definition with three fields demonstrating the basic SDL syntax. (2) KEY MECHANISM: `ID!` is a special scalar that serializes as a string; it is semantically distinct from `String!` (GraphQL tooling treats ID fields as entity identifiers for cache normalization). (3) WHY IT MATTERS: `Float` for price can cause floating-point rounding issues (0.1 + 0.2 != 0.3); production schemas often use a custom `Money` scalar that serializes as an integer (cents) to avoid floating-point problems. (4) WHAT BREAKS: using `Float` for monetary values causes rounding errors in JavaScript clients; `1.99 + 2.99 = 4.9800000000000004`. (5) TAKEAWAY: use `Int` (cents) or a custom `Money` scalar for monetary amounts; never `Float`.

2. Query type: root entry point for all read operations.
3. Mutation type: root entry point for all write operations.
4. Input types: typed argument objects for mutations.
5. Enum types: fixed sets of values.
6. Scalar types: primitive types (built-in: `Int`, `Float`, `String`, `Boolean`, `ID`; custom: `DateTime`).
7. Interface types: shared field contracts that multiple types implement.
8. Union types: polymorphic fields that can return one of several types.
9. Directive declarations: `@deprecated`, custom directives.

*What separates good from great:* The SDL as a design artifact. At companies with mature
GraphQL practices (GitHub, Shopify), the SDL is designed in collaborative sessions before
any resolver code is written. Frontend and backend engineers agree on the schema; this
is the "schema-first" development model. The schema defines the contract; backend and
frontend then develop in parallel (frontend mocks the GraphQL server with the schema;
backend implements resolvers to satisfy the schema). Schema changes go through a review
process similar to API versioning proposals. The SDL file is in version control and
treated as a first-class deliverable.

---

**[JUNIOR] Q2 (Application): What is the difference between nullable and non-null fields in SDL? When would you use each?**

Nullable field: can return `null` (default). `name: String` - the server might return
null for this field.
Non-null field: guaranteed not to return null. `name: String!` - the server promises
this field will always have a value.

Use non-null (`!`) when:
- The field is a unique identifier: `id: ID!` - every entity has an ID.
- The field is always populated: `createdAt: DateTime!` - every record has a creation time.
- System-generated values that always exist.

Use nullable (no `!`) when:
- The field is optional: `bio: String` - not every user writes a bio.
- The field might fail: any field fetched from a remote service (might timeout).
- The field depends on permissions: `salary: Float` - nullable if not all users have access.
- You are uncertain: default to nullable if you are not sure; easier to add `!` later
  than to remove it (removing `!` is a non-breaking change; adding `!` can be breaking
  if resolvers sometimes return null).

Rule of thumb: use `!` only when you can make a strong guarantee that the field will
never be null at any point in the object's lifecycle, under any error condition.

*What separates good from great:* The error isolation argument for nullable. When a non-null
field resolver throws an exception, GraphQL's error propagation can null out the entire
object (or query). Nullable fields isolate errors: a nullable bio field resolver error
returns `{ bio: null }` instead of nulling the entire user object. For fields that access
external services or have error conditions, nullable is safer. The tradeoff: nullable
requires clients to handle `null` values (with `?.` optional chaining). Non-null fields
simplify client code but require server guarantees. The senior engineer's heuristic: non-null
for IDs and system timestamps; nullable for user-provided content and external data.

---

**[JUNIOR] Q3 (Definition): What is a custom scalar in GraphQL and why would you add one?**

A custom scalar is a named primitive type with custom serialization behavior. The five
built-in scalars (Int, Float, String, Boolean, ID) cover basic data types; custom scalars
cover domain-specific types.

Common custom scalars and why to add them:
- `DateTime`: the built-in `String` does not enforce ISO 8601 format; a `DateTime`
  scalar validates and parses date strings consistently.
- `URL`: validates that a string value is a valid URL format.
- `Email`: validates email format.
- `JSON`: for dynamic or schema-less data (configuration objects, metadata).
- `PositiveInt`: validates that an integer is positive.

SDL declaration:
```graphql
scalar DateTime
scalar URL
scalar JSON

type Event {
  id: ID!
  name: String!
  startTime: DateTime!    # Not just String
  website: URL            # Validated URL
  metadata: JSON          # Dynamic data
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: declaring custom scalars in SDL and using them in a type definition to provide semantic meaning beyond what the built-in scalars offer. (2) KEY MECHANISM: the SDL `scalar DateTime` is just a declaration; the actual serialization (converting a Date object to an ISO string), parsing (converting an ISO string to a Date object), and validation (rejecting non-ISO strings) logic must be implemented in the server code; the `graphql-scalars` library provides production-ready implementations for 30+ common scalars. (3) WHY IT MATTERS: using `String` for dates allows clients to pass `"yesterday"` as a date argument and receive a runtime resolver error; a `DateTime` scalar validates the format at the GraphQL layer before the resolver executes, providing a clearer error message and consistent date handling. (4) WHAT BREAKS: custom scalar serialization errors cause the field to be null and an error in the response `errors` array; if the resolver returns a value the scalar serializer cannot handle, the error is surfaced at serialization time. (5) TAKEAWAY: use `graphql-scalars` library for common custom scalars; do not reinvent `DateTime`, `URL`, `Email`, or `JSON` serialization; the library handles edge cases (timezones, relative dates, URL encoding) correctly.

*What separates good from great:* The `JSON` scalar trade-off. The `JSON` custom scalar
accepts any valid JSON value as a field value. This seems convenient for dynamic data but
defeats GraphQL's type system for that field: clients lose autocomplete, type checking,
and documentation for JSON fields. A field typed as `JSON` is effectively an escape hatch
from GraphQL's type system. The better approach: if the structure of the JSON is known,
define it as a proper GraphQL type with named fields; if the structure is truly dynamic
and unknown (user-defined configuration), `JSON` is acceptable with the understanding
that it bypasses type safety. "Use `JSON` when the structure is unknowable at schema
design time; otherwise, always define proper types."

---

**[SENIOR] Q4 (Trade-off): How would you decide whether to use an interface or a union type in a GraphQL schema?**

Interface: defines a set of fields that multiple types must implement. Use when the
polymorphic types share common fields that clients always query.

```graphql
interface Node {
  id: ID!
}
interface Timestamped {
  createdAt: DateTime!
  updatedAt: DateTime!
}

type User implements Node & Timestamped {
  id: ID!
  name: String!
  createdAt: DateTime!
  updatedAt: DateTime!
}
type Post implements Node & Timestamped {
  id: ID!
  title: String!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the `Node` and `Timestamped` interfaces that multiple types implement, allowing generic queries against the interface. (2) KEY MECHANISM: a field typed as `Node` can return any type implementing the interface; clients can query `node(id: "User:1") { id }` and get the ID regardless of whether the node is a User or Post; type-specific fields require inline fragments. (3) WHY IT MATTERS: interfaces enable generic cache operations (Apollo Client uses the `Node` interface's `id` for cache normalization); the Relay spec requires all types to implement `Node`. (4) WHAT BREAKS: adding a required field to an interface is a breaking change for all implementing types; use `@deprecated` to signal interface evolution and add new optional fields. (5) TAKEAWAY: implement the `Node` interface on every entity type; it enables global unique IDs, generic cache operations, and Relay compatibility; the cost is one extra `id: ID!` field constraint on every type (which should already be present).

Union: used when the polymorphic types share NO common fields. Use for search results or feed items where types are completely distinct.

```graphql
union SearchResult = User | Post | Product | Order

type Query {
  search(query: String!): [SearchResult!]!
}
# Clients use inline fragments for type-specific fields:
# { search(query: "Alice") {
#     ... on User { name email }
#     ... on Post { title }
#     ... on Product { price }
#   }
# }
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a union type for heterogeneous search results where the polymorphic types have no shared fields. (2) KEY MECHANISM: unions require no shared field contract; clients must use inline fragments for ALL field access since the union itself has no fields; the `__typename` meta-field is the only field available without inline fragments. (3) WHY IT MATTERS: a feed or search result naturally contains heterogeneous content types; union types model this polymorphism correctly; the alternative (separate fields `users`, `posts`, `products` in the search result) requires multiple round-trips or complex client merging logic. (4) WHAT BREAKS: unions require `__resolveType` in the resolver to determine the concrete type; without it, GraphQL cannot route to the correct fragment; a missing `__resolveType` causes "abstract type must resolve to an object type at runtime" errors. (5) TAKEAWAY: use union for feed/search result types where content is heterogeneous; use interface when polymorphic types share fields that clients always query; when in doubt, union is safer (no shared field contract to maintain).

Decision: interface if types share fields clients need without inline fragments. Union if types are completely different. Hybrid: interface for shared fields + implement interface on types that also form a union.

*What separates good from great:* The `__resolveType` implementation detail. Every interface
and union type requires a `__resolveType` (or `isTypeOf`) function that determines which
concrete type a runtime object represents. This function is called for EVERY object of
that type. Performance-critical implementations cache the type determination or include
a `__typename` field in database records to avoid runtime type-checking logic. At Facebook
scale, `__resolveType` for feed items is called millions of times per minute; its
implementation is optimized to a simple property lookup, not a database query.

---

**[JUNIOR] Q5 (Application): What is an input type and why is it separate from regular object types?**

An input type defines the shape of arguments passed to mutations (and queries). It is
structurally similar to an object type but exists separately in the SDL with the
`input` keyword.

Reason for separation: object types can contain resolvers; input types cannot. Object type
fields can return other object types (creating a graph); input types can only reference
scalar types and other input types (no circular references via object types). This prevents
using a query result type as a mutation argument directly, which would create design
ambiguity (should the input type have resolvers? should it be cached?).

Example:
```graphql
# CANNOT do this:
mutation CreatePost(post: Post!) { ... }
# 'Post' is an output type; cannot be used as input

# MUST do this:
input CreatePostInput {
  title: String!
  content: String!
  authorId: ID!
}
mutation CreatePost(input: CreatePostInput!): Post!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the correct pattern of using an `input` type for mutation arguments and why the `Post` output type cannot be used directly. (2) KEY MECHANISM: the GraphQL spec explicitly prohibits using output types as mutation input arguments; `input` types are simpler (only scalars + other input types, no resolvers, no interfaces); this simplicity makes them safe for validation and serialization. (3) WHY IT MATTERS: the `CreatePostInput` pattern is the standard GraphQL mutation design; wrapping all mutation arguments in a single `input` object is a convention that enables mutation batching and makes the mutation signature stable over time (add new optional fields to the input type without changing the mutation signature). (4) WHAT BREAKS: adding a required field to `CreatePostInput` is a breaking change for all callers; add optional fields (with defaults or nullable) to the input type to stay backward compatible. (5) TAKEAWAY: wrap all mutation arguments in a single input type (`mutation createPost(input: CreatePostInput!)`); this is the GraphQL mutation design convention; it keeps mutations extensible without signature changes.

*What separates good from great:* The cursor-based pagination input pattern. Complex
queries with filtering, sorting, and pagination use deeply nested input types. A
`PostsConnection` query might accept `filter: PostFilterInput, orderBy: PostOrderByInput,
pagination: PaginationInput`. Each input type handles one concern. This pattern is from
the Relay Connection specification and is the standard for production GraphQL APIs with
complex filtering needs. Learning the Relay Connection spec input pattern is more valuable
than generic input type usage because it is the pattern you will encounter in production
GraphQL schemas at every major company.

---

**[SENIOR] Q6 (Trade-off): What are the trade-offs of using the `JSON` scalar type vs defining explicit types?**

`JSON` scalar (accepts any valid JSON):
- Pros: flexible; no schema updates needed when the structure changes; quick to implement
  for dynamic configuration data.
- Cons: no type safety for clients; no autocomplete; no documentation (schema just says
  "JSON"); graphql-codegen generates `any` for JSON fields; schema change detection does
  not work for the JSON content.

Explicit types:
- Pros: full type safety; autocomplete; documentation; graphql-codegen generates precise
  types; schema changes are detectable and breaking changes are caught.
- Cons: schema updates required when the structure changes; higher upfront design cost.

Decision framework:
Use `JSON` when: the structure is genuinely unknowable at schema design time (user-defined
configuration, plugin metadata, dynamic form data). Use explicit types when: the structure
is known and consistent (even if complex). The practical dividing line: if you can write
a TypeScript interface for it, write it as a GraphQL type.

*What separates good from great:* The "JSON leakage" pattern in real codebases. Teams
use `JSON` for convenience ("we'll type it later") and it never gets typed. Years later,
the codebase has 20 JSON fields that nobody understands. Migrations require reading source
code because the schema documents nothing. The "type it explicitly" discipline prevents
this: force the team to design the schema structure upfront, which also identifies design
ambiguities early. GraphQL's type system is a forcing function for API design quality;
using `JSON` bypasses the forcing function.

---

**[JUNIOR] Q7 (Application): How do you add documentation to a GraphQL schema?**

Documentation in SDL uses description strings placed before type/field definitions.
Two formats: single-line (`"..."`) and multi-line (`"""..."""`).

```graphql
"""
A registered user account in the system.
Updated when user profile changes.
"""
type User {
  "Unique identifier; stable across renames"
  id: ID!

  "Display name shown in all UI contexts"
  name: String!

  """
  Primary email address.
  Used for authentication and notifications.
  Not shown publicly unless user enables it.
  """
  email: String!

  "Account creation timestamp (ISO 8601)"
  createdAt: DateTime!

  "Whether account has completed onboarding"
  isOnboarded: Boolean!

  role: UserRole!
}

enum UserRole {
  "Full system access"
  ADMIN
  "Standard user access"
  USER
  "Read-only access for partner integrations"
  READ_ONLY
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: SDL documentation using single-line and multi-line description strings on types, fields, and enum values, with meaningful descriptions that go beyond restating the field name. (2) KEY MECHANISM: descriptions appear in introspection results (`__type.description`, `__field.description`); GraphiQL, Apollo Studio, and graphql-codegen all render descriptions; the schema IS the documentation that auto-updates when the schema changes. (3) WHY IT MATTERS: `email: String!` with no description could mean many things (login email, notification email, display email); `"Primary email address. Used for authentication and notifications."` removes ambiguity; descriptions prevent integration bugs from unclear field semantics. (4) WHAT BREAKS: descriptions on `input` type fields are less commonly added; they are equally important for mutation documentation; developers who call mutations need to understand each input field's purpose. (5) TAKEAWAY: write descriptions as you write the SDL, not afterward; a schema without descriptions is a schema without documentation; treat SDL description strings with the same care as code comments.

*What separates good from great:* The `@deprecated` reason as change documentation. When
deprecating a field, the `reason` argument in `@deprecated(reason: "...")` should explain
WHAT to use instead and WHY the field is deprecated. "Deprecated" is insufficient.
`@deprecated(reason: "Use emailAddress. email returns unverified addresses; emailAddress returns only verified addresses.")` is excellent: it explains the semantic change and the migration path. This deprecation reason appears in introspection and is rendered by all tooling; it is the communication channel to all current and future API consumers.

---

# Types: Scalar, Object, Enum, Interface, and Union

---

### 🎯 Model Answer

**30 seconds:**
> GraphQL has six categories of types: (1) Scalar - primitive leaf values (Int, Float,
> String, Boolean, ID, plus custom scalars). (2) Object - named structured types with
> fields (`type User { name: String! }`). (3) Enum - fixed-value sets (`enum Status { ACTIVE INACTIVE }`).
> (4) Interface - field contracts that object types implement (`interface Node { id: ID! }`).
> (5) Union - polymorphic returns with no shared fields (`union Result = User | Post`).
> (6) Input - typed mutation arguments (`input CreateInput { ... }`). Know which to use when
> and you can design any GraphQL schema.

**3 minutes (Senior):**
> The type system is the foundation of GraphQL's correctness guarantees. Object types form
> the graph; scalars are the leaf values. Interface and union types provide polymorphism;
> their primary difference: interfaces require shared fields (clients can query without
> inline fragments), unions do not (all fields require inline fragments). Enum types provide
> type-safe string constants; they serialize as strings over the wire but are validated
> against the enum values; an invalid enum value is rejected at query validation. Input
> types are the mutation-argument equivalent of object types; the separation prevents
> using output types as inputs (which would mix resolver semantics with serialization
> semantics). Custom scalars extend the type system for domain types; they require
> server-side serialization/parsing logic. Understanding the type system fully includes
> the coercion rules (how GraphQL coerces Int to Float, how ID is serialized) and
> non-null + list cardinality modifiers.

**Blank Mind Recovery:**

**(1) Restate:** "Six type categories: Scalar (leaf values), Object (structured types),
Enum (fixed values), Interface (shared field contracts), Union (polymorphism, no shared
fields), Input (mutation arguments). Object types form the graph; scalars are leaves.
Interfaces = shared fields, unions = no shared fields. Input = output but for arguments."

---

### 📘 Concept Explanation

**Type System Hierarchy:**

```text
GRAPHQL TYPE CATEGORIES:

  LEAF TYPES (cannot be traversed further):
  +---------+------------------------------------------+
  | Scalar  | Built-in: Int, Float, String, Boolean, ID|
  |         | Custom: DateTime, URL, Email, JSON        |
  | Enum    | enum Status { ACTIVE INACTIVE DELETED }   |
  +---------+------------------------------------------+

  COMPOSITE TYPES (have fields, can be traversed):
  +-----------+----------------------------------------+
  | Object    | type User { id: ID!, name: String! }   |
  |           | type Query { user(id: ID!): User }      |
  | Interface | interface Node { id: ID! }              |
  |           | - User implements Node                  |
  |           | - Post implements Node                  |
  | Union     | union SearchResult = User | Post        |
  |           | - No shared fields required             |
  +-----------+----------------------------------------+

  INPUT TYPES (arguments only, not returned):
  +-----------+----------------------------------------+
  | Input     | input CreateUserInput {                 |
  |           |   name: String!                         |
  |           |   email: String!                        |
  |           | }                                       |
  +-----------+----------------------------------------+

  TRAVERSAL RULES:
  Query root
    -> Object type fields (traverse)
    -> Scalar fields (leaf; stop)
    -> Enum fields (leaf; stop)
    -> Interface fields (traverse; use inline fragments)
    -> Union fields (inline fragments only)
  
  Cannot traverse a Scalar or Enum
  (no sub-fields to select)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the GraphQL type system hierarchy divided into leaf types (scalars, enums), composite types (objects, interfaces, unions), and input types, with traversal rules. (2) HOW TO READ IT: leaf types are the terminal nodes of any query traversal; composite types are intermediate nodes that can contain sub-fields; input types are not part of the traversal graph (they are only in mutation/query arguments). (3) KEY RELATIONSHIP: a query must terminate at leaf types (scalars or enums); you cannot write a query that returns an `Object` type field without selecting sub-fields; the GraphQL validation engine enforces this. (4) EDGE CASE: interface and union types require inline fragments to access type-specific fields; requesting a field typed as `interface Node` without an inline fragment only allows accessing the interface's own fields (`id`); without inline fragments, all other fields are inaccessible. (5) INSIGHT: a senior engineer notes that the type system is the source of GraphQL's correctness guarantees; the type checker validates queries at parse time, before any resolver runs; invalid queries are rejected immediately with descriptive errors, not runtime failures.

---

### 💻 Code Example

```graphql
# BAD: Using String for enum values
# (no type safety; any string accepted)

type Order {
  id: ID!
  status: String!      # "pending", "shipped", "delivered"?
  priority: String!    # "high", "medium", "low"? "urgent"?
}

type Mutation {
  updateOrderStatus(
    id: ID!
    status: String!    # Client can pass "SHIPED" (typo)
                       # No validation at schema level
    priority: String!  # "High" vs "high" inconsistency?
  ): Order!
}
# Problems:
# - GraphQL accepts any string; typos not caught
# - Clients don't know valid values from schema alone
# - GraphiQL autocomplete shows nothing helpful
# - graphql-codegen generates `string` type (too broad)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `String` for fields that have a fixed set of valid values, which bypasses GraphQL's type system and allows arbitrary invalid strings to pass validation. (2) KEY MECHANISM: GraphQL string validation only checks that the value is a valid string; it cannot validate that the string is one of "pending", "shipped", or "delivered"; a client passing "SHIPED" (typo) receives no error at the GraphQL layer. (3) WHY IT MATTERS: without enum validation, invalid status values propagate to the database; a status of "SHIPED" is stored and displayed in the UI; the bug is discovered by users, not by the system. (4) WHAT BREAKS: the lack of schema documentation for valid values means clients must read API documentation (or source code) to know what values to use; GraphiQL autocomplete shows only `String` for the field, not the valid values. (5) TAKEAWAY: any field with a finite set of valid values should use an enum type; the schema documents the valid values, GraphQL validates them at request time, and graphql-codegen generates specific TypeScript union types.

```graphql
# GOOD: Using enums and interfaces correctly

enum OrderStatus {
  PENDING
  PROCESSING
  SHIPPED
  DELIVERED
  CANCELLED
}

enum OrderPriority {
  LOW
  MEDIUM
  HIGH
  URGENT
}

# Interface for shared fields across entity types
interface Node {
  "Global unique identifier for this entity"
  id: ID!
}

# Interface for auditable entities
interface Auditable {
  createdAt: DateTime!
  updatedAt: DateTime!
  createdBy: User!
}

type Order implements Node & Auditable {
  id: ID!
  status: OrderStatus!     # Type-safe; validated
  priority: OrderPriority! # Type-safe; validated
  createdAt: DateTime!
  updatedAt: DateTime!
  createdBy: User!
  items: [OrderItem!]!
  total: Float!
}

type Query {
  # Interface field - returns any Node type
  node(id: ID!): Node

  # Filter by enum - type-safe filtering
  orders(
    status: OrderStatus
    priority: OrderPriority
  ): [Order!]!
}

type Mutation {
  updateOrderStatus(
    id: ID!
    status: OrderStatus!  # Only valid enum values accepted
  ): Order!
}
# Schema validates: OrderStatus.SHIPED -> ERROR (invalid)
# graphql-codegen generates:
# type OrderStatus = 'PENDING' | 'PROCESSING' |
#   'SHIPPED' | 'DELIVERED' | 'CANCELLED'
```

> **Code walkthrough:** (1) WHAT IT SHOWS: replacing `String` fields with enum types for type-safe validation, and implementing the `Node` + `Auditable` interfaces for reusable field contracts. (2) KEY MECHANISM: `enum OrderStatus { PENDING PROCESSING SHIPPED DELIVERED CANCELLED }` causes GraphQL to validate any `OrderStatus` argument against the five valid values; passing `"SHIPED"` (typo) generates a validation error before the resolver runs. (3) WHY IT MATTERS: enum validation catches typos and invalid values at the GraphQL layer; graphql-codegen generates a TypeScript union type `'PENDING' | 'PROCESSING' | ...` which TypeScript uses for compile-time validation on the client side. (4) WHAT BREAKS: changing an enum value name (e.g., `SHIPPED` -> `DISPATCHED`) is a breaking change for all clients; existing queries and mutations using `SHIPPED` fail validation after the change; use `@deprecated` on the old value and add the new value simultaneously, then migrate clients. (5) TAKEAWAY: convert all `String` fields with fixed valid values to enum types; the schema documents the valid values, GraphQL validates them, and TypeScript enforces them on the client side - triple validation prevents invalid state from entering the system.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> GraphQL has six type categories: Scalars (primitive values: Int, Float, String, Boolean,
> ID), Object types (the main building blocks with named fields), Enums (fixed sets of
> valid values like `enum Status { ACTIVE INACTIVE }`), Interfaces (field contracts that
> multiple types implement), Unions (when a field can return one of several unrelated
> types), and Input types (for mutation arguments). Most of the time you work with Object
> types, Scalars, and Enums. Use Interface when multiple types share the same fields. Use
> Union for search results or feeds with mixed content types.

---

**Senior / Staff (5+ years):**
> The type system architecture drives API correctness. Key decisions: (1) Enum vs String
> - always use enum for finite value sets; the type system validates values at the GraphQL
> layer, before resolvers run. (2) Interface vs Union - interface when polymorphic types
> share fields clients query without inline fragments; union when types have no common
> fields (search results, feed items). (3) Non-null placement - non-null on output fields
> is a promise; null propagation can null out ancestors; be conservative with non-null
> on fields that might be absent or fail. (4) Custom scalars - `DateTime`, `URL`, `Email`
> provide domain-level validation; use `graphql-scalars` library. (5) Input types - always
> wrap mutation arguments in a single input object; enables mutation extensibility. The
> type system is the first line of defense; it eliminates a class of runtime bugs by
> rejecting invalid queries at parse time.

---

### ⚠️ Common Misconceptions

**Misconception: "Interface types and Union types are interchangeable."**

Interface and union types serve different scenarios and are NOT interchangeable. Interface:
types share common fields and the interface field guarantees those fields are available
without inline fragments. Example: `type Query { node(id: ID!): Node }` - the `id` field
is accessible on the `Node` return value without any inline fragment because all implementing
types must have `id`. Union: types share NO common fields; accessing any field requires
an inline fragment. Example: `type Query { search(q: String!): [SearchResult!]! }` where
`SearchResult = User | Post` - every field access requires `... on User { name }` or
`... on Post { title }`. Using interface when types have no shared fields forces implementing
types to add required fields that have no meaning for them. Using union when types do share
fields means clients must always use inline fragments even for the shared fields.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Missing `__resolveType` for interface or union causing runtime errors.**

Symptom: query returns `"Abstract type must resolve to an Object type at runtime for field
Query.search with value {}, received undefined"` error in the response.
Root cause: the resolver for a union or interface type field is missing the `__resolveType`
function that determines which concrete type each returned object is.

```javascript
// BAD: Missing __resolveType for SearchResult union
const resolvers = {
  Query: {
    search: async (_, { query }) => {
      // Returns mixed array of users and posts
      return db.search(query);
      // Problem: GraphQL cannot determine if each item
      // is a User or a Post without __resolveType
    }
  }
  // MISSING: SearchResult: { __resolveType }
};

// GOOD: Adding __resolveType to resolve the union
const resolvers = {
  Query: {
    search: async (_, { query }) => {
      return db.search(query);
    }
  },
  SearchResult: {
    __resolveType(obj) {
      // Determine type from object structure
      if (obj.username !== undefined) return 'User';
      if (obj.title !== undefined) return 'Post';
      // Fallback: include __typename in DB records
      return obj.__typename || null;
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the missing `__resolveType` failure mode and fix - `__resolveType` is required for every union and interface type to tell the GraphQL runtime which concrete type a returned object is. (2) KEY MECHANISM: when a resolver returns an object for a union/interface field, GraphQL calls `__resolveType(obj)` to determine which concrete type to use for validation and field resolution; without it, GraphQL cannot match the object to its type and throws the "must resolve to an Object type" error. (3) WHY IT MATTERS: this error surfaces in production when polymorphic data is first returned; it causes the entire union/interface field to return null with an error, potentially breaking search or feed functionality. (4) WHAT BREAKS: relying on structural discrimination (`obj.username !== undefined`) is fragile if data shapes overlap; the most reliable approach is to include `__typename` in database records or use a type discriminator field. (5) TAKEAWAY: always implement `__resolveType` for every union and interface when defining the schema; this is a mandatory step that is easy to forget because it is not part of the SDL definition itself.

---

### ⚖️ Comparison Table

| Type | Syntax | Can Have Fields? | Can Be Input? | Can Be Returned? |
|---|---|---|---|---|
| Scalar | `scalar DateTime` | No (leaf) | Yes | Yes |
| Object | `type User { ... }` | Yes | No | Yes |
| Enum | `enum Role { ADMIN }` | No (leaf) | Yes | Yes |
| Interface | `interface Node { id: ID! }` | Yes (abstract) | No | Yes |
| Union | `union Result = A \| B` | No (polymorphic) | No | Yes |
| Input | `input CreateInput { ... }` | Yes | Yes | No |

---

### 🏛️ System Design

*(Omit: L1 keyword; type system architectural patterns covered in L5 entries.)*

---

### 📊 Diagram

```text
TYPE HIERARCHY WITH RELATIONSHIPS:

  Node (Interface)
  +--------------+
  | id: ID!      |
  +--------------+
       ^   ^   ^
       |   |   |
  User Post Product   <- All implement Node
  (Object types)
       |
       v
  String, ID,         <- Scalar leaves
  DateTime, Boolean

  SearchResult (Union)
  = User | Post | Product
  (no shared fields)

  Input types (arguments):
  CreateUserInput ---> User (Mutation returns User)
  UpdatePostInput ---> Post (Mutation returns Post)
  
  QUERY TRAVERSAL:
  Query
  -> user(id: ID!): User  [Object - traverse]
     -> name: String!     [Scalar - leaf, stop]
     -> posts: [Post!]!   [Object - traverse]
        -> title: String! [Scalar - leaf, stop]
  -> node(id: ID!): Node  [Interface - traverse]
     -> id: ID!           [Scalar - no fragment needed]
     -> ... on User { name } [Inline fragment for more]
  -> search: [SearchResult!]! [Union]
     -> ... on User { name }  [Inline fragment required]
     -> ... on Post { title } [Inline fragment required]
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the complete type relationship diagram showing interface implementation (`Node` implemented by `User`, `Post`, `Product`), union membership (`SearchResult`), scalar leaf types, input type relationships, and query traversal rules. (2) HOW TO READ IT: the interface hierarchy (Node at top) shows that all three entity types implement `Node`; the union shows that `SearchResult` is any of those three types; the traversal section shows when inline fragments are required (union, type-specific interface fields) vs when they are optional (interface's own fields like `id`). (3) KEY RELATIONSHIP: all entity types implementing `Node` means they all have a stable `id: ID!` field; this enables Apollo Client's normalized cache to use the global ID for cache key generation. (4) EDGE CASE: an object type can implement multiple interfaces; `User implements Node & Auditable` inherits the field requirements of both; the type must provide all fields from all implemented interfaces. (5) INSIGHT: designing the type hierarchy with `Node` as a universal interface is a best practice from the Relay specification; it enables global entity lookups (`query { node(id: "User:1") { ... on User { name } } }`), is required for Relay client compatibility, and provides a consistent cache normalization strategy for Apollo Client.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | scalar types, enum vs string |
| Application | 2 | type selection, union vs interface |
| Trade-off | 2 | nullable considerations, type design |
| Scenario | 1 | resolveType failure |

---

**[JUNIOR] Q1 (Definition): What are the built-in scalar types in GraphQL and when would you use each?**

GraphQL has five built-in scalar types:

1. `String`: UTF-8 character sequence. Use for: text fields (name, description, email,
   content). Default choice for most text data.

2. `Boolean`: true or false. Use for: flags, status fields (`isActive`, `isVerified`,
   `hasChildren`).

3. `Int`: 32-bit signed integer (-2,147,483,648 to 2,147,483,647). Use for: counts,
   ages, pagination offsets, IDs when the ID is an integer (though `ID` is preferred).
   Do NOT use for monetary values (use custom `Money` scalar) or for values that might
   exceed 2 billion.

4. `Float`: double-precision floating point. Use for: coordinates (latitude/longitude),
   scientific values, percentages. Do NOT use for monetary values (floating-point precision
   issues).

5. `ID`: serialized as a string; semantically represents a unique identifier. Use for:
   all entity IDs; GraphQL and client libraries (Apollo Client) treat `ID` fields as
   cache keys; prefer `ID` over `Int` even when IDs are integers.

When the built-in scalars are insufficient: add custom scalars from `graphql-scalars`
library: `DateTime` (ISO 8601 date strings), `URL` (valid URL format), `Email` (valid
email format), `PositiveInt` (validated positive integers), `JSON` (arbitrary JSON).

*What separates good from great:* The `ID` vs `Int` distinction for entity identifiers.
Using `Int` for IDs couples the schema to the current ID strategy (auto-increment integers).
When migrating to UUID-based IDs or distributed IDs (Snowflake), changing `Int` IDs to
`String` IDs is a breaking schema change. Using `ID` from the start: `ID` serializes as
a string; an integer ID `42` becomes `"42"` in GraphQL; a UUID ID `"uuid-..."` remains
a string. Clients code to `ID` type; the underlying format can change without a schema
change. "Always use `ID` for entity identifiers" is a best practice that protects against
future ID strategy migrations.

---

**[JUNIOR] Q2 (Trade-off): When should you define a custom scalar type vs using a built-in scalar?**

Define a custom scalar when: (1) the built-in scalar does not enforce the format or
semantics you need, and (2) incorrect values would cause bugs in production.

Practical decision matrix:

| Situation | Use | Reason |
|---|---|---|
| Date stored as ISO string | `DateTime` custom | Format validation + parsing |
| URL stored in DB | `URL` custom | Format validation |
| Email address | `Email` custom | Format validation |
| HTML content | `String` built-in | String is sufficient |
| UUID entity ID | `ID` built-in | ID covers string identifiers |
| Integer 1-100 | `Int` built-in | Range check in resolver is fine |
| Monetary amount | Custom `Money` | Precision: store as cents (Int) |
| Lat/lng coordinate | `Float` built-in | Float is appropriate |
| Arbitrary config | `JSON` custom | Only if truly dynamic structure |

The rule: create a custom scalar when the built-in scalar accepts values that would
cause bugs (a `String` that is supposed to be an email accepting `"not-an-email"`).

*What separates good from great:* The custom scalar implementation depth. Declaring
`scalar DateTime` in SDL is just a declaration; the implementation requires:
(1) `serialize(value)` - converts the internal value (JavaScript Date object) to the
wire format (ISO string); (2) `parseValue(value)` - parses an input variable value
from the client (ISO string) to the internal format (Date object); (3) `parseLiteral(ast)`
- parses a literal value inline in a query (`createdAfter: "2024-01-01"`) to the internal
format. Missing any of these causes serialization errors. The `graphql-scalars` library
implements all three for 30+ common scalars; always use it over manual implementation.

---

**[SENIOR] Q3 (Application): How would you model a content feed that returns posts, videos, and ads?**

A heterogeneous feed is the canonical union type use case. The types (Post, Video, Ad)
have different fields and no meaningful shared fields for clients. Use union:

```graphql
union FeedItem = Post | Video | Ad

type Post {
  id: ID!
  content: String!
  author: User!
  likeCount: Int!
  createdAt: DateTime!
}

type Video {
  id: ID!
  thumbnailUrl: URL!
  duration: Int!    # seconds
  videoUrl: URL!
  creator: User!
  viewCount: Int!
}

type Ad {
  id: ID!
  imageUrl: URL!
  targetUrl: URL!
  sponsor: String!
  impressionId: ID!  # For ad tracking
}

type Query {
  feed(
    userId: ID!
    limit: Int = 20
    cursor: String
  ): FeedConnection!
}

type FeedConnection {
  edges: [FeedEdge!]!
  pageInfo: PageInfo!
}

type FeedEdge {
  node: FeedItem!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  endCursor: String
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: modeling a polymorphic content feed using the GraphQL union type with Relay Connection pagination, which is the production pattern for infinite scroll feeds. (2) KEY MECHANISM: `union FeedItem = Post | Video | Ad` allows each feed item to be one of three types; clients use inline fragments to access type-specific fields; `FeedConnection` uses the Relay Connection pagination spec with `edges` (items with cursor) and `pageInfo` (pagination state). (3) WHY IT MATTERS: the Relay Connection pattern is the standard for cursor-based pagination in production GraphQL APIs; it works with infinite scroll, load-more patterns, and Apollo Client's `fetchMore` API out of the box. (4) WHAT BREAKS: using `offset` pagination for feeds with frequent inserts/deletes causes items to skip or duplicate when the offset shifts; cursor-based pagination is stable under concurrent writes. (5) TAKEAWAY: use the Relay Connection pagination pattern (FeedConnection, FeedEdge, PageInfo) for all paginated lists that might be large or have concurrent writes; it is the GraphQL community standard and works with all major client libraries.

*What separates good from great:* The `impressionId` on the Ad type. Ad impression tracking
requires knowing WHICH ad request resulted in an impression; server-side, each ad returned
in a feed response gets a unique `impressionId` generated at response time. When the client
renders the ad and fires an impression event, it sends the `impressionId` to the tracking
service. Without `impressionId`, ad tracking would require client-side UUID generation
(less reliable) or ad content hashing (impractical). This pattern - including operation-
specific tracking IDs in feed responses - is a real production detail that separates
experienced GraphQL schema designers from beginners.

---

**[JUNIOR] Q4 (Definition): What is an enum type and why is it preferable to using strings for fixed-value fields?**

An enum type defines a set of valid named values that a field can have. It is preferable
to strings for four reasons:

1. Validation: GraphQL validates enum values at query parse time; `status: PENDING` where
   `PENDING` is not a valid enum value returns an error immediately; a typo in a string
   passes validation silently.

2. Documentation: the schema lists all valid values; GraphiQL and Apollo Studio autocomplete
   show the valid enum values when a user types in a query.

3. Type safety: graphql-codegen generates a TypeScript union type for enum values;
   TypeScript enforces valid values at compile time on the client.

4. Introspection: tooling can discover valid enum values via introspection and generate
   dropdowns, documentation, and migration tools.

Example impact: a mobile developer calls `updateStatus(id: "1", status: "Shipped")` (capital S).
With `String` type: the mutation executes; the resolver stores "Shipped" in the database;
inconsistent data (some records "shipped", some "Shipped"). With `OrderStatus` enum:
the GraphQL engine rejects "Shipped" immediately ("Value 'Shipped' does not exist in
'OrderStatus' enum"); the inconsistency never reaches the database.

*What separates good from great:* Enum serialization in different languages. GraphQL
enum values are uppercase by convention (`PENDING`, `SHIPPED`). When the server uses
lowercase or camelCase internally (database values, programming language constants),
the GraphQL layer needs to map between the schema enum values and the internal values.
In Apollo Server, this is done via enum values resolvers. In Strawberry (Python), the
`@strawberry.enum` decorator maps Python enum members to GraphQL values. This mapping
is transparent to clients but essential for server implementation; failing to implement
it causes resolver values to not match the enum schema.

---

**[SENIOR] Q5 (Trade-off): What are the performance implications of deeply nested object types?**

Deeply nested types (User -> Posts -> Comments -> Reactions -> Users -> ...) have two
performance implications:

1. N+1 resolver problem multiplied by depth: without DataLoader, a query for users with
   posts with comments with reactions with reaction-users is N^depth database queries.
   100 users -> 100 post queries -> 1,000 comment queries -> 10,000 reaction queries =
   potentially 11,100+ database queries for one GraphQL request.

2. Query depth = potential DoS vector: a client can write an infinitely deep query:
   `{ user { friends { friends { friends { friends { ... } } } } } }`. Without depth
   limiting, this executes until timeout or OOM.

Mitigations:

1. DataLoader at every level: every list resolver uses DataLoader to batch sibling
   queries. The N^depth explosion becomes: 1 (users) + 1 (all posts for those users,
   batched) + 1 (all comments, batched) + 1 (all reactions, batched) = 4 queries
   regardless of depth.

2. Query depth limiting: reject queries exceeding a maximum depth (typically 5-8 levels).
   Libraries: `graphql-depth-limit`.

3. Query complexity scoring: assign complexity scores to fields; reject queries exceeding
   a total complexity budget. This addresses wide queries (100 fields shallow) that depth
   limiting misses.

*What separates good from great:* The DataLoader batching context window. DataLoader
batches resolver calls that happen within the same event loop tick. For nested resolvers,
DataLoader's batching window is per-level: all level-2 resolvers batch together; all
level-3 resolvers batch together. This means the batched query count is O(depth), not
O(1). For a 5-level deep query with DataLoader: 5 batched database queries. For a 5-level
deep query without DataLoader: O(N^5) queries. DataLoader reduces exponential to linear.

---

**[JUNIOR] Q6 (Application): When would you use a GraphQL interface and what must implementing types provide?**

Use an interface when: multiple object types share the same fields and you want to
write generic queries that work with any of those types without inline fragments.

An implementing type must provide all fields declared in the interface:

```graphql
interface Searchable {
  id: ID!
  "Short title used in search results"
  title: String!
  "Relevance score from search engine"
  relevanceScore: Float
}

type Article implements Searchable {
  id: ID!
  title: String!          # Required by interface
  relevanceScore: Float   # Required by interface
  content: String!        # Article-specific field
  author: User!
}

type Product implements Searchable {
  id: ID!
  title: String!          # Required by interface
  relevanceScore: Float   # Required by interface
  price: Float!           # Product-specific field
  sku: String!
}

type Query {
  # Returns any Searchable type
  search(query: String!): [Searchable!]!
}

# Query without inline fragments (interface fields only):
# { search(query: "laptop") {
#     id title relevanceScore
#   } }
# Works for both Article and Product results!

# Query with inline fragments for type-specific fields:
# { search(query: "laptop") {
#     id title relevanceScore
#     ... on Product { price sku }
#     ... on Article { author { name } }
#   } }
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the `Searchable` interface used in a search API that returns mixed Article and Product results, demonstrating how interface fields are accessible without inline fragments while type-specific fields require them. (2) KEY MECHANISM: `type Article implements Searchable` requires the `Article` resolver to provide `id`, `title`, and `relevanceScore` as defined in the interface; the GraphQL engine validates this at server startup. (3) WHY IT MATTERS: the generic `{ search { id title relevanceScore } }` query works for any search result type; a new type added to the search results (e.g., `Video implements Searchable`) automatically works with existing client queries as long as it implements the interface fields. (4) WHAT BREAKS: implementing a type without providing all interface fields causes a schema validation error at server startup; the server refuses to start with "Article must implement required field 'relevanceScore'". (5) TAKEAWAY: use interfaces for any query that needs to work across multiple types generically; the interface is a contract that enables both generic queries and type-specific inline fragments; it is more flexible than union for cases where the polymorphic types share meaningful common fields.

*What separates good from great:* Interface implementation across services in federation.
In a federated GraphQL architecture (Apollo Federation), object types in different
subgraph services can implement the same interface. The router ensures that interface
queries work across service boundaries. This enables cross-service polymorphic queries:
a `Node` interface implemented in the Users service AND the Products service allows
`query { node(id: "Product:1") { ... on Product { price } } }` to route to the correct
subgraph. Interface-based cross-service queries are a federation capability that requires
deliberate schema design from the start.

---

**[JUNIOR] Q7 (Scenario): A colleague's GraphQL query returns partial null data unexpectedly. How would you diagnose the cause?**

Partial null data in a GraphQL response typically means one of three things:

1. A resolver returned null for a non-null field (null propagation)
2. A resolver threw an exception
3. A permissions/authorization check failed and the resolver returned null

Diagnosis steps:

Step 1 - Check the `errors` array in the response:
GraphQL always returns errors in the response body alongside partial data.
```json
{
  "data": {
    "user": {
      "id": "1",
      "name": null,
      "profile": null
    }
  },
  "errors": [{
    "message": "Cannot read property 'bio' of undefined",
    "path": ["user", "profile", "bio"],
    "locations": [{"line": 5, "column": 5}]
  }]
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a GraphQL response with partial null data and the errors array revealing the exact cause - an error in the `bio` resolver that propagated null through `profile`. (2) KEY MECHANISM: GraphQL's error format includes `path` (the exact field path that failed), `message` (the error), and `locations` (the line in the query); using `path` to navigate to the failing resolver is the primary diagnosis tool. (3) WHY IT MATTERS: without checking `errors`, the symptom (null fields) is visible but the cause is not; the `errors` array is the root cause; always check `errors` before assuming the null is intentional. (4) WHAT BREAKS: some GraphQL error handling implementations redact error messages in production (sending generic "Internal Server Error" instead of the actual error); this makes diagnosis harder; use structured error IDs and server-side logs with the correlation ID from the response. (5) TAKEAWAY: GraphQL ALWAYS responds with HTTP 200 even on errors; check `data.errors` not the HTTP status code; the errors array is the diagnostic output.

Step 2 - Check the `path` field to identify the failing resolver:
The `path: ["user", "profile", "bio"]` indicates the `bio` field of the `profile` resolver
of the `user` resolver failed.

Step 3 - Check server logs for the resolver error:
Search for the error message `"Cannot read property 'bio' of undefined"` in server logs.
Root cause: `profile` resolver returned `undefined` (user has no profile); `bio` resolver
tried to access `undefined.bio` and threw an exception.

Fix: null-check in the `profile` resolver; if the user has no profile, return `null`
instead of `undefined`.

*What separates good from great:* The `errors.extensions` diagnostic pattern. Production
GraphQL servers include structured error metadata in `errors[].extensions`: error code,
request ID, resolver name, and environment. This enables: (1) client-side error handling
by code (not message string matching), (2) log correlation (request ID links the response
error to server-side logs), (3) error categorization (user errors vs system errors).
Implementing `extensions` on all errors is a production readiness requirement; debugging
production GraphQL without structured error extensions is significantly harder.

---

# Queries, Mutations, and Subscriptions

---

### 🎯 Model Answer

**30 seconds:**
> GraphQL has three operation types: Query (reads, can be parallelized), Mutation
> (writes, execute serially), and Subscription (real-time events over WebSocket).
> Queries are the most common. Mutations follow a request-response pattern like REST
> but with GraphQL's type system. Subscriptions maintain a persistent connection and
> push data when events occur. Each operation starts from the root `type Query`,
> `type Mutation`, or `type Subscription` in the schema.

**3 minutes (Senior):**
> The three operation types have distinct execution semantics: Queries execute in parallel
> (sibling root fields can resolve concurrently); mutations execute serially (each root
> mutation field completes before the next begins, providing ordering guarantees for
> batched mutations). Subscriptions maintain a stateful WebSocket or SSE connection;
> the server pushes events to the client when the subscribed event occurs. Practical
> considerations: (1) Mutation design - always return the modified entity; clients update
> their cache without re-fetching. (2) Subscription infrastructure - WebSocket connections
> are stateful; horizontal scaling requires pub/sub (Redis) to broadcast events across
> instances. (3) Operation naming - named operations (`query GetUser(...)`) are required
> for production; they appear in server logs, Apollo Studio metrics, and error messages;
> anonymous operations cannot be identified in diagnostics.

**Blank Mind Recovery:**

**(1) Restate:** "Three operations: Query (read, parallel), Mutation (write, serial),
Subscription (real-time, WebSocket). Mutations return the modified entity. Named
operations for production debuggability. Subscriptions need pub/sub for horizontal scaling."

---

### 📘 Concept Explanation

**Operation Types Comparison:**

```text
OPERATION TYPES:

QUERY (Read):
  - Can run in parallel (multiple root fields)
  - Idempotent (no side effects)
  - Cached by client (Apollo Client)
  - Transport: HTTP POST (or GET for persisted)
  - Response: data object

  query GetDashboard {
    user { name }         <- parallel
    recentOrders { id }   <- parallel with user
    notifications { text } <- parallel with both
  }
  All three resolve concurrently

MUTATION (Write):
  - Executes SERIALLY (spec guarantee)
  - Side effects allowed and expected
  - Invalidates cache (Apollo Client refetch)
  - Transport: HTTP POST
  - Response: data object with affected entity

  mutation Setup {
    createUser { id }     <- runs first, awaited
    createProfile { id }  <- runs after createUser
  }
  Ordering guaranteed

SUBSCRIPTION (Real-time):
  - Persistent connection (WebSocket or SSE)
  - Server pushes events to client
  - Stateful (not HTTP request/response)
  - Transport: WebSocket (ws://) or SSE
  - Response: stream of event objects

  subscription Live {
    orderUpdated { id status }
  }
  Keeps connection open; server pushes on event

KEY DIFFERENCES:
  Query:        stateless, parallel, cacheable
  Mutation:     stateless*, serial, cache-invalidating
  Subscription: stateful, event-driven, persistent
  (* HTTP is stateless; mutation triggers side effects)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the three operation types with their execution models, transport protocols, and key behavioral differences summarized in a comparison format. (2) HOW TO READ IT: each operation type shows its key characteristics; the "parallel vs serial" distinction between Query and Mutation is the most important behavioral difference; Subscription's "stateful" nature is what makes it architecturally different from the other two. (3) KEY RELATIONSHIP: the serial execution guarantee for mutations enables safe batched writes (createUser must complete before createProfile which creates the profile for the new user); this is a spec requirement, not an Apollo Server implementation choice. (4) EDGE CASE: multiple root-level mutations in a single request execute serially; multiple root-level queries execute in parallel; this asymmetry is intentional and stated in the spec. (5) INSIGHT: a senior engineer designs mutation inputs with this in mind: if mutation B requires the result of mutation A, they MUST be in the same request (to get serial guarantee) or sequential requests; sending them in separate HTTP requests loses the ordering guarantee.

---

### 💻 Code Example

```javascript
// BAD: Anonymous operations with no variable types
// (not production-ready; hard to debug)

// Anonymous query - cannot be identified in logs
const query = `
  {
    user(id: "1") {
      name
      orders {
        id
        status
      }
    }
  }
`;

// BAD: Mutation that returns only Boolean
// (clients cannot update cache)
const mutation = `
  mutation {
    updateOrderStatus(id: "123", status: SHIPPED)
  }
`;
// Returns: { "data": { "updateOrderStatus": true } }
// Apollo Client cannot update the Order in its cache
// because the mutation returns no Order data
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two anti-patterns - anonymous queries that appear as "unnamed" in server logs making debugging impossible, and mutations returning Boolean instead of the affected entity preventing cache updates. (2) KEY MECHANISM: anonymous queries appear as `(anonymous)` in Apollo Studio metrics and server logs; when 1000 queries per second fail, identifying which query is failing is impossible without a name; named operations are the primary identifier in GraphQL diagnostics. (3) WHY IT MATTERS: a mutation returning `Boolean` forces the client to either refetch the full entity (extra network request) or manually update the cache with stale data; returning the affected entity allows Apollo Client to automatically update all queries that reference that entity. (4) WHAT BREAKS: when multiple queries on the same page fetch different fields of the same entity, a mutation update that returns only Boolean cannot update all of them; Apollo Client needs the entity data (including `id` for cache key) to find and update all cached references. (5) TAKEAWAY: name ALL operations; mutations MUST return the modified entity with at least its `id` field; this is not optional in production GraphQL.

```javascript
// GOOD: Named operations with variables and full returns

// Named query with typed variables
const GET_USER_ORDERS = gql`
  query GetUserOrders($userId: ID!, $limit: Int = 10) {
    user(id: $userId) {
      id
      name
      orders(limit: $limit) {
        id
        status
        total
        createdAt
        items {
          productName
          quantity
          price
        }
      }
    }
  }
`;

// Named mutation returning the modified entity
const UPDATE_ORDER_STATUS = gql`
  mutation UpdateOrderStatus(
    $orderId: ID!
    $status: OrderStatus!
  ) {
    updateOrderStatus(id: $orderId, status: $status) {
      id          # Apollo uses this for cache key
      status      # Updated field - Apollo updates cache
      updatedAt   # Server-set timestamp
    }
  }
`;

// Named subscription with cleanup
const ORDER_STATUS_SUBSCRIPTION = gql`
  subscription OnOrderStatusChange($orderId: ID!) {
    orderStatusChanged(orderId: $orderId) {
      id
      status
      updatedAt
    }
  }
`;

// React component using all three
function OrderDashboard({ userId, activeOrderId }) {
  const { data: ordersData } = useQuery(
    GET_USER_ORDERS,
    { variables: { userId, limit: 5 } }
  );

  const [updateStatus] = useMutation(UPDATE_ORDER_STATUS);

  // Subscription updates cache automatically
  // when order status changes on server
  useSubscription(ORDER_STATUS_SUBSCRIPTION, {
    variables: { orderId: activeOrderId },
    skip: !activeOrderId
  });

  return (/* render orders */null);
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: production-ready named query, mutation, and subscription with typed variables, the mutation returning the full modified entity, and a React component using all three operation types together. (2) KEY MECHANISM: named operations (`GetUserOrders`, `UpdateOrderStatus`) appear as identifiers in Apollo Studio metrics and server logs; `gql` template literals are parsed at import time (not at every component render); the subscription uses `skip: !activeOrderId` to not open a WebSocket connection when there is no active order. (3) WHY IT MATTERS: the mutation returns `id`, `status`, and `updatedAt`; Apollo Client uses the `id` to find the Order entry in its normalized cache and updates `status` and `updatedAt` automatically; all components querying that order's status see the update without a separate refetch. (4) WHAT BREAKS: the subscription and the mutation both update the Order cache entry; if the subscription event arrives before the mutation response, the order status may briefly show the old value; Apollo Client's optimistic updates resolve this UX issue. (5) TAKEAWAY: the three operation types complement each other; queries fetch initial data, mutations update it (with cache update via response), subscriptions keep it live; all three use the same Apollo Client cache and coordinate automatically.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> GraphQL has three operation types: Query (fetch data, like HTTP GET), Mutation (change
> data, like HTTP POST/PUT/DELETE), and Subscription (real-time data over WebSocket).
> Queries and mutations look similar in syntax; the key difference is intent and execution.
> Subscriptions are different - they maintain a persistent connection and receive events
> as they happen. In practice: most of your code will be queries and mutations. Name all
> operations (good for debugging), use variables (good for reuse), and have mutations
> return the modified entity (good for caching).

---

**Senior / Staff (5+ years):**
> The three operation types have different execution guarantees and infrastructure needs.
> Query: parallel execution, stateless HTTP, cacheable; safe to add fields at any depth
> without ordering concerns. Mutation: serial execution guarantee per the spec; always
> return the modified entity for cache updates; design input types for extensibility.
> Subscription: stateful WebSocket connection; requires pub/sub for horizontal scaling;
> connection lifecycle management (reconnection, deduplication) is client responsibility
> but server must handle concurrent connections efficiently. In practice: query and mutation
> handle 95% of use cases; subscriptions are specialized infrastructure with non-trivial
> operational requirements; evaluate SSE as a simpler alternative before implementing
> WebSocket subscriptions.

---

### ⚠️ Common Misconceptions

**Misconception: "HTTP status code indicates success or failure for GraphQL operations."**

GraphQL ALWAYS returns HTTP 200 OK, even for errors. A mutation that fails, a query
that returns null due to a resolver error, and an invalid query that fails schema
validation all return HTTP 200. The actual success/failure is in the response body:
successful response: `{ "data": { "user": {...} } }`. Error response: `{ "data": null,
"errors": [{"message": "Not Found", "path": ["user"]}] }`. Partial success: `{ "data":
{"user": {"name": "Alice", "profile": null}}, "errors": [{"path": ["user", "profile"],
"message": "..."}] }`. Implication: clients cannot rely on HTTP status codes for error
handling; they MUST check the `errors` array in every response; monitoring based on
HTTP status codes misses GraphQL errors (the HTTP layer sees all 200s even when 30%
of queries are failing).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: WebSocket subscription connection drops and events are lost.**

Symptom: real-time dashboard shows stale data after 30 minutes; orders are not updating;
no errors in the UI.
Root cause: WebSocket connection dropped (network hiccup, load balancer timeout); the
client's subscription is no longer active; events are missed.

```javascript
// BAD: Subscription without reconnection handling
useSubscription(ORDER_SUBSCRIPTION, {
  variables: { orderId }
  // No error handler; no reconnection; events lost
});

// GOOD: Subscription with reconnection + catch-up
function useOrderSubscription(orderId) {
  const [missedEvents, setMissedEvents] = useState(false);

  const { error } = useSubscription(
    ORDER_SUBSCRIPTION,
    {
      variables: { orderId },
      onError: (err) => {
        console.error('Subscription error:', err);
        setMissedEvents(true);
      }
    }
  );

  // Refetch when reconnection is detected
  const { refetch } = useQuery(
    GET_ORDER_STATUS,
    {
      variables: { orderId },
      skip: !missedEvents
    }
  );

  useEffect(() => {
    if (missedEvents) {
      // Re-query to get current state
      // (catch up on missed events)
      refetch().then(() => setMissedEvents(false));
    }
  }, [missedEvents, refetch]);
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: handling WebSocket subscription disconnection with an error handler that detects connection loss and triggers a re-query to catch up on events missed during the disconnection. (2) KEY MECHANISM: `onError` fires when the subscription WebSocket encounters an error (connection dropped, server error); `setMissedEvents(true)` triggers a regular query via `useQuery` to fetch the current state and update the cache; this "catch-up query" pattern ensures consistency after reconnection. (3) WHY IT MATTERS: subscriptions are not guaranteed delivery; WebSocket connections drop due to network issues, load balancer timeouts (typically 60 seconds), or server restarts; without catch-up logic, the client shows stale data indefinitely. (4) WHAT BREAKS: Apollo Client's WebSocket link auto-reconnects on connection drop but does NOT re-send any missed events; the catch-up query is required to restore consistency after reconnection. (5) TAKEAWAY: implement catch-up logic (re-query on reconnect) for every subscription that displays critical data; subscriptions for non-critical data (typing indicators, presence) can tolerate missed events; subscriptions for order status, payment status, or any business-critical data require catch-up.

---

### ⚖️ Comparison Table

| Aspect | Query | Mutation | Subscription |
|---|---|---|---|
| Purpose | Read data | Write data | Real-time events |
| Execution | Parallel (root fields) | Serial (root fields) | Event-driven |
| Transport | HTTP POST/GET | HTTP POST | WebSocket/SSE |
| State | Stateless | Stateless | Stateful |
| Caching | Apollo Client caches | Invalidates cache | Updates cache |
| Scaling | Horizontal (stateless) | Horizontal (stateless) | Requires pub/sub |
| Error HTTP code | 200 always | 200 always | WS close code |

---

### 🏛️ System Design

*(Omit: L1 keyword; subscription scaling patterns covered in L4 Real-time Scale entry.)*

---

### 📊 Diagram

```text
OPERATION TYPE EXECUTION FLOW:

QUERY (parallel):
  POST /graphql
  { query: "{ a { x } b { y } }" }
  GraphQL Engine
  -> resolve a() [concurrent]
  -> resolve b() [concurrent]
  -> merge results
  <- { "data": { "a": {x}, "b": {y} } }

MUTATION (serial):
  POST /graphql
  { query: "mutation { m1 { id } m2 { id } }" }
  GraphQL Engine
  -> resolve m1()        [runs first]
  -> await m1 complete   [wait for m1]
  -> resolve m2()        [runs after m1]
  -> merge results
  <- { "data": { "m1": {id}, "m2": {id} } }

SUBSCRIPTION (event-driven):
  WebSocket upgrade
  Client: { subscribe: "subscription S { e { id } }" }
  Server: registers event listener for S
  [connection stays open]
  [event occurs on server]
  Server -> push: { "data": { "e": {id} } }
  Server -> push: { "data": { "e": {id} } }  (again)
  [client unsubscribes or disconnects]
  Server: removes listener, closes connection
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the execution flow for all three operation types, showing the parallelism in queries, the serial guarantee in mutations, and the persistent event-driven nature of subscriptions. (2) HOW TO READ IT: follow the arrows top-to-bottom for each operation type; the `[concurrent]` annotation on query resolution vs `[wait for m1]` on mutation resolution shows the key behavioral difference. (3) KEY RELATIONSHIP: query parallelism enables better latency for complex queries with multiple root fields; mutation serialism enables safe dependent writes; these are opposite behaviors because queries are read-only (order doesn't matter) while mutations have side effects (order matters). (4) EDGE CASE: queries can have side effects if resolvers have them (logging, metrics); but the GraphQL spec assumes queries are side-effect-free; mutations are the contract for side effects; never put side effects in query resolvers. (5) INSIGHT: a senior engineer notes that the WebSocket upgrade for subscriptions means HTTP infrastructure (load balancers, WAF, CDN) must support WebSocket connections; some infrastructure defaults to rejecting WebSocket upgrades; subscription deployment requires explicit WebSocket support configuration in all infrastructure layers.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | operation types, mutation return values |
| Application | 2 | mutation design, subscription use cases |
| Trade-off | 2 | query vs mutation, subscription vs polling |
| Scenario | 1 | subscription reconnection |

---

**[JUNIOR] Q1 (Definition): What is the difference between a GraphQL query and a mutation?**

Query: reads data. No side effects expected. Parallel execution allowed. Idempotent
(calling the same query multiple times returns the same result without side effects).
GraphQL cacheable.

Mutation: writes data. Side effects expected (database writes, email sends, payments).
Serial execution: if multiple mutations are in one request, they execute in order.
Not idempotent in general.

Naming convention:
Queries: noun-first (`user`, `posts`, `currentUser`).
Mutations: verb-first (`createUser`, `updateOrderStatus`, `deletePost`).

Syntactic difference:
```graphql
query GetUser($id: ID!) {      # explicit 'query' keyword
  user(id: $id) { name }
}

mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) { id name }
}

# Shorthand for anonymous query (query keyword optional):
{ user(id: "1") { name } }   # Works; not recommended
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the syntactic difference between query and mutation declarations with the naming convention for each. (2) KEY MECHANISM: the `query` keyword is technically optional (the shorthand `{ field }` is an anonymous query); the `mutation` keyword is required; good practice: always use explicit keywords with names. (3) WHY IT MATTERS: the distinction matters for execution semantics (parallel vs serial) and for client-side caching (queries are cached; mutations invalidate cache entries). (4) WHAT BREAKS: accidentally using a query for a write operation (a resolver with side effects on a query field) - the query might be cached and the side effect might not run on subsequent calls. (5) TAKEAWAY: use query for reads, mutation for writes; follow the naming convention (noun for queries, verb for mutations); name every operation.

*What separates good from great:* The parallel query root fields optimization. When a
query has multiple root fields (`{ user { name } recentPosts { title } notifications { text } }`),
GraphQL can resolve all three simultaneously. Apollo Server, by default, resolves root
fields of a query in parallel when they are independent. This is why complex dashboard
queries (fetching user data, order data, notification data simultaneously) are more
efficient in GraphQL than sequential REST calls. The server's concurrency model determines
actual parallelism; Node.js event loop handles I/O-bound resolvers concurrently; CPU-
bound resolvers are still sequential.

---

**[JUNIOR] Q2 (Application): Why should a mutation return the modified entity rather than just a success boolean?**

Three concrete reasons:

1. Apollo Client cache updates:
Apollo Client normalizes entities by `__typename + id`. When a mutation returns the
entity with its `id`, Apollo Client finds the entity in its cache and updates it
automatically. All components querying that entity see the update without a network
request.

Without entity return (returns Boolean):
- Mutation succeeds.
- Apollo Client cache still has old data.
- UI shows old data.
- Client must manually trigger a `refetchQueries` (extra network request) or manually
  update the cache (boilerplate code).

With entity return:
- Mutation succeeds.
- Response contains updated entity with `id`, `status`, `updatedAt`.
- Apollo Client finds `Order:123` in cache, updates fields.
- All components using `Order:123` re-render with new data.
- Zero extra network requests.

2. Server-generated values:
Mutations often produce server-side values: `id` (auto-generated), `createdAt`, `updatedAt`,
`slug` (generated from title). Returning the entity gives clients these server-generated
values immediately without a follow-up query.

3. Optimistic UI revert:
Apollo Client's optimistic updates allow the UI to show the expected result before the
mutation completes. If the mutation fails, Apollo reverts to the original data using
the actual server response. This requires the mutation to return the real entity data.

*What separates good from great:* The "return only what changed" optimization for large
entities. A `User` type might have 50 fields. A mutation that updates the user's
notification settings only changes 3 fields. The mutation should return only the fields
that changed plus `id` (for cache key). Requesting all 50 fields in the mutation response
wastes bandwidth. Design mutations to return minimal entity data: `id` always, plus
only the fields the mutation modified. Clients can always query additional fields via
a separate query if needed.

---

**[SENIOR] Q3 (Application): How do you design a GraphQL mutation for a complex multi-step operation?**

Complex operations (multi-step workflows) in GraphQL: use a single mutation with an input
type that captures all parameters; return a rich result type that includes success/failure
state and all affected entities.

```graphql
input CheckoutInput {
  cartId: ID!
  paymentMethodId: ID!
  shippingAddressId: ID!
  couponCode: String    # Optional
}

# Rich result type (not just Order)
type CheckoutResult {
  success: Boolean!
  order: Order          # null if failed
  paymentTransaction: PaymentTransaction
  errors: [CheckoutError!]!  # Business errors
}

type CheckoutError {
  code: CheckoutErrorCode!
  message: String!
  field: String  # which input field caused the error
}

enum CheckoutErrorCode {
  CART_EMPTY
  PAYMENT_FAILED
  OUT_OF_STOCK
  INVALID_COUPON
  ADDRESS_INVALID
}

type Mutation {
  checkout(input: CheckoutInput!): CheckoutResult!
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a complex mutation design using a rich result type that includes success/failure state, the affected entity, and structured business error codes, rather than throwing GraphQL errors for business logic failures. (2) KEY MECHANISM: business errors (PAYMENT_FAILED, OUT_OF_STOCK) are returned in `errors: [CheckoutError!]!` rather than thrown as GraphQL exceptions; system errors (database timeout) are still thrown as exceptions; this separation allows clients to handle business errors distinctly from infrastructure failures. (3) WHY IT MATTERS: the `CheckoutErrorCode` enum documents all possible failure modes in the schema; client developers know every possible error code they need to handle; the schema is the error documentation. (4) WHAT BREAKS: mixing business errors (payment failed) with system errors (database down) in the same error mechanism makes client error handling inconsistent; the pattern above cleanly separates: `success: false + errors: [PAYMENT_FAILED]` for business failures vs HTTP 500/GraphQL exception for system failures. (5) TAKEAWAY: design complex mutations with result types that include `errors` for business logic failures; never throw exceptions for expected business outcomes (payment declined is expected, not exceptional); use the result type's `errors` array for predictable, handleable failures.

*What separates good from great:* The "result type vs union" debate for mutation responses.
An alternative pattern uses union return types: `type Mutation { checkout(input: CheckoutInput!): CheckoutSuccess | CheckoutFailure }`. This is more explicit (each case has its own type) but less extensible (adding a new failure mode requires a new union member). The `CheckoutResult` pattern (success + errors in one type) is more pragmatic: one result type handles all outcomes; the `errors` array documents failure modes; `success: Boolean!` is a quick check. The union pattern is used in sophisticated APIs (GitHub's GraphQL API uses it for some mutations). Neither is universally better; the union pattern is more expressive; the result type pattern is simpler to implement and evolve.

---

**[SENIOR] Q4 (Trade-off): When would you choose GraphQL subscriptions over polling?**

Polling: client sends a query every N seconds to check for updates.
Subscription: server pushes events to the client as they occur.

Choose subscriptions when:
1. Update frequency is high (multiple updates per second): polling at 1-second intervals
   is 86,400 requests/day per client; a subscription receives the same number of events
   but without the polling overhead (empty responses when no changes occurred).
2. Latency matters: a status that changes 50ms after a mutation must be reflected in
   the UI within 100ms; polling at 1 second means 0-1000ms latency; subscription delivers
   in ~50ms (server event + network).
3. Data volume is large: polling for a chat room fetches the full message list every
   interval; subscription receives only the new message (delta updates).

Choose polling when:
1. Update frequency is low (once per hour): a subscription connection that holds open for
   3,600 seconds to receive 1 event is wasteful; polling every 10 minutes is simpler.
2. Infrastructure does not support WebSocket: some environments (Cloudflare Workers,
   AWS Lambda) have limitations on long-lived connections.
3. The subscription use case is simple (single user's data updates): polling may be
   simpler to implement and debug.
4. Server-Sent Events (SSE) is acceptable: SSE is simpler than WebSocket for server-
   to-client updates; if bidirectional communication is not needed, SSE is a lighter choice.

Rule of thumb: subscriptions for high-frequency, latency-sensitive, or delta-update
scenarios; polling for low-frequency, latency-tolerant, full-state scenarios.

*What separates good from great:* The infrastructure cost analysis. A WebSocket subscription
connection holds a TCP connection open for its duration. A server handling 10,000 concurrent
subscription connections has 10,000 open file descriptors. Most servers have a limit of
65,535 concurrent TCP connections per port; large WebSocket subscription deployments
require multiple server instances with a pub/sub broker (Redis) coordinating events. This
is significantly more complex than polling, which is stateless and scales horizontally
without coordination. The operational overhead of subscription infrastructure must be
weighed against the user experience benefit; for most CRUD applications, the UX benefit
does not justify the infrastructure complexity.

---

**[JUNIOR] Q5 (Application): What variables are in GraphQL operations and why use them instead of string interpolation?**

Variables are named, typed parameters in GraphQL operations. They are defined in the
operation signature and referenced in the query body with the `$` prefix.

Why use variables instead of string interpolation:

1. Security - prevents injection:
```javascript
// BAD: String interpolation (injection risk)
const userId = req.params.id; // Could be: "1) { id } user(id: 999"
const query = `{ user(id: ${userId}) { name } }`;
// Injected: { user(id: 1) { id } user(id: 999) { name } }
// Attacker can manipulate the query structure!

// GOOD: Variables (server validates against schema)
const query = `query GetUser($id: ID!) {
  user(id: $id) { name }
}`;
const variables = { id: userId };
// Variables are validated as ID type; injection prevented
// Variables cannot change the query structure
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the critical security difference between string interpolation (which allows query structure injection) and typed variables (which are validated against their declared type and cannot change the query structure). (2) KEY MECHANISM: GraphQL variables are parsed and type-checked separately from the query structure; a variable typed as `ID!` can only contain an ID scalar value; it cannot contain GraphQL syntax like `) { } (`; the query structure is determined entirely by the static query string. (3) WHY IT MATTERS: GraphQL injection via string interpolation is a real security vulnerability; an attacker who controls an interpolated value can exfiltrate data from other parts of the schema by injecting additional query fields. (4) WHAT BREAKS: using variables prevents injection but requires ALL dynamic values to be declared as typed variables in the operation signature; there is no way to use a variable to change the selection set (which fields to query) - that is by design. (5) TAKEAWAY: NEVER interpolate user-controlled values into GraphQL query strings; ALWAYS use typed variables; this is a security requirement, not just a best practice.

2. Performance - enables query caching:
The query string `query GetUser($id: ID!) { user(id: $id) { name } }` is static.
The GraphQL server can parse and validate the query once, cache the parsed result,
and reuse it for all calls with different variable values. String interpolation produces
a different query string for each ID value, defeating query parsing cache.

3. Reusability: one query string with variables can be called with different variable
   values; no string construction needed in application code.

*What separates good from great:* The persisted query optimization. Named, variable-based
queries enable persisted queries: the client sends a query ID (hash of the query string)
instead of the full query string. The server maps the ID to the pre-registered query.
Benefits: (1) smaller request payload (ID vs full query string), (2) prevents arbitrary
query execution (only pre-registered queries allowed - a security hardening measure),
(3) enables CDN caching of query responses by query ID + variables. Persisted queries
require static query strings with variables; string interpolation makes persisted queries
impossible.

---

**[SENIOR] Q6 (Trade-off): How does serial mutation execution affect the design of complex workflows?**

Serial mutation execution guarantees that multiple mutations in one request execute in
order; each mutation completes before the next begins. This affects workflow design:

Advantage - dependent operations in one request:
```graphql
mutation OnboardUser($userInput: CreateUserInput!) {
  createUser(input: $userInput) { id }
  createDefaultProfile { id }     # Safe: runs after createUser
  sendWelcomeEmail { sent }       # Safe: runs after profile
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: three dependent mutations in one request that execute serially, where each depends on the previous completing successfully. (2) KEY MECHANISM: the GraphQL spec guarantees that `createUser` completes before `createDefaultProfile` starts; `sendWelcomeEmail` runs after both; the ordering is respected even if the server processes requests concurrently. (3) WHY IT MATTERS: sending three separate HTTP requests for these mutations loses the ordering guarantee; concurrent requests might execute out of order; the serial guarantee only applies within a single request containing multiple root mutations. (4) WHAT BREAKS: if `createUser` fails, `createDefaultProfile` still runs (the error is in the response `errors` array, but execution continues); this can create orphaned records; implement compensating mutations or use a transaction pattern (a single mutation that runs all steps in a database transaction). (5) TAKEAWAY: for dependent mutations that must all succeed together, prefer a single mutation that wraps the entire operation in a transaction; for independent mutations that happen to run in order, serial mutations are appropriate.

Limitation - no rollback:
If `createUser` succeeds but `sendWelcomeEmail` fails, there is no automatic rollback.
The user is created but did not receive the email. For true atomic operations, design
a single mutation that wraps all steps in a database transaction:

```graphql
mutation OnboardUser($input: OnboardUserInput!) {
  onboardUser(input: $input) {
    user { id }
    welcomeEmailSent
    errors { code message }
  }
}
# Single resolver; wraps all steps in DB transaction
# Atomically succeeds or fails
```

> **Code walkthrough:** (1) WHAT IT SHOWS: consolidating dependent mutations into a single mutation with a resolver that wraps all operations in a database transaction, providing atomicity (all succeed or none commit). (2) KEY MECHANISM: a single GraphQL mutation resolver can span multiple database operations in one transaction; if the welcome email send fails, the transaction rolls back the user creation; no orphaned data. (3) WHY IT MATTERS: the multi-mutation serial approach has no atomicity guarantee; the single-mutation transactional approach does; for operations that must all succeed together, the single-mutation pattern is the correct design. (4) WHAT BREAKS: long-running transactions (including external service calls like email sending) can hold database locks and reduce throughput; consider moving external service calls (email, notifications) to a background queue outside the transaction. (5) TAKEAWAY: use the single-mutation transactional pattern for operations that must be atomic; use serial mutations for independent operations that happen to run in order; understand the difference between serial execution and transactional atomicity.

*What separates good from great:* The idempotency key pattern for mutations. Network
failures can cause a mutation to succeed on the server but the response to be lost in
transit. Without idempotency, retrying the mutation creates duplicate records. The
idempotency key pattern: the client generates a UUID for each mutation attempt; the server
stores the UUID and the result; if the same UUID is sent again, the server returns the
stored result instead of executing the mutation again. This pattern (used by Stripe, Shopify)
is essential for payment mutations and any mutation that must not be duplicated.

---

**[JUNIOR] Q7 (Application): What is a subscription and when would you use it in a real application?**

A subscription is a long-lived GraphQL operation that receives a stream of events from
the server over a persistent connection (WebSocket). Unlike query and mutation (request-
response), a subscription stays open and the server pushes updates to the client.

Real-world use cases:
1. Live order tracking: customer opened "Track Order" page; subscription sends push
   update when order status changes from PROCESSING to SHIPPED to DELIVERED.
2. Chat application: subscription pushes each new message to all participants in
   a chat room in real-time.
3. Live sports scores: subscription pushes score updates as goals/points are scored.
4. Real-time notifications: subscription pushes notification events (new follower,
   comment on post) as they occur.
5. Collaborative editing: subscription pushes cursor positions and document changes
   to all editors in real-time.
6. Live dashboard metrics: subscription pushes system metrics (CPU, memory, error rate)
   updates every second.

When NOT to use subscriptions:
- Infrequently changing data (user profile, product catalog): polling or re-fetch on
  demand is simpler.
- Simple success/failure notification: a mutation can return success; no subscription needed.
- Data only needed once (one-time check): a query is sufficient.

*What separates good from great:* The subscription scope design. A subscription should
be scoped to the minimum necessary audience. `subscription { allOrdersUpdated }` sends
EVERY order update to EVERY connected client; wasteful and a data exposure risk. `subscription { orderUpdated(orderId: $orderId) }` scopes the subscription to a specific order. The server only pushes to clients subscribed to that specific order ID. Proper subscription scoping reduces event fan-out, reduces bandwidth, and prevents data leakage (user A should not receive order updates for user B's orders). Always design subscriptions with the narrowest possible scope.
