````markdown
# 🐧 Linux-Droid16  
**Run Debian XFCE on GrapheneOS / Android 16 without root or virtualization**

A minimal setup for launching a full Debian Linux desktop inside **Android 16 Terminal**, viewable through the **Run VNC** app — completely **userland**, no `systemd`, no `root`, no `virtualization`.

---

## 🧩 Overview

This project provides two ready-to-run scripts:

| Script | Where to Run | Purpose |
|---------|---------------|----------|
| [`phase1_setup.sh`](https://raw.githubusercontent.com/if-ai/linux-droid16/main/phase1_setup.sh) | Android 16 Terminal | Installs Debian userland via `proot-distro` and creates a launcher |
| [`phase2_3_one_shot.sh`](https://raw.githubusercontent.com/if-ai/linux-droid16/main/phase2_3_one_shot.sh) | Inside Debian | Installs XFCE desktop, sets up TigerVNC, and creates start/stop helpers |

---

## ⚙️ Installation Guide

### 1️⃣ Phase 1 — Base Setup (Android 16 Terminal)

Open the **Android 16 Terminal** app and run:

```bash
wget https://raw.githubusercontent.com/if-ai/linux-droid16/main/phase1_setup.sh
bash phase1_setup.sh
````

This installs Debian in a userland environment using `proot-distro`
and creates a launcher script called `debian-login.sh`.

Then enter Debian:

```bash
./debian-login.sh
```

---

### 2️⃣ Phase 2 — Debian Desktop + VNC (inside Debian)

Once inside Debian, set up the desktop environment and VNC:

```bash
wget https://raw.githubusercontent.com/if-ai/linux-droid16/main/phase2_3_one_shot.sh
bash phase2_3_one_shot.sh
```

After setup, start the VNC server:

```bash
./start-vnc.sh
```

Then open the **Run VNC** app and connect to:

```
Address: 127.0.0.1
Port: 5901
Password: (the one you set with vncpasswd)
```

You’ll see the **XFCE desktop** inside the VNC viewer.

To stop VNC later:

```bash
./stop-vnc.sh
```

---

## 🧠 What You Get

* Full **Debian (stable)** running in userland
* **XFCE4 desktop** over TigerVNC
* Safe, isolated environment — no root, no `systemd`
* Persistent filesystem via `proot-distro`
* Compatible with **GrapheneOS**, **Vanilla Android 16**, and **Termux-based terminals**

---

## 🧰 Optional — Node.js, Python, etc.

Inside Debian, you can install any server-side tools:

```bash
apt install -y curl
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install --lts
```

Then run any Node.js app locally:

```bash
node app.js
```

Accessible at:

```
http://127.0.0.1:<port>
```

---

## 🧱 Directory Structure

```
linux-droid16/
├── phase1_setup.sh          # Run in Android 16 Terminal
├── phase2_3_one_shot.sh     # Run inside Debian
├── debian-login.sh          # Auto-generated Debian launcher
├── start-vnc.sh             # VNC start helper (auto-generated)
└── stop-vnc.sh              # VNC stop helper (auto-generated)
```

---

## 🧩 Troubleshooting

**Terminal crashes after “VNC service” prompt:**

> GrapheneOS forbids low-level virtualization.
> Only use these scripts — they stay in userland (`proot`).

**Black screen in VNC:**

```bash
chmod +x ~/.vnc/xstartup
./stop-vnc.sh && ./start-vnc.sh
```

**Reset Debian completely:**

```bash
proot-distro remove debian
proot-distro install debian
```

---

## 🪶 License

[MIT License](LICENSE)

---

**Repo:** [if-ai/linux-droid16](https://github.com/if-ai/linux-droid16)
**Author:** [ImpactFrames (if@impactframes.ai)](https://impactframes.ai)

```
```
