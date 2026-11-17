// Sunshine start menu: search field, 4-column pinned grid ("All apps"), two-column recommended files ("More"), user and power footer.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root
    readonly property color gold: "#ffd27a"
    readonly property color amber: "#f5a442"
    readonly property color orange: "#e87932"
    readonly property color text: "#f4f0eb"
    readonly property color muted: "#aaa3a0"
    readonly property var pinnedIds: ["firefox.desktop", "systemsettings.desktop", "org.kde.dolphin.desktop", "org.kde.konsole.desktop",
                                      "sunshine-store.desktop", "zen.desktop", "org.kde.kate.desktop", "sunshine-welcome.desktop"]
    property var pinned: []
    property var found: ({})
    property bool allApps: false
    property string userName: ""

    property bool open: false
    readonly property int taskbarH: 62      // the 48 px taskbar plus a gap; the top bar is above the menu anyway
    readonly property int menuW: Math.max(532, Math.round(Screen.width * 0.285))
    readonly property int menuH: Math.round(Screen.height * 0.60)
    preferredRepresentation: compactRepresentation
    fullRepresentation: Item { }
    Connections { target: Plasmoid; function onActivated() { root.open = !root.open } }
    PlasmaCore.Dialog {
        id: dlg
        visible: root.open
        location: PlasmaCore.Types.Floating
        backgroundHints: PlasmaCore.Types.StandardBackground
        hideOnWindowDeactivate: true
        x: Screen.virtualX + Math.round((Screen.width - root.menuW) / 2)
        y: Screen.virtualY + Screen.height - root.taskbarH - root.menuH
        onVisibleChanged: if (!visible) root.open = false
        mainItem: MenuContent { implicitWidth: root.menuW; implicitHeight: root.menuH; width: root.menuW; height: root.menuH }
    }
    Plasmoid.icon: "sunshine-menu"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    function bare(id) { return String(id).replace(/^applications:/, "") }
    function consider(row, id, name, icon) {
        var b = bare(id)
        if (pinnedIds.indexOf(b) < 0) return
        found[b] = { row: row, name: name, icon: icon }
        var l = []
        for (var i = 0; i < pinnedIds.length; i++) if (found[pinnedIds[i]]) l.push(found[pinnedIds[i]])
        pinned = l
    }
    function close() { root.open = false }
    function run(cmd) { exec.connectSource(cmd) }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => { disconnectSource(source) }
    }
    P5Support.DataSource {
        engine: "executable"; connectedSources: ["id -un"]
        onNewData: (source, data) => { root.userName = String(data["stdout"]).trim(); disconnectSource(source) }
    }
    property var apps: null
    Kicker.RootModel {
        id: rootModel
        autoPopulate: false; appletInterface: root
        showAllApps: true; showAllAppsCategorized: false; showRecentApps: false; showRecentDocs: false; showRecentFolders: false
        showPowerSession: false; showFavoritesPlaceholder: false; showRootSeparator: false
        onRefreshed: { var m = rootModel.modelForRow(0); root.apps = m }
        Component.onCompleted: refresh()
    }
    Kicker.RecentUsageModel { id: recent; shownItems: Kicker.RecentUsageModel.AppsAndDocs; ordering: Kicker.RecentUsageModel.Recent }
    Kicker.RunnerModel { id: runner; appletInterface: root; mergeResults: true; runners: ["krunner_services", "krunner_systemsettings", "krunner_recentdocuments"] }
    Repeater {
        model: root.apps
        delegate: Item { visible: false; Component.onCompleted: root.consider(index, model.favoriteId, model.display, model.decoration) }
    }

    compactRepresentation: Item {
        id: compact
        Layout.minimumWidth: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Kirigami.Icon { anchors.centerIn: parent; width: Math.min(parent.height, Kirigami.Units.iconSizes.medium + 4); height: width; source: "sunshine-menu"; active: ma.containsMouse }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.open = !root.open }
    }

    component Pill: Rectangle {
        id: pill
        property alias label: t.text
        signal clicked()
        implicitWidth: t.implicitWidth + 34; implicitHeight: 28; radius: 14
        color: pa.containsMouse ? Qt.rgba(1, 0.64, 0.26, 0.12) : "transparent"
        border.width: 1; border.color: pa.containsMouse ? root.gold : Qt.rgba(0.91, 0.47, 0.2, 0.75)
        Row { anchors.centerIn: parent; spacing: 6
            Text { id: t; color: root.amber; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "›"; color: root.amber; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; onClicked: pill.clicked() }
    }
    component Header: RowLayout {
        property alias title: h.text
        property alias pill: p.label
        signal pillClicked()
        Layout.fillWidth: true
        Text { id: h; color: root.amber; font.pixelSize: 15; font.bold: true; Layout.leftMargin: 12 }
        Item { Layout.fillWidth: true }
        Pill { id: p; onClicked: parent.pillClicked() }
    }


    component MenuContent: Item {
        id: menu
        focus: true
        Keys.onEscapePressed: root.close()
        Connections {
            target: root
            function onOpenChanged() { if (root.open) { search.text = ""; root.allApps = false; search.forceActiveFocus() } }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // search
            Rectangle {
                Layout.fillWidth: true; Layout.margins: 16; Layout.bottomMargin: 10
                implicitHeight: 40; radius: 8
                color: Qt.rgba(0.07, 0.07, 0.11, 0.8)
                border.width: 1; border.color: search.activeFocus ? root.gold : Qt.rgba(0.91, 0.47, 0.2, 0.8)
                RowLayout { anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                    Kirigami.Icon { source: "edit-find-symbolic"; isMask: true; color: root.gold; Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
                    TextInput {
                        id: search
                        Layout.fillWidth: true; color: root.text; font.pixelSize: 15; clip: true; selectByMouse: true
                        onTextChanged: runner.query = text
                        Keys.onEscapePressed: root.close()
                        Keys.onReturnPressed: { if (text.length && results.count > 0) { runner.trigger(0, "", null); root.close() } }
                        Text { text: "Type here to search"; color: root.muted; font.pixelSize: 15; visible: !search.text.length; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            // search results
            ListView {
                id: results
                visible: search.text.length > 0
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.leftMargin: 12; Layout.rightMargin: 12
                clip: true; model: runner
                delegate: Rectangle {
                    width: results.width; height: 44; radius: 8
                    color: ra.containsMouse ? Qt.rgba(1, 0.64, 0.26, 0.10) : "transparent"
                    Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 12
                        Kirigami.Icon { source: model.decoration; width: 28; height: 28; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: model.display; color: root.text; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: parent.width - 60 }
                    }
                    MouseArea { id: ra; anchors.fill: parent; hoverEnabled: true; onClicked: { runner.trigger(index, "", null); root.close() } }
                }
            }

            // pinned
            Header { visible: search.text.length === 0; title: root.allApps ? "All apps" : "Pinned"; pill: root.allApps ? "Back" : "All apps"; onPillClicked: root.allApps = !root.allApps; Layout.leftMargin: 16; Layout.rightMargin: 16 }
            Grid {
                visible: search.text.length === 0 && !root.allApps
                Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 6
                columns: 4; columnSpacing: 0; rowSpacing: 6
                Repeater {
                    model: root.pinned
                    delegate: Item {
                        width: Math.floor((menu.width - 32) / 4); height: 92
                        Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 8; color: pa2.containsMouse ? Qt.rgba(1, 0.64, 0.26, 0.09) : "transparent"
                            Rectangle { visible: pa2.containsMouse; width: 18; height: 2; radius: 1; color: root.gold; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 3 } }
                        Column { anchors.centerIn: parent; spacing: 7
                            Kirigami.Icon { source: modelData.icon; width: 40; height: 40; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: modelData.name; color: root.text; font.pixelSize: 13; width: 124; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                        }
                        MouseArea { id: pa2; anchors.fill: parent; hoverEnabled: true; onClicked: { root.apps.trigger(modelData.row, "", null); root.close() } }
                    }
                }
            }
            // all apps list
            ListView {
                visible: search.text.length === 0 && root.allApps
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.leftMargin: 12; Layout.rightMargin: 12
                clip: true; model: root.apps
                delegate: Rectangle {
                    width: ListView.view.width; height: 38; radius: 8
                    color: aa.containsMouse ? Qt.rgba(1, 0.64, 0.26, 0.10) : "transparent"
                    Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 12
                        Kirigami.Icon { source: model.decoration; width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: model.display; color: root.text; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: aa; anchors.fill: parent; hoverEnabled: true; onClicked: { root.apps.trigger(index, "", null); root.close() } }
                }
            }

            Rectangle { visible: search.text.length === 0 && !root.allApps; Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.topMargin: 6; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }

            // recommended
            Header { visible: search.text.length === 0 && !root.allApps; title: "Recommended"; pill: "More"; Layout.topMargin: 8; Layout.leftMargin: 16; Layout.rightMargin: 16; onPillClicked: root.run("dolphin recent:/") }
            Grid {
                visible: search.text.length === 0 && !root.allApps
                Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.topMargin: 4
                columns: 2; columnSpacing: 8; rowSpacing: 2
                Repeater {
                    id: recRep
                    model: recent
                    delegate: Item {
                        visible: index < 6
                        width: Math.floor((menu.width - 40) / 2); height: visible ? 54 : 0
                        Rectangle { anchors.fill: parent; radius: 8; color: ra2.containsMouse ? Qt.rgba(1, 0.64, 0.26, 0.09) : "transparent" }
                        Row { anchors.fill: parent; anchors.leftMargin: 10; spacing: 12
                            Kirigami.Icon { source: model.decoration; width: 30; height: 30; anchors.verticalCenter: parent.verticalCenter }
                            Column { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 52
                                Text { text: model.display; color: root.text; font.pixelSize: 13; elide: Text.ElideRight; width: parent.width }
                                Text { text: model.description || ""; color: root.muted; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                            }
                        }
                        MouseArea { id: ra2; anchors.fill: parent; hoverEnabled: true; onClicked: { recent.trigger(index, "", null); root.close() } }
                    }
                }
            }
            Text { visible: search.text.length === 0 && !root.allApps && recRep.count === 0; text: "Recent files and apps will appear here"; color: root.muted; font.pixelSize: 13; Layout.leftMargin: 28; Layout.topMargin: 10 }
            Item { Layout.fillHeight: true; visible: search.text.length === 0 && !root.allApps }

            // footer
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 60
                color: Qt.rgba(0, 0, 0, 0.22)
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.07) }
                RowLayout { anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 12
                    Rectangle { Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 18; color: "transparent"; border.width: 1.5; border.color: root.amber
                        Kirigami.Icon { anchors.centerIn: parent; width: 22; height: 22; source: "user-identity"; isMask: true; color: root.amber } }
                    Text { text: root.userName; color: root.amber; font.pixelSize: 14; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Repeater {
                        model: [{ i: "folder-open-symbolic", c: "dolphin" }, { i: "configure-symbolic", c: "systemsettings" }, { i: "system-shutdown-symbolic", c: "qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptShutDown" }]
                        delegate: Item { Layout.preferredWidth: 36; Layout.preferredHeight: 36
                            Rectangle { anchors.fill: parent; radius: 8; color: fa.containsMouse ? Qt.rgba(1, 0.64, 0.26, 0.12) : "transparent" }
                            Kirigami.Icon { anchors.centerIn: parent; width: 22; height: 22; source: modelData.i; isMask: true; color: root.gold }
                            MouseArea { id: fa; anchors.fill: parent; hoverEnabled: true; onClicked: { root.run(modelData.c); root.close() } }
                        }
                    }
                }
            }
        }
        // rich gold glow at the bottom centre: frame colour -> light orange -> yellow towards the middle
        Canvas {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 46; enabled: false
            onPaint: {
                var c = getContext("2d"); c.reset()
                var w = width, h = height
                c.save(); c.translate(w / 2, h); c.scale((w / 2) / h, 1)
                var g = c.createRadialGradient(0, 0, 0, 0, 0, h)
                g.addColorStop(0.0, "rgba(255,210,122,0.55)"); g.addColorStop(0.35, "rgba(245,164,66,0.28)"); g.addColorStop(0.7, "rgba(232,121,50,0.10)"); g.addColorStop(1.0, "rgba(232,121,50,0)")
                c.fillStyle = g; c.fillRect(-h, -h, 2 * h, h); c.restore()
            }
        }
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 2
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.22; color: "#99e87932" }
                GradientStop { position: 0.5; color: "#ffffd27a" }
                GradientStop { position: 0.78; color: "#99e87932" }
                GradientStop { position: 1.0; color: "transparent" } }
        }
    }
}
