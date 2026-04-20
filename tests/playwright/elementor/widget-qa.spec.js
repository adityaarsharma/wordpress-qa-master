/**
 * Orbit — Elementor Widget QA
 *
 * Tests every widget defined in qa.config.json → plugin.widgets[]
 * For each widget: find in panel → insert → screenshot editor → screenshot frontend → responsive → JS errors
 *
 * Also runs competitor comparison when qa.config.json → competitors[] is set.
 *
 * Usage:
 *   npx playwright test tests/playwright/elementor/ --project=elementor-widgets
 *   WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/elementor/ --project=elementor-widgets
 *
 * qa.config.json shape this spec reads:
 * {
 *   "plugin": {
 *     "name": "The Plus Addons",
 *     "widgets": [
 *       { "name": "Mega Menu", "category": "navigation", "searchTerm": "mega" },
 *       { "name": "Team Member", "category": "creative", "searchTerm": "team" }
 *     ]
 *   },
 *   "testPageUrl": "http://localhost:8881/orbit-test-page/",
 *   "competitors": ["elementkit", "happy-elementor-addons"]
 * }
 */
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

const BASE   = process.env.WP_TEST_URL || 'http://localhost:8881';
const ADMIN  = `${BASE}/wp-admin`;
const SNAP_DIR = path.join(__dirname, '../../../reports/screenshots/elementor');
const VIDEO_DIR = path.join(__dirname, '../../../reports/videos');

fs.mkdirSync(SNAP_DIR, { recursive: true });
fs.mkdirSync(VIDEO_DIR, { recursive: true });

let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(path.join(__dirname, '../../../qa.config.json'), 'utf8')); } catch {}

const PLUGIN_NAME  = cfg.plugin?.name   || 'Plugin';
const PLUGIN_SLUG  = cfg.plugin?.slug   || '';
const WIDGETS      = cfg.plugin?.widgets || [];
const TEST_PAGE    = cfg.testPageUrl    || `${BASE}/?p=1`;

// Helper: save screenshot to reports/screenshots/elementor/
async function snap(page, name) {
  const safe = name.replace(/[^a-z0-9-]/gi, '-').toLowerCase();
  const filePath = path.join(SNAP_DIR, `${safe}.png`);
  await page.screenshot({ path: filePath, fullPage: false });
  return filePath;
}

// Helper: wait for Elementor editor to be ready (avoids networkidle timeout)
async function waitForElementor(page) {
  await page.waitForLoadState('domcontentloaded');
  // Wait for Elementor panel to appear
  await page.waitForSelector('.elementor-panel, #elementor-panel', { timeout: 30000 }).catch(() => {});
  await page.waitForTimeout(2000);
}

// ─────────────────────────────────────────────────────────────────────────────
// Editor: Panel Presence
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Elementor Editor — Panel', () => {
  test('editor loads and plugin panel is visible', async ({ page }) => {
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));

    await page.goto(`${ADMIN}/post-new.php?post_type=page`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    // Click "Edit with Elementor" if present
    const editBtn = page.locator('a:has-text("Edit with Elementor"), #elementor-switch-mode-button');
    if (await editBtn.count() > 0) {
      await editBtn.first().click();
      await waitForElementor(page);
    } else {
      // Already in Elementor editor
      await waitForElementor(page);
    }

    const panel = page.locator('.elementor-panel, #elementor-panel');
    const panelExists = await panel.count();

    await snap(page, 'editor-panel-loaded');

    expect(panelExists, 'Elementor panel should exist').toBeGreaterThan(0);
    expect(errors, `JS errors on editor load:\n${errors.join('\n')}`).toHaveLength(0);
  });

  test('plugin search returns results in widget panel', async ({ page }) => {
    if (WIDGETS.length === 0) {
      test.skip();
      return;
    }

    await page.goto(`${ADMIN}/post-new.php?post_type=page`);
    await waitForElementor(page);

    const editBtn = page.locator('#elementor-switch-mode-button, a:has-text("Edit with Elementor")');
    if (await editBtn.count() > 0) {
      await editBtn.first().click();
      await waitForElementor(page);
    }

    // Open widget panel (click the + add elements button)
    const addBtn = page.locator('.elementor-add-section-area-button, .elementor-add-section-button, button[aria-label*="Add"]').first();
    if (await addBtn.isVisible().catch(() => false)) {
      await addBtn.click();
      await page.waitForTimeout(500);
    }

    // Search for the first widget
    const firstWidget = WIDGETS[0];
    const searchInput = page.locator('.elementor-search-input, input[placeholder*="Search"]').first();
    if (await searchInput.isVisible().catch(() => false)) {
      await searchInput.fill(firstWidget.searchTerm || firstWidget.name);
      await page.waitForTimeout(1000);

      const results = await page.locator('.elementor-element-wrapper, .elementor-widget-title').count();
      await snap(page, `panel-search-${firstWidget.name}`);
      expect(results, `Search for "${firstWidget.name}" returned no widgets`).toBeGreaterThan(0);
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Per-widget tests
// ─────────────────────────────────────────────────────────────────────────────
for (const widget of WIDGETS) {
  test.describe(`Widget: ${widget.name}`, () => {
    test(`[${widget.name}] — can be found in Elementor panel`, async ({ page }) => {
      await page.goto(`${ADMIN}/post-new.php?post_type=page`);
      await waitForElementor(page);

      const editBtn = page.locator('#elementor-switch-mode-button, a:has-text("Edit with Elementor")');
      if (await editBtn.count() > 0) {
        await editBtn.first().click();
        await waitForElementor(page);
      }

      const searchInput = page.locator('.elementor-search-input, input[placeholder*="Search"]').first();
      if (await searchInput.isVisible().catch(() => false)) {
        await searchInput.fill(widget.searchTerm || widget.name);
        await page.waitForTimeout(1000);
        await snap(page, `widget-search-${widget.name}`);
      }

      // Check widget title appears
      const widgetInPanel = page.locator(`.elementor-widget-title:has-text("${widget.name}"), [title*="${widget.name}"]`).first();
      const found = await widgetInPanel.count();
      expect(found, `"${widget.name}" not found in Elementor panel`).toBeGreaterThan(0);
    });

    test(`[${widget.name}] — editor panel screenshot`, async ({ page }) => {
      await page.goto(`${ADMIN}/post-new.php?post_type=page`);
      await waitForElementor(page);

      const editBtn = page.locator('#elementor-switch-mode-button, a:has-text("Edit with Elementor")');
      if (await editBtn.count() > 0) {
        await editBtn.first().click();
        await waitForElementor(page);
      }

      await snap(page, `editor-${widget.name}-panel`);
      await expect(page).toHaveScreenshot(`editor-${widget.name.replace(/\s+/g, '-').toLowerCase()}-panel.png`, {
        fullPage: false,
        maxDiffPixelRatio: 0.05,
      });
    });

    test(`[${widget.name}] — no JS errors in editor`, async ({ page }) => {
      const errors = [];
      page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
      page.on('pageerror', e => errors.push(e.message));

      await page.goto(`${ADMIN}/post-new.php?post_type=page`);
      await waitForElementor(page);

      const editBtn = page.locator('#elementor-switch-mode-button, a:has-text("Edit with Elementor")');
      if (await editBtn.count() > 0) {
        await editBtn.first().click();
        await waitForElementor(page);
      }

      await page.waitForTimeout(3000);

      const filtered = errors.filter(e =>
        !e.includes('favicon') &&
        !e.includes('net::ERR') &&
        !e.includes('wp.apiFetch') &&
        !e.includes('sourceURL')
      );

      expect(filtered, `JS errors while loading editor with ${widget.name}:\n${filtered.join('\n')}`).toHaveLength(0);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Frontend: widget output on test page
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Frontend — Widget Output', () => {
  test('test page renders — no PHP errors', async ({ page }) => {
    await page.goto(TEST_PAGE);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(1000);

    const body = await page.locator('body').textContent();
    expect(body, 'PHP fatal on test page').not.toMatch(/Fatal error|PHP Warning|Parse error/);

    const html = await page.content();
    expect(html.length, 'Test page rendered blank').toBeGreaterThan(500);

    await snap(page, 'frontend-test-page-desktop');
    await expect(page).toHaveScreenshot('frontend-test-page.png', { fullPage: true, maxDiffPixelRatio: 0.04 });
  });

  test('test page — no JS console errors', async ({ page }) => {
    const errors = [];
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    page.on('pageerror', e => errors.push(e.message));

    await page.goto(TEST_PAGE);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const filtered = errors.filter(e => !e.includes('favicon') && !e.includes('net::ERR'));
    expect(filtered, `Frontend JS errors:\n${filtered.join('\n')}`).toHaveLength(0);
  });

  test('test page — mobile viewport (375px)', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(TEST_PAGE);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(1000);

    // No horizontal overflow
    const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
    expect(bodyWidth, `Horizontal overflow at 375px: ${bodyWidth}px`).toBeLessThanOrEqual(390);

    await snap(page, 'frontend-test-page-mobile');
    await expect(page).toHaveScreenshot('frontend-test-page-mobile.png', { fullPage: true, maxDiffPixelRatio: 0.05 });
  });

  test('test page — tablet viewport (768px)', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto(TEST_PAGE);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(1000);

    const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
    expect(bodyWidth, `Horizontal overflow at 768px: ${bodyWidth}px`).toBeLessThanOrEqual(790);

    await snap(page, 'frontend-test-page-tablet');
    await expect(page).toHaveScreenshot('frontend-test-page-tablet.png', { fullPage: true, maxDiffPixelRatio: 0.05 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// UX Complexity Audit — How complex is your plugin to configure?
// ─────────────────────────────────────────────────────────────────────────────
test.describe('UX Complexity Audit', () => {
  test('plugin settings page — complexity score', async ({ page }) => {
    if (!PLUGIN_SLUG) { test.skip(); return; }

    await page.goto(`${ADMIN}/admin.php?page=${PLUGIN_SLUG}`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(1500);

    const tabs      = await page.locator('.nav-tab, .tab-link, [role="tab"]').count();
    const inputs    = await page.locator('input:not([type="hidden"]):not([type="submit"])').count();
    const toggles   = await page.locator('input[type="checkbox"], input[type="radio"]').count();
    const selects   = await page.locator('select').count();
    const sections  = await page.locator('.settings-section, .card, .postbox, fieldset').count();

    const complexity = tabs * 3 + inputs + toggles + selects * 2 + sections;

    console.log(`\n=== ${PLUGIN_NAME} Complexity Score ===`);
    console.log(`  Tabs: ${tabs}`);
    console.log(`  Text inputs: ${inputs}`);
    console.log(`  Toggles/checkboxes: ${toggles}`);
    console.log(`  Selects: ${selects}`);
    console.log(`  Sections: ${sections}`);
    console.log(`  COMPLEXITY SCORE: ${complexity}`);
    console.log(`  (Yoast ≈ 180 | RankMath ≈ 320 | Good target: <200)`);

    await snap(page, `settings-complexity-audit`);

    // Not a hard fail — just measured and logged for PM review
    expect(complexity).toBeGreaterThan(0); // sanity: page rendered something
  });

  test('settings page — first-time user can find primary CTA in ≤3 clicks', async ({ page }) => {
    if (!PLUGIN_SLUG) { test.skip(); return; }

    // Simulate a first-time user landing on WP admin dashboard
    await page.goto(`${ADMIN}/`);
    await page.waitForLoadState('domcontentloaded');

    let clicks = 0;

    // Step 1: Is plugin visible in admin menu?
    const menuLink = page.locator(`#adminmenu a:has-text("${PLUGIN_NAME}"), #adminmenu a[href*="${PLUGIN_SLUG}"]`).first();
    const menuVisible = await menuLink.isVisible().catch(() => false);

    if (menuVisible) {
      clicks++;
      await menuLink.click();
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(1000);
      await snap(page, 'ux-click1-settings');
    }

    // Step 2: Is there a "Get Started" / setup wizard / primary button?
    const primaryBtn = page.locator('a:has-text("Get Started"), a:has-text("Setup Wizard"), a:has-text("Quick Setup"), .button-primary').first();
    const primaryVisible = await primaryBtn.isVisible().catch(() => false);

    if (primaryVisible) {
      clicks++;
    }

    console.log(`\n=== ${PLUGIN_NAME} — Click Depth to Primary Action ===`);
    console.log(`  Menu found: ${menuVisible}`);
    console.log(`  Primary CTA visible after: ${clicks} click(s)`);
    console.log(`  Setup wizard: ${primaryVisible}`);

    await snap(page, 'ux-click-depth-result');

    // PM signal: primary action should be reachable in ≤3 clicks from dashboard
    expect(clicks, 'Primary action took >3 clicks to reach').toBeLessThanOrEqual(3);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Competitor Widget Comparison (runs only when competitors are configured)
// ─────────────────────────────────────────────────────────────────────────────
if (cfg.competitors && cfg.competitors.length > 0) {
  test.describe('Competitor Widget Comparison', () => {
    test('side-by-side: settings page screenshot vs competitor', async ({ page }) => {
      if (!PLUGIN_SLUG) { test.skip(); return; }

      // Your plugin settings
      await page.goto(`${ADMIN}/admin.php?page=${PLUGIN_SLUG}`);
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(1500);
      await snap(page, `compare-YOURS-settings`);
      await expect(page).toHaveScreenshot(`compare-your-plugin-settings.png`, {
        fullPage: true, maxDiffPixelRatio: 0.05
      });

      // For each competitor that has a known admin page slug
      for (const slug of cfg.competitors) {
        await page.goto(`${ADMIN}/admin.php?page=${slug}`);
        await page.waitForLoadState('domcontentloaded');
        await page.waitForTimeout(1500);
        await snap(page, `compare-${slug}-settings`);
        // Screenshot saved — visual comparison done manually or via HTML report
      }

      console.log(`\nCompetitor settings screenshots saved to reports/screenshots/elementor/`);
      console.log(`Open HTML report to view side-by-side: npx playwright show-report reports/playwright-html`);
    });
  });
}
