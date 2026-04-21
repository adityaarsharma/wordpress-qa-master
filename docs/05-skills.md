# Claude Skills — Complete Reference

> All 6 mandatory core skills + 5 add-on skills. What each one finds, real vulnerability examples with bad→fixed code, and exactly how to invoke them.

---

## Table of Contents

1. [How Skills Work](#1-how-skills-work)
2. [Core Skill 1 — WordPress Plugin Development](#2-core-skill-1--wordpress-plugin-development)
3. [Core Skill 2 — WordPress Penetration Testing](#3-core-skill-2--wordpress-penetration-testing)
4. [Core Skill 3 — Performance Engineer](#4-core-skill-3--performance-engineer)
5. [Core Skill 4 — Database Optimizer](#5-core-skill-4--database-optimizer)
6. [Core Skill 5 — Accessibility Compliance](#6-core-skill-5--accessibility-compliance)
7. [Core Skill 6 — Code Review Excellence](#7-core-skill-6--code-review-excellence)
8. [Add-on: antigravity-design-expert](#8-add-on-antigravity-design-expert)
9. [Add-on: wordpress-theme-development](#9-add-on-wordpress-theme-development)
10. [Add-on: wordpress-woocommerce-development](#10-add-on-wordpress-woocommerce-development)
11. [Add-on: api-security-testing](#11-add-on-api-security-testing)
12. [Add-on: php-pro](#12-add-on-php-pro)
13. [Choosing Skills by Plugin Type](#13-choosing-skills-by-plugin-type)
14. [Skill Deduplication Reference](#14-skill-deduplication-reference)
15. [Custom Skill Prompts](#15-custom-skill-prompts)

---

## 1. How Skills Work

Skills are Claude Code specialists — markdown files at `~/.claude/skills/` that give Claude Code expert-level domain knowledge. When you invoke a skill with `/skill-name`, Claude Code loads that domain knowledge and applies it to whatever you're auditing.

```bash
# How the gauntlet invokes a skill
claude "/wordpress-penetration-testing
Security audit the WordPress plugin at: /path/to/plugin
Check: XSS, CSRF, SQLi, auth bypass, path traversal.
Rate each finding Critical / High / Medium / Low.
Output a full markdown report with a severity summary table at the top." \
  > reports/skill-audits/security.md

# How you invoke a skill directly
claude "/wordpress-penetration-testing Audit ~/plugins/my-plugin — OWASP Top 10"
```

Skills always write to files. Never output-only-to-terminal — that breaks the HTML report generator.

---

## 2. Core Skill 1 — WordPress Plugin Development

**Skill**: `/wordpress-plugin-development`
**Report**: `reports/skill-audits/wp-standards.md`

### What it checks

| Category | Checks |
|---|---|
| Escaping | Every output: `esc_html`, `esc_attr`, `esc_url`, `wp_kses_post` |
| Nonces | Forms, AJAX handlers, REST endpoints |
| Capabilities | `current_user_can()` before every privileged action |
| i18n | Text domain consistency, wrapped strings, `date_i18n()` vs `date()` |
| Hooks | Priority conflicts, `__return_false` misuse, `the_content` filter abuse |
| WP APIs | Using `$_SESSION` instead of transients, `file_get_contents` instead of `wp_remote_get` |
| Plugin header | Version numbers, text domain, PHP requirement |
| Uninstall | `uninstall.php` covers options, tables, cron, capabilities |
| Naming | Functions/classes/options prefixed with plugin slug |

### Real findings examples

**Missing escape — severity: High**

```php
// BAD — found in admin-page.php:47
echo '<h2>' . get_option('my_plugin_title') . '</h2>';

// FIXED
echo '<h2>' . esc_html( get_option( 'my_plugin_title' ) ) . '</h2>';
```

**Missing capability check — severity: Critical**

```php
// BAD — any logged-in user can delete data
add_action( 'admin_post_my_plugin_delete', function() {
    $id = intval( $_GET['id'] );
    delete_option( 'my_plugin_item_' . $id );
    wp_redirect( admin_url( 'admin.php?page=my-plugin' ) );
    exit;
});

// FIXED
add_action( 'admin_post_my_plugin_delete', function() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( esc_html__( 'You do not have permission to do this.', 'my-plugin' ) );
    }
    check_admin_referer( 'my_plugin_delete_' . intval( $_GET['id'] ) );

    $id = intval( $_GET['id'] );
    delete_option( 'my_plugin_item_' . $id );

    wp_redirect( admin_url( 'admin.php?page=my-plugin' ) );
    exit;
});
```

### Invoke directly

```bash
claude "/wordpress-plugin-development
Audit the WordPress plugin at: ~/plugins/my-plugin
Focus on: escaping, nonces, capability checks, i18n, uninstall cleanup.
Output markdown with severity table at top. File:line references required." \
  > reports/skill-audits/wp-standards.md
```

---

## 3. Core Skill 2 — WordPress Penetration Testing

**Skill**: `/wordpress-penetration-testing`
**Report**: `reports/skill-audits/security.md`

### What it checks — OWASP Top 10 for WordPress

| Vulnerability | What it looks for |
|---|---|
| **XSS** (Reflected, Stored, DOM) | `echo $_GET[...]`, unsanitized option values in output, JS `innerHTML` with WP data |
| **CSRF** | Forms missing `wp_nonce_field()`, AJAX missing `check_ajax_referer()` |
| **SQLi** | `$wpdb->query()` without `prepare()`, string concatenation in SQL |
| **Auth bypass** | Missing `permission_callback` on REST routes, `is_user_logged_in()` instead of `current_user_can()` |
| **Path traversal** | `file_get_contents()` with user input, `include` with `$_GET` |
| **Object injection** | `unserialize()` on user-controlled data |
| **Privilege escalation** | `update_user_meta()` with user-supplied role, capability assignment from input |
| **SSRF** | `wp_remote_get()` with unsanitized URL parameter |
| **File upload RCE** | Missing MIME type validation, no `.htaccess` protection |
| **Insecure Direct Object Reference** | Accessing other users' data without ownership check |

### Real findings examples

**SQL injection — severity: Critical**

```php
// BAD — found in class-search.php:112
function my_plugin_search( $keyword ) {
    global $wpdb;
    return $wpdb->get_results(
        "SELECT * FROM {$wpdb->prefix}my_plugin_items WHERE name LIKE '%" . $keyword . "%'"
    );
}

// FIXED
function my_plugin_search( $keyword ) {
    global $wpdb;
    return $wpdb->get_results(
        $wpdb->prepare(
            "SELECT * FROM {$wpdb->prefix}my_plugin_items WHERE name LIKE %s",
            '%' . $wpdb->esc_like( sanitize_text_field( $keyword ) ) . '%'
        )
    );
}
```

**Missing REST permission callback — severity: Critical**

```php
// BAD — any visitor can call this endpoint
register_rest_route( 'my-plugin/v1', '/export', [
    'methods'  => 'GET',
    'callback' => 'my_plugin_export_all_data',
]);

// FIXED
register_rest_route( 'my-plugin/v1', '/export', [
    'methods'             => 'GET',
    'callback'            => 'my_plugin_export_all_data',
    'permission_callback' => function() {
        return current_user_can( 'export' );
    },
]);
```

**Stored XSS via meta — severity: High**

```php
// BAD — meta value echoed without escape
function my_plugin_render_widget() {
    $title = get_post_meta( get_the_ID(), '_mp_widget_title', true );
    echo '<h3>' . $title . '</h3>';  // XSS if meta was saved from user input
}

// FIXED
function my_plugin_render_widget() {
    $title = get_post_meta( get_the_ID(), '_mp_widget_title', true );
    echo '<h3>' . esc_html( $title ) . '</h3>';
}
```

### Invoke directly

```bash
claude "/wordpress-penetration-testing
Security audit the WordPress plugin at: ~/plugins/my-plugin
Check: XSS (reflected + stored + DOM), CSRF, SQLi, auth bypass, path traversal,
object injection, privilege escalation, SSRF, file upload RCE, IDOR.
OWASP Top 10 for WordPress. Rate each finding Critical / High / Medium / Low with CVSS context.
List every finding with file:line. Include code diff for Critical/High.
Output full markdown with severity summary table at the top." \
  > reports/skill-audits/security.md
```

---

## 4. Core Skill 3 — Performance Engineer

**Skill**: `/performance-engineer`
**Report**: `reports/skill-audits/performance.md`

### What it checks

| Area | Checks |
|---|---|
| **Hook callbacks** | Expensive logic on `init`, `wp_head`, `wp_footer`, `shutdown` |
| **N+1 queries** | DB calls inside loops — should use `update_postmeta_cache()` |
| **Asset loading** | CSS/JS loaded on every page vs conditionally |
| **Blocking resources** | Scripts in `<head>` not deferred |
| **Expensive loops** | `get_posts(['numberposts' => -1])`, unbounded `WP_Query` |
| **External HTTP on page load** | Synchronous `wp_remote_get()` in `init` or `wp_head` |
| **Object caching** | Missing transients around expensive computations |
| **Autoload** | Large data stored in autoloaded options |

### Real findings examples

**N+1 queries — severity: High**

```php
// BAD — 50 queries for 50 posts
$posts = get_posts([ 'numberposts' => 50 ]);
foreach ( $posts as $post ) {
    $featured = get_post_meta( $post->ID, '_mp_featured', true ); // 50 queries!
}

// FIXED — 1 query total
$posts    = get_posts([ 'numberposts' => 50 ]);
$post_ids = wp_list_pluck( $posts, 'ID' );
update_postmeta_cache( $post_ids ); // primes the cache — 1 query

foreach ( $posts as $post ) {
    $featured = get_post_meta( $post->ID, '_mp_featured', true ); // hits cache, 0 queries
}
```

**Blocking external HTTP — severity: High**

```php
// BAD — blocks every page load if API is slow
add_action( 'init', function() {
    $data = wp_remote_get( 'https://api.example.com/config' );
    // process $data...
});

// FIXED — cache for 1 hour, only fetch when cache is empty
add_action( 'init', function() {
    $data = get_transient( 'mp_api_config' );
    if ( false === $data ) {
        $response = wp_remote_get( 'https://api.example.com/config' );
        if ( ! is_wp_error( $response ) ) {
            $data = wp_remote_retrieve_body( $response );
            set_transient( 'mp_api_config', $data, HOUR_IN_SECONDS );
        }
    }
});
```

---

## 5. Core Skill 4 — Database Optimizer

**Skill**: `/database-optimizer`
**Report**: `reports/skill-audits/database.md`

### What it checks

| Area | Checks |
|---|---|
| **Prepared statements** | All `$wpdb` calls use `prepare()` |
| **N+1 patterns** | Same query inside a loop |
| **Custom tables** | Missing indexes on foreign keys and search columns |
| **Autoload bloat** | Options > 10KB with `autoload = yes` |
| **Transient patterns** | Missing transients around expensive queries |
| **Unbounded queries** | `LIMIT` missing, `SELECT *` without column filtering |
| **Raw SQL** | Direct SQL strings instead of `$wpdb->insert()`, `$wpdb->update()` |

### Real findings examples

**Autoload bloat — severity: Medium**

```php
// BAD — stores a big array in autoloaded options (loaded on every request)
update_option( 'my_plugin_all_data', $huge_array );
//             loads 200KB on every page load

// FIXED — mark large data as non-autoload
update_option( 'my_plugin_all_data', $huge_array, false );
//                                                 ^^^^^ — autoload = no
```

**Missing index on custom table — severity: High**

```php
// BAD — table created without index on frequently queried column
function my_plugin_create_table() {
    global $wpdb;
    $wpdb->query( "CREATE TABLE {$wpdb->prefix}mp_items (
        id bigint(20) NOT NULL AUTO_INCREMENT,
        user_id bigint(20) NOT NULL,
        status varchar(20) DEFAULT 'active',
        created_at datetime NOT NULL,
        PRIMARY KEY (id)
        -- Missing index on user_id! Every user lookup is a full table scan
    ) {$wpdb->get_charset_collate()}" );
}

// FIXED
$wpdb->query( "CREATE TABLE {$wpdb->prefix}mp_items (
    id bigint(20) NOT NULL AUTO_INCREMENT,
    user_id bigint(20) NOT NULL,
    status varchar(20) DEFAULT 'active',
    created_at datetime NOT NULL,
    PRIMARY KEY (id),
    KEY user_id (user_id),      -- index for user lookups
    KEY status (status)         -- index for status filtering
) {$wpdb->get_charset_collate()}" );
```

---

## 6. Core Skill 5 — Accessibility Compliance

**Skill**: `/accessibility-compliance-accessibility-audit`
**Report**: `reports/skill-audits/accessibility.md`
**Standard**: WCAG 2.2 AA

### What it checks

| Area | Checks |
|---|---|
| **Admin UI** | Labels on form fields, keyboard navigation through settings panels |
| **Block output** | ARIA roles on custom blocks, heading hierarchy |
| **Color contrast** | Text/background ratio ≥ 4.5:1 (AA) |
| **Focus management** | Focus visible on all interactive elements, skip links |
| **Screen readers** | `aria-label` on icon-only buttons, live regions for dynamic updates |
| **Images** | `alt` text on all `<img>`, decorative images with `alt=""` |
| **Forms** | `for`/`id` pairing on labels, error messages associated with fields |
| **Keyboard** | All interactive elements reachable and operable via Tab / Enter / Space |
| **Motion** | `prefers-reduced-motion` respected for animations |

### Real findings examples

**Missing label — severity: High**

```php
// BAD — screen reader has no idea what this input is for
echo '<input type="text" name="mp_api_key" value="">';

// FIXED
echo '<label for="mp_api_key">' . esc_html__( 'API Key', 'my-plugin' ) . '</label>';
echo '<input type="text" id="mp_api_key" name="mp_api_key"
      aria-describedby="mp_api_key_desc" value="">';
echo '<p id="mp_api_key_desc">' . esc_html__( 'Enter your API key from the dashboard.', 'my-plugin' ) . '</p>';
```

**Icon-only button — severity: High**

```php
// BAD — screen reader announces "button" with no label
echo '<button class="mp-delete-btn"><span class="dashicons dashicons-trash"></span></button>';

// FIXED
echo '<button class="mp-delete-btn" aria-label="' . esc_attr__( 'Delete item', 'my-plugin' ) . '">
    <span class="dashicons dashicons-trash" aria-hidden="true"></span>
</button>';
```

---

## 7. Core Skill 6 — Code Review Excellence

**Skill**: `/code-review-excellence`
**Report**: `reports/skill-audits/code-quality.md`

### What it checks

| Area | Checks |
|---|---|
| **Dead code** | Commented-out code blocks, unused functions/classes, unreachable branches |
| **Cyclomatic complexity** | Functions with >10 branches (hard to test, easy to break) |
| **Error handling** | `is_wp_error()` checks after `wp_remote_get()`, graceful fallbacks |
| **Type safety** | Missing type hints, implicit type coercion bugs |
| **Readability** | Magic numbers, unclear variable names, missing docblocks on public APIs |
| **PHP 8.x compatibility** | Deprecated functions, null-safe operator opportunities |
| **DRY violations** | Copy-pasted blocks that should be extracted into functions |
| **Test coverage gaps** | Branches with no corresponding test coverage |

### Real findings examples

**Missing error handling — severity: High**

```php
// BAD — if API returns WP_Error, code crashes on next line
$response = wp_remote_get( 'https://api.example.com/data' );
$body     = wp_remote_retrieve_body( $response );
$data     = json_decode( $body );

// FIXED
$response = wp_remote_get( 'https://api.example.com/data' );
if ( is_wp_error( $response ) ) {
    // Log and return a safe default
    error_log( 'My Plugin: API request failed: ' . $response->get_error_message() );
    return [];
}

$body = wp_remote_retrieve_body( $response );
$data = json_decode( $body, true );
if ( JSON_ERROR_NONE !== json_last_error() ) {
    error_log( 'My Plugin: Invalid JSON from API: ' . json_last_error_msg() );
    return [];
}
```

**High complexity — severity: Medium**

```php
// BAD — 14 nested conditions, impossible to unit-test
function my_plugin_process( $data ) {
    if ( isset( $data['type'] ) ) {
        if ( $data['type'] === 'post' ) {
            if ( isset( $data['id'] ) && $data['id'] > 0 ) {
                if ( current_user_can( 'edit_post', $data['id'] ) ) {
                    if ( get_post_status( $data['id'] ) === 'publish' ) {
                        // ... more nesting ...
```

```php
// FIXED — extract conditions into named functions
function my_plugin_process( $data ) {
    if ( ! my_plugin_is_valid_post_data( $data ) ) {
        return new WP_Error( 'invalid_data', 'Invalid data' );
    }
    if ( ! my_plugin_user_can_edit( $data['id'] ) ) {
        return new WP_Error( 'forbidden', 'Not allowed' );
    }
    return my_plugin_do_process( $data );
}
```

---

## 8. Add-on: antigravity-design-expert

**Skill**: `/antigravity-design-expert`
**When to use**: Elementor addons, UI-heavy plugins, landing page builders
**What it adds** (beyond the 6 core skills):

| Check | Detail |
|---|---|
| **Hit areas** | All interactive elements ≥ 44×44px (iOS HIG + WCAG 2.5.5) |
| **Concentric radius** | Nested border-radius values follow the `outer - padding` formula |
| **Visual hierarchy** | Typography scale, spacing rhythm, color usage consistency |
| **GSAP / animation quality** | `will-change` usage, 60fps frame budget, `prefers-reduced-motion` |
| **Spacing** | 8px grid system consistency |
| **Mobile polish** | Touch target sizing, tap highlight removal, scroll behavior |

**Invoke**:
```bash
claude "/antigravity-design-expert
Design audit the Elementor addon at: ~/plugins/my-elementor-plugin
Check: 44px hit areas, concentric border radius, spacing consistency,
animation performance (60fps, will-change), mobile tap targets.
Rate each finding: Critical / High / Medium / Low.
Output full markdown with severity table." \
  > reports/skill-audits/design.md
```

---

## 9. Add-on: wordpress-theme-development

**Skill**: `/wordpress-theme-development`
**When to use**: Gutenberg block plugins, FSE themes, Gutenberg-first plugins
**What it adds**:

| Check | Detail |
|---|---|
| **block.json** | All blocks use `block.json`, not PHP-only registration |
| **block supports** | `supports.color`, `supports.typography`, `supports.spacing` declared |
| **Template hierarchy** | Custom templates follow WP template hierarchy rules |
| **FSE / theme.json** | `theme.json` `color.palette`, `typography.fontSizes` properly declared |
| **Block transforms** | Transform from/to related block types |
| **Editor vs frontend** | Editor-only CSS/JS not loaded on frontend |
| **Server-side rendering** | `render_callback` for dynamic blocks, not just `save` |

**Invoke**:
```bash
claude "/wordpress-theme-development
Audit the Gutenberg block plugin at: ~/plugins/my-blocks
Check: block.json completeness, block supports, FSE patterns, server-side rendering.
Output markdown with severity table." \
  > reports/skill-audits/gutenberg.md
```

---

## 10. Add-on: wordpress-woocommerce-development

**Skill**: `/wordpress-woocommerce-development`
**When to use**: Any plugin that hooks into WooCommerce
**What it adds**:

| Check | Detail |
|---|---|
| **WC hooks** | Using correct WC action/filter names, not WP core hooks for WC events |
| **Gateway security** | Payment gateway callback verification, order status checks |
| **Template overrides** | Templates in `templates/woocommerce/` follow WC conventions |
| **Cart / checkout safety** | Nonces on cart actions, sanitized quantities |
| **Product meta** | Correct use of `wc_get_product()` vs `get_post()` |
| **WC version compatibility** | Deprecated WC function usage flagged |
| **REST API** | WC REST API custom endpoints follow WC auth patterns |

**Invoke**:
```bash
claude "/wordpress-woocommerce-development
Audit the WooCommerce extension at: ~/plugins/my-woo-plugin
Check: WC hooks, gateway security, template overrides, cart safety.
Output markdown with severity table." \
  > reports/skill-audits/woocommerce.md
```

---

## 11. Add-on: api-security-testing

**Skill**: `/api-security-testing`
**When to use**: REST API plugins, headless WordPress setups
**What it adds**:

| Check | Detail |
|---|---|
| **Endpoint auth** | Every endpoint has `permission_callback`, not just `__return_true` |
| **Input validation** | `sanitize_callback` on all registered REST params |
| **Rate limiting** | Expensive endpoints have nonce or throttle protection |
| **CORS** | `Access-Control-Allow-Origin` headers correctly scoped |
| **Response leakage** | Error messages don't expose stack traces or user data |
| **JWT / OAuth** | If used: token validation, expiry, refresh flow |
| **Enumeration** | `/wp-json/wp/v2/users` disclosure check |

**Invoke**:
```bash
claude "/api-security-testing
Audit all REST endpoints in: ~/plugins/my-rest-plugin
Check: auth on every route, input sanitization, rate limiting, CORS, response leakage.
Output markdown with severity table." \
  > reports/skill-audits/api-security.md
```

---

## 12. Add-on: php-pro

**Skill**: `/php-pro`
**When to use**: Complex OOP plugins, PHP 8.x modernization, strict typing
**What it adds**:

| Check | Detail |
|---|---|
| **Typed properties** | PHP 8.0+ typed class properties used where appropriate |
| **Null-safe operator** | `$obj?->method()` instead of nested null checks |
| **Named arguments** | Long function calls use named arguments for clarity |
| **Match expressions** | `match()` used instead of `switch` where applicable |
| **Readonly properties** | VO/DTO classes use `readonly` |
| **Fibers** | Async patterns using PHP 8.1 Fibers where appropriate |
| **Enum types** | Status strings replaced by PHP 8.1 enums |
| **Constructor promotion** | `public function __construct( private string $name )` style |

**Invoke**:
```bash
claude "/php-pro
Modernize the PHP code in: ~/plugins/my-plugin/includes
Upgrade patterns to PHP 8.x: typed properties, match expressions, constructor promotion, null-safe.
Output markdown with file:line references." \
  > reports/skill-audits/php-modern.md
```

---

## 13. Choosing Skills by Plugin Type

| Plugin type | Core 6 | Add-on skills |
|---|---|---|
| General / utility plugin | ✓ All 6 | — |
| Elementor addon | ✓ All 6 | `antigravity-design-expert` |
| Gutenberg blocks | ✓ All 6 | `wordpress-theme-development` |
| WooCommerce extension | ✓ All 6 | `wordpress-woocommerce-development` |
| FSE theme | ✓ All 6 | `wordpress-theme-development` |
| REST API / headless | ✓ All 6 | `api-security-testing` |
| Complex PHP / DDD | ✓ All 6 | `php-pro` |
| Elementor + WooCommerce | ✓ All 6 | `antigravity-design-expert` + `wordpress-woocommerce-development` |
| Gutenberg + REST API | ✓ All 6 | `wordpress-theme-development` + `api-security-testing` |

---

## 14. Skill Deduplication Reference

Multiple skills with similar names exist in the ecosystem. Always use these:

| Task | ✓ Use | ✗ Skip |
|---|---|---|
| WP plugin audit | `/wordpress-plugin-development` | `/wordpress` (too generic) |
| Security | `/wordpress-penetration-testing` | `/security-audit`, `/security-scanning-security-sast` |
| Performance | `/performance-engineer` | `/performance-optimizer`, `/performance-profiling` |
| Database | `/database-optimizer` | `/database`, `/database-admin`, `/database-architect` |
| Accessibility | `/accessibility-compliance-accessibility-audit` | `/accessibility-review`, `/wcag-audit-patterns` |
| Code review | `/code-review-excellence` | `/code-review-ai-ai-review`, `/code-reviewer`, `/code-review-checklist` |
| E2E testing | `/playwright-skill` | `/e2e-testing`, `/playwright-java` |
| WooCommerce | `/wordpress-woocommerce-development` | `/woocommerce` |
| Design | `/antigravity-design-expert` | `/ui-ux-designer`, `/design-expert` |

---

## 15. Custom Skill Prompts

You can give skills additional context to get more targeted findings:

```bash
# Focused on a specific vulnerability type
claude "/wordpress-penetration-testing
Audit only the REST API endpoints in ~/plugins/my-plugin/includes/api/
Focus exclusively on: permission_callback completeness, input sanitization, rate limiting.
List every register_rest_route call and whether it has proper auth.
Output: table of endpoints with auth status."

# Focused on a known problem area
claude "/database-optimizer
Review only the WP_Query calls in ~/plugins/my-plugin/includes/
I suspect N+1 queries in the listing view. Find every get_post_meta inside a loop.
Show: file:line, query count estimate, fix with update_postmeta_cache."

# Comparing two approaches
claude "/code-review-excellence
Review ~/plugins/my-plugin/includes/class-cache.php
I'm considering replacing the current array-based cache with transients.
Assess: current approach's weaknesses, transient benefits for this use case,
migration risk. Output: recommendation with pros/cons table."

# Full audit with report format specified
claude "/wordpress-plugin-development
Audit ~/plugins/my-plugin
Output format:
## Critical Issues (block release)
## High Issues (fix in this PR)
## Medium Issues (fix next sprint)
## Low / Info (log for later)
Each with: description, file:line, bad code, fixed code."
```

---

**Next**: [docs/07-test-templates.md](07-test-templates.md) — complete test templates for every plugin type.
