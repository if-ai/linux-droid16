#!/usr/bin/env bash
# patch_pidf_fix.sh — patch existing installs to avoid "PIDF: unbound variable"
# Run this in the environment where the files live (as root or the user).

set -Eeuo pipefail

TARGET_USER="${TARGET_USER:-${SUDO_USER:-$USER}}"
TARGET_HOME="${TARGET_HOME:-$HOME}"

fix_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  sed -i \
    -e 's/^PIDF="\$HOME\/\.ssh\/sshd\.pid"$/PIDF="${PIDF:-$HOME\/.ssh\/sshd.pid}"/' \
    -e 's/^CONF="\$HOME\/\.ssh\/sshd_config"$/CONF="${CONF:-$HOME\/.ssh\/sshd_config}"/' \
    -e 's/\[ -f "\$PIDF" \] \&\& \[ -s "\$PIDF" \]/[ -n "${PIDF:-}" ] \&\& [ -f "$PIDF" ] \&\& [ -s "$PIDF" ]/' \
    "$f" || true
  chmod +x "$f" || true
}

fix_file "$TARGET_HOME/start-ssh.sh"
fix_file "$TARGET_HOME/stop-ssh.sh"

echo "Patched (if present):"
echo "  $TARGET_HOME/start-ssh.sh"
echo "  $TARGET_HOME/stop-ssh.sh"
