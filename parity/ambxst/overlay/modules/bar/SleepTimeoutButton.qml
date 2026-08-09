pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.modules.globals
import qs.config

// Bar button controlling the whole inactivity idle chain.
// Rewrites every listener in Config.system.idle.listeners (dim -> lock ->
// screen-off -> suspend), which IdleService reads live each tick.
// "Never" parks every listener far in the future so nothing fires at all.
Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    // Sentinel timeout meaning "never" (1 year of idle). IdleService only fires
    // a listener when elapsedIdleTime >= timeout, so this never triggers.
    readonly property int neverTimeout: 31536000
    // Timeouts at or above this are displayed as "Never".
    readonly property int neverThreshold: 86400

    // Minute options offered in the menu (-1 == Never).
    readonly property var options: [5, 10, 20, 30, 60, -1]

    // Classify a listener by its onTimeout command so we can stage it.
    function roleOf(cmd) {
        cmd = cmd || "";
        if (cmd.indexOf("suspend") !== -1)
            return "suspend";
        if (cmd.indexOf("lock-session") !== -1)
            return "lock";
        if (cmd.indexOf("screen off") !== -1)
            return "screenoff";
        if (cmd.indexOf("brightness") !== -1)
            return "dim";
        return "other";
    }

    // New timeout (seconds) for a role given the target T seconds.
    // Dim & lock land just before T; screen-off at T; suspend just after.
    function stagedTimeout(role, T) {
        switch (role) {
        case "dim":
            return Math.max(T - 60, 20);
        case "lock":
            return Math.max(T - 30, 25);
        case "screenoff":
            return T;
        case "suspend":
            return T + 30;
        default:
            return T;
        }
    }

    function suspendIndex() {
        const listeners = Config.system.idle.listeners;
        if (!listeners)
            return -1;
        for (let i = 0; i < listeners.length; i++)
            if (root.roleOf(listeners[i].onTimeout) === "suspend")
                return i;
        return -1;
    }

    function findRole(role) {
        const listeners = Config.system.idle.listeners;
        if (!listeners)
            return -1;
        for (let i = 0; i < listeners.length; i++)
            if (root.roleOf(listeners[i].onTimeout) === role)
                return i;
        return -1;
    }

    // Current setting in minutes, or -1 for Never.
    function currentMinutes() {
        const listeners = Config.system.idle.listeners;
        if (!listeners || listeners.length === 0)
            return -1;
        const si = root.suspendIndex();
        if (si !== -1 && (listeners[si].timeout || 0) >= root.neverThreshold)
            return -1;
        // Derive the target T from whichever anchor listener exists.
        let idx = root.findRole("screenoff");
        if (idx !== -1)
            return Math.round((listeners[idx].timeout || 0) / 60);
        if (si !== -1)
            return Math.round(((listeners[si].timeout || 0) - 30) / 60);
        idx = root.findRole("lock");
        if (idx !== -1)
            return Math.round(((listeners[idx].timeout || 0) + 30) / 60);
        return -1;
    }

    function labelFor(min) {
        return min < 0 ? "Never" : (min + " min");
    }

    // Rewrite every listener's timeout for the chosen value (min < 0 == Never).
    function setMinutes(min) {
        const src = Config.system.idle.listeners;
        if (!src)
            return;
        const isNever = min < 0;
        const T = min * 60;
        const next = [];
        for (let i = 0; i < src.length; i++) {
            const l = src[i];
            next.push({
                "timeout": isNever ? root.neverTimeout : root.stagedTimeout(root.roleOf(l.onTimeout), T),
                "onTimeout": l.onTimeout,
                "onResume": l.onResume
            });
        }
        Config.system.idle.listeners = next;
    }

    function openMenu() {
        const cur = root.currentMinutes();
        const items = root.options.map(min => ({
            text: root.labelFor(min),
            icon: min === cur ? Icons.timer : "",
            textColor: min === cur ? Colors.primary : undefined,
            isSeparator: false,
            onTriggered: function () {
                root.setMinutes(min);
            }
        }));
        Visibilities.contextMenu.openCustomMenu(items, 160, 32, "sleeptimeout");
    }

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    StyledToolTip {
        show: root.isHovered
        tooltipText: "Inactivity timeout: " + root.labelFor(root.currentMinutes()) + "\nClick to change"
    }

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        topLeftRadius: root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        bottomRightRadius: root.endRadius

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.isHovered ? 0.25 : 0
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
            text: root.currentMinutes() < 0 ? Icons.moon : Icons.timer
            font.family: Icons.font
            font.pixelSize: 18
            color: Colors.overBackground
            opacity: root.currentMinutes() < 0 ? 0.5 : 1
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openMenu()
        }
    }
}
