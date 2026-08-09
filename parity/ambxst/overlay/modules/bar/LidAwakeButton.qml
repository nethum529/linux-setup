pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.components
import qs.modules.theme
import qs.config

// One-click "close lid, stay awake" toggle.
// Backed by ~/.local/bin/lidawake, which holds a block inhibitor on
// handle-lid-switch (logind) inside a transient --user unit. No root needed.
Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    readonly property string cmd: "/home/nethum/.local/bin/lidawake"

    // True while the lid-awake inhibitor is held.
    property bool awake: false

    function refresh() {
        statusProc.running = false;
        statusProc.running = true;
    }

    Process {
        id: statusProc
        running: false
        command: [root.cmd, "status"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.awake = (text.trim() === "on")
        }
    }

    Process {
        id: toggleProc
        running: false
        command: [root.cmd, "toggle"]
        onRunningChanged: if (!running)
            root.refresh()
    }

    // Reflect external changes (CLI, logout) and re-check after each wake.
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    StyledToolTip {
        show: root.isHovered
        tooltipText: root.awake ? "Lid: staying awake\nClose lid → keeps running\nClick to allow sleep" : "Lid: normal\nClose lid → suspends\nClick to stay awake"
    }

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: root.awake ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        topLeftRadius: root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        bottomRightRadius: root.endRadius

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.awake ? 0 : (root.isHovered ? 0.25 : 0)
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
            text: Icons.xeyes
            font.family: Icons.font
            font.pixelSize: 18
            color: root.awake ? buttonBg.item : Colors.overBackground
            opacity: root.awake ? 1 : 0.6

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
            onClicked: toggleProc.running = true
        }
    }
}
