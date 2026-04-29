---
name: orbit-broken-access-control
description: Deep audit for Broken Access Control — Patchstack 2026's #1 attack class (57% of all blocked attacks). Covers IDOR, missing capability checks, mass assignment, REST/AJAX auth bypass, role-confusion, privilege escalation paths. Goes deeper than `/orbit-wp-security` on this specific class. Use when the user says "broken access control", "IDOR", "privilege escalation", "auth bypass", "OWASP A01", or after a high-severity Patchstack alert.
---

# 🪐 orbit-broken-access-control — OWASP A01 deep audit

Per Patchstack's State of WP Security 2026, Broken Access Control accounts for **57% of all blocked attacks** — exploits that look like normal authenticated traffic, no obvious injection patterns, undetectable by generic WAFs. This skill specialises in finding them in source.

---

## Runtime — fetch live before auditing

When this skill is invoked:

1. **Fetch in parallel**:
   - https://patchstack.com/whitepaper/state-of-wordpress-security-in-2026/ → current attack stats + new patterns
   - https://patchstack.com/database/?type=broken-access-control → latest BAC CVEs in WP plugins
   - https://owasp.org/Top10/A01_2021-Broken_Access_Control/ → OWASP reference (kept current)
   - https://developer.wordpress.org/apis/security/ → WP-specific guidance

2. **Synthesize**: which BAC patterns are trending in WP plugins this quarter? What's the most-recent CVE pattern Patchstack has flagged?

3. **Audit the plugin** against fetched current patterns.

---

## What this skill checks (the 8 deadly BAC patterns in WP)

### 1. IDOR (Insecure Direct Object Reference)

Attacker changes an ID in the URL/POST and accesses someone else's data.

```php
// ❌ Fetches order without checking if THIS user owns it
function my_plugin_get_order() {
  check_ajax_referer( 'my_nonce', 'nonce' );
  $order_id = intval( $_POST['order_id'] );
  $order = wc_get_order( $order_id );
  wp_send_json( $order );  // anyone with a nonce can read any order
}

// ✅ Authorise the SPECIFIC object
function my_plugin_get_order() {
  check_ajax_referer( 'my_nonce', 'nonce' );
  $order_id = intval( $_POST['order_id'] );
  $order = wc_get_order( $order_id );

  // The check that's almost always missing
  if ( ! $order || $order->get_user_id() !== get_current_user_id() ) {
    wp_send_json_error( '', 403 );
  }
  wp_send_json( $order );
}
```

### 2. Missing capability check on state-changing actions

```php
// ❌ Just nonce — any logged-in user (even subscriber) can call
add_action( 'wp_ajax_my_save_settings', function() {
  check_ajax_referer( 'my_nonce', 'nonce' );
  update_option( 'my_critical_setting', $_POST['value'] );
});

// ✅ Capability + nonce
add_action( 'wp_ajax_my_save_settings', function() {
  check_ajax_referer( 'my_nonce', 'nonce' );
  if ( ! current_user_can( 'manage_options' ) ) wp_send_json_error( '', 403 );
  update_option( 'my_critical_setting', sanitize_text_field( $_POST['value'] ) );
});
```

### 3. REST `permission_callback => '__return_true'` (red flag)

```php
register_rest_route( 'my-plugin/v1', '/admin', [
  'callback' => 'my_admin_endpoint',
  'permission_callback' => '__return_true',  // ← always wrong for write/admin endpoints
] );
```

For read-only public endpoints `__return_true` is OK, but flag every instance for review.

### 4. Mass assignment

```php
// ❌ Update ALL fields from $_POST — attacker can set is_admin = true
update_user_meta( $user_id, 'profile', $_POST );

// ✅ Whitelist what you accept
$allowed = [ 'display_name', 'bio', 'website' ];
$update = array_intersect_key( $_POST, array_flip( $allowed ) );
foreach ( $update as $key => $value ) {
  update_user_meta( $user_id, $key, sanitize_text_field( $value ) );
}
```

### 5. Hidden admin URL "security"

```php
// ❌ "Hidden" admin page — accessible to anyone who knows the URL
add_action( 'admin_init', function() {
  if ( isset( $_GET['my_special_page'] ) ) {
    require_once 'admin/special.php';  // no auth check inside
  }
});

// ✅ Capability-gate at entry
add_action( 'admin_init', function() {
  if ( isset( $_GET['my_special_page'] ) ) {
    if ( ! current_user_can( 'manage_options' ) ) wp_die( 'Unauthorised', 403 );
    require_once 'admin/special.php';
  }
});
```

### 6. Role / capability confusion

```php
// ❌ Logical OR where AND was needed
if ( current_user_can( 'edit_posts' ) || $is_owner ) { ... }
// Subscriber who happens to be is_owner of NO post still passes

// ✅ Sequential checks with explicit precedence
if ( ! current_user_can( 'edit_posts' ) ) wp_die( 'Insufficient role' );
if ( ! my_plugin_user_owns_object( $object_id ) ) wp_die( 'Not your object' );
```

### 7. Privilege escalation via meta-update

```php
// ❌ User can update their own user_meta with arbitrary keys
function my_plugin_update_profile() {
  check_ajax_referer( 'my_nonce', 'nonce' );
  $user_id = get_current_user_id();
  foreach ( $_POST as $key => $value ) {
    update_user_meta( $user_id, $key, $value );  // attacker sets `wp_capabilities`
  }
}

// ✅ Block known-sensitive meta keys + whitelist
$BLOCKED = [ 'wp_capabilities', 'wp_user_level', 'session_tokens' ];
foreach ( $_POST as $key => $value ) {
  if ( in_array( $key, $BLOCKED, true ) ) continue;
  if ( ! in_array( $key, $ALLOWED, true ) ) continue;
  update_user_meta( $user_id, $key, sanitize_text_field( $value ) );
}
```

### 8. Cross-tenant leak (multisite + multi-user contexts)

```php
// ❌ Settings stored as global option but feature is per-user
update_option( 'my_user_pref_' . $user_id, $value );  // OK
$value = get_option( 'my_user_pref_' . $other_user_id );  // ← no auth check

// ✅ Always scope reads by current user's identity, not request input
$value = get_user_meta( get_current_user_id(), 'my_pref', true );
```

---

## Active probing pattern

Beyond static review, this skill optionally runs active probes:

```bash
PLUGIN_SLUG=my-plugin npx playwright test --project=bac-probe
```

The probe:
1. Logs in as a low-privilege user (subscriber)
2. Tries to call every admin AJAX action + REST endpoint
3. Tries to access every admin URL
4. Reports which return 200 (BAC bug) vs 403 (correct)

---

## Output

```markdown
# Broken Access Control — my-plugin · 2026-04-30

> Per Patchstack 2026 Whitepaper (fetched 2026-04-30):
> BAC = 57% of all blocked WP attacks. Top vuln class.

## Static findings
- ❌ CRITICAL: includes/class-orders.php:42 — IDOR
   `wc_get_order($_POST['id'])` without ownership check
   Probe: subscriber → call my_get_order with admin's order_id → leaks

- ❌ HIGH: REST /my-plugin/v1/admin uses `__return_true` permission_callback

- ⚠ MEDIUM: admin/special.php — capability check inside but loaded via $_GET
   detection — gate at the loader

## Active probe (subscriber-level user)
- 14 of 28 admin-AJAX actions returned 200 to subscriber → BAC
- 3 of 12 REST endpoints accessible without auth → BAC

## Severity: CRITICAL — block release immediately
```

---

## Pair with

- `/orbit-wp-security` — broader SAST
- `/orbit-rest-fuzzer` / `/orbit-ajax-fuzzer` — active probe specialists
- `/orbit-cve-check` — live CVE feed for any of these in your code's CVE neighbours
- `/orbit-premium-audit` — premium plugins are 76% exploitable

---

## Smoke test

Input: plugin with 1 AJAX handler that's missing `current_user_can`.
Expected:
- 1 ❌ HIGH finding
- Suggested fix code (drop-in)
- Cites Patchstack 2026 with today's date

---

## Embedded fallback rules (offline)
1. Authorise the OBJECT, not just the action (IDOR check)
2. Capability + nonce on every state-changing handler
3. `__return_true` permission_callback = always-flag for review
4. Whitelist accepted fields (no mass assignment)
5. No "security through obscurity" — gate every admin path
6. Block known-sensitive meta keys (`wp_capabilities`, `wp_user_level`)
7. Scope reads by current-user identity

## Sources & Evergreen References

### Live sources (fetched on every run)
- [Patchstack State of Security 2026](https://patchstack.com/whitepaper/state-of-wordpress-security-in-2026/)
- [Patchstack BAC database](https://patchstack.com/database/)
- [OWASP A01 Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [WP Security APIs handbook](https://developer.wordpress.org/apis/security/)

### Last reviewed
2026-04-30 — fetch on every run; BAC patterns evolve as plugins ship new attack surfaces
