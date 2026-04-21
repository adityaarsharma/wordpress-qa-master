// @ts-check
/**
 * RankReady — Cache Layer & Content Negotiation Test Suite
 *
 * Tests that RankReady emits the correct response headers so every known CDN
 * and WordPress page-cache layer is bypassed for dynamic endpoints (.md URLs,
 * homepage markdown negotiation). Also verifies llms.txt stays cacheable and
 * content negotiation follows RFC 9110 q-value rules.
 *
 * No third-party cache plugins are installed or required — this suite tests
 * only the headers RankReady itself emits, which is what matters.
 *
 * Run from ~/Claude/wordpress-qa-master:
 *   WP_TEST_URL=http://localhost:8890 WP_USER=admin WP_PASS=password \
 *   npx playwright test rankready/tests/cache.spec.js \
 *     --config=rankready/playwright.config.js --reporter=line
 */
const { test, expect } = require('@playwright/test');
const { execSync }     = require('child_process');

const BASE_URL = process.env.WP_TEST_URL || 'http://localhost:8890';
const WP_USER  = process.env.WP_USER     || 'admin';
const WP_PASS  = process.env.WP_PASS     || 'password';

// ── Helpers ──────────────────────────────────────────────────────────────────

function wp( cmd ) {
  return execSync(
    `cd "${__dirname}/.." && npx @wordpress/env run cli wp ${cmd} 2>/dev/null`,
    { encoding: 'utf8' }
  ).trim();
}

function enableEndpoints() {
  wp( 'option update rr_md_enable on' );
  wp( 'option update rr_llms_enable on' );
  wp( 'option update rr_llms_full_enable on' );
  wp( 'option update rr_robots_enable on' );
  wp( 'option update rr_content_signals_enable on' );
  wp( 'rewrite flush --hard' );
}

/** Create a test post and return its slug. Idempotent. */
function ensureTestPost() {
  try {
    const id = wp( 'post create --post_title="Cache Test Post" --post_status=publish --post_content="Cache test body paragraph." --porcelain' );
    wp( `post update ${id} --post_name=cache-test-post` );
  } catch { /* post may already exist */ }
  return 'cache-test-post';
}

// ── Setup (runs once before all tests) ───────────────────────────────────────

let testPostSlug;

test.beforeAll( () => {
  enableEndpoints();
  testPostSlug = ensureTestPost();
} );

// ── No auth needed for HTTP header / endpoint tests ───────────────────────────
// These all use page.request (no browser UI, no cookie auth required) since
// the endpoints being tested are public.

test.describe( 'Homepage — cache bypass headers', () => {

  test( 'Vary: Accept present on HTML response', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/' );
    expect( res.headers()['vary'] ).toContain( 'Accept' );
  } );

  test( 'cf-edge-cache: no-cache (Cloudflare APO bypass)', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/' );
    expect( res.headers()['cf-edge-cache'] ).toBe( 'no-cache' );
  } );

  test( 'CDN-Cache-Control: no-store (Cloudflare / BunnyCDN)', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/' );
    expect( res.headers()['cdn-cache-control'] ).toContain( 'no-store' );
  } );

  test( 'Surrogate-Control: no-store (Varnish / Fastly)', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/' );
    expect( res.headers()['surrogate-control'] ).toContain( 'no-store' );
  } );

  test( 'Edge-Control: no-store (Akamai)', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/' );
    expect( res.headers()['edge-control'] ).toContain( 'no-store' );
  } );

  test( 'X-Accel-Expires: 0 (nginx FastCGI cache bypass)', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/' );
    expect( res.headers()['x-accel-expires'] ).toBe( '0' );
  } );

  test( 'Cache-Control: no-store (HTTP standard)', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/' );
    expect( res.headers()['cache-control'] ).toContain( 'no-store' );
  } );

} );

test.describe( 'Homepage — markdown content negotiation', () => {

  test( 'Accept: text/markdown → 200 text/markdown', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/', {
      headers: { 'Accept': 'text/markdown' },
    } );
    expect( res.status() ).toBe( 200 );
    expect( res.headers()['content-type'] ).toContain( 'text/markdown' );
  } );

  test( 'Markdown response carries cf-edge-cache: no-cache', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/', {
      headers: { 'Accept': 'text/markdown' },
    } );
    expect( res.headers()['cf-edge-cache'] ).toBe( 'no-cache' );
  } );

  test( 'Markdown response carries Vary: Accept', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/', {
      headers: { 'Accept': 'text/markdown' },
    } );
    expect( res.headers()['vary'] ).toContain( 'Accept' );
  } );

  test( 'Markdown response carries x-markdown-source: accept', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/', {
      headers: { 'Accept': 'text/markdown' },
    } );
    expect( res.headers()['x-markdown-source'] ).toBe( 'accept' );
  } );

  test( 'Markdown body starts with # site title', async ( { request } ) => {
    const res  = await request.get( BASE_URL + '/', { headers: { 'Accept': 'text/markdown' } } );
    const body = await res.text();
    expect( body.trim() ).toMatch( /^#\s+\S/ );
  } );

} );

test.describe( 'Post .md URL endpoint', () => {

  test( 'returns 200 text/markdown', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}.md` );
    expect( res.status() ).toBe( 200 );
    expect( res.headers()['content-type'] ).toContain( 'text/markdown' );
  } );

  test( 'cf-edge-cache: no-cache present', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}.md` );
    expect( res.headers()['cf-edge-cache'] ).toBe( 'no-cache' );
  } );

  test( 'CDN-Cache-Control: no-store present', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}.md` );
    expect( res.headers()['cdn-cache-control'] ).toContain( 'no-store' );
  } );

  test( 'Surrogate-Control: no-store present', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}.md` );
    expect( res.headers()['surrogate-control'] ).toContain( 'no-store' );
  } );

  test( 'Edge-Control: no-store present', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}.md` );
    expect( res.headers()['edge-control'] ).toContain( 'no-store' );
  } );

  test( 'Cache-Control: no-store present', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}.md` );
    expect( res.headers()['cache-control'] ).toContain( 'no-store' );
  } );

} );

test.describe( 'Singular post — Accept header negotiation', () => {

  test( 'Accept: text/markdown → 200 markdown + all no-cache headers', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}/`, {
      headers: { 'Accept': 'text/markdown' },
    } );
    expect( res.status() ).toBe( 200 );
    expect( res.headers()['content-type'] ).toContain( 'text/markdown' );
    expect( res.headers()['cf-edge-cache'] ).toBe( 'no-cache' );
    expect( res.headers()['cdn-cache-control'] ).toContain( 'no-store' );
    expect( res.headers()['surrogate-control'] ).toContain( 'no-store' );
    expect( res.headers()['cache-control'] ).toContain( 'no-store' );
    expect( res.headers()['vary'] ).toContain( 'Accept' );
  } );

  test( 'Accept: application/json → 406 with no-cache + Vary: Accept', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}/`, {
      headers: { 'Accept': 'application/json' },
    } );
    expect( res.status() ).toBe( 406 );
    // 406 must also carry no-store — a cached 406 would wrongly serve an error to browser clients.
    expect( res.headers()['cache-control'] ).toContain( 'no-store' );
    expect( res.headers()['vary'] ).toContain( 'Accept' );
  } );

} );

test.describe( 'llms.txt — should stay cacheable', () => {

  test( '200 text/plain', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/llms.txt' );
    expect( res.status() ).toBe( 200 );
    expect( res.headers()['content-type'] ).toContain( 'text/plain' );
  } );

  test( 'Cache-Control: public max-age (no negotiation — safe to cache)', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/llms.txt' );
    const cc  = res.headers()['cache-control'] || '';
    expect( cc ).toContain( 'public' );
    expect( cc ).toMatch( /max-age=\d+/ );
  } );

  test( 'Link discovery header present (rel="llms-txt")', async ( { request } ) => {
    const res  = await request.get( BASE_URL + '/llms.txt' );
    const link = res.headers()['link'] || '';
    expect( link ).toContain( 'rel="llms-txt"' );
  } );

  test( 'llms-full.txt: 200 text/plain', async ( { request } ) => {
    const res = await request.get( BASE_URL + '/llms-full.txt' );
    expect( res.status() ).toBe( 200 );
    expect( res.headers()['content-type'] ).toContain( 'text/plain' );
  } );

} );

test.describe( 'RFC 9110 q-value content negotiation', () => {

  test( 'text/html;q=1.0, text/markdown;q=0.5 → serves HTML', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}/`, {
      headers: { 'Accept': 'text/html;q=1.0,text/markdown;q=0.5' },
    } );
    expect( res.headers()['content-type'] ).toContain( 'text/html' );
  } );

  test( 'text/markdown;q=1.0, text/html;q=0.5 → serves markdown', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}/`, {
      headers: { 'Accept': 'text/markdown;q=1.0,text/html;q=0.5' },
    } );
    expect( res.headers()['content-type'] ).toContain( 'text/markdown' );
  } );

  test( 'equal q-values → markdown preferred over HTML on tie', async ( { request } ) => {
    const res = await request.get( `${BASE_URL}/${testPostSlug}/`, {
      headers: { 'Accept': 'text/markdown;q=0.9,text/html;q=0.9' },
    } );
    expect( res.headers()['content-type'] ).toContain( 'text/markdown' );
  } );

} );

test.describe( 'Sequential request correctness', () => {

  test( 'Two markdown requests both return markdown (no stale HTML served)', async ( { request } ) => {
    const r1 = await request.get( BASE_URL + '/', { headers: { 'Accept': 'text/markdown' } } );
    const r2 = await request.get( BASE_URL + '/', { headers: { 'Accept': 'text/markdown' } } );
    expect( r1.headers()['content-type'] ).toContain( 'text/markdown' );
    expect( r2.headers()['content-type'] ).toContain( 'text/markdown' );
  } );

  test( 'HTML request after markdown request still returns HTML', async ( { request } ) => {
    await request.get( BASE_URL + '/', { headers: { 'Accept': 'text/markdown' } } );
    const html = await request.get( BASE_URL + '/', { headers: { 'Accept': 'text/html' } } );
    expect( html.headers()['content-type'] ).toContain( 'text/html' );
  } );

} );

// ── Admin checks — need authenticated browser ─────────────────────────────────

test.describe( 'PHP safety checks — no fatal errors', () => {

  test.beforeEach( async ( { page } ) => {
    await page.goto( BASE_URL + '/wp-login.php' );
    await page.fill( '#user_login', WP_USER );
    await page.fill( '#user_pass', WP_PASS );
    await page.click( '#wp-submit' );
    await expect( page ).toHaveURL( /wp-admin/, { timeout: 30_000 } );
  } );

  test( 'No PHP fatal on homepage (cache constants defined)', async ( { page } ) => {
    await page.goto( BASE_URL + '/' );
    await expect( page.locator( 'body' ) ).not.toContainText( 'Fatal error' );
    await expect( page.locator( 'body' ) ).not.toContainText( 'Cannot redeclare' );
  } );

  test( 'No PHP fatal on admin while cache constants are active', async ( { page } ) => {
    await page.goto( BASE_URL + '/wp-admin/admin.php?page=rankready' );
    await expect( page.locator( 'body' ) ).not.toContainText( 'Fatal error' );
    await expect( page.locator( 'body' ) ).not.toContainText( 'Cannot redeclare' );
  } );

} );
