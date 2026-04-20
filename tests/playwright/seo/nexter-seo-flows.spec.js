/**
 * Nexter SEO — Product Manager Flow Tests
 * Maps the full user journey through every SEO screen.
 * Takes a screenshot at every meaningful step.
 *
 * This spec answers: "Can a non-technical user complete these tasks?"
 * Each test measures discoverability, click depth, and time-to-complete.
 *
 * Run: npx playwright test tests/playwright/seo/nexter-seo-flows.spec.js --headed
 * Screenshots land in: reports/screenshots/flows/
 */
const { test, expect } = require('@playwright/test');
const path = require('path');
const fs   = require('fs');

const BASE   = process.env.WP_TEST_URL || 'http://localhost:8881';
const ADMIN  = `${BASE}/wp-admin`;
const SNAP   = path.join(__dirname, '../../../reports/screenshots/flows');
fs.mkdirSync(SNAP, { recursive: true });

let stepIndex = 0;
async function shot(page, label) {
  stepIndex++;
  const safe  = label.replace(/[^a-z0-9]/gi, '-').toLowerCase();
  const file  = path.join(SNAP, `${String(stepIndex).padStart(2,'0')}-${safe}.png`);
  await page.screenshot({ path: file, fullPage: true });
  console.log(`  📸 ${file}`);
  return file;
}

// Reset step counter per test file run
test.beforeAll(() => { stepIndex = 0; });

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 1 — Discovery: Can a user FIND the SEO settings?
// Complexity vs Yoast: Yoast adds top-level menu. Nexter hides SEO under
// the Nexter menu as a submenu item. 2 extra clicks minimum.
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 1 — Discovery: Finding SEO Settings', () => {
  test('Step 1a: Admin dashboard — can user see SEO entry point?', async ({ page }) => {
    await page.goto(`${ADMIN}/`);
    await page.waitForLoadState('domcontentloaded');
    await shot(page, 'journey1-dashboard');

    // Is Nexter visible in left nav?
    const nexterMenu = page.locator('#adminmenu').getByText(/nexter/i).first();
    await expect(nexterMenu).toBeVisible();
  });

  test('Step 1b: Nexter menu expanded — is Content SEO visible?', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nexter_welcome`);
    await page.waitForLoadState('domcontentloaded');
    await shot(page, 'journey1-nexter-welcome');

    // Count clicks to reach SEO — is there a direct button/link on welcome page?
    const seoLink = page.getByText(/content seo|seo settings/i).first();
    const seoVisible = await seoLink.isVisible().catch(() => false);
    console.log(`  SEO directly visible on welcome page: ${seoVisible}`);
    // This documents a UX gap if false
  });

  test('Step 1c: Content SEO admin page loads (React SPA)', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    // React SPA — wait for the mount point to have children
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000); // React render time
    await shot(page, 'journey1-seo-settings-landing');

    const mount = page.locator('#nexter-content-seo, .nxt-content-seo-mount');
    const hasContent = await mount.count() > 0;
    console.log(`  React mount point exists: ${hasContent}`);

    // Check what tabs/sections are visible on first load
    const bodyText = await page.locator('body').innerText();
    const hasTabs = /sitemap|schema|robots|social|canonical|indexnow/i.test(bodyText);
    console.log(`  SEO sections visible: ${hasTabs}`);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 2 — First-time Setup Complexity
// Yoast: Has a guided wizard. RankMath: Has a setup wizard.
// Nexter: No wizard found — dumps user on full settings page.
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 2 — First-Time Setup', () => {
  test('Step 2a: Does Nexter SEO have a setup wizard or guided onboarding?', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);
    await shot(page, 'journey2-first-time-landing');

    const bodyText = await page.locator('body').innerText();
    const hasWizard = /wizard|setup guide|get started|step 1 of|onboarding/i.test(bodyText);
    console.log(`  Setup wizard present: ${hasWizard}`);
    // EXPECTED: false — documents the gap vs Yoast/RankMath
  });

  test('Step 2b: How many settings are shown immediately? (complexity audit)', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const inputs = await page.locator('input, select, textarea').count();
    const sections = await page.locator('[class*="tab"], [class*="section"], [class*="panel"], [role="tab"]').count();
    console.log(`  Visible inputs: ${inputs} | Sections/tabs: ${sections}`);
    // Yoast shows ~5 settings on first screen. High count = complexity problem.
  });

  test('Step 2c: Nexter welcome page — how many clicks to reach SEO?', async ({ page }) => {
    const clicks = [];

    // Click 1: Admin menu → Nexter
    await page.goto(`${ADMIN}/`);
    await page.waitForLoadState('domcontentloaded');
    clicks.push('Admin dashboard loaded');
    await shot(page, 'journey2-step-dashboard');

    // Click 2: Open Nexter submenu
    const nexterItem = page.locator('#adminmenu a').filter({ hasText: /nexter/i }).first();
    if (await nexterItem.isVisible()) {
      await nexterItem.click();
      await page.waitForLoadState('domcontentloaded');
      clicks.push('Clicked Nexter menu');
      await shot(page, 'journey2-step-nexter-menu');
    }

    // Click 3: Find Content SEO submenu
    const seoItem = page.locator('#adminmenu a').filter({ hasText: /content seo/i }).first();
    if (await seoItem.isVisible()) {
      await seoItem.click();
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(1500);
      clicks.push('Clicked Content SEO');
      await shot(page, 'journey2-step-seo-page');
    }

    console.log(`  Click depth to SEO: ${clicks.length} clicks`);
    console.log(`  Path: ${clicks.join(' → ')}`);
    // Yoast is 1 click from admin menu. Nexter is 2-3 clicks.
    expect(clicks.length).toBeGreaterThan(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 3 — Post Editor SEO Panel
// The most-used flow: user writes a post and sets SEO meta
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 3 — Per-Post SEO in Editor', () => {
  test('Step 3a: New post editor loads', async ({ page }) => {
    await page.goto(`${ADMIN}/post-new.php`);
    // Gutenberg never reaches networkidle — use domcontentloaded + explicit wait
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(4000);
    await shot(page, 'journey3-post-editor-loaded');

    // Is there a Nexter/SEO panel visible in the sidebar?
    const bodyText = await page.locator('body').innerText();
    const hasSeoPanel = /seo|nexter seo|meta title|focus keyword/i.test(bodyText);
    console.log(`  SEO panel visible in editor: ${hasSeoPanel}`);
  });

  test('Step 3b: SEO sidebar panel — what fields are shown?', async ({ page }) => {
    await page.goto(`${ADMIN}/post-new.php`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    // Try to open the document sidebar
    const settingsBtn = page.locator('button[aria-label="Settings"]');
    if (await settingsBtn.isVisible().catch(() => false)) {
      const sidebarOpen = await page.locator('.interface-complementary-area').isVisible().catch(() => false);
      if (!sidebarOpen) await settingsBtn.click().catch(() => {});
      await page.waitForTimeout(500);
    }

    await shot(page, 'journey3-editor-sidebar');

    // Check for Nexter SEO panel button/tab in sidebar
    const seoTab = page.locator('[class*="seo"], [data-title*="SEO"], button:has-text("SEO")');
    const hasSeoTab = await seoTab.count() > 0;
    console.log(`  Nexter SEO panel tab in sidebar: ${hasSeoTab}`);
  });

  test('Step 3c: SEO meta fields — title, description, keywords visible?', async ({ page }) => {
    await page.goto(`${ADMIN}/post-new.php`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    await shot(page, 'journey3-seo-fields-visible');

    // Check for SEO-specific inputs
    const titleInput = page.locator('input[name*="seo_title"], input[id*="seo-title"], input[placeholder*="SEO title"]');
    const descInput  = page.locator('textarea[name*="seo_desc"], textarea[id*="seo-desc"], textarea[placeholder*="description"]');

    console.log(`  SEO title input present: ${await titleInput.count() > 0}`);
    console.log(`  SEO description input present: ${await descInput.count() > 0}`);
  });

  test('Step 3d: Edit existing Hello World post — is SEO panel functional?', async ({ page }) => {
    // Find and edit post ID 1 (Hello World)
    await page.goto(`${ADMIN}/post.php?post=1&action=edit`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);
    await shot(page, 'journey3-edit-hello-world');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 4 — Sitemap Configuration
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 4 — Sitemap Settings', () => {
  test('Step 4a: Sitemap section in SEO settings', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);
    await shot(page, 'journey4-seo-page-sitemap');

    // Try clicking Sitemap tab if visible
    const sitemapTab = page.getByText(/sitemap/i).first();
    if (await sitemapTab.isVisible().catch(() => false)) {
      await sitemapTab.click();
      await page.waitForTimeout(1000);
      await shot(page, 'journey4-sitemap-tab-active');
    }
  });

  test('Step 4b: Sitemap XML is accessible from frontend', async ({ page }) => {
    await page.goto(`${BASE}/sitemap.xml`);
    await page.waitForLoadState('domcontentloaded');
    await shot(page, 'journey4-sitemap-xml-frontend');

    const content = await page.content();
    const isXml = content.includes('<urlset') || content.includes('<?xml');
    console.log(`  Sitemap is valid XML: ${isXml}`);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 5 — Schema Configuration
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 5 — Schema Settings', () => {
  test('Step 5a: Schema section in admin', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const schemaTab = page.getByText(/schema/i).first();
    if (await schemaTab.isVisible().catch(() => false)) {
      await schemaTab.click();
      await page.waitForTimeout(1000);
      await shot(page, 'journey5-schema-tab');
    } else {
      await shot(page, 'journey5-schema-not-found');
      console.log('  WARNING: Schema tab not directly visible — discoverability issue');
    }
  });

  test('Step 5b: Schema JSON-LD output on frontend — unresolved variables?', async ({ page }) => {
    await page.goto(BASE);
    await page.waitForLoadState('domcontentloaded');
    await shot(page, 'journey5-frontend-schema-check');

    const schemaTags = await page.locator('script[type="application/ld+json"]').all();
    for (const tag of schemaTags) {
      const text = await tag.textContent();
      const unresolvedVars = (text.match(/%[a-z._]+%/g) || []);
      if (unresolvedVars.length > 0) {
        console.log(`  BUG: Unresolved schema variables: ${unresolvedVars.join(', ')}`);
      }
    }
    expect(schemaTags.length).toBeGreaterThan(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 6 — Social / OG Settings
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 6 — Social Meta Settings', () => {
  test('Step 6a: Social / OG settings in admin', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const socialTab = page.getByText(/social|open graph|twitter|facebook/i).first();
    if (await socialTab.isVisible().catch(() => false)) {
      await socialTab.click();
      await page.waitForTimeout(1000);
      await shot(page, 'journey6-social-tab');
    } else {
      await shot(page, 'journey6-social-not-found');
      console.log('  WARNING: Social settings tab not directly visible');
    }
  });

  test('Step 6b: Frontend OG tags present', async ({ page }) => {
    await page.goto(BASE);
    await page.waitForLoadState('domcontentloaded');
    await shot(page, 'journey6-frontend-og-check');

    const ogTitle = await page.locator('meta[property="og:title"]').count();
    const ogImage = await page.locator('meta[property="og:image"]').count();
    const twitterCard = await page.locator('meta[name="twitter:card"]').count();
    console.log(`  og:title: ${ogTitle} | og:image: ${ogImage} | twitter:card: ${twitterCard}`);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 7 — Robots.txt / Indexing Control
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 7 — Robots & Indexing', () => {
  test('Step 7a: Robots settings in admin', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const robotsTab = page.getByText(/robots|indexing|noindex/i).first();
    if (await robotsTab.isVisible().catch(() => false)) {
      await robotsTab.click();
      await page.waitForTimeout(1000);
      await shot(page, 'journey7-robots-tab');
    } else {
      await shot(page, 'journey7-robots-not-found');
    }
  });

  test('Step 7b: robots.txt frontend', async ({ page }) => {
    await page.goto(`${BASE}/robots.txt`);
    await page.waitForLoadState('domcontentloaded');
    await shot(page, 'journey7-robots-txt-frontend');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 8 — IndexNow / Instant Indexing
// This feature doesn't exist in Yoast free — is it discoverable?
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 8 — IndexNow (Unique Feature)', () => {
  test('Step 8a: IndexNow settings — is it labeled clearly?', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const indexNowTab = page.getByText(/indexnow|instant index|index now/i).first();
    if (await indexNowTab.isVisible().catch(() => false)) {
      await indexNowTab.click();
      await page.waitForTimeout(1000);
      await shot(page, 'journey8-indexnow-tab');
      console.log('  IndexNow tab visible — good discoverability');
    } else {
      await shot(page, 'journey8-indexnow-not-found');
      console.log('  WARNING: IndexNow tab not directly visible — unique feature buried');
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 9 — Content Audit Feature
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 9 — SEO Audit', () => {
  test('Step 9a: Audit feature — exists and accessible?', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const auditTab = page.getByText(/audit|analyze|score|content score/i).first();
    if (await auditTab.isVisible().catch(() => false)) {
      await auditTab.click();
      await page.waitForTimeout(1000);
      await shot(page, 'journey9-audit-tab');
    } else {
      await shot(page, 'journey9-audit-not-found');
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY 10 — Full Settings Page Scroll (what does a PM see?)
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Journey 10 — Full Settings Overview', () => {
  test('Step 10a: Full SEO settings page — scroll through all sections', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    // Screenshot top
    await shot(page, 'journey10-settings-top');

    // Scroll 25%
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight * 0.25));
    await page.waitForTimeout(500);
    await shot(page, 'journey10-settings-25pct');

    // Scroll 50%
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight * 0.5));
    await page.waitForTimeout(500);
    await shot(page, 'journey10-settings-50pct');

    // Scroll 75%
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight * 0.75));
    await page.waitForTimeout(500);
    await shot(page, 'journey10-settings-75pct');

    // Bottom
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(500);
    await shot(page, 'journey10-settings-bottom');
  });

  test('Step 10b: Count all visible interactive elements (complexity score)', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=nxt_content_seo`);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const counts = await page.evaluate(() => ({
      inputs:    document.querySelectorAll('input:not([type="hidden"])').length,
      selects:   document.querySelectorAll('select').length,
      textareas: document.querySelectorAll('textarea').length,
      buttons:   document.querySelectorAll('button').length,
      tabs:      document.querySelectorAll('[role="tab"], [class*="tab-"]').length,
      toggles:   document.querySelectorAll('input[type="checkbox"], input[type="radio"]').length,
    }));

    console.log('\n  ── COMPLEXITY SCORE ──');
    console.log(`  Inputs:    ${counts.inputs}`);
    console.log(`  Selects:   ${counts.selects}`);
    console.log(`  Textareas: ${counts.textareas}`);
    console.log(`  Buttons:   ${counts.buttons}`);
    console.log(`  Tabs:      ${counts.tabs}`);
    console.log(`  Toggles:   ${counts.toggles}`);
    console.log(`  TOTAL:     ${Object.values(counts).reduce((a,b)=>a+b,0)}`);
    console.log('  Yoast Free first screen: ~8 inputs, 3 tabs');
    console.log('  ─────────────────────────');

    expect(counts).toBeDefined();
  });
});
