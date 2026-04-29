<div align="center">

# 🪐 Orbit

### **Complete UAT for WordPress Plugins**

*A Claude Code plugin · **115 runtime-evergreen `/orbit-*` skills** · Dev → QA → PM → Designer → Release Ops*

**Skills are never snapshots.** Every skill fetches its canonical sources at runtime — WP make blog, Elementor changelog, Stripe docs, NVD/Patchstack/WPScan feeds — derives current rules from today's docs, and cites the live URL + fetch timestamp in every finding.

**The brainless one-command audit:**

```bash
/orbit-do-it ~/plugins/my-plugin
```

Auto-detects plugin type. Picks the right pipeline. Runs core audits + UAT + perf + security + compat in parallel. Writes a one-page TL;DR + a master HTML report. Walks away. Comes back to a verdict.

<br />

![PHP](https://img.shields.io/badge/PHP-7.4%20→%208.5-777BB4?style=for-the-badge&logo=php&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-6.3%20→%207.0-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![Playwright](https://img.shields.io/badge/Playwright-E2E-2EAD33?style=for-the-badge&logo=playwright&logoColor=white)
![Stagehand](https://img.shields.io/badge/Stagehand-AI%20UAT-7C3AED?style=for-the-badge)
![Lighthouse](https://img.shields.io/badge/Lighthouse-Performance-F44B21?style=for-the-badge&logo=lighthouse&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude%20Code-115%20Skills-CC785C?style=for-the-badge)

<br />

**👨‍💻 Dev** · zero-regression releases &nbsp;·&nbsp; **🧪 QA** · structured coverage + auto-generated specs &nbsp;·&nbsp; **📊 PM** · flow maps + RICE backlog + release notes &nbsp;·&nbsp; **🎨 Designer** · visual diffs + token audits + dark mode &nbsp;·&nbsp; **🚀 Release Ops** · WP.org gates + EU CRA compliance &nbsp;·&nbsp; **👤 End User** · real browser, real flows, AI-resolved tests

📖 **[VISION.md](VISION.md)** &nbsp;·&nbsp; 🚀 **[Skills Reference](SKILLS.md)** &nbsp;·&nbsp; 🌱 **[Runtime-Evergreen Pattern](EVERGREEN.md)** &nbsp;·&nbsp; 🛡️ **[Evergreen Security](docs/21-evergreen-security.md)** &nbsp;·&nbsp; 📓 **[Changelog](CHANGELOG.md)**

[Install in 60s](#install-in-60-seconds) · [The brainless agent](#the-brainless-team-agent) · [The 115 skills](#the-115-orbit-skills) · [Runtime-evergreen, explained](#runtime-evergreen-the-philosophy) · [Role guide](docs/onboarding-by-role.md) · [GitHub](https://github.com/adityaarsharma/orbit)

</div>

---

## What Orbit Is

A **Claude Code plugin** that gives a WordPress plugin team — dev, QA, PM, designer, release ops — a single command (`/orbit-do-it`) that audits everything that matters before a release: code standards, security, performance, accessibility, UAT, visual regression, hosting compatibility, EU CRA compliance, and 100+ other concerns.

It's **not a SaaS**. Runs locally via Docker (`wp-env`) + Claude Code. No accounts, no subscriptions, no cloud. The whole stack — 115 skills, all the scripts, the installer, this README — lives in one Git repo.

It's **runtime-evergreen**. When a skill runs, it fetches the canonical source-of-truth doc (e.g. Elementor's changelog, NVD's CVE feed, Kinsta's banned-plugins page) and applies *today's rules* — not a snapshot from when the skill was written. The same `/orbit-elementor-compat` SKILL.md handles V4 today, V5 next year, V6 the year after. Without anyone editing it.

It **composes with `WordPress/agent-skills`** — WP core's official AI agent skills (Brandon Payton, January 2026). Orbit's installer chains `npx openskills install WordPress/agent-skills`, so users get both: WP core's runtime/Playground primitives + Orbit's QA/UAT/audit suite.

---

## Install in 60 seconds

```bash
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash
```

That installs:

1. Orbit cloned to `~/Claude/orbit`
2. **115 `/orbit-*` skills** symlinked into `~/.claude/skills/` (so they autocomplete in Claude Code)
3. **WordPress/agent-skills** via `npx openskills install WordPress/agent-skills` (WP core's official skills — composes alongside Orbit)
4. Power tools: PHPCS + WPCS + VIP + PHPCompatibility, PHPStan, Playwright + Chromium/Firefox/WebKit, Lighthouse, axe-core, WP-CLI, wp-env, wp-now, source-map-explorer, PurgeCSS

After install:

```bash
# Quit Claude Code (Cmd+Q on macOS) and reopen — slash commands register
# Then onboard your first plugin:
/orbit-setup

# Or jump straight to the brainless agent:
/orbit-do-it ~/plugins/my-plugin
```

### Update later

```bash
# In Claude Code:
/orbit-update

# Or via shell:
bash ~/Claude/orbit/update.sh
```

Zero questions. Refreshes skill symlinks, removes deprecated entries, ~20 seconds. Skill text changes are live immediately (symlinks); MCP-server changes need a Claude Code restart.

### From a clone (offline-capable)

```bash
git clone https://github.com/adityaarsharma/orbit ~/Claude/orbit
cd ~/Claude/orbit
bash install.sh
```

---

## The brainless team agent

The whole vision distilled into one command:

```bash
/orbit-do-it ~/plugins/my-plugin
```

What happens:

1. **Auto-detects** plugin type — Elementor addon, Gutenberg block plugin, WooCommerce extension, form plugin, membership/LMS, theme, or generic
2. **Picks the right pipeline** — core 6 audits + type-specific add-ons + UAT + live security feeds + perf + a11y + i18n
3. **Runs in parallel** with CPU throttle (auto-detects M1 / M2 / workstation)
4. **For UAT** — uses `/orbit-uat-agent` (Stagehand-style natural-language tests; no selectors to write)
5. **Generates** the master HTML report + a one-page TL;DR
6. **Verdict** — **SHIP**, **WARN**, or **BLOCK** with the top 3 things to fix

Total: **~10–15 minutes**, zero questions after the path. Designed for non-technical team members + dev leads who want the audit done, not configured.

```
$ /orbit-do-it ~/plugins/my-new-plugin

🪐 Detected: Elementor addon (PHP 8.1+, 14 widgets)
   Pipeline: 6 core audits + Elementor (dev/controls/compat/skins/V4)
             + UAT (natural-language) + live CVE feeds + Lighthouse
   ETA: 12 min.

[12 min later]

✅ Verdict: BLOCK release — 2 Critical findings.

   Top 3 to fix:
   1. Settings page — XSS in ?search= (active probe found it)
   2. widget-3 — render() echoes attribute without esc_html
   3. widget-7 — insert time 1.4s (target < 300ms)

   Full report: ~/plugins/my-new-plugin/reports/index.html
```

Want even less friction? **`/orbit-uat-agent`** alone — describe flows in English ("log in → open Settings → fill API Key → save → verify saved"), the agent generates Playwright + AI-resolved selectors, runs them, self-heals on UI changes. ~$0.01–0.05 per test. Designed so a designer or PM can run UAT without writing a selector.

---

## Runtime-evergreen, the philosophy

Software-quality tooling shouldn't freeze in the year it was written. WordPress, Elementor, Stripe, the CVE landscape — all evolve continuously. A skill that hardcodes "use apiVersion 3" is a time bomb.

Orbit's pattern, top of every SKILL.md:

```markdown
## Runtime — fetch live before auditing (DO THIS FIRST)

When this skill is invoked:

1. Fetch in parallel (these are source-of-truth):
   - https://elementor.com/pro/changelog/
   - https://developers.elementor.com/docs/deprecations/
   - https://github.com/elementor/elementor/releases

2. Synthesize current state:
   - "What's the current major Elementor version as of today?"
   - "What APIs were deprecated in the last 2 minor releases?"

3. Audit against synthesized current rules — NOT against embedded text below.

4. Cite, in every finding: source URL + fetch timestamp.
   Example: `Per elementor.com/pro/changelog (fetched 2026-04-30 14:32 UTC):
            foo() deprecated in 3.22.`
```

That section is **executable instructions for Claude**, not documentation. When the skill runs, Claude reads it → fetches → uses live data.

| | Old pattern (snapshot) | Runtime-evergreen (v2.7) |
|---|---|---|
| `/orbit-elementor-compat` | "Test 3.18 / 3.20 / 3.22 / latest" hardcoded | Fetches changelog → tests latest 3 minors of TODAY |
| `/orbit-host-kinsta` | "Banned plugins as of April 2026" | Fetches Kinsta's banned-plugins page on every run |
| `/orbit-cve-check` | Pulls NVD weekly via cron | Pulls NVD + Patchstack + WPScan + GitHub Advisory + MITRE per invocation |
| `/orbit-pay-stripe` | "Use PaymentIntents API" (today's recommendation) | Fetches Stripe API ref → uses today's recommendation |

WebFetch caches for 15 minutes, so back-to-back runs in `/orbit-do-it` don't fire 100 fetches — unique URLs are de-duped + reused. Total overhead: ~10–30 sec on cold cache, sub-second after.

If WebFetch fails (no network), every skill has `## Embedded fallback rules` for offline mode + a clear `⚠ Live source fetch failed — using fallback. Findings may be stale.` notice.

Full pattern: [EVERGREEN.md](EVERGREEN.md). Drift-checks across the suite: `/orbit-skill-improver --check` (action-mode meta-skill that fetches all skills' sources, diffs rules, opens PRs).

---

## The 115 Orbit skills

| Category | Count | Sample |
|---|---|---|
| **Master + Brainless** | 4 | `/orbit` `/orbit-do-it` `/orbit-skill-add` `/orbit-skill-improver` |
| **Setup & Environment** | 6 | `/orbit-setup` `/orbit-update` `/orbit-install` `/orbit-docker-site` `/orbit-wp-playground` `/orbit-pre-commit` |
| **Pipeline** | 3 | `/orbit-gauntlet` `/orbit-release-gate` `/orbit-multi-plugin` |
| **Code Audits** | 14 | `/orbit-wp-{standards,security,performance,database}` `/orbit-{accessibility,i18n,code-quality,pm-ux-audit,compat-matrix,cve-check,abilities-api,rtc-compat,broken-access-control,scaffold-tests}` |
| **Gutenberg / Block Editor Dev** | 8 | `/orbit-gutenberg-dev` `/orbit-block-{render-test,edit-test,patterns,bindings,variations}` `/orbit-fse-test` `/orbit-interactivity-api` |
| **Elementor Dev** | 6 | `/orbit-elementor-{dev,controls,compat,pro,skins,dynamic-tags}` |
| **UAT Templates + Agent** | 6 | `/orbit-uat-agent` (natural-language) + `/orbit-uat-{elementor,gutenberg,woo,forms,membership}` |
| **QA Specialised** | 5 | `/orbit-qa-{flaky-detector,mutation,coverage,snapshot-cleanup,regression-pack}` |
| **PM Specialised** | 5 | `/orbit-pm-{rice,release-notes,feedback-mining,roadmap,competitor-pulse}` |
| **Designer Specialised** | 5 | `/orbit-designer-{tokens,empty-error,icons,rtl,dark-mode}` |
| **Browser Testing** | 4 | `/orbit-playwright` `/orbit-visual-regression` `/orbit-user-flow` `/orbit-conflict-matrix` |
| **Performance** | 7 | `/orbit-{lighthouse,editor-perf,db-profile,bundle-analysis}` `/orbit-perf-{stress-test,memory-leak,cdn}` |
| **Comparison** | 4 | `/orbit-{uat,version,competitor}-compare` `/orbit-changelog-test` |
| **Release** | 5 | `/orbit-{release-meta,zip-hygiene,plugin-check,block-json-validate,reports}` |
| **WP Edge Cases** | 7 | `/orbit-{multisite,uninstall-test,gdpr,cron-audit,cache-compat,rest-fuzzer,ajax-fuzzer}` |
| **Lifecycle** | 3 | `/orbit-life-{activation,upgrade,rollback}` |
| **Hosting Compat** | 5 | `/orbit-host-{wpengine,kinsta,cloudways,shared,pantheon}` |
| **Plugin Compat** | 5 | `/orbit-compat-{yoast,rankmath,wpml,polylang,acf}` |
| **Payment Integration** | 4 | `/orbit-pay-{stripe,paypal,edd,freemius}` |
| **Security Specialised** | 3 | `/orbit-sec-{xss-active,supply-chain,secrets-leak}` |
| **EU CRA + Premium** | 2 | `/orbit-vdp` (EU mandate) `/orbit-premium-audit` (Patchstack: 76% Pro vulns exploitable) |
| **SEO** | 3 | `/orbit-seo-{schema,sitemap,page-speed}` |

**Full skill reference** with trigger phrases + descriptions: [SKILLS.md](SKILLS.md).

---

## Composition with `WordPress/agent-skills`

WP core ships its own AI agent skills via [WordPress/agent-skills](https://github.com/WordPress/agent-skills) ([announcement, January 2026](https://wordpress.org/news/2026/01/new-ai-agent-skill/)). The flagship skill is `wp-playground` — spins up WordPress in seconds via Playground CLI, gives AI agents a fast feedback loop for code iteration.

**Orbit wraps; it doesn't reinvent.** `install.sh` runs `npx openskills install WordPress/agent-skills` automatically. `/orbit-wp-playground` is a thin doc-only skill that points at WP core's runtime primitives.

| Concern | Owned by |
|---|---|
| Spin up WordPress for testing | **WP core** (`wp-playground`) |
| Plugin code-quality audit | Orbit (`/orbit-wp-standards` etc.) |
| Natural-language UAT | Orbit (`/orbit-uat-agent`) |
| Live security feeds | Orbit (`/orbit-cve-check`) |
| Multi-version matrix | Orbit (`/orbit-compat-matrix`) |
| WP 7.0 Abilities API | **WP core** runtime + Orbit audit (`/orbit-abilities-api`) |

When WP core ships more agent skills, Orbit picks them up via the same `npx openskills install` chain — no Orbit code change needed.

---

## Vision

### Why this exists

Most WordPress plugin issues that reach users fall into five categories:

1. **Code that was never wrong, just untested** — a widget that renders fine on the dev's machine breaks on PHP 8.2 or with WPML active or on Kinsta's edge cache
2. **Performance regressions nobody noticed** — a new feature adds 40 extra DB queries per page load, or 80KB to the bundle
3. **Design debt** — settings UI that confuses users because it was built dev-first, not user-first
4. **Flow blindness** — nobody mapped whether a first-time user can actually complete setup without a tutorial
5. **No comparison baseline** — "our Mega Menu is better than ElementKit" stated without any data

UAT (User Acceptance Testing) is the practice of validating a product from every perspective before it ships — not just "does the code run" but "will a real user get stuck, is the UI regressed, does the PM have evidence it's better than competitors." **Orbit automates that entire layer for WordPress plugins.**

### What top teams do that most don't

- Automattic / WordPress VIP run every commit through PHP linting + VIP coding standards before merge
- 10up uses AI-powered visual regression — catches when something *looks* different without being *technically* broken
- WordPress.org plugin team added 15+ automated security checks in 2025 alone
- Leading Elementor addon teams run Playwright E2E suites across 3 WP versions before release

Orbit brings that same discipline to any plugin team, with a single command.

### The three rules

1. **Local-first, not CI-first.** Real MySQL, real PHP, real browsers — already on your Mac. CI is optional plumbing.
2. **Skills are senior reviewers, scripts are junior QA.** Claude Code skills read the code the way an experienced senior developer would. Scripts handle deterministic checks.
3. **Skills must be runtime-evergreen.** No quarterly maintenance. Every skill fetches its canonical source on every run.

### What's coming next

- **WP 7.0 readiness** (ships May 20, 2026) — already covered by `/orbit-abilities-api` + `/orbit-rtc-compat` + the runtime-fetch pattern
- **EU Cyber Resilience Act compliance** — `/orbit-vdp` is mandatory; `/orbit-premium-audit` covers the 76% premium-exploitability gap
- **Elementor V4 Atomic** (default for new sites April 2026) — `/orbit-elementor-compat` auto-handles via runtime-fetch
- **Cloud-hosted runs** (orbit.run, future) — gauntlet on a PR via GitHub Action, no local Docker
- **Community contributions** — `/orbit-skill-add` is a meta-skill that scaffolds new skills in the Orbit pattern. Anyone can add a skill via PR; the community catalogue grows.

---

## Severity model

Every Orbit skill applies this triage:

| Level | Action before release |
|---|---|
| **Critical** | Block release. Fix immediately. |
| **High** | Block release. Fix in this PR. |
| **Medium** | Fix if under 30 min. Otherwise log + defer. |
| **Low / Info** | Log in tech debt. Defer. |

`/orbit-do-it` reads these consistently and produces a single SHIP / WARN / BLOCK verdict at the top of every report.

---

## Reports

Every audit run drops everything into `reports/`:

```
reports/
├── qa-report-<timestamp>.md           ← markdown summary
├── tldr-<timestamp>.md                ← one-page verdict
├── index.html                         ← master HTML (PM-friendly)
├── playwright-html/index.html         ← visual test report
├── skill-audits/index.html            ← tabbed AI audit
├── uat-report-<timestamp>.html        ← UAT comparison + videos
├── pm-ux/pm-ux-report-*.html          ← PM-friendly UX report
└── lighthouse/lh-<timestamp>.json     ← Core Web Vitals
```

Open the master index:

```bash
open ~/plugins/my-plugin/reports/index.html
```

Designed to be shared with PMs / managers / customers without terminal access.

---

## Standards this follows

- [WordPress Coding Standards](https://github.com/WordPress/WordPress-Coding-Standards) — WPCS phpcs ruleset
- [WordPress VIP Coding Standards](https://github.com/Automattic/VIP-Coding-Standards) — enterprise-grade rules
- [10up Open Source Best Practices](https://10up.github.io/Open-Source-Best-Practices/testing/) — coverage targets, E2E approach
- [WordPress Plugin Check](https://github.com/WordPress/plugin-check) — the official WP.org submission tool
- [WordPress Playground Guide](https://wordpress.github.io/wordpress-playground/) — CI browser testing
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) — security baseline
- [WCAG 2.2 AA](https://www.w3.org/WAI/WCAG22/quickref/) — accessibility
- [Patchstack 2026 Security Whitepaper](https://patchstack.com/whitepaper/state-of-wordpress-security-in-2026/) — current threat model

---

## Contributing

Open to:

- **New skills** — fork, run `/orbit-skill-add`, follow the runtime-evergreen pattern, open a PR
- **Skill improvements** — every skill has `Sources & Evergreen References`. If a source moved or a rule needs updating, `/orbit-skill-improver --pr` opens a draft for review
- **Edge-case reports** — file a GitHub issue with `[skill]` or `[bug]` tag and a minimal repro

Keep contributions research-first. Every check should link to the standard or incident that motivated it.

---

## Built by

[Aditya Sharma](https://adityaarsharma.com) · POSIMYTH Innovation
github.com/adityaarsharma/orbit

**The discipline:** Software-quality tooling shouldn't freeze in the year it was written. It should know what *today* looks like by re-reading the canonical sources every time it runs. That's runtime-evergreen. That's Orbit.
