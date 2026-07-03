# Captive Portal Rescue Widget for KDE Plasma 6

A native, glanceable system tray widget for KDE Plasma 6 (tested on Fedora) to detect, bypass, and restore DNS configurations on public Wi-Fi captive portals (such as hotels, airports, and cafes). It wraps the [captive-portal-rescue](file:///home/user/github/captive-portal-rescue) tool in a clean graphical layout.

---

## 🛠️ The Problem

Many developers configure custom static DNS servers (e.g., Cloudflare `1.1.1.1` or Google `8.8.8.8`), enable DNS-over-HTTPS (DoH), or run VPN mesh networks like Tailscale or WireGuard. 

Public Wi-Fi captive portals rely on **DNS hijacking** to redirect your initial browser requests to their login/landing page. Custom DNS and VPN configs block this redirection, preventing you from reaching the login page and getting online.

This widget provides a simple desktop UI to:
1. Detect when a captive portal is redirecting or hijacking traffic.
2. Temporarily configure your active NetworkManager connection to ignore custom DNS and bind to the gateway's DNS.
3. Automatically launch your default browser to trigger the portal login page.
4. Prompt you to restore your secure, custom DNS/VPN settings with a single click once you are authenticated and online.

---

## ✨ Features

* 📊 **Live Status Monitoring:** Periodically checks your active Wi-Fi profile, custom DNS settings, active VPN interfaces, and internet connectivity.
* 🛡️ **Bypass Custom DNS (Rescue):** Overrides custom DNS settings to bind directly to the portal's internal gateway IP, allowing the browser to load the login page.
* 🚀 **Trigger Portal Page:** Once bypassed, a button appears to automatically trigger browser redirection using http://neverssl.com.
* 🔄 **Single-Click Restore:** Shows a prominent notification when running on bypassed settings, letting you revert to your secure configurations with one click.
* ⚠️ **VPN Detection:** Flags active VPN interfaces (Tailscale, WireGuard, openvpn, etc.) that could conflict with the gateway redirect.

---

## 🚀 Installation & Setup

### Method 1: Symbolic Link for Development (Recommended)

To install the widget from source:

```bash
# 1. Link the repository into your local Plasma widgets directory
ln -s ~/github/org.fedora.captiveportal ~/.local/share/plasma/plasmoids/org.fedora.captiveportal

# 2. Rebuild the KDE configuration cache
kbuildsycoca6

# 3. Restart the Plasma shell to load the widget
systemctl --user restart plasma-plasmashell
```

### Method 2: Installing a `.plasmoid` Package

```bash
# To install for the first time
kpackagetool6 --type Plasma/Applet --install org.fedora.captiveportal.plasmoid
```

---

## 🎨 How to Add the Widget

1. **Right-click** on your desktop wallpaper or panel.
2. Click **Add Widgets...** (or press `Meta+Alt+A`).
3. Search for **"Captive Portal Rescue"**.
4. **Drag and drop** it onto your panel or desktop!

---

## 💻 CLI Usage

The backend helper script can also be run directly in the terminal to inspect connection details:

```bash
# Get connection status in JSON format
python3 contents/ui/backend.py --status

# Execute captive portal rescue
python3 contents/ui/backend.py --rescue

# Restore custom DNS settings
python3 contents/ui/backend.py --restore
```

---

## 🔒 Security & Privacy

This widget operates locally and respects your privacy:
* **Local-First Execution:** Network profiles and DNS configurations are edited using local NetworkManager APIs.
* **No Telemetry:** No user data, location details, or configuration stats are logged or transmitted.
* **Safe Overrides:** DNS overrides are temporary and can be rolled back at any time.

---

## License

MIT License. Free to modify and share!
