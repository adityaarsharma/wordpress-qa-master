# Multi-Plugin Workflows

> Testing multiple plugins simultaneously — batch testing, PHP version matrix, parallel audits.

---

## Table of Contents

1. [When to Use Multi-Plugin Testing](#1-when-to-use-multi-plugin-testing)
2. [Batch Testing: batch-test.sh](#2-batch-testing-batch-testsh)
3. [PHP Version Matrix](#3-php-version-matrix)
4. [Parallel Skill Audits on Multiple Plugins](#4-parallel-skill-audits-on-multiple-plugins)
5. [Free vs Pro Version Testing](#5-free-vs-pro-version-testing)
6. [Plugin Suite Testing (Multiple Plugins Together)](#6-plugin-suite-testing-multiple-plugins-together)
7. [Upgrade Path Matrix](#7-upgrade-path-matrix)
8. [Cleanup After Multi-Plugin Runs](#8-cleanup-after-multi-plugin-runs)

---

## 1. When to Use Multi-Plugin Testing

| Scenario | Command |
|---|---|
| Test all plugins before a release sprint | `batch-test.sh --plugins-dir ~/plugins` |
| Test one plugin on 4 PHP versions | PHP matrix setup + `for` loop |
| Audit 3 plugins in parallel with skills | Parallel `claude` skill calls |
| Test free + pro versions side-by-side | Batch with 2 plugin paths |
| Regression test the entire plugin portfolio | `batch-test.sh --plugins-dir ~/plugins --concurrency 2` |

---

## 2. Batch Testing: batch-test.sh

`batch-test.sh` runs the full gauntlet on multiple plugins in parallel. Each plugin gets its own isolated wp-env container on a unique port.

### Basic usage

```bash
# Test all plugins in a directory
bash scripts/batch-test.sh --plugins-dir ~/plugins

# Test specific plugins
bash scripts/batch-test.sh --plugins "~/plugins/plugin-a,~/plugins/plugin-b,~/plugins/plugin-c"

# Limit concurrency (default: half your CPU cores, max 4)
bash scripts/batch-test.sh --plugins-dir ~/plugins --concurrency 2

# Start on a different base port (useful if 8881 is in use)
bash scripts/batch-test.sh --plugins-dir ~/plugins --base-port 8891
```

### How it works

```
batch-test.sh
    │
    ├── Plugin A → port 8881 → gauntlet.sh → log: batch-logs/plugin-a-*.log
    ├── Plugin B → port 8891 → gauntlet.sh → log: batch-logs/plugin-b-*.log
    ├── Plugin C → port 8901 → gauntlet.sh → log: batch-logs/plugin-c-*.log
    │   (wait for concurrency slot if at cap)
    ├── Plugin D → port 8911 → gauntlet.sh → ...
    │
    └── Summary → reports/batch-TIMESTAMP.md
```

Ports are spaced 10 apart (`BASE_PORT + index * 10`) so Docker containers don't conflict.

### Batch report

```markdown
| Plugin    | Status | Pass | Warn | Fail | Log |
|---|---|---|---|---|---|
| plugin-a  | ✓      | 9    | 2    | 0    | [log](batch-logs/plugin-a.log) |
| plugin-b  | ✗      | 7    | 1    | 2    | [log](batch-logs/plugin-b.log) |
| plugin-c  | ✓      | 11   | 0    | 0    | [log](batch-logs/plugin-c.log) |
```

### Viewing individual plugin logs

```bash
# View full output for plugin-b (which failed)
cat reports/batch-logs/plugin-b-*.log

# Grep for failures across all batch logs
grep -h "✗\|FAIL\|error" reports/batch-logs/*.log
```

### Concurrency tuning

```bash
# Default: auto-scaled to half CPU cores (max 4)
# On a 4-core machine: 2 parallel containers
# On an 8-core machine: 4 parallel containers

# Override:
bash scripts/batch-test.sh --plugins-dir ~/plugins --concurrency 1  # sequential
bash scripts/batch-test.sh --plugins-dir ~/plugins --concurrency 4  # max parallel

# Memory warning:
# Each wp-env container uses ~500MB RAM (WP + MySQL containers)
# 4 parallel = ~2GB RAM usage
# Check before running with --concurrency 4 on < 8GB RAM machines
```

---

## 3. PHP Version Matrix

Test your plugin against PHP 7.4, 8.0, 8.1, and 8.2 to catch compatibility issues before users report them.

### Step 1: Create site directories

```bash
PLUGIN=~/plugins/my-plugin
mkdir -p ~/.wp-env-matrix/{php74,php80,php81,php82}

# PHP 7.4 site
cat > ~/.wp-env-matrix/php74/.wp-env.json <<'EOF'
{
  "core": "WordPress/WordPress#tags/6.4",
  "plugins": ["/path/to/my-plugin"],
  "phpVersion": "7.4",
  "port": 8881,
  "config": {
    "WP_DEBUG": true,
    "WP_DEBUG_LOG": true
  }
}
EOF

# PHP 8.0 site
cat > ~/.wp-env-matrix/php80/.wp-env.json <<'EOF'
{
  "core": "WordPress/WordPress#tags/6.4",
  "plugins": ["/path/to/my-plugin"],
  "phpVersion": "8.0",
  "port": 8882
}
EOF

# PHP 8.1 site
cat > ~/.wp-env-matrix/php81/.wp-env.json <<'EOF'
{
  "core": "WordPress/WordPress#tags/6.4",
  "plugins": ["/path/to/my-plugin"],
  "phpVersion": "8.1",
  "port": 8883
}
EOF

# PHP 8.2 site
cat > ~/.wp-env-matrix/php82/.wp-env.json <<'EOF'
{
  "core": "WordPress/WordPress#tags/6.4",
  "plugins": ["/path/to/my-plugin"],
  "phpVersion": "8.2",
  "port": 8884
}
EOF
```

### Step 2: Start all sites

```bash
(cd ~/.wp-env-matrix/php74 && wp-env start) &
(cd ~/.wp-env-matrix/php80 && wp-env start) &
(cd ~/.wp-env-matrix/php81 && wp-env start) &
(cd ~/.wp-env-matrix/php82 && wp-env start) &
wait
echo "All PHP versions started"
```

### Step 3: Run gauntlet against each

```bash
PLUGIN=~/plugins/my-plugin

for PHP in 74 80 81 82; do
  PORT=$((8880 + PHP / 10))  # 74→8881, 80→8882, 81→8883, 82→8884
  # Adjust port mapping based on your setup

  echo "=== Testing PHP $PHP on port $PORT ==="
  WP_TEST_URL=http://localhost:$PORT \
    bash scripts/gauntlet.sh \
      --plugin "$PLUGIN" \
      --mode quick \
    | tee reports/php${PHP}-gauntlet.log
done
```

### Step 4: Compare results

```bash
# Quick pass/fail summary
for PHP in 74 80 81 82; do
  RESULT=$(grep -E "GAUNTLET (PASSED|FAILED)" reports/php${PHP}-gauntlet.log | tail -1)
  echo "PHP $PHP: $RESULT"
done
```

### Expected output

```
PHP 74: ✓ GAUNTLET PASSED
PHP 80: ✓ GAUNTLET PASSED
PHP 81: ✓ GAUNTLET PASSED
PHP 82: ⚠ GAUNTLET PASSED WITH WARNINGS
```

### Common PHP version issues

| PHP Version | Common Problems |
|---|---|
| PHP 7.4 → 8.0 | `count()` on null, `array_key_first()` behavior, `$_SERVER` type changes |
| PHP 8.0 → 8.1 | `array_is_list()` not available in 8.0, `fibers` not in 8.0, `readonly` properties |
| PHP 8.1 → 8.2 | Deprecation of dynamic properties, `true` as standalone type |
| Any version | `create_function()` removed in 8.0, `each()` removed in 8.0 |

PHPStan in Step 3 and the `PHPCompatibilityWP` PHPCS ruleset catch most of these automatically.

---

## 4. Parallel Skill Audits on Multiple Plugins

Run all 6 skills on multiple plugins simultaneously (6 × N Claude processes):

```bash
# Define plugins
PLUGINS=(
  "~/plugins/plugin-a"
  "~/plugins/plugin-b"
  "~/plugins/plugin-c"
)

# Create output dirs
for P in "${PLUGINS[@]}"; do
  NAME=$(basename "$P")
  mkdir -p "reports/skill-audits-$NAME"
done

# Launch all audits in parallel
for P in "${PLUGINS[@]}"; do
  NAME=$(basename "$P")
  DIR="reports/skill-audits-$NAME"

  claude "/wordpress-penetration-testing Security audit $P — OWASP Top 10" \
    > "$DIR/security.md" 2>/dev/null &

  claude "/performance-engineer Analyze $P — N+1, assets, hooks" \
    > "$DIR/performance.md" 2>/dev/null &
done

wait
echo "All parallel skill audits complete"
ls reports/skill-audits-*/security.md
```

### Generate combined HTML report

After running audits, generate an HTML report per plugin:

```bash
for P in "${PLUGINS[@]}"; do
  NAME=$(basename "$P")
  # The gauntlet's Python HTML generator works on any skill-audits dir
  SKILL_REPORT_DIR="reports/skill-audits-$NAME" \
  PLUGIN_NAME="$NAME" \
  python3 scripts/generate-skill-report.py  # if extracted as standalone script
done
```

---

## 5. Free vs Pro Version Testing

Test both versions side-by-side to ensure:
1. Free version upgrades to Pro without data loss
2. Pro features are properly gated (not accessible in Free)
3. Downgrade from Pro → Free doesn't break the site

```bash
# Create two sites on different ports
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin-free --port 8881 --site free
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin-pro --port 8882 --site pro

# Run gauntlet on both
WP_TEST_URL=http://localhost:8881 bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin-free
WP_TEST_URL=http://localhost:8882 bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin-pro
```

### Upgrade path test

```bash
# 1. Start with Free version
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin-free --port 8881

# 2. Create test data (simulate real user)
wp-env run cli wp post create --post_title="Test Post" --post_status=publish
wp-env run cli wp option update my_plugin_setting "test-value"

# 3. Install Pro on top (upgrade)
wp-env run cli wp plugin install ~/plugins/my-plugin-pro.zip --activate --force

# 4. Run quick gauntlet — should still pass
WP_TEST_URL=http://localhost:8881 bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin-pro --mode quick

# 5. Verify data survived
wp-env run cli wp option get my_plugin_setting  # should return "test-value"
```

---

## 6. Plugin Suite Testing (Multiple Plugins Together)

If you have a suite of plugins (like a plugin + companion extensions), test them all activated together:

```json
// .wp-env.json — all suite plugins active simultaneously
{
  "plugins": [
    "/path/to/core-plugin",
    "/path/to/extension-a",
    "/path/to/extension-b",
    "/path/to/extension-c",
    "https://downloads.wordpress.org/plugin/woocommerce.zip"
  ],
  "port": 8881
}
```

```bash
# Start
wp-env start

# Run gauntlet against the core plugin
bash scripts/gauntlet.sh --plugin ~/plugins/core-plugin

# Run Playwright for all extensions
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/suite/
```

### What to check in suite testing

1. **No activation order dependency** — disable all, then activate in different orders
2. **No shared option name collisions** — prefix check via skill
3. **No JS handle conflicts** — check `wp_enqueue_script` handle names
4. **Combined load time** — Lighthouse score with all active vs one at a time

```bash
# Activation order test
wp-env run cli wp plugin deactivate --all
wp-env run cli wp plugin activate extension-b  # activate in random order
wp-env run cli wp plugin activate core-plugin
wp-env run cli wp plugin activate extension-a
# Site should still work — visit homepage
curl -sf http://localhost:8881/ | grep -i "500\|Fatal" && echo "FAIL" || echo "PASS"
```

---

## 7. Upgrade Path Matrix

Test your current release against all supported WordPress versions:

```bash
WP_VERSIONS=("6.3" "6.4" "6.5" "6.6" "trunk")
PLUGIN=~/plugins/my-plugin

for WP_VER in "${WP_VERSIONS[@]}"; do
  echo "=== Testing against WP $WP_VER ==="

  # Create a site with this WP version
  mkdir -p ~/.wp-env-matrix/wp${WP_VER//./}
  cat > ~/.wp-env-matrix/wp${WP_VER//./}/.wp-env.json <<EOF
{
  "core": "WordPress/WordPress#tags/${WP_VER}",
  "plugins": ["${PLUGIN}"],
  "port": 8881
}
EOF

  (cd ~/.wp-env-matrix/wp${WP_VER//./} && wp-env start)

  # Quick gauntlet
  WP_TEST_URL=http://localhost:8881 \
    bash scripts/gauntlet.sh --plugin "$PLUGIN" --mode quick \
    | grep -E "GAUNTLET|✗|FAIL" | tee -a reports/wp-matrix-results.txt

  # Stop to free port 8881 for next version
  (cd ~/.wp-env-matrix/wp${WP_VER//./} && wp-env stop)
done

echo "=== Matrix Results ==="
cat reports/wp-matrix-results.txt
```

---

## 8. Cleanup After Multi-Plugin Runs

Multi-plugin testing creates lots of Docker containers and uses disk space.

### Stop all containers

```bash
# Stop all wp-env containers
for dir in ~/.wp-env-matrix/*/; do
  (cd "$dir" && wp-env stop) 2>/dev/null
done

# Stop batch sites
for dir in .wp-env-site/batch-*/; do
  (cd "$dir" && wp-env stop) 2>/dev/null
done
```

### Destroy all test sites

```bash
# Nuclear — removes all containers and volumes
for dir in ~/.wp-env-matrix/*/; do
  (cd "$dir" && wp-env destroy) 2>/dev/null
done

rm -rf .wp-env-site/batch-*
```

### Reclaim Docker disk space

```bash
# Remove unused containers, images, and volumes
docker system prune -f

# More aggressive — removes ALL stopped containers + unused images
docker system prune -a -f

# Check recovered space
docker system df
```

### Archive reports before cleanup

```bash
# Zip all reports for this sprint
SPRINT="sprint-$(date +%Y%m%d)"
zip -r "~/reports-archive/$SPRINT.zip" reports/
rm -rf reports/batch-logs/ reports/screenshots/ reports/videos/
```

---

**Next**: [docs/13-roles.md](13-roles.md) — role-specific guides for Developer, QA, PM, and Designer.
