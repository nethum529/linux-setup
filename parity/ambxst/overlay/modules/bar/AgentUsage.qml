pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.components
import qs.modules.theme
import qs.config

// Claude Code + Codex usage indicator. Reads the JSON written by agentdash.
Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    property bool popupOpen: usagePopup.isOpen

    readonly property string usageFilePath: Quickshell.env("HOME") + "/.local/state/agentdash/usage.json"
    readonly property color claudeColor: "#D97757"
    readonly property color codexColor: "#5477C4"
    readonly property string usageFont: "JetBrainsMono Nerd Font Mono"

    // Parsed provider state
    property var claude: ({})
    property var codex: ({})
    property real fetchedAt: 0
    property bool hasError: false

    readonly property bool claudeHasData: claude.error === undefined && claude.session_pct !== undefined
    readonly property bool codexHasData: codex.error === undefined && (codex.weekly_pct !== undefined || codex.session_pct !== undefined)

    // Values shown on the compact pill (most relevant window per provider)
    readonly property real claudePct: claude.session_pct !== undefined ? claude.session_pct : -1
    readonly property real codexPct: codex.session_pct !== undefined ? codex.session_pct : (codex.weekly_pct !== undefined ? codex.weekly_pct : -1)

    readonly property real claudeWeeklyPct: claude.weekly_pct !== undefined ? claude.weekly_pct : -1
    readonly property real codexWeeklyPct: codex.weekly_pct !== undefined ? codex.weekly_pct : -1

    Layout.preferredWidth: vertical ? 36 : 88
    Layout.preferredHeight: vertical ? 76 : 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    // ---- Data loading ---------------------------------------------------
    FileView {
        id: usageFile
        path: root.usageFilePath
        onLoaded: root.parse(usageFile.text())
    }

    Timer {
        id: refreshTimer
        interval: 60000
        running: true
        repeat: true
        onTriggered: usageFile.reload()
    }

    Component.onCompleted: {
        usageFile.reload();
    }

    function parse(text) {
        try {
            const state = JSON.parse(text);
            const prov = state.providers || {};
            root.claude = prov.claude || {};
            root.codex = prov.codex || {};
            root.fetchedAt = state.fetched_at || 0;
            root.hasError = false;
        } catch (e) {
            root.hasError = true;
        }
    }

    // ---- Helpers --------------------------------------------------------
    function pctText(pct) {
        return (pct === undefined || pct === null || pct < 0) ? "–" : Math.round(pct) + "%";
    }

    function fmtResets(epoch) {
        if (!epoch)
            return "–";
        const d = new Date(epoch * 1000);
        const now = new Date();
        const pad = n => (n < 10 ? "0" : "") + n;
        const hm = pad(d.getHours()) + ":" + pad(d.getMinutes());
        if (d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate())
            return hm;
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return days[d.getDay()] + " " + hm;
    }

    function fmtFetched(epoch) {
        if (!epoch)
            return "";
        const d = new Date(epoch * 1000);
        const pad = n => (n < 10 ? "0" : "") + n;
        return pad(d.getHours()) + ":" + pad(d.getMinutes());
    }

    function tooltipText() {
        let parts = [];
        parts.push(claudeHasData ? ("Claude 5h " + Math.round(claudePct) + "%" + (claudeWeeklyPct >= 0 ? " · wk " + Math.round(claudeWeeklyPct) + "%" : "")) : "Claude –");
        if (codexHasData) {
            let codexText = "Codex";
            if (codex.session_pct !== undefined)
                codexText += " 5h " + Math.round(codex.session_pct) + "%";
            if (codexWeeklyPct >= 0)
                codexText += " · wk " + Math.round(codexWeeklyPct) + "%";
            parts.push(codexText);
        } else {
            parts.push("Codex –");
        }
        if (hasError || (!claudeHasData && !codexHasData))
            parts.push("stale");
        return parts.join("   ");
    }

    // ---- Compact bar pill ----------------------------------------------
    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        topLeftRadius: root.vertical ? root.startRadius : root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        bottomRightRadius: root.vertical ? root.endRadius : root.endRadius

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

        RowLayout {
            anchors.centerIn: parent
            width: 82
            height: parent.height
            spacing: 6
            visible: !root.vertical

            // Claude
            RowLayout {
                Layout.preferredWidth: 34
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: "C"
                    font.family: root.usageFont
                    font.pixelSize: Styling.fontSize(-2)
                    font.weight: Font.DemiBold
                    color: root.claudeColor
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.pctText(root.claudePct)
                    font.family: root.usageFont
                    font.pixelSize: Styling.monoFontSize(-2)
                    color: Colors.overBackground
                    opacity: 0.9
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 14
                color: Colors.outlineVariant
                opacity: 0.5
            }

            // Codex
            RowLayout {
                Layout.preferredWidth: 34
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: "X"
                    font.family: root.usageFont
                    font.pixelSize: Styling.fontSize(-2)
                    font.weight: Font.DemiBold
                    color: root.codexColor
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.pctText(root.codexPct)
                    font.family: root.usageFont
                    font.pixelSize: Styling.monoFontSize(-2)
                    color: Colors.overBackground
                    opacity: 0.9
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4
            visible: root.vertical

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "C " + root.pctText(root.claudePct)
                font.family: root.usageFont
                font.pixelSize: Styling.monoFontSize(-2)
                font.weight: Font.DemiBold
                color: root.claudeColor
            }

            Rectangle {
                width: 18
                height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: Colors.outlineVariant
                opacity: 0.5
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "X " + root.pctText(root.codexPct)
                font.family: root.usageFont
                font.pixelSize: Styling.monoFontSize(-2)
                font.weight: Font.DemiBold
                color: root.codexColor
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: usagePopup.toggle()
        }

        StyledToolTip {
            visible: root.isHovered && !usagePopup.isOpen
            tooltipText: root.tooltipText()
        }
    }

    // ---- Detail popup ---------------------------------------------------
    BarPopup {
        id: usagePopup
        anchorItem: buttonBg
        bar: root.bar

        contentWidth: 300
        contentHeight: popupColumn.implicitHeight + usagePopup.popupPadding * 2

        ColumnLayout {
            id: popupColumn

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: implicitHeight
            spacing: 6

            ProviderCard {
                id: claudeCard
                Layout.fillWidth: true
                title: "Claude Code"
                plan: root.claude.plan !== undefined ? root.claude.plan : ""
                accent: root.claudeColor
                sessionPct: root.claudePct
                sessionResets: root.claude.session_resets !== undefined ? root.claude.session_resets : 0
                weeklyPct: root.claudeWeeklyPct
                weeklyResets: root.claude.weekly_resets !== undefined ? root.claude.weekly_resets : 0
            }

            ProviderCard {
                id: codexCard
                Layout.fillWidth: true
                title: "Codex"
                plan: root.codex.plan !== undefined ? root.codex.plan : ""
                accent: root.codexColor
                sessionPct: root.codex.session_pct !== undefined ? root.codex.session_pct : -1
                sessionResets: root.codex.session_resets !== undefined ? root.codex.session_resets : 0
                weeklyPct: root.codexWeeklyPct
                weeklyResets: root.codex.weekly_resets !== undefined ? root.codex.weekly_resets : 0
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.hasError ? "usage data unavailable" : (root.fetchedAt > 0 ? "updated " + root.fmtFetched(root.fetchedAt) : "")
                font.family: root.usageFont
                font.pixelSize: Styling.monoFontSize(-3)
                color: Colors.overBackground
                opacity: 0.5
            }
        }
    }

    // One window row: label + reset on top, progress bar + pct below
    component UsageRow: ColumnLayout {
        id: usageRow

        required property string windowLabel
        required property real pct
        required property real resets
        required property color accent

        readonly property bool hasUsage: pct >= 0

        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: windowLabel
                font.family: root.usageFont
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.overBackground
                opacity: 0.7
            }

            Text {
                text: usageRow.hasUsage ? (resets > 0 ? "resets " + root.fmtResets(resets) : "reset pending") : "not reported"
                font.family: root.usageFont
                font.pixelSize: Styling.monoFontSize(-3)
                color: Colors.overBackground
                opacity: usageRow.hasUsage ? 0.55 : 0.4
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: usageRow.hasUsage

            Item {
                Layout.fillWidth: true
                height: 5

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Colors.outlineVariant
                }

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: parent.width * Math.max(0, Math.min(usageRow.pct, 100)) / 100
                    radius: 2
                    color: usageRow.accent
                }
            }

            Text {
                text: root.pctText(usageRow.pct)
                font.family: root.usageFont
                font.pixelSize: Styling.monoFontSize(-2)
                font.weight: Font.DemiBold
                color: usageRow.accent
            }
        }
    }

    component ProviderCard: StyledRect {
        id: card

        required property string title
        required property string plan
        required property color accent
        required property real sessionPct
        required property real sessionResets
        required property real weeklyPct
        required property real weeklyResets

        implicitHeight: cardColumn.implicitHeight + 20
        variant: "common"
        enableShadow: false
        radius: Styling.radius(-8)

        ColumnLayout {
            id: cardColumn

            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: card.title
                    font.family: root.usageFont
                    font.pixelSize: Styling.fontSize(0)
                    font.weight: Font.DemiBold
                    color: card.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: card.plan
                    font.family: root.usageFont
                    font.pixelSize: Styling.monoFontSize(-2)
                    color: Colors.overBackground
                    opacity: 0.6
                    visible: text !== ""
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            UsageRow {
                Layout.fillWidth: true
                windowLabel: "5h window"
                pct: card.sessionPct
                resets: card.sessionResets
                accent: card.accent
            }

            UsageRow {
                Layout.fillWidth: true
                windowLabel: "Weekly"
                pct: card.weeklyPct
                resets: card.weeklyResets
                accent: card.accent
            }
        }
    }
}
