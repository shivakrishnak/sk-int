---
layout: default
title: "MCP - L1 Core Concepts"
parent: "MCP"
nav_order: 2
permalink: /mcp/l1-core-concepts/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 4 | [MCP Tools](#mcp-tools) | ★☆☆ |
| 5 | [MCP Resources](#mcp-resources) | ★☆☆ |
| 6 | [MCP Prompts](#mcp-prompts) | ★☆☆ |

---

# MCP Tools

**Interview Weight:** ★☆☆ - Tools are the most
commonly implemented MCP primitive. Every MCP
practitioner must understand the tool model deeply.

---

### 🎯 Model Answer

**30 seconds:**

> MCP Tools are the action primitive: callable
> functions the AI can invoke with typed arguments.
> They are defined with a name, description, and
> JSON Schema input specification. The AI uses the
> description to decide when to call the tool and
> the schema to construct valid arguments. Tools
> can have side effects (write files, call APIs,
> modify state) unlike Resources which are read-only.

**3 minutes:**

> MCP Tools are the most important primitive for
> AI capability extension. A tool has three required
> parts: a name (unique within the server), a description
> (the AI reads this to decide when to call it),
> and an inputSchema (JSON Schema defining valid
> arguments).
>
> The tool description is the most critical field.
> The AI's decision to call a tool is driven entirely
> by matching user intent to tool descriptions.
> A vague description ("does things with data") causes
> the AI to miss the tool. A precise description
> ("searches the company knowledge base for technical
> documentation, returns the top 5 matching passages")
> enables reliable tool selection.
>
> When a tool is invoked, the server receives the
> tool name and arguments, executes the tool, and
> returns a result. Results can be text content,
> image content, or embedded resources. Tool errors
> can be returned as `isError: true` content or
> as JSON-RPC protocol errors.
>
> Tool annotations (MCP 2025-03): optional metadata
> about a tool's behavior. `readOnlyHint: true` signals
> the tool has no side effects. `destructiveHint: true`
> signals the tool modifies or deletes data.
> `idempotentHint: true` signals repeated calls with
> the same arguments produce the same result. These
> annotations help clients implement confirmation
> dialogs or audit logging.

**Blank Mind Recovery:**

**(1) Restate:** "MCP Tools are the action primitive -
callable functions the AI can invoke."

**(2) First principles:** "The AI needs a way to
call external functions. Tools provide: a name to
call, a description to know when to call it, and
a schema to construct valid arguments."

**(3) Bridge:** "Think of function definitions in
a type-checked language: the function signature
(schema) validates inputs, the docstring (description)
tells developers when to use it, and the body
(your implementation) does the work."

---

### 📘 Concept Explanation

**What it is:**

An MCP Tool is a callable action exposed by an MCP
server that the AI can invoke with typed JSON arguments.
Tools are the equivalent of function calls in the
MCP model - they can have side effects and return
results to the AI.

**The problem it solves:**

AI assistants need to take actions in the world:
search, query, write, post. Without a standard
tool definition format, every action requires a
custom integration per AI platform. MCP Tools
provide a single definition format that any MCP
client translates to its AI's native capability.

**How it works:**

```
TOOL LIFECYCLE:

Server startup:
  tools/list -> returns [{name, description, inputSchema}]

AI decides to call a tool:
  tools/call -> {name, arguments}
             <- {content: [...], isError: false/true}

Tool result types:
  TextContent:  {type: "text", text: "..."}
  ImageContent: {type: "image", data: "base64...", mimeType}
  EmbeddedResource: {type: "resource", resource: {uri, ...}}

Error handling:
  Tool execution error -> isError: true in content
    (AI sees the error and can respond)
  Protocol error -> JSON-RPC error response
    (connection/format problem, not a tool error)
```

> **Code walkthrough:** This MCP Tools example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

The tool description drives AI behavior. The AI
reads all tool descriptions at context-load time
and uses them to route user requests. A tool that
is never called despite being registered almost
always has a poor description. Invest heavily in
writing descriptions that precisely match the
intent patterns your users will express.

**When to use it:**

- Actions with side effects (creating, modifying,
  deleting records)
- Computations that require external data or processing
- Any operation the AI should perform in the world
  (query, search, send, generate)

**When NOT to use it:**

- Read-only data access where Resources are more
  appropriate (file content, static records)
- Data the AI needs as background context (include
  in system prompt or as Resource)
- One-time setup operations (use server initialization)

**Alternatives:**

- Resources: for read-only data access without
  side effects
- Prompts: for pre-built workflow templates
- Direct system prompt injection: for static context
  that doesn't change between calls

**First-principles derivation:**

AI assistants need action capability. The action
must be: discoverable (tools/list), described
(the AI must know when to call it), validated
(schema ensures valid arguments), and executed
(server performs the action). These four requirements
map directly to MCP's tools/list + description +
inputSchema + call_tool implementation pattern.

---

### 💻 Code Example


```python
# BAD: anti-pattern - see GOOD example below
```

```python
from mcp.server import Server
from mcp.server.models import InitializationOptions
import mcp.types as types
import anthropic
import json

server = Server("tools-demo")

# BAD: Tool with vague description
# The AI will rarely invoke this correctly.
BAD_TOOL = types.Tool(
    name="process",
    description="Process data",   # TOO VAGUE
    inputSchema={
        "type": "object",
        "properties": {
            "data": {"type": "string"}
        }
    }
)

# GOOD: Tool with precise, intent-matching description
GOOD_TOOL = types.Tool(
    name="search_knowledge_base",
    description=(
        "Search the company knowledge base for "
        "technical documentation, how-to guides, "
        "and policies. Returns the top matching "
        "passages with source URLs. Use when the "
        "user asks about internal processes, tools, "
        "or company-specific technical questions."
    ),
    inputSchema={
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": (
                    "Natural language search query. "
                    "Use specific terms for better results."
                )
            },
            "max_results": {
                "type": "integer",
                "description": "Max results to return (1-10)",
                "default": 5
            }
        },
        "required": ["query"]
    }
)


@server.list_tools()
async def list_tools() -> list[types.Tool]:
    return [GOOD_TOOL]


@server.call_tool()
async def call_tool(
    name: str, arguments: dict
) -> list[types.TextContent]:
    if name == "search_knowledge_base":
        query = arguments.get("query", "")
        max_results = arguments.get("max_results", 5)

        # In production: call your search system
        # This simulates a result
        results = [
            {
                "title": f"Guide: {query}",
                "url": "https://wiki.company.com/...",
                "excerpt": f"Documentation about {query}..."
            }
        ]

        return [types.TextContent(
            type="text",
            text=json.dumps(results[:max_results],
                           indent=2)
        )]

    # Proper error: tool execution error, not protocol error
    return [types.TextContent(
        type="text",
        text=f"Unknown tool: {name}",
    )]
    # Note: isError is set when using ErrorContent
    # For protocol errors: raise McpError(...)


# Example: calling Claude with this tool via API
def call_claude_with_tool():
    client = anthropic.Anthropic()
    resp = client.messages.create(
        model="claude-haiku-4-5",
        max_tokens=256,
        tools=[{
            "name": GOOD_TOOL.name,
            "description": GOOD_TOOL.description,
            "input_schema": GOOD_TOOL.inputSchema
        }],
        messages=[{
            "role": "user",
            "content": "How do I set up the CI pipeline?"
        }]
    )
    return resp
```

> **Code walkthrough:** The BAD example has a genericice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> tool name and description ("Process data") - the
> AI cannot determine when to call this tool without
> specific intent-matching language. The GOOD example
> uses a description that names the data source
> (company knowledge base), the content type (technical
> documentation, how-to guides, policies), return
> format (top matching passages with URLs), and
> invocation trigger (user asks about internal processes).
> This gives the AI everything it needs to route
> user requests correctly. The inputSchema includes
> property-level descriptions that help the AI
> construct valid arguments. The error handling
> returns a TextContent response (tool-level error
> that the AI can see and reason about) rather than
> raising an exception (protocol-level error that
> the AI cannot handle gracefully).

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "MCP Tools are callable actions the AI can invoke
> with typed arguments. Each tool has three parts:
> a name, a description (the AI reads this to decide
> when to call the tool), and an inputSchema (JSON
> Schema defining valid arguments). Tools can have
> side effects - that's what distinguishes them from
> Resources which are read-only. The most important
> thing I've learned: invest heavily in the description.
> If the AI never calls a tool, the description
> is almost always the problem."

---

**Senior / Staff:**

> "MCP Tools are the foundation of AI capability
> extension. The architectural insight: the tool
> description is the contract between the server
> author and the AI reasoning engine. The AI uses
> description-to-intent matching to decide which
> tool to call. For production systems, I treat
> tool descriptions as first-class API documentation
> and iterate on them based on actual tool invocation
> logs. Tool annotations (2025-03 spec) add a safety
> layer: `readOnlyHint` enables clients to skip
> confirmation for safe tools, `destructiveHint`
> triggers confirmation dialogs. For enterprise
> deployment, I always annotate tools with their
> safety level - it enables clients to implement
> appropriate access controls without server changes."

---

### ⚠️ Common Misconceptions

**Misconception: "Any tool name and description
will work as long as the implementation is correct."**

The AI uses the description to DECIDE whether to
invoke a tool. A correct implementation with a poor
description means the tool is never called. In
production RAG with MCP tools, "tool never invoked"
is the most common failure mode - and the fix is
always the description, not the implementation.
Treat the description as the primary interface.
Write it before writing the implementation.
Test it by asking an AI "when would you call this
tool and why?" and iterate until the answer matches
your intent.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Tool is registered but the AI never calls it**

*Symptom:* The server is connected, tools/list
returns the tool, but the AI answers without
invoking the tool even when the tool would clearly help.

*Diagnosis:*

1. Test the description directly: ask Claude
   "Given this tool description: '[paste description]',
   when would you call this tool and what query
   would trigger it?" If Claude cannot give a clear
   answer, the description needs work.

2. Check for conflicting tools: if another tool
   has a similar description, the AI may consistently
   prefer it. Make descriptions distinct.

3. Verify tools/list response: some clients silently
   drop tools with invalid schemas. Test manually:
   send a tools/list request and validate the
   returned schema.

4. Check client tool limits: some clients limit
   the number of tools the AI sees simultaneously.
   If too many tools are registered, some may be
   dropped.

*Fix:* Rewrite the description to be more specific
and to match the exact user intent patterns you
expect. Add "Use this tool when the user asks about
[specific scenarios]" language.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Definition / structure | 2-3 min |
| Description quality | 3-4 min |
| Schema design | 3-4 min |
| Debugging | 4-5 min |
| Error handling | 3-4 min |
| Trade-off | 3-4 min |
| Blank mind recovery | 1 min |

---

**[JUNIOR] Q1 - What are the three required fields
of an MCP Tool definition?**

*Why they ask:* Baseline knowledge.

(1) `name`: unique identifier for the tool within
    the server. Used in tools/call to specify which
    tool to invoke. Convention: snake_case, descriptive
    verb-noun format (e.g., `search_docs`, `create_issue`,
    `execute_query`).

(2) `description`: natural language description of
    what the tool does and when to use it. The AI
    reads this to decide whether to call the tool.
    This is the most important field - write it
    as if describing the tool to a thoughtful
    colleague who needs to know WHEN to call it.

(3) `inputSchema`: JSON Schema object defining
    valid arguments. Must be `type: object`. Properties
    define individual parameters with their types
    and descriptions. `required` lists mandatory params.

Optional but important: property-level `description`
fields within the inputSchema. These help the AI
construct valid arguments for each parameter.

*What separates good from great:* "The description
is the most important field - it drives when the
AI calls the tool."

---

**[MID] Q2 - [DEBUGGING] Your tool is being called
but always with missing or wrong arguments. What do you check?**

*Why they ask:* Schema debugging skills.

Three areas:

(1) Property descriptions: does each required property
    have a clear description explaining what to pass?
    Without property descriptions, the AI guesses.
    Example - BAD:
    ```json
    "properties": {
      "start_date": {"type": "string"}
    }
    ```
> **Code walkthrough:** This Example: calling Claude with this tool via API example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

    GOOD:
    ```json
    "properties": {
      "start_date": {
        "type": "string",
        "description": "Start date in ISO 8601 format: YYYY-MM-DD"
      }
    }
    ```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

(2) Required field precision: if a parameter is
    optional (has a sensible default), don't put
    it in `required`. If it's mandatory, do. The AI
    will attempt to construct values for required
    fields even when it doesn't have them, leading
    to hallucinated values.

(3) Enum values for constrained fields: if a parameter
    only accepts specific values, use enum:
    ```json
    "type": {"type": "string", "enum": ["create", "update", "delete"]}
    ```
> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

    Without enum, the AI invents values.

*What separates good from great:* "Use enum for
constrained fields - without it the AI invents
values."

---

**[SENIOR] Q3 - [TRADE-OFF] When should a tool
return structured JSON vs. plain text?**

*Why they ask:* API design judgment.

Return structured JSON when:
- The AI needs to reason over the result (e.g.,
  compare values, filter records, count items)
- The result is a list of items the AI will present
  formatted
- Downstream tools or workflows depend on the result

Example: a query returning user records. If returned
as JSON, the AI can say "User #12345 has 3 open
tickets." If returned as plain text, the AI must
parse the text first.

Return plain text when:
- The result is a narrative or explanation
- The AI should use it as-is (no further reasoning needed)
- Formatting would be lost in text (complex tables)

Best practice: return structured data (JSON string
in TextContent) when the AI needs to reason over it.
Return plain text when the AI should display it.

```python
# For structured results (AI will reason over it):
return [types.TextContent(
    type="text",
    text=json.dumps({"users": [...], "count": 5})
)]

# For narrative results (AI displays as-is):
return [types.TextContent(
    type="text",
    text="Found 5 users in the system: Alice, Bob..."
)]
```

> **Code walkthrough:** This For narrative results (AI displays as-is): example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

*What separates good from great:* "Return JSON when
the AI needs to reason over the result; plain text
when it displays it directly."

---

**[JUNIOR] Q4 - What is the difference between a
tool execution error and a protocol error in MCP?**

*Why they ask:* Error model understanding.

Tool execution error: something went wrong in your
tool's business logic. The server executed the
tool but it failed (database error, API timeout,
invalid query result). Return these as TextContent
with `isError: true`:
```python
return [types.TextContent(
    type="text",
    text="Error: Database connection failed"
)], True  # isError=True
```
> **Code walkthrough:** This For narrative results (AI displays as-is): example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

The AI receives this as tool output. It can see
the error message and decide how to respond (try
again, ask the user for help, use a different tool).

Protocol error: something went wrong at the MCP
layer before tool execution (invalid JSON-RPC format,
unknown method, missing required params). Return
these as JSON-RPC error responses (raise McpError
in the Python SDK). The AI does NOT see the error
content - it's a communication failure.

Rule: use tool execution errors for business logic
failures. Use protocol errors only for genuine
protocol violations.

*What separates good from great:* "Tool execution
errors are visible to the AI; protocol errors are not."

---

**[MID] Q5 - What are MCP Tool annotations and
why do they matter for production deployments?**

*Why they ask:* Tests knowledge of the 2025-03 spec additions.

Tool annotations (added in MCP spec 2025-03) are
optional metadata hints that describe tool behavior:

`readOnlyHint`: this tool has no side effects. Safe
to call without confirmation. Example: `search_docs`,
`get_weather`, `list_files`.

`destructiveHint`: this tool modifies or deletes
data. Example: `delete_record`, `drop_table`.

`idempotentHint`: calling this tool multiple times
with the same arguments produces the same result.
Example: `set_configuration` (not additive, just sets).

`openWorldHint`: the tool may interact with external
systems beyond the MCP server (web requests, email).

Why they matter in production:

(1) Client confirmation dialogs: a client can show
    "Are you sure you want to delete this record?"
    for `destructiveHint: true` tools. Read-only
    tools execute without confirmation.

(2) Audit logging: clients can automatically flag
    and log `destructiveHint: true` invocations for
    compliance or review.

(3) Retry logic: `idempotentHint: true` tools are
    safe to retry on failure; non-idempotent ones
    may have partial effects if retried.

*What separates good from great:* "Annotations
enable the client to implement access controls
without server changes."

---

**[SENIOR] Q6 - [BEHAVIORAL] Describe a time you
designed or improved an MCP tool's definition to
fix a real problem.**

*Why they ask:* Production experience.

Situation: built a knowledge base search MCP server
for an engineering team. The tool was registered
and the server was connected, but during testing
the AI consistently answered knowledge base questions
from its training data instead of calling the search tool.

Diagnosis: the tool description was "Search the knowledge base"
- too short and generic. The AI's training data
contained many similar concepts and it defaulted
to its own knowledge.

Fix (iterative description improvement):

Iteration 1: "Search the company's internal knowledge
base for engineering documentation."
Result: AI called it sometimes but not for policy questions.

Iteration 2: "Search [CompanyName]'s internal Confluence
knowledge base for engineering documentation, policies,
processes, and how-to guides. This is the authoritative
source for company-specific information. Use this
for any question about internal tools, processes,
policies, or company-specific technical details."
Result: AI called it reliably for all internal questions.

Key additions that made the difference:
- Specific source name (Confluence)
- "Authoritative source" framing
- Explicit trigger conditions ("internal tools, processes")
- Signal that training data is insufficient for these

Lesson: think about what the AI needs to hear to
PREFER your tool over its training knowledge.

*What separates good from great:* "Authoritative
source framing - explicitly signaling why the tool
is preferred over training data."

---

**[JUNIOR] Q7 - How do you test an MCP tool in isolation?**

*Why they ask:* Testing skills.

Three levels of testing:

Level 1: Unit test the handler function directly:
```python
import asyncio
from your_server import call_tool

async def test_search():
    result = await call_tool(
        "search_knowledge_base",
        {"query": "CI pipeline setup"}
    )
    assert len(result) > 0
    assert result[0].type == "text"
    assert "CI" in result[0].text

asyncio.run(test_search())
```

> **Code walkthrough:** This For narrative results (AI displays as-is): example demonstrates asyncio coroutine definition using async/await. **KEY MECHANISM:** the event loop schedules coroutines; await suspends execution until the awaited future resolves. **WHY IT MATTERS:** blocking call inside async def starves the event loop - all coroutines freeze. **TAKEAWAY: never use blocking I/O (requests, time.sleep) inside async def; use aiohttp, asyncio.sleep.**

Level 2: Test the JSON-RPC protocol directly:
```bash
# Start server, send raw MCP message via stdin:
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call",
"params":{"name":"search_knowledge_base",
"arguments":{"query":"CI pipeline"}}}' | python server.py
```
> **Code walkthrough:** This Start server, send raw MCP message via stdin: example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Verify the JSON-RPC response format.

Level 3: Integration test via MCP inspector:
The official MCP Inspector tool
(npx @modelcontextprotocol/inspector) provides
a UI for connecting to servers and testing tools
interactively.

For CI: use Level 1 (unit tests on handlers) +
Level 2 (JSON-RPC protocol test) as automated
pre-commit checks.

*What separates good from great:* "MCP Inspector
for interactive manual testing, unit tests for
automated CI."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ concept.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ concept.)*

---

### 📊 Diagram

*(Omit: tool lifecycle is well-expressed as text.)*

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


# MCP Resources

**Interview Weight:** ★☆☆ - Resources are the read-only
data primitive. Understanding when to use Resources
vs Tools is a key design decision in every MCP server.

---

### 🎯 Model Answer

**30 seconds:**

> MCP Resources are read-only data sources identified
> by URIs that the AI can access for context. Unlike
> Tools (which invoke actions), Resources only expose
> data - they have no side effects. Examples: a file's
> contents at `file:///path/to/file.txt`, a database
> record at `postgres://db/users/12345`, or a documentation
> page at `wiki://pages/auth-setup`. Resources are
> safer than Tools: a client granting resource access
> cannot accidentally trigger writes.

**3 minutes:**

> Resources are the MCP primitive for providing the
> AI with access to data without enabling action.
> They solve the "I need the AI to read this document"
> problem without the risk of "accidentally writing
> to it."
>
> Resources have two required parts: a URI (a unique
> identifier for the resource - can be any URI format,
> not just HTTP) and a MIME type (telling the client
> how to interpret the content).
>
> The resource content is returned as text (for
> structured or plain text data) or base64-encoded
> blob (for binary data like images or PDFs).
>
> Resources also support listing: the `resources/list`
> call returns all available resources with their
> URIs and descriptions. This enables the AI to
> discover what data is available before accessing
> it.
>
> Resource subscriptions (optional capability): the
> client can subscribe to a resource and receive
> notifications when it changes. This enables near-real-time
> data freshness for resources that update frequently.
>
> The key design decision: use a Resource when the
> AI should read data without modifying it, and use
> a Tool when the AI needs to compute over or transform
> data. A file's contents: Resource. A query that
> searches and filters the file: Tool.

**Blank Mind Recovery:**

**(1) Restate:** "MCP Resources are the read-only
data primitive - the AI can read them but not modify them."

**(2) First principles:** "The AI needs access to
data. The safest access mode is read-only. Resources
provide this: identifiable by URI, content accessible
on demand, no side effects."

**(3) Bridge:** "Like HTTP GET vs POST: Resources
are GET-only. Tools are POST. The distinction
enforces read-only access at the protocol level."

---

### 📘 Concept Explanation

**What it is:**

An MCP Resource is a read-only data object identified
by a URI that an MCP server exposes for AI access.
Resources provide the AI with context and information
without enabling write operations or side effects.

**The problem it solves:**

AI assistants need context: "What does this file
contain?", "What's the current database record?",
"What does this documentation page say?" Using a
Tool for read-only data access adds unnecessary
risk (Tools CAN have side effects; the AI might
call the wrong method). Resources provide guaranteed
read-only access at the protocol level.

**How it works:**

```
RESOURCE TYPES:

TEXT RESOURCE (most common):
  URI: "file:///home/user/config.yaml"
  content: {
    uri: same URI,
    mimeType: "text/plain",
    text: "contents of the file..."
  }

BLOB RESOURCE (binary):
  URI: "image://screenshots/ui-2025.png"
  content: {
    uri: same URI,
    mimeType: "image/png",
    blob: "base64-encoded-data..."
  }

RESOURCE LISTING:
  resources/list -> [
    {
      uri: "file:///docs/README.md",
      name: "Project README",
      description: "...",
      mimeType: "text/markdown"
    },
    ...
  ]

RESOURCE ACCESS:
  resources/read {uri: "file:///docs/README.md"}
  -> {contents: [{uri, mimeType, text}]}

RESOURCE SUBSCRIPTIONS (optional):
  resources/subscribe {uri: "..."}
  -> notifications/resources/updated when changed
```

> **Code walkthrough:** This MCP Resources example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

Resources and Tools have different safety profiles.
A Resource is a safe default for data access: the
worst it can do is expose data. A Tool can have
write side effects. When designing an MCP server,
default to Resources for data access and only use
Tools when the operation modifies state or requires
computation.

**When to use it:**

- File contents the AI should reference (documentation,
  config, source code)
- Database records the AI should read without querying
- Dynamic content that changes (subscription pattern)
- Large data the AI needs as context

**When NOT to use it:**

- Data that requires filtering or searching (use a
  Tool with the query as an argument)
- Write operations of any kind (use a Tool)
- Data that must be computed or aggregated (use a Tool)

**Alternatives:**

- System prompt injection: for small, static context
  that doesn't change between requests
- Tool with read-only implementation: works but
  loses the semantic safety signal of Resources
- RAG retrieval: for large knowledge bases where
  the AI should retrieve relevant subsets

**First-principles derivation:**

AI needs data access. The safety requirement is
read-only access (the AI should not accidentally
modify data it's only supposed to read). HTTP has
this: GET is safe, POST is not. Resources are the
MCP equivalent of GET: URI-identified, content-returning,
no side effects guaranteed at the protocol level.

---

### 💻 Code Example


```python
# BAD: anti-pattern - see GOOD example below
```

```python
from mcp.server import Server
import mcp.types as types
import json
from pathlib import Path

server = Server("resources-demo")

DOCS_DIR = Path("/path/to/docs")


# GOOD: Resources for read-only file access
@server.list_resources()
async def list_resources() -> list[types.Resource]:
    """Expose documentation files as resources."""
    resources = []
    if DOCS_DIR.exists():
        for f in DOCS_DIR.glob("*.md"):
            resources.append(types.Resource(
                uri=f"file://{f.absolute()}",
                name=f.name,
                description=f"Documentation: {f.stem}",
                mimeType="text/markdown"
            ))
    return resources


@server.read_resource()
async def read_resource(
    uri: str
) -> types.ReadResourceResult:
    """Return resource content by URI."""
    # Validate URI is within allowed directory
    path = Path(uri.replace("file://", ""))
    try:
        # Security: resolve and verify no path traversal
        resolved = path.resolve()
        allowed = DOCS_DIR.resolve()
        resolved.relative_to(allowed)  # raises if outside
    except ValueError:
        raise ValueError(f"Path outside allowed dir: {uri}")

    if not resolved.exists():
        raise FileNotFoundError(f"Resource not found: {uri}")

    content = resolved.read_text(encoding="utf-8")
    return types.ReadResourceResult(
        contents=[
            types.TextResourceContents(
                uri=uri,
                mimeType="text/markdown",
                text=content
            )
        ]
    )


# BAD: Using a Tool for read-only data access
# (works, but loses the safety semantics)
@server.list_tools()
async def list_tools() -> list[types.Tool]:
    return [types.Tool(
        name="read_doc",  # BAD: read-only should be Resource
        description="Read a documentation file",
        inputSchema={
            "type": "object",
            "properties": {"path": {"type": "string"}},
            "required": ["path"]
        }
    )]
# Resources are the right primitive for read-only access.
# Tools with side-effect-free implementations work
# but lose the client-level safety guarantees.
```

> **Code walkthrough:** The `list_resources()` handlerice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> scans a directory and exposes each markdown file
> as a Resource with a `file://` URI. The `read_resource()`
> handler validates that the requested URI is within
> the allowed directory (path traversal protection -
> critical for any file-access server). It then reads
> and returns the file content. Notice the security
> check: `resolved.relative_to(allowed)` raises
> ValueError if the path tries to escape the docs
> directory via `../` sequences. The BAD example
> shows the same access as a Tool - it works functionally
> but loses the read-only semantic guarantee. A client
> that wants to grant read-only access to documentation
> must allow ALL tools (including write tools) if
> the read access is implemented as a Tool. With
> Resources, a client can grant resource-only access
> safely.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "MCP Resources are the read-only data primitive.
> They're identified by URIs (like file:// or database://
> URIs) and return content as text or binary. The
> key distinction from Tools: Resources have no side
> effects. The AI can only read them. When I design
> an MCP server, I default to Resources for data
> the AI needs to read, and only use Tools when
> the operation writes, transforms, or has side effects.
> Resources also support subscriptions - the client
> gets notified when a resource changes."

---

**Senior / Staff:**

> "The Resource primitive is the correct abstraction
> for providing AI with read-only access to data.
> The architectural value: a tiered access model.
> A resource-only MCP server can be safely deployed
> with no risk of write operations. A tool+resource
> server requires more careful access control. For
> enterprise security models, I always model the
> access tiers explicitly: 'read-only resources for
> observers, tools for operators.' The subscription
> mechanism (resources/subscribe) is underused but
> powerful for near-real-time context: a dashboard
> resource that updates on subscription changes means
> the AI always has current state without polling.
> The security consideration that's often missed:
> resources can expose sensitive data. Apply the
> same access controls (auth, filtering, field-level
> masking) to Resources as you would to any read API."

---

### ⚠️ Common Misconceptions

**Misconception: "Resources are just Tools without
side effects - there's no real difference."**

The difference is semantic AND functional. Semantically:
the read-only guarantee is part of the MCP protocol
contract, not just your implementation. A client
can grant resource-only access with confidence -
no server code changes can turn a Resource into
a write operation. Functionally: Resources support
subscriptions (push notifications on change) and
URI-based discovery (resources/list returns URI
templates). Tools do not support subscriptions.
Resources are also the correct layer for embedding
in multi-modal content (image resources, PDF resources)
via EmbeddedResource content types.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Resource read returns stale data**

*Symptom:* The AI references outdated information
from a resource even after the underlying data was
updated.

*Root cause:* The MCP client caches resource content
and does not re-read on every access. Or the server's
resource implementation caches the content at
server startup.

*Diagnosis:*
1. Check if the server implementation reads from
   source on every `read_resource()` call or caches
   at startup.
2. Check if the client has a resource cache with
   a long TTL.
3. Test: update the underlying data, then call
   `resources/read` directly via JSON-RPC and check
   if the new content is returned.

*Fix:*
- Server side: always read from the source on
  `read_resource()`. Cache only if the source is
  slow AND you implement cache invalidation.
- Client side: use resource subscriptions
  (`resources/subscribe`) to receive update
  notifications when the resource changes.
- Both: set a short TTL on any cache and include
  the `last_modified` timestamp in the resource
  description for transparency.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Definition / comparison to Tools | 2-3 min |
| URI design | 3-4 min |
| Subscription model | 3-4 min |
| Security | 4-5 min |
| Trade-off | 3-4 min |
| Blank mind recovery | 1 min |

---

**[JUNIOR] Q1 - What are MCP Resources and how do
they differ from Tools?**

*Why they ask:* Core data model.

Resources: read-only data objects identified by
URIs. The AI accesses them to read content (file,
record, page). No side effects.

Tools: callable actions with typed arguments. Can
have side effects (write, modify, delete).

Key differences:

| Aspect | Resource | Tool |
|---|---|---|
| Side effects | None (read-only) | Possible |
| Invocation | URI-based read | Name+arguments call |
| Discovery | resources/list | tools/list |
| Update notifications | Subscriptions | Not supported |
| Content types | Text, blob | Arbitrary return |

When to use each:
- AI should read a document: Resource
- AI should search and filter documents: Tool
- AI should create or modify: Tool (never Resource)

*What separates good from great:* "Resources support
subscriptions - Tools do not."

---

**[MID] Q2 - What URI schemes are used in MCP
Resources and how do you design them?**

*Why they ask:* Resource URI design is a practical skill.

MCP Resources can use any URI scheme - there is no
restriction to `http://` or `file://`. Common patterns:

```
Filesystem:
  file:///home/user/docs/README.md

Database records:
  postgres://mydb/users/12345
  mysql://orders/2025-01-15

Platform-specific:
  github://repos/my-org/my-repo/README.md
  confluence://pages/auth-setup-guide
  jira://tickets/PROJ-1234

Computed/virtual:
  memory://agent/session/summary
  cache://query-results/abc123
```

> **Code walkthrough:** This but lose the client-level safety guarantees. example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

URI design guidelines:

(1) Make URIs stable: the same resource should have
    the same URI across requests. Don't include
    timestamps or request IDs in URIs.

(2) Make URIs descriptive: a human (or AI) should
    be able to infer the content from the URI.

(3) Support templates for collections:
    `resources/list` can return URI templates
    (`postgres://mydb/users/{id}`) that the client
    can use to construct specific resource URIs.

(4) Use scheme-first organization: group resources
    by logical namespace using the URI scheme.

*What separates good from great:* "URI templates
for collections - one template, many resources."

---

**[SENIOR] Q3 - What is resource subscription in
MCP and when should you implement it?**

*Why they ask:* Tests depth beyond the basics.

Resource subscriptions: after a client calls
`resources/subscribe {uri}`, the server can send
`notifications/resources/updated {uri}` messages
when the resource changes. The client re-reads
the resource to get the new content.

Use cases:
- Live configuration files: subscribe to
  `file:///config.yaml`. When the config changes,
  the AI's context updates automatically.
- Database records: subscribe to a user record.
  When the account state changes, the AI sees
  the current state.
- Dashboard data: subscribe to aggregated metrics.
  The AI's "current state" of the system stays fresh.

Implementation requirements:
- Server must have a mechanism to detect changes
  (file watcher, database triggers, polling)
- Server must maintain a subscriber list per resource
- Server must send notifications when changes occur

When NOT to implement subscriptions:
- Resource changes very infrequently (daily/weekly):
  re-read on every request is simpler
- Resource is write-once (static documentation):
  no notifications needed
- Server has no change detection mechanism:
  don't fake subscriptions with polling if the
  cost isn't justified

*What separates good from great:* "Subscriptions
require server-side change detection - only implement
if you have a reliable change signal."

---

**[JUNIOR] Q4 - [DEBUGGING] A file resource returns
404 even though the file exists. What do you check?**

*Why they ask:* Basic debugging.

Step 1: Verify the URI format. The `file://` URI
must use the full absolute path:
`file:///home/user/docs/README.md` (three slashes:
two for protocol, one for path root).

Step 2: Verify the path in the resources/list response.
Does the URI returned by `resources/list` match
the URI being used in `resources/read`? Trailing
slashes, encoding differences, and case sensitivity
can cause mismatches.

Step 3: Check the server's allowed directory
restriction. Most file resource implementations
restrict access to specific directories. Verify
the requested file is within the allowed directory.

Step 4: Check file permissions. The server process
must have read access to the file. On Linux/macOS:
`ls -la /path/to/file`. On Windows: check NTFS
permissions for the server's running user.

Step 5: Test with a URI that definitely exists
(something you can confirm is in the allowed
directory) to isolate whether the issue is
the specific file or the implementation.

*What separates good from great:* "Three slashes
in file:// URIs - file:///absolute/path, not file://path."

---

**[SENIOR] Q5 - What security controls should
every MCP file resource server implement?**

*Why they ask:* Security awareness.

Four mandatory controls:

(1) Directory allowlist: only expose resources
    within explicitly configured directories.
    Never expose the entire filesystem.

(2) Path traversal protection: after resolving
    the URI to a filesystem path, verify the resolved
    path is still within the allowed directory.
    `../` sequences in URIs can escape the directory.
    Use `Path.resolve()` then `relative_to()` to detect:
    ```python
    resolved = path.resolve()
    allowed = allowed_dir.resolve()
    resolved.relative_to(allowed)  # raises if outside
    ```

> **Code walkthrough:** This Unknown example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

(3) Symlink policy: decide whether to follow symlinks.
    A symlink in the allowed directory can point
    to anywhere on the filesystem. Options:
    - Disallow symlinks entirely
    - Follow symlinks only if the target is also
      in the allowed directory

(4) Sensitive file filtering: even within the allowed
    directory, some files should not be exposed
    (`.env`, `secrets.yaml`, private keys). Implement
    an explicit denylist for sensitive file patterns.

*What separates good from great:* "Path traversal
via symlinks - follow symlinks only if the target
is also within the allowed directory."

---

**[MID] Q6 - [TRADE-OFF] When is a Resource better
than injecting content into the system prompt?**

*Why they ask:* Architecture judgment.

System prompt injection: include the data directly
in the system prompt before the conversation starts.

Resources: data available on demand, read by the
AI when needed.

Use system prompt injection when:
- Data is small (< 2,000 tokens)
- Data is critical for all queries (AI always needs it)
- Data is static (doesn't change during the session)
- You need the AI to have context before the first message

Use Resources when:
- Data is large (documents, large records)
- AI needs it selectively (only for specific queries)
- Data changes frequently (use subscriptions)
- Data is user-specific (different users, different resources)
- You want the AI to discover and select relevant documents

Context window consideration: injecting 10,000
tokens of documentation into the system prompt
uses expensive context on every call. Resources
are read on demand - the AI pays the context cost
only when it actually needs the data.

*What separates good from great:* "Large, selectively-needed
data belongs in Resources; small, always-needed
context belongs in the system prompt."

---

**[JUNIOR] Q7 - What MIME types are common for MCP
Resources and why do they matter?**

*Why they ask:* Practical implementation knowledge.

Common MIME types and their use:

`text/plain`: plain text content. Most universal.
`text/markdown`: Markdown-formatted documentation.
Most AI assistants render this well.
`text/html`: HTML content. The AI may or may not
strip tags depending on the client.
`application/json`: JSON data. Use for structured
records the AI should reason over.
`application/pdf`: PDF documents. Requires blob
content type, not text.
`image/png`, `image/jpeg`: image content. Returned
as blob with base64 encoding.

Why MIME types matter:

(1) Client rendering: some clients display Resources
    with appropriate formatting based on MIME type
    (markdown rendered as HTML, JSON prettified).

(2) AI interpretation: the AI uses the MIME type
    to understand the content format. A JSON resource
    with `text/plain` MIME type may be interpreted
    as a string rather than structured data.

(3) Binary vs. text: MIME type determines whether
    the content is returned as `text` or `blob` in
    the resource content. Text MIME types use `text`;
    binary types use `blob` with base64 encoding.

*What separates good from great:* "MIME type determines
text vs blob content - use application/json for
structured data the AI should reason over."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ concept.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ concept.)*

---

### 📊 Diagram

*(Omit: resource flow is well-expressed as text.)*

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


# MCP Prompts

**Interview Weight:** ★☆☆ - MCP Prompts are the
least-used primitive but the most impactful for
creating reusable AI workflows. Knowing them
distinguishes practitioners from casual users.

---

### 🎯 Model Answer

**30 seconds:**

> MCP Prompts are reusable prompt templates stored
> on the server that users can invoke through AI
> clients. Unlike Tools (which the AI calls autonomously)
> and Resources (which provide data), Prompts are
> user-invoked and return a structured message sequence
> the AI processes. Example: a "summarize document"
> prompt template accepts a document URI and returns
> a system + user message sequence ready for the AI.

**3 minutes:**

> Prompts solve the "reusable workflow" problem for
> AI applications. Without Prompts: each user crafts
> their own prompt for common tasks, with inconsistent
> results. With Prompts: a server defines the optimal
> prompt for each task; users invoke it by name;
> the AI processes it consistently.
>
> A Prompt has three parts: a name (unique identifier),
> a description (what it does), and optional arguments
> (parameters the user provides when invoking it).
> When invoked via `prompts/get`, the server returns
> a list of messages - typically a system message
> setting context and a user message with the specific
> request.
>
> The key distinction from Tools: Prompts are
> USER-invoked (the user selects a prompt template
> in the UI). Tools are AI-invoked (the AI autonomously
> decides to call them). This makes Prompts appropriate
> for predefined workflows: code review templates,
> document summarization templates, debugging
> checklists. Tools are appropriate for dynamic
> capability access: searching, querying, executing.
>
> In Claude Desktop: Prompts appear in the `/` slash
> command menu. A user types `/summarize-document`
> and is prompted for the document URI. The client
> calls `prompts/get` with the arguments, gets the
> message sequence, and sends it to the AI.

**Blank Mind Recovery:**

**(1) Restate:** "MCP Prompts are reusable workflow
templates stored on the server."

**(2) First principles:** "Repeating the same complex
prompt for common tasks is wasteful and inconsistent.
Prompts store the best version once on the server;
users invoke it by name."

**(3) Bridge:** "Think of SQL views: a view is a
saved, reusable query. A Prompt is a saved, reusable
AI workflow. Same benefit - encode best practice
once, reuse everywhere."

---

### 📘 Concept Explanation

**What it is:**

MCP Prompts are server-defined, user-invocable
prompt templates that accept arguments and return
structured message sequences. They enable standardized,
reusable AI workflows accessible to all users
of an MCP server.

**The problem it solves:**

Without Prompts: each user writes their own version
of common workflows. Code review quality varies by
how well each developer writes prompts. Document
summaries are inconsistent. Debugging approaches
differ by person. Prompts centralize the "best prompt"
for each workflow on the server.

**How it works:**

```
PROMPT STRUCTURE:

{
  name: "summarize-document",
  description: "Create a structured summary of a doc",
  arguments: [
    {
      name: "document_uri",
      description: "URI of the document to summarize",
      required: true
    },
    {
      name: "style",
      description: "executive | technical | bullet-points",
      required: false
    }
  ]
}

PROMPT INVOCATION (prompts/get):
  request: {
    name: "summarize-document",
    arguments: {
      document_uri: "file:///docs/design.md",
      style: "executive"
    }
  }
  response: {
    messages: [
      {
        role: "user",
        content: {
          type: "text",
          text: "Summarize this document...\n[doc content]"
        }
      }
    ]
  }
```

> **Code walkthrough:** This MCP Prompts example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

Prompts are the only MCP primitive that is
USER-invoked rather than AI-invoked. Tools are
called by the AI when it decides to take action.
Resources are read by the AI or client when data
is needed. Prompts are selected by the USER through
the client UI. This makes Prompts the right primitive
for predefined workflows that users consciously choose.

**When to use it:**

- Common, repeated tasks with an optimal prompt
  formulation (code review, summarization, debugging)
- Multi-step workflows that need consistent setup
  (pre-loaded system context + user message structure)
- Team-standardized AI interactions (the "official"
  way to do a code review with AI)

**When NOT to use it:**

- Tasks the AI should decide to do autonomously
  (use Tools)
- Data access without a workflow (use Resources)
- One-off prompts that vary too much between uses
  (prompt directly in the chat)

**Alternatives:**

- Custom system prompts in client config: simpler
  but not server-side, not user-parameterizable
- Prompt libraries in code: not discoverable
  via MCP, not accessible from multiple clients
- Templates in documentation: not executable,
  requires manual copy-paste

**First-principles derivation:**

Users of AI tools have recurring, high-value workflows:
"summarize this", "review this code", "debug this
error". The optimal prompt for each workflow is
discoverable through experimentation. Prompts enable
this expertise to be captured once on the server
and shared with all users - eliminating per-user
prompt quality variance.

---

### 💻 Code Example

```python
from mcp.server import Server
import mcp.types as types

server = Server("prompt-examples")


@server.list_prompts()
async def list_prompts() -> list[types.Prompt]:
    """Expose available prompt templates."""
    return [
        types.Prompt(
            name="code-review",
            description=(
                "Conduct a thorough code review focusing "
                "on: correctness, security, performance, "
                "readability. Returns structured feedback "
                "with severity levels."
            ),
            arguments=[
                types.PromptArgument(
                    name="language",
                    description="Programming language (python, java, etc.)",
                    required=True
                ),
                types.PromptArgument(
                    name="focus",
                    description=(
                        "Review focus: security | performance | "
                        "readability | all"
                    ),
                    required=False
                )
            ]
        ),
        types.Prompt(
            name="summarize-document",
            description=(
                "Create a structured document summary. "
                "Accepts a document URI and returns "
                "a summary with key points and action items."
            ),
            arguments=[
                types.PromptArgument(
                    name="document_uri",
                    description="URI of the document (file:// or wiki://)",
                    required=True
                ),
                types.PromptArgument(
                    name="style",
                    description="executive | technical | bullet-points",
                    required=False
                )
            ]
        )
    ]


@server.get_prompt()
async def get_prompt(
    name: str,
    arguments: dict | None
) -> types.GetPromptResult:
    """Return the message sequence for a prompt template."""
    args = arguments or {}

    if name == "code-review":
        lang = args.get("language", "unknown")
        focus = args.get("focus", "all")

        return types.GetPromptResult(
            description="Code review workflow",
            messages=[
                types.PromptMessage(
                    role="user",
                    content=types.TextContent(
                        type="text",
                        text=(
                            f"Please conduct a {focus} code "
                            f"review of the following "
                            f"{lang} code. Structure your "
                            f"feedback with: "
                            f"CRITICAL / WARNING / SUGGESTION "
                            f"severity levels. For each issue: "
                            f"describe the problem, explain why "
                            f"it matters, and suggest a fix.\n\n"
                            f"[Paste your code here]"
                        )
                    )
                )
            ]
        )

    if name == "summarize-document":
        uri = args.get("document_uri", "")
        style = args.get("style", "technical")
        return types.GetPromptResult(
            description="Document summary workflow",
            messages=[
                types.PromptMessage(
                    role="user",
                    content=types.TextContent(
                        type="text",
                        text=(
                            f"Summarize the document at {uri}. "
                            f"Style: {style}. "
                            f"Include: executive summary (2-3 sentences), "
                            f"key findings (bullet points), "
                            f"action items (if any), "
                            f"open questions (if any)."
                        )
                    )
                )
            ]
        )

    raise ValueError(f"Unknown prompt: {name}")
```

> **Code walkthrough:** The `list_prompts()` handlerice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> returns two prompt templates: `code-review` and
> `summarize-document`. Each has a name, a description
> that explains what it does (critical for user
> discoverability in client UIs), and arguments with
> required/optional flags. The `get_prompt()` handler
> takes the prompt name and user-provided arguments,
> then constructs a message sequence. The message
> sequence is the actual prompt content - it can
> be a single user message or a multi-turn sequence
> with system and user messages. The `code-review`
> prompt uses severity-level structure (CRITICAL /
> WARNING / SUGGESTION) baked into the template -
> this is the "best prompt" encoded once for everyone.
> Users who invoke this prompt get consistent,
> structured code reviews without needing to know
> how to write the optimal code review prompt.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "MCP Prompts are reusable workflow templates stored
> on the server. Unlike Tools (which the AI calls
> autonomously) and Resources (which provide data),
> Prompts are user-invoked: the user selects a prompt
> template in the client UI, provides arguments,
> and the server returns a structured message sequence.
> In Claude Desktop, Prompts appear in the slash
> command menu. They're useful for encoding the 'best
> prompt' for common tasks like code review or
> document summarization."

---

**Senior / Staff:**

> "MCP Prompts are the underutilized primitive with
> the highest leverage for teams. The strategic value:
> when a team has figured out the optimal prompt for
> a common workflow (code review, architecture review,
> incident diagnosis), capturing it as a Prompt means
> every team member gets the benefit without needing
> to know prompt engineering. It's the equivalent
> of a shared runbook but for AI workflows. For
> enterprise deployments, I think of Prompts as
> part of the 'AI process library' - alongside the
> tool and resource servers. The team's accumulated
> prompt engineering expertise becomes a shared asset,
> discoverable and executable from any MCP-compatible
> client."

---

### ⚠️ Common Misconceptions

**Misconception: "MCP Prompts and Tool descriptions
are the same thing."**

Tool descriptions are passive metadata: the AI reads
them to decide WHEN to autonomously call a tool.
Prompts are active templates: users explicitly SELECT
them in the client UI to start a workflow. A tool
description is "search the docs when the user asks
a technical question." A Prompt is "here is the
structured code review workflow - invoke it when
you want a code review." Different invocation model,
different purpose. Prompts are for user-directed
workflows; tool descriptions are for AI-directed
capability matching.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Prompts are not visible in Claude Desktop
slash command menu**

*Symptom:* The server is connected and tools work,
but the slash command menu shows no prompts.

*Diagnosis:*

1. Verify the server exposes the `prompts` capability.
   Check the initialize response: the `capabilities`
   object must include `"prompts": {}`.

2. Test `prompts/list` directly:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"prompts/list",
   "params":{}}' | python server.py
   ```
> **Code walkthrough:** This Unknown example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

   Should return a list with your prompt definitions.

3. Check for runtime errors in the `list_prompts()`
   handler. If it raises an exception, the client
   may fail silently and show no prompts.

4. Verify the prompt name contains only allowed
   characters (lowercase letters, numbers, hyphens,
   underscores). Special characters in the name
   may cause parsing issues in some clients.

*Fix:* Ensure `list_prompts()` returns a valid list
without errors. The capability must be declared
in the server's InitializationOptions.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Definition / distinction | 2-3 min |
| Design | 3-4 min |
| Use cases | 3-4 min |
| Comparison to Tools | 3-4 min |
| Debugging | 4-5 min |
| Blank mind recovery | 1 min |

---

**[JUNIOR] Q1 - What is an MCP Prompt and how does
it appear to users?**

*Why they ask:* Baseline understanding.

An MCP Prompt is a server-defined, parameterizable
workflow template. It has:
- A name (unique identifier)
- A description (what it does - shown in the client UI)
- Optional arguments (parameters the user provides)

When invoked (`prompts/get`), it returns a structured
message sequence ready for the AI to process.

In Claude Desktop: Prompts appear in the slash
command menu. Typing `/` shows all available prompts
from all connected servers. The user selects a prompt,
fills in any required arguments, and the client
sends the resulting message sequence to the AI.

In VS Code Copilot: similar - prompts appear as
selectable workflow starters.

Key distinction from Tools: the USER invokes Prompts.
The AI autonomously invokes Tools. This means Prompts
are for conscious, deliberate workflow selection;
Tools are for the AI to take action based on reasoning.

*What separates good from great:* "Prompts appear
in the client's slash command menu - they're a UI
element, not just a protocol primitive."

---

**[MID] Q2 - When would you use a Prompt vs. a
system prompt in your MCP server config?**

*Why they ask:* Design decision clarity.

System prompt (in server/client config):
- Applies to ALL conversations globally
- Not user-selectable (always active)
- Not parameterizable per-invocation
- Use for: global context (server identity, usage rules,
  default behavior)

MCP Prompt:
- User-selectable per conversation
- Parameterizable (user provides arguments)
- Multiple prompts available simultaneously
- Use for: specific workflow templates (code review,
  summarization, debugging), multi-step task initiation,
  team-standardized workflows

When both are appropriate together:
System prompt sets the AI's identity and general
context. MCP Prompts define specific workflows
within that context. Example: system prompt establishes
"You are an engineering assistant for Acme Corp."
MCP Prompts provide "code-review", "incident-diagnosis",
"architecture-review" workflows within that context.

*What separates good from great:* "System prompt
for always-active global context; Prompts for user-selected
specific workflows."

---

**[SENIOR] Q3 - What makes an effective MCP Prompt
template design?**

*Why they ask:* Prompt engineering applied to server design.

Five design principles:

(1) Single, clear purpose: one prompt does one thing.
    "code-review" not "code-review-and-summarize".
    The user should know exactly what they'll get.

(2) Structured output: bake output format into the
    template. "Return findings as CRITICAL/WARNING/SUGGESTION
    with description + reason + fix" produces consistently
    structured responses.

(3) Context injection: the prompt template is the
    right place to inject document content or resource
    data. Include instructions to embed the resource
    content in the message.

(4) Minimal required arguments: each required argument
    creates friction. Default values for optional
    args reduce the cognitive load for common cases.

(5) Discoverable names: the name should be self-documenting.
    `summarize-document` not `sd`. The description
    should explain in one sentence what the user gets.

Anti-patterns to avoid:
- Overly complex argument schemas (users won't fill them)
- Prompts that could be better served by a tool
  (e.g., "get all users" - that's a Resource, not a Prompt)
- Prompts that duplicate Claude's built-in capabilities
  (Claude already summarizes well without a Prompt)

*What separates good from great:* "Bake structured
output format into the template - encode the best
output schema once, share with the whole team."

---

**[JUNIOR] Q4 - What is the return format of prompts/get?**

*Why they ask:* Protocol-level understanding.

`prompts/get` returns a `GetPromptResult`:

```json
{
  "description": "Code review workflow",
  "messages": [
    {
      "role": "user",
      "content": {
        "type": "text",
        "text": "Please review this Python code..."
      }
    }
  ]
}
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Key fields:
- `description`: optional description of this invocation
  (can differ from the prompt's static description)
- `messages`: array of PromptMessage objects, each
  with a `role` (user/assistant) and `content`

The messages array can contain:
- A single user message (most common)
- A system message + user message
- A multi-turn sequence (system, user, assistant, user...)
  for workflows that need a conversation preamble

The client takes this message array and uses it
to initialize or continue the conversation with
the AI. The messages are injected into the conversation
context.

*What separates good from great:* "Messages can
be multi-turn - a prompts/get response can include
a full conversation preamble, not just a single message."

---

**[MID] Q5 - [TRADE-OFF] Prompts vs. Tool - which
primitive for a "code review" workflow?**

*Why they ask:* Design decision judgment.

Use a Prompt for code review. Reasons:

(1) User-initiated: the user consciously decides
    "I want a code review." This is not something
    the AI should autonomously decide to do when
    the user is asking about something else.

(2) Workflow initiation: code review is a structured
    workflow that benefits from a predefined system
    message and output format.

(3) No external side effects: reviewing code doesn't
    require reading from external systems or writing
    to anything. It's pure reasoning.

A Tool would be appropriate for code review ONLY
if the AI should autonomously trigger a review
based on some other condition (e.g., a CI pipeline
bot that automatically reviews every new PR). In
that case, the Tool triggers the review as part
of an automated workflow.

In interactive AI assistants (Claude Desktop):
Prompts for user-triggered workflows; Tools for
AI-triggered data access and external actions.

The boundary: "Does the USER decide when to do this?
Prompt. Does the AI decide autonomously? Tool."

*What separates good from great:* "The invocation
model determines the primitive: user-decided =
Prompt, AI-decided = Tool."

---

**[JUNIOR] Q6 - [DEBUGGING] How do you test an
MCP Prompt before deploying it?**

*Why they ask:* Testing methodology.

Three-step testing process:

Step 1: Test the `prompts/get` response directly:
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"prompts/get",
"params":{"name":"code-review",
"arguments":{"language":"python","focus":"security"}}}' \
| python server.py
```
> **Code walkthrough:** This Unknown example demonstrates shell script pattern. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

Verify the response contains valid messages.

Step 2: Send the returned messages to Claude directly:
```python
import anthropic
client = anthropic.Anthropic()
# Use the messages from prompts/get response
resp = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=prompt_messages  # from prompts/get
)
print(resp.content[0].text)
```
> **Code walkthrough:** This Use the messages from prompts/get response example demonstrates Python code pattern using authentication. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

Evaluate the output quality.

Step 3: A/B test prompt variants: run the same
code sample through multiple prompt formulations
and compare output quality. Iterate until the
structured output format is consistently correct.

For CI: verify `prompts/list` and `prompts/get`
return valid JSON-RPC responses without errors.
Quality of the AI's output is harder to automate
but can be validated with an LLM-as-judge test.

*What separates good from great:* "Send the prompts/get
messages directly to Claude to evaluate output
quality before deploying."

---

**[JUNIOR] Q7 - What happens if a Prompt's required
argument is not provided?**

*Why they ask:* Error handling behavior.

Per MCP spec: the server should return an error
if a required argument is not provided. The error
should be a JSON-RPC error response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": "Required argument 'language' not provided"
  }
}
```

> **Code walkthrough:** This Use the messages from prompts/get response example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

In the Python SDK: raise McpError with the appropriate
error code:
```python
from mcp.shared.exceptions import McpError
from mcp.types import ErrorCode

if "language" not in (arguments or {}):
    raise McpError(
        ErrorCode.InvalidParams,
        "Required argument 'language' not provided"
    )
```

> **Code walkthrough:** This Use the messages from prompts/get response example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

Client behavior: the client should catch this error
and prompt the user to provide the missing argument
before re-invoking.

Best practice: design Prompts so that truly optional
arguments have good defaults. Minimize required
arguments to reduce invocation friction. If an
argument is required, make it obvious in the
argument description why it's required.

*What separates good from great:* "Use JSON-RPC
error code -32602 (InvalidParams) for missing
required arguments."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ concept.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ concept.)*

---

### 📊 Diagram

*(Omit: Prompts flow is well-expressed as text.)*

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



