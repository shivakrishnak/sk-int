---
layout: default
title: "CSS - L1 Layout Basics"
parent: "CSS"
nav_order: 3
permalink: /css/l1-layout-basics/
render_with_liquid: false
---

# CSS Display Property

🎯 **Interview Weight:** critical - controls whether an element
participates in block, inline, flex, grid, or no layout;
the most important CSS property for layout architecture

---

### 🎯 Model Answer

**30 seconds:**

> The CSS `display` property controls how an element generates
> boxes and participates in the layout model. Key values:
> `block` (full width, starts new line), `inline` (flows
> with text, no width/height control), `inline-block`
> (flows like inline but accepts width/height), `flex`
> (Flexbox container), `grid` (Grid container), `none`
> (removes from layout entirely). Every layout decision
> starts with choosing the right display value.

**3 minutes (Senior):**

> `display` actually sets two things: the outer display type
> (how the element participates in its parent's formatting
> context) and the inner display type (the formatting context
> it creates for its children). `display: block` means "outer:
> block (participates in block flow), inner: flow (children
> participate in normal block/inline flow)." `display: flex`
> means "outer: block, inner: flex (children are flex items)."
>
> The outer types: `block` elements start on new lines and
> take full width by default. `inline` elements flow within
> text and don't accept width/height. Most elements default
> to one or the other - `div` is `block`, `span` is `inline`.
>
> `inline-block` is the most common "workaround" value - it
> flows inline but accepts box model properties. This was
> the main way to lay out items horizontally before Flexbox.
> Replaced by Flex/Grid in modern CSS but still useful for
> things like inline badges, buttons in text flow, or icons.
>
> `none` removes an element from layout AND makes it
> inaccessible to screen readers. Use `visibility: hidden`
> to hide visually but keep accessibility tree, or the
> sr-only technique (clip + size 1px) to hide visually but
> keep in accessibility tree.
>
> `contents` is the unusual value: it removes the element's
> box but keeps its children. Useful for semantic wrapper
> elements that shouldn't affect layout.

*Adapting up:* Discuss the two-value syntax (`display:
block flow`), `display: contents` and accessibility
implications, flow-root for BFC creation.

*Adapting down:* block takes full width, inline flows with
text, flex/grid for layout containers.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the CSS display
property - let me walk through what it controls."

**(2) First principles:** "From first principles, every
element needs to know: do I start on a new line or flow
with text? Do I create a layout context for my children?
Display controls both."

**(3) Bridge:** "Think of display like a traffic rule for
elements: block elements say 'I own this lane,' inline
elements say 'I share the lane with text,' flex/grid say
'I manage my children's lanes.'"

---

### 📘 Concept Explanation

**What it is:**

`display` sets an element's outer display type (how it
participates in flow layout) and its inner display type
(the formatting context it creates for its children).

**The problem it solves:**

HTML elements need to participate in layout in different
ways - some should stack vertically, others flow inline
with text, others should be layout containers with their
own positioning rules for children.

**How it works:**

```
OUTER TYPES (how element fits in parent flow):
  block       - starts new line, takes full width
  inline      - flows with text, no width/height
  run-in      - rare: depends on next sibling

INNER TYPES (formatting context for children):
  flow        - normal block/inline flow (default)
  flow-root   - BFC (block formatting context)
  flex        - flexbox layout for children
  grid        - grid layout for children
  table       - table layout for children
  ruby        - ruby annotation layout

COMBINED SHORTHAND VALUES:
  block         = block flow
  inline        = inline flow
  inline-block  = inline flow-root
  flex          = block flex
  inline-flex   = inline flex
  grid          = block grid
  inline-grid   = inline grid
  none          = removed from layout entirely
  contents      = box removed, children kept

VISUAL REFERENCE:
  div (block):  [ full width, new line ]
  span (inline):    flows with text
  flex:         [ child | child | child ]
  grid:         [ child | child ]
                [ child | child ]
```

**The key insight:**

`display: none` removes the element from both visual layout
AND the accessibility tree. Screen readers skip it entirely.
This is correct for modals and dropdowns that should be
completely hidden. For content that should be visually
hidden but remain accessible (e.g., screen-reader labels),
use the sr-only technique: position absolute, clip, 1px size.

**When to use it:**

- `flex`: any 1D layout (row or column, gap, alignment)
- `grid`: any 2D layout, named areas, complex alignment
- `inline-block`: inline elements needing box model control
- `none`: complete removal (modals, hidden panels)
- `flow-root`: creating a BFC to contain floats or
  prevent margin collapse

**When NOT to use it:**

Don't use `display: none` for accessibility-relevant content
you want to temporarily hide. Don't use `inline-block` for
grid/flex-style layouts (Flex is more powerful and cleaner).

**Alternatives:**

- `visibility: hidden` - hides visually, keeps layout space,
  accessible tree still present
- `opacity: 0` - hides visually, keeps layout, events fire
- `clip-path: inset(50%)` + `width:1px; height:1px` -
  the sr-only pattern for accessible visual hiding
- `content-visibility: auto` - defers rendering for
  off-screen content (performance optimization)

**First-principles derivation:**

Given constraint: HTML elements need to participate in
different layout algorithms (block flow, text flow, flex,
grid) and create different layout contexts for their
children. A single property controlling both outer and
inner layout type is the minimal solution.

---

### 💻 Code Example

**BAD: inline element with width/height (doesn't work)**

```css
/* BAD: span is inline, width/height have no effect */
span.badge {
  width: 20px;
  height: 20px;
  background: red; /* background works */
  /* width/height silently ignored */
}
```

> **Code walkthrough:** Inline elements ignore `width` and
> `height`. The badge will be as wide as its content, not
> 20x20px. This is a common confusion for new developers
> who add size to inline elements and wonder why it doesn't
> work.

**GOOD: correct display for each use case**

```css
/* inline-block: flows with text, accepts size */
.badge {
  display: inline-block;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: red;
}

/* flex container: 1D layout */
.toolbar {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

/* grid container: 2D layout */
.page-layout {
  display: grid;
  grid-template-columns: 250px 1fr;
  grid-template-rows: auto 1fr auto;
}
```

> **Code walkthrough:** Each value matches the layout need.
> `inline-block` for an element that must flow with text
> but have precise dimensions. `flex` for 1D toolbar with
> alignment. `grid` for 2D page structure with named rows
> and columns. The choice of display IS the layout decision.

**PRODUCTION: accessible show/hide vs display:none**

```css
/* Completely removes - screen readers skip entirely */
.hidden {
  display: none;
}

/* Hides visually, keeps space, events still fire */
.invisible {
  visibility: hidden;
}

/* Hides visually, screen readers CAN still read */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0,0,0,0);
  white-space: nowrap;
  border: 0;
}
```

> **Code walkthrough:** Three different "hidden" concepts
> with different accessibility and layout implications.
> `display: none` is for truly non-existent content.
> `visibility: hidden` for layout-preserving hide.
> `.sr-only` for visually hidden but screen-reader accessible
> labels, skip links, and supplementary text - the standard
> pattern used by every major accessibility-focused framework.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `display` controls how an element participates in the page
> layout. The key values: `block` means the element takes
> full width and starts on a new line (div, p, h1 are
> block by default). `inline` flows with text and ignores
> width/height (span, a are inline). `inline-block` is a
> hybrid - flows with text but accepts width/height.
> `flex` makes the element a Flexbox container for its
> children. `grid` makes it a CSS Grid container. `none`
> removes it from layout entirely (screen readers also
> skip it). Choosing the right display value is usually
> the first layout decision for any component.

*Push deeper:* Explain the difference between `display: none`
and `visibility: hidden` - one removes from layout and
accessibility tree, the other just hides visually.

---

**Senior / Staff (5+ years):**

> `display` sets both the outer display (how the element
> fits in its parent's formatting context) and inner display
> (the formatting context it creates for children). `display:
> flex` means "I'm block-level in my parent, and I create
> a flex formatting context for my children."
>
> The production decisions around display are often
> accessibility-related. `display: none` removes content
> from the accessibility tree - right for dialogs that are
> truly closed, wrong for content you want screen readers
> to announce. The sr-only pattern (`position: absolute;
> width: 1px; height: 1px; clip: rect(0,0,0,0)`) is the
> standard for visually hidden but screen-reader accessible
> content. `display: contents` removes the element box
> but keeps children in flow - useful for semantic wrapper
> elements that create DOM hierarchy without affecting layout.
>
> `display: flow-root` (creating a block formatting context)
> is the modern replacement for `overflow: hidden` as a
> clearfix. It contains floats and prevents margin collapse
> without the overflow side effect.

---

### ⚠️ Common Misconceptions

**"Inline elements can't have width and height"**

They can't with `display: inline`. Changing to
`inline-block` enables full box model control while
maintaining text flow behavior.

**"display: none and visibility: hidden are the same"**

`display: none` removes from layout (no space occupied)
and accessibility tree (screen readers skip it). `visibility:
hidden` hides visually but preserves layout space and
remains in the accessibility tree.

**"flex and grid are replacements for each other"**

Flex is for 1D layout (one axis at a time). Grid is for 2D
layout (rows and columns simultaneously). Choose based on
whether you're laying out in one or two dimensions.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: element dimensions not applying**

Diagnosis: check `display` in DevTools Computed tab. If
the element is `inline`, width/height are ignored.

Fix: `display: inline-block` or `display: block`.

---

**Symptom: display:none content announced by screen reader**

This shouldn't happen - `display: none` removes from
accessibility tree. If a screen reader is reading it,
the element may have `aria-hidden="false"` overriding,
or the screen reader has a non-standard behavior.

Verify: browser accessibility inspector shows no node.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| "Block vs inline vs inline-block" | 2-3 min | Three distinctions |
| "display:none vs visibility:hidden" | 2-3 min | Accessibility angle |
| Layout choice (flex vs grid) | 3-4 min | 1D vs 2D reasoning |
| BFC explanation | 3-4 min | flow-root + margin collapse |
| sr-only pattern | 3 min | Accessible visual hiding |

---

**Q1: What is the difference between block and inline
elements?** `[JUNIOR]` CONCEPTUAL

*Why they ask:* Foundational CSS knowledge; reveals whether
candidate understands the default document flow.

*Likely follow-up:* "Name three block and three inline
HTML elements."

> **Answer:**
>
> Block and inline are the two fundamental display modes
> of HTML elements.
>
> Block elements: take the full available width by default,
> start on a new line, and create a new "row" in the
> document flow. You can set width, height, margin, and
> padding on all sides. Block elements stack vertically.
> Examples: `div`, `p`, `h1-h6`, `ul`, `ol`, `li`,
> `section`, `header`, `footer`, `main`, `article`.
>
> Inline elements: flow within text content, only as wide
> as their content. They sit on the baseline of surrounding
> text. Width and height have no effect. Vertical margin
> and padding are quirky - they apply but don't push other
> elements away (they overlap). Examples: `span`, `a`, `em`,
> `strong`, `img` (technically inline-block by default),
> `button` (inline-block).
>
> Inline-block: the hybrid that flows with text but accepts
> full box model control (width, height, all margins and
> padding work normally).
>
> Note: HTML elements have CSS default display values, but
> CSS can override them. A `div` can be made inline; a
> `span` can be made block. The HTML element type sets the
> semantic meaning; CSS display controls the layout behavior.
>
> *What separates good from great:* Knowing that `img` is
> `inline` by default (creating a baseline gap below
> images) and that setting `display: block` on images
> eliminates this common mysterious gap.

---

**Q2: When should you use display:none vs
visibility:hidden?** `[MID]` COMPARISON

*Why they ask:* Tests accessibility and layout knowledge.

*Likely follow-up:* "What about opacity: 0?"

> **Answer:**
>
> They hide elements differently with different side effects.
>
> `display: none`: removes the element from the layout
> entirely (no space reserved), removes it from the
> accessibility tree (screen readers skip it), and
> removes all descendants from both. Use for: truly
> non-existent content (closed modals, off-screen menus,
> tab panels not currently active).
>
> `visibility: hidden`: hides visually but preserves the
> layout space (a gap remains where the element was).
> The element remains in the accessibility tree. Children
> can override with `visibility: visible` to become visible
> even though the parent is hidden. Use for: elements
> you want to momentarily hide without layout shift (avoid
> jank when toggling), or when you need pointer events
> blocked but layout preserved.
>
> `opacity: 0`: fully transparent but takes up space,
> remains in accessibility tree, AND pointer events still
> fire. The element is invisible but clickable. Use for:
> transitions and animations (fade in/out), or hover effects.
>
> The three form a spectrum: `display: none` is true
> removal; `visibility: hidden` is invisible-but-present;
> `opacity: 0` is invisible-but-interactive.
>
> *What separates good from great:* Mentioning the sr-only
> technique as the fourth option - visually hidden (using
> clip and 1px size) but still in the accessibility tree
> and read by screen readers. Used for supplementary labels
> and skip links.

---

**Q3: What is a Block Formatting Context and why does
it matter?** `[SENIOR]` MECHANISM

*Why they ask:* BFC is the mechanism behind several important
CSS behaviors. Tests deep layout knowledge.

*Likely follow-up:* "How do you create a BFC without
overflow:hidden?"

> **Answer:**
>
> A Block Formatting Context (BFC) is an independent layout
> region. Elements inside a BFC don't affect elements
> outside it for certain behaviors.
>
> What a BFC provides:
> 1. Contains floats - a floated child stays within the
>    BFC parent instead of overflowing it.
> 2. Prevents margin collapse - margins between a BFC
>    element and its contents don't collapse.
> 3. Doesn't overlap floats - a BFC element won't flow
>    under a sibling float; it respects the float boundary.
>
> How to create a BFC:
> - `overflow: hidden/auto/scroll` (the classic hack -
>   side effect: may clip content)
> - `display: flow-root` (the modern, clean way - no
>   side effects)
> - `display: flex` or `display: grid`
> - `position: absolute` or `position: fixed`
> - `float: left/right`
> - `contain: layout`
>
> Practical use: you have a parent div with only floated
> children. The parent collapses to 0 height because floats
> are removed from normal flow. `display: flow-root` on
> the parent creates a BFC, containing the floats.
> Also used to prevent unexpected margin collapse between
> sections.
>
> *What separates good from great:* Knowing that
> `display: flow-root` was introduced specifically as a
> clean BFC trigger without the `overflow: hidden` side
> effect. Before it, `overflow: hidden` was the "clearfix"
> hack, but it clips content and affects scrollability.
> `flow-root` does only what's needed.

---

**Q4: How does display:flex affect element behavior?**
`[MID]` MECHANISM

*Why they ask:* Flex is the primary 1D layout system;
understanding how it changes the display model matters.

*Likely follow-up:* "Does display:flex affect the element
or its children?"

> **Answer:**
>
> `display: flex` affects both the element and its direct
> children.
>
> For the element itself: it becomes a block-level element
> (takes full width, new line) and establishes a flex
> formatting context for its children.
>
> For its direct children (flex items): several defaults
> change:
> - They participate in flex layout instead of block/inline
> - `display` of children is "blockified" - inline children
>   behave like block for sizing purposes
> - Margins of flex items don't collapse (no margin collapse
>   inside flex containers)
> - Children can now receive `flex-grow`, `flex-shrink`,
>   `flex-basis`, `align-self`, `order` properties
> - `float` and `clear` on children have no effect
>   (flexbox overrides float)
> - `vertical-align` on children has no effect
>
> Importantly: Flex only affects DIRECT children. A
> grandchild is not a flex item. If you need grandchildren
> to be flex items, nest flex containers.
>
> `display: inline-flex` creates an inline-level flex
> container - same flex behavior for children, but the
> container itself flows inline with text rather than
> being block.
>
> *What separates good from great:* Knowing that `flex`
> establishes a new formatting context so floated or
> absolutely positioned elements among siblings don't
> interact with flex items.

---

**Q5: What is the difference between display:none and
removing an element from the DOM?** `[SENIOR]` COMPARISON

*Why they ask:* Tests understanding of the rendering
pipeline and accessibility implications.

*Likely follow-up:* "When would you remove from DOM vs
use display:none?"

> **Answer:**
>
> `display: none` leaves the element in the DOM. It is
> parsed, in the DOM tree, and React/JS can still reference
> it. The browser includes it in the accessibility tree
> check (and then marks it as not accessible). CSS
> transitions don't work on `display` changes (you
> can't fade in from `display: none`).
>
> Removing from the DOM (React unmount, DOM remove/append):
> the element is gone entirely. Memory is freed for the
> element and its subtree. Event listeners attached to
> it are removed (preventing memory leaks). The element
> is definitely inaccessible.
>
> When to prefer `display: none`:
> - The element should be instantly restorable (modal
>   that toggles open/close) - DOM manipulation has
>   overhead; display toggle is instant.
> - You need to preserve JavaScript state in the component
>   tree (React component state is lost on unmount).
> - You're using CSS animations that need the element
>   to exist before becoming visible.
>
> When to prefer DOM removal:
> - Truly transient content that will be regenerated
>   (a dropdown menu built from current data).
> - Memory-sensitive scenarios (rendering thousands of
>   items - virtualize the list, only mount visible items).
> - When state should reset on close.
>
> *What separates good from great:* Knowing that
> `content-visibility: auto` is a newer approach for
> performance - it defers rendering of off-screen
> elements entirely while keeping them in the DOM. Useful
> for long lists without full virtualization.

---

**Q6: What is display:contents and when is it useful?**
`[SENIOR]` MECHANISM

*Why they ask:* Tests knowledge of lesser-known but useful
display value.

*Likely follow-up:* "What are the accessibility concerns
with display:contents?"

> **Answer:**
>
> `display: contents` removes an element's box from the
> layout but keeps its children as if they were direct
> children of the parent. The element is visually
> "transparent" in the layout - its box doesn't exist,
> but its children do.
>
> Use case 1: semantic wrapper elements. You want a `<ul>`
> to be a flex item without its children also being flex
> items, but semantically the list wrapper should remain.
> `display: contents` on a wrapper makes its children
> participate directly in the parent's flex layout.
>
> Use case 2: unwrapping an element in a flex/grid context.
> A component receives a wrapper div you don't control,
> but you need its children to be grid items.
>
> Accessibility concern: in some browsers, `display: contents`
> removes the element from the accessibility tree, including
> its ARIA role. A `<button>` with `display: contents` may
> lose button semantics. This is a known browser bug, mostly
> fixed in modern browsers. Verify with accessibility
> inspector before using on interactive/semantic elements.
>
> Safe use: non-interactive structural wrappers (`div`,
> `section` used only as layout groupings). Avoid on
> semantic elements (`button`, `a`, `form`, `table`,
> `ul`, `li`) until browser behavior is verified.
>
> *What separates good from great:* Knowing that
> `display: contents` is on the CSS Display spec level 3
> and browser support is good but implementation bugs
> still exist for certain semantic elements. Testing
> with axe or a screen reader is always recommended.

---

**Q7: How do you handle display property changes for
CSS transitions and animations?** `[SENIOR]` PRODUCTION

*Why they ask:* Animating display changes is a common
frontend challenge with a non-obvious solution.

*Likely follow-up:* "What is the @starting-style rule?"

> **Answer:**
>
> `display` is not animatable - you cannot transition
> from `display: none` to `display: block` with a CSS
> transition. The element jumps instantly.
>
> The traditional workaround: combine display with
> opacity and visibility transitions:
>
> ```css
> .modal {
>   display: block;
>   opacity: 0;
>   visibility: hidden;
>   transition: opacity 0.3s, visibility 0.3s;
> }
> .modal.open {
>   opacity: 1;
>   visibility: visible;
> }
> ```
>
> Start with `display: block`, `opacity: 0`, and animate
> opacity. Use `visibility: hidden` instead of display
> to keep the element in layout during the animation.
>
> For DOM-insertion animations: the element starts hidden
> (opacity: 0) and you immediately add the `open` class
> to trigger the opacity transition. For removal: remove
> `open`, wait for transition to end (transitionend event),
> then set `display: none` or remove from DOM.
>
> The modern CSS approach: `@starting-style` (2023). This
> defines initial values for transitions that run when an
> element first becomes visible (including from
> `display: none`). The browser can now transition out
> of `display: none`:
>
> ```css
> .modal { transition: opacity 0.3s; opacity: 1; }
> @starting-style { .modal { opacity: 0; } }
> ```
>
> `@starting-style` tells the browser what value to
> transition FROM when the element first appears.
>
> *What separates good from great:* Knowing that the
> `popover` API and `<dialog>` element handle show/hide
> transitions natively, with browser support for
> `@starting-style` enabling entry/exit animations
> without JavaScript transition management.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Walk through BFC creation and its effects |
| Hiring Manager | Frame around accessibility implications of display:none |
| Bar Raiser | Discuss display:contents accessibility bugs |
| Peer Engineer | Share a display transition animation challenge |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational keyword - display value comparisons
covered in Q1, Q2, and Q5 of Interview Deep-Dive)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational keyword - not architecture-level)*

---

### 📊 Diagram

*(Omit: prose and code examples are sufficient; display
values are better understood through code than diagrams)*

---
---

# CSS Positioning

🎯 **Interview Weight:** high - positioning bugs are common
in production; stacking context and z-index misunderstandings
cause persistent layout issues

---

### 🎯 Model Answer

**30 seconds:**

> CSS `position` controls how an element is placed relative
> to its normal flow position or a containing block. Values:
> `static` (default, normal flow), `relative` (offset from
> its normal position, creates stacking context), `absolute`
> (removed from flow, positioned relative to nearest
> non-static ancestor), `fixed` (removed from flow,
> relative to viewport), `sticky` (hybrid: normal flow
> until a scroll threshold, then fixed relative to
> scroll container). The most common mistake: absolute
> elements position relative to the viewport when no
> positioned ancestor exists.

**3 minutes (Senior):**

> CSS position has five values with distinct behavior.
> `static` is the default - elements flow normally, `top/
> left/right/bottom` have no effect, no stacking context
> created.
>
> `relative` offsets the element from where it would be in
> normal flow, BUT the element still occupies its original
> space (other elements don't fill the gap). It creates a
> stacking context and a containing block for absolutely
> positioned descendants. Used frequently to "anchor" a
> parent for a child's absolute positioning.
>
> `absolute` removes the element from normal flow (no space
> reserved). It positions relative to the nearest ancestor
> with `position` other than `static` (the "positioned
> ancestor" or "offset parent"). If none exists, it positions
> relative to the initial containing block (viewport). This
> is the most common source of positioning bugs: adding an
> absolute element and seeing it fly to the top-left corner
> because no positioned ancestor is set.
>
> `fixed` removes from flow and positions relative to the
> viewport. Scrolling doesn't affect it. Breaks when inside
> a `transform` or `filter` parent (which creates a new
> containing block, overriding viewport).
>
> `sticky` is a hybrid: the element flows normally until it
> hits a scroll threshold, then "sticks" until its parent
> element scrolls past. Requires at least one of `top/
> right/bottom/left` to be set. Common gotcha: the parent
> element must be taller than the sticky element AND have
> `overflow` not set to `hidden/auto` (that contains
> the sticky within the parent scrollport).

*Adapting up:* Discuss stacking contexts in depth, the
containing block algorithm, and sticky position gotchas
with overflow.

*Adapting down:* static = normal, relative = shift from
normal, absolute = positioned relative to ancestor,
fixed = viewport-relative.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS positioning -
let me walk through the five position values and when
to use each."

**(2) First principles:** "From first principles, elements
need to be positioned in one of three coordinate systems:
relative to their natural position, relative to an ancestor,
or relative to the viewport."

**(3) Bridge:** "Think of absolute positioning like placing
a sticky note: you need a surface to stick it to (the
positioned ancestor). Without the surface, it falls to
the floor (viewport top-left)."

---

### 📘 Concept Explanation

**What it is:**

`position` determines the coordinate system used to place
an element and whether it participates in normal document
flow.

**The problem it solves:**

Normal document flow is unsuitable for UI patterns like
tooltips (should hover over other content), fixed headers
(should stay on screen while scrolling), and sticky nav
(should stick at scroll threshold).

**How it works:**

```
position: static   (default)
  - normal flow, top/left/right/bottom ignored

position: relative
  - normal flow (space preserved)
  - top/left/right/bottom: offset from normal position
  - creates: stacking context (with z-index)
  - creates: containing block for absolute descendants

position: absolute
  - OUT of normal flow (no space reserved)
  - positioned relative to: nearest NON-static ancestor
  - if no ancestor: relative to initial containing block
  - inset: 0 fills the containing block entirely

position: fixed
  - OUT of normal flow
  - positioned relative to: viewport
  - EXCEPT: inside transform/filter/will-change/
    contain: layout/paint -> positioned to that element

position: sticky
  - IN normal flow until threshold
  - "sticks" at threshold (e.g., top: 0) until parent ends
  - requires: scroll container must NOT have overflow:hidden
  - requires: parent must be taller than sticky element
```

**The key insight:**

`position: relative` on a parent makes it the "offset
parent" - the anchor for absolutely positioned children.
This is the most important CSS positioning pattern. Always
set `position: relative` on a container when you want
its absolute children to be positioned relative to it.

**When to use it:**

- `relative`: to be the offset parent for absolute children,
  or to shift an element slightly without affecting flow
- `absolute`: tooltips, dropdowns, badges, decorative
  overlays, anything that should overlay other content
- `fixed`: sticky headers, floating action buttons,
  cookie banners
- `sticky`: sticky table headers, sticky sidebar nav,
  sticky section headings

**When NOT to use it:**

Don't use absolute/fixed positioning for page layout -
use Flexbox or Grid. Positioning is for overlapping
elements, not for structural layout.

**Alternatives:**

- `inset-inline-start/end` and `inset-block-start/end` -
  logical property equivalents for RTL/LTR support
- CSS anchor positioning (coming) - positions relative
  to another element anywhere in the DOM
- `translate` transform - shifts visually without
  affecting flow (similar to `position: relative` effect
  but composited, better performance)

**First-principles derivation:**

Given constraint: some UI elements must overlay others
without affecting document flow, and some must remain
fixed while content scrolls. Normal flow can't satisfy
these requirements. A position property with explicit
coordinate systems is the minimal solution.

---

### 💻 Code Example

**BAD: absolute without positioned parent**

```css
/* BAD: .tooltip will position to viewport, not .card */
.card {
  /* no position set */
}

.tooltip {
  position: absolute;
  top: 0;
  right: 0;
  /* positions relative to viewport! */
}
```

> **Code walkthrough:** Without a positioned ancestor,
> the absolute element finds the initial containing block
> (essentially the viewport) as its reference. The tooltip
> will appear at the top-right of the screen, not the
> top-right of the card. This is the most common absolute
> positioning mistake.

**GOOD: relative parent + absolute child**

```css
/* GOOD: relative creates positioned ancestor */
.card {
  position: relative; /* creates containing block */
}

.badge {
  position: absolute;
  top: -8px;          /* 8px above card's top edge */
  right: -8px;        /* 8px right of card's right edge */
  /* correctly positioned relative to .card */
}

/* Pattern: overlay that fills the container */
.overlay {
  position: absolute;
  inset: 0;  /* shorthand for top:0; right:0; bottom:0; left:0 */
  background: rgba(0, 0, 0, 0.5);
}
```

> **Code walkthrough:** `position: relative` on `.card`
> makes it the containing block. The badge's `top: -8px;
> right: -8px` positions it relative to the card's border
> edge. The overlay uses `inset: 0` (the modern shorthand)
> to fill the container completely.

**PRODUCTION: sticky header with z-index stack**

```css
/* Sticky header that stays above scrolling content */
.site-header {
  position: sticky;
  top: 0;
  z-index: 100;   /* above page content */
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* Page content - no z-index needed (below 100) */
.page-content {
  padding-top: 1rem;
}

/* Modal overlay - above header */
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 200; /* above everything */
  background: rgba(0,0,0,0.5);
}
```

> **Code walkthrough:** A layered z-index strategy:
> page content at default (0), sticky header at 100,
> dropdowns/tooltips at 150, modal at 200. Documenting
> these as CSS custom properties (`--z-header: 100;
> --z-modal: 200;`) prevents magic numbers from proliferating.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CSS `position` has five values. `static` is the default
> - normal document flow. `relative` shifts an element from
> its normal position without affecting other elements.
> `absolute` removes from flow and positions relative to
> the nearest ancestor with a non-static position - if
> none exists, it goes to the viewport. `fixed` stays in
> the viewport even when scrolling. `sticky` acts like
> normal flow until it hits a scroll threshold, then sticks.
> The most important thing: when using `absolute`, always
> make sure a parent element has `position: relative` so
> you're positioning relative to that parent, not the
> viewport.

*Push deeper:* Discuss stacking contexts and when z-index
doesn't work as expected.

---

**Senior / Staff (5+ years):**

> Positioning in production is mainly about two things:
> containing blocks and stacking contexts.
>
> The containing block determines where absolute/fixed
> elements anchor. Any non-static positioned ancestor
> creates a containing block for absolute. For fixed,
> it's the viewport - EXCEPT when any ancestor has
> `transform`, `filter`, `will-change: transform`, or
> `contain: layout/paint` set, in which case that ancestor
> becomes the containing block. This is the most common
> cause of "my fixed element isn't sticking to the viewport."
>
> Stacking contexts control z-index ordering. z-index only
> works within the same stacking context. Setting `z-index:
> 9999` on a child element can't make it appear above an
> ancestor that has a lower z-index but is in a different
> stacking context. Elements with `position: relative/
> absolute/fixed/sticky + z-index`, `opacity < 1`,
> `transform`, `filter`, `will-change`, `isolation:
> isolate`, and others all create new stacking contexts.
> When z-index isn't working, the answer is almost always
> stacking contexts.

---

### ⚠️ Common Misconceptions

**"z-index controls the absolute stack order of all elements"**

z-index only applies within a stacking context. An element
in a child stacking context can't appear above a sibling
of its parent if that parent's z-index loses. The paint
order is determined by the stacking context tree.

**"sticky stops working at the bottom of the page"**

Sticky stops when its parent element's edge passes the
threshold. This is intentional - sticky is relative to
the parent scroll container, not the page. If sticky
stops early, the parent is too small or has overflow:hidden.

**"position:fixed always positions to the viewport"**

Not if any ancestor has `transform`, `filter`, or similar
properties. That ancestor becomes the containing block
instead of the viewport. This breaks modals and fixed
headers when placed inside animated containers.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: absolutely positioned element appears at
viewport top-left instead of inside parent**

Cause: no positioned ancestor.

Diagnosis:
```
# DevTools: select element > Computed tab
# "Offset parent" shows which element is the anchor
# If it shows "document" or "html" -> no positioned ancestor
```

Fix: add `position: relative` to the intended parent.

---

**Symptom: sticky element not sticking**

Cause: overflow on ancestor, parent too small, or missing
top/left value.

Diagnosis:
```
# Check: does .sticky element have top/bottom/left/right?
# Check: does any ancestor have overflow: hidden/auto/scroll?
# Check: is the parent tall enough to allow "sticking"?
# DevTools: scroll and watch if position changes in Layout tab
```

---

**Symptom: z-index not working**

Cause: element is in a stacking context with lower priority
than competing elements.

Diagnosis:
```
# Select element > Computed tab > z-index shows "auto"?
# Check parent chain for stacking context creators:
# position + z-index, opacity < 1, transform, filter,
# will-change, isolation: isolate
```

Fix: either place elements in the same stacking context,
or ensure the stacking context containing your element
has a higher z-index.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| "Position values" | 2-3 min | All 5 with differences |
| "Element positions wrong" | 3-4 min | Positioned ancestor |
| z-index not working | 3-4 min | Stacking context |
| sticky not working | 3 min | overflow + parent size |
| fixed inside transform | 3-4 min | Containing block |

---

**Q1: Explain the five CSS position values.** `[JUNIOR]`
CONCEPTUAL

*Why they ask:* Foundation of layout debugging.

*Likely follow-up:* "What is the default position value?"

> **Answer:**
>
> The five CSS position values each define a different
> coordinate system.
>
> `static` is the default. Elements follow normal document
> flow. `top`, `right`, `bottom`, `left` have no effect.
>
> `relative` keeps the element in normal flow (space is
> preserved) but allows offset using `top`/`left`/etc.
> The offset is from where the element would be in static
> flow. It also makes the element a containing block for
> absolute descendants.
>
> `absolute` removes the element from flow (no space
> reserved). It anchors to the nearest non-static ancestor.
> If no such ancestor exists, it anchors to the initial
> containing block (viewport edge for most cases).
>
> `fixed` removes from flow. Anchors to the viewport and
> stays there during scrolling. Exception: if an ancestor
> has `transform` or `filter` applied, fixed anchors to
> that ancestor instead.
>
> `sticky` is a hybrid. The element flows normally until
> it reaches a defined threshold (e.g., `top: 0`) during
> scroll, then "sticks" at that position until its parent
> container scrolls past.
>
> *What separates good from great:* The key distinction
> between relative and absolute for when to use each:
> `relative` when you need a small visual adjustment
> without disrupting flow (nudge an icon 1px), or to
> create an offset parent. `absolute` when the element
> should overlay other content without affecting layout.

---

**Q2: What causes z-index to not work?** `[SENIOR]`
DEBUGGING

*Why they ask:* The most common CSS positioning bug.

*Likely follow-up:* "What is a stacking context?"

> **Answer:**
>
> z-index only orders elements within the same stacking
> context. A stacking context is an independent z-axis
> layer. Elements in different stacking contexts are
> ordered by their stacking context's z-index, not their
> own. A child element can never appear above a sibling
> of its parent if its parent's stacking context has a
> lower z-index.
>
> Things that create a stacking context:
> - `position: relative/absolute/fixed/sticky` with any
>   `z-index` other than `auto`
> - `opacity` less than 1
> - `transform`, `filter`, `perspective`
> - `will-change: transform` (or other composited properties)
> - `isolation: isolate`
> - `mix-blend-mode` other than `normal`
>
> Diagnosis workflow:
> 1. Check if the element itself has z-index. Does it have
>    a non-static position? z-index requires positioning.
> 2. Walk up the ancestor chain. Find the first ancestor
>    with a stacking context. What's its z-index?
> 3. If that ancestor's stacking context is inside a lower
>    z-index context, no child z-index will help.
>
> Fix options: flatten the stacking context hierarchy,
> move the element to be a sibling in the correct stacking
> context, or add `isolation: isolate` to establish explicit
> stacking contexts for components.
>
> *What separates good from great:* `isolation: isolate`
> creates a stacking context without any visual side effects.
> Use it on modal backdrop containers to ensure modal content
> always appears above non-modal stacking contexts.

---

**Q3: How does position:sticky work and why does it
sometimes fail?** `[SENIOR]` DEBUGGING

*Why they ask:* Sticky has well-known failure modes that
are non-obvious.

*Likely follow-up:* "How do you fix sticky inside a grid?"

> **Answer:**
>
> `position: sticky` creates a hybrid: the element flows
> in normal flow, but when scrolling would move it past
> a threshold (`top: 0`, `top: 64px`, etc.), it "sticks"
> at that threshold. It unsticks when its parent element's
> bottom edge passes the threshold.
>
> Common failure modes:
>
> 1. Missing threshold: `position: sticky` has no effect
>    without at least one of `top`, `right`, `bottom`,
>    `left` set. This is the most common bug.
>
> 2. Ancestor has `overflow: hidden/auto/scroll`: sticky
>    only works relative to a scroll container. If an
>    ancestor intercepts scrolling with an overflow
>    setting, the sticky element sticks within that
>    container (which may not be visible), not the page.
>    Find the ancestor with overflow and remove it (or
>    use `overflow: clip` instead of `hidden` if clipping
>    is needed but not scroll containment).
>
> 3. Parent isn't tall enough: sticky sticks WITHIN its
>    parent. If the parent is the same height as the sticky
>    element, there's nothing to stick to.
>
> 4. Inside a grid/flex row: a grid item's containing
>    block is the grid, and sticky works within the grid
>    row's scrollport. Set `align-self: start` on the
>    sticky grid item - otherwise it stretches to fill
>    the row and has no room to stick.
>
> *What separates good from great:* `overflow: clip` was
> added to CSS to handle the case where you need clipping
> without creating a scroll container. Unlike
> `overflow: hidden`, `overflow: clip` does not create a
> block formatting context and does not intercept sticky
> positioning. It clips at the element edge without the
> scroll container side effect.

---

**Q4: How does fixed positioning break inside transforms?**
`[STAFF]` MECHANISM

*Why they ask:* Tests deep knowledge of containing blocks.

*Likely follow-up:* "How do you fix a modal inside an
animated container?"

> **Answer:**
>
> `position: fixed` is normally relative to the viewport.
> However, the CSS spec defines the containing block for
> fixed elements as the "initial containing block" (the
> viewport), UNLESS an ancestor has certain properties
> that create a new containing block:
>
> - `transform` other than `none`
> - `filter` other than `none`
> - `perspective` other than `none`
> - `will-change` with transform, filter, or perspective
> - `contain: layout`, `contain: paint`, or `contain: strict`
> - `backdrop-filter` other than `none`
>
> When any of these exist, the fixed element anchors to
> that ancestor, not the viewport. This means the element
> moves with the ancestor, making it no longer "fixed."
>
> This is a very common bug when adding CSS animations
> (`transform` is commonly used) or backdrop blur effects
> to a page. Any `transform` in the ancestor chain breaks
> fixed positioning.
>
> Solutions:
> 1. Move the fixed element outside the transformed
>    ancestor in the DOM (e.g., at the body level).
> 2. Use `translate` (the CSS property, not transform
>    function) - it has no effect on containing blocks.
> 3. For modals: use a Portal pattern (React `createPortal`)
>    to render at the document body root, outside any
>    transformed ancestor.
>
> *What separates good from great:* Knowing that `translate`,
> `scale`, and `rotate` as standalone CSS properties (added
> in CSS 2022) do NOT create new containing blocks, unlike
> `transform: translate()`. Using the standalone properties
> for animations preserves fixed positioning behavior.

---

**Q5: What is the difference between inset and top/right/
bottom/left?** `[MID]` MECHANISM

*Why they ask:* Tests familiarity with modern CSS shorthand.

*Likely follow-up:* "What does inset: 0 do?"

> **Answer:**
>
> `inset` is the shorthand for setting all four edge offsets
> at once: `top`, `right`, `bottom`, and `left`.
>
> `inset: 0` = `top: 0; right: 0; bottom: 0; left: 0`.
> Combined with `position: absolute`, this makes an element
> fill its containing block completely.
>
> `inset: 1rem` = 1rem on all four sides.
>
> `inset: 1rem 2rem` = 1rem top/bottom, 2rem left/right
> (same two-value shorthand as padding/margin).
>
> `inset: 0 0 auto 0` = fills width, auto height from top.
>
> The physical properties (`top`, `right`, `bottom`, `left`)
> are directional - always the same regardless of writing
> direction. The logical equivalents:
> - `inset-inline-start` = `left` (in LTR) or `right` (RTL)
> - `inset-inline-end` = `right` (LTR) or `left` (RTL)
> - `inset-block-start` = `top`
> - `inset-block-end` = `bottom`
>
> Using logical properties makes CSS work correctly in RTL
> languages (Arabic, Hebrew) without separate styles.
>
> *What separates good from great:* `inset: 0` fills the
> containing block only if the element is `position: absolute`
> or `fixed`. It's a common pattern for overlays, loading
> states, and image covers that fill their containers.

---

**Q6: When should you use position:absolute vs Flexbox/Grid
for layout?** `[MID]` TRADE-OFF

*Why they ask:* Tests layout architecture judgment.

*Likely follow-up:* "What are the accessibility implications
of using absolute positioning for layout?"

> **Answer:**
>
> The key distinction: use Flexbox/Grid for elements that
> participate in the flow (other elements should respond
> to their size), and use absolute positioning for elements
> that OVERLAY flow (overlapping tooltips, badges, overlays).
>
> Absolute positioning for layout (instead of Flex/Grid)
> has these costs:
>
> 1. Elements don't respond to content size. Fixed pixel
>    positions break when content grows.
>
> 2. Elements are removed from flow, so adjacent elements
>    don't account for them. A nav with absolute children
>    won't expand to contain them.
>
> 3. Accessibility: source order and visual order decouple.
>    Keyboard navigation follows DOM order; absolute
>    positioning can make visual order completely different.
>    Screen reader users and keyboard users experience
>    different orderings.
>
> 4. Responsive design is harder: absolute pixel positions
>    break at different viewport sizes.
>
> When absolute IS correct:
> - Badge on a card (overlapping, should not affect card height)
> - Tooltip (overlaying other content)
> - Dropdown menu (overlaying page content)
> - Loading overlay (covering the element below)
> - Absolutely-positioned decoration (not content)
>
> *What separates good from great:* The `order` property
> in Flexbox/Grid lets you change visual order without
> changing DOM order - so you can have a sidebar first
> in DOM (for keyboard/screen reader) but second visually.
> This is a better solution than absolute positioning for
> reordering content.

---

**Q7: How do you build a tooltip that positions above
an element?** `[MID]` HANDS-ON

*Why they ask:* Classic absolute positioning use case;
tests practical application.

*Likely follow-up:* "How do you keep the tooltip within
the viewport?"

> **Answer:**
>
> The pattern: position:relative parent, absolute tooltip.
>
> ```css
> .tooltip-wrapper {
>   position: relative;
>   display: inline-block;
> }
>
> .tooltip {
>   position: absolute;
>   bottom: calc(100% + 8px); /* above parent with gap */
>   left: 50%;
>   transform: translateX(-50%); /* center horizontally */
>   white-space: nowrap;
>   background: #1a1a1a;
>   color: white;
>   padding: 0.25rem 0.5rem;
>   border-radius: 4px;
>   font-size: 0.875rem;
>   pointer-events: none; /* don't trigger hover on tooltip */
>   z-index: 10;
>   /* hidden by default */
>   opacity: 0;
>   visibility: hidden;
>   transition: opacity 0.2s, visibility 0.2s;
> }
>
> .tooltip-wrapper:hover .tooltip,
> .tooltip-wrapper:focus-within .tooltip {
>   opacity: 1;
>   visibility: visible;
> }
> ```
>
> `bottom: calc(100% + 8px)` positions the tooltip's bottom
> edge above the parent's top edge with 8px gap. `left: 50%;
> transform: translateX(-50%)` centers it horizontally over
> the parent.
>
> To keep within viewport: use CSS Anchor Positioning (2024+)
> which has flip/auto-placement built in. Or use JavaScript
> (Floating UI, Popper.js) to calculate position accounting
> for viewport bounds.
>
> *What separates good from great:* Adding `role="tooltip"`
> and `aria-describedby` to the trigger - the tooltip should
> be accessible: `<button aria-describedby="my-tooltip">`.
> The tooltip text should be in the DOM and connected by ID,
> not just visually overlaid.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Walk through the stacking context algorithm |
| Hiring Manager | Frame as "layout bugs that ship to production" |
| Bar Raiser | Discuss CSS anchor positioning as the future approach |
| Peer Engineer | Share a z-index debugging story |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational keyword - position value comparisons
covered in Q1 and Q6 of Interview Deep-Dive)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational keyword - not architecture-level)*

---

### 📊 Diagram

*(Omit: code examples with inline comments are sufficient
for CSS positioning concepts)*

---
---

# CSS Float and Clear

🎯 **Interview Weight:** low-medium - floats are largely
replaced by Flexbox and Grid; still tested in legacy
codebases and to verify cascade/BFC knowledge

---

### 🎯 Model Answer

**30 seconds:**

> CSS `float` was the original layout mechanism - it
> moves an element to the left or right of its container,
> allowing text to flow around it. Today, floats are used
> almost exclusively for text wrapping around images;
> all other layout uses have been replaced by Flexbox
> and Grid. The key associated concept is `clear`, which
> prevents elements from flowing alongside floated
> elements, and the clearfix hack (now replaced by
> `display: flow-root`) which prevents container collapse
> when children are floated.

**3 minutes (Senior):**

> Float was introduced for the newspaper-style layout
> pattern: an image floated left with text flowing around
> it. It was then repurposed - badly - as a layout system
> for multi-column designs throughout the 2000s and 2010s,
> before Flexbox and Grid made it obsolete for that purpose.
>
> How float works: a floated element is removed from normal
> flow (other block elements flow under it as if it's not
> there) but inline content (text, inline-block elements)
> flows around the float's edge. This creates the text-wrap
> effect.
>
> The major problem: float breaks container height. A parent
> with only floated children has 0 height because floated
> children are removed from flow. The classic fix was the
> "clearfix" hack - adding a pseudo-element after floats:
> `.clearfix::after { content:""; display:table; clear:both }`.
> The modern fix is `display: flow-root` on the container,
> which creates a Block Formatting Context (BFC) that
> contains floats.
>
> `clear: left/right/both` prevents an element from flowing
> alongside floats. `clear: both` is the most common - it
> pushes the element below all floated siblings.
>
> Modern CSS: use float only for text wrapping around images
> (`float: left` on an `img` inside text). For all layout
> work, use Flexbox or Grid. The CSS `shape-outside` property
> extends float with custom shapes for text wrapping.

*Adapting up:* Discuss shape-outside for advanced text
wrapping, and the spec history of float as a layout
mechanism.

*Adapting down:* floats text-wrapping around images;
clear stops that wrapping; clearfix contains floated
children in a parent.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS float and clear -
let me walk through what floats do and when they're
appropriate today."

**(2) First principles:** "From first principles, print
layout has text wrapping around images. Float is CSS's
mechanism for this specific pattern."

**(3) Bridge:** "Think of a newspaper: the article photo
is 'floated' left and text flows around the right side.
CSS float does exactly that - and nothing more in modern CSS."

---

### 📘 Concept Explanation

**What it is:**

`float: left|right` moves an element to the left or right
of its container and allows inline content (text) to flow
around it. `clear: left|right|both` prevents an element
from flowing alongside floats.

**The problem it solves:**

Text wrapping around images - the newspaper layout pattern.
Historically also used for multi-column layouts (now
replaced by Flexbox/Grid).

**How it works:**

```
BEFORE FLOAT:
  +----+
  | p  | ← text flows under image in normal flow
  +----+

WITH float: left:
  +-----+ Text flows around
  | img |   the float to
  +-----+   the right side.
  More text continues below
  the float when it runs out.

clear: both:
  (ensures next element is below all floats)

CONTAINER COLLAPSE:
  Parent div
    [floated child]  <- 0 height contribution
  div height = 0 (collapses!)

FIX: display: flow-root on parent (BFC)
  Parent div (BFC)
    [floated child]  <- contained
  div height = float height ✓
```

**The key insight:**

The only modern use case for `float` is text wrapping
around images. Everything else that float was historically
used for (multi-column layout, sidebar layout, equal-height
columns) is better done with Flexbox or Grid.

**When to use it:**

Only for inline text flowing around images. Use `float:
left` on an image inside a text paragraph. This is still
the correct CSS for that pattern.

**When NOT to use it:**

Never use float for page layout, multi-column design,
card grids, or navigation. These should use Flexbox or
Grid. Float layout code in modern projects is a maintenance
red flag.

**Alternatives:**

- Flexbox: for 1D layout (single row or column)
- Grid: for 2D layout
- CSS Multi-column (`column-count`): for newspaper-style
  multi-column text flow
- CSS `shape-outside`: float with a custom shape

**First-principles derivation:**

Float existed to enable the print-design pattern of text
wrapping around images. When the web grew to require
arbitrary layouts, float was repurposed beyond its design
intent, producing fragile layout hacks. Flexbox and Grid
were designed specifically for layout, solving all the
problems float layout had.

---

### 💻 Code Example

**BAD: float used for layout (legacy pattern)**

```css
/* BAD: float-based two-column layout */
.sidebar {
  float: left;
  width: 250px;
}
.main-content {
  float: left;
  width: calc(100% - 250px);
}
.container::after {
  content: "";
  display: table;
  clear: both;
} /* clearfix hack required */
```

> **Code walkthrough:** Float-based layout requires the
> clearfix hack on the container (or it collapses to 0
> height), requires matching widths that must add up to
> 100%, breaks on mobile, and doesn't support equal
> heights. This is the pattern that Flexbox replaced.

**GOOD: float's only modern use case - text wrapping**

```css
/* GOOD: text wrapping around image - float's purpose */
.article-image {
  float: left;
  margin: 0 1rem 1rem 0; /* breathing room */
  max-width: 40%;        /* limit image size */
}

/* Stop wrapping after the image */
.next-section {
  clear: both; /* ensures this starts below float */
}
```

> **Code walkthrough:** Text wrapping around an image is
> the only remaining valid use of float. The image floats
> left, text flows around it to the right, and the next
> section uses `clear: both` to ensure it starts below
> the float. This is the newspaper layout pattern that
> float was designed for.

**PRODUCTION: shape-outside for creative text wrapping**

```css
/* Advanced: text wraps around a circular image */
.author-photo {
  float: left;
  width: 150px;
  height: 150px;
  border-radius: 50%;
  margin: 0 1rem 1rem 0;
  /* Text wraps in a circular path */
  shape-outside: circle(50%);
  shape-margin: 0.5rem;
}
```

> **Code walkthrough:** `shape-outside` extends float
> to allow text wrapping around non-rectangular shapes.
> `circle(50%)` makes text flow in a circular path around
> the image. `shape-margin` adds a gap between the shape
> and the text. The element still needs to be floated for
> `shape-outside` to take effect - it only modifies
> the float's text-wrapping behavior.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `float` moves an element left or right within its
> container and lets text flow around it - it was designed
> for the newspaper-image pattern. For modern layout
> (sidebars, columns, grids), use Flexbox or Grid instead.
> The associated `clear` property stops elements from
> flowing alongside floats - `clear: both` ensures an
> element appears below all floated elements. If you
> have a container with all floated children, it will
> collapse to 0 height; add `display: flow-root` to
> the container to fix that (or the older clearfix hack).

*Push deeper:* Ask about the difference between `display:
flow-root` and the clearfix hack.

---

**Senior / Staff (5+ years):**

> Float today is a single-purpose tool: text wrapping
> around inline images. Anything else is legacy code.
> The important concept associated with float is BFC
> creation: floated elements are removed from normal
> flow, which causes parent containers to collapse.
> `display: flow-root` on the container creates a BFC
> that contains floats - the modern, clean solution.
> `overflow: hidden` worked as a BFC trigger too but
> clips content; `flow-root` was introduced to fix this.
>
> `shape-outside` is the one modern extension to float
> worth knowing: it allows text to wrap around custom
> shapes (circle, polygon, path) rather than the
> float's rectangular bounding box. Useful for editorial
> design in CSS.
>
> In legacy codebases, float layout is common and often
> fragile. Migrating it to Flexbox or Grid is usually
> the right refactor for maintainability.

---

### ⚠️ Common Misconceptions

**"You need a clearfix div after floated elements"**

Modern fix: `display: flow-root` on the parent. The `<div
class="clearfix">` or CSS pseudo-element hack is obsolete.

**"Float was designed for layout"**

Float was designed for text wrapping around images. Its
use as a layout tool was a community hack that worked
but had many limitations. Flexbox and Grid are what
layout tools look like when designed for that purpose.

**"clear: both removes the float"**

`clear: both` on an element makes it start below all
floats. It doesn't remove the float from the element
it's applied to. `float: none` removes the float.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: parent container collapses (0 height)**

Cause: all children are floated, so normal flow has
nothing to size the parent.

Diagnosis:
```
# DevTools: select parent element
# Height shows 0 in Layout tab
# Children visible but outside parent in box model
```

Fix: `display: flow-root` on the parent. Or if keeping
legacy: clearfix pseudo-element.

---

**Symptom: text not wrapping around float**

Cause: text is in a block element that has established
a BFC (overflow: hidden/auto, display: flow-root).

Diagnosis: check if the text container has overflow set.

Fix: remove the overflow/BFC from the text container,
or use `display: flow-root` only on the outer container.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| "What is CSS float?" | 2 min | Text wrapping + legacy history |
| Container collapse | 3 min | BFC + display:flow-root |
| "When do you use float today?" | 2 min | Only text wrapping |
| clearfix vs flow-root | 3 min | Modern vs legacy |
| shape-outside | 3 min | Modern float extension |

---

**Q1: What does CSS float do and when do you use it today?**
`[JUNIOR]` CONCEPTUAL

*Why they ask:* Tests whether candidate knows modern vs
legacy CSS approaches.

*Likely follow-up:* "What replaced float for layout?"

> **Answer:**
>
> `float: left` or `float: right` moves an element out
> of normal block flow and positions it to the left or
> right of its container. Inline content (text) flows
> around the floated element.
>
> Its original purpose: text wrapping around images, the
> newspaper layout pattern. A floated image with text
> flowing around it is still the correct modern use.
>
> What it was incorrectly used for: before 2012 (Flexbox
> era), float was the only reliable cross-browser multi-
> column layout tool. `float: left` on every column, with
> widths adding to 100%, created grid-like layouts.
> These required clearfix hacks and were fragile.
>
> Today: use float only for text-wrapping. For all layout:
> use `display: flex` (1D layout), `display: grid` (2D
> layout), or CSS `columns` (newspaper-style text columns).
>
> If you're maintaining legacy code with float layouts,
> that's a technical debt item. The migration to Flexbox
> or Grid is usually straightforward and improves both
> code quality and layout robustness.
>
> *What separates good from great:* Knowing `shape-outside`
> - it extends float to allow text wrapping around custom
> shapes (circles, polygons). It only works on floated
> elements, so float is still the mechanism, but the
> text path can be custom-shaped.

---

**Q2: Why does a container collapse when all children
are floated?** `[MID]` MECHANISM

*Why they ask:* BFC and float containment is frequently
misunderstood.

*Likely follow-up:* "How do you fix it without overflow:hidden?"

> **Answer:**
>
> When you float an element, it's removed from normal flow.
> A parent element's height is calculated from its non-floated
> children in normal flow. If ALL children are floated, there
> are no children in normal flow, and the parent height
> computes to 0.
>
> The parent visually collapses - it appears to have no
> height, even though the floated children are visible
> because they extend beyond the parent's boundary.
>
> Two solutions:
>
> 1. Old: clearfix hack. Add a pseudo-element as the last
>    child of the parent:
>    `.parent::after { content: ""; display: table; clear: both; }`
>    This inserts an invisible non-floated element at the end,
>    forcing the parent to be tall enough to contain it
>    (which `clear: both` forces to be below all floats).
>
> 2. Modern: `display: flow-root` on the parent. This creates
>    a Block Formatting Context (BFC). Elements inside a BFC
>    are contained within it, including floats. The parent
>    now extends to contain all floated children. No pseudo-
>    element needed, no `overflow` side effects.
>
> *What separates good from great:* Understanding WHY
> `display: flow-root` works: a BFC's height is computed
> to include all content within it, including floats. Normal
> flow doesn't include floats in height calculation; a BFC
> does. `overflow: hidden/auto/scroll` also creates a BFC
> (which is why it "worked" as a clearfix) but has the
> side effect of actually clipping or scrolling content.
> `flow-root` creates the BFC without those side effects.

---

**Q3: What is the difference between clearfix and
display:flow-root?** `[MID]` COMPARISON

*Why they ask:* Tests knowledge of BFC mechanics and
CSS evolution.

*Likely follow-up:* "What other properties create a BFC?"

> **Answer:**
>
> Both solve the same problem - containing floated children -
> but via different mechanisms.
>
> Clearfix uses a CSS pseudo-element injected as the last
> child with `clear: both`. The container's height expands
> to include this pseudo-element, which sits below all floats
> because of `clear: both`. It's a workaround that tricks
> the height calculation.
>
> `display: flow-root` creates a new Block Formatting Context
> (BFC). A BFC's height calculation includes floated
> children. No pseudo-element needed - the BFC property
> itself changes how height is computed for the container.
>
> `display: flow-root` is strictly better:
> - No extra CSS rules (just one property)
> - No pseudo-element in the document
> - No side effects (unlike `overflow: hidden` which
>   also creates a BFC but clips content)
> - Clearly communicates intent: "this is a BFC container"
>
> The clearfix hack predates `display: flow-root` (which
> was only added to CSS in 2017). Legacy codebases use
> clearfix; new code should use `display: flow-root`.
>
> Other BFC creators: `overflow: hidden/auto/scroll`,
> `display: flex/grid/inline-block`, `position: absolute/
> fixed`, `float: left/right`, `contain: layout`.
>
> *What separates good from great:* `display: flow-root`
> exists specifically because `overflow: hidden` was being
> misused as a clearfix, creating unintended clipping
> side effects. The CSS working group added `flow-root`
> as the semantic, side-effect-free BFC creator.

---

**Q4: What is shape-outside and what does it enable?**
`[SENIOR]` MECHANISM

*Why they ask:* Tests knowledge of modern CSS float extension.

*Likely follow-up:* "What shapes does shape-outside support?"

> **Answer:**
>
> `shape-outside` defines the shape that inline content
> flows around when wrapping a floated element. Without it,
> text wraps around the float's rectangular bounding box.
> With `shape-outside`, text can wrap around circles,
> ellipses, polygons, or even image transparency.
>
> Key requirement: the element must be floated. `shape-
> outside` only affects float wrapping behavior - it has
> no effect without `float: left` or `float: right`.
>
> Available shapes:
> - `circle(50%)` - circular wrapping
> - `ellipse(100px 50px at 50% 50%)` - elliptical wrapping
> - `polygon(0 0, 100% 0, 100% 100%)` - arbitrary polygon
> - `url(image.png)` - wrap around image alpha channel
>   (transparent areas allow text intrusion)
> - `inset(0 0 0 0 round 10px)` - rectangular with rounded
>   corners
>
> `shape-margin` adds spacing between the shape boundary
> and the text.
>
> Use case: editorial CSS design - text flowing around
> a circular author photo, around a diagonal graphic,
> or through the transparent parts of a complex image.
>
> *What separates good from great:* The shape can be
> animated. `shape-outside: polygon(...)` with a CSS
> transition or animation creates moving text wrap paths.
> This is a very advanced but powerful editorial effect
> that's impossible without `shape-outside`.

---

**Q5: A page has an old float layout. It breaks on
mobile. How do you migrate it?** `[SENIOR]` PRODUCTION

*Why they ask:* Practical CSS migration skill.

*Likely follow-up:* "What do you check first before
changing layout code?"

> **Answer:**
>
> Migration approach: audit, understand intent, refactor.
>
> Step 1: Audit the existing layout. Screenshot the
> desktop layout. Note how many columns, what sizes,
> how they respond (do they stack? overlap?). Understand
> the intended layout before touching code.
>
> Step 2: Check for clearfix patterns. They indicate which
> elements were float-layout containers. Replace clearfix
> pseudo-elements with `display: flex` or `display: grid`
> on those containers.
>
> Step 3: Replace the float columns with flex:
> Old: `div { float: left; width: 33.33%; }`
> New: `parent { display: flex; gap: 1rem; }
>       div { flex: 1; min-width: 200px; }`
>
> Step 4: Add responsive behavior. Flex wraps naturally
> with `flex-wrap: wrap`. Grid can use auto-fill:
> `grid-template-columns: repeat(auto-fill, minmax(200px, 1fr))`
>
> Step 5: Remove all float-related CSS (`float: left/right`,
> `clear: both`, clearfix pseudo-elements) from elements
> that are now flex/grid items.
>
> Step 6: Test - verify no remaining float layout is
> present. The remaining float usage should only be on
> `img` elements inside text content.
>
> *What separates good from great:* Running automated
> visual regression tests before and after the migration.
> Float migration can change subtle spacing. Screenshots
> at multiple viewports compared automatically catch
> regressions faster than manual testing.

---

**Q6: What does clear:both do?** `[JUNIOR]` MECHANISM

*Why they ask:* Associated concept with float.

*Likely follow-up:* "What is the difference between clear:left,
clear:right, and clear:both?"

> **Answer:**
>
> `clear` prevents an element from flowing alongside a floated
> element. It forces the element to start below floats.
>
> `clear: left` - element starts below any left-floated
> elements above it in the DOM.
>
> `clear: right` - element starts below any right-floated
> elements above it.
>
> `clear: both` - element starts below ALL floated elements
> (both left and right floats). This is the most common value.
>
> `clear: none` - default, element flows normally regardless
> of floats.
>
> The visual effect: an element with `clear: both` is pushed
> down until there's no float to its left OR right. This is
> what `clearfix` exploits: the pseudo-element with
> `clear: both` is forced below all floats, expanding the
> parent container.
>
> Practical modern use of `clear`: ending a text-wrapping
> section. After a floated image and its surrounding text,
> the next section should use `clear: both` to start
> cleanly below both the float and its wrapped text.
>
> *What separates good from great:* Knowing that `clear`
> only affects block-level elements. It has no effect on
> inline or inline-block elements. An inline `span` with
> `clear: both` won't be cleared. Also: `clear` only
> affects floats in the same block formatting context.

---

**Q7: How would you make text wrap around a circular
image?** `[SENIOR]` HANDS-ON

*Why they ask:* Tests both float and shape-outside knowledge.

*Likely follow-up:* "What happens without shape-outside?"

> **Answer:**
>
> Without `shape-outside`, text wraps around the image's
> rectangular bounding box even if the image is circular.
> The text stays outside the square, leaving white space
> in the corners.
>
> With `shape-outside`:
>
> ```css
> .author-photo {
>   float: left;
>   width: 160px;
>   height: 160px;
>   border-radius: 50%;
>   /* Tell text to wrap around the circle */
>   shape-outside: circle(50%);
>   shape-margin: 12px;
>   margin: 0 16px 16px 0;
> }
> ```
>
> `shape-outside: circle(50%)` defines the wrap boundary
> as a circle at the center with radius 50% (80px for
> a 160px element). Text flows around this circular path
> instead of the rectangular box.
>
> `shape-margin: 12px` adds 12px of breathing room between
> the circular boundary and the text.
>
> The `border-radius: 50%` makes the image visually circular.
> The `shape-outside: circle(50%)` makes the text wrap
> circularly. Both are needed - the image display and the
> text wrap shape are independent.
>
> *What separates good from great:* Using `url(image.png)`
> as the shape reference: `shape-outside: url(photo.png)`
> makes text flow around the non-transparent parts of the
> image. This works with PNG or WebP images with alpha
> transparency, enabling complex shaped text wrapping for
> editorial layouts.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | BFC mechanics + display:flow-root vs clearfix |
| Hiring Manager | Frame as legacy migration knowledge |
| Bar Raiser | Discuss shape-outside as modern float use |
| Peer Engineer | Talk about migrating a float layout to Flex/Grid |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational keyword - float vs modern layout
alternatives covered in Concept Explanation and Q5 Deep-Dive)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational keyword - not architecture-level)*

---

### 📊 Diagram

*(Omit: the code examples with inline comments are sufficient
for understanding CSS float behavior)*
