#!/usr/bin/env bash
# Orbit — design.md Generator
#
# Reads the plugin code and produces a design.md file documenting the plugin's
# architecture. One-command "architecture snapshot" for code review, team
# onboarding, WP.org submission documentation, or CEO overview.
#
# Output: <PLUGIN_PATH>/design.md  (overwrites existing — run during release prep)
#
# Works on any plugin name — no hardcoding. Pulls the plugin name from the
# main file's "Plugin Name:" header.

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1 || true)

# ─── Extract metadata ────────────────────────────────────────────────────────
if [ -n "$MAIN_FILE" ]; then
  PLUGIN_NAME=$(grep -iE "^\s*\*?\s*Plugin Name:" "$MAIN_FILE" | head -1 | sed -E 's/.*Plugin Name:\s*//' | tr -d '\r' | sed 's/^ *//;s/ *$//' | head -c 100)
  VERSION=$(grep -iE "^\s*\*?\s*Version:" "$MAIN_FILE" | head -1 | sed -E 's/.*Version:\s*//' | tr -d ' \r')
  DESC=$(grep -iE "^\s*\*?\s*Description:" "$MAIN_FILE" | head -1 | sed -E 's/.*Description:\s*//' | tr -d '\r' | sed 's/^ *//;s/ *$//' | head -c 300)
  REQUIRES_WP=$(grep -iE "^\s*\*?\s*Requires at least:" "$MAIN_FILE" | head -1 | sed -E 's/.*Requires at least:\s*//' | tr -d ' \r')
  REQUIRES_PHP=$(grep -iE "^\s*\*?\s*Requires PHP:" "$MAIN_FILE" | head -1 | sed -E 's/.*Requires PHP:\s*//' | tr -d ' \r')
  TESTED_UP=$(grep -iE "^\s*\*?\s*Tested up to:" "$MAIN_FILE" | head -1 | sed -E 's/.*Tested up to:\s*//' | tr -d ' \r')
  TEXT_DOMAIN=$(grep -iE "^\s*\*?\s*Text Domain:" "$MAIN_FILE" | head -1 | sed -E 's/.*Text Domain:\s*//' | tr -d ' \r')
  AUTHOR=$(grep -iE "^\s*\*?\s*Author:" "$MAIN_FILE" | head -1 | sed -E 's/.*Author:\s*//' | tr -d '\r' | sed 's/^ *//;s/ *$//' | head -c 100)
  LICENSE=$(grep -iE "^\s*\*?\s*License:" "$MAIN_FILE" | head -1 | sed -E 's/.*License:\s*//' | tr -d '\r' | sed 's/^ *//;s/ *$//' | head -c 50)
  REQUIRES_PLUGINS=$(grep -iE "^\s*\*?\s*Requires Plugins:" "$MAIN_FILE" | head -1 | sed -E 's/.*Requires Plugins:\s*//' | tr -d '\r' | sed 's/^ *//;s/ *$//' | head -c 200)
else
  PLUGIN_NAME="$PLUGIN_SLUG"
  VERSION=""; DESC=""; REQUIRES_WP=""; REQUIRES_PHP=""; TESTED_UP=""
  TEXT_DOMAIN="$PLUGIN_SLUG"; AUTHOR=""; LICENSE=""; REQUIRES_PLUGINS=""
fi

echo -e "${CYAN}Generating design.md for: ${PLUGIN_NAME}${NC}"

# ─── Extract entry points ────────────────────────────────────────────────────
list_unique() { sort -u | grep -v '^$' | head -30; }

ADMIN_PAGES=$(grep -rEh "add_(menu|submenu|options|dashboard|management|plugins|theme|users|tools)_page\s*\(" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -oE "['\"][a-z0-9_-]+['\"]" | sed "s/['\"]//g" | \
  grep -vE '^(read|manage_options|administrator|edit_posts|dashicons)' | list_unique)

SHORTCODES=$(grep -rEh "add_shortcode\s*\(\s*['\"]([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*add_shortcode\s*\(\s*['\"]([^'\"]+)['\"].*/\1/" | list_unique)

REST_ROUTES=$(grep -rEh "register_rest_route\s*\(\s*['\"]([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*register_rest_route\s*\(\s*['\"]([^'\"]+)['\"].*/\1/" | list_unique)

AJAX_PRIV=$(grep -rEh "add_action\s*\(\s*['\"]wp_ajax_([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -v "wp_ajax_nopriv_" | sed -E "s/.*wp_ajax_([^'\"]+)['\"].*/\1/" | list_unique)

AJAX_NOPRIV=$(grep -rEh "add_action\s*\(\s*['\"]wp_ajax_nopriv_([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*wp_ajax_nopriv_([^'\"]+)['\"].*/\1/" | list_unique)

CRON_HOOKS=$(grep -rEh "wp_(schedule_event|schedule_single_event)\s*\([^,]+,\s*['\"]([^'\"]+)['\"]" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*['\"]([a-z0-9_-]+)['\"][^'\"]*\$/\1/" | list_unique)

BLOCKS=$(find "$PLUGIN_PATH" -name "block.json" -not -path "*/node_modules/*" -not -path "*/vendor/*" 2>/dev/null | \
  while read -r bjson; do
    python3 -c "import json; print(json.load(open('$bjson')).get('name',''))" 2>/dev/null
  done | list_unique)

CPTS=$(grep -rEh "register_post_type\s*\(\s*['\"]([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*register_post_type\s*\(\s*['\"]([^'\"]+)['\"].*/\1/" | list_unique)

TAXONOMIES=$(grep -rEh "register_taxonomy\s*\(\s*['\"]([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*register_taxonomy\s*\(\s*['\"]([^'\"]+)['\"].*/\1/" | list_unique)

TABLES=$(grep -rEh "\\\$wpdb->prefix\s*\.\s*['\"]([a-z0-9_]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -oE "['\"][a-z0-9_]+['\"]" | sed "s/['\"]//g" | \
  grep -vE '^(options|posts|postmeta|users|usermeta|terms|termmeta|term_relationships|term_taxonomy|comments|commentmeta)$' | list_unique)

# ─── External services ───────────────────────────────────────────────────────
EXTERNAL_APIS=$(grep -rEh "wp_remote_(get|post|request)\s*\(\s*['\"]https?://[^'\"/)]+" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -oE "https?://[a-zA-Z0-9.-]+" | sort -u | grep -v "^https\?://$" | head -10)

# ─── Plugin type heuristic ───────────────────────────────────────────────────
USES_WC=$(grep -rEl "wc_get_order|WC_Order" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
USES_ELEMENTOR=$(grep -rEl "Elementor\\\\Widget_Base" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

PLUGIN_TYPE="general"
[ -n "$BLOCKS" ] && PLUGIN_TYPE="gutenberg-blocks"
[ "$USES_ELEMENTOR" -gt 0 ] && PLUGIN_TYPE="elementor-addon"
[ "$USES_WC" -gt 0 ] && PLUGIN_TYPE="woocommerce-extension"
[ -n "$REST_ROUTES" ] && [ -z "$ADMIN_PAGES" ] && PLUGIN_TYPE="rest-api"

# ─── File structure summary ──────────────────────────────────────────────────
PHP_COUNT=$(find "$PLUGIN_PATH" -name "*.php" -not -path "*/vendor/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
JS_COUNT=$(find "$PLUGIN_PATH" -name "*.js" -not -path "*/vendor/*" -not -path "*/node_modules/*" -not -path "*/build/*" -not -name "*.min.js" 2>/dev/null | wc -l | tr -d ' ')
CSS_COUNT=$(find "$PLUGIN_PATH" -name "*.css" -not -path "*/vendor/*" -not -path "*/node_modules/*" -not -path "*/build/*" -not -name "*.min.css" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_LOC=$(find "$PLUGIN_PATH" -name "*.php" -not -path "*/vendor/*" -not -path "*/node_modules/*" -exec wc -l {} \; 2>/dev/null | awk '{total+=$1} END {print total}')

# ─── Hooks this plugin provides (for integrators) ────────────────────────────
PROVIDED_ACTIONS=$(grep -rEh "do_action\s*\(\s*['\"][a-z0-9_]+['\"]" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*do_action\s*\(\s*['\"]([a-z0-9_]+)['\"].*/\1/" | \
  grep -v "^wp_\|^admin_\|^init\$\|^plugins_loaded\$" | list_unique | head -15)

PROVIDED_FILTERS=$(grep -rEh "apply_filters\s*\(\s*['\"][a-z0-9_]+['\"]" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*apply_filters\s*\(\s*['\"]([a-z0-9_]+)['\"].*/\1/" | \
  grep -v "^the_content\$\|^the_title\$\|^wp_" | list_unique | head -15)

# ─── Generate the design.md ──────────────────────────────────────────────────
DESIGN_MD="$PLUGIN_PATH/design.md"
GENERATED=$(date '+%Y-%m-%d %H:%M')

cat > "$DESIGN_MD" << DESIGN_HEADER
# ${PLUGIN_NAME} — Architecture Snapshot

> Auto-generated by Orbit. Reflects the plugin's code structure at \`v${VERSION:-?}\`.
> Re-generate before each release: \`bash scripts/generate-design-md.sh /path/to/plugin\`

**Last regenerated:** ${GENERATED}

---

## Overview

| | |
|---|---|
| **Plugin name** | ${PLUGIN_NAME} |
| **Slug** | \`${PLUGIN_SLUG}\` |
| **Version** | \`${VERSION:-—}\` |
| **Type** | ${PLUGIN_TYPE} |
| **Author** | ${AUTHOR:-—} |
| **License** | ${LICENSE:-—} |
| **Text Domain** | \`${TEXT_DOMAIN:-—}\` |
| **Requires WP** | \`${REQUIRES_WP:-—}\` |
| **Tested up to** | \`${TESTED_UP:-—}\` |
| **Requires PHP** | \`${REQUIRES_PHP:-—}\` |
| **Requires Plugins** | ${REQUIRES_PLUGINS:-—} |

**Description:** ${DESC:-_No description declared_}

**Size:** ${PHP_COUNT} PHP files · ${JS_COUNT} JS files · ${CSS_COUNT} CSS files · ~${TOTAL_LOC:-0} PHP lines

---

## Entry points (how the outside world talks to this plugin)

DESIGN_HEADER

# Admin pages
echo "### Admin pages ($(echo "$ADMIN_PAGES" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$ADMIN_PAGES" ]; then
  echo "$ADMIN_PAGES" | while read -r slug; do
    [ -n "$slug" ] && echo "- \`?page=${slug}\`"
  done >> "$DESIGN_MD"
else
  echo "_None._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

# Shortcodes
echo "### Shortcodes ($(echo "$SHORTCODES" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$SHORTCODES" ]; then
  echo "$SHORTCODES" | while read -r sc; do
    [ -n "$sc" ] && echo "- \`[${sc}]\`"
  done >> "$DESIGN_MD"
else
  echo "_None._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

# REST routes
echo "### REST routes ($(echo "$REST_ROUTES" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$REST_ROUTES" ]; then
  echo "$REST_ROUTES" | while read -r r; do
    [ -n "$r" ] && echo "- \`/wp-json/${r}\`"
  done >> "$DESIGN_MD"
else
  echo "_None._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

# AJAX actions
AJAX_PRIV_COUNT=$(echo "$AJAX_PRIV" | grep -c . 2>/dev/null || echo 0)
AJAX_NOPRIV_COUNT=$(echo "$AJAX_NOPRIV" | grep -c . 2>/dev/null || echo 0)
echo "### AJAX actions ($AJAX_PRIV_COUNT authenticated · $AJAX_NOPRIV_COUNT public)" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$AJAX_PRIV" ]; then
  echo "**Authenticated** (\`wp_ajax_*\`):" >> "$DESIGN_MD"
  echo "$AJAX_PRIV" | while read -r a; do [ -n "$a" ] && echo "- \`$a\`"; done >> "$DESIGN_MD"
  echo "" >> "$DESIGN_MD"
fi
if [ -n "$AJAX_NOPRIV" ]; then
  echo "**Public** (\`wp_ajax_nopriv_*\` — ⚠️ attack surface):" >> "$DESIGN_MD"
  echo "$AJAX_NOPRIV" | while read -r a; do [ -n "$a" ] && echo "- \`$a\`"; done >> "$DESIGN_MD"
  echo "" >> "$DESIGN_MD"
fi
[ -z "$AJAX_PRIV" ] && [ -z "$AJAX_NOPRIV" ] && { echo "_None._" >> "$DESIGN_MD"; echo "" >> "$DESIGN_MD"; }

# Gutenberg blocks
echo "### Gutenberg blocks ($(echo "$BLOCKS" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$BLOCKS" ]; then
  echo "$BLOCKS" | while read -r b; do [ -n "$b" ] && echo "- \`$b\`"; done >> "$DESIGN_MD"
else
  echo "_None._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

# Custom post types + taxonomies
echo "### Custom post types ($(echo "$CPTS" | grep -c . 2>/dev/null || echo 0)) / Taxonomies ($(echo "$TAXONOMIES" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$CPTS" ]; then
  echo "**CPTs:**" >> "$DESIGN_MD"
  echo "$CPTS" | while read -r t; do [ -n "$t" ] && echo "- \`$t\`"; done >> "$DESIGN_MD"
fi
if [ -n "$TAXONOMIES" ]; then
  echo "" >> "$DESIGN_MD"
  echo "**Taxonomies:**" >> "$DESIGN_MD"
  echo "$TAXONOMIES" | while read -r t; do [ -n "$t" ] && echo "- \`$t\`"; done >> "$DESIGN_MD"
fi
[ -z "$CPTS" ] && [ -z "$TAXONOMIES" ] && echo "_None._" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"

# Cron hooks
echo "### Scheduled (cron) hooks ($(echo "$CRON_HOOKS" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$CRON_HOOKS" ]; then
  echo "$CRON_HOOKS" | while read -r h; do [ -n "$h" ] && echo "- \`$h\`"; done >> "$DESIGN_MD"
else
  echo "_None._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

cat >> "$DESIGN_MD" << 'DESIGN_PERSIST'

---

## Data persistence

DESIGN_PERSIST

# Custom DB tables
echo "### Custom database tables ($(echo "$TABLES" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$TABLES" ]; then
  echo "$TABLES" | while read -r t; do [ -n "$t" ] && echo "- \`{\$wpdb->prefix}$t\`"; done >> "$DESIGN_MD"
else
  echo "_None. Uses only WordPress core tables._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

cat >> "$DESIGN_MD" << 'DESIGN_INTEG'

---

## External integrations

DESIGN_INTEG

# External services
echo "### External services" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$EXTERNAL_APIS" ]; then
  echo "$EXTERNAL_APIS" | while read -r url; do [ -n "$url" ] && echo "- \`$url\`"; done >> "$DESIGN_MD"
else
  echo "_None detected. No outbound HTTP to third-party services._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

# Provided hooks
cat >> "$DESIGN_MD" << 'DESIGN_HOOKS'

---

## Extensibility (hooks provided for integrators)

DESIGN_HOOKS

echo "### Custom actions ($(echo "$PROVIDED_ACTIONS" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$PROVIDED_ACTIONS" ]; then
  echo "$PROVIDED_ACTIONS" | while read -r h; do [ -n "$h" ] && echo "- \`$h\`"; done >> "$DESIGN_MD"
else
  echo "_None._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

echo "### Custom filters ($(echo "$PROVIDED_FILTERS" | grep -c . 2>/dev/null || echo 0))" >> "$DESIGN_MD"
echo "" >> "$DESIGN_MD"
if [ -n "$PROVIDED_FILTERS" ]; then
  echo "$PROVIDED_FILTERS" | while read -r h; do [ -n "$h" ] && echo "- \`$h\`"; done >> "$DESIGN_MD"
else
  echo "_None._" >> "$DESIGN_MD"
fi
echo "" >> "$DESIGN_MD"

# ─── File structure ──────────────────────────────────────────────────────────
cat >> "$DESIGN_MD" << 'DESIGN_FILES'

---

## File structure

```
DESIGN_FILES
(cd "$PLUGIN_PATH" && find . -maxdepth 3 -type d -not -path '*/vendor/*' -not -path '*/node_modules/*' -not -path '*/.git*' -not -path '*/build/*' 2>/dev/null | head -25 | sort | sed 's|^\./||' | sed '/^$/d') >> "$DESIGN_MD"
echo '```' >> "$DESIGN_MD"

# ─── Footer ──────────────────────────────────────────────────────────────────
cat >> "$DESIGN_MD" << 'DESIGN_FOOTER'

---

## Related docs

- `readme.txt` — user-facing description + changelog
- `CHANGELOG.md` — developer changelog (if present)
- `uninstall.php` — cleanup logic (if present)
- `qa.config.json` — Orbit test configuration (if present)

---

_This document was generated by [Orbit](https://github.com/adityaarsharma/orbit) — WordPress Plugin QA Framework.
It reflects only what can be inferred from the code. Design intent, business reasoning, and product
decisions should be documented separately._
DESIGN_FOOTER

echo -e "${GREEN}✓${NC} Wrote $DESIGN_MD ($(wc -l < "$DESIGN_MD" | tr -d ' ') lines)"
exit 0
