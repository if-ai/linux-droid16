# phase1_setup.sh  (APT-BASED; RUN IN YOUR CURRENT TERMINAL)
#!/usr/bin/env bash
set -Eeuo pipefail

# --- helpers ---
have(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 1; }
as_root(){ if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

have apt-get || die "This script requires apt/apt-get."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE2="$SCRIPT_DIR/phase2_3_one_shot.sh"
[ -f "$PHASE2" ] || die "Missing $PHASE2 next to this script."

# --- base pkgs for this environment ---
as_root apt-get update -y
as_root apt-get install -y wget tmux sudo ca-certificates

# --- decide target user & create debian-login.sh stub ---
if [ "$(id -u)" -eq 0 ]; then
  TARGET_USER="${TARGET_USER:-droid}"
  TARGET_HOME="/home/$TARGET_USER"
  id "$TARGET_USER" >/dev/null 2>&1 || {
    as_root useradd -m -s /bin/bash "$TARGET_USER"
    echo "$TARGET_USER:$TARGET_USER" | as_root chpasswd
    as_root usermod -aG sudo "$TARGET_USER" || true
  }
  # copy phase2 into target user's home for convenience
  as_root install -m 0755 "$PHASE2" "$TARGET_HOME/phase2_3_one_shot.sh"
  as_root chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/phase2_3_one_shot.sh"

  cat > "$SCRIPT_DIR/debian-login.sh" <<EOF
#!/usr/bin/env bash
exec su - $TARGET_USER
EOF
  chmod +x "$SCRIPT_DIR/debian-login.sh"
  echo "Done. Enter the user shell with:  ./debian-login.sh"
  echo "Then run inside that shell:       bash ~/phase2_3_one_shot.sh"
else
  # not root: create a no-op debian-login to keep docs consistent
  cat > "$SCRIPT_DIR/debian-login.sh" <<'EOF'
#!/usr/bin/env bash
# Already in this Debian-like environment; start a login shell.
exec bash -l
EOF
  chmod +x "$SCRIPT_DIR/debian-login.sh"
  echo "Done. You're already a normal user."
  echo "Run:  ./debian-login.sh"
  echo "Then: bash ./phase2_3_one_shot.sh   (or the path where the repo lives)"
fi
