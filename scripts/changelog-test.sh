#!/usr/bin/env bash
# Changelog-Based Test Suggester
# Reads CHANGELOG.md from a plugin, maps each change to a targeted test
# Usage: bash scripts/changelog-test.sh --changelog /path/to/CHANGELOG.md [--version 2.4.0]

set -e

CHANGELOG=""
VERSION=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --changelog) CHANGELOG="$2"; shift ;;
    --version)   VERSION="$2"; shift ;;
  esac
  shift
done

[ -z "$CHANGELOG" ] && { echo "Usage: $0 --changelog /path/to/CHANGELOG.md [--version X.Y.Z]"; exit 1; }
[ ! -f "$CHANGELOG" ] && { echo "Changelog not found: $CHANGELOG"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${BOLD}Changelog-Based Test Planner${NC}"
echo "Changelog: $CHANGELOG"
echo "============================================"

# Extract the latest version section if no version specified
if [ -z "$VERSION" ]; then
  VERSION=$(grep -oP '(?<=## \[)\d+\.\d+\.\d+' "$CHANGELOG" | head -1)
  echo "Latest version detected: $VERSION"
fi

# Extract the changelog section for this version
SECTION=$(awk "/## \[$VERSION\]/,/## \[/" "$CHANGELOG" 2>/dev/null | head -50)
if [ -z "$SECTION" ]; then
  # Try without brackets
  SECTION=$(awk "/## $VERSION/,/## /" "$CHANGELOG" 2>/dev/null | head -50)
fi

if [ -z "$SECTION" ]; then
  echo "Could not find version $VERSION in changelog."
  echo "Available versions:"
  grep -oP '(?<=## \[)\d+\.\d+\.\d+' "$CHANGELOG" | head -10
  exit 1
fi

echo ""
echo -e "${BOLD}Changes in v$VERSION:${NC}"
echo "$SECTION"
echo ""
echo "============================================"
echo -e "${BOLD}Suggested Tests:${NC}"
echo ""

# Map change keywords to test suggestions
while IFS= read -r line; do
  line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')

  # New widget/block/feature
  if echo "$line_lower" | grep -qE "add(ed)?.*widget|add(ed)?.*block|new.*widget|new.*block"; then
    WIDGET=$(echo "$line" | grep -oP '(?<=[Aa]dded? )[A-Za-z\s]+(?= (widget|block))' | head -1)
    echo -e "${GREEN}[NEW FEATURE]${NC} $line"
    echo "  → Test: Create a test page with the $WIDGET widget → verify it renders on frontend"
    echo "  → Test: Open Elementor editor → search for '$WIDGET' → verify it appears in panel"
    echo "  → Add: tests/playwright/tpa/${WIDGET// /-}.spec.js"
    echo ""
  fi

  # Performance fix
  if echo "$line_lower" | grep -qE "performance|speed|slow|query|cache|optimi"; then
    echo -e "${YELLOW}[PERFORMANCE]${NC} $line"
    echo "  → Run: bash scripts/db-profile.sh and compare query count to previous version"
    echo "  → Run: lighthouse \$WP_TEST_URL and compare performance score"
    echo "  → Check: bundle size didn't grow (scripts/compare-versions.sh)"
    echo ""
  fi

  # Security fix
  if echo "$line_lower" | grep -qE "security|xss|csrf|nonce|sanitiz|escap|capabilit|vulnerab"; then
    echo -e "${RED:-\033[0;31m}[SECURITY]${NC} $line"
    echo "  → Run: /wordpress-penetration-testing on the affected file"
    echo "  → Run: phpcs --standard=config/phpcs.xml on changed files"
    echo "  → Verify: the specific vulnerability is no longer exploitable"
    echo ""
  fi

  # Bug fix
  if echo "$line_lower" | grep -qE "fix(ed)?|bug|broken|crash|fatal|error|resolv"; then
    FEATURE=$(echo "$line" | sed 's/.*[Ff]ix[ed]* *//' | cut -c1-60)
    echo -e "${GREEN}[BUG FIX]${NC} $line"
    echo "  → Test: Reproduce the original bug scenario → verify it no longer occurs"
    echo "  → Add regression test: tests/playwright/tpa/regression.spec.js"
    echo "  → Check: PHP lint passes, no new fatal errors"
    echo ""
  fi

  # Admin / settings change
  if echo "$line_lower" | grep -qE "admin|setting|option|dashboard|panel"; then
    echo -e "${YELLOW}[ADMIN CHANGE]${NC} $line"
    echo "  → Test: Visit admin panel → verify change is visible and works"
    echo "  → Test: Save settings → verify data persists after page reload"
    echo "  → Test: No PHP errors in admin with WP_DEBUG=true"
    echo ""
  fi

  # Elementor-specific
  if echo "$line_lower" | grep -qE "elementor|editor|widget panel"; then
    echo -e "${GREEN}[ELEMENTOR]${NC} $line"
    echo "  → Test: Open Elementor editor → verify change works as expected"
    echo "  → Test: Publish page with affected widget → verify frontend renders correctly"
    echo "  → Visual: Update screenshot baseline for affected widget"
    echo ""
  fi

  # Gutenberg/blocks
  if echo "$line_lower" | grep -qE "block|gutenberg|fse|full.site|template"; then
    echo -e "${GREEN}[GUTENBERG]${NC} $line"
    echo "  → Test: Open block editor → verify block appears and functions"
    echo "  → Test: Save and reload page → block renders correctly on frontend"
    echo "  → Test: block.json updated if attributes changed"
    echo ""
  fi

  # WooCommerce/EDD
  if echo "$line_lower" | grep -qE "woocommerce|woo|edd|store|product|cart|checkout"; then
    echo -e "${YELLOW}[ECOMMERCE]${NC} $line"
    echo "  → Test: WooCommerce compatibility — key store pages render correctly"
    echo "  → Test: No conflicts with WC hooks on affected pages"
    echo ""
  fi

  # i18n / translation
  if echo "$line_lower" | grep -qE "translat|i18n|l10n|pot|language|locale"; then
    echo -e "${GREEN}[I18N]${NC} $line"
    echo "  → Run: wp i18n make-pot . languages/plugin.pot"
    echo "  → Check: All new strings are wrapped in __() or esc_html__()"
    echo "  → Verify: .pot file updated and committed"
    echo ""
  fi

  # Deprecation / removal
  if echo "$line_lower" | grep -qE "deprecat|remov(ed)?|drop(ped)?"; then
    echo -e "${YELLOW}[BREAKING/DEPRECATION]${NC} $line"
    echo "  → Test: Sites using the removed feature still work (graceful fallback)"
    echo "  → Check: Deprecation notice added if applicable"
    echo "  → Update: CHANGELOG with migration instructions for users"
    echo ""
  fi

done <<< "$SECTION"

echo "============================================"
echo ""
echo -e "${BOLD}Quick Commands to Run:${NC}"
echo ""
echo "  # Code check on changed files"
echo "  phpcs --standard=config/phpcs.xml /path/to/plugin"
echo ""
echo "  # DB regression check"
echo "  bash scripts/db-profile.sh"
echo ""
echo "  # Full version comparison"
echo "  bash scripts/compare-versions.sh --old plugin-old.zip --new plugin-new.zip"
echo ""
echo "  # Run Playwright for affected areas"
echo "  WP_TEST_URL=\$WP_TPA_URL npx playwright test tests/playwright/tpa/"
echo ""
