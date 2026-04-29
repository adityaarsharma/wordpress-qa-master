---
name: orbit-skill-improver
description: The action-mode meta-skill that REWRITES other Orbit skills. For every `~/.claude/skills/orbit-*/SKILL.md`, fetches the canonical sources listed in `Sources & Evergreen References`, diffs against embedded rules, proposes patches, and (with `--apply` or `--pr`) modifies the SKILL.md files. Replaces the read-only `/orbit-evergreen-update`. Use when the user says "improve skills", "skill-improver", "update orbit skills with current docs", "retrofit runtime-evergreen pattern", or quarterly + after every major WP release.
argument-hint: [--check | --apply | --pr] [--specific orbit-X]
---

# 🪐 orbit-skill-improver — The skill that improves skills

`/orbit-evergreen-update` only flagged drift. This one **acts** — fetches sources, diffs rules, edits SKILL.md, opens PRs.

---

## Three modes

```
/orbit-skill-improver --check                  # Read-only — list drift, propose changes (default)
/orbit-skill-improver --apply                  # Modify SKILL.md files in place + bump Last reviewed
/orbit-skill-improver --pr                     # Same as --apply but commit to a branch + open PR
```

Plus targeted runs:
```
/orbit-skill-improver --specific orbit-elementor-compat       # Just one skill
/orbit-skill-improver --source <url>                          # Re-check every skill that links to <url>
/orbit-skill-improver --check-smoke                           # Run smoke tests + flag regressions
```

---

## What `--check` produces

For each `~/.claude/skills/orbit-*/SKILL.md`:

1. **Parse** the `Sources & Evergreen References` section → URL list
2. **WebFetch** every URL in parallel
3. **Diff** the fetched content vs the rules embedded in the skill
4. **Categorise** drift:
   - **Stale rule**: skill says X, source now says Y
   - **Missing rule**: source has new pattern the skill doesn't cover
   - **Dead rule**: skill cites a function/API that no longer exists
   - **Broken link**: source URL 404s / redirects
   - **Stale Last reviewed**: > 90 days old
5. **Output**: a diff-style report with proposed patches

```
[Drift] orbit-block-bindings/SKILL.md
  - L42: rule says "apiVersion 3 is current"
    source diff: WP 7.0 introduces apiVersion 4 (per make.wordpress.org/core 2026-04-29)
    proposed patch:
       - apiVersion 3 (WP 6.5+) is current
       + apiVersion 3 (WP 6.5+) → apiVersion 4 (WP 7.0+); use 4 if Requires at least: 7.0+

  - L78: link https://make.wordpress.org/core/2024/03/06/new-feature-the-block-bindings-api/
    status: 200 OK (no fix needed)

  Last reviewed: 2026-04-29 (1 day stale, OK)
```

---

## What `--apply` does

Same as `--check`, but actually edits SKILL.md:

- Replaces stale rule text with proposed patch
- Updates `Last reviewed:` to today's date
- Adds a `# Auto-updated by /orbit-skill-improver on YYYY-MM-DD` comment line in the change

Always conservative — won't auto-apply if:
- Multiple sources disagree (hold for human review)
- Patch removes >30% of rule text (hold for human review)
- Skill was last manually edited within 7 days (defer to human's recent intent)

---

## What `--pr` does

Adds on top of `--apply`:
1. Creates a branch `orbit-skill-improver/auto-update-YYYY-MM-DD`
2. Commits per-skill (one commit per SKILL.md changed, atomic for review)
3. Pushes branch
4. Opens a single PR with all commits, body summarising changes
5. Requests review (no auto-merge — human must approve)

Suitable for quarterly maintenance from CI:
```yaml
- run: claude "/orbit-skill-improver --pr"
```

---

## What `--check-smoke` does

For each skill that has a `## Smoke test` section:
1. Read the documented input + expected output
2. Run the skill against the input
3. Compare actual output to expected
4. Flag mismatches

```
[Smoke test] orbit-do-it
  Input: ~/test-plugins/hello-dolly/
  Expected: SHIP verdict, 0 critical, < 3 min
  Actual:   SHIP verdict, 0 critical, 4m12s
  Status: ⚠ time exceeded by 24s (rules unchanged; CPU-throttle issue)
```

---

## Self-improvement loop

After running across all 116 skills, output a "skill-of-skills" summary:
- Which sources changed most this quarter
- Which skill categories had the most drift
- Which links 404'd (need manual replacement)
- Which embedded fallback rules diverged most from live sources (signal that the skill should be runtime-evergreen, not snapshot)

The output of one run can drive priorities for the next quarter.

---

## Source authority reranking

When a skill cites multiple sources and they disagree, weight by authority:

```
Authority score (highest → lowest):
1. WordPress.org / make.wordpress.org           (weight 10)
2. Official vendor docs (elementor.com, stripe.com)  (weight 9)
3. Spec docs (W3C, IETF, MDN)                   (weight 9)
4. Active GitHub repos with recent commits      (weight 7)
5. Patchstack / WPScan official feeds           (weight 9 for security)
6. Practitioner blogs / aggregators             (weight 5)
7. Community Q&A (Stack Overflow, Reddit)       (weight 3)
```

When proposing a patch from conflicting sources, prefer the higher-weight one + flag the conflict in the report.

---

## Operating rhythm

Recommended cadence:

- **Daily** (lightweight): `/orbit-skill-improver --check --specific orbit-cve-check` (security feed only)
- **Weekly** (medium): `--check` across all skills
- **Quarterly** (full): `--pr` to open a real review-able update
- **After every major release** (WP 7.0, Elementor V5): manual `--source <release-notes-url>` to re-pull

---

## Smoke test

Input: a fresh `~/Claude/orbit/skills/orbit-block-bindings/SKILL.md`
Expected (today, 2026-04-30):
- 0 stale rules (just released v2.6, sources unchanged)
- 0 broken links
- Bump `Last reviewed:` to today

After 6 months without manual update + a WP minor release that adds new Block Bindings sources:
- 1-2 stale rules expected
- patches proposed
- `--apply` updates the skill in place

---

## Pair with

- Every other Orbit skill — this one improves them all
- `/orbit-cve-check` — actually has a live feed (this skill verifies it's still using the current canonical URL)

---

## Sources & Evergreen References

### Live sources (used by this skill on every run)
- The `Sources & Evergreen References` section of every other Orbit skill
- [GitHub API](https://docs.github.com/en/rest) — for branch / PR creation
- [WebFetch tool docs](https://docs.anthropic.com/en/docs/claude-code/skills) — Claude's runtime

### Last reviewed
2026-04-30 — this is the meta-skill; running it bumps every other skill's `Last reviewed`
