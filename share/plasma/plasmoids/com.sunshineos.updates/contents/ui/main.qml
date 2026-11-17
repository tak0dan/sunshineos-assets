// Sunshine updates: a small icon for the taskbar. Red dot = package updates; download arrow = distro update, Sunshine repository
// (themes, configs, tools) update, or more than 50 packages. The popup lists what is pending and starts the update.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root
    property int packages: 0
    property int sunshine: 0
    property bool distro: false
    property string release: ""
    property string st: "none"
    readonly property string stateCmd: "cat \"${XDG_CACHE_HOME:-$HOME/.cache}/sunshine/update-state.json\" 2>/dev/null"

    toolTipMainText: st === "none" ? "System is up to date" : (st === "arrow" ? "Important updates are available" : packages + " package updates")
    toolTipSubText: "Click to see details"
    Plasmoid.icon: "system-software-update"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    function apply(text) {
        try {
            var d = JSON.parse(text)
            packages = d.packages; sunshine = d.sunshine; distro = d.distro; release = d.release; st = d.state
        } catch (e) { }
    }
    P5Support.DataSource {
        id: reader
        engine: "executable"
        onNewData: (source, data) => { if (source === root.stateCmd) root.apply(String(data["stdout"])); disconnectSource(source) }
    }
    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (source, data) => { disconnectSource(source); reader.connectSource(root.stateCmd) }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: reader.connectSource(root.stateCmd) }
    Timer { interval: 120000; running: true; onTriggered: runner.connectSource("/usr/local/bin/sunshine-update-check --quiet") }

    compactRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing
        Layout.preferredWidth: Layout.minimumWidth
        Kirigami.Icon { id: ic; anchors.centerIn: parent; width: Kirigami.Units.iconSizes.smallMedium; height: width; source: "system-software-update"; isMask: false }
        // red dot at the right
        Rectangle {
            visible: root.st === "dot"
            width: 9; height: 9; radius: 5; color: "#e5484d"; border.width: 1; border.color: "#17121a"
            anchors.right: ic.right; anchors.top: ic.top; anchors.rightMargin: -3; anchors.topMargin: -2
        }
        // download arrow badge (like Garuda's update widget)
        Rectangle {
            visible: root.st === "arrow"
            width: 14; height: 14; radius: 7; color: "#f5a442"; border.width: 1; border.color: "#17121a"
            anchors.right: ic.right; anchors.top: ic.top; anchors.rightMargin: -5; anchors.topMargin: -4
            Kirigami.Icon { anchors.centerIn: parent; width: 10; height: 10; source: "go-down-symbolic"; isMask: true; color: "#2a1a0e" }
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        spacing: Kirigami.Units.largeSpacing
        Text { text: root.st === "none" ? "Everything is up to date ☀" : "Updates are available"; color: "#ffd27a"; font.pixelSize: 16; font.bold: true; Layout.margins: 8 }
        Text { text: "Packages: " + root.packages; color: "#f4f0eb"; Layout.leftMargin: 8 }
        Text { visible: root.sunshine > 0; text: "Sunshine themes, configs and tools: " + root.sunshine + " update(s)"; color: "#f5a442"; Layout.leftMargin: 8 }
        Text { visible: root.distro; text: "A new Sunshine OS release is available" + (root.release ? " (" + root.release + ")" : ""); color: "#f5a442"; Layout.leftMargin: 8 }
        RowLayout {
            Layout.margins: 8
            Rectangle { Layout.fillWidth: true; implicitHeight: 34; radius: 8; color: ub.containsMouse ? "#e87932" : "#c9652a"
                Text { anchors.centerIn: parent; text: "Update now"; color: "white"; font.bold: true }
                MouseArea { id: ub; anchors.fill: parent; hoverEnabled: true; onClicked: { runner.connectSource("/usr/local/bin/sunshine-update"); root.expanded = false } } }
            Rectangle { Layout.fillWidth: true; implicitHeight: 34; radius: 8; color: "transparent"; border.width: 1; border.color: cb.containsMouse ? "#ffd27a" : "#e87932"
                Text { anchors.centerIn: parent; text: "Check again"; color: "#f4f0eb" }
                MouseArea { id: cb; anchors.fill: parent; hoverEnabled: true; onClicked: runner.connectSource("/usr/local/bin/sunshine-update-check --quiet") } }
        }
    }
}
