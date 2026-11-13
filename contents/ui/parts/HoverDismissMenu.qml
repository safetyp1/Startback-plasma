import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.Menu {
    id: menu

    popupType: QQC2.Popup.Window
    margins: -1

    property Item anchorItem: null
    property bool anchorHovered: false
    property bool pointerVisited: false
    property bool menuPointerVisited: false
    property bool dismissOnMenuExit: false

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