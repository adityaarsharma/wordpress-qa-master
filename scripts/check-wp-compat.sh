#!/usr/bin/env bash
# Orbit — WordPress Function Compatibility Check (plugin-check `wp_functions_compatibility`)
#
# If your plugin header says `Requires at least: 6.3` but your code calls a
# function added in WP 6.7, every user on 6.3-6.6 gets a fatal error the
# moment that code path runs.
#
# This checks your declared min WP version against a curated list of functions
# added in each recent WP version. Curated list — not exhaustive — covers the
# functions most commonly used in modern plugins.

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1)
if [ -z "$MAIN_FILE" ]; then
  echo "No main plugin file — skipping WP compat check"
  exit 0
fi

MIN_WP=$(grep -iE "^\s*\*?\s*Requires at least:" "$MAIN_FILE" | head -1 | sed -E 's/.*Requires at least:\s*//' | tr -d ' \r')
if [ -z "$MIN_WP" ]; then
  echo -e "${YELLOW}⚠ 'Requires at least' not declared — can't check compatibility${NC}"
  echo "   Add to plugin header: Requires at least: 6.3"
  exit 0
fi

echo "Plugin declares: Requires at least: $MIN_WP"
echo ""

# Curated — functions and their introduced-in version.
# Format: "function_name:X.Y"
# Extend this list when new WP versions ship.
FUNCTIONS=(
  # WP 7.0
  "wp_register_ability:7.0"
  "wp_execute_ability:7.0"
  "wp_get_registered_abilities:7.0"
  "wp_store_connector_key:7.0"
  # WP 6.9
  "wp_trigger_comment_moderation_emails:6.9"
  # WP 6.7
  "wp_register_block_metadata_collection:6.7"
  "wp_script_modules:6.7"
  # WP 6.6
  "wp_get_admin_notice:6.6"
  "wp_admin_notice:6.6"
  # WP 6.5
  "register_block_bindings_source:6.5"
  "wp_register_script_module:6.5"
  "wp_enqueue_script_module:6.5"
  "wp_deregister_script_module:6.5"
  "wp_interactivity_state:6.5"
  "wp_interactivity_config:6.5"
  "wp_interactivity_process_directives:6.5"
  # WP 6.4
  "wp_trigger_error:6.4"
  "block_has_support:6.4"
  # WP 6.3
  "register_block_style:6.3"
  "wp_admin_notice:6.3"
  "wp_omit_loading_attr_threshold:6.3"
  # WP 6.2
  "wp_theme_has_theme_json:6.2"
  # WP 6.1
  "wp_enqueue_block_style:6.1"
  # WP 6.0
  "wp_is_block_theme:6.0"
)

version_ge() {
  # returns 0 if $1 >= $2
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

FAIL=0
INCOMPAT=()

for entry in "${FUNCTIONS[@]}"; do
  FUNC="${entry%:*}"
  VER="${entry#*:}"

  # If plugin's min version is already >= function's min version, function is safe
  if version_ge "$MIN_WP" "$VER"; then
    continue
  fi

  # Plugin supports older WP but uses this newer function
  HITS=$(grep -rEn "(^|[^a-zA-Z_>])$FUNC\s*\(" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
    grep -vE "//.*$FUNC|#.*$FUNC|/\*.*$FUNC|function\s+$FUNC" | head -3 || true)
  if [ -n "$HITS" ]; then
    INCOMPAT+=("$FUNC:$VER")
    echo -e "${RED}✗ ${FUNC}() — introduced in WP $VER, but plugin declares $MIN_WP${NC}"
    echo "$HITS" | head -1 | sed 's/^/   /'
    FAIL=1
  fi
done

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}WP compatibility: FAIL — ${#INCOMPAT[@]} incompatible function call(s)${NC}"
  echo ""
  echo "Fix options:"
  echo "  1. Bump 'Requires at least' in plugin header + readme.txt"
  echo "  2. OR guard with function_exists() checks"
  echo "  3. OR drop the feature for older WP versions"
  exit 1
fi

echo -e "${GREEN}WP compatibility: PASS — plugin code matches declared min WP $MIN_WP${NC}"
exit 0
