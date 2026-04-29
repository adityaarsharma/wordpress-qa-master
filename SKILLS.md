# Orbit — Skills Reference

> **115 specialised `/orbit-*` Claude Code skills** for WordPress plugin QA.
> Every skill is **runtime-evergreen** — fetches its canonical sources at runtime,
> derives current rules from today's docs, and cites the live URL + fetch timestamp
> in every finding. No quarterly maintenance. The skill stays current automatically.
>
> Type `/orbit-do-it <plugin-path>` for the brainless one-command audit.
> Or `/orbit` for the master menu.

**Repo:** https://github.com/adityaarsharma/orbit
**Author:** [Aditya Sharma](https://github.com/adityaarsharma) · POSIMYTH Innovation
**Whitepaper / runtime-evergreen pattern:** [EVERGREEN.md](EVERGREEN.md)
**How to add a new skill:** [skills/orbit-skill-add/SKILL.md](skills/orbit-skill-add/SKILL.md)
**How to keep skills current:** [skills/orbit-skill-improver/SKILL.md](skills/orbit-skill-improver/SKILL.md)

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash
```

After install, restart Claude Code (`Cmd+Q` and reopen on macOS) so the slash commands appear in the palette. Then type `/orbit` for the master menu, or `/orbit-setup` to onboard your first plugin.

---

## What "evergreen" means

Every skill links to canonical sources — WP Plugin Handbook, Block Editor Handbook, MDN, OWASP, schema.org, Stripe / PayPal docs, etc. — and instructs Claude to fetch them on every audit. Rules in any SKILL.md are a starting point; the canonical doc is always source-of-truth.

To audit drift across the suite (quarterly recommended): `/orbit-evergreen-update`.

Full pattern: [EVERGREEN.md](EVERGREEN.md).

---

## All 106 skills, by category

### 🛠 Setup & Environment (6)
| Skill | What it does |
|---|---|
| `/orbit-setup` | Guided onboarding wizard — installs everything, configures first plugin, runs first audit |
| `/orbit-update` | Pull latest Orbit + refresh skill symlinks. Zero questions. |
| `/orbit-install` | Power-tools installer (PHPCS, Playwright, Lighthouse, WP-CLI, etc.) |
| `/orbit-docker-site` | wp-env / wp-now setup; troubleshooting |
| `/orbit-wp-playground` | **Wraps WordPress/agent-skills (Brandon Payton's wp-playground; WP core official)** |
| `/orbit-pre-commit` | Git pre-commit hook — blocks `var_dump`, `console.log DEBUG`, etc. (<10s) |

### 🏃 Pipeline (3)
| Skill | What it does |
|---|---|
| `/orbit-gauntlet` | Full 11-step audit (modes: quick / full / release) |
| `/orbit-release-gate` | Day-of-release sequence — preflight → metadata → gauntlet → evidence pack |
| `/orbit-multi-plugin` | Batch-test multiple plugins in parallel |

### 🌐 Master + Meta (4)
| Skill | What it does |
|---|---|
| `/orbit` | Master dispatcher — routes user intent to the right skill, role-based menu |
| **`/orbit-do-it`** | **Brainless orchestrator — one command, audits everything, opens report** |
| `/orbit-skill-add` | Generate new `/orbit-*` skills following the established pattern |
| `/orbit-skill-improver` | Action-mode meta — fetches live sources, edits stale skills, opens PRs |

### 🔍 Code Audits — General (6)
| Skill | What it does |
|---|---|
| `/orbit-wp-standards` | WP coding standards — naming, escaping, nonces, capabilities, i18n |
| `/orbit-wp-security` | XSS / CSRF / SQLi / auth bypass / path traversal in source |
| `/orbit-wp-performance` | Hook weight, N+1 DB calls, transient misuse, blocking assets |
| `/orbit-wp-database` | $wpdb, autoload bloat, missing indexes, uninstall cleanup |
| `/orbit-scaffold-tests` | Read code → 70+ business-logic test scenarios |
| `/orbit-code-quality` | Dead code, complexity, **AI-hallucination radar** (Veracode 45% stat) |

### 🔍 Code Audits — Specialised (8) — **incl. v2.7 additions**
| Skill | What it does |
|---|---|
| `/orbit-accessibility` | WCAG 2.2 AA on admin UI + frontend output |
| `/orbit-i18n` | Translation strings, text domain, POT freshness, RTL |
| `/orbit-pm-ux-audit` | Spell-check + guided UX score + label benchmark |
| `/orbit-compat-matrix` | PHP 7.4 / 8.1 / 8.3 / 8.5 × WP 6.3 / 6.5 / latest matrix |
| `/orbit-cve-check` | **Runtime-evergreen — fetches NVD + Patchstack + WPScan + GitHub Advisory live** |
| `/orbit-abilities-api` | **WP 7.0 Abilities API + AI Client API audit** |
| `/orbit-rtc-compat` | **WP 7.0 Real-Time Collaboration compat — meta-box → register_post_meta** |
| `/orbit-broken-access-control` | **OWASP A01 deep audit — Patchstack's 57% top attack class** |

### 🧱 Gutenberg / Block Editor Dev (8) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-gutenberg-dev` | Block dev workflow — apiVersion, render.php, supports, textdomain |
| `/orbit-block-render-test` | Server-side render coverage + scaffolder |
| `/orbit-block-edit-test` | Editor-time UX coverage (InspectorControls, transforms) |
| `/orbit-block-patterns` | Block patterns — registration, `viewportWidth`, synced patterns |
| `/orbit-fse-test` | Full-Site-Editing — theme.json schema 3, templates, style variations |
| `/orbit-block-bindings` | Block Bindings API (WP 6.5+) — modern data-source binding |
| `/orbit-interactivity-api` | Interactivity API — modern client-side block behaviour |
| `/orbit-block-variations` | Block variations + transforms — vs separate blocks |

### 🎨 Elementor Dev (6) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-elementor-dev` | Widget_Base subclass + register_controls + render escaping |
| `/orbit-elementor-controls` | Built-in control coverage + Custom Control_Base |
| `/orbit-elementor-compat` | Across Elementor versions (3.18 / 3.20 / 3.22 / latest) |
| `/orbit-elementor-pro` | Pro extensions — Form Actions, Display Conditions, Theme Builder |
| `/orbit-elementor-skins` | Skin_Base — widget variations |
| `/orbit-elementor-dynamic-tags` | Dynamic Tags — server-side data sources |

### 🌐 Browser Testing (4)
| Skill | What it does |
|---|---|
| `/orbit-playwright` | Setup / write / run / debug E2E |
| `/orbit-visual-regression` | Pixel-diff snapshots + responsive + admin colours |
| `/orbit-user-flow` | Click depth + onboarding + analytics-event verification |
| `/orbit-conflict-matrix` | Test against top 20 WP plugins one at a time |

### 🧪 UAT Templates (6) — incl. **v2.7 brainless agent**
| Skill | What it does |
|---|---|
| **`/orbit-uat-agent`** | **Stagehand-style natural-language UAT — write tests in English, no selectors** |
| `/orbit-uat-elementor` | Elementor addon UAT — drag → configure → save → frontend |
| `/orbit-uat-gutenberg` | Block plugin UAT — uses `@wordpress/e2e-test-utils-playwright` |
| `/orbit-uat-woo` | WooCommerce extension UAT — incl. HPOS + Block Checkout |
| `/orbit-uat-forms` | Form plugin UAT — validation, anti-spam, GDPR consent |
| `/orbit-uat-membership` | LMS / membership UAT — paywall, drip, certificate, billing |

### 🧪 QA Specialised (5) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-qa-flaky-detector` | Run tests N times, rank by pass-rate, suggest root causes |
| `/orbit-qa-mutation` | Infection PHP — measures TEST quality, not code quality |
| `/orbit-qa-coverage` | PHPUnit + Xdebug / pcov line + branch coverage |
| `/orbit-qa-snapshot-cleanup` | Find orphan / stale Playwright PNGs |
| `/orbit-qa-regression-pack` | Manage `@regression`-tagged tests; coverage rate |

### 📊 PM Specialised (5) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-pm-rice` | RICE-scored backlog from any audit's findings |
| `/orbit-pm-release-notes` | Auto-draft release notes (blog / email / readme.txt / social) |
| `/orbit-pm-feedback-mining` | Mine WP.org reviews + forum into themed action items |
| `/orbit-pm-roadmap` | Quarterly roadmap from RICE + feedback + competitor gaps |
| `/orbit-pm-competitor-pulse` | Monthly competitor cadence / bundle / rating tracker |

### 🎨 Designer Specialised (5) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-designer-tokens` | Color palette + typography + spacing + radius + shadow tokens |
| `/orbit-designer-empty-error` | Empty-state + error-state coverage |
| `/orbit-designer-icons` | Icon system — library inventory, accessibility, consistency |
| `/orbit-designer-rtl` | RTL layout — logical properties vs hardcoded directional |
| `/orbit-designer-dark-mode` | WP admin colour schemes + `prefers-color-scheme` + contrast |

### ⚡ Performance (7)
| Skill | What it does |
|---|---|
| `/orbit-lighthouse` | Core Web Vitals (LCP / FCP / TBT / CLS / TTI) |
| `/orbit-editor-perf` | Elementor / Gutenberg editor ready time + widget timing |
| `/orbit-db-profile` | Query count, slow queries, N+1, autoload bloat |
| `/orbit-bundle-analysis` | JS / CSS bundle weight + source-map-explorer + PurgeCSS |
| `/orbit-perf-stress-test` | k6 / JMeter — concurrent users, p95/p99 latency — **NEW v2.6** |
| `/orbit-perf-memory-leak` | Detect linear memory growth across requests — **NEW v2.6** |
| `/orbit-perf-cdn` | Cloudflare / BunnyCDN / KeyCDN compatibility — **NEW v2.6** |

### 🆚 Comparison (4)
| Skill | What it does |
|---|---|
| `/orbit-uat-compare` | Plugin A vs Plugin B HTML report with paired screenshots + videos |
| `/orbit-version-compare` | Old version vs new version diff |
| `/orbit-competitor-compare` | Vs WP.org competitors (version, bundle, code quality) |
| `/orbit-changelog-test` | Map every changelog entry → targeted test |

### 📦 Release Metadata (5)
| Skill | What it does |
|---|---|
| `/orbit-release-meta` | Plugin header + readme.txt + version parity + license + POT |
| `/orbit-zip-hygiene` | Validate the release zip (no .git, no source maps, no dev deps) |
| `/orbit-plugin-check` | Run wordpress.org's official plugin-check tool |
| `/orbit-block-json-validate` | Every block.json against current WP schema |
| `/orbit-reports` | Generate master HTML index across every report |

### 🔬 WP-Specific Edge Cases (7)
| Skill | What it does |
|---|---|
| `/orbit-multisite` | Network activation, super-admin caps, switch_to_blog safety |
| `/orbit-uninstall-test` | Verify uninstall.php cleans options / postmeta / tables / crons |
| `/orbit-rest-fuzzer` | Auto-discover register_rest_route + fuzz |
| `/orbit-ajax-fuzzer` | wp_ajax_* / wp_ajax_nopriv_* fuzzing |
| `/orbit-gdpr` | wp_privacy_personal_data_exporters + erasers |
| `/orbit-cron-audit` | wp_schedule_event hygiene + zombie cron detection |
| `/orbit-cache-compat` | Object cache (Redis) + page cache (WP Rocket / EverCache) |

### 🔄 Lifecycle (3) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-life-activation` | register_activation_hook safety + idempotency |
| `/orbit-life-upgrade` | Version-migration logic — every n→n+1 path covered |
| `/orbit-life-rollback` | Forward-compatible schema; what happens when user downgrades |

### 🏠 Hosting Compat (5) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-host-wpengine` | WP Engine — disallowed plugins, EverCache, file locks |
| `/orbit-host-kinsta` | Kinsta — Cloudflare Enterprise edge, Redis add-on |
| `/orbit-host-cloudways` | Cloudways — Breeze, Varnish, Object Cache Pro |
| `/orbit-host-shared` | Shared hosting — memory / time / I/O / disable_functions |
| `/orbit-host-pantheon` | Pantheon — read-only filesystem, multidev, Quicksilver |

### 🔌 Plugin Compat (5) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-compat-yoast` | Yoast SEO coexistence — title / schema / sitemap / breadcrumb |
| `/orbit-compat-rankmath` | RankMath SEO coexistence (more aggressive defaults than Yoast) |
| `/orbit-compat-wpml` | WPML — wpml-config.xml, string registration, language detection |
| `/orbit-compat-polylang` | Polylang — pll_* functions, free + Pro features |
| `/orbit-compat-acf` | ACF — get_field defensive use, ACF Blocks, JSON sync |

### 🇪🇺 Compliance + Premium (2) — **NEW v2.7**
| Skill | What it does |
|---|---|
| `/orbit-vdp` | EU Cyber Resilience Act mandate — VDP / SECURITY.md / security.txt / SLA |
| `/orbit-premium-audit` | Stricter audit for Pro plugins — Patchstack found 76% premium vulns exploitable |

### 💳 Payment Integration (4) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-pay-stripe` | Stripe — keys, idempotency, webhook signatures, PaymentIntents, SCA |
| `/orbit-pay-paypal` | PayPal — Smart Buttons, REST v2, webhook verification, IPN deprecation |
| `/orbit-pay-edd` | EDD Software Licensing — license check, plugin updater, expiry behaviour |
| `/orbit-pay-freemius` | Freemius SDK — opt-in, GDPR disclosure, opt-out preservation |

### 🔒 Security Specialised (3) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-sec-xss-active` | Active XSS probing — DOM / reflected / stored payloads |
| `/orbit-sec-supply-chain` | Composer + npm CVE + license + abandoned-package audit |
| `/orbit-sec-secrets-leak` | Hardcoded secrets in source / git history (gitleaks-style) |

### 📈 SEO (3) — **NEW v2.6**
| Skill | What it does |
|---|---|
| `/orbit-seo-schema` | Schema.org / JSON-LD — required fields, Yoast/RankMath coexistence |
| `/orbit-seo-sitemap` | XML sitemap — well-formed, sitemap-index, robots.txt linkage |
| `/orbit-seo-page-speed` | Google PSI API — lab vs field (CrUX) Core Web Vitals |

---

## Mandatory skills for `/orbit-gauntlet --mode full`

The 6 parallel AI audits in Step 11:

1. `/orbit-wp-standards`
2. `/orbit-wp-security`
3. `/orbit-wp-performance`
4. `/orbit-wp-database`
5. `/orbit-accessibility`
6. `/orbit-code-quality`

---

## Severity model (applied to every skill)

| Level | Action before release |
|---|---|
| **Critical** | Block release. Fix immediately. |
| **High** | Block release. Fix in this PR. |
| **Medium** | Fix if under 30 min. Otherwise log and defer. |
| **Low / Info** | Log in tech debt. Defer. |

---

## How to add a new skill

```
/orbit-skill-add
```

Or read the manual: [skills/orbit-skill-add/SKILL.md](skills/orbit-skill-add/SKILL.md). Naming pattern: `/orbit-<thing>` / `-test` / `-fuzzer` / `-compat` / `-validate` / `-audit`.

---

## Output rules

Every skill writes to `reports/` — never terminal-only. Master HTML index via `/orbit-reports`.

| Skill type | Output | Location |
|---|---|---|
| Code audits | Markdown | `reports/skill-audits/<skill>.md` |
| Playwright | HTML reporter | `reports/playwright-html/index.html` |
| Gauntlet | Master markdown | `reports/qa-report-<timestamp>.md` |
| UAT compare | HTML + paired media | `reports/uat-report-<timestamp>.html` |
| Lighthouse | JSON + summary | `reports/lighthouse/lh-<timestamp>.json` |
| DB profile | Text | `reports/db-profile-<timestamp>.txt` |
| PM UX | HTML | `reports/pm-ux/pm-ux-report-<timestamp>.html` |
| Master index | HTML linking to all | `reports/index.html` |

---

## The evergreen guarantee

Every Orbit skill must include a **`Sources & Evergreen References`** section near the bottom — canonical doc URLs, rule lineage (what rule was added in which release), and a `Last reviewed` date. This is enforced — `/orbit-skill-add` won't scaffold without these sections.

To check the entire suite for drift quarterly: `/orbit-evergreen-update`.

Full pattern + philosophy: [EVERGREEN.md](EVERGREEN.md).

---

## Built by

**[Aditya Sharma](https://adityaarsharma.com)** · POSIMYTH Innovation
github.com/adityaarsharma/orbit
