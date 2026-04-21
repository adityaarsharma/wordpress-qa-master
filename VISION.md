# Orbit — Vision

> This is the anchor document. Every contributor, every AI agent, every new
> feature decision checks back against this. If a change doesn't serve this
> vision, it doesn't belong in Orbit.

---

## What Orbit Is

**Orbit is a complete QA + UAT platform for WordPress plugins — run from one command, covering every perspective a plugin is judged from before users touch it.**

Orbit is NOT:
- A linter. (PHPCS is a linter. Orbit orchestrates linters and many other things.)
- Plugin-specific. (No brand names, no business logic, no hardcoded paths.)
- A replacement for human QA. (It does everything *automatable* so humans spend time on judgment calls.)
- Only for developers. (Product managers, designers, analysts, and release ops each get a role-specific output.)

---

## The Six Perspectives Orbit Must Always Cover

A plugin is judged from six distinct angles. Any release Orbit approves must satisfy all six. When we add a new check, we ask: *whose perspective does this serve?*

### 1. 👨‍💻 Developer
**What they need:** Zero-regression shipping. Fast feedback on what broke.
**What Orbit gives them:**
- PHP lint + WPCS + PHPStan L5 (static)
- Custom Claude skills that review source code for WP-specific vuln patterns (`/orbit-wp-security`, `/orbit-wp-performance`, `/orbit-wp-database`, `/orbit-wp-standards`)
- Zip hygiene + forbidden-function scan + supply-chain audit
- Pre-commit hook + `--dry-run` preflight
- Deprecation notice scan on PHP 8.x
- Per-PID exit tracking so failures are never silent

### 2. 🧪 QA Engineer
**What they need:** Structured test coverage with reproducible results.
**What Orbit gives them:**
- Playwright specs for every common WP entry point — admin pages, REST endpoints, AJAX actions, shortcodes, blocks, cron
- Auto-scaffolding (`scripts/scaffold-tests.sh`) — reads plugin code, generates draft test scenarios
- Conflict matrix against top 20 popular plugins
- Cross-browser (Chromium + Firefox + WebKit)
- Lifecycle tests: activation, uninstall cleanup, update path v1→v2, block deprecation
- Keyboard navigation, focus trap detection, admin color scheme matrix, RTL layout

### 3. 👔 Product Manager
**What they need:** Real user flows validated. "Time to first value" measured.
**What Orbit gives them:**
- Full user journey template (`user-journey.spec.js`) — install → configure → use → uninstall as one flow
- First-time user experience (`onboarding-ftue.spec.js`) — 3-clicks-to-core-feature metric
- Empty / error / loading / form-validation state coverage
- UAT HTML report with screenshots + video
- Reports index HTML — one landing page per release

### 4. 📊 Product Analyst
**What they need:** Analytics events actually fire when they should.
**What Orbit gives them:**
- `analytics-events.spec.js` — intercepts GA, Mixpanel, PostHog, and custom endpoints and asserts declared events fire on the triggering user action
- Event payload validation (not just "event fired" but "event fired with the right shape")
- Consent-mode handling check (GDPR)

### 5. 🎨 Designer
**What they need:** Visual correctness preserved across releases and configurations.
**What Orbit gives them:**
- Visual regression vs baseline AND vs previous git tag
- 9-scheme admin color compatibility matrix
- RTL layout validation (Arabic locale, no horizontal overflow)
- Full-page screenshots at desktop / tablet / mobile viewports
- Video recordings of every flow spec

### 6. 👤 End User (via release ops)
**What they need:** When they click update, nothing breaks. Their data is preserved. Their settings survive.
**What Orbit gives them (via the release gate):**
- Update-path migration test (v1 zip → v2 zip, assert settings preserved)
- Uninstall cleanup verification (no orphaned data)
- WP.org `plugin-check` compliance
- readme.txt parser validation, version parity, license compliance
- Memory profiling (catches plugins that crash 64MB shared hosting)
- Multisite / network activation sanity

---

## UAT Philosophy

Automated UAT ≠ just running tests. Orbit's UAT surface is specifically the **human-readable artifact** that a non-engineer can look at and say "ship it" or "no":

- **`reports/uat-report-<date>.html`** — video + screenshot comparison viewer
- **`reports/skill-audits/index.html`** — 6 AI code-review reports with severity badges, tabbed navigation
- **`reports/index.html`** — master landing linking every output of the run
- **`qa-scenarios.md`** (from scaffolder) — human-readable test plan derived from the actual plugin code

A product manager should be able to open one of these reports, scroll it, and know what the state of the release is without running anything themselves.

---

## Smart Principles (what keeps Orbit sharp over time)

### 1. Code-driven, not convention-driven
We don't ask "did the developer name their admin page `{{prefix}}-settings`?" We read `add_menu_page()` calls and find out what they actually named it. Every entry point is auto-discovered.

### 2. Skip gracefully, never fail-spurious
If a plugin has no blocks, block.json checks skip (don't fail). If no WooCommerce references, HPOS check skips. Tests `test.skip()` when their `qa.config.json` field isn't set. Orbit never fails a release for a check that wasn't applicable.

### 3. Severity-aware
Not every finding blocks a release. Orbit classifies:
- **Critical / High** — block release
- **Medium** — fix in this release if <30 min, else backlog
- **Low / Info** — log and defer

### 4. Every check cites its source
If we say "XSS via shortcode attrs affects 6M sites", we link the Patchstack report. Claim without citation = claim we remove.

### 5. Review, don't generate
The 4 custom Orbit skills are explicitly reviewers, not scaffolders. `/orbit-wp-security` reads PHP and finds bugs. It does not generate new plugin code.

### 6. Plugin-agnostic, always
Orbit never hardcodes a plugin slug, brand, or path. Every script takes `<plugin-path>` as argument. No leakage from the framework into specific plugins.

### 7. Self-testing
`scripts/gauntlet-dry-run.sh` validates the framework itself — every dep, every skill, every script, env connectivity. Run before any real work.

---

## Current State (April 2026)

### Coverage matrix

| Category | Checks | Status |
|---|---|---|
| Static analysis | 5 (lint, PHPCS, PHPStan, zip-hygiene, **PHP 8.0-8.5 compat**) | ✅ shipped |
| Release gate | 9 (header, readme.txt, version parity, license, block.json, HPOS, **WP function compat, modern WP, Requires Plugins**) | ✅ shipped |
| Functional E2E | 15 Playwright specs (+ **bundle-size** per page) | ✅ shipped |
| Security | **22** vuln patterns in `/orbit-wp-security` (incl. April 2026 supply-chain attack patterns) | ✅ shipped |
| Performance | Lighthouse + DB profile + memory + object cache + **script loading strategy + Script Modules dynamic deps** | ✅ shipped |
| Accessibility | axe + keyboard + colors + RTL | ✅ shipped |
| PM / PA | User journey + FTUE + analytics + empty/error/loading states | ✅ shipped |
| Modern WP (6.5–7.0) | Script Modules, Interactivity API, Block Bindings, Site Health, Plugin Dependencies, plugin-updater detection, external menu links | ✅ shipped |
| Auto-scaffolding | `scaffold-tests.sh` reads plugin + generates config + scenarios + specs | ✅ shipped |
| CI | GitHub Actions, pre-commit hook, dry-run preflight | ✅ shipped |
| Reporting | Master HTML index + UAT HTML + skill audit HTML | ✅ shipped |
| **Evergreen security log** | Living attack-pattern catalog at `docs/21-evergreen-security.md`, 90-day cadence | ✅ shipped |

### Ongoing research (what we're watching)

Security is evergreen — Orbit maintains [docs/21-evergreen-security.md](docs/21-evergreen-security.md)
as a live attack-pattern log. Updated quarterly (next pass: July 2026).

**Areas under active watch (as of April 2026):**

1. **WP 7.0 Abilities + Connectors API** — launched March 2026. Our `wp7-connectors.spec.js` probes `WP_Ability` class + `abilities_api_init` + `wp_execute_ability`. `/orbit-wp-security` pattern #18 defends against the April 2026 EssentialPlugin attack vector.
2. **PHP 8.4 / 8.5 deprecations** — implicit nullable types, dynamic properties, E_STRICT removed. Covered by `check-php-compat.sh` (April 2026).
3. **WP 6.9 list table `manage_posts_extra_tablenav`** — plugins hooking this break silently when the list is empty. Empty-state spec covers general case; dedicated spec pending.
4. **Patchstack quarterly reports** — 2025 top 5 vuln classes: XSS 34.7%, CSRF 19%, LFI 12.6%, Broken Access Control 10.9%, SQLi 7.2%. 2026 mid-year report expected July.
5. **WP.org plugin-check tool** — canonical rule list at [github.com/WordPress/plugin-check](https://github.com/WordPress/plugin-check/blob/trunk/docs/checks.md). Re-sync `gauntlet.sh` Step 2b + our own checks quarterly.
6. **AI-generated code hallucinations** — `/vibe-code-auditor` ships. New LLM versions introduce new hallucination patterns; monitor.
7. **Script Modules cross-plugin pollution** — WP 6.5+ shared module registry, collision surface.
8. **Plugin ownership transfer backdoors** — EssentialPlugin April 2026 attack pattern. Static detection for the 3 signature patterns ships in `/orbit-wp-security`. Ownership-transfer detection at registry level is out of scope.

See `docs/21-evergreen-security.md` for the full SHIPPED / RESEARCHING / WATCHING log.

---

## Contribution Rules

If you propose a new check, it must:

1. **Pick a perspective.** Which of the 6 users does it serve? State it in the PR.
2. **Cite the source.** Why does this bug happen? CVE ID, wp.org handbook link, Patchstack article, or real postmortem.
3. **Be plugin-agnostic.** Works on any plugin by default.
4. **Skip gracefully.** Doesn't fail if the plugin doesn't have the thing you're checking for.
5. **Tell the user how to fix.** Error messages include the fix.

If you propose a new skill, it must:

1. **Have a clear negative scope.** "This skill does X. It does NOT do Y." Add this to the top of SKILL.md.
2. **Enumerate patterns with code examples.** Bad code + good code + severity rating rule for every pattern.
3. **Be a reviewer, not a generator.** Unless the skill's whole purpose is scaffolding (like `/orbit-scaffold-tests`).

If you propose a new doc, it must:

1. **Have a clear audience.** Which of the 6 perspectives is it for?
2. **Link back to VISION.md.** Explain which vision principle it serves.
3. **Have runnable examples.** Not just theory.

---

## Anti-goals

Orbit will not become:

- A WordPress penetration-testing tool (WPScan, Metasploit domain — off-limits)
- A WordPress site-monitoring product (that's Site Health, Jetpack, etc.)
- A plugin-store reviewer (no compat scoring, no reviews ingestion)
- A WordPress.org replacement (we help plugins pass wp.org review; we are not the review team)
- A cloud service (Orbit runs locally and in CI, no SaaS component)
- A learning resource for WordPress development (we assume you know WordPress)

---

## Success Metrics

Orbit succeeds when:

- ✅ A developer can `bash scripts/gauntlet.sh --plugin <path>` and know within 15 minutes whether to ship.
- ✅ A product manager can open `reports/uat-report-*.html` without any terminal commands.
- ✅ A QA engineer can `bash scripts/scaffold-tests.sh <plugin>` and start with a 50-scenario test plan instead of blank page.
- ✅ A release manager can run `gauntlet.sh --mode release` and get a pass/fail that matches what WP.org will say.
- ✅ An analyst can verify all tracked events fire without manual clicking.
- ✅ A designer can see a visual diff against the last tag without setting up any tools.

---

## Versioning of this doc

Treat VISION.md like the plugin-itself header. When the surface materially changes, bump:

- **Minor change** — adding one check: update the "Current State" table only.
- **Major change** — adding a new perspective, removing a principle, changing an anti-goal: new commit with a changelog line in CHANGELOG.md.

Last material update: April 2026 — completed PM/PA role coverage, auto-scaffolder shipped, VISION.md established.
