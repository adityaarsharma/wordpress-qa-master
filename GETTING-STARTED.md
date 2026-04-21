# Orbit — WordPress Plugin QA Framework

> The fastest way to go from "I think this plugin is ready" to "I know it is."
> Orbit runs static analysis, browser tests, performance benchmarks, security scans,
> and AI skill audits — all from one command.

---

## What Orbit Does in 60 Seconds

```
Your Plugin
    │
    ▼
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin
    │
    ├─ Step 1  PHP Lint          → zero syntax errors required
    ├─ Step 2  PHPCS / WPCS      → WP coding standards, security rules
    ├─ Step 3  PHPStan           → static analysis, type safety
    ├─ Step 4  Asset Weight      → JS/CSS bundle size audit
    ├─ Step 5  i18n / POT        → translatable strings check
    ├─ Step 6  Playwright        → functional + visual + accessibility tests
    ├─ Step 7  Lighthouse        → performance score (target: 80+)
    ├─ Step 8  DB Profiling      → query count + slow query detection
    ├─ Step 9  Competitor        → side-by-side feature comparison
    ├─ Step 10 UI Performance    → editor load time (Elementor/Gutenberg)
    └─ Step 11 Claude Skill Audits (6 parallel AI agents, 3-6 min)
               ├─ WP Standards  → hooks, escaping, nonces, i18n
               ├─ Security      → OWASP Top 10 for WordPress
               ├─ Performance   → N+1s, blocking assets, hook weight
               ├─ Database      → queries, indexes, autoload bloat
               ├─ Accessibility → WCAG 2.2 AA
               └─ Code Quality  → complexity, dead code, error handling
    │
    ▼
reports/
├── qa-report-TIMESTAMP.md           ← full markdown report
├── playwright-html/index.html       ← visual test report
├── skill-audits/index.html          ← tabbed AI audit report
├── uat-report-TIMESTAMP.html        ← PM-friendly video + screenshot report
└── lighthouse/lh-TIMESTAMP.json     ← performance data
```

**One command. Zero manual steps. Release with confidence.**

---

## 5-Minute Quick Start

```bash
# 1. Clone Orbit
git clone https://github.com/adityaarsharma/orbit.git ~/Claude/orbit
cd ~/Claude/orbit

# 2. Install all tools in one shot
bash setup/install.sh

# 3. Start a test WordPress site for your plugin
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin --port 8881

# 4. Run the full gauntlet
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

# 5. Open reports
open reports/skill-audits/index.html
npx playwright show-report reports/playwright-html
```

That's it. Your plugin now has a complete quality audit.

---

## Documentation Map

| What you need | Where to go |
|---|---|
| **Full installation** — every tool, verification, skill setup | [docs/01-installation.md](docs/01-installation.md) |
| **Configure Orbit** for your plugin — qa.config.json reference | [docs/02-configuration.md](docs/02-configuration.md) |
| **Test environment** — wp-env, Docker, WP-CLI, multisite | [docs/03-test-environment.md](docs/03-test-environment.md) |
| **Gauntlet deep-dive** — all 11 steps explained with examples | [docs/04-gauntlet.md](docs/04-gauntlet.md) |
| **Claude Skills** — all 6 core + 5 add-on skills, what they find | [docs/05-skills.md](docs/05-skills.md) |
| **Writing Playwright tests** — recipes for every plugin type | [docs/writing-tests.md](docs/writing-tests.md) |
| **Test templates** — Elementor, Gutenberg, SEO, WooCommerce, REST | [docs/07-test-templates.md](docs/07-test-templates.md) |
| **Reading reports** — how to interpret every report type | [docs/08-reading-reports.md](docs/08-reading-reports.md) |
| **Multi-plugin workflows** — batch testing, PHP matrix | [docs/09-multi-plugin.md](docs/09-multi-plugin.md) |
| **Real-world QA cases** — 18 edge cases most checklists miss | [docs/real-world-qa.md](docs/real-world-qa.md) |
| **Deep performance** — beyond Lighthouse, editor perf, bundle analysis | [docs/deep-performance.md](docs/deep-performance.md) |
| **Database profiling** — N+1s, slow queries, autoload bloat | [docs/database-profiling.md](docs/database-profiling.md) |
| **Role guides** — Developer, QA, PM, Designer workflows | [docs/13-roles.md](docs/13-roles.md) |
| **Common WP mistakes** — 17 patterns Orbit catches automatically | [docs/common-wp-mistakes.md](docs/common-wp-mistakes.md) |
| **CI/CD integration** — GitHub Actions, automated release gates | [docs/15-ci-cd.md](docs/15-ci-cd.md) |
| **Power tools** — extend Orbit with extra tooling | [docs/power-tools.md](docs/power-tools.md) |

---

## Which Command Do You Need?

```bash
# Full pre-release audit (all 11 steps)
bash scripts/gauntlet.sh --plugin /path/to/plugin

# Quick sanity check (skips Steps 7–11)
bash scripts/gauntlet.sh --plugin /path/to/plugin --mode quick

# Just Playwright tests
WP_TEST_URL=http://localhost:8881 npx playwright test

# Just skill audits (6 parallel AI agents)
P=/path/to/plugin
claude "/wordpress-penetration-testing Security audit $P" > reports/skill-audits/security.md &
claude "/performance-engineer Analyze $P" > reports/skill-audits/performance.md &
wait

# Test multiple plugins simultaneously
bash scripts/batch-test.sh --plugins-dir ~/plugins

# Point at staging instead of local
WP_TEST_URL=https://staging.example.com bash scripts/gauntlet.sh --plugin /path/to/plugin
```

---

## Prerequisites at a Glance

| Tool | Required For | Min Version |
|---|---|---|
| Node.js | Playwright, wp-env, npm scripts | 18+ |
| Docker Desktop | wp-env test sites | Latest |
| PHP CLI | PHP lint (Step 1) | 7.4+ |
| Composer | PHPCS, PHPStan | Latest |
| WP-CLI | i18n check (Step 5), DB work | Latest |
| Claude Code CLI | Skill audits (Step 11) | Latest |
| Git | Pulling Orbit | Latest |

All installed by `bash setup/install.sh`. See [docs/01-installation.md](docs/01-installation.md) for details.

---

## The 6 Mandatory Claude Skills

Orbit uses **Claude Code skills** — specialist AI agents that read your plugin code and produce structured markdown reports. They always run via `AGENTS.md` which Claude Code reads automatically.

| # | Skill | What it finds |
|---|---|---|
| 1 | `/wordpress-plugin-development` | WP API misuse, escaping gaps, nonce missing |
| 2 | `/wordpress-penetration-testing` | XSS, CSRF, SQLi, auth bypass, path traversal |
| 3 | `/performance-engineer` | Hook weight, N+1s, blocking scripts |
| 4 | `/database-optimizer` | Raw SQL, autoload bloat, missing indexes |
| 5 | `/accessibility-compliance-accessibility-audit` | WCAG 2.2 AA violations |
| 6 | `/code-review-excellence` | Dead code, complexity, error handling |

Full skill deep-dive: [docs/05-skills.md](docs/05-skills.md)

---

## Severity Triage

| Level | Action |
|---|---|
| **Critical** | Block release. Fix today. |
| **High** | Block release. Fix in this PR. |
| **Medium** | Fix if < 30 min. Otherwise log in tech debt. |
| **Low / Info** | Log. Defer. |

---

## Project Structure

```
orbit/
├── GETTING-STARTED.md           ← you are here
├── AGENTS.md                    ← Claude reads this — hard-codes 6 mandatory skills
├── SKILLS.md                    ← skill reference + deduplication guide
├── scripts/
│   ├── gauntlet.sh              ← main entry point — runs all 11 steps
│   ├── batch-test.sh            ← parallel multi-plugin testing
│   ├── create-test-site.sh      ← spins up wp-env + installs plugin
│   ├── db-profile.sh            ← database query profiling
│   ├── editor-perf.sh           ← Elementor/Gutenberg editor load timing
│   ├── competitor-compare.sh    ← side-by-side plugin comparison
│   └── generate-uat-report.py   ← HTML report generator
├── tests/playwright/
│   ├── playwright.config.js     ← 7 test projects
│   ├── auth.setup.js            ← WP admin login → saves cookies
│   ├── helpers.js               ← assertPageReady, gotoAdmin, discoverNavLinks, snapPair
│   └── templates/               ← ready-to-copy test specs
├── config/
│   ├── phpcs.xml                ← WordPress coding standards config
│   └── phpstan.neon             ← PHPStan config
├── setup/install.sh             ← one-command installer
├── checklists/pre-release-checklist.md
├── docs/                        ← all documentation (you are here)
└── qa.config.example.json       ← plugin config template
```

---

**Next step**: [docs/01-installation.md](docs/01-installation.md) — complete installation guide.
