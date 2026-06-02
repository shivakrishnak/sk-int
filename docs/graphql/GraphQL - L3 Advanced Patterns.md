---
layout: default
title: "GraphQL - L3 Advanced Patterns"
parent: "GraphQL"
nav_order: 7
permalink: /graphql/l3-advanced-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 16 | [Schema Stitching vs Federation](#schema-stitching-vs-federation) | ★★☆ |
| 17 | [Authentication and Authorization Patterns](#authentication-and-authorization-patterns) | ★★☆ |

---

# Schema Stitching vs Federation

---

### 🎯 Model Answer

**30 seconds:**
> Schema stitching manually combines multiple GraphQL schemas into one - it is the
> older approach requiring custom merge configuration. Federation (Apollo Federation)
> is the modern standard: each service owns its own schema and exposes it independently;
> a gateway automatically composes them into a unified supergraph. Federation uses
> type extensions and `@key` directives so services can reference entities from other
> services. Choose Federation for new microservices architectures; schema stitching for
> gradual legacy migrations.

**3 minutes (Senior):**
> Schema stitching merges multiple schemas at the gateway layer using SDL merging,
> remote schema delegation, and custom resolvers for cross-schema type merging. The
> gateway controls the full composition; all services must be co-developed with
> the gateway. Issues: merging conflicts, manual delegation chains, gateway as a
> single-team bottleneck. Apollo Federation distributes ownership: each service declares
> `@key(fields: "id")` on entity types and extends types from other services using
> `@extends`. The gateway uses schema composition (compile-time) to validate the
> combined supergraph and query planning (runtime) to split queries across services
> optimally. Federation v2 improves on v1 with shareable types (`@shareable`), no
> "extend" keyword required, and better incremental migration support. Federation solves
> the schema ownership problem: the Team A owns the User type; Team B owns the Product
> type; neither team must coordinate schema changes with the gateway team; the gateway
> auto-composes.

**Blank Mind Recovery:**

**(1) Restate:** "Schema stitching: old, manual, gateway controls composition. Federation:
modern, distributed ownership, services expose subgraph schemas, gateway auto-composes.
Key directive: `@key(fields: 'id')` on entity types. Gateway: query plan splits query
across services. Federation v2: `@shareable`, no `extend` required."

---

### 📘 Concept Explanation

**Federation Architecture:**

```text
SCHEMA STITCHING ARCHITECTURE:
  Gateway owns composition logic (bottleneck):

  User Service (raw schema)
  + Post Service (raw schema)
  + Comment Service (raw schema)
    |
  Gateway: manually stitches schemas together
    - merges type definitions
    - writes custom type mergers
    - delegates sub-queries to each service
    - all services change -> gateway must update
  Gateway team = bottleneck for all schema changes

  ---
FEDERATION ARCHITECTURE:
  Each service owns its subgraph schema:

  User Subgraph:                   Post Subgraph:
  type User @key(fields: "id") {   type Post @key(fields: "id") {
    id: ID!                          id: ID!
    name: String!                    title: String!
    email: String!                   author: User
  }                                }
                                   extend type User
                                   @key(fields: "id") {
                                     id: ID! @external
                                     posts: [Post!]!
                                   }
                                   # User extended in Post service
                                   # User service not touched!

  Federation Gateway:
  Receives query { user { name posts { title } } }
  Query plan:
  1. Fetch User(name) from User Subgraph
  2. Fetch Post(title) by User.id from Post Subgraph
  Parallel where possible; sequential where dependent
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the architectural difference between schema stitching (gateway-owned, centralized composition) and federation (service-owned, distributed composition). (2) HOW TO READ IT: the top section shows schema stitching where the gateway manually combines raw service schemas; the bottom shows federation where each subgraph uses `@key` and `extend type` directives to define their part of the unified schema. (3) KEY RELATIONSHIP: in federation, the Post service can add `posts: [Post!]!` to the User type without modifying the User service or the gateway; ownership is distributed and independent. (4) EDGE CASE: if two services extend the same type with conflicting fields, federation composition fails at build time; this compile-time failure is preferable to a runtime failure in production. (5) INSIGHT: a senior engineer values federation's compile-time composition validation; the `rover compose` command validates the combined supergraph before deployment; schema conflicts are caught before they reach production.

---

### 💻 Code Example

```javascript
// BAD: Schema stitching with manual delegation
// (gateway-owned, high coupling, manual merging)

// Gateway code (stitching approach):
const { stitchSchemas } = require('@graphql-tools/stitch');

const userSchema = await fetchRemoteSchema(
  'https://users-service/graphql'
);
const postSchema = await fetchRemoteSchema(
  'https://posts-service/graphql'
);

const stitchedSchema = stitchSchemas({
  subschemas: [
    { schema: userSchema },
    { schema: postSchema }
  ],
  // Manual type merging configuration:
  // When both schemas have User type, tell the
  // gateway how to merge them
  typeMergingOptions: {
    User: {
      fieldName: 'user',
      args: ({ id }) => ({ id }),
      // Gateway must know about User structure
      // Any service schema change requires updating
      // this gateway configuration
      selectionSet: '{ id }'
    }
  }
});
// Problems:
// 1. Gateway team must coordinate all schema changes
// 2. Remote schema fetching adds startup latency
// 3. Type merging configuration grows complex at scale
// 4. No compile-time validation of the combined schema
```

> **Code walkthrough:** (1) WHAT IT SHOWS: schema stitching with manual type merging configuration in the gateway, highlighting the coupling between gateway configuration and service schema structure. (2) KEY MECHANISM: `stitchSchemas` merges the user and post service schemas at the gateway; `typeMergingOptions.User` tells the gateway how to merge User types from different services; this configuration must be updated whenever the User type changes in any service. (3) WHY IT MATTERS: the gateway team becomes a bottleneck; every service schema change (adding a field, changing an argument) requires gateway configuration updates and gateway re-deployment; independent team velocity is lost. (4) WHAT BREAKS: remote schema fetching on gateway startup (`fetchRemoteSchema`) creates a startup dependency; if any service is down when the gateway starts, the startup fails; federation uses offline schema composition instead. (5) TAKEAWAY: schema stitching is appropriate for gradual migration of existing services; for new microservices architectures, use Apollo Federation from the start.

```javascript
// BAD: Schema stitching (centralized gateway composition - see block above)
// GOOD: Apollo Federation - distributed schema ownership

// users-service/schema.graphql (subgraph schema):
// (SDL - schema definition language)
// Users service owns User type completely:

/*
type Query {
  user(id: ID!): User
  me: User
}

type User @key(fields: "id") {
  id: ID!
  name: String!
  email: String!
  createdAt: DateTime!
}
*/

// posts-service/schema.graphql (subgraph schema):
// Posts service EXTENDS User (no changes to user service!)

/*
type Query {
  post(id: ID!): Post
  feed(first: Int, after: String): PostConnection
}

type Post @key(fields: "id") {
  id: ID!
  title: String!
  content: String!
  author: User!
}

extend type User @key(fields: "id") {
  id: ID! @external    # External: owned by user service
  posts(first: Int): [Post!]!  # Added by post service!
}
*/

// posts-service/resolvers.js:
const resolvers = {
  Post: {
    author: ({ authorId }) => ({ __typename: 'User', id: authorId })
    // Return a reference: gateway fetches from user service
  },
  User: {
    // Reference resolver: receives { id } stub from gateway
    __resolveReference: async ({ id }, { db }) =>
      db.getUserById(id)
    // Called by gateway when user fields are needed
    // for a User reference from another service
  }
};

// Gateway: AUTO-COMPOSES from all subgraph schemas
// No manual type merging configuration needed!
// Query: { user { name posts { title } } }
// Gateway plan:
//   1. user(id) -> users-service (name, id)
//   2. posts(authorId: user.id) -> posts-service (title)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Apollo Federation's distributed schema ownership - the users service owns the User type with `@key(fields: "id")`, the posts service extends User with `posts` field without touching the users service or gateway, and the `__resolveReference` resolver handles cross-service entity fetching. (2) KEY MECHANISM: `@key(fields: "id")` marks User as a federated entity; the gateway uses the key to look up a User when it needs fields from the users service for a reference received from the posts service; `__resolveReference` is the resolver for these cross-service lookups. (3) WHY IT MATTERS: the posts team can add `posts: [Post!]!` to the User type without involving the users team or the gateway team; the gateway auto-composes the new field; team independence at the schema level. (4) WHAT BREAKS: if `__resolveReference` is not implemented for an entity type, the gateway cannot fetch entity fields across services; it returns null for those fields; every `@key` type must have a `__resolveReference` resolver. (5) TAKEAWAY: federation's compile-time composition (`rover compose`) validates that all referenced types exist and all `@key` fields are resolvable before deployment; schema conflicts are caught at the earliest possible stage.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Schema stitching is the older approach where a gateway manually combines multiple
> GraphQL service schemas. Apollo Federation is the modern standard: each service
> exposes its own schema (subgraph) with entity ownership declarations (`@key`
> directive); the gateway automatically composes them into a unified API. With
> federation, the posts team can extend the User type to add `posts` without touching
> the user service. Teams own their types independently; the gateway composition is
> automatic.

---

**Senior / Staff (5+ years):**
> The key decision between schema stitching and federation is team ownership model.
> Schema stitching creates a gateway team bottleneck; all schema changes require gateway
> configuration updates. Federation distributes schema ownership: each team owns their
> service's types and can extend other services' types via `extend type`. Federation v1
> limitations: required `extend type` syntax (awkward), `@external` + `@requires`
> verbosity. Federation v2 addresses these: `@shareable` for types shared across
> services, implicit type extensions, better composition error messages. For existing
> REST/legacy-backed schemas being migrated to GraphQL, schema stitching with
> `@graphql-tools/stitch` is the pragmatic migration path. For greenfield microservices,
> Apollo Federation v2 is the standard.

---

### ⚠️ Common Misconceptions

**Misconception: "Schema stitching and federation achieve the same architecture with different tools."**

Schema stitching and federation have fundamentally different ownership models. Schema
stitching: the gateway owns the composition; services expose raw schemas; the gateway
team merges them. Federation: each service owns its entity types; the gateway
auto-composes based on service-declared directives; no gateway team involvement for
adding fields to existing types. The operational difference: with schema stitching,
adding `posts: [Post!]!` to the User type requires: (1) modifying the gateway's type
merging configuration, (2) coordinating with the gateway team, (3) re-deploying the
gateway. With federation: the posts team adds `extend type User @key(fields: "id") {
id: ID! @external posts: [Post!]! }` to the posts service schema and re-deploys only
the posts service. No gateway team involvement. This is not a tooling difference; it is
an architectural ownership model difference with significant team velocity implications.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Federation composition fails because a required `__resolveReference` resolver is missing.**

Symptom: queries that cross service boundaries return null for entity fields; the posts
service can fetch post data, but `Post.author.name` returns null even though the user
service has the user data.

Root cause: `__resolveReference` not implemented in the users service for the User entity.

```javascript
// BAD: User entity without __resolveReference
// posts-service: returns User reference
Post: {
  author: ({ authorId }) => ({
    __typename: 'User',
    id: authorId  // Reference: type + key only
  })
}

// users-service: User entity missing __resolveReference
// BAD: no __resolveReference -> gateway cannot fetch
// User fields from user service for cross-service refs

// GOOD: User entity with __resolveReference
// BAD: (see above - missing resolver returns null)
const resolvers = {
  User: {
    __resolveReference: async (
      { id },  // The reference: { __typename, id }
      { loaders }
    ) => {
      // Fetch full User entity by id
      return loaders.user.load(id);
      // Returns: { id, name, email, ... }
      // Gateway merges with data from post service
    }
  }
};
// Now: { post { title author { name } } }
// Gateway: Post.author -> { __typename:User, id:1 }
// -> calls User.__resolveReference({id:1})
// -> returns { id:1, name:Alice, email:... }
// author.name = "Alice" (correct!)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the missing `__resolveReference` bug and fix - without it, the gateway receives a User reference (`{ __typename: 'User', id: 1 }`) from the posts service but cannot resolve it to a full User object from the users service. (2) KEY MECHANISM: `__resolveReference` is the cross-service entity resolver; the gateway calls it when it receives a reference to an entity from another service; it receives the reference object (with key fields) and must return the full entity. (3) WHY IT MATTERS: without `__resolveReference`, cross-service entity references silently return null; the bug only manifests in cross-service queries, not single-service queries; it can be missed in development if testing is service-isolated. (4) WHAT BREAKS: using a DataLoader inside `__resolveReference` is important for performance; if `__resolveReference` is called for 100 User references from 100 posts, DataLoader batches them into one database query. (5) TAKEAWAY: every entity type (marked with `@key`) must have a `__resolveReference` resolver; this is the single most common federation implementation bug; add a lint rule or CI check that verifies every `@key` type has a corresponding `__resolveReference`.

---

### ⚖️ Comparison Table

| Aspect | Schema Stitching | Apollo Federation |
|---|---|---|
| Schema ownership | Centralized (gateway team) | Distributed (service teams) |
| Type composition | Manual merge configuration | Auto-compose from `@key` directives |
| Compile-time validation | Limited | Full (`rover compose`) |
| Team independence | Low (gateway bottleneck) | High (independent schema changes) |
| Migration support | Good (gradual migration tools) | Supported (v2 incremental) |
| Learning curve | Moderate | Moderate-High |
| Ecosystem | `@graphql-tools` | Apollo Federation v2 spec |
| Best for | Legacy migration | Greenfield microservices |

---

### 🏛️ System Design

*(Omit: L3 keyword; federation at scale with schema registry, RBAC per service, and query planning covered in L5 Architecture entry.)*

---

### 📊 Diagram

```text
APOLLO FEDERATION QUERY EXECUTION:

  Supergraph (gateway composes subgraphs):
  type User { id name email posts:[Post] }
  type Post { id title author:User }

  Client query:
  { user(id:"1") { name posts { title } } }

  Gateway Query Plan (auto-generated):
  Step 1: Fetch from users-service
    user(id:"1") { name id }
    Result: { name:"Alice", id:"1" }

  Step 2: Fetch from posts-service
    (using id from Step 1)
    posts(authorId:"1") { title id }
    Result: [{ title:"A", id:"10" },
             { title:"B", id:"11" }]

  Step 3: Stitch results:
  { user: { name:"Alice",
            posts: [{ title:"A" },
                    { title:"B" }] } }

  ENTITY REFERENCE FLOW:
  Post.author resolver returns:
    { __typename:"User", id:"1" } (reference)
  Gateway: call User.__resolveReference({id:"1"})
    -> users-service: user(id:"1") { name ... }
  Gateway: merge author fields into Post result
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: Apollo Federation's query execution flow - from a unified client query through gateway query planning, service-specific fetches, and result stitching, plus the entity reference resolution flow. (2) HOW TO READ IT: the query plan shows two sequential steps (user fetch, then post fetch using the user's ID); the Entity Reference Flow shows how `Post.author` returns a reference that the gateway resolves against the users service. (3) KEY RELATIONSHIP: the gateway's query planner generates the optimal execution plan based on the subgraph schemas; it minimizes round-trips by parallelizing independent fetches and batching entity references. (4) EDGE CASE: if a field is marked `@requires(fields: "externalField")`, the gateway must fetch the required field from the owning service before it can resolve the dependent field; this creates a sequential dependency in the query plan. (5) INSIGHT: a senior engineer monitors gateway query plan execution times to identify sequential dependencies that could be parallelized by restructuring the schema or using `@requires` more carefully.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | schema stitching, federation model |
| Application | 2 | @key directive, __resolveReference |
| Trade-off | 2 | stitching vs federation, when to use each |
| Scenario | 2 | missing resolver, composition failure |

---

**[JUNIOR] Q1 (Definition): What is the `@key` directive in Apollo Federation and what does it do?**

The `@key` directive marks an entity type with its primary key fields, enabling
cross-service references. Without `@key`, a type is a value type - it can only be
used within its owning service.

```graphql
# User entity: can be referenced across services
type User @key(fields: "id") {
  id: ID!      # The key field - used to reference User
  name: String!
  email: String!
}
# Any other service can now reference User entities
# by providing { __typename: "User", id: "123" }

# Post service can reference User by id:
type Post {
  id: ID!
  title: String!
  author: User!  # Reference to User entity
  authorId: ID!  # The key value stored in posts table
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the `@key` directive marking User as a federated entity with `id` as the key field, and a Post type that references User across service boundaries. (2) KEY MECHANISM: `@key(fields: "id")` tells the federation gateway that `id` is the stable key for User entities; the gateway uses this key to fetch User from the users service when other services need User fields. (3) WHY IT MATTERS: without `@key`, the Post service returning `author: User` would require the Post service to resolve all User fields locally (duplicating logic); with `@key`, Post returns a reference and the gateway fetches User fields from the authoritative users service. (4) WHAT BREAKS: if the key field is mutable (e.g., `email` as a key), updating a user's email invalidates all cross-service references to that user; always use immutable identifiers (primary key `id`, UUID) as `@key` fields. (5) TAKEAWAY: `@key` is the core building block of federation; every entity that is referenced across services must have a `@key`; the key must be a unique, stable, immutable identifier.

*What separates good from great:* Compound `@key` for entities with composite primary
keys. For entities like `OrderLineItem` that are uniquely identified by both `orderId`
AND `lineItemId`: `type OrderLineItem @key(fields: "orderId lineItemId") { orderId: ID!
lineItemId: ID! ... }`. The `__resolveReference` receives `{ orderId, lineItemId }` and
queries the database with both keys. Compound keys are common in relational databases
with composite primary keys; federation supports them fully.

---

**[JUNIOR] Q2 (Application): How does the federation gateway execute a cross-service query?**

When a query spans multiple services, the federation gateway generates a query plan:

1. Parse the unified query: `{ post(id:"10") { title author { name email } } }`.
2. Identify which service owns each field:
   - `Post.title` -> posts-service.
   - `Post.author` -> posts-service returns a User reference.
   - `User.name`, `User.email` -> users-service.
3. Generate the execution plan:
   - Step A: fetch `post(id:"10") { title authorId }` from posts-service.
   - Step B: call `User.__resolveReference({ id: authorId })` against users-service
     to get `{ name, email }`.
4. Execute the plan and stitch results:
   - Post: `{ title: "Hello", author: { name: "Alice", email: "a@b.com" } }`.

The query plan is generated once per query shape (not per request); plans are cached
in the gateway for frequently executed queries.

*What separates good from great:* The query plan batching optimization. If a query
returns 50 posts, each with an author, the gateway does NOT call
`User.__resolveReference` 50 times individually. It collects all 50 User ID references
from the posts-service response and sends one batch entity resolution request to the
users-service: `_entities(representations: [{ __typename: "User", id: "1" }, ...50 refs])`.
The users-service calls `__resolveReference` for each representation, and DataLoader
batches the actual database queries. This is federation's built-in equivalent of DataLoader.

---

**[SENIOR] Q3 (Trade-off): When would you choose schema stitching over Apollo Federation?**

Schema stitching is the better choice when:

1. Migrating legacy GraphQL services: existing services with established schemas cannot
   easily add `@key` directives without refactoring; stitching allows gradual migration
   by proxying the existing schemas with type merging.

2. Non-Apollo GraphQL services: federation requires Apollo-compatible server
   implementations; `@graphql-tools/stitch` works with any GraphQL server.

3. Simple two-service composition: for a monorepo with two small GraphQL services,
   federation's ceremony (`@key`, `__resolveReference`, schema registry, rover compose)
   may be overkill; stitching with simple type merging is simpler.

4. Gateway-team ownership model: in organizations where a dedicated API team controls
   the gateway and all schema decisions flow through them, schema stitching matches the
   organizational model; federation's distributed ownership requires team autonomy.

5. Non-standard data sources: stitching can merge any SDL schema, including schemas
   over gRPC, REST-wrapped as GraphQL, or generated from database introspection; some
   of these cannot expose federation-compatible subgraph schemas.

*What separates good from great:* The migration path from stitching to federation.
`@graphql-tools/stitch` and Apollo Federation v2 can coexist during migration. Start
with stitching for existing services; add federation directives to new services and
gradually migrate existing services by adding `@key` and `__resolveReference` to them.
The gateway can route to both stitched and federated subgraphs during the transition period.

---

**[JUNIOR] Q4 (Application): What is the difference between `@external` and `@provides` in Federation v1?**

`@external`: marks a field that is owned by a different service. When a service extends
a type with `@external` fields, it is saying "this field exists, but I don't own it;
the owning service provides it."

```graphql
# posts-service: extends User from users-service
extend type User @key(fields: "id") {
  id: ID! @external      # Owned by users-service
  name: String! @external # Owned by users-service
  posts: [Post!]!        # Owned by posts-service
}
# The gateway knows: when user.name is requested,
# fetch it from users-service (not posts-service)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `@external` marking fields that belong to the users service but are referenced in the posts service's User type extension. (2) KEY MECHANISM: `@external` fields are never resolved by the posts service; they are declared to express dependencies; the gateway knows to fetch them from the owning service. (3) WHY IT MATTERS: without `@external`, the gateway would expect the posts service to resolve `name` for User; it would be confused when posts service does not have the `name` resolver. (4) WHAT BREAKS: declaring `@external` on fields that the service does not own is required; forgetting `@external` on the `id` field in an extension causes composition errors. (5) TAKEAWAY: in Federation v1, all fields from other services must be declared `@external` in extensions; Federation v2 makes this less verbose by inferring external fields from the `@key` declaration.

`@provides`: tells the gateway that a resolver provides certain fields from a referenced
entity, avoiding an extra cross-service round-trip:
```graphql
type Post {
  id: ID!
  title: String!
  # @provides: this resolver returns author.name
  # so the gateway doesn't need to go to users-service
  # for name when fetching posts with author.name
  author: User! @provides(fields: "name")
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the `@provides` directive on the `author` field declaring that this resolver returns the `name` field from the User type, so the gateway can skip the extra round-trip to the users service when only `author.name` is requested. (2) KEY MECHANISM: when `@provides(fields: "name")` is declared, the gateway's query planner skips the entity resolution step to the users service for `name` specifically; the posts service resolver returns `{ __typename: 'User', id, name }` (the name pre-fetched from a denormalized column or a join). (3) WHY IT MATTERS: if `author.name` is requested on 100 posts, without `@provides` this causes 100 entity resolutions to the users service; `@provides` reduces this to zero if the posts table stores author names. (4) WHAT BREAKS: if the `author` resolver does NOT actually return `name` despite declaring `@provides(fields: "name")`, the gateway receives null for name; the declaration must match the actual resolver behavior. (5) TAKEAWAY: use `@provides` only for denormalized fields that are genuinely stored in the current service's data; do not over-declare `@provides` for fields that require cross-service fetching.

Use `@provides` when the data is already available in the post (e.g., denormalized
author name stored in the posts table) and the extra round-trip to the users service
can be avoided.

---

**[SENIOR] Q5 (Trade-off): How does Apollo Federation handle schema changes across services?**

Federation uses compile-time schema composition validation. Before deploying a service
with schema changes, run `rover compose`:

```bash
# Validate composed supergraph before deployment
rover supergraph compose \
  --config supergraph.yaml > supergraph.graphql
# If composition fails: the schema change breaks
# the federated supergraph; fix before deploying

# supergraph.yaml:
# federation_version: =2.0.0
# subgraphs:
#   users: {routing_url: ..., schema: {file: ...}}
#   posts: {routing_url: ..., schema: {file: ...}}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the `rover supergraph compose` command that validates the combined supergraph from all subgraph schemas, catching cross-service schema conflicts before deployment. (2) KEY MECHANISM: `rover compose` downloads the current subgraph schemas from the schema registry (or local files), runs the Federation composition algorithm, produces a composed supergraph SDL if successful, or detailed error messages if composition fails. (3) WHY IT MATTERS: composition validation is the safety net for distributed schema changes; if the posts service removes the `authorId` field needed by the `__resolveReference` resolver, composition fails before production deployment. (4) WHAT BREAKS: composition errors are not always obvious; "External field used as key but not present in selection set" requires understanding the composition algorithm; the Apollo Schema Registry provides better error messages than CLI composition. (5) TAKEAWAY: run `rover supergraph compose` in CI for every subgraph schema change; block deployments on composition failures; treat composition errors the same as build failures.

Breaking changes in federation:
- Removing a `@key` field: breaks all services that reference the entity by that key.
- Removing `@shareable` from a type: breaks services that were using the shared type.
- Changing a `@key` field's type: breaking change for all referencing services.
- Adding a non-nullable field to a type without a default: breaks existing queries.

*What separates good from great:* The Apollo Schema Registry as the central composition
authority. The registry stores every subgraph schema version; when any subgraph is
deployed, the registry runs composition against the current versions of all other
subgraphs; if composition fails, the deployment is blocked. This is the production-grade
safety net; manual `rover compose` is only for local development validation.

---

**[JUNIOR] Q6 (Scenario): The gateway returns null for User fields on a Post. How do you debug federation?**

Diagnosis steps:

Step 1 - Check federation query plan in Apollo Studio:
Apollo Studio shows the query execution plan; look for "Entity Resolver" steps that
return null; identify which service is failing to resolve User references.

Step 2 - Verify `__resolveReference` is implemented:
```javascript
// Check users-service resolvers:
// Is __resolveReference present?
User: {
  __resolveReference: async ({ id }, { db }) => {
    console.log('Resolving User:', id);
    const user = await db.findUser(id);
    console.log('Resolved:', user);
    return user;  // Must return full user object
  }
}
// If not implemented: users-service cannot
// resolve entity references -> null returned
```

> **Code walkthrough:** (1) WHAT IT SHOWS: adding debug logging to `__resolveReference` to trace cross-service entity resolution, identifying whether the resolver is being called and whether it returns the expected data. (2) KEY MECHANISM: the gateway calls `__resolveReference` with the reference object; adding `console.log` reveals if it is called at all, with what arguments, and what it returns; null return means the user was not found in the database. (3) WHY IT MATTERS: null User fields on a Post are often caused by either missing `__resolveReference` or a database query returning null for the authorId; logging distinguishes the two cases. (4) WHAT BREAKS: if `db.findUser(id)` receives a string ID but the database has integer IDs, the lookup fails with no error and returns null; always normalize ID types in `__resolveReference`. (5) TAKEAWAY: `__resolveReference` is the entry point for cross-service entity resolution; add structured logging in development; add metrics in production to track resolution success rates per entity type.

Step 3 - Verify `@key` field in the mutation/response:
When posts-service returns `author: { __typename: 'User', id: authorId }`, verify that
`authorId` is a valid user ID that exists in the users database. A foreign key pointing
to a non-existent user is a data integrity issue, not a federation issue.

*What separates good from great:* The federated query trace in Apollo Studio. Apollo
Studio's trace view shows the execution time breakdown per service for each field in a
federated query. A User resolution taking 200ms for 50 posts indicates DataLoader is
not batching `__resolveReference` calls; the gateway sends 50 individual entity
resolution requests instead of one batch request. Add DataLoader inside
`__resolveReference` to batch entity lookups.

---

**[SENIOR] Q7 (Application): What are the key differences between Apollo Federation v1 and v2?**

Federation v2 improvements over v1:

1. No `extend` keyword required:
   v1: `extend type User @key(fields: "id") { ... }`.
   v2: `type User @key(fields: "id", resolvable: false) { ... }`.
   Or simply define the entity in any service with the same `@key`.

2. `@shareable` directive:
   v1: types could not be owned by multiple services.
   v2: `@shareable` allows a type to be defined in multiple services; useful for value
   types that are simple enough to be duplicated safely.

3. Better composition error messages:
   v1 composition errors were cryptic; v2 errors include service name, field name,
   and specific conflict description.

4. `@override` for migrating fields between services:
   v2: `fieldName: String @override(from: "old-service")` safely migrates a field from
   one service to another; the gateway routes to the new service but falls back to the old
   service during the migration period.

5. `@interfaceObject` for schema interfaces:
   v2: an entity implementing an interface can be resolved without knowing the concrete type
   at federation boundaries; enables more complex polymorphic schemas in federation.

*What separates good from great:* The `@override` migration pattern. Migrating a field
from one service to another in v1 required coordinated deployment of both services and
the gateway to avoid a window where the field was unavailable. In v2, `@override` enables
incremental migration: add the field in the new service with `@override(from: "old-service")`;
the gateway routes to the new service; the old field remains as fallback; deploy the new
service, validate, then remove the old field in a subsequent deployment. Zero-downtime
field migration is a v2 capability with no v1 equivalent.

---

# Authentication and Authorization Patterns

---

### 🎯 Model Answer

**30 seconds:**
> Authentication (who are you?) is handled in the GraphQL context function: extract
> and validate the JWT/session token and put the user object in the context. Every
> resolver can then check `context.user`. Authorization (are you allowed?) is handled
> in resolvers or with directives. Two common patterns: (1) inline resolver checks
> (`if (!context.user.hasPermission('edit:post')) throw new GraphQLError('Forbidden')`)
> and (2) schema directives (`@auth(requires: ADMIN)`) which centralize authorization
> logic. For complex permission systems, use the "permissions-as-a-type" pattern.

**3 minutes (Senior):**
> Authentication: JWT validation in the Apollo Server context function; synchronous
> JWT.verify; put decoded user in context; never put raw token in context; handle expired
> token gracefully (return null user, let resolvers decide). Authorization has three
> patterns with different trade-offs: (1) Inline checks - simple but scattered;
> every resolver repeats the check; forget one = security hole. (2) Schema directives
> (`@auth`, `@hasRole`) - centralized, visible in schema, but complex implementation
> with directive transformers; supports field-level auth visibility. (3) GraphQL Shield
> (middleware) - define authorization rules in a separate rule tree that mirrors the
> schema; middleware approach; clean separation between auth and business logic.
> The production concern beyond authorization: information disclosure. In REST, a 403
> response indicates the resource exists; in GraphQL, returning null for an unauthorized
> field may reveal that the field exists (vs the field not existing). Use `FORBIDDEN`
> errors for visibility-critical fields; use null with no error for fields that should
> be invisible when unauthorized.

**Blank Mind Recovery:**

**(1) Restate:** "Auth: JWT validation in context function. User in `context.user`.
Authorization: (1) inline resolver checks, (2) schema directives `@auth(requires: ADMIN)`,
(3) GraphQL Shield middleware rules tree. Security: information disclosure via null vs
error (null hides existence; error reveals it). Field-level vs type-level permissions."

---

### 📘 Concept Explanation

**Authentication and Authorization Architecture:**

```text
GRAPHQL AUTHENTICATION FLOW:

  Client Request
  Authorization: Bearer eyJhbGci...
          |
  Apollo Server: context function
    const token = req.headers.authorization
    const user = verifyJWT(token) or null
    return { user, db, loaders }
          |
  GraphQL resolvers receive context:
    resolver(parent, args, { user, db }) {
      // user is verified or null
    }

  AUTHORIZATION PATTERNS:

  PATTERN 1 - Inline checks:
  deletePost: (_, { id }, { user }) => {
    if (!user) throw new Error('Unauthenticated')
    if (!user.hasRole('EDITOR'))
      throw new Error('Forbidden')
    return db.deletePost(id)
  }
  RISK: Scattered checks; easy to miss one field

  PATTERN 2 - Schema directives:
  type Mutation {
    deletePost(id:ID!): Post
      @auth(requires: EDITOR)
  }
  # Auth check runs BEFORE resolver; centralized

  PATTERN 3 - GraphQL Shield (middleware):
  const permissions = shield({
    Mutation: {
      deletePost: isAuthenticated && hasRole('EDITOR')
    }
  })
  # Declarative rule tree; cleanest separation
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the three GraphQL authorization patterns showing how authentication (token validation to user) and authorization (permission check on user) are structurally different concerns and can be implemented at different layers. (2) HOW TO READ IT: the top section shows authentication flow (universal - always in context function); the AUTHORIZATION PATTERNS section shows three approaches with increasing abstraction and decreasing scattering of auth logic. (3) KEY RELATIONSHIP: authentication is a cross-cutting concern that must run for every request; authorization is field/mutation-specific and can be implemented at different granularities (schema, middleware, inline). (4) EDGE CASE: if the JWT is expired or malformed, `verifyJWT()` throws; the context function must catch this and return null for the user; resolvers then see `context.user = null` and can throw `UNAUTHENTICATED` if needed. (5) INSIGHT: a senior engineer uses pattern 2 (directives) or 3 (Shield) for authorization to ensure no resolver accidentally bypasses auth checks; inline pattern 1 scales poorly because every new resolver requires manual auth check insertion.

---

### 💻 Code Example

```javascript
// BAD: Authentication in resolvers (insecure)
// Authorization missing (any field is public)

const resolvers = {
  Query: {
    // BAD: authenticates inside resolver
    // Other resolvers may forget to authenticate
    me: async (_, __, { req }) => {
      const token = req.headers.authorization;
      if (!token) return null;
      const user = jwt.verify(token, SECRET);
      return db.findUser(user.id);
      // Every resolver must repeat this
      // Forget once -> unauthenticated access
    },
    // BAD: No auth check at all!
    adminStats: async (_, __, { db }) =>
      db.getAdminStats()
      // Anyone can access admin statistics!
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two security anti-patterns - authenticating inside individual resolvers (requires every resolver to repeat the auth logic) and a resolver with no authentication check at all (unauthorized access to admin data). (2) KEY MECHANISM: when authentication is in individual resolvers, each new resolver written by any developer must remember to include the auth check; the discipline breaks over time; one forgotten check exposes protected data. (3) WHY IT MATTERS: `adminStats` is accessible without authentication; any user can call `{ adminStats { ... } }` and receive sensitive data; this is a data exposure vulnerability. (4) WHAT BREAKS: JWT verification throwing on invalid tokens in the resolver means a malformed token causes a 500 server error rather than a 401 unauthorized response; auth errors should be handled gracefully. (5) TAKEAWAY: NEVER authenticate inside individual resolvers; ALWAYS authenticate in the context function and put the user in context; let resolvers check `context.user`.

```javascript
// GOOD: Authentication in context, authorization
// in resolvers or Shield

const jwt = require('jsonwebtoken');
const { AuthenticationError,
        ForbiddenError } = require('apollo-server');

// Apollo Server context function:
// Called once per request; user available to all resolvers
const server = new ApolloServer({
  context: ({ req }) => {
    let user = null;
    try {
      const token = req.headers.authorization
        ?.replace('Bearer ', '');
      if (token) {
        user = jwt.verify(token, process.env.JWT_SECRET);
        // user = { id, email, roles, iat, exp }
      }
    } catch (err) {
      // Expired, malformed, or invalid token
      // null user: resolvers decide how to handle
      if (!(err instanceof jwt.TokenExpiredError
            || err instanceof jwt.JsonWebTokenError)) {
        throw err;  // Rethrow unexpected errors
      }
    }
    return { user, db, loaders };
  }
});

// Resolver-level authorization:
const resolvers = {
  Query: {
    me: (_, __, { user }) => {
      if (!user) throw new AuthenticationError(
        'You must be logged in'
      );
      return db.findUser(user.id);
    },

    // ADMIN-only query:
    adminStats: (_, __, { user }) => {
      if (!user) throw new AuthenticationError(
        'Authentication required'
      );
      if (!user.roles.includes('ADMIN')) {
        throw new ForbiddenError(
          'Admin role required'
        );
      }
      return db.getAdminStats();
    }
  },

  // Field-level authorization:
  User: {
    email: (user, _, { user: currentUser }) => {
      // Users can see their own email; admins see all
      if (currentUser?.id === user.id
          || currentUser?.roles.includes('ADMIN')) {
        return user.email;
      }
      return null;  // Hide email from other users
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: authentication in the context function (universal, once per request) and authorization in resolvers (field-specific), with field-level access control on User.email that hides data from unauthorized users rather than throwing errors. (2) KEY MECHANISM: `jwt.verify(token, secret)` in the context function runs once per request; the decoded user payload (including `id`, `roles`) is available to all resolvers via `context.user`; no resolver needs to parse the JWT. (3) WHY IT MATTERS: field-level authorization (`User.email` returning null) enables the API to serve partial data - authenticated users see their own email; other users see null; both get a valid response. (4) WHAT BREAKS: catching `TokenExpiredError` but not re-throwing unexpected JWT errors hides real bugs (wrong `JWT_SECRET`, algorithm mismatch); re-throw non-JWT errors to expose configuration issues. (5) TAKEAWAY: context function handles authentication (once, centrally); resolvers handle authorization (where needed, at the appropriate granularity: query, mutation, or field).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Authentication in GraphQL: validate the JWT token in the Apollo Server context
> function (called once per request); put the decoded user in the context; resolvers
> check `context.user`. Authorization: in each resolver, check if `context.user` has
> the required role or permission before returning data. For admin-only queries, throw
> `AuthenticationError` if user is null, and `ForbiddenError` if user lacks the role.
> Field-level authorization: return null instead of throwing if unauthorized - this
> hides the field value without exposing errors.

---

**Senior / Staff (5+ years):**
> Production GraphQL auth has several layers: (1) Transport-level TLS (mandatory, not
> optional). (2) Authentication in context function - JWT verification once per request;
> user in context; handle token expiry gracefully. (3) Authorization patterns - inline
> (scattered, error-prone), directives (centralized, visible in schema), Shield
> (middleware, declarative). (4) Information disclosure - returning null vs throwing an
> error on unauthorized access; null reveals only that the field exists; FORBIDDEN error
> reveals that data exists AND you don't have access; choose based on sensitivity. (5)
> GraphQL introspection - disable in production to prevent schema reconnaissance; attackers
> use introspection to identify auth-restricted fields. (6) Rate limiting per user to
> prevent auth bypass via query amplification.

---

### ⚠️ Common Misconceptions

**Misconception: "Returning null for unauthorized fields is always safer than throwing an error."**

Returning null for an unauthorized field hides the field value but reveals that the
field EXISTS in the schema. A different approach: use schema-level visibility to hide
the field entirely from unauthorized users. With graphql-shield `hideFieldsFromSchema`,
unauthorized users see the schema without the field, and attempts to query it return
an "unknown field" error rather than a permission error - complete information hiding.
However, schema-based hiding requires separate schema views per user role, which adds
complexity. The practical recommendation: throw `ForbiddenError` for high-sensitivity
fields (medical records, financial data) where the existence of data is also sensitive;
return null for low-sensitivity fields (extra profile information, preference flags)
where knowing the field exists but having no access is acceptable. The choice between
null and error is a security design decision, not a convention.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: JWT secret exposed in error messages during token verification failure.**

Symptom: production users receive error messages containing technical JWT details;
error logs expose the JWT algorithm or secret hint.

```javascript
// BAD: JWT error exposed to client
const server = new ApolloServer({
  context: ({ req }) => {
    const token = req.headers.authorization;
    // BAD: jwt.verify throws; error propagates to client
    const user = jwt.verify(token, SECRET);
    // Error: "JsonWebTokenError: invalid signature"
    // This message reaches the GraphQL response
    // Could expose algorithm info or secret hints
    return { user };
  },
  // BAD: formatError passes raw errors to client
});

// GOOD: Sanitize auth errors before client exposure
// BAD: (see above - JWT errors must be caught)
const server = new ApolloServer({
  context: ({ req }) => {
    let user = null;
    try {
      const token = req.headers.authorization
        ?.replace('Bearer ', '');
      if (token) {
        user = jwt.verify(token, process.env.JWT_SECRET);
      }
    } catch (err) {
      // Log full error server-side for debugging
      logger.warn('JWT verification failed', {
        error: err.message,
        // Do NOT log the token or secret
      });
      // Return null user (no client error)
      // Resolvers handle unauthenticated case
    }
    return { user, db };
  },
  // formatError: sanitize all errors for client
  formatError: (err) => {
    // Log full error server-side
    logger.error(err.extensions?.code, err);
    // Return sanitized error to client
    return {
      message: err.message,
      locations: err.locations,
      path: err.path,
      extensions: {
        code: err.extensions?.code || 'INTERNAL_ERROR'
      }
      // Remove: stacktrace, originalError
    };
  }
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the JWT error exposure vulnerability and the fix - catching JWT errors in the context function and sanitizing all errors via `formatError` to prevent internal implementation details from reaching the client. (2) KEY MECHANISM: `jwt.verify` throws `JsonWebTokenError` or `TokenExpiredError` with messages like "invalid signature"; these messages reveal the JWT algorithm used; the `try/catch` block catches them, logs server-side, and returns `null` for `user` (graceful degradation). (3) WHY IT MATTERS: "invalid signature" in a client-visible error message is an OWASP Top 10 security misconfiguration; it reveals the authentication mechanism's internal details; attackers use this to guide forgery attempts. (4) WHAT BREAKS: `formatError` that omits `err.path` breaks Apollo Client error handling for partial responses; always include `message`, `locations`, `path`, and a sanitized `extensions.code`. (5) TAKEAWAY: NEVER let raw JWT, database, or framework errors reach the client; always wrap with `formatError` in Apollo Server; log full errors server-side; send only sanitized error codes and user-friendly messages to clients.

---

### ⚖️ Comparison Table

| Pattern | Auth Logic Location | Centralization | Complexity | Best For |
|---|---|---|---|---|
| Inline resolver checks | Each resolver | Low (scattered) | Low | Small APIs, few auth rules |
| Schema directives `@auth` | Schema SDL + transformer | High (schema visible) | Medium | Field-level visibility |
| GraphQL Shield | Middleware rule tree | High (separate file) | Medium | Complex permission systems |
| graphql-auth-directives | Schema directives | High | Low (library) | Standard RBAC patterns |
| Custom middleware | Middleware layer | High | High | Non-standard requirements |

---

### 🏛️ System Design

*(Omit: L3 keyword; multi-tenant auth, federated identity across microservices, and RBAC schema design covered in L5 Architecture entry.)*

---

### 📊 Diagram

```text
GRAPHQL AUTHORIZATION LAYERS:

  Request
    |
  [Transport Layer]
    TLS / HTTPS (mandatory)
    |
  [Context Layer] - once per request
    Extract token -> verify JWT
    context.user = decoded payload or null
    |
  [Schema Layer] - optional
    @auth, @hasRole directives
    Checked before resolver runs
    |
  [Resolver Layer] - per field
    if (!user) throw AuthenticationError
    if (!user.hasRole) throw ForbiddenError
    return data
    |
  [Field Layer] - optional
    return null vs data
    based on user.id === field.userId
    |
  [Error Layer] - formatError
    Sanitize errors before client
    Remove stack traces
    Translate to error codes

  AUTHORIZATION MATRIX:
  Field          | Anonymous | User | Editor | Admin
  -------------- | --------- | ---- | ------ | -----
  Query.me       | UNAUTH    | YES  | YES    | YES
  User.email     | null      | own  | own    | all
  Mutation.post  | UNAUTH    | YES  | YES    | YES
  Mutation.delete| UNAUTH    | own  | all    | all
  Query.admin    | UNAUTH    | FORB | FORB   | YES
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the layered authorization architecture from transport-level TLS through context authentication, schema directives, resolver checks, field-level visibility, and error sanitization, plus an authorization matrix showing different access levels per role. (2) HOW TO READ IT: each layer adds an authorization gate; transport (cannot bypass), context (always runs), schema (optional centralization), resolver (where most auth lives), field (fine-grained visibility), error (sanitization). (3) KEY RELATIONSHIP: the context layer is foundational - it provides `user` to all other layers; without centralized authentication in context, every subsequent layer must re-authenticate. (4) EDGE CASE: the authorization matrix shows `User.email = own/all` (not YES/NO) for "User" and "Admin" roles; this is field-level authorization that cannot be expressed as a simple allow/deny; it requires access to both the requesting user and the field's parent object. (5) INSIGHT: a senior engineer uses the authorization matrix to identify all required auth rules before implementation; a cell in the matrix = one auth rule; count the rules to estimate implementation complexity; 50+ rules suggest GraphQL Shield is worth the setup cost.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | authentication vs authorization, patterns |
| Application | 2 | JWT context, field-level auth |
| Security | 3 | information disclosure, error sanitization, introspection |
| Scenario | 2 | missing auth check, Shield implementation |

---

**[JUNIOR] Q1 (Definition): What is the difference between authentication and authorization in GraphQL?**

Authentication: verifying the identity of the caller (who are you?). In GraphQL:
extract JWT from `Authorization: Bearer <token>` header; verify signature and expiry;
decode the payload to get `{ id, email, roles }`. Result: `context.user`.

Authorization: verifying the caller has permission for the operation (are you allowed?).
In GraphQL: check `context.user.roles` or `context.user.id` before returning data or
executing mutations.

They are separate concerns at separate layers:
- Authentication: Apollo Server context function (once per request, before any resolver).
- Authorization: resolvers (per field, per mutation) or schema directives (per field in SDL).

```javascript
// Authentication: context function
context: ({ req }) => {
  const user = verifyToken(req.headers.authorization);
  return { user }; // user = null if unauthenticated
},

// Authorization: resolver
me: (_, __, { user }) => {
  if (!user) throw new AuthenticationError('Login first');
  // user is verified; now check what user can do
  return db.getUser(user.id);
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the clean separation between authentication (context function, once) and authorization (resolver, per operation). (2) KEY MECHANISM: `verifyToken` validates the JWT and returns the decoded user or null; resolvers check `context.user` without re-parsing the token. (3) WHY IT MATTERS: separation allows context to handle authentication consistently; resolvers focus on authorization (business logic). (4) WHAT BREAKS: putting authentication logic in resolvers means some resolvers might skip it; centralization in context ensures no resolver can accidentally bypass authentication. (5) TAKEAWAY: authentication in context (always), authorization in resolvers (where needed) - this is the universal GraphQL auth pattern.

---

**[JUNIOR] Q2 (Application): How do you implement JWT authentication in an Apollo Server context function?**

```javascript
const jwt = require('jsonwebtoken');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => {
    let user = null;

    // Step 1: Extract token
    const authHeader = req.headers.authorization;
    const token = authHeader?.startsWith('Bearer ')
      ? authHeader.slice(7)
      : null;

    // Step 2: Verify token (if present)
    if (token) {
      try {
        user = jwt.verify(
          token,
          process.env.JWT_SECRET
        );
        // user = { id, email, roles, iat, exp }
      } catch (err) {
        // Invalid or expired token
        // Return null user; resolvers handle
        // Do NOT throw here - let resolvers decide
        // if authentication is required for their field
      }
    }

    // Step 3: Return context with user + services
    return { user, db, loaders };
  }
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a complete JWT authentication context function with proper token extraction, verification, and graceful error handling. (2) KEY MECHANISM: `jwt.verify(token, secret)` validates the signature and expiry in one call; the decoded payload (`{ id, email, roles }`) is stored in `user`; the `try/catch` prevents JWT errors from propagating to the client. (3) WHY IT MATTERS: `try/catch` in the context function is essential; without it, a malformed token causes a 500 error instead of returning null and letting resolvers handle the unauthenticated case gracefully. (4) WHAT BREAKS: hardcoding `JWT_SECRET` instead of using `process.env.JWT_SECRET` is a secret exposure vulnerability; secrets must come from environment variables or a secrets manager, never from source code. (5) TAKEAWAY: the context function pattern is standard; copy it exactly; the key decisions are: extract token, verify (try/catch), return null on failure; resolvers handle the null user case per their own authorization requirements.

*What separates good from great:* Token refresh in the context function. Long-lived JWTs
are a security risk; short-lived JWTs (15 minutes) require refresh. The context function
can detect an expired token (caught `TokenExpiredError`) and add a flag to the response:
`context.tokenExpired = true`. The resolver for `me` checks `context.tokenExpired` and
returns a specific error code (`TOKEN_EXPIRED`). The client receives this code and
automatically calls the refresh token endpoint to get a new JWT. This is the production
JWT refresh flow; pure server-side handling without client-side token expiry detection.

---

**[SENIOR] Q3 (Security): What is information disclosure in GraphQL and how do you prevent it?**

Information disclosure: when an API reveals more than intended, giving attackers insight
into the system structure, data existence, or access controls.

GraphQL-specific information disclosure risks:

1. Schema introspection: `{ __schema { types { name } } }` reveals all types, fields,
   arguments, directives. Attackers map the API surface.
   Prevention: disable introspection in production.
   ```javascript
   const server = new ApolloServer({
     introspection: process.env.NODE_ENV !== 'production'
   });
   ```

   > **Code walkthrough:** (1) WHAT IT SHOWS: disabling introspection in production via Apollo Server's built-in `introspection` flag, while leaving it enabled in development. (2) KEY MECHANISM: `process.env.NODE_ENV !== 'production'` evaluates to `true` in development and `false` in production; Apollo Server returns a `GraphQLError` for `__schema` and `__type` queries when introspection is disabled. (3) WHY IT MATTERS: introspection in production enables attackers to map the entire API surface; disabling it removes schema reconnaissance as an attack vector. (4) WHAT BREAKS: disabling introspection breaks GraphiQL, Apollo Studio Explorer, and code generators in production; clients using introspection for query validation will fail; always keep enabled in development and staging. (5) TAKEAWAY: `introspection: process.env.NODE_ENV !== 'production'` is the universal safe default; it is a one-line security improvement for every production GraphQL API.

2. Error messages: stack traces, SQL errors, or JWT algorithm hints in error responses.
   Prevention: `formatError` in Apollo Server to sanitize all errors.

3. Null vs Error for unauthorized fields: returning `{ user: { email: null } }` reveals
   that the email field exists; returning FORBIDDEN reveals the field exists AND the user
   lacks permission. Both reveal existence.
   Prevention for high-sensitivity: use schema-level field hiding (graphql-shield
   `hideFieldsFromSchema`) to make the field invisible to unauthorized users.

4. Timing attacks: an authentication check that returns "user not found" in 5ms vs
   "wrong password" in 50ms reveals user existence.
   Prevention: normalize response times for auth failures with `crypto.timingSafeEqual`.

5. Query error messages: detailed validation errors that reveal schema structure.
   Prevention: limit introspection and add generic error messages for non-development environments.

*What separates good from great:* The difference between `null` and `undefined` for
auth-hidden fields. In JSON, `null` explicitly indicates "no value" (field exists, is
empty). `undefined` causes the field to be omitted from the response entirely (field
appears to not exist). When hiding a field from unauthorized users, omitting it (returning
`undefined`) is more secure than returning `null`. However, GraphQL spec requires
returning `null` for nullable fields and throwing an error for non-nullable fields; there
is no "omit from response" option for individual fields. Schema-level hiding (type
definitions per role) is the only way to completely hide fields from the schema and
response.

---

**[JUNIOR] Q4 (Application): How do you implement field-level authorization in GraphQL?**

Field-level authorization: different users see different fields of the same type.

```javascript
const resolvers = {
  User: {
    // Public: everyone can see
    name: (user) => user.name,
    bio: (user) => user.bio,

    // Restricted: only own account or admins
    email: (user, _, { user: currentUser }) => {
      // Check if currentUser can see this user's email
      if (!currentUser) return null;
      if (currentUser.id === user.id) return user.email;
      if (currentUser.roles.includes('ADMIN')) {
        return user.email;
      }
      return null;  // Unauthorized: hide email
    },

    // Highly restricted: only admins
    internalNotes: (user, _, { user: currentUser }) => {
      if (!currentUser?.roles.includes('ADMIN')) {
        throw new ForbiddenError(
          'Admin only'
        );
      }
      return user.internalNotes;
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: field-level authorization on the User type with three access levels: public (name, bio), restricted by ownership or role (email), and admin-only with explicit error (internalNotes). (2) KEY MECHANISM: field resolvers receive `{ user: currentUser }` from context; the field resolver checks the relationship between `currentUser` and the parent `user` object (owns their own data) or role-based access. (3) WHY IT MATTERS: field-level auth enables a single User query to return different data based on the requesting user; one API endpoint, multiple authorization levels; no need for separate admin/user API versions. (4) WHAT BREAKS: returning null silently (email) vs throwing an error (internalNotes) is a deliberate choice; null says "you don't have access but I won't alert you"; ForbiddenError says "you tried to access something you're not allowed to". (5) TAKEAWAY: use null for low-sensitivity fields where partial data is acceptable; use ForbiddenError for high-sensitivity fields where the attempt should be logged and the user alerted; document the authorization policy for each field.

---

**[SENIOR] Q5 (Application): How does GraphQL Shield simplify complex authorization logic?**

GraphQL Shield defines a permissions middleware tree that mirrors the schema:

```javascript
const { shield, rule, and, or, not }
  = require('graphql-shield');

// Define reusable rules:
const isAuthenticated = rule({ cache: 'contextual' })(
  async (parent, args, ctx) => {
    return ctx.user !== null
      || new Error('Not authenticated');
  }
);

const isAdmin = rule({ cache: 'contextual' })(
  async (parent, args, { user }) => {
    return user?.roles.includes('ADMIN')
      || new Error('Admin role required');
  }
);

const isPostOwner = rule({ cache: 'strict' })(
  async (parent, { id }, { user, db }) => {
    const post = await db.getPost(id);
    return post.authorId === user?.id
      || new Error('Post ownership required');
  }
);

// Permissions tree mirrors the schema:
const permissions = shield({
  Query: {
    me: isAuthenticated,
    adminStats: isAdmin,
    post: allow  // Public
  },
  Mutation: {
    createPost: isAuthenticated,
    updatePost: and(isAuthenticated, isPostOwner),
    deletePost: or(isAdmin, isPostOwner)
  },
  User: {
    email: isAuthenticated,  // Any authenticated user
    internalNotes: isAdmin
  }
}, {
  // Authorization failures return null or error:
  fallbackError: 'Unauthorized',
  allowExternalErrors: true
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: GraphQL Shield defining reusable authorization rules (`isAuthenticated`, `isAdmin`, `isPostOwner`) and combining them with logical operators (`and`, `or`) in a permissions tree that mirrors the schema structure. (2) KEY MECHANISM: Shield wraps all resolvers with the matching permission rule; the rule runs before the resolver; if the rule returns false or an Error, the resolver is not called and Shield returns the error; if the rule passes, the resolver runs normally. (3) WHY IT MATTERS: the permissions tree is in one file and mirrors the schema; adding a new query requires adding one line to the permissions tree; the authorization rules are auditable as a standalone document; no need to review every resolver for auth checks. (4) WHAT BREAKS: `cache: 'contextual'` caches the rule result per request context (reuse result within one request); `cache: 'strict'` caches per `{ parent, args, context }` (reuse across calls with same arguments); using `contextual` for rules that depend on the parent object (like `isPostOwner`) is incorrect - use `strict` or `no-cache`. (5) TAKEAWAY: GraphQL Shield is the production choice for complex authorization; define atomic rules, compose with `and`/`or`, declare in a schema-mirroring tree; the permissions tree is your authorization documentation.

---

**[SENIOR] Q6 (Security): How do you prevent authorization bypass via introspection?**

Introspection reveals the full schema: all types, fields, arguments, directives, and
their descriptions. Attackers use introspection to:
1. Identify admin-only fields (`adminStats`, `deleteUser`) and attempt to access them.
2. Discover `@deprecated` fields that may have looser access controls.
3. Find fields accepting sensitive inputs (user IDs, organization IDs) and attempt
   enumeration attacks.

Prevention:
```javascript
// Disable introspection in production:
const server = new ApolloServer({
  introspection: process.env.NODE_ENV !== 'production',
  // production: false, development/staging: true
});

// For APIs that need introspection for partners:
// Add authentication to introspection queries:
const server = new ApolloServer({
  validationRules: [
    (context) => ({
      Field: {
        enter({ name }) {
          if (name.value.startsWith('__')
              && !context.options.context.user) {
            context.reportError(
              new GraphQLError('Introspection disabled')
            );
          }
        }
      }
    })
  ]
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two approaches to blocking introspection - completely disabling it in production (simplest) and conditionally blocking it for unauthenticated users (for APIs that need introspection for authenticated partners). (2) KEY MECHANISM: the first approach uses Apollo Server's built-in `introspection: false` flag; the second uses a custom validation rule that checks if the query starts with `__` (introspection queries) and rejects them for unauthenticated contexts. (3) WHY IT MATTERS: disabling introspection is an OWASP API Security Top 10 recommendation for production GraphQL APIs; it significantly reduces the attack surface by denying schema reconnaissance. (4) WHAT BREAKS: disabling introspection breaks GraphiQL, Apollo Studio, and any client that uses `__schema` for code generation; only disable in production, not in development or CI environments. (5) TAKEAWAY: use `introspection: process.env.NODE_ENV !== 'production'` as the universal pattern; development and staging have full introspection; production is locked down.

*What separates good from great:* Introspection for authenticated partners with schema
redaction. Some APIs need to expose introspection to authenticated partners (API
consumers building their own clients) but not to the general public. The approach: allow
introspection only with a valid partner API key (different from user authentication);
return a schema that excludes internal/admin types (type filtering in the introspection
response). This is a custom introspection middleware that filters the `__schema` response
based on the caller's role - exposing only the public types to the public schema view and
the full schema to admins and partners.

---

**[SENIOR] Q7 (Scenario): A user can access other users' private data. How do you debug the authorization failure?**

Scenario: a security report indicates user A can see user B's private email address in
a `{ user(id: "B") { email } }` query.

Step 1 - Locate the `User.email` resolver:
```javascript
// Find the email resolver:
User: {
  email: (user, _, { user: currentUser }) => {
    // Is this resolver even checking authorization?
    // console.log current state:
    console.log({
      requestingUser: currentUser?.id,
      targetUser: user.id,
      sameUser: currentUser?.id === user.id
    });
    // If this log shows different IDs but still
    // returns the email: authorization logic is wrong
    return user.email;
    // BUG: No auth check! Returns email for anyone
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a diagnostic `console.log` in the `User.email` resolver to verify that the requesting user and target user IDs are being compared correctly, revealing whether the authorization logic is present and functioning. (2) KEY MECHANISM: the log shows `requestingUser: A, targetUser: B, sameUser: false`; if email is returned despite `sameUser: false`, the authorization check is missing or buggy. (3) WHY IT MATTERS: missing field-level authorization is the most common GraphQL security vulnerability; it is easy to add a field to the type and forget to add the authorization check; the diagnostic approach quickly confirms whether auth logic exists. (4) WHAT BREAKS: logging user IDs in production logs is a privacy concern; use this logging only in development/staging; in production, use structured logging with user IDs that are only accessible to authorized operations staff. (5) TAKEAWAY: for any security report of data exposure, the first diagnostic step is to check if a resolver for the affected field exists AND if it contains authorization logic; many cases are simply missing the auth check.

Step 2 - Add the missing authorization check:
```javascript
User: {
  email: (user, _, { user: currentUser }) => {
    if (!currentUser) return null;
    if (currentUser.id === user.id
        || currentUser.roles.includes('ADMIN')) {
      return user.email;
    }
    return null;  // Unauthorized: hide email
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the authorization fix for the User.email resolver - adding an ownership check so only the user themselves or admins can see the email address. (2) KEY MECHANISM: `currentUser?.id === user.id` compares the authenticated user's ID with the parent object's ID; if they match, the requester owns this User record; admins bypass the check via `roles.includes('ADMIN')`. (3) WHY IT MATTERS: this two-line fix closes the data exposure vulnerability; the return null path silently hides the unauthorized value without revealing access control details. (4) WHAT BREAKS: if `currentUser.id` and `user.id` are different types (string vs number), the strict equality check (`===`) always returns false even for the same user; normalize IDs to the same type. (5) TAKEAWAY: every sensitive field resolver should follow this pattern: check ownership OR admin role; return data if authorized; return null (or throw) if not; add a regression test to prevent future regressions.

Step 3 - Add a test to prevent regression:
```javascript
it('hides email for other users', async () => {
  const result = await gql({ query: '{ user(id:"B")
    { email } }', user: { id: 'A', roles: [] } });
  expect(result.data.user.email).toBeNull();
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a regression test that verifies user A cannot see user B's email after the authorization fix. (2) KEY MECHANISM: the test calls the `user(id: "B")` query with user A's context; the test expects `email` to be null; if the auth check is removed in the future, this test fails and catches the regression. (3) WHY IT MATTERS: authorization bugs are often reintroduced during refactoring; automated tests are the only reliable prevention for authorization regressions. (4) WHAT BREAKS: if the test uses a real database instead of a mock, it requires test data setup (user A and user B must exist); use mocking for the user context and the database response to keep the test fast and isolated. (5) TAKEAWAY: for every security fix, add a test that reproduces the original vulnerability; the test name should be descriptive enough to serve as documentation for the authorization requirement.

*What separates good from great:* The authorization audit across all sensitive fields.
After finding one unauthorized field, run an authorization audit: list all fields in the
schema that handle sensitive data (email, phone, SSN, payment info, private notes); for
each, verify the resolver contains an authorization check. Automate this with a schema
introspection script that flags fields with certain name patterns (`email`, `phone`,
`ssn`, `token`, `password`) and verifies they have authorization logic in the resolver.
An authorization audit script prevents similar vulnerabilities from existing in parallel.
