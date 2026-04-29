<div align="center">

# 🪐 Orbit

### **Complete UAT for WordPress Plugins**

*A Claude Code plugin · **115 runtime-evergreen `/orbit-*` skills** · Dev → QA → PM → Designer → End User · **fetches live canonical sources on every run** (skills are never snapshots)*

**Brainless one-command audit:** `/orbit-do-it ~/plugins/my-plugin` — auto-detects plugin type, runs the right audit + UAT pipeline, opens report.

**👉 [Get started in 60 seconds](#install-in-60-seconds) — one curl command + a wizard**

<br />

![PHP](https://img.shields.io/badge/PHP-7.4%20→%208.5-777BB4?style=for-the-badge&logo=php&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-6.3%20→%20Latest-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![Playwright](https://img.shields.io/badge/Playwright-E2E-2EAD33?style=for-the-badge&logo=playwright&logoColor=white)
![Lighthouse](https://img.shields.io/badge/Lighthouse-Performance-F44B21?style=for-the-badge&logo=lighthouse&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude%20Code-45%20Skills-CC785C?style=for-the-badge)

<br />

**👨‍💻 Dev** → zero-regression releases &nbsp;·&nbsp; **🧪 QA** → structured test coverage &nbsp;·&nbsp; **📊 PM** → flow maps + complexity scores &nbsp;·&nbsp; **📈 PA** → analytics events verified &nbsp;·&nbsp; **🎨 Designer** → visual diffs + UI audits &nbsp;·&nbsp; **👤 End User** → real browser, real flows

📖 **[VISION.md](VISION.md)** &nbsp;·&nbsp; 🚀 **[Skills Reference (45 skills)](SKILLS.md)** &nbsp;·&nbsp; 🛣 **[Roadmap (60+ more)](SKILL-ROADMAP.md)** &nbsp;·&nbsp; 🛡️ **[Evergreen Security](docs/21-evergreen-security.md)**

---

**v2.7.0 · April 2026 · Runtime-Evergreen + Brainless Agent** — **115 specialised `/orbit-*` skills**, each one **runtime-evergreen**: when invoked, the skill fetches its canonical sources (WP make blog, Elementor changelog, Stripe docs, NVD/Patchstack/WPScan feeds, etc.) and derives current rules from today's docs — not from a snapshot taken when the SKILL.md was written. Findings cite the live URL + fetch timestamp. The skills handle Elementor V4, V5 (when it ships), WP 7.0, WP 7.5 (when it ships) without anyone editing the SKILL.md.

Plus **`/orbit-do-it`** — the brainless team agent. One command, walks away, comes back to a verdict.

Plus **`/orbit-uat-agent`** — Stagehand-style natural-language UAT (no selectors, no specs to write).

Plus **wraps `WordPress/agent-skills`** (WP core's official agent skills, Jan 2026) via the installer — `npx openskills install WordPress/agent-skills` runs alongside Orbit. Don't reinvent; compose.

See [EVERGREEN.md](EVERGREEN.md) for the runtime-evergreen pattern + whitepaper philosophy.

🎯 **[Use Cases](docs/24-use-cases.md)** (25 real scenarios · Dev/QA/PM/PA/Designer/Release-Ops) &nbsp;·&nbsp; 🧩 **[Extending Orbit](docs/23-extending-orbit.md)** (how to add checks, write specs, create skills)

Covers **Elementor Addons · Gutenberg Blocks · SEO Plugins · WooCommerce Extensions · Themes**

<br />

[Install in 60s](#install-in-60-seconds) · [Skills (45)](#the-45-orbit-skills) · [What It Checks](#what-it-checks) · [**Role Guide**](docs/onboarding-by-role.md) · [Skills Reference](SKILLS.md) · [Roadmap](SKILL-ROADMAP.md) · [GitHub](https://github.com/adityaarsharma/orbit)

</div>

---

## Install in 60 seconds

Orbit is a **Claude Code plugin** — 45 `/orbit-*` slash commands you can invoke from any Claude Code session.

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash
```

That's it. The installer:
1. Clones Orbit to `~/Claude/orbit`
2. Symlinks 45 skills into `~/.claude/skills/orbit-*` (so `/orbit-*` autocompletes in Claude Code)
3. Runs `setup/install.sh` — installs PHPCS, WPCS, PHPStan, Playwright + browsers, Lighthouse, axe-core, WP-CLI, wp-env, wp-now, source-map-explorer, PurgeCSS
4. Prints what's next

**After install:** fully quit Claude Code (`Cmd+Q` on macOS), reopen, type `/orbit` — the master menu appears.

### Update later

```bash
# In Claude Code:
/orbit-update

# Or via shell:
bash ~/Claude/orbit/update.sh
```

Pulls the latest from GitHub, refreshes every skill in place, removes deprecated entries. Zero questions, ~20 seconds.

### From a clone (offline-capable)

```bash
git clone https://github.com/adityaarsharma/orbit ~/Claude/orbit
cd ~/Claude/orbit && bash install.sh
```

### Configure your first plugin

Once installed, fire up the wizard:

```
/orbit-setup
```

It walks you through plugin path, type (Elementor / Gutenberg / SEO / WooCommerce / Theme), competitors, visual baseline URLs, default mode — then spins up a wp-env Docker site and runs your first audit. ~10 minutes end-to-end.

---

## The 106 Orbit skills

| Category | Count | Examples |
|---|---|---|
| Master + Setup | 5 | `/orbit` `/orbit-setup` `/orbit-install` `/orbit-update` `/orbit-docker-site` |
| Pipeline | 3 | `/orbit-gauntlet` `/orbit-release-gate` `/orbit-multi-plugin` |
| Code Audits | 11 | `/orbit-wp-{standards,security,performance,database}` `/orbit-{accessibility,i18n,code-quality,pm-ux-audit,compat-matrix,cve-check,scaffold-tests}` |
| **Gutenberg / Block Editor Dev** | 8 | `/orbit-gutenberg-dev` `/orbit-block-{render-test,edit-test,patterns,bindings,variations}` `/orbit-fse-test` `/orbit-interactivity-api` |
| **Elementor Dev** | 6 | `/orbit-elementor-{dev,controls,compat,pro,skins,dynamic-tags}` |
| Browser Testing | 4 | `/orbit-playwright` `/orbit-visual-regression` `/orbit-user-flow` `/orbit-conflict-matrix` |
| **UAT Templates** | 5 | `/orbit-uat-{elementor,gutenberg,woo,forms,membership}` |
| **QA Specialised** | 5 | `/orbit-qa-{flaky-detector,mutation,coverage,snapshot-cleanup,regression-pack}` |
| **PM Specialised** | 5 | `/orbit-pm-{rice,release-notes,feedback-mining,roadmap,competitor-pulse}` |
| **Designer Specialised** | 5 | `/orbit-designer-{tokens,empty-error,icons,rtl,dark-mode}` |
| Performance | 7 | `/orbit-{lighthouse,editor-perf,db-profile,bundle-analysis}` `/orbit-perf-{stress-test,memory-leak,cdn}` |
| Comparison | 4 | `/orbit-{uat,version,competitor}-compare` `/orbit-changelog-test` |
| Release | 5 | `/orbit-{release-meta,zip-hygiene,plugin-check,block-json-validate,reports}` |
| WP-specific edge cases | 7 | `/orbit-{multisite,uninstall-test,gdpr,cron-audit,cache-compat,rest-fuzzer,ajax-fuzzer}` |
| **Lifecycle** | 3 | `/orbit-life-{activation,upgrade,rollback}` |
| **Hosting Compat** | 5 | `/orbit-host-{wpengine,kinsta,cloudways,shared,pantheon}` |
| **Plugin Compat** | 5 | `/orbit-compat-{yoast,rankmath,wpml,polylang,acf}` |
| **Payment Integration** | 4 | `/orbit-pay-{stripe,paypal,edd,freemius}` |
| **Security Specialised** | 3 | `/orbit-sec-{xss-active,supply-chain,secrets-leak}` |
| **SEO** | 3 | `/orbit-seo-{schema,sitemap,page-speed}` |
| Other / Meta | 3 | `/orbit-pre-commit` `/orbit-skill-add` `/orbit-evergreen-update` |

**👉 [Full skill reference with trigger phrases + descriptions](SKILLS.md)**
**👉 [Runtime-evergreen pattern (whitepaper)](EVERGREEN.md)**
**👉 [How to add new skills](skills/orbit-skill-add/SKILL.md)** + **[How to keep skills current](skills/orbit-skill-improver/SKILL.md)**

---

---

## The Pitch — What This Actually Is

**Orbit is a UAT platform for WordPress plugins.** Not just code checks — every angle a plugin gets judged from before users touch it: code quality, visual correctness, UX flow depth, PM-level complexity scoring, responsive behavior, and real competitor context.

One command and you get:

- ✅ Real WordPress + real MySQL running in Docker (fully scripted, no GUI clicks)
- ✅ PHP lint + WordPress Coding Standards + VIP + PHPStan (catches bugs before they run)
- ✅ Playwright E2E tests + visual regression + a11y (catches bugs before users see them)
- ✅ Lighthouse + custom perf harness for Elementor/Gutenberg editor (catches slow code)
- ✅ DB query profiling with Query Monitor + `performance_schema` (catches N+1s)
- ✅ Competitor analysis from wordpress.org (catches when you fall behind)
- ✅ Claude Code skill integration — 30+ `/slash` commands for AI-assisted audit (catches what humans miss)
- ✅ PM flow mapping — click-depth, wizard detection, complexity scoring per feature vs competitors
- ✅ **PM UX Audit** — spell-check all UI text + guided experience score (0–10) + label benchmarking vs Yoast, RankMath, WooCommerce, WPForms and 6 more
- ✅ Designer layer — pixel-diff visual regression across admin, editor, and frontend at every viewport
- ✅ Mass parallel mode — test 5 plugins at once on your own Mac, CPU-throttled
- ✅ Zero hardcoding — works for any WP plugin type (Elementor, Gutenberg, SEO, WooCommerce, themes)

**The outcome**: every release goes through the same scrutiny as if a Dev, QA engineer, PM, Designer, and beta tester all signed off — automated.

---

## 🆕 Auto-Scaffolding: Orbit Reads Your Plugin Code and Generates Tests

Point Orbit at any plugin directory. It reads every `add_menu_page`, `register_rest_route`, `add_shortcode`, `wp_ajax_`, `wp_schedule_event`, `block.json`, `register_post_type` — then generates:

```bash
bash scripts/scaffold-tests.sh ~/plugins/my-plugin [--deep]
```

→ **`scaffold-out/my-plugin/qa.config.json`** — prefilled with every detected entry point
→ **`scaffold-out/my-plugin/qa-scenarios.md`** — 40-80 structured QA scenarios
→ **`tests/playwright/flows/scaffold-my-plugin-smoke.spec.js`** — draft Playwright spec
→ (with `--deep`) **`ai-scenarios.md`** — AI reads code, writes business-logic scenarios with file:line refs

[→ Full auto-test-generation guide](docs/20-auto-test-generation.md) &nbsp;·&nbsp; [→ Business logic testing guide](docs/19-business-logic-guide.md)

---

Built and maintained by [@adityaarsharma](https://github.com/adityaarsharma). Works with any Claude Code-enabled machine.

---

## Vision

Orbit's job is to be the last line of defence between your plugin and your users.

Today it's WordPress-focused because that's where the problem is clearest: plugin teams ship on gut feel, QA is "I tested it on my machine," and UX decisions are never backed by data. Orbit changes that — one `bash scripts/gauntlet.sh` gives you evidence.

The same problem exists everywhere software gets built and shipped without a proper UAT layer. Orbit is designed to grow with that.

**For now**: WordPress plugins — Elementor addons, Gutenberg blocks, SEO plugins, WooCommerce extensions, themes.

**The discipline that powers it**: Dev signs off on code. QA signs off on function. PM signs off on flows and complexity. Designer signs off on visuals. All automated. All from one config file.

---

## Why This Exists

Most WordPress plugin issues that reach users fall into five categories:

1. **Code that was never wrong, just untested** — a widget that renders fine on the dev's machine breaks on PHP 8.2
2. **Performance regressions nobody noticed** — a new feature adds 40 extra DB queries per page load
3. **Design debt** — settings UI that confuses users because it was built dev-first, not user-first
4. **Flow blindness** — nobody mapped whether a first-time user can actually complete setup without a tutorial
5. **No comparison baseline** — "our Mega Menu is better than ElementKit" stated without any data

UAT (User Acceptance Testing) is the practice of validating a product from every perspective before it ships — not just "does the code run" but "will a real user get stuck, is the UI regressed, does the PM have evidence it's better than competitors." Orbit automates that entire layer for WordPress plugins.

**What top teams do that most don't**:
- Automattic/WordPress VIP run every commit through PHP linting + VIP coding standards before merge
- 10up uses AI-powered visual regression testing — catching when something *looks* different without being *technically* broken
- WordPress.org plugin team added 15+ automated security checks in 2025 alone
- Leading Elementor addon teams run Playwright E2E suites across 3 WP versions before release

Orbit brings that same discipline to any plugin team, with a single command.

---

## What It Checks

### For Developers

| Layer | What It Catches | Tools | Time |
|---|---|---|---|
| **PHP Lint** | Fatal syntax errors, parse failures | `php -l` | 10s |
| **WordPress Standards** | Naming, escaping, nonces, capability checks, SQL injection | phpcs (WPCS + VIP) | 30s |
| **Static Analysis** | Type errors, undefined vars, dead code | PHPStan level 5 | 45s |
| **Security Scan** | XSS, CSRF, SQLi, auth bypass, path traversal | phpcs security sniffs | 30s |
| **Database Profiling** | N+1 queries, slow queries, autoload bloat | Query Monitor + MySQL | 2min |
| **Asset Weight** | JS/CSS bundle size, size regression per release | File analysis | 5s |
| **Compatibility** | PHP 7.4–8.3 × WP 6.3–latest | `wp-env` multi-config + `php -l` | 5min |
| **i18n / POT** | Untranslated strings, missing text domains | `wp i18n make-pot` | 20s |

### For QA Testers

| Layer | What It Catches | Tools | Time |
|---|---|---|---|
| **Functional Tests** | Broken features, admin panel errors, 404 assets | Playwright | 3min |
| **Visual Regression** | UI changes between releases (pixel diff) | Playwright snapshots | 2min |
| **Responsive Tests** | Mobile/tablet/desktop layout breaks | Playwright viewports | 2min |
| **Accessibility** | Color contrast, missing labels, keyboard nav | axe-core (WCAG 2.1 AA) | 1min |
| **Console Errors** | JS errors specific to your plugin | Playwright | 1min |
| **Changelog Testing** | Maps each changelog entry to targeted test | `changelog-test.sh` | 1min |

### For Designers

| Layer | What It Catches | Tools | Time |
|---|---|---|---|
| **Visual Regression** | Any pixel-level UI change between releases | Playwright toHaveScreenshot() | 2min |
| **UI Audit** | Overflow, empty containers, unlabeled inputs, broken images | Playwright + DOM assertions | 1min |
| **Admin Screen Snapshots** | Every settings page, editor panel, plugin list page | Playwright screenshots | 1min |
| **Mobile Viewport** | Admin at 375px — overflow, stacked elements | Playwright viewport tests | 1min |
| **Frontend Visual** | Homepage, single post, archive at desktop + mobile | Playwright + toHaveScreenshot | 2min |

### For Product Managers

No commands to memorize — read `reports/qa-report-{timestamp}.md` after every gauntlet run.

| Layer | What It Protects | Shown As | Where |
|---|---|---|---|
| **Release Comparison** | "Did this release get worse or better?" | Score deltas (↑↓) | `scripts/compare-versions.sh` output |
| **Lighthouse Score** | User-facing speed and quality | 0–100 score | Gauntlet report |
| **Competitor Analysis** | "Are we ahead or behind?" | Side-by-side table of code quality, asset weight, update cadence | `reports/competitor-*.md` |
| **Pre-Release Checklist** | Sign-off gate before shipping | 60-point checklist | [checklists/pre-release-checklist.md](checklists/pre-release-checklist.md) |
| **UI/UX Checklist** | "Does this feel premium?" | 40-point checklist | [checklists/ui-ux-checklist.md](checklists/ui-ux-checklist.md) |
| **Changelog → Risk Map** | "What does this release change that could break?" | Test plan per changelog entry | `scripts/changelog-test.sh` |
| **Spell-Check Scan** | Typos in labels, buttons, tooltips, error messages — caught before users see them | Typo list per screen | Gauntlet report |
| **Guided Experience Score** | Does product guide new users or drop them cold? Wizard steps, hints, inline help detection | 0–10 guidance score | FTUE report |
| **Label + Option Ordering** | Confusing labels, illogically ordered select/radio/checkbox options | Flagged list per form | Admin audit |

**PM workflow**: before every release, open the latest gauntlet report + `reports/pm-ux/pm-ux-report-*.html` → check score deltas → sign off on the pre-release checklist. No terminal needed.

---

### 🆕 PM UX Audit — Step 12 of the Gauntlet

Orbit's newest layer. Runs automatically in `--mode full`. Three Playwright-based checks that catch the kind of quality issues that land in 1-star reviews:

#### Run standalone

```bash
# Full gauntlet includes it automatically
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

# Run PM UX checks only
WP_TEST_URL=http://localhost:8881 \
PLUGIN_ADMIN_SLUG=my-plugin-slug \
bash scripts/pm-ux-audit.sh
```

#### 1. Spell-Check Scan

Extracts every visible string from the plugin admin — labels, buttons, tooltips, placeholders, headings, notices — and checks for typos.

```
❌ "seting" → "setting"          [label] on /wp-admin/admin.php?page=my-plugin
❌ "intergration" → "integration" [heading] on /wp-admin/admin.php?page=my-plugin-advanced
❌ "recieve" → "receive"          [notice] on /wp-admin/admin.php?page=my-plugin
```

- Built-in dictionary of 60 most common WP plugin UI typos
- Optionally runs `cspell` for deeper coverage (install: `npm i -g cspell`)
- Output: `reports/pm-ux/spell-check-findings.json`

#### 2. Guided Experience Score

Scans for guidance signals across every admin page and scores the product 0–10. Compares against 7 top WP plugins.

```
[Guided UX] Score: 4/10  ████░░░░░░  (Competitor avg: 8/10)

  ✓ Present (2):
     • Inline Help Text (+2pts)
     • Placeholder Text (+1pt)

  ✗ Missing (5) — users are navigating these alone:
     • Setup Wizard (would add +3pts)
       A step-by-step setup flow for first-time users.
       → RankMath, WooCommerce, WPForms all use a wizard. Score +3.

     • Welcome / Onboarding Screen (would add +2pts)
       → RankMath, MonsterInsights, Elementor show a welcome screen on first activate.

     • Tooltips / Info Icons (would add +2pts)
       → Yoast SEO, WooCommerce, WPForms use "?" icons next to every setting.

  Competitors with better guidance:
     • RankMath: 9/10  (you are 5 points behind)
     • WPForms: 9/10   (you are 5 points behind)
     • Elementor: 9/10 (you are 5 points behind)
```

Signals scored: setup wizard (+3), welcome screen (+2), tooltips (+2), inline help text (+2), placeholder text (+1), empty-state guidance (+2), WP Help tab (+1).

#### 3. Label & Terminology Audit

Benchmarks every label, button, nav item, and option against `config/pm-ux/competitor-terms.json` — industry-standard terminology from 10 top WP plugins.

```
[Label Audit] 7 issue(s) found across 4 page(s)

  Anti-patterns: 4 (2 high severity)
  ❌ [button] "Submit" is a vague button label. Use "Save Settings".
      → WooCommerce, WPForms, Yoast SEO all use specific verbs.
  ❌ [button] "Toggle" is ambiguous. Use "Enable [Feature]" or "Disable [Feature]".
      → Jetpack, WooCommerce, Yoast SEO always name their toggles.
  ⚠  [label] "Enqueue scripts" contains PHP jargon. Use "Load Scripts".
      → WooCommerce, WPForms translate dev-terms into user-friendly language.
  ⚠  [nav] "Config" — industry standard is "Settings" (Yoast, WooCommerce, WordPress Core).

  Terminology vs competitors: 2
  ⚠  [button] "Apply" — industry standard is "Save Settings" (Yoast SEO, WooCommerce, RankMath).
  ⚠  [nav] "Utilities" — industry standard is "Tools" (Yoast SEO, WooCommerce, RankMath).

  Option ordering: 1 group out of logical order
  ⚠  "Cache Duration" → current: [Monthly, Daily, Never, Weekly]
     suggested: [Never, Daily, Weekly, Monthly]
     → WooCommerce, WPForms order options logically: None → Low → High → Custom.
```

Anti-patterns caught: vague buttons (Submit/OK/Go), double negatives, PHP jargon (enqueue/nonce/transient), ambiguous toggles, ALL CAPS abuse, tech abbreviations, non-specific "Enable" labels.

#### Output: PM UX HTML Report

After every run, one HTML report opens in browser — no terminal needed for the PM:

```
open reports/pm-ux/pm-ux-report-<timestamp>.html
```

Contains: typo count + list, guidance score card with competitor comparison, full label findings table. Share with your PM, they read it like a test report.

#### Competitor terms database

`config/pm-ux/competitor-terms.json` — the brain of the system. Contains industry-standard labels from:

**Yoast SEO · RankMath · Elementor · WooCommerce · WPForms · Gravity Forms · MonsterInsights · Jetpack · ContactForm7 · AIOSEO**

Covers: nav labels, button labels, field labels, error messages, toggle labels, section headings. When Orbit flags a term, it names which competitor uses the correct one.

Add your own competitors by editing this file — the format is self-explanatory.

---

### For End Users (via Real Browser Testing)

| Layer | What It Validates | Tools | Time |
|---|---|---|---|
| **User Flow Mapping** | Can a real user find and complete every core action? | Playwright journeys spec | 3min |
| **Click Depth Scoring** | How many clicks to reach key features? (Yoast: 2, yours: ?) | Journey tests with click counter | 1min |
| **Wizard / Onboarding Detection** | Does first-time setup exist and work? | Flow spec journey 1 | 1min |
| **Confusion Scoring** | Tab count × input count × toggle count — complexity index | Audit spec | 1min |
| **No PHP/JS Errors to User** | Zero fatal errors, zero unhandled JS errors reaching the DOM | Playwright console + body scan | 1min |

---

## Quick Start (the long version)

The 60-second install above is the easiest path. If you want to know what it's doing under the hood:

### Option 1 — Claude Code wizard (recommended for first time)

```bash
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash
# Then in Claude Code:
/orbit-setup
```

The wizard asks you 9 questions and creates `qa.config.json`:
- What type of plugin (Elementor addon / Gutenberg / SEO / WooCommerce / Theme)?
- Where is your source code?
- Who are your competitors? (auto-downloads and analyzes them)
- Do you have a Pro version to compare?
- Who uses this — dev, QA, or product team?

Every subsequent `/orbit-*` command reads from `qa.config.json` so you never repeat yourself.

### Option 2 — Manual (full control)

```bash
git clone https://github.com/adityaarsharma/orbit ~/Claude/orbit
cd ~/Claude/orbit
bash install.sh           # symlinks skills + installs power tools
bash setup/init.sh        # legacy plugin-config wizard (or use /orbit-setup)
```

---

## Test Site — Fully Automated (No GUI, No Clicks)

Orbit uses **`@wordpress/env`** (Docker) for full automation or **`wp-now`** for instant, zero-config runs. No GUI apps to install, no click-through setup.

### Path A — `@wordpress/env` (recommended for CI-grade isolation)

Docker-based, fully scriptable, multiple parallel sites possible.

**Prerequisites**: [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

```bash
# One command — creates WP site + installs your plugin + Query Monitor
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin --port 8881

# Site ready at: http://localhost:8881
# Admin:         http://localhost:8881/wp-admin  (admin / password)
```

**Lifecycle**:

```bash
wp-env stop                       # pause the site
wp-env start                      # resume
wp-env destroy                    # nuke it
wp-env clean all                  # reset DB to clean state
wp-env run cli wp <any-wp-cli>    # run any WP-CLI command
```

**Config**: auto-generated at `.wp-env-site/.wp-env.json`. Customize PHP/WP versions:

```json
{
  "core": "WordPress/WordPress#tags/6.5",
  "phpVersion": "8.2",
  "plugins": ["./path/to/my-plugin", "https://downloads.wordpress.org/plugin/query-monitor.zip"]
}
```

### Path B — `wp-now` (zero-config, instant)

No Docker. Runs in any plugin folder, auto-detects the plugin, spins up WP in seconds.

```bash
cd ~/plugins/my-plugin
wp-now start

# → http://localhost:8881 — plugin already active
```

Great for quick sanity checks. Not great for DB profiling or multi-site matrices (use wp-env for those).

### Which to Use When

| Scenario | Use |
|---|---|
| Full Orbit gauntlet | `wp-env` (via `create-test-site.sh`) |
| Quick single-widget check | `wp-now` |
| Multi-version matrix (PHP 7.4 × 8.3 × WP 6.3 × latest) | `wp-env` with multiple configs |
| CI / GitHub Actions later | `wp-env` (works identically in CI) |

Both come with Orbit's power-tools installer:

```bash
bash scripts/install-power-tools.sh
```

---

## Running the Pipeline

### Full Pre-Release Gauntlet

Run every layer before any release tag:

```bash
# Using qa.config.json (after init.sh)
bash scripts/gauntlet.sh

# Explicit plugin path
WP_TEST_URL=http://localhost:8881 \
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

# Quick mode (skips DB + Lighthouse — for fast developer iteration)
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode quick
```

Exit codes: `0` = all passed · `1` = failures found (do not release)

### Gauntlet Steps (What Runs in Order)

```
Step 1   PHP Lint           → syntax errors in every .php file
Step 1a  Release Metadata   → header, readme.txt, version parity, license, HPOS, WP compat
Step 1b  Zip Hygiene        → dev files, forbidden functions, supply-chain audit
Step 2   PHPCS              → WordPress + VIP coding standards
Step 3   PHPStan            → static analysis (level 5)
Step 4   Asset Weight       → JS/CSS bundle sizes
Step 5   i18n / POT         → translatable strings + text domain check (wp-cli)
Step 6   Playwright Tests   → functional + visual regression + flow videos
Step 7   Lighthouse         → Core Web Vitals scores
Step 8   DB Profiling       → query count + slow query log + memory + cron + GDPR
Step 9   Competitor         → side-by-side comparison of competitor plugins
Step 10  UI Performance     → editor load time (Elementor/Gutenberg) + frontend TTFB
Step 11  Claude Skills      → 6 parallel AI audits (security, perf, DB, a11y, standards, quality)
Step 12  PM UX Audit        → spell-check + guided experience score + label benchmarking
```

### Changelog-Based Tests

When you update the CHANGELOG, automatically generate a targeted test plan:

```bash
bash scripts/changelog-test.sh --changelog ~/plugins/the-plus-addons/CHANGELOG.md

# Output: per-change test suggestions
# [NEW FEATURE] Added Mega Menu widget
#   → Test: Create a test page with Mega Menu → verify renders
#   → Test: Elementor editor → search "Mega Menu" → verify in panel
# [PERFORMANCE] Reduced DB queries on homepage
#   → Run: db-profile.sh and compare query count
# [SECURITY] Added nonce verification to AJAX handler
#   → Run: /wordpress-penetration-testing on changed file
```

### Competitor Analysis

Download and analyze competitor plugins automatically:

```bash
# Uses competitors from qa.config.json
bash scripts/competitor-compare.sh

# Or explicit
bash scripts/competitor-compare.sh --competitors "essential-addons-for-elementor-free,premium-addons-for-elementor"
```

What it pulls from each competitor:
- Version, active installs, rating, last updated
- JS/CSS bundle size (are they leaner than you?)
- PHPCS errors vs WordPress standards
- Security patterns (nonce usage, escaping, DB prepare)
- block.json adoption

### Version Comparison (Before vs After)

```bash
bash scripts/compare-versions.sh \
  --old ~/downloads/the-plus-addons-v2.3.zip \
  --new ~/downloads/the-plus-addons-v2.4.zip
```

Compares: PHPCS errors, bundle sizes, and sets up visual diff baseline.

---

## Playwright Tests — Browser Automation

Default URL assumes `wp-env` on port 8881. Override with `WP_TEST_URL`.

### First Run — Save Admin Cookies

```bash
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/auth.setup.js --project=setup
```

### Run Tests

```bash
# Any template/folder
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/my-plugin/

# Responsive (mobile + tablet + desktop projects)
npx playwright test tests/playwright/my-plugin/ --project=mobile-chrome --project=tablet

# Just one file
npx playwright test tests/playwright/my-plugin/core.spec.js
```

### Watch Tests Run (4 Ways)

Running tests blind is miserable. Pick the mode that fits:

#### 1. **UI Mode** — best for development (interactive)

```bash
npx playwright test --ui
```

Opens a full test runner GUI. You see:
- Every test in a sidebar — click to run individually
- **Live DOM snapshot** at every step (time-travel debugger)
- Network, console, source tabs
- Watch mode — re-runs on file save

*Use this 90% of the time when writing/fixing tests.*

#### 2. **Headed Mode** — watch the browser do its thing

```bash
npx playwright test --headed --slowMo=500
```

Opens a real Chromium window. `--slowMo=500` pauses 500ms between actions so you can follow along.

*Use when you want to verify a specific flow visually.*

#### 3. **Debug Mode** — step through line by line

```bash
npx playwright test --debug
```

Opens the Playwright Inspector — set breakpoints, step over, pick locators.

*Use when a test fails and you can't tell why.*

#### 4. **Trace Viewer** — post-mortem on any failed test

```bash
# Traces auto-save on failure when "trace: 'on-first-retry'" is set in playwright.config.js
npx playwright show-trace test-results/.../trace.zip
```

Opens a web UI showing:
- DOM snapshot at every action
- Network waterfall
- Console logs
- Screenshots and video (if enabled)

*Use when a test failed on CI or someone else's machine — full forensic replay.*

### HTML Report — after any run

```bash
npx playwright show-report reports/playwright-html
```

Shows pass/fail per test, screenshots of failures, traces, and diffs.

### Screenshots + Video on Every Run

Already configured in `playwright.config.js`:

```js
use: {
  screenshot: 'only-on-failure',
  video: 'retain-on-failure',
  trace: 'on-first-retry',
}
```

Every failure gets a screenshot + video + trace automatically.

### What Each Test File Checks

**`tests/playwright/templates/seo-plugin/core.spec.js`** — Template for plugin comparison flows:
- Discovery tests — print all nav links for both plugins (run first)
- PAIR 1–N — side-by-side screenshots of matching features
- Frontend check — OG tags, schema, canonical on the homepage

**`{plugin}/core.spec.js`** — Plugin admin panel:
- Admin page loads without PHP fatal errors
- No broken images, no JS console errors
- Page loads under 4 seconds
- axe-core WCAG 2.1 AA accessibility scan
- Visual regression screenshots

**`{plugin}/responsive.spec.js`** — Responsive quality:
- No horizontal scroll at 375px, 768px, 1440px
- All interactive elements ≥ 44×44px (touch target size)
- Per-viewport visual snapshots

---

## UAT Flow Comparison (Plugin A vs Plugin B)

Orbit includes a **side-by-side UAT report system** for comparing two plugins on the same feature set. Produces an HTML report with paired screenshots, videos, PM analysis, RICE backlog, and a feature comparison table.

### Quick start

```bash
# Run flow tests + generate report + open in browser
npm run uat

# Run flow tests + generate report (no open — use on CI)
npm run uat:ci
```

### How the pairing system works

Screenshots and videos are named using the **PAIR-NN-slug-a/b convention**:

```
pair-01-dashboard-a.png    ← Plugin A dashboard
pair-01-dashboard-b.png    ← Plugin B dashboard
pair-02-meta-a.png         ← Plugin A meta templates
pair-02-meta-b.png         ← Plugin B meta templates
```

The report pairs files by **slug** (not by index). This means Social always pairs with Social, Sitemaps always pairs with Sitemaps — regardless of how many tests each plugin has or what order they run in. This is enforced by the `snapPair()` helper in `tests/playwright/helpers.js`.

### Writing a flow spec

Copy `tests/playwright/templates/seo-plugin/core.spec.js` for a new plugin pair.

**Step 1 — Discovery** (run this first for each plugin):
```bash
npx playwright test "Discovery | Plugin A"
# Prints all nav links to console — copy the exact URLs
```

**Step 2 — Use `snapPair()`, never `page.screenshot()`:**
```js
await snapPair(page, 1, 'dashboard', 'a', SNAP);           // pair-01-dashboard-a.png
await snapPair(page, 1, 'dashboard', 'a', SNAP, 'scroll'); // pair-01-dashboard-a-scroll.png
```

**Step 3 — Test title format** (required for video auto-renaming):
```
"PAIR-1 | dashboard | a | Plugin A dashboard overview"
```

### Generating the HTML report

```bash
python3 scripts/generate-uat-report.py \
  --title  "Plugin A vs Plugin B — v2.1" \
  --label-a "Plugin A" --label-b "Plugin B" \
  --snaps  reports/screenshots/flows-compare \
  --videos reports/videos \
  --out    reports/uat-report.html
```

**Adding PM analysis, RICE backlog, and feature table:**

Pass a `--flow-data` JSON file to add per-flow PM analysis, RICE scores, and a feature comparison table. Without it, the report shows only screenshots and videos.

```bash
python3 scripts/generate-uat-report.py \
  --flow-data reports/flow-data/my-plugin-vs-competitor.json \
  --out reports/uat-report.html
```

The JSON file structure:

```json
{
  "FLOW_DATA": {
    "1": {
      "slug": "dashboard",
      "title": "Dashboard",
      "verdict": "🔴 Needs Redesign",
      "a_summary": "...",
      "b_summary": "...",
      "pm_analysis": "<p>...</p>",
      "wins": ["..."],
      "gaps": ["..."],
      "actions": ["..."]
    }
  },
  "RICE": [
    { "r": 1, "n": "Fix description", "s": 54000, "reach": 18000,
      "imp": "MASSIVE", "eff": "XS", "t": "qw", "q": 1, "note": "..." }
  ],
  "FEATURES": [
    ["Feature name", "Plugin A description", "Plugin B description", "a|b|none"]
  ],
  "IA_RECS": "<div>...optional HTML for IA section...</div>"
}
```

---

## Performance Testing

All performance testing runs locally with no external APIs required.

### Lighthouse CLI

```bash
# Full report (opens in browser)
lighthouse http://localhost:8881 \
  --output=html \
  --output-path=reports/lighthouse/report.html \
  --chrome-flags="--headless"

open reports/lighthouse/report.html

# Quick score
lighthouse http://localhost:8881 --output=json --quiet \
  | python3 -c "import json,sys; d=json.load(sys.stdin); \
    print('Performance:', int(d['categories']['performance']['score']*100), \
    '| A11y:', int(d['categories']['accessibility']['score']*100))"
```

### Core Web Vitals Targets

| Metric | Target | What It Means |
|---|---|---|
| Performance score | ≥ 80 | Overall weighted score |
| LCP | < 2.5s | When the main content loads |
| FCP | < 1.8s | When first content appears |
| TBT | < 200ms | JS blocking the main thread |
| CLS | < 0.1 | No layout jumps (content jumping around) |
| TTI | < 3.8s | When the page responds to user input |

### DB Query Profiling

Runs WP-CLI inside your `wp-env` container to count queries, flag slow ones, and detect N+1 patterns.

```bash
# Default — uses wp-env site at port 8881
bash scripts/db-profile.sh

# Custom URL / pages
WP_TEST_URL="http://localhost:8881" \
TEST_PAGES="/,/my-test-page/" \
bash scripts/db-profile.sh
```

Flags: query count >60/page, any query >100ms, N+1 patterns.

---

## Skill-Assisted Audits (Claude Code)

This pipeline integrates with Claude Code skills for deep AI-assisted analysis. See [SKILLS.md](SKILLS.md) for the full reference.

### Quick Examples

```bash
# Full security audit
claude "/wordpress-penetration-testing Audit ~/plugins/the-plus-addons for all OWASP vulnerabilities"

# Performance deep-dive
claude "/performance-engineer Find all N+1 queries in ~/plugins/the-plus-addons/includes/"

# Admin UI quality check
claude "/antigravity-design-expert Review admin UI in ~/plugins/the-plus-addons/admin/ for polish issues"

# 4 parallel audit agents (WP standards, security, performance, DB)
claude "Run 4 parallel audits on ~/plugins/the-plus-addons:
1. /wordpress-plugin-development — WP standards
2. /wordpress-penetration-testing — security
3. /performance-engineer — performance
4. /database-optimizer — database
Merge findings by severity."
```

---

## Deep Performance — Beyond Lighthouse

Lighthouse scores the rendered page. Orbit also profiles the parts Lighthouse can't see:

### 1. Backend — Which Hook Is Slow?

Find which PHP hook of yours is blocking page render. Query Monitor's **Hooks & Actions** panel + automated profiling:

```bash
bash scripts/db-profile.sh                    # query count + slow queries
wp-env run cli wp profile stage --all         # if wp-cli-profile installed
```

Use `/performance-engineer` to analyze which of your `init/wp_loaded/wp_head` callbacks take >50ms.

### 2. Frontend — What's Bloating the Bundle?

Beyond Lighthouse scores — actual bundle audit:

```bash
npx source-map-explorer path/to/plugin/assets/js/main.js
purgecss --css path/to/plugin/assets/css/frontend.css --content http://localhost:8881
```

Shows which files/selectors are shipped but unused.

### 3. Editor Performance — Elementor + Gutenberg

Most addon bugs live here: editor feels slow, widgets lag, panel freezes. Orbit has a dedicated harness:

```bash
bash scripts/editor-perf.sh
# → reports/editor-perf-{timestamp}.json
```

Measures:
- **Editor ready time** (target: <3s)
- **Widget panel populated** (target: <500ms after ready)
- **Widget insert → render** (target: <300ms per widget)
- **Memory growth after 20 widgets** (target: <100MB)
- **Console spam + errors** from your plugin

Then feed to Claude:

```bash
claude "/performance-engineer
Analyze reports/editor-perf-*.json for ~/plugins/my-plugin.
Rank widgets by insertMs, find heavy operations, suggest fixes."
```

Full guide: [docs/deep-performance.md](docs/deep-performance.md) — covers backend hook timing, Xdebug profiling, React DevTools, long-task detection, and release-blocking thresholds.

---

## Claude Code-Native (No CI Required)

Orbit runs **locally, on demand, from Claude Code**. No GitHub Actions, no servers, no API keys, no secrets to manage. Every check is a `/skill` call or a `bash scripts/*.sh` invocation you trigger yourself.

**Why local-only?**
- WordPress plugin QA needs real MySQL, real PHP, real browsers — you have those on your Mac.
- CI drifts: tooling breaks silently, nobody fixes it, releases ship anyway. Local is inspectable.
- Claude Code with `/` commands is faster to iterate than CI logs.

**When you want automation later**, wire `bash scripts/gauntlet.sh` into your existing deploy pipeline — it exits 0 on pass, 1 on fail.

---

## Adding Tests for Your Plugin

1. Create: `tests/playwright/your-plugin/core.spec.js`
2. Copy a template from `tests/playwright/templates/`
3. Replace admin URLs and CSS selectors with your plugin's
4. Create a test site: `bash scripts/create-test-site.sh --plugin ~/plugins/your-plugin --port 8881`
5. Run: `WP_TEST_URL=http://your-plugin.local npx playwright test tests/playwright/your-plugin/`

Minimal new test template:

```js
const { test, expect } = require('@playwright/test');

test('my widget renders correctly', async ({ page }) => {
  await page.goto('/my-test-page/');
  await page.waitForLoadState('networkidle');

  await expect(page.locator('.my-widget-class')).toBeVisible();

  // No JS errors from your plugin
  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  expect(errors.filter(e => e.includes('my-plugin'))).toHaveLength(0);

  // Visual snapshot (first run creates baseline; subsequent runs diff)
  await expect(page).toHaveScreenshot('my-widget.png', { maxDiffPixelRatio: 0.02 });
});
```

---

## Report Output

Every gauntlet run creates `reports/qa-report-{timestamp}.md`. Example:

```
# WordPress QA Gauntlet Report
Plugin: the-plus-addons | Date: 2026-04-20 | Mode: full / local

## Results
- ✓ PHP Lint:      0 errors
- ✓ PHPCS:         0 errors, 8 warnings
- ✓ PHPStan:       clean
- ✓ Asset Weight:  JS 1.18MB | CSS 342KB
- ✓ Playwright:    48/48 tests passed
- ✓ Lighthouse:    83/100
- ⚠ DB Queries:   67/page on homepage (threshold: 60) — review

Summary: 6 passed · 1 warning · 0 failed
```

---

## Checklists

- [Pre-Release Checklist](checklists/pre-release-checklist.md) — full sign-off before any release (dev, QA, product)
- [UI/UX Checklist](checklists/ui-ux-checklist.md) — design quality (40 points, based on make-interfaces-feel-better)
- [Performance Checklist](checklists/performance-checklist.md) — Core Web Vitals, assets, DB
- [Security Checklist](checklists/security-checklist.md) — XSS, CSRF, SQLi, auth

---

## Docs

- **[GETTING-STARTED.md](GETTING-STARTED.md) — 🌟 the one you should read first**
- **[docs/onboarding-by-role.md](docs/onboarding-by-role.md) — Role-by-role guide: Dev, QA, PM, PA, Designer, End User — exact commands, what to read, what to sign off**
- [What is Playwright](docs/what-is-playwright.md) — beginner-friendly primer on browser automation
- [Writing Tests Guide](docs/writing-tests.md) — practical test-authoring recipes for every plugin type
- [Real-World QA Cases](docs/real-world-qa.md) — 18 cases most checklists miss (uninstall, upgrade, multisite, GDPR, REST, etc.)
- [wp-env Setup](docs/wp-env-setup.md) — fully automated WP test sites, Docker-based
- [Database Profiling Guide](docs/database-profiling.md) — Query Monitor, N+1 fixes, `performance_schema`
- [Deep Performance Guide](docs/deep-performance.md) — backend hooks, frontend bundle, Elementor editor perf
- [Common WordPress Mistakes](docs/common-wp-mistakes.md) — what this pipeline catches automatically
- [Power Tools Guide](docs/power-tools.md) — Claude Mem, Rector, Psalm, WPScan, and more
- [Skill Commands Reference](SKILLS.md) — every Claude Code skill, with Antigravity attribution
- [Playwright Templates](tests/playwright/templates/README.md) — generic templates per plugin type

---

## The `plugins/` Drop Box

Orbit has a `plugins/` folder for comparison runs and competitor analysis:

```
plugins/
├── free/     # Auto-downloaded free zips (from wordpress.org)
└── pro/      # You manually drop Pro / paid zips here
```

**Pull every free plugin slug from your config**:

```bash
bash scripts/pull-plugins.sh
# Reads qa.config.json "competitors" → downloads latest zips → saves to plugins/free/<slug>/
```

**For Pro zips**: download from your vendor account, drop into `plugins/pro/`, reference in `qa.config.json`:

```json
{
  "plugin": {
    "proZip": "plugins/pro/my-plugin-pro-2.4.zip"
  }
}
```

Full details: [plugins/README.md](plugins/README.md).

---

## Coverage Targets

| Metric | Minimum | Target | Blocks Release? |
|---|---|---|---|
| PHP syntax errors | 0 | 0 | Yes |
| PHPCS errors | 0 | 0 | Yes |
| Security findings (critical/high) | 0 | 0 | Yes |
| E2E tests passing | 100% | 100% | Yes |
| Accessibility score | 85 | 95+ | Yes |
| Lighthouse performance | 75 | 85+ | Warn only |
| DB query count regression | 0 increase | 0 increase | Warn only |
| Visual diffs (unintended) | 0 | 0 | Warn only |
| PHP 7.4–8.3 clean | Yes | Yes | Yes |

---

## Folder Structure

```
orbit/
├── setup/
│   ├── init.sh                    # Interactive first-run setup (Orbit config)
│   ├── install.sh                 # Basic dependency installer
│   └── playground-blueprint.json  # Optional WP Playground local blueprint
├── plugins/                        # Plugin zip drop-box (gitignored)
│   ├── free/                       # Auto-downloaded from wordpress.org
│   └── pro/                        # You drop Pro/paid zips here manually
├── tests/playwright/
│   ├── playwright.config.js        # Multi-project config (desktop + mobile + tablet)
│   ├── auth.setup.js               # Save admin cookies once
│   ├── templates/                  # Copy these for your plugin
│   │   ├── generic-plugin/
│   │   ├── elementor-addon/
│   │   ├── gutenberg-block/
│   │   ├── seo-plugin/
│   │   ├── woocommerce/
│   │   └── theme/
│   ├── elementor-addon/            # Template: Elementor addon
│   └── gutenberg-block/            # Template: Gutenberg block plugin
├── config/
│   ├── phpcs.xml                   # WPCS + VIP + PHPCompatibility rules
│   ├── phpstan.neon                # Level 5 static analysis
│   └── lighthouserc.json           # Performance/a11y thresholds
├── scripts/
│   ├── gauntlet.sh                 # Full pre-release pipeline (8 steps)
│   ├── install-power-tools.sh      # Install every quality tool worth having
│   ├── create-test-site.sh         # Automated wp-env test site
│   ├── pull-plugins.sh             # Download free competitor zips by slug
│   ├── changelog-test.sh           # Maps changelog → targeted tests
│   ├── compare-versions.sh         # Version A vs B diff
│   ├── competitor-compare.sh       # Analyze competitor plugin zips
│   ├── db-profile.sh               # Query count + slow query profiling
│   └── editor-perf.sh              # Elementor/Gutenberg editor load + widget-insert timing
├── checklists/
│   ├── pre-release-checklist.md
│   ├── ui-ux-checklist.md
│   ├── performance-checklist.md
│   └── security-checklist.md
├── docs/
│   ├── wp-env-setup.md
│   ├── database-profiling.md
│   └── common-wp-mistakes.md      # What senior WP devs know to avoid
├── SKILLS.md                       # Claude Code skill commands reference
└── qa.config.json                  # Created by init.sh — your plugin config
```

---

## Standards This Follows

- [WordPress Coding Standards](https://github.com/WordPress/WordPress-Coding-Standards) — WPCS phpcs ruleset
- [WordPress VIP Coding Standards](https://github.com/Automattic/VIP-Coding-Standards) — enterprise-grade rules
- [10up Open Source Best Practices](https://10up.github.io/Open-Source-Best-Practices/testing/) — coverage targets, E2E approach
- [WordPress Playground E2E Guide](https://wordpress.github.io/wordpress-playground/guides/e2e-testing-with-playwright/) — CI browser testing
- [make-interfaces-feel-better](https://skills.sh/jakubkrehel/make-interfaces-feel-better/make-interfaces-feel-better) — UI/UX quality principles

---

## Power Tools — Level Up Every Claude Code Session

Orbit works on basic tooling, but install the full power kit and every plugin audit becomes a senior-team operation:

```bash
bash scripts/install-power-tools.sh
```

This installs:

### Claude Code Add-Ons
- **claude-mem** — persistent memory across Claude Code sessions. Every audit becomes searchable context for the next one.
- **ccusage** — track your Claude Code token spend per session.

### PHP Quality
- **PHP_CodeSniffer + WPCS + VIP + PHPCompatibility** — the full WordPress standards stack
- **PHPStan** level 5 + **szepeviktor/phpstan-wordpress** — static analysis with WP stubs
- **Psalm** — alternative static analyzer (different strengths than PHPStan)
- **Rector** — automated PHP refactoring, upgrade PHP 7 → 8 automatically
- **PHPBench** — micro-benchmarks for hot paths

### JS / CSS / Browser
- **Playwright** + Chromium/Firefox/WebKit
- **Lighthouse** + **LHCI**
- **ESLint** + `@wordpress/eslint-plugin`
- **Stylelint** + `@wordpress/stylelint-config`
- **@axe-core/cli** — accessibility scanner

### WordPress-Specific
- **WP-CLI** — master it, save hours per day
- **@wordpress/env** — Docker-based WP sites, fully scriptable
- **wp-now** — zero-config instant WP from any folder
- **WPScan** — WordPress vulnerability scanner (CVE checks)

### Must-Install Claude Skills
All 13 skills used in [SKILLS.md](SKILLS.md):
- `/wordpress`, `/wordpress-plugin-development`, `/wordpress-penetration-testing`, `/wordpress-theme-development`, `/wordpress-woocommerce-development`
- `/performance-engineer`, `/database-optimizer`, `/ui-ux-designer`, `/production-code-audit`, `/accessibility-compliance-accessibility-audit`
- `/antigravity-design-expert`, `/antigravity-workflows`, `/antigravity-skill-orchestrator`

Full list + install guide: [docs/power-tools.md](docs/power-tools.md).

---

## Roadmap — How Orbit Gets Better

Orbit is designed to grow. Tracked ideas:

### Near-term
- [x] **PM UX Audit (Step 12)** — spell-check, guided experience score, label benchmarking vs 10 top WP plugins ✅ shipped v2.4.0
- [ ] **Plugin Check integration** — run [WordPress/plugin-check](https://github.com/WordPress/plugin-check) as a gauntlet step (mirrors wordpress.org submission checks)
- [ ] **Mutation testing** — via Infection PHP to catch weak tests
- [ ] **Release note auto-generator** — from Playwright diffs + changelog, produce a marketable changelog
- [ ] **Multi-site matrix testing** — run gauntlet across `PHP × WP × WooCommerce` combinations via wp-env
- [ ] **Translation coverage report** — per-locale .mo file freshness check

### Medium-term
- [ ] **WPScan CVE check** — wire into gauntlet as a security gate
- [ ] **Memory profiling** — Xdebug + cachegrind integration for "which hook is slow"
- [ ] **REST API fuzzer** — auto-discover + fuzz every `register_rest_route` call
- [ ] **Gutenberg block.json linter** — strict validation against current WP standards
- [ ] **Visual diff UI** — web viewer for pixel diffs beyond Playwright's HTML reporter

### Long-term
- [ ] **Claude Code Skill: `/orbit-audit`** — one skill that orchestrates the full gauntlet
- [ ] **VS Code extension** — run any Orbit script from the editor's command palette
- [ ] **Release gate bot** — comment on PRs with a pass/fail grid
- [ ] **Public benchmark dashboard** — community-submitted competitor scores, kept fresh

### Contribute an idea
Open an issue at [github.com/adityaarsharma/orbit/issues](https://github.com/adityaarsharma/orbit/issues) with `[roadmap]` in the title.

**Repo**: [github.com/adityaarsharma/orbit](https://github.com/adityaarsharma/orbit)

---

## Contributing / Extending

This repo is designed to grow. Good contributions:
- New Playwright templates for plugin types (tests/playwright/templates/)
- Plugin-type-specific PHPCS rule additions
- Additional competitor analysis metrics
- Performance regression rules
- New skill invocation patterns in SKILLS.md
- New power tools worth installing (docs/power-tools.md)

Keep it research-first. If adding a check: link to the standard or incident that motivated it.

---

## Philosophy

Orbit follows three rules:

1. **Build from config, not hardcoded paths.** Everything reads `qa.config.json`. A config-less run is a smoke test.
2. **Local-first, not CI-first.** Real MySQL, real PHP, real browsers — already on your Mac. CI is optional plumbing.
3. **Agents over scripts, when useful.** Claude Code skills are the senior reviewer; scripts are the junior QA.

---

## Credits & Attribution

Orbit stands on the shoulders of open-source skill collections. **You don't need Google Antigravity installed** — every referenced skill works directly inside Claude Code.

| Project | What | Link |
|---|---|---|
| **Antigravity Skills** (rmyndharis) | 300+ skills ported from Claude Code Agents — core `antigravity-*` skills | [github.com/rmyndharis/antigravity-skills](https://github.com/rmyndharis/antigravity-skills) |
| **Antigravity Awesome Skills** (sickn33) | 1,400+ skills + installer CLI | [github.com/sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) |
| **Awesome Agent Skills** (VoltAgent) | 1,000+ skills from Anthropic, Vercel, Stripe, Cloudflare, Figma, Sentry | [github.com/VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) |
| **WordPress Coding Standards** | phpcs ruleset | [WordPress/WordPress-Coding-Standards](https://github.com/WordPress/WordPress-Coding-Standards) |
| **WordPress VIP Coding Standards** | Enterprise sniffs | [Automattic/VIP-Coding-Standards](https://github.com/Automattic/VIP-Coding-Standards) |
| **10up Engineering Best Practices** | Reference docs | [10up.github.io/Engineering-Best-Practices](https://10up.github.io/Engineering-Best-Practices/) |
| **@wordpress/env** | Docker-based local WP | [github.com/WordPress/gutenberg/tree/trunk/packages/env](https://github.com/WordPress/gutenberg/tree/trunk/packages/env) |
| **WPScan** | WordPress CVE scanner | [github.com/wpscanteam/wpscan](https://github.com/wpscanteam/wpscan) |

Full skill-to-task mapping: [SKILLS.md](SKILLS.md). Power tools setup: [docs/power-tools.md](docs/power-tools.md).

---

*Built by [Aditya R Sharma](https://adityaarsharma.com) · [github.com/adityaarsharma/orbit](https://github.com/adityaarsharma/orbit) · Licensed for any WordPress plugin team serious about shipping quality.*
