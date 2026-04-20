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
