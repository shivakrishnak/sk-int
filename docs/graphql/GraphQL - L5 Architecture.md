---
layout: default
title: "GraphQL - L5 Architecture"
parent: "GraphQL"
nav_order: 12
permalink: /graphql/l5-architecture/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 23 | [Apollo Federation: Subgraphs and Supergraph](#apollo-federation-subgraphs-and-supergraph) | ★★★ |

---

# Apollo Federation: Subgraphs and Supergraph

---

### 🎯 Model Answer

**30 seconds:**
> Apollo Federation composes multiple independent GraphQL services (subgraphs) into a
> single unified API (supergraph) via a gateway. Each subgraph owns a domain slice;
> the gateway plans and executes queries by distributing fields to the right subgraph.
> Key Federation 2 concepts: `@key` (entity identity), `@extends` replaced by
> distributed `type` definitions, `@requires` (inter-subgraph field dependencies),
> `@provides` (optimization hint), and the schema registry (supergraph SDL).

**3 minutes (Senior):**
> Federation solves the organizational scaling problem: one GraphQL monolith becomes
> a bottleneck when 10 teams all work in one schema. Federation lets each team own
> their subgraph schema independently. The gateway (Apollo Router) reads a supergraph
> SDL published to the schema registry and plans query execution: given a client query,
> which fields come from which subgraph? This is the Query Plan. Entity resolution is
> the core mechanism: the `User` type has `@key(fields: "id")`; the Users subgraph
> resolves `User.id`, `User.name`, `User.email`; the Posts subgraph defines `User @key`
> and extends `Post.author: User` by reference; the gateway fetches `Post.author.id`
> from Posts, then uses it to call `Users._entities({ id: ... })` to resolve the full
> `User` object. The `@requires` directive declares that a subgraph field requires
> another field from the same entity (possibly from a different subgraph) to resolve.
> Federation 2 trade-offs: operational complexity (schema registry, gateway, composition
> checks); latency overhead (multi-subgraph queries require gateway coordination); benefit:
> independent team ownership with a unified API surface.

**Blank Mind Recovery:**

**(1) Restate:** "Federation: multiple subgraph GraphQL services -> gateway composes into
one API. Subgraphs use `@key` to declare entity identity; gateway distributes fields to
the right subgraph. `@requires`: this field needs another field to resolve. `@provides`:
this subgraph can provide this field from an entity (optimization). Schema registry:
published supergraph SDL. Gateway (Apollo Router): plans queries, calls subgraphs,
assembles responses. Trade-off: complexity + latency overhead vs independent team
ownership."

---

### 📘 Concept Explanation

**Federation Architecture Components:**

```text
APOLLO FEDERATION 2 ARCHITECTURE:

SCHEMA REGISTRY (Apollo Studio / Rover)
  Subgraph A SDL (users.graphql)
  Subgraph B SDL (posts.graphql)
  Subgraph C SDL (orders.graphql)
  -> Composition check (valid supergraph?)
  -> Publish supergraph SDL

GATEWAY (Apollo Router)
  - Reads supergraph SDL
  - Receives client requests
  - Builds query plan (which fields -> which subgraph)
  - Executes parallel subgraph calls
  - Assembles results

SUBGRAPH A (Users Service)
  type User @key(fields: "id") {
    id: ID!
    name: String!
    email: String!
  }

SUBGRAPH B (Posts Service)
  type Post @key(fields: "id") {
    id: ID!
    title: String!
    author: User!      # <- Uses User from Subgraph A
  }
  extend type User @key(fields: "id") {
    # Reference entity from Subgraph A
    # Posts subgraph can add fields to User:
    posts: [Post!]!
  }

CLIENT QUERY FLOW:
  query { post(id:"1") { title author { name email } } }
          |
    [Gateway: build query plan]
    - Fetch Post(id:1) from Posts subgraph
      - Get: title, author.id
    - Fetch User(_entities: [{id: author.id}]) from Users
      - Get: name, email
          |
    [Execute plan in parallel where possible]
          |
    [Assemble: { post: { title, author: {name,email} } }]
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the four components of Apollo Federation 2 - schema registry, gateway, subgraphs A/B/C, and the client query execution flow showing how a single client query is decomposed, distributed, and assembled. (2) HOW TO READ IT: the registry stores SDL; the gateway reads the supergraph SDL; subgraphs define their own types; the query flow shows the gateway decomposing a query into two subgraph requests and assembling the result. (3) KEY RELATIONSHIP: the `User` type is defined in Subgraph A (the authoritative owner); Subgraph B references it via `@key`; the gateway knows to fetch User fields from Subgraph A using the `_entities` query; this is entity resolution. (4) EDGE CASE: if Subgraph A (Users) is unavailable, any query that requires User fields returns null for those fields; partial results are returned if the gateway is configured to tolerate subgraph failures. (5) INSIGHT: a senior engineer recognizes that entity resolution adds one additional subgraph call per entity type in the response; a query for `Post.author.profile.settings` may require 3 subgraph hops (Posts -> Users -> Profiles -> Settings); minimizing hops is a key Federation query plan optimization.

---

### 💻 Code Example

```javascript
// BAD: GraphQL monolith - all types in one service
// This works but creates organizational problems:
// - 5 teams all edit one schema file
// - Any schema change requires full service deploy
// - No team ownership boundaries
// - One service scales all operations together
// -> Add users, posts, orders, payments all in one

// users/resolvers.js + posts/resolvers.js +
// orders/resolvers.js all in ONE express server
// This is fine for 1 team, unsustainable for 5+ teams.
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the organizational problem with a GraphQL monolith - all types, resolvers, and mutations in one service - which creates coordination overhead as the team grows. (2) KEY MECHANISM: a single GraphQL service is simple to operate but creates contention when multiple teams contribute; every schema change requires a PR review from all teams; a bug in the orders resolver can break user queries (shared deployment). (3) WHY IT MATTERS: Federation is not a technical choice for small teams; it is an organizational choice that trades operational complexity for team independence; adopt Federation when you have 3+ teams with distinct domain boundaries. (4) WHAT BREAKS: prematurely adopting Federation adds gateway overhead (~10ms), schema registry operations, and composition checks to a codebase that didn't need it; the trade-off is only worth it at organizational scale. (5) TAKEAWAY: start with a monolith; migrate to Federation when you have clear domain boundaries and 3+ teams that need to deploy independently.

```graphql
# GOOD: Federation 2 - Users subgraph (authoritative owner)
# BAD: (see above - monolith approach)
# File: users/schema.graphql

extend schema
  @link(url: "https://specs.apollo.dev/federation/v2.3",
        import: ["@key", "@shareable"])

type Query {
  user(id: ID!): User
  me: User
}

# User is the authoritative definition (this subgraph owns it)
type User @key(fields: "id") {
  id: ID!
  name: String!
  email: String!
  # Profile fields owned by this subgraph:
  createdAt: String!
  timezone: String
}

# _entities query is auto-generated by Federation SDK
# Gateway calls: _entities(representations: [{__typename:"User", id:"1"}])
# Returns: [User!]!  <- resolves User fields for other subgraphs
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Federation 2 Users subgraph SDL - the `@link` directive imports Federation directives; `@key(fields: "id")` declares that `User.id` is the entity key; this subgraph is the authoritative owner of all User fields listed. (2) KEY MECHANISM: `@key(fields: "id")` makes `User` a Federation entity; other subgraphs can reference `User` by its `id`; the gateway routes requests for User fields to this subgraph using the auto-generated `_entities` query. (3) WHY IT MATTERS: the `@key` declaration is the foundation of Federation; without it, a type cannot be referenced across subgraphs; every entity that appears in multiple subgraphs must have a `@key`. (4) WHAT BREAKS: if the Users subgraph changes `User @key(fields: "id")` to `@key(fields: "email")` without updating the Posts subgraph's `User` reference, composition fails; key changes require coordinated updates across all referencing subgraphs. (5) TAKEAWAY: design entity keys with stability in mind; `id: ID!` is always a good key (immutable, unique); `email` is a bad key (can change, not globally unique); keys must be stable across the lifetime of the schema.

```graphql
# Posts subgraph: references User from Users subgraph
# File: posts/schema.graphql

extend schema
  @link(url: "https://specs.apollo.dev/federation/v2.3",
        import: ["@key", "@requires", "@provides",
                 "@external"])

type Query {
  post(id: ID!): Post
  feed(first: Int = 20): [Post!]!
}

type Post @key(fields: "id") {
  id: ID!
  title: String!
  content: String!
  authorId: ID!
  # Reference to User entity (resolved by Users subgraph)
  author: User!
}

# Stub reference to User entity
# (Not the owner - does not define User fields here)
type User @key(fields: "id") {
  id: ID! @external  # <- "This field comes from Users subgraph"
  # Add Posts-specific fields to User:
  posts: [Post!]!    # <- Users can query user.posts
  postCount: Int!    # <- Additional field owned by Posts subgraph
}

# Resolver: Post.author
# How the gateway resolves this:
# 1. Fetch Post(id:1) from Posts subgraph -> returns {id, authorId}
# 2. Fetch _entities([{__typename:"User", id: authorId}])
#      from Users subgraph -> returns User{name, email, ...}
# 3. Merge: Post.author = the returned User object
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Posts subgraph referencing the `User` entity from the Users subgraph - `User @key(fields: "id") { id: ID! @external }` is a stub that says "I know User has an id, I don't own any User fields, but I can add posts-related fields to the User type." (2) KEY MECHANISM: `@external` marks `id: ID!` as belonging to another subgraph; `posts: [Post!]!` and `postCount: Int!` are new fields that the Posts subgraph contributes to the User type; when a client queries `user { posts { title } }`, the gateway fetches User from Users subgraph then fetches User.posts from Posts subgraph using the user's id. (3) WHY IT MATTERS: this cross-subgraph type extension is Federation's power - the Posts team adds `user.posts` without modifying the Users subgraph's code; teams are independent. (4) WHAT BREAKS: if Posts subgraph adds a field to User that the Users subgraph also adds (same name), composition fails with a "field conflict" error; use `@shareable` to explicitly allow multiple subgraphs to define the same field. (5) TAKEAWAY: the Posts subgraph "extends" the User type by adding `posts` and `postCount`; this is the Federation model for cross-domain relationships; each team adds fields to types they "own" (in terms of the business domain relationship, not the type definition).

```javascript
// BAD: Standard ApolloServer (not Federation-aware)
// Missing buildSubgraphSchema - no _entities query
const server = new ApolloServer({ typeDefs, resolvers });
// Gateway cannot call this as a subgraph:
// { _service { sdl } } -> error: no _service field
// _entities([...]) -> error: no _entities field
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `new ApolloServer({ typeDefs, resolvers })` directly creates a standard GraphQL server that lacks the Federation `_entities` and `_service` queries required by the gateway. (2) KEY MECHANISM: Apollo Server without `buildSubgraphSchema` does not add Federation infrastructure; the gateway attempts `{ _service { sdl } }` to verify the subgraph and gets an error; the subgraph cannot be registered. (3) WHY IT MATTERS: this is the most common Federation setup mistake; the server starts and serves queries normally, but the gateway cannot use it as a subgraph; the error appears only when registering with the schema registry. (4) WHAT BREAKS: the gateway health check fails on startup if a subgraph does not support `_service`; the gateway logs "Subgraph does not support Federation" and refuses to include it in the supergraph. (5) TAKEAWAY: always use `buildSubgraphSchema` for any GraphQL service intended to be a Federation subgraph; this is the single mandatory change.

```javascript
// GOOD: Federation 2 subgraph server setup
// BAD: monolith approach (see top of file)

const { ApolloServer } = require('@apollo/server');
const {
  buildSubgraphSchema
} = require('@apollo/subgraph');
const { gql } = require('graphql-tag');
const { readFileSync } = require('fs');

const typeDefs = gql(
  readFileSync('./schema.graphql', 'utf-8')
);

const resolvers = {
  Query: {
    user: (_, { id }, { db }) => db.findUser(id)
  },
  User: {
    // Entity resolver: called by gateway for _entities query
    __resolveReference: async (reference, { db }) => {
      // reference = { __typename: "User", id: "123" }
      return db.findUser(reference.id);
    }
  }
};

const server = new ApolloServer({
  // buildSubgraphSchema adds _entities query and
  // _service query automatically
  schema: buildSubgraphSchema({ typeDefs, resolvers })
});

// The gateway calls _entities when it needs
// to resolve a User reference from another subgraph:
// POST /graphql { query: "query($reps:[_Any!]!) {
//   _entities(representations:$reps) { ... on User { name } }
// }", variables: { reps: [{__typename:"User", id:"1"}] } }
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `buildSubgraphSchema` replacing the standard `new ApolloServer({ typeDefs, resolvers })` call - the critical difference is that `buildSubgraphSchema` adds the Federation-required `_entities` and `_service` queries automatically. (2) KEY MECHANISM: the `__resolveReference` resolver is the Federation entity resolver; the gateway calls `_entities(representations: [{__typename:"User", id:"1"}])` when it needs to fetch User fields for an entity reference from another subgraph; `__resolveReference` receives the representation object and returns the full entity. (3) WHY IT MATTERS: without `__resolveReference`, the subgraph cannot respond to cross-subgraph entity requests; the gateway would receive an error when trying to complete a query that needs User fields from the Users subgraph via an entity reference. (4) WHAT BREAKS: if `__resolveReference` does not return all fields the gateway expects, it receives null for those fields; ensure the resolver returns the full entity object (not just the key fields). (5) TAKEAWAY: `__resolveReference` is the Federation entity resolver - it is the single most important Federation-specific resolver to implement correctly; treat it like a `findById` method with the `representations` array as the input.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Apollo Federation lets you split a GraphQL monolith into multiple services (subgraphs),
> each owned by a different team. A gateway (Apollo Router) combines them into one API.
> Key concepts: `@key` marks a type as a Federation entity (identifiable by a field);
> subgraphs can reference entities from other subgraphs; the gateway routes each field
> to the right subgraph. Use `buildSubgraphSchema` instead of the standard schema builder,
> and implement `__resolveReference` for every entity type.

---

**Senior / Staff (5+ years):**
> Federation is an organizational tool first, a technical tool second. It solves the
> monolith coordination problem at the cost of operational complexity (gateway, schema
> registry, composition checks, query planning overhead). The critical design decisions:
> (1) entity key selection - use stable, immutable identifiers (`id: ID!`); avoid mutable
> fields. (2) subgraph boundaries - align with domain-driven design and team ownership;
> do not split too finely (each split adds a subgraph call). (3) `@requires` and `@provides`
> - use `@requires` when a field depends on another subgraph's field; use `@provides`
> as an optimization hint to the gateway that this subgraph can serve a field without an
> additional hop. (4) query plan analysis - use Apollo Router's query plan visualization
> to identify multi-hop queries and optimize them. Performance: Federation adds 10-50ms
> gateway overhead for simple queries; for queries requiring 3+ subgraph hops, this can
> reach 100-200ms extra; optimize by reducing hops with `@provides` or by co-locating
> related types.

---

### ⚠️ Common Misconceptions

**Misconception: "Federation is just schema stitching with a different name."**

Federation and schema stitching solve the same problem (multi-service GraphQL composition)
but with fundamentally different approaches:

Schema stitching (old approach):
- The gateway has knowledge of all subgraph schemas.
- The gateway must manually configure which fields come from which service.
- Adding a new field requires updating the gateway configuration.
- Type merging is done at the gateway layer; subgraphs don't know about each other.
- Maintenance: high; every inter-service relationship requires explicit gateway config.

Apollo Federation:
- Each subgraph declares its own relationships using directives (`@key`, `@requires`).
- The gateway reads a published supergraph SDL and derives routing automatically.
- Adding a new cross-subgraph relationship requires only subgraph schema changes.
- Composition is validated by the schema registry before deployment.
- Maintenance: lower; subgraphs are self-describing.

The practical difference: with schema stitching, the gateway is the coordination point
and must be updated for every cross-service relationship. With Federation, each subgraph
declares its own contracts, and the gateway is stateless (reads the published supergraph
SDL without knowing individual subgraph schemas).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Federation composition error blocks deployment.**

Symptom: `rover subgraph publish` fails with a composition error; the new subgraph
schema cannot be deployed because it breaks the supergraph.

```bash
# Error example:
rover subgraph publish \
  --schema posts.graphql \
  --name posts \
  --routing-url http://posts-service/graphql
# Error: [INVALID_FIELD_SHARING]
#   Field "User.email" can only be defined
#   at most once, but is defined in subgraphs
#   "users" and "posts". If this is intentional,
#   mark it @shareable.

# Diagnosis: which subgraphs define this field?
rover subgraph introspect http://users-service/graphql
rover subgraph introspect http://posts-service/graphql
# Both return: type User { email: String }
# -> Both define email; only one should own it

# Fix: mark @shareable if intentional
# OR: remove from Posts subgraph (correct approach)

# Check composition locally before pushing:
rover supergraph compose --config supergraph.yaml
# Runs composition without publishing
# Shows errors without affecting production
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Federation composition error where two subgraphs both define `User.email`, causing a conflict - the schema registry rejects the publish. (2) KEY MECHANISM: Federation 2 requires that each field have a single authoritative owner (unless `@shareable` is declared); `INVALID_FIELD_SHARING` means the gateway cannot determine which subgraph's version of a field is authoritative. (3) WHY IT MATTERS: composition checks are a key Federation safety mechanism; they prevent incompatible schema changes from reaching the gateway; the schema registry is the enforcement point. (4) WHAT BREAKS: marking every conflicting field `@shareable` (the quick fix) bypasses the intent of Federation - each field should have one owner; `@shareable` should be reserved for fields that genuinely need to be resolvable from multiple subgraphs (e.g., entity key fields like `id`). (5) TAKEAWAY: run `rover supergraph compose --config supergraph.yaml` locally before every `rover subgraph publish`; local composition catches errors before they block the pipeline; add it to the pre-commit hook or CI validation step.

---

### ⚖️ Comparison Table

| Feature | Apollo Federation 2 | Schema Stitching | GraphQL Monolith |
|---|---|---|---|
| Team ownership | Per-subgraph | Per-gateway-config | Shared |
| Cross-service relationships | `@key` + `@requires` | Manual gateway config | In-process |
| Deployment independence | Full | Partial | None |
| Gateway complexity | Apollo Router | Custom/stitch | None |
| Query planning | Automatic (supergraph) | Manual | None |
| Schema registry | Required | Optional | None |
| Operational overhead | High | Medium | Low |
| Best for | 5+ teams, microservices | Incremental adoption | 1-2 teams |

---

### 🏛️ System Design

**Federation 2 Multi-Team Architecture:**

```text
APOLLO FEDERATION 2 PRODUCTION ARCHITECTURE:

[Schema Registry - Apollo Studio]
  Users subgraph SDL ---> Composition check
  Posts subgraph SDL ---> (valid supergraph?)
  Orders subgraph SDL --> Publish supergraph SDL
                          Poll or webhook to Router

[Apollo Router (Gateway)]
  Reads supergraph SDL
  Receives: POST /graphql (client query)
  Builds: Query Plan
  Executes: parallel subgraph calls
  Assembles: unified response

  Query Plan Example:
  GetUserWithPosts {
    Fetch(users-service): User(id).{name, email}
    Fetch(posts-service): User._entities(id).{posts}
    Flatten + Merge
  }

[Users Service]   [Posts Service]   [Orders Service]
  users DB          posts DB          orders DB
  users.graphql     posts.graphql     orders.graphql

  Each service:
  - Owned by separate team
  - Independent deployment
  - buildSubgraphSchema() setup
  - __resolveReference() for entities

[CI/CD Pipeline per subgraph]
  Test -> rover subgraph check (composition check)
       -> rover subgraph publish (if checks pass)
       -> Router polls registry -> hot reload SDL
  No Router restart needed for schema changes!
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the full Federation 2 production architecture from schema registry through the gateway to three independent subgraph services, including the CI/CD pipeline for independent deployments. (2) HOW TO READ IT: the schema registry is the central coordination point; the router reads from it; subgraph services run independently; the CI/CD pipeline shows the subgraph-publish workflow. (3) KEY RELATIONSHIP: the registry -> router connection is continuous (router polls or uses webhook); when a subgraph publishes a new schema, the router hot-reloads the supergraph SDL within seconds, with no downtime; this is the key operational benefit of Federation over manual gateway config. (4) EDGE CASE: the composition check in CI/CD is the critical safeguard; a subgraph that fails composition is blocked from publishing; without this gate, a bad schema could be published and break the supergraph for all teams. (5) INSIGHT: "No Router restart needed for schema changes" is the operational superpower of Federation - the router's schema polling means a team can publish a new subgraph schema and the gateway picks it up automatically; in a monolith or schema stitching setup, every schema change requires redeploying the gateway.

---

### 📊 Diagram

```text
FEDERATION ENTITY RESOLUTION FLOW:

Client query:
  query {
    post(id: "1") {
      title
      author { name email }
    }
  }

Gateway query plan:

STEP 1 (Posts subgraph):
  Query: post(id:"1") { title authorId }
  Result: { title: "Hello", authorId: "u42" }

STEP 2 (Users subgraph, using authorId from step 1):
  Query: _entities([{__typename:"User", id:"u42"}])
         { ... on User { name email } }
  Result: { name: "Alice", email: "a@e.com" }

ASSEMBLE:
  { post: {
      title: "Hello",
      author: { name: "Alice", email: "a@e.com" }
  }}

LATENCY BREAKDOWN:
  Network + gateway:   ~5ms
  Step 1 (Posts):     ~20ms
  Step 2 (Users):     ~15ms  <- parallel to other steps
  Total:              ~40ms
  (vs monolith: ~30ms but with coupled deployment)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the two-step entity resolution flow for a query that needs data from two subgraphs - Posts for the post data and Users for the author data. (2) HOW TO READ IT: STEP 1 fetches from Posts subgraph, yielding the `authorId`; STEP 2 uses `authorId` to call Users subgraph's `_entities` query; the gateway merges both results into the final response. (3) KEY RELATIONSHIP: the `authorId` from STEP 1 is the entity reference that triggers STEP 2; without a `@key(fields: "id")` on the User type, there is no way to route STEP 2 to the Users subgraph. (4) EDGE CASE: if `author` in Posts subgraph uses `@provides(fields: "name email")`, STEP 2 can be skipped because Posts subgraph can provide the User fields; this eliminates the second subgraph hop and reduces latency to one round-trip. (5) INSIGHT: the latency breakdown shows that Federation adds approximately 10ms over a monolith (gateway overhead + extra subgraph call); this is acceptable for most operations; for latency-sensitive operations, use `@provides` to eliminate subgraph hops.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Federation architecture, entity resolution |
| Application | 2 | subgraph setup, entity resolver |
| Architecture | 3 | query planning, composition, @requires |
| Trade-off | 2 | Federation vs monolith, latency overhead |
| Debugging | 2 | composition errors, multi-hop latency |
| Security | 1 | subgraph access control |

---

**[JUNIOR] Q1 (Definition): What is the difference between a subgraph and a supergraph?**

Subgraph: an individual GraphQL service that owns a subset of the overall schema. Each
subgraph uses `buildSubgraphSchema` and exposes its own GraphQL endpoint. It operates
independently - it can be deployed, scaled, and maintained by a single team.

Supergraph: the unified GraphQL schema composed from all subgraph schemas. The supergraph
SDL is published to a schema registry; the gateway (Apollo Router) reads it to understand
the full API. The supergraph has no running service - it is a schema document that the
router uses to route queries.

Analogy: subgraphs are like microservices (each owns a domain); the supergraph is like
the API contract (the combined interface all clients use); the router is like the API
gateway (routes requests to the right service based on the contract).

In practice:
- Clients interact with the supergraph endpoint (one URL, the router).
- Teams build and deploy subgraphs (many services, each with its own endpoint).
- The schema registry publishes the supergraph SDL derived from all subgraph SDLs.
- The router uses the supergraph SDL to plan and route queries.

*What separates good from great:* understanding that the supergraph is not a running
service but a compiled artifact. `rover supergraph compose` takes N subgraph schemas and
produces one supergraph SDL file; this file is deployed to the router; when subgraphs
change, they publish new schemas, composition re-runs, and the router gets a new
supergraph SDL. The router is the only running piece that has the full view.

---

**[SENIOR] Q2 (Architecture): How does Apollo Router build and execute a query plan?**

Query planning is the process of decomposing a client query into subgraph-specific
fetch operations:

```graphql
# Client query:
query GetPost {
  post(id: "1") {
    title           # <- Posts subgraph
    author {        # <- Users subgraph (entity)
      name          # <- Users subgraph
      email         # <- Users subgraph
      posts {       # <- Posts subgraph (back again!)
        id title
      }
    }
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a GraphQL query that spans three subgraphs in the query execution - `post.title` from Posts, `author.name/email` from Users, and `author.posts` back to Posts - creating a three-hop query plan. (2) KEY MECHANISM: the gateway decomposes this query into three `Fetch` operations; `post.title` and `author.posts` come from Posts; `author.name/email` from Users; the dependency chain is sequential: Posts -> Users -> Posts. (3) WHY IT MATTERS: three sequential hops add 3 x (subgraph round-trip time) to the total latency; for LAN deployments (~2ms/hop), this is 6ms extra; for inter-datacenter (~20ms/hop), this is 60ms extra. (4) EDGE CASE: if `@provides(fields: "name email")` is added to `Post.author`, the second Users hop is eliminated; the query becomes two-hop: Posts -> Posts. (5) TAKEAWAY: this query pattern (entity A -> entity B -> entity A) creates a W-shaped query plan; avoid it by restructuring the query or using `@provides` to collapse the B hop.

Query plan analysis:
1. `post(id:"1")` -> Posts subgraph: fetch `{title, authorId}`.
2. `author { name, email }` -> Users subgraph via `_entities([{id: authorId}])`.
3. `author.posts` -> Posts subgraph again: `_entities([{id: userId}])` to get User.posts.

This query requires 3 subgraph calls. The router identifies steps 1 and 2 as sequential
(need `authorId` from step 1 before executing step 2); step 3 depends on the User `id`
from step 2 but could potentially be parallelized with step 2 if `@provides` is used.

Apollo Router uses a Cost-Based Optimizer (CBO) to find the lowest-cost query plan:
- Plans with fewer subgraph calls are preferred.
- Parallel calls reduce wall-clock time.
- `@provides` and `@requires` affect plan options.

```bash
# Inspect the query plan for debugging:
# Apollo Router: enable query plan logging
# config.yaml:
# telemetry:
#   experimental_logging:
#     display_query_plan: true

# Apollo Sandbox: Query Plan tab shows the plan
# for any operation against the router endpoint
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a multi-hop Federation query that traverses three subgraph calls, plus the config to expose query plans for debugging. (2) KEY MECHANISM: the router reads the supergraph SDL (which contains `@join__*` Federation directives encoding the query routing information) to determine which subgraph owns each field; it builds a dependency graph and schedules calls accordingly. (3) WHY IT MATTERS: understanding query plans is essential for optimization; a query with 5 subgraph hops takes 5x longer than a single-subgraph query; `display_query_plan: true` makes the plan visible without source code access. (4) WHAT BREAKS: circular entity references (User requires Post.metrics, Post requires User.recentActivity) create infinite query plan depth; the router detects circular references and returns an error during composition. (5) TAKEAWAY: check query plans for all latency-sensitive operations; any plan with more than 2 sequential hops is a candidate for optimization using `@provides` or schema restructuring.

*What separates good from great:* understanding the Apollo Router's two-phase execution
model. Phase 1 (planning): build the query plan from the supergraph SDL - this is CPU-
only, no network calls; plans for common queries can be cached. Phase 2 (execution):
execute the plan by making subgraph requests in the planned order (sequential or parallel).
The plan cache means a query's routing is computed once; subsequent identical queries
reuse the cached plan without re-planning.

---

**[SENIOR] Q3 (Application): How do you implement `@requires` and when do you need it?**

`@requires` is used when a field in one subgraph needs a field from the same entity
in another subgraph to resolve:

```graphql
# Example: shipping estimate requires user's location
# Users subgraph:
type User @key(fields: "id") {
  id: ID!
  name: String!
  country: String!  # <- needed by Orders subgraph
}

# Orders subgraph:
type User @key(fields: "id") {
  id: ID!    @external
  country: String! @external  # <- comes from Users subgraph
  shippingEstimate: String!
    @requires(fields: "country")
    # "I need User.country (from Users subgraph)
    #  to compute shippingEstimate"
}

# What happens when client queries user.shippingEstimate:
# 1. Router calls Users subgraph: _entities(id) -> {country}
# 2. Router calls Orders subgraph: _entities({id, country})
#    With country in the representation, Orders can compute
#    the shipping estimate without calling Users again
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `@requires(fields: "country")` on `shippingEstimate` - the Orders subgraph needs `User.country` from the Users subgraph to compute the shipping estimate; the gateway fetches `country` from Users and includes it in the `_entities` representation for Orders. (2) KEY MECHANISM: without `@requires`, the Orders subgraph's `shippingEstimate` resolver would only receive `{id}` in the representation; it would need to make an HTTP call to Users service to get `country`; `@requires` tells the gateway to pre-fetch `country` and provide it, eliminating the extra call. (3) WHY IT MATTERS: `@requires` improves performance by having the gateway provide needed context instead of the subgraph making additional service calls; it also keeps the subgraph pure (no cross-service calls in resolvers). (4) WHAT BREAKS: if the `@requires` field is expensive to compute (e.g., `country` requires a DB query), the gateway will fetch it even for queries that don't request `shippingEstimate`; redesign to compute on demand rather than pre-fetching. (5) TAKEAWAY: `@requires` is the correct pattern for cross-entity field dependencies; use it instead of HTTP calls between subgraphs; it makes dependencies explicit and optimizable by the gateway.

---

**[JUNIOR] Q4 (Application): What does `buildSubgraphSchema` do differently from the standard ApolloServer schema builder?**

`buildSubgraphSchema` adds Federation-required infrastructure to a regular schema:

1. Adds the `_entities` query: the gateway calls `_entities(representations: [_Any!]!)` to
   resolve entity references from other subgraphs; `buildSubgraphSchema` adds this query
   and wires it to the `__resolveReference` resolvers.

2. Adds the `_service` query: `{ _service { sdl } }` returns the subgraph's SDL; the
   schema registry and gateway use this to verify the subgraph is running and to introspect
   its schema.

3. Adds scalar types: `_Any`, `_FieldSet`, `link__Import` - internal Federation types
   needed for entity representations and `@link` directives.

4. Processes `@key` directives: reads `@key(fields: "id")` annotations and creates the
   routing metadata that the gateway uses for query planning.

Without `buildSubgraphSchema`: `ApolloServer({ typeDefs, resolvers })` creates a standard
GraphQL server; it cannot respond to `_entities` queries; the router cannot use it as a
Federation subgraph.

*What separates good from great:* `buildSubgraphSchema` also validates the schema for
Federation compatibility during server startup. If a `@key` field references a non-existent
field, it throws at startup rather than failing at query time; this is an early-error
detection mechanism. Add `buildSubgraphSchema` even for the first subgraph in a future-
Federation architecture to establish the pattern before Federation is needed.

---

**[SENIOR] Q5 (Architecture): How do you configure Federation for gradual migration from a monolith?**

Strangler fig pattern for Federation migration:

Step 1: The monolith is the only subgraph. Wrap it with `buildSubgraphSchema` and register
it as a Federation subgraph. The gateway passes all queries to it. No change to clients.

```javascript
// Monolith: add buildSubgraphSchema
// (no other changes needed initially)
const schema = buildSubgraphSchema({ typeDefs, resolvers });
const server = new ApolloServer({ schema });
```

> **Code walkthrough:** (1) WHAT IT SHOWS: adding `buildSubgraphSchema` to the existing monolith as the first step of Federation migration - this makes the monolith a valid Federation subgraph without changing any of its types or resolvers. (2) KEY MECHANISM: `buildSubgraphSchema` adds the `_entities` and `_service` infrastructure; the monolith's existing types and resolvers are unchanged; the gateway can now route all queries to the monolith (same behavior, but via Federation). (3) WHY IT MATTERS: this first step adds Federation infrastructure with zero behavior change; clients see no difference; the system is now ready for type extraction in subsequent steps. (4) WHAT BREAKS: if the monolith uses any reserved Federation type names (`_Service`, `_Any`, `_Entity`), `buildSubgraphSchema` will throw a conflict; rename conflicting types before adding Federation. (5) TAKEAWAY: the first migration step is additive; the monolith becomes a subgraph with zero behavior change; subsequent steps extract types to new subgraphs one at a time.

Step 2: Extract one domain type (e.g., `User`) to a new Users subgraph.
Step 3: Register the Users subgraph; mark `User` as `@key` in both schemas during transition.
Step 4: Remove `User` type from the monolith; compose the two-subgraph supergraph.
Step 5: Repeat for each domain type until the monolith is empty.

The key safety: composition checks at each step validate the supergraph is still valid;
a failed composition blocks deployment; partial extraction is supported (two subgraphs
defining the same type during transition via `@shareable`).

---

**[SENIOR] Q6 (Trade-off): What are the latency trade-offs of Apollo Federation?**

Federation adds latency at two points:

1. Gateway overhead: query planning, query plan lookup, result assembly. Typical: 2-5ms
   for simple queries; 5-15ms for complex multi-hop queries.

2. Additional subgraph calls: each cross-subgraph entity reference adds one subgraph
   round-trip. For a LAN (same data center): 0.5-2ms per call. For WAN: 10-50ms per call.
   A 3-hop query adds 1-6ms (LAN) or 30-150ms (WAN).

Mitigation strategies:

```graphql
# Use @provides to eliminate subgraph hops
type Post @key(fields: "id") {
  id: ID!
  title: String!
  authorId: ID!
  # @provides: "I can provide these User fields
  #             without calling the Users subgraph"
  author: User! @provides(fields: "name avatar")
}

type User @key(fields: "id") {
  id: ID!        @external
  name: String!  @external
  avatar: String! @external
}

# With @provides: queries for post.author.name
# and post.author.avatar are served by Posts subgraph
# WITHOUT a second call to Users subgraph.
# Trade-off: Posts must store/cache user name and avatar.
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `@provides(fields: "name avatar")` on `Post.author` - the Posts subgraph claims it can provide `User.name` and `User.avatar` without calling the Users subgraph, eliminating the second subgraph hop. (2) KEY MECHANISM: the gateway reads `@provides` and uses it in query planning; if a client queries `post.author.name` and Posts `@provides(fields: "name")`, the gateway skips the Users subgraph call; the Posts resolver must return `{name, avatar}` in the `author` object. (3) WHY IT MATTERS: `@provides` eliminates subgraph hops for the specified fields; a two-hop query becomes a single-hop query; latency reduction can be significant for LAN deployments. (4) WHAT BREAKS: Posts subgraph providing `User.name` must denormalize the data (store name in posts DB or cache); if the user's name changes, posts may serve stale name data until the cache is invalidated; `@provides` trades freshness for latency. (5) TAKEAWAY: use `@provides` for slowly-changing fields (user name, avatar, display name) that are queried frequently with entities from other subgraphs; not for real-time data (balance, status, live counts).

---

**[SENIOR] Q7 (Debugging): How do you debug a Federation query that returns null for entity fields?**

Entity fields returning null indicate a failed `_entities` call or missing `__resolveReference`:

```bash
# Step 1: Check gateway logs for _entities errors
# Apollo Router: enable debug logging
# Or: check Apollo Studio > Operations > Errors

# Step 2: Test _entities directly
# Call the subgraph's _entities endpoint:
curl -X POST http://users-service/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"query($reps:[_Any!]!){
    _entities(representations:$reps){
      ... on User { name email }
    }
  }","variables":{"reps":[
    {"__typename":"User","id":"123"}
  ]}}'

# Expected: {"data":{"_entities":[{"name":"Alice",...}]}}
# Null in array: __resolveReference returned null
# Error: missing @key field in representation
# No _entities field: buildSubgraphSchema not used

# Step 3: Verify __resolveReference implementation
# Common bugs:
# - Returns undefined instead of null for missing entity
# - Throws instead of returning null
# - Incorrect key field lookup
```

> **Code walkthrough:** (1) WHAT IT SHOWS: directly calling the `_entities` query on a subgraph to test entity resolution in isolation, bypassing the gateway to determine if the issue is in the subgraph or the gateway's query planning. (2) KEY MECHANISM: `_entities` accepts `representations: [{__typename: "User", id: "123"}]`; the subgraph's `__resolveReference` resolver handles each representation; null in the response indicates `__resolveReference` returned null (entity not found or error). (3) WHY IT MATTERS: isolating `_entities` from the gateway tells you where the failure is; if `_entities` works correctly (returns User data), the issue is in the gateway's query planning or representation passing; if it returns null, the issue is in `__resolveReference`. (4) WHAT BREAKS: `"No _entities field"` means `buildSubgraphSchema` was not used; the service is a regular GraphQL server, not a Federation subgraph; the gateway cannot route entity requests to it. (5) TAKEAWAY: test `_entities` directly against each subgraph as part of integration testing; a health check that verifies `_entities` returns the correct data for a test entity catches `__resolveReference` bugs before they reach production.

---

**[SECURITY] Q8 (Security): How do you secure subgraph services in a Federation setup?**

Subgraph services should not be exposed to the public internet - only the gateway should
call them:

1. Network isolation: deploy subgraphs in a private network (VPC/subnet); the gateway
   is the only service with a public endpoint; subgraphs are only accessible from within
   the VPC.

2. mTLS between gateway and subgraphs: configure Apollo Router to use mutual TLS
   when calling subgraphs; subgraphs verify that the caller is the legitimate router.

3. `Router-Authorization` header: Apollo Router can add a custom header to all
   subgraph requests; subgraphs verify the header value:

```javascript
// Subgraph: verify Router-Authorization header
const authMiddleware = (req, res, next) => {
  const routerToken = req.headers['router-authorization'];
  if (routerToken !== process.env.ROUTER_SECRET) {
    return res.status(403).json({
      errors: [{ message: 'Unauthorized subgraph access' }]
    });
  }
  next();
};

app.use('/graphql', authMiddleware, server.middleware());

// Apollo Router: add header to all subgraph requests
// router.yaml:
// headers:
//   subgraphs:
//     all:
//       request:
//         - insert:
//             name: Router-Authorization
//             value: "${env.ROUTER_SECRET}"
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a subgraph-side middleware that verifies a secret token added by the Apollo Router to all subgraph requests - this prevents direct access to the subgraph by bypassing the gateway. (2) KEY MECHANISM: the router adds `Router-Authorization: SECRET` to every subgraph request via the `headers.subgraphs.all.request` config; the subgraph middleware rejects requests without the correct header; an attacker calling the subgraph directly without knowing the secret receives a 403. (3) WHY IT MATTERS: without subgraph authentication, attackers can call subgraphs directly; this bypasses all gateway-level security controls (rate limiting, APQ, auth validation); the attack surface expands from 1 endpoint to N subgraph endpoints. (4) WHAT BREAKS: the `ROUTER_SECRET` must be rotated; rotation requires updating the router config AND all subgraph services simultaneously; coordinate rotation with a short overlap period. (5) TAKEAWAY: deploy subgraphs in a private network AND add secret-token authentication; defense in depth; network isolation prevents external access; token authentication prevents internal-network actors from bypassing the gateway.

---

**[SENIOR] Q9 (Architecture): How does the schema registry enable zero-downtime schema updates?**

The schema registry enables hot-reload of the supergraph SDL without restarting the router:

1. A team publishes a new subgraph schema: `rover subgraph publish`.
2. The registry runs composition: validates the new supergraph SDL.
3. If composition passes: the registry publishes the new supergraph SDL.
4. Apollo Router polls the registry every 10 seconds (configurable).
5. Router detects the new supergraph SDL version.
6. Router builds new query plans from the new SDL.
7. Router hot-reloads: in-flight requests complete with the old SDL; new requests
   use the new SDL.
8. Old SDL is garbage-collected after all in-flight requests complete.

Result: schema updates are applied within 10-20 seconds with zero downtime and no
router restart.

Contrast with schema stitching: the gateway must be restarted or redeployed for
every schema change because its configuration is embedded in code.

*What separates good from great:* understanding the registry's launch checking feature.
Apollo Studio's "launch" tracks which schema version is deployed to which environment
(development, staging, production). The router reports which supergraph SDL version it
is running. The registry shows the current deployment status for all environments. This
provides an audit trail: when a latency spike occurs, check if a schema was published
in the preceding 30 minutes; the launch history shows exactly what changed.

---

**[SENIOR] Q10 (Trade-off): When should you NOT use Apollo Federation?**

Federation is NOT the right choice when:

1. Single team, single codebase: Federation adds operational complexity (gateway, registry,
   composition checks) without organizational benefit. A monolith is simpler.

2. Startup or MVP stage: Federation requires 3+ services to justify the overhead; deploying
   a gateway + schema registry before the product has product-market fit is premature.

3. All data in one database: Federation is designed for distributed data ownership; if
   all queries ultimately hit one database, there is no isolation benefit - just overhead.

4. Real-time subscriptions are the primary use case: Federation's subscription support
   is limited (Federation 2.3 has basic subscription passthrough); complex multi-subgraph
   subscription scenarios are poorly supported.

5. Very high-frequency, latency-sensitive queries: the gateway adds 5-15ms overhead;
   for APIs where P95 target is < 20ms, Federation may be incompatible.

The inflection point: Federation becomes worth it when you have 3+ teams with distinct
domain boundaries, each needing to deploy independently. The operational cost (gateway
maintenance, schema registry, composition checks) is justified by the development
velocity gain (teams don't block each other).

*What separates good from great:* proposing Federation EARLY in the design conversation
rather than as a retrofit. Migrating a 200-type monolith to Federation is a 6-12 month
project; designing Federation boundaries from the start of a 5-team product takes
2 days. The strangler-fig migration pattern makes retrofitting possible but painful;
green-field Federation adoption is dramatically easier.

---

**[JUNIOR] Q11 (Definition): What is the difference between `@external` and `@requires` in Federation 2?**

`@external`: "This field is defined and owned by another subgraph, but I'm declaring it
here so I can reference it."

```graphql
# Users subgraph defines: type User { id, name, country }
# Orders subgraph needs to reference User.country:

type User @key(fields: "id") {
  id: ID!          @external  # User.id is from Users subgraph
  country: String! @external  # User.country is from Users subgraph
  shippingEstimate: String!
    @requires(fields: "country")  # <- I need country to resolve this
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `@external` on `id` and `country` (owned by Users subgraph) and `@requires(fields: "country")` on `shippingEstimate` - the Orders subgraph declares it needs `country` in the entity representation to resolve `shippingEstimate`. (2) KEY MECHANISM: when a client queries `user.shippingEstimate`, the gateway fetches `{id, country}` from Users subgraph, then calls Orders subgraph with `{__typename:"User", id, country}` as the representation; the resolver receives `country` without making any service call. (3) WHY IT MATTERS: without `@requires`, the Orders resolver must call Users service itself to get `country`; `@requires` makes the dependency explicit and lets the gateway optimize it. (4) WHAT BREAKS: if `country` is expensive to compute (DB join), `@requires` causes it to be fetched even when `shippingEstimate` is not queried. (5) TAKEAWAY: `@requires` is the correct pattern for inter-subgraph field dependencies; it makes the gateway the coordinator instead of subgraphs calling each other.

`@requires`: "I need these `@external` fields to be provided in the entity representation
before I can resolve this field."

Without `@requires`: the gateway would call Orders subgraph with `{__typename, id}` only;
the Orders subgraph's `shippingEstimate` resolver would need to call the Users service
to get `country` itself.

With `@requires`: the gateway calls Users subgraph first to get `{id, country}`, then
calls Orders subgraph with `{__typename, id, country}` as the representation; the resolver
receives `country` in the parent object and does not need to call Users.

In Federation 2: `@external` is only needed on fields referenced by `@requires` or
`@provides`; it is not needed simply to reference an entity type.

*What separates good from great:* understanding when `@requires` versus a simple service
call is the right choice. `@requires` is correct when the required field is a key or
a simple scalar; for complex data (the shipping estimate depends on a user's entire
purchase history, not just one field), a service call or read model is more appropriate.

---

**[SENIOR] Q12 (Architecture): How do you implement per-subgraph authentication in Federation?**

Authentication in Federation has two layers:

1. Gateway-level authentication (most common): the router validates the JWT/session
   before forwarding to subgraphs. The router adds the authenticated user context to
   subgraph requests via headers.

```yaml
# Apollo Router: propagate Authorization header to all subgraphs
headers:
  subgraphs:
    all:
      request:
        - propagate:
            named: Authorization
            # Forwards the client's Authorization header
            # to all subgraph requests
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Apollo Router YAML configuration to propagate the client's `Authorization` header to all subgraph requests, enabling subgraphs to perform their own authentication or use the token for user context. (2) KEY MECHANISM: the router receives `Authorization: Bearer JWT` from the client; the `propagate.named: Authorization` rule forwards this header unchanged to all subgraph calls; subgraphs extract the JWT from the header and decode it to identify the user. (3) WHY IT MATTERS: without header propagation, subgraphs receive no user context; they cannot perform field-level authorization (e.g., "only show User.email to the account owner"); propagating the Authorization header enables standard auth patterns in subgraphs. (4) WHAT BREAKS: propagating the raw JWT to all subgraphs requires all subgraphs to validate the JWT independently; if the signing key rotates, all subgraphs must be updated simultaneously; alternatively, the router validates the JWT and adds a claims header (e.g., `X-User-Id`) to avoid per-subgraph JWT validation. (5) TAKEAWAY: choose between JWT propagation (subgraphs validate independently) and claims extraction (router validates, adds structured headers); JWT propagation is simpler but requires per-subgraph validation; claims extraction centralizes validation but requires the router to be trusted by all subgraphs.

2. Subgraph-level authorization: after receiving user context (via header), each
   subgraph applies field-level authorization in its resolvers.
