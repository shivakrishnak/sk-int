---
layout: default
title: "Distributed Systems - L3 Security"
parent: "Distributed Systems"
grand_parent: "SK Interview"
nav_order: 12
permalink: /distributed-systems/l3-security/
---

# mTLS and Service-to-Service Authentication

**TL;DR:** Mutual TLS (mTLS) is a protocol where BOTH the client
and server present X.509 certificates and authenticate each other.
In a microservices architecture, mTLS provides service-to-service
authentication: each service has a certificate that proves its
identity. A compromised service cannot impersonate another
(unless its private key is stolen). Service meshes (Istio, Linkerd)
provision and rotate certificates automatically via a Certificate
Authority (CA), making mTLS transparent to application code.

---

### 🎯 Model Answer

**30 seconds:**
> mTLS is TLS where both sides present certificates. Normal HTTPS:
> the server proves its identity to the client. mTLS: both the
> server AND the client prove their identities. In microservices,
> mTLS authenticates service-to-service calls: Service A presents
> a certificate signed by the mesh CA. Service B verifies it.
> Service B presents its certificate. Service A verifies it.
> Only services with valid mesh-issued certificates can communicate.

**3 minutes:**
> Standard TLS is one-way: the server proves its identity to the
> client (the browser verifies the bank's certificate). The client
> is anonymous. mTLS extends this: the client also proves its
> identity to the server using an X.509 certificate.
>
> In microservices, mTLS provides the "zero trust" service identity
> layer: each service receives a certificate from the mesh CA
> (e.g., Citadel in Istio). When Service A calls Service B, both
> sides present their certificates. Service B verifies that A's
> certificate was signed by the mesh CA and contains the expected
> SPIFFE ID (e.g., `spiffe://cluster.local/ns/default/sa/service-a`).
> Service A verifies B's certificate similarly. If either side's
> certificate is invalid or absent: the connection is rejected.
>
> The service mesh sidecar proxy (Envoy in Istio) handles all TLS
> termination transparently. Application code calls `http://service-b`
> and does not know that mTLS is happening. The sidecar intercepts
> the outbound call, upgrades it to mTLS using the pod's certificate,
> and forwards to Service B's sidecar, which also validates the
> certificate before forwarding to the application.

**Blank Mind Recovery:**

**(1) Restate:** "mTLS - mutual TLS - both sides show a certificate.
Client proves identity to server AND server proves identity to client."

**(2) First principles:** "Normal TLS: you verify the server (bank
certificate). mTLS: the server also verifies you (you show a
certificate). In microservices: services are both clients and
servers. mTLS prevents a compromised network path from accepting
calls from unauthorized services."

**(3) Bridge:** "Like a building where everyone shows an ID card
AND the building shows its official badge to you. Both sides
authenticate. No one can enter without an ID, and no door can
be faked."

---

### 📘 Concept Explanation

**What it is:**
A TLS extension where both the client and server authenticate
each other using X.509 certificates. The mTLS handshake includes
both `Certificate` and `CertificateVerify` messages from both parties.

**The problem it solves:**
In a distributed microservices environment, services communicate
over a network that may not be fully trusted (east-west traffic).
Service-to-service authentication ensures that only authorized
services can communicate, preventing: unauthorized access by
a compromised service, man-in-the-middle attacks between services,
and lateral movement after a network breach.

**mTLS handshake:**

```
Standard TLS (one-way):
  Client → Server: ClientHello
  Server → Client: ServerHello + Certificate
  Client: verify server certificate
  Client → Server: ClientKeyExchange
  Both: derive session keys
  Both: encrypted communication

mTLS (mutual):
  Client → Server: ClientHello
  Server → Client: ServerHello + Certificate
                   + CertificateRequest   ← added
  Client: verify server certificate
  Client → Server: Certificate            ← added (client cert)
                   ClientKeyExchange
                   CertificateVerify      ← added (signature)
  Server: verify client certificate
  Both: derive session keys
  Both: encrypted communication

If client certificate is invalid or missing:
  → Server sends alert, closes connection
```

**SPIFFE: Secure Production Identity Framework for Everyone**

```
SPIFFE provides a standard identity format for services:
  spiffe://{trust-domain}/path/to/service

Example in Kubernetes (Istio):
  spiffe://cluster.local/ns/payments/sa/payment-service

The SVID (SPIFFE Verifiable Identity Document) is an X.509
certificate where the Subject Alternative Name contains
the SPIFFE URI.

Service mesh issues SVIDs:
  payment-service pod → Citadel CA issues:
    Subject: O=cluster.local, CN=payment-service
    SAN: spiffe://cluster.local/ns/payments/sa/payment-service
    Valid for: 24 hours (auto-rotated)

When payment-service calls order-service:
  mTLS handshake exchanges SVIDs
  order-service verifies:
    - Certificate signed by mesh CA? YES
    - SPIFFE URI matches expected service? YES
    - Certificate not expired? YES
  → connection allowed

Authorization policy can then use the SPIFFE URI:
  "Allow calls to /orders endpoint only from
   payment-service SPIFFE ID"
```

**Certificate rotation:**

```
Istio Citadel automatic rotation:
  1. Each pod gets a certificate via the CSR (Certificate
     Signing Request) protocol on startup
  2. Default TTL: 24 hours
  3. At 80% TTL (19.2 hours): agent sends new CSR to Citadel
  4. Citadel issues new certificate
  5. New certificate loaded into envoy without pod restart
  6. Old certificate valid until 100% TTL (graceful cutover)
  
  Manual certificate: rotation requires pod restart
  Mesh certificate: zero-downtime rotation
```

**The key insight:**
mTLS is most powerful when combined with authorization policies
based on service identity. Authentication (who are you?) is only
half: you also need authorization (are you allowed to call this
endpoint?). Istio's AuthorizationPolicy uses SPIFFE IDs to
specify per-service, per-endpoint access rules.

**When to use it:**
- Any microservices environment where east-west traffic must
  be secured (financial services, healthcare, regulated industries)
- Zero-trust network architecture
- When network-level security (VPC, firewall) is insufficient
  for service-level access control

**When NOT to use it:**
- Simple systems where all services are fully trusted (e.g.,
  single-team monorepo, all services in the same process)
- Systems where the added latency of mTLS handshake is
  unacceptable for very latency-sensitive calls
  (amortized via connection reuse: TLS 1.3 reduces handshake cost)
- External client connections (use API key / OAuth token instead)

**Alternatives:**
- API key headers: simpler but not cryptographically verified;
  key can be stolen from logs or environment variables
- JWT-based service identity: service presents a signed JWT;
  no PKI infrastructure required; but JWT validation adds latency
- Network policies (Kubernetes NetworkPolicy): coarse-grained
  (pod-level), not service-level; no encryption

**First-principles derivation:**
"A certificate is a public key plus a digital signature from a
CA. If I trust the CA, I can verify the certificate. If each
service has a CA-signed certificate, I can verify any service's
identity by checking its certificate against the CA. mTLS makes
this a protocol-level guarantee - no application code required."

---

### 💻 Code Example

```java
// mTLS IN SPRING BOOT (server-side config)

// BAD: no client authentication - any client can connect
@Bean
public TomcatServletWebServerFactory serverFactory() {
    TomcatServletWebServerFactory factory =
        new TomcatServletWebServerFactory();
    factory.addConnectorCustomizers(connector -> {
        connector.setPort(8443);
        connector.setSecure(true);
        connector.setScheme("https");
        // BAD: no client auth = one-way TLS only
    });
    return factory;
}

// GOOD: mutual TLS with client certificate required
# application.yml
# server:
#   ssl:
#     enabled: true
#     key-store: classpath:keystore.p12
#     key-store-password: changeit
#     key-store-type: PKCS12
#     trust-store: classpath:truststore.p12
#     trust-store-password: changeit
#     client-auth: need  # ← REQUIRE client cert

// GOOD: RestTemplate (client) with mTLS
@Bean
public RestTemplate mtlsRestTemplate() throws Exception {
    SSLContext sslContext = SSLContextBuilder.create()
        // Client certificate (this service's identity)
        .loadKeyMaterial(
            ResourceUtils.getFile("classpath:client.p12"),
            "changeit".toCharArray(),
            "changeit".toCharArray())
        // Trust store (mesh CA certificate)
        .loadTrustMaterial(
            ResourceUtils.getFile(
                "classpath:truststore.p12"),
            "changeit".toCharArray())
        .build();

    CloseableHttpClient httpClient = HttpClients.custom()
        .setSSLContext(sslContext)
        .setSSLHostnameVerifier(
            new DefaultHostnameVerifier())
        .build();

    HttpComponentsClientHttpRequestFactory factory =
        new HttpComponentsClientHttpRequestFactory(
            httpClient);

    return new RestTemplate(factory);
}
```

> **Code walkthrough:** The BAD pattern configures HTTPS (one-way
> TLS) without client authentication - any HTTP client can call
> the service. The GOOD server configuration adds `client-auth: need`
> which requires every client to present a valid certificate signed
> by the trust store's CA. The GOOD client configuration loads both
> the client's own certificate (proving its identity to the server)
> and a trust store (verifying the server's certificate). Both sides
> authenticate: mTLS. In production with a service mesh, this Spring
> Boot configuration is replaced by Envoy sidecar configuration -
> the application listens on plain HTTP, and Envoy handles mTLS
> termination.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> mTLS extends normal HTTPS by requiring both the server and the
> client to present valid certificates. In microservices, each
> service gets a certificate from the mesh CA. When Service A calls
> Service B, both exchange certificates and verify they are signed
> by the mesh CA. Only services with valid mesh certificates can
> communicate. The service mesh (Istio) handles this automatically -
> application code does not need to change.

---

**Senior / Staff:**
> mTLS is the authentication layer in a zero-trust architecture.
> I care about three operational concerns: (1) certificate rotation
> must be automatic and zero-downtime (24-hour TTL with 80% renewal).
> (2) mTLS must be enforced via PeerAuthentication policy in STRICT
> mode - PERMISSIVE mode allows non-mTLS traffic, which defeats the
> purpose and is a misconfiguration risk. (3) mTLS is authentication
> only - I layer AuthorizationPolicy on top to specify which services
> can call which endpoints. Without AuthorizationPolicy, any
> mesh-enrolled service can call any other service.

---

### ⚠️ Common Misconceptions

**"mTLS in a service mesh is encryption only"**

Reality: mTLS provides both encryption AND authentication. The
encryption is the same as TLS (AES-GCM cipher suite). Authentication
is the added value: each service's identity is verified via a
certificate. Many teams enable mTLS for encryption but do not
configure AuthorizationPolicy - they get authentication but no
access control. A compromised service inside the mesh can still
call any other service. mTLS + AuthorizationPolicy together
provide the "zero trust" guarantee.

**"My services are in a private VPC, so I do not need mTLS"**

Reality: network perimeter security (VPC, security groups) is
necessary but not sufficient. Once an attacker compromises any
service inside the VPC (through a vulnerability), they have
unrestricted access to all other services. mTLS enforces
service-level access control: even inside the VPC, a compromised
service cannot call services its SPIFFE ID is not authorized for.
This is the "lateral movement prevention" layer.

---

### ⚖️ Comparison Table

| Approach | Authentication | Encryption | Complexity | Rotation | Use When |
|---|---|---|---|---|---|
| mTLS (service mesh) | Cryptographic | Yes (TLS) | High (infra) | Automatic | Regulated; zero-trust |
| API keys (header) | Shared secret | Requires TLS | Low | Manual | External clients |
| JWT service token | Signed claim | Requires TLS | Medium | Short TTL | Stateless, no PKI |
| Network policy | IP/port | No | Low | N/A | Coarse isolation |
| mTLS (manual) | Cryptographic | Yes (TLS) | Very high | Manual | Small, no mesh |

**The deciding factor:** Is this regulated or high-security?
Use mTLS with a service mesh. Is this a small deployment without
Kubernetes? Use JWT service tokens. Is this an external client?
Use OAuth 2.0 / API key with TLS.

---

### 🔥 Field Q&A

#### Production Failures

Q: Services are failing to connect after a certificate rotation.
Some pods cannot communicate with others. How do you diagnose?

A: Certificate rotation failures typically appear as TLS handshake
errors. Diagnosis: (1) Check envoy sidecar logs for `CERTIFICATE_VERIFY`
or `HANDSHAKE_FAILURE` errors: `kubectl logs <pod> -c istio-proxy | grep -i cert`.
(2) Check certificate expiry: `openssl s_client -connect service:port -showcerts`
to see the certificate being presented. (3) Check if the new
certificate has the correct SPIFFE URI (SAN field):
`openssl x509 -in cert.pem -text | grep URI`.
(4) Check if the trust store on the verifying side includes the
new CA certificate (rotation of the CA itself requires updating
trust stores everywhere). (5) In Istio: check Citadel logs for
CSR signing failures. Check that the mesh pod's service account
has the permissions to request certificates. Fix: if the CA
certificate changed: roll out the new CA root to all trust stores
before revoking the old one (two-phase CA rotation).

#### Candidate Mistakes

Q: How does mTLS differ from regular HTTPS?

**What NOT to say:** "mTLS uses a special certificate format."

**Say instead:** "Regular HTTPS is one-way TLS: the server presents
a certificate, the client verifies it. The client is anonymous from
a certificate perspective (it may authenticate via API key or session
cookie at the application layer, but not at the TLS layer). mTLS is
mutual TLS: both the server AND the client present X.509 certificates,
and both verify each other's certificate against a trusted CA. In a
microservices environment, each service acts as both a client (making
calls) and a server (receiving calls). mTLS gives each service a
cryptographically verifiable identity at the protocol level - no
shared secrets, no API keys in headers that can be leaked. The service
mesh (Istio, Linkerd) automates certificate issuance and rotation,
so application code does not need to change."

---

---

# Authorization in Microservices

**TL;DR:** Authorization in microservices is complex because a
single user request touches multiple services. The main patterns:
(1) centralized authorization service (AuthZ) that all services
call, (2) distributed JWT-based authorization where each service
validates the token independently, (3) policy-as-code with OPA
(Open Policy Agent) sidecar for fine-grained, auditable rules.
Pass user identity as a JWT in the Authorization header; propagate
it through all service-to-service calls.

---

### 🎯 Model Answer

**30 seconds:**
> Authorization in microservices: who can do what, enforced across
> multiple services. The challenge: a user request fans out across
> 5 services - each must enforce authorization without duplicating
> logic. Main patterns: JWT-based (each service validates the JWT),
> centralized AuthZ service (all services call a central policy
> engine), or OPA sidecar (policy-as-code evaluated at the sidecar
> level). JWT propagation through all service calls is mandatory.

**3 minutes:**
> In a monolith, authorization is straightforward: one service
> checks one set of rules. In microservices, a user request fans
> out: the API gateway, the Order service, the Inventory service,
> and the Payment service all need to enforce that the user is
> authorized for the specific operation.
>
> Three main patterns: (1) JWT propagation - the API gateway
> validates the user's OAuth JWT token and passes it to downstream
> services via the `Authorization: Bearer <token>` header. Each
> service independently validates the JWT signature and checks
> claims. No central authorization server required for each call.
> Scalable but coarse-grained.
>
> (2) Centralized AuthZ (policy decision point) - services call a
> central authorization service to ask "can user X perform action Y
> on resource Z?" The AuthZ service evaluates rules against user
> attributes, resource attributes, and environment context (ABAC).
> Flexible but adds latency per authorization call.
>
> (3) OPA (Open Policy Agent) - policy-as-code. Rules written in
> Rego language, deployed as a sidecar or daemonset. Services query
> OPA for decisions. OPA evaluates locally (no network call to a
> central service for most decisions). Policies are version-controlled,
> testable, and auditable.

**Blank Mind Recovery:**

**(1) Restate:** "Authorization = can this user/service do this
action? In microservices: enforced at every service, not just
the gateway."

**(2) First principles:** "Who? What? On what? These three questions
define an authorization decision. In microservices: the user context
(who) must be passed from service to service via a token. Each
service answers: is this user allowed to do this? Using the token
to extract identity and check permissions."

**(3) Bridge:** "Like a hospital where your badge is checked at the
front door (authentication) and then at each department (authorization).
The badge carries your role (doctor, nurse) - the JWT. Each department
has its own rules: only surgeons enter the OR. Each service enforces
its own rules using the JWT claims."

---

### 📘 Concept Explanation

**What it is:**
The enforcement of access control policies across multiple services
in a distributed system. Determines which authenticated user or
service is allowed to perform which operation on which resource.

**The problem it solves:**
In a monolith, authorization logic is centralized. In microservices,
it must be distributed: every service that receives a user request
must enforce authorization. Without a clear strategy, authorization
logic is duplicated across services, inconsistently enforced,
and hard to audit or change.

**JWT propagation pattern:**

```
API Gateway:
  1. Receives user request with OAuth access token
  2. Validates token signature (using JWKS endpoint)
  3. Extracts claims: userId, roles, tenantId
  4. Forwards request to Service A with original token
     Authorization: Bearer <original_jwt>
     OR
     Creates a new internal JWT with extracted claims

Service A → Service B (service-to-service call):
  Must forward the user context:
  - Include the user's JWT in the outbound request
  - Do NOT strip the Authorization header
  - Do NOT use service identity (mTLS) alone for user authorization

Service B:
  1. Validates JWT signature (JWKS, cached public key)
  2. Extracts userId, roles from claims
  3. Checks: does role 'VIEWER' allow POST /orders? NO → 403
  4. Checks: does userId own resource X? YES → allow
```

**Role-based access control (RBAC) vs. Attribute-based (ABAC):**

```
RBAC - Role-Based Access Control:
  User has roles: ADMIN, VIEWER, EDITOR
  Service checks: does role EDITOR allow POST /orders? YES

  Simple, fast, easy to implement
  Limitation: coarse-grained (all EDITORs can edit everything)
  Good for: most internal services, standard CRUD operations

ABAC - Attribute-Based Access Control:
  Decision based on:
    - User attributes (department, clearance level, tenantId)
    - Resource attributes (owner, classification, tenantId)
    - Environment (time of day, IP range, request rate)
  
  Policy: "Allow if user.department = resource.department
           AND time IN [09:00, 17:00] AND user.clearance >= 2"

  Flexible, fine-grained
  Limitation: complex policy management, harder to debug
  Good for: regulated industries, multi-tenant SaaS,
            complex permission models

OPA (Open Policy Agent) - ABAC with policy-as-code:
  Policy in Rego language (version-controlled, testable):
  
  allow if {
    input.user.roles[_] == "ADMIN"
  }
  
  allow if {
    input.user.tenantId == input.resource.tenantId
    input.method == "GET"
  }
```

**Multi-tenant authorization:**

```
Critical: tenant isolation
  Every resource must have a tenantId
  Every authorization check must include tenantId comparison
  
  BAD: JWT contains userId; service fetches resource by resourceId
       only → can access other tenants' resources

  GOOD: JWT contains userId + tenantId
        Service query:
          WHERE resource.id = :resourceId
            AND resource.tenantId = :jwtTenantId
        
        If the resourceId belongs to a different tenant:
          the WHERE clause returns nothing → 404 (not 403)
          (Do NOT tell the user the resource exists but is
          forbidden - that leaks tenant data)
```

**Token exchange (service-to-service with user context):**

```
Problem: Service A calls Service B on behalf of User X.
         Service B needs to know: who is User X?
         But the original JWT is issued for Service A's audience.

OAuth 2.0 Token Exchange (RFC 8693):
  Service A requests a new token from the auth server
    subject_token = User X's original JWT
    subject_token_type = access_token
    requested_token_type = access_token
    audience = service-b.internal

  Auth server issues a new JWT:
    sub = User X
    aud = service-b.internal
    act = service-a (acting party)

  Service A calls Service B with the exchanged token.
  Service B validates: aud = service-b.internal ✓
                       sub = User X (carries user context) ✓
```

**The key insight:**
Authentication and authorization are separate concerns. mTLS
handles service-to-service authentication (who is calling).
JWT handles user authorization (is the user allowed to do this).
Both are required in a zero-trust microservices architecture.

**When to use centralized AuthZ (OPA/Casbin):**
- Multi-tenant SaaS with complex, dynamic permission rules
- Regulated industries requiring auditable policy decisions
- When authorization rules change frequently and must be
  updated without code deployments

**When to use distributed JWT-based AuthZ:**
- Simple RBAC (role-based rules, checked in each service)
- High-throughput services where a remote AuthZ call per request
  adds unacceptable latency
- Most internal services in a single-tenant system

**Alternatives:**
- Casbin (Go/Java library): embeddable authorization library
  with multiple model types (RBAC, ABAC, ACL)
- Keycloak Authorization Services: centralized RBAC/ABAC
  with admin UI
- AWS Cognito + API Gateway: for AWS-native systems

**First-principles derivation:**
"Authorization is: given an identity, a resource, and an action,
is the action permitted? In microservices: the identity must be
carried from service to service (JWT). Each service must evaluate
the permission rule. The rules can live in the service (RBAC in code),
in a policy engine (OPA), or in a central AuthZ service."

---

### 💻 Code Example

```java
// AUTHORIZATION IN SPRING BOOT MICROSERVICES

// BAD: checking authorization in every service method manually
@GetMapping("/orders/{orderId}")
public Order getOrder(
        @PathVariable String orderId,
        HttpServletRequest request) {
    // BAD: no authorization check at all
    // BAD: or manual check without standard approach
    String role = extractRole(
        request.getHeader("Authorization"));
    if (!role.equals("ADMIN")) {  // coarse, duplicated
        throw new ForbiddenException();
    }
    return orderRepo.findById(orderId).orElseThrow();
}

// GOOD: Spring Security with JWT-based authorization
@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())  // stateless API
            .sessionManagement(sm -> sm
                .sessionCreationPolicy(
                    SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health")
                    .permitAll()
                .anyRequest().authenticated())
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(
                    jwtAuthConverter())));
        return http.build();
    }
}

// Service method: use @PreAuthorize with SpEL
@RestController
@RequestMapping("/orders")
public class OrderController {

    @GetMapping("/{orderId}")
    @PreAuthorize(
        "hasRole('VIEWER') or hasRole('ADMIN')")
    public Order getOrder(
            @PathVariable String orderId,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getSubject();
        String tenantId = jwt.getClaimAsString("tenantId");
        // GOOD: include tenantId in query (tenant isolation)
        return orderRepo
            .findByIdAndTenantId(orderId, tenantId)
            .orElseThrow(() -> new NotFoundException());
        // Returns 404 if wrong tenant (not 403 - no leak)
    }

    @PostMapping
    @PreAuthorize("hasRole('EDITOR') or hasRole('ADMIN')")
    public Order createOrder(
            @RequestBody OrderRequest req,
            @AuthenticationPrincipal Jwt jwt) {
        req.setTenantId(jwt.getClaimAsString("tenantId"));
        return orderService.create(req);
    }
}
```

> **Code walkthrough:** The BAD pattern manually extracts and
> checks roles in every endpoint - duplicated logic, easy to
> forget, not standardized. The GOOD pattern uses Spring Security's
> `@oauth2ResourceServer` to validate the JWT automatically (signature
> check against the auth server's JWKS endpoint). `@PreAuthorize`
> declaratively specifies role requirements per endpoint. The
> critical detail: the `findByIdAndTenantId` query includes the
> tenant ID from the JWT in the database query. This enforces tenant
> isolation at the data layer - even if the authorization check
> passes, a user from Tenant A cannot retrieve Tenant B's orders
> because the query returns no rows for a cross-tenant resource ID.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Authorization in microservices means each service verifies that
> the caller is allowed to perform the requested operation. The user's
> identity is carried in a JWT token that is validated by each service.
> Spring Security with `@PreAuthorize` handles this declaratively.
> Multi-tenant systems must include the tenant ID from the JWT in
> all database queries to prevent cross-tenant data access.

---

**Senior / Staff:**
> I think about authorization at three layers: (1) API gateway:
> validates the token (signature, expiry, audience). Rejects
> unauthenticated requests before they reach any service.
> (2) Service layer: `@PreAuthorize` role checks. Validates the
> user has the required role for the operation. (3) Data layer:
> all queries include tenantId (or ownerId) from the JWT claims.
> This is the safety net - even if layers 1-2 have a bug, the
> data layer ensures cross-tenant isolation. For complex permission
> models (per-resource, dynamic rules): OPA as a sidecar with
> Rego policies. Policies are version-controlled, testable with
> `opa test`, and deployable independently of service code.

---

### ⚠️ Common Misconceptions

**"The API gateway handles authorization - services do not need
their own checks"**

Reality: gateway authorization is coarse-grained (is the user
authenticated, do they have the right subscription tier). Services
have resource-level rules: can THIS user access THIS specific resource?
The gateway does not know which tenant owns which order. This
is resource-level authorization that only the service can enforce.
Also: if a service is ever called directly (e.g., service-to-service
without going through the gateway), it must enforce its own rules.
Never rely on a single authorization point for distributed systems.

**"JWT tokens are safe to trust without validation"**

Reality: a JWT's signature must be verified against the auth
server's public key (JWKS endpoint) on every request (or the public
key must be cached locally). An unsigned or incorrectly signed JWT
must be rejected. Common mistake: validating the JWT format but
not the signature, or using `none` algorithm JWTs in development
and accidentally deploying without the algorithm restriction.
Always configure the JWT validator to only accept specific
algorithms (e.g., `RS256` or `ES256` - never `none`).

---

### ⚖️ Comparison Table

| Pattern | Complexity | Latency | Flexibility | Update Without Deploy | Use When |
|---|---|---|---|---|---|
| JWT RBAC in code | Low | None | Low | No | Simple roles, stable rules |
| Centralized AuthZ service | High | +5-20ms/req | High | Yes | Complex dynamic rules |
| OPA sidecar | Medium | +1-2ms local | High | Yes | Policy-as-code, auditing |
| Keycloak AuthZ | Medium | +5ms | Medium | Yes (admin UI) | Admin-managed permissions |
| Data-layer tenantId | None | None (query) | N/A | N/A | Multi-tenant isolation |

**The deciding factor:** How often do authorization rules change
and who controls them? If stable rules controlled by developers:
JWT RBAC in code. If dynamic rules controlled by non-developers
(ops, legal, compliance): OPA or centralized AuthZ. Multi-tenant:
data-layer tenantId isolation is ALWAYS required regardless of
the authorization pattern chosen.

---

### 🔥 Field Q&A

#### Production Failures

Q: A multi-tenant SaaS has a data breach: Tenant A's data was
accessed by Tenant B's users. The API gateway was properly
configured. How did this happen and how do you fix it?

A: This is a horizontal privilege escalation (tenant isolation
failure). The gateway check authenticated the user and confirmed
their role. The service authorized the role for the operation.
But the query fetched the resource by ID without filtering by
tenant. Tenant B's user called `GET /orders/12345` where order
12345 belongs to Tenant A. The service found the order and returned
it. The fix: (1) Add `tenantId` claim to JWT (if not already there).
(2) Change all repository queries to include `WHERE tenantId = :jwtTenantId`.
(3) Return 404 (not 403) for cross-tenant access - do not confirm
the resource exists to the wrong tenant. (4) Add integration tests
specifically for cross-tenant access: create a resource as Tenant A,
attempt to access it as Tenant B, assert 404. (5) Audit logs: log
all authorization decisions including tenantId for forensic analysis.

#### Candidate Mistakes

Q: How do you propagate user context through service-to-service calls?

**What NOT to say:** "Each service calls the auth server to get
the user's identity."

**Say instead:** "The user's JWT is passed through every service
call using the `Authorization: Bearer <token>` header. The first
service that receives the user request (API gateway or BFF) validates
the JWT. Downstream services also validate the JWT signature (using
a cached copy of the auth server's public key from the JWKS endpoint).
They do NOT call the auth server on every request - that would be
a severe bottleneck. The public key is cached for the duration of
its validity (typically hours). When Service A calls Service B on
behalf of the user: Service A includes the same Authorization header
in the outbound call. In Spring Boot: use a `ClientHttpRequestInterceptor`
on the RestTemplate or a WebClient filter that automatically propagates
the incoming Authorization header from the SecurityContext. Never
hardcode the user ID into the request body - always carry it in the
token so it cannot be tampered with."

### 🚨 Failure Modes and Diagnosis

**Failure 1: Certificate rotation breaks mTLS - pods cannot
communicate after CA rotation**

Symptom: After a CA certificate rotation, some services fail to
connect to others. TLS handshake failures in proxy logs.

Root cause: CA rotation done in one step (old CA removed before
all pods received the new CA's trust). Pods with old trust stores
do not trust the new CA. Pods with new trust stores do not trust
the old CA. Both see handshake failures.

Diagnosis:
```bash
# Check for TLS errors in Istio proxy
kubectl logs <pod> -c istio-proxy | grep -E \
  "HANDSHAKE|CERTIFICATE|TLS" | tail -50

# Check which CA the pod currently trusts
istioctl proxy-config secret <pod> -o json | \
  jq '.dynamicActiveSecrets[].secret.name'

# Check certificate expiry
istioctl proxy-config secret <pod> --name \
  "default" -o json | jq \
  '.dynamicActiveSecrets[0].secret.tlsCertificate
   .certificateChain.inlineBytes' | \
  base64 -d | openssl x509 -noout -dates
```

Fix: Use two-phase CA rotation. Phase 1: add new CA to all trust
stores (both old and new CAs trusted). Phase 2: issue new leaf
certificates signed by new CA. Phase 3: remove old CA from trust
stores. Each phase must complete before the next starts.

---

**Failure 2: JWT validation failure - "algorithm none" attack**

Symptom: Unauthorized users can access protected endpoints by
crafting JWTs with `"alg": "none"` and arbitrary claims.

Root cause: JWT validation library accepts the `none` algorithm
(no signature required) - all claims are trusted without
cryptographic verification.

Diagnosis:
```bash
# Check if any JWT with alg=none was accepted
grep -r '"alg".*"none"' /var/log/auth-service/
# Or check the JWT library configuration:
# io.jsonwebtoken (jjwt): must explicitly disallow none
```

Fix:
```java
// VULNERABLE: accepts any algorithm
Jwts.parser().parseClaimsJws(token);

// SAFE: explicitly specify allowed algorithms
Jwts.parserBuilder()
    .setSigningKey(publicKey)
    .requireAudience("my-service")
    // jjwt rejects none algorithm by default
    // but explicitly set allowed algorithms:
    .build()
    .parseClaimsJws(token);
// Use Spring Security oauth2ResourceServer:
// .jwt(jwt -> jwt.decoder(
//   NimbusJwtDecoder.withJwkSetUri(jwksUri)
//     .jwsAlgorithm(SignatureAlgorithm.RS256)
//     .build()))
```

---

**Failure 3: Broken tenant isolation - cross-tenant data access**

Symptom: Queries return data from multiple tenants; or a user
in Tenant A can access Tenant B's data via API.

Root cause: Database queries do not include `tenantId` filter.
The JWT contains `tenantId` claim but the service does not use
it in repository queries.

Diagnosis:
```sql
-- Find orders not owned by any single tenant
-- (indicator of cross-tenant contamination)
SELECT tenant_id, COUNT(*) FROM orders
GROUP BY tenant_id ORDER BY COUNT(*) DESC;

-- Verify a specific request: trace the JWT tenantId
-- vs the resource's tenantId
```

Fix: Add tenantId to all repository methods:
```java
// BAD:
Order findById(String orderId);

// GOOD:
Optional<Order> findByIdAndTenantId(
    String orderId, String tenantId);
// Returns empty Optional for cross-tenant ID
// → 404 response (not 403, no data leaked)
```

---

### 🎯 Interview Deep-Dive

| Category | Count |
|---|---|
| Clarification | 1 |
| Mechanism | 2 |
| Failure / Debugging | 2 |
| Trade-off | 1 |
| Production | 1 |
| Code | 1 |
| Behavioral | 1 |

---

**Q1 (Clarification) - Why is mTLS needed if the services are
already inside a VPC?**

A: A VPC is a network perimeter - it controls which IP addresses
and ports can communicate. It does NOT know which service is making
a call. Inside a VPC, once an attacker compromises one service
(through a dependency vulnerability, SSRF, or injection attack),
they have unrestricted network access to all other services.
VPC rules allow "service-a's IP range can call service-b on port 8080."
They do not authenticate that the caller is actually service-a.

mTLS adds service identity: every service has a certificate issued
by the mesh CA. A compromised service cannot call services it is
not authorized for even if it has network access - its SPIFFE ID
will not be in the target service's authorization policy.

The combination is "defense in depth": VPC for network perimeter
(prevents external connections), mTLS for service identity
(prevents lateral movement after compromise).

*What separates good from great:* framing the answer around "lateral
movement." The VPC is a boundary against external attackers. mTLS
is a boundary against internal compromised components. A security
architecture that relies only on perimeter controls is "castle and
moat" - once inside, nothing stops an attacker. mTLS implements the
"zero trust" principle: never trust, always verify, even inside.

---

**Q2 (Mechanism) - How does OPA (Open Policy Agent) make
authorization decisions?**

A: OPA is a general-purpose policy engine. It evaluates policies
written in Rego (a declarative query language) against JSON input
data.

Evaluation process:
1. The service (or Envoy sidecar) sends an HTTP POST to OPA:
   ```json
   POST /v1/data/authz/allow
   {
     "input": {
       "user": {"id": "u1", "roles": ["EDITOR"], "tenantId": "t1"},
       "resource": {"id": "r1", "tenantId": "t1", "owner": "u1"},
       "action": "write",
       "method": "POST",
       "path": "/orders"
     }
   }
   ```
2. OPA evaluates the Rego policy:
   ```
   allow if {
     "EDITOR" in input.user.roles
     input.user.tenantId == input.resource.tenantId
   }
   ```
3. OPA returns `{"result": true}` or `{"result": false}`.
4. The service allows or denies the request based on the response.

In a service mesh: Envoy's External Authorization filter can
call OPA before forwarding the request. The authorization decision
happens at the proxy layer, transparent to application code.

Policy advantages: Rego policies are version-controlled in Git,
unit-testable with `opa test`, and deployable independently of
application code (policy changes do not require service redeploys).

*What separates good from great:* discussing OPA's data coupling.
The policy references `input.resource.tenantId` - where does the
resource's tenantId come from? The service must enrich the
authorization request with resource attributes fetched from the
database BEFORE calling OPA. OPA evaluates the policy; it does
not fetch data. This means a round-trip: fetch resource → call OPA
→ authorize. The latency of this round-trip must be factored into
the service's response time budget.

---

**Q3 (Mechanism) - How does the JWT flow work end-to-end in a
microservices request?**

A: End-to-end JWT flow:

1. User authenticates with the auth server (OAuth 2.0 Authorization
   Code or Password flow). Auth server returns an access token
   (JWT signed with RS256) and a refresh token.

2. User sends a request to the API gateway:
   `GET /orders/123 Authorization: Bearer <access_token>`

3. API gateway validates the JWT:
   - Fetch the auth server's public key from JWKS endpoint
     (cached for key TTL, typically 1 hour)
   - Verify the signature: JWT.header + JWT.payload signed with RS256
   - Verify claims: `exp` (not expired), `iss` (correct issuer),
     `aud` (this service is the audience)
   - If validation fails: return 401

4. Gateway forwards to Order Service with the original JWT.
   OR: gateway creates a new internal JWT with a shorter TTL
   (15 min) signed with an internal key.

5. Order Service validates the JWT (same process as step 3,
   but using a cached public key, not calling the auth server).

6. Order Service calls Payment Service:
   - Includes the JWT in the Authorization header
   - Payment Service validates the same JWT

7. If the JWT is expired mid-request (rare but possible):
   - The service returns 401
   - The gateway receives 401 from the upstream service
   - The gateway can refresh the token using the refresh token
     (if available) and retry
   - Or return 401 to the client to re-authenticate

*What separates good from great:* step 7 (token expiry mid-request).
This is a real operational scenario that most interview answers
miss. A request spanning multiple services with a JWT near its
expiry may succeed at the gateway (token valid) but fail at a
downstream service (token just expired). Mitigation: use a short
TTL (15 min) with frequent refresh, and set the gateway's
rejection threshold to `exp - 30 seconds` to prevent issuing
requests with a JWT about to expire.

---

**Q4 (Failure / Debugging) - A service is returning 403 for
requests that should be authorized. The JWT is valid and the
user has the correct role. What do you check?**

A: Systematic 403 diagnosis (role check passes but still 403):

1. Confirm the role claim in the JWT. Decode the token:
   ```bash
   jwt_decode() { echo $1 | cut -d'.' -f2 | \
     base64 -d 2>/dev/null | python3 -m json.tool; }
   jwt_decode <token>
   # Check: does "roles" array contain the expected value?
   # Check: is the claim name "roles" or "authorities"
   # or "scope"? Many mistakes here.
   ```

2. Check the security config: is the role prefix correct?
   Spring Security adds a `ROLE_` prefix by convention.
   If the JWT contains `"EDITOR"` but `@PreAuthorize` checks
   `hasRole('EDITOR')` (which checks for `ROLE_EDITOR`): mismatch.
   Fix: use `hasAuthority('EDITOR')` instead, or configure
   the converter to add the prefix.

3. Check the audience claim. `aud` must match the service's
   configured audience. A JWT issued for `api-gateway` may
   not be valid for `order-service` if `aud = "api-gateway"`.

4. Check method security: is `@EnableMethodSecurity` annotated
   on the config class? Without it, `@PreAuthorize` annotations
   are silently ignored (no exception, just the annotation does
   nothing - the endpoint is unprotected or incorrectly protected).

5. Check if the Spring Security filter chain is applying.
   Debug log: `logging.level.org.springframework.security=DEBUG`.
   Look for `FilterSecurityInterceptor` and the authorization
   decision for the request path.

*What separates good from great:* step 2 (ROLE_ prefix). This
is one of the most common Spring Security mistakes and is
completely non-obvious. The `hasRole()` method automatically
prepends `ROLE_`. If your JWT contains plain role names without
the prefix, you must use `hasAuthority()` instead. Many developers
spend hours on this.

---

**Q5 (Failure / Debugging) - mTLS is enabled in PERMISSIVE mode.
How does this affect the security posture?**

A: PERMISSIVE mode in Istio allows both mTLS and plaintext traffic.
A pod in PERMISSIVE mode accepts connections from:
- Services with sidecars (mTLS connections)
- Services without sidecars (plaintext connections)
- Any external process that can reach the pod's IP (plaintext)

Security implications:
1. Pods without sidecars (e.g., legacy services not yet on the
   mesh) can call any PERMISSIVE pod in plaintext - bypassing
   all service identity checks.
2. Any process that can reach the pod (including a compromised
   pod in the cluster) can call it in plaintext without a
   certificate.
3. Authorization policies based on SPIFFE IDs (source principal)
   only apply to mTLS connections. Plaintext connections have
   no principal - the policy cannot match and the request may
   be allowed by default.

Diagnosis:
```bash
# Check which namespaces have STRICT mode
kubectl get peerauthentication -A -o yaml | \
  grep -A5 "mtls:"
# "PERMISSIVE" = insecure
# "STRICT" = mTLS only
```

Fix: set PeerAuthentication to STRICT after verifying all services
have sidecars injected:
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
```

*What separates good from great:* the insight that PERMISSIVE mode
with SPIFFE-based AuthorizationPolicy has a silent gap: plaintext
connections bypass the principal matching in the policy. An engineer
who only checks "is mTLS enabled?" will miss that PERMISSIVE means
"maybe mTLS" not "always mTLS." STRICT is the only mode that
guarantees all connections are authenticated.

---

**Q6 (Trade-off) - JWT-based authorization vs. OPA sidecar -
what are the trade-offs?**

A: JWT-based authorization (in-code RBAC):
- Latency: zero additional latency (JWT is already present in memory)
- Complexity: low (Spring Security annotations)
- Flexibility: low (rule changes require code deploy + test + release)
- Auditability: poor (logic scattered across services)
- Use when: rules are stable, simple RBAC, developer-controlled

OPA sidecar:
- Latency: +1-2ms per authorization call (local HTTP to OPA;
  OPA is co-located, not a remote service)
- Complexity: medium (Rego policy language, separate deployment)
- Flexibility: high (policy changes deploy independently,
  no service restart needed)
- Auditability: high (all decisions logged; policy is code-reviewed,
  tested, version-controlled)
- Use when: rules change frequently, compliance auditing required,
  non-developer policy authors (ops, legal, compliance)

The hidden trade-off: OPA decisions are based on input data.
If the authorization decision requires resource attributes
(is this user the owner of this resource?), the service must
fetch the resource BEFORE calling OPA. This adds a database
round-trip to every authorization decision. For read operations
on user-owned resources: the service ends up fetching the
resource twice (once for the authorization check, once for
the response). This can be optimized by passing the fetched
resource as part of the OPA input and eliminating the second
fetch.

*What separates good from great:* the resource-fetch trade-off.
This is a real engineering problem with OPA that is not obvious
from reading the documentation. The decision to use OPA must
account for the additional database round-trip for resource-level
authorization decisions.

---

**Q7 (Production) - How do you handle token expiry in a long-running
request that spans multiple microservices?**

A: Token expiry mid-request is a real operational challenge.
Three strategies:

Strategy 1 - Short TTL with refresh at the gateway:
- Set access token TTL to 15 minutes
- API gateway validates `exp - 30 seconds` (reject tokens within
  30s of expiry before routing)
- If a downstream service returns 401, the gateway uses the
  refresh token to get a new access token and retries once
- Downside: the gateway must maintain user session state (refresh
  token) to re-issue tokens

Strategy 2 - Internal token with extended TTL:
- API gateway validates the external token
- Issues a new internal token (signed with internal key) with
  a TTL matching the maximum request duration (e.g., 5 minutes)
- Internal token audience: internal services only (not accepted
  by external endpoints)
- Downstream services validate the internal token (local signature
  verification, no auth server call)
- Downside: internal token with 5-minute TTL can be used by a
  compromised service for up to 5 minutes

Strategy 3 - Service account token for service-to-service:
- Service-to-service calls do not carry the user token
- Services use their own service account token (mTLS certificate)
  for authentication
- User context is passed in a request header (user ID, tenantId,
  roles) signed by the gateway
- Downstream services trust the user context headers only from
  gateway (verified by mTLS certificate)

In practice: Strategy 2 (internal token with bounded TTL) is
the most practical for most systems. It eliminates the auth server
from the hot path (all validation is local) while maintaining
user context throughout the request.

*What separates good from great:* the insight that "all services
call the auth server to validate JWTs" is a bottleneck pattern.
The auth server becomes a single point of failure and a
performance bottleneck. The solution: cache the auth server's
public key (from the JWKS endpoint) locally in each service.
JWT validation is then O(1) local crypto, not a network call.
The JWKS endpoint is called only when the cached key expires
(typically every few hours).

---

**Q8 (Code) - Implement a Spring Boot filter that propagates the
Authorization header for all outbound service calls.**

A:
```java
// BAD: propagating userId in the request body
// (easy to tamper with, cannot be verified)
public OrderResponse createOrder(
        OrderRequest req, String userId) {
    // BAD: passing userId as a query param or body field
    InventoryResponse inv = restTemplate.postForObject(
        "http://inventory-service/reserve?userId=" + userId,
        req, InventoryResponse.class);
    // Inventory service cannot verify if userId was tampered
    return ...;
}

// GOOD: propagate JWT automatically via interceptor
@Component
public class JwtPropagationInterceptor
        implements ClientHttpRequestInterceptor {

    @Override
    public ClientHttpResponse intercept(
            HttpRequest request,
            byte[] body,
            ClientHttpRequestExecution execution)
            throws IOException {

        // Get current security context
        Authentication auth = SecurityContextHolder
            .getContext().getAuthentication();

        if (auth instanceof JwtAuthenticationToken jwtAuth) {
            String tokenValue = jwtAuth.getToken()
                .getTokenValue();
            // Add to outbound request
            request.getHeaders().setBearerAuth(tokenValue);
        }

        return execution.execute(request, body);
    }
}

// Register interceptor on RestTemplate bean:
@Bean
public RestTemplate restTemplate() {
    RestTemplate template = new RestTemplate();
    template.setInterceptors(List.of(
        new JwtPropagationInterceptor()));
    return template;
}
// Now ALL calls via this RestTemplate automatically
// carry the current user's JWT.
```

> **Code walkthrough:** The BAD pattern passes the userId as
> a query parameter - any caller can forge this value because
> it is not cryptographically signed. The GOOD pattern uses a
> `ClientHttpRequestInterceptor` that automatically extracts the
> JWT from the Spring Security context and adds it to every outbound
> request. Application code does not need to handle token propagation
> explicitly - calling `restTemplate.getForObject(...)` automatically
> includes the JWT. The JWT is signed by the auth server, so downstream
> services can verify it cryptographically - the userId claim cannot
> be tampered with.

---

**Q9 (Behavioral) - Describe how you would migrate a monolith with
session-based authentication to a microservices architecture with
JWT-based authorization.**

A: Migration in phases:

Phase 1 - Parallel auth (strangler fig):
"Add JWT support to the monolith while keeping session-based auth
working. The API gateway handles new requests via JWT. Legacy
routes continue via session. This allows new microservices to
use JWT from day one while the monolith is progressively extracted."

Phase 2 - Identity extraction:
"Extract the auth system first (before any domain services).
Deploy an identity provider (Keycloak, Auth0) that:
(1) Issues JWTs for new clients.
(2) Validates existing session cookies and issues JWTs (bridge).
New microservices authenticate against the IdP directly."

Phase 3 - Service-by-service migration:
"For each extracted service: receive JWT, validate signature using
the IdP's JWKS endpoint. Add @PreAuthorize annotations with the
same role mapping as the monolith's session-based auth checks.
Run both paths in production (A/B) until the microservice path
is validated."

Phase 4 - Deprecate session auth:
"Once all services use JWT: deprecate the monolith's session auth.
Remove the bridge. Issue only JWTs for all clients."

Lessons learned: "The hardest part was token scope. The monolith
had fine-grained permissions stored in the database (per-user,
per-resource). Encoding all permissions in a JWT would make it
too large. Solution: put coarse roles in JWT (ADMIN, EDITOR, VIEWER)
and resource-level checks in the data layer (tenantId, ownerId
from JWT compared to database resource attributes). This kept
JWTs small (<500 bytes) while maintaining fine-grained access control."

*What separates good from great:* the JWT size insight. JWTs with
50+ permissions become problematic (large headers, performance,
caching issues). The pattern of "coarse roles in JWT + fine-grained
at data layer" is the production-grade solution. Encoding all
permissions in the JWT is an anti-pattern at scale.
