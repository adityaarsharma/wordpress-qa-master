#!/usr/bin/env bash
# Orbit — Full Pre-Release Gauntlet
# Usage: bash scripts/gauntlet.sh --plugin /path/to/plugin [--env local|ci] [--mode full|quick]
#
# macOS note: if you see "colors not working", run: export TERM=xterm-256color

set -e
[ -z "$TERM" ] && export TERM=xterm-256color

PLUGIN_PATH=""
ENV="local"
MODE="full"
INSTALL_TYPE=""
REPORT_DIR="reports"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$REPORT_DIR/qa-report-$TIMESTAMP.md"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ok()     { echo -e "${GREEN}✓ $1${NC}"; }
warn()   { echo -e "${YELLOW}⚠ $1${NC}"; }
fail()   { echo -e "${RED}✗ $1${NC}"; }
header() { echo -e "\n${BOLD}[ $1 ]${NC}"; }
log()    { echo "$1" >> "$REPORT_FILE"; }

# Parse args
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --plugin)  PLUGIN_PATH="$2"; shift ;;
    --env)     ENV="$2"; shift ;;
    --mode)    MODE="$2"; shift ;;
    --install) INSTALL_TYPE="$2"; shift ;;  # fresh|update — skips prompt in CI
  esac
  shift
done

if [ -z "$PLUGIN_PATH" ] && [ -f "qa.config.json" ]; then
  PLUGIN_PATH=$(python3 -c "import json; print(json.load(open('qa.config.json'))['plugin']['path'])" 2>/dev/null || echo "")
fi
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 --plugin /path/to/plugin  (or run from dir with qa.config.json)"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Plugin path not found: $PLUGIN_PATH"; exit 1; }

mkdir -p "$REPORT_DIR"
PLUGIN_NAME=$(basename "$PLUGIN_PATH")

# Init report
cat > "$REPORT_FILE" << EOF
# Orbit Gauntlet Report
**Plugin**: $PLUGIN_NAME
**Date**: $(date)
**Mode**: $MODE / $ENV
**Path**: $PLUGIN_PATH

---

EOF

echo ""
echo -e "${BOLD}Orbit — Pre-Release Gauntlet${NC}"
echo -e "Plugin: ${YELLOW}$PLUGIN_NAME${NC} | Mode: $MODE | Env: $ENV"
echo "================================================"

# ── STEP 0: Install context prompt ────────────────────────────────────────────
# Different risk profile: fresh installs can have DB migration issues;
# updates must preserve existing user data. Knowing which we're testing
# lets Orbit adjust what to flag as critical vs expected.
if [ -z "$INSTALL_TYPE" ] && [ -t 0 ]; then
  echo ""
  echo -e "${BOLD}  Step 0: What are you testing?${NC}"
  echo "    [1] Fresh install — testing on a clean WordPress site"
  echo "    [2] Plugin update — testing upgrade from a previous version"
  echo "    [3] Skip (run all checks)"
  echo ""
  read -rp "  Enter 1, 2, or 3 [3]: " install_choice
  case "${install_choice:-3}" in
    1) INSTALL_TYPE="fresh" ;;
    2) INSTALL_TYPE="update" ;;
    *) INSTALL_TYPE="full" ;;
  esac
fi

if [ "$INSTALL_TYPE" = "fresh" ]; then
  echo -e "  ${CYAN}Mode: Fresh install — will emphasize activation hooks, DB table creation, defaults${NC}"
elif [ "$INSTALL_TYPE" = "update" ]; then
  echo -e "  ${CYAN}Mode: Plugin update — will emphasize data migration, setting preservation, schema upgrade${NC}"
fi
echo ""

PASS=0; WARN=0; FAIL=0

# ── STEP 1: PHP LINT ──────────────────────────────────────────────────────────
header "Step 1: PHP Lint"
log "## Step 1: PHP Lint"

PHP_ERRORS=$(find "$PLUGIN_PATH" -name "*.php" \
  -not -path "*/vendor/*" -not -path "*/node_modules/*" \
  -exec php -l {} \; 2>&1 | grep -v "No syntax errors" | grep -v "^$" || true)

if [ -z "$PHP_ERRORS" ]; then
  ok "PHP lint — no syntax errors"
  log "- ✓ No PHP syntax errors"
  ((PASS++))
else
  fail "PHP lint — ERRORS FOUND:"
  echo "$PHP_ERRORS"
  log "- ✗ PHP syntax errors:\n\`\`\`\n$PHP_ERRORS\n\`\`\`"
  ((FAIL++))
fi

# ── STEP 1a: RELEASE GATE (plugin header, readme.txt, version parity, license) ──
# Runs only in --mode release|full. Blocks tag if any disagreement found.
if [ "$MODE" = "full" ] || [ "$MODE" = "release" ]; then
  header "Step 1a: Release Metadata"
  log "## Step 1a: Release Metadata"

  # Plugin header
  if bash scripts/check-plugin-header.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ Plugin header"; ((PASS++))
  else
    log "- ✗ Plugin header"; ((FAIL++))
  fi

  # readme.txt
  if [ -f "$PLUGIN_PATH/readme.txt" ]; then
    if bash scripts/check-readme-txt.sh "$PLUGIN_PATH" 2>&1; then
      log "- ✓ readme.txt"; ((PASS++))
    else
      log "- ✗ readme.txt"; ((FAIL++))
    fi
  fi

  # Version parity
  if bash scripts/check-version-parity.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ Version parity"; ((PASS++))
  else
    log "- ✗ Version parity"; ((FAIL++))
  fi

  # License compliance
  if bash scripts/check-license.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ License compliance"; ((PASS++))
  else
    log "- ⚠ License compliance"; ((WARN++))
  fi

  # block.json (only if blocks present)
  if find "$PLUGIN_PATH" -name "block.json" -not -path "*/node_modules/*" 2>/dev/null | grep -q .; then
    if bash scripts/check-block-json.sh "$PLUGIN_PATH" 2>&1; then
      log "- ✓ block.json"; ((PASS++))
    else
      log "- ⚠ block.json"; ((WARN++))
    fi
  fi

  # HPOS — only fires if plugin touches WooCommerce
  if bash scripts/check-hpos-declaration.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ HPOS (or not applicable)"; ((PASS++))
  else
    log "- ✗ HPOS declaration missing"; ((FAIL++))
  fi

  # WordPress function compatibility vs declared min WP
  if bash scripts/check-wp-compat.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ WP function compatibility"; ((PASS++))
  else
    log "- ✗ WP function compatibility (plugin uses newer WP functions than declared)"; ((FAIL++))
  fi

  # PHP compatibility (through PHP 8.5) vs declared min PHP
  if bash scripts/check-php-compat.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ PHP 8.x compatibility"; ((PASS++))
  else
    log "- ✗ PHP compatibility issues"; ((FAIL++))
  fi

  # Modern WP features (Script Modules, Interactivity API, Plugin Dependencies, etc.)
  if bash scripts/check-modern-wp.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ Modern WP features"; ((PASS++))
  else
    log "- ⚠ Modern WP: warnings"; ((WARN++))
  fi

  # Plugin ownership transfer detection (April 2026 supply-chain defense)
  if bash scripts/check-ownership-transfer.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ Ownership stable"; ((PASS++))
  else
    log "- ✗ Ownership transfer detected — manual review required"; ((FAIL++))
  fi

  # Live CVE correlation (NVD + WPScan public feeds)
  if bash scripts/check-live-cve.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ Live CVE correlation: clean"; ((PASS++))
  else
    log "- ⚠ Live CVE correlation: matching patterns found"; ((WARN++))
  fi

  # WP.org detailed guidelines (18 numbered rules)
  if bash scripts/check-wp-org-guidelines.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ WP.org guidelines"; ((PASS++))
  else
    log "- ✗ WP.org guidelines: submission would be rejected"; ((FAIL++))
  fi

  # POT file verification (not just generation — checks shipped file)
  if bash scripts/check-pot-file.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ POT file"; ((PASS++))
  else
    log "- ⚠ POT file missing or out-of-sync"; ((WARN++))
  fi

  # RTL readiness static check (complements rtl-layout.spec.js runtime test)
  if bash scripts/check-rtl-readiness.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ RTL readiness"; ((PASS++))
  else
    log "- ⚠ RTL readiness: missing rtl.css / is_rtl usage / Domain Path"; ((WARN++))
  fi

  # Generate design.md (architecture snapshot for release docs)
  if bash scripts/generate-design-md.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ design.md generated at $PLUGIN_PATH/design.md"; ((PASS++))
  else
    log "- ⚠ design.md generation skipped"; ((WARN++))
  fi
fi

# ── STEP 1b: ZIP HYGIENE + SUPPLY CHAIN + FORBIDDEN FUNCTIONS ────────────────
# Catches the #1 WP.org auto-rejection triggers (2025):
#   - Dev files shipped (.git, node_modules, tests/, composer.json)
#   - Source maps leaking original source
#   - Forbidden functions (eval, base64_decode, exec, system)
#   - Vulnerable composer/npm dependencies
header "Step 1b: Zip Hygiene + Supply Chain"
log "## Step 1b: Zip Hygiene"

if bash scripts/check-zip-hygiene.sh "$PLUGIN_PATH" 2>&1; then
  log "- ✓ Zip hygiene + supply chain: clean"
  ((PASS++))
else
  HYGIENE_EXIT=$?
  if [ "$HYGIENE_EXIT" -eq 1 ]; then
    log "- ✗ Zip hygiene: dev files or forbidden functions present"
    ((FAIL++))
  else
    log "- ⚠ Zip hygiene: warnings (review above)"
    ((WARN++))
  fi
fi

# ── STEP 1c: CODE DOCUMENTATION QUALITY ──────────────────────────────────────
# PHPDoc coverage, @since tags, @param/@return, TODO tracking, CHANGELOG sync.
# Runs in full mode. Exit 0=pass, 2=warnings (no hard failures possible).
if [ "$MODE" = "full" ] || [ "$MODE" = "release" ]; then
  header "Step 1c: Code Documentation Quality"
  log "## Step 1c: Code Docs"

  DOCS_EXIT=0
  PLUGIN_VERSION=$(grep -r "Version:" "$PLUGIN_PATH"/*.php 2>/dev/null | \
    grep -oE "[0-9]+\.[0-9]+(\.[0-9]+)?" | head -1 || echo "")

  bash scripts/check-code-docs.sh "$PLUGIN_PATH" ${PLUGIN_VERSION:+--version "$PLUGIN_VERSION"} 2>&1 || DOCS_EXIT=$?

  if [ "$DOCS_EXIT" -eq 0 ]; then
    log "- ✓ Code docs: all checks passed"
    ((PASS++))
  else
    log "- ⚠ Code docs: documentation gaps found (review before release)"
    ((WARN++))
  fi
fi

# ── STEP 2: WORDPRESS CODING STANDARDS ───────────────────────────────────────
header "Step 2: WordPress Coding Standards (PHPCS)"
log "## Step 2: PHPCS / WPCS"

if command -v phpcs &>/dev/null; then
  PHPCS_OUT=$(phpcs \
    --standard="$(pwd)/config/phpcs.xml" \
    --extensions=php \
    --ignore=vendor,node_modules \
    --report=summary \
    "$PLUGIN_PATH" 2>&1 || true)

  ERROR_COUNT=$(echo "$PHPCS_OUT" | grep -oE '[0-9]+ ERROR' | grep -oE '[0-9]+' | head -1 || echo "0")
  WARN_COUNT=$(echo "$PHPCS_OUT"  | grep -oE '[0-9]+ WARNING' | grep -oE '[0-9]+' | head -1 || echo "0")

  if [ "$ERROR_COUNT" -eq 0 ] && [ "$WARN_COUNT" -lt 10 ]; then
    ok "PHPCS — $ERROR_COUNT errors, $WARN_COUNT warnings"
    log "- ✓ PHPCS: $ERROR_COUNT errors, $WARN_COUNT warnings"
    ((PASS++))
  elif [ "$ERROR_COUNT" -gt 0 ]; then
    fail "PHPCS — $ERROR_COUNT errors, $WARN_COUNT warnings"
    log "- ✗ PHPCS: $ERROR_COUNT errors, $WARN_COUNT warnings"
    ((FAIL++))
  else
    warn "PHPCS — $WARN_COUNT warnings (review needed)"
    log "- ⚠ PHPCS: $WARN_COUNT warnings"
    ((WARN++))
  fi
else
  warn "phpcs not installed — skipping. Run: composer global require squizlabs/php_codesniffer"
  log "- ⚠ PHPCS: skipped (not installed)"
  ((WARN++))
fi

# ── STEP 2b: WORDPRESS.ORG PLUGIN CHECK (official WP.org review tool) ────────
# This is what the WordPress.org plugin review team actually runs.
# Catches: unsafe functions (eval, base64_decode), remote code exec patterns,
# GPL violations, readme.txt format errors, plugin header issues, and 40+ more.
header "Step 2b: WordPress.org Plugin Check"
log "## Step 2b: Plugin Check (WP.org)"

if command -v wp &>/dev/null; then
  PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
  # Copy plugin to wp-env plugins dir if running in local wp-env
  WP_ENV_PLUGINS=""
  if [ -d ".wp-env" ]; then
    WP_ENV_PLUGINS=$(wp eval 'echo WP_PLUGIN_DIR;' --path="$(wp eval 'echo ABSPATH;' 2>/dev/null)" 2>/dev/null || echo "")
  fi

  # Run plugin-check via wp-cli (requires plugin-check plugin installed in wp-env)
  # Install: wp plugin install plugin-check --activate
  WP_CHECK_OUT=$(wp plugin check "$PLUGIN_SLUG" \
    --format=table 2>&1 || true)
  WP_CHECK_ERRORS=$(echo "$WP_CHECK_OUT" | grep -c "ERROR\|error" 2>/dev/null || echo "0")
  WP_CHECK_WARNINGS=$(echo "$WP_CHECK_OUT" | grep -c "WARNING\|warning" 2>/dev/null || echo "0")

  if echo "$WP_CHECK_OUT" | grep -qi "no errors\|no issues\|0 errors"; then
    ok "Plugin Check — passed (WP.org review compliant)"
    log "- ✓ Plugin Check: passed"
    ((PASS++))
  elif [ "$WP_CHECK_ERRORS" -gt 0 ]; then
    fail "Plugin Check — $WP_CHECK_ERRORS errors (would fail WP.org review)"
    echo "$WP_CHECK_OUT" | head -20
    log "- ✗ Plugin Check: $WP_CHECK_ERRORS errors, $WP_CHECK_WARNINGS warnings"
    ((FAIL++))
  else
    warn "Plugin Check — $WP_CHECK_WARNINGS warnings (review before WP.org submission)"
    log "- ⚠ Plugin Check: $WP_CHECK_WARNINGS warnings"
    ((WARN++))
  fi
else
  warn "WP-CLI not found — skipping Plugin Check. Install: brew install wp-cli"
  log "- ⚠ Plugin Check: skipped (wp-cli not found)"
  ((WARN++))
fi

# ── STEP 3: PHPSTAN STATIC ANALYSIS ──────────────────────────────────────────
header "Step 3: PHPStan Static Analysis"
log "## Step 3: PHPStan"

if command -v phpstan &>/dev/null; then
  PHPSTAN_OUT=$(phpstan analyse \
    --configuration="$(pwd)/config/phpstan.neon" \
    --no-progress \
    "$PLUGIN_PATH/includes" 2>&1 || true)

  if echo "$PHPSTAN_OUT" | grep -q "No errors"; then
    ok "PHPStan — no errors"
    log "- ✓ PHPStan: clean"
    ((PASS++))
  else
    PHPSTAN_ERRORS=$(echo "$PHPSTAN_OUT" | tail -5)
    warn "PHPStan — issues found (review)"
    log "- ⚠ PHPStan:\n\`\`\`\n$PHPSTAN_ERRORS\n\`\`\`"
    ((WARN++))
  fi
else
  warn "phpstan not installed — skipping"
  log "- ⚠ PHPStan: skipped"
  ((WARN++))
fi

# ── STEP 4: ASSET WEIGHT ─────────────────────────────────────────────────────
header "Step 4: Asset Weight Audit"
log "## Step 4: Asset Weight"

JS_SIZE=$(find "$PLUGIN_PATH" -name "*.js" -not -path "*/node_modules/*" \
  -not -name "*.min.js" 2>/dev/null | xargs wc -c 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
CSS_SIZE=$(find "$PLUGIN_PATH" -name "*.css" -not -path "*/node_modules/*" 2>/dev/null \
  | xargs wc -c 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
JS_MB=$(echo "scale=2; $JS_SIZE/1048576" | bc 2>/dev/null || echo "?")
CSS_KB=$(echo "scale=0; $CSS_SIZE/1024" | bc 2>/dev/null || echo "?")

ok "JS total: ${JS_MB}MB | CSS total: ${CSS_KB}KB"
log "- JS total: ${JS_MB}MB | CSS total: ${CSS_KB}KB"
((PASS++))

# ── STEP 5: i18n / POT FILE CHECK ─────────────────────────────────────────────
header "Step 5: i18n / POT File"
log "## Step 5: i18n / POT"

if command -v wp &>/dev/null; then
  POT_OUT=$(cd "$PLUGIN_PATH" && wp i18n make-pot . /tmp/orbit-check.pot --skip-audit 2>&1 || true)
  UNWRAPPED=$(grep -rE "echo\s+['\"]" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null \
    | grep -vE "(__\(|_e\(|esc_html__|esc_attr__|_x\(|_n\()" | wc -l | tr -d ' ')

  if [ -f "/tmp/orbit-check.pot" ]; then
    STRINGS=$(grep -c '^msgid "' /tmp/orbit-check.pot || echo "0")
    ok "POT generated — $STRINGS translatable strings"
    log "- ✓ POT generated: $STRINGS strings"
    if [ "$UNWRAPPED" -gt 0 ]; then
      warn "$UNWRAPPED possibly untranslated echo strings — review"
      log "- ⚠ $UNWRAPPED possibly untranslated strings"
      ((WARN++))
    else
      ((PASS++))
    fi
    rm -f /tmp/orbit-check.pot
  else
    warn "POT generation failed — check plugin header + text domain"
    log "- ⚠ POT generation failed"
    ((WARN++))
  fi
else
  warn "wp-cli not installed — skipping i18n check"
  log "- ⚠ i18n: skipped (wp-cli missing)"
  ((WARN++))
fi

# ── STEP 6: PLAYWRIGHT FUNCTIONAL + VISUAL TESTS ─────────────────────────────
header "Step 6: Playwright Functional + Visual + UI Audit Tests"
log "## Step 6: Playwright"

PW_CONFIG="tests/playwright/playwright.config.js"

if command -v npx &>/dev/null && [ -f "$PW_CONFIG" ]; then
  # Ensure auth file exists — run setup project first if not
  if [ ! -f ".auth/wp-admin.json" ]; then
    echo "  Running auth setup (one-time)..."
    WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
      npx playwright test --config="$PW_CONFIG" --project=setup 2>/dev/null || true
  fi

  # Run all tests: functional (chromium) + visual snapshots + UI audit
  PLAYWRIGHT_OUT=$(WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
    npx playwright test --config="$PW_CONFIG" \
    --project=chromium --project=visual \
    --reporter=line 2>&1 || true)

  PASSED=$(echo "$PLAYWRIGHT_OUT" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' | head -1 || echo "0")
  FAILED=$(echo "$PLAYWRIGHT_OUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | head -1 || echo "0")

  # Always generate HTML report
  HTML_REPORT="reports/playwright-html/index.html"
  if [ "$FAILED" -eq 0 ]; then
    ok "Playwright — $PASSED tests passed"
    log "- ✓ Playwright: $PASSED passed, 0 failed"
    ((PASS++))
  else
    fail "Playwright — $FAILED failed, $PASSED passed"
    log "- ✗ Playwright: $FAILED failed, $PASSED passed"
    ((FAIL++))
  fi
  log "- HTML report: $HTML_REPORT"
  echo -e "  ${CYAN}HTML report:${NC} $(pwd)/$HTML_REPORT"
  echo -e "  ${CYAN}View with:${NC} npx playwright show-report reports/playwright-html"

  # ── STEP 6a: PM UX + GDPR + Asset Leak flows ──────────────────────────────
  # Run the dedicated PM/GDPR specs as part of the Playwright phase.
  # These always run as "warn-only" — no hard failures from this group.
  PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
  PM_SPECS="tests/playwright/flows"
  if [ -d "$PM_SPECS" ]; then
    PM_SPEC_LIST=$(find "$PM_SPECS" -name "*.spec.js" | sort | tr '\n' ',' | sed 's/,$//')
    if [ -n "$PM_SPEC_LIST" ]; then
      echo ""
      echo -e "  ${CYAN}Running PM/GDPR/asset-leak flow specs...${NC}"

      ADMIN_SLUG=$(python3 -c "import json; print(json.load(open('qa.config.json')).get('plugin',{}).get('admin_slug',''))" 2>/dev/null || echo "$PLUGIN_SLUG")
      HAS_FORMS=$(python3 -c "import json; print(str(json.load(open('qa.config.json')).get('plugin',{}).get('has_email_forms',False)).lower())" 2>/dev/null || echo "false")
      ACTIVE_PAGES=$(python3 -c "import json; print(','.join(json.load(open('qa.config.json')).get('plugin',{}).get('frontend_active_pages',[])))" 2>/dev/null || echo "")

      PLUGIN_SLUG="$PLUGIN_SLUG" \
      PLUGIN_ADMIN_SLUG="$ADMIN_SLUG" \
      PLUGIN_HAS_EMAIL_FORMS="$HAS_FORMS" \
      PLUGIN_ACTIVE_PAGES="$ACTIVE_PAGES" \
      WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
        npx playwright test --config="$PW_CONFIG" \
        --grep-invert "cookie-consent|opt-out" \
        "$PM_SPECS" \
        --reporter=line 2>&1 | tail -10 || true

      PM_REPORT_DIR="reports/pm-ux"
      PM_JSON_COUNT=$(ls "$PM_REPORT_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
      ok "PM/GDPR flow specs: $PM_JSON_COUNT report(s) written to $PM_REPORT_DIR/"
      log "- ✓ PM/GDPR flows: $PM_JSON_COUNT JSON reports"
    fi
  fi

  # ── STEP 6b: Flow comparison videos (feeds PM HTML report) ─────────────────
  FLOW_SPECS=$(find tests/playwright/flows -name "*.spec.js" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$FLOW_SPECS" -gt 0 ]; then
    echo ""
    echo -e "  ${CYAN}Running $FLOW_SPECS flow spec(s) with video recording...${NC}"
    mkdir -p reports/screenshots/flows-compare reports/videos

    WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
      npx playwright test --config="$PW_CONFIG" \
      --project=video \
      --reporter=line 2>&1 | tail -5 || true

    FLOW_SNAPS=$(ls reports/screenshots/flows-compare/*.png 2>/dev/null | wc -l | tr -d ' ')
    FLOW_VIDS=$(find reports/videos -name "*.webm" -o -name "*.mp4" 2>/dev/null | wc -l | tr -d ' ')
    ok "Flow videos: $FLOW_VIDS videos | $FLOW_SNAPS screenshots"
    log "- ✓ Flow recording: $FLOW_VIDS videos, $FLOW_SNAPS screenshots"

    # Generate deep PM HTML report
    UAT_HTML="reports/uat-report-$TIMESTAMP.html"
    python3 scripts/generate-uat-report.py \
      --title "UAT Report — $(date +%Y-%m-%d)" \
      --snaps "reports/screenshots/flows-compare" \
      --videos "reports/videos" \
      --out "$UAT_HTML" 2>/dev/null && {
      ok "PM report generated: $UAT_HTML"
      log "- ✓ PM report: $UAT_HTML"
      echo -e "  ${CYAN}Open report:${NC} open $(pwd)/$UAT_HTML"
      ((PASS++))
    } || {
      warn "PM report generation failed — run: python3 scripts/generate-uat-report.py"
      log "- ⚠ PM report: generation failed"
      ((WARN++))
    }
  fi
else
  warn "Playwright not configured — skipping. Run: npm install && npx playwright install"
  log "- ⚠ Playwright: skipped (not configured)"
  ((WARN++))
fi

# ── STEP 6c: PHP DEPRECATION NOTICE SCAN (runtime — PHPStan can't catch these) ─
# PHPStan is static analysis. PHP Deprecated notices only appear at RUNTIME
# when the deprecated code path is actually executed. This step catches them
# by parsing wp-content/debug.log after Playwright has exercised the plugin.
header "Step 6c: PHP Deprecation Notice Scan"
log "## Step 6c: Deprecation Scan"

# Find wp-content debug.log (works with wp-env and standard installs)
DEBUG_LOG_PATHS=(
  "$(wp eval 'echo WP_CONTENT_DIR;' 2>/dev/null)/debug.log"
  ".wp-env/*/WordPress/wp-content/debug.log"
  "/tmp/wordpress/wp-content/debug.log"
)
DEBUG_LOG=""
for path in "${DEBUG_LOG_PATHS[@]}"; do
  # Handle glob patterns
  for resolved in $path; do
    if [ -f "$resolved" ]; then
      DEBUG_LOG="$resolved"
      break 2
    fi
  done
done

if [ -n "$DEBUG_LOG" ] && [ -f "$DEBUG_LOG" ]; then
  PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
  # Count deprecations from this plugin specifically
  DEPRECATED=$(grep -i "PHP Deprecated" "$DEBUG_LOG" 2>/dev/null | \
    grep -i "$PLUGIN_SLUG" | wc -l | tr -d ' ' || echo "0")
  # Count all deprecations (could be WP core or other plugins affecting ours)
  ALL_DEPRECATED=$(grep -c "PHP Deprecated" "$DEBUG_LOG" 2>/dev/null || echo "0")

  if [ "$DEPRECATED" -eq 0 ]; then
    ok "No PHP deprecation notices from $PLUGIN_SLUG (debug.log)"
    [ "$ALL_DEPRECATED" -gt 0 ] && warn "  Note: $ALL_DEPRECATED total deprecations in log (from WP core or other plugins)"
    log "- ✓ Deprecation scan: 0 from plugin, $ALL_DEPRECATED total"
    ((PASS++))
  else
    fail "$DEPRECATED PHP Deprecated notices from $PLUGIN_SLUG — PHP 8.x incompatibility risk"
    grep -i "PHP Deprecated" "$DEBUG_LOG" | grep -i "$PLUGIN_SLUG" | head -5
    log "- ✗ Deprecation: $DEPRECATED notices from plugin"
    ((FAIL++))
  fi
else
  warn "debug.log not found — enable WP_DEBUG + WP_DEBUG_LOG for deprecation scan"
  warn "  Add to wp-env .wp-env.json: { \"config\": { \"WP_DEBUG\": true, \"WP_DEBUG_LOG\": true } }"
  log "- ⚠ Deprecation scan: skipped (debug.log not found)"
  ((WARN++))
fi

# ── STEP 7: LIGHTHOUSE PERFORMANCE ───────────────────────────────────────────
if [ "$MODE" = "full" ]; then
  header "Step 7: Lighthouse Performance"
  log "## Step 7: Lighthouse"

  WP_LOCAL_URL="${WP_TEST_URL:-http://localhost:8881}"

  if command -v lighthouse &>/dev/null; then
    mkdir -p reports/lighthouse
    LHCI_OUT=$(lighthouse "$WP_LOCAL_URL" \
      --output=json \
      --output-path="reports/lighthouse/lh-$TIMESTAMP.json" \
      --chrome-flags="--headless --no-sandbox" \
      --quiet 2>&1 || true)

    if [ -f "reports/lighthouse/lh-$TIMESTAMP.json" ]; then
      SCORE=$(python3 -c "
import json
with open('reports/lighthouse/lh-$TIMESTAMP.json') as f:
    d = json.load(f)
print(int(d['categories']['performance']['score']*100))
" 2>/dev/null || echo "?")

      if [ "$SCORE" != "?" ] && [ "$SCORE" -ge 80 ]; then
        ok "Lighthouse performance: $SCORE/100"
        log "- ✓ Lighthouse: $SCORE/100"
        ((PASS++))
      elif [ "$SCORE" != "?" ]; then
        warn "Lighthouse performance: $SCORE/100 (target: 80+)"
        log "- ⚠ Lighthouse: $SCORE/100"
        ((WARN++))
      fi

      # ── Attribution: map slow resources back to plugin files ─────────────────
      ATTR_OUT="reports/lighthouse/attribution-$TIMESTAMP.md"
      python3 scripts/lighthouse-attribution.py \
        --report "reports/lighthouse/lh-$TIMESTAMP.json" \
        --slug "$(basename "$PLUGIN_PATH")" \
        --out "$ATTR_OUT" 2>/dev/null && {
        ok "Lighthouse attribution: $ATTR_OUT"
        log "- ✓ Lighthouse attribution: $ATTR_OUT"
        echo -e "  ${CYAN}Open:${NC} open $(pwd)/$ATTR_OUT"
      } || {
        warn "Lighthouse attribution: run manually: python3 scripts/lighthouse-attribution.py"
        log "- ⚠ Lighthouse attribution: failed"
      }
    fi
  else
    warn "Lighthouse not installed — skipping. Install: npm install -g lighthouse"
    log "- ⚠ Lighthouse: skipped (install with: npm install -g lighthouse)"
    ((WARN++))
  fi
fi

# ── STEP 8: DB PROFILING (local only) ─────────────────────────────────────────
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ]; then
  header "Step 8: Database Profiling"
  log "## Step 8: Database"
  bash scripts/db-profile.sh 2>/dev/null || warn "DB profiling failed — see docs/database-profiling.md"
  log "- See reports/db-profile-$TIMESTAMP.txt"
fi

# ── STEP 8b: MEMORY PROFILING ─────────────────────────────────────────────────
# Shared hosting memory limits: 64MB (common cheap hosting), 128MB (standard),
# 256MB+ (managed hosting). A single bloated plugin can white-screen an entire site.
# This check measures PHP peak memory usage when the plugin is active.
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ]; then
  header "Step 8b: Memory Profiling"
  log "## Step 8b: Memory"

  if command -v wp &>/dev/null; then
    # Peak memory after WP loads with plugin active
    PEAK_MEM=$(wp eval 'echo round(memory_get_peak_usage(true) / 1048576, 1);' 2>/dev/null || echo "?")
    # Current memory limit
    MEM_LIMIT=$(wp eval 'echo WP_MEMORY_LIMIT;' 2>/dev/null || echo "?")

    if [ "$PEAK_MEM" != "?" ]; then
      PEAK_INT=$(echo "$PEAK_MEM" | cut -d. -f1)
      if [ "$PEAK_INT" -lt 32 ]; then
        ok "Peak memory: ${PEAK_MEM}MB (excellent — under 32MB threshold)"
        log "- ✓ Memory: ${PEAK_MEM}MB peak (limit: $MEM_LIMIT)"
        ((PASS++))
      elif [ "$PEAK_INT" -lt 64 ]; then
        warn "Peak memory: ${PEAK_MEM}MB (watch — approaches 64MB shared hosting limit)"
        log "- ⚠ Memory: ${PEAK_MEM}MB peak (limit: $MEM_LIMIT)"
        ((WARN++))
      else
        fail "Peak memory: ${PEAK_MEM}MB (HIGH — will crash on 64MB shared hosting)"
        log "- ✗ Memory: ${PEAK_MEM}MB peak — exceeds shared hosting limit"
        ((FAIL++))
      fi
    else
      warn "Memory profiling failed — is wp-env running?"
      log "- ⚠ Memory: skipped (wp-cli eval failed)"
      ((WARN++))
    fi
  else
    warn "WP-CLI not found — skipping memory profiling"
    log "- ⚠ Memory: skipped (wp-cli not found)"
    ((WARN++))
  fi
fi

# ── STEP 8c: WP-CRON VERIFICATION ─────────────────────────────────────────────
# Cron failures are completely silent in WordPress — no error, no log.
# A plugin that registers scheduled events on activation must also clear them
# on deactivation. This step checks the cron queue state using WP-CLI.
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ]; then
  header "Step 8c: WP-Cron Event Verification"
  log "## Step 8c: WP-Cron"

  if command -v wp &>/dev/null; then
    CRON_COUNT=$(wp cron event list --format=count 2>/dev/null || echo "?")
    CRON_LIST=$(wp cron event list --format=table 2>/dev/null | head -20 || echo "")

    if [ "$CRON_COUNT" != "?" ]; then
      ok "WP-Cron events registered: $CRON_COUNT"
      # Check for overdue events (stuck/never-firing crons)
      OVERDUE=$(wp cron event list --format=json 2>/dev/null | \
        python3 -c "import json,sys,time; d=json.load(sys.stdin); print(sum(1 for e in d if e.get('next_run_relative','').startswith('-')))" \
        2>/dev/null || echo "0")
      if [ "$OVERDUE" -gt 0 ]; then
        warn "  $OVERDUE overdue cron events (scheduled in the past, never fired)"
        warn "  Check: is DISABLE_WP_CRON=true without a server-side cron replacement?"
        log "- ⚠ Cron: $CRON_COUNT events, $OVERDUE overdue"
        ((WARN++))
      else
        log "- ✓ Cron: $CRON_COUNT events, 0 overdue"
        ((PASS++))
      fi
      # Show first 5 events for manual verification
      echo -e "  ${CYAN}Cron events (verify your plugin's scheduled hooks are present):${NC}"
      wp cron event list --format=table 2>/dev/null | head -8 || true
    else
      warn "Could not read WP-Cron events — is wp-env running?"
      log "- ⚠ Cron: skipped"
      ((WARN++))
    fi
  else
    warn "WP-CLI not found — skipping cron verification"
    log "- ⚠ Cron: skipped (wp-cli not found)"
    ((WARN++))
  fi
fi

# ── STEP 8d: Full GDPR Compliance Check ───────────────────────────────────────
# Covers: WP Privacy API hooks, cookie declaration, third-party scripts,
# email collection opt-in, data encryption, data minimization, uninstall cleanup,
# CCPA/GPC signals. Exit 0=pass, 1=fail (missing required hooks), 2=warnings.
if [ "$MODE" = "full" ]; then
  header "Step 8d: GDPR Full Compliance"
  log "## Step 8d: GDPR"

  GDPR_EXIT=0
  bash scripts/check-gdpr-full.sh "$PLUGIN_PATH" 2>&1 || GDPR_EXIT=$?

  if [ "$GDPR_EXIT" -eq 0 ]; then
    log "- ✓ GDPR: all checks passed"
    ((PASS++))
  elif [ "$GDPR_EXIT" -eq 1 ]; then
    log "- ✗ GDPR: required Privacy API hooks missing — WP.org will reject"
    ((FAIL++))
  else
    log "- ⚠ GDPR: warnings found — review before release"
    ((WARN++))
  fi
fi

# ── STEP 8d2: Database Schema Review ──────────────────────────────────────────
# Checks: CREATE TABLE vs existing WP tables, dbDelta() usage, index coverage,
# wp_options autoload audit, schema versioning, transient expiry, object cache.
if [ "$MODE" = "full" ]; then
  header "Step 8d2: Database Schema Review"
  log "## Step 8d2: DB Schema"

  DB_EXIT=0
  bash scripts/check-db-schema.sh "$PLUGIN_PATH" 2>&1 || DB_EXIT=$?

  if [ "$DB_EXIT" -eq 0 ]; then
    log "- ✓ DB schema: all checks passed"
    ((PASS++))
  elif [ "$DB_EXIT" -eq 1 ]; then
    log "- ✗ DB schema: critical issue (CREATE TABLE without dbDelta)"
    ((FAIL++))
  else
    log "- ⚠ DB schema: warnings found — review schema decisions"
    ((WARN++))
  fi
fi

# ── STEP 8e: Login Page Asset Leak Check ──────────────────────────────────────
# Many plugins accidentally enqueue scripts on wp-login.php. Slows login,
# leaks plugin info to unauthenticated visitors.
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ]; then
  header "Step 8e: Login Page Asset Check"
  log "## Step 8e: Login Assets"
  PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
  if bash scripts/check-login-assets.sh "$PLUGIN_SLUG" "${WP_TEST_URL:-http://localhost:8881}" 2>&1; then
    log "- ✓ Login assets: no leakage"
    ((PASS++))
  else
    log "- ⚠ Login assets: plugin leaking on wp-login.php"
    ((WARN++))
  fi
fi

# ── STEP 8f: Translation / i18n Runtime Test ──────────────────────────────────
# Tests the plugin with an actual loaded .mo file. Catches mistranslated
# format strings (sprintf with wrong arg count) that crash PHP at runtime.
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ]; then
  header "Step 8f: Translation Runtime Test"
  log "## Step 8f: Translation"
  if bash scripts/check-translation.sh "$PLUGIN_PATH" 2>&1; then
    log "- ✓ Translation: passes under pseudo-locale load"
    ((PASS++))
  else
    log "- ⚠ Translation: PHP errors under translation"
    ((WARN++))
  fi
fi

# ── STEP 8g: Lifecycle Tests (uninstall / update / block deprecation) ─────────
# Playwright specs that verify:
#   - Plugin cleans up options/tables/cron on delete (WP.org compliance)
#   - v1 → v2 upgrade preserves user settings
#   - Existing Gutenberg block content doesn't break after update
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ] && command -v npx &>/dev/null; then
  PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
  PLUGIN_PREFIX=$(python3 -c "import json; print(json.load(open('qa.config.json')).get('plugin',{}).get('prefix',''))" 2>/dev/null || echo "${PLUGIN_SLUG//-/_}")

  header "Step 8g: Lifecycle Tests (uninstall / update / blocks)"
  log "## Step 8g: Lifecycle"

  LIFECYCLE_OUT=$(PLUGIN_SLUG="$PLUGIN_SLUG" PLUGIN_PREFIX="$PLUGIN_PREFIX" \
    WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
    npx playwright test --config="$PW_CONFIG" --project=lifecycle --reporter=line 2>&1 || true)

  LC_PASSED=$(echo "$LIFECYCLE_OUT" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' | head -1 || echo "0")
  LC_FAILED=$(echo "$LIFECYCLE_OUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | head -1 || echo "0")

  if [ "$LC_FAILED" -eq 0 ] && [ "$LC_PASSED" -gt 0 ]; then
    ok "Lifecycle tests: $LC_PASSED passed"
    log "- ✓ Lifecycle: $LC_PASSED passed"
    ((PASS++))
  elif [ "$LC_FAILED" -gt 0 ]; then
    fail "Lifecycle tests: $LC_FAILED failed"
    log "- ✗ Lifecycle: $LC_FAILED failed"
    ((FAIL++))
  else
    warn "Lifecycle tests: skipped (configure PLUGIN_SLUG / PLUGIN_V1_ZIP / BLOCK_POST_ID in qa.config.json)"
    log "- ⚠ Lifecycle: tests skipped (env vars not configured)"
    ((WARN++))
  fi
fi

# ── STEP 8h: Keyboard Navigation + Admin Color Schemes (if admin UI) ─────────
# Catches focus traps and color-scheme incompatibility — both invisible to axe-core.
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ] && command -v npx &>/dev/null; then
  if [ -n "$(python3 -c "import json; c=json.load(open('qa.config.json')); print(c.get('plugin',{}).get('admin_slug',''))" 2>/dev/null)" ]; then
    header "Step 8h: Keyboard Navigation + Admin Color Schemes"
    log "## Step 8h: A11y Extras"

    ADMIN_SLUG=$(python3 -c "import json; print(json.load(open('qa.config.json'))['plugin'].get('admin_slug',''))" 2>/dev/null)

    # Keyboard nav
    KB_OUT=$(PLUGIN_ADMIN_SLUG="$ADMIN_SLUG" WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
      npx playwright test --config="$PW_CONFIG" --project=keyboard --reporter=line 2>&1 || true)
    KB_FAIL=$(echo "$KB_OUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | head -1 || echo "0")
    if [ "$KB_FAIL" -eq 0 ]; then
      ok "Keyboard navigation: no focus traps"
      ((PASS++))
    else
      warn "Keyboard navigation: $KB_FAIL failures (focus trap?)"
      ((WARN++))
    fi

    # Admin color schemes
    AC_OUT=$(PLUGIN_ADMIN_SLUG="$ADMIN_SLUG" WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
      npx playwright test --config="$PW_CONFIG" --project=admin-colors --reporter=line 2>&1 || true)
    AC_PASS=$(echo "$AC_OUT" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' | head -1 || echo "0")
    AC_FAIL=$(echo "$AC_OUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | head -1 || echo "0")
    if [ "$AC_FAIL" -eq 0 ]; then
      ok "Admin color schemes: $AC_PASS/9 compatible"
      log "- ✓ Admin colors: $AC_PASS schemes pass"
      ((PASS++))
    else
      warn "Admin color schemes: $AC_FAIL schemes break the UI"
      log "- ⚠ Admin colors: $AC_FAIL schemes fail"
      ((WARN++))
    fi

    # RTL layout
    RTL_OUT=$(PLUGIN_ADMIN_SLUG="$ADMIN_SLUG" WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
      npx playwright test --config="$PW_CONFIG" --project=rtl --reporter=line 2>&1 || true)
    RTL_FAIL=$(echo "$RTL_OUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | head -1 || echo "0")
    if [ "$RTL_FAIL" -eq 0 ]; then
      ok "RTL layout: compatible"
      ((PASS++))
    else
      warn "RTL layout: breaks in Arabic/Hebrew"
      ((WARN++))
    fi
  fi
fi

# ── STEP 8i: REST API Application Password Auth ───────────────────────────────
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ] && command -v npx &>/dev/null; then
  REST_ENDPOINT=$(python3 -c "import json; print(json.load(open('qa.config.json'))['plugin'].get('rest_admin_endpoint',''))" 2>/dev/null || echo "")
  if [ -n "$REST_ENDPOINT" ]; then
    header "Step 8i: REST API — Application Passwords"
    log "## Step 8i: App Passwords"

    AP_OUT=$(PLUGIN_REST_ADMIN_ENDPOINT="$REST_ENDPOINT" WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
      npx playwright test --config="$PW_CONFIG" --project=rest-apppass --reporter=line 2>&1 || true)
    AP_FAIL=$(echo "$AP_OUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | head -1 || echo "0")
    if [ "$AP_FAIL" -eq 0 ]; then
      ok "Application Passwords: permission checks hold"
      ((PASS++))
    else
      fail "Application Passwords: $AP_FAIL failures — IDOR or permission_callback bug"
      ((FAIL++))
    fi
  fi
fi

# ── STEP 9: COMPETITOR COMPARISON + VULNERABILITY INTELLIGENCE ────────────────
if [ -f "qa.config.json" ]; then
  COMPETITORS_JSON=$(python3 -c "
import json
c = json.load(open('qa.config.json')).get('competitors', [])
slugs = [s if isinstance(s, str) else s.get('slug', s.get('name','')) for s in c]
print(','.join(slugs))
" 2>/dev/null || echo "")

  if [ -n "$COMPETITORS_JSON" ]; then
    header "Step 9: Competitor Comparison + Vulnerability Intelligence"
    log "## Step 9: Competitor Analysis"

    # 9a: Feature/UX comparison
    bash scripts/competitor-compare.sh 2>/dev/null && {
      ok "Competitor feature comparison — see reports/competitor-*.md"
      log "- ✓ Competitor compare: see reports/competitor-*.md"
      ((PASS++))
    } || {
      warn "Competitor feature comparison failed — run: bash scripts/competitor-compare.sh"
      log "- ⚠ Competitor compare: failed"
      ((WARN++))
    }

    # 9b: CVE intelligence — what vulnerabilities did competitors have?
    echo ""
    VULN_EXIT=0
    bash scripts/check-competitor-vulns.sh "$PLUGIN_PATH" 2>&1 || VULN_EXIT=$?

    if [ "$VULN_EXIT" -eq 0 ]; then
      ok "Competitor CVE intelligence: no matching risk patterns"
      log "- ✓ Competitor CVE intel: clean"
      ((PASS++))
    else
      warn "Competitor CVE intelligence: matching patterns found — see reports/competitor-vulns-*.md"
      log "- ⚠ Competitor CVE intel: risk patterns found — review report"
      ((WARN++))
    fi
  fi
fi

# ── STEP 10: UI / FRONTEND PERFORMANCE ────────────────────────────────────────
if [ "$MODE" = "full" ]; then
  header "Step 10: UI / Frontend Performance"
  log "## Step 10: UI Performance"

  PLUGIN_TYPE=$(python3 -c "import json; print(json.load(open('qa.config.json'))['plugin']['type'])" 2>/dev/null || echo "general")
  WP_PERF_URL="${WP_TEST_URL:-http://localhost:8881}"

  # Editor performance (Elementor or Gutenberg editor load time)
  if [ "$PLUGIN_TYPE" = "elementor-addon" ] || [ "$PLUGIN_TYPE" = "gutenberg-blocks" ]; then
    if [ -f "scripts/editor-perf.sh" ]; then
      EDITOR_REPORT="reports/editor-perf-$TIMESTAMP.json"
      REPORT_PATH="$EDITOR_REPORT" bash scripts/editor-perf.sh \
        --url "$WP_PERF_URL" 2>/dev/null && {
        ok "Editor performance measured — see $EDITOR_REPORT"
        log "- ✓ Editor perf: $EDITOR_REPORT"
        ((PASS++))
      } || {
        warn "Editor perf failed — run manually: bash scripts/editor-perf.sh"
        log "- ⚠ Editor perf: failed"
        ((WARN++))
      }
    fi
  else
    # For SEO/WooCommerce/general plugins: measure frontend page load via curl
    LOAD_TIME=$(curl -o /dev/null -s -w "%{time_total}" "$WP_PERF_URL" 2>/dev/null || echo "?")
    TTFB=$(curl -o /dev/null -s -w "%{time_starttransfer}" "$WP_PERF_URL" 2>/dev/null || echo "?")
    if [ "$LOAD_TIME" != "?" ]; then
      LOAD_MS=$(echo "$LOAD_TIME * 1000" | bc 2>/dev/null | cut -d. -f1 || echo "?")
      TTFB_MS=$(echo "$TTFB * 1000" | bc 2>/dev/null | cut -d. -f1 || echo "?")
      ok "Frontend: total ${LOAD_MS}ms | TTFB ${TTFB_MS}ms"
      log "- ✓ Frontend load: ${LOAD_MS}ms | TTFB: ${TTFB_MS}ms"
      ((PASS++))
    else
      warn "Frontend perf check failed — is wp-env running? Start with: bash scripts/create-test-site.sh"
      log "- ⚠ Frontend perf: could not reach $WP_PERF_URL"
      ((WARN++))
    fi
  fi
fi

# ── STEP 11: CLAUDE SKILL AUDITS ──────────────────────────────────────────────
# Runs all 6 mandatory Orbit skills in parallel via Antigravity / claude CLI.
# Skills: WP standards · Security · Performance · DB · Accessibility · Code Quality
# Each skill writes a markdown file. After all finish, a consolidated HTML report
# is generated at reports/skill-audits/index.html — always output to file, never
# terminal-only.

if [ "$MODE" = "full" ] && command -v claude &>/dev/null && [ -n "$PLUGIN_PATH" ]; then
  header "Step 11: Claude Skill Audits (6 parallel)"
  log "## Step 11: Skill Audits"

  SKILL_REPORT_DIR="reports/skill-audits"
  mkdir -p "$SKILL_REPORT_DIR"

  echo -e "  ${CYAN}Running 6 parallel skill audits on $PLUGIN_PATH...${NC}"
  echo -e "  ${CYAN}This takes 3-6 minutes. Reports stream to $SKILL_REPORT_DIR/\n${NC}"

  # 1. WP Standards (uses /orbit-wp-standards — review-focused, not scaffolding)
  claude "/orbit-wp-standards
You are performing a WordPress plugin code standards review — NOT generating new code.
Read and analyze the WordPress plugin at: $PLUGIN_PATH
Check: text domain consistency, nonce field naming, prefix collision risk, enqueue hook timing,
sanitize-on-input + escape-on-output rule, activation hook safety, capability checks on all admin actions,
i18n wrapping completeness, no direct DB queries without \$wpdb, plugin header completeness.
Rate each finding Critical / High / Medium / Low. List all issues with file:line references.
Output a full markdown report with a severity summary table at the top." \
    > "$SKILL_REPORT_DIR/wp-standards.md" 2>"$SKILL_REPORT_DIR/wp-standards.err" &
  PID_WP=$!

  # 2. Security — PHP SOURCE CODE review (NOT a live attack tool)
  # Uses our custom /orbit-wp-security skill which covers 13 WP-specific vuln patterns.
  # DO NOT use /wordpress-penetration-testing here — that is an attacker tool for live sites
  claude "/orbit-wp-security
You are performing a static security code review of a WordPress plugin — NOT scanning a live URL.
Read the PHP source code at: $PLUGIN_PATH
Check these WordPress-specific vulnerability patterns:
1. is_admin() misuse — returns true for unauthenticated admin-ajax.php requests
2. Conditional nonce bypass — if (isset(\$_POST['nonce']) && !wp_verify_nonce()) pattern
3. Shortcode attribute XSS — wp_kses_post() does NOT sanitize shortcode attributes
4. ORDER BY / LIMIT SQL injection — \$wpdb->prepare() cannot parameterize these clauses
5. PHP Object Injection via unserialize() with DB-sourced data
6. wp_ajax_nopriv_ + update_option() = unauthenticated site takeover
7. Privilege escalation via unrestricted update_user_meta()
8. REST API IDOR — permission_callback present but no object ownership check
9. Missing output escaping before echo/print
10. Capability checks missing on AJAX handlers
Rate each finding Critical / High / Medium / Low with file:line references.
Output a full markdown report with a severity summary table at the top." \
    > "$SKILL_REPORT_DIR/security.md" 2>"$SKILL_REPORT_DIR/security.err" &
  PID_SEC=$!

  # 3. WP-Specific Performance (uses /orbit-wp-performance — WP hook system, not cloud infra)
  # DO NOT use /performance-engineer — that is a Kubernetes/Prometheus cloud skill
  claude "/orbit-wp-performance
You are analyzing WordPress plugin performance by reading PHP source code.
Analyze the plugin at: $PLUGIN_PATH
Check these WordPress-specific performance patterns:
1. Hooks running on every page load vs conditional (is_admin, is_singular, etc.)
2. N+1 DB queries — WP_Query or get_posts() inside foreach loops
3. get_option() or get_post_meta() called in loops without caching
4. Assets (scripts/styles) enqueued globally instead of page-specific
5. Autoload option bloat — large arrays stored with autoload=yes
6. Transient misuse — setting transients on every page request
7. Direct \$wpdb queries where WP API functions would be more efficient
8. Missing wp_cache_* usage for expensive operations
9. Blocking synchronous HTTP requests on the critical path
10. Missing object caching layer (wp_cache_get before expensive queries)
Rate all issues by frontend and admin impact. Include before/after code examples.
Output a full markdown report with a severity summary table at the top." \
    > "$SKILL_REPORT_DIR/performance.md" 2>"$SKILL_REPORT_DIR/performance.err" &
  PID_PERF=$!

  # 4. WP-Specific Database Review (uses /orbit-wp-database — $wpdb patterns, not enterprise DBA)
  # DO NOT use community /database-optimizer — that is a PostgreSQL/DynamoDB enterprise skill
  claude "/orbit-wp-database
You are reviewing WordPress plugin database usage by reading PHP source code.
Review all database usage in the WordPress plugin at: $PLUGIN_PATH
Check these WordPress/MySQL specific patterns:
1. \$wpdb->prepare() on ALL user-controlled input including ORDER BY/LIMIT clauses
2. Custom tables use dbDelta() not raw CREATE TABLE (uppercase column types, two-space PRIMARY KEY)
3. Large options stored with autoload = 'no'
4. Transient expiry set appropriately (not zero = never expires)
5. get_post_meta() with single=true to avoid array wrapping bugs
6. Missing indexes on custom table columns used in WHERE clauses
7. uninstall.php drops custom tables and deletes all options/transients
8. No direct wpdb queries where WP_Query or get_posts() would work
9. SQL LIKE queries with proper esc_like() escaping
10. No unbounded queries (posts_per_page = -1 without scale justification)
List every fix with corrected code examples where applicable.
Output a full markdown report with a severity summary table at the top." \
    > "$SKILL_REPORT_DIR/database.md" 2>"$SKILL_REPORT_DIR/database.err" &
  PID_DB=$!

  # 5. Accessibility (WCAG 2.2 AA)
  claude "/accessibility-compliance-accessibility-audit
Audit the WordPress plugin at: $PLUGIN_PATH for accessibility compliance.
Check: admin UI keyboard navigation, ARIA roles/labels, color contrast, focus management, screen reader output, block editor output.
Standard: WCAG 2.2 AA. Rate each issue Critical / High / Medium / Low.
Also check: focus trap in modals, Tab order for settings pages, missing form labels, no aria-hidden on interactive elements.
Output a full markdown report with a severity summary table at the top." \
    > "$SKILL_REPORT_DIR/accessibility.md" 2>"$SKILL_REPORT_DIR/accessibility.err" &
  PID_A11Y=$!

  # 6. Code Quality — includes AI-generated code risk detection
  claude "/vibe-code-auditor
Review the code quality of the WordPress plugin at: $PLUGIN_PATH
Check: dead code, cyclomatic complexity, error handling gaps, type safety, readability, PHP 8.x compatibility.
Additionally check for AI-generated code risks: hallucinated WordPress functions, incorrect hook signatures,
wrong return types from WP API functions, missing error handling on wp_remote_get() responses,
silently-failing patterns (no return value check, no is_wp_error() check).
Rate each issue High / Medium / Low. Include refactor suggestions.
Output a full markdown report with a severity summary table at the top." \
    > "$SKILL_REPORT_DIR/code-quality.md" 2>"$SKILL_REPORT_DIR/code-quality.err" &
  PID_CQ=$!

  # Wait for each individually + capture exit codes (wait $p1 $p2... returns last only)
  FAILED_SKILLS=""
  for pair in "WP:$PID_WP:wp-standards" "SEC:$PID_SEC:security" "PERF:$PID_PERF:performance" \
              "DB:$PID_DB:database" "A11Y:$PID_A11Y:accessibility" "CQ:$PID_CQ:code-quality"; do
    IFS=':' read -r label pid fname <<< "$pair"
    wait "$pid" 2>/dev/null
    rc=$?
    # Treat as failure if exit != 0 OR output file is empty/missing
    if [ "$rc" -ne 0 ] || [ ! -s "$SKILL_REPORT_DIR/${fname}.md" ]; then
      FAILED_SKILLS="$FAILED_SKILLS $label(rc=$rc)"
      # Show stderr if populated
      if [ -s "$SKILL_REPORT_DIR/${fname}.err" ]; then
        echo "  [${label}] error output:"
        head -3 "$SKILL_REPORT_DIR/${fname}.err" | sed 's/^/    /'
      fi
    fi
  done
  if [ -n "$FAILED_SKILLS" ]; then
    warn "Some skill audits failed:$FAILED_SKILLS"
    log "- ⚠ Failed skill audits:$FAILED_SKILLS"
  fi

  # Report results
  SKILL_FILES=$(ls "$SKILL_REPORT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  SKILL_HTML="$SKILL_REPORT_DIR/index.html"

  if [ "$SKILL_FILES" -gt 0 ]; then
    ok "Skill audits complete — $SKILL_FILES reports written"
    log "- ✓ Skill audits: $SKILL_FILES markdown reports in $SKILL_REPORT_DIR/"
    ((PASS++))

    # ── Generate consolidated HTML report ─────────────────────────────────────
    python3 - <<PYEOF
import os, re, html, datetime

skill_dir = "$SKILL_REPORT_DIR"
plugin_name = "$PLUGIN_NAME"
timestamp_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

# Map filename → display label
skill_labels = {
    "wp-standards.md":   ("WP Standards",  "#3b82f6"),
    "security.md":       ("Security",      "#ef4444"),
    "performance.md":    ("Performance",   "#f59e0b"),
    "database.md":       ("Database",      "#8b5cf6"),
    "accessibility.md":  ("Accessibility", "#10b981"),
    "code-quality.md":   ("Code Quality",  "#6366f1"),
}

sev_pat = re.compile(r'\b(Critical|High|Medium|Low)\b', re.IGNORECASE)
sev_colors = {"critical":"#ef4444","high":"#f97316","medium":"#eab308","low":"#22c55e"}

def md_to_html(text):
    """Minimal markdown → HTML: headers, bold, code, hr, lists, severity badges."""
    lines = text.split('\n')
    out = []
    in_code = False
    in_table = False
    for line in lines:
        # Fenced code blocks
        if line.strip().startswith('```'):
            if in_code:
                out.append('</code></pre>')
                in_code = False
            else:
                lang = line.strip()[3:].strip()
                out.append(f'<pre><code class="lang-{html.escape(lang)}">')
                in_code = True
            continue
        if in_code:
            out.append(html.escape(line))
            continue
        # Table detection
        if '|' in line and line.strip().startswith('|'):
            if not in_table:
                out.append('<table>')
                in_table = True
            cells = [c.strip() for c in line.strip().strip('|').split('|')]
            if all(re.match(r'^[-: ]+$', c) for c in cells):
                continue  # separator row
            tag = 'th' if not any(out[-1].startswith('<tr') for _ in [1]) else 'td'
            out.append('<tr>' + ''.join(f'<td>{html.escape(c)}</td>' for c in cells) + '</tr>')
            continue
        elif in_table:
            out.append('</table>')
            in_table = False
        # Headers
        m = re.match(r'^(#{1,6})\s+(.*)', line)
        if m:
            lvl = len(m.group(1))
            txt = html.escape(m.group(2))
            out.append(f'<h{lvl}>{txt}</h{lvl}>')
            continue
        # HR
        if re.match(r'^---+$', line.strip()):
            out.append('<hr>')
            continue
        # List items
        m2 = re.match(r'^(\s*[-*+]|\s*\d+\.)\s+(.*)', line)
        if m2:
            txt = html.escape(m2.group(2))
            txt = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', txt)
            txt = re.sub(r'`(.*?)`', r'<code>\1</code>', txt)
            # Severity badge
            def badge(m):
                sev = m.group(1).lower()
                col = sev_colors.get(sev, "#888")
                return f'<span class="badge" style="background:{col}">{m.group(1)}</span>'
            txt = sev_pat.sub(badge, txt)
            out.append(f'<li>{txt}</li>')
            continue
        # Paragraph
        if line.strip():
            txt = html.escape(line)
            txt = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', txt)
            txt = re.sub(r'`(.*?)`', r'<code>\1</code>', txt)
            def badge(m):
                sev = m.group(1).lower()
                col = sev_colors.get(sev, "#888")
                return f'<span class="badge" style="background:{col}">{m.group(1)}</span>'
            txt = sev_pat.sub(badge, txt)
            out.append(f'<p>{txt}</p>')
        else:
            out.append('')
    if in_code:
        out.append('</code></pre>')
    if in_table:
        out.append('</table>')
    return '\n'.join(out)

# Count severity totals across all files
total_counts = {"critical":0,"high":0,"medium":0,"low":0}
sections = []
for fname, (label, color) in skill_labels.items():
    fpath = os.path.join(skill_dir, fname)
    if not os.path.exists(fpath):
        continue
    with open(fpath) as f:
        content = f.read()
    for sev in total_counts:
        total_counts[sev] += len(re.findall(sev, content, re.IGNORECASE))
    body_html = md_to_html(content)
    sections.append((label, color, fname, body_html))

# Build nav tabs
nav = ''.join(
    f'<button class="tab-btn" data-target="tab-{i}" style="border-top:3px solid {color}">{label}</button>'
    for i, (label, color, _, _) in enumerate(sections)
)

# Build tab panels
panels = ''.join(
    f'<div class="tab-panel" id="tab-{i}"><div class="skill-body">{body}</div></div>'
    for i, (_, _, _, body) in enumerate(sections)
)

sev_bar = ''.join(
    f'<span class="sev-chip" style="background:{sev_colors[s]}">{total_counts[s]} {s.title()}</span>'
    for s in ["critical","high","medium","low"]
)

html_out = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Orbit Skill Audit — {html.escape(plugin_name)}</title>
<style>
  *{{box-sizing:border-box;margin:0;padding:0}}
  body{{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#0f172a;color:#e2e8f0;line-height:1.6}}
  header{{background:#1e293b;padding:20px 32px;border-bottom:1px solid #334155}}
  header h1{{font-size:1.4rem;font-weight:700;color:#f8fafc}}
  header p{{color:#94a3b8;font-size:.875rem;margin-top:4px}}
  .sev-bar{{display:flex;gap:8px;margin-top:12px;flex-wrap:wrap}}
  .sev-chip{{padding:3px 10px;border-radius:999px;font-size:.75rem;font-weight:600;color:#fff}}
  .tabs{{display:flex;gap:0;overflow-x:auto;background:#1e293b;border-bottom:1px solid #334155;padding:0 32px}}
  .tab-btn{{padding:12px 18px;background:none;border:none;border-top:3px solid transparent;color:#94a3b8;cursor:pointer;font-size:.85rem;font-weight:500;white-space:nowrap;transition:color .15s}}
  .tab-btn:hover,.tab-btn.active{{color:#f8fafc}}
  .tab-btn.active{{background:#0f172a}}
  .tab-panel{{display:none;padding:32px;max-width:1200px;margin:0 auto}}
  .tab-panel.active{{display:block}}
  .skill-body h1{{font-size:1.5rem;margin:24px 0 8px;color:#f8fafc}}
  .skill-body h2{{font-size:1.2rem;margin:20px 0 8px;color:#e2e8f0;padding-bottom:4px;border-bottom:1px solid #334155}}
  .skill-body h3{{font-size:1rem;margin:16px 0 6px;color:#cbd5e1}}
  .skill-body h4,.skill-body h5,.skill-body h6{{margin:12px 0 4px;color:#94a3b8}}
  .skill-body p{{margin:8px 0;color:#cbd5e1}}
  .skill-body li{{margin:4px 0 4px 20px;color:#cbd5e1}}
  .skill-body pre{{background:#1e293b;border:1px solid #334155;border-radius:6px;padding:16px;overflow-x:auto;margin:12px 0}}
  .skill-body code{{font-family:'JetBrains Mono',monospace;font-size:.82rem;color:#7dd3fc}}
  .skill-body p code,.skill-body li code{{background:#1e293b;padding:1px 5px;border-radius:3px;color:#7dd3fc}}
  .skill-body hr{{border:none;border-top:1px solid #334155;margin:20px 0}}
  .skill-body strong{{color:#f8fafc}}
  .skill-body table{{width:100%;border-collapse:collapse;margin:12px 0;font-size:.85rem}}
  .skill-body td,.skill-body th{{border:1px solid #334155;padding:8px 12px;text-align:left}}
  .skill-body th{{background:#1e293b;color:#f8fafc;font-weight:600}}
  .skill-body tr:nth-child(even){{background:#1a2744}}
  .badge{{padding:1px 8px;border-radius:999px;font-size:.72rem;font-weight:700;color:#fff}}
  footer{{text-align:center;padding:24px;color:#475569;font-size:.8rem;border-top:1px solid #1e293b}}
</style>
</head>
<body>
<header>
  <h1>Orbit Skill Audit Report</h1>
  <p>Plugin: <strong>{html.escape(plugin_name)}</strong> &nbsp;·&nbsp; Generated: {timestamp_str} &nbsp;·&nbsp; {len(sections)} skills run</p>
  <div class="sev-bar">{sev_bar}</div>
</header>
<div class="tabs">{nav}</div>
<div class="panels">{panels}</div>
<footer>Generated by <strong>Orbit</strong> — WordPress Plugin QA Framework</footer>
<script>
  const btns = document.querySelectorAll('.tab-btn');
  const panels = document.querySelectorAll('.tab-panel');
  function activate(i) {{
    btns.forEach((b,j) => b.classList.toggle('active', i===j));
    panels.forEach((p,j) => p.classList.toggle('active', i===j));
  }}
  btns.forEach((b,i) => b.addEventListener('click', () => activate(i)));
  activate(0);
</script>
</body>
</html>"""

with open("$SKILL_HTML", "w") as f:
    f.write(html_out)
print("HTML report written.")
PYEOF

    if [ -f "$SKILL_HTML" ]; then
      ok "Skill audit HTML report: $SKILL_HTML"
      log "- ✓ Skill audit HTML: $SKILL_HTML"
      echo -e "  ${CYAN}Open:${NC} open $(pwd)/$SKILL_HTML"
    else
      warn "HTML generation failed — markdown reports still available in $SKILL_REPORT_DIR/"
      log "- ⚠ Skill audit HTML: generation failed (markdown reports available)"
    fi

    # Surface critical findings
    CRIT=$(grep -rl "Critical\|CRITICAL" "$SKILL_REPORT_DIR/"*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CRIT" -gt 0 ]; then
      warn "Critical findings found — review $SKILL_REPORT_DIR/security.md before release"
      log "- ⚠ Critical findings in $CRIT skill report(s)"
      ((WARN++))
    fi
  else
    warn "Skill audits produced no output — run manually: claude '/wordpress-penetration-testing Audit $PLUGIN_PATH'"
    log "- ⚠ Skill audits: no output"
    ((WARN++))
  fi
elif [ "$MODE" = "full" ] && [ -n "$PLUGIN_PATH" ]; then
  echo -e "  ${YELLOW}Skill audits: claude CLI not found. Install: npm install -g @anthropic-ai/claude-code${NC}"
  echo -e "  ${YELLOW}Re-run gauntlet after install for all 6 automated skill audits.${NC}"
fi

# ── STEP 12: PM UX AUDIT (spell-check + guided UX + label audit) ──────────────
# Runs in full mode only. Never hard-blocks a release — everything is WARN.
# PM reads reports/pm-ux/pm-ux-report-*.html and decides.
if [ "$MODE" = "full" ] && [ "$ENV" = "local" ] && command -v npx &>/dev/null; then
  header "Step 12: PM UX Audit"
  log "## Step 12: PM UX Audit"

  ADMIN_SLUG=$(python3 -c "import json; print(json.load(open('qa.config.json'))['plugin'].get('admin_slug',''))" 2>/dev/null || echo "")

  PM_UX_OUT=$(WP_TEST_URL="${WP_TEST_URL:-http://localhost:8881}" \
    PLUGIN_ADMIN_SLUG="$ADMIN_SLUG" \
    bash scripts/pm-ux-audit.sh 2>&1 || true)
  echo "$PM_UX_OUT" | tail -20

  PM_UX_REPORT=$(ls reports/pm-ux/pm-ux-report-*.html 2>/dev/null | sort | tail -1 || echo "")

  # Read scores from JSON
  TYPOS=$(python3 -c "import json; d=json.load(open('reports/pm-ux/spell-check-findings.json')); print(len(d.get('findings',[])))" 2>/dev/null || echo "?")
  GUIDED=$(python3 -c "import json; print(json.load(open('reports/pm-ux/guided-ux-score.json'))['score'])" 2>/dev/null || echo "?")
  LABELS=$(python3 -c "import json; print(json.load(open('reports/pm-ux/label-audit-findings.json'))['summary']['total'])" 2>/dev/null || echo "?")

  PM_ISSUES=0
  [ "$TYPOS" != "?" ] && [ "$TYPOS" -gt 0 ] && { warn "Spell-check: $TYPOS typo(s) in UI text"; log "- ⚠ Spell-check: $TYPOS typos"; ((WARN++)); PM_ISSUES=$((PM_ISSUES+1)); } || ok "Spell-check: clean"
  [ "$GUIDED" != "?" ] && [ "$GUIDED" -lt 6 ]  && { warn "Guided UX score: $GUIDED/10 — below competitor avg"; log "- ⚠ Guided UX: $GUIDED/10"; ((WARN++)); PM_ISSUES=$((PM_ISSUES+1)); } || ok "Guided UX: $GUIDED/10"
  [ "$LABELS" != "?" ] && [ "$LABELS" -gt 0 ]  && { warn "Label audit: $LABELS issue(s) vs industry standards"; log "- ⚠ Labels: $LABELS issues"; ((WARN++)); PM_ISSUES=$((PM_ISSUES+1)); } || ok "Labels: industry standard"

  if [ -n "$PM_UX_REPORT" ]; then
    ok "PM UX report: $PM_UX_REPORT"
    log "- ✓ PM UX report: $PM_UX_REPORT"
    echo -e "  ${CYAN}Open:${NC} open $(pwd)/$PM_UX_REPORT"
  fi

  [ "$PM_ISSUES" -eq 0 ] && { ok "PM UX Audit — all clear"; log "- ✓ PM UX: all clear"; ((PASS++)); }
fi

# ── FINAL REPORT ──────────────────────────────────────────────────────────────
header "Results"
log "---"
log "## Summary"
log "- ✓ Passed: $PASS"
log "- ⚠ Warnings: $WARN"
log "- ✗ Failed: $FAIL"

echo ""
echo "================================="
echo -e "${BOLD}Results${NC}: ${GREEN}$PASS passed${NC} | ${YELLOW}$WARN warnings${NC} | ${RED}$FAIL failed${NC}"
echo ""
# Auto-generate UAT HTML report if flow screenshots exist
if [ -d "reports/screenshots/flows-compare" ] && ls reports/screenshots/flows-compare/*.png &>/dev/null; then
  UAT_HTML="reports/uat-compare-$TIMESTAMP.html"
  python3 scripts/generate-uat-report.py \
    --title "UAT Flow Report — $(date +%Y-%m-%d)" \
    --out "$UAT_HTML" \
    --snaps "reports/screenshots/flows-compare" \
    --videos "reports/videos" 2>/dev/null && {
    ok "UAT HTML report generated: $UAT_HTML"
  } || true
fi

echo -e "${BOLD}Reports generated:${NC}"
echo "  MD report:       $(pwd)/$REPORT_FILE"
echo "  Playwright:      $(pwd)/reports/playwright-html/index.html"
echo "  Screenshots:     $(pwd)/reports/screenshots/"
echo "  Videos:          $(pwd)/reports/videos/"
[ -f "reports/skill-audits/index.html" ] && echo "  Skill audits:    $(pwd)/reports/skill-audits/index.html"
for f in reports/uat-report-*.html; do [ -f "$f" ] && echo "  UAT report:      $(pwd)/$f"; done
for f in reports/pm-ux/pm-ux-report-*.html; do [ -f "$f" ] && echo "  PM UX report:    $(pwd)/$f"; done
for f in reports/pm-ux/*.json; do [ -f "$f" ] && echo "  PM/GDPR flows:   $(pwd)/$f" && break; done
for f in reports/lighthouse/attribution-*.md; do [ -f "$f" ] && echo "  LH attribution:  $(pwd)/$f" && break; done
for f in reports/competitor-vulns-*.md; do [ -f "$f" ] && echo "  CVE intel:       $(pwd)/$f" && break; done
echo ""
echo -e "${CYAN}View Playwright:${NC}   npx playwright show-report reports/playwright-html"
echo -e "${CYAN}View skill audits:${NC} open reports/skill-audits/index.html"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}✗ GAUNTLET FAILED — do not release${NC}"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo -e "${YELLOW}⚠ GAUNTLET PASSED WITH WARNINGS — review before release${NC}"
  exit 0
else
  echo -e "${GREEN}✓ GAUNTLET PASSED — ready to release${NC}"
  exit 0
fi
