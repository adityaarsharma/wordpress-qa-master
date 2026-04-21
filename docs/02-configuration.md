# Configuration Reference

> Everything `qa.config.json` does, every field explained, with real examples for every plugin type.

---

## Table of Contents

1. [Creating Your Config](#1-creating-your-config)
2. [Plugin Section](#2-plugin-section)
3. [Environment Section](#3-environment-section)
4. [Companions Section](#4-companions-section)
5. [Upgrade Testing](#5-upgrade-testing)
6. [Competitors Section](#6-competitors-section)
7. [QA Focus Section](#7-qa-focus-section)
8. [Thresholds Section](#8-thresholds-section)
9. [Complete Examples by Plugin Type](#9-complete-examples-by-plugin-type)
10. [Using Config Without a File](#10-using-config-without-a-file)

---

## 1. Creating Your Config

```bash
cp qa.config.example.json qa.config.json
```

`qa.config.json` is gitignored — it's local to your machine. Never commit it (it may contain staging URLs or internal paths).

Once the file exists in the Orbit directory, you can run the gauntlet without `--plugin`:

```bash
# With config file
cd ~/Claude/orbit
bash scripts/gauntlet.sh

# Without config file (path required)
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin
```

---

## 2. Plugin Section

```json
"plugin": {
  "name": "My Awesome Plugin",
  "slug": "my-awesome-plugin",
  "type": "general",
  "path": "/Users/you/plugins/my-awesome-plugin",
  "version": "2.1.0",
  "hasPro": true,
  "proZip": "/Users/you/plugins/my-awesome-plugin-pro.zip",
  "textDomain": "my-awesome-plugin",
  "requiresAtLeast": "5.9",
  "testedUpTo": "6.7",
  "requiresPHP": "7.4"
}
```

### Field reference

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Human-readable plugin name (used in reports) |
| `slug` | string | Yes | WP.org slug — used for admin menu detection, competitor lookup |
| `type` | string | Yes | See plugin types below |
| `path` | string | Yes | **Absolute path** to the plugin folder |
| `version` | string | Yes | Current version being tested |
| `hasPro` | boolean | No | Whether a Pro version exists |
| `proZip` | string | If `hasPro: true` | Path to Pro zip for upgrade path testing |
| `textDomain` | string | Yes | Must match the `Text Domain:` in plugin header |
| `requiresAtLeast` | string | Yes | Minimum WP version from plugin header |
| `testedUpTo` | string | Yes | "Tested up to" WP version from plugin header |
| `requiresPHP` | string | Yes | Minimum PHP version from plugin header |

### Plugin types

The `type` field controls which test templates load and which add-on skills fire in Step 11.

| Type value | When to use | Extra skills triggered |
|---|---|---|
| `general` | Any plugin that doesn't fit the others | None |
| `elementor-addon` | Adds widgets to Elementor | `/antigravity-design-expert` |
| `gutenberg-blocks` | Registers Gutenberg blocks | `/wordpress-theme-development` |
| `seo` | SEO metadata, sitemaps, schema | None (all covered by 6 core) |
| `woocommerce` | WooCommerce extensions, gateways | `/wordpress-woocommerce-development` |
| `rest-api` | Custom REST endpoints, headless | `/api-security-testing` |
| `theme` | WP theme or FSE theme | `/wordpress-theme-development` |

---

## 3. Environment Section

```json
"environment": {
  "testUrl": "http://localhost:8881",
  "wpEnvPort": 8881,
  "adminUser": "admin",
  "adminPass": "password",
  "multisite": false,
  "stagingUrl": "https://staging.example.com"
}
```

### Field reference

| Field | Type | Default | Description |
|---|---|---|---|
| `testUrl` | string | `http://localhost:8881` | Base URL Playwright uses for all tests |
| `wpEnvPort` | number | `8881` | Port wp-env listens on |
| `adminUser` | string | `admin` | WordPress admin username |
| `adminPass` | string | `password` | WordPress admin password |
| `multisite` | boolean | `false` | If true, gauntlet runs multisite-specific checks |
| `stagingUrl` | string | `""` | Optional — if set, Playwright can also run against staging |

### Using staging URL

```bash
# Run Playwright against staging (not local wp-env)
WP_TEST_URL=https://staging.example.com npx playwright test

# Or set in config and override with env var
WP_TEST_URL=https://staging.example.com bash scripts/gauntlet.sh
```

For staging behind basic auth:

```bash
WP_TEST_URL=https://user:pass@staging.example.com bash scripts/gauntlet.sh
```

---

## 4. Companions Section

Companions are plugins that should be active alongside yours during testing. Use WP.org slugs.

```json
"companions": [
  "woocommerce",
  "elementor",
  "wordpress-seo",
  "contact-form-7"
]
```

The test site setup script reads this list and installs these plugins automatically:

```bash
bash scripts/create-test-site.sh --plugin ~/plugins/my-plugin
# → installs companions from qa.config.json automatically
```

### Common companion combinations

```json
// WooCommerce addon
"companions": ["woocommerce", "woocommerce-payments"]

// Elementor addon
"companions": ["elementor", "elementor-pro"]

// SEO plugin
"companions": ["wordpress-seo", "rank-math-seo"]  // conflict testing

// General plugin (conflict hardening)
"companions": ["woocommerce", "elementor", "wordpress-seo", "contact-form-7", "wpml"]
```

---

## 5. Upgrade Testing

Test that upgrading from an older version doesn't break anything.

```json
"upgrade": {
  "test": true,
  "fromVersion": "1.5.0",
  "fromZip": "/path/to/old-version.zip"
}
```

When `test: true`, the gauntlet:
1. Installs `fromZip` version
2. Creates test content (simulates real user data)
3. Upgrades to current version
4. Runs full functional tests

This catches the most common release-day breakage: DB schema changes that the upgrade migration doesn't handle.

---

## 6. Competitors Section

```json
"competitors": [
  "competitor-plugin-slug",
  "another-competitor-slug"
]
```

Used by Step 9 (Competitor Comparison) and by the SEO/comparison test templates. Competitors are installed automatically in wp-env and tested side-by-side with your plugin.

The `seo-plugin` test template uses the `PAIR-NN` naming convention to generate a report where each feature of your plugin sits next to the same feature from the competitor.

---

## 7. QA Focus Section

Control which areas of testing get attention.

```json
"qaFocus": {
  "priority": "full",
  "testAreas": [
    "activation",
    "admin-panel-load",
    "frontend-output",
    "rest-api-auth",
    "multisite",
    "upgrade-path",
    "accessibility"
  ]
}
```

### Priority values

| Value | What it does |
|---|---|
| `full` | All 11 gauntlet steps |
| `quick` | Steps 1–6 only (no Lighthouse, DB profile, editor perf, or skills) |
| `security` | Steps 1, 2, and 11 (security skill only) |
| `performance` | Steps 4, 7, 8, 10, and performance skill |

### testAreas values

Flags specific Playwright test projects to include/skip. Values map to test file names in `tests/playwright/`.

---

## 8. Thresholds Section

Define your pass/fail thresholds. The gauntlet will `warn` or `fail` based on these.

```json
"thresholds": {
  "lighthouse": {
    "performance": 75,
    "accessibility": 85,
    "bestPractices": 80,
    "seo": 80
  },
  "dbQueriesPerPage": 60,
  "dbQueriesAdmin": 100,
  "jsBundleKb": 500,
  "cssBundleKb": 200,
  "editorReadyMs": 4000,
  "widgetInsertMs": 800
}
```

### Threshold reference

| Threshold | Default | Warn | Fail |
|---|---|---|---|
| `lighthouse.performance` | 75 | < 75 | < 60 |
| `lighthouse.accessibility` | 85 | < 85 | < 70 |
| `dbQueriesPerPage` | 60 | > 60 | > 100 |
| `dbQueriesAdmin` | 100 | > 100 | > 200 |
| `jsBundleKb` | 500 | > 500 | > 1000 |
| `cssBundleKb` | 200 | > 200 | > 500 |
| `editorReadyMs` | 4000 | > 4000ms | > 8000ms |
| `widgetInsertMs` | 800 | > 800ms | > 2000ms |

---

## 9. Complete Examples by Plugin Type

### Elementor Addon

```json
{
  "plugin": {
    "name": "My Elementor Widget Pack",
    "slug": "my-elementor-widgets",
    "type": "elementor-addon",
    "path": "/Users/you/plugins/my-elementor-widgets",
    "version": "3.0.0",
    "hasPro": true,
    "proZip": "/Users/you/plugins/my-elementor-widgets-pro.zip",
    "textDomain": "my-elementor-widgets",
    "requiresAtLeast": "5.9",
    "testedUpTo": "6.7",
    "requiresPHP": "7.4"
  },
  "environment": {
    "testUrl": "http://localhost:8881",
    "wpEnvPort": 8881,
    "adminUser": "admin",
    "adminPass": "password",
    "multisite": false
  },
  "companions": ["elementor", "elementor-pro"],
  "upgrade": {
    "test": true,
    "fromVersion": "2.9.0"
  },
  "competitors": ["essential-addons-for-elementor-lite"],
  "qaFocus": {
    "priority": "full",
    "testAreas": ["activation", "elementor-widgets", "frontend-output", "accessibility"]
  },
  "thresholds": {
    "lighthouse": { "performance": 70, "accessibility": 90 },
    "editorReadyMs": 3000,
    "widgetInsertMs": 600
  }
}
```

### WooCommerce Extension

```json
{
  "plugin": {
    "name": "Custom WooCommerce Checkout",
    "slug": "custom-woo-checkout",
    "type": "woocommerce",
    "path": "/Users/you/plugins/custom-woo-checkout",
    "version": "1.2.0",
    "hasPro": false,
    "textDomain": "custom-woo-checkout",
    "requiresAtLeast": "6.0",
    "testedUpTo": "6.7",
    "requiresPHP": "8.0"
  },
  "environment": {
    "testUrl": "http://localhost:8881",
    "wpEnvPort": 8881,
    "adminUser": "admin",
    "adminPass": "password"
  },
  "companions": ["woocommerce"],
  "qaFocus": {
    "priority": "full",
    "testAreas": ["activation", "woocommerce-checkout", "rest-api-auth", "security"]
  },
  "thresholds": {
    "lighthouse": { "performance": 80, "accessibility": 90 },
    "dbQueriesPerPage": 50
  }
}
```

### SEO Plugin

```json
{
  "plugin": {
    "name": "My SEO Plugin",
    "slug": "my-seo-plugin",
    "type": "seo",
    "path": "/Users/you/plugins/my-seo-plugin",
    "version": "5.1.0",
    "hasPro": true,
    "proZip": "/Users/you/plugins/my-seo-plugin-pro.zip",
    "textDomain": "my-seo-plugin",
    "requiresAtLeast": "5.5",
    "testedUpTo": "6.7",
    "requiresPHP": "7.4"
  },
  "environment": {
    "testUrl": "http://localhost:8881",
    "wpEnvPort": 8881,
    "adminUser": "admin",
    "adminPass": "password"
  },
  "competitors": ["wordpress-seo", "rank-math-seo"],
  "qaFocus": {
    "priority": "full",
    "testAreas": ["activation", "admin-panel-load", "frontend-output", "sitemaps", "schema"]
  },
  "thresholds": {
    "lighthouse": { "performance": 85, "seo": 95 },
    "dbQueriesPerPage": 40
  }
}
```

### REST API / Headless Plugin

```json
{
  "plugin": {
    "name": "Custom REST API Extensions",
    "slug": "custom-rest-api",
    "type": "rest-api",
    "path": "/Users/you/plugins/custom-rest-api",
    "version": "1.0.0",
    "hasPro": false,
    "textDomain": "custom-rest-api",
    "requiresAtLeast": "5.5",
    "testedUpTo": "6.7",
    "requiresPHP": "8.0"
  },
  "environment": {
    "testUrl": "http://localhost:8881",
    "wpEnvPort": 8881,
    "adminUser": "admin",
    "adminPass": "password"
  },
  "qaFocus": {
    "priority": "full",
    "testAreas": ["activation", "rest-api-auth", "security"]
  },
  "thresholds": {
    "lighthouse": { "performance": 90 },
    "dbQueriesPerPage": 30
  }
}
```

---

## 10. Using Config Without a File

You can pass all config as CLI arguments and environment variables instead of a JSON file:

```bash
# Plugin path via CLI flag
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode full

# WordPress URL via env var
WP_TEST_URL=http://localhost:8882 bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin

# Admin credentials via env vars
WP_ADMIN_USER=admin WP_ADMIN_PASS=secret bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin
```

Environment variables always override `qa.config.json` values.

---

**Next**: [docs/03-test-environment.md](03-test-environment.md) — spin up a WordPress test site for your plugin.
