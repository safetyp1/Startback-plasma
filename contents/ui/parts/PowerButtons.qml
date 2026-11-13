/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import ".." as UI

/**
 * Power management buttons for StartBack Plasma
 * Shutdown split button plus a dropdown with the remaining session actions.
 */
FocusScope {
    id: powerButtons

    property bool actionInProgress: false
    implicitWidth: shutdownButton.implicitWidth + dropdownButton.width + 2
    implicitHeight: Kirigami.Units.gridUnit * 1.8

    signal executeAction(string command, string actionType)
    signal keyNavUp()
    signal keyNavDown()
    signal keyNavLeft()
    signal closeRequested()

    activeFocusOnTab: true

    readonly property var actions: [
        { text: i18n("Restart"),        icon: "system-reboot",            type: "restart",
          command: "qdbus6 org.kde.Shutdown /Shutdown logoutAndReboot || systemctl reboot" },
        { text: i18n("Turn Off Screen"), icon: "video-display",           type: "screen_off",
          command: "kscreen-doctor --dpms off" },
        { text: i18n("Lock Screen"),    icon: "system-lock-screen",       type: "lock",
          command: "loginctl lock-session || qdbus org.kde.kscreenlocker /ScreenSaver Lock" },
        { text: i18n("Sleep"),          icon: "system-suspend",           type: "suspend",
          command: "systemctl suspend" },
        { text: i18n("Hibernate"),      icon: "system-suspend-hibernate", type: "hibernate",
          command: "systemctl hibernate" },
        { text: i18n("Log Out"),        icon: "system-log-out",           type: "logout",
          command: "qdbus6 org.kde.Shutdown /Shutdown logout || qdbus org.kde.ksmserver /KSMServer logout 1 0 0" }
    ]

    // -1 means the dropdown is closed.
    property alias menuIndex: systemActionsMenu.currentIndex
    readonly property bool menuOpen: menuIndex >= 0
    property bool menuOpenedWithKeyboard: false

    function openMenu(withKeyboard = false) {
        menuOpenedWithKeyboard = withKeyboard;
        forceActiveFocus();
        systemActionsMenu.popup(flyoutAnchor, 0, flyoutAnchor.height);
        menuIndex = actions.length - 1;
    }

    function closeMenu() {
        systemActionsMenu.close();
        menuIndex = -1;
        if (menuOpenedWithKeyboard) forceActiveFocus(); else focus = false;
    }

    function runShutdown() {
        powerButtons.executeAction("qdbus6 org.kde.Shutdown /Shutdown logoutAndShutdown || systemctl poweroff", "shutdown");
    }

    function runAction(index) {
        const action = actions[index];
        if (!action) return;
        closeMenu();
        powerButtons.executeAction(action.command, action.type);
    }

    Keys.onPressed: (event) => {
        if (menuOpen) {
            switch (event.key) {
            case Qt.Key_Up:
                event.accepted = true;
                menuIndex = (menuIndex - 1 + actions.length) % actions.length;
                break;
            case Qt.Key_Down:
                event.accepted = true;
                menuIndex = (menuIndex + 1) % actions.length;
                break;
            case Qt.Key_Left:
            case Qt.Key_Escape:
                event.accepted = true;
                closeMenu();
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                event.accepted = true;
                runAction(menuIndex);
                break;
            }
            return;
        }

        switch (event.key) {
        case Qt.Key_Up:    event.accepted = true; keyNavUp(); break;
        case Qt.Key_Down:  event.accepted = true; keyNavDown(); break;
        case Qt.Key_Left:  event.accepted = true; keyNavLeft(); break;
        case Qt.Key_Right: event.accepted = true; openMenu(true); break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space: event.accepted = true; runShutdown(); break;
        }
    }

    onActiveFocusChanged: if (!activeFocus && !systemActionsMenu.visible) menuIndex = -1

    Connections {
        target: kicker
        function onExpandedChanged() { if (!kicker.expanded) systemActionsMenu.close(); }
    }

    Rectangle {
        objectName: "powerButtonFrame"
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.28)

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: dropdownButton.width + 1
            width: 1
            color: parent.border.color
        }
    }

    PlasmaComponents3.Button {
        id: shutdownButton
        objectName: "shutdownButton"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width - dropdownButton.width - 2
        leftPadding: Kirigami.Units.smallSpacing * 2
        rightPadding: Kirigami.Units.smallSpacing * 2
        text: i18n("Shut down")
        icon.name: "system-shutdown"
        enabled: !powerButtons.actionInProgress
        focusPolicy: Qt.NoFocus
        hoverEnabled: true
        background: PlasmaExtras.Highlight {
            anchors.fill: parent
            hovered: shutdownButton.enabled && (shutdownButton.hovered || (powerButtons.activeFocus && !powerButtons.menuOpen))
            pressed: shutdownButton.pressed
            visible: hovered || pressed
        }

        contentItem: PlasmaComponents3.Label {
            text: shutdownButton.text
            leftPadding: shutdownIcon.width + Kirigami.Units.smallSpacing * 2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            UI.ReferenceIcon {
                id: shutdownIcon
                objectName: "shutdownIcon"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Kirigami.Units.iconSizes.small
                height: width
                iconName: shutdownButton.icon.name
                opacity: shutdownButton.enabled ? 1 : 0.4
            }
        }

        onClicked: powerButtons.runShutdown()

        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            interactive: false
            mainText: shutdownButton.text
            subText: i18n("Closes all open programs, shuts down the system and turns off your computer.")
        }
    }

    PlasmaComponents3.Button {
        id: dropdownButton
        objectName: "powerOptionsButton"
        Accessible.name: i18n("Power options")
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Kirigami.Units.gridUnit * 1.2
        icon.name: "go-next"
        focusPolicy: Qt.NoFocus
        hoverEnabled: true
        background: PlasmaExtras.Highlight {
            anchors.fill: parent
            hovered: dropdownButton.hovered || powerButtons.menuOpen
            pressed: dropdownButton.pressed
            visible: hovered || pressed
        }

        contentItem: UI.ReferenceIcon {
            iconName: dropdownButton.icon.name
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }

        onClicked: powerButtons.menuOpen ? powerButtons.closeMenu() : powerButtons.openMenu()
    }

    Item {
        id: flyoutAnchor
        parent: dropdownButton
        x: dropdownButton.width
        y: dropdownButton.height - systemActionsMenu.implicitHeight - height
        width: 1
        height: 1
    }

    HoverDismissMenu {
        id: systemActionsMenu
        objectName: "powerOptionsMenu"
        anchorItem: dropdownButton
        anchorHovered: dropdownButton.hovered
        dismissOnMenuExit: true
        onAboutToHide: currentIndex = -1
        onClosed: {
            if (powerButtons.menuOpenedWithKeyboard && powerButtons.visible && kicker.expanded) {
                powerButtons.forceActiveFocus();
            } else {
                powerButtons.focus = false;
            }
        }

        Shortcut {
            sequences: ["Left", "Escape"]
            enabled: systemActionsMenu.opened
            context: Qt.ApplicationShortcut
            onActivated: {
                powerButtons.menuOpenedWithKeyboard = true;
                powerButtons.closeMenu();
            }
        }

        Instantiator {
            model: powerButtons.actions
            delegate: PlasmaComponents3.MenuItem {
                required property int index
                required property var modelData
                text: modelData.text
                icon.name: modelData.icon
                enabled: !powerButtons.actionInProgress
                onTriggered: powerButtons.runAction(index)
                Keys.onLeftPressed: event => { event.accepted = true; powerButtons.closeMenu(); }
            }
            onObjectAdded: (index, object) => systemActionsMenu.insertItem(index, object)
            onObjectRemoved: (index, object) => systemActionsMenu.removeItem(object)
        }
    }
}
