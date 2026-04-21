// @ts-check
const { defineConfig, devices } = require('@playwright/test');
const path = require('path');

const BASE_URL  = process.env.WP_TEST_URL || 'http://localhost:8881';
const AUTH_FILE = path.join(__dirname, '../../.auth/wp-admin.json');

// HTML report: reports/playwright-html/index.html
// View after any run: npx playwright show-report reports/playwright-html
module.exports = defineConfig({
  testDir: './',
  timeout: 120_000,
  expect: {
    timeout: 30_000,
    toHaveScreenshot: { maxDiffPixelRatio: 0.02, threshold: 0.2 },
  },
  fullyParallel: true,
  workers: process.env.PLAYWRIGHT_WORKERS || (process.env.CI ? 1 : '50%'),
  retries: process.env.CI ? 2 : 0,

  reporter: [
    // HTML report — always generated, never auto-opened (open manually)
    ['html', { outputFolder: '../../reports/playwright-html', open: 'never' }],
    // JSON for gauntlet.sh pass/fail parsing
    ['json', { outputFile: '../../reports/playwright-results.json' }],
    // Terminal output during run
    ['line'],
  ],

  use: {
    baseURL: BASE_URL,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },

  projects: [
    // ── Auth setup — runs once, saves admin cookies ──
    {
      name: 'setup',
      testMatch: '**/auth.setup.js',
      use: { storageState: undefined },
    },

    // ── Desktop Chrome — main test run (admin-authenticated) ──
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      dependencies: ['setup'],
    },

    // ── Firefox — catches Safari-adjacent bugs, CSS Grid edge cases ──
    {
      name: 'firefox',
      use: {
        ...devices['Desktop Firefox'],
        storageState: AUTH_FILE,
      },
      dependencies: ['setup'],
    },

    // ── WebKit — Safari engine, catches real Safari-only bugs ──
    // Run with: npx playwright test --project=webkit
    {
      name: 'webkit',
      use: {
        ...devices['Desktop Safari'],
        storageState: AUTH_FILE,
      },
      dependencies: ['setup'],
    },

    // ── Visual snapshots — full-page screenshots + UI audit ──
    {
      name: 'visual',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
        screenshot: 'on',
      },
      testMatch: '**/visual/**/*.spec.js',
      dependencies: ['setup'],
    },

    // ── Mobile viewport — responsive checks ──
    {
      name: 'mobile-chrome',
      use: {
        ...devices['Pixel 5'],
        storageState: AUTH_FILE,
      },
      dependencies: ['setup'],
      testMatch: '**/responsive.spec.js',
    },

    // ── Tablet viewport ──
    {
      name: 'tablet',
      use: {
        ...devices['iPad Pro'],
        storageState: AUTH_FILE,
      },
      dependencies: ['setup'],
      testMatch: '**/responsive.spec.js',
    },

    // ── Video recording — every test recorded to reports/videos/ ──
    {
      name: 'video',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
        video: { mode: 'on', size: { width: 1280, height: 800 } },
        screenshot: 'on',
      },
      testMatch: '**/flows/**/*.spec.js',
      dependencies: ['setup'],
      preserveOutput: 'always',
    },

    // ── Elementor widget QA — widget-by-widget testing ──
    {
      name: 'elementor-widgets',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
        video: { mode: 'on', size: { width: 1440, height: 900 } },
        screenshot: 'on',
      },
      testMatch: '**/elementor/**/*.spec.js',
      dependencies: ['setup'],
    },

    // ── RTL (Arabic/Hebrew/Farsi) layout test ──
    {
      name: 'rtl',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
        locale: 'ar',
        screenshot: 'on',
      },
      testMatch: '**/flows/rtl-layout.spec.js',
      dependencies: ['setup'],
    },

    // ── Multisite activation test ──
    {
      name: 'multisite',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: '**/flows/multisite-activation.spec.js',
      dependencies: ['setup'],
    },

    // ── Admin color scheme compatibility (8 built-in schemes) ──
    {
      name: 'admin-colors',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: '**/flows/admin-color-schemes.spec.js',
      dependencies: ['setup'],
    },

    // ── Keyboard navigation / focus trap detection ──
    {
      name: 'keyboard',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: '**/flows/keyboard-nav.spec.js',
      dependencies: ['setup'],
    },

    // ── Uninstall cleanup + update path + block deprecation ──
    {
      name: 'lifecycle',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: ['**/flows/uninstall-cleanup.spec.js', '**/flows/update-path.spec.js', '**/flows/block-deprecation.spec.js'],
      dependencies: ['setup'],
    },

    // ── REST API — Application Passwords ──
    {
      name: 'rest-apppass',
      use: {
        ...devices['Desktop Chrome'],
      },
      testMatch: '**/flows/app-passwords.spec.js',
      dependencies: ['setup'],
    },

    // ── UX coverage — empty / error / loading / form states ──
    {
      name: 'ux-states',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: [
        '**/flows/empty-states.spec.js',
        '**/flows/error-states.spec.js',
        '**/flows/loading-states.spec.js',
        '**/flows/form-validation.spec.js',
      ],
      dependencies: ['setup'],
    },

    // ── Plugin conflict matrix (top 20 popular plugins) ──
    {
      name: 'conflict',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: '**/flows/plugin-conflict.spec.js',
      dependencies: ['setup'],
    },

    // ── WordPress 7.0 Connectors / Abilities API security ──
    {
      name: 'wp7',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: '**/flows/wp7-connectors.spec.js',
      dependencies: ['setup'],
    },

    // ── PM role: full user journey, FTUE, analytics ──
    {
      name: 'pm',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
        video: { mode: 'on', size: { width: 1440, height: 900 } },
      },
      testMatch: [
        '**/flows/user-journey.spec.js',
        '**/flows/onboarding-ftue.spec.js',
      ],
      dependencies: ['setup'],
    },

    // ── PA role: analytics events firing ──
    {
      name: 'analytics',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: '**/flows/analytics-events.spec.js',
      dependencies: ['setup'],
    },

    // ── Visual regression vs previous release tag ──
    {
      name: 'visual-release',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: '**/flows/visual-regression-release.spec.js',
      dependencies: ['setup'],
    },

    // ── Per-page plugin bundle size enforcement (plugin-check parity) ──
    {
      name: 'bundle-size',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: '**/flows/bundle-size.spec.js',
      dependencies: ['setup'],
    },
  ],

  // WP Playground server for CI
  ...(process.env.USE_PLAYGROUND === 'true' ? {
    webServer: {
      command: 'npx @wp-playground/cli server --blueprint=setup/playground-blueprint.json',
      url: 'http://localhost:9400',
      reuseExistingServer: !process.env.CI,
      timeout: 120_000,
    },
  } : {}),
});
