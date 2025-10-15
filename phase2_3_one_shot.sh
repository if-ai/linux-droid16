# phase2_3_one_shot.sh  (RUN *INSIDE* DEBIAN AFTER ./debian-login.sh)
#!/usr/bin/env bash
set -Eeuo pipefail

# ---- sanity ----
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Not inside a Debian/apt environment. Use ./debian-login.sh first."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ---- packages ----
apt-get update -y
apt-get install -y \
  xfce4 xfce4-goodies dbus-x11 xorg xterm \
  tigervnc-standalone-server tigervnc-common

# ---- VNC config ----
mkdir -p "$HOME/.vnc"

# prompt once for a VNC password if missing
if [ ! -f "$HOME/.vnc/passwd" ]; then
  echo "Set a VNC password (min 6 chars, won't echo)."
  vncpasswd
fi

# xstartup (dbus + xfce)
cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
dbus-launch >/dev/null 2>&1 &
startxfce4
EOF
chmod +x "$HOME/.vnc/xstartup"

# allow env overrides: VNC_DISPLAY, VNC_GEOMETRY, VNC_LOCALHOST
# defaults => :1, 1280x720, no
cat > "$HOME/start-vnc.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
DISPLAY_NUM="${VNC_DISPLAY:-:1}"
GEOM="${VNC_GEOMETRY:-1280x720}"
LOCALHOST_FLAG="${VNC_LOCALHOST:-no}"

# clean previous
vncserver -kill "$DISPLAY_NUM" >/dev/null 2>&1 || true

# ensure password exists
if [ ! -f "$HOME/.vnc/passwd" ]; then
  echo "No VNC password set. You will be prompted now."
  vncpasswd
fi

# start
export DISPLAY="$DISPLAY_NUM"
vncserver "$DISPLAY_NUM" -geometry "$GEOM" -localhost "$LOCALHOST_FLAG"

PORT="$(echo "$DISPLAY_NUM" | sed 's/://')"
PORT=$((5900 + ${PORT:-1}))
echo "VNC running on $DISPLAY_NUM (TCP $PORT). Connect your client to 127.0.0.1:$PORT"
echo "Tip: override defaults:  VNC_DISPLAY=:2 VNC_GEOMETRY=1920x1080 VNC_LOCALHOST=yes ./start-vnc.sh"
EOF
chmod +x "$HOME/start-vnc.sh"

cat > "$HOME/stop-vnc.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
DISPLAY_NUM="${VNC_DISPLAY:-:1}"
vncserver -kill "$DISPLAY_NUM" || true
pkill -9 Xtightvnc tigervnc Xvnc 2>/dev/null || true
echo "VNC $DISPLAY_NUM stopped."
EOF
chmod +x "$HOME/stop-vnc.sh"

echo
echo "✅ Phase 2/3 complete."
echo "Start GUI:  ./start-vnc.sh            (defaults: :1 @ 1280x720, localhost=no)"
echo "Stop GUI:   ./stop-vnc.sh"
echo "Examples:"
echo "  VNC_GEOMETRY=1920x1080 ./start-vnc.sh"
echo "  VNC_DISPLAY=:2 VNC_LOCALHOST=yes ./start-vnc.sh"
