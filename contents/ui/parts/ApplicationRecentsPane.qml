import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

FocusScope {
    id: pane

    property Item anchorItem: null
    property var owner: null
    property var entries: []
    property string applicationName: ""
    property string applicationIcon: ""
    property string sectionTitle: ""
    readonly property bool opened: entries.length > 0
    visible: opened
    activeFocusOnTab: true

    signal itemTriggered()

    function openFor(item, actionList, title, source, name, icon) {
        if (!kicker.expanded || !item || !item.visible || !actionList || actionList.length === 0) return false;
        anchorItem = item;
        owner = source;
        applicationName = name || "";
        applicationIcon = typeof icon === "string" ? icon : "";
        sectionTitle = title || i18n("Recent");
        recentList.currentIndex = -1;
        entries = actionList;
        recentList.positionViewAtBeginning();
        return true;
    }

    function close(restoreFocus = true) {
        const anchor = anchorItem;
        entries = [];
        owner = null;
        anchorItem = null;
        if (restoreFocus && kicker.expanded && anchor && anchor.visible) anchor.forceActiveFocus();
    }

    function focusFirst() {
        if (!opened) return;
        recentList.currentIndex = 0;
        forceActiveFocus();
    }

    function activateEntry(index) {
        const entry = entries[index];
        if (!entry || entry.enabled === false) return;
        if (typeof entry.trigger === "function") entry.trigger();
        else if (entry.actionId && owner && typeof owner.runAction === "function") {
            owner.runAction(owner.jumpIndex, String(entry.actionId), entry.actionArgument);
        }
        itemTriggered();
    }

    Connections {
        target: kicker
        function onExpandedChanged() { if (!kicker.expanded) pane.close(false); }
    }

    Connections {
        target: pane.anchorItem
        function onVisibleChanged() { if (pane.anchorItem && !pane.anchorItem.visible) pane.close(false); }
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_Escape:
            event.accepted = true;
            close();
            break;
        case Qt.Key_Up:
            event.accepted = true;
            recentList.decrementCurrentIndex();
            break;
        case Qt.Key_Down:
            event.accepted = true;
            recentList.incrementCurrentIndex();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            event.accepted = true;
            activateEntry(recentList.currentIndex);
            break;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing * 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PC3.ToolButton {
                objectName: "applicationRecentsBack"
                icon.name: "go-previous"
                Accessible.name: i18n("Back")
                onClicked: pane.close()
            }

            Kirigami.Icon {
                source: pane.applicationIcon
                visible: pane.applicationIcon !== ""
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Layout.preferredWidth
            }

            PC3.Label {
                text: pane.applicationName
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Kirigami.Heading {
            text: pane.sectionTitle
            level: 4
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        PC3.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff
            PC3.ScrollBar.vertical.policy: PC3.ScrollBar.AsNeeded

            ListView {
                id: recentList
                objectName: "applicationRecentsList"
                clip: true
                model: pane.entries
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false

                delegate: PC3.MenuItem {
                    required property int index
                    required property var modelData
                    width: recentList.width
                    text: modelData.text || ""
                    icon.name: typeof modelData.icon === "string" ? modelData.icon : ""
                    enabled: modelData.enabled !== false
                    highlighted: pane.activeFocus && ListView.isCurrentItem
                    onTriggered: pane.activateEntry(index)
                    Keys.onLeftPressed: event => { event.accepted = true; pane.close(); }
                    Keys.onEscapePressed: event => { event.accepted = true; pane.close(); }
                }
            }
        }
    }
}