````markdown
# 🐧 Linux-Droid16  
**Run Debian XFCE on GrapheneOS / Android 16 — no root, no virtualization**

This project lets you install and run a full **Debian desktop** on Android 16 (including GrapheneOS) using only the built-in **Android Terminal** and the **Run VNC** viewer.  
Everything runs inside **userland** (`proot`), so it’s safe and reversible.

---

## 🚀 Quick Start

### 1️⃣ Clone the repository
Open the **Android 16 Terminal** app and run:

```bash
pkg update -y
pkg install -y git
git clone https://github.com/if-ai/linux-droid16.git
cd linux-droid16
````

---

### 2️⃣ Authorize scripts

Make both scripts executable:

```bash
chmod +x phase1_setup.sh phase2_3_one_shot.sh
```

---

### 3️⃣ Phase 1 — Base setup (Android Terminal)

Run the first script to install `proot-distro`, create Debian, and a launcher:

```bash
bash phase1_setup.sh
```

When it finishes, start Debian:

```bash
./debian-login.sh
```

---

### 4️⃣ Phase 2 — Desktop + VNC (inside Debian)

Now you’re inside Debian. Run the second script:

```bash
bash /root/linux-droid16/phase2_3_one_shot.sh
```

*(or adjust the path if you cloned elsewhere)*

It will:

* Install XFCE desktop + TigerVNC
* Ask you to set a VNC password
* Create `start-vnc.sh` and `stop-vnc.sh` helpers

When complete, start your desktop:

```bash
./start-vnc.sh
```

Then open **Run VNC** and connect to:

```
Address: 127.0.0.1
Port: 5901
Password: (the one you set)
```

To stop later:

```bash
./stop-vnc.sh
```

---

## 💡 Optional: Run Node.js / Local Servers

Inside Debian you can install Node.js (via nvm) and run local apps:

```bash
apt install -y curl
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install --lts
node -v
npm -v
```

Then run your app:

```bash
node app.js
```

Access it from Android at:

```
http://127.0.0.1:<port>
```

---

## 🧱 File Tree

```
linux-droid16/
├── phase1_setup.sh          # Run in Android Terminal
├── phase2_3_one_shot.sh     # Run inside Debian
├── debian-login.sh          # Auto-generated launcher
├── start-vnc.sh             # Created by script (run GUI)
└── stop-vnc.sh              # Created by script (stop GUI)
```

---

## 🛠️ Troubleshooting

**Terminal closes when enabling VNC service:**

> That’s the original Ubuntu-16 installer. Use these scripts instead — they stay in userland and don’t touch virtualization.

**Black screen in VNC:**

```bash
chmod +x ~/.vnc/xstartup
./stop-vnc.sh && ./start-vnc.sh
```

**Reset Debian environment:**

```bash
proot-distro remove debian
proot-distro install debian
```

---

## 🪶 License

MIT License

---

**Repository:** [https://github.com/if-ai/linux-droid16](https://github.com/if-ai/linux-droid16)
**Author:** ImpactFrames ([if@impactframes.ai](mailto:if@impactframes.ai))

```
```
