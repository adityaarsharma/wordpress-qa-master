# Writing Playwright Tests for WordPress Plugins

> Practical guide — copy a template, customize, commit. No theory, just recipes.

---

## Step 1 — Copy the Right Template

```bash
# Pick the template closest to your plugin type
cp -r tests/playwright/templates/Page Builder-addon tests/playwright/my-plugin
# or: gutenberg-block, seo-plugin, woocommerce, theme, generic-plugin
```

---

## Step 2 — Open the Spec File

```bash
open tests/playwright/my-plugin/core.spec.js
# or use your editor
```

Every template has comments showing what to change. Look for `<-- CHANGE ME` markers.

---

## Step 3 — Update the Basics

### Plugin slug + admin URL

```js
const PLUGIN_SLUG = 'my-plugin';
const ADMIN_SLUG  = 'my-plugin-settings';  // admin.php?page=my-plugin-settings
```

### Selectors for your plugin's UI

Inspect the element in browser DevTools, copy its CSS selector or data attribute:

```js
// Find in DevTools: right-click element → Inspect → right-click node → Copy → Copy selector
await expect(page.locator('.my-plugin-dashboard__header')).toBeVisible();

// Better: use data-testid attributes in your plugin code
await expect(page.locator('[data-testid="mp-dashboard"]')).toBeVisible();
```

---

## Step 4 — Run in UI Mode (Fastest Way to Write)

```bash
npx playwright test --ui
```

Click your test in the sidebar. Edit the spec file. Save. It auto-reruns. Iterate until green.

---

## Common Recipes

### Check admin menu item exists

```js
test('admin menu has my plugin', async ({ page }) => {
  await page.goto('/wp-admin/');
  await expect(page.locator('li#toplevel_page_my-plugin')).toBeVisible();
});
```

### Check a setting saves

```js
test('setting persists', async ({ page }) => {
  await page.goto('/wp-admin/admin.php?page=my-plugin-settings');
  await page.fill('input[name="mp_api_key"]', 'abc123');
  await page.click('button:has-text("Save Changes")');

  // Reload to verify persistence
  await page.reload();
  await expect(page.locator('input[name="mp_api_key"]')).toHaveValue('abc123');
});
```

### Check no PHP errors on a page

```js
test('no PHP errors on dashboard', async ({ page }) => {
  const phpErrors = [];
  page.on('console', msg => {
    if (/PHP (Warning|Notice|Fatal)/.test(msg.text())) phpErrors.push(msg.text());
  });

  await page.goto('/wp-admin/admin.php?page=my-plugin');
  await page.waitForLoadState('networkidle');

  expect(phpErrors, phpErrors.join('\n')).toHaveLength(0);
});
```

### Check no 404s on plugin assets

```js
test('no 404 on plugin assets', async ({ page }) => {
  const bad = [];
  page.on('response', r => {
    if (r.status() === 404 && r.url().includes('my-plugin')) bad.push(r.url());
  });

  await page.goto('/');
  await page.waitForLoadState('networkidle');

  expect(bad).toHaveLength(0);
});
```

### Check a form submission (AJAX)

```js
test('submit form via AJAX', async ({ page }) => {
  await page.goto('/contact/');

  // Wait for the AJAX response while submitting
  const [response] = await Promise.all([
    page.waitForResponse(r => r.url().includes('/wp-admin/admin-ajax.php')),
    page.click('button[type="submit"]'),
  ]);

  expect(response.status()).toBe(200);
  const data = await response.json();
  expect(data.success).toBe(true);
});
```

### Check mobile responsive behavior

```js
test('mobile has no horizontal scroll', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/');

  const hasScroll = await page.evaluate(() =>
    document.documentElement.scrollWidth > window.innerWidth
  );
  expect(hasScroll).toBe(false);
});
```

### Check visual regression (snapshot)

```js
test('homepage visual baseline', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');
  // First run: creates baseline. Future runs: compare.
  await expect(page).toHaveScreenshot('homepage.png', {
    maxDiffPixelRatio: 0.02,
    fullPage: true
  });
});
```

First run saves the baseline. Subsequent runs diff against it. Tolerance is 2% pixel difference. Update baselines intentionally with:

```bash
npx playwright test --update-snapshots
```

### Check accessibility (axe-core)

```js
const AxeBuilder = require('@axe-core/playwright').default;

test('homepage passes WCAG 2.1 AA', async ({ page }) => {
  await page.goto('/');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .analyze();
  expect(results.violations, JSON.stringify(results.violations, null, 2)).toEqual([]);
});
```

### Page Builder-specific — widget appears in panel

```js
test('My Widget appears in Page Builder panel', async ({ page }) => {
  await page.goto('/wp-admin/post-new.php?post_type=page');
  await page.click('#Page Builder-switch-mode-button');
  await page.waitForSelector('#Page Builder-panel-elements-wrapper');

  await page.fill('#Page Builder-panel-elements-search-input', 'My Widget');
  await expect(
    page.locator('.Page Builder-element:has-text("My Widget")')
  ).toBeVisible();
});
```

### Gutenberg-specific — block appears in inserter

```js
test('My Block in inserter', async ({ page }) => {
  await page.goto('/wp-admin/post-new.php');

  // Close welcome modal if present
  const close = page.locator('button[aria-label="Close"]');
  if (await close.isVisible().catch(() => false)) await close.click();

  await page.click('button[aria-label="Toggle block inserter"]');
  await page.fill('input[placeholder="Search"]', 'My Block');

  await expect(
    page.locator('button.block-editor-block-types-list__item:has-text("My Block")')
  ).toBeVisible();
});
```

### WooCommerce-specific — add to cart flow

```js
test('add product to cart', async ({ page }) => {
  await page.goto('/shop/');
  await page.locator('.add_to_cart_button').first().click();
  await page.waitForTimeout(500);
  await page.goto('/cart/');
  await expect(page.locator('.cart_item')).toHaveCount.toBeGreaterThan(0);
});
```

---

## Advanced Patterns

### Run the same test across multiple pages

```js
const PAGES = ['/', '/shop/', '/blog/', '/contact/'];

for (const path of PAGES) {
  test(`no errors on ${path}`, async ({ page }) => {
    const errors = [];
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    await page.goto(path);
    await page.waitForLoadState('networkidle');
    expect(errors).toHaveLength(0);
  });
}
```

### Capture screenshots across viewports

```js
for (const [vw, vh, name] of [[1440, 900, 'desktop'], [768, 1024, 'tablet'], [375, 667, 'mobile']]) {
  test(`${name} snapshot`, async ({ page }) => {
    await page.setViewportSize({ width: vw, height: vh });
    await page.goto('/');
    await expect(page).toHaveScreenshot(`${name}.png`);
  });
}
```

### Test an admin flow + verify frontend effect

```js
test('create post in admin → appears on frontend', async ({ page }) => {
  // Admin
  await page.goto('/wp-admin/post-new.php');
  await page.fill('h1[aria-label="Add title"]', 'Playwright Test Post');
  await page.click('button:has-text("Publish")', { timeout: 5000 });
  await page.click('button:has-text("Publish"):not([disabled])');
  await page.waitForSelector('a:has-text("View Post")');

  // Frontend
  await page.goto('/?s=Playwright');
  await expect(page.locator('article:has-text("Playwright Test Post")')).toBeVisible();
});
```

### Measure performance in a test

```js
test('dashboard loads under 3s', async ({ page }) => {
  const start = Date.now();
  await page.goto('/wp-admin/admin.php?page=my-plugin');
  await page.waitForLoadState('networkidle');
  const ms = Date.now() - start;

  expect(ms, `Dashboard took ${ms}ms`).toBeLessThan(3000);
});
```

### Intercept network requests to mock external APIs

```js
test('plugin handles API failure gracefully', async ({ page }) => {
  await page.route('https://api.external.com/**', route => {
    route.fulfill({ status: 500, body: 'Server error' });
  });

  await page.goto('/wp-admin/admin.php?page=my-plugin');
  await expect(page.locator('.mp-error-notice')).toContainText('Failed to connect');
});
```

---

## Running Your New Tests

```bash
# Run just your plugin's tests
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/my-plugin/

# Watch them run
npx playwright test tests/playwright/my-plugin/ --headed --slowMo=500

# UI mode (best DX)
npx playwright test --ui

# Specific test by name
npx playwright test -g "no PHP errors"

# Run in all projects (desktop + mobile + tablet)
npx playwright test tests/playwright/my-plugin/ --project=chromium --project=mobile-chrome
```

---

## Debugging Failures

### 1. Read the HTML report

```bash
npx playwright show-report reports/playwright-html
```

Click the failed test → see screenshot, trace, error stack.

### 2. Re-run in debug mode

```bash
npx playwright test tests/playwright/my-plugin/core.spec.js --debug
```

Inspector opens — step through line by line.

### 3. Add `--headed --slowMo=1000` to watch

```bash
npx playwright test -g "my failing test" --headed --slowMo=1000
```

### 4. Trace viewer

```bash
npx playwright show-trace test-results/.../trace.zip
```

Time-travel through every step with full DOM snapshots.

---

## Tips From the Trenches

- **Use `page.waitForLoadState('networkidle')`** after navigation to wait for all AJAX to settle
- **Avoid `page.waitForTimeout(ms)`** — it's flaky. Use `waitForSelector`, `waitForResponse`, `waitForLoadState` instead
- **Prefer user-facing selectors** — `getByRole`, `getByLabel`, `getByText` over raw CSS
- **One assertion per test when possible** — failures are easier to pinpoint
- **Use `test.describe.serial()` for tests that must run in order** (e.g., create → edit → delete)
- **`test.only()` during development**, remove before commit
- **Commit screenshots** to `tests/playwright/*/core.spec.js-snapshots/` so teammates get the same baseline

---

## When to Write a Test

Write a test when:
- A bug is fixed (write the regression test first, then fix)
- A new feature ships (at least smoke-level coverage)
- A user reports something broken that should have been caught
- You're about to add conditional logic that branches behavior

Don't write a test when:
- You're exploring a spike — delete the code or pave it with tests later
- The logic is trivial (getters, simple props)
- You can't articulate what should be true for it to pass

---

## Next

- [docs/what-is-playwright.md](what-is-playwright.md) — Playwright 101 if the above felt fast
- [tests/playwright/templates/](../tests/playwright/templates/) — every starter template
- [SKILLS.md](../SKILLS.md) — Claude Code skills that can **write tests for you** (`/unit-testing-test-generate`, `/tdd-workflows-tdd-cycle`, `/e2e-testing-patterns`)
