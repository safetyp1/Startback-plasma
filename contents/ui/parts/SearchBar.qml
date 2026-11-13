/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import ".." as UI

/**
 * Search bar component for StartBack Plasma
 * Provides text input for searching applications and files
 */
Rectangle {
    id: searchBar

    // Layout properties
    Layout.fillWidth: true
    implicitHeight: searchField.height + Kirigami.Units.smallSpacing * 2
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: implicitHeight

    color: "transparent"

    // Properties
    property alias text: searchField.text
    property bool isSearching: text !== ""
    property var menuContentRef: null
    property int currentShowApps: 0

    // Signals
    signal searchTextChanged(string text)
    signal escapePressed()
    signal navigateToResults()
    signal activateResult()
    signal keyNavUp()
    signal keyNavDown()
    signal contextMenuRequested(real x, real y)

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.RightButton
        onClicked: mouse => searchBar.contextMenuRequested(mouse.x, mouse.y)
    }

    // Public functions
    function clear() {
        searchField.clear();
    }

    function backspace() {
        searchField.backspace();
    }

    function appendText(newText) {
        searchField.appendText(newText);
    }

    function focusSearchField() {
        searchField.forceActiveFocus();
    }

    // Search field
    PlasmaComponents3.TextField {
        id: searchField
        objectName: "searchInput"

        width: Math.max(0, parent.width - Kirigami.Units.smallSpacing * 4)
        height: Kirigami.Units.gridUnit * 1.8

        anchors {
            left: parent.left
            leftMargin: Kirigami.Units.smallSpacing * 2
            verticalCenter: parent.verticalCenter
        }

        placeholderText: i18n("Search programs and files")
        leftPadding: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing * 4
        rightPadding: Kirigami.Units.smallSpacing * 2
        color: Kirigami.Theme.textColor
        placeholderTextColor: Qt.rgba(color.r, color.g, color.b, 0.55)

        background: Rectangle {
            radius: 1
            color: Qt.rgba(0, 0, 0, 0.32)
            border.width: 1
            border.color: searchField.activeFocus ? Kirigami.Theme.highlightColor
                                                 : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.22)
        }

        UI.ReferenceIcon {
            anchors.left: parent.left
            anchors.leftMargin: Kirigami.Units.smallSpacing * 2
            anchors.verticalCenter: parent.verticalCenter
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            iconName: "edit-find"
            color: Kirigami.Theme.textColor
            opacity: 0.6
        }

        Rectangle {
            x: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing * 3
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height * 0.6
            color: Kirigami.Theme.textColor
            opacity: 0.2
        }

        onTextChanged: {
            searchBar.isSearching = (text !== "");
            // The query travels through the signal only: assigning it to a model
            // here would overwrite the binding that feeds every search section.
            searchBar.searchTextChanged(text);
        }

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

        function clear() {
            text = "";
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (searchBar.isSearching) {
                    clear();
                } else {
                    searchBar.escapePressed();
                }
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && searchBar.isSearching) {
                event.accepted = true;
                searchBar.activateResult();
            } else if (event.key === Qt.Key_Up) {
                event.accepted = true;
                searchBar.keyNavUp();
            } else if (event.key === Qt.Key_Down) {
                event.accepted = true;
                searchBar.keyNavDown();
            } else if (event.key === Qt.Key_Tab) {
                event.accepted = true;
                searchBar.keyNavDown();
            } else if (event.key === Qt.Key_Backtab) {
                event.accepted = true;
                searchBar.navigateToResults();
            }
        }
    }
}
