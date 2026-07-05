import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page
    width: childrenRect.width
    height: childrenRect.height

    property alias cfg_showBackground: showBackgroundCheckbox.checked
    property alias cfg_debugMode: debugModeCheckbox.checked
    property alias cfg_checkInterval: checkIntervalSpinBox.value
    property alias cfg_showTitle: showTitleCheckbox.checked
    property alias cfg_showDetails: showDetailsCheckbox.checked
    property alias cfg_autoRescue: autoRescueCheckbox.checked
    property alias cfg_autoRestore: autoRestoreCheckbox.checked

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        CheckBox {
            id: showBackgroundCheckbox
            Kirigami.FormData.label: i18n("Appearance:")
            text: i18n("Show background card")
        }

        CheckBox {
            id: showTitleCheckbox
            text: i18n("Show widget title")
        }

        CheckBox {
            id: showDetailsCheckbox
            text: i18n("Show network names & explanations")
        }

        CheckBox {
            id: autoRescueCheckbox
            Kirigami.FormData.label: i18n("Automation:")
            text: i18n("Automatically rescue connection on captive portals")
        }

        CheckBox {
            id: autoRestoreCheckbox
            text: i18n("Automatically restore settings when online")
        }

        CheckBox {
            id: debugModeCheckbox
            Kirigami.FormData.label: i18n("Debugging:")
            text: i18n("Enable debug logging")
        }

        SpinBox {
            id: checkIntervalSpinBox
            Kirigami.FormData.label: i18n("Polling Interval (secs):")
            from: 10
            to: 300
            stepSize: 5
        }
    }
}
