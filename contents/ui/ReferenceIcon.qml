import QtQuick
import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: icon

    property string iconName: ""
    property string glyphName: iconName
    property string fallback: iconName
    property color color: Kirigami.Theme.textColor
    property bool useWindowsIconFont: !Plasmoid.configuration || Plasmoid.configuration.useWindowsIconFont !== false
    property string windowsIconFont: Plasmoid.configuration ? (Plasmoid.configuration.windowsIconFont || "") : ""
    implicitWidth: Kirigami.Units.iconSizes.smallMedium
    implicitHeight: implicitWidth

    readonly property url resolvedWindowsIconFont: {
        if (windowsIconFont.trim()) return Qt.resolvedUrl(windowsIconFont.trim());
        const path = StandardPaths.locate(StandardPaths.GenericDataLocation, "Windows7StartMenu4KDE/fonts/SegoeIcons.ttf");
        return path ? Qt.resolvedUrl(path) : "";
    }

    readonly property string windowsGlyph: {
        const glyphs = {
            "user-identity": "\uec25",
            "user-home": "\uec25",
            "document-new": "\ue8a5",
            "folder-documents": "\ue8a5",
            "viewimage": "\ue91b",
            "folder-pictures": "\ue91b",
            "audio-x-generic": "\uec4f",
            "folder-music": "\uec4f",
            "download": "\ue896",
            "folder-download": "\ue896",
            "document-open-recent": "\ue81c",
            "computer": "\uec4e",
            "configure": "\ue912",
            "settings-configure": "\ue713",
            "utilities-terminal": "\ue756",
            "system-run": "\ue8da",
            "edit-find": "\ue721",
            "system-shutdown": "\ue7e8",
            "go-next": "\ue76c",
            "go-previous": "\ue76b"
        };
        return glyphs[glyphName] || "";
    }

    readonly property bool usingWindowsGlyph: useWindowsIconFont && windowsGlyph !== "" && windowsFont.status === FontLoader.Ready
                                             && (windowsFont.name === "Segoe Fluent Icons" || windowsFont.name === "Segoe MDL2 Assets")

    FontLoader {
        id: windowsFont
        objectName: "windowsIconFontLoader"
        source: icon.resolvedWindowsIconFont
    }

    Text {
        id: glyph
        objectName: "windowsIconGlyph"
        anchors.fill: parent
        visible: icon.usingWindowsGlyph
        text: icon.windowsGlyph
        textFormat: Text.PlainText
        color: icon.color
        font.family: windowsFont.name
        font.pixelSize: Math.max(1, Math.floor(Math.min(width, height)))
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    readonly property string outlineSource: {
        const aliases = {
            "user-identity": "im-user",
            "viewimage": "image-x-generic",
            "download": "go-down",
            "settings-configure": "preferences-other"
        };
        const name = aliases[iconName] || iconName;
        if (!name) return "";
        const directories = ["actions/22", "devices/22", "mimetypes/22", "preferences/22", "apps/16"];
        for (const directory of directories) {
            const path = StandardPaths.locate(StandardPaths.GenericDataLocation, "icons/breeze-dark/" + directory + "/" + name + ".svg");
            if (path) return path;
        }
        return "";
    }

    readonly property url source: outlineSource ? Qt.resolvedUrl(outlineSource) : ""
    readonly property bool valid: usingWindowsGlyph || artwork.status === Image.Ready || fallbackIcon.valid

    Image {
        id: artwork
        objectName: "outlineArtwork"
        anchors.fill: parent
        source: icon.source
        sourceSize: Qt.size(width, height)
        visible: !icon.usingWindowsGlyph && status === Image.Ready
    }

    Kirigami.Icon {
        id: fallbackIcon
        anchors.fill: parent
        visible: !icon.usingWindowsGlyph && !artwork.visible
        source: icon.iconName
        fallback: icon.fallback
        color: icon.color
        isMask: true
        animated: false
    }
}