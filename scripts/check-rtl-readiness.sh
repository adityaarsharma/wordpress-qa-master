#!/usr/bin/env bash
# Orbit — RTL (Right-to-Left) Readiness Static Check
#
# Complements tests/playwright/flows/rtl-layout.spec.js (dynamic layout test).
# This is the STATIC check — does the plugin have the files + APIs required
# for RTL support?
#
# Checks:
#   1. `rtl.css` ships alongside each CSS file (OR wp_style_add_data registered)
#   2. `is_rtl()` used in PHP where layout direction matters
#   3. `Domain Path: /languages` header present (required for RTL language loading)
#   4. readme.txt mentions RTL/bidi support
#   5. No hardcoded `float: left`, `margin-left`, `padding-left` in CSS
#      without logical property alternative

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FAIL=0
WARN=0

echo -e "${CYAN}── RTL Readiness Static Check ──${NC}"

# ─── 1. CSS files + RTL counterparts ─────────────────────────────────────────
echo ""
echo -e "${CYAN}#1 — CSS files ship with RTL counterparts${NC}"
CSS_FILES=$(find "$PLUGIN_PATH" -name "*.css" \
  -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/build/*" \
  -not -name "*-rtl.css" -not -name "rtl.css" -not -name "*.min.css" 2>/dev/null)

# Files that use wp_style_add_data('rtl', ...) = auto-generated
AUTO_RTL=$(grep -rE "wp_style_add_data\s*\(\s*['\"][^'\"]+['\"]\s*,\s*['\"]rtl['\"]" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

# Portable line-counter that never yields multi-line output under set -e
count_lines() {
  [ -z "$1" ] && { echo 0; return; }
  printf '%s\n' "$1" | grep -c . 2>/dev/null || echo 0
}

CSS_COUNT=$(count_lines "$CSS_FILES")
MISSING_RTL=()

if [ "$CSS_COUNT" -gt 0 ] && [ "$AUTO_RTL" -eq 0 ]; then
  # Check each CSS has a counterpart
  while IFS= read -r css; do
    [ -z "$css" ] && continue
    base="${css%.css}"
    if [ ! -f "${base}-rtl.css" ] && [ ! -f "$(dirname "$css")/rtl.css" ]; then
      MISSING_RTL+=("$css")
    fi
  done <<< "$CSS_FILES"

  if [ "${#MISSING_RTL[@]}" -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC} ${#MISSING_RTL[@]} CSS file(s) have no RTL counterpart:"
    for f in "${MISSING_RTL[@]:0:3}"; do
      echo "     ${f#$PLUGIN_PATH/}"
    done
    echo "   Two fixes:"
    echo "   (a) wp_style_add_data(\$handle, 'rtl', 'replace') for auto-swap"
    echo "   (b) ship <file>-rtl.css alongside each <file>.css (WP auto-swaps)"
    WARN=1
  else
    echo -e "${GREEN}✓${NC} All $CSS_COUNT CSS files have RTL counterparts"
  fi
elif [ "$AUTO_RTL" -gt 0 ]; then
  echo -e "${GREEN}✓${NC} wp_style_add_data('rtl') registered ($AUTO_RTL styles — WP auto-handles)"
else
  echo "  (no CSS files — not applicable)"
fi

# ─── 2. is_rtl() used in PHP for direction-aware output ──────────────────────
echo ""
echo -e "${CYAN}#2 — is_rtl() used for direction-aware output${NC}"
IS_RTL_USE=$(grep -rE "is_rtl\s*\(" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

# Look for direction-hardcoded PHP that should use is_rtl()
HARDCODED_DIR=$(grep -rEn "class\s*=\s*['\"][^'\"]*(\b(pull-left|pull-right|text-left|text-right|float-left|float-right))[^'\"]*['\"]" \
  "$PLUGIN_PATH" --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -3 || true)

if [ "$IS_RTL_USE" -gt 0 ]; then
  echo -e "${GREEN}✓${NC} is_rtl() used ($IS_RTL_USE call(s))"
fi
if [ -n "$HARDCODED_DIR" ]; then
  echo -e "${YELLOW}⚠${NC} Direction-specific Bootstrap classes in PHP — not RTL-aware:"
  echo "$HARDCODED_DIR" | head -2 | sed 's/^/     /'
  echo "   Use logical classes: text-start / text-end, pull-start / pull-end"
  WARN=1
fi

# ─── 3. Domain Path header ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}#3 — Domain Path header present${NC}"
MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1 || true)
if [ -n "$MAIN_FILE" ]; then
  DP=$(grep -iE "^\s*\*?\s*Domain Path:" "$MAIN_FILE" | head -1 | sed -E 's/.*Domain Path:\s*//' | tr -d ' \r')
  if [ -n "$DP" ]; then
    echo -e "${GREEN}✓${NC} Domain Path: $DP"
  else
    echo -e "${YELLOW}⚠${NC} Domain Path header missing — RTL/translation loading may fail"
    echo "   Add to plugin header: Domain Path: /languages"
    WARN=1
  fi
fi

# ─── 4. readme.txt mentions RTL ──────────────────────────────────────────────
echo ""
echo -e "${CYAN}#4 — readme.txt declares RTL support${NC}"
if [ -f "$PLUGIN_PATH/readme.txt" ]; then
  RTL_MENTION=$(grep -iE "rtl|right.to.left|bidi|bidirectional|arabic|hebrew|farsi" "$PLUGIN_PATH/readme.txt" | head -2 || true)
  if [ -n "$RTL_MENTION" ]; then
    echo -e "${GREEN}✓${NC} readme.txt mentions RTL/bidi support"
  else
    echo -e "${YELLOW}⚠${NC} readme.txt doesn't mention RTL — users won't know it's supported"
    WARN=1
  fi
fi

# ─── 5. Hardcoded directional CSS properties ─────────────────────────────────
echo ""
echo -e "${CYAN}#5 — CSS uses logical properties where possible${NC}"
if [ "$CSS_COUNT" -gt 0 ]; then
  # Count physical (LTR-only) properties vs logical
  PHYSICAL=$(grep -rE "(margin-left|margin-right|padding-left|padding-right|border-left|border-right|left:|right:|text-align:\s*(left|right)|float:\s*(left|right))" \
    "$PLUGIN_PATH" --include="*.css" --exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=build \
    2>/dev/null | wc -l | tr -d ' ' || echo 0)
  LOGICAL=$(grep -rE "(margin-inline-start|margin-inline-end|padding-inline-start|padding-inline-end|border-inline-start|border-inline-end|inset-inline-start|inset-inline-end|text-align:\s*(start|end))" \
    "$PLUGIN_PATH" --include="*.css" --exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=build \
    2>/dev/null | wc -l | tr -d ' ' || echo 0)
  PHYSICAL=${PHYSICAL:-0}
  LOGICAL=${LOGICAL:-0}

  echo "  Physical (LTR-hardcoded): $PHYSICAL  ·  Logical (RTL-safe): $LOGICAL"

  if [ "$PHYSICAL" -gt 20 ] && [ "$LOGICAL" -eq 0 ] && [ "$AUTO_RTL" -eq 0 ] && [ "${#MISSING_RTL[@]}" -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC} $PHYSICAL direction-specific CSS properties + no RTL counterpart + no logical props"
    echo "   Either: ship -rtl.css OR migrate to logical properties (inline-start/end)"
    WARN=1
  elif [ "$LOGICAL" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Uses logical properties ($LOGICAL instances — RTL-safe by default)"
  else
    echo -e "${GREEN}✓${NC} CSS direction usage acceptable"
  fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════"
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}RTL readiness: FAIL${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}RTL readiness: WARN — review above${NC}"
  echo ""
  echo "Full RTL verification: also run the dynamic layout test:"
  echo "   PLUGIN_ADMIN_SLUG=your-plugin npx playwright test --project=rtl"
  exit 0
fi
echo -e "${GREEN}RTL readiness: PASS${NC}"
exit 0
