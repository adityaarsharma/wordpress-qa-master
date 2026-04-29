# Changelog

All notable changes to Orbit follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

---

## [Unreleased]

---

## [2.7.0] — 2026-04-30 — "Runtime-Evergreen + Brainless Agent"

The big conceptual shift: skills are no longer snapshots. Every skill is **runtime-evergreen** — when invoked, it fetches its canonical sources via WebFetch FIRST, derives current rules from today's docs, applies them to the user's plugin, and cites the live URL + fetch timestamp in every finding. No more "manually update the skill quarterly." Same `/orbit-elementor-compat` SKILL.md handles Elementor V4 today, V5 when it ships, V6 when that ships — because the rule-source is the live changelog, not embedded text.

Plus the brainless team agent the user asked for: `/orbit-do-it <plugin-path>` orchestrates everything; `/orbit-uat-agent` runs Stagehand-style natural-language UAT (write tests in English, no selectors).

### Added — 9 new skills

- **`/orbit-do-it`** — brainless orchestrator. Auto-detects plugin type, assembles the right pipeline (core 6 audits + type-specific add-ons + UAT + live security feeds), runs in parallel, generates one-page TL;DR + master HTML report. Zero questions after the path. ~10-15 min.
- **`/orbit-uat-agent`** — Stagehand-style natural-language UAT runner. Reads plugin code, infers user flows, generates English test plans, executes via AI-resolved selectors that survive UI changes. Self-heals on DOM drift.
- **`/orbit-wp-playground`** — thin wrapper for WordPress core's official agent skills (`WordPress/agent-skills`, Brandon Payton, Jan 2026). Composes; doesn't reinvent.
- **`/orbit-abilities-api`** — WP 7.0 Abilities API + AI Client API audit.
- **`/orbit-rtc-compat`** — WP 7.0 Real-Time Collaboration compat. Classic meta-boxes block RTC.
- **`/orbit-vdp`** — EU Cyber Resilience Act (2026) mandates VDP for every commercial WP plugin sold in EU.
- **`/orbit-premium-audit`** — stricter audit for Pro plugins. Patchstack 2026: 76% of premium-component vulns exploitable.
- **`/orbit-broken-access-control`** — OWASP A01 deep audit. Patchstack: BAC = 57% of all blocked WP attacks.
- **`/orbit-skill-improver`** — action-mode meta-skill. Replaces read-only `/orbit-evergreen-update`. `--check`, `--apply`, `--pr` modes.

### Changed — 6 skills rewritten with runtime-fetch pattern

- **`/orbit-elementor-compat`** — fetches Elementor's changelog at runtime
- **`/orbit-cve-check`** — fetches 5 security feeds on every invocation
- **`/orbit-host-kinsta`** — fetches banned-plugins list + cache rules live
- **`/orbit-host-wpengine`** — fetches disallowed list + EverCache rules live
- **`/orbit-pay-stripe`** — fetches Stripe docs at runtime
- **`/orbit-plugin-check`** — fetches latest plugin-check release; verifies user's version

### Added — EVERGREEN.md rewritten

Runtime-evergreen pattern is now the doc's main definition. Every skill must have `## Runtime — fetch live before auditing (DO THIS FIRST)` near the top with executable instructions.

### Added — install.sh chains WordPress/agent-skills

```bash
npx openskills install WordPress/agent-skills
npx openskills sync
```

Runs alongside Orbit's symlink step. User gets both Orbit's QA-focused skills + WP core's runtime / Playground primitives.

### Removed

- **`SKILL-ROADMAP.md`** — most candidates from v2.5/v2.6 shipped; remaining gaps tracked via GitHub issues + `/orbit-skill-add` for community contributions.

### Migration from v2.6

```bash
bash ~/Claude/orbit/install.sh --update
# Symlinks the 9 new skills + the 6 rewritten ones
# Restart Claude Code (Cmd+Q + reopen)
# Then: /orbit-skill-improver --check
```

The 6 rewritten skills demonstrate the pattern. Other skills retrofit via `/orbit-skill-improver --apply` over time.

### Stats
- 115 total skills (was 106 in v2.6)
- WordPress/agent-skills installed alongside Orbit (composes, doesn't compete)
- 6 fully runtime-evergreen demonstration skills; remaining retrofit via the meta-skill

---

## [2.6.0] — 2026-04-29 — "Evergreen + Limitless"

61 new skills (now **106 total**), each linked to live canonical sources so the suite stays current with the day's reality, not statically frozen. Plus a meta-skill (`/orbit-evergreen-update`) that walks every other skill, fetches the linked sources, flags drift.

### Added — The Evergreen Pattern

- **`EVERGREEN.md`** — the whitepaper / philosophy doc. Every skill must include a `Sources & Evergreen References` section with: canonical doc URLs (fetch on every audit), rule lineage (which release added each rule), and a `Last reviewed` date. The canonical doc is always source-of-truth; rules in SKILL.md are a starting point.

- **`/orbit-evergreen-update`** — meta-skill that walks every `~/.claude/skills/orbit-*/SKILL.md`, fetches the linked sources, diffs against embedded rules, flags drift. Operating modes: `--check` (read-only), `--apply` (auto-fix non-controversial), `--specific orbit-X` (single skill), `--source <URL>` (force re-check across all skills). Recommended cadence: quarterly + after every WP minor release.

### Added — 61 new skills

#### Block Editor / Gutenberg Dev (8 new)
- **`/orbit-gutenberg-dev`** — block dev workflow audit (apiVersion, render.php, supports, textdomain, ServerSideRender migration)
- **`/orbit-block-render-test`** — server-side render coverage check + test scaffolder
- **`/orbit-block-edit-test`** — editor-time UX coverage (InspectorControls, transforms, undo/redo, inner blocks)
- **`/orbit-block-patterns`** — block-pattern registration audit (`viewportWidth`, synced patterns, pattern category)
- **`/orbit-fse-test`** — Full-Site-Editing compat (theme.json schema 3, templates, parts, style variations, block locking)
- **`/orbit-block-bindings`** — Block Bindings API (WP 6.5+) — catches plugins still using `render_block` filter pattern
- **`/orbit-interactivity-api`** — modern client-side block behaviour without bundling React for the frontend
- **`/orbit-block-variations`** — `registerBlockVariation()` audit; flags over-blocking that should be variations

#### Elementor Dev (6 new)
- **`/orbit-elementor-dev`** — Widget_Base structure, register_controls, render escaping, get_*_depends, content_template
- **`/orbit-elementor-controls`** — built-in vs custom controls, selectors for live preview
- **`/orbit-elementor-compat`** — across-version matrix (3.18 / 3.20 / 3.22 / latest), deprecated APIs, Editor V4 prep
- **`/orbit-elementor-pro`** — Form Action subclasses, Display Conditions, Theme Builder locations, Popup triggers
- **`/orbit-elementor-skins`** — Skin_Base subclassing; flags plugins shipping multiple widgets that should be skins
- **`/orbit-elementor-dynamic-tags`** — Tag class structure, categories, sanitization, Pro guard

#### UAT Specialised Templates (5 new)
- **`/orbit-uat-elementor`** — drag → configure → save → frontend, responsive breakpoints, Theme Builder context
- **`/orbit-uat-gutenberg`** — uses `@wordpress/e2e-test-utils-playwright`, FSE template context, Query Loop, synced patterns
- **`/orbit-uat-woo`** — product CRUD, classic + Block Checkout, HPOS-aware, REST + Store API, refunds
- **`/orbit-uat-forms`** — render, validation (client + server), anti-spam, file upload, multi-step, GDPR consent
- **`/orbit-uat-membership`** — registration, server-side paywall, course progress, drip schedule, cert generation, sub lifecycle

#### QA Specialised (5 new)
- **`/orbit-qa-flaky-detector`** — runs each spec N times, flags pass-rate < 100%, suggests root causes
- **`/orbit-qa-mutation`** — Infection PHP — measures TEST quality, not code quality; MSI tracking
- **`/orbit-qa-coverage`** — PHPUnit + Xdebug / pcov line + branch + function coverage
- **`/orbit-qa-snapshot-cleanup`** — find orphan / stale Playwright PNGs; Linux-only baseline strategy
- **`/orbit-qa-regression-pack`** — `@regression`-tagged tests; coverage rate per [FIX] commit

#### PM Specialised (5 new)
- **`/orbit-pm-rice`** — RICE-scored backlog from any audit's findings; severity-override rules
- **`/orbit-pm-release-notes`** — auto-draft 4 outputs (blog / email / readme.txt / social) from CHANGELOG + git diff + visual regression
- **`/orbit-pm-feedback-mining`** — mine WP.org reviews + forum threads + GitHub issues into themed action items
- **`/orbit-pm-roadmap`** — quarterly roadmap from RICE + feedback + competitor gaps; north-star metric per quarter
- **`/orbit-pm-competitor-pulse`** — monthly competitor cadence / bundle / rating tracker; cron-friendly

#### Designer Specialised (5 new)
- **`/orbit-designer-tokens`** — colour / typography / spacing / radius / shadow tokens audit; WP admin token adoption
- **`/orbit-designer-empty-error`** — empty-state coverage with CTAs; error-state coverage with recoverable messages
- **`/orbit-designer-icons`** — icon-library inventory (Dashicons, FA, inline SVG), accessibility, sizing scale
- **`/orbit-designer-rtl`** — logical properties vs hardcoded directional values; rtl.css + `wp_style_add_data`
- **`/orbit-designer-dark-mode`** — WP admin colour-scheme matrix + `prefers-color-scheme` + contrast in both modes

#### Performance Deep (3 new)
- **`/orbit-perf-stress-test`** — k6 / JMeter — concurrent users, p50/p95/p99 latency, throughput, error rate
- **`/orbit-perf-memory-leak`** — runs hot path N times, measures `memory_get_usage()`, flags linear growth
- **`/orbit-perf-cdn`** — Cloudflare / BunnyCDN / KeyCDN compat — asset URL rewrites, immutable cache, CORS for fonts

#### Security Specialised (3 new)
- **`/orbit-sec-xss-active`** — active XSS probing — DOM / reflected / stored payloads against every URL parameter, form, REST endpoint
- **`/orbit-sec-supply-chain`** — Composer + npm CVE check, license compatibility, abandoned packages, typosquatting risk, lockfile integrity
- **`/orbit-sec-secrets-leak`** — gitleaks-style — API keys, OAuth tokens, AWS / Stripe / Twilio / Slack patterns; full git history scan

#### SEO (3 new)
- **`/orbit-seo-schema`** — Schema.org / JSON-LD audit; Google Rich Results eligibility; coexistence with Yoast / RankMath
- **`/orbit-seo-sitemap`** — XML sitemap audit; sitemap-index for 50K+ URLs; robots.txt linkage; Yoast / RankMath / WP core coexistence
- **`/orbit-seo-page-speed`** — Google PSI API integration — lab vs field (CrUX) Core Web Vitals comparison

#### Lifecycle (3 new)
- **`/orbit-life-activation`** — `register_activation_hook` safety, idempotency, multisite network-activate, defer heavy ops
- **`/orbit-life-upgrade`** — version-migration logic — every n→n+1 path covered, idempotent, batched for big tables
- **`/orbit-life-rollback`** — forward-compatible schema; what happens when a user downgrades; min_supported_version pattern

#### Hosting Compat (5 new)
- **`/orbit-host-wpengine`** — disallowed plugins, EverCache, file locks, Memcached
- **`/orbit-host-kinsta`** — Cloudflare Enterprise, Redis add-on, Quicksilver-equivalent multidev
- **`/orbit-host-cloudways`** — Breeze, Varnish, OCP, NGINX-only stack
- **`/orbit-host-shared`** — memory / time / I/O / `disable_functions` / no Redis / mod_security
- **`/orbit-host-pantheon`** — read-only filesystem (uploads only writable), Quicksilver hooks, NGINX-only

#### Plugin Compat (5 new)
- **`/orbit-compat-yoast`** — title-tag / schema / sitemap / breadcrumb / REST namespace coexistence
- **`/orbit-compat-rankmath`** — schema graph (more aggressive than Yoast), redirections coexistence
- **`/orbit-compat-wpml`** — wpml-config.xml registration, String API, language detection, URL filtering
- **`/orbit-compat-polylang`** — pll_* functions, translatable strings, free + Pro features
- **`/orbit-compat-acf`** — defensive get_field, ACF Blocks v3, JSON sync vs PHP, REST exposure

#### Payment Integration (4 new)
- **`/orbit-pay-stripe`** — keys, idempotency, webhook signatures, PaymentIntents (SCA), Stripe Elements (PCI scope), test vs live
- **`/orbit-pay-paypal`** — REST v2 (Orders + Payments), Smart Buttons, webhook signature verification, IPN deprecation, OAuth token caching
- **`/orbit-pay-edd`** — Software Licensing — license check, EDD_SL_Plugin_Updater, expiry behaviour (don't ransom)
- **`/orbit-pay-freemius`** — SDK init, opt-in flow (GDPR), opt-out preservation, telemetry disclosure, SDK version pinning

### Changed

- **`SKILLS.md`** rewritten — every skill in one table, by-category breakdown, evergreen-pattern note, severity model, output rules.
- **`README.md`** — bumped to "106 specialised skills, evergreen", new category table, EVERGREEN.md link prominent.
- **`SKILL-ROADMAP.md`** — most v2.6 candidate skills marked DONE; roadmap now lists remaining gaps + new wishlist (CCPA / HIPAA / multilingual deep / hosting tier 2).

### Migration notes from v2.5

```bash
bash ~/Claude/orbit/install.sh --update
# Re-symlinks the 61 new skills into ~/.claude/skills/orbit-*
# Restart Claude Code (Cmd+Q + reopen) to register the new commands.
# Then: /orbit-evergreen-update --check  to verify your existing 45 skills are current.
```

Existing v2.5 skills (45) are unchanged. Future versions will gradually backfill the `Sources & Evergreen References` section into them — `/orbit-evergreen-update` flags which need it.

---

## [2.5.0] — 2026-04-29 — "Claude Code-native"

Orbit reorganises into a proper **Claude Code plugin** — 45 specialised `/orbit-*` slash commands, one master dispatcher, one curl-installer, one updater, and a meta-skill so the suite keeps growing. Pickle-style organisation: install once, type `/orbit`, get to work.

### Added — 40 new skills (5 existing kept)

**Master + Setup (5)**
- **`/orbit`** — master dispatcher. Reads user intent, routes to the right `/orbit-*` skill or shows the role-based menu (Dev / QA / PM / Designer / Release Ops).
- **`/orbit-setup`** — guided onboarding wizard. Installs skills + power tools, configures `qa.config.json`, spins up wp-env, runs first audit. ~10 min end-to-end.
- **`/orbit-update`** — pulls latest Orbit + refreshes every skill symlink. Zero questions, ~20 sec. Removes deprecated entries.
- **`/orbit-install`** — one-shot installer for PHPCS, WPCS, VIP, PHPCompatibility, PHPStan, Psalm, Rector, Playwright + browsers, Lighthouse, axe-core, WP-CLI, wp-env, wp-now, source-map-explorer, PurgeCSS, claude-mem.
- **`/orbit-docker-site`** — wp-env (Docker) or wp-now setup, lifecycle commands, multi-version matrix, troubleshooting.

**Pipeline (3)**
- **`/orbit-gauntlet`** — full pipeline runner with 3 modes (quick / full / release). Documents what each of the 11 steps does, severity → release-gate mapping, sub-skill drill-down per failure layer.
- **`/orbit-release-gate`** — day-of-release sequence: preflight → metadata → release-mode gauntlet → evidence-pack HTML.
- **`/orbit-multi-plugin`** — batch-test multiple plugins in parallel with CPU throttling. Slack / Discord webhook integration.

**Code Audits (6 new + 5 existing kept)**
- **`/orbit-code-quality`** — dead code, complexity hotspots, error-handling gaps, type safety, **AI-hallucination radar** (catches Cursor/Copilot-introduced fake WP function names, wrong sanitize choices, missing nonces on AI-generated handlers — addresses Veracode's 45% AI-vuln stat).
- **`/orbit-accessibility`** — axe-core (30%) + code review for the 70% axe can't see (focus traps, screen-reader announcements, dynamic content, WCAG 3.3 forms, block editor specifics).
- **`/orbit-i18n`** — translation coverage, text-domain matching, POT freshness, locale-load hook timing, translator-friendly placeholders, RTL readiness.
- **`/orbit-pm-ux-audit`** — wraps the v2.4 spell-check + guidance score + label benchmark with HTML report.
- **`/orbit-compat-matrix`** — PHP 7.4 / 8.1 / 8.3 / 8.5 × WP 6.3 / 6.5 / latest matrix testing + modernisation opportunity report.
- **`/orbit-cve-check`** — wraps `check-live-cve.sh` + `check-ownership-transfer.sh` as a unified weekly-cron-friendly skill.

**Browser Testing (4)**
- **`/orbit-playwright`** — full Playwright workflow: setup, write specs, 5 run modes (headless / UI / headed / debug / trace viewer), CI patterns.
- **`/orbit-visual-regression`** — pixel-diff snapshots, responsive matrix (375 / 768 / 1440), 9-scheme admin colour matrix, baseline-update rules.
- **`/orbit-user-flow`** — click-depth measurement, onboarding/wizard detection, confusion scoring, analytics-event verification, GDPR consent compliance.
- **`/orbit-conflict-matrix`** — test against top 20 WP plugins (Yoast, RankMath, WC, Elementor, Jetpack, UpdraftPlus, etc.) one at a time. Configurable.

**Performance (4)**
- **`/orbit-lighthouse`** — Core Web Vitals scoring, multi-config (mobile / desktop / 4× CPU throttle), LHCI integration.
- **`/orbit-editor-perf`** — Elementor / Gutenberg editor profiling: ready time, panel populated, widget insert→render, memory growth, console error spam.
- **`/orbit-db-profile`** — query count per page, slow-query detection, N+1 patterns, autoload bloat, transient explosion, cron storm.
- **`/orbit-bundle-analysis`** — JS / CSS bundle weight, source-map-explorer treemap, PurgeCSS unused-CSS report, asset-weight regression vs previous release.

**Comparison (4)**
- **`/orbit-uat-compare`** — Plugin A vs Plugin B HTML report with PAIR-NN-slug-a/b screenshot convention, paired videos, PM analysis JSON, RICE backlog, feature comparison table.
- **`/orbit-version-compare`** — old.zip vs new.zip diff: PHPCS errors, asset weight, function adds/removes, hook adds/removes, visual baseline setup.
- **`/orbit-competitor-compare`** — auto-downloads WP.org competitors, extracts version/installs/rating/bundle/PHPCS/security signals/block.json adoption, produces strategic gap analysis.
- **`/orbit-changelog-test`** — reads CHANGELOG.md, classifies each entry (NEW FEATURE / PERFORMANCE / SECURITY / FIX / I18N / DEPRECATION), generates per-line test plan with spec paths and skill audit suggestions.

**Release (5)**
- **`/orbit-release-meta`** — plugin header validator, readme.txt (Stable tag, Tested up to, Requires PHP), version parity across 3 sources, license compliance, POT freshness, RTL readiness.
- **`/orbit-zip-hygiene`** — release-zip validator: dev-artefact detection, source-map / composer-dev-deps / forbidden-functions / supply-chain audit.
- **`/orbit-plugin-check`** — wraps the official wordpress.org `plugin-check` tool (the one their review team uses) with severity guidance.
- **`/orbit-block-json-validate`** — every block.json against current schema (apiVersion 3, name format, attribute types, supports, file refs, textdomain).
- **`/orbit-reports`** — generates the master `reports/index.html` with severity bar, tabbed audits, embedded Playwright + UAT + PM UX reports.

**WP-specific edge cases (7)**
- **`/orbit-multisite`** — network activation, super-admin caps, settings storage strategy, switch_to_blog safety, multisite uninstall pattern.
- **`/orbit-uninstall-test`** — verifies uninstall.php cleans options, transients, postmeta, usermeta, custom tables, capabilities, scheduled crons, uploads.
- **`/orbit-rest-fuzzer`** — auto-discovers `register_rest_route` calls, fuzzes each with malformed payloads / missing auth / type juggling / SQLi+XSS injection vectors.
- **`/orbit-ajax-fuzzer`** — same for `wp_ajax_*` and the dangerous `wp_ajax_nopriv_*` handlers (with rate-limit + CSRF coverage).
- **`/orbit-gdpr`** — verifies `wp_privacy_personal_data_exporters` + `wp_privacy_personal_data_erasers` registration, privacy-policy content, cookie declarations, consent-mode compliance.
- **`/orbit-cron-audit`** — wp_schedule_event hygiene: missed schedules, duplicate registrations, missing unschedule, **zombie crons** (scheduled but no handler), cron storm detection.
- **`/orbit-cache-compat`** — object cache (Redis / Memcached) compatibility, cache invalidation on writes, page-cache busting cookies, transient explosion, key namespacing.

**Meta (1)**
- **`/orbit-skill-add`** — generate new `/orbit-*` skills following the established pattern. Naming conventions, required sections, length sweet spot, install-script integration. The skill that creates skills.

### Added — Distribution

- **`install.sh`** at repo root — Pickle-style one-line installer: clones repo, symlinks 45 skills into `~/.claude/skills/orbit-*`, runs `setup/install.sh`, removes deprecated entries. Supports `--update` and `--skills-only` flags. Live updates without breaking — symlinks mean `git pull` instantly refreshes every skill.
- **`update.sh`** at repo root — explicit updater (also invocable via `/orbit-update` from Claude Code). Handles local-changes safely, refuses destructive operations, shows changelog of new commits.
- **`SKILL-ROADMAP.md`** — 60+ candidate skills organised in 10 tiers (compatibility, hosting, payment, lifecycle, REST/CLI, block editor, performance, security, SEO, plugin-store, DX, CI/CD, migration, docs). Each marked unclaimed; PR-friendly.
- **`SKILLS.md`** — completely rewritten with all 45 skills in one table, by-category breakdown, install instructions, severity model, output rules, mandatory-skill list for the gauntlet.

### Changed

- **`README.md`** — new "Install in 60 seconds" section at the top, "The 45 Orbit skills" category table, repositioned existing Quick Start as the long-form alternative. Tagline updated: "A Claude Code plugin · 45 specialised /orbit-* skills".
- **`GETTING-STARTED.md`** — install instructions now lead with the curl one-liner + `/orbit-setup` wizard. Old 5-step quick-start still documented.
- **`AGENTS.md`** — references updated to point at the new orbit-* skills (kept the v2.4 hard rules around skill deduplication).

### Removed

- **`orbit-init`** skill (renamed to `/orbit-setup` to match Pickle's pattern). The installer auto-removes the old folder on next `/orbit-update`.

### Migration notes

- If you installed Orbit before v2.5: run `bash ~/Claude/orbit/install.sh --update` once. This removes deprecated `orbit-init`, symlinks the 40 new skills into `~/.claude/skills/`, and leaves your `qa.config.json` / `reports/` / `.auth/` untouched.
- Restart Claude Code (`Cmd+Q` + reopen on macOS) so the new slash commands appear in the palette.
- Old `bash setup/init.sh` still works for per-plugin `qa.config.json` setup, but `/orbit-setup` is the new front door (handles install + config in one wizard).

---

## [2.4.0] — 2026-04-22 — "PM UX Quality"

Three new PM-perspective checks that close the gap between "does it work" and "does it feel right." All checks are **warn severity** — PMs decide, never hard-blocks.

### Added
- **`tests/playwright/pm/spell-check.spec.js`** — crawls every plugin admin page, extracts all visible UI text (labels, buttons, tooltips, notices, headings, placeholders), checks against a 60-entry built-in typo dictionary, optionally deepens with `cspell`. Output: `reports/pm-ux/spell-check-findings.json`.
- **`tests/playwright/pm/guided-ux.spec.js`** — scores the plugin's onboarding quality 0–10 across 7 signals (wizard, welcome screen, tooltips, inline help, placeholder text, empty-state messaging, help tab). Benchmarks against Yoast SEO (8/10), RankMath (9/10), WooCommerce (8/10), WPForms (9/10), Gravity Forms (8/10), Jetpack (7/10), AIOSEO (8/10). Output: `reports/pm-ux/guided-ux-score.json`.
- **`tests/playwright/pm/label-audit.spec.js`** — flags 9 anti-pattern classes (vague buttons, double negatives, WP jargon, ambiguous toggles, inconsistent save labels, ALL CAPS abuse, etc.), benchmarks terminology against `config/pm-ux/competitor-terms.json`, and checks logical ordering of select/radio option groups. Output: `reports/pm-ux/label-audit-findings.json`.
- **`config/pm-ux/competitor-terms.json`** — 10-competitor UI terminology database (Yoast SEO, RankMath, Elementor, WooCommerce, WPForms, Gravity Forms, MonsterInsights, Jetpack, ContactForm7, AIOSEO). Covers nav labels, button labels, field labels, error messages, toggle labels, section headings. Each entry lists the industry-standard term, which competitors use it, and the anti-patterns to avoid.
- **`config/pm-ux/cspell.json`** — cspell configuration with WP-ecosystem allowlist (wordpress, elementor, gutenberg, nonce, transient, wpdb, and 30+ plugin-specific terms).
- **`scripts/pm-ux-audit.sh`** — orchestrates all 3 Playwright PM specs, reads JSON outputs, prints a summary, generates the HTML report. Usage: `bash scripts/pm-ux-audit.sh [--url http://localhost:8881] [--slug plugin-slug]`.
- **`scripts/generate-pm-ux-report.py`** — Python HTML report generator, consistent with the existing `generate-uat-report.py` pattern. Three sections (spell-check, guided UX, label audit), color-coded summary cards, competitor comparison table.
- **Gauntlet Step 12** — `scripts/gauntlet.sh` now runs the PM UX Audit as Step 12 in `full` + `local` mode. Exits 0 (issues are PM-flagged warnings, not CI failures).
- **`VISION.md`** updated with PM UX Quality row in the coverage matrix.

---

## [2.3.0] — 2026-04-21 — "Unique Layer"

First two capabilities nobody else ships. Both are **free forever** — uses NVD + WPScan public feeds, no API keys, no paid tier.

### Added
- **`scripts/check-ownership-transfer.sh`** — reads plugin main-file git history, flags when Author / Author URI / Plugin Name headers change between commits. Defends against the April 2026 EssentialPlugin attack vector (attacker buys plugin → pushes backdoored update weeks later). First static detection in the WP ecosystem.
- **`scripts/check-live-cve.sh`** — pulls NVD (NIST National Vulnerability Database) + WPScan public feeds for last 60 days of WordPress CVEs, correlates against plugin code. Caches 24h. Optional `WPSCAN_API_TOKEN` for higher-rate auth. Turns Orbit from release-time tool into continuous security posture tool.
- Both scripts wired into gauntlet release mode (`--mode full|release`).

### Verified
- `check-live-cve.sh` self-tested: 100 recent WP CVEs ingested, correctly correlated 5 deliberate vulns in test plugin (XSS, SQLi, nopriv AJAX, unserialize, missing nonce) with real CVE matches.
- `check-ownership-transfer.sh` self-tested: correctly skipped on non-plugin repos, flags Author/URI/Name header drift across git history.

---

## [2.2.0] — 2026-04-21 — "Mature Release"

The release where Orbit closes every deep-research gap. Covers WP.org
plugin-check canonical rules, Patchstack 2025 top-5 vuln classes, WP 6.5→7.0
features, PHP 8.0→8.5 compatibility, and the April 2026 EssentialPlugin
supply-chain attack patterns.

### Added — Foundation
- `VISION.md` — anchor doc with 6 perspectives (Dev/QA/PM/PA/Designer/End User), 7 smart principles, evergreen research loop
- `docs/22-what-orbit-does.md` — shareable overview
- `docs/21-evergreen-security.md` — living attack-pattern log, 90-day research cadence (SHIPPED / RESEARCHING / WATCHING)
- `docs/20-auto-test-generation.md` — how Orbit reads plugin code
- `docs/19-business-logic-guide.md` — plugin-specific testing on top of Orbit
- `docs/18-release-checklist.md` — complete pre-tag gate for all 6 roles
- `docs/17-whats-new.md` — v2 demo doc
- `docs/16-master-audit.md` — master audit + antigravity skill mappings
- `.github/workflows/ci.yml` — lean self-validation workflow + brand-leakage enforcement
- `.githooks/pre-commit` + `install-pre-commit-hook.sh`

### Added — Release gate checks (9 new scripts)
- `check-plugin-header.sh` · `check-readme-txt.sh` · `check-version-parity.sh`
- `check-license.sh` · `check-block-json.sh` · `check-hpos-declaration.sh`
- `check-wp-compat.sh` — WP function version gate against declared "Requires at least"
- `check-php-compat.sh` — PHP 8.0-8.5: removed functions, implicit nullable, property hooks, `array_find` family, `mb_trim`, E_STRICT removal
- `check-modern-wp.sh` — Script Modules, Interactivity API, Plugin Dependencies, Site Health, Block Bindings, custom updater detection, external menu links

### Added — Dev workflow
- `scaffold-tests.sh` — reads plugin code, generates `qa.config.json` + 40-80 scenarios + draft spec
- `gauntlet-dry-run.sh` · `generate-reports-index.py`
- `/orbit-scaffold-tests` custom skill — AI-augmented scenario writer (via `--deep`)

### Added — Playwright projects (14 new specs)
- UX states: `empty-states` · `error-states` · `loading-states` · `form-validation`
- Lifecycle: `uninstall-cleanup` · `update-path` · `block-deprecation`
- Accessibility: `keyboard-nav` · `admin-color-schemes` · `rtl-layout`
- Network: `multisite-activation` · `app-passwords`
- Modern: `wp7-connectors` · `plugin-conflict` (top-20 matrix)
- PM/PA: `user-journey` · `onboarding-ftue` · `analytics-events`
- Visual: `visual-regression-release` (diff vs previous git tag)
- Performance: `bundle-size` (per-page JS/CSS enforcement)
- Cross-browser projects: `firefox` · `webkit`

### Added — Custom Claude skills (4 WP-native)
- `/orbit-wp-security` — **22 vulnerability patterns** (+5 for April 2026):
  - #18 `unserialize()` on HTTP responses (EssentialPlugin attack)
  - #19 `permission_callback => __return_true` on sensitive routes
  - #20 `register_setting()` missing `sanitize_callback`
  - #21 callable property injection gadget chain
  - #22 external admin menu URLs
- `/orbit-wp-performance` — 14 patterns (+script loading strategy, Script Modules dynamic deps, block metadata bulk registration, per-page CSS weight)
- `/orbit-wp-database` — `$wpdb`, dbDelta, autoload, uninstall cleanup
- `/orbit-wp-standards` — review-mode WP coding standards
- `deep-research` skill — rewritten Claude-native (WebSearch + WebFetch)

### Changed
- Replaced 4 mismatched community skills in AGENTS.md:
  - `/wordpress-penetration-testing` (attacker tool) → `/security-auditor` + `/security-scanning-security-sast`
  - `/performance-engineer` (cloud infra) → `/orbit-wp-performance` + `/web-performance-optimization`
  - `/database-optimizer` (enterprise DBA) → `/orbit-wp-database`
  - `/wordpress-plugin-development` (scaffolder) → `/orbit-wp-standards`
- Gauntlet Step 11: per-PID `wait` loop + per-skill `.err` file (was silent failure on Claude CLI errors)
- `check-zip-hygiene.sh` expanded: AI dev dirs (`.cursor`, `.aider`, `.continue`, `.claude`, `.windsurf`, `.codex`, `.fleet`, `.zed`, `.github/copilot-*`), OS artifacts, editor backups, obfuscation (hex + `chr()` chains), `ALLOW_UNFILTERED_UPLOADS`
- Gauntlet: new release gate wiring for all 9 release-metadata checks

### Removed
- `.github/workflows/gauntlet.yml` — overbuilt for the framework repo itself; full gauntlet workflow now lives as a copy-paste template in `docs/15-ci-cd.md` for users' plugin repos

### Fixed (identified by 3-agent review + self-testing)
- Orphaned `/orbit-wp-security` skill — AGENTS.md referenced it, gauntlet.sh invoked `/security-auditor` instead
- `wait $P1 $P2 ...` returning only last PID's status → multiple failures reported as success
- `2>/dev/null` swallowing Claude CLI errors
- `check-translation.sh` / `check-object-cache.sh` / `check-zip-hygiene.sh` — empty-var arithmetic crash under `set -e` (`grep -c \|\| echo 0` producing `"0\n0"`)
- `uninstall-cleanup.spec.js` — wp-cli `--search` uses `*` glob, not `%` SQL wildcard (was: test always passed)
- `keyboard-nav.spec.js` — focus-indicator check always-true no-op (`style.border !== 'none'`)
- `plugin-conflict.spec.js` — debug.log path was host path; fixed to use `WP_CONTENT_DIR` inside container
- `wp7-connectors.spec.js` — rewritten against real WP 7.0 API (`WP_Ability` class + `abilities_api_init` + `wp_execute_ability`) — previous version invented fake functions and always skipped (false green)
- `scaffold-tests.sh` — same `grep -c` anti-pattern + Python boolean heredoc fixes
- `base64_decode` / `base64_encode` moved from hard-fail to WARN (WP core uses these legitimately)
- `deep-research` skill — no longer requires external Gemini API / Python dependency

### Security
- **Evergreen research loop established.** `docs/21-evergreen-security.md` is the living record. Next quarterly pass: July 2026.

---

## [2.1.0] — 2026-04-20

### Fixed (Critical — brand content in public repo)
- `setup/playground-blueprint.json` — replaced "POSIMYTH QA Test Site" with "Orbit QA Test Site" (C-01)
- `checklists/pre-release-checklist.md` — removed product-specific brand names; checklist is now generic for any WordPress plugin (C-02)
- `checklists/ui-ux-checklist.md` — removed "TPA" and "NexterWP" section headings; sections are now generic Elementor / Gutenberg (C-02)
- `scripts/gauntlet.sh` — removed hardcoded `NEXTER-VS-RANKMATH-UAT.html` reference; output now globs any `uat-report-*.html` (C-04)

### Fixed (High priority)
- `scripts/generate-uat-report.py` — `FLOW_DATA`, `RICE`, and `FEATURES` are now empty by default; all plugin-specific PM data must be supplied via the new `--flow-data <file.json>` argument (C-03 / H)
- `package.json` — replaced macOS-only `open` in `npm run uat` with cross-platform `npx open-cli` (H-01)
- `scripts/generate-uat-report.py` — `scan_pairs()` regex fixed from `(?:-\w+)?` to `(?:-[\w-]+)?` so extras with hyphens (e.g. `pair-01-dashboard-a-scroll-down.png`) are matched correctly (H-03)
- `tests/playwright/helpers.js` — `gotoAdmin()` now uses `waitForLoadState('networkidle')` + 800ms buffer instead of a fixed 2500ms `waitForTimeout` (H-04)
- `tests/playwright/helpers.js` — moved `require('path')` and `require('fs')` from mid-file to the top of the module (H-07)

### Removed
- `scripts/generate-uat-report.sh` — redundant shell wrapper around the Python script; use `python3 scripts/generate-uat-report.py` directly or `npm run uat` (H-06)

### Added
- `qa.config.example.json` — documented config schema with comments; copy to `qa.config.json` (gitignored) and fill in your plugin details (H-02)
- `setup/plugins/plugin-example.setup.json` — template for per-plugin setup files used by `setup/plugin-setup.js`
- `scripts/generate-uat-report.py --flow-data` — new CLI argument pointing to a JSON file containing `FLOW_DATA`, `RICE`, `FEATURES`, and `IA_RECS` for a specific plugin comparison

---

## [2.0.0] — 2026-04-19

### Added
- **PAIR-NN-slug-a/b naming convention** — screenshots and videos are now named `pair-NN-{slug}-{a|b}[-extra].{ext}`. The slug is the pairing key, not the index. Eliminates the index-mismatch bug where Social was shown beside Titles in the UAT report.
- `snapPair(page, pairNum, slug, side, snapDir, extra)` helper in `helpers.js` — enforces the naming contract at capture time.
- `scan_pairs()` in `generate-uat-report.py` — pairs screenshots/videos by slug instead of sequential index. Replaces the old `grp()` function.
- `afterEach` video auto-renaming hook in `tests/playwright/templates/seo-plugin/core.spec.js` — parses test title format `"PAIR-N | slug | a|b | Description"` and copies Playwright's auto-generated video to the correct `pair-NN-slug-a/b.webm` name.
- `--label-a` / `--label-b` CLI args for `generate-uat-report.py` — plugin display names are now configurable from the command line.
- `scripts/gauntlet.sh` Step 6b — auto-detects `tests/playwright/flows/*.spec.js` and runs them with `--project=video`, then calls `generate-uat-report.py`.
- `npm run uat` and `npm run uat:ci` scripts in `package.json`.
- Deep PM HTML report (`generate-uat-report.py`) with per-flow analysis, RICE backlog, IA navigation recommendations, and feature comparison table.

### Changed
- `generate-uat-report.py` rewritten to use `scan_pairs()` slug-based matching.
- `core.spec.js` template rewritten with full PAIR structure and video auto-renaming.

---

## [1.0.0] — 2026-04-17

### Added
- Initial Orbit framework: `gauntlet.sh`, Playwright setup, `helpers.js`, checklists, report generator.
