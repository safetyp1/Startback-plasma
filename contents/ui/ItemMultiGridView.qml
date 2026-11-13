/*
    SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
    SPDX-License-Identifier: AGPL-3.0-or-later
*/

import QtQuick

import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.plasma.plasmoid

PlasmaComponents.ScrollView {
    id: itemMultiGrid

    anchors {
        top: parent.top
    }

    width: parent.width
    implicitHeight: itemColumn.implicitHeight
    clip: true

    PlasmaComponents.ScrollBar.horizontal.policy: PlasmaComponents.ScrollBar.AlwaysOff
    PlasmaComponents.ScrollBar.vertical.policy: PlasmaComponents.ScrollBar.AsNeeded

    signal keyNavLeft(int subGridIndex)
    signal keyNavRight(int subGridIndex)
    signal keyNavUp()
    signal keyNavDown()

    property bool grabFocus: false
    // Ordered list of { title, model }: the caller decides which section comes
    // first, instead of inheriting whatever order the runners answered in.
    property var sections: []
    onSectionsChanged: Qt.callLater(() => {
        flickable.cancelFlick();
        flickable.contentY = 0;
        selectFirstResult();
    })
    property alias count: repeater.count
    property alias flickableItem: flickable

    property int cellWidth
    property int cellHeight
    property int iconSize: Kirigami.Units.iconSizes.medium

    function selectFirstResult() {
        let selected = false;
        for (let sectionIndex = 0; sectionIndex < repeater.count; ++sectionIndex) {
            const section = repeater.itemAt(sectionIndex);
            if (!section) continue;
            const grid = section.itemGrid;
            grid.currentIndex = !selected && grid.count > 0 ? 0 : -1;
            if (grid.count > 0) selected = true;
        }
    }

    function moveSelection(step) {
        let selectedIndex = -1;
        let total = 0;
        for (let sectionIndex = 0; sectionIndex < repeater.count; ++sectionIndex) {
            const grid = subGridAt(sectionIndex);
            if (grid.currentIndex >= 0) selectedIndex = total + grid.currentIndex;
            total += grid.count;
        }
        if (total === 0) return false;

        const nextIndex = selectedIndex < 0 ? (step < 0 ? total - 1 : 0)
                                           : Math.max(0, Math.min(total - 1, selectedIndex + step));
        let offset = 0;
        for (let sectionIndex = 0; sectionIndex < repeater.count; ++sectionIndex) {
            const grid = subGridAt(sectionIndex);
            const localIndex = nextIndex - offset;
            grid.currentIndex = localIndex >= 0 && localIndex < grid.count ? localIndex : -1;
            offset += grid.count;
        }
        return true;
    }

    function activateCurrentResult() {
        for (let sectionIndex = 0; sectionIndex < repeater.count; ++sectionIndex) {
            const grid = subGridAt(sectionIndex);
            if (grid.currentItem && grid.currentItem.enabled) {
                grid.currentItem.actionTriggered("", null);
                return true;
            }
        }
        return false;
    }

    function subGridAt(index) {
        return repeater.itemAt(index).itemGrid;
    }

    function tryActivate(row, col) {
        if (flickable.contentY > 0) {
            row = 0;
        }

        var target = null;
        var rows = 0;

        for (var i = 0; i < repeater.count; i++) {
            var grid = subGridAt(i);

            if (rows <= row) {
                target = grid;
                rows += grid.lastRow() + 2; // Header counts as one.
            } else {
                break;
            }
        }

        if (target) {
            rows -= (target.lastRow() + 2);
            target.tryActivate(row - rows, col);
        }
    }

    onFocusChanged: {
        if (!focus) {
            for (var i = 0; i < repeater.count; i++) {
                subGridAt(i).focus = false;
            }
        }
    }

    Flickable {
        id: flickable
        width: itemMultiGrid.availableWidth
        height: itemMultiGrid.availableHeight
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: itemColumn.implicitHeight
        clip: true

        Column {
            id: itemColumn
            width: flickable.width

            Repeater {
                id: repeater

                model: itemMultiGrid.sections

                delegate: Item {
                    width: itemColumn.width
                    height: visible ? gridView.height + gridViewLabel.height + Kirigami.Units.largeSpacing * 2 : 0
                    visible: gridView.count > 0

                    property Item itemGrid: gridView

                    Kirigami.Heading {
                        id: gridViewLabel
                        anchors.top: parent.top
                        x: Kirigami.Units.smallSpacing
                        width: parent.width - x
                        height: implicitHeight

                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        opacity: 1.0
                        color: Kirigami.Theme.textColor
                        level: 4

                        text: modelData && modelData.title ? modelData.title : ""
                        textFormat: Text.PlainText
                    }

                    MouseArea {
                        width: parent.width
                        height: parent.height
                        onClicked: {
                            // CORREÇÃO: Verificar se root existe
                            if (typeof root !== "undefined" && root.toggle) {
                                root.toggle();
                            } else if (typeof kicker !== "undefined") {
                                kicker.expanded = false;
                            }
                        }
                    }

                    ItemGridView {
                        id: gridView

                        anchors {
                            top: gridViewLabel.bottom
                            topMargin: Kirigami.Units.largeSpacing
                        }

                        width: parent.width
                        height: Math.ceil(count / Math.max(1, Math.floor(width / cellWidth))) * cellHeight

                        cellWidth: Math.max(1, Math.min(width, itemMultiGrid.cellWidth))
                        cellHeight: itemMultiGrid.cellHeight
                        iconSize: itemMultiGrid.iconSize
                        dragEnabled: false

                        verticalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff

                        model: modelData ? modelData.model : null

                        onFocusChanged: {
                            if (focus) {
                                itemMultiGrid.focus = true;
                            }
                        }

                        onCountChanged: {
                            Qt.callLater(itemMultiGrid.selectFirstResult);
                            if (itemMultiGrid.grabFocus && index == 0 && count > 0) {
                                currentIndex = 0;
                                focus = true;
                            }
                        }

                        onCurrentItemChanged: {
                            if (!currentItem) {
                                return;
                            }

                            if (index == 0 && currentRow() === 0) {
                                flickable.contentY = 0;
                                return;
                            }

                            var y = currentItem.y;
                            y = contentItem.mapToItem(flickable.contentItem, 0, y).y;

                            if (y < flickable.contentY) {
                                flickable.contentY = y;
                            } else {
                                y += itemMultiGrid.cellHeight;
                                y -= flickable.contentY;
                                y -= itemMultiGrid.height;

                                if (y > 0) {
                                    flickable.contentY += y;
                                }
                            }
                        }

                        onKeyNavLeft: {
                            itemMultiGrid.keyNavLeft(index);
                        }

                        onKeyNavRight: {
                            itemMultiGrid.keyNavRight(index);
                        }

                        onKeyNavUp: {
                            if (index > 0) {
                                var prevGrid = subGridAt(index - 1);
                                prevGrid.tryActivate(prevGrid.lastRow(), currentCol());
                            } else {
                                itemMultiGrid.keyNavUp();
                            }
                        }

                        onKeyNavDown: {
                            if (index < repeater.count - 1) {
                                subGridAt(index + 1).tryActivate(0, currentCol());
                            } else {
                                itemMultiGrid.keyNavDown();
                            }
                        }
                    }

                    // HACK: Steal wheel events from the nested grid view and forward them to
                    // the ScrollView's internal WheelArea.
                    Kicker.WheelInterceptor {
                        anchors.fill: gridView
                        z: 1

                        destination: flickable
                    }
                }
            }
        }
    }
}