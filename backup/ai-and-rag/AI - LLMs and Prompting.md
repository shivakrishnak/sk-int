---
layout: default
title: "AI - LLMs and Prompting"
parent: "AI Foundations, LLMs, RAG and Agents"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/ai-and-rag/llms-and-prompting/
topic: AI Foundations, LLMs, RAG and Agents
subtopic: LLMs and Prompting
keywords:
  - LLM Architecture
  - Prompt Engineering
  - Few-Shot Learning
  - Chain-of-Thought
  - Temperature and Sampling
  - Context Windows
difficulty_range: medium-hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [LLM Architecture](#llm-architecture)
- [Prompt Engineering](#prompt-engineering)
- [Few-Shot Learning](#few-shot-learning)
- [Chain-of-Thought](#chain-of-thought)
- [Temperature and Sampling](#temperature-and-sampling)
- [Context Windows](#context-windows)

# LLM Architecture

**TL;DR** - Large Language Models are decoder-only Transformers with billions of parameters trained on internet-scale text to predict the next token - emergent capabilities (reasoning, coding, translation) arise from scale, and understanding the architecture informs how to use them effectively.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Without understanding LLM architecture, developers treat models as magic black boxes - unable to predict failures, optimize costs, work within context limits, or understand why prompting techniques work.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
LLM architecture (decoder-only Transformer):
  Input tokens -> Embedding -> N Transformer blocks -> Output
  Each block: Self-Attention + Feed-Forward + LayerNorm

  Generation process (autoregressive):
    Input: "The capital of France is"
    Step 1: Model predicts next token: "Paris"
    Step 2: Append "Paris", predict next: "."
    Step 3: Append ".", predict next: [end]
    (One token at a time, each conditioned on all previous)

Scale milestones:
  | Model       | Parameters | Training data  | Context |
  |-------------|-----------|----------------|---------|
  | GPT-2       | 1.5B      | 40GB text      | 1K      |
  | GPT-3       | 175B      | 570GB          | 4K      |
  | GPT-4       | ~1.8T (MoE)| ~13T tokens  | 128K    |
  | Claude 3.5  | Unknown   | Unknown        | 200K    |
  | Llama 3 70B | 70B       | 15T tokens     | 128K    |

Key concepts:
  Parameters: Learned weights (billions)
    More params = more patterns captured = more capable
  Context window: Max tokens processed at once
    128K tokens ~= 96K words ~= 300 pages
  Attention: O(n^2) with sequence length
    Longer context = more compute = slower + expensive
  MoE (Mixture of Experts): Not all params active
    GPT-4: 1.8T params but only ~280B active per token
    Enables large capacity with lower inference cost

Emergent capabilities (appear at scale):
  - Reasoning (chain-of-thought)
  - Code generation
  - Translation (100+ languages)
  - Instruction following
  - In-context learning (few-shot)
  These don't exist in small models - emerge with scale
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. LLMs are autoregressive next-token predictors (decoder Transformers). Each output token is conditioned on all previous tokens. Generation is sequential (one token at a time).
2. Capabilities emerge from scale: more parameters + more training data = reasoning, code generation, instruction following. Not explicitly programmed - emergent from next-token prediction.
3. Context window = how much the model can "see" at once. Everything must fit: system prompt + conversation history + user input + output. Managing context is critical.

**Interview one-liner:**
"LLMs are scaled decoder-only Transformers trained on next-token prediction where capabilities emerge from scale - I work with their architectural constraints: autoregressive generation (sequential), finite context windows (careful prompt budgeting), and attention costs (O(n^2) with context length driving latency and cost)."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for LLM Architecture. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Prompt Engineering

**TL;DR** - Prompt engineering is the practice of designing inputs to LLMs to reliably get desired outputs - including system prompts, instruction formatting, constraints, examples, and output structuring - it's the primary interface for programming LLM behavior.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Same question, wildly different answers. "Write code" produces inconsistent quality. No way to reliably constrain outputs. Model ignores requirements, hallucinates, or produces wrong format. Vague prompts = vague results.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Prompt anatomy:
  System prompt: Role, constraints, behavior rules
  Context:       Background info, documents, examples
  User message:  The actual request
  Output format: Expected structure, schema

Key techniques:
  1. Role assignment:
     "You are a senior Python developer reviewing code
      for security vulnerabilities."

  2. Explicit constraints:
     "Respond in JSON. Max 3 sentences. No markdown.
      If unsure, say 'I don't know' rather than guess."

  3. Structured output:
     "Return: {confidence: 0-1, answer: string, sources: []}"

  4. Step-by-step instructions:
     "1. Analyze the code for bugs
      2. Rate severity (low/medium/high)
      3. Suggest a fix with code example"

  5. Negative examples (what NOT to do):
     "Do NOT include explanations.
      Do NOT use placeholder values.
      Do NOT hallucinate information not in the context."

Prompt engineering principles:
  - Be specific (not "summarize" but "summarize in 3 bullets
    focusing on technical decisions")
  - Show, don't tell (examples > instructions)
  - Constrain the output format (JSON schema, templates)
  - Test adversarially (what makes it fail?)
  - Iterate systematically (change one thing at a time)
  - Version your prompts (they're code, treat them as such)

Common failure patterns:
  Problem: Model ignores instructions
  Fix: Move critical instructions to end of prompt,
       repeat key constraints, use delimiters (---/###)

  Problem: Hallucination
  Fix: Provide source material, add "only use provided
       context", ask for confidence scores

  Problem: Inconsistent format
  Fix: Provide exact output template, use JSON mode,
       add format validation in application code
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Be specific and structured: role + context + task + constraints + output format. Vague prompts = vague results. Treat prompts as code (version, test, iterate).
2. Show don't tell: few-shot examples are more reliable than instructions alone. Provide examples of desired output format.
3. Defense in depth: prompts can be ignored, so validate outputs in code. Use JSON mode/structured outputs, add application-level validation, handle edge cases programmatically.

**Interview one-liner:**
"Prompt engineering is programming LLM behavior through structured inputs - I use system prompts for role/constraints, few-shot examples for format consistency, chain-of-thought for reasoning, and always validate outputs programmatically since prompts are probabilistic guidance, not deterministic contracts."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Prompt Engineering. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Few-Shot Learning

**TL;DR** - Few-shot learning provides examples in the prompt to teach the model the desired pattern without fine-tuning - showing 2-5 input/output pairs dramatically improves consistency, format adherence, and task accuracy compared to zero-shot instructions alone.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Telling the model "classify sentiment as positive/negative/neutral" gives inconsistent results. Some responses include explanations, some use different labels, some hedge. Instructions alone don't reliably convey the expected behavior pattern.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Zero-shot (instruction only):
  "Classify the sentiment of this review as
   positive, negative, or neutral."
  Result: Inconsistent format, explanations included

Few-shot (examples provided):
  "Classify sentiment. Examples:
   Input: 'Great product, love it!' -> positive
   Input: 'Terrible, broke after a day' -> negative
   Input: 'It works fine, nothing special' -> neutral

   Input: 'Best purchase I've made this year!' -> "
  Result: "positive" (consistent, no explanation)

Few-shot best practices:
  1. Diverse examples: Cover edge cases and boundaries
     (not just easy examples - include ambiguous ones)
  2. Balanced: Equal representation of each class/format
  3. Representative: Match the difficulty of real inputs
  4. Ordered: Place hardest/most relevant examples last
     (recency bias - model attends more to recent examples)
  5. Consistent format: Exact same structure in each example
  6. Minimal: 3-5 examples usually sufficient
     (more examples = more tokens = higher cost)

When few-shot works best:
  - Classification tasks (sentiment, intent, category)
  - Format specification (JSON, specific template)
  - Style matching (tone, verbosity, technical level)
  - Domain-specific terminology or conventions

When to go beyond few-shot:
  - Need >95% accuracy -> fine-tuning
  - Complex multi-step reasoning -> chain-of-thought
  - Domain knowledge needed -> RAG
  - 100+ examples would help -> fine-tuning dataset
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Few-shot = provide 3-5 examples in the prompt. Dramatically improves format consistency and accuracy without fine-tuning. Works by pattern matching, not explicit instruction.
2. Example quality matters more than quantity: diverse, balanced, representative, covering edge cases. 3 great examples beat 10 mediocre ones.
3. Few-shot vs fine-tuning: few-shot for quick iteration (no training needed), fine-tuning for sustained high accuracy at scale (lower per-request cost, consistent behavior).

**Interview one-liner:**
"Few-shot learning teaches via examples in-context - I use 3-5 diverse, balanced examples covering edge cases to establish consistent output patterns, placing the most relevant examples last (recency bias), and escalate to fine-tuning only when few-shot consistency isn't sufficient for production accuracy requirements."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Few-Shot Learning. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Chain-of-Thought

**TL;DR** - Chain-of-thought (CoT) prompting asks models to show their reasoning step-by-step before giving a final answer - dramatically improving accuracy on complex tasks (math, logic, multi-step problems) by preventing the model from jumping to conclusions.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Ask "What's 17 \* 23 + 45 / 9?" and the model guesses. Complex reasoning tasks fail because the model tries to produce the answer in one step. Multi-step problems require intermediate reasoning, but models default to single-hop answers.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Without CoT (direct answer):
  Q: "If a store has 15 apples and sells 2/3 of them,
      then receives a shipment of 20, how many total?"
  A: "25" (WRONG - model guessed)

With CoT (step-by-step):
  Q: "...Think step by step."
  A: "1. Start with 15 apples
      2. Sell 2/3: 15 * 2/3 = 10 sold, 5 remain
      3. Receive shipment: 5 + 20 = 25
      Answer: 25" (CORRECT - verified reasoning)

CoT variants:
  Zero-shot CoT:
    Add "Let's think step by step" to any prompt
    Simple, general, moderate improvement

  Few-shot CoT:
    Provide examples WITH reasoning shown
    More reliable, task-specific patterns

  Self-consistency:
    Generate multiple CoT paths, take majority vote
    Higher accuracy, higher cost (3-5x tokens)

  Tree-of-thought:
    Explore multiple reasoning branches
    Evaluate and prune bad paths
    Best for: planning, puzzles, complex decisions

When to use CoT:
  YES: Math, logic, multi-step reasoning, analysis,
       code debugging, complex decisions
  NO:  Simple classification, extraction, translation,
       formatting tasks (adds unnecessary tokens)

Implementation pattern:
  System: "For complex questions, think step by step.
           Show your reasoning, then give final answer."

  Or structured:
  System: "Analyze in this format:
           REASONING: [your step-by-step analysis]
           ANSWER: [final concise answer]"

  (Parse ANSWER from response programmatically)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. "Think step by step" improves accuracy on reasoning tasks by 20-40%+. Forces model to show intermediate steps instead of jumping to conclusions.
2. Use CoT for complex reasoning (math, logic, analysis, debugging). Don't use for simple tasks (classification, extraction) - wastes tokens for no benefit.
3. Self-consistency (multiple CoT paths + majority vote) further improves accuracy but costs 3-5x more tokens. Use for high-stakes decisions where accuracy matters more than cost.

**Interview one-liner:**
"Chain-of-thought prompting forces explicit step-by-step reasoning before answers - I use it for complex tasks (debugging, analysis, multi-step logic), structured CoT with parseable sections (REASONING/ANSWER) for automation, and self-consistency for high-stakes decisions where I trade cost for accuracy."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Chain-of-Thought. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Temperature and Sampling

**TL;DR** - Temperature controls randomness in model outputs (0 = deterministic/focused, 1 = creative/varied), while other sampling parameters (top_p, top_k, frequency_penalty) fine-tune the output distribution - choosing correctly balances creativity vs consistency for your use case.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Same prompt returns different results every time (or always the same boring response). Code generation produces "creative" hallucinations. Creative writing is repetitive. No control over the determinism/creativity trade-off.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
How generation works:
  Model outputs probability for EVERY token in vocabulary
  "The capital of France is" ->
    Paris: 0.85, Lyon: 0.05, a: 0.03, the: 0.02, ...

Temperature adjusts this distribution:
  Temp = 0:   Always pick highest probability (greedy)
               "Paris" every time. Deterministic.
  Temp = 0.3: Slightly random, mostly top choices
               "Paris" 95% of the time. Focused.
  Temp = 0.7: Moderate randomness, diverse but coherent
               "Paris" 80%, occasionally surprising
  Temp = 1.0: Full distribution randomness
               More creative, less predictable
  Temp > 1.0: Amplified randomness (often incoherent)
               Rarely useful. Avoid.

Sampling parameters:
  Temperature: Scale the logits (randomness control)
  Top-p (nucleus): Only consider tokens summing to p%
    top_p=0.9: Consider tokens until 90% probability mass
    Dynamically sizes the candidate pool
  Top-k: Only consider top K tokens
    top_k=50: Only top 50 most likely tokens
  Frequency penalty: Penalize repeated tokens
    Prevents repetitive output loops
  Presence penalty: Penalize tokens that already appeared
    Encourages topic diversity

Recommended settings by use case:
  | Use Case           | Temperature | Top-p |
  |-------------------|-------------|-------|
  | Code generation   | 0-0.2       | 0.95  |
  | Factual Q&A       | 0           | 1.0   |
  | Data extraction   | 0           | 1.0   |
  | Creative writing  | 0.7-0.9     | 0.95  |
  | Brainstorming     | 0.8-1.0     | 0.95  |
  | Summarization     | 0.3-0.5     | 0.95  |
  | Conversation      | 0.5-0.7     | 0.9   |

Key insight: temp=0 is NOT truly deterministic
  (implementation details can cause slight variation)
  For true determinism: set seed parameter if available
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Temperature 0 for factual/code tasks (deterministic, consistent). Temperature 0.7-0.9 for creative tasks (varied, interesting). Never exceed 1.0.
2. Top-p (nucleus sampling) complements temperature by dynamically sizing the candidate pool. top_p=0.95 with temperature is the common combination.
3. For production systems: use low temperature (0-0.3) for reliability. Add frequency/presence penalties only if seeing repetition issues. Validate outputs regardless of settings.

**Interview one-liner:**
"Temperature controls output randomness (0 for factual/code, 0.7+ for creative) while top-p dynamically bounds the token candidate set - in production I use low temperature for deterministic outputs with programmatic validation, since sampling parameters reduce but don't eliminate inconsistency."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Temperature and Sampling. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Context Windows

**TL;DR** - The context window is the maximum number of tokens an LLM can process in a single request (input + output combined) - managing it effectively is critical for cost, latency, accuracy, and application design, requiring strategies like summarization, RAG, and sliding windows.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Conversations get too long and the model "forgets" earlier messages. Documents exceed the limit. Costs grow linearly with context length. Important instructions at the beginning get lost ("lost in the middle" problem).
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Context window sizes (2024-2025):
  | Model            | Context Window | ~Pages |
  |-----------------|----------------|--------|
  | GPT-4o          | 128K tokens    | ~300   |
  | Claude 3.5      | 200K tokens    | ~500   |
  | Gemini 1.5 Pro  | 2M tokens      | ~5000  |
  | Llama 3         | 128K tokens    | ~300   |
  | GPT-4o-mini     | 128K tokens    | ~300   |

Context budget (must fit in window):
  System prompt:      ~500-2000 tokens
  Conversation history: Variable (grows!)
  Retrieved context (RAG): ~2000-8000 tokens
  User message:        ~100-500 tokens
  Output (generation): ~500-4000 tokens
  TOTAL must be < context window

"Lost in the middle" problem:
  Models attend best to: beginning and end of context
  Information in the middle is less reliably used
  Implications:
  - Put critical instructions in system prompt (start)
  - Put most relevant context near the end
  - Don't assume middle content is processed equally

Context management strategies:
  1. Sliding window: Keep last N messages, drop oldest
  2. Summarization: Periodically summarize older messages
  3. RAG: Retrieve only relevant context per query
  4. Hierarchical: Summary of all + detail of relevant
  5. Truncation: Hard limit with priority ordering

Cost implications:
  Tokens used = tokens billed
  128K context at $15/M tokens = $1.92 per FULL request
  vs 4K context = $0.06 per request (32x cheaper!)
  Strategy: Only include what's relevant (RAG > dump all)

Latency implications:
  More context tokens = longer time-to-first-token
  Attention is O(n^2): doubling context = 4x compute
  Practical: 128K context = noticeably slower than 4K
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Context window = total tokens (input + output). Budget carefully: system prompt + history + retrieved context + user message + max output must fit.
2. "Lost in the middle": models attend best to start and end. Put instructions first, relevant context last. Don't rely on middle content being processed equally.
3. More context = more cost + more latency (quadratic attention). Use RAG to include only relevant context rather than dumping everything. 4K relevant tokens beats 128K irrelevant ones.

**Interview one-liner:**
"Context windows require careful budgeting (system prompt + history + RAG context + output < limit) - I use RAG for selective retrieval rather than stuffing full documents, place critical instructions at boundaries (start/end, not middle), and implement sliding-window summarization for long conversations to manage cost and latency."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Context Windows. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]
