# Reading Reports — Complete Guide

> How to interpret every report Orbit generates, what each number means, and exactly what action to take.

---

## Table of Contents

1. [Report Overview](#1-report-overview)
2. [Gauntlet Markdown Report](#2-gauntlet-markdown-report)
3. [Skill Audit HTML Report](#3-skill-audit-html-report)
4. [Playwright HTML Report](#4-playwright-html-report)
5. [UAT / PM Video Report](#5-uat--pm-video-report)
6. [Lighthouse JSON Report](#6-lighthouse-json-report)
7. [DB Profile Text Report](#7-db-profile-text-report)
8. [Batch Report](#8-batch-report)
9. [Severity Decision Framework](#9-severity-decision-framework)
10. [Release Sign-off Checklist](#10-release-sign-off-checklist)

---

## 1. Report Overview

After a full gauntlet run, here's where everything lives:

```
reports/
├── qa-report-20240115-143022.md         ← gauntlet summary (all 11 steps)
├── skill-audits/
│   ├── index.html                       ← tabbed HTML — open this first
│   ├── wp-standards.md                  ← raw markdown from skill 1
│   ├── security.md                      ← raw markdown from skill 2
│   ├── performance.md                   ← raw markdown from skill 3
│   ├── database.md                      ← raw markdown from skill 4
│   ├── accessibility.md                 ← raw markdown from skill 5
│   └── code-quality.md                  ← raw markdown from skill 6
├── playwright-html/
│   └── index.html                       ← Playwright test results
├── screenshots/
│   └── flows-compare/
│       ├── pair-01-dashboard-a.png      ← your plugin
│       ├── pair-01-dashboard-b.png      ← competitor
│       └── ...
├── videos/
│   ├── pair-01-dashboard-a.webm
│   └── ...
├── uat-report-20240115-143022.html      ← PM-friendly video + screenshots
├── lighthouse/
│   └── lh-20240115-143022.json         ← Lighthouse raw data
└── db-profile-20240115-143022.txt      ← database query profile
```

### Opening everything at once

```bash
open reports/skill-audits/index.html    # AI audit (most important)
npx playwright show-report reports/playwright-html  # functional tests
open reports/uat-report-*.html          # video comparison
```

---

## 2. Gauntlet Markdown Report

**File**: `reports/qa-report-TIMESTAMP.md`
**Open with**: Any markdown viewer or `cat reports/qa-report-*.md`

### Structure

```markdown
# Orbit Gauntlet Report
**Plugin**: my-plugin
**Date**: Mon Jan 15 14:30:22 2024
**Mode**: full / local
**Path**: /Users/you/plugins/my-plugin

---

## Step 1: PHP Lint
- ✓ No PHP syntax errors

## Step 2: PHPCS / WPCS
- ✗ PHPCS: 3 errors, 7 warnings

## Step 6: Playwright
- ✓ Playwright: 18 passed, 0 failed
- HTML report: reports/playwright-html/index.html

...

## Summary
- ✓ Passed: 8
- ⚠ Warnings: 2
- ✗ Failed: 1
```

### How to read it

| Symbol | Meaning | Action |
|---|---|---|
| `✓` | Passed | No action needed |
| `⚠` | Warning — passed but has issues | Review, fix if < 30 min |
| `✗` | Failed — blocks release | Fix before releasing |

**If any `✗` appears**: Do not release. Fix all failures first.

---

## 3. Skill Audit HTML Report

**File**: `reports/skill-audits/index.html`
**Open with**: `open reports/skill-audits/index.html`

This is the most important report. Six tabbed sections, one per skill audit.

### Header

At the top, severity counts across all 6 audits:

```
Orbit Skill Audit Report
Plugin: my-plugin  ·  Generated: 2024-01-15 14:30  ·  6 skills run

[3 Critical] [7 High] [14 Medium] [22 Low]
```

**Interpretation**:
- Any `Critical` or `High` → block release
- Review every `Critical` today, even if it means delaying

### Reading a finding

Each finding looks like:

```
## XSS via Reflected Input (Critical)

**File**: includes/class-admin.php:47
**Affected**: Admin panel settings page

**Bad**:
    echo '<h2>' . $_GET['message'] . '</h2>';

**Fixed**:
    echo '<h2>' . esc_html( wp_unslash( $_GET['message'] ) ) . '</h2>';

**CVSS**: 6.1 (Medium) — requires victim to visit crafted URL
```

**How to act on it**:
1. Open the file at the line number
2. Apply the fix shown
3. Re-run the gauntlet to verify

### Severity color coding

| Color | Severity | Action |
|---|---|---|
| 🔴 Red | Critical | Block release. Fix today. |
| 🟠 Orange | High | Block release. Fix in this PR. |
| 🟡 Yellow | Medium | Fix if < 30 min. Log otherwise. |
| 🟢 Green | Low / Info | Log in tech debt. |

### Tab by tab: what each skill focuses on

**WP Standards tab**: Escaping, nonces, capability checks, i18n, WP API usage
**Security tab**: Exploitable vulnerabilities — XSS, SQLi, CSRF, auth bypass
**Performance tab**: Hook callbacks, N+1 queries, asset loading, caching gaps
**Database tab**: Prepared statements, indexes, autoload bloat, query patterns
**Accessibility tab**: WCAG 2.2 AA — labels, contrast, keyboard nav, ARIA
**Code Quality tab**: Dead code, complexity, error handling, type safety

---

## 4. Playwright HTML Report

**File**: `reports/playwright-html/index.html`
**Open with**: `npx playwright show-report reports/playwright-html`

The Playwright report opens in your browser with a full test results view.

### Layout

```
Test Results — 18 passed, 2 failed, 0 skipped
Duration: 45s

✗ FAILED
  ✗ my-plugin › admin panel loads without errors
     Expected "PHP Warning" not to match /PHP Warning/i
     Screenshot: [attachment]
     Trace: [link]

✓ PASSED
  ✓ plugin activates without errors
  ✓ settings save and persist
  ✓ frontend loads without errors
  ...
```

### Debugging a failed test

1. **Click the failed test** → expands with:
   - Error message (exact assertion that failed)
   - Screenshot at the point of failure
   - Video if running in `video` project
   - Trace file (time-travel debugger)

2. **Open the Trace viewer**:
   - Click "Trace" link in the report
   - Or: `npx playwright show-trace test-results/.../trace.zip`
   - Every action has a DOM snapshot — step through like a debugger

3. **Re-run in debug mode**:
```bash
npx playwright test tests/playwright/my-plugin/ --debug
# Playwright Inspector opens — step line by line
```

4. **Watch it run**:
```bash
npx playwright test tests/playwright/my-plugin/ --headed --slowMo=1000
```

### Reading the timeline

In the Trace viewer:
- Each row is a test action (click, fill, goto, etc.)
- Click any row → see the DOM state at that moment
- "Before" and "After" snapshots for every action
- Network requests tab shows all XHR/fetch

### Screenshot diffs

For visual regression failures:
1. Click the failing snapshot test
2. You'll see 3 panels: **Expected** | **Actual** | **Diff**
3. Pink areas in Diff = what changed

If the change is intentional:
```bash
npx playwright test --update-snapshots
```

---

## 5. UAT / PM Video Report

**File**: `reports/uat-report-TIMESTAMP.html`
**Open with**: `open reports/uat-report-*.html`

This report is designed for product managers and clients — no code, just visual proof.

### Structure

```
UAT Report — 2024-01-15
═══════════════════════

PAIR 1 — Dashboard
┌─────────────────────┬─────────────────────┐
│    Our Plugin       │     Competitor      │
│ [screenshot pair]   │  [screenshot pair]  │
│ [video  pair  ]     │  [video  pair  ]    │
└─────────────────────┴─────────────────────┘

PAIR 2 — Meta Templates
[...]
```

### How pairs work

Screenshots are matched by the `PAIR-NN-slug-a/b.png` naming convention:
- `pair-01-dashboard-a.png` always appears next to `pair-01-dashboard-b.png`
- `a` = your plugin (left column)
- `b` = competitor (right column)

Videos auto-rename via `test.afterEach` in the SEO spec template.

### Who this report is for

- **PM / Product**: "Does our plugin look better than the competition?"
- **Founder review**: "Here's the QA evidence before we tag v2.0"
- **Client sign-off**: Visual evidence that features work as expected

---

## 6. Lighthouse JSON Report

**File**: `reports/lighthouse/lh-TIMESTAMP.json`
**Open with**: Parse with Python or use the Lighthouse viewer

### Key fields

```json
{
  "categories": {
    "performance": { "score": 0.82 },      // 82/100
    "accessibility": { "score": 0.94 },
    "best-practices": { "score": 0.88 },
    "seo": { "score": 0.91 }
  },
  "audits": {
    "first-contentful-paint": { "numericValue": 1240 },   // 1.24s
    "largest-contentful-paint": { "numericValue": 2100 }, // 2.1s
    "total-blocking-time": { "numericValue": 340 },       // 340ms
    "cumulative-layout-shift": { "numericValue": 0.02 },
    "speed-index": { "numericValue": 1800 }
  }
}
```

### Reading scores

| Score | Rating |
|---|---|
| 90–100 | 🟢 Good |
| 75–89 | 🟡 Needs improvement |
| < 75 | 🔴 Poor — investigate |

### Gauntlet thresholds

| Metric | Default threshold | Action if below |
|---|---|---|
| Performance | 75 | Warn in gauntlet |
| Performance | 60 | Fail in gauntlet |
| Accessibility | 85 | Warn in gauntlet |

### Extracting score quickly

```bash
python3 -c "
import json
with open('$(ls reports/lighthouse/lh-*.json | tail -1)') as f:
    d = json.load(f)
for cat, data in d['categories'].items():
    print(f'{cat}: {int(data[\"score\"]*100)}/100')
"
```

### Visualizing the report

```bash
# Convert JSON to HTML and open in browser
lighthouse --output=html \
  --output-path=reports/lighthouse/report.html \
  --config-path=reports/lighthouse/lh-latest.json

open reports/lighthouse/report.html
```

---

## 7. DB Profile Text Report

**File**: `reports/db-profile-TIMESTAMP.txt`
**Open with**: `cat reports/db-profile-*.txt`

### Structure

```
=== Orbit DB Profile — 2024-01-15 14:30 ===
Plugin: my-plugin
WP URL: http://localhost:8881

--- Homepage ---
Queries: 28
Time:    142ms
---

--- Single Post ---
Queries: 24
Time:    118ms
---

--- Admin Panel ---
Queries: 67        ← WARNING: > 50
Time:    289ms
---

--- Slow Queries (>50ms) ---
[None found]
---

--- Autoloaded Options (top 10 by size) ---
option_name             | size
my_plugin_settings      | 2.1KB
my_plugin_cache         | 48.3KB  ← WARNING: should not be autoloaded
```

### Interpreting query counts

| Page | Acceptable | Warning | Bad |
|---|---|---|---|
| Homepage | < 30 | 30–60 | > 60 |
| Single post/page | < 25 | 25–50 | > 50 |
| Archive | < 40 | 40–80 | > 80 |
| Admin panel | < 50 | 50–100 | > 100 |

### What to fix

**High query count** → Look for N+1 patterns. See [docs/database-profiling.md](database-profiling.md).

**Slow queries** → Add indexes or rewrite the query. See examples in [docs/database-profiling.md](database-profiling.md).

**Large autoloaded options** → Add `false` as third parameter to `update_option()` for large data.

### Compare before/after

```bash
# Baseline (before your change)
bash scripts/db-profile.sh
cp reports/db-profile-*.txt reports/db-before.txt

# After your change
bash scripts/db-profile.sh
cp reports/db-profile-*.txt reports/db-after.txt

# Diff
diff reports/db-before.txt reports/db-after.txt
```

---

## 8. Batch Report

**File**: `reports/batch-TIMESTAMP.md`
**Open with**: Any markdown viewer

When running `batch-test.sh`, each plugin gets a row:

```markdown
# Orbit Batch Report
Date: 2024-01-15
Plugins: 4
Concurrency: 2

| Plugin | Status | Pass | Warn | Fail | Log |
|---|---|---|---|---|---|
| my-plugin-free | ✓ | 9 | 2 | 0 | [log](batch-logs/my-plugin-free-20240115.log) |
| my-plugin-pro | ✗ | 7 | 3 | 2 | [log](batch-logs/my-plugin-pro-20240115.log) |
| other-plugin | ✓ | 11 | 0 | 0 | [log](batch-logs/other-plugin-20240115.log) |
| legacy-plugin | ⚠ | 6 | 5 | 0 | [log](batch-logs/legacy-plugin-20240115.log) |
```

### Interpreting batch results

| Status | Meaning |
|---|---|
| `✓` | Gauntlet passed |
| `⚠` | Passed with warnings — review the log |
| `✗` | Failed — open log file to see which step |

### Viewing a specific plugin's log

```bash
cat reports/batch-logs/my-plugin-pro-20240115.log
# Shows full gauntlet output for just that plugin
```

---

## 9. Severity Decision Framework

Use this decision tree for every skill audit finding:

```
Finding received
      │
      ▼
Is it Critical or High?
      │
    YES ──────────────→ Block release. Fix now.
      │                 File a bug. Assign to developer.
      │
      NO
      │
      ▼
Is it Medium?
      │
    YES ──────────────→ Can it be fixed in < 30 min?
      │                       │
      │                     YES → Fix now, include in this release
      │                       │
      │                      NO → Log in backlog. Defer to next sprint.
      │
      NO
      │
      ▼
Low / Info
      │
      └──────────────→ Log in tech debt list. Defer.
                        Don't block the release.
```

### Critical examples (always block)

- SQL injection anywhere
- XSS in admin or frontend with no auth required
- REST endpoint exposing private data without auth
- PHP file upload with no MIME validation
- Hardcoded credentials or API keys in source

### High examples (block release)

- CSRF on any state-changing form
- Missing nonce on AJAX handlers that modify data
- Capability check missing on admin actions
- Stored XSS that requires admin to trigger
- Memory usage growth that crashes after 20 widgets

### Medium examples (fix if quick)

- Unnecessary asset loading on every page
- Missing `alt` text on admin UI images
- Autoloaded option that's > 10KB
- Missing `is_wp_error()` check (could cause cryptic failures)
- Cyclomatic complexity > 15 (hard to test)

### Low examples (log and defer)

- Function/class naming improvement
- Missing docblock on a private method
- Unused import/variable
- Minor spacing inconsistency in output HTML

---

## 10. Release Sign-off Checklist

After reviewing all reports, walk through this list:

```
GAUNTLET
[ ] Gauntlet exit code: 0
[ ] Zero ✗ failures in qa-report-*.md
[ ] All warnings reviewed and accepted or fixed

SKILL AUDITS (reports/skill-audits/index.html)
[ ] Zero Critical findings
[ ] Zero High findings
[ ] Medium findings logged in backlog
[ ] Security tab: no XSS, CSRF, SQLi, auth bypass

PLAYWRIGHT (reports/playwright-html)
[ ] Zero failed tests
[ ] Visual snapshots reviewed for regressions
[ ] Accessibility tests passing

PERFORMANCE (reports/lighthouse/)
[ ] Performance score ≥ 75
[ ] No render-blocking resources flagged

DATABASE (reports/db-profile-*.txt)
[ ] Query count per page within thresholds
[ ] No slow queries > 100ms
[ ] No large autoloaded options

PRE-RELEASE CHECKLIST
[ ] Version bumped in plugin header
[ ] Version bumped in readme.txt
[ ] CHANGELOG updated
[ ] Tested on: PHP 7.4, 8.0, 8.1, 8.2
[ ] Tested on: Latest WP and WP-1
[ ] Tested with conflict plugins active
```

When all boxes are checked → tag the release.

---

**Next**: [docs/09-multi-plugin.md](09-multi-plugin.md) — testing multiple plugins at once.
