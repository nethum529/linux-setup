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

    property bool popupOpen: audioPopup.isOpen
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property real volume: Audio.value

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    StyledToolTip {
        show: root.isHovered && !root.popupOpen
        tooltipText: (root.muted ? "Muted" : ("Volume: " + Math.round(root.volume * 100) + "%")) + "\nClick for sound devices & mixer"
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
            text: Audio.volumeIcon(root.volume, root.muted)
            font.family: Icons.font
            font.pixelSize: 18
            color: root.popupOpen ? buttonBg.item : (root.muted ? Colors.overBackground : Styling.srItem("overprimary"))
            opacity: (root.popupOpen || !root.muted) ? 1 : 0.5

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
                    Audio.toggleMute();
                else
                    audioPopup.toggle();
            }
        }
    }

    // Left-click popup: the dashboard Sound mixer (output/input devices + per-device & per-app volume)
    BarPopup {
        id: audioPopup
        anchorItem: buttonBg
        bar: root.bar
        contentWidth: 400
        contentHeight: 500

        Loader {
            anchors.fill: parent
            active: audioPopup.isOpen
            sourceComponent: AudioMixerPanel {}
        }
    }
}
