/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-FileCopyrightText: zayronxio
 *  SPDX-FileCopyrightText: 2023 WackyIdeas <wackyideas@disroot.org>
 *  SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "parts" as Parts

Item {
    id: contentRoot

    property int showApps: 0
    property bool searching: false
    property int cellHeight: 48
    property int iconSize: 32
    property var executable
    property var configuration: Plasmoid.configuration

    property alias searchField: searchField
    property alias favoritesComponent: favoritesContainer
    property alias favoritesGrid: favoritesGrid
    property alias recentsGrid: recentsGrid
    property alias appsView: appsView
    property alias runnerGrid: runnerGrid
    property alias sidebar: sidebar

    readonly property bool recentAppsEnabled: configuration.showRecentsView && configuration.numberRecentApps > 0
    readonly property real applicationListsHeight: Math.max(cellHeight, favoritesGrid.contentHeight)
        + (recentAppsEnabled ? recentsGrid.contentHeight : 0)
        + (favoritesGrid.count > 0 && recentAppsEnabled && recentsGrid.count > 0 ? Kirigami.Units.smallSpacing * 2 + 1 : 0)
    readonly property real sidebarContentHeight: {
        const groups = [sidePanelModels.firstCategory, sidePanelModels.secondCategory, sidePanelModels.thirdCategory]
            .map(category => (category || []).filter(entry => contentRoot.entryVisible(entry)).length);
        return (groups[0] + groups[1] + groups[2]) * 44
            + (groups[0] > 0 && groups[1] > 0 ? separatorOne.implicitHeight : 0)
            + (groups[1] > 0 && groups[2] > 0 ? separatorTwo.implicitHeight : 0)
            + Kirigami.Units.smallSpacing * 2;
    }
    implicitHeight: Math.max(applicationListsHeight, sidebarContentHeight)

    onSearchingChanged: if (searching) applicationRecents.close(false)
    onShowAppsChanged: applicationRecents.close(false)

    signal searchTextChanged(string text)
    signal closeRequested()
    signal contextMenuRequested(real x, real y)

    // Covers only the empty strip under a column, so the rows above keep their
    // own context menus while bare background reaches the applet options.
    component BlankAreaMenu: MouseArea {
        property real filledHeight: 0
        anchors.left: parent.left
        anchors.right: parent.right
        y: Math.min(filledHeight, parent.height)
        height: Math.max(0, parent.height - y)
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            const p = mapToItem(contentRoot, mouse.x, mouse.y);
            contentRoot.contextMenuRequested(p.x, p.y);
        }
    }

    readonly property real listColumnRatio: 0.6
    readonly property real sideColumnRatio: 1 - listColumnRatio

    SidePanelModels {
        id: sidePanelModels
        configuration: contentRoot.configuration
    }

    // Entries the user kept enabled, keyed by the stable entry name.
    readonly property var sidePanelVisibility: {
        const stored = configuration.sidePanelVisibility;
        if (!stored || stored === "") return {};
        try { return JSON.parse(stored); } catch (e) { return {}; }
    }

    function entryVisible(entry) {
        if (configuration.referenceSidebar) {
            return typeof sidePanelModels.referenceVisibility[entry.name] !== "undefined";
        }
        return typeof contentRoot.sidePanelVisibility[entry.name] !== "undefined";
    }

    function updateSeparators() {
        separatorOne.updateVisibility();
        separatorTwo.updateVisibility();
    }

    // Search field, hidden by default since main.qml owns the visible one.
    PC3.TextField {
        id: searchField
        width: parent.width * 0.4
        height: Kirigami.Units.gridUnit * 2
        anchors {
            top: parent.top
            topMargin: Kirigami.Units.gridUnit
            horizontalCenter: parent.horizontalCenter
        }
        placeholderText: i18n("Type here to search…")
        visible: false

        onTextChanged: contentRoot.searchTextChanged(text)

        function backspace() {
            if (!visible) return;
            focus = true;
            text = text.slice(0, -1);
        }

        function appendText(newText) {
            if (!visible) return;
            focus = true;
            text = text + newText;
        }
    }

    Item {
        id: mainArea
        anchors {
            top: searchField.visible ? searchField.bottom : parent.top
            topMargin: searchField.visible ? Kirigami.Units.gridUnit : 0
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        // ---- Left column, favorites over recently used --------------------

        Item {
            id: favoritesContainer
            // The grids render every row they hold, so without this they paint
            // straight over the search field and the All Applications button.
            clip: true
            visible: contentRoot.showApps === 0 && !contentRoot.searching
            anchors { top: parent.top; left: parent.left }
            width: parent.width * contentRoot.listColumnRatio
            // Ends where its content ends instead of reserving the whole column.
            height: Math.min(favoritesGrid.height + columnSeparator.height + recentsGrid.height, parent.height)

            property alias model: favoritesGrid.externalFavoritesModel

            function tryActivate(row, col) {
                const perRow = Math.max(1, Math.floor(width / favoritesGrid.cellWidth));
                const favoritesRows = Math.ceil(favoritesGrid.count / perRow);
                if (row < favoritesRows) {
                    favoritesGrid.tryActivate(row, col);
                } else {
                    recentsGrid.tryActivate(row - favoritesRows, col);
                }
            }

            Column {
                id: favoritesColumn
                anchors.fill: parent
                spacing: 0

                Parts.FavoritesRow {
                    id: favoritesGrid
                    recentFilesPane: applicationRecents
                    clip: true
                    activeFocusOnTab: true
                    width: parent.width
                    // Favorites come first and recents keep at most one guaranteed row,
                    // so a full pinned list stays whole instead of losing its last entry.
                    height: {
                        const available = mainArea.height;
                        const reserved = (recentsGrid.visible && recentsGrid.count > 0) ? contentRoot.cellHeight : 0;
                        const rows = Math.floor((available - reserved - columnSeparator.height) / contentRoot.cellHeight);
                        return Math.max(0, Math.min(Math.max(contentHeight, contentRoot.cellHeight), rows * contentRoot.cellHeight));
                    }
                    dragEnabled: true
                    dropEnabled: true
                    cellWidth: width
                    cellHeight: contentRoot.cellHeight
                    iconSize: contentRoot.iconSize


                    onKeyNavDown: {
                        if (recentsGrid.visible && recentsGrid.count > 0) {
                            recentsGrid.forceActiveFocus();
                            recentsGrid.currentIndex = 0;
                        }
                    }
                    onKeyNavUp: contentRoot.keyNavUpRequested()
                    onKeyNavRight: sidebar.focusFirst()
                    onMenuClosed: contentRoot.closeRequested()
                }

                Rectangle {
                    id: columnSeparator
                    width: parent.width * 0.9
                    height: visible ? Kirigami.Units.smallSpacing * 2 + 1 : 0
                    color: "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: favoritesGrid.count > 0 && recentsGrid.visible && recentsGrid.count > 0

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.3
                    }
                }

                Parts.RecentsRow {
                    id: recentsGrid
                    recentFilesPane: applicationRecents
                    clip: true
                    activeFocusOnTab: true
                    width: parent.width
                    // Snapped to whole rows; a partial row would just be clipped away.
                    maximumApps: contentRoot.configuration.numberRecentApps
                    height: {
                        if (!visible) return 0;
                        const rest = mainArea.height - favoritesGrid.height - columnSeparator.height;
                        const rows = Math.floor(rest / contentRoot.cellHeight);
                        return Math.max(0, Math.min(contentHeight, rows * contentRoot.cellHeight));
                    }
                    visible: contentRoot.recentAppsEnabled
                    cellWidth: width
                    cellHeight: contentRoot.cellHeight
                    iconSize: contentRoot.iconSize
                    favoritesModel: favoritesGrid.externalFavoritesModel


                    onKeyNavUp: {
                        if (favoritesGrid.count > 0) {
                            favoritesGrid.forceActiveFocus();
                            favoritesGrid.currentIndex = favoritesGrid.count - 1;
                        }
                    }
                    onKeyNavDown: contentRoot.keyNavDownRequested()
                    onKeyNavRight: sidebar.focusFirst()
                    onMenuClosed: contentRoot.closeRequested()
                }
            }
        }

        BlankAreaMenu {
            parent: favoritesContainer
            filledHeight: favoritesGrid.height + columnSeparator.height + recentsGrid.height
            visible: favoritesContainer.visible
        }

        // ---- Left column, All Programs ------------------------------------

        ApplicationsView {
            id: appsView
            visible: contentRoot.showApps === 1 && !contentRoot.searching
            enabled: visible
            anchors { top: parent.top; left: parent.left }
            width: parent.width * contentRoot.listColumnRatio
            height: parent.height
            iconSize: contentRoot.iconSize
            cellHeight: contentRoot.cellHeight

            onExitTop: contentRoot.keyNavUpRequested()
            onExitBottom: contentRoot.keyNavDownRequested()
            onExitLeft: {
                contentRoot.showApps = 0;
                contentRoot.showAppsChangeRequested(0);
            }
        }

        // ---- Left column, search results ----------------------------------

        Item {
            id: searchContainer
            visible: contentRoot.searching
            anchors { top: parent.top; left: parent.left }
            width: parent.width * contentRoot.listColumnRatio
            height: parent.height

            ItemMultiGridView {
                id: runnerGrid
                anchors.fill: parent
                cellWidth: parent.width
                cellHeight: contentRoot.cellHeight
                iconSize: contentRoot.iconSize
                enabled: parent.visible
                z: enabled ? 5 : -1
                grabFocus: false
            }
        }

        // ---- Right column --------------------------------------------------

        FocusScope {
            id: sidebar
            objectName: "sidebar"
            visible: !applicationRecents.opened
            activeFocusOnTab: true
            width: parent.width * contentRoot.sideColumnRatio

            anchors {
                top: parent.top
                topMargin: 0
                right: parent.right
                rightMargin: Kirigami.Units.smallSpacing
                bottom: parent.bottom
            }

            signal keyNavUp()
            signal keyNavDown()
            signal keyNavLeft()

            onActiveFocusChanged: if (activeFocus && !sidebarColumn.hasFocusedEntry()) focusFirst()

            function focusFirst() {
                if (applicationRecents.opened) {
                    applicationRecents.focusFirst();
                    return;
                }
                for (let i = 0; i < sidebarColumn.children.length; i++) {
                    const child = sidebarColumn.children[i];
                    if (child && child.visible && child.objectName === "SidePanelItem") {
                        child.forceActiveFocus();
                        return;
                    }
                }
            }

            onKeyNavLeft: {
                if (favoritesContainer.visible) {
                    if (recentsGrid.visible && recentsGrid.count > 0) {
                        recentsGrid.forceActiveFocus();
                        recentsGrid.currentIndex = 0;
                    } else if (favoritesGrid.count > 0) {
                        favoritesGrid.forceActiveFocus();
                        favoritesGrid.currentIndex = 0;
                    }
                } else if (appsView.visible) {
                    appsView.focusFirst();
                }
            }

            PC3.ScrollView {
                id: sidebarScroll
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                anchors.leftMargin: Kirigami.Units.smallSpacing

                PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff
                PC3.ScrollBar.vertical.policy: PC3.ScrollBar.AsNeeded

                Column {
                    id: sidebarColumn
                    width: sidebarScroll.width
                    spacing: 0

                    function hasFocusedEntry() {
                        for (let i = 0; i < children.length; i++) {
                            if (children[i] && children[i].activeFocus) return true;
                        }
                        return false;
                    }

                    component Entry: SidePanelItem {
                        configuration: contentRoot.configuration
                        // The whole side panel is one tab stop; the arrows walk it.
                        activeFocusOnTab: false
                        width: sidebarColumn.width
                        executable: contentRoot.executable
                        onNavigateLeft: sidebar.keyNavLeft()
                        onNavigateBelow: sidebar.keyNavDown()
                        onNavigateAbove: sidebar.keyNavUp()
                        onCloseRequested: contentRoot.closeRequested()
                        onVisibleChanged: contentRoot.updateSeparators()
                    }

                    Repeater {
                        model: sidePanelModels.firstCategory.length
                        delegate: Entry {
                            required property int index
                            readonly property var entry: sidePanelModels.firstCategory[index]
                            visible: contentRoot.entryVisible(entry)
                            itemText: entry.itemText
                            description: entry.description
                            itemIcon: entry.itemIcon
                            itemIconFallback: entry.itemIconFallback
                            executableString: entry.executableString
                            executeProgram: entry.executeProgram
                            menuModel: entry.menuModel
                        }
                    }

                    SidePanelSeparator {
                        id: separatorOne
                        width: sidebarColumn.width
                    }

                    Repeater {
                        model: sidePanelModels.secondCategory.length
                        delegate: Entry {
                            required property int index
                            readonly property var entry: sidePanelModels.secondCategory[index]
                            visible: contentRoot.entryVisible(entry)
                            itemText: entry.itemText
                            description: entry.description
                            itemIcon: entry.itemIcon
                            itemIconFallback: entry.itemIconFallback
                            executableString: entry.executableString
                            executeProgram: entry.executeProgram
                            menuModel: entry.menuModel
                        }
                    }

                    SidePanelSeparator {
                        id: separatorTwo
                        width: sidebarColumn.width
                    }

                    Repeater {
                        model: sidePanelModels.thirdCategory.length
                        delegate: Entry {
                            required property int index
                            readonly property var entry: sidePanelModels.thirdCategory[index]
                            visible: contentRoot.entryVisible(entry)
                            itemText: entry.itemText
                            description: entry.description
                            itemIcon: entry.itemIcon
                            itemIconFallback: entry.itemIconFallback
                            executableString: entry.executableString
                            executeProgram: entry.executeProgram
                            menuModel: entry.menuModel
                        }
                    }
                }
            }

            BlankAreaMenu {
                filledHeight: sidebarScroll.y + sidebarColumn.height
            }
        }

        Parts.ApplicationRecentsPane {
            id: applicationRecents
            objectName: "applicationRecentsPane"
            width: parent.width * contentRoot.sideColumnRatio
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: Kirigami.Units.smallSpacing
            anchors.bottom: parent.bottom
            onItemTriggered: contentRoot.closeRequested()
        }
    }

    signal keyNavUpRequested()
    signal keyNavDownRequested()
    signal showAppsChangeRequested(int value)

    Component.onCompleted: Qt.callLater(updateSeparators)
}
