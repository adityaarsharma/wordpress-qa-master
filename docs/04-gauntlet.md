# The Gauntlet — All 11 Steps Explained

> Every step in `gauntlet.sh`, what it checks, what failure looks like, and exactly how to fix it.

---

## Table of Contents

1. [Running the Gauntlet](#1-running-the-gauntlet)
2. [Step 1 — PHP Lint](#2-step-1--php-lint)
3. [Step 2 — WordPress Coding Standards (PHPCS)](#3-step-2--wordpress-coding-standards-phpcs)
4. [Step 3 — PHPStan Static Analysis](#4-step-3--phpstan-static-analysis)
5. [Step 4 — Asset Weight Audit](#5-step-4--asset-weight-audit)
6. [Step 5 — i18n / POT File Check](#6-step-5--i18n--pot-file-check)
7. [Step 6 — Playwright Tests](#7-step-6--playwright-tests)
8. [Step 7 — Lighthouse Performance](#8-step-7--lighthouse-performance)
9. [Step 8 — Database Profiling](#9-step-8--database-profiling)
10. [Step 9 — Competitor Comparison](#10-step-9--competitor-comparison)
11. [Step 10 — UI / Frontend Performance](#11-step-10--ui--frontend-performance)
12. [Step 11 — Claude Skill Audits](#12-step-11--claude-skill-audits)
13. [Reading the Final Report](#13-reading-the-final-report)
14. [CI Mode vs Local Mode](#14-ci-mode-vs-local-mode)

---

## 1. Running the Gauntlet

```bash
# Full run (all 11 steps) — recommended before every release
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

# Quick run (Steps 1–6 only) — for rapid development iteration
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode quick

# With qa.config.json present (no --plugin needed)
cd ~/Claude/orbit
bash scripts/gauntlet.sh

# Against a specific environment
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --env ci

# Point at staging
WP_TEST_URL=https://staging.example.com bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin
```

### Flags

| Flag | Values | Default | Description |
|---|---|---|---|
| `--plugin` | path | (from config) | Absolute path to plugin folder |
| `--mode` | `full`, `quick` | `full` | `quick` skips Steps 7–11 |
| `--env` | `local`, `ci` | `local` | `ci` disables interactive prompts |

### Exit codes

| Code | Meaning |
|---|---|
| `0` | All passed (or passed with warnings) |
| `1` | One or more failures — **do not release** |

---

## 2. Step 1 — PHP Lint

**What it does**: Runs `php -l` on every `.php` file in the plugin (excluding `vendor/`, `node_modules/`). Catches parse errors and syntax mistakes.

**Command used**:
```bash
find "$PLUGIN_PATH" -name "*.php" \
  -not -path "*/vendor/*" -not -path "*/node_modules/*" \
  -exec php -l {} \;
```

**Pass condition**: Zero syntax errors.

**Example failure**:
```
Parse error: syntax error, unexpected '}' in /plugins/my-plugin/includes/class-settings.php on line 47
```

**Fix**: Open the file at the reported line. Common causes:
- Missing `;` at end of statement
- Unmatched `{` or `}`
- Curly-quoted strings from copying from Google Docs (use real apostrophes)

**Tip**: Add PHP lint as a pre-commit hook so this never reaches the gauntlet:
```bash
# .git/hooks/pre-commit
find . -name "*.php" -not -path "*/vendor/*" -exec php -l {} \; | grep -v "No syntax errors"
```

---

## 3. Step 2 — WordPress Coding Standards (PHPCS)

**What it does**: Runs PHP_CodeSniffer with the full WordPress + VIP + PHPCompatibility ruleset (`config/phpcs.xml`). Catches security issues, API misuse, escaping violations, nonce missing, and PHP version compatibility issues.

**Rules always active** (never excluded):
- `WordPress.Security.EscapeOutput` — every output must be escaped
- `WordPress.Security.NonceVerification` — every form/AJAX must verify nonce
- `WordPress.DB.PreparedSQL` — no raw SQL
- `WordPress.WP.Capabilities` — capability checks must use standard caps
- `PHPCompatibilityWP` — PHP 7.4+ compatibility

**Pass condition**: Zero `ERROR` level violations. Up to 9 warnings allowed (warns but passes).

**Example failure output**:
```
FILE: /plugins/my-plugin/includes/class-admin.php
----------------------------------------------------------------------
FOUND 3 ERRORS AND 1 WARNING AFFECTING 4 LINES
----------------------------------------------------------------------
 23 | ERROR | Missing nonce verification
 45 | ERROR | All output should be run through an escaping function
 67 | ERROR | Use $wpdb->prepare() or similar to prevent possible SQL injection
 91 | WARNING | Detected usage of a non-sanitized input variable
```

**Fix examples**:

```php
// Line 23 — Missing nonce
// BAD
if ( isset( $_POST['action'] ) ) {
    // process form
}

// GOOD
if ( isset( $_POST['action'] ) && check_admin_referer( 'my_action_nonce' ) ) {
    // process form
}

// Line 45 — Missing escape
// BAD
echo $_GET['message'];

// GOOD
echo esc_html( $_GET['message'] );

// Line 67 — Unprepared SQL
// BAD
$wpdb->query( "DELETE FROM $wpdb->posts WHERE ID = " . $_GET['id'] );

// GOOD
$wpdb->query(
    $wpdb->prepare( "DELETE FROM $wpdb->posts WHERE ID = %d", intval( $_GET['id'] ) )
);
```

**Running PHPCS manually with full output**:
```bash
phpcs \
  --standard=config/phpcs.xml \
  --extensions=php \
  --ignore=vendor,node_modules \
  --report=full \
  ~/plugins/my-plugin

# Attempt auto-fix (safe transformations only)
phpcbf \
  --standard=config/phpcs.xml \
  --extensions=php \
  --ignore=vendor,node_modules \
  ~/plugins/my-plugin
```

---

## 4. Step 3 — PHPStan Static Analysis

**What it does**: Static analysis for type errors, undefined variables, impossible conditions, and logic bugs that PHPCS doesn't catch.

**Level**: Level 5 by default (catches the most common real bugs without too much noise).

**Example failures**:
```
Line 42: Call to method get_value() on possibly null value of type WP_Post|null
Line 78: Parameter $post of method save() has invalid type My_Plugin\Post
Line 103: Function my_plugin_get_item() should return string but return statement is missing
```

**Fix examples**:

```php
// Line 42 — Null check missing
// BAD
$post = get_post( $id );
echo $post->post_title;  // $post could be null

// GOOD
$post = get_post( $id );
if ( ! $post instanceof WP_Post ) {
    return;
}
echo esc_html( $post->post_title );

// Line 103 — Missing return
// BAD
function my_plugin_get_item( $id ) {
    if ( $id > 0 ) {
        return get_post( $id );
    }
    // No return for the else case — PHPStan catches this
}

// GOOD
function my_plugin_get_item( $id ) {
    if ( $id > 0 ) {
        return get_post( $id );
    }
    return null;
}
```

**Running PHPStan manually**:
```bash
phpstan analyse \
  --configuration=config/phpstan.neon \
  --level=5 \
  ~/plugins/my-plugin/includes

# More verbose output
phpstan analyse --configuration=config/phpstan.neon --level=5 --debug ~/plugins/my-plugin/includes
```

**PHPStan is a warning** in the gauntlet (won't fail a release) but should be reviewed. Level-5 errors represent real bugs.

---

## 5. Step 4 — Asset Weight Audit

**What it does**: Counts total KB/MB of all `.js` and `.css` files in the plugin (excluding `node_modules/` and `.min.js` build artifacts).

**This is informational** — it never fails the gauntlet, but it establishes a baseline. Compare across releases to catch accidental bundle bloat.

**Example output**:
```
✓ JS total: 0.84MB | CSS total: 156KB
```

**Red flags**:
- JS > 1MB without a complex interactive feature justifying it
- CSS > 500KB for a simple UI
- A release bumps bundle size by >10% without explanation

**Reducing bundle size**:
```bash
# See what's in your JS bundle
npx source-map-explorer ~/plugins/my-plugin/assets/js/main.js

# Find unused CSS
npx purgecss \
  --css ~/plugins/my-plugin/assets/css/frontend.css \
  --content http://localhost:8881

# Orbit skill prompt
claude "/performance-engineer Analyze asset bloat for ~/plugins/my-plugin. Check: unused JS (source-map), purge CSS, code splitting opportunities."
```

---

## 6. Step 5 — i18n / POT File Check

**What it does**:
1. Runs `wp i18n make-pot` to generate a fresh `.pot` file
2. Counts translatable strings
3. Scans for `echo '...'` patterns not wrapped in `__()` or `_e()`

**Pass condition**: POT file generates successfully. Warns if unwrapped strings are found.

**Example failure**:
```
⚠ POT generation failed — check plugin header + text domain
```

**Fix**: Your plugin header must declare the text domain:
```php
/**
 * Plugin Name: My Plugin
 * Text Domain: my-plugin
 * Domain Path: /languages
 */
```

And `Text Domain` must match every `__( 'string', 'my-plugin' )` call exactly.

**Example warning**:
```
⚠ 14 possibly untranslated echo strings — review
```

**Fix**:
```php
// BAD
echo 'Save Changes';
echo "Settings saved.";

// GOOD
echo esc_html__( 'Save Changes', 'my-plugin' );
echo esc_html__( 'Settings saved.', 'my-plugin' );
```

**Running the i18n check manually**:
```bash
# From inside your plugin directory
wp i18n make-pot . languages/my-plugin.pot

# Check for untranslated strings
grep -rE "echo\s+['\"]" . --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules \
  | grep -vE "(__\(|_e\(|esc_html__|esc_attr__|_x\(|_n\()"
```

---

## 7. Step 6 — Playwright Tests

**What it does**: Runs the full Playwright test suite for your plugin — functional tests, visual snapshots, and accessibility checks.

**Test projects run** (from `playwright.config.js`):
- `setup` — logs in once, saves cookies to `.auth/wp-admin.json`
- `chromium` — all functional tests (authenticated as admin)
- `visual` — full-page screenshots for visual regression
- `video` (if flow specs exist) — records every test as video

**Pass condition**: Zero failed tests.

**Example failure output**:
```
✗ Playwright — 2 failed, 14 passed

  FAILED tests/playwright/my-plugin/core.spec.js:
    ✗ admin panel loads without errors (expected to find .my-plugin-dashboard, not found)
    ✗ settings save persists (timeout waiting for success notice)
```

**Debug a Playwright failure**:

```bash
# Open the HTML report — click failed test to see screenshot + trace
npx playwright show-report reports/playwright-html

# Re-run in debug mode (opens inspector)
npx playwright test tests/playwright/my-plugin/core.spec.js --debug

# Re-run with visible browser (no headless)
npx playwright test tests/playwright/my-plugin/core.spec.js --headed --slowMo=1000

# Run just the failing test
npx playwright test -g "admin panel loads"
```

**Auth issues** — if tests redirect to login:
```bash
# Delete stale auth file and re-run setup
rm .auth/wp-admin.json
npx playwright test --project=setup
```

**View visual comparison after snapshot failure**:
```bash
npx playwright show-report reports/playwright-html
# Click the failed snapshot test
# → Shows baseline / actual / diff side-by-side
```

**Update snapshots** when intentional UI changes are made:
```bash
npx playwright test --update-snapshots
```

**Flow tests and video recording**: If you have tests in `tests/playwright/flows/`, the gauntlet also runs the `video` project, recording every test and generating a PM-friendly HTML report at `reports/uat-report-TIMESTAMP.html`.

---

## 8. Step 7 — Lighthouse Performance

**What it does**: Runs Google Lighthouse against the test site homepage. Measures Core Web Vitals + overall performance score.

**Mode**: Only runs in `--mode full`. Skipped in `--mode quick`.

**Pass condition**: Performance score ≥ 75 (warn). Fail if < 60.

**Example output**:
```
✓ Lighthouse performance: 82/100
```

**Example failure**:
```
⚠ Lighthouse performance: 58/100 (target: 80+)
```

**What tanks Lighthouse scores**:
- JS files not deferred/async (`wp_enqueue_script` without `true` for footer)
- Render-blocking CSS in `<head>` that isn't needed above the fold
- Missing `width`/`height` on `<img>` tags (causes CLS)
- Large images not optimized
- Plugin adding CSS/JS on pages that don't need it

**Fix — load assets in footer**:
```php
// BAD
wp_enqueue_script( 'my-plugin', MY_PLUGIN_URL . 'app.js', ['jquery'] );
//                                                          ^^^^^^^ — in header

// GOOD
wp_enqueue_script( 'my-plugin', MY_PLUGIN_URL . 'app.js', ['jquery'], MY_PLUGIN_VERSION, true );
//                                                                                         ^^^^ — in footer
```

**Fix — conditional asset loading**:
```php
function my_plugin_assets() {
    // Only load on pages that actually use the shortcode
    global $post;
    if ( is_a( $post, 'WP_Post' ) && has_shortcode( $post->post_content, 'my_plugin' ) ) {
        wp_enqueue_style( 'my-plugin', MY_PLUGIN_URL . 'style.css', [], MY_PLUGIN_VERSION );
        wp_enqueue_script( 'my-plugin', MY_PLUGIN_URL . 'app.js', [], MY_PLUGIN_VERSION, true );
    }
}
add_action( 'wp_enqueue_scripts', 'my_plugin_assets' );
```

**Running Lighthouse manually**:
```bash
lighthouse http://localhost:8881 \
  --output=html \
  --output-path=reports/lighthouse-manual.html \
  --chrome-flags="--headless --no-sandbox"

open reports/lighthouse-manual.html
```

---

## 9. Step 8 — Database Profiling

**What it does**: Measures query count per page type and captures slow queries (>50ms) using MySQL `performance_schema` and WordPress `SAVEQUERIES`.

**Mode**: Only runs in `--mode full --env local`. Skipped in CI (no real MySQL) and `--mode quick`.

**Output**: `reports/db-profile-TIMESTAMP.txt`

**Pass condition**: Informational only. Gauntlet warns if query counts exceed thresholds in `qa.config.json`.

**Example output**:
```
Homepage:        28 queries | 142ms total
Single post:     24 queries | 118ms
Admin panel:     67 queries | 289ms   ← WARNING
```

**Red flags**: See [docs/database-profiling.md](database-profiling.md) for full guidance.

**Running DB profile manually**:
```bash
bash scripts/db-profile.sh
cat reports/db-profile-*.txt
```

---

## 10. Step 9 — Competitor Comparison

**What it does**: If `qa.config.json` has a `competitors` list, installs the competitor plugins in wp-env and runs the comparison flow tests from `tests/playwright/flows/`.

**Pass condition**: Comparison tests complete. Generates screenshots + UAT HTML report.

**Example output**:
```
✓ Competitor analysis complete — see reports/competitor-*.md
```

**Setting up competitor comparison**:

1. Add competitor slugs to `qa.config.json`:
```json
"competitors": ["wordpress-seo", "rank-math-seo"]
```

2. Copy the SEO test template:
```bash
cp -r tests/playwright/templates/seo-plugin tests/playwright/flows/seo-compare
```

3. Run the discovery test first to get exact nav URLs:
```bash
npx playwright test tests/playwright/flows/seo-compare/core.spec.js -g "Discovery" --headed
```

4. Fill in the pair tests with the discovered URLs.

Full competitor testing guide: [docs/07-test-templates.md](07-test-templates.md)

---

## 11. Step 10 — UI / Frontend Performance

**What it does**: Measures editor performance (Elementor or Gutenberg) or frontend page load time depending on `plugin.type` in config.

**For Elementor addons** (`type: "elementor-addon"`):
- Runs `scripts/editor-perf.sh`
- Measures: editor ready time, widget insert time, memory per widget
- Output: `reports/editor-perf-TIMESTAMP.json`

**For Gutenberg blocks** (`type: "gutenberg-blocks"`):
- Measures block insert latency via Playwright
- Measures React render performance

**For all other plugins**:
- Measures frontend page load time via `curl`
- Reports: total load time + TTFB (Time to First Byte)

**Example output (Elementor)**:
```
✓ Editor performance measured — see reports/editor-perf-20240115-143022.json
  Editor ready: 2840ms | Panel populated: 410ms
  Slowest widget: Hero Section — 950ms insert, 420ms render
```

**Red flags**:
- Editor ready > 6 seconds
- Any widget insert > 1.5 seconds
- Memory growth > 250MB over 20 widgets

See [docs/deep-performance.md](deep-performance.md) for detailed interpretation.

---

## 12. Step 11 — Claude Skill Audits

**What it does**: Launches 6 Claude Code skill agents in parallel, each reading your plugin code and writing a markdown audit report.

**Mode**: Only runs in `--mode full` when `claude` CLI is installed.

**Timeline**: 3–6 minutes (all 6 run simultaneously).

### The 6 skills

```
Plugin PHP files
        │
   ┌────┴────────────────────────────────────────────────────┐
   │                                                          │
   ▼                                                          ▼
/wordpress-plugin-development              /wordpress-penetration-testing
WP standards, hooks, escaping,             OWASP Top 10: XSS, CSRF, SQLi,
nonces, capabilities, i18n                 auth bypass, path traversal
   │                                                          │
   ▼                                                          ▼
/performance-engineer                      /database-optimizer
Hook weight, N+1 queries,                  Prepared statements, autoload
blocking assets, expensive loops           bloat, indexes, transient misuse
   │                                                          │
   ▼                                                          ▼
/accessibility-compliance-                 /code-review-excellence
accessibility-audit                        Dead code, complexity,
WCAG 2.2 AA — admin UI + frontend          error handling, type safety
   │                                                          │
   └──────────────────────┬──────────────────────────────────┘
                          │
                          ▼
        reports/skill-audits/
        ├── wp-standards.md
        ├── security.md
        ├── performance.md
        ├── database.md
        ├── accessibility.md
        ├── code-quality.md
        └── index.html    ← dark-mode tabbed HTML report
```

### Example output

```
✓ Skill audits complete — 6 reports written
✓ Skill audit HTML report: reports/skill-audits/index.html
⚠ Critical findings found — review reports/skill-audits/security.md before release
```

### Opening the HTML report

```bash
open reports/skill-audits/index.html
```

The report has 6 tabs (one per skill) with:
- Severity summary at the top (Critical / High / Medium / Low counts)
- Color-coded findings with file:line references
- Code examples showing the bad pattern + the fix

### Running skills manually (without gauntlet)

```bash
P=~/plugins/my-plugin

# All 6 in parallel
claude "/wordpress-plugin-development Audit $P — WP standards, hooks, escaping. Output markdown." > reports/skill-audits/wp-standards.md &
claude "/wordpress-penetration-testing Security audit $P — OWASP Top 10. Output markdown." > reports/skill-audits/security.md &
claude "/performance-engineer Analyze $P — hook weight, N+1, assets. Output markdown." > reports/skill-audits/performance.md &
claude "/database-optimizer Review $P — queries, indexes, autoload. Output markdown." > reports/skill-audits/database.md &
claude "/accessibility-compliance-accessibility-audit Audit $P admin UI + frontend. Output markdown." > reports/skill-audits/accessibility.md &
claude "/code-review-excellence Review $P — quality, complexity. Output markdown." > reports/skill-audits/code-quality.md &
wait
```

### Skills deep-dive

→ [docs/05-skills.md](05-skills.md) for what each skill finds, real vulnerability examples, and how to run add-on skills for specific plugin types.

---

## 13. Reading the Final Report

After the gauntlet, you'll see:

```
=================================
Results: 9 passed | 2 warnings | 0 failed

Reports generated:
  MD report:      /Users/you/Claude/orbit/reports/qa-report-20240115-143022.md
  Playwright:     /Users/you/Claude/orbit/reports/playwright-html/index.html
  Screenshots:    /Users/you/Claude/orbit/reports/screenshots/
  Videos:         /Users/you/Claude/orbit/reports/videos/
  Skill audits:   /Users/you/Claude/orbit/reports/skill-audits/index.html

View Playwright:   npx playwright show-report reports/playwright-html
View skill audits: open reports/skill-audits/index.html

⚠ GAUNTLET PASSED WITH WARNINGS — review before release
```

### When to release

| Result | Decision |
|---|---|
| `✓ GAUNTLET PASSED` | Safe to tag and release |
| `⚠ GAUNTLET PASSED WITH WARNINGS` | Review warnings. Fix Critical/High from skill audits first. |
| `✗ GAUNTLET FAILED` | **Do not release.** Fix failures first. |

---

## 14. CI Mode vs Local Mode

### Local (default)

- All 11 steps run
- DB profiling enabled (uses local MySQL container)
- Video recording enabled
- Skill audits enabled (Claude CLI)
- Browser opens are suppressed

### CI mode

```bash
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --env ci
```

Changes in CI mode:
- Steps 8 (DB profiling) skipped (no persistent MySQL in most CI)
- Workers set to 1 for Playwright (less parallelism for stability)
- HTML reports still generated (artifact-friendly)
- Exit codes respected (non-zero fails the CI job)

See [docs/15-ci-cd.md](15-ci-cd.md) for full GitHub Actions integration.

---

**Next**: [docs/05-skills.md](05-skills.md) — deep-dive into all 6 core skills and 5 add-on skills.
