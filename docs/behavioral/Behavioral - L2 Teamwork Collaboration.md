---
layout: default
title: "Behavioral - L2 Teamwork Collaboration"
parent: "Behavioral Interview Skills"
nav_order: 4
permalink: /behavioral/l2-teamwork-collaboration/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Teamwork and Collaboration](#teamwork-and-collaboration) | critical |
| 2 | [Giving and Receiving Feedback](#giving-and-receiving-feedback) | high |

---

# Teamwork and Collaboration

🎯 Interview Weight: critical - teamwork is assessed in
every behavioral loop; engineers who cannot articulate
how they work with others, handle disagreements, and
contribute to a shared outcome are filtered at every
level from junior to staff.

---

### 🎯 Model Answer

**30 seconds:**
> Effective teamwork means actively contributing to shared
> outcomes, not just doing your individual tasks well.
> In engineering it specifically means: communicating
> progress and blockers proactively, being explicit about
> your assumptions and asking about others', and taking
> joint ownership of outcomes rather than defending
> your piece of the work. The failure mode is working
> in isolation and surfacing conflicts too late.

**3 minutes (Senior):**
> Teamwork in engineering has three concrete behaviors:
> proactive communication, explicit assumption management,
> and shared accountability.
>
> Proactive communication means you surface blockers,
> risks, and changes before they become problems for
> others. "I'm running three days late" communicated
> at the start of the delay is a different impact from
> the same information communicated at the deadline. Most
> collaboration failures in engineering are communication
> timing failures, not competency failures.
>
> Explicit assumption management means you state your
> assumptions when making decisions and invite challenge:
> "I'm assuming the API response time is under 100ms -
> if that changes, the architecture decision changes."
> Engineers who build on unstated assumptions create
> brittle systems and difficult team dynamics.
>
> Shared accountability means taking ownership of the
> team outcome, not just your module. If the release
> fails because of someone else's piece, a collaborative
> engineer asks: "What could I have done differently
> to catch this earlier?" This is not about blame
> redistribution - it is about creating a learning
> culture and a high-trust team environment.
>
> The non-obvious insight: collaboration problems in
> engineering are usually diagnosed as personality
> conflicts but are usually structure problems. Two
> engineers disagreeing constantly in design reviews
> often have no shared definition of "good." Fixing
> the structure (team agreement on decision criteria,
> explicit escalation paths) fixes the collaboration
> problem without requiring either person to change
> their personality.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers define collaboration
structures, not just exhibit them. They establish the
norms: how decisions get made, what requires full team
input vs individual discretion, how disagreements are
escalated. The staff contribution to teamwork is the
environment design, not just the individual behavior.

*Adapting down:* "Good teamwork means keeping your
teammates informed, surfacing blockers early, and
taking ownership of shared outcomes. The key habit
is communicating proactively rather than waiting
to be asked."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about teamwork and
collaboration - let me walk through what effective
engineering collaboration looks like in practice."

**(2) First principles:** "Teams succeed when each
member's work contributes to the shared goal and
each member has the information they need when they
need it. Collaboration is the system that ensures
both."

**(3) Bridge:** "Engineering collaboration is like
a well-designed distributed system: each component
does its work, but the interfaces between components
are explicitly defined and the failure modes are
handled. Poor collaboration is a poorly specified
interface."

---

### 📘 Concept Explanation

**What it is:**
Teamwork and collaboration in engineering is the set
of behaviors that enable a group of individuals to
produce a shared outcome more effectively than they
could individually: proactive communication, shared
accountability, explicit assumption management, and
constructive engagement with disagreement.

**The problem it solves:**
Engineering teams face coordination costs: each
person's work depends on others, and misalignment
in any dependency creates rework, delays, and
frustration. Collaboration behaviors are the
coordination mechanisms that reduce these costs.

**How it works:**

```
EFFECTIVE ENGINEERING COLLABORATION
=====================================

PROACTIVE COMMUNICATION
  Share: progress, blockers, risks, scope changes
  Timing: surface early, not at deadline
  Channel: right medium for urgency level
    Blocker on critical path -> immediate sync
    FYI update -> async message
    Decision needed -> calendar invite, not slack

ASSUMPTION MANAGEMENT
  State assumptions explicitly in design decisions
  Invite challenge: "Does this hold for your use case?"
  Document in ADRs: "We assumed X; if X changes,
    revisit Y"

SHARED ACCOUNTABILITY
  Own the team outcome, not just your module
  Offer help before asked when you see a risk
  Retro honestly: "What could I have caught earlier?"

DISAGREEMENT HANDLING
  Lead with shared goal: "We both want X, right?"
  Separate person from position: critique the
    design, not the designer
  Escalate with options: "Two paths: A or B.
    My preference is A because..."
```

**The key insight:**
Most team friction in engineering is misalignment
on implicit criteria, not personality. Two engineers
disagreeing about code review standards are not
incompatible people - they have different unstated
quality models. Making the criteria explicit resolves
most conflicts faster than any soft skill intervention.

**When to use it:**
Every team interaction: design reviews, code reviews,
standups, retrospectives, cross-functional planning.
Collaboration behaviors are not situational - they are
a baseline professional operating standard.

**When NOT to use it:**
Shared accountability does not mean consensus on
every decision. Over-collaboration (requiring full
team input on every decision) slows execution. The
skill is knowing which decisions need collaboration
and which should be made with autonomy.

**Alternatives:**
- Individual contributor model: high autonomy, low
  coordination cost, but limited on complex shared
  systems
- Pair programming: high collaboration density,
  not scalable to all work
- Async-first culture: reduces sync meetings, requires
  explicit written communication norms

**First-principles derivation:**
Complex engineering systems cannot be built by one
person. They require coordination of multiple people's
work over time. The coordination mechanism is
collaboration: communication, assumption alignment,
and shared accountability. Teams without explicit
collaboration behaviors develop implicit ones, which
are often inefficient or conflict-generating.

---

### 💻 Code Example

*(Omit: ARCHETYPE 6 - behavioral topic. No code blocks.)*

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Good teamwork means communicating proactively,
> stating your assumptions, and taking shared ownership
> of outcomes. The specific habit that matters most
> early career: surface blockers as soon as you
> identify them, not when they become deadline risks.

*Push deeper:* "In code reviews, collaboration means
explaining your reasoning in PR descriptions so
reviewers spend less time guessing your intent and
more time catching real issues. A five-sentence PR
description is a collaboration act."

---

**Senior / Staff (5+ years):**
> Senior collaboration includes designing the team's
> collaboration structures: how decisions get made,
> what needs full team input, how disagreements
> are escalated, and how outcomes are measured jointly.

The shift from mid to senior in teamwork is moving
from "I collaborate well" to "I make my team more
effective at collaborating." The senior signal is
when your presence changes the team's dynamic.

*Push deeper:* "Staff-level collaboration includes
cross-team and cross-functional collaboration, which
requires even more explicit interface definition.
When working across team boundaries, state your team's
constraints, timelines, and assumptions explicitly.
Assume nothing is shared by default across team
boundaries."

---

### ⚠️ Common Misconceptions

**Misconception 1: Collaboration means consensus on
all decisions.**

Effective teams make decisions - sometimes quickly and
without unanimous agreement. Consensus-seeking on all
decisions produces slow teams and diluted choices.
Collaboration means ensuring all voices are heard, then
making a clear decision the team commits to. Not every
member needs to agree; every member needs to be respected.

**Misconception 2: The best collaborators always
accommodate others' preferences.**

Persistent accommodation without disagreement signals
lack of conviction, which undermines trust. Engineers
who never push back are neither trusted nor influential.
Productive collaboration includes respectful disagreement,
explicit trade-off negotiation, and confident advocacy
for technical positions.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Teamwork story where you describe
the team's success but not your specific contribution.**

Symptom: "Our team did X and it worked out great."
Evaluator thinks: what was YOUR role? STAR requires
explicit Task (your personal responsibility). Fix:
"My specific role was [X]. I was responsible for
[Y component]. I specifically drove [Z decision]."

**Failure Mode 2: Describing a difficult team member
as "challenging" without specific behavior.**

Symptom: "One colleague had a really hard time with
feedback." No specifics, no observable behavior.
Fix: describe the specific behavior ("in code reviews,
he would accept changes verbally then re-implement
his original approach in the next commit"), what you
tried, and how it resolved - honest imperfect resolution
is fine.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What does effective collaboration look like to you?"
- "Tell me about a time you contributed to a
  high-functioning team."

🗣️ "I define effective collaboration as: everyone on
the team has the information they need when they need
it, decisions are made by the right people with the
right inputs, and everyone takes ownership of the
shared outcome, not just their piece. On my best team,
we had a standing norm: if you identified a risk that
could affect someone else's work, you surfaced it that
day, not at the end of the sprint. That one norm
prevented more delays than any other process we
had."

#### Comparison
- "How does collaboration in a small startup differ
  from collaboration at a large company?"
- "What is the difference between coordination and
  collaboration?"

🗣️ "At a startup, the collaboration cost is low because
everyone is in the same room or the same Slack channel.
Decisions happen fast, context is shared by proximity.
At a large company, collaboration requires explicit
investment: writing things down, using structured
decision-making processes, and creating shared
documentation that survives team changes.
Coordination is the scheduling and sequencing of
work - who does what, in what order. Collaboration
is the quality of how that work integrates: are
assumptions shared, are risks surfaced, are
dependencies understood? You can have coordination
without collaboration, and the seams between teams
will show in the product."

#### Scenario
- "Tell me about a time you worked on a team where
  collaboration was difficult. What did you do?"
- "Describe a situation where cross-functional
  collaboration led to a better outcome than you
  could have achieved alone."

🗣️ "**S (Situation):** During a platform migration
project, our team of four backend engineers was
working in relative isolation from the frontend team.
We were six weeks in before we discovered our API
contract assumptions were incompatible - we had
built pagination one way, they had built their
state management expecting a different model.
**T (Task):** I was the tech lead, and this was
going to cost us two weeks of rework if we did not
address it immediately.
**A (Action):** I called a joint design session the
same day I discovered the mismatch. I brought a
written options doc: three API contract variations
with the trade-offs for each team. We reviewed it
together, chose the option that minimized frontend
rework (slightly more backend work), and I documented
the decision in an ADR. I also proposed a weekly
interface review for the remaining six weeks.
**R (Result):** We recovered with only three days
of rework instead of two weeks. The interface review
caught two more mismatches early. I added 'joint API
contract review within the first two weeks' to our
project playbook as a standard practice."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Show you proactively prevented a collaboration failure |
| Hiring Manager | Show you took ownership of the team outcome |
| Bar Raiser | Show you changed a process, not just fixed one instance |
| Peer Engineer | Be specific about what you did, not "we worked together" |

---

### ⚖️ Comparison

| Collaboration Style | Team Speed | Decision Quality | Works When |
|---|---|---|---|
| **Proactive + Documented** | Medium | High | Team is distributed or growing |
| Informal verbal-only | High | Medium | Small co-located team |
| Consensus-required | Low | High | Safety-critical or irreversible decisions |
| Individual autonomy | High | Variable | Decoupled work, experienced team |

**The deciding factor:**
Choose your collaboration style based on the cost of
misalignment: the higher the cost of a missed
dependency or wrong assumption, the more formal
and documented the collaboration needs to be.

---

### 🔥 Field Q&A

#### Behavioral Scenarios

Q: Tell me about a time a team member was not pulling
their weight. How did you handle it?

**S (Situation):** "Our team was building a distributed
caching layer and one of the three engineers was
consistently missing sprint goals - two weeks running.
**T (Task):** I was not the team lead but I was working
most closely with this engineer.
**A (Action):** I asked for a 1:1 and opened with
curiosity, not accusation: 'I've noticed we've been
slower on the caching module than planned. Is there
something blocking you that I can help with?' It
turned out they had an under-specified requirement
and had been guessing rather than asking. I helped
them write out the gaps and we got PM clarification
the same day. We also agreed to do a daily 15-minute
check-in for the rest of the sprint.
**R (Result):** The engineer delivered on the next
two sprints. I learned: performance problems often
have structural causes that look like motivation
problems on the surface."

Q: Tell me about a time you disagreed with how your
team was working but could not change it. How did
you cope?

A: "Our team used a waterfall-style sprint planning
where requirements were locked before any technical
exploration. I thought it was creating rework, and
I raised this in a retrospective with a specific
proposal: a one-week discovery sprint before each
planning cycle. The team voted not to change the
process at that time. I disagreed but I committed.
I documented my concerns and the team's reasoning in
a retro note, asked to revisit after two more sprints,
and in the meantime I started doing personal discovery
spikes on new requirements before they locked in. Two
sprints later, one of my spikes had prevented a major
architecture error and the team adopted the discovery
sprint approach. The lesson: disagree and commit, but
continue to advocate with evidence."

Q: Describe a situation where you had to collaborate
with someone you found difficult to work with.

A: "I had a colleague who had a different default
working style: they preferred to move fast and fix
later; I preferred to design explicitly before
implementing. This created friction in code reviews -
I flagged design issues they saw as over-engineering.
I proposed a working agreement at the start of a
shared project: we would define the 'minimum design
necessary' criteria upfront, so neither of us was
guessing what level of design was expected. This
turned an ongoing conflict into a productive
conversation about trade-offs."

#### Candidate Mistakes

Q: What is the most common mistake candidates make
when answering teamwork questions?

**What NOT to say:** "We worked together really well
and everyone contributed equally."

**Say instead:** "The specific contribution I made to
the team's outcome was [X]. I did this by [specific
actions]. My teammate did [Y]. The combined effect was
[measurable result]."

Q: How do candidates fail to show genuine teamwork
rather than just describing it?

**What NOT to say:** "I'm a great team player. I always
help my colleagues when they need it."

**Say instead:** Give a specific story: "In [situation],
I noticed [colleague] was blocked on [specific issue].
I stopped my own work for a day and pair-programmed
with them to resolve it, because the team outcome
mattered more than my individual sprint velocity."

Q: What is the trap in "we" language during teamwork
stories?

**What NOT to say:** "We designed the architecture,
we built the system, we shipped it on time."

**Say instead:** "I designed the data model and
API contracts. My colleague owned the service layer.
The PM coordinated the stakeholder reviews. My
specific contribution was..."

Q: What do candidates miss when describing teamwork
failures?

**What NOT to say:** "The project failed because
the team wasn't aligned."

**Say instead:** "The project failed to hit the
timeline. Looking back, the key moment where I could
have made a different decision was [specific moment].
I should have [specific action]. This is what I
changed in subsequent projects."

#### Questions to Ask the Interviewer

Q: "How does the team make decisions when there is
strong disagreement?"

*Why:* Reveals the team's actual collaboration
culture - whether dissent is welcomed or suppressed.
*If asked back:* "I prefer teams where the best
argument wins, not the loudest voice. I use a
written options doc with explicit trade-offs to
depersonalize technical disagreements."

Q: "What does a typical retrospective look like
on this team?"

*Why:* Teams with real retrospective practices
have genuine collaboration cultures.
*If asked back:* "I've run retros with a standard
format: what worked, what didn't, what we change next.
The most important thing is that the action items
from retros actually get done."

Q: "How do team members get help when they're stuck?"

*Why:* Reveals the psychological safety and
collaboration norms of the team.
*If asked back:* "On my best teams, asking for help
is normalized and fast. On my worst teams, people
struggle solo for days before asking."

Q: "How does the team handle missed dependencies
between engineers?"

*Why:* Reveals whether the team has learned from
coordination failures or repeats them.
*If asked back:* "I try to make dependencies explicit
in planning and check in on them proactively rather
than waiting to discover misses at integration time."

---

---

# Giving and Receiving Feedback

🎯 Interview Weight: high - feedback culture is a proxy
signal for growth mindset; engineers who cannot give
specific feedback or who are defensive when receiving
it are a liability in any high-performing team.

---

### 🎯 Model Answer

**30 seconds:**
> Giving feedback means providing specific, behavior-focused
> observations with the goal of improving performance,
> not criticizing the person. Receiving feedback means
> genuinely listening, asking clarifying questions to
> understand, and deciding independently what to act on
> rather than either accepting everything defensively
> or rejecting everything defensively. The rarest skill
> is receiving feedback without becoming defensive.

**3 minutes (Senior):**
> Effective feedback has two sides: giving and receiving,
> and most people are weak on at least one.
>
> Giving feedback: the best feedback is specific,
> behavior-focused, and timely. "Your code lacks
> comments" is generic and person-focused. "This function
> is missing a comment explaining the O(n^2) complexity
> choice - future reviewers will optimize it incorrectly
> without that context" is specific, behavior-focused,
> and explains the impact. The Situation-Behavior-Impact
> (SBI) model is the giving structure: describe the
> situation, the specific behavior observed, and the
> impact of that behavior.
>
> Receiving feedback: the first job is to understand,
> not to respond. Most people hear feedback and
> immediately evaluate whether they agree. The better
> practice is to hear it, ask one clarifying question
> to confirm understanding, say "thank you for telling
> me this," and then take time privately to evaluate
> whether to act on it. Responding defensively in the
> moment - even if the feedback is wrong - closes
> future feedback channels.
>
> The non-obvious insight: the most valuable feedback
> you will ever receive is the feedback people were
> reluctant to give you. It was not delivered because
> the person feared your reaction. Your track record
> of receiving feedback openly is what determines
> whether you get the honest feedback that would
> actually change your performance.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Senior engineers create feedback culture
by modeling both sides visibly: they give specific,
actionable feedback in code reviews and design reviews,
and they publicly ask for feedback and act on it. "In
our last project review, I got feedback that my design
docs are hard to skim. I changed my format for the
next doc. Can you tell me if it's better?" This
modeling makes the team's feedback culture safe.

*Adapting down:* "Giving feedback means being specific
about what you observed and what impact it had, not
judging the person. Receiving feedback means listening
without becoming defensive. The skill that matters
most: saying 'thank you' before you decide whether
you agree."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about giving and
receiving feedback - let me walk through both sides
and what the failure modes look like."

**(2) First principles:** "Teams improve when
performance information flows accurately between
members. Feedback is the mechanism for that flow.
Any behavior that blocks feedback flow - vagueness
in giving, defensiveness in receiving - slows the
team's improvement rate."

**(3) Bridge:** "Feedback in a team is like error
reporting in a system: if errors are swallowed silently
(defensiveness blocks delivery) or logged without
detail (vague feedback), the system cannot self-
correct."

---

### 📘 Concept Explanation

**What it is:**
Feedback in professional settings is the direct
communication of specific observations about someone's
work or behavior, with the intent to help them improve
performance or maintain it. Effective feedback is
specific, behavior-focused, timely, and given with
respect for the person.

**The problem it solves:**
Without feedback, engineers repeat mistakes they do
not know they are making, continue behaviors they
would change if told the impact, and miss growth
opportunities that are visible to others but not to
themselves. Feedback is the correction signal in the
human performance system.

**How it works:**

```
GIVING FEEDBACK: SBI MODEL
============================

S - SITUATION
  "In yesterday's design review..."
  Anchors to observable context, not general pattern

B - BEHAVIOR
  "...you interrupted three people mid-sentence..."
  Observable action, not interpretation
  NOT: "you were being dismissive"
  YES: "you cut off the sentence before they finished"

I - IMPACT
  "...which meant their ideas were not captured
   and two people stopped contributing."
  Effect on outcomes or others, not on the giver

RECEIVING FEEDBACK: HEAR-ASK-THANK-DECIDE
============================================

HEAR: Listen without formulating your defense
ASK: "Can you give me a specific example?"
THANK: "Thank you for telling me this" (always)
DECIDE: Evaluate privately; do not decide in the room

FEEDBACK QUALITY SPECTRUM
  Least useful: "You should improve your communication"
  Better: "Your design doc was hard to skim"
  Best: "Your design doc has no summary section; I
    spent 10 min searching for the recommendation,
    which slowed the review. Adding a summary
    section would fix this."
```

**The key insight:**
The quality of feedback you receive is directly
proportional to how you respond to feedback. Interviewers
who hear you say "I once got feedback that [specific
behavior] was a problem, and here's what I changed"
are hearing evidence that you have an open feedback
loop with the people around you.

**When to use it:**
Give feedback immediately after the observable behavior
when possible - timely feedback has more impact. Receive
feedback graciously whenever offered, regardless of
whether you agree. Disagree with feedback privately
after processing, not publicly in the moment.

**When NOT to use it:**
Do not give feedback in public when it concerns
someone's personal performance - this is embarrassing
and reduces receptiveness. Do not give feedback to
someone who did not ask for it in non-work contexts.
Do not give feedback under emotional activation -
wait until you can observe the behavior and impact
calmly.

**Alternatives:**
- 360-degree reviews: structured, anonymous, less
  timely than real-time feedback
- Manager-delivered feedback only: scales poorly,
  creates information bottleneck
- Public code review: appropriate for code quality,
  not for behavioral feedback

**First-principles derivation:**
Performance improves when the gap between current
performance and desired performance is made visible
and specific. Feedback is the information that makes
the gap visible. The more specific and timely the
feedback, the smaller the correction needed to close
the gap. Systems without feedback loops drift from
optimal; the same is true for human performance systems.

---

### 💻 Code Example

*(Omit: ARCHETYPE 6 - behavioral topic. No code blocks.)*

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Giving feedback means being specific about what you
> observed and what impact it had, not judging the
> person. Receiving feedback means listening first,
> asking for clarification if needed, saying thank you,
> and then deciding privately whether to act on it.

*Push deeper:* "The feedback that helped me most early
in my career came from a code reviewer who wrote:
'This function is hard to test because it has three
responsibilities. Consider splitting into [specific
functions].' That specificity told me exactly what to
change and why. Generic feedback - 'this code needs
work' - I could not act on."

---

**Senior / Staff (5+ years):**
> Senior engineers should be creating feedback culture,
> not just participating in it. This means modeling
> both directions visibly: giving specific, actionable
> feedback in reviews and explicitly asking for feedback
> on your own work and acting on it publicly.

The signal interviewers look for at senior level:
a story where you received critical feedback, what
you did with it, and what measurably changed as a
result.

*Push deeper:* "The hardest feedback to give is to
someone above you in the hierarchy. The skill at
senior level is giving upward feedback constructively:
framing it as a shared problem rather than a criticism,
proposing a path forward rather than just identifying
the gap, and timing it well."

---

### ⚠️ Common Misconceptions

**Misconception 1: Positive feedback is not real
feedback - only critical feedback develops people.**

Positive feedback that is specific and behavioral
("your system design doc pre-empted the three objections
I had - that structure is exactly what we need") is one
of the highest-value coaching tools. It names what right
looks like and reinforces it. Blanket positive ("nice
work") is not feedback; specific positive absolutely is.

**Misconception 2: Receiving critical feedback gracefully
means agreeing with it.**

You can receive feedback professionally while disagreeing.
"Thank you - I want to make sure I understand your concern
before I respond" is professional. Agreeing with feedback
you believe is wrong just to avoid tension creates
misaligned expectations. Understand it, ask questions,
then respond honestly.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Feedback story describing the other
person's change without explaining your role in it.**

Symptom: "I gave them the feedback and they changed."
Evaluator thinks: what made it land? What was the
framing, the relationship, the timing? Without your
specific approach, this story demonstrates luck, not
feedback skill. Fix: describe HOW you delivered it -
the timing, the framing, the specific language, the
follow-up conversation.

**Failure Mode 2: Feedback-received story showing
immediate compliance without reflection.**

Symptom: "They told me X and I immediately changed."
Evaluator thinks: too compliant, no judgment. Strong
feedback receiving involves: understanding the observation,
evaluating it against your own assessment, deciding what
to integrate. Fix: "I took it seriously, asked a follow-up
to understand the specific instance, then changed [X]
but not [Y] because [reasoning]."

---

### 🎯 Interview Deep-Dive

#### Definition
- "Tell me about a time you gave difficult feedback
  to a colleague."
- "Describe a time you received feedback that was
  hard to hear. How did you respond?"

🗣️ "I received feedback from my tech lead that my
code reviews were too critical in tone - reviewers
were deterred from asking me to review their code.
My initial reaction was defensive: I thought I was
giving thorough feedback. But I asked for a specific
example, got one, and recognized it immediately.
My comments were technically accurate but framed
as 'this is wrong' rather than 'here's a more
resilient approach because...' I changed my review
comment template and started ending suggestions
with the reasoning. Three sprints later, I was
getting more review requests, not fewer. The
feedback was right."

#### Comparison
- "How does the SBI feedback model differ from
  just telling someone what they did wrong?"
- "When is written feedback better than verbal
  feedback?"

🗣️ "Telling someone what they did wrong conflates
observation with judgment: 'You made a poor decision'
is a judgment, not an observation. SBI separates
them: 'In the incident review, you stated X was
the root cause before we had completed the analysis
[Situation + Behavior]. Three engineers stopped
contributing their hypotheses because they assumed
you had already concluded [Impact].' Now the person
can see exactly what happened and its effect. Written
feedback is better when the feedback is complex and
needs to be processed carefully, or when the person
needs time to review supporting evidence. Verbal
feedback is better for immediate correction and
for delivery with warmth and nuance."

#### Scenario
- "Tell me about a time giving feedback improved
  a team outcome."
- "Describe a time you had to give feedback to
  someone more senior than you."

🗣️ "**S:** Our team's release cadence was slipping
because our tech lead's design docs consistently
lacked implementation details, requiring follow-up
questions that each cost two to three days.
**T:** I was the most junior person on the team but
I saw the pattern and wanted to address it without
creating conflict.
**A:** I prepared one specific example with the
impact documented - the three questions it generated,
the two and a half days it cost. I asked for a 1:1,
opened with the shared goal: 'I want to help us
hit release cadence. I've noticed a pattern I
think I can help with.' Then I shared the example
and proposed a design doc template that included
the implementation detail section. I offered to
write the first template.
**R:** The tech lead was receptive. We adopted the
template. The follow-up question pattern dropped
significantly in the next two projects."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Show you give technical feedback effectively |
| Hiring Manager | Show you receive feedback and act on it |
| Bar Raiser | Show you can give upward feedback constructively |
| Peer Engineer | Be honest about a time feedback was hard |

---

### ⚖️ Comparison

| Feedback Approach | Specificity | Reception | Works When |
|---|---|---|---|
| **SBI Model** | High | Good | Performance or behavior feedback |
| Peer code review | Technical | Good | Code quality, patterns |
| Manager-mediated | Variable | Variable | Sensitive situations |
| Anonymous 360 | Variable | Low defensiveness | Pattern identification |

**The deciding factor:**
Use SBI for real-time behavioral feedback. Use code
review for technical feedback. Use anonymous 360 when
the direct relationship makes real-time feedback unsafe.

---

### 🔥 Field Q&A

#### Behavioral Scenarios

Q: Tell me about a time you had to address a persistent
performance problem with a colleague.

A: "An engineer on my team was consistently submitting
PRs without tests, despite our team agreement. I had
mentioned it once and it had not changed. I asked for
a 1:1, used SBI: 'In the last three sprints, four of
your five PRs had no test coverage [situation/behavior].
This caused two incidents that I traced back to untested
edge cases, and it also created a norm pressure that
other engineers started using as justification to skip
tests too [impact].' I asked if there was a blocker -
there was: they were unfamiliar with our test framework.
We paired for two hours. Test coverage on subsequent
PRs improved significantly."

Q: Describe a time when feedback you gave was initially
rejected but turned out to be right.

A: "In a design review, I raised a concern that our
proposed database schema would make future multi-tenancy
difficult. The architect disagreed and we kept the
original design. Six months later, we had a large
customer requiring multi-tenancy and the migration
was painful. In the retro, the architect said my
concern was right and they wished they had listened.
I did not say 'I told you so' - I helped design the
migration. But I did use it to advocate for a post-
design review checklist that included multi-tenancy
considerations."

Q: How do you handle receiving feedback you believe
is genuinely wrong?

A: "I listen fully, ask for a specific example to
understand the evidence, say thank you, and then I
process privately. If I still disagree after reflection,
I return to the giver: 'I've thought about the feedback.
I understand [their concern]. My perspective is [X]
because [specific reasoning]. I'd like to understand
if there's something I'm missing.' This keeps the
conversation open without immediately accepting wrong
feedback or dismissing it defensively."

#### Candidate Mistakes

Q: What is the mistake candidates make when describing
receiving critical feedback?

**What NOT to say:** "I always take feedback well. I
appreciate when people help me improve."

**Say instead:** Give a specific story: "I received
feedback that [specific behavior]. My initial reaction
was defensive because [reason]. After reflecting, I
recognized [what was valid]. I changed [specific
behavior]. [Measurable outcome]."

Q: What do candidates get wrong when describing
giving feedback?

**What NOT to say:** "I'm very direct. I tell people
exactly what I think."

**Say instead:** "I use a specific-behavior-focused
approach. For example, in [situation] I said [specific
SBI phrasing] which led to [outcome]."

Q: How do candidates signal poor feedback culture?

**What NOT to say:** "I don't really like giving
negative feedback. I prefer to let things work
themselves out."

**Say instead:** "I give feedback early and
specifically, because small early feedback is less
uncomfortable than large late feedback when a pattern
has compounded."

Q: What is the gap in "I gave them feedback and they
improved" stories?

**What NOT to say:** "I told them the issue and they
fixed it."

**Say instead:** "I told them [specific behavior with
SBI structure], they said [their perspective], we agreed
on [specific change], and over the next [timeframe]
I observed [specific improvement]."

#### Questions to Ask the Interviewer

Q: "How does this team typically handle code review
feedback? Is there a culture norm around how critical
is appropriate?"

*Why:* Reveals the team's actual feedback culture,
not the aspiration.
*If asked back:* "I prefer detailed, specific feedback
that improves the code. I give the same. I avoid vague
'this needs work' comments."

Q: "Can you tell me about the last time someone on
this team changed their approach based on feedback
from a peer?"

*Why:* Reveals whether feedback actually flows and
lands.
*If asked back:* "The signal I look for is teams where
both giving and receiving feedback is normalized, not
just encouraged in theory."

Q: "How does this team handle it when feedback in a
retro identifies a process problem that has been
raised before?"

*Why:* Reveals whether feedback leads to real change.
*If asked back:* "The pattern I try to prevent: retros
that produce action items that never get done. I track
retro action items explicitly."

Q: "What does 360-degree feedback look like on this
team?"

*Why:* Reveals the formality and seriousness of the
feedback culture.
*If asked back:* "I've found peer feedback most valuable
when it's specific and given by people who see my work
regularly. Generic 360s from people who barely interact
with me produce low signal."
