import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmaComponents.Menu {
    id: menu

    popupType: QQC2.Popup.Window
    margins: -1
    font: Kirigami.Theme.defaultFont

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.backgroundColor: "#25262b"
    Kirigami.Theme.textColor: "#f2f2f2"
    Kirigami.Theme.disabledTextColor: "#9b9ba0"

    property var configuration: Plasmoid.configuration || ({})
    property Item anchorItem: null
    property bool anchorHovered: false
    property bool pointerVisited: false
    property bool menuPointerVisited: false
    property bool dismissOnMenuExit: false

    background: Rectangle {
        implicitWidth: Kirigami.Units.gridUnit * 8 + margins.left + margins.right
        implicitHeight: Kirigami.Units.gridUnit * 2 + margins.top + margins.bottom
        opacity: Math.min(100, Math.max(0, menu.configuration.menuBackgroundOpacity ?? 85) + 10) / 100
        layer.enabled: menu.opened

        readonly property QtObject margins: QtObject {
            readonly property real top: Kirigami.Units.smallSpacing
            readonly property real left: Kirigami.Units.smallSpacing
            readonly property real right: Kirigami.Units.smallSpacing
            readonly property real bottom: Kirigami.Units.smallSpacing
        }

        gradient: Gradient {
            GradientStop { position: 0; color: "#303136" }
            GradientStop { position: 1; color: "#202126" }
        }

        Rectangle {
            objectName: "flyoutTint"
            anchors.fill: parent
            opacity: menu.configuration.menuFrameOpacity > 0 ? menu.configuration.menuFrameOpacity / 100 : 0
            color: menu.configuration.menuFrameUseThemeColor
                     ? menu.Kirigami.Theme.backgroundColor
                   : (menu.configuration.menuFrameColor || "transparent")
        }
    }

    onOpened: {
        pointerVisited = anchorHovered || menuHover.hovered;
        menuPointerVisited = menuHover.hovered;
    }
    onAnchorHoveredChanged: if (anchorHovered && opened) pointerVisited = true

    property Item menuTracker: Item {
        parent: menu.contentItem ? menu.contentItem.parent : null

        HoverHandler {
            id: menuHover
            parent: menu.contentItem
            blocking: false
            onHoveredChanged: if (hovered && menu.opened) {
                menu.pointerVisited = true;
                menu.menuPointerVisited = true;
            }
        }
    }

    Timer {
        interval: 250
        running: menu.opened && menu.pointerVisited && !menuHover.hovered
             && (!menu.anchorHovered || (menu.dismissOnMenuExit && menu.menuPointerVisited))
        onTriggered: menu.close()
    }
}