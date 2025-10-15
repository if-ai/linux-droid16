#!/usr/bin/env bash
# install_all.sh — ONE-SHOT setup from Android 16 Terminal (GrapheneOS friendly)
# - Installs proot-distro + Debian
# - Sets up XFCE + TigerVNC inside Debian (user-level, no systemd)
# - Creates helper launchers so you can start Debian desktop as an “app”

set -Eeuo pipefail

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }

# 0) Sanity (Android 16 Terminal / Termux-like env)
require_cmd pkg

# 1) Android-side deps + Debian (userland)
pkg update -y
pkg upgrade -y
pkg install -y proot-distro git tmux

if ! proot-distro list | grep -q "^debian"; then
  proot-distro install debian
fi

# 2) Convenience: quick Debian shell
cat > "$HOME/debian-login.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login debian
EOF
chmod +x "$HOME/debian-login.sh"

# 3) Inject inside-Debian setup script
proot-distro login debian -- bash -lc '
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- Create a normal user "droid" if missing ---
if ! id droid >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" droid
  echo "droid:droid" | chpasswd
  usermod -aG sudo droid || true
fi

apt-get update
apt-get install -y xfce4 xfce4-goodies dbus-x11 xorg xterm tigervnc-standalone-server tigervnc-common openssh-server

# --- Per-user VNC + SSH (no systemd), for user "droid" ---
sudo -u droid bash -lc "
  set -Eeuo pipefail
  mkdir -p \$HOME/.vnc

  # xstartup
  cat > \$HOME/.vnc/xstartup <<\XEOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
dbus-launch >/dev/null 2>&1 &
startxfce4
XEOF
  chmod +x \$HOME/.vnc/xstartup

  # start/stop VNC helpers
  cat > \$HOME/start-vnc.sh <<\XEOF
#!/usr/bin/env bash
set -Eeuo pipefail
export DISPLAY=:1
vncserver -kill :1 >/dev/null 2>&1 || true
if [ ! -f \$HOME/.vnc/passwd ]; then
  echo "No VNC password set. You will be prompted now (min 6 chars)."
  vncpasswd
fi
vncserver :1 -geometry 1280x720 -localhost no
echo "VNC running on :1 (TCP 5901). Connect to 127.0.0.1:5901"
XEOF
  chmod +x \$HOME/start-vnc.sh

  cat > \$HOME/stop-vnc.sh <<\XEOF
#!/usr/bin/env bash
set -Eeuo pipefail
vncserver -kill :1 || true
pkill -9 Xtightvnc tigervnc Xvnc 2>/dev/null || true
echo "VNC :1 stopped."
XEOF
  chmod +x \$HOME/stop-vnc.sh

  # user-level sshd (optional) start/stop
  mkdir -p \$HOME/.ssh/sshd
  if ! compgen -G "\$HOME/.ssh/sshd/ssh_host_*_key" >/dev/null; then
    ssh-keygen -t rsa -b 3072 -f \$HOME/.ssh/sshd/ssh_host_rsa_key -N "" >/dev/null
    ssh-keygen -t ed25519 -f \$HOME/.ssh/sshd/ssh_host_ed25519_key -N "" >/dev/null
  fi

  cat > \$HOME/.ssh/sshd_config <<EOF2
Port 10022
Protocol 2
HostKey \$HOME/.ssh/sshd/ssh_host_rsa_key
HostKey \$HOME/.ssh/sshd/ssh_host_ed25519_key
UsePAM no
PasswordAuthentication yes
PermitRootLogin prohibit-password
AllowTcpForwarding yes
ClientAliveInterval 60
Subsystem sftp internal-sftp
PidFile \$HOME/.ssh/sshd.pid
EOF2

  cat > \$HOME/start-ssh.sh <<\XEOF
#!/usr/bin/env bash
set -Eeuo pipefail
CONF="\$HOME/.ssh/sshd_config"
PIDF="\$HOME/.ssh/sshd.pid"
[ -f "\$PIDF" ] && [ -s "\$PIDF" ] && kill "\$(cat "\$PIDF")" 2>/dev/null || true
/usr/sbin/sshd -f "\$CONF" -D &
echo \$! > "\$PIDF"
echo "User-level sshd started on port 10022 (user: droid)."
XEOF
  chmod +x \$HOME/start-ssh.sh

  cat > \$HOME/stop-ssh.sh <<\XEOF
#!/usr/bin/env bash
set -Eeuo pipefail
PIDF="\$HOME/.ssh/sshd.pid"
if [ -f "\$PIDF" ] && [ -s "\$PIDF" ]; then
  kill "\$(cat "\$PIDF")" 2>/dev/null || true
  rm -f "\$PIDF"
  echo "User-level sshd stopped."
else
  echo "No user-level sshd running."
fi
XEOF
  chmod +x \$HOME/stop-ssh.sh
"

# --- Android-side helpers that launch straight into VNC/SSH as user droid ---
exit 0
'

# 4) Android-side one-tap helpers
cat > "$HOME/debian-vnc.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Start Debian VNC session (as user droid) and keep it running
proot-distro login debian --user droid -- bash -lc '~/start-vnc.sh'
EOF
chmod +x "$HOME/debian-vnc.sh"

cat > "$HOME/debian-vnc-stop.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login debian --user droid -- bash -lc '~/stop-vnc.sh'
EOF
chmod +x "$HOME/debian-vnc-stop.sh"

cat > "$HOME/debian-ssh.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Start user-level sshd (optional)
proot-distro login debian --user droid -- bash -lc '~/start-ssh.sh'
EOF
chmod +x "$HOME/debian-ssh.sh"

cat > "$HOME/debian-ssh-stop.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login debian --user droid -- bash -lc '~/stop-ssh.sh'
EOF
chmod +x "$HOME/debian-ssh-stop.sh"

echo
echo "✅ All done."
echo "Open Debian shell:        ./debian-login.sh"
echo "Start Debian desktop:     ./debian-vnc.sh   (then connect Run VNC to 127.0.0.1:5901)"
echo "Stop Debian desktop:      ./debian-vnc-stop.sh"
echo "Start optional SSH:       ./debian-ssh.sh   (connect: ssh droid@127.0.0.1 -p 10022)"
echo "Stop optional SSH:        ./debian-ssh-stop.sh"
