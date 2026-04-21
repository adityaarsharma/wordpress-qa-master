#!/usr/bin/env bash
# Orbit — Zip Hygiene + Supply Chain + Forbidden Function Check
#
# Consolidates three P0 checks:
#   1. Dev artifacts present (.git, node_modules, tests/, .github, etc.)
#   2. composer.lock / package-lock.json vulnerabilities (via audit)
#   3. Forbidden PHP functions (eval, base64_decode, exec, system, passthru)
#
# These are the #1 reasons WordPress.org rejects plugins in 2025.
# Source: make.wordpress.org/plugins/2026/01/07/a-year-in-the-plugins-team-2025/

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

FAIL=0
WARN=0

echo -e "${CYAN}── Zip Hygiene ──${NC}"

# 1a. Dev directories that must not ship
# Expanded to match plugin-check `file_type` check + AI development artifacts (2026)
BAD_DIRS=(
  .git .github .gitlab .bitbucket .svn .hg
  node_modules tests test spec specs
  .vscode .idea .circleci .fleet .zed
  .cursor .aider .continue .claude .windsurf .codex
  .cache .parcel-cache .next .nuxt .turbo
)
for d in "${BAD_DIRS[@]}"; do
  if [ -d "$PLUGIN_PATH/$d" ]; then
    echo -e "${RED}✗ Dev directory shipped: $d/${NC}"
    FAIL=1
  fi
done

# 1b. Dev files that must not ship
BAD_FILES=(
  ".env" ".env.example" ".env.local" ".env.production"
  "composer.json" "composer.lock" "package.json" "package-lock.json" "yarn.lock" "pnpm-lock.yaml" "bun.lockb"
  "webpack.config.js" "rollup.config.js" "vite.config.js" "gulpfile.js" "Gruntfile.js" "esbuild.config.js"
  ".eslintrc" ".eslintrc.js" ".eslintrc.json" ".prettierrc" ".prettierrc.json" ".stylelintrc"
  ".gitignore" ".gitattributes" ".editorconfig" ".nvmrc" ".node-version"
  "phpcs.xml" "phpcs.xml.dist" "phpunit.xml" "phpunit.xml.dist" "phpstan.neon" "phpstan.neon.dist"
  "README.md" "CHANGELOG.md" "CONTRIBUTING.md" "CODE_OF_CONDUCT.md" "SECURITY.md"
  "Dockerfile" "docker-compose.yml" "docker-compose.yaml"
  "Makefile" "Procfile"
  # macOS / Windows / editor artifacts
  ".DS_Store" "Thumbs.db" "desktop.ini"
  # AI config files
  ".cursorrules" "CLAUDE.md" "AGENTS.md" ".aider.conf.yml" ".continuerc.json"
)
for f in "${BAD_FILES[@]}"; do
  if [ -f "$PLUGIN_PATH/$f" ]; then
    # Some files are OK if referenced from plugin main file — warn not fail
    case "$f" in
      composer.json|README.md|CHANGELOG.md)
        echo -e "${YELLOW}⚠ Dev file in production zip: $f${NC}"
        WARN=1
        ;;
      *)
        echo -e "${RED}✗ Dev file shipped: $f${NC}"
        FAIL=1
        ;;
    esac
  fi
done

# 1c. Source maps leak original code — never ship
SOURCE_MAPS=$(find "$PLUGIN_PATH" -name "*.map" -not -path "*/vendor/*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SOURCE_MAPS" -gt 0 ]; then
  echo -e "${RED}✗ $SOURCE_MAPS source map files (.map) shipped — reveals unminified source${NC}"
  find "$PLUGIN_PATH" -name "*.map" -not -path "*/vendor/*" | head -3
  FAIL=1
fi

# 1c-b. Editor backup / scratch files
BACKUPS=$(find "$PLUGIN_PATH" -type f \( -name "*.bak" -o -name "*.orig" -o -name "*.swp" -o -name "*.swo" -o -name "*~" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$BACKUPS" -gt 0 ]; then
  echo -e "${YELLOW}⚠ $BACKUPS editor backup files (.bak, .orig, .swp, ~) shipped${NC}"
  WARN=1
fi

# 1c-c. GitHub Copilot / IDE cache nested in any dir (not just root)
NESTED_AI=$(find "$PLUGIN_PATH" -type d \( -name "copilot-*" -o -name ".history" -o -name ".vscode-test" \) 2>/dev/null | head -5)
if [ -n "$NESTED_AI" ]; then
  echo -e "${YELLOW}⚠ AI/IDE cache dirs nested in plugin:${NC}"
  echo "$NESTED_AI" | head -3
  WARN=1
fi

# 1d. Zero-byte or suspiciously large files
HUGE=$(find "$PLUGIN_PATH" -type f -size +5M -not -path "*/vendor/*" 2>/dev/null)
if [ -n "$HUGE" ]; then
  echo -e "${YELLOW}⚠ Files over 5MB (consider compression or exclusion):${NC}"
  echo "$HUGE" | head -5
  WARN=1
fi

[ "$FAIL" -eq 0 ] && echo -e "${GREEN}✓ Zip hygiene clean${NC}"

echo ""
echo -e "${CYAN}── Supply Chain ──${NC}"

# 2a. composer audit
if [ -f "$PLUGIN_PATH/composer.lock" ] && command -v composer &>/dev/null; then
  AUDIT=$(cd "$PLUGIN_PATH" && composer audit --no-ansi --format=plain 2>&1 || true)
  VULN_COUNT=$(echo "$AUDIT" | grep -cE "(CVE-|security advisories)" 2>/dev/null || true)
  VULN_COUNT=${VULN_COUNT:-0}
  VULN_COUNT=$(echo "$VULN_COUNT" | head -1 | tr -dc '0-9')
  VULN_COUNT=${VULN_COUNT:-0}
  if [ "$VULN_COUNT" -gt 0 ]; then
    echo -e "${RED}✗ composer audit found $VULN_COUNT advisories${NC}"
    echo "$AUDIT" | head -20
    FAIL=1
  else
    echo -e "${GREEN}✓ composer audit clean${NC}"
  fi
else
  [ ! -f "$PLUGIN_PATH/composer.lock" ] && echo "  (no composer.lock — skipping composer audit)"
  [ -f "$PLUGIN_PATH/composer.lock" ] && ! command -v composer &>/dev/null && \
    echo -e "${YELLOW}⚠ composer not installed — can't audit${NC}"
fi

# 2b. npm audit
if [ -f "$PLUGIN_PATH/package-lock.json" ] && command -v npm &>/dev/null; then
  AUDIT_JSON=$(cd "$PLUGIN_PATH" && npm audit --json 2>/dev/null || echo '{}')
  HIGH=$(echo "$AUDIT_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); v=d.get('metadata',{}).get('vulnerabilities',{}); print(v.get('high',0)+v.get('critical',0))" 2>/dev/null || true)
  if [ "$HIGH" -gt 0 ]; then
    echo -e "${RED}✗ npm audit: $HIGH high/critical vulnerabilities${NC}"
    FAIL=1
  else
    echo -e "${GREEN}✓ npm audit clean${NC}"
  fi
else
  [ ! -f "$PLUGIN_PATH/package-lock.json" ] && echo "  (no package-lock.json — skipping npm audit)"
fi

echo ""
echo -e "${CYAN}── Forbidden PHP Functions (WP.org auto-reject) ──${NC}"

# 3. Forbidden functions per WP.org plugin review team 2025 standards
# Per WP.org plugin review team + PHP security consensus:
# - eval() is a hard fail (no legitimate use)
# - exec/system/passthru/shell_exec/proc_open/popen = hard fail (shell exec)
# - create_function = hard fail (removed in PHP 8.0, string eval)
# - base64_decode/encode = WARN only (WP core uses it for REST/media/OAuth)
# - assert() = WARN (context dependent, PHP 8.3 deprecated string form)
# Ref: https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/
FORBIDDEN=(
  'eval\s*\('
  'exec\s*\('
  'system\s*\('
  'passthru\s*\('
  'shell_exec\s*\('
  'proc_open\s*\('
  'popen\s*\('
  'create_function\s*\('
  'extract\s*\(\s*\$_(GET|POST|REQUEST|COOKIE)'
  'parse_str\s*\([^,]+\)\s*;'
  'preg_replace\s*\([^,]+/e'
)

WARN_PATTERNS=(
  'base64_decode\s*\('
  'base64_encode\s*\('
  'assert\s*\('
)

FF_FAIL=0
for pattern in "${FORBIDDEN[@]}"; do
  HITS=$(grep -rEn "(^|[^a-zA-Z_])$pattern" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=tests 2>/dev/null | \
    grep -vE "//.*$pattern|#.*$pattern|/\*.*$pattern" | head -5 || true)
  if [ -n "$HITS" ]; then
    FUNC_NAME=$(echo "$pattern" | sed 's/[^a-zA-Z0-9_]//g' | head -c 30)
    echo -e "${RED}✗ Forbidden function: ${FUNC_NAME}${NC}"
    echo "$HITS" | head -2
    FF_FAIL=1
  fi
done

# Code obfuscation beyond forbidden functions (plugin-check `code_obfuscation`)
# Matches: long hex strings, chr()-chain encoding, variable-named-as-string constructions
OBF_COUNT=0
OBF_HITS=$(grep -rEn '\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}' "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -3 || true)
if [ -n "$OBF_HITS" ]; then
  echo -e "${RED}✗ Hex-encoded string sequences (common obfuscation signal):${NC}"
  echo "$OBF_HITS" | head -2
  FAIL=1; OBF_COUNT=$((OBF_COUNT+1))
fi
CHR_HITS=$(grep -rEn 'chr\([0-9]+\)\s*\.\s*chr\([0-9]+\)\s*\.\s*chr\([0-9]+\)' "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -3 || true)
if [ -n "$CHR_HITS" ]; then
  echo -e "${RED}✗ chr() concatenation chains (string-building obfuscation):${NC}"
  echo "$CHR_HITS" | head -2
  FAIL=1; OBF_COUNT=$((OBF_COUNT+1))
fi

# ALLOW_UNFILTERED_UPLOADS — plugins that define this = security nightmare
UNFILTERED=$(grep -rEn "define\s*\(\s*['\"]ALLOW_UNFILTERED_UPLOADS['\"]\s*,\s*true" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -3 || true)
if [ -n "$UNFILTERED" ]; then
  echo -e "${RED}✗ Plugin defines ALLOW_UNFILTERED_UPLOADS=true — bypasses WP's MIME allowlist${NC}"
  echo "$UNFILTERED" | head -2
  FAIL=1
fi

for pattern in "${WARN_PATTERNS[@]}"; do
  HITS=$(grep -rEn "(^|[^a-zA-Z_])$pattern" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=tests 2>/dev/null | \
    grep -vE "//.*$pattern|#.*$pattern|/\*.*$pattern" | head -3 || true)
  if [ -n "$HITS" ]; then
    FUNC_NAME=$(echo "$pattern" | sed 's/[^a-zA-Z0-9_]//g' | head -c 30)
    echo -e "${YELLOW}⚠ ${FUNC_NAME} usage (review context — WP core uses this for legit cases):${NC}"
    echo "$HITS" | head -2
    WARN=1
  fi
done

if [ "$FF_FAIL" -eq 1 ]; then
  FAIL=1
  echo ""
  echo "   These will cause automatic WordPress.org rejection."
  echo "   Ref: https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/"
else
  echo -e "${GREEN}✓ No forbidden functions found${NC}"
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}ZIP HYGIENE + SUPPLY CHAIN: FAIL${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}ZIP HYGIENE + SUPPLY CHAIN: WARN (review above)${NC}"
  exit 0
fi
echo -e "${GREEN}ZIP HYGIENE + SUPPLY CHAIN: PASS${NC}"
exit 0
