/*
 *  SPDX-FileCopyrightText: 2025 Walter Rodrigues <wmr2@cin.ufpe.br>
 *  SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configAppearance

    property alias cfg_menuBackgroundOpacity: menuBackgroundOpacity.value
    property alias cfg_menuFrameUseThemeColor: menuFrameUseThemeColor.checked
    property alias cfg_menuFrameColor: menuFrameColor.color
    property alias cfg_menuFrameOpacity: menuFrameOpacity.value

    property alias cfg_listPanelUseThemeColor: listPanelUseThemeColor.checked
    property alias cfg_listPanelColor: listPanelColor.color
    property alias cfg_listPanelOpacity: listPanelOpacity.value

    property alias cfg_sidePanelUseThemeColor: sidePanelUseThemeColor.checked
    property alias cfg_sidePanelColor: sidePanelColor.color
    property alias cfg_sidePanelOpacity: sidePanelOpacity.value
    property alias cfg_useWindowsIconFont: useWindowsIconFont.checked
    property alias cfg_windowsIconFont: windowsIconFont.text

    FileDialog {
        id: fontPicker
        title: i18n("Choose a local Segoe icon font")
        nameFilters: [i18n("Font files (*.ttf *.otf)")]
        onAccepted: windowsIconFont.text = selectedFile.toString()
    }

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        CheckBox {
            id: useWindowsIconFont
            text: i18n("Use local Windows icon font")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Icon font:")
            enabled: useWindowsIconFont.checked

            TextField {
                id: windowsIconFont
                Layout.fillWidth: true
                placeholderText: i18n("Automatic local font")
                Accessible.name: i18n("Local Segoe icon font path")
            }

            ToolButton {
                icon.name: "document-open"
                onClicked: fontPicker.open()
                ToolTip.text: i18n("Choose font")
                ToolTip.visible: hovered
                Accessible.name: ToolTip.text
            }
        }

        Label {
            text: i18n("Use a local Segoe Fluent Icons or Segoe MDL2 Assets font. No Windows fonts are bundled with this widget.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: configAppearance.width - Kirigami.Units.gridUnit * 2
        }

        Item { Kirigami.FormData.isSection: true }

        Slider {
            id: menuBackgroundOpacity
            objectName: "menuBackgroundOpacity"
            Kirigami.FormData.label: i18n("Background opacity:")
            from: 0
            to: 100
            value: 85
            stepSize: 1
            snapMode: Slider.SnapAlways
        }

        Label {
            text: menuBackgroundOpacity.value + "%"
        }

        Item { Kirigami.FormData.isSection: true }

        // ---- Whole menu -----------------------------------------------------

        Slider {
            id: menuFrameOpacity
            Kirigami.FormData.label: i18n("Whole menu tint:")
            from: 0
            to: 100
            stepSize: 1
            snapMode: Slider.SnapAlways
        }

        Label {
            text: menuFrameOpacity.value === 0 ? i18n("No tint") : menuFrameOpacity.value + "%"
        }

        CheckBox {
            id: menuFrameUseThemeColor
            text: i18n("Use the theme background colour")
            enabled: menuFrameOpacity.value > 0
        }

        KQuickControls.ColorButton {
            id: menuFrameColor
            Kirigami.FormData.label: i18n("Menu colour:")
            enabled: menuFrameOpacity.value > 0 && !menuFrameUseThemeColor.checked
            showAlphaChannel: false
        }

        Item { Kirigami.FormData.isSection: true }

        // ---- Application list ------------------------------------------------

        Slider {
            id: listPanelOpacity
            Kirigami.FormData.label: i18n("Application list tint:")
            from: 0
            to: 100
            stepSize: 1
            snapMode: Slider.SnapAlways
        }

        Label {
            text: listPanelOpacity.value === 0 ? i18n("No tint") : listPanelOpacity.value + "%"
        }

        CheckBox {
            id: listPanelUseThemeColor
            text: i18n("Use the theme background colour")
            enabled: listPanelOpacity.value > 0
        }

        KQuickControls.ColorButton {
            id: listPanelColor
            Kirigami.FormData.label: i18n("Application list colour:")
            enabled: listPanelOpacity.value > 0 && !listPanelUseThemeColor.checked
            showAlphaChannel: false
        }

        Item { Kirigami.FormData.isSection: true }

        // ---- Side panel --------------------------------------------------------

        Slider {
            id: sidePanelOpacity
            Kirigami.FormData.label: i18n("Side panel tint:")
            from: 0
            to: 100
            stepSize: 1
            snapMode: Slider.SnapAlways
        }

        Label {
            text: sidePanelOpacity.value === 0 ? i18n("No tint") : sidePanelOpacity.value + "%"
        }

        CheckBox {
            id: sidePanelUseThemeColor
            text: i18n("Use the theme background colour")
            enabled: sidePanelOpacity.value > 0
        }

        KQuickControls.ColorButton {
            id: sidePanelColor
            Kirigami.FormData.label: i18n("Side panel colour:")
            enabled: sidePanelOpacity.value > 0 && !sidePanelUseThemeColor.checked
            showAlphaChannel: false
        }
    }
}
