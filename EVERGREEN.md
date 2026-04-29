# Orbit — The Runtime-Evergreen Pattern

> Skills are not snapshots. **Every Orbit skill fetches its canonical sources at runtime, derives current rules from today's docs, applies them to the user's plugin, and cites the live URL + fetch timestamp in every finding.** The skill is dynamic by design. No quarterly maintenance. No "update the skill" chore.

---

## Why this exists

A skill that hardcodes "WP supports apiVersion 3" is a time bomb. True today, wrong tomorrow when WP 7.0 ships apiVersion 4. The user shouldn't have to remember to update their tooling — the tooling should keep itself current by reading the source-of-truth on every run.

So: every Orbit skill, when invoked, **starts by fetching live**.

---

## The runtime-evergreen contract

Every Orbit `SKILL.md` MUST include — near the top, before any embedded rules — a section like this:

```markdown
## Runtime — fetch live before auditing (DO THIS FIRST)

When this skill is invoked, before applying any rules below:

1. **Fetch in parallel** (these URLs are source-of-truth — the rules below are
   only a fallback if fetch fails):
   - https://elementor.com/pro/changelog/  → extract latest version + last 2 minors' breaking changes
   - https://developers.elementor.com/docs/deprecations/ → current deprecation list
   - https://github.com/elementor/elementor/releases → latest tag

2. **Synthesize current state** from the fetched content:
   - "What is the current major Elementor version as of <today>?"
   - "What APIs were deprecated in the last 2 minor releases?"
   - "What patterns does the migration guide recommend RIGHT NOW?"

3. **Audit the user's plugin** against the synthesized current rules — not against
   the fallback rules in this file.

4. **Cite, in every finding**: source URL + fetched-on date.
   Example: `Per elementor.com/pro/changelog/ (fetched 2026-04-30): foo() deprecated in 3.22.`

## Embedded fallback rules (used only if WebFetch fails)
[the older static rules — kept as offline fallback only]
```

That section is **executable instructions for Claude**, not documentation. When the skill runs, Claude reads SKILL.md → sees "fetch these first" → does it → uses the live data.

---

## What this changes in practice

| | v2.6 (snapshot) | v2.7 (runtime-evergreen) |
|---|---|---|
| `/orbit-elementor-compat` | "Test 3.18 / 3.20 / 3.22 / latest" (hardcoded) | Fetches Elementor changelog → tests against whatever the latest 3 minors are TODAY |
| `/orbit-host-kinsta` | "Banned plugins as of April 2026" (snapshot) | Fetches Kinsta's banned-plugins page on every run |
| `/orbit-cve-check` | Pulls NVD weekly via cron (manual) | Pulls NVD + Patchstack + WPScan on every invocation |
| `/orbit-pay-stripe` | "Use PaymentIntents API" (today's recommendation) | Fetches Stripe API ref → uses whatever Stripe currently recommends |
| `/orbit-block-bindings` | "apiVersion 3 is current" | Fetches Block API Versions doc → reflects today's current |
| `/orbit-plugin-check` | "Plugin Check 1.9 (March 2026)" | Fetches WP.org repo → uses whatever's latest |

**Net:** the same SKILL.md works for Elementor V5 when it ships, WP 7.5 when it ships, Stripe API v2027 when it ships — without any human editing the skill.

---

## Performance + caching

WebFetch caches for 15 minutes. So a `/orbit-do-it` run that invokes 12 skills doesn't fire 12 × 5 fetches — it fires the unique URLs once and reuses. Total overhead: ~10-30 sec on cold cache, sub-second after.

For batch jobs (CI, weekly cron), wrap the run with a `WEB_CACHE_TTL=3600` to extend the cache to an hour.

---

## Offline / fallback mode

If WebFetch fails (no internet, source 404, rate-limited):

1. Skill emits a clear notice: `⚠ Live source fetch failed — using embedded fallback rules. Findings may reflect stale guidance.`
2. Falls back to the static rules in `## Embedded fallback rules`.
3. Suggests retry when network is available.

Skills NEVER refuse to run because of fetch failure — degraded mode is acceptable, silent failure is not.

---

## Smoke test (per skill)

Every skill should ship with a smoke-test reference — a known-input → known-output example documented in the SKILL.md, so reviewers can verify the skill produces sensible output.

```markdown
## Smoke test

Input: a vanilla "Hello Dolly" plugin (~/test-plugins/hello-dolly/).
Expected output:
  - 0 Critical findings
  - 1 Medium ("Plugin Header missing 'Requires PHP'")
  - Cites <fetched-source> + today's date
```

This is the "eval / reference" the user asked for. When you change a skill, run it against the smoke-test input — if the output drifts unexpectedly, you've broken something.

`/orbit-skill-improver --check-smoke` runs every skill against its smoke-test input (when one exists) and flags regressions.

---

## Aligning with WordPress/agent-skills

WordPress core ships its own AI agent skills via `npx openskills install WordPress/agent-skills` (Jan 2026, [announcement](https://wordpress.org/news/2026/01/new-ai-agent-skill/)). Orbit **wraps**, doesn't reimplement:

- `install.sh` chains `npx openskills install WordPress/agent-skills` after symlinking Orbit's own skills
- `/orbit-wp-playground` is a thin doc-only skill that points at WP's `wp-playground` for the AI feedback loop
- Orbit's skills focus on QA / UAT / audit; WP's skills focus on agent-runtime primitives. They compose.

When WP core ships more agent skills, Orbit picks them up automatically via the same `npx openskills install` chain — no Orbit code change needed.

---

## How a skill becomes truly evergreen — checklist

For every skill, verify:

- [ ] Has a `## Runtime — fetch live before auditing` section near the top
- [ ] Lists 2-5 canonical URLs as the live source of truth
- [ ] Says "fetch first, derive rules from fetched content"
- [ ] Cites fetched URL + date in finding output
- [ ] Has `## Embedded fallback rules` for offline mode
- [ ] Has a `## Smoke test` reference
- [ ] Has `## Sources & Evergreen References` (the documentation list, kept for reference)

`/orbit-skill-improver` (rewrite of the old `/orbit-evergreen-update`) walks every skill and adds missing sections. Run quarterly OR after every WP minor release OR whenever the user types `/orbit-skill-improver --apply`.

---

## When to break the pattern

Some skills don't have an external canonical source — purely internal patterns (e.g., `/orbit-pre-commit`, `/orbit-multi-plugin`, `/orbit-reports`). Those skills can omit the `Runtime — fetch live` section and rely on embedded rules only. But they're a small minority — most skills (~80 of 116) have a canonical source on the open web, so they MUST be runtime-evergreen.

---

## Built by

[Aditya Sharma](https://adityaarsharma.com) · POSIMYTH Innovation
github.com/adityaarsharma/orbit

**The discipline:** Software-quality tooling shouldn't freeze in the year it was written. It should know what *today* looks like by re-reading the canonical sources every time it runs.
