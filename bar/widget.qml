import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "iamcheyan.clipboard"

    readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
    readonly property string bindingScript: [
        'hl.unbind("SUPER + CTRL + V")',
        'hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("omarchy-shell iamcheyan.clipboard toggleAtCursor"), { description = "omarchy-clipboard" })'
    ].join("; ")
    readonly property string restoreScript: [
        'hl.unbind("SUPER + CTRL + V")',
        'hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("omarchy-shell shell toggle omarchy.clipboard"), { description = "Clipboard manager" })'
    ].join("; ")

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function applyBinding() {
        Quickshell.execDetached(["hyprctl", "eval", root.bindingScript]);
    }

    Component.onCompleted: {
        root.applyBinding();
        bindingEnsureDelay.start();
    }

    Timer {
        id: bindingEnsureDelay
        interval: 1200
        repeat: false
        onTriggered: root.applyBinding()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event && event.name === "configreloaded") bindingEnsureDelay.restart();
        }
    }

    Component.onDestruction: Quickshell.execDetached(["hyprctl", "eval", root.restoreScript])

    function injectPanel() {
        if (!panelLoader.item) return;
        panelLoader.item.bar = root.bar;
        panelLoader.item.anchorItem = button;
        panelLoader.item.hostWidget = root;
    }
    function open() {
        if (!panelLoader.item) {
            panelLoader.active = true;
            Qt.callLater(function() { if (panelLoader.item) panelLoader.item.open(); });
        } else panelLoader.item.open();
    }
    function openAtBar() {
        if (!panelLoader.item) {
            panelLoader.active = true;
            Qt.callLater(function() { if (panelLoader.item) panelLoader.item.openAtBar(); });
        } else panelLoader.item.openAtBar();
    }
    function openAtCursor() {
        if (!panelLoader.item) {
            panelLoader.active = true;
            Qt.callLater(function() { if (panelLoader.item) panelLoader.item.openAtCursor(); });
        } else panelLoader.item.openAtCursor();
    }
    function close() { if (panelLoader.item) panelLoader.item.close(); }
    function toggleAtBar() { root.opened ? root.close() : root.openAtBar(); }
    onBarChanged: injectPanel()

    IpcHandler {
        target: "iamcheyan.clipboard"
        function toggleAtCursor(): void { root.opened ? root.close() : root.openAtCursor(); }
        function openAtCursor(): void { root.openAtCursor(); }
        function toggle(): void { root.opened ? root.close() : root.openAtCursor(); }
        function open(): void { root.openAtCursor(); }
        function close(): void { root.close(); }
    }

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("../ClipboardPanel.qml")
        visible: false
        onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel); }
    }

    BarIconButton {
        id: button
        bar: root.bar
        text: "󰅌"
        tooltipText: "Clipboard history"
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton) root.toggleAtBar();
        }
    }
}
