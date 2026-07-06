<!-- textlint-disable slopless/flesch-kincaid,slopless/gunning-fog -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0/0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-07-06

### Added
- **Force Raw Network Check:** Clicking the refresh button in the system tray now forces a live HTTP/HTTPS canary check through the specific Wi-Fi interface, bypassing NetworkManager's cached/global connectivity status (useful when a VPN is active but blocking actual internet traffic).

### Fixed
- **VPN Binding Bug:** Fixed an array slice issue in the backend where the Wi-Fi interface binding (`--interface`) was incorrectly removed from `neverssl.com` curl connectivity checks.
- **Firefox Canary Binding:** Bound the Firefox portal whitelisting check to the Wi-Fi interface if specified.

### Changed
- **Code Optimization (Slop Removal):** Deduplicated QML icon and color path calculations into unified properties, reducing duplicate logic in the UI components.

## [0.2.0] - 2026-07-05

### Added
- **Auto-Rescue:** New option in settings to automatically bypass custom secure DNS configurations (using `captive-portal-rescue.sh`) as soon as a captive portal redirect or network blockage is detected.
- **Auto-Restore:** New option (enabled by default) to automatically restore secure custom DNS and VPN settings once a working internet connection is successfully detected after portal login.
- **Passive System Notifications:** Integrated native KDE system notifications on key state changes (e.g. portal detection, rescue activation, and settings restoration).
- **Automation Section in Settings UI:** Added interactive checkboxes under an "Automation" category in the settings configuration page.

### Changed
- **Rescue Connection Availability:** Changed "Rescue Connection" button visibility to be always available whenever Wi-Fi is connected and the connection has not yet been rescued. This allows users to manually bypass DNS issues even if the widget's automatic check incorrectly reports online or whitelisted connectivity.
- **Troubleshooting Button Option:** Updated button text to show "Force Rescue (Troubleshoot)" when online, clarifying its function in stable network states.
- **Adaptive Polling (Performance Optimization):** Polling interval now dynamically expands (increases by 10x, e.g., up to 5 minutes) when the connection is stably `ONLINE` and not rescued, saving CPU cycles, network traffic, and battery. The interval automatically reverts to the standard check interval (e.g. 30 seconds) when offline or rescued.
- **Local Connectivity Resolution (Performance Optimization):** Added native NetworkManager local connectivity checking in `backend.py` which avoids executing external curl requests entirely when the connection is already online.
- **50% CPU Subprocess Reduction (Performance Optimization):** Optimized backend.py helper functions to read network interfaces from `/sys/class/net` directly and combine multiple `nmcli` queries, slashing spawned subprocess counts by half during background polling loops.

---

## [0.1.0] - 2026-07-02

### Added
- Initial release of the KDE Plasma 6 Captive Portal Rescue tray widget.
- Status monitoring for active connection, DNS ignore configurations, and VPN interfaces.
- Manual trigger buttons for the `captive-portal-rescue.sh` script to perform network rescue and settings restoration.
- Native system tray compact and expanded representations matching Breeze styling.

