#!/usr/bin/env bash
# Competitor Analysis — Download + analyze competitor plugin zips from wordpress.org
# Compares code quality, asset weight, and patterns against your plugin
# Usage: bash scripts/competitor-compare.sh [--plugin /path/to/yours] [--competitors "slug1,slug2"]

set -e

MY_PLUGIN=""
COMPETITORS=""
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT="reports/competitor-$TIMESTAMP.md"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --plugin)      MY_PLUGIN="$2"; shift ;;
    --competitors) COMPETITORS="$2"; shift ;;
    --config)
      if [ -f "qa.config.json" ]; then
        MY_PLUGIN=$(python3 -c "import json; d=json.load(open('qa.config.json')); print(d['plugin']['path'])")
        COMPETITORS=$(python3 -c "import json; d=json.load(open('qa.config.json')); print(','.join(d['competitors']))" 2>/dev/null || echo "")
      fi
      ;;
  esac
  shift
done

# Load from qa.config.json if not specified
if [ -z "$MY_PLUGIN" ] && [ -f "qa.config.json" ]; then
  MY_PLUGIN=$(python3 -c "import json; d=json.load(open('qa.config.json')); print(d['plugin']['path'])" 2>/dev/null || echo "")
  COMPETITORS=$(python3 -c "import json; d=json.load(open('qa.config.json')); print(','.join(d['competitors']))" 2>/dev/null || echo "")
fi

[ -z "$COMPETITORS" ] && {
  echo "No competitors specified. Run setup/init.sh first or use --competitors 'slug1,slug2'"
  exit 1
}

mkdir -p reports tmp/competitors

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${BOLD}Competitor Analysis${NC}"
echo "Competitors: $COMPETITORS"
echo "Your plugin: ${MY_PLUGIN:-not set}"
echo "========================================"

cat > "$REPORT" << EOF
# Competitor Analysis Report
**Date**: $(date)
**Competitors**: $COMPETITORS
**Your Plugin**: $MY_PLUGIN

---

EOF

analyze_plugin() {
  local SLUG="$1"
  local DIR="tmp/competitors/$SLUG"

  echo ""
  echo -e "${YELLOW}Analyzing: $SLUG${NC}"

  # Download from wordpress.org API
  local API_URL="https://api.wordpress.org/plugins/info/1.0/${SLUG}.json"
  local INFO=$(curl -sf "$API_URL" 2>/dev/null || echo "{}")

  local VERSION=$(echo "$INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('version','?'))" 2>/dev/null || echo "?")
  local ACTIVE=$(echo "$INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('active_installs','?'))" 2>/dev/null || echo "?")
  local RATING=$(echo "$INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('rating','?'))" 2>/dev/null || echo "?")
  local LAST_UPDATED=$(echo "$INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('last_updated','?'))" 2>/dev/null || echo "?")
  local REQUIRES_WP=$(echo "$INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('requires','?'))" 2>/dev/null || echo "?")
  local REQUIRES_PHP=$(echo "$INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('requires_php','?'))" 2>/dev/null || echo "?")
  local DOWNLOAD_URL=$(echo "$INFO" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('download_link',''))" 2>/dev/null || echo "")

  echo "  Version: $VERSION | Active installs: $ACTIVE | Rating: $RATING"
  echo "  Last updated: $LAST_UPDATED | Requires WP: $REQUIRES_WP | PHP: $REQUIRES_PHP"

  cat >> "$REPORT" << EOF
## $SLUG

| Metric | Value |
|---|---|
| Version | $VERSION |
| Active installs | $ACTIVE |
| Rating | $RATING/100 |
| Last updated | $LAST_UPDATED |
| Requires WP | $REQUIRES_WP+ |
| Requires PHP | $REQUIRES_PHP+ |

EOF

  # Download and extract the plugin zip
  if [ -n "$DOWNLOAD_URL" ]; then
    echo "  Downloading zip..."
    local ZIP_FILE="tmp/competitors/${SLUG}.zip"
    curl -sfL "$DOWNLOAD_URL" -o "$ZIP_FILE" 2>/dev/null || {
      echo "  Failed to download $SLUG"
      return
    }

    mkdir -p "$DIR"
    unzip -q "$ZIP_FILE" -d "$DIR" 2>/dev/null || true

    # Code analysis
    local PHP_COUNT=$(find "$DIR" -name "*.php" -not -path "*/vendor/*" 2>/dev/null | wc -l)
    local JS_KB=$(find "$DIR" -name "*.js" -not -path "*/node_modules/*" 2>/dev/null | xargs wc -c 2>/dev/null | tail -1 | awk '{print int($1/1024)}' || echo "0")
    local CSS_KB=$(find "$DIR" -name "*.css" 2>/dev/null | xargs wc -c 2>/dev/null | tail -1 | awk '{print int($1/1024)}' || echo "0")
    local PHP_KB=$(find "$DIR" -name "*.php" -not -path "*/vendor/*" 2>/dev/null | xargs wc -c 2>/dev/null | tail -1 | awk '{print int($1/1024)}' || echo "0")

    # Check coding patterns (what standards they follow)
    local HAS_NAMESPACE=$(grep -rL "namespace " "$DIR" --include="*.php" 2>/dev/null | wc -l || echo "?")
    local HAS_NONCES=$(grep -rl "wp_nonce\|check_admin_referer\|nonce_field" "$DIR" --include="*.php" 2>/dev/null | wc -l || echo "0")
    local HAS_PREPARE=$(grep -rl "wpdb->prepare\|wpdb->insert\|wpdb->update" "$DIR" --include="*.php" 2>/dev/null | wc -l || echo "0")
    local HAS_ESCAPING=$(grep -rl "esc_html\|esc_attr\|wp_kses" "$DIR" --include="*.php" 2>/dev/null | wc -l || echo "0")
    local HAS_AUTOLOAD=$(grep -rl "autoload" "$DIR" --include="*.php" 2>/dev/null | wc -l || echo "0")
    local HAS_BLOCK_JSON=$(find "$DIR" -name "block.json" 2>/dev/null | wc -l || echo "0")

    echo "  PHP files: $PHP_COUNT | JS: ${JS_KB}KB | CSS: ${CSS_KB}KB | PHP code: ${PHP_KB}KB"
    echo "  Nonce usage: $HAS_NONCES files | Escaping: $HAS_ESCAPING files | DB prepare: $HAS_PREPARE files"

    cat >> "$REPORT" << EOF
### Code Analysis

| Metric | $SLUG |
|---|---|
| PHP files | $PHP_COUNT |
| JS bundle | ${JS_KB}KB |
| CSS bundle | ${CSS_KB}KB |
| PHP code size | ${PHP_KB}KB |
| Files with nonce checks | $HAS_NONCES |
| Files with escaping | $HAS_ESCAPING |
| Files with db prepare | $HAS_PREPARE |
| block.json files | $HAS_BLOCK_JSON |

EOF

    # Run PHPCS if available
    if command -v phpcs &>/dev/null; then
      echo "  Running PHPCS..."
      local PHPCS_ERRORS=$(phpcs --standard=WordPress \
        --extensions=php \
        --ignore=vendor,node_modules \
        --report=summary \
        "$DIR" 2>&1 | grep -oP '\d+(?= ERROR)' | head -1 || echo "0")
      local PHPCS_WARNS=$(phpcs --standard=WordPress \
        --extensions=php \
        --ignore=vendor,node_modules \
        --report=summary \
        "$DIR" 2>&1 | grep -oP '\d+(?= WARNING)' | head -1 || echo "0")

      echo "  PHPCS: $PHPCS_ERRORS errors, $PHPCS_WARNS warnings (vs WP standards)"

      cat >> "$REPORT" << EOF
### PHPCS (WordPress Standards)
- Errors: **$PHPCS_ERRORS**
- Warnings: **$PHPCS_WARNS**

EOF
    fi

    echo ""
    cat >> "$REPORT" << EOF
---

EOF
  else
    echo "  No download URL found for $SLUG"
  fi
}

# Analyze each competitor
IFS=',' read -ra COMP_LIST <<< "$COMPETITORS"
for COMP in "${COMP_LIST[@]}"; do
  COMP=$(echo "$COMP" | xargs)  # trim whitespace
  [ -n "$COMP" ] && analyze_plugin "$COMP"
done

# Analyze your own plugin for comparison
if [ -n "$MY_PLUGIN" ] && [ -d "$MY_PLUGIN" ]; then
  echo ""
  echo -e "${GREEN}Analyzing YOUR plugin for comparison...${NC}"

  MY_JS_KB=$(find "$MY_PLUGIN" -name "*.js" -not -path "*/node_modules/*" 2>/dev/null | xargs wc -c 2>/dev/null | tail -1 | awk '{print int($1/1024)}' || echo "0")
  MY_CSS_KB=$(find "$MY_PLUGIN" -name "*.css" 2>/dev/null | xargs wc -c 2>/dev/null | tail -1 | awk '{print int($1/1024)}' || echo "0")
  MY_PHP_COUNT=$(find "$MY_PLUGIN" -name "*.php" -not -path "*/vendor/*" 2>/dev/null | wc -l)

  cat >> "$REPORT" << EOF
## Your Plugin (Comparison Baseline)
- PHP files: $MY_PHP_COUNT
- JS: ${MY_JS_KB}KB
- CSS: ${MY_CSS_KB}KB

EOF
fi

# Cleanup downloads
rm -rf tmp/competitors/

echo ""
echo "========================================"
echo -e "${GREEN}Competitor analysis complete${NC}"
echo "Report: $REPORT"
echo ""
echo "Key questions to ask from this data:"
echo "  1. Are competitors shipping smaller JS bundles? (performance signal)"
echo "  2. Do competitors have fewer PHPCS errors? (code quality bar)"
echo "  3. Are competitors using block.json? (future-proofing signal)"
echo "  4. When did competitors last update? (market activity)"
