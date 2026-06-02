---
layout: default
title: "Security - L4 OAuth Internals"
parent: "Security"
nav_order: 9
permalink: /security/l4-oauth-internals/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [OAuth 2.0 Attack Vectors and PKCE](#oauth-20-attack-vectors-and-pkce) | high |

---

# OAuth 2.0 Attack Vectors and PKCE

---
id: SEC-020
title: "OAuth 2.0 Attack Vectors and PKCE"
category: Security
difficulty: "★★★"
interview_weight: high
asked_at: Senior+
seniority: senior
tags: [security, oauth2, pkce, oidc, authentication]
status: draft
sd: true
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> OAuth 2.0 has several well-known attack vectors: authorization code interception
> (PKCE prevents this), open redirect in redirect_uri (strict allowlisting prevents
> this), state parameter CSRF (state prevents this), token leakage via Referer header,
> and JWT algorithm confusion. PKCE (Proof Key for Code Exchange) prevents authorization
> code theft by requiring the client to prove it generated the original request, even
> if an attacker intercepts the code.

**3 minutes (Senior):**
> The authorization code flow works: client sends auth request, user authenticates,
> authorization server redirects to client's redirect_uri with a code, client
> exchanges code for token. PKCE extension: client generates a random `code_verifier`,
> hashes it (SHA-256) to produce `code_challenge`, sends the challenge with the auth
> request. When exchanging code for token, client sends the original `code_verifier`.
> The authorization server verifies `hash(code_verifier) == code_challenge`. An
> attacker who intercepts the authorization code cannot use it without the
> `code_verifier`, which never left the client. Critical in mobile/SPA contexts
> where the redirect could be intercepted by a malicious app on the same device.
> Modern OAuth 2.1 makes PKCE mandatory for all public clients.

**Framework:** Auth flow step → Threat per step → Mitigation → Implementation

**Blank Mind Recovery:**

**(1) Restate:** "OAuth 2.0 has specific attack vectors at each step of the flow.
PKCE protects against authorization code interception by requiring proof of the
original request."

**(2) First principles:** "OAuth 2.0 proves who authorized access. Each piece of
the flow (code, state, redirect_uri) is a potential attack surface.
PKCE closes the code interception window."

**(3) Bridge:** "PKCE is like a vault combination that you only reveal when picking
up a package. You give the bank the combination hash when you request the pickup;
an interceptor who steals the package cannot use it without knowing the original combination."

---

### 📘 Concept Explanation

**What it is:**
OAuth 2.0 is an authorization framework that allows a client application to obtain
limited access to a resource owner's resources on an authorization server.
PKCE (RFC 7636) is an extension to the authorization code flow that prevents
authorization code interception attacks by binding the authorization request to the
token exchange.

**The problem it solves:**
OAuth 2.0 authorization codes are one-time tokens transmitted via redirect URIs.
In mobile environments, multiple apps can register the same custom URI scheme;
a malicious app intercepts the redirect and steals the code. PKCE prevents code
theft by requiring proof of the original request.

**How the standard flow works:**

```
AUTHORIZATION CODE FLOW + PKCE:

Client                Auth Server
  |                       |
  |--1. Auth Request ----->|
  |  response_type=code    |
  |  client_id             |
  |  redirect_uri          |
  |  scope                 |
  |  state (CSRF token)    |
  |  code_challenge (PKCE) |
  |  code_challenge_method |
  |                        |
  |  User authenticates    |
  |  User consents         |
  |                        |
  |<--2. Auth Code --------|
  |   (via redirect_uri)   |
  |   + state echoed back  |
  |                        |
  |--3. Token Exchange ---->|
  |  code                  |
  |  code_verifier (PKCE)  |
  |                        | verify:
  |                        | SHA256(verifier)
  |                        | == challenge
  |<--4. Token Response ---|
  |  access_token          |
  |  refresh_token         |
  |  id_token (OIDC)       |
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the OAuth 2.0 authorization code flow with PKCE extension, showing all four steps and the data exchanged at each. (2) HOW TO READ IT: the client is on the left; auth server on the right; numbered arrows show the sequence; PKCE components (`code_challenge`, `code_verifier`) appear at steps 1 and 3. (3) KEY RELATIONSHIP: the PKCE binding ties step 1 (auth request) to step 3 (token exchange); the code alone (stolen at step 2) is useless without the `code_verifier` generated in step 1 that never left the client. (4) EDGE CASE: in mobile, step 2 (the redirect) can be intercepted by a malicious app; with PKCE, the intercepted code cannot be exchanged because the attacker does not have the `code_verifier`. (5) INSIGHT: a senior engineer notices that `state` (CSRF protection) and `code_challenge` (PKCE) are generated at step 1 but protect against different threats; both are required.

**PKCE mechanics in detail:**

```
PKCE CODE GENERATION:

1. Generate code_verifier:
   Random 43-128 char string
   [A-Z][a-z][0-9]-._~

2. Derive code_challenge:
   S256 method (required in OAuth 2.1):
   code_challenge =
     BASE64URL(SHA256(code_verifier))

3. Auth request includes:
   code_challenge=<hash>
   code_challenge_method=S256

4. Token exchange includes:
   code_verifier=<original random string>

5. Server verifies:
   SHA256(verifier) == stored_challenge

ATTACK (without PKCE):
  Attacker intercepts code -> exchanges for token
  ATTACK SUCCEEDS

ATTACK (with PKCE):
  Attacker intercepts code, has no verifier
  Auth server: verifier required -> REJECTED
  ATTACK FAILS
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the full PKCE computation steps and how the attack is blocked. (2) KEY MECHANISM: the `code_challenge` is a one-way SHA-256 hash of the verifier; the verifier is never transmitted in the auth request; only the client that generated the verifier can complete the token exchange. (3) WHY IT MATTERS: in mobile apps, the OS routes redirects to apps that register the URI scheme; a malicious app can register the same scheme and intercept the redirect; PKCE makes the intercepted code useless. (4) WHAT BREAKS: using the plain method (`code_challenge = code_verifier`) provides no security; the `S256` method is required; `plain` must be disabled at the authorization server. (5) TAKEAWAY: PKCE S256 is mandatory for all public clients (mobile, SPA); confidential clients (server-side) with client secrets also benefit from PKCE as defense in depth.

**Key insight:**
OAuth 2.0 security depends on the correct implementation of multiple parameters
(state, redirect_uri allowlist, PKCE) that are each optional in the original RFC
but effectively mandatory for security. OAuth 2.1 codifies this by making them mandatory.

---

### 💻 Code Example

```java
// BAD: No PKCE, no state check - vulnerable
@GetMapping("/callback")
public void callbackBad(
        @RequestParam String code,
        HttpServletResponse response) {
    // BAD: no state check - CSRF possible
    // BAD: no code_verifier - code theft possible
    TokenResponse tokens = authClient.exchangeCode(
        code, clientId, clientSecret, redirectUri);
    session.setAttribute("token", tokens.accessToken);
}

// GOOD: PKCE + state verification
@GetMapping("/callback")
public void callbackGood(
        @RequestParam String code,
        @RequestParam String state,
        HttpSession session,
        HttpServletResponse response) {

    // Verify state to prevent CSRF
    String expectedState =
        (String) session.getAttribute("oauth_state");
    if (expectedState == null
            || !MessageDigest.isEqual(
                state.getBytes(),
                expectedState.getBytes())) {
        throw new SecurityException("Invalid state");
    }

    // Include code_verifier for PKCE verification
    String codeVerifier =
        (String) session.getAttribute("code_verifier");

    TokenResponse tokens = authClient.exchangeCode(
        code, clientId, redirectUri, codeVerifier);

    // Clear PKCE verifier - one-time use
    session.removeAttribute("code_verifier");
    session.removeAttribute("oauth_state");
    session.setAttribute("token", tokens.accessToken);
}

@GetMapping("/login")
public void initiateLogin(
        HttpSession session,
        HttpServletResponse response)
        throws Exception {

    // Generate PKCE verifier (256-bit entropy)
    byte[] verifierBytes = new byte[32];
    new SecureRandom().nextBytes(verifierBytes);
    String codeVerifier = Base64.getUrlEncoder()
        .withoutPadding()
        .encodeToString(verifierBytes);

    // Derive S256 challenge
    byte[] hash = MessageDigest
        .getInstance("SHA-256")
        .digest(codeVerifier.getBytes(
            StandardCharsets.US_ASCII));
    String codeChallenge = Base64.getUrlEncoder()
        .withoutPadding()
        .encodeToString(hash);

    // Generate state CSRF token (128-bit)
    byte[] stateBytes = new byte[16];
    new SecureRandom().nextBytes(stateBytes);
    String state = Base64.getUrlEncoder()
        .withoutPadding()
        .encodeToString(stateBytes);

    // Store for verification in callback
    session.setAttribute("code_verifier", codeVerifier);
    session.setAttribute("oauth_state", state);

    // Build auth URL with PKCE
    String authUrl = authServer + "/authorize"
        + "?response_type=code"
        + "&client_id=" + clientId
        + "&redirect_uri=" + redirectUri
        + "&scope=openid+profile"
        + "&state=" + state
        + "&code_challenge=" + codeChallenge
        + "&code_challenge_method=S256";

    response.sendRedirect(authUrl);
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: BAD callback (no state, no PKCE) versus GOOD implementation with PKCE verifier and state CSRF protection, plus the login initiation that generates both. (2) KEY MECHANISM: the `code_verifier` is generated at login start, stored in session, and sent only at token exchange; the auth server verifies `SHA256(verifier) == stored_challenge`; state is a random nonce stored in session and echoed back to prevent CSRF. (3) WHY IT MATTERS: without state, an attacker can trick a user into completing an OAuth flow with the attacker's code, binding the user's session to the attacker's account. (4) WHAT BREAKS: not clearing the verifier after use allows replay; not using constant-time comparison for state allows timing attacks. (5) TAKEAWAY: generate PKCE verifier and state at auth start, store in session, verify both at callback, clear after use - four independent protections.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> OAuth 2.0 has specific attacks at each step. CSRF on the callback: prevented by
> the state parameter. Code theft by a malicious app: prevented by PKCE. Token
> leakage via URL: use authorization code flow, not implicit. PKCE works by having
> the client prove it generated the original request by sending the verifier that
> hashes to the challenge sent at the start.

---

**Senior / Staff (5+ years):**
> OAuth 2.0 attack surface: redirect_uri manipulation (open redirect to phishing),
> authorization code interception (PKCE prevents), state parameter CSRF (state prevents),
> JWT algorithm confusion (alg:none, HS256 with RS256 key), refresh token rotation
> issues (detect theft via reuse detection), and authorization server mix-up attacks.
> I implement: strict redirect_uri allowlist with exact match, PKCE with S256 for all
> public clients, state with entropy >= 128 bits, JWTs validated with explicit algorithm
> specification, refresh token rotation with reuse detection (OAuth security BCP RFC 9700).
> For SPAs: BFF pattern (Backend for Frontend) eliminates token storage in the browser
> entirely - tokens stay server-side.

---

### ⚠️ Common Misconceptions

**Misconception 1: "The implicit flow is fine for SPAs."**

The implicit flow returns tokens in the URL fragment, which appears in browser history,
is sent in Referer headers, and can be logged by analytics scripts. The implicit flow
was deprecated in OAuth 2.1. SPAs must use the authorization code flow with PKCE.
If the SPA cannot keep a client secret, PKCE (requiring no client secret) is specifically
designed for this scenario.

**Misconception 2: "PKCE is only needed for mobile apps."**

PKCE prevents authorization code interception. While mobile is the primary concern
(same-device malicious app), PKCE also defends against authorization code theft from
browser history, browser extensions logging codes, and network-level code injection.
OAuth 2.1 mandates PKCE for all public clients.

**Misconception 3: "State is optional because HTTPS prevents CSRF."**

HTTPS encrypts the channel but does not prevent CSRF. A CSRF attack against OAuth
does not need to read the response - it forces the user's browser to complete an
attacker-controlled OAuth flow, binding the user's account to the attacker's
authorization. State is mandatory for CSRF prevention in OAuth.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Open redirect via redirect_uri manipulation.**

Symptom: authorization server issues code to attacker-controlled domain.
Diagnosis: check authorization server redirect_uri matching - must be exact string
match, URL-decoded before comparison; no wildcard patterns.
Fix: register exact redirect URIs; authorization server must reject any deviation.

**Failure Mode 2: JWT accepted with `alg:none`.**

Symptom: any unsigned JWT accepted by the resource server.
Root cause: JWT library reads the `alg` header from the token to select algorithm.
Diagnosis: submit a JWT with `alg: none` and no signature; if accepted, the library
is misconfgured.
Fix: hard-code the expected algorithm; reject any JWT where the `alg` header does not
match; never accept `none`.

**Failure Mode 3: Refresh token reuse not detected.**

Symptom: stolen refresh tokens used indefinitely without detection.
Root cause: authorization server does not track token families or detect reuse.
Fix: enable refresh token rotation with reuse detection in the authorization server
configuration (Keycloak: `Revoke Refresh Token: enabled`).

---

### ⚖️ Comparison Table

| Flow | Client type | Security | Modern status |
|---|---|---|---|
| **Auth Code + PKCE** | Public (mobile, SPA) | Code binding + CSRF | Recommended for all |
| **Auth Code + secret** | Confidential (server) | Client auth | Server-side apps |
| **Client Credentials** | Machine-to-machine | No user context | Service-to-service |
| **Implicit** | SPA (deprecated) | Tokens in URL | Deprecated; never use |
| **ROPC** | Legacy only | Password exposed | Never; eliminate |

---

### 🏛️ System Design

**BFF Pattern - Tokens Never in Browser**

```
  BROWSER           BFF SERVER       AUTH SERVER
  +-------+        +----------+     +----------+
  |  SPA  |--1---->|   BFF    |     |          |
  | (JS)  |        |  /login  |--2->| Keycloak |
  +-------+        +----------+     +----------+
      |                |   ^             |
      |  redirect      |   |             |
      |<-3--(browser   |   |--4-PKCE---->|
      |   redirected)  |                 |
      |                |<--5-token resp--|
      |--6-fwd code--->|
      |                | tokens stored
      |                | server-side
      |<--7-HttpOnly---|
      |    cookie      |

  API CALL FLOW:
  SPA --[HttpOnly session cookie]--> BFF
  BFF --[Bearer access_token]------> API
  Tokens NEVER reach JavaScript
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Backend for Frontend (BFF) pattern where the SPA delegates OAuth token handling to a server component, eliminating tokens from browser JavaScript. (2) HOW TO READ IT: steps 1-7 show the login flow; the BFF handles PKCE at step 4 and stores tokens at step 5; the browser only holds a session cookie. (3) KEY RELATIONSHIP: the tokens (access, refresh) live in the BFF server-side; XSS in the browser cannot reach them; the browser sends only a session cookie which is HttpOnly and cannot be read by JavaScript. (4) EDGE CASE: if the BFF itself is compromised, tokens are accessible; BFF security (hardening, minimal attack surface) becomes critical. (5) INSIGHT: a senior engineer recognizes the BFF pattern addresses the "implicit flow was deprecated, but SPAs still need tokens" problem by moving token handling back to the server without changing the SPA architecture.

---

### 📊 Diagram

```
OAUTH 2.0 ATTACK SURFACE MAP:

  Step 1 - Auth Request:
    Threat: CSRF (attacker initiates flow)
    Fix:    state (entropy >= 128 bits)

  Step 1 - Auth Request:
    Threat: Code interception preparation
    Fix:    code_challenge (PKCE S256)

  Step 2 - Redirect:
    Threat: redirect_uri manipulation
    Fix:    exact match allowlist on auth server

  Step 2 - Redirect:
    Threat: Code interception (mobile URI)
    Fix:    PKCE (code useless without verifier)

  Step 3 - Token Exchange:
    Threat: Client impersonation
    Fix:    client_secret (confidential)
            code_verifier (public clients)

  Step 4 - Token Response:
    Threat: Token storage in browser
    Fix:    HttpOnly cookies; BFF pattern

  JWT Validation:
    Threat: Algorithm confusion (alg:none)
    Fix:    Hard-code algorithm in verifier

  Step 5 - API Calls:
    Threat: Bearer token theft (XSS)
    Fix:    Short expiry; rotation; BFF
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the complete OAuth 2.0 attack surface organized by flow step with specific threat and fix at each point. (2) KEY MECHANISM: each step has a different attack surface; state and code_challenge are both generated at step 1 but protect against different threats (CSRF vs code theft); they are independent protections. (3) WHY IT MATTERS: developers who implement OAuth without understanding the threat-per-step typically implement some but not all mitigations; this map enables complete coverage. (4) WHAT BREAKS: implementing state but not PKCE leaves step 2 code interception possible; implementing PKCE but not state leaves CSRF possible; both are required. (5) TAKEAWAY: use an OAuth library (Spring Security OAuth2 Client, AppAuth for mobile) rather than hand-rolling; the library has been through security review; custom implementations miss subtle requirements.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | PKCE, state |
| Mechanism | 3 | JWT algorithm, token rotation, mix-up |
| Application | 2 | SPA, migration |
| Scenario | 2 | Code theft, audit |
| Trade-off | 2 | BFF vs SPA, IDP vs custom |
| Behavioral | 1 | 50-service rollout |

---

**[MID] Q1 (Definition): Explain PKCE step by step. Why does it prevent authorization code theft?**

PKCE (Proof Key for Code Exchange) is an extension to the OAuth 2.0 authorization
code flow that prevents an attacker who intercepts the authorization code from using it.

Step 1 - Code verifier generation: the client generates a cryptographically random string
of 43-128 characters. This is the `code_verifier`. Generated at the start of the auth
flow and kept secret on the client.

Step 2 - Code challenge derivation: the client computes
`code_challenge = BASE64URL(SHA256(code_verifier))`. This is a one-way transformation;
the verifier cannot be reconstructed from the challenge.

Step 3 - Authorization request: the client sends `code_challenge` and
`code_challenge_method=S256`. The server stores the challenge associated with the code.

Step 4 - Redirect with code: the auth server returns the authorization code via redirect.
The `code_verifier` was never transmitted.

Step 5 - Token exchange: the client sends the `code` plus the original `code_verifier`.
The server verifies `SHA256(received_verifier) == stored_challenge`. Mismatch = rejected.

Why it prevents code theft: an attacker who intercepts the authorization code has the
code but not the `code_verifier` (never transmitted). They cannot exchange the code
for a token without the verifier. The code is useless to them.

*What separates good from great:* Understanding why `plain` is insecure. If
`code_challenge_method=plain`, then `code_challenge = code_verifier`. An attacker
who reads the auth request (in logs, browser history, network) gets the verifier
directly. `S256` is required; `plain` must be disabled.

---

**[MID] Q2 (Definition): What is the state parameter and what does it protect against?**

The `state` parameter is a CSRF protection mechanism. The client generates a random
unguessable value, stores it in session, sends it in the authorization request, and
verifies it when the callback returns.

CSRF attack this prevents: without state, an attacker can initiate an OAuth flow with
their own account, then trick the victim into completing the flow. The victim's browser
follows the callback URL and the victim's session becomes associated with the attacker's
authorization. The attacker logs in as the victim.

Mechanism: the authorization server echoes the state parameter back in the redirect
without modification. The client checks that the returned state matches what it stored.
An attacker cannot predict the random state; they cannot forge a callback that passes
the check.

Requirements: state must be at least 128 bits of randomness from `SecureRandom`;
stored server-side (session) or in a signed cookie; comparison must be constant-time;
state is single-use (discard after the callback).

*What separates good from great:* The session fixation variant. The CSRF attack can
fix the user's session to the attacker's OAuth session. Even if the state check passes
(the attacker's legitimate OAuth flow), the result binds the wrong identity to the
victim's session. The fix is binding the session to the authenticated user identity at
login completion.

---

**[SENIOR] Q3 (Mechanism): Explain the JWT algorithm confusion attack and how to prevent it.**

In OAuth/OIDC, the resource server validates JWTs issued by the authorization server.
RS256 (asymmetric) is typical: private key signs, public key verifies. The public key
is published at `/.well-known/jwks.json`.

Algorithm confusion attack: an attacker obtains the RS256 public key (it is public).
They create a JWT with `"alg": "HS256"` header and sign it with HMAC-SHA256 using
the public key bytes as the HMAC secret. A vulnerable resource server that reads the
`alg` from the token header and calls `verify(token, publicKeyBytes)` verifies the
HS256 signature successfully. The attacker can set arbitrary claims (user ID, roles).

Why it works: the validator accepts the HS256 signature because it verifies correctly
with the public key bytes as the HMAC secret.

Prevention:
1. Hard-code the expected algorithm: never read `alg` from the token to select the
   verification algorithm; specify `RS256` explicitly in the validator.
2. Use strongly typed key objects: `java.security.PublicKey` cannot be used as an
   HMAC secret in properly typed JWT libraries.
3. Verify `iss` (issuer) before `alg`: reject tokens from unexpected issuers immediately.
4. Use a vetted library (Nimbus-JOSE, jjwt 0.11+) with algorithm pinning.

*What separates good from great:* JWKS endpoint key rotation. Authorization servers
rotate signing keys; the resource server fetches current public keys from the JWKS
endpoint. Cache the key (24h TTL) with a fallback to fresh fetch on verification
failure - not too aggressive (rejects valid tokens during rotation) nor too loose
(vulnerable to JWKS injection via SSRF). The JWKS endpoint must be HTTPS only.

---

**[SENIOR] Q4 (Application): How do you implement OAuth 2.0 in a Single Page Application securely?**

SPAs have a fundamental challenge: they cannot store secrets (JavaScript is exposed).
The original recommendation (implicit flow) returned tokens in the URL - deprecated
because tokens in URLs appear in browser history and Referer headers.

Current best practice: authorization code flow with PKCE.

Option A - PKCE without BFF: SPA does the authorization code + PKCE flow entirely in
the browser. Access token stored in JavaScript memory (not localStorage). Refresh
token in a short sliding session with silent refresh.
Advantage: simpler. Disadvantage: tokens exist in JavaScript memory; XSS can read them.

Option B - BFF pattern (Backend for Frontend): a server-side component handles
token exchange and storage. Tokens stored server-side; browser receives an HttpOnly
session cookie only. API calls go through the BFF which attaches the access token.
Advantage: tokens never in browser; XSS cannot steal them. Disadvantage: requires
a server component; more complex architecture.

For high-security (banking, healthcare): BFF is required.
For standard consumer applications: PKCE without BFF is acceptable with XSS mitigations.

*What separates good from great:* Content Security Policy (CSP) as defense in depth.
A strict CSP (`script-src 'self'`) blocks injected scripts from exfiltrating in-memory
tokens. CSP is the control that makes PKCE-without-BFF more secure. Together: PKCE
protects the code exchange; CSP limits XSS scope; HttpOnly cookies protect refresh tokens.

---

**[SENIOR] Q5 (Mechanism): How does refresh token rotation with reuse detection work?**

Refresh token rotation means: every time a refresh token is used to get a new access
token, the old refresh token is invalidated and a new refresh token is issued.

Reuse detection: the authorization server tracks each refresh token is used exactly once.
If a token that was already used is presented, the server detects a theft:

Normal flow: client has RT1, exchanges for AT1+RT2; later uses RT2 for AT2+RT3.
RT1 is invalidated after first use; RT2 after second.

Theft scenario: client and attacker both have RT1. Client uses RT1 first: gets AT1+RT2.
Attacker tries RT1: server sees RT1 was already used - theft detected!
Server action: invalidate the entire refresh token family (all tokens derived from RT1).
Both client and attacker are logged out; user re-authenticates.

Why this works: the attacker cannot use the stolen token without revealing the theft.
The window of attacker access is limited to between the theft and the detection.

Implementation: the authorization server must track token families and detect reuse.
Most OAuth servers (Keycloak, Auth0) implement this; enable in configuration.

*What separates good from great:* The clock skew problem. If the client sends RT1 and
the network is slow, the client may retry with RT1 before getting the response. The
server sees RT1 used twice - legitimate retry, not theft. Solution: short reuse window
(1-5 seconds) where the same token can be presented again; outside this window, reuse
is treated as theft.

---

**[SENIOR] Q6 (Scenario): You discover authorization codes are being stolen in production. How do you investigate?**

Immediate triage: are codes being stolen in transit, at the client, or at the
authorization server? Evidence to collect:

1. What clients are affected? Web, mobile, or all? Mobile URI scheme code interception
   is the most common.

2. Are PKCE and state implemented? If not, these are the primary fixes.

3. Authorization code expiry: what is the TTL? Codes valid for 10+ minutes give
   attackers a larger window. Reduce to 60 seconds.

4. Redirect_uri validation: does the server enforce exact match or weak matching?
   Weak matching enables redirect_uri manipulation.

5. Check server logs: are there token exchange requests from unexpected IPs?
   A stolen code produces a token exchange from an IP that never received the redirect.

Fixes: enable PKCE S256 enforcement; reduce code TTL to 60 seconds; enforce exact
match on redirect_uri; enable one-time-use on codes.

Detection: SIEM alert if the IP performing the token exchange does not match the IP
that received the redirect response. This is the most reliable theft indicator.

*What separates good from great:* If PKCE is implemented and codes are still being
stolen, the interception is upstream (before the redirect reaches the client).
Investigate network capture, compromised CDN, or server-side log exposure where the
redirect URL (including code) is captured in access logs.

---

**[SENIOR] Q7 (Trade-off): When should you use Client Credentials flow vs Authorization Code flow?**

The fundamental distinction: who is the resource owner?

Client Credentials flow: the client itself is the resource owner. No user is involved.
A background service accesses an API on its own behalf.
Use cases: microservice-to-microservice communication, batch jobs, CI/CD pipelines,
monitoring agents.
Properties: no user consent, no redirect, short-lived access token, client authenticates
with client_id + client_secret (or mTLS).

Authorization Code flow: a user (resource owner) grants the client access to their
resources. User context in the token.
Use cases: any user-facing application accessing APIs on behalf of the user.
Properties: user consent required, redirect-based, user identity in token sub claim.

Decision criteria:
- Human user involved? Authorization Code with PKCE.
- Service-to-service, no user context? Client Credentials.
- Can the service store a secret securely (server-side)? Client Credentials with secret.
- Public client (mobile, SPA)? PKCE mandatory; Client Credentials not applicable.

Do not use Client Credentials and embed user IDs in claims as a substitute for
user-specific tokens; this is authorization bypass by design.

*What separates good from great:* The mTLS variant of Client Credentials. Instead of
client_secret (stored, rotatable), the client authenticates with a client certificate.
Certificate rotation is managed by PKI. mTLS Client Credentials is more secure because
certificate theft is harder to exploit (requires the private key) and rotation is
managed at infrastructure level.

---

**[SENIOR] Q8 (Scenario): How do you migrate a legacy application from Basic Auth to OAuth 2.0?**

Migration involves three parallel workstreams.

Workstream 1 - Identity infrastructure: deploy an authorization server (Keycloak,
Auth0, Cognito). Configure clients (redirect URIs, scopes). Set token TTLs (access:
5-15 min; refresh: 7-30 days).

Workstream 2 - Application migration: the API changes from validating Basic Auth
credentials to validating JWT Bearer tokens. Spring Security: replace `http.httpBasic()`
with `http.oauth2ResourceServer()` and configure the JWKS URI.

Transition approach - parallel authentication: accept both Basic Auth (legacy clients)
and JWT Bearer (new OAuth clients) simultaneously using the Spring Security filter chain.
Each client migrates independently.

```java
// Transition: accept both Basic Auth and JWT
http.authorizeHttpRequests(auth ->
    auth.anyRequest().authenticated())
  .httpBasic()  // legacy clients continue to work
  .oauth2ResourceServer(oauth2 ->
    oauth2.jwt());  // new OAuth clients
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Spring Security configured for parallel authentication supporting both legacy Basic Auth clients and new OAuth2/JWT clients during migration. (2) KEY MECHANISM: Spring Security's filter chain tries each mechanism; `Authorization: Bearer <jwt>` hits the JWT filter; `Authorization: Basic <cred>` hits httpBasic; both work simultaneously. (3) WHY IT MATTERS: a hard cutover requires all clients to migrate simultaneously - operationally impossible; parallel auth allows gradual migration with a deprecation timeline. (4) WHAT BREAKS: permitting both forever; set a deprecation date and monitor `Authorization: Basic` header usage; remove httpBasic when usage reaches zero. (5) TAKEAWAY: parallel authentication with a clear deprecation timeline is the safe migration pattern; never hard-cut authentication systems without a proven fallback.

Workstream 3 - Client migration: provide OAuth client libraries. Set a Basic Auth
deprecation date. Monitor Basic Auth header usage; remove Basic Auth support when
all clients have migrated.

*What separates good from great:* Service account migration. Machine-to-machine clients
using Basic Auth should migrate to Client Credentials flow. Create a dedicated OAuth
client per machine with minimal scopes; rotate Basic Auth credentials on the old system
only after the new client is validated in production.

---

**[SENIOR] Q9 (Mechanism): What is an authorization server mix-up attack?**

Mix-up attacks target OAuth clients configured for multiple authorization servers.
The attacker tricks the client into associating a code from one authorization server
(the attacker's malicious server) with the state of a flow intended for a different
server (the legitimate server).

Attack scenario: client configured for both `auth.legitimate.com` and
`auth.attacker.com`. User initiates login via `auth.legitimate.com`. Attacker injects
a code from `auth.attacker.com` into the redirect. Client sends this code to its
backend, which attempts token exchange with the wrong server.

Mitigation - RFC 9207 (AS Issuer Identification): the authorization server includes
an `iss` parameter in the authorization response. The client verifies that `iss`
matches the expected authorization server before processing the code.

OAuth 2.1 (consolidating best practices): PKCE mandatory for all public clients,
state mandatory, redirect_uri exact match required, implicit flow removed, Resource
Owner Password Credentials flow removed.

*What separates good from great:* This attack is primarily a concern for multi-AS
clients. Single-AS clients are not directly vulnerable but benefit from `iss` validation
as defense against AS spoofing (e.g., SSRF changing the AS endpoint). Use libraries
that implement RFC 9207; verify the library version.

---

**[SENIOR] Q10 (Trade-off): What are the trade-offs between using an identity provider vs building your own OAuth server?**

Build your own OAuth server trade-offs:

Arguments for build: full control over token format and claims; no external dependency;
custom authentication flows (hardware tokens, biometrics); data residency requirements.

Arguments against: OAuth 2.0 has subtle security requirements (PKCE, state, algorithm
pinning, token rotation, PKCE verifier entropy, JWKS rotation) - all must be implemented
correctly. Operational burden: key rotation, high availability (auth outage = total outage),
security patches. Security track record: Auth0/Keycloak have had vulnerabilities found
and fixed over years; a new implementation will have undiscovered vulnerabilities.

Realistic scenarios for custom OAuth server: government or regulated environments
with strict data sovereignty; deep integration with legacy auth systems; very large
scale with specific volume requirements.

For 95% of applications: use an established IDP. Security research, compliance
certifications (SOC 2, ISO 27001), and operational tooling are all provided.

*What separates good from great:* Even using an established IDP requires correct
configuration. Auth0/Keycloak misconfiguration is common: algorithm confusion enabled
in older versions, weak state entropy defaults, refresh token rotation not enabled
by default. Using an IDP is necessary but not sufficient; verify the security
configuration matches best practices for every IDP deployment.

---

**[SENIOR] Q11 (Scenario): You are reviewing an OAuth implementation. What do you specifically check?**

Systematic review checklist:

Authorization request (client side):
- State generated with >= 128 bits of entropy from `SecureRandom`?
- PKCE implemented with `S256` method?
- State verified at callback with constant-time comparison?
- `code_verifier` stored in session, not URL or localStorage?

Token exchange:
- `redirect_uri` in token exchange exactly matches the auth request?
- `code_verifier` sent at exchange?
- Code verified as one-time-use (server rejects replay)?

JWT validation (resource server):
- Algorithm hard-coded, not read from token `alg` header?
- `iss` claim verified against expected authorization server URL?
- `aud` claim verified against this resource server's identifier?
- `exp` claim verified? Clock skew tolerance bounded (<= 5 minutes)?
- JWKS endpoint HTTPS only? Cached with bounded TTL?

Token storage:
- Access tokens in memory only, not localStorage for SPAs?
- Refresh tokens in HttpOnly cookies or server-side storage?
- Tokens excluded from access logs and debug logs?

*What separates good from great:* The `aud` claim validation gap. Many implementations
validate `iss` and `exp` but skip `aud`. A token issued for API-A can be replayed against
API-B if API-B does not check the audience. API-B should accept tokens only where `aud`
includes its specific identifier.

---

**[STAFF] Q12 (Behavioral): Your company is adopting OAuth 2.0 across 50 microservices. How do you plan the rollout?**

This is a platform decision, not a per-service decision. Infrastructure-first, then migration.

Phase 1 - Foundation (4-6 weeks): select the authorization server. For 50 microservices
at company scale: Keycloak on Kubernetes with PostgreSQL backend is typical (self-hosted,
free, flexible). Configure: realms, client registration policy, PKCE enforcement, token
TTLs, key rotation schedule.

Security baseline: define the minimum valid JWT validation configuration. Package as a
Spring Boot auto-configuration starter (company internal library). Every service adds
the starter; JWT validation is standardized. This eliminates per-service JWT configuration
drift - the most common source of auth bugs.

Phase 2 - Migration tiers (8-12 weeks):

Tier 1 (user-facing services): web apps, mobile backends. PKCE + state.
Use spring-security-oauth2-client autoconfiguration.

Tier 2 (service-to-service): background services, batch jobs. Client Credentials flow.
Provide a shared `WebClient` with automatic token management (fetch, cache, refresh on
expiry). Services use the shared client; no per-service OAuth code.

Tier 3 (legacy services that cannot be easily changed): use an API gateway sidecar or
proxy that handles authentication and injects identity as a signed JWT from a trusted
internal service.

Monitoring: track auth errors per service via the authorization server's admin API.
A service with elevated 401/403 rates signals misconfiguration.

*What separates good from great:* The developer experience investment. If adding OAuth
to a new service takes 2 hours, developers shortcut it. If the company starter configures
auth in 5 minutes and includes tests, adoption is friction-free. Security adoption is
an adoption problem as much as a security problem. Invest in tooling that makes the
secure path the easy path.
