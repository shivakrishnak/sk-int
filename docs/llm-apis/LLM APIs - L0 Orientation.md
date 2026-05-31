---
layout: default
title: "LLM APIs - L0 Orientation"
parent: "LLM APIs"
nav_order: 1
permalink: /llm-apis/l0-orientation/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [LLM API Landscape](#llm-api-landscape) | ★☆☆ |
| 2 | [Claude API Overview](#claude-api-overview) | ★☆☆ |
| 3 | [GitHub Copilot Overview](#github-copilot-overview) | ★☆☆ |

---

# LLM API Landscape

**Interview Weight:** ★☆☆ - Orientation knowledge.
Expected of any engineer working on AI features.
Inability to describe the LLM API landscape signals
inexperience with the current AI engineering ecosystem.

---

### 🎯 Model Answer

**30 seconds:**

> The LLM API landscape consists of cloud API providers
> offering language model capabilities over HTTP.
> The three major providers are Anthropic (Claude),
> OpenAI (GPT series), and Google (Gemini). Each
> exposes a messages/chat completions API where you
> send a conversation (system prompt + user messages)
> and receive a text response. Beyond raw APIs,
> developer tools like GitHub Copilot embed LLMs
> directly into development workflows via IDE extensions
> and agent mode, abstracting the API entirely.

**3 minutes:**

> The LLM API landscape divides into three layers.
>
> Layer 1 - Foundation Model APIs: direct access to
> large language models from cloud providers. Anthropic
> provides the Claude API (claude-3-5-sonnet, claude-opus-4, etc.).
> OpenAI provides the GPT API (gpt-4o, o1, o3 series).
> Google provides the Gemini API. AWS provides Bedrock
> (a meta-API supporting multiple models). Azure
> provides OpenAI Service (hosted OpenAI models).
>
> Layer 2 - Development Tools: tools that embed LLMs
> into developer workflows without direct API access.
> GitHub Copilot is the dominant example: code completion,
> chat, and agent mode in VS Code. JetBrains AI
> Assistant, Cursor, and similar tools follow the
> same pattern.
>
> Layer 3 - Frameworks and Orchestration: libraries
> that orchestrate multiple LLM calls, tool use,
> and agent workflows. LangChain, LlamaIndex, AutoGen,
> CrewAI. These are built on top of Layer 1 APIs.
>
> Key differentiation between providers: context
> window (how much text can be in one request),
> model capability (reasoning quality, instruction
> following), pricing (per-token costs), latency
> (time to first token), and tool use support (structured
> function calling).

**Blank Mind Recovery:**

**(1) Restate:** "LLM API landscape. Three major providers:
Anthropic Claude, OpenAI GPT, Google Gemini."

**(2) First principles:** "All LLM APIs share the same
basic interface: send text in, get text out. Differences
are in quality, context window, price, and speed."

**(3) Bridge:** "Same as cloud databases: AWS RDS,
Azure SQL, Google Cloud SQL. Same concept, different
providers. Choose based on your specific requirements."

---

### 📘 Concept Explanation

**What it is:**

The LLM API landscape is the ecosystem of cloud-hosted
large language model services accessible via HTTP,
plus the developer tooling built on top of them.

**The problem it solves:**

Training large language models requires millions of
dollars of compute. The API model enables every
developer to use frontier AI models without training
infrastructure - same as cloud databases enabled
every developer to use enterprise databases.

**How it works:**

```
LLM API LANDSCAPE OVERVIEW:

Foundation APIs:
  Anthropic   -> claude-3-5-sonnet-20241022
                 claude-opus-4-5 (most capable)
                 claude-haiku-3-5 (fastest)

  OpenAI      -> gpt-4o, gpt-4o-mini
                 o1, o3 (reasoning models)
                 o4-mini

  Google      -> gemini-2.5-pro (long context)
                 gemini-2.5-flash (fast)

  AWS Bedrock -> wrapper around Anthropic, Meta,
                 Mistral, Amazon Titan

Developer Tools:
  GitHub Copilot -> code completion + chat + agents
  Cursor         -> AI-native code editor
  Codeium        -> multi-IDE completions

Frameworks:
  LangChain, LlamaIndex, AutoGen, CrewAI
  (orchestrate the Foundation APIs above)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Key comparison dimensions:**

Context window: how many tokens (roughly, words/4)
fit in one request. Claude 3.5 Sonnet: 200K tokens.
Gemini 2.5 Pro: 1M tokens. GPT-4o: 128K tokens.

Pricing (mid-2025 approximate):
- Claude 3.5 Haiku: $0.80/$4 per MTok in/out
- Claude 3.5 Sonnet: $3/$15 per MTok in/out
- GPT-4o mini: $0.15/$0.60 per MTok in/out
- GPT-4o: $2.50/$10 per MTok in/out

**When each provider is preferred:**

Claude: long-document analysis, coding tasks, nuanced
instruction following, tool use, safety-critical applications.

OpenAI: existing OpenAI integrations, Azure enterprise
deployments, o-series reasoning models for math/code.

Google Gemini: native Google Cloud users, very long
context (1M tokens), multimodal (video + audio + text).

AWS Bedrock: organizations requiring data residency,
AWS-native workloads, model flexibility without
vendor lock-in at the infrastructure level.

---

### 💻 Code Example

```python
"""
LLM API landscape: same task, three providers.
Shows the API surface is conceptually identical.
"""
import os

# --- ANTHROPIC CLAUDE ---
import anthropic

def ask_claude(question: str) -> str:
    client = anthropic.Anthropic(
        api_key=os.environ["ANTHROPIC_API_KEY"]
    )
    msg = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=256,
        messages=[{"role": "user", "content": question}]
    )
    return msg.content[0].text


# --- OPENAI GPT ---
from openai import OpenAI

def ask_gpt(question: str) -> str:
    client = OpenAI(
        api_key=os.environ["OPENAI_API_KEY"]
    )
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": question}],
        max_tokens=256
    )
    return resp.choices[0].message.content


# --- GOOGLE GEMINI ---
import google.generativeai as genai

def ask_gemini(question: str) -> str:
    genai.configure(api_key=os.environ["GEMINI_API_KEY"])
    model = genai.GenerativeModel("gemini-2.5-flash")
    resp = model.generate_content(question)
    return resp.text


# All three: send question, get text back.
# The interface is conceptually identical.
# Differences: SDK shape, token limits, pricing.
```

> **Code walkthrough:** All three providers follow
> the same fundamental pattern: create a client with
> an API key, specify a model, pass a message, receive
> text. The Anthropic SDK uses `messages.create()`
> with a `messages` list; OpenAI uses `chat.completions.create()`
> with the same structure; Gemini uses `generate_content()`.
> Each returns a response object with different paths
> to the actual text. This structural similarity
> is why abstraction frameworks like LangChain can
> wrap all three: the conceptual interface is the
> same even if the SDK surfaces differ. The key
> variable across providers is the model identifier
> (different naming schemes) and the response parsing.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "The three major LLM API providers are Anthropic
> (Claude), OpenAI (GPT), and Google (Gemini). Each
> lets you send a text message and get a response back.
> The main differences are model capability, context
> window size, and pricing. For development tools,
> GitHub Copilot embeds Claude and GPT into VS Code
> for code completion and chat - that's a Layer 2 tool
> built on top of the Layer 1 APIs."

---

**Senior / Staff:**

> "When evaluating LLM API providers, I look at four
> dimensions: capability (does it follow instructions
> correctly at my complexity level?), context window
> (can it handle my document sizes?), pricing at
> scale (what does $1000/month buy?), and SLA (uptime,
> rate limits, data retention policies). I also consider
> ecosystem: does the provider offer batch processing?
> Prompt caching? MCP support? The API surface is
> commodity - the differentiation is in performance,
> reliability, and the value-added features around
> the core inference API."

---

### ⚠️ Common Misconceptions

**Misconception: "OpenAI is the only LLM API provider
that matters."**

OpenAI's early market position created this perception.
By 2025, Anthropic's Claude models consistently
outperform on coding and instruction-following benchmarks.
Google's Gemini leads on context length. AWS Bedrock
provides enterprise compliance and model flexibility
that OpenAI's direct API doesn't offer. Provider
selection should be based on capability benchmarks,
not name recognition.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Hard-coded provider-specific API shapes
make switching providers expensive**

*Symptom:* The team wants to switch from OpenAI GPT-4o
to Claude for better instruction following. The
migration takes 3 weeks because every API call
is hand-coded for OpenAI's response format.

*Root cause:* No abstraction layer between the
application and the provider SDK.

*Fix:* Introduce a thin adapter interface:

```python
from abc import ABC, abstractmethod

class LLMClient(ABC):
    @abstractmethod
    async def complete(
        self,
        messages: list[dict],
        max_tokens: int = 1024
    ) -> str:
        ...

class AnthropicClient(LLMClient):
    async def complete(self, messages, max_tokens=1024):
        import anthropic, os
        client = anthropic.Anthropic(
            api_key=os.environ["ANTHROPIC_API_KEY"]
        )
        msg = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=max_tokens,
            messages=messages
        )
        return msg.content[0].text

# Switching providers: swap AnthropicClient for
# OpenAIClient. Application code unchanged.
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Landscape overview | 2-3 min |
| Provider comparison | 3-4 min |
| Pricing / scale | 3-4 min |
| API abstraction | 3-4 min |
| Provider selection | 3-4 min |
| Trade-off | 3-4 min |
| Practical scenario | 3-4 min |

---

**[JUNIOR] Q1 - Name the three major LLM API providers
and their model families.**

*Why they ask:* Baseline knowledge.

Anthropic: Claude model family. Current: claude-3-5-sonnet-20241022
(strong all-around), claude-3-5-haiku-20241022 (fast/cheap),
claude-opus-4-5 (most capable). Anthropic's focus:
safety, instruction following, coding.

OpenAI: GPT and o-series families. GPT-4o (multimodal,
fast), GPT-4o-mini (cheap), o1/o3 (chain-of-thought
reasoning). OpenAI's focus: reasoning (o-series),
multimodal, ecosystem breadth.

Google: Gemini family. Gemini-2.5-pro (1M token context,
best long-doc), Gemini-2.5-flash (fast, cheap).
Google's focus: context length, multimodal, native
Google Cloud integration.

Bonus: Meta's Llama models (open source, self-hosted
or via Bedrock/Together), Mistral (European provider,
open-weight models), Cohere (enterprise/RAG focus).

*What separates good from great:* "Knowing the current
model names signals active engagement with the field -
the landscape changes every few months."

---

**[JUNIOR] Q2 - What is the difference between a
foundation API and a developer tool like GitHub Copilot?**

*Why they ask:* Ecosystem understanding.

Foundation API: direct HTTP access to a large language
model. You send API calls, manage API keys, pay
per token, and build your own application logic.
Full control, full responsibility. Examples: Anthropic
API, OpenAI API, Google Gemini API.

Developer tool: an application built on top of
foundation APIs, designed for a specific workflow
and embedded in specific tooling. GitHub Copilot
is built on top of OpenAI/Anthropic APIs but exposes
a higher-level interface: code completions appear
inline as you type; chat answers questions about
your codebase; agent mode runs multi-step tasks.

You don't call Copilot's API manually with `curl`.
Copilot is a product; the LLM API is infrastructure.

The distinction matters for pricing and control:
Copilot is a flat subscription ($10-39/month). The
underlying API would cost $2-15 per million tokens.
For individual developers: Copilot is usually cheaper.
For high-volume automated workflows: direct API
is usually cheaper.

*What separates good from great:* "Copilot is a product
with UX and workflow integration on top of the same
foundation APIs - knowing this helps decide which
layer to build at."

---

**[MID] Q3 - How does context window size affect
LLM API selection?**

*Why they ask:* Practical decision criteria.

Context window: the maximum number of tokens in
a single API request (input + output combined).

Impact on use cases:

Document Q&A (one large doc in context): Gemini 2.5
Pro (1M tokens = ~750K words) handles entire books.
Claude 3.5 Sonnet (200K = ~150K words) handles
most long documents. GPT-4o (128K = ~96K words)
handles smaller docs.

Multi-turn conversation: context fills as the
conversation grows. At 100 turns of 500 words each:
50K tokens. All providers handle this. At 1000
turns: 500K tokens. Only Gemini handles this natively.

Code analysis (entire codebase): a medium codebase
(500K tokens) requires chunking on GPT-4o (128K)
but fits in Claude (200K) with careful management.

Pricing impact: context window cost scales with
usage. Sending 100K tokens of context in every
request costs 100x more than sending 1K tokens.
Even with large context windows available, using
minimum necessary context reduces costs.

Selection rule: choose the provider whose context
window is large enough for your p95 use case.
Don't pay for more than you need.

*What separates good from great:* "Context efficiency
matters as much as context size - 200K tokens of
context at every API call is expensive. Use retrieval
(RAG) to reduce context while still handling large datasets."

---

**[MID] Q4 - What factors determine LLM API cost
at scale?**

*Why they ask:* Production cost awareness.

LLM API pricing components:

(1) Input tokens: tokens in your request (system
    prompt + conversation history + user message).
    Priced lower than output (typically 3-5x less).

(2) Output tokens: tokens in the model's response.
    Priced higher because generation is compute-intensive.

(3) Prompt caching: providers offer discounted rates
    for repeated prefixes (system prompts, document context).
    Anthropic: cached tokens at 10% of input cost.
    Up to 90% savings on repeated context.

Cost at scale example (1 million requests/day):
- Avg request: 500 input tokens + 200 output tokens
- Claude 3.5 Sonnet: $3/MTok in, $15/MTok out
- Daily cost: (500M * $3/1M) + (200M * $15/1M)
             = $1,500 + $3,000 = $4,500/day
- Monthly: ~$135,000

With prompt caching (if 80% of input is the same
system prompt):
- Cached: 400 tokens * $0.30/MTok = $0.12/MTok effective
- Non-cached: 100 tokens * $3/MTok
- New effective cost: much lower (60-80% savings)

*What separates good from great:* "Prompt caching
is the highest-leverage cost optimization - it
can reduce costs by 60-80% for applications with
consistent system prompts."

---

**[JUNIOR] Q5 - What is an LLM API rate limit?**

*Why they ask:* Baseline operational knowledge.

Rate limits: per-provider caps on API usage to
prevent overloading infrastructure and to tier pricing.

Typical dimensions:
- Requests per minute (RPM): max API calls/minute
- Tokens per minute (TPM): max tokens consumed/minute
- Tokens per day (TPD): daily token budget
- Requests per day (RPD): daily request count

Anthropic rate limits (Tier 1 starting):
- 50 RPM, 40,000 TPM, 1,000,000 TPD

Enterprise limits (Tier 4+):
- 4,000 RPM, 400,000 TPM, unlimited TPD

When you hit a rate limit: the API returns HTTP 429.
Your code must implement exponential backoff and retry.

Common operational issue: batch jobs that don't
respect rate limits get 429 errors, fail silently,
and produce incomplete results.

*What separates good from great:* "Rate limits
differ by tier and model - haiku has higher limits
than sonnet which has higher limits than opus, by design."

---

**[MID] Q6 - [TRADE-OFF] What are the advantages
and disadvantages of using AWS Bedrock vs. calling
the Anthropic API directly?**

*Why they ask:* Provider selection reasoning.

Anthropic direct:
+ Latest models immediately on release
+ Native Anthropic features (prompt caching, batch API)
+ Simpler SDK (`pip install anthropic`)
+ Direct relationship with Anthropic support
- Single-vendor dependency
- Not in AWS billing/IAM ecosystem

AWS Bedrock:
+ AWS IAM authentication (no API keys in code)
+ AWS CloudTrail audit logging (automatic)
+ VPC deployment (no internet egress)
+ Unified billing with other AWS services
+ Model flexibility (swap to Meta Llama, Mistral, etc.)
+ AWS enterprise SLAs and data residency controls
- Models available after delay post-Anthropic release
- Some Anthropic features not available (prompt caching)
- Bedrock API shape differs from Anthropic native
- Higher operational complexity

Decision rule: use Anthropic direct for projects
where latest features and simplest integration matter.
Use Bedrock for enterprise organizations requiring
AWS compliance (HIPAA, FedRAMP), VPC-only deployments,
or centralized multi-model API management.

*What separates good from great:* "IAM-based auth
is Bedrock's strongest argument for enterprise - no
API keys means no API key leakage in CI/CD pipelines."

---

**[JUNIOR] Q7 - How do you handle an LLM API key securely?**

*Why they ask:* Security fundamentals.

LLM API keys are credentials that grant billable
access to the provider. Leaked keys have caused
$50,000+ unauthorized charges in hours.

Secure handling:

1. Never hard-code keys in source code:
```python
# BAD: key in source (leaks via git history)
client = anthropic.Anthropic(
    api_key="sk-ant-api03-..."
)

# GOOD: key from environment variable
import os
client = anthropic.Anthropic(
    api_key=os.environ["ANTHROPIC_API_KEY"]
)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

2. Never commit keys to git:
   - `.env` files must be in `.gitignore`
   - Use `git secret` or similar for encrypted storage
   - Pre-commit hooks: `gitleaks`, `trufflehog`

3. In production: use secrets management:
   - AWS Secrets Manager / Parameter Store
   - HashiCorp Vault
   - Kubernetes Secrets (with RBAC)
   - GitHub Actions Secrets (for CI/CD)

4. Key rotation: rotate keys quarterly or
   immediately on suspected exposure.

5. Monitor usage: set billing alerts. Unexpected
   cost spikes indicate key leakage.

*What separates good from great:* "Pre-commit hooks
(gitleaks) are the last line of defense before
a key reaches git history, where it's very hard to truly remove."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ orientation keyword.)*

---

### 🏛️ System Design

*(Omit: L0 orientation keyword.)*

---

### 📊 Diagram

*(Omit: landscape is clearer as structured text.)*

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


# Claude API Overview

**Interview Weight:** ★☆☆ - Any engineer using Claude
should know the API surface: models, messages API,
key parameters, pricing tiers, and the capabilities
that distinguish Claude from other providers.

---

### 🎯 Model Answer

**30 seconds:**

> The Claude API from Anthropic is accessed via HTTP
> or the Python/TypeScript SDKs. The core interface
> is the Messages API: you provide a model ID, optional
> system prompt, a list of messages (user/assistant
> alternating), and `max_tokens`. Claude returns
> a response message. Key Claude differentiators:
> 200K token context window, strong instruction following,
> native tool use (function calling), prompt caching
> (90% cost reduction on repeated context), and
> the Batch API for async bulk processing.

**3 minutes:**

> The Claude API exposes three primary capabilities.
>
> Messages API (core): stateless request-response.
> Each call is independent. You manage conversation
> history by passing previous messages. The API
> does not store state.
>
> Tool Use: Claude can call structured tools (functions)
> you define. You pass tool definitions, Claude
> returns tool calls (in structured JSON), your
> code executes them and returns results, Claude
> incorporates the results. This is the foundation
> for agentic AI patterns.
>
> Streaming: instead of waiting for the complete
> response, receive text tokens as they are generated.
> Critical for user-facing applications where
> time-to-first-token matters.
>
> Advanced features: Prompt Caching (cache the
> system prompt + documents, pay 10% of normal
> input cost for cached hits), Batch API (send
> up to 10,000 requests in one batch, 50% cost
> discount, 24h completion SLA), Vision (send
> images for analysis), Computer Use (Claude
> can control a computer directly).

**Blank Mind Recovery:**

**(1) Restate:** "Claude API. Messages API: system prompt,
messages list, max_tokens. Returns response text."

**(2) First principles:** "All LLM APIs are the same:
text in, text out. Claude's differentiators are
context window (200K), instruction following quality,
and prompt caching."

**(3) Bridge:** "Same structure as any chat API.
You've used it with OpenAI? Same concept: system
prompt + user messages + get response."

---

### 📘 Concept Explanation

**What it is:**

The Claude API is Anthropic's REST API providing
access to Claude language models for text generation,
tool use, vision, and streaming.

**The problem it solves:**

Provides programmatic access to Claude's reasoning
and language capabilities without managing model
infrastructure.

**How it works:**

```
REQUEST STRUCTURE:
POST https://api.anthropic.com/v1/messages

Headers:
  x-api-key: $ANTHROPIC_API_KEY
  anthropic-version: 2023-06-01
  content-type: application/json

Body:
  model: "claude-3-5-sonnet-20241022"
  max_tokens: 1024
  system: "You are a helpful assistant."  # optional
  messages: [
    {"role": "user",   "content": "Hello!"},
    {"role": "assistant", "content": "Hi there!"},
    {"role": "user",   "content": "What is 2+2?"}
  ]

RESPONSE:
  id: "msg_..."
  type: "message"
  role: "assistant"
  content: [{"type": "text", "text": "4"}]
  model: "claude-3-5-sonnet-20241022"
  stop_reason: "end_turn"
  usage: {input_tokens: 28, output_tokens: 3}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Claude model tiers:**

- claude-3-5-haiku: fastest, cheapest. Good for
  simple classification, extraction, formatting.
- claude-3-5-sonnet: balanced. Best for most tasks.
  Default choice.
- claude-opus-4-5: most capable. Complex reasoning,
  nuanced analysis. Most expensive.

**Key parameters:**

- `max_tokens`: hard limit on response length.
  Claude stops at this limit even mid-sentence.
  Set generously (4096+) for open-ended tasks.
- `temperature`: 0.0 = deterministic, 1.0 = creative.
  Default is 1.0. For data extraction: use 0.0.
  For creative writing: use 1.0.
- `system`: system-level instructions that set
  Claude's role and constraints. Not part of messages.
- `stop_sequences`: text patterns that terminate
  generation early. Useful for structured output.

---

### 💻 Code Example

```python
"""
Claude Messages API: minimal to production pattern.
"""
import anthropic
import os

client = anthropic.Anthropic(
    api_key=os.environ["ANTHROPIC_API_KEY"]
)

# MINIMAL - simplest possible call
def ask_claude_minimal(question: str) -> str:
    msg = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[{"role": "user", "content": question}]
    )
    return msg.content[0].text


# WITH SYSTEM PROMPT - set role and constraints
def analyze_sentiment(text: str) -> str:
    msg = client.messages.create(
        model="claude-3-5-haiku-20241022",
        max_tokens=64,
        system=(
            "You are a sentiment classifier. "
            "Respond with exactly one word: "
            "POSITIVE, NEGATIVE, or NEUTRAL."
        ),
        messages=[
            {"role": "user", "content": text}
        ]
    )
    return msg.content[0].text.strip()


# MULTI-TURN CONVERSATION - manage history manually
def chat_session():
    history = []

    def chat(user_message: str) -> str:
        history.append({
            "role": "user",
            "content": user_message
        })
        msg = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            system="You are a helpful assistant.",
            messages=history
        )
        reply = msg.content[0].text
        history.append({
            "role": "assistant",
            "content": reply
        })
        return reply

    print(chat("My name is Alex."))
    # "Nice to meet you, Alex!"
    print(chat("What's my name?"))
    # "Your name is Alex."
    # History was passed - Claude remembers it.


# INSPECT USAGE - track token consumption
def ask_with_usage(question: str) -> dict:
    msg = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[{"role": "user", "content": question}]
    )
    return {
        "text": msg.content[0].text,
        "input_tokens": msg.usage.input_tokens,
        "output_tokens": msg.usage.output_tokens,
        "stop_reason": msg.stop_reason
    }
```

> **Code walkthrough:** Four patterns in increasing
> complexity. The minimal call shows the essential
> three parameters: model, max_tokens, messages.
> The sentiment classifier shows how `system` prompt
> constrains Claude's output format - adding "respond
> with exactly one word" makes the output predictable
> and parseable. Multi-turn conversation shows that
> Claude is stateless: you must manually append
> each exchange to the history list and pass the
> full history in every request. The usage inspection
> shows `msg.usage` - always monitor token consumption
> in production for cost tracking and anomaly detection.
> `stop_reason: "end_turn"` is normal completion;
> `stop_reason: "max_tokens"` means the response
> was cut short - a signal to increase `max_tokens`.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "The Claude API's main interface is `messages.create`.
> You pass a model ID, how many tokens the response
> can use, an optional system prompt, and the conversation
> history. Claude returns the response text and
> token usage stats. For most tasks I use claude-3-5-sonnet;
> for fast/cheap tasks I use claude-3-5-haiku.
> The API is stateless - I have to include the
> full conversation history in every call."

---

**Senior / Staff:**

> "The Claude API differentiates on three features
> that matter operationally. Prompt caching: if my
> system prompt and document context are the same
> across requests, I can cache them for 90% cost
> reduction - essential at scale. The Batch API:
> for async workloads that don't need real-time
> response, batch processing saves 50% and removes
> rate limit pressure. Tool use: Claude's structured
> tool calling is reliable enough for production
> agentic workflows. I evaluate the API choice
> per workflow: streaming for user-facing, batch
> for background processing, cached prompts for
> any task with consistent context."

---

### ⚠️ Common Misconceptions

**Misconception: "The Claude API maintains conversation
state between calls."**

The Claude API is fully stateless. Each `messages.create()`
call is independent. If you want Claude to "remember"
previous turns, you must include them in the `messages`
list. Forgetting to include history is a common bug:
the second question appears to Claude as the first
message in a new conversation. The conversation
grows with each turn - memory management (truncation
or summarization) is your responsibility.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Response cut off mid-sentence (`stop_reason: max_tokens`)**

*Symptom:* Claude's responses are truncated. You
receive partial JSON, half-written paragraphs.

*Diagnosis:* Check `msg.stop_reason`.
If `"max_tokens"`: the `max_tokens` limit was hit.

*Fix:* Increase `max_tokens`. The per-request cost
for output tokens is small compared to the cost
of a useless truncated response. Common mistake:
setting `max_tokens=256` for a task that generates
long outputs. Use 4096 as the default unless you
specifically need short responses.

```python
# BAD: will truncate long analysis
msg = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=256,   # too small
    messages=[...]
)

# GOOD: generous limit, check stop reason
msg = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=4096,
    messages=[...]
)
if msg.stop_reason == "max_tokens":
    import sys
    print("WARN: response truncated", file=sys.stderr)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| API surface | 2-3 min |
| Models + use cases | 3-4 min |
| Stateless design | 3-4 min |
| Prompt caching | 3-4 min |
| Tool use | 3-4 min |
| Cost optimization | 3-4 min |
| Debugging | 3-4 min |

---

**[JUNIOR] Q1 - What are the three Claude model
tiers and when do you use each?**

*Why they ask:* Practical knowledge.

Claude-3-5-haiku: fastest, cheapest (~$0.80/$4
per MTok in/out). Use for: classification, short
extractions, simple transformations, high-volume
routing tasks where quality requirements are modest.
Not for: complex reasoning, nuanced analysis, long
generations.

Claude-3-5-sonnet: balanced ($3/$15 per MTok in/out).
The default choice for most tasks. Excellent at:
coding, analysis, document Q&A, tool use, complex
instructions. The cost-quality sweet spot.

Claude-opus-4-5: most capable ($15/$75 per MTok in/out).
Use only for tasks that actually require it: complex
multi-step reasoning, expert-level analysis, tasks
where haiku/sonnet produce incorrect results.
5x the cost of sonnet.

Decision rule: start with sonnet for new tasks.
If quality is insufficient, move to opus.
If quality is more than sufficient and cost matters,
move to haiku.

*What separates good from great:* "Most tasks don't
need opus - defaulting to sonnet and using haiku
for high-volume simple tasks reduces costs by 4-10x."

---

**[MID] Q2 - What is the `system` parameter and
how does it differ from a first user message?**

*Why they ask:* Understanding the API design.

System prompt: passed as the `system` string parameter,
not as a message. It sets Claude's role, constraints,
and behavioral instructions. Claude treats it differently
from user messages: it has higher authority, it's
always "in context" regardless of message count,
and it's factored into how Claude interprets everything
that follows.

Difference from a first user message:
- System prompt is not part of the turn structure
  (user/assistant alternation). It's separate context.
- Prompt caching is enabled for system prompts:
  cached at `cache_control: {"type": "ephemeral"}`.
  A 5,000-token system prompt sent in 1000 requests
  costs $0.30/MTok cached vs. $3/MTok uncached = 90% savings.
- Role instruction in a user message is weaker than
  in the system prompt. "Pretend you're a pirate"
  in a user message is a request; in the system
  prompt it's a directive Claude follows consistently.

When the system prompt should be long: when you need
persistent context (document content), detailed
behavioral constraints (safety guardrails), or role
definitions that apply to all turns.

*What separates good from great:* "System prompt
gets prompt caching - put stable context there, not in the messages list."

---

**[JUNIOR] Q3 - What does `stop_reason: "end_turn"`
vs. `"max_tokens"` mean?**

*Why they ask:* Response parsing.

`stop_reason: "end_turn"`: Claude finished responding
naturally. It reached the end of its response and
stopped. This is the happy path.

`stop_reason: "max_tokens"`: generation was forcibly
stopped because the `max_tokens` limit was reached.
The response is truncated mid-generation. This is
a potential problem: you may receive an incomplete
response. For structured output (JSON, code), this
can cause unparseable responses.

`stop_reason: "stop_sequence"`: generation stopped
because a `stop_sequences` pattern was matched.
This is expected and controlled behavior when you've
set stop sequences.

`stop_reason: "tool_use"`: Claude wants to call
a tool. It's not done responding - it's pausing
to execute a tool. You must handle the tool call,
return the result, and continue the conversation.

Action on `max_tokens`: always log it as a warning
and consider increasing `max_tokens`. For structured
outputs, the caller should detect and handle truncation.

*What separates good from great:* "Always check
stop_reason in production - silent max_tokens truncations
produce subtly wrong results that are hard to detect without logging."

---

**[MID] Q4 - What is prompt caching and when does
it apply?**

*Why they ask:* Cost optimization knowledge.

Prompt caching: Anthropic caches portions of the
context marked with `cache_control` so that repeated
API calls with the same prefix pay only 10% of
the normal input token cost.

How it works: on the first call, the marked portion
is processed and cached (costs 125% of normal price
for this call - the cache write). On all subsequent
calls with the same content: 10% of normal price
(cache hit). Cache lifetime: 5 minutes (extended
to 1 hour with a flag).

When to cache:
- System prompts (same for all requests in an app)
- Reference documents (legal text, code files, manuals)
- Few-shot examples (the same examples in every request)

```python
msg = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    system=[
        {
            "type": "text",
            "text": system_prompt,
            "cache_control": {"type": "ephemeral"}
        }
    ],
    messages=[{"role": "user", "content": question}]
)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Savings calculation: 10,000 RPD * 5,000-token system
prompt = 50M input tokens/day. Without caching:
$150/day. With caching (99% hits): ~$16/day. Savings: 89%.

*What separates good from great:* "Cache write costs 25% more on the first call
- use caching only for prompts that repeat across many calls, not for unique prompts."

---

**[MID] Q5 - How does the Batch API differ from
regular API calls?**

*Why they ask:* Async processing knowledge.

Regular API: synchronous. You send a request and
wait for the response (typically 1-30 seconds).
Rate limits apply: 50-4000 RPM depending on tier.

Batch API: asynchronous. You submit a batch of
up to 10,000 requests in one call. Anthropic processes
them within 24 hours. You poll for completion.
Results are returned as a JSONL file.

Advantages:
- 50% cost discount on all requests
- No rate limits: send 10,000 requests regardless of RPM tier
- Simplified infrastructure: no queue management needed

Disadvantages:
- Not for real-time applications (24h SLA)
- Results arrive out-of-order
- More complex result handling (JSONL, polling)

Use cases: batch document analysis, generating training
data, evaluating model outputs at scale, nightly
enrichment jobs, offline QA pipelines.

*What separates good from great:* "Batch API + prompt
caching together can reduce background processing
costs by 80-90% - the combination is the highest
ROI optimization for high-volume pipelines."

---

**[JUNIOR] Q6 - What happens if you don't include
conversation history in a multi-turn interaction?**

*Why they ask:* Stateless API understanding.

The Claude API is stateless. Each `messages.create`
call is a fresh request. Claude has no memory
between calls.

If you don't include previous turns:

```python
# BAD: forgetting to include history
client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    messages=[
        # Missing: {"role": "user", "content": "My name is Alex."},
        # Missing: {"role": "assistant", "content": "Nice to meet you, Alex!"},
        {"role": "user", "content": "What's my name?"}
    ]
)
# Claude: "I don't know your name - you haven't told me."
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Claude does not know your name because the conversation
where you said "My name is Alex" was never included.

Memory management implications:
- Each added turn increases token usage
- Long conversations eventually exceed context limits
- Solutions: sliding window (keep last N turns),
  summarization (compress old turns into a summary),
  retrieval (embed old turns, retrieve relevant ones)

*What separates good from great:* "Sliding window
is the simplest; summarization preserves more semantic
content; retrieval is needed for very long histories (>100 turns)."

---

**[JUNIOR] Q7 - [DEBUGGING] How do you diagnose
unexpectedly high token usage in the Claude API?**

*Why they ask:* Operational troubleshooting.

Always log `msg.usage.input_tokens` and
`msg.usage.output_tokens` per request.

Diagnostic steps:

(1) Log both per-request. High input_tokens usually
    means the conversation history or system prompt
    is large.

(2) Check system prompt size:
```python
import anthropic
# Tokenize to get actual count
client = anthropic.Anthropic()
result = client.beta.messages.count_tokens(
    model="claude-3-5-sonnet-20241022",
    system=my_system_prompt,
    messages=[]
)
print(f"System prompt: {result.input_tokens} tokens")
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

(3) Check conversation history growth. After N turns,
    history could be 10,000+ tokens.
    Print `len(history)` and total token count.

(4) Check for accidental document inclusion.
    If a large document is being added to every
    message instead of the system prompt, costs spike.

(5) Enable structured logging:
```python
import json, sys
msg = client.messages.create(...)
print(json.dumps({
    "in_tokens": msg.usage.input_tokens,
    "out_tokens": msg.usage.output_tokens,
    "model": msg.model,
}), file=sys.stderr)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* "Token count logging
from day one prevents month-end billing surprises."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ overview keyword.)*

---

### 🏛️ System Design

*(Omit: L0 orientation keyword.)*

---

### 📊 Diagram

*(Omit: clearer as structured text for this overview.)*

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


# GitHub Copilot Overview

**Interview Weight:** ★☆☆ - GitHub Copilot is the
most widely deployed AI development tool. Any engineer
in 2025 should be able to describe what it is,
its core modes, and how it differs from direct
LLM API calls.

---

### 🎯 Model Answer

**30 seconds:**

> GitHub Copilot is an AI coding assistant embedded
> in VS Code (and other IDEs) that provides three
> modes: inline code completion (code appears as
> you type), Copilot Chat (a conversation panel
> for asking questions about your code), and Agent
> Mode (Copilot autonomously runs multi-step coding
> tasks). It's powered by OpenAI and Anthropic models
> and differs from direct API calls in that developers
> don't call any API - Copilot handles all context
> assembly and model calls automatically.

**3 minutes:**

> GitHub Copilot operates at three levels of AI
> assistance.
>
> Level 1 - Inline Completion: as you type, Copilot
> suggests code completions (grey "ghost text").
> Context is automatic: the current file, surrounding
> functions, and open related files are passed to
> the model. Tab accepts; Escape rejects.
>
> Level 2 - Copilot Chat: a panel in VS Code where
> you ask questions in natural language. You can
> ask about selected code (`/explain`), request
> refactoring, ask architecture questions, or generate
> code from a description. Slash commands:
> `/explain`, `/fix`, `/tests`, `/doc` provide
> structured workflows.
>
> Level 3 - Agent Mode: Copilot autonomously performs
> multi-step coding tasks. You give a goal ("add
> input validation to the User model"); Copilot
> reads relevant files, writes code, runs tests,
> reads the output, fixes failures, and continues
> until done. This is the agentic AI coding workflow.
>
> Underlying model: GitHub Copilot uses OpenAI
> GPT-4o and Claude 3.5 Sonnet/Sonnet-4. You can
> select the model in the chat panel. Different
> models have different strengths: Claude tends
> to excel at following complex instructions;
> GPT-4o tends to be faster.

**Blank Mind Recovery:**

**(1) Restate:** "GitHub Copilot. Three modes: inline
completion, chat, agent mode."

**(2) First principles:** "It's an LLM API call where
VS Code automatically assembles the context from
your files. You're still calling an LLM - just
without writing the API call."

**(3) Bridge:** "Like Google Autocomplete is to
the Google Search API. Copilot is the product;
the LLM API is the infrastructure underneath."

---

### 📘 Concept Explanation

**What it is:**

GitHub Copilot is an AI-powered coding assistant
embedded in IDEs, using LLMs to provide code completion,
answering coding questions, and autonomously executing
multi-step coding tasks.

**The problem it solves:**

Reduces developer time spent on: boilerplate code,
context switching to documentation, test writing,
debugging repetitive errors, and implementing standard patterns.

**How it works:**

```
COPILOT ARCHITECTURE:

Developer types in VS Code
       |
       v
Copilot extension (context assembler)
  - Current file content
  - Cursor position
  - Open tab files (related context)
  - Workspace index (for @workspace queries)
       |
       v
LLM API call (OpenAI / Anthropic)
  - Model: GPT-4o or Claude 3.5 Sonnet
  - Assembled context as prompt
       |
       v
Response
  - Inline completion: ghost text at cursor
  - Chat: response in panel
  - Agent: tool calls (file read/write, terminal)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Three modes in detail:**

Inline completion: triggered automatically as you
type. Accepts with Tab. Shows up to 3 alternatives
(Alt+[ / Alt+]). Context: current file + open files.

Chat (`Cmd+I` or panel): conversational. Can reference:
`@workspace` (full project), `@terminal` (terminal
output), `#file:path` (specific file), selected
code. Slash commands for structured tasks.

Agent mode: autonomous multi-step. Copilot gets
to call tools: read files, write files, run terminal
commands, run tests. The agent loop continues until
the task is done or blocked.

**Key slash commands:**

- `/explain`: explain selected code
- `/fix`: diagnose and fix selected code problem
- `/tests`: generate unit tests for selected function
- `/doc`: generate documentation comment
- `/new`: create a new file/component from description

---

### 💻 Code Example

```python
"""
NOT code: Copilot doesn't have a Python API.
This file shows HOW Copilot works via docstrings
(a primary way to guide inline completion).
"""

# HOW TO GUIDE COPILOT WITH DOCSTRINGS:

def parse_user_from_json(json_str: str) -> dict:
    """
    Parse a user object from a JSON string.

    Expected JSON format:
    {
        "id": 123,
        "name": "Alice Smith",
        "email": "alice@example.com",
        "created_at": "2024-01-15T10:30:00Z"
    }

    Returns a dict with keys: id, name, email, created_at.
    Raises ValueError if required fields are missing.
    Raises json.JSONDecodeError if JSON is invalid.
    """
    # Copilot will complete this with correct logic
    # because the docstring fully describes the contract.
    import json
    data = json.loads(json_str)
    required = {"id", "name", "email", "created_at"}
    missing = required - data.keys()
    if missing:
        raise ValueError(
            f"Missing required fields: {missing}"
        )
    return {
        "id": int(data["id"]),
        "name": str(data["name"]),
        "email": str(data["email"]),
        "created_at": data["created_at"]
    }


# HOW TO USE CHAT FOR CODE REVIEW:
# Select the function above in VS Code.
# Open Copilot Chat.
# Type: /explain
# -> Copilot explains what the code does.

# Type: /tests
# -> Copilot generates pytest test cases.

# Type: What edge cases does this function miss?
# -> Copilot: "Doesn't validate email format,
#    doesn't handle non-string name values,
#    doesn't validate ISO 8601 timestamp format."


# AGENT MODE EXAMPLE (prose description):
# In VS Code chat, switch to Agent mode.
# Type: "Add input validation to this function:
#        - email must match basic email regex
#        - name must be 1-100 characters
#        - id must be a positive integer
#        - return pydantic model instead of dict"
#
# Copilot agent will:
# 1. Read this file
# 2. Write the updated function with pydantic
# 3. Check for pydantic in requirements.txt
# 4. If missing: add it and run pip install
# 5. Run tests to verify
# 6. Fix any failures
```

> **Code walkthrough:** Copilot doesn't have a Python
> API - this illustrates HOW to work with it effectively.
> The docstring is the primary mechanism for guiding
> inline completion: a complete docstring with input
> format, output format, and exception contracts gives
> Copilot all the information needed to generate
> correct implementation code. The comments show
> the slash command workflow: `/explain` for understanding,
> `/tests` for test generation, freeform questions
> for code review. The Agent Mode prose section describes
> a realistic agentic task: you provide a goal in
> natural language, the agent autonomously reads
> code, writes changes, installs dependencies, runs
> tests, and iterates until done.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "GitHub Copilot has three modes. Inline completion:
> code suggestions appear as I type, Tab to accept.
> Chat: I ask questions about my code or ask it
> to write code from a description. Agent mode:
> I give a high-level goal and Copilot does the
> whole task - reads files, writes code, runs tests,
> fixes failures. Under the hood it's calling OpenAI
> or Claude APIs with my code as context."

---

**Senior / Staff:**

> "Copilot's value is in context assembly: gathering
> relevant code from across the project and structuring
> it into an effective prompt automatically. The
> three modes exist on a spectrum from assistant
> (inline) to autonomous agent. Agent mode is where
> the most productivity gain is: for tasks like
> 'add pagination to all REST endpoints' that would
> take a developer 2 hours, a well-prompted Copilot
> agent can complete it in 5 minutes. The limitation
> is context: Copilot works best on well-structured
> codebases with clear conventions. Messy code with
> inconsistent patterns produces worse suggestions.
> The practical implication: investing in code quality
> and consistency pays dividends in AI tool productivity."

---

### ⚠️ Common Misconceptions

**Misconception: "Copilot suggestions are always
correct and can be accepted without review."**

Copilot generates statistically likely code given
the context. It makes mistakes: incorrect logic,
subtle security issues (SQL injection, path traversal),
deprecated APIs, wrong error handling. Every suggestion
must be reviewed. Copilot accelerates the writing
of code; the developer is still responsible for
its correctness. The key skill is fast review:
understanding generated code quickly enough to
accept/reject/modify efficiently.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Copilot generates plausible-looking but
incorrect security handling**

*Symptom:* Copilot generates input validation code
that looks correct but misses a security case.
Example: generates a path that uses `str.startswith()`
for path traversal prevention (bypass: `../etc/../passwd`).

*Root cause:* Copilot predicts likely code, not
provably correct code. Common security patterns
appear in training data, but edge cases don't.

*Fix:*
1. Always review security-sensitive code from Copilot
   more carefully than business logic
2. Add security-specific review comments in chat:
   "Does this code have any path traversal vulnerabilities?"
3. Use static analysis (bandit for Python, semgrep)
   on generated code as a backstop
4. Know common patterns where Copilot errs:
   auth checks, input validation, SQL construction,
   file path handling, cryptography

*Rule:* Copilot for speed; security review for correctness.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Three modes | 2-3 min |
| Context assembly | 3-4 min |
| Agent mode | 3-4 min |
| Effective prompting | 3-4 min |
| Security review | 3-4 min |
| vs. direct API | 3-4 min |
| Model selection | 3-4 min |

---

**[JUNIOR] Q1 - What are the three Copilot modes
and when do you use each?**

*Why they ask:* Baseline knowledge.

Inline completion: use for code you're actively writing.
Fastest path from intent to code. Best when: writing
functions, classes, test cases. The context is your
current file - write clear docstrings to guide it.

Chat panel: use for: understanding unfamiliar code,
generating code from a spec, debugging, refactoring.
Can query the whole workspace with `@workspace`.
Best for: complex generation that needs iteration.

Agent mode: use for well-defined multi-file tasks.
Best for: adding a feature across multiple files,
writing a full test suite, refactoring a pattern
across the codebase. Less suitable for: tasks with
vague requirements (agent may interpret ambiguously).

Practical workflow: start with inline for unit-level
tasks. Switch to chat when the task needs clarification
or spans multiple considerations. Use agent for
defined, bounded tasks that would take 30+ minutes manually.

*What separates good from great:* "Agent mode works
best with defined acceptance criteria - 'add X until
all tests pass' is better than 'improve the code.'"

---

**[MID] Q2 - How does Copilot assemble context for
a code completion request?**

*Why they ask:* Understanding what makes better suggestions.

For inline completion, Copilot assembles:
(1) Current file: the code before and after the cursor.
(2) Open tabs: files currently open in VS Code.
    Related files (same module, same class) are
    prioritized. Copilot infers "related" from imports.
(3) Workspace index: for `@workspace` queries and
    some completions, Copilot builds a semantic index
    of the whole project.
(4) Language server context: type information from
    the language server (TypeScript types, Python
    type annotations).

Context budget: there's a token limit. Copilot truncates
context to fit. Implications:
- Very large files: only a portion is sent
- Open the most relevant files: if you want Copilot
  to follow patterns from another file, open it
- Write clear signatures: type annotations and
  docstrings become context

What makes better completions:
- Type annotations: `def process_user(user: User) -> Result[str]`
- Docstrings: specify input/output/exceptions
- Related file open: if you're implementing a service
  that uses a model, have the model file open
- Clear naming: consistent naming from the rest of
  the codebase helps Copilot follow conventions

*What separates good from great:* "Open the model
definition and related service files before asking
Copilot to generate new service code - those files
become context that guides the generation."

---

**[JUNIOR] Q3 - What is the difference between
Copilot Chat and Copilot Agent mode?**

*Why they ask:* Mode distinction.

Chat: conversational, request-response. You ask;
Copilot responds with text or code. You decide
what to do with the response. Copilot doesn't
take actions in your codebase without your involvement.

Agent: autonomous, multi-step. Copilot executes
a plan. It can: read files (via `#file:` or `@workspace`),
write files directly to your filesystem, run terminal
commands, run tests, and read the output. It continues
autonomously until the task is done or it gets stuck.

Key difference: agency. In Chat, Copilot is an
advisor. In Agent mode, Copilot is an executor.

Agent mode tools:
- File read: reads any file in the workspace
- File write: writes/modifies files directly
- Terminal: runs shell commands (tests, builds, installs)
- Web search (some configurations): looks up documentation

Safety: Agent mode shows what it's going to do before
doing it in most operations. You can cancel at any step.
For terminal commands, it shows the command and asks for approval.

*What separates good from great:* "Agent mode's terminal
access means it can install dependencies, run tests,
and fix the failures it causes - it's a complete
coding loop, not just code generation."

---

**[MID] Q4 - How do you use Copilot effectively
for test generation?**

*Why they ask:* Practical productivity.

Best practice for test generation with Copilot:

(1) Write the function completely first.
    Copilot generates better tests when the implementation
    is visible. It can see the edge cases from the code.

(2) Open the test file (or create it), then write
    the import and class structure. Copilot will
    complete test methods.

(3) Use the slash command:
    Select the function in VS Code Chat.
    Type `/tests`. Copilot generates pytest test cases.

(4) Use a natural language follow-up:
    "Add edge case tests for: empty string input,
    None input, and inputs > 1000 characters."

(5) Check for common test gaps in generated tests:
    - Exception cases (is `pytest.raises()` used?)
    - Boundary values (off-by-one)
    - Empty/None inputs
    - Integration vs. unit (is it mocking correctly?)

Common problem: Copilot generates tests that test
the implementation not the contract. If the implementation
has a bug, the generated test may pass despite the bug.
Always verify tests by intentionally breaking the
implementation and confirming the test fails.

*What separates good from great:* "Mutation testing
verification: break the function deliberately and
confirm the test catches it. Copilot-generated tests
sometimes mirror the implementation logic instead of testing the contract."

---

**[MID] Q5 - When is direct LLM API usage better
than GitHub Copilot?**

*Why they ask:* Tool selection.

Copilot is the right tool when:
- A developer is actively writing code and wants
  real-time assistance
- The task is within VS Code
- You want conversational code help
- Agent mode tasks are bounded to a codebase

Direct API is better when:
- Automated pipelines (CI/CD, nightly scripts):
  Copilot is an IDE tool, not an API
- High-volume processing: tokenize documents, classify
  tickets, generate summaries at scale. Copilot
  isn't built for this.
- Custom prompting: you need full control over the
  system prompt, temperature, or response format.
  Copilot doesn't expose these.
- Multi-model routing: use Claude for one step,
  GPT for another. Copilot uses a fixed model set.
- Building AI features into your application:
  Copilot is a developer tool; the Claude/OpenAI
  API is the infrastructure for AI-powered products.

The divide: Copilot = developer productivity tool.
LLM API = AI application infrastructure.

*What separates good from great:* "The split is
interactive vs. automated - Copilot for developers
interacting, direct API for code running without a human in the loop."

---

**[JUNIOR] Q6 - How do you reference specific
files in Copilot Chat?**

*Why they ask:* Practical workflow.

Copilot Chat file references:

`#file:path/to/file.py` - reference a specific file.
The file's content is included in the context.
Example: "Refactor #file:src/auth.py to use bcrypt instead of MD5"

`@workspace` - reference the whole workspace.
Copilot builds a semantic index of all files.
Example: "@workspace How does authentication work in this project?"

`#selection` - reference currently selected code.
Equivalent to: select code in editor, then ask
a question. The selection is included as context.

`@terminal` - reference terminal output.
Useful for: "Why did this test fail? @terminal"
(Copilot sees the test output.)

`#sym:ClassName` or `#sym:functionName` - reference
a specific symbol. Copilot finds the definition.

Practical usage: when asking Copilot to modify a
specific file or understand a specific class,
always reference it explicitly. Without an explicit
reference, Copilot uses heuristics to choose context
and may choose the wrong file.

*What separates good from great:* "Explicit references
produce better results than relying on @workspace
heuristics - always reference the specific file when you know it."

---

**[JUNIOR] Q7 - [TRADE-OFF] What are the privacy
implications of using GitHub Copilot?**

*Why they ask:* Enterprise awareness.

How Copilot handles code:

In VS Code: your code is sent to GitHub/Microsoft/OpenAI
APIs as context for completions. By default, GitHub
may use this telemetry data to improve Copilot models.

Individual plans: code telemetry opt-in/out in settings.
If telemetry is on: GitHub can use completion suggestions
to train models. If off: code is used only for
the current completion, not for training.

Enterprise plans: GitHub Copilot Business and Enterprise
include: no training data opt-in by default, data
stays within the organization's agreement, audit logs,
IP indemnification.

Key privacy risks:
- Proprietary code sent to external APIs
- Trade secrets in code visible to API providers
- Personally identifiable information in code context
- Model prompts containing credentials (if hardcoded)

Mitigation:
- Use Copilot Business/Enterprise for proprietary code
- Review settings: disable "Allow GitHub to use my
  code snippets to improve GitHub Copilot"
- Don't hardcode secrets in files open during Copilot sessions
- For air-gapped environments: use GitHub Copilot
  Enterprise with on-premises model (with Azure AI)

*What separates good from great:* "Enterprise plans
with data residency and no-training commitments
are required for regulated industries - know the
difference before recommending Copilot for a bank."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ overview keyword.)*

---

### 🏛️ System Design

*(Omit: L0 orientation keyword.)*

---

### 📊 Diagram

*(Omit: architecture is clearer as structured text.)*

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



