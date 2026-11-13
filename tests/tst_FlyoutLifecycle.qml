import QtQuick
import QtQuick.Window
import QtCore
import QtTest
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami
import "../contents/ui" as UI
import "../contents/ui/parts" as Parts

Item {
    id: harness
    width: 640
    height: 480

    function i18n(text) { return text; }

    Kicker.DragHelper {
        id: dragHelper
    }

    QtObject {
        id: kicker
        property bool expanded: true
        property Item dragSource: null
    }

    Item {
        id: anchor
        x: 20
        y: 20
        width: 200
        height: 44
    }

    Item {
        id: focusTarget
        x: 20
        y: 100
        width: 200
        height: 44
    }

    Parts.JumpListFlyout {
        id: flyout
    }

    ListModel {
        id: documents
        ListElement { display: "Recent document"; decoration: "document-open" }
    }

    QtObject {
        id: sidebarConfiguration
        property bool useWindowsIcons: false
        property int submenuHoverDelay: 80
        property int numberRecentFiles: 10
    }

    Component {
        id: sidebarComponent
        UI.SidePanelItem {
            x: 300
            y: 100
            width: 200
            height: 44
            itemText: "Recent Items"
            menuModel: documents
            configuration: sidebarConfiguration
        }
    }

    Component {
        id: searchComponent
        Parts.SearchBar { width: 300; height: 54 }
    }

    Component {
        id: allProgramsButtonComponent
        Parts.AllProgramsButton { y: 240; width: 300; height: 40 }
    }

    Component {
        id: powerComponent
        Parts.PowerButtons { x: 20; y: 250; width: implicitWidth; height: implicitHeight }
    }

    ListModel {
        id: applications
        ListElement {
            display: "Application with a long name"
            decoration: "application-x-executable"
            favoriteId: "test.desktop"
            launcherUrl: "applications:test.desktop"
            hasRecentFiles: false
            disabled: false
        }
    }

    Component {
        id: favoritesComponent
        Parts.FavoritesRow {
            width: 300
            height: 44
            cellWidth: width
            cellHeight: 44
            iconSize: 36
            model: applications
        }
    }

    Component {
        id: persistentFavoritesComponent
        ListModel {
            function isFavorite(favoriteId) {
                for (let index = 0; index < count; ++index) {
                    if (get(index).favoriteId === favoriteId) return true;
                }
                return false;
            }
            function addFavorite(favoriteId, index) {
                insert(index === undefined ? count : index, {
                    display: favoriteId, decoration: "application-x-executable",
                    favoriteId: favoriteId, url: favoriteId
                });
            }
        }
    }

    Component {
        id: favoritesBackendViewComponent
        Parts.FavoritesRow { width: 300; height: 200; cellWidth: width; cellHeight: 44; iconSize: 36 }
    }

    Component {
        id: recentAppsViewComponent
        Parts.RecentsRow { width: 300; height: 200; cellWidth: width; cellHeight: 44; iconSize: 36; maximumApps: 10 }
    }

    Component {
        id: appDragSourceComponent
        Item {
            width: 24
            height: 24
            property string launcherUrl: "applications:dropped.desktop"
            Drag.source: this
            Drag.supportedActions: Qt.CopyAction
            Drag.proposedAction: Qt.CopyAction
        }
    }

    Component {
        id: menuConfigurationComponent
        QtObject {
            property bool showRecentsView: true
            property int numberRecentApps: 10
            property bool referenceSidebar: true
            property string sidePanelVisibility: "{}"
            property bool useWindowsIcons: false
            property int submenuHoverDelay: 80
            property int numberRecentFiles: 10
        }
    }

    Component {
        id: menuContentComponent
        UI.MenuContent { width: 640; height: implicitHeight; cellHeight: 44; iconSize: 36 }
    }

    Component {
        id: appsListViewComponent
        UI.AppsListView { width: 300; height: 200 }
    }

    Component { id: spyComponent; SignalSpy {} }

    Component {
        id: outlineIconComponent
        UI.ReferenceIcon { width: 22; height: 22; iconName: "configure"; useWindowsIconFont: false }
    }

    Component {
        id: searchResultsComponent
        UI.ItemMultiGridView {
            width: 300
            height: 180
            cellWidth: width
            cellHeight: 44
            iconSize: 36
            grabFocus: false
            sections: [{ title: "Programs", model: applications }, { title: "Recent", model: documents }]
        }
    }

    Component { id: searchModelComponent; ListModel {} }

    Component {
        id: applicationRecentsComponent
        Parts.ApplicationRecentsPane { x: 300; width: 240; height: 400 }
    }

    Component {
        id: searchActivationModelComponent
        ListModel {
            signal resultTriggered(int row)
            function trigger(row, actionId, argument) {
                resultTriggered(row);
                return false;
            }
            ListElement { display: "First matching application"; decoration: "application-x-executable"; disabled: false }
        }
    }

    Component {
        id: applicationsViewComponent
        UI.ApplicationsView { width: 300; height: 400; hierarchical: true }
    }

    Component {
        id: fileSearchComponent
        Kicker.RunnerModel {
            mergeResults: false
            runners: ["windows7startmenu-test-unavailable-runner"]
        }
    }

    Component {
        id: panelPopupComponent
        PlasmaCore.AppletPopup {
            visible: false
            margin: 12
            backgroundHints: PlasmaCore.Types.StandardBackground
            mainItem: Item { implicitWidth: 200; implicitHeight: 200 }
        }
    }

    Component { id: popupAttachmentComponent; Parts.PanelPopupAttachment {} }
    Component { id: appearanceComponent; UI.ConfigAppearance { width: 640; height: 480 } }
    Component { id: foregroundComponent; Rectangle { x: 40; y: 40; width: 12; height: 12; color: "white"; z: 10 } }

    TestCase {
        name: "FlyoutLifecycle"
        when: windowShown

        function test_recentAppDropUsesPersistentFavorites() {
            const backend = createTemporaryObject(persistentFavoritesComponent, harness);
            verify(backend);
            backend.addFavorite("applications:first.desktop");
            const favorites = createTemporaryObject(favoritesComponent, harness, { externalFavoritesModel: backend });
            verify(favorites);
            compare(favorites.dropFavoritesModel, backend);
            verify(favorites.addDroppedFavorite({ launcherUrl: "applications:pinned.desktop" }, 0));
            compare(backend.count, 2);
            compare(backend.get(0).favoriteId, "applications:pinned.desktop");
            compare(backend.get(1).favoriteId, "applications:first.desktop");
            verify(!favorites.addDroppedFavorite({ launcherUrl: "applications:pinned.desktop" }, 1));
            verify(!favorites.addDroppedFavorite({ url: "file:///tmp/document.txt" }, 0));
            favorites.dropEnabled = false;
            verify(!favorites.addDroppedFavorite({ launcherUrl: "applications:ignored.desktop" }, 0));
            compare(backend.count, 2);
            const reopened = createTemporaryObject(favoritesComponent, harness, { externalFavoritesModel: backend });
            verify(reopened);
            compare(reopened.dropFavoritesModel, backend);
            verify(backend.isFavorite("applications:pinned.desktop"));
        }

        function test_appDragDropPinsAtReleasePosition_data() {
            return [
                { tag: "before-first", existing: true, dropY: 10, expectedIndex: 0 },
                { tag: "append", existing: true, dropY: 120, expectedIndex: 2 },
                { tag: "empty-favorites", existing: false, dropY: 10, expectedIndex: 0 }
            ];
        }

        function test_appDragDropPinsAtReleasePosition(data) {
            const backend = createTemporaryObject(persistentFavoritesComponent, harness);
            verify(backend);
            if (data.existing) {
                backend.addFavorite("applications:first.desktop");
                backend.addFavorite("applications:last.desktop");
            }
            const favorites = createTemporaryObject(favoritesBackendViewComponent, harness, { externalFavoritesModel: backend });
            const source = createTemporaryObject(appDragSourceComponent, harness, { x: 400, y: 300 });
            verify(favorites);
            verify(source);
            tryCompare(favorites, "count", data.existing ? 2 : 0);
            favorites.forceLayout();
            verify(waitForPolish(favorites));
            const dropArea = findChild(favorites, "favoritesDropArea");
            verify(dropArea);
            kicker.dragSource = source;
            try {
                source.Drag.active = true;
                source.x = 10;
                source.y = data.dropY;
                tryCompare(dropArea, "containsDrag", true);
                compare(source.Drag.drop(), Qt.CopyAction);
                compare(backend.get(data.expectedIndex).favoriteId, source.launcherUrl);
                compare(backend.count, data.existing ? 3 : 1);
            } finally {
                source.Drag.cancel();
                kicker.dragSource = null;
            }
        }

        function test_allProgramsHoverHighlightClearsOnExit() {
            const model = createTemporaryObject(searchModelComponent, harness);
            verify(model);
            model.append({ display: "First app", decoration: "application-x-executable", disabled: false, hasChildren: false });
            model.append({ display: "Second app", decoration: "application-x-executable", disabled: false, hasChildren: false });
            const apps = createTemporaryObject(appsListViewComponent, harness, { model: model });
            verify(apps);
            tryCompare(apps, "count", 2);
            apps.forceActiveFocus();
            tryVerify(() => apps.rowAt(1) !== null);
            const row = apps.rowAt(1);
            const highlight = findChild(row, "applicationRowHighlight");
            verify(highlight);
            mouseMove(row, 20, row.height / 2);
            tryCompare(highlight, "visible", true);
            compare(apps.currentIndex, 1);
            mouseMove(focusTarget, 5, 5);
            tryCompare(highlight, "visible", false);
            apps.forceActiveFocus();
            keyClick(Qt.Key_Up);
            compare(apps.currentIndex, 0);
            const firstHighlight = findChild(apps.rowAt(0), "applicationRowHighlight");
            verify(firstHighlight);
            tryCompare(firstHighlight, "visible", true);
            focusTarget.forceActiveFocus();
            tryCompare(firstHighlight, "visible", false);
        }

        function test_popupHasNoResizeMargins() {
            const popup = createTemporaryObject(panelPopupComponent, harness);
            verify(popup);
            const attachment = createTemporaryObject(popupAttachmentComponent, popup.mainItem);
            verify(attachment);
            popup.visible = true;
            tryVerify(() => attachment.nativeFrame !== null);
            tryCompare(attachment.nativeFrame, "imagePath", "");
            tryCompare(popup, "leftPadding", 0);
            tryCompare(popup, "rightPadding", 0);
            tryCompare(popup, "topPadding", 0);
            tryCompare(popup, "bottomPadding", 0);
            verify(!attachment.nativeBackground.visible);
            popup.visible = false;
        }

        function test_menuHeightFitsLargerColumn_data() {
            return [
                { tag: "sidebar-minimum", favorites: 0, recent: 0 },
                { tag: "ten-recents-and-favorites", favorites: 2, recent: 10 },
                { tag: "many-favorites", favorites: 15, recent: 1 }
            ];
        }

        function test_menuHeightFitsLargerColumn(data) {
            const config = createTemporaryObject(menuConfigurationComponent, harness, { numberRecentApps: data.recent });
            const backend = createTemporaryObject(persistentFavoritesComponent, harness);
            const usage = createTemporaryObject(searchModelComponent, harness);
            verify(config);
            verify(backend);
            verify(usage);
            for (let index = 0; index < data.favorites; ++index) backend.addFavorite("applications:favorite" + index + ".desktop");
            for (let index = 0; index < 12; ++index) {
                usage.append({ display: "Recent app " + index, decoration: "application-x-executable",
                               favoriteId: "recent" + index + ".desktop", url: "applications:recent" + index + ".desktop" });
            }
            const menu = createTemporaryObject(menuContentComponent, harness, { configuration: config });
            verify(menu);
            menu.favoritesGrid.externalFavoritesModel = backend;
            menu.recentsGrid.usageModel = usage;
            tryCompare(menu.favoritesGrid, "count", data.favorites);
            tryCompare(menu.recentsGrid, "count", data.recent);
            const separator = data.favorites > 0 && data.recent > 0 ? Kirigami.Units.smallSpacing * 2 + 1 : 0;
            const listHeight = Math.max(1, data.favorites) * 44 + data.recent * 44 + separator;
            const sidebarHeight = 10 * 44 + Kirigami.Units.smallSpacing * 6;
            compare(menu.sidebarContentHeight, sidebarHeight);
            compare(menu.implicitHeight, Math.max(listHeight, sidebarHeight));
            tryCompare(menu.favoritesGrid, "height", Math.max(1, data.favorites) * 44);
            tryCompare(menu.recentsGrid, "height", data.recent * 44);
            menu.height = 60;
            compare(menu.implicitHeight, Math.max(listHeight, sidebarHeight));
            menu.searching = true;
            compare(menu.implicitHeight, Math.max(listHeight, sidebarHeight));
            menu.searching = false;
            menu.showApps = 1;
            compare(menu.implicitHeight, Math.max(listHeight, sidebarHeight));
            menu.showApps = 0;
            backend.clear();
            config.numberRecentApps = 2;
            tryCompare(menu.favoritesGrid, "count", 0);
            tryCompare(menu.recentsGrid, "count", 2);
            tryCompare(menu, "implicitHeight", sidebarHeight);
            config.referenceSidebar = false;
            tryCompare(menu, "sidebarContentHeight", Kirigami.Units.smallSpacing * 2);
            tryCompare(menu, "implicitHeight", 44 * 3);
        }

        function test_recentAppsRemainEnabledAndLaunch() {
            const usage = createTemporaryObject(searchActivationModelComponent, harness);
            verify(usage);
            usage.setProperty(0, "url", "applications:test.desktop");
            usage.setProperty(0, "favoriteId", "test.desktop");
            const recents = createTemporaryObject(recentAppsViewComponent, harness, { usageModel: usage });
            verify(recents);
            tryCompare(recents, "count", 1);
            verify(!recents.dropEnabled);
            recents.currentIndex = 0;
            recents.forceLayout();
            tryVerify(() => recents.currentItem !== null);
            verify(recents.currentItem.enabled, "Rejecting drops must not disable recently-used apps");
            verify(findChild(recents.currentItem, "applicationIcon").enabled);
            const triggered = createTemporaryObject(spyComponent, harness, { target: usage, signalName: "resultTriggered" });
            verify(triggered.valid);
            mouseClick(recents, 20, recents.cellHeight / 2);
            compare(triggered.count, 1);
            compare(triggered.signalArguments[0][0], 0);
        }

        function test_pinnedAppsDisappearFromRecentlyUsed() {
            const backend = createTemporaryObject(persistentFavoritesComponent, harness);
            const usage = createTemporaryObject(searchModelComponent, harness);
            verify(backend);
            verify(usage);
            usage.append({ display: "Pinned app", decoration: "application-x-executable",
                           favoriteId: "pinned.desktop", url: "applications:pinned.desktop" });
            usage.append({ display: "Other app", decoration: "application-x-executable",
                           favoriteId: "other.desktop", url: "applications:other.desktop" });
            const recents = createTemporaryObject(recentAppsViewComponent, harness, { usageModel: usage, favoritesModel: backend });
            const favorites = createTemporaryObject(favoritesBackendViewComponent, harness, { externalFavoritesModel: backend });
            verify(recents);
            verify(favorites);
            tryCompare(recents, "count", 2);
            tryCompare(favorites, "count", 0);
            verify(favorites.addDroppedFavorite(recents.model.get(0), 0));
            tryCompare(favorites, "count", 1);
            tryCompare(recents, "count", 1);
            compare(recents.model.get(0).launcherUrl, "applications:other.desktop");
            const reopened = createTemporaryObject(favoritesBackendViewComponent, harness, { externalFavoritesModel: backend });
            verify(reopened);
            tryCompare(reopened, "count", 1);
            compare(reopened.model.get(0).launcherUrl, "applications:pinned.desktop");
            backend.remove(0);
            tryCompare(favorites, "count", 0);
            tryCompare(recents, "count", 2);
        }

        function test_applicationRecentsInlineLifecycle() {
            const pane = createTemporaryObject(applicationRecentsComponent, harness);
            verify(pane);
            verify(!pane.opened);
            let triggered = 0;
            verify(pane.openFor(anchor, [{ text: "Document", trigger: () => ++triggered }], "Recent", anchor, "Editor", "accessories-text-editor"));
            verify(pane.opened);
            compare(pane.Window.window, anchor.Window.window);
            compare(pane.applicationName, "Editor");
            pane.focusFirst();
            keyClick(Qt.Key_Return);
            compare(triggered, 1);
            const list = findChild(pane, "applicationRecentsList");
            verify(list);
            tryVerify(() => list.itemAtIndex(0) !== null);
            const row = list.itemAtIndex(0);
            verify(row.width > 0);
            verify(row.width <= pane.width);
            mouseClick(row, row.width / 2, row.height / 2);
            compare(triggered, 2);
            keyClick(Qt.Key_Left);
            verify(!pane.opened);
            tryCompare(anchor, "activeFocus", true);
            verify(pane.openFor(anchor, [{ text: "Another document" }], "Recent", anchor, "Editor", ""));
            const back = findChild(pane, "applicationRecentsBack");
            verify(back);
            mouseClick(back, back.width / 2, back.height / 2);
            verify(!pane.opened);
            verify(kicker.expanded);
            verify(pane.openFor(anchor, [{ text: "Another document" }], "Recent", anchor, "Editor", ""));
            kicker.expanded = false;
            verify(!pane.opened);
            compare(pane.owner, null);
            verify(!pane.openFor(anchor, [{ text: "Document" }], "Recent", anchor, "Editor", ""));
        }

        function test_applicationRecentsForwardsDesktopActions() {
            const pane = createTemporaryObject(applicationRecentsComponent, harness);
            verify(pane);
            let invoked = null;
            const source = {
                jumpIndex: 2,
                runAction: (row, action, argument) => invoked = [row, action, argument]
            };
            verify(pane.openFor(anchor, [{ text: "New window", actionId: "new-window", actionArgument: "test" }], "Tasks", source, "Browser", ""));
            pane.activateEntry(0);
            compare(invoked, [2, "new-window", "test"]);
            invoked = null;
            verify(pane.openFor(anchor, [{ text: "Unavailable", enabled: false, actionId: "disabled" }], "Tasks", source, "Browser", ""));
            pane.activateEntry(0);
            compare(invoked, null);
        }

        function test_applicationRecentsTracksSelectedOwner() {
            const pane = createTemporaryObject(applicationRecentsComponent, harness);
            const first = createTemporaryObject(favoritesComponent, harness, { recentFilesPane: pane });
            const second = createTemporaryObject(favoritesComponent, harness, { recentFilesPane: pane });
            verify(pane);
            verify(first);
            verify(second);
            verify(pane.openFor(anchor, [{ text: "Document" }], "Recent", first, "First app", ""));
            verify(first.jumpOpen);
            verify(!second.jumpOpen);
            verify(pane.openFor(anchor, [{ text: "Another document" }], "Recent", second, "Second app", ""));
            verify(!first.jumpOpen);
            verify(second.jumpOpen);
            pane.close();
            verify(!first.jumpOpen);
            verify(!second.jumpOpen);
        }

        function test_categoryExpansionDoesNotAddHeader() {
            const view = createTemporaryObject(applicationsViewComponent, harness);
            verify(view);
            tryCompare(view.activeView, "height", view.height);
            view.activeView.expandedLabel = "Graphics";
            verify(waitForRendering(view));
            tryCompare(view.activeView, "y", 0);
            compare(view.activeView.height, view.height);
            view.reset();
            compare(view.activeView.expandedLabel, "");
            compare(view.activeView.y, 0);
        }

        function test_sidebarFlyoutLimitsRecentEntries() {
            const history = createTemporaryObject(searchModelComponent, harness);
            verify(history);
            for (let entry = 0; entry < 100; ++entry) {
                history.append({ display: "Recent document " + entry, decoration: "document-open" });
            }
            const sidebar = createTemporaryObject(sidebarComponent, harness, { menuModel: history });
            verify(sidebar);
            sidebar.openFlyout();
            const menu = findChild(sidebar, "sidebarFlyout");
            verify(menu);
            tryCompare(menu, "opened", true);
            compare(menu.count, sidebarConfiguration.numberRecentFiles);
            tryVerify(() => menu.height <= menu.itemAt(0).height * menu.count + menu.topPadding + menu.bottomPadding + 1);
            const originalLimit = sidebarConfiguration.numberRecentFiles;
            try {
                sidebarConfiguration.numberRecentFiles = 3;
                tryCompare(menu, "count", 3);
                sidebarConfiguration.numberRecentFiles = 12;
                tryCompare(menu, "count", 12);
                compare(menu.itemAt(11).text, "Recent document 11");
            } finally {
                sidebarConfiguration.numberRecentFiles = originalLimit;
            }
        }

        function test_shutdownFrameAlignsWithSearchInput() {
            const search = createTemporaryObject(searchComponent, harness);
            const power = createTemporaryObject(powerComponent, harness);
            verify(search);
            verify(power);
            power.anchors.verticalCenter = search.verticalCenter;
            const input = findChild(search, "searchInput");
            const frame = findChild(power, "powerButtonFrame");
            verify(input);
            verify(frame);
            compare(frame.height, input.height);
            fuzzyCompare(frame.mapToItem(search, 0, 0).y, input.y, 0.01);
        }

        function test_shutdownLabelFitsFrame_data() {
            return [
                { tag: "default", text: "Shut down", pointSize: 10 },
                { tag: "large-text", text: "Shut down", pointSize: 16 },
                { tag: "long-label", text: "Shut down computer", pointSize: 10 }
            ];
        }

        function test_shutdownLabelFitsFrame(data) {
            const power = createTemporaryObject(powerComponent, harness);
            verify(power);
            const button = findChild(power, "shutdownButton");
            verify(button);
            button.text = data.text;
            button.contentItem.font.pointSize = data.pointSize;
            const padding = Kirigami.Units.smallSpacing * 2;
            tryVerify(() => button.contentItem.x >= padding);
            verify(button.width - button.contentItem.x - button.contentItem.implicitWidth >= padding - 0.5);
            verify(!button.contentItem.truncated);
            const frame = findChild(power, "powerButtonFrame");
            verify(frame);
            compare(frame.width, power.width);
            verify(button.width < frame.width);
        }

        function test_powerButtonsHighlightOnHover_data() {
            return [
                { tag: "shutdown", buttonName: "shutdownButton" },
                { tag: "options", buttonName: "powerOptionsButton" }
            ];
        }

        function test_powerButtonsHighlightOnHover(data) {
            const power = createTemporaryObject(powerComponent, harness);
            verify(power);
            const button = findChild(power, data.buttonName);
            verify(button);
            const actions = createTemporaryObject(spyComponent, harness, { target: power, signalName: "executeAction" });
            verify(actions.valid);
            verify(!button.background.visible);
            mouseMove(button, button.width / 2, button.height / 2);
            tryCompare(button, "hovered", true);
            verify(button.background.hovered);
            verify(button.background.visible);
            verify(!power.menuOpen);
            compare(button.background.width, button.width);
            compare(button.background.height, button.height);
            mousePress(button, button.width / 2, button.height / 2);
            verify(button.background.pressed);
            mouseMove(focusTarget, 10, 10);
            mouseRelease(focusTarget, 10, 10);
            tryCompare(button, "hovered", false);
            verify(!button.background.visible);
            compare(actions.count, 0);
        }

        function test_shutdownIconPrecedesLabel() {
            const power = createTemporaryObject(powerComponent, harness);
            verify(power);
            const button = findChild(power, "shutdownButton");
            verify(button);
            compare(button.icon.name, "system-shutdown");
            compare(button.contentItem.text, "Shut down");
            const icon = findChild(button, "shutdownIcon");
            verify(icon);
            compare(icon.iconName, "system-shutdown");
            verify(icon.visible);
            verify(icon.width > 0);
            verify(icon.x + icon.width < button.contentItem.leftPadding);
        }

        function test_allProgramsHoverActivatesOnce_data() {
            return [
                { tag: "all-programs", view: 0, searching: false, signal: "showAppsChangeRequested" },
                { tag: "back", view: 1, searching: false, signal: "showAppsChangeRequested" },
                { tag: "search-back", view: 0, searching: true, signal: "searchCancelled" }
            ];
        }

        function test_allProgramsHoverActivatesOnce(data) {
            const button = createTemporaryObject(allProgramsButtonComponent, harness, {
                currentShowApps: data.view, searching: data.searching
            });
            verify(button);
            const spy = createTemporaryObject(spyComponent, harness, { target: button, signalName: data.signal });
            verify(spy.valid);
            mouseMove(button, button.width / 2, button.height / 2);
            wait(650);
            compare(spy.count, 0);
            tryCompare(spy, "count", 1, 500);
            wait(800);
            compare(spy.count, 1);
        }

        function test_allProgramsHoverCancelsOnLeaveOrCollapse() {
            const button = createTemporaryObject(allProgramsButtonComponent, harness);
            verify(button);
            const spy = createTemporaryObject(spyComponent, harness, { target: button, signalName: "showAppsChangeRequested" });
            verify(spy.valid);
            mouseMove(button, button.width / 2, button.height / 2);
            wait(100);
            mouseMove(focusTarget, 10, 10);
            wait(800);
            compare(spy.count, 0);
            mouseMove(button, button.width / 2, button.height / 2);
            button.launcherExpanded = false;
            wait(800);
            compare(spy.count, 0);
        }

        function test_sidebarIconLeadingPadding_data() {
            return [
                { tag: "narrow", width: 180 },
                { tag: "default", width: 200 },
                { tag: "wide", width: 260 }
            ];
        }

        function test_sidebarIconLeadingPadding(data) {
            const sidebar = createTemporaryObject(sidebarComponent, harness, {
                width: data.width, itemIcon: "settings-configure", itemIconFallback: "configure"
            });
            verify(sidebar);
            const icon = findChild(sidebar, "sidePanelIcon");
            verify(icon);
            tryVerify(() => icon.width > 0);
            const position = icon.mapToItem(sidebar, 0, 0);
            compare(position.x, Kirigami.Units.smallSpacing * 4);
            verify(position.x + icon.width < sidebar.width);
            compare(sidebar.height, 44);
        }

        function test_allProgramsHoverMatchesSidebar_data() {
            return [
                { tag: "all-programs", view: 0, searching: false },
                { tag: "back", view: 1, searching: false },
                { tag: "search-back", view: 0, searching: true }
            ];
        }

        function test_allProgramsHoverMatchesSidebar(data) {
            const button = createTemporaryObject(allProgramsButtonComponent, harness, {
                currentShowApps: data.view, searching: data.searching
            });
            verify(button);
            const highlight = button.background;
            verify(!highlight.visible);
            mouseMove(button, button.width / 2, button.height / 2);
            tryCompare(button, "hovered", true);
            verify(!button.activeFocus);
            verify(highlight.hovered);
            verify(highlight.visible);
            compare(highlight.width, button.width);
            compare(highlight.height, button.height);
            mousePress(button, button.width / 2, button.height / 2);
            verify(highlight.pressed);
            mouseRelease(button, button.width / 2, button.height / 2);
            mouseMove(focusTarget, 10, 10);
            focusTarget.forceActiveFocus();
            tryCompare(button, "hovered", false);
            verify(!highlight.visible);
            button.forceActiveFocus();
            verify(highlight.visible);
            verify(highlight.hovered);
        }

        function test_searchBackReturnsToStartingView_data() {
            return [
                { tag: "main-menu-click", view: 0, keyboard: false },
                { tag: "programs-click", view: 1, keyboard: false },
                { tag: "main-menu-keyboard", view: 0, keyboard: true },
                { tag: "programs-keyboard", view: 1, keyboard: true }
            ];
        }

        function test_searchBackReturnsToStartingView(data) {
            const search = createTemporaryObject(searchComponent, harness, { y: 300 });
            verify(search);
            const button = createTemporaryObject(allProgramsButtonComponent, harness, {
                currentShowApps: data.view, searching: Qt.binding(() => search.text !== "")
            });
            verify(button);
            button.searchCancelled.connect(() => search.clear());
            button.showAppsChangeRequested.connect(value => button.currentShowApps = value);
            search.text = "word";
            compare(button.text, "Back");
            compare(button.icon.name, "go-previous");
            if (data.keyboard) {
                button.forceActiveFocus();
                keyClick(Qt.Key_Space);
            } else {
                mouseClick(button, button.width / 2, button.height / 2);
            }
            compare(search.text, "");
            compare(button.currentShowApps, data.view);
            compare(button.text, data.view === 0 ? "All Programs" : "Back");
            mouseClick(button, button.width / 2, button.height / 2);
            compare(button.currentShowApps, data.view === 0 ? 1 : 0);
        }

        function test_missingFileRunnerDoesNotSearchPrograms() {
            const files = createTemporaryObject(fileSearchComponent, harness);
            verify(files);
            files.query = "word";
            tryVerify(() => !files.querying);
            compare(files.count, 0);
            compare(files.modelForRow(0), null);
            verify(!files.resultsPresent);
        }

        function test_panelPopupIsFramelessAndAttached() {
            const popup = createTemporaryObject(panelPopupComponent, harness);
            verify(popup);
            const attachment = createTemporaryObject(popupAttachmentComponent, popup.mainItem);
            verify(attachment);
            compare(attachment.popupWindow, popup);
            tryCompare(popup, "margin", 0);
            verify(attachment.nativeBackground !== null);
            compare(attachment.nativeBackground.visible, false);
            compare(popup.borders, 0);
            tryVerify(() => attachment.width === popup.width && popup.width > 0);
            tryVerify(() => attachment.height === popup.height && popup.height > 0);
            const origin = attachment.mapToItem(popup.contentItem, 0, 0);
            compare(origin.x, 0);
            compare(origin.y, 0);
            const content = attachment.contentRect;
            const contentOrigin = popup.mainItem.mapToItem(popup.contentItem, content.x, content.y);
            compare(contentOrigin.x, Kirigami.Units.smallSpacing);
            compare(contentOrigin.y, Kirigami.Units.smallSpacing);
            compare(popup.width - contentOrigin.x - content.width, Kirigami.Units.smallSpacing);
            compare(popup.height - contentOrigin.y - content.height, Kirigami.Units.smallSpacing);
            popup.borders = Qt.TopEdge | Qt.LeftEdge;
            compare(popup.borders, 0);
            compare(attachment.mapToItem(popup.contentItem, 0, 0).x, 0);
        }

        function test_searchBarHasCompactVerticalPadding() {
            const search = createTemporaryObject(searchComponent, harness);
            verify(search);
            search.height = search.implicitHeight;
            const input = findChild(search, "searchInput");
            verify(input);
            compare(input.y, Kirigami.Units.smallSpacing);
            compare(search.height - input.y - input.height, Kirigami.Units.smallSpacing);
        }

        function test_menuBackgroundTransparency_data() {
            return [
                { tag: "transparent", opacity: 0 },
                { tag: "half", opacity: 50 },
                { tag: "slightly-translucent", opacity: 85 },
                { tag: "opaque", opacity: 100 },
                { tag: "translucent-with-solid-tint", opacity: 85, tint: true }
            ];
        }

        function test_menuBackgroundTransparency(data) {
            const popup = createTemporaryObject(panelPopupComponent, harness);
            verify(popup);
            const background = createTemporaryObject(popupAttachmentComponent, popup.mainItem, {
                color: "#303136", backgroundOpacity: data.opacity, z: -3
            });
            verify(background);
            if (data.tint) {
                const tint = createTemporaryObject(foregroundComponent, background, {
                    x: 0, y: 0, width: background.width, height: background.height, color: "#abcdef", z: 0
                });
                verify(tint);
            }
            const foreground = createTemporaryObject(foregroundComponent, popup.mainItem);
            verify(foreground);
            popup.visible = true;
            verify(waitForRendering(popup.contentItem));
            const image = grabImage(popup.contentItem);
            const backgroundPixel = image.pixel(5, 5);
            verify(Math.abs(backgroundPixel.a - data.opacity / 100) < 0.02,
                   "Native popup must preserve the configured background alpha: " + backgroundPixel.a);
            const point = foreground.mapToItem(popup.contentItem, 6, 6);
                 const pixelScale = image.width / popup.contentItem.width;
                 compare(image.pixel(Math.round(point.x * pixelScale), Math.round(point.y * pixelScale)).a, 1);
            popup.visible = false;
        }

        function test_backgroundFollowsPopupReparenting() {
            const background = createTemporaryObject(popupAttachmentComponent, harness, {
                color: "#303136", backgroundOpacity: 50, z: -3
            });
            verify(background);
            compare(background.nativeBackground, null);
            const popup = createTemporaryObject(panelPopupComponent, harness);
            verify(popup);
            popup.visible = true;
            background.parent = popup.mainItem;
            tryCompare(background, "popupWindow", popup);
            tryVerify(() => background.nativeBackground !== null);
            compare(background.nativeBackground.visible, false);
            verify(waitForRendering(popup.contentItem));
            const image = grabImage(popup.contentItem);
            verify(Math.abs(image.pixel(5, 5).a - 0.5) < 0.02);
            popup.visible = false;
            background.parent = harness;
            tryCompare(background, "nativeBackground", null);
        }

        function test_backgroundOpacitySetting() {
            const appearance = createTemporaryObject(appearanceComponent, harness);
            verify(appearance);
            compare(appearance.cfg_menuBackgroundOpacity, 85);
            const slider = findChild(appearance, "menuBackgroundOpacity");
            verify(slider);
            compare(slider.from, 0);
            compare(slider.to, 100);
            appearance.cfg_menuBackgroundOpacity = 40;
            compare(slider.value, 40);
            slider.value = 100;
            compare(appearance.cfg_menuBackgroundOpacity, 100);
        }

        function test_popupAttachmentIgnoresOrdinaryWindow() {
            const attachment = createTemporaryObject(popupAttachmentComponent, harness, { popupWindow: harness.Window.window });
            verify(attachment);
            verify(attachment.popupWindow !== null);
        }

        function test_searchResultsFitActualColumns() {
            const results = createTemporaryObject(searchResultsComponent, harness);
            verify(results);
            tryCompare(results, "count", 2);
            const grid = results.subGridAt(0);
            tryCompare(grid, "count", 1);
            compare(grid.cellWidth, grid.width);
            compare(grid.height, 44);
            compare(grid.iconSize, 36);
            compare(grid.lastRow(), 0);
            grid.tryActivate(0, 0);
            compare(grid.currentIndex, 0);
            tryVerify(() => grid.currentItem !== null);
            compare(findChild(grid.currentItem, "searchResultIcon").width, 36);
            const label = findChild(grid.currentItem, "searchResultLabel");
            verify(label.x + label.width <= grid.width);
        }

        function test_searchEnterOpensFirstResult_data() {
            return [
                { tag: "return", key: Qt.Key_Return },
                { tag: "keypad-enter", key: Qt.Key_Enter }
            ];
        }

        function test_searchEnterOpensFirstResult(data) {
            const model = createTemporaryObject(searchActivationModelComponent, harness);
            verify(model);
            const search = createTemporaryObject(searchComponent, harness, { y: 300 });
            const results = createTemporaryObject(searchResultsComponent, harness, {
                sections: [{ title: "Programs", model: model }]
            });
            verify(search);
            verify(results);
            const triggered = createTemporaryObject(spyComponent, harness, {
                target: model, signalName: "resultTriggered"
            });
            verify(triggered.valid);
            search.activateResult.connect(() => results.activateCurrentResult());
            search.text = "first";
            search.focusSearchField();
            tryCompare(results.subGridAt(0), "currentIndex", 0);
            tryVerify(() => results.subGridAt(0).currentItem !== null);
            verify(findChild(search, "searchInput").activeFocus);
            keyClick(data.key);
            compare(triggered.count, 1);
            compare(triggered.signalArguments[0][0], 0);
            results.sections = [];
            tryCompare(results, "count", 0);
            keyClick(data.key);
            compare(triggered.count, 1);
        }

        function test_searchArrowsMoveThroughResults() {
            const model = createTemporaryObject(searchActivationModelComponent, harness);
            const empty = createTemporaryObject(searchModelComponent, harness);
            verify(model);
            verify(empty);
            model.append({ display: "Second application", decoration: "application-x-executable", disabled: false });
            model.append({ display: "Third application", decoration: "application-x-executable", disabled: false });
            const search = createTemporaryObject(searchComponent, harness, { y: 300 });
            const results = createTemporaryObject(searchResultsComponent, harness, {
                height: 100,
                sections: [{ title: "Empty", model: empty }, { title: "Programs", model: model },
                           { title: "Empty", model: empty }, { title: "Recent", model: documents }]
            });
            verify(search);
            verify(results);
            search.keyNavUp.connect(() => results.moveSelection(-1));
            search.keyNavDown.connect(() => results.moveSelection(1));
            search.activateResult.connect(() => results.activateCurrentResult());
            const triggered = createTemporaryObject(spyComponent, harness, { target: model, signalName: "resultTriggered" });
            verify(triggered.valid);
            search.text = "application";
            search.focusSearchField();
            const input = findChild(search, "searchInput");
            const apps = results.subGridAt(1);
            const recent = results.subGridAt(3);
            tryCompare(apps, "currentIndex", 0);
            keyClick(Qt.Key_Up);
            compare(apps.currentIndex, 0);
            keyClick(Qt.Key_Down);
            compare(apps.currentIndex, 1);
            keyClick(Qt.Key_Down);
            compare(apps.currentIndex, 2);
            keyClick(Qt.Key_Down);
            compare(apps.currentIndex, -1);
            compare(recent.currentIndex, 0);
            keyClick(Qt.Key_Down);
            compare(recent.currentIndex, 0);
            verify(results.flickableItem.contentY > 0);
            keyClick(Qt.Key_Up);
            compare(recent.currentIndex, -1);
            compare(apps.currentIndex, 2);
            verify(input.activeFocus);
            keyClick(Qt.Key_Return);
            compare(triggered.count, 1);
            compare(triggered.signalArguments[0][0], 2);
            keyClick(Qt.Key_X);
            compare(search.text, "applicationx");
            verify(input.activeFocus);
            results.sections = [];
            tryCompare(results, "count", 0);
            keyClick(Qt.Key_Up);
            keyClick(Qt.Key_Down);
            verify(input.activeFocus);
        }

        function test_searchSelectsFirstNonEmptyResult() {
            const pending = createTemporaryObject(searchModelComponent, harness);
            verify(pending);
            const results = createTemporaryObject(searchResultsComponent, harness, {
                sections: [{ title: "Programs", model: pending }, { title: "Recent", model: documents }]
            });
            verify(results);
            tryCompare(results.subGridAt(1), "currentIndex", 0);
            compare(results.subGridAt(0).currentIndex, -1);
            pending.append({ display: "First application", decoration: "application-x-executable", disabled: false });
            tryCompare(results.subGridAt(0), "currentIndex", 0);
            compare(results.subGridAt(1).currentIndex, -1);
            pending.clear();
            tryCompare(results.subGridAt(1), "currentIndex", 0);
            compare(results.subGridAt(0).currentIndex, -1);
        }

        function test_searchTypingKeepsFocusDuringResultsRefresh() {
            const search = createTemporaryObject(searchComponent, harness, { y: 300 });
            const results = createTemporaryObject(searchResultsComponent, harness, { sections: [] });
            verify(search);
            verify(results);
            search.searchTextChanged.connect(() => {
                results.sections = [{ title: "Programs", model: applications }];
            });
            const input = findChild(search, "searchInput");
            verify(input);
            search.focusSearchField();
            const keys = [Qt.Key_F, Qt.Key_I, Qt.Key_R, Qt.Key_E, Qt.Key_F, Qt.Key_O, Qt.Key_X];
            for (let index = 0; index < keys.length; index++) {
                keyClick(keys[index]);
                wait(1);
                compare(search.text, "firefox".slice(0, index + 1));
                verify(input.activeFocus, "Results refresh must not take focus from the search input");
                tryCompare(results.subGridAt(0), "currentIndex", 0);
            }
            results.tryActivate(0, 0);
            tryVerify(() => results.subGridAt(0).activeFocus);
            verify(!input.activeFocus);
        }

        function test_searchResultsScrollAcrossSections() {
            const results = createTemporaryObject(searchResultsComponent, harness, { height: 60 });
            verify(results);
            tryCompare(results, "count", 2);
            const flickable = results.flickableItem;
            tryVerify(() => flickable.contentHeight > flickable.height);
            results.subGridAt(1).tryActivate(0, 0);
            tryVerify(() => flickable.contentY > 0);
            verify(flickable.contentY <= flickable.contentHeight - flickable.height);
            results.subGridAt(0).tryActivate(0, 0);
            tryCompare(flickable, "contentY", 0);
        }

        function test_searchResultsWheelScrollsRows() {
            const model = createTemporaryObject(searchModelComponent, harness);
            verify(model);
            for (let index = 0; index < 20; index++) {
                model.append({ display: "Search result " + index, decoration: "application-x-executable", disabled: false });
            }
            const results = createTemporaryObject(searchResultsComponent, harness, {
                sections: [{ title: "Programs", model: model }]
            });
            verify(results);
            tryCompare(results, "count", 1);
            const grid = results.subGridAt(0);
            tryCompare(grid, "count", 20);
            compare(grid.height, 20 * 44);
            compare(grid.lastRow(), 19);
            const flickable = results.flickableItem;
            tryVerify(() => flickable.contentHeight > flickable.height);
            mouseMove(results, results.width / 2, 100);
            mouseWheel(results, results.width / 2, 100, 0, -120);
            tryVerify(() => flickable.contentY > 0);
            verify(flickable.contentY <= flickable.contentHeight - flickable.height);
            results.sections = [{ title: "New search", model: model }];
            tryCompare(flickable, "contentY", 0);
        }

        function hoverTimer(item) {
            for (let index = 0; index < item.resources.length; index++) {
                const resource = item.resources[index];
                if (typeof resource.restart === "function" && resource.interval !== undefined) return resource;
            }
            fail("Sidebar hover timer not found");
        }

        function init() {
            mouseMove(focusTarget, 10, 10);
            kicker.expanded = true;
            anchor.visible = true;
            flyout.close();
            tryCompare(flyout, "visible", false);
            focusTarget.forceActiveFocus();
        }

        function cleanup() {
            kicker.expanded = false;
            flyout.close();
            tryCompare(flyout, "visible", false);
        }

        function openFlyout() {
            verify(flyout.openFor(anchor, [{ text: "Recent document" }], "Recent"));
            tryCompare(flyout, "opened", true);
        }

        function test_flyoutsOpenOutsideLauncher_data() {
            return [
                { tag: "application-recents", sidebar: false },
                { tag: "sidebar-recents", sidebar: true }
            ];
        }

        function test_flyoutsOpenOutsideLauncher(data) {
            const row = data.sidebar ? createTemporaryObject(sidebarComponent, harness) : anchor;
            verify(row);
            const originalX = row.x;
            const launcherWindow = harness.Window.window;
            const originalWindowWidth = launcherWindow.width;
            const originalHarnessWidth = harness.width;
            try {
                launcherWindow.width = 400;
                harness.width = 400;
                row.x = harness.width - row.width - 10;
                let menu = flyout;
                if (data.sidebar) {
                    row.openFlyout();
                    menu = findChild(row, "sidebarFlyout");
                } else {
                    openFlyout();
                }
                verify(menu);
                tryCompare(menu, "opened", true);
                if (data.sidebar) {
                    verify(menu.parent.width > 0, "Wayland requires a valid anchor rectangle");
                    verify(menu.parent.height > 0, "Wayland requires a valid anchor rectangle");
                    compare(menu.parent.mapToGlobal(0, menu.parent.height), row.mapToGlobal(row.width, 0));
                }
                const popupWindow = menu.contentItem.Window.window;
                verify(popupWindow !== row.Window.window, "Flyout must have its own popup window");
                verify(waitForPolish(menu.contentItem));
                const rowRight = row.mapToGlobal(row.width, 0).x;
                const popupLeft = menu.contentItem.mapToGlobal(0, 0).x;
                verify(popupLeft >= rowRight, "Flyout must open to the right of its row: " + popupLeft + " < " + rowRight);
                if (data.sidebar) {
                    const rowTop = row.mapToGlobal(0, 0).y;
                    const popupTop = menu.contentItem.mapToGlobal(0, 0).y - menu.topPadding;
                    fuzzyCompare(popupTop, rowTop, 1);
                }
                const launcherRight = harness.mapToGlobal(harness.width, 0).x;
                verify(popupLeft + menu.contentItem.width > launcherRight,
                       "Flyout must be able to extend beyond the launcher");
            } finally {
                row.x = originalX;
                launcherWindow.width = originalWindowWidth;
                harness.width = originalHarnessWidth;
            }
        }

        function test_flyoutRowsHighlightOnHover_data() {
            return [
                { tag: "application-recents", sidebar: false },
                { tag: "sidebar-recents", sidebar: true }
            ];
        }

        function test_flyoutRowsHighlightOnHover(data) {
            let menu = flyout;
            if (data.sidebar) {
                const sidebar = createTemporaryObject(sidebarComponent, harness);
                verify(sidebar);
                sidebar.openFlyout();
                menu = findChild(sidebar, "sidebarFlyout");
            } else {
                openFlyout();
            }
            verify(menu);
            tryCompare(menu, "opened", true);
            const row = menu.itemAt(data.sidebar ? 0 : 1);
            verify(row);
            mouseMove(row, row.width / 2, row.height / 2);
            tryCompare(row, "hovered", true);
            tryCompare(row.background.children[0], "opacity", 1);
            compare(menu.pointerVisited, true);
        }

        function test_flyoutClosesAfterPointerLeaves() {
            openFlyout();
            mouseMove(flyout.contentItem, 10, 10);
            tryCompare(flyout, "pointerVisited", true);
            mouseMove(flyout.contentItem, -40, -40);
            wait(100);
            verify(flyout.opened);
            tryCompare(flyout, "visible", false, 700);
            verify(kicker.expanded);
        }

        function test_flyoutReentryCancelsDismissal() {
            openFlyout();
            mouseMove(flyout.contentItem, 10, 10);
            tryCompare(flyout, "pointerVisited", true);
            mouseMove(flyout.contentItem, -40, -40);
            wait(100);
            mouseMove(flyout.contentItem, 10, 10);
            wait(350);
            verify(flyout.opened);
        }

        function test_keyboardFlyoutDoesNotAutoDismiss() {
            openFlyout();
            wait(350);
            verify(flyout.opened);
        }

        function test_sidebarFlyoutClosesAfterPointerLeaves() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            sidebar.openFlyout();
            tryCompare(sidebar, "flyoutOpen", true);
            const menu = findChild(sidebar, "sidebarFlyout");
            verify(menu);
            mouseMove(menu.contentItem, 10, 10);
            tryCompare(menu, "pointerVisited", true);
            mouseMove(menu.contentItem, -40, -40);
            tryCompare(sidebar, "flyoutOpen", false, 700);
            verify(kicker.expanded);
        }

        function test_collapseAndReopen() {
            openFlyout();
            kicker.expanded = false;
            tryCompare(flyout, "visible", false);
            verify(!anchor.activeFocus);
            kicker.expanded = true;
            verify(!flyout.visible);
        }

        function test_hiddenAnchorClosesFlyout() {
            openFlyout();
            anchor.visible = false;
            tryCompare(flyout, "visible", false);
            verify(!anchor.activeFocus);
        }

        function test_cannotOpenWhileCollapsed() {
            kicker.expanded = false;
            verify(!flyout.openFor(anchor, [{ text: "Recent document" }], "Recent"));
            verify(!flyout.visible);
        }

        function test_cannotOpenForHiddenAnchor() {
            anchor.visible = false;
            verify(!flyout.openFor(anchor, [{ text: "Recent document" }], "Recent"));
            verify(!flyout.visible);
        }

        function test_emptyMenuDoesNotOpen() {
            verify(!flyout.openFor(anchor, [], "Recent"));
            verify(!flyout.visible);
        }

        function test_leftReturnsFocus() {
            openFlyout();
            keyClick(Qt.Key_Left);
            tryCompare(flyout, "visible", false);
            tryCompare(anchor, "activeFocus", true);
            verify(kicker.expanded);
        }

        function test_escapeDismissesOnlyFlyout() {
            openFlyout();
            keyClick(Qt.Key_Escape);
            tryCompare(flyout, "visible", false);
            tryCompare(anchor, "activeFocus", true);
            verify(kicker.expanded);
        }

        function test_sidebarCollapseAndReopen() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            sidebar.openFlyout();
            tryCompare(sidebar, "flyoutOpen", true);
            kicker.expanded = false;
            tryCompare(sidebar, "flyoutOpen", false);
            kicker.expanded = true;
            verify(!sidebar.flyoutOpen);
        }

        function test_sidebarCollapseCancelsPendingHover() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            const timer = hoverTimer(sidebar);
            timer.interval = 80;
            timer.start();
            verify(timer.running);
            kicker.expanded = false;
            compare(timer.running, false);
            kicker.expanded = true;
            wait(120);
            verify(!sidebar.flyoutOpen);
        }

        function test_sidebarHiddenCancelsPendingHover() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            const timer = hoverTimer(sidebar);
            timer.interval = 80;
            timer.start();
            sidebar.visible = false;
            compare(timer.running, false);
            wait(120);
            verify(!sidebar.flyoutOpen);
        }

        function test_sidebarCannotOpenWhileCollapsed() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            kicker.expanded = false;
            sidebar.openFlyout();
            verify(!sidebar.flyoutOpen);
        }

        function test_sidebarHoverOpensAfterDelay() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            mouseMove(sidebar, 20, 20);
            verify(hoverTimer(sidebar).running);
            verify(!sidebar.flyoutOpen);
            tryCompare(sidebar, "flyoutOpen", true);
        }

        function test_sidebarHighlightClearsOnPointerExit_data() {
            return [
                { tag: "action", hasFlyout: false },
                { tag: "recent-files", hasFlyout: true }
            ];
        }

        function test_sidebarHighlightClearsOnPointerExit(data) {
            const sidebar = createTemporaryObject(sidebarComponent, harness, {
                menuModel: data.hasFlyout ? documents : null
            });
            verify(sidebar);
            let highlight = null;
            for (const child of sidebar.children) {
                if ("hovered" in child && "pressed" in child) highlight = child;
            }
            verify(highlight);
            mouseMove(sidebar, 20, 20);
            verify(highlight.visible);
            mouseMove(focusTarget, 10, 10);
            tryCompare(highlight, "visible", false);
            verify(!sidebar.activeFocus);
            sidebar.forceActiveFocus();
            verify(highlight.visible);
        }

        function test_sidebarLeavingCancelsHover() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            mouseMove(sidebar, 20, 20);
            verify(hoverTimer(sidebar).running);
            mouseMove(focusTarget, 10, 10);
            compare(hoverTimer(sidebar).running, false);
            wait(120);
            verify(!sidebar.flyoutOpen);
        }

        function test_sidebarRightThenLeft() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            sidebar.forceActiveFocus();
            keyClick(Qt.Key_Right);
            tryCompare(sidebar, "flyoutOpen", true);
            keyClick(Qt.Key_Left);
            tryCompare(sidebar, "flyoutOpen", false);
            tryCompare(sidebar, "activeFocus", true);
            verify(kicker.expanded);
        }

        function test_sidebarEscapeDismissesOnlyFlyout() {
            const sidebar = createTemporaryObject(sidebarComponent, harness);
            verify(sidebar);
            sidebar.openFlyout();
            tryCompare(sidebar, "flyoutOpen", true);
            keyClick(Qt.Key_Escape);
            tryCompare(sidebar, "flyoutOpen", false);
            tryCompare(sidebar, "activeFocus", true);
            verify(kicker.expanded);
        }

        function test_applicationIconFitsRow() {
            const favorites = createTemporaryObject(favoritesComponent, harness);
            verify(favorites);
            tryCompare(favorites, "count", 1);
            favorites.currentIndex = 0;
            tryVerify(() => favorites.currentItem !== null);
            const icon = findChild(favorites.currentItem, "applicationIcon");
            verify(icon);
            compare(icon.width, 36);
            compare(icon.height, 36);
            verify(icon.y >= 0);
            verify(icon.y + icon.height <= favorites.currentItem.height);
        }

        function test_outlineIconUsesFileUrl() {
            const icon = createTemporaryObject(outlineIconComponent, harness);
            verify(icon);
            if (!icon.outlineSource) skip("Breeze Dark outline assets are not installed");
            verify(icon.source.toString().startsWith("file:"));
            verify(icon.source.toString().endsWith("/actions/22/configure.svg"));
            const artwork = findChild(icon, "outlineArtwork");
            verify(artwork);
            tryCompare(artwork, "status", Image.Ready);
            tryCompare(icon, "valid", true);
            const image = grabImage(icon);
            compare(image.width, 22);
            compare(image.height, 22);
            verify(image.pixel(3, 16).r > 0.5);
        }

        function test_searchFitsColumn_data() {
            return [{ tag: "narrow", width: 260 }, { tag: "default", width: 320 }, { tag: "wide", width: 400 }];
        }

        function test_windowsGlyphFont_data() {
            return [
                { tag: "personal", name: "user-identity", code: 0xec25 },
                { tag: "documents", name: "document-new", code: 0xe8a5 },
                { tag: "pictures", name: "viewimage", code: 0xe91b },
                { tag: "music", name: "audio-x-generic", code: 0xec4f },
                { tag: "downloads", name: "download", code: 0xe896 },
                { tag: "recents", name: "document-open-recent", code: 0xe81c },
                { tag: "computer", name: "computer", code: 0xec4e },
                { tag: "control-panel", name: "configure", code: 0xe912 },
                { tag: "settings", name: "settings-configure", code: 0xe713 },
                { tag: "terminal", name: "utilities-terminal", code: 0xe756 },
                { tag: "run", name: "system-run", code: 0xe8da },
                { tag: "search", name: "edit-find", code: 0xe721 },
                { tag: "power", name: "system-shutdown", code: 0xe7e8 },
                { tag: "next", name: "go-next", code: 0xe76c },
                { tag: "previous", name: "go-previous", code: 0xe76b }
            ];
        }

        function test_windowsGlyphFont(data) {
            const fontPath = StandardPaths.locate(StandardPaths.GenericDataLocation, "Windows7StartMenu4KDE/fonts/SegoeIcons.ttf");
            if (!fontPath) skip("A local SegoeIcons.ttf has not been installed");
            const icon = createTemporaryObject(outlineIconComponent, harness, {
                iconName: data.name, windowsIconFont: fontPath, useWindowsIconFont: true, color: "white"
            });
            verify(icon);
            const loader = findChild(icon, "windowsIconFontLoader");
            tryCompare(loader, "status", FontLoader.Ready);
            tryCompare(icon, "usingWindowsGlyph", true);
            compare(icon.windowsGlyph.charCodeAt(0), data.code);
            verify(!findChild(icon, "outlineArtwork").visible);
            const image = grabImage(icon);
            let litPixels = 0;
            for (let row = 0; row < image.height; row++) {
                for (let column = 0; column < image.width; column++) {
                    const pixel = image.pixel(column, row);
                    if (pixel.a > 0.1 && pixel.r > 0.5) litPixels++;
                }
            }
            verify(litPixels > 5, "Windows glyph must render visible strokes");
        }

        function test_unmappedIconUsesFallback() {
            const icon = createTemporaryObject(outlineIconComponent, harness, { iconName: "video-display", useWindowsIconFont: true });
            verify(icon);
            compare(icon.windowsGlyph, "");
            verify(!icon.usingWindowsGlyph);
            tryCompare(icon, "valid", true);
        }

        function test_sidebarGlyphPreservesSettingsIdentity() {
            const sidebar = createTemporaryObject(sidebarComponent, harness, {
                itemIcon: "settings-configure", itemIconFallback: "configure"
            });
            verify(sidebar);
            const icon = findChild(sidebar, "sidePanelIcon");
            verify(icon);
            compare(icon.iconName, "configure");
            compare(icon.glyphName, "settings-configure");
            compare(icon.windowsGlyph.charCodeAt(0), 0xe713);
            if (icon.resolvedWindowsIconFont.toString()) {
                icon.useWindowsIconFont = true;
                tryCompare(icon, "usingWindowsGlyph", true);
            }
        }

        function test_nonIconFontUsesFallback() {
            const regularFont = StandardPaths.locate(StandardPaths.GenericDataLocation, "fonts/TTF/DejaVuSans.ttf");
            if (!regularFont) skip("DejaVu Sans is not installed");
            const icon = createTemporaryObject(outlineIconComponent, harness, { windowsIconFont: regularFont, useWindowsIconFont: true });
            verify(icon);
            tryCompare(findChild(icon, "windowsIconFontLoader"), "status", FontLoader.Ready);
            verify(!icon.usingWindowsGlyph);
            tryCompare(findChild(icon, "outlineArtwork"), "status", Image.Ready);
        }

        function test_missingIconFontUsesFallback() {
            const icon = createTemporaryObject(outlineIconComponent, harness, {
                windowsIconFont: "/nonexistent/Windows7StartMenu4KDE-font-test.ttf", useWindowsIconFont: true
            });
            verify(icon);
            tryCompare(findChild(icon, "windowsIconFontLoader"), "status", FontLoader.Error);
            verify(!icon.usingWindowsGlyph);
            tryCompare(findChild(icon, "outlineArtwork"), "status", Image.Ready);
            verify(icon.valid);
        }

        function test_fontToggleRestoresFallback() {
            const fontPath = StandardPaths.locate(StandardPaths.GenericDataLocation, "Windows7StartMenu4KDE/fonts/SegoeIcons.ttf");
            if (!fontPath) skip("A local SegoeIcons.ttf has not been installed");
            const icon = createTemporaryObject(outlineIconComponent, harness, { windowsIconFont: fontPath, useWindowsIconFont: true });
            verify(icon);
            tryCompare(icon, "usingWindowsGlyph", true);
            icon.useWindowsIconFont = false;
            verify(!icon.usingWindowsGlyph);
            tryCompare(findChild(icon, "outlineArtwork"), "visible", true);
        }

        function test_searchFitsColumn(data) {
            const search = createTemporaryObject(searchComponent, harness, { width: data.width });
            verify(search);
            const input = findChild(search, "searchInput");
            verify(input);
            verify(input.x >= 0);
            verify(input.x + input.width <= search.width);
            verify(input.leftPadding + input.rightPadding < input.width);
            compare(input.placeholderText, "Search programs and files");
            search.text = "A very long search query that must scroll inside the field";
            compare(input.text, search.text);
            verify(search.isSearching);
            search.clear();
            compare(search.text, "");
        }

        function test_searchFooterNavigation() {
            const search = createTemporaryObject(searchComponent, harness);
            verify(search);
            const up = createTemporaryObject(spyComponent, harness, { target: search, signalName: "keyNavUp" });
            const down = createTemporaryObject(spyComponent, harness, { target: search, signalName: "keyNavDown" });
            search.focusSearchField();
            keyClick(Qt.Key_Up);
            compare(up.count, 1);
            keyClick(Qt.Key_Tab);
            compare(down.count, 1);
        }

        function test_flyoutMouseDismissalClearsButtonHighlights_data() {
            return [
                { tag: "power-leave", sidebar: false, outsideClick: false },
                { tag: "power-click", sidebar: false, outsideClick: true },
                { tag: "sidebar-leave", sidebar: true, outsideClick: false },
                { tag: "sidebar-click", sidebar: true, outsideClick: true }
            ];
        }

        function test_flyoutMouseDismissalClearsButtonHighlights(data) {
            const control = createTemporaryObject(data.sidebar ? sidebarComponent : powerComponent, harness);
            verify(control);
            const highlights = [];
            if (data.sidebar) {
                for (const child of control.children) {
                    if ("hovered" in child && "pressed" in child) highlights.push(child);
                }
            } else {
                highlights.push(findChild(control, "shutdownButton").background);
                highlights.push(findChild(control, "powerOptionsButton").background);
            }
            verify(highlights.length > 0);
            mouseClick(control, control.width - 5, control.height / 2);
            const menu = findChild(control, data.sidebar ? "sidebarFlyout" : "powerOptionsMenu");
            verify(menu);
            tryCompare(menu, "opened", true);
            mouseMove(menu.contentItem, 10, 10);
            tryCompare(menu, "menuPointerVisited", true);
            if (data.outsideClick) {
                mouseClick(menu.contentItem, -40, -40);
            } else {
                mouseMove(menu.contentItem, -40, -40);
            }
            tryCompare(menu, "visible", false, 1000);
            verify(!control.activeFocus);
            for (const highlight of highlights) tryCompare(highlight, "visible", false);
            mouseMove(control, control.width - 5, control.height / 2);
            tryCompare(highlights[highlights.length - 1], "visible", true);
            mouseMove(focusTarget, 5, 5);
            for (const highlight of highlights) tryCompare(highlight, "visible", false);
        }

        function test_powerFlyoutClosesAfterPointerLeaves_data() {
            return [
                { tag: "leave", reenter: false },
                { tag: "reenter", reenter: true }
            ];
        }

        function test_powerFlyoutClosesAfterPointerLeaves(data) {
            const power = createTemporaryObject(powerComponent, harness);
            verify(power);
            const actions = createTemporaryObject(spyComponent, harness, { target: power, signalName: "executeAction" });
            power.openMenu();
            const menu = findChild(power, "powerOptionsMenu");
            verify(menu);
            tryCompare(menu, "opened", true);
            menu.anchorHovered = true;
            mouseMove(menu.contentItem, menu.contentItem.width / 2, 10);
            tryCompare(menu, "pointerVisited", true);
            mouseMove(menu.contentItem, -40, -40);
            wait(100);
            verify(menu.opened);
            if (data.reenter) {
                mouseMove(menu.contentItem, menu.contentItem.width / 2, 10);
                wait(350);
                verify(menu.opened);
                mouseMove(menu.contentItem, -40, -40);
            }
            tryCompare(menu, "visible", false, 700);
            verify(!power.menuOpen);
            verify(kicker.expanded);
            compare(actions.count, 0);
        }

        function test_keyboardPowerFlyoutDoesNotAutoDismiss() {
            const power = createTemporaryObject(powerComponent, harness);
            verify(power);
            mouseMove(focusTarget, 5, 5);
            power.openMenu();
            const menu = findChild(power, "powerOptionsMenu");
            verify(menu);
            tryCompare(menu, "opened", true);
            wait(350);
            verify(menu.opened);
            power.closeMenu();
            tryCompare(menu, "visible", false);
        }

        function test_powerFlyoutOpensBesideArrow_data() {
            return [
                { tag: "middle", y: 250 },
                { tag: "footer", y: harness.height - 40 }
            ];
        }

        function test_powerFlyoutOpensBesideArrow(data) {
            const power = createTemporaryObject(powerComponent, harness, { y: data.y });
            verify(power);
            const arrow = findChild(power, "powerOptionsButton");
            verify(arrow);
            mouseClick(arrow, arrow.width / 2, arrow.height / 2);
            const menu = findChild(power, "powerOptionsMenu");
            verify(menu);
            tryCompare(menu, "opened", true);
            verify(menu.parent.width > 0);
            verify(menu.parent.height > 0);
            compare(menu.parent.mapToGlobal(0, menu.parent.height), arrow.mapToGlobal(arrow.width, arrow.height - menu.implicitHeight));
            verify(menu.contentItem.Window.window !== power.Window.window);
            verify(waitForPolish(menu.contentItem));
            const popupOrigin = menu.contentItem.mapToGlobal(0, 0);
            const arrowRight = arrow.mapToGlobal(arrow.width, 0);
            verify(popupOrigin.x >= arrowRight.x, "Power flyout must open to the right of the arrow");
            const popupBottom = popupOrigin.y + menu.contentItem.height + menu.bottomPadding;
            const arrowBottom = arrow.mapToGlobal(arrow.width, arrow.height).y;
            fuzzyCompare(popupBottom, arrowBottom, 1);
            power.closeMenu();
            tryCompare(menu, "visible", false);
        }

        function test_powerOptionsUseOpaquePopup() {
            const power = createTemporaryObject(powerComponent, harness);
            verify(power);
            power.openMenu();
            const menu = findChild(power, "powerOptionsMenu");
            verify(menu);
            tryCompare(menu, "opened", true);
            compare(menu.count, power.actions.length);
            verify(menu.contentItem.Window.window !== power.Window.window);
            const image = grabImage(menu.background);
            compare(image.pixel(Math.floor(image.width / 2), Math.floor(image.height / 2)).a, 1);
            power.closeMenu();
            verify(!power.menuOpen);
        }

        function test_powerOptionsDoNotShutdown() {
            const power = createTemporaryObject(powerComponent, harness);
            verify(power);
            verify(power.width > 0);
            const actions = createTemporaryObject(spyComponent, harness, { target: power, signalName: "executeAction" });
            mouseClick(power, power.width - 5, power.height / 2);
            verify(power.menuOpen);
            const menu = findChild(power, "powerOptionsMenu");
            verify(menu);
            tryCompare(menu, "opened", true);
            compare(actions.count, 0);
            keyClick(Qt.Key_Escape);
            tryCompare(power, "menuOpen", false);
            tryCompare(menu, "visible", false);
            mouseClick(power, 20, power.height / 2);
            compare(actions.count, 1);
            compare(actions.signalArguments[0][1], "shutdown");
        }
    }
}