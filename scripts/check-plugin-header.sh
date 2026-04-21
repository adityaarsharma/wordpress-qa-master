#!/usr/bin/env bash
# Orbit — Plugin Header Completeness Check
#
# The plugin header in the main PHP file must have specific fields for WordPress
# to recognize and display it correctly. Missing fields = WP.org submission warnings
# or "Plugin could not be activated" errors.

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1)
if [ -z "$MAIN_FILE" ]; then
  echo -e "${RED}✗ No main plugin file (no .php has 'Plugin Name:' header)${NC}"
  exit 1
fi

echo "Checking: $(basename "$MAIN_FILE")"
echo ""

FAIL=0
WARN=0

# Required fields
REQUIRED=(
  "Plugin Name"
  "Version"
  "Description"
  "Author"
  "License"
  "Text Domain"
)

# Validate "Requires Plugins" header (WP 6.5+) — comma-separated WP.org slugs only
REQUIRES_PLUGINS=$(grep -iE "^\s*\*?\s*Requires Plugins:" "$MAIN_FILE" | head -1 | sed -E 's/.*Requires Plugins:\s*//' | tr -d '\r' || true)
if [ -n "$REQUIRES_PLUGINS" ]; then
  # Must be comma-separated lowercase slugs, no .php suffixes, no URLs
  if echo "$REQUIRES_PLUGINS" | grep -qE '[A-Z]'; then
    echo -e "${RED}✗ Requires Plugins: '$REQUIRES_PLUGINS' — must be lowercase WP.org slugs${NC}"
    FAIL=1
  fi
  if echo "$REQUIRES_PLUGINS" | grep -qE '\.php|http|/'; then
    echo -e "${RED}✗ Requires Plugins: '$REQUIRES_PLUGINS' — use plugin SLUG only (e.g. 'woocommerce'), not plugin/plugin.php${NC}"
    FAIL=1
  fi
fi
for field in "${REQUIRED[@]}"; do
  if ! grep -qE "^\s*\*?\s*${field}:" "$MAIN_FILE"; then
    echo -e "${RED}✗ Missing header: ${field}:${NC}"
    FAIL=1
  fi
done

# Recommended
for field in "Plugin URI" "Author URI" "License URI" "Requires at least" "Requires PHP" "Domain Path" "Update URI"; do
  if ! grep -qE "^\s*\*?\s*${field}:" "$MAIN_FILE"; then
    echo -e "${YELLOW}⚠ Missing header (recommended): ${field}:${NC}"
    WARN=1
  fi
done

# Text Domain must match plugin folder
PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
TEXT_DOMAIN=$(grep -iE "^\s*\*?\s*Text Domain:" "$MAIN_FILE" | head -1 | sed -E 's/.*Text Domain:\s*//' | tr -d ' \r')
if [ -n "$TEXT_DOMAIN" ] && [ "$TEXT_DOMAIN" != "$PLUGIN_SLUG" ]; then
  echo -e "${RED}✗ Text Domain '$TEXT_DOMAIN' must match plugin folder name '$PLUGIN_SLUG'${NC}"
  FAIL=1
fi

# Requires PHP should be >= 7.4 (WP core requirement)
REQ_PHP=$(grep -iE "^\s*\*?\s*Requires PHP:" "$MAIN_FILE" | head -1 | sed -E 's/.*Requires PHP:\s*//' | tr -d ' \r')
if [ -n "$REQ_PHP" ]; then
  # Basic check: major.minor format
  if ! echo "$REQ_PHP" | grep -qE '^[0-9]+\.[0-9]+$'; then
    echo -e "${YELLOW}⚠ Requires PHP: '$REQ_PHP' — should be 'X.Y' format${NC}"
    WARN=1
  fi
fi

# License should be GPL
PLUGIN_LICENSE=$(grep -iE "^\s*\*?\s*License:" "$MAIN_FILE" | head -1 | sed -E 's/.*License:\s*//' | tr -d ' \r')
if [ -n "$PLUGIN_LICENSE" ] && ! echo "$PLUGIN_LICENSE" | grep -qiE "GPL"; then
  echo -e "${RED}✗ License: $PLUGIN_LICENSE — must be GPL-compatible for WP.org${NC}"
  FAIL=1
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}Plugin header: FAIL${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}Plugin header: WARN — recommended fields missing${NC}"
  exit 0
fi
echo -e "${GREEN}Plugin header: PASS — all fields present${NC}"
exit 0
