<!-- textlint-disable slopless/flesch-kincaid,slopless/gunning-fog,slopless/coleman-liau -->
# Roadmap 🗺️

This document outlines the planned future features and improvements for the **Captive Portal Rescue KDE Widget**.

---

## 📋 Planned features

### 1. Interactive VPN toggle
* **Goal:** Allow users to temporarily disable active VPN interfaces (like Tailscale, WireGuard, or OpenVPN) directly from the widget panel.
* **Why:** VPNs route traffic away from the local portal gateway, which is the most common reason portal logins fail.
* **How:** Automate temporary VPN suspension (e.g. running `tailscale down` or `nmcli connection down <vpn-id>`) during the rescue flow, and restore it automatically during the restore flow.

### 2. Native KDE portal helper integration
* **Goal:** Trigger the native KDE Plasma portal login dialog instead of launching a full web browser to `neverssl.com`.
* **Why:** Native dialogs provide a cleaner, more integrated desktop experience without cluttering the browser history.

### 3. Proxy detection & warnings in GUI
* **Goal:** Detect active system proxy settings (`http_proxy`, `all_proxy`) and display a clear warning indicator in the widget layout.
* **Why:** Environment proxies intercept local HTTP traffic, blocking portal redirection and disrupting checks.

### 4. Custom portal login scripts
* **Goal:** Allow users to configure post-rescue commands or login automations for specific networks (like a library or corporate office) that require custom authentication forms.
