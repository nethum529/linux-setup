pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.services
import qs.modules.theme
import qs.modules.components
import qs.config

// HVA listening indicator: a small top pill rendered as a layer surface.
//
// The hva service publishes its FSM state atomically to
// $XDG_STATE_HOME/handy-voice/indicator.json (a JSON document with
// {listening, state, ts}) and heartbeats while listening. This window
// watches that file and shows only while the service is listening and the
// document is fresh; a stale or missing document hides the pill, so a
// crashed hva can never leave a ghost indicator behind.
//
// The X button on the right requests a coordinated cancellation: it runs
// `hva request-cancel`, which only writes a request file for the service
// to consume. The service alone cancels Handy (never a toggle), so the
// FSM cannot race the click with a pending automatic stop that would
// transcribe or paste the aborted recording. The pill hides only after
// the service confirms the discard (listening becomes false).
//
// Layout: one horizontal flow (mic + label content group, then the X
// control group) with explicit outer insets, one 8 px rhythm inside the
// content group and a 2x 16 px gap before the control. The pill width is
// the measured content plus the insets - no arbitrary padding - and every
// element sits on whole-pixel coordinates. The pill casts no shadow: the
// window is exactly pill-sized, so a shadow would clip into a halo.
PanelWindow {
    id: root

    readonly property string stateFilePath: {
        const base = Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state");
        return base + "/handy-voice/indicator.json";
    }

    //: Maximum age (s) of the heartbeat before the pill hides.
    readonly property real staleAfter: 4

    property bool listening: false
    property real ts: 0

    //: True from the first click until the service confirms the discard
    //: (listening becomes false again); dims the X so the click is seen.
    property bool cancelling: false

    //: Pill geometry. Outer insets balance the mic's left edge (12 px)
    //: with the X glyph's right edge (12 px, the 28 px hit area is inset
    //: 6 px from the pill edge). The 16 px gap between the label and the
    //: X is twice the 8 px rhythm inside the content group.
    readonly property int insetLeft: 12
    readonly property int insetRight: 6
    readonly property int groupGap: 16
    readonly property int contentSpacing: 8
    readonly property int micSize: 16
    readonly property int closeSize: 28
    readonly property int closeIconSize: 16

    TextMetrics {
        id: labelMetrics
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        text: "Listening"
    }

    readonly property int labelWidth: Math.ceil(labelMetrics.advanceWidth)

    readonly property int pillWidth:
        root.insetLeft + root.micSize + root.contentSpacing + root.labelWidth
        + root.groupGap + root.closeSize + root.insetRight

    // Follow the monitor the user is working on. During shell startup, fall
    // back to the first configured bar screen, then the first known screen.
    readonly property var targetScreen: {
        const focusedName = AxctlService.focusedMonitor?.name ?? "";
        const focusedScreen = Quickshell.screens.find(s => s.name === focusedName);
        if (focusedScreen)
            return focusedScreen;

        const list = (Config.bar && Config.bar.screenList !== undefined ? Config.bar.screenList : []);
        if (list && list.length > 0) {
            for (const s of Quickshell.screens)
                if (list.indexOf(s.name) !== -1) return s;
        }
        return Quickshell.screens[0];
    }

    screen: root.targetScreen

    implicitWidth: root.pillWidth
    implicitHeight: 40

    anchors {
        top: true
    }

    // Drop the pill just below the top bar.
    WlrLayershell.margins.top: 46

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ambxst:hva"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Click-through indicator: only the X button (closeButton) is part of
    // the input region, so the layer never consumes pointer events anywhere
    // else and nothing under the pill is blocked. The pill has no keyboard
    // or key handlers at all.
    mask: Region {
        item: closeButton
    }

    visible: root.listening

    // ---- state file ---------------------------------------------------
    FileView {
        id: stateFile
        path: root.stateFilePath
        atomicWrites: true
        watchChanges: true
        preload: true

        onFileChanged: reload()
        onLoaded: root.applyState(text())
        onLoadFailed: root.listening = false
    }

    //: Watchdog: re-reads the file and hides a stale heartbeat.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            stateFile.reload();
            if (root.listening && (Date.now() / 1000) - root.ts > root.staleAfter)
                root.listening = false;
        }
    }

    Component.onCompleted: stateFile.reload()

    function applyState(text) {
        try {
            const state = JSON.parse(text);
            root.ts = Number(state.ts || 0);
            const fresh = (Date.now() / 1000) - root.ts <= root.staleAfter;
            const listening = state.listening === true && fresh;
            if (listening)
                root.cancelling = false;
            root.listening = listening;
        } catch (e) {
            root.listening = false;
        }
    }

    //: Ask the hva service to cancel the current session (coordinated:
    //: only the service touches Handy, so no toggle can race the click).
    function requestCancel() {
        root.cancelling = true;
        cancelRequest.running = true;
    }

    Process {
        id: cancelRequest
        running: false
        command: ["hva", "request-cancel"]
        onExited: (code, exitStatus) => {
            if (code !== 0)
                console.warn("HvaIndicator: hva request-cancel failed with exit code", code);
        }
    }

    // ---- pill ---------------------------------------------------------
    StyledRect {
        id: pill
        anchors.centerIn: parent
        width: root.pillWidth
        height: 40
        variant: "transparent"
        color: "#000000"
        radius: height / 2
        enableBorder: false
        enableShadow: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.insetLeft
            anchors.rightMargin: root.insetRight
            spacing: root.groupGap

            RowLayout {
                spacing: root.contentSpacing
                Layout.alignment: Qt.AlignVCenter

                Image {
                    source: Qt.resolvedUrl("../../assets/lucide/mic.svg")
                    sourceSize.width: root.micSize
                    sourceSize.height: root.micSize
                    Layout.preferredWidth: root.micSize
                    Layout.preferredHeight: root.micSize
                    Layout.alignment: Qt.AlignVCenter
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: "Listening"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    color: "#ffffff"
                    width: root.labelWidth
                    height: root.micSize
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // The only interactive area of the window (see the input mask):
            // discard the current recording without pasting it. The 16 px
            // glyph sits centered in a 28 px hit area; the visual right
            // edge of the X lands 12 px from the pill edge, mirroring the
            // mic's left edge. Feedback is glyph opacity only - no
            // background, shadow, or scale.
            MouseArea {
                id: closeButton
                width: root.closeSize
                height: root.closeSize
                Layout.alignment: Qt.AlignVCenter
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                Image {
                    anchors.centerIn: parent
                    source: Qt.resolvedUrl("../../assets/lucide/x.svg")
                    sourceSize.width: root.closeIconSize
                    sourceSize.height: root.closeIconSize
                    fillMode: Image.PreserveAspectFit
                    opacity: root.cancelling ? 0.45
                             : closeButton.pressed ? 0.55
                             : closeButton.containsMouse ? 0.7 : 1

                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration / 2
                        }
                    }
                }

                onClicked: root.requestCancel()
            }
        }
    }
}
