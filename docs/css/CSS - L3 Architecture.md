---
layout: default
title: "CSS - L3 Architecture"
parent: "CSS"
nav_order: 8
permalink: /css/l3-architecture/
render_with_liquid: false
---

# CSS Methodologies (BEM, SMACSS, OOCSS)

🎯 **Interview Weight:** high - CSS architecture is tested
in senior frontend roles; BEM is nearly universal in
component-based teams; understanding the trade-offs between
methodologies signals maturity

---

### 🎯 Model Answer

**30 seconds:**

> CSS methodologies solve the global scope problem - any CSS
> class can accidentally affect any element. BEM (Block,
> Element, Modifier) prevents this with naming conventions:
> `.block__element--modifier`. SMACSS categorizes rules into
> Base, Layout, Module, State, Theme layers. OOCSS separates
> structure from skin and container from content. All three
> address the same problem: CSS specificity conflicts and
> unintended style leakage in large codebases.

**3 minutes (Senior):**

> BEM is the most widely adopted. Its three-level naming
> creates self-contained components: `.card` (Block),
> `.card__title` (Element - a child of the block),
> `.card--featured` (Modifier - a variant). The double-
> underscore and double-hyphen are deliberate: they're
> unlikely to appear in natural English names, making
> BEM classes visually scannable.
>
> The BEM rule: elements only belong to their block, never
> to another element. `.card__title__icon` is invalid.
> Instead: `.card__icon` (icon is a card element) or a
> separate nested block.
>
> OOCSS (Nicole Sullivan) introduced two principles that
> now permeate all methodology: separate structure (layout,
> sizing) from skin (colors, backgrounds), and separate
> container from content (a heading shouldn't have different
> styles because it's inside a specific container).
>
> SMACSS (Jonathan Snook) provides a categorization layer:
> Base rules are element selectors (body, p), Layout rules
> position major sections (header, sidebar), Module rules
> are reusable components (cards, buttons), State rules
> describe component states (`.is-active`, `.is-hidden`),
> Theme rules are cosmetic overrides.
>
> In practice: most teams use BEM for component naming +
> SMACSS-inspired layer organization + OOCSS principles
> as the underlying philosophy.

*Adapting up:* Discuss CSS Modules and Scoped CSS as the
evolution beyond naming conventions - enforced by tooling
rather than discipline.

*Adapting down:* BEM is a naming convention: `.block__element
--modifier`. It prevents naming conflicts in large teams.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS methodologies -
why they exist and how BEM, SMACSS, and OOCSS work."

**(2) First principles:** "From first principles, CSS has
global scope. Any class can accidentally apply anywhere.
Methodologies solve this through naming conventions and
organization rules."

**(3) Bridge:** "Think of BEM like Java package naming.
`com.company.module.Class` prevents conflicts. `.block__
element--modifier` does the same for CSS classes."

---

### 📘 Concept Explanation

**What it is:**

CSS naming and organization conventions that prevent style
conflicts, improve readability, and scale across large teams.
The three major methodologies: BEM (Block Element Modifier),
SMACSS (Scalable and Modular Architecture for CSS), OOCSS
(Object-Oriented CSS).

**The problem it solves:**

CSS's global scope means `.button` in one file can conflict
with `.button` in another. Specificity wars emerge when
developers keep increasing specificity to override each
other. Methodologies provide rules that prevent these
conflicts without tooling.

**How it works:**

```
BEM NAMING CONVENTION:
  Block: standalone component
    .card {}
    .nav {}
    .hero {}

  Element: child of block (double underscore)
    .card__title {}
    .card__image {}
    .nav__item {}

  Modifier: variant/state (double hyphen)
    .card--featured {}
    .card--compact {}
    .nav__item--active {}

  Rules:
    - Elements only belong to their block
    - .card__title__icon INVALID
    - .card__icon VALID (icon is a card-level element)
    - Never mix block + element selector chains

SMACSS LAYERS:
  Base:   html, body, p, a { }
          Element selectors only, no classes
  Layout: .l-header, .l-sidebar
          Major page sections (l- prefix optional)
  Module: .card, .nav, .button
          Reusable UI components
  State:  .is-active, .is-hidden, .is-loading
          Applied with JavaScript
  Theme:  .theme-dark .button { }
          Cosmetic overrides, usually optional

OOCSS PRINCIPLES:
  1. Separate structure from skin:
     /* BAD: combines structure and skin */
     .card { display: flex; padding: 1rem;
             background: white; border-radius: 4px; }
     /* GOOD: split */
     .box { display: flex; padding: 1rem; }    /* structure */
     .surface { background: white; border-radius: 4px; } /* skin */

  2. Separate container from content:
     /* BAD: content styled based on container */
     .sidebar h2 { color: gray; font-size: 0.9em; }
     /* GOOD: class on the heading itself */
     .sidebar-heading { color: gray; font-size: 0.9em; }
```

**The key insight:**

BEM's double-underscore syntax creates a visual hierarchy
that maps to the DOM structure WITHOUT using CSS nesting
(which increases specificity). `.card__title` has specificity
(0,1,0) - same as `.card`. No specificity wars because every
class is at the same specificity level.

**When to use it:**

BEM: component-based projects, multi-developer teams,
when no CSS scoping tooling is available.

SMACSS: organizing large stylesheets into logical layers.

OOCSS: guiding principles for writing reusable utility
patterns.

**When NOT to use it:**

When CSS Modules or CSS-in-JS provides scoping automatically.
When using Tailwind (utility-first replaces BEM naming).
For small solo projects (overhead outweighs benefit).

**Alternatives:**

- CSS Modules: build-tool-enforced scoping
- CSS-in-JS: JavaScript-controlled scoped CSS
- Utility-first (Tailwind): no component class names
- CSS `@scope` (emerging): native CSS scoping

**First-principles derivation:**

CSS is globally scoped by design. The cascade was built for
documents, not component libraries. Methodologies impose
constraints on naming to simulate scoping without browser
enforcement. They require team discipline. Tool-based
solutions (CSS Modules) enforce the same constraints
automatically.

---

### 💻 Code Example

**BAD: flat CSS without methodology**

```css
/* BAD: naming conflicts across components */
/* card.css */
.title { font-size: 1.25rem; }
.image { border-radius: 4px; }
.meta  { color: gray; font-size: 0.875rem; }

/* blog-post.css */
.title { font-size: 2rem; } /* conflicts with card.css! */
/* Which .title applies where? Depends on load order */
```

> **Code walkthrough:** Generic class names (`.title`,
> `.image`) conflict when multiple components are loaded.
> The last stylesheet wins for same-specificity selectors.
> This is how CSS becomes unmaintainable: each developer
> adds more specific selectors to win conflicts, creating
> a specificity arms race.

**GOOD: BEM naming prevents conflicts**

```css
/* card.css - BEM naming */
.card {}
.card__title { font-size: 1.25rem; }
.card__image { border-radius: 4px; }
.card__meta  { color: gray; font-size: 0.875rem; }
.card--featured { border: 2px solid gold; }

/* blog-post.css - BEM naming */
.post {}
.post__title  { font-size: 2rem; }
.post__image  { width: 100%; height: auto; }
/* Zero conflicts - namespaced to their block */
```

> **Code walkthrough:** `.card__title` and `.post__title`
> are different selectors. They cannot conflict even if
> both elements exist on the same page. The block name
> acts as a namespace. Every class has the same specificity
> (0,1,0), so no specificity wars.

**PRODUCTION: BEM + SMACSS combined**

```css
/* Base layer */
*, *::before, *::after { box-sizing: border-box; }
body { font-family: system-ui, sans-serif; }

/* Layout layer */
.l-page {
  display: grid;
  grid-template-columns: 240px 1fr;
  min-height: 100vh;
}
.l-header { grid-column: 1 / -1; }
.l-sidebar {}
.l-main   {}

/* Module layer: BEM components */
.card {}
.card__header { padding: 1rem; border-bottom: 1px solid; }
.card__body   { padding: 1rem; }
.card--elevated { box-shadow: 0 4px 16px rgba(0,0,0,0.1); }

/* State layer */
.is-hidden  { display: none !important; }
.is-loading { opacity: 0.6; pointer-events: none; }
.is-active  { } /* defined per component */

/* .is-active .card { border-color: blue } */
/* SMACSS: state + module = contextual override */
```

> **Code walkthrough:** SMACSS layer separation means you
> know WHERE to find any rule. Layout rules are all in one
> section. Component (Module) rules use BEM naming. State
> rules are toggled by JavaScript class manipulation.
> The `!important` on `.is-hidden` is the ONE legitimate
> global `!important` - a state that must always win.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> BEM is a CSS naming convention to prevent conflicts. Block
> is the component (`.card`), element is a child of the block
> (`.card__title` with double underscore), modifier is a
> variant (`.card--dark` with double hyphen). The naming
> prevents two `.title` classes from conflicting because
> they become `.card__title` and `.post__title`. I use BEM
> when building components without CSS Modules available.

---

**Senior / Staff (5+ years):**

> Methodologies solve the global scope problem without
> tooling. BEM's value is the visual hierarchy - you can
> understand component structure from class names alone.
> The strict flat specificity (every BEM class is 0,1,0)
> prevents specificity wars.
>
> In practice, I use BEM for component naming within
> SMACSS-organized layers when CSS Modules aren't available.
> When CSS Modules or CSS-in-JS is available, methodology
> discipline is replaced by tooling enforcement - which is
> strictly better.
>
> BEM's main limitation: verbose class names in HTML
> (`.site-header__navigation__item--active`). This is why
> tooling-based approaches (Modules, styled-components)
> have largely replaced BEM in modern React ecosystems.

---

### ⚠️ Common Misconceptions

**"BEM elements can be nested: .block__element__sub-element"**

No. `.card__title__icon` is invalid BEM. Icons inside card
titles are either `.card__icon` (a block-level element) or
a nested block: `.icon` inside `.card__title`.

**"Modifiers replace the base block class in HTML"**

`<div class="card--featured">` is wrong. Both classes
must be present: `<div class="card card--featured">`.
The modifier ADDS properties; the block provides base styles.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: BEM nesting in HTML exceeds 3+ levels**

`card__header__nav__item__link__icon` - BEM has gone too deep.

Cause: the component's DOM structure is too deeply nested
to represent at block level.

Fix: break into sub-components. The `.nav` inside `.card__header`
should be its own `.nav` block with `.nav__item` elements.

---

**Symptom: specificity conflict despite using BEM**

Cause: BEM classes mixed with element/ID selectors.

```css
/* VIOLATES BEM: adds element selector specificity */
article.card { } /* specificity: 0,1,1 - breaks BEM */
```

Fix: only use classes in BEM selectors. Never combine
with element or ID selectors.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Explain BEM naming | 3 min | Block/Element/Modifier |
| Why BEM uses double __ and -- | 2-3 min | Collision avoidance |
| BEM element nesting rules | 3 min | Flat elements, no nesting |
| SMACSS layers | 3-4 min | 5-layer categorization |
| OOCSS principles | 3 min | Structure vs skin |
| BEM vs CSS Modules | 3-4 min | Convention vs tooling |
| When not to use BEM | 3 min | Tailwind, CSS-in-JS |
| State classes in BEM | 2-3 min | .is- prefix, SMACSS |
| BEM in team practice | 3-4 min | Consistency, linting |

---

**Q1: What problem do CSS methodologies solve?** `[MID]`
CONCEPTUAL

*Why they ask:* Tests understanding of the CSS global scope
problem.

*Likely follow-up:* "What would happen without any methodology
in a large codebase?"

> **Answer:**
>
> CSS is globally scoped. Every class name you write is
> globally visible - there is no encapsulation. `.button`
> in one file is the same selector as `.button` in another.
> In a large team with many files, name collisions are
> inevitable.
>
> The consequences:
> 1. Name conflicts: two developers write `.header`, each
>    expecting different styles. The last one loaded wins.
>
> 2. Specificity creep: to override another developer's
>    styles, you increase specificity. Over time:
>    `div.container .section .card .title { }` - high
>    specificity that's impossible to override without
>    even higher specificity.
>
> 3. Fear of deleting: nobody knows if a class is still
>    used. Removing `.special-title` might break an
>    unknown component. Dead CSS accumulates.
>
> 4. Unpredictable side effects: changing `.link` to fix
>    one component accidentally breaks links in another
>    component that shares the class.
>
> CSS methodologies solve this through NAMING CONVENTIONS
> that create de-facto namespacing. BEM's `.card__title`
> is clearly only for titles inside cards. SMACSS's
> `.is-active` is clearly a state class. The problem
> isn't solved at the browser level (it's still global
> CSS), but human-readable structure prevents accidental
> conflicts.
>
> *What separates good from great:* The only true solution
> to CSS global scope is tooling: CSS Modules, styled-
> components, CSS-in-JS. These generate unique class names
> at build time or runtime, making conflicts technically
> impossible. Methodologies require discipline; tooling
> enforces it. Methodologies are valuable when tooling
> isn't available or when working with legacy codebases.

---

**Q2: Explain BEM naming with an example.** `[JUNIOR]`
MECHANISM

*Why they ask:* BEM is nearly universal in frontend teams.

*Likely follow-up:* "Can an element also be a block?"

> **Answer:**
>
> BEM: Block, Element, Modifier. Three levels of component
> naming.
>
> **Block**: a standalone, reusable UI component.
> `.card`, `.nav`, `.button`, `.hero`
>
> **Element**: a child part of a block. Uses `__` (double
> underscore) separator. Can only belong to its block.
> `.card__title`, `.card__image`, `.card__actions`
> `.nav__item`, `.nav__link`
>
> **Modifier**: a variant or state of a block or element.
> Uses `--` (double hyphen) separator.
> `.card--compact`, `.card--featured`
> `.button--primary`, `.button--disabled`
> `.nav__item--active`
>
> Example markup:
> ```html
> <article class="card card--featured">
>   <img class="card__image" src="..." alt="">
>   <div class="card__body">
>     <h2 class="card__title">Title</h2>
>     <p class="card__description">...</p>
>   </div>
>   <div class="card__footer">
>     <button class="button button--primary">
>       Read More
>     </button>
>   </div>
> </article>
> ```
>
> Note: `.button` inside `.card__footer` is NOT `.card__
> footer__button`. The button is a SEPARATE block (`button`)
> that happens to be inside a card. Blocks can be nested.
>
> Can an element also be a block? Yes. In the example, the
> `.button` block lives inside the `.card` block. The button
> is its own block with its own elements (`.button__icon`).
>
> *What separates good from great:* The `.card__footer`
> contains a `.button` block. Don't write `.card__button`
> to style the button inside the card - that violates
> block encapsulation. If the button needs card-specific
> styling, use: `.card .button { }` (a contextual override
> - this is allowed as a last resort but goes against
> OOCSS's "separate container from content" principle).

---

**Q3: When would you choose CSS Modules over BEM?**
`[SENIOR]` TRADE-OFF

*Why they ask:* Architecture decision for real projects.

*Likely follow-up:* "Can you use both in the same project?"

> **Answer:**
>
> BEM: a naming convention enforced by team discipline. It
> works in any environment (plain CSS, preprocessors) but
> requires every developer to follow the rules consistently.
>
> CSS Modules: a build-tool feature (webpack, Vite, etc.)
> that locally scopes class names by transforming them.
> `.card__title` in `Card.module.css` becomes
> `Card_card__title_hash123` in the output. The scoping
> is enforced by tooling, not convention.
>
> When CSS Modules is better:
>
> 1. Component-based frameworks (React, Vue, Svelte):
>    CSS Modules integrates naturally - each component
>    file has its own CSS file. No global pollution.
>
> 2. Large teams: you can't trust everyone to follow BEM.
>    Modules enforce scoping automatically.
>
> 3. When you want short, readable class names:
>    `.title` locally means exactly the title in THAT
>    component, not globally.
>
> 4. When you want dead code elimination: unused CSS
>    Module classes can be tree-shaken.
>
> BEM is still useful when:
>
> 1. No build tool: plain HTML/CSS projects
> 2. Shared CSS (for components consumed by plain HTML)
> 3. Design system tokens (global classes)
> 4. When CSS Modules are not available (legacy CMS)
>
> Can you use both: yes. Use BEM naming conventions WITHIN
> CSS Modules files for readability, even though scoping
> is handled by the module system.
>
> *What separates good from great:* CSS Modules' `:global()`
> and `:local()` escape hatches allow mixing scoped and
> global CSS in the same file. `:global(.is-active)` creates
> a global class that SMACSS-style state classes need.
> This makes CSS Modules + SMACSS state classes a practical
> combination.

---

**Q4: What are the OOCSS principles?** `[SENIOR]`
MECHANISM

*Why they ask:* OOCSS principles underlie all methodologies
and Tailwind.

*Likely follow-up:* "How does Tailwind relate to OOCSS?"

> **Answer:**
>
> OOCSS (Nicole Sullivan, 2008) has two core principles:
>
> **Principle 1: Separate Structure from Skin**
>
> Structure: dimensions, layout, positioning (display,
> position, width, height, margin, padding, overflow)
>
> Skin: visual design (color, background, border, shadow,
> font)
>
> ```css
> /* BAD: monolithic class */
> .promo-box {
>   display: flex;        /* structure */
>   padding: 1rem;        /* structure */
>   background: #2563eb;  /* skin */
>   color: white;         /* skin */
>   border-radius: 4px;   /* skin */
>   box-shadow: ...;      /* skin */
> }
>
> /* GOOD: separate structure and skin */
> .media-box {
>   display: flex;
>   padding: 1rem;
> }
> .brand-skin {
>   background: #2563eb;
>   color: white;
>   border-radius: 4px;
> }
> ```
>
> Structure classes can be reused across different visual
> styles. Skin classes can apply to different structures.
>
> **Principle 2: Separate Container from Content**
>
> Content shouldn't have different styles based on
> where it is in the page.
>
> ```css
> /* BAD: heading styled based on container */
> .sidebar h2 { font-size: 1rem; color: gray; }
> .footer h2  { font-size: 0.875rem; color: white; }
>
> /* GOOD: classes on the content itself */
> .sidebar-heading { font-size: 1rem; color: gray; }
> .footer-heading  { font-size: 0.875rem; color: white; }
> ```
>
> Relationship to Tailwind: Tailwind is OOCSS taken to its
> logical extreme. Every class is an atomic structure or
> skin utility: `flex`, `p-4`, `bg-blue-600`, `text-white`,
> `rounded`. You compose utilities in HTML rather than
> naming classes. This maximizes reuse but trades off
> abstraction.
>
> *What separates good from great:* OOCSS was the origin
> of utility-first CSS, which predates Tailwind by a decade.
> Atomic CSS (Thierry Koblentz, 2013), Tachyons (2014),
> and Basscss (2013) all applied OOCSS principles at the
> utility level. Tailwind (2017) made it mainstream.

---

**Q5: How do SMACSS State classes work with JavaScript?**
`[MID]` MECHANISM

*Why they ask:* JS-CSS integration is everyday frontend work.

*Likely follow-up:* "What's the alternative to `.is-` state
classes?"

> **Answer:**
>
> SMACSS State classes are toggled by JavaScript to reflect
> UI state. They conventionally start with `.is-` (active
> state) or `.has-` (feature presence).
>
> ```css
> /* Defined globally in SMACSS State layer */
> .is-hidden { display: none !important; }
> .is-loading { opacity: 0.6; pointer-events: none; }
> .is-expanded { }  /* defined per component */
>
> /* Component-level state override */
> .accordion.is-expanded .accordion__body {
>   max-height: 500px; /* expands the panel */
> }
> .nav__item.is-active {
>   font-weight: bold;
>   color: var(--color-primary);
> }
> ```
>
> JavaScript:
> ```javascript
> // Toggle state
> button.addEventListener('click', () => {
>   panel.classList.toggle('is-expanded');
>   button.setAttribute('aria-expanded',
>     panel.classList.contains('is-expanded')
>   );
> });
>
> // Add/remove single states
> form.classList.add('is-loading');
> fetch('/api/...').then(() => {
>   form.classList.remove('is-loading');
> });
> ```
>
> Alternative: `data-*` attributes:
> ```css
> [data-state="expanded"] .panel__body { display: block; }
> ```
>
> `data-*` attributes are more descriptive for complex
> multi-state machines (idle/loading/success/error vs
> the proliferating `.is-loading`, `.is-success`, `.is-error`
> class pattern).
>
> *What separates good from great:* Always pair visual state
> changes with ARIA attribute changes. `.is-active` sets
> the visual; `aria-selected="true"` communicates to
> screen readers. CSS state + ARIA state must be in sync.
> Use CSS `[aria-expanded="true"]` as the style hook when
> possible - single source of truth for both accessibility
> and style.

---

**Q6: What is the "specificity flat" design?** `[SENIOR]`
MECHANISM

*Why they ask:* Specificity management is a senior CSS skill.

*Likely follow-up:* "How do you avoid !important in a
BEM-based codebase?"

> **Answer:**
>
> "Specificity flat" means keeping all selector specificities
> at the same level - ideally single-class (0,1,0). This
> prevents the specificity arms race where overriding rules
> requires ever-higher specificity.
>
> BEM enforces specificity flat by design:
> ```css
> .card { }           /* 0,1,0 */
> .card__title { }    /* 0,1,0 */
> .card--featured { } /* 0,1,0 */
> ```
>
> All the same specificity. Cascade order determines wins.
>
> Violations that break specificity flat:
> ```css
> .card .card__title { }         /* 0,2,0 - HIGHER */
> article.card .card__title { }  /* 0,2,1 - EVEN HIGHER */
> #main .card { }                /* 1,1,0 - MUCH HIGHER */
> ```
>
> The danger: once any rule uses nesting or IDs, the flat
> model breaks and overriding requires matching or exceeding
> that specificity.
>
> Specificity flat practices:
> 1. Only use class selectors (no elements, no IDs in CSS)
> 2. Never nest BEM selectors in preprocessors
> 3. Use `@layer` (CSS Cascade Layers) to control override
>    order without specificity:
>
> ```css
> @layer base, components, utilities;
>
> @layer components {
>   .card { } /* 0,1,0 */
> }
> @layer utilities {
>   .text-center { } /* 0,1,0 */
>   /* Wins over .card because 'utilities' layer > 'components' */
>   /* WITHOUT higher specificity */
> }
> ```
>
> `@layer` is the modern specificity management tool.
> Layer order determines precedence, not specificity.
>
> *What separates good from great:* `!important` reverses
> layer precedence. `!important` in a low-priority layer
> beats `!important` in a high-priority layer. This is
> counterintuitive and rarely needed, but understanding
> it prevents confusion when `!important` appears in
> utility libraries.

---

**Q7: How has CSS methodology evolved from BEM to
modern tooling?** `[SENIOR]` ARCHITECTURE

*Why they ask:* Historical context shows professional
evolution awareness.

*Likely follow-up:* "What does CSS Modules replace in BEM?"

> **Answer:**
>
> Evolution timeline:
>
> 2008: OOCSS - principles for reusable CSS objects
> 2010: SMACSS - 5-layer categorical organization
> 2013: BEM - component naming convention
> 2014: CSS Modules - build-tool-enforced scoping
> 2015: styled-components - runtime CSS-in-JS
> 2017: Tailwind CSS - utility-first atomic CSS
> 2019: CSS Custom Properties + design tokens
> 2022: CSS `@layer` - native cascade management
> 2024: CSS `@scope` - native element-level scoping
>
> Each generation solves the same problem (global scope)
> with different trade-offs:
>
> BEM: zero tooling, requires discipline, verbose HTML
> CSS Modules: build tooling required, automatic scoping,
>   readable class names
> styled-components: runtime overhead, JS-CSS coupling,
>   great DX in React
> Tailwind: utility composition in HTML, no naming needed,
>   learning curve, HTML verbosity
> CSS @scope: native solution, no tooling, no naming,
>   currently limited browser support
>
> Modern best practice (2024): CSS Modules or CSS-in-JS
> for component styles + Tailwind utilities for spacing
> and typography + CSS custom properties for design tokens
> + CSS `@layer` for cascade management.
>
> BEM still relevant: design systems consumed as plain
> CSS, legacy codebases, non-framework HTML/CSS projects.
>
> *What separates good from great:* CSS `@scope` (Chrome
> 118+) enables native CSS scoping: `@scope (.card) {
> .title { } }` applies `.title` only within `.card` without
> changing specificity. This is what BEM simulates with
> naming conventions. As `@scope` gains broader browser
> support, it will be the long-term replacement for both
> BEM and CSS Modules.

---

**Q8: Describe BEM in a real design system component
library.** `[SENIOR]` PRODUCTION

*Why they ask:* Tests ability to apply methodology at scale.

*Likely follow-up:* "How do you handle component variants?"

> **Answer:**
>
> In a design system consuming plain CSS (no CSS Modules):
>
> Directory structure:
> ```
> styles/
>   tokens/
>     colors.css      /* :root custom properties */
>     typography.css
>     spacing.css
>   base/
>     reset.css
>     base.css
>   components/
>     button.css      /* .button, .button--primary, etc. */
>     card.css        /* .card, .card__*, .card--* */
>     nav.css
>   utilities/
>     display.css     /* .hidden, .flex, .grid */
>     spacing.css     /* .mt-4, .mb-2, etc. */
> ```
>
> Component: button
> ```css
> /* block */
> .button {
>   display: inline-flex;
>   align-items: center;
>   gap: 0.5rem;
>   padding: 0.5rem 1rem;
>   border: 1px solid transparent;
>   border-radius: var(--radius);
>   font-size: var(--text-sm);
>   font-weight: 500;
>   cursor: pointer;
>   transition: background var(--transition);
>   /* structural only - no colors */
> }
>
> /* modifiers for variants */
> .button--primary {
>   background: var(--color-primary);
>   color: white;
>   border-color: var(--color-primary);
> }
> .button--secondary {
>   background: transparent;
>   color: var(--color-primary);
>   border-color: var(--color-primary);
> }
> .button--sm { padding: 0.25rem 0.75rem; font-size: var(--text-xs); }
> .button--lg { padding: 0.75rem 1.5rem; font-size: var(--text-base); }
>
> /* elements */
> .button__icon {
>   width: 1em;
>   height: 1em;
>   flex-shrink: 0;
> }
>
> /* state (SMACSS style) */
> .button.is-loading { opacity: 0.7; pointer-events: none; }
> .button:disabled, .button[disabled] { opacity: 0.5; cursor: not-allowed; }
> ```
>
> Usage: `<button class="button button--primary button--lg">`
>
> *What separates good from great:* The `button--primary`
> modifier only provides colors/skin. The `button` base
> provides structure. This is the OOCSS separation applied
> within BEM. Adding a new variant only requires a new
> modifier class with its specific skin properties.

---

**Q9: How do you handle global vs component-level
overrides in BEM without !important?** `[SENIOR]` TRADE-OFF

*Why they ask:* Managing overrides is a real daily pain point.

*Likely follow-up:* "What does CSS @layer add here?"

> **Answer:**
>
> The problem: global design tokens and utility classes
> sometimes need to override component styles, but BEM's
> flat specificity (all 0,1,0) means only source order
> determines the winner.
>
> Solution 1: Source order management
> Load order: base → tokens → components → utilities
> Utilities come last, so they override components.
>
> ```css
> /* utilities.css - loaded last */
> .text-center { text-align: center; }
> /* Overrides .card__title's text-align if any */
> ```
>
> Solution 2: CSS Cascade Layers (modern)
> ```css
> @layer base, tokens, components, utilities;
>
> @layer components {
>   .card__title { text-align: left; }
> }
>
> @layer utilities {
>   .text-center { text-align: center; }
>   /* utilities layer > components layer: wins */
>   /* regardless of specificity or source order */
> }
> ```
>
> `@layer` replaces source-order management with explicit
> layer order. More maintainable, more predictable.
>
> Solution 3: Specificity bump (anti-pattern, last resort)
> ```css
> /* Add a :where() wrapper to lower specificity */
> :where(.card) .text-center { text-align: center; }
> /* or use !important on utilities (Bootstrap does this) */
> ```
>
> `!important` utilities (Bootstrap/Tailwind `!` prefix)
> are legitimate when utilities are explicitly meant to be
> override-proof. But they can't be overridden without
> their own `!important`, creating problems if you need
> to override them contextually.
>
> *What separates good from great:* CSS `@layer` is the
> correct long-term solution. It replaces all source-order
> management, `!important` utilities, and specificity hacks.
> Browsers support it universally since 2022. Any new
> project should use `@layer` for cascade management.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Specificity flat design |
| Hiring Manager | Team adoption and BEM trade-offs |
| Bar Raiser | Evolution from BEM to @layer/@scope |
| Peer Engineer | BEM component variant patterns |

---

### ⚖️ Comparison Table

| Methodology | Enforcement | Verbosity | Best For |
|---|---|---|---|
| BEM | Convention only | High | Plain CSS, legacy |
| SMACSS | Convention only | Low (org only) | Large CSS files |
| OOCSS | Convention only | Medium | DRY utility classes |
| CSS Modules | Build tool | Low | React/Vue components |
| CSS-in-JS | Runtime/build | Low | React + dynamic styles |
| Tailwind | Build tool | HTML-verbose | Utility-first teams |
| CSS @scope | Browser native | Low | Modern browsers only |

---

### 🏛️ System Design

*(Omit: ★★☆ working-level - CSS design system architecture
covered in L5 Design Systems)*

---

### 📊 Diagram

*(Omit: BEM naming hierarchy is best shown with code
examples, which are provided above)*

---
---

# CSS-in-JS Trade-offs

🎯 **Interview Weight:** high - CSS-in-JS is divisive in
the community; being able to articulate performance costs,
DX benefits, and when to choose each approach is a senior
frontend capability

---

### 🎯 Model Answer

**30 seconds:**

> CSS-in-JS libraries (styled-components, Emotion) write CSS
> as JavaScript template literals. Benefits: automatic
> scoping, dynamic styles via props, co-located styles, and
> TypeScript integration. Costs: runtime overhead (CSS
> generated at render time), larger bundle, and SSR
> hydration complexity. Zero-runtime alternatives (vanilla-
> extract, Linaria) compile to static CSS at build time,
> preserving the DX benefits without the runtime cost.

**3 minutes (Senior):**

> Runtime CSS-in-JS (styled-components, Emotion): CSS strings
> are processed by the JavaScript runtime. Each component
> render may generate new CSS rules. The library injects
> `<style>` tags or uses the CSSOM API (`insertRule`) to
> apply styles. This work happens in the browser's main
> thread, competing with React rendering.
>
> Performance impact: styled-components v5 benchmark showed
> ~25% slower initial render compared to CSS Modules or
> plain CSS for component-heavy pages. The impact grows
> with component count and dynamic style complexity.
>
> With React Server Components (RSC), runtime CSS-in-JS
> faces a fundamental problem: CSS-in-JS libraries use
> React Context for theme propagation. Server Components
> cannot use Context. styled-components v5 is incompatible
> with RSC. The styled-components team released v6 with
> RSC support but the approach is more complex.
>
> Zero-runtime CSS-in-JS: vanilla-extract, Linaria, Panda
> CSS, StyleX (Meta). These process CSS at build time,
> outputting static CSS files. DX is similar (TypeScript,
> co-location, variants) but no runtime cost. Compatible
> with RSC.
>
> The industry has largely moved toward zero-runtime solutions
> for performance-sensitive applications.

*Adapting up:* Compare styled-components v5 vs v6 RSC
approach; discuss how CSS Modules competes with zero-runtime
CSS-in-JS.

*Adapting down:* CSS-in-JS writes CSS in JavaScript strings.
It has automatic scoping but adds JavaScript overhead.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS-in-JS - what it is,
the performance trade-offs, and when it's the right choice
versus alternatives."

**(2) First principles:** "From first principles, CSS-in-JS
trades static file scoping (CSS Modules) for dynamic
JavaScript-driven scoping and props-based style logic.
Every trade-off follows from that core exchange."

**(3) Bridge:** "CSS-in-JS is like using a database instead
of a file for storing data. More capability, more overhead.
Zero-runtime CSS-in-JS is like having a database that compiles
to a file at build time."

---

### 📘 Concept Explanation

**What it is:**

Libraries that allow CSS to be written within JavaScript
files, with styles scoped to components, support for dynamic
props-based styling, and TypeScript integration. Runtime
variants generate CSS at browser-render time. Zero-runtime
variants generate static CSS at build time.

**The problem it solves:**

CSS Modules requires separate `.module.css` files. CSS-in-JS
co-locates styles with component logic, enables type-safe
props-based styling, and provides theme system integration
via Context.

**How it works:**

```
RUNTIME CSS-in-JS (styled-components):
  import styled from 'styled-components';

  const Button = styled.button`
    background: ${props => props.primary
      ? 'blue' : 'white'};
    padding: 0.5rem 1rem;
    border: 2px solid blue;
  `;

  // At render time:
  // 1. Template literal evaluates (includes prop values)
  // 2. Hash generated from CSS string
  // 3. CSS injected as <style> tag (or via CSSOM)
  // 4. Hash used as class name on element
  // Result: <button class="sc-abc123">

ZERO-RUNTIME (vanilla-extract):
  // button.css.ts (TypeScript)
  import { style, createVar } from '@vanilla-extract/css';
  export const base = style({
    padding: '0.5rem 1rem',
  });
  export const primary = style([base, {
    background: 'blue',
  }]);
  // At build time:
  // → CSS file generated with hashed class names
  // → TypeScript types for class names
  // Zero runtime processing

CSS MODULES (comparison):
  /* button.module.css */
  .base { padding: 0.5rem 1rem; }
  .primary { background: blue; }

  // build tool processes → class name hashing
  // .button_base_hash123, .button_primary_hash456
  // No TypeScript types without extra plugin
```

**The key insight:**

The performance cost of runtime CSS-in-JS scales with
component mount count and render frequency. For static
UIs with few re-renders (marketing pages), the cost is
imperceptible. For data-heavy UIs with frequent renders
(dashboards, lists), the runtime cost accumulates and
causes measurable slowdowns.

**When to use runtime CSS-in-JS:**

- Legacy React applications already using styled-components
- Teams prioritizing DX over performance
- Applications not yet using RSC
- When dynamic prop-based styles have very complex logic
  that's hard to model with CSS custom properties

**When NOT to use runtime CSS-in-JS:**

- React Server Components (Context incompatibility)
- Performance-critical, high-component-count pages
- New projects starting fresh (zero-runtime is better)

**Alternatives:**

- CSS Modules: static scoping, no runtime cost
- vanilla-extract: zero-runtime CSS-in-JS (TypeScript)
- StyleX (Meta): atomic CSS-in-JS (zero-runtime)
- Tailwind: utility-first, no CSS authoring

**First-principles derivation:**

CSS needs scoping and dynamic values. Two solutions:
(1) Build-time scoping (CSS Modules, vanilla-extract) - no
runtime cost but no runtime dynamism. (2) Runtime scoping
(styled-components) - dynamic by nature but costs compute
at render time. The choice is a classic static vs dynamic
trade-off.

---

### 💻 Code Example

**BAD: runtime CSS-in-JS with frequent re-renders**

```javascript
// BAD: computationally expensive for animated/fast-updating UI
const ProgressBar = styled.div`
  width: ${props => props.progress}%;
  height: 8px;
  background: blue;
  transition: width 0.3s;
`;

function Progress({ value }) {
  // Re-renders every 16ms during animation
  // Each render: CSS string evaluated, new hash computed,
  // CSSOM updated → main thread work on every frame
  return <ProgressBar progress={value} />;
}
```

> **Code walkthrough:** The `progress` prop changes on
> every animation frame. Each render triggers styled-
> components to evaluate the template literal, compute
> a new hash, and update the CSSOM rule. This is main
> thread work running at 60fps, competing with React's
> render work.

**GOOD: CSS custom property for dynamic values**

```javascript
// GOOD: CSS custom property for dynamic value
const ProgressBar = styled.div`
  width: var(--progress, 0%);
  height: 8px;
  background: blue;
  transition: width 0.3s;
`;

function Progress({ value }) {
  return (
    <ProgressBar
      style={{ '--progress': `${value}%` }}
    />
  );
}
// Only the inline style prop updates (cheap)
// styled-components renders with a fixed class
// CSS custom property update handled by CSS engine
```

> **Code walkthrough:** Move the dynamic value from the
> CSS-in-JS template to a CSS custom property in the
> inline style. styled-components generates ONE class
> (no re-hashing on value change). The CSS custom property
> is updated directly in the DOM's inline style map, which
> is a browser-native operation. This dramatically reduces
> main-thread work for frequently-updating values.

**PRODUCTION: zero-runtime with vanilla-extract**

```typescript
// button.css.ts (zero-runtime TypeScript)
import { style } from '@vanilla-extract/css';
import { vars } from './theme.css';

export const base = style({
  display: 'inline-flex',
  alignItems: 'center',
  padding: `${vars.space.sm} ${vars.space.md}`,
  borderRadius: vars.radius.sm,
  fontSize: vars.text.sm,
  fontWeight: '500',
  transition: `background ${vars.transition}`,
  cursor: 'pointer',
});

export const primary = style([base, {
  background: vars.color.primary,
  color: 'white',
}]);

export const secondary = style([base, {
  background: 'transparent',
  color: vars.color.primary,
  border: `1px solid ${vars.color.primary}`,
}]);
```

```typescript
// Button.tsx
import * as styles from './button.css';
import { clsx } from 'clsx';

function Button({ variant = 'primary', className, ...props }) {
  return (
    <button
      className={clsx(styles[variant], className)}
      {...props}
    />
  );
}
```

> **Code walkthrough:** vanilla-extract processes `button.css.ts`
> at build time. The output is a static CSS file with hashed
> class names. No runtime processing. TypeScript types
> ensure `styles.primary` is valid (typos are type errors).
> Theme values come from `vars` (also generated from a type-
> safe theme file). This is DX equivalent to styled-components
> with zero runtime cost.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CSS-in-JS like styled-components writes CSS inside
> JavaScript using template literals. The main benefits:
> styles are co-located with the component, you get automatic
> scoping (no class name conflicts), and you can use props
> to change styles. The main downside: it adds JavaScript
> overhead because styles are processed at runtime when the
> component renders.

---

**Senior / Staff (5+ years):**

> Runtime CSS-in-JS (styled-components, Emotion) has
> measurable performance costs - style computation runs
> on the main thread at render time. For high-component-
> count or frequently-updating UIs, this matters.
>
> More critically, runtime CSS-in-JS is fundamentally
> incompatible with React Server Components because it uses
> Context, which isn't available in RSC. styled-components
> v6 attempted to solve this but the solution is complex.
>
> For new projects I default to CSS Modules for component
> scoping or vanilla-extract/Panda CSS for TypeScript
> integration. Tailwind handles utilities. CSS custom
> properties handle dynamic values. This stack matches the
> performance of plain CSS with comparable DX to styled-
> components.

---

### ⚠️ Common Misconceptions

**"CSS-in-JS is just for co-location - performance is
identical"**

Runtime CSS-in-JS processes CSS on the main thread.
Benchmarks (styled-components v5 vs CSS Modules) show
20-30% slower initial render in component-heavy apps.
The impact is real and scales with component count.

**"Zero-runtime CSS-in-JS has no advantages over CSS Modules"**

Zero-runtime CSS-in-JS (vanilla-extract) adds: TypeScript
types for class names (no typos), type-safe design token
system, and runtime variant composition. CSS Modules are
just scoped CSS with no TypeScript-first authoring.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: RSC runtime error with styled-components**

```
Error: styled-components requires React Client Context.
Cannot be used in Server Components.
```

Cause: styled-components v5 uses React Context internally,
which is unavailable in RSC.

Fix options:
1. Add `'use client'` to component (converts to client component)
2. Migrate to CSS Modules or vanilla-extract
3. Upgrade to styled-components v6 with RSC support

---

**Symptom: FOUC (Flash of Unstyled Content) with SSR**

Cause: SSR sends HTML without CSS; client-side JS
hydrates and inserts styles. Content flashes unstyled.

Fix: styled-components and Emotion both require server-side
style extraction:
```javascript
// styled-components SSR
import { ServerStyleSheet } from 'styled-components';
const sheet = new ServerStyleSheet();
const html = renderToString(sheet.collectStyles(<App />));
const css = sheet.getStyleTags();
// Inject css into HTML head
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Explain CSS-in-JS | 3 min | Runtime vs zero-runtime |
| Performance costs | 3-4 min | Main thread, CSSOM |
| RSC compatibility issue | 3-4 min | Context limitation |
| styled-components vs CSS Modules | 3-4 min | Trade-off articulation |
| Zero-runtime solutions | 3-4 min | vanilla-extract, StyleX |
| SSR and FOUC | 3 min | Style extraction |
| When CSS-in-JS is right choice | 3 min | Judgment |
| Dynamic styles without CSS-in-JS | 3-4 min | Custom properties |
| Future of CSS-in-JS | 3-4 min | @scope, @layer evolution |

---

**Q1: What is CSS-in-JS and what problem does it solve?**
`[MID]` CONCEPTUAL

*Why they ask:* Sets baseline understanding of the concept.

*Likely follow-up:* "How does it compare to CSS Modules?"

> **Answer:**
>
> CSS-in-JS is a pattern where CSS styles are written within
> JavaScript files, typically as tagged template literals or
> object syntax. Popular implementations: styled-components,
> Emotion, JSS.
>
> Problems it solves vs plain CSS and CSS Modules:
>
> 1. **Co-location**: styles live with the component.
>    In CSS Modules, you have `Card.jsx` + `Card.module.css`.
>    In CSS-in-JS: one file.
>
> 2. **Dynamic styles via props**: styles can change based
>    on component props directly in the CSS syntax:
>    ```javascript
>    const Button = styled.button`
>      background: ${p => p.primary ? 'blue' : 'white'};
>    `;
>    ```
>    CSS Modules requires toggling class names: `styles.primary`
>    vs `styles.secondary`.
>
> 3. **TypeScript-safe theming**: the theme object is typed.
>    Accessing `theme.colors.nonexistent` is a type error.
>    CSS custom properties have no type checking.
>
> 4. **Dead code elimination**: unused styled-components
>    are tree-shaken with the component.
>
> Compared to CSS Modules:
> - CSS Modules: static CSS file, build-time scoping, no runtime
> - CSS-in-JS: JavaScript-based, runtime scoping, more dynamic
>
> Both solve the global scope problem. CSS-in-JS adds more
> capabilities at a runtime cost.
>
> *What separates good from great:* CSS Modules with TypeScript
> types is now possible via `typescript-plugin-css-modules`
> or codegen tools. This closes the type-safety gap between
> CSS Modules and CSS-in-JS, removing one of CSS-in-JS's
> main advantages.

---

**Q2: What is the performance cost of runtime CSS-in-JS?**
`[SENIOR]` PRODUCTION

*Why they ask:* Performance implications are the main
argument against CSS-in-JS.

*Likely follow-up:* "At what scale does the cost become
noticeable?"

> **Answer:**
>
> Runtime CSS-in-JS has three performance costs:
>
> 1. **Style computation on every render**: the template
>    literal is evaluated when the component renders.
>    Props are interpolated, a new CSS string is generated,
>    and a hash computed. For components with many dynamic
>    props, this happens on every re-render.
>
> 2. **CSSOM manipulation**: styles are injected by calling
>    `document.styleSheets[x].insertRule()` (CSSOM) or by
>    updating `<style>` innerHTML. Both are main-thread
>    DOM operations.
>
> 3. **Garbage collection pressure**: temporary CSS strings
>    and hash objects created per render add GC pressure.
>
> Benchmarks context: styled-components v5 with 1000
> components showed ~25ms longer initial paint vs CSS
> Modules in typical benchmarks. For most apps with 50-200
> components, this is imperceptible. For data-heavy apps
> with 1000+ components or frequent re-renders
> (scroll virtualization, real-time data), it's measurable.
>
> Emotion's optimizations: `css` tagged template literal
> memoizes the CSS string per unique set of interpolations,
> reducing re-computation. Emotion is faster than styled-
> components v5 in most benchmarks.
>
> styled-components v6: uses `insertRule` instead of
> innerHTML manipulation for style injection (faster CSSOM
> API), and has improved serialization caching. The
> performance gap with CSS Modules has narrowed.
>
> *What separates good from great:* The performance cost
> is frontloaded (initial render). After hydration, style
> rules are cached. The penalty is felt most on page load,
> less so on subsequent interactions. For SSR-heavy apps
> (Next.js), SSR style extraction removes the FOUC cost
> but doesn't remove the client-side runtime on hydration.

---

**Q3: Why is styled-components (v5) incompatible with
React Server Components?** `[SENIOR]` MECHANISM

*Why they ask:* RSC is the current React paradigm; this
is a critical architectural constraint.

*Likely follow-up:* "How did styled-components v6 try to
fix this?"

> **Answer:**
>
> React Server Components (RSC) run in the Node.js server
> environment. They don't have access to browser APIs,
> cannot use React state or effects, and cannot use React
> Context.
>
> styled-components v5 uses React Context for three things:
> 1. Theme propagation: `<ThemeProvider theme={...}>`
>    injects the theme via Context
> 2. Style injection: tracks which styles to inject during
>    SSR via a Context-based ServerStyleSheet
> 3. Component registry: tracks styled-components instances
>    via Context
>
> In RSC, Context is unavailable. Any component that
> references `useContext(ThemeContext)` (which styled-
> components does internally) fails.
>
> The error: "React Context is not available in Server
> Components" - thrown when styled-components tries to
> access theme or inject styles.
>
> Workarounds with v5:
> - Mark all styled-components as `'use client'`
> - This turns them into Client Components, making RSC
>   a non-benefit for those components
>
> styled-components v6 approach:
> - Uses the React 18 style flushing API for RSC-compatible
>   style injection
> - Theme can be passed as props instead of Context
>   for Server Component usage
> - The ergonomics are more complex than v5
>
> Industry response: many teams migrated to CSS Modules
> or zero-runtime alternatives when adopting RSC.
>
> *What separates good from great:* Next.js's official
> recommendation for RSC styling is CSS Modules. Vercel
> (who builds Next.js) created Turbopack which has first-
> class CSS Modules support. The RSC + runtime CSS-in-JS
> incompatibility is what drove the "CSS-in-JS is dead"
> takes in 2023 - more nuanced reality: runtime CSS-in-JS
> is increasingly a legacy choice for new RSC-based apps.

---

**Q4: What are zero-runtime CSS-in-JS alternatives?**
`[SENIOR]` COMPARISON

*Why they ask:* Shows awareness of the modern ecosystem.

*Likely follow-up:* "What does vanilla-extract offer
that CSS Modules doesn't?"

> **Answer:**
>
> Zero-runtime CSS-in-JS libraries compile CSS to static
> files at build time, eliminating runtime JavaScript cost.
>
> **vanilla-extract** (Mark Dalgleish, 2021):
> - TypeScript-first: `.css.ts` files
> - Type-safe design token system
> - Zero-runtime: outputs `.css` files at build time
> - RSC compatible
> - `style()`, `createVar()`, `recipe()` API
>
> **StyleX** (Meta, 2024):
> - Atomic CSS generation (like Tailwind but from JS)
> - Used internally at facebook.com
> - TypeScript-first
> - Compiler strips all JS at build time
> - Deterministic specificity (important for large apps)
>
> **Panda CSS** (Chakra UI team, 2023):
> - Combines atomic CSS + recipe API
> - Token-based design system
> - RSC compatible
> - Large ecosystem of components
>
> **Linaria** (earlier, less popular):
> - Template literal API similar to styled-components
> - But compiled at build time
>
> Comparison to CSS Modules:
>
> | Feature | CSS Modules | vanilla-extract |
> |---|---|---|
> | TypeScript types | Plugin needed | Built-in |
> | Design tokens | Manual | First-class `createTheme` |
> | Variant API | Manual classNames | Built-in `recipe()` |
> | RSC compat | Yes | Yes |
> | Runtime cost | Zero | Zero |
>
> *What separates good from great:* vanilla-extract's
> `sprinkles` addon generates atomic utility classes from
> a design token spec - similar to Tailwind but type-safe
> and constrained to your design system tokens. This is
> the zero-runtime equivalent of the CSS-in-JS + design
> system integration pattern.

---

**Q5: How do you handle dynamic styles without
runtime CSS-in-JS?** `[SENIOR]` HANDS-ON

*Why they ask:* Tests practical CSS custom property
knowledge for dynamic styling.

*Likely follow-up:* "What are the limits of this approach?"

> **Answer:**
>
> CSS custom properties handle most CSS-in-JS dynamic
> style use cases:
>
> **Simple prop-based styles:**
> ```javascript
> // CSS-in-JS approach (runtime cost):
> const Card = styled.div`
>   background: ${p => p.color};
>   width: ${p => p.width}px;
> `;
>
> // CSS custom property approach (no runtime CSS):
> function Card({ color, width, children }) {
>   return (
>     <div
>       className={styles.card}
>       style={{
>         '--card-color': color,
>         '--card-width': `${width}px`,
>       }}
>     >
>       {children}
>     </div>
>   );
> }
> ```
>
> ```css
> /* card.module.css */
> .card {
>   background: var(--card-color);
>   width: var(--card-width);
> }
> ```
>
> **Variants (fixed set of options):**
> ```javascript
> // Use data attributes or class names
> <Button data-variant="primary">Click</Button>
>
> // CSS:
> .button[data-variant="primary"] {
>   background: var(--color-primary);
> }
> .button[data-variant="secondary"] {
>   background: transparent;
>   border: 1px solid var(--color-primary);
> }
> ```
>
> Limits:
> - CSS can't compute arbitrary JavaScript values
>   (e.g., `background: ${interpolate(p.value, colors)}`)
> - For complex color interpolations, gradients based on
>   data values, or layouts computed in JavaScript, inline
>   styles are still needed
> - TypeScript doesn't type-check custom property names
>   (vanilla-extract solves this)
>
> *What separates good from great:* For truly dynamic
> data-driven styles (a chart with thousands of bars each
> with a different height), inline styles are the correct
> tool. CSS custom properties reduce the class-per-value
> problem to a property-per-value problem. At thousands
> of elements, the rendering cost is the same regardless
> of approach.

---

**Q6: What is FOUC and how does CSS-in-JS address it
in SSR?** `[SENIOR]` PRODUCTION

*Why they ask:* SSR + CSS-in-JS is a common gotcha.

*Likely follow-up:* "How does CSS Modules avoid this?"

> **Answer:**
>
> FOUC (Flash of Unstyled Content): when a page renders
> HTML without its CSS applied, showing a brief flash of
> unstyled content before CSS loads/injects.
>
> With runtime CSS-in-JS in SSR:
> 1. Server renders HTML (fast)
> 2. Browser receives HTML, starts rendering
> 3. JavaScript bundle downloads and parses (slow)
> 4. React hydrates, styled-components runs, CSS injects
> 5. UI "pops" from unstyled to styled (FOUC)
>
> Fix: extract styles during SSR, inline them in `<head>`:
>
> ```javascript
> // Next.js _document.js (pages router)
> import Document, { Html, Head, Main, NextScript }
>   from 'next/document';
> import { ServerStyleSheet } from 'styled-components';
>
> export default class MyDocument extends Document {
>   static async getInitialProps(ctx) {
>     const sheet = new ServerStyleSheet();
>     const originalRenderPage = ctx.renderPage;
>
>     ctx.renderPage = () =>
>       originalRenderPage({
>         enhanceApp: (App) => (props) =>
>           sheet.collectStyles(<App {...props} />),
>       });
>
>     const initialProps = await Document.getInitialProps(ctx);
>     return {
>       ...initialProps,
>       styles: [initialProps.styles, sheet.getStyleElement()],
>     };
>   }
> }
> ```
>
> The SSR-extracted styles are inlined in the `<head>` as
> `<style>` tags. The browser renders with styles from the
> first HTML byte. On hydration, styled-components compares
> the SSR styles with client-computed styles to verify
> consistency.
>
> CSS Modules avoids FOUC entirely: styles are in static
> `.css` files. They're served as separate resources that
> load before React JavaScript. No SSR style extraction
> needed.
>
> *What separates good from great:* The SSR extraction
> doubles the CSS processing: once on the server (to
> extract) and once on the client (to verify/hydrate).
> With vanilla-extract or CSS Modules, CSS is static -
> processed once at build time. This is another reason
> zero-runtime solutions are recommended for SSR-heavy
> Next.js apps.

---

**Q7: When would you choose styled-components in 2024?**
`[SENIOR]` TRADE-OFF

*Why they ask:* Shows ability to make pragmatic decisions
rather than dogmatic ones.

*Likely follow-up:* "Would you use it for a new project?"

> **Answer:**
>
> Legitimate cases for styled-components in 2024:
>
> 1. **Existing codebase**: a large React application already
>    using styled-components. Migration cost is enormous.
>    Maintain and upgrade incrementally to v6 for RSC support.
>
> 2. **Non-RSC React apps**: React apps that don't use
>    Server Components (most SPAs, Create React App
>    successors, Vite-based apps). No RSC incompatibility.
>
> 3. **Team familiarity**: if the team deeply knows styled-
>    components and the performance cost is not a bottleneck,
>    the DX advantage may outweigh migration.
>
> 4. **Extremely dynamic UIs**: highly interactive UIs where
>    prop-based style logic is genuinely complex. styled-
>    components v5 still has better ergonomics than custom
>    properties for very dynamic cases.
>
> Would I use it for a new project? No.
>
> For a new project in 2024:
> - App using RSC (Next.js App Router): CSS Modules or
>   vanilla-extract
> - SPA (Vite, React without RSC): CSS Modules or
>   vanilla-extract, possibly Tailwind for utilities
> - Design-system-heavy: vanilla-extract with Sprinkles
>   or Panda CSS for token-safe atomic classes
>
> The DX benefits of styled-components are largely matched
> by vanilla-extract, without the performance or RSC costs.
>
> *What separates good from great:* Recognizing that "best
> tool" depends on context and constraints - not declaring
> styled-components universally bad. For a team of 5 working
> on an SPA that rarely re-renders and has no RSC plans,
> styled-components is a perfectly reasonable choice. For a
> 50-person team building a performance-critical Next.js
> App Router application, it's not. Context matters.

---

**Q8: What is StyleX (Meta) and how does it compare
to Tailwind?** `[STAFF]` COMPARISON

*Why they ask:* StyleX is used at Facebook-scale; staff
candidates follow cutting edge.

*Likely follow-up:* "What is atomic CSS and why does it
improve performance?"

> **Answer:**
>
> StyleX (open-sourced by Meta in 2023) is a zero-runtime
> CSS-in-JS system used internally by Meta (Facebook,
> Instagram, Threads). Key properties:
>
> 1. **Atomic CSS output**: every style declaration becomes
>    a single-property utility class. `{color: 'blue', padding: 8}`
>    → two atomic classes. Shared atomic classes are deduplicated.
>
> 2. **TypeScript-first**: style definitions are typed.
>    Theme constraints are compile-time checked.
>
> 3. **Zero-runtime**: compiler strips all JS, outputs
>    static CSS file with atomic classes.
>
> 4. **Predictable specificity**: atomic classes each
>    have specificity (0,1,0). Merge resolution is
>    deterministic - later properties win. This solves
>    the specificity war problem at scale.
>
> Comparison to Tailwind:
>
> | Aspect | StyleX | Tailwind |
> |---|---|---|
> | Authoring | JS/TS objects | HTML class strings |
> | TypeScript | Built-in | Plugin-based |
> | Design tokens | Type-safe constraints | Configurable theme |
> | Build output | Atomic CSS | Atomic CSS |
> | Tree-shaking | Per-class used | Per-class used |
> | IDE support | TypeScript | IntelliSense plugin |
> | Co-location | Yes | No (HTML) |
>
> Both output atomic CSS (maximum CSS reuse at scale).
>
> *What separates good from great:* The "atomic CSS"
> advantage at scale: at facebook.com with thousands of
> components, a monolithic CSS file would be enormous.
> Atomic CSS means each unique property-value pair appears
> once in the CSS output, regardless of how many components
> use it. A 10,000-component app using atomic CSS may have
> a smaller CSS payload than a 1,000-component app using
> component-scoped CSS because property combinations are
> shared.

---

**Q9: How do you migrate from styled-components to CSS
Modules?** `[SENIOR]` PRODUCTION

*Why they ask:* Migration strategy is a real work scenario
as teams move away from runtime CSS-in-JS.

*Likely follow-up:* "What is the biggest challenge in
this migration?"

> **Answer:**
>
> Migration strategy: incremental file-by-file, starting
> with leaf components (no children).
>
> Step 1: For each component, create a `.module.css` file
> ```
> Button.tsx → Button.module.css
> Card.tsx → Card.module.css
> ```
>
> Step 2: Translate styled-components to CSS Modules
>
> ```javascript
> // BEFORE: styled-components
> const Button = styled.button`
>   background: ${p => p.primary ? 'blue' : 'white'};
>   padding: 0.5rem 1rem;
>   border-radius: 4px;
> `;
>
> // AFTER: CSS Modules
> // Button.module.css
> .button { padding: 0.5rem 1rem; border-radius: 4px; }
> .primary { background: blue; }
> .secondary { background: white; }
>
> // Button.tsx
> import s from './Button.module.css';
> function Button({ primary, children }) {
>   return (
>     <button className={clsx(s.button, primary ? s.primary : s.secondary)}>
>       {children}
>     </button>
>   );
> }
> ```
>
> Step 3: Replace theme/ThemeProvider with CSS custom
> properties on `:root`
>
> ```javascript
> // BEFORE: ThemeProvider + styled-components theme
> const theme = { colors: { primary: '#2563eb' } };
>
> // AFTER: CSS custom properties
> // theme.css
> :root { --color-primary: #2563eb; }
> // Reference as var(--color-primary) in any CSS
> ```
>
> Biggest challenges:
> 1. Dynamic props: `background: ${p => p.color}` has no
>    CSS Modules equivalent - use CSS custom property.
> 2. Theme access in JS: styled-components `${theme.colors.x}`
>    in template literals - refactor to `var(--x)`.
> 3. Global styles: styled-components `createGlobalStyle` -
>    move to a global CSS file.
>
> *What separates good from great:* Use a codemods approach
> for large codebases. A Babel AST transform can automatically
> extract styled-components templates to CSS Modules files
> for simple cases. For complex dynamic styles, manual
> refactoring is needed. Prioritize high-traffic, performance-
> critical components for migration first.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Runtime vs zero-runtime performance analysis |
| Hiring Manager | Migration strategy and business case |
| Bar Raiser | RSC incompatibility deep-dive |
| Peer Engineer | vanilla-extract vs styled-components DX |

---

### ⚖️ Comparison Table

| Approach | Runtime Cost | TypeScript | RSC Compat | DX |
|---|---|---|---|---|
| CSS Modules | None | Plugin | Yes | Good |
| styled-components v5 | High | Good | No | Excellent |
| styled-components v6 | High | Good | Partial | Good |
| Emotion | Medium | Good | No | Excellent |
| vanilla-extract | None | Excellent | Yes | Good |
| StyleX | None | Excellent | Yes | Good |
| Tailwind | None (utility) | Plugin | Yes | Good |

---

### 🏛️ System Design

*(Omit: ★★☆ working-level - CSS-in-JS at design system
scale covered in L5 Design Systems)*

---

### 📊 Diagram

*(Omit: CSS-in-JS processing pipeline is better described
in text than a static diagram)*
