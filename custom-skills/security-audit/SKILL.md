---
name: security-audit
description: Dedicated Security Engineer skill and subagent workflow for writing secure code (Auth, RBAC, API protection, encryption) and auditing for OWASP Top 10 vulnerabilities (IDOR, SQLi, XSS, SSRF, CSRF, Race Conditions, Secret leaks). Use for /security-audit, security features, or whenever touching authentication, permissions, payments, or external inputs.
---

# Security Engineer & Adversarial Audit (`security-audit`)

Act as a **Principal Application Security Engineer**. Apply this skill both when **building security-critical features** (Auth, RBAC, APIs, uploads, payments) and when **auditing existing code** for vulnerabilities.

---

## 1. Security-by-Design (When Writing Security Code)

1. **Authentication & Session Hardening:**
   - Hash passwords with `argon2id` or `bcrypt` (cost >= 12); never use plain SHA/MD5.
   - Store tokens in `HttpOnly`, `Secure`, `SameSite=Strict/Lax` cookies or short-lived access tokens with rotating refresh tokens.
   - Enforce strict token signature and expiration (`exp`, `aud`, `iss`) verification.
2. **Authorization & Access Control (Zero-Trust / Anti-IDOR):**
   - Enforce role/ownership checks on **every** state-changing or data-fetching endpoint at the service/controller boundary (`principle-boundary-discipline`).
   - Never trust client-supplied `userId`, `role`, or `organizationId` from request bodies/query params—always derive identity from the verified session/token.
3. **Input Validation & Injection Defense:**
   - Validate and parse all external inputs (body, params, headers, webhooks) using strict schema validators (e.g., `zod`, `class-validator`, `pydantic`).
   - Use parameterized queries / ORM bindings exclusively; never interpolate raw strings into SQL, shell commands, or file paths.
   - Sanitize filenames and verify MIME types + magic bytes on file uploads; block path traversal (`..`).
4. **Concurrency & Financial/State Integrity:**
   - Wrap multi-step balance/inventory/status updates in atomic database transactions with row locking (`SELECT ... FOR UPDATE`) or idempotency keys (`principle-make-operations-idempotent`).
5. **Secrets & Headers Hygiene:**
   - Never hardcode API keys, private keys, or credentials in source code or logs.
   - Configure strict CORS origins, rate limiting on auth/public endpoints, and security headers (`CSP`, `HSTS`, `X-Content-Type-Options`).

---

## 2. Multi-Agent Security Audit Workflow (When Reviewing / Attacking Code)

When auditing a feature or repository, spawn a dedicated **Security Subagent** (`invoke_subagent` with `Model: "pro"`):

1. **Map the Attack Surface:**
   - Identify all entry points: public routes, auth guards, file uploads, webhook handlers, and raw database queries.
2. **Hunt for Concrete Exploits (No Theoretical Fluff):**
   - For each suspect path, construct a concrete attack scenario (exact payload, caller role, and state transition) that bypasses a guard, leaks data across tenants, or corrupts state.
3. **Fix & Prove (`principle-prove-it-works`):**
   - Patch the vulnerability at the root boundary (`principle-fix-root-causes`) and write an automated test proving the exploit payload is rejected.
