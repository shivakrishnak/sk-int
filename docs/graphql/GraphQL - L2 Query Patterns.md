---
layout: default
title: "GraphQL - L2 Query Patterns"
parent: "GraphQL"
nav_order: 5
permalink: /graphql/l2-query-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 12 | [DataLoader: Batching and Caching](#dataloader-batching-and-caching) | ★★☆ |
| 13 | [Pagination: Offset vs Cursor-Based](#pagination-offset-vs-cursor-based) | ★★☆ |

---

# DataLoader: Batching and Caching

---

### 🎯 Model Answer

**30 seconds:**
> DataLoader is a batching and caching library that solves the N+1 query problem in
> GraphQL resolvers. Without DataLoader, a list of 100 users triggers 100 separate
> `SELECT author WHERE id=N` queries. With DataLoader, all 100 ID lookups are collected
> in one event loop tick and executed as a single `SELECT ... WHERE id IN (1,2,...100)`
> query. DataLoader also caches results within a single request, so if the same ID is
> requested twice, the database is queried only once.

**3 minutes (Senior):**
> DataLoader uses JavaScript's event loop batching mechanism: `load(id)` returns a
> Promise; DataLoader queues the ID; at the end of the current event loop tick (using
> `process.nextTick`), DataLoader collects all queued IDs and calls the batch function
> with the entire array. The batch function runs one database query and returns results
> ordered to match the input IDs. DataLoader's per-request cache (Map from ID to Promise)
> prevents duplicate database queries within the same request: if `author.id === 42` for
> three different posts, DataLoader queries the database for 42 once and caches the result
> for subsequent requests in the same event loop iteration. Critical: DataLoader instances
> must be per-request (created in the context function) to prevent cross-request cache
> leaks. One DataLoader per data source per entity type. Batching behavior: DataLoader's
> default batch scheduler collects all `load()` calls that occur within a single tick;
> for nested resolvers, this means all Post.author calls (sibling level) are batched
> together, reducing N+1 to 1 batched query per level.

**Blank Mind Recovery:**

**(1) Restate:** "DataLoader: batches database queries. `load(id)` collects IDs. End of
event loop tick: calls batch function with all IDs. Returns array of results (order must
match input IDs). Per-request cache: same ID requested twice = one database query.
MUST be per-request (in context function) to avoid cross-request data leaks."

---

### 📘 Concept Explanation

**DataLoader Batch Execution Mechanism:**

```text
DATALOADER BATCHING EXECUTION TIMELINE:

  Event Loop Tick (GraphQL resolution pass):

  Post[0].author resolver:
    dataLoader.load("user:1")   <- Queued, not yet fetched

  Post[1].author resolver:
    dataLoader.load("user:2")   <- Queued

  Post[2].author resolver:
    dataLoader.load("user:1")   <- Same ID! Cache hit.

  ... (98 more Post.author calls)

  End of event loop tick:
  DataLoader.scheduleBatch() fires:
    Collected IDs: ["user:1", "user:2", "user:3", ...]
    (deduplicated: "user:1" appears only once)
    Calls: batchFn(["user:1", "user:2", "user:3", ...])
      -> ONE SQL: SELECT * FROM users
                  WHERE id IN (1, 2, 3, ...)

    Database returns: [User1, User2, User3, ...]
    DataLoader maps to original promises:
      user:1 -> Promise.resolve(User1)
      user:2 -> Promise.resolve(User2)
      user:1 -> Promise.resolve(User1) [from cache]
      (all 100 Post.author promises resolved)

  RESULT:
  100 posts, each with unique/shared authors
  = 1 batched database query (vs 100 individual queries)
  = O(1) database calls per resolver level
    instead of O(N) where N = list length
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: DataLoader's event loop batching mechanism showing how 100 `load()` calls from 100 `Post.author` resolvers are collected and executed as one database query, including deduplication of repeated IDs. (2) HOW TO READ IT: follow the timeline top-to-bottom; the first section shows individual `load()` calls being queued; the "end of event loop tick" section shows the batch function being called with all collected IDs simultaneously; the result section shows the impact. (3) KEY RELATIONSHIP: JavaScript's event loop enables DataLoader's batching; all synchronous code in one tick runs before Promises resolve; all sibling resolver calls happen synchronously, queuing their `load()` calls before the batch fires. (4) EDGE CASE: if `user:1` is requested twice, DataLoader deduplicates it in the batch (queries once) but returns the same result to both requesting resolvers; this is the caching benefit; the database sees the ID once. (5) INSIGHT: a senior engineer recognizes that DataLoader's batching is level-by-level: all level-3 resolver calls in a query are batched together (one query); all level-4 resolver calls are batched together (another query); for a 5-level deep query with DataLoader, there are 5 batched queries instead of O(N^5) individual queries.

---

### 💻 Code Example

```javascript
// BAD: No DataLoader; individual DB queries per resolver
// (N+1 anti-pattern; defeats GraphQL's composability)

const resolvers = {
  // Query returns 50 blog posts
  Query: {
    posts: async () => db.query('SELECT * FROM posts')
  },
  Post: {
    // This resolver runs 50 times (once per post)
    author: async ({ authorId }) => {
      return db.query(
        'SELECT * FROM users WHERE id = $1',
        [authorId]
      );
      // Executes 50 individual queries!
    },
    // Comments resolver also has N+1
    comments: async ({ id }) => {
      return db.query(
        'SELECT * FROM comments WHERE post_id = $1',
        [id]
      );
      // 50 more queries for comments!
    }
  }
};
// Total: 1 (posts) + 50 (authors) + 50 (comments) = 101 DB queries
// For 50 posts. Adding tags: +50. Following users: +50.
// Each added field multiplies the problem.
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the N+1 anti-pattern in action - three resolvers generating 101 database queries for a 50-post listing, and how the problem scales multiplicatively with each new list field added. (2) KEY MECHANISM: each `Post.author` resolver call is completely independent; no coordination between them; each opens a DB connection, executes `SELECT WHERE id = N`, and returns; 50 independent connections, 50 sequential queries. (3) WHY IT MATTERS: 101 queries for a simple blog listing is fine in development (test database is local; fast); in production (database is remote; 5ms round-trip each), 101 queries = 505ms minimum; real-world databases at load add more latency; this is a production performance disaster hiding in development. (4) WHAT BREAKS: database connection pool exhaustion; each query holds a connection; a connection pool of 20 connections cannot handle more than 20 concurrent queries; request queuing starts; response times degrade; under high load, timeouts cascade. (5) TAKEAWAY: any field resolver that queries the database using a foreign key from the parent object (`authorId`, `postId`, `categoryId`) is an N+1 candidate; DataLoader is the mandatory fix.

```javascript
// GOOD: DataLoader solving N+1 at every level

const DataLoader = require('dataloader');

// One DataLoader per entity type per request
const createLoaders = (db) => ({
  // User DataLoader: batch by user IDs
  user: new DataLoader(async (userIds) => {
    const users = await db.query(
      'SELECT * FROM users WHERE id = ANY($1)',
      [userIds]
    );
    const userMap = new Map(
      users.map(u => [u.id.toString(), u])
    );
    // MUST preserve order matching input IDs
    return userIds.map(
      id => userMap.get(id.toString()) || null
    );
  }),

  // Comment DataLoader: batch by post IDs
  // Returns ARRAY of comments per post ID (one-to-many)
  commentsByPostId: new DataLoader(async (postIds) => {
    const comments = await db.query(
      'SELECT * FROM comments WHERE post_id = ANY($1)',
      [postIds]
    );
    // Group comments by postId
    const commentsByPost = new Map();
    for (const comment of comments) {
      const key = comment.postId.toString();
      if (!commentsByPost.has(key)) {
        commentsByPost.set(key, []);
      }
      commentsByPost.get(key).push(comment);
    }
    // Return array-per-postId (one-to-many)
    return postIds.map(
      id => commentsByPost.get(id.toString()) || []
    );
  })
});

// Context: fresh DataLoaders per request
const server = new ApolloServer({
  context: ({ req }) => ({
    db,
    loaders: createLoaders(db)
  })
});

const resolvers = {
  Query: {
    posts: async (_, __, { db }) =>
      db.query('SELECT * FROM posts')
  },
  Post: {
    // 50 calls -> 1 batched query via DataLoader
    author: async ({ authorId }, _, { loaders }) =>
      loaders.user.load(authorId.toString()),

    // 50 calls -> 1 batched query via DataLoader
    comments: async ({ id }, _, { loaders }) =>
      loaders.commentsByPostId.load(id.toString())
  }
};
// Total: 1 (posts) + 1 (all authors batched)
//      + 1 (all comments batched) = 3 DB queries
// For 50 posts with authors AND comments!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: DataLoader solving N+1 at two levels simultaneously - `Post.author` (one-to-one, user by ID) and `Post.comments` (one-to-many, comments by post ID) - reducing from 101 queries to 3. (2) KEY MECHANISM: `commentsByPostId` DataLoader batches all 50 post IDs into one `WHERE post_id = ANY($1)` query; the batch function groups results by `postId` and returns an array of comments per post ID; the `one-to-many` DataLoader pattern returns an array for each key. (3) WHY IT MATTERS: the one-to-many pattern is the most common DataLoader use case in relational databases; every parent-children relationship (post-comments, user-posts, order-items) is one-to-many; DataLoader handles both one-to-one and one-to-many. (4) WHAT BREAKS: using the same DataLoader approach for one-to-many but returning a flat array instead of an array-of-arrays causes DataLoader to return wrong data; DataLoader requires the batch function to return `[arrayForId1, arrayForId2, ...]` for one-to-many. (5) TAKEAWAY: implement `createLoaders(db)` as a factory function called in the context function; create one DataLoader per entity type; handle one-to-one (return single item or null) and one-to-many (return array of items) separately.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> DataLoader solves the N+1 query problem in GraphQL. Without DataLoader, a field resolver
> that looks up a related entity (like `Post.author`) runs once per item in the parent
> list, causing N separate database queries for N posts. DataLoader batches these calls:
> it collects all IDs requested in the same event loop tick and executes one `WHERE id IN
> (...)` query for all of them. Create DataLoader instances in the request context
> (not globally) to prevent cross-request data leaks.

---

**Senior / Staff (5+ years):**
> DataLoader is a concurrency primitive that leverages JavaScript's event loop for batching.
> Key production considerations: (1) Per-request instances: global DataLoaders cache across
> requests, causing security and correctness issues; create fresh instances in the context
> function. (2) Order preservation: the batch function MUST return results in the same
> order as the input IDs; incorrect ordering causes wrong data mapping (e.g., user 1 gets
> user 2's data). (3) One-to-many pattern: use separate DataLoaders for one-to-many
> relationships; the batch function returns `[Array<T>]` not `T[]`. (4) Batch scheduler:
> the default batch scheduler fires at the end of the event loop tick; custom schedulers
> are possible for different batching windows (e.g., `maxBatchSize` option to limit batch
> size). (5) Cache invalidation: DataLoader's per-request cache is never invalidated
> within a request; if a mutation updates a user mid-request, subsequent `load()` calls
> return the pre-mutation cached value; this is typically acceptable (mutations and queries
> are separate requests).

---

### ⚠️ Common Misconceptions

**Misconception: "DataLoader eliminates all N+1 problems automatically once installed."**

DataLoader only batches resolvers that explicitly use it. A resolver that does
`db.query('SELECT * FROM users WHERE id = ?', [post.authorId])` directly (not via
DataLoader) is still N+1, regardless of whether DataLoader is installed in the project.
DataLoader must be explicitly called in every resolver that has an N+1 pattern:
`context.loaders.user.load(post.authorId)`. The developer must: (1) identify N+1
resolvers (those that query by foreign key), (2) create a DataLoader for each entity
type in the context factory, (3) update resolvers to use `context.loaders.X.load(id)`
instead of direct database calls. DataLoader is a tool, not magic; it requires deliberate
implementation at each N+1 site. A DataLoader that is created but never used in resolvers
provides zero benefit. Code review should verify that every list field resolver uses
DataLoader for its child resolvers.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: DataLoader batch function returns wrong data due to ordering violation.**

Symptom: posts show wrong authors; user A's post shows user B's name; no errors, just
wrong data.
Root cause: the batch function returns users in database sort order, not in the input
ID order; DataLoader maps the first user to the first post author request, second user
to the second request, etc. (positional mapping), regardless of whether the IDs match.

```javascript
// BAD: Batch function violates order contract
const userLoader = new DataLoader(async (userIds) => {
  const users = await db.query(
    'SELECT * FROM users WHERE id = ANY($1)',
    [userIds]
  );
  // Returns users in DB ORDER BY id ASC
  // Input: [5, 2, 8, 1] (request order)
  // DB returns: [1, 2, 5, 8] (ascending order)
  // DataLoader maps: id 5 -> User(1), id 2 -> User(2)
  //                  id 8 -> User(5), id 1 -> User(8)
  // WRONG! Post authored by user 5 shows user 1's name.
  return users;  // BUG: wrong order
});

// GOOD: Explicit order preservation via Map
// BAD: (see above - returning users in DB order is wrong)
const userLoader = new DataLoader(async (userIds) => {
  const users = await db.query(
    'SELECT * FROM users WHERE id = ANY($1)',
    [userIds]
  );
  // Build lookup map for O(1) access
  const userMap = new Map(
    users.map(u => [String(u.id), u])
  );
  // Map each input ID to its user (in input order)
  return userIds.map(
    id => userMap.get(String(id)) ?? null
  );
  // Input: [5, 2, 8, 1]
  // Returns: [User(5), User(2), User(8), User(1)]
  // CORRECT: position matches input position
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the DataLoader ordering violation bug and fix - the batch function must return results positionally matching the input IDs array, not in any other order. (2) KEY MECHANISM: DataLoader maps its results by array position (not by ID value); result[0] is returned to the resolver that called `load(userIds[0])`; if the database returns users sorted by ID instead of by request order, position 0 is the smallest ID user, not the first requested user. (3) WHY IT MATTERS: this is a silent data correctness bug; no error is thrown; posts display the wrong authors; in a social application, user A sees user B's private profile data; this is a data exposure security issue. (4) WHAT BREAKS: `String(u.id)` vs `u.id.toString()` vs `Number(id)` - type inconsistencies in the Map key cause cache misses; always normalize IDs to the same type; use `String()` consistently. (5) TAKEAWAY: the DataLoader contract is unambiguous - return an array where index `i` corresponds to `userIds[i]`; build a Map from the database results and use `userIds.map(id => map.get(id))` to produce the correctly ordered output; test with IDs out of numeric order.

---

### ⚖️ Comparison Table

| Scenario | Without DataLoader | With DataLoader | Reduction |
|---|---|---|---|
| 100 posts, show author | 101 queries | 2 queries | 50x |
| 100 posts, show authors + comments | 201 queries | 3 queries | 67x |
| 10 users, each with 10 posts (author field) | 101 queries | 2 queries | 50x |
| 5-level deep with all N+1 fixed | 5 batched queries | Same | N/A |
| Same entity ID requested twice | 2 queries | 1 query (cache) | 2x |

---

### 🏛️ System Design

*(Omit: L2 keyword; DataLoader at scale and per-service DataLoaders in federation covered in L4 Performance entry.)*

---

### 📊 Diagram

```text
DATALOADER TIMING IN NODE.JS EVENT LOOP:

  [Event Loop Tick Start]
    |
    Query.posts resolver:
      returns 50 Post objects
    |
    Post[0].author: loaders.user.load("1")  -> QUEUED
    Post[0].comments: loaders.comments.load("1") -> QUEUED
    Post[1].author: loaders.user.load("2")  -> QUEUED
    Post[1].comments: loaders.comments.load("1") -> QUEUED
    ...
    Post[49].author: loaders.user.load("7") -> QUEUED
    Post[49].comments: loaders.comments.load("49")
    |
  [Synchronous code complete; Promises pending]
    |
  [process.nextTick fires - DataLoader batch scheduler]
    |
    userLoader.batchFn(["1","2","3",...,"50"])
    -> ONE query: SELECT * FROM users WHERE id IN (...)
    |
    commentLoader.batchFn(["1","2","3",...,"50"])
    -> ONE query: SELECT * FROM comments
                  WHERE post_id IN (...)
    |
  [All Promises resolve; resolvers return]
    |
  [GraphQL response assembled and sent]

  RESULT:
  1 (posts) + 1 (users) + 1 (comments) = 3 queries
  For 50 posts with authors AND comments
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Node.js event loop timing of DataLoader batching, showing how all 100 `load()` calls from synchronous resolver execution are collected before `process.nextTick` fires the batch function. (2) HOW TO READ IT: the left column shows the timeline; the indented items show resolver calls queuing IDs; the `process.nextTick` section shows the batch functions firing with all collected IDs simultaneously. (3) KEY RELATIONSHIP: the event loop tick boundary is what enables batching; all resolver calls that occur synchronously within one tick are batched together; resolvers at different nesting levels occur in different ticks (DataLoader batches per level, not per entire query). (4) EDGE CASE: if a resolver has `await` before the `dataLoader.load()` call, the `load()` occurs in a later tick; it may miss the current batch and trigger a separate batch; avoid unnecessary `await` before `load()` calls. (5) INSIGHT: a senior engineer knows that DataLoader's batching is synchronous collection, async execution; the `load()` calls are collected synchronously (no await); the batch function runs asynchronously; this means all sibling resolvers' `load()` calls are always collected in the same tick, guaranteeing they batch together.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | DataLoader mechanism, batching window |
| Application | 2 | one-to-one, one-to-many DataLoaders |
| Trade-off | 1 | caching trade-offs |
| Debugging | 2 | N+1 diagnosis, ordering bug |

---

**[JUNIOR] Q1 (Definition): What is the N+1 query problem in GraphQL and why does DataLoader solve it?**

The N+1 query problem: when a list resolver returns N items (1 query) and each item
has a field resolver that makes its own database query (N queries), the total is N+1
queries. This scales linearly with the list size.

```javascript
// N+1 without DataLoader:
// 1 query: posts table (returns 100 posts)
posts: () => db.query('SELECT * FROM posts')
// 100 queries: one per post for the author
author: ({ authorId }) =>
  db.query('SELECT FROM users WHERE id = $1', [authorId])
// Total: 101 database queries for 100 posts
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the N+1 problem in its simplest form - one list query returning N items, each triggering its own query. (2) KEY MECHANISM: GraphQL calls the `author` resolver once per post object; each call is independent; there is no built-in batching mechanism in GraphQL itself. (3) WHY IT MATTERS: at 100 posts, 101 queries. At 1000 posts (a paginated list page), 1001 queries. The linear scaling of N+1 is the production performance cliff. (4) WHAT BREAKS: database connection pool exhaustion, high query volume, slow response times, and cascading failures under load. (5) TAKEAWAY: any resolver that uses a foreign key from the parent (`root.authorId`, `root.userId`, `root.categoryId`) to query another table is an N+1 pattern; every such resolver needs DataLoader.

DataLoader solves N+1 by batching: instead of 100 individual `WHERE id = N` queries,
DataLoader collects all 100 IDs and issues ONE `WHERE id IN (1,2,...100)` query.
The key insight: DataLoader uses the event loop - all resolver calls in one tick queue
their IDs; at the end of the tick, DataLoader fires the batch function with all IDs.
Result: N+1 becomes 2 queries (list + batch).

*What separates good from great:* The DataLoader batching guarantee. DataLoader's batching
is guaranteed for sibling resolvers - resolvers at the same depth in the same query
always batch together. This is because sibling resolvers execute within the same event
loop tick; their `load()` calls are all queued before `process.nextTick` fires the
batch. Parent-child resolvers execute in different ticks (parent must resolve before
child can run); they are batched separately. A query 5 levels deep with DataLoader at
each level generates 5 batched queries (one per level). DataLoader reduces N^depth to
depth (linear instead of exponential).

---

**[JUNIOR] Q2 (Application): How do you implement a one-to-many DataLoader?**

A one-to-many DataLoader handles cases where one key maps to multiple values (e.g.,
one post has many comments).

Implementation:
```javascript
// One-to-many: postId -> [Comment, Comment, ...]
const commentsByPostIdLoader = new DataLoader(
  async (postIds) => {
    // Fetch all comments for all post IDs at once
    const allComments = await db.query(`
      SELECT * FROM comments
      WHERE post_id = ANY($1::integer[])
    `, [postIds]);

    // Group comments by post ID
    const groups = new Map(
      postIds.map(id => [String(id), []])
    );
    for (const comment of allComments) {
      const key = String(comment.postId);
      if (groups.has(key)) {
        groups.get(key).push(comment);
      }
    }

    // Return arrays in postIds order
    // (DataLoader requires this!)
    return postIds.map(id => groups.get(String(id)));
    // Result: [[Comment1, Comment2], [Comment3], [], ...]
    // Index 0 = comments for postIds[0]
    // Index 1 = comments for postIds[1]
    // ...
  }
);

// Usage in resolver:
const resolvers = {
  Post: {
    comments: ({ id }, _, { loaders }) =>
      loaders.commentsByPostId.load(String(id))
      // Returns Promise<Comment[]>
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a one-to-many DataLoader that batches comment lookups by post ID, grouping comments by their `postId` and returning an array of comments per post. (2) KEY MECHANISM: the batch function initializes a Map with empty arrays for each input post ID; iterates all fetched comments and groups them by `postId`; returns an array of arrays in the same order as input `postIds`. (3) WHY IT MATTERS: the one-to-many pattern is the most common DataLoader use case; every parent-children relationship in a relational schema (post/comments, order/items, user/addresses) requires this pattern. (4) WHAT BREAKS: forgetting to initialize empty arrays for posts with no comments causes `undefined` at positions where no comments exist; `postIds.map(id => groups.get(id) || [])` handles the "no comments" case. (5) TAKEAWAY: one-to-many DataLoaders differ from one-to-one only in the batch function: group results by key (a Map of arrays) and return an array-of-arrays; the outer array order must match input IDs.

*What separates good from great:* The DataLoader options for performance tuning.
Two important options: (1) `maxBatchSize: N` - limits how many keys are batched in
one call; useful if the database has `IN` clause size limits or if very large batches
should be split; (2) `cache: false` - disables the per-request cache; use when the
entity changes within a single request (e.g., a mutation and a query in the same
request share a context); rare but important for mutations that query the same entities
they modify. The default `cache: true` is correct for read-heavy workloads; `cache: false`
for write-then-read patterns within the same request context.

---

**[SENIOR] Q3 (Application): How do you test resolvers that use DataLoader?**

Testing DataLoader-based resolvers requires mocking the context and DataLoader instances:

```javascript
// Option 1: Unit test with mocked DataLoader
describe('Post.author resolver', () => {
  it('loads author via DataLoader', async () => {
    const mockUser = {
      id: '1', name: 'Alice', role: 'USER'
    };
    // Mock DataLoader that returns the mock user
    const mockContext = {
      loaders: {
        user: {
          load: jest.fn().mockResolvedValue(mockUser)
        }
      }
    };

    const post = { id: '10', authorId: '1' };
    const result = await resolvers.Post.author(
      post, {}, mockContext
    );

    // Verify DataLoader.load was called with correct ID
    expect(mockContext.loaders.user.load)
      .toHaveBeenCalledWith('1');
    expect(result).toEqual(mockUser);
  });
});

// Option 2: Integration test with real DataLoader
// (verifies batching behavior)
describe('DataLoader batching', () => {
  it('batches multiple loads into one DB query', async () => {
    const dbSpy = jest.spyOn(db, 'query');
    const loader = new DataLoader(
      async (ids) => db.getUsersByIds(ids)
    );

    // Simulate concurrent loads (same tick)
    await Promise.all([
      loader.load('1'),
      loader.load('2'),
      loader.load('1')  // Duplicate - should not add query
    ]);

    // Verify ONE batched query, not three
    expect(dbSpy).toHaveBeenCalledTimes(1);
    expect(dbSpy).toHaveBeenCalledWith(
      expect.any(String),
      [['1', '2']]  // Deduplicated IDs
    );
  });
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two testing approaches for DataLoader-based resolvers - unit testing with a mock DataLoader (tests resolver logic) and integration testing with a real DataLoader (tests batching behavior). (2) KEY MECHANISM: unit test with mock DataLoader verifies the resolver calls `load` with the correct ID and handles the response correctly; integration test with real DataLoader verifies the batching and deduplication behavior (3 loads, 1 DB call). (3) WHY IT MATTERS: DataLoader behavior (batching, deduplication, caching) is critical for performance and correctness; integration tests catch bugs in the batch function (ordering violations, missing null handling). (4) WHAT BREAKS: testing DataLoader batching requires `Promise.all([load1, load2, load3])` to run all loads in the same tick; sequential `await load1; await load2;` runs loads in different ticks and batching does not occur in tests. (5) TAKEAWAY: unit test resolvers with mock DataLoaders for fast, isolated tests; add integration tests for DataLoader batch functions to verify ordering and null handling; test edge cases: empty input array, all IDs missing from DB, duplicate IDs.

---

**[SENIOR] Q4 (Trade-off): DataLoader caches within a request. When is this a problem?**

DataLoader's per-request cache is beneficial in most cases: the same user ID requested
by 5 different resolvers in the same query results in 1 database query (not 5). The
result is cached as a Promise; subsequent `load(id)` calls with the same ID return
the resolved Promise immediately.

Problem: mutation + query within the same request using the same context.

Scenario: a request executes a mutation that updates a user AND a query that reads
the same user. If the query resolver runs before the mutation and caches the user, the
mutation updates the user, but the post-mutation query reads from the cache and returns
the pre-mutation value.

In practice, this is rare because:
1. GraphQL mutations and queries are typically separate requests.
2. Within a single request, mutations execute serially and queries in parallel; a
   mutation's user update would need to affect a query that runs in the same request.

When it is a problem: batched requests (Apollo Client's link chain can batch a mutation
and query into one HTTP request); the mutation updates a user, the query expects the
updated user, but gets the cached pre-update value.

Fix: `loader.clear(id)` after a mutation to invalidate the cache entry:
```javascript
Mutation: {
  updateUser: async (_, { id, input }, { loaders, db }) => {
    const user = await db.updateUser(id, input);
    loaders.user.clear(id);  // Invalidate cache entry
    return user;
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `loader.clear(id)` to invalidate a specific cache entry after a mutation that updates the entity, preventing subsequent reads in the same request from returning stale pre-mutation data. (2) KEY MECHANISM: `clear(id)` removes the cached Promise for that ID; the next `load(id)` call in the same request creates a new batch entry; the batch function queries the database again for the current (post-mutation) value. (3) WHY IT MATTERS: this edge case arises primarily in batched GraphQL request scenarios; clearing the cache after mutations that affect cached entities ensures correctness in those scenarios. (4) WHAT BREAKS: `clearAll()` clears the entire cache; if used after every mutation, it defeats DataLoader's caching benefit for the rest of the request. (5) TAKEAWAY: add `loader.clear(id)` in mutation resolvers that update entities that might be read later in the same request; this is a targeted fix for a specific edge case, not a general pattern.

---

**[JUNIOR] Q5 (Definition): Why must DataLoader instances be created per-request?**

DataLoader instances maintain an in-memory cache (a Map from key to Promise). This
cache lives for the lifetime of the DataLoader instance. If a DataLoader instance is
shared across requests:
- Request A loads `User:1` -> User A data is cached.
- Request B loads `User:1` -> Returns User A data from cache (stale or wrong!).
- Request C modifies `User:1` -> Cache is NOT invalidated (DataLoader has no cache
  invalidation mechanism for external changes).

Security implication: User B's request might see User A's private data if they load
the same user ID. This is a critical data leakage security vulnerability.

Correct implementation: create a new DataLoader instance for EVERY request:
```javascript
const server = new ApolloServer({
  context: ({ req }) => ({
    // New DataLoader instance per request:
    loaders: {
      user: new DataLoader(
        async (ids) => db.getUsersByIds(ids)
      )
    }
    // Cache lifetime = request lifetime
    // Garbage collected when request context is gc'd
  })
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: creating DataLoader instances in the Apollo Server context function to ensure each request gets fresh DataLoader instances with empty caches. (2) KEY MECHANISM: `context()` is called once per request; returning `new DataLoader(...)` creates a fresh instance with an empty Map cache; the instance is garbage collected when the request context goes out of scope (after response is sent). (3) WHY IT MATTERS: per-request DataLoaders ensure request isolation; User A's cached data never leaks to User B's request; this is both a correctness requirement and a security requirement. (4) WHAT BREAKS: `const globalLoader = new DataLoader(...)` at module scope is a classic mistake; it looks harmless in single-user development but causes data leaks and stale data in multi-user production. (5) TAKEAWAY: ALWAYS create DataLoader instances in the context function; NEVER create them at module scope or as singletons; this is a security requirement, not just a best practice.

*What separates good from great:* The memory implication of per-request DataLoaders.
Each request creates new DataLoader instances; each instance allocates a Map for the
cache; under high load (1000 requests/second), 1000 DataLoader instances are created
and garbage collected per second. This is acceptable because DataLoaders are lightweight
(small Map, no OS resources); the GC overhead is minimal. However, if DataLoaders are
created but rarely used (contexts where most requests don't hit the batched endpoints),
lazy initialization reduces unnecessary allocations:
`get user() { return this._user || (this._user = new DataLoader(...)) }`.

---

**[SENIOR] Q6 (Scenario): DataLoader is in use but the N+1 problem still exists. How do you diagnose?**

Scenario: DataLoader was added to the context 6 months ago; a performance audit reveals
database still receives N+1 queries for the `Post.author` field.

Diagnosis steps:

Step 1 - Enable database query logging:
```bash
# PostgreSQL: log all queries
# Add to postgresql.conf:
# log_min_duration_statement = 0  # Log all queries
# In psql:
SET log_min_duration_statement = 0;
# Execute the GraphQL query and check logs:
tail -f /var/log/postgresql/postgresql-*.log \
  | grep "SELECT.*users"
# Expected with DataLoader: ONE SELECT ... WHERE id IN (...)
# Indicates N+1: multiple "SELECT ... WHERE id = ..." lines
```

> **Code walkthrough:** (1) WHAT IT SHOWS: enabling database query logging to distinguish DataLoader batching (one `IN (...)` query) from N+1 (many individual `WHERE id = ?` queries) at the database level, not the application level. (2) KEY MECHANISM: `log_min_duration_statement = 0` logs every query regardless of execution time; counting the number of `SELECT * FROM users WHERE id =` queries in the log after one GraphQL request reveals whether batching is working. (3) WHY IT MATTERS: application-level logging (adding console.log in resolvers) might not accurately reflect when DataLoader's batch function fires; database logs are the ground truth. (4) WHAT BREAKS: high-verbosity query logging in production creates significant log volume; use only in investigation, not in normal production operation; use sampling (log 1% of queries) for normal monitoring. (5) TAKEAWAY: when debugging N+1, go to the database logs; the query pattern (one `IN` query vs many `WHERE id =` queries) definitively identifies whether DataLoader is batching correctly.

Step 2 - Check the resolver for DataLoader usage:
```javascript
// Is DataLoader actually being called?
Post: {
  author: async ({ authorId }, _, { loaders }) => {
    // Is 'loaders' in context?
    // Is loaders.user a DataLoader instance?
    // Is the resolver calling loaders.user.load()?
    console.log(typeof loaders?.user?.load);
    // If undefined -> DataLoader not in context!
    // If function -> DataLoader present
    return loaders?.user?.load(authorId);
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a diagnostic console.log that checks whether the DataLoader is present in the resolver context, distinguishing between a missing context setup and a missing `load()` call. (2) KEY MECHANISM: `typeof loaders?.user?.load === 'function'` confirms the DataLoader instance is in context; `undefined` indicates the context function is not creating DataLoaders for this request path. (3) WHY IT MATTERS: the two failure causes have different fixes: missing DataLoader in context requires a context factory update; wrong resolver code requires a resolver update; the diagnostic distinguishes them. (4) WHAT BREAKS: optional chaining `loaders?.user?.load` hides the bug silently (returns undefined instead of throwing); for debugging, temporarily remove optional chaining to get an explicit error. (5) TAKEAWAY: always log or inspect context structure when DataLoader batching is not occurring; the context is the single source of DataLoader availability.

Step 3 - Common causes of DataLoader bypass:
- Resolver uses `context.db.getUser(id)` directly (DataLoader never called).
- DataLoader not included in context for certain request paths (e.g., missing from
  context function for WebSocket subscription requests).
- Wrong DataLoader instance used (using a loader that queries a different table).

*What separates good from great:* The DataLoader metrics approach. In production, add
a counter to the DataLoader batch function to track batch sizes:
```javascript
const userLoader = new DataLoader(async (ids) => {
  metrics.histogram('dataloader.userBatchSize', ids.length);
  const users = await db.getUsersByIds(ids);
  return ids.map(id => userMap.get(id) || null);
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: adding a metrics histogram to the DataLoader batch function to track batch sizes in production, enabling detection of batching failures (batch size consistently 1 = batching broken). (2) KEY MECHANISM: `ids.length` is the batch size; a healthy DataLoader with N post author resolvers has batch size N; a broken DataLoader (load() calls in different ticks) has batch size 1; the histogram reveals the pattern. (3) WHY IT MATTERS: N+1 problems in production are often introduced gradually as developers add new resolvers that bypass DataLoader; batch size monitoring catches regressions before they impact production performance. (4) WHAT BREAKS: monitoring only average batch size hides bimodal distributions; use percentiles (p50, p95) to see whether most batches are large (healthy) with occasional small batches (expected for sequential requests). (5) TAKEAWAY: instrument DataLoader batch functions with metrics from day one; batch size histograms are the primary DataLoader health metric.

If batch sizes are consistently 1 (histogram shows all values are 1), the DataLoader
is being called but is NOT batching - possible causes: load() calls are occurring in
different event loop ticks (async calls before load()), or the DataLoader is being
recreated unnecessarily. Batch size metrics are the DataLoader health check.

---

**[SENIOR] Q7 (Debugging): How does DataLoader behave when the batch function throws an error?**

When the DataLoader batch function throws an error, DataLoader rejects ALL promises in
the current batch with the same error. This is the "broadcast failure" behavior.

```javascript
// Batch function that may throw:
const userLoader = new DataLoader(async (ids) => {
  // If this throws, ALL queued load() calls reject
  const users = await db.getUsersByIds(ids);

  // BETTER: handle partial failures per-ID
  return ids.map(id => {
    const user = userMap.get(String(id));
    if (!user) {
      // Return Error for missing users (not null)
      // DataLoader rejects ONLY that promise
      return new Error(
        `User not found: ${id}`
      );
    }
    return user;
  });
});
// Usage: loader.load(id) rejects with Error
// for missing IDs, resolves for found IDs
// Other IDs in the same batch are NOT affected
```

> **Code walkthrough:** (1) WHAT IT SHOWS: returning `Error` instances from the batch function for specific IDs, causing DataLoader to reject only the affected promises rather than broadcasting failure to all IDs in the batch. (2) KEY MECHANISM: DataLoader distinguishes between batch-level throws (reject ALL batch promises) and per-ID Error instances (reject only that ID's promise); returning `new Error(...)` for a specific index causes only that ID's `load()` promise to reject; other IDs in the batch succeed. (3) WHY IT MATTERS: a single missing user should not cause all 100 posts in a batch to fail to load; per-ID error handling enables graceful partial failures where only the affected fields are null/error. (4) WHAT BREAKS: returning `null` instead of `new Error()` for a missing user causes DataLoader to return null (no error); the component receives null for `post.author` and must handle it gracefully; returning Error causes the resolver to throw and GraphQL to return a partial error in the response. (5) TAKEAWAY: use `return new Error(...)` for expected not-found cases; use throw for unexpected errors (network failures, database connection loss); this distinction enables fine-grained error handling per batch entry.

*What separates good from great:* The DataLoader error vs null distinction in GraphQL.
When a batch function returns `null` for a missing entity, the GraphQL response includes
`"author": null`. When it returns `new Error(...)`, the GraphQL response includes
`"errors": [{"message": "User not found: 42", "path": ["posts", 0, "author"]}]`
with `"author": null` in the data. Use Error for entities that should exist (referential
integrity violation - the foreign key points to a non-existent user) and null for
optional fields. This distinction helps clients distinguish "this is intentionally empty"
from "this is a data integrity problem".

---

### 🎯 Model Answer

**30 seconds:**
> Two pagination approaches: offset (`page=2, limit=10`) and cursor-based (`after=XYZ,
> first=10`). Offset is simpler but has inconsistency issues: if items are added/deleted
> while paginating, items may be skipped or duplicated. Cursor-based pagination is stable:
> the cursor points to a specific item in the data set; items added after the cursor are
> not included; items before the cursor are not repeated. The Relay Connection specification
> (`edges`, `node`, `cursor`, `pageInfo`) is the GraphQL standard for cursor-based pagination.

**3 minutes (Senior):**
> Offset pagination limitation: the database uses `OFFSET N LIMIT M`; if records are
> inserted before offset N while the user is on page 2, the page boundaries shift and
> items from page 1 "leak" onto page 2 (the user sees duplicates) or items between pages
> 1 and 2 are skipped. This is a consistency problem inherent to offset pagination.
> Cursor-based pagination uses a stable cursor (opaque base64 string encoding the position:
> record ID, created_at, or a composite sort key); the query is `WHERE id > cursor_id
> LIMIT N` (keyset pagination) or similar; insertions and deletions before the cursor
> do not affect the page; insertions after the cursor are included in subsequent pages
> (correct behavior for a live feed). Relay Connection spec: `edges: [{ node: T, cursor: String }]`
> and `pageInfo: { hasNextPage, hasPreviousPage, startCursor, endCursor }`. Trade-off:
> cursor pagination cannot jump to page N (no random access); only next/previous
> navigation is supported. For random-access pagination (DataGrid with page 1, 2, ..., N),
> offset is more appropriate despite its consistency limitations.

**Blank Mind Recovery:**

**(1) Restate:** "Offset: simple, inconsistent under concurrent writes. Cursor: stable,
no random access. Relay Connection: `edges[node, cursor]` + `pageInfo[hasNextPage, endCursor]`.
Cursor = opaque base64 of sort key. Keyset pagination: `WHERE created_at > cursor AND
LIMIT 20`. Apollo fetchMore with endCursor for next page."

---

### 📘 Concept Explanation

**Offset vs Cursor Pagination Comparison:**

```text
OFFSET PAGINATION PROBLEM (Concurrent Inserts):

  Page 1 query (LIMIT 10 OFFSET 0):
  Posts: [A, B, C, D, E, F, G, H, I, J]

  [User reading page 1]

  [New post X inserted before A]
  Posts now: [X, A, B, C, D, E, F, G, H, I, J, ...]

  Page 2 query (LIMIT 10 OFFSET 10):
  Posts: [J, K, L, M, N, O, P, Q, R, S]
  ^-- J was on page 1! DUPLICATE for user.
  K through S: never shown (shifted).

  CURSOR PAGINATION STABILITY:

  Page 1 query (FIRST 10, AFTER null):
  Returns: [A, B, ..., J]
  endCursor = "cursor(J)"

  [New post X inserted before A]
  Posts: [X, A, B, C, D, E, F, G, H, I, J, ...]

  Page 2 query (FIRST 10, AFTER cursor(J)):
  Query: WHERE sort_key > J.sort_key LIMIT 10
  Returns: [K, L, M, N, O, P, Q, R, S, T]
  ^-- Starts after J; X is before J; not included.
  ^-- No duplicates; no gaps relative to J.

  TRADE-OFF: No random access.
  Cannot jump to "page 5" with cursor pagination.
  Can only navigate forward (AFTER cursor)
  and backward (BEFORE cursor).
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the offset pagination consistency failure scenario (concurrent insert causes duplicate on page 2) and cursor pagination's stability (subsequent pages always start after the cursor position, unaffected by inserts). (2) HOW TO READ IT: the offset section shows how a new insert shifts all positions, causing the page boundary to move; post J moves from the end of page 1 to the start of page 2. (3) KEY RELATIONSHIP: cursor pagination's stability comes from keyset pagination (`WHERE sort_key > cursor_value LIMIT N`); the cursor encodes an absolute position in the sort order, not a row count; inserts/deletes that affect rows before the cursor do not change the rows after it. (4) EDGE CASE: if the cursor is based on `created_at` and two posts have the exact same `created_at` timestamp, the cursor is ambiguous; use a composite cursor `(created_at, id)` where `id` breaks ties; the Relay cursor convention encodes both. (5) INSIGHT: a senior engineer notes that cursor pagination also has a consistency edge case: if the item that the cursor points to is deleted, the next page query returns items after the deleted item's position (based on the sort key value, not the item itself); this is typically acceptable behavior for most use cases.

---

### 💻 Code Example

```graphql
# BAD: Offset pagination in GraphQL schema
# (inconsistent under concurrent writes;
# no standard format)

type Query {
  posts(
    page: Int = 1       # Page number (implicit offset)
    limit: Int = 10
  ): PostPage
}

type PostPage {
  posts: [Post!]!
  total: Int!           # Total count (expensive query!)
  currentPage: Int!
  totalPages: Int!
}
# Problems:
# 1. Offset inconsistency under concurrent inserts/deletes
# 2. total count requires COUNT(*) query (expensive)
# 3. No standard format; each API invents its own
# 4. No cursor for Apollo Client integration
# 5. Page-based (jump to page N) conflicts with
#    infinite scroll UX patterns
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the offset-based pagination schema anti-pattern with page numbers and total counts, highlighting the expense of `COUNT(*)` and the non-standard format. (2) KEY MECHANISM: `total: Int!` requires a `SELECT COUNT(*) FROM posts WHERE ...` query for every paginated list request; on a table with 10 million rows, `COUNT(*)` with a WHERE clause is an expensive full scan unless there is an index on the filter columns. (3) WHY IT MATTERS: the `total` count is the most expensive part of offset pagination; with 1000 requests/second, 1000 count queries per second can overwhelm the database; many production APIs return an estimated count or remove the total count entirely. (4) WHAT BREAKS: non-standard format (custom `PostPage` type per list) means Apollo Client cannot auto-handle pagination; each list requires custom pagination code instead of using `relayStylePagination()` or similar helpers. (5) TAKEAWAY: avoid offset pagination for data that is frequently updated (social feeds, activity streams, live order lists); use the Relay Connection spec as the standard GraphQL pagination format.

```graphql
# GOOD: Relay Connection spec cursor-based pagination

type Query {
  posts(
    first: Int          # Number of items (forward pagination)
    after: String       # Cursor (opaque; forward)
    last: Int           # Number of items (backward pagination)
    before: String      # Cursor (opaque; backward)
    filter: PostFilter  # Optional filtering
    orderBy: PostOrderBy # Sort field
  ): PostConnection!
}

type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  # Optional: totalCount (expensive; use sparingly)
  # totalCount: Int
}

type PostEdge {
  node: Post!           # The actual post
  cursor: String!       # Opaque cursor for this position
}

type PageInfo {
  hasNextPage: Boolean! # Are there more pages forward?
  hasPreviousPage: Boolean! # Are there pages backward?
  startCursor: String   # Cursor of first item in page
  endCursor: String     # Cursor of last item (use for next page)
}

# Server-side cursor implementation:
# cursor = base64("Post:${id}:${createdAt}")
# Query: WHERE created_at > decodedCursor.createdAt
#          OR (created_at = decodedCursor.createdAt
#              AND id > decodedCursor.id)
#        ORDER BY created_at ASC, id ASC
#        LIMIT first
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Relay Connection spec for cursor-based pagination with `PostConnection`, `PostEdge`, and `PageInfo` types, and the composite cursor encoding that prevents ambiguity with ties. (2) KEY MECHANISM: `cursor = base64("Post:id:createdAt")` encodes both the sort key (createdAt) and the tie-breaker (id); the database query decodes the cursor and uses keyset pagination (`WHERE created_at > cursor.createdAt OR (created_at = cursor.createdAt AND id > cursor.id)`). (3) WHY IT MATTERS: the Relay Connection spec is the GraphQL community standard; Apollo Client's `relayStylePagination()` helper automatically handles cursor merging in the cache for Relay spec APIs; no custom pagination code needed. (4) WHAT BREAKS: if the cursor is based on a mutable field (like `updatedAt`), the cursor position changes when the record is updated; use `id` or `createdAt` (immutable fields) as cursor components. (5) TAKEAWAY: adopt the Relay Connection spec for all list types; it is the universal standard; all GraphQL tooling and client libraries support it; designing custom pagination formats creates unnecessary integration complexity.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Two pagination types: offset (page-based: `page=2, size=10`) and cursor-based (position-
> based: `after=cursor, first=10`). Offset is simpler; cursor is more reliable. In
> GraphQL, the standard format is the Relay Connection spec: a query returns a
> `Connection` type with `edges` (items + cursors) and `pageInfo` (has-next, end-cursor).
> To load the next page, use the `endCursor` from the current page as the `after` argument
> in the next query. Apollo Client's `fetchMore` function handles this automatically.

---

**Senior / Staff (5+ years):**
> Pagination choice is data-access-pattern-dependent: (1) Offset pagination: best for
> data with rare concurrent writes (search results, reports); supports random access
> (jump to page N); `COUNT(*)` for total count is expensive but manageable; simple client
> implementation. (2) Cursor pagination: best for live feeds, social timelines, order
> history (frequent concurrent writes); consistent under concurrent inserts/deletes; no
> random access; cursor must encode immutable sort fields. (3) Relay Connection spec: use
> for all cursor-based pagination; it is the standard; tooling (Apollo, Relay, graphql-
> codegen) all support it natively. (4) Keyset pagination: the SQL pattern underlying
> cursor pagination; `WHERE sort_key > cursor_value ORDER BY sort_key LIMIT N`; requires
> an index on the sort key; much more efficient than `OFFSET N` for large datasets.

---

### ⚠️ Common Misconceptions

**Misconception: "Cursor-based pagination is always better than offset pagination."**

Cursor-based pagination is better for consistency under concurrent writes and for large
datasets. But it has limitations: (1) No random access: you cannot jump to "page 47"
with a cursor; you can only navigate forward (next) and backward (previous). (2)
Sorting complexity: the cursor must encode ALL sort fields to be a stable position;
a cursor that encodes only `id` is broken for multi-field sorts (e.g., `ORDER BY
createdAt DESC, id DESC`). (3) Client complexity: clients must track cursors; fetching
more requires storing the `endCursor`; the code is more complex than `page + 1`. (4)
User expectation: users who expect "page 1, page 2, page 3" navigation (data grids,
search results) are better served by offset pagination; infinite scroll and "load more"
UX patterns are natural fits for cursor pagination. The choice should be driven by the
use case, not by a general rule.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Cursor pagination returns duplicates due to non-unique cursor sort key.**

Symptom: some items appear on both page 1 and page 2; the list shows duplicates.
Root cause: the cursor sort key has non-unique values for adjacent records; the keyset
query includes records from the previous page.

```sql
-- BAD: cursor based only on non-unique 'status' field
SELECT * FROM orders
WHERE status > :cursor_status
ORDER BY status
LIMIT 10;
-- Problem: many orders have status='PENDING'
-- cursor('PENDING') includes ALL PENDING orders!
-- Ambiguous; returns same records repeatedly.

-- BAD: cursor based only on created_at
-- (may not be unique)
SELECT * FROM orders
WHERE created_at > :cursor_time
ORDER BY created_at
LIMIT 10;
-- Problem: two orders created in same millisecond
-- Share the same created_at; ambiguous cursor

-- GOOD: composite cursor (created_at, id) for uniqueness
SELECT * FROM orders
WHERE (created_at, id) > (:cursor_time, :cursor_id)
ORDER BY created_at ASC, id ASC
LIMIT 10;
-- (created_at, id) is unique: no two orders share both
-- This is a composite keyset pagination query
-- Requires index: CREATE INDEX ON orders
--   (created_at, id);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the duplicate cursor problem from non-unique sort keys and the composite cursor fix using `(created_at, id)` which is guaranteed unique. (2) KEY MECHANISM: `(created_at, id) > (:cursor_time, :cursor_id)` uses row comparison which PostgreSQL evaluates as: either `created_at > cursor_time`, or `created_at = cursor_time AND id > cursor_id`; this precisely defines "after this position" without ambiguity. (3) WHY IT MATTERS: duplicate items in a paginated list are a data integrity issue that users notice and report; the root cause (non-unique cursor) is subtle and often not caught in testing (tests typically use unique timestamps). (4) WHAT BREAKS: PostgreSQL's tuple comparison `(a, b) > (:a, :b)` is standard SQL but not all databases support it; MySQL uses `WHERE a > :a OR (a = :a AND b > :b)` as the equivalent. (5) TAKEAWAY: always use a composite cursor that includes a unique field (typically the primary key `id`) as the final component; this guarantees uniqueness and prevents duplicates at page boundaries.

---

### ⚖️ Comparison Table

| Aspect | Offset Pagination | Cursor Pagination |
|---|---|---|
| Consistency | Low (skips/dupes on concurrent writes) | High (stable positions) |
| Random access | Yes (jump to page N) | No (sequential only) |
| Performance | Degrades with OFFSET N (full scan) | Consistent (index seek) |
| Complexity | Simple | Moderate (cursor encoding) |
| GraphQL standard | Non-standard | Relay Connection spec |
| Apollo Client | Manual handling | relayStylePagination() |
| Use case | Search, reports, data grids | Feeds, timelines, history |
| COUNT(*) cost | Required (expensive) | Optional (not needed) |

---

### 🏛️ System Design

*(Omit: L2 keyword; pagination at scale (sharding, distributed cursors) covered in L5 Architecture entry.)*

---

### 📊 Diagram

```text
RELAY CONNECTION RESPONSE STRUCTURE:

  query { posts(first:3, after:null) {
    edges { node { id title } cursor }
    pageInfo { hasNextPage endCursor }
  } }

  Response:
  {
    posts: {
      edges: [
        { node: {id:"1", title:"A"},
          cursor: "base64(Post:1:2024-01-01)" },
        { node: {id:"2", title:"B"},
          cursor: "base64(Post:2:2024-01-02)" },
        { node: {id:"3", title:"C"},
          cursor: "base64(Post:3:2024-01-03)" }
      ],
      pageInfo: {
        hasNextPage: true,
        endCursor: "base64(Post:3:2024-01-03)"
      }
    }
  }

  NEXT PAGE:
  query { posts(first:3,
    after:"base64(Post:3:2024-01-03)") { ... } }
  -> SQL: WHERE (created_at, id) > (2024-01-03, 3)
          ORDER BY created_at, id LIMIT 3

  CLIENT (Apollo fetchMore):
  fetchMore({
    variables: {
      after: data.posts.pageInfo.endCursor
    }
  })
  -> Apollo merges new edges with existing
  -> Component re-renders with full list
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the complete Relay Connection response structure showing edges with node + cursor, pageInfo with hasNextPage + endCursor, and the flow from the first page's endCursor to the next page's `after` argument. (2) HOW TO READ IT: the first query uses `after: null` (start from beginning); the response includes 3 posts with their cursors and `pageInfo.endCursor = last cursor`; the next page query uses that `endCursor` as `after`; the SQL translates to a keyset condition. (3) KEY RELATIONSHIP: the `endCursor` is both the position marker for the last item on the page AND the `after` parameter for the next page; this is the single connection between pages. (4) EDGE CASE: if `hasNextPage` is false, there are no more items; the client should not make another `fetchMore` call; checking `hasNextPage` before calling `fetchMore` prevents a spurious empty query. (5) INSIGHT: a senior engineer notes that the cursor is opaque (base64 encoded) and should not be parsed by clients; it is an implementation detail of the server; changing the cursor encoding (e.g., from ID-based to UUID-based) is a non-breaking change as long as old cursors are still honored; some servers use a cursor expiry policy (cursors valid for 24 hours) to allow internal cursor format changes.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | offset vs cursor, Relay spec |
| Application | 2 | keyset pagination SQL, Apollo implementation |
| Trade-off | 2 | when to use each, consistent vs random access |
| Scenario | 2 | duplicate diagnosis, cursor design |

---

**[JUNIOR] Q1 (Definition): What are the two main pagination approaches in GraphQL?**

Offset pagination: `page` (or `offset`) + `limit` parameters.
```graphql
query { posts(offset: 20, limit: 10) { id title } }
# DB: SELECT * FROM posts LIMIT 10 OFFSET 20
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the offset pagination query pattern with a simple GraphQL API. (2) KEY MECHANISM: `OFFSET 20 LIMIT 10` instructs the database to skip 20 rows and return the next 10; the database scans 30 rows and discards the first 20. (3) WHY IT MATTERS: at large offsets (page 100 of 10-item pages = OFFSET 990), the database scans 1000 rows and discards 990 - highly inefficient. (4) WHAT BREAKS: concurrent inserts shift all row positions; page 2 may return a duplicate of the last item from page 1. (5) TAKEAWAY: offset pagination is simple but has consistency and performance limitations at scale.

Cursor pagination: `first`/`after` (or `last`/`before`) parameters with opaque cursors.
```graphql
query { posts(first: 10, after: "cursor_value") {
  edges { node { id title } cursor }
  pageInfo { hasNextPage endCursor }
} }
# DB: WHERE id > decode(cursor_value) LIMIT 10
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Relay Connection cursor pagination query pattern with `first`/`after` and the full `edges/pageInfo` response structure. (2) KEY MECHANISM: `after: "cursor_value"` is decoded server-side to a sort position; the database executes a keyset query (`WHERE id > decoded_id LIMIT 10`); no row scanning or skipping. (3) WHY IT MATTERS: keyset pagination is O(log N) via index seek regardless of page depth; offset pagination degrades to O(N) at deep pages. (4) WHAT BREAKS: if `cursor_value` is malformed or expired, the server must return an appropriate error; never assume cursor values are valid. (5) TAKEAWAY: the Relay Connection spec (`edges/node/cursor/pageInfo`) is the GraphQL standard for cursor pagination; adopt it for all new list types.

Key difference:
- Offset: position is row number (offset 20 = rows 21-30).
- Cursor: position is a specific item in the sorted data.
- Under concurrent inserts: offset pages shift; cursor pages are stable.

In GraphQL specifically: cursor pagination with the Relay Connection spec (`edges`,
`node`, `cursor`, `pageInfo`) is the community standard. Use it for new APIs.

*What separates good from great:* The "keyset pagination" term for cursor-based SQL.
Cursor-based pagination is implemented in SQL as keyset pagination: instead of
`OFFSET N` (skip N rows - requires full scan), use `WHERE sort_key > last_seen_value`
(index seek directly to the position). Keyset pagination is O(log N) (index seek);
offset pagination is O(N) (scan N rows to skip them). For the 100th page of a 1-million
row table: offset requires scanning 990,000 rows to skip; keyset seeks directly to
the position via the index. The performance difference is dramatic at scale.

---

**[JUNIOR] Q2 (Application): How do you implement the Relay Connection spec in a GraphQL server?**

The Relay Connection spec defines the response structure. Server implementation:

```javascript
// Schema types (already defined above in SDL section)
// PostConnection, PostEdge, PageInfo

// Resolver implementation
const resolvers = {
  Query: {
    posts: async (_, {
      first = 10,
      after,
      filter,
      orderBy = { field: 'CREATED_AT', direction: 'ASC' }
    }) => {
      // Decode cursor (if provided)
      let afterCursor = null;
      if (after) {
        const decoded = Buffer.from(after, 'base64')
          .toString('utf8');
        // Format: "Post:${id}:${createdAt}"
        afterCursor = JSON.parse(decoded);
      }

      // Keyset query
      const whereClause = afterCursor
        ? `WHERE (created_at, id) > ($1, $2)`
        : '';
      const params = afterCursor
        ? [afterCursor.createdAt, afterCursor.id]
        : [];

      // Fetch first + 1 to detect hasNextPage
      const rows = await db.query(`
        SELECT * FROM posts
        ${whereClause}
        ORDER BY created_at ASC, id ASC
        LIMIT $${params.length + 1}
      `, [...params, first + 1]);

      const hasNextPage = rows.length > first;
      const edges = rows.slice(0, first).map(row => ({
        node: row,
        cursor: Buffer.from(
          JSON.stringify({
            id: row.id,
            createdAt: row.createdAt
          })
        ).toString('base64')
      }));

      return {
        edges,
        pageInfo: {
          hasNextPage,
          hasPreviousPage: !!after, // Simplified
          startCursor: edges[0]?.cursor || null,
          endCursor: edges[edges.length - 1]?.cursor || null
        }
      };
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a complete Relay Connection resolver implementation with cursor decoding, keyset SQL query, `hasNextPage` detection via fetching `first + 1` items, and cursor encoding for the edge list. (2) KEY MECHANISM: fetching `first + 1` rows is the standard technique for detecting `hasNextPage` without a COUNT query; if `rows.length > first`, there is at least one more page; slice to `first` items for the actual response. (3) WHY IT MATTERS: `hasNextPage` without fetching `first + 1` would require a separate `COUNT(*)` query; fetching one extra row is cheaper than a count query. (4) WHAT BREAKS: `Buffer.from(json).toString('base64')` creates an opaque cursor; clients must not parse this; if the cursor encoding changes (new sort field added), old cursors from pre-change pages are invalid; add a version prefix to cursors for forward compatibility. (5) TAKEAWAY: the "fetch first + 1" trick for `hasNextPage` is the standard Relay Connection implementation pattern; avoid `COUNT(*)` for pagination; cursor encoding should be opaque, versioned, and immutable for a given sort order.

---

**[SENIOR] Q3 (Trade-off): When would you choose offset pagination despite its consistency problems?**

Offset pagination is the better choice when:

1. Random access is required: "jump to page 47" in a data table or search results.
   Cursor pagination cannot support page number navigation.

2. Data is write-rarely: a product catalog with 10,000 products and weekly updates;
   the offset consistency problem only manifests under concurrent writes; infrequent
   writes mean rare inconsistencies.

3. Total count is needed for UI: a "showing 21-30 of 500 results" display requires
   knowing the total count; cursor pagination's `COUNT(*)` optimization avoidance is
   lost if you need the total count anyway.

4. Simple implementation is preferred: offset is simpler to implement and understand;
   cursor encoding, keyset pagination, and cursor caching add complexity; if the
   consistency benefit is not needed, offset's simplicity wins.

5. Performance is acceptable: for small datasets (< 10,000 rows), `OFFSET N` performance
   is not a problem; the keyset advantage only materializes at scale (100,000+ rows and
   deep pagination).

Decision: use cursor pagination as the default for GraphQL APIs; override to offset for
data grid UX requirements, low-write data, or when total count display is required.

*What separates good from great:* The hybrid pagination approach. Some APIs use offset
for the initial load and "most recently loaded" scenarios (when the user is on page 1,
offset is fine because no pages were skipped), and cursor for "load more" infinite scroll
(avoiding consistency issues as the user scrolls deep). This hybrid is a pragmatic
compromise: simple offset for the common case (page 1), stable cursor for the edge case
(deep pagination with concurrent writes). The Relay Connection spec supports this because
the first query can use `after: null` (effectively offset = 0) and subsequent queries
use the returned cursor.

---

**[JUNIOR] Q4 (Application): How do you implement infinite scroll with Apollo Client and cursor pagination?**

Infinite scroll with Apollo Client uses `fetchMore` to load subsequent pages:

{% raw %}
```javascript
const FEED_QUERY = gql`
  query GetFeed($after: String) {
    posts(first: 20, after: $after) {
      edges {
        node { id title author { name } }
        cursor
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

function InfiniteScrollFeed() {
  const { data, loading, fetchMore } = useQuery(
    FEED_QUERY,
    { variables: {} }  // First page: after=undefined
  );

  // Load more when user scrolls to bottom
  const loadMore = useCallback(() => {
    if (!data?.posts.pageInfo.hasNextPage) return;
    if (loading) return;

    fetchMore({
      variables: {
        after: data.posts.pageInfo.endCursor
      }
      // Apollo merges the new edges with existing
      // via the merge policy defined in InMemoryCache
    });
  }, [data, loading, fetchMore]);

  // Intersection Observer for scroll detection
  const sentinel = useRef(null);
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) loadMore();
      },
      { threshold: 0.1 }
    );
    if (sentinel.current) {
      observer.observe(sentinel.current);
    }
    return () => observer.disconnect();
  }, [loadMore]);

  return (
    <div>
      {data?.posts.edges.map(({ node }) => (
        <PostCard key={node.id} post={node} />
      ))}
      {loading && <p>Loading...</p>}
      {/* Sentinel element at bottom of list */}
      <div ref={sentinel} style={{ height: 1 }} />
    </div>
  );
}
```
{% endraw %}

> **Code walkthrough:** (1) WHAT IT SHOWS: an infinite scroll implementation using Apollo Client's `fetchMore` with cursor pagination and an Intersection Observer to detect when the user reaches the bottom of the list. (2) KEY MECHANISM: `fetchMore({ variables: { after: endCursor } })` fetches the next page; Apollo's merge policy (configured in `InMemoryCache`) appends the new edges to the existing list; the component re-renders with all loaded posts. (3) WHY IT MATTERS: Intersection Observer is the performance-correct approach to scroll detection; it uses browser-native callbacks instead of scroll event listeners (which fire hundreds of times per second). (4) WHAT BREAKS: calling `loadMore` multiple times before the previous `fetchMore` completes results in duplicate page loads; the `if (loading) return` guard prevents this; alternatively, track loading state specifically for `fetchMore`. (5) TAKEAWAY: the IntersectionObserver + `fetchMore` + cursor pagination pattern is the standard infinite scroll implementation with Apollo Client; requires the merge policy in InMemoryCache for page accumulation.

---

**[SENIOR] Q5 (Trade-off): How does cursor pagination affect search and filtering?**

Cursor pagination with filtering: the filter is applied to the query, and the cursor
represents a position within the filtered result set, not the full dataset.

Challenge: the cursor is specific to a particular filter + sort combination. A cursor
from a "published posts" query cannot be used as the cursor for an "all posts" query.

```graphql
# Cursor is filter-specific:
query Page1Published {
  posts(first: 10, filter: { status: PUBLISHED }) {
    edges { node { id } cursor }
    pageInfo { endCursor }
  }
}
# endCursor: "base64(Post:5:2024-01-05)"

query Page2Published {
  # Using cursor from previous published-only query:
  posts(first: 10, filter: { status: PUBLISHED },
        after: "base64(Post:5:2024-01-05)") {
    ...
  }
}
# CORRECT: cursor is valid for same filter

query Page2AllPosts {
  # Using cursor from published-only query for ALL posts:
  posts(first: 10,
        after: "base64(Post:5:2024-01-05)") {
    ...
  }
}
# INCORRECT: cursor (Post:5) is from published set;
# mixed with all posts, might skip unpublished posts
# or include wrong items
```

> **Code walkthrough:** (1) WHAT IT SHOWS: that cursor pagination is filter-scoped; a cursor from a filtered query cannot be reliably used for a different filter, because the cursor position refers to a position in the sorted-and-filtered dataset, not the global dataset. (2) KEY MECHANISM: `base64(Post:5:2024-01-05)` encodes the position of Post 5 (published) in the sorted published-posts list; if Post 5 is position 5 in published posts but position 8 in all posts, using this cursor for all-posts pagination yields the wrong results. (3) WHY IT MATTERS: this affects client-side cursor caching; if a client navigates from a filtered list to the full list, the cached cursor is invalid; the client must restart pagination from the beginning. (4) WHAT BREAKS: some cursor implementations include the filter state in the cursor encoding; this guarantees cursor-filter consistency at the cost of cursor size and complexity. (5) TAKEAWAY: cursors are scoped to the query that created them; include filter context in cursor validation on the server; reject cursors that do not match the current query's filter/sort parameters; this prevents subtle pagination bugs from cursor reuse across different queries.

*What separates good from great:* The cursor as a fully-specified sort position. A
production-grade cursor encodes all components needed to precisely reproduce the position
in the sorted dataset: `{ sortField: "createdAt", sortValue: "2024-01-05", sortDirection: "ASC", id: 5, version: 1 }`. The `version` field allows cursor format evolution (v1
cursors use `createdAt`; v2 cursors use `updatedAt`); the server handles both versions.
This cursor design is robust to schema changes and supports multi-field sorting correctly.

---

**[JUNIOR] Q6 (Application): How does the GraphQL server compute `hasNextPage` efficiently?**

The standard technique: fetch `first + 1` items from the database. If `rows.length
> first`, there is at least one more item; return `rows.slice(0, first)` for the actual
page.

Alternatives and their costs:

1. `COUNT(*)` query (common but expensive):
   ```sql
   SELECT COUNT(*) FROM posts WHERE filter = ?
   ```

   > **Code walkthrough:** (1) WHAT IT SHOWS: a COUNT(*) query to determine total rows for hasNextPage calculation. (2) KEY MECHANISM: the database scans all matching rows (or uses an index) to count them; for complex WHERE clauses, this may be a full table scan. (3) WHY IT MATTERS: at 10 million rows, COUNT(*) with a filter takes seconds; at 1000 requests/second, count queries dominate database load. (4) WHAT BREAKS: counting with JOINs is even more expensive; any COUNT(*) with a JOIN forces evaluation of all matching join rows. (5) TAKEAWAY: avoid COUNT(*) for pagination; use the `first + 1` trick instead.

   Requires a separate database query; can be a full table scan without an index on
   the filter column; at scale (millions of rows), `COUNT(*)` with complex filters
   can take seconds.

2. Fetch first + 1 (efficient):
   ```sql
   SELECT * FROM posts WHERE sort_key > cursor
   ORDER BY sort_key LIMIT first + 1
   ```

   > **Code walkthrough:** (1) WHAT IT SHOWS: the `first + 1` trick for hasNextPage detection - fetching one extra row to determine whether more pages exist without a COUNT query. (2) KEY MECHANISM: if the database returns `first + 1` rows, there are at least `first + 1` matching rows; `hasNextPage = true`; return only the first `first` rows to the client. (3) WHY IT MATTERS: one query; one extra row transfer; much cheaper than COUNT(*) at scale. (4) WHAT BREAKS: if `first = 0`, fetching 1 row still works correctly (hasNextPage = rows.length > 0). (5) TAKEAWAY: always use `first + 1` for hasNextPage; never use COUNT(*).

   One query; costs one extra row transfer; efficient.

3. Estimated count (for large datasets):
   Some databases (PostgreSQL) have `pg_class.reltuples` for approximate row counts;
   useful for "total" count display but not for precise `hasNextPage`.

For `hasPreviousPage` in cursor pagination: similarly fetch `last + 1` items for
backward pagination. In practice, `hasPreviousPage` is often simplified:
if `after` is provided, `hasPreviousPage = true` (there was at least one page before).

*What separates good from great:* The connection for relay totalCount. Adding `totalCount`
to a Relay Connection type is tempting for UIs that need "showing 21-30 of 500 results".
But `COUNT(*)` queries are expensive; at 1000 requests/second with complex filters,
count queries can overwhelm the database. Two patterns: (1) approximate count using
database statistics (fast but imprecise), (2) count only for the first page (cached,
refreshed periodically). The most performant solution is often to not show the total
count; "showing 20 results, load more" is UX-equivalent to "showing 21-30 of 500"
for most use cases. Consider whether the total count justifies the database cost.

---

**[SENIOR] Q7 (Scenario): Users report seeing the same post twice when scrolling through an infinite feed. How do you debug?**

Symptom: item duplication in infinite scroll pagination.

Step 1 - Identify if it is a client-side or server-side issue:
Client-side: check Apollo Client's cache merge policy.
Server-side: inspect the cursor and the database query.

Step 2 - Check the Apollo cache merge policy:
```javascript
// Is the merge policy configured correctly?
const cache = new InMemoryCache({
  typePolicies: {
    Query: {
      fields: {
        posts: {
          // Is keyArgs correct? (determines cache key)
          keyArgs: ['filter', 'orderBy'],
          // Does merge accumulate pages?
          merge(existing = [], incoming) {
            return [...(existing.edges || []),
                    ...(incoming.edges || [])];
          }
        }
      }
    }
  }
});
// If merge is MISSING: each fetchMore replaces the list
// (no duplicates but data is lost!)
// If merge is WRONG: duplicates may occur
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing duplicate items by checking the Apollo Client cache merge policy for the paginated field. (2) KEY MECHANISM: without a merge policy, `fetchMore` REPLACES the existing cached edges with the new page; the user sees only the latest page; with a correct merge policy, pages accumulate; an incorrect merge policy (merging with wrong logic) can cause duplicates. (3) WHY IT MATTERS: Apollo's cache merge policies are the most common source of pagination issues in Apollo Client applications; they are easy to forget and their absence causes subtle (loss of previous page data) or obvious (duplicates) bugs. (4) WHAT BREAKS: `merge(existing, incoming)` where `existing` is undefined on first load requires a default value (`existing = []`); without the default, spreading `undefined.edges` throws an error on first load. (5) TAKEAWAY: always configure merge policies for paginated fields; test with at least 3 pages of data in development to verify accumulation.

Step 3 - Check the server-side cursor:
```sql
-- Is the cursor unique? Run this on the DB:
SELECT created_at, COUNT(*) as count
FROM posts
GROUP BY created_at
HAVING COUNT(*) > 1;
-- If any rows returned: duplicate timestamps!
-- These cause cursor ambiguity and duplicates.
-- Fix: use composite cursor (created_at, id)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a SQL diagnostic query to detect duplicate `created_at` timestamps that would cause cursor ambiguity and item duplication in cursor-based pagination. (2) KEY MECHANISM: any two posts with identical `created_at` values create an ambiguous cursor; the keyset query `WHERE created_at > cursor_time` may include or exclude both depending on exact millisecond values. (3) WHY IT MATTERS: duplicate timestamps are common in imported data (bulk imports, migrations) or in tests (posts created rapidly without timestamp variability). (4) WHAT BREAKS: even one pair of duplicate timestamps causes occasional duplicate pages for users whose page boundary falls exactly at those records. (5) TAKEAWAY: the diagnostic query identifies the scope of the duplicate timestamp problem; the fix is composite cursor `(created_at, id)`; this must be combined with a database index on `(created_at, id)` for performance.

*What separates good from great:* The deduplication guard on the client side. Even with
a correct server cursor, race conditions can cause the same item to appear twice in a
rapidly updating feed. Client-side deduplication: track seen item IDs and filter
duplicates before rendering. This is a defensive measure for feeds with frequent inserts.
`const uniquePosts = posts.filter((post, index) => posts.findIndex(p => p.id === post.id) === index)`.
This O(N²) deduplication is acceptable for typical feed sizes (< 1000 items displayed
simultaneously).
