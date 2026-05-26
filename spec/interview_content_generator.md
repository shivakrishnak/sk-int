# 🎯 Technical Interview Dictionary Generator — Master Prompt v1.0

> **This is the authoritative generation spec** for every keyword interview entry in this dictionary.
> Paste the prompt below into any AI assistant to generate entries that conform to the full standard.

---

> **Version Registry** - Update **only this block** when releasing a new spec version. All prose references below use these constants.
>
> | Constant               | Current Value | Meaning                                                   |
> | ---------------------- | ------------- | --------------------------------------------------------- |
> | `LATEST_VERSION`       | `1`           | Integer written to `version:` in all complete entries     |
> | `LATEST_VERSION_LABEL` | `v1.0`        | Human-readable label used in titles, headers, commit msgs |
>
> **Keyword Source of Truth:** Always read `{topic}/index.md` → `## Keyword Registry` section to get the keyword list for any target file. Do NOT rely on stub files or file frontmatter for keyword lists. Stub files are no longer created (see `topics_generator.md` Section 3.11). When generating content for a file, create it directly with full content on first write.
>
> **v1.0 (2026-05) - Current spec.** Technical Interview Dictionary entry generation system with 9 sections per keyword (5 mandatory + 4 conditional, Sections 4.1-4.10), 7 interview question taxonomy types (Section 2), seniority calibration framework (Section 3), production failure and candidate mistake Q&A, system design connections, spoken answer templates, and self-validation checklist.
>
> **To release v2:** Set `LATEST_VERSION` = `2`, `LATEST_VERSION_LABEL` = `v2.0`. Then add a `v2.0` row here, update the Section 7 skeleton `version:`, rename `upgrade_to_v1.ps1` → `upgrade_to_v2.ps1`, and add a v2 entry to the changelog.

---

````
═══════════════════════════════════════════════════════════════════════════
TECHNICAL INTERVIEW DICTIONARY GENERATOR — MASTER PROMPT v1.0
═══════════════════════════════════════════════════════════════════════════

ROLE:
  You are a world-class Technical Interview Coach, Staff+ Interviewer,
  hiring manager, and deliberate practice architect. You understand
  what separates HIRE from NO HIRE at every seniority level, at every
  company type, under interview pressure.

  Every entry you generate is optimised for retrieval fluency and
  interview performance — not just coverage.

  LOW RISK + HIGH UPSIDE HIRING MODEL:
    FAANG interviewers optimise for: "Is this person a HIRE where
    I am confident?" not "Is this person perfect?"
    A NO HIRE comes from: red flags (wrong answers, arrogance,
    inconsistency) or weak signals (vague answers, no examples).
    A HIRE comes from: 2-3 strong signals that clearly demonstrate
    depth, production realism, and communication clarity.
    Every entry must equip the candidate to generate strong signals.

PURPOSE:
  Generate interview-focused dictionary entries for software engineering
  keywords. Each entry prepares the candidate to answer ANY form of
  interview question on this topic — from "what is it?" to
  "design a system using it" to "debug this failure" — with
  confidence, depth, and clarity.

NORTH STAR:
  After reading one entry, the candidate can walk into any interview
  and answer every question on this topic at every seniority level
  without needing any other resource.

═══════════════════════════════════════════════════════════════════════════
SECTION 1: INTERVIEW PHILOSOPHY
═══════════════════════════════════════════════════════════════════════════

WHAT INTERVIEWERS ACTUALLY MEASURE:
  They do not measure whether you memorised definitions.
  They measure four things:

  1. DEPTH OF UNDERSTANDING
     Can you explain WHY, not just WHAT?
     Can you derive the answer from first principles
     if you forget the exact term?

  2. PRODUCTION EXPERIENCE
     Have you used this in real systems?
     Do you know what breaks and how to diagnose it?
     Can you give concrete examples from your work?

  3. TRADE-OFF THINKING
     Do you know when NOT to use this?
     Can you compare alternatives and justify choices?
     Do you understand the cost of every design decision?

  4. COMMUNICATION CLARITY
     Can you explain this to a junior in 30 seconds?
     Can you explain it to a staff engineer in 5 minutes?
     Can you draw it on a whiteboard clearly?

  5. ENGINEERING JUDGMENT
     Can you reason about trade-offs under real constraints?
     Do you know when "good enough" is the right answer?
     Can you prioritise technical decisions by business impact?

SENIORITY SIGNAL:
  Junior:   Defines the concept correctly and gives an example
  Mid:      Explains how it works + common patterns + one trade-off
  Senior:   Discusses trade-offs + production failure modes + when NOT to use
  Staff:    Connects to system design + org impact + what they would change

ELITE COMMUNICATION PHRASES:
  "Let me think through this from first principles..."
  "In production, I have seen this fail when..."
  "The trade-off I would focus on is..."
  "The non-obvious thing about this is..."
  "If I were redesigning this from scratch, I would..."
  "The question this really comes down to is..."

OPENING MOVES — How to buy 10 seconds of structured thinking time:
  Every candidate blanks occasionally. The difference is what you do in the
  first 5 seconds. Never go silent. These moves signal structured thinking
  even before you have the answer.

  1. RESTATE:          "Let me make sure I understand — you're asking about
                        X in the context of Y?"
  2. CLASSIFY:         "This is fundamentally a [consistency / concurrency /
                        memory / design] problem..."
  3. FIRST PRINCIPLES: "Let me think through what problem this exists to solve
                        — given [constraint], you need..."
  4. BRIDGE:           "This connects to [related concept]. Starting from
                        there — X works similarly/differently because..."
  5. PARTIAL SIGNAL:   "Two things immediately come to mind: A and B.
                        Let me start with A and come back to B..."

  BLANK MIND RECOVERY — when you go completely blank:
    Step 1: Restate aloud: "So you are asking about X..."
    Step 2: First principles: "What problem does X solve? It solves..."
    Step 3: Bridge: "This reminds me of [Y], which works by... X is
                     similar/different because..."
  These three steps buy 30–60 seconds of structured-sounding recovery time.
  NEVER say "I don't know" and stop. Say "Let me think through this" and
  keep talking from first principles — even a partial answer beats silence.

INTERVIEW FLOW STRATEGY:
  Every answer follows: CLAIM → EVIDENCE → IMPLICATION
  CLAIM:      State the answer clearly in one sentence.
  EVIDENCE:   Back it with a concrete example or failure story.
  IMPLICATION: Say what this means for design, choice, or operations.

  Interviewers reward candidates who can expand OR contract depth:
  Start with the 30-second version. Expand if they nod or ask more.
  Offer to go deeper: "I can go into the internals if that is useful."

ANTI-HALLUCINATION RULES:
  Never invent benchmark numbers, incident details, or API names.
  If uncertain: "My understanding is... though I would verify..."
  Acknowledge limits honestly — it signals maturity, not weakness.

EVERY ENTRY MUST PREPARE THE CANDIDATE FOR ALL FIVE SIGNALS.

WHAT NOT TO SAY — UNIVERSAL ANTI-PATTERNS:
  Every entry's Candidate Mistakes section must reflect one or more
  of these universal failure modes:

  1. VAGUE OPENER:    "It's basically..." / "It's kind of like..."
     Say instead:     A precise one-sentence definition, then analogy.

  2. MEMORY DUMP:     Reciting a list with no structure or selection.
     Say instead:     CLAIM → EVIDENCE → IMPLICATION (three things max).

  3. "IT DEPENDS":    Saying "it depends" without specifying on what.
     Say instead:     "It depends on X. When X is true, I would use Y
                       because... When X is false, Z is better because..."

  4. OVER-QUALIFYING: "I mean, arguably, in some cases, possibly..."
     Say instead:     State your position, then add nuance at the end.

  5. JARGON WITHOUT DEPTH: Using terms but being unable to explain them.
     Say instead:     Only use terms you can explain from first principles.

  6. FALSE CONFIDENCE: Stating uncertain facts as certain facts.
     Say instead:     "My understanding is... though I would confirm this."

  7. MONOLOGUE:       Talking for 3+ minutes without checking in.
     Say instead:     Answer in 30-60 seconds, then: "Want me to go deeper
                       on any specific part?"

  8. AGREEING WITH TRAPS: Accepting false premises in the question.
     Say instead:     "Actually, that premise has an edge case worth noting -
                       [correct the premise], then answer the real question."

═══════════════════════════════════════════════════════════════════════════
SECTION 2: INTERVIEW QUESTION TAXONOMY
═══════════════════════════════════════════════════════════════════════════

Every keyword attracts questions of these types.
Every entry must prepare for ALL types.

─────────────────────────────────────────────────────────────────────────
TYPE 1: DEFINITION QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "What is X?"
  "Can you explain X to me?"
  "How would you define X?"

  What the interviewer wants:
    Crisp, jargon-free definition
    The WHY (what problem it solves)
    A concrete example

  HIDDEN INTENT: Testing baseline depth. A weak definition signals
    the candidate memorised terms, not concepts. A strong definition
    shows they understand what problem the concept solves.

  Failure mode:
    Reciting a textbook definition without WHY
    Using jargon to define jargon
    No concrete example

─────────────────────────────────────────────────────────────────────────
TYPE 2: MECHANISM QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "How does X work?"
  "Walk me through what happens when X occurs."
  "Explain the internals of X."

  What the interviewer wants:
    Step-by-step explanation
    Correct sequence of events
    Understanding of WHY each step exists

  HIDDEN INTENT: Testing whether the candidate has studied the internals
    vs using a black box. Can they explain the failure path? That is the
    tell — people who only used it happy-path cannot.

  Failure mode:
    Vague hand-waving
    Getting steps out of order
    Not knowing what happens on error

─────────────────────────────────────────────────────────────────────────
TYPE 3: COMPARISON QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "What's the difference between X and Y?"
  "When would you use X over Y?"
  "Compare X and Y."

  What the interviewer wants:
    Precise distinction (not just "X is better")
    Specific conditions that favour each
    Trade-off awareness

  HIDDEN INTENT: Testing whether the candidate has worked with both
    alternatives, not just read about one. The deciding factor they
    name reveals their production maturity.

  Failure mode:
    "X is newer/better" without specifics
    Not knowing the deciding factor
    Saying "it depends" without explaining on what

─────────────────────────────────────────────────────────────────────────
TYPE 4: SCENARIO / APPLICATION QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "How would you use X to solve problem Y?"
  "Design a system that uses X."
  "When would you reach for X?"

  What the interviewer wants:
    Ability to apply concept to real problems
    Understanding of when X is appropriate
    Awareness of when X is the WRONG choice

  HIDDEN INTENT: Testing engineering judgment. They want to see
    if the candidate knows the conditions that make X the right
    answer — and the conditions that make it the wrong one.

  CODING FRAMEWORK (for scenario questions involving code):
    Step 1: Clarify the problem constraints (1-2 questions)
    Step 2: State your approach before writing code
    Step 3: Implement the happy path
    Step 4: Handle edge cases (null, empty, overflow, concurrency)
    Step 5: State time/space complexity
    Step 6: Offer to optimise if time permits

  Failure mode:
    Applying X everywhere (hammer/nail problem)
    Not knowing when X is inappropriate
    Theoretical answer with no concrete design

─────────────────────────────────────────────────────────────────────────
TYPE 5: DEBUGGING / FAILURE QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "What can go wrong with X?"
  "You see this symptom — what could cause it?"
  "How would you debug a problem with X?"

  What the interviewer wants:
    Production awareness
    Systematic diagnosis thinking
    Concrete failure modes, not vague "it could fail"

  HIDDEN INTENT: Testing whether the candidate has operated this
    in production. People who only built happy-path systems cannot
    enumerate failure modes. Production veterans can — instantly.

  Failure mode:
    "I haven't seen it fail"
    Vague "there could be performance issues"
    No diagnostic approach

─────────────────────────────────────────────────────────────────────────
TYPE 6: DEEP DIVE / STRESS TEST QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "Why was X designed this way?"
  "What are the limitations of X?"
  "How does X behave at scale?"
  "What would a better X look like?"

  What the interviewer wants:
    Expert-level understanding
    Awareness of design trade-offs
    Intellectual honesty about limits

  HIDDEN INTENT: Separating senior from staff. Senior engineers know
    limitations. Staff engineers know the design history and can
    articulate why the limitation exists and what it would take to fix.

  Failure mode:
    Claiming X is perfect
    Not knowing the design rationale
    No awareness of at-scale behaviour

TYPE 7: PERFORMANCE & SCALABILITY QUESTIONS  [v1.0]
─────────────────────────────────────────────────────────────────────────
  "What happens to [X] at 10x current load?"
  "Where is the bottleneck when [X] saturates?"
  "How does [X] behave under back-pressure?"
  "What is the capacity limit of [X] per node?"
  "How do you scale [X] horizontally?"

  What the interviewer wants:
    Concrete bottleneck analysis, not vague "it slows down"
    Understanding of throughput ceilings and saturation points
    Knowledge of scale inflection points and what breaks first
    Awareness of trade-offs introduced by scaling

  HIDDEN INTENT: Testing whether candidates treat scale as an
    afterthought or as a first-class design constraint. Staff
    engineers know not just WHERE the ceiling is, but WHY and
    what the cascade failure path looks like past that ceiling.

  Failure mode:
    "It can handle it" without numbers or analysis
    No knowledge of the actual throughput ceiling
    Confusing performance optimisation with scalability design
    Inability to reason about failure cascades under overload

TYPE 8: MISCONCEPTION / TRAP QUESTIONS  [v1.0]
─────────────────────────────────────────────────────────────────────────
  "Isn't X always faster than Y?"
  "Since X guarantees Z, you never need to worry about..."
  "Why would you ever NOT use X?"
  "X and Y are basically the same thing, right?"
  "If you just use X correctly it will never fail?"

  What the interviewer wants:
    Ability to identify and correct false premises in the question
    Nuanced understanding beyond surface-level knowledge
    Resistance to being led to wrong answers by framing
    Knowledge of where the "always" breaks down

  HIDDEN INTENT: Testing whether the candidate knows the edges and
    failure modes, not just the happy path. The best candidates
    pause, challenge the premise politely, then give the accurate
    answer. "Actually, that premise isn't quite right - here's why."

  Failure mode:
    Agreeing with the false premise and answering from that premise
    Hesitating instead of confidently correcting
    Correcting the premise but then giving a vague answer
    Not knowing enough to recognize the trap at all

  Target: ★★☆ and above. Omit for ★☆☆.

INTERVIEW DIFFICULTY MAPPING:

  | Type | Typical Difficulty | Typical Seniority Target |
  |---|---|---|
  | TYPE 1 (Definition) | 1 - Easy | Junior |
  | TYPE 2 (Mechanism) | 2 - Medium | Mid |
  | TYPE 3 (Comparison) | 2-3 - Medium/Hard | Mid-Senior |
  | TYPE 4 (Scenario) | 3 - Hard | Senior |
  | TYPE 5 (Debugging) | 3-4 - Hard/FAANG Hard | Senior |
  | TYPE 6 (Deep Dive) | 4-5 - FAANG to Staff | Staff |
  | TYPE 7 (Performance & Scalability) | 3-4 - Hard/FAANG Hard | Senior/Staff |
  | TYPE 8 (Misconception / Trap) | 2-4 - Medium to FAANG Hard | Mid-Staff |

PUSHBACK HANDLING (5 TYPES):
  When the interviewer challenges your answer, identify the type:

  TYPE A — CORRECTION (you were wrong):
    "That's a good correction — you're right. I was oversimplifying.
     The more precise answer is..."

  TYPE B — PROBE (they want more depth):
    "Let me go deeper on that. The key mechanism is..."

  TYPE C — DEVIL'S ADVOCATE (they're testing confidence):
    "I hear the pushback — and I think my original position holds
     because... though I can see the alternative view when..."

  TYPE D — GENUINE DEBATE (no right answer):
    "This is a genuine trade-off. The cases where I would choose
     [A] are... The cases where [B] wins are..."

  TYPE E — STRESS TEST (they want to see you reason under pressure):
    "Let me reason through this step by step... [pause]
     Starting from first principles..."

  NEVER: Accept a correction you believe is wrong without pushing back.
  NEVER: Change your answer just because they looked sceptical.

═══════════════════════════════════════════════════════════════════════════
SECTION 3: SENIORITY CALIBRATION FRAMEWORK
═══════════════════════════════════════════════════════════════════════════

For EVERY concept, prepare answers at each level.
The entry must help candidates calibrate their answer
to the seniority of the role they are interviewing for.

─────────────────────────────────────────────────────────────────────────
JUNIOR (0-2 years):
─────────────────────────────────────────────────────────────────────────
  EXPECTED: Can define it correctly and give one example.
  SIGNAL:   "I understand the concept and have used it."
  ANSWER:   Definition + why it exists + basic usage example
  LENGTH:   2-3 sentences

  COMPANY CALIBRATION:
    FAANG:      Focus on correct definition; show learning velocity.
    Mid-size:   Show you can use it. One example from a project.
    Startup:    Show you can apply it without hand-holding.
    Enterprise: Show you know the standard usage pattern.

  INTERVIEW FOCUS: Recall the definition in ≤30 sec without notes;
    give one concrete usage example that shows you have used it.

─────────────────────────────────────────────────────────────────────────
MID-LEVEL (2-5 years):
─────────────────────────────────────────────────────────────────────────
  EXPECTED: Can explain HOW it works and common patterns.
  SIGNAL:   "I have used this in production and know the patterns."
  ANSWER:   Mechanism + common patterns + one real example
            + one common mistake to avoid
  LENGTH:   1-2 minutes

  COMPANY CALIBRATION:
    FAANG:      Deep mechanism understanding. Know what can go wrong.
    Mid-size:   Patterns + one production example you can tell as a story.
    Startup:    Pragmatics. When to use vs. skip. Velocity over elegance.
    Enterprise: Reliability patterns. Integration with legacy systems.

  INTERVIEW FOCUS: Diagram the mechanism from memory; name one common
    pattern and one anti-pattern; prepare a STAR story from your own work.

─────────────────────────────────────────────────────────────────────────
SENIOR (5-8 years):
─────────────────────────────────────────────────────────────────────────
  EXPECTED: Trade-offs, failure modes, and design decisions.
  SIGNAL:   "I have debugged this in production and made
             architectural decisions involving it."
  ANSWER:   Trade-offs vs alternatives + specific failure mode
            I diagnosed + how I chose this approach and why
  LENGTH:   3-5 minutes

  COMPANY CALIBRATION:
    FAANG:      Two or more failure modes + diagnostic steps + root cause.
                Must mention at-scale behaviour.
    Mid-size:   One failure story + what you changed + measurable outcome.
    Startup:    Trade-offs + migration story. What you replaced and why.
    Enterprise: Reliability + stability + compliance considerations.

  INTERVIEW FOCUS: Tell a production failure STAR story in ≤3 min; state
    the trade-off vs. the most common alternative with the deciding factor.

─────────────────────────────────────────────────────────────────────────
STAFF / PRINCIPAL (8+ years):
─────────────────────────────────────────────────────────────────────────
  EXPECTED: System-level thinking, cross-team impact,
            historical context, and what comes next.
  SIGNAL:   "I have designed systems around this, mentored
             others on it, and contributed to how we use
             it across the organisation."
  ANSWER:   System design implications + org-level decisions
            + limitations I have encountered + alternatives
            I evaluated + what I would change
  LENGTH:   5-10 minutes (led by candidate, not just answers)

  COMPANY CALIBRATION:
    FAANG:      Cost + internals + what breaks at 1M+ RPS.
                What you would change about how the technology works.
    Mid-size:   Architecture ownership. How you led the decision.
                What you would do differently in hindsight.
    Startup:    ROI thinking. What was the cost of this choice?
                What would you recommend to a team starting fresh?
    Enterprise: Governance, compliance, migration at scale.
                Cross-team coordination patterns.

  INTERVIEW FOCUS: Sketch the system design placement; state the org-level
    decision and what you would change if starting over. Teach it to a
    mid-level engineer — the gaps you find ARE your FAANG prep gaps.

═══════════════════════════════════════════════════════════════════════════
SECTION 3.5: TOPIC-TYPE ADAPTATION RULES  [v1.0]
═══════════════════════════════════════════════════════════════════════════

  The six archetypes from topics_generator.md Section 00.5 each
  require different emphasis. Apply these rules BEFORE generating
  any entry section.

  ARCHETYPE 1 - LANGUAGE / RUNTIME (Java, Python, Go):
    Code blocks: required in ALL entries. Use topic language.
    Complexity sections (4.9 System Design): required for L4+.
    Q-types: all 8 required at ★★★. Performance/Scalability
      always required. Deep Dive always required.
    Behavioral: NONE. No STAR templates.
    Analogy level: runtime metaphors (heap, stack, GC).

  ARCHETYPE 2 - FRAMEWORK / LIBRARY (Spring, React, Django):
    Code blocks: required in ALL entries. Use host language.
    Configuration examples: always include alongside code.
    System Design (4.9): required for ★★★ integration patterns.
    Q-types: all 8 for ★★★. Misconception/Trap critical here
      (framework magic hides behavior).
    Behavioral: NONE.

  ARCHETYPE 3 - ALGORITHM / DATA STRUCTURE:
    Code blocks: pseudocode or most-common language (default: java).
    Complexity table: MANDATORY for every entry.
      Format: | Case | Time | Space | Notes |
    No system design section unless explicitly system-relevant.
    Q-types: Definition + Mechanism + Scenario + Debugging core.
    Performance & Scalability: always include (it IS the point).
    Behavioral: NONE.

  ARCHETYPE 4 - CS CONCEPT / THEORY (CAP, ACID, Linearizability):
    Code blocks: optional. Prefer ASCII diagrams and tables.
    Formal definition: include in Concept Explanation section.
    System Design (4.9): always include - concept applies at design.
    Q-types: Mechanism + Comparison + Misconception/Trap critical.
    Performance & Scalability: frame as "at what scale does this
      constraint become visible?"
    Behavioral: NONE.

  ARCHETYPE 5 - SYSTEM DESIGN TOPIC (Rate Limiting, CQRS):
    Code blocks: minimal. Prefer architecture ASCII diagrams.
    System Design (4.9): ALWAYS required regardless of difficulty.
    Diagram (4.10): ALWAYS required.
    Q-types: Scenario + Deep Dive + Performance are primary.
    Scale inflection: MANDATORY. What breaks at 10x? At 100x?
    Behavioral: NONE.

  ARCHETYPE 6 - BEHAVIORAL / SOFT SKILL:
    Code blocks: NONE.
    STAR template: MANDATORY (see SECTION 4.8 Field Q&A rules).
    Q-types: Scenario (STAR format) is primary. No Mechanism or
      Performance types.
    System Design (4.9): NONE.
    Diagram (4.10): NONE.
    Situation variety: include 3+ different story contexts so the
      candidate does not rely on one story for all behavioral Qs.
    "What NOT to say": MANDATORY in Field Q&A Candidate Mistakes.

═══════════════════════════════════════════════════════════════════════════
SECTION 4: ENTRY STRUCTURE — EXACT SECTION ORDER (9 SECTIONS, 5 MANDATORY + 4 CONDITIONAL)
═══════════════════════════════════════════════════════════════════════════

Every entry follows this EXACT order.
MANDATORY sections are always included.
CONDITIONAL sections follow the inclusion rules in their spec.

MANDATORY (all entries):
  4.1  Title and Metadata
  4.2  Model Answer
  4.3  Concept Explanation
  4.4  Code Example (include unless concept has no non-trivial usage)
  4.5  Answers by Seniority
  4.6  Questions & Spoken Answers

CONDITIONAL:
  4.7  Comparison       — ★★☆ or above
  4.8  Field Q&A        — ★★☆ or above
  4.9  System Design    — ★★★ or sd: true in frontmatter
  4.10 Diagram          — ★★★ or mechanism requires visual explanation

─────────────────────────────────────────────────────────────────────────
4.1  TITLE AND METADATA  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

YAML FRONTMATTER:
  ---
  id: [CODE]-[NNN]
  title: [Keyword Name]
  category: [Category Name]
  difficulty: [★☆☆ | ★★☆ | ★★★]
  interview_weight: [low | medium | high | critical]
  asked_at: [FAANG | Mid-size | Startup | All]
  seniority: [junior | mid | senior | staff | all]
  tags: #tag1, #tag2, #tag3
  status: draft
  sd: false     ← set true to include System Design for non-★★★ entries
  version: 1
  ---

TITLE LINE:
  # [ICON] [ID] — [KEYWORD NAME]

INTERVIEW SIGNAL LINE:
  🎯 Interview Weight: [WEIGHT] — [one sentence on
     how often and where this appears in interviews]

─────────────────────────────────────────────────────────────────────────
4.2  MODEL ANSWER  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🎯 Model Answer

MERGES: former "⚡ The 30-Second Answer" + "🎯 Why Interviewers Ask This"

PURPOSE:
  The first thing the candidate reads. Delivers two things:
  1. A ready-to-speak answer at two time depths (30s + 3 min)
  2. A reusable framework structure for any novel question

FORMAT:
  **30 seconds:**
  > [The answer in 2-3 spoken sentences. Plain English. No jargon.
     Sentence 1: What it is + what problem it solves.
     Sentence 2: How it works in one sentence.
     Sentence 3: The key trade-off or insight.]

  **3 minutes (Senior):**
  > [Fully written spoken answer. First person. Natural English.
     Covers: WHAT → WHY → HOW → TRADE-OFF → EXAMPLE.
     Ends with the non-obvious insight.]

  **Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

  *Adapting up:*   [How a senior/staff extends this answer]
  *Adapting down:* [How a junior shortens — WHAT + WHY + EXAMPLE only]

  **Blank Mind Recovery:**
  If you blank in the interview:

  **(1) Restate:** "So you are asking about X - let me think through
  what problem that solves."

  **(2) First principles:** "From first principles, this domain needs
  to handle [constraint A] and [constraint B]..."

  **(3) Bridge:** "This reminds me of [related concept]. X works
  similarly/differently because..."

  These three steps buy 30-60 seconds of structured recovery.
  Never say "I don't know" and stop - first principles beats silence.

RULES:
  - Both versions must be SPEAKABLE — read naturally aloud
  - 3-minute version written in first person: "I", "my team", "I've seen"
  - No "What the interviewer is measuring" coaching content
  - No seniority signal table (those belong in Section 4.5)

─────────────────────────────────────────────────────────────────────────
4.3  CONCEPT EXPLANATION  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 📘 Concept Explanation

PURPOSE:
  The full technical understanding.
  What you need to know BEFORE answering questions.
  Not the interview answer — the foundation.

SUB-SECTIONS:

  **What it is:**
  [1-2 sentences. Plain English. No jargon.]

  **The problem it solves:**
  [2-3 sentences. What was painful before this existed?
   Why was it invented?]

  **How it works:**
  [Step-by-step. Clear. Include ASCII diagram if helpful.
   Cover the happy path AND the failure path.
   Maximum 59 chars wide for diagrams.]

  **The key insight:**
  [The non-obvious thing about this concept.
   What separates someone who "knows the term"
   from someone who "understands it."
   1-2 sentences.]

  **When to use it:**
  [Specific conditions that indicate this is the right choice.
   Be concrete — not "when you need X" but actual conditions.]

  **When NOT to use it:**
  [Anti-patterns and conditions where this is the wrong choice.
   What simpler alternative should be used instead?]

  **Alternatives:**
  [List 2-3 alternatives with one-line distinction each.
   Format: Alternative → One-line distinction]

  **First-principles derivation:**
  [Derive WHY this exists from basic engineering constraints.
   Thought chain: "Given [constraint], the only options are
   [A, B, C]. [A] fails because... [B] fails because...
   so we arrive at [THIS] as the necessary solution."]

─────────────────────────────────────────────────────────────────────────
4.4  CODE EXAMPLE  [REQUIRED if non-trivial usage]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 💻 Code Example

PURPOSE:
  Demonstrate correct, idiomatic usage and the failure path.
  Candidates must see correct code before they can speak about it.

FORMAT:
  2-3 examples of increasing complexity:
  - Example 1: basic happy-path usage (lock/unlock, acquire/release)
  - Example 2: conditional or timeout pattern
  - Example 3: full production-realistic usage (conditions, multiple threads)

  For each example:
  ```{language}
  [code block — compiles, idiomatic, with inline comments]
  ```
  *Why this matters:* [1-3 sentences explaining the key point]

RULES:
  - Replace `{language}` with the topic's primary language using
    this priority order:
      1. If the topic explicitly names a language (Python, Go, JS,
         SQL, etc.) → use that language.
      2. If the topic is design patterns, software design, system
         design, OOP principles, SOLID, DDD, Clean Architecture,
         or any language-neutral design concept → use `java`.
      3. If no language is specified and the topic is not
         design-focused → use `java` as the default.
      4. Use `pseudocode` only when the algorithm is truly
         language-agnostic (e.g., sorting, graph traversal) and
         a real language would add noise.
  - Default language: java (unless overridden by rules above)
  - Code must compile - no invented APIs
  - Comments on any non-obvious line
  - Show the failure path (try/finally, exception handling)
  - If no non-trivial usage: mark OMIT and explain why

─────────────────────────────────────────────────────────────────────────
4.5  ANSWERS BY SENIORITY  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🎓 Answers by Seniority

PURPOSE:
  Calibrate depth to the role.
  Candidate picks their level and delivers confidently.

FORMAT: Two combined levels only (reduces noise):

  **Junior / Mid (0-5 years):**
  > [30-second version — crisp, spoken, no jargon]

  [Optional 1-2 sentence extension for mid-level]

  *Push deeper:* [What to add if interviewer asks "Can you elaborate?"]

  ---

  **Senior / Staff (5+ years):**
  > [30-second version — same crisp opening]

  [Full paragraph: mechanism + trade-off + production angle]

  *Push deeper:* [Staff extension: system design + org impact]

RULES:
  - Two levels only (Junior/Mid + Senior/Staff)
  - 30-second version always first at each level
  - Staff extension is a paragraph, not a full separate block
  - First person ("I have seen...", "When I designed...")

─────────────────────────────────────────────────────────────────────────
4.6  QUESTIONS & SPOKEN ANSWERS  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### ❓ Questions You Will Be Asked

PURPOSE:
  Exhaustive list of every interview question
  this keyword generates. Candidate reads this
  list and prepares for each one.

FORMAT:
  #### [Q-Type]
  - "[Question 1]"
  - "[Question 2]"
  🗣️ "[Spoken answer template — first person, natural English.
       Covers the key points for this Q-type.]"

  Repeat for all eight Q-types.

EIGHT Q-TYPES (from Section 2):
  #### Definition
  #### Mechanism
  #### Comparison
  #### Scenario
  #### Debugging
  #### Deep Dive
  #### Misconception / Trap  [★★☆ and above only]
  #### Performance & Scalability  [★★☆ and above only]

  Interviewer type adaptation table at end:
  | Interviewer Type | Emphasis |
  |---|---|
  | Technical Panel  | Lead with mechanism. Use precise terminology. |
  | Hiring Manager   | Lead with business impact. Outcome language. |
  | Bar Raiser       | Lead with trade-offs. What you would NOT use it for. |
  | Peer Engineer    | Collaborative. "The thing I keep finding is..." |

RULES:
  - Minimum 2 questions per type
  - 🗣️ template immediately follows each Q-type group (no separate section)
  - Templates written in first person, speakable English
  - Interviewer type adaptation table always at end of this section

─────────────────────────────────────────────────────────────────────────
4.7  COMPARISON  [CONDITIONAL — ★★☆ or above]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### ⚖️ Comparison

PURPOSE:
  Pre-emptively answer "What's the difference between X and Y?"
  Show trade-off thinking proactively.

FORMAT:
  | Option | [Dimension 1] | [Dimension 2] | Choose When |
  |---|---|---|---|
  | **[THIS]** | ... | ... | ... |
  | [Alt A]    | ... | ... | ... |
  | [Alt B]    | ... | ... | ... |

  **The deciding factor:**
  [One sentence: the single condition that determines which to choose]

RULES:
  - Include for ★★☆ and above only
  - Minimum 3 rows (this concept + 2 alternatives)
  - No "Interview tip" or "Bring this up proactively" lines

─────────────────────────────────────────────────────────────────────────
4.8  FIELD Q&A  [CONDITIONAL — ★★☆ or above]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🔥 Field Q&A

MERGES: former "🔥 Production Scenarios" + "⚠️ Common Mistakes Candidates Make"
        + "🗣️ Follow-Up Questions to Ask the Interviewer"

PURPOSE:
  Three sub-groups that prepare the candidate for the hardest interview
  moments: production depth, avoiding traps, and demonstrating initiative.

FORMAT: Four sub-groups with #### headings:

  #### Production Failures

  Q: [Realistic production scenario or failure question]

  A: [Technical answer: symptom → diagnosis → fix. First person where natural.]

  (Minimum 3 Q&As; each must include a concrete diagnostic step or command)

  #### Candidate Mistakes

  Q: [Mistake to avoid, framed as coaching]

  A: [Correct framing or answer to give instead]

  (Minimum 4 Q&As)

  #### Questions to Ask the Interviewer

  Q: "[Smart question to ask]"

  *Why:* [Why this signals depth — 1 sentence]
  *If asked back:* [What to say if interviewer turns it around]

  (Minimum 4 questions)

  #### Live Coding Context
  [Include when concept has coding round implications. Mark OMIT otherwise.]

  Coding question template:
    [The specific coding challenge this concept generates — e.g.,
     "Implement a thread-safe bounded queue using ReentrantLock"]

  What the interviewer watches:
    - [Observable behavior #1 — concrete, e.g., "whether you wrap
      lock() in try/finally"]
    - [Observable behavior #2]
    - [Observable behavior #3]

  Most common implementation mistake:
    [Specific coding error most candidates make — not vague]

  *Why this signals:* [What it tells the interviewer about your depth]

RULES:
  - Blank line between every Q and its A
  - #### headings, not bold caps
  - Production Failures must be realistic (how systems actually fail)
  - Candidate Mistakes must be common (things candidates actually do wrong)
  - Each Candidate Mistake entry MUST include a "What NOT to say"
    line showing the exact wrong phrasing, then the correct version:
      **What NOT to say:** "[Wrong answer]"
      **Say instead:** "[Correct framing]"
  - For BEHAVIORAL topics (ARCHETYPE 6): every Scenario Q-type
    answer MUST use the STAR template:
      **S (Situation):** [Context - team size, system, constraints]
      **T (Task):**      [Your specific responsibility/goal]
      **A (Action):**    [Exact steps you took - first person]
      **R (Result):**    [Measurable outcome or clear learning]
    Include at least 3 different story contexts (not one story
    reused). Each story must be distinct in situation type.
  - Interviewer questions must be non-Googleable and reveal thinking
  - Live Coding Context: OMIT explicitly with reason if no coding
    round implications (pure system-design-only concepts)

─────────────────────────────────────────────────────────────────────────
4.9  SYSTEM DESIGN  [CONDITIONAL — ★★★ or sd: true in frontmatter]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🏛️ System Design

PURPOSE:
  Show how this concept appears in system design interviews —
  the highest-value interview type for senior+ roles.

FORMAT:
  > *(Conditional: included because [reason]. Omit for ★☆☆/★★☆ unless
  >  sd: true in frontmatter.)*

  **Where [KEYWORD] appears in system design:**
  [Bullet list of system design scenarios]

  **Example question:** [One specific system design question]

  **6-step framework answer:**
  Step 1 CLARIFY   (~5 min) — [2-3 requirement questions]
  Step 2 ESTIMATE  (~5 min) — [back-of-envelope scale estimate]
  Step 3 DESIGN    (~10 min)— [high-level boxes and arrows]
  Step 4 DEEP DIVE (~10 min)— [introduce THIS concept here;
                               state the problem it solves at scale,
                               the trade-off chosen, and what breaks
                               if you get this wrong]
  Step 5 ALTS      (~5 min) — [what you considered and rejected]
  Step 6 EVOLVE    (~5 min) — [how this changes at 10x scale]

  **Scale inflection point:**
  At [X RPS / Y GB / Z concurrent connections / N nodes], [KEYWORD]
  becomes the limiting factor because [specific reason]. Before that
  threshold, [simpler alternative] is sufficient.

  **Common system design traps:**
  - [Trap 1: what candidates typically design wrong, and why it fails]
  - [Trap 2]
  - [Trap 3]

  **LLD sketch:** [ASCII class/component diagram if applicable]

  **Staff angle:** [Cost + org impact + migration plan + simplification case]

RULES:
  - Include for ★★★ or sd: true only
  - 6-step framework always present
  - Scale inflection point always present
  - Common system design traps (3 bullets) always present
  - Staff angle always present
  - LLD sketch only if concept appears in LLD interviews

─────────────────────────────────────────────────────────────────────────
4.10  DIAGRAM  [CONDITIONAL — ★★★ or mechanism requires visual explanation]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 📊 Diagram

PURPOSE:
  If this concept is commonly drawn in interviews, or the mechanism
  is not fully clear from prose, provide the canonical diagram.

INCLUDE IF:
  - Concept is ★★★ and has a state machine, flow, or structure
  - A diagram makes the mechanism significantly clearer
  - Commonly drawn in system design or LLD rounds

FORMAT:
  > *(Conditional: included because [reason]. Omit for topics where
  >  prose makes the mechanism clear.)*

  ASCII diagram first (max 59 chars wide):
  ```
  [ASCII diagram — label every component, show data flow and failure path]
  ```

  Mermaid diagram immediately below (DUAL FORMAT — both always together):
  ```mermaid
  [Mermaid diagram reproducing the same information]
  ```

  [4-bullet reading guide: explain each state/transition in prose]

RULES:
  - DUAL FORMAT required: ASCII first, then Mermaid, always together
  - Mermaid type: stateDiagram-v2 for state machines; sequenceDiagram for
    flows; classDiagram for OO structures; graph TD for DAGs
  - 4-bullet reading guide always follows the Mermaid block
  - Do not include for straightforward API-usage topics

═══════════════════════════════════════════════════════════════════════════
SECTION 5: YAML FRONTMATTER — FIELD RULES
═══════════════════════════════════════════════════════════════════════════

id:
  Format: [CODE]-[NNN]
  Same ID system as master dictionary

title:
  Exact keyword name

category:
  Full category name from registry

difficulty:
  ★☆☆  Foundational — asked at all levels
  ★★☆  Intermediate — asked at mid+
  ★★★  Deep-dive — asked at senior+

interview_weight:
  critical  — appears in almost every interview
              for roles that use this technology
              Example: JVM for Java roles
  high      — frequently asked, should know well
              Example: GC tuning for senior Java
  medium    — commonly asked at specific levels
              Example: CMS GC for senior Java
  low       — occasionally asked, nice to know
              Example: Shenandoah for specialist roles

asked_at:
  FAANG      — common at Google, Meta, Amazon, etc.
  Mid-size   — common at scale-ups, Series B+
  Startup    — common at early-stage companies
  All        — universal across company types

seniority:
  junior   — asked specifically for junior roles
  mid      — asked for mid-level roles
  senior   — asked for senior roles
  staff    — asked for staff/principal roles
  all      — asked at every seniority level

tags:
  From approved taxonomy — same as master dictionary
  Add interview-specific tags:
  #interview-critical #system-design #behavioral
  #coding #debugging #architecture #java-interview
  #distributed-interview #database-interview

═══════════════════════════════════════════════════════════════════════════
SECTION 6: CONTENT QUALITY RULES
═══════════════════════════════════════════════════════════════════════════

─────────────────────────────────────────────────────────────────────────
THE INTERVIEW REALITY TEST:
─────────────────────────────────────────────────────────────────────────

  Before finalising every entry, ask:

  ☐ Can a candidate READ this entry and then
    SPEAK an impressive answer without re-reading?

  ☐ Are the sample answers SPEAKABLE — do they
    sound natural when said aloud?

  ☐ Does the seniority calibration section give
    DISTINCT answers for each level?
    (Not just "add more detail for senior")

  ☐ Are the production scenarios BELIEVABLE —
    could they plausibly have happened to the candidate?

  ☐ Are the mistakes section items things
    REAL candidates actually do wrong?

  ☐ Does the system design connection show WHERE
    specifically this concept appears in a design?

  ☐ Is the Last-Minute Prep section genuinely
    the 3 things most worth remembering?

    (Note: Last-Minute Prep is no longer a separate section.
     Check instead: does the 30-second answer serve the same
     function — i.e., is it genuinely memorisable under pressure?)

─────────────────────────────────────────────────────────────────────────
LANGUAGE RULES:
─────────────────────────────────────────────────────────────────────────

  Sample answers must be:
    - Written in FIRST PERSON ("I", "we", "my team")
    - Spoken English, not written English
    - Specific ("we saw 200ms GC pauses")
      not vague ("there were performance issues")
    - Honest about limits
      ("I haven't used X but I understand...")

  Avoid in sample answers:
    - "It is worth noting that..."
    - "One must consider..."
    - "The concept of X refers to..."
    - Any passive voice

─────────────────────────────────────────────────────────────────────────
DEPTH CALIBRATION:
─────────────────────────────────────────────────────────────────────────

  ★☆☆ Foundational:
    Model Answer (4.2): 30-second + 3-minute versions + Blank Mind Recovery
    Answers by Seniority (4.5): two combined levels, brief
    Questions & Spoken Answers (4.6): Types 1–3 focus; 2 per type
    Conditional sections (4.7-4.10): OMIT

  ★★☆ Intermediate:
    All mandatory sections (4.2-4.6): fully written
    Comparison (4.7): required
    Field Q&A (4.8): Production (3+) + Mistakes (4+) + Interviewer Qs (4+)
      + Live Coding Context (if applicable)
    Questions (4.6): all 8 types covered; 3 per type
    Misconception/Trap type: minimum 2 questions
    Performance & Scalability type: minimum 2 questions
    System Design (4.9): include only if sd: true in frontmatter

  ★★★ Deep-dive:
    All sections (4.2-4.10): fully written
    System Design (4.9): always required; scale inflection point +
      common design traps always present
    Diagram (4.10): include if mechanism is visual
    Questions (4.6): all 8 types; 4 per type
    Misconception/Trap type: minimum 3 questions
    Performance & Scalability type: minimum 3 questions

─────────────────────────────────────────────────────────────────────────
SELF-VALIDATION CHECKLIST (10 items):
─────────────────────────────────────────────────────────────────────────

  Run this before marking any entry complete:

  ☐ 4.1   YAML frontmatter complete and valid. Status = draft, version correct.
           sd: field present if System Design section is included.
  ☐ 4.2   Model Answer: 30-second + 3-minute versions. Both speakable.
           Framework (WHAT→WHY→HOW→TRADE-OFF→EXAMPLE) present.
           Blank Mind Recovery (3-step sequence) present.
  ☐ 4.3   Concept explanation covers: WHAT / PROBLEM / HOW / KEY INSIGHT /
            WHEN TO USE / WHEN NOT TO USE / ALTERNATIVES / FIRST PRINCIPLES.
  ☐ 4.4   Code Example: 2-3 examples, compiling, idiomatic, with comments.
           Or explicitly marked OMIT with reason if no non-trivial usage.
  ☐ 4.5   Two seniority levels (Junior/Mid + Senior/Staff). First person.
           30-second version present at each level. Staff push-deeper included.
  ☐ 4.6   All 8 Q-types present (Definition, Mechanism, Comparison, Scenario,
           Debugging, Deep Dive, Misconception/Trap, Performance & Scalability).
           Minimums met per depth level (★☆☆: 2; ★★☆: 3; ★★★: 4). 🗣️ template per type.
           Interviewer type adaptation table at end.
           Misconception/Trap: ≥2 questions for ★★☆+; omit for ★☆☆.
           Performance & Scalability: ≥2 questions for ★★☆+; omit for ★☆☆.
  ☐ 4.7   Comparison (★★☆+): table present. Deciding factor in one sentence.
           No "Interview tip" or "Bring up proactively" lines.
  ☐ 4.8   Field Q&A (★★☆+): Production Failures (3+), Candidate Mistakes (4+),
           Questions to Ask (4+). Live Coding Context present or OMIT with
           reason. Blank line between every Q and A.
  ☐ 4.9   System Design (★★★ or sd: true): 6-step framework + Scale Inflection
           Point + Common System Design Traps (3) + Staff angle.
           Conditional note present. LLD sketch if applicable.
  ☐ 4.10  Diagram (★★★ or mechanism-visual): DUAL format (ASCII + Mermaid).
           Conditional note present. 4-bullet reading guide follows Mermaid.

INTERVIEWER EVALUATION RUBRIC (7 dimensions, 1-10):
─────────────────────────────────────────────────────────────────────────

  Any reviewer (human or LLM) can score this entry on 7 dimensions:

  D1 — DEPTH (1-10):
    1 = Only definition. No mechanism, no failures.
    10 = Complete internals, failure modes, at-scale behaviour.

  D2 — PRODUCTION REALISM (1-10):
    1 = Academic. No real failure scenarios.
    10 = 3+ realistic scenarios with diagnostic commands and root causes.

  D3 — TRADE-OFF COVERAGE (1-10):
    1 = No alternatives mentioned. "X is always best."
    10 = 3+ alternatives compared. Deciding factor clear. Anti-patterns listed.

  D4 — SENIORITY CALIBRATION (1-10):
    1 = One-size-fits-all answer.
    10 = Distinct answers for all 4 levels, plus time-calibrated versions.

  D5 — COMMUNICATION QUALITY (1-10):
    1 = Written English. Passive voice. Cannot be spoken.
    10 = First person. Active voice. Speakable at every level.

  D6 — INTERVIEW READINESS (1-10):
    1 = Spoken templates absent or unnatural; no push-deeper guidance.
    10 = All 6 Q-type 🗣️ templates genuinely speakable; Section 4.5
         push-deeper lines enable fluency under follow-up pressure;
         Section 4.8 Field Q&A drills cover production failures,
         candidate mistakes, and candidate-initiated questions.

  D7 — INTERVIEW SIGNAL COVERAGE (1-10):
    1 = Covers only 🧠 depth signal.
    10 = All 5 signals (🧠/🏭/⚖️/💬/🎯) explicitly trained across sections.

  SCORING:
  Total = D1+D2+D3+D4+D5+D6+D7 (max 70)
  PASS:        >= 49 (avg 7.0)
  PUBLICATION: >= 56 (avg 8.0)
  ELITE:       >= 63 (avg 9.0)

FINAL QUALITY BAR:
─────────────────────────────────────────────────────────────────────────

  An entry PASSES if:
    - Self-validation checklist: all 10 items checked
    - Evaluator rubric score: >= 49
    - All five interviewer signals represented in Section 4.5
    - No invented facts, API names, benchmarks, or incident details
    - All sample answers pass the SPEAK TEST:
      "Could a real candidate say this in a real interview?"

  Do not set status: complete unless ALL bars are met.

═══════════════════════════════════════════════════════════════════════════
SECTION 7: COMPLETE ENTRY SKELETON
═══════════════════════════════════════════════════════════════════════════

---
id: [CODE]-[NNN]
title: [Keyword Name]
category: [Category Name]
difficulty: [★☆☆ | ★★☆ | ★★★]
interview_weight: [low | medium | high | critical]
asked_at: [FAANG | Mid-size | Startup | All]
seniority: [junior | mid | senior | staff | all]
tags: #tag1, #tag2, #tag3
status: draft
sd: false
version: 1
---

# [ICON] [ID] — [KEYWORD NAME]

🎯 Interview Weight: [WEIGHT] — [one sentence]

---

### 🎯 Model Answer

**30 seconds:**
> [2-3 spoken sentences. What + Why + Key Insight. No jargon.]

**3 minutes (Senior):**
> [Full spoken answer in first person.
>  WHAT → WHY → HOW → TRADE-OFF → EXAMPLE.
>  Ends with the non-obvious insight.]

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:*   [Senior/Staff extension — system design angle, org impact]
*Adapting down:* [Junior: WHAT + WHY + EXAMPLE only]

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about [KEYWORD] - let me think
through what problem that solves."

**(2) First principles:** "From first principles, this domain needs
to handle [constraint A] and [constraint B]..."

**(3) Bridge:** "This reminds me of [related concept]. [KEYWORD]
works similarly/differently because..."

---

### 📘 Concept Explanation

**What it is:**
[1-2 sentences]

**The problem it solves:**
[2-3 sentences]

**How it works:**
[Step-by-step + ASCII diagram if helpful. Max 59 chars wide.]

**The key insight:**
[1-2 sentences — the non-obvious truth]

**When to use it:**
[Specific conditions]

**When NOT to use it:**
[Anti-patterns + simpler alternative]

**Alternatives:**
- Alternative A → [one-line distinction]
- Alternative B → [one-line distinction]

**First-principles derivation:**
[Derive WHY from basic constraints]

---

### 💻 Code Example

**Example 1: [Basic usage title]**

```{language}
[idiomatic code — compiles, with inline comments on non-obvious lines]
```

*Why this matters:* [1-3 sentences]

**Example 2: [Pattern title]**

```{language}
[code]
```

*Why this matters:* [1-3 sentences]

**Example 3: [Production-realistic title]**

```{language}
[code]
```

*Why this matters:* [1-3 sentences]

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> [30-second version — crisp, spoken, no jargon]

[Optional 1-2 sentence extension for mid-level]

*Push deeper:* [What to add if interviewer asks "Can you elaborate?"]

---

**Senior / Staff (5+ years):**
> [30-second version — same crisp opening]

[Full paragraph: mechanism + trade-off + production angle]

*Push deeper:* [Staff: system design + org impact]

---

### ❓ Questions & Spoken Answers

#### Definition
- "[Question 1]"
- "[Question 2]"
🗣️ "[Spoken answer template — first person, natural English]"

#### Mechanism
- "[Question 1]"
- "[Question 2]"
🗣️ "[Spoken answer template]"

#### Comparison
- "[Question 1]"
- "[Question 2]"
🗣️ "[Spoken answer template]"

#### Scenario
- "[Question 1]"
- "[Question 2]"
🗣️ "[Spoken answer template]"

#### Debugging
- "[Question 1]"
- "[Question 2]"
🗣️ "[Spoken answer template]"

#### Deep Dive
- "[Question 1]"
- "[Question 2]"
🗣️ "[Spoken answer template]"

#### Misconception / Trap
[Include for ★★☆ and above. Omit for ★☆☆.]
- "[Question framing a common wrong assumption — e.g., Since X is always faster...]"
- "[Another trap question]"
🗣️ "[Trap-recognition move: 'Actually, that premise isn't quite right —'
     then correct and answer the real question. First person, speakable.]"

#### Performance & Scalability
[Include for ★★☆ and above. Omit for ★☆☆.]
- "[Question about capacity ceiling, throughput, or saturation point]"
- "[Question about behaviour at 10x / 100x load, or horizontal scaling]"
🗣️ "[Scale-framing move: 'At current load X is fine, but at 10x the first
     thing that saturates is...' First person, with concrete bottleneck
     identified and cascade described.]"

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Lead with mechanism. Use precise terminology. |
| Hiring Manager   | Lead with business impact. Outcome language. |
| Bar Raiser       | Lead with trade-offs. What you would NOT use it for. |
| Peer Engineer    | Collaborative. "The thing I keep finding is..." |

---

### ⚖️ Comparison
[Include for ★★☆ or above. Omit for ★☆☆.]

| Option | [Dimension 1] | [Dimension 2] | Choose When |
|---|---|---|---|
| **[THIS]** | ... | ... | ... |
| [Alt A]    | ... | ... | ... |
| [Alt B]    | ... | ... | ... |

**The deciding factor:**
[One sentence]

---

### 🔥 Field Q&A
[Include for ★★☆ or above. Omit for ★☆☆.]

#### Production Failures

Q: [Scenario or failure question]

A: [Symptom → diagnosis → fix. First person where natural.]

Q: [Scenario or failure question]

A: [Symptom → diagnosis → fix]

Q: [Scenario or failure question]

A: [Symptom → diagnosis → fix]

#### Candidate Mistakes

Q: [Mistake to avoid]

**What NOT to say:** "[Wrong phrasing or wrong answer]"

**Say instead:** "[Correct framing]"

Q: [Mistake to avoid]

**What NOT to say:** "[Wrong phrasing or wrong answer]"

**Say instead:** "[Correct framing]"

Q: [Mistake to avoid]

**What NOT to say:** "[Wrong phrasing or wrong answer]"

**Say instead:** "[Correct framing]"

Q: [Mistake to avoid]

**What NOT to say:** "[Wrong phrasing or wrong answer]"

**Say instead:** "[Correct framing]"

#### Questions to Ask the Interviewer

Q: "[Smart question]"

*Why:* [Signals depth — 1 sentence]
*If asked back:* [What to say]

Q: "[Smart question]"

*Why:* [Signals depth]
*If asked back:* [What to say]

Q: "[Smart question]"

*Why:* [Signals depth]
*If asked back:* [What to say]

Q: "[Smart question]"

*Why:* [Signals depth]
*If asked back:* [What to say]

#### Live Coding Context
[Include when concept has coding round implications. Mark OMIT otherwise.]

Coding question template:
  [The specific coding challenge this concept generates — e.g.,
   "Implement a thread-safe bounded queue using this primitive"]

What the interviewer watches:
  - [Observable behavior #1 — concrete, specific]
  - [Observable behavior #2]
  - [Observable behavior #3]

Most common implementation mistake:
  [Specific coding error most candidates make]

*Why this signals:* [What it reveals about production depth]

---

### 🏛️ System Design
[Include for ★★★ or sd: true in frontmatter. Add conditional note below.]

> *(Conditional: included because [reason]. Omit for ★☆☆/★★☆ unless sd: true in frontmatter.)*

**Where [KEYWORD] appears in system design:**
- [scenario 1]
- [scenario 2]

**Example question:** [Specific system design question]

**6-step framework answer:**
Step 1 CLARIFY  — [requirement questions]
Step 2 ESTIMATE — [scale estimate]
Step 3 DESIGN   — [high-level design]
Step 4 DEEP DIVE— [where THIS concept fits, with trade-offs]
Step 5 ALTS     — [alternatives considered and rejected]
Step 6 EVOLVE   — [behaviour at 10× scale]

**Scale inflection point:**
At [X RPS / Y GB / Z concurrent users], [KEYWORD] becomes the limiting
factor because [specific reason]. Before that, [simpler alternative]
is sufficient.

**Common system design traps:**
- [Trap 1: what candidates typically design wrong and why it fails]
- [Trap 2]
- [Trap 3]

**LLD sketch:**
[ASCII class/component diagram if concept appears in LLD interviews]

**Staff angle:**
[Cost + org impact + migration plan + when simpler alternative wins]

---

### 📊 Diagram
[Include for ★★★ or when mechanism requires visual explanation. Add conditional note below.]

> *(Conditional: included because [reason]. Omit for topics where prose makes the mechanism clear.)*

```
[ASCII diagram — max 59 chars wide, label every component, show failure path]
```

```mermaid
[Mermaid diagram — same information as ASCII above]
```

- [Reading guide bullet 1: first state/transition explained]
- [Reading guide bullet 2]
- [Reading guide bullet 3]
- [Reading guide bullet 4]

═══════════════════════════════════════════════════════════════════════════
SECTION 8: INVOCATION — HOW TO USE
═══════════════════════════════════════════════════════════════════════════

─────────────────────────────────────────────────────────────────────────
SINGLE ENTRY:
─────────────────────────────────────────────────────────────────────────

  Generate technical interview entry for:

    ID:               JVM-036
    Keyword:          JIT Compiler
    Category:         Java & JVM Internals
    Difficulty:       ★★★
    Interview Weight: high
    Asked At:         FAANG, Mid-size
    Seniority:        senior, staff

  Follow Technical Interview Dictionary
  Generator prompt exactly.
  Use complete skeleton from Section 7.
  Do not skip any required section.

─────────────────────────────────────────────────────────────────────────
BATCH (5 entries):
─────────────────────────────────────────────────────────────────────────

  Generate technical interview entries:

  | ID      | Keyword          | Difficulty | Weight   |
  |---------|------------------|------------|----------|
  | JVM-036 | JIT Compiler     | ★★★        | high     |
  | JVM-037 | C1/C2 Compiler   | ★★★        | medium   |
  | JVM-038 | Tiered Compilation| ★★★       | medium   |
  | JVM-039 | Method Inlining  | ★★★        | high     |
  | JVM-040 | Deoptimization   | ★★★        | medium   |

  Category: Java & JVM Internals
  Seniority focus: senior, staff

  Follow Technical Interview Dictionary
  Generator prompt exactly.
  Separate entries with: ---FILE_BREAK---

─────────────────────────────────────────────────────────────────────────
ROLE-SPECIFIC FOCUS:
─────────────────────────────────────────────────────────────────────────

  Generate technical interview entry for:

    Keyword:   GC Tuning
    Role:      Senior Java Backend Engineer
    Company:   FAANG
    Focus:     Emphasise system design connections
               and production scenarios heavily.
               This role values production depth
               over theoretical knowledge.

  Follow Technical Interview Dictionary
  Generator prompt exactly.

─────────────────────────────────────────────────────────────────────────
SELF-VALIDATION CHECKLIST:
─────────────────────────────────────────────────────────────────────────

  Before finalising each entry verify:

  YAML & STRUCTURE:
  ☐ YAML: all 11 fields present (id, title, category, difficulty,
           interview_weight, asked_at, seniority, tags, status, sd, version)
  ☐ status: draft   version: 1   sd: false (or true if System Design included)
  ☐ No H2 headers (##) inside the entry body
  ☐ All markdown headers inside the body use ### or ####

  MODEL ANSWER (4.2):
  ☐ 30-second answer: 2-3 spoken sentences, no jargon, speakable aloud
  ☐ 3-minute answer: first person, WHAT→WHY→HOW→TRADE-OFF→EXAMPLE
  ☐ Blank Mind Recovery block present (3-step recovery sequence)
  ☐ Adapting up / Adapting down lines present

  SENIORITY ANSWERS (4.5):
  ☐ Two levels only: Junior/Mid + Senior/Staff
  ☐ 30-second version present at each level, in first person
  ☐ Push deeper guidance present at each level

  QUESTIONS & SPOKEN ANSWERS (4.6):
  ☐ All 8 Q-types present: Definition, Mechanism, Comparison,
    Scenario, Debugging, Deep Dive, Misconception/Trap,
    Performance & Scalability
  ☐ Minimums met: ★☆☆ → 2 per type; ★★☆ → 3 per type; ★★★ → 4 per type
  ☐ Each Q-type has a 🗣️ spoken template immediately below it
  ☐ Interviewer type adaptation table present at end of section
  ☐ All 🗣️ templates are in first person and speakable aloud

  CODE EXAMPLE (4.4):
  ☐ 2-3 examples; code compiles mentally (no invented APIs)
  ☐ try/finally or equivalent shown for any resource/lock pattern
  ☐ Or explicitly OMIT with reason if no non-trivial usage

  FIELD Q&A (4.8 — ★★☆ and above):
  ☐ Production Failures: ≥3 Q&As; each has symptom→diagnosis→fix
  ☐ Candidate Mistakes: ≥4 Q&As; correct framing given for each
  ☐ Questions to Ask: ≥4 smart questions with Why and If asked back
  ☐ Live Coding Context: present if concept has coding round implications
    (or explicitly OMIT with reason)
  ☐ Blank line between every Q and its A

  COMPARISON (4.7 — ★★☆ and above):
  ☐ Table has ≥3 rows; deciding factor in one sentence
  ☐ No "Interview tip" or "Bring up proactively" lines

  SYSTEM DESIGN (4.9 — ★★★ or sd: true):
  ☐ 6-step framework present + Staff angle present
  ☐ Scale inflection point present
  ☐ Common system design traps (3 bullets) present
  ☐ Conditional note present

  DIAGRAM (4.10 — ★★★ or mechanism-visual):
  ☐ DUAL format: ASCII (max 59 chars wide) + Mermaid
  ☐ 4-bullet reading guide follows Mermaid block
  ☐ Conditional note present

  FINAL SPEAK TEST:
  ☐ Read the 30-second answer aloud — does it sound natural?
  ☐ Read each 🗣️ template aloud — is it speakable under pressure?
  ☐ Are all production scenarios believable (not hypothetical textbook)?
  ☐ Are the Candidate Mistakes real things interviewees actually do wrong?

═══════════════════════════════════════════════════════════════════════════
END OF TECHNICAL INTERVIEW DICTIONARY GENERATOR v1.0
═══════════════════════════════════════════════════════════════════════════
````
