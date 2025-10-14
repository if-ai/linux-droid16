# phase2_3_one_shot.sh  (RUN INSIDE DEBIAN AFTER ./debian-login.sh)
#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Not inside Debian. Use ./debian-login.sh first."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y xfce4 xfce4-goodies dbus-x11 tigervnc-standalone-server xterm

mkdir -p "$HOME/.vnc"

if [ ! -f "$HOME/.vnc/passwd" ]; then
  echo "Set a VNC password (won't echo)."
  vncpasswd
fi

cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &
EOF
chmod +x "$HOME/.vnc/xstartup"

cat > "$HOME/start-vnc.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export DISPLAY=:1
vncserver -kill :1 >/dev/null 2>&1 || true
vncserver :1 -geometry 1280x720 -localhost no
echo "VNC running on :1 (TCP 5901). Connect your VNC client to 127.0.0.1:5901"
EOF
chmod +x "$HOME/start-vnc.sh"

cat > "$HOME/stop-vnc.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
vncserver -kill :1 || true
pkill -9 Xtightvnc tigervnc Xvnc 2>/dev/null || true
echo "VNC :1 stopped."
EOF
chmod +x "$HOME/stop-vnc.sh"

echo "Done. Start GUI with:  ./start-vnc.sh   (stop with: ./stop-vnc.sh)"
