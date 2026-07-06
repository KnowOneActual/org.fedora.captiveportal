<!-- textlint-disable slopless/flesch-kincaid -->
# Captive portal rescue widget for KDE Plasma 6

[![Version](https://img.shields.io/badge/version-0.2.1-green.svg)](https://github.com/KnowOneActual/org.fedora.captiveportal/releases)
[![KDE Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6%2B-blue?logo=kde&logoColor=white)](https://kde.org)
[![Fedora Tested](https://img.shields.io/badge/Fedora-tested-blue?logo=fedora&logoColor=white)](https://fedoraproject.org)
[![Python 3](https://img.shields.io/badge/Python-3-blue?logo=python&logoColor=white)](https://python.org)
[![NetworkManager](https://img.shields.io/badge/NetworkManager-integrated-darkgreen?logo=linux&logoColor=white)](https://networkmanager.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A native system tray widget for KDE Plasma 6 on Fedora. It helps you log in to public Wi-Fi captive portals (like hotels, airports, and cafes). It bypasses custom DNS settings and VPNs to show the login page. Then it restores your secure settings after you connect. It wraps the [captive-portal-rescue](https://github.com/KnowOneActual/captive-portal-rescue) script in a clean graphical layout.

---

## ⚡ Quick summary (Why, what, how)

* **Why:** Custom DNS (like `1.1.1.1`) and active VPNs block public Wi-Fi login pages. Connecting at the library or a cafe usually requires manually disabling these secure settings.
* **What:** A native system tray widget that detects portal redirects, temporarily bypasses custom DNS, triggers the login page, and restores secure settings once you are online.
* **How:** It uses a local Python script to modify active NetworkManager connections, open the portal page, and restore the original profile settings automatically.

---

## 🛠️ The problem

Many developers use custom DNS (like Cloudflare `1.1.1.1` or Google `8.8.8.8`), enable DNS-over-HTTPS (DoH), or run VPNs (like Tailscale or WireGuard).

Public Wi-Fi captive portals hijack DNS to redirect your browser to their login page. Custom DNS and VPN settings block this redirect. This stops you from reaching the login page or getting online.

This widget gives you a simple tool to:
1. Detect when a portal blocks your connection.
2. Temporarily bypass custom DNS to use the portal's DNS.
3. Open your browser to trigger the login page.
4. Restore your secure DNS and VPN settings in one click after you log in.

---

## 💡 Why this exists

I developed this tool to make my own travels easier. Connecting to various public and private networks with custom DNS and active VPNs is a bit of a hassle. I wanted a fast, native desktop tool to handle it. Building this widget was also a way to learn KDE Plasma 6 development and wrap my original CLI tool, [captive-portal-rescue](https://github.com/KnowOneActual/captive-portal-rescue).

---

## ✨ Features

* 📊 **Live monitoring:** Checks your active Wi-Fi, custom DNS, active VPNs, and network state.
* 🤖 **Auto-rescue & restore:** Bypasses custom DNS when a portal is found. Restores settings once you are online.
* 🔔 **System notifications:** Native desktop alerts tell you when a portal is blocked, rescued, or restored.
* 🛡️ **DNS bypass:** Ignores custom DNS and uses the local gateway IP to load the login page.
* 🚀 **Browser trigger:** Opens the portal login page in your browser.
* 🔄 **Easy restore:** Reverts to your secure DNS and VPN settings in one click.
* 🔋 **Battery-friendly:** Polls less often when online to save battery. It uses local checks to reduce network traffic.
* ⚠️ **VPN alerts:** Warns you if active VPNs block the portal.

---

## 🚀 Installation & setup

### Method 1: Symbolic link for development (recommended)

To install the widget from source:

```bash
# 1. Link the repo into your local Plasma widgets folder
ln -s ~/github/org.fedora.captiveportal ~/.local/share/plasma/plasmoids/org.fedora.captiveportal

# 2. Rebuild the KDE configuration cache
kbuildsycoca6

# 3. Restart the Plasma shell to load the widget
systemctl --user restart plasma-plasmashell
```

### Method 2: Install a `.plasmoid` package

```bash
# To install for the first time
kpackagetool6 --type Plasma/Applet --install org.fedora.captiveportal.plasmoid
```

---

## 🎨 How to add the widget

1. **Right-click** on your desktop wallpaper or panel.
2. Click **Add Widgets...** (or press `Meta+Alt+A`).
3. Search for **"Captive Portal Rescue"**.
4. **Drag and drop** it onto your panel or desktop!

---

## 💻 CLI usage

You can also run the helper script in the terminal to see details:

```bash
# Get connection status in JSON format
python3 contents/ui/backend.py --status

# Force raw connection check, bypassing NetworkManager cache
python3 contents/ui/backend.py --status --force

# Execute captive portal rescue
python3 contents/ui/backend.py --rescue

# Restore custom DNS settings
python3 contents/ui/backend.py --restore
```

---

## 🔒 Security & privacy

This widget runs locally and respects your privacy:
* **Local execution:** It edits network profiles and DNS settings with local NetworkManager tools.
* **No telemetry:** It does not collect or send any user data.
* **Safe overrides:** DNS bypasses are temporary and easy to undo.

---

## License

[MIT License](LICENSE). Free to modify and share!
