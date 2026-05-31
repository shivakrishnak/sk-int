---
layout: default
title: "CSS - L2 Custom Properties and Animation"
parent: "CSS"
nav_order: 7
permalink: /css/l2-custom-properties-and-animation/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [CSS Custom Properties (Variables)](#css-custom-properties-variables) | critical |
| 2 | [CSS Transitions and Animations](#css-transitions-and-animations) | high |

---

# CSS Custom Properties (Variables)

🎯 **Interview Weight:** critical - Custom properties are the
foundation of modern CSS design systems; every frontend senior
interview includes theming and custom property scoping questions

---

### 🎯 Model Answer

**30 seconds:**

> CSS custom properties (also called CSS variables) are user-
> defined properties starting with `--`. Set them on any
> element: `--color: blue`. Reference with `var()`: `color:
> var(--color)`. They cascade, inherit, and are scoped to
> the DOM element they're defined on. They enable dynamic
> theming: changing a custom property on `:root` updates
> all components that use it, including via JavaScript.

**3 minutes (Senior):**

> Custom properties follow the CSS cascade - they inherit
> down the DOM tree and can be overridden on any descendant.
> This enables scoped component themes: define `--card-bg` on
> a `.dark-theme` class and all `.card` descendants inherit
> the override.
>
> Unlike Sass variables (compiled away), CSS custom properties
> exist at runtime. JavaScript can read and write them:
> `element.style.setProperty('--color', '#ff0000')` and
> `getComputedStyle(element).getPropertyValue('--color')`.
> This enables animation, user preference application, and
> runtime theming without page reload.
>
> The `var()` function takes a fallback: `var(--color, blue)`.
> If `--color` is not defined, `blue` is used. Fallbacks can
> themselves be `var()`: `var(--primary, var(--blue, #0070f3))`.
>
> Custom properties are type-free by default - they hold
> any CSS value. `@property` (Houdini) declares custom
> properties with types and animation support:
>
> ```css
> @property --hue {
>   syntax: '<number>';
>   initial-value: 0;
>   inherits: false;
> }
> ```
>
> Typed properties can be transitioned and animated. A plain
> `--hue` variable can't be transitioned; a typed `--hue`
> with `syntax: '<number>'` can.

*Adapting up:* Discuss `@property`, registered custom
properties, and CSS Houdini's Property and Value API.

*Adapting down:* CSS variables start with `--`, are set
anywhere, referenced with `var()`, and update all usages
when changed.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS custom properties -
how they work, scope, cascade behavior, and use in design
systems."

**(2) First principles:** "From first principles, a design
system needs reusable named values that can be changed in
one place. CSS custom properties provide named, scoped,
cascade-aware values that components can reference."

**(3) Bridge:** "Think of custom properties like environment
variables. You set them in a parent context; children read
them. Override the parent variable and all children get the
new value automatically."

---

### 📘 Concept Explanation

**What it is:**

CSS author-defined properties, declared with `--property-name:
value`, referenced with `var(--property-name)`. They cascade,
inherit, and are scoped to the DOM subtree of the declaring
element.

**The problem it solves:**

Maintaining consistency across a large codebase where the
same color, spacing, or timing appears in hundreds of rules.
Without custom properties: global find-replace for color
changes. With custom properties: update one value, all usages
update automatically.

**How it works:**

```
DECLARATION:
  element { --property-name: value; }
  :root { --primary: #2563eb; } /* global scope */
  .card { --card-bg: #f8fafc; } /* scoped to .card */

REFERENCE:
  color: var(--primary);
  background: var(--card-bg, #fff); /* with fallback */
  font-size: calc(var(--base-size) * 1.25);

INHERITANCE:
  :root sets --color: blue
    .parent reads --color → blue
      .child reads --color → blue (inherited)
        .child { --color: red; }
          .grandchild reads --color → red (overridden)

JAVASCRIPT INTERACTION:
  # Read:
  getComputedStyle(el).getPropertyValue('--color')
  # Set inline:
  el.style.setProperty('--color', '#ff0000')
  # Remove:
  el.style.removeProperty('--color')

@PROPERTY (typed, Houdini):
  @property --progress {
    syntax: '<number>';
    initial-value: 0;
    inherits: false;
  }
  /* Can be animated/transitioned - plain vars cannot */

CSS VALUES:
  var() accepts any valid CSS value including:
    - colors, lengths, percentages
    - shorthand fragments: var(--border) in border: 1px solid var(--border)
    - calc() contexts: calc(var(--base) * 2)
    - NOT property names, selectors, at-rules
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**

Custom properties ARE NOT replaced at compile time (unlike Sass
variables). They exist in the CSS cascade at runtime, are
inspectable in DevTools, and are dynamic. Setting a custom
property value via JavaScript or a new CSS rule triggers an
instant re-render of all elements that depend on it.

**When to use it:**

- Design tokens (colors, spacing, typography)
- Component theming and dark mode
- Dynamic values that change based on user interaction
- Computed values using `calc(var(...))`
- Reducing repetition of magic values

**When NOT to use it:**

When values are truly static and used in one place - a custom
property just adds indirection. When the property is used
in a Sass or PostCSS build process where compile-time
variables are sufficient.

**Alternatives:**

- Sass variables (`$color: blue`) - compile-time, no runtime
- CSS `@layer` with custom defaults
- CSS-in-JS (design token injection at runtime)

**First-principles derivation:**

CSS rules need shared values. Without named values, every rule
with the same color is independently maintained. Custom
properties provide scoped, inherited named values that follow
the cascade, enabling single-point-of-truth updates throughout
a DOM subtree.

---

### 💻 Code Example

**BAD: repeated color values**

```css
/* BAD: color repeated everywhere */
.btn-primary { background: #2563eb; color: white; }
.link { color: #2563eb; }
.heading { border-bottom: 2px solid #2563eb; }
.badge { background: #2563eb; }
/* Change blue to another color: 50+ replacements */
```

> **Code walkthrough:** Magic number repetition makes
> global changes error-prone. A brand color change requires
> finding every instance - often missing some. This is
> especially fragile in large codebases where different
> developers write different files.

**GOOD: design token custom properties**

```css
/* GOOD: single source of truth */
:root {
  --color-primary: #2563eb;
  --color-primary-hover: #1d4ed8;
  --color-text: #0f172a;
  --color-surface: #f8fafc;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 2rem;
  --radius: 0.375rem;
  --transition: 0.15s ease;
}

.btn-primary {
  background: var(--color-primary);
  color: white;
  padding: var(--space-sm) var(--space-md);
  border-radius: var(--radius);
  transition: background var(--transition);
}
.btn-primary:hover {
  background: var(--color-primary-hover);
}
.link { color: var(--color-primary); }
.heading {
  border-bottom: 2px solid var(--color-primary);
}
```

> **Code walkthrough:** `--color-primary` is the single
> source of truth. Update it once, all usages update.
> The dark mode override is trivial: `@media (prefers-
> color-scheme: dark) { :root { --color-primary: #60a5fa; } }`.
> No component-level changes needed.

**PRODUCTION: component theming with scoped overrides**

```css
/* Component defines its own property contracts */
.card {
  --card-bg: var(--color-surface, #fff);
  --card-border: var(--color-border, #e2e8f0);
  --card-text: var(--color-text, #0f172a);

  background: var(--card-bg);
  border: 1px solid var(--card-border);
  color: var(--card-text);
  border-radius: var(--radius, 0.375rem);
  padding: var(--space-md, 1rem);
}

/* Theme override - no component CSS changes */
.card--dark {
  --card-bg: #1e293b;
  --card-border: #334155;
  --card-text: #f1f5f9;
}

/* Danger variant via property override */
.card--danger {
  --card-border: #ef4444;
  --card-bg: #fef2f2;
}
```

> **Code walkthrough:** The card defines its own "API"
> via custom properties. Variants don't change the card's
> structure - they only override the property values.
> A `.card--dark` class only sets variables; the card's
> structural CSS remains unchanged. This pattern makes
> theming and variants extremely lightweight and
> predictable.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CSS custom properties let you name values and reuse them.
> Define `--color: blue` on `:root`, reference it as `color:
> var(--color)` anywhere. Change it in one place, all
> references update. They're great for colors, spacing, and
> font sizes. The `var()` function takes an optional
> fallback: `var(--color, blue)` uses blue if `--color`
> isn't defined.

---

**Senior / Staff (5+ years):**

> Custom properties are the CSS runtime token system. Unlike
> Sass, they exist at runtime and can be modified by
> JavaScript or CSS overrides. This enables component
> contracts - a button's `--btn-bg` can be set globally
> for theming but overridden locally for variants.
>
> The scoping model is powerful: `.dark-theme { --color-bg:
> #0f172a }` automatically dark-themes all children.
>
> `@property` (now in all major browsers) enables typed
> custom properties that can be transitioned - enabling
> complex animations like CSS-only gradient transitions
> that were impossible before.

---

### ⚠️ Common Misconceptions

**"Custom properties work in attribute selectors"**

`[data-color="var(--primary)"]` doesn't work. Custom
properties in `var()` can only be used as CSS value
replacements, not in selector strings or attribute values.

**"Custom properties can hold property names"**

`var(--display-type)` cannot be used as: `var(--display-type):
flex`. Custom properties hold values, not property names.

**"Fallback in var() works like a default everywhere"**

Fallback in `var(--x, blue)` only applies if `--x` is not
defined in the cascade. If `--x` is defined as `invalid`,
the fallback is NOT used - the property receives its
initial value instead.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: var() shows inherited value instead of expected**

Cause: custom property is defined on ancestor, overridden
elsewhere in the cascade.

```
# DevTools: select element > Computed tab
# Expand the property using var() → hover reveals variable
# Click variable name → Styles tab shows where it's set
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

**Symptom: dark mode custom property not applying**

Check: `:root` specificity vs element override specificity.
`[data-theme="dark"]` on `<html>` has higher specificity
than `:root`. Source order also matters - `[data-theme]`
rule must come AFTER the base `:root` rule.

---

**Symptom: calc() with custom property returns NaN/invalid**

```css
/* FAIL: var() without unit */
:root { --size: 16; }
font-size: calc(var(--size) * 1px); /* works */
font-size: calc(var(--size) px); /* FAIL: space before unit */

/* CORRECT: unit in the variable or multiply */
:root { --size: 16px; }
font-size: var(--size); /* direct use */
/* or */
:root { --size: 16; }
font-size: calc(var(--size) * 1px); /* multiply by unit */
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Explain custom properties | 3 min | Cascade + runtime |
| vs Sass variables | 3 min | Compile vs runtime |
| Dark mode implementation | 4 min | Property overrides |
| Component theming pattern | 4 min | Scoped overrides |
| JS interaction | 3 min | setProperty/getComputedStyle |
| @property typed vars | 3-4 min | Animation support |
| Fallback behavior | 2-3 min | Undefined vs invalid |
| Debugging custom properties | 3 min | DevTools inspection |
| Design token architecture | 4 min | Token layers |

---

**Q1: How do CSS custom properties cascade?** `[MID]`
MECHANISM

*Why they ask:* Cascade behavior is what makes custom
properties different from simple string substitution.

*Likely follow-up:* "How does inheritance differ from
specificity here?"

> **Answer:**
>
> Custom properties follow the standard CSS cascade:
> specificity and source order determine which declaration
> wins. The winning value is then inherited by all
> descendant elements.
>
> ```css
> :root { --color: blue; }
>
> .parent { --color: green; } /* specificity: 0,1,0 */
>
> /* In the DOM: */
> /* <div class="parent">     --color: green */
> /*   <p>text</p>            --color: green (inherited) */
> /*   <p class="override">   --color: ??? */
> /* </div>                                */
>
> .override { --color: red; } /* wins on .override element */
> ```
>
> Cascade order:
> 1. `!important` declarations (all cascade layers)
> 2. Normal declarations (by specificity)
> 3. Inherited value from parent
> 4. Initial value (custom properties have no real initial
>    value - they're "unset" until declared)
>
> Critical distinction: inheritance vs cascade.
> - Cascade: which declaration applies to THIS element
>   (by specificity/source order)
> - Inheritance: if no declaration matches, use parent's
>   computed value
>
> Custom properties inherit by default (like `color` does).
> `@property { inherits: false; }` makes a typed property
> non-inheriting.
>
> *What separates good from great:* An unset custom property
> is NOT the same as a property set to `initial`. An unset
> custom property makes `var(--x)` evaluate to the fallback
> (if provided) or to the property's initial value. A custom
> property set to `invalid` (e.g., `--color: ;` an empty
> value) causes `var(--color)` to use the property's initial
> value, NOT the fallback. This is a subtle but important
> distinction.

---

**Q2: How do you use custom properties for dark mode?**
`[MID]` PRODUCTION

*Why they ask:* Dark mode is now expected; proper
implementation tests understanding of the token model.

*Likely follow-up:* "How do you support both OS preference
and manual toggle?"

> **Answer:**
>
> ```css
> /* Light mode tokens (default) */
> :root {
>   --bg: #ffffff;
>   --text: #0f172a;
>   --surface: #f8fafc;
>   --primary: #2563eb;
>   --border: #e2e8f0;
> }
>
> /* OS-level dark mode override */
> @media (prefers-color-scheme: dark) {
>   :root {
>     --bg: #0f172a;
>     --text: #f1f5f9;
>     --surface: #1e293b;
>     --primary: #60a5fa;
>     --border: #334155;
>   }
> }
>
> /* Manual toggle override (beats OS preference) */
> [data-theme="light"] {
>   --bg: #ffffff;
>   --text: #0f172a;
>   --surface: #f8fafc;
>   --primary: #2563eb;
>   --border: #e2e8f0;
> }
> [data-theme="dark"] {
>   --bg: #0f172a;
>   --text: #f1f5f9;
>   --surface: #1e293b;
>   --primary: #60a5fa;
>   --border: #334155;
> }
>
> /* Components only use tokens, never raw colors */
> .card {
>   background: var(--surface);
>   color: var(--text);
>   border: 1px solid var(--border);
> }
> ```
>
> JavaScript toggle:
> ```javascript
> const toggleDark = () => {
>   const current = document.documentElement
>     .getAttribute('data-theme');
>   document.documentElement.setAttribute(
>     'data-theme',
>     current === 'dark' ? 'light' : 'dark'
>   );
>   localStorage.setItem('theme',
>     document.documentElement.getAttribute('data-theme')
>   );
> };
> ```
>
> On page load (in `<head>` before first paint):
> ```javascript
> const saved = localStorage.getItem('theme');
> if (saved) {
>   document.documentElement.setAttribute('data-theme', saved);
> }
> ```
>
> *What separates good from great:* The `data-theme`
> attribute on `<html>` has higher specificity than `:root`
> pseudo-class when both use class-level selectors. BUT
> `[data-theme]` attribute selectors have the same
> specificity (0,1,0) as `:root` (pseudo-class). Source order
> determines the winner - `[data-theme]` MUST come AFTER
> `:root` in the stylesheet.

---

**Q3: How do CSS custom properties interact with
JavaScript?** `[MID]` MECHANISM

*Why they ask:* JS-CSS interaction via custom properties
is a key pattern for reactive styling.

*Likely follow-up:* "How do you animate a custom property
value?"

> **Answer:**
>
> Reading a custom property from JavaScript:
> ```javascript
> // Computed value (after cascade resolution)
> const value = getComputedStyle(element)
>   .getPropertyValue('--my-property')
>   .trim();
> // Note: getPropertyValue is used (not style.cssText)
> ```
>
> Setting a custom property:
> ```javascript
> // Inline style (highest specificity in cascade)
> element.style.setProperty('--my-property', '42px');
>
> // On document root (global):
> document.documentElement.style.setProperty(
>   '--primary', '#ff0000'
> );
> ```
>
> Removing (restores cascade value):
> ```javascript
> element.style.removeProperty('--my-property');
> ```
>
> Practical example - user-controlled theme:
> ```javascript
> // User picks a custom accent color
> const picker = document.getElementById('color-picker');
> picker.addEventListener('input', (e) => {
>   document.documentElement.style.setProperty(
>     '--color-primary', e.target.value
>   );
> });
> ```
>
> This instantly updates every element using
> `var(--color-primary)` - no DOM manipulation, no class
> toggling, no JavaScript-managed styles.
>
> Animation: plain custom properties (without `@property`)
> cannot be interpolated (animated). The browser can't
> know if `--x` goes from "10" to "20" linearly. Use
> `@property` with `syntax: '<number>'` to enable animation:
>
> ```css
> @property --progress {
>   syntax: '<number>';
>   initial-value: 0;
>   inherits: false;
> }
> .bar {
>   transition: --progress 0.5s ease;
>   width: calc(var(--progress) * 1%);
> }
> ```
>
> *What separates good from great:* `getComputedStyle`
> returns the COMPUTED value including the cascade resolution.
> `element.style.getPropertyValue('--x')` returns only the
> inline style value, not the inherited or cascaded value.
> Use `getComputedStyle` to see what the element actually
> "sees."

---

**Q4: What is `@property` and why does it matter?**
`[SENIOR]` MECHANISM

*Why they ask:* `@property` is the Houdini API in production;
senior candidates should know it.

*Likely follow-up:* "Can you give a real use case for
animating a custom property?"

> **Answer:**
>
> `@property` registers a custom property with type information,
> an initial value, and inheritance behavior. It's part of
> the CSS Houdini Properties and Values API Level 1, now
> supported in all major browsers (Chrome 85+, Safari 16.4+,
> Firefox 128+).
>
> ```css
> @property --hue {
>   syntax: '<number>';
>   initial-value: 220;
>   inherits: false;
> }
>
> @property --gradient-angle {
>   syntax: '<angle>';
>   initial-value: 0deg;
>   inherits: false;
> }
> ```
>
> Without `@property`: plain `--hue` has no type. CSS can't
> interpolate between `--hue: 220` and `--hue: 360` because
> it doesn't know they're numbers.
>
> With `@property { syntax: '<number>' }`: CSS knows `--hue`
> is a number. It can be transitioned and animated:
>
> ```css
> .hue-shift {
>   background: hsl(var(--hue) 70% 50%);
>   transition: --hue 0.5s ease;
> }
> .hue-shift:hover { --hue: 360; }
> /* Smoothly transitions through hue values */
> ```
>
> Real use case - animated gradient:
> ```css
> @property --angle {
>   syntax: '<angle>';
>   initial-value: 0deg;
>   inherits: false;
> }
> @keyframes rotate-gradient {
>   to { --angle: 360deg; }
> }
> .gradient-card {
>   background: conic-gradient(
>     from var(--angle),
>     #2563eb,
>     #7c3aed,
>     #2563eb
>   );
>   animation: rotate-gradient 3s linear infinite;
> }
> /* Smoothly rotating gradient - impossible without @property */
> ```
>
> *What separates good from great:* `syntax` values include:
> `'<color>'`, `'<length>'`, `'<number>'`, `'<percentage>'`,
> `'<angle>'`, `'<time>'`, `'<integer>'`, `'*'` (any).
> For complex values: `'<color>+'` (space-separated list).
> The `initial-value` is required when `inherits: false`
> so the browser knows the starting value.

---

**Q5: How do you debug a CSS custom property that isn't
working?** `[MID]` DEBUGGING

*Why they ask:* Custom property debugging requires specific
DevTools knowledge.

*Likely follow-up:* "What does the DevTools Computed tab
show for custom properties?"

> **Answer:**
>
> Step 1: Open DevTools, select the element, go to the
> Computed tab. Search for the property using `var()`. Hover
> over the `var()` value - it shows the resolved custom
> property name and current value.
>
> Step 2: Click the custom property name in the Computed tab
> to jump to the Styles tab where it's defined.
>
> Step 3: In the Styles tab, check the cascade. Custom
> properties show with their declarations in specificity
> order. Struck-through declarations are overridden.
>
> Common failure scenarios:
>
> 1. Property not defined at all: `var(--x)` shows as
>    fallback or property's initial value.
>    Fix: define `--x` in the cascade (often forgot to add
>    to `:root`).
>
> 2. Property defined too specifically:
>    `.card { --color: blue }` only applies inside `.card`.
>    Elements outside `.card` don't have `--color`.
>
> 3. Typo in property name: `--colour` vs `--color`.
>    CSS doesn't warn about undefined custom properties.
>    Fix: check spelling in both declaration and usage.
>
> 4. Invalid value set via JavaScript:
>    `el.style.setProperty('--count', NaN)` - inspect
>    the element's inline styles to verify the value.
>
> 5. @media override not applying:
>    Check if the `@media` block surrounds the variable
>    declaration, not just a `var()` usage.
>
> *What separates good from great:* In Chrome DevTools,
> custom properties defined on an element appear in the
> Styles panel under the `element.style` section if set
> via JavaScript. They also appear in each rule that sets
> them. The Computed tab shows the FINAL resolved value
> after all cascade resolution.

---

**Q6: How do custom properties compare to Sass variables?**
`[SENIOR]` COMPARISON

*Why they ask:* Candidates often use both; understanding
the distinction shows depth.

*Likely follow-up:* "When would you use both in the
same project?"

> **Answer:**
>
> Sass variables (`$color: blue`) are compile-time constructs.
> They're replaced with their literal value during the
> Sass-to-CSS compilation step. The resulting CSS has no
> variables - just literal values.
>
> CSS custom properties are runtime. They exist in the
> browser's CSSOM, can change dynamically, and follow
> the cascade.
>
> Key differences:
>
> | Aspect | Sass Variable | CSS Custom Property |
> |---|---|---|
> | Exists at runtime | No | Yes |
> | Cascades and inherits | No | Yes |
> | JS readable/writable | No | Yes |
> | Conditionally overridable | No (unless in media query) | Yes (any selector) |
> | Animatable | No | With @property |
> | Scope | Block scope (Sass) | CSS cascade scope |
> | DevTools visible | No (compiled away) | Yes |
>
> When to use both: Sass variables for build-time values
> (breakpoints, compile-time calculations, mixin parameters),
> CSS custom properties for runtime tokens (colors, spacing,
> themes).
>
> ```scss
> // Sass: breakpoints are build-time only
> $breakpoint-md: 768px;
> @mixin tablet { @media (min-width: $breakpoint-md) { @content; } }
>
> // CSS custom property: colors are runtime tokens
> :root { --color-primary: #2563eb; }
> ```
>
> *What separates good from great:* Sass variables can
> compile to CSS custom properties: `$color: var(--primary)`.
> This gives you Sass's compile-time validation AND CSS's
> runtime flexibility. Tailwind CSS v3+ takes this approach
> internally.

---

**Q7: What is the design token architecture for custom
properties?** `[STAFF]` ARCHITECTURE

*Why they ask:* Senior/Staff candidates are expected to
know token systems at scale.

*Likely follow-up:* "What are tier-1 vs tier-2 tokens?"

> **Answer:**
>
> Design token architecture uses a three-tier system:
>
> Tier 1 (Primitive tokens): Raw values with no semantic
> meaning. The palette.
> ```css
> :root {
>   --color-blue-50: #eff6ff;
>   --color-blue-500: #3b82f6;
>   --color-blue-700: #1d4ed8;
>   --space-1: 0.25rem;
>   --space-4: 1rem;
>   --space-8: 2rem;
> }
> ```
>
> Tier 2 (Semantic tokens): Reference tier-1 tokens,
> provide semantic meaning. The design decisions.
> ```css
> :root {
>   --color-primary: var(--color-blue-500);
>   --color-primary-hover: var(--color-blue-700);
>   --color-surface: white;
>   --color-text: var(--color-slate-900);
>   --space-component-padding: var(--space-4);
> }
> ```
>
> Tier 3 (Component tokens): Component-specific overrides.
> ```css
> .button {
>   --btn-bg: var(--color-primary);
>   --btn-color: white;
>   --btn-padding: var(--space-component-padding);
>   background: var(--btn-bg);
>   color: var(--btn-color);
>   padding: var(--btn-padding);
> }
> ```
>
> Dark mode only overrides tier-2 semantic tokens:
> ```css
> @media (prefers-color-scheme: dark) {
>   :root {
>     --color-primary: var(--color-blue-400);
>     --color-surface: var(--color-slate-900);
>   }
> }
> ```
>
> Primitive tokens never change. Semantic tokens change
> for themes. Component tokens change for variants.
>
> *What separates good from great:* Token Studio (Figma
> plugin) and the W3C Design Tokens Community Group spec
> standardize the JSON format for design tokens. Tools
> like Style Dictionary transform token JSON to CSS custom
> properties, Sass variables, iOS swift, Android XML, and
> more. This creates a single source of truth in the design
> tool that feeds all platforms.

---

**Q8: Implement a user-customizable color theme using
custom properties.** `[SENIOR]` HANDS-ON

*Why they ask:* End-to-end design + implementation test.

*Likely follow-up:* "How do you persist the user's choice?"

> **Answer:**
>
> ```css
> /* Base tokens */
> :root {
>   --hue: 220; /* base hue - user controls this */
>   --color-primary: hsl(var(--hue) 80% 50%);
>   --color-primary-light: hsl(var(--hue) 80% 95%);
>   --color-primary-dark: hsl(var(--hue) 80% 30%);
> }
>
> /* Components use semantic tokens, never raw hsl() */
> .btn {
>   background: var(--color-primary);
>   color: white;
> }
> .badge {
>   background: var(--color-primary-light);
>   color: var(--color-primary-dark);
> }
> ```
>
> JavaScript:
> ```javascript
> // Read saved preference
> const savedHue = localStorage.getItem('theme-hue');
> if (savedHue) {
>   document.documentElement.style
>     .setProperty('--hue', savedHue);
> }
>
> // User changes color
> document.getElementById('hue-picker')
>   .addEventListener('input', (e) => {
>     const hue = e.target.value;
>     document.documentElement.style
>       .setProperty('--hue', hue);
>     localStorage.setItem('theme-hue', hue);
>   });
> ```
>
> One variable (`--hue`) controls the entire color scheme.
> `hsl()` derives primary, light, and dark variants from
> the same hue with different lightness/saturation values.
>
> For multi-color themes: expand to `--hue-primary: 220;
> --hue-accent: 160;` etc.
>
> *What separates good from great:* Check contrast ratios
> when the user picks a custom hue. `color-contrast()` (CSS
> Level 6 proposal) would handle this natively, but for now
> use a JavaScript contrast checker. Prevent saving a hue
> that results in WCAG-failing text contrast against white
> backgrounds. This is a safety net for accessibility.

---

**Q9: What are the performance implications of custom
properties?** `[SENIOR]` PRODUCTION

*Why they ask:* Shows understanding of browser rendering
pipeline.

*Likely follow-up:* "Does changing a custom property
on :root trigger layout?"

> **Answer:**
>
> Custom properties and the rendering pipeline:
>
> 1. Style recalculation: when a custom property changes,
>    all elements that use `var(--changed-prop)` must
>    recalculate their styles. This triggers "style
>    invalidation."
>
> 2. Layout vs paint vs composite:
>    - If the custom property changes a `color` or
>      `background`: paint only (no layout)
>    - If it changes `width`, `padding`, `font-size`: layout
>      (expensive - reflow)
>    - If it changes `transform` or `opacity`: composite
>      only (cheap - GPU)
>
> 3. Changing `:root` custom property recalculates styles
>    for all elements that directly or indirectly use it -
>    potentially the ENTIRE DOM.
>
> Performance best practices:
>
> ```css
> /* CHEAP: composite-only property changes */
> @property --opacity {
>   syntax: '<number>';
>   initial-value: 1;
>   inherits: false;
> }
> .fade {
>   opacity: var(--opacity);
>   /* Opacity is composited - no layout or paint */
>   transition: --opacity 0.3s;
> }
>
> /* EXPENSIVE: layout-affecting changes */
> .panel {
>   height: calc(var(--panel-size) * 1px);
>   /* Avoid animating - causes layout reflow */
> }
> ```
>
> For animation: prefer custom properties that affect
> `transform`, `opacity`, or `filter` (compositor properties).
> Avoid animating properties that cause layout (height,
> width, padding).
>
> *What separates good from great:* DevTools Performance
> panel shows "Style Recalculation" events. Changing
> `--color-primary` on `:root` appears as a large style
> recalculation if thousands of elements use it. Mitigate
> by scoping: `[data-theme="dark"]` triggers recalculation
> only for descendant elements, not the entire document.
> For most UIs this is imperceptible but matters for
> very large DOM trees (virtual scroll lists, data grids).

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Cascade mechanics + @property |
| Hiring Manager | Dark mode and design system value |
| Bar Raiser | Token architecture three-tier model |
| Peer Engineer | Debugging pattern with DevTools |

---

### ⚖️ Comparison Table

| Feature | CSS Custom Properties | Sass Variables |
|---|---|---|
| Exists at runtime | Yes | No (compiled) |
| DevTools visible | Yes | No |
| JS interaction | Yes (read/write) | No |
| Cascade and inherit | Yes | No |
| Animatable | With @property | No |
| Theming support | Native | Requires compile step |
| Browser support | All modern | Requires build tool |
| Fallback values | var(--x, default) | Default in $variable |

---

### 🏛️ System Design

*(Omit: ★★☆ working-level - design token systems at scale
covered in L5 Design Systems)*

---

### 📊 Diagram

*(Omit: custom property cascade is best shown with code
examples, which are provided above)*

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


# CSS Transitions and Animations

🎯 **Interview Weight:** high - Animations are tested in
UI-heavy roles; performance implications (janky animations
triggering layout) distinguish seniors; GSAP vs CSS
animation trade-offs appear in senior interviews

---

### 🎯 Model Answer

**30 seconds:**

> CSS transitions animate a property from one value to
> another triggered by a state change (`:hover`, class add).
> CSS animations use `@keyframes` to define multi-step motion
> independent of state changes. For both, performance matters:
> stick to `transform` and `opacity` (GPU-composited).
> Layout-affecting properties (`width`, `height`) trigger
> reflow and cause jank.

**3 minutes (Senior):**

> Transitions: `transition: property duration timing-function
> delay`. The browser interpolates between the start and end
> values when the property changes. `transition: all` is
> convenient but performance-dangerous - it will also
> transition any accidental property changes.
>
> Animations: `@keyframes name { from {} to {} }` or with
> percentage stops. Applied via `animation: name duration
> timing-function delay iteration fill-mode`. `animation-
> fill-mode: forwards` keeps the final keyframe state after
> the animation ends. Without it, the element snaps back.
>
> Performance: `transform` and `opacity` are handled by the
> GPU compositor - they don't trigger layout or paint.
> `width`, `height`, `top`, `left`, `margin` trigger
> layout reflow, which recalculates positions of potentially
> ALL elements. `color`, `background-color` trigger paint
> without layout.
>
> For JavaScript-driven animations: Web Animations API
> (`element.animate()`) runs on the compositor thread,
> same performance as CSS transitions. GSAP uses this
> internally for modern browsers.
>
> `will-change: transform` promotes an element to its own
> GPU layer BEFORE the animation starts, avoiding the first-
> frame jitter. But overusing `will-change` consumes GPU
> memory - don't apply to hundreds of elements.

*Adapting up:* `@property` typed custom properties for
complex animated values; View Transitions API for page transitions.

*Adapting down:* transitions animate property changes;
keyframe animations run automatically; both need transform
and opacity for smooth performance.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS transitions and
animations - the syntax, timing functions, and performance
rules."

**(2) First principles:** "From first principles, animation
is interpolating values over time. CSS transitions define
HOW a property change is interpolated. Keyframes define
WHAT values to interpolate THROUGH."

**(3) Bridge:** "Transitions are reactive (respond to state
changes). Animations are proactive (run on their own
timeline). Use transitions for UI feedback, animations for
motion design."

---

### 📘 Concept Explanation

**What it is:**

CSS transitions: smooth interpolation of a property value
over time when the value changes due to a state change.
CSS animations: multi-step, timeline-controlled property
changes defined in `@keyframes`, independent of external
state changes.

**The problem it solves:**

Communicating system state changes to users (hover feedback,
modal open/close), guiding attention (entrance animations),
and communicating hierarchy (loading indicators).

**How it works:**

```
TRANSITION SYNTAX:
  transition: <property> <duration> [<timing>] [<delay>]

  transition: color 0.2s ease;
  transition: all 0.3s ease; /* all properties */
  transition: color 0.2s, transform 0.3s;  /* multiple */

TRANSITION PROPERTIES:
  transition-property: color, transform
  transition-duration: 0.2s, 0.3s
  transition-timing-function: ease | linear | ease-in |
    ease-out | ease-in-out | cubic-bezier(x1,y1,x2,y2) |
    steps(n, start|end)
  transition-delay: 0s, 0.1s

KEYFRAME ANIMATION SYNTAX:
  @keyframes slide-in {
    from { transform: translateX(-100%); opacity: 0; }
    to   { transform: translateX(0);    opacity: 1; }
  }

  /* Multiple stops */
  @keyframes pulse {
    0%   { transform: scale(1); }
    50%  { transform: scale(1.05); }
    100% { transform: scale(1); }
  }

ANIMATION PROPERTIES:
  animation: <name> <duration> <timing> <delay>
    <iteration> <direction> <fill-mode> <play-state>

  animation: slide-in 0.4s ease-out;
  animation: pulse 1s ease-in-out infinite;
  animation-fill-mode: none | forwards | backwards | both
  animation-direction: normal | reverse | alternate
  animation-play-state: running | paused

PERFORMANCE TIERS:
  Composite (GPU, no layout):
    transform: translate(), scale(), rotate(), skew()
    opacity
    filter (most functions)
    will-change (promotes element, use sparingly)

  Paint (no layout):
    color, background-color, border-color
    box-shadow, text-shadow

  Layout (expensive - avoid animating):
    width, height, padding, margin
    top, left, right, bottom (when not position:fixed)
    font-size, line-height
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**

Animating `transform: translateX(-100%)` is free (GPU-
composited, no layout). Animating `left: -100%` causes
reflow on every frame. These look the same to the user
but have vastly different performance implications. Always
use `transform` for positional animation.

**When to use transitions:**

State-change feedback (hover, focus, active), toggle
animation (show/hide), responsive state changes.

**When to use animations:**

Loading indicators, entrance animations, continuous motion,
multi-step sequences, motion that runs on page load.

**When NOT to use either:**

When `prefers-reduced-motion: reduce` is active. Always
implement reduced-motion alternatives.

**Alternatives:**

- JavaScript `element.animate()` (Web Animations API): same
  performance, JavaScript-controllable
- GSAP: production motion library, superior sequencing
- Framer Motion (React): declarative animation

**First-principles derivation:**

User interfaces communicate through change. Motion guides
attention, confirms actions, and communicates state. CSS
transitions and animations are the browser's built-in
motion primitives. The GPU compositor thread runs them
independently from JavaScript, enabling smooth 60fps
animation even when the main thread is busy.

---

### 💻 Code Example

**BAD: animating layout-triggering properties**

```css
/* BAD: layout-triggering animation */
.drawer {
  width: 0;
  overflow: hidden;
  transition: width 0.3s ease; /* triggers layout! */
}
.drawer.open {
  width: 280px;
}
/* Every frame: browser recalculates layout of ALL siblings */
/* Causes jank on complex pages */
```

> **Code walkthrough:** Animating `width` triggers layout
> recalculation on every frame (60 frames/sec). The browser
> must recalculate positions of all elements affected by the
> drawer's changing width. On complex pages this causes
> dropped frames and jank.

**GOOD: GPU-composited animation**

```css
/* GOOD: transform-based animation */
.drawer {
  transform: translateX(-280px);
  transition: transform 0.3s ease-out;
  will-change: transform; /* pre-promote to GPU layer */
}
.drawer.open {
  transform: translateX(0);
}
/* Only the drawer's layer moves on GPU */
/* Zero layout recalculation */
```

> **Code walkthrough:** `transform: translateX()` runs
> entirely on the GPU compositor thread. No layout
> recalculation. The drawer appears to slide but no DOM
> positions change. `will-change: transform` promotes the
> element to its own GPU layer BEFORE the transition starts,
> eliminating the initial-frame promote cost.

**PRODUCTION: loading spinner + reduced motion**

```css
@keyframes spin {
  to { transform: rotate(360deg); }
}

.spinner {
  width: 1.5rem;
  height: 1.5rem;
  border: 2px solid var(--color-border, #e2e8f0);
  border-top-color: var(--color-primary, #2563eb);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
  will-change: transform;
}

/* Respect reduced motion - still show indicator */
@media (prefers-reduced-motion: reduce) {
  .spinner {
    animation: none;
    border-top-color: var(--color-primary, #2563eb);
    /* Shows a static indicator - no motion */
  }
}
```

> **Code walkthrough:** The spinner uses `transform: rotate`
> via the `to {}` keyframe shorthand (equivalent to `from {
> transform: rotate(0deg) } to { ... }`). It's GPU-composited,
> runs independently of main thread. The reduced-motion
> override disables the spinning but keeps the visual
> indicator present - the user still sees "loading" but
> without the rotational motion that could cause vestibular
> discomfort.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CSS transitions animate property changes using the
> `transition` property: `transition: background 0.3s ease`.
> When the background color changes (e.g., on `:hover`), it
> smoothly interpolates. For multi-step animation, use
> `@keyframes` and the `animation` property. The key
> performance rule: animate `transform` and `opacity`
> (GPU-composited, smooth). Avoid animating `width`,
> `height`, or `top/left` (triggers layout reflow).

---

**Senior / Staff (5+ years):**

> The performance model is critical. `transform` and `opacity`
> are composited by the GPU - independent of the main thread.
> Everything else either triggers layout or paint, both
> running on the main thread.
>
> `will-change` is a hint to the browser to promote an
> element to its own compositor layer BEFORE animation.
> Without it, the first frame of a transform animation
> has a promote cost. But `will-change` consumes GPU memory
> - use it only on elements actively animating, not globally.
>
> For complex motion design: GSAP is the industry standard.
> It uses the Web Animations API internally (same GPU
> performance), provides superior easing functions,
> sequencing, and timeline control that pure CSS can't match.
> The View Transitions API (Chrome 111+) handles page-level
> transitions with native browser performance.

---

### ⚠️ Common Misconceptions

**"`transition: all` is convenient and harmless"**

`transition: all` intercepts ALL property changes including
ones you don't intend to animate. If JavaScript adds a class
that changes 10 properties, all 10 transition. Including
layout-affecting ones. Use explicit property lists.

**"CSS animations run on the GPU always"**

Only `transform` and `opacity` are guaranteed compositor-
thread. Everything else (including `filter` in some cases)
may fall back to main-thread painting. Check with DevTools
Layers panel.

**"`will-change: transform` on all animated elements
is best practice"**

`will-change` creates a new compositor layer consuming GPU
VRAM. Applying it to hundreds of cards or list items exhausts
GPU memory causing performance degradation worse than not
using it. Apply only to elements actively animating, remove
after animation ends.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: animation is janky (dropping frames)**

```
# Chrome DevTools: Performance panel
# Record while animation plays
# Look for:
#   Long tasks (>50ms) on main thread during animation
#   "Layout" or "Paint" events in compositor thread
#   Frame rate drops in FPS graph
# Fix: identify which CSS property triggers layout/paint
# Replace with transform equivalent
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

**Symptom: animation restarts on page visibility restore**

Cause: browsers pause animations when tab is hidden
(performance optimization). On return, animation resumes
from paused state.

```css
/* Handle visibility change in JS if needed */
document.addEventListener('visibilitychange', () => {
  const animEls = document.querySelectorAll('.animated');
  animEls.forEach(el => {
    el.style.animationPlayState =
      document.hidden ? 'paused' : 'running';
  });
});
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

**Symptom: animation-fill-mode: forwards still not
keeping final state**

Cause: specificity conflict. Another rule is overriding
the final keyframe value after animation ends.

Check: the final keyframe's properties vs other rules
targeting the same element. `animation-fill-mode: forwards`
has lower specificity than explicitly set properties.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Transition vs Animation | 2-3 min | Reactive vs proactive |
| GPU-composited properties | 3 min | transform + opacity |
| will-change correct use | 3-4 min | Use sparingly |
| animation-fill-mode | 2-3 min | forwards keeps state |
| Timing function comparison | 3 min | ease vs linear |
| Reduced motion handling | 3-4 min | prefers-reduced-motion |
| Debug janky animation | 3-4 min | DevTools Performance |
| CSS vs GSAP trade-off | 3-4 min | When each is better |
| View Transitions API | 3 min | Page-level transitions |

---

**Q1: What CSS properties can be smoothly animated?**
`[JUNIOR]` MECHANISM

*Why they ask:* Foundation for animation performance knowledge.

*Likely follow-up:* "Why is animating height a problem?"

> **Answer:**
>
> Not all CSS properties can be animated. The browser
> needs to know how to interpolate between two values.
>
> Animatable: properties with discrete intermediate values.
> All length properties (px, em, %): `width`, `height`,
> `top`, `margin`, `padding`. Color properties: `color`,
> `background-color`, `border-color`. `transform`,
> `opacity`, `filter`, `font-size`, `line-height`.
>
> Not animatable: `display` (block vs flex is discrete,
> no intermediate state), `font-family` (strings), `position`
> (static/relative/absolute/fixed are discrete).
>
> For display toggle: `display: none` prevents all
> transitions. Use `opacity: 0` + `pointer-events: none`
> for "visible but not interactive," or `visibility: hidden`
> (which CAN transition).
>
> ```css
> /* Animate opacity for show/hide */
> .modal { opacity: 0; visibility: hidden;
>          transition: opacity 0.3s, visibility 0.3s; }
> .modal.open { opacity: 1; visibility: visible; }
> /* visibility transition: element becomes invisible
>    only AFTER opacity transitions to 0 */
> ```
>
> Performance tiers (as covered elsewhere): transform +
> opacity = GPU compositor. Everything else = main thread.
>
> *What separates good from great:* The FLIP technique
> (First, Last, Invert, Play) enables smooth layout-based
> animations without animating layout. Record element
> position (First), change layout (Last), invert using
> transform to start at the First position (Invert),
> then animate transform back to zero (Play). GSAP's
> `.from()` and Web Animations API support this pattern.

---

**Q2: What is `animation-fill-mode` and what does
`forwards` do?** `[JUNIOR]` MECHANISM

*Why they ask:* `fill-mode` is commonly forgotten but
critical for entrance animations.

*Likely follow-up:* "What does `both` do?"

> **Answer:**
>
> `animation-fill-mode` controls whether an animation applies
> its keyframe styles OUTSIDE the animation's active time
> (before it starts or after it ends).
>
> `none` (default): before start = no keyframe styles applied.
> After end = element snaps back to pre-animation state.
>
> `forwards`: after the animation ends, the element KEEPS
> the styles from the last keyframe. Essential for entrance
> animations where the final position should remain.
>
> ```css
> @keyframes fade-in {
>   from { opacity: 0; transform: translateY(20px); }
>   to   { opacity: 1; transform: translateY(0); }
> }
>
> .card {
>   animation: fade-in 0.5s ease-out forwards;
>   /* Without 'forwards': card snaps back to transparent+shifted */
>   /* With 'forwards': card stays at final opacity:1, translated:0 */
> }
> ```
>
> `backwards`: during the delay period before the animation
> starts, apply the FIRST keyframe styles. Useful when
> there's a delay: the element starts at the initial keyframe
> state before the animation begins.
>
> `both`: apply `backwards` before start AND `forwards`
> after end. Most useful for entrance animations with delays.
>
> ```css
> .stagger-item {
>   animation: fade-in 0.4s ease-out both;
>   animation-delay: calc(var(--index) * 0.1s);
>   /* 'both': hidden (from opacity:0) during delay */
>   /* then fades in, then stays visible (forwards) */
> }
> ```
>
> *What separates good from great:* `animation-fill-mode:
> forwards` can cause unexpected behavior in re-used
> animation states. If you animate OUT an element and
> want to animate it IN again, you need to reset the
> animation. Set `animation: none` first (to clear the
> filled-forward state), then re-apply the animation.

---

**Q3: How do you implement a staggered list entrance
animation?** `[SENIOR]` HANDS-ON

*Why they ask:* Staggered animations are common UI patterns;
the CSS approach shows knowledge of custom properties and
animations.

*Likely follow-up:* "How do you do this without JavaScript?"

> **Answer:**
>
> Pure CSS approach using custom property for index:
>
> ```css
> @keyframes fade-up {
>   from {
>     opacity: 0;
>     transform: translateY(16px);
>   }
>   to {
>     opacity: 1;
>     transform: translateY(0);
>   }
> }
>
> .list-item {
>   animation: fade-up 0.4s ease-out both;
>   /* Custom property as delay multiplier */
>   animation-delay: calc(var(--index, 0) * 80ms);
> }
>
> /* Pure CSS: target nth-child */
> .list-item:nth-child(1) { --index: 0; }
> .list-item:nth-child(2) { --index: 1; }
> .list-item:nth-child(3) { --index: 2; }
> .list-item:nth-child(4) { --index: 3; }
> .list-item:nth-child(5) { --index: 4; }
> ```
>
> JavaScript approach (for dynamic lists):
>
> ```javascript
> document.querySelectorAll('.list-item')
>   .forEach((item, index) => {
>     item.style.setProperty('--index', index);
>   });
> ```
>
> ```css
> .list-item {
>   animation: fade-up 0.4s ease-out both;
>   animation-delay: calc(var(--index, 0) * 80ms);
> }
> ```
>
> The JavaScript version is dynamic (works for any number
> of items), cleaner for generated content. The pure CSS
> version works without JavaScript but requires writing
> nth-child rules for each item position.
>
> Reduced motion:
> ```css
> @media (prefers-reduced-motion: reduce) {
>   .list-item {
>     animation: none;
>     opacity: 1;
>   }
> }
> ```
>
> *What separates good from great:* `animation-fill-mode: both`
> (not `forwards`) keeps items at `opacity: 0` during their
> delay period so they don't appear briefly before animating.
> Without `backwards` (part of `both`), items 2-5 flash
> at full opacity during their delay before the animation
> begins.

---

**Q4: When do you use CSS animations vs JavaScript
animation libraries?** `[SENIOR]` TRADE-OFF

*Why they ask:* Shows judgment about tooling choices.

*Likely follow-up:* "What does GSAP provide that CSS doesn't?"

> **Answer:**
>
> CSS animations are the right choice when:
>
> 1. Simple transitions: single-property state change
>    (hover effects, show/hide)
> 2. Looping indicators: spinners, pulse, progress bars
> 3. Entrance/exit animations: straightforward `@keyframes`
> 4. Reduced-motion support is easily handled in CSS
> 5. No JavaScript dependency desired (performance-critical
>    path, accessibility-first)
>
> JavaScript animation (GSAP, Web Animations API) wins when:
>
> 1. Complex sequences: "after X ends, start Y with different
>    easing, then trigger Z." CSS has no sequencing primitives.
>
> 2. Physics-based motion: spring animations, inertia.
>    CSS timing functions are cubic bezier only.
>
> 3. SVG path animation, morphing, draw effects:
>    GSAP's SVG tools handle this with minimal code.
>
> 4. Scroll-linked animation: GSAP ScrollTrigger handles
>    progress-linked animations that are complex in CSS.
>
> 5. Dynamic values: GSAP animates based on computed
>    positions, sizes read at runtime.
>
> 6. Stagger with complex timing: `gsap.from('.item',
>    { opacity: 0, stagger: 0.1 })` - one line.
>
> GSAP performance: GSAP's `gsap.to()` uses CSS transforms
> internally (compositor thread) when possible. For complex
> stagger timelines it's actually faster than multiple
> CSS animation declarations.
>
> *What separates good from great:* The Web Animations API
> (`element.animate()`) provides the performance of CSS
> animations with JavaScript control. For most GSAP-worthy
> use cases in modern browsers, WAAPI is sufficient without
> the 35KB dependency. GSAP is the choice when WAAPI lacks
> specific features (complex stagger, scroll triggers,
> SVG morphing, compatibility back to IE11).

---

**Q5: What is `will-change` and when should you use it?**
`[SENIOR]` PRODUCTION

*Why they ask:* Overuse/misuse of `will-change` is a
real production problem.

*Likely follow-up:* "What are the costs of `will-change`?"

> **Answer:**
>
> `will-change: transform` is a performance hint telling
> the browser "this element is about to animate - optimize
> for it." The browser creates a new compositor layer for
> the element.
>
> Benefit: when animation starts, the element is already
> on its own GPU layer. No promotion cost on the first
> frame. Eliminates "flash of unpromoted layer" on complex
> pages.
>
> ```css
> /* CORRECT: applied to elements that actively animate */
> .animated-card {
>   will-change: transform;
>   /* Applied when animation is imminent */
> }
>
> /* Remove after animation completes */
> .animated-card.done {
>   will-change: auto;
>   /* Returns element to normal layer management */
> }
> ```
>
> Costs:
> 1. GPU VRAM consumption: each `will-change` element
>    occupies GPU memory. On mobile devices with limited
>    VRAM, too many promoted layers causes GPU memory
>    pressure and worse performance than not using it.
>
> 2. Visual artifacts: compositor layers may affect rendering
>    of z-index and opacity of siblings.
>
> 3. Compositing itself has overhead: the browser must
>    composite all layers on every frame, even un-animated
>    ones.
>
> Rules:
> - Apply only when animation is imminent, not globally
> - Remove with `will-change: auto` when done
> - Never apply to hundreds of elements simultaneously
> - Prefer `transform` over `will-change` when possible
>   (transforms are GPU even without will-change)
>
> Modern guidance: start without `will-change`. Add it
> only if DevTools shows a performance problem on the
> first animation frame. Most animations run fine without it.
>
> *What separates good from great:* `will-change: transform`
> creates a stacking context (like `position: relative` +
> `z-index`). This changes how z-index works for children
> and siblings. Pages with complex z-index layouts may show
> unexpected stacking order changes when `will-change` is
> added.

---

**Q6: How do you animate an element entering and
leaving the DOM?** `[SENIOR]` HANDS-ON

*Why they ask:* Enter/leave animations require coordination
between CSS and JavaScript.

*Likely follow-up:* "How does React handle this?"

> **Answer:**
>
> Entering the DOM: add a class on insertion.
>
> ```css
> @keyframes fade-in {
>   from { opacity: 0; transform: scale(0.95); }
>   to   { opacity: 1; transform: scale(1); }
> }
> .item-enter { animation: fade-in 0.3s ease-out both; }
> ```
>
> Leaving the DOM (harder - element must remain until
> animation finishes):
>
> ```css
> @keyframes fade-out {
>   to { opacity: 0; transform: scale(0.95); }
> }
> .item-exit {
>   animation: fade-out 0.3s ease-in forwards;
>   pointer-events: none;
> }
> ```
>
> ```javascript
> function removeWithAnimation(element) {
>   element.classList.add('item-exit');
>   element.addEventListener('animationend', () => {
>     element.remove();
>   }, { once: true });
> }
> ```
>
> The element must stay in the DOM while the exit animation
> plays. `animationend` event fires when the animation
> completes; only then remove the element.
>
> React/framework approach: React Transition Group or
> Framer Motion handle this automatically by deferring
> unmounting until exit animation completes.
>
> Native: View Transitions API (Chrome 111+) handles
> enter/leave transitions with browser-level support:
> ```javascript
> document.startViewTransition(() => {
>   // DOM change happens here
>   element.remove();
>   // Browser automatically creates cross-fade
> });
> ```
>
> *What separates good from great:* `{ once: true }` in
> `addEventListener` automatically removes the event
> listener after it fires once. Forgetting this leaks
> event listeners. For multiple removals, the listener
> builds up. Always clean up animation event listeners.

---

**Q7: Debug a CSS animation that isn't playing.**
`[MID]` DEBUGGING

*Why they ask:* Animation debugging is a practical daily
skill.

*Likely follow-up:* "What does `animation-play-state:
paused` do by accident?"

> **Answer:**
>
> Systematic diagnosis:
>
> Step 1: DevTools Elements panel > select element >
> check Computed tab for `animation-name`. If it shows
> `none`, the animation property isn't applied. Check
> specificity - another rule may override it.
>
> Step 2: DevTools Animations panel (Chrome: More Tools >
> Animations). Shows all running animations, their timing,
> and allows pause/scrub. If the animation appears but
> looks wrong, scrub the timeline to see each frame.
>
> Step 3: Check `@keyframes` name match. The name in
> `animation: <name>` must exactly match the name after
> `@keyframes`. CSS is case-sensitive for animation names.
>
> Step 4: Check `animation-fill-mode`. If it's `none`
> (default) and the animation duration has passed, the
> element is back at its original state. It may have played
> and you missed it.
>
> Step 5: Check `animation-duration`. Default is `0s` -
> animation completes instantly. Must set a duration.
>
> Step 6: Check `prefers-reduced-motion` override in
> DevTools: Rendering > Emulate CSS media feature.
> Toggle to `reduce` to see if your CSS disables it.
>
> Common surprise: `animation-play-state: paused` is
> sometimes set accidentally by JavaScript that pauses
> animations. Check element's computed `animation-play-state`.
>
> *What separates good from great:* The Animations panel
> in DevTools allows you to scrub animations frame by
> frame and change their speed (0.1x for slow-motion
> debugging). This is invaluable for timing issues.
> Additionally, `element.getAnimations()` returns all
> active Animation objects on an element, including their
> state and current time.

---

**Q8: What is the View Transitions API?** `[SENIOR]`
MECHANISM

*Why they ask:* Modern browser API that changes page
transition patterns.

*Likely follow-up:* "What was required before for page
transitions?"

> **Answer:**
>
> The View Transitions API (Chrome 111+, Safari 18+,
> Firefox behind flag as of 2024) provides browser-native
> page transition animations using a two-phase approach:
>
> ```javascript
> // Trigger a transition
> document.startViewTransition(() => {
>   // Perform DOM update
>   document.querySelector('.page').innerHTML = newContent;
>   // Or: in a SPA, navigate to next view
> });
> ```
>
> What the browser does:
> 1. Captures a snapshot of the current state (old state)
> 2. Performs your DOM change
> 3. Captures new state
> 4. Cross-fades between old and new in an overlay layer
>    (separate from page content)
>
> By default: simple cross-fade. Customizable with CSS:
>
> ```css
> /* Customize the transition animation */
> ::view-transition-old(root) {
>   animation: slide-out 0.3s ease-in forwards;
> }
> ::view-transition-new(root) {
>   animation: slide-in 0.3s ease-out both;
>   animation-delay: 0.2s;
> }
>
> /* Named transitions for specific elements */
> .hero-image {
>   view-transition-name: hero;
> }
> /* The hero image morphs between old and new positions */
> ::view-transition-group(hero) {
>   animation-duration: 0.5s;
>   animation-timing-function: ease-in-out;
> }
> ```
>
> Before View Transitions: page transitions in SPAs
> required complex JavaScript (GSAP, custom JS to snapshot
> old page, render new page in overlay, transition between
> them). Fraught with edge cases.
>
> *What separates good from great:* `view-transition-name`
> on matching elements in the old and new DOM enables FLIP-
> style shared element transitions - the browser morphs
> the element's position and size between the old and new
> locations. This creates the "shared element transition"
> (like Android's Activity transition) natively, without
> JavaScript measurement.

---

**Q9: Implement a progress bar animation for loading.**
`[MID]` HANDS-ON

*Why they ask:* Real component implementation test.

*Likely follow-up:* "How do you make this accessible?"

> **Answer:**
>
> ```css
> /* DETERMINATE: known progress value */
> .progress-bar {
>   height: 4px;
>   background: var(--color-surface, #e2e8f0);
>   border-radius: 2px;
>   overflow: hidden;
>   position: relative;
> }
>
> .progress-fill {
>   height: 100%;
>   background: var(--color-primary, #2563eb);
>   border-radius: 2px;
>   transition: width 0.3s ease;
>   width: var(--progress, 0%);
>   /* CSS custom property drives the progress */
> }
>
> /* INDETERMINATE: unknown progress */
> @keyframes indeterminate {
>   0%   { transform: translateX(-100%) scaleX(0.3); }
>   50%  { transform: translateX(0%) scaleX(0.7); }
>   100% { transform: translateX(100%) scaleX(0.3); }
> }
>
> .progress-bar--indeterminate .progress-fill {
>   width: 100%;
>   animation: indeterminate 1.5s ease-in-out infinite;
>   transform-origin: left center;
> }
>
> /* Reduced motion */
> @media (prefers-reduced-motion: reduce) {
>   .progress-bar--indeterminate .progress-fill {
>     animation: none;
>     width: 40%;
>     margin: 0 auto; /* static indicator */
>   }
> }
> ```
>
> JavaScript: update progress:
> ```javascript
> function setProgress(percent) {
>   document.querySelector('.progress-fill')
>     .style.setProperty('--progress', `${percent}%`);
> }
> ```
>
> Accessibility:
> ```html
> <div class="progress-bar" role="progressbar"
>      aria-valuenow="0" aria-valuemin="0"
>      aria-valuemax="100" aria-label="Loading...">
>   <div class="progress-fill"></div>
> </div>
> ```
>
> Update `aria-valuenow` as progress changes. For
> indeterminate: set `aria-valuenow` to omitted or use
> `aria-valuetext="Loading"`.
>
> *What separates good from great:* Using a CSS custom
> property (`--progress`) allows smooth animated transitions
> between progress values. Setting `--progress: 75%` and
> the fill has a `transition: width 0.3s` automatically
> animates from the current to new value. JavaScript only
> needs to update the variable, not manage the animation.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | GPU compositor vs layout tier |
| Hiring Manager | when CSS vs GSAP is right choice |
| Bar Raiser | View Transitions API and FLIP |
| Peer Engineer | reduced-motion accessibility |

---

### ⚖️ Comparison Table

| Feature | CSS Transition | CSS Animation | Web Animations API | GSAP |
|---|---|---|---|---|
| Trigger | State change | Auto / JS | JS | JS |
| Sequencing | No | Limited (delays) | Timeline (basic) | Full timeline |
| Physics (spring) | No | No | No | Yes (GSAP Flip) |
| Performance | Same (GPU for transform) | Same | Same | Same |
| Dependency | None | None | None | 35KB library |
| Learning curve | Low | Medium | Medium | Medium |

---

### 🏛️ System Design

*(Omit: ★★☆ working-level - CSS animation architecture at
scale covered in L5 Design Systems)*

---

### 📊 Diagram

*(Omit: animation timing is better understood through code
examples than static diagrams)*

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



