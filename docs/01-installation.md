# Installation Guide

> Complete setup from zero to running your first gauntlet. Every tool, every step, verified.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [One-Command Install](#2-one-command-install)
3. [Manual Installation (step by step)](#3-manual-installation)
4. [Installing Claude Code Skills](#4-installing-claude-code-skills)
5. [Verify Everything Works](#5-verify-everything-works)
6. [Troubleshooting Installation](#6-troubleshooting-installation)
7. [Updating Orbit](#7-updating-orbit)

---

## 1. Prerequisites

Before running anything, you need these on your machine.

### macOS (recommended)

```bash
# Install Homebrew if missing
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Core requirements
brew install node@20 php composer git
brew install --cask docker

# WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
```

### Ubuntu / Debian

```bash
# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# PHP + Composer
sudo apt-get install -y php php-cli php-xml php-mbstring
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Docker
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER  # allow running without sudo

# WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp
```

### Minimum versions required

| Tool | Minimum | Check command |
|---|---|---|
| Node.js | 18.x | `node --version` |
| PHP | 7.4 | `php --version` |
| Composer | 2.x | `composer --version` |
| Docker | 24+ | `docker --version` |
| WP-CLI | 2.8+ | `wp --version` |
| Git | 2.x | `git --version` |

---

## 2. One-Command Install

```bash
git clone https://github.com/adityaarsharma/orbit.git ~/Claude/orbit
cd ~/Claude/orbit
bash setup/install.sh
```

`install.sh` handles:
- npm packages (`@playwright/test`, `@wordpress/env`, `lighthouse`, etc.)
- Playwright browser binaries
- PHP Composer packages (PHP_CodeSniffer, WPCS, VIP standards, PHPStan)
- wp-env global install
- wp-now global install
- Claude Code skills verification

Takes about 3–5 minutes the first time (mostly browser downloads).

---

## 3. Manual Installation

If `install.sh` fails for any step, here is every piece individually.

### 3.1 Node packages

```bash
cd ~/Claude/orbit
npm install

# Install Playwright browsers (chromium, firefox, webkit)
npx playwright install
npx playwright install-deps  # system libs (Linux only)
```

### 3.2 Global npm tools

```bash
npm install -g @wordpress/env          # wp-env — Docker-based WP test sites
npm install -g @wp-now/wp-now          # wp-now — zero-config instant WP
npm install -g lighthouse              # performance audits
npm install -g @lhci/cli               # Lighthouse CI
```

### 3.3 PHP Quality Tools (via Composer)

```bash
# Install all PHP tools globally
composer global require \
  squizlabs/php_codesniffer \
  wp-coding-standards/wpcs \
  automattic/vipwpcs \
  phpcompatibility/phpcompatibility-wp \
  phpstan/phpstan \
  szepeviktor/phpstan-wordpress

# Register WPCS + VIP standards with phpcs
phpcs --config-set installed_paths \
  ~/.composer/vendor/wp-coding-standards/wpcs,\
  ~/.composer/vendor/automattic/vipwpcs,\
  ~/.composer/vendor/phpcompatibility/phpcompatibility-wp

# Verify standards loaded
phpcs -i
# Should include: WordPress, WordPress-Core, WordPress-Docs, WordPress-Extra, WordPressVIPMinimum, PHPCompatibilityWP
```

### 3.4 Claude Code CLI

```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

Claude Code is required for Step 11 (skill audits). Without it, the gauntlet still runs Steps 1–10.

### 3.5 PHPStan config

The `config/phpstan.neon` file already exists in Orbit. It runs PHPStan at level 5 with WordPress stubs. If your plugin has a custom `phpstan.neon`, point the gauntlet to it:

```bash
# Override in gauntlet.sh by passing config path
PHPSTAN_CONFIG=/path/to/your/phpstan.neon bash scripts/gauntlet.sh --plugin /path/to/plugin
```

---

## 4. Installing Claude Code Skills

Skills are `.md` files installed into `~/.claude/skills/`. They tell Claude Code how to behave as a specialist auditor.

### Recommended: Antigravity CLI installer

```bash
npx antigravity-awesome-skills
```

This installs all skills from the awesome-agent-skills registry into `~/.claude/skills/`.

### Manual install

```bash
# Clone the skills repo
git clone https://github.com/VoltAgent/awesome-agent-skills ~/Claude/awesome-agent-skills

# Symlink into Claude's skills directory
mkdir -p ~/.claude/skills
ln -sf ~/Claude/awesome-agent-skills/skills/* ~/.claude/skills/
```

### Verify each mandatory skill is installed

```bash
ls ~/.claude/skills/wordpress-plugin-development       && echo "✓ WP Standards"
ls ~/.claude/skills/wordpress-penetration-testing      && echo "✓ Security"
ls ~/.claude/skills/performance-engineer               && echo "✓ Performance"
ls ~/.claude/skills/database-optimizer                 && echo "✓ Database"
ls ~/.claude/skills/accessibility-compliance-accessibility-audit && echo "✓ Accessibility"
ls ~/.claude/skills/code-review-excellence             && echo "✓ Code Quality"
```

All 6 should print `✓`. If any are missing:

```bash
# Install individually from Claude Code
/skill install wordpress-plugin-development
/skill install wordpress-penetration-testing
/skill install performance-engineer
/skill install database-optimizer
/skill install accessibility-compliance-accessibility-audit
/skill install code-review-excellence
```

### Add-on skills (install based on plugin type)

```bash
# Elementor addon plugins
ls ~/.claude/skills/antigravity-design-expert

# Gutenberg / FSE theme plugins
ls ~/.claude/skills/wordpress-theme-development

# WooCommerce plugins
ls ~/.claude/skills/wordpress-woocommerce-development

# REST API / headless plugins
ls ~/.claude/skills/api-security-testing

# Complex PHP / OOP plugins
ls ~/.claude/skills/php-pro
```

---

## 5. Verify Everything Works

Run this after installation to confirm all tools are operational:

```bash
echo "=== Orbit Installation Verification ==="
echo ""

# Node
node --version && echo "✓ Node.js" || echo "✗ Node.js missing"
npm --version  && echo "✓ npm" || echo "✗ npm missing"

# PHP
php --version  && echo "✓ PHP" || echo "✗ PHP missing"
phpcs --version && echo "✓ PHPCS" || echo "✗ PHPCS missing — run: composer global require squizlabs/php_codesniffer"
phpstan --version 2>/dev/null && echo "✓ PHPStan" || echo "✗ PHPStan missing"

# WP tools
wp --version   && echo "✓ WP-CLI" || echo "✗ WP-CLI missing"
wp-env --version && echo "✓ wp-env" || echo "✗ wp-env missing — run: npm i -g @wordpress/env"

# Playwright
npx playwright --version && echo "✓ Playwright" || echo "✗ Playwright missing"

# Lighthouse
lighthouse --version 2>/dev/null && echo "✓ Lighthouse" || echo "⚠ Lighthouse missing — optional, run: npm i -g lighthouse"

# Claude Code
claude --version 2>/dev/null && echo "✓ Claude Code" || echo "⚠ Claude Code missing — optional for skills"

# Docker
docker info &>/dev/null && echo "✓ Docker running" || echo "✗ Docker not running — start Docker Desktop"

echo ""
echo "=== PHPCS Standards ==="
phpcs -i 2>/dev/null | grep -E "WordPress|VIPMinimum|PHPCompatibility" || echo "✗ WPCS standards not registered"
```

Expected output (all green):
```
✓ Node.js
✓ npm
✓ PHP
✓ PHPCS
✓ PHPStan
✓ WP-CLI
✓ wp-env
✓ Playwright
✓ Lighthouse
✓ Claude Code
✓ Docker running

=== PHPCS Standards ===
WordPress, WordPress-Core, WordPress-Docs, WordPress-Extra
WordPressVIPMinimum
PHPCompatibilityWP
```

---

## 6. Troubleshooting Installation

### Docker not running

```bash
# macOS — open Docker Desktop app first
open -a Docker

# Ubuntu
sudo systemctl start docker
sudo systemctl enable docker
```

### PHPCS "No coding standards found"

```bash
# Re-run standards registration
phpcs --config-set installed_paths \
  $(composer global config home)/vendor/wp-coding-standards/wpcs,\
  $(composer global config home)/vendor/automattic/vipwpcs,\
  $(composer global config home)/vendor/phpcompatibility/phpcompatibility-wp

phpcs -i  # verify
```

### Playwright browsers missing

```bash
npx playwright install
npx playwright install-deps  # Linux only
```

### wp-env "port already in use"

```bash
lsof -i :8881         # find what's using port 8881
# Change port in create-test-site.sh call: --port 8882
```

### Claude Code "skill not found"

```bash
# Check skills directory
ls ~/.claude/skills/ | grep wordpress

# Re-install from registry
npx antigravity-awesome-skills
```

### PHP version too old (7.2 or lower)

Orbit requires PHP 7.4+ for the CLI tools (phpcs, phpstan). Your production server can run any version — only the CLI tools need 7.4+.

```bash
# macOS — install multiple PHP versions
brew install php@8.2
brew link php@8.2 --force
php --version  # should show 8.2.x
```

### npm install fails on Apple Silicon

```bash
# Clear npm cache and reinstall
npm cache clean --force
arch -x86_64 npm install  # fallback for Intel-only packages
```

---

## 7. Updating Orbit

```bash
cd ~/Claude/orbit
git pull origin main
npm install          # pick up any new dependencies
bash setup/install.sh  # re-run to update tools
```

### Updating skills

```bash
# If installed via Antigravity CLI
npx antigravity-awesome-skills

# If installed via symlink
cd ~/Claude/awesome-agent-skills
git pull origin main
# Symlinks update automatically
```

---

## What's Next

- [docs/02-configuration.md](02-configuration.md) — Set up `qa.config.json` for your plugin
- [docs/03-test-environment.md](03-test-environment.md) — Spin up a WordPress test site
- [docs/04-gauntlet.md](04-gauntlet.md) — Run your first full audit
