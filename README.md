<div align="center">

# 🪐 Orbit

### **Complete UAT for WordPress Plugins**

*Every perspective. Every release. Dev → QA → PM → Designer → End User.*

**👉 [Start Here: Getting Started Guide](GETTING-STARTED.md) — 15 min to first run**

<br />

![PHP](https://img.shields.io/badge/PHP-7.4%20→%208.3-777BB4?style=for-the-badge&logo=php&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-6.3%20→%20Latest-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![Playwright](https://img.shields.io/badge/Playwright-E2E-2EAD33?style=for-the-badge&logo=playwright&logoColor=white)
![Lighthouse](https://img.shields.io/badge/Lighthouse-Performance-F44B21?style=for-the-badge&logo=lighthouse&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude%20Code-Skills-CC785C?style=for-the-badge)

<br />

**👨‍💻 Dev** → zero-regression releases &nbsp;·&nbsp; **🧪 QA** → structured test coverage &nbsp;·&nbsp; **📊 PM** → flow maps + complexity scores &nbsp;·&nbsp; **🎨 Designer** → visual diffs + UI audits &nbsp;·&nbsp; **👤 End User** → real browser, real flows

Covers **Elementor Addons · Gutenberg Blocks · SEO Plugins · WooCommerce Extensions · Themes**

<br />

[Quick Start](#quick-start) · [What It Checks](#what-it-checks) · [Skills Reference](SKILLS.md) · [GitHub](https://github.com/adityaarsharma/plugorbit) · [Common WP Mistakes](docs/common-wp-mistakes.md)

</div>

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
- ✅ Designer layer — pixel-diff visual regression across admin, editor, and frontend at every viewport
- ✅ Mass parallel mode — test 5 plugins at once on your own Mac, CPU-throttled
- ✅ Zero hardcoding — works for any WP plugin type (Elementor, Gutenberg, SEO, WooCommerce, themes)

**The outcome**: every release goes through the same scrutiny as if a Dev, QA engineer, PM, Designer, and beta tester all signed off — automated.

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

**PM workflow**: before every release, open the latest gauntlet report + competitor report → check score deltas → sign off on the pre-release checklist. No terminal needed.

### For End Users (via Real Browser Testing)

| Layer | What It Validates | Tools | Time |
|---|---|---|---|
| **User Flow Mapping** | Can a real user find and complete every core action? | Playwright journeys spec | 3min |
| **Click Depth Scoring** | How many clicks to reach key features? (Yoast: 2, yours: ?) | Journey tests with click counter | 1min |
| **Wizard / Onboarding Detection** | Does first-time setup exist and work? | Flow spec journey 1 | 1min |
| **Confusion Scoring** | Tab count × input count × toggle count — complexity index | Audit spec | 1min |
| **No PHP/JS Errors to User** | Zero fatal errors, zero unhandled JS errors reaching the DOM | Playwright console + body scan | 1min |

---

## Quick Start

### Option 1 — Interactive Setup (Recommended for First Time)

```bash
git clone https://github.com/adityaarsharma/plugorbit
cd orbit
bash setup/init.sh
```

`init.sh` asks you 9 questions and creates `qa.config.json`:
- What type of plugin (Elementor addon / Gutenberg / SEO / WooCommerce / Theme)?
- Where is your source code?
- Who are your competitors? (auto-downloads and analyzes them)
- Do you have a Pro version to compare?
- Who uses this — dev, QA, or product team?

Every subsequent command reads from `qa.config.json` so you never repeat yourself.

### Option 2 — One-Liner (Skip Questions)

```bash
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/plugorbit/main/setup/install.sh | bash
```

### Option 3 — Manual

```bash
git clone https://github.com/adityaarsharma/plugorbit
cd orbit
bash setup/install.sh   # installs all tools
# Then configure qa.config.json manually (see structure below)
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
Step 1  PHP Lint           → syntax errors in every .php file
Step 2  PHPCS              → WordPress + VIP coding standards
Step 3  PHPStan            → static analysis (level 5)
Step 4  Asset Weight       → JS/CSS bundle sizes
Step 5  i18n / POT         → translatable strings + text domain check (wp-cli)
Step 6  Playwright Tests   → functional + visual regression
Step 7  Lighthouse         → Core Web Vitals scores
Step 8  DB Profiling       → query count + slow query log
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

**`tpa/core.spec.js`** — The Plus Addons core:
- Admin settings page loads without PHP fatal errors
- Elementor editor loads with TPA panel visible
- TPA widgets appear when searching in Elementor
- Frontend page has zero JS console errors from TPA code
- No broken images on test pages
- Page loads under 4 seconds
- axe-core WCAG 2.1 AA accessibility scan
- Visual regression screenshots (homepage + test page)

**`tpa/responsive.spec.js`** — Responsive quality:
- No horizontal scroll at 375px, 768px, 1440px
- Mobile hamburger menu opens and shows navigation
- All interactive elements ≥ 44×44px (touch target size)
- Per-viewport visual snapshots

**`nexterwp/core.spec.js`** — NexterWP theme + blocks + extension:
- Theme active, no critical admin notices
- WordPress Customizer loads cleanly
- Nexter Blocks visible in Gutenberg block inserter
- Nexter Blocks + Extension admin pages load without errors
- Homepage zero JS errors from Nexter code
- Header builder and footer render
- Single post template renders correctly
- No horizontal overflow at any viewport
- Zero CSS/JS 404 responses
- Lighthouse budget: load time < 4 seconds
- WCAG 2.1 AA accessibility scan
- Visual regression snapshots

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

# 4 parallel audit agents (same as RankReady gauntlet)
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
2. Copy structure from `tests/playwright/tpa/core.spec.js`
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
│   ├── tpa/                        # Real example: Elementor addon
│   └── nexterwp/                   # Real example: theme + blocks
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
- [ ] **Plugin Check integration** — run [WordPress/plugin-check](https://github.com/WordPress/plugin-check) as Step 9 of gauntlet (mirrors wordpress.org submission checks)
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
Open an issue at [github.com/adityaarsharma/plugorbit/issues](https://github.com/adityaarsharma/plugorbit/issues) with `[roadmap]` in the title.

**Repo**: [github.com/adityaarsharma/plugorbit](https://github.com/adityaarsharma/plugorbit)

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

*Built by [Aditya R Sharma](https://adityaarsharma.com) · [github.com/adityaarsharma/plugorbit](https://github.com/adityaarsharma/plugorbit) · Licensed for any WordPress plugin team serious about shipping quality.*
