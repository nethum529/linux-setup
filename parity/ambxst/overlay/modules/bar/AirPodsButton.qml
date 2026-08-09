pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.config

// Dedicated one-click connect/disconnect for the AirPods Max.
Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    // Known address as a fallback if the device object isn't currently in the list.
    readonly property string fallbackAddress: "70:F9:4A:85:BD:8F"

    // Find the AirPods among known Bluetooth devices (by name).
    readonly property var dev: {
        const list = BluetoothService.devices;
        if (!list)
            return null;
        for (let i = 0; i < list.length; i++) {
            if ((list[i].name ?? "").toLowerCase().includes("airpod"))
                return list[i];
        }
        return null;
    }
    readonly property string address: dev?.address ?? fallbackAddress
    readonly property bool connected: dev?.connected ?? false
    readonly property bool busy: (dev?.connecting ?? false) || BluetoothService.isUpdating

    function toggleConnection() {
        if (connected) {
            BluetoothService.disconnectDevice(address);
        } else if (!BluetoothService.enabled) {
            BluetoothService.setEnabled(true);
            enableThenConnect.start();
        } else {
            BluetoothService.connectDevice(address);
        }
    }

    Timer {
        id: enableThenConnect
        interval: 1500
        repeat: false
        onTriggered: BluetoothService.connectDevice(root.address)
    }

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    StyledToolTip {
        show: root.isHovered
        tooltipText: root.busy ? "AirPods Max: working…" : (root.connected ? "AirPods Max: Connected\nClick to disconnect" : "AirPods Max: Disconnected\nClick to connect")
    }

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: root.connected ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        topLeftRadius: root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        bottomRightRadius: root.endRadius

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.connected ? 0 : (root.isHovered ? 0.25 : 0)
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
            text: Icons.headphones
            font.family: Icons.font
            font.pixelSize: 18
            color: root.connected ? buttonBg.item : Colors.overBackground
            opacity: root.busy ? 0.5 : (root.connected ? 1 : 0.6)

            // Gentle pulse while connecting/disconnecting
            SequentialAnimation on opacity {
                running: root.busy && Config.animDuration > 0
                loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 500; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.7; duration: 500; easing.type: Easing.InOutQuad }
            }

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
            onClicked: root.toggleConnection()
        }
    }
}
