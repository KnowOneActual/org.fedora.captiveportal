#!/usr/bin/env python3
import subprocess
import json
import argparse
import os
import shutil

SCRIPT_PATH = "/home/user/github/captive-portal-rescue/captive-portal-rescue.sh"


def detect_vpn_interfaces():
    try:
        interfaces = []
        for name in os.listdir("/sys/class/net"):
            if any(
                vpn_prefix in name
                for vpn_prefix in [
                    "tailscale",
                    "tun",
                    "wg",
                    "mullvad",
                    "cscotun",
                    "fortissl",
                ]
            ):
                interfaces.append(name)
        return interfaces
    except Exception:
        return []


def get_active_wifi():
    try:
        # Get active connection details in a single nmcli run
        res = subprocess.run(
            [
                "nmcli",
                "-t",
                "-f",
                "NAME,UUID,TYPE,DEVICE,ACTIVE",
                "connection",
                "show",
                "--active",
            ],
            capture_output=True,
            text=True,
            errors="replace",
            check=True,
        )
        for line in res.stdout.splitlines():
            parts = line.strip().split(":")
            if len(parts) >= 5:
                name_val, uuid_val, conn_type, dev, active = (
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4],
                )
                if active == "yes" and "wireless" in conn_type.lower():
                    return {"name": name_val, "uuid": uuid_val, "interface": dev}
    except Exception:
        pass
    return None


def check_nm_connectivity():
    try:
        res = subprocess.run(
            ["nmcli", "networking", "connectivity"],
            capture_output=True,
            text=True,
            errors="replace",
            timeout=2,
        )
        return res.stdout.strip()
    except Exception:
        return "unknown"


def check_connectivity(interface=None, force=False):
    nm_status = check_nm_connectivity()
    if nm_status == "none":
        return "OFFLINE", None
    if nm_status == "portal":
        return "PORTAL_REDIRECTED", "http://neverssl.com"

    # Setup HTTP header/timeout details
    # If interface is specified, we check if we can bind urllib to it.
    # Note: socket binding in urllib is complex, so we will use curl via subprocess
    # because curl supports binding to an interface natively and accurately.

    curl_base = ["curl", "-4", "-s", "-o", "/dev/null", "--connect-timeout", "3"]
    if interface:
        curl_base += ["--interface", interface]

    try:
        # Check HTTPS Google Canary (should return 204)
        https_res = subprocess.run(
            curl_base
            + ["-w", "%{http_code}", "https://clients3.google.com/generate_204"],
            capture_output=True,
            text=True,
            errors="replace",
        )
        if https_res.returncode == 0 and https_res.stdout.strip() == "204":
            return "ONLINE", None
    except Exception:
        pass

    try:
        # Check HTTP neverssl.com redirect
        # We want to capture redirect URL and HTTP status code
        http_res = subprocess.run(
            curl_base + ["-w", "%{http_code}\\n%{redirect_url}", "http://neverssl.com"],
            capture_output=True,
            text=True,
            errors="replace",
        )
        if http_res.returncode == 0:
            lines = http_res.stdout.strip().splitlines()
            code = lines[0].strip() if len(lines) > 0 else ""
            redirect = lines[1].strip() if len(lines) > 1 else ""

            if redirect:
                return "PORTAL_REDIRECTED", redirect

            # If 200, check Firefox portal canary
            if code == "200":
                firefox_cmd = ["curl", "-4", "-s", "--connect-timeout", "3"]
                if interface:
                    firefox_cmd += ["--interface", interface]
                firefox_res = subprocess.run(
                    firefox_cmd + ["http://detectportal.firefox.com/success.txt"],
                    capture_output=True,
                    text=True,
                    errors="replace",
                )
                if "success" in firefox_res.stdout.strip():
                    return "PORTAL_WHITELISTED", None
                else:
                    # Captive portal returns a login page instead of success.txt
                    return "PORTAL_REDIRECTED", "http://neverssl.com"
    except Exception:
        pass

    return "OFFLINE", None


def get_dns_settings(uuid_val):
    if not uuid_val:
        return "unknown", ""
    try:
        res = subprocess.run(
            [
                "nmcli",
                "-f",
                "ipv4.ignore-auto-dns,ipv4.dns",
                "-t",
                "connection",
                "show",
                uuid_val,
            ],
            capture_output=True,
            text=True,
            errors="replace",
            check=True,
        )
        ignore4 = "unknown"
        dns4 = ""
        for line in res.stdout.splitlines():
            if line.startswith("ipv4.ignore-auto-dns:"):
                ignore4 = line.split(":", 1)[1].strip()
            elif line.startswith("ipv4.dns:"):
                dns4 = line.split(":", 1)[1].strip()
        return ignore4, dns4
    except Exception:
        return "unknown", ""


def get_status(force=False):
    wifi = get_active_wifi()
    vpn_ifs = detect_vpn_interfaces()

    if not wifi:
        return {
            "status": "DISCONNECTED",
            "active_wifi_name": "None",
            "active_wifi_uuid": "None",
            "device_interface": "None",
            "ipv4_ignore_auto_dns": "unknown",
            "ipv4_dns": "",
            "rescue_status": "NORMAL",
            "vpn_active": len(vpn_ifs) > 0,
            "vpn_interfaces": ", ".join(vpn_ifs) if vpn_ifs else "None",
            "connectivity": "OFFLINE",
            "redirect_url": None,
        }

    ignore4, dns4 = get_dns_settings(wifi["uuid"])

    # Check rescue status
    is_rescued = ignore4 == "yes" and dns4 != ""
    rescue_status = "RESCUED" if is_rescued else "NORMAL"

    connectivity, redirect_url = check_connectivity(wifi["interface"], force=force)

    # Map overall status
    if connectivity == "ONLINE":
        status = "ONLINE"
    elif connectivity == "PORTAL_REDIRECTED":
        status = "PORTAL_DETECTED"
    elif connectivity == "PORTAL_WHITELISTED":
        status = "PORTAL_AWAITING_LOGIN"
    else:
        status = "OFFLINE"

    return {
        "status": status,
        "active_wifi_name": wifi["name"],
        "active_wifi_uuid": wifi["uuid"],
        "device_interface": wifi["interface"],
        "ipv4_ignore_auto_dns": ignore4,
        "ipv4_dns": dns4,
        "rescue_status": rescue_status,
        "vpn_active": len(vpn_ifs) > 0,
        "vpn_interfaces": ", ".join(vpn_ifs) if vpn_ifs else "None",
        "connectivity": connectivity,
        "redirect_url": redirect_url,
    }


def run_rescue():
    try:
        # Run the rescue shell script with --no-open to prevent spawning standard browser
        res = subprocess.run(
            ["bash", SCRIPT_PATH, "--no-open"], capture_output=True, text=True, errors="replace"
        )
        return {
            "success": res.returncode == 0,
            "stdout": res.stdout,
            "stderr": res.stderr,
        }
    except Exception as e:
        return {"success": False, "stdout": "", "stderr": str(e)}


def run_restore():
    try:
        # Run the restore shell script
        res = subprocess.run(
            ["bash", SCRIPT_PATH, "--restore"],
            capture_output=True,
            text=True,
            errors="replace",
        )
        return {
            "success": res.returncode == 0,
            "stdout": res.stdout,
            "stderr": res.stderr,
        }
    except Exception as e:
        return {"success": False, "stdout": "", "stderr": str(e)}


def open_browser_private(url):
    # 1. Get default browser desktop file
    try:
        res = subprocess.run(
            ["xdg-settings", "get", "default-web-browser"],
            capture_output=True,
            text=True,
            errors="ignore",
        )
        browser_app = res.stdout.strip()
    except Exception:
        browser_app = ""

    if not browser_app:
        try:
            res = subprocess.run(
                ["xdg-mime", "query", "default", "x-scheme-handler/http"],
                capture_output=True,
                text=True,
                errors="ignore",
            )
            browser_app = res.stdout.strip()
        except Exception:
            pass

    # Normalize name to lowercase
    app_lower = browser_app.lower()

    # Get flatpak ID if it exists
    flatpak_id = None
    if browser_app.endswith(".desktop"):
        potential_id = browser_app[:-8]
        if potential_id.count(".") >= 2:
            flatpak_id = potential_id

    # 2. Determine binary and flag
    binary = None
    flag = None

    if "firefox" in app_lower:
        binary = "firefox"
        flag = "-private-window"
        if not flatpak_id:
            flatpak_id = "org.mozilla.firefox"
    elif "chrome" in app_lower:
        binary = "google-chrome"
        flag = "--incognito"
        if not flatpak_id:
            flatpak_id = "com.google.Chrome"
    elif "chromium" in app_lower:
        binary = "chromium-browser"
        flag = "--incognito"
        if not flatpak_id:
            flatpak_id = "org.chromium.Chromium"
    elif "brave" in app_lower:
        binary = "brave-browser"
        flag = "--incognito"
        if not flatpak_id:
            flatpak_id = "com.brave.Browser"
    elif "librewolf" in app_lower:
        binary = "librewolf"
        flag = "-private-window"
        if not flatpak_id:
            flatpak_id = "io.gitlab.librewolf-community"
    elif "edge" in app_lower:
        binary = "microsoft-edge"
        flag = "--inprivate"
        if not flatpak_id:
            flatpak_id = "com.microsoft.Edge"
    elif "opera" in app_lower:
        binary = "opera"
        flag = "--private"
        if not flatpak_id:
            flatpak_id = "com.opera.Opera"
    elif "epiphany" in app_lower:
        binary = "epiphany"
        flag = "--incognito"
        if not flatpak_id:
            flatpak_id = "org.gnome.Epiphany"
    elif "falkon" in app_lower:
        binary = "falkon"
        flag = "--private-browsing"
        if not flatpak_id:
            flatpak_id = "org.kde.falkon"

    # If we couldn't match a known browser, fallback to xdg-open
    if not binary:
        try:
            subprocess.Popen(["xdg-open", url])
            return True
        except Exception:
            return False

    # Check if Flatpak is installed and the app exists as Flatpak
    flatpak_bin = shutil.which("flatpak")
    if flatpak_bin and flatpak_id:
        try:
            check_res = subprocess.run(
                ["flatpak", "info", flatpak_id],
                capture_output=True,
                text=True,
                errors="ignore"
            )
            if check_res.returncode == 0:
                subprocess.Popen(["flatpak", "run", flatpak_id, flag, url])
                return True
        except Exception:
            pass

    # Check if the binary is in PATH
    resolved_bin = shutil.which(binary)
    if not resolved_bin:
        # Fallbacks for specific common browsers
        if "chrome" in binary:
            resolved_bin = shutil.which("chrome")
        elif "chromium" in binary:
            resolved_bin = shutil.which("chromium")
        elif "brave" in binary:
            resolved_bin = shutil.which("brave")

    if not resolved_bin:
        resolved_bin = shutil.which(binary.split("-")[0])

    if resolved_bin:
        try:
            subprocess.Popen([resolved_bin, flag, url])
            return True
        except Exception:
            pass

    # Final fallback to xdg-open
    try:
        subprocess.Popen(["xdg-open", url])
        return True
    except Exception:
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Captive Portal Rescue KDE Backend Wrapper"
    )
    parser.add_argument(
        "--status", action="store_true", help="Get current connection status in JSON"
    )
    parser.add_argument(
        "--force", action="store_true", help="Force connectivity check, bypassing cache"
    )
    parser.add_argument(
        "--rescue", action="store_true", help="Execute captive portal rescue flow"
    )
    parser.add_argument(
        "--restore", action="store_true", help="Restore custom connection settings"
    )
    parser.add_argument(
        "--open-url", type=str, help="Open URL in private/incognito browser mode"
    )
    parser.add_argument(
        "--json", action="store_true", help="Force output in JSON format (default)"
    )

    args = parser.parse_args()

    if args.open_url:
        success = open_browser_private(args.open_url)
        print(json.dumps({"success": success}))
        return

    if args.rescue:
        result = run_rescue()
        # After rescue, fetch and return updated status
        status = get_status(force=args.force)
        status["action_result"] = result
        
        # Automatically open portal login page in private/incognito mode if rescued
        if result.get("success") and status.get("status") in ["PORTAL_DETECTED", "PORTAL_AWAITING_LOGIN", "OFFLINE"]:
            url = status.get("redirect_url") or "http://neverssl.com"
            open_browser_private(url)
            
        print(json.dumps(status))
    elif args.restore:
        result = run_restore()
        # After restore, fetch and return updated status
        status = get_status(force=args.force)
        status["action_result"] = result
        print(json.dumps(status))
    else:
        # Default is --status
        status = get_status(force=args.force)
        print(json.dumps(status))


if __name__ == "__main__":
    main()
