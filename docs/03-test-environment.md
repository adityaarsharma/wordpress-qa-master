# Test Environment Setup

> How to spin up a real WordPress site for testing — automatically, reproducibly, and without touching your live site.

---

## Table of Contents

1. [Two Tools: wp-env vs wp-now](#1-two-tools-wp-env-vs-wp-now)
2. [The Orbit Wrapper: create-test-site.sh](#2-the-orbit-wrapper-create-test-sitesh)
3. [Raw wp-env Usage](#3-raw-wp-env-usage)
4. [wp-now: Zero-Config Quick Start](#4-wp-now-zero-config-quick-start)
5. [Daily Site Management](#5-daily-site-management)
6. [WP-CLI Inside wp-env](#6-wp-cli-inside-wp-env)
7. [Database Access](#7-database-access)
8. [Multisite Testing](#8-multisite-testing)
9. [Multi-PHP Version Matrix](#9-multi-php-version-matrix)
10. [Loading Test Fixtures](#10-loading-test-fixtures)
11. [Plugin Conflict Testing](#11-plugin-conflict-testing)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Two Tools: wp-env vs wp-now

| Feature | wp-env | wp-now |
|---|---|---|
| Backed by | Docker (real MySQL) | PHP WASM (in-process SQLite) |
| Setup time | ~60 sec first run | ~5 sec |
| DB profiling | ✓ Full MySQL support | ✗ SQLite only |
| Multiple PHP versions | ✓ One config per version | ✗ Single version |
| CI-friendly | ✓ Fully headless | ✓ |
| Requires Docker | ✓ Yes | ✗ No |
| Best for | Full gauntlet, release audits | Quick sanity checks |

**Rule of thumb**: Use `wp-env` for the gauntlet. Use `wp-now` for "does this activate?" checks.

---

## 2. The Orbit Wrapper: create-test-site.sh

The recommended way to start a test site. It handles everything automatically.

```bash
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin --port 8881
```

What it does:
1. Creates `.wp-env-site/` with a `.wp-env.json` configured for your plugin
2. Adds Query Monitor for DB profiling
3. Enables `WP_DEBUG`, `WP_DEBUG_LOG`, `SAVEQUERIES` automatically
4. Starts wp-env Docker containers
5. Installs plugins listed in `qa.config.json > companions`
6. Creates an admin user (`admin` / `password`)
7. Prints the site URL and credentials

### Options

```bash
bash scripts/create-test-site.sh \
  --plugin ~/plugins/my-plugin \    # required: path to plugin
  --port 8881 \                     # port for the test site (default: 8881)
  --site my-site \                  # internal site name (default: auto from plugin slug)
  --php 8.2 \                       # PHP version (7.4, 8.0, 8.1, 8.2 — default: latest)
  --wp 6.4 \                        # WordPress version (default: latest)
  --mode full                       # full = Query Monitor + debug enabled; quick = minimal
```

### Output

```
✓ wp-env started
✓ Plugin activated: my-plugin
✓ Query Monitor activated
✓ WP_DEBUG enabled

Site ready at: http://localhost:8881
Admin:         http://localhost:8881/wp-admin
Username:      admin
Password:      password
```

---

## 3. Raw wp-env Usage

If you want more control, manage wp-env directly.

### Basic .wp-env.json

```json
{
  "core": "WordPress/WordPress#trunk",
  "plugins": [
    "/path/to/your/plugin",
    "https://downloads.wordpress.org/plugin/query-monitor.zip"
  ],
  "port": 8881,
  "config": {
    "WP_DEBUG": true,
    "WP_DEBUG_LOG": true,
    "SAVEQUERIES": true,
    "WP_DEBUG_DISPLAY": false
  }
}
```

```bash
# Start the site
wp-env start

# Site is at http://localhost:8881
# Admin at http://localhost:8881/wp-admin — admin / password
```

### Specific WordPress version

```json
{
  "core": "WordPress/WordPress#tags/6.4",
  "plugins": ["/path/to/my-plugin"],
  "port": 8881
}
```

### WordPress.org plugin as companion

```json
{
  "plugins": [
    "/path/to/my-plugin",
    "https://downloads.wordpress.org/plugin/woocommerce.zip",
    "https://downloads.wordpress.org/plugin/elementor.zip",
    "https://downloads.wordpress.org/plugin/wordpress-seo.zip"
  ]
}
```

### Specific theme

```json
{
  "themes": [
    "https://downloads.wordpress.org/theme/twentytwentyfour.zip"
  ]
}
```

### Mappings (symlink a local file)

```json
{
  "mappings": {
    "wp-content/uploads/my-test-data": "/path/to/local/test-data"
  }
}
```

---

## 4. wp-now: Zero-Config Quick Start

For instant testing without Docker:

```bash
cd ~/plugins/my-plugin
wp-now start

# → http://localhost:8881
# Runs PHP-WASM with SQLite. No setup required.
```

### wp-now with a specific WP version

```bash
wp-now start --wp=6.4
```

### Limitations

- No real MySQL — DB profiling doesn't work
- No WP-CLI MySQL access
- Session doesn't persist on restart
- Not suitable for multi-plugin conflict testing

---

## 5. Daily Site Management

```bash
# Start (or restart) the site
wp-env start

# Stop (pause Docker containers, keep data)
wp-env stop

# Destroy (wipe everything — clean slate)
wp-env destroy

# Reset DB to factory state (keep containers)
wp-env clean all
wp-env clean db       # just DB
wp-env clean uploads  # just uploads

# View container logs
wp-env logs
wp-env logs --watch   # follow live

# Restart without losing data
wp-env stop && wp-env start
```

---

## 6. WP-CLI Inside wp-env

All WP-CLI commands work via `wp-env run cli wp ...`:

```bash
# Plugin management
wp-env run cli wp plugin list
wp-env run cli wp plugin activate my-plugin
wp-env run cli wp plugin deactivate my-plugin
wp-env run cli wp plugin install woocommerce --activate
wp-env run cli wp plugin install my-plugin.zip --activate --force  # upgrade

# User management
wp-env run cli wp user list
wp-env run cli wp user create editor editor@test.com --role=editor --user_pass=password
wp-env run cli wp user create subscriber sub@test.com --role=subscriber --user_pass=password

# Content seeding
wp-env run cli wp post create --post_title="Test Post" --post_status=publish
wp-env run cli wp post generate --count=100
wp-env run cli wp post generate --count=10000 --post_type=product  # stress test

# Options
wp-env run cli wp option list --search="my_plugin_*"
wp-env run cli wp option get blogname
wp-env run cli wp option update blogname "Test Site"

# Theme
wp-env run cli wp theme activate twentytwentyfour
wp-env run cli wp theme install storefront --activate

# Transients
wp-env run cli wp transient delete --all

# Cron
wp-env run cli wp cron event list
wp-env run cli wp cron event run my_plugin_daily

# WP config
wp-env run cli wp config set WP_DEBUG true --type=constant
wp-env run cli wp config get

# DB
wp-env run cli wp db cli            # interactive MySQL shell
wp-env run cli wp db query "SELECT option_name, length(option_value) FROM wp_options WHERE autoload='yes' ORDER BY 2 DESC LIMIT 10"
wp-env run cli wp db export backup.sql
wp-env run cli wp db import restore.sql

# Shell into container
wp-env run cli bash
wp-env run wordpress bash           # WP container shell
```

---

## 7. Database Access

### Via WP-CLI (easiest)

```bash
wp-env run cli wp db cli   # interactive MySQL prompt
```

### Via External Client (TablePlus, Sequel Ace, DBeaver)

```bash
# Get the connection details
wp-env run cli wp config get DB_HOST DB_NAME DB_USER DB_PASSWORD --format=table
```

Use those details in TablePlus or any MySQL client.

### Enable performance_schema for query profiling

```bash
wp-env run cli wp db query "SET GLOBAL performance_schema = ON"

# Top 10 slowest queries
wp-env run cli wp db query "
SELECT DIGEST_TEXT, EXEC_COUNT, TOTAL_LATENCY
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME = DATABASE()
ORDER BY TOTAL_LATENCY DESC
LIMIT 10
"
```

---

## 8. Multisite Testing

```bash
# Convert single site to multisite
wp-env run cli wp core multisite-convert --title="Test Network"

# Create additional sites
wp-env run cli wp site create --slug=site2 --title="Second Site"
wp-env run cli wp site list

# Network-activate your plugin
wp-env run cli wp plugin activate my-plugin --network

# Test the second site
WP_TEST_URL=http://localhost:8881/site2 npx playwright test
```

### Multisite .wp-env.json

```json
{
  "core": "WordPress/WordPress#trunk",
  "plugins": ["/path/to/my-plugin"],
  "port": 8881,
  "config": {
    "WP_ALLOW_MULTISITE": true,
    "MULTISITE": true,
    "SUBDOMAIN_INSTALL": false,
    "DOMAIN_CURRENT_SITE": "localhost",
    "PATH_CURRENT_SITE": "/",
    "SITE_ID_CURRENT_SITE": 1,
    "BLOG_ID_CURRENT_SITE": 1
  }
}
```

---

## 9. Multi-PHP Version Matrix

Test your plugin on PHP 7.4, 8.0, 8.1, and 8.2 simultaneously.

### Manual approach (4 terminal tabs)

```bash
# Terminal 1 — PHP 7.4
mkdir -p ~/.wp-env-sites/php74 && cd ~/.wp-env-sites/php74
cat > .wp-env.json <<'EOF'
{ "plugins": ["/path/to/my-plugin"], "phpVersion": "7.4", "port": 8881 }
EOF
wp-env start

# Terminal 2 — PHP 8.0
mkdir -p ~/.wp-env-sites/php80 && cd ~/.wp-env-sites/php80
cat > .wp-env.json <<'EOF'
{ "plugins": ["/path/to/my-plugin"], "phpVersion": "8.0", "port": 8882 }
EOF
wp-env start

# Terminal 3 — PHP 8.1
mkdir -p ~/.wp-env-sites/php81 && cd ~/.wp-env-sites/php81
cat > .wp-env.json <<'EOF'
{ "plugins": ["/path/to/my-plugin"], "phpVersion": "8.1", "port": 8883 }
EOF
wp-env start

# Terminal 4 — PHP 8.2
mkdir -p ~/.wp-env-sites/php82 && cd ~/.wp-env-sites/php82
cat > .wp-env.json <<'EOF'
{ "plugins": ["/path/to/my-plugin"], "phpVersion": "8.2", "port": 8884 }
EOF
wp-env start
```

### Run gauntlet against each version

```bash
for PORT in 8881 8882 8883 8884; do
  PHP_VER=$(( PORT - 8877 ))  # 4→7.4, 5→8.0, 6→8.1, 7→8.2
  echo "=== Testing on port $PORT ==="
  WP_TEST_URL=http://localhost:$PORT \
    bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode quick
done
```

### Batch PHP matrix (one command)

```bash
bash scripts/batch-test.sh \
  --plugins ~/plugins/my-plugin \
  --mode matrix \
  --php-versions "7.4,8.0,8.1,8.2"
```

Results appear in `reports/batch-TIMESTAMP.md` with a pass/fail per PHP version.

---

## 10. Loading Test Fixtures

Seed your site with realistic data before testing.

### Generate posts at scale

```bash
# 100 regular posts
wp-env run cli wp post generate --count=100

# 10,000 posts (stress test)
wp-env run cli wp post generate --count=10000

# WooCommerce products
wp-env run cli wp post generate --count=500 --post_type=product

# Custom post type
wp-env run cli wp post generate --count=200 --post_type=my_cpt
```

### Import a database dump from production

```bash
# Export from production
wp db export production-backup.sql

# Import into wp-env
wp-env run cli wp db import /path/to/production-backup.sql

# Search-replace URLs
wp-env run cli wp search-replace 'https://yoursite.com' 'http://localhost:8881' --all-tables
```

### Create specific users for testing

```bash
wp-env run cli wp user create admin2 admin2@test.com --role=administrator --user_pass=password
wp-env run cli wp user create editor editor@test.com --role=editor --user_pass=password
wp-env run cli wp user create subscriber sub@test.com --role=subscriber --user_pass=password
wp-env run cli wp user create shop_manager manager@test.com --role=shop_manager --user_pass=password
```

### Activate specific pages

```bash
# Create pages your plugin needs
wp-env run cli wp post create \
  --post_type=page \
  --post_title="Shop" \
  --post_status=publish \
  --post_content="[woocommerce_shop]"

wp-env run cli wp option update woocommerce_shop_page_id $(wp-env run cli wp post list --post_type=page --name=shop --field=ID)
```

---

## 11. Plugin Conflict Testing

Stress-test your plugin alongside popular conflict risks:

```bash
# Install the "conflict suite"
wp-env run cli wp plugin install \
  woocommerce \
  elementor \
  wordpress-seo \
  contact-form-7 \
  wpml \
  --activate

# Run your gauntlet — all these plugins active simultaneously
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin
```

If the gauntlet passes with all these active, you're safe for 90% of real-world installs.

### Common conflict sources

| Plugin | Why it conflicts | What to check |
|---|---|---|
| WooCommerce | `wc_` function prefix, cart hooks | `woocommerce_loaded` hook timing |
| Elementor | `elementor/loaded` action, widget registration | Use `elementor/widgets/register`, not `init` |
| Yoast SEO | `wpseo_` option prefix, `the_title` filter weight | Filter priority clashes |
| Rank Math | Schema output, canonical URL filters | Duplicate schema types in `<head>` |
| WPML | Language handling in queries, URLs | Hardcoded `get_locale()` calls |
| Beaver Builder | Similar widget API to Elementor | Class name collisions |

---

## 12. Troubleshooting

### wp-env start hangs

```bash
# Check Docker is running
docker info

# Nuclear option — destroy and restart
wp-env destroy
wp-env start
```

### Port already in use

```bash
lsof -i :8881       # see what's on port 8881
# Use a different port:
# Change "port" in .wp-env.json to 8882
```

### Site loads but plugin not active

```bash
wp-env run cli wp plugin list | grep my-plugin
wp-env run cli wp plugin activate my-plugin
```

### "Plugin could not be activated because it triggered a fatal error"

```bash
wp-env run cli wp eval 'ini_set("display_errors", 1); include ABSPATH . "wp-admin/includes/plugin.php"; activate_plugin("my-plugin/my-plugin.php");'
# Shows the actual PHP fatal
```

### Changes to .wp-env.json not taking effect

```bash
wp-env stop
wp-env start --update  # re-pulls config
```

### Plugin not found after updating path

```bash
# Destroy and recreate (path must be in .wp-env.json before start)
wp-env destroy && wp-env start
```

---

**Next**: [docs/04-gauntlet.md](04-gauntlet.md) — understand all 11 gauntlet steps in depth.
