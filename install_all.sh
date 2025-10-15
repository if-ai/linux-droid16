#!/usr/bin/env bash
# install_all_apt.sh — ONE-SHOT (APT-BASED) SETUP
# For terminals that have `apt` (Debian/Ubuntu-like env on Android/GrapheneOS).
# - Installs XFCE + TigerVNC (no systemd services)
# - Creates user-level start/stop scripts for VNC and SSH
# - Works when run as root or normal user

set -Eeuo pipefail

# -------- helpers --------
have() { command -v "$1" >/dev/null 2>&1; }
die() { echo "ERROR: $*" >&2; exit 1; }
sudocmd() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

# -------- env detect --------
have apt-get || die "This script requires apt/apt-get."
if ! have sudo && [ "$(id -u)" -ne 0 ]; then
  die "sudo missing and you are not root. Install sudo or run as root."
fi

# target user (where desktop+VNC live)
if [ "$(id -u)" -eq 0 ]; then
  TARGET_USER="${TARGET_USER:-droid}"
  TARGET_HOME="/home/$TARGET_USER"
  if ! id "$TARGET_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$TARGET_USER"
    echo "$TARGET_USER:$TARGET_USER" | chpasswd
    usermod -aG sudo "$TARGET_USER" 2>/dev/null || true
  fi
else
  TARGET_USER="$(whoami)"
  TARGET_HOME="$HOME"
fi

# run-as helper
as_user() {
  if [ "$(id -u)" -eq 0 ]; then
    sudo -u "$TARGET_USER" -H bash -lc "$*"
  else
    bash -lc "$*"
  fi
}

# -------- install base packages --------
export DEBIAN_FRONTEND=noninteractive
sudocmd apt-get update -y
sudocmd apt-get install -y \
  xfce4 xfce4-goodies dbus-x11 xorg xterm \
  tigervnc-standalone-server tigervnc-common \
  openssh-server ca-certificates curl

# -------- VNC config (user-level) --------
as_user "mkdir -p '$TARGET_HOME/.vnc'"

# xstartup
as_user "cat > '$TARGET_HOME/.vnc/xstartup' <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
dbus-launch >/dev/null 2>&1 &
startxfce4
EOF
chmod +x '$TARGET_HOME/.vnc/xstartup'"

# start/stop VNC helpers
as_user "cat > '$TARGET_HOME/start-vnc.sh' <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export DISPLAY=:1
vncserver -kill :1 >/dev/null 2>&1 || true
if [ ! -f \"\$HOME/.vnc/passwd\" ]; then
  echo \"No VNC password set. You will be prompted now (min 6 chars).\"
  vncpasswd
fi
vncserver :1 -geometry 1280x720 -localhost no
echo \"VNC running on :1 (TCP 5901). Connect your VNC client to 127.0.0.1:5901\"
EOF
chmod +x '$TARGET_HOME/start-vnc.sh'"

as_user "cat > '$TARGET_HOME/stop-vnc.sh' <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
vncserver -kill :1 || true
pkill -9 Xtightvnc tigervnc Xvnc 2>/dev/null || true
echo \"VNC :1 stopped.\"
EOF
chmod +x '$TARGET_HOME/stop-vnc.sh'"

# -------- optional SSH (user-level launcher, no systemd) --------
as_user "mkdir -p '$TARGET_HOME/.ssh/sshd'"

# host keys (per-user, if not present)
if [ ! -f "$TARGET_HOME/.ssh/sshd/ssh_host_rsa_key" ]; then
  as_user "ssh-keygen -t rsa -b 3072 -f '$TARGET_HOME/.ssh/sshd/ssh_host_rsa_key' -N '' >/dev/null"
fi
if [ ! -f "$TARGET_HOME/.ssh/sshd/ssh_host_ed25519_key" ]; then
  as_user "ssh-keygen -t ed25519 -f '$TARGET_HOME/.ssh/sshd/ssh_host_ed25519_key' -N '' >/dev/null"
fi

as_user "cat > '$TARGET_HOME/.ssh/sshd_config' <<EOF
Port 10022
Protocol 2
HostKey $TARGET_HOME/.ssh/sshd/ssh_host_rsa_key
HostKey $TARGET_HOME/.ssh/sshd/ssh_host_ed25519_key
UsePAM no
PasswordAuthentication yes
PermitRootLogin prohibit-password
AllowTcpForwarding yes
ClientAliveInterval 60
Subsystem sftp internal-sftp
PidFile $TARGET_HOME/.ssh/sshd.pid
EOF"

as_user "cat > '$TARGET_HOME/start-ssh.sh' <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
CONF=\"$HOME/.ssh/sshd_config\"
PIDF=\"$HOME/.ssh/sshd.pid\"
[ -f \"$PIDF\" ] && [ -s \"$PIDF\" ] && kill \"\$(cat \"$PIDF\")\" 2>/dev/null || true
/usr/sbin/sshd -f \"$CONF\" -D &
echo \$! > \"$PIDF\"
echo \"User-level sshd started on port 10022 (user: \$USER). Use: ssh \$USER@127.0.0.1 -p 10022\"
EOF
chmod +x '$TARGET_HOME/start-ssh.sh'"

as_user "cat > '$TARGET_HOME/stop-ssh.sh' <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
PIDF=\"$HOME/.ssh/sshd.pid\"
if [ -f \"$PIDF\" ] && [ -s \"$PIDF\" ]; then
  kill \"\$(cat \"$PIDF\")\" 2>/dev/null || true
  rm -f \"$PIDF\"
  echo \"User-level sshd stopped.\"
else
  echo \"No user-level sshd running.\"
fi
EOF
chmod +x '$TARGET_HOME/stop-ssh.sh'"

# ensure ownership when run as root
if [ "$(id -u)" -eq 0 ]; then
  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.vnc" "$TARGET_HOME/.ssh" \
    "$TARGET_HOME/start-vnc.sh" "$TARGET_HOME/stop-vnc.sh" \
    "$TARGET_HOME/start-ssh.sh" "$TARGET_HOME/stop-ssh.sh"
fi

echo
echo "✅ Done."
echo "User:        $TARGET_USER"
echo "Home:        $TARGET_HOME"
echo
echo "Start desktop:  su - $TARGET_USER -c \"$TARGET_HOME/start-vnc.sh\"    (or run as the user)"
echo "Then connect Run VNC to:  127.0.0.1:5901"
echo "Stop desktop:   su - $TARGET_USER -c \"$TARGET_HOME/stop-vnc.sh\""
echo
echo "Optional SSH:   su - $TARGET_USER -c \"$TARGET_HOME/start-ssh.sh\""
echo "Connect:        ssh $TARGET_USER@127.0.0.1 -p 10022"
echo "Stop SSH:       su - $TARGET_USER -c \"$TARGET_HOME/stop-ssh.sh\""
