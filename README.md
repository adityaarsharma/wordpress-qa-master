# WordPress QA Master

> Automated QA pipeline for WordPress plugins — code quality, database profiling, performance, functional testing, visual regression, and UI/UX checks. No external APIs required. Built for serious plugin teams shipping at scale.

**Covers**: The Plus Addons for Elementor · NexterWP Theme + Blocks + Extension · Any WordPress plugin

---

## Table of Contents

1. [What This Covers](#what-this-covers)
2. [How the Pipeline Works](#how-the-pipeline-works)
3. [Prerequisites](#prerequisites)
4. [Step 1 — Install Local WP](#step-1--install-local-wp)
5. [Step 2 — Create Test Sites](#step-2--create-test-sites)
6. [Step 3 — Install Dependencies](#step-3--install-dependencies)
7. [Running Tests](#running-tests)
   - [Full Pre-Release Gauntlet](#full-pre-release-gauntlet)
   - [Code Quality Tests](#code-quality-tests)
   - [Database Profiling](#database-profiling)
   - [Performance Tests](#performance-tests)
   - [Functional Tests (Playwright)](#functional-tests-playwright)
   - [Visual Regression Tests](#visual-regression-tests)
   - [Responsive Tests](#responsive-tests)
   - [Accessibility Tests](#accessibility-tests)
   - [Version Comparison](#version-comparison)
8. [CI / GitHub Actions](#ci--github-actions)
9. [Report Output](#report-output)
10. [Plugin-Specific Test Suites](#plugin-specific-test-suites)
11. [Adding Tests for Your Plugin](#adding-tests-for-your-plugin)
12. [Checklists](#checklists)
13. [Coverage Targets](#coverage-targets)
14. [Standards](#standards)

---

## What This Covers

| Layer | What It Checks | Tools | Local | CI |
|---|---|---|---|---|
| **Code Quality** | PHP syntax, WPCS, VIP standards | `php -l`, phpcs | Yes | Yes |
| **Static Analysis** | Type safety, undefined vars, dead code | PHPStan level 5 | Yes | Yes |
| **Security** | XSS, CSRF, SQLi, capability checks | phpcs security sniffs | Yes | Yes |
| **Database** | Query count, slow queries, N+1s, autoload | Query Monitor, MySQL slow log | Yes | No* |
| **Performance** | LCP, FCP, TBT, CLS, TTI, asset weight | Lighthouse CLI, @lhci/cli | Yes | Yes |
| **Functional** | Widget renders, admin panel, editor, REST | Playwright | Yes | Yes |
| **Visual Regression** | Pixel diff between releases | Playwright screenshots | Yes | Yes |
| **Responsive** | Mobile / tablet / desktop rendering | Playwright viewports | Yes | Yes |
| **Accessibility** | WCAG 2.1 AA, keyboard nav, labels | axe-core + Playwright | Yes | Yes |
| **Compatibility** | PHP 7.4–8.3 × WP 6.3–latest | GitHub Actions matrix | No | Yes |

> *Database profiling requires a real MySQL connection. Use Local WP for this layer.

---

## How the Pipeline Works

```
Your Plugin ZIP
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│  LAYER 1 — Static (no WordPress needed)                 │
│  php -l → phpcs (WPCS+VIP) → PHPStan → asset sizing    │
└─────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│  LAYER 2 — Local WP (full MySQL, real PHP)             │
│  Restore snapshot → Install zip → WP-CLI verify        │
│  Query Monitor DB profiling → MySQL slow query log     │
└─────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│  LAYER 3 — Browser (Playwright against Local WP)       │
│  Functional tests → Visual snapshots → Responsive     │
│  Accessibility (axe-core) → Console error check       │
└─────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│  LAYER 4 — Performance (Lighthouse CLI, local)         │
│  Core Web Vitals → Asset weight → Render blocking      │
└─────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│  REPORT — qa-report-{timestamp}.md                     │
│  Pass / Warn / Fail per layer + version comparison     │
└─────────────────────────────────────────────────────────┘
```

In CI (GitHub Actions), Layers 2 and 3 use WordPress Playground instead of Local WP. Layer 2 DB profiling is local-only.

---

## Prerequisites

Before anything else, confirm you have:

| Tool | Min Version | Check |
|---|---|---|
| macOS | 12+ (Monterey) | `sw_vers` |
| PHP | 7.4+ | `php -v` |
| Node.js | 18+ | `node -v` |
| Composer | 2.x | `composer --version` |
| Git | any | `git --version` |

If Node or PHP are missing, the install script handles them.

---

## Step 1 — Install Local WP

**Local WP** (by Flywheel) is the required local environment. It gives you:
- Real MySQL 8.0 database (needed for query profiling)
- Real PHP execution (not simulated)
- Snapshot/restore in 5 seconds (clean state before every test run)
- WP-CLI built in (automate everything via terminal)
- SSH access to each site
- Multiple sites running simultaneously

### Download

Go to **https://localwp.com** → click **Download** → choose macOS.

Current stable version: **Local 9.x** (as of 2026). Always download the latest stable from the site — do not use older versions as they have issues with Apple Silicon.

**macOS Apple Silicon (M1/M2/M3/M4)**: Download the `arm64` build. Local 9.x is fully native on Apple Silicon.

**macOS Intel**: Download the `x64` build.

### Install

1. Open the `.dmg` file
2. Drag **Local** to your Applications folder
3. Open Local — it will ask for your admin password to set up networking
4. Sign in or create a free account (required for Local, free tier is sufficient)

### Verify WP-CLI Works

After installing, open Terminal and test:

```bash
# Local adds WP-CLI to your PATH — verify:
wp --version
# Should print: WP-CLI 2.x.x
```

If `wp` is not found, add Local's WP-CLI to your PATH:

```bash
# Add to ~/.zshrc
export PATH="/Applications/Local.app/Contents/Resources/extraResources/lightning-services/php-8.1.x/bin/WP-CLI:$PATH"
source ~/.zshrc
```

---

## Step 2 — Create Test Sites

You need two dedicated test sites — one per product under test. These are isolated from your real dev/staging sites.

### Create Site: tpa-test (The Plus Addons)

1. Open Local WP → click **+** (bottom left)
2. Choose **Create a new site**
3. Site name: `tpa-test`
4. Click **Continue**
5. Choose **Custom** environment:
   - PHP: **8.1** (best compatibility range for TPA)
   - Web server: **nginx** (matches most production hosts)
   - MySQL: **8.0**
6. Click **Continue**
7. WordPress username: `admin` | Password: `password` | Email: `admin@example.com`
8. Click **Add Site**

Local will provision the site. Takes ~30 seconds.

### Create Site: nexterwp-test (NexterWP)

Repeat the same steps, site name: `nexterwp-test`.

### Your Sites Will Be At

```
http://tpa-test.local      (or a similar .local domain — check Local app)
http://nexterwp-test.local
```

Check the exact URL in Local WP → click the site → see **Site Domain** at the top.

### Install Plugins on Each Site

Open the **site shell** in Local (right-click site → Open Site Shell), then:

```bash
# ── TPA Test Site ──────────────────────────────────────────────
export WP_TPA="$HOME/Local Sites/tpa-test/app/public"

# Required: Elementor (TPA depends on it)
wp --path="$WP_TPA" plugin install elementor --activate

# Required: Query Monitor (DB profiling)
wp --path="$WP_TPA" plugin install query-monitor --activate

# Your plugin (replace path with actual zip location)
wp --path="$WP_TPA" plugin install ~/Downloads/the-plus-addons.zip --activate --force

# ── NexterWP Test Site ─────────────────────────────────────────
export WP_NWP="$HOME/Local Sites/nexterwp-test/app/public"

wp --path="$WP_NWP" plugin install query-monitor --activate
wp --path="$WP_NWP" theme  install ~/Downloads/nexterwp-theme.zip --activate --force
wp --path="$WP_NWP" plugin install ~/Downloads/nexter-blocks.zip --activate --force
wp --path="$WP_NWP" plugin install ~/Downloads/nexter-extension.zip --activate --force
```

### Create Test Content

```bash
# Create a test page for each product
wp --path="$WP_TPA" post create \
  --post_title="TPA Widget Test Page" \
  --post_type=page \
  --post_status=publish \
  --post_name=tpa-test

wp --path="$WP_NWP" post create \
  --post_title="NexterWP Block Test Page" \
  --post_type=page \
  --post_status=publish \
  --post_name=nwp-test
```

### Take a Clean Snapshot

This is the most important step. With clean plugins installed:

1. Right-click your site in Local WP
2. **Snapshots** → **Save Snapshot**
3. Name it: `clean-tpa-v2.x` (include the version you're testing)

Before every test run, restore this snapshot — you get a perfectly clean database with zero test pollution.

**Restore a snapshot**:
1. Right-click site → **Snapshots** → click the snapshot → **Restore**
2. Takes ~5 seconds

### Set Environment Variables

Add these to your `~/.zshrc`:

```bash
export WP_TPA_PATH="$HOME/Local Sites/tpa-test/app/public"
export WP_NWP_PATH="$HOME/Local Sites/nexterwp-test/app/public"
export WP_TPA_URL="http://tpa-test.local"
export WP_NWP_URL="http://nexterwp-test.local"
export WP_ADMIN_USER="admin"
export WP_ADMIN_PASS="password"
```

```bash
source ~/.zshrc
```

### Enable MySQL Slow Query Log

In Local WP:
1. Click your site → **Database** tab → toggle **Enable Slow Query Log**
2. Set threshold: `0.05` seconds (50ms)

This logs any query taking over 50ms — essential for catching performance regressions.

---

## Step 3 — Install Dependencies

```bash
git clone https://github.com/adityaarsharma/wordpress-qa-master
cd wordpress-qa-master
bash setup/install.sh
```

The install script sets up:
- Node.js (via nvm if not present)
- Playwright + Chromium, Firefox browsers
- PHP_CodeSniffer + WordPress Coding Standards + VIP Coding Standards
- PHPStan + WordPress stubs
- Lighthouse CLI + LHCI
- axe-core CLI

Takes ~3–5 minutes on first run.

---

## Running Tests

### Full Pre-Release Gauntlet

Run every layer in sequence. Use this before tagging any release.

```bash
# The Plus Addons
WP_TEST_URL=$WP_TPA_URL bash scripts/gauntlet.sh \
  --plugin $WP_TPA_PATH \
  --env local

# NexterWP
WP_TEST_URL=$WP_NWP_URL bash scripts/gauntlet.sh \
  --plugin $WP_NWP_PATH \
  --env local

# Quick mode (skips DB profiling + Lighthouse — for fast PR checks)
bash scripts/gauntlet.sh --plugin /path/to/plugin --mode quick
```

Exit codes: `0` = all passed, `1` = failures found (do not release).

---

### Code Quality Tests

These run entirely on source code — no WordPress needed.

#### PHP Lint (syntax check)

Catches fatal parse errors before they ever hit WordPress:

```bash
find /path/to/plugin -name "*.php" \
  -not -path "*/vendor/*" \
  -exec php -l {} \; | grep -v "No syntax errors"
```

Zero output = all files are syntactically valid.

#### PHP_CodeSniffer (WPCS + VIP Standards)

Enforces WordPress coding standards, security rules, and VIP platform compatibility. The config at `config/phpcs.xml` combines three rulesets:

- **WordPress** — general WP coding style
- **WordPressVIPMinimum** — VIP platform constraints (stricter)
- **PHPCompatibilityWP** — PHP version compatibility (7.4–8.3)

Security rules (`EscapeOutput`, `NonceVerification`, `PreparedSQL`) are **never excluded**.

```bash
# Run against your plugin
phpcs --standard=config/phpcs.xml /path/to/plugin

# Show only errors (hide warnings)
phpcs --standard=config/phpcs.xml --severity=8 /path/to/plugin

# Auto-fix what's fixable
phpcbf --standard=config/phpcs.xml /path/to/plugin
```

**What it catches**:
- Missing `esc_html()` / `esc_attr()` on output
- Missing nonce checks on form submissions and AJAX
- Direct SQL queries without `$wpdb->prepare()`
- Missing capability checks before privileged actions
- PHP version incompatibilities (e.g. `readonly` properties on PHP 7.4)

#### PHPStan (static analysis)

Finds type errors, undefined variables, and logic bugs without running the code:

```bash
phpstan analyse --configuration=config/phpstan.neon /path/to/plugin/includes
```

Level 5 catches: type mismatches, nullable dereferences, dead code paths, incorrect argument types.

---

### Database Profiling

Requires Local WP running with Query Monitor active.

```bash
# Profile key pages
WP_PATH="$WP_TPA_PATH" WP_TEST_URL="$WP_TPA_URL" \
  TEST_PAGES="/,/tpa-test/,/wp-admin/admin.php?page=tpa_dashboard" \
  bash scripts/db-profile.sh
```

Output shows per-page:
- Total DB query count
- Load time (ms)
- Slow queries flagged (>100ms)
- Slow query log entries from MySQL

**What to look for**:

| Finding | What It Means | Action |
|---|---|---|
| Query count >60 on frontend | Too many queries | Cache meta, use `update_postmeta_cache()` |
| Same query repeated >5x | N+1 pattern | Batch with `post__in` |
| Any query >100ms | Missing index or bad query | Check `wp_postmeta` index, use `EXPLAIN` |
| Autoloaded option >10KB | Bloating every page load | Set `autoload = 'no'` |

See [docs/database-profiling.md](docs/database-profiling.md) for detailed fix patterns.

---

### Performance Tests

All performance testing uses Lighthouse CLI — no external API required.

#### Run Lighthouse Locally

```bash
# Against Local WP (full report)
lighthouse $WP_TPA_URL \
  --output=html \
  --output-path=reports/lighthouse/tpa-$(date +%Y%m%d).html \
  --chrome-flags="--headless --no-sandbox"

# Open report
open reports/lighthouse/tpa-$(date +%Y%m%d).html

# Quick score only
lighthouse $WP_TPA_URL --output=json --quiet \
  | python3 -c "import json,sys; d=json.load(sys.stdin); \
    print('Performance:', int(d['categories']['performance']['score']*100), \
    '| A11y:', int(d['categories']['accessibility']['score']*100), \
    '| SEO:', int(d['categories']['seo']['score']*100))"
```

#### What Lighthouse Measures

| Metric | Target | What It Is |
|---|---|---|
| **Performance score** | ≥ 80 | Weighted average of all metrics |
| **LCP** (Largest Contentful Paint) | < 2.5s | When main content loads |
| **FCP** (First Contentful Paint) | < 1.8s | When first content appears |
| **TBT** (Total Blocking Time) | < 200ms | JS blocking the main thread |
| **CLS** (Cumulative Layout Shift) | < 0.1 | Visual stability (no content jumping) |
| **TTI** (Time to Interactive) | < 3.8s | When page responds to user input |
| **Accessibility score** | ≥ 85 | Color contrast, labels, roles |

#### Asset Weight Check

```bash
# JS total size (unminified source)
find /path/to/plugin -name "*.js" -not -path "*/node_modules/*" \
  | xargs wc -c | tail -1

# CSS total size
find /path/to/plugin -name "*.css" \
  | xargs wc -c | tail -1

# Find largest files
find /path/to/plugin \( -name "*.js" -o -name "*.css" \) \
  -not -path "*/node_modules/*" \
  | xargs wc -c | sort -rn | head -10
```

A 200KB unminified JS file = ~60KB minified+gzipped. Flag anything that grew >10% between releases.

#### Lighthouse CI (automated thresholds)

The `config/lighthouserc.json` defines pass/warn/fail thresholds used in both local gauntlet runs and GitHub Actions:

```bash
# Run LHCI against any URL
lhci autorun --config=config/lighthouserc.json \
  --collect.url=$WP_TPA_URL
```

---

### Functional Tests (Playwright)

Playwright drives a real Chromium browser against your Local WP site. Tests assert actual behavior, not just "page loaded."

#### First Run — Set Up Auth

Save admin cookies so tests don't log in every time:

```bash
WP_TEST_URL=$WP_TPA_URL npx playwright test \
  tests/playwright/auth.setup.js \
  --project=setup
```

This creates `.auth/wp-admin.json`. All subsequent tests reuse these cookies.

#### Run The Plus Addons Tests

```bash
# All TPA tests
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/

# Specific test file
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/core.spec.js

# With browser visible (headed mode — watch what's happening)
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/ --headed

# Debug single test
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/ --debug
```

#### Run NexterWP Tests

```bash
WP_TEST_URL=$WP_NWP_URL npx playwright test tests/playwright/nexterwp/
```

#### What Each Test File Does

**`tpa/core.spec.js`**:
- Admin panel loads without PHP fatal errors or notice banners
- Widgets list page renders toggles
- Elementor editor loads with TPA widgets panel visible
- TPA widget category appears when searching in Elementor
- Frontend page has zero JS console errors from TPA files
- Page loads within 4-second budget
- No broken images (width === 0 check)
- axe-core WCAG 2.1 AA scan on homepage
- Visual regression screenshots (homepage + test page)

**`tpa/responsive.spec.js`**:
- Page at 375px (iPhone), 768px (iPad), 1440px (desktop) — no horizontal scroll
- Per-viewport visual snapshots
- Mobile nav (hamburger) opens and shows menu
- Touch targets ≥ 44×44px check

**`nexterwp/core.spec.js`**:
- Theme active, no critical admin notices
- WordPress Customizer loads
- Block editor loads with Nexter Blocks in inserter
- Nexter Blocks admin page, Nexter Extension settings — no fatal errors
- Homepage zero JS errors from Nexter files
- Header builder visible
- Footer renders
- Single post template renders
- No horizontal overflow
- Load within 4s budget
- Zero CSS/JS 404 responses
- WCAG 2.1 AA scan
- Visual snapshots

#### Open Test Report

```bash
npx playwright show-report reports/playwright-html
```

HTML report shows: pass/fail per test, screenshots on failure, video replay, trace viewer.

---

### Visual Regression Tests

Playwright compares pixel-level screenshots between runs. First run creates the baseline; every subsequent run diffs against it.

#### Set Baseline (Before a Release)

```bash
# Set baseline on current version
WP_TEST_URL=$WP_TPA_URL npx playwright test --update-snapshots
```

Screenshots saved to `tests/playwright/tpa/*.png-snapshots/`.

#### Verify New Version Doesn't Break Design

```bash
# Restore Local WP snapshot → Install new plugin zip → Then:
WP_TEST_URL=$WP_TPA_URL npx playwright test

# If visual diff found, report shows pixel diff image
# Review: intentional change? Update baseline. Regression? Fix before release.
```

Threshold is set to `maxDiffPixelRatio: 0.02` (2% of pixels can differ — allows for font rendering variance). Adjust in test files if needed.

---

### Responsive Tests

Tests every page at three viewport sizes simultaneously:

```bash
# Run only responsive tests
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/responsive.spec.js \
  --project=chromium --project=mobile-chrome --project=tablet
```

What it checks at each viewport:
- No horizontal scroll (most common responsive bug)
- Navigation accessible (hamburger opens on mobile)
- Touch targets ≥ 44×44px on mobile
- Visual snapshot per viewport (catches layout breaks)

---

### Accessibility Tests

axe-core runs against every major page and reports WCAG 2.1 AA violations:

```bash
# Run accessibility tests
WP_TEST_URL=$WP_TPA_URL npx playwright test \
  --grep="Accessibility" \
  tests/playwright/tpa/core.spec.js

# Standalone axe-core CLI scan
axe $WP_TPA_URL --tags wcag2a,wcag2aa
```

**What it catches**: missing alt text, insufficient color contrast, form inputs without labels, buttons without accessible names, heading order violations, keyboard navigation issues.

Critical/serious violations fail the test. Moderate/minor are logged as warnings.

---

### Version Comparison

Compare two plugin versions across every metric:

```bash
bash scripts/compare-versions.sh \
  --old ~/Downloads/the-plus-addons-v2.3.zip \
  --new ~/Downloads/the-plus-addons-v2.4.zip
```

Output in `reports/compare-{timestamp}.md`:

```
Plugin Version Comparison
=========================
Old: the-plus-addons-v2.3
New: the-plus-addons-v2.4

Code Quality
------------
PHPCS Errors:    0 → 0     ✓
PHPCS Warnings:  14 → 11   ✓ improved

Asset Size
----------
JS:   1,180KB → 1,204KB  +24KB
CSS:    340KB → 338KB    -2KB

Visual Regression
-----------------
Run Playwright twice to compare screenshots:
  WP_PLUGIN_VERSION=old npx playwright test --update-snapshots
  (install new zip + restore snapshot)
  WP_PLUGIN_VERSION=new npx playwright test
```

---

## CI / GitHub Actions

Two workflows included:

### `qa-quick.yml` — Runs on Every Pull Request

Fast check on only the files changed in the PR:
- PHP lint on changed `.php` files only
- PHPCS on changed `.php` files only
- Playwright smoke test against WP Playground

Takes ~3–4 minutes. Gives fast signal before a full review.

### `qa-full.yml` — Runs on `release/**` and `main`

Full gauntlet in parallel jobs:
1. **Code Quality** — PHP lint + PHPCS (full plugin) + PHPStan
2. **E2E Tests** — Playwright full suite against WordPress Playground
3. **Lighthouse CI** — Performance + accessibility + SEO scores
4. **Compatibility matrix** — PHP 7.4 / 8.0 / 8.1 / 8.2 / 8.3 × WP 6.3 / 6.4 / 6.5 / latest

All jobs run in parallel. Total time: ~8–12 minutes.

Results posted as a summary table in GitHub Actions UI under each run.

#### WordPress Playground in CI

GitHub Actions uses WordPress Playground (WebAssembly) instead of Local WP. Playground spins up a full WordPress in ~20 seconds with no infrastructure. The `setup/playground-blueprint.json` configures it with Query Monitor and a test page.

No secrets or paid services required — works on free GitHub Actions minutes.

---

## Report Output

Every gauntlet run writes `reports/qa-report-{timestamp}.md`:

```
# WordPress QA Gauntlet Report
Plugin: the-plus-addons
Date:   2026-04-20 14:32:11
Mode:   full / local

## Step 1: PHP Lint
- ✓ No PHP syntax errors

## Step 2: PHPCS / WPCS
- ✓ PHPCS: 0 errors, 8 warnings

## Step 3: PHPStan
- ✓ PHPStan: clean

## Step 4: Asset Weight
- JS total: 1.18MB | CSS total: 342KB

## Step 5: Playwright
- ✓ Playwright: 48 passed, 0 failed

## Step 6: Lighthouse
- ✓ Lighthouse: 83/100

## Step 7: Database
- See reports/db-profile-20260420-143211.txt

---
## Summary
- ✓ Passed:   5
- ⚠ Warnings: 1
- ✗ Failed:   0
```

---

## Plugin-Specific Test Suites

### The Plus Addons for Elementor

```bash
# Full suite
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/ --reporter=html

# Just admin tests
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/core.spec.js \
  --grep="Admin Panel"

# Just responsive
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/responsive.spec.js

# Headed (watch browser)
WP_TEST_URL=$WP_TPA_URL npx playwright test tests/playwright/tpa/ --headed --slowMo=500
```

### NexterWP (Theme + Nexter Blocks + Nexter Extension)

```bash
# Full suite
WP_TEST_URL=$WP_NWP_URL npx playwright test tests/playwright/nexterwp/ --reporter=html

# Just block editor tests
WP_TEST_URL=$WP_NWP_URL npx playwright test tests/playwright/nexterwp/core.spec.js \
  --grep="Nexter Blocks"

# Frontend only
WP_TEST_URL=$WP_NWP_URL npx playwright test tests/playwright/nexterwp/core.spec.js \
  --grep="Frontend"
```

---

## Adding Tests for Your Plugin

1. Create `tests/playwright/your-plugin/core.spec.js`
2. Copy the structure from `tests/playwright/tpa/core.spec.js`
3. Replace selectors with your plugin's actual class names / admin URLs
4. Create a Local WP site for your plugin (see Step 2)
5. Run: `WP_TEST_URL=http://your-plugin-test.local npx playwright test tests/playwright/your-plugin/`

For a new test page add to `tests/playwright/your-plugin/core.spec.js`:

```js
test('my new widget renders correctly', async ({ page }) => {
  await page.goto('/my-test-page/');
  await page.waitForLoadState('networkidle');

  // Assert widget is visible
  await expect(page.locator('.my-widget-class')).toBeVisible();

  // Assert no JS errors from your plugin
  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text());
  });
  const pluginErrors = errors.filter(e => e.includes('my-plugin'));
  expect(pluginErrors).toHaveLength(0);

  // Visual snapshot
  await expect(page).toHaveScreenshot('my-widget.png', { maxDiffPixelRatio: 0.02 });
});
```

---

## Checklists

- [Pre-Release Checklist](checklists/pre-release-checklist.md) — full sign-off before any release
- [UI/UX Checklist](checklists/ui-ux-checklist.md) — design quality gates (animations, spacing, hit areas)
- [Performance Checklist](checklists/performance-checklist.md) — Core Web Vitals, asset loading, DB
- [Security Checklist](checklists/security-checklist.md) — XSS, CSRF, SQLi, capability checks

---

## Coverage Targets

| Metric | Minimum | Target | Block Release? |
|---|---|---|---|
| PHP syntax errors | 0 | 0 | Yes |
| PHPCS errors | 0 | 0 | Yes |
| Security findings (critical/high) | 0 | 0 | Yes |
| E2E test pass rate | 100% | 100% | Yes |
| Lighthouse performance | 75 | 85+ | Warn only |
| Lighthouse accessibility | 85 | 95+ | Yes |
| DB query regression | 0 increase | 0 increase | Warn only |
| Visual diffs (unintended) | 0 | 0 | Warn only |
| PHP unit test coverage | 60% | 80% | No |

---

## Standards

This pipeline is built on:

- [WordPress Coding Standards](https://github.com/WordPress/WordPress-Coding-Standards) — WPCS ruleset
- [WordPress VIP Coding Standards](https://github.com/Automattic/VIP-Coding-Standards) — stricter platform rules
- [10up Open Source Best Practices](https://10up.github.io/Open-Source-Best-Practices/testing/) — E2E + coverage targets
- [WordPress Playground E2E Guide](https://wordpress.github.io/wordpress-playground/guides/e2e-testing-with-playwright/) — Playwright + Playground patterns
- [make-interfaces-feel-better](https://skills.sh/jakubkrehel/make-interfaces-feel-better/make-interfaces-feel-better) — UI/UX quality principles

---

## Claude Code Integration

This repo is designed to work with Claude Code and its MCP tools. Claude can run the full gauntlet autonomously — using Playwright MCP for browser tests, Bash for scripts, and parallel audit agents for code analysis:

```bash
# Claude runs the full gauntlet with one prompt
claude "Run full QA gauntlet on ~/plugins/the-plus-addons using Local WP at http://tpa-test.local"
```

With `mcp__playwright__*` tools connected, Claude can also interactively debug failing tests, inspect the DOM, take screenshots, and fix the issues it finds — all in one session.
