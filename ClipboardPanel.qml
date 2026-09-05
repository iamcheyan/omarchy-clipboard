import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "apps/iamcheyan-clipboard/modules/clipboard"

Panel {
    id: root
    moduleName: "iamcheyan.clipboard"
    manageIpc: false
    property var anchorItem: null
    property var hostWidget: null
    property bool cursorMode: false
    property bool cursorReady: false
    property real cursorGlobalX: 0
    property real cursorGlobalY: 0
    property real cursorScreenX: 0
    property real cursorScreenY: 0
    property var cursorScreen: null

    function open() { root.openAtBar(); }
    function openAtBar() {
        root.cursorMode = false;
        root.cursorReady = true;
        root.controller.show();
    }
    function openAtCursor() {
        root.cursorMode = true;
        root.cursorReady = false;
        cursorPositionProcess.running = true;
        root.controller.show();
    }
    function close() { root.controller.hide(); }
    function toggle() { root.opened ? root.close() : root.open(); }

    Process {
        id: cursorPositionProcess
        command: ["hyprctl", "cursorpos", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const position = JSON.parse(text || "{}");
                    root.cursorGlobalX = Number(position.x) || 0;
                    root.cursorGlobalY = Number(position.y) || 0;
                    root.resolveCursorScreen();
                } catch (error) {
                    root.cursorReady = true;
                }
            }
        }
        onExited: if (!running && root.cursorMode && !root.cursorReady) root.cursorReady = true
    }

    function resolveCursorScreen() {
        const screens = Quickshell.screens;
        for (let index = 0; index < screens.length; index++) {
            const candidate = screens[index];
            if (root.cursorGlobalX >= candidate.x
                    && root.cursorGlobalX < candidate.x + candidate.width
                    && root.cursorGlobalY >= candidate.y
                    && root.cursorGlobalY < candidate.y + candidate.height) {
                root.cursorScreen = candidate;
                root.cursorScreenX = candidate.x;
                root.cursorScreenY = candidate.y;
                root.cursorReady = true;
                return;
            }
        }
        root.cursorReady = true;
    }

    // Use Omarchy's own anchor/cardOrigin calculation, but keep the original
    // transparent full-screen menu surface so KeyboardPanel's card background
    // is never painted behind the clipboard UI.
    KeyboardPanel {
        id: geometry
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: false
        padding: 0
        borderSpec: Border.none()
        contentWidth: geometry.fittedContentWidth(clipboardDialog.menuWidth + clipboardDialog.previewWidth + 10)
        contentHeight: geometry.fittedContentHeight(clipboardDialog.menuHeight)
    }

    PanelWindow {
        id: clipboardWindow
        screen: root.cursorMode ? root.cursorScreen
            : (root.anchorItem && root.anchorItem.QsWindow ? root.anchorItem.QsWindow.window.screen : null)
        visible: root.opened && (!root.cursorMode || root.cursorReady)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:clipboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        ClipboardDialog {
            id: clipboardDialog
            z: 1
            x: root.cursorMode ? 0 : geometry.cardOrigin.x
            y: root.cursorMode ? 0 : geometry.cardOrigin.y
            width: root.cursorMode ? clipboardWindow.width : geometry.contentWidth
            height: root.cursorMode ? clipboardWindow.height : geometry.contentHeight
            screen: clipboardWindow.screen
            visible: root.opened
            show: root.opened
            embedded: !root.cursorMode
            positionMode: root.cursorMode ? "cursor" : "bar"
            cursorGlobalX: root.cursorGlobalX
            cursorGlobalY: root.cursorGlobalY
            screenGlobalX: root.cursorScreenX
            screenGlobalY: root.cursorScreenY
            onDismiss: root.close()
        }

        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: root.close()
        }

        Keys.onEscapePressed: root.close()
    }
}
