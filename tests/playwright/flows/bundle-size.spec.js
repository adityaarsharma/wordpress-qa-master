// @ts-check
/**
 * Orbit — Per-Page Bundle Size Enforcement
 *
 * Matches plugin-check `enqueued_scripts_size` / `enqueued_styles_size` rules.
 * Step 4 of the gauntlet measures total plugin JS/CSS weight across the whole
 * plugin — but the REAL question is: how many bytes does the user download
 * when loading page X?
 *
 * This spec navigates each admin page + homepage and asserts per-page totals.
 *
 * Thresholds (from plugin-check defaults + pro team consensus):
 *   - Admin pages:   total JS < 500KB gzip, total CSS < 200KB gzip
 *   - Frontend:      total JS < 150KB gzip, total CSS < 100KB gzip
 *   - Login page:    plugin JS/CSS = 0 (see check-login-assets.sh)
 *
 * Usage:
 *   PLUGIN_SLUG=my-plugin PLUGIN_ADMIN_SLUG=my-plugin-settings \
 *     npx playwright test bundle-size.spec.js
 */

const { test, expect } = require('@playwright/test');
const { attachConsoleErrorGuard } = require('../helpers');

const PLUGIN_SLUG = (process.env.PLUGIN_SLUG || '').replace(/[^a-zA-Z0-9_-]/g, '');
const ADMIN_SLUG  = process.env.PLUGIN_ADMIN_SLUG || PLUGIN_SLUG;

const ADMIN_JS_KB_LIMIT   = parseInt(process.env.ADMIN_JS_KB_LIMIT   || '500', 10);
const ADMIN_CSS_KB_LIMIT  = parseInt(process.env.ADMIN_CSS_KB_LIMIT  || '200', 10);
const FRONT_JS_KB_LIMIT   = parseInt(process.env.FRONT_JS_KB_LIMIT   || '150', 10);
const FRONT_CSS_KB_LIMIT  = parseInt(process.env.FRONT_CSS_KB_LIMIT  || '100', 10);

async function measurePluginAssets(page, pluginSlug) {
  const requests = [];
  page.on('response', async (res) => {
    const url = res.url();
    if (!url.includes(`/wp-content/plugins/${pluginSlug}/`)) return;
    const ct = (res.headers()['content-type'] || '').toLowerCase();
    try {
      const body = await res.body();
      requests.push({
        url,
        bytes: body.length,
        type: ct.includes('javascript') ? 'js' : ct.includes('css') ? 'css' : 'other',
      });
    } catch { /* resource already closed */ }
  });
  return requests;
}

test.describe('Per-page plugin bundle size', () => {
  test.skip(!PLUGIN_SLUG, 'Set PLUGIN_SLUG');

  test(`admin page "${ADMIN_SLUG}" stays under limits`, async ({ page }) => {
    const guard = attachConsoleErrorGuard(page);
    const assets = await measurePluginAssets(page, PLUGIN_SLUG);

    await page.goto(`/wp-admin/admin.php?page=${ADMIN_SLUG}`);
    await page.waitForLoadState('networkidle');

    const jsBytes  = assets.filter(a => a.type === 'js').reduce((n, a) => n + a.bytes, 0);
    const cssBytes = assets.filter(a => a.type === 'css').reduce((n, a) => n + a.bytes, 0);
    const jsKB  = Math.round(jsBytes / 1024);
    const cssKB = Math.round(cssBytes / 1024);

    console.log(`[orbit] Admin ${ADMIN_SLUG}: JS=${jsKB}KB, CSS=${cssKB}KB`);

    expect(jsKB,
      `Admin page JS ${jsKB}KB exceeds limit ${ADMIN_JS_KB_LIMIT}KB — split, defer, or conditionally load`
    ).toBeLessThan(ADMIN_JS_KB_LIMIT);

    expect(cssKB,
      `Admin page CSS ${cssKB}KB exceeds limit ${ADMIN_CSS_KB_LIMIT}KB — split per section`
    ).toBeLessThan(ADMIN_CSS_KB_LIMIT);

    guard.assertClean(`bundle: ${ADMIN_SLUG}`);
  });

  test('frontend homepage plugin bundle under limit', async ({ page }) => {
    const guard = attachConsoleErrorGuard(page);
    const assets = await measurePluginAssets(page, PLUGIN_SLUG);

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const jsBytes  = assets.filter(a => a.type === 'js').reduce((n, a) => n + a.bytes, 0);
    const cssBytes = assets.filter(a => a.type === 'css').reduce((n, a) => n + a.bytes, 0);
    const jsKB  = Math.round(jsBytes / 1024);
    const cssKB = Math.round(cssBytes / 1024);

    console.log(`[orbit] Frontend: JS=${jsKB}KB, CSS=${cssKB}KB`);

    expect(jsKB,
      `Frontend JS ${jsKB}KB > ${FRONT_JS_KB_LIMIT}KB — front-end should load minimal plugin code. Consider only loading via conditional enqueue.`
    ).toBeLessThan(FRONT_JS_KB_LIMIT);

    expect(cssKB,
      `Frontend CSS ${cssKB}KB > ${FRONT_CSS_KB_LIMIT}KB`
    ).toBeLessThan(FRONT_CSS_KB_LIMIT);

    guard.assertClean('bundle: frontend /');
  });

  test('login page loads ZERO plugin assets', async ({ page }) => {
    const assets = await measurePluginAssets(page, PLUGIN_SLUG);
    await page.goto('/wp-login.php');
    await page.waitForLoadState('networkidle');

    const leaked = assets.filter(a => a.type === 'js' || a.type === 'css');
    expect(leaked.length,
      `Login page leaked ${leaked.length} plugin asset(s):\n${leaked.slice(0, 3).map(a => '  ' + a.url).join('\n')}`
    ).toBe(0);
  });

  test('script loading strategy: non-critical scripts use defer/async', async ({ page }) => {
    // plugin-check `non_blocking_scripts` rule
    await page.goto(`/wp-admin/admin.php?page=${ADMIN_SLUG}`);
    await page.waitForLoadState('networkidle');

    const blockingScripts = await page.evaluate((slug) => {
      const scripts = Array.from(document.querySelectorAll(`script[src*="/wp-content/plugins/${slug}/"]`));
      return scripts
        .filter(s => {
          const src = s.getAttribute('src') || '';
          // Inline head scripts with no defer/async = blocking
          return !s.hasAttribute('defer') && !s.hasAttribute('async') && s.type !== 'module';
        })
        .map(s => s.getAttribute('src') || '');
    }, PLUGIN_SLUG);

    if (blockingScripts.length > 3) {
      console.warn(`[orbit] ${blockingScripts.length} blocking scripts on ${ADMIN_SLUG}:`);
      blockingScripts.slice(0, 5).forEach(s => console.warn(`   ${s}`));
    }

    // Soft check — warn not fail
    expect(blockingScripts.length,
      `${blockingScripts.length} blocking (non-defer, non-async, non-module) scripts. Consider wp_script_add_data($handle, 'strategy', 'defer').`
    ).toBeLessThanOrEqual(5);
  });
});
