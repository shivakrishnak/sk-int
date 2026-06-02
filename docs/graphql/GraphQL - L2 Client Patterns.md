---
layout: default
title: "GraphQL - L2 Client Patterns"
parent: "GraphQL"
nav_order: 4
permalink: /graphql/l2-client-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 10 | [Apollo Client: Queries, Mutations, and Cache](#apollo-client-queries-mutations-and-cache) | ★★☆ |
| 11 | [Fragments and Colocation Pattern](#fragments-and-colocation-pattern) | ★★☆ |

---

# Apollo Client: Queries, Mutations, and Cache

---

### 🎯 Model Answer

**30 seconds:**
> Apollo Client is the most widely used GraphQL client. It provides hooks (`useQuery`,
> `useMutation`, `useSubscription`) for React, a normalized in-memory cache keyed by
> `__typename + id`, and automatic cache updates when mutations return affected entities.
> The cache is the key differentiator: Apollo normalizes every query result, and when a
> mutation updates an entity, all queries that include that entity update automatically
> without re-fetching. Understanding the normalized cache is the core Apollo competency.

**3 minutes (Senior):**
> Apollo Client's normalized cache (InMemoryCache) stores entities as a flat key-value
> store keyed by `__typename + id` (e.g., `User:1`, `Post:42`). When a query returns
> `{ user { id name posts { id title } } }`, Apollo stores: `User:1` with `name` field
> and a list of references to `[Post:10, Post:11]`; `Post:10` with `title` field; `Post:11`
> with `title` field. Normalization means that if a mutation updates `Post:10.title`, all
> queries that include `Post:10` re-render with the new title, regardless of which query
> originally fetched that post. Cache write policies: `merge` (for lists - how do paginated
> results merge?) and `keyFields` (custom cache key for types without `id` or with
> composite keys). Cache eviction: `cache.evict({ id: 'Post:10' })` removes an entity
> and triggers re-fetch for queries that need it. Fetch policies: `cache-first` (default),
> `network-only`, `cache-and-network` (return cached data immediately then update from network).

**Blank Mind Recovery:**

**(1) Restate:** "Apollo Client: normalized InMemoryCache keyed by `__typename + id`.
Hooks: `useQuery`, `useMutation`, `useSubscription`. Key: mutation returning entity with
`id` auto-updates all queries with that entity. Fetch policies: cache-first (default),
network-only, cache-and-network. Cache problems: pagination merge policies, missing `id`
for normalization."

---

### 📘 Concept Explanation

**Apollo Client Normalized Cache Architecture:**

```text
APOLLO CLIENT NORMALIZED CACHE:

  QUERY RESULT (from server):
  {
    user: { id: "1", name: "Alice", role: "ADMIN",
      posts: [
        { id: "10", title: "First Post" },
        { id: "11", title: "Second Post" }
      ]
    }
  }

  NORMALIZED CACHE (flat store):
  ROOT_QUERY -> {
    "user({"id":"1"})": -> "User:1" (reference)
  }
  "User:1" -> {
    id: "1",
    name: "Alice",
    role: "ADMIN",
    posts: ["Post:10", "Post:11"] (references)
  }
  "Post:10" -> { id: "10", title: "First Post" }
  "Post:11" -> { id: "11", title: "Second Post" }

  MUTATION UPDATES POST:
  mutation UpdatePost($id: ID!, $title: String!) {
    updatePost(id: $id, title: $title) {
      id    <- Apollo uses this for cache key
      title <- Apollo updates this in "Post:10"
    }
  }
  
  After mutation response { id:"10", title:"New Title" }:
  Cache updates: "Post:10" -> { id:"10", title:"New Title" }
  Result: ALL queries containing "Post:10" re-render!
  No refetch needed; automatic cache update.
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Apollo Client InMemoryCache normalization process, showing how a nested query result is flattened into a key-value store and how a mutation update propagates to all queries containing the affected entity. (2) HOW TO READ IT: the top shows the raw query result (nested JSON); the middle shows the normalized cache (flat map with object references); the bottom shows the mutation update process (mutation returns `id + title`, Apollo finds `Post:10` in cache, updates `title`, re-renders all components using `Post:10`). (3) KEY RELATIONSHIP: the flat normalized cache is the mechanism for automatic cache updates; because all objects are stored once by their `id`, updating one object updates all query results that reference it. (4) EDGE CASE: if a type does not have an `id` field (or the field name is different), Apollo cannot normalize it and stores it inline; changes to that object do NOT propagate automatically; all queries that include the object must be refetched manually. (5) INSIGHT: a senior engineer designs the GraphQL schema with `id: ID!` on every entity type specifically to enable Apollo Client normalization; the `id` field is not just for querying individual entities - it is required for cache normalization to work correctly.

---

### 💻 Code Example

```javascript
// BAD: Refetching everything after a mutation
// (wasteful; ignores Apollo's cache advantages)

function PostList() {
  const { data } = useQuery(GET_POSTS);
  const [deletePost] = useMutation(DELETE_POST, {
    // BAD: refetch everything after deletion
    refetchQueries: ['GetPosts', 'GetUserStats',
                     'GetRecentActivity'],
    // Problems:
    // 1. 3 network requests after every deletion
    // 2. Stale data window during refetch
    // 3. Ignores cache for instant UI updates
    onError: (error) => console.error(error)
  });

  return (
    <ul>
      {data?.posts.map(post => (
        <li key={post.id}>
          {post.title}
          <button onClick={() => deletePost({
            variables: { id: post.id }
          })}>Delete</button>
        </li>
      ))}
    </ul>
  );
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the refetchQueries anti-pattern where a mutation triggers 3 full network refetches instead of updating the cache directly, introducing stale data windows and unnecessary network requests. (2) KEY MECHANISM: `refetchQueries: ['GetPosts', ...]` schedules new network requests after the mutation completes; during the round-trip, the UI shows stale data; with 3 refetches, there are 3 sequential round-trips before the UI is fully up to date. (3) WHY IT MATTERS: on a mobile connection with 200ms round-trip time, 3 sequential refetches after a deletion add 600ms of latency; Apollo's cache update approach provides instant UI update without any round-trip. (4) WHAT BREAKS: `refetchQueries` with active subscriptions that update the same data causes race conditions - the refetch and the subscription update may arrive in different orders; direct cache updates are deterministic. (5) TAKEAWAY: use direct cache updates (`update` function in `useMutation`) for deletions and additions to lists; use `refetchQueries` only when the updated data cannot be derived from the mutation response.

```javascript
// GOOD: Direct cache updates with Apollo

import {
  useQuery, useMutation, useApolloClient
} from '@apollo/client';

const GET_POSTS = gql`
  query GetPosts {
    posts {
      id
      title
      author { id name }
    }
  }
`;

const DELETE_POST = gql`
  mutation DeletePost($id: ID!) {
    deletePost(id: $id) {
      id    # Apollo needs ID to find and evict cache entry
    }
  }
`;

const CREATE_POST = gql`
  mutation CreatePost($input: CreatePostInput!) {
    createPost(input: $input) {
      id      # For cache normalization
      title   # New post fields
      author { id name }
    }
  }
`;

function PostList() {
  const client = useApolloClient();
  const { data, loading, error } = useQuery(GET_POSTS);

  // Delete: evict from cache directly
  const [deletePost] = useMutation(DELETE_POST, {
    update(cache, { data: { deletePost } }) {
      // Remove deleted post from all lists
      cache.evict({ id: `Post:${deletePost.id}` });
      // Clean up any dangling references
      cache.gc();
    }
    // No refetchQueries: cache handles it instantly
  });

  // Create: append to cache list directly
  const [createPost] = useMutation(CREATE_POST, {
    update(cache, { data: { createPost } }) {
      // Read current posts from cache
      const { posts } = cache.readQuery({
        query: GET_POSTS
      }) || { posts: [] };

      // Write updated posts list to cache
      cache.writeQuery({
        query: GET_POSTS,
        data: {
          posts: [...posts, createPost]
        }
      });
    }
  });

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;

  return (
    <ul>
      {data.posts.map(post => (
        <li key={post.id}>
          {post.title}
          <button onClick={() => deletePost({
            variables: { id: post.id }
          })}>Delete</button>
        </li>
      ))}
    </ul>
  );
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: direct cache updates for both deletion (cache eviction) and creation (cache write), providing instant UI updates without additional network requests. (2) KEY MECHANISM: `cache.evict({ id: 'Post:10' })` removes the entity from the normalized cache; all components querying that post are re-rendered with the post removed from the list; `cache.gc()` (garbage collection) removes any dangling references to the evicted post. (3) WHY IT MATTERS: `deletePost` completes with ONE network request (the mutation); the UI updates instantly; no additional refetch round-trips; the user sees immediate feedback. (4) WHAT BREAKS: `cache.evict` removes the entity but does not remove it from query results that hard-coded the entity's reference; `cache.gc()` must follow `evict` to clean up stale references in ROOT_QUERY. (5) TAKEAWAY: prefer direct cache updates (evict for deletions, readQuery+writeQuery for additions) over refetchQueries; direct cache updates are instant and deterministic; use refetchQueries only when you cannot determine what changed (complex server-side aggregations).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Apollo Client provides React hooks (`useQuery`, `useMutation`) for making GraphQL requests.
> It has an in-memory cache that stores query results. The cache is normalized: entities
> are stored by their type and ID (`User:1`, `Post:42`), so when a mutation updates a post,
> ALL components showing that post update automatically. For mutations, always include the
> `id` field in the response so Apollo can find and update the cache entry. Use
> `refetchQueries` when you need to force re-fetch from the server after a mutation.

---

**Senior / Staff (5+ years):**
> Apollo Client's normalized cache is its core differentiator; understanding its internals
> is essential for production use. Key areas: (1) Cache key configuration - `keyFields`
> option in `InMemoryCache` for types with non-standard IDs or composite keys. (2) Merge
> policies for lists - pagination requires explicit `merge` functions; without them, each
> page of results overwrites the previous. (3) Fetch policies - `cache-first` for stable
> data, `cache-and-network` for frequently updated data, `network-only` for always-fresh
> data. (4) Optimistic updates - `optimisticResponse` on mutations for instant UI feedback;
> Apollo rolls back to server data if the mutation fails. (5) Cache eviction and garbage
> collection - `evict()` + `gc()` for managing cache size. (6) Reactive variables - for
> local state that should trigger reactive cache reads; replaces Redux for most local state
> needs.

---

### ⚠️ Common Misconceptions

**Misconception: "Apollo Client's cache automatically handles pagination."**

Apollo Client does NOT automatically merge paginated results by default. Without a custom
merge policy, each page load OVERWRITES the previous results in the cache. If you load
page 1 (10 posts) and then page 2 (next 10 posts), the cache stores only the 10 posts
from page 2; page 1 results are gone. To implement pagination correctly with Apollo:

1. Offset pagination: define a `merge` function for the paginated field:
```javascript
const cache = new InMemoryCache({
  typePolicies: {
    Query: {
      fields: {
        posts: {
          keyArgs: ['filter', 'orderBy'],
          merge(existing = [], incoming) {
            return [...existing, ...incoming];
          }
        }
      }
    }
  }
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a custom `merge` function for a paginated `posts` field that appends new results to existing cached results instead of replacing them. (2) KEY MECHANISM: `keyArgs` specifies which arguments are part of the cache key; `filter` and `orderBy` change the result set (different cache entries); `offset` and `limit` are not in `keyArgs` (they are pagination parameters, not cache key parameters); the `merge` function receives `existing` (already cached items) and `incoming` (new page) and merges them. (3) WHY IT MATTERS: without the merge function, loading page 2 replaces page 1 in the cache; the user scrolls down, loads more, and the first 10 items disappear from the UI. (4) WHAT BREAKS: cursor-based pagination requires a more complex merge function that tracks cursors; using `[...existing, ...incoming]` for cursor pagination can lead to duplicates if the cursor is not advanced correctly. (5) TAKEAWAY: always define merge policies for paginated fields; the Relay Connection pattern (with `edges` and `pageInfo`) has built-in support in Apollo Client 3 via the `relayStylePagination()` helper function.

2. Cursor-based pagination: use `relayStylePagination()` from Apollo Client utilities
   for Relay Connection spec pagination.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Stale cache data after mutation because mutation response missing `id`.**

Symptom: mutation runs successfully, server updates data, but UI still shows old data;
a page refresh shows the updated data.
Root cause: the mutation response did not include the entity's `id` field; Apollo Client
could not find the entity in the cache to update it.

```javascript
// BAD: Mutation response missing id (cache not updated)
const UPDATE_USER_NAME = gql`
  mutation UpdateUserName($id: ID!, $name: String!) {
    updateUser(id: $id, name: $name) {
      name   # Updated field returned
      # MISSING: id field
      # Apollo cannot identify which User to update
      # in normalized cache without id
    }
  }
`;
// Result: Apollo stores the response but cannot merge
// it with the existing User in cache because
// it does not know which User this belongs to.
// The User component shows old name until page refresh.

// GOOD: Mutation response includes id for normalization
// BAD: (see above - missing id breaks cache update)
const UPDATE_USER_NAME = gql`
  mutation UpdateUserName($id: ID!, $name: String!) {
    updateUser(id: $id, name: $name) {
      id     # Required: cache key for normalization
      name   # Updated field
    }
  }
`;
// Result: Apollo finds User:${id} in cache,
// updates name field, all components with User:${id}
// re-render with new name instantly.
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the most common Apollo Client gotcha - the mutation response missing the `id` field causes Apollo to fail to normalize the response with the cached entity, resulting in stale UI. (2) KEY MECHANISM: Apollo's normalization requires `__typename` + `id` to create the cache key; without `id` in the mutation response, Apollo cannot form `User:1` as the cache key and stores the response as an unnormalized fragment without connecting it to the existing `User:1` cache entry. (3) WHY IT MATTERS: the `name` field is updated on the server; the client still shows the old name; the user thinks the mutation failed; they submit again (possibly a duplicate write); this is a UX and data integrity issue. (4) WHAT BREAKS: even if `id` is in the response, if `__typename` is not (e.g., `addTypename: false` in InMemoryCache config), normalization fails; never disable `addTypename` in production. (5) TAKEAWAY: always include `id` in every mutation response; make it a team coding standard; consider a lint rule (graphql-eslint) that enforces `id` in mutation selections.

---

### ⚖️ Comparison Table

| Approach | When to Use | Network Requests | Stale Data Risk |
|---|---|---|---|
| `cache-first` (default) | Stable data | 0 after first fetch | Medium (until refetch) |
| `network-only` | Always-fresh data | 1 per query | None |
| `cache-and-network` | Fresh but fast UI | 1 per query | None (shows cached then updates) |
| `cache.evict` + `gc()` | After deletion | 0 | None |
| `readQuery` + `writeQuery` | After creation/update | 0 | None |
| `refetchQueries` | Complex server aggregations | N (one per query) | None after refetch |
| Optimistic response | Instant feedback | 1 (mutation) | Rolled back on error |

---

### 🏛️ System Design

*(Omit: L2 keyword; cache architecture at scale covered in L5 Architecture entry.)*

---

### 📊 Diagram

```text
APOLLO CLIENT CACHE UPDATE FLOW:

  Mutation fires
    -> Server processes mutation
    -> Returns { id:"10", title:"New Title" }
          |
  Apollo Client receives mutation response
          |
  InMemoryCache.write(response)
          |
  Cache lookup: "Post:10" exists?
  YES -> Update fields: title = "New Title"
  NO  -> Create new entry "Post:10"
          |
  Reactive cache invalidation:
  Any active query/component that has a
  reactive variable pointing to "Post:10"
  is notified of change
          |
  React re-renders components:
  - PostList (if shows Post:10)
  - PostDetail (if shows Post:10)
  - UserProfile (if shows Post:10 in posts list)
  ALL update simultaneously, zero additional requests

  CACHE MISS (entity not in cache):
  Apollo follows network fetch policy to decide:
  cache-first: skip network (return null/undefined)
  network-only: fetch from network
  cache-and-network: show cached (if any), fetch network
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Apollo Client cache update flow from mutation response through InMemoryCache normalization to reactive React re-rendering. (2) HOW TO READ IT: follow the arrows from "Mutation fires" through the server round-trip to cache write to component re-render; the key is the "Reactive cache invalidation" step which triggers all affected components simultaneously. (3) KEY RELATIONSHIP: Apollo Client's reactive cache is the mechanism that connects mutations to query component re-renders; the normalized cache acts as the single source of truth; any update to a cache entry notifies all subscribers. (4) EDGE CASE: if `Post:10` is in the cache but a mutation returns new fields that are NOT in the cache (e.g., a `description` field that was never queried), Apollo adds those fields to the `Post:10` cache entry; subsequent queries requesting `description` are served from cache without a network request. (5) INSIGHT: a senior engineer designs the mutation response to return all fields that any component in the application might need after the mutation; this "fat response" pattern maximizes cache population and minimizes subsequent fetches.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | cache normalization, InMemoryCache |
| Application | 3 | mutations with cache, fetch policies, pagination |
| Trade-off | 2 | cache-first vs network-only, optimistic vs refetch |
| Scenario | 2 | stale cache debugging, pagination issues |

---

**[JUNIOR] Q1 (Definition): How does Apollo Client's normalized cache work?**

Apollo Client's InMemoryCache stores data in a normalized flat structure rather than
hierarchically (as the query result came in). Normalization means:

1. Each entity is stored once, keyed by `__typename + id` (e.g., `User:1`, `Post:42`).
2. Relationships between entities are stored as references (not nested copies).
3. Multiple queries that fetch the same entity share the same cache entry.

Process:
- Query returns: `{ user: { id:"1", name:"Alice", posts: [{id:"10", title:"A"}] } }`
- Cache stores: `User:1 = {id:"1", name:"Alice", posts: [ref(Post:10)]}` and `Post:10 = {id:"10", title:"A"}`.
- Mutation updates `Post:10.title = "B"`.
- Cache updates `Post:10 = {id:"10", title:"B"}`.
- All components that read data containing `Post:10` are re-rendered with `title:"B"`.

This works because all queries referencing `Post:10` use the same cache entry; updating
the entry once propagates to all query results.

*What separates good from great:* The `keyFields` customization. By default, Apollo uses
`id` as the cache key field. If your entity uses a different field name (e.g., `_id`
for MongoDB, or `uuid` for UUID-keyed entities) or a composite key (`organizationId +
projectId`), configure `keyFields`:
```javascript
const cache = new InMemoryCache({
  typePolicies: {
    User: { keyFields: ['uuid'] }, // Use uuid instead of id
    Project: {
      keyFields: ['organizationId', 'projectId']
    }
  }
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: configuring Apollo's InMemoryCache with custom key fields for entities that don't use standard `id` fields or that require composite keys for uniqueness. (2) KEY MECHANISM: without correct `keyFields`, Apollo either stores entities as unnormalized inline objects (no cache key) or creates incorrect cache keys that do not uniquely identify entities; both cause incorrect cache behavior. (3) WHY IT MATTERS: a project queried from the context of organization A and organization B might return different data; without composite `keyFields: ['organizationId', 'projectId']`, Apollo conflates them into one cache entry. (4) WHAT BREAKS: if `keyFields` includes a field that is not always present in query responses, Apollo falls back to un-keyed storage for that type; always include all keyFields in every query. (5) TAKEAWAY: review `keyFields` configuration as part of any new type addition to the schema; correct key fields are required for cache normalization to work.

---

**[JUNIOR] Q2 (Application): How do you implement optimistic updates in Apollo Client?**

Optimistic updates allow the UI to show the expected result of a mutation immediately,
before the server responds. If the server response differs (or the mutation fails),
Apollo reverts to the actual server response.

```javascript
const [updatePostTitle] = useMutation(UPDATE_POST_TITLE, {
  // Optimistic response: what we expect the server to return
  optimisticResponse: {
    updatePost: {
      __typename: 'Post',
      id: postId,
      title: newTitle  // Show the new title immediately
    }
  }
  // Apollo immediately updates cache with optimistic data
  // UI re-renders with new title before server responds
  // When server responds: Apollo replaces optimistic
  //   data with real server response
  // If mutation fails: Apollo reverts to pre-mutation data
});

// Usage:
updatePostTitle({
  variables: { id: postId, title: newTitle }
});
// UI shows new title immediately (optimistic)
// No loading spinner needed for the title update
```

> **Code walkthrough:** (1) WHAT IT SHOWS: an optimistic response for a post title update that causes the UI to show the new title immediately, before the server responds, providing an instant feedback experience. (2) KEY MECHANISM: `optimisticResponse` must include `__typename` (required for normalization) and `id` (for cache key); Apollo writes this to the cache immediately; when the actual server response arrives, it replaces the optimistic entry; if the mutation fails, Apollo reverts. (3) WHY IT MATTERS: without optimistic updates, the UI shows a loading state for every mutation (while waiting for the server to confirm); with optimistic updates, inline edits feel instant, improving perceived performance significantly. (4) WHAT BREAKS: optimistic data that is wrong (optimistic value differs from actual server value) causes a brief flash - the UI shows the optimistic value, then updates to the server value; for destructive mutations (delete), ensure the optimistic response is accurate to avoid UX confusion. (5) TAKEAWAY: use optimistic updates for all mutations where the expected result is predictable (title edits, status changes, like/unlike); do not use them for mutations with complex server-side logic where the result may differ significantly from the input (payment processing, multi-step workflows).

*What separates good from great:* The optimistic update failure rollback. When an
optimistic mutation fails, Apollo Client rolls back the cache to the pre-mutation state.
But if the UI has additional state changes (e.g., the component unmounted or the user
navigated away), the rollback may not be visible to the user. The error handler should
show a notification: "Update failed, original value restored." Without this notification,
the user may not realize the optimistic update was reversed; they may re-submit thinking
the first submission was lost.

---

**[SENIOR] Q3 (Application): How do you implement cursor-based pagination with Apollo Client?**

Apollo Client 3 provides `relayStylePagination()` for Relay Connection spec pagination.
For custom cursor-based pagination:

```javascript
// Cache configuration for cursor pagination
const cache = new InMemoryCache({
  typePolicies: {
    Query: {
      fields: {
        posts: {
          // keyArgs: args that define the DATASET
          // (not pagination args like cursor/limit)
          keyArgs: ['filter', 'orderBy'],

          // merge: how to combine pages
          merge(existing, incoming, { args }) {
            const existingEdges =
              existing?.edges ?? [];
            const incomingEdges =
              incoming.edges ?? [];

            // Append new page to existing
            return {
              ...incoming,
              edges: [...existingEdges, ...incomingEdges]
            };
          }
        }
      }
    }
  }
});

// Component with infinite scroll
const PAGINATED_POSTS = gql`
  query GetPosts($filter: PostFilter, $cursor: String) {
    posts(filter: $filter, first: 20, after: $cursor) {
      edges {
        cursor
        node { id title author { name } }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

function PostFeed() {
  const { data, fetchMore, loading } = useQuery(
    PAGINATED_POSTS,
    { variables: { filter: { status: 'PUBLISHED' } } }
  );

  const loadMore = () => {
    if (!data.posts.pageInfo.hasNextPage) return;
    fetchMore({
      variables: {
        cursor: data.posts.pageInfo.endCursor
      }
    });
  };

  return (
    <div>
      {data?.posts.edges.map(({ node }) => (
        <PostCard key={node.id} post={node} />
      ))}
      {data?.posts.pageInfo.hasNextPage && (
        <button onClick={loadMore}>
          Load More
        </button>
      )}
    </div>
  );
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: cursor-based pagination with Apollo Client using a custom merge policy that appends new pages to existing cached results, and `fetchMore` to load the next page using the `endCursor` from `pageInfo`. (2) KEY MECHANISM: `keyArgs: ['filter', 'orderBy']` means filter and orderBy define which dataset to cache; `after` (cursor) and `first` (page size) are NOT in keyArgs, so all pages of the same filter/orderBy share one cache entry; the merge function appends them. (3) WHY IT MATTERS: without `keyArgs`, Apollo treats each `after` cursor value as a different dataset (different cache entries); pagination is impossible; each page is isolated. (4) WHAT BREAKS: if the user changes the filter while on page 3, Apollo creates a new cache entry for the new filter; when they switch back to the original filter, Apollo shows all 3 accumulated pages from the cache (correct behavior - the paginated list is fully cached). (5) TAKEAWAY: cursor pagination with Apollo requires: `keyArgs` (dataset definition), `merge` (append pages), and `fetchMore` (load next page); using `relayStylePagination()` from `@apollo/client/utilities` handles all of this automatically for Relay Connection spec APIs.

---

**[JUNIOR] Q4 (Definition): What are Apollo Client fetch policies and when would you change the default?**

Fetch policies control where Apollo reads data from (cache, network, or both):

1. `cache-first` (default): check cache first; return cached data if available; only
   fetch from network on cache miss. Best for stable data (user profiles, product details).

2. `network-only`: always fetch from network; never use cached data; write result to
   cache for others to use. Best for frequently updated data that must be current.

3. `cache-only`: read only from cache; never fetch from network; return undefined if
   not in cache. Best for data that is always loaded by other queries first.

4. `cache-and-network`: immediately return cached data (if available); simultaneously
   fetch from network; update cache and re-render when network data arrives. Best for
   dashboards that should load fast but always show current data.

5. `no-cache`: always fetch from network; do NOT write to cache. Best for sensitive data
   (medical records, financial data) that should not be stored client-side.

Decision: use `cache-first` as the default; override to `cache-and-network` for
frequently updated data (e.g., notification counts, live order status); use `network-only`
for data that MUST be fresh (payment status, real-time inventory).

*What separates good from great:* The `cache-and-network` vs subscriptions comparison.
`cache-and-network` polls on every `useQuery` render (including re-renders), which may
cause excessive network requests. For true "live" data (updating while the user watches),
use subscriptions (WebSocket push) instead. For "fresh on mount" data (load fresh data
when the user navigates to a page), `cache-and-network` is ideal: shows cached data
instantly (no loading spinner), fetches fresh data, updates if different.

---

**[SENIOR] Q5 (Trade-off): When should you use optimistic updates vs refetchQueries?**

Optimistic updates: best for mutations where the expected result is predictable from
the mutation inputs.
- Example: `updatePostTitle(id, title)` - the post will have the new title; write it
  optimistically.
- Advantage: instant UI feedback; zero additional network requests.
- Disadvantage: wrong if the server returns a different result (server-side transformations).

`refetchQueries`: best for mutations where the server-side effects are complex and
the client cannot predict the full result.
- Example: `processOrder(orderId)` - the server may update inventory, loyalty points,
  shipping schedule; the client cannot predict all affected data.
- Advantage: always accurate (fresh from server).
- Disadvantage: N additional network requests; stale window while refetching.

Decision framework:
- Can you predict the mutation result from the input? -> Optimistic.
- Does the mutation affect data beyond what it returns? -> refetchQueries.
- Is the mutation for frequently changing data? -> Optimistic (fast UX).
- Is the mutation for financial/critical data? -> refetchQueries (accuracy over speed).

*What separates good from great:* The hybrid approach for complex mutations. `processOrder`
can use both: optimistic update for the order status (likely `PROCESSING` after submission)
AND refetchQueries for complex aggregations that change (inventory, stats). The optimistic
update provides instant order status feedback; the refetch updates the dashboard metrics
in the background. This hybrid approach combines instant feedback for the primary action
with accuracy for secondary data.

---

**[JUNIOR] Q6 (Scenario): Apollo Client shows stale data after a user is deleted. How would you debug?**

Debugging cache staleness after deletion:

Step 1 - Verify the mutation response includes `id`:
Check the DELETE mutation definition. If `id` is missing, Apollo cannot identify and
remove the cached entity.

Step 2 - Check the mutation's `update` function:
Is there a cache update function for the deletion?
```javascript
// Check: does the mutation have this pattern?
const [deleteUser] = useMutation(DELETE_USER, {
  update(cache, { data: { deleteUser } }) {
    cache.evict({ id: `User:${deleteUser.id}` });
    cache.gc();
  }
});
// If missing: the cache is not updated; stale data shown
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the diagnostic check for a deletion mutation - verifying the `update` callback exists and calls `cache.evict` + `cache.gc` to remove the deleted entity from the cache. (2) KEY MECHANISM: without the `update` function, Apollo writes the mutation response to the cache but does NOT remove the deleted entity; the `User:123` entry remains in the cache; queries listing users continue to show the deleted user until a refetch or page reload. (3) WHY IT MATTERS: the deleted user appears in the UI after deletion - the most visible cache staleness issue; without the `update` callback, the only fix is a page reload. (4) WHAT BREAKS: `cache.evict` without `cache.gc()` removes the entity reference from its own cache entry but leaves dangling references in query results that point to the now-evicted entity; `cache.gc()` removes those dangling references. (5) TAKEAWAY: every deletion mutation MUST have a cache update callback that calls `evict` + `gc`; this is the single most common Apollo Client cache bug in production.

Step 3 - Use Apollo Client DevTools:
Apollo DevTools (browser extension) shows the current cache state; inspect whether the
deleted user is still in the cache after the mutation.

Step 4 - Add cache update if missing:
Add the `update` callback with `cache.evict({ id: 'User:${id}' })` and `cache.gc()`.

*What separates good from great:* The Apollo DevTools cache inspector. Apollo DevTools'
cache tab shows the normalized cache in real time. Navigate to the cache inspector,
execute the deletion mutation, and watch whether `User:123` disappears from the cache.
If it remains, the eviction is missing. This direct observation of the cache state is
faster than code review for debugging cache issues. Apollo DevTools is a mandatory tool
for any developer working with Apollo Client.

---

**[SENIOR] Q7 (Trade-off): When is Apollo Client not the right choice for a GraphQL client?**

Apollo Client is the right choice for most React applications with GraphQL backends.
Consider alternatives when:

1. Bundle size matters critically (mobile web, low-bandwidth):
   Apollo Client + React is ~25-30KB gzipped. `urql` is ~5-7KB; `React Query` (not
   GraphQL-specific but works with GraphQL) is ~13KB. For performance-critical applications
   where the JavaScript bundle size directly impacts conversion rate, smaller clients matter.

2. Simple data fetching without complex caching:
   If your application makes GraphQL requests but does not benefit from normalized caching
   (no shared entities across queries, no mutation cache updates), `fetch` with `gql`
   template literals is sufficient. Adding Apollo for simple data fetching adds unnecessary
   complexity and bundle size.

3. Non-React frameworks (Vue, Svelte, Angular):
   Apollo has adapters for Vue and Angular but they are less maintained. `urql` has
   first-class support for Vue, Svelte, and other frameworks. For non-React projects,
   `urql` or `graphql-request` may be better choices.

4. Server-side rendering with fine-grained cache control:
   Apollo's SSR story (`getDataFromTree`, `ApolloProvider` on server) works but adds
   complexity. TanStack Query (React Query) with a GraphQL client has a simpler SSR
   story for Next.js applications.

*What separates good from great:* The Apollo vs urql normalized cache comparison.
`urql`'s Document Cache (default) is simpler than Apollo's normalized cache: it caches
by query document + variables; any mutation invalidates all cached queries that contain
the same types; automatic invalidation without custom update functions. For most
applications (where the simplicity of "any User mutation invalidates all User queries"
is acceptable), urql's document cache is simpler to work with. Apollo's normalized cache
is more powerful (fine-grained cache updates) but requires more configuration (merge
policies, eviction, update functions). Choose based on how complex your cache update
requirements are.

---

# Fragments and Colocation Pattern

---

### 🎯 Model Answer

**30 seconds:**
> GraphQL fragments are reusable selections of fields on a type. They solve the
> duplication problem: define `UserFields` once, use it in 10 queries. The colocation
> pattern (from Relay) takes this further: define the fragment in the same component that
> uses the data; the component "owns" its data requirements as a fragment; parent
> components compose child fragments into their queries. This creates a data dependency
> graph that mirrors the component tree - changes to a component's data needs require
> only changing its fragment.

**3 minutes (Senior):**
> Fragments are the primary mechanism for composing GraphQL queries in large applications.
> Two uses: (1) deduplication - write field selections once, reference in multiple queries;
> (2) colocation - define each component's data requirements as a fragment on the component
> file; parent components spread child fragments into their own queries. The colocation
> pattern enables: isolated component data requirements (a component only requests what
> it needs); automatic "over-fetching" detection (if a fragment requests unused fields,
> the component is a candidate for optimization); schema change impact analysis (if a
> field is removed from the schema, every fragment using that field is a breaking change).
> Relay's data masking feature prevents components from accessing data they did not
> explicitly request in their fragment; Apollo Client does not enforce this (components
> can read any data from the cache), but the discipline of only using data from your
> fragment is the right practice. Fragment naming convention: `ComponentName_TypeName`
> (e.g., `UserCard_User`, `PostList_Post`).

**Blank Mind Recovery:**

**(1) Restate:** "Fragment: reusable field selection. Use `fragment UserFields on User { ... }`.
Spread with `...UserFields`. Colocation: fragment defined in the component that uses it.
Component owns its data requirements. Naming: `ComponentName_TypeName`. Relay data masking:
components can only see their own fragment data."

---

### 📘 Concept Explanation

**Fragment Colocation Architecture:**

```text
COMPONENT TREE WITH COLOCATED FRAGMENTS:

  <App />
  query AppQuery {                    <- Top-level query
    viewer {                          <- Starts from root
      ...HeaderFragment               <- Header's data
      ...FeedFragment                 <- Feed's data
    }
  }
  |
  +-- <Header />
  |   fragment HeaderFragment on User {
  |     id name avatarUrl
  |   }
  |
  +-- <Feed />
      fragment FeedFragment on User {
        feed(limit: 20) {
          ...PostCardFragment         <- PostCard's data
        }
      }
      |
      +-- <PostCard post={post} />
          fragment PostCardFragment on Post {
            id title createdAt
            author { ...AvatarFragment }
            likeCount
          }
          |
          +-- <Avatar user={user} />
              fragment AvatarFragment on User {
                id name avatarUrl
              }

  ONE QUERY fetches everything needed:
  AppQuery = HeaderFragment
           + FeedFragment
           + PostCardFragment (for each post)
           + AvatarFragment (for each author)

  KEY: Component owns its data requirements.
  Change Avatar's needs? Edit AvatarFragment only.
  No other component needs to change.
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the component tree with colocated fragments showing how each component defines its data requirements as a fragment and how parent components compose child fragments into their queries. (2) HOW TO READ IT: each component is paired with its fragment; parent components include child component fragments using `...ChildFragment`; the root query includes all fragments, resulting in ONE network request for all component data. (3) KEY RELATIONSHIP: the fragment hierarchy mirrors the component hierarchy; changing `AvatarFragment` to add a `role` field affects only the Avatar component; the parent components (PostCard, Feed, App) automatically include the new field because they spread AvatarFragment. (4) EDGE CASE: deeply nested fragments increase query depth; ensure depth limiting on the server accommodates the maximum depth of the component tree. (5) INSIGHT: a senior engineer recognizes that the colocation pattern makes data requirements auditable; `PostCardFragment` documents exactly which fields PostCard uses; if the schema removes `likeCount`, only `PostCardFragment` needs updating; the scope of the breaking change is immediately clear.

---

### 💻 Code Example

```javascript
// BAD: Fragments defined separately from components
// (colocation violated; hard to maintain)

// In queries.js (centralized, far from components)
const ALL_USER_FIELDS = gql`
  fragment AllUserFields on User {
    id name email avatarUrl bio
    createdAt role isVerified followerCount
    # Many fields - some may not be needed by any component
  }
`;

// Every component uses the same mega-fragment
const GET_USER_PROFILE = gql`
  query GetUserProfile($id: ID!) {
    user(id: $id) {
      ...AllUserFields  # Fetches everything
      posts { ...AllUserFields } # Oops: posts.author
    }
  }
  ${ALL_USER_FIELDS}
`;

// UserCard only uses name and avatarUrl
// but receives all 10 fields (over-fetching)
function UserCard({ user }) {
  return (
    <div>
      <img src={user.avatarUrl} alt={user.name} />
      <span>{user.name}</span>
      {/* bio, email, role, etc. fetched but unused */}
    </div>
  );
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the centralized mega-fragment anti-pattern where a single fragment requests all possible user fields, and every component uses it regardless of how few fields they actually need - resulting in over-fetching. (2) KEY MECHANISM: `AllUserFields` fetches 10 fields; `UserCard` uses 2; the other 8 are fetched, transferred, and stored in the cache but never displayed; with 100 users on the screen, that is 800 unnecessary field values per request. (3) WHY IT MATTERS: over-fetching with a mega-fragment is not just inefficient; it couples all components to one fragment definition; adding a field to any component's needs requires adding it to `AllUserFields` (bloating it further) or creating a new fragment (undermining the DRY goal). (4) WHAT BREAKS: GraphQL servers with field-level query complexity scoring charge all 10 fields against the complexity budget even when only 2 are used; complex aggregation fields (like `followerCount`) in a mega-fragment add query cost even when the component does not display them. (5) TAKEAWAY: the mega-fragment anti-pattern defeats the purpose of GraphQL's selective fields; colocate fragments with components; each component requests exactly what it needs.

```javascript
// GOOD: Colocated fragments - each component
// owns its data requirements

// Avatar.jsx
const AVATAR_FRAGMENT = gql`
  fragment Avatar_User on User {
    id
    name
    avatarUrl
  }
`;

function Avatar({ user }) {
  return (
    <img
      src={user.avatarUrl}
      alt={user.name}
      title={user.name}
    />
  );
}
Avatar.fragment = AVATAR_FRAGMENT;

// PostCard.jsx
const POST_CARD_FRAGMENT = gql`
  fragment PostCard_Post on Post {
    id
    title
    createdAt
    likeCount
    author {
      ...Avatar_User  # Spread Avatar's fragment
    }
  }
  ${Avatar.fragment}  # Include Avatar's fragment def
`;

function PostCard({ post }) {
  return (
    <article>
      <h2>{post.title}</h2>
      <Avatar user={post.author} />
      <span>{post.likeCount} likes</span>
    </article>
  );
}
PostCard.fragment = POST_CARD_FRAGMENT;

// FeedPage.jsx - the top-level query
const GET_FEED = gql`
  query GetFeed($cursor: String) {
    feed(after: $cursor) {
      edges {
        node {
          ...PostCard_Post  # Spread PostCard's fragment
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
  ${PostCard.fragment}  # Includes Avatar_User too
`;

function FeedPage() {
  const { data } = useQuery(GET_FEED);
  return (
    <div>
      {data?.feed.edges.map(({ node }) => (
        <PostCard key={node.id} post={node} />
      ))}
    </div>
  );
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the colocated fragment pattern where each component defines its own fragment (exported as `Component.fragment`), and parent components spread child fragments into their own fragments or queries, composing the full data requirement bottom-up. (2) KEY MECHANISM: `Avatar.fragment` is defined on the `Avatar` component; `PostCard` spreads `...Avatar_User` in its fragment and includes `Avatar.fragment` in the template literal interpolation; the `GetFeed` query includes `PostCard.fragment` (which transitively includes `Avatar.fragment`); ONE query fetches all data. (3) WHY IT MATTERS: when the Avatar component needs a new field (`role`), only `AVATAR_FRAGMENT` changes; `PostCard.fragment`, `GET_FEED`, and all other components auto-include the new field because they spread `Avatar.fragment`; the change is one line in one file. (4) WHAT BREAKS: circular fragment spreading (`A spreads B, B spreads A`) causes infinite recursion in the query; GraphQL servers reject circular fragments; design the component hierarchy to be acyclic. (5) TAKEAWAY: the colocation pattern (`Component.fragment = gql\`...\``) is the best practice for large React + Apollo applications; it is the architecture Relay enforces; adopt it from the start of a project, not after the codebase grows.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Fragments are named, reusable selections of fields on a type. Define once:
> `fragment UserFields on User { id name avatarUrl }`. Use in any query: `{ user(id: "1")
> { ...UserFields } }`. They prevent duplication: if 5 queries need user fields, define
> them once in a fragment and spread it in all 5 queries. Colocation: define the fragment
> in the same file as the component that uses it. The component "owns" the fragment - it
> defines what data it needs. Parent components include child components' fragments.

---

**Senior / Staff (5+ years):**
> Fragments and colocation form the data architecture of large GraphQL applications.
> Key principles: (1) Fragment ownership - each component defines exactly the fields it
> needs; no more, no less. (2) Fragment composition - parent components compose child
> fragments; the root query is the union of all component data requirements. (3) Fragment
> naming convention - `ComponentName_TypeName` (from Relay specification) enables
> tooling to identify fragment ownership. (4) Data masking (Relay) - prevents accidental
> access to data outside a component's declared fragment; Apollo does not enforce this
> but good discipline prevents "prop drilling via cache". (5) Fragment spreading gotcha -
> when a fragment spreads another fragment, the parent must include the child fragment
> definition in the `gql` template literal; missing `${ChildComponent.fragment}` causes
> "Unknown fragment" errors at runtime. (6) `useFragment` hook (Apollo Client 3.8+) -
> reads a specific fragment from the cache without triggering a new network request;
> enables component-level cache reads aligned with colocation.

---

### ⚠️ Common Misconceptions

**Misconception: "Fragments are just for code reuse; colocation is an optional pattern."**

Fragments serve two purposes: (1) code reuse (the commonly understood purpose), and
(2) data ownership specification (the colocation pattern). The colocation pattern is not
optional in large applications; it is the only scalable approach to managing data
requirements across a component tree. Without colocation: a centralized queries file
grows to hundreds of lines; adding a field for one component requires finding the right
query in the central file; removing a field requires checking all components to see
if any still use it; schema change impact analysis is manual and error-prone. With
colocation: each component's data requirements are in the component file; schema changes
break the fragments that use the removed field; the impact is immediately visible at
the fragment definition; TypeScript type checking (via graphql-codegen with fragment
types) catches breaking schema changes at compile time for every affected component.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: "Unknown fragment" error at runtime due to missing fragment interpolation.**

Symptom: Apollo Client throws `Unknown fragment "Avatar_User"` when executing a query;
the Avatar component appears in the tree but no data is loaded.
Root cause: the parent query includes `...Avatar_User` in its selection but does not
include the `Avatar_User` fragment DEFINITION (via template literal interpolation).

```javascript
// BAD: Spread without including fragment definition
const GET_POSTS = gql`
  query GetPosts {
    posts {
      id title
      author {
        ...Avatar_User  # Spread: references fragment
        # Fragment definition NOT included below!
      }
    }
  }
  # MISSING: ${Avatar.fragment}
  # Avatar_User fragment definition is not included
`;
// Error at runtime: "Unknown fragment 'Avatar_User'"

// GOOD: Include fragment definition via interpolation
// BAD: (see above - missing fragment definition)
const GET_POSTS = gql`
  query GetPosts {
    posts {
      id title
      author {
        ...Avatar_User
      }
    }
  }
  ${Avatar.fragment}  # Include Avatar_User definition
`;
// Avatar.fragment = gql`fragment Avatar_User on User {
//   id name avatarUrl }`
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the "unknown fragment" error caused by spreading a fragment by name (`...Avatar_User`) without including the fragment definition (`${Avatar.fragment}`) in the query's `gql` template literal. (2) KEY MECHANISM: `gql` parses the entire document at load time; fragment references (spreads) must have their definitions present in the same `gql` document; `${Avatar.fragment}` interpolates the `Avatar_User` fragment definition into the document; without it, the `gql` document has a dangling reference to a non-existent fragment. (3) WHY IT MATTERS: this error is silent at development time (the component renders without data) and only throws when the query executes; without TypeScript and graphql-codegen, it may reach production. (4) WHAT BREAKS: missing transitive fragment inclusions; if `Avatar.fragment` spreads `ProfilePicture_Image` but `ProfilePicture.fragment` is not included, the same error occurs for the nested fragment. (5) TAKEAWAY: when using the colocation pattern (`Component.fragment = gql\`...\``), always interpolate `${ChildComponent.fragment}` in the parent's query or fragment; use graphql-codegen with TypeScript to catch missing fragment definitions at compile time.

---

### ⚖️ Comparison Table

| Approach | Code Organization | Over-fetching Risk | Schema Change Impact | Maintainability |
|---|---|---|---|---|
| Mega-fragment | Centralized queries file | High | Scattered changes | Poor at scale |
| Colocated fragments | Component-scoped | Low (request only needed) | Localized to fragment | Excellent |
| No fragments | Per-query full selections | Medium | All queries with the field | Poor (duplication) |
| Relay fragments + masking | Strict colocation | Minimal | Compile-time detection | Excellent |

---

### 🏛️ System Design

*(Omit: L2 keyword; fragment composition at scale covered in L5 Federation entry.)*

---

### 📊 Diagram

```text
FRAGMENT COMPOSITION FLOW:

  Component tree:
  <Page> -> <Feed> -> <PostCard> -> <Avatar>

  Fragment ownership (bottom-up definition):
  Avatar.fragment    = fragment Avatar_User on User
                       { id name avatarUrl }
  PostCard.fragment  = fragment PostCard_Post on Post
                       { id title author { ...Avatar_User } }
                       + ${Avatar.fragment}
  Feed.fragment      = fragment Feed_User on User
                       { feed { edges { node {
                           ...PostCard_Post } } } }
                       + ${PostCard.fragment}

  Page query (top-level):
  GET_PAGE = query {
    viewer {
      ...Feed_User     <- spreads whole tree
    }
  }
  + ${Feed.fragment}   <- includes PostCard (and Avatar)

  Network request: ONE query with all fragments

  TYPE-SAFE FLOW with graphql-codegen:
  Schema change: User.avatarUrl removed
  -> Avatar.fragment uses avatarUrl
  -> graphql-codegen regenerates types
  -> TypeScript: "avatarUrl does not exist on User"
  -> COMPILE ERROR in Avatar.tsx
  -> Impact: one file, immediately visible
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the bottom-up fragment composition flow from leaf component (Avatar) to root query (Page), and the TypeScript compile-time schema change impact analysis with graphql-codegen. (2) HOW TO READ IT: fragments are defined at the bottom (leaf components) and composed upward; the root query `GET_PAGE` transitively includes all fragments; `${Feed.fragment}` includes `${PostCard.fragment}` which includes `${Avatar.fragment}`. (3) KEY RELATIONSHIP: one network request at the root fetches all data for all components; the data flows DOWN through props; the fragment definitions flow UP through composition; these are opposite directions. (4) EDGE CASE: if `Avatar` is used in two different component trees (Feed and Header), both must include `Avatar.fragment`; Apollo deduplicates identical fragment definitions at parse time; no duplicate fragment definition error. (5) INSIGHT: a senior engineer combines the colocation pattern with graphql-codegen to generate TypeScript types from fragments; each component gets a TypeScript type for its fragment data; schema changes that break a fragment cause TypeScript compile errors in the exact component that uses the broken field; schema change impact analysis is automated.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | fragments, colocation pattern |
| Application | 3 | fragment composition, naming, typed fragments |
| Trade-off | 2 | colocation vs centralized, Relay masking |
| Scenario | 2 | missing fragment definition, over-fetching |

---

**[JUNIOR] Q1 (Definition): What is a GraphQL fragment and how is it used?**

A fragment is a named, reusable selection of fields on a specific type. Syntax:
`fragment FragmentName on TypeName { field1 field2 }`. Used in queries with the spread
operator: `...FragmentName`.

Purpose:
1. Reuse field selections across multiple queries without duplication.
2. Group related fields by their purpose (all user display fields vs all user contact fields).
3. Define a component's data requirements (colocation pattern).

```graphql
# Define fragment:
fragment UserCard_User on User {
  id
  name
  avatarUrl
  bio
}

# Use in multiple queries:
query GetUser($id: ID!) {
  user(id: $id) {
    ...UserCard_User
    email         # Additional field not in fragment
  }
}

query GetTeamMembers($teamId: ID!) {
  team(id: $teamId) {
    members {
      ...UserCard_User
      # Only needs UserCard fields; no email needed
    }
  }
}
# Fragment reused in two queries;
# update UserCard_User -> both queries updated
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a fragment `UserCard_User` used in two different queries, demonstrating the deduplication benefit - changing the fragment updates both queries simultaneously. (2) KEY MECHANISM: the fragment definition is parsed and inlined into the query document at `gql` parse time; the server receives the full query with all fragment fields expanded; fragments are a client-side abstraction (the server does not receive fragment syntax). (3) WHY IT MATTERS: without fragments, `UserCard` fields (`id`, `name`, `avatarUrl`, `bio`) would be written in every query that fetches user data for display; adding a new field to the user card requires finding and updating every query. (4) WHAT BREAKS: using a fragment on the wrong type (e.g., `fragment UserFields on Post`) causes a validation error; `...UserFields` can only be spread on `User` type fields. (5) TAKEAWAY: name fragments descriptively; use the `ComponentName_TypeName` convention; export fragments from component files; this makes the fragment's purpose and scope immediately clear.

*What separates good from great:* The Relay fragment mask pattern. In Relay, when
`PostCard` spreads `...Avatar_User`, `PostCard` can ONLY access the fields in
`PostCard_Post`; it CANNOT access fields from `Avatar_User` even though they are
fetched. This prevents "spooky action at a distance" where one component depends on
another component's fragment fields without declaring that dependency. Apollo Client
does not enforce this masking (any component can read any cached data), but the
discipline of only accessing data declared in your own fragment is the right practice.
Accessing data from another component's fragment is a hidden coupling that breaks when
the other component changes its fragment.

---

**[SENIOR] Q2 (Application): How do you integrate fragments with TypeScript for type-safe components?**

The graphql-codegen tool generates TypeScript types from fragment definitions. Each
fragment gets a corresponding TypeScript type.

```typescript
// 1. Define fragment with graphql-codegen

const USER_CARD_FRAGMENT = gql`
  fragment UserCard_User on User {
    id
    name
    avatarUrl
    role
  }
`;

// 2. graphql-codegen generates (auto-generated file):
// export type UserCard_UserFragment = {
//   __typename?: 'User';
//   id: string;
//   name: string;
//   avatarUrl: string;
//   role: UserRole;
// };

// 3. Import and use generated type:
import type { UserCard_UserFragment }
  from './__generated__/UserCard_User';

interface UserCardProps {
  // Typed with fragment type!
  user: UserCard_UserFragment;
}

function UserCard({ user }: UserCardProps) {
  // TypeScript knows exact shape of user:
  return (
    <div>
      <img src={user.avatarUrl} alt={user.name} />
      <span>{user.name}</span>
      <span>{user.role}</span>
      {/* user.email would be a TypeScript error:
          "Property 'email' does not exist on type
          'UserCard_UserFragment'" */}
    </div>
  );
}
UserCard.fragment = USER_CARD_FRAGMENT;
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the graphql-codegen integration that generates TypeScript types from fragment definitions, making components type-safe for their declared data requirements. (2) KEY MECHANISM: graphql-codegen reads the schema and all fragment definitions; generates TypeScript interfaces/types for each; when the schema changes (field renamed or removed), graphql-codegen regenerates the types; TypeScript compilation fails if a component accesses a removed field. (3) WHY IT MATTERS: `user.email` access in `UserCard` (which did not declare `email` in its fragment) is a TypeScript error; this enforces the data ownership principle at compile time; Relay's runtime masking equivalent, but enforced by TypeScript. (4) WHAT BREAKS: forgetting to run graphql-codegen after schema changes means TypeScript types are stale; set up graphql-codegen in watch mode during development or as a CI step to catch stale types. (5) TAKEAWAY: configure graphql-codegen for all projects using Apollo Client with TypeScript; the setup cost is one hour; the maintenance savings over the project lifetime are significant; schema changes become refactoring tasks with compile-time guidance.

*What separates good from great:* The `useFragment` hook (Apollo Client 3.8+). The
`useFragment` hook allows a component to read its specific fragment from the cache,
enabling truly isolated data access patterns. Combined with graphql-codegen types, each
component has a type-safe view into the cache for its specific fragment. This is Apollo's
approach to Relay-style data masking: each component reads only its fragment, and the
TypeScript type ensures no accidental access to other fragments' data.

---

**[JUNIOR] Q3 (Application): What is the naming convention for GraphQL fragments and why does it matter?**

The standard naming convention for colocated fragments is `ComponentName_TypeName`:

Examples:
- `UserCard_User` (UserCard component, User type)
- `PostCard_Post` (PostCard component, Post type)
- `Avatar_User` (Avatar component, User type)
- `TeamMemberList_Team` (TeamMemberList component, Team type)

Why it matters:

1. Fragment uniqueness: fragment names must be unique within a GraphQL document. If two
   components both define `UserFields`, there is a conflict. `UserCard_User` and
   `Avatar_User` are distinct names even though both are fragments on `User`.

2. Ownership identification: `UserCard_User` immediately identifies that the UserCard
   component owns this fragment; when a bug is reported on the user card display, the
   `UserCard_User` fragment is the first place to look.

3. Tooling: Relay's code generation uses `ComponentName_TypeName` as the naming convention;
   graphql-codegen follows the same convention for generated type names; Apollo DevTools
   shows fragment names in the cache inspector.

4. Grep-ability: searching the codebase for `UserCard_User` finds: the fragment definition
   (Avatar.jsx), all queries that include it, and all places the UserCard component is
   used with data.

*What separates good from great:* The uniqueness requirement is a runtime contract.
Fragment names must be globally unique within a request's document. In a project with
100 components, the probability of naming collisions increases. The `ComponentName_TypeName`
convention provides automatic uniqueness because component names are unique by convention
(two components in the same project rarely have the same name). This is a self-enforcing
uniqueness convention; without it, naming collisions cause cryptic "duplicate fragment
definition" errors.

---

**[SENIOR] Q4 (Trade-off): What are the challenges of the fragment colocation pattern in large teams?**

Challenges and mitigations:

1. Fragment composition complexity:
   Challenge: deeply nested component trees create deeply nested fragment compositions;
   forgetting `${ChildComponent.fragment}` causes runtime errors.
   Mitigation: TypeScript + graphql-codegen generates types from fragments; missing
   fragment inclusion causes TypeScript compile errors.

2. Over-spreading anti-pattern:
   Challenge: developers spread large fragments (including 10 fields) into components
   that need only 1 field; lazy spreading defeats the colocation purpose.
   Mitigation: code review; graphql-codegen field usage analysis; tools like
   `@graphql-eslint/no-unused-fragments` warn on fragments with unused fields.

3. Fragment maintenance overhead:
   Challenge: each component has a fragment; with 50 components, there are 50+ fragments
   to maintain; schema changes require updating many fragments.
   Mitigation: graphql-codegen type generation; schema changes cause TypeScript errors
   at the affected fragments; change propagation is guided by the compiler.

4. Performance: fragment spreading in queries increases query document size:
   Challenge: a query with 20 nested fragments has a large document size; POST body
   is larger.
   Mitigation: persisted queries (send query hash instead of full document); the server
   maps the hash to the pre-registered full query; client sends only the hash.

*What separates good from great:* The schema change impact analysis with fragments. When
the schema removes or renames a field, graphql-codegen regenerates types; TypeScript
reports compile errors at every fragment using the removed field. With 50 colocated
fragments, the compile errors identify exactly which components need updating and in
which file each component lives. Without fragments (queries centralized), finding all
affected queries requires grep-based searching; with colocated fragments, the TypeScript
compiler is the search tool. Fragment colocation + graphql-codegen + TypeScript = schema
change impact analysis as a compile-time process, not a manual audit.

---

**[JUNIOR] Q5 (Application): How do you use fragments with inline fragments for union and interface types?**

Inline fragments (`... on TypeName { fields }`) are used within queries to select
type-specific fields from a union or interface. Named fragments on specific types work
the same way.

```graphql
union SearchResult = User | Post | Product

fragment UserResult_User on User {
  id name email
  __typename
}

fragment PostResult_Post on Post {
  id title author { name }
  __typename
}

fragment ProductResult_Product on Product {
  id name price sku
  __typename
}

query Search($query: String!) {
  search(query: $query) {
    # Inline fragment for each type in union:
    ... on User { ...UserResult_User }
    ... on Post { ...PostResult_Post }
    ... on Product { ...ProductResult_Product }
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using named fragments combined with inline fragments to handle polymorphic union type fields in a search query, where each result type has its own fragment defining type-specific fields. (2) KEY MECHANISM: `... on User` is an inline fragment that applies only when the search result is a `User` type; `...UserResult_User` spreads the named fragment for user-specific fields; `__typename` is included in each fragment to enable client-side type discrimination. (3) WHY IT MATTERS: without inline fragments or spread fragments, accessing type-specific fields on a union return is impossible; the GraphQL engine only allows accessing fields declared in the interface (or no fields for unions without inline fragments). (4) WHAT BREAKS: forgetting `__typename` in fragments on union/interface types prevents the Apollo Client InMemoryCache from normalizing the entities correctly (it needs `__typename` + `id` for cache key formation). (5) TAKEAWAY: always include `__typename` in fragments on types that are part of a union or interface; this is required for Apollo Client cache normalization and for runtime type discrimination in components.

In React components using Apollo Client:
```typescript
// TypeScript discriminated union from graphql-codegen
type SearchResult_Fragment =
  | UserResult_UserFragment
  | PostResult_PostFragment
  | ProductResult_ProductFragment;

function SearchResultItem({
  result
}: { result: SearchResult_Fragment }) {
  // Type narrowing via __typename
  switch (result.__typename) {
    case 'User':
      return <UserCard user={result} />;
    case 'Post':
      return <PostCard post={result} />;
    case 'Product':
      return <ProductCard product={result} />;
    default:
      return null;
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: TypeScript discriminated union type for search results with `__typename` as the discriminant, allowing type-safe narrowing to the specific fragment type in each case. (2) KEY MECHANISM: graphql-codegen generates a union type for `SearchResult_Fragment` where each member has a `__typename` discriminant; TypeScript's type narrowing in the `switch` statement restricts the type to the specific fragment type in each case. (3) WHY IT MATTERS: without TypeScript type narrowing, accessing `result.email` (user-only) on a search result requires an unsafe cast; with the discriminated union, TypeScript knows inside `case 'User':` that `result` is `UserResult_UserFragment` and allows `result.email` access. (4) WHAT BREAKS: if any case branch accesses a field not in the corresponding fragment type, TypeScript reports a compile error; this is the desired behavior - it enforces that each component only uses the data it declared in its fragment. (5) TAKEAWAY: `__typename` is the key to union type handling - include it in every fragment on union/interface members; graphql-codegen uses it to generate discriminated union types; TypeScript uses it for type narrowing.

*What separates good from great:* The exhaustive switch pattern for union types. Adding
a `default` case that throws (in development) or returns null (in production) ensures
that new types added to the union are handled. In development: `default: throw new Error('Unhandled type: ' + result.__typename)` immediately alerts when a new union member is added but the component's switch statement is not updated. In production: `default: return null` gracefully handles unknown types. TypeScript's exhaustive check (`never` type assertion) catches missing cases at compile time when using the discriminated union pattern.

---

**[SENIOR] Q6 (Scenario): A component is rendering with stale data after another component updates the same entity. How do you diagnose with fragments?**

Scenario: `PostCard` updates a post title via mutation; `PostSidebar` (in a different
page section) still shows the old title even though both components display the same post.

Step 1 - Check if both components request `id` in their fragments:
```javascript
// PostCard.fragment
fragment PostCard_Post on Post {
  id          # Present
  title
  # ...
}

// PostSidebar.fragment
fragment PostSidebar_Post on Post {
  # BUG: id is missing!
  title
  viewCount
}
// Without id, Apollo cannot normalize this Post
// Apollo stores it as an inline object, not Post:10
// Mutation update to Post:10 does not affect
// PostSidebar's inline-stored copy!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the diagnosis of a stale cache bug caused by a fragment missing the `id` field, preventing Apollo from normalizing the Post and connecting it to the cache entry that the mutation updates. (2) KEY MECHANISM: Apollo normalizes `Post:10` from `PostCard.fragment` (has `id`); Apollo stores PostSidebar's post data inline (no `id`, no normalization); they are two separate cache entries; updating `Post:10` does not affect the inline entry. (3) WHY IT MATTERS: two components showing the same post with different data is a data consistency bug; users see conflicting information; this is a trust-destroying UX issue. (4) WHAT BREAKS: the bug is silent; no error in the console; the data is just different in different components; Apollo DevTools cache inspector shows `Post:10` for the normalized entry but the inline data for the un-normalized entry. (5) TAKEAWAY: every fragment must include `id` for types that should be normalized; consider a lint rule that enforces `id` in all fragments on entity types.

Step 2 - Add `id` to PostSidebar.fragment:
```javascript
fragment PostSidebar_Post on Post {
  id          # Add: enables normalization
  title
  viewCount
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: adding `id` to `PostSidebar_Post` fragment to enable Apollo normalization. (2) KEY MECHANISM: with `id` present, Apollo creates a `Post:10` cache entry for PostSidebar's data; it merges with the same `Post:10` entry from PostCard; they now share one cache entry. (3) WHY IT MATTERS: one cache entry means mutation updates to `Post:10` propagate to both components simultaneously. (4) WHAT BREAKS: the fix requires `id` to always be included in the query that uses this fragment. (5) TAKEAWAY: include `id` in every fragment on entity types; normalization depends on it.

After the fix, Apollo normalizes both components to `Post:10`; the mutation update
propagates to both.

Step 3 - Verify fix with Apollo DevTools:
In the cache inspector, after the mutation, verify that `Post:10.title` shows the new
value and both `PostCard` and `PostSidebar` re-rendered with the updated title.

*What separates good from great:* The fragment type policy in InMemoryCache. When `id`
is present in a fragment but Apollo is still not normalizing correctly, check the
`typePolicies` configuration. If the type has a custom `keyFields` configuration
that differs from `id`, fragments must include the custom key field. For example,
if `Post` uses `keyFields: ['uuid']`, the fragment must include `uuid`, not `id`.
The Apollo DevTools cache inspector reveals whether entries are normalized (shown as
`Post:uuid-value`) or inline (shown as inline objects within the parent entry).

---

**[JUNIOR] Q7 (Application): How do you avoid duplicate fragment declarations when a fragment is used in multiple files?**

The problem: `Avatar.fragment` is needed in multiple parent components; importing from
the Avatar component file ensures only one definition.

Solution: export fragment from the component file and import it everywhere needed:
```javascript
// Avatar.jsx
export const AVATAR_FRAGMENT = gql`
  fragment Avatar_User on User {
    id name avatarUrl
  }
`;
function Avatar({ user }) { /* ... */ }
export default Avatar;

// PostCard.jsx
import { AVATAR_FRAGMENT } from './Avatar';
const POST_CARD_FRAGMENT = gql`
  fragment PostCard_Post on Post {
    id title
    author { ...Avatar_User }
  }
  ${AVATAR_FRAGMENT}  # Include definition once
`;

// ProfilePage.jsx
import { AVATAR_FRAGMENT } from './Avatar';
const PROFILE_QUERY = gql`
  query GetProfile($id: ID!) {
    user(id: $id) {
      ...Avatar_User
      bio createdAt
    }
  }
  ${AVATAR_FRAGMENT}  # Same import, no duplication
`;
```

> **Code walkthrough:** (1) WHAT IT SHOWS: exporting the fragment from the Avatar component and importing it in PostCard and ProfilePage, ensuring one source of truth for the fragment definition. (2) KEY MECHANISM: `gql` parses the template literal at module load time; `${AVATAR_FRAGMENT}` interpolates the fragment definition inline; when PostCard and ProfilePage both include `${AVATAR_FRAGMENT}`, Apollo Client deduplicates identical fragment definitions automatically; no "duplicate fragment" errors. (3) WHY IT MATTERS: without a single export, the `Avatar_User` fragment might be defined differently in PostCard.jsx and ProfilePage.jsx (one uses `id name avatarUrl`, the other forgets `id`); duplicate inconsistent definitions cause subtle bugs. (4) WHAT BREAKS: circular imports (PostCard imports Avatar, Avatar imports PostCard) cause webpack module resolution errors; design the component hierarchy to be acyclic - leaf components should not import parent components. (5) TAKEAWAY: the `Component.fragment = gql\`...\`` pattern with explicit export is the standard; one fragment definition, one source of truth, imported wherever needed.

*What separates good from great:* The `fragmentMatcher` for interface and union types.
Apollo Client needs to know which types implement which interfaces to correctly normalize
union and interface query results. By default, Apollo 3 uses the `possibleTypes` option
in `InMemoryCache` configuration:
```javascript
const cache = new InMemoryCache({
  possibleTypes: {
    SearchResult: ['User', 'Post', 'Product'],
    Node: ['User', 'Post', 'Product', 'Order']
  }
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: configuring `possibleTypes` in Apollo's InMemoryCache so the cache knows which concrete types implement each interface or union. (2) KEY MECHANISM: without `possibleTypes`, Apollo cannot determine that a `SearchResult` field might be a `User` or `Post`; it cannot normalize them correctly. (3) WHY IT MATTERS: missing `possibleTypes` causes union/interface type query results to be stored incorrectly; conditional fragments may not render. (4) WHAT BREAKS: adding a new type to a union without updating `possibleTypes` causes that type to be unnormalized. (5) TAKEAWAY: auto-generate `possibleTypes` with graphql-codegen; never maintain it manually.

Without `possibleTypes`, Apollo cannot normalize interface and union type results correctly.
`possibleTypes` is auto-generated by `graphql-codegen` from the schema introspection.
Update it when the schema adds new types to a union or interface.
