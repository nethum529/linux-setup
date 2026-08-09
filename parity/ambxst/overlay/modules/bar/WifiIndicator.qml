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

    property bool popupOpen: wifiPopup.isOpen
    readonly property bool active: NetworkService.wifiEnabled

    function wifiIcon() {
        if (!NetworkService.wifiEnabled)
            return Icons.wifiOff;
        const s = NetworkService.networkStrength;
        if (s <= 0)
            return Icons.wifiNone;
        if (s >= 66)
            return Icons.wifiHigh;
        if (s >= 33)
            return Icons.wifiMedium;
        return Icons.wifiLow;
    }

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    StyledToolTip {
        show: root.isHovered && !root.popupOpen
        tooltipText: {
            if (!NetworkService.wifiEnabled)
                return "Wi-Fi: Off\nLeft-click to toggle · Right-click for networks";
            if (NetworkService.networkName !== "")
                return "Wi-Fi: " + NetworkService.networkName + " (" + NetworkService.networkStrength + "%)\nLeft-click to toggle · Right-click for networks";
            return "Wi-Fi: On (not connected)\nLeft-click to toggle · Right-click for networks";
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
            text: root.wifiIcon()
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
                    wifiPopup.toggle();
                else
                    NetworkService.toggleWifi();
            }
        }
    }

    // Right-click popup: the same Wi-Fi panel used in the dashboard
    BarPopup {
        id: wifiPopup
        anchorItem: buttonBg
        bar: root.bar
        contentWidth: 360
        contentHeight: 440

        Loader {
            anchors.fill: parent
            active: wifiPopup.isOpen
            sourceComponent: WifiPanel {}
        }
    }
}
