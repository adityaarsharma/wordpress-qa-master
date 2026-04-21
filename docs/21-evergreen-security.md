# Evergreen Security Log

> Security doesn't stand still. This file is Orbit's living record of WordPress
> plugin attack patterns we've researched, shipped defenses for, and continue to
> monitor. When a new pattern emerges, add it here first with date + source,
> then ship a detection.

**Last research pass:** April 2026
**Research cadence:** 90 days (next: July 2026)

---

## How this log works

Each entry has:
- **Pattern name** — short label
- **Discovered** — date the pattern entered public knowledge
- **Sources** — primary links
- **How it works** — attack mechanics in one paragraph
- **Detection** — where Orbit catches it (skill file, script, or spec)
- **Status** — `SHIPPED` (detection live), `RESEARCHING` (known, no detection yet), `WATCHING` (emerging)

---

## SHIPPED — attack patterns Orbit detects today

### Supply Chain: Plugin ownership transfer + delayed backdoor
- **Discovered:** April 2026 — EssentialPlugin attack, 30+ plugins, 400K+ sites
- **Sources:**
  - [Patchstack analysis](https://patchstack.com/articles/critical-supply-chain-compromise-on-20-plugins-by-essentialplugin/)
  - [Next Web coverage](https://thenextweb.com/news/wordpress-plugins-backdoor-supply-chain-essential-plugin-flippa-2)
- **How it works:** Attacker bought plugin portfolio via Flippa. Pushed v2.6.7 with 191 extra lines of PHP including a deserialization backdoor. Code sat dormant 8 months, activated April 5-6 2026. WordPress.org closed 31 plugins April 7 2026.
- **Detection in Orbit:**
  - `/orbit-wp-security` pattern #18 — `unserialize()` on HTTP responses (Critical)
  - `/orbit-wp-security` pattern #19 — `'permission_callback' => '__return_true'` flag
  - `/orbit-wp-security` pattern #21 — callable property injection gadget chain
- **Status:** **SHIPPED** April 2026

### is_admin() misconception (unauth admin-ajax)
- **Discovered:** Long-known; amplified by Patchstack 2024 data
- **How it works:** `is_admin()` returns true for any admin-ajax.php request, including unauthenticated bot traffic. Developers use it as an auth gate, exposing sensitive actions.
- **Detection:** `/orbit-wp-security` pattern #1
- **Status:** **SHIPPED**

### Conditional nonce bypass
- **Discovered:** Common CSRF pattern, ~18% of 2024 WP CSRF disclosures per Patchstack
- **How it works:** `if (isset($_POST['nonce']) && !wp_verify_nonce(...))` — attacker omits the nonce field entirely, `isset` is false, whole condition short-circuits, die() never fires.
- **Detection:** `/orbit-wp-security` pattern #2
- **Status:** **SHIPPED**

### Shortcode attribute Stored XSS
- **Discovered:** 2024 — 100+ plugins, 6M sites per Patchstack
- **How it works:** `wp_kses_post()` on shortcode output does NOT sanitize attributes. Plugins echo `$atts['url']` directly into HTML.
- **Detection:** `/orbit-wp-security` pattern #3
- **Status:** **SHIPPED**

### ORDER BY / LIMIT SQL injection
- **Discovered:** Common; `$wpdb->prepare()` cannot parameterize ORDER BY or LIMIT clauses — many devs assume it can.
- **Detection:** `/orbit-wp-security` pattern #4 + `/orbit-wp-database` pattern #1
- **Status:** **SHIPPED**

### LFI via user-controlled `include` / `readfile`
- **Discovered:** Patchstack 2025 — 12.6% of all WP vulns
- **Detection:** `/orbit-wp-security` pattern #11
- **Status:** **SHIPPED**

### Broken Access Control in admin-post / admin_init
- **Discovered:** Patchstack 2025 — 10.9% of all WP vulns
- **Detection:** `/orbit-wp-security` pattern #12
- **Status:** **SHIPPED**

### Dynamic `current_user_can()` with user input
- **Discovered:** Essential Addons 2023 CVE, Fluent Forms 2024
- **How it works:** `current_user_can($_POST['cap'])` — attacker sets cap to `'exist'` which returns true for any logged-in user. Direct privilege escalation.
- **Detection:** `/orbit-wp-security` pattern #17
- **Status:** **SHIPPED**

### `register_setting()` without `sanitize_callback`
- **Discovered:** Canonical plugin-check rule
- **How it works:** Option-based XSS; user-controlled setting stored raw in wp_options, echoed as HTML on the next admin page load.
- **Detection:** `/orbit-wp-security` pattern #20
- **Status:** **SHIPPED** April 2026

### `ALLOW_UNFILTERED_UPLOADS = true`
- **Discovered:** WP.org auto-reject rule
- **How it works:** Defining this constant bypasses WP's MIME allowlist, allowing .php uploads → RCE.
- **Detection:** `check-zip-hygiene.sh`
- **Status:** **SHIPPED** April 2026

### External admin menu URLs (scam plugins)
- **Discovered:** Plugin-check `external_admin_menu_links` canonical rule
- **How it works:** `add_menu_page()` with an external URL as slug → clicking the menu item redirects to attacker's affiliate/phishing site.
- **Detection:** `check-modern-wp.sh`, `/orbit-wp-security` pattern #22
- **Status:** **SHIPPED** April 2026

---

## RESEARCHING — known patterns, detection planned

### PHP 8.4 implicitly nullable type deprecation
- **Discovered:** PHP 8.4 release (Nov 2024)
- **How it works:** `function foo(string $x = null)` — implicit nullable deprecated; at PHP 9.0 will be error. Plugins shipping this on PHP 8.4 see deprecation notices; on 9.0 they'll fatal.
- **Detection:** `check-php-compat.sh` (shipped April 2026)
- **Status:** **SHIPPED** April 2026 (moving to SHIPPED category next pass)

### WP 6.9 list table `manage_posts_extra_tablenav` empty-state change
- **Discovered:** WP 6.9 release, Dec 2025
- **How it works:** WP 6.9 skips rendering the bottom tablenav when list table has no items. Plugins using that hook to display custom empty-state UI break silently.
- **Detection:** `empty-states.spec.js` covers the general empty-state case. Specific hook breakage needs dedicated spec.
- **Status:** **RESEARCHING**

---

## WATCHING — emerging patterns, no confirmed exploitation yet

### WP 7.0 Connectors API key extraction
- **Discovered:** April 2026 — API launched, no reported exploits yet
- **How it works:** Connector keys stored in DB not encrypted, no per-plugin scoping. A malicious plugin could enumerate and exfiltrate every site's OpenAI/Anthropic keys.
- **Detection planned:** `wp7-connectors.spec.js` probes for correct Ability registration + permission_callback enforcement. Extraction detection needs SAST rule.
- **Status:** **WATCHING**

### Plugin Dependencies (Requires Plugins) impersonation
- **Discovered:** Theoretical; WP 6.5+ feature
- **How it works:** Plugin declares `Requires Plugins: woocommerce` but uses it in ways that assume a specific version. On mismatch → fatal.
- **Detection:** `check-modern-wp.sh` validates declaration format. Runtime version-compat checks needed.
- **Status:** **WATCHING**

### AI-generated code vulnerabilities
- **Discovered:** Ongoing 2024-2026 — AI assistants (Copilot, Cursor, Claude) hallucinate `sanitize_*` variants that don't exist, skip nonce checks silently, invent WP functions.
- **How it works:** Developer accepts AI suggestion without reviewing. Code looks plausible but has subtle WP-specific auth/sanitization holes.
- **Detection:** `/vibe-code-auditor` skill (shipped). We watch for new patterns as LLMs change.
- **Status:** **SHIPPED** + **WATCHING** for new hallucination modes

### Script Modules cross-plugin pollution
- **Discovered:** WP 6.5+ Script Modules feature
- **How it works:** All plugins share the same module registry. Collisions on module IDs possible. One plugin overriding another's registration could inject JS.
- **Detection:** `check-modern-wp.sh` detects Script Module usage. Conflict detection needs runtime spec.
- **Status:** **WATCHING**

---

## Research sources — quarterly reads

These are the feeds we re-read every 90 days:

1. **Patchstack** — [2026 mid-year report (when published)](https://patchstack.com/whitepaper/) + quarterly "Most Exploited" reports
2. **Wordfence blog** — weekly vulnerability roundups
3. **Make WordPress Plugins** — [weekly team updates](https://make.wordpress.org/plugins/)
4. **Make WordPress Core** — [dev notes for each WP release](https://make.wordpress.org/core/)
5. **PHP RFC announcements** — what's deprecated next
6. **WP.org plugin-check releases** — [docs/checks.md](https://github.com/WordPress/plugin-check/blob/trunk/docs/checks.md) canonical rule evolution
7. **Reddit r/ProWordPress + r/WordPress** — real practitioner pain points
8. **CVE database** — filter on plugin category

---

## The 90-day process

Every quarter:
1. Read the 8 sources above
2. For each new pattern found: add it here under `WATCHING` with date + source
3. For each `WATCHING` item that sees its first exploitation: promote to `RESEARCHING`
4. For each `RESEARCHING` item: ship detection → promote to `SHIPPED`
5. Update VISION.md "Current State" table
6. Tag a release with the security log delta in CHANGELOG.md

---

## Threat model we defend against

Orbit assumes:
- **Attackers read plugin source** (it's free and open)
- **Attackers buy plugin ownership on Flippa** (proven April 2026)
- **Developers use AI assistance** (and AI hallucinates WP-specific patterns)
- **Users install 20+ plugins** (conflict surface)
- **Users run shared hosting** (64MB PHP memory, no WAF, no monitoring)
- **Users don't update** (plugins sit on old versions for months)
- **Sites reach 10k+ posts / users** (scale breaks naive code)

We do NOT assume:
- A professional security team is reviewing code (most plugin authors are solo)
- Any runtime monitoring (most sites have none)
- Users read security advisories (they click "update" and trust the author)

Orbit's job: catch what can be caught at static-analysis + E2E time, so the first line of defense is the release gate — before the plugin hits WordPress.org.
