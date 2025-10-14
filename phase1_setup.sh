# phase1_setup.sh  (RUN IN ANDROID 16 TERMINAL, NOT INSIDE DEBIAN)
#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v pkg >/dev/null 2>&1; then
  echo "Run this in the Android 16 Terminal (Termux-like env with 'pkg')."
  exit 1
fi

pkg update -y
pkg upgrade -y
pkg install -y proot-distro wget tmux

if ! proot-distro list | grep -q "^debian"; then
  proot-distro install debian
fi

cat > "$HOME/debian-login.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login debian
EOF
chmod +x "$HOME/debian-login.sh"

echo "Done. Enter Debian with:  ./debian-login.sh"
