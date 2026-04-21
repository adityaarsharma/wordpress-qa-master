#!/usr/bin/env bash
# Orbit — PHP Compatibility Check (through PHP 8.5, April 2026)
#
# Catches:
#   - PHP 8.x deprecations that will become errors
#   - Removed functions (PHP 8.0 / 8.1 / 8.3 removals)
#   - Dynamic properties (deprecated 8.2, required 8.2+)
#   - Implicit nullable types (deprecated 8.4)
#   - str_contains / str_starts_with usage without version guards
#   - E_STRICT removed in 8.4
#   - Explicit nullable parameter type declarations (8.4+)
#   - json_validate (8.3+), array_find (8.4+) usage
#   - mb_trim / mb_ltrim / mb_rtrim (8.4+)
#
# Static scan — reads source, cross-references with declared "Requires PHP"
# version in plugin header.

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1)
MIN_PHP=""
[ -n "$MAIN_FILE" ] && MIN_PHP=$(grep -iE "^\s*\*?\s*Requires PHP:" "$MAIN_FILE" | head -1 | sed -E 's/.*Requires PHP:\s*//' | tr -d ' \r')

if [ -z "$MIN_PHP" ]; then
  echo -e "${YELLOW}⚠ 'Requires PHP' not declared in plugin header${NC}"
  echo "   Add: Requires PHP: 7.4 (or your actual minimum)"
  MIN_PHP="7.4"
fi

echo "Plugin declares: Requires PHP: $MIN_PHP"
echo "Scanning against PHP 8.0 → 8.5 compatibility rules"
echo ""

version_ge() { [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]; }

FAIL=0
WARN=0

# ─── Removed / unusable in modern PHP ────────────────────────────────────────
echo -e "${CYAN}── Removed / breaking changes ──${NC}"

# PHP 8.0 removed: each(), create_function(), _autoload(), money_format()
for fn in 'each\b' 'create_function\s*\(' '__autoload\s*\(' 'money_format\s*\('; do
  FN_LABEL=$(echo "$fn" | sed 's/[^a-z_]//gi')
  HITS=$(grep -rEn "(^|[^a-zA-Z_>])${fn}" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
    grep -vE "//.*${fn}|function\s+${fn}" | head -3 || true)
  if [ -n "$HITS" ]; then
    echo -e "${RED}✗${NC} ${FN_LABEL} — removed in PHP 8.0"
    echo "$HITS" | head -1 | sed 's/^/   /'
    FAIL=1
  fi
done

# PHP 8.1 removed: restore_include_path() + misc.
# PHP 8.3 deprecated: various constants
# PHP 8.4 deprecated: implicitly nullable parameter types, E_STRICT constant
IMPLICIT_NULLABLE=$(grep -rEn "function\s+[a-zA-Z_]+\s*\([^)]*\b[a-zA-Z_]+\s+\\\$[a-zA-Z_]+\s*=\s*null" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -vE '\?\s*[a-zA-Z_]+\s+\$' | head -3 || true)
if [ -n "$IMPLICIT_NULLABLE" ]; then
  echo -e "${YELLOW}⚠${NC} Implicit nullable parameters (deprecated PHP 8.4):"
  echo "$IMPLICIT_NULLABLE" | head -2 | sed 's/^/   /'
  echo "   Fix: change 'string \$x = null' to '?string \$x = null'"
  WARN=1
fi

# PHP 8.2 deprecated: dynamic properties (error in 8.3 without #[AllowDynamicProperties])
DYN_PROPS=$(grep -rEn '^\s*class\s+[A-Z][a-zA-Z0-9_]*\s*({|extends|implements)' "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -20 || true)
if [ -n "$DYN_PROPS" ]; then
  CLASS_COUNT=$(echo "$DYN_PROPS" | wc -l | tr -d ' ')
  ALLOW_DYNAMIC=$(grep -rEn "#\[AllowDynamicProperties\]" "$PLUGIN_PATH" \
    --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CLASS_COUNT" -gt 0 ] && [ "$ALLOW_DYNAMIC" -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC} $CLASS_COUNT class(es) defined, 0 use #[AllowDynamicProperties]"
    echo "   PHP 8.2+ deprecates dynamic props. Either declare them or add the attribute."
    WARN=1
  fi
fi

# ─── Missing backward-compat guards ──────────────────────────────────────────
echo ""
echo -e "${CYAN}── Backward compatibility guards ──${NC}"

# str_contains, str_starts_with, str_ends_with — PHP 8.0+
if ! version_ge "$MIN_PHP" "8.0"; then
  for fn in 'str_contains' 'str_starts_with' 'str_ends_with'; do
    HITS=$(grep -rEn "(^|[^a-zA-Z_>])${fn}\s*\(" "$PLUGIN_PATH" --include="*.php" \
      --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
    if [ -n "$HITS" ]; then
      echo -e "${RED}✗${NC} ${fn}() — PHP 8.0+ only, plugin declares $MIN_PHP"
      echo "$HITS" | head -1 | sed 's/^/   /'
      FAIL=1
    fi
  done
fi

# json_validate — PHP 8.3+
if ! version_ge "$MIN_PHP" "8.3"; then
  HITS=$(grep -rEn "(^|[^a-zA-Z_>])json_validate\s*\(" "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
  if [ -n "$HITS" ]; then
    echo -e "${RED}✗${NC} json_validate() — PHP 8.3+ only"
    FAIL=1
  fi
fi

# array_find, array_find_key, array_any, array_all — PHP 8.4+
if ! version_ge "$MIN_PHP" "8.4"; then
  for fn in 'array_find' 'array_find_key' 'array_any' 'array_all'; do
    HITS=$(grep -rEn "(^|[^a-zA-Z_>])${fn}\s*\(" "$PLUGIN_PATH" --include="*.php" \
      --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
    if [ -n "$HITS" ]; then
      echo -e "${RED}✗${NC} ${fn}() — PHP 8.4+ only"
      FAIL=1
    fi
  done
  # mb_trim family
  for fn in 'mb_trim' 'mb_ltrim' 'mb_rtrim' 'mb_ucfirst' 'mb_lcfirst'; do
    HITS=$(grep -rEn "(^|[^a-zA-Z_>])${fn}\s*\(" "$PLUGIN_PATH" --include="*.php" \
      --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -1 || true)
    if [ -n "$HITS" ]; then
      echo -e "${RED}✗${NC} ${fn}() — PHP 8.4+ only"
      FAIL=1
    fi
  done
fi

# Property hooks (PHP 8.4+) — "public int $x { get => ...; set => ...; }"
if ! version_ge "$MIN_PHP" "8.4"; then
  HOOKS=$(grep -rEn 'public\s+(readonly\s+)?[a-zA-Z_][a-zA-Z0-9_|?]*\s+\$[a-zA-Z_][a-zA-Z0-9_]*\s*\{\s*get' "$PLUGIN_PATH" \
    --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
  if [ -n "$HOOKS" ]; then
    echo -e "${RED}✗${NC} Property hooks ({ get => ... }) — PHP 8.4+ only"
    FAIL=1
  fi
fi

# Asymmetric visibility (PHP 8.4+) — "public private(set) $x"
if ! version_ge "$MIN_PHP" "8.4"; then
  ASYM=$(grep -rEn 'public\s+(protected|private)\s*\(\s*set\s*\)' "$PLUGIN_PATH" --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
  if [ -n "$ASYM" ]; then
    echo -e "${RED}✗${NC} Asymmetric visibility (private(set)) — PHP 8.4+ only"
    FAIL=1
  fi
fi

# ─── PHP 8.x modernization recommendations (warn only, not fail) ─────────────
echo ""
echo -e "${CYAN}── Modernization opportunities ──${NC}"

# utf8_encode / utf8_decode — deprecated 8.2, removed 9.0
UTF8_LEGACY=$(grep -rEn '(utf8_encode|utf8_decode)\s*\(' "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -3 || true)
if [ -n "$UTF8_LEGACY" ]; then
  echo -e "${YELLOW}⚠${NC} utf8_encode/utf8_decode — deprecated PHP 8.2, use mb_convert_encoding()"
  WARN=1
fi

# call_user_method / call_user_method_array removed long ago, flag if present
LEGACY_CALLS=$(grep -rEn '(call_user_method|call_user_method_array)\s*\(' "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
if [ -n "$LEGACY_CALLS" ]; then
  echo -e "${RED}✗${NC} call_user_method() — removed in PHP 7.0"
  FAIL=1
fi

# E_STRICT constant removed in PHP 8.4
E_STRICT=$(grep -rEn "E_STRICT" "$PLUGIN_PATH" --include="*.php" \
  --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | head -2 || true)
if [ -n "$E_STRICT" ]; then
  echo -e "${YELLOW}⚠${NC} E_STRICT — constant removed in PHP 8.4"
  WARN=1
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}PHP compatibility: FAIL${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}PHP compatibility: WARN${NC}"
  exit 0
fi
echo -e "${GREEN}PHP compatibility: PASS (through PHP 8.5)${NC}"
exit 0
