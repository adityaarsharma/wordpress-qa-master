#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  🪐  Orbit — One-line installer
#  WordPress Plugin QA Framework · github.com/adityaarsharma/orbit
#
#  Usage (paste into Claude Code or your terminal):
#    curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash
#
#  Or, if Orbit is already cloned, run from the repo root:
#    bash install.sh
#
#  Flags:
#    --update      Refresh symlinks + remove deprecated, no prompts
#    --skills-only Skip the power-tools install (just symlink skills)
#    --help        Print this help
# ══════════════════════════════════════════════════════════════
set -e

# ── Args ────────────────────────────────────────────────────────
UPDATE_MODE=0
SKILLS_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE_MODE=1 ;;
    --skills-only) SKILLS_ONLY=1 ;;
    --help|-h)
      head -25 "$0" | grep -E '^#' | sed 's/^# //;s/^#//'
      exit 0
      ;;
  esac
done

# ── Constants ───────────────────────────────────────────────────
SKILLS_DIR="$HOME/.claude/skills"
ORBIT_HOME_DEFAULT="$HOME/Claude/orbit"
REPO_URL="https://github.com/adityaarsharma/orbit.git"

# ── Header ──────────────────────────────────────────────────────
if [ $UPDATE_MODE -eq 0 ]; then
  cat <<'HEADER'

════════════════════════════════════════════════════
  🪐  Orbit — WordPress Plugin QA Framework
════════════════════════════════════════════════════

  Installing 45 specialised /orbit-* commands:

    /orbit                  Master dispatcher (start here)
    /orbit-setup            Guided onboarding
    /orbit-gauntlet         Full 11-step audit
    /orbit-wp-standards     PHP/WP coding standards
    /orbit-wp-security      XSS / CSRF / SQLi audit
    /orbit-wp-performance   Hook weight + N+1
    /orbit-wp-database      $wpdb / autoload / indexes
    /orbit-playwright       E2E browser tests
    /orbit-uat-compare      Plugin A vs Plugin B
    /orbit-update           One-command updater
    ... and 35 more

  Repo:    github.com/adityaarsharma/orbit
  License: GPL-2.0+ (open source)
  Author:  Aditya Sharma · POSIMYTH Innovation

════════════════════════════════════════════════════

HEADER
fi

# ── Resolve ORBIT_HOME ──────────────────────────────────────────
# If we're already inside the repo, use it. Otherwise clone.
if [ -f "./install.sh" ] && [ -d "./skills/orbit" ]; then
  ORBIT_HOME="$(pwd -P)"
  if [ $UPDATE_MODE -eq 1 ]; then
    echo "⏳ [1/4] Pulling latest from GitHub..."
    git -C "$ORBIT_HOME" fetch --tags --quiet
    git -C "$ORBIT_HOME" pull --rebase --quiet
    echo "   ✓ Pulled latest"
  else
    echo "⏳ [1/4] Using local repo at $ORBIT_HOME"
  fi
elif [ -d "$ORBIT_HOME_DEFAULT/.git" ]; then
  ORBIT_HOME="$ORBIT_HOME_DEFAULT"
  echo "⏳ [1/4] Found existing Orbit at $ORBIT_HOME — pulling latest..."
  git -C "$ORBIT_HOME" fetch --tags --quiet
  git -C "$ORBIT_HOME" pull --rebase --quiet
  echo "   ✓ Pulled latest"
else
  ORBIT_HOME="$ORBIT_HOME_DEFAULT"
  echo "⏳ [1/4] Cloning Orbit to $ORBIT_HOME..."
  mkdir -p "$(dirname "$ORBIT_HOME")"
  git clone --depth 1 --quiet "$REPO_URL" "$ORBIT_HOME"
  echo "   ✓ Cloned"
fi

# ── Capture version ─────────────────────────────────────────────
ORBIT_VERSION=$(git -C "$ORBIT_HOME" describe --tags --always 2>/dev/null || echo "main")
echo "$ORBIT_VERSION" > "$ORBIT_HOME/.orbit_version"

# ── Install skills (symlinks for live updates) ──────────────────
echo ""
echo "⏳ [2/4] Installing /orbit-* skills to ~/.claude/skills/..."
mkdir -p "$SKILLS_DIR"

INSTALLED=0
for skill_path in "$ORBIT_HOME/skills/"orbit*; do
  skill=$(basename "$skill_path")
  [ -f "$skill_path/SKILL.md" ] || continue

  # Remove existing entry (symlink or directory) so we can re-link cleanly
  if [ -L "$SKILLS_DIR/$skill" ] || [ -d "$SKILLS_DIR/$skill" ]; then
    rm -rf "$SKILLS_DIR/$skill"
  fi

  # Symlink so /orbit-update gets fresh content automatically
  ln -s "$skill_path" "$SKILLS_DIR/$skill"
  INSTALLED=$((INSTALLED + 1))
done

echo "   ✓ Linked $INSTALLED skills"

# ── Remove deprecated skills ────────────────────────────────────
DEPRECATED=(
  orbit-init           # → orbit-setup (renamed in v2.5)
)
REMOVED=0
for skill in "${DEPRECATED[@]}"; do
  if [ -L "$SKILLS_DIR/$skill" ] || [ -d "$SKILLS_DIR/$skill" ]; then
    rm -rf "$SKILLS_DIR/$skill"
    echo "   ✓ Removed deprecated: $skill"
    REMOVED=$((REMOVED + 1))
  fi
done

# ── WordPress/agent-skills (official WP core agent skills) ─────
if [ $UPDATE_MODE -eq 0 ] && [ $SKILLS_ONLY -eq 0 ]; then
  echo ""
  echo "⏳ [3a] Installing WordPress/agent-skills (official WP core skills)..."
  echo "   wp-playground gives AI agents a fast WP feedback loop."
  echo "   Source: github.com/WordPress/agent-skills"
  echo ""
  if command -v npx >/dev/null 2>&1; then
    npx -y openskills install WordPress/agent-skills 2>/dev/null && {
      npx -y openskills sync 2>/dev/null || true
      echo "   ✓ WordPress/agent-skills installed"
    } || {
      echo "   ⚠ Couldn't install WordPress/agent-skills (network or npm issue)."
      echo "     Re-try later: npx openskills install WordPress/agent-skills"
    }
  else
    echo "   ⚠ npx not found — install Node.js to use WordPress/agent-skills"
  fi
fi

# ── Power tools (skipped on --update or --skills-only) ──────────
if [ $UPDATE_MODE -eq 0 ] && [ $SKILLS_ONLY -eq 0 ]; then
  echo ""
  echo "⏳ [3/4] Installing power tools (PHPCS / Playwright / Lighthouse / wp-env)..."
  echo "   This is the longest step — about 3-5 minutes on first install."
  echo "   While we wait: /orbit-install can re-run individual tools later."
  echo ""

  if [ -x "$ORBIT_HOME/setup/install.sh" ]; then
    bash "$ORBIT_HOME/setup/install.sh" || {
      echo "   ⚠  Power-tools install hit an error."
      echo "      Skills are installed. Re-run later: /orbit-install"
    }
  else
    echo "   ⚠  setup/install.sh not found in repo. Skills are installed."
    echo "      Run /orbit-install to set up power tools manually."
  fi
else
  echo ""
  echo "⏳ [3/4] Skipping power tools ($([ $UPDATE_MODE -eq 1 ] && echo 'update mode' || echo 'skills-only mode'))"
fi

# ── Closing ─────────────────────────────────────────────────────
echo ""
echo "⏳ [4/4] Wrapping up..."
echo ""
cat <<FOOTER
════════════════════════════════════════════════════
  ✅  Orbit installed — $ORBIT_VERSION
════════════════════════════════════════════════════

  Skills installed:    $INSTALLED
  Skills removed:      $REMOVED (deprecated)
  Repo:                $ORBIT_HOME
  Skills folder:       $SKILLS_DIR

────────────────────────────────────────────────────
  Next steps
────────────────────────────────────────────────────

FOOTER

if [ $UPDATE_MODE -eq 0 ]; then
  cat <<'NEXT'
  1. Fully quit Claude Code (Cmd+Q on Mac)
  2. Reopen it
  3. Type /orbit  →  master menu appears

  Or jump straight in:

     /orbit-setup            Guided wizard for your first plugin
     /orbit-docker-site      Spin up a wp-env test site
     /orbit-gauntlet         Full audit (after setup)

  Documentation:
     ~/Claude/orbit/README.md
     ~/Claude/orbit/GETTING-STARTED.md
     ~/Claude/orbit/SKILLS.md          (every skill listed)

  Update later:    /orbit-update
  Open the menu:   /orbit

NEXT
else
  cat <<'NEXTUPDATE'
  Skill text changes are live immediately — no restart needed.

  Verify:        /orbit
  See changes:   git -C ~/Claude/orbit log --oneline -10

NEXTUPDATE
fi

cat <<'OUTRO'
────────────────────────────────────────────────────
  🪐  Built by Aditya Sharma · POSIMYTH Innovation
  github.com/adityaarsharma/orbit
════════════════════════════════════════════════════

OUTRO

exit 0
