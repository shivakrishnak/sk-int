---
layout: default
title: "Security - L2 Authentication"
parent: "Security"
nav_order: 4
permalink: /security/l2-authentication/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [OAuth 2.0 and OpenID Connect](#oauth-20-and-openid-connect) | critical |
| 2 | [JWT: Signing, Validation, and Common Vulnerabilities](#jwt-signing-validation-and-common-vulnerabilities) | critical |

---

# OAuth 2.0 and OpenID Connect

---
id: SEC-010
title: "OAuth 2.0 and OpenID Connect"
category: Security
difficulty: ★★☆
interview_weight: critical
asked_at: All
seniority: mid
tags: #security, #oauth2, #oidc, #openid-connect, #authentication, #authorization
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - OAuth 2.0 and OIDC are the industry standard for API authentication and single sign-on; expected from mid-level and above in any role that touches APIs or user authentication.

---

### 🎯 Model Answer

**30 seconds:**
> OAuth 2.0 is an authorization framework that lets a user grant a third-party
> application limited access to their resources at another service, without sharing
> their credentials. OpenID Connect (OIDC) is an identity layer on top of OAuth 2.0
> that adds user authentication - it tells the client who the user is. OAuth answers
> "can this app access this resource?" OIDC answers "who is this user?"

**3 minutes (Senior):**
> OAuth 2.0 solves the delegation problem: how can a user grant a third-party app
> access to their data at a service without giving that app their password? The answer
> is the Authorization Code Flow: the user authenticates directly with the service
> (not the third-party app), consents to the specific permissions (scopes) the app
> requests, and the service issues the app a short-lived access token - a limited
> credential that can only do what the scopes allow. The key security principle is
> that the user's credentials never leave the authorization server; the third-party
> app only ever sees access tokens.
> OpenID Connect adds identity to this flow by introducing the ID token - a JWT that
> the authorization server signs and gives to the client application. The ID token
> contains claims about who the user is (sub, email, name) and when they authenticated
> (auth_time). The access token authorizes API calls; the ID token authenticates
> the user identity.
> The non-obvious insight is that OAuth 2.0 itself does not define how authentication
> happens - only authorization. Many developers conflate the access token with proof
> of identity, which is wrong and can lead to security vulnerabilities. The ID token
> is the correct authentication artifact; the access token is the authorization artifact.

**Framework:** DELEGATION PROBLEM → AUTHORIZATION CODE FLOW → ACCESS TOKEN (authorization) → ID TOKEN (identity) → SCOPE AND CONSENT

*Adapting up:* Senior/staff should discuss PKCE (Proof Key for Code Exchange) for
public clients, the Token Exchange extension for service-to-service delegation, and
the security of implicit flow (deprecated) vs authorization code.

*Adapting down:* Junior - "OAuth lets an app access your data at another service
without getting your password. You log in to Google and approve the permissions;
Google gives the app a token to access only what you approved."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about OAuth 2.0 - let me think through what problem
it was designed to solve."

**(2) First principles:** "Before OAuth, apps that needed your data from another service
asked you for your username and password for that service. OAuth solves this by having
the service itself issue limited-access tokens instead of sharing credentials."

**(3) Bridge:** "This is like a hotel key card versus the master key. The guest gets
a card that opens only their room for three days (OAuth access token with scope and
expiry). The hotel never gives out the master key (user's actual credentials)."

---

### 📘 Concept Explanation

**What it is:**
OAuth 2.0 is an open authorization framework (RFC 6749) that defines how resource
owners can grant third-party clients limited access to their protected resources via
an authorization server, without exposing credentials. OpenID Connect (OIDC) extends
OAuth 2.0 with a standard identity layer, adding user authentication, standard claims,
and the UserInfo endpoint.

**The problem it solves:**
Without OAuth: to let a calendar app read your Gmail contacts, you would need to give
the calendar app your Gmail password. The calendar app then has unlimited access to
everything in your account, and if it is compromised, your credentials are stolen.
OAuth solves this: you authenticate directly with Gmail, consent to "contacts.read"
scope only, and Gmail gives the calendar app an access token limited to contacts.read
that expires in one hour.

**How it works:**

```
AUTHORIZATION CODE FLOW (most secure):

  User          Client App      Auth Server      Resource Server
   |--clicks login-->|                                |
   |             |--redirect with client_id,-------->|
   |             |   scope, state, redirect_uri      |
   |<--------login page---------------------------------|
   |--credentials only to Auth Server---------------->|
   |<-------redirect with code-------------------------|
   |             |<--code----|
   |             |--exchange code for tokens-------->|
   |             |<---access_token, id_token, -------|
   |             |    refresh_token                  |
   |             |--API request + access_token------>|
   |             |<-------resource data--------------|
```

```
KEY ARTIFACTS:
  Authorization Code - short-lived (60s), single-use
    exchange for tokens; never reaches client directly
  Access Token - bearer token for API access
    short-lived (15-60 min); scoped to consented scopes
  Refresh Token - used to get new access tokens
    long-lived (days); stored server-side if possible
  ID Token (OIDC) - JWT about the user identity
    signed by auth server; NOT for API authorization
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the three OAuth 2.0/OIDC token types and their distinct purposes and lifetimes. (2) KEY MECHANISM: the access token is the bearer credential for API calls - short-lived to limit breach impact; the refresh token is the long-lived credential stored securely and used only to obtain new access tokens from the authorization server; the ID token is OIDC-specific metadata about the user's identity, not an API credential. (3) WHY IT MATTERS: misusing the ID token as an API credential creates a security flaw - it is not intended for API authorization and may not have the same revocation semantics as access tokens. (4) WHAT BREAKS: storing the refresh token in localStorage exposes it to XSS; it should be in an httpOnly cookie or secure storage. (5) TAKEAWAY: access tokens are the API credential; ID tokens identify the user to the client app; refresh tokens are long-lived secrets stored with maximum protection.

**The key insight:**
The authorization code flow separates the user-facing authentication step (where the
user enters credentials directly with the auth server) from the token issuance step
(which happens server-to-server). The client app never sees the user's credentials;
it only receives a short-lived code, which it exchanges for tokens via a back-channel
call. This prevents credential interception by malicious clients.

**When to use it:**
OAuth 2.0: whenever a third-party app needs to access user data at another service.
OIDC: whenever you need to verify user identity for Single Sign-On or federated login.
Client Credentials flow: for machine-to-machine API access (no user involved).

**When NOT to use it:**
Do not use the Implicit Flow (returns tokens directly in the URL fragment) - it is
deprecated in OAuth 2.1 due to token exposure in browser history and referrer headers.
Use Authorization Code with PKCE instead for browser-based SPAs.

**Alternatives:**
- SAML 2.0 - XML-based federated identity, common in enterprise SSO; more complex than OIDC
- API Keys - simpler for machine-to-machine but no user delegation or scoping
- Session-based auth with SSO - for tightly coupled applications in one domain

**First-principles derivation:**
Given: user wants to delegate access without sharing credentials. Required properties:
(1) credentials stay with the trusted auth server, (2) access is scoped (not
all-or-nothing), (3) access is revocable without credential changes, (4) the
delegated token is time-limited. The Authorization Code Flow with access tokens
satisfies all four properties by design.

---

### 💻 Code Example

```java
// OAuth 2.0 Client Credentials flow (machine-to-machine)
// Secure service calling another service with OAuth token

@Service
public class PaymentServiceClient {
    private final OAuth2AuthorizedClientManager clientMgr;
    private final WebClient webClient;

    public PaymentResponse processPayment(
            PaymentRequest req) {
        // Spring Security auto-fetches/refreshes token
        OAuth2AuthorizeRequest authReq =
            OAuth2AuthorizeRequest
                .withClientRegistrationId("payment-api")
                .principal("payment-service")
                .build();

        OAuth2AuthorizedClient client =
            clientMgr.authorize(authReq);

        if (client == null
                || client.getAccessToken() == null) {
            throw new IllegalStateException(
                "Failed to obtain access token");
        }

        // Token automatically added to Authorization header
        return webClient.post()
            .uri("/api/payments")
            .headers(h -> h.setBearerAuth(
                client.getAccessToken().getTokenValue()))
            .bodyValue(req)
            .retrieve()
            .bodyToMono(PaymentResponse.class)
            .block();
    }
}

// application.yml
// spring:
//   security:
//     oauth2:
//       client:
//         registration:
//           payment-api:
//             client-id: ${CLIENT_ID}
//             client-secret: ${CLIENT_SECRET}
//             authorization-grant-type: client_credentials
//             scope: payments:write
//         provider:
//           payment-api:
//             token-uri: https://auth.example.com/token
```

> **Code walkthrough:** (1) WHAT IT SHOWS: OAuth 2.0 Client Credentials flow for service-to-service authentication, using Spring Security's OAuth2 client support which handles token caching and automatic refresh. (2) KEY MECHANISM: the `OAuth2AuthorizedClientManager` fetches an access token using the client ID and secret, caches it until near-expiry, and automatically refreshes it before expiry - the calling service code never manages token lifecycle manually. (3) WHY IT MATTERS: manually managing token lifecycle (fetch, cache, refresh) is error-prone and a common source of race conditions and token leakage bugs; delegating to a client manager eliminates these. (4) WHAT BREAKS: storing `CLIENT_SECRET` in source code or plaintext config files is a common mistake; use environment variables or a secrets manager (Vault, AWS Secrets Manager). (5) TAKEAWAY: use OAuth2 framework support rather than manually calling token endpoints; the framework handles expiry, caching, and token binding correctly.

```java
// OIDC: Validating ID token claims in a resource server
@Component
public class OidcTokenValidator {
    private final JwtDecoder decoder;

    // Validation on incoming ID token
    public UserClaims validateAndExtract(String idToken) {
        try {
            Jwt jwt = decoder.decode(idToken);

            // Validate required OIDC claims
            String issuer = jwt.getIssuer().toString();
            if (!TRUSTED_ISSUER.equals(issuer)) {
                throw new SecurityException(
                    "Untrusted issuer: " + issuer);
            }

            // Validate audience matches our client ID
            List<String> audience = jwt.getAudience();
            if (!audience.contains(OUR_CLIENT_ID)) {
                throw new SecurityException(
                    "Token not issued for this client");
            }

            // Extract standard OIDC claims
            return UserClaims.builder()
                .sub(jwt.getSubject())
                .email(jwt.getClaimAsString("email"))
                .emailVerified(
                    jwt.getClaimAsBoolean("email_verified"))
                .build();

        } catch (JwtException e) {
            throw new SecurityException(
                "Invalid ID token: " + e.getMessage(), e);
        }
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: ID token validation with issuer and audience checks - the two most critical validations beyond signature verification that prevent token substitution attacks. (2) KEY MECHANISM: the JwtDecoder verifies the token signature against the authorization server's public key (fetched from the JWKS endpoint); the application code then verifies that the token was issued by the expected issuer and intended for this specific client (audience). (3) WHY IT MATTERS: an access token issued for one service could be presented to another service - the audience check prevents this; without it, a token theft from one service can be used against another. (4) WHAT BREAKS: not checking the audience allows a token intended for api-service-a to be presented to api-service-b if both accept the same issuer; this is a token confusion attack. (5) TAKEAWAY: always validate issuer, audience, and expiry in addition to signature; signature alone is insufficient for authorization decisions.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> OAuth 2.0 lets apps access user data at other services without getting the user's
> password. The user authenticates with the service (like Google), approves specific
> permissions, and Google gives the app a short-lived access token. OIDC adds identity -
> the ID token tells you who the user is. The key distinction: access token authorizes
> API calls; ID token identifies the user.

*Push deeper:* Explain the steps of the Authorization Code Flow - what gets sent in
each redirect and why the code exchange happens server-to-server.

---

**Senior / Staff (5+ years):**
> I use OAuth 2.0 Authorization Code with PKCE for all browser-based apps (SPAs,
> mobile) because the Implicit Flow has been deprecated - tokens in URL fragments
> appear in browser history and referrer headers. For server-side web apps, I use
> Authorization Code without PKCE (the client secret provides the same security
> guarantee that PKCE provides for public clients). For service-to-service, Client
> Credentials flow. The OIDC design decision I watch most carefully is the ID token
> audience validation - failing to verify that the token was issued for your specific
> client ID allows token substitution attacks where a token obtained from one service
> is replayed against another. I also enforce short access token lifetimes (15-60
> minutes) and use short-lived refresh tokens with rotation (each use of the refresh
> token issues a new one and invalidates the old one - this provides refresh token
> theft detection).

*Push deeper:* Discuss the Token Exchange flow (RFC 8693) for service-to-service
delegation where Service A calls Service B on behalf of a user, and Service B needs
to know both who the user is and that Service A is the caller.

---

### ⚠️ Common Misconceptions

**Misconception 1: An access token proves who the user is.**

Access tokens authorize API calls - they prove the bearer has permission to access
certain resources. They do not authenticate user identity reliably. A service
receiving an access token cannot definitively determine the user's identity from
the access token alone (access tokens may be opaque strings). The ID token (OIDC)
is the correct artifact for user identity. Using an access token to determine
user identity is a design mistake that breaks when access tokens are machine-issued.

**Misconception 2: The Implicit Flow is equivalent to Authorization Code for SPAs.**

Implicit Flow returns tokens directly in the URL fragment (`#access_token=...`). URL
fragments appear in browser history, server access logs, and referrer headers when
the user navigates away. Tokens in URLs are a significant security risk. The
Authorization Code Flow with PKCE provides the same user experience for SPAs while
keeping tokens in HTTP responses (not URLs). Implicit Flow is deprecated in OAuth 2.1.

**Misconception 3: OAuth and OIDC are the same thing.**

OAuth 2.0 is an authorization framework. It delegates resource access to a third
party. It says nothing about who the user is. OpenID Connect is a separate specification
(built on top of OAuth 2.0) that adds user authentication. You can use OAuth 2.0
without OIDC (Client Credentials flow has no user). You can use OIDC without delegating
resource access (just authenticate the user's identity). They are related but distinct.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: State parameter not validated, enabling CSRF on the redirect.**

Symptom: an attacker can start an OAuth flow with their own account, capture the
authorization redirect URL (with code and state), and trick another user into loading
that URL - logging the victim into the attacker's account.
Diagnosis: check whether the `state` parameter is validated on the callback against
the value generated at the start of the flow. If the state is not stored in the user's
session and compared on callback, CSRF on OAuth is possible.

**Failure Mode 2: Access token logged or stored in plaintext.**

Symptom: access tokens appear in application logs, HTTP access logs, or database
tables - tokens are then extractable from log management systems.
Diagnosis: grep logs for access token patterns; audit log configuration to ensure
Authorization headers are redacted; ensure tokens are not included in error messages.

**Failure Mode 3: Refresh token not rotated on use.**

Symptom: a refresh token is stolen and used by an attacker; the legitimate client
continues to use the same refresh token, and there is no detection of the parallel
use.
Diagnosis: implement refresh token rotation (RFC 6749 best practice) - each refresh
token use issues a new one and invalidates the previous. If the old token is used
again after rotation, it indicates theft and the entire token family should be revoked.

---

### ⚖️ Comparison Table

| Flow | Client Type | Use Case | Security Notes |
|---|---|---|---|
| **Auth Code + PKCE** | Public (SPA, mobile) | User-delegated access | Recommended for all new clients |
| Auth Code (no PKCE) | Confidential (server) | User-delegated, server-side | Client secret protects code exchange |
| Client Credentials | Confidential (service) | Machine-to-machine | No user; service authenticates by ID+secret |
| Device Authorization | Limited input device | TV, IoT, CLI tools | User approves on separate device |
| Implicit (deprecated) | Public | Legacy SPA | Deprecated; tokens in URL; do not use |
| ROPC (deprecated) | Trusted first-party | Migration/legacy only | User password flows to app; defeats OAuth purpose |

**The deciding factor:**
Is there a user (use Authorization Code or Device flow)? Is it a machine calling another
machine (use Client Credentials)? Is the client public/untrusted (add PKCE)?

---

### 🏛️ System Design

*(Omit: ★★☆ intermediate. OAuth 2.0 attack vectors and full system design covered in L4 OAuth Internals entry.)*

---

### 📊 Diagram

*(Omit: the Authorization Code Flow ASCII diagram in Concept Explanation clearly illustrates the mechanism. Mermaid diagram omitted for ★★☆ level.)*

---

### 🎯 Interview Deep-Dive

| Question Category | Count | Coverage |
|---|---|---|
| Definition | 2 | OAuth vs OIDC, flows |
| Mechanism | 2 | Auth Code Flow steps, PKCE |
| Debugging | 2 | Auth failures, token theft |
| Trade-off | 2 | Flow selection, token types |
| Behavioral | 1 | Implementing OAuth in production |

---

**[MID] Q1 (Definition): What is the difference between OAuth 2.0 and OpenID Connect?**

OAuth 2.0 is an authorization delegation framework: it allows a user to grant a
third-party application limited access to their resources at a service, without sharing
their credentials. The output is an access token that can be used to call APIs.
OAuth 2.0 defines WHAT the client is allowed to do (scopes), not WHO the user is.

OpenID Connect (OIDC) is an authentication protocol built on top of OAuth 2.0. It
adds one key artifact: the ID token. The ID token is a JWT signed by the authorization
server that contains claims about who the user is (subject identifier, email, name,
when they authenticated). OIDC defines WHO the user is.

Concrete distinction: a service that accepts access tokens to authorize API calls
is using OAuth 2.0. A service that redirects users to an identity provider to establish
who they are (Single Sign-On, federated login) is using OIDC.

You can use OAuth 2.0 without OIDC (Client Credentials flow for machine-to-machine
access has no user identity component). You can use OIDC for pure authentication without
accessing any remote resource. They are related frameworks with different primary purposes.

The combination - OAuth 2.0 for authorization, OIDC for authentication, with the
same auth server handling both - is the standard architecture for modern web applications.

*What separates good from great:* Understanding the access token misuse risk. Developers
who do not know about OIDC often use the access token's content to infer user identity.
This is unsafe: access tokens are for resources servers, not for learning user identity.
The ID token is the correct artifact for user identity claims. Using the right artifact
for the right purpose is the architectural discipline OIDC enforces.

---

**[MID] Q2 (Definition): Walk me through the OAuth 2.0 Authorization Code Flow step by step.**

The Authorization Code Flow involves five parties: user (resource owner), browser,
client application, authorization server, and resource server.

Step 1 - Client initiates: the client redirects the user's browser to the authorization
server with: `client_id` (who is asking), `redirect_uri` (where to return the user),
`scope` (what permissions are requested, e.g., `openid email contacts.read`), `state`
(a random string that will be returned unmodified - prevents CSRF), and `response_type=code`.

Step 2 - User authenticates and consents: the authorization server authenticates the
user (login page). After authentication, it shows a consent screen: "App X wants to
access your contacts and email - Allow?" The user approves.

Step 3 - Authorization code returned: the authorization server redirects the user's
browser back to the `redirect_uri` with an authorization `code` (short-lived, single-use,
60 seconds). The client validates that the returned `state` matches the one it sent.

Step 4 - Code exchange: the client application's backend makes a server-to-server
POST request to the authorization server's token endpoint, sending the `code`,
`client_id`, `client_secret`, and `redirect_uri`. The client secret authenticates
the client. The authorization server returns: `access_token`, `id_token` (OIDC),
`refresh_token`, and expiry.

Step 5 - Use access token: the client calls the resource API with the access token
in the Authorization header (`Bearer <token>`). The resource server validates the
token (typically by calling the authorization server's introspection endpoint or
validating a JWT signature). If valid and scope sufficient, it returns the resource.

The security of this flow comes from: (1) credentials never leaving the auth server,
(2) the code exchange happening server-to-server (not in the browser where it could
be intercepted), (3) the state parameter preventing CSRF, and (4) the code being
single-use and short-lived.

*What separates good from great:* Explaining why the authorization code is separate
from the access token. The code is transmitted via the user's browser (URL redirect),
which is less secure than a direct server-to-server call. If the code were the access
token, interception of the redirect URL would immediately give the attacker access.
The server-to-server code exchange adds the client authentication step (client secret
or PKCE) before issuing the actual tokens.

---

**[MID] Q3 (Mechanism): What is PKCE and why is it required for public clients?**

PKCE (Proof Key for Code Exchange, pronounced "pixie") is an OAuth 2.0 extension
(RFC 7636) that protects the authorization code from being used by attackers even
if they capture the authorization redirect URL.

The problem PKCE solves: in a mobile app or SPA, there is no server to hold the
client secret. The client is "public" - anyone can decompile the app or inspect
the JavaScript and find the client ID. Without a client secret, the code exchange
step (Step 4 above) cannot authenticate the client. An attacker who captures the
authorization code (via a malicious app intercepting the redirect, or a URL leak)
could exchange it for tokens.

How PKCE works: before the authorization request, the client generates a random
`code_verifier` (a 43-128 character cryptographically random string). It derives
`code_challenge = BASE64URL(SHA256(code_verifier))`. It sends `code_challenge`
with the authorization request. When exchanging the code for tokens, it sends the
original `code_verifier`. The authorization server hashes the `code_verifier` and
compares to the stored `code_challenge`. Only the original client that generated
the verifier can pass this check.

An attacker who intercepts the authorization code does not have the `code_verifier`
(it was never transmitted in the redirect). They cannot complete the code exchange.

PKCE for confidential clients: OAuth 2.1 recommends PKCE even for server-side clients
with client secrets, as defense-in-depth. It prevents authorization code injection
attacks where an attacker tricks the server into completing a code exchange with a
valid code from a different client's session.

*What separates good from great:* Understanding that PKCE does not replace client
authentication for confidential clients - it is additive. A server-side app should
use both the client secret AND PKCE. The client secret proves "this is the registered
client"; PKCE proves "this is the same authorization session that started the flow."

---

**[SENIOR] Q4 (Mechanism): How do you implement token introspection vs JWT self-contained
validation? When do you choose each?**

When a resource server receives an access token, it needs to validate it. There are
two approaches: introspection (call back to the auth server) or local JWT validation.

Token introspection (RFC 7662): the resource server makes a POST request to the
authorization server's introspection endpoint with the token. The auth server responds
with the token's active status, expiry, scope, and subject. This is authoritative -
the auth server can revoke a token and introspection will immediately reflect that.
Cost: a network call per request. At 10,000 RPS, introspection adds 10,000
calls/second to the auth server - a scalability bottleneck. Caching introspection
responses (with short TTL matching token expiry) reduces this.

JWT self-contained validation: the access token is a signed JWT containing claims
(scope, subject, expiry, issuer, audience). The resource server validates the JWT
signature using the auth server's public key (fetched once from the JWKS endpoint
and cached). Validation is local - no network call. At 10,000 RPS, validation is
in-memory. Cost: revocation is delayed. If a JWT is revoked (user logs out, admin
revokes), it remains valid until its expiry. A 15-minute JWT cannot be invalidated
before its expiry window.

Decision framework: use JWT local validation when access tokens are short-lived (15
minutes) and immediate revocation is not a hard requirement. Use introspection when
tokens have longer lifetimes, or when the application requires immediate revocation
capability (e.g., on user logout or security incident). Many systems combine both:
JWT for normal validation, with a secondary token blocklist check for high-security
operations.

*What separates good from great:* Quantifying the revocation window. A 15-minute
JWT means a stolen token is valid for at most 15 minutes after theft detection.
For most applications, this is acceptable. For financial applications or admin
operations, even 15 minutes may be unacceptable - use introspection or
very short JWT lifetimes (2-5 minutes) with refresh token rotation.

---

**[SENIOR] Q5 (Debugging): Your OAuth integration intermittently fails with "invalid_grant"
errors during the code exchange. How do you diagnose?**

`invalid_grant` during code exchange means the authorization server rejected the
authorization code. The three most common causes are:

Cause 1 - code already used: authorization codes are single-use. If the application
retries the code exchange on network timeout or page refresh, the second request
will fail with invalid_grant. Diagnosis: check if your code exchange handler is
idempotent - if the request times out, does it retry? Fix: detect invalid_grant errors
and redirect the user to restart the authorization flow rather than retrying the code.

Cause 2 - code expired: codes expire in 60 seconds (sometimes shorter). If there is
a processing delay between receiving the code (in the redirect) and exchanging it,
the code may expire. Diagnosis: check the timestamp of the incoming redirect vs the
token request in access logs. Fix: minimize processing time between receiving the
code and exchanging it; ensure the exchange happens immediately on receiving the redirect.

Cause 3 - redirect_uri mismatch: the redirect_uri in the token request must exactly
match the one in the authorization request and the one registered with the auth server
(including trailing slashes, http vs https). Diagnosis: log both redirect_uris and
compare character-by-character. Common mismatch: mobile apps with dynamic return ports,
or developers forgetting to register the exact URI including query parameters.

Cause 4 (less common) - state parameter conflict in multi-tab scenarios: if users
have multiple authorization flows open simultaneously, sessions might mix up state
and code pairs. Diagnosis: check if the issue is more frequent when users have
multiple browser tabs open.

*What separates good from great:* Implementing OAuth flow diagnostics logging that
captures the authorization request parameters and code exchange parameters (excluding
secrets) side-by-side. This allows rapid diagnosis of parameter mismatches without
relying on reproducing the issue.

---

**[SENIOR] Q6 (Trade-off): When would you use OAuth 2.0 Client Credentials vs mTLS
for service-to-service authentication?**

Both solve service-to-service authentication but through different mechanisms with
different operational trade-offs.

OAuth 2.0 Client Credentials: the calling service authenticates to an OAuth authorization
server with a client ID and secret, and receives a short-lived JWT access token. It
presents this token to the target service. The target validates the JWT signature.
Benefits: well-understood protocol, standard across all languages and frameworks,
tokens carry scope information, centralized audit log at the auth server. Costs:
requires an auth server infrastructure, client secrets must be managed and rotated,
network round-trip to get tokens (mitigated by caching).

mTLS: both services authenticate each other using X.509 certificates, with the
connection itself providing authentication. No separate auth server required for
each call. Benefits: no shared secrets that can be leaked through configuration
(private keys are hardware-bound in HSMs), mutual authentication is inherent
(both parties prove identity), forward secrecy. Costs: certificate management
infrastructure (internal CA, automated rotation), harder to debug than token-based
auth, no standard "scope" concept (access control must be at the application layer).

When to use Client Credentials: when you already have an OAuth infrastructure, need
fine-grained scope-based access control, or need integration with external services
that support OAuth (third-party APIs, SaaS).

When to use mTLS: in a zero-trust mesh architecture (Istio, Linkerd) where all
service-to-service calls are authenticated at the infrastructure level; for
compliance environments where certificate-based authentication is required; when
operating without an always-available OAuth server.

*What separates good from great:* Recognizing that many modern architectures use
both: mTLS at the infrastructure layer (service mesh handles cert management transparently)
for transport authentication, plus OAuth tokens at the application layer for
user-delegated access control. The two are complementary, not competing.

---

**[SENIOR] Q7 (Behavioral): Tell me about an OAuth or OIDC integration you implemented.
What were the security decisions you made?**

I implemented OIDC-based Single Sign-On for a multi-service platform at a previous
company. The platform had eight separate applications (user portal, admin console,
API gateway, analytics dashboard) that all needed to share authentication.

Key decisions: (1) I chose Keycloak as the internal identity provider over using
a cloud IdP (Okta, Auth0) because of data sovereignty requirements - user identities
could not leave our infrastructure. This required running Keycloak in active-active
configuration for high availability.

(2) For browser applications, I used Authorization Code with PKCE. The auth code
must be exchanged server-side with the client secret even for SPAs - this was a
deliberate choice to avoid exposing refresh tokens in browser storage.

(3) Refresh token lifetime was a key decision: users expected to stay logged in for
8 hours without re-authentication, but I wanted short access token lifetimes (15 min)
for revocability. The compromise: 15-minute access tokens, 8-hour refresh tokens,
with rotation on use (each refresh gets a new refresh token). This provided effective
revocation (a compromised refresh token is used once before being rotated; the
legitimate client's next refresh fails because the old token is invalidated, triggering
re-login).

(4) I implemented a shared logout mechanism: logout from any application revoked the
session at Keycloak and broadcasted a backchannel logout notification (OIDC
specification) to all applications that had issued tokens for that session. This
prevented the "logged out of one app but still logged in to others" problem.

*What separates good from great:* The refresh token rotation strategy for detecting
theft. This is a non-obvious OIDC best practice that turned a "can't immediately
revoke JWT" weakness into a "theft is detectable" strength.

---

**[STAFF] Q8 (Deep Dive): How does token binding differ from bearer tokens and
why hasn't it been widely adopted?**

Bearer tokens work like cash: whoever holds the token can use it. If stolen (via
XSS, network interception, server-side log exposure), the token is immediately
usable by the attacker. The only mitigation is short expiry.

Token binding (RFC 8471-8473) cryptographically binds an OAuth access token to a
specific TLS connection. The client generates a key pair per TLS connection; the
token is bound to the public key's hash. A resource server receiving the token
verifies that the current TLS connection's key matches the one bound to the token.
A stolen token without the corresponding TLS key cannot be used.

The security improvement is significant: token theft becomes much harder because
the attacker needs both the token value AND the TLS session key (not just the token).

Why hasn't it been widely adopted: (1) Requires support in the browser, TLS library,
authorization server, and resource server simultaneously - a coordination problem.
(2) Browser support was experimental and then removed from Chrome in 2020 after
Microsoft, the primary proponent, deprioritized it. (3) It is incompatible with
token proxy scenarios (load balancers that terminate TLS) because the TLS connection
changes at the load balancer. (4) DPoP (Demonstration of Proof-of-Possession, RFC 9449)
emerged as a simpler alternative: the client signs each token request with an ephemeral
key, binding the token to a key the client controls without requiring TLS layer changes.
DPoP is gaining adoption as the practical successor to token binding.

*What separates good from great:* Knowing about DPoP as the pragmatic current
approach to proof-of-possession tokens. DPoP is now supported by Keycloak, Auth0,
and Azure AD - it provides most of token binding's security benefit with significantly
simpler implementation.

---

**[STAFF] Q9 (Trade-off): Centralized vs federated identity: what are the system
design trade-offs?**

Centralized identity: one authorization server manages all user identities and issues
tokens for all services. Single point of administration, single audit log, consistent
policy enforcement.

Trade-offs: single point of failure (mitigate with active-active HA); single point
of compromise (if the auth server is breached, all user identities are exposed);
latency dependency (every authentication requires a call to the central server).

Federated identity: multiple identity providers, often organized hierarchically (each
department or product line has its own IdP that federates with a root IdP). Users
authenticate to their local IdP; other services accept tokens from any trusted IdP.

Trade-offs: more complex token validation (must verify tokens from multiple issuers);
policy inconsistency risk (each IdP may enforce different policies); harder to audit
across multiple sources.

For most organizations: centralized identity (one Okta/Keycloak/Azure AD) provides
the best balance of simplicity and security. Federated identity is appropriate for
mergers and acquisitions (combining two organizations' identity systems), or when
different regulatory requirements mandate separate identity domains (healthcare,
government).

The staff-level consideration: the authorization server is critical infrastructure.
It must be treated with the same reliability and security rigor as the database: HA
configuration, automated failover, regular security updates, restricted access, and
an incident response plan for auth server compromise (which is a full organizational
incident, not just a service outage).

*What separates good from great:* Framing the auth server as organizational critical
infrastructure - a single auth server compromise can give an attacker access to every
service in the organization. The blast radius calculation drives investment in auth
server security and redundancy.

---

---

# JWT: Signing, Validation, and Common Vulnerabilities

---
id: SEC-011
title: "JWT: Signing, Validation, and Common Vulnerabilities"
category: Security
difficulty: ★★☆
interview_weight: critical
asked_at: All
seniority: mid
tags: #security, #jwt, #json-web-token, #authentication, #signing, #vulnerabilities
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - JWT is ubiquitous in modern APIs; every backend engineer must know how they work, how to validate them correctly, and the three classic vulnerabilities.

---

### 🎯 Model Answer

**30 seconds:**
> A JWT (JSON Web Token) is a compact, self-contained token with three parts: header
> (algorithm and type), payload (claims), and signature. The signature is created by
> the issuer using a private key or shared secret; the receiver validates it using the
> public key or shared secret. The three most important security rules: always verify
> the signature, always validate `exp` (expiry) and `aud` (audience), and never accept
> tokens with `alg: none` or allow the algorithm to be specified by the token sender.

**3 minutes (Senior):**
> JWTs are a specific implementation of the OAuth 2.0 token format - they are self-
> contained bearer tokens that carry claims about the user or authorization context.
> The three-part structure (header.payload.signature) allows any party with the
> validation key to verify the token without querying a database. The signing algorithm
> matters critically: RS256 (RSA with SHA-256) uses asymmetric keys - the issuer signs
> with a private key; validators use the public key (from the JWKS endpoint); only the
> issuer can create valid tokens. HS256 (HMAC-SHA256) uses a shared secret - any party
> that knows the secret can create AND validate tokens. For multi-service architectures,
> RS256 is preferable because each service can verify tokens without holding a secret
> that could be used to forge tokens. The three classic JWT vulnerabilities: (1) `alg:none`
> attack - a server that accepts tokens signed with `alg: none` can be tricked with an
> unsigned token; never accept none algorithm. (2) RS256-to-HS256 confusion - a server
> expecting RS256 that also accepts HS256 can be attacked by using the RS256 public key
> as the HS256 secret (the public key is public!). (3) JWKS endpoint spoofing via
> `jku`/`kid` header injection - check these against an allowlist, never fetch the URL
> from the token itself.

**Framework:** STRUCTURE (three parts) → ALGORITHMS (RS256 vs HS256) → VALIDATION (what to check) → VULNERABILITIES (three classic attacks)

*Adapting up:* Senior/staff should discuss JWT revocation challenges (tokens are valid
until expiry), nested JWTs, and token size considerations in high-throughput systems.

*Adapting down:* Junior - "A JWT is a token with a signature that proves it was issued
by a trusted party. Check: is the signature valid? Is it expired? Is it intended for us?"

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about JWTs - let me think through their structure and
what makes them secure or insecure."

**(2) First principles:** "A JWT needs to carry claims (user ID, scopes) and prove those
claims were set by a trusted issuer and haven't been tampered with. The signature
provides both - it's a cryptographic hash of the header and payload using the issuer's key."

**(3) Bridge:** "This is similar to a sealed envelope with an official stamp. The claims
are inside the envelope; the stamp (signature) proves who sealed it and that it hasn't
been opened."

---

### 📘 Concept Explanation

**What it is:**
A JSON Web Token (JWT, RFC 7519) is a compact, URL-safe token representing claims as
a JSON object. It consists of three Base64url-encoded segments separated by dots:
header (algorithm metadata), payload (claims), and signature. The signature cryptographically
binds the header and payload to the issuer's key.

**The problem it solves:**
In stateless API architectures, services need to validate caller identity and permissions
without querying a central session store on every request. JWTs allow services to
self-contain all necessary authorization information with a cryptographic proof of
authenticity that any service can verify independently.

**How it works:**

```
JWT STRUCTURE:
  header.payload.signature
  
  Header (Base64url decoded):
  {
    "alg": "RS256",  <-- MUST validate this
    "typ": "JWT",
    "kid": "key-2024-01"  <-- key ID for rotation
  }
  
  Payload (Base64url decoded):
  {
    "sub": "user_123",   <-- subject (user ID)
    "iss": "auth.co",    <-- issuer (MUST validate)
    "aud": "api.co",     <-- audience (MUST validate)
    "exp": 1234567890,   <-- expiry (MUST validate)
    "iat": 1234567000,   <-- issued at
    "scope": "read write"
  }
  
  Signature:
  RSASHA256(
    Base64url(header) + "." + Base64url(payload),
    private_key
  )
```

```
VALIDATION CHECKLIST (ALL MUST PASS):
  1. Algorithm: is alg in our allowed list? (reject none)
  2. Signature: verify with issuer's public key
  3. Expiry: exp > current_time
  4. Not before: nbf <= current_time (if present)
  5. Issuer: iss == expected_issuer
  6. Audience: aud contains our service identifier
  7. Key ID: kid matches a known key (JWKS lookup)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the complete JWT validation checklist that must run before trusting any token claim. (2) KEY MECHANISM: each step eliminates an attack class - signature verification prevents tampering; expiry check prevents replay of old tokens; issuer check prevents tokens from a rogue auth server; audience check prevents a token minted for service A from being used against service B. (3) WHY IT MATTERS: skipping any single step opens an attack vector; a library that only checks the signature but not expiry allows indefinite replay. (4) WHAT BREAKS: caching the JWKS endpoint response indefinitely means key rotation is not picked up; cache with a short TTL (5 minutes) and re-fetch on 401 from downstream. (5) TAKEAWAY: validate all 7 steps, not just the signature; use a well-maintained JWT library that enforces these by default; be wary of libraries that require opt-in per check.

**The key insight:**
The header and payload are Base64url-encoded (not encrypted) - anyone can decode and
read the contents without any key. JWTs provide integrity (the signature proves the
contents have not been tampered with) and authenticity (the signature proves who signed
it), but NOT confidentiality (use JWE for encrypted JWTs if payload is sensitive).

**When to use it:**
JWTs are appropriate for: stateless API authorization (access tokens in OAuth 2.0/OIDC),
service-to-service authentication, and propagating user identity across service boundaries.

**When NOT to use it:**
Do not put sensitive information (PII, credit card numbers, secrets) in JWT payloads
without encryption - the payload is only Base64-encoded, not encrypted. Do not use JWTs
for session management in web applications (use opaque tokens stored server-side instead,
for revocability). Do not use HS256 in multi-service architectures where multiple services
need to validate tokens - RS256 is correct.

**Alternatives:**
- Opaque tokens with introspection - revocable, but requires database lookup per request
- PASETO (Platform-Agnostic Security Tokens) - avoids JWT's algorithm flexibility issues
- Macaroons - tokens with attenuated authority (can be restricted post-issuance)

**First-principles derivation:**
A self-contained token needs three things: the claims (what it asserts), proof that a
trusted party created it (signature), and protection against replay (expiry and audience).
JWT's three-part structure directly implements these requirements. The flexibility of
algorithm choice (RS256, HS256, ES256) is a feature for adoption but a security liability
when the receiving party accepts algorithms it didn't expect.

---

### 💻 Code Example

```java
// BAD: JWT validation with critical mistakes
public class VulnerableJwtValidator {
    // VULN 1: Uses token's own algorithm claim
    // Allows alg:none or RS256->HS256 confusion attack
    public Claims validateBad(String token,
            String publicKeyPem) throws Exception {
        // jwt.decode() only decodes, does NOT verify!
        // Many developers confuse decode with verify
        Claims claims = Jwts.parserBuilder()
            // BAD: algorithm determined by token header
            .build()
            .parseClaimsJws(token)
            .getBody();

        // VULN 2: No audience validation
        // VULN 3: No issuer validation
        // Any token signed by the key is accepted
        return claims;
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two critical JWT validation failures - accepting any algorithm from the token header (enabling alg:none and RS256-to-HS256 confusion) and not validating iss/aud claims. (2) KEY MECHANISM: JWT libraries that allow the token's header to specify the algorithm can be tricked into accepting unsigned tokens (alg:none) or using the wrong algorithm (providing an RS256 public key as the HS256 secret). (3) WHY IT MATTERS: these are not theoretical vulnerabilities - CVEs have been filed against production JWT libraries that implemented these patterns incorrectly, including Auth0 and Okta integrations. (4) WHAT BREAKS: an attacker creates a token with `alg:none`, removes the signature, and the server accepts it as valid; or an attacker creates an HS256-signed token using the RS256 public key (which is public!) and the server's RS256-expecting validator accepts it by downgrading to HS256. (5) TAKEAWAY: always specify the expected algorithm in the validator, never accept it from the token.

```java
// GOOD: Secure JWT validation with all required checks
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import java.security.PublicKey;

public class SecureJwtValidator {
    private final PublicKey publicKey;  // RS256 issuer key
    private final String expectedIssuer;
    private final String expectedAudience;

    // Allow ONLY RS256 - no algorithm negotiation
    public Claims validate(String token) {
        try {
            return Jwts.parserBuilder()
                // 1. Explicit algorithm: RS256 ONLY
                //    rejects alg:none and HS256
                .requireIssuer(expectedIssuer) // 2. iss check
                .requireAudience(expectedAudience)//3. aud check
                .setSigningKey(publicKey) // 4. RS256 key
                .build()
                .parseClaimsJws(token)
                // Automatically validates:
                // - Signature against publicKey
                // - exp (expiry)
                // - nbf (not before, if present)
                // - iss, aud (from require* above)
                .getBody();

        } catch (ExpiredJwtException e) {
            // Distinct handling for expired vs invalid
            throw new TokenExpiredException(
                "Token expired at: " + e.getClaims().getExpiration());
        } catch (JwtException e) {
            // Generic: invalid signature, malformed, etc.
            throw new InvalidTokenException(
                "Token validation failed: " + e.getMessage());
        }
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: secure JWT validation that explicitly specifies the algorithm (no negotiation), validates all required claims (iss, aud, exp), and distinguishes expired tokens from invalid ones for appropriate error handling. (2) KEY MECHANISM: providing the `PublicKey` directly to `setSigningKey` forces the library to use RSA validation; attempting to use an HS256 token will fail because the library cannot use an RSA public key for HMAC verification. (3) WHY IT MATTERS: `requireIssuer` and `requireAudience` prevent cross-service token confusion attacks - a valid token issued for service-a cannot be used against service-b because their expected audiences differ. (4) WHAT BREAKS: without `requireAudience`, a user's access token for the mobile app API can be presented to the admin API if both accept the same issuer's tokens. (5) TAKEAWAY: the six-check validation checklist (algorithm, signature, exp, nbf, iss, aud) must all pass; any one failing check means the token must be rejected.

```java
// JWT creation: proper signing and claims
@Service
public class JwtTokenService {
    private final PrivateKey privateKey; // RS256 private key
    private final String issuerUri;

    public String createAccessToken(
            String userId, String audience,
            List<String> scopes) {
        Instant now = Instant.now();

        return Jwts.builder()
            // Standard claims
            .setSubject(userId)
            .setIssuer(issuerUri)
            .setAudience(audience)
            .setIssuedAt(Date.from(now))
            // Short expiry: 15 minutes
            .setExpiration(Date.from(
                now.plus(15, ChronoUnit.MINUTES)))
            // Custom claims
            .claim("scope",
                String.join(" ", scopes))
            // NEVER include sensitive data in JWT payload!
            // payload is base64 encoded, not encrypted
            // RS256 signing
            .signWith(privateKey, SignatureAlgorithm.RS256)
            .compact();
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: JWT creation with all required security claims - short expiry (15 minutes), explicit issuer and audience, and RS256 signing with a private key. (2) KEY MECHANISM: RS256 signs with the private key; validators use only the public key, which can be shared publicly via a JWKS endpoint without risk. (3) WHY IT MATTERS: 15-minute expiry is the key architectural decision that limits the blast radius of token theft - a stolen token is valid for at most 15 minutes, after which it expires and the attacker must steal a new one. (4) WHAT BREAKS: including sensitive data (SSN, credit card, password) in the JWT payload is wrong because Base64 is not encryption - anyone who intercepts the token can decode and read it; use JWE (encrypted JWT) for sensitive payloads. (5) TAKEAWAY: set expiry as short as the application can tolerate; the refresh mechanism handles token renewal without user interaction.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A JWT has three parts: header (algorithm), payload (claims like user ID and expiry),
> and signature. The signature proves it was issued by a trusted party and hasn't been
> tampered with. To validate: check the signature is valid, check it's not expired,
> check the audience matches your service. Never accept tokens with `alg: none`.

*Push deeper:* Explain the difference between Base64-encoded (public, readable by
anyone) and encrypted (needs decryption key to read). JWT payloads are Base64 only.

---

**Senior / Staff (5+ years):**
> I always use RS256 for multi-service architectures because asymmetric keys mean
> validators hold only the public key - they can verify but not create tokens. HS256
> requires sharing the secret with every validator, meaning any compromised service
> can forge tokens for all other services. My complete validation: explicit RS256
> algorithm enforcement (never negotiate from token header), signature verification,
> expiry check, issuer validation, and audience validation. The vulnerability I watch
> for is audience skipping - a token issued for the mobile app API should not be
> accepted by the admin API. I also implement short access token lifetimes (15 min)
> because JWTs cannot be revoked without a token blocklist. For security incidents
> requiring immediate revocation, I maintain a Redis-based blocklist that's checked
> after signature validation - the extra lookup is worth the immediate revocation
> capability for high-security endpoints.

*Push deeper:* Discuss the `kid` (key ID) parameter in the JWT header - it enables
key rotation by allowing the validator to look up the correct validation key for
each token. Without it, rotating signing keys requires a coordination cutover.

---

### ⚠️ Common Misconceptions

**Misconception 1: JWT payload is encrypted - it's private.**

JWT payloads are Base64url-encoded, not encrypted. Anyone who has the token can
decode the header and payload and read all claims in plaintext. Never include
sensitive information (passwords, SSNs, private data) in a JWT payload unless
using JWE (JSON Web Encryption) - a completely different standard.

**Misconception 2: `alg: none` is only a theoretical vulnerability.**

The `alg: none` attack has been exploited in production systems. Several JWT library
vulnerabilities have allowed attackers to forge tokens by setting `alg: none` and
removing the signature - the library accepted the token as valid because the algorithm
header said no signature was required. Real CVEs: CVE-2015-9235 (node-jsonwebtoken),
various Python JWT libraries. Always use a library that requires you to specify the
expected algorithm and rejects `alg: none` by default.

**Misconception 3: Validating the JWT signature is sufficient.**

Signature validation proves the token was issued by the holder of the signing key.
It does not validate that the token is intended for your service (audience), was issued
by a trusted issuer (issuer), or is still valid (expiry). A valid signature from a
trusted CA on an expired token for a different service should be rejected. All six
validation checks are required.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: alg:none or RS256-to-HS256 confusion attack.**

Symptom: security scanner or penetration tester reports ability to forge tokens;
the auth token is accepted without a valid signature.
Diagnosis: attempt to create a token with `alg: none` and empty signature; attempt
to create an HS256-signed token using the RS256 public key as the secret. Test whether
the validator accepts either.
Fix: specify the expected algorithm explicitly in the JWT validator; never accept
algorithm from the token header.

**Failure Mode 2: JWT leaking sensitive claims.**

Symptom: security audit finds tokens containing user email, phone, or other PII in
the payload; tokens visible in logs or URL fragments.
Diagnosis: decode tokens in use (base64url decode the payload section) and check for
sensitive claims. Check whether tokens appear in access logs (X-Authorization logging).
Fix: remove sensitive claims from JWT payload; use opaque sub (user ID) and look up
user details from a database if needed; use JWE for payloads that must contain
sensitive data.

**Failure Mode 3: JWT expiry not validated, allowing long-term token use.**

Symptom: a user account is disabled or compromised but their JWT continues to provide
access; security team cannot revoke access despite disabling the account.
Diagnosis: check whether `exp` claim is validated in the token validator; check token
lifetime (should be 15-60 minutes for access tokens).
Fix: validate `exp` in every token check; shorten token lifetime; implement a token
blocklist for immediate revocation of specific tokens on security events.

---

### ⚖️ Comparison Table

| Aspect | JWT (RS256) | JWT (HS256) | Opaque Token |
|---|---|---|---|
| **Validation** | Local (public key) | Local (shared secret) | Remote introspection |
| **Revocation** | Delayed (until expiry) | Delayed (until expiry) | Immediate |
| **Scalability** | High (no DB call) | High (no DB call) | Lower (introspection call) |
| **Multi-service** | Good (public key shared) | Poor (secret shared = can forge) | Good (central validation) |
| **Payload visible** | Yes (Base64 only) | Yes (Base64 only) | No (opaque) |
| **Key compromise** | Revoke public key at JWKS | Rotate secret; all tokens invalid | Rotate introspection secret |

**The deciding factor:**
Multi-service architectures with scalability requirements → RS256 JWT with short expiry.
Applications requiring immediate revocation → Opaque tokens with introspection (or
RS256 JWT with a token blocklist for hybrid approach).

---

### 🏛️ System Design

*(Omit: ★★☆ intermediate. Full JWT attack vector system design covered in L4 OAuth Internals entry.)*

---

### 📊 Diagram

*(Omit: the JWT structure ASCII diagram in Concept Explanation and the validation checklist provide sufficient visual representation for this intermediate level.)*

---

### 🎯 Interview Deep-Dive

| Question Category | Count | Coverage |
|---|---|---|
| Definition | 2 | JWT structure, claims |
| Mechanism | 2 | RS256 vs HS256, validation |
| Debugging | 2 | alg:none, token leakage |
| Trade-off | 2 | JWT vs opaque, RS256 vs HS256 |
| Behavioral | 1 | Production JWT security decision |

---

**[MID] Q1 (Definition): What are the three parts of a JWT and what does each contain?**

A JWT consists of three Base64url-encoded segments separated by dots: `header.payload.signature`.

The header contains metadata about the token: the algorithm used to sign it (`alg`,
e.g., `RS256` or `HS256`) and the token type (`typ: "JWT"`). Optionally, it may include
`kid` (key ID) for key rotation and `jku` (JWKS URL) - though `jku` must never be
used from the token itself (see vulnerabilities). The header is parsed FIRST by validators
to determine how to verify the signature.

The payload contains the claims: assertions about the subject and the token itself.
Standard registered claims: `iss` (issuer), `sub` (subject/user ID), `aud` (audience),
`exp` (expiry as Unix timestamp), `iat` (issued at), `nbf` (not valid before), `jti`
(JWT ID for revocation). Custom claims (application-specific): `scope`, `email`,
`roles`, `tenant_id`. The payload is readable by anyone who has the token - it is
Base64url encoded, not encrypted.

The signature is computed by: Base64url(header) + "." + Base64url(payload), signed
with the issuer's key using the algorithm specified in the header. For RS256: the
issuer applies RSASSA-PKCS1-v1_5-SHA256 with their private key. Validators verify
using the corresponding public key.

The signature proves: (1) the header and payload have not been modified since issuance
(integrity), (2) the token was created by the holder of the signing key (authenticity).
It does NOT prove that the payload is confidential (the payload is readable without
the key).

*What separates good from great:* Immediately noting that the payload is Base64, not
encrypted, and therefore should not contain sensitive data. Many developers learn about
JWT by seeing the "encoded" appearance and assume encryption is involved.

---

**[MID] Q2 (Mechanism): Why is RS256 preferred over HS256 in multi-service architectures?**

HS256 (HMAC-SHA256) uses a symmetric key: the same secret is used to both create and
validate the signature. Any service that needs to validate tokens must know the secret.
Any service that knows the secret can also CREATE valid tokens - they are equivalent.

In a microservices architecture with HS256: if the `order-service` needs to validate
tokens, it must know the HS256 secret. If `order-service` is compromised (RCE via
a vulnerability), the attacker now has the HS256 secret and can forge tokens for any
user with any claims. The attacker can create themselves an admin token and use it
against every other service.

RS256 (RSA-SHA256) uses asymmetric keys: the auth server signs with the private key;
all services validate with the public key. The public key, as the name implies, can be
public - it is shared via the JWKS endpoint (`/.well-known/jwks.json`). Knowing the
public key allows you to VERIFY tokens but not CREATE them (that requires the private key).

In a microservices architecture with RS256: compromising any service except the auth
server does not give the attacker the ability to forge tokens. They can read the
public key (it's public), but that's useless for creating forged tokens.

The rule: HS256 is appropriate when only one service both creates and validates tokens
(e.g., a monolith that issues and validates its own sessions). RS256 is required when
multiple services validate tokens independently.

*What separates good from great:* The mathematical asymmetry of RSA - you can publish
the public key in a JWKS endpoint that the whole internet can read, and it provides
zero advantage to an attacker. The private key is the only material that needs to be
protected, and it lives only on the auth server.

---

**[MID] Q3 (Mechanism): Explain the alg:none JWT vulnerability and how to prevent it.**

The `alg: none` vulnerability is a class of attacks where the JWT header specifies
`"alg": "none"`, indicating no signature is required. Some JWT library implementations
honor this and accept the token without signature verification.

Attack: the attacker takes a valid JWT and decodes it. They modify the payload (change
their user ID to an admin user, change their role to "admin", extend the expiry).
They re-encode the header with `"alg": "none"` and the modified payload. They remove
the signature entirely (or leave an empty string after the second dot). The resulting
token is `base64url(header).base64url(modified_payload).` (empty signature).

If the server's JWT library checks: "does the alg say none? Yes. Is alg:none allowed?
Yes (bad library). Verify signature: skip. Token accepted." The attacker is now admin.

Prevention: specify the expected algorithm(s) in the validator. Modern JWT libraries
require you to explicitly specify the expected algorithm and reject any token whose
header specifies a different algorithm. The library should also reject `alg: none`
by default unless explicitly allowed (which it never should be in production).

```java
// jjwt: explicit algorithm, rejecting none
Jwts.parserBuilder()
    .setSigningKey(publicKey)  // RS256 implied by PublicKey
    // jjwt 0.11+ rejects alg:none by default
    .build()
    .parseClaimsJws(token);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: jjwt 0.11+ configured with an RS256 public key to prevent both the alg:none attack and the RS256-to-HS256 confusion attack. (2) KEY MECHANISM: providing a `java.security.PublicKey` type to the parser constrains jjwt to accept only asymmetric algorithm tokens (RS256/ES256); an HS256-signed token would require a `SecretKey` type, which the parser rejects when given a `PublicKey`. (3) WHY IT MATTERS: the alg:none attack (strip signature, set alg=none) is entirely blocked in jjwt 0.11+ by default; the HS256-confusion attack requires the parser to accept both key types, which explicit `PublicKey` typing prevents. (4) WHAT BREAKS: using `Keys.hmacShaKeyFor(publicKeyBytes)` to create the verification key causes the confusion vulnerability - the type system protection is bypassed. (5) TAKEAWAY: use the strongly typed `PublicKey` object for RS256 verification; never convert a public key to bytes for HMAC verification; upgrade to jjwt 0.11+ where alg:none is rejected by default.

The public key type prevents alg:none AND HS256 confusion: if a `java.security.PublicKey`
is provided, jjwt will only accept RS256/ES256 tokens and automatically reject HS256
(which expects a symmetric key type).

*What separates good from great:* Knowing the RS256-to-HS256 confusion variant, which
is subtler: an attacker creates an HS256-signed token using the RS256 public key as the
HMAC secret (the public key is... public). If the validator was expecting RS256 but also
accepts HS256, and the HMAC validation uses the public key as the secret, the token
validates. The defense: the key object type prevents this - a `PublicKey` cannot be
used as an HMAC secret.

---

**[SENIOR] Q4 (Mechanism): How do you implement JWT key rotation without causing
authentication outages?**

JWT key rotation is a high-risk operation: the signing key changes, but tokens issued
with the old key are still in circulation (valid until their expiry).

The mechanism for zero-downtime rotation uses the `kid` (key ID) header claim:

Step 1 - Generate new key pair. Add the new public key to the JWKS endpoint alongside
the old key. The JWKS endpoint now returns both keys with distinct `kid` values.
Validators that check the `kid` header in incoming tokens will look up the correct key.

Step 2 - Update issuer to sign new tokens with the new private key, including the new
`kid` in the header.

Step 3 - Validators check the `kid` header and look up the matching key in the JWKS
cache. Old tokens (signed with old key, old kid) are validated with the old key. New
tokens (signed with new key, new kid) are validated with the new key. Both work during
the transition period.

Step 4 - Wait for old tokens to expire (typically 15-60 minutes for access tokens;
hours or days for refresh tokens). During this window, both keys must remain in the JWKS
endpoint.

Step 5 - Remove the old key from the JWKS endpoint. Any old token still in circulation
will now fail validation (key not found). If access token lifetime is 15 minutes,
wait at least 15 minutes from step 2 before removing the old key.

Critical implementation note: validators must refresh their JWKS cache when they encounter
a `kid` they don't recognize (not just on startup). Cache refresh triggers should be
rate-limited to prevent DoS via `kid` header manipulation.

*What separates good from great:* Handling the cache refresh trigger correctly. If an
attacker sends tokens with arbitrary `kid` values, a naive implementation might make
a JWKS endpoint request for every unknown `kid` - a DDOS vector. Correct implementation:
try known cached keys first; if no match, refresh the JWKS cache once per short period
(e.g., once per 5 minutes maximum, not once per request with unknown kid).

---

**[SENIOR] Q5 (Debugging): Your monitoring shows a sudden spike in authentication errors.
Investigation reveals malformed JWTs with modified payloads. What is happening?**

Malformed JWTs with modified payloads but invalid signatures indicate one of three
scenarios: an attack probe, a misconfigured client, or a library bug.

First, check whether the signature is actually invalid or if the validator is accepting
invalid signatures (a validator bug). Decode one of the "malformed" tokens and compare
its signature bytes to what would be expected for the header+payload with the signing key.
If the signature is genuinely invalid, the validator is working correctly.

Attack probe: an attacker is testing for JWT vulnerabilities - they take a valid token,
modify the payload, and see if the server accepts it. The signature fails; errors are
expected. This is normal attack surface probing. Response: no action required beyond
confirming the validator is rejecting them. Optionally, add rate limiting on authentication
errors per IP to slow the probing.

Client bug: a client library may be creating malformed tokens. Check the `iss` and
`sub` fields - if they match real users but the signature is wrong, a client is
generating tokens incorrectly. Contact the client team.

Rotation issue: if the signing key was recently rotated, check whether all auth server
instances have the new key (key rotation should be atomic). If some instances sign with
the old key and validators have already removed it, those tokens will have "valid" signatures
that validators call "invalid" because the key is gone. Fix: ensure JWKS endpoint
retains old keys until all tokens signed with them have expired.

Check for JWT library version: some JWT library versions have bugs in signature validation
that manifest as intermittent failures. Check if errors correlate with specific token
issuance times or token structures.

*What separates good from great:* Distinguishing between "the signature is invalid"
(correct behavior, attack or client bug) versus "a valid signature is being wrongly rejected"
(validator bug or key rotation issue). The diagnosis path is different: decode the token,
manually verify the signature offline, and compare to the error.

---

**[SENIOR] Q6 (Trade-off): When would you add a JWT token blocklist despite JWTs
being designed to be stateless?**

JWTs are designed to be stateless - any validator can verify them without a database
call. Adding a blocklist reintroduces state, partly defeating this design goal. But
there are scenarios where the revocation capability outweighs the stateless benefit.

Scenarios requiring a blocklist: (1) Security incidents: a user account is compromised
and password reset, but active JWTs remain valid for their remaining lifetime (up to
15-60 minutes). For a financial service, 15 minutes of unauthorized access post-
compromise is unacceptable. (2) User logout in high-security contexts: healthcare and
banking applications require that logout immediately terminates all access, not just
after the token expiry. (3) Privilege revocation: an admin is removed from their role,
but they have an active admin-scoped JWT. The privilege revocation must take effect
immediately. (4) Token theft detection: refresh token rotation detects theft (the
old token is used after being rotated), but the access token issued from the stolen
refresh token is still valid until expiry.

Implementation: use a Redis-based blocklist with TTL matching the token's remaining
validity. The blocklist entry can be the JWT's `jti` (JWT ID) claim - a unique
identifier per token. The validator checks: signature valid AND `jti` not in blocklist.
TTL means blocklist entries self-clean when the token would have expired anyway.

Performance impact: a Redis GET adds ~1ms latency per request. For most APIs, this
is acceptable. At 50,000 RPS with 1ms additional latency: if blocklist check is on the
critical path, this adds ~50 seconds of aggregate latency per second - still one additional
network hop, not a bottleneck with Redis.

*What separates good from great:* Recognizing that the blocklist only needs to contain
explicitly revoked tokens, not all tokens. The baseline protection is the short expiry;
the blocklist handles the exceptional cases (security incidents, high-security contexts).
Most tokens never enter the blocklist - their expiry is the primary revocation mechanism.

---

**[SENIOR] Q7 (Trade-off): A colleague suggests using long-lived JWTs (30 days) to
reduce refresh token complexity. What is your response?**

I would explain the security risks clearly, propose an alternative that meets the
business need, and let the team make an informed decision.

The security problem with 30-day JWTs: if a token is stolen - from a client device,
via XSS, from a log file, from a network intercept before HTTPS - the attacker has
30 days of API access. If the user changes their password (common response to suspected
account compromise), the JWT remains valid for 30 days. There is no revocation mechanism
unless a blocklist is implemented (which adds the state that was meant to be avoided).

The legitimate business need: reducing refresh overhead. Refreshing tokens every
15-60 minutes requires the client to implement refresh logic and handle refresh failures.

Alternative that meets the need: use short-lived access tokens (15-60 minutes) with
long-lived opaque refresh tokens (30 days). Access tokens are stateless JWTs for
API authorization. Refresh tokens are stored server-side with a reference in an
HttpOnly cookie. The access token expiry means a stolen access token has a max 60-minute
window. The refresh token's server-side storage allows immediate revocation on compromise.
Refresh token rotation detects theft.

The client experience is equivalent: transparent token refresh happens in the background;
the user stays logged in for 30 days. The security posture is dramatically better.

If the team insists on long-lived JWTs: implement a blocklist (Redis with TTL) and a
clear process for revoking tokens on security events. Document the 30-day window as an
accepted risk with explicit approval.

*What separates good from great:* Framing security recommendations as alternatives
that meet business needs, not just objections. "Use short-lived JWTs with refresh tokens"
solves the problem the colleague was trying to solve while maintaining the security
posture. Engineering decisions are rarely about "secure vs convenient" - they are about
finding the correct trade-off.

---

**[STAFF] Q8 (Deep Dive): How does the JWKS (JSON Web Key Set) endpoint work and
what are its security considerations?**

The JWKS endpoint (typically at `/.well-known/jwks.json`) is a public URL that serves
the authorization server's current public keys in a standardized JSON format. It
enables validators to fetch the correct verification key for any JWT, supporting
key rotation without out-of-band key distribution.

JWKS format: the endpoint returns a JSON object with a `keys` array. Each key has:
`kty` (key type: RSA, EC), `alg` (algorithm: RS256), `use` (purpose: sig for signing),
`kid` (key ID matching the JWT header), and the key material (`n` and `e` for RSA: modulus
and exponent).

Validator behavior: the validator maintains a cache of JWKS keys. On receiving a JWT,
it checks the `kid` header, finds the matching key in the cache, and verifies the
signature. If `kid` is not in the cache, it fetches the JWKS endpoint (with a rate
limit to prevent DoS), updates the cache, and retries.

Security considerations:

JWKS endpoint availability: the JWKS endpoint is a dependency for all JWT validation.
If it goes down and the cache expires, authentication fails across all services. Solution:
use a long cache TTL (1 hour) and proactive cache refresh; continue using cached keys
even after TTL on endpoint failure (degraded mode).

`jku` and `x5u` header injection: JWT headers can include `jku` (JWKS URL) and `x5u`
(X.509 certificate URL). A vulnerable validator that fetches the JWKS URL from the
JWT header can be redirected to a JWKS endpoint the attacker controls, serving attacker-
generated keys that validate attacker-forged tokens. Fix: NEVER use `jku` or `x5u`
from the token header; use only pre-configured JWKS endpoint URLs.

Key ID confusion: if multiple auth servers share the same `kid` values, a token from
auth-server-A could be validated using auth-server-B's key (if they happen to have
the same kid). Fix: validate the issuer BEFORE the signature; use the issuer to look
up the correct JWKS endpoint.

*What separates good from great:* Understanding the `jku` injection attack as the
JWT equivalent of DNS rebinding: the token header tells the validator where to get the
key for verifying itself. This is like a signed document telling you "trust the signature
- here is the notary to verify it" while the document author controls who the notary
is. Never trust self-referential key references.

---

**[SENIOR] Q9 (Behavioral): You are reviewing a PR that introduces JWT for a new microservice. What do you check?**

A JWT PR review covers algorithm choice, validation completeness, secret management,
and token design.

Algorithm choice: Is `alg` hardcoded to RS256 or ES256? Is HS256 forced via a symmetric
key type? Are the algorithm none and HS256-confusion attacks prevented by using a
`PublicKey` type for verification? If the service uses a third-party auth server,
does it validate the issuer before the signature?

Validation completeness: Does the validation code check all seven required claims -
signature, expiry, not-before, issuer, audience, key-id, algorithm? Does it use a
well-maintained library or roll its own verification? Any custom claims with
authorization semantics must also be validated.

Secret management: If HS256 is used, where is the signing secret stored? Hard-coded
secrets or secrets in source control are immediate rejections. Proper storage: Vault,
AWS Secrets Manager, or Kubernetes secrets with RBAC. Key rotation: how does the
service pick up new keys without downtime?

Token design: Are there sensitive fields (PII, raw roles) in the payload? JWT payloads
are Base64, not encrypted - do not put secrets, passwords, or sensitive user data in
claims. Token lifetime: is expiry set appropriately (15 min for access tokens)? Is
there a refresh token mechanism for user-facing flows?

*What separates good from great:* Checking the rejection path. Many validators return
200 on validation errors with a specific error claim instead of returning 401. The
service must propagate the 401 to callers so upstream rate limiting and monitoring
pick up authentication failures correctly.
