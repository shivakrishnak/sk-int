---
layout: default
title: "CSS - L4 Modern Layout"
parent: "CSS"
nav_order: 12
permalink: /css/l4-modern-layout/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [CSS Container Queries and Subgrid](#css-container-queries-and-subgrid) | critical |

---

# CSS Container Queries and Subgrid

🎯 **Interview Weight:** critical (★★★) - Container Queries
are the most significant CSS layout addition since Grid;
Subgrid completes the CSS Grid model. Both are now universally
supported and signal deep modern CSS knowledge.

---

### 🎯 Model Answer

**30 seconds:**

> Container Queries let components respond to their
> CONTAINER's size, not the viewport. A card at 300px wide
> renders a compact layout regardless of whether it's in
> a 400px sidebar or an 800px main content area. Media
> queries can't do this - they only see viewport width.
> CSS Subgrid allows grid children to participate in the
> PARENT'S grid tracks, enabling alignment across nested
> elements - the solution to multi-row card alignment.

**3 minutes (Senior):**

> Container Queries come in two forms: size queries
> (`@container (min-width: 400px)`) and style queries
> (`@container style(--variant: compact)`).
>
> Size queries require a containment context:
> `container-type: inline-size` (respond to width only -
> most common), `container-type: size` (respond to width
> and height), or `container-type: normal` (for style
> queries only). `container: sidebar / inline-size` sets
> both the name and type.
>
> The key insight: size containment means the element's
> size cannot be influenced by its descendants. This is
> required for container queries to avoid circular
> dependencies: if the container's size responded to its
> children, and the children responded to the container's
> size, infinite loops could occur.
>
> Subgrid: `grid-template-columns: subgrid` on a grid
> item makes that item's OWN columns align to the parent
> grid's column tracks. Previously, nested grid items were
> isolated - each grid container created its own track
> system. With subgrid, a `.card` can position its title,
> image, and footer each on a parent grid track, ensuring
> alignment with adjacent cards.
>
> `grid-template-rows: subgrid` is the critical feature:
> all cards in a grid row can align their internal rows
> (title, body, footer) to each other, even if content
> lengths differ.

*Adapting up:* Discuss container style queries for
condition-based theming; subgrid for design system
multi-column layouts.

*Adapting down:* Container queries are like media queries
but for the parent div's size, not the screen size.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Container Queries
and Subgrid - modern CSS layout features for responsive
components and nested grid alignment."

**(2) First principles:** "Media queries solve viewport-
level responsiveness. Components often live in containers
smaller than the viewport. Container Queries are media
queries for the element's container, enabling truly
component-level responsiveness."

**(3) Bridge:** "Think of Container Queries like a business
unit's budget vs the company's total revenue. The company's
revenue (viewport) is the global context. Each business
unit (container) has its own budget (size) that determines
its internal decisions."

---

### 📘 Concept Explanation

**What it is:**

**Container Queries**: CSS at-rules that apply styles
based on the size or style values of an ancestor element
(the "container"), not the viewport.

**Subgrid**: a `grid-template-columns/rows` value that
extends the parent grid's track definition into a nested
grid item, enabling alignment across grid hierarchy levels.

**The problem it solves:**

Media queries respond to the viewport. Components placed
in narrow sidebars need different layouts than the same
components in wide main content areas - at the same viewport
width. Media queries cannot express this.

Subgrid solves the "uneven card row" problem: cards with
different content heights have misaligned internal rows
(title, body, footer). Subgrid lets cards align to the
parent grid's rows.

**How it works:**

```
CONTAINER QUERIES:

Step 1: Declare containment context
  .sidebar {
    container-type: inline-size;
    /* or */
    container: sidebar / inline-size;
    /* name + type shorthand */
  }

Step 2: Write container query
  @container (min-width: 400px) {
    .card { flex-direction: row; }
  }

  /* Named container query */
  @container sidebar (max-width: 300px) {
    .card { font-size: 0.875rem; }
  }

  /* Relative units: cqi, cqw, cqh, cqmin, cqmax */
  .card__title {
    font-size: clamp(1rem, 3cqi, 2rem);
    /* 3% of the container's inline size */
  }

CONTAINER TYPES:
  inline-size: respond to width (most common)
  size:        respond to width + height
  normal:      style queries only, no size queries

CSS SUBGRID:

Without subgrid (problem):
  .grid { display: grid; grid-template-columns: 1fr 1fr; }
  .card { display: grid; } /* new isolated grid */
  /* Cards cannot align to each other's internal rows */

With subgrid (solution):
  .grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    grid-template-rows: auto auto auto;
    /* 3 rows: title / body / footer */
  }

  .card {
    display: grid;
    grid-row: span 3;          /* occupy 3 parent rows */
    grid-template-rows: subgrid; /* align to parent rows */
  }

  /* Now ALL cards align title/body/footer to same rows */

CONTAINER STYLE QUERIES:
  .card-wrapper {
    container-type: normal;
    --card-variant: compact;
  }

  @container style(--card-variant: compact) {
    .card { padding: 0.5rem; font-size: 0.875rem; }
  }
```

> **Code walkthrough:** This CSS Container Queries and Subgrid example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

`container-type: inline-size` creates CSS Containment for
the inline axis. This is why `width: 100%` on a child
inside a container-type element resolves to the container
size, not the viewport. Container queries require this
containment to avoid the infinite loop: container can't
be sized by children if children are sized by container.

**When to use Container Queries:**

- Reusable components that appear in multiple contexts
  (sidebar, main, modal, dashboard widget)
- Design system components that should be self-responsive
- Replacing page-level media queries for component layout

**When to use Subgrid:**

- Card grids where cards have multi-row internal structure
  (image + title + body + footer)
- Any layout where nested elements must align to the parent
  grid's tracks
- When `align-items: stretch` and fixed heights are hacks
  to achieve row alignment

**When NOT to use:**

Container size containment (`container-type: inline-size`)
prevents the container from being sized by its children's
content (in the inline axis). This can break layouts that
depend on content-driven sizing. Test carefully when adding
to existing layouts.

**Alternatives:**

Media queries for viewport-level responsiveness (still valid
for page layout). CSS Grid `auto-fill` + `minmax` for
fluid grids without container queries. Flexbox wrapping
for single-axis fluid layouts.

**First-principles derivation:**

CSS has always had a cascade of responsive contexts:
viewport → page → component. Media queries provided
viewport-level responses. Container Queries complete the
model by providing component-level responses. CSS Subgrid
completes the grid model by making grid tracks inheriterable
(like other CSS properties) rather than isolated per
grid container.

---

### 💻 Code Example

**BAD: media query for component responsiveness**

```css
/* BAD: this only works if the card is always in a
   full-width context at small viewport sizes */
.card {
  display: flex;
  flex-direction: column;
}
@media (min-width: 600px) {
  .card {
    flex-direction: row;
  }
}
/* Problem: card in a narrow sidebar at 1200px viewport
   gets flex-direction: row even though it's only 280px wide
   The card is broken */
```

> **Code walkthrough:** Media queries respond to viewportice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> width, not element width. A 600px viewport breakpoint
> enables the row layout, but at 1200px viewport, the card
> in a 280px sidebar ALSO gets the row layout because the
> viewport is 1200px. The condition (card is wide enough)
> is not captured by a viewport query.

**GOOD: container query for component-level responsiveness**

```css
/* GOOD: card responds to its container, not the viewport */
.card-container {
  container-type: inline-size;
  /* Establishes containment context */
}

.card {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.card__image {
  width: 100%;
  aspect-ratio: 16/9;
  object-fit: cover;
}

/* Card layout changes when ITS container is wide enough */
@container (min-width: 400px) {
  .card {
    flex-direction: row;
    align-items: flex-start;
  }
  .card__image {
    width: 200px;
    aspect-ratio: 1;
  }
}

/* Even smaller container: compact mode */
@container (max-width: 250px) {
  .card { padding: 0.5rem; }
  .card__description { display: none; }
  .card__title { font-size: 0.875rem; }
}
```

> **Code walkthrough:** The `.card-container` elementice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> establishes the containment context. The card inside
> responds to the container's width. Place this card in
> a 600px sidebar - it renders column layout. Place it
> in a 1200px main area - it renders row layout. SAME
> CSS, SAME component, correct layout in both contexts.

**PRODUCTION: Subgrid for aligned card grids**

```css
/* Card grid with subgrid for internal alignment */
.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
}

.product-card {
  display: grid;
  /* Span 3 rows of the parent: image, content, actions */
  grid-row: span 3;
  grid-template-rows: subgrid;
  /* Each card's rows align to the parent grid's rows */

  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
}

.product-card__image {
  /* Row 1: image (same height across all cards in a row) */
  grid-row: 1;
  width: 100%;
  aspect-ratio: 4/3;
  object-fit: cover;
}

.product-card__content {
  /* Row 2: content (same baseline regardless of text length) */
  grid-row: 2;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.product-card__actions {
  /* Row 3: footer actions (always aligned to bottom of row) */
  grid-row: 3;
  padding: 1rem;
  border-top: 1px solid #e5e7eb;
  display: flex;
  gap: 0.5rem;
}
```

> **Code walkthrough:** `grid-row: span 3` tells each cardice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> to occupy 3 row tracks in the parent grid. `grid-template-
> rows: subgrid` means those 3 row tracks are inherited
> from the parent (not the card's own rows). Cards with
> short descriptions and cards with long descriptions now
> have their actions row aligned at the same Y position
> in each grid row. This eliminates the classic "misaligned
> buttons" problem in product card grids.

**PRODUCTION: container + subgrid combined**

```css
/* Container query enables layout switching */
/* Subgrid aligns internal rows in grid layout */

.dashboard {
  container-type: inline-size;
}

.widget-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}

@container (min-width: 768px) {
  .widget-grid {
    grid-template-columns: repeat(2, 1fr);
    /* 3 implicit rows per grid track: header/content/footer */
  }
  .widget {
    grid-row: span 3;
    grid-template-rows: subgrid;
    display: grid;
  }
}

.widget__header { grid-row: 1; padding: 0.75rem 1rem; }
.widget__content { grid-row: 2; padding: 1rem; flex: 1; }
.widget__footer  { grid-row: 3; padding: 0.5rem 1rem; }
```

> **Code walkthrough:** The `.dashboard` container respondsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> to its own width (not viewport). When the dashboard is
> narrow (embedded widget panel), single column. When wide
> (main content area), 2-column grid with subgrid alignment.
> The same widget component works in both contexts without
> JavaScript or component variants.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Container Queries let me write CSS that responds to the
> parent container's width, not the viewport width. I declare
> `container-type: inline-size` on the parent, then use
> `@container (min-width: 400px)` to change the child's
> styles. This is better than media queries for reusable
> components that appear in different contexts - sidebar,
> main content, modal - at the same viewport width.

---

**Senior / Staff (5+ years):**

> Container Queries complete the CSS responsiveness model.
> Media queries handle viewport-level layout. Container
> queries handle component-level layout. Design system
> components should be self-responsive: a card component
> should adapt based on its containment context, not
> viewport width. This makes components truly portable.
>
> Subgrid is the complement to Container Queries for grid
> layouts. Grid's limitation has always been track isolation:
> nested grids create their own track systems. Subgrid
> enables track inheritance. For card grids with multi-row
> internal structure, subgrid is now the standard solution
> over `align-items: stretch` hacks.
>
> Container queries + subgrid together represent the maturity
> of CSS's layout capabilities. Component-level responsiveness
> + cross-component alignment without JavaScript.

---

### ⚠️ Common Misconceptions

**"Container queries replace media queries"**

No. Media queries handle viewport-level responsiveness (page
layout, navigation patterns). Container queries handle
component-level responsiveness. Both serve different purposes
and work together. A page layout changes at a viewport
breakpoint; within that layout, components respond to their
container.

**"container-type on every element is fine"**

`container-type: inline-size` creates CSS Containment. It
prevents the element from being sized by its children's
inline content. If you need content to drive the container's
width, don't use `container-type: inline-size`. Apply
container-type only on wrapper/layout elements, not on
content elements.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: container query never applies styles**

```
Debug checklist:
1. Is container-type declared on the PARENT of .card?
   (Not on .card itself)

2. Is there a named container mismatch?
   @container sidebar ... needs container: sidebar / inline-size

3. Is the parent width actually exceeding the breakpoint?
   DevTools: inspect parent element, check Computed → width

4. Is the parent's width constrained?
   container-type: inline-size on the parent means width
   is NOT determined by children. Might be 0 if the parent
   has no explicit width or flexbox sizing.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

**Symptom: subgrid items not aligning**

```
Checklist:
1. Is grid-row: span N on the card? (N = number of rows)
   Without span, card doesn't occupy multiple parent rows

2. Is grid-template-rows: subgrid on the card?
   Not grid-template-rows: auto auto auto

3. Does parent grid define row tracks?
   grid-template-rows: repeat(3, auto) - explicit rows needed

4. Are all cards the same number of rows?
   Mixed span sizes cause alignment gaps
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Container query vs media query | 3-4 min | Component vs viewport |
| container-type values | 3 min | Containment implications |
| Container query units (cqi, cqw) | 3 min | Relative to container |
| Container style queries | 3-4 min | Conditional theming |
| Subgrid motivation | 3-4 min | Track alignment problem |
| grid-row: span N + subgrid | 4 min | Mechanics |
| Container + Subgrid combined | 4 min | Practical patterns |
| Containment implications | 3-4 min | Sizing side effects |
| Browser support strategy | 2-3 min | Progressive enhancement |
| Named containers | 3 min | Multi-context components |
| Container queries in frameworks | 3-4 min | React integration |
| Future: @when / @else | 3 min | CSS conditional rules |

---

**[JUNIOR] Q1 - [MECHANISM] What problem do Container Queries solve that**
Media Queries cannot?** `[SENIOR]` CONCEPTUAL

*Why they ask:* Core motivation for container queries.

*Likely follow-up:* "When should you still use media queries?"

> **Answer:**
>
> Media queries respond to the viewport - the browser window
> width. They cannot answer "how wide is the element that
> contains this component?"
>
> The problem: component placement varies in modern layouts.
> A product card might appear in:
> - A 300px sidebar (narrow)
> - A 1200px main content area (wide)
> - A 600px modal
> - A 400px dashboard widget
>
> All at the SAME viewport width. Media queries applied
> to the component see the viewport width, not the
> component's container width. There's no way to say
> "render row layout when my container is wide enough."
>
> Before container queries, solutions:
> 1. Resize Observer in JavaScript: observe container size,
>    toggle classes on the component. Works but requires JS.
> 2. Multiple media query breakpoints for each context:
>    `.sidebar .card` media queries, `.main .card` media
>    queries. Brittle, context-dependent, not reusable.
> 3. Accept layout compromise: fixed layouts that work
>    "well enough" everywhere.
>
> Container queries provide CSS-native element-level
> responsive design:
> ```css
> .card-wrapper { container-type: inline-size; }
> @container (min-width: 400px) {
>   .card { flex-direction: row; }
> }
> /* Works correctly in any context - the card
>    responds to its OWN container's width */
> ```
>
> When to still use media queries:
> - Page-level layout (nav to sidebar switch at viewport width)
> - Typography scale (base font-size responsive to viewport)
> - Feature detection (`@media (hover: hover)`)
>
> *What separates good from great:* Container queries are
> component-scoped; media queries are page-scoped. A design
> system should use container queries for component
> responsiveness and media queries only for layout-level
> changes that are genuinely viewport-dependent.

---

**[SENIOR] Q2 - [MECHANISM] What is container-type and what are its implications?**

*Why they ask:* container-type creates CSS containment - a
side effect with implications.

*Likely follow-up:* "What is the difference between
inline-size and size?"

> **Answer:**
>
> `container-type` declares the element as a query container
> and what type of dimensional queries it supports:
>
> `container-type: inline-size` (most common):
> - Creates a containment context for the INLINE axis (width
>   in horizontal writing modes)
> - Element's width cannot be influenced by its children
> - `cqi` and `cqw` units resolve to this container's width
> - Implied containment: `contain: inline-size layout style`
>
> `container-type: size`:
> - Containment for BOTH axes (width and height)
> - Element must have explicit height or display that
>   constrains it (flex/grid item)
> - `cqi`, `cqw`, `cqh`, `cqmin`, `cqmax` all available
> - Less commonly used (height is rarely container-queried)
>
> `container-type: normal` (default):
> - No size containment
> - Only style queries work (not size queries)
>
> The CRITICAL implication of `inline-size`:
>
> ```css
> .wrapper { container-type: inline-size; }
>
> /* Inside .wrapper, this behavior changes: */
> .child { width: auto; }
> /* .child's width is computed based on .wrapper's
>    width, not flowing from content */
>
> /* If .wrapper has no explicit width and is sized by
>    content, and .child responds to .wrapper, you might
>    get unexpected zero-width or collapsed layouts */
> ```
>
> In practice: `container-type: inline-size` on block
> elements that fill their parent width (like `<section>`,
> `<article>`, `<div>`) works perfectly. Problems arise
> on inline elements or elements sized by content.
>
> *What separates good from great:* `container-type: inline-size`
> implies `contain: inline-size layout style`. The `layout`
> containment means the element IS a "layout containment
> box" - its internal layout doesn't affect external
> elements. This is a performance optimization (like
> `contain: layout`) in addition to the query feature.
> So container queries ALSO give you layout isolation
> as a side effect.

---

**[SENIOR] Q3 - [MECHANISM] What are container query units (cqi, cqw, cqh)?**

*Why they ask:* CQ units are new relative units that enable
fluid container-responsive sizing.

*Likely follow-up:* "How do cqi and cqw differ?"

> **Answer:**
>
> Container query units are relative to the query container
> (the nearest ancestor with `container-type`):
>
> `cqw`: 1% of the container's width
> `cqh`: 1% of the container's height (`container-type: size` required)
> `cqi`: 1% of the container's inline size (usually = `cqw`)
> `cqb`: 1% of the container's block size (usually = `cqh`)
> `cqmin`: min(cqi, cqb) - smaller of the two
> `cqmax`: max(cqi, cqb) - larger of the two
>
> `cqi` vs `cqw`: `cqi` is writing-mode aware (inline axis).
> In horizontal writing mode, they're identical. In vertical
> writing mode, `cqi` is the height. `cqi` is more correct
> for internationalized text.
>
> Use cases:
>
> ```css
> .card-wrapper { container-type: inline-size; }
>
> /* Fluid typography relative to container */
> .card__title {
>   font-size: clamp(1rem, 4cqi, 2rem);
>   /* 4% of container width, clamped between 1-2rem */
>   /* Equivalent to vw-based fluid type but container-relative */
> }
>
> /* Fluid spacing */
> .card {
>   padding: clamp(0.5rem, 3cqi, 2rem);
> }
>
> /* Grid columns relative to container */
> .card-grid {
>   display: grid;
>   grid-template-columns: repeat(
>     auto-fill,
>     minmax(clamp(150px, 30cqi, 250px), 1fr)
>   );
> }
> ```
>
> These units enable fully fluid component design without
> JavaScript ResizeObserver tricks.
>
> *What separates good from great:* CQ units + `clamp()` +
> `@container` work together as a complete toolkit for
> responsive components. `clamp(1rem, 4cqi, 2rem)` is fluid
> font size: scales continuously from 1rem to 2rem as the
> container grows from 25 to 50cqi wide. No step-function
> breakpoints needed.

---

**[SENIOR] Q4 - [CONCEPTUAL] What is the problem that CSS Subgrid solves?**

*Why they ask:* Subgrid's motivation reveals depth of CSS Grid
understanding.

*Likely follow-up:* "What was the workaround before subgrid?"

> **Answer:**
>
> CSS Grid is a 2D layout system. Each `display: grid`
> element creates its own isolated track system. Nested
> grids create SEPARATE track systems with no relationship
> to the parent.
>
> The classic problem: card grid rows.
>
> ```
> WITHOUT SUBGRID:
>
> Parent Grid: 3 columns
> ┌──────────┬──────────┬──────────┐
> │ Card 1   │ Card 2   │ Card 3   │
> │ [Title]  │ [Title]  │ [Title]  │ ← misaligned
> │[Long     │ [Short   │ [Medium  │   if different
> │ content] │ content] │ content] │   lengths
> │ [Button] │ [Button] │ [Button] │ ← misaligned
> └──────────┴──────────┴──────────┘
> Cards are isolated - no shared rows across columns
> ```
>
> Workarounds before subgrid:
> 1. `align-items: stretch` + `display: flex` + `flex-direction:
>    column` + `justify-content: space-between` on cards.
>    Works for simple 3-part cards (title/body/footer) but
>    doesn't handle multi-row bodies or more complex layouts.
> 2. Fixed heights on card rows. Brittle, breaks with content
>    changes or font changes.
> 3. JavaScript to equalize card heights using ResizeObserver.
>    Works but adds JS complexity.
>
> ```
> WITH SUBGRID:
>
> Parent Grid: 3 columns, 3 rows per "card row"
> ┌──────────┬──────────┬──────────┐
> │ Title 1  │ Title 2  │ Title 3  │ ← Row 1: aligned!
> │──────────│──────────│──────────│
> │ Long     │ Short    │ Medium   │ ← Row 2: tallest wins
> │ content  │ content  │ content  │   (grid row expands)
> │──────────│──────────│──────────│
> │ Button 1 │ Button 2 │ Button 3 │ ← Row 3: aligned!
> └──────────┴──────────┴──────────┘
> Cards participate in parent grid rows - perfect alignment
> ```
>
> *What separates good from great:* The pre-subgrid flex
> workaround works for strictly 3-section cards. It breaks
> when body has multiple sub-elements (category tag, rating,
> description, reviews - 4 rows in "body"). Subgrid handles
> arbitrary numbers of rows with zero extra CSS.

---

**[MID] Q5 - [MECHANISM] Explain the CSS required to implement Subgrid**
for a card grid.** `[SENIOR]` HANDS-ON

*Why they ask:* Tests ability to actually implement subgrid.

*Likely follow-up:* "What happens if cards have different
numbers of rows?"

> **Answer:**
>
> ```css
> /* Parent grid: 3 columns, implicit rows */
> .card-grid {
>   display: grid;
>   grid-template-columns: repeat(3, 1fr);
>   /* NOTE: grid-template-rows not needed on parent
>      for basic subgrid - rows are implicitly sized */
>   gap: 1rem;
>
>   /* BUT: for explicit row alignment, define rows: */
>   grid-auto-rows: auto;
>   /* Or set explicit rows per "card block": */
>   /* This is the key: each set of 3 rows (card) */
>   /* shares the same row heights */
> }
>
> .product-card {
>   display: grid;
>   /* Span 3 rows of parent (for 3-section card) */
>   grid-row: span 3;
>   /* Inherit parent's row tracks for those 3 rows */
>   grid-template-rows: subgrid;
>
>   /* Optional: named grid areas */
>   grid-template-areas:
>     "image"
>     "content"
>     "footer";
> }
>
> .product-card__image {
>   grid-area: image; /* Row 1 */
> }
>
> .product-card__content {
>   grid-area: content; /* Row 2 - tallest card's content sets height */
>   padding: 1rem;
>   display: flex;
>   flex-direction: column;
>   gap: 0.5rem;
> }
>
> .product-card__footer {
>   grid-area: footer; /* Row 3 - always aligned */
>   padding: 1rem;
>   border-top: 1px solid #e5e7eb;
>   display: flex;
>   align-items: center;
>   justify-content: space-between;
> }
> ```
>
> What happens with different numbers of rows? Each card
> MUST have the same `grid-row: span N`. If one card has
> 4 rows and others have 3, the grid breaks - the 4-row
> card doesn't fit the 3-row pattern.
>
> Solution: if cards have variable content, wrap extra
> content in the same cell: all "content" still occupies
> row 2 regardless of internal content count.
>
> *What separates good from great:* Column subgrid is
> the less-discussed but powerful version. `grid-template-columns:
> subgrid` on a card placed across multiple parent columns
> lets the card's internal columns align to parent column
> tracks. A full-width card can place its image exactly
> in column 1 and its text in columns 2-3, aligning with
> other elements on the same row.

---

**[SENIOR] Q6 - [MECHANISM] What are container style queries and when are they**
useful?** `[SENIOR]` MECHANISM

*Why they ask:* Style queries are newer and less known but
architecturally powerful.

*Likely follow-up:* "How do style queries differ from
theming with CSS custom properties?"

> **Answer:**
>
> Container style queries test the COMPUTED VALUE of a CSS
> custom property on the container, not its size.
>
> ```css
> /* Declare a container for style queries */
> .card-wrapper {
>   container-type: normal; /* No size containment needed */
>   /* or any container-type */
> }
>
> /* Variant flag on the container */
> .sidebar .card-wrapper {
>   --card-variant: compact;
> }
>
> /* Default: full-size card */
> .card { padding: 1.5rem; }
>
> /* Style query: respond to container's custom property */
> @container style(--card-variant: compact) {
>   .card {
>     padding: 0.5rem;
>     font-size: 0.875rem;
>   }
>   .card__description { display: none; }
>   .card__image { height: 80px; }
> }
> ```
>
> How it differs from theming with custom properties:
>
> **Custom property inheritance** (standard approach):
> ```css
> /* Set in parent, consumed by children via var() */
> .sidebar { --card-padding: 0.5rem; }
> .card { padding: var(--card-padding, 1.5rem); }
> ```
> Works but: each property needs to be individually
> declared and consumed. Adding a "compact" mode requires
> adding many `--compact-X` properties.
>
> **Style query** (new approach):
> ```css
> /* One flag on the container */
> .sidebar { --card-variant: compact; }
> /* Style query changes MANY properties at once */
> @container style(--card-variant: compact) {
>   /* any number of properties changed */
> }
> ```
> Style queries are like CSS-level theme switching based
> on a container flag - closer to "media queries for
> themes" than individual custom property inheritance.
>
> *What separates good from great:* Style queries are
> currently (2024) only supported for custom properties
> (not for standard CSS properties like `color` or `font-size`).
> `@container style(color: red)` doesn't work yet - only
> `@container style(--my-prop: value)`. The spec plans to
> eventually support standard properties, making style
> queries a full "CSS state query" mechanism.

---

**[SENIOR] Q7 - [MECHANISM] How do you handle browser support for container**
queries and subgrid?** `[SENIOR]` PRODUCTION

*Why they ask:* Production CSS requires support strategies.

*Likely follow-up:* "What does progressive enhancement look
like for container queries?"

> **Answer:**
>
> **Container queries**: supported in all modern browsers
> since:
> - Chrome 105+ (September 2022)
> - Firefox 110+ (February 2023)
> - Safari 16+ (September 2022)
>
> For target browsers: > 1%, last 2 versions - this covers
> all modern browsers. Container queries are safe for
> production.
>
> For legacy browsers (if required): `@supports` progressive
> enhancement:
>
> ```css
> /* Default: media-query-based layout (legacy) */
> @media (min-width: 600px) {
>   .card { flex-direction: row; }
> }
>
> /* Enhanced: container-query-based layout */
> @supports (container-type: inline-size) {
>   /* Override the media query with container query */
>   .card-wrapper { container-type: inline-size; }
>
>   @media (min-width: 600px) {
>     /* Remove the media query layout override */
>     .card { flex-direction: column; } /* back to default */
>   }
>
>   @container (min-width: 400px) {
>     .card { flex-direction: row; } /* container-based */
>   }
> }
> ```
>
> **Subgrid**: supported in all modern browsers since:
> - Chrome 117+ (September 2023)
> - Firefox 71+ (December 2019)
> - Safari 16+ (September 2022)
>
> All currently maintained browsers support subgrid.
> Safe for production as of 2024.
>
> Polyfill: there's no meaningful polyfill for either
> feature. The progressive enhancement approach (graceful
> degradation to media queries / flex workaround) is the
> right strategy.
>
> *What separates good from great:* The @supports query
> for container-type is the correct feature detection method.
> Unlike many CSS features where you can test for the property,
> `container-type` doesn't have a meaningful fallback to
> wrap. The progressive enhancement pattern provides full
> functionality for modern browsers and acceptable (not
> broken) layout for legacy browsers.

---

**[SENIOR] Q8 - [MECHANISM] How do you use named containers for multi-context**
components?** `[SENIOR]` HANDS-ON

*Why they ask:* Named containers are key to controlling
which container a query targets.

*Likely follow-up:* "What happens if no named container
is found?"

> **Answer:**
>
> By default, container queries target the nearest ancestor
> container. Named containers target a SPECIFIC ancestor
> by name.
>
> ```css
> /* Name the containers */
> .page-layout {
>   container: page / inline-size;
>   /* shorthand: name + type */
>   /* equivalent to: */
>   /* container-name: page; */
>   /* container-type: inline-size; */
> }
>
> .sidebar {
>   container: sidebar / inline-size;
> }
>
> .card-area {
>   container: card-area / inline-size;
> }
>
> /* Component inside nested containers */
> .widget {
>   /* Default: responds to nearest container (card-area) */
>   padding: 1rem;
> }
>
> /* Target specific named container */
> @container sidebar (max-width: 260px) {
>   .widget { padding: 0.5rem; font-size: 0.875rem; }
> }
>
> @container page (min-width: 1200px) {
>   .widget { font-size: 1.125rem; }
>   /* Responds to page layout width regardless of nesting */
> }
> ```
>
> Named containers are powerful for:
> - Components that need to respond to different levels
>   of layout context (widget responds to page, not just
>   immediate parent)
> - Navigation components that respond to the sidebar
>   they're inside, not the nearest div
>
> What if named container not found?
> The query simply never matches. No error. Useful for
> optional container names: write your query for a named
> container, and if the component is placed without that
> container, the query is silently ignored.
>
> *What separates good from great:* The container naming
> system is the CSS equivalent of CSS Custom Properties'
> inheritance: a component can respond to ANY ancestor
> with a given name, not just the immediate parent. This
> enables a component library where components declare
> their own container name conventions, and layout systems
> declare matching container names. The component responds
> correctly regardless of nesting depth.

---

**[SENIOR] Q9 - [MECHANISM] What layout patterns become possible with Container**
Queries + Subgrid that weren't possible before?**
`[STAFF]` ARCHITECTURE

*Why they ask:* Staff engineers articulate the design
language impact of new features.

*Likely follow-up:* "How does this change component
library design?"

> **Answer:**
>
> **1. Truly portable components**
>
> Before: components needed context-specific CSS classes
> (`.card--sidebar-variant`, `.card--main-variant`).
>
> After: one component adapts to any context automatically.
> Component libraries ship ONE implementation. Applications
> only declare the container context.
>
> **2. Cross-row card alignment without JavaScript**
>
> Before: ResizeObserver + JavaScript to equalize card
> heights, or fixed heights in CSS.
>
> After: `grid-template-rows: subgrid` with `grid-row: span N`.
> Zero JavaScript. Works with dynamic content changes.
>
> **3. Intrinsic grid + fluid component layout**
>
> ```css
> .grid {
>   container-type: inline-size;
>   display: grid;
>   grid-template-columns: repeat(
>     auto-fill, minmax(min(100%, 280px), 1fr)
>   );
> }
> .card-container { container-type: inline-size; }
> @container (min-width: 400px) {
>   .card { flex-direction: row; }
> }
> ```
>
> Grid adapts columns to container width.
> Cards inside adapt layout to THEIR own width.
> Two levels of container responsiveness, zero media queries.
>
> **4. Contextual theming via style queries**
>
> Before: separate component variants or CSS custom
> property per property.
>
> After: `--context: sidebar` on a layout region.
> `@container style(--context: sidebar)` in the component.
> Completely declarative theming.
>
> **Impact on component library design:**
>
> Component libraries can now use `container-type: inline-size`
> on their wrapper elements as a first-class feature.
> The `size` prop (`.button--sm`, `.button--lg`) can be
> supplemented with automatic size based on container.
> A component renders "small" in a narrow sidebar and
> "large" in a wide hero section - same markup.
>
> *What separates good from great:* The combination of
> Container Queries + Subgrid + `@scope` (emerging) represents
> a complete CSS component model: component-level scoping
> (@scope), component-level responsiveness (Container Queries),
> and cross-component alignment (Subgrid). When `@scope` gains
> broad browser support, CSS will have a native "component
> primitive" without needing CSS Modules or CSS-in-JS.

---

**[SENIOR] Q10 - [MECHANISM] What is the `container` shorthand and what are**
the best practices?** `[SENIOR]` HANDS-ON

*Why they ask:* Practical syntax knowledge.

*Likely follow-up:* "Should you always name your containers?"

> **Answer:**
>
> The `container` shorthand combines `container-name` and
> `container-type`:
>
> ```css
> /* Verbose */
> .sidebar {
>   container-name: sidebar;
>   container-type: inline-size;
> }
>
> /* Shorthand: name / type */
> .sidebar { container: sidebar / inline-size; }
>
> /* Multiple names (space-separated): */
> .sidebar { container: sidebar layout-region / inline-size; }
> /* @container sidebar { } and @container layout-region { }
>    both match this element */
>
> /* Just a type (anonymous container): */
> .card-wrapper { container: inline-size; }
> /* Equivalent to: container-type: inline-size; (no name) */
> ```
>
> Best practices:
>
> 1. **Name layout-level containers**: `container: page /
>    inline-size`, `container: sidebar / inline-size`. These
>    are design zones that multiple components respond to.
>
> 2. **Anonymous containers for immediate wrappers**:
>    `.card-wrapper { container-type: inline-size }`. No
>    name needed if only the immediate child queries it.
>
> 3. **Prefer `inline-size` over `size`**: `size` requires
>    the element to have a constrained height. `inline-size`
>    works for any width-based responsiveness (95% of cases).
>
> 4. **Put container-type on the WRAPPER, not the component**:
>    the component queries its PARENT container. The component
>    itself should not have `container-type` unless it's also
>    a wrapper for nested components.
>
> 5. **Document container names in design tokens or README**:
>    Container names are "magic strings" in CSS - document
>    them like design tokens.
>
> *What separates good from great:* `container: name / type`
> can be combined with `@layer`:
> ```css
> @layer layout {
>   .page { container: page / inline-size; }
>   .sidebar { container: sidebar / inline-size; }
> }
> ```
> Placing container declarations in a dedicated `@layer layout`
> makes them easy to find and modify. This is part of the
> systematic CSS architecture approach.

---

**[STAFF] Q11 - [MECHANISM] How do container queries work with React/Vue**
components?** `[SENIOR]` PRODUCTION

*Why they ask:* Framework integration is a real-world need.

*Likely follow-up:* "Do you need any JavaScript for container
queries in React?"

> **Answer:**
>
> Container queries are pure CSS - no JavaScript required.
> In React, the pattern is:
>
> ```jsx
> // ProductCard component
> // CSS handles all responsiveness - no ResizeObserver needed
>
> // ProductCard.module.css
> .cardContainer {
>   container-type: inline-size;
>   /* The wrapper queries for the card inside */
> }
>
> .card {
>   display: flex;
>   flex-direction: column;
>   gap: 1rem;
> }
>
> // @container is in the CSS file, not JSX
>
> // ProductCard.tsx
> import styles from './ProductCard.module.css';
>
> function ProductCard({ product }) {
>   return (
>     <div className={styles.cardContainer}>
>       <article className={styles.card}>
>         {/* JSX handles content structure */}
>         {/* CSS handles responsive layout */}
>       </article>
>     </div>
>   );
> }
> ```
>
> CSS Modules + Container Queries:
> ```css
> /* ProductCard.module.css */
> .container { container-type: inline-size; }
> .card { display: flex; flex-direction: column; }
>
> /* Container query with scoped class name: */
> @container (min-width: 400px) {
>   .card { flex-direction: row; }
>   .image { width: 200px; }
> }
> /* CSS Modules scopes .card and .image,
>    but @container is NOT scoped to the module.
>    The container query targets the nearest container,
>    which is the scoped .container element. Correct! */
> ```
>
> No JavaScript needed: Container queries replace the
> ResizeObserver + conditional render/className pattern
> that was common before:
>
> ```jsx
> // BEFORE container queries (needed JavaScript):
> const isNarrow = useContainerWidth(containerRef) < 400;
> return (
>   <div ref={containerRef} className={isNarrow ? 'narrow' : 'wide'}>
>     ...
>   </div>
> );
>
> // AFTER container queries (pure CSS):
> return (
>   <div style={{ containerType: 'inline-size' }}>
>     ...
>   </div>
> );
> ```
>
> *What separates good from great:* Setting `containerType`
> in React inline styles (`style={{ containerType: 'inline-size' }}`)
> works but is inefficient if many instances share the
> same value. Define the container wrapper class in CSS
> and reuse the className. Inline styles for container-type
> are acceptable for dynamic container names
> (`containerName: `widget-${id}``).

---

**[STAFF] Q12 - [MECHANISM] How will `@when` / `@else` affect component**
queries in the future?** `[STAFF]` ARCHITECTURE

*Why they ask:* Staff engineers track specification evolution.

*Likely follow-up:* "How do you handle this today without @when?"

> **Answer:**
>
> `@when` and `@else` are proposed CSS conditional rules
> (CSS Conditional Rules Level 5). They unify `@media`,
> `@supports`, and `@container` into a single conditional
> syntax with branching:
>
> ```css
> /* Current CSS: verbose duplication */
> @container (min-width: 400px) {
>   @supports (display: grid) {
>     .card { display: grid; }
>   }
> }
> @container (max-width: 399px) {
>   .card { display: flex; }
> }
>
> /* Proposed @when / @else (not yet standard): */
> @when container(min-width: 400px)
>   and supports(display: grid) {
>   .card { display: grid; }
> } @else {
>   .card { display: flex; }
> }
> ```
>
> This reduces duplication when conditions must cover
> all cases (not just progressive enhancement).
>
> Current status: `@when`/`@else` is a Level 5 proposal.
> No browser has shipped it. No timeline for implementation.
>
> How to handle this today:
>
> 1. Default to the "simpler" case, progressive enhance:
>    ```css
>    .card { display: flex; } /* default (no support) */
>    @supports (container-type: inline-size) {
>      @container (min-width: 400px) {
>        .card { display: grid; }
>      }
>    }
>    ```
>
> 2. Trust browser support: if the browsers in your
>    browserslist support container queries universally
>    (they do in 2024), skip the `@supports` wrapper.
>
> 3. CSS Nesting simplifies overlapping conditions:
>    ```css
>    @container (min-width: 400px) {
>      .card { display: grid; }
>      /* Nested @supports */
>      @supports not (display: grid) {
>        .card { display: flex; }
>      }
>    }
>    ```
>
> *What separates good from great:* The `@when`/`@else`
> proposal is part of a broader CSS conditional
> system being designed with input from all major browser
> vendors. It reflects the CSS spec's move toward a more
> programmable model. Following the CSS WG GitHub repository
> and attending Chrome/Firefox developer preview talks
> is how staff engineers stay ahead of these changes.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | container-type implications + subgrid mechanics |
| Hiring Manager | Component portability with container queries |
| Bar Raiser | @when proposal, style queries future |
| Peer Engineer | Card grid subgrid implementation |

---

### ⚖️ Comparison Table

| Feature | Media Queries | Container Queries | Subgrid |
|---|---|---|---|
| Responds to | Viewport | Container | Parent grid tracks |
| Level | Page layout | Component | Nested layout |
| Requires | Nothing | container-type | display: grid parent |
| Browser support | Universal | Modern (2022+) | Modern (2022+) |
| Affects | Styles | Styles | Track alignment |
| JavaScript needed | No | No | No |

---

### 🏛️ System Design

**Design system with Container Queries and Subgrid:**

Large e-commerce platform: 50+ reusable components,
placement in 10+ layout contexts. Goal: zero context-specific
CSS variants.

**Architecture:**

```
CONTAINER HIERARCHY:
┌─────────────────────────────────────────────┐
│  page-layout (container: page / inline-size) │
│  ┌──────────────────────────────────────────┐│
│  │ sidebar                                  ││
│  │ (container: sidebar / inline-size)       ││
│  │ ┌────────────────────────────────────┐   ││
│  │ │ component-wrapper                  │   ││
│  │ │ (container-type: inline-size)      │   ││
│  │ │ ┌────────────────────────────────┐ │   ││
│  │ │ │ <Card> responds to nearest     │ │   ││
│  │ │ │ unnamed container (280px wide) │ │   ││
│  │ │ │ → compact layout               │ │   ││
│  │ │ └────────────────────────────────┘ │   ││
│  │ └────────────────────────────────────┘   ││
│  └──────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────┐│
│  │ product-grid (subgrid for card rows)      ││
│  │ → all cards aligned title/body/CTA rows  ││
│  └──────────────────────────────────────────┘│
└─────────────────────────────────────────────┘

Design token layer:
  :root { container: root / inline-size; }
  All layout sections declare named containers.
  
Component library convention:
  Every widget wrapper uses container-type: inline-size.
  Components never use media queries (only @container).
  Card grids always use subgrid.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 📊 Diagram

```
WITHOUT CONTAINER QUERIES:
 Viewport 1200px
 ┌──────────┬──────────────────────────────┐
 │ Sidebar  │ Main Content                 │
 │ 280px    │                              │
 │ [Card]   │ [Card] [Card] [Card]         │
 │ ← Same   │   Same CSS!                  │
 │ viewport │   Wrong layout in sidebar!   │
 └──────────┴──────────────────────────────┘

WITH CONTAINER QUERIES:
 ┌──────────┬──────────────────────────────┐
 │ Sidebar  │ Main Content                 │
 │ container│ container: main / inline-size│
 │ 280px    │ 900px                        │
 │ [Compact]│ [Full Layout] [Full] [Full]  │
 │ ← CQ sees│ ← CQ sees 900px             │
 │  280px   │  (not 1200px viewport!)      │
 └──────────┴──────────────────────────────┘
```

```mermaid
flowchart TD
    A[Component needs responsive layout] --> B{What responds to what?}
    B -->|Viewport width| C[Use @media]
    B -->|Container width| D[Use @container]
    D --> E[Add container-type to parent wrapper]
    E --> F[@container size-query in component CSS]
    G[Grid cards need aligned rows] --> H[Use Subgrid]
    H --> I[Parent: display grid with row template]
    I --> J[Cards: grid-row span N + grid-template-rows: subgrid]
    J --> K[Internal rows align across all cards in a row]
```

> **Diagram walkthrough:** The decision tree for container
> queries vs media queries is simple: if the layout decision
> depends on where the component is placed (container context),
> use container queries. If it depends on the viewport (like
> navigation collapsing to hamburger), use media queries. For
> grid card alignment, subgrid requires three pieces: a parent
> grid with explicit rows, cards that span those rows, and the
> subgrid declaration to inherit the parent's row tracks.

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



