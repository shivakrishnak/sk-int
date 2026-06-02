---
layout: default
title: "Security - L6 Theory"
parent: "Security"
nav_order: 15
permalink: /security/l6-theory/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Cryptographic Protocol Design Principles](#cryptographic-protocol-design-principles) | ★★☆ |
| 2 | [Formal Security Proofs and Threat Models](#formal-security-proofs-and-threat-models) | ★★☆ |

---

# Cryptographic Protocol Design Principles

---

### 🎯 Model Answer

**30 seconds:**
> Cryptographic protocol design principles are the rules that prevent subtle security
> flaws in protocols that use mathematically sound cryptographic primitives. The key
> principles: authenticate before encrypting (MAC-then-encrypt is broken; use
> Encrypt-then-MAC or AEAD), use nonces/IVs correctly (never reuse a nonce with the
> same key), include context binding to prevent cross-protocol attacks, and use
> established protocols (TLS 1.3, Signal) rather than inventing your own.

**3 minutes (Senior):**
> Most cryptographic protocol failures are not attacks on the underlying math - they
> are attacks on how the protocol uses the math. Padding oracle attacks exploit CBC
> mode with flawed MAC verification ordering. Nonce reuse in AES-GCM leaks the
> authentication key after seeing two ciphertexts under the same nonce. Length extension
> attacks apply to MD5/SHA-1/SHA-256 MACs but not to HMAC or SHA-3. The three most
> important principles: (1) Use Authenticated Encryption with Associated Data (AEAD)
> modes (AES-GCM, ChaCha20-Poly1305) - they bundle confidentiality, integrity, and
> authenticity in one primitive; (2) Never roll your own crypto - use well-vetted
> libraries (libsodium, BouncyCastle, Java Cryptography Architecture); (3) Key
> separation - use different keys for different purposes; never use the same key for
> encryption and MAC, or for different protocol versions.

**Framework:** Primitive Selection -> Protocol Composition -> Implementation -> Key Management

**Blank Mind Recovery:**

**(1) Restate:** "Crypto protocols fail not because the math is broken, but because
of implementation flaws: wrong mode, wrong ordering, nonce reuse, or oracle attacks.
AEAD modes (AES-GCM) prevent most of these by bundling confidentiality and integrity."

**(2) First principles:** "A cipher encrypts. A MAC authenticates. An AEAD mode does
both together, preventing the composition errors (MAC-then-encrypt) that cause
padding oracle attacks."

**(3) Bridge:** "Crypto protocol design is like building with LEGO. Each piece is
strong. The failure comes from connecting pieces in the wrong order or using the same
connector twice. AEAD modes give you a complete sub-assembly that removes the assembly
error."

---

### 📘 Concept Explanation

**Why Protocol Design Matters Beyond Primitive Selection:**

A cryptographic primitive (AES, SHA-256, RSA) is mathematically sound. A protocol
that uses it incorrectly can be broken completely. Three classic failures:

```text
CLASSIC PROTOCOL DESIGN FAILURES:

  1. PADDING ORACLE (CBC mode + MAC-then-Encrypt):
     - Protocol: encrypt plaintext, then MAC ciphertext
     - Attacker: modifies ciphertext and observes
       padding error vs MAC error timing
     - Result: decrypts any ciphertext without key
     - Fix: Encrypt-then-MAC OR use AEAD

  2. NONCE REUSE (AES-GCM, ChaCha20-Poly1305):
     - Protocol: reuses nonce N with same key K
     - Attack: attacker XORs two ciphertexts to get
       P1 XOR P2 (XOR of plaintexts)
     - For AES-GCM: nonce reuse leaks auth key H
       (catastrophic: forgery becomes possible)
     - Fix: use random 96-bit nonce; use counter;
       use key+nonce ratchet (Signal protocol)

  3. LENGTH EXTENSION (Hash-based MAC):
     - Protocol: MAC = H(key || message)
     - Attack: given H(key || message), attacker
       computes H(key || message || extra)
       without knowing the key
     - Affects: MD5, SHA-1, SHA-256
     - Does NOT affect: HMAC, SHA-3 (Keccak)
     - Fix: always use HMAC(key, message)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: three classic protocol design failures that
> occur even when the underlying cryptographic primitive is sound. (2) KEY MECHANISM:
> for the padding oracle attack, the flaw is that error message differentiation (padding
> error vs MAC error) creates an oracle; by submitting modified ciphertexts and observing
> which error occurs, an attacker can decrypt arbitrary ciphertext through repeated
> queries; this is completely independent of key length. (3) WHY IT MATTERS: POODLE
> (2014) and BEAST (2011) both exploited CBC padding oracle vulnerabilities in SSL/TLS;
> both were practical attacks against real production traffic. (4) WHAT BREAKS: using
> CBC mode with a "verify first, decrypt second" approach does not prevent padding
> oracles if the verification and decryption error paths are distinguishable; timing
> differences of microseconds are sufficient for a remote timing attack. (5) TAKEAWAY:
> AEAD modes (AES-GCM, ChaCha20-Poly1305) solve all three problems in one primitive;
> use them exclusively for symmetric encryption.

**Core Protocol Design Principles:**

```text
PRINCIPLE 1 - USE AEAD MODES:
  AES-GCM: combines AES-CTR + GHASH MAC
    - Provides: confidentiality + integrity
      + authenticity in one operation
    - Key: 128 or 256-bit
    - Nonce: 96-bit (must be unique per key)
    - Auth tag: 128-bit (96+ for some uses)
    - WARNING: nonce reuse is catastrophic

  ChaCha20-Poly1305:
    - Same guarantees as AES-GCM
    - Better performance on platforms without
      AES-NI hardware acceleration
    - Used in TLS 1.3, WireGuard, Signal

PRINCIPLE 2 - KEY SEPARATION:
  - Use distinct keys for distinct purposes
  - Never reuse an encryption key as a MAC key
  - Never reuse keys across protocol versions
  - Derive keys with HKDF for each purpose:
    enc_key = HKDF(master, "encryption v1")
    mac_key = HKDF(master, "mac v1")

PRINCIPLE 3 - INCLUDE CONTEXT BINDING:
  - Bind ciphertext to its context (sender,
    receiver, session, version)
  - Use Associated Data in AEAD for this
  - Prevents: cross-protocol attacks, replay
    attacks with reused ciphertexts

PRINCIPLE 4 - NONCE MANAGEMENT:
  - Preferred: random 96-bit nonce (collision
    probability 1/2^32 after 2^32 messages)
  - For high-volume: counter-based nonce
    with synchronized state
  - For stateless: use key derivation with
    random salt per message (AEAD with KDF)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the four core principles for sound
> cryptographic protocol design, focusing on AEAD modes, key separation, context
> binding, and nonce management. (2) KEY MECHANISM: HKDF (HMAC-based Key Derivation
> Function) is the standard way to derive multiple purpose-specific keys from a single
> master key; it takes the master key, a salt, and an "info" string (context) and
> produces a derived key that is cryptographically independent of keys derived with
> different info strings. (3) WHY IT MATTERS: TLS 1.3 strictly applies key separation
> by deriving distinct keys for each direction, handshake phase, and operation from
> a single master secret; this prevents cross-directional and cross-phase attacks. (4)
> WHAT BREAKS: context binding is the most commonly omitted principle; without it, a
> ciphertext encrypted for "server A" can be replayed as if encrypted for "server B"
> in a cross-protocol attack; always include sender ID, receiver ID, and session
> context in AEAD's associated data. (5) TAKEAWAY: TLS 1.3 is the canonical
> implementation of all four principles; if implementing a custom protocol, study
> TLS 1.3's key schedule and learn from it rather than inventing from scratch.

---

### 💻 Code Example

```python
# Cryptographic protocol design: AEAD vs BAD patterns

# BAD: manual CBC + MAC (ordering error - mac-then-encrypt)
from Crypto.Cipher import AES
from Crypto.Hash import HMAC, SHA256
import os

def encrypt_bad(key: bytes, plaintext: bytes) -> bytes:
    # Step 1: MAC the plaintext
    mac = HMAC.new(key, plaintext, SHA256).digest()
    # Step 2: Encrypt plaintext+mac together
    # WRONG: MAC-then-Encrypt is vulnerable to
    # padding oracle attacks in CBC mode
    cipher = AES.new(key[:16], AES.MODE_CBC)
    iv = cipher.iv
    ct = cipher.encrypt(pad(plaintext + mac))
    return iv + ct
```

> **Code walkthrough:** (1) WHAT IT SHOWS: MAC-then-Encrypt in CBC mode - the
> anti-pattern that led to the POODLE and BEAST attacks; the MAC is computed over
> plaintext, then both plaintext and MAC are encrypted together. (2) KEY MECHANISM:
> the vulnerability is that CBC decryption can fail with a padding error before the MAC
> is verified; by observing whether a padding error or MAC error occurs, an attacker
> can determine the last byte of the plaintext and iterate; BEAST used this to decrypt
> HTTPS session cookies in under an hour. (3) WHY IT MATTERS: this pattern was used in
> SSLv3 and early TLS; it is the reason those protocols are now forbidden; any library
> implementing this pattern today is dangerously wrong. (4) WHAT BREAKS: even
> Encrypt-then-MAC (encrypt first, then MAC the ciphertext) is only safe if implemented
> correctly; AEAD modes are always preferred because they are a proven, tested
> implementation of Encrypt-then-MAC. (5) TAKEAWAY: never implement symmetric
> encryption manually in production code; always use an AEAD cipher mode from a
> well-vetted cryptographic library.

```python
# GOOD: AEAD with AES-GCM
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os

def encrypt_good(key: bytes,
                 plaintext: bytes,
                 associated_data: bytes) -> bytes:
    """Authenticated encryption with context binding.

    associated_data binds ciphertext to its context
    (sender, receiver, session, version) without
    including it in the ciphertext.
    """
    aesgcm = AESGCM(key)
    # Random nonce: safe for up to ~2^32 messages
    # with the same key (birthday bound)
    nonce = os.urandom(12)  # 96-bit
    # AEAD: confidentiality + integrity + authenticity
    # associated_data is authenticated but not encrypted
    ciphertext = aesgcm.encrypt(
        nonce, plaintext, associated_data
    )
    return nonce + ciphertext  # nonce prepended

def decrypt_good(key: bytes,
                 nonce_and_ct: bytes,
                 associated_data: bytes) -> bytes:
    """Decrypt and verify. Raises InvalidTag on
    any tampering with ciphertext or associated_data.
    """
    nonce, ciphertext = (
        nonce_and_ct[:12],
        nonce_and_ct[12:]
    )
    aesgcm = AESGCM(key)
    # InvalidTag exception if authentication fails
    return aesgcm.decrypt(nonce, ciphertext,
                          associated_data)

# Usage: bind ciphertext to session context
session_context = b"sender:alice|receiver:bob|v1"
ct = encrypt_good(key, plaintext, session_context)
pt = decrypt_good(key, ct, session_context)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: AES-GCM authenticated encryption with
> associated data for context binding; the `associated_data` parameter (sender, receiver,
> session, version) is authenticated but not encrypted, binding the ciphertext to its
> intended context. (2) KEY MECHANISM: the GCM authentication tag covers both the
> ciphertext and the associated data; if either is tampered with, decryption raises
> `InvalidTag`; this prevents replay attacks where a valid ciphertext from one session
> is replayed in a different session context. (3) WHY IT MATTERS: TLS 1.3 uses context
> binding to prevent cross-session attacks; every AEAD encryption in TLS 1.3 includes
> the record type, protocol version, and record length as associated data. (4) WHAT
> BREAKS: using `os.urandom(12)` for nonces has a ~1/2^32 collision probability after
> 2^32 messages with the same key; for high-volume systems (>4B messages/key), use a
> counter-based nonce or rotate keys more frequently. (5) TAKEAWAY: always use the
> `associated_data` parameter in AEAD operations; it is free (no performance cost) and
> prevents an entire class of cross-protocol attacks that occur when the same key is
> reused in multiple contexts.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Cryptographic protocols fail not because the math is broken, but because of how the
> primitives are combined. Key failures: MAC-then-Encrypt in CBC mode is vulnerable to
> padding oracle attacks; nonce reuse in AES-GCM is catastrophic; using H(key || message)
> as a MAC is vulnerable to length extension. The fix for all three: use AEAD modes
> (AES-GCM, ChaCha20-Poly1305) from an established library. Never implement symmetric
> encryption manually.

---

**Senior / Staff (5+ years):**
> Protocol design principles define the composition rules for cryptographic primitives.
> The key insight: mathematical security of individual primitives does not compose
> automatically; composition requires explicit proof. TLS 1.3 is the canonical modern
> design: mandatory AEAD (no CBC mode), perfect forward secrecy by default (ephemeral
> ECDH keys), strict key separation with HKDF key schedule, explicit session binding
> with context data in AEAD operations. For custom protocols: use the Signal Protocol
> for end-to-end encrypted messaging (Double Ratchet algorithm provides forward secrecy
> + break-in recovery); use Noise Framework for handshake-based protocols; use standard
> JOSE (JSON Web Encryption) for token-based systems. Never design a custom protocol
> for production use without formal analysis.

---

### ⚠️ Common Misconceptions

**Misconception 1: "AES is secure so AES-CBC is secure."**

AES the block cipher is secure. AES-CBC the mode of operation has fundamental
vulnerabilities when combined with improper padding and MAC ordering. The cipher
primitive (AES) being secure does not make every mode of operation that uses it
secure. AES-GCM and ChaCha20-Poly1305 are the modes that provide authenticated
encryption with proven security composition.

**Misconception 2: "HTTPS means the protocol is cryptographically safe."**

HTTPS means the transport is encrypted with TLS. The application protocol on top of
TLS can still have cryptographic flaws: broken JWT signing (alg:none vulnerability),
weak password hashing (MD5, unsalted SHA), insecure key storage, or hard-coded keys.
TLS protects data in transit; it says nothing about the application's cryptographic
implementation.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Nonce reuse in AES-GCM.**

Symptom: two ciphertexts encrypted with the same key and same nonce are observed
by an attacker; XOR of ciphertexts gives XOR of plaintexts; worse, the GCM
authentication key H can be recovered.
Root cause: counter-based nonce not synchronized across processes; random nonce
collision (with 12-byte nonces, probability approaches 1% after ~4 billion messages
per key).
Fix: use unique nonces per key; if running distributed, use a key per node (HKDF-derived),
not a shared key; rotate encryption keys before birthday bound is reached.

**Failure Mode 2: Length extension attack on home-built MAC.**

Symptom: attacker submits a forged MAC for an extended message without knowing the key.
Root cause: MAC = SHA-256(key || message) allows extension; the SHA-256 internal state
after processing the message becomes the starting point for hashing the extension.
Fix: replace SHA-256(key || message) with HMAC-SHA256(key, message); HMAC applies the
key twice (inner and outer hash) which prevents extension attacks.

---

### ⚖️ Comparison Table

| Mode | Confidentiality | Integrity | Auth | Nonce Reuse Risk |
|---|---|---|---|---|
| **AES-GCM** | Yes | Yes (GHASH) | Yes | Catastrophic |
| **ChaCha20-Poly1305** | Yes | Yes (Poly1305) | Yes | High |
| **AES-CBC + HMAC** | Yes | Yes (HMAC) | No (separate) | Low |
| **AES-CBC + no MAC** | Yes | No | No | High (padding oracle) |
| **AES-ECB** | Weak (patterns leak) | No | No | N/A |

---

### 🏛️ System Design

*(Omit: L6 Theory keyword; system design applies to broader protocol-level
decisions covered in the L4/L5 entries on OAuth Internals and Zero Trust.)*

---

### 📊 Diagram

```text
TLS 1.3 KEY SCHEDULE (simplified):

  PSK / DHE output
         |
         v
  [Extract] ---> Early Secret
         |
  [Derive] ----> client_early_traffic_secret
         |
  [Extract] ---> Handshake Secret
         |
  +------+------+
  |             |
  v             v
client_hs    server_hs
_traffic     _traffic
_secret      _secret
         |
  [Extract] ---> Master Secret
         |
  +------+------+------+
  |             |      |
  v             v      v
client_ap  server_ap  exporter
_traffic   _traffic   _secret
_secret    _secret
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the TLS 1.3 key schedule showing how
> a single Diffie-Hellman exchange output (or PSK) is expanded into multiple
> purpose-specific keys using HKDF. (2) HOW TO READ IT: the vertical flow is the HKDF
> extract-and-expand chain; each Extract takes inputs and creates an intermediate secret;
> each Derive produces a purpose-specific key; client and server traffic keys are derived
> separately. (3) KEY RELATIONSHIP: key separation is enforced by the key schedule;
> the client traffic secret and server traffic secret are cryptographically independent
> even though they derive from the same master secret; this prevents cross-directional
> attacks. (4) EDGE CASE: if a derived secret is compromised (e.g., server_ap_traffic),
> the other secrets remain secure; this is the principle of key separation protecting
> the system even under partial compromise. (5) INSIGHT: a senior engineer notes that
> TLS 1.3 used 7 years of formal cryptographic analysis (including mechanized proofs
> in ProVerif and TLS-Attacker fuzzing) before standardization; this is the result of
> applying rigorous protocol design principles at scale.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | AEAD modes, nonce management |
| Mechanism | 2 | Padding oracle, length extension |
| Application | 2 | Key derivation, context binding |
| Scenario | 2 | Nonce reuse diagnosis, custom protocol review |
| Trade-off | 1 | Algorithm selection |

---

**[MID] Q1 (Definition): What is an AEAD cipher mode and why should it be used for symmetric encryption?**

AEAD stands for Authenticated Encryption with Associated Data. It is a symmetric
encryption mode that provides three security properties simultaneously: confidentiality
(ciphertext reveals nothing about plaintext), integrity (tampering with ciphertext is
detected), and authenticity (the ciphertext came from someone with the correct key).

The two most common AEAD ciphers:
- AES-GCM: AES in Counter mode + GHASH authentication tag (128-bit). Widely hardware-
  accelerated (AES-NI on x86; ARM Crypto Extension on ARM). Used in TLS 1.3, IPsec.
  Weakness: nonce reuse is catastrophic.
- ChaCha20-Poly1305: ChaCha20 stream cipher + Poly1305 MAC. Software-friendly; better
  performance on devices without AES hardware acceleration. Used in TLS 1.3 (as a
  fallback), WireGuard, Signal.

Why use AEAD instead of cipher + separate MAC:
Manual composition errors: CBC+HMAC where the MAC is applied before encryption (MAC-
then-Encrypt) is vulnerable to padding oracle attacks; applying them in the right order
requires expertise. AEAD modes implement the correct composition (Encrypt-then-MAC
essentially) in a single, tested, battle-hardened operation.

Associated data: the associated data parameter allows the ciphertext to be bound to
its context (sender, receiver, session) without including that data in the ciphertext.
This prevents replay attacks where a valid ciphertext is used in a different context.

*What separates good from great:* Understanding that "authenticated" in AEAD means
the ciphertext is authenticated, not the parties. AES-GCM authentication proves that
the ciphertext was not tampered with and was produced by someone with the key; it does
not prove which specific party produced it. For protocol-level authentication (proving
identity), you still need asymmetric signatures or a PKI. AEAD provides integrity and
message authentication only.

---

**[MID] Q2 (Mechanism): How does a padding oracle attack work?**

A padding oracle attack exploits the difference in error messages between a padding
error and a MAC verification error in CBC mode encrypted messages.

How CBC decryption works: CBC decryption XORs each decrypted block with the previous
ciphertext block to produce plaintext. The last block must contain valid PKCS#7 padding
(1 byte of 0x01, 2 bytes of 0x0202, etc.) or the decryption fails.

The attack:
1. Attacker intercepts a ciphertext block.
2. Attacker modifies the last byte of the previous ciphertext block and submits it.
3. Server either: (a) returns a padding error (the modified byte produced invalid padding)
   or (b) returns a MAC error (the padding was valid but the MAC failed).
4. By observing which error occurs, the attacker determines whether the last byte of
   the decrypted block XOR'd with the modified byte equals 0x01 (valid padding).
5. Iterating over all 256 values, the attacker finds the correct byte and computes the
   plaintext last byte. Repeat for all bytes.

This requires ~128 oracle queries per byte, so ~4,096 queries to decrypt a 32-byte
block. Against a real HTTPS server with a 256-byte response body, decryption requires
about 65,536 requests - feasible in minutes over a fast network.

*What separates good from great:* The timing side channel variant. Even if the server
returns the same error message for padding errors and MAC errors, the different code
paths take different amounts of time. Remote timing oracles with microsecond precision
have been demonstrated against TLS implementations over LAN. The only complete fix is
AEAD modes, where the authentication tag verification is always performed in constant
time regardless of ciphertext content.

---

**[SENIOR] Q3 (Mechanism): What happens when a nonce is reused in AES-GCM?**

AES-GCM uses AES-CTR for encryption. AES-CTR produces a keystream by encrypting a
counter with the key. The keystream is XOR'd with the plaintext to produce ciphertext.

If two messages are encrypted with the same key and same nonce:

```text
C1 = P1 XOR Keystream(K, N)
C2 = P2 XOR Keystream(K, N)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the XOR relationship that emerges when two
> plaintexts are encrypted with the same keystream. (2) KEY MECHANISM: AES-CTR mode
> produces a keystream by encrypting a counter; if the same nonce N is used with key K,
> the keystream is identical for both messages; XOR-ing the ciphertexts cancels the
> keystream, revealing P1 XOR P2. (3) WHY IT MATTERS: if one plaintext is known or
> partially guessable (HTTP headers are predictable), the other plaintext is immediately
> recoverable. (4) WHAT BREAKS: for AES-GCM, nonce reuse additionally leaks the
> authentication key H, enabling forged authentication tags. (5) TAKEAWAY: nonce reuse
> in any CTR-based cipher is catastrophic; use random 96-bit nonces or per-instance
> derived keys to prevent collision.

Since both use the same keystream: `C1 XOR C2 = P1 XOR P2`.
If one plaintext is known (or predictable), the other is immediately recoverable.
For plaintext that is partially known (HTTP headers), large portions of the unknown
plaintext can be recovered.

GCM authentication key recovery: in AES-GCM, the authentication key H = AES(K, 0).
H is used to compute the Poly1305 MAC over the ciphertext. If two messages are
encrypted under the same nonce, an attacker can solve for H algebraically from the
two authentication tags and the two ciphertexts. With H known, the attacker can forge
authentication tags for any ciphertext - breaking the entire authentication guarantee.

*What separates good from great:* The practical attack scenario. Nonce reuse in
AES-GCM occurred in real systems due to improper counter synchronization in distributed
systems. When the same key is shared across multiple server instances without
synchronized nonce state, two servers can independently generate the same nonce. Fix:
derive per-instance keys using HKDF (different node ID as context), or use a
SIV (Synthetic IV) mode like AES-GCM-SIV which is nonce-misuse-resistant.

---

**[SENIOR] Q4 (Application): How does HKDF work and when do you need it?**

HKDF (HMAC-based Key Derivation Function, RFC 5869) derives multiple
cryptographically independent keys from a single master key.

Two-phase operation:
- Extract: HKDF-Extract(salt, IKM) = PRK (pseudorandom key). Takes the Input Keying
  Material (IKM, e.g., a DH shared secret) and a salt; produces a uniformly distributed
  pseudorandom key. This phase is used when the input is not uniformly random (DH output
  is not uniform).
- Expand: HKDF-Expand(PRK, info, length) = OKM (output keying material). Takes the PRK
  and an application-specific context string (info); produces a key of the desired length.
  Different info strings produce independent keys.

When to use HKDF:
1. Key separation: deriving distinct keys for encryption, MAC, and IV generation
   from a single shared secret.
2. Key stretching after key exchange: DH shared secrets are not uniformly random;
   HKDF-Extract processes them into a uniformly distributed key.
3. Ratchet mechanisms: the Signal Double Ratchet uses HKDF to derive message keys
   from chain keys; each message advances the ratchet, providing forward secrecy.

*What separates good from great:* The `info` parameter design. HKDF's info parameter
provides domain separation; keys derived with different info strings are independent
even if they share the same PRK. A robust info string includes: application name,
protocol version, and purpose; e.g., "myapp|v1|client_write_key". This prevents a
key derived for one purpose from being reused for another, even accidentally.

---

**[SENIOR] Q5 (Scenario): You are reviewing a custom cryptographic protocol. What do you check first?**

Custom cryptographic protocol review checklist (in priority order):

1. Nonce/IV management: how are nonces generated? Are they random or counter-based?
   Is counter state persistent across restarts? Can nonces be reused under any
   circumstance? This is the single most common catastrophic flaw.

2. Authentication mode: is CBC with manual MAC used? What is the MAC ordering (MAC-
   then-Encrypt vs Encrypt-then-MAC)? Are AEAD modes used? If not, why not?

3. Key usage: is the same key used for both encryption and MAC? Are keys reused across
   protocol versions or different purposes? Is HKDF used for key derivation?

4. Context binding: does authenticated encryption include session/sender/receiver context
   in associated data? Can ciphertexts be replayed from one session to another?

5. Handshake/authentication: how are parties authenticated? Is there a PKI? Are
   certificates validated? Can a man-in-the-middle intercept the key exchange?

6. Formal analysis: has the protocol been analyzed with formal tools (ProVerif, Tamarin)?
   Has it been published and peer-reviewed?

*What separates good from great:* The "could Schneier break this?" test. Applied
cryptographer Bruce Schneier's maxim: "Anyone, from the most clueless amateur to the
best cryptographer, can create an algorithm that he himself can't break." A custom
protocol is only as secure as the rigor of its analysis. Before deploying a custom
protocol in production, require: published threat model, formal analysis with ProVerif
or Tamarin, public review period, and independent cryptographic audit. If the business
timeline does not allow this, use an established protocol instead.

---

**[SENIOR] Q6 (Trade-off): When would you choose ChaCha20-Poly1305 over AES-GCM?**

Both ChaCha20-Poly1305 and AES-GCM are IETF-standard AEAD ciphers used in TLS 1.3.
The choice depends on the hardware and threat model.

Choose AES-GCM when:
- Target hardware has AES-NI acceleration (most x86 servers, modern ARM with Crypto
  Extension): AES-GCM is 3-10x faster than ChaCha20-Poly1305 with hardware acceleration.
- Regulatory compliance: some regulations (FIPS 140-2, Common Criteria) require
  NIST-approved algorithms; AES is NIST-approved; ChaCha20 is not yet FIPS-approved
  (FIPS 140-3 draft includes it but it is not widely enforced yet).

Choose ChaCha20-Poly1305 when:
- Target hardware lacks AES hardware acceleration (older ARM, IoT, mobile): software
  AES is up to 3x slower than ChaCha20-Poly1305 and vulnerable to cache-timing attacks.
- Nonce-misuse concern: both are equally catastrophic under nonce reuse, but ChaCha20-
  Poly1305's software implementation is less likely to contain timing-based side channels.
- TLS on mobile clients: Google Chrome uses ChaCha20-Poly1305 as the preferred cipher
  for mobile clients and AES-GCM for servers; this is the correct deployment pattern.

*What separates good from great:* The timing attack concern with software AES. Software
AES implementations (table-based S-box lookup) are vulnerable to cache-timing attacks
on systems where the attacker can measure cache behavior. On systems without AES-NI,
a timing side-channel attacker with local access could potentially recover AES keys
from a software implementation. ChaCha20 is designed to be constant-time in software,
making it the safer choice for platforms without hardware AES acceleration.

---

**[SENIOR] Q7 (Scenario): A developer proposes using SHA-256(secret_key + request_body) as a request authentication MAC. What is the vulnerability?**

The proposed MAC construction `SHA-256(secret_key + request_body)` is vulnerable to
a length extension attack because SHA-256 uses the Merkle-Damgard construction.

How the Merkle-Damgard construction works:
SHA-256 processes the message in 512-bit blocks. The final hash is the internal state
after processing all blocks. If you know `SHA-256(key + message)`, you know the internal
state of SHA-256 after processing `key + message`. You can then continue hashing from
that state, effectively computing `SHA-256(key + message + padding + extension)` without
knowing the key.

Attack scenario:
- Attacker observes: `SHA-256(key + "action=read&user=alice")` in a request.
- Attacker computes: `SHA-256(key + "action=read&user=alice" + [padding] + "&user=admin")`
  without knowing the key.
- Attacker submits the extended request with the forged MAC.
- Server verifies the MAC and accepts the forged request.

This affects SHA-256, SHA-1, and MD5. It does NOT affect: HMAC-SHA256 (HMAC applies
the key twice, breaking the extension property), SHA-3 (Keccak uses a sponge
construction, not Merkle-Damgard), BLAKE2/BLAKE3.

Fix: replace `SHA-256(key + message)` with `HMAC-SHA256(key, message)`.

*What separates good from great:* Real-world impact. Flickr's API in 2009 used an
insecure MAC construction vulnerable to length extension; Flickr had to revoke and
reissue API keys. AWS Signature v2 (deprecated) used a similar insecure construction;
AWS Signature v4 uses HMAC-SHA256. Any API that uses a hash-based MAC without HMAC
should be considered vulnerable and migrated immediately.

---

**[SENIOR] Q8 (Application): How does the Signal Protocol achieve forward secrecy and break-in recovery?**

The Signal Protocol uses the Double Ratchet algorithm to provide both forward secrecy
(compromising a key does not expose past messages) and break-in recovery (compromising
a key does not expose future messages indefinitely).

Two ratchets working together:

Diffie-Hellman Ratchet (Asymmetric Ratchet):
- Each message includes a new ephemeral public key.
- When the receiver responds, they generate a new DH share using the sender's ephemeral
  key; this produces a new root key.
- The DH ratchet advances with each round trip, providing break-in recovery: after
  a new DH exchange, an attacker who had the previous session key cannot derive the
  new session key.

Symmetric Ratchet (Chain Key Ratchet):
- A chain key is advanced for each message using a KDF (HKDF step).
- Each message key is derived from the chain key and then the chain key is advanced.
- The chain key provides forward secrecy within a session: once a message key is used
  and deleted, it cannot be rederived from the current chain key.

Combined: the DH ratchet provides break-in recovery (future secrecy) while the
symmetric ratchet provides forward secrecy (past secrecy). Together they achieve
both properties, unlike TLS 1.3 which provides forward secrecy but not break-in
recovery within a session.

*What separates good from great:* The X3DH initial key agreement (Extended Triple
Diffie-Hellman). Before the Double Ratchet can start, Signal uses X3DH to establish
the initial shared secret. X3DH uses four DH computations with identity keys, signed
prekeys, and one-time prekeys. This provides strong authentication (sender and receiver
identity keys are used) and deniability (neither party can cryptographically prove to
a third party who authored a message). The combination of X3DH + Double Ratchet is
the state of the art for secure messaging protocol design.

---

**[SENIOR] Q9 (Mechanism): What is a side-channel attack and how does it differ from a direct cryptographic attack?**

A direct cryptographic attack exploits mathematical weaknesses in a cryptographic
primitive or protocol (e.g., birthday collision in MD5, discrete logarithm weakness).
A side-channel attack exploits information leaked through the physical or computational
implementation rather than the algorithm itself.

Common side-channel types:

Timing: the time taken to complete a cryptographic operation varies with the key or
plaintext. Non-constant-time comparisons (strcmp-style) leak the number of matching
bytes before a mismatch; variable-time modular exponentiation in RSA leaks key bits.

Cache: on shared hardware (cloud VMs), CPU cache state can be observed by a co-resident
attacker. Table-based AES lookups access memory based on key-dependent indices; cache
timing reveals which indices were accessed, leaking key bytes (PRIME+PROBE, FLUSH+RELOAD
attacks).

Power/EM: physical devices (smartcards, HSMs) emit power consumption and electromagnetic
radiation that correlates with cryptographic operations; differential power analysis (DPA)
can recover keys from thousands of power traces.

Mitigation:
- Use constant-time implementations: no branches on secret data; no secret-dependent
  memory accesses.
- Use hardware with AES-NI (constant-time by design for AES operations).
- Use HMAC with constant-time comparison for MAC verification.
- Use hardware security modules (HSMs) with physical side-channel protection for key
  storage.

*What separates good from great:* The Hertzbleed timing attack (2022). Intel CPUs
dynamically adjust clock frequency based on power consumption; on some processors,
the clock frequency varied with the SIMD instruction operands, creating a timing side
channel even in code intended to be constant-time. This demonstrated that side-channel
analysis must account for microarchitectural behavior, not just algorithmic complexity.
The recommended mitigation: use hardware-accelerated AES (AES-NI) which is implemented
to be constant-time at the hardware level.

---

---

# Formal Security Proofs and Threat Models

---

### 🎯 Model Answer

**30 seconds:**
> Formal security proofs provide mathematical guarantees that a cryptographic scheme
> is secure assuming certain mathematical hardness assumptions hold (e.g., discrete
> log, RSA, random oracle). A threat model formally defines the adversary's capabilities,
> goals, and the assumptions under which security is claimed. Without a formal threat
> model, "security" is undefined; a system can be "secure against casual attackers but
> insecure against nation-state adversaries" - these are different threat models with
> different defenses.

**3 minutes (Senior):**
> The security reduction: a scheme S is proven secure by showing that breaking S is
> computationally equivalent to solving a hard problem H. If you can break S (in
> polynomial time), then you can solve H (in polynomial time). Since H is assumed hard,
> S must also be hard to break. This is the foundation of provably secure cryptography.
> Game-based security definitions formalize what "secure" means: IND-CPA (indistinguishable
> under chosen-plaintext attack) means an adversary cannot distinguish encryptions of
> two chosen plaintexts; IND-CCA2 (indistinguishable under adaptive chosen-ciphertext
> attack) additionally allows the adversary to query a decryption oracle. A system
> secure under IND-CCA2 is secure against padding oracles and related attacks. For
> threat modeling: STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure,
> Denial of Service, Elevation of Privilege) provides a structured adversary capability
> taxonomy; PASTA (Process for Attack Simulation and Threat Analysis) provides a
> risk-aligned threat modeling process for product teams.

**Framework:** Adversary Model -> Security Definition -> Hardness Assumption -> Proof

**Blank Mind Recovery:**

**(1) Restate:** "A security proof says: breaking this scheme is as hard as solving
this math problem. A threat model says: these are the adversary's capabilities and
goals, and our system is secure against them under these assumptions."

**(2) First principles:** "Security is relative to an adversary. Without defining
the adversary, 'secure' is meaningless. Formal proofs make the adversary model
explicit and provide quantitative guarantees."

**(3) Bridge:** "A threat model is like a chess game where you specify your opponent's
strength. A formal proof says: your opponent cannot win this game unless they can
solve a problem that is currently considered unsolvable (like P vs NP). But if the
opponent is secretly a grandmaster (nation-state adversary), your proof still holds -
the hardness assumptions account for the opponent's computational power."

---

### 📘 Concept Explanation

**Game-Based Security Definitions:**

Security definitions in modern cryptography are formalized as security games between
a challenger and an adversary. The adversary wins if they can distinguish or forge;
the scheme is secure if no polynomial-time adversary can win with non-negligible
probability.

```text
IND-CPA GAME (Indistinguishability under
Chosen-Plaintext Attack):

  Challenger         Adversary
      |                  |
      |<-- (m0, m1) ------|  Adversary chooses
      |                  |  two messages
      |-- b = random 0/1 |
      |-- c = Enc(K, mb) |  Challenger encrypts
      |--- c ----------->|  one of them (randomly)
      |                  |
      |<-- b' = guess ----|  Adversary guesses
      |                  |  which was encrypted
      |                  |
  Adversary wins if b' == b
  Scheme is IND-CPA secure if:
    Pr[b' == b] <= 1/2 + negligible(n)

IND-CCA2 GAME (Chosen-Ciphertext Attack):
  Same as IND-CPA, but adversary also has
  access to a decryption oracle (can ask
  challenger to decrypt any ciphertext
  except the challenge ciphertext c).

  IND-CCA2 security => immune to:
  - Padding oracle attacks
  - Related-ciphertext attacks
  - Chosen-ciphertext distinguishing attacks
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the IND-CPA and IND-CCA2 game definitions
> that formalize what it means for an encryption scheme to be "secure." (2) KEY MECHANISM:
> the security game framework captures adversarial capabilities precisely; IND-CPA models
> an adversary who can choose plaintexts to encrypt but cannot obtain decryptions;
> IND-CCA2 additionally models the stronger adversary who has a decryption oracle,
> modeling attacks like padding oracles. (3) WHY IT MATTERS: a scheme that is only
> IND-CPA secure (like textbook RSA without OAEP padding) is insecure in the real world
> because an attacker can submit modified ciphertexts for decryption; IND-CCA2 security
> requires OAEP or equivalent and is the minimum security standard for practical systems.
> (4) WHAT BREAKS: AES-CBC with correct MAC ordering (Encrypt-then-MAC) is IND-CPA
> secure but not IND-CCA2 secure if the MAC is not constant-time; padding oracle attacks
> exploit the timing oracle. (5) TAKEAWAY: always use IND-CCA2 secure schemes for
> asymmetric encryption (RSA-OAEP, not textbook RSA) and AEAD for symmetric encryption;
> these are the minimum security standards for production systems.

**STRIDE Threat Modeling:**

STRIDE is a threat taxonomy developed by Microsoft for structured threat modeling.
Each letter represents a category of threat and the security property it violates.

```text
STRIDE THREAT TAXONOMY:

  S - Spoofing: impersonating another entity
      Violated property: Authentication
      Example: session fixation, ARP spoofing,
               phishing with lookalike domain
      Control: strong authentication (MFA),
               certificate pinning, DMARC

  T - Tampering: modifying data or code
      Violated property: Integrity
      Example: MITM modifying HTTP response,
               SQL injection, code signing bypass
      Control: HMAC, digital signatures,
               TLS for transport

  R - Repudiation: denying an action
      Violated property: Non-repudiation
      Example: user denies placing an order,
               attacker deletes audit logs
      Control: cryptographic audit logs,
               digital signatures on actions

  I - Information Disclosure: exposing data
      Violated property: Confidentiality
      Example: path traversal, verbose errors,
               cleartext passwords in logs
      Control: encryption, access control,
               log sanitization

  D - Denial of Service: reducing availability
      Violated property: Availability
      Example: DDoS, resource exhaustion,
               ReDoS, Zip bomb
      Control: rate limiting, WAF, CDN,
               input validation

  E - Elevation of Privilege: gaining access
      Violated property: Authorization
      Example: broken access control,
               IDOR, privilege escalation
      Control: least privilege, RBAC,
               security boundary enforcement
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the complete STRIDE taxonomy mapping each
> threat category to the security property it violates and its corresponding control.
> (2) KEY MECHANISM: STRIDE is applied by diagramming the system (data flow diagram
> with trust boundaries) and systematically asking "can an attacker [Spoof/Tamper/
> Repudiate/Disclose/Deny/Elevate] at each element and trust boundary?" This systematic
> enumeration prevents the "forgot to consider X" failure mode of informal threat
> modeling. (3) WHY IT MATTERS: STRIDE threat modeling is required for Microsoft's SDL
> (Security Development Lifecycle); AWS uses data flow diagrams with STRIDE for service
> threat models; many compliance frameworks (SOC2, GDPR's DPIA) implicitly require a
> threat model. (4) WHAT BREAKS: STRIDE without a data flow diagram produces an
> incomplete analysis; the diagram forces you to identify trust boundaries (where the
> security perimeter is crossed) which is where most threats materialize. (5) TAKEAWAY:
> create a data flow diagram for any new feature or service; apply STRIDE at each
> element and each trust boundary crossing; the result is a structured threat register
> that drives security requirements.

---

### 💻 Code Example

```python
# Demonstrating provable security properties:
# constant-time comparison for MAC verification

# BAD: variable-time comparison leaks MAC bytes
def verify_mac_bad(expected_mac: bytes,
                   actual_mac: bytes) -> bool:
    # Python == on bytes short-circuits on mismatch
    # Timing reveals how many bytes matched
    return expected_mac == actual_mac
    # Attacker: send MACs byte-by-byte;
    # the correct first byte takes slightly longer
    # to compare than wrong first bytes.
    # Can recover MAC one byte at a time.
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a variable-time MAC comparison vulnerability;
> Python's `==` on bytes short-circuits, returning False as soon as a mismatching byte
> is found; this creates a timing oracle where the comparison time correlates with the
> number of correct prefix bytes. (2) KEY MECHANISM: the attacker submits 256 candidate
> MACs differing only in the first byte; the one that takes slightly longer to compare
> is the correct first byte; repeated for each byte position, the full MAC is recovered
> in O(n*256) attempts rather than O(2^128). (3) WHY IT MATTERS: this attack has been
> demonstrated against real web frameworks; Django had a timing vulnerability in its
> HMAC comparison in 2012; the constant-time comparison fix is now in standard libraries.
> (4) WHAT BREAKS: implementing constant-time comparison manually is error-prone;
> compiler optimizations can reintroduce variable-time behavior; use the standard library
> function instead. (5) TAKEAWAY: never compare secrets with standard equality operators;
> always use `hmac.compare_digest()` (Python), `crypto.timingSafeEqual()` (Node.js),
> or `MessageDigest.isEqual()` with timing safety guarantees.

```python
# GOOD: constant-time comparison
import hmac

def verify_mac_good(expected_mac: bytes,
                    actual_mac: bytes) -> bool:
    """Constant-time comparison prevents timing attacks.
    hmac.compare_digest compares all bytes regardless
    of where the first mismatch occurs.
    """
    return hmac.compare_digest(expected_mac,
                               actual_mac)

# GOOD: full MAC verification with HMAC-SHA256
import hashlib

def create_mac(key: bytes, message: bytes) -> bytes:
    return hmac.new(key, message,
                    hashlib.sha256).digest()

def verify_full(key: bytes, message: bytes,
                provided_mac: bytes) -> bool:
    expected = create_mac(key, message)
    # Both: constant-time compare AND correct
    # HMAC construction (immune to length extension)
    return hmac.compare_digest(expected, provided_mac)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: constant-time MAC comparison using Python's
> `hmac.compare_digest()` which is implemented in C with a guarantee that comparison
> time does not vary with the position of the first mismatch. (2) KEY MECHANISM:
> `hmac.compare_digest()` XORs all byte pairs and accumulates the result; it processes
> all bytes regardless of early mismatches, making the comparison time O(n) independent
> of where the mismatch occurs. (3) WHY IT MATTERS: the combination of HMAC-SHA256
> (immune to length extension attacks) + constant-time comparison (immune to timing
> attacks) provides the security properties required for production MAC verification.
> (4) WHAT BREAKS: if `expected` and `provided_mac` have different lengths, some
> implementations return False immediately without comparing; `hmac.compare_digest()`
> is documented to resist timing attacks even in the length-mismatch case. (5) TAKEAWAY:
> every MAC and token verification in production code must use constant-time comparison;
> audit all security-sensitive comparisons and replace `==` with `hmac.compare_digest()`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A threat model defines who the attackers are, what they can do, and what we are
> protecting. Without it, security decisions are arbitrary - you might spend effort
> defending against attackers who cannot reach your system while ignoring ones that can.
> Formal security proofs prove that breaking a crypto scheme requires solving a hard
> math problem. STRIDE is a practical threat taxonomy (Spoofing, Tampering, Repudiation,
> Information Disclosure, DoS, Elevation of Privilege) used to systematically find
> security issues in a system design.

---

**Senior / Staff (5+ years):**
> Formal threat models are the foundation of rational security investment. The threat
> model defines the adversary (capabilities, motivation, resources), the assets (what
> must be protected), and the attack surface (entry points). Security decisions are
> evaluated against the threat model: a control that defends against an out-of-model
> adversary is waste; a control that leaves an in-model adversary unchecked is a gap.
> For protocol design: game-based security definitions (IND-CCA2, EUF-CMA) provide
> mathematical precision about what "secure" means; they allow comparing two schemes
> objectively. In practice: use STRIDE + data flow diagrams for product threat modeling;
> use formal analysis tools (ProVerif, Tamarin, TLS-Attacker) for protocol design; use
> CVSS and threat intelligence for prioritizing vulnerability remediation.

---

### ⚠️ Common Misconceptions

**Misconception 1: "A formal proof means the system is secure."**

A formal proof provides security guarantees conditional on: (1) the hardness of the
underlying mathematical assumption, (2) the correctness of the implementation matching
the proven scheme, and (3) the threat model matching the real-world adversary. Formal
proofs for RSA assume factoring is hard; if efficient quantum computers exist, RSA
proofs are invalid. An implementation bug can make a provably secure scheme insecure.
A proof under a weaker threat model (IND-CPA) does not guarantee security under a
stronger adversary (IND-CCA2).

**Misconception 2: "Threat modeling is a one-time activity."**

Threat models go stale as systems evolve. New features add attack surface; dependencies
change trust relationships; the threat landscape evolves. A threat model created at
system design time is a starting point, not a permanent artifact. Schedule threat model
reviews at: major feature releases, significant architecture changes, when new threat
intelligence is published about your system's components, and annually as a baseline.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Security proof does not match implementation.**

Symptom: a "provably secure" scheme is broken in practice.
Root cause: the proof models a simplified scheme; the implementation adds details
(error handling, padding, network framing) not in the proof; the attacker exploits
these implementation-specific details.
Example: PKCS#1 v1.5 RSA encryption has no formal proof; it was broken by Bleichenbacher's
1998 padding oracle attack. RSA-OAEP has a formal proof under the random oracle model.
Fix: use schemes with tight security reductions and formal proof coverage of the full
implementation, not just the core algorithm.

**Failure Mode 2: Threat model does not include in-scope attackers.**

Symptom: system is broken by an attack that was not considered.
Root cause: threat model assumed "attacker cannot observe network traffic" but the
system is deployed on a shared cloud host where traffic can be observed.
Fix: explicitly document all threat model assumptions; revisit assumptions when the
deployment environment changes; include "insider threat" and "compromised dependency"
in the threat model for high-security systems.

---

### ⚖️ Comparison Table

| Threat Model Method | Formality | Best For | Limitation |
|---|---|---|---|
| **STRIDE + DFD** | Semi-formal | Product security, feature design | Requires system diagram; manual process |
| **PASTA** | Risk-aligned | Business risk context | Complex; requires security expertise |
| **LINDDUN** | Semi-formal | Privacy threat analysis | Focuses on privacy only |
| **Attack Trees** | Formal | Specific attack analysis | Labor intensive for large systems |
| **ProVerif/Tamarin** | Fully formal | Protocol design and verification | Requires formal methods expertise |

---

### 🏛️ System Design

*(Omit: L6 Theory keyword; formal proofs and threat models are foundational analysis
methods that inform system design decisions covered in L4/L5 entries.)*

---

### 📊 Diagram

```text
STRIDE THREAT MODELING WORKFLOW:

  1. Draw Data Flow Diagram (DFD)
     [Browser] --HTTPS--> [API Server] --> [DB]
          ^                    |
          |                    v
       [CDN]            [Auth Service]

  2. Identify Trust Boundaries
     Browser/API: public internet boundary
     API/DB: internal service boundary
     API/Auth: internal service boundary

  3. Apply STRIDE at each boundary:
     Browser->API: S(spoofing), T(tampering),
                   I(disclosure), D(DoS)
     API->DB: T(injection), I(disclosure),
              E(privilege escalation)

  4. Generate Threat Register:
     ID | Threat | STRIDE | Risk | Control
     T1 | SQLi   | T      | High | Param query
     T2 | IDOR   | E,I    | High | Authz check
     T3 | XSS    | T      | Med  | CSP, encode

  5. Validate controls in code review
     and security testing
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the complete STRIDE threat modeling
> workflow from drawing a data flow diagram to generating a validated threat register.
> (2) HOW TO READ IT: top to bottom is the sequential process; the DFD (step 1)
> identifies components and data flows; trust boundaries (step 2) are the most important
> locations to analyze; STRIDE is applied at each boundary (step 3) to enumerate
> specific threats. (3) KEY RELATIONSHIP: the threat register (step 4) is the output
> that drives security requirements and testing; each threat has a risk rating and a
> control; the control is validated in code review and security testing (step 5). (4)
> EDGE CASE: missing trust boundaries are the most common STRIDE failure; if you do not
> identify the boundary between your system and a third-party API, you will not analyze
> the trust relationship and may miss spoofing or information disclosure threats through
> that boundary. (5) INSIGHT: a senior engineer notes that STRIDE is most valuable when
> done as a team exercise during design review; security expertise is not required for
> all participants; developers who understand the system often identify the most
> high-impact threats because they know which data flows contain sensitive information.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | IND-CCA2, threat modeling |
| Mechanism | 2 | Security reductions, STRIDE |
| Application | 2 | Threat modeling process, formal tools |
| Scenario | 2 | Protocol review, threat model gap |
| Trade-off | 1 | Formal vs practical security |

---

**[MID] Q1 (Definition): What is a threat model and why does every security decision need one?**

A threat model formally defines: (1) the system being protected (components, data flows,
trust boundaries), (2) the assets that must be protected (data, functionality, availability),
(3) the adversaries (capabilities, motivation, entry points), and (4) the attacks those
adversaries can mount.

Without a threat model, security decisions are arbitrary:
- You might implement strong encryption for data at rest while leaving the same data
  accessible via an unprotected API.
- You might invest in DDoS protection against nation-state attackers when your actual
  adversaries are script kiddies who stop at the first obstacle.
- You might implement MFA for every user while giving a third-party vendor unrestricted
  database access.

A threat model makes security decisions rational: a control is worth implementing if
it significantly reduces risk from an in-model adversary; a control that defends only
against out-of-model adversaries is waste.

Practical threat modeling: STRIDE applied to a data flow diagram is the most common
practical approach. The output is a threat register listing specific threats with risk
ratings and mitigations; this drives the security requirements for each component.

*What separates good from great:* The "adversary capabilities" definition. Most threat
models vaguely describe the adversary as "external attacker"; a precise threat model
specifies: can the adversary observe network traffic? Can they create accounts? Do they
have access to the source code? Do they have physical access to hardware? Each capability
enables different attack classes. A precise adversary model leads to precise control
selection; a vague one leads to both over-security and under-security simultaneously.

---

**[MID] Q2 (Definition): What does IND-CCA2 secure mean and why does it matter for practical systems?**

IND-CCA2 (Indistinguishability under adaptive Chosen-Ciphertext Attack) is the gold
standard security definition for encryption schemes. It models an adversary who can:
- Encrypt any plaintext of their choice (chosen-plaintext oracle).
- Decrypt any ciphertext of their choice except the challenge ciphertext (chosen-
  ciphertext oracle, adaptive: oracle can be queried after seeing the challenge).

A scheme is IND-CCA2 secure if this adversary cannot distinguish the encryption of
two chosen plaintexts with better than 50% probability.

Why it matters: a scheme that is only IND-CPA secure (no decryption oracle) can be
broken if the attacker has access to even a partial decryption oracle - which is the
case for any system that returns error messages, validates padding, or provides any
feedback about decryption failures. IND-CCA2 security is the minimum standard for
any encryption used in a system where an attacker can observe the outcome of decryption
operations (which is almost every real system).

Practical implications:
- Textbook RSA (no padding): not IND-CPA secure (deterministic: encrypt same plaintext
  twice, get same ciphertext).
- RSA-PKCS#1 v1.5: not IND-CCA2 secure (Bleichenbacher attack uses a padding oracle).
- RSA-OAEP: IND-CCA2 secure under the random oracle model.
- AES-CBC: not IND-CCA2 secure (padding oracle attacks).
- AES-GCM (AEAD): IND-CCA2 secure (assuming no nonce reuse).

*What separates good from great:* The random oracle model caveat. RSA-OAEP is proven
secure under the random oracle model (ROM), which models hash functions as truly random
functions. In practice, hash functions like SHA-256 are not random oracles; they have
algebraic structure. Whether ROM proofs translate to real-world security is an open
research question. For this reason, post-quantum key encapsulation mechanisms (KEMs)
like CRYSTALS-Kyber (NIST PQC winner) are designed with security proofs in the standard
model (no ROM assumption).

---

**[SENIOR] Q3 (Mechanism): How does a security reduction proof work?**

A security reduction proves that scheme S is secure by showing: if there exists an
efficient adversary A that breaks S, then there exists an efficient algorithm B that
solves hard problem H using A as a subroutine.

Since H is assumed computationally hard (infeasible to solve in polynomial time), A
cannot exist (or A would give an efficient solution to H, contradicting the hardness
assumption). Therefore S is secure.

Example: IND-CPA security of ElGamal encryption under the Decisional Diffie-Hellman
(DDH) assumption.
- DDH assumption: given (g, g^a, g^b, g^c), it is hard to determine if c = ab mod p.
- Reduction: if adversary A can distinguish ElGamal encryptions of m0 vs m1, then
  algorithm B can use A to solve the DDH problem.
- B simulates the IND-CPA game for A; when A produces a guess, B translates that guess
  into a DDH answer.
- Since DDH is assumed hard, A cannot win with non-negligible advantage; therefore
  ElGamal is IND-CPA secure under DDH.

Tightness of the reduction: if A breaks S with advantage epsilon, and B solves H with
advantage epsilon/2 (tight reduction), then the security of S is essentially equivalent
to the security of H. Loose reductions (B solves H with advantage epsilon/n^2) mean
that S requires larger parameters to achieve the same security level as H.

*What separates good from great:* The concrete security vs asymptotic security
distinction. Asymptotic security says: for any polynomial-time adversary. Concrete
security says: for any adversary running in time t with advantage epsilon, the key size
must be at least k bits. A scheme with a loose reduction may require 256-bit keys to
achieve 128-bit security; a scheme with a tight reduction only needs 128-bit keys.
TLS 1.3's design was partly guided by tight security reductions for the key schedule.

---

**[SENIOR] Q4 (Application): How do you conduct a threat modeling session for a new API?**

Threat modeling for a new API follows a structured process that produces a validated
threat register and security requirements.

Step 1 - Scope definition (30 minutes):
Define what is being modeled: the API endpoints, the data they handle, the clients
that call them, the downstream services they call. Define what is out of scope.

Step 2 - Data flow diagram (1 hour):
Draw: all API endpoints as processes, all data stores (databases, caches, queues),
all external entities (clients, downstream services, third-party APIs), all data flows
connecting them. Identify trust boundaries: where data crosses a security perimeter
(internet, internal network zone, database, third-party service).

Step 3 - STRIDE enumeration (1-2 hours):
For each trust boundary and data flow, systematically ask:
S: Can an attacker impersonate a legitimate entity here? (Authentication controls?)
T: Can an attacker modify data in this flow? (Integrity controls?)
R: Can actions be denied? (Non-repudiation controls, audit logs?)
I: Can data be observed by unauthorized parties? (Encryption, access control?)
D: Can availability be impacted at this point? (Rate limiting, circuit breaking?)
E: Can an attacker gain elevated access through this flow? (Authorization checks?)

Step 4 - Threat register (30 minutes):
For each identified threat: assign a threat ID, rate the risk (Likelihood x Impact),
identify the existing control (if any), identify the required control (if not mitigated).

Step 5 - Control validation:
Security requirements from the threat register are added to the API's test plan;
penetration testing validates high-risk threats; code review validates implementation
of controls.

*What separates good from great:* Running the threat model as a design exercise, not
a documentation exercise. The most valuable insight comes from the DFD construction
phase: when developers draw data flows, they often discover that data flows through
more systems than expected, that sensitive data is cached in unexpected places, or that
trust boundaries are not where they thought. These discoveries before implementation
are free; the same discoveries after deployment are expensive vulnerabilities.

---

**[SENIOR] Q5 (Scenario): A formal analysis tool (ProVerif) reports a potential attack on a protocol. How do you evaluate the finding?**

ProVerif and Tamarin are automated formal verification tools for cryptographic protocols.
They model the protocol as a symbolic process calculus and automatically check whether
an adversary who controls the network can achieve a given goal (secrecy, authentication,
forward secrecy).

Evaluating a ProVerif finding:

Step 1 - Understand the attacker model: ProVerif uses the Dolev-Yao model (all-powerful
network adversary who can intercept, modify, and inject messages). If your actual
threat model is weaker (passive adversary only), some findings may not apply.

Step 2 - Trace the attack: ProVerif outputs a witness trace showing the adversary
messages that lead to the attack. Read the trace step-by-step to understand: what
messages the adversary sends and receives, what secrets are exposed, which protocol
assumption is violated.

Step 3 - Determine if the attack is in-scope: does the attack require adversary
capabilities that are outside your threat model? Does it require a compromised
participant? If so, it may be an out-of-model finding that does not require a fix.

Step 4 - Verify the fix: once a protocol change is proposed to fix the finding,
re-run ProVerif with the updated model to confirm the attack trace no longer exists.

*What separates good from great:* The "symbolic vs computational" gap. ProVerif and
Tamarin use the symbolic model where cryptographic operations are ideal (perfect
encryption, perfect hash). A protocol proven secure in the symbolic model may still
be insecure in the computational model (where operations are implemented with real
algorithms that can have side channels or approximation errors). A symbolic proof is
necessary but not sufficient; complement with: computational analysis (CryptoVerif),
implementation review, and penetration testing.

---

**[SENIOR] Q6 (Application): How do you prioritize security controls when the threat model has many threats?**

Not all threats require immediate controls. Prioritization combines risk scoring with
business context.

Step 1 - Risk scoring for each threat:
Risk = Likelihood x Impact.
Likelihood factors: adversary motivation, adversary capability, attack difficulty,
existing partial controls.
Impact factors: data sensitivity, business criticality, regulatory consequence,
reputational damage.

Step 2 - Apply DREAD or CVSS for consistency:
DREAD (Damage, Reproducibility, Exploitability, Affected users, Discoverability):
5-point scale per dimension; total score ranks threats comparably.
CVSS (Common Vulnerability Scoring System): industry-standard scoring for known
vulnerability types; useful for comparing new findings to known CVE severity.

Step 3 - Business context adjustment:
A high-risk threat against a non-critical asset may be lower priority than a medium-risk
threat against the authentication system. Adjust priority based on: what assets are
at risk, what compliance implications exist, what the customer impact would be.

Step 4 - Create a prioritized remediation backlog:
Critical (CVSS 9+): must be fixed before deployment.
High (CVSS 7-9): fix in the next sprint; no release with this open.
Medium (CVSS 4-7): schedule within 30 days.
Low (CVSS 0-4): schedule within 90 days; accept with documentation.

*What separates good from great:* The "accept risk" decision. Not every threat can
be mitigated economically. Risk acceptance requires: documented business justification,
compensating controls (additional monitoring, incident response readiness), explicit
sign-off from the appropriate risk owner (not the security team - they assess; the
business unit owns the risk). Undocumented risk acceptance is "ignoring security";
documented risk acceptance with compensating controls is rational risk management.

---

**[SENIOR] Q7 (Trade-off): When should you use formal verification vs practical security testing?**

Formal verification (ProVerif, Tamarin) and practical security testing (penetration
testing, fuzzing) provide complementary coverage; neither alone is sufficient.

Formal verification strengths:
- Exhaustive: proves security for all possible adversary messages, not just the ones
  a tester thought of.
- Protocol-level: finds logical flaws in the protocol structure before implementation.
- Mechanized: the proof is checkable by a computer; human error in reviewing the proof
  is minimized.

Formal verification limitations:
- Symbolic model: ideal cryptographic operations; real implementations can have
  timing side channels, padding vulnerabilities.
- Protocol only: does not test the implementation (code bugs, memory safety, race
  conditions).
- Expertise required: using ProVerif or Tamarin requires formal methods expertise.
- Scope limited: models the protocol in isolation; does not model integration with
  other systems.

Practical security testing strengths:
- Implementation-level: finds bugs in actual code (buffer overflows, injection, logic
  errors).
- Integration: tests the full system including third-party libraries and deployment
  configuration.
- Adversarial creativity: human testers find unexpected attack paths.

Practical security testing limitations:
- Incomplete: cannot test all adversary message sequences.
- Misses logical flaws: pen testers may not find subtle protocol-level issues.

When to use each:
- Custom cryptographic protocol design: formal verification first, then implementation
  testing.
- Standard protocol implementation (TLS, OAuth): focus on implementation testing;
  the protocol is already formally analyzed.
- High-assurance systems (financial, healthcare, national security): both; the
  additional cost is justified by the risk.

*What separates good from great:* The "trust but verify" principle for cryptographic
libraries. Even formally verified protocols can be broken by bugs in the cryptographic
library implementation. The DUAL EC DRBG backdoor (NSA backdoor in an NIST-approved
PRNG) and the Heartbleed bug (memory read past buffer in OpenSSL) were both in
implementations of otherwise sound cryptographic designs. Regular library updates,
monitoring for CVEs in cryptographic dependencies, and independent audits of
cryptographic library code are essential for production systems.

---

**[SENIOR] Q8 (Application): How do you handle a threat that is in-model but too expensive to mitigate?**

When a threat is within the threat model but mitigation cost exceeds business tolerance,
the options are: accept the risk (with documentation), transfer the risk (insurance,
contractual), or reduce the risk through compensating controls.

Risk acceptance process:
1. Document the threat precisely: what attack, what adversary capability required,
   what impact if exploited.
2. Document why mitigation is infeasible: cost, technical constraint, timeline, or
   business trade-off.
3. Identify compensating controls: what reduces the risk without fully mitigating it?
   (Enhanced monitoring to detect exploitation, incident response plan for rapid
   response, reduced data retention to limit impact.)
4. Obtain sign-off from the appropriate risk owner: not the security team; the business
   unit head, product manager, or CISO depending on the risk level.
5. Review at a defined interval: accepted risks do not stay accepted forever; re-evaluate
   at each major release or annually.

Example: a startup cannot afford a full penetration test. Risk: an undetected vulnerability
could be exploited before discovery. Compensating controls: bug bounty program (external
security researchers), SAST/DAST in CI/CD pipeline, monitoring for anomalous API usage
patterns, rapid incident response capability. These do not eliminate the risk but reduce
likelihood and impact to an acceptable level given the business context.

*What separates good from great:* The risk owner distinction. The security team's job
is to identify and assess risk; it is not to decide whether the business should accept
it. When a security engineer says "this is not worth fixing," they are making a business
decision that is not theirs to make. Present the risk clearly to the risk owner; present
compensating controls; present the residual risk; let the risk owner decide. This
creates accountability and ensures that accepted risks are business decisions, not
security team oversights.

---

**[SENIOR] Q9 (Scenario): A new team member asks "is our system secure?" How do you answer?**

"Secure" is not a binary property; it is relative to a threat model. The correct
response is to ask: "Secure against what adversary, in what context, with what
assumptions?"

A structured answer:

"Our system has gone through the following security processes:
1. Threat modeling: we completed STRIDE threat modeling in [month]; the resulting
   threat register has [X] open items, [Y] of which are accepted risks with documentation.
2. Penetration testing: we had [firm] conduct a penetration test in [month]; the
   findings were [Z critical, A high, B medium], of which [C] remain open.
3. Dependency scanning: we run automated SCA (Snyk, Dependabot) against all dependencies;
   we have SLA of [time] for critical CVEs.
4. Code review: all code changes require security-focused code review for changes to
   authentication, authorization, and cryptographic operations.
5. Compliance: we are SOC2 Type II certified (last audit [date]); our controls were
   assessed as operating effectively.

Caveats: our threat model assumes [specific adversary model]; a more sophisticated
adversary (nation-state) may use capabilities not in our model. Our penetration test
covered [specific scope]; it did not cover [out-of-scope systems]."

*What separates good from great:* Honesty about unknowns. A mature security program
knows what it has tested, what remains untested, and what is in the accepted risk
register. Claiming "we are secure" without qualification is a red flag; it indicates
either overconfidence or lack of security program maturity. A senior engineer can
articulate the security posture precisely: what was tested, when, by whom, what was
found, what was fixed, what was accepted, and what assumptions the security claims rest on.
