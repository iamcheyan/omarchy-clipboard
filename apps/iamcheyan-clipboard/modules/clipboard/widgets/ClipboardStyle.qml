pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Singleton {
    id: root

    // The embedded panel supplies the host's live singletons. The standalone
    // entry point supplies the same tokens from the installed shell.
    property var palette: null
    property var style: null
    property var borderTokens: null
    property Component panelBorderComponent: null
    readonly property var panelBorderSpec: borderTokens && palette && style
        ? borderTokens.surfaceSpec("popups", "border", palette.popups.border, Math.max(1, style.space(2)))
        : null
    readonly property color panelBorderColor: panelBorderSpec ? panelBorderSpec.color : (palette ? palette.popups.border : fg)
    readonly property int panelBorderWidth: panelBorderSpec ? borderTokens.uniformWidth(panelBorderSpec) : 2
    readonly property color fg: palette ? palette.menu.text : "#cacccc"
    readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.75)
    readonly property color muted: palette ? palette.muted : "#707880"
    readonly property color bg: palette ? palette.menu.background : "#101315"
    readonly property color panel: bg
    readonly property color surface: style ? style.normalFill : Qt.rgba(fg.r, fg.g, fg.b, 0.04)
    readonly property color surfaceHover: style ? style.hoverFill : Qt.rgba(fg.r, fg.g, fg.b, 0.08)
    readonly property color surfaceSelected: palette ? palette.menu.selectedBackground : surfaceHover
    readonly property color selectedText: palette ? palette.menu.selectedText : fg
    readonly property color line: palette ? palette.menu.border : fg
    readonly property color controlBorder: style ? style.normalBorderColor : line
    readonly property color separator: Qt.rgba(line.r, line.g, line.b, line.a * 0.28)
    readonly property color accent: palette ? palette.accent : fg
    readonly property color accentSoft: style ? style.selectedAccentFill : surfaceHover
    readonly property int radius: style ? style.cornerRadius : 0
    readonly property string fontFamily: style ? style.font.menuFamily : "monospace"
    readonly property int fontPixelSmall: style ? style.font.body : 12
    readonly property int fontCaption: style ? style.font.caption : 10
    readonly property int fontSubtitle: style ? style.font.subtitle : 13
    readonly property int fontTitle: style ? style.font.title : 14
    readonly property int fontHeading: style ? style.font.heading : 16
    readonly property string cliphistDecode: (Quickshell.env("HOME") ?? "") + "/.cache/media/cliphist"

    function cleanCliphistEntry(str: string): string {
        const text = String(str).replace(/^\d+\t/, "");
        // Normalize only the presentation. The original clipboard payload
        // remains untouched for preview and paste.
        return text.split(/\r?\n/).map(line => line.replace(/^\s+/, "")).join("\n").trim();
    }
}
