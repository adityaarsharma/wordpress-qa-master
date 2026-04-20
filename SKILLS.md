# Skill Commands for WordPress QA Master

This repo is designed to work with Claude Code and its installed skills. Each section below shows which skills to invoke for each QA task — individually or as part of a full gauntlet run.

---

## How to Use Skills with This Repo

When running Claude Code against your plugin, prefix your prompt with the skill name:

```bash
# From your plugin directory
claude "/skill-name Do X for this plugin"

# Or from this QA repo, pointing at your plugin
claude "/skill-name Review /path/to/my-plugin for WordPress coding standards"
```

---

## QA Task → Skill Mapping

### Code Quality Review

```
/wordpress-plugin-development
Review the plugin at [path] for WordPress plugin development best practices:
- Plugin header, activation/deactivation/uninstall hooks
- REST API registration, Gutenberg block patterns
- Sanitization, escaping, nonce usage, capability checks
- Hook priorities, autoloader pattern
```

```
/wordpress
Check [path] against WordPress coding standards:
- Naming conventions (functions, classes, hooks, files)
- PHP DocBlocks, inline documentation
- Proper use of WordPress APIs vs rolling custom solutions
```

### Security Audit

```
/wordpress-penetration-testing
Run a full security audit on [path]:
- XSS via missing esc_html/esc_attr/wp_kses_post
- CSRF via missing nonce verification on forms + AJAX + REST
- SQL injection via missing $wpdb->prepare()
- Auth bypass — check all REST permission_callback
- Privilege escalation — missing current_user_can() checks
- Path traversal in file operations
- SSRF in any URL fetching (wp_remote_get)
```

### Performance Analysis

```
/performance-engineer
Analyze [path] for WordPress performance issues:
- N+1 database queries (same query in a loop)
- Missing object cache usage (wp_cache_get/set)
- Assets enqueued unconditionally on every page
- Synchronous HTTP calls blocking page loads (wp_remote_get in init hook)
- Heavy operations not deferred to wp_cron
- Hook priorities on hot paths (init, wp_loaded, wp_head)
```

### Database Optimization

```
/database-optimizer
Review [path] database patterns:
- wp_options autoload flags — large/rarely-read options should be autoload=no
- wp_postmeta query efficiency — missing meta_key index usage
- Bulk operations not using batching
- Transient cleanup — are transients deleted on uninstall?
- Direct DB queries vs WP APIs
- N+1 patterns in WP_Query loops
```

### UI/UX Design Review

```
/antigravity-design-expert
Review the admin UI in [path]/admin/ against these principles:
- Concentric border radius on nested elements (outer = inner + padding)
- Optical alignment for icons and buttons
- Shadows over borders for depth
- Scale on press = 0.96 for interactive elements
- Font smoothing at root
- Tabular numbers on any counters/stats
- Minimum 44x44px hit areas
- No transition:all — list specific properties
```

```
/ui-ux-designer
Review the admin panel and widget settings UI in [path]:
- Progressive disclosure — hide advanced options until needed
- Form labels on all inputs (no placeholder-only labels)
- Error states clear and actionable
- Success feedback on save actions
- Destructive actions require confirmation
- Settings grouped logically, max 5 top-level tabs
- Complex widgets: is the flow obvious? Can a user complete task in <3 clicks?
```

### Full Holistic Plugin Review

```
/production-code-audit
Run a full production readiness audit on [path]:
1. Security vulnerabilities (XSS, CSRF, SQLi, auth)
2. Performance bottlenecks (DB, caching, assets)
3. Code quality (SOLID, WP standards, dead code)
4. Error handling (PHP errors, AJAX error states, REST error responses)
5. Uninstall cleanup (does plugin clean up its data?)
6. Compatibility risks (PHP versions, WP versions, popular plugins)
Flag: critical / high / medium / low with file:line references.
```

### Changelog-Based Testing

```
/wordpress-plugin-development
Read CHANGELOG.md and identify what changed in the latest version.
For each change, suggest the most targeted Playwright test to verify it works:
- New widget/block → test it renders on frontend
- Admin setting added → test it saves correctly
- Performance fix → test DB query count didn't regress
- Security fix → write a test that verifies the patch
Output a test plan with file:line pointers for new test cases.
```

### Browser/E2E Automation Workflow

```
/antigravity-workflows
Execute the "QA and Browser Automation" workflow for my WordPress plugin.
Plugin path: [path]
Test site: [http://tpa-test.local or http://nexterwp-test.local]
Run through: admin panel, frontend rendering, Elementor editor, responsive viewports.
Use Playwright MCP for browser control.
```

### Theme Development Review (NexterWP)

```
/wordpress-theme-development
Review the NexterWP theme at [path]:
- Theme header, required files (style.css, index.php, functions.php)
- Template hierarchy usage
- Child theme compatibility
- Proper use of wp_enqueue_scripts, add_theme_support
- Customizer API implementation
- WooCommerce compatibility hooks
- Block theme requirements (theme.json, block templates)
```

### WooCommerce / EDD Integration

```
/wordpress-woocommerce-development
Review [path] for WooCommerce/EDD compatibility:
- Hook into WC lifecycle correctly (woocommerce_loaded)
- Not overriding WC templates directly
- Using WC CRUD objects, not direct DB queries
- Payment gateway security if applicable
- Correct capability checks on store actions
```

---

## Antigravity Skill Orchestrator

For complex multi-step tasks, use the orchestrator to automatically chain the right skills:

```
/antigravity-skill-orchestrator
Run a complete pre-release quality check on my WordPress plugin at [path].
I need: security audit + performance review + UI/UX check + database optimization + coding standards.
Orchestrate the right skills in the right order and give me a prioritized findings report.
```

The orchestrator will:
1. Break down the task
2. Search memory for similar plugin audits
3. Assemble the right skill sequence
4. Execute each skill with checkpoints
5. Merge findings into a single prioritized report

---

## Antigravity Workflows — Pre-Built Sequences

### Full QA + Browser Automation Workflow

```
/antigravity-workflows
Execute the "QA and Browser Automation" workflow for:
- Plugin: The Plus Addons for Elementor
- Test site: http://tpa-test.local
- Focus: full E2E, visual regression, responsive
```

### Security Audit Workflow

```
/antigravity-workflows
Execute the "Security Audit for Web App" workflow adapted for WordPress plugins.
Target: [path/to/plugin]
Scope: PHP backend security only (no frontend JS).
```

---

## Individual Skill Quick Reference

| Task | Skill Command |
|---|---|
| WP coding standards | `/wordpress` |
| Plugin dev best practices | `/wordpress-plugin-development` |
| Security scan | `/wordpress-penetration-testing` |
| Theme review | `/wordpress-theme-development` |
| Performance analysis | `/performance-engineer` |
| DB optimization | `/database-optimizer` |
| UI/UX principles | `/antigravity-design-expert` |
| Admin UI quality | `/ui-ux-designer` |
| Production readiness | `/production-code-audit` |
| Full orchestrated audit | `/antigravity-skill-orchestrator` |
| Multi-step QA workflow | `/antigravity-workflows` |
| Code refactoring | `/code-refactoring-refactor-clean` |
| Security hardening | `/security-scanning-security-hardening` |
| Accessibility audit | `/accessibility-compliance-accessibility-audit` |
| Common WP mistakes | See `docs/common-wp-mistakes.md` |

---

## Claude Code One-Liners

Run these directly from terminal against your plugin:

```bash
# Full security scan
claude "/wordpress-penetration-testing Audit ~/plugins/the-plus-addons for all OWASP Top 10 vulnerabilities"

# Performance deep-dive
claude "/performance-engineer Find all N+1 queries and caching issues in ~/plugins/the-plus-addons/includes/"

# Admin UI review
claude "/antigravity-design-expert Review the settings UI in ~/plugins/the-plus-addons/admin/ against concentric radius, hit areas, and animation principles"

# Full pre-release audit (4 agents in parallel)
claude "Run 4 parallel audit agents on ~/plugins/the-plus-addons:
1. /wordpress-plugin-development — WP standards
2. /wordpress-penetration-testing — security
3. /performance-engineer — performance
4. /database-optimizer — database
Dispatch all 4 simultaneously, merge findings by severity."
```
