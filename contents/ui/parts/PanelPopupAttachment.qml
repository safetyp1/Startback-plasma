import QtQuick
import QtQuick.Window
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

Rectangle {
    id: attachment
    color: "transparent"

    property var popupWindow: Window.window
    property int backgroundOpacity: 85
    opacity: Math.max(0, Math.min(100, backgroundOpacity)) / 100
    layer.enabled: nativeBackground !== null && popupWindow.visible

    readonly property Item nativeBackground: {
        if (!popupWindow || !("mainItem" in popupWindow)) return null;
        for (const child of popupWindow.contentItem.children) {
            if (child === popupWindow.mainItem) continue;
            for (const artwork of child.children) {
                if (artwork instanceof KSvg.FrameSvgItem) {
                    return child;
                }
            }
        }
        return null;
    }
    readonly property Item nativeFrame: {
        if (!nativeBackground) return null;
        for (const artwork of nativeBackground.children) {
            if (artwork instanceof KSvg.FrameSvgItem) return artwork;
        }
        return null;
    }
    readonly property real leftInset: popupWindow && "leftPadding" in popupWindow ? popupWindow.leftPadding : 0
    readonly property real rightInset: popupWindow && "rightPadding" in popupWindow ? popupWindow.rightPadding : 0
    readonly property real topInset: popupWindow && "topPadding" in popupWindow ? popupWindow.topPadding : 0
    readonly property real bottomInset: popupWindow && "bottomPadding" in popupWindow ? popupWindow.bottomPadding : 0
    readonly property rect contentRect: Qt.rect(Kirigami.Units.smallSpacing - leftInset,
                                               Kirigami.Units.smallSpacing - topInset,
                                               Math.max(0, width - Kirigami.Units.smallSpacing * 2),
                                               Math.max(0, height - Kirigami.Units.smallSpacing * 2))

    anchors.fill: parent
    anchors.leftMargin: -leftInset
    anchors.rightMargin: -rightInset
    anchors.topMargin: -topInset
    anchors.bottomMargin: -bottomInset

    Binding {
        target: attachment.popupWindow
        property: "borders"
        value: 0
        when: attachment.popupWindow !== null && "borders" in attachment.popupWindow
    }

    Connections {
        target: attachment.popupWindow
        ignoreUnknownSignals: true

        function onBordersChanged() {
            if (attachment.popupWindow.borders !== 0) attachment.popupWindow.borders = 0;
        }
    }

    Binding {
        target: attachment.popupWindow
        property: "margin"
        value: 0
        when: attachment.popupWindow !== null && "margin" in attachment.popupWindow
    }

    Binding {
        target: attachment.nativeFrame
        property: "imagePath"
        value: ""
        when: attachment.nativeFrame !== null
    }

    Binding {
        target: attachment.nativeBackground
        property: "visible"
        value: false
        when: attachment.nativeBackground !== null
    }
}