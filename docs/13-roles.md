# Role-Based Guide

> Your job in Orbit depends on your role. This guide tells each person exactly what to run, what to read, and what to decide.

---

## Table of Contents

1. [Developer](#1-developer)
2. [QA Engineer](#2-qa-engineer)
3. [Product Manager](#3-product-manager)
4. [Designer / UI Review](#4-designer--ui-review)
5. [Team Workflow: Pre-Release Sequence](#5-team-workflow-pre-release-sequence)

---

## 1. Developer

You own: writing code, fixing issues, running the gauntlet during development, interpreting skill audit findings.

### Daily workflow

```bash
# 1. Start your test site (once per session)
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin --port 8881

# 2. Write/modify code
# ...

# 3. Quick sanity check (Steps 1–6, < 2 min)
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode quick

# 4. Fix failures, repeat

# 5. Before committing — full run
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin
```

### Pre-release workflow

```bash
# Full gauntlet
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

# Review skill audit findings
open reports/skill-audits/index.html
# Fix all Critical and High findings

# Verify PHP compatibility
# (run PHP matrix if you changed any PHP patterns)

# Sign off
# → All passing → tag the release
```

### Interpreting skill audits

**Focus on**: Security tab first, then WP Standards, then Performance.

| Finding | Your action |
|---|---|
| Critical SQLi | Fix immediately. Don't commit until fixed. |
| Missing nonce | Add `check_admin_referer()` or `wp_verify_nonce()` |
| N+1 query | Add `update_postmeta_cache()` before the loop |
| High complexity | Extract sub-functions. Target < 10 branches. |
| Low/Info | Log in TODO comment or Jira. Ship anyway. |

### Playwright test writing

```bash
# Copy the right template
cp -r tests/playwright/templates/elementor-addon tests/playwright/my-plugin

# Run in UI mode while writing
npx playwright test --ui

# Run your tests against local wp-env
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/my-plugin/

# Debug a failing test
npx playwright test tests/playwright/my-plugin/ --debug
```

**Rules**:
- Always call `assertPageReady(page)` at the start of every test
- Always call `discoverNavLinks()` before writing any nav-based test
- Use `gotoAdmin(page, slug)` instead of `page.goto('/wp-admin/...')`
- Never use `page.waitForTimeout()` — use `waitForSelector` or `waitForLoadState`

### Skill prompts for targeted help

```bash
# Security review of a specific file you're worried about
claude "/wordpress-penetration-testing
Review only ~/plugins/my-plugin/includes/class-rest-api.php
Every register_rest_route call — does it have permission_callback?
Does permission_callback check the correct capability?
Output: table of routes with auth status."

# Performance question
claude "/performance-engineer
I have a WP_Query that returns 200 posts. Is this approach efficient?

\`\`\`php
$posts = new WP_Query(['posts_per_page' => 200]);
foreach ($posts->posts as $post) {
    $meta = get_post_meta($post->ID, '_my_key', true);
}
\`\`\`

Show me the fixed version with query count comparison."

# PHP modernization
claude "/php-pro
Suggest PHP 8.x improvements for ~/plugins/my-plugin/includes/class-settings.php
Focus on: null-safe operator, match expressions, constructor promotion.
Show before/after for each suggestion."
```

### What you own in reports

| Report | Developer action |
|---|---|
| `qa-report-*.md` | Fix all `✗` before tagging |
| `skill-audits/security.md` | Fix Critical + High before release |
| `playwright-html/` | Fix all failed tests |
| `db-profile-*.txt` | Fix any query count regression vs previous version |

---

## 2. QA Engineer

You own: writing and maintaining the test suite, running full audits, verifying fixes, maintaining quality bar.

### Daily workflow

```bash
# Start test site
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin --port 8881

# Run full test suite
WP_TEST_URL=http://localhost:8881 npx playwright test

# View results
npx playwright show-report reports/playwright-html
```

### Before release

```bash
# Full gauntlet
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

# PHP compatibility matrix
# (See docs/09-multi-plugin.md for full setup)
for PORT in 8881 8882 8883 8884; do
  WP_TEST_URL=http://localhost:$PORT bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode quick
done

# Plugin conflict test
# Activate all conflict-risk plugins and run
wp-env run cli wp plugin install woocommerce elementor wordpress-seo --activate
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

# Accessibility deep check
npx playwright test tests/playwright/my-plugin/a11y.spec.js --headed
```

### Test writing guide

```bash
# Template for a new feature area
cp tests/playwright/templates/generic-plugin/core.spec.js \
   tests/playwright/my-plugin/new-feature.spec.js

# Write tests using the discovery flow:
# 1. Run the Discovery test → get exact nav URLs
# 2. Use gotoAdmin() + assertPageReady() for every admin page
# 3. Write assertions for every user-visible behavior
# 4. Add visual snapshot for every screen state

# Run with headed browser to verify selectors
npx playwright test tests/playwright/my-plugin/new-feature.spec.js --headed
```

### Decision matrix: when to add a test

| Situation | Add test? |
|---|---|
| Bug was reported by a user | ✅ Yes — regression test |
| New feature shipping | ✅ Yes — at least smoke-level |
| Config option with 2 states | ✅ Yes — test both states |
| Trivial getter/setter | ❌ No |
| Code explored in a spike | ❌ No — delete the spike |
| Fix to a visual bug | ✅ Yes — visual regression snapshot |

### Maintaining test quality

```bash
# Update visual snapshots after intentional UI change
npx playwright test --update-snapshots

# Check test coverage — which features have no test?
npx playwright test --list  # shows all tests
# Compare against feature list in CHANGELOG.md

# Find flaky tests
npx playwright test --repeat-each=5  # run each test 5 times
# Any that fail inconsistently → investigate timing

# Remove obsolete tests
# When a feature is removed, delete the corresponding spec file
```

### What you own in reports

| Report | QA action |
|---|---|
| `playwright-html/` | Own every test — write missing ones, fix flaky ones |
| `skill-audits/accessibility.md` | File issues for Critical/High findings. Verify fixes. |
| `uat-report-*.html` | Share with PM for visual sign-off |
| `batch-TIMESTAMP.md` | Track portfolio-wide quality trends |

---

## 3. Product Manager

You own: release decisions, interpreting what findings mean for users, approving the UAT report.

### What you read (no code required)

**Primary**: `reports/uat-report-TIMESTAMP.html`
- Open with `open reports/uat-report-*.html`
- Shows videos + side-by-side screenshots of every flow
- Left column: your plugin. Right column: competitor.
- "Does our plugin look and behave better?"

**Secondary**: Summary from the gauntlet:
```
Results: 9 passed | 2 warnings | 0 failed
⚠ GAUNTLET PASSED WITH WARNINGS — review before release
```

### Release decision matrix

| Gauntlet result | Skill audits | PM decision |
|---|---|---|
| ✓ All passed | No Critical/High | **Green light — tag the release** |
| ⚠ Warnings only | No Critical/High | **Review warnings with dev, release if minor** |
| ✗ Any failures | — | **Hold release until fixed** |
| Any result | Has Critical | **Hold release — security risk to users** |
| Any result | Has High | **Hold release — quality risk** |
| Any result | Medium only | **Dev's call — ship or defer** |

### What Critical/High actually means for users

| Skill finding | What it means for a user |
|---|---|
| **Critical: SQLi** | An attacker could wipe the user's database |
| **Critical: XSS** | User's browser could be hijacked — sessions stolen |
| **Critical: Auth bypass** | Anyone can access admin-only features |
| **High: Missing nonce** | CSRF attack — user tricked into changing settings |
| **High: N+1 queries** | User's admin panel takes 5+ seconds to load |
| **High: Autoload bloat** | Every page load on user's site is 200ms slower |
| **Medium: Missing alt text** | Screen reader users can't understand your UI |

### Questions to ask before signing off

1. "Are there any Critical or High findings in the security tab?" → If yes: hold.
2. "Did all Playwright tests pass?" → If no: what feature is broken?
3. "Does the UAT report show all features working as expected?"
4. "Has the PHP compatibility matrix been run?" (for major releases)
5. "Is the CHANGELOG updated for this version?"

### What to ask for after a release

```
After every release, ask the developer for:
1. The qa-report-*.md summary (pass/fail counts)
2. Whether skill audits found Critical or High issues
3. Screenshot of the Playwright HTML report summary
```

---

## 4. Designer / UI Review

You own: visual quality, UX polish, consistency with the design system, and the visual regression baseline.

### What you run

```bash
# Visual regression suite — check every screen for regressions
npx playwright test tests/playwright/visual/ --headed

# View side-by-side comparison after any visual failure
npx playwright show-report reports/playwright-html
# Click a visual test → see baseline / actual / diff

# UAT video report — watch the flows as a user would
open reports/uat-report-*.html
```

### Setting up the visual baseline

When a new design ships:

```bash
# First run — creates baseline screenshots
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/visual/

# Baselines are saved to:
# tests/playwright/visual/snapshots/*.png
```

After an intentional design change:

```bash
# Update baselines
npx playwright test tests/playwright/visual/ --update-snapshots
# Review each updated screenshot — confirm the new design is correct
# Commit the updated baselines
git add tests/playwright/visual/
git commit -m "visual: update baselines for new design system"
```

### What to look for in the UAT report

Open `reports/uat-report-*.html` and check:

1. **Hit areas** — Does every button look clickable? At least 44×44px?
2. **Visual hierarchy** — Can you immediately tell what the most important action is?
3. **Spacing consistency** — Are margins/paddings consistent with the design system?
4. **Mobile rendering** — Does the 375px viewport look intentional, not broken?
5. **Animation** — Any janky transitions? (check videos)
6. **Color contrast** — Can you read text clearly on all backgrounds?
7. **Empty states** — Do empty lists/search results look designed, not broken?

### Running the design-specific skill

```bash
# For Elementor addon plugins
claude "/antigravity-design-expert
Review the UI quality of ~/plugins/my-plugin
Check: 44px hit areas, spacing consistency, concentric radius, typography hierarchy.
Output: ranked list of polish issues with screenshots/selectors." \
  > reports/skill-audits/design.md

open reports/skill-audits/design.md
```

### Visual test for every screen state

A complete visual test suite covers:

| Screen | States to snapshot |
|---|---|
| Admin dashboard | Default, empty, populated, error state |
| Settings page | Default, saved, validation error |
| Frontend widget | Default, custom colors, mobile |
| Modal / drawer | Open, closed, loading |
| Empty states | No posts, no settings, fresh install |

```bash
# Run with full page screenshots
WP_TEST_URL=http://localhost:8881 npx playwright test \
  --project=visual \
  --headed \
  tests/playwright/visual/
```

---

## 5. Team Workflow: Pre-Release Sequence

Who does what, in what order, before tagging a release.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1: DEVELOPER (day of code freeze)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Developer runs:
  bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

Reviews skill-audits/index.html:
  → Fixes all Critical and High findings
  → Re-runs gauntlet to confirm fixes

Hands off:
  "Gauntlet clean. No Critical/High in skills.
   Playwright: 18/18 passed.
   Reports at reports/skill-audits/index.html"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 2: QA ENGINEER (day before release)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

QA runs:
  Full Playwright suite + PHP matrix + conflict test
  bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

Reviews:
  playwright-html/ → all tests pass
  accessibility.md → no Critical a11y issues
  db-profile-*.txt → no query regression

Hands off:
  "QA complete. 22 tests pass.
   PHP matrix: 7.4/8.0/8.1/8.2 all clean.
   UAT report: reports/uat-report-*.html"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 3: DESIGNER (visual sign-off)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Designer reviews:
  UAT report: open reports/uat-report-*.html
  Visual regression: npx playwright show-report reports/playwright-html

Confirms:
  → UI matches design spec
  → No regressions from previous version
  → Mobile rendering looks intentional

Hands off:
  "Design approved. Visual baselines updated."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 4: PM (release decision)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PM reviews:
  UAT report for feature completeness
  Gauntlet summary: pass/warn/fail counts
  Skill audits: any Critical/High?

Decision:
  All phases green → tag the release
  Any blocker found → back to Developer

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RELEASE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

git tag v2.1.0
git push origin v2.1.0
```

### Minimum for hotfix releases

For urgent bug fixes that must ship same day:

```bash
# Minimum required for a hotfix
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode quick

# Manual checks:
# [ ] PHP lint passes
# [ ] Plugin activates cleanly
# [ ] The specific bug being fixed is confirmed fixed
# [ ] No new PHP errors in wp-content/debug.log
```

Full matrix and visual review can follow in the next release.

---

**Next**: [docs/15-ci-cd.md](15-ci-cd.md) — GitHub Actions and automated CI/CD integration.
