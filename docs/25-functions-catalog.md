# Functions Catalog — Every Part of Orbit, One Line Each

> The inventory. Point anyone here when they ask "what does X do?" Every
> script, spec, skill, config, and doc is listed with a one-line summary.

---

## Scripts — `scripts/` (26 files)

### Entry points
| Script | One-liner |
|---|---|
| `gauntlet.sh` | Main pipeline — runs 25+ steps end-to-end with `--mode quick\|full\|release` |
| `gauntlet-dry-run.sh` | Preflight — validates every dep + env + skill in ~5 seconds |
| `scaffold-tests.sh` | Reads plugin code → generates `qa.config.json` + scenarios + draft Playwright spec |
| `generate-design-md.sh` | Produces `design.md` architecture snapshot from plugin code |
| `generate-reports-index.py` | Builds `reports/index.html` master landing page |
| `generate-uat-report.py` | Builds PM-facing UAT HTML with videos + screenshots |
| `install-pre-commit-hook.sh` | One-command install of `.githooks/pre-commit` into any repo |

### Release gate
| Script | One-liner |
|---|---|
| `check-plugin-header.sh` | Required + recommended header fields; Text Domain match; GPL license |
| `check-readme-txt.sh` | WP.org parser compliance — sections, fields, length, stable tag |
| `check-version-parity.sh` | Plugin header ↔ readme.txt ↔ CHANGELOG.md ↔ git tag sync |
| `check-license.sh` | GPL compliance scan for composer vendor + npm node_modules |
| `check-block-json.sh` | `apiVersion: 3` + `$schema` + name format + render path |
| `check-hpos-declaration.sh` | WooCommerce HPOS compatibility (auto-skips if no WC) |
| `check-wp-compat.sh` | Plugin WP function usage vs declared "Requires at least" |
| `check-php-compat.sh` | PHP 8.0-8.5: removed functions, implicit nullable, property hooks |
| `check-modern-wp.sh` | Script Modules, Interactivity API, Plugin Dependencies, Site Health |
| `check-wp-org-guidelines.sh` | Deep check against all 18 WP.org detailed plugin guidelines |
| `check-pot-file.sh` | Verifies shipped POT exists + headers + JS coverage + freshness |
| `check-rtl-readiness.sh` | Static — `rtl.css`, `is_rtl()`, Domain Path, readme.txt |

### Quality / security
| Script | One-liner |
|---|---|
| `check-zip-hygiene.sh` | Dev artifacts (.git, AI dirs, source maps) + obfuscation + `ALLOW_UNFILTERED_UPLOADS` |
| `check-gdpr-hooks.sh` | Scans for user data + missing `wp_privacy_personal_data_*` hooks |
| `check-login-assets.sh` | Flags plugin assets that leak onto wp-login.php |
| `check-translation.sh` | Generates pseudo-locale `.mo`, loads it, scans for runtime errors |
| `check-object-cache.sh` | Redis object cache compatibility + transient bypass detection |
| `check-ownership-transfer.sh` | Git-log plugin Author/URI/Name across commits (April 2026 attack defense) |
| `check-live-cve.sh` | Correlates plugin code against last 60 days of NVD + WPScan CVEs (free) |

### Test environment
| Script | One-liner |
|---|---|
| `create-test-site.sh` | Spins up wp-env Docker site with the plugin pre-installed |
| `db-profile.sh` | N+1 detection + autoload bloat + slow query summary |
| `editor-perf.sh` | Measures Elementor/Gutenberg editor load time |
| `seed-large-dataset.sh` | Generates 1,000+ posts/users/terms for scale testing |
| `batch-test.sh` | Runs the gauntlet against multiple plugins in parallel |
| `compare-versions.sh` | Diffs behavior between two plugin versions |
| `competitor-compare.sh` | Side-by-side screenshots of plugin vs declared competitors |
| `changelog-test.sh` | Extracts changelog entries and verifies sync across files |
| `install-power-tools.sh` | Installs optional tools (Lighthouse, msgfmt, Redis) via brew |
| `pull-plugins.sh` | Downloads top-N popular plugins for conflict matrix |

### PM / PA / UX
| Script | One-liner |
|---|---|
| `pm-ux-audit.sh` | Orchestrates spell-check + guided-ux + label-audit specs, generates HTML |
| `generate-pm-ux-report.py` | HTML report for PM UX Audit results |

---

## Playwright projects + specs — `tests/playwright/`

### Project runners (`playwright.config.js`)
| Project | What it runs |
|---|---|
| `setup` | One-time WP admin login, saves cookies to `.auth/wp-admin.json` |
| `chromium` | Main functional E2E on Desktop Chrome |
| `firefox` | Cross-browser Firefox |
| `webkit` | Cross-browser Safari (WebKit) |
| `visual` | Full-page screenshot baselines |
| `mobile-chrome` | Pixel 5 responsive checks |
| `tablet` | iPad Pro responsive checks |
| `video` | All flow specs recorded to `reports/videos/` |
| `elementor-widgets` | Per-widget Elementor testing |
| `rtl` | Arabic locale layout verification |
| `multisite` | Network activation + subsite smoke |
| `admin-colors` | All 9 WP admin color schemes |
| `keyboard` | Focus trap + tab order |
| `lifecycle` | uninstall + update-path + block-deprecation |
| `rest-apppass` | Application Passwords REST auth |
| `ux-states` | empty + error + loading + form-validation |
| `conflict` | Top-20 popular plugins matrix |
| `wp7` | WP 7.0 Abilities / Connectors API |
| `pm` | User journey + FTUE |
| `analytics` | Event firing verification |
| `visual-release` | Diff vs previous git tag |
| `bundle-size` | Per-page JS/CSS size limits |

### Flow specs — `tests/playwright/flows/`
Each file implements one spec. See its top docblock for usage and `qa.config.json` fields it reads.

| Spec | One-liner |
|---|---|
| `uninstall-cleanup.spec.js` | Asserts options/tables/cron/user meta/caps/revisions cleaned on delete |
| `update-path.spec.js` | v1 zip → v2 zip, asserts settings + DB survive |
| `block-deprecation.spec.js` | Existing posts with plugin's blocks still render after update |
| `keyboard-nav.spec.js` | Tab through UI, detect focus trap, verify focus-visible indicator |
| `admin-color-schemes.spec.js` | Cycle all 9 WP admin colors, assert no invisible text |
| `rtl-layout.spec.js` | Arabic locale + overflow detection + visual baseline |
| `multisite-activation.spec.js` | Network-activate + subsite smoke + sitemeta vs options |
| `app-passwords.spec.js` | REST endpoint auth — admin pwd works, subscriber rejected |
| `wp7-connectors.spec.js` | WP 7.0 `WP_Ability` class registration + agent permission context |
| `plugin-conflict.spec.js` | Top-20 popular plugins activated one-by-one, assert no fatals |
| `empty-states.spec.js` | Admin pages with zero items show helpful message + CTA |
| `error-states.spec.js` | AJAX 500 / REST WP_Error doesn't freeze UI or leak raw codes |
| `loading-states.spec.js` | Spinner/skeleton shown during async + CLS < 0.25 |
| `form-validation.spec.js` | Empty required fields → field-specific errors + `aria-invalid` |
| `user-journey.spec.js` | End-to-end install → configure → use flow (PM role) |
| `onboarding-ftue.spec.js` | Activation redirect + skippable onboarding + 3-clicks-to-feature |
| `analytics-events.spec.js` | GA/Mixpanel/PostHog events fire on declared user actions |
| `visual-regression-release.spec.js` | Pixel diff vs previous git tag screenshots |
| `bundle-size.spec.js` | Per-page JS/CSS weight + login-must-be-zero + defer/async |

### PM UX specs — `tests/playwright/pm/`
| Spec | One-liner |
|---|---|
| `spell-check.spec.js` | Crawls admin pages, extracts UI text, flags typos |
| `guided-ux.spec.js` | Scores onboarding quality 0-10 across 7 signals |
| `label-audit.spec.js` | Flags 9 anti-pattern label classes + competitor terminology |

---

## Custom Claude skills — `~/.claude/skills/`

| Skill | Role |
|---|---|
| `/orbit-wp-security` | 22 WP vulnerability patterns — PHP source code reviewer (not attacker tool) |
| `/orbit-wp-performance` | 14 WP perf patterns — hooks, queries, transients, Script Modules |
| `/orbit-wp-database` | `$wpdb`, dbDelta, autoload, uninstall cleanup patterns |
| `/orbit-wp-standards` | Review-mode WP coding standards (not scaffolder) |
| `/orbit-scaffold-tests` | AI-augmented business-logic scenario writer (via `--deep`) |

Plus community skills referenced by the gauntlet:
`/security-auditor`, `/security-scanning-security-sast`, `/vibe-code-auditor`, `/codebase-audit-pre-push`, `/accessibility-compliance-accessibility-audit`, `/web-performance-optimization`, `/fixing-accessibility`, `/wcag-audit-patterns`, `/deep-research`.

---

## Configs — `config/`

| Config | Purpose |
|---|---|
| `.wp-env.multisite.json` | WP multisite with 2 pre-created subsites |
| `.wp-env.redis.json` | WP + Redis object cache via redis-cache plugin |
| `.wp-env.rc.json` | WP trunk / RC build for pre-release compat testing |
| `pm-ux/competitor-terms.json` | 10-plugin UI terminology database (Yoast, RankMath, Woo, etc.) |
| `pm-ux/cspell.json` | Spell-check config with WP-ecosystem allowlist |
| `phpcs.xml` | PHPCS ruleset (WP + VIP standards) |
| `phpstan.neon` | PHPStan level 5 config |
| `lighthouserc.json` | Lighthouse CI config with WP-specific targets |

---

## Workflows + hooks

| File | Purpose |
|---|---|
| `.github/workflows/ci.yml` | Self-validation on every PR — syntax + brand-leakage enforcement |
| `.githooks/pre-commit` | Fast commit-time: PHP lint + JSON validity + scratch detection + credential blocker |

---

## Docs — `docs/` + root (29 files)

### Anchor + shareable
| Doc | For |
|---|---|
| `VISION.md` | The anchor — 6 perspectives + 7 smart principles + research loop |
| `docs/22-what-orbit-does.md` | Shareable one-pager for "what is Orbit?" |
| `docs/25-functions-catalog.md` | This doc — inventory of every part |

### Onboarding
| Doc | For |
|---|---|
| `GETTING-STARTED.md` | Entry point + doc map for first-time users |
| `docs/00-concepts.md` | Plain-English explainer for every tool in the pipeline |
| `docs/onboarding-by-role.md` | Step-by-step per role (Dev/QA/PM/PA/Designer/End User) |
| `docs/13-roles.md` | Deep role guide with daily workflows + decision rules |

### How-tos
| Doc | For |
|---|---|
| `docs/01-installation.md` | macOS + Ubuntu install, verification |
| `docs/02-configuration.md` | `qa.config.json` full reference with 4 plugin examples |
| `docs/03-test-environment.md` | wp-env, wp-now, PHP matrix, WP-CLI |
| `docs/04-gauntlet.md` | All pipeline steps with bad/good code examples |
| `docs/05-skills.md` | All 6 core + 5 add-on skills explained |
| `docs/07-test-templates.md` | Working Playwright specs for 6 plugin types |
| `docs/writing-tests.md` | Per-plugin-type test recipes |
| `docs/19-business-logic-guide.md` | Writing tests for plugin-specific logic |
| `docs/20-auto-test-generation.md` | How Orbit reads plugin code via scaffolder |
| `docs/23-extending-orbit.md` | Ideate, plan, add checks, write specs, create skills |
| `docs/24-use-cases.md` | 25 real scenarios by role |

### Reading + release
| Doc | For |
|---|---|
| `docs/08-reading-reports.md` | How to interpret every report type |
| `docs/18-release-checklist.md` | Complete pre-tag gate covering all roles |
| `docs/17-whats-new.md` | v2.x demo doc for team walkthroughs |

### Advanced
| Doc | For |
|---|---|
| `docs/09-multi-plugin.md` | Batch testing + PHP matrix workflows |
| `docs/database-profiling.md` | N+1s, slow queries, autoload bloat |
| `docs/deep-performance.md` | Beyond Lighthouse — editor perf, bundle analysis |
| `docs/15-ci-cd.md` | GitHub Actions / GitLab / CircleCI full gauntlet templates |
| `docs/common-wp-mistakes.md` | 17 patterns Orbit catches automatically |
| `docs/real-world-qa.md` | 18 edge cases most checklists miss |
| `docs/power-tools.md` | Optional extensions for larger teams |
| `docs/what-is-playwright.md` | Playwright primer for QA new to E2E |
| `docs/wp-env-setup.md` | wp-env deep-dive |

### Ongoing
| Doc | For |
|---|---|
| `docs/16-master-audit.md` | Master gap audit + antigravity skill mappings |
| `docs/21-evergreen-security.md` | Living attack-pattern catalog (SHIPPED/RESEARCHING/WATCHING), 90-day cadence |
| `CHANGELOG.md` | Every release, every change, every fix |

---

## How to find what you need

| If you're… | Start here |
|---|---|
| New to Orbit | `GETTING-STARTED.md` → `docs/00-concepts.md` |
| Sharing with someone | `docs/22-what-orbit-does.md` |
| Shipping a release | `docs/18-release-checklist.md` |
| Writing tests | `docs/19-business-logic-guide.md` + `docs/23-extending-orbit.md` |
| Looking up "what does X do?" | This doc (`docs/25-functions-catalog.md`) |
| Debugging a failed check | `docs/08-reading-reports.md` |
| Adding a new perspective | `VISION.md` → `docs/23-extending-orbit.md` |
| Tracking security threats | `docs/21-evergreen-security.md` |

---

_If a script/spec/skill/doc isn't listed here, it either doesn't exist or this catalog is stale.
Re-generate after each release._
