# Security Policy

Tilawa (`tilawa-workspace`) takes the security of the Tilawa / MeMuslim apps, APIs, and related services seriously. We appreciate responsible disclosure of security issues.

## Supported Versions

Security updates are provided for the latest production release of the Tilawa mobile app and for the `master` branch of this repository.

| Version / Channel | Supported |
| ----------------- | --------- |
| Latest production app release (Play Store / App Store) | ✅ |
| `master` branch (workspace) | ✅ |
| Older production releases | ❌ (upgrade recommended) |
| Development / staging / preview builds | ❌ (report still welcome if they affect production risk) |

## Reporting a Vulnerability

**Do not** open a public GitHub issue, pull request, or discussion for security vulnerabilities.

### Preferred channel

Report privately via GitHub Security Advisories:

➡️ [Report a vulnerability](https://github.com/MuslimInc/tilawa-workspace/security/advisories/new)

### Alternate channel

If you cannot use GitHub Advisories, email:

**security@tilawa.app**

Use subject line: `[SECURITY] <short summary>`

### What to include

Please provide as much detail as you reasonably can:

- Affected product (Tilawa Android, Tilawa iOS, admin, Cloud Functions, etc.)
- Version / build number or commit SHA (if known)
- Vulnerability type (e.g. auth bypass, IDOR, injection, secrets exposure, payment fraud)
- Steps to reproduce
- Impact assessment (what an attacker could achieve)
- Proof of concept (non-destructive preferred)
- Any suggested remediation

### Response expectations

| Stage | Target |
| ----- | ------ |
| Initial acknowledgement | Within **3 business days** |
| Triage / severity assessment | Within **7 business days** |
| Status updates | At least every **14 days** until resolved or closed |

We may ask follow-up questions. Please keep the report confidential until we have published a fix or coordinated disclosure.

### Outcomes

- **Accepted** — We will work on a fix, credit you if you wish (unless you prefer to remain anonymous), and coordinate disclosure timing.
- **Declined** — We will explain why (e.g. intended behavior, out of scope, duplicate, or insufficient impact).

## Scope

In scope examples:

- Authentication / session / account takeover issues
- Authorization flaws (accessing another user’s data or actions)
- Sensitive data exposure (PII, tokens, payment-related data)
- Remote code execution, injection, or similar server-side flaws
- Insecure storage or transmission of secrets / credentials
- Payment / purchase bypass or privilege escalation
- Misconfigured Firebase / Cloud Functions / security rules with real-world impact

Out of scope examples (unless they demonstrate a practical security impact):

- Social engineering, phishing, or physical attacks
- Denial-of-service / volumetric flooding without a novel application bug
- Reports from automated scanners without a working proof of concept
- Missing security headers or best-practice recommendations with no exploitable impact
- Vulnerabilities only present in outdated clients after a fixed release is available
- Issues in third-party dependencies already tracked upstream (report upstream; link us if Tilawa is uniquely affected)

## Safe Harbor

We will not pursue legal action against researchers who:

- Make a good-faith effort to avoid privacy violations, data destruction, and service disruption
- Do not access, exfiltrate, or modify data beyond what is needed to demonstrate the issue
- Do not exploit the vulnerability beyond a minimal proof of concept
- Report findings promptly through the channels above
- Give us a reasonable time to remediate before public disclosure

If you are unsure whether an action is allowed, ask first via the reporting channel.

## Coordinated Disclosure

Please do not publicly disclose the vulnerability until:

1. We confirm a fix is released, **or**
2. We mutually agree on a disclosure date

We typically aim to resolve accepted issues as quickly as severity warrants. Critical issues affecting user accounts, payments, or sensitive data are prioritized.

## Prefer private reports

Public issues, PRs, and screenshots that reveal exploit details can put users at risk. When in doubt, use the private advisory form.

Thank you for helping keep Tilawa users safe.
