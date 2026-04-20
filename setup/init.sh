#!/usr/bin/env bash
# PlugOrbit — Interactive First-Run Setup
# Creates qa.config.json tailored to your plugin type
# Usage: bash setup/init.sh

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

clear
echo ""
echo -e "${BOLD}${CYAN}"
echo "  ██████╗ ██╗     ██╗   ██╗ ██████╗ ██████╗ ██████╗ ██████╗ ██╗████████╗"
echo "  ██╔══██╗██║     ██║   ██║██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║╚══██╔══╝"
echo "  ██████╔╝██║     ██║   ██║██║  ███╗██║   ██║██████╔╝██████╔╝██║   ██║   "
echo "  ██╔═══╝ ██║     ██║   ██║██║   ██║██║   ██║██╔══██╗██╔══██╗██║   ██║   "
echo "  ██║     ███████╗╚██████╔╝╚██████╔╝╚██████╔╝██║  ██║██████╔╝██║   ██║   "
echo "  ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝   ╚═╝  "
echo -e "${NC}"
echo -e "${BOLD}  WordPress Plugin QA — Intelligent Setup${NC}"
echo "  ─────────────────────────────────────────"
echo ""
echo "  I'll ask a few questions to configure your QA pipeline."
echo "  This creates qa.config.json — everything adapts to your plugin type."
echo ""

# ── Plugin Name ───────────────────────────────────────────────────────────────
echo -e "${YELLOW}Q1. What is your plugin name?${NC}"
read -r -p "  Plugin name: " PLUGIN_NAME
echo ""

# ── Plugin Slug ───────────────────────────────────────────────────────────────
PLUGIN_SLUG=$(echo "$PLUGIN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
read -r -p "  Plugin slug (folder name) [$PLUGIN_SLUG]: " SLUG_INPUT
PLUGIN_SLUG="${SLUG_INPUT:-$PLUGIN_SLUG}"
echo ""

# ── Plugin Type ───────────────────────────────────────────────────────────────
echo -e "${YELLOW}Q2. What type of plugin is this?${NC}"
echo "   1) Elementor Addon (widget/extension for Elementor)"
echo "   2) Gutenberg Blocks Plugin"
echo "   3) WordPress Theme"
echo "   4) SEO Plugin"
echo "   5) WooCommerce Extension"
echo "   6) General WordPress Plugin"
echo "   7) Page Builder (Beaver, Divi, etc.)"
read -r -p "  Choose [1-7]: " PLUGIN_TYPE_NUM

case $PLUGIN_TYPE_NUM in
  1) PLUGIN_TYPE="elementor-addon" ;;
  2) PLUGIN_TYPE="gutenberg-blocks" ;;
  3) PLUGIN_TYPE="theme" ;;
  4) PLUGIN_TYPE="seo-plugin" ;;
  5) PLUGIN_TYPE="woocommerce-extension" ;;
  6) PLUGIN_TYPE="general" ;;
  7) PLUGIN_TYPE="page-builder" ;;
  *) PLUGIN_TYPE="general" ;;
esac
echo ""

# ── Plugin Path ───────────────────────────────────────────────────────────────
echo -e "${YELLOW}Q3. Where is your plugin source code?${NC}"
DEFAULT_PATH="$HOME/plugins/$PLUGIN_SLUG"
read -r -p "  Plugin path [$DEFAULT_PATH]: " PLUGIN_PATH_INPUT
PLUGIN_PATH="${PLUGIN_PATH_INPUT:-$DEFAULT_PATH}"
echo ""

# ── Local WP Site URL ─────────────────────────────────────────────────────────
echo -e "${YELLOW}Q4. What is your Local WP test site URL?${NC}"
DEFAULT_URL="http://$PLUGIN_SLUG-test.local"
read -r -p "  Test site URL [$DEFAULT_URL]: " WP_URL_INPUT
WP_URL="${WP_URL_INPUT:-$DEFAULT_URL}"
echo ""

# ── Local WP Path ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}Q5. What is the Local WP site path (WordPress root)?${NC}"
DEFAULT_WP_PATH="$HOME/Local Sites/$PLUGIN_SLUG-test/app/public"
read -r -p "  WP path [$DEFAULT_WP_PATH]: " WP_PATH_INPUT
WP_PATH="${WP_PATH_INPUT:-$DEFAULT_WP_PATH}"
echo ""

# ── Competitors ───────────────────────────────────────────────────────────────
echo -e "${YELLOW}Q6. Who are your top competitors? (comma-separated wordpress.org slugs)${NC}"
echo "   Example: elementor,wpbakery,divi"
case $PLUGIN_TYPE in
  elementor-addon)   COMPETITOR_HINT="essential-addons-for-elementor-free,premium-addons-for-elementor" ;;
  gutenberg-blocks)  COMPETITOR_HINT="ultimate-blocks,kadence-blocks,spectra" ;;
  seo-plugin)        COMPETITOR_HINT="wordpress-seo,all-in-one-seo-pack,rankmath-seo" ;;
  woocommerce-extension) COMPETITOR_HINT="woocommerce,automatewoo,yith-woocommerce-wishlist" ;;
  theme)             COMPETITOR_HINT="astra,generatepress,hello-elementor" ;;
  *)                 COMPETITOR_HINT="" ;;
esac
[ -n "$COMPETITOR_HINT" ] && echo -e "   Suggested: ${CYAN}$COMPETITOR_HINT${NC}"
read -r -p "  Competitors: " COMPETITORS
echo ""

# ── Pro Version ───────────────────────────────────────────────────────────────
echo -e "${YELLOW}Q7. Do you have a Pro version to compare against Free?${NC}"
read -r -p "  Has Pro version? [y/N]: " HAS_PRO_INPUT
HAS_PRO="false"
PRO_ZIP=""
if [[ "$HAS_PRO_INPUT" =~ ^[Yy] ]]; then
  HAS_PRO="true"
  read -r -p "  Pro zip path (leave blank to set later): " PRO_ZIP_INPUT
  PRO_ZIP="${PRO_ZIP_INPUT:-}"
fi
echo ""

# ── Team Roles ────────────────────────────────────────────────────────────────
echo -e "${YELLOW}Q8. Who will use this pipeline? (select all that apply)${NC}"
echo "   d) Developers  q) QA testers  p) Product managers  a) All"
read -r -p "  Roles [a]: " ROLES_INPUT
ROLES="${ROLES_INPUT:-a}"
echo ""

# ── Notification ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}Q9. Slack webhook URL for test result notifications? (optional)${NC}"
read -r -p "  Slack webhook URL [skip]: " SLACK_WEBHOOK
echo ""

# ── Write config ─────────────────────────────────────────────────────────────
cat > qa.config.json << EOF
{
  "plugin": {
    "name": "$PLUGIN_NAME",
    "slug": "$PLUGIN_SLUG",
    "type": "$PLUGIN_TYPE",
    "path": "$PLUGIN_PATH",
    "hasPro": $HAS_PRO,
    "proZip": "$PRO_ZIP"
  },
  "environment": {
    "localWpUrl": "$WP_URL",
    "localWpPath": "$WP_PATH",
    "adminUser": "admin",
    "adminPass": "password"
  },
  "competitors": [$(echo "$COMPETITORS" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' | sed 's/.*/    "&"/' | paste -sd ',' -)
  ],
  "team": {
    "roles": "$ROLES",
    "slackWebhook": "$SLACK_WEBHOOK"
  },
  "thresholds": {
    "lighthouse": { "performance": 75, "accessibility": 85 },
    "dbQueriesPerPage": 60,
    "jsBundleKb": 500,
    "cssBundleKb": 200
  },
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# ── Type-specific Playwright config ──────────────────────────────────────────
case $PLUGIN_TYPE in
  elementor-addon)
    cat > .env.test << EOF
WP_TEST_URL=$WP_URL
WP_PATH=$WP_PATH
TPA_TEST_PAGE=/tpa-test/
PLUGIN_TYPE=elementor-addon
EOF
    ;;
  gutenberg-blocks)
    cat > .env.test << EOF
WP_TEST_URL=$WP_URL
WP_PATH=$WP_PATH
PLUGIN_TYPE=gutenberg-blocks
EOF
    ;;
  theme)
    cat > .env.test << EOF
WP_TEST_URL=$WP_URL
WP_PATH=$WP_PATH
PLUGIN_TYPE=theme
EOF
    ;;
esac

echo ""
echo "  ─────────────────────────────────────────"
echo -e "${GREEN}  Setup complete!${NC} Config saved to: qa.config.json"
echo ""
echo "  Next steps:"
echo ""

if [ "$PLUGIN_TYPE" = "elementor-addon" ] || [ "$PLUGIN_TYPE" = "gutenberg-blocks" ] || [ "$PLUGIN_TYPE" = "theme" ]; then
  echo "  1. Install Local WP: https://localwp.com (Local 9.x, choose arm64 for M1/M2/M3/M4 Mac)"
  echo "  2. Create site '$PLUGIN_SLUG-test' in Local WP (PHP 8.1, nginx, MySQL 8.0)"
  echo "  3. Install deps:  bash setup/install.sh"
  echo "  4. Run gauntlet:  bash scripts/gauntlet.sh --plugin $PLUGIN_PATH --env local"
fi

if [ -n "$COMPETITORS" ]; then
  echo ""
  echo "  Competitor analysis ready:"
  echo "  bash scripts/competitor-compare.sh"
fi

echo ""
echo "  Full docs: https://github.com/adityaarsharma/wordpress-qa-master"
echo ""
