#!/usr/bin/env bash
# Orbit — Modern WordPress Feature Detection (WP 6.5-7.0)
#
# Checks adoption of modern WP features that are either required for 2026-era
# plugins or improve user experience substantially:
#   - Script Modules (WP 6.5+) for JS — replaces wp_enqueue_script
#   - Interactivity API (WP 6.5+) — replaces inline jQuery in blocks
#   - Plugin Dependencies "Requires Plugins" header (WP 6.5+)
#   - Site Health `site_status_tests` filter registration
#   - Block Bindings API (WP 6.5+)
#   - Custom plugin updater detection (bypass of WP.org updates)
#   - External admin menu links (potential scam pattern)

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FAIL=0
WARN=0
INFO=0

# ─── Script Modules (WP 6.5+) ────────────────────────────────────────────────
echo -e "${CYAN}── Script Modules (WP 6.5+) ──${NC}"
MODULES=$(grep -rEn "wp_register_script_module\s*\(" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
LEGACY_JS=$(grep -rEn "wp_enqueue_script\s*\(" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

if [ "$MODULES" -gt 0 ]; then
  echo -e "${GREEN}✓${NC} Uses Script Modules API ($MODULES registrations)"
  # Verify dynamic dependency pattern for @wordpress/a11y
  A11Y_DYNAMIC=$(grep -rEn "wp_register_script_module[^)]*@wordpress/a11y[^)]*import.*dynamic" "$PLUGIN_PATH" \
    --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
  A11Y_ANY=$(grep -rEn "@wordpress/a11y" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
  if [ "$A11Y_ANY" -gt 0 ] && [ "$A11Y_DYNAMIC" -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC} @wordpress/a11y imported but not marked as dynamic — blocks module init"
    WARN=1
  fi
elif [ "$LEGACY_JS" -gt 5 ]; then
  echo -e "${YELLOW}⚠${NC} Uses legacy wp_enqueue_script ($LEGACY_JS times) — consider migrating to Script Modules"
  INFO=1
else
  echo -e "  ${CYAN}ℹ${NC} No script registrations — not applicable"
fi

# ─── Interactivity API (WP 6.5+) ─────────────────────────────────────────────
echo ""
echo -e "${CYAN}── Interactivity API (WP 6.5+) ──${NC}"
INTERACTIVE=$(grep -rEn "@wordpress/interactivity|wp_interactivity_state|wp_interactivity_config" "$PLUGIN_PATH" \
  --include="*.php" --include="*.js" --include="*.json" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
# Modern interactive directives
WP_DIRECTIVES=$(grep -rEn 'data-wp-(on|bind|class|style|text|interactive)' "$PLUGIN_PATH" \
  --include="*.php" --include="*.js" --include="*.html" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
# Legacy patterns inside blocks
BLOCK_FILES=$(find "$PLUGIN_PATH" -name "block.json" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
INLINE_JQUERY=$(grep -rEn '\\\$\s*\(\s*document\s*\)\.ready|jQuery\(|wp_enqueue_script.*jquery' "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

if [ "$INTERACTIVE" -gt 0 ] || [ "$WP_DIRECTIVES" -gt 0 ]; then
  echo -e "${GREEN}✓${NC} Uses Interactivity API ($WP_DIRECTIVES directives, $INTERACTIVE API calls)"
elif [ "$BLOCK_FILES" -gt 0 ] && [ "$INLINE_JQUERY" -gt 5 ]; then
  echo -e "${YELLOW}⚠${NC} $BLOCK_FILES blocks ship, but still uses jQuery ($INLINE_JQUERY times). Interactivity API is the 2026 pattern."
  WARN=1
else
  echo -e "  ${CYAN}ℹ${NC} Not applicable — plugin doesn't ship interactive blocks"
fi

# ─── Plugin Dependencies "Requires Plugins" header (WP 6.5+) ─────────────────
echo ""
echo -e "${CYAN}── Plugin Dependencies Header (WP 6.5+) ──${NC}"
MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1)
if [ -z "$MAIN_FILE" ]; then
  echo -e "  ${CYAN}ℹ${NC} No main plugin file detected"
else
  REQUIRES=$(grep -iE "^\s*\*?\s*Requires Plugins:" "$MAIN_FILE" | head -1 | sed -E 's/.*Requires Plugins:\s*//' | tr -d ' \r')
  # Detect hidden dependencies on other plugins (usage of their functions/classes without guards)
  USES_WC=$(grep -rEln "WC\(\)|wc_get_order|WC_Order|WooCommerce" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
  USES_ELEMENTOR=$(grep -rEln "Elementor\\\\|elementor_loaded|\\\\Elementor\\\\" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

  if [ -n "$REQUIRES" ]; then
    echo -e "${GREEN}✓${NC} Declares Requires Plugins: $REQUIRES"
    # Format must be comma-separated WP.org slugs
    if echo "$REQUIRES" | grep -qE '[A-Z]|\.'; then
      echo -e "${RED}✗${NC} Format invalid — should be lowercase wp.org slugs (e.g. 'woocommerce')"
      FAIL=1
    fi
  else
    if [ "$USES_WC" -gt 3 ]; then
      echo -e "${YELLOW}⚠${NC} Uses WooCommerce ($USES_WC files) but no 'Requires Plugins: woocommerce' header"
      WARN=1
    elif [ "$USES_ELEMENTOR" -gt 3 ]; then
      echo -e "${YELLOW}⚠${NC} Uses Elementor ($USES_ELEMENTOR files) but no 'Requires Plugins: elementor' header"
      WARN=1
    else
      echo -e "  ${CYAN}ℹ${NC} No plugin dependencies detected"
    fi
  fi
fi

# ─── Site Health test registration ───────────────────────────────────────────
echo ""
echo -e "${CYAN}── Site Health Integration ──${NC}"
SITE_HEALTH=$(grep -rEn "add_filter\s*\(\s*['\"]site_status_tests['\"]" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
if [ "$SITE_HEALTH" -gt 0 ]; then
  echo -e "${GREEN}✓${NC} Registers Site Health tests ($SITE_HEALTH hook(s))"
else
  echo -e "  ${CYAN}ℹ${NC} No Site Health tests registered (recommended for plugins with API keys, cron, or external deps)"
fi

# ─── Block Bindings API (WP 6.5+) ────────────────────────────────────────────
echo ""
echo -e "${CYAN}── Block Bindings API (WP 6.5+) ──${NC}"
BINDINGS=$(grep -rEn "register_block_bindings_source\s*\(" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
if [ "$BINDINGS" -gt 0 ]; then
  echo -e "${GREEN}✓${NC} Uses Block Bindings ($BINDINGS registrations)"
else
  echo -e "  ${CYAN}ℹ${NC} No block bindings — only relevant for plugins that expose dynamic block sources"
fi

# ─── Custom plugin updater detection ─────────────────────────────────────────
echo ""
echo -e "${CYAN}── Custom Plugin Updater ──${NC}"
CUSTOM_UPDATER=$(grep -rEn "pre_set_site_transient_update_plugins|site_transient_update_plugins" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
EXTERNAL_UPDATE_URL=$(grep -rEn "wp_remote_get\s*\(\s*['\"]https?://[^'\"]+\.(com|io|net|org|dev)/(update|version|api/v[0-9]+)" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

if [ "$CUSTOM_UPDATER" -gt 0 ]; then
  echo -e "${YELLOW}⚠${NC} Hooks into plugin update transient ($CUSTOM_UPDATER times)"
  echo "   WP.org plugins must NOT bundle custom updaters that bypass WP.org review."
  echo "   OK for commercial plugins; not OK for WP.org submissions (auto-reject)."
  WARN=1
fi
if [ "$EXTERNAL_UPDATE_URL" -gt 0 ]; then
  echo -e "${YELLOW}⚠${NC} Calls external update-like URLs ($EXTERNAL_UPDATE_URL) — verify these aren't shipping updates outside WP.org"
  WARN=1
fi
if [ "$CUSTOM_UPDATER" -eq 0 ] && [ "$EXTERNAL_UPDATE_URL" -eq 0 ]; then
  echo -e "${GREEN}✓${NC} No custom updater detected"
fi

# ─── External admin menu links (scam-plugin pattern) ─────────────────────────
echo ""
echo -e "${CYAN}── External Admin Menu Links ──${NC}"
EXT_MENU=$(grep -rEn "add_(menu|submenu)_page\s*\([^)]*https?://[^)]+\)" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -5 || true)
if [ -n "$EXT_MENU" ]; then
  echo -e "${YELLOW}⚠${NC} Admin menu items link to external URLs:"
  echo "$EXT_MENU" | head -3 | sed 's/^/   /'
  echo "   WP.org flags this — admin menus should stay inside the admin."
  WARN=1
else
  echo -e "${GREEN}✓${NC} No external admin menu links"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}Modern WP: FAIL${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}Modern WP: WARN — review above${NC}"
  exit 0
fi
echo -e "${GREEN}Modern WP: PASS${NC}"
exit 0
