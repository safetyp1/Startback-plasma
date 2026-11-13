import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import ".." as UI

PlasmaComponents3.Button {
    id: button

    property int currentShowApps: 0
    property bool searching: false
    property bool launcherExpanded: true
    property bool hoverActionTriggered: false

    signal searchCancelled()
    signal showAppsChangeRequested(int value)

    text: searching || currentShowApps !== 0 ? i18n("Back") : i18n("All Programs")
    icon.name: searching || currentShowApps !== 0 ? "go-previous" : "go-next"
    activeFocusOnTab: true
    hoverEnabled: true
    onHoveredChanged: if (!hovered) hoverActionTriggered = false

    Timer {
        interval: 750
        running: button.hovered && button.visible && button.enabled && button.launcherExpanded
                 && !button.pressed && !button.hoverActionTriggered
        onTriggered: button.clicked()
    }

    background: PlasmaExtras.Highlight {
        anchors.fill: parent
        hovered: button.hovered || button.activeFocus
        pressed: button.pressed
        visible: hovered || pressed
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing * 2

        UI.ReferenceIcon {
            iconName: button.icon.name
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }

        PlasmaComponents3.Label {
            text: button.text
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    onClicked: {
        hoverActionTriggered = true;
        if (searching) searchCancelled();
        else showAppsChangeRequested(currentShowApps === 0 ? 1 : 0);
    }
}