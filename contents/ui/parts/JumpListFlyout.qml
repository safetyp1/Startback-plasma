/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import org.kde.plasma.components as PlasmaComponents

/**
 * Recent documents flyout for an application row.
 * A QQC2 menu rather than the QMenu wrapper, because only this one lets the
 * left arrow walk back out to the list instead of forcing Escape.
 */
HoverDismissMenu {
    id: flyout

    property var entries: []
    anchorHovered: anchorItem !== null && "containsMouse" in anchorItem && anchorItem.containsMouse

    signal itemTriggered()
    // Entries taken from a Kicker actionList carry no closure, only an id to dispatch.
    signal actionRequested(string actionId, var actionArgument)

    function openFor(item, actionList, title) {
        if (!kicker.expanded || !item || !item.visible || !actionList || actionList.length === 0) return false;
        const list = [];
        if (title && title !== "") list.push({ text: title, enabled: false });
        for (let i = 0; i < actionList.length; i++) list.push(actionList[i]);
        entries = list;
        anchorItem = item;
        popup(item, item.width, 0);
        return true;
    }

    onClosed: if (anchorItem && anchorItem.visible && kicker.expanded) anchorItem.forceActiveFocus()

    Connections {
        target: kicker
        function onExpandedChanged() {
            if (!kicker.expanded) flyout.close();
        }
    }

    Connections {
        target: flyout.anchorItem
        function onVisibleChanged() {
            if (!flyout.anchorItem.visible) flyout.close();
        }
    }

    // Second route out, for when the menu is a window of its own and the
    // focused entry never sees the key. Only live while this flyout is open.
    Shortcut {
        sequence: "Left"
        enabled: flyout.opened
        context: Qt.ApplicationShortcut
        onActivated: flyout.close()
    }

    Instantiator {
        model: flyout.entries
        delegate: PlasmaComponents.MenuItem {
            required property var modelData

            text: modelData.text || ""
            icon.name: typeof modelData.icon === "string" ? modelData.icon : ""
            enabled: modelData.enabled !== false

            onTriggered: {
                if (typeof modelData.trigger === "function") modelData.trigger();
                else if (modelData.actionId) flyout.actionRequested(String(modelData.actionId), modelData.actionArgument);
                flyout.itemTriggered();
            }

            Keys.priority: Keys.BeforeItem
            Keys.onLeftPressed: event => { event.accepted = true; flyout.close(); }
        }
        onObjectAdded: (index, object) => flyout.insertItem(index, object)
        onObjectRemoved: (index, object) => flyout.removeItem(object)
    }
}
