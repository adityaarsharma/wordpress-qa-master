---
name: orbit-plugin-check
description: Run the official WordPress.org `plugin-check` tool against your plugin — wraps the official WP-CLI command. Fetches the LATEST release at runtime, verifies the user's installed version is current, and runs the checks the WP.org review team uses. Use when the user says "plugin-check", "WP.org submission", "official checks", or before any release destined for wp.org.
---

# 🪐 orbit-plugin-check — Wrapper for the official WP.org Plugin Check

> WP.org maintains the canonical submission-check tool. This skill ensures the user is running the latest release + invokes it correctly + interprets the output with WP.org-team severity levels.

---

## Runtime — fetch live before auditing (DO THIS FIRST)

When this skill is invoked:

1. **Fetch in parallel**:
   - https://github.com/WordPress/plugin-check/releases/latest → latest release tag
   - https://wordpress.org/plugins/plugin-check/ → WP.org listing for the plugin
   - https://make.wordpress.org/plugins/handbook/ → current submission rules

2. **Synthesize**:
   - "What's the latest plugin-check version as of today?"
   - "Is the user's installed plugin-check version stale?"
   - "Have any new check categories been added in the last release?"

3. **Run** `wp plugin check` against the plugin + interpret output.

---

## What it wraps

```bash
# Install via WP-CLI in the test wp-env
wp-env run cli wp plugin install plugin-check --activate

# Run the checks
wp-env run cli wp plugin check my-plugin

# Or with JSON output for parsing
wp-env run cli wp plugin check my-plugin --format=json
```

---

## What plugin-check finds (the rule categories)

WP.org plugin-check ships with these categories (per the latest release fetched today):

- **Security** — direct $_GET/$_POST without sanitization, missing nonces, capability checks
- **Performance** — basic perf anti-patterns
- **i18n / translation** — strings not wrapped, text-domain mismatch
- **readme.txt** — required fields, stable tag, tags ≤ 12, no trademarks
- **Plugin header** — required fields, GPL-compatible license
- **Code quality** — no `eval()`, no forbidden functions, no BOM, file-end newline
- **Block-specific** (if Gutenberg blocks) — block.json validity, file references exist

Specific rules grow each release — the runtime fetch detects new ones.

---

## Severity model (WP.org's own)

| Type | Severity | Submission action |
|---|---|---|
| ERROR | Block | WP.org review will reject |
| WARNING | Should fix | Often pushed back on; sometimes waved |
| INFO | Nice to have | Often ignored |

**Whitepaper intent:** WP.org review's actual reject-rate per category isn't published, but the plugin-check tool is what they USE — so passing plugin-check → high probability of acceptance, failing → near-certain rejection.

---

## Output

```markdown
# Plugin Check — my-plugin · 2026-04-30

> Per github.com/WordPress/plugin-check (fetched 2026-04-30 14:32 UTC):
> Latest plugin-check version: 1.10.x
> Your installed version: 1.9.0 (slightly stale; safe to use)

## ERRORS (must fix before submission)
- ❌ `eval()` detected — admin/legacy.php:42
- ❌ `Stable tag` mismatch — readme.txt says 2.3, plugin header says 2.4

## WARNINGS (recommended)
- ⚠ Direct `$_POST['x']` without sanitize — includes/class-form.php:88
- ⚠ Missing `Tested up to: 7.0` (per latest WP plugin handbook fetched today)

## INFO (nice-to-have)
- ℹ 3 strings could use translator comments

## Summary
- Errors: 2 (must fix)
- Warnings: 12
- Info: 4
- WP.org submission verdict: BLOCK until errors fixed
```

---

## .plugin-check-config.json (optional, sparingly)

```json
{
  "exclusions": [ "vendor/", "tests/", "build/" ],
  "skip": []
}
```

Don't skip security or forbidden-function checks. Those exist for reasons.

---

## Pair with

- `/orbit-release-meta` — plugin header / readme.txt / version parity
- `/orbit-zip-hygiene` — what's in the actual zip
- `/orbit-do-it` — orchestrator includes plugin-check on `--mode release`

---

## Smoke test

Input: a vanilla plugin with valid header + readme.
Expected:
- 0 errors, 0 warnings (if plugin is clean)
- Cites the latest plugin-check version fetched today
- Run completes < 30s

---

## Embedded fallback rules (offline)
- Latest plugin-check is at github.com/WordPress/plugin-check/releases/latest
- Install via WP-CLI: `wp plugin install plugin-check --activate`
- Run via WP-CLI: `wp plugin check <slug>`
- Output format: `--format=json` for parsing

## Sources & Evergreen References

### Live sources (fetched on every run)
- [WordPress/plugin-check GitHub](https://github.com/WordPress/plugin-check) — repo + releases
- [Plugin Check on WP.org](https://wordpress.org/plugins/plugin-check/)
- [Plugin Reviewers Handbook](https://make.wordpress.org/plugins/handbook/) — submission rules

### Last reviewed
2026-04-30 — runtime-evergreen, fetches latest release + handbook on every invocation
