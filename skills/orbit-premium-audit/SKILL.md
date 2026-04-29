---
name: orbit-premium-audit
description: Stricter audit pass for Premium / paid WordPress plugins — Patchstack 2026 found 76% of premium-component vulns are exploitable (vs ~50% for free plugins). Premium code gets less security scrutiny + more attack interest. This skill runs a deeper rule set: license-server hardening, paid-only-feature gating, telemetry disclosure, premium-update channel security, anti-piracy logic review. Use when the user says "premium audit", "Pro plugin", "paid plugin checks", or runs against a Pro / paid product.
---

# 🪐 orbit-premium-audit — Stricter audit for Pro plugins

Patchstack 2026: **76% of vulnerabilities in premium components are exploitable, vs ~50% in free plugins**. The premium tier is a bigger attack surface that gets less community review. This skill closes the gap.

---

## Runtime — fetch live before auditing

When this skill is invoked:

1. **Fetch in parallel**:
   - https://patchstack.com/whitepaper/state-of-wordpress-security-in-2026/ → current premium-vuln stats
   - https://patchstack.com/database/ → recent premium-plugin CVEs (last 90 days)
   - https://easydigitaldownloads.com/docs/category/extensions/edd-software-licensing/ → license-server best practices
   - https://freemius.com/help/documentation/wordpress-sdk/ → SDK current API

2. **Synthesize**: which premium-specific attack patterns are trending right now? Last 90 days of premium-plugin CVEs — what classes are they?

3. **Audit the plugin** with stricter rules than free-plugin defaults.

---

## What this skill checks (premium-specific, beyond free-plugin baseline)

### 1. License-server endpoint hardening
**Whitepaper intent:** A license-check endpoint is an attractive attack target — it usually accepts a license key + site URL, returns sensitive data. It's also often coded by a single dev with no security review.

```php
// ❌ Vulnerable patterns (common in premium plugins):
$response = wp_remote_get( "https://license.example.com/check?key={$_POST['key']}" );
// ↑ Sends key in URL (logged at proxy/CDN); no nonce; no rate limit

// ✅ Hardened
$response = wp_remote_post( 'https://license.example.com/v1/check', [
  'timeout' => 10,
  'headers' => [
    'Authorization' => 'Bearer ' . get_option( 'my_plugin_license_key' ),
    'X-Site-URL' => home_url(),
    'X-Plugin-Version' => MY_PLUGIN_VERSION,
  ],
  'body' => [],
]);
```

Plus:
- License key stored in `wp_options`, NOT a custom table
- Encrypted at rest (or at minimum obfuscated — base64+ROT is NOT encryption)
- Periodic re-check (24h) with backoff on failure
- HTTPS-only license server endpoints
- Signed JWT response from license server (server signs; plugin verifies)

### 2. Premium-only feature gating must be SERVER-side too
**Whitepaper intent:** Plugins that gate premium features only via JS (`if (license_active) showProFeature()`) are bypassed by editing the JS. Server-side gate.

```php
// ❌ Client-side only
wp_localize_script( 'my-plugin', 'my_plugin_data', [
  'is_pro' => $this->is_active_license(),
] );

// ✅ Server-side gate at the action handler
add_action( 'wp_ajax_my_pro_feature', function() {
  check_ajax_referer( 'my_plugin_nonce', 'nonce' );
  if ( ! my_plugin_has_active_license() ) wp_send_json_error( 'License required', 403 );
  // ... pro logic ...
});
```

### 3. Anti-piracy logic — proportional, not destructive
Some premium plugins implement anti-piracy that breaks the customer's site if license invalid. This is industry-condemned — your paying customer who let the license lapse loses access to their data.

```php
// ❌ Destroys functionality
if ( ! $this->is_active_license() ) {
  remove_all_actions();  // ← cripples the plugin
  return;
}

// ✅ Show notice; keep plugin functional
if ( ! $this->is_active_license() ) {
  add_action( 'admin_notices', 'my_plugin_renew_notice' );
  // BUT — plugin keeps working at last-known-good state
}
```

### 4. Premium update channel is the highest-risk attack
**Whitepaper intent:** Plugins that auto-update from the seller's server bypass WP.org's review. If the seller's server is compromised, every customer site gets a backdoored update — that's the April 2026 EssentialPlugin attack pattern.

Checks:
- Update server uses HTTPS + signed releases
- Plugin verifies update signature before install
- Update server has IP allowlisting / WAF
- Update server isn't reachable except via verified plugin endpoints

Recommended: use `EDD_SL_Plugin_Updater` or Freemius — they handle this properly.

### 5. Telemetry disclosure (GDPR mandatory)
Premium plugins typically phone home with usage data, license check, version. That's personal data under GDPR.

- Privacy policy must list every data point sent
- Opt-out option must exist + must NOT degrade plugin functionality
- Telemetry endpoint over HTTPS only

### 6. Trial-period logic
Trial plugins often have time-bomb bugs (expires correctly the first time, gets confused on renew). Test:
- Trial expiry behaviour matches docs
- Re-activation after expiry doesn't extend trial
- Day-before-expiry / day-of / day-after notifications work
- Customer's data is NOT deleted on trial expiry

### 7. Premium addon hooks (ecosystem)
If your plugin has a Pro addon ecosystem (other devs build on top), check:
- Hooks documented for addon developers
- API surface stable (back-compat shims for renamed hooks)
- Don't use bare `do_action_deprecated` without `since` and `replacement`

### 8. "Activation per site" enforcement
Most premium plugins limit "activations per license." Check:
- Activation count is enforced server-side, not client
- Site URL matched on activation (so "moving sites" needs deactivate-old-first)
- Multisite handling: 1 activation OR per-site (document either way)

---

## Output

```markdown
# Premium Audit — my-pro-plugin · 2026-04-30

> Per Patchstack 2026 Whitepaper (fetched 2026-04-30):
> 76% of premium-plugin CVEs are exploitable. Stricter audit applies.

## License-server hardening
- ❌ License key sent in URL on activation request (admin-side check)
- ⚠ License key obfuscated (base64) but not encrypted — use sodium_crypto_secretbox
- ✓ License-server uses HTTPS

## Server-side feature gating
- ❌ 4 admin-AJAX handlers gate Pro features client-side only
   → handlers can be called by editing inline JS
   → Add server-side `my_plugin_has_active_license()` check

## Anti-piracy
- ⚠ Plugin disables all features when license lapses
   → Industry-condemned. Show notice but keep plugin functional.

## Update channel
- ❌ Update server `https://updates.example.com` not behind WAF
- ❌ Releases not signed (any compromise = mass backdoor)
   → Add Sigstore / minisign signatures

## GDPR / telemetry
- ❌ Privacy policy doesn't disclose 4 telemetry data points
- ⚠ Opt-out hidden 3 clicks deep

## Severity: HIGH — multiple findings; recommend halt release until license-server + signing addressed
```

---

## Pair with

- `/orbit-pay-edd` / `/orbit-pay-freemius` — license-server SDKs
- `/orbit-cve-check` — live CVE feed
- `/orbit-sec-supply-chain` — your update channel is part of the supply chain
- `/orbit-vdp` — EU CRA mandates VDP for commercial plugins
- `/orbit-gdpr` — telemetry disclosure

---

## Smoke test

Input: a freemium plugin with EDD_SL_Plugin_Updater integrated.
Expected:
- 1-2 medium findings (e.g. trial-expiry edge case, telemetry disclosure)
- No critical if EDD setup is correct

---

## Embedded fallback rules (offline)
- License keys: HTTPS POST only, never in URL params
- Server-side feature gates required
- Don't break customer's site on license lapse
- Sign your update releases
- Disclose telemetry in privacy policy + provide functional opt-out

## Sources & Evergreen References

### Live sources (fetched on every run)
- [Patchstack 2026 Whitepaper](https://patchstack.com/whitepaper/state-of-wordpress-security-in-2026/)
- [Patchstack DB](https://patchstack.com/database/) — recent premium-plugin CVEs
- [EDD Software Licensing](https://easydigitaldownloads.com/docs/category/extensions/edd-software-licensing/)
- [Freemius SDK](https://freemius.com/help/documentation/wordpress-sdk/)
- [Sigstore](https://www.sigstore.dev/) — signed-release pattern

### Last reviewed
2026-04-30 — fetch on every run
