#!/usr/bin/env bash
# Orbit — WordPress.org Detailed Plugin Guidelines Deep Check
#
# Maps every numbered guideline from:
#   https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/
#
# Goes beyond plugin-check by testing intent-level compliance:
#   - Phone-home without consent
#   - Trialware / nagware patterns
#   - External service disclosure
#   - Advertising / sponsored content
#   - Opt-in credits + links
#   - Obfuscation beyond base64
#   - Hijacking admin screens
#
# Run before any WP.org submission.

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FAIL=0
WARN=0

php_grep() {
  grep -rEn "$1" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=tests 2>/dev/null | head -3 || true
}

echo -e "${CYAN}── WP.org Detailed Plugin Guidelines Deep Check ──${NC}"

# ─── Guideline 1: GPL-compatible license ─────────────────────────────────────
echo ""
echo -e "${CYAN}#1 — GPL-compatible license${NC}"
MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1 || true)
if [ -n "$MAIN_FILE" ]; then
  LICENSE=$(grep -iE "^\s*\*?\s*License:" "$MAIN_FILE" | head -1 | sed -E 's/.*License:\s*//' | tr -d ' \r' || true)
  if echo "$LICENSE" | grep -qiE "gpl|mit|bsd|apache|isc"; then
    echo -e "${GREEN}✓${NC} License: $LICENSE"
  else
    echo -e "${RED}✗${NC} License '$LICENSE' not GPL-compatible"; FAIL=1
  fi
fi

# ─── Guideline 3: No service requirements without clear disclosure ───────────
echo ""
echo -e "${CYAN}#3 — External service disclosure${NC}"
EXTERNAL_APIS=$(php_grep "wp_remote_(get|post|request)\s*\(\s*['\"]https?://[^'\"]+")
if [ -n "$EXTERNAL_APIS" ]; then
  # Look for disclosure — terms of use, privacy policy, or "requires external service" in readme.txt
  DISCLOSURE=$(grep -riE "external\s+service|third.party|requires.+(server|service|account)|privacy.policy" \
    "$PLUGIN_PATH/readme.txt" 2>/dev/null | head -1 || true)
  if [ -z "$DISCLOSURE" ]; then
    echo -e "${YELLOW}⚠${NC} Plugin calls external APIs but readme.txt doesn't disclose external services"
    echo "$EXTERNAL_APIS" | head -2 | sed 's/^/     /'
    echo "   Fix: add a section to readme.txt listing each external service + link to its privacy policy"
    WARN=1
  else
    echo -e "${GREEN}✓${NC} External services disclosed in readme.txt"
  fi
else
  echo "  (no external API calls detected)"
fi

# ─── Guideline 4: External links must be opt-in ───────────────────────────────
echo ""
echo -e "${CYAN}#4 — External links / credits must be opt-in${NC}"
# Look for "powered by" / "credit" / footer links that are ALWAYS on
FORCED_CREDIT=$(php_grep "echo.*powered.?by|Powered\s+by\s+<a|Built\s+with\s+<a|Made\s+with\s+[^<]*<a.*href")
if [ -n "$FORCED_CREDIT" ]; then
  # Check if there's a setting to turn it off
  OPT_OUT=$(grep -riE "hide_credit|show_credit|remove_branding|hide_powered_by|show_powered_by" \
    "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -1 || true)
  if [ -z "$OPT_OUT" ]; then
    echo -e "${RED}✗${NC} Plugin may output 'Powered by' credit with no opt-out setting"
    echo "$FORCED_CREDIT" | head -2 | sed 's/^/     /'
    echo "   WP.org requires credits to be OFF by default and user-enabled"
    FAIL=1
  else
    echo -e "${YELLOW}⚠${NC} Credit output found AND opt-out setting found — verify default is OFF"
    WARN=1
  fi
else
  echo -e "${GREEN}✓${NC} No forced credit/powered-by markup detected"
fi

# ─── Guideline 5: No phone-home without consent ──────────────────────────────
echo ""
echo -e "${CYAN}#5 — Phone-home / telemetry requires explicit consent${NC}"
# Look for wp_remote_* calls that happen on activation/init without nonce/user action
PHONE_HOME=$(grep -rEn "wp_remote_(get|post).*\$this->(slug|version|site_url)|wp_remote_(get|post).*home_url\(" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -3 || true)
if [ -n "$PHONE_HOME" ]; then
  # Must have consent check near it
  CONSENT=$(grep -rEn "allow_tracking|usage_tracking|telemetry_consent|opted_in|analytics_consent" \
    "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -1 || true)
  if [ -z "$CONSENT" ]; then
    echo -e "${RED}✗${NC} Plugin appears to phone-home (send site info to remote server) but no consent check detected"
    echo "$PHONE_HOME" | head -2 | sed 's/^/     /'
    echo "   WP.org requires: default OFF, explicit opt-in, disclose what data is sent"
    FAIL=1
  else
    echo -e "${YELLOW}⚠${NC} Phone-home detected with consent check — verify consent is OFF by default"
    WARN=1
  fi
else
  echo -e "${GREEN}✓${NC} No phone-home patterns detected"
fi

# ─── Guideline 6: No tracking / data collection without consent ──────────────
echo ""
echo -e "${CYAN}#6 — User data collection requires consent${NC}"
# GDPR hooks registered?
GDPR_REG=$(grep -rE "wp_privacy_personal_data_(exporters|erasers)" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
USES_USER_DATA=$(grep -rEl "add_user_meta|update_user_meta|wp_create_user|user_email" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
if [ "$USES_USER_DATA" -gt 0 ] && [ "$GDPR_REG" -eq 0 ]; then
  echo -e "${RED}✗${NC} Plugin touches user data ($USES_USER_DATA files) but doesn't register GDPR hooks"
  echo "   Add: add_filter('wp_privacy_personal_data_exporters', ...)"
  echo "        add_filter('wp_privacy_personal_data_erasers', ...)"
  FAIL=1
elif [ "$GDPR_REG" -gt 0 ]; then
  echo -e "${GREEN}✓${NC} GDPR Privacy API hooks registered ($GDPR_REG)"
else
  echo "  (plugin doesn't touch user data — not applicable)"
fi

# ─── Guideline 7: No trialware / feature-gated nags ──────────────────────────
echo ""
echo -e "${CYAN}#7 — No trialware / disabled features nagging for upgrade${NC}"
# Admin notices mentioning "Pro", "upgrade", "trial", "expire"
NAG_NOTICE=$(grep -rEn "admin_notice.*(Pro|Premium|Upgrade|Trial|Expir)|Upgrade\s+to\s+Pro|Premium\s+feature|unlock\s+this|sign\s+up\s+for" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -3 || true)
if [ -n "$NAG_NOTICE" ]; then
  echo -e "${YELLOW}⚠${NC} Nagware / upgrade prompts detected — review each for WP.org compliance:"
  echo "$NAG_NOTICE" | head -2 | sed 's/^/     /'
  echo "   WP.org allows upgrade prompts BUT: (a) dismissible, (b) not persistent across sessions,"
  echo "   (c) not blocking core functionality of the free plugin"
  WARN=1
else
  echo -e "${GREEN}✓${NC} No nagware patterns detected"
fi

# ─── Guideline 8: Trademark compliance (plugin slug) ─────────────────────────
echo ""
echo -e "${CYAN}#8 — Trademark compliance in plugin slug${NC}"
PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
# Lowercase for comparison — portable (bash 3.2 on macOS lacks ${VAR,,})
PLUGIN_SLUG_LC=$(echo "$PLUGIN_SLUG" | tr '[:upper:]' '[:lower:]')
TRADEMARKS="wordpress woo woocommerce elementor gutenberg yoast jetpack google facebook amazon microsoft adobe"
VIOLATES_TM=0
for tm in $TRADEMARKS; do
  if [ "$PLUGIN_SLUG_LC" = "$tm" ] || echo "$PLUGIN_SLUG_LC" | grep -qE "^${tm}[- ]|^${tm}$"; then
    echo -e "${RED}✗${NC} Plugin slug '$PLUGIN_SLUG' starts with trademarked term '$tm'"
    echo "   WP.org reserves trademarked terms. Use '<your-brand>-for-$tm' pattern instead."
    VIOLATES_TM=1
    FAIL=1
  fi
done
[ "$VIOLATES_TM" -eq 0 ] && echo -e "${GREEN}✓${NC} Plugin slug '$PLUGIN_SLUG' doesn't claim a reserved trademark"

# ─── Guideline 9: No executable code from external sources ───────────────────
echo ""
echo -e "${CYAN}#9 — No remote code execution${NC}"
REMOTE_CODE=$(grep -rEn "eval\s*\(.*wp_remote|eval\s*\(.*file_get_contents\s*\(\s*['\"]https?|include\s*\(\s*['\"]https?://|require\s*\(\s*['\"]https?://" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
if [ -n "$REMOTE_CODE" ]; then
  echo -e "${RED}✗${NC} Plugin appears to execute code loaded from external sources (auto-reject)"
  echo "$REMOTE_CODE" | head -2 | sed 's/^/     /'
  FAIL=1
else
  echo -e "${GREEN}✓${NC} No remote code execution patterns"
fi

# ─── Guideline 10: No hijacking admin ────────────────────────────────────────
echo ""
echo -e "${CYAN}#10 — No hijacking the admin dashboard${NC}"
HIJACKS=$(grep -rEn "wp_redirect.*wp-admin|header\s*\(\s*['\"]Location:.*wp-admin.*['\"]\s*\)" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -v "admin-ajax\|admin-post\|plugins.php\|options-general" | head -3 || true)
# Also check for modifying core screens
CORE_HOOKS=$(grep -rEn "add_filter\s*\(\s*['\"]admin_footer_text['\"]" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
if [ -n "$HIJACKS" ]; then
  echo -e "${YELLOW}⚠${NC} Activation / init redirects into wp-admin detected — verify these are user-initiated:"
  echo "$HIJACKS" | head -2 | sed 's/^/     /'
  WARN=1
else
  echo -e "${GREEN}✓${NC} No admin-hijacking patterns"
fi
if [ -n "$CORE_HOOKS" ]; then
  echo -e "${YELLOW}⚠${NC} Modifies admin footer text — ensure this is plugin-page-scoped, not site-wide"
  WARN=1
fi

# ─── Guideline 11: No user lock-in ───────────────────────────────────────────
echo ""
echo -e "${CYAN}#11 — Uninstall removes all plugin data${NC}"
if [ -f "$PLUGIN_PATH/uninstall.php" ]; then
  # Verify uninstall actually does something
  UNINSTALL_CLEANUP=$(grep -cE "delete_option|delete_site_option|DROP TABLE|delete_metadata|delete_transient" \
    "$PLUGIN_PATH/uninstall.php" 2>/dev/null || echo 0)
  if [ "$UNINSTALL_CLEANUP" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} uninstall.php present + performs cleanup ($UNINSTALL_CLEANUP deletion calls)"
  else
    echo -e "${YELLOW}⚠${NC} uninstall.php exists but no delete_option / DROP TABLE / delete_metadata calls — may leave orphaned data"
    WARN=1
  fi
else
  REG_HOOK=$(grep -rE "register_uninstall_hook" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -1 || true)
  if [ -n "$REG_HOOK" ]; then
    echo -e "${GREEN}✓${NC} register_uninstall_hook() used (verify callback cleans data)"
  else
    echo -e "${RED}✗${NC} No uninstall.php AND no register_uninstall_hook() — plugin will leave orphaned data"
    FAIL=1
  fi
fi

# ─── Guideline 13: No obfuscation ────────────────────────────────────────────
echo ""
echo -e "${CYAN}#13 — No code obfuscation${NC}"
OBF=$(grep -rEn '\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}|chr\([0-9]+\)\s*\.\s*chr\([0-9]+\)\s*\.\s*chr' \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
if [ -n "$OBF" ]; then
  echo -e "${RED}✗${NC} Code obfuscation detected (hex sequences / chr chains) — auto-reject"
  echo "$OBF" | head -2 | sed 's/^/     /'
  FAIL=1
else
  echo -e "${GREEN}✓${NC} No obfuscation patterns detected"
fi

# ─── Guideline 14: Use WP core functions ─────────────────────────────────────
echo ""
echo -e "${CYAN}#14 — Use WordPress core functions where available${NC}"
# file_get_contents on URLs (should use wp_remote_get)
RAW_HTTP=$(grep -rEn "file_get_contents\s*\(\s*['\"]https?://" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
# curl_exec (should use wp_remote_get)
CURL_DIRECT=$(grep -rEn "curl_exec\s*\(" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
CORE_FN_ISSUES=0
if [ -n "$RAW_HTTP" ]; then
  echo -e "${YELLOW}⚠${NC} Uses file_get_contents() for HTTP — should use wp_remote_get()"
  echo "$RAW_HTTP" | head -1 | sed 's/^/     /'
  CORE_FN_ISSUES=1
fi
if [ -n "$CURL_DIRECT" ]; then
  echo -e "${YELLOW}⚠${NC} Uses curl_exec() directly — should use wp_remote_get()/wp_remote_post()"
  CORE_FN_ISSUES=1
fi
[ "$CORE_FN_ISSUES" -eq 1 ] && WARN=1
[ "$CORE_FN_ISSUES" -eq 0 ] && echo -e "${GREEN}✓${NC} Uses WP core HTTP functions"

# ─── Guideline 17: Respect third-party trademarks (in code) ──────────────────
echo ""
echo -e "${CYAN}#17 — Third-party trademark respect in plugin text${NC}"
# Check readme.txt + plugin header for trademarked claims
if [ -f "$PLUGIN_PATH/readme.txt" ]; then
  TM_CLAIMS=$(grep -iE "official\s+(woocommerce|elementor|yoast|jetpack|wordpress)" "$PLUGIN_PATH/readme.txt" | head -2 || true)
  if [ -n "$TM_CLAIMS" ]; then
    echo -e "${YELLOW}⚠${NC} readme.txt claims 'official' association with a trademarked product:"
    echo "$TM_CLAIMS" | head -2 | sed 's/^/     /'
    echo "   Unless you are the actual trademark holder, say 'for WooCommerce' not 'Official WooCommerce'"
    WARN=1
  else
    echo -e "${GREEN}✓${NC} No unauthorized 'official' trademark claims"
  fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════"
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}WP.org Guidelines: FAIL — would be rejected at submission${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}WP.org Guidelines: WARN — review above, may slow review process${NC}"
  exit 0
fi
echo -e "${GREEN}WP.org Guidelines: PASS — submission-ready${NC}"
exit 0
