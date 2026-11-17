// Sunshine window bar: close / minimize / maximize buttons and the title of the active window.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation
    fullRepresentation: Item { }

    TaskManager.TasksModel {
        id: tasks
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
    }
    readonly property var activeIndex: tasks.activeTask
    readonly property bool hasActive: activeIndex && activeIndex.valid
    readonly property string title: hasActive ? String(tasks.data(activeIndex, Qt.DisplayRole)) : "Sunshine OS"

    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        Repeater {
            model: [
                { c: "#e5484d", act: "close" },
                { c: "#f5a442", act: "min" },
                { c: "#9be37a", act: "max" }
            ]
            delegate: Rectangle {
                Layout.preferredWidth: 12; Layout.preferredHeight: 12; radius: 6
                color: ma.containsMouse ? modelData.c : Qt.rgba(1, 1, 1, 0.22)
                opacity: root.hasActive ? 1 : 0.4
                MouseArea {
                    id: ma; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (!root.hasActive) return
                        if (modelData.act === "close") tasks.requestClose(root.activeIndex)
                        else if (modelData.act === "min") tasks.requestToggleMinimized(root.activeIndex)
                        else tasks.requestToggleMaximized(root.activeIndex)
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true; Layout.leftMargin: 6
            text: root.title; color: "#f4f0eb"; elide: Text.ElideRight
            font.pixelSize: Kirigami.Units.gridUnit * 0.72; font.bold: true
        }
    }
}
