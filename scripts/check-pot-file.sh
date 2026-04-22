#!/usr/bin/env bash
# Orbit — POT File Verification
#
# Checks:
#   1. Plugin ships a .pot file in /languages/
#   2. File matches the declared Text Domain
#   3. Has proper POT headers (Project-Id-Version, Language-Team, POEdit meta)
#   4. String count is within 10% of a fresh make-pot run (detects stale POT)
#   5. Includes JS strings (WP 5.0+ requirement for wp.i18n)
#   6. Plugin header has `Domain Path: /languages`

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FAIL=0
WARN=0

# ─── Find text domain ────────────────────────────────────────────────────────
MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1 || true)
if [ -z "$MAIN_FILE" ]; then
  echo "No main plugin file — skipping POT check"
  exit 0
fi

TEXT_DOMAIN=$(grep -iE "^\s*\*?\s*Text Domain:" "$MAIN_FILE" | head -1 | sed -E 's/.*Text Domain:\s*//' | tr -d ' \r')
DOMAIN_PATH=$(grep -iE "^\s*\*?\s*Domain Path:" "$MAIN_FILE" | head -1 | sed -E 's/.*Domain Path:\s*//' | tr -d ' \r')

if [ -z "$TEXT_DOMAIN" ]; then
  echo -e "${RED}✗ Text Domain not declared in plugin header${NC}"
  exit 1
fi

echo -e "${CYAN}── POT File Verification ──${NC}"
echo "Text Domain: $TEXT_DOMAIN"
echo "Domain Path: ${DOMAIN_PATH:-(not set)}"
echo ""

# ─── Check Domain Path header ────────────────────────────────────────────────
if [ -z "$DOMAIN_PATH" ]; then
  echo -e "${YELLOW}⚠${NC} 'Domain Path' header missing — add: Domain Path: /languages"
  WARN=1
fi

# ─── Find POT file ───────────────────────────────────────────────────────────
# Try declared Domain Path first, then /languages/ fallback
POT_CANDIDATES=()
if [ -n "$DOMAIN_PATH" ]; then
  POT_CANDIDATES+=("$PLUGIN_PATH${DOMAIN_PATH}/${TEXT_DOMAIN}.pot")
fi
POT_CANDIDATES+=(
  "$PLUGIN_PATH/languages/${TEXT_DOMAIN}.pot"
  "$PLUGIN_PATH/lang/${TEXT_DOMAIN}.pot"
  "$PLUGIN_PATH/i18n/${TEXT_DOMAIN}.pot"
)

POT_FILE=""
for candidate in "${POT_CANDIDATES[@]}"; do
  if [ -f "$candidate" ]; then
    POT_FILE="$candidate"
    break
  fi
done

if [ -z "$POT_FILE" ]; then
  echo -e "${RED}✗${NC} No POT file found. Expected one of:"
  for c in "${POT_CANDIDATES[@]}"; do echo "     $c"; done
  echo "   Generate with: wp i18n make-pot $PLUGIN_PATH $PLUGIN_PATH/languages/${TEXT_DOMAIN}.pot"
  FAIL=1
  exit 1
fi

echo -e "${GREEN}✓${NC} POT file found: ${POT_FILE#$PLUGIN_PATH/}"

# ─── Check POT headers ───────────────────────────────────────────────────────
PROJECT_ID=$(grep -E "^\"Project-Id-Version:" "$POT_FILE" | head -1 || true)
LANG_TEAM=$(grep -E "^\"Language-Team:" "$POT_FILE" | head -1 || true)
POT_CREATION=$(grep -E "^\"POT-Creation-Date:" "$POT_FILE" | head -1 | sed -E 's/.*"POT-Creation-Date: ([^\\]+)\\n".*/\1/' || true)

[ -z "$PROJECT_ID" ] && { echo -e "${YELLOW}⚠${NC} POT missing Project-Id-Version header"; WARN=1; }
[ -z "$LANG_TEAM" ] && { echo -e "${YELLOW}⚠${NC} POT missing Language-Team header"; WARN=1; }

if [ -n "$POT_CREATION" ]; then
  echo "  Generated: $POT_CREATION"
  # Warn if POT is older than 90 days
  if command -v python3 &>/dev/null; then
    STALE=$(python3 -c "
import datetime, sys
try:
    d = datetime.datetime.strptime('$POT_CREATION'[:10], '%Y-%m-%d')
    age = (datetime.datetime.now() - d).days
    print('stale' if age > 90 else 'fresh')
except: print('unknown')
" 2>/dev/null)
    if [ "$STALE" = "stale" ]; then
      echo -e "${YELLOW}⚠${NC} POT is >90 days old — regenerate before release"
      WARN=1
    fi
  fi
fi

# ─── Count strings in existing POT ───────────────────────────────────────────
POT_STRINGS=$(grep -c "^msgid \"" "$POT_FILE" 2>/dev/null || echo 0)
# Subtract the header msgid ""
POT_STRINGS=$((POT_STRINGS - 1))
[ "$POT_STRINGS" -lt 0 ] && POT_STRINGS=0
echo "  Strings in POT: $POT_STRINGS"

# ─── Compare against fresh make-pot ──────────────────────────────────────────
if command -v wp &>/dev/null; then
  FRESH_POT=$(mktemp -t orbit-fresh-pot.XXXXXX.pot)
  trap 'rm -f "$FRESH_POT"' EXIT
  (cd "$PLUGIN_PATH" && wp i18n make-pot . "$FRESH_POT" --skip-audit 2>/dev/null) || true

  if [ -f "$FRESH_POT" ] && [ -s "$FRESH_POT" ]; then
    FRESH_STRINGS=$(grep -c "^msgid \"" "$FRESH_POT" 2>/dev/null || echo 0)
    FRESH_STRINGS=$((FRESH_STRINGS - 1))
    [ "$FRESH_STRINGS" -lt 0 ] && FRESH_STRINGS=0

    DIFF=$((FRESH_STRINGS - POT_STRINGS))
    ABS_DIFF=${DIFF#-}
    if [ "$FRESH_STRINGS" -gt 0 ]; then
      PCT=$(( (ABS_DIFF * 100) / FRESH_STRINGS ))
    else
      PCT=0
    fi

    echo "  Strings in fresh make-pot: $FRESH_STRINGS (diff: ${DIFF:+$DIFF}, $PCT%)"

    if [ "$PCT" -gt 10 ]; then
      echo -e "${RED}✗${NC} Shipped POT is out-of-sync with source ($PCT% diff, threshold 10%)"
      echo "   Regenerate: wp i18n make-pot $PLUGIN_PATH $POT_FILE"
      FAIL=1
    else
      echo -e "${GREEN}✓${NC} Shipped POT matches source ($PCT% diff)"
    fi
  fi
else
  echo -e "${YELLOW}⚠${NC} WP-CLI not installed — can't compare against fresh POT"
  WARN=1
fi

# ─── Check JS string coverage (WP 5.0+ wp.i18n) ──────────────────────────────
echo ""
JS_I18N_USAGE=$(grep -rEn "__\s*\(\s*['\"][^'\"]+['\"]\s*,\s*['\"]${TEXT_DOMAIN}['\"]|_n\s*\(|_x\s*\(|wp\.i18n\.__" \
  "$PLUGIN_PATH" --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" \
  --exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=build 2>/dev/null | wc -l | tr -d ' ')

if [ "$JS_I18N_USAGE" -gt 0 ]; then
  # POT should include JS strings (make-pot handles this since WP-CLI 2.2+)
  JS_IN_POT=$(grep -E "^#:.*\.(js|jsx|ts|tsx)" "$POT_FILE" | wc -l | tr -d ' ')
  if [ "$JS_IN_POT" -eq 0 ]; then
    echo -e "${RED}✗${NC} Plugin uses wp.i18n in JS ($JS_I18N_USAGE calls) but POT has no JS strings"
    echo "   Fix: wp i18n make-pot . $POT_FILE (needs WP-CLI ≥ 2.2)"
    FAIL=1
  else
    echo -e "${GREEN}✓${NC} JS i18n coverage in POT: $JS_IN_POT entries from .js/.ts files"
  fi
else
  echo "  (no wp.i18n calls in JS — not applicable)"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════"
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}POT verification: FAIL${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}POT verification: WARN${NC}"
  exit 0
fi
echo -e "${GREEN}POT verification: PASS${NC}"
exit 0
