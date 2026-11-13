/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-FileCopyrightText: 2023 WackyIdeas <wackyideas@disroot.org>
 *  SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.coreaddons 1.0 as KCoreAddons
import org.kde.kitemmodels as KItemModels
import "parts" as Parts

PlasmoidItem {
    id: kicker

    toolTipMainText: ""
    toolTipSubText: ""

    signal reset
    signal modelsRefreshed()

    property Item dragSource: null

    clip: false

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property QtObject globalFavorites: rootModel ? rootModel.favoritesModel : null
    property QtObject systemFavorites: rootModel ? rootModel.systemFavoritesModel : null

    readonly property bool hierarchical: Plasmoid.configuration.hierarchicalAllPrograms

    // Every search source reads the query from here, so the sections below the
    // search bar always answer the same text.
    property string searchQuery: ""

    KCoreAddons.KUser {
        id: kuser
    }

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon

    onSystemFavoritesChanged: {
        if (systemFavorites) {
            systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }
    }

    compactRepresentation: Item {
        Layout.minimumWidth: orb.implicitWidth
        Layout.minimumHeight: orb.implicitHeight

        OrbButton {
            id: orb
            anchors.centerIn: parent
            width: Math.min(parent.width, implicitWidth > 0 ? implicitWidth : parent.width)
            height: Math.min(parent.height, implicitHeight > 0 ? implicitHeight : parent.height)
            hovered: mouseArea.containsMouse
            pressed: kicker.expanded
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: kicker.expanded = !kicker.expanded
        }
    }

    fullRepresentation: Item {
        id: root

        Layout.minimumWidth: Layout.preferredWidth
        implicitHeight: Math.ceil(menuContent.implicitHeight + allAppsRow.implicitHeight + footerRow.implicitHeight
            + 1 + Kirigami.Units.smallSpacing * 2 - popupBackground.topInset - popupBackground.bottomInset)
        Layout.minimumHeight: Math.min(implicitHeight, Screen.height - Kirigami.Units.gridUnit * 4)
        Layout.preferredWidth: Kirigami.Units.gridUnit * 30
        Layout.maximumWidth: Layout.preferredWidth
        Layout.preferredHeight: Layout.minimumHeight
        Layout.maximumHeight: Layout.preferredHeight

        property int showApps: 0
        property bool searching: searchBar.text !== ""
        property bool systemActionInProgress: false
        property string currentAction: ""

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.backgroundColor: "#25262b"
        Kirigami.Theme.textColor: "#f2f2f2"
        Kirigami.Theme.disabledTextColor: "#9b9ba0"

        Parts.PanelPopupAttachment {
            id: popupBackground
            z: -3
            backgroundOpacity: Plasmoid.configuration.menuBackgroundOpacity
            gradient: Gradient {
                GradientStop { position: 0; color: "#303136" }
                GradientStop { position: 1; color: "#202126" }
            }

            Rectangle {
                anchors.fill: parent
                visible: Plasmoid.configuration.menuFrameOpacity > 0
                opacity: Plasmoid.configuration.menuFrameOpacity / 100
                color: Plasmoid.configuration.menuFrameUseThemeColor
                       ? Kirigami.Theme.backgroundColor
                       : Plasmoid.configuration.menuFrameColor
            }

            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.smallSpacing
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.smallSpacing
                width: menuContent.width * menuContent.listColumnRatio
                height: menuContent.height
                visible: Plasmoid.configuration.listPanelOpacity > 0
                opacity: Plasmoid.configuration.listPanelOpacity / 100
                color: Plasmoid.configuration.listPanelUseThemeColor
                       ? Kirigami.Theme.backgroundColor
                       : Plasmoid.configuration.listPanelColor
            }

            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.smallSpacing
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.smallSpacing
                width: menuContent.width * menuContent.sideColumnRatio
                height: menuContent.height
                visible: Plasmoid.configuration.sidePanelOpacity > 0
                opacity: Plasmoid.configuration.sidePanelOpacity / 100
                color: Plasmoid.configuration.sidePanelUseThemeColor
                       ? Kirigami.Theme.backgroundColor
                       : Plasmoid.configuration.sidePanelColor
            }
        }

        Rectangle {
            x: menuLayout.x
            y: menuLayout.y
            width: menuLayout.width * menuContent.listColumnRatio
            height: menuLayout.height
            z: 1
            color: "transparent"
            border.width: 1
            border.color: Kirigami.Theme.textColor
            opacity: 0.14
        }

        // Right clicking empty space inside the popup reached nothing, so the
        // applet options were only available from the panel button.
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.RightButton
            onClicked: mouse => {
                // Lets the shell refresh the applet actions, as it does for the panel menu.
                Plasmoid.contextualActionsAboutToShow();
                appletContextMenu.popup(root, mouse.x, mouse.y);
            }
        }

        PlasmaComponents3.Menu {
            id: appletContextMenu

            // Same labels the panel menu shows, straight from the applet's own actions; their icon names never reach QML, so those stay local.
            readonly property var configureAction: Plasmoid.internalAction("configure")
            readonly property var alternativesAction: Plasmoid.internalAction("alternatives")

            PlasmaComponents3.MenuItem {
                text: i18n("Edit Applications…")
                icon.name: "kmenuedit"
                enabled: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
                onTriggered: processRunner.runMenuEditor()
            }

            PlasmaComponents3.MenuSeparator {}

            PlasmaComponents3.MenuItem {
                text: appletContextMenu.configureAction ? appletContextMenu.configureAction.text : ""
                icon.name: "configure"
                visible: appletContextMenu.configureAction !== null && appletContextMenu.configureAction.visible
                height: visible ? implicitHeight : 0
                enabled: appletContextMenu.configureAction !== null && appletContextMenu.configureAction.enabled
                onTriggered: appletContextMenu.configureAction.trigger()
            }

            PlasmaComponents3.MenuItem {
                text: appletContextMenu.alternativesAction ? appletContextMenu.alternativesAction.text : ""
                icon.name: "exchange-positions"
                visible: appletContextMenu.alternativesAction !== null && appletContextMenu.alternativesAction.visible
                height: visible ? implicitHeight : 0
                enabled: appletContextMenu.alternativesAction !== null && appletContextMenu.alternativesAction.enabled
                onTriggered: appletContextMenu.alternativesAction.trigger()
            }
        }

        function executeSystemAction(command, actionType) {
            if (systemActionInProgress) return;
            systemActionInProgress = true;
            currentAction = actionType;

            const executable = kicker.executable;
            if (executable) {
                executable.exited.connect(onSystemActionCompleted);
                executable.exec(command);
            } else {
                systemActionInProgress = false;
                currentAction = "";
            }
            root.toggle();
        }

        function onSystemActionCompleted(cmd, exitCode, exitStatus, stdout, stderr) {
            const executable = kicker.executable;
            if (executable) executable.exited.disconnect(onSystemActionCompleted);
            systemActionInProgress = false;
            currentAction = "";
        }

        function toggle() {
            kicker.expanded = false;
        }

        function setShowApps(value) {
            showApps = value;
            menuContent.showApps = value;
            if (!kicker.expanded) return;
            if (value === 1) {
                Qt.callLater(() => {
                    if (kicker.expanded) menuContent.appsView.focusFirst();
                });
            } else if (menuContent.favoritesGrid.count > 0) {
                Qt.callLater(() => {
                    if (!kicker.expanded) return;
                    menuContent.favoritesGrid.currentIndex = 0;
                    menuContent.favoritesGrid.forceActiveFocus();
                });
            }
        }

        clip: false

        ColumnLayout {
            id: menuLayout
            x: popupBackground.contentRect.x
            y: popupBackground.contentRect.y
            width: popupBackground.contentRect.width
            height: popupBackground.contentRect.height
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                MenuContent {
                    id: menuContent
                    anchors.fill: parent
                    showApps: root.showApps
                    searching: root.searching
                    cellHeight: 44
                    iconSize: 36
                    executable: kicker.executable

                    onSearchTextChanged: text => {
                        root.searching = (text !== "");
                        kicker.searchQuery = text;
                    }
                    onCloseRequested: root.toggle()
                    onContextMenuRequested: (x, y) => {
                        const p = menuContent.mapToItem(root, x, y);
                        appletContextMenu.popup(root, p.x, p.y);
                    }
                    onKeyNavUpRequested: allAppsButton.forceActiveFocus()
                    onKeyNavDownRequested: allAppsButton.forceActiveFocus()
                    onShowAppsChangeRequested: value => root.setShowApps(value)
                }

                Binding {
                    target: menuContent.runnerGrid
                    property: "sections"
                    value: kicker.searchSections
                }

                Connections {
                    target: menuContent.sidebar

                    function onKeyNavUp() { allAppsButton.forceActiveFocus(); }
                    function onKeyNavDown() { powerButtons.forceActiveFocus(); }
                }
            }

            Item {
                id: allAppsRow
                implicitHeight: Kirigami.Units.gridUnit * 2
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.minimumHeight: Kirigami.Units.gridUnit * 2
                Layout.maximumHeight: Kirigami.Units.gridUnit * 2

                Item {
                    width: parent.width * menuContent.listColumnRatio
                    height: parent.height

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                        anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.14
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.positiveTextColor
                        opacity: 0.18
                        visible: Plasmoid.configuration.highlightNewApps
                                 && newlyInstalledApps.count > 0
                                 && root.showApps === 0
                                 && !root.searching
                    }

                    Parts.AllProgramsButton {
                        id: allAppsButton
                        anchors.fill: parent
                        currentShowApps: root.showApps
                        searching: root.searching
                        launcherExpanded: kicker.expanded

                        Keys.onPressed: (event) => {
                            switch (event.key) {
                            case Qt.Key_Up:
                                event.accepted = true;
                                if (root.showApps === 0) {
                                    const grid = menuContent.recentsGrid.visible && menuContent.recentsGrid.count > 0
                                               ? menuContent.recentsGrid : menuContent.favoritesGrid;
                                    grid.forceActiveFocus();
                                    grid.currentIndex = grid.count - 1;
                                } else {
                                    menuContent.appsView.focusFirst();
                                }
                                break;
                            case Qt.Key_Down:
                                event.accepted = true;
                                searchBar.focusSearchField();
                                break;
                            case Qt.Key_Right:
                                event.accepted = true;
                                powerButtons.forceActiveFocus();
                                break;
                            case Qt.Key_Left:
                                event.accepted = true;
                                if (root.searching || root.showApps === 1) allAppsButton.clicked();
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                            case Qt.Key_Space:
                                event.accepted = true;
                                allAppsButton.clicked();
                                break;
                            }
                        }

                        onSearchCancelled: {
                            searchBar.clear();
                            searchBar.focusSearchField();
                        }
                        onShowAppsChangeRequested: value => root.setShowApps(value)
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: menuLayout.width * menuContent.listColumnRatio
                Layout.alignment: Qt.AlignLeft
                Layout.preferredHeight: 1
                color: Kirigami.Theme.textColor
                opacity: 0.14
            }

            Item {
                id: footerRow
                implicitHeight: Math.max(searchBar.implicitHeight, powerButtons.implicitHeight + Kirigami.Units.smallSpacing * 2)
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.minimumHeight: Layout.preferredHeight
                Layout.maximumHeight: Layout.preferredHeight

                Parts.SearchBar {
                    id: searchBar
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * menuContent.listColumnRatio
                    menuContentRef: menuContent
                    currentShowApps: root.showApps

                    onSearchTextChanged: text => {
                        kicker.searchQuery = text;
                    }
                    onContextMenuRequested: (x, y) => {
                        const p = searchBar.mapToItem(root, x, y);
                        appletContextMenu.popup(root, p.x, p.y);
                    }
                    onEscapePressed: root.toggle()
                    onActivateResult: if (root.searching) menuContent.runnerGrid.activateCurrentResult()
                    onKeyNavUp: {
                        if (root.searching) menuContent.runnerGrid.moveSelection(-1);
                        else searchBar.navigateToResults();
                    }
                    onKeyNavDown: {
                        if (root.searching) menuContent.runnerGrid.moveSelection(1);
                        else searchBar.navigateToResults();
                    }
                    onNavigateToResults: {
                        if (root.searching) {
                            menuContent.runnerGrid.tryActivate(0, 0);
                        } else if (root.showApps === 1) {
                            menuContent.appsView.focusFirst();
                        } else {
                            menuContent.favoritesComponent.tryActivate(0, 0);
                        }
                    }
                }

                Parts.PowerButtons {
                    id: powerButtons
                    anchors.left: searchBar.right
                    anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width - x - Kirigami.Units.smallSpacing)
                    height: implicitHeight
                    actionInProgress: root.systemActionInProgress
                    onExecuteAction: (command, actionType) => root.executeSystemAction(command, actionType)
                    onCloseRequested: root.toggle()
                    onKeyNavUp: menuContent.sidebar.focusFirst()
                    onKeyNavDown: menuContent.sidebar.focusFirst()
                    onKeyNavLeft: searchBar.focusSearchField()
                }
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (root.searching) searchBar.clear(); else kicker.expanded = false;
                return;
            }
            if (event.key === Qt.Key_Up) {
                event.accepted = true;
                allAppsButton.forceActiveFocus();
                return;
            }
            if (event.key === Qt.Key_Down) {
                if (root.showApps === 1) {
                    event.accepted = true;
                    menuContent.appsView.focusFirst();
                } else if (menuContent.recentsGrid.visible && menuContent.recentsGrid.count > 0) {
                    event.accepted = true;
                    menuContent.recentsGrid.forceActiveFocus();
                    menuContent.recentsGrid.currentIndex = 0;
                }
                return;
            }
            if (event.key === Qt.Key_Backspace) {
                event.accepted = true;
                searchBar.backspace();
            } else if (event.text !== "" && event.text.trim() !== "") {
                event.accepted = true;
                searchBar.focusSearchField();
                searchBar.appendText(event.text);
            }
        }

        focus: true

        Connections {
            target: kicker
            // Without an explicit entry point the popup opens with focus on a
            // container that handles no keys, so the arrows did nothing at all.
            function onExpandedChanged() {
                if (!kicker.expanded) {
                    appletContextMenu.close();
                    powerButtons.menuIndex = -1;
                    menuContent.appsView.reset();
                }
                // The query outlives the popup otherwise, so reopening still
                // showed the previous search instead of the menu.
                searchBar.clear();
                root.setShowApps(0);
                if (kicker.expanded) Qt.callLater(() => {
                    if (kicker.expanded) searchBar.focusSearchField();
                });
            }
            function onModelsRefreshed() {
                menuContent.favoritesComponent.model = kicker.globalFavorites;
                kicker.bindAppModels(menuContent);
            }
        }

        Component.onCompleted: {
            menuContent.favoritesComponent.model = kicker.globalFavorites;
            kicker.bindAppModels(menuContent);
            // The popup is built on the first expand, so the entry point has to
            // live here too or the very first keypress lands on nothing.
            Qt.callLater(() => {
                if (kicker.expanded) searchBar.focusSearchField();
            });
        }
    }

    // Keeps the All Programs views pointed at whichever shape the model has.
    function bindAppModels(menuContent) {
        if (!menuContent || !rootModel) return;
        if (kicker.hierarchical) {
            menuContent.appsView.treeModel = rootModel;
        } else {
            menuContent.appsView.flatModel = rootModel.modelForRow(0);
        }
    }

    // Drives the glow on the All Programs button while an application the user
    // has never launched is sitting somewhere in the tree.
    KItemModels.KSortFilterProxyModel {
        id: newlyInstalledApps
        sourceModel: rootModel
        filterRowCallback: function (sourceRow, sourceParent) {
            const role = sourceModel.KItemModels.KRoleNames.role("isNewlyInstalled");
            return sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), role) === true;
        }
    }

    Kicker.RootModel {
        id: rootModel
        autoPopulate: true
        appNameFormat: Plasmoid.configuration.appNameFormat
        flat: true
        appletInterface: kicker

        // Hierarchical mode keeps the category rows so they can be expanded in
        // place; flat mode collapses everything into one alphabetical list.
        sorted: !kicker.hierarchical
        showSeparators: !kicker.hierarchical
        showTopLevelItems: kicker.hierarchical
        showAllApps: !kicker.hierarchical
        showAllAppsCategorized: false

        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        highlightNewlyInstalledApps: Plasmoid.configuration.highlightNewApps

        onRefreshed: Qt.callLater(() => kicker.modelsRefreshed())

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)

            // Seeds the ten defaults on a first run only; an existing list is never overwritten.
            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favoriteApps);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }
            refresh();
        }
    }

    Connections {
        target: Plasmoid.configuration

        function onHierarchicalAllProgramsChanged() { rootModel.refresh(); }
        function onHiddenApplicationsChanged() { rootModel.refresh(); }
        function onFavoriteSystemActionsChanged() {
            if (systemFavorites) systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }
    }

    Connections {
        target: globalFavorites
        // One way only; pushing the config list back would re-add the defaults on every start.
        function onFavoritesChanged() {
            if (target) Plasmoid.configuration.favoriteApps = target.favorites;
        }
    }

    Connections {
        target: systemFavorites
        function onFavoritesChanged() {
            if (target) Plasmoid.configuration.favoriteSystemActions = target.favorites;
        }
    }

    Connections {
        target: runnerModel
        function onQueryFinished() { kicker.rebuildSearchSections(); }
        function onCountChanged() { kicker.rebuildSearchSections(); }
    }

    // Applications and system entries. File runners are deliberately absent so
    // this model can never push a file above a program in the list.
    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: kicker
        favoritesModel: globalFavorites
        mergeResults: true
        query: kicker.searchQuery
        runners: {
            const results = ["krunner_services",
                             "krunner_systemsettings",
                             "krunner_sessions",
                             "krunner_powerdevil",
                             "calculator",
                             "unitconverter"];
            if (Plasmoid.configuration.useExtraRunners) {
                const fileRunners = ["quicksearch", "baloosearch"];
                results.push(...Plasmoid.configuration.extraRunners.filter(r => fileRunners.indexOf(r) === -1));
            }
            return results;
        }
    }

    // The extended search section: the user's own runner, or the stock Baloo
    // one when the settings ask for the KDE default.
    Kicker.RunnerModel {
        id: fileRunnerModel
        appletInterface: kicker
        favoritesModel: globalFavorites
        mergeResults: false
        query: Plasmoid.configuration.extendedSearch ? kicker.searchQuery : ""
        runners: Plasmoid.configuration.extendedSearchEngine === "kde"
                 ? ["baloosearch"]
                 : ["quicksearch"]
    }

    Kicker.RecentUsageModel {
        id: recentDocsSource
        ordering: 0 // most recent first
        shownItems: Kicker.RecentUsageModel.OnlyDocs
    }

    // KSortFilterProxyModel exposes no row mapping to QML, so activation counts
    // matches instead: with no sorting the proxy keeps the source order, so the
    // Nth visible row is the Nth source row that passes the same predicate.
    KItemModels.KSortFilterProxyModel {
        id: recentDocsResults
        sourceModel: recentDocsSource

        readonly property int displayRole: recentDocsSource.KItemModels.KRoleNames.role("display")

        function matches(sourceRow) {
            const query = kicker.searchQuery.trim().toLowerCase();
            if (query === "" || !Plasmoid.configuration.searchRecentDocuments) {
                return false;
            }
            const name = String(sourceModel.data(sourceModel.index(sourceRow, 0), displayRole) || "").toLowerCase();
            return query.split(/\s+/).every(word => name.indexOf(word) !== -1);
        }

        filterRowCallback: function (sourceRow, sourceParent) {
            return matches(sourceRow);
        }

        function trigger(row, actionId, argument) {
            let visible = -1;
            for (let i = 0; i < sourceModel.count; ++i) {
                if (matches(i) && ++visible === row) {
                    sourceModel.trigger(i, actionId || "", argument === undefined ? null : argument);
                    return;
                }
            }
        }
    }

    // Fixed section order, rebuilt whenever one of the sources answers.
    property var searchSections: []

    function rebuildSearchSections() {
        const sections = [];
        if (runnerModel.count > 0) {
            sections.push({ title: i18n("Programs"), model: runnerModel.modelForRow(0) });
        }
        if (Plasmoid.configuration.searchRecentDocuments && recentDocsResults.count > 0) {
            sections.push({ title: i18n("Recent"), model: recentDocsResults });
        }
        if (Plasmoid.configuration.extendedSearch && fileRunnerModel.count > 0) {
            sections.push({ title: i18n("Extended search"), model: fileRunnerModel.modelForRow(0) });
        }
        kicker.searchSections = sections;
    }

    onSearchQueryChanged: {
        // The proxy has no way to know the query changed; nothing re-filters
        // until it is told to.
        recentDocsResults.invalidateFilter();
        if (searchQuery === "") {
            kicker.searchSections = [];
        } else {
            rebuildSearchSections();
        }
    }

    Connections {
        target: fileRunnerModel
        function onQueryFinished() { kicker.rebuildSearchSections(); }
        function onCountChanged() { kicker.rebuildSearchSections(); }
    }

    Connections {
        target: recentDocsResults
        function onCountChanged() { kicker.rebuildSearchSections(); }
    }

    // Mirrors the search settings into the file the quicksearch runner reads, so
    // Alt+F2 and the menu share one engine and one set of roots.
    function syncQuickSearchConfig() {
        if (!kicker.executable) {
            return;
        }
        const engine = Plasmoid.configuration.extendedSearchEngine;
        const config = {
            engine: engine === "kde" ? "script" : engine,
            roots: (Plasmoid.configuration.extendedSearchPaths || []).filter(path => path !== ""),
            max_results: Plasmoid.configuration.extendedSearchMax,
            min_length: 3,
            timeout: Plasmoid.configuration.extendedSearchTimeout
        };
        const payload = JSON.stringify(config).replace(/'/g, "'\\''");
        kicker.executable.exec("printf '%s' '" + payload
            + "' > \"${XDG_CONFIG_HOME:-$HOME/.config}/krunner-quicksearch.json\"");
    }

    Connections {
        target: Plasmoid.configuration
        function onExtendedSearchEngineChanged() { kicker.syncQuickSearchConfig(); }
        function onExtendedSearchPathsChanged() { kicker.syncQuickSearchConfig(); }
        function onExtendedSearchMaxChanged() { kicker.syncQuickSearchConfig(); }
        function onExtendedSearchTimeoutChanged() { kicker.syncQuickSearchConfig(); }
    }

    property P5Support.DataSource executable: P5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner
    }

    Kicker.WindowSystem {
        id: windowSystem
    }

    KSvg.FrameSvgItem {
        id: highlightItemSvg
        visible: false
        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    KSvg.FrameSvgItem {
        id: panelSvg
        visible: false
        imagePath: "widgets/panel-background"
    }

    KSvg.FrameSvgItem {
        id: scrollbarSvg
        visible: false
        imagePath: "widgets/scrollbar"
    }

    KSvg.FrameSvgItem {
        id: backgroundSvg
        visible: false
        imagePath: "dialogs/background"
    }

    PlasmaComponents3.Label {
        id: toolTipDelegate
        width: contentWidth
        height: undefined
        property Item toolTip
        text: toolTip ? toolTip.text : ""
        textFormat: Text.PlainText
    }

    function resetDragSource() {
        dragSource = null;
    }

    function enableHideOnWindowDeactivate() {
        kicker.hideOnWindowDeactivate = true;
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: {
        windowSystem.focusIn.connect(enableHideOnWindowDeactivate);
        dragHelper.dropped.connect(resetDragSource);
        syncQuickSearchConfig();
    }
}
