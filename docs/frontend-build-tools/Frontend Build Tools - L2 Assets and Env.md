---
layout: default
title: "Frontend Build Tools - L2 Assets and Env"
parent: "Frontend Build Tools"
nav_order: 6
permalink: /frontend-build-tools/l2-assets-and-env/
---

# CSS and Static Asset Processing

---

### 🎯 Model Answer

**30 seconds:**

> Build tools process CSS via loaders/plugins: CSS Modules scope
> classnames to prevent collisions, PostCSS runs autoprefixer and
> other transforms, and Sass/Less compile preprocessor syntax. Static
> assets (images, fonts) are either inlined as base64 (small assets)
> or copied with content-hashed filenames for cache busting. In Vite,
> importing an image returns a URL string with the hashed filename.

**Blank Mind Recovery:**

**(1) Restate:** "CSS: modules for scoping, PostCSS for transforms,
preprocessors for syntax. Assets: inline small ones, copy+hash large ones."

---

### 📘 Concept Explanation

**What it is:**

Asset processing transforms non-JavaScript resources (CSS, images,
fonts, SVGs) for browser delivery: scoped CSS classnames, vendor-
prefixed CSS, optimized images with content-hashed filenames.

**The problem it solves:**

Global CSS classnames collide in large apps. CSS vendor prefixes must
be added manually. Images need cache-busting filenames. SVGs should
be inlineable as React components. Build tools solve all of these.

**How it works:**

```
CSS Processing Pipeline:
  .scss file
    -> sass-loader: SCSS -> CSS
    -> postcss-loader: CSS transforms (autoprefixer, etc.)
    -> css-loader: process @import, url()
    -> MiniCssExtractPlugin.loader (prod) OR style-loader (dev)
    -> output: .css file with extracted styles

CSS Modules:
  /* Button.module.css */
  .button { background: blue; }  /* global: .button */
  /* After CSS Modules: */
  .Button_button_a3f9e2 { ... }  /* scoped: hash appended */

  // Button.tsx:
  import styles from './Button.module.css';
  <button className={styles.button}>  /* uses scoped name */
  /* Collision impossible: each file gets unique hash */

PostCSS (postcss.config.js):
  module.exports = {
    plugins: [
      require('autoprefixer'),    // add vendor prefixes
      require('postcss-nested'),  // SCSS-like nesting in CSS
      require('tailwindcss'),     // Tailwind CSS processing
      require('cssnano'),         // minify (production)
    ],
  };

Asset Processing:
  Small images (< threshold): inlined as base64 data URL
    <img src="data:image/png;base64,iVBOR...">
    Saves an HTTP request; increases JS bundle size

  Large images: copied to output with content hash
    src/logo.png -> dist/assets/logo-a3f9e2.png
    <img src="/assets/logo-a3f9e2.png">
    Browser caches with long expiry; hash busts stale cache

  SVG as React component (SVGR):
    import { ReactComponent as Logo } from './logo.svg';
    <Logo className="logo" />  /* SVG inlined in JSX */
```

**The key insight:**

CSS Modules trade one design constraint for another: you lose global
CSS (bad practice anyway) and gain guaranteed class name uniqueness
(essential in component-based architectures). The hash in the classname
is generated from the file path, ensuring uniqueness across modules.

---

### 💻 Code Example

**Example 1: CSS Modules with TypeScript**

```typescript
// Button.module.css
.container {
  display: flex;
  gap: 8px;
}

.button {
  padding: 8px 16px;
  border-radius: 4px;
}

.button--primary { background: #0070f3; color: white; }
.button--secondary { background: transparent; border: 1px solid; }

/* :global() to opt-out of scoping for third-party styles */
:global(.react-tooltip) { z-index: 1000; }

// Button.tsx
import styles from './Button.module.css';

// TypeScript: generate .d.ts for CSS Modules
// via: typed-css-modules or css-modules-typescript-loader
// Button.module.css.d.ts (auto-generated):
// export const container: string;
// export const button: string;
// export const 'button--primary': string;

interface ButtonProps {
  variant: 'primary' | 'secondary';
  children: React.ReactNode;
}

export function Button({ variant, children }: ButtonProps) {
  return (
    <div className={styles.container}>
      <button
        className={`
          ${styles.button}
          ${styles[`button--${variant}`]}
        `}
      >
        {children}
      </button>
    </div>
  );
}
// Rendered HTML: <button class="Button_button_a3f9e2
//                              Button_button--primary_b4f1d3">
```

> **Code walkthrough:** CSS Modules generate unique classnames per
> file, making class name collision impossible. The `styles.button`
> reference becomes the hashed name at build time. TypeScript integration
> (via `typed-css-modules`) generates `.d.ts` files for CSS modules,
> giving you type-checking on style names (typos in classnames become
> compile errors). The `:global()` escape hatch handles third-party
> library styles that expect specific classnames.

**Example 2: Vite asset handling**

```typescript
// Static asset imports in Vite
import logoUrl from './assets/logo.png';
// logoUrl = '/assets/logo-a3f9e2.png' (hashed URL string)
<img src={logoUrl} alt="Logo" />

// Inline as base64 (under threshold):
import tinyIconUrl from './assets/icon.svg?inline';
// Returns data:image/svg+xml;base64,...

// SVG as React component (via @vitejs/plugin-svgr):
import { ReactComponent as Logo } from './assets/logo.svg';
<Logo className="logo" aria-label="Company logo" />

// URL with ?url (always as URL, never inline):
import fileUrl from './assets/data.json?url';

// Raw content as string:
import svgContent from './assets/icon.svg?raw';
// svgContent = '<svg xmlns="..."...'

// webpack equivalent (asset/resource = copy+hash):
// { test: /\.(png|jpg|gif)$/, type: 'asset/resource' }
// { test: /\.svg$/, use: '@svgr/webpack' }  <- SVG as component
```

> **Code walkthrough:** Vite's asset import returns a URL string with
> a content-hashed filename. The URL changes only when the asset
> content changes, enabling long-lived CDN caching. The query suffixes
> (`?raw`, `?url`, `?inline`) are Vite-specific import modifiers that
> change how the asset is processed. SVG as React component via SVGR
> is particularly useful for icons: they can be styled with CSS,
> animated with JavaScript, and are infinitely scalable.

---

### ⚖️ Comparison Table

| CSS approach | Scoping | Build step | Use when |
|---|---|---|---|
| Global CSS | None (collides) | Simple | Landing pages only |
| CSS Modules | File-scoped | Yes | Component libraries, apps |
| CSS-in-JS | Component-scoped | Yes (runtime) | Dynamic styles |
| Tailwind | Utility classes | Yes (purge) | Rapid prototyping |
| Scoped CSS (Vue) | Component-scoped | Yes | Vue projects |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> CSS Modules scope classnames to the file to prevent collisions.
> PostCSS adds autoprefixer and runs Tailwind. Images imported in JS
> get content-hashed filenames. Small assets are inlined as base64.

**Senior / Staff:**

> CSS Modules are my default for component styling. I add TypeScript
> support via typed-css-modules for autocomplete and typo checking.
> For production performance: critical CSS inlining (above-fold styles
> in `<style>` tag), non-critical CSS deferred. Asset strategy: <4KB
> inline, >4KB copy-with-hash. SVGs as React components for icons
> (CSS-styleable, no img request). PostCSS with cssnano for minification.

---

### ⚠️ Common Misconceptions

**Misconception 1: CSS Modules generate different classnames each build.**

CSS Module classnames are deterministic based on the file path and
classname. The same source produces the same output classname (though
the exact format can be configured). Builds are reproducible.

**Misconception 2: Importing an image in JS copies it to the bundle.**

Importing an image returns a URL string. The image file is processed
separately and written to `dist/assets/` with a hashed name. It is
not embedded in the JS bundle (unless it's below the inline threshold).

---

### 🚨 Failure Modes and Diagnosis

**Failure: CSS class not found (styles.x is undefined).**

Cause: Typo in CSS class name; TypeScript won't catch without types.

Fix: Install `typed-css-modules`; run `tcm src --watch` for live updates.

**Failure: Image returns undefined in JS.**

Cause: Wrong file extension in import; or no loader/plugin configured.

Fix: Check extension; for webpack add asset/resource rule; for Vite
confirm file is in `src/` or `public/`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What are CSS Modules? | Definition | ★★☆ | 2 min |
| How do CSS Modules prevent class collisions? | Mechanism | ★★☆ | 2 min |
| What does PostCSS/autoprefixer do? | Definition | ★★☆ | 1 min |
| Why are image filenames hashed? | Mechanism | ★☆☆ | 1 min |
| When is an image inlined vs copied? | Decision | ★★☆ | 2 min |
| CSS Modules vs CSS-in-JS trade-offs? | Comparison | ★★★ | 3 min |
| How to add TypeScript support for CSS Modules? | Scenario | ★★☆ | 2 min |

**Q: CSS Modules vs CSS-in-JS - when do you choose each?**

A: CSS Modules: styles are in `.css` files processed at build time.
Zero runtime overhead. Full CSS language support. Works with PostCSS.
Styles are static (no dynamic JS values in CSS without CSS variables).

CSS-in-JS (styled-components, Emotion): styles written in JavaScript.
Can reference props and component state directly. Runtime style injection
(SSR-compatible via critical CSS extraction). Better TypeScript integration
for prop-based styling.

When to choose CSS Modules: performance-critical applications, server-
rendered apps where runtime CSS injection adds complexity, teams
familiar with CSS, projects using Tailwind alongside.

When to choose CSS-in-JS: component libraries where consumers need to
customize styles via props, highly dynamic themes, React Native sharing,
existing codebase using it.

The trend: CSS-in-JS has faced performance criticism (runtime cost,
SSR complexity). Many teams are moving back to CSS Modules or Tailwind.
Next.js 13+ documentation recommends CSS Modules or Tailwind over
CSS-in-JS for performance reasons.

*What separates good from great:* Understanding CSS Layer (@layer) as
a modern alternative to CSS Modules for ordering specificity without
class name hashing. Still requires some build tooling but keeps CSS
in plain CSS files with modern scoping semantics.

---

# Environment Variables in Build Tools

---

### 🎯 Model Answer

**30 seconds:**

> Build tools replace environment variable references at build time.
> webpack uses `DefinePlugin` to replace `process.env.NODE_ENV` with
> a literal string. Vite uses `import.meta.env.VITE_*`. Variables
> from `.env` files are loaded and injected. Security critical: only
> expose client-safe variables (prefixed `VITE_` or `REACT_APP_`).
> Secret keys must NEVER be in client bundles - they are visible to anyone.

**Blank Mind Recovery:**

**(1) Restate:** "Env vars: build-time replacement. Vite: VITE_ prefix +
import.meta.env. webpack: DefinePlugin + process.env. Never put secrets
in client bundles."

---

### 📘 Concept Explanation

**What it is:**

Environment variables in frontend build tools allow the same codebase
to connect to different API endpoints, feature flags, or configurations
in different environments (dev, staging, production) without code changes.

**The problem it solves:**

Frontend code runs in the browser - it cannot read server-side
environment variables at runtime. Build tools inject variable values
at build time, replacing variable references with literal strings in
the bundle.

**How it works:**

```
.env files (Vite convention):
  .env            <- always loaded (base values)
  .env.local      <- local overrides (gitignored)
  .env.development <- loaded in dev mode
  .env.production  <- loaded in prod build

Vite variable injection:
  # .env.production:
  VITE_API_URL=https://api.example.com
  VITE_STRIPE_KEY=pk_live_...

  # In source:
  const url = import.meta.env.VITE_API_URL;
  // After vite build: const url = "https://api.example.com";
  // (literal string, no variable at runtime)

  # Security: only VITE_* variables are exposed
  DATABASE_URL=postgres://...  # NOT exposed (no VITE_ prefix)
  VITE_PUBLIC_KEY=pk_...       # EXPOSED (prefixed)

webpack DefinePlugin equivalent:
  new webpack.DefinePlugin({
    'process.env.NODE_ENV': JSON.stringify('production'),
    'process.env.REACT_APP_API_URL': JSON.stringify(
      process.env.REACT_APP_API_URL
    ),
    // Only REACT_APP_* exposed (Create React App convention)
  })

  # Source: const url = process.env.REACT_APP_API_URL;
  # Bundle: const url = "https://api.example.com";

Environment-specific configuration:
  Dev:  VITE_API_URL=http://localhost:8080
  Staging: VITE_API_URL=https://staging.api.example.com
  Prod: VITE_API_URL=https://api.example.com
```

**The key insight:**

These values are compiled into the bundle as plain text strings.
Anyone can open DevTools and find them. Never put database passwords,
secret API keys, or private tokens in frontend environment variables.
Use only public-facing values (API URLs, public OAuth client IDs,
feature flags, analytics IDs).

---

### 💻 Code Example

**Example 1: Vite environment variable setup**

```typescript
// .env.development
VITE_API_URL=http://localhost:8080/api
VITE_STRIPE_PUBLIC_KEY=pk_test_...
VITE_FEATURE_NEW_UI=true

// .env.production
VITE_API_URL=https://api.example.com
VITE_STRIPE_PUBLIC_KEY=pk_live_...
VITE_FEATURE_NEW_UI=false

// .env.local (gitignored - personal overrides)
VITE_API_URL=http://localhost:9000/api  # different local port

// TypeScript: define env types for autocomplete + safety
// src/vite-env.d.ts (or src/env.d.ts):
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_STRIPE_PUBLIC_KEY: string;
  readonly VITE_FEATURE_NEW_UI: string; // string, not boolean!
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

// Usage in code:
const apiUrl = import.meta.env.VITE_API_URL;
// TypeScript knows the type; typos cause compile errors

// Feature flags (convert string to boolean):
const showNewUI = import.meta.env.VITE_FEATURE_NEW_UI === 'true';

// BAD: secret in env var
VITE_DATABASE_PASSWORD=secretpassword  // visible to everyone!
// GOOD: only on server (never in client bundle)
```

> **Code walkthrough:** Vite reads `.env` files in priority order:
> `.env.local` overrides `.env`, `.env.production` applies only in
> production builds. The TypeScript `ImportMetaEnv` interface gives
> autocomplete for `import.meta.env.VITE_*` and catches typos at
> compile time. Note that env variables are always strings - `'true'`
> not `true`. Parse to the correct type before using in logic.

**Example 2: Runtime configuration as an alternative**

```typescript
// Alternative to build-time env injection:
// Serve a runtime config file from the server

// public/config.js (served but not bundled):
window.__APP_CONFIG__ = {
  apiUrl: '{{API_URL}}',  // replaced by server/container on startup
  featureFlags: { newUI: true },
};

// In app initialization:
interface AppConfig {
  apiUrl: string;
  featureFlags: Record<string, boolean>;
}

declare global {
  interface Window {
    __APP_CONFIG__: AppConfig;
  }
}

function getConfig(): AppConfig {
  if (!window.__APP_CONFIG__) {
    throw new Error('App config not loaded');
  }
  return window.__APP_CONFIG__;
}

// Usage:
const { apiUrl } = getConfig();
```

> **Code walkthrough:** Runtime config avoids rebuilding for each
> environment. The same Docker image can be deployed to staging and
> production with different `config.js` files injected by the
> deployment system. This is superior for: containerized apps
> (one image, multiple environments), config values that change
> without a code change, and values that cannot be known at build
> time. The trade-off: requires a server to inject the config file;
> cannot use for static sites.

---

### ⚖️ Comparison Table

| Approach | Build-time | Runtime | Rebuild needed | Secrets safe? |
|---|---|---|---|---|
| Vite `import.meta.env` | Yes | No | Yes (per env) | Only if not VITE_ prefixed |
| webpack DefinePlugin | Yes | No | Yes | Only if not REACT_APP_ |
| Runtime config file | No | Yes | No | No (still in browser) |
| Server-side injection | No | Yes | No | Yes (never sent to browser) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Vite reads `.env` files and exposes variables prefixed with `VITE_`
> via `import.meta.env`. Values are replaced at build time. Never put
> secrets in frontend environment variables - they're visible in the
> bundle.

**Senior / Staff:**

> Build-time env vars are compiled into the bundle as plain strings.
> Security boundary: only public-facing values (API URLs, public OAuth
> keys, feature flags). For containerized deployments I prefer runtime
> config injection (serve a `config.js` file from the container) to
> avoid rebuilding per environment. TypeScript `ImportMetaEnv` interface
> gives type safety for env var access. In CI, env vars are sourced
> from the secret store (GitHub Actions secrets, AWS SSM) not .env files.

---

### ⚠️ Common Misconceptions

**Misconception 1: .env.local is ignored in production builds.**

`.env.local` IS loaded in production builds unless explicitly excluded.
It should be gitignored and never committed. Use CI/CD secrets instead.

**Misconception 2: Environment variables with no VITE_ prefix are private.**

Unprefixed variables are simply not injected - they are still readable
by the build process (Node.js). They are not exposed to the browser
bundle, but should still not contain truly sensitive values in CI
pipelines.

---

### 🚨 Failure Modes and Diagnosis

**Failure: API URL points to localhost in production.**

Cause: `.env.local` overrides `.env.production`; local file deployed.

Fix: Never commit `.env.local`; confirm `.gitignore` excludes it.
Use CI secrets for production values.

**Failure: `import.meta.env.VITE_X` is undefined at runtime.**

Cause: Variable not prefixed with `VITE_`; or `.env` file not found.

Diagnose: `console.log(import.meta.env)` to see all exposed vars.
Fix: Add `VITE_` prefix; check `.env` file location (must be in root).

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How do env vars work in Vite vs webpack? | Comparison | ★★☆ | 2 min |
| Why are secrets unsafe in frontend env vars? | Security | ★★☆ | 2 min |
| What env vars should/shouldn't be in the bundle? | Security | ★★☆ | 2 min |
| How to handle per-environment config without rebuilding? | Design | ★★★ | 4 min |
| How to add TypeScript support for Vite env vars? | Scenario | ★★☆ | 2 min |
| What is the .env file loading order in Vite? | Mechanism | ★★☆ | 2 min |
| How to manage env vars in CI/CD? | Scenario | ★★☆ | 3 min |

**Q: How do you manage environment variables in CI/CD securely?**

A: CI/CD secret management separates config from code. Three layers:

Secrets store: all sensitive and environment-specific values live in
the secrets store - GitHub Actions secrets, AWS Parameter Store, Vault,
or Azure Key Vault. Never in code, never in .env files committed to git.

CI pipeline injection: the CI system injects secrets as environment
variables during the build step. GitHub Actions: `${{ secrets.VITE_API_URL }}`.
These are masked in logs and never exposed to pull request runners.

Build-time vs runtime split: for containerized deployments, I only
use build-time env vars for values that don't change per environment
(build timestamp, app version). Everything environment-specific uses
runtime config injection: an init container or startup script writes
a `config.js` file with the correct values for that environment.

Audit trail: secrets stores log every access. This enables auditing
who accessed which secret and when. Hardcoded values have no audit trail.

*What separates good from great:* Knowing that build-time env vars
are visible in the bundle as plaintext strings. Run
`strings dist/main.js | grep your-api-key` to verify no secrets leaked.
This is a simple but critical security check before each production
deploy.
