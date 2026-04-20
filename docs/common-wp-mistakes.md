# Common WordPress Coding Mistakes
> What senior WordPress developers know to avoid — and what this QA pipeline catches automatically.

---

## Security Mistakes

### 1. Output Without Escaping (XSS)

```php
// BAD — user input directly in HTML
echo $_GET['message'];
echo get_option('my_setting');

// GOOD
echo esc_html( $_GET['message'] );
echo esc_html( get_option('my_setting') );

// For HTML content (e.g. post content from trusted editors)
echo wp_kses_post( $content );

// For attributes
echo '<input value="' . esc_attr( $value ) . '">';

// For URLs
echo '<a href="' . esc_url( $url ) . '">';
```

**Caught by**: `WordPress.Security.EscapeOutput` (phpcs)

---

### 2. Forms Without Nonce Verification (CSRF)

```php
// BAD — no verification that the request came from your form
if ( isset( $_POST['my_action'] ) ) {
    update_option( 'my_setting', $_POST['value'] );
}

// GOOD
if ( isset( $_POST['my_action'] ) && check_admin_referer( 'my_action_nonce' ) ) {
    update_option( 'my_setting', sanitize_text_field( $_POST['value'] ) );
}

// In your form:
wp_nonce_field( 'my_action_nonce' );
```

**Caught by**: `WordPress.Security.NonceVerification` (phpcs)

---

### 3. Direct SQL Without Prepare (SQL Injection)

```php
// BAD
$results = $wpdb->get_results(
    "SELECT * FROM $wpdb->posts WHERE post_author = " . $_GET['author']
);

// GOOD
$results = $wpdb->get_results(
    $wpdb->prepare(
        "SELECT * FROM $wpdb->posts WHERE post_author = %d",
        intval( $_GET['author'] )
    )
);
```

**Caught by**: `WordPress.DB.PreparedSQL` (phpcs)

---

### 4. REST Endpoints Without Permission Check

```php
// BAD — anyone can call this endpoint
register_rest_route( 'my-plugin/v1', '/settings', [
    'methods'  => 'POST',
    'callback' => 'my_save_settings',
] );

// GOOD
register_rest_route( 'my-plugin/v1', '/settings', [
    'methods'             => 'POST',
    'callback'            => 'my_save_settings',
    'permission_callback' => function() {
        return current_user_can( 'manage_options' );
    },
] );
```

**Caught by**: `/wordpress-penetration-testing` skill, `WordPress.WP.Capabilities` (phpcs)

---

### 5. Missing Input Sanitization

```php
// BAD — storing raw user input
update_option( 'my_text', $_POST['text'] );
update_post_meta( $post_id, 'my_url', $_POST['url'] );

// GOOD
update_option( 'my_text', sanitize_text_field( $_POST['text'] ) );
update_post_meta( $post_id, 'my_url', esc_url_raw( $_POST['url'] ) );

// By type:
sanitize_text_field()    // Plain text
sanitize_textarea_field()// Multi-line text
sanitize_email()         // Email addresses
esc_url_raw()            // URLs stored in DB
absint()                 // Positive integers
intval()                 // Integers
sanitize_key()           // Slugs, keys
wp_kses_post()           // HTML with allowed tags
```

---

## Performance Mistakes

### 6. N+1 Database Queries

```php
// BAD — fires one query per post in the loop
$posts = get_posts([ 'numberposts' => 50 ]);
foreach ( $posts as $post ) {
    $author = get_user_by( 'id', $post->post_author ); // 50 queries!
    $meta   = get_post_meta( $post->ID, 'my_key', true ); // 50 more!
}

// GOOD — pre-warm the cache
$posts    = get_posts([ 'numberposts' => 50 ]);
$post_ids = wp_list_pluck( $posts, 'ID' );
update_postmeta_cache( $post_ids ); // 1 query to cache all meta

$user_ids = array_unique( wp_list_pluck( $posts, 'post_author' ) );
// Pre-load users via a single query
get_users([ 'include' => $user_ids ]);

foreach ( $posts as $post ) {
    $meta = get_post_meta( $post->ID, 'my_key', true ); // hits cache, 0 queries
}
```

**Caught by**: `db-profile.sh`, `/performance-engineer`, `/database-optimizer`

---

### 7. Loading Assets on Every Page

```php
// BAD — loads plugin CSS/JS everywhere
add_action( 'wp_enqueue_scripts', 'my_plugin_assets' );
function my_plugin_assets() {
    wp_enqueue_style( 'my-plugin', MY_PLUGIN_URL . 'assets/style.css' );
    wp_enqueue_script( 'my-plugin', MY_PLUGIN_URL . 'assets/app.js' );
}

// GOOD — only where needed
function my_plugin_assets() {
    if ( ! is_singular( 'my_post_type' ) && ! has_shortcode( get_post()->post_content, 'my_shortcode' ) ) {
        return;
    }
    wp_enqueue_style( 'my-plugin', MY_PLUGIN_URL . 'assets/style.css', [], MY_PLUGIN_VERSION );
    wp_enqueue_script( 'my-plugin', MY_PLUGIN_URL . 'assets/app.js', ['jquery'], MY_PLUGIN_VERSION, true );
}
```

**Caught by**: Lighthouse TBT score, `/performance-engineer`

---

### 8. Synchronous HTTP Calls on Page Load

```php
// BAD — blocks page render if external API is slow/down
add_action( 'init', function() {
    $response = wp_remote_get( 'https://api.example.com/data' );
    $data = json_decode( wp_remote_retrieve_body( $response ) );
});

// GOOD — cache the result, refresh in background via cron
function get_api_data() {
    $cached = get_transient( 'my_api_data' );
    if ( false !== $cached ) {
        return $cached;
    }

    // This only runs when cache is empty
    $response = wp_remote_get( 'https://api.example.com/data' );
    $data     = json_decode( wp_remote_retrieve_body( $response ), true );

    set_transient( 'my_api_data', $data, HOUR_IN_SECONDS );
    return $data;
}
```

---

### 9. Wrong Autoload on Options

```php
// BAD — large data autoloaded on every request
update_option( 'my_plugin_cache', $huge_array ); // autoload=yes by default

// GOOD
update_option( 'my_plugin_cache', $huge_array, false ); // autoload=no
update_option( 'my_plugin_settings', $settings );       // settings: autoload=yes is fine
update_option( 'my_plugin_logs', $logs, false );        // logs: never autoload
```

---

## WordPress API Mistakes

### 10. Rolling Custom Solutions Instead of WP APIs

```php
// BAD — custom session handling
$_SESSION['my_data'] = $data;

// GOOD — use WP transients or user meta
set_transient( 'my_user_' . get_current_user_id(), $data, DAY_IN_SECONDS );

// BAD — custom file operations
file_put_contents( ABSPATH . 'wp-content/my-file.json', json_encode($data) );

// GOOD — WP Filesystem API
global $wp_filesystem;
WP_Filesystem();
$wp_filesystem->put_contents( WP_CONTENT_DIR . '/my-file.json', json_encode($data) );
```

---

### 11. Hardcoding Paths and URLs

```php
// BAD
$path = '/var/www/html/wp-content/plugins/my-plugin/';
$url  = 'https://mysite.com/wp-content/plugins/my-plugin/';

// GOOD
$path = plugin_dir_path( __FILE__ );
$url  = plugin_dir_url( __FILE__ );

// For themes
$path = get_template_directory() . '/';
$url  = get_template_directory_uri() . '/';
```

---

### 12. Not Prefixing Functions, Classes, and Options

```php
// BAD — will conflict with other plugins
function get_settings() { ... }
class Settings { ... }
update_option( 'settings', $data );
add_filter( 'init', 'setup' );

// GOOD — use your plugin prefix
function tpa_get_settings() { ... }
class TPA_Settings { ... }
update_option( 'tpa_settings', $data );
add_filter( 'init', 'tpa_setup' );
```

---

### 13. Not Cleaning Up on Uninstall

```php
// BAD — leaves orphaned data in the database after uninstall

// GOOD — in uninstall.php
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) exit;

// Remove all plugin options
delete_option( 'my_plugin_settings' );
delete_option( 'my_plugin_cache' );

// Remove post meta
delete_post_meta_by_key( 'my_plugin_data' );

// Remove custom tables
global $wpdb;
$wpdb->query( "DROP TABLE IF EXISTS {$wpdb->prefix}my_plugin_table" );

// Remove transients
delete_transient( 'my_plugin_cache' );
```

---

## Gutenberg / Block Mistakes

### 14. Inline Styles in Block Output

```php
// BAD — inline styles can't be overridden easily
function my_block_render( $attributes ) {
    return '<div style="color:' . $attributes['color'] . ';">...</div>';
}

// GOOD — use CSS custom properties or block support classes
function my_block_render( $attributes ) {
    $style = '--my-block-color: ' . sanitize_hex_color( $attributes['color'] ) . ';';
    return '<div class="wp-block-my-block" style="' . esc_attr( $style ) . '">...</div>';
}
```

---

### 15. Not Using block.json

Every modern block must have a `block.json` file. Using `register_block_type( __FILE__ )` (PHP-only registration) misses:
- Block.json: metadata, attribute types, editor/frontend scripts separation
- Server-side rendering declaration
- Script handles auto-registration

```json
{
  "apiVersion": 3,
  "name": "my-plugin/my-block",
  "title": "My Block",
  "category": "widgets",
  "attributes": {
    "content": { "type": "string", "default": "" }
  },
  "editorScript": "file:./index.js",
  "style": "file:./style.css"
}
```

---

## Elementor-Specific Mistakes

### 16. Not Checking Elementor Version

```php
// BAD — crashes if Elementor not active or old version
use Elementor\Widget_Base;

// GOOD
if ( ! did_action( 'elementor/loaded' ) ) {
    return;
}

add_action( 'elementor/widgets/register', function( $widgets_manager ) {
    // Register widgets here
});
```

### 17. Registering Widgets on Wrong Hook

```php
// BAD — too early, Elementor not ready
add_action( 'init', 'register_my_widgets' );

// GOOD
add_action( 'elementor/widgets/register', 'register_my_widgets' );
```

---

## How This QA Pipeline Catches These

| Mistake | Automated Check | Manual Check |
|---|---|---|
| Missing escaping | phpcs `EscapeOutput` | `/wordpress-penetration-testing` |
| Missing nonce | phpcs `NonceVerification` | `/wordpress-penetration-testing` |
| SQL injection | phpcs `PreparedSQL` | `/wordpress-penetration-testing` |
| REST auth missing | phpcs `Capabilities` | `/wordpress-penetration-testing` |
| N+1 queries | `db-profile.sh` Query Monitor | `/database-optimizer` |
| Assets on every page | Lighthouse TBT | `/performance-engineer` |
| Autoload bloat | `db-profile.sh` | `/database-optimizer` |
| Hardcoded paths | phpcs WPCS sniffs | `/wordpress-plugin-development` |
| No cleanup on uninstall | `/wordpress-plugin-development` | Pre-release checklist |
| Missing block.json | `/wordpress-plugin-development` | Code review |
| Elementor wrong hook | Playwright editor test | `/wordpress-plugin-development` |
