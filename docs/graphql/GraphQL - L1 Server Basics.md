---
layout: default
title: "GraphQL - L1 Server Basics"
parent: "GraphQL"
nav_order: 3
permalink: /graphql/l1-server-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 7 | [Resolvers and Resolution Chain](#resolvers-and-resolution-chain) | ★☆☆ |
| 8 | [Context and Authentication in GraphQL](#context-and-authentication-in-graphql) | ★☆☆ |
| 9 | [Error Handling in GraphQL](#error-handling-in-graphql) | ★☆☆ |

---

# Resolvers and Resolution Chain

---

### 🎯 Model Answer

**30 seconds:**
> A resolver is a function that fetches the data for a single field in the GraphQL schema.
> Every field in a GraphQL schema has a resolver. When a client sends a query, GraphQL
> calls the resolver for each requested field in a tree traversal. The resolution chain
> is the sequence of resolver calls from the root Query down through nested object types
> to scalar leaf values. Resolvers receive four arguments: `root` (parent object),
> `args` (field arguments), `context` (shared request data), `info` (query metadata).

**3 minutes (Senior):**
> Resolvers are the execution layer of GraphQL; the schema defines what data is available,
> resolvers define how to fetch it. Resolution chain: GraphQL executes the root resolver
> (e.g., `Query.user`) first; the resolved object is passed as the `root` argument to
> the next level's resolvers (e.g., `User.name`, `User.posts`); this continues until
> all requested fields are resolved to scalars. Default resolvers: if no resolver is defined
> for a field, GraphQL uses the default resolver which reads `root[fieldName]`. This means
> object types that map directly to database rows often need no field resolvers; only
> root resolvers and resolvers that need custom logic require explicit implementation.
> Performance considerations: (1) resolvers should be pure functions where possible
> (deterministic given the same inputs), (2) avoid side effects in resolvers (use mutations
> for writes), (3) N+1 is the primary performance anti-pattern (each item in a list triggers
> its own resolver call without DataLoader batching).

**Blank Mind Recovery:**

**(1) Restate:** "Resolver: function that fetches data for one field. Four args: root
(parent data), args (field arguments), context (auth, db connections), info (query AST).
Default resolver: reads root[fieldName]. Resolution chain: root -> child -> grandchild
until scalars. N+1 problem: list resolver triggers N child resolvers; fix with DataLoader."

---

### 📘 Concept Explanation

**Resolver Execution Model:**

```text
RESOLVER EXECUTION TREE:

  Query {                          <- type Query
    user(id: "1") {                <- Query.user resolver
      name                         <- User.name resolver
      email                        <- User.email resolver
      posts {                      <- User.posts resolver
        title                      <- Post.title resolver
        author {                   <- Post.author resolver
          name                     <- User.name resolver
        }
      }
    }
  }

  EXECUTION ORDER:
  1. Query.user(root=null, args={id:"1"})
     -> Returns: { id:"1", name:"Alice", email:"..." }
  2. User.name(root={id:"1", name:"Alice",...}, args={})
     -> Default resolver: return root.name = "Alice"
  3. User.email(root={id:"1",...}, args={})
     -> Default resolver: return root.email
  4. User.posts(root={id:"1",...}, args={})
     -> Custom resolver: db.query("SELECT * FROM posts
        WHERE user_id = 1")
     -> Returns: [{id:"10", title:"Post A"}, ...]
  5. Post.title(root={id:"10",title:"Post A"}, args={})
     -> Default resolver: return root.title = "Post A"
  6. Post.author(root={id:"10",...}, args={})
     -> Custom resolver: db.query("SELECT * FROM users
        WHERE id = " + root.authorId)
     -> Returns: { id:"2", name:"Bob" }
  7. User.name(root={id:"2", name:"Bob"}, args={})
     -> Default resolver: return "Bob"

  KEY: Steps 6+7 repeat for EVERY post (N+1 problem)
  FIX: DataLoader batches step 6 across all posts
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the complete resolver execution tree for a nested GraphQL query showing the order of resolver calls, the passing of `root` (parent data) down the chain, and where N+1 occurs. (2) HOW TO READ IT: each indented level is a child resolver call; the output of each resolver becomes the `root` argument for its children; scalar fields use the default resolver (just read the property); object/list fields need custom resolvers to fetch from the database. (3) KEY RELATIONSHIP: `User.posts` resolver returns a list of posts; for each post, `Post.author` resolver fires independently; without DataLoader, this is one database query per post (N+1). (4) EDGE CASE: `User.name` appears twice in the tree (once as the main user's name, once as a post author's name); these are two separate resolver invocations with different `root` arguments; the same resolver function handles both but with different context. (5) INSIGHT: a senior engineer notes that the N+1 pattern is most visible in the resolution tree diagram; any resolver that takes the `root.id` and fetches from the database is a DataLoader candidate; every list resolver is a DataLoader candidate.

---

### 💻 Code Example

```javascript
// BAD: Naive resolvers with N+1 database queries
// (no DataLoader batching)

const resolvers = {
  Query: {
    posts: async () => {
      // Returns 100 posts
      return db.query('SELECT * FROM posts');
    }
  },
  Post: {
    // This runs 100 times (once per post)
    author: async (post) => {
      // 100 individual SELECT queries!
      return db.query(
        'SELECT * FROM users WHERE id = ?',
        [post.authorId]
      );
    }
  }
};
// Total: 1 (posts) + 100 (authors) = 101 DB queries
// For 100 posts with authors
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the N+1 anti-pattern where the `author` resolver executes one database query per post, totaling 101 queries for 100 posts. (2) KEY MECHANISM: GraphQL calls `Post.author(root=post, ...)` for each post object returned by `Query.posts`; each call executes an independent `SELECT WHERE id = ?` query; the database connection pool handles these queries sequentially (or with limited concurrency). (3) WHY IT MATTERS: 101 queries vs 1 query is a 100x overhead on the database; with 100 concurrent users each requesting a post list, that is 10,100 queries/second instead of 100; typical databases struggle above 10,000 queries/second. (4) WHAT BREAKS: database connection pool exhaustion; each query holds a connection; with 101 concurrent queries per request and a pool of 20 connections, requests queue; response time degrades; eventually timeouts and 500 errors. (5) TAKEAWAY: any resolver that does `SELECT * FROM table WHERE id = root.foreignKeyId` is an N+1 candidate; use DataLoader to batch these into `SELECT * FROM table WHERE id IN (id1, id2, ..., id100)`.

```javascript
// GOOD: Resolvers with DataLoader batching

const DataLoader = require('dataloader');

// DataLoader for batching user lookups
// batchFn receives ALL requested IDs at once
const createUserLoader = () => new DataLoader(
  async (userIds) => {
    // ONE query for ALL requested user IDs
    const users = await db.query(
      'SELECT * FROM users WHERE id IN (?)',
      [userIds]
    );
    // Map: preserve order matching userIds array
    return userIds.map(
      id => users.find(u => u.id === id) || null
    );
  }
);

// DataLoader is created per-request (in context)
// to prevent cache leaks across requests
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => ({
    db,
    loaders: {
      user: createUserLoader()   // Fresh per request
    }
  })
});

const resolvers = {
  Query: {
    posts: async (_, __, { db }) => {
      return db.query('SELECT * FROM posts');
    }
  },
  Post: {
    // Now batched: DataLoader collects all author IDs
    // from all posts and issues ONE query
    author: async (post, _, { loaders }) => {
      return loaders.user.load(post.authorId);
      // DataLoader defers execution until end of tick
      // Then batches ALL load() calls: 100 IDs -> 1 query
    }
  }
};
// Total: 1 (posts) + 1 (all authors batched) = 2 queries!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the DataLoader pattern that reduces 101 database queries to 2 by batching all `author` resolver calls into a single `IN (...)` query. (2) KEY MECHANISM: DataLoader's `batchFn` receives an array of all IDs that were passed to `load()` in the same event loop tick; the 100 `loaders.user.load(post.authorId)` calls in the post list all collect into one batch; the batch function issues one `SELECT ... WHERE id IN (1,2,...100)` query; DataLoader maps the results back to the individual calls. (3) WHY IT MATTERS: from 101 queries to 2 queries is a 50x reduction; DataLoader also caches loaded values within the same request (if user 42 is an author of two posts, DataLoader loads it once and returns the cached value for the second post). (4) WHAT BREAKS: the order-preservation requirement in `batchFn` is critical; `userIds.map(id => users.find(u => u.id === id))` preserves the input order; if the database returns users in a different order and the map is not done, DataLoader will return wrong users for wrong posts. (5) TAKEAWAY: create DataLoader instances in the request context (not globally); a global DataLoader would cache data across requests, causing users to see each other's private data; per-request DataLoaders are safe.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> A resolver is a function that fetches data for one field in the GraphQL schema. When
> a client sends a query, GraphQL calls the resolver for each requested field in order
> from the root (`Query`) down to leaf scalar values. Each resolver receives: the parent
> object (`root`/`parent`), the field's arguments (`args`), shared request data (`context`),
> and query metadata (`info`). If no resolver is defined for a field, GraphQL uses a
> default resolver that returns `root.fieldName`. Custom resolvers are needed for root
> fields and for fields that require database queries or custom logic.

---

**Senior / Staff (5+ years):**
> Resolvers form the execution engine of GraphQL. Key production concerns: (1) Default
> resolver behavior: GraphQL provides a default resolver for object type fields that
> returns `root.fieldName`; only root Query/Mutation fields and fields with custom logic
> need explicit resolvers. (2) N+1 problem: every list resolver without DataLoader creates
> N+1 database queries; DataLoader is the standard solution. (3) Resolver purity: resolvers
> should be pure I/O functions (fetch data, return it); business logic belongs in a service
> layer called by resolvers, not in the resolver itself. (4) Context as dependency injection:
> the context object carries database connections, auth info, and DataLoader instances;
> share database connections via context rather than creating new connections per resolver.
> (5) `info` argument: carries the query AST; advanced optimizations (database query
> projection - only SELECT requested fields) use `info` to determine which fields were
> requested.

---

### ⚠️ Common Misconceptions

**Misconception: "Every field in the schema needs a custom resolver."**

GraphQL has default resolvers for object type fields. The default resolver is:
`return root[fieldName]`. This means that for any object type field that directly
maps to a property of the parent object, no custom resolver is needed. Example: if
`Query.user` returns `{ id: "1", name: "Alice", email: "alice@example.com" }` from
a database query, then `User.name` and `User.email` field resolvers are not needed;
the default resolver reads `root.name` and `root.email` automatically. Custom resolvers
are needed for: (1) root Query and Mutation fields (they start the resolution chain),
(2) fields that need a database query or external service call, (3) fields with computed
values (e.g., `fullName` combining `firstName + " " + lastName`), (4) fields with
access control logic. A common mistake is writing a resolver for every field
"just to be explicit" - this adds unnecessary boilerplate.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Resolver returns incorrect data due to wrong DataLoader ordering.**

Symptom: post authors are swapped; post "Article A" shows author "Bob" but should show
"Alice"; no errors in the response.
Root cause: DataLoader batch function does not preserve the input ID order when returning
results; database returns users in a different order than requested IDs.

```javascript
// BAD: DataLoader batchFn without order preservation
const userLoader = new DataLoader(async (userIds) => {
  const users = await db.query(
    'SELECT * FROM users WHERE id IN (?)',
    [userIds]
  );
  // BUG: returns users in DB order, not userIds order
  return users;
  // DB returns: [Bob (id=2), Alice (id=1)]
  // userIds was: [1, 2] (Alice first)
  // DataLoader maps: id=1 -> Bob (WRONG!), id=2 -> Alice
});

// GOOD: Preserve order matching userIds input
const userLoader = new DataLoader(async (userIds) => {
  const users = await db.query(
    'SELECT * FROM users WHERE id IN (?)',
    [userIds]
  );
  const userMap = new Map(
    users.map(u => [String(u.id), u])
  );
  // Map input IDs to users in exact input order
  return userIds.map(
    id => userMap.get(String(id)) || null
  );
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the DataLoader order-preservation requirement and the bug that occurs when the batch function returns results in database order instead of input ID order, causing data to be mapped to wrong entities. (2) KEY MECHANISM: DataLoader requires the batch function to return an array where index `i` corresponds to `userIds[i]`; if the database returns users in a different order, the mapping fails silently; user IDs are mapped to wrong user objects. (3) WHY IT MATTERS: this bug is silent - no error, just wrong data; a post shows the wrong author; in a social application, this could expose private data (user A sees user B's private profile fields). (4) WHAT BREAKS: using a Set or object map that doesn't preserve insertion order causes the same issue; always explicitly sort output using `userIds.map(id => userMap.get(id))`. (5) TAKEAWAY: the DataLoader batch function contract: return an array of length `userIds.length` where the item at each index corresponds to the ID at the same index; use a Map for O(1) lookup and explicit ordering; test with multiple IDs in non-sequential order.

---

### ⚖️ Comparison Table

| Aspect | Root Resolver | Field Resolver | Default Resolver |
|---|---|---|---|
| When called | Start of query for root fields | When parent object has been resolved | When no explicit resolver defined |
| Root argument | null | Parent object from parent resolver | Parent object |
| Custom logic | Always required | When DB query needed | Never (built-in) |
| DataLoader | Not applicable | Apply for list items | Not applicable |
| Example | `Query.user` | `User.posts` | `User.name` |

---

### 🏛️ System Design

*(Omit: L1 keyword; resolver architecture at scale covered in L4 Production entries.)*

---

### 📊 Diagram

```text
RESOLVER ARGUMENT FLOW:

  Query.user(root=null, args={id:"1"}, ctx, info)
  |
  +-- Returns: { id:"1", name:"Alice", posts:[...] }
  |
  +--> User.name(root={id:"1",name:"Alice",...}, args={})
  |    Default resolver: returns "Alice"
  |
  +--> User.posts(root={id:"1",...}, args={limit:5})
       Custom resolver: db.query("SELECT FROM posts
         WHERE user_id=1 LIMIT 5")
       |
       +-- Returns: [{id:"10", title:"Post A", authorId:"2"}]
       |
       +--> Post.title(root={id:"10",title:"Post A"}, args={})
       |    Default resolver: returns "Post A"
       |
       +--> Post.author(root={id:"10", authorId:"2"}, args={})
            DataLoader: loaders.user.load("2")
            Batched with other Post.author calls
            Returns: { id:"2", name:"Bob" }
            |
            +--> User.name(root={id:"2",name:"Bob"}, args={})
                 Default resolver: returns "Bob"

  CONTEXT flows to ALL resolvers (shared):
  ctx = { db, user (from auth), loaders }
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the resolver argument flow through a nested query showing how `root`, `args`, and `context` flow from the root resolver down to scalar leaf resolvers. (2) HOW TO READ IT: each arrow shows the direction of resolver execution (parent to child); the indentation represents nesting depth; `root` at each level is the return value of the parent resolver; `context` is horizontal (shared across all resolvers at all depths). (3) KEY RELATIONSHIP: `context` is the dependency injection mechanism; it carries `db` (database connection pool), `user` (authenticated user), and `loaders` (DataLoader instances); all resolvers at all depths share the same context object, making authentication and DataLoader batching work consistently. (4) EDGE CASE: `root` at the Query level is `null` (or the root value passed to the executor); Query resolvers that try to access `root.something` will get null; they must use `args` and `context` for all data access. (5) INSIGHT: a senior engineer recognizes that the context object is where the "service layer" lives; the context carries database connections, service clients, and auth state; resolvers that access `context.db` or `context.services.orderService` follow the dependency injection pattern and are testable in isolation.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | resolver signature, default resolvers |
| Application | 2 | DataLoader integration, context pattern |
| Trade-off | 1 | resolver location, business logic in resolvers |
| Scenario | 2 | N+1 diagnosis, DataLoader ordering bug |

---

**[JUNIOR] Q1 (Definition): What arguments does a resolver receive and what is each used for?**

A resolver function receives four arguments:

1. `root` (also called `parent`): the resolved value of the parent field. For root
   Query/Mutation resolvers, `root` is null (or the configured root value). For nested
   field resolvers, `root` is the object returned by the parent resolver.
   Usage: access the parent entity's fields (e.g., `root.id`, `root.authorId`).

2. `args`: an object containing all arguments passed to the field in the query.
   For `user(id: "1")`, `args = { id: "1" }`. For `posts(limit: 10, offset: 0)`,
   `args = { limit: 10, offset: 0 }`.
   Usage: filter/pagination/sorting arguments for the resolver's data fetch.

3. `context`: a shared object available to ALL resolvers for a request. Contains
   database connections, authenticated user info, DataLoader instances, and anything
   needed across resolvers.
   Usage: access shared resources without passing them through the resolver chain.

4. `info`: the current query AST and execution state. Contains `fieldName` (current
   field), `returnType` (GraphQL type), `schema` (the full schema), and `path` (field
   path for error reporting).
   Usage: advanced optimizations (selective SQL projection), custom directives,
   error tracing.

*What separates good from great:* The `info` argument for database projection optimization.
`info.fieldNodes` contains the AST of the currently resolving field, including which
sub-fields were requested. A sophisticated resolver can use this to project only the
requested columns in a SQL query: if the client only requests `user { name }`, the
resolver can run `SELECT name FROM users WHERE id = 1` instead of `SELECT * FROM users
WHERE id = 1`. Libraries like `graphql-fields` and `graphql-parse-resolve-info` extract
the requested fields from `info` for this purpose. This optimization is significant for
tables with many columns or large text columns (like content/description fields).

---

**[JUNIOR] Q2 (Application): What is a default resolver and when does GraphQL use it?**

The default resolver is GraphQL's built-in fallback for fields that have no explicit
resolver function defined. It performs: `return root[fieldName]`. In other words, it
reads the property named after the field from the parent object.

GraphQL uses the default resolver when:
- The type has no resolver map entry for the field.
- Or the resolver map entry for the field is `undefined`.

Example:
```javascript
// BAD: Unnecessary explicit resolvers
// (duplicating default resolver behavior)
const resolvers = {
  User: {
    id: (user) => user.id,       // Unnecessary
    name: (user) => user.name,   // Unnecessary
    email: (user) => user.email  // Unnecessary
  }
};

// GOOD: Only define resolvers for non-trivial fields
// BAD: (see above - default resolver handles id/name/email)
const resolvers = {
  Query: {
    user: (_, { id }) => db.findUser(id)
    // Returns: { id, name, email, ... }
    // Default resolver handles all scalar fields
  },
  User: {
    // Only custom resolver needed:
    posts: (user) => db.findPostsByUserId(user.id),
    fullName: (user) => `${user.firstName} ${user.lastName}`
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: eliminating unnecessary explicit resolvers that just return `root.fieldName` (which is exactly what the default resolver does), and keeping only resolvers that have actual custom logic. (2) KEY MECHANISM: when GraphQL executes `user.name`, it looks for a `User.name` resolver in the resolver map; if not found, it uses the default resolver which returns `root['name']`; if the User object from the database has a `name` property, this works without any explicit resolver. (3) WHY IT MATTERS: unnecessary explicit resolvers add boilerplate code that obscures which fields have real custom logic; with 20 unnecessary trivial resolvers and 2 meaningful ones, the meaningful ones are lost in the noise. (4) WHAT BREAKS: the default resolver is case-sensitive; `User.avatarUrl` with the camelCase field name will not find `root.avatar_url` (snake_case database column) automatically; a custom resolver or field name transformation is needed for snake_case to camelCase conversion. (5) TAKEAWAY: only define explicit resolvers when the resolver has logic beyond `return root[fieldName]`; let the default resolver handle trivial field access; use a field name transformer for snake_case to camelCase if the database returns snake_case column names.

*What separates good from great:* The field name aliasing resolver pattern. Production
databases often use snake_case column names (`created_at`, `user_id`, `full_name`) while
GraphQL convention is camelCase (`createdAt`, `userId`, `fullName`). Options: (1) write
explicit resolvers for every snake_case field, (2) transform column names when constructing
resolver return objects, (3) use a library like `snakeCaseMiddleware` that transforms
all root object keys. Option 2 (transform in the root resolver, not the field resolver)
is most common in production: `return { ...user, createdAt: user.created_at }`. This
centralizes the transformation in the root resolver and keeps field resolvers trivial.

---

**[SENIOR] Q3 (Application): How do you implement a service layer pattern with GraphQL resolvers?**

The service layer pattern separates business logic from GraphQL resolvers. Resolvers
become thin wrappers that: (1) validate input (already handled by GraphQL schema), (2)
call the appropriate service method, (3) return the result.

```javascript
// BAD: Business logic directly in resolver
const resolvers = {
  Mutation: {
    createOrder: async (_, { input }, { db, user }) => {
      // Business logic inline in resolver:
      const cart = await db.getCart(input.cartId);
      if (cart.userId !== user.id) {
        throw new Error('Not your cart');
      }
      const inventory = await db.checkInventory(
        cart.items
      );
      if (!inventory.allAvailable) {
        throw new Error('Out of stock');
      }
      const payment = await paymentService.charge(
        input.paymentMethodId,
        cart.total
      );
      const order = await db.createOrder({
        userId: user.id,
        cartId: input.cartId,
        paymentId: payment.id
      });
      await emailService.sendConfirmation(
        user.email, order
      );
      return order;
      // Problems: untestable, not reusable,
      // mixes GraphQL concerns with business logic
    }
  }
};

// GOOD: Thin resolver calling a service
const resolvers = {
  Mutation: {
    // BAD: (see above - logic in resolver)
    createOrder: async (_, { input }, { services, user }) => {
      return services.orderService.createOrder(
        user.id, input
      );
      // Thin: just pass args to service
    }
  }
};

// Service: testable independently of GraphQL
class OrderService {
  async createOrder(userId, input) {
    const cart = await this.cartRepository.get(
      input.cartId
    );
    this.validateCartOwnership(cart, userId);
    await this.inventoryService.validateStock(cart);
    const payment = await this.paymentService.charge(
      input.paymentMethodId, cart.total
    );
    const order = await this.orderRepository.create({
      userId, cartId: input.cartId,
      paymentId: payment.id
    });
    await this.emailService.sendConfirmation(order);
    return order;
  }
}
// Test OrderService without GraphQL context!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: refactoring an inline business logic resolver into a thin resolver that delegates to an OrderService, making the business logic testable independently of GraphQL. (2) KEY MECHANISM: the resolver's context carries `services` (which contains service instances); the resolver is one line (call service, return result); the `OrderService` can be instantiated and tested with mock repositories without any GraphQL infrastructure. (3) WHY IT MATTERS: inline resolver business logic can only be tested by running a full GraphQL server with a test schema; a service layer can be unit tested with mock dependencies; the test pyramid requires unit tests (fast, isolated) to be the majority. (4) WHAT BREAKS: services that access the GraphQL `context` directly (e.g., services that take `context.user` instead of a plain `userId`) become tightly coupled to GraphQL; pass primitive values (IDs, strings) to services, not the GraphQL context object. (5) TAKEAWAY: the GraphQL resolver layer is a delivery mechanism (like HTTP controllers in REST); business logic belongs in services; resolvers should be thin wrappers of 1-3 lines each; if a resolver is more than 10 lines, extract to a service.

*What separates good from great:* The service layer as the authorization boundary. In
the service layer pattern, authorization checks belong in the service, not the resolver.
The resolver just calls the service; the service verifies permissions and throws if
unauthorized. This means the service enforces authorization regardless of how it is
called (GraphQL resolver, REST controller, background job). If authorization is only in
the GraphQL resolver, a non-GraphQL caller (a background job that calls the service
directly) bypasses authorization. Service-level authorization is the defense-in-depth
principle applied to the service layer.

---

**[JUNIOR] Q4 (Definition): What is the resolution chain and how does GraphQL traverse it?**

The resolution chain is the ordered sequence of resolver calls that GraphQL executes to
fulfill a query, starting from the root type (Query) and traversing down through nested
types to scalar leaf values.

Traversal rules:
1. Start at the root: the Query (or Mutation/Subscription) type's root field resolver.
2. Execute children: after a resolver returns an object, GraphQL calls the resolvers for
   each requested child field, passing the returned object as `root`.
3. Execute in parallel when possible: sibling fields (at the same depth in the tree)
   can execute concurrently (when they are independent).
4. Terminate at scalars: when a resolver returns a scalar (String, Int, etc.), traversal
   stops; no children to resolve.
5. Handle null: if a resolver returns null for a nullable field, traversal stops for
   that branch (no children); if a resolver returns null for a non-null field, error
   propagation begins.

The chain depth equals the query nesting depth. A query 5 levels deep has a resolution
chain of depth 5. Depth limiting (discussed in L2 Performance) controls how deep the
chain can go for security.

*What separates good from great:* The resolution chain as a tree, not a chain. The term
"resolution chain" implies sequential execution, but the actual execution model is a
tree traversal with potential parallelism. Sibling resolvers execute concurrently in
Apollo Server (Node.js: I/O-bound resolvers run concurrently via Promise.all). The
"chain" is sequential only from root to leaf in a single branch; across branches, execution
is parallel. Understanding this tree model explains why N+1 occurs (each item in a list
is a separate branch, each with its own author resolver call) and why DataLoader works
(it collects calls from all branches in the same event loop tick and batches them).

---

**[SENIOR] Q5 (Trade-off): When is it appropriate to have resolver logic vs pushing logic to the database layer?**

Two extremes and their trade-offs:

Resolver-heavy (logic in resolvers):
- Pros: language-agnostic business logic; testable without database; composable service
  layer; works across multiple databases.
- Cons: more round-trips to the database; complex filtering/aggregation is less efficient
  in code than in SQL; N+1 problems require DataLoader.

Database-heavy (logic in SQL/stored procedures):
- Pros: filtering, sorting, aggregation are SQL strengths; one database call vs many;
  database query optimizer handles complex JOINs efficiently.
- Cons: business logic in the database is harder to test; stored procedures are database-
  specific (vendor lock-in); less flexible for non-SQL data sources.

Decision framework:
- Simple filtering and sorting: push to database (WHERE clause, ORDER BY).
- Aggregations (SUM, COUNT, AVG): push to database.
- Data from multiple unrelated sources (one field from SQL, another from Redis):
  resolver layer with DataLoader batching.
- Complex business rules (multi-step validation, conditional logic): service layer.
- Full-text search: dedicated search service (Elasticsearch/OpenSearch).

*What separates good from great:* The query projection optimization. The `info` argument
in resolvers contains which fields were requested. An advanced resolver uses this to
generate a minimal SQL SELECT: `SELECT id, name FROM users` when only `id` and `name`
are requested, instead of `SELECT *`. Libraries like `graphql-parse-resolve-info` extract
the requested fields. This optimization is most impactful for tables with many columns
or BLOB/TEXT columns that are expensive to transfer; selecting only the needed columns
can reduce query I/O by 80% for wide tables.

---

**[JUNIOR] Q6 (Application): How do you handle a resolver that needs data from multiple sources?**

A resolver can call multiple data sources and merge the results. The pattern is the
same as any async function: await each source and return the combined object.

```javascript
// User resolver combining SQL user data
// with Redis cached profile stats
const resolvers = {
  Query: {
    user: async (_, { id }, { db, redis }) => {
      // Parallel fetch from two sources
      const [user, stats] = await Promise.all([
        db.query(
          'SELECT * FROM users WHERE id = ?', [id]
        ),
        redis.hgetall(`user:stats:${id}`)
      ]);

      if (!user) return null;

      // Merge: SQL fields + Redis cached stats
      return {
        ...user,
        postCount: stats?.postCount || 0,
        followerCount: stats?.followerCount || 0
      };
    }
  }
};
// parallel sources: lower latency than sequential
// Promise.all: both queries run concurrently
```

> **Code walkthrough:** (1) WHAT IT SHOWS: fetching data from two sources (PostgreSQL and Redis) in parallel using `Promise.all` and merging the results into a single resolver return value. (2) KEY MECHANISM: `Promise.all([sqlPromise, redisPromise])` runs both queries concurrently; total latency = max(SQL latency, Redis latency); sequential execution would be SQL latency + Redis latency; parallel is faster. (3) WHY IT MATTERS: profile stats (post count, follower count) are frequently accessed but expensive to compute in SQL; caching in Redis and merging in the resolver provides SQL's structured querying for user fields and Redis's low-latency for stats. (4) WHAT BREAKS: if the Redis stats are unavailable (Redis down), `stats` is null; the `stats?.postCount || 0` null-safe access returns 0 as the fallback; the user is still returned; graceful degradation on partial source failure. (5) TAKEAWAY: the multi-source resolver pattern works for any combination of data stores; use `Promise.all` for independent sources; the resolver returns a merged object; child resolvers use the merged object via the default resolver (or custom if needed).

*What separates good from great:* The single-source-of-truth principle for cache invalidation.
When a resolver merges a SQL source (authoritative) with a Redis cache (derived), the
cache must be invalidated when the SQL data changes. A mutation that updates `postCount`
in SQL must also update `user:stats:{id}` in Redis. Without invalidation, the merged
object returns stale stats. The event-driven invalidation pattern: mutations publish
events (e.g., "post created"); an event handler updates the Redis cache. This is more
reliable than trying to update the cache in the mutation resolver itself (which may fail
and leave the cache inconsistent). Cache invalidation at the event level is a production
architecture pattern for multi-source resolvers.

---

**[JUNIOR] Q7 (Scenario): A query for a list of users with their posts is slow. How do you investigate and fix it?**

Step 1 - Measure resolver timings with Apollo Tracing:

```bash
# Enable Apollo Tracing in server config:
# ApolloServer({ tracing: true })
# Check response for tracing data:

curl -s http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ users { id posts { title } } }"}' \
  | python3 -m json.tool | grep -A5 "tracing"

# Output:
# "tracing": {
#   "execution": {
#     "resolvers": [
#       {"path": ["users"], "duration": 15000000},
#       {"path": ["users", 0, "posts"], "duration": 12000000},
#       {"path": ["users", 1, "posts"], "duration": 11000000},
#       ... (100 more Post resolver entries)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using Apollo Server tracing to get per-resolver timing data, which reveals that `Post.posts` is called 100 times (once per user), each taking ~12ms - the N+1 signature. (2) KEY MECHANISM: Apollo tracing adds a `tracing` object to GraphQL responses containing execution timing for every resolver call; the 100 entries for `users.N.posts` with similar durations is the visual N+1 pattern in timing data. (3) WHY IT MATTERS: 100 × 12ms = 1,200ms for post loading alone; without tracing, the slow query is diagnosed by guess; with tracing, the exact resolver and its call count are immediately visible. (4) WHAT BREAKS: enabling tracing in production adds response payload size (100+ resolver timings in the response body); use Apollo Studio's cloud tracing instead (reports timing data separately, does not add to response payload). (5) TAKEAWAY: enable Apollo tracing in development and staging for all queries; use it as the first diagnostic tool for performance investigation; look for the N+1 pattern (same resolver path at different indices with similar durations).

Step 2 - Identify the N+1:
The tracing output shows `User.posts` (or whatever the list field is) being called once
per user. Each call is a separate database query. This is the N+1 pattern.

Step 3 - Apply DataLoader:
Create a DataLoader that batches `SELECT * FROM posts WHERE user_id IN (...)`.
Use it in the `User.posts` resolver via the context: `loaders.postsByUserId.load(user.id)`.

Step 4 - Re-measure:
After DataLoader, tracing should show `User.posts` resolver calls completing in < 1ms
(cache hit from DataLoader) after the initial batch completes.

*What separates good from great:* The DataLoader key design. When batching `posts by userId`,
the DataLoader key is `userId` and the batch function returns an array of posts for each
userId (multiple posts per key). This is a "one-to-many" DataLoader. Standard DataLoader
returns one value per key; for one-to-many, the batch function must return an array of
arrays: `return userIds.map(id => posts.filter(p => p.userId === id))`. The ordering
constraint still applies to the outer array (matches userIds order); the inner array
(posts for each user) can be in any order. Implementing one-to-many DataLoader correctly
is the most common DataLoader implementation pattern in production.

---

# Context and Authentication in GraphQL

---

### 🎯 Model Answer

**30 seconds:**
> The GraphQL `context` is a shared object populated once per request and passed to
> every resolver. It is the standard way to share authentication state, database connections,
> and DataLoader instances across all resolvers without prop-drilling. Authentication in
> GraphQL: verify the token in the context function (before resolvers run); attach the
> authenticated user to context; resolvers check `context.user` for authorization.

**3 minutes (Senior):**
> The context function runs once per request and receives the raw HTTP request; it returns
> the context object that all resolvers share. This is the dependency injection layer for
> GraphQL servers. Authentication pattern: (1) extract the token from the Authorization
> header in the context function, (2) verify the token (JWT verification, session lookup),
> (3) attach the authenticated user object to context, (4) resolvers access `context.user`
> for authorization decisions. Critical security consideration: authentication is in the
> context function (throws if token invalid); authorization is in resolvers or the service
> layer (checks if the authenticated user has permission to access the requested resource).
> Do NOT confuse authentication (who are you?) with authorization (what can you do?).
> Field-level authorization: sensitive fields (salary, private email) must check authorization
> in their specific resolver; the schema does not automatically hide fields from unauthorized
> users; resolvers must explicitly enforce field-level access control.

**Blank Mind Recovery:**

**(1) Restate:** "Context: shared object per request, passed to every resolver. Contains:
authenticated user, database connections, DataLoaders. Auth pattern: verify token in context
function, attach user to context, check context.user in resolvers. Authentication = who?
Authorization = what can they do? Both required; different locations."

---

### 📘 Concept Explanation

**Context Function and Authentication Flow:**

```text
REQUEST AUTHENTICATION FLOW:

  Client Request
  { Authorization: "Bearer eyJhbGci..." }
        |
        v
  context() function (runs ONCE per request)
  1. req.headers.authorization
  2. Extract "Bearer" token
  3. Verify JWT signature
  4. Decode payload -> { userId, role }
  5. Load user from DB (optional - expensive)
  6. Return context:
     {
       user: { id: "1", role: "ADMIN" },
       db: connectionPool,
       loaders: { user: DataLoader, ... }
     }
        |
        v
  GraphQL execution begins
  All resolvers receive context

  Query.orders(root, args, context)
  -> context.user exists? (authentication check)
  -> context.user.role === "ADMIN"? (auth check)
  -> db.query("SELECT * FROM orders")

  AUTHENTICATION vs AUTHORIZATION:
  Authentication: "Who are you?"
  -> Verify token in context()
  -> Throw if invalid/expired

  Authorization: "Can you do this?"
  -> Check context.user.role in resolver
  -> Check context.user.id === resource.ownerId
  -> Throw GraphQL error if not permitted
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the authentication flow from the incoming HTTP request through the context function to resolver-level authorization, separating authentication (context function) from authorization (resolver). (2) HOW TO READ IT: follow the flow top-to-bottom; the context function runs once and establishes identity; all resolvers run after context is set and use `context.user` for their authorization checks. (3) KEY RELATIONSHIP: the context function is the authentication boundary; if the JWT is invalid or expired, throw an error in the context function; the request is rejected before any resolver runs; resolvers can assume `context.user` is valid if it exists. (4) EDGE CASE: some GraphQL endpoints are public (no auth required, e.g., `query { publicPosts { title } }`); throw in the context function ONLY for authentication failures, not for unauthenticated requests; set `context.user = null` for unauthenticated requests and let resolvers decide if auth is required. (5) INSIGHT: a senior engineer centralizes authentication in the context function and distributes authorization to resolvers (or the service layer); this ensures authentication is never bypassed (it runs before every request) while keeping authorization flexible (each resolver enforces its own rules).

---

### 💻 Code Example

```javascript
// BAD: Authentication in every resolver separately
// (inconsistent; easy to miss a resolver)

const resolvers = {
  Query: {
    myProfile: async (_, __, { req }) => {
      // BAD: each resolver re-verifies token
      const token = req.headers.authorization;
      if (!token) throw new Error('Not authenticated');
      const user = await verifyToken(token);  // Repeated
      return db.getUser(user.id);
    },
    myOrders: async (_, __, { req }) => {
      // Same verification code repeated
      const token = req.headers.authorization;
      if (!token) throw new Error('Not authenticated');
      const user = await verifyToken(token);  // Repeated
      return db.getOrders(user.id);
    }
    // If developer forgets auth check in one resolver:
    // -> security hole; that field is publicly accessible
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the anti-pattern of repeating authentication verification in every resolver, which is verbose, inconsistent, and creates security gaps when a developer forgets to add the check. (2) KEY MECHANISM: when authentication is per-resolver, every new resolver added to the codebase requires the developer to remember to add the auth check; this is a security requirement relying on developer discipline rather than enforcement. (3) WHY IT MATTERS: one forgotten auth check exposes a resolver to unauthenticated access; in a large codebase with many resolvers, the probability of a missed check increases; the context-based pattern eliminates this class of bugs. (4) WHAT BREAKS: the repeated `verifyToken(token)` calls also add latency; JWT verification is computationally cheap but database lookups for session-based auth are not; doing this per-resolver means N token verifications per query with N resolvers. (5) TAKEAWAY: authentication belongs in the context function (once per request); authorization belongs in resolvers (per-field decision); never do authentication in individual resolvers.

```javascript
// GOOD: Authentication centralized in context function,
// authorization in resolvers

// Apollo Server context function
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: async ({ req }) => {
    // Authentication: runs ONCE per request
    const token = req.headers.authorization
      ?.replace('Bearer ', '');

    let user = null;
    if (token) {
      try {
        const payload = jwt.verify(
          token, process.env.JWT_SECRET
        );
        // Optional: load full user from DB
        // (or use JWT claims directly)
        user = await db.getUserById(payload.userId);
      } catch (err) {
        // Invalid token: throw here if ALL endpoints need auth
        // Or set user = null if some endpoints are public
        throw new AuthenticationError(
          'Invalid or expired token'
        );
      }
    }

    return {
      user,                      // null if unauthenticated
      db,                        // Shared DB connection
      loaders: {                 // Per-request DataLoaders
        user: createUserLoader(db)
      }
    };
  }
});

// Resolvers: only authorization, no authentication
const resolvers = {
  Query: {
    myProfile: async (_, __, { user, db }) => {
      // Authorization: check if user is authenticated
      if (!user) throw new AuthenticationError(
        'Must be logged in'
      );
      return db.getUser(user.id);
    },
    adminStats: async (_, __, { user, db }) => {
      // Authorization: check role
      if (!user || user.role !== 'ADMIN') {
        throw new ForbiddenError(
          'Admin access required'
        );
      }
      return db.getSystemStats();
    },
    publicPosts: async (_, __, { db }) => {
      // No auth required: public endpoint
      return db.getPublicPosts();
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: centralizing authentication in the Apollo Server `context` function (runs once per request, verifies the JWT, attaches the user) and distributing authorization to individual resolvers (check `context.user` for authentication state and role for authorization). (2) KEY MECHANISM: the context function runs before any resolver; JWT verification happens once; the `user` object is attached to context; resolvers receive `user` and make access decisions without re-verifying the token. (3) WHY IT MATTERS: authentication runs exactly once per request regardless of how many resolvers execute; the `publicPosts` resolver does not need any auth check - it simply ignores `user`; the pattern scales cleanly to any number of resolvers. (4) WHAT BREAKS: if `JWT_SECRET` is not set in environment variables, `jwt.verify` throws a generic error; always validate environment configuration at server startup, not at request time. (5) TAKEAWAY: the context pattern is the GraphQL authentication standard; every GraphQL server tutorial and production guide recommends this pattern; implement it before writing any resolver.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> The context object is populated once per request in the context function. It carries
> shared data like the authenticated user, database connections, and DataLoader instances.
> All resolvers receive the same context object. For authentication: verify the JWT token
> in the context function, attach the user to context if valid, and check `context.user`
> in resolvers that require authentication. This way, authentication logic is in one place
> and resolvers just check if the user is present.

---

**Senior / Staff (5+ years):**
> Context is the dependency injection mechanism for GraphQL servers. Production considerations:
> (1) Authentication in context, authorization in resolvers (or service layer) - never
> mix them. (2) Per-request DataLoaders - create DataLoader instances in the context
> function, not globally; global DataLoaders cache across requests and cause data leaks.
> (3) Context poisoning risk: avoid putting mutable state in context; if two concurrent
> resolvers modify context, they will interfere; use immutable context objects. (4) Field-level
> authorization requires resolvers to check permissions; schema tools like graphql-shield
> provide declarative authorization rules on fields without code in resolvers. (5) Auth
> errors: use dedicated error classes (AuthenticationError, ForbiddenError) not generic
> Error; clients distinguish 401 (unauthenticated) from 403 (unauthorized) via the error
> code.

---

### ⚠️ Common Misconceptions

**Misconception: "Setting up authentication in the context function automatically protects all fields."**

Authentication in the context function only establishes identity (who the user is). It
does NOT automatically restrict access to any field. If you authenticate the user in
context (valid token, user attached to context) but do not add authorization checks in
resolvers, ALL fields are accessible to any authenticated user. A regular user could
query admin-only fields without any error. Field-level authorization requires explicit
checks in each resolver that has access restrictions: `if (!context.user || context.user.role !== "ADMIN") throw new ForbiddenError(...)`. Authorization frameworks like `graphql-shield`
provide a declarative way to define authorization rules per field, reducing the risk of
missing authorization checks. But the fundamental point remains: authentication ≠ authorization;
context-level authentication is step 1; field-level authorization is a separate, required step 2.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: DataLoader instances created globally, causing cross-request data leaks.**

Symptom: users see each other's data intermittently; user B's request returns user A's
profile data.
Root cause: DataLoader instances created outside the context function cache data across
requests; user A's data from a previous request is still in the cache when user B's
request runs.

```javascript
// BAD: Global DataLoader (SECURITY VULNERABILITY)
const globalUserLoader = new DataLoader(
  async (ids) => {
    return db.getUsersByIds(ids);
  }
);
// This DataLoader's cache persists ACROSS requests!
// User A loads user 1 -> cache: {1: UserA}
// User B requests user 1 -> returns cached UserA data
// Even if user 1's data changed or B should not see it

const server = new ApolloServer({
  context: () => ({
    loaders: {
      user: globalUserLoader  // WRONG: shared state
    }
  })
});

// GOOD: Per-request DataLoader (safe)
// BAD: (see above - global loader leaks data across requests)
const server = new ApolloServer({
  context: ({ req }) => ({
    user: authenticateRequest(req),
    db,
    loaders: {
      // Fresh DataLoader for EVERY request
      // Cache only lives for the duration of one request
      user: new DataLoader(
        async (ids) => db.getUsersByIds(ids)
      )
    }
  })
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the critical security difference between a global DataLoader (persists cache across requests - data leaks) and a per-request DataLoader (fresh instance each request - safe). (2) KEY MECHANISM: DataLoader's in-memory cache maps keys to promises; a global DataLoader's cache accumulates all loaded data for the server's lifetime; request A's data is in the cache when request B runs; if request B happens to load the same IDs, it gets request A's data from cache (even if request A belonged to a different user). (3) WHY IT MATTERS: this is a serious security vulnerability; authenticated users can see other users' private data; the symptom is intermittent and difficult to reproduce deterministically, making it hard to diagnose. (4) WHAT BREAKS: even without security concerns, a global DataLoader's cache grows unboundedly; after thousands of requests, the server's heap grows until OOM; global DataLoaders are both a security issue and a memory leak. (5) TAKEAWAY: ALWAYS create DataLoader instances in the context function (per-request); never create them globally; this is a security requirement, not just a best practice.

---

### ⚖️ Comparison Table

| Concern | Context Function | Resolver | Service Layer |
|---|---|---|---|
| Authentication | ✓ Verify token here | ✗ Check context.user only | Optionally re-verify |
| Authorization | ✗ No field context here | ✓ Per-field checks | ✓ Business rule enforcement |
| DB connection | ✓ Share pool via context | ✓ Use context.db | ✓ Injected via DI |
| DataLoader | ✓ Create per-request | ✓ Use context.loaders | N/A |
| Error handling | AuthenticationError | ForbiddenError | Domain errors |

---

### 🏛️ System Design

*(Omit: L1 keyword; auth architecture at scale covered in L4 entries.)*

---

### 📊 Diagram

```text
CONTEXT LIFECYCLE PER REQUEST:

  HTTP Request arrives
  { Authorization: "Bearer TOKEN" }
        |
  context({ req }) function
  - Verify JWT (AuthenticationError if invalid)
  - Load user from DB or decode from JWT
  - Create DataLoaders (per-request)
  - Return context object:
    { user, db, loaders }
        |
  Context injected into ALL resolvers:

  Query.user(root, args, {user, db, loaders})
       |           <- Receives same context
  User.posts(root, args, {user, db, loaders})
       |           <- Receives same context
  Post.author(root, args, {user, db, loaders})
              <- Same DataLoader instance!
              <- DataLoader batches across all
                 Post.author calls in this request

  Request ends:
  - Context object garbage collected
  - DataLoader cache cleared (per-request scope)
  - New request: fresh context, fresh DataLoaders
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the context lifecycle from HTTP request through context function creation to injection into all resolvers and garbage collection at request end. (2) HOW TO READ IT: the context function (top) creates a fresh context for each request; the same context object reference is shared by all resolvers (Query.user, User.posts, Post.author); the DataLoader in the context accumulates all `load()` calls from all Post.author resolver instances and issues one batched query. (3) KEY RELATIONSHIP: the shared DataLoader instance within a request is what enables batching; all 100 `Post.author` resolver calls use the SAME DataLoader instance from context; DataLoader collects all 100 IDs and issues one query. (4) EDGE CASE: if the context function throws (invalid JWT), NO resolvers run; the entire request is rejected before any data access occurs; this is the authentication guarantee. (5) INSIGHT: the context lifetime matching the request lifetime is the critical property; per-request context ensures DataLoader cache isolation between users and requests; this is both a correctness and security property.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 1 | context vs request scope |
| Application | 3 | auth pattern, context usage, DataLoader in context |
| Trade-off | 1 | field-level authorization approaches |
| Scenario | 2 | global DataLoader vulnerability, field auth gap |

---

**[JUNIOR] Q1 (Definition): What is the GraphQL context object and why is it important?**

The context object is a shared data object that is created once per request and passed
as the third argument to every resolver function in the request. It provides a consistent
way to share request-scoped data across all resolvers without passing it through the
resolver chain manually.

What context typically contains:
1. Authenticated user: `{ user: { id: "1", role: "ADMIN" } }` (null if unauthenticated).
2. Database connections: `{ db: postgresPool }` - shared connection pool instance.
3. DataLoader instances: `{ loaders: { user: DataLoader, post: DataLoader } }` - per-request
   batching caches.
4. Request metadata: `{ requestId: "uuid", correlationId: "trace-id" }` for logging.
5. Feature flags: `{ features: { newFeedAlgorithm: true } }` - request-specific flags.

Without context, sharing this data requires:
- Global variables (unsafe in concurrent requests).
- Passing data through the resolver chain (ugly, brittle).
- Re-loading data in each resolver (wasteful, inconsistent).

*What separates good from great:* The immutability principle for context. Context should
be treated as immutable after creation. If resolvers can modify the context object, they
can interfere with each other (resolver A modifies `context.user.role`; resolver B reads
the modified role). In practice: design context objects with readonly properties in
TypeScript; use `Object.freeze(context)` for strict immutability. If state must be shared
between resolvers (e.g., an audit log of which entities were accessed), use a mutable
collection within context (e.g., `context.accessLog = []`) but document it explicitly.

---

**[SENIOR] Q2 (Application): How do you implement JWT authentication in a GraphQL server?**

JWT authentication in Apollo Server:

```javascript
const jwt = require('jsonwebtoken');
const { AuthenticationError } = require('apollo-server');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: async ({ req }) => {
    // Step 1: Extract token
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ')
      ? authHeader.slice(7)
      : null;

    let user = null;
    if (token) {
      // Step 2: Verify token (throws on invalid)
      const payload = jwt.verify(
        token,
        process.env.JWT_SECRET,
        { algorithms: ['HS256'] }  // Explicit algorithm
      );
      // Step 3: Attach user (from payload or DB)
      // Option A: trust JWT claims (no DB round-trip)
      user = {
        id: payload.sub,
        role: payload.role,
        email: payload.email
      };
      // Option B: verify user still exists (more secure)
      // user = await db.getUserById(payload.sub);
      // if (!user || !user.isActive) {
      //   throw new AuthenticationError(
      //     'Account deactivated'
      //   );
      // }
    }

    return { user, db, loaders: createLoaders(db) };
  }
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: JWT authentication in the Apollo Server context function - token extraction, verification with explicit algorithm specification, and user population in context. (2) KEY MECHANISM: `jwt.verify()` validates the signature AND checks the expiry (`exp` claim); if either fails, it throws an error; the error is caught by the `if (token)` block (or re-thrown as `AuthenticationError`); the `algorithms` option prevents the "algorithm confusion" attack (accepting `alg: none`). (3) WHY IT MATTERS: specifying `{ algorithms: ['HS256'] }` prevents the JWT algorithm confusion attack where an attacker changes the `alg` header to `none` and removes the signature; without explicit algorithm, some JWT libraries accept unsigned tokens. (4) WHAT BREAKS: `jwt.verify()` throws `JsonWebTokenError` for invalid signatures and `TokenExpiredError` for expired tokens; catching these and re-throwing as `AuthenticationError` provides consistent error handling; not catching them exposes internal JWT error messages to clients. (5) TAKEAWAY: always specify `algorithms` in `jwt.verify()` as a security hardening measure; use `AuthenticationError` for authentication failures (returns error code that clients handle specially); never expose raw JWT error messages to clients.

*What separates good from great:* Option A vs Option B for user population. Option A
(trust JWT claims, no DB round-trip) is faster (no database query per request) but
has a security gap: if a user is deactivated after their JWT is issued, they continue
to have access until the JWT expires. Option B (verify user in DB per request) closes
this gap but adds a database query to every request. The production compromise: use
short-lived JWTs (15 minutes) with refresh tokens; Option A is safe because the
access window for a deactivated user is at most 15 minutes; the refresh token endpoint
verifies the user is still active and issues a new JWT.

---

**[JUNIOR] Q3 (Application): How do you restrict a GraphQL field to admin users only?**

Field-level authorization: check `context.user` in the field resolver and throw
if the user does not have the required role.

```javascript
const resolvers = {
  Query: {
    allUsers: async (_, __, { user, db }) => {
      // Must be authenticated
      if (!user) {
        throw new AuthenticationError(
          'You must be logged in'
        );
      }
      // Must be admin
      if (user.role !== 'ADMIN') {
        throw new ForbiddenError(
          'Only admins can list all users'
        );
      }
      return db.getAllUsers();
    }
  },
  User: {
    salary: (user, _, { currentUser }) => {
      // Field-level: only admin or own user
      if (!currentUser) {
        throw new AuthenticationError('Login required');
      }
      if (currentUser.role !== 'ADMIN'
        && currentUser.id !== user.id) {
        throw new ForbiddenError(
          'Cannot view salary'
        );
      }
      return user.salary;
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: field-level authorization for two fields - `Query.allUsers` (admin-only) and `User.salary` (admin or own user); each resolver independently enforces its access rules. (2) KEY MECHANISM: `AuthenticationError` indicates the user is not logged in (HTTP 401 equivalent); `ForbiddenError` indicates the user is logged in but lacks permission (HTTP 403 equivalent); Apollo Client and other GraphQL clients treat these error codes differently. (3) WHY IT MATTERS: `User.salary` demonstrates resource-level authorization (can see own salary but not others'); this is a common access pattern; the check `currentUser.id !== user.id` uses `currentUser` (from context) and `user` (the User being resolved) to implement owner-only access. (4) WHAT BREAKS: `context` renaming - using `context.user` in some resolvers and `context.currentUser` in others causes confusion; standardize on one name (e.g., always `context.user`). (5) TAKEAWAY: always check both authentication (user exists) AND authorization (user has permission) in resolvers that have access control; checking only one and not the other is an authorization gap.

*What separates good from great:* The `graphql-shield` declarative authorization approach.
As the number of fields with authorization rules grows, inline authorization checks in
every resolver become verbose and inconsistent. `graphql-shield` provides a rule-based
authorization layer that separates authorization logic from resolver logic. Define rules
once: `const isAdmin = rule()(() => context.user?.role === 'ADMIN')`. Apply to fields:
`const permissions = shield({ Query: { allUsers: isAdmin } })`. Rules are composable:
`and(isAuthenticated, isAdmin)`. This approach centralizes authorization, makes rules
auditable, and prevents missing authorization checks on new fields (new fields without
a shield rule default to deny or allow based on the default policy).

---

**[SENIOR] Q4 (Trade-off): What are the trade-offs between including all user info in JWT claims vs loading from the database on each request?**

JWT claims (decode, no DB):
- Pros: zero database queries for authentication; scalable (stateless JWT verification);
  lower latency per request.
- Cons: stale claims until JWT expiry (role change takes 15+ minutes to take effect);
  no revocation (compromised tokens cannot be immediately invalidated); payload grows
  with more claims (larger HTTP headers).

DB lookup (verify user on each request):
- Pros: always current data (role changes are immediate); token revocation works
  (delete session from DB); additional validation possible (check user is active, not banned).
- Cons: one database query per request (latency + DB load); reduces benefit of JWT's
  statelessness; DB becomes a scaling bottleneck for authentication.

Production compromise - short-lived JWT + refresh token:
- Access token: JWT, 15-minute expiry, trust claims, no DB lookup.
- Refresh token: long-lived (7 days), stored in DB, verifies user is active, issues
  new access tokens.
- Role changes: take effect within 15 minutes (access token expiry).
- Token revocation: delete refresh token from DB; attacker cannot get a new access
  token after the current one expires.

*What separates good from great:* The token revocation use case. "The VP was fired; how
do you immediately revoke their admin access?" With pure JWT claims and 24-hour expiry:
you cannot; the VP has 24 hours of admin access after being fired. With short-lived JWT
(15 min) + DB-verified refresh: delete the refresh token from the DB; the VP's next
token refresh fails; they lose access within 15 minutes. For high-security systems
(healthcare, finance, government), the short-lived JWT + refresh pattern is the minimum
acceptable revocation latency.

---

**[JUNIOR] Q5 (Application): How does GraphQL handle CORS and authentication for browser clients?**

CORS (Cross-Origin Resource Sharing) for GraphQL: same as any HTTP API. The GraphQL
server needs CORS headers to allow browser clients from different origins to make requests.

For Apollo Server with CORS:
```javascript
const { ApolloServer } = require('apollo-server');
// apollo-server configures CORS by default

// OR with express and apollo-server-express:
const app = express();
app.use(cors({
  origin: ['https://app.example.com',
           'http://localhost:3000'],
  credentials: true  // For cookies/auth headers
}));
```

> **Code walkthrough:** (1) WHAT IT SHOWS: configuring CORS for a GraphQL server with Apollo, specifying allowed origins and enabling credentials for authentication headers. (2) KEY MECHANISM: `credentials: true` in CORS configuration allows the browser to send cookies and Authorization headers cross-origin; without this, `Authorization: Bearer TOKEN` headers are blocked by the browser for cross-origin requests. (3) WHY IT MATTERS: a GraphQL server at `api.example.com` and a frontend at `app.example.com` are different origins; without CORS headers, the browser blocks GraphQL requests from the frontend. (4) WHAT BREAKS: `origin: '*'` (allow all origins) combined with `credentials: true` is blocked by the browser's CORS policy; when credentials are true, the origin must be specific (not wildcard). (5) TAKEAWAY: always configure CORS with specific origin allowlist in production; never use `*` for APIs that accept authentication credentials.

For authentication in browser clients:
- `Authorization: Bearer TOKEN` header: set in Apollo Client's `HttpLink` auth header; the most common approach.
- HttpOnly cookies: more secure (JavaScript cannot read the cookie); used for session-based auth; requires server to set `Set-Cookie: token=...; HttpOnly; Secure; SameSite=Strict`.

*What separates good from great:* The CSRF protection consideration for cookie-based
auth. HttpOnly cookies prevent XSS attacks (JavaScript cannot steal the cookie) but
are vulnerable to CSRF (Cross-Site Request Forgery - a malicious site can trigger a
request that includes the cookie). CSRF protection for GraphQL: use the `SameSite=Strict`
cookie attribute (the cookie is not sent for cross-site requests) plus a CSRF token
validation for mutation requests. Alternatively, use `Authorization: Bearer TOKEN` in
headers (not cookies) - headers cannot be set by cross-site requests, so CSRF is not
a concern. Most modern GraphQL implementations use bearer tokens in headers, which is
both simpler and CSRF-resistant.

---

**[SENIOR] Q6 (Scenario): A GraphQL API is accidentally exposing private user data to all authenticated users. How do you find and fix the authorization gaps?**

Investigation steps:

Step 1 - Identify all sensitive fields in the schema:

```bash
# Generate schema SDL from running server
# Using GraphQL introspection:
npx graphql-inspector introspect \
  http://localhost:4000/graphql \
  --output schema.graphql

# Look for sensitive field names:
grep -E "(salary|password|ssn|email|phone|private|secret)" \
  schema.graphql
# Output: lists all fields with potentially sensitive names
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using GraphQL introspection + schema inspection to systematically identify sensitive fields in the schema that may lack authorization checks. (2) KEY MECHANISM: `graphql-inspector introspect` fetches the full SDL via introspection; `grep` searches for sensitive field names; this gives a checklist of fields to audit for authorization. (3) WHY IT MATTERS: manually reviewing all resolvers for authorization gaps is error-prone; systematic schema-level field identification creates a complete audit checklist. (4) WHAT BREAKS: introspection may be disabled in production; run introspection against the development/staging server; maintain a separate schema file in the repository that is always current. (5) TAKEAWAY: treat the schema as a security audit artifact; review all fields with sensitive names; confirm each has appropriate authorization in its resolver.

Step 2 - Audit resolver authorization for each sensitive field:
For each sensitive field, read the resolver and verify it has both authentication check
(`if (!context.user) throw AuthenticationError`) and appropriate authorization check
(`if (context.user.role !== 'ADMIN' && context.user.id !== entity.ownerId) throw ForbiddenError`).

Step 3 - Add missing authorization checks:
For each field missing authorization, add the appropriate check based on the data
sensitivity level.

Step 4 - Prevent future gaps with graphql-shield:
Implement `graphql-shield` with a default-deny policy so all new fields must explicitly
opt-in to authorization rules.

*What separates good from great:* The introspection disable-in-production security
hardening. If introspection is enabled in production, any authenticated user can enumerate
all types and fields (including sensitive field names). This aids attackers in crafting
targeted queries. The recommendation: disable introspection in production for unauthenticated
requests; only allow introspection for admin/developer users; this reduces the attack
surface by preventing schema enumeration.

---

**[JUNIOR] Q7 (Trade-off): When should you put authorization logic in resolvers vs in a middleware library like graphql-shield?**

Inline resolver authorization (checking context.user in each resolver):
- Good for: small APIs with few authorization rules; simple all-or-nothing access control;
  when authorization logic is tightly coupled to the resolver's business logic.
- Bad for: large APIs with many resolvers; complex role hierarchies; when authorization
  rules need to be audited or changed independently of business logic.

graphql-shield (declarative authorization):
- Good for: medium to large APIs (10+ resolvers with auth); complex authorization rules;
  when authorization policy needs to be reviewed separately from business logic; default-
  deny policy enforcement (new fields automatically protected).
- Bad for: very simple APIs where the overhead of learning graphql-shield is not justified;
  highly custom authorization logic that does not fit rule-based patterns.

Decision rule: if the team has more than 5 resolvers with authorization requirements and
the authorization patterns are consistent (e.g., "must be authenticated" + "must own
the resource"), use graphql-shield. If the authorization is one-off and each resolver
has unique rules, inline checks are clearer.

*What separates good from great:* The default policy argument. graphql-shield's default
policy option (`fallbackRule: deny`) means any field WITHOUT an explicit rule is
automatically denied. This is the "secure by default" principle: new fields are protected
until explicitly permitted, rather than open until explicitly protected. In large codebases
where authorization reviews are common, the default-deny policy prevents the "we forgot
to add authorization to the new field" incident. This is a security architecture decision,
not just a tooling choice.

---

# Error Handling in GraphQL

---

### 🎯 Model Answer

**30 seconds:**
> GraphQL error handling differs fundamentally from REST: GraphQL always returns HTTP 200,
> even for errors. Errors appear in the response body in an `errors` array. Three error
> categories: (1) validation errors (query violates schema - caught before execution),
> (2) resolver errors (exception thrown in a resolver - partial results possible), (3)
> business logic errors (expected failures like "not found" or "insufficient funds" -
> return in data, not errors). The key practice: use custom error classes to distinguish
> error types, and return business errors in the data response, not as resolver exceptions.

**3 minutes (Senior):**
> GraphQL error handling has three layers: (1) Schema validation - queries that violate
> the schema type system are rejected before execution; no resolver runs; the response is
> `{ errors: [{message: "Field 'xyz' does not exist"}], data: null }`. (2) Resolver
> execution errors - exceptions thrown in resolvers cause the field to be null and an error
> entry added to the response errors array; siblings continue executing (partial results);
> error is in `errors[].extensions.code` for clients to handle. (3) Business logic errors
> - not every "failure" should be an exception; "user not found" or "payment declined"
> are expected outcomes, not infrastructure failures; return these as typed error values
> in the data response using result types (`type CheckoutResult { success, errors }`) rather
> than throwing exceptions; this keeps the business error contract in the schema and makes
> client error handling predictable. Production concern: redact internal error details
> in production; expose only safe error messages to clients; log full error details server-side.

**Blank Mind Recovery:**

**(1) Restate:** "GraphQL: always HTTP 200. Errors in response body `errors[]`. Three types:
validation (schema mismatch), resolver exception (partial data), business error (return in
data, not errors). Custom error classes: AuthenticationError, ForbiddenError, UserInputError.
Redact internal details in production. Never return stack traces to clients."

---

### 📘 Concept Explanation

**Error Response Format:**

```text
GRAPHQL ERROR RESPONSE FORMAT:

  {
    "data": {
      "user": null,           <- Null for failed field
      "posts": [{...}]        <- Other fields still work
    },
    "errors": [
      {
        "message": "User not found",   <- Human message
        "locations": [                  <- Query location
          { "line": 2, "column": 3 }
        ],
        "path": ["user"],              <- Field path
        "extensions": {                 <- Custom metadata
          "code": "USER_NOT_FOUND",    <- Error code
          "requestId": "abc-123"       <- For log correlation
        }
      }
    ]
  }

  PARTIAL SUCCESS EXAMPLE:
  Query: { user { name } posts { title } }
  user resolver: throws "User not found"
  posts resolver: succeeds

  Response:
  {
    "data": {
      "user": null,           <- Failed
      "posts": [{...}]        <- Succeeded
    },
    "errors": [{ ... }]       <- Error for user field
  }
  HTTP status: 200 OK (always!)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the GraphQL error response format showing how errors coexist with partial data, the structure of error objects (message, locations, path, extensions), and the partial success case. (2) HOW TO READ IT: the `data` object contains successful resolver results (or null for failed fields); the `errors` array contains all errors that occurred; both can be present simultaneously (partial data + errors). (3) KEY RELATIONSHIP: `path` links each error to the specific field that failed; clients use `path` to identify which part of the response failed; `extensions.code` is the machine-readable error identifier that clients use for conditional error handling. (4) EDGE CASE: when a non-null field fails (returns null due to error), null propagation can cause the entire `data` to be null even though only one field failed; design fields as nullable to prevent total query failure from partial errors. (5) INSIGHT: a senior engineer configures their GraphQL monitoring to alert on `errors` array presence in responses, not HTTP status codes; HTTP status code monitoring is useless for GraphQL since all responses are HTTP 200; `errors` array presence is the actual error indicator.

---

### 💻 Code Example

```javascript
// BAD: Using generic Error for all failures
// (no error codes; internal details leaked to client)

const resolvers = {
  Query: {
    user: async (_, { id }) => {
      const user = await db.getUser(id);
      if (!user) {
        // BAD: generic Error; no code; client cannot
        // distinguish "not found" from "db error"
        throw new Error('User not found');
      }
      return user;
    }
  },
  Mutation: {
    transferFunds: async (_, { from, to, amount }) => {
      try {
        return await bankService.transfer(from, to, amount);
      } catch (err) {
        // BAD: leaks internal error message and stack trace
        // to the client response
        throw new Error(err.message);
        // Could expose: database errors, internal states,
        // sensitive account information in error message
      }
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the generic error anti-pattern - throwing `new Error()` without error codes, which provides no machine-readable error classification, and potentially leaking internal error messages from database or service exceptions. (2) KEY MECHANISM: generic `Error` objects do not have an `extensions.code` property; clients cannot distinguish "user not found" (show a 404 message) from "database connection failed" (show a retry message); all errors look the same to the client. (3) WHY IT MATTERS: `throw new Error(err.message)` where `err` is a database exception may expose internal details like `"FATAL: password authentication failed for user 'postgres'"` or `"Connection refused to 10.0.0.1:5432"` - revealing infrastructure details that aid attackers. (4) WHAT BREAKS: Apollo Server in production mode (`NODE_ENV=production`) automatically masks internal error messages with "Internal server error"; explicitly throwing `new Error(err.message)` bypasses this masking. (5) TAKEAWAY: always use specific error classes (`UserInputError`, `AuthenticationError`, `ForbiddenError`) for expected errors; catch unexpected errors and throw a safe generic message; log the full error server-side with a request correlation ID.

```javascript
// GOOD: Custom error classes with error codes
// and safe error messages

const {
  ApolloError, UserInputError,
  AuthenticationError, ForbiddenError
} = require('apollo-server');

// Custom error class for domain errors
class NotFoundError extends ApolloError {
  constructor(resourceType, id) {
    super(
      `${resourceType} with id '${id}' not found`,
      'NOT_FOUND'  // Machine-readable code
    );
  }
}

class InsufficientFundsError extends ApolloError {
  constructor(available, required) {
    super(
      'Insufficient funds for this transfer',
      'INSUFFICIENT_FUNDS',
      // BAD: (see above - leaking amounts is a design choice)
      // Extensions are safe data for the client:
      { availableBalance: available,
        requiredAmount: required }
    );
  }
}

const resolvers = {
  Query: {
    user: async (_, { id }) => {
      const user = await db.getUser(id);
      if (!user) {
        // Specific error with code
        throw new NotFoundError('User', id);
      }
      return user;
    }
  },
  Mutation: {
    transferFunds: async (_, { from, to, amount },
                          { user }) => {
      if (!user) throw new AuthenticationError(
        'Login required for transfers'
      );

      try {
        return await bankService.transfer(
          from, to, amount
        );
      } catch (err) {
        if (err.code === 'INSUFFICIENT_FUNDS') {
          // Expected business error: safe message
          throw new InsufficientFundsError(
            err.availableBalance, amount
          );
        }
        // Unexpected error: log internally, safe message
        logger.error({
          msg: 'Transfer failed',
          error: err.message,
          stack: err.stack,
          from, to, amount  // Log all context
        });
        // Safe message to client (no internal details)
        throw new ApolloError(
          'Transfer failed. Please try again.',
          'TRANSFER_ERROR'
        );
      }
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: custom error classes with machine-readable error codes, safe client-facing messages, and the pattern of catching internal errors, logging them server-side, and throwing a safe generic message to the client. (2) KEY MECHANISM: `ApolloError(message, code, extensions)` creates a GraphQL error with an `extensions.code` field; `extensions` can include additional safe data (available balance); the error `message` is what the client shows to users. (3) WHY IT MATTERS: `client receives INSUFFICIENT_FUNDS` code and shows "You don't have enough funds"; if the code were `TRANSFER_ERROR`, the client would show a generic message; specific error codes enable specific UI responses. (4) WHAT BREAKS: including sensitive data in error messages or extensions - bank account numbers, internal service names, SQL queries - in the `extensions` object is still exposed to clients; only include data that is safe to show users. (5) TAKEAWAY: the error handling pattern: (1) expected business errors: specific custom error class with code; (2) unexpected system errors: log with full context, throw generic safe error to client; never expose internal error details to clients.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> GraphQL always returns HTTP 200, even for errors. Errors appear in the `errors` array
> in the response body. There are three types: validation errors (invalid query, caught
> before execution), resolver errors (exception in a resolver, field becomes null), and
> business errors. Use specific error classes like `UserInputError` (bad input from client)
> and `AuthenticationError` (not logged in) from apollo-server. Always check the `errors`
> array in the response, not the HTTP status code, to determine if a GraphQL operation
> succeeded.

---

**Senior / Staff (5+ years):**
> GraphQL error handling requires distinguishing three error categories with different
> client impacts: (1) Schema validation errors (query malformed - client bug, fix the query).
> (2) Resolver exceptions (server-side failure - may be retriable, depends on error code).
> (3) Business logic errors (expected outcomes - handle based on error code). Production
> practices: (1) use ApolloError subclasses with machine-readable codes; clients handle
> by code, not message string (which changes). (2) Redact internal errors in production;
> Apollo Server's `NODE_ENV=production` masks stack traces; ensure custom error handling
> does not bypass this. (3) Structured logging: log every unexpected resolver error with
> requestId, userId, operation name, variables, and error details; correlate with client
> error reports. (4) Error monitoring: track `errors` array in responses at the monitoring
> layer; alert on error rate increase; GraphQL errors are invisible to HTTP-status-based
> monitoring.

---

### ⚠️ Common Misconceptions

**Misconception: "If a GraphQL resolver throws an error, the entire query fails."**

A resolver exception does NOT fail the entire query by default. The field that threw
returns null; an error entry is added to the `errors` array; other fields in the same
query continue executing and may return successfully. This is "partial success": the
response contains both `data` (partial results from successful resolvers) and `errors`
(entries for failed resolvers). Example: `{ user { name } recentPosts { title } }` -
if the `user` resolver throws, `user` is null in the response but `recentPosts` still
executes and returns results. The entire query fails only when the failing field is non-null
AND null propagation reaches the query root. Design fields as nullable to enable
graceful partial success in the face of errors.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Error masking in production causing invisible failures.**

Symptom: errors appear as "Internal server error" in production with no detail;
resolvers are failing but it is impossible to determine why from client error responses.
Root cause: Apollo Server's production error masking is correct (hides internal details)
but the server-side logging is missing; errors are masked without being logged.

```javascript
// BAD: No error logging; production errors invisible
const server = new ApolloServer({
  typeDefs, resolvers
  // No formatError; no logging
  // Errors masked in production but not logged
});

// GOOD: Error logging with redaction
const server = new ApolloServer({
  typeDefs,
  resolvers,
  formatError: (error) => {
    // Log the FULL error server-side (with all details)
    if (!error.originalError
      || !(error.originalError instanceof ApolloError)) {
      // Only log unexpected errors (not user errors)
      logger.error({
        message: error.message,
        locations: error.locations,
        path: error.path,
        // Stack trace for unexpected errors
        stack: error.originalError?.stack,
        extensions: error.extensions
      });
    }

    // Return SAFE error to client
    if (error.originalError instanceof ApolloError) {
      // Known error: safe to return as-is
      return error;
    }
    // Unknown error: return generic message (redacted)
    return new ApolloError(
      'Internal server error',
      'INTERNAL_ERROR',
      { requestId: error.extensions?.requestId }
    );
  }
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the `formatError` function in Apollo Server that logs all unexpected errors server-side (with full details) while returning only safe generic messages to clients. (2) KEY MECHANISM: `formatError` runs for every error before it is sent to the client; `error.originalError` is the original JavaScript error that was thrown; if it is not an `ApolloError` (custom error), it is unexpected; log with full stack trace server-side and return a generic message to the client. (3) WHY IT MATTERS: without `formatError` logging, production errors are invisible; the client sees "Internal server error" but there is no server log to diagnose the cause; debugging production incidents requires server-side logs. (4) WHAT BREAKS: logging sensitive data in errors (user passwords, SSNs, bank account numbers) is a security vulnerability; log the error structure and stack trace, not request variables that may contain sensitive user data. (5) TAKEAWAY: implement `formatError` in every production GraphQL server; log unexpected errors server-side with correlation IDs; return safe generic messages to clients; do not skip this because Apollo Server's default masking "is good enough" - it is not, because it provides no diagnostic information.

---

### ⚖️ Comparison Table

| Error Type | Where | HTTP Status | Client Action | Example |
|---|---|---|---|---|
| Schema validation | Pre-execution | 200 | Fix query | Field does not exist |
| AuthenticationError | Resolver | 200 | Redirect to login | No valid token |
| ForbiddenError | Resolver | 200 | Show "Access denied" | Wrong role |
| UserInputError | Resolver | 200 | Show field error | Invalid email format |
| Business error (result type) | In data field | 200 | Show specific message | Insufficient funds |
| System error (ApolloError) | Resolver | 200 | Show generic message, retry | DB connection failed |
| Network error | Transport | 4xx/5xx | Retry | Request timeout |

---

### 🏛️ System Design

*(Omit: L1 keyword; error handling at scale (structured logging, error tracking) covered in L4 Production Debugging entry.)*

---

### 📊 Diagram

```text
ERROR CLASSIFICATION IN GRAPHQL:

  Error occurs
      |
      +-- Is it a schema validation error?
      |   YES: pre-execution rejection
      |        { data: null, errors: [schema error] }
      |        HTTP 200; fix the query
      |
      +-- Is it an expected business outcome?
      |   YES: return in data, not errors
      |        { data: { checkout: {
      |            success: false,
      |            errors: [INSUFFICIENT_FUNDS] } } }
      |        HTTP 200; client handles by error code
      |
      +-- Is it a known auth/permission error?
      |   YES: throw AuthenticationError or ForbiddenError
      |        { data: null, errors: [code: AUTH_ERROR] }
      |        HTTP 200; client redirects to login
      |
      +-- Is it an unexpected system error?
          YES: log full details server-side
               throw generic ApolloError to client
               { data: null, errors: [INTERNAL_ERROR] }
               HTTP 200; client shows "try again"
               Monitor error rate; alert on spike

  Client NEVER sees HTTP 4xx/5xx from GraphQL layer
  (transport errors from network/load balancer only)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a decision tree for classifying GraphQL errors and determining the correct handling approach for each type. (2) HOW TO READ IT: follow each branch from "Error occurs" to the appropriate handling; each branch shows the response format, HTTP status, and client action. (3) KEY RELATIONSHIP: all four error types return HTTP 200; the only way clients see non-200 status is from network/infrastructure errors (load balancer timeouts, CORS failures); GraphQL errors are always in the response body. (4) EDGE CASE: the "expected business outcome" branch is the most commonly missed; developers throw exceptions for business failures instead of returning them in typed result types; this makes client error handling fragile (matching error messages instead of codes). (5) INSIGHT: a senior engineer designs the error taxonomy before writing any resolvers; agreeing on error codes, their meanings, and client handling (before implementation) prevents ad-hoc error handling inconsistencies across the API.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | error format, HTTP 200 always |
| Application | 2 | error classes, result types |
| Trade-off | 1 | exceptions vs result types |
| Scenario | 2 | error masking, partial success |

---

**[JUNIOR] Q1 (Definition): Why does GraphQL always return HTTP 200 even for errors?**

GraphQL is transport-agnostic in its design; the HTTP transport is one implementation.
The GraphQL spec defines response semantics at the application layer (the `data`
and `errors` fields), not at the HTTP transport layer. The HTTP 200 response means
"the GraphQL server received your request and processed it" - not that the GraphQL
operation succeeded. Whether the operation succeeded is determined by the response body.

Implications:
1. HTTP status code monitoring is insufficient for GraphQL; monitoring must check
   the `errors` field in response bodies.
2. HTTP caching (which keys on URL and response headers) treats all GraphQL responses
   the same (200 OK); response body content (which may be different for different queries)
   is not considered.
3. Some infrastructure tools (WAF rules, API gateways) that make decisions based on
   HTTP status codes do not handle GraphQL errors correctly.

Exception: servers may return non-200 status for transport-level issues:
- HTTP 400: the request body is not valid JSON (malformed request before GraphQL processing).
- HTTP 401/403: authentication middleware rejects the request before GraphQL processing.
- HTTP 500: server crash before GraphQL processing (not a GraphQL error).

*What separates good from great:* The monitoring gap. Companies migrating from REST to
GraphQL often discover their error rate monitoring is blind to GraphQL errors. The SLA
(e.g., "99.9% of requests succeed") is measured by HTTP 2xx rate. After migration, HTTP
2xx rate remains at 100% even when 30% of GraphQL operations are failing (errors in the
response body). Fixing this requires adding a custom metric: parse response bodies and
count responses with non-empty `errors` arrays. This is a post-migration monitoring update
that is frequently overlooked.

---

**[JUNIOR] Q2 (Application): What GraphQL error classes are available in Apollo Server and when do you use each?**

Apollo Server provides four error classes:

1. `ApolloError(message, code, extensions)`:
   Base class for all custom errors. Use when the built-in classes do not match your
   error type. Creates an error with `extensions.code`.

2. `UserInputError(message, extensions)`:
   Use for invalid user input (bad request format). Extensions often contain field-level
   validation details (which field is invalid, why).
   Example: `throw new UserInputError('Email is invalid', { field: 'email' })`.

3. `AuthenticationError(message)`:
   Use when the user is not authenticated. Implies "please log in."
   Example: `throw new AuthenticationError('You must be logged in')`.

4. `ForbiddenError(message)`:
   Use when the user is authenticated but lacks permission. Implies "you don't have
   access to this."
   Example: `throw new ForbiddenError('Admin access required')`.

All four extend `ApolloError` with specific error codes:
- `UserInputError` -> code: `BAD_USER_INPUT`
- `AuthenticationError` -> code: `UNAUTHENTICATED`
- `ForbiddenError` -> code: `FORBIDDEN`
- `ApolloError` with custom code -> code: whatever you specify

Apollo Client and other GraphQL clients can handle errors by code:
```javascript
if (error.graphQLErrors.some(
  e => e.extensions?.code === 'UNAUTHENTICATED'
)) {
  redirectToLogin();
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: handling specific GraphQL error codes in the client by checking `error.graphQLErrors[].extensions.code`. (2) KEY MECHANISM: Apollo Client provides `graphQLErrors` (GraphQL-layer errors from the `errors` array) and `networkError` (HTTP/network-level failures) separately; `graphQLErrors` is where GraphQL error codes are checked. (3) WHY IT MATTERS: matching by error code (`'UNAUTHENTICATED'`) vs message string is more stable; error messages change for UX improvements; error codes are contractual. (4) WHAT BREAKS: if the server uses generic `Error` (no code), `extensions.code` is undefined; the client cannot distinguish error types. (5) TAKEAWAY: always use typed error classes in resolvers; always handle errors by `extensions.code` in clients; never match error messages (they change).

*What separates good from great:* Defining a custom error code registry. In large teams,
ad-hoc error codes proliferate ("USER_NOT_FOUND", "user_not_found", "USER_MISSING",
"NO_SUCH_USER"). Define all error codes as an enum in the schema or in a shared constants
file; document what each code means and what clients should do. A consistent error code
registry enables: client-side handling by code, error monitoring aggregation, and
cross-team alignment. Shopify's GraphQL API has a documented error type taxonomy; every
error type and code is in the API reference.

---

**[SENIOR] Q3 (Trade-off): When should business errors be returned in the `data` field vs thrown as exceptions?**

Exceptions (`errors` array): for unexpected errors and authorization failures.
Result types (`data` field): for expected business outcomes that represent valid
completed operation results (even if the business outcome is negative).

Decision rule: "Is this error an expected, domain-defined outcome of the operation?"
- YES -> return in data with a typed error structure.
- NO -> throw as an exception.

Examples:
- "User not found" for a public user lookup: arguable; if the user might legitimately
  not exist, a nullable return (`user: User` returning null) is the cleanest approach.
- "Insufficient funds" for a bank transfer: expected business outcome; return in result
  type with `{ success: false, errors: [INSUFFICIENT_FUNDS] }`.
- "Payment processor returned 'card declined'": expected business outcome; return in
  result type.
- "Database connection failed": unexpected system error; throw ApolloError.
- "User does not have permission": authorization error; throw ForbiddenError.

The practical benefit: result type errors are in the schema (clients can generate
handling code); exception errors are discovered at runtime (clients need to check error
codes that may not be in the schema). Result types make the complete success/failure
contract explicit and type-safe.

*What separates good from great:* The "errors as data" philosophy (from GraphQL spec author
Lee Byron). The argument: an operation completing with an expected failure state (payment
declined, item out of stock) is not a system error; it is a valid response to a valid
request. Representing it as an exception in the `errors` array conflates "the system
failed" (exception) with "the business rule prevented this action" (expected outcome).
Returning expected outcomes in the `data` response field with typed error codes makes
the full operation contract visible in the schema, type-safe for clients, and easier
to handle. The practical result: more code upfront (result types), fewer surprise errors
in client error handling.

---

**[JUNIOR] Q4 (Application): How do you return validation errors for user input in a GraphQL mutation?**

UserInputError with field-level details:

```javascript
const { UserInputError } = require('apollo-server');

const resolvers = {
  Mutation: {
    createUser: async (_, { input }) => {
      const errors = {};

      // Validate each field
      if (!input.email || !input.email.includes('@')) {
        errors.email = 'Valid email address required';
      }
      if (!input.name || input.name.length < 2) {
        errors.name = 'Name must be at least 2 characters';
      }
      if (!input.password || input.password.length < 8) {
        errors.password =
          'Password must be at least 8 characters';
      }

      // Throw with field-level error details
      if (Object.keys(errors).length > 0) {
        throw new UserInputError(
          'Invalid input',
          { validationErrors: errors }
          // extensions.validationErrors available to client
        );
      }

      return db.createUser(input);
    }
  }
};

// Client receives:
// {
//   "errors": [{
//     "message": "Invalid input",
//     "extensions": {
//       "code": "BAD_USER_INPUT",
//       "validationErrors": {
//         "email": "Valid email address required",
//         "password": "Password min 8 chars"
//       }
//     }
//   }]
// }
```

> **Code walkthrough:** (1) WHAT IT SHOWS: collecting all field validation errors before throwing a single `UserInputError` with a `validationErrors` map in extensions, allowing clients to display per-field error messages in the form. (2) KEY MECHANISM: collecting all errors before throwing (not throwing on first error) sends ALL validation errors in one response; the client does not need multiple round-trips to discover all validation failures. (3) WHY IT MATTERS: a form with 5 fields where each error causes a separate request creates a frustrating UX (user fixes one field, submits, gets next error); returning all validation errors simultaneously allows the form to highlight all invalid fields at once. (4) WHAT BREAKS: using `ApolloError` instead of `UserInputError` sends the wrong error code (`INTERNAL_ERROR` instead of `BAD_USER_INPUT`); clients treating `BAD_USER_INPUT` as a client-side error (no retry) vs `INTERNAL_ERROR` as a server error (retry) will retry input validation errors unnecessarily. (5) TAKEAWAY: collect all validation errors before throwing; use `UserInputError` for all input validation failures; provide field-level details in `extensions.validationErrors` so clients can display per-field error messages.

*What separates good from great:* The schema-level validation via input type constraints.
GraphQL validates input types against their schema type at the execution layer (e.g.,
`Int` argument rejects a string). But domain validation (email format, password length)
must happen in resolvers. The production pattern: use validation libraries (Joi, Zod,
Yup) in the resolver to validate the full input before business logic; throw
`UserInputError` with structured validation errors for all failures. This approach
works consistently across all mutations. The more advanced approach: create a custom
GraphQL scalar (`Email`, `Password`) that validates format in the scalar's `parseValue`
function; invalid values fail before the resolver runs. This schema-level validation
is more robust but requires custom scalar implementation.

---

**[SENIOR] Q5 (Scenario): A GraphQL API is logging raw database errors to the client response in production. How do you fix it without losing diagnostic information?**

The problem: unhandled database exceptions propagate to GraphQL's error handling and
Apollo Server (in development mode) returns the raw error message to the client. In
production, Apollo Server masks generic errors but the team may have disabled masking
or used a custom error format that re-exposes the error message.

Fix with structured error handling:

```javascript
// 1. Add formatError to Apollo Server configuration
const server = new ApolloServer({
  typeDefs,
  resolvers,
  formatError: (error) => {
    const originalError = error.originalError;

    // Log everything server-side before masking
    if (originalError
      && !(originalError instanceof ApolloError)) {
      logger.error({
        message: 'Unexpected resolver error',
        apolloMessage: error.message,
        originalMessage: originalError.message,
        stack: originalError.stack,
        path: error.path,
        // DO NOT log variables (may have passwords)
        // DO log the operation path for diagnosis
        requestId: error.extensions?.requestId
      });
    }

    // Mask non-ApolloError exceptions
    if (!(originalError instanceof ApolloError)) {
      return new ApolloError(
        'An unexpected error occurred',
        'INTERNAL_SERVER_ERROR',
        {
          // Safe to return to client:
          requestId: error.extensions?.requestId
        }
      );
    }

    // Return ApolloError subclasses as-is
    // (they are intentionally created for clients)
    return error;
  }
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a `formatError` function that logs unexpected errors server-side (with full details for diagnosis) and masks them for clients (returning only a safe generic message with a request ID for correlation). (2) KEY MECHANISM: `error.originalError` is the original exception thrown by the resolver; if it is not an `ApolloError` subclass, it is an unexpected error; log it fully and mask it; if it IS an `ApolloError`, it was intentionally created for the client and is safe to return. (3) WHY IT MATTERS: the request ID in the masked error enables client support to report "error requestId: abc-123" and operations to find the full log entry for diagnosis; no diagnostic information is lost, but none is exposed to end users. (4) WHAT BREAKS: not masking `ApolloError` subclasses that contain sensitive data in extensions; custom `ApolloError` subclasses must be carefully designed to include only client-safe data in their messages and extensions. (5) TAKEAWAY: `formatError` is the production error handling configuration; implement it in every production GraphQL server; test it by intentionally triggering a database error and verifying the client response is masked and the server log contains the full details.

*What separates good from great:* The `requestId` correlation pattern. Generating a unique
`requestId` at the start of each GraphQL request and including it in both the server log
and the masked client error response enables correlation: when a user reports "I got an
error, here is the error ID", operations can search the log for that ID and find the full
details. Implement this with a request-scoped `requestId` in the context function and
attach it to the Apollo Server's `context.requestId`. Include it in all log entries and
in masked error extensions. This is the production incident diagnosis standard for GraphQL
APIs.

---

**[JUNIOR] Q6 (Application): How does partial error handling work in GraphQL when one resolver fails?**

When a resolver fails in a GraphQL query, GraphQL provides partial results: the failed
field is null, all other fields that succeeded return their values, and the errors array
contains an entry for the failed field.

Example:
```graphql
query {
  user(id: "1") {    # Resolver throws "User not found"
    name             # Never called (parent is null)
  }
  posts {            # Resolver succeeds
    title
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a GraphQL query with two sibling root fields where one fails and the other succeeds - demonstrating partial result behavior. (2) KEY MECHANISM: root fields `user` and `posts` execute independently; `user` resolver throws, causing that field to be null; `posts` resolver is unaffected and returns data. (3) WHY IT MATTERS: independent resolver failure isolation prevents one failing field from making the entire query return null. (4) WHAT BREAKS: if `user` were `user!` (non-null), null propagation would null the entire query. (5) TAKEAWAY: nullable field design enables graceful partial success.

Response:
```json
{
  "data": {
    "user": null,
    "posts": [{"title": "Post A"}, {"title": "Post B"}]
  },
  "errors": [{
    "message": "User not found",
    "path": ["user"],
    "extensions": {"code": "NOT_FOUND"}
  }]
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a partial success GraphQL response where `user` fails (returns null with an error) but `posts` succeeds (returns data), demonstrating that GraphQL continues executing independent resolvers even when one fails. (2) KEY MECHANISM: `user` and `posts` are sibling root fields; they execute independently (and potentially in parallel); `user` failure does not affect `posts` execution; both results are merged into the response. (3) WHY IT MATTERS: partial success prevents a single failing resolver from making a complex dashboard query return completely empty data; the user sees partial data (posts loaded) instead of a blank screen. (4) WHAT BREAKS: partial success handling requires clients to check BOTH `data` (for partial results) AND `errors` (for failures) on every response; clients that only check `data` miss errors; clients that only check `errors` ignore partial data. (5) TAKEAWAY: always check both `data` and `errors` in GraphQL responses; null fields in `data` may be intentional (optional data not found) or error-caused (failed resolver); the `errors` array distinguishes the two cases.

Client handling of partial success:
- Check `errors` array first; log any errors.
- Render available `data` (show posts even though user data failed).
- Show an error indicator for the failed section (empty user card with "Error loading user").
- Do not discard all data because one field failed.

*What separates good from great:* The error boundary pattern in React with Apollo Client.
React Error Boundaries do not catch GraphQL errors (they are not JavaScript exceptions).
Apollo Client's `error` and `data` fields are both returned simultaneously when partial
errors occur. The pattern: check `error.graphQLErrors` and identify which paths failed
using `error.graphQLErrors[].path`; render an error indicator for those specific paths
while rendering available data for successful paths. This per-path error rendering is
the correct implementation of partial success in React + Apollo Client applications.

---

**[SENIOR] Q7 (Trade-off): How should a GraphQL API handle errors from downstream services (REST APIs, databases)?**

Three strategies for downstream service errors:

Strategy 1 - Propagate error (transparent):
Catch the downstream error, convert it to an appropriate ApolloError, and throw.
Use when: the downstream error is meaningful to the client (e.g., payment declined
with a specific error code).
Risk: downstream service internals may leak to clients if error messages are not sanitized.

Strategy 2 - Return null (graceful degradation):
Catch the downstream error, log it, and return null.
Use when: the field is optional (nullable in schema) and partial data is acceptable.
Example: `enrichment: ProfileEnrichment` field fetches from an external enrichment service;
if the service is down, return null (user profile loads without enrichment data).
Risk: errors are silent; monitoring must alert on null rate increase.

Strategy 3 - Circuit breaker with fallback:
Use a circuit breaker pattern: after N failures, stop calling the downstream service
and return a fallback value (null, cached value, or default); when the service recovers,
resume calls.
Use when: the downstream service has reliability issues and the caller must handle
partial availability.
Risk: complexity; requires circuit breaker library (e.g., `opossum`).

*What separates good from great:* The return null vs throw distinction for non-critical
fields. A downstream enrichment service returning 503 should NOT fail the entire user
query; `enrichment: EnrichmentData` is an optional enhancement. Return null for that
field (with a log entry and alerting). But a payment service returning 503 for a transfer
mutation IS critical; throw an ApolloError with retry guidance. The schema's nullability
design drives the error strategy: non-null fields must succeed or the query fails;
nullable fields can return null as a graceful degradation. Design fields as nullable when
they depend on non-critical services; non-null only for essential data.
