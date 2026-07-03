import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // Sizing boundaries
    implicitWidth: Kirigami.Units.gridUnit * 18
    implicitHeight: root.fullRepresentationItem ? root.fullRepresentationItem.implicitHeight : Kirigami.Units.gridUnit * 12

    // Properties mapped from backend
    property string status: "DISCONNECTED"
    property string activeWifiName: "None"
    property string activeWifiUuid: "None"
    property string deviceInterface: "None"
    property string ipv4IgnoreAutoDns: "no"
    property string ipv4Dns: ""
    property string rescueStatus: "NORMAL"
    property bool vpnActive: false
    property string vpnInterfaces: "None"
    property string connectivity: "OFFLINE"
    property string redirectUrl: ""
    property bool isRefreshing: false

    // Configuration shortcut bindings
    readonly property bool debugMode: plasmoid.configuration.debugMode
    readonly property int checkInterval: plasmoid.configuration.checkInterval

    // Styling properties
    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color mutedTextColor: Kirigami.Theme.disabledTextColor
    readonly property color accentColor: Kirigami.Theme.highlightColor
    readonly property int textStyle: plasmoid.configuration.showBackground ? Text.Normal : Text.Outline
    readonly property color outlineColor: (root.textColor.r + root.textColor.g + root.textColor.b > 1.5) ? "#a0000000" : "#a0ffffff"

    Plasmoid.title: "Captive Portal Rescue"
    Plasmoid.icon: {
        if (root.status === "ONLINE") return "network-security-activated";
        if (root.status === "PORTAL_DETECTED" || root.status === "PORTAL_AWAITING_LOGIN") return "network-security-waning";
        return "network-security-deactivated";
    }

    Plasmoid.backgroundHints: plasmoid.configuration.showBackground ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    // The data source to run the python helper script
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            var stdout = data["stdout"];
            if (stdout) {
                try {
                    var parsed = JSON.parse(stdout.trim());
                    root.status = parsed.status || "DISCONNECTED";
                    root.activeWifiName = parsed.active_wifi_name || "None";
                    root.activeWifiUuid = parsed.active_wifi_uuid || "None";
                    root.deviceInterface = parsed.device_interface || "None";
                    root.ipv4IgnoreAutoDns = parsed.ipv4_ignore_auto_dns || "no";
                    root.ipv4Dns = parsed.ipv4_dns || "";
                    root.rescueStatus = parsed.rescue_status || "NORMAL";
                    root.vpnActive = parsed.vpn_active || false;
                    root.vpnInterfaces = parsed.vpn_interfaces || "None";
                    root.connectivity = parsed.connectivity || "OFFLINE";
                    root.redirectUrl = parsed.redirect_url || "";
                } catch (e) {
                    console.log("JSON Parse error: " + e);
                }
            }
            root.isRefreshing = false;
        }

        function runStatus() {
            var scriptPath = Qt.resolvedUrl("backend.py").toString();
            if (scriptPath.indexOf("file://") === 0) {
                scriptPath = scriptPath.substring(7);
            }
            var cmd = "python3 " + scriptPath + " --status";
            connectSource(cmd);
        }

        function runRescue() {
            var scriptPath = Qt.resolvedUrl("backend.py").toString();
            if (scriptPath.indexOf("file://") === 0) {
                scriptPath = scriptPath.substring(7);
            }
            var cmd = "python3 " + scriptPath + " --rescue";
            connectSource(cmd);
        }

        function runRestore() {
            var scriptPath = Qt.resolvedUrl("backend.py").toString();
            if (scriptPath.indexOf("file://") === 0) {
                scriptPath = scriptPath.substring(7);
            }
            var cmd = "python3 " + scriptPath + " --restore";
            connectSource(cmd);
        }
    }

    function refresh() {
        if (root.isRefreshing) return;
        root.isRefreshing = true;
        executable.runStatus();
    }

    function rescue() {
        if (root.isRefreshing) return;
        root.isRefreshing = true;
        executable.runRescue();
    }

    function restore() {
        if (root.isRefreshing) return;
        root.isRefreshing = true;
        executable.runRestore();
    }

    function openLoginPage() {
        var url = root.redirectUrl ? root.redirectUrl : "http://neverssl.com";
        Qt.openUrlExternally(url);
    }

    // Auto-refresh timer
    Timer {
        id: refreshTimer
        interval: root.checkInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Main QML View
    fullRepresentation: Item {
        id: panelItem
        implicitWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: mainLayout.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: {
                        if (root.status === "ONLINE") return "network-security-activated";
                        if (root.status === "PORTAL_DETECTED" || root.status === "PORTAL_AWAITING_LOGIN") return "network-security-waning";
                        return "network-security-deactivated";
                    }
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    color: {
                        if (root.status === "ONLINE") return "#67C23A";
                        if (root.status === "PORTAL_DETECTED") return "#E6A23C";
                        if (root.status === "PORTAL_AWAITING_LOGIN") return "#409EFF";
                        return root.mutedTextColor;
                    }
                }

                PlasmaComponents.Label {
                    text: "PORTAL RESCUE"
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.letterSpacing: 1.2
                    color: root.textColor
                    style: root.textStyle
                    styleColor: root.outlineColor
                    Layout.fillWidth: true
                }

                // Refreshing dot
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.isRefreshing ? "#E6A23C" : (root.status === "ONLINE" ? "#67C23A" : (root.status === "DISCONNECTED" ? root.mutedTextColor : "#F56C6C"))
                    Layout.rightMargin: 4
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Refresh Button
                Kirigami.Icon {
                    source: "view-refresh"
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    color: root.textColor
                    opacity: refreshMouseArea.containsMouse ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                        running: root.isRefreshing
                    }

                    MouseArea {
                        id: refreshMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refresh()
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.textColor
                opacity: 0.15
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }

            // State Badge
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: statusLabel.implicitWidth + 24
                implicitHeight: Kirigami.Units.gridUnit * 1.5
                radius: 12
                color: {
                    if (root.status === "ONLINE") return "#1067C23A";
                    if (root.status === "PORTAL_DETECTED") return "#10E6A23C";
                    if (root.status === "PORTAL_AWAITING_LOGIN") return "#10409EFF";
                    return "#10909399";
                }
                border.width: 1
                border.color: {
                    if (root.status === "ONLINE") return "#4067C23A";
                    if (root.status === "PORTAL_DETECTED") return "#40E6A23C";
                    if (root.status === "PORTAL_AWAITING_LOGIN") return "#40409EFF";
                    return "#40909399";
                }

                PlasmaComponents.Label {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: {
                        if (root.status === "ONLINE") return "Connected to Internet";
                        if (root.status === "PORTAL_DETECTED") return "Captive Portal Blocked";
                        if (root.status === "PORTAL_AWAITING_LOGIN") return "Bypassed (Awaiting Login)";
                        if (root.status === "DISCONNECTED") return "No Wi-Fi Connected";
                        return "Offline";
                    }
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    color: {
                        if (root.status === "ONLINE") return "#67C23A";
                        if (root.status === "PORTAL_DETECTED") return "#E6A23C";
                        if (root.status === "PORTAL_AWAITING_LOGIN") return "#409EFF";
                        return root.textColor;
                    }
                }
            }

            // Connection Info Text
            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                color: root.textColor
                opacity: 0.85
                text: {
                    if (root.status === "ONLINE" && root.rescueStatus === "RESCUED") {
                        return "Online, but DNS is currently bypassed. Click 'Restore Settings' once you have finished.";
                    }
                    if (root.status === "ONLINE") {
                        return "Standard connection active. Secure custom DNS configurations are enabled.";
                    }
                    if (root.status === "PORTAL_DETECTED") {
                        return "Your connection to " + root.activeWifiName + " is blocked. Custom DNS or active VPNs are preventing redirection.";
                    }
                    if (root.status === "PORTAL_AWAITING_LOGIN") {
                        return "Temporarily bypassing custom DNS. Please open the portal login page to log in.";
                    }
                    if (root.status === "DISCONNECTED") {
                        return "Please select a Wi-Fi network from your connection panel to begin.";
                    }
                    return "No internet access. Gateway checking failed.";
                }
            }

            // Warning panel for VPNs
            RowLayout {
                Layout.fillWidth: true
                visible: root.vpnActive
                spacing: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "dialog-warning"
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    color: "#E6A23C"
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    color: "#E6A23C"
                    wrapMode: Text.Wrap
                    text: "Active VPNs (" + root.vpnInterfaces + ") will route traffic away from the portal gateway. Temporarily disable them if login fails."
                }
            }

            // Action Buttons
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.mediumSpacing

                // Rescue Button
                PlasmaComponents.Button {
                    Layout.fillWidth: true
                    text: "Rescue Connection"
                    icon.name: "network-wired"
                    visible: root.status === "PORTAL_DETECTED" || root.status === "OFFLINE"
                    enabled: !root.isRefreshing && root.status !== "DISCONNECTED"
                    onClicked: root.rescue()
                }

                // Open Login Page Button
                PlasmaComponents.Button {
                    Layout.fillWidth: true
                    text: "Open Login Page"
                    icon.name: "internet-services"
                    visible: root.status === "PORTAL_AWAITING_LOGIN"
                    enabled: !root.isRefreshing
                    onClicked: root.openLoginPage()
                }

                // Restore Button (Shows when rescued and online or in bypassed mode)
                PlasmaComponents.Button {
                    Layout.fillWidth: true
                    text: "Restore Settings"
                    icon.name: "edit-undo"
                    visible: root.rescueStatus === "RESCUED"
                    enabled: !root.isRefreshing
                    onClicked: root.restore()
                }
            }
        }
    }
}
