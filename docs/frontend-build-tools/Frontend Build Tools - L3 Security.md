---
layout: default
title: "Frontend Build Tools - L3 Security"
parent: "Frontend Build Tools"
nav_order: 9
permalink: /frontend-build-tools/l3-security/
render_with_liquid: false
---

# Supply Chain Security (npm audit, lockfiles, provenance)

---

### 🎯 Model Answer

**30 seconds:**

> Supply chain attacks target your dependencies, not your code.
> `npm audit` detects known vulnerabilities in installed packages.
> Committed lockfiles ensure reproducible installs (preventing
> dependency confusion attacks). Package provenance (npm > 9.5)
> cryptographically links a published package to its source repository
> and CI build. Defense in depth: audit in CI, pin deps via lockfile,
> verify provenance for critical packages.

**Blank Mind Recovery:**

**(1) Restate:** "Supply chain security: audit for CVEs, lockfile for
reproducibility, provenance to verify package origin."

---

### 📘 Concept Explanation

**What it is:**

Supply chain security for frontend projects focuses on protecting
the npm dependency chain: detecting vulnerable packages, ensuring
dependency reproducibility, and verifying package authenticity.

**The problem it solves:**

The 2021 `ua-parser-js` compromise, the `colors`/`faker` malicious
update, and the `event-stream` attack all show that popular npm
packages can be compromised. Supply chain attacks can inject malicious
code into millions of applications through a single package.

**How it works:**

```
Attack vectors:

1. Vulnerable dependency (CVE in package)
   Detection: npm audit, Snyk, Dependabot alerts
   Fix: npm audit fix, version pinning, alternative package

2. Typosquatting (malicious package with similar name)
   Example: 'lodahs' instead of 'lodash'
   Prevention: verify package name before install, use scoped packages

3. Dependency confusion (internal package name hijacked on npm)
   Prevention: .npmrc with scoped registry; private registry mirroring

4. Compromised maintainer account (supply chain injection)
   Prevention: lockfile (hash verification), provenance attestation

5. Postinstall scripts (arbitrary code execution during npm install)
   Risk: packages with postinstall scripts run arbitrary code
   Mitigation: npm install --ignore-scripts (carefully)

Defense layers:
  npm audit:
    Checks installed packages against npm Advisory Database (OSV)
    npm audit --audit-level=critical  # only fail on critical
    npm audit fix                     # auto-update patch versions
    npm audit fix --force             # update across major versions

  Lockfile security:
    package-lock.json includes: package hashes (integrity field)
    npm verifies hash on install - detects tampering
    ALWAYS commit lockfile and verify it hasn't changed unexpectedly

  Provenance attestation (npm >= 9.5):
    npm publish --provenance
    Links package to: source repo, workflow, commit SHA
    Consumers can verify: 'this package was built from github.com/...'
    npm info <package>  # shows provenance info
    View at: npmjs.com/package/<name>
```

**The key insight:**

`npm ci` (not `npm install`) verifies package integrity hashes
from the lockfile. This is a defense against supply chain attacks
where a package registry serves different content for the same version.
The lockfile's `integrity` field is the fingerprint.

---

### 💻 Code Example

**Example 1: npm audit in CI with fail conditions**

```yaml
# .github/workflows/security.yml
name: Security Audit

on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with: { node-version: 20 }
      - run: npm ci

      # Fail on high or critical vulnerabilities:
      - name: Audit production dependencies
        run: npm audit --audit-level=high --omit=dev
        # --omit=dev: only check production deps
        # --audit-level=high: fail on high+critical only

      # Report dev dependency issues (don't fail):
      - name: Audit dev dependencies
        run: npm audit --audit-level=critical || true
        # Dev vulns reported but not blocking (lower risk)
```

```bash
# Local audit workflow:
npm audit                          # full report
npm audit --audit-level=critical   # only critical

# Auto-fix (safe: patch versions only):
npm audit fix

# Check what would be updated:
npm outdated

# Fix a specific vulnerability (manual):
npm install some-package@^4.0.0    # update to safe version

# When audit fix breaks things (major version bump):
# 1. Review the changelog for breaking changes
# 2. Test the updated version
# 3. Either update calling code or pin to safe version
```

> **Code walkthrough:** Separating production and dev audit levels
> reflects risk difference: production deps run in users' browsers;
> dev deps run only in CI. A critical vulnerability in ESLint (dev
> dep) is less urgent than one in a production auth library. The `||
> true` allows dev audit failures to report without blocking the build,
> while production audit failures block deployment.

**Example 2: Lockfile integrity verification**

```bash
# Check package integrity in lockfile:
cat package-lock.json | jq '
  .packages["node_modules/react"] | {version, integrity}
'
# {
#   "version": "18.2.0",
#   "integrity": "sha512-/3IjMdb2L9QbBdWiW5e3P2/npwMBaU9mHCSCUzNln0ZCYbcfTsGbTJrU/kGemdH2IWmB2ioZ+zkxtmq6g09fgQ=="
# }

# npm ci verifies this integrity on every install
# Tampered package: npm ci FAILS with integrity mismatch

# Detect unexpected lockfile changes in CI:
- name: Verify lockfile unchanged
  run: |
    npm ci
    # If someone changed package.json without updating lockfile:
    # npm ci fails with: "npm ci can only install packages when
    # your package.json and package-lock.json are in sync"

# Audit lockfile changes in PR reviews:
# Any change to package-lock.json should be reviewed for:
# - Expected version updates (matches package.json change?)
# - Unexpected additions (new transitive deps?)
# - Integrity hash changes (package content changed?)
```

> **Code walkthrough:** The `integrity` field in package-lock.json is
> a SHA-512 hash of the package content. When `npm ci` runs, it verifies
> each installed package matches the lockfile hash. This is why `npm ci`
> is secure: even if a malicious actor replaced the package on the
> registry with the same version number, the content hash would differ
> and the install would fail. Always use `npm ci` in production builds.

---

### ⚖️ Comparison Table

| Threat | Prevention | Tooling |
|---|---|---|
| Known CVE in dep | npm audit / Dependabot | Automated |
| Typosquatting | Manual name verification | Code review |
| Dependency confusion | .npmrc scoped registry | Configuration |
| Compromised package | Lockfile integrity (npm ci) | Process |
| Compromised maintainer | Provenance attestation | npm >= 9.5 |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `npm audit` checks for known vulnerabilities in dependencies.
> `npm audit fix` updates packages to safe versions. In CI, I run
> `npm audit --audit-level=high` to fail builds with critical issues.
> The lockfile ensures reproducible installs.

**Senior / Staff:**

> Supply chain security requires multiple layers: audit in CI for
> CVEs, lockfile integrity via `npm ci` for tamper detection, Dependabot
> for automated updates, and package provenance for high-assurance
> environments. I separate production and dev audit levels in CI:
> production deps use `--audit-level=high`, dev deps are reported but
> not blocking. For internal tools, I use a private registry (Artifactory,
> Verdaccio) with allowlist to prevent dependency confusion attacks.

---

### ⚠️ Common Misconceptions

**Misconception 1: npm audit catches all supply chain attacks.**

npm audit only catches known CVEs (publicly reported vulnerabilities).
A zero-day compromise (unknown at audit time), typosquatting, or
dependency confusion bypasses npm audit entirely.

**Misconception 2: Pinning exact versions in package.json prevents attacks.**

Pinning only pins direct dependencies. Transitive dependencies still
resolve dynamically unless the lockfile is committed and `npm ci` is used.

---

### 🚨 Failure Modes and Diagnosis

**Failure: npm audit finds vulnerability, `npm audit fix` breaks the app.**

Cause: Fix requires a major version bump with breaking changes.

Fix: Pin to last safe version (check vulnerability advisory for
patched version); evaluate alternative package.

**Failure: Dependency confusion attack via private package name.**

Cause: Internal package name `@company/utils` published to public npm.

Fix: Configure `.npmrc` to always use private registry for scoped
packages: `@company:registry=https://registry.company.com`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is a supply chain attack? | Definition | ★★☆ | 2 min |
| What does npm audit detect (and not detect)? | Mechanism | ★★☆ | 2 min |
| Why does npm ci protect against supply chain attacks? | Mechanism | ★★☆ | 2 min |
| What is dependency confusion? | Definition | ★★★ | 2 min |
| How to secure a private npm registry? | Design | ★★★ | 3 min |
| What is npm provenance attestation? | Definition | ★★☆ | 2 min |
| How do you handle npm audit fix breaking changes? | Scenario | ★★☆ | 3 min |

**Q: Explain dependency confusion and how to prevent it.**

A: Dependency confusion is an attack where a public package name
shadows an internal package name. If an internal package is named
`@mycompany/utils` and the attacker publishes a malicious package
with the same name to the public npm registry at a higher version,
npm may install the public malicious package instead of the internal one.

This works because npm resolves packages across both the private and
public registries, and the highest version wins.

Prevention:

Scoped registry configuration: in `.npmrc`, pin all internal scopes
to the private registry: `@mycompany:registry=https://registry.mycompany.com`.
npm then only looks at the private registry for `@mycompany/*` packages.

Name reservation: register internal package names on public npm
(even as empty/private packages) to prevent name squatting.

`publishConfig` in package.json: set `"publishConfig": {"registry":
"https://registry.mycompany.com"}` to prevent accidental public publish.

The npm provenance system partially mitigates this: consumers can
verify the package's source repository. A malicious lookalike package
would not have provenance from the legitimate organization.

*What separates good from great:* The Solarwinds-style attack (injecting
code during the build process) is harder to prevent with just npm
security. Defense in depth: restrict what CI can write to the registry,
sign releases with OIDC tokens (npm provenance), monitor for unexpected
package uploads, and review all dependencies added in PRs.

---

# Build-time Security and CSP Integration

---

### 🎯 Model Answer

**30 seconds:**

> Build tools can integrate with Content Security Policy (CSP) to
> prevent XSS attacks. The challenge: CSP requires allowing specific
> script sources, but build tools generate inline scripts (for HMR,
> `<style>` injection). Solution: generate nonces at build time
> (webpack nonce plugin), extract all CSS to separate files (no inline
> styles), and use `script-src 'nonce-{random}'` instead of
> `'unsafe-inline'`.

**Blank Mind Recovery:**

**(1) Restate:** "Build-time security: avoid unsafe-inline in CSP.
Use nonces for scripts, extract CSS to files, avoid eval in source maps."

---

### 📘 Concept Explanation

**What it is:**

Build-time security addresses security concerns introduced by the
build process itself: inline scripts that violate CSP, eval-based
source maps, environment variable exposure, and generated code that
creates security risks.

**The problem it solves:**

webpack-dev-server uses `eval()` for fast source maps (`eval-source-map`).
MiniCssExtract removes inline styles. HMR injects inline scripts.
Without careful configuration, the build output makes it harder to
implement strict CSP.

**How it works:**

```
CSP conflict with build tools:
  webpack devtool: 'eval-source-map'
    -> uses eval() for source maps
    -> requires: script-src 'unsafe-eval'
    -> CSP violation: allows arbitrary eval

  style-loader (dev):
    -> injects inline <style> tags
    -> requires: style-src 'unsafe-inline'
    -> CSP violation

  HMR runtime (webpack/Vite dev):
    -> injects inline scripts
    -> requires: script-src 'unsafe-inline'
    -> Only in development (acceptable)

Build-time CSP solutions:

1. Source map approach:
  Development: eval-source-map (fast, requires unsafe-eval in dev)
  Production:  source-map (external .map files, no eval)
  -> separate CSP for dev/prod environments is acceptable

2. CSS: always extract in production
  MiniCssExtractPlugin: CSS in separate .css files (no inline)
  -> No style-src 'unsafe-inline' needed in production

3. Nonce-based CSP for dynamic scripts:
  Server generates random nonce per request
  <script nonce="abc123" src="...">
  CSP: script-src 'nonce-abc123'
  webpack: __webpack_nonce__ = window.__csp_nonce;
  HtmlWebpackPlugin: inject nonce into generated tags

4. Hash-based CSP for static inline scripts:
  sha256-<hash> allows specific inline scripts by content hash
  webpack-subresource-integrity: generates integrity hashes
  -> Works for static scripts but not dynamic content
```

**The key insight:**

Production and development CSP requirements differ. Development uses
`unsafe-eval` and `unsafe-inline` for DX (fast HMR). Production must
not. Never use the development webpack config in production - the CSP
violations are a symptom of a misconfigured build.

---

### 💻 Code Example

**Example 1: Production-safe source maps and CSS**

```javascript
// webpack.prod.js - CSP-compatible production config

module.exports = merge(base, {
  // PRODUCTION source maps: external files, no eval
  devtool: 'source-map',
  // BAD for prod: devtool: 'eval-source-map' (requires unsafe-eval)
  // BAD for prod: devtool: 'cheap-eval-source-map'
  // GOOD for prod: 'source-map' (external .map files)
  //                'hidden-source-map' (no sourceMappingURL comment)

  module: {
    rules: [
      {
        test: /\.css$/,
        // PRODUCTION: extract to separate file (no inline)
        use: [MiniCssExtractPlugin.loader, 'css-loader'],
        // BAD for prod: style-loader (injects inline <style>)
      },
    ],
  },

  // Subresource Integrity for CDN-served assets:
  output: {
    crossOriginLoading: 'anonymous', // needed for SRI
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: './public/index.html',
    }),
    // SRI: adds integrity="sha384-..." to <script> and <link> tags
    // Browsers verify hash before executing
    new SubresourceIntegrityPlugin({
      hashFuncNames: ['sha384'],
      enabled: true,
    }),
  ],
});
```

> **Code walkthrough:** The source map choice is a security/DX balance.
> In production, `source-map` generates external `.map` files without
> `eval()`. `hidden-source-map` is stricter - it generates `.map` files
> but doesn't add the `//# sourceMappingURL` comment to JS files,
> preventing browser DevTools from automatically loading them (useful
> when source maps are served to a private error monitoring service).
> Subresource Integrity (SRI) adds a cryptographic hash to script tags,
> preventing CDN compromise from serving malicious JS.

**Example 2: Environment variable security audit**

```bash
# Security check: verify no secrets in bundle
# Run after production build

# Check for common secret patterns:
grep -r 'sk_live_\|sk_test_\|SECRET\|password\|private' \
  dist/assets/*.js

# Check specific env var was NOT included:
grep -r 'DATABASE_URL\|PRIVATE_KEY' dist/assets/*.js
# Should return nothing

# Check which env vars ARE in the bundle:
grep -r 'import.meta.env\.' dist/assets/*.js |
  grep -oP 'VITE_\w+' | sort -u

# Expected output: only public vars:
# VITE_API_URL
# VITE_STRIPE_PUBLIC_KEY
# NOT: VITE_DATABASE_URL (should never be in bundle)

# Vite: by default, only VITE_ prefixed vars are included
# Verify none of your VITE_ vars contain secrets

# In CI: add as a mandatory security check step
- name: Check for secrets in bundle
  run: |
    if grep -r 'sk_live_\|SECRET_' dist/; then
      echo "SECRET DETECTED IN BUNDLE!"
      exit 1
    fi
```

> **Code walkthrough:** The post-build secret scan is a safety net:
> even if a developer accidentally adds `VITE_` prefix to a secret,
> the CI step catches it before deploy. Pattern matching for `sk_live_`
> (Stripe live secret key prefix) and common naming conventions catches
> most accidents. This is defense-in-depth: the primary protection is
> "never prefix secrets with VITE_", but the scan catches mistakes.

---

### ⚖️ Comparison Table

| devtool value | eval? | Speed | Security | Use when |
|---|---|---|---|---|
| `eval-source-map` | Yes | Fast | Low (unsafe-eval) | Development only |
| `source-map` | No | Slow | High | Production |
| `hidden-source-map` | No | Slow | Highest | Prod (private maps) |
| `nosources-source-map` | No | Medium | High | Prod (no source in map) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> In production, I use `devtool: 'source-map'` (external files, no eval).
> CSS is extracted with MiniCssExtractPlugin (no inline styles).
> I never put secret API keys in VITE_ env variables - they're visible
> in the bundle.

**Senior / Staff:**

> Build-time security covers three areas: CSP compatibility (extract
> CSS, use external source maps, nonces for inline scripts), secret
> protection (post-build scan, audit VITE_ variables), and dependency
> integrity (npm ci with lockfile hashes, SRI for CDN-served assets).
> I configure Sentry with `hidden-source-map` - external maps uploaded
> to Sentry, no public sourceMappingURL, so source code is not exposed
> via browser DevTools while errors are still debuggable.

---

### ⚠️ Common Misconceptions

**Misconception 1: `unsafe-eval` is only needed in development.**

`eval-source-map` (and other eval-based devtool values) require
`unsafe-eval` in CSP. Using them in production bypasses CSP protection.
Always use `source-map` or `hidden-source-map` in production.

**Misconception 2: Environment variables prefixed VITE_ are private.**

`VITE_` prefixed variables are PUBLIC - they are compiled into the
browser bundle. The prefix is there to prevent accidentally exposing
non-prefixed server-side variables, not to make them private.

---

### 🚨 Failure Modes and Diagnosis

**Failure: CSP violation: "Refused to execute inline script".**

Cause: HMR or style-loader injects inline scripts; CSP blocks them.

Diagnose: Check browser console for specific CSP error.
Fix (dev): add `unsafe-inline` to dev CSP only. Fix (prod): ensure
no inline scripts in prod build (MiniCssExtractPlugin, no HMR).

**Failure: Source map loaded in browser reveals proprietary source code.**

Cause: `source-map` devtool adds sourceMappingURL pointing to public .map.

Fix: Use `hidden-source-map` (no URL comment) and serve maps to
Sentry only; restrict .map files in CDN/nginx config.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What CSP issues do build tools create? | Mechanism | ★★☆ | 3 min |
| Why is eval-source-map a security risk in production? | Security | ★★☆ | 2 min |
| How to implement nonce-based CSP with webpack? | Scenario | ★★★ | 4 min |
| What is Subresource Integrity (SRI)? | Definition | ★★☆ | 2 min |
| How to prevent secrets in frontend bundles? | Security | ★★☆ | 2 min |
| hidden-source-map vs source-map? | Comparison | ★★☆ | 2 min |
| Build-time security checklist for a new project | Design | ★★★ | 4 min |

**Q: What is Subresource Integrity and how do build tools support it?**

A: Subresource Integrity (SRI) allows browsers to verify that a file
downloaded from a CDN hasn't been tampered with. The `integrity`
attribute on `<script>` or `<link>` contains a cryptographic hash of
the expected file content. If the served file's hash doesn't match,
the browser refuses to execute it.

```html
<script src="https://cdn.example.com/app.js"
        integrity="sha384-abc123..."
        crossorigin="anonymous">
</script>
```

webpack support: `webpack-subresource-integrity` plugin automatically
adds `integrity` attributes to all `<script>` and `<link>` tags
generated by HtmlWebpackPlugin. It also requires `crossOriginLoading:
'anonymous'` in the output config.

Use cases: when scripts or styles are served from a CDN. If an attacker
compromises the CDN and serves a modified JavaScript file, the browser
detects the hash mismatch and refuses to run it.

Limitations: only protects files with known hashes at build time.
Dynamically fetched resources (API responses, dynamically generated
scripts) cannot use SRI.

*What separates good from great:* The interaction between SRI and
caching. SRI hashes are content-based - the same file always has the
same hash. But if the CDN serves a stale cached version of a file with
an old hash that doesn't match the current `integrity` attribute, the
browser rejects it. Proper CDN cache invalidation (via hashed filenames)
prevents this: the new filename has a new hash, the old cache entry
has the old name and is never referenced by the new HTML.
