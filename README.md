# PlugOrbit — WordPress Plugin QA Intelligence

> The automated QA pipeline that makes every WordPress plugin ship like it was built by a senior team — even when it wasn't.

**Who this is for**: Plugin developers who want zero-regression releases · QA teams doing structured testing · Product managers who need confidence before shipping

**Covers out-of-the-box**: The Plus Addons for Elementor · NexterWP Theme + Blocks + Extension · Any WordPress plugin (Elementor addon, Gutenberg blocks, SEO plugin, WooCommerce extension, theme)

[![WordPress QA](https://github.com/adityaarsharma/wordpress-qa-master/actions/workflows/qa-full.yml/badge.svg)](https://github.com/adityaarsharma/wordpress-qa-master/actions/workflows/qa-full.yml)

---

## Why This Exists

Most WordPress plugin bugs that reach users fall into three categories:

1. **Code that was never wrong, just untested** — a widget that renders fine on the dev's machine breaks on PHP 8.2
2. **Performance regressions nobody noticed** — a new feature adds 40 extra DB queries per page load
3. **Design debt** — settings UI that confuses users because it was built dev-first, not user-first

This pipeline catches all three, automatically, before any release ships.

**What top teams do that most don't**:
- Automattic/WordPress VIP run every commit through PHP linting + VIP coding standards before merge
- 10up uses AI-powered visual regression testing — catching when something *looks* different without being *technically* broken
- WordPress.org plugin team added 15+ automated security checks in 2025 alone
- Leading Elementor addon teams run Playwright E2E suites across 3 WP versions before release

PlugOrbit brings that same discipline to any plugin team, with a single command.

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
| **Compatibility** | PHP 7.4–8.3 × WP 6.3–latest | GitHub Actions matrix | 5min |

### For QA Testers

| Layer | What It Catches | Tools | Time |
|---|---|---|---|
| **Functional Tests** | Broken features, admin panel errors, 404 assets | Playwright | 3min |
| **Visual Regression** | UI changes between releases (pixel diff) | Playwright snapshots | 2min |
| **Responsive Tests** | Mobile/tablet/desktop layout breaks | Playwright viewports | 2min |
| **Accessibility** | Color contrast, missing labels, keyboard nav | axe-core (WCAG 2.1 AA) | 1min |
| **Console Errors** | JS errors specific to your plugin | Playwright | 1min |
| **Changelog Testing** | Maps each changelog entry to targeted test | `changelog-test.sh` | 1min |

### For Product Managers

| Layer | What It Protects | Shown As |
|---|---|---|
| **Release Comparison** | "Did this release get worse or better?" | Score deltas (↑↓) |
| **Lighthouse Score** | User-facing speed and quality | 0–100 score |
| **Competitor Analysis** | "Are we ahead or behind on code quality?" | Side-by-side table |
| **Pre-Release Checklist** | Sign-off gate before anything ships | Checklist |
| **UI/UX Checklist** | "Does this feel premium?" | 40-point checklist |

---

## Quick Start

### Option 1 — Interactive Setup (Recommended for First Time)

```bash
git clone https://github.com/adityaarsharma/wordpress-qa-master
cd wordpress-qa-master
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
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/wordpress-qa-master/main/setup/install.sh | bash
```

### Option 3 — Manual

```bash
git clone https://github.com/adityaarsharma/wordpress-qa-master
cd wordpress-qa-master
bash setup/install.sh   # installs all tools
# Then configure qa.config.json manually (see structure below)
```

---

## Local WP — Required for Full Testing

### What Is Local WP and Why You Need It

Local WP (by Flywheel) is a free desktop app that runs a real WordPress environment on your Mac or Windows machine. Unlike WordPress Playground (browser-based), Local WP gives you:

- **Real MySQL 8.0 database** — required for DB query profiling, slow query logs
- **Real PHP 8.1** — catches issues that PHP simulators miss
- **Snapshots** — restore a clean database in 5 seconds before each test run
- **WP-CLI built in** — automate plugin installs, database resets from terminal
- **Multiple sites at once** — one per plugin under test

### Download the Right Version

**Download**: https://localwp.com → click **Download**

| Your Mac | Download |
|---|---|
| Apple Silicon (M1 / M2 / M3 / M4) | `Local-9.x.x-mac-arm64.dmg` |
| Intel Mac | `Local-9.x.x-mac-x64.dmg` |
| Windows | `Local-9.x.x-windows.exe` |

> Always use **Local 9.x** (current stable). Older versions have networking issues on modern macOS.

### Create Your Test Site

1. Open Local → click **+** (bottom left)
2. Site name: `tpa-test` (or your plugin name + `-test`)
3. Choose **Custom** environment:
   - PHP: **8.1**
   - Web server: **nginx**
   - MySQL: **8.0**
4. WordPress username: `admin` | Password: `password`
5. Click **Add Site**

Repeat for each plugin (e.g. `nexterwp-test`).

### First-Time Site Setup via WP-CLI

```bash
# Open the site shell in Local WP (right-click site → Open Site Shell)

# Install Query Monitor for DB profiling (required)
wp plugin install query-monitor --activate

# Install Elementor if testing an Elementor addon
wp plugin install elementor --activate

# Install your plugin
wp plugin install ~/Downloads/your-plugin.zip --activate --force

# Create a test page
wp post create --post_title="QA Test Page" --post_type=page --post_status=publish --post_name=qa-test
```

### Take a Clean Snapshot

After setup is complete, **before running any tests**:

1. Right-click site in Local → **Snapshots** → **Save Snapshot**
2. Name: `clean-v{version}` (e.g. `clean-v2.4.0`)

**Restore before every test run**: Right-click → Snapshots → Restore.
Takes 5 seconds. Guarantees a clean database with no test pollution.

### Enable MySQL Slow Query Log

Local WP → Click site → **Database** tab → toggle **Enable Slow Query Log** → threshold: `0.05s`

This logs any DB query taking over 50ms — essential for performance regression detection.

---

## Running the Pipeline

### Full Pre-Release Gauntlet

Run every layer before any release tag:

```bash
# Using qa.config.json (after init.sh)
bash scripts/gauntlet.sh

# Manual with explicit paths
WP_TEST_URL=http://tpa-test.local \
bash scripts/gauntlet.sh --plugin ~/plugins/the-plus-addons --env local

# Quick mode (skips DB + Lighthouse — for fast developer iteration)
bash scripts/gauntlet.sh --plugin ~/plugins/the-plus-addons --mode quick
```

Exit codes: `0` = all passed · `1` = failures found (do not release)

### Gauntlet Steps (What Runs in Order)

```
Step 1  PHP Lint           → syntax errors in every .php file
Step 2  PHPCS              → WordPress + VIP coding standards
Step 3  PHPStan            → static analysis (level 5)
Step 4  Asset Weight       → JS/CSS bundle sizes
Step 5  Playwright Tests   → functional + visual regression
Step 6  Lighthouse         → Core Web Vitals scores
Step 7  DB Profiling       → query count + slow query log (local only)
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

### First Run — Auth Setup

```bash
WP_TEST_URL=http://tpa-test.local \
npx playwright test tests/playwright/auth.setup.js --project=setup
```

### Run Tests

```bash
# The Plus Addons — full suite
WP_TEST_URL=http://tpa-test.local npx playwright test tests/playwright/tpa/

# NexterWP — full suite
WP_TEST_URL=http://nexterwp-test.local npx playwright test tests/playwright/nexterwp/

# Responsive only (mobile + tablet + desktop)
WP_TEST_URL=http://tpa-test.local npx playwright test tests/playwright/tpa/responsive.spec.js

# Watch the browser while tests run
WP_TEST_URL=http://tpa-test.local npx playwright test tests/playwright/tpa/ --headed --slowMo=500

# Debug a specific failing test
WP_TEST_URL=http://tpa-test.local npx playwright test --debug
```

### View Test Report

```bash
npx playwright show-report reports/playwright-html
```

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
lighthouse http://tpa-test.local \
  --output=html \
  --output-path=reports/lighthouse/report.html \
  --chrome-flags="--headless"

open reports/lighthouse/report.html

# Quick score
lighthouse http://tpa-test.local --output=json --quiet \
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

```bash
WP_PATH="$HOME/Local Sites/tpa-test/app/public" \
WP_TEST_URL="http://tpa-test.local" \
TEST_PAGES="/,/qa-test/" \
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

## CI / GitHub Actions

### What Triggers What

| Trigger | Workflow | What Runs |
|---|---|---|
| Any pull request | `qa-quick.yml` | PHP lint on changed files + PHPCS + smoke tests |
| Push to `release/**` | `qa-full.yml` | Full gauntlet (all 4 jobs in parallel) |
| Push to `main` | `qa-full.yml` | Full gauntlet |
| Manual trigger | `qa-full.yml` | Choose which plugin to test |

### Jobs in the Full Workflow

All 4 jobs run in parallel. Total time: ~8–12 minutes.

1. **Code Quality** — PHP lint + PHPCS (WPCS + VIP) + PHPStan + asset weight
2. **E2E Tests** — Full Playwright suite via WordPress Playground (no server needed)
3. **Lighthouse CI** — Performance + accessibility + SEO scores with thresholds
4. **Compatibility Matrix** — PHP 7.4 / 8.0 / 8.1 / 8.2 / 8.3 (fail-fast: off)

Results appear as a summary table in GitHub Actions → each run → Summary tab.

### No Secrets Required

GitHub Actions uses WordPress Playground (WebAssembly) for browser tests — no server, no API keys, no paid services. Runs on free GitHub Actions minutes.

---

## Adding Tests for Your Plugin

1. Create: `tests/playwright/your-plugin/core.spec.js`
2. Copy structure from `tests/playwright/tpa/core.spec.js`
3. Replace admin URLs and CSS selectors with your plugin's
4. Create a Local WP test site (Step: Create Test Sites)
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

- [Local WP Setup Guide](docs/local-wp-setup.md) — detailed step-by-step
- [Database Profiling Guide](docs/database-profiling.md) — Query Monitor, N+1 fixes, slow log
- [Common WordPress Mistakes](docs/common-wp-mistakes.md) — what this pipeline catches automatically + how to fix them
- [Skill Commands Reference](SKILLS.md) — Claude Code skill invocations for every QA task

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
wordpress-qa-master/
├── setup/
│   ├── init.sh                    # Interactive first-run setup
│   ├── install.sh                 # 1-click dependency installer
│   └── playground-blueprint.json  # WP Playground CI config
├── tests/playwright/
│   ├── playwright.config.js        # Multi-project config (desktop + mobile + tablet)
│   ├── auth.setup.js               # Save admin cookies once
│   ├── tpa/
│   │   ├── core.spec.js            # TPA: admin, editor, frontend, a11y, visual
│   │   └── responsive.spec.js      # TPA: mobile/tablet/desktop viewports
│   └── nexterwp/
│       └── core.spec.js            # NexterWP: theme, blocks, extension, visual
├── config/
│   ├── phpcs.xml                   # WPCS + VIP + PHPCompatibility rules
│   ├── phpstan.neon                # Level 5 static analysis
│   └── lighthouserc.json           # Performance/a11y thresholds
├── scripts/
│   ├── gauntlet.sh                 # Full pre-release pipeline
│   ├── changelog-test.sh           # Maps changelog → targeted tests
│   ├── compare-versions.sh         # Version A vs B diff
│   ├── competitor-compare.sh       # Download + analyze competitor plugins
│   └── db-profile.sh              # MySQL slow log + WP-CLI query profiling
├── .github/workflows/
│   ├── qa-full.yml                 # 4 parallel jobs: code + E2E + Lighthouse + matrix
│   └── qa-quick.yml               # Fast PR check (changed files only)
├── checklists/
│   ├── pre-release-checklist.md
│   ├── ui-ux-checklist.md
│   ├── performance-checklist.md
│   └── security-checklist.md
├── docs/
│   ├── local-wp-setup.md
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

## Contributing / Extending

This repo is designed to grow. Good contributions:
- New test specs for specific widget/block types
- Plugin-type-specific PHPCS rule additions
- Additional competitor analysis metrics
- Performance regression rules
- New skill invocation patterns in SKILLS.md

Keep it research-first. If adding a check: link to the standard or incident that motivated it.

---

*Built for [POSIMYTH Innovation](https://posimyth.com) — makers of The Plus Addons for Elementor, NexterWP, UiChemy.*
