---
layout: default
title: "GraphQL - L3 Real-time"
parent: "GraphQL"
nav_order: 8
permalink: /graphql/l3-real-time/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 18 | [GraphQL Subscriptions with WebSocket](#graphql-subscriptions-with-websocket) | ★★☆ |
| 19 | [Server-Sent Events as Subscription Alternative](#server-sent-events-as-subscription-alternative) | ★★☆ |

---

# GraphQL Subscriptions with WebSocket

---

### 🎯 Model Answer

**30 seconds:**
> GraphQL subscriptions enable real-time data from server to client. They use the
> `graphql-ws` protocol over WebSockets. A client sends a `subscribe` operation; the
> server pushes data whenever an event occurs. The server uses an async iterator
> (PubSub pattern) to emit events: mutations publish to a topic; subscribers receive
> events on that topic. Key concern: subscriptions are long-lived WebSocket connections
> that consume server memory; scale requires distributed PubSub (Redis).

**3 minutes (Senior):**
> Subscriptions are fundamentally different from queries and mutations: they are
> long-lived connections, not request-response. The protocol is `graphql-ws`
> (NOT the deprecated `subscriptions-transport-ws`). The server side: subscriptions
> are defined as async generators or use PubSub; Apollo Server uses `graphql-ws`
> and `ws` library; the subscription resolver returns an AsyncIterator (via
> `pubsub.asyncIterator('TOPIC')`). The client side: Apollo Client uses
> `GraphQLWsLink` to connect; subscription results flow into the cache. Production
> concerns: (1) Connection memory - each WebSocket connection consumes server memory;
> 10,000 concurrent subscriptions require horizontal scaling; use sticky sessions or
> Redis PubSub. (2) Subscription filtering - broadcast events only to clients that
> need them (filter by subscription argument); avoid broadcast storms. (3)
> Authentication - WebSocket connections authenticate at the connection protocol level
> (not per message); the initial `connection_init` payload carries the auth token. (4)
> Scalability - Redis PubSub for multi-server setups; without it, a subscription to a
> mutation handled by server B receives no events when server A handles the mutation.

**Blank Mind Recovery:**

**(1) Restate:** "Subscriptions = long-lived WebSocket connections. Protocol: `graphql-ws`.
Server: `pubsub.asyncIterator('TOPIC')` in subscribe resolver. Client: `GraphQLWsLink`.
Mutation triggers: `pubsub.publish('TOPIC', { data })`. Auth in connection_init. Scale:
Redis PubSub for multi-server. Filter events per subscription with `withFilter`."

---

### 📘 Concept Explanation

**Subscription Architecture and PubSub Pattern:**

```text
SUBSCRIPTION FLOW:

Client                      Server
  |                           |
  |--subscribe operation----->|
  |  { subscription {         |
  |    messageAdded { text } }}|
  |                           |
  |   WebSocket connection     |
  |   (long-lived, persistent) |
  |                           |
  |         [other client or UI event]
  |                           |
  |   mutation sendMessage     |
  |   (separate HTTP or WS)   |
  |                           |-> pubsub.publish(
  |                           |     'MESSAGE_ADDED',
  |                           |     { messageAdded: msg }
  |                           |   )
  |                           |
  |<-- Next() from AsyncIter--|
  |  { data: {                |
  |    messageAdded: {text}}} |
  |                           |
  |<-- Next() on next event---|
  |                           |

PUBSUB PATTERN:
  Subscriber 1 ---\
  Subscriber 2 ----> Topic: 'MESSAGE_ADDED'
  Subscriber 3 ---/      |
                    pubsub.publish() triggers all
                    subscribed AsyncIterators
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the subscription flow from client subscription setup through server WebSocket maintenance, mutation-triggered publish, and event delivery back to the client. (2) HOW TO READ IT: the horizontal swim lanes show client and server actions over time; the initial subscribe operation creates the WebSocket; subsequent `publish` events trigger data delivery; the connection persists until the client unsubscribes or disconnects. (3) KEY RELATIONSHIP: the `mutation -> pubsub.publish` is decoupled from the subscription connection; mutations handle publication (event production) independently of how many subscribers exist. (4) EDGE CASE: if `pubsub.publish` happens when no clients are subscribed to the topic, the event is dropped - this is fine and expected; events are not queued for future subscribers. (5) INSIGHT: a senior engineer recognizes that in-memory PubSub (default) fails silently when the API is horizontally scaled: client subscribes on Server A, mutation runs on Server B - `pubsub.publish` on Server B does not reach Server A's subscribers; Redis PubSub is mandatory for multi-instance deployments.

---

### 💻 Code Example

```javascript
// BAD: Using deprecated subscriptions-transport-ws
// and in-memory PubSub in production multi-server setup

const { PubSub } = require('graphql-subscriptions');

// BAD: In-memory PubSub - fails at scale!
const pubsub = new PubSub();
// Singleton: only works on a single server process
// Scale to 2 servers: subscriber on S1 misses events
// published from S2

// BAD: subscriptions-transport-ws (deprecated 2021)
const { SubscriptionServer } = require(
  'subscriptions-transport-ws'
);
SubscriptionServer.create(
  { schema, execute, subscribe },
  { server: httpServer, path: '/graphql' }
);
// Deprecated; many clients have stopped supporting it
// Known issues with reconnection and error handling
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two anti-patterns in one: using the deprecated `subscriptions-transport-ws` protocol library and in-memory PubSub that only works on a single server. (2) KEY MECHANISM: `subscriptions-transport-ws` was the original WebSocket protocol for GraphQL; it was deprecated in 2021 in favor of `graphql-ws`; the client library `@apollo/client` dropped it; mixing old and new causes silent connection failures. (3) WHY IT MATTERS: in-memory PubSub creates a critical production bug: horizontal scaling distributes clients and mutations across servers; mutations publish to the local in-memory store; subscribers on other servers never receive events. (4) WHAT BREAKS: the bug is invisible in development (single server); it appears in production under load when auto-scaling adds instances; difficult to diagnose because some clients receive events and others do not. (5) TAKEAWAY: always use `graphql-ws` (not `subscriptions-transport-ws`); always use Redis PubSub (not in-memory) for any production deployment that may run more than one server instance.

```javascript
// GOOD: graphql-ws + Redis PubSub for production

const { createServer } = require('http');
const { makeExecutableSchema } = require(
  '@graphql-tools/schema'
);
const { WebSocketServer } = require('ws');
const { useServer } = require('graphql-ws/lib/use/ws');
const { RedisPubSub } = require(
  'graphql-redis-subscriptions'
);
const Redis = require('ioredis');

// GOOD: Redis PubSub - works across multiple servers
const publisher = new Redis({ host: 'redis', port: 6379 });
const subscriber = new Redis({ host: 'redis', port: 6379 });
const pubsub = new RedisPubSub({
  publisher,
  subscriber
  // All server instances share the same Redis topic;
  // any server's publish() reaches all subscribers
  // regardless of which server they connected to
});

const typeDefs = `
  type Message {
    id: ID!
    text: String!
    author: String!
  }

  type Query { messages: [Message!]! }

  type Mutation {
    sendMessage(text: String!, author: String!): Message!
  }

  type Subscription {
    messageAdded: Message!
    messageAddedByAuthor(author: String!): Message!
  }
`;

const resolvers = {
  Mutation: {
    sendMessage: async (_, { text, author }, { db }) => {
      const msg = await db.createMessage({ text, author });
      await pubsub.publish('MESSAGE_ADDED', {
        messageAdded: msg
      });
      return msg;
    }
  },
  Subscription: {
    messageAdded: {
      // Subscribe: returns AsyncIterator for the topic
      subscribe: () =>
        pubsub.asyncIterator(['MESSAGE_ADDED'])
    },
    messageAddedByAuthor: {
      // Filter: only send events matching subscription args
      subscribe: withFilter(
        () => pubsub.asyncIterator(['MESSAGE_ADDED']),
        (payload, variables) =>
          payload.messageAdded.author === variables.author
      )
    }
  }
};

const schema = makeExecutableSchema(
  { typeDefs, resolvers }
);

const httpServer = createServer(app);

// WebSocket server using graphql-ws protocol:
const wsServer = new WebSocketServer({
  server: httpServer,
  path: '/graphql'
});

useServer({
  schema,
  // Authentication in WebSocket context:
  context: async (ctx) => {
    const token = ctx.connectionParams?.authorization;
    const user = token ? verifyJWT(token) : null;
    return { user, db, pubsub };
    // context called per subscription message
    // NOT per connection (unlike HTTP context)
  },
  onConnect: async (ctx) => {
    const token = ctx.connectionParams?.authorization;
    if (isBlacklisted(token)) {
      return false;  // Reject connection
    }
    return true;
  }
}, wsServer);

httpServer.listen(4000);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a complete production-ready subscription setup with `graphql-ws`, Redis PubSub, per-author event filtering, and WebSocket authentication via `connectionParams`. (2) KEY MECHANISM: `useServer({ schema, context }, wsServer)` integrates `graphql-ws` with the Node.js `ws` library; `RedisPubSub` uses two Redis connections (publisher and subscriber) so that publishing on any server instance propagates to all subscribers across all server instances via Redis pub/sub channels. (3) WHY IT MATTERS: `withFilter` prevents broadcast storms - without it, `messageAddedByAuthor(author: "Alice")` receives events for ALL authors and must filter on the client; with it, only events where `payload.messageAdded.author === variables.author` are delivered. (4) WHAT BREAKS: WebSocket `context` is called per-message (not per-connection); if context fetches data from a database, it runs for every event delivered to every subscriber; use connection-level caching (`ctx.extra`) for user data that does not change per-message. (5) TAKEAWAY: the critical production trio: `graphql-ws` (protocol), Redis PubSub (multi-server), `withFilter` (event targeting); missing any one creates a correctness or scalability issue.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> GraphQL subscriptions use WebSockets to push real-time data from server to client.
> The server uses PubSub: mutations call `pubsub.publish('TOPIC', { data })`; the
> subscription resolver returns `pubsub.asyncIterator('TOPIC')` which receives published
> events. The client uses `GraphQLWsLink` and the `useSubscription` hook. For production
> multi-server deployments, use Redis PubSub instead of in-memory PubSub to ensure
> events reach subscribers regardless of which server instance handles the mutation.

---

**Senior / Staff (5+ years):**
> Production subscription design requires: (1) `graphql-ws` protocol (deprecated
> `subscriptions-transport-ws` causes reconnection issues). (2) Redis PubSub for
> horizontal scaling - mandatory for any multi-instance deployment. (3) `withFilter`
> to prevent broadcast storms - filtering server-side reduces unnecessary network traffic.
> (4) Authentication at the WebSocket connection level via `connectionParams` - the
> `Authorization` header cannot be set on WebSocket connections in browsers; use
> `connectionParams` passed in the `GraphQLWsLink` options. (5) Connection limiting -
> each WebSocket connection consumes server memory (50-200KB per connection); 10,000
> concurrent connections require monitoring and connection pool management. (6) Heartbeat
> - WebSocket connections silently die behind load balancers and NAT gateways; configure
> `ping_interval` to detect dead connections and reclaim memory.

---

### ⚠️ Common Misconceptions

**Misconception: "Subscriptions are just long-polling implemented as WebSockets."**

Subscriptions and long-polling are architecturally different. Long-polling: client sends
HTTP request; server holds the request open until data is available or timeout; client
immediately sends another request. WebSocket subscriptions: client opens one persistent
bidirectional connection; server pushes events as they occur; no polling loop. The
practical differences: (1) Connection overhead - long-polling creates a new HTTP request
per event (new TLS handshake, new headers, new load balancer routing); WebSocket creates
one connection and reuses it for all events. (2) Latency - long-polling has minimum
latency equal to one HTTP round-trip; WebSocket push has minimal latency (data is
pushed as soon as available). (3) Server capacity - long-polling with 1000 clients and
10 events/second = 10,000 HTTP requests/second; WebSocket with 1000 clients and 10
events/second = 10,000 messages/second on persistent connections (much lower overhead).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Subscriptions stop receiving events after server restart or scaling.**

Symptom: client reports receiving initial events but events stop after ~1 hour.
Server logs show connections being established but no events delivered.

Root cause: in-memory PubSub does not survive process restarts; when the server
restarts, all active subscriptions are dropped; clients must re-subscribe; if the client
does not handle reconnection, subscriptions are permanently lost.

```javascript
// BAD: No reconnection handling in client
// subscription stops receiving events after server restart
const link = new GraphQLWsLink(createClient({
  url: 'ws://localhost:4000/graphql'
  // Default: no reconnect configuration
  // Server restart -> client stops receiving events
}));

// GOOD: Reconnection and re-subscription handling
// BAD: (see above - reconnect not configured)
const link = new GraphQLWsLink(createClient({
  url: 'ws://localhost:4000/graphql',
  retryAttempts: Infinity,  // Keep retrying forever
  connectionParams: () => ({
    authorization: localStorage.getItem('token')
    // Function: called on each reconnection attempt
    // Refreshes token if it expired during disconnect
  }),
  on: {
    connected: () => console.log('WS connected'),
    closed: () => console.log('WS closed - reconnecting'),
    error: (err) => console.error('WS error', err)
  },
  // Exponential backoff between retry attempts:
  retryWait: async (retries) => {
    await new Promise(resolve =>
      setTimeout(resolve, Math.min(
        1000 * Math.pow(2, retries), 30000
      ))
    );
  }
}));
```

> **Code walkthrough:** (1) WHAT IT SHOWS: WebSocket reconnection configuration for production resilience - `retryAttempts: Infinity` and exponential backoff ensure the client reconnects after server restarts. (2) KEY MECHANISM: `graphql-ws` client retries on connection close; `retryWait` adds delay between attempts; exponential backoff (1s, 2s, 4s... capped at 30s) prevents thundering herd when many clients reconnect simultaneously after a server restart. (3) WHY IT MATTERS: without reconnection, a server restart (deployment, crash, auto-scale down) silently disconnects all subscription clients; they continue rendering the last received value without realizing the subscription is dead. (4) WHAT BREAKS: `connectionParams: () => ...` as a function is critical; if it is a plain object, the token is captured at startup; after a token expiry and server reconnect, the old expired token is sent; using a function re-evaluates the token on each reconnect attempt. (5) TAKEAWAY: always configure `retryAttempts: Infinity` and `retryWait` exponential backoff in production WebSocket clients; subscription clients must be resilient to server restarts.

---

### ⚖️ Comparison Table

| Aspect | In-memory PubSub | Redis PubSub |
|---|---|---|
| Multi-server | No (single instance only) | Yes (all instances share) |
| Setup complexity | None (zero config) | Redis connection config |
| Event persistence | No (events dropped on restart) | No (still not persistent) |
| Latency overhead | None | ~1ms Redis round-trip |
| Best for | Development, single-instance | Production, multi-instance |

---

### 🏛️ System Design

*(Omit: L3 keyword; subscription scaling, backpressure, and event sourcing architecture covered in L5 Architecture entry.)*

---

### 📊 Diagram

```text
REDIS PUBSUB - MULTI-SERVER SUBSCRIPTION:

  Server A                    Redis
  Clients: [C1, C2]              |
  Subscribe to 'MSG_ADDED'       |
    -> Redis SUBSCRIBE channel   |
                                 |
  Server B                     Redis channel:
  Handles mutation:             'MSG_ADDED'
  pubsub.publish('MSG_ADDED')  -> broadcasts to
    -> Redis PUBLISH channel      all Redis
                                  SUBSCRIBE
                                  connections
  Server A receives:
  Redis -> asyncIterator next()
  C1 and C2 receive the event

  WITHOUT REDIS (in-memory):
  Server A: C1 waits for events
  Server B: mutation publishes
            to in-memory store
            (local to Server B)
  Server A: NEVER receives event
  C1: No update (silent failure)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Redis PubSub architecture enabling subscriptions across multiple server instances - Server A's subscribers receive events from mutations handled by Server B via Redis as the shared message bus. (2) HOW TO READ IT: Server A subscribes to the Redis channel when the first client subscribes; Server B publishes to Redis when a mutation fires; Redis broadcasts to all subscribers including Server A; Server A's asyncIterator delivers the event to clients C1 and C2. (3) KEY RELATIONSHIP: Redis is the decoupling layer between mutation handlers (producers) and subscription servers (consumers); without Redis, producers and consumers must be on the same process. (4) EDGE CASE: if Redis goes down, all subscriptions stop receiving events; clients see stale data without error; implement Redis connection monitoring and client-visible "connection health" status in the subscription response. (5) INSIGHT: a senior engineer uses Redis Sentinel or Redis Cluster for PubSub in production; a single Redis instance is a single point of failure; Sentinel provides automatic failover for the PubSub message bus.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | protocol, async iterator |
| Application | 2 | server setup, filtering |
| Architecture | 2 | Redis PubSub, multi-server |
| Scenario | 2 | auth, reconnection |

---

**[JUNIOR] Q1 (Definition): What is the `graphql-ws` protocol and why was `subscriptions-transport-ws` deprecated?**

`graphql-ws` is the modern WebSocket sub-protocol for GraphQL subscriptions. It defines
the message types exchanged between client and server:
- `connection_init` (client to server, with auth payload)
- `subscribe` (client starts a subscription operation)
- `next` (server sends an event to the client)
- `error` (server reports an error)
- `complete` (client or server ends the subscription)

`subscriptions-transport-ws` was the original WebSocket library for GraphQL subscriptions
(pre-2021). It was deprecated because: (1) it had reconnection bugs - clients sometimes
fail to re-subscribe after reconnection; (2) it does not support graceful subscription
completion; (3) its client (`SubscriptionClient`) was bundled with Apollo Client but had
to be maintained by the community; (4) `graphql-ws` (by Denis Badurina) was designed
from scratch with lessons learned and a cleaner protocol.

Migration: `graphql-ws` uses `new WebSocketServer` (the `ws` library) + `useServer`;
`subscriptions-transport-ws` used `SubscriptionServer.create`. Apollo Client migrated
from `WebSocketLink` to `GraphQLWsLink`.

*What separates good from great:* The sub-protocol negotiation. The WebSocket handshake
includes a `Sec-WebSocket-Protocol` header. `graphql-ws` uses `graphql-transport-ws`;
`subscriptions-transport-ws` used `graphql-ws` (confusingly different from the library
name). If a client using the new library connects to a server using the old library
(or vice versa), the sub-protocol negotiation fails and the WebSocket connection is
rejected. Check the `Sec-WebSocket-Protocol` header in browser dev tools when debugging
subscription connection failures.

---

**[JUNIOR] Q2 (Application): How do you filter subscription events server-side in GraphQL?**

Use `withFilter` from `graphql-subscriptions` to prevent delivering events to clients
that did not subscribe to them:

```javascript
const { withFilter } = require('graphql-subscriptions');

const resolvers = {
  Subscription: {
    // Without filter: ALL commentAdded events
    // delivered to ALL subscribers regardless of
    // which postId they subscribed to
    commentAdded: {
      subscribe: withFilter(
        () => pubsub.asyncIterator(['COMMENT_ADDED']),
        (payload, variables) => {
          // Return true: deliver event to this subscriber
          // Return false: skip this subscriber
          return (
            payload.commentAdded.postId ===
            variables.postId
          );
        }
      )
    }
  }
};
// Client subscribes with:
// subscription { commentAdded(postId: "123") { text } }
// Only receives events where payload.postId === "123"
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `withFilter` wrapping the `asyncIterator` to filter events per subscriber based on the subscription variables (the `postId` argument). (2) KEY MECHANISM: `withFilter` creates a new AsyncIterator that calls the filter function for each event; if the filter returns false for a subscriber, the event is not delivered to that subscriber; the underlying Redis PubSub still receives the event. (3) WHY IT MATTERS: without `withFilter`, a client subscribed to comments on post 123 receives events for comments on ALL posts; this is both incorrect data delivery and unnecessary network traffic. (4) WHAT BREAKS: if the filter function throws an exception, the subscription may silently stop receiving events; wrap filter logic in try/catch; return false on error rather than letting the error propagate. (5) TAKEAWAY: every subscription that accepts arguments should use `withFilter` to match events to subscribers; server-side filtering is more efficient than client-side filtering because it prevents unnecessary network delivery.

*What separates good from great:* Filter function performance. The `withFilter` function
is called ONCE PER EVENT PER SUBSCRIBER. With 10,000 subscribers and 100 events/second,
the filter function runs 1,000,000 times/second. Keep filter logic O(1): compare IDs,
check set membership. Never do database lookups in the filter function. For complex
authorization in subscription filters (user can only see events they have permission for),
cache permission data in the WebSocket context (loaded once at `onConnect`) and reference
the cache in the filter.

---

**[SENIOR] Q3 (Architecture): How does Redis PubSub enable subscriptions at scale?**

Redis PubSub uses Redis's native PUBLISH/SUBSCRIBE commands as the message bus:

When a client subscribes: the server calls `pubsub.asyncIterator(['TOPIC'])`. `RedisPubSub`
calls Redis `SUBSCRIBE topic`. Redis tracks all active SUBSCRIBE listeners across all
connected servers.

When a mutation fires: the server calls `pubsub.publish('TOPIC', payload)`. `RedisPubSub`
calls Redis `PUBLISH topic serialized_payload`. Redis broadcasts the message to ALL servers
that have called `SUBSCRIBE topic`. Each server's `asyncIterator` receives the event
and delivers it to its local subscribers.

```javascript
// Setup: RedisPubSub with connection pooling
const pubsub = new RedisPubSub({
  publisher: new Redis(redisConfig),
  subscriber: new Redis(redisConfig),
  // Two connections: Redis spec requires separate
  // connections for PUBLISH and SUBSCRIBE
  // Cannot use same connection for both
});

// Publisher (in Mutation resolver):
await pubsub.publish('ORDER_UPDATED', {
  orderUpdated: { id, status, updatedAt }
});
// -> Redis PUBLISH order_updated '{"id":...}'
// -> All subscribed servers receive message
// -> Each server delivers to matching subscriptions

// Subscriber (in Subscription resolver):
subscribe: withFilter(
  () => pubsub.asyncIterator(['ORDER_UPDATED']),
  (payload, { orderId }) =>
    payload.orderUpdated.id === orderId
)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `RedisPubSub` configuration with separate publisher and subscriber Redis connections (required by Redis protocol) and the flow from mutation publish to cross-server event delivery. (2) KEY MECHANISM: Redis PUBLISH/SUBSCRIBE is at-most-once delivery (fire-and-forget); events are not persisted; if a subscriber is temporarily disconnected, events during that window are lost; this is by design for real-time use cases. (3) WHY IT MATTERS: all server instances connect to the same Redis; mutations on any server instance publish to Redis; all server instances receive the event and deliver to their local WebSocket subscribers; the net effect is as if all servers share one PubSub bus. (4) WHAT BREAKS: serialization performance - `RedisPubSub` serializes payloads to JSON for Redis; large payloads (full document objects) serialize/deserialize on every event; use event IDs and let resolvers fetch data instead of putting full documents in events. (5) TAKEAWAY: Redis PubSub requires two connections per server instance (publisher + subscriber); this is a Redis protocol requirement; do not reuse one connection for both; use connection pooling for publisher connections under high mutation load.

---

**[JUNIOR] Q4 (Application): How do you authenticate WebSocket subscriptions?**

Browser WebSocket connections cannot set custom HTTP headers (a browser limitation).
Use `connectionParams` instead:

```javascript
// Client (Apollo Client):
import { createClient } from 'graphql-ws';

const wsClient = createClient({
  url: 'wss://api.example.com/graphql',
  connectionParams: () => ({
    // Sent as JSON in the connection_init message
    // Not an HTTP header!
    authorization: `Bearer ${getToken()}`
  })
  // connectionParams as a function: re-evaluated
  // on each reconnect; picks up refreshed tokens
});

// Server (graphql-ws useServer):
useServer({
  schema,
  context: async (ctx) => {
    // ctx.connectionParams contains the client's
    // connection_init payload
    const token = ctx.connectionParams?.authorization
      ?.replace('Bearer ', '');
    let user = null;
    if (token) {
      user = verifyJWT(token);
    }
    // user is available in all subscription resolvers
    return { user, db };
  },
  onConnect: async (ctx) => {
    const token = ctx.connectionParams?.authorization;
    if (!token) {
      return false;  // Reject unauthenticated connections
      // Client receives: "Unauthorized"
    }
    try {
      verifyJWT(token.replace('Bearer ', ''));
      return true;  // Accept connection
    } catch (err) {
      return false;  // Reject invalid token
    }
  }
}, wsServer);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: WebSocket authentication using `connectionParams` on the client and `ctx.connectionParams` on the server - the only way to send authentication data for WebSocket connections in browsers. (2) KEY MECHANISM: `connectionParams` is sent in the `connection_init` protocol message; the server's `onConnect` handler receives it and can reject the connection (return false) before any subscription operations; `context` is also called and populates the subscription resolver context. (3) WHY IT MATTERS: WebSocket connections are long-lived; a compromised token or revoked user should be detected at the connection level; `onConnect` allows early rejection; polling the token validity on each event delivery is too expensive. (4) WHAT BREAKS: `connectionParams` as a plain object (not a function) captures the token at startup; if the JWT expires and is refreshed, the WebSocket client continues to send the old expired token on reconnect; use a function to re-evaluate the token. (5) TAKEAWAY: `connectionParams: () => ({ authorization: getToken() })` - always a function, never a plain object; `onConnect` validates the token once per connection; `context` makes the decoded user available per message.

---

**[SENIOR] Q5 (Architecture): What are the memory and connection management concerns for subscriptions at scale?**

Each WebSocket connection on Node.js consumes approximately 50-200KB of heap memory
depending on: the amount of data buffered per connection, the size of the resolver context
stored per connection, and the number of active subscriptions per connection.

```text
Scale math for 10,000 concurrent subscribers:
  Memory: 10,000 * 150KB = ~1.5GB heap
  -> Requires servers with 4GB+ RAM for margin
  -> 2-3 server instances for redundancy

  Events: 100 events/second * 10,000 subscribers
  -> withFilter: 1,000,000 filter calls/second
  -> Keep filter O(1) and synchronous

  Redis: 100 publishes/second
  -> Each publish: Redis PUBLISH (< 1ms)
  -> 10,000 subscriber deliveries/second
  -> Redis handles this easily; monitor memory
```

> **Code walkthrough:** (1) WHAT IT SHOWS: back-of-envelope calculations for WebSocket subscription infrastructure sizing at 10,000 concurrent connections. (2) KEY MECHANISM: each WebSocket connection stores: the context object (user, db handles), active subscription iterators, and buffered but not yet ACKed messages; 150KB is typical; context size is the main variable. (3) WHY IT MATTERS: underestimating WebSocket memory leads to OOM kills on auto-scaled instances; subscription servers should be profiled under load before production. (4) WHAT BREAKS: keeping large objects in the subscription context (full user profile, all user permissions) multiplies memory usage by the number of connections; store only the minimum needed (user ID, roles). (5) TAKEAWAY: subscription server sizing is dominated by connection count; memory is the constraint, not CPU; right-size by measuring context memory per connection and calculating max connections per server with 50% headroom.

Connection lifecycle management:
- `onConnect`: validate auth, reject unauthenticated connections, track connection count.
- `onDisconnect`: clean up per-connection state, decrement connection counter, log disconnect duration.
- Heartbeat: configure `keepAlive` in `useServer` to detect dead connections.

---

**[JUNIOR] Q6 (Application): How do you unsubscribe and handle subscription cleanup?**

```javascript
// Apollo Client: clean up subscription
const { data, loading } = useSubscription(
  MESSAGE_SUBSCRIPTION,
  {
    onSubscriptionData: ({ subscriptionData }) => {
      // Handle each event
    },
    onSubscriptionComplete: () => {
      console.log('Subscription complete');
    }
  }
);
// useSubscription automatically unsubscribes when
// the component unmounts (React effect cleanup)

// Manual subscription cleanup:
const observable = client.subscribe({
  query: MESSAGE_SUBSCRIPTION
});
const sub = observable.subscribe({
  next: (data) => handleEvent(data),
  error: (err) => handleError(err),
  complete: () => console.log('done')
});

// Call sub.unsubscribe() to stop receiving events
// This sends a 'complete' message over the WebSocket
// Server stops the AsyncIterator for this subscription

return () => sub.unsubscribe(); // cleanup
```

> **Code walkthrough:** (1) WHAT IT SHOWS: subscription cleanup using `useSubscription` (automatic React cleanup on unmount) and manual `Observable.subscribe()` with explicit `unsubscribe()`. (2) KEY MECHANISM: `useSubscription` returns an RxJS Observable; React's useEffect cleanup calls `unsubscribe()` on unmount; the `graphql-ws` client sends a `complete` message to the server; the server stops the AsyncIterator; the event loop removes the subscriber from PubSub. (3) WHY IT MATTERS: not cleaning up subscriptions causes memory leaks on both client (zombie event handlers) and server (dead WebSocket connections consuming memory, Redis PubSub listeners that never clean up). (4) WHAT BREAKS: components that subscribe on mount but never unsubscribe accumulate zombie subscriptions in long-running single-page applications; each navigation adds subscriptions without removing old ones; server memory grows unboundedly. (5) TAKEAWAY: always implement subscription cleanup; in React, `useSubscription` handles cleanup automatically; for manual subscriptions, use `sub.unsubscribe()` in a `useEffect` return function or `componentWillUnmount`.

---

**[SENIOR] Q7 (Architecture): How do you debug a production subscription issue where some clients receive events but others do not?**

This symptom strongly indicates an in-memory PubSub with multiple server instances. Verify:

```bash
# Step 1: Check server instance count
# If > 1 server and in-memory PubSub -> confirmed bug
kubectl get pods -n production | grep api-server
# api-server-abc  1/1  Running  3d
# api-server-def  1/1  Running  3d
# 2 instances + in-memory PubSub = confirmed bug!

# Step 2: Check which server each client connected to
# Add connection logging:
# onConnect: () => logger.info('WS connected', {
#   serverId: process.env.HOSTNAME,
#   clientIp: ctx.extra.socket.remoteAddress
# })

# Step 3: Verify Redis PubSub is being used
grep -r "new PubSub()" src/
# Found: src/pubsub.js:
# const pubsub = new PubSub()
# CONFIRMED: in-memory PubSub - root cause found
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a systematic debugging approach for the "some clients receive events, some don't" symptom - checking instance count, connection routing, and PubSub type. (2) KEY MECHANISM: in-memory PubSub + multiple instances = events published to the instance handling the mutation are only delivered to subscribers on THAT instance; clients on other instances see no events. (3) WHY IT MATTERS: this bug is invisible in development (single server); appears in production under load or after scaling; the first client reports events (connected to the same instance as the mutation handler); the second client does not (connected to a different instance). (4) WHAT BREAKS: moving to Redis PubSub requires redeployment; during the migration window, some clients experience the bug; deploy Redis PubSub with a feature flag so rollback is instant. (5) TAKEAWAY: the diagnostic signature - "some clients receive events but others don't" with multiple server instances = in-memory PubSub; the fix is always the same: Redis PubSub.

Fix: replace `new PubSub()` with `new RedisPubSub({ publisher, subscriber })`.

*What separates good from great:* Event ordering guarantees. Redis PubSub delivers events
in FIFO order per channel. However, multiple channels or multiple Redis PUBLISH calls
in one mutation may deliver events out of order. For event-sourced systems where ordering
matters (order state machine), use Redis Streams (not PubSub); Redis Streams provide
consumer groups, acknowledgment, and ordered delivery with replay capability.

---

# Server-Sent Events as Subscription Alternative

---

### 🎯 Model Answer

**30 seconds:**
> Server-Sent Events (SSE) are an alternative to WebSockets for GraphQL subscriptions.
> SSE uses a standard HTTP connection that stays open; the server pushes events as
> `data: ...\n\n` formatted text. Advantages: simpler infrastructure (works over HTTP/1.1
> and HTTP/2, no WebSocket upgrade required), automatic reconnection built into the
> browser, works through most firewalls and proxies. Disadvantage: unidirectional (server
> to client only) - clients must use a separate HTTP request to send mutations. Use SSE
> for simple push-only subscription needs; use WebSockets for bidirectional communication.

**3 minutes (Senior):**
> SSE is underused in GraphQL. The `graphql-sse` library implements the GraphQL over
> SSE spec. Advantages vs WebSockets: (1) HTTP semantics - authentication via standard
> `Authorization` header (not `connectionParams` workaround); proxies and load balancers
> handle SSE natively. (2) HTTP/2 multiplexing - HTTP/2 supports multiple SSE streams
> over one connection; WebSockets are one connection per client. (3) Automatic
> reconnection - browsers retry automatically on disconnect (no client code required).
> (4) Simpler server code - no WebSocket server, no ws library, just HTTP handlers.
> Disadvantages: (1) Unidirectional - clients cannot send messages over the SSE
> connection; mutations must be sent via separate HTTP requests (which is already the
> norm for most GraphQL clients). (2) Text-only - SSE is UTF-8 text; binary data
> requires base64 encoding. (3) Single origin limit - SSE connections are subject to
> browser's same-origin policy and credential handling. Choose SSE for: dashboard
> updates, notifications, feed updates. Choose WebSockets for: collaborative editing,
> multiplayer games, bidirectional chat.

**Blank Mind Recovery:**

**(1) Restate:** "SSE = HTTP connection kept open, server pushes `data: ...\n\n` events.
Simpler than WebSocket: standard HTTP auth header, auto-reconnect, works through proxies.
Unidirectional: server-to-client only. GraphQL: `graphql-sse` library. Best for
dashboards, notifications. WebSockets for bidirectional. HTTP/2 SSE = multiple streams
per connection."

---

### 📘 Concept Explanation

**SSE vs WebSocket for GraphQL Subscriptions:**

```text
SERVER-SENT EVENTS (SSE) FLOW:

Client: GET /graphql/stream
  Accept: text/event-stream
  Authorization: Bearer <token>
  Connection: keep-alive

Server: HTTP 200 OK
  Content-Type: text/event-stream
  Connection: keep-alive
  Cache-Control: no-cache
  (HTTP connection stays open)

Server pushes events (text format):
  data: {"data":{"messageAdded":{"text":"Hello"}}}
  (blank line terminates each event)

  data: {"data":{"messageAdded":{"text":"World"}}}

Client receives events automatically
Client auto-reconnects if connection drops
  (Last-Event-ID header on reconnect)

WEBSOCKET FLOW (comparison):
  Client: HTTP Upgrade to WebSocket (handshake)
  Both: full-duplex binary or text frames
  Client: can SEND messages to server
  Server: can PUSH events to client
  Use when: client needs to send data to server
    over the same channel (chat, collaborative editing)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the SSE protocol flow - client makes a normal HTTP GET request with `Accept: text/event-stream`; the server keeps the connection open and pushes `data:` formatted events; no WebSocket upgrade or protocol switching. (2) HOW TO READ IT: the SSE flow shows standard HTTP semantics with keep-alive; the WebSocket comparison shows the separate upgrade handshake and bidirectional capability. (3) KEY RELATIONSHIP: SSE is server-to-client only; the client sends mutations via separate HTTP POST requests; the SSE connection is exclusively for receiving subscription events. (4) EDGE CASE: some proxies buffer HTTP responses before forwarding; a proxy that buffers the SSE stream blocks event delivery; use `Content-Type: text/event-stream` and `X-Accel-Buffering: no` header to disable nginx buffering. (5) INSIGHT: a senior engineer recognizes that SSE over HTTP/2 is superior to WebSockets in terms of infrastructure: HTTP/2 multiplexes all streams over one TCP connection, has better compression, and reuses existing HTTP load balancer infrastructure.

---

### 💻 Code Example

```javascript
// BAD: Custom SSE implementation (unnecessary complexity)
// when graphql-sse provides the standard implementation

// BAD: Manual SSE without graphql-sse
app.get('/subscriptions', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  // BAD: No authentication header check
  // BAD: No subscription operation parsing
  // BAD: Manual event ID tracking
  // BAD: No spec-compliant graphql-sse protocol
  const interval = setInterval(() => {
    res.write(`data: ${JSON.stringify({
      data: { ping: Date.now() }
    })}\n\n`);
  }, 1000);
  req.on('close', () => clearInterval(interval));
});
// This is not a spec-compliant GraphQL subscription
// No operation parsing, no variable handling,
// no error formatting per GraphQL spec
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a manual SSE implementation that is not spec-compliant for GraphQL - missing operation parsing, authentication, error formatting, and reconnection support. (2) KEY MECHANISM: the raw SSE protocol is simple (headers + `data: ...\n\n` format) but implementing it correctly for GraphQL requires: operation parsing, type system validation, variable handling, and all GraphQL error types. (3) WHY IT MATTERS: a custom SSE implementation that bypasses the GraphQL execution engine loses validation, error formatting, and schema compatibility; clients receive events in a non-standard format. (4) WHAT BREAKS: the `req.on('close')` cleanup is correct; forgetting it leaks intervals; each disconnected client's interval continues running forever. (5) TAKEAWAY: use `graphql-sse` for spec-compliant GraphQL over SSE; it handles operation parsing, subscriptions, and the SSE protocol; the manual implementation is only for understanding the protocol.

```javascript
// GOOD: graphql-sse for spec-compliant GraphQL subscriptions

const { createHandler } = require('graphql-sse/lib/use/express');

// SSE handler: handles both HTTP and SSE paths
// Single handler for all operations
const handler = createHandler({
  schema,
  // Authentication via standard HTTP Authorization header
  context: async (req) => {
    const token = req.headers.authorization
      ?.replace('Bearer ', '');
    const user = token ? verifyJWT(token) : null;
    return { user, db, pubsub };
    // Standard HTTP context! No connectionParams needed.
    // Works with any HTTP middleware (cookie-session, etc.)
  }
});

// Express integration:
app.use('/graphql', handler);

// That's it! graphql-sse handles:
// - Regular query/mutation requests (HTTP POST)
// - Subscription requests (HTTP GET/POST, SSE response)
// - Event ID tracking for reconnection
// - Error formatting per GraphQL spec

// Client (Apollo Client):
import { createClient } from 'graphql-sse';
import { SSELink } from '@graphql-sse/apollo-link';

const sseClient = createClient({
  url: 'https://api.example.com/graphql',
  headers: {
    // Standard HTTP header! Works in SSE.
    authorization: `Bearer ${token}`
  }
  // Automatic reconnection: built into graphql-sse
  // No manual retry configuration needed
});

const sseLink = new SSELink({ client: sseClient });

const client = new ApolloClient({
  cache: new InMemoryCache(),
  link: from([
    authLink,
    split(
      ({ query }) => {
        const def = getMainDefinition(query);
        return def.kind === 'OperationDefinition'
          && def.operation === 'subscription';
      },
      sseLink,     // Subscriptions -> SSE
      httpLink     // Queries/mutations -> HTTP POST
    )
  ])
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a complete `graphql-sse` setup replacing WebSocket subscriptions with SSE - the server uses `createHandler` for Express; the client uses `SSELink` with Apollo Client; authentication uses the standard HTTP `Authorization` header. (2) KEY MECHANISM: `createHandler` produces a single HTTP handler that serves both regular GraphQL operations and SSE subscription streams; the client detects whether an operation is a subscription (via `split`) and routes it to `SSELink` instead of `httpLink`. (3) WHY IT MATTERS: SSE authentication uses standard HTTP headers - no `connectionParams` workaround; the existing HTTP middleware stack (cookie parsing, session auth, rate limiting) works unchanged for subscriptions. (4) WHAT BREAKS: SSE connections are subject to browser's 6 concurrent connection per domain limit (HTTP/1.1); with HTTP/2, this limit is lifted; ensure your server supports HTTP/2 for SSE to work at scale. (5) TAKEAWAY: `graphql-sse` requires fewer moving parts than WebSocket subscriptions: no `ws` library, no WebSocket server, no `graphql-ws` - just a standard HTTP handler; ideal for teams that want subscriptions without WebSocket infrastructure complexity.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Server-Sent Events (SSE) are an alternative to WebSockets for push notifications.
> The server keeps an HTTP connection open and pushes events formatted as `data: ...\n\n`.
> For GraphQL, the `graphql-sse` library implements the spec. Advantage: simpler than
> WebSockets, uses standard HTTP headers for authentication, browsers reconnect
> automatically. Limitation: server-to-client only (unidirectional). GraphQL mutations
> still use HTTP POST; only subscriptions use SSE. Choose SSE for dashboards and
> notifications; WebSockets for bidirectional communication.

---

**Senior / Staff (5+ years):**
> SSE is the appropriate choice for most GraphQL subscription use cases. Most GraphQL
> subscriptions are unidirectional (server pushes data to client); clients send mutations
> via HTTP POST regardless. SSE advantages: standard HTTP authentication (no WebSocket
> connection params workaround), HTTP/2 multiplexing (multiple subscriptions over one
> TCP connection), automatic browser reconnection, works through all proxies and load
> balancers without special configuration. SSE limitations: unidirectional (fine for
> notifications, problematic for collaborative editing), UTF-8 text only (WebSocket
> supports binary frames). The SSE vs WebSocket decision: default to SSE unless the
> client needs to send real-time messages to the server (not just HTTP POST mutations).

---

### ⚠️ Common Misconceptions

**Misconception: "SSE requires HTTP/2 to be useful for multiple subscriptions."**

SSE works fine over HTTP/1.1, with one TCP connection per SSE subscription per client.
HTTP/1.1 browsers have a limit of 6 connections per domain; with HTTP/1.1, a client
running 7+ simultaneous SSE subscriptions would hit this limit. However, most production
systems do not need 7+ simultaneous subscriptions from one client. For the common use
case (1-3 subscriptions per page), HTTP/1.1 SSE works correctly. HTTP/2 removes the
connection limit (multiplexes streams over one connection) and is better for high-
subscription-count use cases. The practical recommendation: deploy with HTTP/2 (HTTPS
already assumes HTTP/2 in modern configurations); SSE then has no connection limits.
But HTTP/2 is not a prerequisite for SSE to work - it is an optimization.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: SSE events not arriving behind nginx reverse proxy.**

Symptom: WebSocket subscriptions work; SSE subscriptions connect but receive no events.
Direct connections work; nginx proxied connections do not.

Root cause: nginx buffers HTTP responses by default; SSE requires streaming (no buffering).

```nginx
# BAD: default nginx config buffers responses
# events never arrive until buffer fills
location /graphql {
    proxy_pass http://backend:4000;
    # Missing: proxy buffering disabled
    # SSE events buffered until proxy_buffer_size fills
}

# GOOD: nginx config for SSE
# BAD: (see above - buffering blocks events)
location /graphql {
    proxy_pass http://backend:4000;

    # Required for SSE:
    proxy_http_version 1.1;
    proxy_set_header Connection '';
    chunked_transfer_encoding on;

    # Disable response buffering for SSE:
    proxy_buffering off;
    # Or: X-Accel-Buffering: no header from server

    # Keep connection alive:
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;

    # Preserve keep-alive connection:
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: nginx configuration required for SSE to work through a reverse proxy - `proxy_buffering off` is the critical directive that enables streaming. (2) KEY MECHANISM: nginx buffers response bodies by default to improve throughput for large responses; SSE is a streaming response with no defined end; without `proxy_buffering off`, nginx waits for the buffer to fill before forwarding; the buffer fills slowly (SSE events trickle in); events are delayed or never arrive. (3) WHY IT MATTERS: SSE behind nginx works correctly in development (no nginx) but silently breaks in production (nginx buffering); the symptom looks like a networking issue or subscription bug. (4) WHAT BREAKS: `proxy_read_timeout 3600s` is essential; without it, nginx closes the SSE connection after the default 60-second read timeout even if no events have been sent; clients must reconnect every 60 seconds. (5) TAKEAWAY: the `nginx + SSE` configuration is a standard pattern; add it to the nginx template for any service that uses SSE; the `proxy_buffering off` directive is the non-obvious critical setting.

---

### ⚖️ Comparison Table

| Aspect | SSE | WebSocket |
|---|---|---|
| Direction | Server-to-client only | Bidirectional |
| HTTP Authentication | Standard header | connectionParams workaround |
| Proxy compatibility | Excellent (with buffering off) | Requires WS-aware proxy |
| Auto-reconnect | Yes (browser built-in) | Client library responsibility |
| HTTP/2 benefit | Multiplexed streams | No benefit (separate conn) |
| Binary support | No (text only) | Yes |
| Protocol complexity | Low | Higher (graphql-ws protocol) |
| Best for | Notifications, dashboards | Chat, collaborative editing |

---

### 🏛️ System Design

*(Omit: L3 keyword; SSE in production with connection pooling and backpressure covered in L5 Architecture entry.)*

---

### 📊 Diagram

```text
SSE vs WEBSOCKET INFRASTRUCTURE:

SSE ARCHITECTURE:
  Client --- HTTPS (HTTP/2) ---> Load Balancer
                                  |
              HTTP/2 multiplexing allows N SSE
              streams over ONE TCP connection:
                  |
              API Server (no WS config!)
              Express app.use('/graphql', handler)
              Standard HTTP middleware works
              Auth via Authorization header

WEBSOCKET ARCHITECTURE:
  Client --- WSS (WebSocket) --> Load Balancer
                   |              (WS-aware required!)
              TCP upgrade          nginx/ALB must
              required             pass WS headers
                   |
              WS Server (ws library + graphql-ws)
              Separate from HTTP server
              Custom auth (connectionParams)
              Sticky sessions for Redis PubSub

SSE RECONNECTION (built-in):
  Server sends: id: 42
                data: {...}
  Server closes connection
  Browser auto-reconnects:
    GET /graphql
    Last-Event-ID: 42
  Server resumes from event 42
  (requires server-side event log
   for replay - Redis stream)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: infrastructure comparison between SSE (simpler, HTTP/2, no special proxy config) and WebSockets (bidirectional, requires WS-aware load balancer, sticky sessions). (2) HOW TO READ IT: SSE uses standard HTTPS; HTTP/2 multiplexes multiple SSE subscriptions over one TCP connection; no special load balancer configuration beyond standard HTTPS. WebSocket requires the load balancer to understand the `Upgrade` header and route subsequent WS frames correctly. (3) KEY RELATIONSHIP: SSE works on any HTTPS infrastructure; WebSocket requires WebSocket-aware infrastructure; this difference determines operational complexity. (4) EDGE CASE: SSE's `Last-Event-ID` reconnection requires the server to store recent events for replay; a pure push-only SSE server that forgets events cannot replay missed events after reconnection; Redis Streams or a small event log is needed for reliable reconnection. (5) INSIGHT: a senior engineer chooses SSE for services where infrastructure simplicity is valued and bidirectionality is not required; the simplified authentication and proxy compatibility reduce operational overhead significantly.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | SSE protocol, vs WebSocket |
| Application | 2 | implementation, nginx config |
| Trade-off | 2 | when to use each, HTTP/2 |
| Scenario | 2 | events not arriving, reconnection |

---

**[JUNIOR] Q1 (Definition): What are Server-Sent Events and how do they differ from WebSockets?**

Server-Sent Events (SSE) are an HTTP-based technology for server-to-client push:
- The client opens a normal HTTP connection (GET request with `Accept: text/event-stream`).
- The server keeps the connection open and sends events in a simple text format:
  `data: {"value": 42}\n\n`
- The browser has built-in reconnection; if the connection drops, the browser
  automatically retries the GET request.

WebSockets differences:
- WebSocket: bidirectional (both client and server can send messages); separate TCP
  protocol (requires `Upgrade: websocket` HTTP handshake); binary or text.
- SSE: unidirectional (server to client only); uses standard HTTP; text only.

For GraphQL: SSE is sufficient for subscriptions because GraphQL subscriptions are
server-to-client push. Clients already send queries and mutations via HTTP POST. The
SSE connection is only for receiving subscription events.

*What separates good from great:* The browser connection limit for SSE under HTTP/1.1.
Browsers limit 6 concurrent connections per domain under HTTP/1.1. Each SSE subscription
uses one connection. With HTTP/1.1, a client with 7+ active subscriptions would queue
the 7th. HTTP/2 removes this limit by multiplexing streams over one connection. Modern
browsers default to HTTP/2 for HTTPS. When deploying GraphQL over SSE, ensure HTTPS
(which implies HTTP/2 in modern configurations) to avoid connection limits.

---

**[JUNIOR] Q2 (Application): How do you implement GraphQL subscriptions with `graphql-sse`?**

```javascript
// Server implementation:
const express = require('express');
const { createHandler } = require(
  'graphql-sse/lib/use/express'
);

const app = express();

// createHandler replaces Apollo Server
// for SSE-based subscriptions
const handler = createHandler({
  schema,    // Same schema as non-SSE setup
  context: async (req) => ({
    // Standard HTTP request context
    user: req.user,  // From passport/JWT middleware
    db,
    pubsub
    // Same context as regular HTTP resolvers!
  })
});

// Single handler for all GraphQL:
app.use('/graphql', express.json(), handler);
// GET /graphql with Accept: text/event-stream
//   -> SSE connection for subscriptions
// POST /graphql with JSON body
//   -> Regular query/mutation
app.listen(4000);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `graphql-sse`'s `createHandler` for Express - a single middleware function that handles both regular GraphQL requests and SSE subscription connections, using the standard `req.user` from existing auth middleware. (2) KEY MECHANISM: `createHandler` inspects the request to determine if it should respond with SSE (GET request with `Accept: text/event-stream`) or a regular JSON response; subscriptions over SSE and mutations over HTTP POST are handled by the same endpoint. (3) WHY IT MATTERS: existing HTTP middleware (Passport, JWT verification, rate limiting) applies to SSE connections; there is no separate WebSocket context setup; authentication that works for mutations automatically works for subscriptions. (4) WHAT BREAKS: `express.json()` must come before the handler for mutations to parse the request body; for GET-based SSE requests, `express.json()` is skipped automatically. (5) TAKEAWAY: `createHandler` is a drop-in replacement for Apollo Server HTTP handler when SSE subscriptions are needed; the schema, resolvers, and context function are identical.

---

**[SENIOR] Q3 (Trade-off): When should you choose SSE over WebSockets for GraphQL subscriptions?**

Choose SSE when:
1. No bidirectional requirements: all client interactions are HTTP POST mutations;
   subscriptions are purely server-to-client push. This is the majority of use cases.
2. Existing HTTP infrastructure: standard load balancers, CDNs, and reverse proxies
   handle SSE without WebSocket-specific configuration.
3. Simplified authentication: `Authorization` header in the SSE GET request uses the
   same auth middleware as HTTP mutations; no `connectionParams` workaround.
4. HTTP/2 available: multiple subscriptions multiplexed over one connection; better
   than multiple WebSocket connections.
5. Team prefers simplicity: SSE requires no additional server library, no ws package,
   no WebSocket server lifecycle management.

Choose WebSockets when:
1. Bidirectional communication: the client needs to send real-time messages (not just
   HTTP POST mutations) - chat, collaborative document editing, live cursor sharing.
2. Binary data: WebSocket supports binary frames; SSE is text-only.
3. Existing WebSocket infrastructure: already configured load balancers, auth middleware,
   monitoring for WebSockets.
4. Fine-grained connection control: WebSocket allows custom keepalive frames, connection
   metadata, and server-initiated close with status codes.

*What separates good from great:* The hybrid approach. Use SSE for read-heavy
subscriptions (dashboards, feeds, notifications) and HTTP POST for all writes (mutations).
Use WebSockets ONLY for features that genuinely require bidirectional communication
(real-time collaborative editing). Most production systems do not need WebSockets; a
single SSE connection handles all subscription needs while HTTP handles all mutations.

---

**[JUNIOR] Q4 (Application): How does SSE handle connection drops and reconnection?**

The browser's EventSource API handles reconnection automatically:
1. When the SSE connection drops, the browser waits `retry` milliseconds (configurable
   by the server) before reconnecting.
2. The browser includes `Last-Event-ID` header in the reconnect request with the ID
   of the last received event.
3. The server can use `Last-Event-ID` to replay missed events (if event log is maintained).

```javascript
// Server: include event IDs for reconnection
res.write(`id: ${event.id}\n`);
res.write(`data: ${JSON.stringify(event.data)}\n\n`);

// Server: set retry interval (default 3 seconds)
res.write(`retry: 5000\n`);  // 5 second retry

// Server: store recent events for replay
// (Redis Streams or in-memory ring buffer)
// On reconnect: check Last-Event-ID header
const lastId = req.headers['last-event-id'];
if (lastId) {
  // Replay all events after lastId
  const missed = await getEventsSince(lastId);
  missed.forEach(event => {
    res.write(`id: ${event.id}\n`);
    res.write(`data: ${JSON.stringify(event)}\n\n`);
  });
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: server-side event ID tracking and the `Last-Event-ID` reconnection header for replaying missed events after a connection drop. (2) KEY MECHANISM: the server sends `id: N` with each event; on reconnect, the browser sends `Last-Event-ID: N`; the server queries its event store for events after ID N and replays them; the client receives missed events seamlessly. (3) WHY IT MATTERS: without event IDs and replay, SSE clients miss events during disconnections; for financial data, stock prices, or order status, missed events cause incorrect UI state. (4) WHAT BREAKS: maintaining an event log for replay requires storage; the log must be bounded (ring buffer or TTL); unbounded logs consume unlimited memory or disk. (5) TAKEAWAY: implement event IDs for all subscriptions that require reliability; for ephemeral notifications (typing indicators, presence), skip event IDs; for state-change events (order status, document edits), implement event IDs with a bounded replay log.

---

**[SENIOR] Q5 (Trade-off): What are the proxy and infrastructure considerations for SSE in production?**

SSE infrastructure requirements:

1. Nginx: disable response buffering (`proxy_buffering off`) to prevent nginx from
   buffering the SSE stream; set long read/send timeouts (`proxy_read_timeout 3600s`).

2. AWS ALB (Application Load Balancer): supports SSE natively; long-lived HTTP
   connections require setting the idle timeout to match or exceed the SSE connection
   duration.

3. AWS API Gateway: limited support for SSE; recommended to bypass API Gateway for
   SSE endpoints and connect directly to the service or through ALB.

4. CDN (CloudFront, Fastly): standard CDN configurations cache HTTP responses and do
   not support SSE; disable caching for the SSE endpoint and configure streaming support.

5. Kubernetes (Ingress): nginx Ingress Controller requires `nginx.ingress.kubernetes.io/
   proxy-read-timeout` annotation for SSE endpoints to prevent 60-second timeout.

```yaml
# Kubernetes nginx ingress annotation for SSE:
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Kubernetes nginx Ingress annotations that configure the reverse proxy for SSE - disabling buffering and setting long timeouts. (2) KEY MECHANISM: Kubernetes nginx Ingress uses nginx proxy; the default configuration is optimized for request-response HTTP; SSE requires the streaming-specific settings; annotations override the defaults per ingress resource. (3) WHY IT MATTERS: deploying SSE without these annotations causes SSE connections to silently fail after 60 seconds (read timeout); clients reconnect every minute causing increased connection churn. (4) WHAT BREAKS: `proxy-buffering: "off"` as a string annotation (not `false` as boolean) is the correct Kubernetes annotation format; using `false` as a boolean is silently ignored. (5) TAKEAWAY: create a standard Ingress template for services with SSE that includes the buffering and timeout annotations; add these to the deployment checklist for any new service using graphql-sse.

---

**[SENIOR] Q6 (Scenario): How do you migrate from WebSocket subscriptions to SSE?**

Migration is low-risk because the schema and resolver logic are unchanged:

1. Keep the same subscription resolvers (PubSub, withFilter, Redis): no changes needed.

2. Replace the server transport:
   - Remove: `ws` library, `graphql-ws` `useServer`.
   - Add: `graphql-sse` `createHandler`.

3. Update the client transport:
   - Remove: `GraphQLWsLink`, `createClient` from `graphql-ws`.
   - Add: `SSELink`, `createClient` from `graphql-sse`.

4. Update authentication:
   - Remove: `connectionParams: () => ({ authorization: ... })`.
   - Add: standard `Authorization` header in `SSELink` options.

5. Update infrastructure:
   - Nginx: add `proxy_buffering off` and timeout settings.
   - Load balancer: extend idle timeout.
   - Remove: WebSocket listener, sticky sessions configuration (if using Redis PubSub).

6. Test: subscription functionality is identical; no schema or resolver changes mean no
   behavior changes; integration tests should pass without modification.

*What separates good from great:* The parallel migration approach. Add SSE alongside
the existing WebSocket endpoint; update clients incrementally by feature flag; monitor
SSE client reconnection rates and event delivery rates; decommission WebSocket endpoint
after all clients migrate. Parallel migration allows instant rollback (re-enable
WebSocket link for specific clients) without full redeploy.

---

**[JUNIOR] Q7 (Application): How do you send a GraphQL subscription request over SSE?**

```bash
# Raw SSE subscription request (for testing):
# Use curl to observe the SSE stream directly

curl -N -H "Accept: text/event-stream" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  --data-urlencode 'query=subscription {
    messageAdded { text author }
  }' \
  "https://api.example.com/graphql"

# Expected output (events as they arrive):
# data: {"id":"1","type":"next","payload":{"data":{"messageAdded":{"text":"Hello","author":"Alice"}}}}
#
# data: {"id":"1","type":"next","payload":{"data":{"messageAdded":{"text":"World","author":"Bob"}}}}
#
# (stream remains open, events arrive as mutations fire)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `curl` to test a GraphQL subscription over SSE - sending the subscription operation as a GET request with `Accept: text/event-stream` and receiving server push events in the terminal. (2) KEY MECHANISM: `-N` disables curl's output buffering (required for streaming); `Accept: text/event-stream` tells the server to respond with the SSE stream; the `data:` lines show the `graphql-sse` protocol format including operation ID and event type. (3) WHY IT MATTERS: curl SSE testing is the fastest way to verify that a subscription is working - no client setup, no Apollo Client, no frontend required; useful in debugging and CI health checks. (4) WHAT BREAKS: the query parameter format varies by `graphql-sse` version; some versions use GET with query params, others use POST with body; check the library version's documented request format. (5) TAKEAWAY: keep this curl command in a team runbook for quickly testing subscription connectivity; it can be used in monitoring scripts to verify that the SSE endpoint is delivering events.
