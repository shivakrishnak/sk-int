---
layout: default
title: "LLM APIs - L1 Core Usage"
parent: "LLM APIs"
nav_order: 2
permalink: /llm-apis/l1-core-usage/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 4 | [Claude Messages API](#claude-messages-api) | ★☆☆ |
| 5 | [LLM API Authentication and Key Management](#llm-api-authentication-and-key-management) | ★☆☆ |
| 6 | [Streaming API Responses](#streaming-api-responses) | ★☆☆ |

---

# Claude Messages API

**Interview Weight:** ★☆☆ - Core operational knowledge.
Engineers building with Claude must know the Messages
API signature, turn structure, and common parameters
cold. This is the daily-use interface.

---

### 🎯 Model Answer

**30 seconds:**

> The Claude Messages API is a POST endpoint at
> `/v1/messages`. You send: `model` (which Claude
> version), `max_tokens` (response length cap),
> optional `system` (system prompt), and `messages`
> (an array of `{role, content}` objects alternating
> user/assistant). You receive a response with a
> `content` array (text blocks), `stop_reason`,
> and `usage` (token counts). The API is stateless:
> you manage conversation history by passing all
> previous turns on every call.

**3 minutes:**

> The Messages API is the foundation of all Claude
> integrations. Understanding its request structure:
>
> Required parameters: `model` identifies which
> Claude model to use. `max_tokens` is a hard cap
> on the response length - Claude stops at this
> limit even mid-sentence. `messages` is the conversation:
> an array of objects each with `role` (either "user"
> or "assistant") and `content` (the text).
>
> Optional parameters: `system` is the system
> prompt - instructions that set Claude's role and
> behavior. `temperature` (0.0-1.0) controls
> determinism. `stop_sequences` provides patterns
> that cause Claude to stop generating.
>
> Response structure: `content` is an array of content
> blocks (normally one `TextBlock`). `stop_reason`
> tells you why generation stopped: "end_turn" (natural
> end), "max_tokens" (limit hit), "stop_sequence"
> (your stop sequence matched), "tool_use" (Claude
> wants to call a tool). `usage` gives input and
> output token counts for cost tracking.
>
> Conversation management: the API is stateless.
> You must pass the full conversation history in
> `messages` on every call. Each new turn adds to
> the history. As the conversation grows, token
> usage grows. You must implement truncation or
> summarization to manage history length.

**Blank Mind Recovery:**

**(1) Restate:** "Messages API. POST to /v1/messages.
Required: model, max_tokens, messages. Get back
content text and stop_reason."

**(2) First principles:** "Send a conversation (list
of messages), get back the next message. Simple.
The stateless part is the key: I must pass all
previous turns every time."

**(3) Bridge:** "Same as any chat API: you send the
history and the latest message, get back the reply.
I've seen this pattern in OpenAI and Gemini too."

---

### 📘 Concept Explanation

**What it is:**

The Claude Messages API (`POST /v1/messages`) is
the primary HTTP interface for generating text with
Claude models. It accepts a conversation history
and returns the next turn.

**The problem it solves:**

Provides a structured, stateless interface for
language model inference, supporting both simple
single-turn queries and complex multi-turn conversations
with tool use.

**How it works:**

```
REQUEST ANATOMY:

{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1024,
  "system": "You are a helpful assistant.",
  "messages": [
    {"role": "user",      "content": "What is Python?"},
    {"role": "assistant", "content": "Python is..."},
    {"role": "user",      "content": "Who created it?"}
  ],
  "temperature": 0.0,       // optional, 0-1
  "stop_sequences": ["\n\n"] // optional
}

RESPONSE ANATOMY:

{
  "id": "msg_...",
  "type": "message",
  "role": "assistant",
  "content": [
    {"type": "text", "text": "Guido van Rossum..."}
  ],
  "model": "claude-3-5-sonnet-20241022",
  "stop_reason": "end_turn",
  "usage": {
    "input_tokens": 47,
    "output_tokens": 23
  }
}
```

> **Code walkthrough:** This Claude Messages API example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Messages rules:**

- Must alternate user/assistant/user/assistant...
- First message must be role "user"
- Cannot have two consecutive same-role messages
- Maximum: fits within context window (200K tokens
  for claude-3-5-sonnet)

**Key parameters:**

- `max_tokens`: hard cap. Always set it. Omitting it
  causes the API to use a low default.
- `temperature`: 0.0 for deterministic/analytical.
  1.0 for creative. Default: 1.0.
- `system`: sets role and constraints. Cached with
  `cache_control` for cost savings.
- `stop_sequences`: list of strings that terminate
  generation. Useful for structured output.

---

### 💻 Code Example

```python
"""
Claude Messages API: from basic to production patterns.
"""
import anthropic
import os
import sys

client = anthropic.Anthropic(
    api_key=os.environ["ANTHROPIC_API_KEY"]
)

# --- PATTERN 1: SINGLE-TURN (simplest) ---
def classify_intent(text: str) -> str:
    """Classify user intent. Returns one of:
    QUESTION, COMMAND, STATEMENT, OTHER"""
    msg = client.messages.create(
        model="claude-3-5-haiku-20241022",
        max_tokens=16,
        temperature=0.0,
        system=(
            "Classify the user's message intent. "
            "Reply with one word: QUESTION, "
            "COMMAND, STATEMENT, or OTHER."
        ),
        messages=[{"role": "user", "content": text}]
    )
    return msg.content[0].text.strip()

# classify_intent("What time is it?") -> "QUESTION"


# --- PATTERN 2: MULTI-TURN (conversation) ---
class ConversationSession:
    """Manages multi-turn Claude conversation."""

    def __init__(self, system: str = ""):
        self.system = system
        self._history: list[dict] = []

    def send(self, user_message: str) -> str:
        self._history.append({
            "role": "user",
            "content": user_message
        })
        kwargs: dict = {
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 2048,
            "messages": self._history
        }
        if self.system:
            kwargs["system"] = self.system

        msg = client.messages.create(**kwargs)

        # Log usage for cost tracking
        print(
            f"Tokens: in={msg.usage.input_tokens} "
            f"out={msg.usage.output_tokens} "
            f"stop={msg.stop_reason}",
            file=sys.stderr
        )

        if msg.stop_reason == "max_tokens":
            print(
                "WARN: response truncated",
                file=sys.stderr
            )

        reply = msg.content[0].text
        self._history.append({
            "role": "assistant",
            "content": reply
        })
        return reply

    @property
    def total_turns(self) -> int:
        return len(self._history) // 2


# --- PATTERN 3: STRUCTURED OUTPUT ---
import json

def extract_entities(text: str) -> dict:
    """Extract people, places, dates from text.
    Returns: {"people": [...], "places": [...],
               "dates": [...]}"""
    msg = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=512,
        temperature=0.0,
        system=(
            "Extract named entities from text. "
            "Respond with valid JSON only. "
            "No explanation, no markdown."
        ),
        messages=[
            {
                "role": "user",
                "content": (
                    f"Extract entities from: {text}\n\n"
                    "Return JSON with keys: "
                    "people, places, dates (each an array)"
                )
            }
        ]
    )
    raw = msg.content[0].text
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        # Fallback: return empty structure
        return {"people": [], "places": [], "dates": []}
```

> **Code walkthrough:** Three patterns cover theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> common Messages API use cases. Pattern 1 (single-turn)
> uses `temperature=0.0` and `max_tokens=16` for
> a classification task where the answer is one word -
> this is correct sizing. Pattern 2 (conversation)
> shows the manual history management required for
> statefulness: every call gets the full `_history`
> list, and every response gets appended back. The
> usage logging to stderr is production-essential:
> without it you have no visibility into token costs.
> The `stop_reason` check catches truncation before
> it silently corrupts results. Pattern 3 (structured
> output) shows the JSON extraction approach: instruct
> Claude to "return JSON only" in the system prompt,
> wrap `json.loads()` in a try/except because Claude
> occasionally wraps JSON in markdown despite instructions.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "The Messages API takes `model`, `max_tokens`,
> and a `messages` list. Each message has a `role`
> (user or assistant) and content text. The API is
> stateless: I have to pass the whole conversation
> history in every request. The response has `content`
> with the text, `stop_reason` (why it stopped),
> and `usage` with the token counts. I always log
> the usage to track costs."

---

**Senior / Staff:**

> "The Messages API design reflects key LLM production
> tradeoffs. Statelessness: each call is independent.
> This is the right design for scale - no server-side
> session management, no sticky routing - but it
> shifts conversation management to the client. The
> implications at scale: long conversations accumulate
> tokens; at 100+ turns you need a truncation or
> summarization strategy. For production, I wrap the
> API in a class that handles history management,
> logs usage metrics, checks stop_reason, and exposes
> error handling. The raw SDK is good for prototyping;
> production needs the wrapper."

---

### ⚠️ Common Misconceptions

**Misconception: "I can have two user messages
in a row without an assistant turn between them."**

The Messages API requires strict user/assistant
alternation. Two consecutive `role: "user"` messages
causes a 400 error. If you want to provide context
before the first user message, use the `system`
parameter. If you need to inject text that looks
like an intermediate AI response (for few-shot prompting),
you must add an `role: "assistant"` message between user turns.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Conversation grows unbounded, costs spike**

*Symptom:* Early requests cost $0.01. After 50 turns,
the same request costs $0.30. Monthly costs are
trending to $10,000+.

*Root cause:* History is never truncated. Input tokens
grow linearly with conversation length. At turn 100
with average 200 words/turn: 20,000 words ~= 27,000 tokens
in context. At $3/MTok: $0.08 per request.

*Fix:* Implement a sliding window:

```python
MAX_HISTORY_TURNS = 20  # keep last 20 turns

def trim_history(
    history: list[dict],
    max_turns: int = MAX_HISTORY_TURNS
) -> list[dict]:
    """Keep last max_turns pairs (user+assistant)."""
    if len(history) <= max_turns * 2:
        return history
    return history[-(max_turns * 2):]
```

> **Code walkthrough:** This Fallback: return empty structure example demonstrates function definition. **KEY MECHANISM:** Python compiles the function body to bytecode; default args are evaluated once at definition time. **WHY IT MATTERS:** mutable default arguments (def f(x=[])) share state across calls - a classic bug. **TAKEAWAY: use None as default for mutable args and initialize inside the function body.**

For applications where long-term memory matters,
use summarization: every 20 turns, ask Claude to
summarize the conversation so far, then replace
the history with the summary as context.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| API signature | 2-3 min |
| History management | 3-4 min |
| Token counting | 3-4 min |
| Structured output | 3-4 min |
| stop_reason handling | 3-4 min |
| Performance patterns | 3-4 min |
| Cost optimization | 3-4 min |

---

**[JUNIOR] Q1 - What are the required parameters
for a Messages API call?**

*Why they ask:* Baseline knowledge.

Required:
- `model`: the Claude model identifier. Example:
  `"claude-3-5-sonnet-20241022"`. The full version
  string is required; `"claude"` alone is not valid.
- `max_tokens`: maximum number of output tokens.
  Must be a positive integer. No default - omitting
  it may cause an API error or use a very low default
  depending on SDK version.
- `messages`: a non-empty array of message objects.
  Each object has `role` ("user" or "assistant")
  and `content` (string or array of content blocks).

Optional but commonly used:
- `system`: the system prompt (string or array)
- `temperature`: 0.0-1.0 (default 1.0)
- `stop_sequences`: array of strings

What happens if messages is empty: 400 Bad Request.
What happens if messages doesn't start with "user": 400 Bad Request.
What happens if messages has consecutive same roles: 400 Bad Request.

*What separates good from great:* "The full model
string is required - always check the current model
identifiers in the Anthropic docs as they update
with new releases."

---

**[MID] Q2 - How do you implement conversation
history management in a multi-turn application?**

*Why they ask:* Stateless API + conversation management.

The Messages API is stateless. History management is entirely your responsibility.

Pattern 1 - Simple append (bounded conversations):

```python
history = []

def chat(user_msg: str) -> str:
    history.append(
        {"role": "user", "content": user_msg}
    )
    msg = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=history
    )
    reply = msg.content[0].text
    history.append(
        {"role": "assistant", "content": reply}
    )
    return reply
```

> **Code walkthrough:** This Fallback: return empty structure example demonstrates function definition using authentication. **KEY MECHANISM:** Python compiles the function body to bytecode; default args are evaluated once at definition time. **WHY IT MATTERS:** mutable default arguments (def f(x=[])) share state across calls - a classic bug. **TAKEAWAY: use None as default for mutable args and initialize inside the function body.**

Pattern 2 - Sliding window (long conversations):

```python
def chat_windowed(
    history: list[dict],
    user_msg: str,
    max_turns: int = 10
) -> tuple[str, list[dict]]:
    history.append(
        {"role": "user", "content": user_msg}
    )
    window = history[-(max_turns * 2):]
    msg = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=window
    )
    reply = msg.content[0].text
    history.append(
        {"role": "assistant", "content": reply}
    )
    return reply, history
```

> **Code walkthrough:** This Unknown example demonstrates function definition using authentication. **KEY MECHANISM:** Python compiles the function body to bytecode; default args are evaluated once at definition time. **WHY IT MATTERS:** mutable default arguments (def f(x=[])) share state across calls - a classic bug. **TAKEAWAY: use None as default for mutable args and initialize inside the function body.**

Pattern 3 - Persistent storage (multi-session):
Store history in a database keyed by session_id.
Load on each request. Truncate to last N turns.

*What separates good from great:* "For customer-facing
chat, persist history in a database - in-memory
history is lost on server restart or horizontal scaling."

---

**[JUNIOR] Q3 - What does `stop_reason: "tool_use"` mean?**

*Why they ask:* Tool use workflow understanding.

When Claude is given tool definitions and decides
to call a tool, it returns early with `stop_reason: "tool_use"`.
The response content includes a `tool_use` block (not just text).

This signals: the conversation is not finished.
Claude is pausing to execute a tool and needs you
to call it and return the result.

```python
msg = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    tools=[my_tool_definition],
    messages=history
)

if msg.stop_reason == "tool_use":
    # Find tool_use block in content
    tool_call = next(
        b for b in msg.content
        if b.type == "tool_use"
    )
    # Execute the tool
    result = execute_tool(
        tool_call.name, tool_call.input
    )
    # Return result and continue conversation
    history.append(
        {"role": "assistant", "content": msg.content}
    )
    history.append({
        "role": "user",
        "content": [{
            "type": "tool_result",
            "tool_use_id": tool_call.id,
            "content": result
        }]
    })
    # Continue: call messages.create again
```

> **Code walkthrough:** This Continue: call messages.create again example demonstrates Python code pattern using authentication. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

*What separates good from great:* "tool_use stop_reason
starts an async loop - the conversation continues
until stop_reason is end_turn."

---

**[MID] Q4 - How do you get structured (JSON) output
from Claude reliably?**

*Why they ask:* Data extraction patterns.

Three approaches from least to most reliable:

Approach 1 - Prompt instruction (least reliable):
Tell Claude "respond with JSON only." Works 95%
of the time. Claude occasionally adds markdown
fences or explanatory text.

```python
# Parse with fallback
raw = msg.content[0].text
if raw.startswith("```"):
    raw = raw.split("```")[1].removeprefix("json").strip()
result = json.loads(raw)
```

> **Code walkthrough:** This Parse with fallback example demonstrates context manager. **KEY MECHANISM:** __enter__ acquires the resource; __exit__ always runs for cleanup even on exception. **WHY IT MATTERS:** forgetting with for file/connection objects leaks file descriptors and DB connections. **TAKEAWAY: always use with for any resource with explicit cleanup.**

Approach 2 - Assistant turn prefill:
Add a partial assistant message to force JSON start:

```python
messages=[
    {"role": "user", "content": prompt},
    {"role": "assistant", "content": "{"}  # force JSON
]
```

> **Code walkthrough:** This Parse with fallback example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

Then prepend `{` to the response before parsing.
Very reliable: Claude continues from where you left off.

Approach 3 - Tool use (most reliable):
Define a "record data" tool. Claude must call the
tool with structured arguments to provide data.
Arguments are validated by your tool schema (JSON Schema).

For production data pipelines: use tool use.
For simple extraction: approach 2 is pragmatic.

*What separates good from great:* "Tool use for
structured output is the most reliable because
Claude must satisfy your JSON Schema to call the tool."

---

**[JUNIOR] Q5 - What is the `temperature` parameter?**

*Why they ask:* Core parameter knowledge.

Temperature controls how deterministic Claude's
output is, on a scale of 0.0 to 1.0.

0.0 (deterministic): Claude always picks the most
likely next token. Same prompt -> same output (usually).
Use for: classification, extraction, factual Q&A,
code generation where correctness matters.

1.0 (default): Claude samples from the probability
distribution. Same prompt may produce different
outputs each time. More creative, varied responses.
Use for: creative writing, brainstorming, generating
diverse options.

Middle values: 0.3-0.7 for balanced tasks.

Common mistake: using the default temperature (1.0)
for classification or data extraction. This introduces
randomness into tasks that need consistency.


```python
# BAD: anti-pattern - see GOOD example below
```

```python
# BAD: random classification
msg = client.messages.create(
    model="...",
    max_tokens=16,
    # temperature defaults to 1.0 - random!
    messages=[{"role": "user",
               "content": f"Sentiment of: {text}"}]
)

# GOOD: deterministic classification
msg = client.messages.create(
    model="...",
    max_tokens=16,
    temperature=0.0,  # deterministic
    messages=[{"role": "user",
               "content": f"Sentiment of: {text}"}]
)
```

> **Code walkthrough:** BAD pattern: This GOOD: deterministic classification example demonstrates Python code pattern using authentication. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **WHAT BREAKS: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

*What separates good from great:* "Temperature=0
doesn't guarantee identical output across all model
versions - always run regression tests when upgrading."

---

**[MID] Q6 - How do you implement retry logic for
the Messages API?**

*Why they ask:* Production reliability.

Retryable errors: 429 (rate limit), 529 (API overloaded),
500/502/503/504 (transient server errors).

Non-retryable: 400 (bad request), 401 (invalid key),
403 (permission denied). Retrying these wastes time.

```python
import time
import anthropic

def create_with_retry(
    client: anthropic.Anthropic,
    max_attempts: int = 3,
    **kwargs
) -> anthropic.types.Message:
    last_err = None
    for attempt in range(max_attempts):
        try:
            return client.messages.create(**kwargs)
        except anthropic.RateLimitError as e:
            wait = 2 ** attempt  # 1, 2, 4 seconds
            import sys
            print(
                f"Rate limit hit, waiting {wait}s",
                file=sys.stderr
            )
            time.sleep(wait)
            last_err = e
        except anthropic.APIStatusError as e:
            if e.status_code in (500, 502, 503, 529):
                wait = 2 ** attempt
                time.sleep(wait)
                last_err = e
            else:
                raise  # non-retryable, fail fast
    raise last_err
```

> **Code walkthrough:** This GOOD: deterministic classification example demonstrates function definition using error handling. **KEY MECHANISM:** Python compiles the function body to bytecode; default args are evaluated once at definition time. **WHY IT MATTERS:** mutable default arguments (def f(x=[])) share state across calls - a classic bug. **TAKEAWAY: use None as default for mutable args and initialize inside the function body.**

For production: use the Anthropic SDK's built-in
retry with `max_retries=3` in the client constructor.

*What separates good from great:* "The Anthropic SDK
supports max_retries natively - use it as a baseline,
then add custom handling for 429s with respect for
the Retry-After header."

---

**[JUNIOR] Q7 - How do you calculate the cost of
a Messages API call?**

*Why they ask:* Production cost awareness.

Cost formula:
```
cost = (input_tokens * input_price)
     + (output_tokens * output_price)
```

> **Code walkthrough:** This GOOD: deterministic classification example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Mid-2025 pricing (approximate):
- claude-3-5-sonnet: $3/MTok in, $15/MTok out
- claude-3-5-haiku: $0.80/MTok in, $4/MTok out
- claude-opus-4-5: $15/MTok in, $75/MTok out

Where to get token counts:
```python
msg = client.messages.create(...)
input_t = msg.usage.input_tokens
output_t = msg.usage.output_tokens

# claude-3-5-sonnet pricing
cost_usd = (
    (input_t * 3.0) + (output_t * 15.0)
) / 1_000_000

print(f"Cost: ${cost_usd:.6f}")
```

> **Code walkthrough:** This claude-3-5-sonnet pricing example demonstrates Python code pattern using authentication. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

Monthly estimation: if avg request = 500 in + 200 out
at 10,000 requests/day:
= (5B * 3) + (2B * 15) / 1M
= $15,000 + $30,000 = $45,000/month

With haiku instead: $4,000 + $8,000 = $12,000/month

*What separates good from great:* "Always calculate
costs for all three model tiers before deciding -
haiku vs. sonnet is often a 4-5x price difference
for similar quality on simpler tasks."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ operational keyword.)*

---

### 🏛️ System Design

*(Omit: L1 core usage keyword.)*

---

### 📊 Diagram

*(Omit: clearer as structured text for this API reference.)*

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


# LLM API Authentication and Key Management

**Interview Weight:** ★☆☆ - Security fundamentals.
API key management is the most common security
issue in LLM API integrations. Every engineer
must know the secure patterns.

---

### 🎯 Model Answer

**30 seconds:**

> LLM APIs authenticate with bearer tokens (API keys).
> The key must never appear in source code - pass
> it via environment variables only. In production,
> use a secrets manager (AWS Secrets Manager, HashiCorp
> Vault, Kubernetes Secrets). Rotate keys regularly
> and monitor usage for anomalies. Leaked API keys
> can generate $50,000+ in unauthorized charges
> within hours - prevention is non-negotiable.

**3 minutes:**

> LLM API keys are long-lived bearer tokens that grant
> full API access. Unlike short-lived JWTs, they
> don't expire automatically. This makes them high-value
> targets for attackers.
>
> The threat model: a developer commits a key to
> a public GitHub repository. Automated scanners
> find it within minutes. Attackers run inference
> workloads at the developer's expense. Anthropic
> and OpenAI monitor for anomalous usage but may
> not catch this before significant charges accumulate.
>
> The secure pattern: API keys live in environment
> variables during development, in secrets managers
> in production. Code reads from the environment.
> Keys are never in source code, never in config
> files committed to version control.
>
> Defense in depth: (1) Never commit keys. (2) Use
> pre-commit hooks (gitleaks) to catch keys before
> they reach git history. (3) Set billing alerts
> to detect unauthorized usage. (4) Rotate keys
> periodically or immediately after suspected exposure.
> (5) Use key scoping where supported (Anthropic
> supports restricted keys for specific models).

**Blank Mind Recovery:**

**(1) Restate:** "LLM API key management. Keys in
environment variables. Never in code. Secrets manager
in production."

**(2) First principles:** "API keys are passwords.
Treat them like passwords: don't hardcode, don't
log, rotate regularly, monitor for misuse."

**(3) Bridge:** "Same as database credentials:
connection string not in source code. Environment
variable. Secrets manager in production. Same pattern."

---

### 📘 Concept Explanation

**What it is:**

LLM API authentication uses long-lived API keys
passed as bearer tokens in HTTP headers. Key management
is the practice of generating, storing, rotating,
and revoking these keys securely.

**The problem it solves:**

API keys grant billable access to AI models. Leakage
causes unauthorized financial charges and potential
data exposure. Proper key management prevents leakage.

**How it works:**

```
REQUEST AUTHENTICATION:

HTTP Header:
  x-api-key: sk-ant-api03-...   (Anthropic)
  Authorization: Bearer sk-...   (OpenAI)

Key types:
  Anthropic: sk-ant-api03-[random]
  OpenAI:    sk-[random]
  Google:    AIza[random]

These are bearer tokens: possession = access.
No expiry. No refresh flow.
```

> **Code walkthrough:** This LLM API Authentication and Key Management example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Key storage by environment:**

```
DEVELOPMENT:
  .env file (in .gitignore)
  -> os.environ["ANTHROPIC_API_KEY"]
  
  .env file:
    ANTHROPIC_API_KEY=sk-ant-api03-...

STAGING/PRODUCTION:
  AWS Secrets Manager
  HashiCorp Vault
  Azure Key Vault
  Kubernetes Secrets (with RBAC)
  
  Application reads from secrets manager at startup
  or via sidecar (Vault Agent)

CI/CD:
  GitHub Actions Secrets
  GitLab CI Variables (masked)
  Never in pipeline scripts or artifacts
```

> **Code walkthrough:** This LLM API Authentication and Key Management example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Defense layers:**

- Layer 1 (prevention): never write key in source
- Layer 2 (detection): pre-commit hooks (gitleaks)
- Layer 3 (monitoring): billing alerts, usage anomaly alerts
- Layer 4 (response): immediate key rotation on exposure

---

### 💻 Code Example


```python
# BAD: anti-pattern - see GOOD example below
```


```python
# BAD: anti-pattern - see GOOD example below
```


```python
# BAD: anti-pattern - see GOOD example below
```

```python
"""
LLM API key management: bad patterns vs. good patterns.
"""

# --- BAD PATTERNS ---

# BAD 1: Hardcoded in source code
import anthropic
client_bad = anthropic.Anthropic(
    api_key="sk-ant-api03-NEVER-DO-THIS"
    # This is in git history forever.
    # Even if you delete the line, history has it.
)

# BAD 2: In a config file committed to git
# config.py:
#   ANTHROPIC_KEY = "sk-ant-api03-NEVER-DO-THIS"
# ...
# from config import ANTHROPIC_KEY  # BAD

# BAD 3: Logging the key
import os
key = os.environ.get("ANTHROPIC_API_KEY", "")
print(f"Using key: {key}")  # BAD: key in logs

# BAD 4: In a .env file NOT in .gitignore
# If .env is committed: key is exposed.
# .env must always be in .gitignore

# --- GOOD PATTERNS ---

import os
import sys

# GOOD 1: Environment variable (development)
def get_client() -> anthropic.Anthropic:
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print(
            "ERROR: ANTHROPIC_API_KEY not set",
            file=sys.stderr
        )
        raise EnvironmentError(
            "ANTHROPIC_API_KEY environment variable required"
        )
    # Verify key format without logging the key
    if not api_key.startswith("sk-ant"):
        raise ValueError("Invalid Anthropic API key format")
    return anthropic.Anthropic(api_key=api_key)


# GOOD 2: AWS Secrets Manager (production)
import json

def get_client_from_aws() -> anthropic.Anthropic:
    import boto3
    session = boto3.session.Session()
    sm = session.client(
        service_name="secretsmanager",
        region_name="us-east-1"
    )
    secret = sm.get_secret_value(
        SecretId="prod/llm-api/anthropic"
    )
    secret_dict = json.loads(secret["SecretString"])
    return anthropic.Anthropic(
        api_key=secret_dict["api_key"]
    )


# BAD: see prior example above (3: .env file with python-doten...)
# GOOD 3: .env file with python-dotenv (dev only)
# requirements: python-dotenv in dev dependencies
def load_env_for_development():
    try:
        from dotenv import load_dotenv
        load_dotenv()  # reads .env (must be gitignored)
    except ImportError:
        pass  # dotenv not installed in production
```

> **Code walkthrough:** Four bad patterns show theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> most common mistakes. Hardcoding is the most dangerous:
> git history is permanent - even if the line is
> deleted, the key exists in every previous commit.
> Logging is subtle: "Using key: sk-ant-..." writes
> the actual key to stdout/logs where it can be
> harvested from log aggregation tools. The good
> patterns show the layered approach: environment
> variables for development (read by `os.environ.get()`),
> AWS Secrets Manager for production (the key never
> touches the filesystem or environment of the
> application server), and `python-dotenv` for local
> development convenience while keeping the `.env`
> file gitignored. The format validation (`startswith("sk-ant")`)
> catches misconfiguration without logging the key itself.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "API keys go in environment variables, never in
> source code. In development, I use a `.env` file
> (always in `.gitignore`) with `python-dotenv`.
> In production, the key comes from AWS Secrets Manager
> or a similar secrets manager. I set billing alerts
> at both 50% and 100% of my monthly budget. If
> I ever suspect a key was exposed, I rotate it
> immediately - the key is compromised the moment
> it's committed to git, even if I delete the commit."

---

**Senior / Staff:**

> "Key management for LLM APIs is the same as database
> credential management. The security model is:
> (1) Never in code - environment or secrets manager only.
> (2) Pre-commit hooks catch mistakes before they
> reach git history. (3) Billing alerts catch unauthorized
> usage within minutes. (4) Rotate keys on a schedule
> (quarterly) and immediately on suspected exposure.
> At org level, I add IAM-based auth where available
> (AWS Bedrock + IAM roles = no API keys at all).
> That's the best practice for cloud-native deployments:
> eliminate the API key entirely by using IAM."

---

### ⚠️ Common Misconceptions

**Misconception: "I can delete a committed key from
git and the exposure is undone."**

Once an API key is committed to a git repository,
it exists in the git object store for the lifetime
of the repository. `git rm` and even `git filter-branch`
don't fully remove it from all forks, mirrors, and
distributed clones. Automated scanners harvest keys
from repositories within minutes of push. The only
correct response to a committed key is: (1) revoke
the key immediately, (2) generate a new key, (3)
treat the old key as fully compromised.

---

### 🚨 Failure Modes and Diagnosis

**Failure: API key leaked via GitHub Actions log**

*Symptom:* Billing alert fires. Usage graph shows
spike from an unusual IP range. API key was valid
10 minutes after it appears in CI logs.

*Root cause:* A developer added a debug print that
included the API key value. GitHub Actions logs
are world-readable for public repositories.

*Immediate response:*
1. Revoke the key immediately (Anthropic console)
2. Generate a new key
3. Update secret in GitHub Actions Secrets
4. Review recent API usage for unauthorized calls
5. Contact Anthropic support if charges occurred

*Prevention:*
```bash
# In CI: ensure all secrets are masked
# GitHub Actions automatically masks values
# added as secrets.
# But: if you print the key from the environment,
# GitHub Actions adds it to the mask - test this.

# Better: never print env vars containing "key" or "token"
# Add linting rule: no print(os.environ["...KEY..."])
```

> **Code walkthrough:** This Add linting rule: no print(os.environ["...KEY..."]) example demonstrates shell script pattern using authentication. **KEY MECHANISM:** the shell executes commands sequentially; pipes pass stdout of one command to stdin of the next. **WHY IT MATTERS:** unquoted variables with spaces cause word splitting - IFS splits the value into multiple arguments. **TAKEAWAY: always double-quote variables: "$VAR"; use [[ ]] instead of [ ] for safer conditionals.**

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Secure storage | 2-3 min |
| Secrets manager integration | 3-4 min |
| Key rotation | 3-4 min |
| Incident response | 3-4 min |
| CI/CD security | 3-4 min |
| IAM-based alternatives | 3-4 min |
| Monitoring | 3-4 min |

---

**[JUNIOR] Q1 - How do you store LLM API keys
in a production application?**

*Why they ask:* Security basics.

Production secret storage: the key is never on
the server's filesystem or in the application's
environment variables directly (except injected
by the secrets manager).

AWS pattern:
1. Store key in AWS Secrets Manager at path
   `prod/app-name/anthropic-api-key`
2. Application code at startup:
   calls `GetSecretValue` via IAM role
3. IAM role: has only `secretsmanager:GetSecretValue`
   on that specific secret ARN
4. No credentials in application code or config

Kubernetes pattern:
1. Create Kubernetes Secret: `kubectl create secret generic`
2. Reference in pod spec as an environment variable
   or volume mount
3. RBAC: restrict which pods can access which secrets
4. External Secrets Operator: sync from Vault/AWS SM
   automatically

Docker/container pattern:
1. Never bake secrets into images
2. Inject at runtime via: environment variables
   (acceptable), secrets manager (best), Docker Secrets
   (for Docker Swarm)

*What separates good from great:* "IAM roles for
Bedrock eliminate API keys entirely - the best
secret is the one that doesn't exist."

---

**[MID] Q2 - How do you detect a leaked API key quickly?**

*Why they ask:* Incident detection.

Detection methods, fastest to most comprehensive:

(1) Billing alerts: configure a monthly budget
    alert at 50% and 100% thresholds. Unauthorized
    usage usually generates a large spike within
    hours. Alert fires within minutes of threshold.

(2) Usage monitoring: track requests per minute/hour
    in your own logging. Alert on: usage outside
    business hours, usage from unexpected IPs, sudden
    5x spikes in request volume.

(3) Provider dashboards: Anthropic, OpenAI, and Google
    all have usage dashboards with breakdowns by
    API key and time. Check these daily during incidents.

(4) Pre-commit scanning (preventing leaks):
    `gitleaks` scans for known API key patterns
    before every commit. `trufflehog` scans full
    git history. These prevent the leak rather than detect it after.

(5) GitHub Secret Scanning: GitHub automatically
    scans pushes for known API key formats and
    alerts the repository owner (and Anthropic directly
    for Anthropic keys).

Response SLA: a leaked key should be revoked within
5 minutes of detection. That's why automated billing
alerts and usage anomaly detection are critical.

*What separates good from great:* "GitHub Secret
Scanning is automatic for public repos - for private
repos, enable it in GitHub Advanced Security settings."

---

**[JUNIOR] Q3 - What happens if you commit an API
key to a public GitHub repo?**

*Why they ask:* Severity awareness.

Timeline of a committed API key incident:

T+0: developer pushes commit with hardcoded API key.

T+0 to T+5 min: GitHub Secret Scanning detects the
key format. Notifies Anthropic/OpenAI automatically.
Provider may revoke the key proactively.

T+0 to T+60 min: Automated scanners (bots scanning
GitHub for API key patterns) find the key.

T+30 to T+120 min: Automated exploitation starts.
Attackers run inference workloads at max rate.

T+1h to T+24h: Bill accumulates. At 4,000 RPM
using claude-3-5-sonnet: ~$10,000/hour.

What you MUST do:
1. Revoke the key immediately (before fixing code)
2. Generate a new key
3. Replace in production secrets management
4. Run `git filter-repo` to attempt removal
   (note: this doesn't help for public repos where
   the commit is already cached/cloned)
5. Contact Anthropic support to report unauthorized usage

*What separates good from great:* "Revoke first,
fix code second - every minute of hesitation is
potential hundreds in charges."

---

**[MID] Q4 - How do you implement API key rotation
without downtime?**

*Why they ask:* Operational rotation.

Key rotation without downtime requires having two
keys active simultaneously during the transition.

Procedure:
1. Generate new API key (keep old key active)
2. Deploy new key to secrets manager
   (stage: `prod/app/anthropic-key-v2`)
3. Deploy application update that reads from new path.
   Run alongside old version (blue-green or canary).
4. Verify new key is working (check API response metrics)
5. Revoke old key AFTER new version is fully deployed
6. Update secrets manager path back to canonical name

For rolling updates without key versioning:
1. Generate new key
2. Update secret in secrets manager (in-place)
3. Rolling restart application instances
   (each instance picks up new key on restart)
4. Revoke old key after all instances have restarted

AWS Secrets Manager Rotation:
- Supports automatic rotation with Lambda functions
- Built-in rotation schedules (quarterly, monthly)
- Zero-downtime rotation if application reads
  the secret at each request (not just at startup)

*What separates good from great:* "Read the secret
on each request or cache with short TTL (1 min)
rather than at startup - this enables rotation without deployment."

---

**[JUNIOR] Q5 - What is the risk of logging the
`ANTHROPIC_API_KEY` environment variable?**

*Why they ask:* Subtle security risk.

Logging the API key exposes it to:
- Log aggregation systems (Splunk, ELK, CloudWatch)
- Anyone with read access to logs
- Log exports, backups, and audit trails that
  may have broader retention and access policies

A developer may add:
```python
import os
print(f"Starting with key: {os.environ['ANTHROPIC_API_KEY']}")
```

> **Code walkthrough:** This Add linting rule: no print(os.environ["...KEY..."]) example demonstrates context manager. **KEY MECHANISM:** __enter__ acquires the resource; __exit__ always runs for cleanup even on exception. **WHY IT MATTERS:** forgetting with for file/connection objects leaks file descriptors and DB connections. **TAKEAWAY: always use with for any resource with explicit cleanup.**

This key is now in:
- Application stdout logs
- Container logs (Docker, Kubernetes)
- CloudWatch Logs (if on AWS)
- Any log aggregation pipeline

Depending on access policies, this exposes the key
to anyone who can read logs - often a much larger
group than those who can read secrets.

Prevention:
```python
key = os.environ.get("ANTHROPIC_API_KEY", "")
# Log presence, not value:
import sys
print(
    f"API key configured: {bool(key)}",
    file=sys.stderr
)
# Or log only prefix to verify format:
print(
    f"Key prefix: {key[:8]}...",
    file=sys.stderr
)
# Never: print(f"Key: {key}")
```

> **Code walkthrough:** This Never: print(f"Key: {key}") example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

*What separates good from great:* "Log boolean presence
or first 8 chars for format verification - never
the actual value."

---

**[MID] Q6 - How does AWS Bedrock eliminate API
key management?**

*Why they ask:* IAM-based auth alternative.

AWS Bedrock uses IAM authentication instead of API
keys. There is no `ANTHROPIC_API_KEY` to manage.

How it works:
1. Application runs on AWS (EC2, ECS, Lambda, EKS)
   with an IAM role attached
2. IAM role has `bedrock:InvokeModel` permission
   on the desired model ARN
3. The AWS SDK uses the instance's IAM credentials
   (automatically available via Instance Metadata Service)
4. Application code never handles a credential string

```python
import boto3
import json

bedrock = boto3.client(
    "bedrock-runtime",
    region_name="us-east-1"
)
# No api_key parameter - uses IAM role automatically

body = json.dumps({
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 1024,
    "messages": [
        {"role": "user", "content": "Hello!"}
    ]
})

response = bedrock.invoke_model(
    modelId="anthropic.claude-3-5-sonnet-20241022-v2:0",
    body=body
)
result = json.loads(response["body"].read())
print(result["content"][0]["text"])
```

> **Code walkthrough:** This uses IAM role automatically example demonstrates Python code pattern using authentication. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

Security benefits: no credential in code, no rotation
required (IAM credentials auto-rotate), audit trail
via CloudTrail (every Bedrock call is logged),
fine-grained IAM policies per model.

*What separates good from great:* "IAM-based auth
with CloudTrail is better than API keys for enterprise
compliance - every call is automatically audit-logged without custom instrumentation."

---

**[JUNIOR] Q7 - How do you set up billing alerts
for LLM API usage?**

*Why they ask:* Cost monitoring basics.

Anthropic:
1. Console -> Settings -> Billing
2. Set budget limit (hard cap on monthly spend)
3. Enable email alerts at 50% and 80% of budget
4. Anthropic suspends API on budget exhaustion
   (prevents runaway charges)

OpenAI:
1. Platform.openai.com -> Settings -> Limits
2. Set monthly usage limit
3. Configure email alerts at specified dollar amounts

Google (Gemini):
1. Google Cloud Console -> Billing -> Budgets
2. Create budget for Vertex AI / Generative AI
3. Configure Pub/Sub alerts for programmatic handling

Programmatic monitoring (all providers):
- Log `usage.input_tokens` and `usage.output_tokens` per call
- Aggregate in a time-series database
- Alert if: daily cost > threshold, hourly rate > 3x
  7-day average, single-caller usage spikes

```python
import time

def tracked_call(client, **kwargs):
    start = time.time()
    msg = client.messages.create(**kwargs)
    elapsed = time.time() - start

    # Emit metrics
    metrics.emit({
        "cost_usd": calculate_cost(msg.usage),
        "latency_ms": elapsed * 1000,
        "input_tokens": msg.usage.input_tokens,
        "output_tokens": msg.usage.output_tokens,
        "model": msg.model
    })
    return msg
```

> **Code walkthrough:** This Emit metrics example demonstrates function definition using authentication. **KEY MECHANISM:** Python compiles the function body to bytecode; default args are evaluated once at definition time. **WHY IT MATTERS:** mutable default arguments (def f(x=[])) share state across calls - a classic bug. **TAKEAWAY: use None as default for mutable args and initialize inside the function body.**

*What separates good from great:* "Per-call metrics
emitted to a TSDB give you minute-level visibility
and enable alerts on rate anomalies, not just total spend."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ security fundamentals keyword.)*

---

### 🏛️ System Design

*(Omit: L1 core usage keyword.)*

---

### 📊 Diagram

*(Omit: patterns clearer as code for this security topic.)*

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


# Streaming API Responses

**Interview Weight:** ★☆☆ - Streaming is the default
pattern for user-facing LLM applications. Not knowing
how to implement it signals that you haven't shipped
production AI features.

---

### 🎯 Model Answer

**30 seconds:**

> Streaming sends LLM output tokens to the client
> as they're generated, instead of waiting for the
> complete response. This reduces perceived latency:
> the user sees text appearing in real time (like
> ChatGPT's interface) rather than waiting 10-30
> seconds for a blank screen before seeing a wall
> of text. The Anthropic SDK supports streaming
> via `client.messages.stream()` context manager,
> which yields `text_delta` events. Server-Sent Events
> (SSE) is the standard for delivering this to web browsers.

**3 minutes:**

> Streaming matters for user experience. A 10-second
> Claude response that appears character by character
> feels fast. The same response appearing all at once
> after a 10-second wait feels slow. The total time
> is identical; the perception is completely different.
>
> The Anthropic streaming API uses Server-Sent Events:
> the HTTP connection stays open; the server sends
> events as tokens are generated. Each event is a
> typed object (content_block_delta with a text_delta).
>
> The Anthropic Python SDK provides a streaming
> context manager that handles the SSE protocol:
> `client.messages.stream()`. You iterate over
> events or text chunks. At the end, you can access
> the final accumulated message.
>
> For web applications, you proxy the stream from
> your backend to the browser using either SSE
> (EventSource API) or WebSockets. FastAPI supports
> SSE via `StreamingResponse`. The browser renders
> each chunk as it arrives.
>
> Streaming requires different error handling than
> standard API calls: errors can occur mid-stream
> after the response has started. You must handle
> this gracefully to avoid showing partial text
> followed by an error state.

**Blank Mind Recovery:**

**(1) Restate:** "Streaming: tokens arrive as they're
generated. User sees text appear in real time."

**(2) First principles:** "Same as video streaming:
start watching before the whole file downloads.
Reduce time-to-first-content."

**(3) Bridge:** "Same as watching ChatGPT type:
each word appears as it's generated. That's streaming."

---

### 📘 Concept Explanation

**What it is:**

Streaming API responses deliver LLM-generated tokens
to the caller incrementally as they are generated,
using Server-Sent Events over a persistent HTTP connection.

**The problem it solves:**

Without streaming: user waits 5-30 seconds for
a blank response area, then sees the full text appear
at once. Feels unresponsive. With streaming: text
appears within 1-2 seconds of the request and
builds character by character. Feels interactive.

**How it works:**

```
NON-STREAMING:

Client -> POST /v1/messages -> Server
                            <- (wait 15 seconds)
                            <- Full response (1500 tokens)

Total wait: 15s
Time to first content: 15s

STREAMING:

Client -> POST /v1/messages (stream=true) -> Server
                            <- token 1 (0.2s)
                            <- token 2 (0.4s)
                            <- token 3 (0.6s)
                            ...
                            <- token 1500 (15s)
                            <- [DONE]

Total wait: 15s (same)
Time to first content: 0.2s (75x faster perception)
```

> **Code walkthrough:** This Streaming API Responses example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**SSE event types in Anthropic streaming:**

```
message_start         - response metadata starts
content_block_start   - a new content block begins
content_block_delta   - a text chunk (delta)
content_block_stop    - content block finished
message_delta         - stop_reason, usage updates
message_stop          - stream complete
```

> **Code walkthrough:** This Streaming API Responses example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

For text generation: you only need `content_block_delta`
events where `delta.type == "text_delta"`. The
`delta.text` field contains the new text chunk.

---

### 💻 Code Example

```python
"""
Streaming LLM responses: console to web API.
"""
import anthropic
import os
import sys

client = anthropic.Anthropic(
    api_key=os.environ["ANTHROPIC_API_KEY"]
)

# --- PATTERN 1: CONSOLE STREAMING ---
def stream_to_console(prompt: str):
    """Print tokens as they arrive."""
    with client.messages.stream(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt}]
    ) as stream:
        for text in stream.text_stream:
            print(text, end="", flush=True)
        print()  # newline at end

        # Access the final message for metadata
        final = stream.get_final_message()
        print(
            f"\nTokens: {final.usage.input_tokens}"
            f"/{final.usage.output_tokens}",
            file=sys.stderr
        )


# --- PATTERN 2: COLLECT FULL RESPONSE ---
def stream_and_collect(prompt: str) -> str:
    """Stream but return the accumulated text."""
    with client.messages.stream(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[{"role": "user", "content": prompt}]
    ) as stream:
        # Accumulate while streaming
        chunks = []
        for text in stream.text_stream:
            chunks.append(text)
            # Optionally: write to stdout for progress
            print(".", end="", flush=True)
        print()
    return "".join(chunks)


# --- PATTERN 3: WEB SSE (FastAPI) ---
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import json

app = FastAPI()

@app.post("/api/chat")
async def chat_stream(body: dict):
    """Stream Claude response as SSE to browser."""

    async def generate():
        # Use async streaming for web apps
        async with client.messages.stream(
            model="claude-3-5-sonnet-20241022",
            max_tokens=2048,
            messages=body.get("messages", [])
        ) as stream:
            async for text in stream.text_stream:
                # SSE format: "data: {json}\n\n"
                yield (
                    f"data: {json.dumps({'text': text})}\n\n"
                )
            # Send done signal
            yield "data: [DONE]\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no"  # disable nginx buffering
        }
    )


# BROWSER-SIDE JAVASCRIPT:
# const source = new EventSource("/api/chat");
# source.onmessage = (e) => {
#   if (e.data === "[DONE]") { source.close(); return; }
#   const chunk = JSON.parse(e.data);
#   outputEl.textContent += chunk.text;
# };
```

> **Code walkthrough:** Three streaming patterns coverice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> the main use cases. Pattern 1 (console) uses the
> SDK's `text_stream` iterator which handles event
> parsing internally - each iteration yields a string
> chunk. The `flush=True` is critical: without it,
> Python's stdout buffering holds chunks until a
> full buffer is filled, destroying the streaming
> effect. `stream.get_final_message()` at the end
> provides usage stats after the stream completes.
> Pattern 2 (collect) streams for progress feedback
> but assembles the full response for downstream
> processing. Pattern 3 (FastAPI SSE) shows the
> web integration: async streaming with the SSE wire
> format (`data: {...}\n\n`). The `X-Accel-Buffering: no`
> header is essential for nginx-proxied deployments:
> nginx buffers SSE by default, destroying streaming.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "Streaming sends text to the user as it's generated
> instead of waiting for the full response. I use
> `client.messages.stream()` context manager and
> iterate over `stream.text_stream`. For web apps,
> I send each chunk as a Server-Sent Event. The user
> experience is dramatically better: they see text
> within 1-2 seconds instead of waiting 15+ seconds
> for the full response to appear."

---

**Senior / Staff:**

> "Streaming is the default for user-facing LLM features.
> The UX difference is significant - time-to-first-content
> transforms the perceived responsiveness. In production,
> streaming requires careful error handling: if the
> stream fails mid-response after partial content
> has been sent to the browser, the UI must handle
> a partial content state gracefully. In FastAPI,
> I wrap the streaming generator in a try/except
> and send an error SSE event on failure so the
> browser can show an appropriate error state. I
> also add `X-Accel-Buffering: no` to every SSE
> response when behind nginx - forgetting this means
> streaming is silently broken in production."

---

### ⚠️ Common Misconceptions

**Misconception: "Streaming is faster than non-streaming
in total time."**

Streaming does NOT reduce total generation time.
The total wall-clock time from request start to
last token is identical whether you use streaming
or not. Streaming only improves time-to-first-content:
you receive and can display the first token 0.2-0.5
seconds after the request starts, instead of waiting
for all tokens. The perception of speed improves
dramatically even though the total time doesn't change.

---

### 🚨 Failure Modes and Diagnosis

**Failure: SSE streaming works locally but
not behind nginx**

*Symptom:* Streaming API response arrives all at once
in production, not incrementally. Works perfectly
with `uvicorn` directly. Broken behind nginx.

*Root cause:* nginx buffers SSE by default. All
data is buffered until the connection closes, then
sent at once. This negates streaming.

*Fix:*

Option 1 - Add header in response:
```python
return StreamingResponse(
    generate(),
    media_type="text/event-stream",
    headers={
        "Cache-Control": "no-cache",
        "X-Accel-Buffering": "no",  # nginx: disable buffer
        "Connection": "keep-alive"
    }
)
```

> **Code walkthrough:** This }; example demonstrates Python code pattern. **KEY MECHANISM:** Python evaluates expressions at runtime; objects are reference-counted for garbage collection. **WHY IT MATTERS:** mutable shared state between threads requires explicit locking - the GIL only protects CPython internals. **TAKEAWAY: use threading.Lock for shared mutable state; prefer multiprocessing for CPU-bound parallelism.**

Option 2 - nginx config:
```nginx
location /api/chat {
    proxy_pass http://backend;
    proxy_buffering off;
    proxy_cache off;
    proxy_read_timeout 300s;  # longer timeout for streaming
}
```

> **Code walkthrough:** This }; example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Always test streaming behind the full proxy stack,
not just the app server. nginx buffering is invisible
to the app server - the logs show successful streaming
even when the client receives a batch.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| What is streaming | 2-3 min |
| SDK implementation | 3-4 min |
| Web SSE pattern | 3-4 min |
| Error handling | 3-4 min |
| nginx / proxy issues | 3-4 min |
| When NOT to stream | 3-4 min |
| Token accumulation | 3-4 min |

---

**[JUNIOR] Q1 - What is the difference between
streaming and non-streaming API responses?**

*Why they ask:* Baseline understanding.

Non-streaming: one HTTP request -> wait -> one HTTP response.
The entire generated text arrives as a single JSON blob.
Client waits for the full response. Simpler to implement.

Streaming: one HTTP request -> long-lived HTTP connection
(keep-alive). Server sends Server-Sent Events as
tokens are generated. Each event contains one or
a few tokens. Client receives and renders tokens
incrementally.

Comparison:

```
Non-streaming for a 500-token response:
  T+0:    Request sent
  T+10s:  Full response received (500 tokens)
  T+10s:  User sees text

Streaming for the same 500-token response:
  T+0:    Request sent
  T+0.3s: First token received. User sees "The..."
  T+1s:   50 tokens. User sees first sentence
  T+5s:   250 tokens. User is reading
  T+10s:  500 tokens. Generation complete
```

> **Code walkthrough:** This }; example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

For user-facing chat: streaming is always preferred.
For batch processing, background jobs, or when the
full response is needed before any action: non-streaming
is simpler and correct.

*What separates good from great:* "Total generation
time is identical - streaming improves perceived
speed, not actual speed."

---

**[JUNIOR] Q2 - How do you use the Anthropic SDK
for streaming?**

*Why they ask:* Practical implementation.

The Anthropic Python SDK provides `client.messages.stream()`
as a context manager. Inside the context, `stream.text_stream`
is an iterator yielding string chunks.

```python
import anthropic, os

client = anthropic.Anthropic(
    api_key=os.environ["ANTHROPIC_API_KEY"]
)

# Sync streaming
with client.messages.stream(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Tell me a joke."}
    ]
) as stream:
    for text_chunk in stream.text_stream:
        print(text_chunk, end="", flush=True)

# Async streaming (for FastAPI / async apps)
import asyncio

async def stream_async():
    async with client.messages.stream(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[
            {"role": "user", "content": "Tell me a joke."}
        ]
    ) as stream:
        async for text_chunk in stream.text_stream:
            print(text_chunk, end="", flush=True)

asyncio.run(stream_async())
```

> **Code walkthrough:** This Async streaming (for FastAPI / async apps) example demonstrates asyncio coroutine definition using Stream. **KEY MECHANISM:** the event loop schedules coroutines; await suspends execution until the awaited future resolves. **WHY IT MATTERS:** blocking call inside async def starves the event loop - all coroutines freeze. **TAKEAWAY: never use blocking I/O (requests, time.sleep) inside async def; use aiohttp, asyncio.sleep.**

`flush=True` on print is essential: without it
Python's stdout buffering accumulates chunks until
a buffer boundary, preventing the streaming effect.

For web applications: use the async version with
FastAPI's `StreamingResponse`.

*What separates good from great:* "flush=True is
the most common streaming bug in Python - always
add it or use a proper async write that doesn't buffer."

---

**[MID] Q3 - How do you send streaming LLM responses
to a browser?**

*Why they ask:* Web integration.

Browser streaming uses Server-Sent Events (SSE):
a standard where the server sends newline-delimited
events over a long-lived HTTP GET connection.

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import json, anthropic, os

client = anthropic.Anthropic(
    api_key=os.environ["ANTHROPIC_API_KEY"]
)
app = FastAPI()

@app.post("/stream")
async def stream_chat(body: dict):
    async def event_generator():
        try:
            async with client.messages.stream(
                model="claude-3-5-sonnet-20241022",
                max_tokens=1024,
                messages=body["messages"]
            ) as stream:
                async for chunk in stream.text_stream:
                    yield f"data: {json.dumps({'text': chunk})}\n\n"
            yield "data: [DONE]\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={"X-Accel-Buffering": "no"}
    )
```

> **Code walkthrough:** This Async streaming (for FastAPI / async apps) example demonstrates asyncio coroutine definition using Stream. **KEY MECHANISM:** the event loop schedules coroutines; await suspends execution until the awaited future resolves. **WHY IT MATTERS:** blocking call inside async def starves the event loop - all coroutines freeze. **TAKEAWAY: never use blocking I/O (requests, time.sleep) inside async def; use aiohttp, asyncio.sleep.**

Browser JavaScript:
```javascript
const res = await fetch('/stream', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({messages: [
    {role: 'user', content: 'Hello!'}
  ]})
});
const reader = res.body.getReader();
const decoder = new TextDecoder();
while (true) {
  const {done, value} = await reader.read();
  if (done) break;
  const lines = decoder.decode(value).split('\n');
  for (const line of lines) {
    if (line.startsWith('data: ')) {
      const data = line.slice(6);
      if (data === '[DONE]') break;
      const chunk = JSON.parse(data);
      if (chunk.text) outputEl.textContent += chunk.text;
    }
  }
}
```

> **Code walkthrough:** This Async streaming (for FastAPI / async apps) example demonstrates variable declaration using async/await. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

*What separates good from great:* "Include error
events in the SSE stream - the browser must handle
mid-stream failures gracefully."

---

**[JUNIOR] Q4 - When should you NOT use streaming?**

*Why they ask:* Trade-off understanding.

Don't use streaming when:

(1) The full response is needed before any action:
    if you're extracting JSON, parsing the response,
    or making a decision based on the full output,
    streaming complicates the code without benefit.
    Use non-streaming and parse the complete response.

(2) Background/batch jobs: no user is watching.
    Streaming adds overhead (SSE protocol, event
    parsing) for no UX benefit. Use batch API for
    bulk processing.

(3) Testing: non-streaming responses are simpler
    to assert in tests. Mock the response as a string.

(4) Simple classification/extraction: 16-token
    response for a classification task. Non-streaming
    is simpler and the latency difference is imperceptible.

(5) When downstream processing needs the full text:
    a pipeline that extracts entities from the full
    response doesn't benefit from streaming.

Rule: stream for user-facing chat or long-generation
features where the user is watching. Don't stream
for automated pipelines.

*What separates good from great:* "For tool use
(agentic workflows), streaming is useful for the
text portions but you need to handle the tool_use
blocks synchronously - a hybrid approach."

---

**[MID] Q5 - How do you handle errors that occur
mid-stream?**

*Why they ask:* Production reliability.

Mid-stream errors are harder than standard API errors
because the response has already started. The HTTP
200 status code was sent before the error occurred.

Types of mid-stream errors:
- Rate limit hit while generating (uncommon but possible)
- Network timeout (connection dropped)
- Provider-side error mid-generation

Handling with the SDK:

```python
import anthropic, os, sys

client = anthropic.Anthropic(
    api_key=os.environ["ANTHROPIC_API_KEY"]
)

accumulated = []
try:
    with client.messages.stream(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[...]
    ) as stream:
        for text in stream.text_stream:
            accumulated.append(text)
            yield text  # or write to response
except anthropic.APIStatusError as e:
    # Log error and partial content
    partial = "".join(accumulated)
    print(
        f"Stream error after {len(partial)} chars: {e}",
        file=sys.stderr
    )
    # Signal error to caller
    yield "[ERROR: response incomplete]"
```

> **Code walkthrough:** This Signal error to caller example demonstrates context manager using Stream. **KEY MECHANISM:** __enter__ acquires the resource; __exit__ always runs for cleanup even on exception. **WHY IT MATTERS:** forgetting with for file/connection objects leaks file descriptors and DB connections. **TAKEAWAY: always use with for any resource with explicit cleanup.**

For web applications: send an error SSE event so
the browser knows the stream ended abnormally and
can display an appropriate message.

*What separates good from great:* "Log the partial
content on stream error - the partial text is often
useful for debugging the prompt that caused the failure."

---

**[JUNIOR] Q6 - What is time-to-first-token (TTFT)?**

*Why they ask:* Performance metric knowledge.

TTFT: the time from when the API request is sent
to when the first token is received from the model.

This is the primary latency metric for streaming
applications. The user experience of "how fast does
it respond?" is determined by TTFT, not total generation time.

Typical TTFT for Claude: 0.2-1.0 seconds
(depends on model, server load, and network latency).

TTFT components:
- Network: client to Anthropic server
- Queuing: waiting in request queue
- Prefill: processing the input prompt
  (scales with context size - a 100K token context
  takes longer to prefill than 1K)

What degrades TTFT:
- Large context windows (more to prefill)
- Overloaded API (queuing time)
- Client-server network latency

For latency-sensitive applications: use claude-3-5-haiku
(fastest TTFT) and keep context windows minimal.

*What separates good from great:* "TTFT scales with
input context size - sending a 100K context means
the user waits longer for the first token, even
with streaming."

---

**[MID] Q7 - [TRADE-OFF] What is the infrastructure
overhead of streaming vs. non-streaming?**

*Why they ask:* System design awareness.

Non-streaming:
- Standard HTTP request/response cycle
- Connection released immediately after response
- Load balancer and reverse proxy behavior: standard
- Backend: no special handling needed
- Browser: standard fetch() API

Streaming:
- Long-lived HTTP connection (30-120 seconds typical)
- Connection held open for full generation time
- Load balancer: must support long-lived connections
  (not all do). AWS ALB max idle timeout: 60 seconds
  (must increase for long generations). Configure
  `proxy_read_timeout` in nginx.
- Reverse proxy: must disable buffering
  (nginx: `proxy_buffering off`)
- Backend: must use async (non-blocking) I/O
  (synchronous handlers block during generation)
- Browser: EventSource or fetch with ReadableStream
- Connection count: one per active streaming user
  (a streaming app with 100 concurrent users holds
  100 persistent connections to the backend)

Infrastructure rule: streaming requires configuring
every component in the proxy chain for long connections.
Non-streaming just works.

*What separates good from great:* "AWS ALB 60-second
idle timeout is the most common production failure
for streaming - set it to 300s before launching."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ operational keyword.)*

---

### 🏛️ System Design

*(Omit: L1 core usage keyword.)*

---

### 📊 Diagram

*(Omit: time sequence clearer as text for this concept.)*

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



