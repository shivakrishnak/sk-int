---
layout: default
title: "MCP - L1 Protocol Basics"
parent: "MCP"
nav_order: 3
permalink: /mcp/l1-protocol-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 7 | [MCP Transport Layers](#mcp-transport-layers) | ★☆☆ |
| 8 | [MCP Server Development](#mcp-server-development) | ★☆☆ |
| 9 | [MCP Client Integration](#mcp-client-integration) | ★☆☆ |

---

# MCP Transport Layers

**Interview Weight:** ★☆☆ - Transport is the
deployment decision for every MCP server. Knowing
stdio vs HTTP affects security, ops, and architecture.

---

### 🎯 Model Answer

**30 seconds:**

> MCP supports two transport mechanisms: stdio (the
> host application spawns the server as a subprocess
> and communicates via standard I/O streams) and HTTP
> with Streamable HTTP or SSE (the server runs as
> an independent HTTP process). Stdio is secure,
> zero-config, and best for local single-user servers.
> HTTP is best for shared team servers or remote
> deployments. The server code is identical for both;
> transport is a deployment configuration choice.

**3 minutes:**

> MCP transports handle the physical delivery of
> JSON-RPC messages between client and server.
> The message format is identical regardless of
> transport - only the delivery mechanism changes.
>
> Stdio transport: the MCP host spawns the server
> as a child process (using the `command` and `args`
> in the client config). Communication uses stdin
> for messages from client to server and stdout
> for responses from server to client. No network
> port is opened. The server is process-isolated
> to the host. Authentication is not needed - trust
> comes from process ownership. This is the default
> and simplest approach.
>
> HTTP transport (Streamable HTTP - MCP spec 2025-03):
> replaces the older SSE transport. The server
> exposes a single HTTP endpoint. Clients send
> JSON-RPC requests as HTTP POST and can receive
> streamed responses. Authentication via OAuth 2.1
> or API keys. Best for multi-user, shared, or
> remote deployments.
>
> The Streamable HTTP transport (2025-03) is an
> improvement over the earlier HTTP+SSE design: it
> unifies request and streaming into a single endpoint
> rather than two separate channels, simplifying
> deployment behind standard load balancers and CDNs.

**Blank Mind Recovery:**

**(1) Restate:** "Transport is how MCP client and
server exchange messages. Stdio for local, HTTP
for remote."

**(2) First principles:** "Local subprocess: stdin/stdout
pipes are the simplest secure channel. Remote: HTTP
because it works through firewalls and supports
multi-client access."

**(3) Bridge:** "Think of stdio as a Unix pipe (fast,
local, private) and HTTP as a web API (accessible
anywhere, needs auth)."

---

### 📘 Concept Explanation

**What it is:**

MCP transport layers are the physical communication
mechanisms that carry JSON-RPC messages between
MCP clients and servers. Transport is a deployment
concern - the MCP protocol itself (message formats,
primitives, capabilities) is identical across
all transports.

**The problem it solves:**

Different deployment contexts have different connectivity
requirements. A personal local tool should not need
an HTTP server. A shared team tool needs network
access. Transport flexibility enables MCP to serve
both use cases without changing the server code.

**How it works:**

```
STDIO TRANSPORT:

Host Process            Server Process
  |                         |
  |---(spawn subprocess)-->  |
  |--stdin: JSON-RPC req--> |
  |<-stdout: JSON-RPC resp- |
  |                         |
Security: process isolation
Auth: not needed
Config: command + args in client config

-------------------------------------------

HTTP/STREAMABLE HTTP TRANSPORT (2025-03):

Client Process        HTTP Server Process
  |                         |
  |--POST /mcp -----------> |
  |   {jsonrpc request}     |
  |<--200 + streaming resp- |
  |   or SSE events         |
  |                         |
Security: TLS, OAuth 2.1 / API keys
Auth: required
Config: URL + auth token in client config

-------------------------------------------

OLDER: HTTP + SSE (pre-2025-03, still supported):
  Two channels: POST for requests, GET /events
  for server push. Deprecated in favor of
  Streamable HTTP but backward-compatible.
```

> **Code walkthrough:** This MCP Transport Layers example demonstrates a key concept in practice using goroutine. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

Server code is transport-agnostic. The Python SDK's
`stdio_server()` and `streamable_http_server()` wrap
the same server object in different transport handlers.
This means a server developed with stdio can be
deployed as HTTP later without changing any
tool, resource, or prompt implementation code.

**When to use stdio:**

- Single-user local deployment
- Tools accessing local resources (filesystem, local DBs)
- Privacy-sensitive data that should not traverse a network
- Lowest-overhead, minimal-ops deployment

**When to use HTTP:**

- Shared tools for teams
- Remote server deployment (cloud, VMs)
- Tools requiring authentication per user (different API keys)
- Deployment behind load balancer or proxy
- Needing to share one server instance across many clients

**Alternatives:**

- gRPC: not currently a standard MCP transport, though
  community experiments exist
- WebSocket: not in the official MCP spec

**First-principles derivation:**

AI tool servers need two deployment models: local
(zero-config, no network exposure, maximum privacy)
and remote (multi-user, network-accessible, authenticated).
Stdio is the optimal local transport: built into every
OS, no port management, process-level isolation.
HTTP is the optimal remote transport: universal
connectivity, standard auth primitives, works through
firewalls. MCP supports both without duplicating
server logic.

---

### 💻 Code Example

```python
import asyncio
from mcp.server import Server
from mcp.server.models import InitializationOptions
import mcp.types as types

server = Server("my-server")


@server.list_tools()
async def list_tools() -> list[types.Tool]:
    return [types.Tool(
        name="echo",
        description="Echo back the input for testing",
        inputSchema={
            "type": "object",
            "properties": {
                "message": {"type": "string"}
            },
            "required": ["message"]
        }
    )]


@server.call_tool()
async def call_tool(
    name: str, arguments: dict
) -> list[types.TextContent]:
    if name == "echo":
        return [types.TextContent(
            type="text",
            text=arguments.get("message", "")
        )]
    raise ValueError(f"Unknown tool: {name}")


# OPTION A: Stdio transport (local subprocess)
async def run_stdio():
    from mcp.server.stdio import stdio_server
    async with stdio_server() as (r, w):
        await server.run(
            r, w,
            InitializationOptions(
                server_name="my-server",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=None,
                    experimental_capabilities={}
                )
            )
        )


# OPTION B: HTTP transport (Streamable HTTP 2025-03)
# Same server object, different transport wrapper.
# Install: pip install "mcp[http]"
async def run_http():
    from mcp.server.streamable_http import (
        streamable_http_server
    )
    # Serves on http://localhost:8000/mcp
    await streamable_http_server(
        server,
        host="127.0.0.1",
        port=8000,
        path="/mcp"
    )


# The server object is IDENTICAL for both transports.
# Only the run() wrapper changes. Transport is a
# deployment decision, not a code architecture decision.

if __name__ == "__main__":
    asyncio.run(run_stdio())  # Default: stdio
```

> **Code walkthrough:** The `server` object with itsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `list_tools()` and `call_tool()` handlers is defined
> once and reused by both transport options. `run_stdio()`
> wraps it in the stdio transport - this is what
> Claude Desktop invokes as a subprocess. `run_http()`
> wraps the same server in the Streamable HTTP transport
> for a network-accessible deployment. Zero server
> logic changes required to switch transports. The
> `InitializationOptions` declares server metadata
> and capabilities - this is sent during the initialize
> handshake so the client knows what the server supports.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "MCP has two main transports: stdio (the host spawns
> the server as a subprocess, uses stdin/stdout for
> messages - great for local personal tools) and HTTP
> (the server runs as an HTTP process, needs authentication
> - great for shared team tools). The important thing
> I remember: the server code is the same for both
> transports. Transport is just a deployment configuration
> choice, not a code architecture decision."

---

**Senior / Staff:**

> "Transport selection in MCP follows a simple matrix:
> single-user/local = stdio; multi-user/remote = HTTP.
> The Streamable HTTP transport (2025-03 spec) is
> the right choice for new HTTP deployments - it
> replaces the older SSE approach with a single
> endpoint that handles both requests and streaming,
> working correctly behind standard load balancers
> without special SSE proxy configuration. Security
> posture: stdio servers are scoped to the user's
> local session - no network attack surface. HTTP
> servers require OAuth 2.1 or API key authentication
> plus TLS in production. For enterprise deployments,
> I deploy shared servers behind an API gateway
> with per-user API key injection so the server
> doesn't manage individual user credentials."

---

### ⚠️ Common Misconceptions

**Misconception: "Stdio is less capable than HTTP."**

Stdio is not a limited transport. It delivers the
full MCP protocol including all capabilities (tools,
resources, prompts, sampling, subscriptions). The
only limitation of stdio is locality: the server
runs on the same machine as the host. For local
resources (filesystem, local databases, local
Docker), stdio is preferable - it has lower latency,
no network overhead, and inherently better security
(no open ports, no authentication needed). HTTP
is only necessary when the server must be remote
or shared.

---

### 🚨 Failure Modes and Diagnosis

**Failure: HTTP MCP server works locally but fails
behind a reverse proxy**

*Symptom:* Direct connection to the server works.
Behind nginx or another proxy, requests time out
or return 502.

*Root cause (older SSE transport):* SSE connections
require long-lived connections that proxies with
aggressive timeouts close prematurely. Proxies
also may buffer streaming responses, breaking
the event stream.

*Fix for Streamable HTTP (2025-03):* Upgrade to
the Streamable HTTP transport. It uses standard
HTTP POST with response streaming, which proxies
handle correctly.

*Fix for older SSE (if not upgrading):* Configure
the proxy:
```nginx
proxy_read_timeout 300s;
proxy_buffering off;       # Critical for SSE
proxy_cache off;
add_header X-Accel-Buffering no;
```

> **Code walkthrough:** This deployment decision, not a code architecture decision. example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*Root cause (auth):* The proxy strips `Authorization`
headers. Configure the proxy to forward auth headers:
```nginx
proxy_pass_request_headers on;
```

> **Code walkthrough:** This deployment decision, not a code architecture decision. example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Transport comparison | 3-4 min |
| Security model | 3-4 min |
| Deployment decision | 3-4 min |
| Debugging | 4-5 min |
| Blank mind recovery | 1 min |

---

**[JUNIOR] Q1 - What are the two MCP transport types
and when do you use each?**

*Why they ask:* Fundamental deployment knowledge.

Stdio transport:
- Server runs as a subprocess of the host
- Communication via stdin/stdout
- No network port, no auth needed
- Use for: local tools, single user, sensitive data

HTTP transport (Streamable HTTP, 2025-03):
- Server runs as an independent HTTP server
- Communication via HTTP POST
- Requires TLS + authentication
- Use for: shared team tools, remote deployment,
  multi-user access

Decision rule:
- Will only I use this tool on this machine? -> stdio
- Will teammates or other machines need it? -> HTTP
- Does the tool access local-only resources? -> stdio

*What separates good from great:* "Stdio has no
open network port - it's inherently more secure
for local tools."

---

**[MID] Q2 - What is the Streamable HTTP transport
and why is it an improvement over SSE?**

*Why they ask:* Current spec awareness.

Older SSE transport (pre-2025-03): two channels.
A POST endpoint for client requests. A GET `/events`
endpoint that streams server-sent events back to the client.

Problems with SSE:
- Two separate HTTP connections
- SSE requires proxies to disable buffering (non-trivial config)
- SSE doesn't work well with HTTP/2 multiplexing
- Complex to deploy behind standard infrastructure

Streamable HTTP transport (2025-03):
- Single HTTP endpoint
- Client POSTs requests
- Server responds with either a regular HTTP response
  or a streaming response (using chunked transfer encoding)
- Works correctly behind standard load balancers and CDNs
- No special proxy configuration required

Migration: servers can support both transports
simultaneously for backward compatibility. The client
negotiates which transport to use.

*What separates good from great:* "Streamable HTTP
works behind standard reverse proxies without
special SSE buffering config."

---

**[SENIOR] Q3 - [TRADE-OFF] What are the security
implications of each transport choice?**

*Why they ask:* Security architecture thinking.

Stdio security model:
- Trust is established by process ownership
- The MCP host spawns the server - only processes
  with permission to run the host can access the server
- No network exposure: the server cannot be accessed
  by other users on the same machine via network
- Credential safety: the server receives credentials
  via environment variables (set in client config)
  rather than over a network channel
- Risk: malicious server code can access the local
  user's filesystem and process environment

HTTP security model:
- Authentication required: API keys or OAuth 2.1
- TLS required in production (prevent key interception)
- Network exposure: any network-reachable client
  can attempt to connect
- Multi-tenant considerations: user A must not
  access user B's data when sharing a server
- Audit logging: HTTP access logs provide an audit trail
  that stdio lacks

Decision framework:
- Data classification: secret/confidential data
  -> stdio to prevent network exposure
- Multi-user requirement: -> HTTP with per-user auth
- Audit requirement: -> HTTP (access logs) or add
  logging to stdio server

*What separates good from great:* "HTTP requires
per-user authentication for multi-tenant access -
a shared server must isolate user data."

---

**[JUNIOR] Q4 - How do you configure a stdio MCP
server in Claude Desktop?**

*Why they ask:* Practical setup knowledge.

Claude Desktop config file:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

Config format:
```json
{
  "mcpServers": {
    "my-tool": {
      "command": "python",
      "args": ["/absolute/path/to/server.py"],
      "env": {
        "API_KEY": "your-key",
        "DATABASE_URL": "postgres://..."
      }
    }
  }
}
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Key fields:
- `command`: the executable to run (python, node, uvx)
- `args`: arguments to the command
- `env`: environment variables passed to the server process

For portable team setups (using uvx to avoid
path issues):
```json
{
  "mcpServers": {
    "my-tool": {
      "command": "uvx",
      "args": ["my-mcp-server-package"]
    }
  }
}
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

After editing: restart Claude Desktop.

*What separates good from great:* "Use absolute paths
in command/args - relative paths depend on the shell's
working directory, which varies."

---

**[MID] Q5 - [DEBUGGING] Your stdio MCP server
starts but immediately exits. What do you check?**

*Why they ask:* Startup failure debugging.

Step 1: Run the server command directly in the terminal:
```bash
python /path/to/server.py
```
> **Code walkthrough:** This Unknown example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

If it exits immediately, you'll see the error.

Step 2: Check Claude Desktop logs:
```bash
# macOS
tail -50 ~/Library/Logs/Claude/mcp-server-{name}.log

# Windows
Get-Content "$env:APPDATA\Claude\Logs\mcp-server-{name}.log" -Tail 50
```

> **Code walkthrough:** This Windows example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Common causes:
- Import error: a required package is not installed
  in the Python environment used by the command
- Syntax error: the server code has a syntax error
- Missing environment variable: the server reads
  an env var that's not set in the config's `env` section
- Permission error: the command path is not executable

Fix pattern:
```bash
# Test with the exact environment from config:
API_KEY=your-key python /path/to/server.py
```
> **Code walkthrough:** This Test with the exact environment from config: example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

If this works, the issue is in how Claude Desktop
passes the environment.

*What separates good from great:* "The MCP log
file shows the server's stderr - always check it first."

---

**[JUNIOR] Q6 - How does MCP handle server messages
that arrive before the client sends a request?
(Server push)**

*Why they ask:* Understanding of the async message model.

MCP supports server-initiated messages (notifications)
independent of the request-response cycle. These
are one-way messages: `notification` type messages
have no `id` field (no response expected).

Common server notifications:
- `notifications/tools/list_changed`: the tool list
  has changed; client should re-fetch tools/list
- `notifications/resources/updated`: a subscribed
  resource has changed
- `notifications/progress`: progress update for a
  long-running tool

In stdio: notifications are sent on stdout between
request-response cycles. The client must read stdin
and notifications asynchronously.

In HTTP (Streamable HTTP): the server can send
notifications as part of a streaming response or
by using SSE within the streaming response body.

When to use notifications:
- Tool list changes dynamically (new tools available)
- Resource subscriptions detect changes
- Long-running tool progress updates (> 5 seconds)

*What separates good from great:* "Notifications
are one-way (no id, no response expected) - they're
the async event mechanism for server-to-client push."

---

**[MID] Q7 - How do you choose between deploying
an HTTP MCP server on a VM vs. serverless (Lambda)?**

*Why they ask:* Cloud deployment judgment.

Serverless (Lambda, Cloud Functions):

Pros: zero idle cost, auto-scaling, no server management.
Cons: cold start latency (100ms-500ms per new instance),
connection overhead (no persistent connections),
shorter max execution time (Lambda: 15 min max).

VM / container:

Pros: persistent connections (no reconnect overhead),
no cold starts, predictable latency, longer execution.
Cons: always-on cost even when idle, manual scaling.

Decision factors:

(1) Usage pattern: sporadic (1-10 calls/day) -> serverless.
    Continuous (100+ calls/hour) -> VM/container.

(2) Latency requirement: if the tool must respond
    in < 200ms -> VM/container (avoid cold start).

(3) Stateful operations: if the server holds connection
    state (database connections, cache) -> VM/container.
    Serverless starts fresh each invocation.

(4) Long-running tools: tools that run > 5 minutes
    -> VM/container (serverless max execution limits).

For most MCP servers used by small teams: VM or
container is simpler (fewer deployment edge cases,
persistent connections). Serverless for public
MCP servers with unpredictable traffic.

*What separates good from great:* "Serverless cold
start adds 100-500ms - for interactive AI tools
this is often unacceptable."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ concept.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ concept.)*

---

### 📊 Diagram

```
MCP TRANSPORT COMPARISON:

STDIO (local subprocess):
  Host App
    |--spawn--> Server Process
    |<-stdin/stdout pipes-->|
    No network. No auth.

HTTP (Streamable HTTP 2025-03):
  Host App
    |--HTTP POST /mcp--> Server
    |   {jsonrpc: ...}       |
    |<-200 + stream resp----|
    Needs TLS + OAuth 2.1
```

```mermaid
flowchart LR
    subgraph stdio["stdio Transport"]
        H1[Host App] -->|"spawn subprocess"| S1[Server Process]
        H1 <-->|"stdin/stdout pipes"| S1
    end
    subgraph http["HTTP Transport (Streamable HTTP)"]
        H2[Host App] -->|"HTTP POST /mcp"| S2[HTTP Server]
        S2 -->|"200 + streaming response"| H2
    end
    style stdio fill:#e8f5e9
    style http fill:#e3f2fd
```

> **Diagram walkthrough:** The stdio transport is
> represented as a parent-child process relationship:
> the host spawns the server and communicates via
> OS-level stdin/stdout pipes. There is no network
> socket. The HTTP transport is a standard client-server
> HTTP relationship: any host that can make HTTP
> requests to the server's URL can connect (subject
> to authentication). The Streamable HTTP transport
> uses a single POST endpoint that can respond with
> streaming content, unlike the older two-channel
> SSE approach.

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# MCP Server Development

**Interview Weight:** ★☆☆ - Every developer working
with MCP needs to know how to build a server. This
covers the complete development workflow.

---

### 🎯 Model Answer

**30 seconds:**

> Building an MCP server in Python involves four
> steps: install the `mcp` package (via `uv add mcp`),
> create a `Server` instance, register handlers for
> `list_tools()` and `call_tool()` using decorators,
> and run it with `stdio_server()` or `streamable_http_server()`.
> The MCP Inspector (npx @modelcontextprotocol/inspector)
> is the essential tool for interactive testing before
> connecting to a real client.

**3 minutes:**

> MCP server development follows a consistent pattern
> regardless of what the server does. The Python SDK
> provides a decorator-based API that maps to the
> MCP primitives.
>
> The core server object is `mcp.server.Server`. It
> maintains the server state, handles the JSON-RPC
> protocol, and invokes registered handlers. Handlers
> are async functions decorated with `@server.list_tools()`,
> `@server.call_tool()`, `@server.list_resources()`,
> `@server.read_resource()`, `@server.list_prompts()`,
> `@server.get_prompt()`.
>
> Development best practices: use a virtual environment
> or `uv` for dependency management. Write unit tests
> for handlers by calling them directly (they're
> just async functions). Use the MCP Inspector for
> protocol-level testing before integrating with
> a client.
>
> The lifespan context manager is important for
> production servers: it initializes shared resources
> (database connections, API clients) once on startup
> and cleans them up on shutdown, rather than
> creating them per-request.

**Blank Mind Recovery:**

**(1) Restate:** "Building an MCP server. Let me walk
through the minimum viable implementation."

**(2) First principles:** "Need: a server object,
handlers for tool discovery (list_tools) and
invocation (call_tool), and a transport runner."

**(3) Bridge:** "Like a REST API: define routes
(tool handlers), add a server (transport runner),
start serving."

---

### 📘 Concept Explanation

**What it is:**

MCP server development is the process of building
a server that exposes tools, resources, and/or
prompts to MCP clients using the MCP Python (or
TypeScript) SDK.

**The problem it solves:**

Without a standardized development pattern, MCP
server authors would have to implement JSON-RPC
handling, capability negotiation, and message routing
from scratch. The SDK handles the protocol; authors
implement only the business logic (what the tools
actually do).

**How it works:**

```
DEVELOPMENT WORKFLOW:

1. Install:
   uv init my-server
   uv add mcp

2. Create server.py:
   from mcp.server import Server
   import mcp.types as types

   server = Server("my-server")

   @server.list_tools()
   async def list_tools():
       return [types.Tool(...)]

   @server.call_tool()
   async def call_tool(name, arguments):
       # business logic here
       return [types.TextContent(...)]

3. Add transport runner:
   async def main():
       async with stdio_server() as (r, w):
           await server.run(r, w, opts)
   asyncio.run(main())

4. Test with MCP Inspector:
   npx @modelcontextprotocol/inspector python server.py

5. Configure in Claude Desktop:
   claude_desktop_config.json -> mcpServers entry

6. Deploy / distribute:
   uv build -> PyPI -> uvx install
```

> **Code walkthrough:** This business logic here example demonstrates asyncio coroutine definition using async/await. **KEY MECHANISM:** the event loop schedules coroutines; await suspends execution until the awaited future resolves. **WHY IT MATTERS:** blocking call inside async def starves the event loop - all coroutines freeze. **TAKEAWAY: never use blocking I/O (requests, time.sleep) inside async def; use aiohttp, asyncio.sleep.**

**The key insight:**

Test with MCP Inspector BEFORE connecting to a
real client. The Inspector shows all JSON-RPC
messages, capability responses, and tool call
results in a UI. Debugging a server through
Claude Desktop is difficult (indirect feedback).
The Inspector makes the MCP protocol transparent.

**When to use it:**

Any time you need to expose data or actions to
MCP-compatible AI clients.

**When NOT to use it:**

When a tool only needs to work with one AI client
programmatically (use direct function calling instead).

**Alternatives:**

- TypeScript SDK: `@modelcontextprotocol/sdk`
  Better for Node.js environments and teams with
  TypeScript expertise.
- Community SDKs: Go, Rust, Java (Spring AI)

**First-principles derivation:**

Building an MCP server requires: JSON-RPC 2.0
message handling, capability negotiation (initialize),
list handlers (tools/list, resources/list, prompts/list),
call handlers (tools/call, resources/read, prompts/get),
notification handling, and transport management.
The SDK reduces this to: register handlers as
decorated async functions. The protocol complexity
is hidden by the SDK.

---

### 💻 Code Example

```python
# Complete minimal MCP server with best practices
# Demonstrates: lifespan, typed returns, error handling

import asyncio
import json
from contextlib import asynccontextmanager
from mcp.server import Server
from mcp.server.models import InitializationOptions
from mcp.server.stdio import stdio_server
import mcp.types as types


# BEST PRACTICE: Lifespan for shared resources
@asynccontextmanager
async def server_lifespan(server: Server):
    """Initialize and cleanup shared resources."""
    # Initialize (runs once on startup)
    print("Server starting", flush=True)  # goes to stderr
    # Example: db = await create_connection_pool(...)
    yield {
        # "db": db  # shared context passed to handlers
    }
    # Cleanup (runs on shutdown)
    # await db.close()
    print("Server stopped", flush=True)


server = Server(
    "example-server",
    lifespan=server_lifespan
)


@server.list_tools()
async def list_tools() -> list[types.Tool]:
    """Return all available tools."""
    return [
        types.Tool(
            name="search_records",
            description=(
                "Search customer records by name or email. "
                "Returns matching records with IDs. "
                "Use when user asks to find a customer."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Name or email to search"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Max results (1-50)",
                        "default": 10
                    }
                },
                "required": ["query"]
            }
        )
    ]


@server.call_tool()
async def call_tool(
    name: str,
    arguments: dict
) -> list[types.TextContent]:
    """Handle tool invocations."""
    if name != "search_records":
        # Protocol error: unknown tool
        raise ValueError(f"Unknown tool: {name}")

    query = arguments.get("query")
    if not query:
        # Tool execution error: missing required arg
        return [types.TextContent(
            type="text",
            text="Error: 'query' argument is required"
        )]

    limit = min(arguments.get("limit", 10), 50)

    # Business logic (production: query real DB)
    results = [
        {"id": "C001", "name": "Alice Smith",
         "email": "alice@example.com"},
        {"id": "C002", "name": "Bob Jones",
         "email": "bob@example.com"}
    ]
    filtered = [
        r for r in results
        if query.lower() in r["name"].lower()
        or query.lower() in r["email"].lower()
    ][:limit]

    return [types.TextContent(
        type="text",
        text=json.dumps(filtered, indent=2)
    )]


async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="example-server",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=None,
                    experimental_capabilities={}
                )
            )
        )


if __name__ == "__main__":
    asyncio.run(main())
```

> **Code walkthrough:** The `server_lifespan` contextice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> manager runs setup code once on server startup
> (database connections, API clients) and teardown
> on shutdown - not per-request. The `list_tools()`
> handler returns a typed Tool object with a precise
> description (names the data source, describes
> return format, includes invocation trigger). The
> `call_tool()` handler demonstrates two error
> patterns: raising ValueError for unknown tools
> (protocol-level error) and returning TextContent
> with an error message for missing arguments (tool-level
> error the AI can see). The `limit` parameter is
> capped at 50 (`min(limit, 50)`) to prevent abuse.
> The `main()` function wraps everything in the stdio
> transport. This is the complete, production-ready
> server pattern.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "MCP server development in Python uses the `mcp`
> package. The pattern: create a Server object, register
> async handlers with decorators (`@server.list_tools()`,
> `@server.call_tool()`), and run it with `stdio_server()`.
> I always test with the MCP Inspector before connecting
> to Claude Desktop - it shows all JSON-RPC messages
> and makes debugging much easier. The lifespan context
> manager is the best practice for shared resources
> like database connections."

---

**Senior / Staff:**

> "Production MCP server development has three key
> engineering concerns. First: the lifespan pattern
> for resource management (database connection pools,
> API clients). Without it, each tool call re-creates
> connections. Second: error tier discipline - protocol
> errors (raise exceptions) vs. tool execution errors
> (return isError content). The AI sees tool execution
> errors and can reason about them; protocol errors
> are invisible to the AI. Third: schema quality as
> the primary interface - the tool description and
> inputSchema property descriptions drive AI behavior
> more than the implementation. For distribution,
> `uv build` + PyPI + `uvx` is the modern pattern:
> users install with `uvx my-server` and get a fully
> isolated environment without path management."

---

### ⚠️ Common Misconceptions

**Misconception: "Server stdout is available for
debug logging."**

In stdio transport, stdout IS the MCP communication
channel. Any print statement that writes to stdout
corrupts the JSON-RPC stream and breaks the connection.
All logging must go to stderr. In Python: use
`logging` configured to stderr, or `print("msg",
file=sys.stderr)`. The SDK itself sends stdout
JSON-RPC messages and stderr logs. Never print
to stdout in an MCP stdio server.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Server connects but no tools appear in the client**

*Symptom:* Claude Desktop connects to the server
(green status). The tool panel shows no tools.

*Diagnosis:*

Step 1: Test tools/list directly:
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize",
"params":{"protocolVersion":"2024-11-05","capabilities":{}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
| python server.py
```
> **Code walkthrough:** This Business logic (production: query real DB) example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Verify both responses arrive correctly.

Step 2: Check the initialize response. The
`capabilities` object must include `"tools": {}`
for the client to call tools/list. If tools are
not declared in capabilities, the client won't
request them.

Step 3: Check for exceptions in `list_tools()`.
If the handler raises an exception during the list
call, the client may silently suppress the error
and show no tools.

*Fix:* Ensure `server.get_capabilities()` is called
correctly in `InitializationOptions`. Ensure
`list_tools()` returns a non-empty list without
raising exceptions.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Development workflow | 3-4 min |
| SDK patterns | 3-4 min |
| Testing | 4-5 min |
| Error handling | 3-4 min |
| Distribution | 3-4 min |
| Blank mind recovery | 1 min |

---

**[JUNIOR] Q1 - What are the minimum steps to
build a working MCP server?**

*Why they ask:* Can you build one from scratch?

Five steps:

(1) Install: `uv add mcp` or `pip install mcp`

(2) Create server:
```python
from mcp.server import Server
server = Server("my-server")
```

> **Code walkthrough:** This Business logic (production: query real DB) example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

(3) Register tools:
```python
@server.list_tools()
async def list_tools():
    return [types.Tool(name="ping",
                       description="Test",
                       inputSchema={"type":"object",
                                    "properties":{}})]
@server.call_tool()
async def call_tool(name, arguments):
    return [types.TextContent(type="text", text="pong")]
```

> **Code walkthrough:** This Business logic (production: query real DB) example demonstrates asyncio coroutine definition using async/await. **KEY MECHANISM:** the event loop schedules coroutines; await suspends execution until the awaited future resolves. **WHY IT MATTERS:** blocking call inside async def starves the event loop - all coroutines freeze. **TAKEAWAY: never use blocking I/O (requests, time.sleep) inside async def; use aiohttp, asyncio.sleep.**

(4) Add transport runner:
```python
import asyncio
from mcp.server.stdio import stdio_server

async def main():
    async with stdio_server() as (r, w):
        await server.run(r, w,
            InitializationOptions(
                server_name="my-server",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=None,
                    experimental_capabilities={})))
asyncio.run(main())
```

> **Code walkthrough:** This Unknown example demonstrates asyncio coroutine definition using async/await. **KEY MECHANISM:** the event loop schedules coroutines; await suspends execution until the awaited future resolves. **WHY IT MATTERS:** blocking call inside async def starves the event loop - all coroutines freeze. **TAKEAWAY: never use blocking I/O (requests, time.sleep) inside async def; use aiohttp, asyncio.sleep.**

(5) Test:
```bash
npx @modelcontextprotocol/inspector python server.py
```

> **Code walkthrough:** This Unknown example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

*What separates good from great:* "The Inspector
is step 5 - always test with it before connecting
to a real client."

---

**[MID] Q2 - How do you unit test an MCP server
handler?**

*Why they ask:* Testing discipline.

MCP handlers are just async Python functions. Test
them directly without spinning up the full server:

```python
import asyncio
import pytest
from server import list_tools, call_tool

@pytest.mark.asyncio
async def test_list_tools():
    tools = await list_tools()
    assert len(tools) > 0
    assert tools[0].name == "search_records"
    assert tools[0].inputSchema["type"] == "object"

@pytest.mark.asyncio
async def test_call_tool_success():
    result = await call_tool(
        "search_records",
        {"query": "alice"}
    )
    assert len(result) > 0
    assert result[0].type == "text"
    assert "alice" in result[0].text.lower()

@pytest.mark.asyncio
async def test_call_tool_missing_arg():
    result = await call_tool("search_records", {})
    # Should return error content, not raise
    assert "error" in result[0].text.lower()

@pytest.mark.asyncio
async def test_call_tool_unknown():
    with pytest.raises(ValueError):
        await call_tool("nonexistent", {})
```

> **Code walkthrough:** This Should return error content, not raise example demonstrates asyncio coroutine definition using async/await. **KEY MECHANISM:** the event loop schedules coroutines; await suspends execution until the awaited future resolves. **WHY IT MATTERS:** blocking call inside async def starves the event loop - all coroutines freeze. **TAKEAWAY: never use blocking I/O (requests, time.sleep) inside async def; use aiohttp, asyncio.sleep.**

For integration testing: use the MCP Inspector
or send raw JSON-RPC messages via subprocess.

*What separates good from great:* "Handlers are
just async functions - test them directly without
a mock server framework."

---

**[SENIOR] Q3 - How do you distribute an MCP server
for team use?**

*Why they ask:* Distribution and ops knowledge.

Three distribution patterns:

Pattern 1: PyPI + uvx (recommended for dev tools):
```bash
# Build:
uv build
uv publish

# Team install (no manual venv):
uvx my-mcp-server
```
> **Code walkthrough:** This Team install (no manual venv): example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Config: `"command": "uvx", "args": ["my-mcp-server"]`
Zero path management. Each user gets isolated env.

Pattern 2: Docker + HTTP:
```dockerfile
FROM python:3.12-slim
COPY . .
RUN pip install .
CMD ["python", "server.py", "--http", "--port", "8000"]
```
> **Code walkthrough:** This Team install (no manual venv): example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Team configures the URL + API key. Central deployment,
zero per-user installation.

Pattern 3: Company artifactory/npm (for internal tools):
Publish to internal registry. Users add to their
client config. IT manages the server version centrally.

For teams: Pattern 2 (Docker+HTTP) scales best -
no local installation, central updates, works for
non-developer teammates who use Claude Desktop.

For open-source tools: Pattern 1 (PyPI+uvx) for
frictionless community adoption.

*What separates good from great:* "Docker + HTTP
for teams: central updates, no per-user installation."

---

**[MID] Q4 - What is the MCP Inspector and how
do you use it?**

*Why they ask:* Tool knowledge.

MCP Inspector: an official Anthropic tool for
interactive MCP server testing. It connects to
a server and provides a UI to:
- View capabilities
- List tools, resources, prompts
- Call tools with custom arguments
- Inspect raw JSON-RPC messages

Installation and use:
```bash
# Run directly (no install needed):
npx @modelcontextprotocol/inspector python server.py

# Opens a browser UI at http://localhost:5173
```

> **Code walkthrough:** This Opens a browser UI at http://localhost:5173 example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Workflow:
1. Start Inspector with your server command
2. Click "Connect" in the UI
3. View "Tools" tab to verify tools are listed correctly
4. Click a tool, fill in arguments, click "Run"
5. View result + raw JSON-RPC messages in the Inspector

The "Raw JSON" tab shows every JSON-RPC message
exchanged. This is essential for debugging schema
issues, capability negotiation problems, or error
responses.

Alternative for non-browser: send raw JSON-RPC
via stdin directly (see previous Q1 in Transport Layers).

*What separates good from great:* "The Raw JSON
tab shows every JSON-RPC message - use it to debug
capability negotiation, not just tool calls."

---

**[JUNIOR] Q5 - Why can't you use print() for
logging in an MCP stdio server?**

*Why they ask:* Critical practical knowledge.

In stdio transport: stdout IS the communication
channel. MCP client and server exchange JSON-RPC
messages via stdin/stdout. Any non-JSON-RPC output
on stdout corrupts the message stream. The client
attempts to parse "debug output" as JSON-RPC and
fails with a protocol error.

Symptoms: client shows "parse error" or the server
immediately disconnects after any print statement.

Correct logging:
```python
import sys
import logging

# Configure logging to stderr:
logging.basicConfig(
    level=logging.DEBUG,
    stream=sys.stderr,  # ALWAYS stderr
    format="%(asctime)s %(name)s %(levelname)s %(message)s"
)

logger = logging.getLogger(__name__)

# In handlers:
logger.debug(f"Tool called: {name}")  # Goes to stderr
# NOT: print(f"Tool called: {name}")  # BREAKS the server
```

> **Code walkthrough:** This NOT: print(f"Tool called: {name}")  # BREAKS the server example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

In Claude Desktop, stderr from the server process
appears in the server's log file:
`~/Library/Logs/Claude/mcp-server-{name}.log`

*What separates good from great:* "stdout is the
JSON-RPC channel - a single print() breaks protocol
parsing."

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a production
MCP server you built and what you learned.**

*Why they ask:* Real experience.

Built a PostgreSQL MCP server for an analytics team.
Goals: let data analysts use Claude Desktop to
explore the data warehouse without writing SQL.

Implementation:
- Resources: one resource per table with schema info
  (URI: `postgres://warehouse/{table_name}`)
- Tools: `execute_query` (SELECT only), `list_tables`,
  `describe_table`, `get_sample_rows`
- Prompts: `explain-query` template for pasting
  a slow query and getting an optimization analysis

Key lessons:

(1) SQL injection is trivially exploitable via MCP.
    The AI will happily pass user-provided strings
    as SQL. Fixed: strict query validation (SELECT
    only, no subqueries to system tables, no LIMIT
    bypass, query timeout at 10 seconds).

(2) The lifespan pattern was essential. Without it,
    the server created a new database connection
    per tool call. With a connection pool in lifespan:
    latency dropped from 150ms to 15ms per query.

(3) Tool descriptions needed extensive tuning. Initial
    description: "Execute a SQL query." Claude would
    generate arbitrary SQL with JOINs and window
    functions that timed out. Final description:
    "Execute a simple SELECT query (no JOINs, max
    LIMIT 100). For complex analysis, use explain-query
    prompt first." This steered the AI toward safe queries.

(4) Readonly enforcement: the database user had
    SELECT-only permissions at the PostgreSQL level.
    Even if the AI somehow got an INSERT through,
    the DB rejected it.

*What separates good from great:* "Defense in depth:
SQL validation + SELECT-only DB user + query timeout.
Multiple independent safeguards."

---

**[MID] Q7 - [TRADE-OFF] Python SDK vs TypeScript
SDK - when do you choose each?**

*Why they ask:* Technical decision making.

Python SDK (`mcp` package):
- Better for: data science and ML pipelines, teams
  with Python expertise, tools that call Python-native
  libraries (pandas, numpy, scikit-learn, torch)
- Ecosystem: the largest MCP server community
  (most examples, tutorials, reference servers in Python)
- Deployment: works well with `uvx` for zero-install
  distribution

TypeScript SDK (`@modelcontextprotocol/sdk`):
- Better for: Node.js/web teams, tools that call
  JavaScript APIs, frontend-adjacent tooling
- Ecosystem: strong npm ecosystem for web APIs
- Deployment: `npx` for zero-install distribution
  (similar to `uvx`)

For existing Python teams: Python SDK. Zero learning
curve.
For existing Node.js teams: TypeScript SDK.
For new teams: Python SDK. Larger community and
more examples.

Other SDKs:
- Java (Spring AI): for Java/Kotlin enterprise teams
- Go: for teams deploying MCP in Go microservice environments
- Rust: for performance-critical servers

*What separates good from great:* "Choose based on
team's existing language and what external libraries
the tools need to call."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ concept.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ concept.)*

---

### 📊 Diagram

*(Omit: server development workflow is expressed
well as numbered lists.)*

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# MCP Client Integration

**Interview Weight:** ★☆☆ - Understanding how to
integrate MCP client-side (configuring clients,
connecting to servers) is essential for AI teams
setting up their tooling environment.

---

### 🎯 Model Answer

**30 seconds:**

> MCP client integration means configuring an MCP
> host application (Claude Desktop, VS Code, Cursor)
> to connect to one or more MCP servers. Each client
> has its own config file format but follows the
> same pattern: server name, command or URL, optional
> environment variables. Claude Desktop uses
> `claude_desktop_config.json`, VS Code uses
> `.vscode/mcp.json`, Cursor uses `.cursor/mcp.json`.

**3 minutes:**

> Client integration is the deployment-side of MCP:
> how do you connect your existing MCP servers to
> the AI clients your team actually uses?
>
> Every MCP client follows the same conceptual
> configuration: for each server, specify how to
> start or reach it (command+args for stdio, URL
> for HTTP), and any credentials it needs (env vars
> for stdio, auth headers for HTTP).
>
> Claude Desktop: the global config file connects
> to servers for all conversations. All tools from
> all configured servers are available in every chat.
>
> VS Code GitHub Copilot: uses `.vscode/mcp.json`
> in the workspace root. Server connections are
> scoped to the workspace. The workspace-specific
> config enables different MCP servers per project
> (the frontend project has browser automation tools;
> the backend project has database tools).
>
> Cursor: `.cursor/mcp.json` at the workspace root.
> Similar to VS Code's workspace-scoped approach.
>
> The key workflow: configure client -> restart client
> -> verify server appears (green status) -> test
> a tool -> debug any connection issues.

**Blank Mind Recovery:**

**(1) Restate:** "MCP client integration - configuring
AI clients to connect to servers."

**(2) First principles:** "The client needs to know:
where the server is (command or URL), and what
credentials to pass. That's the entire config."

**(3) Bridge:** "Like configuring database connections:
host, port, credentials. Each client has its own
config file format but the same concepts."

---

### 📘 Concept Explanation

**What it is:**

MCP client integration is the configuration of
MCP-compatible AI client applications to connect
to and use MCP servers.

**The problem it solves:**

Knowing how to BUILD an MCP server is not sufficient.
Deploying it requires knowing how each client expects
the server to be configured, including connection
parameters, credentials, and environment setup.

**How it works:**

```
CLIENT CONFIG LOCATIONS:

Claude Desktop:
  macOS: ~/Library/Application Support/Claude/
         claude_desktop_config.json
  Windows: %APPDATA%\Claude\claude_desktop_config.json

VS Code (workspace-scoped):
  .vscode/mcp.json

Cursor (workspace-scoped):
  .cursor/mcp.json

Continue (VS Code extension):
  ~/.continue/config.yaml -> mcpServers section

FORMAT (Claude Desktop):
{
  "mcpServers": {
    "server-name": {
      "command": "python",
      "args": ["/path/to/server.py"],
      "env": {"API_KEY": "..."}
    }
  }
}

FORMAT (VS Code .vscode/mcp.json):
{
  "mcpServers": {
    "server-name": {
      "command": "python",
      "args": ["${workspaceFolder}/server.py"],
      "env": {}
    }
  }
}

FORMAT (HTTP server - any client):
{
  "mcpServers": {
    "server-name": {
      "url": "https://my-mcp-server.com/mcp",
      "headers": {
        "Authorization": "Bearer ${MY_API_KEY}"
      }
    }
  }
}
```

> **Code walkthrough:** This MCP Client Integration example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

Workspace-scoped configs (VS Code, Cursor) enable
project-specific tooling. The backend project's
workspace gets the database MCP server. The frontend
project's workspace gets the browser automation
server. This is a better default than global tools
that apply to every project.

**When to use global config (Claude Desktop):**

- Tools useful for all projects (filesystem, GitHub)
- Personal productivity tools (calendar, notes)
- General-purpose search

**When to use workspace-scoped config:**

- Project-specific databases
- Project-specific APIs
- Tools that would conflict or confuse in other contexts

**Alternatives:**

- Environment variable injection via shell startup:
  not client-aware, requires manual coordination
- Direct prompt engineering: no MCP, just careful
  context injection - works but doesn't scale

**First-principles derivation:**

AI clients need a standard way to discover and
connect to servers. The config file is the registration
mechanism: it maps a server name to its connection
parameters. Different clients use different file
locations and formats but the same conceptual model.
The VS Code workspace-scoped format adds a useful
isolation layer: project-specific servers without
polluting the global tool list.

---

### 💻 Code Example

```python
"""
Example: test an MCP server programmatically using the
Python client SDK (useful for CI testing or automation).
"""
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def test_mcp_server():
    """
    Connect to an MCP server programmatically
    and call a tool. Useful for integration tests
    and automated client workflows.
    """
    server_params = StdioServerParameters(
        command="python",
        args=["server.py"],   # path to server
        env={"API_KEY": "test-key"}
    )

    async with stdio_client(server_params) as (r, w):
        async with ClientSession(r, w) as session:
            # Initialize the connection
            await session.initialize()

            # List available tools
            tools_response = await session.list_tools()
            print("Available tools:")
            for tool in tools_response.tools:
                print(f"  - {tool.name}: {tool.description[:50]}")

            # Call a tool
            result = await session.call_tool(
                "search_records",
                {"query": "alice"}
            )

            print("Tool result:")
            for content in result.content:
                if hasattr(content, 'text'):
                    print(content.text)

            return result


# For VS Code workspace-scoped config example:
VSCODE_MCP_CONFIG = {
    "mcpServers": {
        "project-db": {
            "command": "python",
            # ${workspaceFolder} is a VS Code variable
            "args": ["${workspaceFolder}/mcp-server/server.py"],
            "env": {
                "DB_URL": "${DB_URL}"  # from user env
            }
        }
    }
}

if __name__ == "__main__":
    asyncio.run(test_mcp_server())
```

> **Code walkthrough:** The MCP Python SDK includesice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> a client API (`ClientSession`) as well as the server
> API. `stdio_client(server_params)` spawns the server
> subprocess and manages the connection. `session.initialize()`
> performs the handshake. `session.list_tools()` and
> `session.call_tool()` are the client equivalents
> of the JSON-RPC protocol calls. This pattern is
> valuable for CI integration tests: automatically
> verify that the server starts, capabilities are
> correct, and tools return expected results. The
> `VSCODE_MCP_CONFIG` dictionary shows the VS Code
> workspace config format with `${workspaceFolder}`
> variable substitution - this is the pattern for
> making team configs portable across different
> checkout directories.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "MCP client integration means configuring the AI
> client app to connect to MCP servers. Claude Desktop
> uses `claude_desktop_config.json` with a `mcpServers`
> section. VS Code uses `.vscode/mcp.json` in the
> workspace. I like VS Code's workspace-scoped config:
> different projects get different servers without
> polluting the global tool list. The typical workflow
> is: add the server config, restart the client,
> verify the server shows green status, test a tool."

---

**Senior / Staff:**

> "MCP client integration has two dimensions: static
> config (which servers to connect to) and dynamic
> behavior (which tools the AI uses). The static
> config is straightforward - each client has its
> format, all follow the same conceptual model.
> The dynamic behavior is where teams need discipline:
> too many servers with overlapping tool descriptions
> confuse the AI and produce inconsistent tool selection.
> For enterprise teams, I recommend a curated 'approved
> server registry' that developers can add to workspace
> configs, with tool description standards reviewed
> before approval. The workspace-scoped VS Code
> config is the right default for development tools:
> each project gets exactly the servers it needs."

---

### ⚠️ Common Misconceptions

**Misconception: "After changing the config file,
tools appear immediately."**

MCP clients establish connections at startup. Config
changes take effect only after restarting the client
application (Claude Desktop, VS Code). The exception:
VS Code may detect workspace config changes and
prompt for a reconnect, but this is client-specific
behavior. As a rule: after any config change, restart
the client, verify the server shows a connected
status, then test a tool to confirm it's working.

---

### 🚨 Failure Modes and Diagnosis

**Failure: VS Code doesn't see MCP server from
`.vscode/mcp.json`**

*Symptom:* Server configured in workspace mcp.json
but no tools appear in Copilot Agent mode.

*Diagnosis:*

Step 1: Verify file location and name exactly:
`.vscode/mcp.json` (not `mcp.json` in root, not
`settings.json`).

Step 2: Validate JSON syntax:
```bash
python -c "import json; json.load(open('.vscode/mcp.json'))"
```
> **Code walkthrough:** This ${workspaceFolder} is a VS Code variable example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Invalid JSON silently fails.

Step 3: Check VS Code version - MCP support in
Copilot Agent Mode requires VS Code 1.87+ and
GitHub Copilot extension 1.176+.

Step 4: Verify the server command works in the
VS Code terminal (not your shell - VS Code may
have a different PATH):
```
# In VS Code integrated terminal:
python path/to/server.py
```

> **Code walkthrough:** This In VS Code integrated terminal: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Step 5: Check VS Code Output panel -> "MCP" channel
for connection errors.

*What separates good from great:* "Check the Output
panel MCP channel - VS Code logs MCP connection
errors there, not in the terminal."

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Config formats | 3-4 min |
| Workspace vs global | 3-4 min |
| HTTP client config | 3-4 min |
| Debugging | 4-5 min |
| Multi-server management | 3-4 min |
| Blank mind recovery | 1 min |

---

**[JUNIOR] Q1 - What is the config file format for
Claude Desktop MCP servers?**

*Why they ask:* Practical readiness.

Config file location:

Format:
```json
{
  "mcpServers": {
    "server-name": {
      "command": "python",
      "args": ["/absolute/path/to/server.py"],
      "env": {
        "API_KEY": "your-key",
        "DATABASE_URL": "postgres://..."
      }
    }
  }
}
```

> **Code walkthrough:** This In VS Code integrated terminal: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Multiple servers: add more entries to `mcpServers`.
Each server appears as a separate connection. All
their tools are combined in the AI's context.

Important: use absolute paths in `args`. Relative
paths are resolved from Claude Desktop's working
directory, which is not predictable.

For uvx-distributed servers:
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "uvx",
      "args": ["mcp-server-filesystem", "--allowed-dirs", "/home/user/docs"]
    }
  }
}
```

> **Code walkthrough:** This In VS Code integrated terminal: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* "Absolute paths
in args, not relative - Claude Desktop's working
directory is not your shell's cwd."

---

**[MID] Q2 - How do you configure an HTTP MCP server
in a client?**

*Why they ask:* HTTP deployment is common for team tools.

HTTP server config replaces `command`/`args` with `url`
and optional `headers`:

Claude Desktop:
```json
{
  "mcpServers": {
    "team-db": {
      "url": "https://mcp-server.company.com/mcp",
      "headers": {
        "Authorization": "Bearer my-api-key"
      }
    }
  }
}
```

> **Code walkthrough:** This In VS Code integrated terminal: example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

VS Code `.vscode/mcp.json`:
```json
{
  "mcpServers": {
    "team-db": {
      "url": "https://mcp-server.company.com/mcp",
      "headers": {
        "Authorization": "Bearer ${MCP_API_KEY}"
      }
    }
  }
}
```

> **Code walkthrough:** This In VS Code integrated terminal: example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

VS Code supports variable substitution: `${MCP_API_KEY}`
resolves from VS Code user settings or environment.

Security note: never hardcode API keys in workspace
configs that are committed to source control.
Use environment variable substitution.

*What separates good from great:* "Never hardcode
API keys in committed workspace configs - use env
var substitution."

---

**[SENIOR] Q3 - [TRADE-OFF] When do you use global
vs workspace-scoped MCP config?**

*Why they ask:* Configuration architecture.

Global config (Claude Desktop, `~/.continue/config.yaml`):
- Applies to all conversations / projects
- Best for: general-purpose tools (filesystem, web search,
  GitHub access, calendar)
- Risk: too many tools slow AI reasoning and create
  confusion from tool overlap

Workspace config (`.vscode/mcp.json`, `.cursor/mcp.json`):
- Applies to this project only
- Best for: project-specific tools (this project's database,
  this project's deployment scripts, this project's
  issue tracker)
- Benefit: reduces irrelevant tools in context;
  the AI focuses on tools relevant to the current work

Hybrid strategy (recommended):
- Global: 3-5 universal tools (filesystem, search, GitHub)
- Workspace: 1-3 project-specific tools (project DB, CI/CD)
- Total: 4-8 tools per session

Why the limit matters: the AI reasons over all
available tool descriptions at every turn. 20+ tools
with similar descriptions degrade tool selection
accuracy. Keep total tools under 10 for reliable behavior.

*What separates good from great:* "Keep total tools
under 10 - tool overload degrades AI tool selection
accuracy."

---

**[JUNIOR] Q4 - [DEBUGGING] How do you verify an
MCP server is correctly connected in Claude Desktop?**

*Why they ask:* Basic verification skill.

Four-step verification:

Step 1: Check server status. In Claude Desktop:
open the server list (in the conversation sidebar
or settings). Each configured server shows:
- Green circle: connected
- Red circle: failed to connect
- Yellow circle: connecting

Step 2: Look for tools in the tool panel. If the
server is green but no tools appear: the server's
tools/list is returning empty or the server
capabilities don't declare tools.

Step 3: Test a tool manually. Ask Claude: "What
tools do you have available?" Claude should list
the tools from the connected server.

Step 4: For deeper debugging: check the server's
log file:
```bash
# macOS:
tail -100 ~/Library/Logs/Claude/mcp-server-{server-name}.log
```

> **Code walkthrough:** This macOS: example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

If the server shows red: the command failed to start.
Check the command path and Python environment.

*What separates good from great:* "Ask Claude 'What
tools do you have available?' - it lists the actual
tool descriptions it sees, confirming end-to-end
integration."

---

**[MID] Q5 - What happens when two MCP servers
expose tools with the same name?**

*Why they ask:* Multi-server management.

MCP clients namespace tools by server. If two servers
both expose a `search` tool:
- Client A sees: `server1/search` and `server2/search`
- The client exposes them to the AI with different names
  (implementation varies by client)
- In some clients: the second server's tool overwrites
  the first's (client-specific behavior)

Best practice to avoid conflicts:

(1) Namespace tool names by server domain:
    Instead of `search`, use `docs_search` (docs server)
    and `code_search` (code server). Makes the purpose
    clear and avoids collisions.

(2) Make descriptions specific enough to differentiate:
    "Search company documentation" vs. "Search source code".
    The AI uses descriptions, not just names, to select tools.

(3) Minimize tools per session: if two servers have
    overlapping tools, consolidate them into one server
    or choose which to keep active per project.

Check your client's documentation for its specific
name collision behavior - it varies.

*What separates good from great:* "Namespace tool
names by domain - it avoids collisions and makes
tool purpose clear."

---

**[SENIOR] Q6 - How do you manage MCP server configs
across a team without committing secrets?**

*Why they ask:* Security + team operations.

Three-layer approach:

Layer 1: Commit the config template (no secrets):
```json
// .vscode/mcp.json (committed)
{
  "mcpServers": {
    "project-db": {
      "command": "uvx",
      "args": ["our-mcp-server"],
      "env": {
        "DB_URL": "${DB_URL}",
        "API_KEY": "${MCP_API_KEY}"
      }
    }
  }
}
```

> **Code walkthrough:** This macOS: example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Layer 2: `.env.local` for local secret injection:
```
# .env.local (gitignored)
DB_URL=postgres://user:password@localhost:5432/dev
MCP_API_KEY=your-dev-key
```
> **Code walkthrough:** This .env.local (gitignored) example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Source this in shell: `source .env.local` before
opening VS Code.

Layer 3: CI/CD environment variables for shared servers:
Team members with production access have their
credentials in their shell's environment. No secret
in any config file.

Additional: use a secrets manager (1Password, Bitwarden,
AWS Secrets Manager) and `op run --env-file` to
inject secrets at runtime.

*What separates good from great:* "`op run --env-file`
for secrets manager injection - team members use
the same config, secrets are centrally managed."

---

**[JUNIOR] Q7 - How do you share MCP server configs
with a team?**

*Why they ask:* Team setup workflow.

For workspace-scoped configs:

(1) Commit `.vscode/mcp.json` and `.cursor/mcp.json`
    with variable-substituted secrets (see Q6).
    Everyone clones the repo and gets the config.

(2) Add setup instructions to the README:
    ```
    ## MCP Setup
    1. Install: uvx mcp-server-name
    2. Set env vars (copy .env.example to .env.local):
       DB_URL=...
       MCP_API_KEY=...
    3. Restart VS Code
    4. Verify: open Copilot Agent, check tool list
    ```

> **Code walkthrough:** This .env.local (gitignored) example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

(3) Add `.env.example` with dummy values (committed)
    and `.env.local` in `.gitignore` (not committed).

For global configs (Claude Desktop):

Document the config to add in a team wiki or README.
Teammates manually add the `mcpServers` entries
to their local `claude_desktop_config.json`.

The more portable approach: deploy the server as
an HTTP server with team-wide URL. Each teammate
adds the same URL + their personal API key to
their global config. No per-user command paths.

*What separates good from great:* "HTTP server URL
in global config: one central URL for the team,
no per-user command paths to manage."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ concept.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ concept.)*

---

### 📊 Diagram

*(Omit: client config is best expressed as code examples.)*

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



