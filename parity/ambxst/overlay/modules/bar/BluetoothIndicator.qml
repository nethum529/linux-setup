pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.modules.widgets.dashboard.controls
import qs.config

Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    property bool popupOpen: btPopup.isOpen
    readonly property bool active: BluetoothService.enabled

    function btIcon() {
        if (!BluetoothService.enabled)
            return Icons.bluetoothOff;
        if (BluetoothService.connected)
            return Icons.bluetoothConnected;
        return Icons.bluetooth;
    }

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    StyledToolTip {
        show: root.isHovered && !root.popupOpen
        tooltipText: {
            if (!BluetoothService.enabled)
                return "Bluetooth: Off\nLeft-click to toggle · Right-click for devices";
            if (BluetoothService.connected)
                return "Bluetooth: " + BluetoothService.connectedDevices + " connected\nLeft-click to toggle · Right-click for devices";
            return "Bluetooth: On\nLeft-click to toggle · Right-click for devices";
        }
    }

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: root.popupOpen ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        topLeftRadius: root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        bottomRightRadius: root.endRadius

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.popupOpen ? 0 : (root.isHovered ? 0.25 : 0)
            radius: parent.radius ?? 0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.btIcon()
            font.family: Icons.font
            font.pixelSize: 18
            color: root.popupOpen ? buttonBg.item : (root.active ? Styling.srItem("overprimary") : Colors.overBackground)
            opacity: (root.popupOpen || root.active) ? 1 : 0.5

            Behavior on color {
                enabled: Config.animDuration > 0
                ColorAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    btPopup.toggle();
                else
                    BluetoothService.toggle();
            }
        }
    }

    // Right-click popup: the same Bluetooth panel used in the dashboard
    BarPopup {
        id: btPopup
        anchorItem: buttonBg
        bar: root.bar
        contentWidth: 360
        contentHeight: 440

        Loader {
            anchors.fill: parent
            active: btPopup.isOpen
            sourceComponent: BluetoothPanel {}
        }
    }
}
