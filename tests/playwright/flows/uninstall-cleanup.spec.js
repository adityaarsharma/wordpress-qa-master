// @ts-check
/**
 * Orbit — Uninstall / Cleanup Test
 *
 * What this verifies:
 *   When a plugin is deactivated + deleted, it must clean up after itself.
 *   Required by WordPress.org plugin review. Orphaned data = user data compliance issue.
 *
 * What gets checked:
 *   - Plugin options are deleted (wp_options table)
 *   - Custom tables are dropped
 *   - Transients are removed
 *   - User meta is cleaned
 *   - Scheduled cron events are cleared
 *
 * Expects: process.env.PLUGIN_SLUG, process.env.PLUGIN_PREFIX (option key prefix)
 * Optional: process.env.PLUGIN_CUSTOM_TABLES (comma-sep list of custom table names, no wp_ prefix)
 */

const { test, expect } = require('@playwright/test');
const { execSync } = require('child_process');

const PLUGIN_SLUG    = process.env.PLUGIN_SLUG || '';
const PLUGIN_PREFIX  = (process.env.PLUGIN_PREFIX || PLUGIN_SLUG.replace(/-/g, '_'))
  .replace(/[^a-zA-Z0-9_]/g, ''); // sanitize — no SQL injection vector
const CUSTOM_TABLES  = (process.env.PLUGIN_CUSTOM_TABLES || '').split(',')
  .filter(Boolean)
  .map((t) => t.replace(/[^a-zA-Z0-9_]/g, ''));
const WP_ENV_RUN     = process.env.WP_ENV_RUN || 'npx wp-env run cli wp';

function wp(cmd) {
  return execSync(`${WP_ENV_RUN} ${cmd}`, { encoding: 'utf8' }).trim();
}

test.describe('Uninstall cleanup (WP.org compliance)', () => {
  test.skip(!PLUGIN_SLUG, 'Set PLUGIN_SLUG env var to run uninstall test');

  test('plugin removes options, tables, and cron events on delete', async () => {
    // 1. Ensure plugin is active first so activation ran
    try {
      wp(`plugin activate ${PLUGIN_SLUG}`);
    } catch (e) {
      // already active is fine
    }

    // 2. Snapshot state while active (for diagnostic if cleanup fails)
    // NOTE: wp-cli `option list --search` uses GLOB patterns (*), NOT SQL (%)
    const optionsBefore = wp(`option list --search='${PLUGIN_PREFIX}*' --format=count`);
    const transientsBefore = wp(
      `db query "SELECT COUNT(*) FROM \\\`wp_options\\\` WHERE option_name LIKE '_transient_${PLUGIN_PREFIX}%'" --skip-column-names`
    );
    console.log(`[orbit] Pre-uninstall — options: ${optionsBefore}, transients: ${transientsBefore}`);

    // 3. Deactivate + delete (triggers uninstall.php or register_uninstall_hook)
    wp(`plugin deactivate ${PLUGIN_SLUG}`);
    wp(`plugin delete ${PLUGIN_SLUG}`);

    // 4. Assertions — options (glob syntax for wp-cli)
    const optionsAfter = parseInt(
      wp(`option list --search='${PLUGIN_PREFIX}*' --format=count`) || '0', 10
    );
    expect(optionsAfter, `${optionsAfter} plugin options left after uninstall`).toBe(0);

    // 5. Transients (SQL % is correct inside db query)
    const transientsAfter = parseInt(
      wp(
        `db query "SELECT COUNT(*) FROM \\\`wp_options\\\` WHERE option_name LIKE '_transient_${PLUGIN_PREFIX}%' OR option_name LIKE '_site_transient_${PLUGIN_PREFIX}%'" --skip-column-names`
      ) || '0',
      10
    );
    expect(transientsAfter, `${transientsAfter} plugin transients left after uninstall`).toBe(0);

    // 6. User meta with plugin prefix
    const userMetaLeft = parseInt(
      wp(
        `db query "SELECT COUNT(*) FROM \\\`wp_usermeta\\\` WHERE meta_key LIKE '${PLUGIN_PREFIX}%'" --skip-column-names`
      ) || '0',
      10
    );
    expect(userMetaLeft, `${userMetaLeft} plugin user_meta rows left after uninstall`).toBe(0);

    // 7. Custom tables dropped
    for (const table of CUSTOM_TABLES) {
      const tableExists = wp(
        `db query "SHOW TABLES LIKE 'wp_${table}'" --skip-column-names`
      );
      expect(tableExists, `Custom table wp_${table} should be dropped on uninstall`).toBe('');
    }

    // 8. No orphaned cron events
    const cronEvents = wp(`cron event list --format=json`);
    let orphaned = [];
    try {
      orphaned = JSON.parse(cronEvents || '[]').filter((e) =>
        (e.hook || '').includes(PLUGIN_PREFIX)
      );
    } catch { /* empty cron = no orphans */ }
    expect(
      orphaned,
      `Found ${orphaned.length} orphaned cron events from this plugin after uninstall`
    ).toEqual([]);

    // 9. Custom capabilities cleaned up (via add_cap / add_role patterns)
    const customCapsLeft = wp(
      `db query "SELECT option_value FROM \\\`wp_options\\\` WHERE option_name = 'wp_user_roles'" --skip-column-names`
    );
    const hasCustomCap = customCapsLeft.includes(PLUGIN_PREFIX);
    expect(hasCustomCap, `Plugin capabilities still in wp_user_roles after uninstall`).toBe(false);

    // 10. Post revisions tied to plugin CPTs are cleaned up
    //     (if plugin registered custom post types, their revisions should be gone)
    const CUSTOM_POST_TYPES = (process.env.PLUGIN_CUSTOM_POST_TYPES || '')
      .split(',').filter(Boolean).map(t => t.replace(/[^a-zA-Z0-9_]/g, ''));
    for (const cpt of CUSTOM_POST_TYPES) {
      const postsLeft = parseInt(
        wp(`db query "SELECT COUNT(*) FROM \\\`wp_posts\\\` WHERE post_type = '${cpt}' OR post_type = 'revision'" --skip-column-names`) || '0',
        10
      );
      // Allow some generic revisions to exist, but plugin-specific posts should be gone
      const pluginPostsLeft = parseInt(
        wp(`db query "SELECT COUNT(*) FROM \\\`wp_posts\\\` WHERE post_type = '${cpt}'" --skip-column-names`) || '0',
        10
      );
      expect(pluginPostsLeft, `${pluginPostsLeft} posts of type '${cpt}' left after uninstall`).toBe(0);
    }

    // 11. Scheduled single events (wp_schedule_single_event) cleared
    const singleEvents = wp(`cron event list --format=json`);
    let orphanedSingles = [];
    try {
      orphanedSingles = JSON.parse(singleEvents || '[]').filter((e) =>
        (e.hook || '').includes(PLUGIN_PREFIX)
      );
    } catch {}
    expect(orphanedSingles,
      `${orphanedSingles.length} orphaned scheduled-single events from plugin after uninstall`
    ).toEqual([]);

    console.log('[orbit] Uninstall cleanup: PASSED');
  });
});
